#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2014 YouMi Information Technology Inc.
'''

from framework.log import logger
from framework.csv import csv, MergeServ
from framework.object import ObjectNoGCDBase, db_property
from framework.helper import objectid2string
from game.globaldata import CrossFishingRankAwardMailID, CrossFishingAutoAwardMailID
from game.object import TargetDefs, TitleDefs
from game.object.game.servrecord import ObjectServerGlobalRecord
from game.object.game.yyhuodong import ObjectYYHuoDongFactory
from game.object.game.gain import  ObjectCostAux, unpack

from tornado.gen import coroutine, Return, sleep

import bisect


#
# ObjectCrossFishingGameGlobal
#

class ObjectCrossFishingGameGlobal(ObjectNoGCDBase):
	DBModel = 'CrossFishingGameGlobal'

	Singleton = None

	SpecialFish = None
	CrossFishingRankSize = 30

	GlobalObjsMap = {} # {areakey: ObjectCrossArenaGameGlobal}
	GlobalHalfPeriodObjsMap = {} # {areakey: ObjectCrossArenaGameGlobal}

	@classmethod
	def classInit(cls):
		baseCfg = csv.cross.fishing.base[1]
		cls.SpecialFish = baseCfg.specialFish

	@classmethod
	def getByAreaKey(cls, key):
		return cls.GlobalHalfPeriodObjsMap.get(key, cls.Singleton)

	def __init__(self, dbc):
		ObjectNoGCDBase.__init__(self, None, dbc)

	def set(self, dic):
		ObjectNoGCDBase.set(self, dic)
		self.isHalfPeriod = ObjectServerGlobalRecord.isHalfPeriod('cross_fishing', self.key)
		return self

	def init(self, server, crossData):
		self.server = server
		self._cross = {}
		self._roleRankMap = {}  # {roleID: (rank, point, specialFishNum)}

		self.initCrossData(crossData)

		cls = ObjectCrossFishingGameGlobal
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

	# key
	key = db_property('key')

	# 跨服server key
	cross_key = db_property('cross_key')

	# 赛季状态
	round = db_property('round')

	# 上期排名
	last_ranks = db_property('last_ranks')

	# 上期匹配区服
	last_servers = db_property('last_servers')

	# 自动钓鱼玩家
	auto_roles = db_property('auto_roles')

	@property
	def servers(self):
		return self._cross.get('servers', [])

	@property
	def date(self):
		return self._cross.get('date', 0)

	@classmethod
	def isOpen(cls, areaKey):
		'''
		是否开启玩法
		'''
		self = cls.getByAreaKey(areaKey)
		if self.cross_key == '' or self.round == "closed":
			return False
		return True

	@classmethod
	def getRound(cls, areaKey):
		self = cls.getByAreaKey(areaKey)
		return self.round

	@classmethod
	def getVersion(cls, areaKey):
		self = cls.getByAreaKey(areaKey)
		return self.version

	@classmethod
	def getCrossKey(cls, areaKey):
		self = cls.getByAreaKey(areaKey)
		return self.cross_key

	@classmethod
	def getDate(cls, areaKey):
		self = cls.getByAreaKey(areaKey)
		return self.date

	@classmethod
	def getGameKey(cls, areaKey):
		self = cls.getByAreaKey(areaKey)
		return self.key

	@classmethod
	@coroutine
	def onCrossEvent(cls, event, key, data, sync):
		'''
		玩法流程
		'''
		logger.info('ObjectCrossFishingGameGlobal.onCrossEvent %s %s', key, event)

		self = cls.getByAreaKey(key)
		if sync:
			self.round = sync['round']

		ret = {}
		if event == 'start':
			self.initCrossData(data.get('model', {}))
			self.onStart()

		elif event == 'closed':
			self.onClosed(key)
		elif event == 'save_rank':
			# onClosed 合服后存在重入情况延后一步调用 reset 清理 cross_key
			self.reset()

			self.onSaveRank(data.get('servers', []), data.get('allRanks', []))
		elif event == 'rank_award':
			self.onRankAward(data.get('allRanks', []))

		raise Return(ret)

	# 初始化
	def initCrossData(self, crossData):
		self._cross = crossData
		if crossData:
			self.round = self._cross.get('round', 'closed')
			logger.info('Cross fishing Init %s %s %s', self.cross_key, self.date, self.round)
		else:
			self.reset()

	# 赛季开始
	def onStart(self):
		logger.info('ObjectCrossFishingGameGlobal.onStart')
		self.round = 'start'
		self.last_ranks = []
		self._roleRankMap = {}

	def onSaveRank(self, servers, allRanks):
		self.last_servers = servers
		self.last_ranks = allRanks

	# 赛季排名奖励
	def onRankAward(self, allRanks):
		from game.mailqueue import MailJoinableQueue
		from game.object.game.role import ObjectRole

		ranks = {item['role_db_id']: item['rank'] for item in allRanks}

		logger.info('ObjectCrossFishingGameGlobal.onRankAward %s', len(ranks))

		cfgs = []
		cfgRanks = []
		for idx in sorted(csv.cross.fishing.rank.keys()):
			cfg = csv.cross.fishing.rank[idx]
			cfgs.append(cfg)
			cfgRanks.append(cfg.rankMax)

		for roleID, rank in ranks.iteritems():
			idx = bisect.bisect_left(cfgRanks, rank)
			cfg = cfgs[idx]
			if rank <= cfg.rankMax:
				mail = ObjectRole.makeMailModel(roleID, CrossFishingRankAwardMailID, contentArgs=rank, attachs=cfg.award)
				MailJoinableQueue.send(mail)

		# 钓鱼大赛称号
		from game.object.game.servrecord import ObjectServerGlobalRecord
		ObjectServerGlobalRecord.saveTitleRanks(TitleDefs.CrossFishing, ranks)

	def reset(self):
		self.round = 'closed'
		self.cross_key = ''
		return True

	@classmethod
	def cleanHalfPeriod(cls):
		for _, obj in cls.GlobalObjsMap.iteritems():
			if obj.isHalfPeriod: # 清除半周期状态
				ObjectServerGlobalRecord.overHalfPeroid('cross_fishing', obj.key)
				obj.isHalfPeriod = ObjectServerGlobalRecord.isHalfPeriod('cross_fishing', obj.key)
				obj.auto_roles = {}

		cls.GlobalHalfPeriodObjsMap = {}

	@classmethod
	@coroutine
	def onCrossCommit(cls, key, transaction):
		'''
		跨服启动commit
		'''
		logger.info('ObjectCrossFishingGameGlobal.onCrossCommit %s %s', key, transaction)

		# cross竞争资源成功
		self = cls.Singleton
		# 玩法已经被占用
		if self.cross_key != '' and self.cross_key != key:
			logger.warning('ObjectCrossFishingGameGlobal.onCrossCommit %s', self.cross_key)
			raise Return(False)

		cls.cleanHalfPeriod()
		# 直接重置
		self.reset()
		self.cross_key = key
		raise Return(True)

	@classmethod
	def cross_client(cls, areaKey, cross_key=None):
		self = cls.getByAreaKey(areaKey)
		if cross_key is None:
			cross_key = self.cross_key
		if cross_key == '':
			return None
		container = self.server.container
		client = container.getserviceOrCreate(cross_key)
		return client

	@classmethod
	def getRankInfo(cls, roleID, areaKey):
		'''
		结束后的排行榜
		'''
		self = cls.getByAreaKey(areaKey)
		if self.cross_key == '' or self.round == 'closed':
			if not self._roleRankMap:
				for item in self.last_ranks:
					itemGameKey = MergeServ.getMergeServKey(item['game_key'])  # 转为合服名
					if itemGameKey != self.key:
						continue
					self._roleRankMap[item['role_db_id']] = (item['rank'], item['point'], item['special_fish_num'])
			myInfo = self._roleRankMap.get(roleID, (0, 0, 0))
			return {
				'ranks': self.last_ranks if len(self.last_ranks) <= cls.CrossFishingRankSize else self.last_ranks[:cls.CrossFishingRankSize],
				'rank': myInfo[0],
				'point': myInfo[1],
				'servers': self.last_servers,
				'special_fish_num': myInfo[2],
			}
		return None

	@classmethod
	def onRoleAuto(cls, roleID, areaKey, autoData):
		self = cls.getByAreaKey(areaKey)
		if self.round != 'start':
			return

		self.auto_roles[roleID] = autoData

	@classmethod
	def clearRoleAuto(cls, roleID, areaKey):
		self = cls.getByAreaKey(areaKey)
		if roleID not in self.auto_roles:
			return

		del self.auto_roles[roleID]

	@classmethod
	def onRoleLogin(cls, game):
		self = cls.getByAreaKey(game.role.areaKey)
		if self.round != "closed":
			return

		if game.role.id not in self.auto_roles:
			return

		cls.onAutoEnd(game)

	@classmethod
	def onAutoEnd(cls, game):
		self = cls.getByAreaKey(game.role.areaKey)
		autoData = self.auto_roles.pop(game.role.id, None)

		game.fishing.is_auto = False
		game.fishing.auto_stopped = True

		if autoData['cost']:
			cost = ObjectCostAux(game, autoData['cost'])
			if not cost.isEnough():
				logger.warning('ObjectCrossFishingGameGlobal.onAutoEnd role %d auto end cost not enough award %s', game.role.uid, unpack(autoData['award']))
				return
			cost.cost(src='cross_fishing_auto_end')
		else:
			logger.warning('ObjectCrossFishingGameGlobal.onAutoEnd role %d auto end has not cost award %s', game.role.uid, unpack(autoData['award']))

		win = 0
		isCrossDay, isCrossWeek = game.fishing.checkCross(autoData['time'])
		for fishID, count in autoData['fish'].iteritems():
			win += count
			if not isCrossDay:
				game.dailyRecord.fishing_record[fishID] = game.dailyRecord.fishing_record.get(fishID, 0) + 1
			if not isCrossWeek:
				game.fishing.week_record[fishID] = game.fishing.week_record.get(fishID, 0) + 1

		if not isCrossDay:
			game.dailyRecord.fishing_counter += win + autoData['fail']
			game.dailyRecord.fishing_win_counter += win
		ObjectYYHuoDongFactory.onGeneralTask(game, TargetDefs.FishingWinTimes, win)
		ObjectYYHuoDongFactory.onGeneralTask(game, TargetDefs.FishingTimes, win + autoData['fail'])

		game.fishing.point = autoData['info']['point']
		game.fishing.special_fish_num = autoData['info']['special_fish_num']

		for k, v in autoData['weight_record'].iteritems():
			game.fishing.weight_record[k] = v

		from game.mailqueue import MailJoinableQueue
		from game.object.game.role import ObjectRole
		from game.object.game.gain import ObjectGainAux

		totalWin = win + game.fishing.auto_win_counter
		totalFail = autoData['fail'] + game.fishing.auto_fail_counter
		oldAward = unpack(game.fishing.auto_award)
		oldAward.pop('fish', {})
		totalAwardEff = ObjectGainAux(game, oldAward)
		totalAwardEff += ObjectGainAux(game, unpack(autoData['award']))
		totalAward = totalAwardEff.to_dict()

		if totalAward:
			mail = ObjectRole.makeMailModel(game.role.id, CrossFishingAutoAwardMailID, contentArgs=(totalWin, totalFail), attachs=totalAward)
			MailJoinableQueue.send(mail)
		else:
			logger.warning('ObjectCrossFishingGameGlobal.onAutoEnd role %d auto end has not award cost win %s fail %s', game.role.uid, totalWin, totalFail)

		game.fishing.auto_award = {}

	@classmethod
	@coroutine
	def onClosed(cls, areaKey):
		logger.info("ObjectCrossFishingGameGlobal.onClosed")

		self = cls.getByAreaKey(areaKey)
		self.round = 'closed'

		from game.object.game import ObjectGame

		updateRoles = []
		for roleID in self.auto_roles.keys():
			autoData = self.auto_roles[roleID]
			if 'info' not in autoData:
				logger.info('_crossFishingAutoEnd role %s has not info', objectid2string(roleID))
				continue
			obj = ObjectGame.getByRoleID(roleID, safe=False)
			if not obj:
				continue

			try:
				if obj.role.areaKey != areaKey:
					continue
				ObjectCrossFishingGameGlobal.onAutoEnd(obj)
				updateRoles.append(autoData['info'])
			except:
				logger.exception('ObjectCrossFishingGameGlobal.onAutoEnd error role %s', objectid2string(roleID))

		rpc = cls.cross_client(areaKey)
		yield rpc.call_async('CrossFishingGameClosed', areaKey, updateRoles)
