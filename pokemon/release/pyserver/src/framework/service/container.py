# -*- coding: utf-8 -*-
'''
Copyright (c) 2014 YouMi Information Technology Inc.
Copyright (c) 2016 TianJi Information Technology Inc.
'''

from framework.log import logger
from framework.loop import AsyncLoop
from framework.service.rpc_client import Client as RPCClient

from nsqrpc.server import NSQServer, NoReply
from nsqrpc.client import NSQClient

import tornado
from tornado.gen import coroutine, Return, sleep
from tornado.concurrent import Future

import re

class Container(object):
	def __init__(self, name, readerdefs=None, writerdefs=None, loop=None):
		self.name = '@' + name
		self.services = {}
		self.ioloop = loop or tornado.ioloop.IOLoop.current()
		self.nsq = NSQServer(self.name, readerdefs, loop=self.ioloop, writerdefs=writerdefs)
		self.nsqclient = NSQClient(self.name, writerdefs, loop=self.ioloop, readerdefs=readerdefs)

	def addservice(self, service):
		self.services[service.name] = service

	def getservice(self, name):
		return self.services[name]

	def getserviceOrCreate(self, name):
		client = self.services.get(name, None)
		if not client:
			client = RPCClient(name, self.nsqclient)
			self.addservice(client)
		return client

	def getservices(self, pattern):
		ret = []
		for _, v in self.services.iteritems():
			if re.match(pattern, v.name):
				ret.append(v)
		return ret

	def isExisted(self, name):
		return name in self.services

	def init(self):
		@coroutine
		def wait():
			yield sleep(1)
		self.ioloop.run_sync(wait)

	def start(self):
		self.nsq.start()

	def stop(self):
		self.nsq.stop() # stop server reader

	def close(self):
		self.nsq.close() # stop server writer
		self.nsqclient.close()

	def fix(self):
		reader = self.nsqclient.reader
		for key, conn in reader.conns.iteritems():
			stream = conn.stream
			if stream._state is None:
				stream._pending_callbacks = 0
				stream._maybe_run_close_callback()
				logger.warning('try to fix _pending_callbacks')
