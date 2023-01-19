#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2014 YouMi Information Technology Inc.
Copyright (c) 2016 TianJi Information Technology Inc.
'''
from __future__ import absolute_import

import tornado.ioloop

import time
import signal
import logging
import datetime
from collections import defaultdict

import msgpackrpc

from tornado.ioloop import PeriodicCallback

from framework.log import logger
from framework.loop import AsyncLoop
from framework.distributed.node import Node

from discovery.defines import ServerDefs
from discovery.rpc import DiscoveryRPC


class Server(Node):
	def __init__(self, name):
		ioloop = tornado.ioloop.IOLoop()
		ioloop.make_current()

		self.cfg = ServerDefs[name]
		self.servStop = False

		self.orderIdx = 1 # service查询返回顺序按hello顺序
		self.nodeOrders = {} # {key: idx}
		self.services = defaultdict(set) # {service: set(key)}
		self.checkTimer = PeriodicCallback(self.checkNodes, 10000, ioloop)
		self.checkTimer.start()

		Node.__init__(self, self.cfg['key'], DiscoveryRPC(self), loop=AsyncLoop(ioloop))
		self.listen(msgpackrpc.Address(self.cfg['ip'], self.cfg['port']))

		signal.signal(signal.SIGINT, lambda sig, frame: self.ioloop.add_callback_from_signal(self.stop))
		signal.signal(signal.SIGTERM, lambda sig, frame: self.ioloop.add_callback_from_signal(self.stop))
		logger.info('%s Start OK', self.nodeName)

	def stop(self):
		if self.servStop:
			return

		self.servStop = True
		self.checkTimer.stop()
		Node.stop(self)

		self.ioloop.stop()
		self.ioloop.close()

		logger.info('%s Stop OK', self.nodeName)
		logging.shutdown()

	def runLoop(self):
		self.ioloop.start()

	def checkNodes(self):
		now = time.time()
		losts = []
		for key, info in self.nodeInfos.iteritems():
			if now - info['last_time'] > 10:
				losts.append(key)
				logger.warning('%s %s lost', key, info)
		map(self.on_node_lost, losts)

	def on_node_lost(self, key):
		Node.on_node_lost(self, key)
		for s in self.services:
			self.services[s].discard(key)
		self.nodeOrders.pop(key, None)

	# 重载Node._fw_hello
	def _fw_hello(self, key, address, states):
		ret = Node._fw_hello(self, key, address, states)
		for service in states:
			self.services[service].add(key)
		if key not in self.nodeOrders:
			self.nodeOrders[key] = self.orderIdx
			self.orderIdx += 1
		return ret
