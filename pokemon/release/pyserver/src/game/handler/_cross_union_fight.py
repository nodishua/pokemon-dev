#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2014 YouMi Information Technology Inc.

cross_union_fight Handlers
'''

from framework.log import logger
from framework.csv import ErrDefs, csv
from game import ClientError
from game.handler.task import RequestHandlerTask
from game.object import UnionDefs, SceneDefs, CrossUnionFightDefs
from game.object.game.cross_union_fight import ObjectCrossUnionFightGameGlobal
from game.object.game.gain import ObjectCostAux
from game.object.game.rank import ObjectRankGlobal
from game.object.game.union import ObjectUnion
from framework.helper import transform2list
from tornado.gen import coroutine, Return
import random
import copy


@coroutine
def refreshToCrossUnionFight(game, rpcPVP, deployCards=None, topCards=None, project=None, force=False):
	role = game.role
	if not role.cross_union_fight_record_db_id:
		raise Return(None)

	deployment = game.cards.deploymentForCrossUnionFight
	# 卡牌没发生改变
	if not any([force, deployCards, topCards, deployment.isdirty(), project]):
		raise Return(None)
	if project and project not in [CrossUnionFightDefs.BattleSix, CrossUnionFightDefs.BattleFour, CrossUnionFightDefs.BattleOne]:
		raise Return(None)

	embattle = {}
	cardsAttr1 = {}
	cardsAttr2 = {}
	topCardsAttr1 = {}
	topCardsAttr2 = {}
	stage = 0
	# 初赛
	if deployCards:
		stage = CrossUnionFightDefs.PreStage
		newProject = project
		# cards
		ObjectCrossUnionFightGameGlobal.delOldCards(deployment, CrossUnionFightDefs.PreStage)  # 删掉原来的布阵
		newCards, _ = deployment.refresh((CrossUnionFightDefs.PreStage, newProject), SceneDefs.CrossUnionFight, deployCards)  # 新布阵
		oldCards = embattle.setdefault('cards', {})
		oldCards[CrossUnionFightDefs.PreStage] = {newProject: newCards}  # 只保留最新一种类型
		# cardsAttr
		cardsD1, cardsD2 = ObjectCrossUnionFightGameGlobal.makeCardsAttr(game, newProject, newCards)  # 属性计算
		cardsAttr1.update(cardsD1)
		cardsAttr2.update(cardsD2)
		# passive_skills
		passiveSkills = game.cards.markBattlePassiveSkills(newCards, SceneDefs.CrossUnionFight)  # 被动技能
		embattle['passive_skills'] = passiveSkills
	# 决赛
	elif topCards:
		stage = CrossUnionFightDefs.TopStage
		newTopProject = project
		# cards
		ObjectCrossUnionFightGameGlobal.delOldCards(deployment, CrossUnionFightDefs.TopStage)  # 删掉原来的布阵
		newTopCards, _ = deployment.refresh((CrossUnionFightDefs.TopStage, newTopProject), SceneDefs.CrossUnionFight, topCards)  # 新布阵
		cards = embattle.setdefault('cards', {})
		cards[CrossUnionFightDefs.TopStage] = {newTopProject: newTopCards}  # 只保留最新一种类型
		# cardsAttr
		topCardsD1, topCardsD2 = ObjectCrossUnionFightGameGlobal.makeCardsAttr(game, newTopProject, newTopCards)  # 属性计算
		topCardsAttr1.update(topCardsD1)
		topCardsAttr2.update(topCardsD2)
		# passive_skills
		topPassiveSkills = game.cards.markBattlePassiveSkills(newTopCards, SceneDefs.CrossUnionFight)  # 被动技能
		embattle['top_passive_skills'] = topPassiveSkills

	# dirty
	for key, keyCards in deployment.cards.iteritems():
		ty, pro = key
		if ty == CrossUnionFightDefs.PreStage:
			dirty = deployment.getdirty((ty, pro))
			dirtyCardsD1, dirtyCardsD2 = game.cards.makeBattleCardModel([], SceneDefs.CrossUnionFight, dirty)
			cardsAttr1.update(dirtyCardsD1)
			cardsAttr2.update(dirtyCardsD2)
		else:
			topDirty = deployment.getdirty((ty, pro))
			topDirtyCardsD1, topDirtyCardsD2 = game.cards.makeBattleCardModel([], SceneDefs.CrossUnionFight, topDirty)
			topCardsAttr1.update(topDirtyCardsD1)
			topCardsAttr2.update(topDirtyCardsD2)

	embattle['card_attrs'] = cardsAttr1
	embattle['card_attrs2'] = cardsAttr2
	embattle['top_card_attrs'] = topCardsAttr1
	embattle['top_card_attrs2'] = topCardsAttr2

	deployment.resetdirty()
	competitor = role.competitor
	competitor['title'] = role.title_id
	yield rpcPVP.call_async('CrossUnionFightDeployCards', role.cross_union_fight_record_db_id, competitor, embattle, stage, project)

	fightingPoint = 0
	if deployCards:
		for cardID, attr in cardsAttr1.iteritems():
			fightingPoint = fightingPoint + attr['fighting_point']
	elif topCards:
		for cardID, attr in topCardsAttr1.iteritems():
			fightingPoint = fightingPoint + attr['fighting_point']
	raise Return(fightingPoint)


@coroutine
def makeCrossUnionFightModel(game, rpc, rpcPVP):
	role = game.role
	if not role.cross_union_fight_record_db_id:
		raise Return(({}, {}))
	# {Cards; PreBattleGroups; TopBattleGroups; Unions; Roles;}
	model = {}
	record = yield rpcPVP.call_async('GetCrossUnionFightRoleRecord', role.cross_union_fight_record_db_id)
	if ObjectCrossUnionFightGameGlobal.isCrossOpen(role.areaKey):
		# 精简只留 cards
		model['cards'] = record['cards']

		cardAttrs = record['card_attrs']
		if 'top' in ObjectCrossUnionFightGameGlobal.Singleton.status:
			cardAttrs = record['top_card_attrs']
		roleInfo = ObjectCrossUnionFightGameGlobal.markCrossUnionFightRoleInfo(game.role, cardAttrs)
		datas = yield rpc.call_async('GetCrossUnionFightModel', roleInfo)
		model.update(datas)
	else:
		model.update(ObjectCrossUnionFightGameGlobal.makeLastModel(role.areaKey))

	model.update(ObjectCrossUnionFightGameGlobal.getCrossGameModel(role.areaKey))

	raise Return(model)


# 主界面main请求 （同步model客户端)
class CrossUnionFightMain(RequestHandlerTask):
	url = r'/game/cross/union/fight/main'

	@coroutine
	def run(self):
		if not ObjectCrossUnionFightGameGlobal.isRoleOpen(self.game):
			raise ClientError(ErrDefs.crossunionfightNoRoleOpen)
		if not ObjectCrossUnionFightGameGlobal.isRoleJoinTime(self.game.role.union_quit_time, 1):
			raise ClientError(ErrDefs.crossunionfightJionTimeUp)

		role = self.game.role
		if not role.cross_union_fight_record_db_id and role.union_db_id:
			# 在线玩家首次 game给阵容
			competitor = role.competitor
			competitor['title'] = role.title_id
			# 随机战场 (初赛/决赛一样）
			project = random.choice([1, 2, 3])
			cards, cardIDs = self.game.cards.makeCrossUnionFightCardInfo(project)
			cardsD1, cardsD2 = ObjectCrossUnionFightGameGlobal.makeCardsAttr(self.game, project, cardIDs)
			passiveSkills = self.game.cards.markBattlePassiveSkills(cardIDs, SceneDefs.CrossUnionFight)
			embattle = {
				'cards': cards,
				'card_attrs': cardsD1,
				'card_attrs2': cardsD2,
				'passive_skills': passiveSkills,
				'top_card_attrs': cardsD1,
				'top_card_attrs2': cardsD2,
				'top_passive_skills': passiveSkills,
			}
			ret = yield self.rpcPVP.call_async('CreateCrossUnionFightRoleRecord', competitor, embattle, project)
			role.cross_union_fight_record_db_id = ret['id']
			cards = ret['cards']
			deployment = self.game.cards.deploymentForCrossUnionFight
			# ty 初/决； groupID 战场
			for ty, battleCards in cards.iteritems():
				for pj, gCards in battleCards.iteritems():
					deployment.deploy((ty, pj), gCards)
		else:
			yield refreshToCrossUnionFight(self.game, self.rpcPVP)

		rpc = ObjectCrossUnionFightGameGlobal.cross_client(role.areaKey)
		model = yield makeCrossUnionFightModel(self.game, rpc, self.rpcPVP)

		self.write({
			'model': {
				'cross_union_fight': model
			},
		})


# 比赛中战报 获取
class CrossUnionFightBattleResult(RequestHandlerTask):
	url = r'/game/cross/union/fight/battle/result'

	@coroutine
	def run(self):
		role = self.game.role
		if not ObjectCrossUnionFightGameGlobal.isRoleEnter(self.game):
			raise ClientError(ErrDefs.crossunionfightNoEnter)

		group = self.input.get('group', None)  # 1-4=初赛 5=决赛
		battleTypes = self.input.get('battleTypes', None)  # {1: start, 2: start, 3: start} 1=6V6  2=4V4  3=1V1
		if not all([x is not None for x in [group, battleTypes]]):
			raise ClientError('param miss')
		if not (1 <= group <= 5):
			raise ClientError('group error')
		# lua的msgpack会把顺序数值下标的table认为是list
		if isinstance(battleTypes, list):
			battleTypes = {idx + 1: v for idx, v in enumerate(battleTypes)}

		ret = {}
		rpc = ObjectCrossUnionFightGameGlobal.cross_client(role.areaKey)
		for battleType, start in battleTypes.iteritems():
			results = yield rpc.call_async('GetCrossUnionFightBattleResult', group, battleType, start, role.id)
			ret[battleType] = results

		status = ObjectCrossUnionFightGameGlobal.getStatus(role.areaKey)

		self.write({
			'view': {
				'status': status,
				'results': ret,
			},
		})


# 公会积分排行榜
class CrossUnionFightPointRank(RequestHandlerTask):
	url = r'/game/cross/union/fight/point/rank'

	@coroutine
	def run(self):
		if not ObjectCrossUnionFightGameGlobal.isRoleOpen(self.game):
			raise ClientError(ErrDefs.crossunionfightNoRoleOpen)

		offest = self.input.get('offest', 0)
		size = self.input.get('size', 5)

		# 排行
		rank, unionIDs = yield ObjectCrossUnionFightGameGlobal.getUnionFightPointRank(self.game.role.areaKey)
		self.write({
			'view': {
				'rank': rank[:size],
				'offest': offest,
				'size': size,
				'union_db_ids': unionIDs,
			},
		})


# 获取玩家阵容详情
class CrossUnionFightRoleInfo(RequestHandlerTask):
	url = r'/game/cross/union/fight/role/info'

	@coroutine
	def run(self):
		if not self.game.role.cross_union_fight_record_db_id:
			raise ClientError(ErrDefs.crossunionfightNoOpen)

		recordID = self.input.get('recordID', None)
		if not all([x is not None for x in [recordID]]):
			raise ClientError('param miss')

		view = yield self.rpcPVP.call_async('GetCrossUnionFightRoleRecord', recordID)

		self.write({
			'view': view,
		})


# 战斗布阵
class CrossUnionFightBattleDeploy(RequestHandlerTask):
	url = r'/game/cross/union/fight/battle/deploy'

	@coroutine
	def run(self):
		if not ObjectCrossUnionFightGameGlobal.isRoleEnter(self.game):
			raise ClientError(ErrDefs.crossunionfightNoEnter)

		stage = self.input.get('stage', None)  # 1=初赛 2=决赛
		deployType = self.input.get('deployType', None)  # 1=6V6  2=4V4  3=1V1
		battleCardIDs = self.input.get('battleCardIDs', None)
		if stage is None or battleCardIDs is None:
			raise ClientError('param is miss')
		if not (1 <= stage <= 2):
			raise ClientError('type error')
		if not (1 <= deployType <= 3):
			raise ClientError('deployType error')

		troopCards = []
		if deployType == CrossUnionFightDefs.BattleSix:
			cards = transform2list(battleCardIDs, 12)
			troopCards.append(cards[:6])
			troopCards.append(cards[6:12])
		elif deployType == CrossUnionFightDefs.BattleFour:
			cards = transform2list(battleCardIDs, 18)
			troopCards.append(cards[:6])
			troopCards.append(cards[6:12])
			troopCards.append(cards[12:18])
		else:
			cards = transform2list(battleCardIDs, 9)
			troopCards.append(cards[:3])
			troopCards.append(cards[3:6])
			troopCards.append(cards[6:9])
		if self.game.cards.isDuplicateMarkID(cards):
			raise ClientError('cards have duplicates')
		for troopCard in troopCards:
			if len(filter(None, troopCard)) == 0:
				raise ClientError('have one battleCards all None')
		# 部署阵容
		if stage == CrossUnionFightDefs.PreStage:
			fightingPoint = yield refreshToCrossUnionFight(self.game, self.rpcPVP, deployCards=cards, project=deployType)
		else:
			fightingPoint = yield refreshToCrossUnionFight(self.game, self.rpcPVP, topCards=cards, project=deployType)

		role = self.game.role
		rpc = ObjectCrossUnionFightGameGlobal.cross_client(role.areaKey)
		if fightingPoint is not None:
			# 选择战场
			yield rpc.call_async('CrossUnionFightChooseProject', role.id, stage, deployType, fightingPoint)
		model = yield makeCrossUnionFightModel(self.game, rpc, self.rpcPVP)

		self.write({
			'model': {
				'cross_union_fight': model
			}
		})


# 战报回放
class CrossUnionFightPlayRecordGet(RequestHandlerTask):
	url = r'/game/cross/union/fight/playrecord/get'

	@coroutine
	def run(self):
		playID = self.input.get('playID', None)
		crossKey = self.input.get('crossKey', None)
		if playID is None or crossKey is None:
			raise ClientError('param miss')

		role = self.game.role
		rpc = ObjectCrossUnionFightGameGlobal.cross_client(role.areaKey, cross_key=crossKey)
		if rpc is None:
			raise ClientError('Cross Union Fight Play Not Existed')
		model = yield rpc.call_async('GetCrossUnionFightPlayRecord', playID)
		if not model:
			raise ClientError('Cross Union Fight Play Not Existed')

		self.write({
			'model': {
				'cross_union_fight_playrecords': {
					playID: model
				}
			}
		})


# 排行榜
class CrossUnionFightRank(RequestHandlerTask):
	url = r'/game/cross/union/fight/rank'

	@coroutine
	def run(self):
		if not ObjectCrossUnionFightGameGlobal.isRoleOpen(self.game):
			raise ClientError(ErrDefs.crossunionfightNoRoleOpen)

		# 比赛进行中 客户端自己构建
		role = self.game.role
		ret = ObjectCrossUnionFightGameGlobal.getRankList(role.areaKey)
		self.write({
			'view': {
				'last_ranks': ret,
			}
		})


# 上期回顾
class CrossUnionFightLastBattle(RequestHandlerTask):
	url = r'/game/cross/union/fight/last/battle'

	@coroutine
	def run(self):
		if not ObjectCrossUnionFightGameGlobal.isRoleOpen(self.game):
			raise ClientError(ErrDefs.crossunionfightNoRoleOpen)

		group = self.input.get('group', None)  # 1-4=初赛 5=决赛

		role = self.game.role
		# 上期数据 直接在game拿
		ret = ObjectCrossUnionFightGameGlobal.getLastRoundResults(role.areaKey, group)

		self.write({'view': ret})


# 竞猜界面信息
class CrossUnionFightBetInfo(RequestHandlerTask):
	url = r'/game/cross/union/fight/bet/info'

	@coroutine
	def run(self):
		if not ObjectCrossUnionFightGameGlobal.isRoleOpen(self.game):
			raise ClientError(ErrDefs.crossunionfightNoRoleOpen)

		role = self.game.role
		if ObjectCrossUnionFightGameGlobal.isCrossOpen(role.areaKey):
			rpc = ObjectCrossUnionFightGameGlobal.cross_client(role.areaKey)
			bets = yield rpc.call_async('GetCrossUnionFightBets')
		else:
			bets = ObjectCrossUnionFightGameGlobal.getLastBets(role.areaKey)

		self.write({
			'view': {
				'bets': bets,
			},
		})


# 竞猜
class CrossUnionFightBet(RequestHandlerTask):
	url = r'/game/cross/union/fight/bet'

	@coroutine
	def run(self):
		if not ObjectCrossUnionFightGameGlobal.isRoleEnter(self.game):
			raise ClientError(ErrDefs.crossunionfightNoEnter)

		group = self.input.get('group', None)  # 组别
		unionID = self.input.get('unionID', None)

		if not all([x is not None for x in [group, unionID]]):
			raise ClientError('param miss')
		if not (1 <= group <= 5):
			raise ClientError('group is error')

		# 只能在准备期间下注
		if not ObjectCrossUnionFightGameGlobal.isCanBet(self.game.role.areaKey, group):
			raise ClientError(ErrDefs.crossunionfightbetSign)

		# 是否已经下注
		role = self.game.role
		rpc = ObjectCrossUnionFightGameGlobal.cross_client(role.areaKey)
		bets = yield rpc.call_async('GetCrossUnionFightBets')
		gBets = bets.get(group, {})
		for _, betInfo in gBets.iteritems():
			roleKeys = betInfo.get("role_keys", [])
			for roleKey in roleKeys:
				if role.id == roleKey[1]:
					raise ClientError(ErrDefs.crossunoinfightHasBet)
		# 竞猜消耗
		cfgBase = csv.cross.union_fight.base[1]
		if group != 5:
			cost = ObjectCostAux(self.game, cfgBase.preBetCost)
		else:
			cost = ObjectCostAux(self.game, cfgBase.top4BetCost)
		if not cost.isEnough():
			raise ClientError("cost not enough")
		cost.cost(src='cross_union_fight_bet')

		# 返回 最新的bet数据
		bets = yield rpc.call_async('CrossUnionFightBetUnion', role.id, role.areaKey, group, unionID)

		self.write({
			'view': {
				'bets': bets,
			},
		})


# 获取战场分布
class CrossUnionFightDeployRoles(RequestHandlerTask):
	url = r'/game/cross/union/fight/deploy/roles'

	@coroutine
	def run(self):
		role = self.game.role
		if not ObjectCrossUnionFightGameGlobal.isRoleOpen(self.game):
			raise ClientError(ErrDefs.crossunionfightNoRoleOpen)

		stage = self.input.get('stage', None)  # 1=初赛 2=决赛
		unionID = self.input.get('unionID', None)
		if not all([x is not None for x in [stage, unionID]]):
			raise ClientError('param miss')
		if not (1 <= stage <= 2):
			raise ClientError('type error')

		if ObjectCrossUnionFightGameGlobal.isCrossOpen(role.areaKey):
			rpc = ObjectCrossUnionFightGameGlobal.cross_client(role.areaKey)
			deployRoles = yield rpc.call_async('GetCrossUnionFightDeployRoles', stage, unionID)
		else:
			deployRoles = ObjectCrossUnionFightGameGlobal.getLastDeployRoles(role.areaKey, stage, unionID)

		self.write({
			'view': {
				'deploy_roles': deployRoles,
			},
		})

