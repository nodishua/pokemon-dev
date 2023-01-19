#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2014 YouMi Information Technology Inc.
'''
from framework.csv import csv
from framework.log import logger
from game.object.game.calculator import zeros


# 冒险执照属性技能
class FakeTrainer(object):
	def __init__(self, trainer_attr_skills):
		self.trainer_attr_skills = trainer_attr_skills

	def getAttrSkillAddition(self):
		from game.object.game.trainer import ObjectTrainer
		return ObjectTrainer.calcAttrSkillAddition(self.trainer_attr_skills)


# 探险器
class FakeExplorer(object):
	def __init__(self, explorers, components):
		self.explorers = explorers
		self.components = components
		from game.object.game.explorer import ObjectExplorer
		self.effects = ObjectExplorer.calcEffects(self.explorers)

	def getEffectAttrByCard(self, card):
		natureType = card.natureType
		from game.object.game.explorer import ObjectExplorer
		return ObjectExplorer.calcEffectAttrs(self.effects, natureType)

	def getComponentStrengthAttrs(self, card):
		natureType = card.natureType
		from game.object.game.explorer import ObjectExplorer
		components = {}
		for k, v in self.components.iteritems():
			cfg = csv.explorer.component[k]
			if not cfg.attrTarget or natureType in cfg.attrTarget:
				components.setdefault(k, v)
		return ObjectExplorer.calcCompoentAttrs(components)

	def getPassiveSkills(self):
		from game.object.game.explorer import ObjectExplorer
		return ObjectExplorer.calcPassiveSkills(self.effects)


# 公会技能
class FakeUnionSkills(object):
	def __init__(self, union_skills):
		self.union_skills = union_skills
		self.additions = None

	def getUnionSkillAttrsAdd(self, card):
		from game.object.game.role import ObjectRole
		if not self.additions:
			self.additions = ObjectRole.calcUnionSkillAttrAddition(self.union_skills)

		const, percent = zeros(), zeros()
		for natureType, (c, p) in self.additions.iteritems():
			if not natureType or card.natureType == natureType:
				const += c
				percent += p
		return const, percent


# 天赋
class FakeTalentTree(object):
	TalentAttrsMap = None

	def __init__(self, talentTree):
		self.talentTree = talentTree
		from game.object.game.talent import ObjectTalentTree
		self.TalentAttrsMap = ObjectTalentTree.TalentAttrsMap

	def getAttrsAddition(self, card, inFront, inBack, scene):
		from game.object.game.talent import ObjectTalentTree
		const, percent = zeros(), zeros()
		for _, tree in self.talentTree.iteritems():
			for talentID, level in tree.iteritems():
				if level > 0:
					ret = ObjectTalentTree.getAttrs(card, talentID, inFront, inBack, scene)
					for attr, num in ret:
						const[attr] += num[0] * level
						percent[attr] += num[1] * level
		return const, percent


class FakeZawake(object):

	def __init__(self, zawakeID, zawake):
		self._zawakeID = zawakeID
		if self._zawakeID:
			self._zawake = {zawakeID: {}}  # role.zawake
			for i in xrange(1, 9):
				for j in zawake:
					self._zawake[zawakeID][i] = j

	def iterateStageLevel(self):
		'''
		遍历已培养的zawake的生成器
		'''
		for zawakeID in sorted(self._zawake.keys(), reverse=True):  # zawakeID会从大到小遍历
			v = self._zawake[zawakeID]
			for stage, maxLvl in v.iteritems():
				for level in xrange(1, maxLvl + 1):
					yield zawakeID, stage, level

	def dynamicAdd(self, cfg, markID=None, markIDOnly=False):
		'''
		把n个attrAddType遍历，每个符合的都加上相应的属性
		'''
		from game.object.game import ObjectZawake
		from game.object import ZawakeDefs
		from game import ServerError
		attrAddType = getattr(cfg, "attrAddType", ZawakeDefs.CardsAll)
		if attrAddType == ZawakeDefs.MarkID:  # 自身系列卡牌
			if not markID:  # 这里必须有markID
				raise ServerError('bad use of zawake dynamic add')
			const, percent = self._markIDCardAttrAddition.setdefault(markID, (zeros(), zeros()))
			ObjectZawake.calcAddition(cfg, const=const, percent=percent)
		elif not markIDOnly:  # 其他属性也加
			if attrAddType == ZawakeDefs.CardNatureType:  # 指定自然属性
				if not cfg['natureType']:
					raise ServerError('zawake csv %d natureType error', cfg.id)

				const, percent = self._natureCardAttrAddition.setdefault(cfg['natureType'], (zeros(), zeros()))
			elif attrAddType == ZawakeDefs.CardsAll:
				const, percent = self._cardAttrAddition.setdefault(ZawakeDefs.CardsAll, (zeros(), zeros()))
			elif attrAddType == 0:  # 不加成
				pass
			ObjectZawake.calcAddition(cfg, const=const, percent=percent)

	def _initEffectAttrAddition(self, card):
		'''
		计算每一类的加成（自然、markID等）然后记录在缓存中。计算生效的技能。
		'''
		from game.object.game import ObjectZawake

		self._cardAttrAddition = {}  # {(type): (const, percent)}
		self._natureCardAttrAddition = {}  # {(nature): (const, percent)}
		self._markIDCardAttrAddition = {}  # {(markID): (const, percent)}

		# bonus加成
		expSum = sum(
			[ObjectZawake.LevelMap[(zawakeID, stage, level)].exp for zawakeID, stage, level in self.iterateStageLevel()])
		for exp, cfg in ObjectZawake.BonusLevels:
			if expSum < exp:
				break
			self.dynamicAdd(cfg)

		# levels加成
		for zawakeID, stage, level in self.iterateStageLevel():
			markID = ObjectZawake.ZawakeMap[zawakeID]
			if card.markID == markID:
				cfg = ObjectZawake.LevelMap[(zawakeID, stage, level)]

				self.dynamicAdd(cfg, markID)

				if cfg.skillID:
					card.zawake_skills.append(cfg.skillID)

	def getAttrsAddition(self, card, scene=0):
		'''
		获得card卡牌的加成
		'''
		const = zeros()
		percent = zeros()

		if not self._zawakeID:
			return const, percent

		from game.object import ZawakeDefs
		self._initEffectAttrAddition(card)

		markID = card.markID
		nature = card.natureType
		additions = [
			(self._natureCardAttrAddition, nature),
			(self._markIDCardAttrAddition, markID),
			(self._cardAttrAddition, ZawakeDefs.CardsAll),
		]

		for v, typ in additions:
			addition = v.get(typ, None)
			if addition:
				const += addition[0]
				percent += addition[1]
		return const, percent
