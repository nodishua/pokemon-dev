#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2014 YouMi Information Technology Inc.
'''

from framework import is_none, todaydate2int, nowtime_t,int2date, int2time,nowdatetime_t, datetime2timestamp
from framework.csv import csv
from framework.object import ObjectBase, ReloadHooker
from framework.log import logger

from game import ServerError
from game.object import ItemDefs, EquipDefs, FragmentDefs
from game.object.game.gain import ObjectGainAux
from game.thinkingdata import ta

from collections import defaultdict

import datetime, time
import copy
#
# ObjectItemsMap
#

class ObjectItemsMap(ObjectBase):

	def __iter__(self):
		return iter(self._items.keys())

	def set(self):
		self._items = self.game.role.items
		return ObjectBase.set(self)

	def _fixCorrupted(self):
		pass

	def getTotalSize(self):
		return reduce(lambda x, y: x + y, self._items.values())

	def getTypeSize(self):
		return len(self._items)

	def getItemsByType(self, type):
		ids = filter(lambda id: csv.items[id].type == type, self._items)
		return {id: self._items[id] for id in ids}

	def getItemCount(self, itemID):
		return self._items.get(itemID, 0)

	def isEnough(self, itemsD):
		for itemID, count in itemsD.iteritems():
			if count <= 0:
				raise ServerError('items (%s, %s) cheat' % (itemID, count))
			if ItemDefs.isItemID(itemID):
				if self._items.get(itemID, 0) < count:
					return False
				if self.isExpire(itemID):
					return False
		return True

	def isExpire(self, itemID):
		cfg = csv.items[itemID]
		if cfg.dateType == ItemDefs.expireValid and nowdatetime_t() > datetime.datetime.combine(int2date(cfg.expireDate), int2time(cfg.expireTime)):
			return True
		return False

	def expireItems(self):
		deadline = float('Inf')
		for itemID in self._items.keys():
			cfg = csv.items[itemID]
			if self.isExpire(itemID):
				d = datetime.datetime.combine(int2date(cfg.expireDate), int2time(cfg.expireTime))
				now_time = int(datetime2timestamp(d))
				if now_time < deadline:
					deadline = now_time
				if cfg.timeOut == 1:
					self._items.pop(itemID)
		return deadline

	def addItem(self, itemID, count):
		if count <= 0:
			raise ServerError('items (%s, %s) cheat' % (itemID, count))
		if not ItemDefs.isItemID(itemID):
			return False

		cfg = csv.items[itemID]
		if cfg.type in (ItemDefs.roleDisplayType, ItemDefs.skinInMemType):
			return False
		count = self._items.get(itemID, 0) + count
		self._items[itemID] = min(count, cfg.stackMax)
		if count > self._items[itemID]:
			logger.warning('role %d %s item %d overflow %d', self.game.role.uid, self.game.role.pid, itemID, count - self._items[itemID])
		return True

	def addItems(self, itemsD):
		for itemID, count in itemsD.iteritems():
			if count <= 0:
				raise ServerError('items (%s, %s) cheat' % (itemID, count))
			if not ItemDefs.isItemID(itemID):
				continue
			cfg = csv.items[itemID]
			if cfg.type in (ItemDefs.roleDisplayType, ItemDefs.skinInMemType):
				continue
			count = self._items.get(itemID, 0) + count
			self._items[itemID] = max(min(count, cfg.stackMax), 0)
			if count > self._items[itemID]:
				logger.warning('role %d %s item %d overflow %d', self.game.role.uid, self.game.role.pid, itemID, count - self._items[itemID])
			if self._items[itemID] <= 0:
				self._items.pop(itemID)
		return True

	def costItems(self, itemsD):
		'''
		直接消耗道具
		对于那些无附加属性的道具消耗
		'''
		if not self.isEnough(itemsD):
			return False
		for itemID, count in itemsD.iteritems():
			if not ItemDefs.isItemID(itemID):
				continue
			self._items[itemID] -= count
			if self._items[itemID] <= 0:
				self._items.pop(itemID)
		return True

	def getCostItem(self, itemID, count):
		'''
		获取消耗道具
		对于那些有附加属性的道具消耗
		这个接口不会直接消耗，需要在gain函数中消耗
		'''
		itemsD = {itemID: count}
		if not ItemDefs.isItemID(itemID):
			return None
		if not self.isEnough(itemsD):
			return None
		return ObjectItemEffectFactory.getEffect(self.game, itemID, count)

	def getCostItems(self, itemsD):
		'''
		获取消耗道具
		对于那些有附加属性的道具消耗
		这个接口不会直接消耗，需要在gain函数中消耗
		'''
		if not self.isEnough(itemsD):
			return None
		ret = {}
		for itemID, count in itemsD.iteritems():
			if not ItemDefs.isItemID(itemID):
				continue
			ret[itemID] = ObjectItemEffectFactory.getEffect(self.game, itemID, count)
		return ret

	def checkRegain(self, itemID, count):
		"""
		检测是否重复获得
		返回判断结果和重复获得的数量
		"""

		stackMax = csv.items[itemID].stackMax
		total = self._items.get(itemID, 0) + count
		if total > stackMax:
			return True, total - stackMax
		return False, 0

#
# ObjectItemEffect
#

class ObjectItemEffect(ObjectBase):
	'''
	普通道具
	'''
	Type = ItemDefs.normalType

	def __init__(self, game, itemID, count):
		ObjectBase.__init__(self, game)
		self._itemID = itemID
		self._count = count
		self._items = self.game.role.items
		if count <= 0:
			raise ServerError('effect (%s, %s) cheat' % (itemID, count))

	@property
	def itemID(self):
		return self._itemID

	@property
	def count(self):
		return self._count

	def gain(self, **kwargs):
		if self._count <= 0:
			raise ServerError('effect (%s, %s) cheat' % (self._itemID, self._count))

		self._items[self._itemID] -= self._count
		if self._items[self._itemID] <= 0:
			self._items.pop(self._itemID)
		src = kwargs.get('src', None)
		if src:
			logger.info('role %d %s cost for %s, %s', self.game.role.uid, self.game.role.pid, src, {self._itemID: self._count})

		ta.good(self.game, self, **kwargs)
	def checkRegain(self):
		return False, 0

#
# ExpItemEffect
#

class ExpItemEffect(ObjectItemEffect):
	'''
	经验道具
	'''
	Type = ItemDefs.expType
	ArgName = 'exp'

	def gain(self, **kwargs):
		if self._count <= 0:
			raise ServerError('effect (%s, %s) cheat' % (self._itemID, self._count))

		card = kwargs['card']
		csvItem = csv.items[self._itemID]
		if ExpItemEffect.ArgName in csvItem.specialArgsMap:
			exp = csvItem.specialArgsMap[ExpItemEffect.ArgName]
			for i in xrange(self._count):
				old = card.exp
				card.exp += exp
				if old == card.exp:
					self._count = i
					break

		ObjectItemEffect.gain(self, **kwargs)

#
# StaminaItemEffect
#

class StaminaItemEffect(ObjectItemEffect):
	'''
	体力道具
	'''
	Type = ItemDefs.staminaType
	ArgName = 'stamina'

	def gain(self, **kwargs):
		if self._count <= 0:
			raise ServerError('effect (%s, %s) cheat' % (self._itemID, self._count))

		csvItem = csv.items[self._itemID]
		if StaminaItemEffect.ArgName in csvItem.specialArgsMap:
			stamina = csvItem.specialArgsMap[StaminaItemEffect.ArgName]
			for i in xrange(self._count):
				old = self.game.role.stamina
				self.game.role.stamina += stamina
				if old == self.game.role.stamina:
					self._count = i
					break

		ObjectItemEffect.gain(self, **kwargs)

#
# GiftItemEffect
#

class GiftItemEffect(ObjectItemEffect, ObjectGainAux):
	'''
	礼包道具
	'''
	Type = ItemDefs.giftType

	def __init__(self, game, itemID, count):
		ObjectItemEffect.__init__(self, game, itemID, count)

		argsD = csv.items[self._itemID].specialArgsMap
		ObjectGainAux.__init__(self, game, argsD)
		ObjectGainAux.__imul__(self, self._count)

	def gain(self, **kwargs):
		ObjectGainAux.gain(self, **kwargs)
		ObjectItemEffect.gain(self, **kwargs)

#
# GiftItemEffectInMem
#

class GiftItemEffectInMem(GiftItemEffect):
	'''
	礼包道具
	现在只有关卡奖励在使用，礼包不进数据库，直接在内存中消耗掉
	'''
	Type = ItemDefs.giftInMemType

	def gain(self, **kwargs):
		ObjectGainAux.gain(self, **kwargs)

#
# SkinItem
#

class SkinItemEffectInMem(ObjectItemEffect):
	'''
	皮肤道具
	现在只有领取运营活动奖励时，道具不进数据库，直接在内存中消耗掉
	'''
	Type = ItemDefs.skinInMemType
	ArgName = 'skinID'

	def gain(self, **kwargs):
		self.game.role.activeSkin(self._itemID)

	def checkRegain(self):
		csvItem = csv.items[self._itemID]
		skinID = csvItem.specialArgsMap.get(SkinItemEffectInMem.ArgName, None)
		if skinID and skinID in self.game.role.skins:
			return True, self._count

		if self._count > 1:
			return True, self._count - 1
		return False, 0

#
# RandomGiftItemEffect
#

class RandomGiftItemEffect(GiftItemEffect):
	'''
	随机礼包道具
	'''
	Type = ItemDefs.randomGiftType

	def __init__(self, game, itemID, count):
		ObjectItemEffect.__init__(self, game, itemID, count)

		libID = self.getLibID(game, itemID)

		from game.object.game.lottery import ObjectDrawRandomItem

		argsD = {}
		for i in xrange(self._count): #count直接在这里处理了
			itemObj = ObjectDrawRandomItem.getObject(libID)
			itemT = itemObj.getRandomItem()
			ObjectDrawRandomItem.packToDict(itemT, argsD)

		# 固定奖励
		if 'fix' in csv.items[itemID].specialArgsMap:
			fixCfg = csv.items[itemID].specialArgsMap['fix']
			if fixCfg:
				for k,v in fixCfg.iteritems():
					ObjectDrawRandomItem.packToDict((k,v*self._count), argsD)

		ObjectGainAux.__init__(self, game, argsD)

	@classmethod
	def getLibID(cls, game, itemID):
		roleLevel = game.role.level
		giftLevelCfg = csv.items[itemID].specialArgsMap['level']
		libID = None
		for level1,level2,ID in giftLevelCfg:
			if roleLevel >= level1 and roleLevel <= level2:
				libID = ID
				break
		if libID is None or is_none(libID):
			raise ServerError('no such %d libID' % libID)

		return libID

	def gain(self, **kwargs):
		ObjectGainAux.gain(self, **kwargs)
		ObjectItemEffect.gain(self, **kwargs)

#
# FeelExpItemEffect
#

class FeelExpItemEffect(ObjectItemEffect):
	'''
	经验道具
	'''
	Type = ItemDefs.feelExpType
	ArgName = 'feel_exp'

	def gain(self, **kwargs):
		if self._count <= 0:
			raise ServerError('effect (%s, %s) cheat' % (self._itemID, self._count))

		markID = kwargs['markID']
		csvItem = csv.items[self._itemID]
		if FeelExpItemEffect.ArgName in csvItem.specialArgsMap:
			feelExp = csvItem.specialArgsMap[FeelExpItemEffect.ArgName]
			for i in xrange(self._count):
				if not self.game.feels.addFeelExp(markID, feelExp):
					self._count = i
					break
		ObjectItemEffect.gain(self, **kwargs)

#
# RoleDisplayEffect
#

class RoleDisplayEffect(ObjectItemEffect):
	"""
	头像，头像框，形象，称号
	"""
	Type = ItemDefs.roleDisplayType
	ArgNames = ('logo', 'frame','title')

	def gain(self, **kwargs):
		csvItem = csv.items[self._itemID]
		for name in RoleDisplayEffect.ArgNames:
			cfgArgID = csvItem.specialArgsMap.get(name, None)
			if cfgArgID:
				if name == 'logo':
					self.game.role.addLogo(cfgArgID)
				elif name == 'frame':
					self.game.role.addFrame(cfgArgID)
				elif name == 'title':
					self.game.role.addTitle(cfgArgID, days=csvItem.specialArgsMap.get("days", None))

	def checkRegain(self):
		csvItem = csv.items[self._itemID]
		for name in RoleDisplayEffect.ArgNames:
			cfgArgID = csvItem.specialArgsMap.get(name, None)
			if cfgArgID:
				if name == 'logo' and cfgArgID in self.game.role.logos:
					return True, self._count
				elif name == 'frame' and cfgArgID in self.game.role.frames:
					return True, self._count
				elif name == 'title' and cfgArgID in self.game.role.titles:
					return True, self._count

		if self._count > 1:
			return True, self._count - 1
		return False, 0

#
# CharacterItemEffect
#

class CharacterItemEffect(ObjectItemEffect):
	'''
	性格道具
	'''
	Type = ItemDefs.characterType
	ArgName = 'character'

	def gain(self, **kwargs):
		card = kwargs['card']
		cfg = csv.items[self._itemID]
		character = cfg.specialArgsMap[self.ArgName]
		card.character = character

		ObjectItemEffect.gain(self, **kwargs)


#
# ObjectItemEffectFactory
#

class ObjectItemEffectFactory(ReloadHooker):

	ItemEffectMap = {}

	@classmethod
	def classInit(cls):
		cls.ItemEffectMap = {
			ObjectItemEffect.Type: ObjectItemEffect,
			ExpItemEffect.Type: ExpItemEffect,
			StaminaItemEffect.Type: StaminaItemEffect,
			GiftItemEffect.Type: GiftItemEffect,
			GiftItemEffectInMem.Type: GiftItemEffectInMem,
			RandomGiftItemEffect.Type: RandomGiftItemEffect,
			FeelExpItemEffect.Type: FeelExpItemEffect,
			SkinItemEffectInMem.Type: SkinItemEffectInMem,
			RoleDisplayEffect.Type: RoleDisplayEffect,
			CharacterItemEffect.Type: CharacterItemEffect,
		}

	@classmethod
	def getEffect(cls, game, itemID, count):
		if count <= 0:
			raise ServerError('effect (%s, %s) cheat' % (itemID, count))
		csvItem = csv.items[itemID]
		return cls.ItemEffectMap[csvItem.type](game, itemID, count)

	@classmethod
	def getEffectByType(cls, type, game, itemID, count):
		if count <= 0:
			raise ServerError('effect (%s, %s) cheat' % (itemID, count))
		return cls.ItemEffectMap[type](game, itemID, count)

	@classmethod
	def checkRegain(cls, type, game, itemID, count):
		if count <= 0:
			raise ServerError('effect (%s, %s) cheat' % (itemID, count))
		return cls.ItemEffectMap[type](game, itemID, count).checkRegain()
