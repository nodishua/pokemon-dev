#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2014 YouMi Information Technology Inc.

PVP Handlers
'''

from framework import period2date, date2int, nowtime_t, nowtime2period, todaydate2int
from framework.csv import ErrDefs, csv
from framework.log import logger
from framework.service.helper import game2pvp
from framework.helper import transform2list

from game import ServerError, ClientError
from game.object import YYHuoDongDefs
from game.globaldata import CraftBetNormalGold, CraftBetAdvanceGold
from game.handler.task import RequestHandlerTask
from game.handler.inl import effectAutoGain
from game.object import FeatureDefs, SceneDefs
from game.object.game import ObjectGame
from game.object.game.gain import ObjectCostAux, ObjectGainAux
from game.object.game.levelcsv import ObjectFeatureUnlockCSV
from game.object.game.message import ObjectMessageGlobal
from game.object.game.cross_craft import ObjectCrossCraftGameGlobal
from game.object.game.shop import ObjectCrossCraftShop
from game.object.game.cache import ObjectCacheGlobal

from tornado.gen import coroutine, Return
from nsqrpc.error import CallError


@coroutine
def refreshCardsToPVP(rpc, game, cards=None, hold_cards=None, force=False):
	if game.role.cross_craft_record_db_id is None:
		raise Return(None)

	deployment = game.cards.deploymentForCrossCraft
	# 卡牌没发生改变
	if not any([force, cards, hold_cards, deployment.isdirty()]):
		raise Return(None)

	# session clean or craft prepare will force refresh newest card attrs

	embattle = {}
	if cards:
		embattle['cards'] = cards
	if hold_cards:
		embattle['cards'] = hold_cards
	cards, dirty = deployment.refresh('cards', SceneDefs.CrossCraft, hold_cards)
	embattle['card_attrs'], embattle['card_attrs2'] = game.cards.makeBattleCardModel(cards, SceneDefs.CrossCraft, dirty)
	embattle['passive_skills'] = game.cards.markBattlePassiveSkills(cards, SceneDefs.CrossCraft)

	deployment.resetdirty()
	if hold_cards:
		yield rpc.call_async('CrossCraftDeployHold', game.role.cross_craft_record_db_id, game.role.competitor, embattle)
	else:
		round, lockcards = ObjectCrossCraftGameGlobal.getRoundAndLockCards(game.role.areaKey)
		yield rpc.call_async('CrossCraftDeploy', game.role.cross_craft_record_db_id, game.role.competitor, embattle, round, lockcards)

@coroutine
def getViewAndModel(rpc, game, refresh_time=None):
	areaKey = game.role.areaKey
	model = ObjectCrossCraftGameGlobal.getSlimModel(areaKey)
	prepareOK = ObjectCrossCraftGameGlobal.prepareOK(areaKey)
	if game.role.cross_craft_record_db_id:
		view = yield rpc.call_async('GetCrossCraftView', game.role.id, game.role.cross_craft_record_db_id, prepareOK)
		if model['round'] != 'closed' and ObjectCrossCraftGameGlobal.isSigned(game): # 已报名才拿info和vsinfo
			view2 = yield ObjectCrossCraftGameGlobal.cross_client(areaKey).call_async('GetCrossCraftView', game.role.id)
			if view2['vsinfo'] is None:
				view2['vsinfo'] = {} # None 在lua层会被转换成 nil
			model.update(view2) # info, vsinfo
	else:
		view = {'history': [], 'cards': [], 'card_attrs': {}, 'info':{}, 'vsinfo': {}}
	model.update(view)
	if model['round'] in ('closed', 'signup'): # 非开始战斗才发昨天战况数据
		plays = ObjectCrossCraftGameGlobal.getLastTop8(refresh_time, areaKey)
		if plays:
			model['last_top8_plays'] = plays
		else:
			model['last_top8_plays'] = {}
	else:
		model['last_top8_plays'] = {}

	if model['round'] == 'prepare': # 特殊处理，prepare阶段的时候，服务器是异步清理 hisotry
		model['history'] = []

	raise Return((None, model))


# 报名
class CrossCraftSignUp(RequestHandlerTask):
	url = r'/game/cross/craft/signup'

	@coroutine
	def run(self):
		if not ObjectCrossCraftGameGlobal.isOpen(self.game.role.areaKey):
			raise ClientError(ErrDefs.craftNoOpen)
		if not ObjectCrossCraftGameGlobal.isRoleOpen(self.game.role.level):
			raise ClientError(ErrDefs.craftNoOpen)

		if not ObjectCrossCraftGameGlobal.isCanSignUp(self.game):
			raise ClientError(ErrDefs.craftNoOpen)

		if not self.game.role.cross_craft_record_db_id:
			raise ClientError('can not signup')

		cards = self.input.get('cards', None)
		if cards:
			cards = transform2list(cards, least=12)
			if self.game.cards.isDuplicateMarkID(cards):
				raise ClientError('cards have duplicates')

			cardsLen = len(filter(None, cards))
			if cardsLen < 12:
				raise ClientError('cards not enough')

		ObjectCrossCraftGameGlobal.signUp(self.game, cards, manual=True)
		if cards:
			yield refreshCardsToPVP(self.rpcPVP, self.game, hold_cards=cards)

		view, model = yield getViewAndModel(self.rpcPVP, self.game)
		self.write({
			'view': view,
			'model': {
				'cross_craft': model,
			},
		})


# 主赛场，我的赛场
# 进入拳皇争霸功能一定要先请求该接口
class CrossCraftBattleMain(RequestHandlerTask):
	url = r'/game/cross/craft/battle/main'

	@coroutine
	def run(self):
		refresh_time = self.input.get('refresh_time', 0)

		if not ObjectCrossCraftGameGlobal.isRoleOpen(self.game.role.level):
			raise ClientError(ErrDefs.crossCraftLevelNotEough)

		role = self.game.role
		if len(role.top_cards) >= 12:
			# 新建CrossCraftRecord
			if role.cross_craft_record_db_id is None:
				cards = role.top_cards[:12]
				cardsD, cardsD2 = self.game.cards.makeBattleCardModel(cards, SceneDefs.CrossCraft)
				passiveSkills = self.game.cards.markBattlePassiveSkills(cards, SceneDefs.CrossCraft)
				embattle = {
					'cards': cards,
					'card_attrs': cardsD,
					'card_attrs2': cardsD2,
					'passive_skills': passiveSkills,
				}
				role.cross_craft_record_db_id = yield self.rpcPVP.call_async('CreateCrossCraftRecord', role.competitor, embattle)

				deployment = self.game.cards.deploymentForCrossCraft
				deployment.deploy('cards', cards)

			# 保存玩家最新卡牌数据
			# 现在策略是玩家必须要打开拳皇争霸界面才会刷新卡牌数据
			else:
				yield refreshCardsToPVP(self.rpcPVP, self.game)

		view, model = yield getViewAndModel(self.rpcPVP, self.game)
		self.write({
			'view': view,
			'model': {
				'cross_craft': model,
			},
		})


# 我的下注
class CrossCraftBetInfo(RequestHandlerTask):
	url = r'/game/cross/craft/bet/info'

	@coroutine
	def run(self):
		rpc = ObjectCrossCraftGameGlobal.cross_client(self.game.role.areaKey)
		if rpc:
			ret = yield rpc.call_async('CrossCraftGetBetInfo', self.game.role.id)
		else:
			ret = ObjectCrossCraftGameGlobal.getLastBetInfo(self.game.role.id, self.game.role.areaKey)
		self.write({
			'view': ret,
		})


# 下注
class CrossCraftBet(RequestHandlerTask):
	url = r'/game/cross/craft/bet'

	@coroutine
	def run(self):
		typ = self.input.get('type', None) # 1-预选押注 2-top4押注 3-冠军押注
		key = self.input.get('key', None)
		roleID = self.input.get('roleID', None)
		coin = self.input.get('coin', None)
		if not all([x is not None for x in [typ, key, roleID, coin]]):
			raise ClientError('param miss')
		if coin not in ('gold', 'coin8'):
			raise ClientError('coin error')
		areaKey = self.game.role.areaKey
		if not ObjectCrossCraftGameGlobal.isOpen(areaKey):
			raise ClientError(ErrDefs.craftNoOpen)
		if not ObjectCrossCraftGameGlobal.isRoleOpen(self.game.role.level):
			raise ClientError(ErrDefs.craftNoOpen)

		# 只能在报名期间下注
		if not ObjectCrossCraftGameGlobal.isCanBet(areaKey):
			raise ClientError(ErrDefs.craftCanNotBet)

		method = None
		# 第一天预选竞猜
		if ObjectCrossCraftGameGlobal.isInSign(areaKey):
			if typ == 1:
				method = 'CrossCraftBetPreRole'
				role = yield ObjectCacheGlobal.queryRole(roleID)
				roleID = { # 预选可以下注未报名的玩家，需要game传相应被下注方的数据
					'role_db_id': role['id'],
					'game_key': key,
					'name': role['name'],
					'logo': role['logo'],
					'frame': role['frame'],
					'level': role['level'],
					'figure': role['figure'],
					'title': role['title_id'],
					'vip': role['vip_level']
				}
		elif ObjectCrossCraftGameGlobal.isInHalftime(areaKey):
			# 第二天top4竞猜/冠军竞猜
			if typ == 2:
				method = 'CrossCraftBetTop4Role'
			elif typ == 3:
				method = 'CrossCraftBetChampion'
		else:
			raise ClientError('not in bet time')
		if not method:
			raise ClientError('type error')
		amount = ObjectCrossCraftGameGlobal.BetAmount[typ][coin]
		cost = ObjectCostAux(self.game, {coin: amount})
		if not cost.isEnough():
			raise ClientError(ErrDefs.costNotEnough)
		cost.cost(src='cross_craft_bet_%d' % typ)
		rpc = ObjectCrossCraftGameGlobal.cross_client(areaKey)
		ret = yield rpc.call_async(method, areaKey, self.game.role.id, roleID, coin, amount)
		self.write({
			'view': ret,
		})


# 获取对方参赛信息
class CrossCraftBattleEnemyGet(RequestHandlerTask):
	url = r'/game/cross/craft/battle/enemy/get'

	@coroutine
	def run(self):
		key = self.input.get('key', None)
		roleID = self.input.get('roleID', None)
		recordID = self.input.get('recordID', None)
		if key is None or roleID is None or recordID is None:
			raise ClientError('param miss')

		client = self.server.container.getserviceOrCreate(game2pvp(key))
		ret = yield client.call_async('GetCrossCraftRecord', recordID)
		ret.pop('hold_cards', None)
		ret.pop('hold_card_attrs', None)
		ret.pop('hold_passive_skills', None)
		ret.pop('passive_skills', None)

		view = ret if ret else {'online': False}
		view['game_key'] = key
		areaKey = self.game.role.areaKey
		client = ObjectCrossCraftGameGlobal.cross_client(areaKey)
		if client:
			lastTime = yield client.call_async('CrossCraftGetRoleLastTime', key, roleID)
		else:
			lastTime = 0
		if lastTime:
			# 10分钟离线
			view['online'] = (nowtime_t() - lastTime < 10 * 60)
		else:
			view['online'] = False

		if ObjectCrossCraftGameGlobal.inBattle(areaKey):
			_, model = yield getViewAndModel(self.rpcPVP, self.game)
		else:
			model = None

		self.write({
			'view': view,
			'model': {
				'cross_craft': model,
			}
		})


# 挑战部署
class CrossCraftBattleDeploy(RequestHandlerTask):
	url = r'/game/cross/craft/battle/deploy'

	@coroutine
	def run(self):
		cards = self.input.get('cards', None)
		if cards is None:
			raise ClientError('battleCardIDs is error')

		cards = transform2list(cards, least=12)
		cardsLen = len(filter(None, cards))
		if cardsLen < 12:
			raise ClientError('cards not enough')

		if not ObjectCrossCraftGameGlobal.isSigned(self.game):
			raise ClientError(ErrDefs.craftNoOpen)

		if ObjectCrossCraftGameGlobal.isInSign(self.game.role.areaKey):
			# 报名阶段才校验，战斗阶段craft service会进行校验
			if self.game.cards.isDuplicateMarkID(cards):
				raise ClientError('cards have duplicates')
			yield refreshCardsToPVP(self.rpcPVP, self.game, hold_cards=cards)
		else:
			ObjectCrossCraftGameGlobal.checkCanDeploy(self.game)
			yield refreshCardsToPVP(self.rpcPVP, self.game, cards=cards)

		_, model = yield getViewAndModel(self.rpcPVP, self.game)
		self.write({
			'model': {
				'cross_craft': model,
			},
		})

# 获取录像数据
class CrossCraftPlayRecordGet(RequestHandlerTask):
	url = r'/game/cross/craft/playrecord/get'

	@coroutine
	def run(self):
		recordID = self.input.get('recordID', None)
		crossKey = self.input.get('crossKey', None)
		if recordID is None or crossKey is None:
			raise ClientError('param miss')

		rpc = ObjectCrossCraftGameGlobal.cross_client(self.game.role.areaKey, cross_key=crossKey)
		if rpc is None:
			raise ClientError(ErrDefs.crossCraftPlayNotExisted)
		model = yield rpc.call_async('GetCrossCraftPlayRecord', recordID)
		if not model:
			raise ClientError(ErrDefs.crossCraftPlayNotExisted)
		self.write({'model': {'cross_craft_playrecords': {recordID: model}}})

# 商店兑换
class CrossCraftShopBuy(RequestHandlerTask):
	url = r'/game/cross/craft/shop/buy'

	@coroutine
	def run(self):
		if not ObjectCrossCraftGameGlobal.isRoleOpen(self.game.role.level):
			raise ClientError(ErrDefs.craftNoOpen)

		csvID = self.input.get('csvID', None)
		count = self.input.get('count', 1)
		if csvID is None:
			raise ClientError('param miss')
		if count <= 0:
			raise ClientError('param error')

		shop = ObjectCrossCraftShop(self.game)
		eff = shop.buyItem(csvID, count, src='cross_craft_shop_buy')
		yield effectAutoGain(eff, self.game, self.dbcGame, src='cross_craft_shop_buy')


# 获取排行榜
class CrossCraftRank(RequestHandlerTask):
	url = r'/game/cross/craft/rank'

	@coroutine
	def run(self):
		offest = self.input.get('offest', 0)
		size = self.input.get('size', 64)

		ret = ObjectCrossCraftGameGlobal.getRankList(offest, size, self.game.role.id, self.game.role.areaKey)
		# 本地rank数据失效，去cross取最新
		if ret is None:
			rpc = ObjectCrossCraftGameGlobal.cross_client(self.game.role.areaKey)
			ret = yield rpc.call_async('GetCrossCraftRank', offest, size, self.game.role.id)
		self.write({
			'view': {
				'rank': ret['ranks'],
				'myinfo': ret['myinfo'],
				'offest': offest,
				'size': size,
			}
		})

# 获取预选赛积分排行榜
class CrossCraftPrePointRank(RequestHandlerTask):
	url = r'/game/cross/craft/pre/point/rank'

	@coroutine
	def run(self):
		offest = self.input.get('offest', 0)
		size = self.input.get('size', 64)

		areaKey = self.game.role.areaKey
		ranks = ObjectCrossCraftGameGlobal.getLastPrePointRank(offest, size, areaKey)
		# 本地rank数据失效，去cross取最新
		if ranks is None:
			rpc = ObjectCrossCraftGameGlobal.cross_client(areaKey)
			ranks = yield rpc.call_async('CrossCraftGetPrePointRank', areaKey, offest, size)
		self.write({
			'view': {
				'rank': ranks,
				'offest': offest,
				'size': size,
			}
		})
