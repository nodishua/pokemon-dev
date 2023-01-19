#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2014 YouMi Information Technology Inc.
'''

from framework import str2num_t, DailyRefreshHour
from framework import weekinclock5date2int, todayinclock5date2int, nowtime_t, nowdatetime_t, datetimefromtimestamp, datetime2timestamp, inclock5date, date2int, OneDay
from framework.csv import csv, ConstDefs
from framework.log import logger
from framework.helper import WeightRandomObject
from framework.object import ObjectDBase, db_property
from game import ClientError
from game.object import FeatureDefs, TargetDefs
from game.object.game.levelcsv import ObjectFeatureUnlockCSV
from game.object.game.yyhuodong import ObjectYYHuoDongFactory
from game.object.game.calculator import zeros
from game.object.game.gain import ObjectGainAux, ObjectCostAux, ObjectGainEffect, pack, unpack
from game.object.game.cross_fishing import ObjectCrossFishingGameGlobal

import random
import copy
import datetime
import math
from collections import defaultdict

#
# ObjectFishing
#

class ObjectFishing(ObjectDBase):
	DBModel = 'Fishing'

	levelMax = 0
	SceneFishMap = {}
	BaitRareMap = defaultdict(list)
	AutoFishingDuration = 0  # 自动钓鱼每个多少时间触发一次，策划配置
	BigFishPointUp = 0.1 # 大鱼积分加成 10%

	LowRare = 1 # 低级鱼
	MiddleRare = 2 # 中级鱼
	HighRare = 3 # 高级鱼

	NormalSceneType = 1 # 普通场景
	PlaySceneType = 2 # 钓鱼大赛场景

	@classmethod
	def classInit(cls):
		cls.AutoFishingDuration = ConstDefs.fishingAutoDuration
		cls.levelMax = len(csv.fishing.level)

		cls.SceneFishMap = {}
		for csvID in csv.fishing.scene:
			cls.SceneFishMap[csvID] = []
		for csvID in csv.fishing.fish:
			cfg = csv.fishing.fish[csvID]
			# 没有配置默认所有场景都可以出现
			if not cfg.scene:
				for sceneID in cls.SceneFishMap.iterkeys():
					cls.SceneFishMap[sceneID].append(cfg)
			else:
				for sceneID in cfg.scene:
					cls.SceneFishMap[sceneID].append(cfg)

		cls.BaitRareMap = defaultdict(list)
		for csvID in csv.fishing.bait:
			cfg = csv.fishing.bait[csvID]
			cls.BaitRareMap[cfg.rare].append(cfg)
		for rare in cls.BaitRareMap:
			cls.BaitRareMap[rare] = sorted(cls.BaitRareMap[rare], key=lambda x: x.id)

	def init(self):
		self.fishingCsvID = None  # 正在钓鱼的 csvID
		self.fishingDoing = False  # 是否操作过钓鱼
		self.fishingOperateStartTime = 0 # 开始钓鱼操作的时间
		self.pointUpd = False # 积分变动
		return ObjectDBase.init(self)

	# 钓鱼等级
	def level():
		dbkey = 'level'
		def fset(self, value):
			old = self.db[dbkey]
			value = min(value, self.levelMax)

			if old != value:
				self.db[dbkey] = value
				self.onLevelUp()
		return locals()
	level = db_property(**level())

	# 钓到过的鱼
	fish = db_property('fish')

	# 解锁的伙伴
	partner = db_property('partner')

	# 历史最大长度
	length_max = db_property('length_max')

	# 选择的场景
	select_scene = db_property('select_scene')

	# 选择的鱼竿
	select_rod = db_property('select_rod')

	# 选择的鱼饵
	select_bait = db_property('select_bait')

	# 选择的伙伴
	select_partner = db_property('select_partner')

	# 普通鱼计数
	fish_counter = db_property('fish_counter')

	# 目标鱼计数器
	target_counter = db_property('target_counter')

	# 是否自动
	is_auto = db_property('is_auto')

	# 自动钓鱼是否已经停止
	auto_stopped = db_property('auto_stopped')

	# 开始自动钓鱼的时间
	auto_start_time = db_property('auto_start_time')

	# 剩余可以自动钓鱼的次数
	auto_last_times = db_property('auto_last_times')

	# 自动钓鱼成功次数
	auto_win_counter = db_property('auto_win_counter')

	# 自动钓鱼失败次数
	auto_fail_counter = db_property('auto_fail_counter')

	# 自动钓鱼使用的时间
	auto_used_time = db_property('auto_used_time')

	# 自动钓鱼奖励
	auto_award = db_property('auto_award')

	# 权值记录
	weight_record = db_property('weight_record')

	# 最后一次操作周
	last_week = db_property('last_week')

	# 每周鱼出现次数
	week_record = db_property('week_record')

	# 最后参加钓鱼大赛日期
	last_play_date = db_property('last_play_date')

	# 钓鱼大赛积分
	point = db_property('point')

	# 钓鱼大赛特殊鱼数量
	special_fish_num = db_property('special_fish_num')

	@property
	def rodItemID(self):
		return csv.fishing.rod[self.select_rod].itemId

	@property
	def baitItemID(self):
		return csv.fishing.bait[self.select_bait].itemId

	def fishCount(self, fishType=None):
		for fishID in self.fish.keys():
			if fishID not in csv.fishing.fish:
				self.fish.pop(fishID, None)

		fish_count = 0
		for fishID, record in self.fish.iteritems():
			cfg = csv.fishing.fish[fishID]
			# 不传fishType返回全部类型鱼钓到的数量
			if fishType and fishType != cfg.type:
				continue
			fish_count += record.get('counter', 0)
		return fish_count

	def getFishingLevelAttrs(self):
		'''
		钓鱼等级 属性加成
		'''
		const = zeros()
		percent = zeros()
		cfg = csv.fishing.level[self.level]
		for j in xrange(1, 99):
			attrTypeKey = 'attrType%d' % j
			if attrTypeKey not in cfg or not cfg[attrTypeKey]:
				break
			attrType = cfg[attrTypeKey]
			attrNum = cfg['attrNum%d' % j]
			num = str2num_t(attrNum)
			const[attrType] += num[0]
			percent[attrType] += num[1]
		return const, percent

	def onLevelUp(self):
		if ObjectFeatureUnlockCSV.isOpen(FeatureDefs.Fishing, self.game):
			cards = self.game.cards.getAllCards()
			for _, card in cards.iteritems():
				card.calcFishingLevelAttrsAddition(card, self.game)
				card.onUpdateAttrs()

	def fishingLevelUp(self):
		level = self.level
		if level == self.levelMax:
			return
		cfg = csv.fishing.level[level]
		if cfg.lowNum > self.fish_counter.get(self.LowRare, 0):
			return
		if cfg.middleNum > self.fish_counter.get(self.MiddleRare, 0):
			return
		if cfg.highNum > self.fish_counter.get(self.HighRare, 0):
			return
		if cfg.totalNum > sum(self.fish_counter.values()):
			return
		if cfg.targetNum:
			for _, num in cfg.targetNum.items():
				if num > self.target_counter:
					return

		# 重置钓鱼计数
		self.fish_counter = {}
		self.target_counter = 0

		self.level += 1

	def checkPrepare(self):
		if self.game.dailyRecord.fishing_counter >= ConstDefs.fishingDailyTimes:
			raise ClientError('fishing times is not enough')

		if self.select_scene <= 0:
			raise ClientError('not select scenes')

		sceneCfg = csv.fishing.scene[self.select_scene]
		if not sceneCfg:
			raise ClientError('scene id error')

		if sceneCfg.type == self.PlaySceneType and not ObjectCrossFishingGameGlobal.isOpen(self.game.role.areaKey):
			raise ClientError('fishing play not open')

		if self.select_rod <= 0:
			raise ClientError('not select rod')

		# 是否解锁选择的鱼竿
		if not self.game.items.isEnough({self.rodItemID: 1}):
			raise ClientError('rod not unlock')

		if self.select_bait <= 0:
			raise ClientError('not select bait')

		baitCfg = csv.fishing.bait[self.select_bait]
		if not self.game.items.isEnough({baitCfg.itemId: 1}):
			raise ClientError('bait is not enough')

		# 是否有场景限制
		if baitCfg.scene and self.select_scene not in baitCfg.scene:
			raise ClientError('can not use bait in scene')

		# 重置积分
		if ObjectCrossFishingGameGlobal.isOpen(self.game.role.areaKey):
			playDate = ObjectCrossFishingGameGlobal.getDate(self.game.role.areaKey)
			if self.last_play_date != playDate:
				self.point = 0
				self.special_fish_num = 0
				self.last_play_date = playDate

	def fishingStart(self):
		weights = {}  # 普通鱼权重
		specialFishes = []  # 特殊鱼权重
		baitCfg = csv.fishing.bait[self.select_bait]
		isPlayScene = csv.fishing.scene[self.select_scene].type == self.PlaySceneType
		for cfg in self.SceneFishMap[self.select_scene]:
			# 最大成功钓鱼次数，默认 -1 表示不限制次数
			if cfg.maxWinTimes > 0 and self.fish.get(cfg.id, {}).get('counter', 0) >=  cfg.maxWinTimes:
				continue
			# 等级不足，默认 0 表示不限制等级
			if cfg.needLv > 0 and self.level < cfg.needLv:
				continue
			# 鱼饵限制，默认空表示没有限制
			if cfg.bait and self.select_bait not in cfg.bait:
				continue
			# 每周出现次数限制，默认 -1 表示没有限制
			if cfg.weekMax != -1 and self.week_record.get(cfg.id, 0) >= cfg.weekMax:
				continue
			# 特殊权值额外处理
			if cfg.randType == 2:
				if self.weight_record.get(cfg.id, 0) >= 1:
					specialFishes.append([cfg.id, cfg.priority, cfg.overDeal])
				continue

			# 钓鱼大赛权值特殊取值
			baseWeight = cfg.crossFishingWeight if isPlayScene else cfg.weight
			if baseWeight <= 0:
				continue

			# 添加权值看下鱼饵是否有额外加成，策划确认：向下取整
			weights[cfg.id] = int(math.floor(baseWeight * baitCfg.extraRate.get(cfg.id, 1)))

		fishID = None
		# 特殊鱼
		if len(specialFishes) > 0:
			specialFishes = sorted(specialFishes, key=lambda x: x[1])
			fishID, _, _ = specialFishes.pop()
			self.weight_record.pop(fishID, None)

			# 处理没有触发的权重
			for csvID, _, overDeal in specialFishes:
				# 1 保留
				# 2 清空
				# 3 权值 -20% （策划确认：直接减 0.2）
				if overDeal == 2:
					self.weight_record[csvID] = 0
				if overDeal == 3:
					self.weight_record[csvID] = max(self.weight_record[csvID] - 0.2, 0)
		# 普通鱼
		elif len(weights) > 0:
			fishID, _ = WeightRandomObject.onceRandom(weights)

		return fishID

	def fishingEnd(self, fishCsvID):
		fishCfg = csv.fishing.fish[fishCsvID]
		length = 0
		# 特殊鱼没有长度
		if len(fishCfg.length) > 0:
			length = random.randint(fishCfg.length[0], fishCfg.length[1])

		# 更新历史最大长度
		if length > self.length_max:
			self.length_max = length

		# 更新钓鱼记录
		fishRecord = self.fish.setdefault(fishCfg.id, {
			'counter': 0,
			'big_counter': 0,
			'length_max': 0
		})
		fishRecord['counter'] = fishRecord['counter'] + 1
		if length > fishRecord['length_max']:
			fishRecord['length_max'] = length
		if fishCfg.big > 0 and length >= fishCfg.big:
			fishRecord['big_counter'] = fishRecord['big_counter'] + 1

		eff = ObjectGainAux(self.game, fishCfg.award)

		# 策划确认：满级之后不计数
		if self.level >= self.levelMax:
			return eff, length

		levelCfg = csv.fishing.level[self.level]

		# fish type != 1 属于特殊掉落
		if fishCfg.type == 1:
			self.fish_counter[fishCfg.rare] = self.fish_counter.get(fishCfg.rare, 0) + 1

		# 目标鱼数量
		if fishCfg.id in levelCfg.targetNum:
			# 策划确认：目标鱼只会配置一种
			self.target_counter = min(self.target_counter + 1, levelCfg.targetNum[fishCfg.id])

		self.fishingLevelUp()

		return eff, length

	def calcPointAndSpecialFish(self, csvID, length):
		if not ObjectCrossFishingGameGlobal.isOpen(self.game.role.areaKey):
			return

		sceneCfg = csv.fishing.scene[self.select_scene]
		if sceneCfg.type != self.PlaySceneType:
			return

		fishCfg = csv.fishing.fish[csvID]
		point = fishCfg.point
		if length >= fishCfg.big:
			point += int(math.ceil(fishCfg.point * self.BigFishPointUp))

		opsTime = nowtime_t() - self.fishingOperateStartTime

		# item [时间下限，时间上限，加成百分比]
		for item in fishCfg.operateTimePointUp:
			if item[0] < opsTime and opsTime <= item[1]:
				point += int(math.ceil(fishCfg.point * item[2]))
				break

		specialFishNum = 0
		if csvID == ObjectCrossFishingGameGlobal.SpecialFish:
			specialFishNum += 1

		self.point += point
		self.special_fish_num += specialFishNum
		self.pointUpd = True

	# 单次钓鱼开始
	def onceStart(self):
		self.checkPrepare()

		self.fishingCsvID = self.fishingStart()
		if self.fishingCsvID is None:
			raise ClientError('has not fish')
		self.fishingDoing = False

	# 单次钓鱼开始操作
	def onceDoing(self):
		self.checkPrepare()

		cost = ObjectCostAux(self.game, {self.baitItemID: 1})
		if not cost.isEnough():
			raise ClientError('bait not enough')
		cost.cost(src="fishing_once")

		self.game.dailyRecord.fishing_counter += 1
		self.fishingDoing = True
		self.fishingOperateStartTime = nowtime_t()
		ObjectYYHuoDongFactory.onGeneralTask(self.game, TargetDefs.FishingTimes, 1)

		self.weekRecord(self.fishingCsvID)

		# 策划需求：不管钓没钓到，消耗了次数就积累一次权值，如有触发到下一次钓鱼时再触发
		self.weightRecord()

	# 周出现次数记录
	def weekRecord(self, csvID):
		week = weekinclock5date2int()
		# 新的一周重置每周鱼出现次数的数据
		if self.last_week != week:
			self.week_record = {}
			self.last_week = week

		cfg = csv.fishing.fish[csvID]
		# weekMax 配置为 -1 没有周出现次数控制
		if cfg.weekMax != -1:
			self.week_record[cfg.id] = self.week_record.get(cfg.id, 0) + 1

	# 权值记录
	def weightRecord(self):
		baitCfg = csv.fishing.bait[self.select_bait]
		for cfg in self.SceneFishMap[self.select_scene]:
			if cfg.randType == 2 and cfg.weightMin >= 0 and cfg.weightMax >= 0:
				self.weight_record[cfg.id] = self.weight_record.get(cfg.id, 0) + random.uniform(cfg.weightMin, cfg.weightMax) * baitCfg.extraRate.get(cfg.id, 1)

	# 单次钓鱼结束
	def onceEnd(self, result):
		if result != 'win':
			return None, 0

		eff , length = self.fishingEnd(self.fishingCsvID)

		if result == 'win':
			self.game.dailyRecord.fishing_record[self.fishingCsvID] = self.game.dailyRecord.fishing_record.get(self.fishingCsvID, 0) + 1

		self.fishingCsvID = None

		return eff, length

	def autoStart(self):
		self.checkPrepare()

		self.is_auto = True
		self.auto_start_time = nowtime_t()
		self.auto_used_time = 0
		self.auto_win_counter = 0
		self.auto_fail_counter = 0
		self.auto_last_times = ConstDefs.fishingDailyTimes - self.game.dailyRecord.fishing_counter
		self.auto_award = {}
		self.auto_stopped = False

	def autoEnd(self):
		award = unpack(self.auto_award)
		award.pop('fish', None)
		def _afterGain():
			self.is_auto = False
			self.auto_stopped = True
			self.auto_award = {}

		return ObjectGainEffect(self.game, award, _afterGain)

	def getAutoBaits(self, times):
		baitCfg = csv.fishing.bait[self.select_bait]
		count = self.game.items.getItemCount(baitCfg.itemId)
		# 当前鱼饵足够
		if count >= times:
			return [self.select_bait] * times

		ret = [self.select_bait] * count

		# 鱼饵不足自动降低稀有度并根据配置 ID 依次自动使用
		for rare in xrange(baitCfg.rare, 0, -1):
			for cfg in self.BaitRareMap[rare]:
				# 已经检查过
				if cfg.id == self.select_bait:
					continue

				if cfg.scene and self.select_scene not in cfg.scene:
					continue

				count = self.game.items.getItemCount(cfg.itemId)
				if count == 0:
					continue

				if count + len(ret) >= times:
					return ret + [cfg.id] * (times - len(ret))
				else:
					ret += [cfg.id] * count

		return ret

	def autoFishing(self, crossDay=False, crossWeek=False):
		if not self.is_auto or self.auto_stopped:
			return

		# 跨天则按开始钓鱼的第二天五点算
		if crossDay:
			now = datetime2timestamp(datetime.datetime.combine(inclock5date(datetimefromtimestamp(self.auto_start_time)), datetime.time(hour=DailyRefreshHour)) + OneDay)
			self.auto_stopped = True
		else:
			now = nowtime_t()

		autoLastTime = now - self.auto_start_time - self.auto_used_time
		fishTimes = min(int(autoLastTime / self.AutoFishingDuration), self.auto_last_times)
		if fishTimes <= 0:
			return

		autoBaits = self.getAutoBaits(fishTimes)
		autoBaitMax = len(autoBaits)
		if autoBaitMax <= 0:
			self.auto_stopped = True
			return

		autoAwardTmp = self.auto_award
		fish = autoAwardTmp.pop('fish', {})
		effTotal = ObjectGainAux(self.game, unpack(autoAwardTmp))
		win = 0
		fail = 0
		for idx in xrange(fishTimes):
			# 鱼饵不足
			if idx >= autoBaitMax:
				self.auto_stopped = True
				break

			self.auto_used_time += self.AutoFishingDuration

			baitID = autoBaits[idx]
			if self.select_bait != baitID:
				self.select_bait = baitID

			fishID = self.fishingStart()
			# 没有可以钓的鱼，可能配置有问题
			if fishID is None:
				logger.warning("role %s rod %s bait %s scene %s fishing auto has not fish", self.game.role.uid, self.select_rod, self.select_bait, self.select_scene)
				self.auto_stopped = True
				break

			# 消耗鱼饵
			cost = ObjectCostAux(self.game, {self.baitItemID: 1})
			if not cost.isEnough():
				self.auto_stopped = True
				break
			cost.cost(src="fishing_auto")

			# 跨天后每日的次数记录已经重置，所以不记录
			if not crossDay:
				self.game.dailyRecord.fishing_counter += 1
			self.auto_last_times -= 1

			p = self.autoFishTimeAndProbability(fishID)

			# 跨周后每日的次数记录已经重置，所以不记录
			if not crossWeek:
				self.weekRecord(fishID)
			self.weightRecord()

			r = random.random()
			# 成功
			if p >= r:
				effTotal = self.autoFishSuccess(fish, fishID, effTotal, imOpenRandGift=True)
				self.auto_win_counter += 1
				if not crossDay:
					self.game.dailyRecord.fishing_record[fishID] = self.game.dailyRecord.fishing_record.get(fishID, 0) + 1
					self.game.dailyRecord.fishing_win_counter += 1
				win += 1
			else:
				self.auto_fail_counter += 1
				fail += 1
		ObjectYYHuoDongFactory.onGeneralTask(self.game, TargetDefs.FishingWinTimes, win)
		ObjectYYHuoDongFactory.onGeneralTask(self.game, TargetDefs.FishingTimes, win + fail)

		# 次数用尽停止
		if self.auto_last_times <= 0:
			self.auto_stopped = True

		# 跨天则强制停止
		if crossDay:
			self.auto_stopped = True

		autoAwardTmp = pack(effTotal.to_dict())
		if fish:
			autoAwardTmp['fish'] = fish

		self.auto_award = autoAwardTmp

	def autoFishTimeAndProbability(self, fishID):
		fishCfg = csv.fishing.fish[fishID]
		rodCfg = csv.fishing.rod[self.select_rod]
		baitCfg = csv.fishing.bait[self.select_bait]
		levelCfg = csv.fishing.level[self.level]

		# 策划确认：鱼饵、鱼竿和等级的额外概率做 base * (1 + rod + bait + level)
		p = fishCfg.probability * (1 + rodCfg.extraProbability + baitCfg.extraProbability + levelCfg.extraProbability)

		return p

	def autoFishSuccess(self, fish, fishID, effTotal, imOpenRandGift=False):
		fish[fishID] = fish.get(fishID, 0) + 1
		eff, length = self.fishingEnd(fishID)
		self.calcPointAndSpecialFish(fishID, length)

		if imOpenRandGift:
			eff.imOpenRandGift2item()
		effTotal += eff

		return effTotal

	def checkCross(self, t):
		nowDay = todayinclock5date2int()
		nowWeek = weekinclock5date2int()
		autoStartTime = datetimefromtimestamp(self.auto_start_time)
		startDay = date2int(inclock5date(autoStartTime))
		startWeek = weekinclock5date2int(autoStartTime)

		return nowDay > startDay, nowWeek > startWeek

	def checkAuto(self):
		# 没有在自动钓鱼
		if not self.is_auto or self.auto_stopped:
			return

		isCrossDay, isCrossWeek = self.checkCross(self.auto_start_time)
		self.autoFishing(crossDay=isCrossDay, crossWeek=isCrossWeek)

		self.calcPlayAuto()

	def oneKey(self):
		self.checkPrepare()

		baitCount = self.game.items.getItemCount(self.baitItemID)
		fishTimes = min(ConstDefs.fishingDailyTimes - self.game.dailyRecord.fishing_counter, baitCount)

		fish = {}
		effTotal = ObjectGainAux(self.game, {})
		win = 0
		fail = 0

		for _ in xrange(fishTimes):
			fishID = self.fishingStart()
			if fishID is None:
				logger.warning("role %s rod %s bait %s scene %s fishing auto has not fish", self.game.role.uid, self.select_rod, self.select_bait, self.select_scene)
				break

			cost = ObjectCostAux(self.game, {self.baitItemID: 1})
			if not cost.isEnough():
				break
			cost.cost(src="fishing_auto")

			self.game.dailyRecord.fishing_counter += 1
			self.weekRecord(fishID)
			self.weightRecord()

			p = self.autoFishTimeAndProbability(fishID)
			r = random.random()
			# 成功
			if p >= r:
				effTotal = self.autoFishSuccess(fish, fishID, effTotal)
				self.game.dailyRecord.fishing_record[fishID] = self.game.dailyRecord.fishing_record.get(fishID, 0) + 1
				win += 1
				self.game.dailyRecord.fishing_win_counter += 1
			else:
				fail += 1
		ObjectYYHuoDongFactory.onGeneralTask(self.game, TargetDefs.FishingWinTimes, win)
		ObjectYYHuoDongFactory.onGeneralTask(self.game, TargetDefs.FishingTimes, win + fail)

		return effTotal, fish, win, fail


	# 钓鱼大赛自动钓鱼预计算
	def calcPlayAuto(self):
		if not self.is_auto or self.auto_stopped:
			return

		sceneCfg = csv.fishing.scene[self.select_scene]
		# 不是钓鱼大赛场景
		if sceneCfg.type != self.PlaySceneType:
			return
		# 钓鱼大赛未开启
		if not ObjectCrossFishingGameGlobal.isOpen(self.game.role.areaKey):
			return

		endTime = datetime2timestamp(datetime.datetime.combine(inclock5date(nowdatetime_t()), datetime.time(hour=23)))
		fishTimes = int((endTime - self.auto_start_time - self.auto_used_time) / self.AutoFishingDuration)
		fishTimes = min(fishTimes, self.auto_last_times)

		autoBaits = self.getAutoBaits(fishTimes)
		autoBaitMax = len(autoBaits)

		# 保存当前记录
		weightRecord= copy.deepcopy(self.weight_record)
		point = self.point
		specialFishNum = self.special_fish_num
		pointUpd = self.pointUpd

		fish = {}
		effTotal = ObjectGainAux(self.game, {})
		costTotal = ObjectCostAux(self.game, {})
		autoLastTimes = self.auto_last_times
		fail = 0

		try:
			for idx in xrange(fishTimes):
				if idx >= autoBaitMax:
					break
				baitID = autoBaits[idx]

				fishID = self.fishingStart()
				if fishID is None:
					logger.warning("role %s rod %s bait %s scene %s fishing auto has not fish", self.game.role.uid, self.select_rod, self.select_bait, self.select_scene)
					break

				cost = ObjectCostAux(self.game, {csv.fishing.bait[baitID].itemId: 1})
				if not cost.isEnough():
					break
				costTotal += cost

				p = self.autoFishTimeAndProbability(fishID)
				autoLastTimes += 1
				self.weightRecord()

				r = random.random()
				# 成功
				if p >= r:
					effTotal = self.autoFishSuccess(fish, fishID, effTotal, imOpenRandGift=True)
				else:
					fail += 1

			ObjectCrossFishingGameGlobal.onRoleAuto(self.game.role.id, self.game.role.areaKey, {
				'time': nowtime_t(),
				'fail': fail,
				'info': self.game.role.makeCrossFishingRankModel(),
				'fish': fish,
				'award': pack(effTotal.to_dict()),
				'cost': costTotal.to_dict(),
				'weight_record': copy.deepcopy(self.weight_record)
			})
		except:
			logger.exception('ObjectFishing.calcPlayAuto error')

		# 恢复记录
		self.weight_record = weightRecord
		self.point = point
		self.special_fish_num = specialFishNum
		self.pointUpd = pointUpd
