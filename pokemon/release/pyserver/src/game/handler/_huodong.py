#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2014 YouMi Information Technology Inc.

HuoDong Handlers
'''

from framework import nowdatetime_t
from framework.csv import csv, ErrDefs
from framework.log import logger
from game import ClientError, ServerError
from game.handler.task import RequestHandlerTask
from game.object import FeatureDefs, MapDefs, YYHuoDongDefs, HuoDongDefs, AchievementDefs
from game.object.game.battle import ObjectHuoDongBattle, ObjectHuoDongSaoDang
from game.object.game.huodong import ObjectHuoDongFactory
from game.object.game.servrecord import ObjectServerGlobalRecord
from game.object.game.yyhuodong import ObjectYYHuoDongFactory
from game.object.game.levelcsv import ObjectFeatureUnlockCSV
from game.object.game.gain import ObjectGainAux
from game.object.game.monstercsv import ObjectMonsterCSV
from game.object.game.rank import ObjectRankGlobal

from game.handler.inl import effectAutoGain

import datetime
from tornado.gen import coroutine
import copy

# 打开活动界面
class HuoDongShow(RequestHandlerTask):
	url = r'/game/huodong/show'

	@coroutine
	def run(self):
		# 判断是否具备开启条件
		if not ObjectFeatureUnlockCSV.isOpen(FeatureDefs.HuoDong, self.game):
			raise ClientError(ErrDefs.levelLessNoOpened)

		role = self.game.role
		openT = role.getHuoDongOpens()
		for k,v in openT.iteritems():
			if not role.huodong_cards or k not in role.huodong_cards:
				role.huodong_cards[k] = copy.deepcopy(role.battle_cards)

		now = nowdatetime_t() - datetime.timedelta(hours=5)
		self.write({'view': {
			'open': openT,
			'day': now.isoweekday(),
		}})


# 开始活动
class HuoDongStart(RequestHandlerTask):
	url = r'/game/huodong/start'

	@coroutine
	def run(self):
		# 判断是否具备开启条件
		if not ObjectFeatureUnlockCSV.isOpen(FeatureDefs.HuoDong, self.game):
			raise ClientError(ErrDefs.levelLessNoOpened)

		battleCardIDs = self.input.get('battleCardIDs', None)
		huodongID = self.input.get('huodongID', None)
		gateID = self.input.get('gateID', None)

		if battleCardIDs is None:
			raise ClientError('battleCardIDs is error')

		if gateID not in csv.scene_conf:
			raise ClientError('gateID error')

		sceneType = csv.scene_conf[gateID].sceneType
		cfgFrag = csv.huodong_gate_fragment[ObjectServerGlobalRecord.getHuodongFragGroup()]
		if sceneType == MapDefs.TypeFrag and gateID not in cfgFrag['gateGroup']:
			raise ClientError('gateID error')

		self.game.role.deployHuodongCards(huodongID, battleCardIDs)
		battleCardIDs = self.game.role.huodong_cards[huodongID]

		# 最终获得 = 基础掉落 * (1 + 双倍 + 月卡特权 + 训练师特权)
		multiples = 1
		if sceneType == MapDefs.TypeGold:
			multiples += self.game.trainer.huodongTypeGoldDropRate
			multiples += self.game.privilege.huodongGoldDropRate
		elif sceneType == MapDefs.TypeExp:
			multiples += self.game.trainer.huodongTypeExpDropRate
			multiples += self.game.privilege.huodongExpDropRate
		elif sceneType == MapDefs.TypeGift:
			multiples += self.game.trainer.huodongTypeGiftDropRate
			multiples += self.game.privilege.huodongGiftDropRate
		elif sceneType == MapDefs.TypeFrag:
			multiples += self.game.trainer.huodongTypeFragDropRate
			multiples += self.game.privilege.huodongFragDropRate
		# 双倍掉落
		yyID = ObjectYYHuoDongFactory.getDoubleDropOpenID(YYHuoDongDefs.DoubleDropGate, gateID)
		if yyID:
			multiples += 1

		self.game.battle = ObjectHuoDongBattle(self.game)
		self.game.battle.multiples = multiples

		# 战斗数据
		ret = self.game.battle.begin(huodongID, gateID, battleCardIDs)

		self.write({
			'model': ret
		})


# 结束活动
class HuoDongEnd(RequestHandlerTask):
	url = r'/game/huodong/end'

	@coroutine
	def run(self):
		if self.game.battle is None:
			raise ClientError('battle miss')

		battleID = self.input.get('battleID', None)
		gateID = self.input.get('gateID', None)
		result = self.input.get('result', None)
		star = self.input.get('star', None)
		percent = self.input.get('percent', None) # 金币副本: 击杀百分比; 经验副本: 击杀数量
		score = self.input.get('score', 0)  # 金币副本： 总伤害量; 经验副本: 击杀数 * 当前等级副本怪物血量
		sameIDs = self.input.get('sameIDs', None)

		if not all([x is not None for x in [battleID, gateID, result, star]]):
			raise ClientError('param miss')
		if gateID != self.game.battle.gateID:
			raise ClientError('gateID error')
		if battleID != self.game.battle.id:
			raise ClientError('battleID error')

		sceneType = csv.scene_conf[gateID].sceneType
		cfgFrag = csv.huodong_gate_fragment[ObjectServerGlobalRecord.getHuodongFragGroup()]
		if sceneType == MapDefs.TypeFrag and gateID not in cfgFrag['gateGroup']:
			raise ClientError('gateID error')

		eff = None

		if sceneType != MapDefs.TypeGold and sceneType != MapDefs.TypeExp and result == 'win':
			cnt = ObjectMonsterCSV.getMonsterCount(gateID)

		# 前面不满足条件的都raise掉了， 走 huodong_drop 的掉落
		if sceneType == MapDefs.TypeGold or sceneType == MapDefs.TypeExp:
			if percent is None:
				raise ClientError('percent error')
			if gateID in csv.huodong_drop:
				dropCfg = csv.huodong_drop[gateID]
				if result == "win" and percent >= 100:
					eff = ObjectGainAux(self.game, dropCfg.saodangAwawrd)
				elif 1 <= percent <= 100:
					eff = ObjectGainAux(self.game, dropCfg.perDrop)
					eff *= percent
					for k,v in enumerate(dropCfg.node):
						if v <= percent:
							eff += ObjectGainAux(self.game, dropCfg.nodeDrop[k])

		elif sceneType == MapDefs.TypeFrag:
			import random
			# 碎片副本 根据上阵精灵获得的奖励
			if result == "win":
				cards = self.game.battle.getBattleCards()
				markIDs = dict(zip(cfgFrag['markIDs'], cfgFrag['dropItems']))
				eff = ObjectGainAux(self.game, {})
				for card in cards:
					if card.markID in markIDs:
						dropItem = markIDs[card.markID]
						if dropItem[2] >= random.randint(0, 100):
							eff += ObjectGainAux(self.game, {dropItem[0]: dropItem[1]})

		huodonogID = self.game.battle.huodonogID
		multiples = self.game.battle.multiples
		# 战斗结算 走 random_drops 的随机掉落
		dropeff = self.game.battle.result(result, star)
		yield effectAutoGain(dropeff, self.game, self.dbcGame, src='huodong_gate_drop_%d' % gateID)

		# 战斗结算完毕
		ret = self.game.battle.end()
		self.game.battle = None
		if dropeff:
			ret['view']['drop'] = dropeff.result

		if eff:
			eff *= multiples
			yield effectAutoGain(eff, self.game, self.dbcGame, src='huodong_gate_%d' % gateID)
			ret['view']['award'] = eff.result

		# 更新排行榜
		if not(sceneType == MapDefs.TypeGift or sceneType == MapDefs.TypeFrag):
			if score:
				ObjectRankGlobal.Singleton.onKeyInfoChange(self.game, 'huodong_%d' % huodonogID, int(score))

		self.write(ret)

# 活动扫荡
class HuoDongSaoDang(RequestHandlerTask):
	url = r'/game/huodong/saodang'

	@coroutine
	def run(self):
		huodongID = self.input.get('huodongID', None)
		gateID = self.input.get('gateID', None)
		times = self.input.get('times', None)

		if gateID is None or times is None or times < 1:
			raise ClientError('param is error')

		sceneType = csv.scene_conf[gateID].sceneType
		multiples = 1
		if sceneType == MapDefs.TypeGold:
			multiples += self.game.trainer.huodongTypeGoldDropRate
			multiples += self.game.privilege.huodongGoldDropRate
			self.game.achievement.onCount(AchievementDefs.GoldHuodongPassCount, 1)
		elif sceneType == MapDefs.TypeExp:
			multiples += self.game.trainer.huodongTypeExpDropRate
			multiples += self.game.privilege.huodongExpDropRate
			self.game.achievement.onCount(AchievementDefs.ExpHuodongPassCount, 1)
		elif sceneType == MapDefs.TypeGift:
			multiples += self.game.trainer.huodongTypeGiftDropRate
			multiples += self.game.privilege.huodongGiftDropRate
			self.game.achievement.onCount(AchievementDefs.GiftHuodongPassCount, 1)
		elif sceneType == MapDefs.TypeFrag:
			multiples += self.game.trainer.huodongTypeFragDropRate
			multiples += self.game.privilege.huodongFragDropRate
			self.game.achievement.onCount(AchievementDefs.FragHuodongPassCount, 1)
		# 双倍掉落
		yyID = ObjectYYHuoDongFactory.getDoubleDropOpenID(YYHuoDongDefs.DoubleDropGate, gateID)
		if yyID:
			multiples += 1

		# 战斗数据
		battle = ObjectHuoDongSaoDang(self.game)
		battle.multiples = multiples
		battle.begin(huodongID, gateID, times)
		# 战斗结算
		eff = battle.result()
		yield effectAutoGain(eff, self.game, self.dbcGame, src='huodong_gate_saodang_drop_%d' % gateID)

		# 战斗结算完毕
		ret = battle.end()

		if sceneType == MapDefs.TypeGold or sceneType == MapDefs.TypeExp:
			# 前面不满足条件的都raise掉了
			if gateID in csv.huodong_drop:
				dropCfg = csv.huodong_drop[gateID]
				eff = ObjectGainAux(self.game, dropCfg.saodangAwawrd)
				eff *= times * multiples
				yield effectAutoGain(eff, self.game, self.dbcGame, src='huodong_saodang_%d' % gateID)
				ret['view']['result'] = eff.result
		else:
			ret['view']['result'] = eff.result
		self.write(ret)