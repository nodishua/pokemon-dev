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

private_key = paramiko.RSAKey.from_private_key_file('key_kdjx_nsq')

def objectid2string(id):
	return binascii.hexlify(id)

def string2objectid(s):
	return binascii.unhexlify(s)

@coroutine
def wait():
	yield sleep(1)

def do():
	with SSHTunnelForwarder(
		('172.81.227.66', 22),
		ssh_pkey = private_key,
		# ssh_password = "password"
		ssh_username = 'root',
		remote_bind_address= ('172.16.2.14', 4150),
	) as server:
		CNNSQDefs = {
			'reader': {
				'nsqd_tcp_addresses': '127.0.0.1:%s' % server.local_bind_port,
				'output_buffer_timeout': 25, # default 250ms
			},
			'writer': {
				'nsqd_tcp_addresses': '127.0.0.1:%s' % server.local_bind_port,
			},
		}

		client = NSQClient('walle.cn.1', CNNSQDefs['writer'], readerdefs=CNNSQDefs['reader'])
		IOLoop.current().run_sync(wait)

		for i in xrange(200, 231):
			print '='*10
			key = 'game.cn_qd.%d' % i
			print key

			resp = client.call('gmGetGameRank', 'union', service_id=key)
			rank = resp['view']['rank'][:10]
			for info in rank:
				# print info.keys()
				print '-'*10
				unionID = info['id']
				print key, info['name'], info['level'], info['members'], info['chairman_name'], info['intro'], objectid2string(info['id'])
				union = client.call('gmGetUnionInfo', unionID, service_id=key)
				# print union.keys()
				chairman_db_id, vice_chairmans = union['chairman_db_id'], union['vice_chairmans']

				role = client.call('gmGetRoleInfo', chairman_db_id, service_id=key)
				# sum([d.get('star', 0) for gateID, d in self.gate_star.iteritems() if gateID in csv.scene_conf and csv.scene_conf[gateID].sceneType in types])
				gateStarSum = sum([d.get('star', 0) for gateID, d in role['gate_star'].iteritems()])
				print key, info['name'], objectid2string(info['id']), '会长:', 'name', role['name'], 'level', role['level'], 'vip', role['vip_level'], 'star', gateStarSum, 'role', objectid2string(chairman_db_id), 'account', objectid2string(role['account_id'])
				for dbid in vice_chairmans:
					role = client.call('gmGetRoleInfo', dbid, service_id=key)
					print key, info['name'], objectid2string(info['id']), '副会长:', 'name', role['name'], 'level', role['level'], 'vip', role['vip_level'], 'star', gateStarSum, 'role', objectid2string(dbid), 'account', objectid2string(role['account_id'])

		client.close()


if __name__ == "__main__":
	do()
