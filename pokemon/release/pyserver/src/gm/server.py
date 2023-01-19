#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2014 YouMi Information Technology Inc.
'''

from __future__ import absolute_import

import framework
from framework.log import logger
from framework.service.container import Container
from framework.service.rpc_client import Client

from .task.console import TConsoleFactory
from .gamerpc_client import GameRPClient
from .httpserver import HTTPServer
from .object.scheme import User
from .object.process.stream import DBStreamProcess
from .object.db import mongoCreateCollection
from .object.db import MongoDB as Mongo

from .object.archive import DBArchive, DBDailyArchive
from .object.account import DBAccount
from .object.order import DBOrder
from .object.cursor import DBCursor
from .object.loganalyzer.archive import *

from .rpc import GMWebRPC

from gm_defines import ServerDefs

import signal
from collections import deque, defaultdict

from tornado.ioloop import IOLoop
from tornado.gen import coroutine


Admin = 999
P1 = 500
P2 = 100
P3 = 1

class Server(object):

	RpcMinPermission = {
		'gmLogin': 0,
		'_hello': 0,

		'gmGC': Admin,
		'gmRefreshCSV': Admin,
		'gmGenRobots': Admin,
		'gmOpenRPDB': Admin,
		'gmCloseRPDB': Admin,
		'gmFlushDB': Admin,
		'gmCommitDB': Admin,
		'gmExecPy': Admin,
		'gmReloadAuto': Admin,
		'gmReloadPyFiles': Admin,
		'gmSetSessionCapacity': Admin,
		'gmRejudgePVPPlay': Admin,

		'gmSendGlobalMail': Admin,
		'gmSendServerMail': Admin,
		'gmSendUnionMail': Admin,
		'gmSendNewbieMail': Admin,
		'gmGenGift': P1,

		'gmRoleAbandon': P2,
		'gmSendMessage': P2,
		'gmSendMail': P2,
		'gmSetGameYYComfig': P2,

		'gmGetGameServers': P3,
		'gmGetGameServerStatus': P3,
		'gmGetGameMachineStatus': P3,
		'gmGetGameAccountStatus': P3,
		'gmGetGameYYComfig': P3,
		'gmGetGameOnlineRoles': P3,
		'gmGetMailCsv': P3,
		'gmGetRoleInfo': P3,
		'gmGetRoleInfoByName': P3,
		'gmGetUnionInfo': P3,
		'gmGetGiftCsv': P3,
		'gmGetGameRank': P3,
	}

	def __init__(self, name):
		self.cfg = ServerDefs[name]
		self.key = self.cfg['key']
		self.name = name
		self.servName = '[%s] GM Server'% name
		self.address = '0.0.0.0:%d'% self.cfg['http_port']
		self._stop = False
		self._start = False

		self.ioloop = IOLoop.instance()

		# init message cache
		self.messageMap = defaultdict(deque)

		# mongo
		self.Mongo = self.setupMongo()

		# run container
		self.container = Container(self.key, self.cfg['nsq']['reader'], self.cfg['nsq']['writer'], self.ioloop)
		language = self.key.split('.')[1]
		custom = set([x for x in self.cfg['dependent']])
		from game_defines import ServerDefs as GameServerDefines
		for key in GameServerDefines:
			if key not in custom and key.split('.')[1] == language:
				self.cfg['dependent'].append(key)

		for dep in self.cfg['dependent']:
			if dep not in self.container.services:
				if dep.startswith('game'):
					client = GameRPClient(dep, self.container.nsqclient)
				else:
					client = Client(dep, self.container.nsqclient)
				self.container.addservice(client)
		self.container.nsq.register(self.key, GMWebRPC(self))
		self.container.init()

		# game rpc client
		self.gameRPCs = {}
		self.gameShenheRPCs = {}
		for serv in self.container.getservices('^game'):
			if 'shenhe' in serv.name:
				# shenhe
				self.gameShenheRPCs[serv.name] = serv
			else:
				self.gameRPCs[serv.name] = serv

		# db client
		self.dbcAccount = self.container.getservices('^accountdb')[0]
		self.dbcGM = self.container.getservices('^accountdb')[0]
		self.dbcGift = self.container.getservices('^giftdb')[0]

		# battletest
		# self.battletestRPC = self.container.getservices('^battletest')[0]

		# task
		self.console = TConsoleFactory(self)

		# http server
		self.httpserver = HTTPServer(debug=self.cfg['debug'])

		self.httpserver.application.cfg = self.cfg

		self.httpserver.application.Mongo = self.Mongo
		self.httpserver.application.gameRPCs = self.gameRPCs
		self.httpserver.application.gameShenheRPCs = self.gameShenheRPCs
		self.httpserver.application.dbcAccount = self.dbcAccount
		self.httpserver.application.dbcGM = self.dbcGM
		self.httpserver.application.dbcGift = self.dbcGift
		self.httpserver.application.messageMap = self.messageMap
		# self.httpserver.application.battletestRPC = self.battletestRPC

		self.httpserver.application.console = self.console

		# 服务的server
		servs = []
		for serv in self.gameRPCs:
			servs.append(serv)
		servs = sorted(servs, key=lambda x:x.split('.')[-1])
		self.httpserver.application.servsList = servs

		# listen
		self.httpserver.listen(self.cfg['http_port'])

		# init gm system
		# self.initGM()

		# db process
		self.dbProcess = None
		self.dbProcess = DBStreamProcess(self.cfg)
		self.httpserver.application.dbProcess = self.dbProcess

		signal.signal(signal.SIGINT, lambda sig, frame: self.ioloop.add_callback_from_signal(self.onShutdown))
		signal.signal(signal.SIGTERM, lambda sig, frame: self.ioloop.add_callback_from_signal(self.onShutdown))

	def stop(self):
		self.httpserver.stop()
		self.ioloop.stop()
		self.ioloop.start()

		self.ioloop.run_sync(self.onApplicationExit)

		self.container.stop()
		self.Mongo.close()
		logger.info('%s Shutdown OK' % self.servName)

	def runLoop(self):
		if self._start:
			logger.info('%s Has Start' % self.servName)
			return

		if self.dbProcess:
			self.dbProcess.start()

		self.container.start()

		self._start = True
		logger.info('%s Start OK' % self.servName)
		self.ioloop.start()

	def onShutdown(self):
		if self._stop:
			return
		self._stop = True
		logger.info('%s onShutdown ...' % self.servName)
		self.stop()
		self.ioloop.stop()
		self.ioloop.close()

	def setupMongo(self):
		mongo = Mongo.get_instance(self.cfg['mongo'])
		User.init(mongo.client)

		mongoCreateCollection(mongo.client, DBArchive)
		mongoCreateCollection(mongo.client, DBDailyArchive)
		mongoCreateCollection(mongo.client, DBCursor)
		mongoCreateCollection(mongo.client, DBAccount)
		mongoCreateCollection(mongo.client, DBOrder)
		mongoCreateCollection(mongo.client, DBOfflineLogInfo)
		mongoCreateCollection(mongo.client, DBLogRoleArchive)
		mongoCreateCollection(mongo.client, DBLogItemArchive)
		mongoCreateCollection(mongo.client, DBLogRole)
		return mongo

	def verifyPermission(self, session, fname):
		permissionNeed = self.RpcMinPermission.get(fname, P3) # 默认都可以操作
		if session.permission < permissionNeed:
			return 'permission_error'
		return 'ok'

	@coroutine
	def onApplicationExit(self):
		if self.dbProcess:
			self.dbProcess.stop()
			self.dbProcess.join()

		logger.info('%s onApplicationExit' % self.servName)
