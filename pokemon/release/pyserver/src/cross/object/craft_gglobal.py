#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2014 YouMi Information Technology Inc.
Copyright (c) 2016 TianJi Information Technology Inc.
'''

from framework import nowdate_t, nowtime2int, nowdate_t, nowtime_t, todaydate2int, nowdatetime_t, date2int, int2date, int2datetime, OneDay, nowdtime_t
from framework.log import logger
from framework.csv import csv
from framework.object import ObjectDBase, db_property, db_ro_property, ObjectDicAttrs
from framework.helper import *
from framework.distributed.helper import *

from game.object.game.cross_craft import RoleSignItem
from cross.object import RemoteObject
from cross.globaldata import *

from tornado.gen import coroutine, sleep, Return
from tornado.ioloop import PeriodicCallback

import re
import math
import copy
import random
import functools
from collections import namedtuple, defaultdict

TESTINQUICK = False

CraftRoleInfo = namedtuple('CraftRoleInfo', ('roleKey', 'recordID', 'name', 'logo', 'level', 'round', 'win', 'point', 'rank'))
# roles = ((servKey1, roleID1), (servKey2, roleID2)), points = (point1, point2)
CraftResultInfo = namedtuple('CraftResultInfo', ('playID', 'roles', 'result', 'points', 'date'))


class RemoteCrossCraftRecord(RemoteObject):
	pass

class ObjectMemDB(ObjectDicAttrs):
	@property
	def db(self):
		return self._dic


#
# ObjectCrossCraftServiceGlobal
#

class ObjectCrossCraftServiceGlobal(ObjectDBase):
	DBModel = 'CrossCraftServiceGlobal'

	Singleton = None

	Top8PlayKeyMap = {
		(1, 8): 1,
		(2, 7): 2,
		(3, 6): 3,
		(4, 5): 4,

		(27, 36): 5,
		(18, 45): 6,

		(1845, 2736): 7,
	}
	Top8PlayKeyRound = [
		[(1, 8), (2, 7), (3, 6), (4, 5)],
		[(27, 36), (18, 45)],
		[(1845, 2736)],
	]
	EmptyRoleKey = ('~empty~', 0)

	MinBetRate = 0
	BetRateFix = 0

	@classmethod
	def classInit(cls):
		cfg = csv.cross.craft.base[1]
		cls.MinBetRate = cfg.minBetRate
		cls.BetRateFix = cfg.betRateFix

	def __init__(self, dbc):
		ObjectDBase.__init__(self, None, dbc)

		if ObjectCrossCraftServiceGlobal.Singleton is not None:
			raise ValueError('This is singleton object')
		ObjectCrossCraftServiceGlobal.Singleton = self

	def init(self, server):
		self.server = server

		self.classInit()

		# DB?????????list??????????????????namedtuple
		craft_roles = {}
		for k, v in self.last_craft_roles.iteritems():
			craft_roles[k] = CraftRoleInfo(*v)
		self.craft_roles = craft_roles
		signup = {}
		for k, v in self.signup.iteritems():
			signup[k] = RoleSignItem(*v)
		self.signup = signup
		# ???????????????????????????
		self.top8_plays = {}
		self.round_results = {}

		self._queryAgentMgrTimer = None
		self.cleanCache()

		return ObjectDBase.init(self)

	def isAllOver(self):
		if self.date == 0:
			return True
		delta = nowdate_t() - int2date(self.date)
		return delta > OneDay

	def cleanCache(self):
		if self._queryAgentMgrTimer:
			self._queryAgentMgrTimer.stop()

		self._betSum = sum([sum(d['gold'].values()) for d in self.bet2.itervalues()])
		self._queryAgentMgrTimer = None

		self._rankCache = [] # ?????????
		self._resultCache = defaultdict(lambda: [0, 0, 0]) # ???????????? {role key: (win, failed, point)}

		self._syncModel = {} # ????????????
		self._roleMatchHistory = {} #???????????????

		self._gamePvpMap = {} # game key - pvp key

		self._playStatus = 'finished'
		self._playMap = {} # {playID: rr}
		self._playCache = {} # {playID: play model}
		self._playGetRecording = set() # {playID} ?????????record
		self._roleCardsFightPoint = {} # {roleKey: top12_cards sum fight point} bet2???
		self._lastMatchDispathes = {} # matches????????????
		self._lastOutDispathes = {} # out??????????????????

	def clean(self):
		self.servers = []
		self.csv_id = 0
		self.date = 0
		self.play_id = 1
		self.round = 'closed'
		self.signup = {}
		self.craft_roles = {}
		self.last_craft_roles = {}
		self.bet2 = {}
		self.top8_plays = {}
		self.round_results = {}

		self.cleanCache()

	def reset(self, csvID, servers):
		self.clean()
		self.csv_id = csvID
		self.servers = servers
		self.date = todaydate2int()

	def resetToday(self):
		logger.info('ObjectCrossCraftServiceGlobal.resetToday %d %d %s', todaydate2int(), self.date, self.round)

		def resetSecondDay():
			if self.round == 'closed':
				# ??????db???mem
				self.clean()

				# cross????????????
				from cross.object.gglobal import ObjectCrossGlobal
				ObjectCrossGlobal.initServiceState('craft')
				return

			self.round = 'halftime'
			# ????????????????????????
			delta = datetime.datetime.combine(int2date(self.date), CraftRoundNextMap['prepare2'].time) + OneDay - nowdatetime_t()
			logger.info('round %s next %s time delta %s', self.round, 'prepare2', delta)
			self.server.ioloop.add_timeout(delta, self.onStartPrepare2)

		# ???????????????
		if todaydate2int() == self.date:
			# ????????????????????????????????????????????????????????????????????????
			if self.round == 'halftime':
				resetSecondDay()
				return

			self.round = 'signup'
			if nowdtime_t() < CraftRoundNextMap['signup'].time:
				self.onInit(self.servers)
			elif nowdtime_t() < CraftRoundNextMap['prepare'].time:
				self.onStartSignUp()
			else:
				self.onStartPrepare()

		# ???????????????
		else:
			resetSecondDay()

		# ???????????????rank cache
		self.refreshRankCache()
		# ??????game????????????
		self.initToGame()

	@property
	def slim_bet2(self):
		return {k: {
			'info': d['info'],
			'rank': d['rank'],
			'rate': d['rate'],
			'gold_sum': d.get('gold_sum', 0), # in dev
			'fight': d['fight'],
		} for k, d in self.bet2.iteritems()}

	def dbForGame(self, gameKey):
		self._syncModel[gameKey] = {}
		return {
			'servers': self.servers,
			'csv_id': self.csv_id,
			'date': self.date,
			'time': self.time,
			'round': self.round,
			'signup_size': len(self.signup),
			'bet2': self.slim_bet2,
			'top8_plays': self.top8_plays,

			'matches': self._lastMatchDispathes.get(gameKey, None),
			'outs': self._lastOutDispathes.get(gameKey, None),
		}

	def syncModel(self, gameKey):
		model = {
			'time': self.time,
			'round': self.round,
			'signup_size': len(self.signup),
			'bet2': self.slim_bet2,
			'top8_plays': self.top8_plays,
		}
		sync = self._syncModel.pop(gameKey, None)
		if sync is None:
			return {'model': model}
		self._syncModel[gameKey] = {}
		return {'model': model, 'sync': sync}

	def initToGame(self):
		result = {}
		for gameKey in self.servers:
			result[gameKey] = self.server.client(gameKey).call_async('crossCraftInit', self.dbForGame(gameKey))
		return multi_future(result)

	def syncToGame(self):
		result = {}
		for gameKey in self.servers:
			result[gameKey] = self.server.client(gameKey).call_async('crossCraftSync', self.syncModel(gameKey))
		return multi_future(result)

	def eventAndDBToGame(self, event):
		result = {}
		for gameKey in self.servers:
			result[gameKey] = self.server.client(gameKey).call_async('crossCraftEvent', event, self.dbForGame(gameKey), None)
		return multi_future(result)

	def eventToGame(self, event, data, sync=True):
		result = {}
		for gameKey in self.servers:
			result[gameKey] = self.server.client(gameKey).call_async('crossCraftEvent', event, data, self.syncModel(gameKey) if sync else None)
		return multi_future(result)

	def eventToSomeGame(self, event, d, sync=True):
		result = {}
		for gameKey, data in d.iteritems():
			result[gameKey] = self.server.client(gameKey).call_async('crossCraftEvent', event, data, self.syncModel(gameKey) if sync else None)
		return multi_future(result)

	def getHistory(self, roleKey):
		if roleKey not in self.signup:
			return
		info = self.signup[roleKey]
		return info.history

	def getPlay(self, playID):
		return self._playCache.get(playID, None)

	def betRole(self, myKey, roleKey, gold):
		if roleKey not in self.bet2:
			return False
		bet = self.bet2[roleKey]
		bet['gold'][myKey] = gold
		self._betSum += gold
		betSum = 0
		for _, d in self.bet2.iteritems():
			goldSum = sum(d['gold'].itervalues())
			d['gold_sum'] = goldSum
			betSum += goldSum
			if goldSum > 0:
				rate = 1.0 * self._betSum * self.BetRateFix / goldSum
				d['rate'] = max(self.MinBetRate, rate)
			else:
				d['rate'] = self.MinBetRate
		self._betSum = betSum
		return True

	@coroutine
	def onInit(self, csvID, servers):
		logger.info('ObjectCrossCraftServiceGlobal.onInit')
		self.reset(csvID, servers)

		yield self.initToGame()

		# ?????????????????????
		delta = timeSubTime(CraftRoundNextMap['signup'].time, nowdtime_t())
		logger.info('round %s next %s time delta %s', self.round, 'signup', delta)
		self.server.ioloop.add_timeout(delta, self.onStartSignUp)

	# ???????????? closed -> signup
	@coroutine
	def onStartSignUp(self):
		logger.info('ObjectCrossCraftServiceGlobal.onStartSignUp')

		self.round = 'signup'
		yield self.eventAndDBToGame('signup')

		# ?????????????????????
		delta = timeSubTime(CraftRoundNextMap['prepare'].time, nowdtime_t())
		if TESTINQUICK:
			delta = datetime.timedelta(seconds=5)
		logger.info('round %s next %s time delta %s', self.round, 'prepare', delta)
		self.server.ioloop.add_timeout(delta, self.onStartPrepare)

	# game????????????
	def onGameSignUpSync(self, nodeKey, signup):
		for roleID, info in signup.iteritems():
			roleKey = (nodeKey, roleID)
			self.signup[roleKey] = RoleSignItem(*info)

	# ???????????? signup -> prepare
	@coroutine
	def onStartPrepare(self):
		if self.round == 'signup':
			self.round = 'prepare'
		else:
			logger.warning('error round %s enter in onStartPrepare', self.round)
			raise Return(None)

		logger.info('ObjectCrossCraftServiceGlobal.onStartPrepare %s', self.round)

		# ???????????????????????????
		prepareOK = False
		while not prepareOK:
			try:
				signups = yield self.eventAndDBToGame('prepare')
				for key, signup in signups.iteritems():
					self.onGameSignUpSync(key, signup)
					logger.info('%s signup %d in prepare, all signup %d', key, len(signup), len(self.signup))
				prepareOK = True
			except:
				logger.exception('prepare error')

		# ????????????history, prepare2?????????
		for roleKey in self.signup:
			self.updSignUpRoleInfo(roleKey, history=[])

		yield self._initPrepare()

	# ?????????????????? halftime -> prepare2
	@coroutine
	def onStartPrepare2(self):
		if self.round == 'halftime':
			self.round = 'prepare2'
		else:
			logger.warning('error round %s enter in onStartPrepare2', self.round)
			raise Return(None)

		logger.info('ObjectCrossCraftServiceGlobal.onStartPrepare2 %s', self.round)

		# ????????????
		yield self.eventAndDBToGame('prepare2')
		yield self._initPrepare()

	@coroutine
	def _initPrepare(self):
		# ??????????????????
		self._playCache = {}

		# ??????????????????, pvp??????db????????????
		roleInfos, roleMatches, roleOuts = yield self.pvpPrepare()

		if self.round == 'prepare':
			if len(roleInfos) != len(self.signup):
				dels = set(self.signup.keys()) - set(roleInfos.keys())
				# record?????????????????????
				for roleKey in dels:
					self.signup.pop(roleKey)
		else:
			for roleKey in roleOuts:
				# ???????????????????????????
				self.updSignUpRoleInfo(roleKey, isOut=True)

		for roleKey, d in roleInfos.iteritems():
			self.updSignUpRoleInfo(roleKey, top12_cards=d['cards'], isOut=False)

		# ???????????????
		matches = self._makeMatchHistory(roleMatches)
		yield self.eventToSomeGame('matches', matches)

		# ?????????????????????, pre11, pre31
		delta = timeSubTime(datetime.time(hour=19), nowdtime_t())
		if TESTINQUICK:
			delta = datetime.timedelta(seconds=5)
		logger.info('round %s next %s time delta %s', self.round, ('pre11', 'pre31'), delta)
		self.server.ioloop.add_timeout(delta, self.onStartRound)

	@coroutine
	def _getRemoteCraftRecord(self, roleKey, recordID, timeout=20):
		servKey, roleID = roleKey
		pvpKey = self._getPVPKey(servKey)
		recordD = yield self.server.client(pvpKey).call_async_timeout('getCrossCraftRecord', timeout, roleID, recordID)
		recordObj = RemoteCrossCraftRecord(None, recordD) # record?????????
		raise Return(recordObj)

	def _getPVPKey(self, servKey):
		if servKey not in self._gamePvpMap:
			domains = node_key2domains(servKey)
			domains[0] = 'pvp'
			self._gamePvpMap[servKey] = node_domains2key(domains)
		return self._gamePvpMap[servKey]

	@coroutine
	def sendHistoryToPVP(self, timeout=20):
		fus = {}
		for roleKey, info in self.signup.iteritems():
			servKey, roleID = roleKey
			pvpKey = self._getPVPKey(servKey)
			fus[roleKey] = self.server.client(pvpKey).call_async_timeout('saveCraftHistory', timeout, roleID, info.cross_craft_record_db_id, info.history)
		yield multi_future(fus)


	# like `startCraftPrepare`
	@coroutine
	def pvpPrepare(self):
		# ???game????????????????????????pvp??????
		signList = {}

		# ??????????????????
		if self.round == 'prepare':
			playerList = {roleKey: info.cross_craft_record_db_id for roleKey, info in self.signup.iteritems()}
		else:
			playerList, failList = self.nextRoundPlayer('pre31')

		# ????????????craft_ranks??????????????????????????????
		for roleKey, recordID in playerList.iteritems():
			try:
				recordObj = yield self._getRemoteCraftRecord(roleKey, recordID)
			except:
				# ????????????Record??????????????????
				logger.exception("role %s cross craft record %d read error", roleKey, recordID)
				continue

			# ?????????????????????
			if recordObj is None or len(recordObj.card_attrs) == 0:
				logger.warning("role %s cross craft record %d card_attrs empty", roleKey, recordID)
				continue

			if self.round == 'prepare':
				self.addCraftRoleInfo(recordObj)

			signList[roleKey] = {
				'cards': recordObj.cards,
			}

		if self.round == 'prepare':
			# ??????
			matchList = self.initRoundMatch(signList.keys())
			failList = set()
		else:
			# ??????signList???????????????
			signList, matchList, failList = self.nextRoundMatch('pre31', signList, failList)
			# {roleKey: failed cnt} -> {out roleKey}
			# ?????????top64??????????????????????????????
			failList = set(self.signup.keys()) - set(failList.keys())

		# ?????????????????????
		if self._queryAgentMgrTimer:
			self._queryAgentMgrTimer.stop()
		self._queryAgentMgrTimer = PeriodicCallback(self._queryAgentMgr, 2500.)

		# ??????agent
		self.server.antiMgr.checkAllAgents()

		# ????????????
		yield self.save_async()
		logger.info('ObjectCrossCraftServiceGlobal.pvpPrepare %s SignUp %d Roles %d Matches %d Outs %d', self.round, len(self.signup), len(signList), len(matchList), len(failList))

		raise Return((signList, matchList, failList))

	def updSignUpRoleInfo(self, roleKey, **kwargs):
		item = self.signup.get(roleKey, None)
		if item is None:
			return
		self.signup[roleKey] = item._replace(**kwargs)

	def addCraftRoleInfo(self, record):
		roleKey = (record.serv_key, record.role_db_id)
		self.craft_roles[roleKey] = CraftRoleInfo(roleKey, record.id, record.role_name, record.role_logo, record.role_level, 0, 0, 0, 0)

	def updateCraftRoleInfo(self, roleKey, result=None, point=None, rank=None):
		info = self.craft_roles[roleKey]

		# ?????????????????????
		if result:
			roundMax = 4 + 4 + 4 + 3 + 3
			if result == 'win':
				self.craft_roles[roleKey] = info._replace(round=min(info.round + 1, roundMax), win=info.win + 1, point=info.point + point)
			else:
				self.craft_roles[roleKey] = info._replace(round=min(info.round + 1, roundMax), point=info.point + point)

		if rank:
			self.craft_roles[roleKey] = info._replace(rank=rank)

	def _makeMatchHistory(self, roleMatches):
		# vsRoleID=None???????????????roleID??????
		round = self.round
		if self.round[:8] == 'prepare2':
			round = 'pre31'
		elif self.round[:7] == 'prepare':
			round = 'pre11'

		self._roleMatchHistory = {
			roleKey: {
				'round': round,
				'info': self.signup[roleKey],
				'vsid': vsRoleKey,
				'vsinfo': self.signup[vsRoleKey] if vsRoleKey else None,
				'play': 0,
				'result': 'unknown' if vsRoleKey else 'win',
				'point': 0,
			} for roleKey, vsRoleKey in roleMatches.iteritems()
		}
		# ????????????game
		dispatches = defaultdict(dict)
		for roleKey, d in self._roleMatchHistory.iteritems():
			servKey, _ = roleKey
			dispatches[servKey][roleKey] = d
		self._lastMatchDispathes = dispatches
		return dispatches

	def _makeRandomMatch(self, roleKeys):
		random.shuffle(roleKeys)
		matchs = zip(roleKeys[::2], roleKeys[1::2])

		# ??????????????????
		if len(roleKeys) % 2 == 1:
			return matchs, roleKeys[-1]
		return matchs, None

	def initRoundMatch(self, roleKeys):
		# prepapre -> pre11
		# ?????????round_results
		vsResult = {}

		matchs, leftRoleKey = self._makeRandomMatch(roleKeys)
		matchList = {r1: r2 for r1, r2 in matchs}
		matchList.update({r2: r1 for r1, r2 in matchs})
		# ??????????????????
		if leftRoleKey:
			matchList[leftRoleKey] = None
			vsResult[leftRoleKey] = self.EmptyRoleKey

		for r1, r2 in matchs:
			vsResult[min(r1, r2)] = max(r1, r2)
		self.round_results['pre11'] = vsResult
		return matchList

	# ???????????????????????? (pre1, pre2, ..., final3)
	@coroutine
	def onStartRound(self):
		nextRound = CraftRoundNextMap[self.round].next

		# ??????????????????, pvp??????db????????????
		# pre11???pre31??????????????????onStartPrepare???????????????????????????None
		roleInfos, roleMatches, roleOuts = yield self.pvpStartRound(nextRound)
		# ????????????????????????????????????
		# ??????yield????????????????????????????????????????????????
		self.round = nextRound

		logger.info('ObjectCrossCraftServiceGlobal.onStartRound %s', self.round)

		if roleInfos:
			# NOTICE: ??????roleInfos?????????????????????????????????????????????
			# roleOuts?????????????????????
			for roleKey in roleOuts:
				self.updSignUpRoleInfo(roleKey, isOut=True)

			# history?????????pushPlayResultToGame
			for roleKey, d in roleInfos.iteritems():
				self.updSignUpRoleInfo(roleKey, top12_cards=d['cards'], isOut=False)

			# ???????????????
			matches = self._makeMatchHistory(roleMatches)

			# ?????????game????????????top8_plays
			yield self.eventToSomeGame('matches', matches)

		else:
			# prepare????????????matches?????????????????????round
			self.syncToGame()

		# ????????????????????????????????????
		delta = datetime.timedelta(minutes=3 if self.isInTopOrFinal() else 2)
		if TESTINQUICK:
			delta = datetime.timedelta(seconds=5)
		self.server.ioloop.add_timeout(delta, self.onPlayStart)
		delta = datetime.timedelta(minutes=5 if self.isInTopOrFinal() else 4)
		if TESTINQUICK:
			delta = datetime.timedelta(seconds=5)
		self.server.ioloop.add_timeout(delta, self.onPlayEnd)

	# like `startCraftRound`
	@coroutine
	def pvpStartRound(self, round):
		if self.getCurrentMatchedRound() == round:
			raise Return((None, None, None))

		# ??????????????????????????????
		if self._queryAgentMgrTimer:
			self._queryAgentMgrTimer.stop()

		# ??????????????????
		playerList, failList = self.nextRoundPlayer(round)

		signList = {}
		# ????????????cards??????
		for roleKey, recordID in playerList.iteritems():
			try:
				recordObj = yield self._getRemoteCraftRecord(roleKey, recordID)
			except:
				# ????????????Record??????????????????
				logger.exception("role %s craft record %d read error", roleKey, recordID)
				continue

			signList[roleKey] = {
				'cards': recordObj.cards,
			}

		# ??????signList???????????????
		signList, matchList, failList = self.nextRoundMatch(round, signList, failList)

		# {roleKey: failed cnt} -> {out roleKey}
		failList = {roleKey for roleKey, fail in failList.iteritems() if fail >= 5}

		# ??????agent
		self.server.antiMgr.checkAllAgents()

		# ????????????
		yield self.save_async()
		logger.info('ObjectCrossCraftServiceGlobal.pvpStartRound %s Roles %d Matches %d Outs %d', round, len(signList), len(matchList), len(failList))

		raise Return((signList, matchList, failList))

	def getCurrentMatchedRound(self):
		if len(self.round_results) == 0:
			return None
		rounds = sorted(self.round_results.keys(), key=lambda k: CraftRoundNextMap[k].idx)
		return rounds[-1]

	def getCurrentRoundResult(self):
		return self.round_results.get(self.round, None)

	def nextRoundPlayer(self, round):
		if round[:3] == 'pre':
			return self._nextPreRoundPlayer(round)
		elif round[:3] == 'top' or round[:5] == 'final':
			return self._nextTopAndFinalRoundPlayer(round)

	def nextRoundMatch(self, round, signList, failList):
		if round[:3] == 'pre':
			return self._nextPreRoundMatch(round, signList, failList)
		elif round[:3] == 'top' or round[:5] == 'final':
			return self._nextTopAndFinalRoundMatch(round, signList, failList)

	@staticmethod
	def calcNextTop8PlayKey(key1, key2):
		if key1 > key2:
			key1, key2 = key2, key1
		carry = lambda x: int(math.pow(10, 1 + int(math.log10(x))))
		return key1 * carry(key2) + key2

	def _getTop64(self):
		# ?????????????????????????????????????????????64???????????????64?????????
		roleWPs = sorted(self.craft_roles.items(), key=lambda t: (t[1].win, t[1].point), reverse=True)
		return [t[0] for t in roleWPs[:64]]

	def _getFightPointTop64(self):
		# ??????top12??????????????????bet2????????????
		roleFights = sorted(self._roleCardsFightPoint.items(), key=lambda t: t[1], reverse=True)
		return [t[0] for t in roleFights]

	def refreshRankCache(self):
		ranks = sorted(self.craft_roles.values(), key=lambda t: (t.round, t.win, t.point), reverse=True)
		# ???(round, win, point)?????????????????????(win, point)
		# ('roleID', 'logo', 'name', 'level', 'vip_level', 'union_name')
		cache = []
		for rank, craftInfo in enumerate(ranks, 1):
			roleKey = tuple(craftInfo.roleKey)
			signInfo = self.signup[roleKey]
			cache.append((
				roleKey,
				craftInfo.logo,
				craftInfo.name,
				craftInfo.level,
				signInfo.vip_level,
				signInfo.unionName,
				(craftInfo.win, craftInfo.point),
				craftInfo.recordID,
			))
			self.updateCraftRoleInfo(roleKey, rank=rank)
		self._rankCache = cache
		return self._rankCache

	def _nextTopAndFinalRoundPlayer(self, round):
		'''
		Top64, 32, 16:
		T0 T1 T2 T3 T4 T5 T6 T7
		1  2  3  4  5  6  7  8
		16 15 14 13 12 11 10 9
		...
		64 63 62 61 60 59 58 57
		??????8?????????????????????8????????????????????????????????????8??????
		'''
		# Player???Match???????????????????????????
		self._top8Map = defaultdict(dict) # {team8key: {top8key: roleKey}}
		playerList = {}
		playerFails = {} # {roleKey: failed cnt} ????????????
		# ?????????_top8Map????????????????????????top64????????????????????????
		roundIdx = CraftRoundNextMap[round].roundIdx
		idx = roundIdx - 1
		if idx == 0:
			if round == 'top64':
				topRoles = self._getTop64()
				for rank, roleKey in enumerate(topRoles):
					tRank = int(rank / 8)
					tIdx = rank % 8 if tRank % 2 == 0 else 7 - rank % 8
					self._top8Map['t%d' % tIdx][tRank + 1] = roleKey
			else:
				# 8????????????64???32, 16???????????????
				teamChampions = [d[7]['roles'][0 if d[7]['result'].result == 'win' else 1] for _, d in self.top8_plays.iteritems()]
				topRoles = sorted(teamChampions, key=lambda k: (self.craft_roles[k].win, self.craft_roles[k].point), reverse=True)
				finalTop8 = {}
				for rank, roleKey in enumerate(topRoles, 1):
					finalTop8[rank] = roleKey
				self._top8Map['final'] = finalTop8

		else:
			# ?????????????????????????????????
			preIdx = idx - 1
			topRoles = [] # ?????????????????????
			if round[:3] == 'top':
				teamKeys = ['t%d' % i for i in xrange(8)]
			else:
				teamKeys = ['final']
			for teamKey in teamKeys:
				for kk in self.Top8PlayKeyRound[preIdx]:
					key = self.Top8PlayKeyMap[kk]
					# ????????????64?????????????????????
					if key in self.top8_plays[teamKey]:
						info = self.top8_plays[teamKey][key]['result']
						winRoleKey = info.roles[0 if info.result == 'win' else 1]
						topRoles += info.roles
					else:
						winRoleKey = self.EmptyRoleKey
					self._top8Map[teamKey][self.calcNextTop8PlayKey(*kk)] = winRoleKey

		playerFails = {tuple(r): 5 for r in topRoles} # ????????????????????????????????????
		for teamKey, d in self._top8Map.iteritems():
			for key, roleKey in d.iteritems():
				if roleKey[1] > 0:
					playerList[roleKey] = self.craft_roles[roleKey].recordID # ????????????recordID
					playerFails[roleKey] = 0 # 0???????????????

		logger.info('top players from %s %s', self.round, [(r, self.craft_roles[r].win, self.craft_roles[r].point) for r in topRoles])
		logger.info('fail players %s', [k for k, v in playerFails.iteritems() if v >= 5])

		# ???????????????top8_plays??????
		top8KeyMap = {} # {rr: (teamkey, top8key)}
		for teamKey, d in self._top8Map.iteritems():
			for kk in self.Top8PlayKeyRound[idx]:
				r1, r2 = d[kk[0]], d[kk[1]]
				key = min((r1, r2), (r2, r1))
				top8KeyMap[key] = (teamKey, self.Top8PlayKeyMap[kk])
				# ??????role1???role2?????? role1.id < role2.id
				if teamKey not in self.top8_plays:
					self.top8_plays[teamKey] = {}
				self.top8_plays[teamKey][self.Top8PlayKeyMap[kk]] = {
					'role1': self.craft_roles.get(key[0], self.EmptyRoleKey),
					'role2': self.craft_roles.get(key[1], self.EmptyRoleKey),
				}

		# top8Map???????????????????????????key
		self._top8Map = top8KeyMap
		return playerList, playerFails

	def _nextTopAndFinalRoundMatch(self, round, signList, failList):
		# ????????????????????????12????????????????????????????????????
		matchList = {}
		# ?????????round_results
		vsResult = {}
		# ???????????? _top8Map {rr: (teamkey, top8key)}
		for rr in self._top8Map:
			r1, r2 = rr
			# ??????????????????
			if r1 == self.EmptyRoleKey:
				pass
			# ????????????????????????
			elif r2 == self.EmptyRoleKey:
				vsResult[r1] = self.EmptyRoleKey
				matchList[r1] = None
			else:
				vsResult[r1] = r2
				matchList[r1], matchList[r2] = r2, r1
		self.round_results[round] = vsResult
		return signList, matchList, failList

	def _nextPreRoundPlayer(self, round):
		playerList = {}
		playerFails = {} # {roleKey: failed cnt} ???????????????????????????????????????
		# ?????????????????????????????????????????????????????????
		# self.round?????????????????????
		roundTotal = CraftRoundNextMap[round].roundIdx - 1
		self._winRoleMap = defaultdict(list)
		for roleKey, info in self.craft_roles.iteritems():
			if roundTotal - info.win < 5:
				self._winRoleMap[info.win].append(roleKey)
				playerList[roleKey] = self.craft_roles[roleKey].recordID # ????????????recordID
			playerFails[roleKey] = roundTotal - info.win
		return playerList, playerFails

	def _nextPreRoundMatch(self, round, signList, failList):
		# ???????????????????????????
		# NOTICE: ???????????????????????????4????????????????????????
		emptyRoles = set()
		roundTotal = CraftRoundNextMap[round].roundIdx - 1
		for roleKey in signList:
			d = signList[roleKey]
			# ????????????????????????3V3
			cardIdx = (roundTotal * 3) % 12
			# ??????????????????????????????
			if d['cards'][cardIdx][0] == 0:
				emptyRoles.add(roleKey)
				failList[roleKey] += 1

		if emptyRoles:
			# ???????????????????????????????????????
			for win in self._winRoleMap:
				self._winRoleMap[win] = [r for r in self._winRoleMap[win] if r not in emptyRoles]

		matchList = {}
		# ?????????round_results
		vsResult = {}
		# ?????????????????????????????????????????????????????????????????????????????????????????????
		for win in sorted(self._winRoleMap.keys(), reverse=True):
			roleKeys = self._winRoleMap[win]
			matchs, leftRoleKey = self._makeRandomMatch(roleKeys)
			# ????????????????????????????????????????????????????????????????????????
			# ????????????????????????????????????????????????
			if leftRoleKey:
				finded, i = False, win - 1
				while i >= 0:
					nextRoleKeys = self._winRoleMap.get(i, None)
					i -= 1
					if nextRoleKeys:
						idx = random.randint(0, len(nextRoleKeys) - 1)
						matchs.append((leftRoleKey, nextRoleKeys.pop(idx)))
						finded = True
						break
				# ???????????????????????????
				if not finded:
					matchList[leftRoleKey] = None
					vsResult[leftRoleKey] = self.EmptyRoleKey
			matchList.update({r1: r2 for r1, r2 in matchs})
			matchList.update({r2: r1 for r1, r2 in matchs})
			for r1, r2 in matchs:
				vsResult[min(r1, r2)] = max(r1, r2)
		self.round_results[round] = vsResult
		return signList, matchList, failList


	# ???????????????????????? (pre1, ..., final3)
	@coroutine
	def onPlayStart(self):
		logger.info('ObjectCrossCraftServiceGlobal.onPlayStart %s', self.round)

		self.initPlay()

		# ????????????
		yield self.eventToGame('play', None)

		# ??????pvp??????, like `runCraftRound`
		roundResult = self.getCurrentRoundResult()
		playsCount = len(roundResult) if roundResult else 0
		logger.info('ObjectCrossCraftServiceGlobal.onPlayStart Plays %d', playsCount)

		# game???????????????????????????????????????????????????????????????
		if roundResult:
			self.server.ioloop.add_timeout(datetime.timedelta(seconds=1), self._makePlayAndRun)
			self._queryAgentMgrTimer.start()

	@coroutine
	def _makePlayAndRun(self):
		# roundResult[roleKey1] = roleID2 ???????????????PlayRecord???
		roundResult = self.getCurrentRoundResult()

		if roundResult is None:
			logger.warning('CurrentRoundResult Empty %s %s', self.round_results.keys(), self.round)
			raise Return(None)
		roundResult = copy.deepcopy(roundResult)
		startDT = nowdatetime_t()
		playsCount = 0

		def recordBack(roleKey1, roleKey2, fu):
			try:
				ret = fu.result()
				recordObj1, recordObj2 = ret['obj1'], ret.get('obj2', None)
				# ??????
				if recordObj2 is None:
					model = self.getByePlayModel(recordObj1)
					cards1, point1 = model['cards'], model['point']
					self.newPlay(0, (roleKey1, self.EmptyRoleKey), None)
					self.recordPlayResult(0, 'win', (point1, 0))
					# ?????????game???????????????
					self.pushPlayResultToGame(model)

				else:
					rr = (roleKey1, roleKey2)
					model = self.getPlayModel(recordObj1, recordObj2)
					self.newPlay(model['cross_id'], rr, model)
					# ????????????????????????????????????future?????????????????????
					self.server.antiMgr.sendCraftPlay(ObjectMemDB(model))
			finally:
				self._playGetRecording.discard((roleKey1, roleKey2))

		allFus = {}
		# roleKey1 < roleKey2 or roleKey2 == EmptyRoleKey
		for roleKey1, roleKey2 in roundResult.iteritems():
			# ????????????PlayRecord??????value???RoleKey???????????????CraftResultInfo
			if len(roleKey2) != 2:
				continue
			# ????????????Record???
			if (roleKey1, roleKey2) in self._playGetRecording:
				continue

			fud = {}
			info1 = self.craft_roles[roleKey1]
			fud['obj1'] = self._getRemoteCraftRecord(roleKey1, info1.recordID)
			if roleKey2 != self.EmptyRoleKey:
				info2 = self.craft_roles[roleKey2]
				fud['obj2'] = self._getRemoteCraftRecord(roleKey2, info2.recordID)
			playsCount += 1
			fu = multi_future(fud)
			fu.add_done_callback(functools.partial(recordBack, roleKey1, roleKey2))
			allFus[len(allFus)] = fu
			self._playGetRecording.add((roleKey1, roleKey2))

		# ??????????????????
		yield multi_future(allFus)
		try:
			self.makePlayEnd()
			self.checkPlayEnd()
		except:
			# ????????????????????????????????????
			self.server.ioloop.add_timeout(datetime.timedelta(seconds=1), self._makePlayAndRun)
		finally:
			logger.info('_makePlayAndRun %d make %d play cost %s', len(roundResult), playsCount, nowdatetime_t() - startDT)

	def initOutCache(self):
		self._lastOutDispathes = defaultdict(dict)
		for roleKey, info in self.signup.iteritems():
			self._lastOutDispathes[roleKey[0]][roleKey[1]] = info.isOut

	def initPlay(self):
		self._playStatus = 'continue'
		self._playMap = {}
		self._playGetRecording = set()
		self.initOutCache()
		# self._playCache = {}
		# self.play_id = 1

	def makePlayEnd(self):
		if self._playStatus != 'finished':
			self._playStatus = 'make_play_end'

	def isFirstMakeEnd(self):
		return self._playStatus in ('make_play_end', 'finished')

	def calcPlayCards(self, record):
		roundIdx = CraftRoundNextMap[self.round].roundIdx - 1
		cardL = [(0, 0, 0)] * 12
		# (RoleCard.id, RoleCard.card_id, skin_id)
		cardIdx = (roundIdx * 3) % 12
		cardT = record.cards[cardIdx]
		# ???????????????????????????
		if cardT[0] == 0:
			return cardL, {}
		cardD = {}
		for i in xrange(3):
			idx = cardIdx + i
			cardL[idx] = record.cards[idx]
			cardID = cardL[idx][0]
			if cardID == 0:
				break
			cardD[cardID] = record.card_attrs[cardID]
		# ????????????12??????????????????
		if CraftRoundNextMap[self.round].idx < 28: # until halftime
			self._roleCardsFightPoint[(record.serv_key, record.role_db_id)] = sum([d.get('fighting_point', 0) for k, d in record.card_attrs.iteritems()])
		return cardL, cardD

	def getByePlayModel(self, record1):
		cards1, cardAttrs1 = self.calcPlayCards(record1)
		# ?????????????????????hp?????????
		point1 = 0
		if cardAttrs1:
			point1 = int(cardAttrs1[cardAttrs1.keys()[0]]['attrs']['hp'] / 1000.0)
		return {
			'id': 0,
			'cross_id': 0,
			'date': self.date,

			'result': 'win',
			'point': point1,
			'defence_point': 0,

			'round': self.round,
			'rand_seed': 1,

			'role_key': (record1.serv_key, record1.role_db_id),
			'record_db_id': record1.id,
			'name': record1.role_name,
			'logo': record1.role_logo,
			'level': record1.role_level,
			'cards': cards1,
			'card_attrs': cardAttrs1,
			'talents': record1.talents,

			'defence_role_key': self.EmptyRoleKey,
			'defence_record_db_id': 0,
			'defence_name': '',
			'defence_logo': 0,
			'defence_level': 0,
			'defence_cards': [],
			'defence_card_attrs': {},
			'defence_talents': {},
		}

	def getPlayModel(self, record1, record2):
		playID = self.play_id
		self.play_id += 1
		cards1, cardAttrs1 = self.calcPlayCards(record1)
		cards2, cardAttrs2 = self.calcPlayCards(record2)
		return {
			'id': playID, # cross???ID???????????????DB ID
			'cross_id': playID,
			'date': self.date,

			'round': self.round,
			'rand_seed': random.randint(1, 99999999),

			'role_key': (record1.serv_key, record1.role_db_id),
			'record_db_id': record1.id,
			'name': record1.role_name,
			'logo': record1.role_logo,
			'level': record1.role_level,
			'cards': cards1,
			'card_attrs': cardAttrs1,
			'talents': record1.talents,

			'defence_role_key': (record2.serv_key, record2.role_db_id),
			'defence_record_db_id': record2.id,
			'defence_name': record2.role_name,
			'defence_logo': record2.role_logo,
			'defence_level': record2.role_level,
			'defence_cards': cards2,
			'defence_card_attrs': cardAttrs2,
			'defence_talents': record2.talents,
		}

	def isInTopOrFinal(self):
		return self.round[:5] == 'final' or self.round[:3] == 'top'

	def newPlay(self, playID, rr, playModel):
		info = CraftResultInfo(playID, rr, 'unknown', (0, 0), self.date)
		self.round_results[self.round][rr[0]] = info
		self._playMap[playID] = (tuple(rr[0]), tuple(rr[1])) # tuple???list??????????????????False
		self._playCache[playID] = playModel

		# ??????top8_plays??????
		if playModel and self.isInTopOrFinal():
			teamKey, key = self._top8Map[rr] # {rr: top8key}
			roleKey1, roleKey2 = playModel['role_key'], playModel['defence_role_key']
			self.top8_plays[teamKey][key] = {
				'roles': (roleKey1, roleKey2),
				'role1': self.craft_roles[roleKey1],
				'role2': self.craft_roles[roleKey2],
				'result': None,
				'cards1': playModel['cards'],
				'cards2': playModel['defence_cards'],
				'info1': self.slimSignInfo(roleKey1),
				'info2': self.slimSignInfo(roleKey2),
				'fight1': sum([d.get('fighting_point', 0) for k, d in playModel['card_attrs'].iteritems()]), # ????????????????????????
				'fight2': sum([d.get('fighting_point', 0) for k, d in playModel['defence_card_attrs'].iteritems()]),
			}

	def recordPlayResult(self, playID, result, points):
		rr = self._playMap.pop(playID, None)
		if rr is None:
			return None

		self._resultCache[rr[0]][0 if result == 'win' else 1] += 1
		self._resultCache[rr[0]][2] += points[0]
		self.updateCraftRoleInfo(rr[0], result, points[0])
		if rr[1] != self.EmptyRoleKey:
			self._resultCache[rr[1]][1 if result == 'win' else 0] += 1
			self._resultCache[rr[1]][2] += points[1]
			self.updateCraftRoleInfo(rr[1], 'fail' if result == 'win' else 'win', points[1])

		info = CraftResultInfo(playID, rr, result, points, self.date)
		self.round_results[self.round][rr[0]] = info

		# ????????????????????????????????????top8_plays
		if self.isInTopOrFinal():
			teamKey, key = self._top8Map[rr] # {rr: top8key}
			self.top8_plays[teamKey][key]['result'] = info
			# ???????????????round???????????????win????????????????????????????????????
			# ?????????????????????round+1??????19????????????????????????
			if teamKey == 'final' and key == 7:
				winRoleID = rr[0] if result == 'win' else rr[1]
				info = self.craft_roles[winRoleID]
				self.craft_roles[winRoleID] = info._replace(round=19)
		return rr

	def pushPlayResultToGame(self, model):
		# model???CraftPlayRecord
		# ??????game??????????????????
		_get = functools.partial(getModelValue, model)
		roleKey1, roleKey2 = _get('role_key'), _get('defence_role_key')

		# like `onPlaying`
		# ????????????
		self._roleMatchHistory[roleKey1].update(play=model['cross_id'], result=model['result'], point=model['point'])
		if roleKey2 in self._roleMatchHistory:
			self._roleMatchHistory[roleKey2].update(play=model['cross_id'], result='fail' if model['result'] == 'win' else 'win', point=model['defence_point'])

		info1 = self.signup[roleKey1]
		info2 = self.signup.get(roleKey2, None)
		# ??????
		if info2 is None:
			history = info1.history + [{
				't': nowtime_t(),
				'r': model['result'],
				'date': model['date'],
				'round': model['round'],
				'point': model['point'],
				'cards': model['cards'],
			}]
			self.updSignUpRoleInfo(roleKey1, history=history)

		else:
			# pattrs?????????????????????????????????????????????
			ClientUseKeys = ['id', 'card_id', 'advance', 'level', 'star', 'skin_id', 'fighting_point']
			history = info1.history + [{
				't': nowtime_t(),
				'r': model['result'],
				'date': model['date'],
				'round': model['round'],
				'point': model['point'],
				'brid': model['cross_id'],
				'cards': model['cards'],
				'pname': info2.name,
				'pid': roleKey2,
				'prid': info2.cross_craft_record_db_id,
				'plogo': info2.logo,
				'plevel': info2.level,
				'pcards': model['defence_cards'],
				'pattrs': {k: {kk: d[kk] for kk in ClientUseKeys} for k, d in model['defence_card_attrs'].iteritems()},
			}]
			self.updSignUpRoleInfo(roleKey1, history=history)

			history = info2.history + [{
				't': nowtime_t(),
				'r': 'fail' if model['result'] == 'win' else 'win',
				'date': model['date'],
				'round': model['round'],
				'point': model['defence_point'],
				'brid': model['cross_id'],
				'cards': model['defence_cards'],
				'pname': info1.name,
				'pid': roleKey1,
				'prid': info1.cross_craft_record_db_id,
				'plogo': info1.logo,
				'plevel': info1.level,
				'pcards': model['cards'],
				'pattrs': {k: {kk: d[kk] for kk in ClientUseKeys} for k, d in model['card_attrs'].iteritems()},
			}]
			self.updSignUpRoleInfo(roleKey2, history=history)

		# ?????????pre??????????????????????????????isOut?????????halftime?????????????????????
		if model['round'][:3] == 'pre':
			roundTotal = CraftRoundNextMap[model['round']].roundIdx
			craftInfo1, craftInfo2 = self.craft_roles[roleKey1], self.craft_roles.get(roleKey2, None)
			self.updSignUpRoleInfo(roleKey1, isOut=roundTotal - craftInfo1.win >= 5)
			if craftInfo2:
				self.updSignUpRoleInfo(roleKey2, isOut=roundTotal - craftInfo2.win >= 5)

		# ????????????top???final????????????????????????
		else:
			self.updSignUpRoleInfo(roleKey1, isOut=model['result'] != 'win')
			self.updSignUpRoleInfo(roleKey2, isOut=model['result'] == 'win')

		# ?????????role??????
		msg = {
			'model': model,
			'role1': self.signup.get(roleKey1, None),
			'role2': self.signup.get(roleKey2, None),
			'match1': self._roleMatchHistory.get(roleKey1, None),
			'match2': self._roleMatchHistory.get(roleKey2, None),
		}

		# play?????????game
		if self.isInTopOrFinal():
			# ??????????????????game
			self.eventToGame('new_play', msg)
		else:
			# ???????????????game
			servKey1, servKey2 = model['role_key'][0], model['defence_role_key'][0]
			d = {servKey1: msg}
			if model['defence_role_key'] != self.EmptyRoleKey and servKey1 != servKey2:
				d[servKey2] = msg
			self.eventToSomeGame('new_play', d, sync=False)

	def checkPlayEnd(self):
		# ??????onPlayEnd?????????????????????
		if self._playStatus == 'finished':
			return 0

		leftPlay = len(self._playMap) + len(self._playGetRecording)
		logger.info('checkPlayEnd %s Playing %d Getting %d', self.round, len(self._playMap), len(self._playGetRecording))
		if leftPlay == 0:
			# ?????????????????????????????????
			if self.round not in self.round_results:
				return 0

			# ??????????????????????????????
			for roleKey1, info in self.round_results[self.round].iteritems():
				if len(info) == 2:
					logger.warning('checkPlayEnd %s invalid %s', self.round, str((roleKey1, info)))
					# ?????????????????????PlayRecord???????????????
					raise Exception('retry make play %s' % str((roleKey1, info)))
				elif info.result == 'unknown':
					self._playMap[info.playID] = info.roles
			# ????????????
			if len(self._playMap) == 0:
				self._playStatus = 'finished'
				logger.info('checkPlayEnd %s -> %s', self.round, CraftRoundNextMap[self.round].next)
		return leftPlay

	# ???????????? (pre1, pre2 .. final1) -> (pre2, pre3 .. over)
	@coroutine
	def onPlayEnd(self):
		while self._playStatus != 'finished':
			yield sleep(1)

		if self._queryAgentMgrTimer:
			self._queryAgentMgrTimer.stop()
			if self.round in ('halftime', 'over'):
				self._queryAgentMgrTimer = None

		# ???????????????matches
		self._lastMatchDispathes = {}

		nextRound = CraftRoundNextMap[self.round].next
		# ???????????????
		self.refreshRankCache()

		# ???????????????
		if nextRound == 'halftime':
			self.onHalftime()

		elif nextRound == 'over':
			self.onOver()

		else:
			delta = timeSubTime(CraftRoundNextMap[nextRound].time, nowdtime_t())
			if TESTINQUICK:
				delta = datetime.timedelta(seconds=5)
			logger.info('round %s next %s time delta %s', self.round, nextRound, delta)
			self.server.ioloop.add_timeout(delta, self.onStartRound)

	@coroutine
	def _queryAgentMgr(self):
		if not self.isFirstMakeEnd():
			logger.info('_queryAgentMgr waitting first make end')
			raise Return(None)

		ret = self.server.antiMgr.syncCraftPlayResults()
		for playID, result in ret.iteritems():
			if result[0] not in ('win', 'fail'):
				logger.warning('agent play %d result %s', playID, result)
				continue

			result = (playID, result[0], (result[1], result[2]))
			rr = self.recordPlayResult(*result)
			if rr:
				roleKey1, roleKey2 = rr
				playModel = self._playCache[playID]
				playModel['result'] = result[1]
				playModel['point'] = result[-1][0]
				playModel['defence_point'] = result[-1][1]
				# ???game?????????
				self.pushPlayResultToGame(playModel)

			else:
				logger.warning('agent play %d redundant result %s', playID, result)

		try:
			localPlays = self.checkPlayEnd()
			# ?????????????????????
			if localPlays > 0 and len(ret) == 0:
				# ???agentmgr???????????????
				leftPlayIDs = self.server.antiMgr.syncCraftPlays(self._playMap.keys())
				# ??????
				for playID in leftPlayIDs:
					playModel = self._playCache[playID]
					self.server.antiMgr.sendCraftPlay(ObjectMemDB(playModel))
		except:
			# ????????????????????????????????????
			self.server.ioloop.add_timeout(datetime.timedelta(seconds=1), self._makePlayAndRun)

	def slimSignInfo(self, roleKey):
		info = self.signup.get(roleKey, None)
		if info is None:
			return None
		return [roleKey, info.logo, info.name, info.level, info.vip_level, info.unionName]

	# ???????????????
	@coroutine
	def onHalftime(self):
		self.round = 'halftime'

		# ????????????????????????
		d = defaultdict(dict) # {serv key: {roleID: (win, fail, point)}}
		for roleKey, t in self._resultCache.iteritems():
			servKey, roleID = roleKey
			d[servKey][roleID] = t
		yield self.eventToSomeGame('battle_award', d)
		self._resultCache.clear()

		# ??????????????????
		dd = {k: (v, None) for k, v in d.iteritems()}
		yield self.eventToSomeGame('bet1_award', dd)

		# ?????????64???????????????????????????, ?????????????????????
		top64 = self._getFightPointTop64()
		# info????????????ObjectRankGlobal.BaseRoleInfos
		# BaseRoleInfos = ('roleID', 'logo', 'name', 'level', 'vip_level', 'union_name')
		self.bet2 = {roleKey: {
			'info': self.slimSignInfo(roleKey),
			'rank': rank,
			'rate': self.MinBetRate,
			'gold': {},
			'gold_sum': 0,
			'fight': self._roleCardsFightPoint.get(roleKey, 0),
		} for rank, roleKey in enumerate(top64, 1)}

		# ??????craft_roles
		self.last_craft_roles = copy.deepcopy(self.craft_roles)

		# ?????????game
		yield self.eventAndDBToGame('halftime')

		# ????????????????????????
		delta = datetime.datetime.combine(nowdate_t() + OneDay, CraftRoundNextMap['prepare2'].time) - nowdatetime_t()
		logger.info('round %s next %s time delta %s', self.round, 'prepare2', delta)
		self.server.ioloop.add_timeout(delta, self.onStartPrepare2)


	# ???????????? final3 -> over -> closed
	@coroutine
	def onOver(self):
		self.round = 'over'

		# ????????????????????????
		d = defaultdict(dict) # {serv key: {roleID: (win, fail)}}
		for roleKey, t in self._resultCache.iteritems():
			servKey, roleID = roleKey
			d[servKey][roleID] = t
		yield self.eventToSomeGame('battle_award', d)
		self._resultCache.clear()

		# ????????????
		# ?????????????????????6W???20W??????????????????????????????????????????????????????????????????????????????????????????????????????1.5???????????????????????????????????????????????????????????????
		d = defaultdict(dict) # {serv key: {roleID: (who, gold, final or top4 or None)}}
		roleLevels = defaultdict(lambda: None)
		allRanks = self.refreshRankCache()
		top4 = allRanks[:4]
		cfg = csv.cross.craft.base[1]
		for i, t in enumerate(top4):
			roleKey = t[0]
			roleLevels[roleKey] = 'final' if i == 0 else 'top4'
		for roleKey, bet in self.bet2.iteritems():
			roleName = bet['info'][2] # slimSignInfo
			rate = bet['rate']
			for betRoleKey, gold in bet['gold'].iteritems():
				betServKey, betRoleID = betRoleKey
				level = roleLevels[roleKey]
				winGold = int(gold / 2)
				if level == 'final':
					winGold = int(gold * rate)
				elif level == 'top4':
					winGold = int(gold * 1.5)
				d[betServKey][betRoleID] = (roleName, min(winGold, cfg.maxBetWin), level)
		dd = {k: (None, v) for k, v in d.iteritems()}
		yield self.eventToSomeGame('bet2_award', dd)

		# ???????????????
		yield self.eventToGame('rank_award', allRanks)

		# ?????????game
		yield self.eventAndDBToGame('over')

		# ?????????????????????pvp
		yield self.sendHistoryToPVP()

		# ??????db???mem
		self.clean()

		# cross????????????
		from cross.object.gglobal import ObjectCrossGlobal
		ObjectCrossGlobal.initServiceState('craft')

	def getRoleCraftInfo(self, roleKey):
		return self.craft_roles.get(roleKey, None)

	def getRankList(self, offest, size):
		return self._rankCache[offest: offest+size]

	# ?????????server [node key list]
	servers = db_property('servers')

	# service.csv???CSV ID
	csv_id = db_property('csv_id')

	# ????????????
	date = db_property('date')

	# round????????????
	time = db_property('time')

	# signup -> prepare -> pre1 -> pre1_lock -> pre2 ... -> final3 -> final3_lock -> over
	def round():
		dbkey = 'round'
		def fset(self, value):
			old = self.db[dbkey]
			self.db[dbkey] = value
			if value != old:
				self.time = nowtime_t()
		return locals()
	round = db_property(**round())

	# ?????????????????? {(node key, Role.id): RoleSignItem}
	signup = db_property('signup')

	# ????????????????????? {Role.id: CraftRoleInfo}
	craft_roles = db_property('craft_roles')

	# ????????????????????? {Role.id: CraftRoleInfo}
	last_craft_roles = db_property('last_craft_roles')

	# ???2????????????????????????64????????????????????? {(node key, Role.id): {info: ObjectRankGlobal.BaseRoleInfos, rank: ????????????, rate: ??????, gold: {(node key, Role.id): gold}}}
	bet2 = db_property('bet2')

	# 8??????????????? {1: {role1: CraftRoleInfo, role2: CraftRoleInfo, result: CraftResultInfo, cards1:[cards], cards2:[cards]}}
	top8_plays = db_property('top8_plays')

	# ??????????????? {pre1: {min(Role1.id, Role2.id): CraftResultInfo}}
	# msgpack?????????tuple??????list????????????dict???key????????????min?????????
	# ????????????PlayRecord??????value???role key???????????????list
	round_results = db_property('round_results')

	# ??????id???????????????????????????
	play_id = db_property('play_id')
