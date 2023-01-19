#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2017 TianJi Information Technology Inc.
'''
from __future__ import absolute_import

import signal
import time
import multiprocessing
from multiprocessing import Queue

import tornado.ioloop
from tornado.gen import coroutine, Return, moment, sleep

from framework.log import logger, MyLoggerAdapter
from framework import int2datetime, OneDay

from gm.object.db import *
from gm.object.account import DBAccount
from gm.object.order import DBOrder


class Process(multiprocessing.Process):

	def __init__(self):
		self._q = Queue(1)
		self.taskQueue = Queue(1)
		self.logger = None
		self.ioloop = None

		super(Process, self).__init__()
		self.daemon = True

	def run(self):
		# ioloop
		self.ioloop = tornado.ioloop.IOLoop()
		self.ioloop.make_current()

		signal.signal(signal.SIGINT, lambda sig, frame: self.ioloop.add_callback_from_signal(self.stop))
		signal.signal(signal.SIGTERM, lambda sig, frame: self.ioloop.add_callback_from_signal(self.stop))

		# logger
		self.logger = MyLoggerAdapter(logger, clientip=self.name)
		self.logger.info('%s %x %x Start', self.name, self.pid, id(self.ioloop))

		# task
		self.console = Console(self)

		self.ioloop.run_sync(self.init)

	@property
	def stopSignal(self):
		return self._q.full()

	def stop(self):
		if self._q.full():
			return
		self._q.put_nowait('over')

	def sendTask(self, task):
		if not isinstance(task, tuple) or len(task) < 1:
			raise
		if not self.taskDone:
			return False
		self.taskQueue.put_nowait(task)
		return True

	@property
	def taskDone(self):
		return self.taskQueue.empty()

	@coroutine
	def init(self):
		pass


class Console(object):

	def __init__(self, serv):
		self._server = serv

	@property
	def server(self):
		return self._server

	def fixDB(self, dates):
		for dateInt in dates:
			sdt = int2datetime((dateInt % 1000000) * 100)
			st, et = time.mktime(sdt.timetuple()), time.mktime((sdt + OneDay).timetuple())

			accounts = DBFind(self.server.mongo.client, DBAccount, {'create_time': {'$gte': st, '$lt': et}}, noCache=True)
			for account in accounts:
				mapObj1 = KeyMapObject(account, {'_id': 'account_id',})
				try:
					self.server._processNewAccount(mapObj1)
				except Exception as e:
					self.server.logger.warning('!! task _processNewAccount %s'% account)
					print e

			accounts = DBFind(self.server.mongo.client, DBAccount, {'last_time': {'$gte': st, '$lt': et}}, noCache=True)
			for account in accounts:
				mapObj2 = KeyMapObject(account, {'_id': 'account_id',})
				try:
					self.server._processLoginAcccount(mapObj2)
				except Exception as e:
					self.server.logger.warning('!! task _processLoginAcccount %s'% account)
					print e

			orders = DBFind(self.server.mongo.client, DBOrder, {'time': {'$gte': st, '$lt': et}}, noCache=True)
			for order in orders:
				mapObj3 = KeyMapObject(order, {'_id': 'order_id',})
				try:
					self.server._processNewOrder(mapObj3)
				except Exception as e:
					self.server.logger.warning('!! task _processNewOrder %s'% order)
					print e

			DBCache.saveAllMongo(self.server.mongo.client)

			try:
				self.server._processDaily(dateInt)
			except Exception as e:
				self.server.logger.warning('!! task _processDaily %s'% dateInt)
				print e