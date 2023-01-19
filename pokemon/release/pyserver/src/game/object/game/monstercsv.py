#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2014 YouMi Information Technology Inc.
'''

from framework.csv import csv
from framework.object import ReloadHooker

#
# ObjectMonsterCSV
#

class ObjectMonsterCSV(ReloadHooker):

	MonsterScenesMap = {}
	GateMonsterCountMap = {}

	@classmethod
	def classInit(cls):
		cls.MonsterScenesMap = {}
		cls.GateMonsterCountMap = {}
		def _notZero(x):
			return x > 0
			
		for i in csv.monster_scenes:
			csvMonster = csv.monster_scenes[i]
			cls.MonsterScenesMap[(csvMonster.scene_id, csvMonster.round)] = csvMonster
			if csvMonster.scene_id not in cls.GateMonsterCountMap:
				cls.GateMonsterCountMap[csvMonster.scene_id] = 0
			cls.GateMonsterCountMap[csvMonster.scene_id] += len(filter(_notZero, csvMonster.monsters))


	@classmethod
	def getMonstersList(cls, gateId):
		retL = []
		for i in xrange(1,999):
			if (gateId,i) not in cls.MonsterScenesMap:
				break
			cfg = cls.MonsterScenesMap[(gateId,i)]
			for k,v in enumerate(cfg.monsters):
				if v > 0:
					retL.append(v)

		return retL

	@classmethod
	def getMonsterCount(cls, gateId):
		return cls.GateMonsterCountMap.get(gateId, 0)