#!/usr/bin/env python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2014 YouMi Information Technology Inc.

Fishing Monster Handlers
'''

from framework import nowtime_t
from framework.csv import ErrDefs, csv
from game import ClientError
from game.globaldata import ShopRefreshItem
from game.object import FeatureDefs, AchievementDefs, TargetDefs
from game.object.game.yyhuodong import ObjectYYHuoDongFactory
from game.object.game.costcsv import ObjectCostCSV
from game.object.game.levelcsv import ObjectFeatureUnlockCSV
from game.object.game.gain import ObjectCostAux, ObjectGainAux
from game.object.game.shop import ObjectFishingShop
from game.object.game.cross_fishing import ObjectCrossFishingGameGlobal
from game.handler.task import RequestHandlerTask
from game.handler.inl import effectAutoGain
from game.thinkingdata import ta

from tornado.gen import coroutine, Return


@coroutine
def updateRankToCross(game):
	top3 = []
	if game.fishing.pointUpd and ObjectCrossFishingGameGlobal.isOpen(game.role.areaKey):
		rpc = ObjectCrossFishingGameGlobal.cross_client(game.role.areaKey)
		top3 = yield rpc.call_async('CrossFishingUpdate', game.role.areaKey, [game.role.makeCrossFishingRankModel()])
		game.fishing.pointUpd = False
	raise Return(top3)


# 钓鱼 准备
class FishingPerpare(RequestHandlerTask):
	url = '/game/fishing/prepare'

	@coroutine
	def run(self):
		if not ObjectFeatureUnlockCSV.isOpen(FeatureDefs.Fishing, self.game):
			raise ClientError('fishing not open')

		# 自动钓鱼时不能切换
		if self.game.fishing.is_auto:
			raise ClientError('in auto fishing')

		itemType = self.input.get('itemType', None)  # scene / rod / bait / partner
		itemID = self.input.get('itemID', None)  # partner -1 时表示不带伙伴

		if not itemType or not itemID:
			raise ClientError('param miss')

		fishing = self.game.fishing

		if itemType == 'scene':
			cfg = csv.fishing.scene[itemID]
			if not cfg:
				raise ClientError('scene ID error')
			if cfg.needLv > fishing.level:
				raise ClientError('scene need unlock first')
			if cfg.type == fishing.PlaySceneType and not ObjectCrossFishingGameGlobal.isOpen(self.game.role.areaKey):
				raise ClientError('play not open')
			fishing.select_scene = itemID
		elif itemType == 'rod':
			cfg = csv.fishing.rod[itemID]
			if not self.game.items.isEnough({cfg.itemId: 1}):
				raise ClientError('rod need unlock first')
			fishing.select_rod = itemID
		elif itemType == 'bait':
			cfg = csv.fishing.bait[itemID]
			if not cfg:
				raise ClientError('bait ID error')
			if cfg.needLv > fishing.level:
				raise ClientError('bait need unlock first')
			# 不配置鱼饵适用场景时，默认全场景适用
			if cfg.scene and fishing.select_scene not in cfg.scene:
				raise ClientError('bait can not use in selected scene')
			if not self.game.items.isEnough({cfg.itemId: 1}):
				raise ClientError('bait not enough')
			fishing.select_bait = itemID
		elif itemType == 'partner':
			if itemID not in fishing.partner and itemID != -1:
				raise ClientError('partner need unlock first')
			fishing.select_partner = itemID
		else:
			raise ClientError('itemType error')


# 钓鱼道具解锁
class FishingItemUnlock(RequestHandlerTask):
	url = '/game/fishing/item/unlock'

	@coroutine
	def run(self):
		if not ObjectFeatureUnlockCSV.isOpen(FeatureDefs.Fishing, self.game):
			raise ClientError('fishing not open')

		itemType = self.input.get('itemType', None)  # rod、 partner
		itemID = self.input.get('itemID', None)
		if not itemType or not itemID:
			raise ClientError('itemID miss')

		fishing = self.game.fishing

		if itemType == 'rod':
			cfg = csv.fishing.rod[itemID]
			if not cfg:
				raise ClientError('rodID error')
			if self.game.items.isEnough({cfg.itemId: 1}):
				raise ClientError('rod had been unlocked')
			if cfg.needLv > fishing.level:
				raise ClientError('unlock condition limit')
			if not cfg.cost:
				raise ClientError('this rod other way unlock')

			cost = ObjectCostAux(self.game, cfg.cost)
			if not cost.isEnough():
				raise ClientError('rod unlock cost not enough')
			cost.cost(src='fishing_rod_unlock')

			eff = ObjectGainAux(self.game, {cfg.itemId: 1})
			if eff:
				yield effectAutoGain(eff, self.game, self.dbcGame, src='fishing_rod_unlock')
		elif itemType == 'partner':
			if itemID in fishing.partner:
				raise ClientError('partner had been unlocked')
			cfg = csv.fishing.partner[itemID]
			if not cfg:
				raise ClientError('partner ID error')

			if cfg.needLv > fishing.level or cfg.unitId not in self.game.role.pokedex:
				raise ClientError('unlock condition limit')

			cost = ObjectCostAux(self.game, cfg.cost)
			if not cost.isEnough():
				raise ClientError('partner unlock cost not enough')
			cost.cost(src='fishing_partner_unlock')
			fishing.partner[itemID] = int(nowtime_t())
		else:
			raise ClientError('itemType error')


# 买鱼饵
class FishingBaitBuy(RequestHandlerTask):
	url = '/game/fishing/bait/buy'

	@coroutine
	def run(self):
		if not ObjectFeatureUnlockCSV.isOpen(FeatureDefs.Fishing, self.game):
			raise ClientError('fishing not open')
		baitID = self.input.get('baitID', None)
		count = self.input.get('count', 1)

		if not baitID:
			raise ClientError('param miss')

		cfg = csv.fishing.bait[baitID]
		if not cfg:
			raise ClientError('baitID error')

		fishing = self.game.fishing
		if not cfg.cost or cfg.needLv > fishing.level:
			raise ClientError('purchase condition limit')

		cost = ObjectCostAux(self.game, cfg.cost)
		cost *= count
		if not cost.isEnough():
			raise ClientError('buy bait cost not enough')
		cost.cost(src='fishing_bait_buy')

		eff = ObjectGainAux(self.game, {cfg.itemId: count})
		if eff:
			yield effectAutoGain(eff, self.game, self.dbcGame, src='fishing_bait_buy')


@coroutine
def getShopModel(game, dbc, refresh=False):
	# 商店存在
	if game.role.fishing_shop_db_id:
		# 强制刷新 或 过期
		if refresh or game.fishingShop.isPast():
			game.role.fishing_shop_db_id = None
			ObjectFishingShop.addFreeObject(game.fishingShop)
			game.fishingShop = ObjectFishingShop(game, dbc)
	# 重新生成商店
	if not game.role.fishing_shop_db_id:
		last_time = nowtime_t()
		roleID = game.role.id
		items = ObjectFishingShop.makeShopItems(game)
		model = ObjectFishingShop.getFreeModel(roleID, items, last_time)
		fromDB = False
		if model is None:
			ret = yield dbc.call_async('DBCreate', "FishingShop", {
				'role_db_id': roleID,
				'items': items,
				'last_time': last_time,
			})
			model = ret['model']
			fromDB = True

		game.role.fishing_shop_db_id = model['id']
		game.fishingShop = ObjectFishingShop(game, dbc).dbset(model, fromDB).init()

	raise Return(game.fishingShop)


# 获取钓鱼商店数据
class FishingShopGet(RequestHandlerTask):
	url = '/game/fishing/shop/get'

	@coroutine
	def run(self):
		if not self.game.role.fishing_db_id:
			raise ClientError(ErrDefs.shopNotExisted)
		yield getShopModel(self.game, self.dbcGame)


# 钓鱼商店购买
class FishingShopBuy(RequestHandlerTask):
	url = '/game/fishing/shop/buy'

	@coroutine
	def run(self):
		idx = self.input.get('idx', None)
		shopID = self.input.get('shopID', None)
		itemID = self.input.get('itemID', None)
		count = self.input.get('count', 1)  # 只增对限购类型生效
		if not all([x is not None for x in [idx, shopID, itemID]]):
			raise ClientError('param miss')
		if count <= 0:
			raise ClientError('param error')
		if not self.game.role.fishing_db_id or not self.game.role.fishing_shop_db_id:
			raise ClientError(ErrDefs.shopNotExisted)
		# 商店过期了
		oldID = self.game.fishingShop.id
		fishingShop = yield getShopModel(self.game, self.dbcGame)
		if oldID != fishingShop.id:
			raise ClientError(ErrDefs.shopRefresh)
		eff = self.game.fishingShop.buyItem(idx, shopID, itemID, count, src='fishing_shop_buy')
		yield effectAutoGain(eff, self.game, self.dbcGame, src='fishing_shop_buy')


# 钓鱼商店刷新
class FishingShopRefresh(RequestHandlerTask):
	url = '/game/fishing/shop/refresh'

	@coroutine
	def run(self):
		if not self.game.role.fishing_db_id or not self.game.role.fishing_shop_db_id:
			raise ClientError(ErrDefs.shopNotExisted)
		# 是否代金券刷新 钻石刷新可不传
		itemRefresh = self.input.get('itemRefresh', None)
		if not itemRefresh:
			refreshTimes = self.game.dailyRecord.fishing_shop_refresh_times
			if refreshTimes >= self.game.role.fishingShopRefreshLimit:
				raise ClientError(ErrDefs.shopRefreshUp)
			costRMB = ObjectCostCSV.getFishingShopRefreshCost(refreshTimes)
			cost = ObjectCostAux(self.game, {'rmb': costRMB})
			if not cost.isEnough():
				raise ClientError("cost rmb not enough")
			self.game.dailyRecord.fishing_shop_refresh_times = refreshTimes + 1
		else:
			cost = ObjectCostAux(self.game, {ShopRefreshItem: 1})
			if not cost.isEnough():
				raise ClientError("cost item not enough")
		cost.cost(src='fishing_shop_refresh')
		yield getShopModel(self.game, self.dbcGame, True)
		self.game.achievement.onCount(AchievementDefs.ShopRefresh, 1)

# 钓鱼主界面
class FishingMain(RequestHandlerTask):
	url = r'/game/fishing/main'

	@coroutine
	def run(self):
		self.game.fishing.checkAuto()
		top3 = yield updateRankToCross(self.game)
		if top3:
			self.write({'view': {'top3': top3}})


# 钓鱼单次开始
class FishingOnceStart(RequestHandlerTask):
	url = r'/game/fishing/once/start'

	@coroutine
	def run(self):
		if self.game.fishing.is_auto:
			raise ClientError("in auto fishing")

		self.game.fishing.onceStart()

		self.write({'view': {'fish': self.game.fishing.fishingCsvID}})


# 钓鱼单次开始操作
class FishingOnceDoing(RequestHandlerTask):
	url = r'/game/fishing/once/doing'

	@coroutine
	def run(self):
		if self.game.fishing.is_auto:
			raise ClientError("in auto fishing")

		fish = self.input.get('fish', None)
		if fish != self.game.fishing.fishingCsvID:
			raise ClientError('fish error')

		self.game.fishing.onceDoing()


# 钓鱼单次结束
class FishingOnceEnd(RequestHandlerTask):
	url = r'/game/fishing/once/end'

	@coroutine
	def run(self):
		fish = self.input.get('fish', None)
		result = self.input.get('result', None)
		if fish is None or result is None:
			raise ClientError('param miss')

		if fish != self.game.fishing.fishingCsvID:
			raise ClientError('fish error')

		if not self.game.fishing.fishingDoing:
			raise ClientError('not doing has cheat')

		if self.game.fishing.is_auto:
			raise ClientError("in auto fishing")

		eff, length = self.game.fishing.onceEnd(result)
		if eff:
			yield effectAutoGain(eff, self.game, self.dbcGame, src='fishing_once_win')
		view = {'length': length, 'award': eff.result if eff else {}}

		top3 = []
		if result == 'win':
			self.game.fishing.calcPointAndSpecialFish(fish, length)
			self.game.dailyRecord.fishing_win_counter += 1
			ObjectYYHuoDongFactory.onGeneralTask(self.game, TargetDefs.FishingWinTimes, 1)
			top3 = yield updateRankToCross(self.game)

		if top3:
			view['top3'] = top3

		self.write({'view': view})
		awardMap = eff.result if eff else {}
		ta.track(self.game, event='fishing',target_fish_id=fish,fishing_result=result,get_prize_list=awardMap.keys())


# 钓鱼自动开始
class FishingAutoStart(RequestHandlerTask):
	url = r'/game/fishing/auto/start'

	@coroutine
	def run(self):
		if self.game.fishing.is_auto:
			raise ClientError("in auto fishing")

		self.game.fishing.autoStart()

# 钓鱼自动结束
class FishingAutoEnd(RequestHandlerTask):
	url = r'/game/fishing/auto/end'

	@coroutine
	def run(self):
		if not self.game.fishing.is_auto:
			raise ClientError("not in auto")

		# 结束前再检查一遍，所见即所得，结束时不触发自动钓鱼
		# self.game.fishing.checkAuto()

		eff = self.game.fishing.autoEnd()
		if eff:
			yield effectAutoGain(eff, self.game, self.dbcGame, src="fishing_auto_end")

		ObjectCrossFishingGameGlobal.clearRoleAuto(self.game.role.id, self.game.role.areaKey)

		self.write({'view': eff.result if eff else {}})
		awardMap = eff.result if eff else {}
		ta.track(self.game, event='fishing',get_prize_list=awardMap.keys())


class FishingOneKey(RequestHandlerTask):
	url = r'/game/fishing/onekey'

	@coroutine
	def run(self):
		if self.game.fishing.is_auto:
			raise ClientError('in auto fishing')

		eff, fish, win, fail = self.game.fishing.oneKey()
		if eff:
			yield effectAutoGain(eff, self.game, self.dbcGame, src="fishing_oneKey")
		view = {
			'fish': fish,
			'award': eff.result if eff else {},
			'win': win,
			'fail': fail
		}

		top3 = yield updateRankToCross(self.game)
		if top3:
			view['top3'] = top3

		self.write({'view': view})


# 钓鱼大赛排名
class CrossFishingRank(RequestHandlerTask):
	url = r'/game/cross/fishing/rank'

	@coroutine
	def run(self):
		if ObjectCrossFishingGameGlobal.isOpen(self.game.role.areaKey):
			rpc = ObjectCrossFishingGameGlobal.cross_client(self.game.role.areaKey)
			view = yield rpc.call_async('CrossFishingRankInfo', self.game.role.areaKey, self.game.role.id)
			crossFishingGameGlobal = ObjectCrossFishingGameGlobal.getByAreaKey(self.game.role.areaKey)
			view['servers'] = crossFishingGameGlobal.servers
		else:
			view = ObjectCrossFishingGameGlobal.getRankInfo(self.game.role.id, self.game.role.areaKey)

		self.write({'view': view})
