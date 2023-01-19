#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2014 YouMi Information Technology Inc.
'''
from __future__ import absolute_import

from framework import str2num_t, nowtime_t, is_percent_t,nowtime2int
from framework.csv import csv, ErrDefs, ConstDefs
from framework.log import logger
from framework.object import ObjectBase, ObjectDBase, ObjectDBaseMap, db_property, ObjectDicAttrs, GCWeakValueDictionary, ReloadHooker, db_ro_property
from framework.helper import getL10nCsvValue, WeightRandomObject, objectid2string
from game import ServerError, ClientError
from game.globaldata import CardResetRMBCost, EquipExpToGold, WorldBossHuodongID
from game.object import SkillDefs, AttrDefs, ItemDefs, SceneDefs, TargetDefs, EffortValueDefs, PropertySwapDefs, CardResetDefs, FragmentDefs, HeldItemDefs, CardAbilityDefs, AchievementDefs, MessageDefs, FeatureDefs, MegaDefs, CardDefs, CrossUnionFightDefs
from game.object.game.cross_union_fight import ObjectCrossUnionFightGameGlobal
from game.object.game.gym import ObjectGymGameGlobal
from game.object.game.cross_arena import ObjectCrossArenaGameGlobal
from game.object.game.equip import ObjectEquip
from game.object.game.gain import ObjectCostAux, ObjectGainAux
from game.object.game.rank import ObjectRankGlobal
from game.object.game.message import ObjectMessageGlobal
from game.object.game.talent import ObjectTalentTree
from game.object.game.yyhuodong import ObjectYYHuoDongFactory
from game.object.game.levelcsv import ObjectFeatureUnlockCSV
from game.object.game.union_fight import ObjectUnionFightGlobal
from game.object.game.calculator import dict2attrs, Calculator, zeros, ones, temporary
from game.object.game.craft import ObjectCraftInfoGlobal
from game.object.game.cross_craft import ObjectCrossCraftGameGlobal
from game.object.game.cross_mine import ObjectCrossMineGameGlobal
from game.thinkingdata import ta

import copy
import weakref
import math
import datetime
import random
from contextlib import contextmanager

from collections import defaultdict

# 个体值属性
NValueAttrs = (AttrDefs.hp, AttrDefs.speed, AttrDefs.damage, AttrDefs.defence, AttrDefs.specialDamage, AttrDefs.specialDefence)

# 努力值属性
EffortAttrs = (AttrDefs.hp, AttrDefs.speed, AttrDefs.damage, AttrDefs.defence, AttrDefs.specialDamage, AttrDefs.specialDefence)
# 努力值属性随机不包含特攻，特攻数值等于物攻数值
EffortRandomAttrs = (AttrDefs.hp, AttrDefs.speed, AttrDefs.damage, AttrDefs.defence, AttrDefs.specialDefence)

#
# CardAttrs
#

class CardAttrs(ObjectDicAttrs):
	'''
	将AttrDefs里的属性名和CSV里的列名进行对应
	self._attrs里面的key是CSV里的列名
	使用getattr方式访问
	'''
	def __getattr__(self, name):
		csvName = getattr(AttrDefs, name, None)
		if not csvName:
			return None
		return ObjectDicAttrs.__getattr__(self, csvName)

#
# CardSlim
#

class CardSlim(object):
	'''
	计算属性所需要的属性
	slim = {card_id,}
	不计算装备相关以及先手值
	'''
	def __init__(self, slim):
		self.game = None # 模仿ObjectBase，但不会真有game
		self.equipsMap = {}
		self.card_id = slim['card_id']
		csvCard = csv.cards[self.card_id]
		self.unitID = csvCard.unitID if csvCard else slim['unit_id']
		self.markID = csvCard.cardMarkID
		self.fightingWeight = csvCard.fightingWeight
		self.level = slim['level']
		self.star = slim['star']
		self.advance = slim['advance']
		self.skin_id = slim["skin_id"]
		self.character = slim['character'] if 'character' in slim else 0
		self.nvalue = slim['nvalue'] if 'nvalue' in slim else {}
		self.feelType = csvCard.feelType
		self.fetters = slim['fetters'] if 'fetters' in slim else {}
		self.skills = slim['skills'] if 'skills' in slim else {}
		self.zawake_skills = slim['zawake_skills'] if 'zawake_skills' in slim else []
		self.starTypeID = csvCard.starTypeID
		self.advanceTypeID = csvCard.advanceTypeID
		self.effort_values = slim['effort_values'] if 'effort_values' in slim else {}
		self.abilities = None
		self.effortSeqID = csvCard.effortSeqID
		self.effort_advance = slim['effort_advance'] if 'effort_advance' in slim else 1

		self.calc = Calculator()

#
# ObjectCard
#

class ObjectCard(ObjectDBase):
	DBModel = 'RoleCard'

	CardsLevelSeq = {}
	CardsMarkStarMap = {} # {(starTypeID, star): csv}
	CardAdvanceMarkLevelMap = {} # {(advanceTypeID, advancelevel): csv}
	CardMarkDevelopMap = {} # {(cardMarkID, branch, develop): card_id}
	CardStar2FragMap = {} #{(type,star):csv}
	CardRecastMap = {} #{locknum:csv}
	CardCharacterPercentMap = {} # {character: attrs}
	CardLevelBaseAttrsCache = {} # {(csvPath, card.level): {attrs}}
	CardNValueConstAttrsRatioCache = {} # {(csvPath, card.level): {attrs}}
	CardFetterAttrMap = {} # {fetterID: (attr, num)} lazy
	CardFetterMarkIDMap = {} # {fetterID: set([markID, ...])} # fetter 会影响的卡牌 markID
	CardMarkIDFetterMap = {} # {markID: set([fetterID, ...])} # 卡牌markID 会影响的 fetter
	CardEffortMap = {}  # {(attrType, advance): cfg}
	CardEffortAdvanceMap = {}  # {(effortSeqID, advance): {attrs, advanceLimit, attrEffect, needLevel}}
	CardsObjsMap = GCWeakValueDictionary()
	CardStarEffectMap = {} # {(starTypeID, star): csv}
	CardStarEffAttrAddMap = {}  # 升星对自身属性加成 {(starTypeID, star): (const, percent)} lazy
	CardAbilityGroupMap = {}  # {abilityID: [group, ...]}  全体属性加成的特性
	CardAbilityAttrMap = {}  # {[csvID, group]: [attrNum]}  特性的属性加成值
	CardAbilityMap = {} # {(seqID, position): cfg}
	BattleCardHaloAttrMap = {} # 编队光环属性加成
	SkillPassiveAttrsCache = {} # {passiveSkillID: {attr: lambda}}
	CardStatAdditionMap = {}  # 配表中配置的属性 {(card.starTypeID, card.star):{'CList':zero(), 'Grow':zero()},...}
	CardAdvanceMarkLevelAdditionMap = {}  # 配表中配置的属性 {(card.starTypeID, card.star):{'CList':zero(), 'Grow':zero()},...}
	CardUnitAdditionMap = {}  # 配表中配置的属性{csvID:zero(),...}
	FightWeightAttrs = []  # 配表中配置的属性列表
	CardNvalueRmbMap = {} # 个体值洗炼钻石保底
	CardSwitchBranchCostMap = {} # 卡牌切换分支消耗


	ClientIgnores = set(['db_attrs'])

	@classmethod
	def classInit(cls):
		# 经验排序
		cls.CardsLevelSeq = {}
		testCsv = csv.base_attribute.card_level[1]
		for i in xrange(1, 9999):
			seq = 'levelExp%d' % i
			if seq not in testCsv:
				break
			cls.CardsLevelSeq[i] = [0]
			for j in csv.base_attribute.card_level:
				exp = csv.base_attribute.card_level[j][seq]
				cls.CardsLevelSeq[i].append(cls.CardsLevelSeq[i][-1] + exp)

		# 卡牌星级
		cls.CardsMarkStarMap = {}
		for i in csv.card_star:
			csvStar = csv.card_star[i]
			cls.CardsMarkStarMap[(csvStar.typeID, csvStar.star)] = csvStar

		# 卡牌升星效果
		cls.CardStarEffectMap = {}
		for i in csv.card_star_effect:
			cfg = csv.card_star_effect[i]
			cls.CardStarEffectMap[(cfg.typeID, cfg.star)] = cfg

		# 卡牌进阶
		cls.CardAdvanceMarkLevelMap = {}
		for i in csv.base_attribute.advance_level:
			csvAdvance = csv.base_attribute.advance_level[i]
			cls.CardAdvanceMarkLevelMap[(csvAdvance.typeID, csvAdvance.stage)] = csvAdvance

		# 卡牌进化
		cls.CardMarkDevelopMap = {}
		for i in csv.cards:
			csvCard = csv.cards[i]
			cls.CardMarkDevelopMap[(csvCard.cardMarkID, csvCard.branch, csvCard.develop)] = i

		# 卡牌星级转换碎片数
		cls.CardStar2FragMap = {}
		for i in csv.card_star2frag:
			csvCardFrag = csv.card_star2frag[i]
			cls.CardStar2FragMap[(csvCardFrag.type, csvCardFrag.getStar)] = csvCardFrag

		# 卡牌洗炼
		cls.CardRecastMap = {}
		for i in csv.card_recast:
			csvRecast = csv.card_recast[i]
			cls.CardRecastMap[csvRecast.lockNum] = csvRecast

		# 性格百分比加成
		cls.CardCharacterPercentMap = {}
		for i in csv.character:
			cfg = csv.character[i]
			percent = ones()
			for attrType, attrNum in cfg.attrMap.iteritems():
				if is_percent_t(attrNum): # 性格只能配置百分比
					percent[attrType] = str2num_t(attrNum)[1]
			cls.CardCharacterPercentMap[i] = percent

		# 努力值
		cls.CardEffortMap = {}
		for i in csv.card_effort:
			cfg = csv.card_effort[i]
			cls.CardEffortMap[(AttrDefs.attrsEnum[cfg.attrType], cfg.advance)] = cfg

		# 努力值进阶
		cls.CardEffortAdvanceMap = {}
		effortAdvanceKeys = sorted(csv.card_effort_advance.keys())
		for i in effortAdvanceKeys:
			cfg = csv.card_effort_advance[i]
			oldValue = cls.CardEffortAdvanceMap.get((cfg.effortSeqID, cfg.advance-1), {})
			newValue = {}
			for k in EffortAttrs:
				newValue[k] = oldValue.get(k, 0) + cfg[k]
			newValue['advanceLimit'] = cfg.advanceLimit
			newValue['attrEffect'] = cfg.attrEffect
			newValue['needLevel'] = cfg.needLevel
			cls.CardEffortAdvanceMap[(cfg.effortSeqID, cfg.advance)] = newValue

		# 羁绊影响的卡牌
		cls.CardFetterMarkIDMap = {}
		for i in csv.cards:
			cfg = csv.cards[i]
			for fetterID in cfg.fetterList:
				cls.CardFetterMarkIDMap.setdefault(fetterID, set([])).add(cfg.cardMarkID)

		# 卡牌影响的羁绊
		cls.CardMarkIDFetterMap = {}
		for i in csv.fetter:
			cfg = csv.fetter[i]
			for card_id in cfg.cards:
				markID = csv.cards[card_id].cardMarkID
				cls.CardMarkIDFetterMap.setdefault(markID, set([])).add(i)

		# 全体属性加成的特性
		cls.CardAbilityGroupMap = {}
		cls.CardAbilityAttrMap = {}
		cls.CardAbilityMap = {}
		for csvID in csv.card_ability:
			cfg = csv.card_ability[csvID]
			cls.CardAbilityMap[(cfg.abilitySeqID, cfg.position)] = cfg
			if cfg.effectType == CardAbilityDefs.EffectAttrType:
				groups = []
				for i in xrange(1, 99):
					at = 'attrType%d' % i
					if at not in cfg or not cfg[at]:
						break
					if cfg['attrAddType%d' % i] == CardAbilityDefs.AttrAddAll:  # 全体
						groups.append(i)
					cls.CardAbilityAttrMap.setdefault((csvID, i), cfg['attrNum%d' % i])
				if groups:
					cls.CardAbilityGroupMap.setdefault(csvID, groups)

		# 编队光环属性加成
		cls.BattleCardHaloAttrMap = {} # {group: [cfg, ]}
		for i in csv.battle_card_halo:
			cfg = csv.battle_card_halo[i]
			if cfg.group not in cls.BattleCardHaloAttrMap:
				cls.BattleCardHaloAttrMap[cfg.group] = [cfg]
			else:
				cls.BattleCardHaloAttrMap[cfg.group].append(cfg)
		for group, cfgs in cls.BattleCardHaloAttrMap.iteritems():
			cls.BattleCardHaloAttrMap[group] = sorted(cfgs, key=lambda x:x.priority, reverse=True)

		# 技能被动增加属性表
		cls.SkillPassiveAttrsCache = {}
		lambdaPrefix = 'lambda skillLevel, baseon=None: '
		for skillID in csv.skill:
			cfg = csv.skill[skillID]
			if cfg.skillType != SkillDefs.passiveAttr:
				continue
			attrs = {}
			for attrE, val in cfg.passiveSkillAttrs.iteritems():
				if isinstance(val, str):
					if val[-1] == '%':
						param = (None, eval(lambdaPrefix + val[:-1]))
					else:
						param = (eval(lambdaPrefix + val), None)
				else:
					param = (eval(lambdaPrefix + str(val)), None)
				attrs[attrE] = param
			cls.SkillPassiveAttrsCache[skillID] = attrs

		# 配表中记录的属性
		cls.CardStatAdditionMap = {}
		for csvID in csv.card_star:
			csvCfg = csv.card_star[csvID]
			cList = zeros()
			growList = zeros()
			for i, attr in enumerate(AttrDefs.attrsEnum[1:], 1):
				key = attr + 'C'
				if key in csvCfg:
					cList[i] = csvCfg[key]
				key = attr + 'Grow'
				if key in csvCfg:
					growList[i] = csvCfg[key]
			cls.CardStatAdditionMap[(csvCfg.typeID, csvCfg.star)] = {'cList': cList, 'growList': growList}

		# 配表中记录的属性
		cls.CardAdvanceMarkLevelAdditionMap = {}
		for csvID in csv.base_attribute.advance_level:
			csvCfg = csv.base_attribute.advance_level[csvID]
			cList = zeros()
			growList = zeros()
			for i, attr in enumerate(AttrDefs.attrsEnum[1:], 1):
				key = attr + 'C'
				if key in csvCfg:
					cList[i] = csvCfg[key]
				key = attr + 'Grow'
				if key in csvCfg:
					growList[i] = csvCfg[key]
			cls.CardAdvanceMarkLevelAdditionMap[(csvCfg.typeID, csvCfg.stage)] = {'cList': cList, 'growList': growList}

		# 配表中记录的属性列表
		cls.CardUnitAdditionMap = {}
		for csvID in csv.unit:
			csvCfg = csv.unit[csvID]
			cList = ones()
			growList = zeros()
			basecList = ones()
			for i, attr in enumerate(AttrDefs.attrsEnum[1:], 1):
				key = attr + 'C'
				if key in csvCfg:
					cList[i] = csvCfg[key]
				key = attr + 'Grow'
				if key in csvCfg:
					growList[i] = csvCfg[key]
				key = attr + 'BaseC'
				if key in csvCfg:
					basecList[i] = csvCfg[key]
			cls.CardUnitAdditionMap[csvID] = {'cList': cList, 'growList': growList, 'basecList': basecList}

		# 配表中配置的属性列表
		cls.FightWeightAttrs = []
		for i in csv.fighting_weight:
			csvCfg = csv.fighting_weight[i]
			cls.FightWeightAttrs = list(csvCfg.keys())
			break

		# 个体值洗炼钻石保底
		cls.CardNvalueRmbMap = {}
		for i in csv.nvalue_rmb:
			cfg = csv.nvalue_rmb[i]
			cls.CardNvalueRmbMap[cfg.locknum] = cfg

		# 切换分支消耗
		cls.CardSwitchBranchCostMap = {}
		for i in csv.cards_branch_cost:
			cfg = csv.cards_branch_cost[i]
			cls.CardSwitchBranchCostMap[cfg.developType] = cfg.cost
		# 清理lazy配置缓存
		cls.CardFetterAttrMap = {}
		cls.CardStarEffAttrAddMap = {}

		# 清理baseAttribute缓存
		cls.CardLevelBaseAttrsCache = {}
		cls.CardNValueConstAttrsRatioCache = {}

		# 刷新csv配置
		for obj in cls.CardsObjsMap.itervalues():
			obj.init()

	def init(self):
		self._csvCard = csv.cards[self.card_id]
		csvAdvance = self.CardAdvanceMarkLevelMap.get((self.advanceTypeID, self.advance), None)
		self._quality = csvAdvance.quality if csvAdvance else 0
		# 控制 attrs 是否需要持久化
		if self.db_attrs:
			self._display = True
		else:
			self._display = False

		if self.held_item:
			heldItem = self.game.heldItems.getHeldItem(self.held_item)
			if not heldItem:
				logger.warning('role %s card %s held_item not exited!' % (objectid2string(self.game.role.id), objectid2string(self.held_item)))
				self.held_item = None

		if self.effort_values: # 线上数据处理, 物攻特攻采用数值较大者
			damage = self.effort_values.get(AttrDefs.damage, 0)
			specialDamage = self.effort_values.get(AttrDefs.specialDamage, 0)
			damage = max(damage, specialDamage)
			self.effort_values[AttrDefs.damage] = damage
			self.effort_values[AttrDefs.specialDamage] = damage

		if self.effort_advance == 0:
			self.effort_advance = 1
			# 线上数据 处理
			if self.effort_values:
				self.resetEffortAdvance()
				for attr in EffortAttrs:
					self.effort_values[attr] = min(self.effort_values.get(attr, 0), self.calEffortArrtUpper(attr, self.advanceLimit))

		# temp fix card 1231 炎帝, 641 拉普拉斯
		if self.card_id == 1231 or self.card_id == 641:
			prefix  = 'role %d %s card %d %s' % (self.game.role.uid, self.game.role.pid, self.card_id, objectid2string(self.id))
			for skillID in self.skills.keys():
				if skillID == 61101 and 61151 not in self.skills:
					level = self.skills.pop(skillID)
					self.skills[61151] = level
					logger.info('%s 61101->61151 level %d', prefix, level)
				elif skillID == 61102 and 61152 not in self.skills:
					level = self.skills.pop(skillID)
					self.skills[61152] = level
					logger.info('%s 61102->61152 level %d', prefix, level)

		if len(self.star_skill_level) < len(self.starSkillList):
			self.star_skill_level += [0] * (len(self.starSkillList) - len(self.star_skill_level))

		if len(self.skill_level) < len(self.skillList): # skill_level字段初始化
			self.skill_level += [0] * (len(self.skillList) - len(self.skill_level))
			for idx, skillID in enumerate(self.skillList):
				self.skill_level[idx] = self.skills.get(skillID, 0)

		self._attrs = None
		self._attrs2 = None
		self.calc = Calculator()
		self._initEquips()
		self._initSkill()
		self._initExp()
		self._initAttrs()

		ObjectCard.CardsObjsMap[self.id] = self
		return ObjectDBase.init(self)

	def _fixCorrupted(self):
		if self.develop != self._csvCard.develop: # 配表修改了develop
			self.develop = self._csvCard.develop

	def initRobot(self):
		self._csvCard = csv.cards[self.card_id]
		csvAdvance = self.CardAdvanceMarkLevelMap.get((self.advanceTypeID, self.advance), None)
		self._quality = csvAdvance.quality if csvAdvance else 0
		self._display = False

		self._attrs = None
		self._attrs2 = None
		self.calc = Calculator()

		if len(self.skill_level) < len(self.skillList): # skill_level字段初始化
			self.skill_level += [0] * (len(self.skillList) - len(self.skill_level))
			for idx, skillID in enumerate(self.skillList):
				self.skill_level[idx] = self.skills.get(skillID, 0)

		self._initEquips()
		self._initRobotSkill()
		# self._initExp()
		# self._initAttrs()
		attrs = ObjectCard.calcAttrs(self)
		self._attrs, self._attrs2 = self.splitAttrs(attrs)
		self.fighting_point = self.calcFightingPoint(self, attrs)

		return self

	def initTwin(self):
		self._csvCard = csv.cards[self.card_id]
		csvAdvance = self.CardAdvanceMarkLevelMap.get((self.advanceTypeID, self.advance), None)
		self._quality = csvAdvance.quality if csvAdvance else 0
		self._display = False

		self._attrs = None
		self._attrs2 = None
		self.calc = Calculator()
		self._initEquips()
		self._initSkill()
		# self._initExp() # 经验不需要
		# self._initAttrs() # init不进行计算属性，避免陷入onFightingPointChange循环
		attrs = ObjectCard.calcAttrs(self)
		self._attrs, self._attrs2 = self.splitAttrs(attrs)
		self.fighting_point = self.calcFightingPoint(self, attrs)

		return ObjectDBase.init(self)

	def set(self, dic):
		ObjectDBase.set(self, dic)
		self._csvCard = csv.cards[self.card_id]
		self.equipsMap = {}
		for k, _ in self.equips.iteritems():
			v = self.equips[k]  #这样才能把v(dict)放到watch里
			obj = ObjectEquip(self.game, self).set(v)
			self.equipsMap[k] = obj
		self._effortAttrList = []
		self.effortTypeMap = {}

		# 线上数据处理
		if self.abilities:
			abilities = {}
			for k, v in self.abilities.iteritems():
				if k > 10:
					cfg = csv.card_ability[k]
					if not cfg:
						continue
					# if cfg.abilitySeqID != self.abilitySeqID: # 不进行此项判断
					# 	continue
					position = cfg.position
				else:
					position = k
				abilities[position] = max(abilities.get(position, 0), v)
			self.abilities = abilities
		return self

	def _initEquips(self):
		for k, v in self.equipsMap.iteritems():
			v.init()

	def _initSkill(self):
		idS = set(self.skillList)
		if ObjectFeatureUnlockCSV.isOpen(FeatureDefs.ExtremityProperty, self.game):
			idS = set(idS).union(set(self.starSkillList))

		for skillid in self.skills.keys():
			if skillid not in idS:
				logger.warning('card[%d] skill %d level %d not in csv, drop!' % (self.card_id, skillid, self.skills[skillid]))
				self.skills.pop(skillid, None)
		diffIds = idS.difference(self.skills)

		self.addSkill(list(diffIds))
		self._checkSkill()
		self._checkStarSkill()

	def _initRobotSkill(self):
		idS = set(self._csvCard.skillList)
		for skillid in self.skills.keys():
			if skillid not in idS:
				logger.warning('card[%d] skill %d level %d not in csv, drop!' % (self.card_id, skillid, self.skills[skillid]))
				self.skills.pop(skillid, None)
		diffIds = idS.difference(self.skills)
		self.addSkill(list(diffIds))

	def addSkill(self, ids):
		if not isinstance(ids, list):
			ids = [ids]
		for id in ids:
			if id not in csv.skill:
				self.skills.pop(id, None)
				logger.warning('card[%d] skill %d not exited!' % (self.card_id, id))
				continue
			self._addSkill(id)

	def _addSkill(self, skillID):
		if (skillID in self.skills) or (skillID not in csv.skill):
			return

		cfg = csv.skill[skillID]
		active = False
		if cfg.activeType == SkillDefs.starActive: # 星级激活
			if self.star >= cfg.activeCondition:
				active = True
		elif cfg.activeType == SkillDefs.advanceActive: # 突破阶段
			if self.advance >= cfg.activeCondition:
				active = True

		if active:
			self.db['skills'][skillID] = 1
			if skillID in self.skillList:
				idx = self.skillList.index(skillID)
				if self.skill_level[idx] == 0: # 当前位置第一次激活
					self.skill_level[idx] = 1
			# 满星极限技能初始等级 0
			if skillID in self.starSkillList:
				self.db['skills'][skillID] = 0
			# 被动技能属性加成时才需要重新计算属性
			if cfg.skillType == SkillDefs.passiveAttr:
				self.calcPassiveSkillAttrsAddition(self)
				self.onUpdateAttrs()

	def _checkSkill(self):
		# 检查一遍技能等级是否一致
		for idx, skillID in enumerate(self.skillList):
			# 技能可能还没激活，比如两个PVP技能
			if skillID not in self.db['skills']:
				continue
			if self.db['skills'][skillID] != self.skill_level[idx]:
				logger.info("card[%d] skill %d has changed" % (self.card_id, skillID))
				self.db['skills'][skillID] = self.skill_level[idx]

	def _checkStarSkill(self):
		for idx, skillID in enumerate(self.starSkillList):
			# 技能可能还没激活
			if skillID not in self.db['skills']:
				continue
			if self.db['skills'][skillID] != self.star_skill_level[idx]:
				logger.info("card[%d] star skill %d has changed" % (self.card_id, skillID))
				self.db['skills'][skillID] = self.star_skill_level[idx]

	@staticmethod
	def calcUnitAttrsAddition(card):
		csvUnit = csv.unit[card.unitID]
		csvUnitAddition = ObjectCard.CardUnitAdditionMap[card.unitID]
		csvPath = 'csv.base_attribute.%s.base_attribute' % csvUnit.attributeType
		# _baseAttrs 基础属性
		cacheKey = (csvPath, card.level)
		if cacheKey not in ObjectCard.CardLevelBaseAttrsCache:
			# 简单LRU
			if len(ObjectCard.CardLevelBaseAttrsCache) > 100:
				ObjectCard.CardLevelBaseAttrsCache.popitem()
			csvLevel = csv.getCSV(csvPath)
			ObjectCard.CardLevelBaseAttrsCache[cacheKey] = dict2attrs(csvLevel[card.level].to_dict())
		# baseAttrs is zero()
		baseAttrs = copy.copy(ObjectCard.CardLevelBaseAttrsCache[cacheKey])

		# unit 属性修正
		baseAttrs *= csvUnitAddition['cList']
		baseAttrs += csvUnitAddition['growList']*card.level

		card.calc.base.set('unit', baseAttrs)

	@staticmethod
	def calcStarAttrsAddition(card):
		addition = ObjectCard.CardStatAdditionMap.get((card.starTypeID, card.star), None)

		attrs = addition['cList'] + addition['growList'] * card.level
		attrs *= ObjectCard.CardUnitAdditionMap[card.unitID]['basecList']

		card.calc.base.set('star', attrs)

	@staticmethod
	def calcStarEffectAttrsAddition(card):
		key = (card.starEffectIndex, card.star)
		t = ObjectCard.CardStarEffAttrAddMap.get(key, None)
		if t is None:
			const, percent = zeros(), zeros()
			for star in xrange(1, card.star+1):
				cfg = ObjectCard.CardStarEffectMap.get((card.starEffectIndex, star), None)
				if cfg:
					attrNum = cfg.attrNum
					for attr, v in attrNum.iteritems():
						num = str2num_t(v)
						const[attr] += num[0]
						percent[attr] += num[1]
			ObjectCard.CardStarEffAttrAddMap[key] = (const, percent)
		else:
			const, percent = t

		card.calc.const.set('star_effect', const)
		card.calc.percent.set('star_effect', percent)

	@staticmethod
	def calcAdvanceAttrsAddition(card):
		addition = ObjectCard.CardAdvanceMarkLevelAdditionMap.get((card.advanceTypeID, card.advance), None)

		attrs = addition['cList'] + addition['growList'] * card.level
		attrs *= ObjectCard.CardUnitAdditionMap[card.unitID]['basecList']

		card.calc.base.set('advance', attrs)

	@staticmethod
	def calcNValueAttrsAddition(card):
		# csvUnit = csv.unit[card.unitID]
		# csvPath = 'csv.base_attribute.%s.base_attribute' % csvUnit.attributeType
		# cacheKey = (csvPath, card.level)
		# if cacheKey not in ObjectCard.CardNValueConstAttrsRatioCache:
		# 	csvLevel = csv.getCSV(csvPath)
		# 	ratio = {attr: 1.0 / 32 * 0.12 * csvLevel[card.level][attr] for attr in NValueAttrs}
		# 	ObjectCard.CardNValueConstAttrsRatioCache[cacheKey] = ratio
		# ratio = ObjectCard.CardNValueConstAttrsRatioCache[cacheKey]

		# 个体值固定属性
		# d = {attr: (value + 1) * ratio[attr] for attr, value in card.nvalue.iteritems()}
		# card.calc.base.set('nvalue', dict2attrs(d))

		# 个体值百分比加成
		flag = all([card.nvalue.get(attr, 0) == 31 for attr in NValueAttrs])
		d = {}
		for attr, value in card.nvalue.iteritems():
			value = (value + 1) * 1.0 / 32 * 0.32 - 0.16
			if value == 31: # 单项完美
				value += 0.05
			if flag: # 六项全完美
				value += 0.05
			d[attr] = value
		card.calc.nvalue.set('nvalue', dict2attrs(d))

	@staticmethod
	def calcFettersAttrsAddition(card, fetters):
		const = zeros()
		percent = zeros()
		for v in fetters:
			attrVals = ObjectCard.getFetterAttrConfig(v)
			for attr, num in attrVals:
				const[attr] += num[0]
				percent[attr] += num[1]

		card.calc.const.set('fetters', const)
		card.calc.percent.set('fetters', percent)

	@staticmethod
	def calcEffortAttrsAddition(card):
		for attr, value in card.effort_values.iteritems():
			card.effort_values[attr] = value
		const = dict2attrs(card.effort_values)
		card.calc.const.set('effort', const)

	@staticmethod
	def calcEffortAdvanceAttrsAddition(card):
		values = ObjectCard.CardEffortAdvanceMap.get((card.effortSeqID, card.effort_advance), {})
		num = str2num_t(values.get('attrEffect', ''))
		constD = {}
		percentD = {}
		# 6种基础 属性都生效
		for attrType in EffortAttrs:
			constD[attrType] = num[0]
			percentD[attrType] = num[1]
		const = dict2attrs(constD)
		percent = dict2attrs(percentD)
		card.calc.const.set('effort_advance', const)
		card.calc.percent.set('effort_advance', percent)

	@staticmethod
	def calcTalentAttrsAddition(card, talentTree, inFront=False, inBack=False, scene=0):
		const, percent = talentTree.getAttrsAddition(card, inFront, inBack, scene)
		card.calc.const.set('talent', const)
		card.calc.percent.set('talent', percent)

	@staticmethod
	def calcFeelGoodAttrsAddition(card, feels):
		addition = feels.getAttrsAddition(card)
		if addition:
			const, percent = addition
			card.calc.const.set('feel', const)
			card.calc.percent.set('feel', percent)

	@staticmethod
	def calcFeelEffectAttrsAddition(card, feels, inFront=False, inBack=False, scene=0):
		const, percent = feels.getEffectAttrsAddition(card, inFront, inBack, scene)
		card.calc.const.set('feel_effect', const)
		card.calc.percent.set('feel_effect', percent)

	@staticmethod
	def calcZawakeAttrsAddition(card, zawake, scene=0):
		const, percent = zawake.getAttrsAddition(card, scene)
		card.calc.const.set('zawake', const)
		card.calc.percent.set('zawake', percent)

	@staticmethod
	def calcEquipsAttrsAddition(card):
		const = zeros()
		percent = zeros()
		for k, equip in card.equipsMap.iteritems():
			attrVal = equip.getAttrs()
			for attr, num in attrVal.iteritems():
				const[attr] += num[0]
				percent[attr] += num[1]
		card.calc.const.set('equips', const)
		card.calc.percent.set('equips', percent)

	@staticmethod
	def calcHeldItemAttrsAddition(card):
		if card.held_item:
			heldItem = card.game.heldItems.getHeldItem(card.held_item)
			# 基础属性
			const = heldItem.getAttrs()
			card.calc.const.set('heldItems', const)

			# 携带效果
			const, percent = heldItem.getEffect(card.markID)
			card.calc.const.set('heldItems_effect', const)
			card.calc.percent.set('heldItems_effect', percent)
		else:
			card.calc.const.set('heldItems', zeros())
			card.calc.const.set('heldItems_effect', zeros())
			card.calc.percent.set('heldItems_effect', zeros())

	@staticmethod
	def calcPassiveSkillAttrsAddition(card):
		const = zeros()
		percent = zeros()
		passSkills = ObjectCard.getPassiveSkillAttrs(card, card.calc.base.evaluation())
		for skill in passSkills:
			for attr, num in skill.iteritems():
				const[attr] += num[0]
				percent[attr] += num[1]
		card.calc.const.set('passive_skill', const)
		card.calc.percent.set('passive_skill', percent)

	@staticmethod
	def calcSkinAttrsAddition(card):
		const, percent = card.game.role.getCardSkinAttrsAdd(card)
		card.calc.const.set('skin', const)
		card.calc.percent.set('skin', percent)

	@staticmethod
	def calcTrainerAttrsAddition(card, trainer):
		const = trainer.getAttrsAddition()
		card.calc.const.set('trainer', const)

	@staticmethod
	def calcTrainerAttrSkillAddition(card, trainer):
		const, percent = trainer.getAttrSkillAddition()
		card.calc.const.set('trainer_attr_skill', const)
		card.calc.percent.set('trainer_attr_skill', percent)

	@staticmethod
	def calcPokedexAttrsAddition(card, pokedex):
		const, percent = pokedex.getAttrsAddition()
		card.calc.const.set('pokedex', const)
		card.calc.percent.set('pokedex', percent)

	@staticmethod
	def calcPokedexDevelopAttrsAddition(card, pokedex):
		const, percent = pokedex.getDevelopAddition()
		card.calc.const.set('pokedex_develop', const)
		card.calc.percent.set('pokedex_develop', percent)

	@staticmethod
	def calcPokedexAdvanceAttrsAddition(card, pokedex):
		const = zeros()
		percent = zeros()
		pokedexAdvanceAttrAdd = pokedex.getAdvanceAttrsAdd(card)
		for attr, num in pokedexAdvanceAttrAdd.iteritems():
			const[attr] += num[0]
			percent[attr] += num[1]
		card.calc.const.set('pokedex_advance', const)
		card.calc.percent.set('pokedex_advance', percent)

	@staticmethod
	def calcFigureAttrsAddition(card):
		const = zeros()
		percent = zeros()
		figureAttrAdd = card.game.role.getFigureAttrsAdd(card)
		for attr, num in figureAttrAdd.iteritems():
			const[attr] += num[0]
			percent[attr] += num[1]
		card.calc.const.set('figure', const)
		card.calc.percent.set('figure', percent)

	@staticmethod
	def calcTitleAttrsAddition(card):
		const = zeros()
		percent = zeros()
		titleAttrAdd = card.game.role.getTitleAttrsAdd(card)
		for attr, num in titleAttrAdd.iteritems():
			const[attr] += num[0]
			percent[attr] += num[1]
		card.calc.const.set('title', const)
		card.calc.percent.set('title', percent)

	@staticmethod
	def calcUnionSkillAttrsAddition(card, role):
		const, percent = role.getUnionSkillAttrsAdd(card)
		card.calc.const.set('union_skill', const)
		card.calc.percent.set('union_skill', percent)

	@staticmethod
	def calcCharacterAddtsAddition(card):
		if not card.character:
			return
		percent = ObjectCard.CardCharacterPercentMap[card.character]
		card.calc.character.set('character', percent)

	@staticmethod
	def calcExplorerComponentAttrsAddition(card, explorer):
		const, percent = explorer.getComponentStrengthAttrs(card)
		card.calc.const.set('explorer_component', const)
		card.calc.percent.set('explorer_component', percent)

	@staticmethod
	def calcExplorerAttrsAddition(card, explorer):
		const, percent = explorer.getEffectAttrByCard(card)
		card.calc.const.set('explorer_effect', const)
		card.calc.percent.set('explorer_effect', percent)

	@staticmethod
	def calcAbilityAttrsAddition(card, scene=0):
		if card.abilities:
			const, percent = card.getAbilityAttrsAdd(scene)
			card.calc.const.set('ability', const)
			card.calc.percent.set('ability', percent)

	@staticmethod
	def calcGemAttrsAddition(card):
		if card.gems:
			const, percent = card.calGemsAttrsAdd()
			card.calc.const.set('gems', const)
			card.calc.percent.set('gems', percent)
		else:
			card.calc.const.set('gems', zeros())
			card.calc.percent.set('gems', zeros())

	@staticmethod
	def calcChipAttrsAddition(card):
		if card.chip:
			const, percent = card.calChipsAttrsAdd()
			card.calc.const.set('chips', const)
			card.calc.percent.set('chips', percent)
		else:
			card.calc.const.set('chips', zeros())
			card.calc.percent.set('chips', zeros())

	@staticmethod
	def calcFishingLevelAttrsAddition(card, game):
		if game.fishing and ObjectFeatureUnlockCSV.isOpen(FeatureDefs.Fishing, game):
			const, percent = game.fishing.getFishingLevelAttrs()
			card.calc.const.set('fishingLevel', const)
			card.calc.percent.set('fishingLevel', percent)

	@staticmethod
	def calcGymBadgeAttrsAddition(card, game):
		if game.role.badges:
			const, percent = game.badge.getBadgeAttrs()
			card.calc.const.set('badge', const)
			card.calc.percent.set('badge', percent)

	@staticmethod
	def calcEquipSignetAdvanceAttrsAddition(card, scene=0):
		const = zeros()
		percent = zeros()
		for k, equip in card.equipsMap.iteritems():
			const1, percent1 = equip.getSignetAdvanceAttrs(scene)
			const += const1
			percent += percent1
		card.calc.const.set('equip_signet_advance', const)
		card.calc.percent.set('equip_signet_advance', percent)

	@staticmethod
	def calcAttrs(card):
		ObjectCard.calcUnitAttrsAddition(card)
		ObjectCard.calcStarAttrsAddition(card)
		ObjectCard.calcAdvanceAttrsAddition(card)
		# 以上优先计算，技能被动属性需要这些基础值
		ObjectCard.calcNValueAttrsAddition(card)
		ObjectCard.calcCharacterAddtsAddition(card)

		ObjectCard.calcEffortAttrsAddition(card)
		ObjectCard.calcEffortAdvanceAttrsAddition(card)
		ObjectCard.calcEquipsAttrsAddition(card)
		ObjectCard.calcPassiveSkillAttrsAddition(card)
		ObjectCard.calcAbilityAttrsAddition(card)
		ObjectCard.calcEquipSignetAdvanceAttrsAddition(card)
		if card.game:
			ObjectCard.calcFettersAttrsAddition(card, card.fetters)
			ObjectCard.calcTalentAttrsAddition(card, card.game.talentTree)
			ObjectCard.calcSkinAttrsAddition(card)
			ObjectCard.calcTrainerAttrsAddition(card, card.game.trainer)
			ObjectCard.calcTrainerAttrSkillAddition(card, card.game.trainer)
			ObjectCard.calcPokedexAttrsAddition(card, card.game.pokedex)
			ObjectCard.calcPokedexDevelopAttrsAddition(card, card.game.pokedex)
			ObjectCard.calcPokedexAdvanceAttrsAddition(card, card.game.pokedex)
			ObjectCard.calcFeelGoodAttrsAddition(card, card.game.feels)
			ObjectCard.calcFeelEffectAttrsAddition(card, card.game.feels)
			ObjectCard.calcZawakeAttrsAddition(card, card.game.zawake)
			ObjectCard.calcFigureAttrsAddition(card)
			ObjectCard.calcTitleAttrsAddition(card)
			ObjectCard.calcUnionSkillAttrsAddition(card, card.game.role)
			ObjectCard.calcHeldItemAttrsAddition(card)
			ObjectCard.calcStarEffectAttrsAddition(card)
			ObjectCard.calcExplorerComponentAttrsAddition(card, card.game.explorer)
			ObjectCard.calcExplorerAttrsAddition(card, card.game.explorer)
			ObjectCard.calcGemAttrsAddition(card)
			ObjectCard.calcChipAttrsAddition(card)
			ObjectCard.calcFishingLevelAttrsAddition(card, card.game)
			ObjectCard.calcGymBadgeAttrsAddition(card, card.game)

		attrs = card.calc.evaluation()
		return attrs

	@staticmethod
	def calcFightingPoint(card, attrs):
		# 计算战斗力
		cfg = csv.fighting_weight[card.fightingWeight]
		_fightingPoint = card.level * cfg.level
		_rate = 1
		for attr in ObjectCard.FightWeightAttrs:
			val = attrs.get(attr, 0)
			if attr == AttrDefs.strikeDamage:
				val -= 15000
			elif attr == AttrDefs.blockPower:
				val -= 3000
			if val > 0:
				if attr in AttrDefs.fightPointPercents:
					_rate += val * cfg[attr]
				else:
					_fightingPoint += val * cfg[attr]
		_fightingPoint *= _rate
		# 技能
		for skillID, level in card.skills.iteritems():
			if skillID not in csv.skill:
				continue
			_fightingPoint += level * csv.skill[skillID].fightingPoint
		# 基础值
		_fightingPoint += csv.unit[card.unitID].fightingPoint
		return int(_fightingPoint)

	def _setFightingPoint(self, fightingPoint):
		if self.fighting_point != fightingPoint:
			self.fighting_point = fightingPoint
			self.game.cards.onFightingPointChange(self)

	@staticmethod
	def splitAttrs(attrs):
		attrs1 = {}
		attrs2 = {}
		for k, v in attrs.iteritems():
			if k in AttrDefs.primaryAttrs:
				attrs1[k] = v
			else:
				if v > 0:
					attrs2[k] = v
		return attrs1, attrs2

	def _initAttrs(self):
		if self._attrs is None:
			attrs = ObjectCard.calcAttrs(self)
		else:
			attrs = self.calc.evaluation()
		self._attrs, self._attrs2 = self.splitAttrs(attrs)
		if self._display:
			self.db_attrs = self._attrs
		_fightingPoint = self.calcFightingPoint(self, attrs)
		self._setFightingPoint(_fightingPoint)

	def _initExp(self):
		seq = 'levelExp%d' % self._csvCard.levelExpID
		self._nextLevelExp = csv.base_attribute.card_level[self.level][seq]

	@property
	def mem(self):
		return {
			'attrs': self._attrs, # key是属性CSV列表名
			'attrs2': self._attrs2,
			'unit_id': self.unitID,
			'next_level_exp': self._nextLevelExp,
			'fetters': self.fetters,
		}

	def calcBattleAttrs(self, inFront, inBack, scene):
		# 调整天赋, 好感度, 特性, 饰品刻印突破 场景加成，计算完之后恢复
		with temporary(self.calc, 'talent', 'feel_effect', 'ability', 'equip_signet_advance'):
			self.calcAbilityAttrsAddition(self, scene)
			if self.game:
				self.calcTalentAttrsAddition(self, self.game.talentTree, inFront, inBack, scene)
				self.calcFeelEffectAttrsAddition(self, self.game.feels, inFront, inBack, scene)
				self.calcEquipSignetAdvanceAttrsAddition(self, scene)
				self.calcZawakeAttrsAddition(self, self.game.zawake, scene)
			attrs = self.calc.evaluation()
		return attrs

	def calcFilterAttrs(self, disables, inFront=False, inBack=False, scene=0):
		nodes = {
			'unit': [self.calc.base],
			'star': [self.calc.base, ],
			'advance': [self.calc.base, ],
			'nvalue': [self.calc.nvalue],
			'character': [self.calc.character, ],

			'fetters': [self.calc.percent, self.calc.const],
			'effort': [self.calc.const, ],
			'effort_advance': [self.calc.percent, self.calc.const],
			'feel': [self.calc.percent, self.calc.const],
			'feel_effect': [self.calc.percent, self.calc.const],
			'equips': [self.calc.percent, self.calc.const],
			'passive_skill': [self.calc.percent, self.calc.const],
			'talent': [self.calc.percent, self.calc.const],
			'trainer': [self.calc.const, ],
			'trainer_attr_skill': [self.calc.percent, self.calc.const],
			'pokedex': [self.calc.percent, self.calc.const],
			'pokedex_advance': [self.calc.percent, self.calc.const],
			'pokedex_develop': [self.calc.percent, self.calc.const],
			'skin': [self.calc.percent, self.calc.const],
			'figure': [self.calc.percent, self.calc.const],
			'title': [self.calc.percent, self.calc.const],
			'union_skill': [self.calc.percent, self.calc.const],
			'heldItems': [self.calc.const, ],
			'heldItems_effect': [self.calc.percent, self.calc.const],
			'explorer_component': [self.calc.percent, self.calc.const],
			'explorer_effect': [self.calc.percent, self.calc.const],
			'star_effect': [self.calc.percent, self.calc.const],
			'ability': [self.calc.percent, self.calc.const],
			'gems': [self.calc.percent, self.calc.const],
			'chips': [self.calc.percent, self.calc.const],
		}
		# 去除disables里的加成，计算完毕之后恢复
		stash = [] # (key, node, value)
		for key in disables:
			for node in nodes[key]:
				stash.append((key, node, node.peek(key)))
				if key == 'character':
					node.set(key, ones())
				else:
					node.set(key, zeros())
		attrs = self.calc.evaluation()
		display = self.calc.to_dict()

		# recover
		for key, node, value in stash:
			node.set(key, value)

		attrs, attrs2 = self.splitAttrs(attrs)
		attrs.update(attrs2)
		return attrs, display

	def battleModel(self, inFront, inBack, scene, **kwargs):
		attrs = self.calcBattleAttrs(inFront, inBack, scene)
		attrs, attrs2 = self.splitAttrs(attrs)

		passive_skills = {}
		if self.game:
			# 特殊效果被动技能(携带道具，探险器, 特性, 形象)
			if self.held_item:
				heldItem = self.game.heldItems.getHeldItem(self.held_item)
				skills = heldItem.getPassiveSkills(self.markID)
				passive_skills.update(skills)
			skills = self.game.explorer.getPassiveSkills()
			passive_skills.update(skills)
			abilitySkills = self.getAbilitySkills()
			passive_skills.update(abilitySkills)
			figureSkills = self.game.role.getFigureAbilitySkills()
			passive_skills.update(figureSkills)
			zawakeSkills = self.game.zawake.getPassiveSkills(self.id)
			passive_skills.update(zawakeSkills)
			chipSkills = self.game.chips.getPassiveSkills(self.id)
			passive_skills.update(chipSkills)
			if scene == SceneDefs.Gym:
				gymTalentSkills = self.game.gymTalentTree.getPassiveSkills()
				passive_skills.update(gymTalentSkills)
		else:
			explorer = kwargs.get('explorer', None) # 实时匹配会外部传入 FakeExplorer
			if explorer:
				passive_skills.update(explorer.getPassiveSkills())

		star_effect = -1 # -1：功能未开放；0-离线数据；>0：功能开放
		if self.game:
			if ObjectFeatureUnlockCSV.isOpen(FeatureDefs.StarEffect, self.game):
				star_effect = self.star

		nature_choose = kwargs.get('nature_choose', 1)

		ret = {
			'id': self.id,
			'card_id': self.card_id,
			'skin_id': self.skin_id,
			'level': self.level,
			'attrs': attrs,
			'attrs2': attrs2,
			'skills': self.skills,
			'fighting_point': self.fighting_point,
			'star': self.star,
			'advance': self.advance,
			'passive_skills': passive_skills,
			'star_effect': star_effect,
			'nature_choose': nature_choose,
		}

		if self.game and scene == SceneDefs.Arena:
			fightingPoint2 = self.calcFightingPoint2()
			ret.update({'fighting_point2': fightingPoint2})

		return ret

	def calcFightingPoint2(self):
		baseCfg = csv.cross.hunting.base[1]
		rarityC = baseCfg.rarityC[self.rarity]
		heldItemC = 1
		if self.held_item:
			heldItem = self.game.heldItems.getHeldItem(self.held_item)
			heldItemC = baseCfg.rarityC[csv.held_item.items[heldItem.held_item_id].quality]
		zawakeC = 1
		zawake = self.game.role.zawake.get(csv.cards[self.card_id].zawakeID, {})
		maxStage = 0
		for stage, level in zawake.iteritems():
			maxStage = max(maxStage, stage)
		zawakeC = baseCfg.zawakeC.get(maxStage, 1)
		fightingPoint2 = int(self.fighting_point * rarityC * heldItemC * zawakeC)
		return fightingPoint2

	# deprecated
	@property
	def pwModel(self):
		logger.warning('pwModel is deprecated, use battleModel')
		return self.battleModel(False, False, 0)

	@property
	def attrs(self):
		return CardAttrs(self._attrs)

	def display(self):
		if not self._display:
			self.db_attrs = self._attrs
			self._display = True

	db_attrs = db_property('db_attrs')

	@property
	def fightgo_val(self):
		return self._attrs['speed']

	@property
	def csvAttrs(self):
		return self._attrs

	@property
	def markID(self):
		return self._csvCard.cardMarkID

	@property
	def zawakeID(self):
		return self._csvCard.zawakeID

	@property
	def branch(self):
		return self._csvCard.branch

	@property
	def feelType(self):
		return self._csvCard.feelType

	@property
	def unitID(self):
		return self._csvCard.unitID

	@property
	def levelMax(self):
		return min(self._csvCard.levelMax, self.game.role.cardLevelMax)

	@property
	def natureType(self):
		return csv.unit[self.unitID].natureType

	@property
	def natureType2(self):
		return csv.unit[self.unitID].natureType2

	# 双属性标记
	@property
	def twinFlag(self):
		return csv.unit[self.unitID].twinFlag

	@property
	def fightingWeight(self):
		return self._csvCard.fightingWeight

	@property
	def rarity(self):
		return csv.unit[self.unitID].rarity

	@property
	def starTypeID(self):
		return self._csvCard.starTypeID

	@property
	def starEffectIndex(self):
		return self._csvCard.starEffectIndex

	@property
	def advanceTypeID(self):
		return self._csvCard.advanceTypeID

	@property
	def abilitySeqID(self):
		return self._csvCard.abilitySeqID

	@property
	def gemPosSeqID(self):
		return self._csvCard.gemPosSeqID

	@property
	def effortSeqID(self):
		return self._csvCard.effortSeqID

	@property
	def gemQualitySeqID(self):
		return self._csvCard.gemQualitySeqID

	@property
	def starSkillSeqID(self):
		return self._csvCard.starSkillSeqID

	@property
	def starSkillMaxLevel(self):
		return self._csvCard.starSkillMaxLevel

	@property
	def skillList(self):
		if self.skin_id and self.skin_id in self._csvCard.skinSkillMap:
			return self._csvCard.skinSkillMap[self.skin_id]
		else:
			return self._csvCard.skillList

	@property
	def starSkillList(self):
		return csv.card_star_skill[self.starSkillSeqID].starSkillList

	@property
	def isMega(self):
		return self._csvCard.megaIndex != 0

	@classmethod
	def getStarFragCfg(cls, type, star):
		return cls.CardStar2FragMap.get((type, star), None)

	# 卡牌CSV ID
	def card_id():
		dbkey = 'card_id'
		def fset(self, value):
			self.db[dbkey] = value
		return locals()
	card_id = db_property(**card_id())

	# 卡牌皮肤id
	def skin_id():
		dbkey = 'skin_id'
		def fset(self, value):
			old = self.db[dbkey]
			self.db[dbkey] = value
			if old != value:
				self.game.cards.updateCardSkills(self, old)
				self.game.cards.onSkinIDChange(self)
		return locals()
	skin_id = db_property(**skin_id())

	# 卡牌等级
	def level():
		dbkey = 'level'
		def fset(self, value):
			old = self.db[dbkey]
			value = min(value, self.levelMax)
			oldFightingPoint = self.fighting_point
			self.db[dbkey] = value
			self.calcUnitAttrsAddition(self)
			self.calcStarAttrsAddition(self)
			self.calcAdvanceAttrsAddition(self)
			self.calcNValueAttrsAddition(self)
			self.onUpdateAttrs()
			if self.game.role.daily_record_db_id:
				self.game.dailyRecord.level_up += max(0, value - old)
			ObjectYYHuoDongFactory.onGeneralTask(self.game, TargetDefs.CardLevelUp, max(0, value - old))

		return locals()
	level = db_property(**level())

	# 卡牌当前获得的总经验
	def exp():
		dbkey = 'sum_exp'
		def fset(self, value):
			old = self.exp
			inc = value - old
			if inc == 0:
				return

			seq = 'levelExp%d' % self._csvCard.levelExpID
			levelSeq = self.CardsLevelSeq[self._csvCard.levelExpID]

			if inc <= 0:
				self.level = 1
			while self.level < self.levelMax and value >= levelSeq[self.level]:
				self.level += 1

			value = min(value, levelSeq[self.level])
			self._nextLevelExp = csv.base_attribute.card_level[self.level][seq]
			self.db['level_exp'] = value - levelSeq[self.level - 1]
			self.db[dbkey] = value
			self.game.cards.deploymentForUnionTraining.put(self.id)
		return locals()
	exp = db_property(**exp())

	# 当前等级下卡牌积累的经验
	def level_exp():
		dbkey = 'level_exp'
		return locals()
	level_exp = db_property(**level_exp())

	# card集满下一等级经验时，role等级提高，自动提高card等级
	def autoUpLevel(self):
		if self._nextLevelExp <= self.level_exp:
			levelSeq = self.CardsLevelSeq[self._csvCard.levelExpID]
			oldFightingPoint = self.fighting_point
			self.level += 1
			addFightingPoint = self.fighting_point - oldFightingPoint
			self.level_exp = min(self.exp, levelSeq[self.level]) - levelSeq[self.level - 1]
			seq = 'levelExp%d' % self._csvCard.levelExpID
			self._nextLevelExp = csv.base_attribute.card_level[self.level][seq]

	# 满足等级自动开启技能
	def autoOpenStarSkill(self):
		if not ObjectFeatureUnlockCSV.isOpen(FeatureDefs.ExtremityProperty, self.game):
			return
		self.addSkill(list(self.starSkillList))
		self._checkSkill()
		self._checkStarSkill()

	# 激活的卡牌技能CardSkill.id列表 {skill_id:level}
	def skills():
		dbkey = 'skills'
		def fset(self, value):
			self.db[dbkey] = value
		return locals()
	skills = db_property(**skills())

	# 激活的z觉醒技能数组
	zawake_skills = db_property('zawake_skills')

	star_skill_level = db_property('star_skill_level')

	skill_level = db_property('skill_level')

	def getSkill(self, skillID):
		return self.db['skills'].get(skillID, 0)

	def updateSkill(self, skillID, addLevel):
		old = self.db['skills'][skillID]
		level = old + addLevel

		cfg = csv.skill[skillID]
		costID = cfg.costID
		level = min(level, max(csv.base_attribute.skill_level.iterkeys()))
		skillIdx = self.skillList.index(skillID)
		goldField = 'gold%d' % costID
		itemField = 'itemMap%d' % costID
		sumGold = 0
		for i in xrange(old, level):
			costCfg = csv.base_attribute.skill_level[i]
			costGold, costItemMap = costCfg[goldField], costCfg[itemField]
			if self.level >= costCfg.needLevel:
				if self.game.role.skill_point > 0:
					cost = ObjectCostAux(self.game, costItemMap)
					cost.gold += costGold
					sumGold += costGold
					if not cost.isEnough():
						raise ClientError("cost item or gold not enough")
					cost.cost(src='card_updateSkill')
				else:
					raise ClientError(ErrDefs.skillPointNotEnough)
			else:
				raise ClientError(ErrDefs.skillLevelLevelNotEnough)

			self.game.role.skill_point -= 1
			self.skill_level[skillIdx] = i + 1
			self.db['skills'][skillID] = self.skill_level[skillIdx]
			# record
			self.game.dailyRecord.skill_up += 1

		# 被动技能属性加成时才需要重新计算属性
		if cfg.skillType == SkillDefs.passiveAttr:
			self.calcPassiveSkillAttrsAddition(self)
		self.onUpdateAttrs()

		ObjectYYHuoDongFactory.onGeneralTask(self.game, TargetDefs.CardSkillUp, addLevel)

		return self.db['skills'][skillID]

	def updateStarSkill(self, skillID, addLevel):
		if self.star < 12:
			raise ClientError('card star not enough')

		old = self.db['skills'][skillID]
		level = old + addLevel

		cfg = csv.skill[skillID]
		costID = cfg.costID
		level = min(level, self.starSkillMaxLevel)
		starSkillIdx = self.starSkillList.index(skillID)
		itemField = 'itemNum%d' % costID
		oldFightingPoint = self.fighting_point
		costPointsNum = 0
		markID = self.markID
		for i in xrange(old, level):
			costCfg = csv.base_attribute.skill_level[i]
			costItemNum = costCfg[itemField]
			costPointsNum += costItemNum
			cost = ObjectCostAux(self.game, {'star_skill_points': {markID: costItemNum}})
			if not cost.isEnough():
				raise ClientError(ErrDefs.starSkillPointNotEnough)
			cost.cost(src="card_updateStarSkill")
			self.star_skill_level[starSkillIdx] = i + 1
			self.db['skills'][skillID] = self.star_skill_level[starSkillIdx]

		# 被动技能属性加成时才需要重新计算属性
		if cfg.skillType == SkillDefs.passiveAttr:
			self.calcPassiveSkillAttrsAddition(self)
		self.onUpdateAttrs()

		ta.card(self, event='card_star_level_up',oldFightingPoint=oldFightingPoint,skillID=skillID,level=self.db['skills'][skillID],costNum=costPointsNum)
		return self.db['skills'][skillID]

	@staticmethod
	def getPassiveSkillAttrs(card, attrs=None):
		def _new(skillID):
			if skillID not in ObjectCard.SkillPassiveAttrsCache:
				return None
			ret, level = {}, card.skills[skillID]
			for attr, t in ObjectCard.SkillPassiveAttrsCache[skillID].iteritems():
				f1, f2 = t
				try:
					# 支持公式计算
					param = (f1(level, lambda x: attrs[x]) if f1 else 0, f2(level) / 100.0 if f2 else 0)
				except Exception:
					logger.exception('passive skill eval error')
					param = (0, 0)
				ret[attr] = param
			return ret

		return filter(None, map(_new, card.skills))

	# 装备槽ID列表
	def equips():
		dbkey = 'equips'
		def fset(self, value):
			self.db[dbkey] = value
		return locals()
	equips = db_property(**equips())

	def onUpgradeEquip(self):
		'''
		卡牌的装备升级
		'''
		self.calcEquipsAttrsAddition(self)
		self.calcEquipSignetAdvanceAttrsAddition(self)
		self.onUpdateAttrs()

	def onUpdateFetters(self):
		self.calcFettersAttrsAddition(self, self.fetters)
		self.onUpdateAttrs()

	def countAdvanceEquips(self, advance):
		ret = 0
		for _, obj in self.equipsMap.iteritems():
			if obj.advance >= advance:
				ret += 1
		return ret

	def countStarEquips(self, star):
		ret = 0
		for _, obj in self.equipsMap.iteritems():
			if obj.star >= star:
				ret += 1
		return ret

	def countAwakeEquips(self, awake):
		ret = 0
		for _, obj in self.equipsMap.iteritems():
			if obj.awake >= awake:
				ret += 1
		return ret

	def equipAdvance(self,pos):
		equipObj = self.equipsMap[pos]
		if equipObj is None:
			raise ClientError("equip pos is error:pos %d"%pos)
		equipObj.advanceBy(1)
		self.onUpgradeEquip()

	def equipStrength(self,pos,count):
		equipObj = self.equipsMap[pos]
		if equipObj is None:
			raise ClientError("equip pos is error:pos %d"%pos)
		equipObj.strengthBy(count)
		self.onUpgradeEquip()

	def equipStrengthByExp(self,pos,costItemIDs):
		equipObj = self.equipsMap[pos]
		if equipObj is None:
			raise ClientError("equip pos is error:pos %d"%pos)
		if (equipObj.level + 1) > equipObj.strengthMax:
			raise ClientError(ErrDefs.strengthMaxErr)
		equipObj.strengthByExp(costItemIDs)

	def equipOneKeyStrengthByExp(self,pos,costItemIDs,targetLevel):
		equipObj = self.equipsMap[pos]
		if equipObj is None:
			raise ClientError("equip pos is error:pos %d"%pos)
		if targetLevel < equipObj.level:
			raise ClientError("equip targetLevel is error: %d"%targetLevel)
		equipObj.strengthByExp(costItemIDs)
		for x in xrange(50): #预留50够了 总共100级 每次进阶至少也要5级 一般20多也够,预防while死循环
			if equipObj.level < equipObj.strengthMax:
				break
			if equipObj.level >= targetLevel:
				break
			equipObj.advanceBy(1)
		self.onUpgradeEquip()

	def equipOneKeyStrength(self,pos,targetLevel):
		equipObj = self.equipsMap[pos]
		if equipObj is None:
			raise ClientError("equip pos is error:pos %d"%pos)
		if targetLevel <= equipObj.level:
			raise ClientError("equip targetLevel is error: %d"%targetLevel)
		for x in xrange(50): #预留50够了 总共100级 每次进阶至少也要5级 一般20多也够,预防while死循环
			if equipObj.level < equipObj.strengthMax:
				equipObj.strengthBy(targetLevel-equipObj.level)
			if equipObj.level >= targetLevel or equipObj.level < equipObj.strengthMax:
				break
			equipObj.advanceBy(1)
		self.onUpgradeEquip()

	def equipRaiseStar(self,pos):
		equipObj = self.equipsMap[pos]
		if equipObj is None:
			raise ClientError("equip pos is error:pos %d"%pos)
		equipObj.raiseStarBy(1)
		self.onUpgradeEquip()

	def equipDropStar(self,pos):
		equipObj = self.equipsMap[pos]
		if equipObj is None:
			raise ClientError("equip pos is error:pos %d"%pos)
		equipObj.dropStar()
		self.onUpgradeEquip()

	def equipAwake(self, pos):
		equipObj = self.equipsMap[pos]
		if equipObj is None:
			raise ClientError("equip pos is error:pos %d"%pos)
		equipObj.onEquipAwake()
		self.onUpgradeEquip()

	def equipDropAwake(self, pos):
		equipObj = self.equipsMap[pos]
		if equipObj is None:
			raise ClientError("equip pos is error:pos %d"%pos)
		equipObj.dropAwake()
		self.onUpgradeEquip()

	def equipRaiseAbility(self, pos, level):
		equipObj = self.equipsMap[pos]
		if equipObj is None:
			raise ClientError("equip pos is error:pos %d"%pos)
		equipObj.onEquipAbility(level)
		self.onUpgradeEquip()

	def equipRaiseSignet(self, pos):
		equipObj = self.equipsMap[pos]
		if equipObj is None:
			raise ClientError("equip pos is error:pos %d"%pos)
		equipObj.onEquipSignetStrength()
		self.onUpgradeEquip()

	def equipSignetAdvance(self, pos):
		equipObj = self.equipsMap[pos]
		if equipObj is None:
			raise ClientError("equip pos is error:pos %d"%pos)
		notEnough = equipObj.onEquipSignetAdvance()
		if notEnough:
			raise ClientError('signet advance items not enough')
		self.onUpgradeEquip()

	def equipOneKeySignet(self, pos, targetLevel, advanceLevel):
		equipObj = self.equipsMap[pos]
		if equipObj is None:
			raise ClientError("equip pos %d is error" % pos)
		if targetLevel <= equipObj.signet and advanceLevel <= equipObj.signetAdvance:
			raise ClientError("onekey target level error")

		notEnough = False
		for x in xrange(50):
			if equipObj.signet < equipObj.signetStrengthMax:
				level = equipObj.signetStrengthMax if equipObj.signetStrengthMax <= targetLevel else targetLevel
				equipObj.onEquipSignetStrength(level - equipObj.signet)

			if equipObj.signet < equipObj.signetStrengthMax:
				break

			# 到达可突破等级且低于目标突破等级
			if equipObj.signet == equipObj.signetStrengthMax and equipObj.signetAdvance < advanceLevel:
				notEnough = equipObj.onEquipSignetAdvance()

			# 达到目标等级 or 小于当前进阶阶段最大等级 or 消耗材料不足
			if (equipObj.signet >= targetLevel and equipObj.signetAdvance >= advanceLevel) or notEnough:
				break
		self.onUpgradeEquip()

	def equipDropSignet(self, pos):
		equipObj = self.equipsMap[pos]
		if equipObj is None:
			raise ClientError("equip pos is error:pos %d"%pos)
		equipObj.dropSignet()
		self.onUpgradeEquip()

	def equipRaiseAwakeAbility(self, pos, level):
		equipObj = self.equipsMap[pos]
		if equipObj is None:
			raise ClientError("equip pos is error:pos %d"%pos)
		equipObj.onEquipAwakeAbility(level)
		self.onUpgradeEquip()

	def onUpdateAttrs(self):
		self._initAttrs() # re-calcuate attrs and fighting_point

	# 卡牌星级
	def star():
		dbkey = 'star'
		def fset(self, value):
			self.db[dbkey] = value
		return locals()
	star = db_property(**star())

	# 升星消耗的万能整卡数量
	cost_universal_cards = db_property('cost_universal_cards')

	def riseStar(self, costCards):
		'''
		卡牌升星
		'''
		csvStar = self.CardsMarkStarMap.get((self.starTypeID, self.star), None)
		if csvStar is None:
			raise ClientError(ErrDefs.cardStarMaxErr)

		nextStarcsv = self.CardsMarkStarMap.get((self.starTypeID, self.star+1), None)
		if nextStarcsv is None:
			raise ClientError(ErrDefs.cardStarMaxErr)

		if len(costCards) != csvStar.costCardNum:
			raise ClientError('costCards num error')
		costAux = ObjectCostAux(self.game, {'gold': csvStar.gold})
		costAux += ObjectCostAux(self.game, csvStar.costItems)
		costAux.setCostCards(costCards)
		if costAux.isEnough():
			# 如果消耗卡牌有携带道具需 卸下
			for costCard in costCards:
				if costCard.held_item:
					heldItem = self.game.heldItems.getHeldItem(costCard.held_item)
					if heldItem:
						heldItem.card_db_id = None
						costCard.held_item = None
				# 记录 已消耗的万能整卡数量
				if costCard.card_id in csvStar.universalCards:
					self.cost_universal_cards[costCard.card_id] = self.cost_universal_cards.get(costCard.card_id, 0) + 1
			costAux.cost(src='card_star')
		else:
			raise ClientError(ErrDefs.costNotEnough)
		oldFightingPoint = self.fighting_point
		self.star += 1
		self.game.role.card_star_times += 1

		cfg = self.CardStarEffectMap.get((self.starEffectIndex, self.star), None)
		if cfg:
			self.calcStarEffectAttrsAddition(self)

		self._initSkill()
		self.calcStarAttrsAddition(self)
		self.onUpdateAttrs()

		self.game.cards.onCardsStarChange({self.markID: self.star})
		addFightingPoint = self.fighting_point - oldFightingPoint
		ta.card(self, event='card_star_up',addFightingPoint=addFightingPoint)

		ObjectMessageGlobal.newsCardStarMsg(self.game.role, self)
		ObjectMessageGlobal.marqueeBroadcast(self.game.role, MessageDefs.MqCardStar, card=self)
		ObjectYYHuoDongFactory.onGeneralTask(self.game, TargetDefs.CardStarCount, 1)
		ObjectYYHuoDongFactory.onGeneralTask(self.game, TargetDefs.CardStar, 1)
		self.game.cards.deploymentForUnionTraining.put(self.id)
		return self.star

	# 进阶级数
	def advance():
		dbkey = 'advance'
		def fset(self, value):
			self.db[dbkey] = value
		return locals()
	advance = db_property(**advance())

	# 卡牌进化
	def develop():
		dbkey = 'develop'
		def fset(self, value):
			self.db[dbkey] = value
		return locals()
	develop = db_property(**develop())

	# 前置进化卡牌
	def beforeCardIDs(self):
		cardIDs = []
		branch = self._csvCard.branch
		for develop in xrange(self.develop, 0, -1):
			cardID = self.CardMarkDevelopMap.get((self.markID, branch, develop), None)
			if not cardID:
				cardID = self.CardMarkDevelopMap.get((self.markID, 0, develop), None)
			if cardID:
				cardIDs.append(cardID)
		return cardIDs

	def riseDevelop(self, branch):
		'''
		进化
		'''
		newCsvCard, nextDevelop, nextCardID = self.getDevelopNext(branch)
		megaIndex = newCsvCard.megaIndex
		if megaIndex:
			raise ClientError('next develop is mega')

		cfg = csv.base_attribute.develop_level[nextCardID]
		if self.level < cfg.needLevel:
			raise ClientError(ErrDefs.cardDevelopLevelUp)
		if self.star < cfg.needStar:
			raise ClientError(ErrDefs.cardDevelopStarUp)
		if self.advance < cfg.needAdvance:
			raise ClientError('advance limit')

		costAux = ObjectCostAux(self.game, cfg.cost)
		if costAux.isEnough():
			costAux.cost(src='card_develop')
		else:
			raise ClientError(ErrDefs.costNotEnough)

		self.developNextChange(newCsvCard, nextDevelop, nextCardID)

	def getDevelopNext(self, branch):
		'''
		进化下一个形态
		'''
		if branch is None:
			branch = self.branch  # 当前分支进化
		else:
			if self.branch > 0 and self.branch != branch:
				raise ClientError('already choose branch')

		nextDevelop = 1
		nextCardID = None
		newCsvCard = None
		for i in xrange(self.develop + 1, 99):
			nextDevelop = i
			nextCardID = self.CardMarkDevelopMap.get((self.markID, branch, nextDevelop), None)
			if nextCardID is None:
				raise ClientError(ErrDefs.cardDevelopLimit)
			newCsvCard = csv.cards[nextCardID]
			if newCsvCard.canDevelop:
				break
		return newCsvCard, nextDevelop, nextCardID

	def developNextChange(self, newCsvCard, nextDevelop, nextCardID):
		'''
		进化后卡牌继承和改变
		'''
		# 技能
		newSkills = {}

		if self.skin_id in newCsvCard.skinSkillMap:
			newSkillList = newCsvCard.skinSkillMap[self.skin_id]
		else:
			if self.skin_id != 0:
				self.skin_id = 0
			newSkillList = newCsvCard.skillList

		if self.skin_id:
			oldSkillList = self._csvCard.skinSkillMap[self.skin_id]
		else:
			oldSkillList = self._csvCard.skillList

		for k, newSkillID in enumerate(newSkillList):
			oldSkillID = oldSkillList[k]
			skillLevel = self.skills.get(oldSkillID, None)
			if skillLevel is not None:
				newSkills[newSkillID] = skillLevel

		for k, newSkillID in enumerate(csv.card_star_skill[newCsvCard.starSkillSeqID].starSkillList):
			oldSkillID = self.starSkillList[k]
			skillLevel = self.skills.get(oldSkillID, None)
			if skillLevel is not None:
				newSkills[newSkillID] = skillLevel

		self.skills = newSkills
		self.develop = nextDevelop
		self.card_id = nextCardID
		self.init()

	def riseDevelopMega(self, branch, costCards):
		'''
		超进化
		'''
		newCsvCard, nextDevelop, nextCardID = self.getDevelopNext(branch)

		megaIndex = newCsvCard.megaIndex
		if not megaIndex:
			raise ClientError('can not develop mega')
		megaCfg = csv.card_mega[megaIndex]
		# 是否满足条件
		key, value = megaCfg.condition
		if key == MegaDefs.RoleLevel:
			if self.game.role.level < value:
				raise ClientError('can not condition (role.level)')
		elif key == MegaDefs.CardLevel:
			if self.level < value:
				raise ClientError('can not condition (card.level)')
		# 本体精灵 是否满足条件
		if megaCfg.card[0] != self.card_id:
			raise ClientError('cardID value error')
		if self.star < megaCfg.card[1]:
			raise ClientError('card star not enough')
		# 消耗
		costAux = ObjectCostAux(self.game, megaCfg.costItems)
		# 消耗卡牌 是否满足条件
		if megaCfg.costCards:
			markID = megaCfg.costCards.get('markID', None)
			rarity = megaCfg.costCards.get('rarity', None)
			star = megaCfg.costCards.get('star', None)
			needNum = megaCfg.costCards.get('num', 0)
			num = 0
			for costCard in costCards:
				if rarity and costCard.rarity != rarity:  # 稀有度
					raise ClientError('costCards error rarity')
				if markID and costCard.markID != markID:  # markID
					raise ClientError('costCards error markID')
				if star and costCard.star < star:  # star
					raise ClientError('costCards error star')
				num = num + 1
			if num != needNum:
				raise ClientError('costCards error len')
			costAux.setCostCards(costCards)
		if not costAux.isEnough():
			raise ClientError(ErrDefs.costNotEnough)
		costAux.cost(src='card_develop_mega')

		self.developNextChange(newCsvCard, nextDevelop, nextCardID)

	def switchBranch(self, branch):
		if self.branch == branch:
			raise ClientError('already in branch')
		nextCardID = self.CardMarkDevelopMap.get((self.markID, branch, self.develop), None)
		if nextCardID is None:
			raise ClientError(ErrDefs.cardDevelopLimit)
		cfg = csv.cards[nextCardID]
		if not cfg.canDevelop:
			raise ClientError(ErrDefs.cardDevelopLimit)
		if cfg.developType not in self.CardSwitchBranchCostMap:
			raise ClientError('developType error')
		costs = self.getSwitchBranchCost(cfg)
		costAux = ObjectCostAux(self.game, costs)
		if costAux.isEnough():
			costAux.cost(src='card_switch_branch')
		else:
			raise ClientError(ErrDefs.costNotEnough)

		self.branch_switch_times += 1
		self.developNextChange(cfg, self.develop, nextCardID)

	# 分支/形态切换次数
	branch_switch_times = db_property("branch_switch_times")

	def getSwitchBranchCost(self, cfg):
		lst = self.CardSwitchBranchCostMap[cfg.developType]
		maxT = min(len(lst) - 1, self.branch_switch_times)
		return lst[maxT]

	#卡牌战斗力
	def fighting_point():
		dbkey = 'fighting_point'
		def fset(self, value):
			self.db[dbkey] = value
		return locals()
	fighting_point = db_property(**fighting_point())

	@classmethod
	def getFetterAttrConfig(cls, fetterID):
		t = cls.CardFetterAttrMap.get(fetterID, None)
		if t is None:
			attrMap = csv.fetter[fetterID].attrMap
			t = []
			for attrType, attrNum in attrMap.iteritems():
				num = str2num_t(attrNum)
				t.append((attrType, num))
			cls.CardFetterAttrMap[fetterID] = t
		return t

	#卡牌激活的羁绊
	@property
	def fetters(self):
		return list(self.game.pokedex.allfetters & set(self._csvCard.fetterList))

	# 卡牌品质
	@property
	def quality(self):
		return self._quality

	# 卡牌进阶等级限制
	@property
	def advanceLevelReq(self):
		return self._csvCard.advanceLevelReq[self.advance-1]

	AdvanceErrMap = {
		ObjectCostAux.LackGold: ErrDefs.advanceGoldNotEnough,
		ObjectCostAux.LackItems: ErrDefs.advanceItemsNotEnough,
		ObjectCostAux.LackFrags: ErrDefs.advanceFragsNotEnough,
		ObjectCostAux.LackRMB: ErrDefs.advanceRMBNotEnough,
	}

	def cardAdvance(self, count=1):
		'''
		卡牌进阶
		@param count: 进阶次数
		@exception:
		'''
		if count <= 0:
			return self.advance

		oldFightingPoint = self.fighting_point
		for i in xrange(count):
			if self.level < self.advanceLevelReq:
				raise ClientError(ErrDefs.advanceLevelNotEnough)

			if self.advance + 1 > self._csvCard.advanceMax:
				raise ClientError(ErrDefs.advanceMaxErr)
			csvAdvance = self.CardAdvanceMarkLevelMap.get((self.advanceTypeID, self.advance), None)
			if csvAdvance is None:
				raise ServerError('advance_level csv typeID %d advance %d not exited!' % (self.advanceTypeID, self.advance))

			costD = copy.deepcopy(csvAdvance.itemMap)
			costD.update(gold=csvAdvance.gold)
			costAux = ObjectCostAux(self.game, costD)
			if costAux.isEnough():
				costAux.cost(src='card_advance')
			else:
				raise ClientError(ObjectCard.AdvanceErrMap[costAux.lack])

			self.advance += 1
			# record
			self.game.role.card_advance_times += 1
			self.game.dailyRecord.card_advance_times += 1

		self.calcAdvanceAttrsAddition(self)
		self.onUpdateAttrs()
		addFightingPoint = self.fighting_point - oldFightingPoint
		ta.card(self, event='card_advance_up',addFightingPoint=addFightingPoint,addAdvance=count)

		ObjectMessageGlobal.newsCardAdvanceMsg(self.game.role, self)
		ObjectYYHuoDongFactory.onGeneralTask(self.game, TargetDefs.CardAdvanceCount, count)
		ObjectYYHuoDongFactory.onGeneralTask(self.game, TargetDefs.CardAdvance, count)
		self.game.cards.deploymentForUnionTraining.put(self.id)
		return self.advance

	def nvalueMinimumActive(self, cfg):
		# 1. 判断生效间隔内是否已经生效
		if self.nvalue_locknum_recast_process >= self.nvalue_locknum_recast_total / cfg.probEffectInterval + 1:
			return False
		# 2. 保底次数激活
		if self.nvalue_locknum_recast_total % cfg.probEffectInterval + 1 >= cfg.probMiniTimes:
			return True
		# 2. 保底概率激活
		prob = cfg.probInit + cfg.probStep * (self.nvalue_locknum_recast_total % cfg.probEffectInterval)
		prob = min(prob, cfg.probLimit)
		rnd = random.random()
		return rnd <= prob

	def nvalueRecast(self):
		locknum = 0
		attrs = set([])
		for k in self.nvalue:
			if not self.nvalue_locked.get(k, False):
				attrs.add(k)
			else:
				locknum += 1

		minimum = False # 是否触发保底机制
		cfg = self.CardNvalueRmbMap.get(locknum, None)
		if cfg and self.nvalue_cost_rmb_total >= cfg.totalCostRmb: # 优先进行钻石保底策略
			if self.nvalueMinimumActive(cfg):
				minimum = True
				self.nvalue_locknum_recast_process += 1
				# 在未锁定项中：随机一项取值31完美，其他未锁定项则在原有随机取值范围内随机取值、但要去除31
				k = random.choice(list(attrs))
				attrs.discard(k)
				self.nvalue[k] = 31
				locknum += 1

		if attrs: # 还有未锁定的需要随机
			from game.object.game.lottery import ObjectDrawNValueRandom
			lib = ObjectDrawNValueRandom.randomLib(self.game, self.nvalue_recast_total + 1)
			cfg = csv.nvalue_random_lib[lib]
			for k in attrs:
				weights = cfg[k]
				if minimum:
					weights = dict(weights)
					weights.pop(31, None)
				v, _ = WeightRandomObject.onceRandom(weights)
				self.nvalue[k] = v
				if self.nvalue[k] == 31:
					locknum += 1

		if locknum == 6:
			self.nvalue_locked = {k:True for k in self.nvalue}
		self.nvalue_recast_total += 1
		self.nvalue_locknum_recast_total += 1

	# 努力值
	effort_values = db_property('effort_values')

	# 努力值突破
	effort_advance = db_property('effort_advance')

	def randomThreeArrts(self):
		'''
		随机 选三个属性
		'''
		attrs = random.sample(EffortRandomAttrs, 3)
		return attrs

	def getEffortArrtValue(self, attrs, trainType):
		'''
		根据选的属性获取 对应的随机值
		'''
		effortAttrDict = {}
		# 记录负数和零的次数
		negativeOrZero = 0
		for attr in attrs:
			cfg = self.CardEffortMap.get((attr, self.effort_advance), None)
			if cfg:
				# 根据权重先随到范围
				randomRangeWeights = cfg['randomRange%d' % trainType]
				weightsRange = {}
				for weights in randomRangeWeights:
					if negativeOrZero == 2 and weights[0][1] < 1:
						continue
					weightsRange[weights[0]] = weights[1]

				# 前两属性为负前提下且第三项没有可随的，直接取1
				if len(weightsRange) == 0:
					effortAttrDict[attr] = 1
					continue

				randomRange, _ = WeightRandomObject.onceRandom(weightsRange)
				# 普通培养 trainType 为 1 | 高级培养 trainType 为 2
				if negativeOrZero == 2:  # 保证三项必有一项为正
					randomValue = random.randint(max(1, randomRange[0]), randomRange[1])
				else:
					randomValue = random.randint(*randomRange)
					if randomValue <= 0:
						negativeOrZero = negativeOrZero + 1
				effortAttrDict[attr] = randomValue
		return effortAttrDict

	def costEffortTrain(self, trainType, trainTime):
		'''
		努力值培养消耗
		'''
		# 与客户端一致，读第一条
		csvIDs = sorted(csv.card_effort.keys())
		cfg = csv.card_effort[csvIDs[0]]
		costItem = ObjectCostAux(self.game, {})
		time = 0
		for i in xrange(trainTime):
			costItem += ObjectCostAux(self.game, cfg['cost%d' % trainType])
			if not costItem.isEnough():
				# 如果一次都不够的话就直接抛
				if i == 0:
					raise ClientError("train item not enough")
				else:
					break
			time = time + 1
		costItem = ObjectCostAux(self.game, {})
		for i in xrange(time):
			costItem += ObjectCostAux(self.game, cfg['cost%d' % trainType])
		costItem.cost(src='effort_cost')
		return time

	def effortTrain(self, trainType, trainTime):
		'''
		努力值培养
		'''
		effortAttrList = []
		for i in xrange(trainTime):
			attrs = self.randomThreeArrts()
			effortAttrValue = self.getEffortArrtValue(attrs, trainType)
			effortAttrList.append(effortAttrValue)
		self.effortTypeMap = {'trainType':trainType, 'trainTime':trainTime}
		self._effortAttrList = effortAttrList
		ObjectYYHuoDongFactory.onGeneralTask(self.game, TargetDefs.EffortTrainTimes, trainTime)
		if trainType == EffortValueDefs.GeneralTrain:
			ObjectYYHuoDongFactory.onGeneralTask(self.game, TargetDefs.EffortGeneralTrainTimes, trainTime)
			self.game.achievement.onCount(AchievementDefs.EffortGeneralTrainTimes, trainTime)
		elif trainType == EffortValueDefs.SeniorTrain:
			ObjectYYHuoDongFactory.onGeneralTask(self.game, TargetDefs.EffortSeniorTrainTimes, trainTime)
			self.game.achievement.onCount(AchievementDefs.EffortSeniorTrainTimes, trainTime)
		return self._effortAttrList

	def saveEffortValue(self, effortIndexs):
		'''
		保存努力值
		'''
		if not self._effortAttrList:
			raise ClientError("can not train")
		grows = {}
		for effortIndex in effortIndexs:
			for attr, val in self._effortAttrList[effortIndex].iteritems():
				grows[attr] = grows.get(attr, 0) + val
		for attr, val in grows.iteritems():
			curLimitArrt = self.calEffortArrtUpper(attr, self.effort_advance)
			lastLimitArrt = self.calEffortArrtUpper(attr, self.effort_advance-1) # 上一阶段的限制值
			# 只处理当前阶段的
			if lastLimitArrt <= self.effort_values.get(attr, 0) <= curLimitArrt:
				if val >= 0:
					self.effort_values[attr] = min(self.effort_values.get(attr, 0) + val, curLimitArrt)
				else:
					self.effort_values[attr] = max(self.effort_values.get(attr, 0) + val, max(lastLimitArrt, 0))
				if attr == AttrDefs.damage: # 特攻与物攻数值保持一致
					self.effort_values[AttrDefs.specialDamage] = self.effort_values[attr]
		self._effortAttrList = []

	def calEffortArrtUpper(self, attr, advance):
		'''
		努力值 阶段属性上限
		'''
		attrUpValues = ObjectCard.CardEffortAdvanceMap.get((self.effortSeqID, advance), {})
		return attrUpValues.get(attr, 0)

	def isEnoughEffortAdvance(self, advance):
		'''
		努力值 该阶段是否满
		'''
		values = ObjectCard.CardEffortAdvanceMap.get((self.effortSeqID, advance), {})
		for attr in EffortAttrs:
			if self.effort_values.get(attr, 0) < values.get(attr, 0):
				return False
		return True

	def resetEffortAdvance(self):
		'''
		努力值阶段重新计算
		'''
		advance = 1
		for i in xrange(1, self.advanceLimit):
			# 等级 和 努力值是否满
			values = ObjectCard.CardEffortAdvanceMap.get((self.effortSeqID, i + 1), {})
			if (not self.isEnoughEffortAdvance(i)) or self.level < values.get('needLevel', 0):
				break
			advance = advance + 1
		self.effort_advance = advance

	@property
	def advanceLimit(self):
		return ObjectCard.CardEffortAdvanceMap[(self.effortSeqID, 1)]['advanceLimit']

	# 卡牌携带道具
	held_item = db_property('held_item')

	# 性别 read_only
	gender = db_ro_property('gender')

	# 性格
	character = db_property('character')

	# 个体值
	nvalue = db_property('nvalue')

	# 个体值锁定状态 {attrName: bool}
	nvalue_locked = db_property('nvalue_locked')

	# 个体值洗炼累计次数
	nvalue_recast_total = db_property('nvalue_recast_total')

	# 个体值洗炼累计消耗钻石
	nvalue_cost_rmb_total = db_property('nvalue_cost_rmb_total')

	# 个体值锁定数量洗炼次数
	nvalue_locknum_recast_total = db_property('nvalue_locknum_recast_total')

	# 个体值锁定保底洗炼触发次数
	nvalue_locknum_recast_process = db_property('nvalue_locknum_recast_process')

	# 获得时间
	created_time = db_ro_property('created_time')

	# 获得时候初始星级
	getstar = db_ro_property('getstar')

	# 锁定
	locked = db_property('locked')

	# 自然属性选择(编队关环使用)
	# deprecated
	nature_choose = db_property('nature_choose')

	# 卡牌名称
	def name():
		dbkey = 'name'
		def fget(self):
			name = self.db[dbkey]
			if not name:
				return self._csvCard.name
			return name
		return locals()
	name = db_property(**name())

	@property
	def trainingModel(self):
		return {
			'id': self.id,
			'card_id': self.card_id,
			'name': self.name,
			'advance': self.advance,
			'star': self.star,
			'level': self.level,
			'level_exp': self.level_exp,
			'sum_exp': self.exp,
			'skin_id': self.skin_id,
		}

	@property
	def rankModel(self):
		return {
			'id': self.id,
			'role_db_id': self.game.role.id,
			'card_id': self.card_id,
			'name': self.name,
			'advance': self.advance,
			'star': self.star,
			'level': self.level,
			'fighting_point': self.fighting_point,
			'skin_id': self.skin_id,
		}

	def propertySwap(self, targetCard, swapType):
		'''
		属性交换（继承）
		'''
		costDict = {
			PropertySwapDefs.EffortSwap: {'rmb': ConstDefs.effortSwapCostRmb},
			PropertySwapDefs.NvalueSwap: {'rmb': ConstDefs.nvalueSwapCostRmb},
			PropertySwapDefs.CharacterSwap: {'rmb': ConstDefs.characterSwapCostRmb}
		}
		if swapType not in costDict.keys():
			raise ClientError('swapType error')
		cost = ObjectCostAux(self.game, costDict.get(swapType, {}))
		if not cost.isEnough():
			raise ClientError("cost rmb not enough")
		# 努力值
		if swapType == PropertySwapDefs.EffortSwap:
			tempEffort = {}
			logger.info("!!! cardID_1:%s effort_value:%s   cardID_2:%s effort_value:%s", self.pid, self.effort_values, targetCard.pid, targetCard.effort_values)
			# 值交换
			for attr in EffortAttrs:
				tempEffort[attr] = self.effort_values.get(attr, 0)
				self.effort_values[attr] = min(targetCard.effort_values.get(attr, 0), self.calEffortArrtUpper(attr, self.advanceLimit))
				targetCard.effort_values[attr] = min(tempEffort.get(attr, 0), targetCard.calEffortArrtUpper(attr, targetCard.advanceLimit))
			# 阶段重新计算
			self.resetEffortAdvance()
			targetCard.resetEffortAdvance()
		else:
			if self.markID != targetCard.markID:
				raise ClientError('Two cards have different markID')
			# 个体值
			if swapType == PropertySwapDefs.NvalueSwap:
				tempNvalue = {}
				for attr in NValueAttrs:
					tempNvalue[attr] = self.nvalue.get(attr, 0)
					self.nvalue[attr] = targetCard.nvalue.get(attr, 0)
					targetCard.nvalue[attr] = tempNvalue.get(attr, 0)
			# 性格
			else:
				tempCharacter = (self.character, targetCard.character)
				self.character = tempCharacter[1]
				targetCard.character = tempCharacter[0]
		cost.cost(src='propertySwap_cost')

	# 是否存在（可能已经被分解）
	exist_flag = db_property('exist_flag')

	def getRebirthEff(self):
		types = ('advance', 'level', 'skill', 'equip', 'ability')
		effAll = ObjectGainAux(self.game, {})
		objs = []
		for typ in types:
			RebirthCls = ObjectCardRebirthFactory.getRebirthCls(typ)
			obj = RebirthCls(self.game, self)
			eff = obj.getEffect(ConstDefs.rebirthRetrunProportion1)
			if eff:
				effAll += eff
				objs.append(obj)
		rmb = ObjectCardRebirthBase.rebirthCost(effAll.result, CardResetDefs.cardRmbCostType)
		cost = ObjectCostAux(self.game, {'rmb': rmb})
		if not cost.isEnough():
			raise ClientError('cost not enough')
		cost.cost(src='card_rebirth')
		haveAllDict = {}
		if self.haveAllCardsAbility():
			haveAllDict['ability'] = True
		for obj in objs:
			obj.rebirth() # 重生
		if haveAllDict:
			if haveAllDict.get('ability', False):
				self.game.cards.onCardsAbilityChange()
		return effAll

	def getDecomposeEff(self):
		frags = {}
		items = {}
		cards = 0

		# 1.初始星级
		cfg = csv.cards[self.card_id]
		if cfg.fragID == 0:
			raise ServerError('cards.csv no fragID')
		starFragCfg = ObjectCard.getStarFragCfg(cfg.fragNumType, self.getstar)
		frags[cfg.fragID] = starFragCfg.baseFragNum

		for i in xrange(self.getstar, self.star):
			csvStar = self.CardsMarkStarMap.get((self.starTypeID, i), None)
			cards += csvStar.costCardNum
			# 2.升星消耗材料
			items['gold'] = items.get('gold', 0) + csvStar.gold
			for k, v in csvStar.costItems.iteritems():
				items[k] = items.get(k, 0) + v

		# 3.消耗系列整卡
		cards -= sum(self.cost_universal_cards.values())
		starFragCfg = ObjectCard.getStarFragCfg(cfg.fragNumType, 1) # 消耗的整卡都当1星处理
		frags[cfg.fragID] += starFragCfg.baseFragNum * cards

		# 4.消耗万能整卡 （暂不处理）

		# 将碎片转换为魂石
		for fragID, num in frags.iteritems():
			cfg = csv.fragments[fragID]
			for k, v in cfg.decomposeGain.iteritems():
				items[k] = items.get(k, 0) + v * num

		for k, v in items.iteritems():
			items[k] = int(math.ceil(ConstDefs.rebirthRetrunProportion2 * v))

		# 5.极限技能
		costItemNum = 0
		for starSkillIdx, skillID in enumerate(self.starSkillList):
			if skillID not in self.db['skills']:
				continue
			cfg = csv.skill[skillID]
			costID = cfg.costID
			itemField = 'itemNum%d' % costID
			skillLevel = self.db['skills'][skillID]
			for i in xrange(0, skillLevel):
				costCfg = csv.base_attribute.skill_level[i]
				costItemNum += costCfg[itemField]
			self.star_skill_level[starSkillIdx] = 0
			self.db['skills'][skillID] = self.star_skill_level[starSkillIdx]

		costItemNum = int(math.ceil(ConstDefs.rebirthRetrunProportion6 * costItemNum))
		if costItemNum > 0:
			items['star_skill_points'] = {self.markID: costItemNum}

		return ObjectGainAux(self.game, items)

	# 特性 {position: strengthLevel}
	abilities = db_property('abilities')

	def abilityStrength(self, position, upLevel):
		cfg = self.CardAbilityMap[(self.abilitySeqID, position)]
		if cfg['abilitySeqID'] != self.abilitySeqID:
			raise ClientError('csv error')

		level = self.abilities.setdefault(position, 0)

		# 判断等级是否已最高
		if (level+upLevel) > cfg['strengthMax']:
			raise ClientError('Ability is MaxLevel')

		# 激活条件
		conditionType, conditionLevel = cfg['strengthCod1']
		preAbilityLevel = cfg['strengthCod2']
		if conditionType == CardAbilityDefs.LevelType:
			if self.level < conditionLevel:
				raise ClientError('level no enough, can not strength')
		elif conditionType == CardAbilityDefs.AdvanceType:
			if self.advance < conditionLevel:
				raise ClientError('advance no enough, can not strength')
		# 任意满足一个就可以
		preAbilityLen = len(cfg['preAbilityID'])
		if preAbilityLevel and preAbilityLen:
			enoughNum = 0
			for pos in cfg['preAbilityID']:
				if self.abilities.get(pos, 0) >= preAbilityLevel:
					enoughNum += 1
			if enoughNum == 0:
				raise ClientError('preAbility level no enough, can not strength')

		# 消耗
		strengthCostSeq = cfg['strengthSeqID']
		cost = ObjectCostAux(self.game, {})
		for i in xrange(1, upLevel+1):
			costItems = csv.card_ability_cost[level + i]['costItemMap%d' % strengthCostSeq]
			cost += ObjectCostAux(self.game, costItems)
		if not cost.isEnough():
			raise ClientError('ability strength cost not enough')
		cost.cost(src='ability_strength')

		self.abilities[position] = level + upLevel
		ObjectYYHuoDongFactory.onGeneralTask(self.game, TargetDefs.CardAbilityStrength, upLevel)

	def getAbilityAttrsAdd(self, scene):
		const = zeros()
		percent = zeros()
		addAbilities = {}  # {csvID: (groups, [level1, level2...])}
		# 自身特性
		for position, level in self.abilities.iteritems():
			cfg = self.CardAbilityMap[(self.abilitySeqID, position)]
			if level > 0 and cfg.effectType == CardAbilityDefs.EffectAttrType:
				groups = []
				for i in xrange(1, 99):
					at = 'attrType%d' % i
					if at not in cfg or not cfg[at]:
						break
					if cfg['attrAddType%d' % i] == CardAbilityDefs.AttrAddOne:  # 自身
						groups.append(i)
					elif cfg['attrAddType%d' % i] == CardAbilityDefs.AttrAddScene:  # 场景
						if scene in cfg['attrAddScene%d' % i]:
							groups.append(i)
				if groups:
					addAbilities[cfg.id] = (groups, [level])

		if self.game:
			# 他人特性影响（全体）
			for _, abilityLevel in self.game.cards.markIDMaxLevelAbility.iteritems():
				for csvID, level in abilityLevel.iteritems():
					if level > 0:
						_, levels = addAbilities.get(csvID, (None, []))
						groups = ObjectCard.CardAbilityGroupMap.get(csvID, [])
						levels.append(level)
						addAbilities[csvID] = (groups, levels)

		# 统一计算
		for csvID, values in addAbilities.iteritems():
			groups, levels = values
			cfg = csv.card_ability[csvID]
			for i in groups:
				attrType = cfg['attrType%d' % i]
				an = ObjectCard.CardAbilityAttrMap.get((csvID, i), [])
				for level in levels:
					attrNum = an[level - 1]
					num = str2num_t(attrNum)
					const[attrType] += num[0]
					percent[attrType] += num[1]
		return const, percent

	def getAbilitySkills(self, isGlobal=False):
		skills = {}
		for position, level in self.abilities.iteritems():
			cfg = self.CardAbilityMap[(self.abilitySeqID, position)]
			if level > 0 and cfg.effectType == CardAbilityDefs.EffectSkillType:
				if isGlobal:
					if csv.skill[cfg.skillID].isGlobal:
						skills[cfg.skillID] = level  # ability level is passive skill level
				else:
					if not csv.skill[cfg.skillID].isGlobal:
						skills[cfg.skillID] = level
		return skills

	# 是否有全体特性
	def haveAllCardsAbility(self):
		for position, level in self.abilities.iteritems():
			cfg = self.CardAbilityMap[(self.abilitySeqID, position)]
			if cfg.id in ObjectCard.CardAbilityGroupMap and level > 0:
				return True
		return False

	def onUpdateAbility(self):
		self.calcAbilityAttrsAddition(self)
		self.onUpdateAttrs()

	# 宝石镶嵌 {位置: gemDbID}
	gems = db_property('gems')

	def calGemsAttrsAdd(self):
		'''
		计算宝石的属性加成
		'''
		const = zeros()
		percent = zeros()
		# 镶嵌属性
		for pos, gemID in self.gems.iteritems():
			gem = self.game.gems.getGem(gemID)
			const1, percent1 = gem.getAttrs()
			const += const1
			percent += percent1
		# 套装共鸣属性
		const2, percent2 = self.game.gems.getGemSuitAttrs(self.id)
		const += const2
		percent += percent2
		# 品质指数属性
		const3, percent3 = self.game.gems.getGemQualityAttrs(self.id)
		const += const3
		percent += percent3

		return const, percent

	# 芯片镶嵌 {位置: chipDbID}
	chip = db_property('chip')

	def calChipsAttrsAdd(self):
		'''
		计算芯片的属性加成
		'''
		const = zeros()
		percent = zeros()
		# 镶嵌属性
		for pos, chipID in self.chip.iteritems():
			chip = self.game.chips.getChip(chipID)
			const1, percent1 = chip.getAttrs()
			const += const1
			percent += percent1
		# # 套装共鸣属性
		const2, percent2 = self.game.chips.getChipSuitAttrs(self)
		const += const2
		percent += percent2
		# 套装共鸣属性
		const3, percent3 = self.game.chips.getResonanceAttrs(self)
		const += const3
		percent += percent3

		return const, percent

	# 勋章守护 [badgeID, guardID]
	badge_guard = db_property('badge_guard')

	def addStarSkillPointByCostCards(self, costCards):
		cfg = csv.card_star_skill[self.starSkillSeqID]
		if cfg is None:
			raise ClientError("config not exists")

		costCardNum = 0
		costAux = ObjectCostAux(self.game, {})
		costAux.setCostCards(costCards)
		if costAux.isEnough():
			# 如果消耗卡牌有携带道具需 卸下
			for costCard in costCards:
				if costCard.held_item:
					heldItem = self.game.heldItems.getHeldItem(costCard.held_item)
					if heldItem:
						heldItem.card_db_id = None
						costCard.held_item = None
				costCardNum += 1
				for i in xrange(costCard.getstar, costCard.star):
					csvStar = costCard.CardsMarkStarMap.get((costCard.starTypeID, i), None)
					costCardNum += csvStar.costCardNum
			costAux.cost(src='card_star_skill')
		else:
			raise ClientError(ErrDefs.costNotEnough)

		return ObjectGainAux(self.game, {'star_skill_points': {self.markID: costCardNum * cfg.cardExchangeRate}})

	def addStarSkillPointByCostfrag(self, costFragNum):
		cfg = csv.card_star_skill[self.starSkillSeqID]

		if cfg.fragExchangeRate == 0:
			raise ClientError('config fragExchangeRate error')

		a, b = divmod(costFragNum, cfg.fragExchangeRate)
		if b > 0:
			raise ClientError('costFragNum error')

		return ObjectGainAux(self.game, {'star_skill_points': {self.markID: a}})

	def starSkillReset(self):
		starSkillList = self.starSkillList
		markID = self.markID

		needReset = False
		for skillID in starSkillList:
			if self.db['skills'][skillID] > 0:
				needReset = True
		if not needReset:
			raise ClientError('has not skill need reset')

		hasPassiveSkill = False
		eff = ObjectGainAux(self.game, {})
		for starSkillIdx, skillID in enumerate(starSkillList):
			cfg = csv.skill[skillID]
			if cfg.skillType == SkillDefs.passiveAttr:
				hasPassiveSkill = True
			costID = cfg.costID
			itemField = 'itemNum%d' % costID
			skillLevel = self.db['skills'][skillID]
			for i in xrange(0, skillLevel):
				costCfg = csv.base_attribute.skill_level[i]
				costItemNum = costCfg[itemField]
				eff += ObjectGainAux(self.game, {'star_skill_points': {markID: costItemNum}})
			self.star_skill_level[starSkillIdx] = 0
			self.db['skills'][skillID] = self.star_skill_level[starSkillIdx]

		if hasPassiveSkill:
			self.calcPassiveSkillAttrsAddition(self)
		self.onUpdateAttrs()

		return eff

def randomCharacter(csvID):
	cfg = csv.character_random[csvID]
	v, _ = WeightRandomObject.onceRandom(cfg.weightList)
	return v

def randomNumericalValue(csvID):
	cfg = csv.nvalue_random_lib[csvID]
	attrs = {}
	for attr in NValueAttrs:
		v, _ = WeightRandomObject.onceRandom(cfg[attr])
		attrs[attr] = v
	return attrs

#
# ObjectCardsMap
#

class ObjectCardsMap(ObjectDBaseMap):

	def _new(self, dic):
		card = ObjectCard(self.game, self.game._dbcGame)
		card.set(dic)
		return (card.id, card)

	def __init__(self, game):
		ObjectDBaseMap.__init__(self, game)
		self._inited = False
		self._markS = set()
		self.fightChangeCards = set()
		self.deploymentForArena = ObjectCardDeployment()
		self.deploymentForUnionTraining = ObjectCardDeployment()
		self.deploymentForCraft = ObjectCardDeployment()
		self.deploymentForCrossCraft = ObjectCardDeployment()
		self.deploymentForCrossOnlineFight = ObjectCardDeployment()
		self.deploymentForUnionFight = ObjectCardDeployment()
		self.deploymentForCrossArena = ObjectCardDeployment()
		self.deploymentForGym = ObjectCardDeployment()
		self.deploymentForCrossMine = ObjectCardDeployment()
		self.deploymentForCrossUnionFight = ObjectCardDeployment()
		self.maxFightPointCardID = 0
		self.markIDMaxStar = defaultdict(int)  # {markID: maxStar}
		self.markIDMaxLevelAbility = {}  # {markID: {position: maxLevel}}
		self.fightChangeCloneDeployCard = None
		self.markIDMaxFight = {}  # {markID: (cardID, fight)}
		self.markIDMaxFightChangeCards = {}
		self.top20Cards = set()

	def init(self):
		self._markS = set([o.markID for o in self._objs.itervalues()])
		self._zawakeS = set([o.zawakeID for o in self._objs.itervalues()])
		self._initMarkIDMaxStar()
		self._initMarkIDMaxLevelAbility()
		self._initMarkIDMaxFight()
		ret = ObjectDBaseMap.init(self)
		self._inited = True
		self._locked = False # if True, will not update total fighting_point
		self.onFightingPointChange()

		return ret

	def _initMarkIDMaxStar(self):
		self.markIDMaxStar = defaultdict(int)
		for _, obj in self._objs.iteritems():
			star = self.markIDMaxStar[obj.markID]
			self.markIDMaxStar[obj.markID] = max(obj.star, star)

	def _initMarkIDMaxLevelAbility(self):
		self.markIDMaxLevelAbility = {}
		for _, obj in self._objs.iteritems():
			for position, level in obj.abilities.iteritems():
				csvID = ObjectCard.CardAbilityMap[(obj.abilitySeqID, position)]
				if csvID in ObjectCard.CardAbilityGroupMap: # 全体特性
					abilityLevel = self.markIDMaxLevelAbility.setdefault(obj.markID, {})
					if level > abilityLevel.setdefault(position, 0):
						self.markIDMaxLevelAbility[obj.markID][position] = level

	def _initMarkIDMaxFight(self):
		self.markIDMaxFight = {}
		for _, obj in self._objs.iteritems():
			if obj.markID not in self.markIDMaxFight:
				self.markIDMaxFight[obj.markID] = (obj.id, obj.fighting_point)
			elif self.markIDMaxFight[obj.markID][1] < obj.fighting_point:
				self.markIDMaxFight[obj.markID] = (obj.id, obj.fighting_point)

	def isExistedByMarkID(self, cardMarkID):
		return cardMarkID in self._markS

	def getCardByMarkID(self, cardMarkID):
		if cardMarkID in self._markS:
			for _, o in self._objs.iteritems():
				if o.markID == cardMarkID:
					return o
		return None

	def getCardsByMarkIDs(self, cardMarkIDs):
		cards = set()
		if not cardMarkIDs:
			return set()
		for _, o in self._objs.iteritems():
			if o.markID in cardMarkIDs:
				cards.add(o)
		return cards

	def getCardsByMarkID(self, cardMarkID):
		cards = []
		if cardMarkID in self._markS:
			for _, o in self._objs.iteritems():
				if o.markID == cardMarkID:
					cards.append(o)
		return cards

	def getCardsByZawakeID(self, zawakeID):
		cards = []
		if zawakeID in self._zawakeS:
			for _, o in self._objs.iteritems():
				if o.zawakeID == zawakeID:
					cards.append(o)
		return cards

	def isExistedByID(self, cardIDs):
		if not isinstance(cardIDs, list):
			cardIDs = [cardIDs]
		for id in cardIDs:
			if id not in self._objs:
				return False
		return True

	def isExistedByCsvID(self, csvID):
		for _, o in self._objs.iteritems():
			if o.card_id == csvID:
				return True
		return False

	def isExistedByStar(self, star):
		for _, o in self._objs.iteritems():
			if o.star >= star:
				return True
		return False

	def updateAllCardsAttr(self):
		for _, card in self._objs.iteritems():
			card.onUpdateAttrs()

	def updateAllNatureCardAttr(self, nature, f=None):
		cards = self.getCardsByNature(nature)
		for card in cards:
			if f:
				f(card)
			card.onUpdateAttrs()

	def updateAllNaturesCardAttr(self, natures, f=None):
		cards = self.getCardsByNatures(natures)
		for card in cards:
			if f:
				f(card)
			card.onUpdateAttrs()

	def getCard(self, cardID):
		return self._objs.get(cardID, None)

	def getCards(self, cardIDs):
		ret = []
		for id in cardIDs:
			if id in self._objs:
				ret.append(self._objs[id])
		return ret

	def getCardsByCsvID(self, csvID):
		ret = []
		for _, o in self._objs.iteritems():
			if o.card_id == csvID:
				ret.append(o)
		return ret

	def getCardsByNature(self, nt):
		if not nt:
			return self._objs.values()
		ret = []
		for _, card in self._objs.iteritems():
			if card.natureType == nt:
				ret.append(card)
		return ret

	def getCardsByNatures(self, nts):
		if 0 in nts:
			return self._objs.values()
		ret = []
		for _, card in self._objs.iteritems():
			if card.natureType in nts:
				ret.append(card)
		return ret

	def getMarkIDsByCardIDs(self, cardIDs):
		ret = set()
		for id in cardIDs:
			if id in self._objs:
				ret.add(self._objs[id].markID)
		return ret

	def getCSVIDs(self):
		return map(lambda o: o.card_id, self._objs.itervalues())

	def getDBIDs(self):
		return self._objs.keys()

	def getAllCards(self):
		return self._objs

	def getFightgoVal(self):
		val = self.game.role.fightgo
		for cardID, card in self._objs.iteritems():
			val += card.fightgo_val
		return int(val)

	def getCostCards(self, cardIDs, user=None):
		if len(cardIDs) != len(set(cardIDs)):
			raise ClientError('have the sample cardID')
		cards = self.getCards(cardIDs)
		if len(cards) != len(cardIDs):
			raise ClientError('card error')
		for card in cards:
			if user and card.id == user:
				raise ClientError('can not cost self')
			if card.locked:
				raise ClientError('card is locked')
			if self.inusing(card.id):
				raise ClientError('card is using')
		return cards

	def countAdvanceCards(self, advance):
		ret = 0
		for _, o in self._objs.iteritems():
			if o.advance >= advance:
				ret += 1
		return ret

	def countStarCards(self, star):
		ret = 0
		for _, o in self._objs.iteritems():
			if o.star >= star:
				ret += 1
		return ret

	def countLevelCards(self, level):
		ret = 0
		for _, o in self._objs.iteritems():
			if o.level >= level:
				ret += 1
		return ret

	def countAdvanceEquips(self, advance):
		ret = 0
		for _, o in self._objs.iteritems():
			ret += o.countAdvanceEquips(advance)
		return ret

	def countStarEquips(self, star):
		ret = 0
		for _, o in self._objs.iteritems():
			ret += o.countStarEquips(star)
		return ret

	def countAwakeEquips(self, awake):
		ret = 0
		for _, o in self._objs.iteritems():
			ret += o.countAwakeEquips(awake)
		return ret

	def countNvalueCards(self, target):
		ret = 0
		for _, o in self._objs.iteritems():
			if all([i >= target for i in o.nvalue.values()]):
				ret += 1
		return ret

	def countMarkIDStarCards(self, markID, star):
		ret = 0
		for _, o in self._objs.iteritems():
			if o.markID == markID and o.star >= star:
				ret += 1
		return ret

	def addCards(self, cardsL, loading=False):
		def _new(dic):
			card = ObjectCard(self.game, self.game._dbcGame)
			if loading:
				card.set(dic)
			else:
				card.set(dic).init().startSync()
			if card.id in self._objs:
				card.gc_destroy()
				raise ServerError('card %d existed' % card.id)
			return (card.id, card)

		objs = dict(map(_new, cardsL))
		self._objs.update(objs)
		self._markS |= set([o.markID for o in objs.itervalues()])
		self.game.role.cards = map(lambda o: o.id, self._objs.itervalues())
		self.game.role.card_gain_times += len(objs)
		self._add(objs.keys())
		if not loading:
			self.game.pokedex.addPokedex(objs.keys())
		self.onCardsStarChange({o.markID: o.star for o in objs.values()})
		ObjectYYHuoDongFactory.onNewCard(self.game, cards=objs.values())
		self.game.achievement.onTargetTypeCount(AchievementDefs.LogoCount)
		return objs

	def deleteCards(self, objs):
		if not objs:
			return

		haveAllDict = {}  # {keyName: False}
		for obj in objs:
			if obj.held_item:  # 卡牌上有携带道具，先卸下
				hitem = self.game.heldItems.getHeldItem(obj.held_item)
				if hitem:
					hitem.card_db_id = None
					obj.held_item = None
			if obj.gems:  # 卡牌上有宝石，先卸下
				gems = self.game.gems.getGems(obj.gems.values())
				for gem in gems:
					if gem:
						gem.card_db_id = None
				obj.gems = {}
			if obj.chip:  # 卡牌上有芯片，先卸下
				chips = self.game.chips.getChips(obj.chip.values())
				for chip in chips:
					if chip:
						chip.card_db_id = None
				obj.chip = {}
			# 是否有全体特性
			if obj.haveAllCardsAbility():
				haveAllDict['ability'] = True

		for obj in objs:
			obj.exist_flag = False
			del self._objs[obj.id]
			self._del([obj.id])
			ObjectCard.CardsObjsMap.pop(obj.id, None)
		self._markS = set([o.markID for o in self._objs.itervalues()])
		self.game.role.cards = map(lambda o: o.id, self._objs.itervalues())
		self.onCardsStarChange({o.markID: o.star for o in objs})
		if haveAllDict.get('ability', False):
			self.onCardsAbilityChange()
		delay = self.game.role.vip_level >= 10
		for obj in objs:
			obj.delete_async(delay=delay and obj.star > obj.getstar)
		# 日常助手删除许愿设置
		cardCsvID = self.game.role.daily_assistant.get("union_frag_donate_card_id", 0)
		if cardCsvID and not self.isExistedByCsvID(cardCsvID):
			self.game.role.daily_assistant.pop("union_frag_donate_card_id", 0)

	def updateFetterCards(self, fetterIDs):
		markIDs = set([])
		for fetterID in fetterIDs:
			if fetterID not in ObjectCard.CardFetterMarkIDMap: # 改羁绊的变动不影响卡牌
				continue
			markIDs |= ObjectCard.CardFetterMarkIDMap[fetterID]
		cards = []
		for markID in markIDs:
			cards.extend(self.getCardsByMarkID(markID))
		for card in cards:
			card.onUpdateFetters()

	def onCardsStarChange(self, markIDStars):
		changed = set()
		for markID, star in markIDStars.iteritems():
			if markID not in self._markS:
				self.markIDMaxStar.pop(markID, None)
				changed.add(markID)
				continue

			old = self.markIDMaxStar[markID]
			maxstar = 0
			for _, obj in self._objs.iteritems():
				if obj.markID == markID:
					maxstar = max(maxstar, obj.star)
			if old != maxstar: # 最大星数变化
				self.markIDMaxStar[markID] = maxstar
				changed.add(markID)
		if changed:
			self.game.pokedex.updateDevelopRelatedCards()

	def onCardsAbilityChange(self):
		# 只要有一个全体的特性有变化 都要全体重新计算
		oldMarkIDMaxLevelAbility = self.markIDMaxLevelAbility
		self._initMarkIDMaxLevelAbility()
		if oldMarkIDMaxLevelAbility != self.markIDMaxLevelAbility:
			for _, card in self._objs.iteritems():
				card.onUpdateAbility()

	def getMaxAbilityLevel(self, markID, position):
		abilityLevel = self.markIDMaxLevelAbility.get(markID, {})
		return abilityLevel.get(position, 0)

	def makeBattleCardHalo(self, cardIDs, scene):
		if len(filter(None, cardIDs)) < 6:
			return {}, {}
		natures = {} # {natureType: count}
		for i, cardID in enumerate(cardIDs):
			card = self._objs.get(cardID, None)
			if not card:
				continue
			natureType = card.natureType if card.nature_choose == 1 else card.natureType2
			natures[natureType] = natures.get(natureType, 0) + 1
		ratio = sorted(natures.values(), reverse=True)

		const, percent = {}, {}
		for group, cfgs in ObjectCard.BattleCardHaloAttrMap.iteritems():
			for cfg in cfgs:
				if scene in cfg.invalidScenes:
					continue
				matched = True
				if cfg.type == 1: # 自然属性比例
					args = sorted(cfg.args, reverse=True)
					if len(ratio) < len(args):
						matched = False
					else:
						for i, v in enumerate(args):
							matched = matched and ratio[i] >= v
				elif cfg.type == 2: # 指定自然属性数量
					for nature, count in cfg.args:
						matched = matched and natures.get(nature, 0) == count
				else:
					matched = False
				if matched:
					for i in xrange(1, 99):
						ty = 'attrType%d'%i
						if ty not in cfg or not cfg[ty]:
							break
						num = str2num_t(cfg['attrValue%d'%i])
						attr = AttrDefs.attrsEnum[cfg[ty]]
						const[attr] = const.get(attr, 0) + num[0]
						percent[attr] = percent.get(attr, 0) + num[1]
					break
		return const, percent

	def findBattleCardHalo(self, natureL, scene):
		natures = {}
		for nature in natureL:
			natures[nature] = natures.get(nature, 0) + 1
		cfgs = []
		priority = 0
		ratio = sorted(natures.values(), reverse=True)
		for group, vv in ObjectCard.BattleCardHaloAttrMap.iteritems():
			for cfg in vv:
				if scene in cfg.invalidScenes:
					continue
				matched = True
				if cfg.type == 1: # 自然属性比例
					args = sorted(cfg.args, reverse=True)
					if len(ratio) < len(args):
						matched = False
					else:
						for i, v in enumerate(args):
							matched = matched and ratio[i] >= v
				elif cfg.type == 2: # 指定自然属性数量
					for nature, count in cfg.args:
						matched = matched and natures.get(nature, 0) == count
				else:
					matched = False
				if matched:
					cfgs.append(cfg)
					if cfg.type == 1:
						priority = max(priority, cfg.autoPriority)
					break
		return cfgs, priority

	# 自动计算最优队伍光环
	def makeBattleCardHaloBest(self, cardIDs, scene):
		v = len(filter(None, cardIDs))
		if v < 6 or v > 12: # 正常只有6张卡才计算队伍光环，但因为之前石英和跨服石英计算了队伍光环，这点不不修改，分别是10张和12张
			return {}, {}, None

		natureTypes = [] # [(natureType, natureType2)]
		for i, cardID in enumerate(cardIDs):
			card = self._objs.get(cardID, None)
			if not card:
				return {}, {}, None
			natureTypes.append((card.natureType, card.natureType2))

		length = len(cardIDs)
		chooses = [1 for _ in xrange(length)]
		best = [None]
		def dfs(i, best):
			if i >= length:
				natureL = [natureTypes[idx][choose-1] for idx, choose in enumerate(chooses)]
				cfgs, priority = self.findBattleCardHalo(natureL, scene)
				if not best[0] or best[0][2] < priority:
					best[0] = (list(chooses), cfgs, priority)
			else:
				chooses[i] = 1
				dfs(i+1, best)
				if natureTypes[i][1]: # 存在第二自然属性
					chooses[i] = 2
					dfs(i+1, best)
		dfs(0, best)

		const, percent = {}, {}
		for cfg in best[0][1]:
			for i in xrange(1, 99):
				ty = 'attrType%d'%i
				if ty not in cfg or not cfg[ty]:
					break
				num = str2num_t(cfg['attrValue%d'%i])
				attr = AttrDefs.attrsEnum[cfg[ty]]
				const[attr] = const.get(attr, 0) + num[0]
				percent[attr] = percent.get(attr, 0) + num[1]
		return const, percent, best[0][0]

	def makeBattleCardModel(self, cardIDs, scene=SceneDefs.City, dirty=None):
		const, percent, chooses = self.makeBattleCardHaloBest(cardIDs, scene) # 队伍光环
		if dirty and any(dirty):
			cardIDs = dirty
		cardsD = {}
		seconds = {} # 第二套属性
		for i, cardID in enumerate(cardIDs):
			card = self._objs.get(cardID, None)
			if not card:
				continue
			inFront = i < 3
			inBack = i >= 3
			choose = chooses[i] if chooses else 1
			model = card.battleModel(inFront, inBack, scene, nature_choose=choose)
			model = appendCardAttrsAddition(model, const, percent)
			cardsD[cardID] = model

			# 第二套属性
			if card.twinFlag:
				twin = card2twin(card)
				model = twin.battleModel(inFront, inBack, scene, nature_choose=choose)
				model = appendCardAttrsAddition(model, const, percent)
				seconds[cardID] = model
		return cardsD, seconds

	def markBattlePassiveSkills(self, cardIDs, scene=SceneDefs.City):
		passive_skills = {}
		isGlobal = True
		for i, cardID in enumerate(cardIDs):
			card = self._objs.get(cardID, None)
			if not card:
				continue
			# 特殊效果被动技能(携带道具，探险器, 特性, 形象)
			if card.held_item:
				heldItem = self.game.heldItems.getHeldItem(card.held_item)
				skills = heldItem.getPassiveSkills(card.markID, isGlobal)
				passive_skills.update(skills)

			abilitySkills = card.getAbilitySkills(isGlobal)
			passive_skills.update(abilitySkills)

			zawakeSkills = self.game.zawake.getPassiveSkills(cardID)
			passive_skills.update(zawakeSkills)

			chipSkills = self.game.chips.getPassiveSkills(cardID)
			passive_skills.update(chipSkills)

		explorerSkills = self.game.explorer.getPassiveSkills(isGlobal)
		passive_skills.update(explorerSkills)
		figureSkills = self.game.role.getFigureAbilitySkills(isGlobal)
		passive_skills.update(figureSkills)
		if scene == SceneDefs.Gym:
			gymTalentSkills = self.game.gymTalentTree.getPassiveSkills(isGlobal)
			passive_skills.update(gymTalentSkills)

		return passive_skills

	def makeUnionFightCardInfo(self, delCards=None):
		cards = {2:{1:[],2:[]},3:{1:[],2:[]},4:{1:[],2:[]},5:{1:[],2:[]},6:{1:[],2:[],3:[]}}
		cardMarkMap = defaultdict(set)
		cardIDs = []
		objs = self._objs.values()
		objs.sort(key=lambda o: o.fighting_point, reverse=True)
		for card in objs:
			for day,li in ObjectUnionFightGlobal.WeekNatureLimit.iteritems():
				if delCards and day in delCards and card.id in delCards[day]:
					continue
				if day not in cards:
					continue
				if card.markID in cardMarkMap[day]:
					continue
				if li and card.natureType not in li and card.natureType2 not in li:
					continue
				info = cards[day]
				if day in (2,3,4,5):
					if len(info[2]) < len(info[1]):
						info[2].append(card.id)
					elif len(info[1]) < 3:
						info[1].append(card.id)
				elif day == 6:
					if len(info[2]) < len(info[1]):
						info[2].append(card.id)
					elif len(info[3]) < len(info[1]):
						info[3].append(card.id)
					elif len(info[1]) < 4:
						info[1].append(card.id)
				else:
					continue

				cardIDs.append(card.id)
				cardMarkMap[day].add(card.markID)
		return cards, cardIDs

	def makeCrossUnionFightCardInfo(self, project):
		# {初 / 决: {战场: [cardID]}} (初:1 决:2) (常规:1 车轮:2 单挑:3)
		cards = {}
		cardMarkMap = set()
		cardIDs = []
		objs = self._objs.values()
		objs.sort(key=lambda o: o.fighting_point, reverse=True)
		for card in objs:
			if card.markID in cardMarkMap:
				continue
			cardMarkMap.add(card.markID)
			if project == CrossUnionFightDefs.BattleSix:
				# 常规 6V6
				projectCards1 = cards.setdefault(CrossUnionFightDefs.BattleSix, [])
				if len(projectCards1)+1 <= 12:
					projectCards1.append(card.id)
					cardIDs.append(card.id)
				else:
					break
			elif project == CrossUnionFightDefs.BattleFour:
				# 车轮 4V4
				projectCards2 = cards.setdefault(CrossUnionFightDefs.BattleFour, [])
				if len(projectCards2)+1 <= 18:
					if (len(projectCards2)+1) % 6 in (1, 2, 3, 4):
						projectCards2.append(card.id)
						cardIDs.append(card.id)
					else:
						projectCards2.append(None)
				else:
					break
			elif project == CrossUnionFightDefs.BattleOne:
				# 单挑 1V1
				projectCards3 = cards.setdefault(CrossUnionFightDefs.BattleOne, [])
				if len(projectCards3)+1 <= 9:
					projectCards3.append(card.id)
					cardIDs.append(card.id)
				else:
					break
		allCards = {}
		for ty in (CrossUnionFightDefs.PreStage, CrossUnionFightDefs.TopStage):
			allCards[ty] = cards
		return allCards, cardIDs

	def makeRankCardInfo(self, cardIDs):
		cardDCSs = []
		cardsD = {}
		for cardID in cardIDs:
			card = self.getCard(cardID)
			if card:
				cardDCSs.append((cardID, card.card_id, card.skin_id))
				cardsD[cardID] = {
					'level': card.level,
					'fighting_point': card.fighting_point,
					'advance': card.advance,
					'star':card.star,
					'skin_id':card.skin_id,
				}
			else:
				cardDCSs.append((None, 0, 0))
		return cardDCSs, cardsD

	def onSkinIDChange(self, card=None):
		if not self._inited or len(self._objs) == 0:
			return

		if card:
			if self.game.role.pvp_record_db_id:
				self.deploymentForArena.put(card.id)
			if self.game.role.craft_record_db_id:
				self.deploymentForCraft.put(card.id)
			if self.game.role.cross_craft_record_db_id:
				self.deploymentForCrossCraft.put(card.id)
			if card.id == self.game.role.clone_deploy_card_db_id:
				cardD = card.battleModel(False, False, SceneDefs.Clone)
				cardD2 = None
				if card.twinFlag:
					cardD2 = card2twin(card).battleModel(False, False, SceneDefs.Clone)
				self.fightChangeCloneDeployCard = [cardD, cardD2]
			if self.game.role.union_fight_record_db_id:
				self.deploymentForUnionFight.put(card.id)
			if self.game.role.cross_arena_record_db_id:
				self.deploymentForCrossArena.put(card.id)
			if self.game.role.gym_record_db_id:
				self.deploymentForGym.put(card.id)
			if self.game.role.union_db_id:
				self.deploymentForUnionTraining.put(card.id)
			if self.game.role.cross_mine_record_db_id:
				self.deploymentForCrossMine.put(card.id)
			if self.game.role.cross_union_fight_record_db_id:
				self.deploymentForCrossUnionFight.put(card.id)

	def updateCardSkills(self, card, oldSkinID):
		newSkills = {}
		cfg = csv.cards[card.card_id]
		if card.skin_id and card.skin_id in cfg.skinSkillMap:
			newSkillList = cfg.skinSkillMap[card.skin_id]
		else:
			newSkillList = cfg.skillList

		if oldSkinID and oldSkinID in cfg.skinSkillMap:
			oldSkillList = cfg.skinSkillMap[oldSkinID]
		else:
			oldSkillList = cfg.skillList

		if newSkillList == oldSkillList:
			return

		for k, newSkillID in enumerate(newSkillList):
			oldSkillID = oldSkillList[k]
			skillLevel = card.skills.get(oldSkillID, None)
			if skillLevel:
				newSkills[newSkillID] = skillLevel

		# 皮肤应该不改变星级技能
		for starSkillID in card.starSkillList:
			skillLevel = card.skills.get(starSkillID, None)
			if skillLevel:
				newSkills[starSkillID] = skillLevel

		card.skills = newSkills
		card.init()

	@contextmanager
	def fightingPointChangeParallel(self):
		self._locked = True
		yield self
		self._locked = False
		self.onFightingPointChange()

	def onFightingPointChange(self, card=None):
		if not self._inited or len(self._objs) == 0:
			return

		if card:
			self.fightChangeCards.add(card)
			if self.game.role.pvp_record_db_id:
				self.deploymentForArena.put(card.id)
			if self.game.role.craft_record_db_id:
				self.deploymentForCraft.put(card.id)
			if self.game.role.cross_craft_record_db_id:
				self.deploymentForCrossCraft.put(card.id)
			if card.id == self.game.role.clone_deploy_card_db_id:
				cardD = card.battleModel(False, False, SceneDefs.Clone)
				cardD2 = None
				if card.twinFlag:
					cardD2 = card2twin(card).battleModel(False, False, SceneDefs.Clone)
				self.fightChangeCloneDeployCard = [cardD, cardD2]
			if self.game.role.union_fight_record_db_id:
				self.deploymentForUnionFight.put(card.id)
			if self.game.role.cross_arena_record_db_id:
				self.deploymentForCrossArena.put(card.id)
			if self.game.role.cross_online_fight_record_db_id:
				self.deploymentForCrossOnlineFight.put(card.id)
			if self.game.role.gym_record_db_id:
				self.deploymentForGym.put(card.id)
			if self.game.role.cross_mine_record_db_id:
				self.deploymentForCrossMine.put(card.id)
			if self.game.role.cross_union_fight_record_db_id:
				self.deploymentForCrossUnionFight.put(card.id)

			markIDMaxFight = self.markIDMaxFight.get(card.markID, ('', 0))
			if markIDMaxFight[1] < card.fighting_point:
				self.markIDMaxFight[card.markID] = (card.id, card.fighting_point)
				self.markIDMaxFightChangeCards[card.markID] = card
			elif markIDMaxFight[1] >= card.fighting_point and markIDMaxFight[0] == card.id:
				self.game.refreshMarkMaxFight = True

		if self._locked:
			return

		# 计算默认阵容总战力
		objs = self.getCards(self.game.role.battle_cards)
		fightingPoint = sum([o.fighting_point for o in objs])
		self.game.role.battle_fighting_point = fightingPoint
		ObjectYYHuoDongFactory.onVIPOrFightPointChanged(self.game)

		# 计算单卡牌最高战力和top6战力
		objs = self._objs.values()
		objs.sort(key=lambda o: o.fighting_point, reverse=True)
		fightingPoint = sum([o.fighting_point for o in objs[:6]])
		if fightingPoint > self.game.role.top6_fighting_point:
			self.game.role.top6_fighting_point = fightingPoint
		fightingPoint += sum([o.fighting_point for o in objs[6:12]])
		if fightingPoint > self.game.role.top12_fighting_point:
			self.game.role.top12_fighting_point = fightingPoint
		self.maxFightPointCardID = objs[0].id
		top20Cards = set()
		for i in xrange(20):
			if i >= len(objs):
				break
			if objs[i]:
				top20Cards.add(objs[i].id)
		self.top20Cards = top20Cards
		# 前N战力卡牌，craft用，目前N为10, 不足不需要补齐
		markS = set()
		idx = 0
		top = []
		for _ in xrange(12):
			while idx < len(objs):
				card = objs[idx]
				idx += 1
				if card.markID not in markS:
					top.append(card.id)
					markS.add(card.markID)
					break
		self.game.role.top_cards = top

		# 前12战力卡牌，拳皇争霸用，不足10张要补齐
		top12 = [(o.id, o.card_id, o.skin_id) for o in objs[:12]]
		if len(top12) < 12:
			top12 += [(None, 0, 0)] * (12 - len(top12))
		self.game.role.top12_cards = top12
		self.game.role.top10_cards = top12[:10]

	# 战力变动记录
	def refreshMarkIDMaxFight(self):
		newMarkIDMaxFight = {}
		for obj in self._objs.itervalues():
			if obj.markID not in newMarkIDMaxFight:
				newMarkIDMaxFight[obj.markID] = (obj.id, obj.fighting_point)
			elif newMarkIDMaxFight[obj.markID][1] < obj.fighting_point:
				newMarkIDMaxFight[obj.markID] = (obj.id, obj.fighting_point)
		for markID, newFP in newMarkIDMaxFight.iteritems():
			if markID not in self.markIDMaxFight or self.markIDMaxFight[markID][1] != newFP[1]:
				self.markIDMaxFight[markID] = newFP
				self.markIDMaxFightChangeCards[markID] = self.getCard(newFP[0])
		for markID in self.markIDMaxFight.keys():
			if markID not in newMarkIDMaxFight:
				del self.markIDMaxFight[markID]
				self.markIDMaxFightChangeCards[markID] = {}

	def getMaxFightPointCard(self):
		return self._objs.get(self.maxFightPointCardID)

	def getSevenStarCardSum(self):
		cnt = 0
		for card in self._objs.itervalues():
			if card.star >= 7:
				cnt += 1
		return cnt

	def isDuplicateMarkID(self, cardIDs):
		hset = set()
		for idx in cardIDs:
			if not idx:
				continue
			card = self.getCard(idx)
			markID = card.markID
			if markID in hset:
				return True
			hset.add(markID)
		return False

	def syncTrainingExp(self, exps):
		if not exps:
			return
		for cardID, exp in exps.iteritems():
			card = self.getCard(cardID)
			if card:
				card.exp += exp

	@property
	def deployment(self):
		d = {
			'arena': self.deploymentForArena.cards,
			'union_training': self.deploymentForUnionTraining.cards,
			'craft': {},
			'cross_craft': {},
			'union_fight': {},
			'cross_arena': {},
			'gym': {},
			'cross_mine': {},
			'cross_union_fight': {},
		}
		if self.game.dailyRecord.craft_sign_up and ObjectCraftInfoGlobal.isInSign():
			d['craft'] = self.deploymentForCraft.cards
		if ObjectCrossCraftGameGlobal.isInSign(self.game.role.areaKey) and ObjectCrossCraftGameGlobal.isSigned(self.game):
			d['cross_craft'] = self.deploymentForCrossCraft.cards
		if self.game.dailyRecord.union_fight_sign_up and ObjectUnionFightGlobal.isInSign():
			for k, cards in self.deploymentForUnionFight.cards.iteritems():
				d['union_fight'][k] = [i for i in cards if i]
		if ObjectCrossArenaGameGlobal.isOpen(self.game.role.areaKey) and ObjectCrossArenaGameGlobal.isRoleOpen(self.game.role.level):
			d['cross_arena'] = self.deploymentForCrossArena.cards
		if ObjectGymGameGlobal.isRoleOpen(self.game.role.level):
			d['gym'] = self.deploymentForGym.cards
		if ObjectCrossMineGameGlobal.isOpen(self.game.role.areaKey) and ObjectCrossMineGameGlobal.isRoleOpen(self.game.role.level):
			d['cross_mine'] = self.deploymentForCrossMine.cards
		if self.game.role.cross_union_fight_record_db_id and ObjectCrossUnionFightGameGlobal.isCrossOpen(self.game.role.areaKey):
			if ObjectCrossUnionFightGameGlobal.isInJoinRoles(self.game.role.areaKey, self.game.role.id):
				for k, cards in self.deploymentForCrossUnionFight.cards.iteritems():
					d['cross_union_fight'][k] = [i for i in cards if i]
		return d

	def inusing(self, cardID):
		# 1.battle_card
		if cardID in self.game.role.battle_cards:
			return True
		# 2.huodong_card # 活动副本，PVE玩法会自动下阵
		# for _, cards in self.game.role.huodong_cards.iteritems():
		# 	if cardID in cards:
		# 		return True
		# 3.arean
		if self.deploymentForArena.inusing(cardID, key='defence_cards'):
			return True
		# 4.union training
		if self.deploymentForUnionTraining.inusing(cardID):
			return True
		# 4. craft # 报名阶段不能分解
		if self.game.dailyRecord.craft_sign_up and ObjectCraftInfoGlobal.isInSign():
			if self.deploymentForCraft.inusing(cardID):
				return True
		# 5. clone 元素挑战不能分解
		if cardID == self.game.role.clone_deploy_card_db_id:
			return True
		# 6. cross craft # 报名阶段不能分解
		if ObjectCrossCraftGameGlobal.isInSign(self.game.role.areaKey) and ObjectCrossCraftGameGlobal.isSigned(self.game):
			if self.deploymentForCrossCraft.inusing(cardID):
				return True
		# 7. union_fight # 报名阶段不能分解
		if self.game.dailyRecord.union_fight_sign_up and ObjectUnionFightGlobal.isInSign():
			if self.deploymentForUnionFight.inusing(cardID):
				return True
		# 8.cross arena
		if ObjectCrossArenaGameGlobal.isOpen(self.game.role.areaKey) and ObjectCrossArenaGameGlobal.isRoleOpen(self.game.role.level):
			if self.deploymentForCrossArena.inusing(cardID, key='defence_cards'):
				return True
		# 9.gym
		if ObjectGymGameGlobal.isRoleOpen(self.game.role.level):
			if self.deploymentForGym.inusing(cardID, key='cards'):
				return True
			if self.deploymentForGym.inusing(cardID, key='cross_cards'):
				return True
		# 10.badge
		if self.game.cards.getCard(cardID).badge_guard:
			return True
		# 11.cross mine
		if ObjectCrossMineGameGlobal.isOpen(self.game.role.areaKey) and ObjectCrossMineGameGlobal.isRoleOpen(self.game.role.level):
			if self.deploymentForCrossMine.inusing(cardID, key='defence_cards'):
				return True
		# 12. cross_union_fight 初/决准备战斗期间不给分解
		role = self.game.role
		if not ObjectCrossUnionFightGameGlobal.canDecompose(role.areaKey) and role.cross_union_fight_record_db_id and ObjectCrossUnionFightGameGlobal.isInJoinRoles(role.areaKey, role.id):
			if self.deploymentForCrossUnionFight.inusing(cardID):
				return True
		return False

	def fillupByTopCards(self,delCards, cards, length):
		cards = filter(lambda x: x and self.getCard(x), cards)
		existed = set(cards)
		markIDs = set([self.getCard(cardID).markID for cardID in existed])

		objs = self._objs.values()
		objs.sort(key=lambda o: o.fighting_point, reverse=True)
		for card in objs:
			if not (card.markID in markIDs or card.id in existed or card.id in delCards):
				cards.append(card.id)
				markIDs.add(card.markID)
			if len(cards) >= length:
				break
		return cards[:length]

	def getCardsRankModel(self, cardIDs):
		ret = []
		for cardID in cardIDs:
			if not cardID:
				ret.append(None)
				continue

			card = self.getCard(cardID)
			if not card:
				ret.append(None)
				continue

			ret.append(card.rankModel)

		return ret

	def cardConvertMegaItems(self, csvID, costCard):
		'''
		超进化 精灵 转化 进化石/钥石
		'''
		cfgConvert = csv.card_mega_convert[csvID]
		# 转化数量
		num = cfgConvert.cardConvertNum
		needSpecialCards = cfgConvert.needSpecialCards
		flag = False
		if needSpecialCards and costCard.card_id in needSpecialCards:
			flag = True
		else:
			for i in xrange(1, 99):
				k = "needCards%d" % i
				if k not in cfgConvert or not cfgConvert[k]:
					break
				rarity, nature = cfgConvert[k]
				# 稀有度
				if costCard.rarity == rarity:
					# 自然属性
					if nature == -1 or costCard.natureType == nature or costCard.natureType2 == nature:
						flag = True
						break
		if not flag:
			raise ClientError('costCardID error')

		# 判断转化次数是否足够
		times = self.game.role.mega_convert_times.get(csvID, 0)
		if times < num:
			raise ClientError(ErrDefs.megaConvertLimit)

		# 消耗
		costAux = ObjectCostAux(self.game, cfgConvert.costItemCard)
		costAux.setCostCards([costCard])
		if not costAux.isEnough():
			raise ClientError(ErrDefs.costNotEnough)
		costAux.cost(src='mega_convert_card')

		self.game.role.mega_convert_times[csvID] = times - num
		return num

	def fragConvertMegaItems(self, csvID, num, costFragID):
		'''
		超进化 碎片 转化 进化石/钥石
		'''
		cfgConvert = csv.card_mega_convert[csvID]
		fragQuality, unitNature = FragmentDefs.getFragAttr(csv, costFragID)
		costFragNum = 0
		for i in xrange(1, 99):
			k = "needFrags%d" % i
			if k not in cfgConvert or not cfgConvert[k]:
				break
			# 判断碎片是否如何条件
			quality, nature, fragNum = cfgConvert[k]
			if fragQuality == quality and nature in unitNature+(-1,):
				costFragNum = fragNum
				break
		if not costFragNum:
			raise ClientError('costFragID error')

		# 判断转化次数是否足够
		times = self.game.role.mega_convert_times.get(csvID, 0)
		if times < num:
			raise ClientError(ErrDefs.megaConvertLimit)

		# 消耗
		costAux = ObjectCostAux(self.game, cfgConvert.costItemFrag)
		costAux += ObjectCostAux(self.game, {costFragID: costFragNum})
		costAux *= num
		if not costAux.isEnough():
			raise ClientError(ErrDefs.costNotEnough)
		costAux.cost(src='mega_convert_frag')

		self.game.role.mega_convert_times[csvID] = times - num

	def getCardFightUpdateInfo(self):
		updateInfo = {}
		for markID, card in self.markIDMaxFightChangeCards.iteritems():
			if card:
				updateInfo[markID] = card.rankModel
			else:
				updateInfo[markID] = {}
		return updateInfo

'''
重生
'''
class ObjectCardRebirthBase(ObjectBase):

	@classmethod
	def classInit(cls):
		ObjectCardRebirthAdvance.classInit()
		ObjectCardRebirthSkill.classInit()
		ObjectCardRebirthEquip.classInit()
		ObjectCardRebirthLevel.classInit()
		ObjectCardRebirthAbility.classInit()

	def __init__(self, game, card):
		ObjectBase.__init__(self, game)
		self.card = card

	def getEffect(self, retrunProportion):
		if not self.isValid():
			return None

		returnItems = self.getReturnItems()
		for k in returnItems:
			prop = retrunProportion
			if k == 'skill_point':
				prop = ConstDefs.rebirthRetrunProportion5 # 技能点单独返还比例
			returnItems[k] = int(math.ceil(prop * returnItems[k]))
		eff = ObjectGainAux(self.game, returnItems)
		return eff

	def isValid(self):
		raise Exception('not implemented')

	def rebirth(self):
		raise Exception('not implemented')

	def getReturnItems(self):
		raise Exception('not implemented')

	@classmethod
	def rebirthCost(cls, returnItems, type):
		'''
		重生消耗
		'''
		costRmb = 0
		for k in returnItems:
			if k == 'gold':
				costRmb += int(math.ceil(float(returnItems[k]) / ConstDefs.rebirthRMBCostByGold))
			elif FragmentDefs.isFragmentID(k):
				costRmb += csv.fragments[k].rebirthRMB * returnItems[k]
			elif HeldItemDefs.isHeldItemID(k):
				costRmb += csv.held_item.items[k].rebirthRMB * returnItems[k]
			elif ItemDefs.isItemID(k):
				costRmb += csv.items[k].rebirthRMB * returnItems[k]
		if costRmb == 0: # 消耗为0，没进行过养成, 不消耗
			return 0

		rmb = 0
		last = None
		for i in sorted(csv.rebirth_rmb_cost.keys()):
			cfg = csv.rebirth_rmb_cost[i]
			if cfg.type != type:
				continue
			if cfg.rmbPoint == 0:
				last = cfg
				continue
			if costRmb > cfg.rmbPoint:
				rmb += (cfg.rmbPoint - last.rmbPoint) * cfg.rmbRate
			else:
				rmb += (costRmb - last.rmbPoint) * cfg.rmbRate
				break
			last = cfg

		if type == CardResetDefs.heldItemRmbCostType:
			rmb = min(rmb, ConstDefs.heldItemRebirthRMBCostLimit)
			rmb = max(rmb, ConstDefs.heldItemRebirthRMBCostMin)
		elif type == CardResetDefs.gemCostType:
			rmb = min(rmb, ConstDefs.gemRebirthRMBCostLimit)
			rmb = max(rmb, ConstDefs.gemRebirthRMBCostMin)
		elif type == CardResetDefs.chipCostType:
			rmb = min(rmb, ConstDefs.chipRebirthRMBCostLimit)
			rmb = max(rmb, ConstDefs.chipRebirthRMBCostMin)
		else:
			rmb = min(rmb, ConstDefs.rebirthRMBCostLimit)
			rmb = max(rmb, ConstDefs.cardRebirthRMBCostMin)
		# 向上取整，与客户端保持一致
		return int(math.ceil(rmb))

	@classmethod
	def dictSum(cls, d1, d2):
		''' 把d2的内容加到d1里'''
		t = copy.copy(d2)
		for key in d1:
			if key in t:
				t[key] += d1[key]
		d1.update(t)


'''
advance
'''
class ObjectCardRebirthAdvance(ObjectCardRebirthBase):
	ReturnMap = {} # {(typeID,stage):{items,gold}}

	@classmethod
	def classInit(cls):
		cls.ReturnMap = {}
		# 生成不同阶卡牌返还物品的字典
		lastTypeID = -1
		lastItems = {}

		for i in sorted(csv.base_attribute.advance_level.keys()):
			csvAdvance = csv.base_attribute.advance_level[i]
			typeID = csvAdvance.typeID
			stage = csvAdvance.stage
			t = copy.copy(csvAdvance.itemMap)
			t.update({'gold':csvAdvance.gold})

			if typeID == lastTypeID:
				ObjectCardRebirthBase.dictSum(lastItems, t)
				cls.ReturnMap[(typeID, stage)] = copy.copy(lastItems)
			else:
				lastTypeID = typeID
				lastItems = t
				cls.ReturnMap[(typeID, stage)] = copy.copy(lastItems)

	def isValid(self):
		return self.card.advance > 1

	def rebirth(self):
		self.card.advance = 1

	def getReturnItems(self):
		if self.card.advance > 1:
			return copy.deepcopy(ObjectCardRebirthAdvance.ReturnMap[(self.card.advanceTypeID, self.card.advance - 1)])
		return {}

'''
skill
'''
class ObjectCardRebirthSkill(ObjectCardRebirthBase):
	ReturnMap = {}

	@classmethod
	def classInit(cls):
		cls.ReturnMap = {}
		for i in sorted(csv.base_attribute.skill_level.keys()):
			skillConfig = csv.base_attribute.skill_level[i]
			for j in xrange(1, 99):
				if not hasattr(skillConfig, 'gold%d'%j):
					break
				if j not in cls.ReturnMap:
					cls.ReturnMap[j] = {}
				if i > 1:
					cls.ReturnMap[j][i] = cls.ReturnMap[j][i-1] + getattr(skillConfig, 'gold%d'%j)
				else:
					cls.ReturnMap[j][i] = getattr(skillConfig, 'gold%d'%j)

	def isValid(self):
		for skillID, level in self.card.skills.iteritems():
			if skillID in self.card.starSkillList:
				continue
			if level > 1:
				return True
		return False

	def rebirth(self):
		for idx, skillID in enumerate(self.card.skillList):
			if skillID in self.card.skills:
				self.card.skill_level[idx] = 1
				self.card.skills[skillID] = 1

	def getReturnItems(self):
		gold = 0
		point = 0
		for skillID in self.card.skills:
			if skillID in self.card.starSkillList:
				continue
			costID = csv.skill[skillID]['costID']
			level = self.card.skills[skillID]
			if level < 2:
				continue
			gold += ObjectCardRebirthSkill.ReturnMap[costID][level-1]
			point += level - 1

		return {'gold': gold, 'skill_point': point}

'''
equip
'''
class ObjectCardRebirthEquip(ObjectCardRebirthBase):
	# self.card.equips  =>  {1: {equipd_id, star, level, advance, exp, awake}, 2: {...}, ...}
	LevelGoldMap = {}
	AdvanceItemMap = {}
	StarMap = {}
	AwakeMap = {}
	AbilityMap = {}
	SignetMap = {}
	SignetAdvanceMap = {}
	AwakeAbilityMap = {}

	@classmethod
	def classInit(cls):
		cls.LevelGoldMap = {}
		cls.AdvanceItemMap = {}
		cls.StarMap = {}
		cls.AwakeMap = {}
		cls.AbilityMap = {}
		cls.SignetMap = {}
		cls.SignetAdvanceMap = {}
		cls.AwakeAbilityMap = {}
		for i in sorted(csv.base_attribute.equip_strength.keys()):
			config = csv.base_attribute.equip_strength[i]
			for j in xrange(1, 99):
				if not hasattr(config, 'costGold%d'%j):
					break
				if j not in cls.LevelGoldMap:
					cls.LevelGoldMap[j] = {}
				if i > 1:
					cls.LevelGoldMap[j][i] = cls.LevelGoldMap[j][i-1] + getattr(config, 'costGold%d'%j)
				else:
					cls.LevelGoldMap[j][i] = getattr(config, 'costGold%d'%j)

		lastEquipID = -1
		lastItems = {}
		for i in sorted(csv.base_attribute.equip_advance.keys()):
			csvAdvance = csv.base_attribute.equip_advance[i]
			equipID = csvAdvance.equip_id
			stage = csvAdvance.stage
			t = copy.copy(csvAdvance.costItemMap)
			t.update({'gold': csvAdvance.costGold})

			if equipID == lastEquipID:
				ObjectCardRebirthBase.dictSum(lastItems, t)
				cls.AdvanceItemMap[(equipID, stage)] = copy.copy(lastItems)
			else:
				lastEquipID = equipID
				lastItems = t
				cls.AdvanceItemMap[(equipID, stage)] = copy.copy(lastItems)

		for i in sorted(csv.base_attribute.equip_star.keys()):
			csvStar = csv.base_attribute.equip_star[i]
			for j in xrange(1, 99):
				if not hasattr(csvStar, 'costItemMap%d'%j):
					break
				if j not in cls.StarMap:
					cls.StarMap[j] = {}
				if i > 0:
					items = copy.copy(cls.StarMap[j][i-1])
					ObjectCardRebirthBase.dictSum(items, getattr(csvStar, 'costItemMap%d'%j))
					cls.StarMap[j][i] = items
				else:
					cls.StarMap[j][i] = getattr(csvStar, 'costItemMap%d'%j)

		for i in sorted(csv.base_attribute.equip_awake.keys()):
			csvAwake = csv.base_attribute.equip_awake[i]
			for j in xrange(1, 99):
				if not hasattr(csvAwake, 'costItemMap%d'%j):
					break
				if j not in cls.AwakeMap:
					cls.AwakeMap[j] = {}
				if i > 0:
					items = copy.copy(cls.AwakeMap[j][i-1])
					ObjectCardRebirthBase.dictSum(items, getattr(csvAwake, 'costItemMap%d'%j))
					cls.AwakeMap[j][i] = items
				else:
					cls.AwakeMap[j][i] = getattr(csvAwake, 'costItemMap%d'%j)

		for i in sorted(csv.base_attribute.equip_ability.keys()):
			csvAbility = csv.base_attribute.equip_ability[i]
			for j in xrange(1, 99):
				if not hasattr(csvAbility, 'costItemMap%d'%j):
					break
				if j not in cls.AbilityMap:
					cls.AbilityMap[j] = {}
				if i > 0:
					items = copy.copy(cls.AbilityMap[j][i-1])
					ObjectCardRebirthBase.dictSum(items, getattr(csvAbility, 'costItemMap%d'%j))
					cls.AbilityMap[j][i] = items
				else:
					cls.AbilityMap[j][i] = getattr(csvAbility, 'costItemMap%d'%j)

		for i in sorted(csv.base_attribute.equip_signet.keys()):
			csvSignet = csv.base_attribute.equip_signet[i]
			for j in xrange(1, 99):
				if not hasattr(csvSignet, 'costItemMap%d'%j):
					break
				if j not in cls.SignetMap:
					cls.SignetMap[j] = {}
				if i > 0:
					items = copy.copy(cls.SignetMap[j][i-1])
					ObjectCardRebirthBase.dictSum(items, getattr(csvSignet, 'costItemMap%d'%j))
					cls.SignetMap[j][i] = items
				else:
					cls.SignetMap[j][i] = getattr(csvSignet, 'costItemMap%d'%j)

		for i in sorted(csv.base_attribute.equip_signet_advance_cost.keys()):
			csvSignetAdvance = csv.base_attribute.equip_signet_advance_cost[i]
			for j in xrange(1, 99):
				if not hasattr(csvSignetAdvance, 'costItemMap%d'%j):
					break
				if j not in cls.SignetAdvanceMap:
					cls.SignetAdvanceMap[j] = {}
				if i > 0:
					items = copy.copy(cls.SignetAdvanceMap[j][i-1])
					ObjectCardRebirthBase.dictSum(items, getattr(csvSignetAdvance, 'costItemMap%d'%j))
					cls.SignetAdvanceMap[j][i] = items
				else:
					cls.SignetAdvanceMap[j][i] = getattr(csvSignetAdvance, 'costItemMap%d'%j)

		for i in sorted(csv.base_attribute.equip_awake_ability.keys()):
			csvAwakeAbility = csv.base_attribute.equip_awake_ability[i]
			for j in xrange(1, 99):
				if not hasattr(csvAwakeAbility, 'costItemMap%d'%j):
					break
				if j not in cls.AwakeAbilityMap:
					cls.AwakeAbilityMap[j] = {}
				if i > 0:
					items = copy.copy(cls.AwakeAbilityMap[j][i-1])
					ObjectCardRebirthBase.dictSum(items, getattr(csvAwakeAbility, 'costItemMap%d'%j))
					cls.AwakeAbilityMap[j][i] = items
				else:
					cls.AwakeAbilityMap[j][i] = getattr(csvAwakeAbility, 'costItemMap%d'%j)

	def isValid(self):
		for _, equip in self.card.equips.iteritems():
			if equip['level'] > 1 or equip['advance'] > 1 or equip['star'] > 0 or equip['awake'] > 0 or equip['signet'] > 0 or equip['awake_ability'] > 0:
				return True
		return False

	def rebirth(self):
		# equipsList = csv.cards[self.card.card_id].equipsList
		for i in self.card.equips.keys():
			self.card.equips[i]['level'] = 1
			self.card.equips[i]['advance'] = 1
			self.card.equips[i]['star'] = 0
			self.card.equips[i]['awake'] = 0
			self.card.equips[i]['ability'] = 0
			self.card.equips[i]['signet'] = 0
			self.card.equips[i]['signet_advance'] = 0
			self.card.equips[i]['awake_ability'] = 0

	def getReturnItems(self):
		ret = {}
		# equipsList = csv.cards[self.card.card_id].equipsList
		for i in self.card.equips.keys():
			eId = self.card.equips[i]['equip_id']
			level = self.card.equips[i]['level']
			advance = self.card.equips[i]['advance']
			star = self.card.equips[i]['star']
			awake = self.card.equips[i]['awake']
			ability = self.card.equips[i]['ability']
			signet = self.card.equips[i]['signet']
			signetAdvance = self.card.equips[i]['signet_advance']
			awakeAbility = self.card.equips[i]['awake_ability']
			strengthSeqID = csv.equips[eId].strengthSeqID
			starSeqID = csv.equips[eId].starSeqID
			awakeSeqID = csv.equips[eId].awakeSeqID
			abilitySeqID = csv.equips[eId].abilitySeqID
			signetSeqID = csv.equips[eId].signetStrengthSeqID
			advanceIndex = csv.equips[eId].advanceIndex
			signetAdvanceSeqID = ObjectEquip.SignetAdvanceMap[(advanceIndex, 1)].advanceSeqID
			awakeAbilitySeqID = csv.equips[eId].awakeAbilitySeqID
			items = {}
			if level >= 2:
				gold = ObjectCardRebirthEquip.LevelGoldMap[strengthSeqID][level-1]
				ObjectCardRebirthBase.dictSum(items, {'gold': gold})
			if advance >= 2:
				advanceItems = copy.deepcopy(ObjectCardRebirthEquip.AdvanceItemMap[(eId, advance-1)])
				ObjectCardRebirthBase.dictSum(items, advanceItems)
			if star >= 1:
				starItems = ObjectCardRebirthEquip.StarMap[starSeqID][star-1]
				ObjectCardRebirthBase.dictSum(items, starItems)
			if awake >= 1:
				awakeItems = ObjectCardRebirthEquip.AwakeMap[awakeSeqID][awake-1]
				ObjectCardRebirthBase.dictSum(items, awakeItems)
			if ability >= 1:
				abilityItems = ObjectCardRebirthEquip.AbilityMap[abilitySeqID][ability-1]
				ObjectCardRebirthBase.dictSum(items, abilityItems)
			if signet >= 1:
				signetItems = ObjectCardRebirthEquip.SignetMap[signetSeqID][signet-1]
				ObjectCardRebirthBase.dictSum(items, signetItems)
			if signetAdvance >= 1:
				signetAdvanceItems = ObjectCardRebirthEquip.SignetAdvanceMap[signetAdvanceSeqID][signetAdvance-1]
				ObjectCardRebirthBase.dictSum(items, signetAdvanceItems)
			if awakeAbility >= 1:
				awakeAbilityItems = ObjectCardRebirthEquip.AwakeAbilityMap[awakeAbilitySeqID][awakeAbility-1]
				ObjectCardRebirthBase.dictSum(items, awakeAbilityItems)
			ObjectCardRebirthBase.dictSum(ret, items)

		return ret


'''
level
'''
class ObjectCardRebirthLevel(ObjectCardRebirthBase):
	@classmethod
	def classInit(cls):
		pass

	def isValid(self):
		return self.card.exp > 0

	def rebirth(self):
		self.card.exp = 0

	def getReturnItems(self):
		exp = self.card.exp
		ret = {}
		for itemID in xrange(16, 10, -1):
			cfg = csv.items[itemID]
			texp = cfg.specialArgsMap['exp']
			count = int(exp / texp)
			if count > 0:
				exp -= count * texp
				ret[itemID] = count
		return ret


'''
ability
'''
class ObjectCardRebirthAbility(ObjectCardRebirthBase):
	AbilityMap = {}

	@classmethod
	def classInit(cls):
		cls.AbilityMap = {}
		for i in sorted(csv.card_ability_cost.keys()):
			csvAbility = csv.card_ability_cost[i]
			for j in xrange(1, 99):
				if not hasattr(csvAbility, 'costItemMap%d' % j):
					break
				if j not in cls.AbilityMap:
					cls.AbilityMap[j] = {}
				items = copy.copy(cls.AbilityMap[j].get(i-1, {}))
				ObjectCardRebirthBase.dictSum(items, getattr(csvAbility, 'costItemMap%d' % j))
				cls.AbilityMap[j][i] = items

	def isValid(self):
		for _, level in self.card.abilities.iteritems():
			if level > 0:
				return True
		return False

	def rebirth(self):
		for i in self.card.abilities.keys():
			self.card.abilities[i] = 0

	def getReturnItems(self):
		ret = {}
		abilitySeqID = self.card.abilitySeqID
		for position, level in self.card.abilities.iteritems():
			cfg = ObjectCard.CardAbilityMap[(abilitySeqID, position)]
			if level >= 1:
				abilityItems = ObjectCardRebirthAbility.AbilityMap[cfg.strengthSeqID][level]
				ObjectCardRebirthBase.dictSum(ret, abilityItems)
		return ret


'''
简单工厂
'''
class ObjectCardRebirthFactory(ReloadHooker):
	clsMap = {}

	@classmethod
	def classInit(cls):
		cls.clsMap = {
			'advance': ObjectCardRebirthAdvance,
			'skill': ObjectCardRebirthSkill,
			'equip': ObjectCardRebirthEquip,
			'level': ObjectCardRebirthLevel,
			'ability': ObjectCardRebirthAbility,
		}

	@classmethod
	def getRebirthCls(cls, rebirthType):
		return cls.clsMap.get(rebirthType)


class ObjectCardDeployment(object):

	def __init__(self):
		self._dirty = set([])
		self._cards = {} # {key: [cardID, ...]}

	@property
	def cards(self):
		return self._cards

	def isdirty(self):
		if self._dirty:
			return True
		return False

	def getdirty(self, key):
		if not self._cards:
			return
		v = []
		for vv in self._cards[key]:
			if vv in self._dirty:
				v.append(vv)
			else:
				v.append(None)
		return v

	def resetdirty(self):
		self._dirty.clear()

	def put(self, cardID):
		if not self._cards:
			return
		self._dirty.add(cardID)

	def deploy(self, key, cards):
		# dict identity not change, dict_sync consider content not change.
		self._cards = copy.copy(self._cards)
		self._cards[key] = cards

	def inusing(self, cardID, key=None):
		if key:
			if key not in self._cards:
				return False
			return cardID in self._cards[key]
		for _, v in self._cards.iteritems():
			if cardID in v:
				return True
		return False

	def filter(self, key, cards):
		if key not in self._cards:
			return None

		valids = []
		hit = False
		for vv in self._cards[key]:
			if vv in cards:
				valids.append(None)
				hit = True
			else:
				valids.append(vv)
		if hit:
			return valids
		return None

	def refresh(self, key, scene, cards=None):
		if cards is None:
			cards = self._cards[key]
			dirty = self.getdirty(key)
			return cards, dirty
		else:
			self.deploy(key, cards)
			return cards, None

	def isExist(self, key):
		return key in self._cards

	def resetCards(self):
		self._cards.clear()

	def popCardsByKey(self, key):
		self._cards = copy.copy(self._cards)
		self._cards.pop(key, [])


def appendCardAttrsAddition(model, const, percent):
	for attr, val in percent.iteritems():
		if val > 0:
			model['attrs'][attr] *= (1 + val)
	for attr, val in const.iteritems():
		if val > 0:
			model['attrs'][attr] += val
	return model

def emptyFunc(self, **kwargs):
	pass

def card2twin(card):
	branch = 1
	if card.branch == 1:
		branch = 2

	import types
	db = copy.deepcopy(card.db)
	twin = ObjectCard(card.game, None) # 没有 dbc
	twin.new_deepcopy() # just for delete dbc
	twin.set(db).initTwin()
	twin.init = twin.initTwin
	twin.onUpdateAttrs = types.MethodType(emptyFunc, twin)
	twin.onFightingPointChange = types.MethodType(emptyFunc, twin)
	nextCardID = ObjectCard.CardMarkDevelopMap.get((twin.markID, branch, twin.develop))
	cfg = csv.cards[nextCardID]
	twin.developNextChange(cfg, card.develop, nextCardID)
	return twin
