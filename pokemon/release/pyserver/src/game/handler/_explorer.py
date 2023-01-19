#!/usr/bin/python
# -*- coding: utf-8 -*-

from framework import nowtime_t
from framework.log import logger
from framework.csv import ErrDefs
from game import ClientError
from game.globaldata import ShopRefreshItem
from game.object import FeatureDefs, AchievementDefs
from game.object.game import ObjectFeatureUnlockCSV
from game.object.game.shop import ObjectExplorerShop
from game.object.game.costcsv import ObjectCostCSV
from game.object.game.gain import ObjectCostAux
from game.handler import RequestHandlerTask
from game.handler.inl import effectAutoGain

from tornado.gen import coroutine, Return


# 探险器 组件激活/升级
class ExplorerComponentStrength(RequestHandlerTask):
	url = r'/game/explorer/component/strength'

	@coroutine
	def run(self):
		if not ObjectFeatureUnlockCSV.isOpen(FeatureDefs.Explorer, self.game):
			raise ClientError('locked')
		componentCsvID = self.input.get('componentCsvID', None)
		if componentCsvID is None:
			raise ClientError('param miss')

		self.game.explorer.componentStrength(componentCsvID)
		# 属性加成
		for card in self.game.cards.getCards(self.game.role.cards):
			card.calcExplorerComponentAttrsAddition(card, self.game.explorer)
			card.onUpdateAttrs()


# 探险器 激活/进阶
class ExplorerAdvance(RequestHandlerTask):
	url = r'/game/explorer/advance'

	@coroutine
	def run(self):
		if not ObjectFeatureUnlockCSV.isOpen(FeatureDefs.Explorer, self.game):
			raise ClientError('locked')
		explorerCsvID = self.input.get('explorerCsvID', None)
		if explorerCsvID is None:
			raise ClientError('param miss')

		self.game.explorer.explorerAdvance(explorerCsvID)
		# 属性加成
		for card in self.game.cards.getCards(self.game.role.cards):
			card.calcExplorerAttrsAddition(card, self.game.explorer)
			card.onUpdateAttrs()


# 探险器 组件分解
class ExplorerComponentDecompose(RequestHandlerTask):
	url = r'/game/explorer/component/decompose'

	@coroutine
	def run(self):
		if not ObjectFeatureUnlockCSV.isOpen(FeatureDefs.Explorer, self.game):
			raise ClientError('locked')
		# {itemID: count}
		componentItems = self.input.get('componentItems', None)
		if componentItems is None:
			raise ClientError('param miss')
		eff = self.game.explorer.componentDecompose(componentItems)
		# 获得寻宝币
		if eff:
			yield effectAutoGain(eff, self.game, self.dbcGame, src='explorer_component_decompose')


@coroutine
def getShopModel(game, dbc, refresh=False):
	if game.role.explorer_shop_db_id:
		# 强制刷新 或 过期
		if refresh or game.explorerShop.isPast():
			game.role.explorer_shop_db_id = None
			ObjectExplorerShop.addFreeObject(game.explorerShop)
			game.explorerShop = ObjectExplorerShop(game, dbc)
	# 重新生成商店
	if not game.role.explorer_shop_db_id:
		last_time = nowtime_t()
		roleID = game.role.id
		items = ObjectExplorerShop.makeShopItems(game)
		model = ObjectExplorerShop.getFreeModel(roleID, items, last_time)  # 回收站中取
		fromDB = False
		if model is None:
			ret = yield dbc.call_async('DBCreate', 'ExplorerShop', {
				'role_db_id': roleID,
				'items': items,
				'last_time': last_time,
			})
			model = ret['model']
			fromDB = True
		game.role.explorer_shop_db_id = model['id']
		game.explorerShop = ObjectExplorerShop(game, dbc).dbset(model, fromDB).init()

	raise Return(game.explorerShop)

# 刷新寻宝商店
class ExplorerShopRefresh(RequestHandlerTask):
	url = r'/game/explorer/shop/refresh'

	@coroutine
	def run(self):
		if not self.game.role.explorer_shop_db_id:
			raise ClientError(ErrDefs.shopNotExisted)
		# 是否代金券刷新 钻石刷新可不传
		itemRefresh = self.input.get('itemRefresh', None)
		if not itemRefresh:
			refreshTimes = self.game.dailyRecord.explorer_shop_refresh_times
			if refreshTimes >= self.game.role.explorerShopRefreshLimit:
				raise ClientError(ErrDefs.shopRefreshUp)
			costRMB = ObjectCostCSV.getExplorerShopRefreshCost(refreshTimes)
			cost = ObjectCostAux(self.game, {'rmb': costRMB})
			if not cost.isEnough():
				raise ClientError("cost rmb not enough")
			self.game.dailyRecord.explorer_shop_refresh_times = refreshTimes + 1
		else:
			cost = ObjectCostAux(self.game, {ShopRefreshItem: 1})
			if not cost.isEnough():
				raise ClientError("cost item not enough")
		cost.cost(src='explorer_shop_refresh')
		yield getShopModel(self.game, self.dbcGame, True)
		self.game.achievement.onCount(AchievementDefs.ShopRefresh, 1)

# 寻宝商店购买
class ExplorerShopBuy(RequestHandlerTask):
	url = r'/game/explorer/shop/buy'

	@coroutine
	def run(self):
		idx = self.input.get('idx', None)
		shopID = self.input.get('shopID', None)
		itemID = self.input.get('itemID', None)
		count = self.input.get('count', 1) # 只增对限购类型生效
		if not all([x is not None for x in [idx, shopID, itemID]]):
			raise ClientError('param miss')
		if count <= 0:
			raise ClientError('param error')
		if not self.game.role.explorer_shop_db_id:
			raise ClientError(ErrDefs.shopNotExisted)
		# 商店过期了
		oldID = self.game.explorerShop.id
		explorerShop = yield getShopModel(self.game, self.dbcGame)
		if oldID != explorerShop.id:
			raise ClientError(ErrDefs.shopRefresh)
		eff = self.game.explorerShop.buyItem(idx, shopID, itemID, count, src='explorer_shop_buy')
		yield effectAutoGain(eff, self.game, self.dbcGame, src='explorer_shop_buy')

# 获取寻宝商店数据
class ExplorerShopGet(RequestHandlerTask):
	url = r'/game/explorer/shop/get'

	@coroutine
	def run(self):
		if not ObjectFeatureUnlockCSV.isOpen(FeatureDefs.Explorer, self.game):
			raise ClientError('locked')
		yield getShopModel(self.game, self.dbcGame)
