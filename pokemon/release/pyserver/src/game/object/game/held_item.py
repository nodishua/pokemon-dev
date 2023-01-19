#!/usr/bin/python
# coding=utf-8
import copy
import math
import random
import weakref

from framework import str2num_t
from framework.csv import csv, ConstDefs, ErrDefs
from framework.log import logger
from framework.helper import objectid2string
from framework.object import ObjectDBase, ObjectDBaseMap, db_property, ObjectBase
from game import ClientError
from game.object import AttrDefs, HeldItemDefs, ItemDefs, TargetDefs
from game.object.game import ObjectCardRebirthBase
from game.object.game.gain import ObjectCostAux, ObjectGainAux
from game.object.game.calculator import zeros
from game.object.game.yyhuodong import ObjectYYHuoDongFactory

#
# ObjectHeldItem
#
class ObjectHeldItem(ObjectDBase):
	DBModel = 'RoleHeldItem'

	HeldItemObjsMap = weakref.WeakValueDictionary()

	@classmethod
	def classInit(cls):
		#  刷新csv配置
		for obj in cls.HeldItemObjsMap.itervalues():
			obj.init()

	def init(self):
		self._csvHeldItem = csv.held_item.items[self.held_item_id]
		ObjectHeldItem.HeldItemObjsMap[self.id] = self
		return ObjectDBase.init(self)

	def _fixCorrupted(self):
		if self.card_db_id:
			card = self.game.cards.getCard(self.card_db_id)
			if not card:
				logger.warning('role %s held_item %s card not exited!' % (objectid2string(self.role_db_id), objectid2string(self.id)))
				self.card_db_id = None
			else:
				card.held_item = self.id

	# Role.id
	role_db_id = db_property('role_db_id')

	# RoleCard.id
	card_db_id = db_property('card_db_id')

	# 携带道具 CSV ID
	held_item_id = db_property('held_item_id')

	# 突破（进阶）等级
	advance = db_property('advance')

	# 强化 等级
	def level():
		dbkey = 'level'
		def fset(self, value):
			old = self.db[dbkey]
			self.db[dbkey] = value
			ObjectYYHuoDongFactory.onGeneralTask(self.game, TargetDefs.HeldItemStrength, max(0, value - old))
		return locals()
	level = db_property(**level())

	# 道具经验
	sum_exp = db_property('sum_exp')

	# 是否存在（可能已经被熔炼）
	exist_flag = db_property('exist_flag')

	# 突破消耗的万能道具数量
	cost_universal_items = db_property('cost_universal_items')

	def getAttrs(self):
		'''
		计算基础属性
		'''
		const = zeros()
		cfg = csv.held_item.items[self.held_item_id]
		strengthSeqID = cfg.strengthAttrSeq
		advanceSeqID = cfg.advanceAttrSeq
		attrRates = cfg.attrNumRates
		for i, attr in enumerate(cfg.attrTypes):
			advanceAttrRate = csv.held_item.advance_attrs[self.advance]['attrRate%d' % advanceSeqID]
			advanceAttrNum = csv.held_item.advance_attrs[self.advance]['attrNum%d' % advanceSeqID]
			levelAttrNum = csv.held_item.level_attrs[self.level]['attrNum%d' % strengthSeqID]
			const[attr] += attrRates[i] * advanceAttrRate[i] * (advanceAttrNum[i] + levelAttrNum[i])
		return const

	def getEffect(self, markID):
		'''
		计算携带效果
		'''
		const = zeros()
		percent = zeros()
		for i in xrange(1, 99):
			effect = "effect%d" % i
			if effect not in self._csvHeldItem or not self._csvHeldItem[effect]:
				break
			cfg = csv.held_item.effect[self._csvHeldItem[effect]]
			if cfg.exclusiveCards and markID not in cfg.exclusiveCards: # 不是专属
				continue
			if cfg.type == 1: # 属性
				level = -1 # 携带效果等级, 实际上是索引下标
				for idx, val in enumerate(self._csvHeldItem["effect%dLevelAdvSeq" % i]):
					if self.advance < val:
						break
					level = idx
				if level < 0:
					continue
				for k in xrange(1, 99):
					attr = "attrType%d" % k
					attrNumKey = "attrNum%d" % k
					if attr not in cfg or not cfg[attr]:
						break
					attr = cfg[attr]
					num = str2num_t(cfg[attrNumKey][level])
					const[attr] += num[0]
					percent[attr] += num[1]
		return const, percent

	def getPassiveSkills(self, markID, isGlobal=False):
		skills = {}
		for i in xrange(1, 99):
			effect = "effect%d" % i
			if effect not in self._csvHeldItem or not self._csvHeldItem[effect]:
				break
			cfg = csv.held_item.effect[self._csvHeldItem[effect]]
			if cfg.exclusiveCards and markID not in cfg.exclusiveCards: # 不是专属
				continue
			if cfg.type == 2: # 技能
				if isGlobal:
					if csv.skill[cfg.skillID].isGlobal:
						skills[cfg.skillID] = self.advance + 1  # held item advance is effect passive skill level
				else:
					if not csv.skill[cfg.skillID].isGlobal:
						skills[cfg.skillID] = self.advance + 1
		return skills

	def strengthHeldItem(self, costD):
		'''
		携带道具强化
		'''
		cfgLevel = csv.held_item.level
		strengthSeqID = self._csvHeldItem["strengthSeqID"]
		strengthMax = self._csvHeldItem["strengthMax"]
		# 消耗
		costHeldItems = []
		exp = 0
		for csvID, count in costD.iteritems():
			if HeldItemDefs.isHeldItemID(csvID):
				heldItems = self.game.heldItems.getCostHeldItems(csvID, count, self.id)
				costHeldItems.extend(heldItems)
				exp += csv.held_item.items[csvID].heldItemExp * count
			elif ItemDefs.isItemID(csvID):
				exp += csv.items[csvID].specialArgsMap.get('heldItemExp', 0) * count

		cost = ObjectCostAux(self.game, costD)
		cost.gold += exp * ConstDefs.heldItemExpNeedGold
		cost.setCostHeldItems(costHeldItems)
		if not cost.isEnough():
			raise ClientError("cost not enough")
		else:
			cost.cost(src='heldItem_strength')

		# 等级升级
		self.sum_exp = self.sum_exp + exp
		tempExp = 0
		level = 1
		for i in xrange(1, strengthMax):
			tempExp += cfgLevel[i]["levelExp%d" % strengthSeqID]
			if self.sum_exp < tempExp:
				break
			level = level + 1
		if level > strengthMax:
			self.level = strengthMax
		else:
			self.level = level

	@property
	def advanceSeqID(self):
		return self._csvHeldItem["advanceSeqID"]

	def advanceHeldItem(self, costHeldItems, itemsD):
		'''
		携带道具突破
		'''
		advanceLvLimit = self._csvHeldItem["advanceLvLimit"]
		advanceMax = self._csvHeldItem["advanceMax"]
		universalItems = self._csvHeldItem['universalItems']
		if self.advance+1 > advanceMax:
			raise ClientError(ErrDefs.advanceIsMAX)
		if advanceLvLimit[self.advance] > self.level:
			raise ClientError("level not reached")

		for itemID, count in itemsD.iteritems():
			if count <= 0:
				raise ClientError('negative is invalid')
			if itemID not in universalItems:
				raise ClientError('item error')
		useUniversal = sum(itemsD.values()) # 使用万能道具数量

		useHeldItems = {} # {csvID: count}
		for v in costHeldItems:
			useHeldItems[v.held_item_id] = useHeldItems.get(v.held_item_id, 0) + 1

		needUniversal = 0
		costD = csv.held_item.advance[self.advance]["costItemMap%d" % self.advanceSeqID]
		for csvID, count in costD.iteritems():
			if HeldItemDefs.isHeldItemID(csvID):
				if useHeldItems.get(csvID, 0) > count:
					raise ClientError('count error')
				needUniversal += count - useHeldItems.get(csvID, 0)
			else:
				itemsD[csvID] = itemsD.get(csvID, 0) + count
		if needUniversal > useUniversal: # 万能使用不够
			raise ClientError('cost not enough')

		for obj in costHeldItems:
			cardID = obj.card_db_id
			if cardID: # 如果已经装备了，脱下
				obj.card_db_id = None
				card = self.game.cards.getCard(cardID)
				card.held_item = None
				card.calcHeldItemAttrsAddition(card)
				card.onUpdateAttrs()

		cost = ObjectCostAux(self.game, itemsD)
		cost.setCostHeldItems(costHeldItems)
		if not cost.isEnough():
			raise ClientError("cost not enough")
		else:
			cost.cost(src='heldItem_advance')
			# 记录消耗的万能道具
			for itemID, count in itemsD.iteritems():
				if itemID in universalItems:
					self.cost_universal_items[itemID] = self.cost_universal_items.get(itemID, 0) + count
		self.advance = self.advance+1
		ObjectYYHuoDongFactory.onGeneralTask(self.game, TargetDefs.HeldItemAdvance, 1)

	def canBeCost(self):
		# 未携带，未养成的才能消耗
		if self.card_db_id or self.sum_exp or self.advance:
			return False
		return True

	@property
	def quality(self):
		return self._csvHeldItem["quality"]

