#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2014 YouMi Information Technology Inc.
'''

from framework import nowtime_t
from framework.csv import csv, ErrDefs, L10nDefs
from framework.helper import WeightRandomObject
from framework.log import logger
from framework.object import ObjectBase, ObjectDicAttrs
from game import ClientError

from game.session import Session
from game.object import UnionDefs, TargetDefs, UnionQADefs

import copy
import math
import random


class ObjectUnion(ObjectDicAttrs):
	"""Union 缓存数据"""
	ObjsMap = {}
	NameCache = set()
	RoleUnionMap = {} # {Role.id: Union.id}

	FeatureMap = {} # {feature: level}

	@classmethod
	def classInit(cls):
		cls.FeatureMap = {}
		levelMax = len(csv.union.union_level)
		for level in xrange(1, levelMax + 1):
			cfg = csv.union.union_level[level]
			for feature in cfg.openFeature:
				cls.FeatureMap[feature] = level

	def __init__(self, dic):
		super(ObjectUnion, self).__init__(dic)
		self.time = 0
		self.packet_last_time = nowtime_t()
		ObjectUnion.ObjsMap[self.id] = self
		ObjectUnion.NameCache.add(self.name)

		for roleID, _ in self.members.iteritems():
			self.RoleUnionMap[roleID] = self.id

	def init(self, dic, time):
		if time >= self.time:
			super(ObjectUnion, self).init(dic)
			self.time = time
		else:
			logger.warning('union init model failed, %d %d', self.time, time)

	def sync(self, dic, time):
		if not dic:
			return
		if time >= self.time:
			super(ObjectUnion, self).sync(dic)
			self.time = time
		else:
			logger.warning('union sync model failed, %d %d', self.time, time)

	def countMails(self):
		return len(self.mails)

	def getMails(self, offest):
		return self.mails[offest:]

	def isFeatureOpen(self, feature):
		return self.level >= self.FeatureMap.get(feature, 999999) # 未配置的默认就当未开放

	@classmethod
	def queryUnionName(cls, roleID):
		unionID = cls.RoleUnionMap.get(roleID, None)
		if unionID is None:
			return ""
		return cls.ObjsMap[unionID].name

	@classmethod
	def queryUnionLogo(cls, roleID):
		unionID = cls.RoleUnionMap.get(roleID, None)
		if unionID is None:
			return ""
		return cls.ObjsMap[unionID].logo

	@classmethod
	def getUnionByRoleID(cls, roleID):
		unionID = cls.RoleUnionMap.get(roleID, None)
		if unionID is None:
			return None
		return cls.getUnionByUnionID(unionID)

	@classmethod
	def getUnionByUnionID(cls, unionID):
		return cls.ObjsMap.get(unionID, None)

#
# ObjectUnionContribTask
#
class ObjectUnionContribTask(ObjectBase):

	TargetMap = {} # {target: [csv]}

	@classmethod
	def classInit(cls):
		cls.TargetMap = {}
		for i in csv.union.union_task:
			cfg = csv.union.union_task[i]
			cls.TargetMap.setdefault(cfg.targetType, []).append(cfg)

	@classmethod
	def onCount(cls, game, targetType, count):
		if not game.role.union_db_id:
			return
		if count <= 0:
			return
		if targetType not in cls.TargetMap:
			return

		for cfg in cls.TargetMap[targetType]:
			if cfg.userType == UnionDefs.UnionTaskRole:
				v, flag = game.role.union_contrib_tasks.get(cfg.id, (0, UnionDefs.UnionTaskNoneFlag))
				if flag == UnionDefs.UnionTaskCloseFlag:
					continue
				v += count
				if v >= cfg.targetArg:
					flag = UnionDefs.UnionTaskOpenFlag
				game.role.union_contrib_tasks[cfg.id] = (v, flag)
			else:
				from game.handler._union import unionCallAsync
				fu = unionCallAsync(Session.server.rpcUnion, 'AddContribTaskCount', game.role, cfg.id, count)

				# def done():
				# 	print 'AddContribTaskCount done'
				# fu.add_done_callback(lambda _: done())

#
# ObjectUnionCanSendRedPacket
#
class ObjectUnionCanSendRedPacket(ObjectBase):

	WatchTargetMap = {
		TargetDefs.Level: ('Role', 'level'),
		TargetDefs.Vip: ('Role', 'vip_level'),
		TargetDefs.Top6FightingPoint: ('Role', 'top6_fighting_point'),
		TargetDefs.Gate: ('Role', 'gate_star'),
		TargetDefs.RechargeRmb: ('DailyRecord', 'recharge_rmb_sum'), # 未使用Role.recharges的原因是vip_sum的更新再recharges更新之后
	}
	WatchModelMap = {}  # {model:{column:targrt}}

	@classmethod
	def classInit(cls):
		cls.WatchModelMap = {}
		for target, mc in cls.WatchTargetMap.iteritems():  # 实现WatchModelMap结构 {model:{column:targrt}}
			cls.WatchModelMap.setdefault(mc[0], {})[mc[1]] = target

	@classmethod
	def refreshCanSend(cls, game):
		if not game.role.union_db_id:
			return
		for model, v in cls.WatchModelMap.iteritems():
			for column, _ in v.iteritems():
				cls.onWatch(game, model, column)

	@classmethod
	def onWatch(cls, game, model, column):
		if not game.role.union_db_id:
			return
		# 监控每次变化  不是WatchTargetMap条件的变化 就直接return掉
		if model not in cls.WatchModelMap or column not in cls.WatchModelMap[model]:
			return
		targetType = cls.WatchModelMap[model][column]
		game.role.refreshUnionRedpackets(targetType)


#
# ObjectUnionQA
#
class ObjectUnionQA(ObjectBase):

	TextQMap = {}  # {type: {group: []}}
	TextQGroupWeightMap = {}  # {type: {group: weight}}
	GameQTypeWeightMap = {}  # {type: weight}
	GameWeightMap = {}  # {type: {csvID: weight}}

	@classmethod
	def classInit(cls):
		cls.TextQMap = {}
		cls.TextQGroupWeightMap = {}
		cls.GameQTypeWeightMap = {}
		cls.GameWeightMap = {}

		for csvID in csv.union_qa.qa_question:
			cfg = csv.union_qa.qa_question[csvID]
			cls.TextQMap.setdefault(cfg.typeSeqID, {}).setdefault(cfg.group, []).append(cfg)
			cls.TextQGroupWeightMap.setdefault(cfg.typeSeqID, {}).setdefault(cfg.group, cfg.weight)

		for csvID in csv.union_qa.qa_game:
			cfg = csv.union_qa.qa_game[csvID]
			cls.GameQTypeWeightMap.setdefault(cfg.type, cfg.weight)
			if cfg.type == UnionQADefs.DisappearCard:
				for gameID in csv.union_qa.qa_game1:
					gameCfg = csv.union_qa.qa_game1[gameID]
					cls.GameWeightMap.setdefault(cfg.type, {}).setdefault(gameID, gameCfg.weight)

	@classmethod
	def prepare(cls, game):
		questions = {}
		textQTypes = set([UnionQADefs.TextQ1, UnionQADefs.TextQ2, UnionQADefs.TextQ3])
		textQWeights = copy.deepcopy(cls.TextQGroupWeightMap)
		for csvID in csv.union_qa.qa_base:
			cfg = csv.union_qa.qa_base[csvID]
			# 文本问答
			if cfg.typeSeqID in textQTypes:
				# 已经随过的组尽量不再参与随机
				if not textQWeights[cfg.typeSeqID]:
					textQWeights[cfg.typeSeqID] = copy.deepcopy(cls.TextQGroupWeightMap[cfg.typeSeqID])
					logger.warning("unionqa textType%s group not enough", cfg.typeSeqID)
				group, _ = WeightRandomObject.onceRandom(textQWeights[cfg.typeSeqID])
				textQWeights[cfg.typeSeqID].pop(group)

				questionCfg = random.choice(cls.TextQMap[cfg.typeSeqID][group])
				raws = []
				for i in xrange(1, 9999):
					choice = "choice%d" % i
					if choice not in questionCfg or not questionCfg[choice]:
						break
					raws.append(i)

				# 选项随机排列
				choices = {}
				answer = 0
				random.shuffle(raws)
				for idx, i in enumerate(raws):
					choices[idx + 1] = questionCfg["choice%d" % i]
					if i == questionCfg.answer:
						answer = idx + 1

				questions[cfg.id] = {
					"type": cfg.typeSeqID,
					"question": questionCfg.desc,
					"choices": choices,
					"answer": answer,
					"questionID": questionCfg.id,
				}
			# 图片问答
			elif cfg.typeSeqID == UnionQADefs.PictureQ:
				typeCfg = csv.union_qa.qa_type[cfg.typeSeqID]

				raws = random.sample(csv.union_qa.qa_img, typeCfg.choiceNum)
				choices = {i + 1: raws[i] for i in xrange(int(typeCfg.choiceNum))}
				answer = random.choice(choices.keys())

				questions[cfg.id] = {
					"type": cfg.typeSeqID,
					"question": choices[answer],
					"choices": choices,  # {idx: imgID}
					"answer": answer,
				}
			# 小游戏
			elif cfg.typeSeqID == UnionQADefs.GameQ:
				gameType, _ = WeightRandomObject.onceRandom(cls.GameQTypeWeightMap)
				# 消失的精灵
				if gameType == UnionQADefs.DisappearCard:
					gameID, _ = WeightRandomObject.onceRandom(cls.GameWeightMap[gameType])
					gameCfg = csv.union_qa.qa_game1[gameID]

					imgIDs = random.sample(csv.union_qa.qa_img, gameCfg.displayNum + 1)
					raws = random.sample(imgIDs, gameCfg.choiceNum)
					choices = {i + 1: raws[i] for i in xrange(int(gameCfg.choiceNum))}
					answer = random.choice(choices.keys())
					imgIDs.remove(choices[answer])

					questions[cfg.id] = {
						"type": cfg.typeSeqID,
						"question": "",
						"display": imgIDs,
						"choices": choices,  # {idx: imgID}
						"answer": answer,
						"gameID": gameID,
					}

		game.role.union_qa_questions = questions
		game.role.union_qa_answers = {}
		game.role.union_qa_score = 0
		return questions

	@classmethod
	def startAnswer(cls, game, idx):
		if idx in game.role.union_qa_answers:
			raise ClientError("this question answered")
		game.role.startAnswerTime = nowtime_t()

	@classmethod
	def submitAnswer(cls, game, idx, answer):
		endTime = nowtime_t()

		useTime = endTime - game.role.startAnswerTime

		question = game.role.union_qa_questions.get(idx, None)
		if not question:
			raise ClientError("not this question")

		typeCfg = csv.union_qa.qa_type[question["type"]]
		ret = {"score": 0}
		if useTime > typeCfg.limitTime:
			ret["timeout"] = 1
		else:
			if answer == question["answer"]:
				for timeDown, timeUp, percent in typeCfg.scoreUp:
					if timeDown <= useTime <= timeUp:
						cfg = csv.union_qa.qa_base[idx]
						score = int(math.ceil(typeCfg.score * percent)) * cfg.multiple
						ret["score"] = score
						game.role.union_qa_score += score
						game.role.union_qa_answers[idx] = 1
						break
		logger.info("uid %s unionqa idx %s time %s score %s", game.role.uid, idx, useTime, ret["score"])
		return ret

	@classmethod
	def resetQAGameData(cls, game):
		game.role.union_qa_answers = None
		game.role.union_qa_questions = None
		game.role.union_qa_score = None

	@classmethod
	def makeUnionQAModel(cls, game):
		role = game.role
		if not game.dailyRecord.union_qa_union_db_id:
			union = ObjectUnion.getUnionByRoleID(role.id)
		else:
			union = ObjectUnion.getUnionByUnionID(game.dailyRecord.union_qa_union_db_id)

		return {
			"role": {
				"role_db_id": role.id,
				"logo": role.logo,
				"frame": role.frame,
				"name": role.name,
				"level": role.level,
				"game_key": role.areaKey,
				"union_name": union.name,
			},
			"union": {
				"id": union.id,
				"level": union.level,
				"logo": union.logo,
				"name": union.name,
				"game_key": role.areaKey,
				"chairman": union.members[union.chairman_db_id]["name"],
			},
		}
