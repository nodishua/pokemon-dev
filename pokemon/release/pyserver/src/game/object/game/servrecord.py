#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2014 YouMi Information Technology Inc.
'''

from __future__ import absolute_import

import framework
from framework import todaydate2int, nowtime_t, datetimefromtimestamp, datetime2timestamp, period2date, todayinclock5date2int, weekinclock5date2int, inclock5date, nowdatetime_t, int2date, todayinclock5elapsedays, date2int, OneDay, DailyRefreshHour
from framework.csv import csv, ConstDefs, ErrDefs, MergeServ
from framework.object import ObjectDBase, db_property, ObjectNoGCDBase
from framework.helper import WeightRandomObject
from framework.log import logger

from game import globaldata, ClientError
from game.globaldata import CrossBraveChallengeRanking, CrossHorseRaceRanking, CrossShavedIceRanking, CrossNormalBraveChallengeRanking, NormalBraveChallengePlayID
from game.object import TitleDefs, HuoDongDefs, FeatureDefs, MapDefs
from game.object.game.wmap import ObjectMap
from game.object.game.levelcsv import ObjectFeatureUnlockCSV
from game.session import Session

from tornado.gen import coroutine, Return, sleep

import bisect
import copy
import datetime
import random

#
# ObjectServerGlobalRecord
#

class ObjectServerGlobalRecord(ObjectNoGCDBase):
	'''
	ServerGlobalRecord是公共对象，不进行GC
	'''
	DBModel = 'ServerGlobalRecord'

	Singleton = None

	GateFragmentMap = {}  # {date: {csvID: randomValue}}
	NormalBraveChallengeThemes = [101, 102, 103, 104]

	def __init__(self, dbc):
		ObjectDBase.__init__(self, None, dbc)

		ObjectServerGlobalRecord.Singleton = self
		# ObjectServerGlobalRecord.GateFragmentMap = {}  # {date: {csvID: randomValue}}

	def init(self):
		logger.info('ObjectServerGlobalRecord.half_period_keys %s', self.half_period_keys)

		self.world_level = 0
		self.initHuodongGift()
		self.initHuodongFrag()
		self.initYYHuodongsRedPacket()
		if self.equip_shop_refresh == 0:
			self.equip_shop_refresh = todayinclock5date2int()

		# 称号处理
		if self.title_roles:
			for titleID, titleInfo in self.title_roles.iteritems():
				roleID, openTime = titleInfo
				self.title_roles_info.setdefault(titleID, {})[roleID] = openTime
			self.title_roles = {}

		return ObjectDBase.init(self)

	# key
	key = db_property('key')

	# 战力排行历史 {yyID:[排名缓存]}
	fight_rank_history = db_property('fight_rank_history')

	# 记录运营活动开始日期，只用于3-相对开服日期
	yyhuodongs_open = db_property('yyhuodongs_open')

	# 克隆兽列表
	clone_monsters = db_property('clone_monsters')

	@classmethod
	def getYYHuoDongOpenTime(cls, yyID):
		self = cls.Singleton
		if yyID not in self.yyhuodongs_open:
			return

		return datetimefromtimestamp(self.yyhuodongs_open[yyID])

	@classmethod
	def setYYHuoDongOpenTime(cls, yyID):
		self = cls.Singleton
		if yyID in self.yyhuodongs_open:
			return

		self.yyhuodongs_open[yyID] = nowtime_t()

	@classmethod
	def delYYHuoDongOpenTime(cls, yyID):
		self = cls.Singleton
		if yyID not in self.yyhuodongs_open:
			return

		self.yyhuodongs_open.pop(yyID, None)

	# 玩家称号, 废弃
	title_roles = db_property('title_roles')  # {titleID: [roleID, openTime]}

	# 玩家称号，允许共存
	title_roles_info = db_property('title_roles_info')  # {titleID: {role.id: openTime}}

	# 公会称号
	union_roles = db_property('union_roles')  # {titleID: [unionID, openTime]}

	# 最近更新时间 （不用它）
	last_time = db_property('last_time')

	@classmethod
	def saveTitleRanks(cls, feature, ranks):
		from game.object.game.role import ObjectRole
		from game.object.game import ObjectGame
		# ranks = {roleID: rank}
		titleRanks = cls.getTitleRanks(feature, ranks)

		self = cls.Singleton
		self.checkRoleTitle()  # 清除过期的称号

		date = period2date(TitleDefs.ResetTime[feature])
		openTime = datetime2timestamp(datetime.datetime.combine(date, TitleDefs.ResetTime[feature]))
		for roleID, rank in titleRanks.iteritems():
			titleID = ObjectRole.getRankTtile(feature, rank)
			if titleID:
				self.title_roles_info.setdefault(titleID, {})[roleID] = openTime  # openTime是称号发放时间

		allobjs, safeGuard = ObjectGame.getAll()
		with safeGuard:
			for game in allobjs:
				game.role.refreshRankTitle()

	@classmethod
	def checkRoleTitle(cls):
		# 清除过期的玩家称号记录
		self = cls.Singleton

		for titleID in self.title_roles_info.keys():
			cfg = csv.title[titleID]
			if cfg is None:
				self.title_roles_info.pop(titleID, None)
				continue
			roleInfo = self.title_roles_info[titleID]
			invalidDay = 3600 * 24 * cfg.days
			for roleID in roleInfo.keys():
				invalidTime = invalidDay + roleInfo[roleID]
				if invalidTime <= nowtime_t():  # 已过期
					roleInfo.pop(roleID, None)

	@classmethod
	def getRoleTitle(cls):
		self = cls.Singleton
		return self.title_roles_info

	@classmethod
	def saveTitleUnions(cls, feature, ranks):
		from game.object.game.role import ObjectRole
		from game.object.game import ObjectGame
		# unionRanks / ranks = {unionID: rank}
		unionRanks = cls.getTitleRanks(feature, ranks)

		self = cls.Singleton
		date = period2date(TitleDefs.ResetTime[feature])
		openTime = datetime2timestamp(datetime.datetime.combine(date, TitleDefs.ResetTime[feature]))
		for unionID, rank in unionRanks.iteritems():
			titleID = ObjectRole.getRankTtile(feature, rank)
			if titleID and titleID in ObjectRole.UnionTitles:
				self.union_roles[titleID] = [unionID, openTime]

		allobjs, safeGuard = ObjectGame.getAll()
		with safeGuard:
			for game in allobjs:
				game.role.syncUnionTitle()

	@classmethod
	def getUnionTitle(cls):
		self = cls.Singleton
		return self.union_roles

	@classmethod
	def getTitleRanks(cls, feature, ranks):
		from game.object.game.role import ObjectRole
		maxRank = ObjectRole.getRankTitleMax(feature)
		if maxRank <= 0:
			return
		maxRank = min(10, maxRank)  # 只取前10名
		titleRanks = {vid: rank for vid, rank in ranks.iteritems() if rank <= maxRank}
		return titleRanks

	@classmethod
	def setWorldLevel(cls, level):
		self = cls.Singleton
		if level != self.world_level:
			self.world_level = level
			self.last_time = nowtime_t()

	@classmethod
	def isWorldLevelBonusOpen(cls, game, gateID):
		if not ObjectFeatureUnlockCSV.isOpen(FeatureDefs.WorldLevel, game):
			return False
		isHeroGate = ObjectMap.queryGateType(gateID) == MapDefs.TypeHeroGate
		servOpenDays = csv.world_level.base[1].servOpenDays
		if isHeroGate:
			servOpenDays = csv.world_level.base[2].servOpenDays
		# 相对开服时间
		openDays = todayinclock5elapsedays(globaldata.GameServOpenDatetime) - todayinclock5elapsedays(nowdatetime_t())
		if openDays < servOpenDays - 1:
			return False
		return True

	@classmethod
	@coroutine
	def refreshWorldLevel(cls, dbc):
		from game.object.game.rank import ObjectRankGlobal
		roles = yield ObjectRankGlobal.getRankList('fight', 0, csv.world_level.base[1].topRank)
		level = 0
		if roles:
				level = sum([v['role']['level'] for v in roles]) / len(roles)
		cls.setWorldLevel(level)

	# 活动副本 礼物本的分组
	huodong_gift_group = db_property('huodong_gift_group')  # int

	# 活动副本 礼物本的怪物 免疫类型
	huodong_gift_immune_type = db_property('huodong_gift_immune_type')  # physical:物免:1  special:特免:2

	# 活动副本 碎片本的分组
	huodong_frag_group = db_property('huodong_frag_group')  # int

	# 碎片本 最近一次出现的日期 {csvID: dateint}
	frag_last_date = db_property('frag_last_date')

	@classmethod
	def huodongGiftSwap(cls):
		"""
		礼物本 副本组、免疫类型切换
		"""
		self = cls.Singleton
		if self.huodong_gift_group == HuoDongDefs.huodongGiftGroup1:
			self.huodong_gift_group = HuoDongDefs.huodongGiftGroup2
			self.huodong_gift_immune_type = HuoDongDefs.huodongGiftSpecialImmune
		else:
			self.huodong_gift_group = HuoDongDefs.huodongGiftGroup1
			self.huodong_gift_immune_type = HuoDongDefs.huodongGiftPhysicalImmune

		self.last_time = nowtime_t()

	@classmethod
	def initHuodongGift(cls):
		self = cls.Singleton
		if not self.huodong_gift_group:
			self.huodong_gift_group = HuoDongDefs.huodongGiftGroup1
		if not self.huodong_gift_immune_type:
			self.huodong_gift_immune_type = HuoDongDefs.huodongGiftPhysicalImmune

	@classmethod
	def getHuodongGiftGroup(cls):
		self = cls.Singleton
		return self.huodong_gift_group

	@classmethod
	def randomHuodongFragGroup(cls):
		'''
		根据权值随机碎片副本组  GateFragmentMap {date: {csvID: randomValue}}
		'''
		self = cls.Singleton
		todayDate = inclock5date(nowdatetime_t())
		todayInt = todayDate.isoweekday()
		weights = copy.copy(cls.GateFragmentMap.get(todayInt, {}))
		for csvID, randomValue in weights.items():
			last_date = self.frag_last_date.get(csvID, 0)
			cfg = csv.huodong_gate_fragment[csvID]
			if last_date:
				if (todayDate - int2date(last_date)).days <= cfg.cd:
					weights.pop(csvID)

		if weights:
			fragGroup, _ = WeightRandomObject.onceRandom(weights)

			self.huodong_frag_group = fragGroup
			self.last_time = nowtime_t()
			self.frag_last_date[fragGroup] = date2int(todayDate)

			logger.info('huodong_frag refresh group %d in %d', fragGroup, date2int(todayDate))
		else:
			logger.warning('huodong_frag refresh error in %d', date2int(todayDate))

	@classmethod
	def initHuodongFrag(cls):
		self = cls.Singleton
		cls.GateFragmentMap = {}
		for j in xrange(7):
			value = {}
			for i in csv.huodong_gate_fragment:
				cfg = csv.huodong_gate_fragment[i]
				if not cfg.date or j + 1 in cfg.date:
					value[cfg.id] = cfg.randomValue
			cls.GateFragmentMap.setdefault(j + 1, value)
		if not self.huodong_frag_group:
			self.randomHuodongFragGroup()

	@classmethod
	def getHuodongFragGroup(cls):
		self = cls.Singleton
		return self.huodong_frag_group

	# 饰品抽卡商店刷新时间
	equip_shop_refresh = db_property('equip_shop_refresh')

	@classmethod
	def isEquipShopPass(cls, lasttime):
		self = cls.Singleton
		delta = (int2date(todayinclock5date2int()) - int2date(self.equip_shop_refresh)).days
		if delta >= ConstDefs.equipShopRefreshDays:
			self.equip_shop_refresh = todayinclock5date2int()

		lastdt = datetimefromtimestamp(lasttime)
		return date2int(lastdt) < self.equip_shop_refresh

	@classmethod
	def modelSync(cls, lastTime):
		self = cls.Singleton
		if self.last_time > lastTime + 0.1:
			return {
				'last_time': self.last_time,
				'huodong_gift_group': self.huodong_gift_group,
				'huodong_gift_immune_type': self.huodong_gift_immune_type,
				'huodong_frag_group': self.huodong_frag_group,
				'equip_shop_refresh': self.equip_shop_refresh,
				'frag_last_date': self.frag_last_date,
				'world_level': self.world_level,
				"unionqa_round": self.unionqa_round,
				"normal_brave_challenge": self.normal_brave_challenge,
			}
		return {}

	# 运营活动红包
	yyhuodongs_redPacket = db_property('yyhuodongs_redPacket')

	@classmethod
	def initYYHuodongsRedPacket(cls):
		self = cls.Singleton
		self.YYHuoDongRedPacketNoRemain = []
		if self.yyhuodongs_redPacket:
			self.YYHuoDongRedPacketCount = max(self.yyhuodongs_redPacket.keys())
			for idx, info in self.yyhuodongs_redPacket.iteritems():
				if len(info['members']) >= info['total_count']:
					self.YYHuoDongRedPacketNoRemain.append(idx)
		else:
			self.YYHuoDongRedPacketCount = 0

	@classmethod
	def clearYYHuoDongRedPacket(cls):
		self = cls.Singleton
		self.yyhuodongs_redPacket = {}

	@classmethod
	def getYYHuoDongRedPackets(cls):
		self = cls.Singleton
		return self.yyhuodongs_redPacket.values()

	@classmethod
	def popYYHuoDongRedPacket(cls, idx):
		self = cls.Singleton
		self.yyhuodongs_redPacket.pop(idx, None)

	@classmethod
	def refreshYYHuoDongRedPacket(cls):
		self = cls.Singleton
		count = len(self.yyhuodongs_redPacket) - 50
		if count > 0 and len(self.YYHuoDongRedPacketNoRemain) > 0:
			ids = self.YYHuoDongRedPacketNoRemain[:count]
			for idx in ids:
				cls.popYYHuoDongRedPacket(idx)
			self.YYHuoDongRedPacketNoRemain = self.YYHuoDongRedPacketNoRemain[count:]

	@classmethod
	def sendMyYYHuoDongRedPacket(cls, game, totalVal, totalCount, message):
		self = cls.Singleton
		self.YYHuoDongRedPacketCount += 1
		idx = self.YYHuoDongRedPacketCount
		model = {
			'idx': idx,
			'created_time' : nowtime_t(),
			'role_id': game.role.id,
			'role_name': game.role.name,
			'role_logo': game.role.logo,
			'role_frame': game.role.frame,
			'total_val': totalVal,
			'total_count': totalCount,
			'message': message,
			'members': {},
		}
		self.yyhuodongs_redPacket[idx] = model
		return idx

	@classmethod
	def robYYHuoDongRedPacket(cls, game, idx):
		self = cls.Singleton
		if idx not in self.yyhuodongs_redPacket:
			raise ClientError(ErrDefs.redPacketNoRemain)
		info = self.yyhuodongs_redPacket[idx]
		role = game.role
		if role.id in info['members']:
			raise ClientError(ErrDefs.redPacketAlreadyRob)
		usedCount = len(info['members'])
		if usedCount >= info['total_count']:
			raise ClientError(ErrDefs.redPacketNoRemain)
		usedVal = sum([v['val'] for v in info['members'].values()])
		remainCount = info['total_count'] - usedCount
		if remainCount == 1:
			val = info['total_val'] - usedVal
		else:
			right = int((info['total_val'] - usedVal - remainCount) * 2 / remainCount)
			val = random.randint(1, max(1, right))
		val = max(int(val), 1)

		# insert to members
		member = {
			'id': role.id,
			'logo': role.logo,
			'name': role.name,
			'vip': role.vip_level_display,
			'frame': role.frame,
			'val': val,
			'union': game.union.name if game.union else '',
		}
		info['members'][role.id] = member

		if len(info['members']) >= info['total_count']:
			self.YYHuoDongRedPacketNoRemain.append(idx)

		return info, val

	# 活动Boss跨服server key
	huodongboss_cross_key = db_property('huodongboss_cross_key')

	@classmethod
	@coroutine
	def onHuoDongBossEvent(cls, event, key, data, sync):
		'''
		玩法流程
		'''
		logger.info('HuoDongBoss.onHuoDongBossEvent %s %s', key, event)

		self = cls.Singleton

		ret = {}
		if event == 'closed':
			logger.info('HuoDongBoss.onClosed')
			self.huodongboss_cross_key = ''

		raise Return(ret)

	@classmethod
	@coroutine
	def onCrossCommit(cls, key, transaction):
		'''
		活动Boss跨服启动commit
		'''
		logger.info('HuoDongBoss.onCrossCommit %s %s', key, transaction)

		self = cls.Singleton
		# 玩法已经被占用
		if self.huodongboss_cross_key != '' and self.huodongboss_cross_key != key:
			logger.warning('HuoDongBoss.onCrossCommit %s', self.huodongboss_cross_key)
			raise Return(False)

		self.huodongboss_cross_key = key
		raise Return(True)

	@classmethod
	def huodongboss_cross_client(cls, cross_key=None):
		if cross_key is None:
			cross_key = cls.Singleton.huodongboss_cross_key
		if cross_key == '':
			return None
		from game.server import Server
		container = Server.Singleton.container
		client = container.getserviceOrCreate(cross_key)
		return client

	yyHuodong_double11_Lottery_info = db_property('yyHuodong_double11_Lottery_info')

	@classmethod
	def setYYHuodongDouble11LotteryInfo(cls, yyID, gameCsvIDs, lotteryCsvIDs, numPond):
		self = cls.Singleton

		info = self.yyHuodong_double11_Lottery_info.setdefault(yyID, {})

		ret = {}
		lotteryCount = len(lotteryCsvIDs)
		for gameCsvID in gameCsvIDs:
			needSet = False

			# 之前没设置过
			if gameCsvID not in info:
				needSet = True

			# 改了配表
			elif set(info[gameCsvID]) != set(lotteryCsvIDs):
				needSet = True

			if needSet:
				info[gameCsvID] = {}
				randNums = random.sample(numPond, lotteryCount)
				for i, lotteryCsvID in enumerate(lotteryCsvIDs):
					info[gameCsvID][lotteryCsvID] = randNums[i]

			ret[gameCsvID] = info[gameCsvID]

		return ret


	# 用于判断是否处于半周期，合服用
	half_period_keys = db_property('half_period_keys')

	@classmethod
	def isHalfPeriod(cls, service, areaKey):
		'''
		判断玩法是否处于合服的半周期内
		cross_craft, cross_arena, cross_fishing, cross_online_fight
		'''
		self = cls.Singleton
		v = self.half_period_keys.get(service, None)
		if v:
			return areaKey in v
		return False

	@classmethod
	def overHalfPeroid(cls, service, areaKey):
		'''
		结束合服时玩法的半周期
		'''
		self = cls.Singleton
		v = self.half_period_keys.get(service, None)
		if not v:
			return
		v = filter(lambda x: x != areaKey, v)
		self.half_period_keys[service] = v
		if len(self.half_period_keys[service]) == 0:
			self.half_period_keys.pop(service, None)
		logger.info('ObjectServerGlobalRecord.overHalfPeroid %s %s %s', service, areaKey, self.half_period_keys)

	# 公会问答跨服server key
	unionqa_cross_key = db_property("unionqa_cross_key")

	# 公会问答 round
	unionqa_round = db_property("unionqa_round")

	# 公会问答 上期跨服server key
	unionqa_last_cross_key = db_property("unionqa_last_cross_key")

	@classmethod
	@coroutine
	def onCrossUnionQAEvent(cls, event, key, data, sync):
		'''
		玩法流程
		'''
		logger.info("CrossUnionQA.onCrossUnionQAEvent %s %s", key, event)

		self = cls.Singleton

		ret = {}
		if event == "start":
			logger.info("CrossUnionQA.onStart")
			self.unionqa_round = "start"
			self.unionqa_last_cross_key = ""
		elif event == "closed":
			logger.info("CrossUnionQA.onClosed")
			self.unionqa_round = "closed"
			self.onUnionQAClosed(data.get("model", {}))
		elif event == "rank_award":
			logger.info("CrossUnionQA.onRankAward")
			roleRanks = data.get("role_ranks", [])
			unionRanks = data.get("union_ranks", [])
			cls.onUnionQARankAward(roleRanks, unionRanks)
		raise Return(ret)

	@classmethod
	@coroutine
	def onCrossUnionQACommit(cls, key, transaction):
		'''
		CrossUnionQA启动commit
		'''
		logger.info('CrossUnionQA.onCrossCommit %s %s', key, transaction)

		self = cls.Singleton
		# 玩法已经被占用
		if self.unionqa_cross_key != '' and self.unionqa_cross_key != key:
			logger.warning('CrossUnionQA.onCrossUnionQACommit %s', self.unionqa_cross_key)
			raise Return(False)

		self.unionqa_cross_key = key
		raise Return(True)

	@classmethod
	def isUnionQAStarted(cls):
		self = cls.Singleton
		return self.unionqa_round == "start"

	@classmethod
	def unionqa_cross_client(cls, cross_key=None):
		if cross_key is None:
			cross_key = cls.Singleton.unionqa_cross_key
		if cross_key == "" and cls.Singleton.unionqa_last_cross_key:
			cross_key = cls.Singleton.unionqa_last_cross_key
		if cross_key == "":
			return None
		from game.server import Server
		container = Server.Singleton.container
		client = container.getserviceOrCreate(cross_key)
		return client

	@classmethod
	@coroutine
	def onUnionQAClosed(cls, data):
		self = cls.Singleton
		self.unionqa_round = "closed"
		self.unionqa_last_cross_key = data.get("key", "")
		self.unionqa_cross_key = ""

	@classmethod
	def onUnionQARankAward(cls, roleRanks, unionRanks):
		from game.mailqueue import MailJoinableQueue
		from game.object.game.role import ObjectRole
		from game.object.game.union import ObjectUnion
		from game.globaldata import UnionQARoleRankAwardMailID, UnionQAUnionRankAwardMailID

		logger.info('ObjectCrossUnionQAGameGlobal.onRankAward role.rank %s', len(roleRanks))

		roleCfgs = []
		roleCfgRanks = []
		for idx in sorted(csv.cross.union_qa.role_rank.keys()):
			cfg = csv.cross.union_qa.role_rank[idx]
			roleCfgs.append(cfg)
			roleCfgRanks.append(cfg.rankMax)

		for info in roleRanks:
			rank = info["rank"]
			idx = bisect.bisect_left(roleCfgRanks, rank)
			cfg = roleCfgs[idx]
			if rank <= cfg.rankMax:
				mail = ObjectRole.makeMailModel(info["role_db_id"], UnionQARoleRankAwardMailID, contentArgs=rank, attachs=cfg.award)
				MailJoinableQueue.send(mail)
			if rank in set([1, 2, 3]):
				cls.saveTitleRanks(TitleDefs.UnionQARole, {info["role_db_id"]: rank})

		logger.info('ObjectCrossUnionQAGameGlobal.onRankAward union.rank %s', len(unionRanks))

		unionCfgs = []
		unionCfgRanks = []
		for idx in sorted(csv.cross.union_qa.union_rank.keys()):
			cfg = csv.cross.union_qa.union_rank[idx]
			unionCfgs.append(cfg)
			unionCfgRanks.append(cfg.rankMax)

		for info in unionRanks:
			rank = info["rank"]
			idx = bisect.bisect_left(unionCfgRanks, rank)
			cfg = unionCfgs[idx]
			if info["rank"] <= cfg.rankMax:
				union = ObjectUnion.getUnionByUnionID(info["id"])
				if union:
					for roleID in union.members:
						mail = ObjectRole.makeMailModel(roleID, UnionQAUnionRankAwardMailID, contentArgs=rank, attachs=cfg.award)
						MailJoinableQueue.send(mail)
					if rank == 1:
						cls.saveTitleUnions(TitleDefs.UnionQAUnion, {info["id"]: info["rank"]})


	# 跨服红包corss_key
	redpacket_cross_key = db_property('redpacket_cross_key')

	@classmethod
	@coroutine
	def onHuoDongCrossRedPacketEvent(cls, event, key, data, sync):
		'''
		玩法流程
		'''
		logger.info('CrossRedPacket.onHuoDongCrossRedPacketEvent %s %s', key, event)

		self = cls.Singleton
		ret = {}
		if event == 'closed':
			logger.info('CrossRedPacket.onClosed')
			self.redpacket_cross_key = ''

		raise Return(ret)

	@classmethod
	@coroutine
	def onHuoDongCrossRedPacketCommit(cls, key, transaction):
		'''
		跨服红包跨服启动commit
		'''
		logger.info('CrossRedPacket.onHuoDongCrossRedPacketCommit %s %s', key, transaction)

		self = cls.Singleton
		# 玩法已经被占用
		if self.redpacket_cross_key != '' and self.redpacket_cross_key != key:
			logger.warning('CrossRedPacket.onHuoDongCrossRedPacketCommit %s', self.redpacket_cross_key)
			raise Return(False)

		self.redpacket_cross_key = key
		raise Return(True)

	@classmethod
	def redpacket_cross_client(cls, cross_key=None):
		if cross_key is None:
			cross_key = cls.Singleton.redpacket_cross_key
		if cross_key == '':
			return None
		from game.server import Server
		container = Server.Singleton.container
		client = container.getserviceOrCreate(cross_key)
		return client

	@classmethod
	@coroutine
	def getYYHuoDongCrossRedPackets(cls, game):
		rpc = cls.redpacket_cross_client()
		if not rpc:
			raise ClientError(ErrDefs.huodongNoOpen)

		redPacketInfoList = yield rpc.call_async('CrossRedPacketList', game.role.areaKey)
		raise Return(redPacketInfoList)

	@classmethod
	@coroutine
	def sendMyYYHuoDongCrossRedPacket(cls, game, totalVal, totalCount, message):
		rpc = cls.redpacket_cross_client()
		if not rpc:
			raise ClientError(ErrDefs.huodongNoOpen)
		role = game.role
		model = {
			'game_key': role.areaKey,
			'created_time': int(nowtime_t()),
			'role_id': role.id,
			'role_name': role.name,
			'role_logo': role.logo,
			'role_frame': role.frame,
			'total_val': totalVal,
			'total_count': totalCount,
			'message': message,
			'members': {},
		}
		resp = yield rpc.call_async('CrossRedPacketSend', role.areaKey, model)
		raise Return((resp['idx'], resp['red_packet_list']))

	@classmethod
	@coroutine
	def robYYHuoDongCrossRedPacket(cls, game, idx):
		rpc = cls.redpacket_cross_client()
		if not rpc:
			raise ClientError(ErrDefs.huodongNoOpen)
		role = game.role
		member = {
			'id': role.id,
			'game_key': role.areaKey,
			'logo': role.logo,
			'name': role.name,
			'vip': role.vip_level_display,
			'frame': role.frame,
			'union': game.union.name if game.union else '',
		}
		resp = yield rpc.call_async('CrossRedPacketRob', role.areaKey, idx, member)
		raise Return((resp['info'], resp['val'], resp['red_packet_list']))

	# 跨服摩天大楼cross_key
	skyscraper_cross_key = db_property('skyscraper_cross_key')

	@classmethod
	@coroutine
	def onHuoDongCrossSkyscraperEvent(cls, event, key):
		'''
		玩法流程
		'''
		logger.info('CrossSkyscraper.onHuoDongCrossSkyscraperEvent %s %s', key, event)

		self = cls.Singleton
		ret = {}
		if event == 'closed':
			logger.info('CrossSkyscraper.onClosed')
			self.skyscraper_cross_key = ''

		raise Return(ret)

	@classmethod
	@coroutine
	def onHuoDongCrossSkyscraperCommit(cls, key, transaction):
		'''
		跨服摩天大楼跨服启动commit
		'''
		logger.info('CrossSkyscraper.onHuoDongCrossSkyscraperCommit %s %s', key, transaction)

		self = cls.Singleton
		# 玩法已经被占用
		if self.skyscraper_cross_key != '' and self.skyscraper_cross_key != key:
			logger.warning('CrossSkyscraper.onHuoDongCrossSkyscraperCommit %s', self.skyscraper_cross_key)
			raise Return(False)

		self.skyscraper_cross_key = key
		raise Return(True)

	@classmethod
	def skyscraper_cross_client(cls, cross_key=None):
		if cross_key is None:
			cross_key = cls.Singleton.skyscraper_cross_key
		if cross_key == '':
			return None
		from game.server import Server
		container = Server.Singleton.container
		client = container.getserviceOrCreate(cross_key)
		return client

	@classmethod
	@coroutine
	def getYYHuoDongCrossSkyscraperRanking(cls, game):
		'返回我的排名和排行榜'
		rpc = cls.skyscraper_cross_client()
		if not rpc:
			raise ClientError(ErrDefs.huodongNoOpen)

		ret = yield rpc.call_async('GetSkyscraperRanking', game.role.areaKey, game.role.id, 100)  # 拿前一百排行榜
		raise Return((ret['rank'], ret['ranking']))

	@classmethod
	@coroutine
	def sendYYHuoDongCrossSkyscraperInfo(cls, game, medallvl, highScore, highFloor):
		rpc = cls.skyscraper_cross_client()
		if not rpc:
			raise ClientError(ErrDefs.huodongNoOpen)
		role = game.role
		model = {
			'role_id': role.id,
			'logo': role.logo,
			'frame': role.frame,
			'name': role.name,
			'level': role.level,
			'game_key': role.areaKey,
			'medallvl': medallvl,
			'high_score': highScore,
			'high_floor': highFloor,
		}
		resp = yield rpc.call_async('SendSkyscraperInfo', game.role.areaKey, model)
		raise Return(resp)

	# 赛马 cross_key
	horse_race_cross_key = db_property('horse_race_cross_key')

	@classmethod
	def setHorseRaceCrossKey(cls, key):
		cls.Singleton.horse_race_cross_key = key

	@classmethod
	def horse_race_cross_client(cls):
		return cls.cross_client(cls.Singleton.horse_race_cross_key)

	@classmethod
	@coroutine
	def onCrossHorseRaceCommit(cls, key, transaction):
		'''
		赛马跨服启动commit
		'''
		logger.info('CrossHorseRace.onCrossHorseRaceCommit %s %s', key, transaction)

		self = cls.Singleton
		# 玩法已经被占用
		if self.horse_race_cross_key != '' and self.horse_race_cross_key != key:
			logger.warning('CrossHorseRace.onCrossHorseRaceCommit %s', self.horse_race_cross_key)
			raise Return(False)

		self.horse_race_cross_key = key
		raise Return(True)

	@classmethod
	def cross_client(cls, key):
		if key == '':
			return None
		from game.server import Server
		container = Server.Singleton.container
		client = container.getserviceOrCreate(key)
		return client

	play_ranking_cross_keys = db_property('play_ranking_cross_keys')

	@classmethod
	@coroutine
	def onCrossRankingCommit(cls, key, transaction):
		logger.info('onCrossRankingCommit %s %s', key, transaction)

		self = cls.Singleton
		if transaction in self.play_ranking_cross_keys:
			if self.play_ranking_cross_keys[transaction] != '' and self.play_ranking_cross_keys[transaction] != key:
				# 玩法已经被占用
				logger.warning('onCrossRankingCommit %s', self.play_ranking_cross_keys[transaction])
				raise Return(False)
		self.play_ranking_cross_keys[transaction] = key
		raise Return(True)

	@classmethod
	@coroutine
	def onCrossRankingEvent(cls, play, event, key):
		logger.info('onCrossRankingEvent %s %s %s', play, key, event)
		self = cls.Singleton
		ret = {}
		if event == 'closed':
			self.play_ranking_cross_keys.pop(play, None)

		raise Return(ret)

	@classmethod
	def crossRankingClient(cls, gamePlay):
		rpcClient = None
		if cls.Singleton.play_ranking_cross_keys.get(gamePlay, ''):
			return cls.cross_client(cls.Singleton.play_ranking_cross_keys[gamePlay])
		return rpcClient

	@classmethod
	@coroutine
	def sendRankingInfo(cls, game, gamePlay, model):
		rpc = cls.crossRankingClient(gamePlay)
		if not rpc:
			raise ClientError(ErrDefs.huodongNoOpen)
		resp = yield rpc.call_async('RankingSendInfo', game.role.areaKey, gamePlay, model)
		raise Return(resp)

	@classmethod
	@coroutine
	def getRankingInfo(cls, game, gamePlay, size=100):
		rpc = cls.crossRankingClient(gamePlay)
		if not rpc:
			raise ClientError(ErrDefs.huodongNoOpen)

		ret = yield rpc.call_async('RankingGet', game.role.areaKey, gamePlay, game.role.id, size)
		raise Return(ret)

	@classmethod
	@coroutine
	def clearRankingInfo(cls, gamePlay):
		rpc = cls.crossRankingClient(gamePlay)
		if not rpc:
			raise Return(False)

		from game.server import Server
		for areaKey in MergeServ.getSrcServKeys(Server.Singleton.key):
			yield rpc.call_async('RankingClear', areaKey, gamePlay)
		raise Return(True)

	# {'refreshTime':0, 'startTime': 0, 'baseCfgID':1, 'endTime': 0}
	normal_brave_challenge = db_property('normal_brave_challenge')

	@classmethod
	def refreshNormalBraveChallenge(cls):
		from game.object.game.yyhuodong import ObjectYYBraveChallenge
		self = cls.Singleton
		self.last_time = nowtime_t()
		ndi = todayinclock5date2int()
		startTime = ObjectYYBraveChallenge.OpenTime.get(framework.__language__, 0)
		if startTime and ndi >= startTime and ndi != self.normal_brave_challenge.get('refreshTime', None):
			startTime = datetime.datetime.combine(
				int2date(startTime),
				globaldata.DailyRecordRefreshTime
			)
			days = todayinclock5elapsedays(startTime) + 1
			if days <= 0:
				return 0
			# 获取今天日期
			nowTime = nowdatetime_t()
			# 获取今天周几
			wday = nowTime.isoweekday()
			# 获取相对起始日期是第几周
			weekCount = days / 7
			if wday != 7:
				weekCount += 1

			round = weekCount % 12
			if round == 0:
				round = 12
			themeidx = round / 3 if round % 3 == 0 else round / 3 + 1
			# 获取当周是哪个主题
			theme = self.NormalBraveChallengeThemes[themeidx-1]
			# 获取主题应当的开关状态
			themeStatus = 3 if round % 3 == 0 else round % 3
			if wday == 1 and nowTime.hour >= DailyRefreshHour:  # 周一刷新点触发
				if themeStatus == 1:  # 新主题开放
					self.normal_brave_challenge['startTime'] = ndi
					self.normal_brave_challenge['endTime'] = date2int(nowTime + OneDay*14)
					self.normal_brave_challenge['baseCfgID'] = theme
					# 重置排行榜
					cls.clearRankingInfo(CrossNormalBraveChallengeRanking)
					# 通知cross重新初始化玩法数据
					Session.startBraveChallengeYYActive(NormalBraveChallengePlayID)
				elif themeStatus == 3:  # 关闭活动
					self.normal_brave_challenge['startTime'] = 0

			self.normal_brave_challenge['refreshTime'] = ndi
		return self.normal_brave_challenge.get('startTime', 0)
