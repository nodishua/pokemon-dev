#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2014 YouMi Information Technology Inc.
'''

from framework import todayinclock5elapsedays, nowtime_t
from framework.csv import csv, MergeServ
from framework.log import logger
from framework.helper import transform2list, objectid2string
from framework.object import ObjectNoGCDBase, db_property
from game import globaldata, ClientError
from game.globaldata import CrossMineAllRankAwardMailID, CrossMineDayRankAwardMailID, CrossMineServRankAwardMailID, CrossMineBossRankAwardMailID
from game.object import FeatureDefs, MessageDefs, TitleDefs
from game.object.game.message import ObjectMessageGlobal
from game.object.game.levelcsv import ObjectFeatureUnlockCSV
from game.object.game.servrecord import ObjectServerGlobalRecord

from tornado.gen import coroutine, Return

import bisect


#
# ObjectCrossMineGameGlobal
#
class ObjectCrossMineGameGlobal(ObjectNoGCDBase):
	DBModel = 'CrossMineGameGlobal'

	Singleton = None

	OpenLevel = 0
	FreeRobTimes = 0
	FreeRevengeTimes = 0
	FreeBossTimes = 0
	MaxBossTimes = 0

	BossRankCfgs = {}  # {version: {cfgs: [], cfgRanks: []}}

	GlobalObjsMap = {}  # {areakey: ObjectCrossMineGameGlobal}
	GlobalHalfPeriodObjsMap = {}  # {areakey: ObjectCrossMineGameGlobal}

	@classmethod
	def classInit(cls):
		cfg = csv.cross.mine.base[1]
		cls.OpenLevel = ObjectFeatureUnlockCSV.getOpenLevel(FeatureDefs.CrossMine)
		cls.FreeRobTimes = cfg.robFreeTimes
		cls.FreeRevengeTimes = cfg.revengeFreeTimes
		cls.FreeBossTimes = cfg.bossFreeTimes
		cls.MaxBossTimes = cfg.bossMaxTimes

		cls.BossRankCfgs = {}
		for idx in sorted(csv.cross.mine.boss_rank_award.keys()):
			cfg = csv.cross.mine.boss_rank_award[idx]
			if cfg.version not in cls.BossRankCfgs:
				cls.BossRankCfgs[cfg.version] = {'cfgs': [], 'cfgRanks': []}
			cls.BossRankCfgs[cfg.version]['cfgs'].append(cfg)
			cls.BossRankCfgs[cfg.version]['cfgRanks'].append(cfg.rank)

	@classmethod
	def getByAreaKey(cls, key):
		return cls.GlobalHalfPeriodObjsMap.get(key, cls.Singleton)

	def __init__(self, dbc):
		ObjectNoGCDBase.__init__(self, None, dbc)

	def set(self, dic):
		ObjectNoGCDBase.set(self, dic)
		self.isHalfPeriod = ObjectServerGlobalRecord.isHalfPeriod('cross_mine', self.key)
		return self

	def init(self, server, data):
		self.server = server
		self._roleRankMap = {}  # {roleID: CrossMineRoleInfo}
		self._cross = {}
		self._lastServerBuffFeedRanks = []  # 结束后的全服 buff 培养排名
		self._bossTimeMap = {} # {bossID: [bossCsbID, openTime]}

		self.initCrossData(data)

		cls = ObjectCrossMineGameGlobal
		cls.GlobalObjsMap[self.key] = self
		# global对象 key与当前服key对应
		if self.key == self.server.key:
			cls.Singleton = self

		# 是在半周期的话
		if self.isHalfPeriod:
			srcServs = MergeServ.getSrcServKeys(self.key)
			for srcServ in srcServs:
				cls.GlobalHalfPeriodObjsMap[srcServ] = self

		return self

	@classmethod
	def cleanHalfPeriod(cls):
		for _, obj in cls.GlobalObjsMap.iteritems():
			if obj.isHalfPeriod:  # 清除半周期状态
				ObjectServerGlobalRecord.overHalfPeroid('cross_mine', obj.key)
				obj.isHalfPeriod = ObjectServerGlobalRecord.isHalfPeriod('cross_mine', obj.key)
				obj.last_ranks = []
				obj.last_server_points = {}
				obj.top_battle_history = []

		cls.GlobalHalfPeriodObjsMap = {}

	@classmethod
	@coroutine
	def onCrossCommit(cls, key, transaction):
		logger.info('ObjectCrossMineGameGlobal.onCrossCommit %s %s', key, transaction)

		# cross竞争资源成功
		self = cls.Singleton
		# 玩法已经被占用
		if self.cross_key != '' and self.cross_key != key:
			logger.warning('ObjectCrossMineGameGlobal.onCrossCommit %s', self.cross_key)
			raise Return(False)

		cls.cleanHalfPeriod()
		self.cross_key = key
		raise Return(True)

	@classmethod
	def cross_client(cls, areaKey, cross_key=None):
		'''
		获取cross rpc
		'''
		self = cls.getByAreaKey(areaKey)
		if cross_key is None:
			cross_key = self.cross_key
		if cross_key == '':
			return None
		container = self.server.container
		client = container.getserviceOrCreate(cross_key)
		return client

	@classmethod
	@coroutine
	def onCrossEvent(cls, event, key, data, sync):
		logger.info('ObjectCrossMineGameGlobal.onCrossEvent %s %s', key, event)

		self = cls.getByAreaKey(key)
		if sync:
			self.round = sync['round']

		ret = {}
		if event == 'init':
			self.initCrossData(data['model'])
			ret['serverOpenDays'] = self.onPrepare()
		elif event == 'start':
			self.onStart()
			self._bossTimeMap = data.get('bossTimeMap', {})
		elif event == 'closed':
			self.onClosed(data.get('last_ranks', []), data.get('last_server_points', {}), data.get('top_battle_history', []))
		elif event == 'dayRankAward':
			self.onRoleRankAward(data.get('role_ranks', {}), False)
		elif event == "allRankAward":
			self.onRoleRankAward(data.get('role_ranks', {}), True)
			self.onServerRankAward(data.get('role_ranks', {}), data.get('last_server_points', {}))
			yield self.onRoleCoin13(data.get('roles', {}))
		elif event == "bossRankAward":
			self.onBossRankAward(data.get('boss_role_ranks', {}), data.get('boss_award_version', 0))
			self._bossTimeMap = data.get('bossTimeMap', {})
		elif event == 'refreshTopHistory':
			self.refreshTopHistoryMsg()

		raise Return(ret)

	def onPrepare(self):
		logger.info('ObjectCrossMineGameGlobal.onPrepare')

		# 开服天数
		days = todayinclock5elapsedays(globaldata.GameServOpenDatetime)
		return days

	def onStart(self):
		logger.info('ObjectCrossMineGameGlobal.onStart')
		self.round = 'start'
		self.last_ranks = []
		self._roleRankMap = {}
		self._lastServerBuffFeedRanks = []
		self.top_battle_history = []

	def onClosed(self, lastRanks, lastServerPoints, topBattleHistory):
		logger.info('ObjectCrossMineGameGlobal.onClosed')
		self.round = 'closed'
		self.cross_key = ''
		self.last_ranks = lastRanks
		self.last_server_points = lastServerPoints
		self.top_battle_history = topBattleHistory

	@coroutine
	def onRoleCoin13(self, roles):
		logger.info('ObjectCrossMineGameGlobal.onRoleCoin13')

		from game.object.game import ObjectGame
		from game.object.game.gain import ObjectCostAux, ObjectGainAux
		from game.handler.inl import effectAutoGain, effectAutoCost

		for roleID, coin13Diff in roles.iteritems():
			if coin13Diff == 0:
				continue

			game = ObjectGame.getByRoleID(roleID, safe=False)
			if game:
				roleID = game.role.id
				oldCoin13 = game.role.coin13

				# 之前的还没同步
				if roleID in self.role_coin13_diff:
					logger.warning('online role %s coin13 sync error old: %s, oldCache: %s, newCache: %s', objectid2string(roleID), oldCoin13, self.role_coin13_diff[roleID], coin13Diff)
					self.role_coin13_diff.pop(roleID)

				try:
					if coin13Diff > 0:
						eff = ObjectGainAux(game, {'coin13': coin13Diff})
						yield effectAutoGain(eff, game, self.server.dbcGame, src='cross_mine_close_sync')
					else:
						cost = ObjectCostAux(game, {'coin13': -coin13Diff})
						yield effectAutoCost(cost, game, src='cross_mine_close_sync')
				except:
					logger.warning('online role %s coin13 sync error old: %s, now: %s, diff: %s', objectid2string(roleID), oldCoin13, game.role.coin13, coin13Diff)

			else:
				# 记入缓存
				self.role_coin13_diff[roleID] = coin13Diff

	def onRoleRankAward(self, ranks, isEnd):
		from game.mailqueue import MailJoinableQueue
		from game.object.game.role import ObjectRole

		logger.info('ObjectCrossMineGameGlobal.onRoleRankAward rankNum %s isEnd %s', len(ranks), isEnd)

		cfgs = []
		cfgRanks = []
		for idx in sorted(csv.cross.mine.role_award.keys()):
			cfg = csv.cross.mine.role_award[idx]
			if cfg.version != self.version:
				continue
			cfgs.append(cfg)
			cfgRanks.append(cfg.rankMax)

		for roleID, rank in ranks.iteritems():
			idx = bisect.bisect_left(cfgRanks, rank)
			cfg = cfgs[idx]
			if rank <= cfg.rankMax:
				award = cfg.endAward if isEnd else cfg.dayAward
				mailID = CrossMineAllRankAwardMailID if isEnd else CrossMineDayRankAwardMailID
				mail = ObjectRole.makeMailModel(roleID, mailID, contentArgs=(rank), attachs=award)
				MailJoinableQueue.send(mail)

		from game.object.game.servrecord import ObjectServerGlobalRecord
		if isEnd:
			ObjectServerGlobalRecord.saveTitleRanks(TitleDefs.CrossMine, ranks)
		else:
			ObjectServerGlobalRecord.saveTitleRanks(TitleDefs.CrossMineDaily, ranks)

	def onServerRankAward(self, roleRanks, serverPoints):
		from game.mailqueue import MailJoinableQueue
		from game.object.game.role import ObjectRole

		logger.info('ObjectCrossMineGameGlobal.onServerRankAward, rankNum %d', len(roleRanks))

		sumPoint = 0
		servNum = 0
		servL = []
		for servKey, point in serverPoints.iteritems():
			sumPoint += point
			servL.append((servKey, point))
			servNum += 1

		servRank = 0
		servPoint = 0
		servL.sort(key=lambda o: o[1], reverse=True)
		for rank, servInfo in enumerate(servL, 1):
			if servInfo[0] == self.server.key:
				servRank = rank
				servPoint = servInfo[1]
				break

		roleCount = len(roleRanks)
		if servRank == 0 or sumPoint == 0 or roleCount == 0:
			logger.warning('ObjectCrossMineGameGlobal.onServerRankAward error %s %s %s', servRank, sumPoint, roleCount)
			return

		baseCfg = csv.cross.mine.base[1]
		servAward = (1.0 * servPoint / sumPoint) * baseCfg.extraAward[servNum]
		servAward = int(servAward + baseCfg['serverAward%d' % servRank])
		servAward = max(servAward, 1)  # 最少也有1
		for roleID in roleRanks.iterkeys():
			mail = ObjectRole.makeMailModel(roleID, CrossMineServRankAwardMailID, contentArgs=(servRank), attachs={'coin13': servAward})
			MailJoinableQueue.send(mail)

	def onBossRankAward(self, ranks, version):
		from game.mailqueue import MailJoinableQueue
		from game.object.game.role import ObjectRole

		logger.info('ObjectCrossMineGameGlobal.onBossRankAward, rankNum %s version %s', len(ranks), version)
		cfgs = self.BossRankCfgs.get(version, {}).get('cfgs', [])
		cfgRanks = self.BossRankCfgs.get(version, {}).get('cfgRanks', [])

		for roleID, rank in ranks.iteritems():
			idx = bisect.bisect_left(cfgRanks, rank)
			cfg = cfgs[idx]
			if rank <= cfg.rank:
				mail = ObjectRole.makeMailModel(roleID, CrossMineBossRankAwardMailID, contentArgs=(rank), attachs=cfg.award)
				MailJoinableQueue.send(mail)

	def refreshTopHistoryMsg(self):
		# 精彩战报刷新 跑马灯
		ObjectMessageGlobal.marqueeBroadcast(None, MessageDefs.MqCrossMineTopHistoryRefresh)
		ObjectMessageGlobal.newsCrossMineTopHistoryRefreshMsg()

	# 初始化 init
	def initCrossData(self, crossData):
		# crossData = {servers; csv_id; date; round}
		self._cross = crossData
		if crossData:
			self.round = self._cross.get('round', 'closed')
			self.csv_id = self._cross.get('csv_id', 0)
			self.date = self._cross.get('date', 0)
			self._bossTimeMap = self._cross.get('bossTimeMap', {})
			if self.csv_id > 0:
				self.version = csv.cross.service[self.csv_id].version
			logger.info('Cross Mine Init %s %s %s, csv_id %d', self.cross_key, self.date, self.round, self.csv_id)
		else:
			self.reset()

	def reset(self):
		self.round = 'closed'
		self.cross_key = ''
		self.version = 0
		return True

	@classmethod
	def isOpen(cls, areaKey):
		# 没有开启跨服
		self = cls.getByAreaKey(areaKey)
		if self.cross_key == '' or self.round == 'closed':
			return False
		return True

	@classmethod
	def inBattle(cls, areaKey):
		self = cls.getByAreaKey(areaKey)
		return self.round == 'start'

	@classmethod
	def isRoleOpen(cls, level):
		# 角色等级满足
		return level >= cls.OpenLevel

	def refreshRoleCache(self):
		pass

	@classmethod
	def getRoleCacheInfo(cls, role):
		self = cls.getByAreaKey(role.areaKey)
		self.refreshRoleCache()
		return self._roleCacheMap.get(role.id, None)

	@classmethod
	def getRankList(cls, areaKey, flag, offset, size, roleID):
		"""
		结束后的排行榜
		"""
		self = cls.getByAreaKey(areaKey)
		if self.cross_key == '' or self.round == 'closed':
			if not self._roleRankMap or not self._lastServerBuffFeedRanks:
				tmp = []
				for rank, role in enumerate(self.last_ranks, 1):
					self._roleRankMap[role['role_db_id']] = role
					if role['server_buff_feed'] <= 0 and role['server_buff_feed_rank'] <= 0:
						continue
					tmp.append((role['role_db_id'], role['server_buff_feed_rank']))

				for tmpRoleID, _ in sorted(tmp, key=lambda x: x[1]):
					self._lastServerBuffFeedRanks.append(self._roleRankMap[tmpRoleID])

			if flag == "role":
				return {
					'ranks': self.last_ranks[offset:offset + size],
					'myInfo': self._roleRankMap.get(roleID, None),
				}
			elif flag == "feed":
				return {
					'ranks': self._lastServerBuffFeedRanks[offset:offset + size],
					'myInfo': self._roleRankMap.get(roleID, None),
				}

		return None

	@classmethod
	def getLastSlimModel(cls, areaKey):
		self = cls.getByAreaKey(areaKey)
		return {
			'round': self.round,
			'serverPoints': self.last_server_points,
			'top10': self.last_ranks[:10],
			'topBattleHistory': self.top_battle_history
		}

	@classmethod
	def getCrossGameModel(cls, areaKey):
		'''
		缩略model
		'''
		self = cls.getByAreaKey(areaKey)
		servers = []
		if self._cross:
			servers = self.servers
		return {
			'date': self.date,
			'round': self.round,
			'csvID': self.csv_id,
			'servers': servers,
		}

	@classmethod
	def getCrossMineCards(cls, role):
		'''
		初始化布阵队伍
		'''
		cards = role.top_cards[:12]
		if len(cards) < 3:
			raise ClientError("Cross mine cards must be greater than 3")
		cardsMap = {}  # {1:[card.id], 2:[card.id]}, 3:[card.id] （队伍一 / 队伍二 / 队伍三）
		# 保证每支队伍至少有一只
		if len(cards) < 7:
			cardsMap[3] = transform2list(cards[:1])
			cardsMap[2] = transform2list(cards[1:2])
			cardsMap[1] = transform2list(cards[2:6])
		elif len(cards) < 9:
			cardsMap[3] = transform2list(cards[:1])
			cardsMap[2] = transform2list(cards[1:-4])
			cardsMap[1] = transform2list(cards[-4:])
		else:
			cardsMap[1] = transform2list(cards[:4])
			cardsMap[2] = transform2list(cards[4:8])
			cardsMap[3] = transform2list(cards[8:12])
		return cardsMap, cards

	@classmethod
	def isRobTimesLimit(cls, game):
		return game.dailyRecord.cross_mine_rob_times >= cls.FreeRobTimes + game.dailyRecord.cross_mine_rob_buy_times

	@classmethod
	def isRevengeTimesLimit(cls, game):
		return game.dailyRecord.cross_mine_revenge_times >= cls.FreeRevengeTimes + game.dailyRecord.cross_mine_revenge_buy_times

	@classmethod
	def isBossTimesLimit(cls, game, bossID):
		return game.dailyRecord.cross_mine_boss_times.get(bossID, 0) >= cls.FreeBossTimes + game.dailyRecord.cross_mine_boss_buy_times.get(bossID, 0)

	@classmethod
	def canBuyBossTimes(cls, game, bossID):
		return game.dailyRecord.cross_mine_boss_buy_times.get(bossID, 0) < cls.MaxBossTimes - cls.FreeBossTimes

	@classmethod
	@coroutine
	def SyncCoin13(cls, game):
		areaKey = game.role.areaKey
		role = game.role
		self = cls.getByAreaKey(areaKey)

		if role.id in self.role_coin13_diff:
			coin13Diff = self.role_coin13_diff[role.id]
			self.role_coin13_diff.pop(role.id)
			oldCoin13 = role.coin13
			if coin13Diff != 0:
				role.coin13 += coin13Diff
				logger.info('role %s uid %s sync coin13 from cache old: %s, now: %s, diff: %s', objectid2string(role.id), role.uid, oldCoin13, role.coin13, {'coin13': coin13Diff})

		if self.isOpen(areaKey):
			rpc = self.cross_client(areaKey)
			oldCoin13 = role.coin13
			coin13Diff = yield rpc.call_async('CrossMineUpdateOriginCoin13', role.id, role.coin13)
			if coin13Diff != 0:
				role.coin13 += coin13Diff
				logger.info('role %s uid %s sync coin13 from rpc old: %s, now: %s, diff: %s', objectid2string(role.id), role.uid, oldCoin13, role.coin13, {'coin13': coin13Diff})

	def getBossTime(self):
		nt = nowtime_t()
		for csvID, openTime in self._bossTimeMap.itervalues():
			if openTime < nt and openTime + csv.cross.mine.boss[csvID].duration * 60 > nt:
				return openTime
		return 0

	# servkey
	key = db_property('key')

	# 跨服server key
	cross_key = db_property('cross_key')

	# 日期
	date = db_property('date')

	# 跨服csv_id
	csv_id = db_property('csv_id')

	# Minelobal.time
	time = db_property('time')

	# MineGlobal.round
	round = db_property('round')

	# 角色缓存资源
	role_coin13_diff = db_property('role_coin13_diff')

	# 上期排行榜
	last_ranks = db_property('last_ranks')

	# 上期服务器积分
	last_server_points = db_property('last_server_points')

	# 结束后精彩战报
	top_battle_history = db_property('top_battle_history')

	@property
	def servers(self):
		return self._cross.get('servers', [])
