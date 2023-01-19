#!/usr/bin/python
# -*- coding: utf-8 -*-

from sshtunnel import SSHTunnelForwarder
from pymongo import MongoClient
import paramiko
import msgpack
import binascii
from bson.objectid import ObjectId

import sys
sys.path.append('../server/src')

from nsqrpc.client import NSQClient
from tornado.ioloop import IOLoop
from tornado.gen import coroutine, Return, sleep
from tornado.concurrent import Future

private_key = paramiko.RSAKey.from_private_key_file('fabfile/ssh_key/key_kdjx_nsq')

def objectid2string(id):
	return binascii.hexlify(id)

def string2objectid(s):
	return binascii.unhexlify(s)

@coroutine
def wait():
	yield sleep(1)

with SSHTunnelForwarder(
	('172.81.227.66', 22),
	ssh_pkey = private_key,
	# ssh_password = "password"
	ssh_username = 'root',
	remote_bind_address= ('172.16.2.10', 27017),
) as server:
	# mongodb://gamesystem:123456@172.16.2.10:27017/game_cn_1?authMechanism=SCRAM-SHA-1&authSource=admin"
	url = "mongodb://gamesystem:123456@%s:%d/%s?authMechanism=SCRAM-SHA-1&authSource=admin" % ('127.0.0.1', server.local_bind_port, 'game_cn_1')
	conn = MongoClient(url)

	collection = conn['game_cn_1']['Role']
	resp = conn['game_cn_1']['RankRole'].find({}, {"_id": 1, "role.name": 1, "fighting_point": 1}).sort('fighting_point', -1).limit(200)
	logs = []
	cards = []
	heldItems = []
	for vv in resp:
		role = collection.find_one({"_id": vv["_id"]}, {"talent_trees": 1, "trainer_level": 1, "top_cards": 1, "held_items": 1, "items": 1})
		# log = 'id %s, name %s, fighting_point %d, talent_trees %s, trainer_level %d' % (vv['_id'], vv['role']['name'].encode('utf-8'), vv['fighting_point'], {id.encode('utf-8'): (v['cost'], sum(v['talent'].values())) for id, v in role['talent_trees'].iteritems()}, role['trainer_level'])
		log = 'id %s, 100 %d' % (vv["_id"], role["items"].get("100", 0))
		# print log
		logs.append(log)
		# cards.extend(role['top_cards'])
		# heldItems.extend(role['held_items'])

	with open('cn_01_roles_100.log', 'w') as fp:
		s = '\n'.join(logs)
		fp.write(s + '\n')

	# with open('cn_01_roles.log', 'w') as fp:
	# 	s = '\n'.join(logs)
	# 	fp.write(s + '\n')

	# collection = conn['game_cn_1']['RoleCard']
	# logs = []
	# for id in cards:
	# 	card = collection.find_one({"_id": id}, {"role_db_id": 1, "card_id": 1, "effort_advance": 1, "abilities": 1, 'star': 1, 'equips': 1})
	# 	log = 'id %s, role_db_id %s, card_id %d, star: %d, effort_advance %d, sum abilities %d, equips %s' % (card["_id"], card["role_db_id"], card["card_id"], card['star'], card.get('effort_advance', 0), sum(card.get("abilities", {}).values()), card['equips'])
	# 	# print log
	# 	logs.append(log)

	# with open('cn_01_cards.log', 'w') as fp:
	# 	s = '\n'.join(logs)
	# 	fp.write(s + '\n')

	# collection = conn['game_cn_1']['RoleHeldItem']
	# logs = []
	# for id in heldItems:
	# 	helditem = collection.find_one({"_id": id}, {"role_db_id": 1, "held_item_id": 1, "advance": 1, "level": 1, "card_db_id": 1})
	# 	log = 'id %s, role_db_id %s, held_item_id %d, advance %d, level %d, card_db_id %s' % (helditem['_id'], helditem['role_db_id'], helditem['held_item_id'], helditem['advance'], helditem['level'], helditem['card_db_id'])
	# 	# print log
	# 	logs.append(log)

	# with open('cn_01_held_items.log', 'w') as fp:
	# 	s = '\n'.join(logs)
	# 	fp.write(s + '\n')

	conn.close()
