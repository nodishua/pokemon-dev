#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2014 YouMi Information Technology Inc.
'''

from framework import str2num_t
from framework.csv import csv, ErrDefs, ConstDefs
from framework.log import logger
from framework.object import ObjectBase
from game import ServerError, ClientError
from game.object import EquipDefs, ItemDefs, TargetDefs, AttrDefs
from game.object.game.costcsv import ObjectCostCSV
from game.object.game.calculator import zeros
from game.object.game.yyhuodong import ObjectYYHuoDongFactory
from game.globaldata import EquipExpToGold
from game.object.game.gain import ObjectCostAux, ObjectGainAux
import copy
from game.thinkingdata import ta
#
# ObjectEquip
#

class ObjectEquip(ObjectBase):

	EquipAdvanceMap = {}
	SignetAdvanceMap = {}

	@classmethod
	def classInit(cls):
		cls.EquipAdvanceMap = {}
		for i in csv.base_attribute.equip_advance:
			csvAdvance = csv.base_attribute.equip_advance[i]
			cls.EquipAdvanceMap[(csvAdvance.equip_id, csvAdvance.stage)] = csvAdvance

		cls.SignetAdvanceMap = {}
		for i in csv.base_attribute.equip_signet_advance:
			csvAdvance = csv.base_attribute.equip_signet_advance[i]
			cls.SignetAdvanceMap[(csvAdvance.advanceIndex, csvAdvance.advanceLevel)] = csvAdvance

	def __init__(self, game, card):
		ObjectBase.__init__(self, game)
		self.card = card

	def set(self, dic):
		self._equip = dic
		return self

	def init(self):
		self._csvEquip = csv.equips[self._equip['equip_id']]
		return ObjectBase.init(self)

	def getAttrs(self):
		ret = {}
		abilityCT = 0.0
		if self.ability > 0:
			abilityCT = str2num_t(self._csvEquip['abilityAttr'][self.ability-1])[1]
		for i in xrange(1, EquipDefs.attrGainMax + 1):
			typeSeq = 'attrType%d' % i
			attrID = self._csvEquip[typeSeq]
			if attrID == 0:
				continue

			numSeq = 'attrNum%d' % i
			advanceNumSeq = 'attrAdvanceNum%d' % i
			starSeq = 'attrStarNum%d' % i
			starC = 'attrStarC%d' % i
			numVT = str2num_t(self._csvEquip[numSeq][self.advance-1])
			advanceNumVT = str2num_t(self._csvEquip[advanceNumSeq][self.advance-1])
			advVT = (self.level * advanceNumVT[0], self.level * advanceNumVT[1])
			starVT = str2num_t(self._csvEquip[starSeq][self.star])
			starCT = self._csvEquip[starC][self.star]

			ret[attrID] = ((numVT[0]+advVT[0]+starVT[0])*starCT*(1+abilityCT), (numVT[1]+advVT[1]+starVT[1])*starCT*(1+abilityCT))

		# ??????
		if self.awake > 0:
			for i in xrange(1, 99):
				at = "awakeAttrType%d" % i
				if at not in self._csvEquip:
					break
				awakeAttrID = self._csvEquip[at]
				if not awakeAttrID:
					break
				# ?????????????????????
				awakeAttrNum = str2num_t(self._csvEquip["awakeAttrNum%d" % i][self.awake - 1])
				tempRet = ret.get(awakeAttrID, (0, 0))
				ret[awakeAttrID] = (tempRet[0] + awakeAttrNum[0], tempRet[1] + awakeAttrNum[1])

		# ????????????
		if self.signet > 0:
			for i in xrange(1, 99):
				at = "signetAttrType%d" % i
				if at not in self._csvEquip:
					break
				signetAttrID = self._csvEquip[at]
				if not signetAttrID:
					break
				signetAttrNum = str2num_t(self._csvEquip["signetAttrNum%d" % i][self.signet - 1])
				tempRet = ret.get(signetAttrID, (0, 0))
				ret[signetAttrID] = (tempRet[0] + signetAttrNum[0], tempRet[1] + signetAttrNum[1])

		# ????????????
		if self.awakeAbility > 0:
			for i in xrange(1, 99):
				at = "awakeAbilityAttrType%d" % i
				if at not in self._csvEquip:
					break
				awakeAbilityAttrID = self._csvEquip[at]
				if not awakeAbilityAttrID:
					break
				# ???????????????????????????
				awakeAbilityAttrNum = str2num_t(self._csvEquip["awakeAbilityAttrNum%d" % i][self.awakeAbility - 1])
				tempRet = ret.get(awakeAbilityAttrID, (0, 0))
				ret[awakeAbilityAttrID] = (tempRet[0] + awakeAbilityAttrNum[0], tempRet[1] + awakeAbilityAttrNum[1])

		return ret

	def getSignetAdvanceAttrs(self, scene):
		'''
		???????????? ????????????
		'''
		const = zeros()
		percent = zeros()
		if self.isSignetAdvanceAttr():
			for level in xrange(1, self.signetAdvance+1):
				cfgAdvance = self.getSignetAdvanceCfg(level)
				if scene in cfgAdvance.sceneType:
					for i in xrange(1, 99):
						at = "attrType%d" % i
						if at not in cfgAdvance:
							break
						attrTypeID = cfgAdvance[at]
						if not attrTypeID:
							break
						signetAttrNum = str2num_t(cfgAdvance["attrNum%d" % i])
						const[attrTypeID] += signetAttrNum[0]
						percent[attrTypeID] += signetAttrNum[1]
		return const, percent

	# ??????????????????
	def getAdvanceCost(self):
		csvAdvance = self.EquipAdvanceMap.get((self.equip_id,self.advance),None)
		if csvAdvance is None:
			raise ServerError('equip csv %d advance %d not exited!' % (self.equip_id, self.advance))
		return csvAdvance['costGold'], csvAdvance['costItemMap']

	# ??????????????????
	@property
	def advanceMax(self):
		return self._csvEquip.advanceMax

	def isRoleLevelReach(self):
		level = self._csvEquip.roleLevelMax[self.advance-1]
		return self.game.role.level >= level

	def advanceBy(self, count=1):
		'''
		????????????
		@param count: ????????????
		'''
		if self.level < self.strengthMax:
			raise ClientError(ErrDefs.advanceLevelNotEnough)
		if (self.advance + 1) > self.advanceMax:
			raise ClientError(ErrDefs.advanceMaxErr)
		if self.isRoleLevelReach() == False:
			raise ClientError(ErrDefs.advanceLevelNotEnough)
		gold, items = self.getAdvanceCost()
		if self.game.role.gold < gold:
			raise ClientError(ErrDefs.advanceGoldNotEnough)
		if not self.game.items.isEnough(items):
			raise ClientError(ErrDefs.advanceItemsNotEnough)

		realCount = 0
		for i in xrange(count):
			if (self.advance + 1) > self.advanceMax:
				break
			if self.isRoleLevelReach() == False:
				break
			if (self.equip_id, (self.advance + 1)) not in self.EquipAdvanceMap:
				raise ServerError('equip csv %d advance %d not exited!' % (self.equip_id, self.advance + 1))

			gold, items = self.getAdvanceCost()
			costAux = ObjectCostAux(self.game, items)
			costAux.gold += gold
			if costAux.isEnough():
				costAux.cost(src='equip_advance')
			else:
				break

			self._equip['advance'] += 1
			# record
			self.game.dailyRecord.equip_advance += 1
			realCount += 1

		self.updateExp()
		ObjectYYHuoDongFactory.onGeneralTask(self.game, TargetDefs.EquipAdvance, realCount)

	# ????????????ID
	@property
	def strengthSeqID(self):
		return self._csvEquip.strengthSeqID

	# ??????????????????
	def getStrengthCost(self):
		csvStrength = csv.base_attribute.equip_strength[self.level]
		goldField = 'costGold%d' % self.strengthSeqID
		itemField = 'costItemMap%d' % self.strengthSeqID
		return csvStrength[goldField], csvStrength[itemField]

	# ??????????????????
	@property
	def strengthMax(self):
		return self._csvEquip.strengthMax[self.advance-1]

	def strengthBy(self, count=1):
		'''
		????????????
		@param count: ????????????
		'''
		if (self.level + 1) > self.strengthMax:
			raise ClientError(ErrDefs.strengthMaxErr)

		gold, items = self.getStrengthCost()
		if self.game.role.gold < gold:
			raise ClientError(ErrDefs.strengthGoldNotEnough)
		if not self.game.items.isEnough(items):
			raise ClientError(ErrDefs.strengthItemsNotEnough)

		realCount = 0
		for i in xrange(count):
			if (self.level + 1) > self.strengthMax:
				break
			if (self.level + 1) not in csv.base_attribute.equip_strength:
				raise ServerError('equip csv %d level %d not exited!' % (self.equip_id, self.level + 1))

			gold, items = self.getStrengthCost()
			cost = ObjectCostAux(self.game, items)
			cost.gold += gold
			if not cost.isEnough():
				break
			cost.cost(src='equip_strengthBy')

			self._equip['level'] += 1
			self.game.dailyRecord.equip_strength += 1
			realCount += 1
		ObjectYYHuoDongFactory.onGeneralTask(self.game, TargetDefs.EquipStrength, realCount)

	# ????????????????????????
	def getStrengthExpCost(self):
		csvStrength = csv.base_attribute.equip_strength[self.level]
		expField = 'costExp%d' % self.strengthSeqID
		return csvStrength[expField]

	# ????????????
	def updateExp(self,exp=0):
		if self.exp == 0 and exp == 0:
			return
		if exp > 0:
			self._equip['exp'] += exp

		oldLevel = self._equip['level']
		while self.exp >= self.getStrengthExpCost():
			if (self.level + 1) > self.strengthMax:
				break
			if (self.level + 1) not in csv.base_attribute.equip_strength:
				break
			self._equip['exp'] -= self.getStrengthExpCost()
			self._equip['level'] += 1

		if oldLevel != self._equip['level']:
			self.card.onUpgradeEquip()

	def strengthByExp(self, costItemIDs):
		'''
		????????????????????????
		@param costItemIDs: ???????????????
		'''
		if (self.level + 1) not in csv.base_attribute.equip_strength:
			raise ServerError('equip csv %d level %d not exited!' % (self.equip_id, self.level + 1))

		expSum = 0
		for itemID, count in costItemIDs.iteritems():
			cfg = csv.items[itemID]
			if cfg.type != ItemDefs.equipStrengthType:
				raise ClientError('item type is not 4')
			expSum += cfg.specialArgsMap['strength_exp'] * count

		if expSum <= 0:
			raise ClientError(ErrDefs.starNoExp)

		needGold = expSum * EquipExpToGold
		cost = ObjectCostAux(self.game, costItemIDs)
		cost.gold += needGold
		if not cost.isEnough():
			raise ClientError("cost is not enough")
		cost.cost(src='equip_strengthByExp')

		self.updateExp(expSum)

	# ????????????
	@property
	def starMax(self):
		return self._csvEquip.starMax

	# ???????????????
	@property
	def starSeqID(self):
		return self._csvEquip.starSeqID

	# ??????????????????
	def getStarCost(self):
		csvStar = csv.base_attribute.equip_star[self.star]
		itemField = 'costItemMap%d' % self.starSeqID
		return csvStar[itemField]

	def raiseStarBy(self, count=1):
		'''
		????????????
		@param count: ????????????
		'''
		oldFightingPoint = self.card.fighting_point
		for i in xrange(count):
			if (self.star + 1) > self.starMax:
				raise ClientError(ErrDefs.starMaxErr)
			if (self.star + 1) not in csv.base_attribute.equip_star:
				raise ServerError('equip csv %d star %d not exited!' % (self.equip_id, self.star + 1))

			items = self.getStarCost()
			cost = ObjectCostAux(self.game, items)
			if not cost.isEnough():
				raise ClientError(ErrDefs.starItemsNotEnough)
			cost.cost(src='equip_raise_star')
			self._equip['star'] += 1

		addFightingPoint = self.card.fighting_point - oldFightingPoint
		ta.equip(self, event='card_equip_star_up',addFightingPoint=addFightingPoint)

		ObjectYYHuoDongFactory.onGeneralTask(self.game, TargetDefs.EquipStar, count)
		ObjectYYHuoDongFactory.onGeneralTask(self.game, TargetDefs.EquipStarCount, count)

	def dropStar(self):
		'''
		????????????
		'''
		isAbility = False
		if self.ability > 0:
			isAbility = True
		count = self.star
		if isAbility:
			costRMB = ObjectCostCSV.getEquipDropCost(self.starMax + self.ability - 1)
			src = 'item_drop_equip_ability'
		else:
			costRMB = ObjectCostCSV.getEquipDropCost(self.star - 1)
			src = 'card_equip_star_down'
		cost = ObjectCostAux(self.game, {'rmb': costRMB})
		if not cost.isEnough():
			raise ClientError('cost rmb can not enough')

		# ????????????
		effAbility = ObjectGainAux(self.game, {})
		if isAbility:
			for i in xrange(self.ability):
				if (self.ability - 1) < 0:
					raise ClientError(ErrDefs.abilityDropErr)
				if (self.ability - 1) not in csv.base_attribute.equip_ability:
					raise ServerError('equip csv %d ability %d not exited!' % (self.equip_id, self.ability - 1))

				self._equip['ability'] -= 1
				items = self.getAbilityCost()
				effAbility += ObjectGainAux(self.game, items)

		# ??????
		effStar = ObjectGainAux(self.game, {})
		for i in xrange(self.star):
			if (self.star - 1) < 0:
				raise ClientError(ErrDefs.starDropErr)
			if (self.star - 1) not in csv.base_attribute.equip_star:
				raise ServerError('equip csv %d star %d not exited!' % (self.equip_id, self.star - 1))

			self._equip['star'] -= 1
			items = self.getStarCost()
			effStar += ObjectGainAux(self.game, items)

		# ??????
		cost.cost(src=src)
		# ??????
		if isAbility:
			effStar += effAbility
		effStar.gain(src='item_drop_star')  # ??????????????????????????????????????????????????????????????????gain

		ta.equip(self, event='card_equip_star_down')
		ObjectYYHuoDongFactory.onGeneralTask(self.game, TargetDefs.EquipStarCount, count)

	# ??????????????????
	@property
	def awakeMax(self):
		return self._csvEquip.awakeMax

	# ???????????????
	@property
	def awakeSeqID(self):
		return self._csvEquip.awakeSeqID

	# ??????????????????
	def getAwakeCost(self):
		csvAwake = csv.base_attribute.equip_awake[self.awake]
		itemField = 'costItemMap%d' % self.awakeSeqID
		return csvAwake[itemField]

	def onEquipAwake(self):
		'''
		????????????
		'''
		# ???????????????
		if (self.awake + 1) > self.awakeMax:
			raise ClientError('full awake! can not awake again')
		# ????????????????????????
		if self._csvEquip.awakeRoleLevelMax and self._csvEquip.awakeStar:
			if self._csvEquip.awakeRoleLevelMax[self.awake] > self.game.role.level or self._csvEquip.awakeStar[self.awake] > self.star:
				raise ClientError('awake can not satisfy the conditions')
		else:
			raise ClientError('awake csv conditions can not None')

		# ???????????????????????????????????????
		costItems = self.getAwakeCost()
		cost = ObjectCostAux(self.game, costItems)
		if not cost.isEnough():
			raise ClientError('awake items can not enough')
		cost.cost(src='equip_awake')
		self._equip['awake'] += 1
		ta.equip(self, event='card_equip_awake_up',cost=cost)

	def dropAwake(self):
		'''
		??????????????????
		'''
		isAbility = False
		if self.awakeAbility > 0:
			isAbility = True
		count = self.awake
		if isAbility:
			costRMB = ObjectCostCSV.getEquipDropCost(self.awakeMax + self.awakeAbility - 1)
			src = 'item_drop_equip_awake_ability'
		else:
			costRMB = ObjectCostCSV.getEquipDropCost(self.awake - 1)
			src = 'card_equip_awake_down'
		cost = ObjectCostAux(self.game, {'rmb': costRMB})
		if not cost.isEnough():
			raise ClientError('cost rmb can not enough')

		# ????????????
		effAbility = ObjectGainAux(self.game, {})
		if isAbility:
			for i in xrange(self.awakeAbility):
				if (self.awakeAbility - 1) < 0:
					raise ClientError(ErrDefs.abilityDropErr)
				if (self.awakeAbility - 1) not in csv.base_attribute.equip_awake_ability:
					raise ServerError('equip csv %d awake_ability %d not exited!' % (self.equip_id, self.awakeAbility - 1))

				self._equip['awake_ability'] -= 1
				items = self.getAwakeAbilityCost()
				effAbility += ObjectGainAux(self.game, items)

		# ??????
		effAwake = ObjectGainAux(self.game, {})
		for i in xrange(self.awake):
			if (self.awake - 1) < 0:
				raise ClientError('drop error')
			if (self.awake - 1) not in csv.base_attribute.equip_awake:
				raise ServerError('equip csv %d awake %d not exited!' % (self.equip_id, self.awake - 1))

			self._equip['awake'] -= 1
			items = self.getAwakeCost()
			effAwake += ObjectGainAux(self.game, items)

		# ??????
		cost.cost(src=src)
		# ??????
		if isAbility:
			effAwake += effAbility
		effAwake.gain(src='item_drop_awake')  # ??????????????????????????????????????????????????????????????????gain

		ta.equip(self, event='card_equip_awake_down',count=count)

	# ??????????????????
	@property
	def abilityMax(self):
		return self._csvEquip.abilityMax

	# ???????????????
	@property
	def abilitySeqID(self):
		return self._csvEquip.abilitySeqID

	# ??????????????????
	def getAbilityCost(self):
		csvAbility = csv.base_attribute.equip_ability[self.ability]
		itemField = 'costItemMap%d' % self.abilitySeqID
		return csvAbility[itemField]

	def onEquipAbility(self, level):
		'''
		??????????????????
		'''
		# ???????????????
		if (self.ability + level) > self.abilityMax:
			raise ClientError('full ability! can not ability again')
		# ????????????????????????
		if self.star < self._csvEquip.starMax:
			raise ClientError('not full star')

		# ????????????
		for i in xrange(level):
			costItems = self.getAbilityCost()
			cost = ObjectCostAux(self.game, costItems)
			if not cost.isEnough():
				raise ClientError('ability items can not enough')
			cost.cost(src='equip_ability')
			self._equip['ability'] += 1

	# ????????????????????????
	@property
	def signetStrengthMax(self):
		return self._csvEquip.signetStrengthMax[self.signetAdvance]

	# ???????????????????????????
	@property
	def signetStrengthSeqID(self):
		return self._csvEquip.signetStrengthSeqID

	# ????????????????????????
	def getSignetStrengthCost(self):
		csvSignet = csv.base_attribute.equip_signet[self.signet]
		itemField = 'costItemMap%d' % self.signetStrengthSeqID
		return csvSignet[itemField]

	def onEquipSignetStrength(self, count=1):
		'''
		??????????????????
		'''
		# ???????????????????????????????????????
		if (self.signet + count) > self.signetStrengthMax:
			raise ClientError('full signet strength! can not signet strength again')

		# ??????????????????????????????
		signetStrengthMin = self._csvEquip.signetStrengthMax[self.signetAdvance-1] if self.signetAdvance > 0 else 0
		if signetStrengthMin > self.signet or self.signetStrengthMax < self.signet:
			raise ClientError('signet level error')

		# ????????????
		for i in xrange(count):
			costItems = self.getSignetStrengthCost()
			cost = ObjectCostAux(self.game, costItems)
			if not cost.isEnough():
				break
			cost.cost(src='equip_signet_strength')
			self._equip['signet'] += 1

	# ????????????????????????
	@property
	def signetAdvanceMax(self):
		return self._csvEquip.signetAdvanceMax

	# ??????????????????
	def getSignetAdvanceCfg(self, signetAdvance):
		advanceIndex = self._csvEquip.advanceIndex
		return self.SignetAdvanceMap[(advanceIndex, signetAdvance)]

	# ????????????????????????
	def getSignetAdvanceCost(self):
		csvSignetCost = csv.base_attribute.equip_signet_advance_cost[self.signetAdvance]
		cfgAdvance = self.getSignetAdvanceCfg(self.signetAdvance + 1)
		itemField = 'costItemMap%d' % cfgAdvance.advanceSeqID
		return csvSignetCost[itemField]

	# ????????????????????????
	def isSignetAdvanceAttr(self):
		if self.signetAdvance <= 0:
			return False
		cfgAdvance = self.getSignetAdvanceCfg(self.signetAdvance)
		if cfgAdvance.advanceLimitType == EquipDefs.SignetAdvanceLimitStar:
			if self.star < cfgAdvance.advanceLimitNum:
				return False
		elif cfgAdvance.advanceLimitType == EquipDefs.SignetAdvanceLimitAwake:
			if self.awake < cfgAdvance.advanceLimitNum:
				return False
		return True

	def onEquipSignetAdvance(self):
		'''
		??????????????????
		'''
		# ?????????????????????
		if (self.signetAdvance + 1) > self.signetAdvanceMax:
			raise ClientError('full signet advance! can not signet advance again')
		# ????????????
		costItems = self.getSignetAdvanceCost()
		cost = ObjectCostAux(self.game, costItems)
		if not cost.isEnough():
			return True
		cost.cost(src='equip_signet_advance')
		self._equip['signet_advance'] += 1
		return False

	def dropSignet(self):
		'''
		???????????????
		'''
		eff = ObjectGainAux(self.game, {})
		costRMB = ObjectCostCSV.getEquipDropCost(self.signet - 1)
		cost = ObjectCostAux(self.game, {'rmb': costRMB})
		if not cost.isEnough():
			raise ClientError('cost rmb can not enough')
		# ??????
		for i in xrange(self.signet):
			if (self.signet - 1) < 0:
				raise ClientError(ErrDefs.signetDropErr)
			if (self.signet - 1) not in csv.base_attribute.equip_signet:
				raise ServerError('equip csv %d signet %d not exited!' % (self.equip_id, self.signet - 1))
			self._equip['signet'] -= 1
			items = self.getSignetStrengthCost()
			eff += ObjectGainAux(self.game, items)
		cost.cost(src='item_drop_signet')
		# ??????
		for i in xrange(self.signetAdvance):
			if (self.signetAdvance - 1) < 0:
				raise ClientError(ErrDefs.signetDropErr)
			if (self.signetAdvance - 1) not in csv.base_attribute.equip_signet_advance_cost:
				raise ServerError('equip csv %d signetAdvance %d not exited!' % (self.equip_id, self.signetAdvance - 1))
			self._equip['signet_advance'] -= 1
			itemsAdvance = self.getSignetAdvanceCost()
			eff += ObjectGainAux(self.game, itemsAdvance)

		eff.gain(src='item_drop_signet')  # ??????????????????????????????????????????????????????????????????gain

	# ????????????????????????
	@property
	def awakeAbilityMax(self):
		return self._csvEquip.awakeAbilityMax

	# ?????????????????????
	@property
	def awakeAbilitySeqID(self):
		return self._csvEquip.awakeAbilitySeqID

	# ????????????????????????
	def getAwakeAbilityCost(self):
		csvAwakeAbility = csv.base_attribute.equip_awake_ability[self.awakeAbility]
		itemField = 'costItemMap%d' % self.awakeAbilitySeqID
		return csvAwakeAbility[itemField]

	def onEquipAwakeAbility(self, level):
		'''
		??????????????????
		'''
		# ?????????????????????
		if (self.awakeAbility + level) > self.awakeAbilityMax:
			raise ClientError('full awake ability! can not awake ability again')
		# ????????????????????????
		if self.awake < self._csvEquip.awakeMax:
			raise ClientError('not full awake')

		# ????????????
		for i in xrange(level):
			costItems = self.getAwakeAbilityCost()
			cost = ObjectCostAux(self.game, costItems)
			if not cost.isEnough():
				raise ClientError('awake ability items can not enough')
			cost.cost(src='equip_awake_ability')
			self._equip['awake_ability'] += 1

	@property
	def equip_id(self):
		return self._equip['equip_id']

	@property
	def level(self):
		return self._equip['level']

	@property
	def advance(self):
		return self._equip['advance']

	@property
	def star(self):
		return self._equip['star']

	@property
	def exp(self):
		return self._equip['exp']

	@property
	def awake(self):
		return self._equip['awake']

	@property
	def ability(self):
		return self._equip.setdefault('ability', 0)

	@property
	def signet(self):
		return self._equip.setdefault('signet', 0)

	@property
	def signetAdvance(self):
		return self._equip.setdefault('signet_advance', 0)

	@property
	def awakeAbility(self):
		return self._equip.setdefault('awake_ability', 0)