#
# ObjectHeldItemMap
#

class ObjectHeldItemsMap(ObjectDBaseMap):

	def _new(self, dic):
		heldItem = ObjectHeldItem(self.game, self.game._dbcGame)
		heldItem.set(dic)
		return (heldItem.id, heldItem)

	def init(self):
		ret = ObjectDBaseMap.init(self)
		return ret

	def getHeldItem(self, heldItemID):
		ret = self._objs.get(heldItemID, None)
		if ret and not ret.exist_flag:
			return None
		return ret

	def getHeldItems(self, heldItemIDs):
		ret = []
		for id in heldItemIDs:
			if id in self._objs:
				heldItem = self._objs[id]
				if not heldItem.exist_flag:
					continue
				ret.append(heldItem)
		return ret

	def addHeldItems(self, heldItemsL):
		if len(heldItemsL) == 0:
			return {}
		def _new(dic):
			heldItem = ObjectHeldItem(self.game, self.game._dbcGame)
			heldItem.set(dic).init().startSync()
			return (heldItem.id, heldItem)
		objs = dict(map(_new, heldItemsL))
		self._objs.update(objs)
		self.game.role.held_items = map(lambda o: o.id, self._objs.itervalues())
		self._add(objs.keys())
		return objs

	def deleteHeldItems(self, objs):
		if not objs:
			return
		for obj in objs:
			obj.exist_flag = False
			del self._objs[obj.id]
			self._del([obj.id])
			ObjectHeldItem.HeldItemObjsMap.pop(obj.id, None)
		self.game.role.held_items = map(lambda o: o.id, self._objs.itervalues())
		for obj in objs:
			obj.delete_async()

	def getCostHeldItems(self, itemID, count, consumer=None):
		objs = []
		for id, obj in self._objs.iteritems():
			if consumer and id == consumer: # 不能是自己
				continue
			if obj.held_item_id == itemID and obj.exist_flag and obj.canBeCost():
				objs.append(obj)
		if len(objs) < count:
			raise ClientError('held items not enough')
		objs = random.sample(objs, count)
		return objs

	def countLevelHeldItems(self, level):
		count = 0
		for heldItemID, _ in self._objs.iteritems():
			heldItem = self._objs.get(heldItemID, None)
			if heldItem:
				if heldItem.level >= level and heldItem.exist_flag:
					count += 1
		return count

	def countQualityHeldItems(self, quality):
		count = 0
		for heldItemID, _ in self._objs.iteritems():
			heldItem = self._objs.get(heldItemID, None)
			if heldItem:
				if csv.held_item.items[heldItem.held_item_id].quality == quality and heldItem.exist_flag:
					count += 1
		return count


