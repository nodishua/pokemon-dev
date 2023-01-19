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


Raws = ""
with open("accounts.txt", 'r') as f:
	Raws = f.read()

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

		print "账号ID,角色数量,最高等级,最高VIP"
		for line in Raws.split('\n'):
			try:
				account_id = line.strip()
				ret = client.call('AccountQuery', string2objectid(account_id), service_id='accountdb.cn.1')
				roles = ret['model']['role_infos']
				
				role_count = len(roles)
				max_level = max([d['level'] for d in roles.values()])
				max_vip = max([d['vip'] for d in roles.values()])

				p_result = [account_id, str(role_count), str(max_level), str(max_vip)]
				print ",".join(p_result)

			except Exception as e:
				pass

		client.close()


if __name__ == "__main__":
	do()