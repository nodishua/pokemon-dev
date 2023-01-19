#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2014 YouMi Information Technology Inc.

RandomTower Handlers
'''
import copy

from framework import nowtime_t
from framework.csv import ErrDefs, csv, ConstDefs
from framework.helper import transform2list
from framework.log import logger
from game import ClientError, ServerError
from game.globaldata import RandomTowerHuodongID, ShopRefreshItem
from game.handler import RequestHandlerTask
from game.handler.inl import effectAutoGain
from game.object import RandomTowerDefs, TargetDefs, FeatureDefs, AchievementDefs, PlayPassportDefs
from game.object.game import ObjectFeatureUnlockCSV
from game.object.game.randomTower import ObjectRandomTower
from game.object.game.costcsv import ObjectCostCSV
from game.object.game.battle import ObjectRandomTowerBattle
from game.object.game.gain import ObjectCostAux, ObjectGainAux
from game.object.game.rank import ObjectRankGlobal
from game.object.game.shop import ObjectRandomTowerShop
from game.object.game.yyhuodong import ObjectYYHuoDongFactory
from game.thinkingdata import ta

from tornado.gen import coroutine, Return


# 每次进入都调用
class RandomTowerPrepare(RequestHandlerTask):
	url = r'/game/random_tower/prepare'

	@coroutine
	def run(self):
		role = self.game.role
		if role.random_tower_db_id is None:
			recordData = yield self.dbcGame.call_async('DBCreate', 'RandomTower', {
				'role_db_id': role.id,
			})
			if not recordData['ret']:
				raise ServerError('db create randomTower record error')
			self.game.role.random_tower_db_id = recordData['model']['id']
			self.game.randomTower.set(recordData['model']).init()

		randomTower = self.game.randomTower
		# 若有更新 则需重新设置房间卡面
		if randomTower.refresh():
			# 排行榜
			yield ObjectRankGlobal.onKeyInfoChange(self.game, 'random_tower')

		self.write({
			'view': {
				# 检测奖励是否更新
				'point_award_update': self.game.randomTower.checkPointAwardVersion()
			}
		})


# 选择卡面 （打怪不发这个）
class RandomTowerBoard(RequestHandlerTask):
	url = r'/game/random_tower/board'

	@coroutine
	def run(self):
		if self.game.role.random_tower_db_id is None:
			raise ClientError('randomTower need prepare')
		boardID = self.input.get('boardID', None)

		randomTower = self.game.randomTower
		if randomTower.room_info.get('board_id', None) and randomTower.room_info.get('board_id', None) != boardID:
			raise ClientError('param boardID error1')
		if boardID:
			# 判断选择卡面对不对（符合线路）
			if not randomTower.isRightChoose(boardID):
				raise ClientError('param boardID error3')
			# 设置下一个房间的选择范围
			if not randomTower.room_info.get('board_id', None):
				randomTower.room_info.setdefault('board_id', boardID)
				randomTower.setNextRoomScope()
			cfg = csv.random_tower.board[boardID]
			# 宝箱
			# 随机事件
			if cfg.type == RandomTowerDefs.EventType:
				events = randomTower.room_info.get('event', None)
				eventCsvID = events.get(boardID, 0)
				cfgEvent = csv.random_tower.event[eventCsvID]
				randomTower.event_time[eventCsvID] = randomTower.event_time.get(eventCsvID, 0) + 1
				# 如果事件只有一个就直接进入下一房间
				if not cfgEvent.choice1:
					# 获得结果
					effAward, buffList, points = randomTower.getEventAward(cfgEvent)
					# buff 添加
					for buffCsvID in buffList:
						cfgBuff = csv.random_tower.buffs[buffCsvID]
						if cfgBuff.buffType != RandomTowerDefs.BuffSupply:
							randomTower.addBuffs(buffCsvID)
						else:  # 补给（扣血 扣怒）
							randomTower.buffSupply(buffCsvID)
					randomTower.nextRoom()
					ret = {}
					if effAward:
						yield effectAutoGain(effAward, self.game, self.dbcGame, src='random_tower_event_award')
						ret['items'] = effAward.result
					if points:
						randomTower.day_point += int(points)
						ret['points'] = points
					yield ObjectRankGlobal.onKeyInfoChange(self.game, 'random_tower')
					if ret:
						self.write({
							'view': ret,
						})
			# buff
			elif cfg.type == RandomTowerDefs.BuffType:
				buffs = randomTower.room_info.get('buff', None)
				buffCsvID = buffs.get(boardID, 0)
				cfgBuff = csv.random_tower.buffs[buffCsvID]
				# 记录 buff
				randomTower.buff_time[buffCsvID] = randomTower.buff_time.get(buffCsvID, 0) + 1
				if cfgBuff['changeLib'] != 0:
					randomTower.buff_lib.append(cfgBuff['changeLib'])
				# 非补给的buff 都进入下个房间
				if cfgBuff.buffType != RandomTowerDefs.BuffSupply:
					randomTower.addBuffs(buffCsvID)
					randomTower.nextRoom()
					yield ObjectRankGlobal.onKeyInfoChange(self.game, 'random_tower')
			# 打怪 就别发了（发了我给你报错）
			elif cfg.type == RandomTowerDefs.MonsterType:
				raise ClientError('monsterType request error')
		# 每层初始房间（开门）
		else:
			# 如果当前房间有面板 不能是开门
			if randomTower.boards.get(randomTower.room, []):
				raise ClientError('param no boardID')
			randomTower.setNextRoomScope()
			randomTower.nextRoom()
			yield ObjectRankGlobal.onKeyInfoChange(self.game, 'random_tower')
		ta.track(self.game, event='random_tower',room=randomTower.room,history_point=randomTower.history_point)


# 开始试炼
class RandomTowerStart(RequestHandlerTask):
	url = r'/game/random_tower/start'

	@coroutine
	def run(self):
		if self.game.role.random_tower_db_id is None:
			raise ClientError('randomTower need prepare')
		battleCardIDs = self.input.get('battleCardIDs', None)
		boardID = self.input.get('boardID', None)

		randomTower = self.game.randomTower
		if boardID is None:
			raise ClientError('param is miss')
		if randomTower.room_info.get('board_id', None) and randomTower.room_info.get('board_id', None) != boardID:
			raise ClientError('param boardID error1')
		if csv.random_tower.board[boardID].type != RandomTowerDefs.MonsterType:
			raise ClientError('param boardID error2')
		# 判断选择卡面对不对（符合线路）
		if not randomTower.isRightChoose(boardID):
			raise ClientError('param boardID error3')

		# 如果客户端发的阵容不为空，判断是否有死卡
		if battleCardIDs:
			battleCardIDs = transform2list(battleCardIDs)
			for cardID in battleCardIDs:
				hp, mp = randomTower.card_states.get(cardID, (1, 1))
				if hp <= 0:
					raise ClientError('battleCards have dead card')

		if not battleCardIDs:
			battleCardIDs = self.game.role.huodong_cards.get(RandomTowerHuodongID, copy.deepcopy(self.game.role.battle_cards))

		# 上阵卡牌不能低于10级
		cardIDs = []
		for cardID in battleCardIDs:
			if cardID:
				card = self.game.cards.getCard(cardID)
				if card:
					if card.level < 10:
						cardIDs.append(None)
						continue
			cardIDs.append(cardID)

		# 保存阵容
		self.game.role.deployHuodongCards(RandomTowerHuodongID, cardIDs)

		# 设置下一个房间的选择范围
		if not randomTower.room_info.get('board_id', None):
			randomTower.room_info.setdefault('board_id', boardID)
			randomTower.setNextRoomScope()

		self.game.battle = ObjectRandomTowerBattle(self.game)
		ret = self.game.battle.begin(boardID, cardIDs)
		self.write({
			'model': ret
		})


# 结束试炼
class RandomTowerEnd(RequestHandlerTask):
	url = r'/game/random_tower/end'

	@coroutine
	def run(self):
		if self.game.role.random_tower_db_id is None:
			raise ClientError('randomTower need prepare')
		battleID = self.input.get('battleID', None)
		result = self.input.get('result', None)
		star = self.input.get('star', None)
		cardStates = self.input.get('cardStates', None)
		enemyStates = self.input.get('enemyStates', None)
		battleRound = self.input.get('battleRound', None)

		if any([x is None for x in [result, star, cardStates, enemyStates, battleRound]]):
			raise ClientError('param miss')
		if battleID != self.game.battle.id:
			raise ClientError('battleID error')

		# 跨日战斗，直接无效
		randomTower = self.game.randomTower
		if randomTower.refresh():
			ret = {'view': {}}
			self.write(ret)
		else:
			enStates = {}
			if isinstance(enemyStates, list):
				for i, v in enumerate(enemyStates):
					enStates[i+1] = v
			else:
				enStates = enemyStates
			# 战斗结算
			self.game.battle.result(result, star, cardStates, enStates, battleRound)
			# 战斗结算完毕
			ret = self.game.battle.end()
			if result == 'win':
				# 进入下一个房间
				randomTower.nextRoom()
				yield ObjectRankGlobal.onKeyInfoChange(self.game, 'random_tower')
			self.game.battle = None

			self.write(ret)


# 战斗碾压（战斗跳过）
class RandomTowerPass(RequestHandlerTask):
	url = r'/game/random_tower/pass'

	@coroutine
	def run(self):
		if self.game.role.random_tower_db_id is None:
			raise ClientError('randomTower need prepare')
		boardID = self.input.get('boardID', None)

		randomTower = self.game.randomTower
		if boardID is None:
			raise ClientError('param is miss')
		if csv.random_tower.board[boardID].type != RandomTowerDefs.MonsterType:
			raise ClientError('param boardID error2')
		# 判断选择卡面对不对（符合线路）
		if not randomTower.isRightChoose(boardID):
			raise ClientError('param boardID error3')
		# 判断是否可以碾压
		if not randomTower.isCanPass():
			raise ClientError('this room can not pass')

		# 战力前10 获得200怒气
		randomTower.passResumeMp(1)
		# 计算积分
		cfgBoard = csv.random_tower.board[boardID]
		cfgTower = csv.random_tower.tower[cfgBoard.room]
		# 积分获得 = 等级基础积分（initPoint)*怪物积分修正系数（pointC）*战斗星级表现系数（starRate）*Vip加成（vipRate）+buff积分加成（addPoint）
		initPoint = csv.random_tower.point[self.game.role.level]['initPoint']
		pointC1 = cfgTower['pointC'][cfgBoard.monsterType - 1]
		pointC2 = cfgBoard['pointC']
		starRate = RandomTowerDefs.StarRate.get(3)
		vipRate = self.game.role.randomTowerPointRate
		addPoint = randomTower.getBuffPointAdd(1, 6)  # 积分加成 默认一回合，存活6个精灵
		point = int(initPoint * pointC1 * pointC2 * starRate * vipRate + addPoint)
		# 每日积分增加
		randomTower.day_point += point

		# 设置下一个房间的选择范围
		randomTower.room_info.setdefault('board_id', boardID)
		randomTower.setNextRoomScope()
		randomTower.nextRoom()
		yield ObjectRankGlobal.onKeyInfoChange(self.game, 'random_tower')
		ObjectYYHuoDongFactory.onGeneralTask(self.game, TargetDefs.RandomTowerBattleWin, 1)
		ret = {
			'view': {
				'point': point,
			}
		}
		self.write(ret)


# 手动跳下一房间（只有 宝箱用）
class RandomTowerNext(RequestHandlerTask):
	url = r'/game/random_tower/next'

	@coroutine
	def run(self):
		if self.game.role.random_tower_db_id is None:
			raise ClientError('randomTower need prepare')
		randomTower = self.game.randomTower
		randomTower.nextRoom()
		yield ObjectRankGlobal.onKeyInfoChange(self.game, 'random_tower')


# 开启宝箱（前需调过board 请求）
class RandomTowerBoxOpen(RequestHandlerTask):
	url = r'/game/random_tower/box/open'

	@coroutine
	def run(self):
		if self.game.role.random_tower_db_id is None:
			raise ClientError('randomTower need prepare')
		randomTower = self.game.randomTower
		boardID = randomTower.room_info.get('board_id', None)
		if not boardID:
			raise ClientError('boardID no choose')
		if csv.random_tower.board[boardID].type != RandomTowerDefs.BoxType:
			raise ClientError('request error')

		cfg = csv.random_tower.board[boardID]
		# 宝箱
		eff = randomTower.getBoxAwards(boardID)
		if cfg.boxType == RandomTowerDefs.CommonType:
			times = ConstDefs.randomTowerBoxLimit1
		else:
			times = ConstDefs.randomTowerBoxLimit2
		ret = None
		# 再开次数满了 自动下一个房间
		if randomTower.room_info.get('count', 0) - 1 >= times:
			randomTower.nextRoom()
			yield ObjectRankGlobal.onKeyInfoChange(self.game, 'random_tower')
		if eff:
			yield effectAutoGain(eff, self.game, self.dbcGame, src='random_tower_box_award')
			ret = eff.result
		ObjectYYHuoDongFactory.onGeneralTask(self.game, TargetDefs.RandomTowerBoxOpen, 1)
		self.write({
			'view': ret,
		})


# buff 补给使用（前需调过board 请求）cards 只有可选择时发, 并兼容单个cardID或数组
class RandomTowerBuffUsed(RequestHandlerTask):
	url = r'/game/random_tower/buff/used'

	@coroutine
	def run(self):
		if self.game.role.random_tower_db_id is None:
			raise ClientError('randomTower need prepare')
		cards = self.input.get('cards', None)

		randomTower = self.game.randomTower
		boardID = randomTower.room_info.get('board_id', None)
		if not boardID:
			raise ClientError('boardID no choose')
		if csv.random_tower.board[boardID].type != RandomTowerDefs.BuffType:
			raise ClientError('request error')

		buffs = randomTower.room_info.get('buff', {})
		buffID = buffs.get(boardID, 0)

		# 没有 10级以上卡牌 就 不补给
		have10LevelCard = False
		for card in self.game.cards.getCards(self.game.role.cards):
			if card.level >= 10:
				have10LevelCard = True
				break

		# 满足前置条件 则补给
		if have10LevelCard and randomTower.isBuffCondition(buffID):
			randomTower.buffSupply(buffID, cards)
		randomTower.nextRoom()
		yield ObjectRankGlobal.onKeyInfoChange(self.game, 'random_tower')


# 随机事件结果选择（若 只有一个选择则不请求）（前需调过board 请求）
class RandomTowerEventChoose(RequestHandlerTask):
	url = r'/game/random_tower/event/choose'

	@coroutine
	def run(self):
		if self.game.role.random_tower_db_id is None:
			raise ClientError('randomTower need prepare')
		choice = self.input.get('choice', None)
		if choice is None:
			raise ClientError('param is miss')

		randomTower = self.game.randomTower
		boardID = randomTower.room_info.get('board_id', None)
		if not boardID:
			raise ClientError('boardID no choose')
		if csv.random_tower.board[boardID].type != RandomTowerDefs.EventType:
			raise ClientError('request error')
		events = randomTower.room_info.get('event', None)
		cfgEvent = csv.random_tower.event[events.get(boardID, 0)]
		# 如果事件不是多选
		if not cfgEvent.choice1:
			raise ClientError('event choose only one')

		# 进入下个房间
		randomTower.nextRoom()
		# 获得结果
		effAward, buffList, points = randomTower.getEventAward(cfgEvent, choice)
		# buff 添加
		for buffCsvID in buffList:
			cfgBuff = csv.random_tower.buffs[buffCsvID]
			if cfgBuff.buffType != RandomTowerDefs.BuffSupply:
				randomTower.addBuffs(buffCsvID)
			else:  # 补给（扣血 扣怒）
				randomTower.buffSupply(buffCsvID)
		ret = {}
		if effAward:
			yield effectAutoGain(effAward, self.game, self.dbcGame, src='random_tower_event_award')
			ret['items'] = effAward.result
		if points:
			randomTower.day_point += int(points)
			ret['points'] = points
		yield ObjectRankGlobal.onKeyInfoChange(self.game, 'random_tower')
		if ret:
			self.write({
				'view': ret,
			})


# 试炼商店获得
class RandomTowerShopGet(RequestHandlerTask):
	url = r'/game/random_tower/shop/get'

	@coroutine
	def run(self):
		yield getRandomShopModel(self.game, self.dbcGame)


# 试炼商店刷新
class RandomTowerShopRefresh(RequestHandlerTask):
	url = r'/game/random_tower/shop/refresh'

	@coroutine
	def run(self):
		if not self.game.role.random_tower_shop_db_id:
			raise ClientError(ErrDefs.shopNotExisted)
		# 是否代金券刷新 钻石刷新可不传
		itemRefresh = self.input.get('itemRefresh', None)
		if not itemRefresh:
			refreshTimes = self.game.dailyRecord.randomTower_shop_refresh_times
			if refreshTimes >= self.game.role.shopRefreshLimit:
				raise ClientError(ErrDefs.shopRefreshUp)
			costRMB = ObjectCostCSV.getRandomTowerShopRefreshCost(refreshTimes)
			cost = ObjectCostAux(self.game, {'rmb': costRMB})
			if not cost.isEnough():
				raise ClientError("cost rmb not enough")
			self.game.dailyRecord.randomTower_shop_refresh_times = refreshTimes + 1
		else:
			cost = ObjectCostAux(self.game, {ShopRefreshItem: 1})
			if not cost.isEnough():
				raise ClientError("cost item not enough")
		cost.cost(src='randomTower_shop_refresh')
		yield getRandomShopModel(self.game, self.dbcGame, True)
		self.game.achievement.onCount(AchievementDefs.ShopRefresh, 1)

# 试炼商店购买
class RandomTowerShopBuy(RequestHandlerTask):
	url = r'/game/random_tower/shop/buy'

	@coroutine
	def run(self):
		idx = self.input.get('idx', None)
		shopID = self.input.get('shopID', None)
		itemID = self.input.get('itemID', None)
		count = self.input.get('count', 1)  # 只增对限购类型生效
		if not all([x is not None for x in [idx, shopID, itemID]]):
			raise ClientError('param miss')
		if count <= 0:
			raise ClientError('param error')
		if not self.game.role.random_tower_shop_db_id:
			raise ClientError(ErrDefs.shopNotExisted)
		# 商店过期了
		oldID = self.game.randomTowerShop.id
		randomTowerShop = yield getRandomShopModel(self.game, self.dbcGame)
		if oldID != randomTowerShop.id:
			raise ClientError(ErrDefs.shopRefresh)
		eff = self.game.randomTowerShop.buyItem(idx, shopID, itemID, count, src='randomTower_shop_buy')
		yield effectAutoGain(eff, self.game, self.dbcGame, src='randomTower_shop_buy')


@coroutine
def getRandomShopModel(game, dbc, refresh=False):
	if game.role.random_tower_shop_db_id:
		# 强制刷新 或 过期
		if refresh or game.randomTowerShop.isPast():
			game.role.random_tower_shop_db_id = None
			ObjectRandomTowerShop.addFreeObject(game.randomTowerShop)
			game.randomTowerShop = ObjectRandomTowerShop(game, dbc)
	# 重新生成商店
	if not game.role.random_tower_shop_db_id:
		last_time = nowtime_t()
		roleID = game.role.id
		items = ObjectRandomTowerShop.makeShopItems(game)
		model = ObjectRandomTowerShop.getFreeModel(roleID, items, last_time)  # 回收站中取
		fromDB = False
		if model is None:
			ret = yield dbc.call_async('DBCreate', 'RandomTowerShop', {
				'role_db_id': roleID,
				'items': items,
				'last_time': last_time,
			})
			model = ret['model']
			fromDB = True
		game.role.random_tower_shop_db_id = model['id']
		game.randomTowerShop = ObjectRandomTowerShop(game, dbc).dbset(model, fromDB).init()

	raise Return(game.randomTowerShop)


# 领取积分奖励
class RandomTowerPointAward(RequestHandlerTask):
	url = r'/game/random_tower/point/award'

	@coroutine
	def run(self):
		csvID = self.input.get('csvID', None)

		if csvID is None:
			raise ClientError('csvID miss')
		randomTower = self.game.randomTower

		if randomTower.point_award_version != randomTower.PointAwardVersion:
			raise ClientError(ErrDefs.randomTowerPointAwardVersionChange)

		retEff = ObjectGainAux(self.game, {})
		if csvID == -1:  # 一键领取
			for csvID, flag in randomTower.point_award.iteritems():
				if flag == 1:
					cfg = csv.random_tower.point_award[csvID]
					eff = ObjectGainAux(self.game, cfg.award)
					retEff += eff
					randomTower.point_award[csvID] = 0
		else:
			if csvID not in csv.random_tower.point_award:
				raise ClientError('csvID err')
			flag = randomTower.point_award.get(csvID, -1)
			if flag == -1:
				raise ClientError("no award")
			if flag == 0:
				raise ClientError("do not get award again")

			cfg = csv.random_tower.point_award[csvID]
			retEff = ObjectGainAux(self.game, cfg.award)
			randomTower.point_award[csvID] = 0
		ret = {}
		if retEff:
			yield effectAutoGain(retEff, self.game, self.dbcGame, src='randomTower_point_award')
			ret = retEff.result

		self.write({
			'view': ret,
		})


# 跳过  下一步（包含开始）
class RandomTowerJumpNext(RequestHandlerTask):
	url = r'/game/random_tower/jump/next'

	@coroutine
	def run(self):
		if self.game.role.random_tower_db_id is None:
			raise ClientError('randomTower need prepare')
		if not ObjectFeatureUnlockCSV.isOpen(FeatureDefs.RandomTowerJump, self.game):
			raise ClientError(ErrDefs.randomTowerJumpNotOpen)
		randomTower = self.game.randomTower
		# 开始 进入直通
		if randomTower.jump_step == RandomTowerDefs.JumpBegin:
			result = randomTower.beginJumpRoom()
			eff = result.get('award', ObjectGainAux(self.game, {}))
			if eff:
				yield effectAutoGain(eff, self.game, self.dbcGame, src='random_tower_box_award')
			result['award'] = eff.result
			ret = {
				'view': result
			}
			randomTower.jump_step = RandomTowerDefs.JumpPoint
			self.write(ret)
		# 进入豪华宝箱
		elif randomTower.jump_step == RandomTowerDefs.JumpPoint:
			randomTower.jump_step = RandomTowerDefs.JumpBox
		# 进入加成
		elif randomTower.jump_step == RandomTowerDefs.JumpBox:
			randomTower.doJumpInfoBuffs(0)
			randomTower.jump_info['buff_index'] = 1  # buff索引从1开始
			randomTower.jump_step = RandomTowerDefs.JumpBuff
		# 进入事件
		elif randomTower.jump_step == RandomTowerDefs.JumpBuff:
			randomTower.nextRandomJumpBuffs()  # 随机获得剩下buffs
			randomTower.jump_step = RandomTowerDefs.JumpEvent
		# 结束
		elif randomTower.jump_step == RandomTowerDefs.JumpEvent:
			randomTower.jump_step = RandomTowerDefs.JumpEnd
			randomTower.jump_info = {}
			randomTower.boards = {}
			randomTower.room = randomTower.getJumpRoomNum()
			passfloor = csv.random_tower.tower[randomTower.room].floor - 1
			# 初始化前三房间
			for i in xrange(randomTower.room, randomTower.room + 3, 1):
				if i <= ObjectRandomTower.MaxRoom:
					randomTower.setRoomBoards(i)
			ObjectYYHuoDongFactory.onGeneralTask(self.game, TargetDefs.RandomTowerFloorTimes, passfloor)
			ObjectYYHuoDongFactory.onGeneralTask(self.game, TargetDefs.RandomTowerFloorMax, passfloor)
			ObjectYYHuoDongFactory.onGeneralTask(self.game, TargetDefs.RandomTowerFloorSum, passfloor)
			ObjectYYHuoDongFactory.onTaskChange(self.game, PlayPassportDefs.RandomTower, passfloor)
			randomTower.nextRoom()
			yield ObjectRankGlobal.onKeyInfoChange(self.game, 'random_tower')


# 跳过  打开豪华宝箱
class RandomTowerJumpBoxOpen(RequestHandlerTask):
	url = r'/game/random_tower/jump/box_open'

	@coroutine
	def run(self):
		if self.game.role.random_tower_db_id is None:
			raise ClientError('randomTower need prepare')
		if not ObjectFeatureUnlockCSV.isOpen(FeatureDefs.RandomTowerJump, self.game):
			raise ClientError(ErrDefs.randomTowerJumpNotOpen)
		boardID = self.input.get('boardID', None)  # 全开传 0
		openType = self.input.get('openType', None)  # "open1" "open5"
		if not all([x is not None for x in [boardID, openType]]):
			raise ClientError('param miss')
		randomTower = self.game.randomTower
		if randomTower.jump_step != RandomTowerDefs.JumpBox:
			raise ClientError('request error')
		boxes = randomTower.jump_info.get('boxes', {})
		effAll = ObjectGainAux(self.game, {})
		costAll = ObjectCostAux(self.game, {})
		times = ConstDefs.randomTowerBoxLimit2
		opens = {}
		# 指定宝箱
		if boardID:
			cfg = csv.random_tower.board[boardID]
			# 非豪华宝箱
			if cfg.type != RandomTowerDefs.BoxType or cfg.boxType != RandomTowerDefs.SpecialType:
				raise ClientError('boardID is not special box')

			count = boxes.get(boardID, 0)
			if count >= times:
				raise ClientError('count run out')
			# 可以打开的次数
			openCount = times - count
			if openType == RandomTowerDefs.BoxOpen1:
				openCount = 1
			costAll, effAll = randomTower.openJumpSpecialBox(boardID, openCount)
			opens[boardID] = openCount
		# 全开
		else:
			for bID, count in boxes.iteritems():
				if count >= times:
					continue
				openCount = times - count
				if openType == RandomTowerDefs.BoxOpen1:
					openCount = 1
				cost, eff = randomTower.openJumpSpecialBox(bID, openCount)
				costAll += cost
				effAll += eff
				opens[bID] = openCount
		if not costAll.isEnough():
			raise ClientError('cost rmb no enough')
		openCountAll = 0
		# 加次数
		for bID, openCount in opens.iteritems():
			boxes = randomTower.jump_info.get('boxes', {})
			count = boxes.get(bID, 0)
			randomTower.jump_info['boxes'][bID] = count + openCount
			openCountAll += openCount
		if not boardID:
			boardID = "all"
		costAll.cost(src='randomTower_boxAward_%s_%s' %(openType, boardID))
		ObjectYYHuoDongFactory.onGeneralTask(self.game, TargetDefs.RandomTowerBoxOpen, openCountAll)
		ret = {}
		if effAll:
			yield effectAutoGain(effAll, self.game, self.dbcGame, src='randomTower_boxAward_%s_%s' %(openType, boardID))
			ret = effAll.result
		self.write({
			'view': ret,
		})


# 跳过  选择buff
class RandomTowerJumpBuff(RequestHandlerTask):
	url = r'/game/random_tower/jump/buff'

	@coroutine
	def run(self):
		if self.game.role.random_tower_db_id is None:
			raise ClientError('randomTower need prepare')
		if not ObjectFeatureUnlockCSV.isOpen(FeatureDefs.RandomTowerJump, self.game):
			raise ClientError(ErrDefs.randomTowerJumpNotOpen)
		boardID = self.input.get('boardID', None)  # 随机传 0
		if boardID is None:
			raise ClientError('param miss')
		randomTower = self.game.randomTower
		if randomTower.jump_step != RandomTowerDefs.JumpBuff:
			raise ClientError('request error')
		buffIndex = randomTower.jump_info.get('buff_index', 1)
		if not boardID:
			boardID = randomTower.randomJumpBuffs(buffIndex)
		buffs = randomTower.jump_info.get('buffs', [])
		buffMap = buffs[buffIndex - 1]
		buffCsvID = buffMap.get(boardID, 0)
		if not buffCsvID:
			raise ClientError('jump buff param boardID error')
		randomTower.setJumpBuff(buffCsvID)
		# 选完了 自动下一步
		if buffIndex >= len(buffs):
			randomTower.jump_step = RandomTowerDefs.JumpEvent
		else:
			randomTower.doJumpInfoBuffs(buffIndex)
			randomTower.jump_info['buff_index'] = buffIndex + 1


# 跳过  选择事件
class RandomTowerJumpEvent(RequestHandlerTask):
	url = r'/game/random_tower/jump/event'

	@coroutine
	def run(self):
		if self.game.role.random_tower_db_id is None:
			raise ClientError('randomTower need prepare')
		if not ObjectFeatureUnlockCSV.isOpen(FeatureDefs.RandomTowerJump, self.game):
			raise ClientError(ErrDefs.randomTowerJumpNotOpen)
		boardID = self.input.get('boardID', None)
		choice = self.input.get('choice', None)
		if not all([x is not None for x in [boardID, choice]]):
			raise ClientError('param miss')
		randomTower = self.game.randomTower
		if randomTower.jump_step != RandomTowerDefs.JumpEvent:
			raise ClientError('request error')
		if boardID not in randomTower.jump_info['events']:
			raise ClientError('jump event param boardID error')
		if csv.random_tower.board[boardID].type != RandomTowerDefs.EventType:
			raise ClientError('boardID is not event type')

		eventCsvID, flag = randomTower.jump_info['events'].get(boardID)
		# 标志为已打开
		if flag:
			raise ClientError('do not choose again')
		cfgEvent = csv.random_tower.event[eventCsvID]
		# 如果事件不是多选
		if not cfgEvent.choice1:
			raise ClientError('event choose only one')
		randomTower.event_time[eventCsvID] = randomTower.event_time.get(eventCsvID, 0) + 1
		# 获得结果
		effAward, buffList, points = randomTower.getEventAward(cfgEvent, choice)
		# 标志为已打开
		randomTower.jump_info['events'][boardID] = (eventCsvID, 1)
		# buff 添加
		for buffCsvID in buffList:
			cfgBuff = csv.random_tower.buffs[buffCsvID]
			if cfgBuff.buffType != RandomTowerDefs.BuffSupply:
				randomTower.addBuffs(buffCsvID)
			else:  # 补给（扣血 扣怒）
				randomTower.buffSupply(buffCsvID)
		ret = {}
		if effAward:
			yield effectAutoGain(effAward, self.game, self.dbcGame, src='randomTower_eventAward_jump')
			ret['items'] = effAward.result
		if points:
			randomTower.day_point += int(points)
			ret['points'] = points
		if ret:
			self.write({
				'view': ret,
			})