#
# ObjectHeldItemsRebirth 重生
#
class ObjectHeldItemsRebirth(ObjectCardRebirthBase):

	def __init__(self, game, heldItem):
		ObjectBase.__init__(self, game)
		self.heldItem = heldItem

	def isValid(self):
		return True

	def rebirth(self):
		self.heldItem.sum_exp = 0
		self.heldItem.level = 1
		self.heldItem.advance = 0
		self.heldItem.cost_universal_items = {}

	def getReturnItems(self):
		items = {}
		# 强化返回金币
		items['gold'] = self.heldItem.sum_exp * ConstDefs.heldItemExpNeedGold
		# 强化返回材料
		exp = self.heldItem.sum_exp
		for itemID in xrange(2103, 2100, -1):
			cfg = csv.items[itemID]
			texp = cfg.specialArgsMap['heldItemExp']
			count = int(exp / texp)
			if count > 0:
				exp -= count * texp
				items[itemID] = count

		# 突破返回材料
		advanceCost = {}
		useUniversal = sum(self.heldItem.cost_universal_items.values())
		for i in xrange(0, self.heldItem.advance):
			costD = csv.held_item.advance[i]["costItemMap%d" % self.heldItem.advanceSeqID]
			for csvID, count in costD.iteritems():
				if HeldItemDefs.isHeldItemID(csvID) and useUniversal > 0:
					least = min(useUniversal, count)
					count -= least
					useUniversal -= least
			if count > 0:
				advanceCost[csvID] = advanceCost.get(csvID, 0) + count
		ObjectCardRebirthBase.dictSum(items, advanceCost)

		for itemID in items.keys():
			items[itemID] = int(math.ceil(ConstDefs.rebirthRetrunProportion3 * items[itemID]))

		# 突破使用的万能材料
		if ConstDefs.rebirthRetrunProportion4 > 0:
			universalItems = {}
			for itemID, count in self.heldItem.cost_universal_items.iteritems():
				universalItems[itemID] = int(math.ceil(count * ConstDefs.rebirthRetrunProportion4))
			ObjectCardRebirthBase.dictSum(items, universalItems)

		return items
