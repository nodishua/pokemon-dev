#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2014 YouMi Information Technology Inc.

PVP Handlers
'''

from framework import period2date, date2int, nowtime_t, nowtime2period, todaydate2int
from framework.csv import ErrDefs, csv, ConstDefs
from framework.helper import transform2list

from game import ServerError, ClientError
from game.object import YYHuoDongDefs, AchievementDefs, TargetDefs
from game.handler.task import RequestHandlerTask
from game.handler.inl import effectAutoGain
from game.object import FeatureDefs, SceneDefs
from game.object.game import ObjectGame
from game.object.game.gain import ObjectCostAux, ObjectGainAux
from game.object.game.levelcsv import ObjectFeatureUnlockCSV
from game.object.game.message import ObjectMessageGlobal
from game.object.game.craft import ObjectCraftInfoGlobal
from game.object.game.shop import ObjectCraftShop
from game.object.game.yyhuodong import ObjectYYHuoDongFactory
from game.thinkingdata import ta

from tornado.gen import coroutine, Return
from nsqrpc.error import CallError


@coroutine
def refreshCardsToPVP(rpc, game, cards=None, hold_cards=None, force=False):
	if game.role.craft_record_db_id is None:
		raise Return(None)

	deployment = game.cards.deploymentForCraft
	# 卡牌没发生改变
	if not any([force, cards, hold_cards, deployment.isdirty()]):
		raise Return(None)

	# session clean or craft prepare will force refresh newest card attrs

	embattle = {}
	if cards:
		embattle['cards'] = cards
	if hold_cards:
		embattle['cards'] = hold_cards
	cards, dirty = deployment.refresh('cards', SceneDefs.Craft, hold_cards)
	embattle['card_attrs'], embattle['card_attrs2'] = game.cards.makeBattleCardModel(cards, SceneDefs.Craft, dirty)
	embattle['passive_skills'] = game.cards.markBattlePassiveSkills(cards, SceneDefs.Craft)

	deployment.resetdirty()
	if hold_cards:
		yield rpc.call_async('DeployHold', game.role.craft_record_db_id, game.role.competitor, embattle)
	else:
		yield rpc.call_async('Deploy', game.role.craft_record_db_id, game.role.competitor, embattle)

@coroutine
def getViewAndModel(rpc, game, refresh_time=None, vsid=None):
	model = ObjectCraftInfoGlobal.getSlimModel()

	if game.role.craft_record_db_id:
		view = yield rpc.call_async('GetCraftView', game.role.id, game.role.craft_record_db_id)
	else:
		view = {'history': [], 'info':{}, 'vsinfo': {}}
	history = view.pop('history', None)
	info = view.pop('info', None)
	vsinfo = view.pop('vsinfo', None)
	if vsinfo is None:
		vsinfo = {} # None 在lua层会被转换成 nil
	model.update(info=info, vsinfo=vsinfo, history=history)
	if model['round'] in ('closed', 'signup'): # 非开始战斗才发昨天战况数据
		plays = ObjectCraftInfoGlobal.getYesterdayTop8(refresh_time)
		if plays:
			model['yesterday_top8_plays'] = plays
		else:
			model['yesterday_top8_plays'] = {}
	else:
		model['yesterday_top8_plays'] = {}

	if model['round'] == 'prepare': # 特殊处理，prepare阶段的时候，服务器是异步清理 hisotry
		model['history'] = {}

	raise Return((view, model))


# 报名
class CraftSignUp(RequestHandlerTask):
	url = r'/game/craft/signup'

	@coroutine
	def run(self):
		if not ObjectCraftInfoGlobal.isRoleOpen(self.game.role.level):
			raise ClientError(ErrDefs.craftNoOpen)

		if not ObjectCraftInfoGlobal.isCanSignUp(self.game):
			raise ClientError(ErrDefs.craftNoOpen)

		if self.game.role.craft_record_db_id is None:
			raise ClientError('not enough cards')

		cards = self.input.get('cards', None)
		if cards:
			cards = transform2list(cards, least=10)
			if self.game.cards.isDuplicateMarkID(cards):
				raise ClientError('cards have duplicates')

			cardsLen = len(filter(None, cards))
			if cardsLen < 10:
				raise ClientError('cards not enough')

		ObjectCraftInfoGlobal.signUp(self.game, cards, manual=True)
		if cards:
			yield refreshCardsToPVP(self.rpcCraft, self.game, hold_cards=cards)

		view, model = yield getViewAndModel(self.rpcCraft, self.game)
		self.game.achievement.onCount(AchievementDefs.CraftBattle, 1)
		ObjectYYHuoDongFactory.onGeneralTask(self.game, TargetDefs.CraftSignup, 1)
		self.write({
			'view': view,
			'model': {
				'craft': model,
			},
		})


# 主赛场，我的赛场
# 进入拳皇争霸功能一定要先请求该接口
class CraftBattleMain(RequestHandlerTask):
	url = r'/game/craft/battle/main'

	@coroutine
	def run(self):
		refresh_time = self.input.get('refresh_time', 0)
		vsid = self.input.get('vsid', 0)

		if not ObjectCraftInfoGlobal.isRoleOpen(self.game.role.level):
			raise ClientError(ErrDefs.craftNoOpen)

		role = self.game.role
		if len(role.top_cards) >= 10:
			# 新建CraftRecord
			if role.craft_record_db_id is None:
				cards = role.top_cards[:10]
				cardsD, cardsD2 = self.game.cards.makeBattleCardModel(cards, SceneDefs.Craft)
				passiveSkills = self.game.cards.markBattlePassiveSkills(cards, SceneDefs.Craft)
				embattle = {
					'cards': cards,
					'card_attrs': cardsD,
					'card_attrs2': cardsD2,
					'passive_skills': passiveSkills,
				}
				role.craft_record_db_id = yield self.rpcCraft.call_async('CreateCraftRecord', role.competitor, embattle)

				deployment = self.game.cards.deploymentForCraft
				deployment.deploy('cards', cards)

			# 保存玩家最新卡牌数据
			# 现在策略是玩家必须要打开拳皇争霸界面才会刷新卡牌数据
			else:
				yield refreshCardsToPVP(self.rpcCraft, self.game)

		view, model = yield getViewAndModel(self.rpcCraft, self.game)
		self.write({
			'view': view,
			'model': {
				'craft': model,
			},
		})


# 我的下注
class CraftBetInfo(RequestHandlerTask):
	url = r'/game/craft/bet/info'

	@coroutine
	def run(self):
		view = yield self.rpcCraft.call_async('GetBetInfo')
		self.write({
			'view': view,
		})


# 下注
class CraftBet(RequestHandlerTask):
	url = r'/game/craft/bet'

	@coroutine
	def run(self):
		roleID = self.input.get('roleID', None)
		if roleID is None:
			raise ClientError('roleID is miss')

		gold = self.input.get('gold', None)
		if gold is None or gold not in (ConstDefs.craftBetNormalGold, ConstDefs.craftBetAdvanceGold):
			raise ClientError('gold is error')

		if not ObjectCraftInfoGlobal.isRoleOpen(self.game.role.level):
			raise ClientError(ErrDefs.craftNoOpen)

		# 只能在报名期间下注
		if not ObjectCraftInfoGlobal.isCanBet():
			raise ClientError(ErrDefs.craftCanNotBet)

		# 是否已经下注
		if self.game.dailyRecord.craft_bets.get('rank1', None):
			raise ClientError(ErrDefs.craftBetYet)

		cost = ObjectCostAux(self.game, {'gold': gold})
		if not cost.isEnough():
			raise ClientError(ErrDefs.craftBetGoldNotEnough)
		view = yield self.rpcCraft.call_async('BetRole', self.game.role.id, roleID, gold)
		cost.cost(src='craft_battle')
		self.game.dailyRecord.craft_bets['rank1'] = [roleID, gold]

		self.write({
			'view': view,
		})

# 获取对方参赛信息
class CraftBattleEnemyGet(RequestHandlerTask):
	url = r'/game/craft/battle/enemy/get'

	@coroutine
	def run(self):
		roleID = self.input.get('roleID', None)
		if roleID is None:
			raise ClientError('roleID miss')

		recordID = self.input.get('recordID', None)
		if recordID is None:
			raise ClientError('recordID miss')

		ret = yield self.rpcCraft.call_async('GetCraftRecord', recordID)

		view = ret if ret else {'online': False}
		enemyGame = ObjectGame.getByRoleID(roleID, safe=False)
		if enemyGame:
			# 10分钟离线
			view['online'] = (nowtime_t() - enemyGame.role.last_time < 10 * 60)
		else:
			view['online'] = False

		if ObjectCraftInfoGlobal.isInBattle():
			_, model = yield getViewAndModel(self.rpcCraft, self.game)
		else:
			model = None
		self.write({
			'view': view,
			'model': {
				'craft': model,
			}
		})


# 挑战部署
class CraftBattleDeploy(RequestHandlerTask):
	url = r'/game/craft/battle/deploy'

	@coroutine
	def run(self):
		cards = self.input.get('battleCardIDs', None)
		if cards is None:
			raise ClientError('cards is error')

		cards = transform2list(cards, least=10)
		cardsLen = len(filter(None, cards))
		if cardsLen < 10:
			raise ClientError('cards not enough')

		if not ObjectCraftInfoGlobal.isSigned(self.game):
			raise ClientError(ErrDefs.craftNoOpen)

		if ObjectCraftInfoGlobal.isOver(): # 已经结束
			raise ClientError(ErrDefs.craftOver)

		if ObjectCraftInfoGlobal.isInSign():
			# 报名阶段才校验，战斗阶段craft service会进行校验
			if self.game.cards.isDuplicateMarkID(cards):
				raise ClientError('cards have duplicates')
			yield refreshCardsToPVP(self.rpcCraft, self.game, hold_cards=cards)
		else:
			yield refreshCardsToPVP(self.rpcCraft, self.game, cards=cards)

		_, model = yield getViewAndModel(self.rpcCraft, self.game)
		self.write({
			'model': {
				'craft': model,
			},
		})


# 获取录像数据
class CraftPlayRecordGet(RequestHandlerTask):
	url = r'/game/craft/playrecord/get'

	@coroutine
	def run(self):
		recordID = self.input.get('recordID', None)
		if recordID is None:
			raise ClientError('param miss')

		model = yield self.rpcCraft.call_async('GetCraftPlayRecord', recordID)
		self.write({'model': {'craft_playrecords': {recordID: model}}})


# 商店兑换
class CraftShopBuy(RequestHandlerTask):
	url = r'/game/craft/shop/buy'

	@coroutine
	def run(self):
		if not ObjectCraftInfoGlobal.isRoleOpen(self.game.role.level):
			raise ClientError(ErrDefs.craftNoOpen)

		csvID = self.input.get('csvID', None)
		count = self.input.get('count', 1)
		if csvID is None:
			raise ClientError('param miss')
		if count <= 0:
			raise ClientError('param error')

		craftShop = ObjectCraftShop(self.game)
		eff = craftShop.buyItem(csvID, count, src='craft_shop_buy')
		yield effectAutoGain(eff, self.game, self.dbcGame, src='craft_shop_buy')
