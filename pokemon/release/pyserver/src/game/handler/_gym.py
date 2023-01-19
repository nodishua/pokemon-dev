#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2014 YouMi Information Technology Inc.

GYM Handlers
'''
from framework import nowtime_t, todayinclock5date2int
from framework.csv import ErrDefs, csv, ConstDefs
from framework.log import logger
from framework.service.helper import game2pvp
from game import ClientError, ServerError
from game.handler import RequestHandlerTask
from game.handler.inl import effectAutoGain
from game.object import SceneDefs, FeatureDefs, MessageDefs, MapDefs, PlayPassportDefs
from game.object.game import ObjectCostCSV, ObjectMessageGlobal, ObjectUnion, ObjectYYHuoDongFactory
from game.object.game.battle import ObjectGymBattle, ObjectGymPass
from game.object.game.gym import ObjectGymGameGlobal
from game.object.game.levelcsv import ObjectFeatureUnlockCSV
from game.object.game.gain import ObjectCostAux, ObjectGainAux
from msgpackrpc.error import CallError
from tornado.gen import coroutine, Return


@coroutine
def makeGymModel(game, rpc, rpcGym):
	role = game.role
	if not role.gym_record_db_id:
		raise Return({'gym': {}, })

	# {leader_roles; cross_gym_roles; record; gym_game_data}
	model = {}
	# record
	record = yield rpcGym.call_async('GetGymRecord', role.gym_record_db_id)
	model['record'] = record
	# leader_roles
	if ObjectGymGameGlobal.isOpen(role.areaKey):
		cardAttrs = model['record']['card_attrs']
		gymRoleInfo = ObjectGymGameGlobal.markGymRoleInfo(game.role, cardAttrs)
		gymLeaderRoles = yield rpcGym.call_async('GetGymLeaderRoles', gymRoleInfo)
		model['leaderRoles'] = gymLeaderRoles
	# cross_gym_roles
	if ObjectGymGameGlobal.isCrossOpen(role.areaKey):
		crossCardAttrs = model['record']['cross_card_attrs']
		crossGymRoleInfo = ObjectGymGameGlobal.markGymRoleInfo(game.role, crossCardAttrs)
		crossGymModel = yield rpc.call_async('GetCrossGymModel', crossGymRoleInfo)
		model['crossGymRoles'] = crossGymModel
	# gym_game_data
	model.update(ObjectGymGameGlobal.Singleton.getGymGameModel(role.areaKey))
	raise Return({
		'gym': model,
	})


@coroutine
def refreshToGym(rpcGym, game, cards=None, cross_cards=None, force=False):
	if not game.role.gym_record_db_id:
		raise Return(None)
	deployment = game.cards.deploymentForGym
	# 没发生改变
	if not any([force, cards, cross_cards, deployment.isdirty()]):
		raise Return(None)
	battle = {}
	# 荣誉馆主
	battle.update(ObjectGymGameGlobal.gymLeaderBattleCards(game, cards))
	# 跨服馆员
	battle.update(ObjectGymGameGlobal.gymCrossBattleCards(game, cross_cards))

	deployment.resetdirty()
	yield rpcGym.call_async('GymRefreshRecord', game.role.gym_record_db_id, game.role.competitor, battle)


# 主界面main请求 （同步model客户端)
class GymBattleMain(RequestHandlerTask):
	url = r'/game/gym/main'

	@coroutine
	def run(self):
		if not ObjectGymGameGlobal.isRoleOpen(self.game.role.level):
			raise ClientError(ErrDefs.levelLessNoOpened)

		role = self.game.role
		# 新建GymRecord
		if role.gym_record_db_id is None:
			role.gym_record_db_id = yield self.rpcGym.call_async('CreateGymRecord', role.competitor)
		else:
			yield refreshToGym(self.rpcGym, self.game)
		# 重置role数据
		isReset = ObjectGymGameGlobal.resetGymDatas(self.game)
		deployment = self.game.cards.deploymentForGym
		if isReset:
			# 新赛季 阵容重置
			yield self.rpcGym.call_async('GymReset', role.gym_record_db_id)
			if deployment.cards:
				deployment.resetCards()
				deployment.resetdirty()

		# 自动恢复天赋点
		eff = ObjectGymGameGlobal.refreshGymTalentPoint(self.game, role)
		if eff:
			yield effectAutoGain(eff, self.game, self.dbcGame, src="gym_talent_auto_recover")

		rpc = ObjectGymGameGlobal.cross_client(role.areaKey)
		model = yield makeGymModel(self.game, rpc, self.rpcGym)

		# 判断是否还是馆主/馆员，不是了就下阵。
		gymModel = model['gym']
		clearCardsKey = []
		if ObjectGymGameGlobal.isOpen(role.areaKey) and deployment.isExist('cards'):
			exist = False
			for gymID, roleInfo in gymModel['leaderRoles'].iteritems():
				if roleInfo['role_id'] == role.id:
					exist = True
			if not exist:
				deployment.popCardsByKey('cards')
				clearCardsKey.append('cards')
		if ObjectGymGameGlobal.isCrossOpen(role.areaKey) and deployment.isExist('cross_cards'):
			exist = False
			for gymID, roles in gymModel['crossGymRoles'].iteritems():
				for pos, roleInfo in roles.iteritems():
					if roleInfo['role_id'] == role.id:
						exist = True
			if not exist:
				deployment.popCardsByKey('cross_cards')
				clearCardsKey.append('cross_cards')
		if clearCardsKey:
			yield self.rpcGym.call_async('GymClearCards', role.gym_record_db_id, clearCardsKey)

		self.write({'model': model})


# 荣誉馆主 开始战斗
class GymLeaderBattleStart(RequestHandlerTask):
	url = r'/game/gym/leader/battle/start'

	@coroutine
	def run(self):
		role = self.game.role
		if role.gym_record_db_id is None:
			raise ClientError('gym not opened')
		# 只有赛季中才可战斗
		if not ObjectGymGameGlobal.isOpen(role.areaKey):
			raise ClientError(ErrDefs.gymNotStart)

		cards = self.input.get('cards', None)
		gymID = self.input.get('gymID', None)
		enemyRecordID = self.input.get('enemyRecordID', None)

		if not all([x is not None for x in [gymID, cards, enemyRecordID]]):
			raise ClientError('param miss')
		if role.gym_record_db_id == enemyRecordID:
			raise ClientError('battle enemy is self')

		cards = ObjectGymGameGlobal.battleInputOK(self.game, cards, gymID)

		# 冷却时间
		gymPwLastTime = role.gym_datas.get('gym_pw_last_time', 0.0)
		delta = nowtime_t() - gymPwLastTime
		ObjectGymGameGlobal.battleCanBegin(self.game, cards, gymID, delta)

		myBattle = ObjectGymGameGlobal.gymLeaderBattleCards(self.game, cards)
		rpc = ObjectGymGameGlobal.cross_client(role.areaKey)
		try:
			model = yield self.rpcGym.call_async('GymLeaderBattleStart', role.gym_record_db_id, enemyRecordID, myBattle, gymID)
			model["gym_id"] = gymID
		except ClientError, e:
			# 刷新道馆馆主信息
			mes = e.log_message
			if mes in (ErrDefs.gymEnemyBattling, ErrDefs.gymEnemyChanged):
				modelBattle = yield makeGymModel(self.game, rpc, self.rpcGym)
				self.write({'model': modelBattle})
				raise ClientError(mes, model=modelBattle)
			raise ClientError(mes)

		self.write({
			'model': {
				'gym_leader_battle': model,
			}
		})


# 荣誉馆主 结束战斗
class GymLeaderBattleEnd(RequestHandlerTask):
	url = r'/game/gym/leader/battle/end'

	@coroutine
	def run(self):
		role = self.game.role

		if not ObjectGymGameGlobal.isOpen(role.areaKey):
			raise ClientError(ErrDefs.gymNotStart)

		result = self.input.get('result', None)
		gymID = self.input.get('gymID', None)  # 用作校验

		if not all([x is not None for x in [result, gymID]]):
			raise ClientError('param miss')

		try:
			ret = yield self.rpcGym.call_async('GymLeaderBattleEnd', role.id, role.gym_record_db_id, result, gymID)
		except CallError, e:
			# 可能作弊了
			raise ClientError(e.msg)
		except:
			raise

		if result == 'win':
			# 重新布阵
			yield refreshToGym(self.rpcGym, self.game, cards=ret['cards'])
			self.game.cards.deploymentForGym.deploy('cards', ret['cards'])
			# 冷却时间
			role.gym_datas['gym_pw_last_time'] = nowtime_t()

		rpc = ObjectGymGameGlobal.cross_client(role.areaKey)
		model = yield makeGymModel(self.game, rpc, self.rpcGym)

		view = {'result': result}
		result = {
			'view': view,
			'model': model,
		}
		self.write(result)


# 跨服道馆位置空 直接占
class CrossGymBattleOccupy(RequestHandlerTask):
	url = r'/game/cross/gym/battle/occupy'

	@coroutine
	def run(self):
		role = self.game.role
		if role.gym_record_db_id is None:
			raise ClientError('gym not opened')
		# 只有跨服赛季中才可以
		if not ObjectGymGameGlobal.isCrossOpen(role.areaKey):
			raise ClientError(ErrDefs.gymNotStart)

		cards = self.input.get('cards', None)
		gymID = self.input.get('gymID', None)
		pos = self.input.get('pos', None)  # 位置

		if not all([x is not None for x in [pos, gymID, cards]]):
			raise ClientError('param miss')

		cards = ObjectGymGameGlobal.battleInputOK(self.game, cards, gymID)

		# 冷却时间
		crossGymPwLastTime = role.gym_datas.get('cross_gym_pw_last_time', 0.0)
		delta = nowtime_t() - crossGymPwLastTime
		rpc = ObjectGymGameGlobal.cross_client(role.areaKey)
		crossGymRole = yield rpc.call_async('GetCrossGymRole', gymID, pos)
		if crossGymRole:
			# 如果馆主/馆员位置是自己，没有冷却CD
			if crossGymRole['role_id'] == self.game.role.id:
				delta = nowtime_t()
		ObjectGymGameGlobal.battleCanBegin(self.game, cards, gymID, delta)

		battle = ObjectGymGameGlobal.gymCrossBattleCards(self.game, cards)
		gymRoleInfo = ObjectGymGameGlobal.markGymRoleInfo(self.game.role, battle["cross_card_attrs"])
		rpc = ObjectGymGameGlobal.cross_client(role.areaKey)
		try:
			ret = yield rpc.call_async('CrossGymBattleOccupy', gymRoleInfo, gymID, pos)
			if ret:
				yield refreshToGym(self.rpcGym, self.game, cross_cards=cards)
				self.game.cards.deploymentForGym.deploy('cross_cards', cards)
				# 冷却时间
				role.gym_datas['cross_gym_pw_last_time'] = nowtime_t()
		except ClientError, e:
			# 刷新道馆馆主信息
			mes = e.log_message
			if mes in (ErrDefs.gymEnemyBattling, ErrDefs.gymEnemyChanged, ErrDefs.gymNotEmpty):
				modelBattle = yield makeGymModel(self.game, rpc, self.rpcGym)
				self.write({'model': modelBattle})
				raise ClientError(mes, model=modelBattle)
			raise ClientError(mes)

		model = yield makeGymModel(self.game, rpc, self.rpcGym)
		self.write({
			'model': model
		})


# 跨服道馆 开始战斗
class CrossGymBattleStart(RequestHandlerTask):
	url = r'/game/cross/gym/battle/start'

	@coroutine
	def run(self):
		role = self.game.role
		if role.gym_record_db_id is None:
			raise ClientError('gym not opened')
		# 只有赛季中才可战斗
		if not ObjectGymGameGlobal.isCrossOpen(role.areaKey):
			raise ClientError(ErrDefs.gymNotStart)

		cards = self.input.get('cards', None)
		gymID = self.input.get('gymID', None)
		pos = self.input.get('pos', None)
		enemyRoleKey = self.input.get('enemyRoleKey', None)
		enemyRecordID = self.input.get('enemyRecordID', None)

		if not all([x is not None for x in [pos, gymID, cards, enemyRoleKey, enemyRecordID]]):
			raise ClientError('param miss')

		if role.gym_record_db_id == enemyRecordID:
			raise ClientError('battle enemy is self')

		cards = ObjectGymGameGlobal.battleInputOK(self.game, cards, gymID)

		# 冷却时间
		crossGymPwLastTime = role.gym_datas.get('cross_gym_pw_last_time', 0.0)
		delta = nowtime_t() - crossGymPwLastTime
		ObjectGymGameGlobal.battleCanBegin(self.game, cards, gymID, delta)

		myBattle = ObjectGymGameGlobal.gymCrossBattleCards(self.game, cards)
		rpc = ObjectGymGameGlobal.cross_client(role.areaKey)
		try:
			model = yield rpc.call_async('CrossGymBattleStart', role.areaKey, enemyRoleKey, role.gym_record_db_id, enemyRecordID, myBattle, gymID, pos)
			model["gym_id"] = gymID
			model["pos"] = pos
		except ClientError, e:
			# 刷新道馆馆主信息
			mes = e.log_message
			if mes in (ErrDefs.gymEnemyBattling, ErrDefs.gymEnemyChanged):
				modelBattle = yield makeGymModel(self.game, rpc, self.rpcGym)
				self.write({'model': modelBattle})
				raise ClientError(mes, model=modelBattle)
			raise ClientError(mes)

		self.write({
			'model': {
				'cross_gym_battle': model,
			}
		})


# 跨服道馆 结束战斗
class CrossGymBattleEnd(RequestHandlerTask):
	url = r'/game/cross/gym/battle/end'

	@coroutine
	def run(self):
		role = self.game.role

		if not ObjectGymGameGlobal.isCrossOpen(role.areaKey):
			raise ClientError(ErrDefs.gymNotStart)

		result = self.input.get('result', None)
		gymID = self.input.get('gymID', None)
		pos = self.input.get('pos', None)

		if not all([x is not None for x in [result, gymID, pos]]):
			raise ClientError('param miss')

		rpc = ObjectGymGameGlobal.cross_client(role.areaKey)
		try:
			ret = yield rpc.call_async('CrossGymBattleEnd', role.id, role.gym_record_db_id, result, gymID, pos)
		except CallError, e:
			# 可能作弊了
			raise ClientError(e.msg)
		except:
			raise

		if result == 'win':
			if ret['is_swap_deploy']:
				# 重新布阵
				yield refreshToGym(self.rpcGym, self.game, cross_cards=ret['cards'])
				self.game.cards.deploymentForGym.deploy('cross_cards', ret['cards'])
			# 冷却时间
			role.gym_datas['cross_gym_pw_last_time'] = nowtime_t()

		model = yield makeGymModel(self.game, rpc, self.rpcGym)
		view = {'result': result}
		result = {
			'view': view,
			'model': model,
		}
		self.write(result)


# 道馆 PVP战报回放
class GymPlayRecordGet(RequestHandlerTask):
	url = r'/game/gym/playrecord/get'

	@coroutine
	def run(self):
		crossKey = self.input.get('crossKey', None)  # 不传为本服，传为跨服
		recordID = self.input.get('recordID', None)  # playRecord.id
		if recordID is None:
			raise ClientError('param miss')
		if crossKey:  # 跨服
			rpc = ObjectGymGameGlobal.cross_client(self.game.role.areaKey, cross_key=crossKey)
			if rpc is None:
				raise ClientError('Cross Gym Play Not Existed')
			model = yield rpc.call_async('GetCrossGymPlayRecord', recordID)
			if not model:
				raise ClientError('Cross Gym Play Not Existed')
		else:  # 本服
			model = yield self.rpcGym.call_async('GetGymPlayRecord', recordID)
			if not model:
				raise ClientError('Gym Play Not Existed')
		self.write({
			'model': {
				'gym_playrecords': {
					recordID: model,
				}
			}
		})


# 道馆 查看玩家详情
class GymRoleInfo(RequestHandlerTask):
	url = r'/game/gym/role/info'

	@coroutine
	def run(self):
		role = self.game.role
		if role.gym_record_db_id is None:
			raise ClientError('gym not opened')

		recordID = self.input.get('recordID', None)
		gameKey = self.input.get('gameKey', None)  # 用于跨服
		if recordID is None:
			raise ClientError('param miss')

		if gameKey:
			client = self.server.container.getserviceOrCreate(ObjectGymGameGlobal.game2gym(gameKey))
		else:
			client = self.rpcGym
		view = yield client.call_async('GetGymRecord', recordID)

		if gameKey:
			view["game_key"] = gameKey
		else:
			view['union_name'] = ObjectUnion.queryUnionName(view['role_id'])
		self.write({
			'view': view,
		})


# 道馆关卡战斗开始
class GymStartGate(RequestHandlerTask):
	url = r'/game/gym/gate/start'

	@coroutine
	def run(self):
		if not ObjectGymGameGlobal.isOpen(self.game.role.areaKey):
			raise ClientError(ErrDefs.gymNotStart)

		gateID = self.input.get('gateID', None)
		gymID = self.input.get('gymID', None)
		cardIDs = self.input.get('cardIDs', None)
		if not all([x is not None for x in [gateID, gymID, cardIDs]]):
			raise ClientError('params miss')

		dailyRecord = self.game.dailyRecord
		cfg = csv.scene_conf[gateID]
		if not cfg or cfg.sceneType != MapDefs.TypeGymGate:
			raise ClientError('gateID error')

		cfgGate = csv.gym.gate[gateID]
		if cfgGate.npc:
			if cfgGate.gymID != gymID:
				raise ClientError('npc gateID error!')
			gymPwLastTime = self.game.role.gym_datas.get('gym_pw_last_time', 0.0)
			delta = nowtime_t() - gymPwLastTime
			ObjectGymGameGlobal.battleCanBegin(self.game, cardIDs, gymID, delta)
			# 馆主为空
			leaderRole = yield self.rpcGym.call_async('GetGymLeader', gymID)
			if leaderRole:
				rpc = ObjectGymGameGlobal.cross_client(self.game.role.areaKey)
				modelBattle = yield makeGymModel(self.game, rpc, self.rpcGym)
				self.write({'model': modelBattle})
				raise ClientError(ErrDefs.gymEnemyIsNotNpc, model=modelBattle)
		else:
			if dailyRecord.gym_battle_times >= ConstDefs.gymBattleTimes + dailyRecord.gym_battle_buy_times:
				raise ClientError('gym gate battle times limit')

		self.game.battle = ObjectGymBattle(self.game)
		ret = self.game.battle.begin(gymID, gateID, cardIDs)

		self.write({
			'model': ret
		})


# 道馆关卡战斗结束
class GymEndGate(RequestHandlerTask):
	url = r'/game/gym/gate/end'

	@coroutine
	def run(self):
		if not ObjectGymGameGlobal.isOpen(self.game.role.areaKey):
			raise ClientError(ErrDefs.gymNotStart)

		if not isinstance(self.game.battle, ObjectGymBattle):
			raise ServerError('gate battle miss')

		battleID = self.input.get('battleID', None)
		gateID = self.input.get('gateID', None)
		result = self.input.get('result', None)
		damage = self.input.get('damage', None)

		if any([x is None for x in [battleID, gateID, result, damage]]):
			raise ClientError('param miss')
		if gateID != self.game.battle.gateID:
			raise ClientError('gateID error')
		if battleID != self.game.battle.id:
			raise ClientError('battleID error')

		damage = int(damage)
		# 伤害保护
		if damage > self.game.battle.maxDamage():
			logger.warning("role %d gym fuben damage %d cheat can max %d", self.game.role.uid, damage, self.game.battle.maxDamage())
			raise ClientError(ErrDefs.rankCheat)
		if damage < 0:
			raise ClientError('damage error')

		# 战斗结算
		eff = self.game.battle.result(result)
		if eff:
			yield effectAutoGain(eff, self.game, self.dbcGame, src="gym_gate")

		ret = self.game.battle.end()

		if result == 'win' and csv.gym.gate[gateID].npc:
			cards = self.game.battle.cardIDs
			gymID = self.game.battle.gymID

			battle = ObjectGymGameGlobal.gymLeaderBattleCards(self.game, cards)
			gymRoleInfo = ObjectGymGameGlobal.markGymRoleInfo(self.game.role, battle["card_attrs"])
			rpc = ObjectGymGameGlobal.cross_client(self.game.role.areaKey)
			try:
				flag = yield self.rpcGym.call_async('GymLeaderBattleOccupy', gymRoleInfo, gymID)
				if flag:
					# 布阵
					yield refreshToGym(self.rpcGym, self.game, cards=cards)
					self.game.cards.deploymentForGym.deploy('cards', cards)
					# 冷却时间
					self.game.role.gym_datas['gym_pw_last_time'] = nowtime_t()
			except ClientError, e:
				# 刷新道馆馆主信息
				mes = e.log_message
				if mes in (ErrDefs.gymEnemyBattling, ErrDefs.gymEnemyChanged, ErrDefs.gymNotEmpty):
					modelBattle = yield makeGymModel(self.game, rpc, self.rpcGym)
					self.write({'model': modelBattle})
					raise ClientError(mes, model=modelBattle)
				raise ClientError(mes)

			model = yield makeGymModel(self.game, rpc, self.rpcGym)
			ret['model'] = model

		role = self.game.role
		if result == 'win' and not csv.gym.gate[gateID].npc and role.isGymPassed(self.game.battle.gymID):
			yield self.rpcGym.call_async('GymFubenPass', role.gym_record_db_id, self.game.battle.gymID, len(role.gym_pass_awards))
			model = yield makeGymModel(self.game, ObjectGymGameGlobal.cross_client(role.areaKey), self.rpcGym)
			ret['model'] = model

		if result == 'win' and not csv.gym.gate[gateID].npc:
			ObjectYYHuoDongFactory.onTaskChange(self.game, PlayPassportDefs.Gym, 1)

		self.game.battle = None

		if eff:
			ret['view']['drop'] = eff.result

		self.write(ret)


# 道馆关卡扫荡
class GymPassGate(RequestHandlerTask):
	url = r'/game/gym/gate/pass'

	@coroutine
	def run(self):
		if not ObjectFeatureUnlockCSV.isOpen(FeatureDefs.GymPass, self.game):
			raise ClientError('GymPass not open')

		if not ObjectGymGameGlobal.isOpen(self.game.role.areaKey):
			raise ClientError(ErrDefs.gymNotStart)

		gateID = self.input.get('gateID', None)
		gymID = self.input.get('gymID', None)
		if not all([x is not None for x in [gateID, gymID]]):
			raise ClientError('params miss')

		dailyRecord = self.game.dailyRecord

		cfg = csv.scene_conf[gateID]
		if not cfg or cfg.sceneType != MapDefs.TypeGymGate:
			raise ClientError('gateID error')

		if dailyRecord.gym_battle_times + 1 >= ConstDefs.gymBattleTimes + dailyRecord.gym_battle_buy_times:
			raise ClientError('gym gate battle times limit')

		self.game.battle = ObjectGymPass(self.game)
		self.game.battle.begin(gymID, gateID)

		# 战斗结算
		eff = self.game.battle.result()
		if eff:
			yield effectAutoGain(eff, self.game, self.dbcGame, src="gym_gate_pass")

		ret = self.game.battle.end()

		role = self.game.role
		if role.isGymPassed(self.game.battle.gymID):
			yield self.rpcGym.call_async('GymFubenPass', role.gym_record_db_id, self.game.battle.gymID, len(role.gym_pass_awards))
			model = yield makeGymModel(self.game, ObjectGymGameGlobal.cross_client(role.areaKey), self.rpcGym)
			ret['model'] = model

		ObjectYYHuoDongFactory.onTaskChange(self.game, PlayPassportDefs.Gym, 1)

		self.game.battle = None

		if eff:
			ret['view']['drop'] = eff.result

		self.write(ret)


# 道馆挑战次数购买
class GymBattleBuy(RequestHandlerTask):
	url = r'/game/gym/battle/buy'

	@coroutine
	def run(self):
		if not ObjectGymGameGlobal.isOpen(self.game.role.areaKey):
			raise ClientError('gym not open')

		battleBuyTimes = self.game.dailyRecord.gym_battle_buy_times
		if battleBuyTimes >= self.game.role.gymBattleBuyTimes:
			raise ClientError('gym battle buy times limit up')

		costRMB = ObjectCostCSV.getGymBattleBuyCost(battleBuyTimes)

		cost = ObjectCostAux(self.game, {'rmb': costRMB})
		if not cost.isEnough():
			raise ClientError("cost rmb not enough")
		cost.cost(src='gym_battle_buy')

		self.game.dailyRecord.gym_battle_buy_times = battleBuyTimes + 1


# 道馆副本 领取通关奖励
class GymGateAward(RequestHandlerTask):
	url = r'/game/gym/gate/award'

	@coroutine
	def run(self):

		gymID = self.input.get('gymID', None)

		eff = ObjectGymGameGlobal.getGymPassedAward(self.game, gymID)
		if eff:
			yield effectAutoGain(eff, self.game, self.dbcGame, src="gym_gate_award")

		self.write({
			'view': eff.result if eff else {}
		})


# 道馆天赋 点数购买
class GymTalentPointBuy(RequestHandlerTask):
	url = r'/game/gym/talent/point/buy'

	@coroutine
	def run(self):
		if not ObjectGymGameGlobal.isOpen(self.game.role.areaKey):
			raise ClientError('gym not open')

		buyTimes = self.game.dailyRecord.gym_talent_point_buy_times
		if buyTimes >= self.game.role.gymTalentPointBuyTimes:
			raise ClientError('gym talent point buy times limit up')

		costRMB = ObjectCostCSV.getGymTalentPointBuyCost(buyTimes)

		cost = ObjectCostAux(self.game, {'rmb': costRMB})
		if not cost.isEnough():
			raise ClientError("cost rmb not enough")
		cost.cost(src='gym_talent_point_buy')

		self.game.dailyRecord.gym_talent_point_buy_times = buyTimes + 1

		eff = ObjectGainAux(self.game, {'gym_talent_point': ConstDefs.gymTalentPointBuyCount})
		yield effectAutoGain(eff, self.game, self.dbcGame, src="gym_talent_point_buy")


# 道馆天赋 升级
class GymTalentLevelUpReady(RequestHandlerTask):
	url = r'/game/gym/talent/level/up'

	@coroutine
	def run(self):
		if not ObjectGymGameGlobal.isOpen(self.game.role.areaKey):
			raise ClientError('gym not open')

		talentID = self.input.get('talentID', None)
		if talentID is None:
			raise ClientError('talentID miss')

		if talentID not in csv.gym.talent_buff:
			raise ClientError('gym talentID error')

		self.game.gymTalentTree.talentLevelUp(talentID)


# 道馆天赋 重置
class GymTalentReset(RequestHandlerTask):
	url = r'/game/gym/talent/reset'

	@coroutine
	def run(self):
		if not ObjectGymGameGlobal.isOpen(self.game.role.areaKey):
			raise ClientError('gym not open')

		eff = self.game.gymTalentTree.talentResetAll()
		if eff:
			yield effectAutoGain(eff, self.game, self.dbcGame, src="gym_talent_reset")

		self.write({
			'view': eff.result if eff else {}
		})
