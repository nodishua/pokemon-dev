#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2014 YouMi Information Technology Inc.

PVP Handlers
'''

from framework import nowdatetime_t, nowdtime_t, datetime2timestamp, todayinclock5date2int, int2date
from framework.log import logger
from framework.csv import ErrDefs, ConstDefs

from game import ClientError
from game.globaldata import UnionFightStartTime
from game.handler.task import RequestHandlerTask
from game.handler.inl import effectAutoGain
from game.object import UnionDefs, SceneDefs
from game.object.game.union_fight import ObjectUnionFightGlobal
from game.object.game.gain import ObjectCostAux
from game.object.game.union import ObjectUnion
from game.object.game.shop import ObjectUnionFightShop

from framework.helper import timeSubTime
from tornado.gen import coroutine, Return
from datetime import datetime, timedelta


@coroutine
def refreshUnionfCardsToPVP(rpc, game, deployCards=None, force=False):
	if game.role.union_fight_record_db_id is None:
		raise Return(None)

	deployment = game.cards.deploymentForUnionFight
	# 卡牌没发生改变
	if not any([force, deployCards, deployment.isdirty()]):
		raise Return(None)

	rpcCards = {}
	rpcCardAttrs = {}
	rpcCardAttrs2 = {}
	rpcPassiveSkills = {}
	if deployCards:
		for weekday, troops in deployCards.iteritems():
			for troopsIdx, cs in troops.iteritems():
				cards, dirty = deployment.refresh((weekday, troopsIdx), SceneDefs.UnionFight, cs)
				rpcCards.setdefault(weekday, {})
				rpcCards[weekday][troopsIdx] = cards
				cardsD1, cardsD2 = game.cards.makeBattleCardModel(set(cards), SceneDefs.UnionFight, dirty)
				rpcCardAttrs.update(cardsD1)
				rpcCardAttrs2.update(cardsD2)
	else:
		wt = {2: 2, 3: 2, 4: 2, 5: 2, 6: 3}
		for weekday, troopsNum in wt.iteritems():
			for troopsIdx in xrange(1, troopsNum + 1):
				cards, dirty = deployment.refresh((weekday, troopsIdx), SceneDefs.UnionFight, None)
				rpcCards.setdefault(weekday, {})
				rpcCards[weekday][troopsIdx] = cards
				cardsD1, cardsD2 = game.cards.makeBattleCardModel(set(cards), SceneDefs.UnionFight, dirty)
				rpcCardAttrs.update(cardsD1)
				rpcCardAttrs2.update(cardsD2)

	embattle = {
		'cards': rpcCards,
		'card_attrs': rpcCardAttrs,
		'card_attrs2': rpcCardAttrs2,
		'passive_skills': rpcPassiveSkills,
	}

	deployment.resetdirty()
	yield rpc.call_async('Deploy', game.role.union_fight_record_db_id, game.role.competitor, embattle)


@coroutine
def getViewAndModel(rpc, input, game):
	model = ObjectUnionFightGlobal.getSlimModel()
	t = UnionFightStartTime
	if ObjectUnionFightGlobal.StartBattleTime is not None:
		t = ObjectUnionFightGlobal.StartBattleTime
	subTime = timeSubTime(nowdtime_t(), t)
	waitSecond = 60
	curRound = int(subTime.total_seconds() / waitSecond)
	now = nowdatetime_t()
	weekday = now.isoweekday()
	nextRoundResultTime = datetime.combine(now.date(),t) + timedelta(seconds=waitSecond * (curRound +1))
	inputRound = input.get('roundKey', None)
	if inputRound is None:
		inputRound = curRound

	top8Deploy = ObjectUnionFightGlobal.getTop8Deploy(game.union.id)
	unionfiGlobal = ObjectUnionFightGlobal.Singleton
	if game.role.union_fight_record_db_id:
		inclock5Weekday = int2date(todayinclock5date2int()).isoweekday()
		view = yield rpc.call_async('GetUnionFightView', game.role.id, game.union.id, game.role.union_fight_record_db_id, unionfiGlobal.round, str(curRound), str(inputRound), top8Deploy, inclock5Weekday)
	else:
		view = {}
	roleInfo = view.pop('role_info', {})
	unionInfo = view.pop('union_info', {})
	rpcTop8Deploy = unionInfo.get("top8_deploy", {})
	rpctop8DeployRoles = rpcTop8Deploy.get('roles', [])
	rpcModel = view.pop('model', {})
	unionBattleStatus = rpcModel.pop('union_battle_status', {})

	if weekday == 6 and unionfiGlobal.round in ('signup', 'prepare'):
		# 可能存在部分报名的玩家卡牌异常而被过滤掉的情况
		if rpctop8DeployRoles is not None and len(top8Deploy) != len(rpctop8DeployRoles):
			ObjectUnionFightGlobal.setTop8Deploy(game.union.id, rpctop8DeployRoles)
		nextRoundBattleTime = datetime.combine(now.date(), UnionFightStartTime) + timedelta(minutes=5)
		rpcModel['next_round_battle_time'] = datetime2timestamp(nextRoundBattleTime)

	if unionfiGlobal.round == 'signup':
		unionSigns = model['signs'].get(game.union.id, (0, 0, ''))
		unionInfo['sign_num'] = unionSigns[0]
		unionInfo['member_num'] = unionSigns[1]
		if unionInfo['member_num'] == 0:
			unionInfo['member_num'] = len(game.union.members)

		# 周六报名阶段处理 top8 对阵信息
		if weekday == 6:
			for k, v in rpcModel['top8_vs_info'].iteritems():
				unionID = v[0]
				if unionID not in model['signs']:
					continue
				unionSigns = model['signs'].get(unionID, (0, 0, ''))
				v[4], v[5] = unionSigns[0], unionSigns[0],
				rpcModel['top8_vs_info'][k] = v

	# 战斗时显示报名人数和存活人数
	elif unionfiGlobal.round == 'battle':
		model['signs'] = unionBattleStatus

	unionInfo['sign_roles'] = ObjectUnionFightGlobal.getUnionSignRoles(game.union.id)

	model.update(rpcModel)
	model.update(role_info=roleInfo)
	model.update(union_info=unionInfo)
	model.update(next_round_result_time=int(datetime2timestamp(nextRoundResultTime)))
	raise Return((view, model))


# 报名
class UnionFightSignup(RequestHandlerTask):
	url = r'/game/union/fight/signup'

	@coroutine
	def run(self):
		if not ObjectUnionFightGlobal.isRoleOpen(self.game):
			raise ClientError(ErrDefs.unionfightNoOpen)

		if not ObjectUnionFightGlobal.isCanSignUp(self.game.role.id, self.game.role.union_fight_record_db_id):
			raise ClientError(ErrDefs.unionfightNoOpen)

		if not ObjectUnionFightGlobal.isRoleJionTime(self.game.role.union_quit_time):
			raise ClientError(ErrDefs.unionfightJionTimeUp)

		weekday = nowdatetime_t().isoweekday()
		deployCards = self.game.cards.deploymentForUnionFight.cards
		wt = {2: 2, 3: 2, 4: 2, 5: 2, 6: 3}
		canSign = True
		for troopIdx in xrange(1, wt[weekday] + 1):
			troopCards = [i for i in deployCards[(weekday, troopIdx)] if i]
			if len(troopCards) == 0:
				canSign = False
				break

		# 原有阵容不能报名，自动补全
		if not canSign:
			cards, _ = self.game.cards.makeUnionFightCardInfo()
			canSign = True
			troops = cards.get(weekday, {})
			if not troops:
				canSign = False
			for troopCards in troops.itervalues():
				if len(troopCards) == 0:
					canSign = False
					break
			if not canSign:
				raise ClientError(ErrDefs.unionFightCardNotEnough)
			yield refreshUnionfCardsToPVP(self.rpcUnionFight, self.game, deployCards=cards)

		ObjectUnionFightGlobal.signUp(self.game, True)

		view, model = yield getViewAndModel(self.rpcUnionFight, self.input, self.game)
		self.write({
			'model': {
				'union_fight': model
			}
		})


# 主赛场，我的赛场
class UnionFightBattleMain(RequestHandlerTask):
	url = r'/game/union/fight/battle/main'

	@coroutine
	def run(self):
		if not ObjectUnionFightGlobal.isOpenDay():
			raise ClientError(ErrDefs.unionfightNoOpen)
		union = self.game.union
		if union is None:
			raise ClientError('no union error')
		if not union.isFeatureOpen(UnionDefs.Unionfight):
			raise ClientError(ErrDefs.unionfightNoOpen)
		if self.game.role.level < ObjectUnionFightGlobal.OpenLevel:
			raise ClientError('role level error')

		if not ObjectUnionFightGlobal.isRoleJionTime(self.game.role.union_quit_time):
			raise ClientError(ErrDefs.unionfightJionTimeUp)

		weekday = nowdatetime_t().isoweekday()
		unionFightGlobal = ObjectUnionFightGlobal.Singleton
		if weekday != 6 and unionFightGlobal.round in ('prepare', 'battle') and union.id not in ObjectUnionFightGlobal.UnionFightSignUps:
			raise ClientError(ErrDefs.unionFightNotSign)

		role = self.game.role
		if role.union_fight_record_db_id is None:
			competitor = role.competitor
			competitor['union_db_id'] = role.union_db_id
			cards, cardIDs = self.game.cards.makeUnionFightCardInfo()
			cardsD1, cardsD2 = self.game.cards.makeBattleCardModel(cardIDs, SceneDefs.UnionFight)
			passiveSkills = self.game.cards.markBattlePassiveSkills(cardIDs, SceneDefs.UnionFight)
			embattle = {
				'cards': cards,
				'card_attrs': cardsD1,
				'card_attrs2': cardsD2,
				'passive_skills': passiveSkills,
			}
			role.union_fight_record_db_id = yield self.rpcUnionFight.call_async('CreateUnionFightRoleRecord', competitor, embattle)
			deployment = self.game.cards.deploymentForUnionFight
			for weekday, troops in cards.iteritems():
				for troopsIdx, cs in troops.iteritems():
					deployment.deploy((weekday, troopsIdx), cs)
		else:
			yield refreshUnionfCardsToPVP(self.rpcUnionFight, self.game)

		view, model = yield getViewAndModel(self.rpcUnionFight, self.input, self.game)
		self.write({
			'model': {
				'union_fight': model
			}
		})


# top8 round results
class UnionFightBTop8RoundResults(RequestHandlerTask):
	url = r'/game/union/fight/top8/round/results'

	@coroutine
	def run(self):
		roundKey = self.input.get('roundKey', '')
		results = yield self.rpcUnionFight.call_async('Top8RoundResult', self.game.union.id, roundKey)
		self.write({
			"model": {
				"union_fight": {
					"round_results": results
				}
			}
		})


# 挑战部署
class UnionFightBattleDeploy(RequestHandlerTask):
	url = r'/game/union/fight/battle/deploy'

	@coroutine
	def run(self):
		weekday = self.input.get('weekday', None)
		battleCardIDs = self.input.get('battleCardIDs', None)
		if weekday is None or battleCardIDs is None:
			raise ClientError('param is miss')
		if not (2 <= weekday <= 6):
			raise ClientError('weekday error')

		if not ObjectUnionFightGlobal.isRoleEnter(self.game):
			raise ClientError(ErrDefs.unionfightNoOpen)

		if not ObjectUnionFightGlobal.isRoleJionTime(self.game.role.union_quit_time):
			raise ClientError(ErrDefs.unionfightJionTimeUp)

		unionfiGlobal = ObjectUnionFightGlobal.Singleton
		curWeekday = nowdatetime_t().isoweekday()
		if unionfiGlobal.round in ('prepare', 'over', 'battle') and weekday <= curWeekday:
			raise ClientError(ErrDefs.unionfightDeployLimit)
		# lua的msgpack会把顺序数值下标的table认为是list
		if isinstance(battleCardIDs, list):
			battleCardIDs = {i + 1: battleCardIDs[i] for i in xrange(len(battleCardIDs))}

		battleCards = {weekday: {}}
		if weekday == 6:
			group = 3
		else:
			group = 2
		if len(battleCardIDs) != group:
			raise ClientError('battleCardIDs groups error')

		weekNatureLimit = ObjectUnionFightGlobal.WeekNatureLimit[weekday]
		hasSet = set()
		markSet = set()
		for i in xrange(1, group + 1):
			battleCards[weekday][i] = []
			cardIDs = battleCardIDs[i]
			if len(cardIDs) != 6:
				raise ClientError('cardIDs len error')

			count = 0
			for idx in cardIDs:
				if not idx:
					battleCards[weekday][i].append("")
					continue
				if idx in hasSet:
					raise ClientError('cardID many error')
				card = self.game.cards.getCard(idx)
				if card is None:
					raise ClientError('cardID error')
				if weekNatureLimit and card.natureType not in weekNatureLimit and card.natureType2 not in weekNatureLimit:
					logger.info("%s %s %s", weekNatureLimit, card.natureType, card.natureType2)
					raise ClientError(ErrDefs.unionFightDeployNatureError)
				if card.markID in markSet:
					raise ClientError('card markID may error')
				hasSet.add(idx)
				markSet.add(card.markID)
				battleCards[weekday][i].append(card.id)
				count += 1

			if count == 0:
				raise ClientError('card4 count error')
			if weekday == 6 and count > 4:
				raise ClientError('card4 count error')
			if weekday < 6 and count > 3:
				raise ClientError('card4 count error')

		yield refreshUnionfCardsToPVP(self.rpcUnionFight, self.game, battleCards, force=True)

		_, model = yield getViewAndModel(self.rpcUnionFight, self.input, self.game)

		self.write({
			'model': {
				'union_fight': model
			}
		})


# 获取录像数据
class UnionFightPlayRecordGet(RequestHandlerTask):
	url = r'/game/union/fight/playrecord/get'

	@coroutine
	def run(self):
		playID = self.input.get('playID', None)
		if playID is None:
			raise ClientError('param miss')

		model = yield self.rpcUnionFight.call_async('GetUnionFightPlayRecord', playID)
		self.write({'model': {'union_fight_playrecords': {playID: model}}})


# 排行榜
class UnionFightRank(RequestHandlerTask):
	url = r'/game/union/fight/rank'

	@coroutine
	def run(self):
		ret = yield self.rpcUnionFight.call_async('GetRankInfo', self.game.role.union_fight_record_db_id)
		self.write({'view': ret})


# 昨日战况，只看周2， 3， 4， 5
class UnionFightYesterdayBattle(RequestHandlerTask):
	url = r'/game/union/fight/yesterday/battle'

	@coroutine
	def run(self):
		unionfiGlobal = ObjectUnionFightGlobal.Singleton
		if unionfiGlobal.round in ('prepare', 'battle'):
			raise ClientError(ErrDefs.unionfightYesterdayLimit)

		weekday = nowdatetime_t().isoweekday()
		if weekday in (7, 1):
			raise ClientError(ErrDefs.unionfightYesterdayLimit)
		if weekday == 2 and unionfiGlobal.round != "over":
			raise ClientError(ErrDefs.unionfightYesterdayLimit)

		roundKey = self.input.get('roundKey', 0)

		ret = yield self.rpcUnionFight.call_async("BattleYesterday", self.game.union.id, roundKey)

		self.write({'view': ret})

# 我的下注
class UnionFightBetInfo(RequestHandlerTask):
	url = r'/game/union/fight/bet/info'

	@coroutine
	def run(self):
		if not ObjectUnionFightGlobal.isRoleOpen(self.game):
			raise ClientError(ErrDefs.unionfightNoOpen)

		view = yield self.rpcUnionFight.call_async('GetBetInfo')
		self.write({
			'view': view,
			'model': {
				'union_fight': ObjectUnionFightGlobal.getSlimModel(),
			},
		})


# 下注
class CraftBet(RequestHandlerTask):
	url = r'/game/union/fight/bet'

	@coroutine
	def run(self):
		unionID = self.input.get('unionID', None)
		if unionID is None:
			raise ClientError('unionID is miss')

		union = ObjectUnion.getUnionByUnionID(unionID)
		if union is None:
			raise ClientError('unionID is error')

		gold = self.input.get('gold', None)
		if gold is None or gold not in (ConstDefs.unionFightBetNormalGold, ConstDefs.unionFightBetAdvanceGold):
			raise ClientError('gold is error')

		# 只能在报名期间下注
		if not ObjectUnionFightGlobal.isCanBet():
			raise ClientError(ErrDefs.unionfightbetSign)

		# 是否已经下注
		if self.game.dailyRecord.union_fight_bets.get('rank1', None):
			raise ClientError(ErrDefs.unoinfightHasBet)

		cost = ObjectCostAux(self.game, {'gold': gold})
		if not cost.isEnough():
			raise ClientError(ErrDefs.unionfiBetGoldNotEnough)
		view = yield self.rpcUnionFight.call_async('BetUnion', self.game.role.id, unionID, gold)
		cost.cost(src='union_fight_bet')
		self.game.dailyRecord.union_fight_bets['rank1'] = [unionID, gold]

		self.write({
			'view': view,
			'model': {
				'union_fight': ObjectUnionFightGlobal.getSlimModel(),
			},
		})


# 商店兑换
class UnionFightShopBuy(RequestHandlerTask):
	url = r'/game/union/fight/shop/buy'

	@coroutine
	def run(self):
		if not ObjectUnionFightGlobal.isOpen():
			raise ClientError(ErrDefs.unionfightNoOpen)

		csvID = self.input.get('csvID', None)
		count = self.input.get('count', 1)
		if csvID is None:
			raise ClientError('param miss')
		if count <= 0:
			raise ClientError('param error')

		unionFightShop = ObjectUnionFightShop(self.game)
		eff = unionFightShop.buyItem(csvID, count, src='union_fight_shop_buy')
		yield effectAutoGain(eff, self.game, self.dbcGame, src='union_fight_shop_buy')


# top8 布阵
class UnionFightTop8DeployInfo(RequestHandlerTask):
	url = r'/game/union/fight/top8/deploy'

	@coroutine
	def run(self):
		weekday = nowdatetime_t().isoweekday()
		if weekday != 6:
			raise ClientError("not in weekday 6")

		roles = self.input.get('roles', None)
		if roles is None:
			raise ClientError('param is miss')

		if not self.game.union:
			raise ClientError(ErrDefs.unionNotExisted)

		# 只有会长与副会长能操作
		if not self.game.role.isUnionChairman() and not self.game.role.isUnionViceChairman():
			raise ClientError(ErrDefs.unionOnlyChairman)

		# 是否是八强公会
		if not ObjectUnionFightGlobal.isTop8Union(self.game.union.id):
			raise ClientError("not in top8 union")

		oldRoles = ObjectUnionFightGlobal.getTop8Deploy(self.game.union.id)
		if len(roles) != len(oldRoles):
			raise ClientError("roles change")

		unionFightGlobal = ObjectUnionFightGlobal.Singleton
		if unionFightGlobal.round != 'signup':
			yield self.rpcUnionFight.call_async('Top8Deploy', self.game.union.id, roles)
		ObjectUnionFightGlobal.setTop8Deploy(self.game.union.id, roles)
		_, model = yield getViewAndModel(self.rpcUnionFight, self.input, self.game)

		self.write({
			'model': {
				'union_fight': model
			}
		})

# 战斗执行
class UnionFightBattleStarSet(RequestHandlerTask):
	url = r'/game/union/fight/battle/star/set'

	@coroutine
	def run(self):
		if not self.game.union:
			raise ClientError(ErrDefs.unionNotExisted)

		# 只有会长与副会长能操作
		if not self.game.role.isUnionChairman() and not self.game.role.isUnionViceChairman():
			raise ClientError(ErrDefs.unionOnlyChairman)

		# 是否是八强公会
		if not ObjectUnionFightGlobal.isTop8Union(self.game.union.id):
			raise ClientError("not in top8 union")

		nature = self.input.get("nature", None)
		attr = self.input.get("attr", None)
		effectType = self.input.get("effectType", None)

		if nature is None or attr is None or effectType is None:
			raise ClientError("param is miss")

		if effectType not in (1, -1):
			raise ClientError("effectType error")

		# if nature
		yield  self.rpcUnionFight.call_async("SetBattleTop8Star", self.game.union.id, nature, attr, effectType)

		_, model = yield getViewAndModel(self.rpcUnionFight, self.input, self.game)

		self.write({
			'model': {
				'union_fight': model
			}
		})

