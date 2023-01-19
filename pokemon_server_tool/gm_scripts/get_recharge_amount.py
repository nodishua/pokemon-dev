#!/usr/bin/python
# -*- coding: utf-8 -*-

from sshtunnel import SSHTunnelForwarder
from pymongo import MongoClient
import paramiko
import msgpack
import binascii
from bson.objectid import ObjectId

import re
import sys
sys.path.append('../../server/src')
sys.path.append('../../release/src')

from nsqrpc.client import NSQClient
from tornado.ioloop import IOLoop
from tornado.gen import coroutine, Return, sleep
from tornado.concurrent import Future

private_key = paramiko.RSAKey.from_private_key_file('../fabfile/ssh_key/key_kdjx_nsq')

KEY = 'cn_qd'
ID_START = 200
ID_END = 231

gm_mongo = "mongodb://gmsystem:123456@172.16.2.2:27017"
DBClient = MongoClient(gm_mongo)

RechargeMap = {
	1: 30,
	2: 88,
	3: 648,
	4: 328,
	5: 198,
	6: 98,
	7: 60,
	8: 30,
	9: 6,

	101: 1,
	102: 6,
	103: 12,
	104: 18,
	105: 25,
	106: 30,
	107: 60,
	108: 98,
	109: 128,
	110: 168,
	111: 198,
	112: 328,
	113: 648,
}

infos = ""
with open("data.txt", 'r') as f:
	infos = f.read()

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


		print "server,account_id,recharge_amount"
		for line in infos.split('\n'):
			try:
				ss = 0
				game_key, role_name = line.strip().split()
				if re.match('[a-z0-9]{24}', role_name):
					account_id = ObjectId(role_name)
				else:
					role = client.call('gmGetRoleInfoByName', role_name, service_id=game_key)
					account_id = ObjectId(binascii.hexlify(role['account_id']))
				
				query = {'account_id': account_id,}

				if 'cn_qd' in game_key:
					data = DBClient.gm_web_qd.Order.find(query)
				else:
					data = DBClient.gm_web.Order.find(query)

				for order in data:
					ss += RechargeMap.get(order['recharge_id'], 0)

				print game_key,",",account_id,',',ss
			except:
				pass

		client.close()


if __name__ == "__main__":
	do()