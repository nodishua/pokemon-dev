#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2014 YouMi Information Technology Inc.
'''

from framework import period2date, date2int, nowtime_t, todaydate2int, nowtime2period, time2period, datetimefromtimestamp, todayinclock5date2int, inclock5date
from framework.csv import csv, ErrDefs
from framework.helper import getRandomSeed, WeightRandomObject, addDict
from framework.object import ReloadHooker, ObjectDBase, db_property, GCWeakValueDictionary, ObjectBase
from game import ClientError, ServerError
from game import globaldata
from game.globaldata import ShopRefreshTime, ShopRefreshPeriods, FishingShopRefreshTime
from game.object import FixShopDefs
from game.object.game.gain import ObjectGainAux, ObjectCostAux, ObjectGainEffect
from game.handler.inl import effectAutoCost

import random
import weakref
import datetime
from collections import deque, defaultdict

from tornado.gen import coroutine, Return


#
# ObjectShopRandom
#

class ObjectShopRandom(ReloadHooker):

	ShopMap = {}
	VIPFixShop = []
	VIPRandomShop = []
	RefreshDate = 20140101
	CSVFile = ''

	@classmethod
	def classInit(cls):
		cls.RefreshDate = date2int(period2date(ShopRefreshTime))
		cls.ShopMap = {}
		cls.VIPFixShop = [[] for i in xrange(globaldata.VIPLevelMax + 1)]
		cls.VIPRandomShop = [[] for i in xrange(globaldata.VIPLevelMax + 1)]
		if isinstance(cls.CSVFile, (tuple, list)):
			csvFile = csv
			for part in cls.CSVFile:
				csvFile = csvFile[part]
		else:
			csvFile = csv[cls.CSVFile]
		for idx in csvFile:
			cls(csvFile[idx])

	@classmethod
	def _getRandomGenerator(cls, game):
		obj = game.rndMap.setdefault(cls.__name__, random.Random(getRandomSeed() ^ game.role.uid))
		return obj

	@classmethod
	def getRandomShop(cls, game, vip, level):
		if date2int(period2date(ShopRefreshTime)) != cls.RefreshDate:
			cls.classInit()

		position = defaultdict(list)
		rndobj = cls._getRandomGenerator(game)
		fixlst = cls.VIPFixShop[vip]
		for obj in fixlst:
			# 判定玩家等级
			if level < obj._cfg.levelRange[0] or level > obj._cfg.levelRange[1]:
				continue
			position[obj._cfg.position].append(obj)

		fixpos = set(position.keys())
		rndlst = cls.VIPRandomShop[vip]
		for obj in rndlst:
			# 判断该栏位是否已有固定出现的
			if obj._cfg.position in fixpos:
				continue
			# 判定玩家等级
			if level < obj._cfg.levelRange[0] or level > obj._cfg.levelRange[1]:
				continue
			position[obj._cfg.position].append(obj)

		# 随机栏位和物品
		for p, lst in position.iteritems():
			# 固定出现直接随机
			if lst[0]._cfg.vipWeight == -1:
				obj = rndobj.choice(lst)
			else:
				obj = WeightRandomObject.onceRandom(lst, lambda o: o._cfg.vipWeight)
			position[p] = (obj.id, obj.getRandomItem(rndobj))

		ret = {p: v for p, v in position.iteritems()}
		return ret

	@classmethod
	def _addObj(cls, obj):
		cls.ShopMap[obj.id] = obj
		for i in xrange(obj._cfg.vipStart, globaldata.VIPLevelMax + 1):
			# -1=必定出现
			if obj._cfg.vipWeight < 0:
				obj.VIPFixShop[i].append(weakref.proxy(obj))
			else:
				obj.VIPRandomShop[i].append(weakref.proxy(obj))

	def __init__(self, cfg):
		self._cfg = cfg
		if len(self._cfg.itemWeightMap) == 0:
			return

		# 有贩售时间的
		if cfg.beginDate != 0:
			# 时间已过
			if cfg.endDate <= self.RefreshDate:
				return
			# 时间未到
			if cfg.beginDate > self.RefreshDate:
				return

		self._addObj(self)

		self._itemSumWeight = 0
		for id in self._cfg.itemWeightMap:
			weight = self._cfg.itemWeightMap[id]
			self._itemSumWeight += weight

	def getRandomItem(self, rndobj):
		rnd = rndobj.randint(1, self._itemSumWeight)
		for id in self._cfg.itemWeightMap:
			weight = self._cfg.itemWeightMap[id]
			rnd -= weight
			if rnd <= 0:
				return id

	@property
	def id(self):
		return self._cfg.id


#
# ObjectShopEffect
#

class ObjectShopEffect(ObjectGainAux):

	def __init__(self, game, itemID, itemCount, afterGain):
		self._afterGain = afterGain
		ObjectGainAux.__init__(self, game, {itemID: itemCount})

	def gain(self, **kwargs):
		ObjectGainAux.gain(self, **kwargs)
		self._afterGain()


#
# ObjectUnionShopRandom
#


class ObjectUnionShopRandom(ObjectShopRandom):

	ShopMap = {}
	VIPFixShop = []
	VIPRandomShop = []
	RefreshDate = 20140101
	CSVFile = ('union', 'union_shop')

#
# ObjectExplorerShopRandom
#


class ObjectExplorerShopRandom(ObjectShopRandom):

	ShopMap = {}
	VIPFixShop = []
	VIPRandomShop = []
	RefreshDate = 20140101
	CSVFile = ('explorer', 'explorer_shop')

#
# ObjectFragShopRandom
#


class ObjectFragShopRandom(ObjectShopRandom):

	ShopMap = {}
	VIPFixShop = []
	VIPRandomShop = []
	RefreshDate = 20140101
	CSVFile = ('frag_shop')

#
# ObjectMysteryShopRandom
#


class ObjectMysteryShopRandom(ObjectShopRandom):

	ShopMap = {}
	VIPFixShop = []
	VIPRandomShop = []
	RefreshDate = 20140101
	CSVFile = 'mystery_shop'

#
# ObjectFixShopRandom
#


class ObjectFixShopRandom(ObjectShopRandom):
	'''
	固定商店刷新时间都按自然日来
	'''

	ShopMap = {}
	VIPFixShop = []
	VIPRandomShop = []
	RefreshDate = 20140101
	CSVFile = 'fix_shop'

#
# ObjectRandomTowerShopRandom
#

class ObjectRandomTowerShopRandom(ObjectShopRandom):

	ShopMap = {}
	VIPFixShop = []
	VIPRandomShop = []
	RefreshDate = 20140101
	CSVFile = ('random_tower', 'shop')

#
# ObjectEquipShopRandom
#

class ObjectEquipShopRandom(ObjectShopRandom):
	ShopMap = {}
	VIPFixShop = []
	VIPRandomShop = []
	RefreshDate = 20140101
	CSVFile = 'equip_shop'

	def __init__(self, cfg):
		if cfg.type != 2: # 1-固定；2-随机
			return
		ObjectShopRandom.__init__(self, cfg)


#
# ObjectFishingShopRandom
#
class ObjectFishingShopRandom(ObjectShopRandom):
	ShopMap = {}
	VIPFixShop = []
	VIPRandomShop = []
	RefreshDate = 20140101
	CSVFile = ('fishing', 'shop')

	@classmethod
	def classInit(cls):
		super(cls, cls).classInit()
		cls.RefreshDate = date2int(period2date(globaldata.FishingShopRefreshTime))

#
# ObjectPVPShop
#

class ObjectPVPShop(ObjectBase):
	Key = 'pvp_shop'

	def __init__(self, game):
		ObjectBase.__init__(self, game)
		self._shopDB = game.role.pvp_shop
		self.level = game.role.level

	@classmethod
	def csv(cls, csvID=None):
		if csvID is None:
			return csv.pwshop
		return csv.pwshop[csvID]

	def canBuy(self, csvID, count):
		import framework
		cfg = self.csv(csvID)
		if framework.__language__ not in cfg.languages:
			raise ClientError(ErrDefs.csvShopLanguageLimit)

		if count < 0:
			raise ClientError("count error")

		now = nowtime_t()
		nowInt = todaydate2int()
		if cfg.beginDate > nowInt or nowInt > cfg.endDate:
			raise ClientError(ErrDefs.csvShopNotInTime)

		if cfg.levelRange[0]>self.level or cfg.levelRange[1]<self.level:
			raise ClientError("level dissatisfy")

		if cfg.limitType:
			if not self.game.role.canShopBuy(self.Key, csvID, count, cfg.limitType, cfg.limitTimes):
				raise ClientError(ErrDefs.buyShopTimesLimit)

		if cfg.exchangeLimit != -1:
			if cfg.exchangeLimit < count:
				raise ClientError(ErrDefs.csvShopTimeNotEnough)

			if csvID in self._shopDB:
				buyTimes, lastRecoverTime = self._shopDB[csvID]
				point = int(now - lastRecoverTime) / (cfg.regainHour * 3600)
				if point >= 1:
					buyTimes -= point
					lastRecoverTime += point * (cfg.regainHour * 3600)
					self._shopDB[csvID] = (buyTimes, lastRecoverTime)

				if buyTimes >= cfg.exchangeLimit or cfg.exchangeLimit - buyTimes < count:
					raise ClientError(ErrDefs.csvShopTimeNotEnough)

				if buyTimes <= 0:
					self._shopDB.pop(csvID, None)

	def buyItem(self, csvID, count=1, **kwargs):
		self.canBuy(csvID, count)

		cfg = self.csv(csvID)
		costAux = ObjectCostAux(self.game, cfg.costMap)
		costAux *= count
		if not costAux.isEnough():
			raise ClientError(ErrDefs.csvShopCoinNotEnough)
		costAux.cost(**kwargs)

		def afterGain():
			if cfg.limitType:
				self.game.role.addShopBuy(self.Key, csvID, count, cfg.limitType)
			if cfg.exchangeLimit != -1:
				if csvID in self._shopDB:
					buyTimes, lastRecoverTime = self._shopDB[csvID]
					self._shopDB[csvID] = (buyTimes + count, lastRecoverTime)
				else:
					self._shopDB[csvID] = (count, nowtime_t())

		eff = ObjectGainEffect(self.game, cfg.itemMap, afterGain)
		eff *= count
		return eff


#
# ObjectFixShop
#

class ObjectFixShop(ObjectDBase):
	Key = 'fix_shop'
	DBModel = 'FixShop'

	ShopsObjsMap = GCWeakValueDictionary()

	@classmethod
	def classInit(cls):
		for obj in cls.ShopsObjsMap.itervalues():
			obj.init()

	def init(self):
		if self._db is None:
			return self
		self.ShopsObjsMap[self.id] = self
		return ObjectDBase.init(self)

	@classmethod
	def csv(cls, csvID=None):
		if csvID is None:
			return csv.fix_shop
		return csv.fix_shop[csvID]

	# Role.id
	def role_db_id():
		dbkey = 'role_db_id'
		return locals()
	role_db_id = db_property(**role_db_id())

	# 商店商品列表 [(商店CSV ID, 商品CSV ID)]
	def items():
		dbkey = 'items'
		def fset(self, value):
			self.db[dbkey] = value
		return locals()
	items = db_property(**items())

	# 已购买商店格子下标（0下标开始） {index:True}
	def buy():
		dbkey = 'buy'
		return locals()
	buy = db_property(**buy())

	# 商店刷新时间 time
	def last_time():
		dbkey = 'last_time'
		return locals()
	last_time = db_property(**last_time())

	@classmethod
	def makeShopItems(cls, game):
		return ObjectFixShopRandom.getRandomShop(game, game.role.vip_level, game.role.level)

	def makeShop(self, items):
		self.items = items
		self.buy = {}
		self.last_time = nowtime_t()

	def canBuy(self, idx, cfg, itemID, count):
		if cfg.limitType:
			if not self.game.role.canShopBuy(self.Key, idx, count, cfg.limitType, cfg.limitTimes):
				raise ClientError(ErrDefs.buyShopTimesLimit)
		else:
			if count != 1:  # 随机刷新商店只能购买1次
				raise ClientError('count error')
			if idx in self.buy:
				raise ClientError(ErrDefs.shopItemBuyYet)

	def buyItem(self, idx, shopID, itemID, count, **kwargs):
		if tuple(self.items[idx]) != (shopID, itemID):
			raise ClientError('shopID or itemID error')
		cfg = self.csv(shopID)
		self.canBuy(idx, cfg, itemID, count)

		discount = kwargs.get('discount', 0)
		if discount > 1:
			raise ClientError('something error happend')
		costItem = ObjectCostAux(self.game, cfg.costMap)
		costItem.setCeil()
		costItem *= count
		costItem *= (1 - discount)
		if not costItem.isEnough():
			raise ClientError(ErrDefs.shopCoinNotEnough)
		costItem.cost(**kwargs)

		def afterGain():
			# 标记已购买
			self.buy[idx] = True
			if cfg.limitType:
				self.game.role.addShopBuy(self.Key, idx, count, cfg.limitType)
		return ObjectShopEffect(self.game, itemID, cfg.itemCount * count, afterGain)

	def isPast(self):
		'''
		判断商店是否过期
		'''
		lastdt = datetimefromtimestamp(self.last_time)
		now_p = nowtime2period(ShopRefreshPeriods)
		last_p = time2period(lastdt, ShopRefreshPeriods)
		return now_p != last_p


#
# ObjectUnionShop
#

class ObjectUnionShop(ObjectFixShop):
	Key = 'union_shop'
	DBModel = 'UnionShop'
	FreeList = deque()

	@classmethod
	def csv(cls, csvID=None):
		if csvID is None:
			return csv.union.union_shop
		return csv.union.union_shop[csvID]

	# 是否已废弃
	def discard_flag():
		dbkey = 'discard_flag'
		def fset(self, value):
			self.db[dbkey] = value
		return locals()
	discard_flag = db_property(**discard_flag())

	@classmethod
	def initFree(cls, ids):
		cls.FreeList = deque(ids)

	@classmethod
	def addFreeObject(cls, obj):
		obj.discard_flag = True
		cls.FreeList.append(obj.id)

	@classmethod
	def getFreeModel(cls, roleID, items, last_time):
		if cls.FreeList:
			id = cls.FreeList.popleft()
			return {
				'id': id,
				'role_db_id': roleID,
				'items': items,
				'buy': {},
				'last_time': last_time,
				'discard_flag': False,
			}
		return None

	@classmethod
	def makeShopItems(cls, game):
		return ObjectUnionShopRandom.getRandomShop(game, game.role.vip_level, game.role.level)


#
# ObjectExplorerShop
#

class ObjectExplorerShop(ObjectUnionShop):
	Key = 'explorer_shop'
	DBModel = 'ExplorerShop'
	FreeList = deque()

	@classmethod
	def csv(cls, csvID=None):
		if csvID is None:
			return csv.explorer.explorer_shop
		return csv.explorer.explorer_shop[csvID]

	@classmethod
	def makeShopItems(cls, game):
		return ObjectExplorerShopRandom.getRandomShop(game, game.role.vip_level, game.role.level)


#
# ObjectFragShop
#

class ObjectFragShop(ObjectUnionShop):
	Key = 'frag_shop'
	DBModel = 'FragShop'
	FreeList = deque()

	@classmethod
	def csv(cls, csvID=None):
		if csvID is None:
			return csv.frag_shop
		return csv.frag_shop[csvID]

	@classmethod
	def makeShopItems(cls, game):
		return ObjectFragShopRandom.getRandomShop(game, game.role.vip_level, game.role.level)


#
# ObjectCraftShop
#

class ObjectCraftShop(ObjectPVPShop):
	Key = 'craft_shop'

	def __init__(self, game):
		ObjectBase.__init__(self, game)
		self._shopDB = game.role.craft_shop
		self.level = game.role.level

	@classmethod
	def csv(cls, csvID=None):
		if csvID is None:
			return csv.craft.shop
		return csv.craft.shop[csvID]

#
# ObjectCrossCraftShop
#
class ObjectCrossCraftShop(ObjectPVPShop):
	Key = 'cross_craft_shop'

	def __init__(self, game):
		ObjectBase.__init__(self, game)
		self._shopDB = game.role.cross_craft_shop
		self.level = game.role.level

	@classmethod
	def csv(cls, csvID=None):
		if csvID is None:
			return csv.cross.craft.shop
		return csv.cross.craft.shop[csvID]

#
# ObjectCrossArenaShop
#
class ObjectCrossArenaShop(ObjectPVPShop):
	Key = 'cross_arena_shop'

	def __init__(self, game):
		ObjectBase.__init__(self, game)
		self._shopDB = game.role.cross_arena_shop
		self.level = game.role.level

	@classmethod
	def csv(cls, csvID=None):
		if csvID is None:
			return csv.cross.arena.shop
		return csv.cross.arena.shop[csvID]

#
# ObjectUnionFightShop
#

class ObjectUnionFightShop(ObjectPVPShop):
	Key = 'union_fight_shop'

	def __init__(self, game):
		ObjectBase.__init__(self, game)
		self._shopDB = game.role.union_fight_shop
		self.level = game.role.level

	@classmethod
	def csv(cls, csvID=None):
		if csvID is None:
			return csv.union_fight.shop
		return csv.union_fight.shop[csvID]

#
# ObjectCrossOnlineFightShop
#
class ObjectCrossOnlineFightShop(ObjectPVPShop):
	Key = 'cross_online_fight_shop'

	def __init__(self, game):
		ObjectBase.__init__(self, game)
		self._shopDB = game.role.cross_online_fight_shop
		self.level = game.role.level

	@classmethod
	def csv(cls, csvID=None):
		if csvID is None:
			return csv.cross.online_fight.shop
		return csv.cross.online_fight.shop[csvID]

	def canBuy(self, csvID, count):
		cfg = self.csv(csvID)
		info = self.game.role.cross_online_fight_info
		# 赛季最高积分限制
		if info['unlimited_top_score'] >= cfg.topScore or info['limited_top_score'] >= cfg.topScore:
			ObjectPVPShop.canBuy(self, csvID, count)
		else:
			raise ClientError('top score limited')
#
# ObjectCrossMineShop
#
class ObjectCrossMineShop(ObjectPVPShop):
	Key = 'cross_mine_shop'

	def __init__(self, game):
		ObjectBase.__init__(self, game)
		self._shopDB = game.role.cross_mine_shop
		self.level = game.role.level

	@classmethod
	def csv(cls, csvID=None):
		if csvID is None:
			return csv.cross.mine.shop
		return csv.cross.mine.shop[csvID]

	@coroutine
	def buyItem(self, csvID, count=1, **kwargs):
		self.canBuy(csvID, count)

		cfg = self.csv(csvID)
		costAux = ObjectCostAux(self.game, cfg.costMap)
		costAux *= count
		kwargs['errDef'] = ErrDefs.csvShopCoinNotEnough
		yield effectAutoCost(costAux, self.game, **kwargs)

		def afterGain():
			if cfg.limitType:
				self.game.role.addShopBuy(self.Key, csvID, count, cfg.limitType)
			if cfg.exchangeLimit != -1:
				if csvID in self._shopDB:
					buyTimes, lastRecoverTime = self._shopDB[csvID]
					self._shopDB[csvID] = (buyTimes + count, lastRecoverTime)
				else:
					self._shopDB[csvID] = (count, nowtime_t())

		eff = ObjectGainEffect(self.game, cfg.itemMap, afterGain)
		eff *= count
		raise Return(eff)


#
# ObjectHuntingShop
#
class ObjectHuntingShop(ObjectPVPShop):
	Key = 'hunting_shop'

	def __init__(self, game):
		ObjectBase.__init__(self, game)
		self._shopDB = game.role.hunting_shop
		self.level = game.role.level

	@classmethod
	def csv(cls, csvID=None):
		if csvID is None:
			return csv.cross.hunting.shop
		return csv.cross.hunting.shop[csvID]

	@coroutine
	def buyItem(self, csvID, count=1, **kwargs):
		self.canBuy(csvID, count)

		cfg = self.csv(csvID)
		costAux = ObjectCostAux(self.game, cfg.costMap)
		costAux *= count
		kwargs['errDef'] = ErrDefs.csvShopCoinNotEnough
		yield effectAutoCost(costAux, self.game, **kwargs)

		def afterGain():
			if cfg.limitType:
				self.game.role.addShopBuy(self.Key, csvID, count, cfg.limitType)
			if cfg.exchangeLimit != -1:
				if csvID in self._shopDB:
					buyTimes, lastRecoverTime = self._shopDB[csvID]
					self._shopDB[csvID] = (buyTimes + count, lastRecoverTime)
				else:
					self._shopDB[csvID] = (count, nowtime_t())

		eff = ObjectGainEffect(self.game, cfg.itemMap, afterGain)
		eff *= count
		raise Return(eff)


#
# ObjectRandomTowerShop
#

class ObjectRandomTowerShop(ObjectUnionShop):
	Key = 'random_tower_shop'
	DBModel = 'RandomTowerShop'
	FreeList = deque()

	@classmethod
	def csv(cls, csvID=None):
		if csvID is None:
			return csv.random_tower.shop
		return csv.random_tower.shop[csvID]

	@classmethod
	def makeShopItems(cls, game):
		return ObjectRandomTowerShopRandom.getRandomShop(game, game.role.vip_level, game.role.level)

#
# ObjectMysteryShop
#

class ObjectMysteryShop(ObjectFixShop):
	Key = 'mystery_shop'
	DBModel = 'MysteryShop'
	ShopsObjsMap = GCWeakValueDictionary()

	@classmethod
	def makeShopItems(cls, game):
		return ObjectMysteryShopRandom.getRandomShop(game, game.role.vip_level, game.role.level)

	@classmethod
	def csv(cls, csvID=None):
		if csvID is None:
			return csv.mystery_shop
		return csv.mystery_shop[csvID]

	#当前商店上次激活时间
	def last_active_time():
		dbkey = 'last_active_time'
		def fset(self, value):
			self.db[dbkey] = value
		return locals()
	last_active_time = db_property(**last_active_time())

	#记录当前商店的刷新次数
	def refresh_times():
		dbkey = 'refresh_times'
		def fset(self, value):
			self.db[dbkey] = value
		return locals()
	refresh_times = db_property(**refresh_times())

	def isPast(self):
		return self.last_time < self.last_active_time

	def onStaminaConsume(self, game, num):
		cfg = csv.mystery_shop_config[1]
		# 判断等级
		if game.role.level < cfg.min_level:
			return

		if self.inCD():
			return

		if game.dailyRecord.mystery_active_times > cfg.daily_active_times:
			return

		randomWeight = random.uniform(cfg.stamina_weight_min, cfg.stamina_weight_max)
		game.dailyRecord.mystery_shop_weight += randomWeight * num
		if game.dailyRecord.mystery_shop_weight >= 1:
			if self.isOpening():
				return
			self.active(game)

	# 激活商店
	def active(self, game):
		self.last_active_time = nowtime_t()
		self.refresh_times = 0
		game.dailyRecord.mystery_shop_weight -= 1
		game.dailyRecord.mystery_active_times += 1

	def isOpening(self):
		existTime = csv.mystery_shop_config[1].shop_exist_time
		opening = (nowtime_t() - self.last_active_time) < existTime
		return opening

	def inCD(self):
		cdTime = csv.mystery_shop_config[1].shop_cd_time
		return nowtime_t() - self.last_active_time < cdTime

#
# ObjectEquipShop
#

class ObjectEquipShop(ObjectUnionShop):
	Key = 'equip_shop'
	DBModel = 'EquipShop'
	FreeList = deque()

	@classmethod
	def csv(cls, csvID=None):
		if csv is None:
			return csv.equip_shop
		return csv.equip_shop[csvID]

	@classmethod
	def makeShopItems(cls, game):
		return ObjectEquipShopRandom.getRandomShop(game, game.role.vip_level, game.role.level)

	def buyItem(self, idx, shopID, itemID, count, **kwargs):
		cfg = self.csv(shopID)
		if cfg.type == 1:# 1-固定
			import framework
			if framework.__language__ not in cfg.languages:
				raise ClientError(ErrDefs.csvShopLanguageLimit)

			now = nowtime_t()
			nowInt = todaydate2int()
			if cfg.beginDate > nowInt or nowInt > cfg.endDate:
				raise ClientError(ErrDefs.csvShopNotInTime)

			if cfg.levelRange[0]>self.game.role.level or cfg.levelRange[1]<self.game.role.level:
				raise ClientError("level not enough")

			if cfg.limitType:
				if not self.game.role.canShopBuy(self.Key, shopID, count, cfg.limitType, cfg.limitTimes):
					raise ClientError(ErrDefs.buyShopTimesLimit)

			costAux = ObjectCostAux(self.game, cfg.costMap)
			costAux *= count
			if not costAux.isEnough():
				raise ClientError(ErrDefs.csvShopCoinNotEnough)
			costAux.cost(**kwargs)

			def afterGain():
				if cfg.limitType:
					self.game.role.addShopBuy(self.Key, shopID, count, cfg.limitType)
			eff = ObjectGainEffect(self.game, cfg.itemMap, afterGain)
			eff *= count
			return eff

		elif cfg.type == 2: # 2-随机
			return ObjectUnionShop.buyItem(self, idx, shopID, itemID, count, **kwargs)
		else:
			raise ClientError('type error')

	def isPast(self):
		'''
		判断商店是否过期
		'''
		from game.object.game.servrecord import ObjectServerGlobalRecord
		return ObjectServerGlobalRecord.isEquipShopPass(self.last_time)


#
# ObjectFishingShop
#
class ObjectFishingShop(ObjectUnionShop):
	Key = 'fishing_shop'
	DBModel = 'FishingShop'
	FreeList = deque()

	@classmethod
	def csv(cls, csvID=None):
		if csvID is None:
			return csv.fishing.shop
		return csv.fishing.shop[csvID]

	@classmethod
	def makeShopItems(cls, game):
		return ObjectFishingShopRandom.getRandomShop(game, game.role.vip_level, game.role.level)

	def isPast(self):
		'''
		判断商店是否过期
		'''
		lastdt = datetimefromtimestamp(self.last_time)
		return date2int(inclock5date(lastdt)) != todayinclock5date2int()

	def canBuy(self, idx, cfg, itemID, count):
		fishingLevel = self.game.fishing.level
		if fishingLevel < cfg.fishingLevelRange[0] or fishingLevel > cfg.fishingLevelRange[1]:
			raise ClientError('fishing level not satisfy')
		super(ObjectUnionShop, self).canBuy(idx, cfg, itemID, count)


#
# ObjectCardSkinShop
#
class ObjectCardSkinShop(ObjectPVPShop):
	Key = 'card_skin_shop'

	def __init__(self, game):
		ObjectBase.__init__(self, game)
		self._shopDB = game.role.card_skin_shop
		self.level = game.role.level

	@classmethod
	def csv(cls, csvID=None):
		if csvID is None:
			return csv.card_skin_shop
		return csv.card_skin_shop[csvID]

	def buyItem(self, csvID, count=1, **kwargs):
		cfg = self.csv(csvID)
		for itemID in cfg.itemMap:
			itemCfg = csv.items[itemID]
			skin_id = itemCfg.specialArgsMap.get('skinID', 0)
			if skin_id and self.game.role.skins.get(skin_id, None) == 0:
				raise ClientError('skin already have')

		self.canBuy(csvID, count)

		cfg = self.csv(csvID)
		costAux = ObjectCostAux(self.game, cfg.costMap)
		costAux *= count
		if not costAux.isEnough():
			raise ClientError(ErrDefs.csvShopCoinNotEnough)
		costAux.cost(**kwargs)

		def afterGain():
			if cfg.limitType:
				self.game.role.addShopBuy(self.Key, csvID, count, cfg.limitType)
			if cfg.exchangeLimit != -1:
				if csvID in self._shopDB:
					buyTimes, lastRecoverTime = self._shopDB[csvID]
					self._shopDB[csvID] = (buyTimes + count, lastRecoverTime)
				else:
					self._shopDB[csvID] = (count, nowtime_t())

		ret = addDict(cfg.itemMap, cfg.extraItem)
		eff = ObjectGainEffect(self.game, ret, afterGain)
		eff *= count
		return eff
