#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2014 YouMi Information Technology Inc.
'''

from framework.csv import csv, MergeServ
from framework.object import ReloadHooker
from framework.distributed.helper import node_key2domains
from game.session import Session


#
# ObjectFeatureUnlockCSV
#

class ObjectFeatureUnlockCSV(ReloadHooker):
	'''
	现在功能开启是等级开启和关卡开启
	'''
	FeatureMap = {}
	DefaultCondition = (999999, 0, 999999) # 未配置的默认就当未开放

	@classmethod
	def classInit(cls):
		import framework
		cls.FeatureMap = {}
		key = MergeServ.getSrcServKeys(Session.server.key)[0]
		domains = node_key2domains(key)
		serverKey, serverIdx = domains[1], int(domains[2])

		for i in csv.unlock:
			cfg = csv.unlock[i]
			if cfg.feature and framework.__language__ in cfg.languages:
				if serverKey in cfg.servers:
					serversRange = cfg.servers[serverKey]
					if int(serversRange[0]) <= serverIdx <= int(serversRange[1]):
						cls.FeatureMap[cfg.feature] = (cfg.startLevel, cfg.startGate, cfg.startVip)

	@classmethod
	def isFeatureExist(cls, feature):
		return feature in cls.FeatureMap

	@classmethod
	def isOpen(cls, feature, game):
		cond = cls.FeatureMap.get(feature, cls.DefaultCondition)
		if cond[2] > 0:  # vip
			gateOpen = True  # 关卡限制默认设置为0, 默认功能开启
			if cond[1] > 0:
				gateOpen = game.role.getGateStar(cond[1]) > 0
			return game.role.level >= cond[0] and game.role.vip_level >= cond[2] and gateOpen
		elif cond[1] > 0:  # gate
			return game.role.level >= cond[0] and game.role.getGateStar(cond[1]) > 0
		return game.role.level >= cond[0]

	@classmethod
	def getOpenLevel(cls, feature):
		cond = cls.FeatureMap.get(feature, cls.DefaultCondition)
		return cond[0]
