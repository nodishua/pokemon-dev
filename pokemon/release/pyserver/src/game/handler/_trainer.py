#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2014 YouMi Information Technology Inc.

Trainer Handlers
'''

from framework.csv import csv, ErrDefs, ConstDefs
from game import ClientError
from game.object import FeatureDefs
from game.handler.task import RequestHandlerTask
from game.handler.inl import effectAutoGain
from game.object.game.gain import ObjectGainAux, ObjectCostAux
from game.object.game.levelcsv import ObjectFeatureUnlockCSV

from tornado.gen import coroutine

# 训练师等级每日奖励
class TrainerDailyAward(RequestHandlerTask):
	url = r'/game/trainer/daily/award'

	@coroutine
	def run(self):
		if not ObjectFeatureUnlockCSV.isOpen(FeatureDefs.Trainer, self.game):
			raise ClientError(ErrDefs.levelLessNoOpened)

		if self.game.dailyRecord.trainer_gift_times > 0:
			raise ClientError('already get')
		cfg = csv.trainer.trainer_level[self.game.role.trainer_level]

		self.game.dailyRecord.trainer_gift_times += 1
		eff = ObjectGainAux(self.game, cfg.dailyAward)
		effectAutoGain(eff, self.game, self.dbcGame, src='trainer_daily_award')
		self.write({
			'view': eff.result,
		})

# 训练师特权技能提升
class TrainerSkillLevelUp(RequestHandlerTask):
	url = r'/game/trainer/skill/levelup'

	@coroutine
	def run(self):
		if not ObjectFeatureUnlockCSV.isOpen(FeatureDefs.Trainer, self.game):
			raise ClientError(ErrDefs.levelLessNoOpened)

		csvID = self.input.get('csvID', None)
		if csvID is None:
			raise ClientError('param miss')

		self.game.trainer.updateSkill(csvID)

# 训练师属性技能提升
class TrainerAttrSkillLevelUp(RequestHandlerTask):
	url = r'/game/trainer/attr_skill/levelup'

	@coroutine
	def run(self):
		if not ObjectFeatureUnlockCSV.isOpen(FeatureDefs.Trainer, self.game):
			raise ClientError(ErrDefs.levelLessNoOpened)

		skills = self.input.get('skills', None) # {csvid: levelup}
		if skills is None:
			raise ClientError('param miss')

		if isinstance(skills, list):
			skills = {i: level for i, level in enumerate(skills, 1)}

		for csvID, level in skills.iteritems():
			if level <= 0:
				raise ClientError('negative is invalid')
			self.game.trainer.updateAttrSkill(csvID, level)

		# 更新所有卡牌属性
		cards = self.game.cards.getAllCards()
		for _, card in cards.iteritems():
			card.calcTrainerAttrSkillAddition(card, self.game.trainer)
			card.onUpdateAttrs()

# 训练师属性技能重置
class TrainerAttrSkillReset(RequestHandlerTask):
	url = r'/game/trainer/attr_skill/reset'

	@coroutine
	def run(self):
		if not ObjectFeatureUnlockCSV.isOpen(FeatureDefs.Trainer, self.game):
			raise ClientError(ErrDefs.levelLessNoOpened)

		if not self.game.role.trainer_attr_skills:
			raise ClientError('reset no ids')

		cost = ObjectCostAux(self.game, {'rmb': ConstDefs.trainerAttrSkillsResetRMB})
		if not cost.isEnough():
			raise ClientError('cost not enough')
		cost.cost(src='trainer_attr_skills_reset')

		total = ObjectGainAux(self.game, {})
		for csvID, level in self.game.role.trainer_attr_skills.iteritems():
			cfg = csv.trainer.attr_skills[csvID]
			cost = ObjectGainAux(self.game, cfg.upCost)
			cost *= level
			total += cost

		self.game.trainer.resetAttrSkill()
		yield effectAutoGain(total, self.game, self.dbcGame, src='trainer_attr_skills_reset')

		# 更新所有卡牌属性
		cards = self.game.cards.getAllCards()
		for _, card in cards.iteritems():
			card.calcTrainerAttrSkillAddition(card, self.game.trainer)
			card.onUpdateAttrs()

		self.write({
			'view': total.result,
		})

# 训练师等级进阶
class TrainerAdvance(RequestHandlerTask):
	url = r'/game/trainer/advance'

	@coroutine
	def run(self):
		if not ObjectFeatureUnlockCSV.isOpen(FeatureDefs.Trainer, self.game):
			raise ClientError(ErrDefs.levelLessNoOpened)

		self.game.trainer.advance()

		# 更新所有卡牌属性
		cards = self.game.cards.getAllCards()
		for _, card in cards.iteritems():
			card.calcTrainerAttrsAddition(card, self.game.trainer)
			card.onUpdateAttrs()
