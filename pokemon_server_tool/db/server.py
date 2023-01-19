#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2014 YouMi Information Technology Inc.
'''

from framework.log import setLogOptions, logger
from db.task.rpc import DBRPC
import db.redisorm as orm
import defines

import msgpackrpc
import tornado.ioloop
from tornado.gen import moment, coroutine

import gc
import time
import signal
import logging
import datetime

# 刷新策略：
# IdleModelCommitTimerSecs时间段内model object没有变化，就回刷到数据库并释放
# 如果SessionCleanZombieTimerSecs时间段内game server中相关db object变动，再从数据库里拖回来
#
# 设计目的：
# 1. db server快速回收内存，调用onCommit，因为db颗粒度小，在线玩家有一部分数据经常不用，如mail，equip，card
# 2. game server依赖session时间回收，调用dbCommitObject或者dbUpdate forget，逻辑上可以成片释放
#
# 定时器机制导致最坏回收时间是2*IdleModelCommitTimerSecs
IdleModelCommitTimerSecs = 10*60
IdleModelCommitPersistence = set([
	'Union',
	'MailGlobal',
	'RankGlobal',
	'PVPGlobal',
	'PVPGlobalHistory',
	'ServerDailyRecord',
	'CloneRoom',
	'CraftInfoGlobal',
	'CraftGlobal',
	'CraftGlobalHistory',
])


class Server(msgpackrpc.Server):
	'''
	Managed redis, cached, or persistence data.
	'''

	def __init__(self, name):
		self.cfg = defines.ServerDefs[name]
		listener = (self.cfg['host'], self.cfg['port'])

		# set logging
		setLogOptions(topic=self.cfg['log_topic'])

		msgpackrpc.Server.__init__(self, DBRPC(self), loop=msgpackrpc.Loop(tornado.ioloop.IOLoop.instance()))
		self.listen(msgpackrpc.Address(*listener))
		self._address = listener

		self.name = name
		self.servName = '[%s] DB Server' % name
		self.servStop = False

		self.redisConfig = self.cfg['redis']
		orm.util.set_connection_settings(**self.redisConfig)
		self.redis = orm.util.get_connection()

		self.commitTimer = msgpackrpc.loop.Loop.instance().attach_periodic_callback(self.onCommit, IdleModelCommitTimerSecs*1000.)

		signal.signal(signal.SIGINT, lambda sig, frame: self.stop())
		signal.signal(signal.SIGTERM, lambda sig, frame: self.stop())

		logger.info('%s connected %s:%d DB %d' % (self.servName, self.redisConfig['host'], self.redisConfig['port'], self.redisConfig['db']))

	def stop(self):
		self.servStop = True
		logger.info('%s stop ...' % self.servName)

		self.commitTimer.stop()

		msgpackrpc.Server.stop(self)
		orm.session.commit(full=True, all=True)
		logger.info('%s Redis Session commit over' % self.servName)

		logging.shutdown()

	@coroutine
	def onCommit(self):
		objs = orm.session.get_zombies(time.time() - IdleModelCommitTimerSecs)
		ocount = len(objs)
		cchanges = 0
		fcount = 0
		for obj in objs:
			if time.time() - obj._lasttime < IdleModelCommitTimerSecs:
				continue

			try:
				ret = orm.session.save(obj, full=True, all=True)
				cchanges += ret
				clsname = type(obj).__name__
				if clsname not in IdleModelCommitPersistence:
					orm.session.forget(obj)
					fcount += 1
			except:
				logger.exception('save db error when onCommit')
				orm.session.forget(obj)

			yield moment

		if fcount > 0:
			logger.info('onCommit %d objects %d columns change, %d objects forget', ocount, cchanges, fcount)
			logger.info('Redis Session %d known, %d wknown', len(orm.session.known), len(orm.session.wknown))

	def runLoop(self):
		self.start()
