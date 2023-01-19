#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2014 YouMi Information Technology Inc.
'''

from framework import nowtime_t
from framework.csv import csv, ConstDefs
from framework.log import logger
from framework.object import ObjectBase
from framework.helper import objectid2string
from game.globaldata import StashCardMailID
from game import ServerError
from game.object import FragmentDefs, EquipDefs, ItemDefs, HeldItemDefs, GemDefs, ZawakeDefs, ChipDefs
from game.thinkingdata import ta

import copy
from math import ceil

def pack(argsD):
	if not argsD:
		return argsD
	ret = {}
	for csvID, count in argsD.iteritems():
		if isinstance(csvID, int):
			ret.setdefault('type1', {})[csvID] = count
		elif isinstance(csvID, str):
			if csvID == 'card' or csvID == 'cards' or csvID == 'libs' or csvID == 'star_skill_points':
				ret[csvID] = count
			else:
				ret.setdefault('type2', {})[csvID] = count
	return ret

def unpack(argsD):
	argsD = copy.deepcopy(argsD)
	type1 = argsD.pop('type1', None)
	type2 = argsD.pop('type2', None)
	if type1:
		for k, v in type1.iteritems():
			argsD[k] = v
	if type2:
		for k, v in type2.iteritems():
			argsD[k] = v
	return argsD

def checkCardValid(cardid):
	import framework
	if hasattr(framework, '__dev__'):
		cfg = csv.cards[cardid]
		if framework.__language__ not in cfg.languages:
			raise ServerError('card %d not in %s' % (cardid, framework.__language__))

class ObjectGoodsMap(ObjectBase):
	'''
	所有道具、碎片等参数map形式的配置处理基类
	'''

	def __init__(self, game, argsD):
		ObjectBase.__init__(self, game)

		self._ceil = False

		self._gemsL = []
		self._chipsL = []
		self._heldItemsL = []
		self._cardsL = []
		self._itemsD = {}
		self._fragsD = {}
		self._zfragsD = {}
		self._gold = 0
		self._exp = 0
		self._role_exp = 0
		self._stamina = 0
		self._skill_point = 0
		self._rmb = 0
		self._recharge_rmb = 0
		self._coin1 = 0
		self._coin2 = 0
		self._coin3 = 0
		self._coin4 = 0
		self._coin5 = 0
		self._coin6 = 0
		self._coin7 = 0
		self._coin8 = 0
		self._coin9 = 0
		self._coin10 = 0
		self._coin11 = 0
		self._coin12 = 0
		self._coin13 = 0
		self._coin14 = 0
		self._talent_point = 0
		self._equip_awake_frag = 0
		self._draw_libs = []
		self._star_skill_points = {}
		self._gym_talent_point = 0

		for csvID, count in argsD.iteritems():
			# check value type
			if csvID not in ('card', 'cards', 'libs', 'star_skill_points') and not isinstance(count, int):
				raise ServerError('goods (%s, %s) invalid' % (csvID, count))
			if isinstance(count, int) and count < 0:
				raise ServerError('goods (%s, %s) cheat' % (csvID, count))

			if isinstance(csvID, int):
				if FragmentDefs.isFragmentID(csvID):
					self._fragsD[csvID] = count
				elif ItemDefs.isItemID(csvID):
					self._itemsD[csvID] = count
				elif HeldItemDefs.isHeldItemID(csvID):
					self._heldItemsL += [csvID for i in xrange(count)]
				elif GemDefs.isGemID(csvID):
					self._gemsL += [csvID for i in xrange(count)]
				elif ZawakeDefs.isZFragID(csvID):
					self._zfragsD[csvID] = count
				elif ChipDefs.isChipID(csvID):
					self._chipsL += [csvID for i in xrange(count)]
			else:
				if csvID == 'gold':
					self._gold = count
				elif csvID == 'exp':
					self._exp = count
				elif csvID == 'role_exp':
					self._role_exp = count
				elif csvID == 'stamina':
					self._stamina = count
				elif csvID == 'skill_point':
					self._skill_point = count
				elif csvID == 'rmb':
					self._rmb = count
				elif csvID == 'recharge_rmb':
					self._recharge_rmb = count
				elif csvID == 'coin1':
					self._coin1 = count
				elif csvID == 'coin2':
					self._coin2 = count
				elif csvID == 'coin3':
					self._coin3 = count
				elif csvID == 'coin4':
					self._coin4 = count
				elif csvID == 'coin5':
					self._coin5 = count
				elif csvID == 'coin6':
					self._coin6 = count
				elif csvID == 'coin7':
					self._coin7 = count
				elif csvID == 'coin8':
					self._coin8 = count
				elif csvID == 'coin9':
					self._coin9 = count
				elif csvID == 'coin10':
					self._coin10 = count
				elif csvID == 'coin11':
					self._coin11 = count
				elif csvID == 'coin12':
					self._coin12 = count
				elif csvID == 'coin13':
					self._coin13 = count
				elif csvID == 'coin14':
					self._coin14 = count
				elif csvID == 'talent_point':
					self._talent_point = count
				elif csvID == 'equip_awake_frag':
					self._equip_awake_frag = count
				elif csvID == 'cards':
					cards = count
					for x in cards:
						checkCardValid(x['id'])
						self._cardsL.append(x)
				elif csvID == 'card':
					# count 内容为 {'id': 卡牌csvID, 'star': 星数(可选)}
					checkCardValid(count['id'])
					self._cardsL.append(count)
				elif csvID == 'libs':
					libs = count
					for x in libs:
						self._draw_libs.append(x)
				elif csvID == 'lib':
					self._draw_libs.append(count)
				elif csvID == 'star_skill_points':
					points = count
					for k, v in points.iteritems():
						self._star_skill_points[k] = v
				elif csvID == 'gym_talent_point':
					self._gym_talent_point = count
		self.checkValid()

	def __iadd__(self, val):
		if not isinstance(val, ObjectGoodsMap):
			raise ValueError('value is not ObjectGoodsMap')

		self._gold += val._gold
		self._exp += val._exp
		self._role_exp += val._role_exp
		self._stamina += val._stamina
		self._skill_point += val._skill_point
		self._rmb += val._rmb
		self.recharge_rmb += val._recharge_rmb
		self._coin1 += val._coin1
		self._coin2 += val._coin2
		self._coin3 += val._coin3
		self._coin4 += val._coin4
		self._coin5 += val._coin5
		self._coin6 += val._coin6
		self._coin7 += val._coin7
		self._coin8 += val._coin8
		self._coin9 += val._coin9
		self._coin10 += val._coin10
		self._coin11 += val._coin11
		self._coin12 += val._coin12
		self._coin13 += val._coin13
		self._coin14 += val._coin14
		self._talent_point += val._talent_point
		self._equip_awake_frag += val._equip_awake_frag
		self._heldItemsL += val._heldItemsL
		self._gemsL += val._gemsL
		self._chipsL += val._chipsL
		self._cardsL += val._cardsL
		for k, v in val._fragsD.iteritems():
			self._fragsD[k] = self._fragsD.get(k, 0) + v
		for k, v in val._zfragsD.iteritems():
			self._zfragsD[k] = self._zfragsD.get(k, 0) + v
		for k, v in val._itemsD.iteritems():
			self._itemsD[k] = self._itemsD.get(k, 0) + v
		self._draw_libs += val._draw_libs
		for k, v in val._star_skill_points.iteritems():
			self._star_skill_points[k] = self._star_skill_points.get(k, 0) + v
		self._gym_talent_point += val._gym_talent_point
		self.checkValid()
		return self

	def __isub__(self, val):
		if not isinstance(val, ObjectGoodsMap):
			raise ValueError('value is not ObjectGoodsMap')

		if any([
			self._gemsL, val._gemsL,
			self._chipsL, val._chipsL,
			self._heldItemsL, val._heldItemsL,
			self._cardsL, val._cardsL,
			self._draw_libs, val._draw_libs,
		]):
			raise ValueError('unsupported')

		self._gold -= val._gold
		self._exp -= val._exp
		self._role_exp -= val._role_exp
		self._stamina -= val._stamina
		self._skill_point -= val._skill_point
		self._rmb -= val._rmb
		self.recharge_rmb -= val._recharge_rmb
		self._coin1 -= val._coin1
		self._coin2 -= val._coin2
		self._coin3 -= val._coin3
		self._coin4 -= val._coin4
		self._coin5 -= val._coin5
		self._coin6 -= val._coin6
		self._coin7 -= val._coin7
		self._coin8 -= val._coin8
		self._coin9 -= val._coin9
		self._coin10 -= val._coin10
		self._coin11 -= val._coin11
		self._coin12 -= val._coin12
		self._coin13 -= val._coin13
		self._coin14 -= val._coin14
		self._talent_point -= val._talent_point
		self._equip_awake_frag -= val._equip_awake_frag

		for k, v in val._fragsD.iteritems():
			self._fragsD[k] = self._fragsD[k] - v

		for k, v in val._zfragsD.iteritems():
			self._zfragsD[k] = self._zfragsD[k] - v

		for k, v in val._itemsD.iteritems():
			self._itemsD[k] = self._itemsD[k] - v

		for k, v in val._star_skill_points.iteritems():
			self._star_skill_points[k] = self._star_skill_points[k] - v
		self._gym_talent_point -= val._gym_talent_point

		self.checkValid()
		return self

	def __mul__(self, num):
		tmp = type(self)(self._game, {})
		tmp += self
		tmp *= num
		return tmp

	def __imul__(self, num):
		if num < 0:
			raise ServerError('negative is invalid')
		if num == 1:
			return self

		if self._ceil: # 主要是用于消耗上
			self._gold = int(ceil(self._gold * num))
			self._exp = int(ceil(self._exp * num))
			self._role_exp = int(ceil(self._role_exp * num))
			self._stamina = int(ceil(self._stamina * num))
			self._skill_point = int(ceil(self._skill_point * num))
			self._rmb = int(ceil(self._rmb * num))
			self._recharge_rmb = int(ceil(self._recharge_rmb * num))
			self._coin1 = int(ceil(self._coin1 * num))
			self._coin2 = int(ceil(self._coin2 * num))
			self._coin3 = int(ceil(self._coin3 * num))
			self._coin4 = int(ceil(self._coin4 * num))
			self._coin5 = int(ceil(self._coin5 * num))
			self._coin6 = int(ceil(self._coin6 * num))
			self._coin7 = int(ceil(self._coin7 * num))
			self._coin8 = int(ceil(self._coin8 * num))
			self._coin9 = int(ceil(self._coin9 * num))
			self._coin10 = int(ceil(self._coin10 * num))
			self._coin11 = int(ceil(self._coin11 * num))
			self._coin12 = int(ceil(self._coin12 * num))
			self._coin13 = int(ceil(self._coin13 * num))
			self._coin14 = int(ceil(self._coin14 * num))
			self._talent_point = int(ceil(self._talent_point * num))
			self._equip_awake_frag = int(ceil(self._equip_awake_frag * num))
			for k, v in self._fragsD.iteritems():
				self._fragsD[k] = int(ceil(v * num))
			for k, v in self._zfragsD.iteritems():
				self._zfragsD[k] = int(ceil(v * num))
			for k, v in self._itemsD.iteritems():
				self._itemsD[k] = int(ceil(v * num))
			for k, v in self._star_skill_points.iteritems():
				self._star_skill_points[k] = int(ceil(v * num))
			self._gym_talent_point = int(ceil(self._gym_talent_point * num))
		else:
			self._gold = int(self._gold * num)
			self._exp = int(self._exp * num)
			self._role_exp = int(self._role_exp * num)
			self._stamina = int(self._stamina * num)
			self._skill_point = int(self._skill_point * num)
			self._rmb = int(self._rmb * num)
			self._recharge_rmb = int(self._recharge_rmb * num)
			self._coin1 = int(self._coin1 * num)
			self._coin2 = int(self._coin2 * num)
			self._coin3 = int(self._coin3 * num)
			self._coin4 = int(self._coin4 * num)
			self._coin5 = int(self._coin5 * num)
			self._coin6 = int(self._coin6 * num)
			self._coin7 = int(self._coin7 * num)
			self._coin8 = int(self._coin8 * num)
			self._coin9 = int(self._coin9 * num)
			self._coin10 = int(self._coin10 * num)
			self._coin11 = int(self._coin11 * num)
			self._coin12 = int(self._coin12 * num)
			self._coin13 = int(self._coin13 * num)
			self._coin14 = int(self._coin14 * num)
			self._talent_point = int(self._talent_point * num)
			self._equip_awake_frag = int(self._equip_awake_frag * num)
			for k, v in self._fragsD.iteritems():
				self._fragsD[k] = int(v * num)
			for k, v in self._zfragsD.iteritems():
				self._zfragsD[k] = int(v * num)
			for k, v in self._itemsD.iteritems():
				self._itemsD[k] = int(v * num)
			for k, v in self._star_skill_points.iteritems():
				self._star_skill_points[k] = int(v * num)
			self._gym_talent_point = int(self._gym_talent_point * num)

		self._gemsL *= int(num)
		self._chipsL *= int(num)
		self._heldItemsL *= int(num)
		self._cardsL *= int(num)
		self._draw_libs *= int(num)

		self.checkValid()
		return self

	def to_dict(self):
		ret = {}
		if self._gold != 0:
			ret['gold'] = int(self._gold)
		if self._exp != 0:
			ret['exp'] = int(self._exp)
		if self._role_exp != 0:
			ret['role_exp'] = int(self._role_exp)
		if self._stamina != 0:
			ret['stamina'] = int(self._stamina)
		if self._skill_point != 0:
			ret['skill_point'] = int(self._skill_point)
		if self._rmb != 0:
			ret['rmb'] = int(self._rmb)
		if self._recharge_rmb != 0:
			ret['recharge_rmb'] = int(self._recharge_rmb)
		if self._coin1 != 0:
			ret['coin1'] = int(self._coin1)
		if self._coin2 != 0:
			ret['coin2'] = int(self._coin2)
		if self._coin3 != 0:
			ret['coin3'] = int(self._coin3)
		if self._coin4 != 0:
			ret['coin4'] = int(self._coin4)
		if self._coin5 != 0:
			ret['coin5'] = int(self._coin5)
		if self._coin6 != 0:
			ret['coin6'] = int(self._coin6)
		if self._coin7 != 0:
			ret['coin7'] = int(self._coin7)
		if self._coin8 != 0:
			ret['coin8'] = int(self._coin8)
		if self._coin9 != 0:
			ret['coin9'] = int(self._coin9)
		if self._coin10 != 0:
			ret['coin10'] = int(self._coin10)
		if self._coin11 != 0:
			ret['coin11'] = int(self._coin11)
		if self._coin12 != 0:
			ret['coin12'] = int(self._coin12)
		if self._coin13 != 0:
			ret['coin13'] = int(self._coin13)
		if self._coin14 != 0:
			ret['coin14'] = int(self._coin14)
		if self._talent_point != 0:
			ret['talent_point'] = int(self._talent_point)
		if self._equip_awake_frag != 0:
			ret['equip_awake_frag'] = int(self._equip_awake_frag)
		if self._cardsL:
			ret['cards'] = self._cardsL
		for k, v in self._fragsD.iteritems():
			ret[k] = v
		for k, v in self._zfragsD.iteritems():
			ret[k] = v
		for k, v in self._itemsD.iteritems():
			ret[k] = v
		for k in self._heldItemsL:
			ret[k] = ret.get(k, 0) + 1
		for k in self._gemsL:
			ret[k] = ret.get(k, 0) + 1
		for k in self._chipsL:
			ret[k] = ret.get(k, 0) + 1
		if self._draw_libs:
			ret['libs'] = self._draw_libs
		if self._star_skill_points:
			ret['star_skill_points'] = self._star_skill_points
		if self._gym_talent_point != 0:
			ret['gym_talent_point'] = int(self._gym_talent_point)
		return ret

	def checkValid(self):
		invalid = False
		invalid = invalid or self._gold < 0
		invalid = invalid or self._exp < 0
		invalid = invalid or self._role_exp < 0
		invalid = invalid or self._stamina < 0
		invalid = invalid or self._skill_point < 0
		invalid = invalid or self._rmb < 0
		invalid = invalid or self._recharge_rmb < 0
		invalid = invalid or self._coin1 < 0
		invalid = invalid or self._coin2 < 0
		invalid = invalid or self._coin3 < 0
		invalid = invalid or self._coin4 < 0
		invalid = invalid or self._coin5 < 0
		invalid = invalid or self._coin6 < 0
		invalid = invalid or self._coin7 < 0
		invalid = invalid or self._coin8 < 0
		invalid = invalid or self._coin9 < 0
		invalid = invalid or self._coin10 < 0
		invalid = invalid or self._coin11 < 0
		invalid = invalid or self._coin12 < 0
		invalid = invalid or self._coin13 < 0
		invalid = invalid or self._coin14 < 0
		invalid = invalid or self._talent_point < 0
		invalid = invalid or self._equip_awake_frag < 0
		invalid = invalid or self._gym_talent_point < 0

		for k, v in self._itemsD.iteritems():
			invalid = invalid or v < 0
		for k, v in self._fragsD.iteritems():
			invalid = invalid or v < 0
		for k, v in self._zfragsD.iteritems():
			invalid = invalid or v < 0
		for k, v in self._star_skill_points.iteritems():
			invalid = invalid or v < 0

		# cards, heldItems, draw_libs, gems

		if invalid:
			raise ValueError('negative is invalid')

	def setCeil(self):
		self._ceil = True

	def exp():
		def fget(self):
			return int(self._exp)
		def fset(self, value):
			self._exp = int(value)
		return locals()
	exp = property(**exp())

	def role_exp():
		def fget(self):
			return int(self._role_exp)
		def fset(self, value):
			self._role_exp = int(value)
		return locals()
	role_exp = property(**role_exp())

	def stamina():
		def fget(self):
			return int(self._stamina)
		def fset(self, value):
			self._stamina = int(value)
		return locals()
	stamina = property(**stamina())

	def gold():
		def fget(self):
			return int(self._gold)
		def fset(self, value):
			self._gold = int(value)
		return locals()
	gold = property(**gold())

	def rmb():
		def fget(self):
			return int(self._rmb)
		def fset(self, value):
			self._rmb = int(value)
		return locals()
	rmb = property(**rmb())

	def recharge_rmb():
		def fget(self):
			return int(self._recharge_rmb)
		def fset(self, value):
			self._recharge_rmb = int(value)
		return locals()
	recharge_rmb = property(**recharge_rmb())

	def items():
		def fget(self):
			return self._itemsD
		return locals()
	items = property(**items())


class ObjectGainAux(ObjectGoodsMap):
	'''
	所有奖励的道具、碎片、卡牌等参数map形式的配置处理辅助
	邮件，包括发给自己或者他人的，由role_db_id来定
	'''

	def __init__(self, game, argsD):
		ObjectGoodsMap.__init__(self, game, argsD)
		self._dbCardsL = None
		self._newCardsL = []
		self._cardFragL = []
		self._dbHeldItemsL = []
		self._newHeldItemsL = []
		self._dbGemsL = []
		self._newGemsL = []
		self._dbChipsL = []
		self._newChipsL = []
		self._stashCardsL = [] # 暂存卡牌列表
		self._regainD = {} # 重复获得

	@property
	def cards(self):
		return self._cardsL

	@property
	def heldItemIDs(self):
		return self._heldItemsL

	@property
	def gemIDs(self):
		return self._gemsL

	@property
	def chipIDs(self):
		return self._chipsL

	@property
	def coin13(self):
		return self._coin13

	def splitCards(self):
		'''
		分离需要创建的卡牌和需要暂存的卡牌
		'''
		free = self.game.role.card_capacity_free
		self._stashCardsL = self._cardsL[free:]
		return self._cardsL[:free], self._stashCardsL

	def setCardsDBL(self, cardsL):
		'''
		外部生成数据库卡牌数据
		'''
		if not isinstance(cardsL, list):
			cardsL = [cardsL]
		self._dbCardsL = cardsL
		self._newCardsL = [(o['id'], o['card_id'] not in self.game.role.pokedex) for o in cardsL]

	def setHeldItemsDBL(self, heldItemsL):
		'''
		外部生成数据库携带道具数据
		'''
		if not isinstance(heldItemsL, list):
			heldItemsL = [heldItemsL]
		self._dbHeldItemsL = heldItemsL
		self._newHeldItemsL = [o['id'] for o in heldItemsL]

	def setGemsDBL(self, gemsL):
		'''
		外部生成宝石数据库数据
		'''
		if not isinstance(gemsL, list):
			gemsL = [gemsL]
		self._dbGemsL = gemsL
		self._newGemsL = [o['id'] for o in gemsL]

	def setChipsDBL(self, chipsL):
		'''
		外部生成芯片数据库数据
		'''
		if not isinstance(chipsL, list):
			chipsL = [chipsL]
		self._dbChipsL = chipsL
		self._newChipsL = [o['id'] for o in chipsL]

	# 暂存卡牌转碎片
	def card2frag(self, card):
		cfg = csv.cards[card['id']]
		getStar = card.get('star', cfg.star)
		from game.object.game.card import ObjectCard
		starFragCfg = ObjectCard.getStarFragCfg(cfg.fragNumType, getStar)
		fragNum = starFragCfg.baseFragNum
		if cfg.fragID == 0 or fragNum == 0:
			raise ServerError('cards.csv no fragID or fragNum value')
		self._fragsD[cfg.fragID] = self._fragsD.get(cfg.fragID, 0) + fragNum
		self._cardFragL += [(cfg.fragID, fragNum, card['id'])]
		return fragNum

	#内存中直接使用
	def imDirectUse(self):
		from game.object.game.item import ObjectItemEffectFactory
		types = (ItemDefs.roleDisplayType, ItemDefs.skinInMemType)
		items = [k for k, _ in self._itemsD.iteritems() if csv.items[k].type in types]
		for itemID in items:
			count = self._itemsD[itemID] # 不pop掉，addItems会过滤这些类型,不会进去背包
			eff = ObjectItemEffectFactory.getEffect(self.game, itemID, count)
			eff.gain()

	# 处理可以直接打开的随机礼包
	def imOpenRandGift2item(self):
		from game.object.game.item import RandomGiftItemEffect
		from game.object.game.lottery import ObjectDrawRandomItem
		imOpenRandGiftItemIDs = [k for k, _ in self._itemsD.iteritems() if csv.items[k].type == ItemDefs.imOpenRandGiftType]

		for itemID in imOpenRandGiftItemIDs:
			libID = RandomGiftItemEffect.getLibID(self.game, itemID)
			if ObjectDrawRandomItem.getObject(libID):
				count = self._itemsD.pop(itemID)
				for _ in xrange(count):
					self._draw_libs.append(libID)

		d = {}
		for libID in self._draw_libs:
			obj = ObjectDrawRandomItem.getObject(libID)
			if obj:
				itemT = obj.getRandomItem(self.game)
				ObjectDrawRandomItem.packToDict(itemT, d)
		self._draw_libs = []
		if d:
			newGain = ObjectGainAux(self.game, d)
			self += newGain

	# 重复获得
	def checkRegain(self):
		from game.object.game.item import ObjectItemEffectFactory
		items = {k: v for k, v in self._itemsD.iteritems() if csv.items[k].regain}
		data = ObjectGoodsMap(self._game, {})
		hasData = False
		for itemID, count in items.iteritems():
			csvItem = csv.items[itemID]
			regain = csv.items[itemID].regain

			# 头像，头像框，称号
			if csvItem.type in [ItemDefs.roleDisplayType, ItemDefs.skinInMemType]:
				hasRegain, regainCOunt = ObjectItemEffectFactory.checkRegain(csvItem.type, self.game, itemID, count)

			# 形象信物
			elif csvItem.specialArgsMap.get('figure', None) and csvItem.specialArgsMap['figure'] in self.game.role.figures:
				hasRegain = True
				regainCOunt = count

			# 通用道具
			else:
				hasRegain, regainCOunt = self.game.items.checkRegain(itemID, count)

			if hasRegain:
				self._itemsD.pop(itemID, None)
				data += ObjectGoodsMap(self._game, regain) * regainCOunt

				# 没有全部转换
				if regainCOunt < count:
					data += ObjectGoodsMap(self._game, {itemID: count - regainCOunt})

				self._regainD[itemID] = self._regainD.get(itemID, 0) + count
				hasData = True

		if hasData:
			self += data

	def gain(self, **kwargs):
		if self._dbGemsL:
			self._objGemsD = self.game.gems.addGems(self._dbGemsL)
		if self._dbChipsL:
			self._objChipsD = self.game.chips.addChips(self._dbChipsL)
		if self._dbHeldItemsL:
			self._objHeldItemsD = self.game.heldItems.addHeldItems(self._dbHeldItemsL)
		if self._dbCardsL:
			self._objCardsD = self.game.cards.addCards(self._dbCardsL)
		if self._stashCardsL:
			if self.game.role.stashCardMailCount >= ConstDefs.stashCardMailCountMax: # 暂存邮件超上限，自动分解需要暂存的卡牌
				cards = self._stashCardsL
				self._stashCardsL = []
				for card in cards:
					self.card2frag(card)
			else:
				from game.object.game.role import ObjectRole
				from game.mailqueue import MailJoinableQueue
				mail = ObjectRole.makeMailModel(self.game.role.id, StashCardMailID, attachs={'cards': self._stashCardsL})
				MailJoinableQueue.send(mail)

		self.checkRegain()
		self.imDirectUse() #内存中直接使用

		self.game.items.addItems(self._itemsD)
		self.game.frags.addFrags(self._fragsD)
		self.game.zawake.addZFrags(self._zfragsD)
		if self._itemsD:
			from game.object.game.yyhuodong import ObjectYYHuoDongFactory
			ObjectYYHuoDongFactory.onItemGain(self.game)
		if self._gold:
			self.game.role.gold += int(self._gold)
		# exp经验给card，由外部来执行
		self.game.role.exp += self._role_exp
		if self._stamina:
			self.game.role.stamina += int(self._stamina)
		if self._skill_point:
			self.game.role.skill_point += int(self._skill_point)
		if self._rmb:
			self.game.role.rmb += int(self._rmb)
		if self._recharge_rmb:
			from game.object.game.yyhuodong import ObjectYYHuoDongFactory
			# recharge_rmb和rmb区别在于，除了rmb加上，vip_exp和相关活动都会参与
			rmb = int(self._recharge_rmb)
			self.game.role.rmb += rmb
			self.game.dailyRecord.recharge_rmb_sum += rmb
			self.game.role.addVIPExp(rmb)
			ObjectYYHuoDongFactory.onRecharge(self.game, rmb)
		if self._coin1:
			self.game.role.coin1 += int(self._coin1)
		if self._coin2:
			self.game.role.coin2 += int(self._coin2)
		if self._coin3:
			self.game.role.coin3 += int(self._coin3)
		if self._coin4:
			self.game.role.coin4 += int(self._coin4)
		if self._coin5:
			self.game.role.coin5 += int(self._coin5)
		if self._coin6:
			self.game.role.coin6 += int(self._coin6)
		if self._coin7:
			self.game.role.coin7 += int(self._coin7)
		if self._coin8:
			self.game.role.coin8 += int(self._coin8)
		if self._coin9:
			self.game.role.coin9 += int(self._coin9)
		if self._coin10:
			self.game.role.coin10 += int(self._coin10)
		if self._coin11:
			self.game.role.coin11 += int(self._coin11)
		if self._coin12:
			self.game.role.coin12 += int(self._coin12)
		if self._coin13:
			self.game.role.coin13 += int(self._coin13)
		if self._coin14:
			self.game.role.coin14 += int(self._coin14)
		if self._talent_point:
			self.game.role.talent_point += int(self._talent_point)
		if self._equip_awake_frag:
			self.game.role.equip_awake_frag += int(self._equip_awake_frag)
		if self._star_skill_points:
			for k, v in self._star_skill_points.iteritems():
				self.game.role.star_skill_points[k] = self.game.role.star_skill_points.get(k, 0) + v
		if self._gym_talent_point:
			self.game.role.gym_datas['gym_talent_point'] = self.game.role.gym_talent_point + self._gym_talent_point

		logger.info("role %d %s gain from %s, %s", self.game.role.uid, self.game.role.pid, kwargs.get('src', ''), self.prettylog)

		ta.good(self.game, self, **kwargs)
	def getHeldItemsObjD(self):
		'''
		外部获取服务器携带道具对象
		'''
		return getattr(self, '_objHeldItemsD', None)

	def getGemsObjD(self):
		'''
		外部获取服务器宝石对象
		'''
		return getattr(self, '_objGemsD', None)

	def getChipsObjD(self):
		'''
		外部获取服务器宝石对象
		'''
		return getattr(self, '_objChipsD', None)

	def getCardsObjD(self):
		'''
		外部获取服务器卡牌对象
		'''
		return getattr(self, '_objCardsD', None)

	@property
	def result(self):
		ret = ObjectGoodsMap.to_dict(self)
		if self._newCardsL:
			ret['carddbIDs'] = self._newCardsL
		if self._cardFragL:
			ret['card2fragL'] = self._cardFragL
		if self._stashCardsL:
			ret['card2mailL'] = self._stashCardsL
		if self._newHeldItemsL:
			ret['heldItemdbIDs'] = self._newHeldItemsL
		if self._newGemsL:
			ret['gemdbIDs'] = self._newGemsL
		if self._newChipsL:
			ret['chipdbIDs'] = self._newChipsL
		if self._regainD:
			ret['regainD'] = self._regainD

		# 客户端保护处理后，可以删除
		if 'recharge_rmb' in ret:
			ret['rmb'] = ret.pop('recharge_rmb') + ret.get('rmb', 0)
		ret.pop('recharge', None)
		return ret

	@property
	def prettylog(self):
		ret = ObjectGoodsMap.to_dict(self)
		if self._newCardsL:
			ret['carddbIDs'] = [(objectid2string(x[0]), x[1]) for x in self._newCardsL]
		if self._cardFragL:
			ret['card2fragL'] = self._cardFragL
		if self._stashCardsL:
			ret['card2mailL'] = self._stashCardsL
		if self._newHeldItemsL:
			ret['heldItemdbIDs'] = [objectid2string(x) for x in self._newHeldItemsL]
		if self._newGemsL:
			ret['gemdbIDs'] = [objectid2string(x) for x in self._newGemsL]
		if self._newChipsL:
			ret['chipdbIDs'] = [objectid2string(x) for x in self._newChipsL]
		if self._regainD:
			ret['regainD'] = self._regainD

		# 客户端保护处理后，可以删除
		if 'recharge_rmb' in ret:
			ret['rmb'] = ret.pop('recharge_rmb') + ret.get('rmb', 0)
		ret.pop('recharge', None)
		return ret

	def hasCards(self):
		return self._newCardsL or self._cardFragL


class ObjectCostAux(ObjectGoodsMap):
	'''
	所有消耗的道具、碎片等参数map形式的配置处理辅助
	'''

	LackNone = 0
	LackItems = 1
	LackFrags = 2
	LackGold = 3
	LackStamina = 4
	LackRMB = 5
	LackCoin1 = 6
	LackCoin2 = 7
	LackCoin3 = 8
	LackCoin4 = 9
	LackCoin5 = 10
	LackTalentPoint = 11
	LackEquipAwakeFrag = 12
	LackCoin6 = 13
	LackCoin7 = 14
	LackCoin8 = 15
	LackCoin9 = 16
	LackCoin10 = 17
	LackCoin11 = 18
	LackCoin12 = 18
	LackGymTalentPoint = 20
	LackCoin13 = 21
	LackZFrags = 22
	LackCoin14 = 23

	def __init__(self, game, argsD):
		ObjectGoodsMap.__init__(self, game, argsD)
		self._lackFlag = None

		self._heldItems = None
		self._costHeldItemsL = [] # [dbid, ]
		self._gems = None
		self._costGemsL = []  # [dbid, ]
		self._chips = None
		self._costChipsL = []  # [dbid, ]
		self._cards = None
		self._costCardsL = [] # [dbid, ]

	@property
	def coin13(self):
		return self._coin13

	def setCostGems(self, objs):
		'''
		外部设置消耗宝石对象
		'''
		self._gems = objs
		self._costGemsL = [o.id for o in objs]
		self._gemsL = [o.gem_id for o in objs]

	def setCostChips(self, objs):
		'''
		外部设置消耗宝石对象
		'''
		self._chips = objs
		self._costChipsL = [o.id for o in objs]
		self._chipsL = [o.chip_id for o in objs]

	def setCostHeldItems(self, objs):
		'''
		外部设置消耗携带道具对象
		'''
		self._heldItems = objs
		self._costHeldItemsL = [o.id for o in objs]
		self._heldItemsL = [o.held_item_id for o in objs]

	def setCostCards(self, objs):
		'''
		外部设置消耗携卡牌对象
		'''
		self._cards = objs
		self._costCardsL = [o.id for o in objs]
		self._cardsL = [{'id': o.card_id, 'star': o.star, 'character': o.character} for o in objs]

	@property
	def lack(self):
		if self._lackFlag is None:
			self.isEnough()
		return self._lackFlag

	def isEnough(self):
		self._lackFlag = ObjectCostAux.LackNone

		if not self.game.items.isEnough(self._itemsD):
			self._lackFlag = ObjectCostAux.LackItems
			return False
		if not self.game.frags.isEnough(self._fragsD):
			self._lackFlag = ObjectCostAux.LackFrags
			return False
		if not self.game.zawake.isZFragEnough(self._zfragsD):
			self._lackFlag = ObjectCostAux.LackZFrags
			return False
		if self._gold > 0 and self.game.role.gold < self._gold:
			self._lackFlag = ObjectCostAux.LackGold
			return False
		# exp, role_exp经验不可能减少
		if self._stamina > 0 and self.game.role.stamina < self._stamina:
			self._lackFlag = ObjectCostAux.LackStamina
			return False
		if self._rmb > 0 and self.game.role.rmb < self._rmb:
			self._lackFlag = ObjectCostAux.LackRMB
			return False
		if self._coin1 > 0 and self.game.role.coin1 < self._coin1:
			self._lackFlag = ObjectCostAux.LackCoin1
			return False
		if self._coin2 > 0 and self.game.role.coin2 < self._coin2:
			self._lackFlag = ObjectCostAux.LackCoin2
			return False
		if self._coin3 > 0 and self.game.role.coin3 < self._coin3:
			self._lackFlag = ObjectCostAux.LackCoin3
			return False
		if self._coin4 > 0 and self.game.role.coin4 < self._coin4:
			self._lackFlag = ObjectCostAux.LackCoin4
			return False
		if self._coin5 > 0 and self.game.role.coin5 < self._coin5:
			self._lackFlag = ObjectCostAux.LackCoin5
			return False
		if self._coin6 > 0 and self.game.role.coin6 < self._coin6:
			self._lackFlag = ObjectCostAux.LackCoin6
			return False
		if self._coin7 > 0 and self.game.role.coin7 < self._coin7:
			self._lackFlag = ObjectCostAux.LackCoin7
			return False
		if self._coin8 > 0 and self.game.role.coin8 < self._coin8:
			self._lackFlag = ObjectCostAux.LackCoin8
			return False
		if self._coin9 > 0 and self.game.role.coin9 < self._coin9:
			self._lackFlag = ObjectCostAux.LackCoin9
			return False
		if self._coin10 > 0 and self.game.role.coin10 < self._coin10:
			self._lackFlag = ObjectCostAux.LackCoin10
			return False
		if self._coin11 > 0 and self.game.role.coin11 < self._coin11:
			self._lackFlag = ObjectCostAux.LackCoin11
			return False
		if self._coin12 > 0 and self.game.role.coin12 < self._coin12:
			self._lackFlag = ObjectCostAux.LackCoin12
			return False
		if self._coin13 > 0 and self.game.role.coin13 < self._coin13:
			self._lackFlag = ObjectCostAux.LackCoin13
			return False
		if self._coin14 > 0 and self.game.role.coin14 < self._coin14:
			self._lackFlag = ObjectCostAux.LackCoin14
			return False
		if self._talent_point > 0 and self.game.role.talent_point < self._talent_point:
			self._lackFlag = ObjectCostAux.LackTalentPoint
			return False
		if self._equip_awake_frag > 0 and self.game.role.equip_awake_frag < self._equip_awake_frag:
			self._lackFlag = ObjectCostAux.LackEquipAwakeFrag
			return False
		if self._skill_point > 0 and self.game.role.skill_point < self._skill_point:
			return False
		for k, v in self._star_skill_points.iteritems():
			if self.game.role.star_skill_points.get(k, 0) < v:
				return False
		if self._gym_talent_point > 0 and self.game.role.gym_talent_point < self._gym_talent_point:
			self._lackFlag = ObjectCostAux.LackGymTalentPoint
			return False

		return True

	def cost(self, **kwargs):
		if self._coin13 > 0 and not kwargs.get('inEffectAutoCost', False):
			raise ServerError('coin6 not support, please try effectAutoCost')
		kwargs.pop('inEffectAutoCost', None)
		self.game.items.costItems(self._itemsD)
		self.game.frags.costFrags(self._fragsD)
		self.game.zawake.costZFrags(self._zfragsD)
		if self._gold:
			self.game.role.gold -= self._gold
		# exp, role_exp经验不可能减少
		if self._stamina:
			self.game.role.stamina -= self._stamina
		if self._skill_point:
			self.game.role.skill_point -= self._skill_point
		if self._rmb:
			self.game.role.rmb -= self._rmb
		if self._coin1:
			self.game.role.coin1 -= self._coin1
		if self._coin2:
			self.game.role.coin2 -= self._coin2
		if self._coin3:
			self.game.role.coin3 -= self._coin3
		if self._coin4:
			self.game.role.coin4 -= self._coin4
		if self._coin5:
			self.game.role.coin5 -= self._coin5
		if self._coin6:
			self.game.role.coin6 -= self._coin6
		if self._coin7:
			self.game.role.coin7 -= self._coin7
		if self._coin8:
			self.game.role.coin8 -= self._coin8
		if self._coin9:
			self.game.role.coin9 -= self._coin9
		if self._coin10:
			self.game.role.coin10 -= self._coin10
		if self._coin11:
			self.game.role.coin11 -= self._coin11
		if self._coin12:
			self.game.role.coin12 -= self._coin12
		if self._coin13:
			self.game.role.coin13 -= self._coin13
		if self._coin14:
			self.game.role.coin14 -= self._coin14
		if self._talent_point:
			self.game.role.talent_point -= self._talent_point
		if self._equip_awake_frag:
			self.game.role.equip_awake_frag -= self._equip_awake_frag
		if self._gym_talent_point:
			self.game.role.gym_datas['gym_talent_point'] = self.game.role.gym_talent_point - self._gym_talent_point

		# 消耗宝石对象
		if self._gems:
			self.game.gems.deleteGems(self._gems)
		if self._chips:
			self.game.chips.deleteChips(self._chips)
		if self._heldItems:
			self.game.heldItems.deleteHeldItems(self._heldItems)
		if self._cards:
			self.game.cards.deleteCards(self._cards)
			self.game.cards.onFightingPointChange()
		if self._star_skill_points.iteritems():
			for k, v in self._star_skill_points.iteritems():
				self.game.role.star_skill_points[k] -= v

		logger.info("role %d %s cost for %s, %s", self.game.role.uid, self.game.role.pid, kwargs.get('src', ''), self.to_dict())

		ta.good(self.game, self, **kwargs)

	def to_dict(self):
		ret = ObjectGoodsMap.to_dict(self)
		if self._costCardsL:
			ret['carddbIDs'] = [objectid2string(x) for x in self._costCardsL]
		if self._costHeldItemsL:
			ret['heldItemdbIDs'] = [objectid2string(x) for x in self._costHeldItemsL]
		if self._costGemsL:
			ret['gemdbIDs'] = [objectid2string(x) for x in self._costGemsL]
		if self._costChipsL:
			ret['chipdbIDs'] = [objectid2string(x) for x in self._costChipsL]
		return ret

class ObjectGainEffect(ObjectGainAux):
	def __init__(self, game, argsD, cb):
		ObjectGainAux.__init__(self, game, argsD)
		self._cb = cb

	def gain(self, **kwargs):
		ObjectGainAux.gain(self, **kwargs)
		if self._cb:
			self._cb()

class ObjectGainResult(dict):
	'''
	ObjectGainAux的辅助类，用于ObjectGainAux.result的展示合并
	'''

	def __init__(self, arg):
		dict.__init__(self, arg)

	def __iadd__(self, val):
		for k, v in val.iteritems():
			if isinstance(v, int):
				self[k] = self.get(k, 0) + v
			elif isinstance(v, list):
				self[k] = self.get(k, []) + v
			else:
				raise ValueError('%s is not support' % type(v))
		return self
