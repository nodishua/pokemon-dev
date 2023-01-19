#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2014 YouMi Information Technology Inc.

PVP Handlers
'''

from framework import period2date, date2int, nowtime_t, nowtime2period
from framework.csv import ErrDefs, csv, ConstDefs
from framework.helper import transform2list

from game import ServerError, ClientError
from game.object import TargetDefs, SceneDefs, FeatureDefs, AchievementDefs, MessageDefs
from game.globaldata import ShopRefreshTime, ShopRefreshPeriods, PVPBattleItemID, PVPSkinIDStart
from game.handler.task import RequestHandlerTask
from game.handler.inl import effectAutoGain
from game.object.game import ObjectGame, ObjectUnionContribTask
from game.object.game.rank import ObjectPWAwardEffect, ObjectArenaFlopAwardRandom
from game.object.game.shop import ObjectPVPShop
from game.object.game.costcsv import ObjectCostCSV
from game.object.game.levelcsv import ObjectFeatureUnlockCSV
from game.object.game.yyhuodong import ObjectYYHuoDongFactory
from game.object.game.society import ObjectSocietyGlobal
from game.object.game.message import ObjectMessageGlobal
from game.object.game.gain import ObjectCostAux, ObjectGainEffect, ObjectGainAux
from game.object.game.union import ObjectUnion
from game.thinkingdata import ta

from tornado.gen import coroutine, Return
from nsqrpc.error import CallError

@coroutine
def makeBattleModel(game, rpc, dbc, refresh):
	model = yield rpc.call_async('GetAreaModel', game.role.id, game.role.pvp_record_db_id, refresh)
	# game_server rank缓存
	game.role.pw_rank = model['record']['rank']
	raise Return({
		'arena': model,
	})

@coroutine
def refreshCardsToPVP(rpc, game, cards=None, defence_cards=None, force=False):
	if not game.role.pvp_record_db_id:
		raise Return(None)
	deployment = game.cards.deploymentForArena
	# 卡牌没发生改变
	if not any([force, cards, defence_cards, deployment.isdirty(), game.role.displayDirty]):
		raise Return(None)
	game.role.displayDirty = True

	embattle = {}

	# 进攻阵容
	if cards:
		embattle['cards'] = cards
	cards, dirty = deployment.refresh('cards', SceneDefs.Arena, cards)
	embattle['card_attrs'], embattle['card_attrs2'] = game.cards.makeBattleCardModel(cards, SceneDefs.Arena, dirty=dirty)
	embattle['passive_skills'] = game.cards.markBattlePassiveSkills(cards, SceneDefs.Arena)

	# 防守阵容
	if defence_cards:
		embattle['defence_cards'] = defence_cards
	defence_cards, defence_dirty = deployment.refresh('defence_cards', SceneDefs.Arena, defence_cards)
	embattle['defence_card_attrs'], embattle['defence_card_attrs2'] = game.cards.makeBattleCardModel(defence_cards, SceneDefs.Arena, dirty=defence_dirty)
	embattle['defence_passive_skills'] = game.cards.markBattlePassiveSkills(defence_cards, SceneDefs.Arena)

	deployment.resetdirty()
	yield rpc.call_async('Deploy', game.role.pvp_record_db_id, game.role.competitor, embattle)

# 排位赛获取战斗信息
class PWBattleGet(RequestHandlerTask):
	url = r'/game/pw/battle/get'

	@coroutine
	def run(self):
		# 判断是否具备开启条件
		if not ObjectFeatureUnlockCSV.isOpen(FeatureDefs.PVP, self.game):
			raise ClientError(ErrDefs.levelLessNoOpened)

		# 新建PVPRecord
		if self.game.role.pvp_record_db_id is None:
			cards = self.game.role.battle_cards
			cardsD, cardsD2 = self.game.cards.makeBattleCardModel(cards, SceneDefs.Arena)
			passiveSkills = self.game.cards.markBattlePassiveSkills(cards, SceneDefs.Arena)

			dbID = max(cardsD, key=lambda x: cardsD[x]['fighting_point'])
			display = cardsD[dbID]['skin_id']
			if not display:
				display = cardsD[dbID]['card_id']

			fightingPoint = 0
			for _, model in cardsD.iteritems():
				fightingPoint += model['fighting_point']

			embattle = {
				'cards': cards,
				'defence_cards': cards,
				'passive_skills': passiveSkills,
				'card_attrs': cardsD,
				'card_attrs2': cardsD2,
				'defence_card_attrs': cardsD,
				'defence_card_attrs2': cardsD2,
				'defence_passive_skills': passiveSkills,
			}

			role = self.game.role
			role.pvp_record_db_id = yield self.rpcArena.call_async('CreateArenaRecord', role.competitor, embattle, fightingPoint, display, False)

			deployment = self.game.cards.deploymentForArena
			deployment.deploy('cards', self.game.role.battle_cards)
			deployment.deploy('defence_cards', self.game.role.battle_cards)
			role.deployments_sync['arena_defence_cards'] = True # 默认同步
		else:
			yield refreshCardsToPVP(self.rpcArena, self.game)

		needRefresh = self.input.get('needRefresh', 0)
		if needRefresh == 1:
			costRMB = ObjectCostCSV.getPvpEnermysFreshCost(self.game.dailyRecord.pvp_enermys_refresh_times)

			cost = ObjectCostAux(self.game, {'rmb': costRMB})
			if not cost.isEnough():
				raise ClientError(ErrDefs.buyRMBNotEnough)
			cost.cost(src='pw_battle_refresh')

			self.game.dailyRecord.pvp_enermys_refresh_times += 1

		model = yield makeBattleModel(self.game, self.rpcArena, self.dbcGame, True if needRefresh == 1 else False)
		self.write({'model': model})

# 排位赛布阵
class PWBattleDeploy(RequestHandlerTask):
	url = r'/game/pw/battle/deploy'

	@coroutine
	def run(self):
		role = self.game.role
		if role.pvp_record_db_id is None:
			raise ClientError('pvp not opened')

		cards = self.input.get('cards', None)
		defenceCards = self.input.get('defenceCards', None)

		if cards:
			cards = transform2list(cards)
			if self.game.cards.isDuplicateMarkID(cards):
				raise ClientError('cards have duplicates')
		if defenceCards:
			defenceCards = transform2list(defenceCards)
			if self.game.cards.isDuplicateMarkID(defenceCards):
				raise ClientError('cards have duplicates')
			self.game.role.deployments_sync['arena_defence_cards'] = False

		yield refreshCardsToPVP(self.rpcArena, self.game, cards=cards, defence_cards=defenceCards)
		model = yield makeBattleModel(self.game, self.rpcArena, self.dbcGame, False)
		self.write({'model': model})

# 排位赛开始战斗
class PWBattleStart(RequestHandlerTask):
	url = r'/game/pw/battle/start'

	@coroutine
	def run(self):
		role = self.game.role
		if role.pvp_record_db_id is None:
			raise ClientError('pvp not opened')
		dailyRecord = self.game.dailyRecord

		myRank = self.input.get('myRank', None)
		battleRank = self.input.get('battleRank', None)
		if battleRank <= 10 and myRank > 20:
			raise ClientError(ErrDefs.pvpRank10Limit)

		enemyRoleID = self.input.get('enemyRoleID', None)
		enemyRecordID = self.input.get('enemyRecordID', None)

		if not all([x is not None for x in [myRank, battleRank, enemyRoleID, enemyRecordID]]):
			raise ClientError('param miss')
		if enemyRoleID == role.id:
			raise ClientError(ErrDefs.pvpSelfErr)

		# 每日排位赛挑战最大次数 = vip.freePWTimes + DailyRecord.buy_pw_times + DailyRecord.item_pw_times
		if dailyRecord.pvp_pw_times >= role.freePWTimes + dailyRecord.buy_pw_times + dailyRecord.item_pw_times:
			cost = ObjectCostAux(self.game, {PVPBattleItemID: 1})
			if not cost.isEnough():
				raise ClientError(ErrDefs.todayChanllengeToMuch)
			cost.cost(src='pw_battle_itemUse')
			dailyRecord.item_pw_times += 1
			self.game.dailyRecord.pvp_pw_last_time = 0
		else:
			# 排位赛CD时间
			if not self.game.privilege.pwNoCD:
				delta = nowtime_t() - dailyRecord.pvp_pw_last_time
				if delta < role.PWcoldTime:
					raise ClientError(ErrDefs.rankTimerNoCD)

		try:
			model = yield self.rpcArena.call_async('BattleStart', myRank, battleRank, role.id, role.pvp_record_db_id, enemyRoleID, enemyRecordID)
		except CallError, e:
			# 刷新列表
			if e.msg in (ErrDefs.rankEnemyBattling, ErrDefs.rankEnemyChanged):
				modelBattle = yield makeBattleModel(self.game, self.rpcArena, self.dbcGame, True)
				raise ClientError(e.msg, model=modelBattle)
			raise ClientError(e.msg)

		# 消耗挑战次数
		dailyRecord.pvp_pw_times += 1
		# 先加1分保底，VIP是2分
		if role.PWpointActive == 1 or role.level >= 45:
			dailyRecord.pvp_result_point += 2
		else:
			dailyRecord.pvp_result_point += 1
		# 记录挑战时间
		dailyRecord.pvp_pw_last_time = nowtime_t()
		ObjectYYHuoDongFactory.onGeneralTask(self.game, TargetDefs.ArenaBattle, 1)
		self.game.achievement.onCount(AchievementDefs.ArenaBattle, 1)

		self.write({
			'model': {
				'arena_battle': model,
			}
		})

# 排位赛结束战斗
class PWBattleEnd(RequestHandlerTask):
	url = r'/game/pw/battle/end'

	@coroutine
	def run(self):
		rank = self.input.get('rank', None)
		result = self.input.get('result', None)
		if not all([x is not None for x in [rank, result]]):
			raise ClientError('param miss')

		myRole = self.game.role
		try:
			ret = yield self.rpcArena.call_async('BattleEnd', rank, myRole.id, myRole.pvp_record_db_id, result)
		except CallError, e:
			# 可能作弊了
			raise ClientError(e.msg)
		except:
			raise

		rank = ret['rank']
		# game_server rank缓存
		self.game.role.pw_rank = rank
		if ret['rank_move'] != 0 and rank == 1:
			ObjectMessageGlobal.newsPVPTopRankMsg(self.game.role)
			ObjectMessageGlobal.marqueeBroadcast(self.game.role, MessageDefs.MqPvpTopRank)

		# 刷新排名奖励
		if rank > 0:
			for idx in csv.pwrank_award:
				cfg = csv.pwrank_award[idx]
				award = self.game.role.pw_rank_award.get(idx,None)
				if award is None and rank <= cfg.needRank:
					self.game.role.pw_rank_award[idx] = 1

		# 翻牌
		flopResult = ObjectArenaFlopAwardRandom.flop(True if result == 'win' else False)
		eff = ObjectGainEffect(self.game, flopResult['award'], None)
		yield effectAutoGain(eff, self.game, self.dbcGame, src='arena_flop_award')

		if result == 'win':
			if myRole.PWpointActive != 1 and myRole.level < 45:
				self.game.dailyRecord.pvp_result_point += 1 # 非VIP的begin已经加过1
			modelBattle = yield makeBattleModel(self.game, self.rpcArena, self.dbcGame, True)
			ObjectUnionContribTask.onCount(self.game, TargetDefs.ArenaBattleWin, 1)
		else:
			modelBattle = yield makeBattleModel(self.game, self.rpcArena, self.dbcGame, False)

		view = ret
		view['result'] = result
		view.update(flopResult)
		result = {
			'view': view,
			'model': modelBattle,
		}

		self.write(result)


		ta.track(self.game, event='end_arena',result=result)

# 排位赛 5次碾压
class PWBattlePass(RequestHandlerTask):
	url = r'/game/pw/battle/pass'

	@coroutine
	def run(self):
		if not ObjectFeatureUnlockCSV.isOpen(FeatureDefs.PvpPass, self.game):
			raise ClientError('pvp_pass not open')
		role = self.game.role
		if role.pvp_record_db_id is None:
			raise ClientError('pvp not opened')

		battleRank = self.input.get('battleRank', None)
		if not battleRank:
			raise ClientError('param miss')
		if role.pw_rank >= battleRank:
			raise ClientError("battleRole rank error")

		dailyRecord = self.game.dailyRecord
		# 剩余可用挑战次数
		canPwTimes = role.freePWTimes + dailyRecord.buy_pw_times + dailyRecord.item_pw_times - dailyRecord.pvp_pw_times
		# 券的数量
		pwItemsCount = self.game.items.getItemCount(PVPBattleItemID)

		if canPwTimes >= 5:
			costPwItemsCount = 0
			needBuyTimes = 0
		else:
			# 需用券或再购买 优先用券
			if 0 < canPwTimes < 5:
				needTimes = 5 - canPwTimes
			else:
				needTimes = 5
			if pwItemsCount >= needTimes:  # 券足够
				costPwItemsCount = needTimes
				needBuyTimes = 0
			else:
				costPwItemsCount = pwItemsCount
				needBuyTimes = needTimes - costPwItemsCount

		# 购买次数限制
		if dailyRecord.buy_pw_times + needBuyTimes >= role.buyPWMaxTimes:
			raise ClientError(ErrDefs.pwBuyMax)

		# 消耗RMB = 购买次数的消耗RMB + 固定消耗
		costRMB = 0
		for i in xrange(0, needBuyTimes):
			costRMB += ObjectCostCSV.getPWBuyCost(self.game.dailyRecord.buy_pw_times + i)
		costRMB += ConstDefs.pvpPassCostRmb
		cost = ObjectCostAux(self.game, {'rmb': costRMB})
		# 消耗券
		if costPwItemsCount:
			cost += ObjectCostAux(self.game, {PVPBattleItemID: costPwItemsCount})
		if not cost.isEnough():
			raise ClientError('cost rmb not enough')
		cost.cost(src='pvp_pass5')

		# 重置挑战时间
		dailyRecord.pvp_pw_last_time = 0
		# 挑战次数+5
		dailyRecord.pvp_pw_times += 5
		# 购买次数加上
		dailyRecord.buy_pw_times += needBuyTimes
		# 券增加次数记录
		dailyRecord.item_pw_times += costPwItemsCount

		# 积分加 2*5
		dailyRecord.pvp_result_point += 2 * 5

		# 翻5次
		ret = []
		for i in xrange(5):
			# 翻牌
			flopResult = ObjectArenaFlopAwardRandom.flop(True)
			effOne = ObjectGainAux(self.game, flopResult['award'])
			yield effectAutoGain(effOne, self.game, self.dbcGame, src='pvp_pass5_award')
			ret.append(effOne.result)

		ObjectYYHuoDongFactory.onGeneralTask(self.game, TargetDefs.ArenaBattle, 5)
		self.game.achievement.onCount(AchievementDefs.ArenaBattle, 5)
		ObjectUnionContribTask.onCount(self.game, TargetDefs.ArenaBattleWin, 5)

		self.write({'view': ret})


# 购买排位赛次数
class PWBattleBuy(RequestHandlerTask):
	url = r'/game/pw/battle/buy'

	@coroutine
	def run(self):
		if self.game.dailyRecord.buy_pw_times >= self.game.role.buyPWMaxTimes:
			raise ClientError(ErrDefs.pwBuyMax)

		costRMB = ObjectCostCSV.getPWBuyCost(self.game.dailyRecord.buy_pw_times)

		cost = ObjectCostAux(self.game, {'rmb': costRMB})
		if not cost.isEnough():
			raise ClientError(ErrDefs.buyRMBNotEnough)
		cost.cost(src='pw_battle_buy')

		self.game.dailyRecord.buy_pw_times += 1
		# 重置挑战时间
		self.game.dailyRecord.pvp_pw_last_time = 0


# 获取排位赛录像数据
class PWPlayRecordGet(RequestHandlerTask):
	url = r'/game/pw/playrecord/get'

	@coroutine
	def run(self):
		recordID = self.input.get('recordID', None)
		if recordID is None:
			raise ClientError('param miss')

		model = yield self.rpcArena.call_async('GetArenaPlayRecord', recordID)
		self.write({
			'model': {
				'arena_playrecords': {
					recordID: model,
				}
			}
		})


# 竞技场积分商店购买
class PWShopBuy(RequestHandlerTask):
	url = r'/game/pw/shop/buy'

	@coroutine
	def run(self):
		csvID = self.input.get('csvID', None)
		count = self.input.get('count', 1)
		if csvID is None:
			raise ClientError('param miss')
		if count <= 0:
			raise ClientError('param error')

		pvpShop = ObjectPVPShop(self.game)
		eff = pvpShop.buyItem(csvID, count, src='pvp_shop_buy')
		yield effectAutoGain(eff, self.game, self.dbcGame, src='pvp_shop_buy')



# 购买排位赛冷却时间
class PWBattleCDBuy(RequestHandlerTask):
	url = r'/game/pw/battle/cd/buy'

	@coroutine
	def run(self):
		costRMB = ObjectCostCSV.getPWCDBuyCost(self.game.dailyRecord.buy_pw_cd_times)

		cost = ObjectCostAux(self.game, {'rmb': costRMB})
		if not cost.isEnough():
			raise ClientError(ErrDefs.buyRMBNotEnough)
		cost.cost(src='pw_battle_cd_buy')

		# 重置挑战时间
		self.game.dailyRecord.pvp_pw_last_time = 0
		self.game.dailyRecord.buy_pw_cd_times += 1


# 领取排位赛排名奖励
class PWBattleRankAward(RequestHandlerTask):
	url = r'/game/pw/battle/rank/award'

	@coroutine
	def run(self):
		csvID = self.input.get('csvID', None)
		if csvID is None or csvID not in csv.pwrank_award:
			raise ClientError('csvID err')

		flag = self.game.role.pw_rank_award.get(csvID,-1)
		if flag == -1:
			raise ClientError(ErrDefs.pwRankAwardLimit)
		if flag == 0:
			raise ClientError(ErrDefs.pwAwardAreadyHas)

		cfg = csv.pwrank_award[csvID]
		if cfg.cost:
			cost = ObjectCostAux(self.game, cfg.cost)
			if not cost.isEnough():
				raise ClientError('not enough')
			cost.cost(src='pw_rank_award')
		eff = ObjectPWAwardEffect(self.game, cfg.award)
		self.game.role.pw_rank_award[csvID] = 0
		yield effectAutoGain(eff, self.game, self.dbcGame, src='pw_rank_award')

# 领取排位赛积分奖励
class PWBattlePointAward(RequestHandlerTask):
	url = r'/game/pw/battle/point/award'

	@coroutine
	def run(self):
		csvID = self.input.get('csvID', None)
		if csvID is None:
			raise ClientError('csvID miss')
		retEff = None
		if csvID == -1: # 一键领取
			for csvID, flag in self.game.dailyRecord.result_point_award.iteritems():
				if flag == 1:
					cfg = csv.pwpoint_award[csvID]
					eff = ObjectPWAwardEffect(self.game, cfg.award)
					if retEff is None:
						retEff = eff
					elif eff:
						retEff += eff
					self.game.dailyRecord.result_point_award[csvID] = 0
		else:
			if csvID not in csv.pwpoint_award:
				raise ClientError('csvID err')
			flag = self.game.dailyRecord.result_point_award.get(csvID,-1)
			if flag == -1:
				raise ClientError(ErrDefs.pwPointAwardLimit)
			if flag == 0:
				raise ClientError(ErrDefs.pwAwardAreadyHas)

			cfg = csv.pwpoint_award[csvID]
			retEff = ObjectPWAwardEffect(self.game, cfg.award)
			self.game.dailyRecord.result_point_award[csvID] = 0
		ret = {}
		if retEff:
			yield effectAutoGain(retEff, self.game, self.dbcGame, src='pw_point_award')
			ret = retEff.result

		self.write({
			'view': ret,
		})

# 道具增加排位赛次数
class PWBattleItemUse(RequestHandlerTask):
	url = r'/game/pw/battle/item/use'

	@coroutine
	def run(self):
		cost = ObjectCostAux(self.game, {PVPBattleItemID: 1})
		if not cost.isEnough():
			raise ClientError(ErrDefs.pwBattleItemLimit)
		cost.cost(src='pw_battle_itemUse')

		self.game.dailyRecord.item_pw_times += 1
		# 重置挑战时间
		self.game.dailyRecord.pvp_pw_last_time = 0

# 竞技场选择展示卡牌
class PWBattleDisplay(RequestHandlerTask):
	url = r'/game/pw/display'

	@coroutine
	def run(self):
		role = self.game.role
		if role.pvp_record_db_id == 0:
			raise ClientError('pvp not opened')
		card_id = self.input.get('card_id', None)
		if card_id is None:
			raise ClientError('card_id miss')
		# 精灵图鉴 或 皮肤
		if card_id not in role.pokedex and (card_id % PVPSkinIDStart) not in role.skins:
			raise ClientError('card_id error')

		self.rpcArena.call_async('UpdateDisplay', role.pvp_record_db_id, card_id)

		self.write({
			'sync': {
				'arena': {
					'record': {'display': card_id},
				}
			}
		})

# 竞技场查看玩家信息
class PWBattleRoleInfo(RequestHandlerTask):
	url = r'/game/pw/role/info'

	@coroutine
	def run(self):
		recordID = self.input.get('recordID', None)
		if recordID is None:
			raise ClientError('recordID miss')

		view = yield self.rpcArena.call_async('GetArenaRoleInfo', recordID)
		view['union_name'] = ObjectUnion.queryUnionName(view['role_db_id'])
		self.write({
			'view': view,
		})

# 竞技场排名查看
class PWBattleRank(RequestHandlerTask):
	url = r'/game/pw/rank'

	@coroutine
	def run(self):
		offest = self.input.get('offest', 0)
		size = self.input.get('size', 50)

		ret = yield self.rpcArena.call_async('GetArenaTop50', offest, size)
		self.write({
			'view': {
				'rank': ret,
				'offest': offest,
				'size': size,
			},
		})
