#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2014 YouMi Information Technology Inc.

Hunting Handlers
'''
from framework.csv import csv, ErrDefs
from framework.helper import transform2list
from framework.log import logger
from game import ClientError
from game.handler import RequestHandlerTask
from game.handler.inl import effectAutoGain
from game.object import FeatureDefs, HuntingDefs, AchievementDefs, TargetDefs
from game.object.game import ObjectCostCSV, ObjectYYHuoDongFactory
from game.object.game.battle import ObjectHuntingBattle
from game.object.game.gain import ObjectGainAux, ObjectCostAux
from game.object.game.levelcsv import ObjectFeatureUnlockCSV
from game.object.game.shop import ObjectHuntingShop
from game.thinkingdata import ta
from msgpackrpc.error import CallError
from tornado.gen import coroutine


# main请求 （同步model客户端)
class HuntingMain(RequestHandlerTask):
	url = r'/game/hunting/main'

	@coroutine
	def run(self):
		if not ObjectFeatureUnlockCSV.isOpen(FeatureDefs.Hunting, self.game):
			raise ClientError("hunting on open")

		role = self.game.role
		# 新建 HuntingRecord
		specialOpen = ObjectFeatureUnlockCSV.isOpen(FeatureDefs.SpecialHunting, self.game)
		if role.hunting_record_db_id is None:
			record = yield self.rpcHunting.call_async('CreateHuntingRecord', role.id, specialOpen)
			role.hunting_record_db_id = record['id']
		else:
			# 含刷新重置次数，在线玩家 客户端倒计时结束 主动请求。
			specialOpen = ObjectFeatureUnlockCSV.isOpen(FeatureDefs.SpecialHunting, self.game)
			record = yield self.rpcHunting.call_async('GetHuntingRecord', role.hunting_record_db_id, specialOpen)

		role.huntingSync = 1  # 标志已同步过
		self.write({
			'model': {
				'hunting': record
			}
		})


# 选择线路开始
class HuntingRouteBegin(RequestHandlerTask):
	url = r'/game/hunting/route/begin'

	@coroutine
	def run(self):
		if not ObjectFeatureUnlockCSV.isOpen(FeatureDefs.Hunting, self.game):
			raise ClientError("hunting on open")
		if self.game.role.hunting_record_db_id is None:
			raise ClientError('hunting need prepare')
		route = self.input.get('route', None)
		if not all([x is not None for x in [route]]):
			raise ClientError('param miss')
		if route not in [HuntingDefs.RouteType, HuntingDefs.SpecialRouteType]:
			raise ClientError('route error')
		if route == HuntingDefs.SpecialRouteType:
			if not ObjectFeatureUnlockCSV.isOpen(FeatureDefs.SpecialHunting, self.game):
				raise ClientError("special hunting on open")

		role = self.game.role
		battleCards = []
		# 上阵卡牌不能低于10级
		for cardID in role.battle_cards:
			if cardID:
				card = self.game.cards.getCard(cardID)
				if not card or (card and card.level < 10):
					battleCards.append(None)
				else:
					battleCards.append(cardID)
			else:
				battleCards.append(None)
		if len(filter(None, battleCards)) == 0:
			battleCards = []
		try:
			model = yield self.rpcHunting.call_async('HuntingRouteBegin', role.hunting_record_db_id, route, battleCards)
		except CallError, e:
			raise ClientError(e.msg)

		ta.track(self.game, event='hunting_begin',route=route)

		self.write({
			'model': {
				'hunting': model
			}
		})


# 手动结束线路
class HuntingRouteEnd(RequestHandlerTask):
	url = r'/game/hunting/route/end'

	@coroutine
	def run(self):
		if not ObjectFeatureUnlockCSV.isOpen(FeatureDefs.Hunting, self.game):
			raise ClientError("hunting on open")
		if self.game.role.hunting_record_db_id is None:
			raise ClientError('hunting need prepare')
		route = self.input.get('route', None)
		if not all([x is not None for x in [route]]):
			raise ClientError('param miss')
		if route not in [HuntingDefs.RouteType, HuntingDefs.SpecialRouteType]:
			raise ClientError('route error')
		if route == HuntingDefs.SpecialRouteType:
			if not ObjectFeatureUnlockCSV.isOpen(FeatureDefs.SpecialHunting, self.game):
				raise ClientError("special hunting on open")

		role = self.game.role
		try:
			model = yield self.rpcHunting.call_async('HuntingRouteEnd', role.hunting_record_db_id, route)
		except ClientError, e:
			mes = e.log_message
			if mes in (ErrDefs.huntingClosed):
				specialOpen = ObjectFeatureUnlockCSV.isOpen(FeatureDefs.SpecialHunting, self.game)
				record = yield self.rpcHunting.call_async('GetHuntingRecord', role.hunting_record_db_id, specialOpen)
				self.write({'model': {'hunting': record}})
				raise ClientError(mes, model=record)
			raise ClientError(mes)

		self.write({
			'model': {
				'hunting': model
			}
		})


# 战斗关查看详情
class HuntingBattleInfo(RequestHandlerTask):
	url = r'/game/hunting/battle/info'

	@coroutine
	def run(self):
		if not ObjectFeatureUnlockCSV.isOpen(FeatureDefs.Hunting, self.game):
			raise ClientError("hunting on open")
		if self.game.role.hunting_record_db_id is None:
			raise ClientError('hunting need prepare')
		route = self.input.get('route', None)
		node = self.input.get('node', None)
		gateID = self.input.get('gateID', None)
		if not all([x is not None for x in [route, node, gateID]]):
			raise ClientError('param miss')
		if route not in [HuntingDefs.RouteType, HuntingDefs.SpecialRouteType]:
			raise ClientError('route error')
		if route == HuntingDefs.SpecialRouteType:
			if not ObjectFeatureUnlockCSV.isOpen(FeatureDefs.SpecialHunting, self.game):
				raise ClientError("special hunting on open")
		nodeType = csv.cross.hunting.route[node].type
		if nodeType != HuntingDefs.BattleType and nodeType != HuntingDefs.MultiType:
			raise ClientError("node is not battle")

		role = self.game.role
		fixAllFp = 0
		# top_cards: [Card.id, ...]
		for topCard in role.top_cards[:6]:
			card = self.game.cards.getCard(topCard)
			if card:
				fixAllFp += card.calcFightingPoint2()
		fixAllFp = int(fixAllFp * csv.cross.hunting.gate[gateID].fightingPointC)

		try:
			resp = yield self.rpcHunting.call_async('GetHuntingBattleInfo', role.hunting_record_db_id, route, node, gateID, fixAllFp)
		except ClientError, e:
			mes = e.log_message
			if mes in (ErrDefs.huntingClosed):
				specialOpen = ObjectFeatureUnlockCSV.isOpen(FeatureDefs.SpecialHunting, self.game)
				record = yield self.rpcHunting.call_async('GetHuntingRecord', role.hunting_record_db_id, specialOpen)
				self.write({'model': {'hunting': record}})
				raise ClientError(mes, model=record)
			raise ClientError(mes)

		model = resp['record']
		self.write({
			'model': {
				'hunting': model
			},
			'view': {
				'defence_role_info': resp['defence_role_info']
			}
		})


# 战斗关手动布阵
class HuntingBattleDeploy(RequestHandlerTask):
	url = r'/game/hunting/battle/deploy'

	@coroutine
	def run(self):
		if not ObjectFeatureUnlockCSV.isOpen(FeatureDefs.Hunting, self.game):
			raise ClientError("hunting on open")
		if self.game.role.hunting_record_db_id is None:
			raise ClientError('hunting need prepare')
		route = self.input.get('route', None)
		node = self.input.get('node', None)
		cardIDs = self.input.get('cardIDs', None)
		if not all([x is not None for x in [route, node, cardIDs]]):
			raise ClientError('param miss')
		if route not in [HuntingDefs.RouteType, HuntingDefs.SpecialRouteType]:
			raise ClientError('route error')
		if route == HuntingDefs.SpecialRouteType:
			if not ObjectFeatureUnlockCSV.isOpen(FeatureDefs.SpecialHunting, self.game):
				raise ClientError("special hunting on open")
		nodeType = csv.cross.hunting.route[node].type
		if nodeType != HuntingDefs.BattleType and nodeType != HuntingDefs.MultiType:
			raise ClientError("node is not battle")

		cardIDs = transform2list(cardIDs)
		if len(cardIDs) != 6:
			raise ClientError(ErrDefs.battleCardCountLimit)
		if self.game.cards.isDuplicateMarkID(cardIDs):
			raise ClientError(ErrDefs.battleCardMarkIDError)

		battleCards = []
		# 上阵卡牌不能低于10级
		for cardID in cardIDs:
			if cardID:
				card = self.game.cards.getCard(cardID)
				if not card or (card and card.level < 10):
					battleCards.append(None)
				else:
					battleCards.append(cardID)
			else:
				battleCards.append(None)
		# 全None的保护
		if len(filter(None, battleCards)) == 0:
			raise ClientError("cardIDs error")

		role = self.game.role
		try:
			model = yield self.rpcHunting.call_async('DeployHuntingCards', role.hunting_record_db_id, route, battleCards)
		except ClientError, e:
			mes = e.log_message
			if mes in (ErrDefs.huntingClosed):
				specialOpen = ObjectFeatureUnlockCSV.isOpen(FeatureDefs.SpecialHunting, self.game)
				record = yield self.rpcHunting.call_async('GetHuntingRecord', role.hunting_record_db_id, specialOpen)
				self.write({'model': {'hunting': record}})
				raise ClientError(mes, model=record)
			raise ClientError(mes)

		self.write({
			'model': {
				'hunting': model,
			}
		})


# 战斗关开始挑战
class HuntingBattleStart(RequestHandlerTask):
	url = r'/game/hunting/battle/start'

	@coroutine
	def run(self):
		if not ObjectFeatureUnlockCSV.isOpen(FeatureDefs.Hunting, self.game):
			raise ClientError("hunting on open")
		if self.game.role.hunting_record_db_id is None:
			raise ClientError('hunting need prepare')
		route = self.input.get('route', None)
		node = self.input.get('node', None)
		gateID = self.input.get('gateID', None)
		cardIDs = self.input.get('cardIDs', None)
		if not all([x is not None for x in [route, node, gateID, cardIDs]]):
			raise ClientError('param miss')
		if route not in [HuntingDefs.RouteType, HuntingDefs.SpecialRouteType]:
			raise ClientError('route error')
		if route == HuntingDefs.SpecialRouteType:
			if not ObjectFeatureUnlockCSV.isOpen(FeatureDefs.SpecialHunting, self.game):
				raise ClientError("special hunting on open")
		nodeType = csv.cross.hunting.route[node].type
		if nodeType != HuntingDefs.BattleType and nodeType != HuntingDefs.MultiType:
			raise ClientError("node is not battle")

		cardIDs = transform2list(cardIDs)
		if len(cardIDs) != 6:
			raise ClientError(ErrDefs.battleCardCountLimit)
		if self.game.cards.isDuplicateMarkID(cardIDs):
			raise ClientError(ErrDefs.battleCardMarkIDError)

		battleCards = []
		# 上阵卡牌不能低于10级
		for cardID in cardIDs:
			if cardID:
				card = self.game.cards.getCard(cardID)
				if not card or (card and card.level < 10):
					battleCards.append(None)
				else:
					battleCards.append(cardID)
			else:
				battleCards.append(None)
		# 全None的保护
		if len(filter(None, battleCards)) == 0:
			raise ClientError("cardIDs error")

		self.game.battle = ObjectHuntingBattle(self.game)
		battleModel = self.game.battle.begin(route, gateID, battleCards)

		role = self.game.role
		try:
			resp = yield self.rpcHunting.call_async('HuntingBattleStart', role.hunting_record_db_id, route, node, battleModel)
		except ClientError, e:
			mes = e.log_message
			if mes in (ErrDefs.huntingClosed):
				specialOpen = ObjectFeatureUnlockCSV.isOpen(FeatureDefs.SpecialHunting, self.game)
				record = yield self.rpcHunting.call_async('GetHuntingRecord', role.hunting_record_db_id, specialOpen)
				self.write({'model': {'hunting': record}})
				raise ClientError(mes, model=record)
			raise ClientError(mes)

		respBattleModel = resp['battle_model']
		self.game.battle.id = respBattleModel['id']
		self.game.battle.cardIDs = respBattleModel['cards']
		self.game.battle.enemyCardIDs = respBattleModel['defence_cards']
		self.game.battle.node = node

		self.write({
			'model': {
				'hunting': resp['record'],
				'hunting_battle': resp['battle_model']
			}
		})


# 战斗关结束挑战
class HuntingBattleEnd(RequestHandlerTask):
	url = r'/game/hunting/battle/end'

	@coroutine
	def run(self):
		if self.game.role.hunting_record_db_id is None:
			raise ClientError('hunting need prepare')
		battleID = self.input.get('battleID', None)
		result = self.input.get('result', None)
		cardStates = self.input.get('cardStates', None)
		enemyStates = self.input.get('enemyStates', None)
		damage = self.input.get('damage', None)
		actions = self.input.get('actions', None)

		if not all([x is not None for x in [battleID, result, cardStates, enemyStates, damage]]):
			raise ClientError('param miss')
		if battleID != self.game.battle.id:
			raise ClientError('battleID error')
		if damage < 0:
			raise ClientError('damage error')
		damage = int(damage)
		# 伤害保护
		if damage > self.game.battle.maxDamage():
			logger.warning("role %d hunting battle damage %d cheat can max %d", self.game.role.uid, damage, self.game.battle.maxDamage())
			raise ClientError(ErrDefs.rankCheat)

		battle = self.game.battle
		battle.resultStatesOK(cardStates, enemyStates)
		# 死亡卡牌 下阵
		for i, cardID in enumerate(battle.cardIDs):
			if cardID and cardStates[cardID][0] <= 0:
				battle.cardIDs[i] = None

		role = self.game.role
		req = {
			"record_id": role.hunting_record_db_id,
			"result": result,
			"route": battle.route,
			"gate_id": battle.gateID,
			"card_ids": battle.cardIDs,
			"card_states": cardStates,
			"enemy_states": enemyStates,
			"damage": float(damage),
			"max_damage": float(self.game.battle.maxDamage()),
			"actions": actions,
		}

		try:
			resp = yield self.rpcHunting.call_async('HuntingBattleEnd', req)
			record = resp['record']
			if resp['is_pass']:
				if battle.route == HuntingDefs.RouteType:
					self.game.achievement.onCount(AchievementDefs.HuntingPass, 1)
					ObjectYYHuoDongFactory.onGeneralTask(self.game, TargetDefs.HuntingPass, 1)
				elif battle.route == HuntingDefs.SpecialRouteType:
					self.game.achievement.onCount(AchievementDefs.HuntingSpecialPass, 1)
					ObjectYYHuoDongFactory.onGeneralTask(self.game, TargetDefs.HuntingSpecialPass, 1)
		except ClientError, e:
			mes = e.log_message
			if mes in (ErrDefs.huntingClosed):
				specialOpen = ObjectFeatureUnlockCSV.isOpen(FeatureDefs.SpecialHunting, self.game)
				record = yield self.rpcHunting.call_async('GetHuntingRecord', role.hunting_record_db_id, specialOpen)
				self.write({'model': {'hunting': record}})
				raise ClientError(mes, model=record)
			raise ClientError(mes)

		# 战斗结算
		drop = None
		if result == 'win':
			cfg = csv.cross.hunting.gate[battle.gateID]
			drop = cfg.drops
		view = {'result': result}
		if drop:
			eff = ObjectGainAux(self.game, drop)
			yield effectAutoGain(eff, self.game, self.dbcGame, src='hunting_battle_award')
			view['drop'] = eff.result
		self.game.battle = None

		if result == 'win':
			ta.track(self.game, event='hunting_battle_win',route=battle.route, gate_id=battle.gateID, node=battle.node)

		self.write({
			'model': {
				'hunting': record
			},
			'view': view
		})


# 战斗关碾压
class HuntingBattlePass(RequestHandlerTask):
	url = r'/game/hunting/battle/pass'

	@coroutine
	def run(self):
		if not ObjectFeatureUnlockCSV.isOpen(FeatureDefs.Hunting, self.game):
			raise ClientError("hunting on open")
		if not ObjectFeatureUnlockCSV.isOpen(FeatureDefs.HuntingPass, self.game):
			raise ClientError("hunting pass on open")
		if self.game.role.hunting_record_db_id is None:
			raise ClientError('hunting need prepare')
		route = self.input.get('route', None)
		node = self.input.get('node', None)
		gateID = self.input.get('gateID', None)
		if not all([x is not None for x in [route, node, gateID]]):
			raise ClientError('param miss')
		if route not in [HuntingDefs.RouteType, HuntingDefs.SpecialRouteType]:
			raise ClientError('route error')
		if route == HuntingDefs.SpecialRouteType:
			if not ObjectFeatureUnlockCSV.isOpen(FeatureDefs.SpecialHunting, self.game):
				raise ClientError("special hunting on open")
			if not ObjectFeatureUnlockCSV.isOpen(FeatureDefs.SpecialHuntingPass, self.game):
				raise ClientError("special hunting pass on open")
		nodeType = csv.cross.hunting.route[node].type
		if nodeType != HuntingDefs.BattleType and nodeType != HuntingDefs.MultiType:
			raise ClientError("node is not battle")

		role = self.game.role
		specialOpen = ObjectFeatureUnlockCSV.isOpen(FeatureDefs.SpecialHunting, self.game)
		record = yield self.rpcHunting.call_async('GetHuntingRecord', role.hunting_record_db_id, specialOpen)
		routeInfo = record['hunting_route'][route]
		cardStates = routeInfo["card_states"]

		# 存活中的战力前10位
		allCards = self.game.cards.getAllCards()
		cards = allCards.values()
		cards.sort(key=lambda o: o.fighting_point, reverse=True)
		top10Cards = []
		for card in cards:
			if len(top10Cards) >= 10:
				break
			if card.level < 10:
				continue
			hp, mp = cardStates.get(card.id, (1.0, 0.0))
			if hp > 0:
				top10Cards.append(card.id)

		try:
			resp = yield self.rpcHunting.call_async('HuntingBattlePass', role.hunting_record_db_id, route, node, gateID, top10Cards)
			record = resp['record']
			if resp['is_pass']:
				if route == HuntingDefs.RouteType:
					self.game.achievement.onCount(AchievementDefs.HuntingPass, 1)
					ObjectYYHuoDongFactory.onGeneralTask(self.game, TargetDefs.HuntingPass, 1)
				elif route == HuntingDefs.SpecialRouteType:
					self.game.achievement.onCount(AchievementDefs.HuntingSpecialPass, 1)
					ObjectYYHuoDongFactory.onGeneralTask(self.game, TargetDefs.HuntingSpecialPass, 1)
		except ClientError, e:
			mes = e.log_message
			if mes in (ErrDefs.huntingClosed):
				specialOpen = ObjectFeatureUnlockCSV.isOpen(FeatureDefs.SpecialHunting, self.game)
				record = yield self.rpcHunting.call_async('GetHuntingRecord', role.hunting_record_db_id, specialOpen)
				self.write({'model': {'hunting': record}})
				raise ClientError(mes, model=record)
			raise ClientError(mes)

		# 碾压结算
		cfg = csv.cross.hunting.gate[gateID]
		eff = ObjectGainAux(self.game, cfg.drops)
		yield effectAutoGain(eff, self.game, self.dbcGame, src='hunting_battle_award')

		self.write({
			'model': {
				'hunting': record
			},
			'view': {
				'result': 'win',
				'drop': eff.result
			}
		})


# 战斗关选择buff（三选一）
class HuntingBattleChoose(RequestHandlerTask):
	url = r'/game/hunting/battle/choose'

	@coroutine
	def run(self):
		if not ObjectFeatureUnlockCSV.isOpen(FeatureDefs.Hunting, self.game):
			raise ClientError("hunting on open")
		if self.game.role.hunting_record_db_id is None:
			raise ClientError('hunting need prepare')
		route = self.input.get('route', None)
		node = self.input.get('node', None)
		boardID = self.input.get('boardID', None)
		if not all([x is not None for x in [route, node, boardID]]):
			raise ClientError('param miss')
		if route not in [HuntingDefs.RouteType, HuntingDefs.SpecialRouteType]:
			raise ClientError('route error')
		if boardID <= 0 or boardID > 3:
			raise ClientError('boardID error')
		if route == HuntingDefs.SpecialRouteType:
			if not ObjectFeatureUnlockCSV.isOpen(FeatureDefs.SpecialHunting, self.game):
				raise ClientError("special hunting on open")
		nodeType = csv.cross.hunting.route[node].type
		if nodeType != HuntingDefs.BattleType and nodeType != HuntingDefs.MultiType:
			raise ClientError("node is not battle")

		role = self.game.role
		try:
			resp = yield self.rpcHunting.call_async('HuntingBattleChoose', role.hunting_record_db_id, route, node, boardID)
			model = resp['record']
			if resp['is_pass']:
				if route == HuntingDefs.RouteType:
					self.game.achievement.onCount(AchievementDefs.HuntingPass, 1)
					ObjectYYHuoDongFactory.onGeneralTask(self.game, TargetDefs.HuntingPass, 1)
				elif route == HuntingDefs.SpecialRouteType:
					self.game.achievement.onCount(AchievementDefs.HuntingSpecialPass, 1)
					ObjectYYHuoDongFactory.onGeneralTask(self.game, TargetDefs.HuntingSpecialPass, 1)
		except ClientError, e:
			mes = e.log_message
			if mes in (ErrDefs.huntingClosed):
				specialOpen = ObjectFeatureUnlockCSV.isOpen(FeatureDefs.SpecialHunting, self.game)
				record = yield self.rpcHunting.call_async('GetHuntingRecord', role.hunting_record_db_id, specialOpen)
				self.write({'model': {'hunting': record}})
				raise ClientError(mes, model=record)
			raise ClientError(mes)

		self.write({
			'model': {
				'hunting': model
			}
		})


# 宝箱关打开宝箱
class HuntingBoxOpen(RequestHandlerTask):
	url = r'/game/hunting/box/open'

	@coroutine
	def run(self):
		if not ObjectFeatureUnlockCSV.isOpen(FeatureDefs.Hunting, self.game):
			raise ClientError("hunting on open")
		if self.game.role.hunting_record_db_id is None:
			raise ClientError('hunting need prepare')
		route = self.input.get('route', None)
		node = self.input.get('node', None)
		if not all([x is not None for x in [route, node]]):
			raise ClientError('param miss')
		if route not in [HuntingDefs.RouteType, HuntingDefs.SpecialRouteType]:
			raise ClientError('route error')
		if route == HuntingDefs.SpecialRouteType:
			if not ObjectFeatureUnlockCSV.isOpen(FeatureDefs.SpecialHunting, self.game):
				raise ClientError("special hunting on open")
		nodeType = csv.cross.hunting.route[node].type
		if nodeType != HuntingDefs.BoxType and nodeType != HuntingDefs.MultiType:
			raise ClientError("node is not box")
		role = self.game.role
		specialOpen = ObjectFeatureUnlockCSV.isOpen(FeatureDefs.SpecialHunting, self.game)
		record = yield self.rpcHunting.call_async('GetHuntingRecord', role.hunting_record_db_id, specialOpen)
		routeInfo = record['hunting_route'][route]
		if routeInfo.get('node', 0) != node:
			raise ClientError("node error")
		if routeInfo['status'] != "starting":
			raise ClientError("status error")
		cfgBase = csv.cross.hunting.base[route]
		if routeInfo.get('box_open_count', 0) >= cfgBase.boxOpenLimit:
			raise ClientError("box open is limit")

		cfg = csv.cross.hunting.route[node]
		eff = ObjectGainAux(self.game, {})
		# 首次
		count = routeInfo.get('box_open_count', 0)
		if count == 0:
			eff += ObjectGainAux(self.game, cfg['boxDropLibs'])
		else:
			costRMB = ObjectCostCSV.getHuntingBoxCost(count-1)
			cost = ObjectCostAux(self.game, {'rmb': costRMB})
			if not cost.isEnough():
				raise ClientError('cost rmb no enough')
			eff += ObjectGainAux(self.game, cfg['boxDropLibs2'])
			cost.cost(src='hunting_box_award')

		try:
			resp = yield self.rpcHunting.call_async('HuntingOpenBox', role.hunting_record_db_id, route, node)
			model = resp['record']
			if resp['is_pass']:
				if route == HuntingDefs.RouteType:
					self.game.achievement.onCount(AchievementDefs.HuntingPass, 1)
					ObjectYYHuoDongFactory.onGeneralTask(self.game, TargetDefs.HuntingPass, 1)
				elif route == HuntingDefs.SpecialRouteType:
					self.game.achievement.onCount(AchievementDefs.HuntingSpecialPass, 1)
					ObjectYYHuoDongFactory.onGeneralTask(self.game, TargetDefs.HuntingSpecialPass, 1)
		except ClientError, e:
			mes = e.log_message
			if mes in (ErrDefs.huntingClosed):
				specialOpen = ObjectFeatureUnlockCSV.isOpen(FeatureDefs.SpecialHunting, self.game)
				record = yield self.rpcHunting.call_async('GetHuntingRecord', role.hunting_record_db_id, specialOpen)
				self.write({'model': {'hunting': record}})
				raise ClientError(mes, model=record)
			raise ClientError(mes)

		if eff:
			yield effectAutoGain(eff, self.game, self.dbcGame, src='hunting_box_award')

		self.write({
			'model': {
				'hunting': model
			},
			'view': eff.result
		})


# 手动往下一节点走（提供宝箱使用）
class HuntingNext(RequestHandlerTask):
	url = r'/game/hunting/next'

	@coroutine
	def run(self):
		if not ObjectFeatureUnlockCSV.isOpen(FeatureDefs.Hunting, self.game):
			raise ClientError("hunting on open")
		if self.game.role.hunting_record_db_id is None:
			raise ClientError('hunting need prepare')
		route = self.input.get('route', None)
		if not all([x is not None for x in [route]]):
			raise ClientError('param miss')
		if route not in [HuntingDefs.RouteType, HuntingDefs.SpecialRouteType]:
			raise ClientError('route error')
		if route == HuntingDefs.SpecialRouteType:
			if not ObjectFeatureUnlockCSV.isOpen(FeatureDefs.SpecialHunting, self.game):
				raise ClientError("special hunting on open")

		role = self.game.role
		try:
			resp = yield self.rpcHunting.call_async('HuntingNextNode', role.hunting_record_db_id, route)
			model = resp['record']
			if resp['is_pass']:
				if route == HuntingDefs.RouteType:
					self.game.achievement.onCount(AchievementDefs.HuntingPass, 1)
					ObjectYYHuoDongFactory.onGeneralTask(self.game, TargetDefs.HuntingPass, 1)
				elif route == HuntingDefs.SpecialRouteType:
					self.game.achievement.onCount(AchievementDefs.HuntingSpecialPass, 1)
					ObjectYYHuoDongFactory.onGeneralTask(self.game, TargetDefs.HuntingSpecialPass, 1)
		except ClientError, e:
			mes = e.log_message
			if mes in (ErrDefs.huntingClosed):
				specialOpen = ObjectFeatureUnlockCSV.isOpen(FeatureDefs.SpecialHunting, self.game)
				record = yield self.rpcHunting.call_async('GetHuntingRecord', role.hunting_record_db_id, specialOpen)
				self.write({'model': {'hunting': record}})
				raise ClientError(mes, model=record)
			raise ClientError(mes)

		self.write({
			'model': {
				'hunting': model
			}
		})


# 救援关补给
class HuntingSupply(RequestHandlerTask):
	url = r'/game/hunting/supply'

	@coroutine
	def run(self):
		if not ObjectFeatureUnlockCSV.isOpen(FeatureDefs.Hunting, self.game):
			raise ClientError("hunting on open")
		if self.game.role.hunting_record_db_id is None:
			raise ClientError('hunting need prepare')
		route = self.input.get('route', None)
		node = self.input.get('node', None)
		csvID = self.input.get('csvID', None)  # 补给csvID
		cardID = self.input.get('cardID', None)  # 全体恢复不传
		if not all([x is not None for x in [route, node, csvID]]):
			raise ClientError('param miss')
		if route not in [HuntingDefs.RouteType, HuntingDefs.SpecialRouteType]:
			raise ClientError('route error')
		if route == HuntingDefs.SpecialRouteType:
			if not ObjectFeatureUnlockCSV.isOpen(FeatureDefs.SpecialHunting, self.game):
				raise ClientError("special hunting on open")
		nodeType = csv.cross.hunting.route[node].type
		if nodeType != HuntingDefs.SupplyType and nodeType != HuntingDefs.MultiType:
			raise ClientError("node is not supply")

		if cardID:
			card = self.game.cards.getCard(cardID)
			if not card:
				raise ClientError("card is not exist")
			if card.level < 10:
				raise ClientError("card level less than 10")

		role = self.game.role
		try:
			resp = yield self.rpcHunting.call_async('HuntingSupply', role.hunting_record_db_id, route, node, csvID, cardID)
			model = resp['record']
			if resp['is_pass']:
				if route == HuntingDefs.RouteType:
					self.game.achievement.onCount(AchievementDefs.HuntingPass, 1)
					ObjectYYHuoDongFactory.onGeneralTask(self.game, TargetDefs.HuntingPass, 1)
				elif route == HuntingDefs.SpecialRouteType:
					self.game.achievement.onCount(AchievementDefs.HuntingSpecialPass, 1)
					ObjectYYHuoDongFactory.onGeneralTask(self.game, TargetDefs.HuntingSpecialPass, 1)
		except ClientError, e:
			mes = e.log_message
			if mes in (ErrDefs.huntingClosed):
				specialOpen = ObjectFeatureUnlockCSV.isOpen(FeatureDefs.SpecialHunting, self.game)
				record = yield self.rpcHunting.call_async('GetHuntingRecord', role.hunting_record_db_id, specialOpen)
				self.write({'model': {'hunting': record}})
				raise ClientError(mes, model=record)
			raise ClientError(mes)

		self.write({
			'model': {
				'hunting': model
			}
		})


# 组合关选择
class HuntingBoardChoose(RequestHandlerTask):
	url = r'/game/hunting/board/choose'

	@coroutine
	def run(self):
		if not ObjectFeatureUnlockCSV.isOpen(FeatureDefs.Hunting, self.game):
			raise ClientError("hunting on open")
		if self.game.role.hunting_record_db_id is None:
			raise ClientError('hunting need prepare')
		route = self.input.get('route', None)
		node = self.input.get('node', None)
		boardID = self.input.get('boardID', None)  # 1=宝箱;2=补给;100101=战斗
		if not all([x is not None for x in [route, node, boardID]]):
			raise ClientError('param miss')
		if route not in [HuntingDefs.RouteType, HuntingDefs.SpecialRouteType]:
			raise ClientError('route error')
		if route == HuntingDefs.SpecialRouteType:
			if not ObjectFeatureUnlockCSV.isOpen(FeatureDefs.SpecialHunting, self.game):
				raise ClientError("special hunting on open")
		if csv.cross.hunting.route[node].type != HuntingDefs.MultiType:
			raise ClientError("node is not multi")
		if boardID == 1:
			if not csv.cross.hunting.route[node].boxDropLibs:
				raise ClientError("boardID error ")
		elif boardID == 2:
			if not csv.cross.hunting.route[node].supplyGroup:
				raise ClientError("boardID error ")
		else:
			if boardID not in csv.cross.hunting.route[node].gateIDs:
				raise ClientError("boardID error ")

		role = self.game.role
		try:
			model = yield self.rpcHunting.call_async('HuntingBoardChoose', role.hunting_record_db_id, route, node, boardID)
		except ClientError, e:
			mes = e.log_message
			if mes in (ErrDefs.huntingClosed):
				specialOpen = ObjectFeatureUnlockCSV.isOpen(FeatureDefs.SpecialHunting, self.game)
				record = yield self.rpcHunting.call_async('GetHuntingRecord', role.hunting_record_db_id, specialOpen)
				self.write({'model': {'hunting': record}})
				raise ClientError(mes, model=record)
			raise ClientError(mes)

		self.write({
			'model': {
				'hunting': model
			}
		})


# 远征商店
class HuntingShop(RequestHandlerTask):
	url = r'/game/hunting/shop'

	@coroutine
	def run(self):
		if not ObjectFeatureUnlockCSV.isOpen(FeatureDefs.Hunting, self.game):
			raise ClientError("hunting on open")

		csvID = self.input.get('csvID', None)
		count = self.input.get('count', 1)
		if csvID is None:
			raise ClientError('param miss')
		if count <= 0:
			raise ClientError('param error')

		shop = ObjectHuntingShop(self.game)
		eff = yield shop.buyItem(csvID, count, src='hunting_shop_buy')
		yield effectAutoGain(eff, self.game, self.dbcGame, src='hunting_shop_buy')

