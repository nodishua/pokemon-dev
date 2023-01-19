#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2014 YouMi Information Technology Inc.
'''

from __future__ import absolute_import

from framework import datetime2int, OneDay, nowdatetime_t, DailyRefreshHour
from framework.log import logger, setLogOptions
from framework.loop import AsyncLoop
from framework.helper import reseedRandom
from framework.dbqueue import DBJoinableQueue
from framework.distributed import ServiceDefs
from framework.distributed.node import Node

from db.client import Client as DBClient
from cross.defines import ServerDefs
from cross.task.rpc import CrossRPC
from cross.agentmgr import CrossAgentManager
from discovery.defines import ServerDefs as DiscoveryDefs

import tornado.log
import tornado.gen
import tornado.options
from tornado.ioloop import PeriodicCallback

import msgpackrpc

import copy
import time
import signal
import logging
import datetime
import functools



class Server(Node):
	NewDayInClock5Timer = None

	def __init__(self, name):
		self.cfg = ServerDefs[name]

		# set random
		reseedRandom()

		# set logging
		setLogOptions(topic=self.cfg['log_topic'])

		# create ioloop
		ioloop = tornado.ioloop.IOLoop.instance()

		# run db queue
		self.dbQueue = DBJoinableQueue()
		self.dbQueue.start()

		# run cross rpc server
		discoveryCfg = DiscoveryDefs[self.cfg['discovery']]
		Node.__init__(self, self.cfg['key'], CrossRPC(self), loop=AsyncLoop(ioloop))
		self.set_discovery((discoveryCfg['ip'], discoveryCfg['port']))
		self.listen(msgpackrpc.Address(self.cfg['host'], self.cfg['port']))

		self.name = name
		self.servName = '[%s] Cross Server' % name
		self.servStop = False

		# run db client
		self.dbcCross = DBClient(self.cfg['db'], loop=AsyncLoop(ioloop))

		# run anti-cheat client
		self.antiMgr = CrossAgentManager(self, self.cfg['anti_server'])

		# init global
		self.initGlobal()
		logger.info('initGlobal OK')

		# init craft
		self.initCraft()
		logger.info('initCraft OK')

		# 启动开始检查是否可以提供服务
		from cross.object.gglobal import ObjectCrossGlobal
		ObjectCrossGlobal.onServiceCheck()

		# init and start timer
		self.starTimer()

		signal.signal(signal.SIGINT, lambda sig, frame: ioloop.add_callback_from_signal(self.onShutdown))
		signal.signal(signal.SIGTERM, lambda sig, frame: ioloop.add_callback_from_signal(self.onShutdown))

	def start(self):
		Node.start(self)

		logger.info('%s Start OK' % self.servName)

	def stop(self):
		if self.servStop:
			return

		self.servStop = True
		Node.stop(self)
		self.ioloop.stop()

	def runLoop(self):
		self.start()
		self.ioloop.start()

	@tornado.gen.coroutine
	def onFlush(self):
		logger.info('%s onFlush ...' % self.servName)

		yield self.dbQueue.join()

	def onShutdown(self):
		logger.info('%s onShutdown ...' % self.servName)

		self.stop()
		self.close()

		self.ioloop.start()
		self.ioloop.run_sync(self.onFlush)
		logger.info('%s DBJoinableQueue join over, left %s' % (self.servName, self.dbQueue.qsize()))

		self.ioloop.stop()
		self.ioloop.close()
		logger.info('%s RPC %s closed' % (self.servName, self.cfg['port']))

		logging.shutdown()

	def starTimer(self):
		def startAndTimer(dtNext, timer):
			def _run(timer):
				timer.start()
				return timer.callback()
			self.ioloop.add_timeout(dtNext - dtNow + datetime.timedelta(seconds=2), _run, timer)
		hour5 = datetime.time(hour=DailyRefreshHour)

		dtNow = datetime.datetime.now()
		if dtNow.time() < hour5:
			dtNext5 = datetime.datetime.combine(dtNow.date(), hour5)
		else:
			dtNext5 = datetime.datetime.combine((dtNow + OneDay).date(), hour5)

		self.NewDayInClock5Timer = PeriodicCallback(self._onNewDayInClock5, (1 + 24 * 3600) * 1000.)
		startAndTimer(dtNext5, self.NewDayInClock5Timer)

	def _onNewDayInClock5(self):
		logger.info('_onNewDayInClock5 %s', nowdatetime_t())

		from cross.object.gglobal import ObjectCrossGlobal
		ObjectCrossGlobal.onServiceCheck()

	def initGlobal(self):
		from cross.object.gglobal import ObjectCrossGlobal

		data = self.dbcCross.call('dbRead', 'CrossGlobal', 1)
		if not data['ret']:
			data = self.dbcCross.call('dbCreate', 'CrossGlobal', {})
			if not data['ret']:
				raise ServerError('db create server global record error')
			data = self.dbcCross.call('dbRead', 'CrossGlobal', 1)
			if not data['ret']:
				raise ServerError('db read server global record error')
		globalObj = ObjectCrossGlobal(self.dbcCross)
		globalObj.set(data['model']).init(self)

		self.dbcCross.call('dbCommit', False, True)

	def initCraft(self):
		from cross.object.gglobal import ObjectCrossGlobal
		from cross.object.craft_gglobal import ObjectCrossCraftServiceGlobal

		data = self.dbcCross.call('dbRead', 'CrossCraftServiceGlobal', 1)
		if not data['ret']:
			data = self.dbcCross.call('dbCreate', 'CrossCraftServiceGlobal', {})
			if not data['ret']:
				raise ServerError('db create craft service error')
			data = self.dbcCross.call('dbRead', 'CrossCraftServiceGlobal', 1)
			if not data['ret']:
				raise ServerError('db read craft service error')

		globalObj = ObjectCrossCraftServiceGlobal(self.dbcCross)
		globalObj.set(data['model']).init(self)

		self.dbcCross.call('dbCommit', False, True)

		# 上次结束了需要清理数据和状态
		# globalObj.clean()
		# globalObj.date = 20170122
		logger.info('ObjectCrossCraftServiceGlobal.isAllOver %s', globalObj.isAllOver())
		if globalObj.isAllOver():
			globalObj.clean()
			ObjectCrossGlobal.initServiceState(ServiceDefs.Craft)

		# 中途重启
		else:
			# 等game准备就绪
			def allInitOK(fu):
				result = None
				try:
					result = fu.result()
				finally:
					pass
				logger.info('crossCraftIsInited %s', result)
				globalObj.resetToday()
			self.wait_clients_ok(globalObj.servers, 'crossCraftIsInited').add_done_callback(allInitOK)


