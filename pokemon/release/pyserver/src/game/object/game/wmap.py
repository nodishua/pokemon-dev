#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2014 YouMi Information Technology Inc.
'''

from __future__ import absolute_import

from framework.csv import csv
from framework.object import ReloadHooker

from game.object import MapDefs, FeatureDefs
from game.object.game.levelcsv import ObjectFeatureUnlockCSV

#
# ObjectMap
#

class ObjectMap(ReloadHooker):
	ObjMap = {}
	WorldMap = None

	@classmethod
	def findObj(cls, type, id):
		uid = (type, id)
		return cls.ObjMap.get(uid, None)

	@classmethod
	def queryGateType(cls, id):
		'''
		查询关卡类型：普通、精英、噩梦 关卡
		'''
		mapObj = ObjectMap.findObj(MapDefs.TypeGate, id)
		if mapObj is None:
			return None
		return mapObj.type

	@classmethod
	def getGateSeqByMap(cls, mapID):
		uid = (MapDefs.TypeMap, mapID)
		mapObj = cls.ObjMap.get(uid, None)
		if mapObj is None:
			uid = (MapDefs.TypeHeroMap, mapID)
			mapObj = cls.ObjMap.get(uid, None)
			if mapObj is None:
				uid = (MapDefs.TypeNightmareMap, mapID)
				mapObj = cls.ObjMap.get(uid, None)

		if mapObj is None:
			return []
		return [o.id for o in mapObj.seq]

	@classmethod
	def classInit(cls):
		cls.ObjMap = {}

		cls.WorldMap = ObjectMap(MapDefs.TypeGlobal)
		cls.WorldMap._make()

		# 扫描非关卡类型的场景，比如塔防等其它玩法场景
		for id in csv.scene_conf:
			cfg = csv.scene_conf[id]
			if cfg.sceneType in [MapDefs.TypeGold, MapDefs.TypeExp, MapDefs.TypeGift, MapDefs.TypeFrag, MapDefs.Type51Huodong]:
				ObjectMap(cfg.sceneType, id, cfg.openLevel, cfg.preGateID)

		# print len(cls.ObjMap.keys())
		# for id in csv.scene_conf:
		# 	flag = True
		# 	for key in cls.ObjMap:
		# 		if id == key[1]:
		# 			flag = False
		# 			break
		# 	if flag:
		# 		print 'no', id

	def __init__(self, type=0, id=0, openLevel=1, preGateID=None, parent=None):
		self.type = type
		self.id = id
		self.openLevel = openLevel
		self.preGateID = preGateID
		self.parent = parent
		self.seq = []
		self.hero = None
		self.nightmare = None

		ObjectMap.ObjMap[self.uid] = self

	@property
	def uid(self):
		type = self.type
		# 精英关卡外部索引时，当做普通关卡来查找
		# 精英只在章节序列中有特定判断
		if type in (MapDefs.TypeHeroGate, MapDefs.TypeNightmareGate):
			type = MapDefs.TypeGate
		return (type, self.id)

	def _make(self, parent=None, deep=0):
		world = csv.world_map
		gate = csv.scene_conf

		if deep == MapDefs.TypeGlobal:
			# 世界列表
			for id in world:
				if world[id].isWorldEnter:
					obj = ObjectMap(MapDefs.TypeWorld, id, world[id].openLevel, None, self)
					self.seq.append(obj)
					obj._make(self, MapDefs.TypeWorld)

		elif deep == MapDefs.TypeWorld:
			# 章节列表
			for id in world[self.id].seq:
				if id in world and world[id].ownerId == self.id:
					obj = ObjectMap(MapDefs.TypeMap, id, world[id].openLevel, None, self)
					self.seq.append(obj)
					obj._make(self, MapDefs.TypeMap)

		elif deep in (MapDefs.TypeMap, MapDefs.TypeHeroMap, MapDefs.TypeNightmareMap):
			nextType = MapDefs.TypeGate
			if deep == MapDefs.TypeHeroMap:
				nextType = MapDefs.TypeHeroGate
			elif deep == MapDefs.TypeNightmareMap:
				nextType = MapDefs.TypeNightmareGate

			# 关卡列表
			# 精英关卡列表
			# 噩梦关卡列表
			for id in world[self.id].seq:
				if id in gate and gate[id].ownerId == self.id:
					obj = ObjectMap(nextType, id, gate[id].openLevel, gate[id].preGateID, self)
					self.seq.append(obj)
					obj._make(self, nextType)

			# 精英关卡是由heroMapId来推算
			id = world[self.id].heroMapId
			if id and id in world:
				obj = ObjectMap(MapDefs.TypeHeroMap, id, world[id].openLevel, None, self)
				self.hero = obj
				obj._make(self, MapDefs.TypeHeroMap)
			# 噩梦关卡是由nightmareMapId来推算
			id = world[self.id].nightmareMapId
			if id and id in world:
				obj = ObjectMap(MapDefs.TypeNightmareMap, id, world[id].openLevel, None, self)
				self.nightmare = obj
				obj._make(self, MapDefs.TypeNightmareMap)

		elif deep == MapDefs.TypeGate:
			pass
		elif deep == MapDefs.TypeHeroGate:
			pass
		elif deep == MapDefs.TypeNightmareGate:
			pass

	def flood(self, game, level, starS, worldNS, mapNS, gateNS, preHero=1, preNightmare=1):
		'''
		关卡开启遍历
		@return 普通关卡状态, 精英关卡状态
		'''
		_Unopen = 0
		_Finished = 1
		_Processing = 2

		if level < self.openLevel:
			return _Unopen
		if self.preGateID is not None and self.preGateID not in starS:
			return _Unopen

		mappN = {
			MapDefs.TypeGlobal: set(),
			MapDefs.TypeWorld: worldNS,
			MapDefs.TypeMap: mapNS,
			MapDefs.TypeHeroMap: mapNS,
			MapDefs.TypeNightmareMap: mapNS,
			MapDefs.TypeGate: gateNS,
			MapDefs.TypeHeroGate: gateNS,
			MapDefs.TypeNightmareGate: gateNS,
		}

		mappN[self.type].add(self.id)
		# 处理关卡
		if len(self.seq) == 0:
			return _Finished if self.id in starS else _Processing

		# 处理世界和章节
		ret = _Finished
		for obj in self.seq:
			ret = obj.flood(game, level, starS, worldNS, mapNS, gateNS, preHero, preNightmare)
			if isinstance(ret, tuple):
				ret, preHero, preNightmare = ret

			if ret == _Unopen:
				break
			elif ret == _Processing:
				if obj.type in (MapDefs.TypeMap, MapDefs.TypeHeroMap, MapDefs.TypeNightmareMap, MapDefs.TypeGate, MapDefs.TypeHeroGate, MapDefs.TypeNightmareGate):
					break

		# 精英关卡开启条件
		# 1. 前置条件的普通关卡通关
		# 2. 达到解锁条件
		retHero = _Finished
		if self.hero:
			retHero = _Unopen
			if ObjectFeatureUnlockCSV.isOpen(FeatureDefs.HeroGate, game):
				if preHero == _Finished:
					retHero = self.hero.flood(game, level, starS, worldNS, mapNS, gateNS)
					if isinstance(retHero, tuple):
						retHero, _, _ = retHero
				# print 'flood hero~', self.uid, ret, retHero, worldNS, mapNS, gateNS

		# 噩梦关卡开启条件
		# 1. 前置条件的普通关卡通关
		# 2. 达到解锁条件
		retNightmare = _Finished
		if self.nightmare:
			retNightmare = _Unopen
			if ObjectFeatureUnlockCSV.isOpen(FeatureDefs.NightmareGate, game):
				if preNightmare == _Finished:
					retNightmare = self.nightmare.flood(game, level, starS, worldNS, mapNS, gateNS)
					if isinstance(retNightmare, tuple):
						retNightmare, _, _ = retNightmare
				# print 'flood nightmare~', self.uid, ret, retNightmare, worldNS, mapNS, gateNS

		# print 'flood~', self.uid, ret, retHero, retNightmare, worldNS, mapNS, gateNS
		return ret, retHero, retNightmare
