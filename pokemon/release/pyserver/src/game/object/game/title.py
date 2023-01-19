#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2014 YouMi Information Technology Inc.
'''

from framework.csv import csv
from framework.log import logger
from framework.object import ObjectBase

from game.object import TargetDefs, FeatureDefs
from game.object.game.target import predGen
from game.object.game.levelcsv import ObjectFeatureUnlockCSV


#
# ObjectTitle
#
class ObjectTitle(ObjectBase):
	def __init__(self, game, titleID):
		ObjectBase.__init__(self, game)
		self._titleID = titleID
		self._csv = csv.title[titleID]
		self._DB = self.game.role.titles

	def setTitle(self):
		'''
		设置完成状态
		内部判断是否已完成
		'''
		if self._DB.get(self._titleID, None) is not None:
			return False
		if not self.isMatched():
			return False
		self.game.role.addTitle(self._titleID)
		return True

	def isMatched(self):
		'''
		是否条件符合 （多条件 需要同时满足）
		'''
		for i in xrange(1, 99):
			ct = "condition%d" % i
			if ct not in self._csv or not self._csv[ct]:
				break
			targetType = self._csv[ct] # 条件类型
			arg1 = self._csv["conditionArg%d" % i + "_1"]
			arg2 = self._csv[ "conditionArg%d" % i + "_2"]
			target = predGen(targetType, arg1, arg2)
			_, funTarget = target
			if targetType == TargetDefs.CostRmb:
				n = self.game.role.rmb_consume
			elif targetType == TargetDefs.SigninTimes:
				n = self.game.role.sign_in_count
			else:
				n = self.game.role.title_counter.get(targetType, 0)
			if not funTarget(self.game, n):
				return False
		return True


#
# ObjectAchieveMap
#
class ObjectTitleMap(ObjectBase):

	WatchTargetMap = {
		TargetDefs.Level: ('Role', 'level'),
		TargetDefs.Vip: ('Role', 'vip_level'),
		TargetDefs.Gate: ('Role', 'gate_star'),
		TargetDefs.FightingPoint: ('Role', 'battle_fighting_point'),
		TargetDefs.CardStarCount: ('Role', 'cards'),
		TargetDefs.UnlockPokedex: ('Role', 'pokedex'),
		TargetDefs.EndlessPassed: ('Role', 'endless_tower_max_gate'),
		TargetDefs.Friends: ('Society', 'friends'),
		TargetDefs.CostRmb: ('Role', 'rmb_consume'),
		TargetDefs.SigninTimes: ('Role', 'sign_in_count'),
		TargetDefs.CaptureLevel: ('Capture', 'level')
	}
	WatchModelMap = {}  # {model:{column:targrt}}
	TargetMap = {}  # 符合条件的配表ID集合 {targrt : [csvid, ...]}

	@classmethod
	def classInit(cls):
		cls.WatchModelMap = {}
		cls.TargetMap = {}
		for target, mc in cls.WatchTargetMap.iteritems():  # 实现WatchModelMap结构 {model:{column:targrt}}
			cls.WatchModelMap.setdefault(mc[0], {})[mc[1]] = target

		for tID in csv.title:
			for i in xrange(1, 99):
				ct = "condition%d" % i
				if ct not in csv.title[tID]:
					break
				condition = csv.title[tID][ct]  # 条件类型
				if not condition:
					break
				cls.TargetMap.setdefault(condition, []).append(tID)
		for targetType in cls.TargetMap:
			l = cls.TargetMap[targetType]
			cls.TargetMap[targetType] = sorted(l)

	def init(self):
		for model, v in self.WatchModelMap.iteritems():
			for column, _ in v.iteritems():
				self.onWatch(model, column)
		return ObjectBase.init(self)

	def onWatch(self, model, column):
		# 监控每次变化  不是WatchTargetMap条件的变化 就直接return掉
		if model not in self.WatchModelMap or column not in self.WatchModelMap[model]:
			return
		targetType = self.WatchModelMap[model][column]
		if targetType not in self.TargetMap:
			return
		for tID in self.TargetMap[targetType]:
			titleObj = ObjectTitle(self.game, tID)
			titleObj.setTitle()

	def onCount(self, targetType, n):
		if n <= 0:
			return
		if targetType not in self.TargetMap:
			return
		counter = self.game.role.title_counter.get(targetType, 0)
		counter += n
		self.game.role.title_counter[targetType] = counter
		if not ObjectFeatureUnlockCSV.isOpen(FeatureDefs.Title, self.game):
			return
		for tID in self.TargetMap[targetType]:
			titleObj = ObjectTitle(self.game, tID)
			titleObj.setTitle()
