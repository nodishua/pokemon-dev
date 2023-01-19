#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2014 YouMi Information Technology Inc.
'''

from __future__ import absolute_import

from framework.log import logger
from framework.object import Copyable, ReloadHooker, GCObject
from game.object.game.badge import ObjectBadge
from game.object.game.cross_arena import ObjectCrossArenaGameGlobal
from game.object.game.cross_union_fight import ObjectCrossUnionFightGameGlobal
from game.object.game.daily_assistant import ObjectDailyAssistant
from game.object.game.endlesstower import ObjectEndlessTowerGlobal
from game.object.game.explorer import ObjectExplorer
from game.object.game.gem import ObjectGem, ObjectGemsMap, ObjectGemRebirth
from game.object.game.chip import ObjectChip, ObjectChipsMap
from game.object.game.gym import ObjectGymGameGlobal, ObjectGymTalentTree
from game.object.game.message import ObjectMessageGlobal
from game.object.game.randomTower import ObjectRandomTower
from game.object.game.reunionrecord import ObjectReunionRecord

from game.object.game.role import ObjectRole
from game.object.game.card import ObjectCard, ObjectCardsMap, ObjectCardRebirthFactory, ObjectCardRebirthBase
from game.object.game.held_item import ObjectHeldItem, ObjectHeldItemsMap
from game.object.game.item import ObjectItemsMap, ObjectItemEffectFactory
from game.object.game.frag import ObjectFragsMap
from game.object.game.drop import ObjectRandomDropFactory, ObjectStableDropFactory
from game.object.game.task import ObjectTaskFactory, ObjectTasksMap
from game.object.game.record import ObjectDailyRecord, ObjectMonthlyRecord, ObjectLotteryRecord
from game.object.game.rank import ObjectPWAwardRange, ObjectRandomTowerAwardRange, ObjectArenaFlopAwardRandom
from game.object.game.shop import ObjectUnionShop, ObjectFixShop, ObjectMysteryShopRandom, ObjectUnionShopRandom, ObjectFixShopRandom, ObjectMysteryShop, ObjectExplorerShopRandom, ObjectExplorerShop, ObjectFragShop,	ObjectFragShopRandom, ObjectRandomTowerShop, ObjectEquipShopRandom, ObjectEquipShop, ObjectFishingShop, ObjectFishingShopRandom
from game.object.game.title import ObjectTitleMap
from game.object.game.wmap import ObjectMap
from game.object.game.battle import ObjectGateBattle
from game.object.game.costcsv import ObjectCostCSV
from game.object.game.lottery import ObjectDrawCardRandom, ObjectDrawEquipRandom, ObjectDrawRandomItem, ObjectDrawNormalRandomItem, ObjectDrawItemRandom, ObjectDrawNValueRandom, ObjectDrawCaptureGroupRandom, ObjectDrawGemRandom, ObjectDrawChipRandom, ObjectDrawChipDynamicRandom
from game.object.game.huodong import ObjectHuoDongFactory
from game.object.game.yyhuodong import ObjectYYHuoDongFactory
from game.object.game.union import ObjectUnion, ObjectUnionContribTask, ObjectUnionCanSendRedPacket, ObjectUnionQA
from game.object.game.society import ObjectSociety
from game.object.game.levelcsv import ObjectFeatureUnlockCSV
from game.object.game.monstercsv import ObjectMonsterCSV
from game.object.game.equip import ObjectEquip
from game.object.game.talent import ObjectTalentTree
from game.object.game.achievement import ObjectAchieveMap
from game.object.game.craft import ObjectCraftInfoGlobal
from game.object.game.pokedex import ObjectPokedex
from game.object.game.union_fight import ObjectUnionFightGlobal
from game.object.game.cross_craft import ObjectCrossCraftGameGlobal
from game.object.game.cross_online_fight import ObjectCrossOnlineFightGameGlobal
from game.object.game.privilege import ObjectPrivilege
from game.object.game.trainer import ObjectTrainer
from game.object.game.feel import ObjectCardFeels
from game.object.game.zawake import ObjectZawake
from game.object.game.capture import ObjectCapture
from game.object.game.fishing import ObjectFishing
from game.object.game.cross_fishing import ObjectCrossFishingGameGlobal
from game.object.game.cross_mine import ObjectCrossMineGameGlobal

import copy
import weakref
import binascii
from tornado.concurrent import Future


def make_sync_dict(db, mem):
	# {}和None均表示未改动，False表示删除，True表示新增
	# 两个均为False，表示该对象被删除，现在没有只删其中一个的可能
	if db is False or mem is False:
		return False

	ret = {}
	if db:
		ret['_db'] = db
	if mem:
		ret['_mem'] = mem
	return ret if ret else None


class ObjectGameGuard(object):
	def __init__(self, game):
		if game is None:
			self.games = []
		elif isinstance(game, (list, tuple, set)):
			self.games = game
		else:
			self.games = [game]

	def __enter__(self):
		for game in self.games:
			try:
				game._safeGuard(True) # 防止game使用过程中被session清理
			except:
				logger.exception('game safe guard enter error')
		return self

	def __exit__(self, type, value, tb):
		for game in self.games:
			try:
				game._safeGuard(False)
			except:
				logger.exception('game safe guard exit error')
		return False


#
# ObjectGame
#

class ObjectGame(GCObject, Copyable, ReloadHooker):

	# 对象生命周期由Session控制
	# {Role.id: ObjectGame}
	ObjsMap = weakref.WeakValueDictionary()

	@classmethod
	def initAllClass(cls):
		ObjectMap.classInit()
		ObjectGateBattle.classInit()
		ObjectRole.classInit()
		ObjectCard.classInit()
		ObjectRandomDropFactory.classInit()
		ObjectStableDropFactory.classInit()
		ObjectItemEffectFactory.classInit()
		ObjectTaskFactory.classInit()
		ObjectTasksMap.classInit()
		ObjectPWAwardRange.classInit()
		ObjectRandomTowerAwardRange.classInit()
		ObjectArenaFlopAwardRandom.classInit()
		ObjectUnionShopRandom.classInit()
		ObjectExplorerShopRandom.classInit()
		ObjectFragShopRandom.classInit()
		ObjectFixShopRandom.classInit()
		ObjectMysteryShopRandom.classInit()
		ObjectEquipShopRandom.classInit()
		ObjectFixShop.classInit()
		ObjectFishingShopRandom.classInit()
		ObjectCostCSV.classInit()
		ObjectFeatureUnlockCSV.classInit()
		ObjectMonsterCSV.classInit()
		ObjectDrawRandomItem.classInit()
		ObjectDrawNormalRandomItem.classInit()
		ObjectDrawCardRandom.classInit()
		ObjectDrawEquipRandom.classInit()
		ObjectDrawNValueRandom.classInit()
		ObjectDrawCaptureGroupRandom.classInit()
		ObjectDrawChipDynamicRandom.classInit()
		ObjectDrawChipRandom.classInit()
		ObjectHuoDongFactory.classInit()
		ObjectTalentTree.classInit()
		ObjectYYHuoDongFactory.classInit()
		ObjectUnion.classInit()
		ObjectFragsMap.classInit()
		ObjectEquip.classInit()
		ObjectAchieveMap.classInit()
		ObjectCraftInfoGlobal.classInit()
		ObjectCrossCraftGameGlobal.classInit()
		ObjectCrossOnlineFightGameGlobal.classInit()
		ObjectUnionFightGlobal.classInit()
		ObjectCardRebirthBase.classInit()
		ObjectCardRebirthFactory.classInit()
		ObjectPokedex.classInit()
		ObjectTitleMap.classInit()
		ObjectEndlessTowerGlobal.classInit()
		ObjectUnionContribTask.classInit()
		ObjectUnionCanSendRedPacket.classInit()
		ObjectHeldItem.classInit()
		ObjectTrainer.classInit()
		ObjectCardFeels.classInit()
		ObjectZawake.classinit()
		ObjectExplorer.classInit()
		ObjectDrawItemRandom.classInit()
		ObjectRandomTower.classInit()
		ObjectCapture.classInit()
		ObjectMessageGlobal.classInit()
		ObjectGem.classInit()
		ObjectGemRebirth.classInit()
		ObjectDrawGemRandom.classInit()
		ObjectChip.classInit()
		ObjectCrossArenaGameGlobal.classInit()
		ObjectFishing.classInit()
		ObjectCrossFishingGameGlobal.classInit()
		ObjectGymGameGlobal.classInit()
		ObjectGymTalentTree.classInit()
		ObjectCrossMineGameGlobal.classInit()
		ObjectUnionQA.classInit()
		ObjectDailyAssistant.classInit()
		ObjectCrossUnionFightGameGlobal.classInit()

	@classmethod
	def getAll(cls):
		allobjs = ObjectGame.ObjsMap.values()
		return allobjs, ObjectGameGuard(allobjs)

	@classmethod
	def getByRoleID(cls, roleID, safe=True):
		game = cls.ObjsMap.get(roleID, None)
		if safe:
			return game, ObjectGameGuard(game)
		return game

	@classmethod
	def popByRoleID(cls, roleID):
		# 离线处理
		# 逻辑上需要强制清理各缓存
		# weakref不能完全保证，因为存在循环引用
		game = cls.ObjsMap.pop(roleID, None)
		if game:
			game._safeGuard = None

			for cardID in game.role.cards:
				ObjectCard.CardsObjsMap.pop(cardID, None)

			for heldItemID in game.role.held_items:
				ObjectHeldItem.HeldItemObjsMap.pop(heldItemID, None)

			for gemID in game.role.gems:
				ObjectGem.GemObjsMap.pop(gemID, None)

			for chipID in game.role.chips:
				ObjectChip.ChipObjsMap.pop(chipID, None)

			ObjectTasksMap.MapObjsMap.pop(game.role.id, None)

			ObjectFixShop.ShopsObjsMap.pop(game.role.fix_shop_db_id, None)
			ObjectUnionShop.ShopsObjsMap.pop(game.role.union_shop_db_id, None)
			ObjectExplorerShop.ShopsObjsMap.pop(game.role.explorer_shop_db_id, None)
			ObjectFragShop.ShopsObjsMap.pop(game.role.frag_shop_db_id, None)
			ObjectMysteryShop.ShopsObjsMap.pop(game.role.mystery_shop_db_id, None)
			ObjectRandomTowerShop.ShopsObjsMap.pop(game.role.random_tower_shop_db_id, None)
			ObjectEquipShop.ShopsObjsMap.pop(game.role.equip_shop_db_id, None)
			ObjectFishingShop.ShopsObjsMap.pop(game.role.fishing_shop_db_id, None)

			from game.object.game.cache import ObjectCacheGlobal
			ObjectCacheGlobal.popRole(roleID)
			for cardID in game.role.cards:
				ObjectCacheGlobal.popCard(cardID)

	def __init__(self, dbcGame, setSafeGuard):
		GCObject.__init__(self)
		self._dbcGame = dbcGame
		self._safeGuard = setSafeGuard

		self.role = ObjectRole(self, dbcGame)
		self.cards = ObjectCardsMap(self)
		self.items = ObjectItemsMap(self)
		self.frags = ObjectFragsMap(self)
		self.tasks = ObjectTasksMap(self)
		self.achievement = ObjectAchieveMap(self)
		self.talentTree = ObjectTalentTree(self)
		self.dailyRecord = ObjectDailyRecord(self, dbcGame)
		self.monthlyRecord = ObjectMonthlyRecord(self, dbcGame)
		self.lotteryRecord = ObjectLotteryRecord(self, dbcGame)
		self.fixShop = ObjectFixShop(self, dbcGame)
		self.mysteryShop = ObjectMysteryShop(self, dbcGame)
		self.society = ObjectSociety(self, dbcGame)
		self.pokedex = ObjectPokedex(self)
		self.privilege = ObjectPrivilege(self)
		self.union = None # Union引用
		self.unionModel = {} # ObjectUnion Model缓存
		self.unionShop = ObjectUnionShop(self, dbcGame)
		self.title = ObjectTitleMap(self)
		self.heldItems = ObjectHeldItemsMap(self)
		self.trainer = ObjectTrainer(self)
		self.feels = ObjectCardFeels(self)
		self.zawake = ObjectZawake(self)
		self.explorer = ObjectExplorer(self)
		self.explorerShop = ObjectExplorerShop(self, dbcGame)
		self.fragShop = ObjectFragShop(self, dbcGame)
		self.randomTowerShop = ObjectRandomTowerShop(self, dbcGame)
		self.randomTower = ObjectRandomTower(self, dbcGame)
		self.equipShop = ObjectEquipShop(self, dbcGame)
		self.capture = ObjectCapture(self, dbcGame)
		self.fishing = ObjectFishing(self, dbcGame)
		self.gems = ObjectGemsMap(self)
		self.chips = ObjectChipsMap(self)
		self.fishingShop = ObjectFishingShop(self, dbcGame)
		self.gymTalentTree = ObjectGymTalentTree(self)
		self.badge = ObjectBadge(self)
		self.reunionRecord = ObjectReunionRecord(self, dbcGame)
		self.dailyAssistant = ObjectDailyAssistant(self)

		# ObjectGateBattle
		# ObjectHuoDongBattle
		# ObjectYuanZhengBattle
		# ObjectUnionHDFubenBattle
		self.battle = None

		# 刷新卡牌卡牌 markID 最大战力
		self.refreshMarkMaxFight = False

		# random state map
		self.rndMap = {}

		# sdk info, only for QQ
		self.sdkInfo = {}

		self.disableModelWatch = False
		self.lastSyncCache = None
		self.syncVersion = 0

	def init(self):
		'''
		初始化独立Model存储的数据
		'''
		self.dailyRecord.init()
		self.monthlyRecord.init()
		self.lotteryRecord.init()
		self.fixShop.init()
		self.heldItems.init()
		self.role.init()
		self.randomTower.init()
		self.cards.init()
		self.society.init()
		self.reunionRecord.init()
		# in `self.role.init()`
			# self.game.items.init()
			# self.game.frags.init()
			# self.game.tasks.init()
			# self.game.talentTree.init()
			# self.pokedex.init()
			# self.privilege.init()
			# self.trainer.init()
			# self.feels.init()

		self.unionShop.init()
		self.explorerShop.init()
		self.mysteryShop.init()
		self.fragShop.init()
		self.randomTowerShop.init()
		self.equipShop.init()
		self.fishingShop.init()
		self.capture.init()
		self.fishing.init()
		self.gems.init()
		self.dailyAssistant.init()

		ObjectGame.ObjsMap[self.role.id] = self

	def new_deepcopy(self):
		del self._dbcGame

	def onModelWatch(self, dbModel, dbKey):
		if self.disableModelWatch:
			return
		self.tasks.onWatch(dbModel, dbKey)
		self.achievement.onWatch(dbModel, dbKey)
		self.title.onWatch(dbModel, dbKey)
		ObjectUnionCanSendRedPacket.onWatch(self, dbModel, dbKey)

	def startSync(self):
		# 跟modelSync一致
		self.role.startSync() # items, frags, tasks
		self.cards.startSync()
		self.tasks.startSync()
		self.dailyRecord.startSync()
		self.monthlyRecord.startSync()
		self.lotteryRecord.startSync()
		self.fixShop.startSync()
		self.unionShop.startSync()
		self.explorerShop.startSync()
		self.fragShop.startSync()
		self.randomTowerShop.startSync()
		self.mysteryShop.startSync()
		self.society.startSync()
		self.heldItems.startSync()
		self.randomTower.startSync()
		self.equipShop.startSync()
		self.fishingShop.startSync()
		self.capture.startSync()
		self.fishing.startSync()
		self.gems.startSync()
		self.chips.startSync()
		self.reunionRecord.startSync()

	def save_async(self, forget=False):
		fus = [
			self.role.save_async(forget), # items, frags, tasks
			self.cards.save_async(forget),
			self.dailyRecord.save_async(forget),
			self.monthlyRecord.save_async(forget),
			self.lotteryRecord.save_async(forget),
			self.fixShop.save_async(forget),
			self.unionShop.save_async(forget),
			self.explorerShop.save_async(forget),
			self.fragShop.save_async(forget),
			self.randomTowerShop.save_async(forget),
			self.mysteryShop.save_async(forget),
			self.society.save_async(forget),
			self.heldItems.save_async(forget),
			self.randomTower.save_async(forget),
			self.equipShop.save_async(forget),
			self.fishingShop.save_async(forget),
			self.capture.save_async(forget),
			self.fishing.save_async(forget),
			self.gems.save_async(forget),
			self.chips.save_async(forget),
			self.reunionRecord.save_async(forget)
		]
		future = Future()
		closure = [len(fus), 0]

		def allDone(fu):
			closure[1] += 1
			if closure[1] >= closure[0]:
				future.set_result(closure[0])
				logger.info('role %s game save%s, ObjectGame left %d', binascii.hexlify(self.role.id), ' and forget' if forget else '', len(ObjectGame.ObjsMap))
		map(lambda f: f.add_done_callback(allDone), fus)
		return future

	@property
	def model(self):
		if self.union:
			self.unionModel = copy.deepcopy(self.union.model)

		return {
			'role': self.role.model,
			'cards': {o.id: o.model for o in self.cards},
			'tasks': self.tasks.model,
			'daily_record': self.dailyRecord.model,
			'monthly_record': self.monthlyRecord.model,
			'lottery_record': self.lotteryRecord.model,
			'fix_shop': self.fixShop.model,
			'union': self.unionModel,
			'union_shop': self.unionShop.model,
			'explorer_shop': self.explorerShop.model,
			'frag_shop': self.fragShop.model,
			'random_tower_shop': self.randomTowerShop.model,
			'mystery_shop': self.mysteryShop.model,
			'society': self.society.model,
			'held_items': {o.id: o.model for o in self.heldItems},
			'random_tower': self.randomTower.model,
			'equip_shop': self.equipShop.model,
			'fishing_shop': self.fishingShop.model,
			'capture': self.capture.model,
			'fishing': self.fishing.model,
			'gems': {o.id: o.model for o in self.gems},
			'chips': {o.id: o.model for o in self.chips},
			'reunion_record': self.reunionRecord.model,
		}

	@property
	def modelSync(self):
		roleSync = self.role.modelSync
		cardsSync = self.cards.dirtyMapSync
		tasksSync = self.tasks.modelSync
		dailyRecordSync = self.dailyRecord.modelSync
		monthlyRecordSync = self.monthlyRecord.modelSync
		lotteryRecordSync = self.lotteryRecord.modelSync
		fixShopSync = self.fixShop.modelSync
		unionShopSync = self.unionShop.modelSync
		explorerShopSync = self.explorerShop.modelSync
		fragShopSync = self.fragShop.modelSync
		randomTowerShopSync = self.randomTowerShop.modelSync
		mysteryShopSync = self.mysteryShop.modelSync
		societySync = self.society.modelSync
		heldItemsSync = self.heldItems.dirtyMapSync
		randomTowerSync = self.randomTower.modelSync
		equipShopSync = self.equipShop.modelSync
		fishingShopSync = self.fishingShop.modelSync
		captureSync = self.capture.modelSync
		fishingSync = self.fishing.modelSync
		gemsSync = self.gems.dirtyMapSync
		chipsSync = self.chips.dirtyMapSync
		reunionRecordSync = self.reunionRecord.modelSync

		# 缩减未更新的数据字段
		def slimSync(sync, kvs, dbIdx, memIdx):
			for key, val in kvs:
				if isinstance(val, dict):
					# cards, equips
					dd = {}
					for k, v in val.iteritems():
						d = make_sync_dict(v[dbIdx], v[memIdx])
						if d is not None:
							dd[k] = d
					if dd:
						sync.setdefault(key, {}).update(dd)
				else:
					d = make_sync_dict(val[dbIdx], val[memIdx])
					if d is not None:
						sync.setdefault(key, {}).update(d)
			return sync

		# 自动检测的ObjectDBase的modelSync
		kvs = (
			('role', roleSync),
			('cards', cardsSync),
			('tasks', tasksSync),
			('daily_record', dailyRecordSync),
			('monthly_record', monthlyRecordSync),
			('lottery_record', lotteryRecordSync),
			('fix_shop', fixShopSync),
			('union_shop', unionShopSync),
			('explorer_shop', explorerShopSync),
			('frag_shop', fragShopSync),
			('random_tower_shop', randomTowerShopSync),
			('mystery_shop', mysteryShopSync),
			('society', societySync),
			('held_items', heldItemsSync),
			('random_tower', randomTowerSync),
			('equip_shop', equipShopSync),
			('fishing_shop', fishingShopSync),
			('capture', captureSync),
			('fishing', fishingSync),
			('gems', gemsSync),
			('chips', chipsSync),
			('reunion_record', reunionRecordSync)
		)
		syncNew = slimSync({}, kvs, 0, 3)
		syncUpd = slimSync({}, kvs, 1, 4)
		syncDel = slimSync({}, kvs, 2, 5)

		# 手动处理的ObjectDBaseMap的modelSync
		kvs = (
			('cards', self.cards.modelSync),
			('held_items', self.heldItems.modelSync),
			('gems', self.gems.modelSync),
			('chips', self.chips.modelSync),
		)
		syncNew = slimSync(syncNew, kvs, 0, 3)
		syncUpd = slimSync(syncUpd, kvs, 1, 4)
		syncDel = slimSync(syncDel, kvs, 2, 5)

		# 手动处理ObjectUnion
		if self.union:
			modelSync = self.union.modelSyncFromCache(self.unionModel)
			self.unionModel = modelSync[-1]
			kvs = (('union', modelSync[:-1]),)
			syncNew = slimSync(syncNew, kvs, 0, 3)
			syncUpd = slimSync(syncUpd, kvs, 1, 4)
			syncDel = slimSync(syncDel, kvs, 2, 5)

		# New: new+upd
		# Replace: new+upd
		# Update: upd
		# Delete: del
		sync = {}
		if syncNew:
			sync['new'] = syncNew
		if syncUpd:
			sync['upd'] = syncUpd
		if syncDel:
			sync['del'] = syncDel

		if sync:
			self.syncVersion += 1
			sync['version'] = self.syncVersion
			self.lastSyncCache = sync
		return sync
