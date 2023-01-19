#!/usr/bin/python
# -*- coding: utf-8 -*-

import contextlib
import paramiko
import binascii
from sshtunnel import SSHTunnelForwarder
from pymongo import MongoClient
from bson.objectid import ObjectId

import sys
sys.path.append('../../server/src')
sys.path.append('../../release/src')

from nsqrpc.client import NSQClient
from tornado.ioloop import IOLoop
from tornado.gen import coroutine, Return, sleep
from tornado.concurrent import Future

def objectid2string(id):
	return binascii.hexlify(id)

def string2objectid(s):
	return binascii.unhexlify(s)

@coroutine
def wait():
	yield sleep(1)


key_path = '../fabfile/ssh_key/key_kdjx_nsq'
private_key = paramiko.RSAKey.from_private_key_file(key_path)

external_cn_gm = ('172.81.227.66', 22)
internal_cn_nsq = ('172.16.2.14', 4150)
internal_cn_nsq2 = ('172.16.2.86', 4150)

@contextlib.contextmanager
def open_forward():
	with SSHTunnelForwarder(external_cn_gm, ssh_pkey=private_key, ssh_username='root', remote_bind_address=internal_cn_nsq) as server:
		with SSHTunnelForwarder(external_cn_gm, ssh_pkey=private_key, ssh_username='root', remote_bind_address=internal_cn_nsq2) as server2:

			CNNSQDefs = {
				'reader': {
					'max_in_flight': 10,
					'nsqd_tcp_addresses': ['127.0.0.1:%s' % server.local_bind_port, '127.0.0.1:%s' % server2.local_bind_port],
					'output_buffer_timeout': 25, # default 250ms
				},
				'writer': {
					'nsqd_tcp_addresses': ['127.0.0.1:%s' % server.local_bind_port, '127.0.0.1:%s' % server2.local_bind_port],
				},
			}

			client = NSQClient('walle.cn.1', CNNSQDefs['writer'], readerdefs=CNNSQDefs['reader'])
			IOLoop.current().run_sync(wait)

			yield client

			client.close()
