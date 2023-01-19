#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2016 TianJi Information Technology Inc.
'''

from framework import inclock5date, nowdatetime_t, todaydate2int, nowtime_t, todayinclock5elapsedays, nowtime2int, time2int, OneDay, nowdate_t, int2date
from framework.csv import ErrDefs, csv, MergeServ
from framework.log import logger
from framework.object import db_property, ObjectNoGCDBase
from framework.helper import model2NamedTuple, timeSubTime
from framework.service.helper import service_key2domains, service_key, gamemerge2game

from game import globaldata, ClientError
from game.globaldata import *
from game.object import FeatureDefs, TitleDefs
from game.object.game.gain import ObjectGoodsMap, ObjectCostAux
from game.object.game.levelcsv import ObjectFeatureUnlockCSV

import re
import copy
import bisect
import random
import datetime
from collections import namedtuple, deque

from game.object.game.servrecord import ObjectServerGlobalRecord
from tornado.gen import coroutine, moment, sleep, Return
from tornado.ioloop import PeriodicCallback

RoleSignFields = ['id', 'area', 'name', 'logo', 'frame', 'level', 'figure', 'title_id', 'vip_level', 'cross_craft_record_db_id']

def model2signitem(d, fields, **kwargs):
	def _get(d, k):
		if isinstance(d, dict):
			if k in d:
				return d[k]
			return kwargs[k]
		if hasattr(d, k):
			return copy.deepcopy(getattr(d, k))
		return kwargs[k]
	dd = {k: _get(d, k) for k in fields}
	dd.update(kwargs)
	vip_hide = _get(d, 'vip_hide')
	if vip_hide:
		dd.update(vip_level=0)
	return dd

def betAward(gold, coin):
	award = {}
	if gold > 0:
		award['gold'] = gold
	if coin > 0:
		award['coin8'] = coin
	return award

class ObjectCrossCraftGameGlobal(ObjectNoGCDBase):
	DBModel = 'CrossCraftGameGlobal'

	Singleton = None

	OpenLevel = 0
	AutoSignVIP = 0
	BetAmount = {}

	PreBetExtraAward = None
	Top4BetExtraAward = None

	AutoSignRoleMap = {} # {Role.id: (name, logo, level, vip_level, cross_craft_record_db_id, top12_cards)} cross_craft_record_db_id必须>0

	GlobalObjsMap = {} # {areakey: ObjectCrossCraftGameGlobal}
	GlobalHalfPeriodObjsMap = {} # {areakey: ObjectCrossCraftGameGlobal}

	@classmethod
	def classInit(cls):
		cfg = csv.cross.craft.base[1]
		cls.OpenLevel = ObjectFeatureUnlockCSV.getOpenLevel(FeatureDefs.CrossCraft)
		cls.AutoSignVIP = cfg.autoSignVIP
		cls.BetAmount = {
			1: {'gold': cfg.preBetGold, 'coin8': cfg.preBetCoin}, # 预选押注
			2: {'gold': cfg.top4BetGold, 'coin8': cfg.top4BetCoin}, # top4押注
			3: {'gold': cfg.championBetGold, 'coin8': cfg.championBetCoin}, # 冠军押注
		}
		cls.PreBetExtraAward = cfg.preBetExtraAward
		cls.Top4BetExtraAward = cfg.top4BetExtraAward

		d = {}
		for roleID in cls.AutoSignRoleMap:
			item = cls.AutoSignRoleMap[roleID]
			if item['vip_level'] >= cls.AutoSignVIP:
				d[roleID] = item
		cls.AutoSignRoleMap = d

	def __init__(self, dbc):
		ObjectNoGCDBase.__init__(self, None, dbc)

	def set(self, dic):
		ObjectNoGCDBase.set(self, dic)
		self.isHalfPeriod = ObjectServerGlobalRecord.isHalfPeriod('cross_craft', self.key)
		return self

	def init(self, server, crossData):
		self.server = server
		self._roleRankMap = {} # {roleID: CraftRoleInfo}
		self._prePointRanks = []
		self._cross = None

		self.autoSignOK = False

		self._msginc = 0 # battle message 增量，辅助 broadcast
		self._broadcastime = 0

		self.initCrossData(crossData)

		cls = ObjectCrossCraftGameGlobal
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
	def getByAreaKey(cls, key):
		return cls.GlobalHalfPeriodObjsMap.get(key, cls.Singleton)

	def initCrossData(self, crossData):
		self._cross = crossData
		if crossData:
			logger.info('Cross Craft Init %s %s %s, csv_id %d', self.cross_key, self.date, self.round, self.csv_id)
			self.date = self._cross.get('date', 0)
			self.round = self._cross.get('round', 'closed')
			if self.csv_id > 0:
				self.version = csv.cross.service[self.csv_id].version
			self._battleMessages = deque(maxlen=CraftBattleMessageMax)
			self._lockCards = False
			self._lockTime = 0
			self._prepareOK = self._cross.get('prepare_ok', False)
		else:
			self.reset()

	def reset(self):
		logger.info('Cross Craft Reset %s %s %s', self.cross_key, self.date, self.round)
		self.round = 'closed'
		self.version = 0
		self.date = 0
		self.signup = {}
		self.cross_key = ''
		self._battleMessages = deque(maxlen=CraftBattleMessageMax)
		self._lockCards = False
		self.autoSignOK = False
		self._prepareOK = False
		return True

	@classmethod
	def initAutoSignUp(cls, models):
		from game.server import Server
		_, language, _ = service_key2domains(Server.Singleton.key)
		cls.AutoSignRoleMap = {}
		for model in models:
			if not model['cross_craft_record_db_id'] or model['disable_flag'] or model['top_cards'] < 12:
				continue
			cls.AutoSignRoleMap[model['id']] = model2signitem(model, RoleSignFields, game_key=gamemerge2game(service_key('game', model['area'], language)))
		logger.info('Cross Craft Init AutoSign Roles %d', len(cls.AutoSignRoleMap))

	@classmethod
	def cleanHalfPeriod(cls):
		for _, obj in cls.GlobalObjsMap.iteritems():
			if obj.isHalfPeriod: # 清除半周期状态
				ObjectServerGlobalRecord.overHalfPeroid('cross_craft', obj.key)
				obj.isHalfPeriod = ObjectServerGlobalRecord.isHalfPeriod('cross_craft', obj.key)
				obj.last_ranks = []
				obj.last_top8_plays = {}

		cls.GlobalHalfPeriodObjsMap = {}

	@classmethod
	@coroutine
	def onCrossCommit(cls, key, transaction):
		logger.info('ObjectCrossCraftGameGlobal.onCrossCommit %s %s', key, transaction)

		# cross竞争资源成功
		self = cls.Singleton
		# 玩法已经被占用
		if self.cross_key != '' and self.cross_key != key:
			logger.warning('ObjectCrossCraftGameGlobal.onCrossCommit %s', self.cross_key)
			raise Return(False)

		cls.cleanHalfPeriod()
		# 直接重置
		self.reset()
		self.cross_key = key
		raise Return(True)

	@classmethod
	@coroutine
	def onCrossEvent(cls, event, key, data, sync):
		logger.info('ObjectCrossCraftGameGlobal.onCrossEvent %s %s', key, event)

		self = cls.getByAreaKey(key)
		if sync:
			self.round = sync['round']
			self.time = sync['time']
			if sync['top8_plays']: # update to cross data
				self._cross.update(top8_plays=sync['top8_plays'])

		ret = {}
		if event == 'init':
			self.initCrossData(data['model'])
		elif event == 'signup':
			self.onStartSignUp()

		elif event == 'prepare':
			self.onAutoSignUp()
			self.onStartPrepare()
			# 强刷一遍在线玩家的record
			from game.object.game import ObjectGame
			from game.handler._cross_craft import refreshCardsToPVP
			allobjs, safeGuard = ObjectGame.getAll()
			with safeGuard:
				for game in allobjs:
					if game.role.id in self.signup:
						game.role.cross_craft_sign_up_date = self.date
						try:
							yield refreshCardsToPVP(self.server.rpcPVP, game, force=True)
						except:
							logger.exception('crossCraftDeploy error')

			ret['signup'] = self.signup.values()

		elif event == 'robot':
			signup = yield self.onMakeRobots(key, data.get('robot', 0))
			ret['signup'] = signup.values()

		elif event == 'prepare_ok':
			self._prepareOK = True

		elif event == 'prepare2':
			self.onStartPrepare2()

		elif event == 'matches':
			self.onStartRound()

		elif event == 'play':
			self.onPlayStart()

		elif event == 'new_play':
			self.onNewPlay(data['battle_message'])

		elif event == 'battle_award':
			self.onBattleAward(data['craft_roles'])

		elif event == 'pre_bet':
			self.onPreBetAward(data['craft_bets'])

		elif event == 'top4_bet':
			self.onTop4BetAward(data['craft_bets'])

		elif event == 'champion_bet':
			self.onChampionBetAward(data['craft_bets'])

		elif event == 'rank_award':
			self.onRankAward(data['craft_rank_map'])

		elif event == 'halftime':
			self.onHalftime()

		elif event == 'over':
			self.onOver(data['craft_ranks'])

		elif event == 'last_bet_info':
			self.onLastBetInfo(data['last_bet_info'])

		elif event == 'pre_point_rank':
			self.last_pre_point_ranks = data['pre_point_ranks']

		raise Return(ret)

	@classmethod
	def isOpen(cls, areaKey):
		# 没有开启跨服
		self = cls.getByAreaKey(areaKey)
		if self.cross_key == '' or self.date == 0:
			return False
		# 玩法过期
		delta = nowdate_t() - int2date(self.date)
		return delta < 2*OneDay

	@classmethod
	def isRoleOpen(cls, level):
		# 角色等级满足
		return level >= cls.OpenLevel

	@classmethod
	def isCanSignUp(cls, game):
		self = cls.getByAreaKey(game.role.areaKey)
		return self.round == 'signup' and game.role.cross_craft_record_db_id

	@classmethod
	def isCanBet(cls, areaKey):
		self = cls.getByAreaKey(areaKey)
		return self.round in ('signup', 'halftime')

	@classmethod
	def inBattle(cls, areaKey):
		self = cls.getByAreaKey(areaKey)
		if self.round[:7] != 'prepare':
			return self.round[:3] in ('pre', 'top', 'fin')
		return False

	@classmethod
	def prepareOK(cls, areaKey):
		self = cls.getByAreaKey(areaKey)
		return self._prepareOK

	@classmethod
	def onRoleInfo(cls, game):
		self = cls.getByAreaKey(game.role.areaKey)
		role = game.role
		if role.vip_level >= cls.AutoSignVIP and role.level >= cls.OpenLevel and role.cross_craft_record_db_id:
			if len(role.top_cards) < 12:
				return
			cls.AutoSignRoleMap[role.id] = model2signitem(role, RoleSignFields, game_key=game.role.areaKey)

			# 刷新自动报名的玩家数据
			# 如果报名已开始则自动报名
			if not cls.isSigned(game) and self.autoSignOK:
				if self.date == todaydate2int() and cls.isRoleOpen(game.role.level) and cls.isCanSignUp(game):
					cls.signUp(game)
		game.role.cross_craft_sign_up_date = self.date if role.id in self.signup else 0

	@classmethod
	def signUp(cls, game, cards=None, manual=False):
		self = cls.getByAreaKey(game.role.areaKey)
		role = game.role
		if role.id in self.signup:
			if not manual:
				manual = self.signup[role.id].get('manual', False)
		self.signup[role.id] = model2signitem(role, RoleSignFields, manual=manual, game_key=game.role.areaKey)
		game.role.cross_craft_sign_up_date = self.date

	@classmethod
	def isSigned(cls, game):
		self = cls.getByAreaKey(game.role.areaKey)
		signed = game.role.id in self.signup
		game.role.cross_craft_sign_up_date = self.date if signed else 0
		return signed

	@classmethod
	def isInSign(cls, areaKey):
		self = cls.getByAreaKey(areaKey)
		return self.round == 'signup'

	@classmethod
	def isInHalftime(cls, areaKey):
		self = cls.getByAreaKey(areaKey)
		return self.round == 'halftime'

	@classmethod
	def getRoundAndLockCards(cls, areaKey):
		self = cls.getByAreaKey(areaKey)
		return self.round, self._lockCards

	@classmethod
	def checkCanDeploy(cls, game):
		self = cls.getByAreaKey(game.role.areaKey)
		role = game.role
		if role.id not in self.signup:
			raise ClientError('not signup')

		# 已经结束
		if self.round in ('over', 'closed'):
			raise ClientError(ErrDefs.craftOver)

	@classmethod
	def getLastTop8(cls, ti, areaKey):
		self = cls.getByAreaKey(areaKey)
		if ti != self.last_refresh_time:
			return self.last_top8_plays
		return None

	# 开始报名 closed -> signup
	def onStartSignUp(self):
		logger.info('ObjectCrossCraftGameGlobal.onStartSignUp')
		# 自动报名倒计时
		delta = timeSubTime(datetime.time(hour=18), nowdatetime_t().time())
		self.server.ioloop.add_timeout(delta, self.onAutoSignUp)

	# 自动报名 signup
	def onAutoSignUp(self):
		cnt = 0
		if self.isHalfPeriod:  # 合服后，在半周期中
			srcServs = MergeServ.getSrcServKeys(self.key)
			for roleID, item in self.AutoSignRoleMap.iteritems():
				if item['game_key'] in srcServs and roleID not in self.signup:
					self.signup[roleID] = item
					cnt += 1
		else:
			for roleID, item in self.AutoSignRoleMap.iteritems():
				if self.key == MergeServ.getMergeServKey(item['game_key']) and roleID not in self.signup:
					self.signup[roleID] = item
					cnt += 1

		self.autoSignOK = True
		logger.info('ObjectCrossCraftGameGlobal.onAutoSignUp %d, signup %d', cnt, len(self.signup))

	# 报名结束 signup -> prepare
	def onStartPrepare(self):
		logger.info('ObjectCrossCraftGameGlobal.onStartPrepare')
		self._battleMessages = deque(maxlen=CraftBattleMessageMax)
		self._lockCards = False
		self.autoSignOK = False
		# 清空上次排行榜
		self.last_ranks = []
		self._roleRankMap = {}
		self.last_pre_point_ranks = []
		self.last_bet_info = {}
		self._prePointRanks = []

	# 构建机器人
	@coroutine
	def onMakeRobots(self, areaKey, number):
		if number <= 0:
			raise Return({})
		# 构建机器人
		robots = yield self._makeRobots(areaKey, number=number)

		# 创建机器人CraftRecord
		ret = yield self.server.rpcPVP.call_async('CreateRobotCrossCraftRecordBulk', robots.values())
		logger.info('ObjectCrossCraftGameGlobal.onStartPrepare Create Robot CrossCraftRecord Finished %s', ret)

		# 机器人进入参赛名单
		signup = {}
		for roleID, d in robots.iteritems():
			area = int(areaKey.split('.')[-1])
			signup[roleID] = model2signitem(d, RoleSignFields, cross_craft_record_db_id=roleID, vip_level=0, game_key=areaKey, area=area, vip_hide=False)
		raise Return(signup)

	# 中场休息结束 halftime -> prepare2
	def onStartPrepare2(self):
		logger.info('ObjectCrossCraftGameGlobal.onStartPrepare2')
		self._lockCards = False

	# 每局准备阶段开始 (pre1, pre2, ..., final3)
	def onStartRound(self):
		logger.info('ObjectCrossCraftGameGlobal.onStartRound')
		self._lockCards = False
		self.broadcast()

	# 每局准备阶段结束 (pre1, ..., final3) -> (pre1_lock, ..., final3_lock)
	def onPlayStart(self):
		logger.info('ObjectCrossCraftGameGlobal.onPlayStart %s', self.round)
		self._lockCards = True
		self._lockTime = nowtime_t()

	# 有新战斗结果
	def onNewPlay(self, playMsg):
		roleKey1, roleKey2 = playMsg['roles']
		if roleKey2[1]:
			name1, name2 = playMsg['names']
			self._battleMessages.append((playMsg['round'], (roleKey1, name1), (roleKey2, name2), playMsg['result'], playMsg['points'], playMsg['streak']))

			# 根据策略进行广播
			self._msginc += 1
			if self.round[:5] == 'final' or self.round[:3] == 'top' or self._msginc > 100 or nowtime_t () - self._broadcastime > 10:
				self.broadcast()

	def refreshRankCache(self):
		if not self._roleRankMap:
			for rank, role in enumerate(self.last_ranks, 1):
				self._roleRankMap[role['role_db_id']] = role

	@classmethod
	def getRankList(cls, offest, size, roleID, areaKey):
		self = cls.getByAreaKey(areaKey)
		if self.cross_key == '' or self.round in ('signup', 'over', 'closed'):
			self.refreshRankCache()
			return {
				'ranks': self.last_ranks[offest:offest + size],
				'myinfo': self._roleRankMap.get(roleID, None),
			}
		return None

	@classmethod
	def getLastBetInfo(cls, roleID, areaKey):
		self = cls.getByAreaKey(areaKey)
		last_bet_info = self.last_bet_info
		return {
			'pre_bet': last_bet_info['pre_bet'].get(roleID, []),
			'top4_bet': last_bet_info['top4_bet'].get(roleID, []),
			'champion_bet': last_bet_info['champion_bet'],
			'mychampion_bet': last_bet_info['role_bet_champion'].get(roleID, [None, ""]),
		}

	@classmethod
	def getLastPrePointRank(cls, offest, size, areaKey):
		self = cls.getByAreaKey(areaKey)
		if self.cross_key == '' or self.round in ('over', 'closed'):
			if not self._prePointRanks:
				self.refreshRankCache()
				ranks = [] # CrossCraftRole+point
				for v in self.last_pre_point_ranks:
					role = self._roleRankMap[v['id']]
					ranks.append({
						'role_db_id': role['role_db_id'],
						'record_db_id': role['record_db_id'],
						'game_key': role['game_key'],
						'name': role['name'],
						'logo': role['logo'],
						'frame': role['frame'],
						'level': role['level'],
						'figure': role['figure'],
						'title': role['title'],
						'vip': role['vip'],
						'point': v['point'],
						'fighting_point': v['fighting_point'],
					})
				self._prePointRanks = ranks
			return self._prePointRanks[offest:offest + size]
		return None

	# 发战斗奖励(第一天和第二天都有)
	def onBattleAward(self, roles):
		logger.info('ObjectCrossCraftGameGlobal.onBattleAward %s', len(roles))
		from game.mailqueue import MailJoinableQueue
		from game.object.game.role import ObjectRole
		for roleID, t in roles.iteritems():
			if 'rbt' in roleID: # robot
				continue
			win, lose, point = t
			award = None
			if win > 0:
				award = ObjectGoodsMap(None, csv.cross.craft.base[1].winAward)
				award *= win
			if lose > 0:
				award2 = ObjectGoodsMap(None, csv.cross.craft.base[1].failAward)
				award2 *= lose
				if award:
					award += award2
				else:
					award = award2
			if award:
				mail = ObjectRole.makeMailModel(roleID, CrossCraftRoundAwardMailID, contentArgs=(win, lose, point), attachs=award.to_dict())
				MailJoinableQueue.send(mail)

	# 预选押注奖励
	def onPreBetAward(self, bets):
		logger.info('ObjectCrossCraftGameGlobal.onPreBetAward %s', len(bets))
		from game.mailqueue import MailJoinableQueue
		from game.object.game.role import ObjectRole
		for betRoleID, result in bets.iteritems():
			wingold, wincoin, wincount = result['win_gold'], result['win_coin'], result['win_count']
			failgold, failcoin, failcount = result['fail_gold'], result['fail_coin'], result['fail_count']
			if wincount > 0:
				if failcount == 0: # 全部成功
					mailID = CrossCraftPreBetAllWinMailID
					award = ObjectGoodsMap(self.game, betAward(wingold, wincoin))
					award += ObjectGoodsMap(self.game, self.PreBetExtraAward)
					mail = ObjectRole.makeMailModel(betRoleID, mailID, attachs=award.to_dict())
					MailJoinableQueue.send(mail)
				else:
					mailID = CrossCraftPreBetWinMailID
					contentArgs = wincount
					award = betAward(wingold, wincoin)
					mail = ObjectRole.makeMailModel(betRoleID, mailID, contentArgs=contentArgs, attachs=award)
					MailJoinableQueue.send(mail)
			if failcount > 0:
				mailID = CrossCraftPreBetFailMailID
				contentArgs = failcount
				award = betAward(failgold, failcoin)
				if not award: # 可能3个没压全
					continue
				mail = ObjectRole.makeMailModel(betRoleID, mailID, contentArgs=contentArgs, attachs=award)
				MailJoinableQueue.send(mail)

	# 四强押注奖励
	def onTop4BetAward(self, bets):
		logger.info('ObjectCrossCraftGameGlobal.onTop4BetAward %s', len(bets))
		from game.mailqueue import MailJoinableQueue
		from game.object.game.role import ObjectRole
		for betRoleID, result in bets.iteritems():
			wingold, wincoin, wincount = result['win_gold'], result['win_coin'], result['win_count']
			failgold, failcoin, failcount = result['fail_gold'], result['fail_coin'], result['fail_count']
			if wincount > 0:
				if failcount == 0: # 全部成功
					mailID = CrossCraftTop4BetAllWinMailID
					award = ObjectGoodsMap(self.game, betAward(wingold, wincoin))
					award += ObjectGoodsMap(self.game, self.Top4BetExtraAward)
					mail = ObjectRole.makeMailModel(betRoleID, mailID, attachs=award.to_dict())
					MailJoinableQueue.send(mail)
				else:
					mailID = CrossCraftTop4BetWinMailID
					contentArgs = wincount
					award = betAward(wingold, wincoin)
					mail = ObjectRole.makeMailModel(betRoleID, mailID, contentArgs=contentArgs, attachs=award)
					MailJoinableQueue.send(mail)
			if failcount > 0:
				mailID = CrossCraftTop4BetFailMailID
				contentArgs = failcount
				award = betAward(failgold, failcoin)
				if not award: # 可能3个没压全
					continue
				mail = ObjectRole.makeMailModel(betRoleID, mailID, contentArgs=contentArgs, attachs=award)
				MailJoinableQueue.send(mail)

	# 冠军押注奖励
	def onChampionBetAward(self, bets):
		logger.info('ObjectCrossCraftGameGlobal.onChampionBetAward %s', len(bets))
		from game.mailqueue import MailJoinableQueue
		from game.object.game.role import ObjectRole
		for betRoleID, result in bets.iteritems():
			wingold, wincoin = result['win_gold'], result['win_coin']
			failgold, failcoin = result['fail_gold'], result['fail_coin']
			if wingold or wincoin:
				mailID = CrossCraftChampionBetWinMailID
				award = betAward(wingold, wincoin)
			else:
				mailID = CrossCraftChampionBetFailMailID
				award = betAward(failgold, failcoin)
			mail = ObjectRole.makeMailModel(betRoleID, mailID, attachs=award)
			MailJoinableQueue.send(mail)

	# 排行奖励
	def onRankAward(self, craftRankMap):
		from game.mailqueue import MailJoinableQueue
		from game.object.game.role import ObjectRole

		self._roleRankMap = {}
		ranks = {} # {roleID: rank}
		for rank, role in craftRankMap.iteritems():
			servKey, roleID = role['game_key'], role['role_db_id']
			ranks[roleID] = rank
		logger.info('ObjectCrossCraftGameGlobal.onRankAward %s', len(ranks))

		cfgs = []
		cfgRanks = []
		for idx in sorted(csv.cross.craft.rank.keys()):
			cfg = csv.cross.craft.rank[idx]
			if cfg.version != self.version:
				continue
			cfgs.append(cfg)
			cfgRanks.append(cfg.rankMax)

		for roleID, rank in ranks.iteritems():
			if 'rbt' in roleID: # robot
				continue
			idx = bisect.bisect_left(cfgRanks, rank)
			cfg = cfgs[idx]
			if rank <= cfg.rankMax:
				mail = ObjectRole.makeMailModel(roleID, CrossCraftRankAwardMailID, contentArgs=rank, attachs=cfg.award)
				MailJoinableQueue.send(mail)

		# 跨服石英称号
		from game.object.game.servrecord import ObjectServerGlobalRecord
		ObjectServerGlobalRecord.saveTitleRanks(TitleDefs.CrossCraft, ranks)

	# 第一天结束 pre24 -> halfttime
	def onHalftime(self):
		logger.info('ObjectCrossCraftGameGlobal.onHalftime')
		self._lockCards = False

	# 全部结束 final3 -> over
	def onOver(self, allRanks):
		logger.info('ObjectCrossCraftGameGlobal.onOver')
		self.last_ranks = allRanks
		self.last_top8_plays = self.top8_plays
		self.signup = {}

		self.round = 'closed'

		self.onClosed()
		# 清理数据倒计时
		# self.server.ioloop.add_timeout(OneDay, self.onClosed)

	# 清理数据 over -> closed
	def onClosed(self):
		logger.info('ObjectCrossCraftGameGlobal.onClosed')
		self.reset()

	# 下注缓存数据
	def onLastBetInfo(self, info):
		self.last_bet_info.setdefault('pre_bet', {})
		self.last_bet_info.setdefault('top4_bet', {})
		self.last_bet_info.setdefault('champion_bet', {})
		self.last_bet_info.setdefault('role_bet_champion', {})

		self.last_bet_info['pre_bet'].update(info['pre_bet'])
		self.last_bet_info['top4_bet'].update(info['top4_bet'])
		self.last_bet_info['champion_bet'].update(info['champion_bet'])
		self.last_bet_info['role_bet_champion'].update(info['role_bet_champion'])

	@classmethod
	def getSlimModel(cls, areaKey):
		self = cls.getByAreaKey(areaKey)
		round, time = self.round, self.time
		# 在cross不存在lock状态，game模拟下
		if self._lockCards and round[:3] in ('pre', 'top', 'fin') and round[:7] != 'prepare':
			round = '%s_lock' % self.round
			time = self._lockTime
		servers = []
		buffs = []
		top8_plays = None
		if self._cross:
			servers = self.servers
			buffs = self.buffs
			top8_plays = self.top8_plays
		return {
			'time': time,
			'date': self.date,
			'servers': servers,
			'round': round,
			'buffs': buffs,
			'battle_messages': list(self._battleMessages),
			'top8_plays': top8_plays,
			'last_refresh_time': self.last_refresh_time,
			'version': self.version,
		}

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

	def broadcast(self):
		self._msginc = 0
		self._broadcastime = nowtime_t()
		data = {
			'model': {
				'cross_craft': {
					'battle_messages': list(self._battleMessages),
				}
			}
		}
		from game.session import Session
		Session.broadcast('/game/push', data, filter=lambda g: not g.role.cross_craft_record_db_id)

	# 构造机器人
	@coroutine
	def _makeRobots(self, areaKey, number=100):
		from framework.helper import randomRobotName
		from game.object.game.card import ObjectCard, randomCharacter, randomNumericalValue

		logger.info('Cross Craft Start Make Robots %d, Total %d', number, number + len(self.signup))

		robots = {}
		fakeCard = ObjectCard(None, None)
		fakeCard.new_deepcopy() # just for delete dbc
		pool = set(csv.cross.craft.robot.keys())
		number = min(number, len(pool))

		for idx in xrange(1, number+1):
			if idx % 10 == 0:
				logger.info('Cross Craft Making Robots %d / %d', idx, number)
			roleID = self.server.getRobotObjectID(idx, 'cross_craft', areaKey) # 机器人RoleID
			csvID = random.choice(list(pool))
			pool.discard(csvID)
			cfg = csv.cross.craft.robot[csvID]
			level = cfg.levelMax
			# make card
			roleCards = []
			roleCardAttrs = {}
			for i in xrange(1, 13):
				card_id = cfg['card%d' % i]
				cardCfg = csv.cards[card_id]
				equips = {}
				for k, v in enumerate(cardCfg.equipsList):
					if v not in csv.equips:
						equips = None
						break
					equips[k + 1] = {
						'equip_id': v,
						'level': 1,
						'star': 0,
						'advance': 1,
						'exp': 0,
						'awake': 0,
					}
				if equips is None:
					continue
				cardID = 'card-%07d' % i
				fakeCard.set({
					'id': cardID,
					'role_db_id': roleID,
					'card_id': card_id,
					'skin_id': 0,
					'advance': random.randint(*cfg['advance%d' % i]),
					'star': random.randint(*cfg['star%d' % i]),
					'develop': cardCfg.develop,
					'level': int(level * random.uniform(*cfg['levelC%d' % i])),
					'character': randomCharacter(cardCfg.chaRnd),
					'nvalue': randomNumericalValue(cardCfg.nValueRnd),
					'skills': {},
					'skill_level': [],
					'effort_values': {},
					'effort_advance': 1,
					'equips': equips,
					'fetters': [],
					'fighting_point': 0,
					'held_item': None,
					'abilities': {},
				}).initRobot()
				roleCards.append(cardID)
				attrs = fakeCard.battleModel(False, False, 0)

				# 强制修正
				attrs['attrs']['hp'] *= random.uniform(*cfg['hpC%d' % i])
				attrs['attrs']['damage'] *= random.uniform(*cfg['damageC%d' % i])
				attrs['attrs']['defence'] *= random.uniform(*cfg['defenceC%d' % i])
				attrs['fighting_point'] = ObjectCard.calcFightingPoint(fakeCard, attrs['attrs'])
				roleCardAttrs[cardID] = attrs
				yield moment

			# make role
			# 数据格式参照 role.competitor, embattle
			robots[roleID] = {
				'id': roleID,
				'name': randomRobotName(),
				'level': level,
				'logo': random.randint(1, 2),
				'frame': 1,
				'figure': random.choice([1, 2, 3, 7, 27]),
				'title_id': 0,

				'cards': roleCards,
				'card_attrs': roleCardAttrs,
			}

		logger.info('Cross Craft End Make Robots %d, Total %d', len(robots), len(robots) + len(self.signup))
		raise Return(robots)

	# servkey
	key = db_property('key')

	# 跨服server key
	cross_key = db_property('cross_key')

	# 日期
	date = db_property('date')

	# CraftGlobal.time
	time = db_property('time')

	# CraftGlobal.round
	round = db_property('round')

	# 报名 {Role.id: RoleSignItem}
	signup = db_property('signup')

	# 上期排行榜
	last_ranks = db_property('last_ranks')

	# 上期8强战斗记录
	def last_top8_plays():
		dbkey = 'last_top8_plays'
		def fset(self, value):
			self.db[dbkey] = value
			self.last_refresh_time = time2int(nowdatetime_t())
		return locals()
	last_top8_plays = db_property(**last_top8_plays())

	# last_top8_plays的刷新时间
	last_refresh_time = db_property('last_refresh_time')

	# 上期竞猜数据
	last_bet_info = db_property('last_bet_info')

	# 上期预选赛积分排行
	last_pre_point_ranks = db_property('last_pre_point_ranks')

	# cross 同步数据
	@property
	def servers(self):
		return self._cross.get('servers', [])

	@property
	def csv_id(self):
		return self._cross.get('csv_id', 0)

	@property
	def top8_plays(self):
		return self._cross.get('top8_plays', {})

	@property
	def buffs(self):
		return self._cross.get('buffs', [])
