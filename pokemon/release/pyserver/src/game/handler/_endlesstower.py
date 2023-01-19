#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2014 YouMi Information Technology Inc.

Endless Tower Handlers
'''
import copy

from framework import todayinclock5elapsedays, datetimefromtimestamp
from framework.csv import csv, ErrDefs
from framework.helper import transform2list
from framework.log import logger
from game import ClientError, ServerError
from game.globaldata import EndlessTowerHuodongID
from game.handler.inl import effectAutoGain
from game.handler.task import RequestHandlerTask

from game.object import EndlessTowerDefs, FeatureDefs, YYHuoDongDefs, MessageDefs, ReunionDefs
from game.object.game import ObjectFeatureUnlockCSV, ObjectYYHuoDongFactory
from game.object.game.battle import ObjectEndlessTowerBattle, ObjectEndlessTowerSaoDang
from game.object.game.endlesstower import ObjectEndlessTowerGlobal
from game.object.game.message import ObjectMessageGlobal
from game.object.game.rank import ObjectRankGlobal
from game.object.game.costcsv import ObjectCostCSV
from game.object.game.gain import ObjectCostAux
from game.thinkingdata import ta
from tornado.gen import coroutine

# 无限塔关卡战斗开始
class EndlessTowerBattleStart(RequestHandlerTask):
	url = r'/game/endless/battle/start'

	@coroutine
	def run(self):
		if not ObjectFeatureUnlockCSV.isOpen(FeatureDefs.EndlessTower, self.game):
			raise ClientError('locked')
		if ObjectEndlessTowerGlobal.maybeCheatRole(self.game.role.id):
			raise ClientError(ErrDefs.cheatError)
		gateID = self.input.get('gateID', None)
		cardIDs = self.input.get('cardIDs', None)
		if not cardIDs:
			cardIDs = self.game.role.huodong_cards.get(EndlessTowerHuodongID, copy.deepcopy(self.game.role.battle_cards))
		else:
			self.game.role.deployHuodongCards(EndlessTowerHuodongID, cardIDs)
			cardIDs = transform2list(cardIDs)

		if any([x is None for x in [gateID, cardIDs]]):
			raise ClientError('param miss')

		self.game.battle = ObjectEndlessTowerBattle(self.game)
		ret = self.game.battle.begin(gateID, cardIDs)
		self.write({
			'model': ret
		})


# 无限塔关卡战斗结束
class EndlessTowerBattleEnd(RequestHandlerTask):
	url = r'/game/endless/battle/end'

	@coroutine
	def run(self):
		if not isinstance(self.game.battle, ObjectEndlessTowerBattle):
			raise ServerError('endlessTower battle miss')

		battleID = self.input.get('battleID', None)
		gateID = self.input.get('gateID', None)
		result = self.input.get('result', None)
		round = self.input.get('round', None)
		actions = self.input.get('actions', None)

		if any([x is None for x in [gateID, battleID, result]]):
			raise ClientError('param miss')
		if gateID != self.game.battle.gateID:
			raise ClientError('gateID error')
		if battleID != self.game.battle.id:
			raise ClientError('battleID error')

		# lua的msgpack会把顺序数值下标的table认为是list
		if isinstance(actions, list):
			actions = {idx + 1: v for idx, v in enumerate(actions)}

		if result == 'win':
			cfg = csv.endless_tower_scene[gateID]
			if self.game.role.top6_fighting_point < cfg.lowestFightingPoint:
				raise ClientError(ErrDefs.lowestFightingPointLimit)

		role = self.game.role
		self.game.battle.combine(result, round, actions)
		if self.rpcAnti and result == 'win':
			ObjectEndlessTowerGlobal.sendToAntiCheatCheck(role.uid, role.id, role.name, self.game.battle.battle_model, result, self.rpcAnti)

		# 运营活动 双倍掉落
		yyTimes = 1
		if role.endless_tower_current <= role.endless_tower_max_gate:
			yyID = ObjectYYHuoDongFactory.getDoubleDropOpenID(YYHuoDongDefs.DoubleEndlessSaodang)
			if yyID:
				yyTimes = 2
		# 战斗结算
		eff = self.game.battle.result(result, round, actions)
		if eff:
			yield effectAutoGain(eff, self.game, self.dbcGame, src='endlessTower_drop_%d' % gateID, mul=yyTimes)

		# 战斗结算完毕
		ret = self.game.battle.end()
		ret['view']['drop'] = eff.result
		if self.game.battle.isUpdRank:
			yield ObjectRankGlobal.onKeyInfoChange(self.game, 'endless')
		self.write(ret)

		if result == 'win':
			self.game.dailyRecord.endless_challenge += 1
			if round is not None and actions is not None:
				first = True if self.game.role.endless_tower_current > self.game.role.endless_tower_max_gate else False
				if first:  # 记录首通的战报
					ObjectEndlessTowerGlobal.recordPlay(self.game.battle.battle_model, self.game.role)
					ObjectMessageGlobal.marqueeBroadcast(self.game.role, MessageDefs.MqEndlessTowerPass, num=role.endless_tower_current-1)
					ObjectMessageGlobal.newsEndlessTowerPassMsg(self.game.role, role.endless_tower_current-1)
		self.game.battle = None


# 无限塔 扫荡
class EndlessTowerSaodang(RequestHandlerTask):
	url = r'/game/endless/saodang'

	@coroutine
	def run(self):
		if not ObjectFeatureUnlockCSV.isOpen(FeatureDefs.EndlessTower, self.game):
			raise ClientError('locked')

		# 扫荡指定到关卡ID
		gateID = self.input.get('gateID', None)

		battle = ObjectEndlessTowerSaoDang(self.game)
		# 战斗数据
		battle.begin(gateID)

		# gateID 不传: 一键扫荡，否则: 关卡扫荡
		if gateID:
			self.game.dailyRecord.endless_challenge += 1
		else:
			count = self.game.role.endless_tower_max_gate - self.game.role.endless_tower_current + 1
			self.game.dailyRecord.endless_challenge += count

		# 战斗结算
		result = []
		# 运营活动 双倍掉落
		yyTimes = 1
		yyID = ObjectYYHuoDongFactory.getDoubleDropOpenID(YYHuoDongDefs.DoubleEndlessSaodang)
		if yyID:
			yyTimes = 2

		# 重聚进度赶超 扫荡翻倍
		cfg = ObjectYYHuoDongFactory.getReunionCatchUpCfg(self.game.role, ReunionDefs.EndlessSaodang)
		if cfg and self.game.role.canReunionCatchUp(cfg):
			self.game.role.addReunionCatchUpRecord(cfg.id)
			yyTimes = 2

		effAll = battle.result()
		for eff in effAll:
			if eff:
				yield effectAutoGain(eff, self.game, self.dbcGame, src='endlessTower_saodang_drop', mul=yyTimes)
			result.append(eff.result)

		# 战斗结算完毕
		ret = battle.end()

		ret['view']['result'] = result

		self.write(ret)
		ta.track(self.game, event='endless_mopping_up',mopping_up_number=self.game.dailyRecord.endless_challenge)


# 无限塔 重置
class EndlessTowerReset(RequestHandlerTask):
	url = r'/game/endless/reset'

	@coroutine
	def run(self):
		resetTimes = self.game.dailyRecord.endless_tower_reset_times
		if self.game.role.endless_tower_current == ObjectEndlessTowerGlobal.MinGate:
			raise ClientError('can not reset')
		if resetTimes >= self.game.role.endlessTowerResetTimes:
			raise ClientError('endlessTower resetTimes has run out')
		else:
			cost = ObjectCostAux(self.game, {'rmb': ObjectCostCSV.getEndlessTowerResetTimesCost(resetTimes)})
			if not cost.isEnough():
				raise ClientError(ErrDefs.buyRMBNotEnough)
			cost.cost(src="endless_reset_times")
			resetTimes = resetTimes + 1
		self.game.role.endless_tower_current = ObjectEndlessTowerGlobal.MinGate
		self.game.dailyRecord.endless_tower_reset_times = resetTimes

		ta.track(self.game, event='endless_level_reset',current_reset_number=resetTimes)

# 无限塔 战报列表
class EndlessTowerPlays(RequestHandlerTask):
	url = r'/game/endless/plays/list'

	@coroutine
	def run(self):
		gateID = self.input.get('gateID', None)
		if not gateID:
			raise ClientError('param miss')
		latesPlays = ObjectEndlessTowerGlobal.getLatestPlays(gateID)

		self.write({
			'view': {
				'latesPlays': latesPlays,
			}
		})


# 无限塔 战报详情
class EndlessTowerLowerPlayDetail(RequestHandlerTask):
	url = r'/game/endless/play/detail'

	@coroutine
	def run(self):
		playID = self.input.get('playID', None)
		if not playID:
			raise ClientError('param miss')

		playRecordData = yield self.dbcGame.call_async('DBRead', 'PVEBattlePlayRecord', playID, False)
		if not playRecordData['ret']:
			raise ClientError(ErrDefs.playRecordNotFound)
		else:
			model = playRecordData['model']

		self.write({
			'model': {
				'endless_playrecords': {
					playID: model
				}
			}
		})




