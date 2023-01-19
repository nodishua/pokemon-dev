#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2014 YouMi Information Technology Inc.
'''

from __future__ import absolute_import
import framework
from framework import todayinclock5date2int
from framework.csv import csv
from framework.object import ReloadHooker, ObjectBase, GCWeakValueDictionary

from game.object import TaskDefs, TargetDefs, AchievementDefs
from game.object.game.gain import ObjectGainAux
from game.object.game.target import predGen, dailyCounter

import weakref
import copy

#
# ObjectTaskEffect
#

class ObjectTaskEffect(ObjectGainAux):
	def __init__(self, game, taskID, cb):
		ObjectGainAux.__init__(self, game, csv.tasks[taskID].awardArgs)
		self._cb = cb
		if csv.tasks[taskID].type == TaskDefs.dailyType:
			self.role_exp *= (1 + self.game.trainer.dailyTaskExpRate)

	def gain(self, **kwargs):
		ObjectGainAux.gain(self, **kwargs)
		self._cb()

#
# ObjectLivenessStageEffect
#
class ObjectLivenessStageEffect(ObjectGainAux):
	def __init__(self, game, csvID, cb):
		ObjectGainAux.__init__(self, game, csv.livenessaward[csvID].award)
		self._cb = cb

	def gain(self, **kwargs):
		ObjectGainAux.gain(self, **kwargs)
		self._cb()

#
# ObjectTaskBase
#

class ObjectTaskBase(ObjectBase):
	def __init__(self, game, taskID, closeCB):
		ObjectBase.__init__(self, game)
		self._taskID = taskID
		self._csv = csv.tasks[taskID]
		self._taskDB = None
		self._closeCB = closeCB

	@property
	def id(self):
		return self._taskID

	@property
	def type(self):
		return self._csv.type

	@property
	def target(self):
		return self._csv.targetType

	@property
	def group(self):
		return self._csv.group

	@property
	def levelReq(self):
		return self._csv.levelReq

	@property
	def vipReq(self):
		return self._csv.vipReq

	@property
	def languages(self):
		return self._csv.languages

	def getStatus(self):
		if self.game.role.level < self.levelReq or self.game.role.vip_level < self.vipReq:
			return TaskDefs.taskNoneFlag
		if framework.__language__ not in self.languages:
			return TaskDefs.taskNoneFlag
		taskD = self._taskDB.get(self.id, None)
		if taskD is None:
			return TaskDefs.taskNoneFlag
		return taskD.get('flag', TaskDefs.taskNoneFlag)

	def isMatched(self):
		'''
		是否条件符合
		'''
		raise NotImplementedError()

	def achieved(self, **kwargs):
		'''
		完成任务
		内部判断是否已完成
		@return True表示从None变成Open状态
		'''
		status = self.getStatus()
		if status != TaskDefs.taskNoneFlag:
			return False
		if not self.isMatched():
			return False

		self._taskDB.setdefault(self.id, {}).update(flag=TaskDefs.taskOpenFlag)
		return True

	def getEffect(self):
		'''
		领取奖励
		'''
		def afterGain():
			self._taskDB.setdefault(self.id, {}).update(flag=TaskDefs.taskCloseFlag)
			if self._closeCB:
				self._closeCB(self)
		return ObjectTaskEffect(self.game, self.id, afterGain)

	def setFlag(self, flag):
		old = self._taskDB.setdefault(self.id, {}).get('flag', TaskDefs.taskNoneFlag)
		if old != TaskDefs.taskCloseFlag:
			self._taskDB.setdefault(self.id, {}).update(flag=flag)

#
# ObjectDailyTask
#

class ObjectDailyTask(ObjectTaskBase):
	'''
	日常任务
	'''
	Type = TaskDefs.dailyType

	def __init__(self, game, taskID, closeCB):
		ObjectTaskBase.__init__(self, game, taskID, self._afterEffectGain)
		assert self.Type == self._csv.type
		self._outCloseCB = closeCB
		self._date = todayinclock5date2int()
		self._taskDB = self.game.role.daily_task.setdefault(self._date, {})

	def _afterEffectGain(self, _):
		targetType = self._csv.targetType
		targetArg = self._csv.targetArg
		targetArg2 = self._csv.targetArg2

		#	115 月卡领取钻石
		# 统计领取数量
		if False and targetType == TaskDefs.monthCardTarget:
			from game.object.game.yyhuodong import ObjectYYMonthlyCard

			rmb = self._csv.awardArgs['rmb']
			record = ObjectYYMonthlyCard.getExistedRecord(targetArg2, self.game)
			if record:
				record['gainsum'] = record.get('gainsum', 0) + rmb

		oldPoint = self.game.dailyRecord.liveness_point
		# 活跃度点数
		self.game.dailyRecord.liveness_point += self._csv.point
		for csvID in csv.livenessaward:
			cfg = csv.livenessaward[csvID]
			if self.game.dailyRecord.liveness_point >= cfg.needPoint:
				if self.game.dailyRecord.liveness_stage_award.get(csvID, TaskDefs.taskNoneFlag) == TaskDefs.taskNoneFlag:
					self.game.dailyRecord.liveness_stage_award[csvID]=TaskDefs.taskOpenFlag

		if self._outCloseCB:
			self._outCloseCB(self)
		if oldPoint < 100 <= self.game.dailyRecord.liveness_point:
			self.game.achievement.onCount(AchievementDefs.LivePoint, 1)

	def achieved(self, **kwargs):
		'''
		日常任务需要判定levelReq来初始化计数
		目前只有炼金不需要重置 # huangwei 20150821
		配置上要注意活动开启等级限制应该晚于日常任务，否则会有无限刷
		'''
		# 可能刚好临界点，request_begin没有对dailyRecord进行刷新，导致新的一天日常状态跟前一天一致
		if self._date != self.game.dailyRecord.date:
			self.game.dailyRecord.renew()

		ret = ObjectTaskBase.achieved(self)
		return ret

	def isMatched(self):
		'''
		是否条件符合
		'''
		targetType = self._csv.targetType
		targetArg = self._csv.targetArg
		targetArg2 = self._csv.targetArg2

		# 可能刚好临界点，request_begin没有对dailyRecord进行刷新，导致新的一天日常状态跟前一天一致
		if self._date != self.game.dailyRecord.date:
			self.game.dailyRecord.renew()

		counter = dailyCounter(self.game, targetType)
		_, pred = predGen(targetType, targetArg, targetArg2)
		return pred(self.game, counter)


#
# ObjectMainTask
#

class ObjectMainTask(ObjectTaskBase):
	'''
	主线任务
	'''
	Type = TaskDefs.mainType

	def __init__(self, game, taskID, closeCB):
		ObjectTaskBase.__init__(self, game, taskID, closeCB)
		assert self.Type == self._csv.type
		self._taskDB = self.game.role.main_task

	def isMatched(self):
		'''
		是否条件符合
		'''
		targetType = self._csv.targetType
		targetArg = self._csv.targetArg
		targetArg2 = self._csv.targetArg2

		_, pred = predGen(targetType, targetArg, targetArg2)
		return pred(self.game, None)

#
# ObjectTaskFactory
#

class ObjectTaskFactory(ReloadHooker):

	TaskMap = {}

	@classmethod
	def classInit(cls):
		cls.TaskMap = {
			ObjectDailyTask.Type: ObjectDailyTask,
			ObjectMainTask.Type: ObjectMainTask,
		}

	@classmethod
	def getTask(cls, game, taskID, closeCB=None):
		csvTask = csv.tasks[taskID]
		return cls.TaskMap[csvTask.type](game, taskID, closeCB)


#
# ObjectTasksMap
#

class ObjectTasksMap(ObjectBase):

	WatchTargetMap = {
		# 主线
		TargetDefs.Level: ('Role', 'level'),
		TargetDefs.Gate: ('Role', 'gate_star'),
		TargetDefs.CardsTotal: ('Role', 'cards'),
		TargetDefs.CardGainTotalTimes: ('Role', 'card_gain_times'),
		TargetDefs.Vip: ('Role', 'vip_level'),
		TargetDefs.EquipAdvanceCount: ('Role', 'equips'),
		TargetDefs.CardAdvanceTotalTimes: ('Role', 'card_advance_times'),
		TargetDefs.GateStar: ('Role', 'gate_star'),
		TargetDefs.CardAdvanceCount: ('Role', 'card_advance_times'),
		TargetDefs.UnlockPokedex: ('Role', 'pokedex'),

		# 日常
		TargetDefs.GateChanllenge: ('DailyRecord', 'gate_chanllenge'),
		TargetDefs.HeroGateChanllenge: ('DailyRecord', 'hero_gate_chanllenge'),
		TargetDefs.HuodongChanllenge: ('DailyRecord', 'huodong_chanllenge'),
		TargetDefs.EndlessChallenge: ('DailyRecord', 'endless_challenge'),
		TargetDefs.ArenaBattle: ('DailyRecord', 'pvp_pw_times'),
		TargetDefs.DrawCard: ('DailyRecord', 'draw_card'),
		TargetDefs.WorldBossBattleTimes: ('DailyRecord', 'boss_gate'),
		TargetDefs.EquipStrength: ('DailyRecord', 'equip_strength'),
		TargetDefs.EquipAdvance: ('DailyRecord', 'equip_advance'),
		TargetDefs.CardSkillUp: ('DailyRecord', 'skill_up'),
		TargetDefs.LianjinTimes: ('DailyRecord', 'lianjin_times'),
		TargetDefs.ShareTimes: ('DailyRecord', 'share_times'),
		TargetDefs.DrawGem: ('DailyRecord', 'draw_gem'),
		TargetDefs.FishingTimes: ('DailyRecord', 'fishing_counter'),
		TargetDefs.FishingWinTimes: ('DailyRecord', 'fishing_win_counter'),

		TargetDefs.CompleteImmediate: ('Role', 'last_time'),
		TargetDefs.CardAdvance: ('DailyRecord', 'card_advance_times'),
		TargetDefs.BuyStaminaTimes: ('DailyRecord', 'buy_stamina_times'),
		TargetDefs.CostRmb: ('DailyRecord', 'consume_rmb_sum'),
		TargetDefs.YYHuodongOpen: ('Role', 'yyhuodongs'), # 判定用的是onWatchYYHuoDongs
		TargetDefs.CardLevelUp: ('DailyRecord', 'level_up'),
		TargetDefs.CloneBattleTimes: ('DailyRecord', 'clone_times'),
		TargetDefs.NightmareGateChanllenge: ('DailyRecord', 'nightmare_gate_chanllenge'),
		TargetDefs.UnionContrib: ('DailyRecord', 'union_contrib_times'),
	}
	WatchModelMap = {}

	YYHuoDongTargetMap = set()
	DailyMap = set()
	MainGroupMap = {}
	MapObjsMap = GCWeakValueDictionary() # 热更新用

	@classmethod
	def classInit(cls):
		# 反向Model查找表
		cls.WatchModelMap = {}
		for target, mc in cls.WatchTargetMap.iteritems():
			cls.WatchModelMap.setdefault(mc[0], set()).add(mc[1])

		# 构造日常和主线监听表
		cls.YYHuoDongTargetMap = set()
		cls.DailyMap = set()
		cls.MainGroupMap = {}
		for taskID in csv.tasks:
			cfg = csv.tasks[taskID]
			if cfg.type == TaskDefs.dailyType:
				cls.DailyMap.add(taskID)
			elif cfg.type == TaskDefs.mainType:
				cls.MainGroupMap.setdefault(cfg.group, []).append(taskID)

			if cfg.targetType == TargetDefs.YYHuodongOpen:
				cls.YYHuoDongTargetMap.add(taskID)

		for group in cls.MainGroupMap:
			l = cls.MainGroupMap[group]
			cls.MainGroupMap[group] = sorted(l, key=lambda x: csv.tasks[x].rankInGroup)

		for o in ObjectTasksMap.MapObjsMap.itervalues():
			o.init()

	def __init__(self, game):
		self._init = False
		self._watching = False
		ObjectBase.__init__(self, game)

	def _gc_destroy(self, items):
		values = []
		if self._init:
			# _main_wmap.values = self._main_noclosed.values()[1]
			values = self._daily_noclosed.values() + self._main_wmap.values()
		ObjectBase._gc_destroy(self, items)
		ObjectBase.other_gc_destroy(values)

	def _closeTask(self, task):
		'''
		opened -> closed
		'''
		if task.type == TaskDefs.mainType:
			assert self._main_noclosed[task.group][1] == task
			idx, task = self._main_noclosed[task.group]
			self._main_noclosed.pop(task.group)
			self._stepMainGroup(task.group, idx + 1)

		elif task.type == TaskDefs.dailyType:
			assert self._daily_noclosed[task.id] == task
			self._daily_noclosed.pop(task.id)

	def _stepMainGroup(self, group, startIdx=0):
		for idx in xrange(startIdx, len(ObjectTasksMap.MainGroupMap[group])):
			taskID = ObjectTasksMap.MainGroupMap[group][idx]
			if self._main_task.get(taskID, {}).get('flag', TaskDefs.taskNoneFlag) == TaskDefs.taskCloseFlag:
				continue
			task = ObjectTaskFactory.getTask(self.game, taskID, self._closeTask)
			task.achieved()
			status = task.getStatus()
			if status != TaskDefs.taskCloseFlag:
				self._main_noclosed[group] = (idx, task)
				self._main_wmap[task.id] = task
				break

	def _makeDaily(self):
		self._daily_noclosed = {}
		self._daily_date = todayinclock5date2int()
		self._daily_task = self.game.role.daily_task.setdefault(self._daily_date, {})
		for taskID in ObjectTasksMap.DailyMap:
			if self._daily_task.get(taskID, {}).get('flag', TaskDefs.taskNoneFlag) == TaskDefs.taskCloseFlag:
				continue
			task = ObjectTaskFactory.getTask(self.game, taskID, self._closeTask)
			task.achieved()
			status = task.getStatus()
			if status != TaskDefs.taskCloseFlag:
				self._daily_noclosed[task.id] = task

	def _cleanDailyDB(self):
		# 清理旧数据
		ndi = todayinclock5date2int()
		for oldDate in self.game.role.daily_task.keys():
			if oldDate == ndi:
				continue
			self.game.role.daily_task.pop(oldDate)

	def set(self):
		# _daily_task 由 _makeDaily 统一操作
		self._main_task = self.game.role.main_task
		return ObjectBase.set(self)

	def init(self):
		self._cleanDailyDB()

		# 构造主线任务图
		self._main_noclosed = {}
		self._main_wmap = weakref.WeakValueDictionary() # 方便查找task
		for group in ObjectTasksMap.MainGroupMap:
			self._stepMainGroup(group)

		# 构造日常任务图
		self._makeDaily()

		# 监听运营活动
		self.onWatchYYHuoDongs()

		self._init = True
		ObjectTasksMap.MapObjsMap[self.game.role.id] = self
		return ObjectBase.init(self)

	@property
	def mem(self):
		return self.getShowStatus()

	def _refreshStatus(self):
		if self._daily_date != todayinclock5date2int():
			self._cleanDailyDB()
			self._makeDaily()
			self.onWatchYYHuoDongs()

	def getShowStatus(self):
		'''
		获取opened状态的TaskID给客户端
		'''
		self._refreshStatus()
		daily = {}
		for taskID in ObjectTasksMap.DailyMap:
			if taskID in self._daily_noclosed:
				task = self._daily_noclosed[taskID]
				daily[taskID] = task.getStatus()
			else:
				daily[taskID] = TaskDefs.taskCloseFlag
		main = {}
		for group, taskT in self._main_noclosed.iteritems():
			idx, task = taskT
			main[group] = (task.id, task.getStatus())

		return {
			"daily": daily,
			"main": main,
		}

	def getNoClosedTask(self, taskID):
		cfg = csv.tasks[taskID]
		if cfg.type == TaskDefs.mainType:
			return self._main_wmap.get(taskID, None)
		elif cfg.type == TaskDefs.dailyType:
			return self._daily_noclosed.get(taskID, None)

	def getCanAwardDailyTasks(self):
		ret = []
		for taskID,task in self._daily_noclosed.iteritems():
			if task.getStatus() == TaskDefs.taskOpenFlag:
				ret.append(task)
		return ret

	def getLivenessStageEffect(self, csvID):
		def _afterGain():
			self.game.dailyRecord.liveness_stage_award[csvID]=TaskDefs.taskCloseFlag
		return ObjectLivenessStageEffect(self.game, csvID, _afterGain)

	def onWatch(self, model, column):
		'''
		刷新任务状态
		unopen -> opened
		'''
		if not self._init or self._watching:
			return

		if model not in ObjectTasksMap.WatchModelMap or column not in ObjectTasksMap.WatchModelMap[model]:
			return

		watchT = (model, column)
		# 防止循环进入，逻辑上不应该有某个计数器影响另外一个计数器的可能
		self._watching = True

		# 更新日常
		for taskID in ObjectTasksMap.DailyMap:
			if taskID not in self._daily_noclosed:
				continue
			task = self._daily_noclosed[taskID]
			if watchT == ObjectTasksMap.WatchTargetMap[task.target]:
				task.achieved()

		# 更新主线
		for group, taskT in self._main_noclosed.items():
			idx, task = taskT
			if watchT == ObjectTasksMap.WatchTargetMap[task.target]:
				task.achieved()

		self._watching = False

	def onWatchYYHuoDongs(self):
		from game.object.game.yyhuodong import ObjectYYHuoDongFactory

		# 更新日常 TargetDefs.YYHuodongOpen
		for taskID in self.YYHuoDongTargetMap:
			if taskID not in self._daily_noclosed:
				continue
			task = self._daily_noclosed[taskID]
			targetArg = task._csv.targetArg
			opened = targetArg in ObjectYYHuoDongFactory.OpenIDSet
			task.setFlag(TaskDefs.taskOpenFlag if opened else TaskDefs.taskNoneFlag)

	@classmethod
	def onYYHuoDongsEvent(cls):
		for o in cls.MapObjsMap.itervalues():
			o.onWatchYYHuoDongs()
