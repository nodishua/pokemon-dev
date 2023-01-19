#!/usr/bin/python
# coding=utf-8
import weakref
import copy

from framework import str2num_t
from framework.csv import ConstDefs, csv
from framework.helper import objectid2string
from framework.log import logger
from framework.object import ObjectDBase, db_property, ObjectDBaseMap, ObjectBase
from game import ServerError, ClientError
from game.object import GemDefs, ItemDefs, CardResetDefs
from game.object.game.calculator import zeros
from game.object.game.card import ObjectCardRebirthBase
from game.object.game.gain import ObjectCostAux, ObjectGainAux


#
# ObjectGem
#
class ObjectGem(ObjectDBase):
	DBModel = 'RoleGem'

	GemObjsMap = weakref.WeakValueDictionary()
	CardGemPosMap = {}
	GemSuitMap = {}  # {(suitID, suitNum, suitQuality): cfg}
	GemSuitNumMap = {}  # {(suitID, suitQuality): [suitNum]}
	GemQualityAttrsMap = {}  # {gemQualitySeqID: [csvID]}
	GemSuitQualityMap = {}  # {suitID: [Quality]}

	@classmethod
	def classInit(cls):
		#  刷新csv配置
		for obj in cls.GemObjsMap.itervalues():
			obj.init()

		# 宝石槽
		cls.CardGemPosMap = {}
		for i in sorted(csv.gem.pos):
			cfg = csv.gem.pos[i]
			cls.CardGemPosMap.setdefault((cfg.gemPosSeqID, cfg.gemPosNo), cfg.openCondition)

		# 宝石
		cls.GemSuitQualityMap = {}
		for i in sorted(csv.gem.gem):
			cfg = csv.gem.gem[i]
			qualitys = cls.GemSuitQualityMap.setdefault(cfg.suitID, set())
			qualitys.add(cfg.quality)

		# 宝石套装
		cls.GemSuitMap = {}
		cls.GemSuitNumMap = {}
		for i in sorted(csv.gem.suit):
			cfg = csv.gem.suit[i]
			cls.GemSuitMap.setdefault((cfg.suitID, cfg.suitNum, cfg.suitQuality), cfg)
			suitNums = cls.GemSuitNumMap.setdefault((cfg.suitID, cfg.suitQuality), [])
			suitNums.append(cfg.suitNum)

		# 宝石品质指数加成
		cls.GemQualityAttrsMap = {}
		for i in sorted(csv.gem.quality_attrs):
			cfg = csv.gem.quality_attrs[i]
			qualityAttrs = cls.GemQualityAttrsMap.setdefault(cfg.gemQualitySeqID, [])
			qualityAttrs.append(i)

	def init(self):
		ObjectGem.GemObjsMap[self.id] = self
		return ObjectDBase.init(self)

	# Role.id
	role_db_id = db_property('role_db_id')

	# RoleCard.id
	card_db_id = db_property('card_db_id')

	# 宝石对应 CSV ID
	gem_id = db_property('gem_id')

	# 宝石强化等级
	level = db_property('level')

	# 是否存在（可能已经被分解）
	exist_flag = db_property('exist_flag')

	def getAttrs(self):
		'''
		计算宝石自身属性加成
		'''
		const = zeros()
		percent = zeros()
		cfg = csv.gem.gem[self.gem_id]
		for i in xrange(1, 99):
			attrTypeKey = "attrType%d" % i
			if attrTypeKey not in cfg or not cfg[attrTypeKey]:
				break
			attrType = cfg[attrTypeKey]
			attrNum = cfg["attrNum%d" % i][self.level-1]
			num = str2num_t(attrNum)
			const[attrType] += num[0]
			percent[attrType] += num[1]
		return const, percent


	def strengthGem(self, gemID, level):
		'''
		宝石 强化
		'''
		gem = self.game.gems.getGem(gemID)
		gemCfg = csv.gem.gem[gem.gem_id]
		if level > gemCfg.strengthMax:
			raise ClientError('levelUpLimit error')

		costItemKey = 'costItemMap%d' % gemCfg.strengthCostSeq

		cost = ObjectCostAux(self.game, {})
		for i in xrange(gem.level, level):
			cost += ObjectCostAux(self.game, csv.gem.cost[i][costItemKey])

		if not cost.isEnough():
			raise ClientError("cost not enough")
		else:
			cost.cost(src='gem_strength')

		self.level = level

	def getGemPos(self):
		'''
		宝石 在卡牌的位置
		'''
		card = self.game.cards.getCard(self.card_db_id)
		posGem = None
		for pos, gemID in card.gems.iteritems():
			if gemID == self.id:
				posGem = pos
				break
		return posGem


