#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2014 YouMi Information Technology Inc.
Copyright (c) 2018 TianJi Information Technology Inc.
'''
from __future__ import absolute_import

import game.patch
import game.dev_check

from framework import todaydate2int, perioddate2int, nowtime_t, int2datetime, nowdatetime_t, DailyRefreshHour
from framework.csv import csv, ErrDefs
from framework.log import logger, setLogOptions, MyLoggerAdapter
from framework.loop import AsyncLoop
from framework.helper import reseedRandom, toUTF8Dict
from framework.dbqueue import DBJoinableQueue
from framework.monitor import MachineStatus
from framework.word_filter import initFilter
from framework.xreload_cache import xreload_init
from framework.distributed import ServiceDefs
from framework.distributed.node import Node
from framework.wnet import WANetClientConn, WANetOkAckTask, WANetErrAckTask, WANetHeartSynTask, WANetBroadcastTask, WANetTask
from framework.service.container import Container
from framework.service.rpc_client import Client

import game.handler
from game import ServerError, ClientError
from game import globaldata
from game.session import Session
from game.object import UnionDefs
from game.rpc import GameRPC
from game.mailqueue import MailJoinableQueue
from game.sdkqueue import SDKJoinableQueue
from game.object.game import ObjectGame
from payment.sdk.qq import SDKQQ, SDKWX
from discovery.defines import ServerDefs as DiscoveryDefs
from game_defines import ServerDefs
from game.thinkingdata import ta

import tornado.log
import tornado.ioloop
import tornado.options
from tornado.iostream import IOStream
from tornado.tcpserver import TCPServer
from tornado.gen import coroutine, Return, moment, sleep
from tornado.curl_httpclient import CurlAsyncHTTPClient

import toro

import gc
import os
import json
import time
import signal
import socket
import logging
import datetime
import functools
import msgpackrpc
import binascii
from collections import deque

class Application(object):
	def __init__(self, handlers, server):
		self.handlers = handlers

		self.dbcGame = server.dbcGame
		self.dbcGift = server.dbcGift
		self.rpcPVP = server.rpcPVP
		self.rpcArena = server.rpcArena
		self.rpcUnion = server.rpcUnion
		self.rpcCraft = server.rpcCraft
		self.rpcClone = server.rpcClone
		self.rpcUnionFight = server.rpcUnionFight
		self.rpcYYHuodong = server.rpcYYHuodong
		self.rpcCardFight = server.rpcCardFight
		self.rpcAnti = server.rpcAnti
		self.rpcCardComment = server.rpcCardComment
		self.rpcCardScore = server.rpcCardScore
		self.rpcGym = server.rpcGym
		self.rpcHunting = server.rpcHunting
		self.mailQueue = server.mailQueue
		self.sdkQueue = server.sdkQueue
		self.servKey = server.key
		self.servName = server.servShowName
		self.servMerged = server.cfg['merged'] if 'merged' in server.cfg else False
		self.roleNameCache = set()

default_dependents = ['storage', 'arena', 'union', 'craft', 'clone', 'pvp', 'union_fight', 'yyhuodong', 'card_fight', 'gym', 'hunting']
Tag2ID = {'dev': 0, 'cn': 1, 'cn_qd': 2, 'cn_ly1': 3, 'kr': 4, 'en': 5, 'tw': 6, 'xy': 7} # use to generate cross robot id, see `getRobotObjectID`
Feature2ID = {'cross_craft': 1, 'cross_arena': 2}

class Server(TCPServer):

	Singleton = None

	def __init__(self, name):
		Server.Singleton = self

		self.name = name
		self.servName = '[%s] Game Server' % name
		self.cfg = ServerDefs[name]
		self.alias = self.cfg.get('alias', [])
		self.shutdown = False
		self.address = self.cfg['port']
		self.key = name
		if 'key' in self.cfg:
			self.key = self.cfg['key']
		_, tag, _ = self.key.split('.')
		if tag not in Tag2ID:
			raise Exception('%s not in Tag2ID', tag)
		import framework
		framework.__server_key__ = self.key
		# set random
		reseedRandom()

		# set logging
		# setLogOptions(topic=self.cfg['log_topic'])

		# set server open datetime
		globaldata.GameServOpenDatetime = self.cfg['open_date']
		logger.info('GameServOpenDatetime %s', globaldata.GameServOpenDatetime)

		globaldata.DailyRecordRefreshTime = datetime.time(hour=DailyRefreshHour)
		globaldata.FishingShopRefreshTime = datetime.time(hour=DailyRefreshHour)

		# machine status
		self.machineStatus = MachineStatus()

		# init word filter
		initFilter()
		if self.cfg.get('shushu',False):
			ta.init('/mnt/logbus_data/%s' % self.key)

		# set ioloop
		self.ioloop = tornado.ioloop.IOLoop.instance()

		self.dbcGame = None
		self.rpcArena = None
		self.rpcUnion = None
		self.dbcGift = None

		# run container
		self.container = Container(self.key, self.cfg['nsq']['reader'], self.cfg['nsq']['writer'], self.ioloop)
		dependent = self.cfg['dependent']
		custom = set([x.split('.')[0] for x in dependent])
		_, language, id = self.key.split('.')
		merged = self.cfg.get('merged', False)
		for k in default_dependents:
			if merged:
				k = '%smerge' % k
			if k not in custom: # use default dependent
				dependent.append('.'.join([k, language, id]))
		logger.info('dependent %s', dependent)
		for dep in dependent:
			if dep not in self.container.services:
				client = Client(dep, self.container.nsqclient)
				self.container.addservice(client)
		self.container.nsqclient.wrap_rpc_error(lambda x: ClientError(x))
		gameRPC = GameRPC(self)
		if self.alias:
			self.container.nsq.register(self.key, gameRPC)
			for alias in self.alias:
				self.container.nsq.register(alias, gameRPC, ignoreNotify=True)
		else:
			self.container.nsq.register(self.key, gameRPC)
		self.container.init()

		self.dbcGame = self.container.getservices('^storage')[0]
		self.rpcArena = self.container.getservices('^arena')[0]
		self.rpcUnion = self.container.getservices('(^union\.|^unionmerge\.)')[0]
		self.rpcCraft = self.container.getservices('^craft')[0]
		self.rpcClone = self.container.getservices('^clone')[0]
		self.rpcPVP = self.container.getservices('^pvp')[0]
		self.rpcUnionFight = self.container.getservices('^union_fight')[0]
		self.rpcYYHuodong = self.container.getservices('^yyhuodong')[0]
		self.rpcCardFight = self.container.getservices('^card_fight')[0]
		self.rpcGym = self.container.getservices('^gym')[0]
		self.rpcHunting = self.container.getservices('^hunting')[0]
		if 'anticheat' in dependent:
			self.rpcAnti = self.container.getservice('anticheat')
		else:
			self.rpcAnti = None

		gifts = self.container.getservices('^giftdb')
		if gifts:
			self.dbcGift = gifts[0]
		else:
			self.dbcGift = None
		if 'chat_monitor' in dependent:
			self.chatMonitor = self.container.getservice('chat_monitor')
		else:
			self.chatMonitor = None
		cardComments = self.container.getservices('^card_comment\.')
		if cardComments:
			self.rpcCardComment = cardComments[0]
		else:
			self.rpcCardComment = None
		cardScores = self.container.getservices('^card_score\.')
		if cardScores:
			self.rpcCardScore = cardScores[0]
		else:
			self.rpcCardScore = None

		# run db queue
		self.dbQueue = DBJoinableQueue()
		self.dbQueue.start()

		# run mail queue
		self.mailQueue = MailJoinableQueue(self.dbcGame, ObjectGame.getByRoleID)
		self.mailQueue.start()

		# run sdk queue
		self.sdkConfig = None
		with open('sdk.conf', 'rb') as fp:
			self.sdkConfig = json.load(fp, object_hook=toUTF8Dict)
		nameConfig = None
		self.servShowName = ''
		self.servID = 1
		try:
			self.servID = int(self.key[-2:])
		except:
			pass
		with open('serv.conf', 'rb') as fp:
			nameConfig = json.load(fp, object_hook=toUTF8Dict)
			for nameD in nameConfig:
				if self.servID == int(nameD['id']):
					self.servShowName = nameD['name']
					break
		self.sdkQueue = SDKJoinableQueue({'uc': CurlAsyncHTTPClient()}, self.sdkConfig)
		self.sdkQueue.start()

		# init sdk
		SDKQQ.initInGameServer()
		SDKWX.initInGameServer()

		# run application
		self.application = Application(game.handler.handlers, self)

		# session timer
		Session.server = self
		Session.ioloop = self.ioloop
		Session.starTimer()

		# init gm config
		self.initGM()
		logger.info('initGM OK')

		# init server global
		self.initServerGlobal()
		logger.info('initServerGlobal OK')

		# set VIP Max
		from game.object.game.levelcsv import ObjectFeatureUnlockCSV
		from game.object import FeatureDefs
		ObjectFeatureUnlockCSV.classInit()
		if ObjectFeatureUnlockCSV.isFeatureExist(FeatureDefs.VIPLevel18):
			globaldata.VIPLevelMax = 18
		else:
			globaldata.VIPLevelMax = 15
		logger.info('VIPLevelMax %d', globaldata.VIPLevelMax)

		# init all of game object class
		ObjectGame.initAllClass()
		logger.info('initAllClass OK')

		# init mail global
		self.initMail()
		logger.info('initMail OK')

		# init union
		self.initUnion()
		logger.info('initUnion OK')

		# init rank global
		self.initRank()
		logger.info('initRank OK')

		# init shop
		self.initShop()
		logger.info('initShop OK')

		# init message
		self.initMessage()
		logger.info('initMessage OK')

		# init society
		self.initSociety()
		logger.info('initSociety OK')

		# # init craft
		self.initCraft()
		logger.info('initCraft OK')

		# # init unionfight
		self.initUnionFight()
		logger.info('initUnionFight OK')

		# init cross craft
		self.initCrossCraft()
		logger.info('initCrossCraft OK')

		# init endless tower
		self.initEndlessTower()
		logger.info('initEndlessTower OK')

		# init cross online battle
		self.initCrossOnlineFight()
		logger.info('initCrossOnlineFight OK')

		# init cross arena
		self.initCrossArena()
		logger.info('initCrossArena OK')

		# init cross fishing
		self.initCrossFishing()
		logger.info('initCrossFishing OK')

		# init gym
		self.initGym()
		logger.info('initGym OK')

		# init cross mine
		self.initCrossMine()
		logger.info('initCrossMine OK')

		# init cross union fight
		self.initCrossUnionFight()
		logger.info('initCrossUnionFight OK')

		# init xreload
		# xreload_init(['./shuma/game/handler', './shuma/game/object'])

		self.dbcGame.call('DBCommit', False, True)

		# start container (nsq server)
		self.container.start()

		self.initTCPServer()

		signal.signal(signal.SIGINT, lambda sig, frame: self.ioloop.add_callback_from_signal(self.onShutdown))
		signal.signal(signal.SIGTERM, lambda sig, frame: self.ioloop.add_callback_from_signal(self.onShutdown))

		# HTTPServer.__init__(self, self.application)
		# HTTPServer.listen(self, self.cfg['port'])
		TCPServer.__init__(self, self.ioloop)

		gc.collect()
		# gc.set_debug(gc.DEBUG_STATS | gc.DEBUG_COLLECTABLE | gc.DEBUG_UNCOLLECTABLE)
		# (10000, 20, 20) 1W账号稳定为5G
		# (100000, 20, 20) 1W账号稳定为15G
		# (50000, 20, 20) 1W账号稳定为8G
		gc.set_threshold(50000, 10, 10)
		# gc.disable()

		logger.info('%s Start OK' % self.servName)

	@coroutine
	def asyncWaitJoin(self):
		yield Session.clearSession()
		logger.info('%s Session clear over, left %d' % (self.servName, Session.getSize()))

		yield self.mailQueue.join()
		logger.info('%s MailJoinableQueue join over, left %d' % (self.servName, self.mailQueue.qsize()))

		yield self.dbQueue.join()
		logger.info('%s DBJoinableQueue join over, left %d' % (self.servName, self.dbQueue.qsize()))

	@coroutine
	def asyncWait(self):
		yield self.asyncWaitJoin()

		# yield self.sdkQueue.join()
		# print self.servName, 'SDKJoinableQueue join over, left', self.sdkQueue.qsize()

		from game.object.game.mail import ObjectMailGlobal
		yield ObjectMailGlobal.Singleton.save_async(True)

		from game.object.game.servrecord import ObjectServerGlobalRecord
		# 全局游戏数据记录
		yield ObjectServerGlobalRecord.Singleton.save_async(True)

		from game.object.game.message import ObjectMessageGlobal
		yield ObjectMessageGlobal.save_async(self.dbcGame)

		try:
			if self.rpcArena:
				yield self.rpcArena.call_async('Flush')
		except Exception, e:
			logger.exception(str(e))
		logger.info('%s close PVP Server over' % self.servName)

	@coroutine
	def onShutdown(self):
		self.newStreamEvent.set()
		if self.shutdown:
			return

		self.shutdown = True
		logger.info('%s onShutdown ...' % self.servName)

		TCPServer.stop(self)
		self.container.stop()

		Session.stopTimer()

		yield self.asyncWaitJoin()

		self.ioloop.stop()
		self.ioloop.start()

		# close appnotify socket
		from game.object.game.message import ObjectMessageGlobal
		if ObjectMessageGlobal.AppNotifyStream:
			ObjectMessageGlobal.AppNotifyStream.close()

		from tornado.ioloop import PeriodicCallback
		PeriodicCallback(self.container.fix, 120*1000).start()
		self.ioloop.run_sync(self.asyncWait)

		self.container.close()

		self.ioloop.stop()
		logger.info('%s %d closed' % (self.servName, self.cfg['port']))

		logging.shutdown()
		ta.onShutdown()

	def runLoop(self):
		TCPServer.listen(self, self.cfg['port'])

		while not self.shutdown:
			self.ioloop.start()

		self.ioloop.close()
		logger.info('%s run loop stop' % self.servName)

	def initTCPServer(self):
		self.recvTaskQue = toro.JoinableQueue()
		self.sendTaskQue = toro.JoinableQueue()
		self.newStreamQue = deque()
		self.newStreamEvent = toro.Event()

		self.handleStreamQue()
		self.handleTask()
		self.handleSend()

	def handle_stream(self, stream, address):
		self.newStreamQue.append((stream, address))
		self.newStreamEvent.set()

	@coroutine
	def handleStreamQue(self):
		while not self.shutdown:
			yield self.newStreamEvent.wait()
			self.newStreamEvent.clear()
			queLen = len(self.newStreamQue)
			for i in xrange(queLen):
				stream, address = self.newStreamQue.popleft()
				if stream.closed():
					continue

				conn = None
				try:
					# WANetClientConn no aes pwd when connection be create
					# after read packet which body encode by init AESPWD
					# the pwd will be changed when the first packet be decode
					conn = WANetClientConn(stream, address, self._onTaskArrived, self._onSockClose, logger=MyLoggerAdapter(logger, clientip=address))
					# Session(conn)
					conn.runRead()

				except Exception, e:
					logger.error('handleStreamQue error, %s, %s', e, address)
					if conn:
						# Session.removeSession(conn)
						conn.close()
					stream.close()

	@coroutine
	def handleSend(self):
		while not self.shutdown:
			ntask = yield self.sendTaskQue.get()
			broadcast = isinstance(ntask, WANetBroadcastTask)
			if not broadcast and ntask.conn not in WANetClientConn.conns:
				self.sendTaskQue.task_done()
				continue

			try:
				if broadcast:
					logger.info('handleSend %s broadcast', ntask.url)
					for key, session in Session.idSessions.iteritems():
						if session.canSendTask():
							ntask.writeOne(session.lastConn, WANetTask.synIDMax - session.clientSynID, session.sessionPwd)
				else:
					# logger.info('handleSend %s syn=%d', ntask.url, ntask.synID, clientip=ntask.conn.address)
					ntask.write()
			except Exception as e:
				logger.error('handleSend error, %s', e)
			finally:
				ntask.forgetData()
				self.sendTaskQue.task_done()

			yield moment

	@coroutine
	def handleTask(self):
		while not self.shutdown:
			ntask, ltask = yield self.recvTaskQue.get()
			if ntask.conn not in WANetClientConn.conns:
				self.recvTaskQue.task_done()
				continue

			logger.debug('handleTask %s syn=%d', ntask.url, ntask.synID, clientip=ntask.conn.address)

			def onReturn(ntask, ltask, fu):
				ack = None
				try:
					ack = fu.result()
				except Exception, e:
					# 可能是非逻辑上的异常，关闭链接防止玩家后续请求
					ntask.conn.close()
					ltask.log_exception(force=True)
				finally:
					ltask.log_request()
					ltask.destroy()
				if ack:
					self.sendTaskQue.put(ack)

			fu = ltask.runInServer()
			fu.add_done_callback(functools.partial(onReturn, ntask, ltask))
			self.recvTaskQue.task_done()

			yield moment

	# def handleCleanZombie(self):
	# 	Session.cleanZombie()

	def _onTaskArrived(self, conn, ntask):
		if self.shutdown:
			return

		handlerCls = None
		try:
			conn.heartLastTime = time.time()
			if isinstance(ntask, WANetHeartSynTask):
				return
			elif isinstance(ntask, WANetOkAckTask):
				return
			elif isinstance(ntask, WANetErrAckTask):
				return

			conn.logger.debug('_onTaskArrived %s syn=%d', getattr(ntask, 'url', None), ntask.synID)

			handlerCls = self.application.handlers.get(ntask.url, None)
			if handlerCls is None:
				conn.logger.warning('_onTaskArrived %s syn=%d no such handler', getattr(ntask, 'url', None), ntask.synID)
				raise Exception('no handlerCls')
		except:
			conn.close()
		finally:
			if handlerCls:
				self.recvTaskQue.put((ntask, handlerCls(self.application, ntask)))
			conn.readNext()

	def _onSockClose(self, conn):
		Session.lostSessionConn(conn)
		conn.logger.info('Conn Close, WANetClientConn size %d, Session size %d', len(WANetClientConn.conns), len(Session.idSessions))

	def sendTask(self, ntask):
		self.sendTaskQue.put(ntask)

	def initGM(self):
		from game.object.game.gm import ObjectGMYYConfig
		from game.object.game.yyhuodong import ObjectYYFightRank

		# read GMYYConfig model
		# GMYYConfig只有一条数据
		gmYYConfig = ObjectGMYYConfig(self.dbcGame)
		data = self.dbcGame.call('DBReadsert', 'GMYYConfig', {'key': self.key}, False)
		if not data['ret']:
			raise ServerError('db readsert gm yunying config error')
		gmYYConfig.set(data['model']).init()
		self.dbcGame.call('DBCommit', False, True)

	def initMail(self):
		from game.object.game.mail import ObjectMailGlobal

		# read MailGlobal model
		# MailGlobal只有一条数据
		globalObj = ObjectMailGlobal(self.dbcGame)
		data = self.dbcGame.call('DBReadsert', 'MailGlobal', {'key': self.key}, False)
		if not data['ret']:
			raise ServerError('db readsert mail global error')
		globalObj.set(data['model']).init()
		self.dbcGame.call('DBCommit', False, True)

	def initRank(self):
		from game.object.game.rank import ObjectRankGlobal
		from game.object.game.servrecord import ObjectServerGlobalRecord

		globalObj = ObjectRankGlobal(self.dbcGame, self.rpcArena, self.alias)
		globalObj.init()

		# 世界等级
		self.ioloop.run_sync(functools.partial(ObjectServerGlobalRecord.refreshWorldLevel, self.dbcGame))

	def initUnion(self):
		from game.object.game.union import ObjectUnion
		data = self.rpcUnion.call('GetCacheModel')
		for m in data:
			ObjectUnion(m)
		logger.info('Union count:%d', len(ObjectUnion.ObjsMap))
		return

	def initShop(self):
		from game.object.game.shop import ObjectUnionShop, ObjectExplorerShop, ObjectFragShop, ObjectRandomTowerShop, ObjectEquipShop, ObjectFishingShop

		# ObjectUnionShop
		data = self.dbcGame.call('DBReadBy', 'UnionShop', {'discard_flag': True})
		if not data['ret']:
			raise ServerError('db read discarded union shops error')
		ids = [d['id'] for d in data['models']]
		ObjectUnionShop.initFree(ids)

		# ObjectExplorerShop
		data = self.dbcGame.call('DBReadBy', 'ExplorerShop', {'discard_flag': True})
		if not data['ret']:
			raise ServerError('db read discarded explorer shops error')
		ids = [d['id'] for d in data['models']]
		ObjectExplorerShop.initFree(ids)

		# ObjectFragShop
		data = self.dbcGame.call('DBReadBy', 'FragShop', {'discard_flag': True})
		if not data['ret']:
			raise ServerError('db read discarded frag shops error')
		ids = [d['id'] for d in data['models']]
		ObjectFragShop.initFree(ids)

		# ObjectRandomTowerShop
		data = self.dbcGame.call('DBReadBy', 'RandomTowerShop', {'discard_flag': True})
		if not data['ret']:
			raise ServerError('db read discarded random_tower shops error')
		ids = [d['id'] for d in data['models']]
		ObjectRandomTowerShop.initFree(ids)

		# ObjectEquipShop
		data = self.dbcGame.call('DBReadBy', 'EquipShop', {'discard_flag': True})
		if not data['ret']:
			raise ServerError('db read discarded equip shops error')
		ids = [d['id'] for d in data['models']]
		ObjectEquipShop.initFree(ids)

		# ObjectFishingShop
		data = self.dbcGame.call('DBReadBy', 'FishingShop', {'discard_flag': True})
		if not data['ret']:
			raise ServerError('db read discarded fishing shops error')
		ids = [d['id'] for d in data['models']]
		ObjectFishingShop.initFree(ids)

		self.dbcGame.call('DBCommit', False, True)

	def initServerGlobal(self):
		from game.object.game.cache import ObjectCacheGlobal
		globalObj = ObjectCacheGlobal()
		globalObj.init(self)

		# 全局记录
		from game.object.game.servrecord import ObjectServerGlobalRecord
		data = self.dbcGame.call('DBReadsert', 'ServerGlobalRecord', {'key': self.key}, False)
		if not data['ret']:
			raise ServerError('db readsert server global record error')
		globalObj = ObjectServerGlobalRecord(self.dbcGame)
		globalObj.set(data['model']).init()

		# 战力排行历史
		from game.object.game.yyhuodong import ObjectYYFightRank
		ObjectYYFightRank.setTop10RankModel(globalObj.fight_rank_history)

		if globalObj.huodongboss_cross_key:
			data = self.container.getserviceOrCreate(globalObj.huodongboss_cross_key).call("HuoDongBossJoin", globalObj.key)
			if not data or data == "closed":
				globalObj.huodongboss_cross_key = ""
				logger.info("HuoDongBoss Status closed")

		if globalObj.unionqa_cross_key:
			data = self.container.getserviceOrCreate(globalObj.unionqa_cross_key).call("CrossUnionQAJoin", globalObj.key)
			if data is None:
				data = {}
			if data.get("round", "closed") == "closed":
				globalObj.onUnionQAClosed(data)
				logger.info("CrossUnionQA Round closed")

		self.dbcGame.call('DBCommit', False, True)

	def onChat(self, type, msg):
		if self.chatMonitor:
			self.chatMonitor.notify('chatMessage', self.name, type, msg)

	def initMessage(self):
		from game.object.game.message import ObjectMessageGlobal

		data = self.dbcGame.call('DBReadsert', 'MessageGlobal', {'key': self.key}, False)
		if not data['ret']:
			raise ServerError('db readsert message global error')

		ObjectMessageGlobal(self.key, self.onChat)
		ObjectMessageGlobal.set(data['model'])

		# def _onConn():
		# 	ObjectMessageGlobal.AppNotifyClosed = False
		# 	logger.info('%s AppNotify connected' % self.servName)

		# def _onClose():
		# 	if not ObjectMessageGlobal.AppNotifyClosed:
		# 		ObjectMessageGlobal.AppNotifyClosed = True
		# 		logger.info('%s AppNotify closed' % self.servName)

		# 	def _reConn():
		# 		stream = IOStream(socket.socket(socket.AF_INET, socket.SOCK_STREAM, 0))
		# 		stream.connect(self.cfg['appnotify_listener'], _onConn)
		# 		stream.set_close_callback(_onClose)
		# 		ObjectMessageGlobal.AppNotifyStream = stream
		# 	self.ioloop.add_timeout(datetime.timedelta(seconds=30), _reConn)

		# stream = IOStream(socket.socket(socket.AF_INET, socket.SOCK_STREAM, 0))
		# stream.connect(self.cfg['appnotify_listener'], _onConn)
		# stream.set_close_callback(_onClose)
		# ObjectMessageGlobal.AppNotifyStream = stream

	def initSociety(self):
		from game.object.game.society import ObjectSocietyGlobal

		oneMonth = 24*3600*30
		now = nowtime_t()
		data = self.dbcGame.call('DBReadRangeBy', 'Role', {'last_time': (now-oneMonth, now+oneMonth), 'level': (2, 99999)}, 100)
		if not data['ret']:
			raise ServerError('db read avaliable role error')
		data = data['models']

		globalObj = ObjectSocietyGlobal()
		globalObj.init(data)
		logger.info('Society RoleCache Size: %d', globalObj.RoleCache.size())
		self.dbcGame.call('DBCommit', False, True)

	def initCraft(self):
		from game.object.game.craft import RoleSignFields, ObjectCraftInfoGlobal

		globalObj = ObjectCraftInfoGlobal(self.dbcGame)
		data = self.dbcGame.call('DBReadsert', 'CraftGameGlobal', {'key': self.key}, False)
		if not data['ret']:
			raise ServerError('db readsert craft game global error')
		globalObj.set(data['model'])

		# read auto sign up role infos
		data = self.dbcGame.call('DBReadKeysRangeBy', 'Role', {'vip_level': (ObjectCraftInfoGlobal.AutoSignVIP, globaldata.INF), 'level': (ObjectCraftInfoGlobal.OpenLevel, globaldata.INF)}, RoleSignFields + ['top_cards', 'disable_flag', 'vip_hide'], 0)
		if not data['ret']:
			raise ServerError('db read craft auto signup role error')
		globalObj.initAutoSignUp(data['models'])

		self.dbcGame.call('DBCommit', False, True)

		logger.info('Craft Before Init Status %s', globalObj.round)

		if globalObj.round not in ('closed', 'signup'):
			data = self.rpcCraft.call('GameSync')
			globalObj.init(self.rpcCraft, data)
		else:
			globalObj.init(self.rpcCraft, None)

		# 根据状态，决定是否启动自动报名和结束报名定时器
		if globalObj.isTodayOpen():
			mayRound = globalObj.getRoundInTime()
			if mayRound == 'signup':
				self.ioloop.run_sync(Session._onCraftStartSignUp)

		logger.info('Craft Now Status %s', globalObj.round)

	def initCrossCraft(self):
		from game.object.game.cross_craft import RoleSignFields, ObjectCrossCraftGameGlobal

		data = self.dbcGame.call('DBReadAll', 'CrossCraftGameGlobal')
		newData = {}
		if not any([model for model in data['models'] if model['key'] == self.key]):
			newData = self.dbcGame.call('DBReadsert', 'CrossCraftGameGlobal', {'key': self.key}, False)
			if not newData['ret']:
				raise ServerError('db readsert cross craft global error')
		models = data.get('models', []) + ([newData.get('model')] if newData.get('model') else [])

		# read auto sign up role infos
		data = self.dbcGame.call('DBReadKeysRangeBy', 'Role', {'vip_level': (ObjectCrossCraftGameGlobal.AutoSignVIP, globaldata.INF), 'level': (ObjectCrossCraftGameGlobal.OpenLevel, globaldata.INF)}, RoleSignFields + ['top_cards', 'disable_flag', 'vip_hide'], 0)
		if not data['ret']:
			raise ServerError('db read craft auto signup role error')
		autoSignup = data['models']

		self.dbcGame.call('DBCommit', False, True)

		# TODO: date判断
		for model in models:
			# 主动判断跨服状态
			# DEBUG:
			# globalObj.cross_key = ''
			# globalObj.bet1 = {}
			# globalObj.signup = {}
			# globalObj.last_top8_plays = {}
			# globalObj.last_ranks = []
			globalObj = ObjectCrossCraftGameGlobal(self.dbcGame)
			globalObj.set(model)

			logger.info('Cross Craft Befroe Init %s %s signup %s', globalObj.cross_key, globalObj.date, len(globalObj.signup))
			if globalObj.cross_key:
				data = self.container.getserviceOrCreate(globalObj.cross_key).call('CrossCraftJoin', globalObj.key)
				globalObj.init(self, data)
				if globalObj.round == 'signup':
					globalObj.onStartSignUp()
			else:
				globalObj.init(self, None)

			logger.info('%s Cross Craft key: %s, Cross Craft Now Status %s', globalObj.key, globalObj.cross_key, globalObj.round)
		ObjectCrossCraftGameGlobal.initAutoSignUp(autoSignup)

	def initCrossArena(self):
		from game.object.game.cross_arena import ObjectCrossArenaGameGlobal

		data = self.dbcGame.call('DBReadAll', 'CrossArenaGameGlobal')
		newData = {}
		if not any([model for model in data['models'] if model['key'] == self.key]):
			newData = self.dbcGame.call('DBReadsert', 'CrossArenaGameGlobal', {'key': self.key}, False)
			if not newData['ret']:
				raise ServerError('db readsert cross arena global error')
		models = data.get('models', []) + ([newData.get('model')] if newData.get('model') else [])

		self.dbcGame.call('DBCommit', False, True)

		for model in models:
			globalObj = ObjectCrossArenaGameGlobal(self.dbcGame)
			globalObj.set(model)

			# 主动判断跨服状态
			if globalObj.cross_key:
				data = self.container.getserviceOrCreate(globalObj.cross_key).call('CrossArenaJoin', globalObj.key)
				globalObj.init(self, data)
			else:
				globalObj.init(self, {})

			logger.info('%s Cross Arena key: %s, Now Status %s', globalObj.key, globalObj.cross_key, globalObj.round)

	def initCrossFishing(self):
		from game.object.game.cross_fishing import ObjectCrossFishingGameGlobal

		data = self.dbcGame.call('DBReadAll', 'CrossFishingGameGlobal')
		newData = {}
		if not any([model for model in data['models'] if model['key'] == self.key]):
			newData = self.dbcGame.call('DBReadsert', 'CrossFishingGameGlobal', {'key': self.key}, False)
			if not newData['ret']:
				raise ServerError('db readsert cross fishing global error')
		models = data.get('models', []) + ([newData.get('model')] if newData.get('model') else [])

		self.dbcGame.call('DBCommit', False, True)

		for model in models:
			globalObj = ObjectCrossFishingGameGlobal(self.dbcGame)
			globalObj.set(model)

			if globalObj.cross_key:
				data = self.container.getserviceOrCreate(globalObj.cross_key).call('CrossFishingJoin', globalObj.key)
				globalObj.init(self, data)
			else:
				globalObj.init(self, {})

			logger.info('%s Cross fishing key: %s, Cross fishing Now Status %s', globalObj.key, globalObj.cross_key, globalObj.round)

	def initUnionFight(self):
		from game.object.game.union_fight import RoleSignFields, ObjectUnionFightGlobal
		globalObj = ObjectUnionFightGlobal(self.dbcGame)
		data = self.dbcGame.call('DBReadsert', 'UnionFightGameGlobal', {'key': self.key}, False)
		if not data['ret']:
			raise ServerError('db readsert unionfight info global error')
		globalObj.set(data['model']).init(self.rpcUnionFight)

		# read auto sign up role infos
		data = self.dbcGame.call('DBReadKeysRangeBy', 'Role', {'level': (ObjectUnionFightGlobal.OpenLevel, globaldata.INF)}, RoleSignFields + ['disable_flag', 'vip_hide'], 0)
		if not data['ret']:
			raise ServerError('db read unionfight auto signup role error')
		globalObj.initAutoSignUp(data['models'])

		self.dbcGame.call('DBCommit', False, True)

		awardTime = globalObj.last_award_time
		logger.info('UnionFight Last AwardTime %d, opendate %s', awardTime, globalObj.OpenDateTime)

		# 判断数据库状态和当前时间状态
		# if globalObj.isOpenInDay():
		globalObj.initUnionFightSign(globalObj.signup)
		mayRound = globalObj.getRoundInTime()
		if mayRound == 'signup':
			self.ioloop.run_sync(Session._onUnionFightStartSignUp)
		elif mayRound == 'closed':
			globalObj.round = mayRound

		logger.info('UnionFight Now Status %s', globalObj.round)

	def initGym(self):
		from game.object.game.gym import ObjectGymGameGlobal

		data = self.dbcGame.call('DBReadAll', 'GymGameGlobal')
		newData = {}
		if not any([model for model in data['models'] if model['key'] == self.key]):
			newData = self.dbcGame.call('DBReadsert', 'GymGameGlobal', {'key': self.key}, False)
			if not newData['ret']:
				raise ServerError('db readsert cross gym global error')
		models = data.get('models', []) + ([newData.get('model')] if newData.get('model') else [])

		self.dbcGame.call('DBCommit', False, True)

		for model in models:
			globalObj = ObjectGymGameGlobal(self.dbcGame)
			globalObj.set(model)
			# 初始化跨服数据（跨服状态和道馆状态一致）
			if globalObj.cross_key:
				data = self.container.getserviceOrCreate(globalObj.cross_key).call('CrossGymJoin', globalObj.key)
				globalObj.init(self, data)
			else:
				globalObj.init(self, {})

			# round（closed)跟cross_key ("") 状态是一致
			logger.info('%s Cross Gym key: %s, Gym Now Status %s', globalObj.key, globalObj.cross_key, globalObj.round)

	def initCrossOnlineFight(self):
		from game.object.game.cross_online_fight import ObjectCrossOnlineFightGameGlobal

		data = self.dbcGame.call('DBReadAll', 'CrossOnlineFightGameGlobal')
		newData = {}
		if not any([model for model in data['models'] if model['key'] == self.key]):
			newData = self.dbcGame.call('DBReadsert', 'CrossOnlineFightGameGlobal', {'key': self.key}, False)
			if not newData['ret']:
				raise ServerError('db readsert cross arena global error')
		models = data.get('models', []) + ([newData.get('model')] if newData.get('model') else [])

		self.dbcGame.call('DBCommit', False, True)

		for model in models:
			globalObj = ObjectCrossOnlineFightGameGlobal(self.dbcGame)
			globalObj.set(model)
			# 主动判断跨服状态
			if globalObj.cross_key:
				data = self.container.getserviceOrCreate(globalObj.cross_key).call('CrossOnlineFightJoin', globalObj.key)
				globalObj.init(self, data)
			else:
				globalObj.init(self, {})
			logger.info('%s Cross OnlineFight key: %s, Cross OnlineFight Now Status %s', globalObj.key, globalObj.cross_key, globalObj.round)

	def initCrossMine(self):
		from game.object.game.cross_mine import ObjectCrossMineGameGlobal

		data = self.dbcGame.call('DBReadAll', 'CrossMineGameGlobal')
		newData = {}
		if not any([model for model in data['models'] if model['key'] == self.key]):
			newData = self.dbcGame.call('DBReadsert', 'CrossMineGameGlobal', {'key': self.key}, False)
			if not newData['ret']:
				raise ServerError('db readsert cross mine global error')
		models = data.get('models', []) + ([newData.get('model')] if newData.get('model') else [])

		self.dbcGame.call('DBCommit', False, True)

		for model in models:
			globalObj = ObjectCrossMineGameGlobal(self.dbcGame)
			globalObj.set(model)

			# 主动判断跨服状态
			if globalObj.cross_key:
				data = self.container.getserviceOrCreate(globalObj.cross_key).call('CrossMineJoin', globalObj.key)
				globalObj.init(self, data)
			else:
				globalObj.init(self, {})

			logger.info('%s Cross Mine key: %s, Now Status %s', globalObj.key, globalObj.cross_key, globalObj.round)

	def initCrossUnionFight(self):
		from game.object.game.cross_union_fight import ObjectCrossUnionFightGameGlobal

		data = self.dbcGame.call('DBReadAll', 'CrossUnionFightGameGlobal')
		newData = {}
		if not any([model for model in data['models'] if model['key'] == self.key]):
			newData = self.dbcGame.call('DBReadsert', 'CrossUnionFightGameGlobal', {'key': self.key}, False)
			if not newData['ret']:
				raise ServerError('db readsert cross union fight global error')
		models = data.get('models', []) + ([newData.get('model')] if newData.get('model') else [])

		self.dbcGame.call('DBCommit', False, True)

		for model in models:
			globalObj = ObjectCrossUnionFightGameGlobal(self.dbcGame)
			globalObj.set(model)

			# 主动判断跨服状态
			if globalObj.cross_key:
				data = self.container.getserviceOrCreate(globalObj.cross_key).call('CrossUnionFightJoin', globalObj.key)
				globalObj.init(self, data)
			else:
				globalObj.init(self, {})

			logger.info('%s Cross Union Fight key: %s, Now Status %s', globalObj.key, globalObj.cross_key, globalObj.status)

	def initEndlessTower(self):
		from game.object.game import ObjectEndlessTowerGlobal
		globalObj = ObjectEndlessTowerGlobal(self.dbcGame)
		data = self.dbcGame.call('DBReadsert', 'EndlessTowerGlobal', {'key': self.key}, False)
		if not data['ret']:
			raise ServerError('db readsert endlessTower info global error')
		globalObj.set(data['model']).init(self)

	def getRobotObjectID(self, idx, feature, areaKey=''):
		if not areaKey:
			areaKey = self.key
		# binascii.unhexlify 参数为偶数个16进制数
		_, key, area = areaKey.split('.')
		# 3 + (2 + 3 + 6 + 7) / 2 = 12
		return 'rbt' + binascii.unhexlify(('%2d%3d%6d%7d' % (Feature2ID[feature], Tag2ID[key], int(area), idx)).replace(' ', 'f'))

	# QQ查询余额接口
	@classmethod
	def getBalanceQQRMBSync(cls, game):
		self = cls.Singleton
		def _query():
			openid = game.sdkInfo.get('openid', '')
			openkey = game.sdkInfo.get('openkey', '')
			pf = game.sdkInfo.get('pf', '')
			pfkey = game.sdkInfo.get('pfkey', '')
			zoneid = game.role.area
			if game.role.channel == SDKQQ.Channel:
				return SDKQQ.queryBalanceRequest(openid, openkey, pf, pfkey, zoneid)
			elif game.role.channel == SDKWX.Channel:
				return SDKWX.queryBalanceRequest(openid, openkey, pf, pfkey, zoneid)
			raise NotImplementedError('%s no implemented', game.role.channel)

		try:
			if self.ioloop._running:
				self.ioloop.stop()
			ret = self.ioloop.run_sync(_query)

			# balance：游戏币个数（包含了赠送游戏币）
			# save_amt: 累计充值金额的游戏币数量
			# print ret
			if 'balance' in ret:
				game.role.setQQRMB(int(ret['balance']))
			if 'save_amt' in ret:
				oldrmb = game.role.qq_rmb
				oldrecharge = game.role.qq_recharge
				game.role.setQQRecharge(int(ret['save_amt']))

				if int(ret['save_amt']) != game.role.qq_recharge:
					logger.warning('role %d qq recharges mismatch %s, old %d %d, now %d %d', game.role.id, str(ret), oldrmb, oldrecharge, game.role.qq_rmb, game.role.qq_recharge)

		except:
			# 先让玩家进去玩吧，详细信息看log
			# raise ServerError(str(e))
			logger.exception('getBalanceQQRMBSync Exception')

	# QQ扣费接口
	@classmethod
	def payQQRMBSync(cls, game, cost):
		self = cls.Singleton
		def _pay():
			openid = game.sdkInfo.get('openid', '')
			openkey = game.sdkInfo.get('openkey', '')
			pf = game.sdkInfo.get('pf', '')
			pfkey = game.sdkInfo.get('pfkey', '')
			zoneid = game.role.area
			billno = '%d_%d_%d_%d_%d_%s' % (todaydate2int(), game.role.area, game.role.id, game.role.qq_rmb, cost, nowtime_t())
			if game.role.channel == SDKQQ.Channel:
				return SDKQQ.payRequest(openid, openkey, pf, pfkey, zoneid, cost, billno)
			elif game.role.channel == SDKWX.Channel:
				return SDKWX.payRequest(openid, openkey, pf, pfkey, zoneid, cost, billno)
			raise NotImplementedError('%s no implemented', game.role.channel)

		try:
			if self.ioloop._running:
				self.ioloop.stop()
			ret = self.ioloop.run_sync(_pay)

			# print ret
			return int(ret['balance'])
		except:
			logger.exception('payQQRMBSync Exception')
			raise ClientError(ErrDefs.payQQRMBNotEnough)
