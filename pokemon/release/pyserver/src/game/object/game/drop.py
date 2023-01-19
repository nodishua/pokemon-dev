#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2014 YouMi Information Technology Inc.
'''

from __future__ import absolute_import

from framework.csv import csv
from framework.object import Copyable, ReloadHooker, ObjectBase, ObjectDBase, db_property
from framework.helper import getL10nCsvValue
from game.object import ItemDefs
from game.object.game.yyhuodong import ObjectYYHuoDongFactory

import copy
import weakref
import random
import itertools
from collections import defaultdict
from weakref import WeakKeyDictionary

#
# ObjectRandomDrop
#

class ObjectRandomDrop(object):
	CSVObjWeakCache = WeakKeyDictionary()

	def __init__(self, gateID, csvGateL):
		self.gateID = gateID
		self.csvGateL = csvGateL

	def getWeightMap(self, csvObj):
		ret = self.CSVObjWeakCache.get(csvObj)
		if ret is not None:
			return ret

		# 计算权重表
		# TODO: optimize
		weightSum = 0.0
		for itemID in csvObj.itemMap:
			weightSum += csvObj.itemMap[itemID]
		if weightSum == 0:
			return None

		weightMap = {}
		for itemID in csvObj.itemMap:
			weightMap[itemID] = csvObj.itemMap[itemID] / weightSum
			if ItemDefs.isItemID(itemID):
				weightMap[itemID] *= csv.items[itemID].gateDropC
		if len(weightMap) == 0:
			return None

		self.CSVObjWeakCache[csvObj] = weightMap
		return weightMap

	def getDropItems(self):
		ret = {}
		# 指定随机和通用随机
		for csvObj in itertools.chain(self.csvGateL):
			weightMap = self.getWeightMap(csvObj)
			if weightMap is None:
				continue

			# 随机次数
			for i in xrange(csvObj.count):
				r = random.randint(1, 100)
				probability = getL10nCsvValue(csvObj, 'probability')
				if r > probability:
					continue

				r = random.random()
				for itemID, prob in weightMap.iteritems():
					r -= prob
					if r <= 0:
						ret[itemID] = ret.get(itemID, 0) + csvObj.itemCount
						break
		return ret


#
# ObjectRandomDropFactory
#

class ObjectRandomDropFactory(ReloadHooker):
	DropCsvMap = {} # {gateID: [cfg, ...]}
	LimitDropCsvMap = {} # {gateID: [cfg, ...]}
	LimitDropExtraCsvMap = defaultdict(dict) # {extraVersion: {gateID: [cfg, ...]}}

	@classmethod
	def classInit(cls):
		cls.DropCsvMap = {}
		cls.LimitDropCsvMap = {}
		cls.LimitDropExtraCsvMap = defaultdict(dict)

		cls._initByCsv(cls.DropCsvMap, csv.random_drops)
		cls._initByCsv(cls.LimitDropCsvMap, csv.limit_drops.random_drops, cls.LimitDropExtraCsvMap)

	@staticmethod
	def _initByCsv(mapp, cfg, extraMapp=None):
		for id in cfg:
			drop = cfg[id]
			if drop.gateID not in csv.scene_conf:
				continue
			if drop.count <= 0:
				continue

			extraVersion = getattr(drop, 'extraVersion', None)
			key = drop.gateID
			d = mapp
			if extraVersion is not None:
				d = extraMapp[extraVersion]
			if key not in d:
				d[key] = []
			d[key].append(drop)

	@classmethod
	def getDrop(cls, gateID):
		csvGateL = None
		if ObjectYYHuoDongFactory.isLimitDropOpen():
			csvGateL = cls.LimitDropCsvMap.get(gateID, []) + cls.DropCsvMap.get(gateID, [])
			extras = ObjectYYHuoDongFactory.getLimitDropExtraVersions()
			for extraVersion in extras:
				csvGateL = csvGateL + cls.LimitDropExtraCsvMap[extraVersion].get(gateID, [])
		else:
			csvGateL = cls.DropCsvMap.get(gateID, [])
		return ObjectRandomDrop(gateID, csvGateL)


#
# ObjectStableDrop
#

class ObjectStableDrop(object):
	def __init__(self, gateID, csvGateL, weightSumMap):
		self.gateID = gateID
		self.csvGateL = csvGateL
		self.weightSumMap = weightSumMap

	def getDropItems(self):
		ret = {}
		# 指定随机和通用随机
		for csvObj in itertools.chain(self.csvGateL):
			firstWeight = getL10nCsvValue(csvObj, 'firstWeight')
			weightRange = (getL10nCsvValue(csvObj, 'weightMin'), getL10nCsvValue(csvObj, 'weightMax'))
			# 首次随机
			if firstWeight < 0 or csvObj.id in self.weightSumMap:
				r = self.weightSumMap.get(csvObj.id, 0) + round(random.uniform(*weightRange), 2)
			else:
				r = firstWeight + round(random.uniform(*weightRange), 2)
			if ItemDefs.isItemID(csvObj.itemID):
				cfg = csv.items[csvObj.itemID]
				r *= cfg.gateDropC
			# 奖励道具
			while r >= 1.0:
				ret[csvObj.itemID] = ret.get(csvObj.itemID, 0) + csvObj.itemCount
				r -= 1.0
			# TODO：本来想减少空值存储，但是首次随机需要判定是否存在
			self.weightSumMap[csvObj.id] = r
		return ret

#
# ObjectStableDropFactory
#

class ObjectStableDropFactory(ReloadHooker):
	DropCsvMap = {} # {gateID: [cfg, ...]}
	LimitDropCsvMap = {} # {gateID: [cfg, ...]}
	LimitDropExtraCsvMap = defaultdict(dict) # {extraVersion: {gateID: [cfg, ...]}}

	@classmethod
	def classInit(cls):
		cls.DropCsvMap = {}
		cls.LimitDropCsvMap = {}
		cls.LimitDropExtraCsvMap = defaultdict(dict)

		cls._initByCsv(cls.DropCsvMap, csv.stable_drops)
		cls._initByCsv(cls.LimitDropCsvMap, csv.limit_drops.stable_drops, cls.LimitDropExtraCsvMap)

	@staticmethod
	def _initByCsv(mapp, cfg, extraMapp=None):
		for id in cfg:
			drop = cfg[id]
			if drop.gateID not in csv.scene_conf:
				continue
			if drop.itemCount <= 0:
				continue
			extraVersion = getattr(drop, 'extraVersion', None)
			key = drop.gateID
			d = mapp
			if extraVersion is not None:
				d = extraMapp[extraVersion]
			if key not in d:
				d[key] = []
			d[key].append(drop)

	@classmethod
	def getDrop(cls, gateID, weightSumMap):
		csvGateL = None
		if ObjectYYHuoDongFactory.isLimitDropOpen():
			csvGateL = cls.LimitDropCsvMap.get(gateID, []) + cls.DropCsvMap.get(gateID, [])
			extras = ObjectYYHuoDongFactory.getLimitDropExtraVersions()
			for extraVersion in extras:
				csvGateL = csvGateL + cls.LimitDropExtraCsvMap[extraVersion].get(gateID, [])
		else:
			csvGateL = cls.DropCsvMap.get(gateID, [])
		return ObjectStableDrop(gateID, csvGateL, weightSumMap)

