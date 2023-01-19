#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2014 YouMi Information Technology Inc.
'''

from framework import str2num_t, nowtime_t
from framework.csv import csv, ErrDefs
from framework.log import logger
from framework.object import ObjectBase
from game import ServerError, ClientError
from game.object import AttrDefs, PokedexAdvanceDefs
from game.object.game import ObjectCard
from game.object.game.calculator import zeros
from collections import defaultdict
from game.thinkingdata import ta

#
# ObjectPokedex
#

class ObjectPokedex(ObjectBase):

	PokedexMap = {} #{cardID:csv}
	PokedexDevelopAttrs = {} # {(markID: star): (const, percent)}

	@classmethod
	def classInit(cls):
		#精灵图鉴
		cls.PokedexMap = {}
		for csvID in csv.pokedex:
			cfg = csv.pokedex[csvID]
			cls.PokedexMap[cfg.cardID] = cfg

		cls.PokedexDevelopAttrs = {}
		for csvID in csv.pokedex_develop:
			cfg = csv.pokedex_develop[csvID]
			const = zeros()
			percent = zeros()
			for i in xrange(1, 99):
					ty = 'attrType%d'%i
					if ty not in cfg or not cfg[ty]:
						break
					attr = cfg[ty]
					if not attr:
						continue
					num = str2num_t(cfg['attrValue%d'%i])
					const[attr] += num[0]
					percent[attr] += num[1]
			cls.PokedexDevelopAttrs[(cfg.markID, cfg.star)] = (const, percent)

	def set(self):
		self._pokedex = self.game.role.pokedex
		self._pokedex_advance = self.game.role.pokedex_advance
		self._attrAddition = None # (const, percent)
		self._developAttrAddition = None # (const, percent)
		self._advanceAttrAdd = defaultdict(dict) #{natureType:{attr:value}}
		return ObjectBase.set(self)

	#登录时的初始化
	def init(self):
		self._fetters = set([])
		self.addPokedex(self.game.cards.getDBIDs(), refresh=False)
		self._initFetters(csv.fetter.keys())

		self.calcAttrs()
		self.calcAdvanceAttrs()
		return ObjectBase.init(self)

	def calcAttrs(self):
		const = zeros()
		percent = zeros()
		for cardID in self._pokedex:
			if cardID in self.PokedexMap:
				pokeCsv = self.PokedexMap[cardID]
				for i in xrange(1,99):
					ty = 'attrType%d'%i
					if ty not in pokeCsv:
						break
					attr = pokeCsv[ty]
					if not attr:
						continue
					num = str2num_t(pokeCsv['attrValue%d'%i])
					const[attr] += num[0]
					percent[attr] += num[1]
		self._attrAddition = (const, percent)

	def calcDevelopAttrs(self):
		const = zeros()
		percent = zeros()
		for markID, maxstar in self.game.cards.markIDMaxStar.iteritems():
			v = self.PokedexDevelopAttrs.get((markID, maxstar))
			if v:
				const += v[0]
				percent += v[1]
		self._developAttrAddition = (const, percent)

	def calcAdvanceAttrs(self):
		self._advanceAttrAdd = defaultdict(dict)
		for csvID, flag in self._pokedex_advance.iteritems():
			if not flag:
				cfg = csv.pokedex_advance[csvID]
				attr = cfg.attrType
				num = str2num_t(cfg.attrValue)

				if not self._advanceAttrAdd[cfg.attrNatureType].get(attr, None):
					self._advanceAttrAdd[cfg.attrNatureType][attr] = num
				else:
					constVal = self._advanceAttrAdd[cfg.attrNatureType][attr][0] + num[0]
					percentVal = self._advanceAttrAdd[cfg.attrNatureType][attr][1] + num[1]
					self._advanceAttrAdd[cfg.attrNatureType][attr] = (constVal, percentVal)

	def getAttrsAddition(self):
		return self._attrAddition

	def getDevelopAddition(self):
		if self._developAttrAddition is None:
			self.calcDevelopAttrs()
		return self._developAttrAddition

	def getAdvanceAttrsAdd(self, card):
		advanceAttrAdd = {}
		for natureType, add in self._advanceAttrAdd.iteritems():
			if not natureType or card.natureType == natureType:
				for attr, num in add.iteritems():
					if not advanceAttrAdd.get(attr, None):
						advanceAttrAdd[attr] = num
					else:
						constVal = advanceAttrAdd[attr][0] + num[0]
						percentVal = advanceAttrAdd[attr][1] + num[1]
						advanceAttrAdd[attr] = (constVal, percentVal)
		return advanceAttrAdd

	def refreshAdvanceState(self):
		#图鉴突破
		for idx in csv.pokedex_advance:
			cfg = csv.pokedex_advance[idx]
			if self._pokedex_advance.get(cfg.id, None) == 0:
				continue
			if cfg.targetType == PokedexAdvanceDefs.TotalCount and len(self._pokedex) >= cfg.targetArg:
				self._pokedex_advance[cfg.id] = 1
			elif cfg.targetType == PokedexAdvanceDefs.SingleCount and cfg.targetArg2:
				count = 0
				for cardID in self._pokedex:
					unitcfg = csv.unit[csv.cards[cardID].unitID]
					if unitcfg and (unitcfg.natureType == cfg.targetArg2 or unitcfg.natureType2 == cfg.targetArg2):
						count += 1
				if count >= cfg.targetArg:
					self._pokedex_advance[cfg.id] = 1

	#增加精灵图鉴
	def addPokedex(self, cardIDs, refresh=True):
		flag = False
		fetterIDs = set([])

		# 初始化 默认激活的图鉴
		if not refresh:
			for cardID, cfg in self.PokedexMap.iteritems():
				if cfg.canDevelop and cardID not in self._pokedex:
					fetterIDs |= self.getUpdateFetters(csv.cards[cardID].cardMarkID)  # 获取影响到的羁绊
					self._pokedex[cardID] = nowtime_t()

		for dbID in cardIDs:
			card = self.game.cards.getCard(dbID)
			addCardIDs = []
			if card.card_id in self.PokedexMap:
				# 图鉴的所有前置形态都激活（包括自身）
				if self.PokedexMap[card.card_id].canDevelop2:
					addCardIDs = card.beforeCardIDs()
				# 只有自身
				else:
					addCardIDs.append(card.card_id)
			for addCardID in addCardIDs:
				if addCardID not in self._pokedex:
					fetterIDs |= self.getUpdateFetters(csv.cards[card.card_id].cardMarkID)  # 获取影响到的羁绊
					self._pokedex[addCardID] = nowtime_t()
					flag = True

		if fetterIDs:
			self._initFetters(fetterIDs)  # 更新羁绊
			self.game.cards.updateFetterCards(fetterIDs)  # 羁绊影响的卡牌 更新羁绊属性加成

		if flag:
			self.refreshAdvanceState()
			if refresh:
				self.calcAttrs()
				cards = self.game.cards.getAllCards()
				for _, card in cards.iteritems():
					card.calcPokedexAttrsAddition(card, self)
					card.onUpdateAttrs()

	def advance(self, csvID):
		if not self._pokedex_advance.get(csvID, None):
			raise ClientError("can not advance")
		self._pokedex_advance[csvID] = 0
		self.calcAdvanceAttrs()

		cfg = csv.pokedex_advance[csvID]
		self.game.cards.updateAllNatureCardAttr(cfg.attrNatureType, f=lambda x: x.calcPokedexAdvanceAttrsAddition(x, self))

	def updateDevelopRelatedCards(self):
		self.calcDevelopAttrs()
		allCards = self.game.cards.getAllCards()
		for _, card in allCards.iteritems():
			card.calcPokedexDevelopAttrsAddition(card, self)
			card.onUpdateAttrs()

	# 更新羁绊
	def _initFetters(self, fetterIDs):
		for fetterID in fetterIDs:
			if self._checkFetter(fetterID):
				self._fetters.add(fetterID)
			else:
				self._fetters.discard(fetterID)

	def _checkFetter(self, id):
		cfg = csv.fetter[id]
		flag = False
		if cfg.cards:
			flag = True
			for cardID in cfg.cards:
				if cardID not in self._pokedex:
					flag = False
					return flag
		return flag

	@property
	def allfetters(self):
		return self._fetters

	# 获得要更新的羁绊
	def getUpdateFetters(self, markID):
		fetterIDs = set([])
		if markID not in ObjectCard.CardMarkIDFetterMap:  # 该图鉴的变动不影响羁绊
			return set([])
		if not self.isExistedByMarkID(markID):
			fetterIDs = ObjectCard.CardMarkIDFetterMap[markID]
		return fetterIDs

	def isExistedByMarkID(self, markID):
		for cardID in self._pokedex:
			if markID == csv.cards[cardID].cardMarkID:
				return True
		return False

	def getAllMarkIDs(self):
		ret = set()
		for cardID in self._pokedex:
			ret.add(csv.cards[cardID].cardMarkID)
		return ret

	def countRarityCards(self, rarity):
		ret = 0
		for card_id in self._pokedex.iterkeys():
			cfg = csv.cards[card_id]
			if csv.unit[cfg.unitID].rarity >= rarity:
				ret += 1
		return ret
