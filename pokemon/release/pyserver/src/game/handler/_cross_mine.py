#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2014 YouMi Information Technology Inc.

PVP Handlers
'''

from framework.csv import csv, ErrDefs
from framework.helper import transform2list
from framework.service.helper import game2pvp

from game import ClientError
from game.globaldata import CrossMineBossHuodongID
from game.handler import RequestHandlerTask
from game.handler.inl import effectAutoGain, effectAutoCost
from game.object import SceneDefs
from game.object.game import ObjectGame, ObjectCostCSV
from game.object.game.cross_mine import ObjectCrossMineGameGlobal
from game.object.game.shop import ObjectCrossMineShop
from game.object.game.gain import ObjectCostAux, ObjectGainAux

from tornado.gen import coroutine, Return


@coroutine
def makeCrossMineModel(game, rpc, refresh, rpcPVP):
	role = game.role
	if not role.cross_mine_record_db_id:
		raise Return({'cross_mine': {}})

	model = {}

	record = yield rpcPVP.call_async('GetCrossMineRecord', role.cross_mine_record_db_id)
	model['record'] = record
	if ObjectCrossMineGameGlobal.isOpen(role.areaKey):
		# 阵容有为空特殊情况处理
		cards = model['record']['cards']
		defenceCards = model['record']['defence_cards']
		cardsNeedRefresh = any(v == 0 or v > 4 for v in [len(filter(None, cards[i])) for i in range(1, 3 + 1)])
		defenceCardsNeedRefresh = any(v == 0 or v > 4 for v in [len(filter(None, defenceCards[i])) for i in range(1, 3 + 1)])
		if cardsNeedRefresh or defenceCardsNeedRefresh:
			cardsMap, _ = ObjectCrossMineGameGlobal.getCrossMineCards(role)
			newCards = None
			newDefenceCards = None
			if cardsNeedRefresh:
				newCards = cardsMap[1]
				newCards.extend(cardsMap[2])
				newCards.extend(cardsMap[3])
			if defenceCardsNeedRefresh:
				newDefenceCards = cardsMap[1]
				newDefenceCards.extend(cardsMap[2])
				newDefenceCards.extend(cardsMap[3])
			yield refreshCardsToCrossMine(rpcPVP, game, cards=newCards, defence_cards=newDefenceCards)
			record = yield rpcPVP.call_async('GetCrossMineRecord', role.cross_mine_record_db_id)
			model['record'] = record

		crossMineRoleInfo = game.role.crossRole(game.role.cross_mine_record_db_id)
		crossMineRoleInfo['fighting_point'] = game.role.top12_fighting_point
		resp = yield rpc.call_async('CrossMineGetModel', role.id, crossMineRoleInfo, refresh)
		yield ObjectCrossMineGameGlobal.SyncCoin13(game)
		model.update(resp)

		if resp['isNew']:
			yield rpcPVP.call_async('CleanCrossMineHistory', role.cross_mine_record_db_id)
			model['record']['history'] = []
	else:
		model.update(ObjectCrossMineGameGlobal.getLastSlimModel(role.areaKey))

	model.update(ObjectCrossMineGameGlobal.getCrossGameModel(role.areaKey))

	raise Return({
		'cross_mine': model,
	})


@coroutine
def refreshCardsToCrossMine(rpc, game, cards=None, defence_cards=None, force=False):
	if not game.role.cross_mine_record_db_id:
		raise Return(None)
	deployment = game.cards.deploymentForCrossMine
	# 卡牌没发生改变
	if not any([force, cards, defence_cards, deployment.isdirty()]):
		raise Return(None)

	embattle = {}

	# 进攻阵容
	if cards:
		cardsMap = {}  # {1:[card.id], 2:[card.id]}
		cardsMap[1] = transform2list(cards[:6])
		cardsMap[2] = transform2list(cards[6:12])
		cardsMap[3] = transform2list(cards[12:18])
		embattle['cards'] = cardsMap
	cards, dirty = deployment.refresh('cards', SceneDefs.CrossMine, cards)
	cardAttrs, cardAttrs12 = game.cards.makeBattleCardModel(cards[:6], SceneDefs.CrossMine, dirty=dirty[:6] if dirty else None)
	cardAttrs2, cardAttrs22 = game.cards.makeBattleCardModel(cards[6:12], SceneDefs.CrossMine, dirty=dirty[6:12] if dirty else None)
	cardAttrs3, cardAttrs32 = game.cards.makeBattleCardModel(cards[12:18], SceneDefs.CrossMine, dirty=dirty[12:18] if dirty else None)
	cardAttrs.update(cardAttrs2)
	cardAttrs.update(cardAttrs3)
	cardAttrs12.update(cardAttrs22)
	cardAttrs12.update(cardAttrs32)
	embattle['card_attrs'] = cardAttrs
	embattle['card_attrs2'] = cardAttrs12
	embattle['passive_skills'] = game.cards.markBattlePassiveSkills(cards, SceneDefs.CrossMine)

	# 防守阵容
	if defence_cards:
		defenceCardsMap = {}
		defenceCardsMap[1] = transform2list(defence_cards[:6])
		defenceCardsMap[2] = transform2list(defence_cards[6:12])
		defenceCardsMap[3] = transform2list(defence_cards[12:18])
		embattle['defence_cards'] = defenceCardsMap
	defence_cards, defence_dirty = deployment.refresh('defence_cards', SceneDefs.CrossMine, defence_cards)
	defenceCardAttrs, defenceCardAttrs12 = game.cards.makeBattleCardModel(defence_cards[:6], SceneDefs.CrossMine, dirty=defence_dirty[:6] if defence_dirty else None)
	defenceCardAttrs2, defenceCardAttrs22 = game.cards.makeBattleCardModel(defence_cards[6:12], SceneDefs.CrossMine, dirty=defence_dirty[6:12] if defence_dirty else None)
	defenceCardAttrs3, defenceCardAttrs32 = game.cards.makeBattleCardModel(defence_cards[12:18], SceneDefs.CrossMine, dirty=defence_dirty[12:18] if defence_dirty else None)
	defenceCardAttrs.update(defenceCardAttrs2)
	defenceCardAttrs.update(defenceCardAttrs3)
	defenceCardAttrs12.update(defenceCardAttrs22)
	defenceCardAttrs12.update(defenceCardAttrs32)
	embattle['defence_card_attrs'] = defenceCardAttrs
	embattle['defence_card_attrs2'] = defenceCardAttrs12
	embattle['defence_passive_skills'] = game.cards.markBattlePassiveSkills(defence_cards, SceneDefs.CrossMine)

	deployment.resetdirty()
	yield rpc.call_async('CrossMineDeployCards', game.role.cross_mine_record_db_id, game.role.competitor, embattle)

	if ObjectCrossMineGameGlobal.isOpen(game.role.areaKey):
		crossRpc = ObjectCrossMineGameGlobal.cross_client(game.role.areaKey)
		yield crossRpc.call_async('CrossMineUpdateRoleInfo', game.role.crossRole(game.role.cross_mine_record_db_id), game.role.top12_fighting_point)


# 跨服资源战主界面
class CrossMineMain(RequestHandlerTask):
	url = r'/game/cross/mine/main'

	@coroutine
	def run(self):
		role = self.game.role
		if not ObjectCrossMineGameGlobal.isRoleOpen(role.level):
			raise ClientError(ErrDefs.crossMineRoleLevelLimit)

		refresh = self.input.get('refresh', False)

		if role.cross_mine_record_db_id is None:
			cardsMap, cards = ObjectCrossMineGameGlobal.getCrossMineCards(role)
			passiveSkills = self.game.cards.markBattlePassiveSkills(cards, SceneDefs.CrossMine)

			cardAttrs, cardAttrs12 = self.game.cards.makeBattleCardModel(cardsMap[1], SceneDefs.CrossMine)
			cardAttrs2, cardAttrs22 = self.game.cards.makeBattleCardModel(cardsMap[2], SceneDefs.CrossMine)
			cardAttrs3, cardAttrs32 = self.game.cards.makeBattleCardModel(cardsMap[3], SceneDefs.CrossMine)
			cardAttrs.update(cardAttrs2)
			cardAttrs.update(cardAttrs3)
			cardAttrs12.update(cardAttrs22)
			cardAttrs12.update(cardAttrs32)

			embattle = {
				'cards': cardsMap,
				'card_attrs': cardAttrs,
				'card_attrs2': cardAttrs12,
				'passive_skills': passiveSkills,
				'defence_cards': cardsMap,
				'defence_card_attrs': cardAttrs,
				'defence_card_attrs2': cardAttrs12,
				'defence_passive_skills': passiveSkills,
			}
			role.cross_mine_record_db_id = yield self.rpcPVP.call_async('CreateCrossMineRecord', role.competitor, embattle)

			deployment = self.game.cards.deploymentForCrossMine
			deployment.deploy('cards', transform2list(cards, 18))
			deployment.deploy('defence_cards', transform2list(cards, 18))
		else:
			if refresh:
				coin13Cost = ObjectCostCSV.getCrossMineEnemyFreshCost(self.game.dailyRecord.cross_mine_enemy_refresh_times)
				cost = ObjectCostAux(self.game, {'coin13': coin13Cost})
				yield effectAutoCost(cost, self.game, src='cross_mine_enemy_refresh', errDef=ErrDefs.costNotEnough)
				self.game.dailyRecord.cross_mine_enemy_refresh_times += 1
			yield refreshCardsToCrossMine(self.rpcPVP, self.game)

		rpc = ObjectCrossMineGameGlobal.cross_client(role.areaKey)
		model = yield makeCrossMineModel(self.game, rpc, refresh, self.rpcPVP)
		self.write({'model': model})


# 布阵卡牌检测
def checkDeployCards(game, cards):
	if not cards:
		return cards

	cards = transform2list(cards, 18)
	if game.cards.isDuplicateMarkID(cards):
		raise ClientError('cards have duplicates')

	if any(v < 1 or v > 4 for v in [len(filter(None, cards[:6])), len(filter(None, cards[6:12])), len(filter(None, cards[12:18]))]):
		raise ClientError('have cards num error')

	return cards


# 跨服资源战布阵
class CrossMineBattleDeploy(RequestHandlerTask):
	url = r'/game/cross/mine/battle/deploy'

	@coroutine
	def run(self):
		if self.game.role.cross_mine_record_db_id is None:
			raise ClientError('cross mine not opened')

		if not ObjectCrossMineGameGlobal.isRoleOpen(self.game.role.level):
			raise ClientError(ErrDefs.crossMineRoleLevelLimit)

		cards = checkDeployCards(self.game, self.input.get('cards', None))
		defenceCards = checkDeployCards(self.game, self.input.get('defenceCards', None))

		yield refreshCardsToCrossMine(self.rpcPVP, self.game, cards=cards, defence_cards=defenceCards)
		rpc = ObjectCrossMineGameGlobal.cross_client(self.game.role.areaKey)
		model = yield makeCrossMineModel(self.game, rpc, False, self.rpcPVP)
		self.write({'model': model})


# 跨服资源战战斗开始
class CrossMineBattleStart(RequestHandlerTask):
	url = r'/game/cross/mine/battle/start'

	@coroutine
	def run(self):
		role = self.game.role
		if role.cross_mine_record_db_id is None:
			raise ClientError('cross mine not opened')

		if not ObjectCrossMineGameGlobal.isOpen(role.areaKey):
			raise ClientError(ErrDefs.crossMineNoOpen)
		if not ObjectCrossMineGameGlobal.isRoleOpen(role.level):
			raise ClientError(ErrDefs.crossMineRoleLevelLimit)

		# rob 抢夺
		# revenge 复仇
		flag = self.input.get('flag', None)
		myRank = self.input.get('myRank', None)
		enemyRank = self.input.get('enemyRank', None)
		enemyRoleID = self.input.get('enemyRoleID', None)
		enemyRecordID = self.input.get('enemyRecordID', None)
		patch = self.input.get('patch', 0)

		if not all([x is not None for x in [flag, myRank, enemyRank, enemyRoleID, enemyRecordID]]):
			raise ClientError('param miss')

		if flag == 'rob' and ObjectCrossMineGameGlobal.isRobTimesLimit(self.game):
			raise ClientError(ErrDefs.crossMineRobTimesLimit)
		if flag == 'revenge' and ObjectCrossMineGameGlobal.isRevengeTimesLimit(self.game):
			raise ClientError(ErrDefs.crossMineRevengeTimesLimit)

		if role.id == enemyRoleID or (flag == 'rob' and myRank == enemyRank):
			raise ClientError(ErrDefs.crossMineRobSelf)

		rpc = ObjectCrossMineGameGlobal.cross_client(role.areaKey)
		try:
			model = yield rpc.call_async('CrossMineBattleStart', flag, myRank, enemyRank, role.id, enemyRoleID, role.cross_mine_record_db_id, enemyRecordID, patch)
		except ClientError, e:
			if e.log_message in (ErrDefs.rankEnemyBattling, ErrDefs.rankEnemyChanged):
				model = yield makeCrossMineModel(self.game, rpc, True, self.rpcPVP)
				raise ClientError(e.log_message, model=model)
			raise ClientError(e.log_message)

		if flag == 'rob':
			self.game.dailyRecord.cross_mine_rob_times += 1
		elif flag == 'revenge':
			self.game.dailyRecord.cross_mine_revenge_times += 1

		self.write({
			'model': {
				'cross_mine_battle': model,
			}
		})


# 跨服资源战战斗结束
class CrossMineRobEnd(RequestHandlerTask):
	url = r'/game/cross/mine/battle/end'

	@coroutine
	def run(self):
		role = self.game.role
		if not ObjectCrossMineGameGlobal.isOpen(role.areaKey):
			raise ClientError(ErrDefs.crossMineNoOpen)
		result = self.input.get('result', None)
		stats = self.input.get('stats', None)  # {1: 'win', 2: "fail"}
		isTopBattle = self.input.get('isTopBattle', None)  # 是否精彩战报
		if not all([x is not None for x in [result, stats, isTopBattle]]):
			raise ClientError('param miss')

		if isinstance(stats, list):
			stats = {idx + 1: v for idx, v in enumerate(stats)}

		rpc = ObjectCrossMineGameGlobal.cross_client(role.areaKey)
		ret = yield rpc.call_async('CrossMineBattleEnd', role.id, role.cross_mine_record_db_id, result, stats, isTopBattle)

		view = ret.pop('view', {})
		view['result'] = result

		# 刷新货币
		ObjectCrossMineGameGlobal.SyncCoin13(self.game)
		game = ObjectGame.getByRoleID(ret.get('enemyRoleID', None), safe=False)
		if game:
			ObjectCrossMineGameGlobal.SyncCoin13(self.game)

		model = yield makeCrossMineModel(self.game, rpc, False, self.rpcPVP)
		self.write({
			'view': view,
			'model': model
		})


# 跨服资源战 Boss 战斗开始
class CrossMineBossBattleStart(RequestHandlerTask):
	url = r'/game/cross/mine/boss/battle/start'

	@coroutine
	def run(self):
		role = self.game.role
		if role.cross_mine_record_db_id is None:
			raise ClientError('cross mine not opened')
		if not ObjectCrossMineGameGlobal.isOpen(role.areaKey):
			raise ClientError(ErrDefs.crossMineNoOpen)
		if not ObjectCrossMineGameGlobal.isRoleOpen(role.level):
			raise ClientError(ErrDefs.crossMineRoleLevelLimit)

		bossID = self.input.get('bossID', None)

		if ObjectCrossMineGameGlobal.isBossTimesLimit(self.game, bossID):
			raise ClientError(ErrDefs.crossMineBossFreeTimesLimit)

		cards = self.game.role.huodong_cards.get(CrossMineBossHuodongID, self.game.role.battle_cards)
		if cards is None:
			raise ClientError('cards error')

		cardAttrs, cardAttrs2 = self.game.cards.makeBattleCardModel(cards, SceneDefs.CrossMineBoss)
		battleCardInfo = {
			'cards': cards,
			'card_attrs': cardAttrs,
			'card_attrs2': cardAttrs2,
			'passive_skills': self.game.cards.markBattlePassiveSkills(cards, SceneDefs.CrossMineBoss),
		}

		rpc = ObjectCrossMineGameGlobal.cross_client(role.areaKey)
		try:
			model = yield rpc.call_async('CrossMineBossStart', role.id, bossID, battleCardInfo)
		except ClientError, e:
			if e.log_message in (ErrDefs.crossMineBossHasKilled):
				model = yield makeCrossMineModel(self.game, rpc, False, self.rpcPVP)
				raise ClientError(e.log_message, model=model)
			else:
				raise ClientError(e.log_message)

		self.write({
			"model": {
				'cross_mine_boss_battle': model
			}
		})


# 跨服资源战 Boss 战斗结束
class CrossMinebossBattleEnd(RequestHandlerTask):
	url = r'/game/cross/mine/boss/battle/end'

	@coroutine
	def run(self):
		role = self.game.role
		if role.cross_mine_record_db_id is None:
			raise ClientError('cross mine not opened')
		if not ObjectCrossMineGameGlobal.isOpen(role.areaKey):
			raise ClientError(ErrDefs.crossMineNoOpen)
		if not ObjectCrossMineGameGlobal.isRoleOpen(role.level):
			raise ClientError(ErrDefs.crossMineRoleLevelLimit)

		battleID = self.input.get('battleID', None)
		damages = self.input.get('damages', None)
		actions = self.input.get('actions', None)
		if isinstance(actions, list):
			actions = {idx + 1: v for idx, v in enumerate(actions)}

		rpc = ObjectCrossMineGameGlobal.cross_client(role.areaKey)
		try:
			resp = yield rpc.call_async('CrossMineBossEnd', role.id, battleID, damages, actions)
		except ClientError, e:
			if e.log_message in (ErrDefs.crossMineBossHasKilled):
				model = yield makeCrossMineModel(self.game, rpc, False, self.rpcPVP)
				raise ClientError(e.log_message, model=model)
			else:
				raise ClientError(e.log_message)

		bossID = resp['bossID']
		self.game.dailyRecord.cross_mine_boss_times[bossID] = self.game.dailyRecord.cross_mine_boss_times.get(bossID, 0) + 1

		csvID = resp['csvID']
		bossCfg = csv.cross.mine.boss[csvID]

		eff = ObjectGainAux(self.game, bossCfg.battleAward)
		if resp['isKill']:
			eff += ObjectGainAux(self.game, bossCfg.killAward)

		yield effectAutoGain(eff, self.game, self.dbcGame, src='cross_mine_boss_end')

		model = yield makeCrossMineModel(self.game, rpc, False, self.rpcPVP)
		self.write({
			'view': {
				'award': eff.result,
				'score': resp['score']
			},
			'model': model
		})


# 跨服资源战购买次数
class CrossMineTimesBuy(RequestHandlerTask):
	url = r'/cross/mine/times/buy'

	@coroutine
	def run(self):
		role = self.game.role
		if not ObjectCrossMineGameGlobal.isOpen(role.areaKey):
			raise ClientError(ErrDefs.crossMineNoOpen)
		if not ObjectCrossMineGameGlobal.isRoleOpen(role.level):
			raise ClientError(ErrDefs.crossMineRoleLevelLimit)

		flag = self.input.get('flag', None)
		if flag is None:
			raise ClientError('param miss')

		if flag not in ['rob', 'revenge']:
			raise ClientError('flag error')

		dailyRecordKey = 'cross_mine_%s_buy_times' % flag
		dailyRecordTimes = getattr(self.game.dailyRecord, dailyRecordKey)
		if dailyRecordTimes >= getattr(role, 'crossMine%sBuyLimit' % flag.capitalize()):
			raise ClientError(getattr(ErrDefs, 'crossMine%sBuyLimit' % flag.capitalize()))

		costRMB = getattr(ObjectCostCSV, 'getCrossMine%sBuyCost' % flag.capitalize())(dailyRecordTimes)
		cost = ObjectCostAux(self.game, {'rmb': costRMB})
		if not cost.isEnough():
			raise ClientError(ErrDefs.buyRMBNotEnough)
		cost.cost(src='cross_mine_%s_buy' % flag)

		setattr(self.game.dailyRecord, dailyRecordKey, dailyRecordTimes + 1)


# 跨服资源战购买 Boss 挑战次数
class CrossMineBossTimesBuy(RequestHandlerTask):
	url = r'/cross/mine/boss/times/buy'

	@coroutine
	def run(self):
		role = self.game.role
		if not ObjectCrossMineGameGlobal.isOpen(role.areaKey):
			raise ClientError(ErrDefs.crossMineNoOpen)
		if not ObjectCrossMineGameGlobal.isRoleOpen(role.level):
			raise ClientError(ErrDefs.crossMineRoleLevelLimit)

		bossID = self.input.get('bossID', None)
		if bossID is None:
			raise ClientError('param miss')

		if not ObjectCrossMineGameGlobal.canBuyBossTimes(self.game, bossID):
			raise ClientError('boss times limit')

		costRMB = ObjectCostCSV.getCrossMineBossBuyCost(self.game.dailyRecord.cross_mine_boss_buy_times.get(bossID, 0))
		cost = ObjectCostAux(self.game, {'rmb': costRMB})
		if not cost.isEnough():
			raise ClientError(ErrDefs.buyRMBNotEnough)
		cost.cost(src='cross_mine_boss_buy')

		self.game.dailyRecord.cross_mine_boss_buy_times[bossID] = self.game.dailyRecord.cross_mine_boss_buy_times.get(bossID, 0) + 1


# 跨服资源战 buff 喂养
class CrossMineBuffFeed(RequestHandlerTask):
	url = r'/cross/mine/buff/feed'

	@coroutine
	def run(self):
		role = self.game.role
		if not ObjectCrossMineGameGlobal.isOpen(role.areaKey):
			raise ClientError(ErrDefs.crossMineNoOpen)
		if not ObjectCrossMineGameGlobal.isRoleOpen(role.level):
			raise ClientError(ErrDefs.crossMineRoleLevelLimit)

		flag = self.input.get('flag', None)
		csvID = self.input.get('csvID', None)
		if flag is None or csvID is None:
			raise ClientError('param miss')
		if flag not in ['server', 'role']:
			raise ClientError('flag error')
		if csvID not in csv.cross.mine.buff_feed:
			raise ClientError('csvID error')

		cfg = csv.cross.mine.buff_feed[csvID]

		if role.vip_level < cfg.feedVip:
			raise ClientError('csvID vip enough')

		dailyFeed = self.game.dailyRecord.cross_mine_buff_feed
		if flag in dailyFeed and dailyFeed[flag].get(csvID, 0) >= cfg.dayFeedTimesLimit:
			raise ClientError(ErrDefs.crossMineBuffFeedLimit)

		cost = ObjectCostAux(self.game, {'coin13': cfg.costCoin13})
		yield effectAutoCost(cost, self.game, src='cross_mine_%s_buff_feed' % flag, errDef=ErrDefs.costNotEnough)

		rpc = ObjectCrossMineGameGlobal.cross_client(role.areaKey)
		yield rpc.call_async('CrossMineBuffFeed', flag, csvID, role.id, role.areaKey)

		if flag not in dailyFeed:
			dailyFeed[flag] = {csvID: 1}
		elif csvID not in dailyFeed[flag]:
			dailyFeed[flag][csvID] = 1
		else:
			dailyFeed[flag][csvID] += 1

		eff = ObjectGainAux(self.game, getattr(cfg, '%sFeedAward' % flag))
		if eff:
			yield effectAutoGain(eff, self.game, self.dbcGame, src='cross_mine_%s_buff_feed' % flag)

		model = yield makeCrossMineModel(self.game, rpc, False, self.rpcPVP)
		self.write({
			'view': eff.result if eff else {},
			'model': model
		})


# 跨服资源战排行榜
class CrossMineRank(RequestHandlerTask):
	url = r'/game/cross/mine/rank'

	@coroutine
	def run(self):
		role = self.game.role
		if role.cross_mine_record_db_id is None:
			raise ClientError('cross mine not opened')

		flag = self.input.get('flag', None)
		if flag is None or flag not in ['role', 'feed']:
			raise ClientError('param miss')

		offset = self.input.get('offset', 0)
		size = self.input.get('size', 50)

		# 结束后，直接在game拿
		ret = ObjectCrossMineGameGlobal.getRankList(role.areaKey, flag, offset, size, self.game.role.id)
		if ret is None:
			rpc = ObjectCrossMineGameGlobal.cross_client(role.areaKey)
			ret = yield rpc.call_async('CrossMineGetRanks', flag, offset, size, self.game.role.id)

		self.write({
			'view': {
				'rank': ret,
				'offset': offset,
				'size': size
			},
		})


# 跨服资源战 boss 排行榜
class CrossMineBossRank(RequestHandlerTask):
	url = r'/game/cross/mine/boss/rank'

	@coroutine
	def run(self):
		role = self.game.role
		if role.cross_mine_record_db_id is None:
			raise ClientError('cross mine not opened')
		if not ObjectCrossMineGameGlobal.isOpen(role.areaKey):
			raise ClientError(ErrDefs.crossMineNoOpen)
		if not ObjectCrossMineGameGlobal.isRoleOpen(role.level):
			raise ClientError(ErrDefs.crossMineRoleLevelLimit)

		bossID = self.input.get('bossID', None)
		if bossID is None:
			raise ClientError('param miss')
		offset = self.input.get('offset', 0)
		size = self.input.get('size', 50)

		# 结束后，直接在game拿
		rpc = ObjectCrossMineGameGlobal.cross_client(role.areaKey)
		ret = yield rpc.call_async('CrossMineGetBossRanks', self.game.role.id, bossID, offset, size)

		model = yield makeCrossMineModel(self.game, rpc, False, self.rpcPVP)
		self.write({
			'view': {
				'rank': ret,
				'offset': offset,
				'size': size
			},
			'model': model
		})


# 跨服资源战战斗回放
class CrossMinePlayRecordGet(RequestHandlerTask):
	url = r'/game/cross/mine/playrecord/get'

	@coroutine
	def run(self):
		crossKey = self.input.get('crossKey', None)
		recordID = self.input.get('recordID', None)  # playRecord.id
		if recordID is None or crossKey is None:
			raise ClientError('param miss')

		rpc = ObjectCrossMineGameGlobal.cross_client(self.game.role.areaKey, cross_key=crossKey)
		if rpc is None:
			raise ClientError('Cross Mine Play Not Existed')
		model = yield rpc.call_async('CrossMineGetPlayRecord', recordID)
		if not model:
			raise ClientError('Cross Mine Play Not Existed')
		self.write({
			'model': {
				'cross_mine_playrecords': {
					recordID: model,
				}
			}
		})


# 查看玩家详情
class CrossMineRoleInfo(RequestHandlerTask):
	url = r'/game/cross/mine/role/info'

	@coroutine
	def run(self):
		role = self.game.role
		if role.cross_mine_record_db_id is None:
			raise ClientError('cross mine not opened')

		flag = self.input.get('flag', "")
		recordID = self.input.get('recordID', None)
		gameKey = self.input.get('gameKey', None)
		rank = self.input.get('rank', None)

		if not all([x is not None for x in [recordID, gameKey, rank]]):
			raise ClientError('param miss')

		client = self.server.container.getserviceOrCreate(game2pvp(gameKey))
		view = yield client.call_async('GetCrossMineRecord', recordID)
		view["game_key"] = gameKey

		info = {}
		if ObjectCrossMineGameGlobal.isOpen(role.areaKey):
			rpc = ObjectCrossMineGameGlobal.cross_client(role.areaKey)
			info = yield rpc.call_async('CrossMineGetEnemyInfo', flag, self.game.role.id, view['role_db_id'])

		view['rank'] = info.get('rank', rank)
		view['speed'] = info.get('speed', 0)
		view['coin13_origin'] = info.get('coin13_origin', 0)
		view['coin13_diff'] = info.get('coin13_diff', 0)
		view['canRobNum'] = info.get('canRobNum', 0)
		view['role_be_roded'] = info['role_be_roded'] if info.get('role_be_roded', None) else {}
		view['role_be_revenged'] = info['role_be_revenged'] if info.get('role_be_revenged', None) else {}
		view['killBoss'] = info['killBoss'] if info.get('killBoss', None) else {}

		self.write({
			'view': view,
		})


# 跨服资源战商店
class CrossMineShop(RequestHandlerTask):
	url = r'/game/cross/mine/shop'

	@coroutine
	def run(self):
		if not ObjectCrossMineGameGlobal.isRoleOpen(self.game.role.level):
			raise ClientError('cross mine shop not opened')

		csvID = self.input.get('csvID', None)
		count = self.input.get('count', 1)
		if csvID is None:
			raise ClientError('param miss')
		if count <= 0:
			raise ClientError('param error')

		shop = ObjectCrossMineShop(self.game)
		eff = yield shop.buyItem(csvID, count, src='cross_mine_shop_buy')
		yield effectAutoGain(eff, self.game, self.dbcGame, src='cross_mine_shop_buy')
