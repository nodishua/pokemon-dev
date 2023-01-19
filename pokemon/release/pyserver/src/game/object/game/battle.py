#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2014 YouMi Information Technology Inc.
'''

from __future__ import absolute_import

from framework import nowtime_t, nowdate_t, perioddate2int, period2date, todayinclock5date2int, nowdatetime_t, inclock5date, datetimefromtimestamp, str2num_t
from framework.csv import csv, ErrDefs, ConstDefs
from framework.log import logger
from framework.object import ObjectBase
from framework.helper import WeightRandomObject, transform2list

from game import ClientError, CheatError
from game.globaldata import CloneRoomFinished, CloneRefreshTime, UnionFubenAwardTime, WorldBossFreeCount, UnionFubenMaxTime, UnionFubenDailyTimeRange, RandomTowerHuodongID
from game.object import ItemDefs, MapDefs, YYHuoDongDefs, YuanzhengDefs, SceneDefs, TargetDefs, AttrDefs, RandomTowerDefs, AchievementDefs, GymDefs, DeployDefs, ReunionDefs
from game.object.game import ObjectCard
from game.object.game.deploy_limit import ObjectDeployLimit
from game.object.game.gym import ObjectGymGameGlobal
from game.object.game.servrecord import ObjectServerGlobalRecord
from game.object.game.wmap import ObjectMap
from game.object.game.drop import ObjectRandomDropFactory, ObjectStableDropFactory
from game.object.game.gain import ObjectGainAux
from game.object.game.yyhuodong import ObjectYYHuoDongFactory
from game.object.game.huodong import ObjectHuoDongFactory

import os
import copy
import random
import msgpack
import binascii
import itertools
import datetime


#
# ObjectGateBattle
#


class ObjectGateBattle(ObjectBase):
	WorldLevelBonus = None

	@classmethod
	def classInit(cls):
		cls.WorldLevelBonus = {}
		for idx in csv.world_level.bonus:
			cfg = csv.world_level.bonus[idx]
			for delta in xrange(cfg.deltaRange[0], cfg.deltaRange[1] + 1):
				cls.WorldLevelBonus[delta] = cfg

	@property
	def scene(self):
		return SceneDefs.Gate

	def _inputOK(self):
		# ignore 0, 0 mean empty slot, -1 mean no slot
		btlIDs = filter(None, self.cardIDs)

		# 获取玩家卡牌
		self._cards = self.game.cards.getCards(btlIDs)
		if len(self._cards) != len(btlIDs):
			raise ClientError(ErrDefs.gateCardsError)

	def _canBegin(self):
		if self.gateID not in self.game.role.gate_open:
			raise ClientError(ErrDefs.gateNoOpen)

		# 每日挑战次数
		if not self.game.role.canStartGate(self.gateID):
			raise ClientError(ErrDefs.todayChanllengeToMuch)

		# 体力是否足够
		cfg = csv.scene_conf[self.gateID]
		if self.game.role.stamina < cfg.staminaCost:
			raise ClientError(ErrDefs.gateStaminaNotEnough)

		# 每日体力消耗上限
		if ConstDefs.dailyStaminaCostMax - self.game.dailyRecord.cost_stamina_sum < cfg.staminaCost:
			raise ClientError(ErrDefs.dailyStaminaCostLimit)

	def _recordBattle(self):
		if self.beginDate == todayinclock5date2int():
			self.game.role.recordGateBattle(self.gateID)
			if hasattr(self, 'catchupGate'):
				catchupCfg = ObjectYYHuoDongFactory.getReunionCatchUpCfg(self.game.role, ReunionDefs.DoubleDropGate, self.gateID)
				self.game.role.addReunionCatchUpRecord(catchupCfg.id, self.catchupGate)

		gateType = ObjectMap.queryGateType(self.gateID)
		if gateType == MapDefs.TypeGate:
			ObjectYYHuoDongFactory.onGeneralTask(self.game, TargetDefs.GateChanllenge, 1)
			self.game.achievement.onCount(AchievementDefs.GateChallenge, 1)

		elif gateType == MapDefs.TypeHeroGate:
			ObjectYYHuoDongFactory.onGeneralTask(self.game, TargetDefs.HeroGateChanllenge, 1)
			self.game.achievement.onCount(AchievementDefs.HeroGateChallenge, 1)

		elif gateType == MapDefs.TypeNightmareGate:
			ObjectYYHuoDongFactory.onGeneralTask(self.game, TargetDefs.NightmareGateChanllenge, 1)

	def _recordGateStar(self):
		self.game.role.addGateStar(self.gateID, self.star)

	def _makeDrop(self):
		# 计算怪物掉落
		self.drop = {}
		self._stableDropWeights = copy.deepcopy(dict(self.game.role.stable_drop_weights))
		rDropGen = ObjectRandomDropFactory.getDrop(self.gateID)
		sDropGen = ObjectStableDropFactory.getDrop(self.gateID, self._stableDropWeights)
		monsterRDrop = rDropGen.getDropItems() if rDropGen else {}
		monsterSDrop = sDropGen.getDropItems() if sDropGen else {}

		if hasattr(self, 'multiples'): # 目前只有活动副本会外部设置
			doubleCnt = self.multiples
		else:
			yyID = ObjectYYHuoDongFactory.getDoubleDropOpenID(YYHuoDongDefs.DoubleDropGate, self.gateID)
			catchupCfg = ObjectYYHuoDongFactory.getReunionCatchUpCfg(self.game.role, ReunionDefs.DoubleDropGate, self.gateID)
			doubleCnt = 1
			if yyID:
				doubleCnt = 2
				self.multiples = doubleCnt
			# 进度赶超和运营活动同时存在是优先执行运营活动
			elif self.game.role.canReunionCatchUp(catchupCfg, times=getattr(self, 'catchupGate', 0) + 1):
				self.catchupGate = getattr(self, 'catchupGate', 0) + 1
				doubleCnt = 2
			else:
				self.multiples = doubleCnt
		# 刷新权值累加器
		if sDropGen:
			self._stableDropWeights = sDropGen.weightSumMap

		for itemID, itemCount in itertools.chain(monsterRDrop.iteritems(), monsterSDrop.iteritems()):
			cfg = csv.items[itemID]
			# 限时掉落不享受双倍加成
			if cfg and cfg.isLimitDrop:
				self.drop[itemID] = int(itemCount) + self.drop.get(itemID, 0)
			else:
				self.drop[itemID] = int(itemCount * doubleCnt) + self.drop.get(itemID, 0)

	def _gainGoldExp(self, cfg, goldMultiples=1):
		# 加卡牌经验
		cards = self.game.cards.getCards(self.cardIDs)
		cardExp = cfg.cardExp
		for card in cards:
			card.exp += cardExp

		# 加主角经验
		# 主角升级会赠送RMB
		self._oldLevel = self.game.role.level
		self._oldRMB = self.game.role.rmb
		self.game.role.exp += cfg.roleExp

		# 加金币
		self.game.role.gold += int(cfg.gold * goldMultiples)

	def _costWhenWin(self, cfg):
		self.game.role.stamina -= cfg.staminaCost

	@property
	def worldLevelBonus(self):
		if ObjectServerGlobalRecord.isWorldLevelBonusOpen(self.game, self.gateID):
			delta = ObjectServerGlobalRecord.Singleton.world_level - self.game.role.level
			cfg = self.WorldLevelBonus.get(delta, None)
			if cfg:
				gateType = ObjectMap.queryGateType(self.gateID)
				if gateType == MapDefs.TypeGate:
					return str2num_t(cfg.gateBonus)[1]
				elif gateType == MapDefs.TypeHeroGate:
					return str2num_t(cfg.heroGateBonus)[1]
				return 0
		return 0

	def begin(self, gateID, cardIDs):
		self.id = binascii.hexlify(os.urandom(16))
		self.randSeed = random.randint(1, 99999999)
		self.beginTime = nowtime_t()
		self.beginDate = todayinclock5date2int()
		self.gateID = gateID
		self.cardIDs = cardIDs

		# 判断数据是否合法
		self._inputOK()

		# 判断可否进入
		self._canBegin()

		# 计算掉落
		self._makeDrop()

		cardsD, cardsD2 = self.game.cards.makeBattleCardModel(self.cardIDs, self.scene)
		# 组装客户端数据
		self._clientData = {
			'battle': {
				'id': self.id,
				'gate_id': self.gateID,
				'rand_seed': self.randSeed,
				'cards': self.cardIDs,
				'card_attrs': cardsD,
				'card_attrs2': cardsD2,
				'level': self.game.role.level,
				'drop': self.drop,
				'passive_skills': self.game.cards.markBattlePassiveSkills(self.cardIDs),
			},
		}

		return self._clientData

	def result(self, result, star):
		self.win = (result == 'win')
		self.star = int(star)
		self.endTime = nowtime_t()

		cfg = csv.scene_conf[self.gateID]
		# if self.win and self.endTime - self.beginTime < cfg.lowFightTime:
		# 	raise CheatError()

		if not self.win:
			# 未过关
			self.star = 0
			self._recordGateStar()

			self._result = {
				'view': {
					'result': result,
					'star': 0,
					'role': {
						'addExp': 0,
						'addLevel': 0,
						'addGold': 0,
					}
				}
			}

		else:
			# 记录
			self._recordBattle()

			mapS = set(self.game.role.map_open)

			# 过关星级
			self._recordGateStar()

			# 扣体力
			self._costWhenWin(cfg)

			multiples = 1
			gateType = ObjectMap.queryGateType(self.gateID)
			if gateType == MapDefs.TypeGate:
				multiples += self.game.trainer.gateGoldDropRate
			elif gateType == MapDefs.TypeHeroGate:
				multiples += self.game.trainer.heroGateGoldDropRate

			# 运营活动额外倍数
			if getattr(self, 'multiples', 1) > 1:
				multiples += (getattr(self, 'multiples', 1) - 1)
			elif getattr(self, 'catchupGate', 0) > 0:
				multiples += 1

			# 加经验和金币
			self._gainGoldExp(cfg, multiples)
			# 世界等级额外经验
			bonus = self.worldLevelBonus
			self.game.role.exp += int(cfg.roleExp * bonus)

			mapS = set(self.game.role.map_open) - mapS

			self._result = {
				'view': {
					'result': result,
					'star': self.star,
					'role': {
						'addExp': cfg.roleExp + int(cfg.roleExp * bonus),
						'addLevel': self.game.role.level - self._oldLevel,
						'addGold': int(cfg.gold * multiples),
						'addRMB': self.game.role.rmb - self._oldRMB,
						'newMap': list(mapS),
					}
				}
			}
			return ObjectGainAux(self.game, self.drop)

		# self._writeRecord()

	def end(self):
		ret = None
		if hasattr(self, '_result'):
			ret = self._result
			del self._result

		# 固定概率设置
		if getattr(self, 'win', False) and hasattr(self, '_stableDropWeights'):
			self.game.role.stable_drop_weights.update(self._stableDropWeights)

		if hasattr(self, '_clientData'):
			del self._clientData

		return ret

	def _writeRecord(self):
		# anti-cheat record test
		print 'anti-cheat record test', 'id' , self.id, 'role_id', self.game.role.id, 'gate_id', self.gateID

		# self._clientData在begin的时候返回给handle，可能会被model sync污染
		# 但这里不管这些数据，反作弊用不到
		data = {'data': self._clientData, 'result': self._result}
		data = msgpack.packb(data, use_bin_type=True)
		records = [{
			'id': self.id,
			# 'account_id': self.game.account.id,
			'role_id': self.game.role.id,
			'gate_id': self.gateID,
			'data': data,
		}]
		f = open('battle.record', 'wb')
		f.write(msgpack.packb(records, use_bin_type=True))
		f.close()



#
# ObjectGateSaoDang
#

class ObjectGateSaoDang(ObjectGateBattle):

	def _canBegin(self):
		# 开启，挑战次数，扫荡次数判断
		if not self.game.role.canSaoDang(self.gateID, self.times):
			raise ClientError(ErrDefs.saodangGateTimesNotEnough)

	def _recordBattle(self):
		if self.beginDate == todayinclock5date2int():
			self.game.role.recordGateBattle(self.gateID, times=self.times)
			if hasattr(self, 'catchupGate'):
				catchupCfg = ObjectYYHuoDongFactory.getReunionCatchUpCfg(self.game.role, ReunionDefs.DoubleDropGate, self.gateID)
				self.game.role.addReunionCatchUpRecord(catchupCfg.id, self.catchupGate)

		gateType = ObjectMap.queryGateType(self.gateID)
		if gateType == MapDefs.TypeGate:
			ObjectYYHuoDongFactory.onGeneralTask(self.game, TargetDefs.GateChanllenge, self.times)
			self.game.achievement.onCount(AchievementDefs.GateChallenge, self.times)

		elif gateType == MapDefs.TypeHeroGate:
			ObjectYYHuoDongFactory.onGeneralTask(self.game, TargetDefs.HeroGateChanllenge, self.times)
			self.game.achievement.onCount(AchievementDefs.HeroGateChallenge, self.times)

		elif gateType == MapDefs.TypeNightmareGate:
			ObjectYYHuoDongFactory.onGeneralTask(self.game, TargetDefs.NightmareGateChanllenge, self.times)

	def _makeDrop(self):
		self.drops = []
		myItemNum = 0
		for i in xrange(self.times):
			ObjectGateBattle._makeDrop(self)
			self.drops.append(self.drop)
			if self.itemID:
				myItemNum += self.drop.get(self.itemID, 0)
			self.drop = None
			# 固定概率设置
			if hasattr(self, '_stableDropWeights'):
				self.game.role.stable_drop_weights.update(self._stableDropWeights)
			if self.targetNum and self.targetNum > 0 and myItemNum >= self.targetNum:
				self.times = i + 1
				break

	def begin(self, gateID, times, itemID=None, targetNum=None):
		self.beginTime = nowtime_t()
		self.beginDate = todayinclock5date2int()
		self.gateID = gateID
		self.times = times
		self.itemID = itemID
		self.targetNum = targetNum
		# 判断可否进入
		self._canBegin()

		# 计算掉落
		self._makeDrop()
		return self.times

	def result(self):
		cfg = csv.scene_conf[self.gateID]

		# 记录
		self._recordBattle()

		multiples = 1
		gateType = ObjectMap.queryGateType(self.gateID)
		if gateType == MapDefs.TypeGate:
			multiples += self.game.trainer.gateGoldDropRate
		elif gateType == MapDefs.TypeHeroGate:
			multiples += self.game.trainer.heroGateGoldDropRate

		# 运营活动额外倍数
		multiples += (getattr(self, 'multiples', 1) - 1)
		# 进度赶超 加成次数
		catchupTimes = getattr(self, 'catchupGate', 0)

		# 加主角经验
		# 主角升级会赠送RMB
		oldLevel = self.game.role.level
		oldRMB = self.game.role.rmb
		# 世界等级额外经验
		bonus = self.worldLevelBonus
		self.game.role.exp += self.times * int(cfg.roleExp * (1 + bonus))

		# 加金币
		self.game.role.gold += (self.times * int(cfg.gold * multiples) + catchupTimes * int(cfg.gold))

		# 扣体力
		staminaCost = cfg.staminaCost
		self.game.role.stamina -= self.times * staminaCost

		# 怪物全死，掉落直接按服务器计算的给
		eff = ObjectGainAux(self.game, {})
		for drop in self.drops:
			eff += ObjectGainAux(self.game, drop)

		# 构造常规奖励
		resultAward = []
		for i in xrange(self.times):
			resultAward.append({
				'exp': int(cfg.roleExp * (1 + bonus)),
				'gold': int(cfg.gold * multiples) if i >= catchupTimes else int(cfg.gold * (multiples + 1)),
				'items': self.drops[i],
			})

		# 扫荡根据关卡奖励经验药水
		extraAward = {}
		saodangAward = cfg.sandangAward
		# 世界等级的扫荡奖励
		if bonus > 0:
			saodangAward = cfg.worldLevelSaodangAward
		for itemID, itemCount in saodangAward.iteritems():
			if ItemDefs.isItemID(itemID):
				self.game.items.addItem(itemID, self.times * itemCount)
				extraAward[itemID] = self.times * itemCount + extraAward.get(itemID, 0)

		# 加装备
		# 等外部数据操作完后调用end函数

		self._result = {
			'view': {
				'result': resultAward,
				'extra': extraAward,
				'world_level_bonus': bonus,
				'role': {
					'addLevel': self.game.role.level - oldLevel,
					'addRMB': self.game.role.rmb - oldRMB,
				},
				'catchup': getattr(self, 'catchupGate', 0)  # 扫荡中, 重聚活动双倍加成的次数
			}
		}
		return eff



#
# ObjectHuoDongBattle
#

class ObjectHuoDongBattle(ObjectGateBattle):

	@property
	def scene(self):
		return SceneDefs.HuodongFuben

	def getBattleCards(self):
		return self._cards

	def _canBegin(self):
		self.game.role.canStartHuoDong(self.huodonogID, self.gateID)

	def _recordBattle(self):
		obj = ObjectHuoDongFactory.getOpenConfig(self.huodonogID)
		if obj and self.beginDate == obj.getPeriodDateInt():
			gateType = csv.scene_conf[self.gateID].sceneType
			self.game.role.recordGateBattle(self.gateID, gateType)
			self.game.role.addHuoDong(self.huodonogID)

		cfg = csv.huodong[self.huodonogID]
		huodongType = csv.scene_conf[self.gateID].sceneType
		if huodongType == MapDefs.TypeGold:
			self.game.achievement.onCount(AchievementDefs.GoldHuodongPassCount, 1)
		elif huodongType == MapDefs.TypeExp:
			self.game.achievement.onCount(AchievementDefs.ExpHuodongPassCount, 1)
		elif huodongType == MapDefs.TypeGift:
			self.game.achievement.onCount(AchievementDefs.GiftHuodongPassCount, 1)
		elif huodongType == MapDefs.TypeFrag:
			self.game.achievement.onCount(AchievementDefs.FragHuodongPassCount, 1)
		ObjectYYHuoDongFactory.onGeneralTask(self.game, TargetDefs.HuodongChanllenge, 1)

	# 活动副本不记录星级奖励
	# 只记录通关状态
	def _recordGateStar(self, star):
		self.game.role.addHuoDongPassedGate(self.huodonogID, self.gateID, star)

	def begin(self, huodonogID, gateID, cardIDs):
		self.huodonogID = huodonogID
		ret = ObjectGateBattle.begin(self, gateID, cardIDs)
		ret['battle']['huodong_id'] = self.huodonogID
		self.beginDate = ObjectHuoDongFactory.getOpenConfig(self.huodonogID).getPeriodDateInt()
		return ret

	def result(self, result, star):
		self.win = (result == 'win')
		self.star = int(star)
		self.endTime = nowtime_t()

		cfg = csv.scene_conf[self.gateID]

		# 碎片副本，礼物副本, 51劳动节副本胜利的时候才记录次数和冷却
		# 其它的活动没有这限制
		record = True
		if cfg.sceneType in (MapDefs.TypeGift, MapDefs.TypeFrag, MapDefs.Type51Huodong):
			record = self.win

		addExp = 0
		addGold = 0
		addLevel = 0
		oldLevel = self.game.role.level
		if record:
			# 记录
			self._recordBattle()

			# 扣体力
			self._costWhenWin(cfg)

			# 加经验和金币
			self._gainGoldExp(cfg)

			addExp = cfg.roleExp
			addGold = cfg.gold
			addLevel = self.game.role.level - oldLevel

		eff = ObjectGainAux(self.game, self.drop)

		# 等外部数据操作完后调用end函数
		if self.win:
			self._recordGateStar(star)

		self._result = {
			'view': {
				'result': result,
				'star': self.star,
				'role': {
					'addExp': addExp,
					'addLevel': addLevel,
					'addGold': addGold,
				}
			}
		}
		if record:
			return eff

	def end(self):
		ret = ObjectGateBattle.end(self)
		ret['view']['huodonogID'] = self.huodonogID
		return ret


#
# ObjectHuoDongSaoDang
#

class ObjectHuoDongSaoDang(ObjectGateSaoDang):
	def _canBegin(self):
		# 是否之前3星通关了
		if self.game.role.getHuoDongGateStar(self.huodonogID, self.gateID) != 3:
			raise ClientError(ErrDefs.huodongCanNotSaoDang)

		self.game.role.canStartHuoDong(self.huodonogID, self.gateID, self.times)

	def _recordBattle(self):
		obj = ObjectHuoDongFactory.getOpenConfig(self.huodonogID)
		if obj and self.beginDate == obj.getPeriodDateInt():
			gateType = csv.scene_conf[self.gateID].sceneType
			self.game.role.recordGateBattle(self.gateID, gateType, self.times)
			self.game.role.addHuoDong(self.huodonogID, self.times)

		cfg = csv.huodong[self.huodonogID]
		ObjectYYHuoDongFactory.onGeneralTask(self.game, TargetDefs.HuodongChanllenge, self.times)

	def begin(self, huodonogID, gateID, times):
		self.huodonogID = huodonogID
		ObjectGateSaoDang.begin(self, gateID, times)
		self.beginDate = ObjectHuoDongFactory.getOpenConfig(self.huodonogID).getPeriodDateInt()

	def end(self):
		ret = ObjectGateSaoDang.end(self)
		ret['view']['huodonogID'] = self.huodonogID
		return ret

#
# ObjectUnionFubenBattle
#

class ObjectUnionFubenBattle(ObjectGateBattle):

	@property
	def scene(self):
		return SceneDefs.UnionFuben

	def canBattle(self):
		# 玩家每天可以进行3次挑战
		if self.game.dailyRecord.union_fb_times >= UnionFubenMaxTime:
			raise ClientError(ErrDefs.todayChanllengeToMuch)

		# 每周1~6的9点半~23点半可以挑战
		nd = nowdatetime_t()
		nt = nd.time()
		if nt < UnionFubenDailyTimeRange[0] or nt > UnionFubenDailyTimeRange[1]:
			raise ClientError(ErrDefs.unionFubenNoOpened)

		if nd.isoweekday() == 7:
			raise ClientError(ErrDefs.unionFubenNoOpened)

	def begin(self, csvID, gateID, cardIDs, buff):
		self.id = binascii.hexlify(os.urandom(16))
		self.randSeed = random.randint(1, 99999999)
		self.csvID = csvID
		self.gateID = gateID
		self.cardIDs = cardIDs
		self.cardsFPSum = 0
		self.beginFBDate = period2date(UnionFubenAwardTime)

		# 判断数据是否合法
		self._inputOK()

		card_attrs, card_attrs2 = self.game.cards.makeBattleCardModel(self.cardIDs, self.scene)
		correct = 1 + buff * 1.0 / 100
		attrs = (AttrDefs.hp, AttrDefs.damage, AttrDefs.defence, AttrDefs.specialDamage, AttrDefs.specialDefence)
		for _, card in card_attrs.iteritems():
			self.cardsFPSum += card['fighting_point']
			for attr in attrs:
				card['attrs'][attr] *= correct
		for _, card in card_attrs2.iteritems():
			for attr in attrs:
				card['attrs'][attr] *= correct

		# 组装客户端数据
		clientData = {
			'union_fuben_battle': {
				'id': self.id,
				'csv_id': self.csvID,
				'gate_id': self.gateID,
				'rand_seed': self.randSeed,
				'cards': self.cardIDs,
				'card_attrs': card_attrs,
				'card_attrs2': card_attrs2,
				'level': self.game.role.level,
				'buff': buff,
				'passive_skills': self.game.cards.markBattlePassiveSkills(self.cardIDs),
			},
		}

		return clientData

	def result(self, result):
		self.win = (result == 'win')

		# 已经过了23:30的结算奖励时间
		if self.beginFBDate != period2date(UnionFubenAwardTime):
			raise ClientError(ErrDefs.unionFubenOutOfTime)

		self._result = {
			'view': {
				'result': result,
			}
		}

	def maxDamage(self):
		# 最大伤害不能超过总战力的 20 倍
		return self.cardsFPSum * ConstDefs.unionFubenMaxDamageMultiple

#
# ObjectWorldBossBattle
#

class ObjectWorldBossBattle(ObjectGateBattle):

	@property
	def scene(self):
		return SceneDefs.WorldBoss

	def _canBegin(self):
		# 每日挑战次数
		todayTimes = self.game.dailyRecord.boss_gate
		if todayTimes >= self.freeCount + self.game.dailyRecord.boss_gate_buy:
			raise ClientError(ErrDefs.yyWorldBossCountLimit)

	def _recordBattle(self):
		self.game.dailyRecord.boss_gate += 1

	def begin(self, gateID, cardIDs, freeCount):
		self.id = binascii.hexlify(os.urandom(16))
		self.randSeed = random.randint(1, 99999999)
		self.gateID = gateID
		self.cardIDs = cardIDs
		self.freeCount = freeCount
		self.beginTime = nowtime_t()
		self.beginDateInt = todayinclock5date2int()
		self.cardsFPSum = 0

		# 判断数据是否合法
		self._inputOK()

		# 判断可否进入
		self._canBegin()

		card_attrs, card_attrs2 = self.game.cards.makeBattleCardModel(self.cardIDs, self.scene)
		for _, card in card_attrs.iteritems():
			self.cardsFPSum += card['fighting_point']

		# 计算掉落
		# self._makeDrop()

		btlIDs = filter(None, self.cardIDs)
		# 获取玩家卡牌
		_cards = self.game.cards.getCards(btlIDs)

		# 组装客户端数据
		clientData = {'world_boss_battle': {
			'id': self.id,
			'level': self.game.role.level,
			'date': self.beginDateInt,
			'time': self.beginTime,
			'gate_id': self.gateID,
			'rand_seed': self.randSeed,
			'cards': self.cardIDs,
			'card_attrs': card_attrs,
			'card_attrs2': card_attrs2,
			'passive_skills': self.game.cards.markBattlePassiveSkills(self.cardIDs),
		}}

		return clientData

	def result(self, result):
		self.win = (result == 'win')

		# 记录
		self._recordBattle()

		self._result = {
			'view': {
				'result': result,
			}
		}

	def maxDamage(self):
		# 最大伤害不能超过总战力的 20 倍
		return self.cardsFPSum * ConstDefs.worldBossMaxDamageMultiple


#
# ObjectEndlessTowerBattle
#

class ObjectEndlessTowerBattle(ObjectGateBattle):
	@property
	def scene(self):
		return SceneDefs.EndlessTower

	def _canBegin(self):
		if self.game.role.endless_tower_current != self.gateID:
			raise ClientError('can not endlessTowerBattle')

	# 计算掉落（普通奖励 和 首通奖励）
	def _makeDrop(self):
		cfg = csv.endless_tower_scene[self.gateID]
		if self.first:
			self.drop = cfg.firstAward
		else:
			self.drop = cfg.saodangAward

	# 开始战斗
	def begin(self, gateID, cardIDs):
		self.id = binascii.hexlify(os.urandom(16))
		self.gateID = gateID
		self.cardIDs = cardIDs
		self.randSeed = random.randint(1, 99999999)
		self.beginDateInt = todayinclock5date2int()
		self.beginTime = nowtime_t()

		self.first = True if self.game.role.endless_tower_current > self.game.role.endless_tower_max_gate else False

		# 关卡限制
		self._inputOK()
		# 判断可否进入
		self._canBegin()
		# 计算掉落
		self._makeDrop()

		cardsD, cardsD2 = self.game.cards.makeBattleCardModel(self.cardIDs, self.scene)
		self.battle_model = {
			'id': self.id,
			'level': self.game.role.level,
			'gate_id': self.gateID,
			'rand_seed': self.randSeed,
			'cards': self.cardIDs,
			'card_attrs': cardsD,
			'card_attrs2': cardsD2,
			'date': self.beginDateInt,
			'time': self.beginTime,
			'passive_skills': self.game.cards.markBattlePassiveSkills(self.cardIDs),
			# 'round': 1,
			# 'actions': []
		}

		# 组装客户端数据
		clientData = {
			'endless_battle': self.battle_model
		}
		return clientData

	# 战斗后关卡处理
	def _recordBattle(self):
		# 最高层和当前层 加一
		self.game.role.endless_tower_current = self.game.role.endless_tower_current + 1

	def combine(self, result, round, actions):
		# 战斗数据补充 用于 战斗录像
		self.battle_model['round'] = round
		self.battle_model['actions'] = actions
		self.battle_model['fightingPoint'] = sum([card.fighting_point for card in self._cards])
		self.battle_model['result'] = result

	# 战斗结果
	def result(self, result, round, actions):
		self.win = (result == 'win')
		self.actions = actions
		self.round = round
		self.isUpdRank = False

		eff = ObjectGainAux(self.game, {})
		if not self.win:
			self._result = {
				'view': {
					'result': result,
				}
			}
		else:
			# 加奖励
			eff = ObjectGainAux(self.game, self.drop)

			oldMaxGate = self.game.role.endless_tower_max_gate
			# 关卡处理
			self._recordBattle()
			if oldMaxGate != self.game.role.endless_tower_max_gate:
				self.isUpdRank = True

			self._result = {
				'view': {
					'result': result,
				}
			}
		return eff

	def end(self):
		ret = self._result
		del self._result
		return ret

#
# ObjectEndlessTowerSaoDang
#

class ObjectEndlessTowerSaoDang(ObjectGateSaoDang):
	def _canBegin(self):
		if self.game.role.endless_tower_current > self.game.role.endless_tower_max_gate:
			raise ClientError('can not endlessTowerSaodang')
		if self.isCurrentSaodang:
			if self.game.role.endless_tower_current != self.gateID:
				raise ClientError('can not endlessTowerSaodang')

	def _makeDrop(self):
		# 计算掉落
		self.drops = []
		cfg = csv.endless_tower_scene
		for gateID in xrange(self.game.role.endless_tower_current, self.endGate):
			self.drop = cfg[gateID].saodangAward
			self.drops.append(self.drop)
			self.drop = None

	def begin(self, gateID):
		self.gateID = gateID
		# gateID 不传: 一键扫荡，否则: 关卡扫荡
		self.isCurrentSaodang = (self.gateID is not None)

		# 结束关卡
		if self.isCurrentSaodang:
			self.endGate = self.game.role.endless_tower_current + 1
		else:
			self.endGate = self.game.role.endless_tower_max_gate + 1

		# 判断可否进入
		self._canBegin()

		# 计算掉落
		self._makeDrop()

	def _recordBattle(self):
		# 当前关卡 回到 最大关卡加一
		self.game.role.endless_tower_current = self.endGate

	def result(self):
		self._recordBattle()

		# 加奖励
		effAll = []
		for i in xrange(len(self.drops)):
			eff = ObjectGainAux(self.game, self.drops[i])
			effAll.append(eff)

		self._result = {
			'view': {
				'result': effAll,
			}
		}
		return effAll

	def end(self):
		ret = self._result
		del self._result
		return ret


#
# ObjectRandomTowerBattle
#

class ObjectRandomTowerBattle(ObjectGateBattle):

	@property
	def scene(self):
		return SceneDefs.RandomTower

	def _resultStatesOK(self, cardStates, enemyStates):
		# 验证角色卡牌状态数据是否合法
		btlIDs = set(self.cardIDs)
		btlIDs.discard(None)
		cardIDs = set(cardStates.keys())
		cardIDs.discard(None)
		if btlIDs != cardIDs:
			raise ClientError('states card error')

		for cardID, t in cardStates.iteritems():
			if isinstance(cardID, int) and len(t) != 2:
				raise ClientError('states attr error')

		if not self.win:
			# 验证对手卡牌状态数据是否合法
			enmBtlIDs = set(self.enemyCardIDs)
			enmBtlIDs.discard(None)
			enemyCardIDs = set(enemyStates.keys())
			# enemyCardIDs == enmBtlIDs 发多少回多少
			if enemyCardIDs != enmBtlIDs:
				raise ClientError('enemy states card error')

			for cardID, t in enemyStates.iteritems():
				if len(t) != 2:
					raise ClientError('enemy states attr error')

	def _recordBattle(self, cardStates, enemyStates, battleRound):
		randomTower = self.game.randomTower

		# 不管输赢都 重算 卡牌的血量和怒气
		for cardID, t in cardStates.iteritems():
			card = self.game.cards.getCard(cardID)
			if card:
				if card.level < 10:
					continue
			randomTower.setCardState(cardID, t)

		# 将死亡的卡牌从阵容下掉
		aliveCount = 0
		for k, v in enumerate(self.game.role.huodong_cards[RandomTowerHuodongID]):
			if v and randomTower.card_states[v][0] > 0:
				aliveCount += 1
			else:
				self.game.role.huodong_cards[RandomTowerHuodongID][k] = None
		if self.win:
			# 计算积分
			cfgBoard = csv.random_tower.board[self.boardID]
			cfgTower = csv.random_tower.tower[cfgBoard.room]
			# 积分获得 = 等级基础积分（initPoint)*房间怪物积分修正系数（pointC1）*怪物积分修正系数（pointC2）*战斗星级表现系数（starRate）*Vip加成（vipRate）+buff积分加成（addPoint）
			initPoint = csv.random_tower.point[self.game.role.level]['initPoint']
			pointC1 = cfgTower['pointC'][cfgBoard.monsterType-1]
			pointC2 = cfgBoard['pointC']
			starRate = RandomTowerDefs.StarRate.get(self.star)
			vipRate = self.game.role.randomTowerPointRate
			addPoint = randomTower.getBuffPointAdd(battleRound, aliveCount)
			self.point = int(initPoint * pointC1 * pointC2 * starRate * vipRate + addPoint)
			# 每日积分增加
			randomTower.day_point += self.point
			ObjectYYHuoDongFactory.onGeneralTask(self.game, TargetDefs.RandomTowerBattleWin, 1)
		else:
			# 重算 怪物的血量和怒气
			for cardID, t in enemyStates.iteritems():
				randomTower.setEnemyState(cardID, t)

		# 记录 被动技能的使用
		randomTower.updateSkillUsed()

	def begin(self, boardID, cardIDs):
		self.id = binascii.hexlify(os.urandom(16))
		self.randSeed = random.randint(1, 99999999)
		self.cardIDs = cardIDs
		self.enemyCardIDs = []
		self.beginDateInt = todayinclock5date2int()
		self.boardID = boardID

		monsters = self.game.randomTower.room_info['enemy'][self.boardID]['monsters']
		for k, v in enumerate(monsters):
			if not v:
				self.enemyCardIDs.append(None)
			else:
				hp, _ = self.game.randomTower.enemy_states.get(str(v['id']), (1, 0))
				if hp > 0:
					self.enemyCardIDs.append(v['id'])
				else:
					self.enemyCardIDs.append(None)

		# 判断数据是否合法
		self._inputOK()

		# 组装客户端数据
		cardsD, cardsD2 = self.game.randomTower.getCardsAttr(self.cardIDs)
		clientData = {
			'random_tower_battle': {
				'id': self.id,
				'board_id': self.boardID,
				'rand_seed': self.randSeed,
				'cards': self.cardIDs,
				'card_attrs': cardsD,
				'card_attrs2': cardsD2,
				'defence_cards': self.enemyCardIDs,
				'defence_card_attrs': self.game.randomTower.room_info['enemy'][self.boardID]['monsters'],
				'level': self.game.role.level,
				'passive_skills': self.game.cards.markBattlePassiveSkills(self.cardIDs),
			}
		}

		return clientData

	def result(self, result, star, cardStates, enemyStates, battleRound):
		self.win = (result == 'win')
		self.star = star
		self.point = 0

		# 判断数据是否合法
		self._resultStatesOK(cardStates, enemyStates)
		# 记录
		self._recordBattle(cardStates, enemyStates, battleRound)

		self._result = {
			'view': {
				'result': result,
				'star': self.star,
				'point': self.point,
			}
		}

	def end(self):
		ret = self._result
		del self._result
		return ret


#
# ObjectGymBattle
#

class ObjectGymBattle(ObjectGateBattle):

	@property
	def scene(self):
		return SceneDefs.Gym

	def _inputOK(self):
		self.cardIDs = self.deployLimit.deployLimit(self.gateID)

	def _canBegin(self):
		cfg = csv.gym.gym[self.gymID]
		if cfg.preGymID and cfg.preGymID not in self.game.role.gym_pass_awards:
			raise ClientError('preGym not passed')
		if not csv.gym.gate[self.gateID].npc:
			current_gym_gate = self.game.role.getCurrentGymGate(self.gymID)
			if current_gym_gate is None:
				raise ClientError('gymID error!')
			if current_gym_gate != self.gateID:
				raise ClientError('gym gateID error!')

	def _recordBattle(self):
		if self.win:
			if not csv.gym.gate[self.gateID].npc:
				self.game.dailyRecord.gym_battle_times += 1
				role = self.game.role
				role.gym_fuben[self.gymID] = role.getCurrentGymDegree(self.gymID) + 1
				if role.isGymPassed(self.gymID):
					role.gym_pass_awards[self.gymID] = GymDefs.PassAwardOpenFlag
					# 前置道馆通关后开启
					for gymID in ObjectGymGameGlobal.GymMap.get(self.gymID, []):
						role.gym_fuben[gymID] = csv.gym.gym[gymID].hardDegreeID[0]

					if role.isGymAllPass:
						self.game.achievement.onCount(AchievementDefs.GymAllPassTimes, 1)

	def _makeDrop(self):
		if csv.gym.gate[self.gateID].npc:
			self.drop = {}
		else:
			ObjectGateBattle._makeDrop(self)

	def begin(self, gymID, gateID, cardIDs):
		self.id = binascii.hexlify(os.urandom(16))
		self.cardIDs = cardIDs
		self.randSeed = random.randint(1, 99999999)
		self.beginDateInt = todayinclock5date2int()
		self.gymID = gymID
		self.gateID = gateID
		self.deployLimit = ObjectDeployLimit(self.game, csv.gym.gate, self.cardIDs)
		self.cardsFPSum = 0

		# 判断数据是否合法
		self._inputOK()

		# 是否可挑战
		self._canBegin()

		# 计算掉落
		self._makeDrop()

		cardAttrs, cardAttrs2 = self.deployLimit.getCardAttrs(self.gateID, self.game.gymTalentTree.getGymTalenetCardsAttr)
		for _, card in cardAttrs.iteritems():
			self.cardsFPSum += card['fighting_point']

		# 组装客户端数据
		clientData = {
			'gym_battle': {
				'id': self.id,
				'level': self.game.role.level,
				'cards': self.cardIDs,
				'rand_seed': self.randSeed,
				'gym_id': self.gymID,
				'gate_id': self.gateID,
				'card_attrs': cardAttrs,
				'card_attrs2': cardAttrs2,
				'passive_skills': self.game.cards.markBattlePassiveSkills(self.cardIDs, self.scene),
			}
		}

		return clientData

	def maxDamage(self):
		# 最大伤害不能超过总战力的 x 倍
		return self.cardsFPSum * ConstDefs.gymFubenMaxDamageMultiple

	def result(self, result):
		self.win = (result == 'win')

		# 记录
		self._recordBattle()

		self._result = {
			'view': {
				'result': result,
			}
		}

		if self.win:
			return ObjectGainAux(self.game, self.drop)

	def end(self):
		ret = self._result
		del self._result
		return ret


#
# ObjectGymPass
#

class ObjectGymPass(ObjectGymBattle):

	def _canBegin(self):
		currentDegree = self.game.role.getCurrentGymDegree(self.gymID)
		degree = csv.gym.gate[self.gateID].hardDegree
		if currentDegree > degree or degree > max(self.game.role.history_jump.get(self.gymID, 0), self.game.role.last_jump.get(self.gymID, 0)):
			raise ClientError("degree can't saodang!")

		ObjectGymBattle._canBegin(self)

	def begin(self, gymID, gateID, itemID=None, targetNum=None):
		self.gymID = gymID
		self.gateID = gateID
		self.win = True

		#是否可扫荡
		self._canBegin()

		# 计算掉落
		self._makeDrop()

	def result(self):
		# 记录
		self._recordBattle()

		eff = ObjectGainAux(self.game, self.drop)

		self._result = {
			'view': {
				'result': 'win',
			}
		}

		return eff


#
# ObjectYYHuoDongBossBattle
#

class ObjectYYHuoDongBossBattle(ObjectGateBattle):

	@property
	def scene(self):
		return SceneDefs.HuoDongBoss

	def _inputOK(self):
		self.cardIDs = self.deployLimit.deployLimit(self.gateID)

	def begin(self, cardIDs, yyID, gate_id, idx):
		self.id = binascii.hexlify(os.urandom(16))
		self.randSeed = random.randint(1, 99999999)
		self.gateID = gate_id
		self.cardIDs = cardIDs
		self.deployLimit = ObjectDeployLimit(self.game, csv.scene_conf, self.cardIDs)
		self.cardsFPSum = 0

		# 判断数据是否合法
		self._inputOK()

		# 计算掉落
		self._makeDrop()

		cardAttrs, cardAttrs2 = self.deployLimit.getCardAttrs(self.gateID, self.game.cards.makeBattleCardModel, scene=self.scene)
		for _, card in cardAttrs.iteritems():
			self.cardsFPSum += card['fighting_point']

		# 组装客户端数据
		clientData = {
			'huodongboss_battle': {
				'id': self.id,
				'idx': idx,  # huodongboss uid
				'level': self.game.role.level,
				'cards': self.cardIDs,
				'rand_seed': self.randSeed,
				'gate_id': self.gateID,
				'card_attrs': cardAttrs,
				'card_attrs2': cardAttrs2,
				'passive_skills': self.game.cards.markBattlePassiveSkills(self.cardIDs, self.scene),
			}
		}

		return clientData

	def result(self, result):
		self.win = (result == 'win')
		self.endTime = nowtime_t()

		# 记录
		# self._recordBattle()

		eff = None
		if not self.win:
			# 未过关
			self._result = {
				'view': {
					'result': result,
				}
			}
		else:
			# 加掉落
			eff = ObjectGainAux(self.game, self.drop)
			self._result = {
				'view': {
					'result': result,
					'drop': self.drop,
				}
			}
		return eff

	def end(self):
		ret = None
		if hasattr(self, '_result'):
			ret = self._result
			del self._result
		return ret

	def maxDamage(self):
		# 最大伤害不能超过总战力的 x 倍
		return self.cardsFPSum * ConstDefs.huoDongBossMaxDamageMultiple


#
# ObjectHuntingBattle
#

class ObjectHuntingBattle(ObjectGateBattle):

	@property
	def scene(self):
		return SceneDefs.Hunting

	def resultStatesOK(self, cardStates, enemyStates):
		if not cardStates:
			raise ClientError('cardStates error')
		# 校验cardStates
		cardIDs = set(self.cardIDs)
		cardIDs.discard(None)
		cardStatesIDs = set(cardStates.keys())
		cardStatesIDs.discard(None)
		if cardStatesIDs != cardIDs:
			raise ClientError('states card error')
		for cardID, attr in cardStates.iteritems():
			if len(attr) != 2:
				raise ClientError('states attr error')

		# 校验enemyStates
		if not enemyStates:
			if isinstance(enemyStates, list):
				enemyStates = {}
		enemyCardIDs = set(self.enemyCardIDs)
		enemyCardIDs.discard(None)
		enemyStatesIDs = set(enemyStates.keys())
		enemyStatesIDs.discard(None)
		if enemyCardIDs != enemyStatesIDs:
			raise ClientError('enemy states card error')
		for cardID, attr in enemyStates.iteritems():
			if len(attr) != 2:
				raise ClientError('enemy states attr error')

	def getFixCardsAttr(self, gateID, cardIDs):
		'''
		获取卡牌的属性（加成后）
		'''
		BaseString = ['hp', 'speed', 'damage', 'defence', 'specialDamage', 'specialDefence']
		attrsD = {}  # {attr: fix}
		cfg = csv.cross.hunting.gate[gateID]
		for s in BaseString:
			field = "%sC" % s
			if field not in cfg or not cfg[field]:
				continue
			num = cfg[field]
			attrsD[s] = num
		cardsAttr, cardsAttr2 = self.game.cards.makeBattleCardModel(cardIDs, SceneDefs.Hunting)
		for cardID, cardAttr in cardsAttr.iteritems():
			card = self.game.cards.getCard(cardID)
			attrs = cardAttr.setdefault('attrs', {})
			for attr, fix in attrsD.iteritems():
				attrValue = attrs.get(attr, 0.0)
				attrValue = attrValue * fix
				attrs[attr] = attrValue
			cardAttr['fighting_point'] = ObjectCard.calcFightingPoint(card, attrs)
		for cardID, cardAttr in cardsAttr2.iteritems():
			card = self.game.cards.getCard(cardID)
			attrs = cardAttr.setdefault('attrs', {})
			for attr, fix in attrsD.iteritems():
				attrValue = attrs.get(attr, 0.0)
				attrValue = attrValue * fix
				attrs[attr] = attrValue
			cardAttr['fighting_point'] = ObjectCard.calcFightingPoint(card, attrs)

		return cardsAttr, cardsAttr2

	def begin(self, route, gateID, cardIDs):
		self.id = None
		self.cardIDs = cardIDs
		self.enemyCardIDs = []
		self.gateID = gateID
		self.route = route

		self.cardsFPSum = 0

		# 修正属性
		cardsD, cardsD2 = self.getFixCardsAttr(self.gateID, self.cardIDs)
		for _, card in cardsD.iteritems():
			self.cardsFPSum += card['fighting_point']
		battle = {
				'level': self.game.role.level,
				'gate_id': self.gateID,
				'route': self.route,

				'cards': self.cardIDs,
				'card_attrs': cardsD,
				'card_attrs2': cardsD2,
				'passive_skills': self.game.cards.markBattlePassiveSkills(self.cardIDs),
		}

		return battle

	def maxDamage(self):
		# 最大伤害不能超过总战力的 x 倍
		return self.cardsFPSum * ConstDefs.huntingMaxDamageMultiple

