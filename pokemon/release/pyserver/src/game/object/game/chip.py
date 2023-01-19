#!/usr/bin/python
# coding=utf-8

from framework import str2num_t
from framework.csv import ConstDefs, csv
from framework.helper import objectid2string, WeightRandomObject
from framework.log import logger
from framework.object import ObjectDBase, db_property, ObjectDBaseMap, ObjectBase
from game import ServerError, ClientError
from game.object import ChipDefs, ItemDefs, CardResetDefs
from game.object.game.calculator import zeros
from game.object.game.card import ObjectCardRebirthBase
from game.object.game.gain import ObjectCostAux, ObjectGainAux

import weakref
import copy
import random

#
# ObjectChip
#
class ObjectChip(ObjectDBase):
	DBModel = 'RoleChip'

	ChipObjsMap = weakref.WeakValueDictionary()
	ChipSuitMap = {}  # {(suitID, suitNum, suitQuality): cfg}
	ChipSuitNumMap = {}  # {(suitID, suitQuality): [suitNum]}
	ChipSuitQualityMap = {}  # {suitID: [Quality]}
	ChipSuitChipMap = {}  # {suitID: [chip csvID]}
	ChipLibMap = {}
	ChipMainAttrMap = {}  # {(seq, level): cfg}
	ChipLevelMap = {}  # {seq: {level: sumExp}}
	ChipResonanceMap = {}  # {groupID: [cfg]}
	StrengthCostMax = None
	RecastCostMax = None

	@classmethod
	def classInit(cls):
		# 芯片
		cls.ChipSuitQualityMap = {}
		cls.ChipSuitChipMap = {}
		for i in sorted(csv.chip.chips):
			cfg = csv.chip.chips[i]
			qualitys = cls.ChipSuitQualityMap.setdefault(cfg.suitID, set())
			qualitys.add(cfg.quality)
			cls.ChipSuitChipMap.setdefault(cfg.suitID, []).append(cfg.id)

		# 芯片套装
		cls.ChipSuitMap = {}
		cls.ChipSuitNumMap = {}
		for i in sorted(csv.chip.suits):
			cfg = csv.chip.suits[i]
			cls.ChipSuitMap.setdefault((cfg.suitID, cfg.suitNum, cfg.suitQuality), cfg)
			suitNums = cls.ChipSuitNumMap.setdefault((cfg.suitID, cfg.suitQuality), [])
			suitNums.append(cfg.suitNum)
		for key in cls.ChipSuitNumMap.keys():
			cls.ChipSuitNumMap[key] = sorted(cls.ChipSuitNumMap[key])

		# 副属性随机库
		cls.ChipLibMap = {}
		for i in csv.chip.libs:
			cfg = csv.chip.libs[i]
			cls.ChipLibMap.setdefault(cfg.randomLibID, []).append(cfg)

		# 主属性
		cls.ChipMainAttrMap = {}
		for i in csv.chip.main_attr:
			cfg = csv.chip.main_attr[i]
			cls.ChipMainAttrMap[(cfg.seq, cfg.level)] = cfg

		# 升级
		cls.ChipLevelMap = {}
		for i in csv.chip.strength_cost:
			cfg = csv.chip.strength_cost[i]
			for i in xrange(1, 99):
				key = 'levelExp%d' % i
				if key in cfg:
					if key not in cls.ChipLevelMap:
						cls.ChipLevelMap[key] = {}
					oldSum = cls.ChipLevelMap[key].get(cfg.id-1, 0)
					cls.ChipLevelMap[key][cfg.id] = oldSum + cfg[key]

		# 共鸣
		cls.ChipResonanceMap = {}
		for i in csv.chip.resonance:
			cfg = csv.chip.resonance[i]
			cls.ChipResonanceMap.setdefault(cfg.groupID, []).append(cfg)
		for groupCfgs in cls.ChipResonanceMap.values():
			groupCfgs.sort(key=lambda x: x.priority, reverse=True)

		# 消耗最大键
		cls.RecastCostMax = max(csv.chip.recast_cost)
		cls.StrengthCostMax = max(csv.chip.strength_cost)

		# 刷新csv配置
		for obj in cls.ChipObjsMap.itervalues():
			obj.init()

	def init(self):
		ObjectChip.ChipObjsMap[self.id] = self
		self._csvChip = csv.chip.chips[self.chip_id]
		return ObjectDBase.init(self)

	@property
	def pos(self):
		return self._csvChip.pos

	# Role.id
	role_db_id = db_property('role_db_id')

	# RoleCard.id
	card_db_id = db_property('card_db_id')

	# 芯片对应 CSV ID
	chip_id = db_property('chip_id')

	# 初次随机到的附属性：[副属性随机库的csvID]
	first = db_property('first')

	# 当前的附属性：[(副属性随机库的csvID, 洗炼次数, 强化次数)]
	now = db_property('now')

	# 重生前副属性
	before = db_property('before')

	# 重生后是否洗练
	recast_flag = db_property('recast_flag')

	# 芯片强化等级
	level = db_property('level')

	# 强化当前等级下的经验
	level_exp = db_property('level_exp')

	# 是否存在（可能已经被分解）
	exist_flag = db_property('exist_flag')

	# 是否锁定
	locked = db_property('locked')

	# 当前获得的总经验
	def exp():
		dbkey = 'sum_exp'
		def fset(self, value):
			old = self.exp
			inc = value - old
			if inc == 0:
				return

			seq = 'levelExp%d' % self._csvChip.strengthSeq
			levelSeq = self.ChipLevelMap[seq]

			if inc <= 0:
				self.level = 1
			while self.level < self._csvChip.maxLevel and value >= levelSeq[self.level]:
				self.level += 1

			value = min(value, levelSeq[self.level])
			self.db['level_exp'] = value - levelSeq.get(self.level-1, 0)
			self.db[dbkey] = value
		return locals()
	exp = db_property(**exp())

	def getAttrs(self):
		'''
		计算芯片自身属性加成
		'''
		const = zeros()
		percent = zeros()

		# 主属性
		mainAttrCfg = self.ChipMainAttrMap[(self._csvChip.mainAttr, self.level)]
		for i in xrange(1, 99):
			attrTypeKey = "attrType%d" % i
			if attrTypeKey not in mainAttrCfg or not mainAttrCfg[attrTypeKey]:
				break
			attrType = mainAttrCfg[attrTypeKey]
			attrNum = mainAttrCfg["attrNum%d" % i]
			num = str2num_t(attrNum)
			const[attrType] += num[0]
			percent[attrType] += num[1]

		# 副属性
		for csvID, recastTimes, strengthTimes in self.now:
			libCfg = csv.chip.libs[csvID]
			for i in xrange(1, 99):
				attrType = "attrType%d" % i
				if attrType not in libCfg or not libCfg[attrType]:
					break
				attrType = libCfg[attrType]
				attrNum = libCfg["attrNum%d" % i][strengthTimes]
				num = str2num_t(attrNum)
				const[attrType] += num[0]
				percent[attrType] += num[1]

		return const, percent

	def getCurAttrStrenthMap(self):
		'''
		获取芯片当前等级各属性最大强化次数
		'''
		strengthMap = {}
		cfg = csv.chip.chips[self.chip_id]
		for n, (csvID, recastTimes, strengthTimes) in enumerate(self.now):
			# 当前等级最大强化次数
			if n < cfg.startNum:
				num = len([i for i in cfg.strengthLevels if i <= self.level])
			else:
				num = len([i for i in cfg.strengthLevels if cfg.acquiredLevels[n - cfg.startNum] <= i <= self.level])
			# 最大强化次数
			maxStrengthTimes = len(csv.chip.libs[csvID].attrNum1) - 1
			strengthMap[csvID] = min(num, maxStrengthTimes)
		return strengthMap
	
	def randomStrengthAttrs(self, num, strengthMap):
		'''
		分配属性强化次数
		'''
		for i in xrange(num):
			pool = []
			for n, (csvID, recastTimes, strengthTimes) in enumerate(self.now):
				# 重生后未洗练时 强化次数上限按照重生前计算
				if self.before and not self.recast_flag and n < len(self.before):
					limit = self.before[n][2]
				else:
					limit = strengthMap.get(csvID, 0)

				if strengthTimes < limit:
					pool.append(n)

			if not pool:
				continue  # 无需强化时跳过
			strengthIndex = random.choice(pool)
			old = self.now[strengthIndex]
			self.now[strengthIndex] = (old[0], old[1], old[2]+1)

			if self.before:
				self.checkBeforeStatus()

	def strengthChip(self, costChips, costCsvIDs):
		'''
		芯片 强化
		'''
		if not costCsvIDs:
			costCsvIDs = {}
		if self.level >= self._csvChip.maxLevel:
			raise ClientError('levelUpLimit error')

		# 计算经验
		exp = 0
		# 金币返还
		goldRet = 0
		for chipID in costChips:
			chip = self.game.chips.getChip(chipID)
			if chip.card_db_id:
				raise ClientError('chip cost material is equiped')
			if chip.locked:
				raise ClientError('chip locked')
			exp += csv.chip.chips[chip.chip_id].exp + chip.exp
			if chip.exp > 0:
				goldRet += chip.exp * ConstDefs.chipExpNeedGold
		for csvID, count in costCsvIDs.iteritems():
			cfg = csv.items[csvID]
			chipExp = cfg.specialArgsMap.get('chipExp', None)
			if chipExp is None:
				raise ClientError('csvID=%d is not chip item' % csvID)
			exp += chipExp * count

		# 计算消耗
		cost = ObjectCostAux(self.game, costCsvIDs)
		# 直接从消耗里扣除金币返还 这样不是很准确, 应该先检查是否足够再扣除返还
		cost += ObjectCostAux(self.game, {'gold': max(exp * ConstDefs.chipExpNeedGold - goldRet, 0)})
		cost.setCostChips([self.game.chips.getChip(chipID) for chipID in costChips])
		if not cost.isEnough():
			raise ClientError("cost not enough")

		cost.cost(src='chip_strength_cost')

		self.exp += exp

		# 等级触发的附属性随机和强化。如果同时可以获得副属性和强化副属性，获得优先再随机强化。
		cfg = csv.chip.chips[self.chip_id]
		# 应有的副属性数量 
		attrNum = cfg.startNum + len([ i for i in cfg.acquiredLevels if i <= self.level])
		# 随机获得属性
		num = attrNum - len(self.now)
		self.randomAttrs(num, self._csvChip.acquiredLib)

		# 当前各附属性最高强化次数
		strengthMap = self.getCurAttrStrenthMap()

		# 强化次数
		strengthNum = len([i for i in cfg.strengthLevels if i <= self.level]) - sum([k[2] for k in self.now])
		self.randomStrengthAttrs(strengthNum, strengthMap)

	def checkBeforeStatus(self):
		'''
		检查芯片是否回到重生前的状态
		'''
		flag = True
		# 重生 洗练后 只要属性保持一致就行
		if len(self.before) == len(self.now) and self.recast_flag:
			flag = True
		elif len(self.now) >= len(self.before):
			for index, k in enumerate(self.before):
				if k[2] > self.now[index][2]:
					flag = False
					break
		else:
			flag = False

		if flag:
			self.before = []

	def recast(self, pos1, pos2):
		'''
		芯片 副属性洗练
		'''

		# 洗练属性
		attrs = set([pos for pos, v in enumerate(self.now) if v[1] > 0])
		for pos in (pos1, pos2):
			if pos is not None:
				if 0 <= pos < len(self.now):
					attrs.add(pos)
				else:
					raise ClientError("no this attr")

		# 洗练总数量不能超过2
		if len(attrs) > 2:
			raise ClientError('recast total num > 2')

		# 消耗
		recastTimes = max([recastTimes for csvID, recastTimes, strengthTimes in self.now]) + 1
		costItemKey = 'costItemMap%d' % self._csvChip.recastCostSeq
		if recastTimes <= self.RecastCostMax:
			costCfg = csv.chip.recast_cost[recastTimes]
		else:
			costCfg = csv.chip.recast_cost[self.RecastCostMax]
		cost = ObjectCostAux(self.game, costCfg[costItemKey])
		if not cost.isEnough():
			raise ClientError('cost not enough')
		cost.cost(src='chip_recast_cost')

		# 洗练
		for pos, (csvID, recastTimes, strengthTimes) in enumerate(self.now):
			if pos not in (pos1, pos2):
				continue

			recastTimes += 1
			weights = []
			attrs = []
			attrs.extend(self.now)
			# 加上重生后未出现的属性
			attrs.extend(self.before[len(self.now):])
			added = {csvID for csvID, _, _ in attrs}
			for cfg in self.ChipLibMap[self._csvChip.recastLib]:
				for a, b, weight in cfg.recastWeight:
					if a <= recastTimes <= b:
						break
				# 如果有重复（包括自己），算修正
				weightFix = 1
				if cfg.id in added:
					for a, b, weightFix in cfg.recastWeightFix:
						if a <= recastTimes <= b:
							break
				weights.append((cfg.id, weight * weightFix))
			newCsvID, _ = WeightRandomObject.onceRandom(weights)
			self.now[pos] = (newCsvID, recastTimes, strengthTimes)

		# 重生后洗练仅恢复未激活属性
		if self.before and not self.recast_flag:
			self.recast_flag = True

		# 重置分配强化次数
		for pos, (csvID, recastTimes, strengthTimes) in enumerate(self.now):
			self.now[pos] = (csvID, recastTimes, 0)

		# 重新分配强化次数
		cfg = csv.chip.chips[self.chip_id]
		curStrengthNum = len([i for i in cfg.strengthLevels if i <= self.level])
		strengthMap = self.getCurAttrStrenthMap()
		self.randomStrengthAttrs(curStrengthNum, strengthMap)

	def getChipPos(self):
		'''
		芯片 在卡牌的位置
		'''
		card = self.game.cards.getCard(self.card_db_id)
		posChip = None
		for pos, chipID in card.chip.iteritems():
			if chipID == self.id:
				posChip = pos
				break
		return posChip

	def onAdd(self):
		'''
		最开始获得的时候，随机副属性。
		'''
		self.level = 1
		self.level_exp = 0

		# 随机初始副属性
		self.randomAttrs(self._csvChip.startNum, self._csvChip.startLib)

	def randomAttrs(self, num, randomLibID):
		'''
		随机生成属性
		'''
		for _ in xrange(num):
			if self.before and len(self.before) > len(self.now):
				csvID, recastTimes, _ = self.before[len(self.now)]
				self.now.append((csvID, recastTimes, 0))
			else:
				choices = self.ChipLibMap[randomLibID]
				got = [i[0] for i in self.now]
				weights = []
				for cfg in choices:
					if cfg.id in got:
						weights.append((cfg.id, cfg.drawWeight * cfg.drawWeightFix))
					else:
						weights.append((cfg.id, cfg.drawWeight))
				csvID, _ = WeightRandomObject.onceRandom(weights)
				self.first.append(csvID)
				self.now.append((csvID, 0, 0))

	def refreshBefore(self, cfg):
		'''
		是否需要更新重生属性数据
		'''
		if len(self.now) == cfg.startNum and all([ strengthTimes == 0 for _, _, strengthTimes in self.now]):
			return

		now = copy.deepcopy(self.now)
		if not self.before:
			self.before = now
			return 

		if len(self.before) > len(self.now):
			# 洗练后 副属性少于重生前 则只覆盖更改的部分
			if self.recast_flag:
				for i in xrange(len(self.before)):
					if i < len(self.now):
						self.before[i] = now[i]
					else:
						self.before[i][2] = 0
		elif len(self.before) < len(self.now):
			self.before = now
		else:
			if self.recast_flag:
				self.before = now
			# 副属性数量相同情况下，看强化次数
			elif sum([i[2] for i in self.before]) < sum([i[2] for i in self.now]):
				self.before = now

	def rebirth(self):
		"""
		芯片 重生
		"""
		rebirthObj = ObjectChipsRebirth(self.game, self)
		eff = rebirthObj.getEffect(ConstDefs.chipRebirthRetrunProportion)

		costRmb = rebirthObj.rebirthCost(eff.result, CardResetDefs.chipCostType)
		cost = ObjectCostAux(self.game, {'rmb': costRmb})
		if not cost.isEnough():
			raise ClientError('cost rmb not enough')
		cost.cost(src='chip_rebirth')
		rebirthObj.rebirth()

		return eff


