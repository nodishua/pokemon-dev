#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2014 YouMi Information Technology Inc.
'''

from framework import nowtime_t
from framework.csv import csv, ErrDefs
from framework.helper import WeightRandomObject
from framework.object import ObjectDBase, db_property

from game import ClientError
from game.object import FeatureDefs, CaptureDefs
from game.object.game import ObjectFeatureUnlockCSV
from game.object.game.gain import ObjectGainAux, ObjectCostAux
from game.object.game.lottery import ObjectDrawCaptureGroupRandom

import random
from collections import defaultdict, namedtuple

#
# ObjectCapture
#

BallCfgKey = namedtuple("BallCfgKey", ('rate', 'weight', 'weightFix'))

class ObjectCapture(ObjectDBase):
	DBModel = 'Capture'

	# 和策划确认固定道具 ID 和对应的配表概率
	FixedItemRate = {
		523: BallCfgKey('rate1', 'weight1', 'weightFix1'), # 通常求
		524: BallCfgKey('rate2', 'weight2', 'weightFix2'), # 高级球
		525: BallCfgKey('rate3', 'weight3', 'weightFix3')  # 大师球
	}
	LevelSumExp = {}
	LevelMax = 0
	GateSpriteMap = {} # {gateID: cfg}
	LimitSpriteGroupMap = defaultdict(list) # {cfg.group: [cfg...]}

	@classmethod
	def classInit(cls):
		cfg = csv.capture.base[1]
		cls.WeightMax = cfg.weightMax
		cls.WeightMin = cfg.weightMin
		cls.DailyMax = cfg.dailyMax
		cls.OnceMax = cfg.onceMax

		levels = csv.capture.level
		sumExp = 0
		cls.LevelSumExp = {}
		cls.LevelSumExp[0] = 0
		cls.LevelMax = len(levels)
		for level in xrange(1, cls.LevelMax):
			sumExp += levels[level].needExp
			cls.LevelSumExp[level] = sumExp

		cls.LimitSpriteGroupMap = defaultdict(list)
		for idx in csv.capture.sprite:
			cfg = csv.capture.sprite[idx]
			if cfg.type == CaptureDefs.GateType:
				cls.GateSpriteMap[cfg.gate] = cfg
			if cfg.type == CaptureDefs.LimitType:
				cls.LimitSpriteGroupMap[cfg.group].append(cfg)

	def set(self, dic):
		ObjectDBase.set(self, dic)
		if self.level <= 0:
			self.level = 1
		return self

	def init(self):
		self.scene_times = 0
		limitSpritesLen = len(self.limit_sprites)
		if limitSpritesLen < self.OnceMax:
			self.limit_sprites += [None] * (self.OnceMax - limitSpritesLen)
		elif limitSpritesLen > self.OnceMax:
			self.limit_sprites = self.limit_sprites[:self.OnceMax]
		return ObjectDBase.init(self)

	# 主角经验
	def exp():
		dbkey = 'exp'
		def fset(self, value):
			if value == self.db[dbkey]:
				return

			if value < self.db[dbkey]:
				self.db['level'] = 1
			if self.db['level_exp'] < 0:
				self.db['level'] = 1

			while self.level < self.LevelMax and ObjectCapture.LevelSumExp[self.level] <= value:
				self.level += 1
			if self.level == self.LevelMax:
				self.db[dbkey] = min(value, ObjectCapture.LevelSumExp[self.level - 1])
			else:
				self.db[dbkey] = value
			self.db['level_exp'] = self.db[dbkey] - ObjectCapture.LevelSumExp[self.level - 1]
		return locals()
	exp = db_property(**exp())

	# 捕捉等级
	level = db_property('level')

	# 关卡精灵
	gate_sprites = db_property('gate_sprites')

	# 关卡精灵权值
	gate_sprites_weight = db_property('gate_sprites_weight')

	# 限时精灵
	limit_sprites = db_property('limit_sprites')

	# 累计成功捕捉的次数
	success_sum = db_property('success_sum')

	# cd 记录
	cd_record = db_property('cd_record')

	# 累计触发次数
	active_sum = db_property('active_sum')

	def onStaminaConsume(self, num):
		if not ObjectFeatureUnlockCSV.isOpen(FeatureDefs.LimitCapture, self.game):
			return

		if self.game.dailyRecord.capture_limit_times >= self.DailyMax:
			return

		randomWeight = random.uniform(self.WeightMax, self.WeightMin)
		self.game.dailyRecord.capture_limit_weight += randomWeight * num
		if  self.game.dailyRecord.capture_limit_weight >= 1:
			for _ in xrange(int(self.game.dailyRecord.capture_limit_weight)):
				if not self.active():
					break

	def checkSprite(self, captureType, index):
		self.game.role.checkCardCapacityEnough(1)
		if captureType == CaptureDefs.GateType:
			if not ObjectFeatureUnlockCSV.isOpen(FeatureDefs.GateCapture, self.game):
				raise ClientError("gate capture not open")
			if index not in csv.capture.sprite:
				raise ClientError("csvID error")
			cfg = csv.capture.sprite[index]
			if cfg.gate not in self.game.role.gate_open:
				raise ClientError(ErrDefs.captureSpriteNotExists)
			if index in self.gate_sprites and self.gate_sprites[index] == 0:
				raise ClientError(ErrDefs.captureDone)
		elif captureType == CaptureDefs.LimitType:
			if not ObjectFeatureUnlockCSV.isOpen(FeatureDefs.LimitCapture, self.game):
				raise ClientError("limit capture not open")
			sprite = self.getLimitSprite(index)
			if sprite is None:
				raise ClientError(ErrDefs.captureSpriteNotExists)
			if sprite['state'] == 0:
				raise ClientError(ErrDefs.captureDone)
			cfg = csv.capture.sprite[sprite['csv_id']]
			if nowtime_t() - sprite['find_time'] > cfg.time:
				raise ClientError(ErrDefs.captureSpriteMiss)
		else:
			raise ClientError("captureType error")

	def getLimitSprite(self, index):
		if index >= len(self.limit_sprites):
			return None
		return self.limit_sprites[index]

	def enter(self, captureType, index):
		self.scene_times = 0
		self.checkSprite(captureType, index)
		if captureType == CaptureDefs.LimitType:
			sprite = self.limit_sprites[index]
			cfg = csv.capture.sprite[sprite['csv_id']]
			if sprite['total_times'] >= cfg.totalTimes:
				raise ClientError(ErrDefs.captureSceneTimesNotEnough)
			sprite['total_times'] += 1

	def capture(self, captureType, index, itemID):
		self.checkSprite(captureType, index)

		if itemID not in self.FixedItemRate:
			raise ClientError("itemsID error")

		cfg, weight = self.getSpriteCfgAndWeight(captureType, index)

		if self.scene_times >= cfg.sceneTimes:
			raise ClientError(ErrDefs.captureTotalTimesNotEnough)

		cost = ObjectCostAux(self.game, {itemID: 1})
		if not cost.isEnough():
			raise ClientError(ErrDefs.captureBallNotEnough)

		ballCfgKey = self.FixedItemRate[itemID]
		weight += int((csv.capture.level[self.level][ballCfgKey.weight] + cfg[ballCfgKey.weightFix]) * 100)
		rate = cfg[ballCfgKey.rate] * csv.capture.level[self.level].rateUp

		eff = None
		if weight >= 100 or random.randint(1, 100) - rate <= 0:
			eff = self.captureSuccess(captureType, index, cfg)

		self.scene_times += 1
		cost.cost(src='capture')
		self.updateSpriteWeight(captureType, index, weight)

		return eff

	def getSpriteCfgAndWeight(self, captureType, index):
		if captureType == CaptureDefs.GateType:
			cfg = csv.capture.sprite[index]
			weight = self.gate_sprites_weight.get(index, 0)
		elif captureType == CaptureDefs.LimitType:
			cfg = csv.capture.sprite[self.limit_sprites[index]['csv_id']]
			weight = self.limit_sprites[index]['weight']
		else:
			raise ClientError("captureType error")

		return cfg, weight

	def updateSpriteWeight(self, captureType, index, weight):
		if captureType == CaptureDefs.GateType:
			if self.gate_sprites.get(index, 1) == 1:
				self.gate_sprites_weight[index] = weight
			else:
				self.gate_sprites_weight.pop(index, None)
		elif captureType == CaptureDefs.LimitType:
			self.limit_sprites[index]['weight'] = weight
		else:
			raise ClientError("captureType error")

	def captureSuccess(self, captureType, index, cfg):
		# state = 1 可捕捉
		# state = 0 不可捕捉
		if captureType == CaptureDefs.GateType:
			self.gate_sprites[index] = 0
		elif captureType == CaptureDefs.LimitType:
			self.limit_sprites[index]['state'] = 0
		else:
			raise ClientError("captureType error")

		self.success_sum += 1
		self.exp += cfg.exp

		return ObjectGainAux(self.game, {'card': {'id': cfg.cardID}})

	def active(self):
		if self.game.dailyRecord.capture_limit_times >= self.DailyMax:
			return False

		now = nowtime_t()

		randIndexs =  []
		# 查找可用的位置
		# 不可用的位置不做清理和修改，方便客户端检测前后差异来做红点提示
		for i, v in enumerate(self.limit_sprites):
			if v is None:
				randIndexs.append(i)
			elif v['state'] == 0:
				randIndexs.append(i)
			else:
				cfg = csv.capture.sprite[v['csv_id']]
				if now - v['find_time'] >= cfg.time:
					randIndexs.append(i)
				elif v['total_times'] >= cfg.totalTimes:
					randIndexs.append(i)

		# 没有可用的位置来随机出精灵
		if len(randIndexs) == 0:
			return False

		randIndex = random.sample(randIndexs, 1)[0]
		group = ObjectDrawCaptureGroupRandom.randomLib(self.game, self.active_sum + 1)

		weights = {}
		for cfg in self.LimitSpriteGroupMap[group]:
			# in cd
			if cfg.id in self.cd_record:
				if now - self.cd_record[cfg.id] < cfg.cd * 60 * 60:
					continue
				else:
					del self.cd_record[cfg.id]
			# 对应关卡为过关
			if cfg.gate > 0 and cfg.gate not in self.game.role.gate_open:
				continue
			# 不允许出现在该位置，策划配置的从 1 开始需要加 1
			if randIndex + 1 not in cfg.limitPos:
				continue

			weights[cfg.id] =  cfg.weight

		if len(weights) == 0:
			return False

		csvID, _ = WeightRandomObject.onceRandom(weights)

		self.limit_sprites[randIndex] = {
			"csv_id": csvID,
			'find_time': int(now),
			'total_times': 0,
			'state': 1,
			'weight': 0
		}
		self.cd_record[csvID] = int(now)
		self.game.dailyRecord.capture_limit_weight -= 1
		self.game.dailyRecord.capture_limit_times += 1
		self.active_sum += 1

		return True