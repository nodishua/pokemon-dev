#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2014 YouMi Information Technology Inc.
'''
from framework.csv import csv, ErrDefs
from framework.helper import transform2list
from framework.log import logger
from framework.object import ObjectBase
from game import ClientError
from game.object import DeployDefs


#
# ObjectDeployLimit
#
class ObjectDeployLimit(ObjectBase):

	def __init__(self, game, csv, cardIDs):
		ObjectBase.__init__(self, game)
		self._csv = csv
		self.cardIDs = cardIDs
		self.wheelCardIDs = []  # 车轮 [[cardIDs]]

	def csv(self, csvID=None):
		if csvID is None:
			return self._csv
		return self._csv[csvID]

	def deployLimit(self, csvID):
		'''
		布阵 条件限制
		'''
		cfg = self.csv(csvID)
		cardNumLimit = cfg.deployCardNumLimit

		if cfg.deployType == DeployDefs.WheelType:  # 车轮
			self.cardIDs = transform2list(self.cardIDs, 6*cfg.deployNum)
			for i in xrange(cfg.deployNum):
				# 车轮 卡牌数量限制判断
				tempCards = filter(None, self.cardIDs[i*6: (i+1)*6])
				if len(tempCards) > cardNumLimit:
					raise ClientError('the %d deploy cards num limit up' % (i+1))
				if len(tempCards) == 0:
					raise ClientError('the %d deploy cards all None' % (i+1))
				self.wheelCardIDs.append(self.cardIDs[i * 6: (i + 1) * 6])
		elif cfg.deployType == DeployDefs.OneByOneType:  # 单挑
			self.cardIDs = transform2list(self.cardIDs, cardNumLimit)
		elif cfg.deployType == DeployDefs.GeneralType:  # 常规
			self.cardIDs = transform2list(self.cardIDs)

		# 1.全为空
		filterCardIDs = filter(None, self.cardIDs)
		if len(filterCardIDs) == 0:
			raise ClientError('cards all None')

		# 2.有不存在卡牌
		cards = self.game.cards.getCards(filterCardIDs)
		if len(cards) != len(filterCardIDs):
			raise ClientError(ErrDefs.gateCardsError)

		# 3.卡牌数量限制判断
		if cfg.deployType == DeployDefs.OneByOneType or cfg.deployType == DeployDefs.GeneralType:
			if len(filterCardIDs) > cardNumLimit:
				raise ClientError('deploy cards num limit up')

		# 4.同markID限制判断
		if self.game.cards.isDuplicateMarkID(filterCardIDs):
			raise ClientError('cards have duplicates')

		# 5.自然属性限制判断
		if cfg.deployNatureLimit:
			for card in cards:
				if not (card.natureType in cfg.deployNatureLimit or card.natureType2 in cfg.deployNatureLimit):
					raise ClientError('deploy cards nature limit')

		return self.cardIDs

	def getCardAttrs(self, csvID, func, **kwargs):
		'''
		战斗 最终属性加成
		'''
		cardAttrs = {}
		cardAttrs2 = {}
		cfg = self.csv(csvID)
		if cfg.deployType == DeployDefs.WheelType:  # 车轮
			for cardIDs in self.wheelCardIDs:
				cardsD1, cardsD2 = func(cardIDs, **kwargs)
				cardAttrs.update(cardsD1)
				cardAttrs2.update(cardsD2)
		else:
			cardsD1, cardsD2 = func(self.cardIDs, **kwargs)
			cardAttrs.update(cardsD1)
			cardAttrs2.update(cardsD2)
		return cardAttrs, cardAttrs2

