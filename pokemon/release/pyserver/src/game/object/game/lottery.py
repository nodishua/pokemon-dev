#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2014 YouMi Information Technology Inc.
'''

from __future__ import absolute_import

from framework import is_none
from framework.csv import csv
from framework.object import ReloadHooker
from framework.helper import getRandomSeed, WeightRandomObject, objectid2string
from game import ServerError
from game.object import DrawDefs, DrawCardDefs, DrawEquipDefs, DrawBoxDefs, ItemDefs
from game.object.game.gain import ObjectGainAux
from game.object.game.item import RandomGiftItemEffect
import heapq
import random
from collections import namedtuple, defaultdict


#
# ObjectDrawRandomItem
#

class ObjectDrawRandomItem(ReloadHooker):
	'''
	通用随机抽奖库
	'''

	CardType = -1
	SpecailType = -2

	Lib = {}

	@classmethod
	def classInit(cls):
		cls.Lib = {}
		for idx in csv.draw_items_lib:
			cfg = csv.draw_items_lib[idx]
			cls.Lib[idx] = cls(cfg, rndKey='draw_items_lib')

	@classmethod
	def getObject(cls, idx):
		return cls.Lib.get(idx, None)

	@classmethod
	def isCard(cls, itemT):
		return itemT[1] == cls.CardType

	@classmethod
	def isSpecial(cls, itemT):
		return itemT[1] == cls.SpecailType

	@classmethod
	def packToDict(cls, itemTs, ret=None):
		ret = {} if ret is None else ret
		itemTs = itemTs if isinstance(itemTs, list) else [itemTs]
		for csvID, itemCount in itemTs:
			if csvID is None:
				continue
			if cls.isCard((csvID, itemCount)):
				if 'cards' in ret:
					ret['cards'].append(csvID)
				elif 'card' in ret:
					ret['cards'] = [ret.pop('card'), csvID]
				else:
					ret['card'] = csvID
			else:
				ret[csvID] = ret.get(csvID, 0) + itemCount
		return ret

	def __init__(self, cfg, weightList=[], cardWeightMap={}, specialWeightMap={}, rndKey='none'):
		self._key = '%s_%d' % (rndKey, cfg.id) if cfg else rndKey
		self._sum = 0
		self._lst = []
		self._cardLst = []
		self._specialLst = []
		self._only = None
		weightList = cfg.weightList if cfg else weightList
		cardWeightMap = cfg.cardWeightMap if cfg else cardWeightMap
		specialWeightMap = cfg.specialWeightMap if cfg else specialWeightMap
		# 只支持列表 <<csvID, weight, count>;...>
		for item in weightList:
			csvID, weight, count = item
			if weight <= 0:
				continue
			self._sum += weight
			self._lst.append((csvID, count, weight))
		# 只支持列表 <<card, weight>;...>
		for card, weight in cardWeightMap:
			if weight <= 0:
				continue
			self._sum += weight
			self._cardLst.append((card, weight))
		# 只支持字典 {csvID:weight}
		for csvID in specialWeightMap:
			weight = specialWeightMap[csvID]
			if weight <= 0:
				continue
			self._sum += weight
			self._specialLst.append((csvID, weight))
		# 只配置单个的，直接给不随机
		if len(self._lst) + len(self._cardLst) + len(self._specialLst) == 1:
			if self._lst:
				csvID, count, weight = self._lst[0]
				self._only = (csvID, count)
			elif self._cardLst:
				card, weight = self._cardLst[0]
				self._only = (card, self.CardType) # count = -1特殊表示卡牌
			elif self._specialLst:
				csvID, weight = self._specialLst[0]
				self._only = (csvID, self.SpecailType) # count = -2特殊

	def _getRandomGenerator(self, game):
		obj = game.rndMap.setdefault(self._key, random.Random(getRandomSeed() ^ game.role.uid))
		return obj

	def getRandomItem(self, game=None, selected=None, unselected=None):
		if self._sum <= 0:
			return (None, 0)

		if self._only:
			return self._only

		rndObj = self._getRandomGenerator(game) if game else random
		ret = self._rand(rndObj, selected, unselected)
		if ret is None or is_none(ret[0]):
			return (None, 0)
		return ret

	def _rand(self, rndObj, selected=None, unselected=None):
		_lst = self._lst
		_sum = self._sum
		if selected and self._lst: # 只增对道具处理, _cardLst和_specialLst不处理
			_lst = [(x[0], x[1], int(x[2] * selected.get(x[0], unselected))) for x in self._lst]
			_sum = sum(x[-1] for x in _lst)
		rnd = rndObj.randint(1, _sum)
		for csvID, count, weight in _lst:
			rnd -= weight
			if rnd <= 0:
				return (csvID, count)
		for card, weight in self._cardLst:
			rnd -= weight
			if rnd <= 0:
				return (card, self.CardType) # count = -1特殊表示卡牌
		for csvID, weight in self._specialLst:
			rnd -= weight
			if rnd <= 0:
				return (csvID, self.SpecailType) # count = -2特殊
		return None

#
#
#

NormalRandomState = namedtuple('NormalRandomState', ('obj', 'state'))
NormalRandomWeight = namedtuple('NormalRandomWeight', ('mu', 'sigma', 'ret'))


#
# ObjectDrawNormalRandomItem
#

class ObjectDrawNormalRandomItem(ObjectDrawRandomItem):
	'''
	正态分布随机抽奖库
	依赖玩家随机状态
	'''

	Lib = {}

	@classmethod
	def classInit(cls):
		cls.Lib = {}
		for idx in csv.draw_items_lib:
			cfg = csv.draw_items_lib[idx]
			cls.Lib[idx] = cls(cfg, rndKey='draw_items_lib_normal')

	def __init__(self, cfg, weightList=[], cardWeightMap={}, specialWeightMap={}, rndKey='none'):
		ObjectDrawRandomItem.__init__(self, cfg, weightList, cardWeightMap, specialWeightMap, rndKey)

		self._lstAll = []
		for csvID, count, weight in self._lst:
			self._lstAll.append(NormalRandomWeight(1.*self._sum/weight, 1.*self._sum/weight/3., (csvID, count)))
		for card, weight in self._cardLst:
			self._lstAll.append(NormalRandomWeight(1.*self._sum/weight, 1.*self._sum/weight/3., (card, self.CardType))) # count = -1特殊表示卡牌
		for csvID, weight in self._specialLst:
			self._lstAll.append(NormalRandomWeight(1.*self._sum/weight, 1.*self._sum/weight/3., (csvID, self.SpecailType))) # count = -2特殊

	# 每个玩家保存各自状态，保持概率独立
	def _getRandomGenerator(self, game):
		obj = game.rndMap.get(self._key, None)
		if obj is None:
			rnd = random.Random(getRandomSeed() ^ game.role.uid)
			st = [(rnd.gauss(x.mu, x.sigma), i) for i, x in enumerate(self._lstAll)]
			heapq.heapify(st)
			obj = NormalRandomState(rnd, st)
			game.rndMap[self._key] = obj
		return obj

	def _rand(self, rndObj, selected=None, unselected=None):
		minp, minj = heapq.heappop(rndObj.state)
		choose = self._lstAll[minj]
		heapq.heappush(rndObj.state, (rndObj.obj.gauss(choose.mu, choose.sigma) + minp, minj))
		return choose.ret


#
# ObjectDrawCardRandom
#

class ObjectDrawCardRandom(ReloadHooker):
	'''
	抽卡随机
	先判定抽卡类型，再按优先级判定是否开启
	再随机抽取随机库，最后在随机库中随机出物品
	'''

	CsvFile = 'draw_card'
	TriggerMap = {} # {drawType: [drawTriggerType: [ObjectDrawCardRandom, ...], ...], ...}

	@classmethod
	def classInit(cls):
		path = cls.CsvFile.split('.')
		if len(path) > 1:
			csvFile = csv
			for part in path:
				csvFile = csvFile[part]
		else:
			csvFile = csv[cls.CsvFile]

		cls.TriggerMap = defaultdict(lambda: [[] for i in xrange(DrawDefs.TriggerTotal)])
		for idx in csvFile:
			cfg = csvFile[idx]
			obj = cls(cfg)
			cls.TriggerMap[cfg.drawType][cfg.drawTriggerType].append(obj)

		# 类型相同的按drawTriggerTimes从大到小顺序
		for draws in cls.TriggerMap.itervalues():
			for triggers in draws:
				triggers.sort(key=lambda x: x.cfg.drawTriggerTimes, reverse=True)

	@classmethod
	def getRandomItems(cls, game, drawType, drawTimes, afterGain):
		_type = 'rmb1' if drawType == 'free1' else drawType
		_type = 'gold1' if _type == 'free_gold1' else _type
		_type = 'limit_box_rmb1' if _type == 'limit_box_free1' else _type
		if _type not in cls.TriggerMap:
			return None
		triggers = cls.TriggerMap[_type]

		# 先加权重
		for i in xrange(4, -1, -1):
			for obj in triggers[i]:
				if obj.cfg.drawTriggerType == DrawDefs.TriggerWeight:
					if not obj.isCountLimit(game, drawTimes):
						obj.addWeight(game)

		# 按优先级来扫描触发
		for i in xrange(4, -1, -1):
			for obj in triggers[i]:
				if obj.isCountLimit(game, drawTimes):
					continue
				if obj.isActive(game, drawTimes):
					obj.activeProcess(game)
					libs = obj.getRandomLib(game)
					ret = {}
					cards = []
					grids = [] # 给客户端显示格子用
					# libs: csv.draw_card.lotteryType
					for idx, count in libs.iteritems():
						itemObj = ObjectDrawRandomItem.getObject(idx)
						if itemObj is not None:
							for j in xrange(count):
								csvID, itemCount = itemObj.getRandomItem(game)
								if csvID is None:
									continue
								# 处理可以直接打开的随机礼包
								if isinstance(csvID,int) and ItemDefs.isItemID(csvID) and csvID in csv.items and csv.items[csvID].type == ItemDefs.imOpenRandGiftType:
									if itemCount != 1:
										raise ServerError('itemCount must be 1')
									libID = RandomGiftItemEffect.getLibID(game, csvID)
									newitemObj = ObjectDrawRandomItem.getObject(libID)
									# 直接打开的随机礼包 数量就当一个处理
									if newitemObj:
										csvID, itemCount = newitemObj.getRandomItem(game)
										if csvID is None:
											continue
								if ObjectDrawNormalRandomItem.isCard((csvID, itemCount)):
									cards.append(csvID)
									continue
								ret[csvID] = ret.get(csvID, 0) + itemCount
								grids.append((csvID, itemCount))
					if cards:
						ret['cards'] = cards
					if ret:
						return ObjectDrawEffect(game, ret, grids, afterGain)
					return None
		return None

	def __init__(self, cfg):
		self._csvID = cfg.id
		self.cfg = cfg
		self._sum = 0
		self._lst = []
		self._only = None
		self._rnd = None
		wmap = {}
		for i in xrange(1, 99):
			typeField = 'lotteryType%d' % i
			weightField = 'lotteryWeight%d' % i
			if typeField not in cfg:
				break
			libs = cfg[typeField]
			weight = cfg[weightField]
			# 没有配置产出和权值的忽略
			if libs and weight > 0:
				self._sum += weight
				wmap[len(self._lst)] = weight
				self._lst.append((libs, weight))
		# 只配置单个的，直接给不随机
		if len(self._lst) == 0:
			self._only = {}
		elif len(self._lst) == 1:
			self._only = self._lst[0][0]
		else:
			self._rnd = ObjectDrawNormalRandomItem(None, specialWeightMap=wmap, rndKey='%s_%d' % (self.CsvFile, cfg.id))

	def isCountLimit(self, game, times):
		if times < self.cfg.startCount:
			return True
		if self.cfg.effectLimit > 0:
			record = game.lotteryRecord
			if self.CsvFile not in record.effect_info:
				record.effect_info[self.CsvFile] = {}
			effectCount = record.effect_info[self.CsvFile].get(self._csvID,0)
			if effectCount >= self.cfg.effectLimit:
				return True
		return False

	def addWeight(self, game):
		if self.cfg.drawTriggerType == DrawDefs.TriggerWeight:
			record = game.lotteryRecord
			weight = random.uniform(self.cfg.weightStart, self.cfg.weightEnd)
			if self.CsvFile not in record.weight_info:
				record.weight_info[self.CsvFile] = {}
			record.weight_info[self.CsvFile][self._csvID] = record.weight_info[self.CsvFile].get(self._csvID,0)+weight

	def activeProcess(self, game):
		if self.cfg.drawTriggerType == DrawDefs.TriggerWeight:
			game.lotteryRecord.weight_info[self.CsvFile][self._csvID] -= 1
		if self.cfg.effectLimit > 0 or self.cfg.drawTriggerType == DrawDefs.TriggerProb: #只针对有次数限制的, 或概率触发的
			record = game.lotteryRecord
			if self.CsvFile not in record.effect_info:
				record.effect_info[self.CsvFile] = {}
			record.effect_info[self.CsvFile][self._csvID] = record.effect_info[self.CsvFile].get(self._csvID,0)+1

	def isActive(self, game, times):
		record = game.lotteryRecord
		count = times - self.cfg.startCount
		if self.cfg.drawTriggerType == DrawDefs.TriggerStart:
			return count >= self.cfg.drawTriggerTimes
		elif self.cfg.drawTriggerType == DrawDefs.TriggerWeight:
			if self.CsvFile not in record.weight_info:
				record.weight_info[self.CsvFile] = {}
			return record.weight_info[self.CsvFile].get(self._csvID,0) >= 1
		elif self.cfg.drawTriggerType == DrawDefs.TriggerProb:
			if self.CsvFile not in record.effect_info:
				record.effect_info[self.CsvFile] = {}
			# from framework.log import logger
			# 1. 判断生效间隔内是否已经生效
			process = record.effect_info[self.CsvFile].get(self._csvID, 0)
			if process >= (count-1) / self.cfg.probEffectInterval + 1:
				# logger.info('count %d, csv_id %d, process %d False', count, self._csvID, process)
				return False
			# 2. 保底次数激活
			if (count-1) % self.cfg.probEffectInterval + 1 >= self.cfg.probMiniTimes:
				# logger.info('count %d, csv_id %d, process %d True', count, self._csvID, process)
				return True
			# 2. 概率激活
			prob = self.cfg.probInit + self.cfg.probStep * ((count-1) % self.cfg.probEffectInterval)
			prob = min(prob, self.cfg.probLimit)
			rnd = random.random()
			# logger.info('count %d, csv_id %d, process %d', count, self._csvID, process)
			# logger.info('prob %f, random %f, %s', prob, rnd, rnd <= prob)
			return rnd <= prob
		elif self.cfg.drawTriggerType == DrawDefs.TriggerEvery:
			return count >= self.cfg.drawTriggerTimes and count % self.cfg.drawTriggerTimes == 0
		elif self.cfg.drawTriggerType == DrawDefs.TriggerOnce:
			return count == self.cfg.drawTriggerTimes
		return False

	def getRandomLib(self, game):
		if self._only:
			return self._only

		lotteryType, _ = self._rnd.getRandomItem(game)
		return self._lst[lotteryType][0]


#
# ObjectDrawEquipRandom
#

class ObjectDrawEquipRandom(ObjectDrawCardRandom):
	'''
	抽装备随机
	'''

	CsvFile = 'draw_equip'
	TriggerMap = {} # {drawType: [drawTriggerType: [ObjectDrawEquipRandom, ...], ...], ...}


#
# ObjectDrawItemRandom
#

class ObjectDrawItemRandom(ObjectDrawCardRandom):
	'''
	抽道具随机
	'''

	CsvFile = 'draw_item'
	TriggerMap = {} # {drawType: [drawTriggerType: [ObjectDrawItemRandom, ...], ...], ...}


#
# ObjectDrawGemRandom
#

class ObjectDrawGemRandom(ObjectDrawCardRandom):
	'''
	抽宝石随机
	'''

	CsvFile = 'draw_gem'
	TriggerMap = {} # {drawType: [drawTriggerType: [ObjectDrawGemRandom, ...], ...], ...}


#
# ObjectDrawEffect
#

class ObjectDrawEffect(ObjectGainAux):
	'''
	抽卡，抽装备，抽道具
	'''

	def __init__(self, game, argsD, grids, afterGain):
		self._grids = grids
		self._afterGain = afterGain

		ObjectGainAux.__init__(self, game, argsD)

	def card2frag(self, card):
		fragNum = ObjectGainAux.card2frag(self, card)

		cfg = csv.cards[card['id']]
		self._grids += [(cfg.fragID, fragNum, card['id'])]
		return True

	def gem2item(self):
		from copy import deepcopy
		# 分解
		decomposeD = {}
		gemIDs = deepcopy(self._gemsL)
		for gemID in gemIDs:
			gemCfg = csv.gem.gem[gemID]
			if gemCfg.quality <= 3:
				self._gemsL.remove(gemID)
				# 只取第一个
				for csvID, num in gemCfg.decomposeReturn.iteritems():
					self._itemsD[csvID] = self._itemsD.get(csvID, 0) + num
					decomposeD[gemID] = (csvID, num)
					break
		# 客户端格子展示
		grids = deepcopy(self._grids)
		for i, grid in enumerate(grids):
			gemID = grid[0]
			if gemID in decomposeD.keys():
				csvID, num = decomposeD[gemID]
				self._grids[i] = (csvID, num, gemID)

	@property
	def result(self):
		ret = {
			'items': self._grids,
		}
		if self._newCardsL:
			ret['carddbIDs'] = self._newCardsL
		if self._cardFragL:
			ret['card2fragL'] = self._cardFragL
		if self._stashCardsL:
			ret['card2mailL'] = self._stashCardsL
		if self._newHeldItemsL:
			ret['heldItemdbIDs'] = self._newHeldItemsL
		if self._newGemsL:
			ret['gemdbIDs'] = self._newGemsL
		if self._newChipsL:
			ret['chipdbIDs'] = self._newChipsL
		return ret

	@property
	def prettylog(self):
		ret = {
			'items': self._grids,
		}
		if self._cardsL:
			ret['cards'] = self._cardsL

		if self._newCardsL:
			ret['carddbIDs'] = [(objectid2string(x[0]), x[1]) for x in self._newCardsL]
		if self._cardFragL:
			ret['card2fragL'] = self._cardFragL
		if self._stashCardsL:
			ret['card2mailL'] = self._stashCardsL
		if self._newHeldItemsL:
			ret['heldItemdbIDs'] = [objectid2string(x) for x in self._newHeldItemsL]
		if self._newGemsL:
			ret['gemdbIDs'] = [objectid2string(x) for x in self._newGemsL]
		if self._newChipsL:
			ret['chipdbIDs'] = [objectid2string(x) for x in self._newChipsL]
		return ret

	def gain(self, **kwargs):
		ObjectGainAux.gain(self, **kwargs)
		self._afterGain()

#
# ObjectDrawNValueRandom
#

class ObjectDrawNValueRandom(ObjectDrawCardRandom):
	'''
	个体值库随机, 随机出个体值库
	'''

	CsvFile = 'nvalue_random'
	TriggerMap = {}

	@classmethod
	def randomLib(cls, game, drawTimes):
		_type = 'default'
		if _type not in cls.TriggerMap:
			return None
		triggers = cls.TriggerMap[_type]

		# 先加权重
		for i in xrange(4, -1, -1):
			for obj in triggers[i]:
				if obj.cfg.drawTriggerType == DrawDefs.TriggerWeight:
					if not obj.isCountLimit(game, drawTimes):
						obj.addWeight(game)

		# 按优先级来扫描触发
		for i in xrange(4, -1, -1):
			for obj in triggers[i]:
				if obj.isCountLimit(game, drawTimes):
					continue
				if obj.isActive(game, drawTimes):
					obj.activeProcess(game)
					return obj.getRandomLib(game)

		return None

	def __init__(self, cfg):
		self._csvID = cfg.id
		self.cfg = cfg
		self._only = None
		self._rnd = None
		if len(cfg.libs) == 1:
			self._only = cfg.libs.keys()[0]
		else:
			self._rnd = WeightRandomObject(cfg.libs)

	def getRandomLib(self, game):
		if self._only:
			return self._only
		lib, _ = self._rnd.getRandom()
		return lib


#
# ObjectDrawCaptureGroupRandom
#

class ObjectDrawCaptureGroupRandom(ObjectDrawNValueRandom):
	"""
	抽捕捉精灵组
	"""

	CsvFile = 'capture.random'
	TriggerMap = {} # {drawType: [drawTriggerType: [ObjectDrawCaptureGroupRandom, ...], ...], ...}


class ObjectDrawChipDynamicRandom(ReloadHooker):
	'''
	抽芯片掉落库权值修正随机
	'''

	CsvFile = 'draw_chip_dynamic'
	TriggerMap = {} # {libID: [drawTriggerType: [ObjectDrawCardRandom, ...], ...], ...}

	@classmethod
	def classInit(cls):
		path = cls.CsvFile.split('.')
		if len(path) > 1:
			csvFile = csv
			for part in path:
				csvFile = csvFile[part]
		else:
			csvFile = csv[cls.CsvFile]

		cls.TriggerMap = defaultdict(lambda: [[] for i in xrange(DrawDefs.TriggerTotal)])
		for idx in csvFile:
			cfg = csvFile[idx]
			obj = cls(cfg)
			cls.TriggerMap[cfg.libID][cfg.drawTriggerType].append(obj)

		# 类型相同的按drawTriggerTimes从大到小顺序
		for draws in cls.TriggerMap.itervalues():
			for triggers in draws:
				triggers.sort(key=lambda x: x.cfg.drawTriggerTimes, reverse=True)

	@classmethod
	def getRandomWeight(cls, game, libID):
		drawTimes = game.lotteryRecord.draw_chip_lib_counter.get(libID, 0) # 已触发的次数
		drawTimes += 1
		game.lotteryRecord.draw_chip_lib_counter[libID] = drawTimes

		if libID not in cls.TriggerMap:
			return None
		triggers = cls.TriggerMap[libID]

		# 先加权重
		for i in xrange(4, -1, -1):
			for obj in triggers[i]:
				if obj.cfg.drawTriggerType == DrawDefs.TriggerWeight:
					if not obj.isCountLimit(game, drawTimes):
						obj.addWeight(game)

		# 按优先级来扫描触发
		for i in xrange(4, -1, -1):
			for obj in triggers[i]:
				if obj.isCountLimit(game, drawTimes):
					continue
				if obj.isActive(game, drawTimes):
					obj.activeProcess(game)
					return (obj.cfg.selected, obj.cfg.unselected)
		return None

	def __init__(self, cfg):
		self._csvID = cfg.id
		self.cfg = cfg

	def isCountLimit(self, game, times):
		if times < self.cfg.startCount:
			return True
		if self.cfg.effectLimit > 0:
			record = game.lotteryRecord
			if self.CsvFile not in record.lib_effect_info:
				record.lib_effect_info[self.CsvFile] = {}
			effectCount = record.lib_effect_info[self.CsvFile].get(self._csvID,0)
			if effectCount >= self.cfg.effectLimit:
				return True
		return False

	def addWeight(self, game):
		if self.cfg.drawTriggerType == DrawDefs.TriggerWeight:
			record = game.lotteryRecord
			weight = random.uniform(self.cfg.weightStart, self.cfg.weightEnd)
			if self.CsvFile not in record.lib_weight_info:
				record.lib_weight_info[self.CsvFile] = {}
			record.lib_weight_info[self.CsvFile][self._csvID] = record.lib_weight_info[self.CsvFile].get(self._csvID,0)+weight

	def activeProcess(self, game):
		if self.cfg.drawTriggerType == DrawDefs.TriggerWeight:
			game.lotteryRecord.lib_weight_info[self.CsvFile][self._csvID] -= 1
		# 需要用于计算lib次数，与抽取不同
		record = game.lotteryRecord
		if self.CsvFile not in record.lib_effect_info:
			record.lib_effect_info[self.CsvFile] = {}
		record.lib_effect_info[self.CsvFile][self._csvID] = record.lib_effect_info[self.CsvFile].get(self._csvID,0)+1

	def isActive(self, game, times):
		record = game.lotteryRecord
		count = times - self.cfg.startCount
		if self.cfg.drawTriggerType == DrawDefs.TriggerStart:
			return count >= self.cfg.drawTriggerTimes
		elif self.cfg.drawTriggerType == DrawDefs.TriggerWeight:
			if self.CsvFile not in record.lib_weight_info:
				record.lib_weight_info[self.CsvFile] = {}
			return record.lib_weight_info[self.CsvFile].get(self._csvID,0) >= 1
		elif self.cfg.drawTriggerType == DrawDefs.TriggerProb:
			if self.CsvFile not in record.lib_effect_info:
				record.lib_effect_info[self.CsvFile] = {}
			# from framework.log import logger
			# 1. 判断生效间隔内是否已经生效
			process = record.lib_effect_info[self.CsvFile].get(self._csvID, 0)
			if process >= (count-1) / self.cfg.probEffectInterval + 1:
				# logger.info('count %d, csv_id %d, process %d False', count, self._csvID, process)
				return False
			# 2. 保底次数激活
			if (count-1) % self.cfg.probEffectInterval + 1 >= self.cfg.probMiniTimes:
				# logger.info('count %d, csv_id %d, process %d True', count, self._csvID, process)
				return True
			# 2. 概率激活
			prob = self.cfg.probInit + self.cfg.probStep * ((count-1) % self.cfg.probEffectInterval)
			prob = min(prob, self.cfg.probLimit)
			rnd = random.random()
			# logger.info('count %d, csv_id %d, process %d', count, self._csvID, process)
			# logger.info('prob %f, random %f, %s', prob, rnd, rnd <= prob)
			return rnd <= prob
		elif self.cfg.drawTriggerType == DrawDefs.TriggerEvery:
			return count >= self.cfg.drawTriggerTimes and count % self.cfg.drawTriggerTimes == 0
		elif self.cfg.drawTriggerType == DrawDefs.TriggerOnce:
			return count == self.cfg.drawTriggerTimes
		return False

#
# ObjectDrawChipRandom
#

class ObjectDrawChipRandom(ObjectDrawCardRandom):
	'''
	抽芯片随机
	'''

	CsvFile = 'draw_chip'
	TriggerMap = {} # {drawType: [drawTriggerType: [ObjectDrawChipRandom, ...], ...], ...}

	@classmethod
	def getRandomItems(cls, game, drawType, drawTimes, afterGain, chooses=None):
		_type = 'rmb1' if drawType == 'free1' else drawType
		_type = 'item1' if _type == 'free_item1' else _type
		if _type not in cls.TriggerMap:
			return None
		triggers = cls.TriggerMap[_type]

		# 先加权重
		for i in xrange(4, -1, -1):
			for obj in triggers[i]:
				if obj.cfg.drawTriggerType == DrawDefs.TriggerWeight:
					if not obj.isCountLimit(game, drawTimes):
						obj.addWeight(game)

		# 按优先级来扫描触发
		for i in xrange(4, -1, -1):
			for obj in triggers[i]:
				if obj.isCountLimit(game, drawTimes):
					continue
				if obj.isActive(game, drawTimes):
					obj.activeProcess(game)
					libs = obj.getRandomLib(game)
					ret = {}
					cards = []
					grids = [] # 给客户端显示格子用
					for idx, count in libs.iteritems():
						itemObj = ObjectDrawRandomItem.getObject(idx)
						if itemObj is not None:
							for j in xrange(count):
								selected, unselected = None, None
								if chooses:
									v = ObjectDrawChipDynamicRandom.getRandomWeight(game, idx)
									if v: # 增对选择的概率修改值
										selected, unselected = v
										selected = {i:selected for i in chooses}
								csvID, itemCount = itemObj.getRandomItem(game, selected, unselected)
								if csvID is None:
									continue
								if ObjectDrawNormalRandomItem.isCard((csvID, itemCount)):
									cards.append(csvID)
									continue
								ret[csvID] = ret.get(csvID, 0) + itemCount
								grids.append((csvID, itemCount))
					if cards:
						ret['cards'] = cards
					if ret:
						return ObjectDrawEffect(game, ret, grids, afterGain)
					return None
		return None
