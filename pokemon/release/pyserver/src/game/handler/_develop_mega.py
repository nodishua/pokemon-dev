#!/usr/bin/python
# coding=utf-8
from framework.csv import ErrDefs, csv, ConstDefs
from framework.log import logger
from game import ClientError
from game.handler import RequestHandlerTask
from game.handler.inl import effectAutoGain, battleCardsAutoDeployment, battleCardsAutoDeploymentByNatureCheck
from game.object import FeatureDefs, MegaDefs
from game.object.game import ObjectFeatureUnlockCSV, ObjectCostCSV
from game.object.game.gain import ObjectGainAux, ObjectCostAux
from tornado.gen import coroutine


#  超进化
class DevelopMega(RequestHandlerTask):
	url = r'/game/develop/mega'

	@coroutine
	def run(self):
		if not ObjectFeatureUnlockCSV.isOpen(FeatureDefs.Mega, self.game):
			raise ClientError(ErrDefs.megaNotOpen)
		cardID = self.input.get('cardID', None)  # 本体
		branch = self.input.get('branch', None)  # 分支
		costCardIDs = self.input.get('costCardIDs', [])  # [cardID ...]
		if cardID is None or branch is None:
			raise ClientError('param miss')
		card = self.game.cards.getCard(cardID)
		if card is None:
			raise ClientError('cardID error')
		oldCardID = card.card_id

		costCards = self.game.cards.getCostCards(costCardIDs, cardID)
		yield battleCardsAutoDeployment(costCardIDs, self.game, **self.rpcs)

		self.game.badge.resetBadgeCache(card)
		oldNatures = (card.natureType, card.natureType2)
		card.riseDevelopMega(branch, costCards)
		self.game.pokedex.addPokedex([card.id])
		newNatures = (card.natureType, card.natureType2)

		yield battleCardsAutoDeploymentByNatureCheck(self.game, cardID, oldNatures, newNatures, **self.rpcs)

		zawakeIDOld = csv.cards[oldCardID].zawakeID
		zawakeIDNew = csv.cards[card.card_id].zawakeID
		if zawakeIDOld and zawakeIDOld != zawakeIDNew:
			eff = self.game.zawake.reset(zawakeIDOld, auto=True)
			if eff:
				yield effectAutoGain(eff, self.game, self.dbcGame, src='zawake_reset_from_mega')
				self.write({"view": eff.result})


# 精灵 转化 进化石/钥石
class DevelopMegaConvertCard(RequestHandlerTask):
	url = r'/game/develop/mega/convert/card'

	@coroutine
	def run(self):
		if not ObjectFeatureUnlockCSV.isOpen(FeatureDefs.Mega, self.game):
			raise ClientError(ErrDefs.megaNotOpen)
		csvID = self.input.get('csvID', None)
		costCardID = self.input.get('costCardID', None)  # cardDBID
		if csvID is None or costCardID is None:
			raise ClientError('param miss')

		costCards = self.game.cards.getCostCards([costCardID])
		yield battleCardsAutoDeployment([costCardID], self.game, **self.rpcs)

		# 转化
		num = self.game.cards.cardConvertMegaItems(csvID, costCards[0])

		eff = ObjectGainAux(self.game, {csvID: num})
		yield effectAutoGain(eff, self.game, self.dbcGame, src='mega_convert_card')


# 碎片 转化 进化石/钥石
class DevelopMegaConvertFrag(RequestHandlerTask):
	url = r'/game/develop/mega/convert/frag'

	@coroutine
	def run(self):
		if not ObjectFeatureUnlockCSV.isOpen(FeatureDefs.Mega, self.game):
			raise ClientError(ErrDefs.megaNotOpen)
		csvID = self.input.get('csvID', None)
		num = self.input.get('num', None)  # 转化数量
		costFragID = self.input.get('costFragID', None)  # fragID
		if csvID is None or num is None or costFragID is None:
			raise ClientError('param miss')

		# 转化
		self.game.cards.fragConvertMegaItems(csvID, num, costFragID)

		eff = ObjectGainAux(self.game, {csvID: num})
		yield effectAutoGain(eff, self.game, self.dbcGame, src='mega_convert_frag')


# 转化 进化石/钥石 次数购买
class DevelopMegaConvertBuy(RequestHandlerTask):
	url = r'/game/develop/mega/convert/buy'

	@coroutine
	def run(self):
		if not ObjectFeatureUnlockCSV.isOpen(FeatureDefs.Mega, self.game):
			raise ClientError(ErrDefs.megaNotOpen)

		csvID = self.input.get('csvID', None)
		if csvID is None:
			raise ClientError('param miss')

		costRMB = 0
		cfg = csv.card_mega_convert[csvID]
		times = self.game.role.mega_convert_times.get(csvID, 0)
		afterBuyTimes = 0
		buyChance = self.game.dailyRecord.mega_convert_buy_times.get(csvID, 0)

		if cfg.type == MegaDefs.MegaCommonItem:
			# 钥石购买机会达上限
			if buyChance >= ConstDefs.megaCommonBuyChanceLimit:
				raise ClientError(ErrDefs.megaCommonBuyChanceLimit)
			afterBuyTimes = ConstDefs.megaCommonBuyAddTimes + times
			# 钥石购买数量超上限
			if afterBuyTimes > self.game.role.megaCommonItemMaxTimes:
				raise ClientError(ErrDefs.megaCommonBuyLimit)
			costRMB = ObjectCostCSV.getMegaCommonItemConvertBuyCost(buyChance)
		elif cfg.type == MegaDefs.MegaItem:
			# 进化石购买机会达上限
			if buyChance >= ConstDefs.megaBuyChanceLimit:
				raise ClientError(ErrDefs.megaBuyChanceLimit)
			afterBuyTimes = ConstDefs.megaBuyAddTimes + times
			# 进化石购买数量超上限
			if afterBuyTimes > self.game.role.megaItemMaxTimes:
				raise ClientError(ErrDefs.megaBuyLimit)
			costRMB = ObjectCostCSV.getMegaItemConvertBuyCost(buyChance)

		cost = ObjectCostAux(self.game, {'rmb': costRMB})
		if not cost.isEnough():
			raise ClientError(ErrDefs.buyRMBNotEnough)
		cost.cost(src='mega_convert_times_buy')

		self.game.role.mega_convert_times[csvID] = afterBuyTimes
		self.game.dailyRecord.mega_convert_buy_times[csvID] = buyChance + 1