#
# ObjectChipsMap
#
class ObjectChipsMap(ObjectDBaseMap):

	def init(self):
		self._passive_skills = {} # 效果被动技能
		return ObjectDBaseMap.init(self)

	def _new(self, dic):
		chip = ObjectChip(self.game, self.game._dbcGame)
		chip.set(dic)
		return (chip.id, chip)

	def getChip(self, chipID):
		'''
		获取单个芯片对象
		'''
		ret = self._objs.get(chipID, None)
		if ret and not ret.exist_flag:
			return None
		return ret

	def getChips(self, chipIDs):
		'''
		获取芯片对象
		'''
		ret = []
		for id in chipIDs:
			if id in self._objs:
				chip = self._objs[id]
				if not chip.exist_flag:
					continue
				ret.append(chip)
		return ret

	def addChips(self, chipsL):
		'''
		添加多个芯片对象
		'''
		if len(chipsL) == 0:
			return {}
		def _new(dic):
			chip = ObjectChip(self.game, self.game._dbcGame)
			chip.set(dic).init().startSync()
			chip.onAdd()
			return (chip.id, chip)
		objs = dict(map(_new, chipsL))
		self._objs.update(objs)
		self.game.role.chips = map(lambda o: o.id, self._objs.itervalues())
		self._add(objs.keys())
		return objs

	def deleteChips(self, objs):
		'''
		删除芯片对象
		'''
		if not objs:
			return
		for obj in objs:
			obj.exist_flag = False
			del self._objs[obj.id]
			self._del([obj.id])
			ObjectChip.ChipObjsMap.pop(obj.id, None)
		self.game.role.chips = map(lambda o: o.id, self._objs.itervalues())
		for obj in objs:
			obj.delete_async()
			plans = self.game.role.chip_plan_map.get(obj.id, [])
			if plans:
				for idx, pos in plans:
					plan = self.game.role.chip_plans.get(idx, {})
					del plan["chips"][pos]

	def getCardChipSuitNum(self, card):
		'''
		卡牌下芯片的套装数量
		'''
		cardChipSuitMap = {}  # {(suitID, suitQuality): suitNum}
		for pos, chipID in card.chip.iteritems():
			chip = self.getChip(chipID)
			chipCfg = csv.chip.chips[chip.chip_id]
			# 只考虑有套装芯片
			if chipCfg.suitID:
				# 只要品质比它高的都算上
				for quality in xrange(1, chipCfg.quality+1):
					if quality in ObjectChip.ChipSuitQualityMap[chipCfg.suitID]:
						suitNum = cardChipSuitMap.get((chipCfg.suitID, quality), 0)
						cardChipSuitMap[(chipCfg.suitID, quality)] = suitNum + 1
		return cardChipSuitMap

	def getChipSuitAttrs(self, card):
		'''
		芯片套装共鸣属性加成
		'''
		# cardChipSuitMap  # {(suitID, quality): num}
		# ChipSuitNumMap  # {(suitID, suitQuality): [suitNum]}
		const = zeros()
		percent = zeros()
		addCfgMaps = {}  # {(suitID, suitNum): cfg}
		skills = {}
		cardChipSuitMap = self.getCardChipSuitNum(card)
		for k, num in cardChipSuitMap.iteritems():
			suitID, quality = k
			for suitNum in ObjectChip.ChipSuitNumMap[k]:
				if suitNum > num:
					break
				else:
					cfg = ObjectChip.ChipSuitMap[(suitID, suitNum, quality)]
					# 同套装 数量一样只作用最高品质
					maxQualityCfg = addCfgMaps.get((suitID, suitNum), cfg)
					if quality >= maxQualityCfg.suitQuality:
						addCfgMaps[(suitID, suitNum)] = cfg

		# 如果是六件相同的套装 需要补足一个两件套效果
		addCfgs = addCfgMaps.values()
		for k in sorted(cardChipSuitMap.keys(), key=lambda x: x[1], reverse=True):
			if cardChipSuitMap[k] == 6:
				suitID, quality = k
				cfg = ObjectChip.ChipSuitMap[(suitID, 2, quality)]
				addCfgs.append(cfg)
				break

		for cfg in addCfgs:
			for i in xrange(1, 99):
				attrTypeKey = "attrType%d" % i
				if attrTypeKey not in cfg or not cfg[attrTypeKey]:
					break
				attrType = cfg[attrTypeKey]
				attrNum = cfg["attrNum%d" % i]
				num = str2num_t(attrNum)
				const[attrType] += num[0]
				percent[attrType] += num[1]
			if cfg.skillID:
				skills[cfg.skillID] = 1
		self._passive_skills[card.id] = skills
		return const, percent

	def getResonanceAttrs(self, card):
		'''
		共鸣属性加成
		'''
		active = []
		for groupCfgs in ObjectChip.ChipResonanceMap.values():
			for cfg in groupCfgs:
				num, condition = cfg.param
				chipNum = 0
				for pos, chipID in card.chip.iteritems():
					chip = self.game.chips.getChip(chipID)
					if cfg.type == ChipDefs.ResonanceQuality:
						chipCfg = csv.chip.chips[chip.chip_id]
						if chipCfg.quality >= condition:
							chipNum += 1
					elif cfg.type == ChipDefs.ResonanceLevel:
						if chip.level >= condition:
							chipNum += 1
				if chipNum >= num:
					active.append(cfg)
					break

		const = zeros()
		percent = zeros()
		for cfg in active:
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

	def getPassiveSkills(self, cardID):
		return self._passive_skills.get(cardID, {})


#
# ObjectChipsRebirth 重生
#
class ObjectChipsRebirth(ObjectCardRebirthBase):

	def __init__(self, game, chip):
		ObjectBase.__init__(self, game)
		self.chip = chip

	def isValid(self):
		return True

	def rebirth(self):
		self.chip.level_exp = 0
		self.chip.exp = 0
		self.chip.level = 1

		# 保留初始条目属性
		cfg = csv.chip.chips[self.chip.chip_id]
		self.chip.refreshBefore(cfg)
		self.chip.recast_flag = False
		self.chip.now = [(csvID, recast, 0) for csvID, recast, _ in self.chip.now[:cfg.startNum]]

	def getReturnItems(self):
		items = {}
		# 强化返回金币
		items['gold'] = self.chip.exp * ConstDefs.chipExpNeedGold
		# 强化返回材料
		exp = self.chip.exp
		for itemID in ChipDefs.StrengthItemIDs:
			cfg = csv.items[itemID]
			texp = cfg.specialArgsMap['chipExp']
			count = int(exp / texp)
			if count > 0:
				exp -= count * texp
				items[itemID] = count

		return items
