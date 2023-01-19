#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2014 YouMi Information Technology Inc.
'''
import framework
from framework import str2num_t
from framework.csv import csv, ErrDefs, ConstDefs
from framework.log import logger
from framework.object import ObjectBase
from game import ServerError, ClientError
from game.object.game.gain import ObjectGoodsMap, ObjectCostAux, ObjectGainAux
from game.object import AttrDefs, TalentDefs, SceneDefs, TargetDefs, FeatureDefs
from game.object.game.calculator import zeros
from game.object.game.yyhuodong import ObjectYYHuoDongFactory
from game.thinkingdata import ta

#
# ObjectEquipsMap
#

class ObjectTalentTree(ObjectBase):
	TalentTreeMap = {} #talentID:[nextTalentID]
	TalentTreeStartNode = {} #treeID:[talentID]
	TalentCostSumMap = {} #(seqID,level):(gold,talent_point)
	TalentActiveCon = []
	TalentAttrsMap = {} # {talentID: [(attr, ty, num, nature)]}

	@classmethod
	def classInit(cls):
		cls.TalentTreeMap = {}
		cls.TalentTreeStartNode = {}
		cls.TalentCostSumMap = {}
		cls.TalentActiveCon = []
		cls.TalentAttrsMap = {}

		for i in sorted(csv.talent_tree):
			cfg = csv.talent_tree[i]
			if framework.__language__ in cfg.languages:
				cls.TalentActiveCon.append((cfg.preTalentpoint, cfg.roleLevel))

		for i in csv.talent:
			cfg = csv.talent[i]
			if cfg.preTalentID:
				if cfg.preTalentID not in cls.TalentTreeMap:
					cls.TalentTreeMap[cfg.preTalentID] = []
				cls.TalentTreeMap[cfg.preTalentID].append(i)
			else:
				cls.TalentTreeStartNode.setdefault(cfg.treeID, []).append(i)

			ret = []
			for j in xrange(1, 99):
				if 'addType%d' % j not in cfg:
					break
				ty = cfg['addType%d' % j]
				if ty is None:
					break
				if ty > TalentDefs.AttrsTotal:
					continue
				attr = cfg['attrType%d' % j]
				num = cfg['attrNum%d' % j]
				if num:
					num = str2num_t(num)
				ret.append((attr, ty, num, cfg['natureType%d' % j]))
			cls.TalentAttrsMap[i] = ret

		for i in xrange(99): #level
			if i not in csv.talent_cost:
				break
			for j in xrange(1, 99): #seq id
				if 'costTalent%d' % j not in csv.talent_cost[i]:
					break
				if i == 0:
					cls.TalentCostSumMap[(j, i)] = (0, 0)
				else:
					cfg = csv.talent_cost[i - 1]
					gold = cfg['costGold%d' % j]
					talent = cfg['costTalent%d' % j]
					preSum = cls.TalentCostSumMap[(j, i - 1)]
					cls.TalentCostSumMap[(j, i)] = (preSum[0] + gold, preSum[1] + talent)

	def set(self):
		self._talentTree = self.game.role.talent_trees
		return ObjectBase.set(self)

	def init(self):
		self.judgeActive()
		return ObjectBase.init(self)

	def judgeActive(self):
		# 使用到GCObject的尽量采用传参方式，对GC友好
		def dfs(role, tree, node):
			if node not in tree:
				cfg = csv.talent[node]
				if role.level >= cfg.roleLevel:
					if cfg.preTalentID is None or (tree[cfg.preTalentID] >= cfg.preTalentLevel):
						tree[node] = 0
			if node in tree and node in ObjectTalentTree.TalentTreeMap:
				for k, v in enumerate(ObjectTalentTree.TalentTreeMap[node]):
					dfs(role, tree, v)

		role = self.game.role
		for i in xrange(1, len(ObjectTalentTree.TalentActiveCon) + 1):
			if i == 1 and role.level < self.TalentActiveCon[i - 1][1]:
				break
			if i > 1 and (role.level < self.TalentActiveCon[i - 1][1] or self._talentTree[i - 1]['cost'] < self.TalentActiveCon[i - 1][0]):
				break
			tree = self._talentTree.get(i, None)
			if tree is None:
				self._talentTree[i] = {'cost': 0, 'talent': {}}
			startNodes = self.TalentTreeStartNode.get(i)
			for startNode in startNodes:
				dfs(role, self._talentTree[i]['talent'], startNode)

	def talentLevelUp(self, talentID):
		cfg = csv.talent[talentID]
		tree = self._talentTree.get(cfg.treeID, None)
		if tree is None:
			raise ClientError('tree no active')

		# 检查所有前置树是否满足条件
		for treeID in xrange(1, cfg.treeID):
			if self.TalentActiveCon[treeID - 1][0] > self._talentTree.get(treeID - 1, {'cost': 0})['cost']:
				raise ClientError('pre condition not satisfied')

		tree = self._talentTree[cfg.treeID]  #这样才能放到dict watch里
		talent = tree['talent']
		oldLevel = talent.get(talentID, None)
		if oldLevel is None:
			raise ClientError('talentID no active')
		if oldLevel >= cfg.levelUp:
			raise ClientError(ErrDefs.talentLevelUp)

		role = self.game.role
		needTalent = csv.talent_cost[oldLevel]['costTalent%d' % cfg.costID]
		if role.talent_point < needTalent:
			raise ClientError(ErrDefs.talentLevelPointUp)
		needGold = csv.talent_cost[oldLevel]['costGold%d' % cfg.costID]

		cost = ObjectCostAux(self.game, {'gold': needGold})
		if not cost.isEnough():
			raise ClientError(ErrDefs.talentLevelGoldUp)
		cost.cost(src='talent')

		role.talent_point -= needTalent
		ObjectYYHuoDongFactory.onGeneralTask(self.game, TargetDefs.TalentPointCost, needTalent)
		tree['cost'] += needTalent
		talent[talentID] = oldLevel + 1
		self.judgeActive()


		ta.track(self.game, event='talent_level_up',talent_type=cfg.treeID,talent_id=talentID,current_talent_level=talent[talentID],cost_talent_number=needTalent,total_cost_talent_number=tree['cost'])


	def talentResetAll(self, treeID):
		rmbCost = ConstDefs.talentResetCost if treeID else ConstDefs.talentResetAllCost
		if self.game.role.rmb < rmbCost:
			raise ClientError(ErrDefs.talentResetRmbUp)

		if treeID:
			tree = self._talentTree.get(treeID, None)
			if tree is None or tree['cost'] == 0:
				raise ClientError(ErrDefs.talentResetNoIDs)
		else:
			if sum([tree['cost'] for tree in self._talentTree.itervalues()]) == 0:
				raise ClientError(ErrDefs.talentResetNoIDs)

		relateIDs = []
		def dfs(tree, node):
			if node not in tree:
				return 0, 0
			relateIDs.append(node)
			cfg = csv.talent[node]
			sumGold, sumTalent = ObjectTalentTree.TalentCostSumMap[(cfg.costID, tree[node])]
			if node in ObjectTalentTree.TalentTreeMap:
				for k, v in enumerate(ObjectTalentTree.TalentTreeMap[node]):
					ret = dfs(tree, v)
					sumGold += ret[0]
					sumTalent += ret[1]
			return sumGold, sumTalent

		sumGold, sumTalent = 0, 0
		treeIDs = [treeID, ] if treeID else self._talentTree.keys()
		for i in treeIDs:
			tree = self._talentTree.get(i, None)
			if tree is None:
				break
			startNodes = self.TalentTreeStartNode.get(i)
			for startNode in startNodes:
				ret = dfs(tree['talent'], startNode)
				sumGold += ret[0]
				sumTalent += ret[1]

		cost = ObjectCostAux(self.game, {'rmb': rmbCost})
		cost.cost(src='talent_reset')
		if treeID:
			self.game.role.talent_trees.pop(treeID)
		else:
			self.game.role.talent_trees = {}
		self._talentTree = self.game.role.talent_trees
		eff = ObjectGainAux(self.game, {'gold': sumGold, 'talent_point': sumTalent})
		eff.gain(src='talent_reset')
		self.judgeActive()
		self.updateRelatedCards(relateIDs)

		return sumGold, sumTalent

	@classmethod
	def getAttrs(cls, card, talentID, inFront, inBack, scene):
		ret = []
		for t in cls.TalentAttrsMap[talentID]:
			attr, ty, num, nature = t
			if ty == TalentDefs.CardsAll:
				ret.append((attr, num))
			elif ty == TalentDefs.CardNatureType:
				if card.natureType == nature:
					ret.append((attr, num))

			if scene:
				if inFront and ty == TalentDefs.BattleFront:
					ret.append((attr, num))
				elif inBack and ty == TalentDefs.BattleBack:
					ret.append((attr, num))
				elif ty == TalentDefs.SceneType and scene == nature:
					ret.append((attr, num))
		return ret

	def getAttrsAddition(self, card, inFront, inBack, scene):
		const = zeros()
		percent = zeros()
		for _, tree in self._talentTree.iteritems():
			for talentID, level in tree['talent'].iteritems():
				if level > 0:
					ret = self.getAttrs(card, talentID, inFront, inBack, scene)
					for attr, num in ret:
						const[attr] += num[0] * level
						percent[attr] += num[1] * level
		return const, percent

	def updateRelatedCards(self, talentIDs):
		role = self.game.role
		allFlag = False
		allCards = self.game.cards.getAllCards()
		natureTypes = set()
		for _,talentID in enumerate(talentIDs):
			for t in self.TalentAttrsMap[talentID]:
				_, ty, _, nature = t
				if ty == TalentDefs.CardsAll:
					allFlag = True
					break
				elif ty == TalentDefs.CardNatureType:
					natureTypes.add(nature)
			if allFlag:
				break

		if allFlag:
			for k, v in allCards.iteritems():
				v.calcTalentAttrsAddition(v, self)
				v.onUpdateAttrs()
		else:
			for k, v in allCards.iteritems():
				if v.natureType in natureTypes:
					v.calcTalentAttrsAddition(v, self)
					v.onUpdateAttrs()

	# 达到多少天赋点 的节点数（暂未用到）
	def countTalentPoints(self, point):
		count = 0
		for k, v in self.game.role.talent_trees.iteritems():
			talentCsvIDs = self.TalentTreeStartNode.get(k, [])
			talent = v.get('talent', {})
			for i in talentCsvIDs:
				cfg = csv.talent[i]
				_, sumTalent = ObjectTalentTree.TalentCostSumMap[(cfg.costID, talent[i])]
				if sumTalent >= point:
					count = count + 1
		return count

