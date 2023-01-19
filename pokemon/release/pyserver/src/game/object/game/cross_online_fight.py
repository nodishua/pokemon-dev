#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2014 YouMi Information Technology Inc.
'''

from framework import str2num_t, weekinclock5date2int, nowdatetime_t, int2date
from framework.csv import csv, MergeServ
from framework.log import logger
from framework.object import ObjectNoGCDBase, db_property
from framework.helper import objectid2string, upperBound, lowerBound
from game.globaldata import CrossOnlineFightFinalAwardMailID, CrossOnlineFightWeeklyAwardMailID, CrossOnlineFightWeeklyNoAwardMailID
from game.object import FeatureDefs, AttrDefs, SceneDefs, TitleDefs, MessageDefs
from game.object.game.levelcsv import ObjectFeatureUnlockCSV
from game.object.game.card import ObjectCard
from game.object.game.gain import ObjectGainAux
from game.object.game.robot import setRobotCard
from game.object.game.message import ObjectMessageGlobal
from game.object.game.fake import FakeTrainer, FakeExplorer, FakeUnionSkills
from game.object.game.servrecord import ObjectServerGlobalRecord

from tornado.gen import coroutine, moment, sleep, Return, Future
import datetime

#
# ObjectCrossOnlineFightGameGlobal
#
class ObjectCrossOnlineFightGameGlobal(ObjectNoGCDBase):
	DBModel = 'CrossOnlineFightGameGlobal'

	Singleton = None

	OpenLevel = 0
	BattleWinAward = None
	BattleFailAward= None
	MatchTime = 0 # 每日有奖励匹配
	MatchTimeMax = 0 # 每日最大匹配次数
	LeastCardNum = 0 # 公平赛备选卡组最少数量
	MostCardNum = 0 # 公平赛备选卡组最多数量
	WeeklyTarget = 0 # 周目标奖励类型(1-胜场次数;2-参与次数)
	WeeklyAwardLeastTimes = 0 # 周结算奖励至少参与次数
	NormalMatchTimeout = 0 # 普通匹配超时(秒)
	LongMatchTimeout = 0 # 长匹配超时(秒)

	LimitedCards = None # [(card_id, markID)]
	ThemeOpens = {}

	# 全队属性加成
	Trainer = None
	Explorer = None
	UnionSkills = None

	GlobalObjsMap = {} # {areakey: ObjectCrossArenaGameGlobal}
	GlobalHalfPeriodObjsMap = {} # {areakey: ObjectCrossArenaGameGlobal}

	@classmethod
	def classInit(cls):
		cls.OpenLevel = ObjectFeatureUnlockCSV.getOpenLevel(FeatureDefs.CrossOnlineFight)

		cfg = csv.cross.online_fight.base[1]
		cls.BattleWinAward = cfg.battleWinAward
		cls.BattleFailAward = cfg.battleFailAward
		cls.MatchTime = cfg.matchTime
		cls.MatchTimeMax = cfg.matchTimeMax
		cls.LeastCardNum = cfg.leastCardNum
		cls.MostCardNum = cfg.mostCardNum
		cls.WeeklyTarget = cfg.weeklyTarget
		cls.WeeklyAwardLeastTimes = cfg.weeklyAwardLeastTimes
		cls.NormalMatchTimeout = cfg.normalMatchTimeout
		cls.LongMatchTimeout = cfg.longMatchTimeout

		cls.LimitedCards = []
		for csvID in csv.cross.online_fight.cards:
			cfg = csv.cross.online_fight.cards[csvID]
			cls.LimitedCards.append((cfg.cardId, csv.cards[cfg.cardId].cardMarkID))

		trainer_attr_skills = {}
		explorers = {}
		components = {}
		union_skills = {}
		for i in csv.cross.online_fight.team:
			cfg = csv.cross.online_fight.team[i]
			if cfg.system == 'union_skill':
				union_skills[cfg.csvID] = cfg.level
			elif cfg.system == 'explorer':
				explorers[cfg.csvID] = {'advance': cfg.level}
			elif cfg.system == 'component':
				components[cfg.csvID] = cfg.level
			elif cfg.system == 'attr_skills':
				trainer_attr_skills[cfg.csvID] = cfg.level
		cls.Trainer = FakeTrainer(trainer_attr_skills)
		cls.Explorer = FakeExplorer(explorers, components)
		cls.UnionSkills = FakeUnionSkills(union_skills)

		cls.ThemeOpens = {}
		for idx in csv.cross.online_fight.theme_open:
			cfg = csv.cross.online_fight.theme_open[idx]
			cls.ThemeOpens[cfg.day] = cfg

	@classmethod
	def getByAreaKey(cls, key):
		return cls.GlobalHalfPeriodObjsMap.get(key, cls.Singleton)

	def __init__(self, dbc):
		ObjectNoGCDBase.__init__(self, None, dbc)

		self.round = 'closed'

	def set(self, dic):
		ObjectNoGCDBase.set(self, dic)
		self.isHalfPeriod = ObjectServerGlobalRecord.isHalfPeriod('cross_online_fight', self.key)
		return self

	def init(self, server, data):
		self.server = server
		self.battleResults = {} # {roleID: Future}
		if data:
			self._cross = data
			self.round = data['round']
		else:
			self._cross = {}
			self.round = 'closed'
			self.cross_key = ''
		self._roleCacheMap = {}

		cls = ObjectCrossOnlineFightGameGlobal
		cls.GlobalObjsMap[self.key] = self
		# global对象 key与当前服key对应
		if self.key == self.server.key:
			cls.Singleton = self

		# 是在半周期的话
		if self.isHalfPeriod:
			srcServs = MergeServ.getSrcServKeys(self.key)
			for srcServ in srcServs:
				cls.GlobalHalfPeriodObjsMap[srcServ] = self

	@classmethod
	def cleanHalfPeriod(cls):
		for _, obj in cls.GlobalObjsMap.iteritems():
			if obj.isHalfPeriod: # 清除半周期状态
				ObjectServerGlobalRecord.overHalfPeroid('cross_online_fight', obj.key)
				obj.isHalfPeriod = ObjectServerGlobalRecord.isHalfPeriod('cross_online_fight', obj.key)
				obj.last_unlimited_top_battle_history = []
				obj.last_unlimited_top_battle_history = []

		cls.GlobalHalfPeriodObjsMap = {}

	@classmethod
	@coroutine
	def onCrossCommit(cls, key, transaction):
		logger.info('ObjectCrossOnlineFightGameGlobal.onCrossCommit %s %s', key, transaction)

		# cross竞争资源成功
		self = cls.Singleton
		# 玩法已经被占用
		if self.cross_key != '' and self.cross_key != key:
			logger.warning('ObjectCrossOnlineFightGameGlobal.onCrossCommit %s', self.cross_key)
			raise Return(False)

		cls.cleanHalfPeriod()
		self.cross_key = key
		raise Return(True)

	@classmethod
	@coroutine
	def onCrossEvent(cls, event, key, data, sync):
		logger.info('ObjectCrossOnlineFightGameGlobal.onCrossEvent %s %s', key, event)

		self = cls.getByAreaKey(key)
		if sync:
			self._cross = sync

		ret = {}
		if event == 'init':
			self._cross = data['model']
		elif event == 'start':
			# TODO: 刷新所有在线角色记录
			pass
		elif event == 'over':
			pass
		elif event == 'closed':
			self.onClosed()
		elif event == 'top_history':
			ObjectMessageGlobal.marqueeBroadcast(None, MessageDefs.MqCrossOnlineFightTopHistoryRefresh)
			ObjectMessageGlobal.newsCrossOnlineFightTopHistoryRefreshMsg()
		elif event == 'new_battles':
			for battle in data['new_battles']:
				self.onNewBattle(battle)
		elif event == 'battle_results':
			for result in data['battle_results']:
				yield self.onBattleResult(result)
		elif event == 'match_discard':
			self.onMatchDiscard(data['discards'])
		elif event == 'calc_cards':
			cards = yield self.calcCards(data['csv_ids'])
			ret['cards'] = cards
		elif event == 'rank_titles':
			self.onRankTitle(data['rank_titles'])
		elif event == 'weekly_award_ranks':
			self.onWeeklyAwardRanks(data['weekly_award_ranks'])
		elif event == 'final_award_ranks':
			self.onFinalAwardRanks(data['final_award_ranks'])
		elif event == 'unlimited_ranks':
			self.onUnlimitedRanks(data['unlimited_ranks'])
		elif event == 'limited_ranks':
			self.onLimitedRanks(data['limited_ranks'])

		raise Return(ret)

	@classmethod
	def isOpen(cls, areaKey):
		# 没有开启跨服
		self = cls.getByAreaKey(areaKey)
		if self.cross_key == '':
			return False
		return True

	@classmethod
	def isRoleOpen(cls, level):
		# 角色等级满足
		return level >= cls.OpenLevel

	# 匹配到对手
	def onNewBattle(self, battle):
		toRoleID = battle['role']['role_db_id']
		self.battleResults[toRoleID] = Future()
		from game.object.game import ObjectGame
		game = ObjectGame.getByRoleID(toRoleID, safe=False)
		if game:
			game.dailyRecord.cross_online_fight_times += 1

		battle.pop('role', None)
		from game.session import Session
		data = {
			'cross_online_fight': battle
		}
		Session.broadcast('/game/push', data, roles=[toRoleID])

	# 匹配超时
	def onMatchDiscard(self, discards):
		from game.session import Session
		data = {
			'cross_online_fight': {
				'match_result': {'matching': 0},
			}
		}
		Session.broadcast('/game/push', data, roles=discards)

	# 战斗结算
	@coroutine
	def onBattleResult(self, view):
		roleID = view['role_id']
		result = view['result']

		from game.object.game import ObjectGame
		game, guard = ObjectGame.getByRoleID(roleID)
		if not result:
			if game:
				game.dailyRecord.cross_online_fight_times -= 1
		else:
			if game:
				with guard:
					if game.dailyRecord.cross_online_fight_times <= self.MatchTime:
						award = None
						if result == 'win':
							award = self.BattleWinAward
						elif result in ('fail', 'giveup', 'offline'): # flee 逃跑不给奖励
							award = self.BattleFailAward
						if award:
							from game.handler.inl import effectAutoGain
							eff = ObjectGainAux(game, award)
							yield effectAutoGain(eff, game, self.server.dbcGame, src='online_fight_battle')
							view['award'] = eff.result

					# 1. 同步历史最高积分
					if game.role.cross_online_fight_info['unlimited_top_score'] < view['unlimited_top_score']:
						game.role.cross_online_fight_info['unlimited_top_score'] = view['unlimited_top_score']
					if game.role.cross_online_fight_info['limited_top_score'] < view['limited_top_score']:
						game.role.cross_online_fight_info['limited_top_score'] = view['limited_top_score']
					# 2. 刷新周目标奖励
					self.recordRoleWeeklyTimes(game.role, result)
			else:
				logger.info('onBattleResult, role %s game maybe clean, result %s', objectid2string(roleID), result)

		if roleID in self.battleResults:
			# if self.battleResults[roleID].running():
			self.battleResults[roleID].set_result(view)
			# else:
			# 	logger.warning('onBattleResult, role %s already setdone', objectid2string(roleID))
		else:
			logger.warning('onBattleResult, role %s miss battle future', objectid2string(roleID))

	# 称号
	def onRankTitle(self, ranks):
		logger.info('ObjectCrossOnlineFightGameGlobal.onRankTitle')
		from game.object.game.servrecord import ObjectServerGlobalRecord
		ObjectServerGlobalRecord.saveTitleRanks(TitleDefs.CrossOnlineFightUnlimited, ranks[1])
		ObjectServerGlobalRecord.saveTitleRanks(TitleDefs.CrossOnlineFightLimited, ranks[2])

	# 周结算积分奖励
	def onWeeklyAwardRanks(self, scores):
		from game.mailqueue import MailJoinableQueue
		from game.object.game.role import ObjectRole

		logger.info('ObjectCrossOnlineFightGameGlobal.onWeeklyAwardRanks %s', len(scores))
		cfgs = []
		for idx in sorted(csv.cross.online_fight.weekly_award.keys()):
			cfg = csv.cross.online_fight.weekly_award[idx]
			if cfg.version != self.version:
				continue
			cfgs.append(cfg)
		total = len(cfgs)

		for roleID, (score, times) in scores.iteritems():
			if times >= self.WeeklyAwardLeastTimes:
				idx = lowerBound(cfgs, score, key=lambda x:x.score[0])
				cfg = cfgs[idx]
				mail = ObjectRole.makeMailModel(roleID, CrossOnlineFightWeeklyAwardMailID, contentArgs=score, attachs=cfg.award)
			else:
				mail = ObjectRole.makeMailModel(roleID, CrossOnlineFightWeeklyNoAwardMailID, contentArgs=(score, self.WeeklyAwardLeastTimes))
			MailJoinableQueue.send(mail)

	# 赛季结算排名奖励
	def onFinalAwardRanks(self, ranks):
		from game.mailqueue import MailJoinableQueue
		from game.object.game.role import ObjectRole

		logger.info('ObjectCrossOnlineFightGameGlobal.onFinalAwardRanks %s, version %d', len(ranks), self.version)
		cfgs = []
		for idx in sorted(csv.cross.online_fight.final_award.keys()):
			cfg = csv.cross.online_fight.final_award[idx]
			if cfg.version != self.version:
				continue
			cfgs.append(cfg)
		total = len(cfgs)
		for roleID, rank in ranks.iteritems():
			idx = upperBound(cfgs, rank, key=lambda x:x.rankMax)
			if idx >= total: # 超过上限，用最后一个奖励
				idx = -1
			cfg = cfgs[idx]
			mail = ObjectRole.makeMailModel(roleID, CrossOnlineFightFinalAwardMailID, contentArgs=rank, attachs=cfg.award)
			MailJoinableQueue.send(mail)

	# 无限赛缓存排名
	def onUnlimitedRanks(self, ranks):
		self.last_unlimited_ranks = ranks
		self._roleCacheMap = {}

	# 公平赛缓存排名
	def onLimitedRanks(self, ranks):
		self.last_limited_ranks = ranks
		self._roleCacheMap = {}

	def onClosed(self):
		logger.info('ObjectCrossOnlineFightGameGlobal.onClosed')
		self.last_unlimited_top_battle_history = self.unlimited_top_battle_history
		self.last_limited_top_battle_history = self.limited_top_battle_history
		self._cross = {}
		self.round = 'closed'
		self.cross_key = ''

	def refreshRoleCache(self):
		if not self._roleCacheMap:
			# {roleid: {unlimited_score, limited_score, unlimited_rank, limited_rank}}
			for rank, d in enumerate(self.last_unlimited_ranks, 1):
				if d['game_key'] == self.server.key:
					info = self._roleCacheMap.setdefault(d['role_db_id'], {})
					info.update(unlimited_score=d['score'], unlimited_rank=rank)

			for rank, d in enumerate(self.last_limited_ranks, 1):
				if d['game_key'] == self.server.key:
					info = self._roleCacheMap.setdefault(d['role_db_id'], {})
					info.update(limited_score=d['score'], limited_rank=rank)

	@classmethod
	def getRoleCacheInfo(cls, role):
		self = cls.getByAreaKey(role.areaKey)
		self.refreshRoleCache()
		return self._roleCacheMap.get(role.id, None)

	@classmethod
	def getRankList(cls, offset, size, roleID, pattern, areaKey):
		self = cls.getByAreaKey(areaKey)
		if pattern == 1:
			return self.last_unlimited_ranks[offset:offset + size]
		else:
			return self.last_limited_ranks[offset:offset + size]

	@classmethod
	def getLastSlimModel(cls, areaKey):
		self = cls.getByAreaKey(areaKey)
		return {
			'round': self.round,
			'unlimited_top_battle_history': self.last_unlimited_top_battle_history,
			'limited_top_battle_history': self.last_limited_top_battle_history,
		}

	@classmethod
	def refreshRoleCrossOnlineFightInfo(cls, game):
		role = game.role
		self = cls.getByAreaKey(role.areaKey)
		if self.start_date != role.cross_online_fight_info['start_date']: # 赛季刷新
			role.cross_online_fight_info['start_date'] = self.start_date
			role.cross_online_fight_info.setdefault('unlimited_top_score', 0) # 玩家非限制赛历史最高积分，赛季不重置
			role.cross_online_fight_info.setdefault('limited_top_score', 0) # 玩家公平赛历史最高积分，赛季不重置
			role.cross_online_fight_info['weekly_date'] = 0
			role.cross_online_fight_info['weekly_win_times'] = 0
			role.cross_online_fight_info['weekly_battle_times'] = 0
			role.cross_online_fight_info['weekly_target'] = {}

		ndt = weekinclock5date2int()
		if role.cross_online_fight_info['weekly_date'] != ndt: # 周刷新
			role.cross_online_fight_info['weekly_date'] = ndt
			role.cross_online_fight_info['weekly_win_times'] = 0
			role.cross_online_fight_info['weekly_battle_times'] = 0
			role.cross_online_fight_info['weekly_target'] = {}

	@classmethod
	def recordRoleWeeklyTimes(cls, role, result):
		if result == "flee" or result == "giveup": # 逃跑/认输不计入周目标次数
			return
		win = result == 'win'
		role.cross_online_fight_info['weekly_battle_times'] += 1
		if win:
			role.cross_online_fight_info['weekly_win_times'] += 1
		times = role.cross_online_fight_info['weekly_win_times'] if cls.WeeklyTarget == 1 else role.cross_online_fight_info['weekly_battle_times']
		role.cross_online_fight_info.setdefault('weekly_target', {})
		for csvid in csv.cross.online_fight.weekly_target:
			cfg = csv.cross.online_fight.weekly_target[csvid]
			if cfg.type == cls.WeeklyTarget and csvid not in role.cross_online_fight_info['weekly_target']:
				if times >= cfg.count:
					role.cross_online_fight_info['weekly_target'][csvid] = 1

	@classmethod
	def getLastBattleResultFuture(cls, role):
		self = cls.getByAreaKey(role.areaKey)
		future = self.battleResults.get(role.id, None)
		return future

	@classmethod
	def isRoleInBattle(cls, role):
		self = cls.getByAreaKey(role.areaKey)
		future = self.battleResults.get(role.id, None)
		return future and future.running()

	@classmethod
	def popLastBattleResult(cls, role):
		self = cls.getByAreaKey(role.areaKey)
		self.battleResults.pop(role.id, None)

	@classmethod
	def makeLimitedBattleCards(cls, game):
		markIDs = set(game.cards.markIDMaxStar.keys())
		cards = []
		for card_id, markID in cls.LimitedCards:
			if markID in markIDs:
				# TODO: 符合该期主题要求
				cards.append(card_id)
		if len(cards) < cls.LeastCardNum:
			return []
		return cards[:cls.MostCardNum]

	@classmethod
	def checkLimitedBattleCards(cls, game, cards, least=None):
		markIDs = set(game.cards.markIDMaxStar.keys())
		valids = set()
		for card_id, markID in cls.LimitedCards:
			if markID in markIDs:
				valids.add(card_id)
		total = len(cards)
		if len(cards) != len(valids & set(cards)):
			return False
		if least is None:
			least = cls.LeastCardNum
		if total > cls.MostCardNum or total < least:
			return False
		# TODO: 检查是否符合该期主题要求
		return True

	@classmethod
	def checkUnlimitedBattleCards(cls, game, cards):
		self = cls.getByAreaKey(game.role.areaKey)
		days = (nowdatetime_t() - datetime.datetime.combine(int2date(self.start_date), datetime.time(hour=5))).days + 1 # 固定5点，和golang那边逻辑一致，和语言区域无关
		if days <= 0 or days not in cls.ThemeOpens:
			logger.warning('days is %d, need checked', days)
			return True
		cfg = cls.ThemeOpens[days]
		for cardID in cards:
			if cardID:
				card = game.cards.getCard(cardID)
				if not card:
					return False
				if card.isMega and card.card_id in cfg.invalidMegaCardIDs: # 非限制赛禁用Meag卡的card_id
					return False
				elif card.markID in cfg.invalidMarkIDs: # 非限制赛禁用markID（不包含Mega）
					return False
		return True

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
	@coroutine
	def calcCards(cls, csvIds):
		cards = {}
		fakeCard = ObjectCard(None, None)
		fakeCard.new_deepcopy()  # just for delete dbc
		for idx, csvId in enumerate(csvIds, 1):
			if idx % 100 == 0:
				logger.info('Cross OnlineFight Making Cards %d / %d', idx, len(csvIds))
			cfg = csv.cross.online_fight.cards[csvId]
			card_id = cfg.cardId
			if card_id not in csv.cards:
				continue
			setRobotCard(fakeCard, card_id, cfg.advance, cfg.star, cfg.level,
				character=0,
				nvalue=cfg.nvalue,
				abilities=cfg.abilities,
				skillLevels=cfg.skillLevels,
				equipStar=cfg.equipStar,
				equipLevel=cfg.equipLevel,
				equipAwake=cfg.equipAwake,
				equipAdvance=cfg.equipAdvance)
			fetters = csv.cards[card_id].fetterList if cfg.fetters else None
			ObjectCard.calcStarEffectAttrsAddition(fakeCard)
			ObjectCard.calcFettersAttrsAddition(fakeCard, fetters)
			ObjectCard.calcTrainerAttrSkillAddition(fakeCard, cls.Trainer)
			ObjectCard.calcExplorerAttrsAddition(fakeCard, cls.Explorer)
			ObjectCard.calcExplorerComponentAttrsAddition(fakeCard, cls.Explorer)
			ObjectCard.calcUnionSkillAttrsAddition(fakeCard, cls.UnionSkills)
			model = fakeCard.battleModel(False, False, SceneDefs.CrossOnlineFight, explorer=cls.Explorer)
			# 属性修正
			for attr in AttrDefs.attrsEnum[1:]:
				if attr in cfg and cfg[attr]:
					constVal, percentVal = str2num_t(cfg[attr])
					if constVal > 0:
						model['attrs'][attr] += constVal
					if percentVal > 0:
						model['attrs'][attr] *= percentVal
			model['fighting_point'] = ObjectCard.calcFightingPoint(fakeCard, model['attrs'])
			cards[csvId] = model
			yield moment

		raise Return(cards)

	@classmethod
	@coroutine
	def makeCardAttrs(cls):
		from game.object import AttrDefs
		csvIds = sorted(csv.cross.online_fight.cards.keys())
		cards = yield cls.calcCards(csvIds)
		logs = []
		log = ['card_id'] + [x for x in AttrDefs.attrsEnum[1:]] + ['fighting_point']
		logs.append(','.join(log) + '\n')
		for csvid in csvIds:
			card = cards[csvid]
			logger.info('card %d, fighting_point %s', card['card_id'], card['fighting_point'])
			log = [str(card['card_id'])] + [str(card['attrs'].get(x, 0)) for x in AttrDefs.attrsEnum[1:]] + [str(card['fighting_point'])]
			logs.append(','.join(log) + '\n')

		with open('cross_online_fight_cards.csv', 'w') as fp:
			fp.writelines(logs)
		logger.info('write to file cross_online_fight_cards.csv finish')

	# servkey
	key = db_property('key')

	# 跨服server key
	cross_key = db_property('cross_key')

	# 上期非限制赛排名
	last_unlimited_ranks = db_property('last_unlimited_ranks')

	# 上期公平赛排名
	last_limited_ranks = db_property('last_limited_ranks')

	# 上期精彩战报
	last_unlimited_top_battle_history = db_property('last_unlimited_top_battle_history')

	last_limited_top_battle_history = db_property('last_limited_top_battle_history')

	# 赛季开始时间
	@property
	def start_date(self):
		return self._cross.get('start_date', 0)

	# 赛季结束时间
	@property
	def end_date(self):
		return self._cross.get('end_date', 0)

	# 奖励版本
	@property
	def version(self):
		return self._cross.get('version', 0)

	@property
	def theme_id(self):
		return self._cross.get('theme_id', 0)

	@property
	def unlimited_top_battle_history(self):
		return self._cross.get('unlimited_top_battle_history', [])

	@property
	def limited_top_battle_history(self):
		return self._cross.get('limited_top_battle_history', [])
