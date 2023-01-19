#!/usr/bin/python
# -*- coding: utf-8 -*-

from framework.log import logger
from game import ClientError
from game.handler import RequestHandlerTask
from game.handler.inl import effectAutoGain
from game.object import FeatureDefs, TargetDefs, DispatchTaskDefs, AchievementDefs
from game.object.game.levelcsv import ObjectFeatureUnlockCSV
from game.object.game.yyhuodong import ObjectYYHuoDongFactory

from tornado.gen import coroutine

# 刷新 任务列表
class dispatchTaskRefresh(RequestHandlerTask):
	url = r'/game/dispatch/task/refresh'

	@coroutine
	def run(self):
		if not ObjectFeatureUnlockCSV.isOpen(FeatureDefs.DispatchTask, self.game):
			raise ClientError('not open')

		flag = self.input.get('flag', None)
		if flag is None:
			raise ClientError('param miss')
		self.game.role.refreshDispatchTasks(flag)


# 开始任务派遣
class dispatchTaskBegin(RequestHandlerTask):
	url = r'/game/dispatch/task/begin'

	@coroutine
	def run(self):
		if not ObjectFeatureUnlockCSV.isOpen(FeatureDefs.DispatchTask, self.game):
			raise ClientError('not open')

		cardIDs = self.input.get('cardIDs', None)
		taskIndex = self.input.get('taskIndex', None)
		if cardIDs is None or taskIndex is None:
			raise ClientError('param miss')
		if len(self.game.role.dispatch_tasks) - 1 < taskIndex:
			raise ClientError('taskIndex error')

		cards = self.game.cards.getCards(cardIDs)
		if len(cards) != len(cardIDs):
			raise ClientError('card error')

		self.game.role.beginDispatchTask(taskIndex, cards)
		ObjectYYHuoDongFactory.onGeneralTask(self.game, TargetDefs.DispatchTask, 1)
		self.game.role.refreshDispatchTasks()


# 领取奖励
class dispatchTaskGetAward(RequestHandlerTask):
	url = r'/game/dispatch/task/award'

	@coroutine
	def run(self):
		if not ObjectFeatureUnlockCSV.isOpen(FeatureDefs.DispatchTask, self.game):
			raise ClientError('not open')

		flag = self.input.get('flag', None)
		taskIndex = self.input.get('taskIndex', None)
		if taskIndex is None or flag is None:
			raise ClientError('param miss')
		if len(self.game.role.dispatch_tasks) - 1 < taskIndex:
			raise ClientError('taskIndex error')

		eff, extraEff, quality = self.game.role.getDispatchTaskAward(taskIndex, flag)
		if eff:
			yield effectAutoGain(eff, self.game, self.dbcGame, src='dispatchTask_award')
		if extraEff:
			yield effectAutoGain(extraEff, self.game, self.dbcGame, src='dispatchTask_award_extra')
		ObjectYYHuoDongFactory.onGeneralTask(self.game, TargetDefs.DispatchTaskDone, 1)
		ObjectYYHuoDongFactory.onGeneralTask(self.game, TargetDefs.DispatchTaskQualityDone, quality)
		if quality == DispatchTaskDefs.AQuality:
			self.game.achievement.onCount(AchievementDefs.DispatchTaskACount, 1)
		elif quality == DispatchTaskDefs.BQuality:
			self.game.achievement.onCount(AchievementDefs.DispatchTaskBCount, 1)
		elif quality == DispatchTaskDefs.CQuality:
			self.game.achievement.onCount(AchievementDefs.DispatchTaskCCount, 1)
		elif quality == DispatchTaskDefs.SQuality:
			self.game.achievement.onCount(AchievementDefs.DispatchTaskSCount, 1)
		elif quality == DispatchTaskDefs.S2Quality:
			self.game.achievement.onCount(AchievementDefs.DispatchTaskS2Count, 1)
		self.game.role.refreshDispatchTasks()

		self.write({
			'view': {
				'result': eff.result,
				'extra': extraEff.result if extraEff else None,
			}
		})
