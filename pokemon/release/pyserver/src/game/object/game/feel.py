#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2014 YouMi Information Technology Inc.
'''

from framework import str2num_t
from framework.log import logger
from framework.csv import csv, ErrDefs, ConstDefs
from framework.object import ObjectBase
from game import ServerError, ClientError
from game.object import CardFeelEffectTypeDefs
from game.object.game.calculator import zeros
from game.object.game.gain import ObjectCostAux
from game.thinkingdata import ta

import copy

# 卡牌好感度

class ObjectCardFeels(ObjectBase):

	CardGoodFeelMap = {} #{(feelType,level):csv}
	CardsFeelLevelSeq = {}  #{feelType:[]}
	CardGoodFeelEffectMap = {} # {markID: [cfg]}

	CardGoodFeelAttrMap = {} # lazy

	@classmethod
	def classInit(cls):
		# 好感度
		cls.CardGoodFeelMap = {}
		for i in csv.good_feel:
			csvFeel = csv.good_feel[i]
			cls.CardGoodFeelMap[(csvFeel.feelType, csvFeel.level)] = csvFeel

		# 好感经验排序
		cls.CardsFeelLevelSeq = {}
		for i in xrange(1, 99):
			if (i, 1) not in cls.CardGoodFeelMap:
				break
			cls.CardsFeelLevelSeq[i] = [0]
			for j in xrange(1, 999):
				if (i, j) not in cls.CardGoodFeelMap:
					break
				exp = cls.CardGoodFeelMap[(i, j)].needExp
				cls.CardsFeelLevelSeq[i].append(cls.CardsFeelLevelSeq[i][-1] + exp)

		cls.CardGoodFeelEffectMap = {}
		for i in csv.good_feel_effect:
			cfg= csv.good_feel_effect[i]
			cls.CardGoodFeelEffectMap.setdefault(cfg.markID, []).append(cfg)
		for markID, v in cls.CardGoodFeelEffectMap.iteritems():
			cls.CardGoodFeelEffectMap[markID] = sorted(v, key=lambda x: x.level)

		# 清理lazy配置缓存
		cls.CardGoodFeelAttrMap = {}

	def set(self):
		self._card_feels = self.game.role.card_feels
		self._changed = {} # {markID: (oldlevel, newlevel)}
		return ObjectBase.set(self)

	def init(self):
		self._initEffectAttrAddition()
		return ObjectBase.init(self)

	def _initEffectAttrAddition(self):
		self._cardAttrAddition = {} # {(scene, type): (const, percent)}
		self._natureCardAttrAddition = {} # {(scene, nature): (const, percent)}
		self._markIDCardAttrAddition = {} # {(scene, markID): (const, percent)}
		for markID, v in self._card_feels.iteritems():
			level = v['level']
			if markID not in self.CardGoodFeelEffectMap:
				continue
			for cfg in self.CardGoodFeelEffectMap[markID]:
				if cfg.level > level:
					break

				scene = cfg.addScene
				if cfg.addType == CardFeelEffectTypeDefs.Card: # 自身系列卡牌
					const, percent = self._markIDCardAttrAddition.setdefault((scene, cfg.markID), (zeros(), zeros()))
				elif cfg.addType == CardFeelEffectTypeDefs.CardNatureType: # 指定自然属性
					if not cfg.natureType:
						raise ServerError('good_feel_effect csv %d natureType error', cfg.id)
					const, percent = self._natureCardAttrAddition.setdefault((scene, cfg.natureType), (zeros(), zeros()))
				else:
					const, percent = self._cardAttrAddition.setdefault((scene, cfg.addType), (zeros(), zeros()))
				self.calcAddition(cfg, const=const, percent=percent)

	def addFeelExp(self, markID, exp):
		feeltype = csv.cards[markID].feelType
		levelSeq = self.CardsFeelLevelSeq[feeltype]
		levelMax = len(levelSeq) - 1

		feel = self._card_feels.setdefault(markID, {
			'level': 0,
			'sum_exp': 0,
			'level_exp': 0,
		})
		level = feel['level']
		oldlevel = level
		if level >= levelMax:
			return False
		exp = feel['sum_exp'] + exp
		while level + 1 <= levelMax and exp >= levelSeq[level + 1]:
			level += 1

		feel['level'] = level
		feel['sum_exp'] = exp
		feel['level_exp'] = exp - levelSeq[level]
		if oldlevel != level:
			self._changed[markID] = (oldlevel, level)
			ta.card(self, event='card_feel_level_up',mark_id=markID,level=level,addLevel=level-oldlevel)
		return True

	def isFeelExpUp(self, markID):
		if markID not in self._card_feels:
			return False
		level = self._card_feels[markID]['level']
		feeltype = csv.cards[markID].feelType
		levelSeq = self.CardsFeelLevelSeq[feeltype]
		levelMax = len(levelSeq) - 1
		return level >= levelMax

	def getAttrsAddition(self, card):
		markID = card.markID
		if markID not in self._card_feels:
			return

		level = self._card_feels[markID]['level']
		key = (card.feelType, level)

		addition = self.CardGoodFeelAttrMap.get(key, None)
		if addition:
			return addition

		cfg = self.CardGoodFeelMap.get(key, None)
		addition = self.calcAddition(cfg)
		self.CardGoodFeelAttrMap[key] = addition
		return addition

	def getEffectAttrsAddition(self, card, inFront, inBack, scene):
		markID = card.markID
		nature = card.natureType
		const = zeros()
		percent = zeros()
		additions = [
			# 固定加成
			(self._natureCardAttrAddition, CardFeelEffectTypeDefs.City, nature),
			(self._markIDCardAttrAddition, CardFeelEffectTypeDefs.City, markID),
			(self._cardAttrAddition, CardFeelEffectTypeDefs.City, CardFeelEffectTypeDefs.CardsAll),
		]
		if scene:
			# 所有战斗场景
			additions.append((self._natureCardAttrAddition, CardFeelEffectTypeDefs.AllBattle, nature))
			additions.append((self._markIDCardAttrAddition, CardFeelEffectTypeDefs.AllBattle, markID))
			additions.append((self._cardAttrAddition, CardFeelEffectTypeDefs.AllBattle, CardFeelEffectTypeDefs.CardsAll))
			if inFront:
				additions.append((self._cardAttrAddition, CardFeelEffectTypeDefs.AllBattle, CardFeelEffectTypeDefs.BattleFront))
			if inBack:
				additions.append((self._cardAttrAddition, CardFeelEffectTypeDefs.AllBattle, CardFeelEffectTypeDefs.BattleBack))

			# 指定战斗场景
			additions.append((self._natureCardAttrAddition, scene, nature))
			additions.append((self._markIDCardAttrAddition, scene, markID))
			additions.append((self._cardAttrAddition, scene, CardFeelEffectTypeDefs.CardsAll))
			if inFront:
				additions.append((self._cardAttrAddition, scene, CardFeelEffectTypeDefs.BattleFront))
			if inBack:
				additions.append((self._cardAttrAddition, scene, CardFeelEffectTypeDefs.BattleBack))

		for v, scene, typ in additions:
			addition = v.get((scene, typ), None)
			if addition:
				const += addition[0]
				percent += addition[1]
		return const, percent

	@staticmethod
	def calcAddition(cfg, const=None, percent=None):
		if const is None:
			const = zeros()
		if percent is None:
			percent = zeros()
		for i in xrange(1, 99):
			attr = 'attrType%d' % i
			if attr not in cfg or not cfg[attr]:
				break
			attr = cfg[attr]
			num = str2num_t(cfg['attrNum%d'%i])
			const[attr] += num[0]
			percent[attr] += num[1]
		return const, percent

	def updateRelatedCards(self):
		if not self._changed:
			return

		self._initEffectAttrAddition()
		markIDs = set(self._changed.keys())
		natures = set()
		isAll = False
		for markID, v in self._changed.iteritems():
			if markID not in self.CardGoodFeelEffectMap:
				continue
			oldlevel, level = v
			for cfg in self.CardGoodFeelEffectMap[markID]:
				if cfg.level > level:
					break
				if cfg.level <= oldlevel:
					continue
				if cfg.addScene != CardFeelEffectTypeDefs.City:
					continue
				if cfg.addType == CardFeelEffectTypeDefs.CardsAll:
					isAll = True
					break
				elif cfg.addType == CardFeelEffectTypeDefs.CardNatureType:
					natures.add(cfg.natureType)
			if isAll:
				break
		self._changed = {}
		cards = self.game.cards.getAllCards()
		for _, card in cards.iteritems():
			if isAll or card.markID in markIDs or card.natureType in natures:
				card.calcFeelGoodAttrsAddition(card, self)
				card.calcFeelEffectAttrsAddition(card, self)
				card.onUpdateAttrs()

	def swapFeel(self, cardID, targetCardID):
		markID = csv.cards[cardID].cardMarkID
		targetMarkID = csv.cards[targetCardID].cardMarkID
		cardCfg = csv.cards[markID]
		targetCardCfg = csv.cards[targetMarkID]

		if csv.unit[cardCfg.unitID].rarity != csv.unit[targetCardCfg.unitID].rarity:
			raise ClientError('card rarity is different')

		itemCheck1 = set([itemID for itemID in cardCfg.feelItems if not csv.items[itemID].specialArgsMap.get('special', False)])
		itemCheck2 = set([itemID for itemID in targetCardCfg.feelItems if not csv.items[itemID].specialArgsMap.get('special', False)])
		if itemCheck1 != itemCheck2:
				raise ClientError('cost item is different')

		feel = self._card_feels.setdefault(markID, {
			'level': 0,
			'sum_exp': 0,
			'level_exp': 0,
		})
		targetFeel = self._card_feels.setdefault(targetMarkID, {
			'level': 0,
			'sum_exp': 0,
			'level_exp': 0,
		})
		# 先消耗
		cost = ObjectCostAux(self.game, {'rmb': ConstDefs.feelSwapCostRmb})
		if not cost.isEnough():
			raise ClientError("cost rmb not enough")
		cost.cost(src='feel_swap')
		# 后交换
		self._card_feels[markID] = copy.deepcopy(targetFeel)
		self._card_feels[targetMarkID] = copy.deepcopy(feel)

		if feel['level'] != targetFeel['level']:
			self._changed[markID] = (feel['level'], targetFeel['level'])
			self._changed[targetMarkID] = (targetFeel['level'], feel['level'])


