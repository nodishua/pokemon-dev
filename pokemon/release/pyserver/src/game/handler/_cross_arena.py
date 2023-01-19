#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2014 YouMi Information Technology Inc.

PVP Handlers
'''
from framework.csv import ErrDefs, csv, ConstDefs
from framework.helper import transform2list
from framework.log import logger
from framework.service.helper import game2pvp
from game import ClientError
from game.globaldata import PVPSkinIDStart
from game.handler import RequestHandlerTask
from game.handler.inl import effectAutoGain
from game.object import SceneDefs, FeatureDefs, CrossArenaDefs, MessageDefs
from game.object.game import ObjectCostCSV, ObjectMessageGlobal
from game.object.game.cross_arena import ObjectCrossArenaGameGlobal
from game.object.game.levelcsv import ObjectFeatureUnlockCSV
from game.object.game.gain import ObjectCostAux, ObjectGainAux
from game.object.game.shop import ObjectCrossArenaShop
from game.thinkingdata import ta
from msgpackrpc.error import CallError
from tornado.gen import coroutine, Return


@coroutine
def makeBattleModel(game, rpc, refresh, rpcPVP):
	role = game.role
	if not role.cross_arena_record_db_id:
		raise Return({'cross_arena': {}, })

	# {enemys; role; record}
	model = {}
	record = yield rpcPVP.call_async('GetCrossArenaRecord', role.cross_arena_record_db_id)
	model['record'] = record
	if ObjectCrossArenaGameGlobal.isOpen(role.areaKey):
		# 防守阵容有为空特殊情况处理
		defenceCards = model['record']['defence_cards']
		if len(filter(None, defenceCards[1])) == 0 or len(filter(None, defenceCards[2])) == 0:
			cardsMap, _ = ObjectCrossArenaGameGlobal.getCrossArenaCards(role)
			dfCards = cardsMap[1]
			dfCards.extend(cardsMap[2])
			yield refreshCardsToCrossArena(rpcPVP, game, defence_cards=dfCards)
			record = yield rpcPVP.call_async('GetCrossArenaRecord', game.role.cross_arena_record_db_id)
			model['record'] = record

		defenceCardAttrs = model['record']['defence_card_attrs']
		crossArenaRoleInfo = ObjectCrossArenaGameGlobal.markCrossArenaRoleInfo(game.role, defenceCardAttrs)
		enemys, roleData, flag = yield rpc.call_async('GetCrossArenaModel', role.id, crossArenaRoleInfo, refresh)
		model['enemys'] = enemys
		model['role'] = roleData
		if flag:
			# 重置上赛季数据
			ObjectCrossArenaGameGlobal.resetCrossAreanDatas(role)
			# 清除上赛季历史战报
			yield rpcPVP.call_async('CleanCrossArenaHistory', role.cross_arena_record_db_id)
			model['record']['history'] = []
			# 初始化 段位奖励
			role.setCrossAreanStageAwards(roleData["rank"])
		model['topBattleHistory'] = yield rpc.call_async('GetCrossArenaTopBattleHistory')
	else:
		model['topBattleHistory'] = ObjectCrossArenaGameGlobal.getTopBattleHistory(role.areaKey)

	model.update(ObjectCrossArenaGameGlobal.getCrossGameModel(role.areaKey))
	raise Return({
		'cross_arena': model,
	})

@coroutine
def refreshCardsToCrossArena(rpc, game, cards=None, defence_cards=None, force=False):
	if not game.role.cross_arena_record_db_id:
		raise Return(None)
	deployment = game.cards.deploymentForCrossArena
	# 卡牌没发生改变
	if not any([force, cards, defence_cards, deployment.isdirty()]):
		raise Return(None)

	embattle = {}

	# 进攻阵容
	if cards:
		cardsMap = {}  # {1:[card.id], 2:[card.id]}
		cardsMap[1] = transform2list(cards[:6])
		cardsMap[2] = transform2list(cards[6:12])
		embattle['cards'] = cardsMap
	cards, dirty = deployment.refresh('cards', SceneDefs.CrossArena, cards)
	cardAttrs, cardAttrs12 = game.cards.makeBattleCardModel(cards[:6], SceneDefs.CrossArena, dirty=dirty[:6] if dirty else None)
	cardAttrs2, cardAttrs22 = game.cards.makeBattleCardModel(cards[6:12], SceneDefs.CrossArena, dirty=dirty[6:12] if dirty else None)
	cardAttrs.update(cardAttrs2)
	cardAttrs12.update(cardAttrs22)
	embattle['card_attrs'] = cardAttrs
	embattle['card_attrs2'] = cardAttrs12
	embattle['passive_skills'] = game.cards.markBattlePassiveSkills(cards, SceneDefs.CrossArena)

	# 防守阵容
	if defence_cards:
		defenceCardsMap = {}
		defenceCardsMap[1] = transform2list(defence_cards[:6])
		defenceCardsMap[2] = transform2list(defence_cards[6:12])
		embattle['defence_cards'] = defenceCardsMap
	defence_cards, defence_dirty = deployment.refresh('defence_cards', SceneDefs.CrossArena, defence_cards)
	defenceCardAttrs, defenceCardAttrs12 = game.cards.makeBattleCardModel(defence_cards[:6], SceneDefs.CrossArena, dirty=defence_dirty[:6] if defence_dirty else None)
	defenceCardAttrs2, defenceCardAttrs22 = game.cards.makeBattleCardModel(defence_cards[6:12], SceneDefs.CrossArena, dirty=defence_dirty[6:12] if defence_dirty else None)
	defenceCardAttrs.update(defenceCardAttrs2)
	defenceCardAttrs12.update(defenceCardAttrs22)
	embattle['defence_card_attrs'] = defenceCardAttrs
	embattle['defence_card_attrs2'] = defenceCardAttrs12
	embattle['defence_passive_skills'] = game.cards.markBattlePassiveSkills(defence_cards, SceneDefs.CrossArena)

	deployment.resetdirty()
	yield rpc.call_async('CrossArenaDeployCards', game.role.cross_arena_record_db_id, game.role.competitor, embattle)


# 进入主界面 先请求该接口 （同步model客户端)
class CrossArenaBattleMain(RequestHandlerTask):
	url = r'/game/cross/arena/battle/main'

	@coroutine
	def run(self):
		if not ObjectCrossArenaGameGlobal.isRoleOpen(self.game.role.level):
			raise ClientError(ErrDefs.levelLessNoOpened)

		needRefresh = self.input.get('needRefresh', 0)

		role = self.game.role
		# 新建CrossArenaRecord
		if role.cross_arena_record_db_id is None:
			cardsMap, cards = ObjectCrossArenaGameGlobal.getCrossArenaCards(role)
			passiveSkills = self.game.cards.markBattlePassiveSkills(cards, SceneDefs.CrossArena)

			cardAttrs, cardAttrs12 = self.game.cards.makeBattleCardModel(cardsMap[1], SceneDefs.CrossArena)
			cardAttrs2, cardAttrs22 = self.game.cards.makeBattleCardModel(cardsMap[2], SceneDefs.CrossArena)
			cardAttrs.update(cardAttrs2)
			cardAttrs12.update(cardAttrs22)

			embattle = {
				'cards': cardsMap,
				'card_attrs': cardAttrs,
				'card_attrs2': cardAttrs12,
				'passive_skills': passiveSkills,
				'defence_cards': cardsMap,
				'defence_card_attrs': cardAttrs,
				'defence_card_attrs2': cardAttrs22,
				'defence_passive_skills': passiveSkills,
			}
			role.cross_arena_record_db_id = yield self.rpcPVP.call_async('CreateCrossArenaRecord', role.competitor, embattle, False)

			deployment = self.game.cards.deploymentForCrossArena
			deployment.deploy('cards', transform2list(cards, 12))
			deployment.deploy('defence_cards', transform2list(cards, 12))

		# 保存玩家最新卡牌数据
		else:
			if needRefresh == 1:
				costGold = ObjectCostCSV.getCrossArenaFreshCost(self.game.dailyRecord.cross_arena_refresh_times)
				cost = ObjectCostAux(self.game, {'gold': costGold})
				if not cost.isEnough():
					raise ClientError(ErrDefs.costNotEnough)
				cost.cost(src='cross_arena_battle_refresh')
				self.game.dailyRecord.cross_arena_refresh_times += 1
			yield refreshCardsToCrossArena(self.rpcPVP, self.game)

		rpc = ObjectCrossArenaGameGlobal.cross_client(role.areaKey)
		model = yield makeBattleModel(self.game, rpc, True if needRefresh == 1 else False, self.rpcPVP)
		self.write({'model': model})


# 队伍布阵（两个队伍）包含防守
class CrossArenaBattleDeploy(RequestHandlerTask):
	url = r'/game/cross/arena/battle/deploy'

	@coroutine
	def run(self):
		role = self.game.role
		if role.cross_arena_record_db_id is None:
			raise ClientError('cross arena not opened')

		cards = self.input.get('cards', None)
		defenceCards = self.input.get('defenceCards', None)

		if cards:
			cards = transform2list(cards, 12)
			if self.game.cards.isDuplicateMarkID(cards):
				raise ClientError('cards have duplicates')
			cards1 = cards[:6]
			cards2 = cards[6:12]
			if len(filter(None, cards1)) == 0 or len(filter(None, cards2)) == 0:
				raise ClientError('have one cards all None')

		if defenceCards:
			defenceCards = transform2list(defenceCards, 12)
			if self.game.cards.isDuplicateMarkID(defenceCards):
				raise ClientError('cards have duplicates')
			defenceCards1 = defenceCards[:6]
			defenceCards2 = defenceCards[6:12]
			if len(filter(None, defenceCards1)) == 0 or len(filter(None, defenceCards2)) == 0:
				raise ClientError('have one defenceCards all None')

		yield refreshCardsToCrossArena(self.rpcPVP, self.game, cards=cards, defence_cards=defenceCards)
		rpc = ObjectCrossArenaGameGlobal.cross_client(role.areaKey)
		model = yield makeBattleModel(self.game, rpc, False, self.rpcPVP)
		self.write({'model': model})


# 开始战斗
class CrossArenaBattleStart(RequestHandlerTask):
	url = r'/game/cross/arena/battle/start'

	@coroutine
	def run(self):
		role = self.game.role
		if role.cross_arena_record_db_id is None:
			raise ClientError('cross arena not opened')
		# 只有赛季中才可战斗
		if not ObjectCrossArenaGameGlobal.isOpen(role.areaKey):
			raise ClientError(ErrDefs.crossArenaNotOpen)

		myRank = self.input.get('myRank', None)
		battleRank = self.input.get('battleRank', None)
		enemyRoleID = self.input.get('enemyRoleID', None)
		enemyRecordID = self.input.get('enemyRecordID', None)
		patch = self.input.get('patch', 0)

		if not all([x is not None for x in [myRank, battleRank, enemyRoleID, enemyRecordID]]):
			raise ClientError('param miss')
		if enemyRoleID == role.id:
			raise ClientError(ErrDefs.pvpSelfErr)

		dailyRecord = self.game.dailyRecord
		if dailyRecord.cross_arena_pw_times >= role.crossArenaFreePWTimes + dailyRecord.cross_arena_buy_times:
			raise ClientError("pw times no enough")

		rpc = ObjectCrossArenaGameGlobal.cross_client(role.areaKey)
		try:
			model = yield rpc.call_async('CrossArenaBattleStart', myRank, battleRank, role.id, enemyRoleID, role.cross_arena_record_db_id, enemyRecordID, patch)
		except CallError, e:
			# 刷新挑战对手列表
			if e.msg in (ErrDefs.rankEnemyBattling, ErrDefs.rankEnemyChanged):
				modelBattle = yield makeBattleModel(self.game, rpc, True, self.rpcPVP)
				raise ClientError(e.msg, model=modelBattle)
			raise ClientError(e.msg)

		dailyRecord.cross_arena_pw_times += 1

		# 每日次数奖励
		for csvID in sorted(csv.cross.arena.daily_award):
			cfg = csv.cross.arena.daily_award[csvID]
			if dailyRecord.cross_arena_pw_times >= cfg.pwTime and csvID not in dailyRecord.cross_arena_point_award:
					dailyRecord.cross_arena_point_award[csvID] = CrossArenaDefs.DailyAwardOpenFlag

		self.write({
			'model': {
				'cross_arena_battle': model,
			}
		})


# 结束战斗
class CrossArenaBattleEnd(RequestHandlerTask):
	url = r'/game/cross/arena/battle/end'

	@coroutine
	def run(self):
		if not ObjectCrossArenaGameGlobal.isOpen(self.game.role.areaKey):
			raise ClientError(ErrDefs.crossArenaNotOpen)
		rank = self.input.get('rank', None)  # 用作检验
		result = self.input.get('result', None)
		isTopBattle = self.input.get('isTopBattle', None)  # 是否精彩战报
		if not all([x is not None for x in [rank, result, isTopBattle]]):
			raise ClientError('param miss')

		role = self.game.role
		try:
			rpc = ObjectCrossArenaGameGlobal.cross_client(role.areaKey)
			ret = yield rpc.call_async('CrossArenaBattleEnd', rank, role.id, role.cross_arena_record_db_id, result, isTopBattle)
		except CallError, e:
			# 可能作弊了
			raise ClientError(e.msg)
		except:
			raise

		ret['result'] = result
		if result == 'win':
			# 段位奖励
			newRank = ret["rank"]
			role.setCrossAreanStageAwards(newRank)
			# 跑马灯
			if newRank == 1:
				ObjectMessageGlobal.marqueeBroadcast(role, MessageDefs.MqCrossArenaTopRank)
				ObjectMessageGlobal.newsCrossArenaTopRankMsg(role)

		rpc = ObjectCrossArenaGameGlobal.cross_client(role.areaKey)
		modelBattle = yield makeBattleModel(self.game, rpc, False, self.rpcPVP)

		result = {
			'view': ret,
			'model': modelBattle,
		}
		self.write(result)

		ta.track(self.game, event='end_cross_arena',result=result)


# 跨服竞技场 5次碾压
class CrossArenaBattlePass(RequestHandlerTask):
	url = r'/game/cross/arena/battle/pass'

	@coroutine
	def run(self):
		if not ObjectFeatureUnlockCSV.isOpen(FeatureDefs.CrossArenaPass, self.game):
			raise ClientError('cross_arena_pass not open')
		if not ObjectCrossArenaGameGlobal.isOpen(self.game.role.areaKey):
			raise ClientError(ErrDefs.crossArenaNotOpen)
		role = self.game.role
		battleRank = self.input.get('battleRank', None)
		if not battleRank:
			raise ClientError('param miss')

		dailyRecord = self.game.dailyRecord
		# 剩余可用挑战次数
		canPwTimes = role.crossArenaFreePWTimes + dailyRecord.cross_arena_buy_times - dailyRecord.cross_arena_pw_times

		if canPwTimes >= 5:
			needBuyTimes = 0
		else:
			needBuyTimes = 5 - canPwTimes

		# 消耗RMB = 购买次数的消耗RMB + 固定消耗
		costRMB = 0
		for i in xrange(0, needBuyTimes):
			costRMB += ObjectCostCSV.getCrossArenaPWBuyCost(self.game.dailyRecord.cross_arena_buy_times + i)
		costRMB += ConstDefs.crossArenaPassCostRmb
		cost = ObjectCostAux(self.game, {'rmb': costRMB})
		if not cost.isEnough():
			raise ClientError('cost rmb not enough')
		cost.cost(src='cross_arena_pass5')

		# 挑战次数+5
		dailyRecord.cross_arena_pw_times += 5
		# 购买次数加上
		dailyRecord.cross_arena_buy_times += needBuyTimes

		# 每日次数奖励
		for csvID in sorted(csv.cross.arena.daily_award):
			cfg = csv.cross.arena.daily_award[csvID]
			if dailyRecord.cross_arena_pw_times >= cfg.pwTime and csvID not in dailyRecord.cross_arena_point_award:
				dailyRecord.cross_arena_point_award[csvID] = CrossArenaDefs.DailyAwardOpenFlag


# 对战情报录像回放
class CrossArenaPlayRecordGet(RequestHandlerTask):
	url = r'/game/cross/arena/playrecord/get'

	@coroutine
	def run(self):
		crossKey = self.input.get('crossKey', None)
		recordID = self.input.get('recordID', None)  # playRecord.id
		if recordID is None or crossKey is None:
			raise ClientError('param miss')

		rpc = ObjectCrossArenaGameGlobal.cross_client(self.game.role.areaKey, cross_key=crossKey)
		if rpc is None:
			raise ClientError('Cross Arena Play Not Existed')
		model = yield rpc.call_async('GetCrossArenaPlayRecord', recordID)
		if not model:
			raise ClientError('Cross Arena Play Not Existed')
		self.write({
			'model': {
				'cross_arena_playrecords': {
					recordID: model,
				}
			}
		})


# 领取每日次数奖励
class CrossArenaDailyAward(RequestHandlerTask):
	url = r'/game/cross/arena/daily/award'

	@coroutine
	def run(self):
		role = self.game.role
		if role.cross_arena_record_db_id is None:
			raise ClientError('cross arena not opened')

		csvID = self.input.get('csvID', None)

		eff = ObjectGainAux(self.game, {})
		if not csvID:  # 一键领取
			for awardID, flag in self.game.dailyRecord.cross_arena_point_award.iteritems():
				if flag == CrossArenaDefs.DailyAwardOpenFlag:
					cfg = csv.cross.arena.daily_award[awardID]
					eff += ObjectGainAux(self.game, cfg.award)
					self.game.dailyRecord.cross_arena_point_award[awardID] = CrossArenaDefs.DailyAwardCloseFlag
		else:
			if csvID not in csv.cross.arena.daily_award:
				raise ClientError('csvID error')
			flag = self.game.dailyRecord.cross_arena_point_award.get(csvID, -1)
			if flag == CrossArenaDefs.DailyAwardCloseFlag:
				raise ClientError('daily award get again')
			elif flag == CrossArenaDefs.DailyAwardNoneFlag:
				raise ClientError('daily award not finish')

			cfg = csv.cross.arena.daily_award[csvID]
			eff += ObjectGainAux(self.game, cfg.award)
			self.game.dailyRecord.cross_arena_point_award[csvID] = CrossArenaDefs.DailyAwardCloseFlag

		ret = {}
		if eff:
			yield effectAutoGain(eff, self.game, self.dbcGame, src='cross_arena_daily_award')
			ret = eff.result

		self.write({
			'view': ret,
		})


# 领取段位奖励
class CrossArenaStageAward(RequestHandlerTask):
	url = r'/game/cross/arena/stage/award'

	@coroutine
	def run(self):
		role = self.game.role
		if role.cross_arena_record_db_id is None:
			raise ClientError('cross arena not opened')

		csvID = self.input.get('csvID', None)  # csvID

		stageAwards = role.cross_arena_datas.setdefault("stage_awards", {})
		eff = ObjectGainAux(self.game, {})
		if not csvID:  # 一键领取
			for awardID, flag in stageAwards.iteritems():
				if flag == CrossArenaDefs.StageAwardOpenFlag:
					cfg = csv.cross.arena.stage[awardID]
					eff += ObjectGainAux(self.game, cfg.award)
					stageAwards[awardID] = CrossArenaDefs.StageAwardCloseFlag
		else:
			if csvID not in csv.cross.arena.stage:
				raise ClientError('csvID error')
			flag = stageAwards.get(csvID, -1)
			if flag == CrossArenaDefs.StageAwardCloseFlag:
				raise ClientError('stage award get again')
			elif flag == CrossArenaDefs.StageAwardNoneFlag:
				raise ClientError('stage award not finish')

			cfg = csv.cross.arena.stage[csvID]
			eff += ObjectGainAux(self.game, cfg.award)
			stageAwards[csvID] = CrossArenaDefs.StageAwardCloseFlag

		ret = {}
		if eff:
			yield effectAutoGain(eff, self.game, self.dbcGame, src='cross_arena_stage_award')
			ret = eff.result

		self.write({
			'view': ret,
		})


# 获取排行榜
class CrossArenaRank(RequestHandlerTask):
	url = r'/game/cross/arena/rank'

	@coroutine
	def run(self):
		role = self.game.role
		if role.cross_arena_record_db_id is None:
			raise ClientError('cross arena not opened')
		offest = self.input.get('offest', 0)
		size = self.input.get('size', 50)

		# 结束后，直接在game拿
		ret = ObjectCrossArenaGameGlobal.getRankList(role.areaKey, offest, size, self.game.role.id)
		if ret is None:
			rpc = ObjectCrossArenaGameGlobal.cross_client(role.areaKey)
			ret = yield rpc.call_async('GetCrossArenaTopRanks', offest, size, self.game.role.id)
		self.write({
			'view': {
				'rank': ret,
				'offest': offest,
				'size': size,
			},
		})


# 购买挑战次数
class CrossArenaBattleBuy(RequestHandlerTask):
	url = r'/game/cross/arena/battle/buy'

	@coroutine
	def run(self):
		if not ObjectCrossArenaGameGlobal.isOpen(self.game.role.areaKey):
			raise ClientError(ErrDefs.crossArenaNotOpen)
		role = self.game.role
		if role.cross_arena_record_db_id is None:
			raise ClientError('cross arena not opened')

		if self.game.dailyRecord.cross_arena_buy_times >= self.game.role.crossArenaBuyPWMaxTimes:
			raise ClientError(ErrDefs.pwBuyMax)

		costRMB = ObjectCostCSV.getCrossArenaPWBuyCost(self.game.dailyRecord.cross_arena_buy_times)

		cost = ObjectCostAux(self.game, {'rmb': costRMB})
		if not cost.isEnough():
			raise ClientError(ErrDefs.buyRMBNotEnough)
		cost.cost(src='cross_arena_pw_buy')

		self.game.dailyRecord.cross_arena_buy_times += 1


# 查看玩家详情
class CrossArenaRoleInfo(RequestHandlerTask):
	url = r'/game/cross/arena/role/info'

	@coroutine
	def run(self):
		role = self.game.role
		if role.cross_arena_record_db_id is None:
			raise ClientError('cross arena not opened')

		recordID = self.input.get('recordID', None)
		gameKey = self.input.get('gameKey', None)
		rank = self.input.get('rank', None)
		if not all([x is not None for x in [recordID, gameKey, rank]]):
			raise ClientError('param miss')

		client = self.server.container.getserviceOrCreate(game2pvp(gameKey))
		view = yield client.call_async('GetCrossArenaRecord', recordID)
		view["game_key"] = gameKey
		view["rank"] = rank
		self.write({
			'view': view,
		})


# 更换展示卡牌
class CrossArenaDisplay(RequestHandlerTask):
	url = r'/game/cross/arena/display'

	@coroutine
	def run(self):
		if not ObjectCrossArenaGameGlobal.isOpen(self.game.role.areaKey):
			raise ClientError(ErrDefs.crossArenaNotOpen)
		role = self.game.role
		if role.cross_arena_record_db_id == 0:
			raise ClientError('cross arena not opened')
		cardID = self.input.get('cardID', None)  # csv_id
		if cardID is None:
			raise ClientError('cardID miss')
		if cardID not in role.pokedex and (cardID % PVPSkinIDStart) not in role.skins:
			raise ClientError('cardID error')

		self.game.role.cross_arena_datas['last_display'] = cardID
		rpc = ObjectCrossArenaGameGlobal.cross_client(role.areaKey)
		yield rpc.call_async('UpdateCrossArenaDisplay', role.id, cardID)

		self.write({
			'sync': {
				'upd': {
					'cross_arena': {
						'role': {'display': cardID},
					}
				}
			}
		})


# 商店兑换
class CrossArenaShopBuy(RequestHandlerTask):
	url = r'/game/cross/arena/shop/buy'

	@coroutine
	def run(self):
		if not ObjectCrossArenaGameGlobal.isRoleOpen(self.game.role.level):
			raise ClientError('cross arena shop not opened')

		csvID = self.input.get('csvID', None)
		count = self.input.get('count', 1)
		if csvID is None:
			raise ClientError('param miss')
		if count <= 0:
			raise ClientError('param error')

		crossArenaShop = ObjectCrossArenaShop(self.game)
		eff = crossArenaShop.buyItem(csvID, count, src='cross_arena_shop_buy')
		yield effectAutoGain(eff, self.game, self.dbcGame, src='cross_arena_shop_buy')

