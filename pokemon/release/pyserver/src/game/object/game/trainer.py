#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2014 YouMi Information Technology Inc.
'''

from framework import str2num_t
from framework.object import ObjectBase
from framework.csv import csv
from framework.log import logger

from game import ClientError
from game.globaldata import TrainerItemID
from game.object import FeatureDefs, TrainerDefs
from game.object.game.gain import ObjectCostAux
from game.object.game.levelcsv import ObjectFeatureUnlockCSV
from game.object.game.calculator import zeros
from game.thinkingdata import ta

from collections import defaultdict

class ObjectTrainer(ObjectBase):

	TrainerLevelMax = 0
	TrainerLevelSumExp = {}
	TrainerLevelAttrsAdditions = {} # {level: const}

	@classmethod
	def classInit(cls):
		sumExp = 0
		cls.TrainerLevelMax = max(csv.trainer.trainer_level.keys())
		cls.TrainerLevelSumExp = {}
		cls.TrainerLevelAttrsAdditions = {}
		cls.TrainerLevelPrivileges = {}
		for level in xrange(1, cls.TrainerLevelMax + 1):
			cfg = csv.trainer.trainer_level[level]
			sumExp += cfg.needExp
			cls.TrainerLevelSumExp[level] = sumExp

			const = zeros()
			for k, v in cfg.attrs.iteritems():
				const[k] = v
			cls.TrainerLevelAttrsAdditions[level] = const

	def set(self):
		self._unlock = False
		return ObjectBase.set(self)

	def init(self):
		self._tarinerAttrSkillAddition = None # (const, percent) 特权技能属性加成
		if self.game.role.trainer_level == 0:
			self.game.role.trainer_level = 1

		role = self.game.role
		self.level_exp = role.trainer_exp - self.TrainerLevelSumExp[role.trainer_level]
		self._unlock = ObjectFeatureUnlockCSV.isOpen(FeatureDefs.Trainer, self.game)

		self.refreshPrivilege()
		return ObjectBase.init(self)

	def refreshPrivilege(self):
		self._privilege = defaultdict(int) # {privilege: num}
		self._staminaGainPrivilege = defaultdict(int) # {yyID: num}
		if not self._unlock:
			return

		for level in xrange(1, self.game.role.trainer_level + 1):
			cfg = csv.trainer.trainer_level[level]
			for k, v in cfg.privilege.iteritems():
				if k == TrainerDefs.GateSaoDangTimes:  # 扫荡特权 取最大值
					if v > self._privilege.get(k, 0):
						self._privilege[k] = v
				else:
					self._privilege[k] += v

		for csvID, level in self.game.role.trainer_skills.iteritems():
			if level > 0:
				cfg = csv.trainer.skills[csvID]
				if cfg.type == TrainerDefs.StaminaGain: # 体力领取特殊处理
					self._staminaGainPrivilege[cfg.arg] += cfg.nums[level - 1]
				elif cfg.type == TrainerDefs.GateSaoDangTimes:  # 扫荡特权 取最大值
					num = self._privilege.get(cfg.type, 0)
					if cfg.nums[level - 1] > num:
						self._privilege[cfg.type] = cfg.nums[level - 1]
				else:
					self._privilege[cfg.type] += cfg.nums[level - 1]

	def advance(self):
		role = self.game.role
		if role.trainer_level >= self.TrainerLevelMax:
			raise ClientError('trainer level max')
		if role.trainer_exp < self.TrainerLevelSumExp[role.trainer_level + 1]:
			raise ClientError('trainer exp not enough')
		role.trainer_level += 1
		self.level_exp = role.trainer_exp - self.TrainerLevelSumExp[role.trainer_level]
		self.refreshPrivilege()

		ta.track(self.game, event='trainer_level_up')

	def updateSkill(self, csvID):
		role = self.game.role
		if csvID not in role.trainer_skills:
			role.trainer_skills[csvID] = 0

		cfg = csv.trainer.skills[csvID]
		if role.trainer_skills[csvID] >= cfg.levelMax:
			raise ClientError('level max')
		cost = ObjectCostAux(self.game, cfg.upCost)
		if not cost.isEnough():
			raise ClientError('cost not enough')
		cost.cost(src='trainer_skill_levelup')
		role.trainer_skills[csvID] += 1
		role.trainer_exp += cfg.upCost.get(TrainerItemID, 0)
		self.level_exp = role.trainer_exp - self.TrainerLevelSumExp[role.trainer_level]
		self.refreshPrivilege()
		ta.track(self.game, event='trainer_skill_level_up',skill_id=csvID)

	def updateAttrSkill(self, csvID, level):
		self._tarinerAttrSkillAddition = None
		cfg = csv.trainer.attr_skills[csvID]
		if self.game.role.trainer_level < cfg.trainerLevel:
			raise ClientError('level not enough')
		if cfg.totalAttrLevel > 0:
			if sum(self.game.role.trainer_attr_skills.values()) < cfg.totalAttrLevel:
				raise ClientError('total level not enough')
		oldLevel = self.game.role.trainer_attr_skills.get(csvID, 0)
		if cfg.levelMax > 0: # levelMax为负数表示等级无上限
			if oldLevel >= cfg.levelMax:
				raise ClientError('level max')
			level = min(level, cfg.levelMax - oldLevel)
		cost = ObjectCostAux(self.game, cfg.upCost)
		cost *= level
		if not cost.isEnough():
			raise ClientError('cost not enough')
		cost.cost(src='trainer_attr_skill_levelup')
		self.game.role.trainer_attr_skills[csvID] = oldLevel + level

	def resetAttrSkill(self):
		self._tarinerAttrSkillAddition = None
		self.game.role.trainer_attr_skills = {}

	def onLevelUp(self):
		if self._unlock:
			return
		self._unlock = ObjectFeatureUnlockCSV.isOpen(FeatureDefs.Trainer, self.game)
		if self._unlock:
			self._tarinerAttrSkillAddition = None
			# 更新所有卡牌
			cards = self.game.cards.getAllCards()
			for _, card in cards.iteritems():
				card.calcTrainerAttrsAddition(card, self)
				card.calcTrainerAttrSkillAddition(card, self)
				card.onUpdateAttrs()

			self.refreshPrivilege()

	def getAttrsAddition(self):
		if self._unlock:
			return self.TrainerLevelAttrsAdditions[self.game.role.trainer_level]
		return zeros()

	@classmethod
	def calcAttrSkillAddition(cls, attrskills):
		const, percent = zeros(), zeros()
		for csvID, level in attrskills.iteritems():
			cfg = csv.trainer.attr_skills[csvID]
			c, p = str2num_t(cfg.attrValue)
			if cfg.attrType1:
				const[cfg.attrType1] += c * level
				percent[cfg.attrType1] += p * level
			if cfg.attrType2:
				const[cfg.attrType2] += c * level
				percent[cfg.attrType2] += p * level
		return const, percent

	def getAttrSkillAddition(self):
		if self._tarinerAttrSkillAddition is None:
			if self._unlock:
				const, percent = self.calcAttrSkillAddition(self.game.role.trainer_attr_skills)
			else:
				const, percent = zeros(), zeros()
			self._tarinerAttrSkillAddition = (const, percent)
		return self._tarinerAttrSkillAddition

	# 钻石扭蛋每日首次半价
	@property
	def firstRMBDrawCardHalf(self):
		return self._privilege.get(TrainerDefs.FirstRMBDrawCardHalf, 0) == 1

	# 体力上限+x
	@property
	def staminaMax(self):
		return self._privilege.get(TrainerDefs.StaminaMax, 0)

	# 体力购买上限增加
	@property
	def staminaBuyTimes(self):
		return self._privilege.get(TrainerDefs.StaminaBuyTimes, 0)

	# 金币购买上限增加
	@property
	def lianjinBuyTimes(self):
		return self._privilege.get(TrainerDefs.LianjinBuyTimes, 0)

	# 日常任务获得经验增加(百分比)
	@property
	def dailyTaskExpRate(self):
		return self._privilege.get(TrainerDefs.DailyTaskExpRate, 0)

	# 金币副本次数增加
	@property
	def huodongTypeGoldTimes(self):
		return self._privilege.get(TrainerDefs.HuodongTypeGoldTimes, 0)

	# 经验副本次数增加
	@property
	def huodongTypeExpTimes(self):
		return self._privilege.get(TrainerDefs.HuodongTypeExpTimes, 0)

	# 经验药水购买价格下降(百分比)
	@property
	def expItemCostFailRate(self):
		return self._privilege.get(TrainerDefs.ExpItemCostFallRate, 0)

	# 金币抽卡免费次数增加
	@property
	def freeGoldDrawCardTimes(self):
		return self._privilege.get(TrainerDefs.FreeGoldDrawCardTimes, 0)

	# 点金免费次数增加
	@property
	def lianjinFreeTimes(self):
		return self._privilege.get(TrainerDefs.LianjinFreeTimes, 0)

	# 点金额外获得量(百分比)
	@property
	def lianjinDropRate(self):
		return self._privilege.get(TrainerDefs.LianjinDropRate, 0)

	# 体力领取
	def staminaGain(self, yyID):
		return self._staminaGainPrivilege.get(yyID, 0)

	# 金币副本产出增加(百分比)
	@property
	def huodongTypeGoldDropRate(self):
		return self._privilege.get(TrainerDefs.HuodongTypeGoldDropRate, 0)

	# 经验副本产出(百分比)
	@property
	def huodongTypeExpDropRate(self):
		return self._privilege.get(TrainerDefs.HuodongTypeExpDropRate, 0)

	# 公会捐献时公会币获得增加(百分比)
	@property
	def unionContribCoinRate(self):
		return self._privilege.get(TrainerDefs.UnionContribCoinRate, 0)

	# 普通副本金币获得量增加(百分比)
	@property
	def gateGoldDropRate(self):
		return self._privilege.get(TrainerDefs.GateGoldDropRate, 0)

	# 精英副本金币获得量增加(百分比)
	@property
	def heroGateGoldDropRate(self):
		return self._privilege.get(TrainerDefs.HeroGateGoldDropRate, 0)

	# 副本扫荡次数开放
	@property
	def gateSaoDangTimes(self):
		return self._privilege.get(TrainerDefs.GateSaoDangTimes, 0)

	# 探险器寻宝额外免费次数
	@property
	def drawItemFreeTimes(self):
		return self._privilege.get(TrainerDefs.DrawItemFreeTimes, 0)

	# 派遣任务免费刷新次数
	@property
	def dispatchTaskFreeRefreshTimes(self):
		return self._privilege.get(TrainerDefs.DispatchTaskFreeRefreshTimes, 0)

	# 礼物副本次数增加
	@property
	def huodongTypeGiftTimes(self):
		return self._privilege.get(TrainerDefs.HuodongTypeGiftTimes, 0)

	# 礼物副本产出增加(百分比)
	@property
	def huodongTypeGiftDropRate(self):
		return self._privilege.get(TrainerDefs.HuodongTypeGiftDropRate, 0)

	# 碎片副本次数增加
	@property
	def huodongTypeFragTimes(self):
		return self._privilege.get(TrainerDefs.HuodongTypeFragTimes, 0)

	# 碎片副本产出增加(百分比)
	@property
	def huodongTypeFragDropRate(self):
		return self._privilege.get(TrainerDefs.HuodongTypeFragDropRate, 0)

	# 每日首次钻石寻宝1次特权半价（探险器功能里）
	@property
	def firstRMBDrawItemHalf(self):
		return self._privilege.get(TrainerDefs.FirstRMBDrawItemHalf, 0) == 1
