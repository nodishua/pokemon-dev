#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2014 YouMi Information Technology Inc.
'''
from __future__ import absolute_import

from framework import int2date, nowtime_t, nowdate_t, todayinclock5date2int, is_qq_channel, inclock5date, nowdatetime_t, todayelapsedays, datetimefromtimestamp, inclockNdate2int, weekinclock5date2int, str2num_t, nowtime2period, time2period, datetimefromtimestamp, monthinclock5date2int, todayinclock5elapsedays, date2int, DailyRefreshHour
from framework.csv import csv, ErrDefs, ConstDefs
from framework.log import logger
from framework.object import ObjectDBase, db_property, db_ro_property
from framework.helper import WeightRandomObject, getL10nCsvValue, transform2list, upperBound, objectid2string
from framework.service.helper import service_key2domains, service_key, gamemerge2game
from game import ClientError, ServerError
from game.object import MapDefs, TaskDefs, RechargeDefs, UnionDefs, YYHuoDongDefs, HuoDongDefs, FeatureDefs, TargetDefs, DispatchTaskDefs, DrawSumBoxDefs, AchievementDefs, CrossArenaDefs, MegaDefs, GymDefs, ReunionDefs, CardSkinDefs, TitleDefs, DailyAssistantDefs
from game import globaldata
from game.globaldata import *
from game.object.game import ObjectEndlessTowerGlobal, ObjectDailyAssistant
from game.object.game.cross_arena import ObjectCrossArenaGameGlobal
from game.object.game.target import predGen
from game.object.game.wmap import ObjectMap
from game.object.game.calculator import zeros
from game.object.game.gain import ObjectGainAux, ObjectGainEffect, ObjectCostAux, ObjectGoodsMap
from game.object.game.huodong import ObjectHuoDongFactory
from game.object.game.yyhuodong import ObjectYYHuoDongFactory, ObjectYYMonthlyCard, ObjectYYDirectBuyGift
from game.object.game.costcsv import ObjectCostCSV
from game.object.game.union import ObjectUnion, ObjectUnionContribTask, ObjectUnionCanSendRedPacket
from game.object.game.message import ObjectMessageGlobal
from game.object.game.servrecord import ObjectServerGlobalRecord
from game.object.game.craft import ObjectCraftInfoGlobal
from game.object.game.union_fight import ObjectUnionFightGlobal
from game.object.game.lottery import ObjectDrawRandomItem
from game.object.game.levelcsv import ObjectFeatureUnlockCSV
from game.object.game.cross_craft import ObjectCrossCraftGameGlobal
from game.object.game.cross_fishing import ObjectCrossFishingGameGlobal
from game.object.game.cross_mine import ObjectCrossMineGameGlobal
from game.object.game.cross_online_fight import ObjectCrossOnlineFightGameGlobal
from game.object.game.gym import ObjectGymGameGlobal
from game.object.game.cross_union_fight import ObjectCrossUnionFightGameGlobal

import copy
import random
import datetime
import math
from collections import defaultdict
from game.thinkingdata import ta

# dbField, csvField, src
GateAwardMap = {
	'chest': ('chest', 'chestAward', 'gate_chest'),
	'win': ('win_award', 'winAward', 'gate_win'),
	'star3': ('star3_award', 'star3Award', 'gate_star3'),
}

#
# ObjectRole
#

class ObjectRole(ObjectDBase):
	DBModel = 'Role'
	ClientIgnores = set([
		'stable_drop_weights',
		'recharges_cache',
		'gifts',
		# 'recharges',
	])

	LevelSumExp = {}
	LevelMax = 0
	OneOffRecharges = [] # 用来QQ充值纠错用
	TitleRankMap = {} # {feature: {rank: csv_id}}
	UnionSkillIDLevelMap = {}  # {(skillID, level): csv}
	DispatchTaskQualityMap = {} # {quality: [cfg, ]}
	HuoDongGateIndexMap = {} # {gateID: index}
	ChatLimit = [] # [(gateStarSum, correction), ]

	CitySpriteGroups = {} # {groups: [cfg]}
	CitySpriteMiniQ = None

	GrowGuideTargetMap = {} # {type: [csvid, ...]}
	UnionTitles = []  # [csvID]

	@classmethod
	def classInit(cls):
		levels = csv.base_attribute.role_level
		sumExp = 0
		cls.LevelSumExp = {}
		cls.LevelSumExp[0] = 0
		cls.LevelMax = len(levels)
		for level in xrange(1, cls.LevelMax):
			sumExp += levels[level].levelExp
			cls.LevelSumExp[level] = sumExp

		cls.OneOffRecharges = []
		for idx in csv.recharges:
			cfg = csv.recharges[idx]
			if cfg.type == RechargeDefs.OneOffType:
				cls.OneOffRecharges.append((cfg.rmb, idx))
		cls.OneOffRecharges.sort()

		cls.TitleRankMap = {}
		cls.UnionTitles = []
		for idx in csv.title:
			cfg = csv.title[idx]
			if cfg.feature:
				d = cls.TitleRankMap.setdefault(cfg.feature, {})
				d[cfg.rank] = idx
			if cfg.kind == TitleDefs.UnionKind:
				cls.UnionTitles.append(idx)

		# 公会修炼
		cls.UnionSkillIDLevelMap = {}
		for i in csv.union.union_skill_level:
			cfg = csv.union.union_skill_level[i]
			cls.UnionSkillIDLevelMap[(cfg.level, cfg.skillID)] = cfg

		# 公会成就红包
		cls.UnionRedpacketMap = {}
		for i in csv.union.red_packet:
			cfg = csv.union.red_packet[i]
			csvIDs = cls.UnionRedpacketMap.get(cfg.conditionType, [])
			csvIDs.append(i)
			cls.UnionRedpacketMap[cfg.conditionType] = csvIDs

		# 派遣任务
		cls.DispatchTaskQualityMap = {}
		for i in csv.dispatch_task.tasks:
			cfg = csv.dispatch_task.tasks[i]
			cls.DispatchTaskQualityMap.setdefault(cfg.quality, []).append(cfg)

		# 主城精灵
		cls.CitySpriteGroups = {}
		miniQ = []
		for i in csv.city_sprites:
			cfg = csv.city_sprites[i]
			if not cfg.active: continue  # 如果未启用就无视

			if cfg.type == CitySpriteMiniQType:
				miniQ.append((i, cfg.weight))
			else:
				cls.CitySpriteGroups.setdefault(cfg.group, []).append(cfg)
		cls.CitySpriteMiniQ = WeightRandomObject(miniQ)

		# 成长向导
		cls.GrowGuideTargetMap = {}
		for i in csv.grow_guide:
			cfg = csv.grow_guide[i]
			if cfg.type == 2: # 任务
				cls.GrowGuideTargetMap.setdefault(cfg.taskType, []).append(i)
			elif cfg.type == 1: # unlock奖励, 用等级来作为触发类型
				cls.GrowGuideTargetMap.setdefault(TargetDefs.Level, []).append(i)

		# 碎片副本
		cls.HuoDongGateIndexMap = {}
		for i in csv.huodong:
			cls.HuoDongGateIndexMap[i] = {}
			if i == HuoDongDefs.TypeFrag:
				for ii in csv.huodong_gate_fragment:
					cfg = csv.huodong_gate_fragment[ii]
					for index, gateID in enumerate(cfg['gateGroup']):
						cls.HuoDongGateIndexMap[i][gateID] = index

			cfg = csv.huodong[i]
			for index, gateID in enumerate(cfg['gateSeq']):
				cls.HuoDongGateIndexMap[i][gateID] = index

			for index, gateID in enumerate(cfg['gateSeq2']):
				cls.HuoDongGateIndexMap[i][gateID] = index

			for index, gateID in enumerate(cfg['gateLimitSeq'], len(cls.HuoDongGateIndexMap[i])):
				cls.HuoDongGateIndexMap[i][gateID] = index

		# 聊天限制数量
		cls.ChatLimit = []
		for idx in csv.chat_limit:
			cfg = csv.chat_limit[idx]
			cls.ChatLimit.append((cfg.gateStarSum, cfg.correction))
		cls.ChatLimit = sorted(cls.ChatLimit, key=lambda x: x[0])

	def set(self, dic):
		ObjectDBase.set(self, dic)
		from game.server import Server
		service, language, _ = service_key2domains(Server.Singleton.key)
		self.areaKey = gamemerge2game(service_key(service, self.area, language))  # 不论是否合服，角色都使用原始服信息
		self._lastchat = None # (msg, count)
		self._silent_time = 0 # 禁言开始时间
		self.huntingSync = 0  # 是否已同步过

		self.last_login_time = self.last_time # 做缓存，上次登录时间，last_time是上次请求时间

		# temp fix
		if self.db['level_exp'] < 0:
			logger.info('role %d %s old level %d, sum_exp %d, level_exp %d', self.uid, self.pid, self.db['level'], self.db['sum_exp'], self.db['level_exp'])
			self.db['level'] = 1
			while self.db['level'] < self.LevelMax and ObjectRole.LevelSumExp[self.db['level']] <= self.db['sum_exp']:
				self.db['level'] += 1
			self.db['level_exp'] = self.db['sum_exp'] - ObjectRole.LevelSumExp[self.db['level'] - 1]
			logger.info('role %d %s new level %d, sum_exp %d, level_exp %d', self.uid, self.pid, self.db['level'], self.db['sum_exp'], self.db['level_exp'])

		import framework
		if hasattr(framework, '__dev__'):
			if self.db['level'] > self.LevelMax:
				self.db['level'] = self.LevelMax

		self.game.items.set()
		self.game.frags.set()
		self.game.tasks.set()
		self.game.talentTree.set()
		self.game.pokedex.set()
		self.game.trainer.set()
		self.game.feels.set()
		self.game.zawake.set()
		self.game.explorer.set()
		self.game.achievement.set()
		self.game.gymTalentTree.set()
		self.game.badge.set()

		self._figureAdd = defaultdict(dict)#形象加成{natureType:{attr:value}}
		self._titleAdd = defaultdict(dict)  # 称号 属性加成
		self._unionStillAdd = defaultdict(dict)  # 公会修炼中心 属性加成
		return self

	def init(self):
		'''
		初始化依赖Role Model存储的数据
		'''
		if self.sign_in_gift[0] == 0:
			self.sign_in_gift = [1, -1]

		if self.endless_tower_current == 0:
			self.endless_tower_current = ObjectEndlessTowerGlobal.MinGate

		self._gate_star_sum = 0
		self._vip_sum = 0
		self._mail = {}
		self._qq_orders_cache = defaultdict(list) # {rechargeID: []} 只是为了让QQ订单号尽量与数据库对应
		self.yyOpen = None
		self.reunionYYID = None
		self.yyDelta = {}
		self.yyHDID = {}
		self.unionMemberRefreshTime = 0 # 公会成员数据上次刷新时间
		self.unionMemberRefreshFuture = None
		self.union_packet_last_time = nowtime_t() # 公会成员红包上次刷新时间
		self.union_role_packet_can_rob = False # 公会成员红包是否有可抢的
		self.union_sys_packet_can_rob = False # 公会系统红包是否有可抢的
		self.cloneBoxDrawNum = 0 # 元素挑战开宝箱次数
		self.cloneSelectMonster = 0 # 元素挑战选择的精灵
		self.huodongsIndex = {} # 活动开启可扫荡最大索引
		self.displayDirty = False # 用于竞技场显示刷新
		self.yyDouble11GameStartTime = 0 # 用于双十一小游戏作弊检测
		self._chat_times_correction = 0
		self.assistant_flags = {}  # 用于小助手弹窗确认交互
		self.yyDispatchCards = None

		self._inited = False


		self.game.items.init()
		self.game.frags.init()
		self.game.tasks.init()
		self.game.talentTree.init()
		self.game.pokedex.init()
		self.game.privilege.init()
		self.game.trainer.init()
		self.game.feels.init()
		self.game.explorer.init()
		self.game.gymTalentTree.init()
		self.game.badge.init()
		self.game.zawake.init()
		self.game.chips.init()

		self._initMap()
		self._initVIPLevel()
		self._initUnion()
		self._initTitle()
		self._initCardSkin()
		self._initFigure()
		self._initUnionSkill()
		self._initHuoDongIndex()
		self._initSkillFigures()

		self.refreshYYOpen()
		self.game.achievement.init()
		self.game.title.init()

		self.initChipPlanCache()  # 芯片方案缓存

		from game.session import Session
		Session.onSkinRefresh(-1)
		Session.onRoleRefresh(-1)

		self._inited = True

		self.onGrowGuideTask(TargetDefs.Level, 0)

		return ObjectDBase.init(self)

	def _fixCorrupted(self):
		# craft、cross craft银币转换成金币
		if self.coin7 or self.coin9:
			import math
			from game.mailqueue import MailJoinableQueue
			for old, new, mailID in (('coin7', 'coin6', CraftCoinTransType), ('coin9', 'coin8', CrossCraftCoinTransType)):
				oldCoin = getattr(self, old, 0)
				if oldCoin > 0:
					# 每100个银币转换成83个金币，最后数值按照整100向上取整，并多加100
					transNum = int(math.ceil(oldCoin * 83 / 10000.0) * 100 + 100)
					cost = ObjectCostAux(self.game, {old: oldCoin})
					cost.cost(src='%s_transform' % old)
					mail = self.makeMailModel(self.id, mailID, contentArgs=(oldCoin, transNum), attachs={new: transNum})
					MailJoinableQueue.send(mail)

	def refreshYYOpen(self, refreshDelta=True):
		# 活动开启，减轻客户端YYGetActive请求次数，直接使用game model数据即可
		old = self.yyOpen
		self.yyOpen = ObjectYYHuoDongFactory.getRoleOpenList(self.level, self.created_time, self.vip_level)
		if refreshDelta or old != self.yyOpen:
			self.yyDelta = ObjectYYHuoDongFactory.getEventDeltaTimes(self.yyOpen, self.game)
			self.yyHDID = ObjectYYHuoDongFactory.getEventHuodongIDs(self.yyOpen, self.game)

	def initRobot(self):
		# self.game.items.init()
		# self.game.frags.init()
		# self.game.tasks.init()

		self.game.talentTree.init()
		self.game.pokedex.init()
		self.game.privilege.init()
		self.game.trainer.init()
		self.game.feels.init()
		self.game.explorer.init()
		self.game.badge.init()

		self._initMap()
		self._initVIPLevel()
		self._initTitle()
		self._initCardSkin()
		self._initFigure()
		self._initUnionSkill()

		self.refreshStamina()
		self.refreshSkillPoint()
		# self._mail = {}

		return ObjectDBase.init(self)

	def _initMap(self):
		worldNS, mapNS, gateNS = set(), set(), set()
		# 忽略未胜利通关的
		starS = set([gateID for gateID, d in self.gate_star.iteritems() if d['star'] > 0])
		ObjectMap.WorldMap.flood(self.game, self.level, starS, worldNS, mapNS, gateNS)

		def inequal_set(k, l):
			if self.db[k] != l:
				self.db[k] = l
		inequal_set('world_open', list(worldNS))
		inequal_set('map_open', list(mapNS))
		inequal_set('gate_open', list(gateNS))

		# 星级总数只计算普通，精英，噩梦，活动等都不算
		types = (MapDefs.TypeGate, MapDefs.TypeHeroGate, MapDefs.TypeNightmareGate)
		self._gate_star_sum = sum([d.get('star', 0) for gateID, d in self.gate_star.iteritems() if gateID in csv.scene_conf and csv.scene_conf[gateID].sceneType in types])

	def _initVIPLevel(self):
		rechargeSt = self.recharges.get(FreeVIPRechargeID, {})
		sumRMB = rechargeSt.get('cnt', 0)
		for rechargeID, d in self.recharges.iteritems():
			# TestOrderID 是测试用（或者月卡自动获得）
			# QQOrderID 是QQ防错补齐的
			if rechargeID == FreeVIPRechargeID:
				continue
			if rechargeID not in csv.recharges:
				logger.warning('recharge %d not existed', rechargeID)
				continue
			cfg = csv.recharges[rechargeID]
			cnt = d.get('cnt', 0)
			sumRMB += cnt * cfg.rmb
		level = 0
		for i in csv.vip:
			if csv.vip[i].upSum > sumRMB:
				break
			level = i - 1
		self._vip_sum = sumRMB
		self.vip_level = level

	def _initUnion(self):
		# 状态由 rpcUnion.onLogin进行初始化
		self._union_place = UnionDefs.NonePlace

		if self.union_db_id:
			self.game.union = ObjectUnion.ObjsMap.get(self.union_db_id, None)
			ObjectUnionCanSendRedPacket.refreshCanSend(self.game)

	def isUnionChairman(self):
		return self._union_place == UnionDefs.ChairmanPlace

	def isUnionViceChairman(self):
		return self._union_place == UnionDefs.ViceChairmanPlace

	# 公会中地位
	def union_place():
		def fget(self):
			return self._union_place
		def fset(self, value):
			self._union_place = value
		return locals()
	union_place = property(**union_place())

	@property
	def mem(self):
		craftInfoGlobal = ObjectCraftInfoGlobal.Singleton
		unionFightGlobal = ObjectUnionFightGlobal.Singleton
		crossFishingGlobal = ObjectCrossFishingGameGlobal.getByAreaKey(self.areaKey)
		crossOnlinefightGlobal = ObjectCrossOnlineFightGameGlobal.getByAreaKey(self.areaKey)
		crossCraftGlobal = ObjectCrossCraftGameGlobal.getByAreaKey(self.areaKey)
		crossMineGlobal = ObjectCrossMineGameGlobal.getByAreaKey(self.areaKey)
		crossArenaGlobal = ObjectCrossArenaGameGlobal.getByAreaKey(self.areaKey)
		servGlobal = ObjectServerGlobalRecord.Singleton
		crossUnionFightGlobal = ObjectCrossUnionFightGameGlobal.getByAreaKey(self.areaKey)
		ret = {
			'game_key': self.areaKey,
			'card_capacity': self.card_capacity,
			'gate_star_sum': self._gate_star_sum,
			'vip_sum': self._vip_sum,
			'union_level': self.union_level,
			'union_place': self._union_place,
			'yy_open': self.yyOpen,
			'yy_delta': self.yyDelta,
			'yy_hdid': self.yyHDID,
			'trainer_level_exp': self.game.trainer.level_exp,
			'union_role_packet_can_rob': self.union_role_packet_can_rob,
			'union_sys_packet_can_rob': self.union_sys_packet_can_rob,
			'union_fuben_passed': self.game.union.fuben_passed if self.game.union else 0,
			'card_deployment': self.game.cards.deployment,
			'huodongs_index': self.huodongsIndex,
			"union_fight_round": unionFightGlobal.round,
			"cross_fishing_round": crossFishingGlobal.round,
			'cross_online_fight_round': crossOnlinefightGlobal.round,
			'cross_mine_round': crossMineGlobal.round,
			'cross_mine_boss_time': crossMineGlobal.getBossTime(),
			'in_cross_online_fight_battle': ObjectCrossOnlineFightGameGlobal.isRoleInBattle(self),
			'in_union_fight_top8': ObjectUnionFightGlobal.inTop8(self.game.role.union_db_id),
			'craft_round': craftInfoGlobal.round,
			'cross_craft_round': crossCraftGlobal.round,
			'cross_arena_round': crossArenaGlobal.round,
			'cross_union_fight_status': crossUnionFightGlobal.status,
			'in_cross_union_fight_join': crossUnionFightGlobal.inJoinUnions(self.game.role.union_db_id),
			'unionqa_round': servGlobal.unionqa_round,
			'hunting_sync': self.huntingSync,
		}
		return ret

	# 合服依然唯一
	@property
	def accountKey(self):
		return (self.area, self.account_id)

	# 用于方面查找Role，单服唯一
	uid = db_ro_property('uid')

	# Account.id
	account_id = db_ro_property('account_id')

	# 用户来源渠道，只有QQ消费钻石的时候用
	channel = db_ro_property('channel')

	# 账号所选区服，合服用
	area = db_ro_property('area')

	# 昵称
	def name():
		dbkey = 'name'
		def fset(self, value):
			self.db[dbkey] = value
			self.displayDirty = True
		return locals()
	name = db_property(**name())

	# 重命名的次数
	rename_count = db_property('rename_count')

	# 个性签名
	personal_sign = db_property('personal_sign')

	# 创建时间
	created_time = db_ro_property('created_time')

	# 上次登陆时间
	last_time = db_property('last_time')

	# 角色头像ID
	def logo():
		dbkey = 'logo'
		def fset(self, value):
			self.db[dbkey] = value
			self.displayDirty = True
		return locals()
	logo = db_property(**logo())

	# 角色拥有头像
	logos = db_property('logos')

	# 角色头像框ID
	def frame():
		dbkey = 'frame'
		def fset(self, value):
			self.db[dbkey] = value
			self.displayDirty = True
		return locals()
	frame = db_property(**frame())

	# 角色拥有的头像框
	frames = db_property('frames')

	# 角色形象ID
	def figure():
		dbkey = 'figure'
		def fset(self, value):
			self.db[dbkey] = value
			self.displayDirty = True
		return locals()
	figure = db_property(**figure())

	# 角色拥有的形象
	figures = db_property('figures')

	# 形象技能所属角色形象{figureID: skillFigureID} -1置空  字段废弃
	skill_figure = db_property('skill_figure')

	# 形象技能设置
	skill_figures = db_property('skill_figures')

	def _initSkillFigures(self):
		if self.skill_figure:
			for figureID, skillFigureID in self.skill_figure.iteritems():
				self.skill_figures[figureID] = [] if skillFigureID == -1 else [skillFigureID]
				logger.info('figureID: %s, old: %s => new: %s', figureID, skillFigureID, self.skill_figures[figureID])
			self.skill_figure = {}

	# 形象可装备技能数量
	figure_skill_count = db_property('figure_skill_count')

	# 卡牌背包购买容量
	card_capacity_buy = db_property('card_capacity_buy')

	# 卡牌背包容量购买次数
	card_capacity_times = db_property('card_capacity_times')

	# 卡牌背包容量
	@property
	def card_capacity(self):
		return ConstDefs.cardBagCapacity + self.card_capacity_buy

	# 卡牌背包剩余容量
	@property
	def card_capacity_free(self):
		return self.card_capacity - len(self.cards)

	def checkCardCapacityEnough(self, capacity):
		if capacity > self.card_capacity_free:
			raise ClientError(ErrDefs.cardCapacityLimit)

	#精灵图鉴
	pokedex = db_property('pokedex')

	#精灵图鉴突破
	pokedex_advance = db_property('pokedex_advance')

	# 金币
	def gold():
		dbkey = 'gold'
		def fset(self, value):
			old = self.db[dbkey]
			self.db[dbkey] = value
			if 0 <= value < old:
				ObjectYYHuoDongFactory.onGoldCost(self.game, old - value)
				ObjectYYHuoDongFactory.onGeneralTask(self.game, TargetDefs.CostGold, old - value)
				ObjectUnionContribTask.onCount(self.game, TargetDefs.CostGold, old - value)
				self.game.achievement.onCount(AchievementDefs.CostGoldCount, old - value)
			elif value > old:
				ObjectYYHuoDongFactory.onGeneralTask(self.game, TargetDefs.GainGold, value - old)
				self.game.achievement.onCount(AchievementDefs.GoldCount, value - old)
		return locals()
	gold = db_property(**gold())

	# RMB钻石
	def rmb():
		dbkey = 'rmb'
		def fset(self, value):
			old = self.db[dbkey]
			self.db[dbkey] = value
			# 扣费
			if 0 <= value < old:
				ObjectYYHuoDongFactory.onRMBCost(self.game, old - value)
				ObjectUnionContribTask.onCount(self.game, TargetDefs.CostRmb, old - value)
				self.rmb_consume += old - value
				self.game.dailyRecord.consume_rmb_sum += old - value
				# QQ渠道需要特殊处理，先QQ扣费，再扣游戏内的，防止QQ扣费失败
				if value < self.qq_rmb:
					self.costQQRMB(self.qq_rmb - value)
			elif value > old:
				self.game.achievement.onCount(AchievementDefs.RmbCount, value - old)
		return locals()
	rmb = db_property(**rmb())

	def setRMBWithoutRecord(self, value):
		old = self.db['rmb']
		self.db['rmb'] = value
		# 扣费
		if 0 <= value < old:
			# QQ渠道需要特殊处理
			if value < self.qq_rmb:
				self.costQQRMB(self.qq_rmb - value)

	def setGoldWithoutRecord(self, value):
		self.db['gold'] = value

	# QQ托管钻石
	def qq_rmb():
		dbkey = 'qq_rmb'
		def fset(self, value):
			value = max(0, value)
			self.db[dbkey] = value
		return locals()
	qq_rmb = db_property(**qq_rmb())

	# QQ充值总额
	qq_recharge = db_property('qq_recharge')

	# 扣费，要调用QQ消费接口，是否扣除成功也不是关键操作
	# 充值，靠数据同步save_amt增量，靠同步balance直接覆盖
	# 上层先扣除rmb，再调用costQQRMB扣除qq_rmb
	# qq_rmb只是用来扣除，不会用来同步rmb
	def costQQRMB(self, cost):
		if not is_qq_channel(self.channel):
			return

		# 这里是特殊写法
		try:
			from game.server import Server
			balance = Server.payQQRMBSync(self.game, cost)
			self.qq_rmb = min(balance, self.rmb)

		except:
			pass

	# QQ同步会失败，不再以qq_rmb来同步rmb
	def setQQRMB(self, val):
		if not is_qq_channel(self.channel):
			return

		# QQ托管钻石不可能多于游戏钻石
		self.qq_rmb = min(val, self.rmb)

	def _makeRecharges(self, val, p=None):
		if p is None:
			p = len(self.OneOffRecharges) - 1

		if val == 0:
			return []
		elif val < 0 or p < 0:
			return None

		t = self.OneOffRecharges[p]
		use = True
		ret = self._makeRecharges(val - t[0], p)
		if ret is None:
			ret = self._makeRecharges(val - t[0], p - 1)
			if ret is None:
				ret = self._makeRecharges(val, p - 1)
				use = False
		if ret is not None:
			return ([t] if use else []) + ret

	# payment 通知失败等原因导致更新不及时时，使用该接口来保证recharges数据正确
	def setQQRecharge(self, val):
		if not is_qq_channel(self.channel):
			return

		bad = False
		step = val - self.qq_recharge
		if step > 0:
			# 模拟计算step的组成，相应的rmb也会加上
			seq = self._makeRecharges(step)
			seq2 = []
			if seq:
				for amount, rechargeID in seq:
					orders = self._qq_orders_cache[rechargeID]
					orderID = QQOrderID # QQOrderID 是QQ防错补齐的
					if orders:
						orderID = orders[-1]
						del orders[-1]
					self.buyRecharge(rechargeID, orderID)
					seq2.append((amount, orderID))
			else:
				bad = True
				# TODO: 出现过支付98，但查询充值为56，可能某处逻辑先给多了，所以差值无法模拟出充值
				# 这里先发钻石，但首冲奖励就没了
				self.rmb += step
				self.addVIPExp(step) # 增加VIP经验
				ObjectYYHuoDongFactory.onRecharge(self.game, step)

			self.qq_recharge = val
			self.qq_rmb = min(self.qq_rmb + step, self.rmb)
			logger.info('role %d had qq recharges %d step %d %s', self.game.role.id, val, step, seq2)

		if bad or step < 0:
			logger.warning('role %d had wrong qq recharges %d step %d bad %s', self.game.role.id, val, step, bad)

	def syncQQRecharge(self, rechargeID, orderID):
		# payment只是做个通知，game重新查询余额
		self._qq_orders_cache[rechargeID].append(orderID)

		# 这里是特殊写法
		from game.server import Server
		Server.getBalanceQQRMBSync(self.game)

	# RMB钻石消耗
	rmb_consume = db_property('rmb_consume')

	# 代币1 - 竞技场
	def coin1():
		dbkey = 'coin1'
		def fset(self, value):
			old = self.db[dbkey]
			self.db[dbkey] = value
			if value > old:
				self.game.achievement.onCount(AchievementDefs.ArenaCoin1Count, value - old)
		return locals()
	coin1 = db_property(**coin1())

	# 代币2 - 远征
	def coin2():
		dbkey = 'coin2'
		def fset(self, value):
			self.db[dbkey] = value
		return locals()
	coin2 = db_property(**coin2())

	# 代币3 - 公会
	def coin3():
		dbkey = 'coin3'
		def fset(self, value):
			self.db[dbkey] = value
		return locals()
	coin3 = db_property(**coin3())

	# 代币4 - 寻宝币
	def coin4():
		dbkey = 'coin4'
		def fset(self, value):
			self.db[dbkey] = value
		return locals()
	coin4 = db_property(**coin4())

	# 代币5 - 精灵魂石（碎片商店购买货币）
	def coin5():
		dbkey = 'coin5'
		def fset(self, value):
			self.db[dbkey] = value
		return locals()
	coin5 = db_property(**coin5())

	# 代币6 - Craft
	def coin6():
		dbkey = 'coin6'
		def fset(self, value):
			self.db[dbkey] = value
		return locals()
	coin6 = db_property(**coin6())

	# 代币7 - Craft
	def coin7():
		dbkey = 'coin7'
		def fset(self, value):
			self.db[dbkey] = value
		return locals()
	coin7 = db_property(**coin7())

	# 代币8 - Cross Craft
	def coin8():
		dbkey = 'coin8'
		def fset(self, value):
			self.db[dbkey] = value
		return locals()
	coin8 = db_property(**coin8())

	# 代币9 - Cross Craft
	def coin9():
		dbkey = 'coin9'
		def fset(self, value):
			self.db[dbkey] = value
		return locals()
	coin9 = db_property(**coin9())

	# 代币10 - UnionFight
	def coin10():
		dbkey = 'coin10'
		def fset(self, value):
			self.db[dbkey] = value
		return locals()
	coin10 = db_property(**coin10())

	# 代币11 - UnionFight
	def coin11():
		dbkey = 'coin11'
		def fset(self, value):
			self.db[dbkey] = value
		return locals()
	coin11 = db_property(**coin11())

	# 代币12 - Cross Arena
	def coin12():
		dbkey = 'coin12'
		def fset(self, value):
			self.db[dbkey] = value
		return locals()
	coin12 = db_property(**coin12())

	# 代币6 - Cross Mine
	def coin13():
		dbkey = 'coin13'
		def fset(self, value):
			if value < 0:
				logger.warning("role %s set coin13 %s warning", objectid2string(self.id), value)
				value = 0
			self.db[dbkey] = value
		return locals()
	coin13 = db_property(**coin13())

	# 代币14 - Hunting
	def coin14():
		dbkey = 'coin14'
		def fset(self, value):
			if value < 0:
				logger.warning("role %s set coin14 %s warning", objectid2string(self.id), value)
				value = 0
			self.db[dbkey] = value
		return locals()
	coin14 = db_property(**coin14())

	# 天赋点
	talent_point = db_property('talent_point')

	# 先手值
	def fightgo():
		dbkey = 'fightgo'
		def fset(self, value):
			if self.db[dbkey] != value:
				self.db[dbkey] = value
		return locals()
	fightgo = db_property(**fightgo())

	# 装备觉醒碎片数量
	equip_awake_frag = db_property('equip_awake_frag')

	# 当日 DailyRecord.id
	daily_record_db_id = db_property('daily_record_db_id')

	# 当日 MonthlyRecord.id
	monthly_record_db_id = db_property('monthly_record_db_id')

	# pvp竞技场数据 PVPRecord.id
	pvp_record_db_id = db_property('pvp_record_db_id')

	# 排位赛主动战斗排队中的数据 PVPPlayRecord.id
	pw_playing_db_id = db_property('pw_playing_db_id')

	# pvp竞技场商店数据 PVPShop.id
	pw_shop_db_id = db_property('pw_shop_db_id')

	# 竞技场商店 {csvid: [count, lastRecoverTime]}
	pvp_shop = db_property('pvp_shop')

	# 固定商店数据 FixShop.id
	fix_shop_db_id = db_property('fix_shop_db_id')

	# 王者商店 {csvid: [count, lastRecoverTime]}
	craft_shop = db_property('craft_shop')

	# 跨服王者商店 {csvid: [count, lastRecoverTime]}
	cross_craft_shop = db_property('cross_craft_shop')

	# 公会战商店 {csvid: [count, lastRecoverTime]}
	union_fight_shop = db_property('union_fight_shop')

	# 跨服竞技场商店 {csvid: [count, lastRecoverTime]}
	cross_arena_shop = db_property('cross_arena_shop')

	# 皮肤商店 {csvid: [count, lastRecoverTime]}
	card_skin_shop = db_property('card_skin_shop')

	# 主角当前体力值
	def stamina():
		dbkey = 'stamina'
		def fget(self):
			self.refreshStamina()
			return self.db[dbkey]
		def fset(self, value):
			'''
			+=: fget and fset
			= : fset
			'''
			old = self.db[dbkey]
			self.db[dbkey] = min(value, StaminaLimitMax)
			if 0 <= value < old:
				ObjectUnionContribTask.onCount(self.game, TargetDefs.CostStamina, old - value)
				ObjectYYHuoDongFactory.onGeneralTask(self.game, TargetDefs.CostStamina, old - value)
				self.game.mysteryShop.onStaminaConsume(self.game, old - value)
				self.game.capture.onStaminaConsume(old - value)
				self.game.dailyRecord.cost_stamina_sum += old - value
				ObjectYYHuoDongFactory.onHuoDongBoss(self.game, old - value)
			if value > old:
				self.game.achievement.onTargetTypeCount(AchievementDefs.StaminaCount)
		return locals()
	stamina = db_property(**stamina())

	# 自动体力恢复上限
	@property
	def staminaMax(self):
		staminaMax = csv.base_attribute.role_level[self.level].staminaMax
		staminaMax += self.game.privilege.staminaExtraMax + self.game.trainer.staminaMax
		return staminaMax

	# 自动恢复体力刷新
	def refreshStamina(self):
		nowTime = nowtime_t()
		stamina = int((nowTime - self.db['stamina_last_recover_time']) / StaminaRecoverTimerSecs)
		if stamina >= 1 and self.db['stamina'] < self.staminaMax:
			self.db['stamina'] = min(self.db['stamina'] + stamina, self.staminaMax)
		self.db['stamina_last_recover_time'] += stamina * StaminaRecoverTimerSecs


	# 溢出经验
	overflow_exp = db_property('overflow_exp')

	# 溢出经验兑换记录
	overflow_exp_exchanges = db_property('overflow_exp_exchanges')

	# 主角经验
	# 处理sum_exp和level_exp
	def exp():
		dbkey = 'sum_exp'
		def fset(self, value):
			if value == self.db[dbkey]:
				return
			# for gm, re-init level
			if value < self.db[dbkey]:
				self.db['level'] = 1
			if self.db['level_exp'] < 0:
				self.db['level'] = 1

			while self.level < self.LevelMax and ObjectRole.LevelSumExp[self.level] <= value:
				self.level += 1
				ta.track(self.game, event='level_up')
			if self.level == self.LevelMax:
				if ObjectFeatureUnlockCSV.isOpen(FeatureDefs.OverflowExpExchange, self.game):
					overflow_exp = value - ObjectRole.LevelSumExp[self.level - 1]
					if overflow_exp > 0:
						self.db['overflow_exp'] += overflow_exp
				self.db[dbkey] = min(value, ObjectRole.LevelSumExp[self.level - 1])
			else:
				self.db[dbkey] = value
			self.db['level_exp'] = self.db[dbkey] - ObjectRole.LevelSumExp[self.level - 1]
		return locals()
	exp = db_property(**exp())

	# 主角等级
	def level():
		dbkey = 'level'
		def fset(self, value):
			old = self.db[dbkey]
			value = min(value, self.LevelMax)
			level = old
			for level in xrange(old + 1, value + 1):
				cfg = csv.base_attribute.role_level[level]
				self.rmb += cfg.rmbGoldGive
				self.stamina += cfg.staminaGive

			if old != value:
				self.db[dbkey] = level
				# 地图刷新，OpenLevel
				self._initMap()
				self.game.talentTree.judgeActive()
				ObjectYYHuoDongFactory.onLevelUp(self.game)
				ObjectCraftInfoGlobal.onRoleInfo(self.game)
				ObjectUnionFightGlobal.onRoleInfo(self.game)
				self.onGrowGuideTask(TargetDefs.Level, 0)
				self.game.trainer.onLevelUp()
				self.game.achievement.onLevelUp()
				self.autoUpCardLevel(old)
		return locals()
	level = db_property(**level())

	def autoUpCardLevel(self, oldLevel):
		for card in self.game.cards.getCards(self.cards):
			if card.level == csv.base_attribute.role_level[oldLevel].cardLevelMax:
				card.autoUpLevel()
				card.autoOpenStarSkill()

	# 卡牌等级上限
	@property
	def cardLevelMax(self):
		return csv.base_attribute.role_level[self.level].cardLevelMax

	# 装备强化等级上限
	@property
	def equipAdvanceMax(self):
		return csv.base_attribute.role_level[self.level].equipAdvanceMax

	# 公会训练经验修正
	@property
	def unionTrainingFix(self):
		return csv.base_attribute.role_level[self.level].unionTrainingFix

	# 自动恢复技能点上限
	@property
	def skillPointMax(self):
		skillPointMax = csv.base_attribute.role_level[self.level].skillPointMax
		skillPointMax += self.game.privilege.skillPointExtraMax
		return skillPointMax

	# 当前玩家VIP等级
	def vip_level():
		dbkey = 'vip_level'
		def fset(self, value):
			value = min(value, globaldata.VIPLevelMax)
			if value != self.db[dbkey]:
				old = self.db[dbkey]
				self.db[dbkey] = value
				ObjectYYHuoDongFactory.onVIPLevelUp(self.game)
				ObjectYYHuoDongFactory.onVIPOrFightPointChanged(self.game)
				ObjectCraftInfoGlobal.onRoleInfo(self.game)
				ObjectUnionFightGlobal.onRoleInfo(self.game)
				if ObjectFeatureUnlockCSV.isOpen(FeatureDefs.DispatchTask, self.game):
					count = self.dispatchTaskCount - csv.vip[old + 1].dispatchTaskCount
					if count > 0:
						self.randomDispatchTask(count)
				ta.track(self.game, event='vip_level_up')
		return locals()
	vip_level = db_property(**vip_level())

	# 是否隐藏VIP
	vip_hide = db_property('vip_hide')

	@property
	def vip_level_display(self):
		return self.vip_level if not self.vip_hide else 0

	@property
	def _currVIPCsv(self):
		return csv.vip[self.vip_level + 1]

	@property
	def vipSum(self):
		return self._vip_sum

	@property
	def union_name(self):
		union = self.game.union
		if union is None:
			return ""
		return union.name

	@property
	def union_level(self):
		union = self.game.union
		if union is None:
			return 0
		return union.level

	@property
	def _nextVIPCsv(self):
		if self.vip_level == globaldata.VIPLevelMax:
			return None
		return csv.vip[self.vip_level + 2]

	@property
	def freePWTimes(self):
		return self._currVIPCsv.freePWTimes

	@property
	def buyStaminaMaxTimes(self):
		return self._currVIPCsv.buyStaminaTimes + self.game.trainer.staminaBuyTimes

	@property
	def buyPWMaxTimes(self):
		return self._currVIPCsv.buyPWTimes

	@property
	def buySkillPointMaxTimes(self):
		return self._currVIPCsv.buySkillPointTimes

	@property
	def buyHeroGateMaxTimes(self):
		return self._currVIPCsv.buyHeroGateTimes

	@property
	def multiSaoDangCountOpen(self):
		return self._currVIPCsv.saodangCountOpen

	@property
	def lianJinUpstart(self):
		upstart = self.game.privilege.lianJinUpstart
		if not upstart:
			return self._currVIPCsv.lianJinUpstart
		for k, v in self._currVIPCsv.lianJinUpstart.iteritems():
			upstart[k] = v + upstart.get(k, 0)
		return upstart

	@property
	def lianJinTimes(self):
		return self._currVIPCsv.lianJinTimes + self.game.trainer.lianjinBuyTimes

	@property
	def lianJinGift(self):
		return self._currVIPCsv.lianJinGift

	@property
	def mysteryRefresh(self):
		return self._currVIPCsv.mysteryRefresh

	@property
	def chatTimes(self):
		return self._currVIPCsv.chatTimes

	@property
	def bossTimeBuyLimit(self):
		return self._currVIPCsv.bossTimeBuyLimit

	@property
	def PWcoldTime(self):
		return self._currVIPCsv.PWcoldTime

	@property
	def PWpointActive(self):
		return self._currVIPCsv.PWpointActive

	@property
	def shopRefreshLimit(self):
		return self._currVIPCsv.shopRefreshLimit

	@property
	def fragShopRefreshLimit(self):
		return self._currVIPCsv.fragShopRefreshLimit + self.game.privilege.fragShopRefreshLimit

	@property
	def explorerShopRefreshLimit(self):
		return self._currVIPCsv.explorerShopRefreshLimit

	@property
	def fishingShopRefreshLimit(self):
		return self._currVIPCsv.fishingShopRefreshLimit

	@property
	def hammer2048(self):
		return self._currVIPCsv.hammer2048

	@property
	def freeTimes2048(self):
		return self._currVIPCsv.freeTimes2048

	@property
	def buyTimes2048(self):
		return self._currVIPCsv.buyTimes2048

	@property
	def freeTimesEatGreenBlock(self):
		return self._currVIPCsv.freeTimesEatGreenBlock

	@property
	def buyTimesEatGreenBlock(self):
		return self._currVIPCsv.buyTimesEatGreenBlock

	@property
	def freeTimesGoDown100(self):
		return self._currVIPCsv.freeTimesGoDown100

	@property
	def buyTimesGoDown100(self):
		return self._currVIPCsv.buyTimesGoDown100

	@property
	def cardbgBuyNum(self):
		return self._currVIPCsv.cardbgBuyNum

	@property
	def dispatchTaskQualityUpd(self):
		return self._currVIPCsv.dispatchTaskQualityUpd

	@property
	def dispatchTaskCount(self):
		return self._currVIPCsv.dispatchTaskCount

	@property
	def drawItemCountLimit(self):
		return self._currVIPCsv.drawItemCountLimit

	@property
	def goldDrawCardCountLimit(self):
		return self._currVIPCsv.goldDrawCardCountLimit

	@property
	def rmbDrawGemCountLimit(self):
		return self._currVIPCsv.rmbDrawGemCountLimit

	@property
	def goldDrawGemCountLimit(self):
		return self._currVIPCsv.goldDrawGemCountLimit

	@property
	def rmbDrawChipCountLimit(self):
		return self._currVIPCsv.rmbDrawChipCountLimit

	@property
	def itemDrawChipCountLimit(self):
		return self._currVIPCsv.itemDrawChipCountLimit

	@property
	def randomTowerPointRate(self):
		return self._currVIPCsv.randomTowerPointRate

	@property
	def roleChatTimes(self):
		return self._currVIPCsv.roleChatTimes

	@property
	def freeLianJinTimes(self):
		return self.game.privilege.lianJinFreeTimes + self.game.trainer.lianjinFreeTimes

	@property
	def crossArenaFreePWTimes(self):
		return self._currVIPCsv.crossArenaFreePWTimes

	@property
	def crossArenaBuyPWMaxTimes(self):
		return self._currVIPCsv.crossArenaBuyPWMaxTimes

	@property
	def megaItemMaxTimes(self):
		return self._currVIPCsv.megaItemMaxTimes

	@property
	def fragExchangeTimes(self):
		return self._currVIPCsv.fragExchangeTimes

	@property
	def heldItemExchangeTimes(self):
		return self._currVIPCsv.heldItemExchangeTimes

	@property
	def crossMineRobBuyLimit(self):
		return self._currVIPCsv.crossMineRobBuyLimit

	@property
	def crossMineRevengeBuyLimit(self):
		return self._currVIPCsv.crossMineRevengeBuyLimit

	@property
	def megaCommonItemMaxTimes(self):
		return self._currVIPCsv.megaCommonItemMaxTimes

	# 开放的世界地图列表
	world_open = db_property('world_open')

	# 开放的章节地图列表
	map_open = db_property('map_open')

	# 开放的关卡列表
	gate_open = db_property('gate_open')

	# 关卡星级字典 {gate_id:{star:0,chest:关卡宝箱 -1表示未达成 1表示可领取 0表示已领取,win_award:关卡通关,star3_award:关卡三星}}
	gate_star = db_property('gate_star')

	@property
	def gateStarSum(self):
		return self._gate_star_sum

	def getGateStar(self, gateID):
		return self.gate_star.get(gateID, {}).get('star', 0)

	@property
	def currentGateID(self):
		return max([gateID for gateID in self.gate_open if gateID in csv.scene_conf and csv.scene_conf[gateID].sceneType == MapDefs.TypeGate])

	def addGateStar(self, gateID, star):
		cfg = csv.scene_conf[gateID]
		old = self.gate_star.get(gateID, {})
		star = max(star, old.get('star', 0))
		if star > 0:
			if cfg.chestAward:
				old['chest'] = old.get('chest', 1)
			if cfg.winAward:
				old['win_award'] = old.get('win_award', 1)
			if star >= 3 and cfg.star3Award:
				old['star3_award'] = old.get('star3_award', 1)
		old['star'] = star
		new = {gateID: old}
		self.gate_star.update(new)

		oldSum = self._gate_star_sum

		# TODO: optimize
		self._initMap()

		if oldSum != 0 and oldSum != self._gate_star_sum:
			self._chat_times_correction = 0
			ObjectYYHuoDongFactory.onGateStarChange(self.game)

		# 是否普通关卡
		mapObj = ObjectMap.findObj(MapDefs.TypeGate, gateID)
		if mapObj:
			self.initMapStarAward(mapObj.parent.id)

	def resetHeroGate(self, gateID):
		# findObj索引不管普通还是精英，都使用TypeGate类型
		# 只是mapObj保存的type是TypeHeroGate
		mapObj = ObjectMap.findObj(MapDefs.TypeGate, gateID)
		if mapObj is None:
			raise ClientError('gateID error')
		if mapObj.type != MapDefs.TypeHeroGate:
			raise ClientError('gateID is not hero gate')

		self.game.dailyRecord.gate_times.update({
			gateID: 0,
		})

	def canStartGate(self, gateID, gateType=MapDefs.TypeGate):
		if gateID not in self.gate_open:
			return False

		mapObj = ObjectMap.findObj(gateType, gateID)
		if mapObj is None:
			return False

		if mapObj.openLevel > self.level:
			return False

		star = self.gate_star.get(gateID, None)
		if not star:
			return True
		todayTimes = self.game.dailyRecord.gate_times.get(gateID, 0)
		addTimes = 0
		# 运营活动 精英关卡次数
		if mapObj.type == MapDefs.TypeHeroGate:
			buyTimes = self.game.dailyRecord.buy_herogate_times.get(gateID, 0)
			if buyTimes == 0:
				yyID = ObjectYYHuoDongFactory.getDoubleDropOpenID(YYHuoDongDefs.DoubleEliteCount)
				if yyID:
					addTimes = csv.yunying.yyhuodong[yyID].paramMap['count']
		if todayTimes >= csv.scene_conf[gateID].dayChallengeMax + addTimes:
			return False
		return True

	def recordGateBattle(self, gateID, gateType=MapDefs.TypeGate, times=1):
		mapObj = ObjectMap.findObj(gateType, gateID)
		if mapObj is None:
			return

		# record
		if mapObj.type == MapDefs.TypeGate:
			self.game.dailyRecord.gate_chanllenge += times
		elif mapObj.type == MapDefs.TypeHeroGate:
			self.game.dailyRecord.hero_gate_chanllenge += times
		elif mapObj.type == MapDefs.TypeNightmareGate:
			self.game.dailyRecord.nightmare_gate_chanllenge += times

		self.game.dailyRecord.gate_times.update({
			gateID: self.game.dailyRecord.gate_times.get(gateID, 0) + times,
		})

	# 章节星级
	map_star = db_property('map_star')

	def initMapStarAward(self, mapID):
		if mapID not in self.map_open:
			return

		gateIDs = ObjectMap.getGateSeqByMap(mapID)
		gateStars = [self.gate_star.get(gateID, {}).get('star', 0) for gateID in gateIDs]
		sumStar = sum(gateStars)

		old = self.map_star.get(mapID, {})
		award = copy.deepcopy(old.get('star_award', MapDefs.starAwardDefault))
		starAwardConds = csv.world_map[mapID].starAwardConds
		for i in xrange(len(award)):
			if award[i] == MapDefs.starAwardCloseFlag:
				continue
			award[i] = MapDefs.starAwardNoneFlag
			if starAwardConds[i] > 0 and sumStar >= starAwardConds[i]:
				award[i] = MapDefs.starAwardOpenFlag
		new = {mapID: {
			'star_award': award,
		}}
		self.map_star.update(new)

	def takeMapStarAward(self, mapID, awardLevel):
		if mapID not in self.map_open:
			return

		old = self.map_star.get(mapID, {})
		award = copy.deepcopy(old.get('star_award', MapDefs.starAwardDefault))
		if award[awardLevel] != MapDefs.starAwardOpenFlag:
			return

		starAwardIDs = csv.world_map[mapID].starAwardIDs
		award[awardLevel] = MapDefs.starAwardCloseFlag
		new = {mapID: {
			'star_award': award,
		}}
		self.map_star.update(new)
		return starAwardIDs[awardLevel]

	# 卡牌RoleCard.id列表
	cards = db_property('cards')

	# 玩家道具字典 {item_id:count}
	items = db_property('items')

	def sellItems(self, itemsD):
		for itemID, itemCount in itemsD.iteritems():
			if itemID not in csv.items:
				raise ClientError('itemID error')
			price = csv.items[itemID].sellPrice
			if price == 0:
				raise ClientError('itemID can not be sell')
			if itemCount <= 0 or itemCount > self.items.get(itemID, 0):
				raise ClientError('itemCount error')

		gold = 0
		for itemID, itemCount in itemsD.iteritems():
			price = csv.items[itemID].sellPrice
			gold += price * itemCount
		cost = ObjectCostAux(self.game, itemsD)
		eff = ObjectGainAux(self.game, {'gold': gold})
		return eff, cost

	# 玩家碎片字典 {frag_id:count}
	frags = db_property('frags')
	zfrags = db_property('zfrags')

	def sellFrags(self, fragsD):
		for fragID, fragCount in fragsD.iteritems():
			if fragID not in csv.fragments:
				raise ClientError('fragID error')
			price = csv.fragments[fragID].sellPrice
			if price == 0:
				raise ClientError('fragID can not be sell')
			if fragCount <= 0 or fragCount > self.frags[fragID]:
				raise ClientError('fragCount error')

		gold = 0
		for fragID, fragCount in fragsD.iteritems():
			price = csv.fragments[fragID].sellPrice
			gold += price * itemCount
		cost = ObjectCostAux(self.game, fragsD)
		eff = ObjectGainAux(self.game, {'gold': gold})
		return eff, cost

	# 玩家携带道具列表 [RoleHeldItem.id]
	held_items = db_property('held_items')

	# 玩家稳定掉落概率权值字典 {stable_drop_id:weight}
	stable_drop_weights = db_property('stable_drop_weights')

	# 出战部署卡牌RoleCard.id列表
	def battle_cards():
		dbkey = 'battle_cards'
		def fset(self, value):
			if len(value) != 6:
				raise ServerError('battle_cards length error %d' % len(value))
			if self.db[dbkey] != value:
				self.db[dbkey] = value
		return locals()
	battle_cards = db_property(**battle_cards())

	def deployBattleCards(self, cards):
		cards = transform2list(cards)
		if len(cards) != 6:
			raise ClientError(ErrDefs.battleCardCountLimit)
		if self.game.cards.isDuplicateMarkID(cards):
			raise ClientError(ErrDefs.battleCardMarkIDError)
		self.battle_cards = cards
		for cardID in self.battle_cards:
			if cardID:
				card = self.game.cards.getCard(cardID)
				card.display()
		self.game.cards.onFightingPointChange()

	# 活动关卡出战部署卡牌RoleCard.id列表
	def huodong_cards():
		dbkey = 'huodong_cards'
		def fset(self, value):
			if self.db[dbkey] != value:
				self.db[dbkey] = value
		return locals()
	huodong_cards = db_property(**huodong_cards())

	def deployHuodongCards(self, huodongID, cards):
		cards = transform2list(cards)
		if len(cards) != 6:
			raise ClientError(ErrDefs.battleCardCountLimit)
		if self.game.cards.isDuplicateMarkID(cards):
			raise ClientError(ErrDefs.battleCardMarkIDError)
		if len(filter(None, cards)) == 0 and huodongID != RandomTowerHuodongID:
			raise ClientError('cards type error')
		if huodongID == RandomTowerHuodongID:
			# 里面不能有死的卡牌
			if self.game.randomTower.hasDeadCard(cards):
				raise ClientError('random_tower card has dead')
		if huodongID == EndlessTowerHuodongID:
			# 是否满足布阵规则
			from game.object.game import ObjectEndlessTowerGlobal
			if not ObjectEndlessTowerGlobal.isRightCards(self.game.cards.getCards(cards), self.endless_tower_current):
				raise ClientError('endlessTower has error card')
		self.huodong_cards[huodongID] = cards

	def filterHuodongCards(self, cards):
		cards = set(cards)
		for huodongID, v in self.huodong_cards.iteritems():
			valids = []
			hit = False
			for vv in v:
				if vv in cards:
					valids.append(None)
					hit = True
				else:
					valids.append(vv)
			if hit:
				self.huodong_cards[huodongID] = valids

	# 阵容同步 {key: flag}
	deployments_sync = db_property('deployments_sync')

	# 日常任务字典{date:{task_id:{arg:0, flag:0}}}
	daily_task = db_property('daily_task')

	# 主线任务字典{task_id:{arg:0, flag:0}}
	main_task = db_property('main_task')

	def takeTaskAward(self, taskID):
		task = self.game.tasks.getNoClosedTask(taskID)
		if task is None:
			raise ClientError(ErrDefs.taskClosed)
		status = task.getStatus()
		if status == TaskDefs.taskOpenFlag:
			return task.getEffect()
		elif status == TaskDefs.taskNoneFlag:
			raise ClientError(ErrDefs.taskUnFinished)
		raise ClientError(ErrDefs.taskClosed)

	def takeLivenessStageAward(self, csvID):
		status = self.game.dailyRecord.liveness_stage_award.get(csvID, TaskDefs.taskNoneFlag)
		if status == TaskDefs.taskNoneFlag:
			raise ClientError(ErrDefs.livenessStageAwardLimit)
		elif status == TaskDefs.taskCloseFlag:
			raise ClientError(ErrDefs.livenessStageAwardAreadyHas)
		return self.game.tasks.getLivenessStageEffect(csvID)

	# 抽奖数据 LotteryRecord.id
	lottery_db_id = db_property('lottery_db_id')

	# 社交数据 Society.id
	society_db_id = db_property('society_db_id')

	# 购买的充值字典{csv_id:{cnt:0, date:20141206, orders:[PayOrder.id]}}
	recharges = db_property('recharges')

	# 离线充值缓存 [(rechargeID, orderID)]
	recharges_cache = db_property('recharges_cache')

	@classmethod
	def isRechargeOK(cls, recharges, rechargeID, orderID):
		recharge = recharges.get(rechargeID, {})
		orders = recharge.get('orders', [])
		if orderID != TestOrderID and orderID in orders:
			return False
		if rechargeID not in csv.recharges:
			return False
		return True

	def buyRecharge(self, rechargeID, orderID, yyID=0, csvID=0, **kwargs):
		'''
		充值
		'''
		recharge = self.recharges.setdefault(rechargeID, {})
		orders = recharge.setdefault('orders', [])
		# 忽略重复充值
		# TestOrderID 是测试用（或者月卡自动获得）
		# QQOrderID 是QQ防错补齐的
		if orderID not in (TestOrderID, QQOrderID) and orderID in orders:
			logger.warning('role %s order %s repeat recharged', objectid2string(self.id), objectid2string(orderID))
			return False
		if rechargeID not in csv.recharges:
			logger.warning('csv.recharges %d not existed', rechargeID)
			return False

		cfg = csv.recharges[rechargeID]
		# 是否有首冲重置活动
		# 0 表示 没重置过，也没活动ID
		# >0 表示 新的重置活动ID
		# <0 表示 重置过的活动ID
		reset = recharge.get('reset', 0)
		cnt = recharge.get('cnt', 0)
		if cnt == 0 or reset > 0:
			rmb = cfg.rmb + cfg.firstPresent
		else:
			rmb = cfg.rmb + cfg.present
		rePro = kwargs.get('rePro', 0)
		if rePro > 0: # lunplay h5充值返利
			from math import ceil
			rmb += int(ceil(cfg.rmb * (rePro * 1.0 / 100)))

		def done():
			recharge['reset'] = -abs(reset)
			recharge['cnt'] = cnt + 1
			if orderID != TestOrderID:
				orders.append(orderID)

		increase_number = rmb
		future = None
		if cfg.type == RechargeDefs.OneOffType:
			done()
			self.rmb += rmb
			logger.info('role %d %s gain from recharge, %s', self.uid, self.pid, {'rmb': rmb})
		elif cfg.type == RechargeDefs.DaysType:
			increase_number = cfg.rmb
			self.rmb += cfg.rmb
			logger.info('role %d %s gain from recharge_month, %s', self.uid, self.pid, {'rmb': cfg.rmb})
			ret, future = ObjectYYHuoDongFactory.buyRecharge(self.game, rechargeID, yyID, csvID, days=cfg.param['days'])
			if not ret:
				return False
			done()
		elif cfg.type == RechargeDefs.GiftType:
			ret, future = ObjectYYHuoDongFactory.buyRecharge(self.game, rechargeID, yyID, csvID)
			if not ret:
				return False
			done()
		channel = kwargs.get('channel', None)
		if orderID == TestOrderID:
			channel = 'test_order'
		ta.track(self.game, event='order_pay', recharge_id=rechargeID,yy_id=yyID,csv_id=csvID,increase_number=increase_number,channel=channel)

		self._initVIPLevel()
		self.game.dailyRecord.recharge_rmb_sum += cfg.rmb
		if cfg.validRechargeHuodong:
			ObjectYYHuoDongFactory.onRecharge(self.game, cfg.rmb, rechargeID)

		if kwargs.get('push', False):
			# 主动推送给客户端
			if future:
				future.add_done_callback(lambda fu: self.pushBuyRecharge(rechargeID, yyID, csvID, fu.result()))
			else:
				self.pushBuyRecharge(rechargeID, yyID, csvID)

		return True

	def pushBuyRecharge(self, rechargeID, yyID, csvID, result=None):
		data = {
			'ret': True,
			'buy_recharge': [rechargeID, yyID, csvID, result],
		}
		from game.session import Session
		session = Session.getSession(self.accountKey)
		session.sendTaskToClient("/game/push", data)

	def setVIPLevel(self, vipLevel):
		if self.vip_level >= vipLevel:
			return
		upSum = csv.vip[vipLevel + 1].upSum
		leftSum = upSum - self._vip_sum
		recharge = self.recharges.setdefault(FreeVIPRechargeID, {})
		recharge['cnt'] = recharge.get('cnt', 0) + leftSum
		self._initVIPLevel()

	def addVIPExp(self, vipExp):
		recharge = self.recharges.setdefault(FreeVIPRechargeID, {})
		recharge['cnt'] = recharge.get('cnt', 0) + vipExp

		self._initVIPLevel()

	def getRechargeDateLeft(self, rechargeID):
		if rechargeID not in csv.recharges:
			return 0
		if rechargeID not in self.recharges:
			return 0
		cfg = csv.recharges[rechargeID]
		if cfg.type != RechargeDefs.daysType:
			return 0
		if self.recharges[rechargeID].get('cnt', 0) == 0:
			return 0
		date = self.recharges[rechargeID].get('date', 0)
		if date == 0:
			return 0

		date = int2date(date)
		return max(0, (date - inclock5date(nowdatetime_t())).days)

	# 已领取礼包字典 {gift_type: 0}
	gifts = db_property('gifts')

	# 邮件缩略数据 [{db_id:Mail.id, subject:Mail.subject, time:Mail.time, type=Mail.type, sender:Mail.sender, global:Mail.role_db_id==0}, ...]
	mailbox = db_property('mailbox')

	# 已读邮件数据 [Mail, ...]
	read_mailbox = db_property('read_mailbox')

	@property
	def stashCardMailCount(self):
		count = 0
		for v in self.mailbox:
			if v['type'] == StashCardMailID:
				count += 1
		return count

	def canAddMail(self, time):
		if len(self.mailbox) < MailBoxMax:
			return True
		oldTime = self.mailbox[0]['time']
		if time > oldTime:
			return True
		return False

	def getMailIDs(self):
		return [m['db_id'] for m in self.mailbox]

	def addMailThumb(self, mailID, subject, time, mailType, sender='', gglobal=False, hasattach=True):
		leng = len(self.mailbox)
		pos = 0
		if leng > 0:
			for idx in xrange(leng - 1, -1, -1):
				oldTime = self.mailbox[idx]['time']
				if time > oldTime:
					pos = idx + 1
					break

		self.mailbox.insert(pos, {
			'db_id': mailID,
			'subject': subject,
			'time': time,
			'type': mailType,
			'sender': sender,
			'global': gglobal,
			'hasattach': hasattach,
		})

		# 先加后删
		if leng > MailBoxMax:
			newMailbox = []
			remove = leng + 1 - MailBoxMax  # 需要删掉的数量
			for mailInfo in self.mailbox:
				if csv.mail[mailInfo['type']].special or remove == 0:
					newMailbox.append(copy.deepcopy(mailInfo))
				else:
					remove = remove - 1
					logger.warning('online role %s mail overflow, %d %s %s', self.pid, mailInfo['type'], objectid2string(mailInfo['db_id']), mailInfo['subject'])
			self.mailbox = newMailbox

		self.game.achievement.onTargetTypeCount(AchievementDefs.MailCount)

	@classmethod
	def addMailThumbInMem(cls, mem, mailModel, roleID):
		time = mailModel['time']
		leng = len(mem)
		pos = 0
		if leng > 0:
			for idx in xrange(leng - 1, -1, -1):
				oldTime = mem[idx]['time']
				if time > oldTime:
					pos = idx + 1
					break

		mem.insert(pos, {
			'db_id': mailModel['id'],
			'subject': mailModel['subject'],
			'time': time,
			'type': mailModel['type'],
			'sender': mailModel['sender'],
			'global': mailModel['role_db_id'] == GlobalMailRoleID, # 全局邮件
			'hasattach': mailModel['attachs'] and True or False,
		})

		# 先加后删
		if leng >= MailBoxMax:
			newMem = []
			remove = leng + 1 - MailBoxMax  # 需要删掉的数量
			for mailInfo in mem:
				if csv.mail[mailInfo['type']].special or remove == 0:
					newMem.append(copy.deepcopy(mailInfo))
				else:
					remove = remove - 1
					logger.warning('offline role %s mail overflow, %d %s %s', objectid2string(roleID), mailInfo['type'], objectid2string(mailInfo['db_id']), mailInfo['subject'])
			mem = newMem

		return mem

	def delMail(self, mailID):
		model = self._mail.pop(mailID, None)
		for i in xrange(len(self.mailbox)):
			mail = self.mailbox[i]
			if mail['db_id'] == mailID:
				del self.mailbox[i]
				break
		if model:
			# 邮件已读后存入已读邮件处
			self.read_mailbox.append(model)
			leng = len(self.read_mailbox)
			if leng > ReadMailBoxMax:
				remove = leng + 1 - ReadMailBoxMax
				# 删去之前的
				del self.read_mailbox[:remove]

	def setMailModel(self, mailID, model):
		self._mail[mailID] = model

	def getMailModel(self, mailID):
		return self._mail.get(mailID, None)

	def isGlobalMail(self, mailID):
		mail = self._mail.get(mailID, None)
		if mail:
			return mail.get('role_db_id', None) == GlobalMailRoleID
		return False

	def isReadMail(self, mailID):
		for mail in self.read_mailbox:
			if mail['id'] == mailID:
				return True
		return False

	def getReadMailModel(self, mailID):
		for mail in self.read_mailbox:
			if mail['id'] == mailID:
				return mail
		return None

	@classmethod
	def makeMailModel(cls, toRoleID, mailType, sender=None, subject=None, content=None, attachs=None, sendTime=None, contentArgs=None):
		cfg = csv.mail[mailType]
		sender = sender if sender else getL10nCsvValue(cfg, 'sender')
		subject = subject if subject else getL10nCsvValue(cfg, 'subject')
		content = content if content else getL10nCsvValue(cfg, 'content')
		try:
			if contentArgs:
				content = content % contentArgs
		except:
			logger.exception('make mail content error')
		attachs = attachs if attachs else cfg.attachs
		sendTime = sendTime if sendTime else nowtime_t()
		return {
			'role_db_id': toRoleID,
			'time': sendTime,
			'type': mailType,
			'sender': sender,
			'subject': subject,
			'content': content,
			'attachs': attachs,
		}

	def makeMyMailModel(self, mailType, sender=None, subject=None, content=None, attachs=None, sendTime=None, contentArgs=None):
		return self.makeMailModel(self.id, mailType, sender, subject, content, attachs, sendTime, contentArgs)

	def isMailExisted(self, mailID):
		if mailID in self._mail:
			return True
		for i in xrange(len(self.mailbox)):
			mail = self.mailbox[i]
			if mail['db_id'] == mailID:
				return True
		return False

	# 活动字典{date:{huodong_id:0, ...}}
	huodongs = db_property('huodongs')

	# yyhuodong在各自class完成active和getEffect
	# huodong因为历史问题，一般没有复杂判定逻辑，所以直接在这里判定
	def addHuoDong(self, id, times=1):
		# 无论是否开启都进行add，可能存在临界时间
		obj = ObjectHuoDongFactory.getConfig(id)
		if obj is None:
			return

		dt = obj.getPeriodDateInt()
		idsD = self.huodongs.setdefault(dt, {})
		hdD = idsD.setdefault(id, {})
		hdD['times'] = times + hdD.get('times', 0)
		hdD['last_time'] = nowtime_t()

		self.game.dailyRecord.huodong_chanllenge += times

	def canStartHuoDong(self, id, gateID, times=1):
		obj = ObjectHuoDongFactory.getOpenConfig(id)
		if obj is None:
			raise ClientError(ErrDefs.huodongNoOpen)
		if obj.openLevel > self.level:
			raise ClientError(ErrDefs.huodongLevelNotEnough)

		if csv.scene_conf[gateID].openLevel > self.level:
			raise ClientError(ErrDefs.huodongLevelNotEnough)

		dt = obj.getPeriodDateInt()
		yet = self.huodongs.get(dt, {}).get(id, {}).get('times', 0)
		# 运营活动 增加活动次数
		yyID = None
		addTimes = 0
		if csv.huodong[id].huodongType == HuoDongDefs.TypeGold:
			addTimes += self.game.trainer.huodongTypeGoldTimes
			addTimes += self.game.privilege.huodongGoldTimes
			yyID = ObjectYYHuoDongFactory.getDoubleDropOpenID(YYHuoDongDefs.DoubleCountGold)
		elif csv.huodong[id].huodongType == HuoDongDefs.TypeExp:
			addTimes += self.game.trainer.huodongTypeExpTimes
			addTimes += self.game.privilege.huodongExpTimes
			yyID = ObjectYYHuoDongFactory.getDoubleDropOpenID(YYHuoDongDefs.DoubleCountExp)
		elif csv.huodong[id].huodongType == HuoDongDefs.TypeGift:
			addTimes += self.game.trainer.huodongTypeGiftTimes
			addTimes += self.game.privilege.huodongGiftTimes
			yyID = ObjectYYHuoDongFactory.getDoubleDropOpenID(YYHuoDongDefs.DoubleCountGift)
		elif csv.huodong[id].huodongType == HuoDongDefs.TypeFrag:
			addTimes += self.game.trainer.huodongTypeFragTimes
			addTimes += self.game.privilege.huodongFragTimes
			yyID = ObjectYYHuoDongFactory.getDoubleDropOpenID(YYHuoDongDefs.DoubleCountFrag)

		if yyID:
			addTimes += csv.yunying.yyhuodong[yyID].paramMap['count']

		# 重聚活动 进度赶超
		reunionTimes = 0
		if csv.huodong[id].huodongType in [HuoDongDefs.TypeGold, HuoDongDefs.TypeExp, HuoDongDefs.TypeGift, HuoDongDefs.TypeFrag]:
			cfg = ObjectYYHuoDongFactory.getReunionCatchUpCfg(self, ReunionDefs.HuodongCount)
			if self.canReunionCatchUp(cfg):
				reunionTimes = cfg.params['count']

		if yet + times > obj.times + addTimes + reunionTimes:
			raise ClientError(ErrDefs.huodongChanllengeToMuch)
		return True

	def getHuoDongOpens(self):
		'''
		只判断开放时间和等级，其余判定交给各自逻辑
		'''
		opensD = ObjectHuoDongFactory.getOpenMap()
		ret = {}
		for id, flag in opensD.iteritems():
			obj = ObjectHuoDongFactory.getOpenConfig(id)
			if obj is None:
				continue
			if obj.openLevel > self.level:
				ret[id] = 2 if flag == 1 else 0 # 2 opening when level ok
				continue
			ret[id] = flag
		return ret

	# 活动通关字典 {huodong_id:{gateID:star}}
	huodongs_gate = db_property('huodongs_gate')

	def _initHuoDongIndex(self):
		for huoDongID in self.huodongs_gate:
			gateD = self.huodongs_gate[huoDongID]
			for gateID in gateD:
				self.setHuoDongGateIndex(gateD[gateID], huoDongID, gateID)

	def setHuoDongGateIndex(self, star, id, gateID):
		if star == 3 and self.HuoDongGateIndexMap[id][gateID] > self.huodongsIndex.get(id, -1):
			tmp = dict(self.huodongsIndex)
			tmp[id] = self.HuoDongGateIndexMap[id][gateID]
			self.huodongsIndex = tmp

			achievementType = 0
			if id == HuoDongDefs.TypeGold:
				achievementType = AchievementDefs.GoldHuodongPassType
			elif id == HuoDongDefs.TypeExp:
				achievementType = AchievementDefs.ExpHuodongPassType
			elif id == HuoDongDefs.TypeGift:
				achievementType = AchievementDefs.GiftHuodongPassType
			elif id == HuoDongDefs.TypeFrag:
				achievementType = AchievementDefs.FragHuodongPassType
			if achievementType:
				self.game.achievement.onTargetTypeCount(achievementType)

	def addHuoDongPassedGate(self, id, gateID, star):
		gateD = self.huodongs_gate.setdefault(id, {})
		old = gateD.get(gateID, 0)
		gateD[gateID] = max(old, star)
		self.setHuoDongGateIndex(gateD[gateID], id, gateID)

	def getHuoDongGateStar(self, id, gateID):
		gateD = self.huodongs_gate.get(id, {})
		star = gateD.get(gateID,0)

		if self.HuoDongGateIndexMap[id][gateID] <= self.huodongsIndex.get(id, -1):
			star = 3

		return star

	def getHuoDongGateIndex(self, id):
		return self.huodongsIndex.get(id, -1)

	def activeSignInGift(self):
		'''
		总累计签到奖励激活
		'''
		sign_idx,sign_flag = self.sign_in_gift[0],self.sign_in_gift[1]
		if sign_idx in csv.sighingift and sign_flag == -1:
			cfg = csv.sighingift[sign_idx]
			if self.sign_in_count >= cfg.day:
				self.sign_in_gift[1] = 1

	def todaySignIn(self):
		now = nowdate_t()

		if self.game.monthlyRecord.last_sign_in_day < now.day:
			# 新签到奖励
			self.game.monthlyRecord.last_sign_in_day = now.day
			self.game.monthlyRecord.sign_in += 1
			self.game.role.sign_in_count += 1

			# 连续签到
			if self.last_sign_in_date:
				days = (now - int2date(self.last_sign_in_date)).days
				if days == 1:
					self.last_sign_in_date = date2int(now)
					self.sign_in_days += 1
				elif days > 1:
					self.last_sign_in_date = date2int(now)
					self.sign_in_days = 1
			else:
				self.last_sign_in_date = date2int(now)
				self.sign_in_days = 1

			# 总累计签到奖励激活
			self.activeSignInGift()
			# 月累计签到奖励激活
			self.game.monthlyRecord.activeSignInGift()

			idx = self.game.monthlyRecord.sign_in
			self.game.monthlyRecord.last_sign_in_idx = idx
			return self.signin(idx, now.month, now.day)

		elif self.game.monthlyRecord.last_sign_in_day == now.day:
			# 剩余签到奖励
			idx = self.game.monthlyRecord.last_sign_in_idx
			return self.signin(idx, now.month, now.day)

		return None

	def signInBuy(self, csvid):
		now = nowdate_t()
		monthlyRecord = self.game.monthlyRecord
		monthField = 'month%d' % now.month

		if not csvid:
			# 新的补签
			# 当月签到限制
			if monthlyRecord.last_sign_in_day < now.day:
				if monthlyRecord.sign_in + 1 >= now.day: # 今日未签到
					raise ClientError('sign in day limit')
			else:
				if monthlyRecord.sign_in >= now.day: # 今日已签到
					raise ClientError('sign in day limit')

			# 累计签到限制，达到创号日期数限定
			days = (now - datetimefromtimestamp(self.created_time).date()).days + 1
			if monthlyRecord.last_sign_in_day < now.day:
				if self.sign_in_count + 1 >= days:
					raise ClientError('sign in day limit')
			else:
				if self.sign_in_count >= days:
					raise ClientError('sign in day limit')

			rmb = ObjectCostCSV.getSignInBuyCost(monthlyRecord.sign_in_buy_times)
			if rmb > 0:
				cost = ObjectCostAux(self.game, {'rmb': rmb})
				if not cost.isEnough():
					raise ClientError('not enough')
				cost.cost(src='sign_in_buy')
			monthlyRecord.sign_in_buy_times += 1
			monthlyRecord.sign_in += 1
			self.sign_in_count += 1

			# 总累计签到奖励激活
			self.activeSignInGift()
			# 月累计签到奖励激活
			monthlyRecord.activeSignInGift()

			idx = self.game.monthlyRecord.sign_in
			return self.signin(idx, now.month, now.day)

		else:
			# 剩余补签奖励
			if now.day not in monthlyRecord.sign_in_awards:
				return None
			if csvid not in monthlyRecord.sign_in_awards[now.day]:
				return None
			return self.signin(csvid, now.month, now.day)

		return None

	def signin(self, idx, month, day):
		if idx not in csv.signin:
			return None

		multiple = 1
		old = self.game.monthlyRecord.sign_in_awards.get(day, {}).get(idx, 0)
		if old == 0:
			# 新签到或补签
			cfg = csv.signin[idx]
			if cfg.vipDouble <= self.vip_level:
				multiple = 2
		elif old == 1:
			cfg = csv.signin[idx]
			if cfg.vipDouble > self.vip_level:
				return None
		elif old == 2:
			return None

		return ObjectSignInAwardEffect(self.game, idx, day, cfg['month%d' % month], multiple)

	def lianjin(self, times, total):
		# 暴击计算
		multiple, _ = WeightRandomObject.onceRandom(self.lianJinUpstart)

		# 炼金修正
		rate = ObjectCostCSV.getLianJinGoldRate(times)

		onelianJinGold = csv.base_attribute.role_level[self.level].lianJinGold * rate
		lianJinGold = onelianJinGold * multiple
		lianJinGold += onelianJinGold * self.game.privilege.lianJinRate
		lianJinGold += onelianJinGold * self.game.trainer.lianjinDropRate

		# 运营活动 双倍
		addGold = 0
		yyID = ObjectYYHuoDongFactory.getDoubleDropOpenID(YYHuoDongDefs.DoubleLianjin)
		if yyID:
			count = csv.yunying.yyhuodong[yyID].paramMap['count']
			if total < count:
				addGold = onelianJinGold

		# 进度赶超 双倍 (不和运营活动叠加)
		catchupCfg = ObjectYYHuoDongFactory.getReunionCatchUpCfg(self.game.role, ReunionDefs.DoubleLianjin)
		if self.game.role.canReunionCatchUp(catchupCfg) and total < catchupCfg.params['count']:
			addGold = onelianJinGold
			self.game.role.addReunionCatchUpRecord(catchupCfg.id)

		lianJinGold += addGold
		lianJinGold = int(lianJinGold)
		return multiple, lianJinGold

	# 新手指引阶段 0 没开始，>0 阶段ID
	newbie_guide = db_property('newbie_guide')

	# 新手指引选卡记录 csv id
	newbie_card_choice = db_property('newbie_card_choice')

	# 客户端事件标记，服务器不使用
	client_flag = db_property('client_flag')

	def canSaoDang(self, gateID, times):
		gateInfo = self.gate_star.get(gateID, None)
		if gateInfo is None or gateInfo.get('star', 0) < 3:
			raise ClientError(ErrDefs.saodangGateNoStar)

		mapObj = ObjectMap.findObj(MapDefs.TypeGate, gateID)
		if mapObj is None:
			return

		todayTimes = self.game.dailyRecord.gate_times.get(gateID, 0)
		addTimes = 0
		# 运营活动 精英关卡次数
		if mapObj.type == MapDefs.TypeHeroGate:
			buyTimes = self.game.dailyRecord.buy_herogate_times.get(gateID, 0)
			if buyTimes == 0:
				yyID = ObjectYYHuoDongFactory.getDoubleDropOpenID(YYHuoDongDefs.DoubleEliteCount)
				if yyID:
					addTimes = csv.yunying.yyhuodong[yyID].paramMap['count']
		if todayTimes + times > csv.scene_conf[gateID].dayChallengeMax + addTimes:
			return False
		return True

	# 运营活动字典 各活动异构 -1表示未达成 1表示可领取 0表示已领取
	yyhuodongs = db_property('yyhuodongs')

	# 卡牌获得总次数
	card_gain_times = db_property('card_gain_times')

	# 卡牌进阶总次数
	card_advance_times = db_property('card_advance_times')

	# 卡牌升星总次数
	card_star_times = db_property('card_star_times')

	# 收取全局邮件的游标
	global_mail_idx = db_property('global_mail_idx')

	# level rank排名
	cardNum_rank = db_property('cardNum_rank')

	# fight rank排名
	fight_rank = db_property('fight_rank')

	# gate star排名
	gate_star_rank = db_property('gate_star_rank')

	# 单张卡牌战斗力排名
	card1fight_rank = db_property('card1fight_rank')

	# endless rank排名
	endless_rank = db_property('endless_rank')

	# 竞技场排名（缓存）
	def pw_rank():
		dbkey = 'pw_rank'
		def fset(self, value):
			self.db[dbkey] = value
			ObjectYYHuoDongFactory.onGeneralTask(self.game, TargetDefs.ArenaRank, 0)
		return locals()
	pw_rank = db_property(**pw_rank())

	# 上阵卡牌战斗力
	battle_fighting_point = db_property('battle_fighting_point')

	# 历史最高前6卡牌战斗力
	top6_fighting_point = db_property('top6_fighting_point')

	# 历史最高前12卡牌战斗力
	top12_fighting_point = db_property('top12_fighting_point')

	# 公会数据 Union.id
	def union_db_id():
		dbkey = 'union_db_id'
		def fset(self, value):
			if value == self.db[dbkey]:
				return
			self.db[dbkey] = value
			if not value:
				self.game.union = None
				ObjectUnion.RoleUnionMap.pop(self.id, None)
				ta.track(self.game, event='leave_union')
			else:
				self.game.union = ObjectUnion.ObjsMap.get(value, None)
				ObjectUnion.RoleUnionMap[self.id] = value
				ObjectUnionCanSendRedPacket.refreshCanSend(self.game)
				ta.track(self.game, event='join_union')

			ObjectUnionFightGlobal.onRoleInfo(self.game)
			self.game.unionModel = {}
		return locals()
	union_db_id = db_property(**union_db_id())

	# 上次离开的公会id
	union_last_db_id = db_property('union_last_db_id')

	# 公会商店数据 UnionShop.id
	union_shop_db_id = db_property('union_shop_db_id')

	# 公会训练所数据 UnionTraining.id
	union_training_db_id = db_property('union_training_db_id')

	# 加入公会时间
	union_join_time = db_property('union_join_time')

	# 退出公会时间
	union_quit_time = db_property('union_quit_time')

	# 上次操作公会时间
	union_last_time = db_property('union_last_time')

	# 申请加入的公会列表(最多三个)
	def union_join_que():
		dbkey = 'union_join_que'
		def fset(self, value):
			if value != self.db[dbkey]:
				self.db[dbkey] = value
		return locals()
	union_join_que = db_property(**union_join_que())

	# 公会活动{huodong: {各活动异构}}
	union_huodongs = db_property('union_huodongs')

	# 收取公会邮件的游标
	union_mail_idx = db_property('union_mail_idx')

	# 公会副本奖励{union_fuben.csv ID: (最近领取月份, 次数)}
	union_fb_award = db_property('union_fb_award')

	@property
	def unionMemberModel(self):
		return {
			'id': self.id,
			'name': self.name,
			'logo': self.logo,
			'level': self.level,
			'vip': self.vip_level_display,
			'fighting_point': self.battle_fighting_point,
			'frame': self.frame
		}

	def resetUnion(self, lasttime=None):
		if not lasttime: # 不知道何时退出的处理，用last_time来模拟quit_time
			lasttime = self.union_last_time
		self.union_db_id = None
		self.union_place = UnionDefs.NonePlace
		self.union_join_que = []
		self.union_quit_time = lasttime
		self.union_join_time = 0
		self.union_mail_idx = 0
		self.union_role_packet_can_rob = False
		self.union_sys_packet_can_rob = False
		# 同步公会称号
		self.syncUnionTitle()

	def syncUnion(self, sync):
		if not sync:
			return

		if self.union_db_id and not sync['union_db_id']: # 有 -> 无
			self.resetUnion()
			return

		if not self.union_db_id and not sync['union_db_id']: # 无 -> 无
			self.union_join_que = sync['union_join_que']
			return

		if not self.union_db_id and sync['union_db_id']: # 无 -> 有
			self.union_join_time = sync['union_join_time']

		self.union_db_id = sync['union_db_id']
		self.union_place = sync['union_place']
		self.union_join_que = []
		self.union_last_db_id = self.union_db_id
		self.union_role_packet_can_rob = sync['union_role_packet_can_rob']
		self.union_sys_packet_can_rob = sync['union_sys_packet_can_rob']
		# 同步公会称号
		self.syncUnionTitle()

	def inUnionQuitCD(self):
		if not self.union_quit_time:
			return False

		cdt = datetimefromtimestamp(self.created_time)
		if todayinclock5elapsedays(cdt) < ConstDefs.newbieUnionQuitProtectDays: # 还在新号保护期内
			return False

		cdt = datetimefromtimestamp(self.union_quit_time)
		return todayinclock5elapsedays(cdt) < 1

	def getUnionFubenPassAward(self, month, csvID):
		lastMonth, lastTimes = self.union_fb_award.get(csvID, (0, 0))
		if lastMonth != month:
			def _afterGain():
				self.union_fb_award[csvID] = (month, lastTimes + 1)
			if lastMonth == 0:
				# 首次通关奖励
				return ObjectGainEffect(self.game, csv.union.union_fuben[csvID].firstAward, _afterGain)
			else:
				# 重复通关奖励
				return ObjectGainEffect(self.game, csv.union.union_fuben[csvID].repeatAward, _afterGain)
		else:
			raise ClientError(ErrDefs.unionFubenAwardGot)

	def getUnionAllFubenPassAward(self, month, csvIDs):
		ids, award = {}, ObjectGoodsMap(None, {})
		for csvID in csvIDs:
			lastMonth, lastTimes = self.union_fb_award.get(csvID, (0, 0))
			if lastMonth != month:
				if lastMonth == 0:
					# 首次通关奖励
					award += ObjectGoodsMap(None, csv.union.union_fuben[csvID].firstAward)
				else:
					# 重复通关奖励
					award += ObjectGoodsMap(None, csv.union.union_fuben[csvID].repeatAward)
				ids[csvID] = lastTimes

		def _afterGain():
			for csvID, lastTimes in ids.iteritems():
				self.union_fb_award[csvID] = (month, lastTimes + 1)
		return ObjectGainEffect(self.game, award.to_dict(), _afterGain)

	# GM封号
	def disable_flag():
		dbkey = 'disable_flag'
		def fset(self, value):
			self.db[dbkey] = value
			if value:
				from game.session import Session
				Session.discardSessionByAccountKey((self.area, self.account_id))
		return locals()
	disable_flag = db_property(**disable_flag())

	# GM禁言
	silent_flag = db_property('silent_flag')

	def initChatLimitCorrection(self):
		if self._chat_times_correction > 0:
			return self._chat_times_correction
		idx = upperBound(self.ChatLimit, self.gateStarSum, key=lambda x:x[0])
		idx = min(idx, len(self.ChatLimit) - 1)
		self._chat_times_correction = self.ChatLimit[idx][1]
		return self._chat_times_correction

	def checkNeedSilent(self, msg):
		now = nowtime_t()
		if self._silent_time and self._silent_time + ConstDefs.autoSilentDuration > now:
			raise ClientError(ErrDefs.chatAutoSilent)
		if self._lastchat and msg == self._lastchat[0]:
			count = self._lastchat[1] + 1
		else:
			count = 1
		if count >= ConstDefs.autoSilentSameNum:
			self._silent_time = now
			raise ClientError(ErrDefs.chatAutoSilent)
		self._lastchat = (msg, count)

	# 总的签到次数
	sign_in_count = db_property('sign_in_count')

	# 总的累积签到奖励
	sign_in_gift = db_property('sign_in_gift')

	# 最近一次签到日期
	last_sign_in_date = db_property('last_sign_in_date')

	# 连续签到天数
	sign_in_days = db_property('sign_in_days')

	# 排名档次奖励
	pw_rank_award = db_property('pw_rank_award')

	# vip礼包
	vip_gift = db_property('vip_gift')

	# 天赋树
	talent_trees = db_property('talent_trees')

	# 自动恢复技能点数时间
	@property
	def skillPointRecoverTime(self):
		return self._currVIPCsv.skillPointRecoverTime

	# 自动恢复技能点数刷新
	def refreshSkillPoint(self):
		nowTime = nowtime_t()
		point = int((nowTime - self.skill_point_last_recover_time) / self.skillPointRecoverTime)
		if point >= 1 and self.db['skill_point'] < self.skillPointMax:
			self.db['skill_point'] = min(self.db['skill_point'] + point, self.skillPointMax)
		self.skill_point_last_recover_time += point * self.skillPointRecoverTime

	# 主角当前技能点数
	def skill_point():
		dbkey = 'skill_point'
		def fget(self):
			self.refreshSkillPoint()
			return self.db[dbkey]
		def fset(self, value):
			old = self.db[dbkey]
			self.db[dbkey] = max(0, min(value, ConstDefs.skillPointLimitMax))
			if old >= self.skillPointMax and self.db[dbkey] < self.skillPointMax:
				self.skill_point_last_recover_time = nowtime_t()
		return locals()
	skill_point = db_property(**skill_point())

	# 玩家上次技能点数恢复时间
	skill_point_last_recover_time = db_property('skill_point_last_recover_time')

	# 历史最佳雪球得分
	snowball_maxpoint = db_property('snowball_maxpoint')

	# 公会扭蛋游戏火神兽个数
	luckyegg_count = db_property('luckyegg_count')

	# 公会扭蛋游戏总次数，获得奖励后重置
	luckyegg_times = db_property('luckyegg_times')

	# 神秘商店数据 MysteryShop.id
	mystery_shop_db_id = db_property('mystery_shop_db_id')

	# 所选择的克隆人房间CloneRoom.id
	clone_room_db_id = db_property('clone_room_db_id')

	# 元素挑战上阵卡牌
	def clone_deploy_card_db_id():
		dbkey = 'clone_deploy_card_db_id'
		def fset(self, value):
			self.db[dbkey] = value
			self.game.cards.fightChangeCloneDeployCard = None
		return locals()
	clone_deploy_card_db_id = db_property(**clone_deploy_card_db_id())

	# 元素挑战世界邀请时间
	clone_world_invite_last_time = db_property('clone_world_invite_last_time')

	# 元素挑战公会邀请时间
	clone_union_invite_last_time = db_property('clone_union_invite_last_time')

	# 元素挑战每日被踢次数
	clone_daily_be_kicked_num = db_property('clone_daily_be_kicked_num')

	# 元素挑战房间创建时间
	clone_room_create_time = db_property('clone_room_create_time')

	# 元素挑战最后一次进玩法的日期
	clone_last_date = db_property('clone_last_date')

	# 拳皇争霸数据 CraftRecord.id
	def craft_record_db_id():
		dbkey = 'craft_record_db_id'
		def fset(self, value):
			self.db[dbkey] = value
			ObjectCraftInfoGlobal.onRoleInfo(self.game)
		return locals()
	craft_record_db_id = db_property(**craft_record_db_id())

	# 跨服拳皇争霸数据 CrossCraftRecord.id
	def cross_craft_record_db_id():
		dbkey = 'cross_craft_record_db_id'
		def fset(self, value):
			self.db[dbkey] = value
			ObjectCrossCraftGameGlobal.onRoleInfo(self.game)
		return locals()
	cross_craft_record_db_id = db_property(**cross_craft_record_db_id())

	# 公会战数据 UnionFightRecord.id
	def union_fight_record_db_id():
		dbkey = 'union_fight_record_db_id'
		def fset(self, value):
			self.db[dbkey] = value
			ObjectUnionFightGlobal.onRoleInfo(self.game)
		return locals()
	union_fight_record_db_id = db_property(**union_fight_record_db_id())

	# 玩家前10卡牌RoleCard.id列表 [(RoleCard.id, RoleCard.card_id, RoleCard.skin_id)]
	# 固定长度为10，不能中间有0
	top10_cards = db_property('top10_cards')
	top12_cards = db_property('top12_cards')
	# 玩家前N卡牌RoleCard.id列表 [Card.id, ...]，markID不重复
	top_cards = db_property('top_cards')

	# 玩家皮肤字典 {skin_id:time}
	skins = db_property('skins')

	def _initCardSkin(self):
		# 初始化精灵皮肤属性加成
		self._skinAdd = defaultdict(lambda:(zeros(), zeros()))
		for skinID in self.skins:
			self.calCardSkinAttr(skinID)

	def onCardSkinRefresh(self, skinIDs):
		refreshAll = False
		markIDs = []
		for skinID in skinIDs:
			cfg = csv.card_skin[skinID]
			if cfg.attrAddType == CardSkinDefs.sameMarkID:
				markIDs.append(cfg.markID)
			elif cfg.attrAddType == CardSkinDefs.allCards:
				refreshAll = True
				break
		cards = self.game.cards.getAllCards().itervalues() if refreshAll else self.game.cards.getCardsByMarkIDs(markIDs)
		for card in cards:
			card.calcSkinAttrsAddition(card)
			card.onUpdateAttrs()

	# 计算皮肤的属性加成
	def calCardSkinAttr(self, skinID):
		cfg = csv.card_skin[skinID]
		markID = cfg.markID if cfg.attrAddType == CardSkinDefs.sameMarkID else 0
		for i in xrange(1, 99):
			attrKey = 'attrType%d' % i
			if attrKey not in cfg or not cfg[attrKey]:
				break
			attr = cfg[attrKey]
			num = str2num_t(cfg['attrNum%d' % i])
			self._skinAdd[markID][0][attr] += num[0]
			self._skinAdd[markID][1][attr] += num[1]

	def getCardSkinAttrsAdd(self, card):
		const = zeros()
		percent = zeros()
		for markID, add in self._skinAdd.iteritems():
			if not markID or card.markID == markID:
				const += add[0]
				percent += add[1]
		return const, percent

	def activeSkin(self, itemID):
		from game.session import Session
		csvItem = csv.items[itemID]
		specialArgsMap = csvItem.specialArgsMap
		skinID = specialArgsMap["skinID"]
		days = specialArgsMap["days"] or 0

		if days == 0:
			# 永久的
			self.skins[skinID] = 0
		else:
			# 限时的
			ndt = nowtime_t() + 3600 * 24 * days
			if skinID in self.skins:
				rt = self.skins[skinID]
				if rt == 0:
					# 原来的就是永久的
					pass
				elif rt < ndt:
					self.skins[skinID] = ndt
					Session.onSkinRefresh(ndt)
			else:
				self.skins[skinID] = ndt
				Session.onSkinRefresh(ndt)

		# 刷新皮肤属性加成
		self._initCardSkin()
		self.onCardSkinRefresh([skinID, ])

	def buySkin(self, skinID):
		csvSkin = csv.card_skin[skinID]

		if not csvSkin.costMap:
			raise ClientError("skin can't buy")

		cost = ObjectCostAux(self.game, csvSkin.costMap)
		if not cost.isEnough():
			raise ClientError(ErrDefs.skinRMBNotEnough)
		cost.cost(src='card_skin_buy')
		self.skins[skinID] = 0

		# 刷新皮肤属性加成
		self._initCardSkin()
		self.onCardSkinRefresh([skinID, ])

		return ObjectGainAux(self.game, csvSkin.extraItem)

	#添加头像
	def addLogo(self, logoID):
		if logoID not in self.logos:
			self.logos[logoID] = nowtime_t()
			self.game.achievement.onTargetTypeCount(AchievementDefs.LogoCount)

	def countLogos(self):
		# 头像的数量为logos、figures、cardIDs、skinIDs之和
		count = 0
		for k in csv.role_logo:
			cfg = csv.role_logo[k]
			if (cfg.cardID and self.pokedex.get(cfg.cardID, None)) or (cfg.itemID and self.logos.get(k, None)) or (cfg.roleID and self.figures.get(cfg.roleID, None)) or (cfg.skinID and self.skins.get(cfg.skinID, None)):
				count = count + 1
		return count

	#添加头像框
	def addFrame(self, frameID):
		if frameID not in self.frames:
			self.frames[frameID] = nowtime_t()

	#形象激活
	def activeFigure(self, figureID, isItemActive=False):
		if figureID in self.figures:
			return

		cfg = csv.role_figure[figureID]
		if not isItemActive:
			cost = ObjectCostAux(self.game, cfg.activeCost)
			if not cost.isEnough():
				raise ClientError('not enough')
			cost.cost(src='figure_active')

		self.figures[figureID] = nowtime_t()
		natures = self.calFigureAttr(figureID)
		self.game.cards.updateAllNaturesCardAttr(natures, f=lambda x: x.calcFigureAttrsAddition(x))
		self.game.achievement.onTargetTypeCount(AchievementDefs.LogoCount)

	#计算属性
	def calFigureAttr(self, figureID):
		needRefreshNatures = set()
		cfg = csv.role_figure[figureID]
		for i in xrange(1, 99):
			ty = 'attrType%d' % i
			if ty not in cfg:
				break
			attr = cfg[ty]
			if not attr:
				continue
			num = str2num_t(cfg['attrValue%d' % i])
			nature = cfg['attrNatureType%d' % i]
			if not self._figureAdd[nature].get(attr, None):
				self._figureAdd[nature][attr] = num
			else:
				constVal = self._figureAdd[nature][attr][0] + num[0]
				percentVal = self._figureAdd[nature][attr][1] + num[1]
				newAddAttr = (constVal, percentVal)
				self._figureAdd[nature][attr] = newAddAttr
			needRefreshNatures.add(nature)
		return needRefreshNatures

	#获得形象属性加成
	def getFigureAttrsAdd(self, card):
		figureAttrAdd = {}
		for natureType, add in self._figureAdd.iteritems():
			if not natureType or card.natureType == natureType:
				for attr, num in add.iteritems():
					if not figureAttrAdd.get(attr, None):
						figureAttrAdd[attr] = num
					else:
						constVal = figureAttrAdd[attr][0] + num[0]
						percentVal = figureAttrAdd[attr][1] + num[1]
						figureAttrAdd[attr] = (constVal, percentVal)
		return figureAttrAdd

	#形象初始化加成
	def _initFigure(self):
		self._figureAdd = defaultdict(dict)
		for figureID in self.figures:
			self.calFigureAttr(figureID)

	def getFigureAbilitySkills(self, isGlobal=False):
		skills = {}
		skillFigureIDs = self.skill_figures.get(self.figure, [self.figure])

		if skillFigureIDs:
			for figureID in skillFigureIDs:
				cfg = csv.role_figure[figureID]
				for index, skillID in enumerate(cfg.skills):
					if self.level >= cfg.activeLevel[index]:
						if isGlobal:
							if csv.skill[skillID].isGlobal:
								skills[skillID] = 1
						else:
							if not csv.skill[skillID].isGlobal:
								skills[skillID] = 1
		return skills

	# 头衔 {id: [invalidTime, openTime]}
	titles = db_property('titles')

	# 称号计数器
	title_counter = db_property('title_counter')

	# 玩家选择的头衔, -1表示置空
	title_id = db_property('title_id')

	# 获得称号
	def addTitle(self, titleID, days=None, openTime=None):
		if days is None:
			days = csv.title[titleID]["days"]
		if openTime is None:
			openTime = nowtime_t()

			if days == 0:  # 永久的
				self.titles[titleID] = (0, openTime)
			else:  # 限时的
				invalidTime, _ = self.titles.get(titleID, (nowtime_t(), 0))
				invalidTime += 3600 * 24 * days
				self.titles[titleID] = (invalidTime, openTime)
				from game.session import Session
				Session.onRoleRefresh(invalidTime)
		else:  # 排行称号
			invalidTime = 3600 * 24 * days + openTime
			self.titles[titleID] = (invalidTime, openTime)
			from game.session import Session
			Session.onRoleRefresh(invalidTime)

		self._initTitle()
		if self._inited:
			self.onTitlesRefresh(titleID)

	# 删除称号
	def removeTitle(self, titleID):
		self.titles.pop(titleID, None)  # 移除称号
		self._initTitle()  # re-calc title addtions
		self.onTitlesRefresh(titleID)

	def onTitlesRefresh(self, titleID):
		cfg = csv.title[titleID]
		natures = set()
		for i in xrange(1, 99):
			ty = 'attrType%d' % i
			if ty not in cfg:
				break
			attr = cfg[ty]
			if not attr:
				continue
			natures.add(cfg['attrNatureType%d' % i])

		self.game.cards.updateAllNaturesCardAttr(natures, f=lambda x: x.calcTitleAttrsAddition(x))

	# 计算称号的属性加成 _titleAdd
	def calTitleAttr(self, titleID):
		cfg = csv.title[titleID]
		for i in xrange(1, 99):
			ty = 'attrType%d' % i
			if ty not in cfg:
				break
			attr = cfg[ty]
			if not attr:
				continue
			nature = cfg['attrNatureType%d' % i]
			num = str2num_t(cfg['attrValue%d' % i])
			if not self._titleAdd[nature].get(attr, None):
				self._titleAdd[nature][attr] = num
			else:
				constVal = self._titleAdd[nature][attr][0] + num[0]
				percentVal = self._titleAdd[nature][attr][1] + num[1]
				newAddAttr = (constVal, percentVal)
				self._titleAdd[nature][attr] = newAddAttr

	# 获得 最新 称号属性加成
	def getTitleAttrsAdd(self, card):
		titleAttrAdd = {}
		for natureType, add in self._titleAdd.iteritems():
			if not natureType or card.natureType == natureType:
				for attr, num in add.iteritems():
					if not titleAttrAdd.get(attr, None):
						titleAttrAdd[attr] = num
					else:
						constVal = titleAttrAdd[attr][0] + num[0]
						percentVal = titleAttrAdd[attr][1] + num[1]
						titleAttrAdd[attr] = (constVal, percentVal)
		return titleAttrAdd

	def _initTitle(self):
		if self.title_id > 0 and self.title_id not in self.titles:
			self.title_id = -1
		# 初始化称号的属性加成
		self._titleAdd = defaultdict(dict)
		for titleID in self.titles:
			self.calTitleAttr(titleID)

	def expireTitles(self):
		nowt = nowtime_t()
		ret = None
		for titleID in self.titles.keys():
			invalidTime, _ = self.titles[titleID]
			if invalidTime > 0:
				if invalidTime <= nowt: # 已过期
					self.removeTitle(titleID)
				else:
					if ret is None or ret > invalidTime:
						ret = invalidTime
		return ret

	@classmethod
	def getRankTitleMax(cls, feature):
		'''
		每类排行榜的最大名次
		'''
		if feature not in cls.TitleRankMap:
			return 0
		return max(cls.TitleRankMap[feature].keys())

	def refreshRankTitle(self):
		titleRoles = ObjectServerGlobalRecord.getRoleTitle()
		for titleID, roleInfo in titleRoles.iteritems():
			if titleID in self.titles and self.id not in roleInfo:
				self.removeTitle(titleID)
				continue
			if self.id in roleInfo:
				self.onRankTitle(titleID, roleInfo[self.id])

	def onRankTitle(self, titleID, openTime):
		cfg = csv.title[titleID]
		if cfg is None:
			return
		invalidTime = 3600 * 24 * cfg.days + openTime
		if invalidTime <= nowtime_t():  # 已获得并已过期废弃
			return
		# 已有的就不发了
		repeat = False
		if titleID in self.titles:
			if openTime == self.titles[titleID][1]:
				return
			repeat = True

		self.addTitle(titleID, openTime=openTime)
		logger.info('role %d %s add rankTitle %d, openTime %s', self.uid, self.pid, titleID, openTime)

		from game.mailqueue import MailJoinableQueue
		mailID = TitleGetMailID
		if repeat:
			mailID = TitleGetAgainMailID
		mail = self.makeMyMailModel(mailID, contentArgs=cfg.title)
		MailJoinableQueue.send(mail)

	@classmethod
	def getRankTtile(cls, feature, rank):
		'''
		获取对应称号的ID
		'''
		if FeatureDefs.Title not in ObjectFeatureUnlockCSV.FeatureMap:
			return None
		if feature not in cls.TitleRankMap:
			return None

		titleID = cls.TitleRankMap[feature].get(rank, None)  # 该名次 对应称号ID
		return titleID

	def syncUnionTitle(self):
		# {titleID: [unionID, openTime]}
		titleUnions = ObjectServerGlobalRecord.getUnionTitle()
		for titleID, (unionID, openTime) in titleUnions.iteritems():
			if titleID in self.titles:
				# 公会已解散  || 称号已经是其他公会
				if self.union_db_id is None or unionID != self.union_db_id:
					self.removeTitle(titleID)
					continue
			# 有公会 且 同公会
			if self.union_db_id and self.union_db_id == unionID:
				self.onRankTitle(titleID, openTime)

	def refreshYYCounter(self):
		if YYHuoDongDefs.TimeLimitUpDraw in self.game.lotteryRecord.yyhuodong_counters:
			return
		counter = 0
		for yyID, record in self.yyhuodongs.iteritems():
			if yyID not in csv.yunying.yyhuodong:
				continue
			cfg = csv.yunying.yyhuodong[yyID]
			if cfg.type != YYHuoDongDefs.TimeLimitUpDraw:
				continue
			info = record.get('info', {})
			counter += info.get('limit_up_counter_1', 0)
			counter += info.get('limit_up_counter_10', 0) * 10

		self.game.lotteryRecord.yyhuodong_counters[YYHuoDongDefs.TimeLimitUpDraw] = counter

	def refreshOnlineGift(self, isEnd=False):
		# 未解锁状态也计数
		now = nowtime_t()
		if len(self.game.dailyRecord.online_gift) == 0:
			self.game.dailyRecord.online_gift = {
				'starttime': now,
				'idx': 0,
				'totaltime': 0.0,
			}
		if self.game.dailyRecord.online_gift['starttime'] == 0:
			self.game.dailyRecord.online_gift['starttime'] = now

		self.game.dailyRecord.online_gift['totaltime'] += nowtime_t() - self.game.dailyRecord.online_gift['starttime']
		self.game.dailyRecord.online_gift['starttime'] = 0 if isEnd else now

	def getOnlineGiftEffect(self):
		if not ObjectFeatureUnlockCSV.isOpen(FeatureDefs.OnlineGift, self.game):
			raise ClientError(ErrDefs.onlineGiftNotOpen)

		online_gift = self.game.dailyRecord.online_gift
		if len(online_gift) == 0:
			raise ClientError(ErrDefs.onlineGiftNotOpen)

		if online_gift['idx'] + 1 not in csv.online_gift:
			raise ClientError(ErrDefs.onlineGiftNotOpen)

		cfg = csv.online_gift[online_gift['idx'] + 1]
		if online_gift['totaltime'] < cfg.periods * 60:
			raise ClientError(ErrDefs.onlineGiftNotOpen)

		def _afterGain():
			online_gift['idx'] += 1

		eff = ObjectGainEffect(self.game, cfg.award, _afterGain)
		# 随机奖励
		lib = ObjectDrawRandomItem.getObject(cfg.randLib)
		if lib:
			item = lib.getRandomItem()
			award = ObjectDrawRandomItem.packToDict(item)
			eff += ObjectGainAux(self.game, award)
		return eff

	# [date,point,gold] 2048游戏当日还未结算的金币
	yy2048_gold = db_property('yy2048_gold')

	# 报名跨服拳皇争霸日子
	cross_craft_sign_up_date = db_property('cross_craft_sign_up_date')

	@property
	def rankRoleModel(self):
		return {
			'id': self.id,
			'logo': self.logo,
			'frame': self.frame,
			'title': self.title_id,
			'name': self.name,
			'level': self.level,
			'vip_level': self.vip_level_display,
			'union_db_id': self.union_db_id,
			# 'union_name': self.game.union.name if self.union_db_id else '',
		}

	@property
	def chatRoleModel(self):
		return {
			'id': self.id,
			'name': self.name,
			'logo': self.logo,
			'frame': self.frame,
			'title': self.title_id,
			'level': self.level,
			'vip': self.vip_level_display,
		}

	@property
	def competitor(self):
		return {
			'id': self.id,
			'name': self.name,
			'level': self.level,
			'vip': self.vip_level_display,
			'logo': self.logo,
			'frame': self.frame,
			'figure': self.figure,
		}

	def crossRole(self, recordID):
		return {
			'role_db_id': self.id,
			'record_db_id': recordID,
			'game_key': self.areaKey,
			'name': self.name,
			'logo': self.logo,
			'frame': self.frame,
			'level': self.level,
			'figure': self.figure,
			'title': self.title_id,
			'vip': self.vip_level_display,
		}

	def crossRankRoleInfo(self, rankData, otherData=None):
		return {
			'role_id': self.id,
			'logo': self.logo,
			'frame': self.frame,
			'name': self.name,
			'level': self.level,
			'vip': self.vip_level_display,
			'game_key': self.areaKey,
			'rank_data': rankData,
			'other_data': otherData if otherData else [],
		}

	# 无尽之塔最高层数 int
	endless_tower_max_gate = db_property('endless_tower_max_gate')

	# 无尽之塔关卡奖励 1-首通 2-扫荡（战斗）{ gainID : type }
	endless_tower_awards = db_property('endless_tower_awards')

	# 无尽之塔当前层数 int
	def endless_tower_current():
		dbkey = 'endless_tower_current'

		def fset(self, value):
			if value == self.db[dbkey]:
				return
			old = self.db[dbkey]
			if value > old and value != ObjectEndlessTowerGlobal.MinGate and old > self.db['endless_tower_max_gate'] and old <= ObjectEndlessTowerGlobal.MaxGate:
				self.db['endless_tower_max_gate'] = old
			self.db[dbkey] = value
		return locals()
	endless_tower_current = db_property(**endless_tower_current())

	# 公会 修炼中心 {skillID: level}
	union_skills = db_property('union_skills')

	def onUnionSkill(self, skillID, unionLevel):
		level = self.union_skills.get(skillID, 0)
		if not self.isUnlockUnionSkill(skillID):
			raise ClientError("union skill not unlock")
		# 判断是否 已最大等级
		if level >= csv.union.union_level[unionLevel].skillLvMax:
			raise ClientError("union skill level max")
		cfgNextLevel = self.UnionSkillIDLevelMap.get((level+1, skillID), None)
		if not cfgNextLevel:
			raise ClientError("the max level, can not skill")
		# 判断公会币消耗是否足够
		cfgLevel = self.UnionSkillIDLevelMap.get((level, skillID), None)
		cost = ObjectCostAux(self.game, cfgLevel.cost)
		if not cost.isEnough():
			raise ClientError("skill coin3 not enough")
		cost.cost(src='union_skill_cost')
		self.union_skills[skillID] = level + 1

		# 计算属性加成
		self._initUnionSkill()
		nature = csv.union.union_skill[skillID].attrNatureType
		self.game.cards.updateAllNatureCardAttr(nature, f=lambda x: x.calcUnionSkillAttrsAddition(x, self))

	def isUnlockUnionSkill(self, skillID):
		cfg = csv.union.union_skill[skillID]
		# 前置条件都为空时，默认已解锁
		if not cfg.preSkill and not cfg.needGuildLv:
			return True
		if cfg.preSkill:
			preid, prelevel = cfg.preSkill
			if self.union_skills.get(preid, 0) >= prelevel:
				return True
		else:
			if cfg.needGuildLv:
				if self.union_level >= cfg.needGuildLv:
					return True
		return False

	def getUnionSkillAttrsAdd(self, card):
		const, percent = zeros(), zeros()
		for natureType, (c, p) in self._unionStillAdd.iteritems():
			if not natureType or card.natureType == natureType:
				const += c
				percent += p
		return const, percent

	def _initUnionSkill(self):
		for i in csv.union.union_skill:
			if self.isUnlockUnionSkill(i):
				self.union_skills.setdefault(i, 0)

		self._unionStillAdd = self.calcUnionSkillAttrAddition(self.union_skills)

	@classmethod
	def calcUnionSkillAttrAddition(cls, union_skills):
		additions = {} # {nature: (const, percent)}
		for skillID, level in union_skills.iteritems():
			cfg = csv.union.union_skill[skillID]
			nature = cfg['attrNatureType']
			attr = cfg['attrType']
			if nature not in additions:
				additions[nature] = (zeros(), zeros())

			cfg = cls.UnionSkillIDLevelMap.get((level, skillID), None)
			if cfg:
				c, p = str2num_t(cfg['attrValue'])
				additions[nature][0][attr] += c # const
				additions[nature][1][attr] += p # percent
		return additions

	def getUnionDailyGift(self):
		'''
		领取公会每日礼包
		'''
		dailyGift = {}
		cfg = csv.union.union_level[self.game.role.union_level]
		if cfg:
			dailyGift = cfg.dailyGift
		eff = ObjectGainAux(self.game, dailyGift)
		return eff

	# 公会捐献任务 {csvid: (count, flag)}
	union_contrib_tasks = db_property('union_contrib_tasks')

	# 可发送的公会成就红包 [(csvid,time)]
	union_redpackets = db_property('union_redpackets')

	# 公会成就红包获取次数 {csvid: times}
	union_redpacket_times = db_property('union_redpacket_times')

	def refreshUnionRedpackets(self, conditionType, count=None, time=None):
		if not self.union_db_id:
			return

		activeTime = time if time else nowtime_t()
		ndt = None
		for i in self.UnionRedpacketMap.get(conditionType, []):
			cfg = csv.union.red_packet[i]
			if cfg.type == UnionDefs.UnionRedpacketOnce and self.union_redpacket_times.get(i, 0) >= 1: # 累计只能获得一次
				continue

			if cfg.type == UnionDefs.UnionRedPacketDaily and self.todayActivedUnionRedPacket(i): # 每日
				continue

			deadline = activeTime + cfg.date * 3600 * 24
			if conditionType == TargetDefs.RechargeRmb: # 充值
				if self.game.dailyRecord.recharge_rmb_sum == 0: # maybe not init ok, no vip_sum
					continue
				if cfg.type == UnionDefs.UnionRedPacketDaily: # 每日充值
					count = self.game.dailyRecord.recharge_rmb_sum
				elif cfg.type == UnionDefs.UnionRedpacketMore: # 累计充值
					count = self._vip_sum / cfg['conditionNum'] - self.union_redpacket_times.get(i, 0)
					if count > 0:
						for _ in xrange(count):
							self.addUnionRedPacket(i, activeTime)
						if ndt is None or ndt > deadline:
							ndt = deadline
					continue

			_, pred = predGen(cfg.conditionType, cfg.conditionNum, None)
			if pred(self.game, count):
				self.addUnionRedPacket(i, activeTime)
				if ndt is None or ndt > deadline:
					ndt = deadline
		if ndt:
			from game.session import Session
			Session.onRoleRefresh(ndt)

	def addUnionRedPacket(self, csvID, time):
		self.union_redpackets.append((csvID, time))
		if csv.union.red_packet[csvID].type == UnionDefs.UnionRedPacketDaily:
			self.game.dailyRecord.redPacket_daily.append(csvID)
		self.union_redpacket_times[csvID] = self.union_redpacket_times.get(csvID, 0) + 1

	def todayActivedUnionRedPacket(self, csvID):
		# 判断的前提，可发送红包有效期必定大于一天
		actived = False
		if csvID in self.game.dailyRecord.redPacket_daily:
			actived = True
		return actived

	def expireUnionCanSendPacket(self):
		now = nowtime_t()
		ret = None
		union_redpackets = []
		flag = False
		for csvID, time in self.union_redpackets:
			cfg = csv.union.red_packet[csvID]
			if cfg is None:
				flag = True
				continue
			deadline = time + cfg.date * 3600 * 24
			if now < deadline:
				union_redpackets.append((csvID, time))
				if ret is None or ret > deadline:
					ret = deadline
			else:
				flag = True # 过期
		if flag:
			self.union_redpackets = union_redpackets
		return ret

	def refreshUnionContribTasks(self, olddate):
		if not self.union_contrib_tasks:
			return

		dt = datetime.datetime.combine(int2date(olddate), datetime.time(hour=DailyRefreshHour))
		weekreset = weekinclock5date2int() != weekinclock5date2int(dt)
		tasks = {}
		for k, v in self.union_contrib_tasks.iteritems():
			cfg = csv.union.union_task[k]
			if cfg.type == UnionDefs.UnionTaskWeek and not weekreset:
				tasks[k] = v
		self.union_contrib_tasks = tasks

	# 训练师等级
	trainer_level = db_property('trainer_level')

	# 训练师经验
	trainer_exp = db_property('trainer_sum_exp')

	# 训练师特权等级 {csvid: level}
	trainer_skills = db_property('trainer_skills')

	# 训练师属性加成 {csvid: level}
	trainer_attr_skills = db_property('trainer_attr_skills')

	# 派遣任务 [{csvID:csvID, fighting_point:fightingPoint, status:status, cardIDs:cardIDs, ending_time:endingTime, extra_award_point:extraAwardPoint}]
	dispatch_tasks = db_property('dispatch_tasks')

	# 派遣任务最新刷新时间
	dispatch_task_last_time = db_property('dispatch_task_last_time')

	def refreshDispatchTasks(self, force=False):
		if not force:
			now_p = nowtime2period(DispatchTaskRefreshPeriods)
			if now_p == self.dispatch_task_last_time:
				return
			self.dispatch_task_last_time = now_p
			self.dispatch_tasks = [copy.deepcopy(x) for x in self.dispatch_tasks if x['status'] == DispatchTaskDefs.TaskFighting] # 自动刷新 只留下进行中的
			count = self.dispatchTaskCount
		else:
			old = len(self.dispatch_tasks)
			self.dispatch_tasks = [copy.deepcopy(x) for x in self.dispatch_tasks if x['status'] != DispatchTaskDefs.TaskCanGet] # 手动刷新 只删除可接收的
			count = old - len(self.dispatch_tasks)
			if self.game.trainer.dispatchTaskFreeRefreshTimes > self.game.dailyRecord.dispatch_refresh_free_times:
				# 特权免费刷新
				self.game.dailyRecord.dispatch_refresh_free_times += 1
			else:
				rmb = int(ConstDefs.dispatchTaskRefreshCostRMB * count)
				cost = ObjectCostAux(self.game, {'rmb': rmb})
				if not cost.isEnough():
					raise ClientError("cost rmb not enough")
				cost.cost(src='dispatchTask_refresh_cost')

		self.randomDispatchTask(count)

	def randomDispatchTask(self, count):
		cfg = None
		for i in csv.dispatch_task.rankdom:
			levelRange = csv.dispatch_task.rankdom[i]['levelRange']
			if levelRange[0] <= self.level <= levelRange[1]:
				cfg = csv.dispatch_task.rankdom[i]
				break
		if cfg is None:
			logger.warning('dispatch task random level range smaller, level %d', self.level)
			return

		weights = {k: int(v * (1 + self.dispatchTaskQualityUpd.get(k, 0))) for k, v in cfg.weights.iteritems()}
		randobj = WeightRandomObject(weights)
		baseFightingPoint = csv.dispatch_task.fighting_point[self.level].fightingPoint
		for _ in xrange(count):
			quality, _ = randobj.getRandom()
			tasks = {}
			for cfg in self.DispatchTaskQualityMap[quality]:
				levelRange = cfg.levelRange
				if levelRange[0] <= self.level <= levelRange[1]:
					tasks[cfg.id] = cfg.weight
			if not tasks:
				logger.warning('dispatch task quality %d level %d not tasks', quality, self.level)
				continue
			csvID, _ = WeightRandomObject.onceRandom(tasks)
			cfg = csv.dispatch_task.tasks[csvID]
			fightingPoint = int(baseFightingPoint * random.uniform(*cfg.fightinPoints))
			self.dispatch_tasks.append({
				'csvID': cfg.id,
				'fighting_point': fightingPoint,
				'status': DispatchTaskDefs.TaskCanGet,
			})

	def beginDispatchTask(self, taskIndex, cards):
		task = self.dispatch_tasks[taskIndex]
		if task['status'] != DispatchTaskDefs.TaskCanGet:
			raise ClientError('status error, cant not dispatch')
		cfg = csv.dispatch_task.tasks[task['csvID']]
		if cfg['cardNums'] != len(cards):
			raise ClientError('card count error, cant not dispatch')

		fightingPoint = 0
		natures = set()
		stars, advanves, raritys = {}, {}, {}
		for card in cards:
			if card.id in self.game.dailyRecord.dispatch_cardIDs:
				raise ClientError('card in rest')
			fightingPoint = fightingPoint + card.fighting_point
			natures.add(card.natureType)
			natures.add(card.natureType2)
			stars[card.star] = stars.get(card.star, 0) + 1
			advanves[card.advance] = advanves.get(card.advance, 0) + 1
			raritys[card.rarity] = raritys.get(card.rarity, 0) + 1
		if fightingPoint < task['fighting_point']:
			raise ClientError('fightingPoint not enough, cant not dispatch')

		# 记录派遣过的卡牌
		for card in cards:
			self.game.dailyRecord.dispatch_cardIDs.append(card.id)

		rate = 0.0
		reach = [] # 达成的条件
		for i in xrange(1, 100):
			condition = 'condition%d' % i
			if condition not in cfg:
				break
			condition = cfg[condition]
			adv, num = cfg['condition%dArg' % i].items()[0]
			got = False
			if condition == 1: # star
				got = sum([v for k, v in stars.iteritems() if k >= adv]) >= num
			elif condition == 2: # advance
				got = sum([v for k, v in advanves.iteritems() if k >= adv]) >= num
			elif condition == 3: # rarity
				got = sum([v for k, v in raritys.iteritems() if k >= adv]) >= num
			if got:
				rate += cfg['rate%d' % i]
			reach.append(1 if got else 0)

		hitnatures = []
		for cardNature in cfg['cardNatures']:
			if cardNature in natures:
				hitnatures.append(cardNature)
		rate = rate + round((len(hitnatures) * 1.0 / len(cfg['cardNatures'])) * cfg['cardNatureRate'], 1)
		rate = min(rate, 100)
		task['status'] = DispatchTaskDefs.TaskFighting
		task['ending_time'] = nowtime_t() + cfg['duration'] * 60
		task['extra_award_point'] = rate
		task['reach_fighting_point'] = fightingPoint
		task['reach'] = reach
		task['reach_natures'] = hitnatures

	def getDispatchTaskAward(self, taskIndex, force):
		task = self.dispatch_tasks[taskIndex]
		if task['status'] != DispatchTaskDefs.TaskFighting:
			raise ClientError('status error, cant not get award or finish')
		delta = task['ending_time'] - nowtime_t()
		if force:  # 立即完成
			if delta > 60:  # 60s 内免费
				costRmb = int(max(math.ceil(delta / ConstDefs.dispatchTaskDoneAtOnceSecond) - 1, 0) * ConstDefs.dispatchTaskDoneAtOnceCostRMB)
				cost = ObjectCostAux(self.game, {'rmb': costRmb})
				if not cost.isEnough():
					raise ClientError("cost rmb not enough")
				cost.cost(src='dispatchTask_manualEnd_cost')
		else:
			if delta > 0:
				raise ClientError("task can not finish")

		task['status'] = DispatchTaskDefs.TaskFinish
		cfg = csv.dispatch_task.tasks[task['csvID']]
		eff = ObjectGainAux(self.game, cfg['award'])
		extraEff = None
		randomNum = round(random.uniform(0, 100), 1)
		if task['extra_award_point'] >= randomNum:
			extraEff = ObjectGainAux(self.game, cfg['extraAward'])
		return eff, extraEff, cfg.quality

	# 卡牌好感度
	card_feels = db_property('card_feels')

	# z觉醒
	zawake = db_property('zawake')
	zawake_skills = db_property('zawake_skills')

	# 主城场景精灵
	city_sprites = db_property('city_sprites')

	def refreshCitySprites(self):
		now_p = nowtime2period(CitySpriteRefreshPeriods)
		last_p = self.city_sprites.get('date', 0)
		if last_p == now_p:
			return
		self.city_sprites['date'] = now_p
		self.city_sprites['groups'] = self._randomCitySpriteGroup()

		# 如果已经触发了百变怪，就要重新随机百变怪位置
		baibian = self.city_sprites['baibian']
		if baibian and baibian['id']:
			self.randomBaibian()

	def _randomCitySpriteGroup(self):
		count = ConstDefs.citySpriteMax
		groups = []
		weights = [(group, v[0].weight, v[0].type, len(v)) for group, v in self.CitySpriteGroups.iteritems() if len(v) <= count] # [(group, weight), ]
		for _ in xrange(ConstDefs.citySpriteMax):
			if count <= 0 or not weights:
				break
			group, _, typ, _ = WeightRandomObject.onceRandom(weights)
			groups.append(group)
			count -= 1
			weights = [v for v in weights if v[0] != group and v[2] != typ and v[3] <= count]
		return groups

	def _randomInGroups(self, groups):
		cfgs = []
		for group in groups:
			v = self.CitySpriteGroups.get(group, None)
			if v:
				cfgs.extend(v)

		cfgs = [cfg for cfg in cfgs if cfg.shape_shifter]
		if not cfgs: return 0  # 没有百变怪
		cfg = random.choice(cfgs)
		return cfg.id

	def randomBaibian(self):
		# 百变怪: shape shifter
		groups = self.city_sprites['groups']

		csvid = self._randomInGroups(groups)
		self.city_sprites['baibian']['id'] = csvid
		self.city_sprites['baibian']['last'] = int(nowtime_t())

	def randomMiniQ(self):
		self.city_sprites['miniQ']['id'], _ = self.CitySpriteMiniQ.getRandom()
		self.city_sprites['miniQ']['last'] = int(nowtime_t())

	# 探险器 {csvID: explorer}
	explorers = db_property('explorers')

	# 探险寻宝商店数据 ExplorerShop.id
	explorer_shop_db_id = db_property('explorer_shop_db_id')

	# 商店限购记录 {key: {position: (times, date)}}
	shop_limit = db_property('shop_limit')

	def canShopBuy(self, key, position, count, limittype, limittimes):
		v = self.shop_limit.setdefault(key, {})
		times, date = v.get(position, (0, 0))
		if limittype == 1: # 日限购
			now = todayinclock5date2int()
		elif limittype == 2: # 周限购
			now = weekinclock5date2int()
		elif limittype == 3: # 月限购
			now = monthinclock5date2int()
		elif limittype == 4: # 永久限购
			now = date
		if date != now:
			v.pop(position, None)
			return True
		return times + count <= limittimes

	def addShopBuy(self, key, position, count, limittype):
		v = self.shop_limit.setdefault(key, {})
		if position in v:
			times, date = v[position]
			v[position] = (times + count, date)
		else:
			if limittype == 1: # 日限购
				now = todayinclock5date2int()
			elif limittype == 2: # 周限购
				now = weekinclock5date2int()
			elif limittype == 3: # 月限购
				now = monthinclock5date2int()
			elif limittype == 4: # 永久限购
				now = todayinclock5date2int()
			v[position] = (count, now)

	# 碎片商店数据 FragShop.id
	frag_shop_db_id = db_property('frag_shop_db_id')

	# 试炼塔数据 RandomTower.id
	random_tower_db_id = db_property('random_tower_db_id')

	# 试炼塔商店 RandomTowerShop.id
	random_tower_shop_db_id = db_property('random_tower_shop_db_id')

	# 精灵捕捉数据 Capture.id
	capture_db_id = db_property('capture_db_id')

	# 钓鱼数据 Fishing.id
	fishing_db_id = db_property('fishing_db_id')

	def makeCrossFishingRankModel(self):
		return {
			'role_db_id': self.id,
			'game_key': self.areaKey,
			'name': self.name,
			'logo': self.logo,
			'level': self.level,
			'frame': self.frame,
			'point': self.game.fishing.point,
			'special_fish_num': self.game.fishing.special_fish_num
		}

	def getGateExtraAwarrd(self, gateID, type):
		dbField, csvField, src = GateAwardMap[type]

		gate_star = self.gate_star.get(gateID, None)
		if gate_star is None:
			raise ClientError('not pass the gate')
		flag = gate_star.get(dbField, -1)
		# 已领取 或 没有达成条件 直接返回
		if flag == 0 or flag == -1:
			return ObjectGainAux(self.game, {})
		# 标志已领取
		self.gate_star[gateID][dbField] = 0
		return ObjectGainAux(self.game, csv.scene_conf[gateID][csvField])

	# 通行证 {yyID: 运营活动ID; buy: 购买情况; level: 等级; exp: 经验; normal_award: 普通奖励; elite_award: 进阶奖励;
	# task: 任务完成情况; lastWeek: 最近一次周任务时间; weekNum: 第几周; lastDay: 最近一天;}
	# shop: {csvID: 购买次数}
	passport = db_property('passport')

	# 成长向导 {csv_id: (flag, count)} flag=1可领取, flag=0已领取
	grow_guide = db_property('grow_guide')

	def onGrowGuideTask(self, type, val):
		csvids = self.GrowGuideTargetMap.get(type, None)
		if not csvids:
			return
		for csvid in csvids:
			cfg = csv.grow_guide[csvid]
			flag, count = self.grow_guide.get(csvid, (-1, 0))
			if flag != -1:
				continue
			if cfg.type == 2: # 任务
				count += val
				_, pred = predGen(type, cfg.taskParam, None)
				if pred(self.game, count):
					flag = 1
			elif cfg.type == 1: # unlock 奖励
				if ObjectFeatureUnlockCSV.isOpen(cfg.feature, self.game):
					flag = 1
			self.grow_guide[csvid] = (flag, count)

	@property
	def lastLoginDateTime(self):
		return datetimefromtimestamp(self.last_login_time)

	# 饰品商店数据 EquipShop.id
	equip_shop_db_id = db_property('equip_shop_db_id')

	# 钓鱼商店数据 FishingShop.id
	fishing_shop_db_id = db_property('fishing_shop_db_id')

	# 抽卡累计宝箱 {drawType: {csvID: 0}}
	draw_sum_box = db_property('draw_sum_box')

	def getDrawSumBox(self, csvID):
		if csvID not in csv.draw_count:
			raise ClientError('param error')

		cfg = csv.draw_count[csvID]

		if cfg.drawType not in [DrawSumBoxDefs.RMBType, DrawSumBoxDefs.LimitUpDrawType, DrawSumBoxDefs.ChipType]:
			raise ClientError("sum box not open")

		if cfg.drawType == DrawSumBoxDefs.RMBType and not ObjectFeatureUnlockCSV.isOpen(FeatureDefs.DrawSumBox, self.game):
			raise ClientError(ErrDefs.levelLessNoOpened)
		elif cfg.drawType == DrawSumBoxDefs.LimitUpDrawType and not ObjectFeatureUnlockCSV.isOpen(FeatureDefs.TimeLimitUpDrawSumBox, self.game):
			raise ClientError(ErrDefs.levelLessNoOpened)

		record = self.draw_sum_box.setdefault(cfg.drawType, {})
		if record.get(csvID, -1) == 0:
			raise ClientError('has gain')

		if self.game.lotteryRecord.drawCounterSum(cfg.drawType) < cfg.count:
			raise ClientError('draw count enough')

		def _afterGain():
			record[csvID] = 0

		return ObjectGainEffect(self.game, cfg.award, _afterGain)

	# 成就点 {成就类别: points}
	achievement_points = db_property('achievement_points')

	# 成就任务 {csv_id: (flag, time)} (可领:1  已领: 0)
	achievement_tasks = db_property('achievement_tasks')

	# 成就宝箱奖励 {csv_id: flag} (可领:1  已领: 0)
	achievement_box_awards = db_property('achievement_box_awards')

	# 成就rank排名
	achievement_rank = db_property('achievement_rank')

	# 各类成就计数器 {type: count}
	achievement_counter = db_property('achievement_counter')

	def countStarGate(self, gateType, star):
		'''
		关卡星级 数量
		'''
		total = 0
		for gateID, v in self.gate_star.iteritems():
			if ObjectMap.queryGateType(gateID) == gateType:
				if v.get('star', 0) >= star:
					total += 1
		return total

	@property
	def huodongRedPacketSend(self):
		return self._currVIPCsv.huodongRedPacketSend

	@property
	def huodongRedPacketRob(self):
		return self._currVIPCsv.huodongRedPacketRob

	@property
	def huodongCrossRedPacketSend(self):
		return self._currVIPCsv.huodongCrossRedPacketSend

	@property
	def huodongCrossRedPacketRob(self):
		return self._currVIPCsv.huodongCrossRedPacketRob

	@property
	def endlessTowerResetTimes(self):
		return self._currVIPCsv.endlessTowerResetTimes

	# 公会碎片赠予历史记录
	union_frag_donate_historys = db_property('union_frag_donate_historys')

	def addUnionFragDonateHistory(self, role, frag):
		history = {
			'role_id': role.id,
			'name': role.name,
			'logo': role.logo,
			'frame': role.frame,
			'level': role.level,
			'frag': frag,
			'time': int(nowtime_t()),
		}
		if self.union_frag_donate_historys is None:
			self.union_frag_donate_historys = []
		self.union_frag_donate_historys.append(history)
		self.union_frag_donate_historys = self.union_frag_donate_historys[-30:]

	@classmethod
	def addUnionFragDonateHistoryInMem(cls, historys, role, frag):
		if historys is None:
			historys = []
			logger.warning('historys is None')
		history = {
			'role_id': role.id,
			'name': role.name,
			'logo': role.logo,
			'frame': role.frame,
			'level': role.level,
			'frag': frag,
			'time': int(nowtime_t()),
		}
		historys.append(history)
		historys = historys[-30:]
		return historys

	# 公会碎片赠予热心人点数
	def union_frag_donate_point():
		dbkey = 'union_frag_donate_point'
		def fset(self, value):
			old = self.db[dbkey]
			self.db[dbkey] = value
			if value > old:
				for csvID in csv.union.union_frag_donate_award:
					if csvID not in self.union_frag_donate_awards:
						cfg = csv.union.union_frag_donate_award[csvID]
						if value >= cfg.point:
							self.union_frag_donate_awards[csvID] = 1
		return locals()
	union_frag_donate_point = db_property(**union_frag_donate_point())

	# 公会碎片赠予热心人点数宝箱奖励 {csv_id: flag} (可领:1  已领: 0)
	union_frag_donate_awards = db_property('union_frag_donate_awards')

	# 宝石 [dbID]
	gems = db_property('gems')

	# 芯片 [dbID]
	chips = db_property('chips')

	# 满星技能极限点
	star_skill_points = db_property('star_skill_points')

	def makeWorldBossRankModel(self):
		battleCards = self.huodong_cards.get(WorldBossHuodongID, [])
		return {
			'role': {
				'id': self.id,
				'logo': self.logo,
				'frame': self.frame,
				'title': self.title_id,
				'name': self.name,
				'level': self.level,
				'vip_level': self.vip_level_display,
			},
			'boss_damage': self.game.dailyRecord.boss_damage_max,
			'boss_battle_cards': self.game.cards.getCardsRankModel(battleCards)
		}

	# 1.当玩家造成伤害后，如玩家此时在A公会，那当日只会对A公会生效，若换到B公会，那造成的的伤害不会记录到B公会里。
	# 2.玩家若当日没有公会，但造成伤害，那之后玩家加入到公会里，只会记录到首个进入的公会中，再换公会则和1同理
	# 3.玩家当日造成伤害后，如果退了A换到B再换回A，那之后的伤害还是正常记录在A里
	def getWorldBossUnion(self):
		if not self.union_db_id:
			return None

		if not self.game.dailyRecord.boss_union_db_id:
			self.game.dailyRecord.boss_union_db_id = self.union_db_id

		if self.game.dailyRecord.boss_union_db_id != self.union_db_id:
			return None

		return ObjectUnion.ObjsMap.get(self.union_db_id, None)

	# 跨服竞技场数据 CrossArenaRecord.id
	cross_arena_record_db_id = db_property('cross_arena_record_db_id')

	# 跨服竞技场赛季数据 {stage_awards, seven_award_stage, finish_award_stage, last_display}
	cross_arena_datas = db_property('cross_arena_datas')

	def setCrossAreanStageAwards(self, rank):
		'''
		跨服竞技场段位奖励
		'''
		stageAwards = self.cross_arena_datas.setdefault("stage_awards", {})
		version = ObjectCrossArenaGameGlobal.getVersion(self.areaKey)
		for csvID in ObjectCrossArenaGameGlobal.StageMap[version]:
			cfg = csv.cross.arena.stage[csvID]
			if rank < cfg.range[1]:
				if csvID not in stageAwards:
					stageAwardCsvIDs = ObjectCrossArenaGameGlobal.StageAwardMap[(version, cfg.stageID)]
					# 没有交集
					if not (set(stageAwardCsvIDs) & set(stageAwards.keys())):
						stageAwards[csvID] = CrossArenaDefs.StageAwardOpenFlag
			if rank >= cfg.range[0]:
				break

	# 进化石可转化总次数 {csvID: 次数}
	mega_convert_times = db_property('mega_convert_times')

	# 进化石转化次数 上次恢复时间
	mega_last_date = db_property('mega_last_date')

	def refreshMegaConvertTimes(self):
		'''
		超进化转化次数 每日恢复
		'''
		now = todayinclock5date2int()
		days = (int2date(now) - int2date(self.mega_last_date)).days
		for csvID in csv.card_mega_convert:
			cfg = csv.card_mega_convert[csvID]
			times = self.mega_convert_times.get(csvID, None)
			if times is not None and self.mega_last_date == now:
				continue
			if cfg.type == MegaDefs.MegaCommonItem:
				if times is None:
					self.mega_convert_times[csvID] = ConstDefs.megaCommonRecoveryFirst
				else:
					self.mega_convert_times[csvID] = min(self.megaCommonItemMaxTimes, max(ConstDefs.megaCommonConvertTimes * days + times, 0))
			elif cfg.type == MegaDefs.MegaItem:
				if times is None:
					self.mega_convert_times[csvID] = ConstDefs.megaRecoveryFirst
				else:
					self.mega_convert_times[csvID] = min(self.megaItemMaxTimes, max(ConstDefs.megaConvertTimes * days + times, 0))
		self.mega_last_date = now

	# 实时对战数据 CrossOnlineFightRecord.id
	cross_online_fight_record_db_id = db_property('cross_online_fight_record_db_id')

	# 实时对战公平赛卡牌 [card_id, ]
	cross_online_fight_limited_cards = db_property('cross_online_fight_limited_cards')

	# 实时对战赛季数据 {'start_date', 'unlimited_top_score', 'limited_top_score', 'weekly_date', 'weekly_target'}
	cross_online_fight_info = db_property('cross_online_fight_info')

	# 实时对战商店 {csvid: [count, lastRecoverTime]}
	cross_online_fight_shop = db_property('cross_online_fight_shop')

	# 精英关卡扫荡收藏列表
	mop_up_collection = db_property('mop_up_collection')

	def makeCardFightRoleModel(self):
		ret = self.competitor
		ret['title'] = self.title_id
		return ret

	def makeCardCommentRoleModel(self):
		ret = self.competitor
		ret.pop('figure')
		ret['role_db_id'] = ret.pop('id')
		ret['game_key'] = self.areaKey
		return ret

	# 道馆勋章 {badgeID: {awake: level, talents: {talentID: level}, guards: {guardID: card_db_id}}, positions: {guardID: bool}}
	badges = db_property('badges')

	# 道馆数据 GymRecord.id
	gym_record_db_id = db_property('gym_record_db_id')

	# 道馆相关数据 {gym_fuben, gym_pass_awards, gym_talent_trees, gym_talent_point, last_date, recover_date, last_jump, history_jump, jump}
	gym_datas = db_property('gym_datas')

	@property
	def gym_talent_point(self):
		return self.gym_datas.get('gym_talent_point', 0)

	@property
	def gym_talent_trees(self):
		return self.gym_datas.setdefault('gym_talent_trees', {})

	@property
	def gym_pass_awards(self):
		return self.gym_datas.setdefault('gym_pass_awards', {})

	@property
	def gym_fuben(self):
		return self.gym_datas.setdefault('gym_fuben', {})

	@property
	def gym_talent_reset_times(self):
		return self.gym_datas.setdefault('gym_talent_reset_times', 0)

	@property
	def history_jump(self):
		return self.gym_datas.setdefault('history_jump', {})

	@property
	def last_jump(self):
		return self.gym_datas.setdefault('last_jump', {})

	@property
	def gymTalentPointBuyTimes(self):
		return self._currVIPCsv.gymTalentPointBuyTimes

	@property
	def gymBattleBuyTimes(self):
		return self._currVIPCsv.gymBattleBuyTimes

	def getGymGates(self, gymID):
		return ObjectGymGameGlobal.gymGate(self.areaKey).get(gymID, {})

	# 获取当前道馆副本进度（难度）
	def getCurrentGymDegree(self, gymID):
		return self.gym_fuben.setdefault(gymID, csv.gym.gym[gymID].hardDegreeID[0])  # 没有则默认当前关卡难度为1

	# 获取当前道馆副本关卡
	def getCurrentGymGate(self, gymID):
		degree = self.getCurrentGymDegree(gymID)
		return self.getGymGates(gymID).get(degree, None)

	# 道馆副本是否通关
	def isGymPassed(self, gymID):
		# 有通关奖励
		if gymID in self.gym_pass_awards:
			return True
		gymGates = self.getGymGates(gymID)
		if gymGates:
			return self.getCurrentGymDegree(gymID) > max(gymGates)
		return False

	# 副本是否全通关
	@property
	def isGymAllPass(self):
		return len(self.gym_pass_awards) == len(csv.gym.gym)

	# 重聚活动 db_id
	reunion_record_db_id = db_property('reunion_record_db_id')

	# 重聚活动记录
	reunion = db_property('reunion')

	@property
	def isReunionRoleOpen(self):
		if not self.reunion.get('info', {}).get('yyID', 0) in self.yyOpen:
			return False
		end_time = self.reunion.get('info', {}).get('end_time', 0)
		return nowtime_t() < end_time

	def canReunionCatchUp(self, cfg, times=1):
		'''
		重聚 进度赶超 是否有加成
		'''
		if not cfg:
			return
		record = self.reunion
		catchup = record.setdefault('catchup', {})
		# 天数加成
		if cfg.addType == ReunionDefs.DayCount:
			days = todayinclock5elapsedays(datetimefromtimestamp(record['info']['reunion_time']))
			if days >= cfg.addNum:
				return
			return True
		# 次数加成
		elif cfg.addType == ReunionDefs.TimesCount:
			num = catchup.get(cfg.id, 0)
			if num + times > cfg.addNum:
				return
			return True
		return

	def addReunionCatchUpRecord(self, csvID, times=1):
		'''
		重聚 进度赶超 活动记录
		'''
		record = self.reunion
		catchup = record.setdefault('catchup', {})
		num = catchup.get(csvID, 0)
		catchup[csvID] = num + times

	@property
	def reunionBindRole(self):
		'''
		重聚 绑定对象id
		'''
		if not self.isReunionRoleOpen:
			return

		record = self.reunion
		if record['role_type'] == ReunionDefs.ReunionRole:
			return self.game.reunionRecord.bind_role_db_id
		elif record['role_type'] == ReunionDefs.SeniorRole:
			return record['info']['role_id']

	def sendReunionClosedNoticeMail(self, reunion, endTime):
		'''
		重聚 活动结束通知邮件
		'''
		if not reunion:
			return

		# 绑定对象不是自身时，不发送邮件
		if self.id != reunion.bind_role_db_id:
			return
		cd = reunion.countBindCD()
		self.reunion['bind_cd'] = cd * 24 * 3600 + endTime

		if cd == ConstDefs.shortBindCD:  # 短cd发送邮件
			from game.mailqueue import MailJoinableQueue
			mail = self.makeMyMailModel(ReunionBindCDNoticeMailID, sendTime=endTime, contentArgs=(ConstDefs.shortBindCD, ))
			MailJoinableQueue.send(mail)

	# 预备队伍 {1:{name:string, cards:[dbIDs]}}
	ready_cards = db_property('ready_cards')

	def deployReadyCards(self, idx, cards):
		cards = transform2list(cards)
		if len(cards) != 6:
			raise ClientError(ErrDefs.battleCardCountLimit)
		if self.game.cards.isDuplicateMarkID(cards):
			raise ClientError(ErrDefs.battleCardMarkIDError)
		info = self.ready_cards.setdefault(idx, {'name': '', 'cards': [None, None, None, None, None, None]})
		info["cards"] = cards

	def filterReadyCards(self, cards):
		cards = set(cards)
		for idx, info in self.ready_cards.iteritems():
			valids = []
			hit = False
			v = info.get('cards', [])
			for vv in v:
				if vv in cards:
					valids.append(None)
					hit = True
				else:
					valids.append(vv)
			if hit:
				self.ready_cards[idx]['cards'] = valids

	# 跨服资源战Record数据 CrossMineRecord.id
	cross_mine_record_db_id = db_property('cross_mine_record_db_id')

	# 跨服资源战商店 {csvid: [count, lastRecoverTime]}
	cross_mine_shop = db_property('cross_mine_shop')

	# 日常助手 设置
	daily_assistant = db_property('daily_assistant')

	# 走格子
	grid_walk = db_property('grid_walk')

	def isResetEndless(self):
		'''
		无尽塔是否能重置
		'''
		if self.endless_tower_current == ObjectEndlessTowerGlobal.MinGate:
			return False
		autoReset = self.daily_assistant.get("endless_buy_reset", 0)
		if not autoReset:
			return False
		resetTimes = self.game.dailyRecord.endless_tower_reset_times
		if resetTimes >= self.endlessTowerResetTimes:
			return False
		rmb = ObjectCostCSV.getEndlessTowerResetTimesCost(resetTimes)
		if rmb > 0:
			flags = self.assistant_flags.get(DailyAssistantDefs.Fuben, {})
			if not flags.get(DailyAssistantDefs.Endless, 0):
				return False
			cost = ObjectCostAux(self.game, {'rmb': rmb})
			if not cost.isEnough():
				return False
		return True

	# 勇者挑战BraveChallengeRecord.id
	brave_challenge_record_db_id = db_property("brave_challenge_record_db_id")

	# 普通勇者挑战BraveChallengeRecord.id
	normal_brave_challenge_record_db_id = db_property("normal_brave_challenge_record_db_id")

	# 普通勇者挑战数据
	normal_brave_challenge = db_property("normal_brave_challenge")

	def makeBraveChallengeRankModel(self, data):
		return {
			"role_id": self.id,
			"logo": self.logo,
			"frame": self.frame,
			"name": self.name,
			"level": self.level,
			"game_key": self.areaKey,
			"rank_data": data["rank_data"],  # 通关消耗的最小回合数
			"brave_challenge_rank_info": data["rank_info"],  # 展示数据
		}

	# 远征Record数据 HuntingRecord.id
	hunting_record_db_id = db_property("hunting_record_db_id")

	# 远征商店 {csvid: [count, lastRecoverTime]}
	hunting_shop = db_property("hunting_shop")

	# 芯片方案
	chip_plans = db_property("chip_plans")

	def initChipPlanCache(self):
		self.chip_plan_map = {}
		for idx, plan in self.chip_plans.iteritems():
			if not plan["chips"]:
				continue
			for pos, chipID in plan["chips"].iteritems():
				self.chip_plan_map.setdefault(chipID, []).append([idx, pos])

	# 部屋大作战Record数据 CrossUnionFightRoleRecord.id
	cross_union_fight_record_db_id = db_property("cross_union_fight_record_db_id")

#
# ObjectSignInAwardEffect
#

class ObjectSignInAwardEffect(ObjectGainAux):
	def __init__(self, game, csvid, day, award, multiple=1):
		self.multiple = multiple
		self.csvid = csvid
		self.day = day
		ObjectGainAux.__init__(self, game, award)
		ObjectGainAux.__imul__(self, self.multiple)

	def gain(self, **kwargs):
		ObjectGainAux.gain(self, **kwargs)
		old = self.game.monthlyRecord.sign_in_awards.get(self.day, {}).get(self.csvid, 0)
		self.game.monthlyRecord.sign_in_awards.setdefault(self.day, {})[self.csvid] = old + self.multiple