#
# ObjectGemsMap
#
class ObjectGemsMap(ObjectDBaseMap):

	def _new(self, dic):
		gem = ObjectGem(self.game, self.game._dbcGame)
		gem.set(dic)
		return (gem.id, gem)

	def init(self):
		ret = ObjectDBaseMap.init(self)
		return ret

	def _fixCorrupted(self):
		if self.game.role.areaKey not in ('game.cn.1', 'game.cn.2', 'game.cn.3', 'game.cn.4', 'game.cn.5'):
			return
		for _, gem in self._objs.iteritems():
			cardID = gem.card_db_id
			if cardID and not self.game.cards.getCard(gem.card_db_id):
				gem.card_db_id = None
				logger.warning('role %s gem %s %s card not exist!' % (objectid2string(self.game.role.id), gem.gem_id, objectid2string(gem.id)))

	def getGem(self, gemID):
		'''
		获取单个宝石对象
		'''
		ret = self._objs.get(gemID, None)
		if ret and not ret.exist_flag:
			return None
		return ret

	def getGems(self, gemIDs):
		'''
		获取宝石对象
		'''
		ret = []
		for id in gemIDs:
			if id in self._objs:
				gem = self._objs[id]
				if not gem.exist_flag:
					continue
				ret.append(gem)
		return ret

	def addGems(self, gemsL):
		'''
		添加多个宝石对象
		'''
		if len(gemsL) == 0:
			return {}
		def _new(dic):
			gem = ObjectGem(self.game, self.game._dbcGame)
			gem.set(dic).init().startSync()
			return (gem.id, gem)
		objs = dict(map(_new, gemsL))
		self._objs.update(objs)
		self.game.role.gems = map(lambda o: o.id, self._objs.itervalues())
		self._add(objs.keys())
		return objs

	def deleteGems(self, objs):
		'''
		删除宝石对象
		'''
		if not objs:
			return
		for obj in objs:
			obj.exist_flag = False
			del self._objs[obj.id]
			self._del([obj.id])
			ObjectGem.GemObjsMap.pop(obj.id, None)
		self.game.role.gems = map(lambda o: o.id, self._objs.itervalues())
		for obj in objs:
			obj.delete_async()

	def hadEquipGem(self, cardID, gem, position=None):
		'''
		宝石 是否已镶嵌相同的散件
		'''
		card = self.game.cards.getCard(cardID)
		gemCfg = csv.gem.gem[gem.gem_id]
		for pos, gID in card.gems.iteritems():
			# 非自身
			if gem.id != gID and pos != position:
				cardGem = self.game.gems.getGem(gID)
				cfg = csv.gem.gem[cardGem.gem_id]
				if gem.gem_id == cardGem.gem_id:
					return True
				# 套装id且散件编号相同、镶嵌位置不同时，
				if cfg.suitID and cfg.suitNo and cfg.suitID == gemCfg.suitID and cfg.suitNo == gemCfg.suitNo:
					return True
		return False

	def decomposeGems(self, gems):
		'''
		分解宝石
		'''
		ret = ObjectGainAux(self.game, {})
		for gem in gems:
			gemCfg = csv.gem.gem[gem.gem_id]
			ret += ObjectGainAux(self.game, gemCfg.decomposeReturn)
			if gem.level > 1:
				rebirthObj = ObjectGemRebirth(self.game, gem)
				ret += rebirthObj.getEffect(ConstDefs.gemRebirthRetrunProportion)
				rebirthObj.rebirth()
		return ret

	def rebirthGem(self, gem):
		'''
		宝石 重生
		'''
		rebirthObj = ObjectGemRebirth(self.game, gem)
		eff = rebirthObj.getEffect(ConstDefs.gemRebirthRetrunProportion)

		costRmb = rebirthObj.rebirthCost(eff.result, CardResetDefs.gemCostType)
		cost = ObjectCostAux(self.game, {'rmb': costRmb})
		if not cost.isEnough():
			raise ClientError('cost rmb not enough')
		cost.cost(src='gem_rebirth')
		rebirthObj.rebirth()

		return eff

	def getCardGemSuitNum(self, cardID):
		'''
		卡牌下宝石的套装数量
		'''
		card = self.game.cards.getCard(cardID)
		cardGemSuitMap = {}  # {(suitID, suitQuality): suitNum}
		for pos, gemID in card.gems.iteritems():
			gem = self.getGem(gemID)
			cfgGem = csv.gem.gem[gem.gem_id]
			# 只考虑有套装宝石
			if cfgGem.suitID:
				# 只要品质比它高的都算上
				for quality in xrange(1, cfgGem.quality+1):
					if quality in ObjectGem.GemSuitQualityMap[cfgGem.suitID]:
						suitNum = cardGemSuitMap.get((cfgGem.suitID, quality), 0)
						cardGemSuitMap[(cfgGem.suitID, quality)] = suitNum + 1
		return cardGemSuitMap

	def getCardGemQualitySum(self, cardID):
		'''
		卡牌下所有宝石的指数和
		'''
		card = self.game.cards.getCard(cardID)
		ret = 0
		for pos, gemID in card.gems.iteritems():
			gem = self.getGem(gemID)
			level = gem.level
			quality = csv.gem.gem[gem.gem_id].quality
			qualityNum = csv.gem.quality[level]["qualityNum%d" % quality]
			ret += qualityNum
		return ret

	def getGemSuitAttrs(self, cardID):
		'''
		宝石套装共鸣属性加成
		'''
		const = zeros()
		percent = zeros()
		# cardGemSuitMap  # {(suitID, quality): num}
		# GemSuitNumMap  # {(suitID, suitQuality): [suitNum]}
		addCfgs = {}  # {(suitID, suitNum): cfg}
		cardGemSuitMap = self.getCardGemSuitNum(cardID)
		for k, num in cardGemSuitMap.iteritems():
			suitID, quality = k
			suitNums = ObjectGem.GemSuitNumMap.get(k, [])
			for suitNum in sorted(suitNums):
				if suitNum > num:
					break
				else:
					cfg = ObjectGem.GemSuitMap.get((suitID, suitNum, quality), None)
					# 同套装 数量一样只作用最高品质
					maxQualityCfg = addCfgs.get((suitID, suitNum), cfg)
					if quality >= maxQualityCfg.suitQuality:
						addCfgs[(suitID, suitNum)] = cfg
		for cfg in addCfgs.values():
			for i in xrange(1, 99):
				attrTypeKey = "attrType%d" % i
				if attrTypeKey not in cfg or not cfg[attrTypeKey]:
					break
				attrType = cfg[attrTypeKey]
				attrNum = cfg["attrNum%d" % i]
				num = str2num_t(attrNum)
				const[attrType] += num[0]
				percent[attrType] += num[1]
		return const, percent

	def getGemQualityAttrs(self, cardID):
		'''
		宝石品质指数属性加成
		'''
		const = zeros()
		percent = zeros()

		# 品质指数和
		qualitySum = self.getCardGemQualitySum(cardID)
		card = self.game.cards.getCard(cardID)
		for i in ObjectGem.GemQualityAttrsMap.get(card.gemQualitySeqID, []):
			cfgAttr = csv.gem.quality_attrs[i]
			if qualitySum >= cfgAttr.qualityNum:
				for i in xrange(1, 99):
					attrTypeKey = "attrType%d" % i
					if attrTypeKey not in cfgAttr or not cfgAttr[attrTypeKey]:
						break
					attrType = cfgAttr[attrTypeKey]
					attrNum = cfgAttr["attrNum%d" % i]
					num = str2num_t(attrNum)
					const[attrType] += num[0]
					percent[attrType] += num[1]
			else:
				break
		return const, percent

	def isDuplicateGem(self, gems):
		'''
		宝石 是否有相同散件
		'''
		if len(set(gems)) != len(gems):
			return True
		suits = set()
		for gem in gems:
			cfg = csv.gem.gem[gem.gem_id]
			if cfg.suitID and cfg.suitNo:
				suit = (cfg.suitID, cfg.suitNo)
			else:
				suit = cfg.id
			if suit in suits:
				return True
			else:
				suits.add(suit)
		return False

	def checkGemPosOpenCondition(self, card, pos):
		'''
		宝石槽 是否开启
		'''
		openCondition = ObjectGem.CardGemPosMap.get((card.gemPosSeqID, pos), ())
		if openCondition:
			openType, value = openCondition
			if openType == 1:
				if self.game.role.level < value:
					raise ClientError('role level not enough')
			elif openType == 2:
				if card.rarity < value:
					raise ClientError('card rarity too low')

	def countCardGemQualitySum(self, qualitySum):
		'''
		计算宝石品质指数达到x的精灵数量
		'''
		count = 0
		for cardID in self.game.role.cards:
			if self.getCardGemQualitySum(cardID) >= qualitySum:
				count += 1
		return count


class ObjectGemRebirth(ObjectCardRebirthBase):
	ReturnMap = {}

	@classmethod
	def classInit(cls):
		cls.ReturnMap = {}

		costs = csv.gem.cost
		for key in sorted(costs.keys()):
			tmpDict = {}
			for k in sorted(costs[key].keys()):
				if key <= 1:
					tmpDict[k] = costs[key][k]
				else:
					tmpDict[k] = copy.copy(cls.ReturnMap[key - 1][k])
					cls.dictSum(tmpDict[k], costs[key][k])
			cls.ReturnMap[key] = tmpDict

	def __init__(self, game, gem):
		ObjectBase.__init__(self, game)
		self.gem = gem

	def isValid(self):
		return True

	def rebirth(self):
		self.gem.level = 1

	def getReturnItems(self):
		items = {}
		gemCfg = csv.gem.gem[self.gem.gem_id]

		if self.gem.level == 1:
			raise ClientError('gem rebirth error')
		else:
			costItemKey = 'costItemMap%d' % gemCfg.strengthCostSeq
			items.update(self.ReturnMap[self.gem.level - 1][costItemKey])

		return items
