#!/usr/bin/python
# -*- coding: utf-8 -*-
from framework.csv import ConstDefs
from framework.log import logger
from game import ClientError
from game.handler import RequestHandlerTask
from game.handler.inl import effectAutoGain
from game.object import CardResetDefs
from game.object.game import ObjectCardRebirthBase
from game.object.game.gain import ObjectCostAux
from game.object.game.held_item import ObjectHeldItemsRebirth
from tornado.gen import coroutine


# 装备 道具
class HeldItemEquip(RequestHandlerTask):
	url = r'/game/helditem/equip'

	@coroutine
	def run(self):
		cardID = self.input.get('cardID', None)
		heldItemID = self.input.get('heldItemID', None)
		if cardID is None or heldItemID is None:
			raise ClientError('param miss')
		card = self.game.cards.getCard(cardID)
		if card is None:
			raise ClientError('cardID error')
		heldItem = self.game.heldItems.getHeldItem(heldItemID)
		if heldItem is None or not heldItem.exist_flag:
			raise ClientError('heldItemID error')

		# 卡牌已有其他道具
		if card.held_item is not None:
			oldHeldItem = self.game.heldItems.getHeldItem(card.held_item)
			oldHeldItem.card_db_id = None

		# 道具已被其他卡牌携带
		if heldItem.card_db_id is not None:
			oldCard = self.game.cards.getCard(heldItem.card_db_id)
			oldCard.held_item = None
			oldCard.calcHeldItemAttrsAddition(oldCard)
			oldCard.onUpdateAttrs()

		# 装备上
		heldItem.card_db_id = cardID
		card.held_item = heldItemID
		card.calcHeldItemAttrsAddition(card)
		card.onUpdateAttrs()


# 脱下 道具
class HeldItemUnload(RequestHandlerTask):
	url = r'/game/helditem/unload'

	@coroutine
	def run(self):
		heldItemID = self.input.get('heldItemID', None)
		if heldItemID is None:
			raise ClientError('param miss')
		heldItem = self.game.heldItems.getHeldItem(heldItemID)
		if heldItem is None or not heldItem.exist_flag:
			raise ClientError('heldItemID error')

		cardID = heldItem.card_db_id
		# 道具没有被装备
		if cardID is None:
			raise ClientError('heldItem is not equip')
		card = self.game.cards.getCard(cardID)

		# 脱下
		heldItem.card_db_id = None
		card.held_item = None
		card.calcHeldItemAttrsAddition(card)
		card.onUpdateAttrs()


# 携带道具 强化
class HeldItemStrength(RequestHandlerTask):
	url = r'/game/helditem/strength'

	@coroutine
	def run(self):
		heldItemID = self.input.get('heldItemID', None)
		csvIDs = self.input.get('csvIDs', None)
		if heldItemID is None or csvIDs is None:
			raise ClientError('param miss')
		heldItem = self.game.heldItems.getHeldItem(heldItemID)
		if heldItem is None or not heldItem.exist_flag:
			raise ClientError('heldItemID error')

		heldItem.strengthHeldItem(csvIDs)
		cardID = heldItem.card_db_id
		if cardID:
			card = self.game.cards.getCard(cardID)
			card.calcHeldItemAttrsAddition(card)
			card.onUpdateAttrs()


# 携带道具 突破
class HeldItemAdvance(RequestHandlerTask):
	url = r'/game/helditem/advance'

	@coroutine
	def run(self):
		heldItemID = self.input.get('heldItemID', None)
		costHeldItemIDs = self.input.get('costHeldItemIDs', None) # 手动选择消耗携带道具
		itemsD = self.input.get('itemsD', None) # 万能替代道具
		if heldItemID is None:
			raise ClientError('param miss')
		heldItem = self.game.heldItems.getHeldItem(heldItemID)
		if heldItem is None or not heldItem.exist_flag:
			raise ClientError('heldItemID error')
		if costHeldItemIDs is None and itemsD is None:
			raise ClientError('param miss')

		if costHeldItemIDs:
			costHeldItems = self.game.heldItems.getHeldItems(costHeldItemIDs)
			if len(costHeldItems) != len(costHeldItemIDs):
				raise ClientError('param error')
			for v in costHeldItems:
				if v.id == heldItem.id:
					raise ClientError('be self')
		else:
			costHeldItems = []
		if itemsD is None:
			itemsD = {}

		heldItem.advanceHeldItem(costHeldItems, itemsD)
		cardID = heldItem.card_db_id
		if cardID:
			card = self.game.cards.getCard(cardID)
			card.calcHeldItemAttrsAddition(card)
			card.onUpdateAttrs()


# 携带道具 重生
class HeldItemRebirth(RequestHandlerTask):
	url = r'/game/helditem/rebirth'

	@coroutine
	def run(self):
		heldItemID = self.input.get('heldItemID', None)
		if heldItemID is None:
			raise ClientError('param miss')
		heldItem = self.game.heldItems.getHeldItem(heldItemID)
		if heldItem is None or not heldItem.exist_flag:
			raise ClientError('heldItemID error')
		# 重生
		rebirthObj = ObjectHeldItemsRebirth(self.game, heldItem)
		eff = rebirthObj.getEffect(1) # 携带道具重生返回的比例在内部处理，故这里传入1
		# 消耗 钻石
		costRmb = rebirthObj.rebirthCost(eff.result, CardResetDefs.heldItemRmbCostType)
		cost = ObjectCostAux(self.game, {'rmb': costRmb})
		if not cost.isEnough():
			raise ClientError('cost rmb not enough')
		cost.cost(src='heldItem_rebirth')
		rebirthObj.rebirth()
		# 获得道具 金币
		if eff:
			yield effectAutoGain(eff, self.game, self.dbcGame, src='heldItem_rebirth')
		cardID = heldItem.card_db_id
		if cardID:
			card = self.game.cards.getCard(cardID)
			card.calcHeldItemAttrsAddition(card)
			card.onUpdateAttrs()
		self.write({
			'view': {
				'result': eff.result
			}
		})
