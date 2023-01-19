#!/usr/bin/python
# coding=utf-8
import copy
from collections import defaultdict

from framework import str2num_t
from framework.csv import csv
from framework.log import logger
from framework.object import ObjectDBase, ObjectBase
from game import ClientError
from game.object import TargetDefs
from game.object.game.calculator import zeros
from game.object.game.gain import ObjectCostAux, ObjectGainAux
from game.object.game.yyhuodong import ObjectYYHuoDongFactory
from game.thinkingdata import ta


#
# ObjectExplorer
#
class ObjectExplorer(ObjectBase):

	ComponentExplorerMap = {}  # {componentCsvID: (explorerCsvID, maxLevel)}
	ComponentAddition = {} # {(component.id, level): (const, percent)}
	EffectAddition = {} # {(effect.id, advance): (const, percent)}
	EffectExplorerMap = {}  # {effectCsvID: (explorerCsvID, maxLevel)}

	@classmethod
	def classInit(cls):
		# 组件位 => 探险器
		cls.ComponentExplorerMap = {}
		cls.EffectExplorerMap = {}
		for i in csv.explorer.explorer:
			cfg = csv.explorer.explorer[i]
			for cID in cfg.componentIDs:
				cls.ComponentExplorerMap[cID] = (i, cfg.levelMax)
			for eID in cfg.effect:
				cls.EffectExplorerMap[eID] = (i, cfg.levelMax)
			for eID in cfg.extraEff:
				cls.EffectExplorerMap[eID] = (i, cfg.levelMax)

		cls.ComponentAddition = {}
		for componentCsvID in csv.explorer.component:
			if componentCsvID not in cls.ComponentExplorerMap:
				continue
			cfg = csv.explorer.component[componentCsvID]
			_, maxLevel = cls.ComponentExplorerMap.get(componentCsvID, (0, 0))
			for l in range(maxLevel):
				level = l+1
				key = (componentCsvID, level)
				c, p = zeros(), zeros()
				for i in xrange(1, 99):
					attrKey = "attrNumType%d" % i
					attrNumKey = "attrNum%d" % i
					if attrKey not in cfg or not cfg[attrKey]:
						break
					attr = cfg[attrKey]
					num = str2num_t(cfg[attrNumKey][level - 1])
					c[attr] += num[0]
					p[attr] += num[1]
				cls.ComponentAddition[key] = (c, p)

		cls.EffectAddition = {}
		for effectCsvID in csv.explorer.explorer_effect:
			if effectCsvID not in cls.EffectExplorerMap:
				continue
			cfg = csv.explorer.explorer_effect[effectCsvID]
			_, maxLevel = cls.EffectExplorerMap.get(effectCsvID, (0, 0))
			if cfg.effectType == 1:  # 1-属性；2-技能
				for l in range(maxLevel):
					advance = l + 1
					key = (effectCsvID, advance)
					c, p = zeros(), zeros()
					for i in xrange(1, 99):
						attrKey = "attrType%d" % i
						attrNumKey = "attrNum%d" % i
						if attrKey not in cfg or not cfg[attrKey]:
							break
						attr = cfg[attrKey]
						num = str2num_t(cfg[attrNumKey][advance - 1])
						c[attr] += num[0]
						p[attr] += num[1]
					cls.EffectAddition[key] = (c, p)

	def set(self):
		self._explorers = self.game.role.explorers
		return ObjectBase.set(self)

	def init(self):
		self._passive_skills = None # 效果被动技能
		self._passive_skills_global = None # 全局效果被动技能
		self._effects = None # 探险器效果
		self._explorerAttrAddition = {} # {natureType: (const, percent)}
		self._componentAttrAddition = {} # {natureType: (const, percent)}
		return ObjectBase.init(self)

	def _fixCorrupted(self):
		# KDYG-4476 探险器-独角爬行器的进阶消耗修正 补偿邮件
		from datetime import datetime
		date = datetime(2020, 5, 1, 4, 30)
		# date = datetime(2020, 4, 29, 15, 13)
		from framework import datetimefromtimestamp
		if datetimefromtimestamp(self.game.role.last_time) < date:
			advance = self._explorers.get(5, {}).get('advance', 0)
			if advance > 0 and advance <= 15:
				countMap = {
					1: 300,
					2: 300,
					3: 300,
					4: 385,
					5: 605,
					6: 880,
					7: 1265,
					8: 1760,
					9: 2400,
					10: 3205,
					11: 4230,
					12: 5495,
					13: 7035,
					14: 8885,
					15: 11065,
				}
				attachs = {4000: countMap.get(advance, 0)}
				from game.mailqueue import MailJoinableQueue
				from game.object.game.role import ObjectRole
				mail = self.game.role.makeMyMailModel(120, attachs=attachs)
				MailJoinableQueue.send(mail)
		return

	def componentStrength(self, componentCsvID):
		'''
		组件激活或升级
		'''
		explorerCsvID, maxLevel = self.ComponentExplorerMap.get(componentCsvID, ())
		if not explorerCsvID:
			raise ClientError('csv error')
		cfg = csv.explorer.component[componentCsvID]

		explorer = self._explorers.setdefault(explorerCsvID, {'advance': 0, 'components': {}})
		components = explorer['components']

		# 判断组件位 等级是否已最高
		if components.get(componentCsvID, 0) >= maxLevel:
			raise ClientError('component is MaxLevel')
		# 激活判断是否有组件道具
		if components.get(componentCsvID, 0) == 0 and self.game.role.items.get(cfg.itemID, 0) < 1:
			raise ClientError('not have component')
		# 消耗
		strengthCostSeq = cfg.strengthCostSeq
		costItems = csv.explorer.component_level[components.get(componentCsvID, 0) + 1]['costItemMap%d' % strengthCostSeq]
		cost = ObjectCostAux(self.game, costItems)
		if not cost.isEnough():
			raise ClientError('cost not enough')
		cost.cost(src='explorer_component_strength')

		oldlevel = components.get(componentCsvID, 0)
		components[componentCsvID] = components.get(componentCsvID, 0) + 1
		if oldlevel > 0: # 升级
			ObjectYYHuoDongFactory.onGeneralTask(self.game, TargetDefs.ExplorerComponentStrength, 1)
		self._componentAttrAddition = {}

		ta.track(self.game, event='explorer_component_strength',explorer_id=explorerCsvID,explorer_component_id=componentCsvID,current_component_level=components[componentCsvID],explorer_advance=explorer['advance'])

	@classmethod
	def calcCompoentAttrs(cls, components):
		const, percent = zeros(), zeros()
		for componentCsvID, level in components.iteritems():
			key = (componentCsvID, level)
			v = cls.ComponentAddition.get(key, None)
			if v is not None:
				const += v[0]
				percent += v[1]
		return const, percent

	def getComponentStrengthAttrs(self, card):
		'''
		组件升级加成属性
		'''
		natureType = card.natureType
		v = self._componentAttrAddition.get(natureType, None)
		if v is not None:
			return v

		const, percent = zeros(), zeros()
		for _, explorer in self._explorers.iteritems():
			components = explorer["components"]
			for componentCsvID, level in components.iteritems():
				cfg = csv.explorer.component[componentCsvID]
				if not cfg.attrTarget or natureType in cfg.attrTarget:
					key = (componentCsvID, level)
					value = self.ComponentAddition.get(key, None)
					if value is not None:
						const += value[0]
						percent += value[1]
		self._componentAttrAddition[natureType] = (const, percent)
		return const, percent

	def componentDecompose(self, componentItems):
		'''
		组件分解
		'''
		effAll = ObjectGainAux(self.game, {})
		for itemID, count in componentItems.iteritems():
			eff = ObjectGainAux(self.game, csv.items[itemID].specialArgsMap)
			eff *= count
			effAll += eff

		cost = ObjectCostAux(self.game, componentItems)
		if not cost.isEnough():
			raise ClientError('cost not enough')
		cost.cost(src='explorer_component_decompose')

		return effAll

	def explorerAdvance(self, explorerCsvID):
		'''
		探险器激活或升级
		'''
		explorer = self._explorers.get(explorerCsvID, {})
		if not explorer:
			raise ClientError('not exist this explorer')
		cfg = csv.explorer.explorer[explorerCsvID]
		# 判断是否满级
		if explorer['advance'] >= cfg.levelMax:
			raise ClientError('explorer is MaxLevel')
		# 判断是否满足条件
		components = explorer['components']
		for componentCsvID in cfg.componentIDs:
			if components.get(componentCsvID, 0) < explorer['advance'] + 1:
				raise ClientError('not reach conditions')
		# 消耗
		advanceCostSeq = cfg.advanceCostSeq
		costItems = csv.explorer.explorer_advance[explorer['advance'] + 1]['costItemMap%d' % advanceCostSeq]
		cost = ObjectCostAux(self.game, costItems)
		if not cost.isEnough():
			raise ClientError('cost not enough')
		cost.cost(src='explorer_advance')
		# 激活或升级
		old = explorer.get('advance', 0)
		explorer['advance'] = explorer.get('advance', 0) + 1
		self._passive_skills = None
		self._passive_skills_global = None
		self._effects = None
		self._explorerAttrAddition = {}
		ObjectYYHuoDongFactory.onGeneralTask(self.game, TargetDefs.ExplorerAdvance, 1)
		if old == 0: # 激活
			ObjectYYHuoDongFactory.onGeneralTask(self.game, TargetDefs.Explorer, 0)

		ta.track(self.game, event='explorer_advance',explorer_id=explorerCsvID,explorer_advance=explorer['advance'])

	@classmethod
	def calcEffects(cls, explorers):
		effects = []
		for csvID, explorer in explorers.iteritems():
			advance = explorer['advance']
			# 获取所有已被激活探险器
			if advance > 0:
				cfg = csv.explorer.explorer[csvID]
				# 主效果
				for effect in cfg.effect:
					effects.append((effect, advance))
				# 额外效果（技能或属性）
				for i, val in enumerate(cfg.extraEffCod):
					if val <= advance:
						effects.append((cfg.extraEff[i], advance))
		return effects

	@classmethod
	def calcEffectAttrs(cls, effects, natureType):
		const = zeros()
		percent = zeros()
		for effectid, advance in effects:
			cfg = csv.explorer.explorer_effect[effectid]
			# 需满足 目标和是属性1
			if (not cfg.target or natureType in cfg.target) and cfg.effectType == 1: # 1-属性；2-技能
				key = (effectid, advance)
				v = cls.EffectAddition.get(key, None)
				if v is not None:
					const += v[0]
					percent += v[1]
		return const, percent

	def getEffectAttrByCard(self, card):
		'''
		通过 card 获得 效果属性加成
		'''
		natureType = card.natureType
		v = self._explorerAttrAddition.get(natureType, None)
		if v is not None:
			return v

		if self._effects is None:
			self._effects = self.calcEffects(self._explorers)

		attrs = self.calcEffectAttrs(self._effects, natureType)
		self._explorerAttrAddition[natureType] = attrs
		return attrs

	@classmethod
	def calcPassiveSkills(cls, effects):
		skills = {}
		for effectid, advance in effects:
			cfg = csv.explorer.explorer_effect[effectid]
			if cfg.effectType == 2: # 技能
				skills[cfg.skillID] = advance  # explorer advance is effect passive skill level
		return skills

	def getPassiveSkills(self, isGlobal=False):
		if isGlobal: # 废弃全局被动技能
			return {}

		if isGlobal and self._passive_skills_global is not None:
			return self._passive_skills_global
		if not isGlobal and  self._passive_skills is not None:
			return self._passive_skills

		if self._effects is None:
			self._effects = self.calcEffects(self._explorers)

		skills = self.calcPassiveSkills(self._effects)
		self._passive_skills = skills
		return skills

	def countActiveExplorers(self):
		count = 0
		for _, explorer in self._explorers.iteritems():
			if explorer['advance'] > 0:
				count += 1
		return count
