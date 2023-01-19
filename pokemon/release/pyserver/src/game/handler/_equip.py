#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2014 YouMi Information Technology Inc.

Equip Handlers
'''

from framework.csv import ErrDefs, csv

from game import BaseHTTPError, ServerError, ClientError
from game.handler.inl import effectAutoGain
from game.handler.task import RequestHandlerTask
from game.object import FeatureDefs, ItemDefs
from game.object.game import ObjectFeatureUnlockCSV

from tornado.gen import coroutine


# 装备进阶
class EquipAdvance(RequestHandlerTask):
	url = r'/game/equip/advance'

	@coroutine
	def run(self):
		cardID = self.input.get('cardID', None)
		equipPos = self.input.get('equipPos', None)
		card = self.game.cards.getCard(cardID)
		if card is None:
			raise ClientError('cardID error')
		if equipPos is None or equipPos < 1 or equipPos > 4:
			raise ClientError('equipPos error')

		card.equipAdvance(equipPos)


# 装备强化
class EquipStrength(RequestHandlerTask):
	url = r'/game/equip/strength'

	@coroutine
	def run(self):
		cardID = self.input.get('cardID', None)
		equipPos = self.input.get('equipPos', None)
		upLevel = self.input.get('upLevel', 1)
		oneKey = self.input.get('oneKey', None)
		card = self.game.cards.getCard(cardID)
		if card is None:
			raise ClientError('cardID error')
		if equipPos is None or equipPos < 1 or equipPos > 4: #1 to No. 4 to enhance
			raise ClientError('equipPos error')
		if not oneKey:
			card.equipStrength(equipPos,upLevel)
		else:
			card.equipOneKeyStrength(equipPos,upLevel)


# 装备经验强化
class EquipStrengthByExp(RequestHandlerTask):
	url = r'/game/equip/strength/exp'

	@coroutine
	def run(self):
		cardID = self.input.get('cardID', None)
		equipPos = self.input.get('equipPos', None)
		costItemIDs = self.input.get('costItemIDs', None)
		upLevel = self.input.get('upLevel', 1)
		oneKey = self.input.get('oneKey', None)
		card = self.game.cards.getCard(cardID)
		if card is None:
			raise ClientError('cardID error')
		if equipPos is None or equipPos < 5 or equipPos > 6: #Reinforcement from 5 to 6 positions
			raise ClientError('equipPos error')
		if costItemIDs is None:
			raise ClientError('costItemIDs is miss')
		if isinstance(costItemIDs, list):
			costItemIDs = {i+1: v for i, v in enumerate(costItemIDs)}
		if len(costItemIDs) == 0:
			raise ClientError('costItemIDs is empty')

		if not oneKey:
			card.equipStrengthByExp(equipPos,costItemIDs)
		else:
			card.equipOneKeyStrengthByExp(equipPos,costItemIDs,upLevel)


# 装备升星
class EquipStar(RequestHandlerTask):
	url = r'/game/equip/star'

	@coroutine
	def run(self):
		cardID = self.input.get('cardID', None)
		equipPos = self.input.get('equipPos', None)
		card = self.game.cards.getCard(cardID)
		if card is None:
			raise ClientError('cardID error')
		if equipPos is None or equipPos < 1 or equipPos > 4:
			raise ClientError('equipPos error')

		card.equipRaiseStar(equipPos)
		self.game.zawake.onAttrChange()


# 装备降星
class EquipDropStar(RequestHandlerTask):
	url = r'/game/equip/star/drop'

	@coroutine
	def run(self):
		cardID = self.input.get('cardID', None)
		equipPos = self.input.get('equipPos', None)
		card = self.game.cards.getCard(cardID)
		if card is None:
			raise ClientError('cardID error')
		if equipPos is None or equipPos < 1 or equipPos > 4:
			raise ClientError('equipPos error')
		card.equipDropStar(equipPos)
		self.game.zawake.onAttrChange()


# 装备觉醒
class EquipAwake(RequestHandlerTask):
	url = r'/game/equip/awake'

	@coroutine
	def run(self):
		cardID = self.input.get('cardID', None)
		equipPos = self.input.get('equipPos', None)
		card = self.game.cards.getCard(cardID)
		if card is None:
			raise ClientError('cardID error')
		if equipPos is None or equipPos < 1 or equipPos > 4:
			raise ClientError('equipPos error')

		card.equipAwake(equipPos)
		self.game.zawake.onAttrChange()


# 装备觉醒降阶
class EquipAwakeDrop(RequestHandlerTask):
	url = r'/game/equip/awake/drop'

	@coroutine
	def run(self):
		cardID = self.input.get('cardID', None)
		equipPos = self.input.get('equipPos', None)
		card = self.game.cards.getCard(cardID)
		if card is None:
			raise ClientError('cardID error')
		if equipPos is None or equipPos < 1 or equipPos > 4:
			raise ClientError('equipPos error')

		card.equipDropAwake(equipPos)
		self.game.zawake.onAttrChange()


# 装备升星潜能
class EquipAbility(RequestHandlerTask):
	url = r'/game/equip/ability'

	@coroutine
	def run(self):
		if not ObjectFeatureUnlockCSV.isOpen(FeatureDefs.EquipAbility, self.game):
			raise ClientError('star ability not open')
		cardID = self.input.get('cardID', None)
		equipPos = self.input.get('equipPos', None)
		level = self.input.get("level", 1)
		card = self.game.cards.getCard(cardID)
		if card is None:
			raise ClientError('cardID error')
		if equipPos is None or equipPos < 1 or equipPos > 4:
			raise ClientError('equipPos error')

		card.equipRaiseAbility(equipPos, level)
		self.game.zawake.onAttrChange()


# 装备刻印
class EquipSignet(RequestHandlerTask):
	url = r'/game/equip/signet'

	@coroutine
	def run(self):
		if not ObjectFeatureUnlockCSV.isOpen(FeatureDefs.EquipSignet, self.game):
			raise ClientError('signet not open')
		cardID = self.input.get('cardID', None)
		equipPos = self.input.get('equipPos', None)
		upLevel = self.input.get("upLevel", None)
		advanceLevel = self.input.get("advanceLevel", None)
		oneKey = self.input.get("oneKey", None)
		card = self.game.cards.getCard(cardID)
		if card is None:
			raise ClientError('cardID error')
		if equipPos is None or equipPos < 1 or equipPos > 4:
			raise ClientError('equipPos error')

		if not oneKey:
			card.equipRaiseSignet(equipPos)
		else:
			card.equipOneKeySignet(equipPos, upLevel, advanceLevel)


# 装备刻印突破
class EquipSignetAdvance(RequestHandlerTask):
	url = r'/game/equip/signet/advance'

	@coroutine
	def run(self):
		if not ObjectFeatureUnlockCSV.isOpen(FeatureDefs.EquipSignet, self.game):
			raise ClientError('signet not open')
		cardID = self.input.get('cardID', None)
		equipPos = self.input.get('equipPos', None)
		card = self.game.cards.getCard(cardID)
		if card is None:
			raise ClientError('cardID error')
		if equipPos is None or equipPos < 1 or equipPos > 4:
			raise ClientError('equipPos error')

		card.equipSignetAdvance(equipPos)
		self.game.zawake.onAttrChange()


# 装备刻印降阶
class EquipSignetDrop(RequestHandlerTask):
	url = r'/game/equip/signet/drop'

	@coroutine
	def run(self):
		if not ObjectFeatureUnlockCSV.isOpen(FeatureDefs.EquipSignet, self.game):
			raise ClientError('signet not open')
		cardID = self.input.get('cardID', None)
		equipPos = self.input.get('equipPos', None)
		card = self.game.cards.getCard(cardID)
		if card is None:
			raise ClientError('cardID error')
		if equipPos is None or equipPos < 1 or equipPos > 4:
			raise ClientError('equipPos error')

		card.equipDropSignet(equipPos)
		self.game.zawake.onAttrChange()


# 装备觉醒潜能
class EquipAwakeAbility(RequestHandlerTask):
	url = r'/game/equip/awake/ability'

	@coroutine
	def run(self):
		if not ObjectFeatureUnlockCSV.isOpen(FeatureDefs.EquipAwakeAbility, self.game):
			raise ClientError('awake ability not open')
		cardID = self.input.get('cardID', None)
		equipPos = self.input.get('equipPos', None)
		level = self.input.get("level", 1)
		card = self.game.cards.getCard(cardID)
		if card is None:
			raise ClientError('cardID error')
		if equipPos is None or equipPos < 1 or equipPos > 4:
			raise ClientError('equipPos error')

		card.equipRaiseAwakeAbility(equipPos, level)

