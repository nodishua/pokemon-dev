#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2014 YouMi Information Technology Inc.
'''

from __future__ import absolute_import

from framework import nowdatetime_t
from framework.log import logger, setLogOptions
from framework.lru import LRUCache
from framework.loop import AsyncLoop
from framework.helper import toUTF8Dict
from framework.service.container import Container
from framework.service.rpc_client import Client

from payment.myordercache import MyOrderCache
from payment.payqueue import PayJoinableQueue
from payment.application import Application
from payment_defines import ServerDefs

import time
import json
import signal
import logging
import httplib
import datetime
import traceback
from collections import deque

import tornado.ioloop
from tornado.httpserver import HTTPServer
from tornado.gen import coroutine, moment
from tornado.concurrent import Future

MyOrderForgetTime = 30*24*60*60 # 保存一个月


class Server(HTTPServer):
	def __init__(self, name):
		self.name = name
		self.cfg = ServerDefs[name]
		self.servName = '[%s] Payment Server' % name
		self.httpAddress = self.cfg['port']
		self.sdkReqID = 1
		self.servStop = False
		self.key = self.cfg['key']

		# set logging
		# setLogOptions(topic=self.cfg['log_topic'])

		self.sdkConfig = None
		self.refreshSDKConfig()

		if self.sdkConfig is None:
			logger.error('Can not get sdk config file')
			return

		# set ioloop
		self.ioloop = tornado.ioloop.IOLoop.instance()

		# run container
		self.container = Container(self.key, self.cfg['nsq']['reader'], self.cfg['nsq']['writer'], self.ioloop)
		language = self.key.split('.')[1]
		dependent = self.cfg['dependent']
		for dep in dependent:
			if dep not in self.container.services:
				client = Client(dep, self.container.nsqclient)
				self.container.addservice(client)
		self.container.init()

		self.dbcPay = self.container.getservices('^paymentdb')[0]
		self.dbcGift = self.container.getservices('^giftdb')[0]

		# game rpc client
		games = self.container.getservices('^game')
		self.gameRPCs = {s.name: s for s in games}

		# run pay queue
		self.payQueue = PayJoinableQueue(self.dbcPay, self.container, self.cfg['game_key_prefix'])
		self.payQueue.start()

		# my order cache
		self.myOrderCache = MyOrderCache()

		# order cache
		self.orderCache = LRUCache(capacity=(len(self.sdkConfig)+4)*5000)

		# init order
		self.initOrder()

		# save my order
		self.myOrderTimer = tornado.ioloop.PeriodicCallback(self.saveMyOrder, 5*1000.)
		self.myOrderTimer.start()

		# run application
		self.application = Application()
		self.application.sdkConfig = self.sdkConfig
		self.application.dbcPay = self.dbcPay
		self.application.dbcGift = self.dbcGift
		self.application.payQueue = self.payQueue
		self.application.orderCache = self.orderCache
		self.application.myOrderCache = self.myOrderCache

		signal.signal(signal.SIGINT, lambda sig, frame: self.ioloop.add_callback_from_signal(self.stop))
		signal.signal(signal.SIGTERM, lambda sig, frame: self.ioloop.add_callback_from_signal(self.stop))

		# start container (nsq server)
		self.container.start()

		HTTPServer.__init__(self, self.application)
		HTTPServer.listen(self, self.cfg['port'])

		logger.info('%s Start OK' % self.servName)

	def stop(self):
		if self.servStop:
			return

		logger.info('%s Stop ...' % self.servName)

		self.servStop = True
		HTTPServer.stop(self)
		self.myOrderTimer.stop()
		self.ioloop.stop()
		self.ioloop.start()

		self.ioloop.run_sync(self.flushMyOrder)

		self.ioloop.run_sync(self.payQueue.join)
		logger.info('%s PayJoinableQueue join over, left %d' % (self.servName, self.payQueue.qsize()))

		self.container.stop()

		self.ioloop.stop()
		self.ioloop.close()

		logger.info('%s Stop OK' % self.servName)
		logging.shutdown()

	def runLoop(self):
		self.ioloop.start()

	def refreshSDKConfig(self):
		if self.sdkConfig:
			return self.sdkConfig

		with open('sdk.conf', 'rb') as fp:
			self.sdkConfig = json.load(fp, object_hook=toUTF8Dict)
		logger.info(str(self.sdkConfig))

		return self.sdkConfig

	def initOrder(self):
		# 自定义订单号
		ret = self.dbcPay.call('MyPayOrderAll')
		endT = time.time() - MyOrderForgetTime
		for k, v in ret.iteritems():
			order, t, uid, rid, skey, pid, yyid, csvid = MyOrderCache.decodeDB(v)
			if MyOrderCache.isOutOfTimeLimit(t, endT):
				continue
			# 测试用，可能会导致跟正式订单冲突
			if skey.find('game_dev') >= 0:
				continue
			self.myOrderCache.add(k, order, t, uid, rid, skey, pid, yyid, csvid)
		logger.info('%s %d/%d My Orders Left Last Time' % (self.servName, len(self.myOrderCache), len(ret)))

		# 支付成功，cdata数据正常，未充值
		ret = self.dbcPay.call('DBReadBy', 'PayOrder', {'recharge_flag': False, 'bad_flag': False})
		if not ret['ret']:
			raise Exception('db read orders error')

		orders = ret['models']
		for order in orders:
			# 测试用，可能会导致跟正式订单冲突
			if order['server_key'].find('game_dev') >= 0:
				continue
			self.orderCache.set(order['order_id'], True)
			self.payQueue.put((order, 0))
			# logger.info('{order_id} Order {id} Account {account_id} Server {server_key} Role {role_id} Time {time} Channel {channel} Recharge {recharge_id} Result {result} Flag {recharge_flag} {bad_flag}'.format(order))
		logger.info('%s %d/%d Orders Left Last Time' % (self.servName, len(self.orderCache), len(orders)))


	def flushMyOrder(self):
		kvs = {}
		endT = time.time() - MyOrderForgetTime
		for order, t in self.myOrderCache.iteritems():
			if MyOrderCache.isOutOfTimeLimit(t, endT):
				continue
			kvs[order] = MyOrderCache.encodeDB(t)
		logger.info('%s %d My Orders Left' % (self.servName, len(kvs)))
		return self.dbcPay.call_async('MyPayOrderCreate', kvs, True)

	def saveMyOrder(self):
		kvs = {}
		if self.myOrderCache.needFlush():
			for order, t in self.myOrderCache.iteritems():
				kvs[order] = MyOrderCache.encodeDB(t)
			self.dbcPay.notify('MyPayOrderCreate', kvs, True)
			self.myOrderCache.markFlush()

		else:
			orders = self.myOrderCache.getNeedSave()
			for order, t in orders:
				kvs[order] = MyOrderCache.encodeDB(t)
			if kvs:
				self.dbcPay.notify('MyPayOrderCreate', kvs)

