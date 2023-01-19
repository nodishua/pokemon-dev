#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2014 YouMi Information Technology Inc.
'''

from __future__ import absolute_import

from framework import nowtime_t
from framework.log import logger
from framework.service.rpc_client import Client

from tornado.ioloop import PeriodicCallback


HeartTimePeriod = 2000

class GameRPClient(Client):

	def __init__(self, name, client):
		Client.__init__(self, name, client)
		self.heartTime = nowtime_t()
		self.heartCallBack = PeriodicCallback(self.onHeart, HeartTimePeriod)
		self.heartCallBack.start()
		self.ackOK = False
		self.heartfuture = None

	def isLost(self):
		return not self.ackOK

	def onHeart(self):
		if self.heartfuture:
			self.ackOK = False
			return

		self.heartfuture = self.call_async('Hello', 'gm')
		self.heartfuture.add_done_callback(self.onHeartAck)

	def onHeartAck(self, fu):
		self.heartfuture = None
		try:
			fu.result()
		except:
			self.ackOK = False
			logger.warning('%s lost' % self.name)
		else:
			self.heartTime = nowtime_t()
			if not self.ackOK:
				self.ackOK = True
				logger.info('%s hello ack' % self.name)
