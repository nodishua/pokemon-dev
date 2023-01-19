#!/usr/bin/python
# -*- coding: utf-8 -*-

from framework.log import logger
from game import ClientError
from game.object import FeatureDefs
from game.object.game import ObjectFeatureUnlockCSV
from game.handler import RequestHandlerTask
from tornado.gen import coroutine


# 勋章天赋升级
class BadgeTalentLevelUp(RequestHandlerTask):
	url = r'/game/badge/talent/level/up'

	@coroutine
	def run(self):
		if not ObjectFeatureUnlockCSV.isOpen(FeatureDefs.Badge, self.game):
			raise ClientError('Badge not open')

		badgeID = self.input.get('badgeID', None)
		count = self.input.get('count', 1)
		if not badgeID:
			raise ClientError('param miss')
		if count > 1 and not ObjectFeatureUnlockCSV.isOpen(FeatureDefs.BadgeOneKey, self.game):
			raise ClientError('BadgeOneKey not open')

		self.game.badge.talentLevelUp(badgeID, count)


# 勋章觉醒
class BadgeAwake(RequestHandlerTask):
	url = r'/game/badge/awake'

	@coroutine
	def run(self):
		if not ObjectFeatureUnlockCSV.isOpen(FeatureDefs.Badge, self.game):
			raise ClientError('Badge not open')

		badgeID = self.input.get('badgeID', None)
		if not badgeID:
			raise ClientError('param miss')

		self.game.badge.badgeAwake(badgeID)


# 勋章 设置守护精灵
class BadgeGuardSetup(RequestHandlerTask):
	url = r'/game/badge/guard/setup'

	@coroutine
	def run(self):
		if not ObjectFeatureUnlockCSV.isOpen(FeatureDefs.Badge, self.game):
			raise ClientError('Badge not open')

		badgeID = self.input.get('badgeID', None)
		guardID = self.input.get('guardID', None)
		cardID = self.input.get('cardID', None)  # -1表示下阵

		if any(x is None for x in [badgeID, guardID, cardID]):
			raise ClientError('param miss')

		self.game.badge.setGuardCard(badgeID, guardID, cardID)


# 勋章 守护精灵栏位解锁
class BadgeGuardUnlock(RequestHandlerTask):
	url = r'/game/badge/guard/unlock'

	@coroutine
	def run(self):
		if not ObjectFeatureUnlockCSV.isOpen(FeatureDefs.Badge, self.game):
			raise ClientError('Badge not open')

		badgeID = self.input.get('badgeID', None)
		guardID = self.input.get('guardID', None)

		if any(x is None for x in [badgeID, guardID]):
			raise ClientError('param miss')

		self.game.badge.unlockGuardPosition(badgeID, guardID)


# 勋章 刷新属性加成
class BadgeAdditionRefresh(RequestHandlerTask):
	url = r'/game/badge/refresh'

	@coroutine
	def run(self):
		if not ObjectFeatureUnlockCSV.isOpen(FeatureDefs.Badge, self.game):
			raise ClientError('Badge not open')

		for card in self.game.cards.getCards(self.game.role.cards):
			card.calcGymBadgeAttrsAddition(card, self.game)
			card.onUpdateAttrs()
