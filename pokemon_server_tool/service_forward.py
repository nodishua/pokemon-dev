#!/usr/bin/python
# -*- coding: utf-8 -*-

from sshtunnel import SSHTunnelForwarder
from pymongo import MongoClient
import paramiko
import msgpack
import binascii
from bson.objectid import ObjectId
from contextlib import contextmanager

import sys
sys.path.append('../server/src')

from nsqrpc.client import NSQClient
from tornado.ioloop import IOLoop
from tornado.gen import coroutine, Return, sleep
from tornado.concurrent import Future

private_key = paramiko.RSAKey.from_private_key_file('fabfile/ssh_key/key_kdjx_nsq')
private_key_kr = paramiko.RSAKey.from_private_key_file('fabfile/ssh_key/key_kdjx_nsq_kr')
private_key_tw = paramiko.RSAKey.from_private_key_file('fabfile/ssh_key/key_kdjx_game_tw')
private_key_en = paramiko.RSAKey.from_private_key_file('fabfile/ssh_key/key_kdjx_game_en')

def objectid2string(id):
	return binascii.hexlify(id)

def string2objectid(s):
	return binascii.unhexlify(s)

@coroutine
def wait():
	yield sleep(1)

LanguageAddressMap = {
	'cn' : {
		'gm': ('172.81.227.66', 22),
		'nsq': ('172.16.2.14', 4150),
		# 'nsqs' [('172.16.2.14', 4150), ('172.16.2.86', 4150)],
	},
	'kr' : {
		'gm': ('119.28.235.28', 22),
		'nsq': ('192.168.1.7', 4150),
	},
	'tw' : {
		'gm': ('43.129.178.28', 22),
		'nsq': ('172.19.0.15', 4150),
	},
	'en' : {
		'gm': ('94.74.92.71', 22),
		'nsq': ('192.168.1.46', 4150),
	}
}

@contextmanager
def open_client(language):
	if language == 'kr':
		KRNSQDefs = {
			'reader': {
				'max_in_flight': 10,
				'nsqd_tcp_addresses': ['192.168.1.7:4150'],
				'output_buffer_timeout': 25, # default 250ms
			},
			'writer': {
				'nsqd_tcp_addresses': ['192.168.1.7:4150'],
			},
		}
		client = NSQClient('walle.kr.1', KRNSQDefs['writer'], readerdefs=KRNSQDefs['reader'])
		IOLoop.current().run_sync(wait)

		yield client

		client.close()
		return
	elif language == 'tw':
		TWNSQDefs = {
			'reader': {
				'max_in_flight': 10,
				'nsqd_tcp_addresses': ['172.19.0.15:4150'],
				'output_buffer_timeout': 25,  # default 250ms
			},
			'writer': {
				'nsqd_tcp_addresses': ['172.19.0.15:4150'],
			},
		}
		client = NSQClient('walle.tw.1', TWNSQDefs['writer'], readerdefs=TWNSQDefs['reader'])
		IOLoop.current().run_sync(wait)

		yield client

		client.close()
		return
	elif language == 'en':
		ENNSQDefs = {
			'reader': {
				'max_in_flight': 10,
				'nsqd_tcp_addresses': ['192.168.1.46:4150'],
				'output_buffer_timeout': 25,  # default 250ms
			},
			'writer': {
				'nsqd_tcp_addresses': ['192.168.1.46:4150'],
			},
		}
		client = NSQClient('walle.en.1', ENNSQDefs['writer'], readerdefs=ENNSQDefs['reader'])
		IOLoop.current().run_sync(wait)

		yield client

		client.close()
		return

@contextmanager
def open_forward(language):
	conf = LanguageAddressMap[language]
	if language == 'kr':
		with SSHTunnelForwarder(
			conf['gm'],
			ssh_pkey = private_key_kr,
			ssh_username = 'root',
			remote_bind_address= ('192.168.1.7', 4150),
		) as server:
			print server.local_bind_port
			KRNSQDefs = {
				'reader': {
					'max_in_flight': 10,
					'nsqd_tcp_addresses': ['127.0.0.1:%s' % server.local_bind_port],
					'output_buffer_timeout': 25, # default 250ms
				},
				'writer': {
					'nsqd_tcp_addresses': ['127.0.0.1:%s' % server.local_bind_port],
				},
			}

			client = NSQClient('walle.kr.1', KRNSQDefs['writer'], readerdefs=KRNSQDefs['reader'])
			IOLoop.current().run_sync(wait)

			yield client

			client.close()
			return
	elif language == 'tw':
		with SSHTunnelForwarder(
			conf['gm'],
			ssh_pkey = private_key_tw,
			ssh_username = 'root',
			remote_bind_address= ('172.19.0.15', 4150),
		) as server:
			print server.local_bind_port
			TWNSQDefs = {
				'reader': {
					'max_in_flight': 10,
					'nsqd_tcp_addresses': ['127.0.0.1:%s' % server.local_bind_port],
					'output_buffer_timeout': 25, # default 250ms
				},
				'writer': {
					'nsqd_tcp_addresses': ['127.0.0.1:%s' % server.local_bind_port],
				},
			}

			client = NSQClient('walle.tw.1', TWNSQDefs['writer'], readerdefs=TWNSQDefs['reader'])
			IOLoop.current().run_sync(wait)

			yield client

			client.close()
			return
	elif language == 'en':
		with SSHTunnelForwarder(
			conf['gm'],
			ssh_pkey = private_key_en,
			ssh_username = 'root',
			remote_bind_address= ('192.168.1.46', 4150),
		) as server:
			print server.local_bind_port
			ENNSQDefs = {
				'reader': {
					'max_in_flight': 10,
					'nsqd_tcp_addresses': ['127.0.0.1:%s' % server.local_bind_port],
					'output_buffer_timeout': 25, # default 250ms
				},
				'writer': {
					'nsqd_tcp_addresses': ['127.0.0.1:%s' % server.local_bind_port],
				},
			}

			client = NSQClient('walle.en.1', ENNSQDefs['writer'], readerdefs=ENNSQDefs['reader'])
			IOLoop.current().run_sync(wait)

			yield client

			client.close()
			return

	with SSHTunnelForwarder(
		conf['gm'],
		ssh_pkey = private_key,
		ssh_username = 'root',
		remote_bind_address= ('172.16.2.14', 4150),
	) as server:
		with SSHTunnelForwarder(
			conf['gm'],
			ssh_pkey = private_key,
			ssh_username = 'root',
			remote_bind_address= ('172.16.2.86', 4150),
		) as server2:
			print server.local_bind_port, server2.local_bind_port
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

			client = NSQClient('walle.cn.2', CNNSQDefs['writer'], readerdefs=CNNSQDefs['reader'])
			IOLoop.current().run_sync(wait)

			yield client

			client.close()
