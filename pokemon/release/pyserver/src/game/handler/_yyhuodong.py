#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2014 YouMi Information Technology Inc.

HuoDong Handlers
'''

from framework import nowtime_t, todayinclock5date2int, datetime2timestamp, datetimefromtimestamp
from framework.csv import csv, ErrDefs, ConstDefs
from framework.helper import transform2list, getL10nCsvValue
from framework.log import logger

from game import ClientError, ServerError
from game.globaldata import YYHuoDongLimitBoxRankCount, WorldBossHuodongID, ReunionInviteCDTime, CrossBraveChallengeRanking, CrossHorseRaceRanking, CrossVolleyballlRanking, CrossShavedIceRanking
from game.handler._society import getFriendSociety
from game.handler.task import RequestHandlerTask
from game.handler.inl import effectAutoGain
from game.object import DrawCardDefs, MessageDefs, AchievementDefs, PasspostDefs, ReunionDefs, TargetDefs, BraveChallengeDefs, YYDispatchDefs, YYVolleyballDefs
from game.object.game import ObjectGame, ObjectRole, ObjectReunionRecord
from game.object.game.rank import ObjectRankGlobal
from game.object.game.society import ObjectSocietyGlobal
from game.object.game.yyhuodong import ObjectYYHuoDongFactory, ObjectYYFightRank, ObjectYYBase, ObjectYYBraveChallenge
from tornado.gen import coroutine, Return
from game.object.game.gain import ObjectGainAux, ObjectCostAux, ObjectGainEffect
from game.object.game.battle import ObjectWorldBossBattle, ObjectYYHuoDongBossBattle
from game.object.game.costcsv import ObjectCostCSV
from game.object.game.message import ObjectMessageGlobal
from game.object.game.servrecord import ObjectServerGlobalRecord
from game.thinkingdata import ta

import time

# 获取激活的活动
class YYGetActive(RequestHandlerTask):
	url = r'/game/yy/active/get'

	@coroutine
	def run(self):
		ObjectYYHuoDongFactory.onActiveGet(self.game)

		# 运营活动奖励未领取
		effs = ObjectYYHuoDongFactory.getRoleRegainMails(self.game)
		for eff in effs:
			yield effectAutoGain(eff, self.game, self.dbcGame, src='yy_regain')

		self.game.role.refreshYYOpen()
		yyIDs = self.game.role.yyOpen
		deltas = self.game.role.yyDelta
		views = ObjectYYHuoDongFactory.getViews(yyIDs)
		self.write({'view': views})


# 获取活动奖励
class YYGetAward(RequestHandlerTask):
	url = r'/game/yy/award/get'

	@coroutine
	def run(self):
		yyID = self.input.get('yyID', None)
		csvID = self.input.get('csvID', None)
		count = self.input.get('count', None) # 次数，目前用于ObjectYYItemBuy(道具折扣), ObjectYYItemExchange(道具兑换)
		if count is not None and count <= 0:
			raise ClientError('param error')

		hdCls = ObjectYYHuoDongFactory.getRoleOpenClass(yyID, self.game.role.level, self.game.role.created_time, self.game.role.vip_level)
		if hdCls is None:
			if yyID in ObjectYYHuoDongFactory.DinnerID:
				hdCls = ObjectYYHuoDongFactory.getDinnerClass(yyID, self.game.role.level, self.game.role.created_time, self.game.role.vip_level)
			else:
				raise ClientError(ErrDefs.huodongNoOpen)
		if count:
			eff = hdCls.getEffect(yyID, csvID, self.game, count)
		else:
			eff = hdCls.getEffect(yyID, csvID, self.game)
		yield effectAutoGain(eff, self.game, self.dbcGame, src='yy_%d' % yyID, yy_id=yyID)

		view = {'result': eff.result if eff else {}}

		views = ObjectYYHuoDongFactory.getViews()
		view.update(views)

		self.write({'view': view})

# 一键获取活动奖励
class YYGetAwardOneKey(RequestHandlerTask):
	url = r'/game/yy/award/get/onekey'

	@coroutine
	def run(self):
		yyID = self.input.get('yyID', None)

		from game.object import YYHuoDongDefs
		if csv.yunying.yyhuodong[yyID].type not in [
			YYHuoDongDefs.GeneralTask,
			YYHuoDongDefs.ServerOpen,
			YYHuoDongDefs.LoginWeal,
			YYHuoDongDefs.BaoZongzi,
			YYHuoDongDefs.HuoDongCloth,
			YYHuoDongDefs.Skyscraper,
			YYHuoDongDefs.PlayPassport,
			YYHuoDongDefs.GridWalk,
			YYHuoDongDefs.Dispatch,
			YYHuoDongDefs.Volleyball,
		]:
			raise ClientError('type error')

		hdCls = ObjectYYHuoDongFactory.getRoleOpenClass(yyID, self.game.role.level, self.game.role.created_time, self.game.role.vip_level)
		if hdCls is None:
			raise ClientError(ErrDefs.huodongNoOpen)

		if csv.yunying.yyhuodong[yyID].type is YYHuoDongDefs.Skyscraper:
			eff = hdCls.getOneKeyEffect(yyID, self.game)
			if eff:
				yield effectAutoGain(eff, self.game, self.dbcGame, src='yy_%d' % yyID, yy_id=yyID)

			lvl = 0
			record = hdCls.getExistedRecord(yyID, self.game)
			keys = record['stamps1'].keys()
			if keys:
				lvl = max(keys)
			yield ObjectServerGlobalRecord.sendYYHuoDongCrossSkyscraperInfo(self.game, medallvl=lvl, highScore=record['info']['high_points'], highFloor=record['info']['high_floors'])
		else:
			eff = hdCls.getOneKeyEffect(yyID, self.game)
			if eff:
				yield effectAutoGain(eff, self.game, self.dbcGame, src='yy_%d' % yyID, yy_id=yyID)

		view = {'result': eff.result if eff else {}}
		self.write({'view': view})

# 查询购买资格
class YYAwardCanBuy(RequestHandlerTask):
	url = r'/game/yy/award/canbuy'

	@coroutine
	def run(self):
		yyID = self.input.get('yyID', None)
		csvID = self.input.get('csvID', None)
		# 查询能否购买
		hdCls = ObjectYYHuoDongFactory.getRoleOpenClass(yyID, self.game.role.level, self.game.role.created_time, self.game.role.vip_level)
		if hdCls is None:
			raise ClientError(ErrDefs.huodongNoOpen)

		self.write({'view': hdCls.canBuy(yyID, csvID, self.game)})


# 限时抽卡
class YYGetDraw(RequestHandlerTask):
	url = r'/game/yy/award/draw'

	@coroutine
	def run(self):
		yyID = self.input.get('yyID', None)

		# 一般限时抽卡: 'limit_rmb1'  'limit_rmb10'
		# up 限时抽卡: 'limit_up_rmb1'  'limit_up_rmb10'
		# 充值大转盘: 'free' 'once' 'all'
		# 活跃大转盘 'lineness_wheel_free1' 'lineness_wheel1' 'lineness_wheel5'
		# 月圆祈福: 'blessing'
		drawType = self.input.get('drawType', None)

		hdCls = ObjectYYHuoDongFactory.getRoleOpenClass(yyID, self.game.role.level, self.game.role.created_time, self.game.role.vip_level)
		if hdCls is None:
			raise ClientError(ErrDefs.huodongNoOpen)

		eff = hdCls.getEffect(yyID, drawType, self.game)
		if eff:
			yield effectAutoGain(eff, self.game, self.dbcGame, src='draw_card_%s' % drawType, yy_id=yyID)
			if eff.getCardsObjD():
				cfrom = None
				mfrom = None
				if drawType in (DrawCardDefs.LimitRMB1, DrawCardDefs.LimitRMB10):
					cfrom = 'limit_draw'
					mfrom = MessageDefs.MqLimitDrawCard
				elif drawType in (DrawCardDefs.LimitUpRMB1, DrawCardDefs.LimitUpRMB10):
					cfrom = 'limit_draw_up'
					mfrom = MessageDefs.MqLimitDrawCardUp
				if cfrom:
					for _, obj in eff.getCardsObjD().iteritems():
						ObjectMessageGlobal.newsCardMsg(self.game.role, obj, cfrom)
						ObjectMessageGlobal.marqueeBroadcast(self.game.role, mfrom, card=obj)
			if drawType == 'blessing':
				hit = hdCls.recordDraw(yyID, self.game, eff.result)
				self.write({'view': {'result': eff.result, 'hit': hit}})
			else:
				self.write({'view': {'result': eff.result}})
			ta.track(self.game, event='activity',yy_id=yyID,activity_type=drawType)


# 限时up 符石
class YYLimitUpDrawGem(RequestHandlerTask):
	url = r'/game/yy/limit/gem/draw'

	@coroutine
	def run(self):
		yyID = self.input.get('yyID', None)
		drawType = self.input.get('drawType', None)
		decompose = self.input.get('decompose', 0)

		hdCls = ObjectYYHuoDongFactory.getRoleOpenClass(yyID, self.game.role.level, self.game.role.created_time, self.game.role.vip_level)
		if hdCls is None:
			raise ClientError(ErrDefs.huodongNoOpen)

		eff = hdCls.getEffect(yyID, drawType, self.game)

		if decompose:
			eff.gem2item()
		if eff:
			yield effectAutoGain(eff, self.game, self.dbcGame, src=drawType, yy_id=yyID)

		self.write({
			'view': eff.result
		})


# 获取开服活动全目标奖励
class YYGetTargetsAward(RequestHandlerTask):
	url = r'/game/yy/targets/award/get'

	@coroutine
	def run(self):
		yyID = self.input.get('yyID', None)

		hdCls = ObjectYYHuoDongFactory.getRoleOpenClass(yyID, self.game.role.level, self.game.role.created_time, self.game.role.vip_level)
		yyObj = ObjectYYHuoDongFactory.getRoleOpenConfig(yyID, self.game.role.level, self.game.role.created_time, self.game.role.vip_level)
		if hdCls is None or yyObj is None:
			raise ClientError(ErrDefs.huodongNoOpen)

		eff = hdCls.getTargetsEffect(yyObj, self.game)
		yield effectAutoGain(eff, self.game, self.dbcGame, src='yy_%d_targets' % yyID, yy_id=yyID)

		self.write({'view': {'result': eff.result if eff else {}}})


# 获取战力排行
class YYGetFightRank(RequestHandlerTask):
	url = r'/game/yy/fightrank/get'

	@coroutine
	def run(self):
		yyID = self.input.get('yyID', None)

		yyObj = ObjectYYHuoDongFactory.getRoleOpenConfig(yyID, self.game.role.level, self.game.role.created_time, self.game.role.vip_level)
		if yyObj is None:
			raise ClientError(ErrDefs.huodongNoOpen)

		# 类似/game/rank获取战力排名数据
		offest = 0
		size = 10
		self.game.role.fight_rank = yield ObjectRankGlobal.queryRank('fight', self.game.role.id)
		ret = ObjectYYFightRank.getTop10RankModel(yyID)
		if ret is None:
			ret = yield ObjectRankGlobal.getRankList('fight', offest, size)

		self.write({'view': {
			'rank': ret,
			'offest': offest,
			'size': size,
			'end_time': datetime2timestamp(ObjectYYFightRank.getAwardDateTime(yyObj)),
		}})

# 对限时宝箱打开做特殊处理
class YYLimitBoxGet(RequestHandlerTask):
	url = r'/game/yy/limit/box/get'

	@coroutine
	def run(self):
		yyID = self.input.get('yyID', None)

		hdCls = ObjectYYHuoDongFactory.getRoleOpenClass(yyID, self.game.role.level, self.game.role.created_time, self.game.role.vip_level)
		yyObj = ObjectYYHuoDongFactory.getRoleOpenConfig(yyID, self.game.role.level, self.game.role.created_time, self.game.role.vip_level)
		if yyObj is None:
			raise ClientError(ErrDefs.huodongNoOpen)

		yybox = 'yybox'

		# 没有资格就不进榜单
		if hdCls.acquireQualify(yyID, self.game):
			record = ObjectYYBase.getRecord(yyID, self.game)
			recordInfo = record.setdefault('info', {})
			if record.get('box_point', 0) > 0:
				nowrank = yield ObjectRankGlobal.queryRank(yybox, self.game.role.id, gameKey=self.game.role.areaKey)
				# 加入抽卡截止时间判断，防止数据清理时产生脏数据
				if nowrank == 0 and not hdCls.hasDrawEnd(yyObj): # 有资格，有积分，且之前没在排行榜内，则加入到排行榜中
					yield ObjectRankGlobal.onKeyInfoChange(self.game, yybox, record)
				elif nowrank > 0 and nowrank != recordInfo.get('rank',0):
					recordInfo['rank'] = nowrank

		rank = yield ObjectRankGlobal.getRankList(yybox, 0, YYHuoDongLimitBoxRankCount, self.game.role.areaKey)

		view = {
			'rank': rank,
			'event_delta': ObjectYYHuoDongFactory.getEventDeltaTimes([yyID], self.game),
		}
		self.write({'view': view})

# 限时宝箱
class YYLimitBox(RequestHandlerTask):
	url = r'/game/yy/limit/box/draw'

	@coroutine
	def run(self):
		yyID = self.input.get('yyID', None)
		drawType = self.input.get('drawType', None)

		hdCls = ObjectYYHuoDongFactory.getRoleOpenClass(yyID, self.game.role.level, self.game.role.created_time, self.game.role.vip_level)
		if hdCls is None:
			raise ClientError(ErrDefs.huodongNoOpen)

		eff = hdCls.getEffect(yyID, drawType, self.game)
		yield effectAutoGain(eff, self.game, self.dbcGame, src='limit_box_%s' % drawType, yy_id=yyID)

		yybox = 'yybox'
		# 没有资格就不进榜单
		if hdCls.acquireQualify(yyID, self.game):
			record = hdCls.getRecord(yyID, self.game)
			if record.get('box_point', 0) > 0:
				yield ObjectRankGlobal.onKeyInfoChange(self.game, yybox, record)

		if eff and eff.getCardsObjD():
			for _, obj in eff.getCardsObjD().iteritems():
				ObjectMessageGlobal.newsCardMsg(self.game.role, obj, 'limitbox')
				ObjectMessageGlobal.marqueeBroadcast(self.game.role, MessageDefs.MqLimitBox, card=obj)

		rank = yield ObjectRankGlobal.getRankList(yybox, 0, YYHuoDongLimitBoxRankCount, self.game.role.areaKey)

		self.write({'view': {
			'result': eff.result if eff else {},
			'rank': rank,
		}})

# 限时宝箱 领取积分奖励
class YYLimitBoxPoint(RequestHandlerTask):
	url = r'/game/yy/limit/box/point'

	@coroutine
	def run(self):
		yyID = self.input.get('yyID', None)
		csvID = self.input.get('csvID', None)

		hdCls = ObjectYYHuoDongFactory.getRoleOpenClass(yyID, self.game.role.level, self.game.role.created_time, self.game.role.vip_level)
		if hdCls is None:
			raise ClientError(ErrDefs.huodongNoOpen)

		record = ObjectYYBase.getRecord(yyID, self.game)
		if record is None:
			raise ClientError(ErrDefs.yyHuoDongNoActive)

		if 'stamps' not in record or csvID not in record['stamps']:
			raise ClientError(ErrDefs.yyboxPointLimit)

		if record['stamps'][csvID] != 1:
			raise ClientError(ErrDefs.yyboxPointAlready)

		record['stamps'][csvID] = 0

		cfg = csv.yunying.limitboxpointaward[csvID]

		eff = ObjectGainAux(self.game, cfg.award)
		if eff:
			yield effectAutoGain(eff, self.game, self.dbcGame, src='limit_box_point', yy_id=yyID)

		self.write({'view': {'result': eff.result if eff else {}}})


# 等级基金购买
class YYLevelFundBuy(RequestHandlerTask):
	url = r'/game/yy/levelfund/buy'

	@coroutine
	def run(self):
		yyID = self.input.get('yyID', None)

		hdCls = ObjectYYHuoDongFactory.getRoleOpenClass(yyID, self.game.role.level, self.game.role.created_time, self.game.role.vip_level)
		yyObj = ObjectYYHuoDongFactory.getRoleOpenConfig(yyID, self.game.role.level, self.game.role.created_time, self.game.role.vip_level)
		if hdCls is None or yyObj is None:
			raise ClientError(ErrDefs.huodongNoOpen)

		hdCls.buy(yyID, self.game)
		hdCls.active(yyObj, self.game)

# 砸金蛋
class YYBreakEggGet(RequestHandlerTask):
	url = r'/game/yy/breakegg/break'

	@coroutine
	def run(self):
		yyID = self.input.get('yyID', None)
		pos = self.input.get('pos', None)

		hdCls = ObjectYYHuoDongFactory.getRoleOpenClass(yyID, self.game.role.level, self.game.role.created_time, self.game.role.vip_level)
		if hdCls is None:
			raise ClientError(ErrDefs.huodongNoOpen)
		eff = hdCls.getEffect(yyID, int(pos), self.game)
		yield effectAutoGain(eff, self.game, self.dbcGame, src='breakegg', yy_id=yyID)

		self.write({'view': {'result': eff.result if eff else {}}})

# 世界boss主界面
class YYWorldBossMain(RequestHandlerTask):
	url = r'/game/yy/world/boss/main'

	@coroutine
	def run(self):
		yyID = self.input.get('yyID', None)

		hdCls = ObjectYYHuoDongFactory.getRoleOpenClass(yyID, self.game.role.level, self.game.role.created_time, self.game.role.vip_level)
		if hdCls is None:
			raise ClientError(ErrDefs.huodongNoOpen)

		view = yield self.rpcYYHuodong.call_async("WorldBossMain")

		self.write({'view': view})

# 世界boss开始战斗
class YYWordBossStart(RequestHandlerTask):
	url = r'/game/yy/world/boss/start'

	@coroutine
	def run(self):
		battleCardIDs = self.input.get('battleCardIDs', None)
		yyID = self.input.get('yyID', None)

		if battleCardIDs is None or yyID is None:
			raise ClientError('param miss')

		hdCls = ObjectYYHuoDongFactory.getRoleOpenClass(yyID, self.game.role.level, self.game.role.created_time, self.game.role.vip_level)
		if hdCls is None:
			raise ClientError(ErrDefs.huodongNoOpen)

		yycfg = csv.yunying.yyhuodong[yyID]
		freeCount = yycfg.paramMap['freeCount']
		worldBossCfg = hdCls.getWorldBossCfg(yycfg.huodongID)
		gateID = worldBossCfg.gateID
		if gateID not in csv.scene_conf:
			raise ClientError('gateID error')

		battleCardIDs = transform2list(battleCardIDs)
		self.game.role.deployHuodongCards(WorldBossHuodongID, battleCardIDs)
		# 战斗数据
		self.game.battle = ObjectWorldBossBattle(self.game)
		ret = self.game.battle.begin(gateID, battleCardIDs, freeCount)

		self.write({
			'model': ret
		})

# 世界boss结束战斗
class YYWordBossEnd(RequestHandlerTask):
	url = r'/game/yy/world/boss/end'

	@coroutine
	def run(self):
		battleID = self.input.get('battleID', None)
		yyID = self.input.get('yyID', None)
		damage = self.input.get('damage', None)

		hdCls = ObjectYYHuoDongFactory.getRoleOpenClass(yyID, self.game.role.level, self.game.role.created_time, self.game.role.vip_level)
		if hdCls is None:
			raise ClientError(ErrDefs.huodongNoOpen)

		if not all([x is not None for x in [battleID, yyID, damage]]):
			raise ClientError('param miss')

		if battleID != self.game.battle.id:
			raise ClientError('battleID error')

		yycfg = csv.yunying.yyhuodong[yyID]
		worldBossCfg = hdCls.getWorldBossCfg(yycfg.huodongID)
		gateID = worldBossCfg.gateID
		if gateID != self.game.battle.gateID:
			raise ClientError('gateID error')

		damage = int(damage)
		# 伤害保护
		if damage > self.game.battle.maxDamage():
			logger.warning("role %d worldBoss damage %d cheat can max %d", self.game.role.uid, damage, self.game.battle.maxDamage())
			raise ClientError(ErrDefs.rankCheat)

		if damage < 0:
			raise ClientError('damage error')

		# 战斗结算
		self.game.battle.result('win')

		damageSum = None
		needUpdate = False
		if damage > self.game.dailyRecord.boss_damage_max:
			self.game.dailyRecord.boss_damage_max = damage
			needUpdate = True

		# 可能当天玩家公会从无到有，更新伤害到新公会
		if not self.game.dailyRecord.boss_union_db_id and self.game.role.union_db_id and self.game.dailyRecord.boss_damage_max > 0:
			needUpdate = True

		if needUpdate:
			req = {'role': self.game.role.makeWorldBossRankModel()}
			union = self.game.role.getWorldBossUnion()
			if union:
				req['union'] = {
					'id': union.id,
					'level': union.level,
					'name': union.name,
					'logo': union.logo,
				}
			damageSum = yield self.rpcYYHuodong.call_async('WorldBossDamageUpdate', req)

		# 战斗结算完毕
		ret = self.game.battle.end()
		self.game.battle = None

		eff = hdCls.getDamageAward(self.game, yycfg.huodongID, damage)
		award = {}
		if eff:
			yield effectAutoGain(eff, self.game, self.dbcGame, src="world_boss", yy_id=yyID)
			award = eff.result

		ret['view']['award'] = award
		if damageSum:
			ret['view']['damageSum'] = damageSum

		self.write(ret)

# 购买排位赛次数
class YYWordBossBuy(RequestHandlerTask):
	url = r'/game/yy/world/boss/buy'

	@coroutine
	def run(self):
		if self.game.dailyRecord.boss_gate_buy >= self.game.role.bossTimeBuyLimit:
			raise ClientError(ErrDefs.yyWorldBossBuyMax)

		costRMB = ObjectCostCSV.getWorldBossBuyCost(self.game.dailyRecord.boss_gate_buy)
		cost = ObjectCostAux(self.game, {'rmb': costRMB})
		if not cost.isEnough():
			raise ClientError(ErrDefs.buyRMBNotEnough)
		cost.cost(src='worldboss_buy')
		self.game.dailyRecord.boss_gate_buy += 1

# 世界boss排名信息
class YYWordBossRank(RequestHandlerTask):
	url = r'/game/yy/world/boss/rank'

	@coroutine
	def run(self):
		unionID = None
		if self.game.union:
			unionID = self.game.union.id
		rankInfo = yield self.rpcYYHuodong.call_async('WorldBossRankInfo', self.game.role.id, unionID)
		self.write({'view': rankInfo})

# 通行证 领取奖励/一键领取
class YYPassportAward(RequestHandlerTask):
	url = r'/game/yy/passport/award/get_onekey'

	@coroutine
	def run(self):
		yyID = self.input.get('yyID', None)

		role = self.game.role
		hdCls = ObjectYYHuoDongFactory.getRoleOpenClass(yyID, role.level, role.created_time, role.vip_level)
		if hdCls is None:
			raise ClientError(ErrDefs.huodongNoOpen)

		eff = hdCls.getOneKeyEffect(yyID, self.game)
		if eff:
			yield effectAutoGain(eff, self.game, self.dbcGame, src='passport_award_oneKey', yy_id=yyID)

		self.write({'view': eff.result if eff else {}})


# 通行证 任务经验领取
class YYPassportTaskGetExp(RequestHandlerTask):
	url = r'/game/yy/passport/task/get_exp'

	@coroutine
	def run(self):
		yyID = self.input.get('yyID', None)
		csvID = self.input.get('csvID', None)  # -1时表示 一键领取

		if yyID is None or csvID is None:
			raise ClientError('prams miss')

		role = self.game.role
		hdCls = ObjectYYHuoDongFactory.getRoleOpenClass(yyID, role.level, role.created_time, role.vip_level)
		if hdCls is None:
			raise ClientError(ErrDefs.huodongNoOpen)

		record = hdCls.getExistedRecord(yyID, self.game)
		if record is None:
			raise ClientError(ErrDefs.yyHuoDongNoActive)

		isMaster = hdCls.checkMaster(record)

		if csvID == -1:
			# 一键领取
			task = record.setdefault('task', {})
			for taskID in task:
				cfg = csv.yunying.passport_task[taskID]
				# 激活大师前，不可领取大师任务奖励，跳过
				if cfg.taskAttribute == PasspostDefs.MasterTask and not isMaster:
					continue
				count, flag = task.get(taskID, (0, 0))
				if flag == 1:
					hdCls.getTaskAward(yyID, taskID, self.game)
		else:
			cfg = csv.yunying.passport_task[csvID]
			if not (cfg.taskAttribute == PasspostDefs.MasterTask and not isMaster):
				hdCls.getTaskAward(yyID, csvID, self.game)


# 通行证积分商店兑换
class PassportShopBuy(RequestHandlerTask):
	url = r'/game/yy/passport/shop/buy'

	@coroutine
	def run(self):
		yyID = self.input.get('yyID', None)
		csvID = self.input.get('csvID', None)
		count = self.input.get('count', 1)
		if yyID is None or csvID is None:
			raise ClientError('param miss')
		if count <= 0:
			raise ClientError('count error')

		cfg = csv.yunying.yyhuodong[yyID]
		if not cfg or self.game.role.passport.get('yy_id', -1) != yyID:
			raise ClientError(ErrDefs.yyHuoDongNoActive)

		shopCfg = csv.yunying.passport_shop[csvID]
		if not shopCfg:
			raise ClientError('passport shop item error')

		shopRecord = self.game.role.passport.setdefault('shop', {})
		buyTimes = shopRecord.setdefault(csvID, 0)
		if (count + buyTimes) > shopCfg.limitTimes:
			raise ClientError(ErrDefs.buyShopTimesLimit)

		cost = ObjectCostAux(self.game, shopCfg.costMap)
		cost *= count
		if not cost.isEnough():
			raise ClientError(ErrDefs.csvShopCoinNotEnough)
		cost.cost(src='passport_shop_buy')

		def afterGain():
			shopRecord[csvID] = count + buyTimes

		eff = ObjectGainEffect(self.game, shopCfg.items, afterGain)
		eff *= count
		if eff:
			yield effectAutoGain(eff, self.game, self.dbcGame, src='passport_shop_buy', yy_id=yyID)


# 资源找回
class YYRetrieveGet(RequestHandlerTask):
	url = r'/game/yy/retrieve/get'

	@coroutine
	def run(self):
		yyID = self.input.get('yyID', None)
		retrieveType = self.input.get('type', None)
		tab = self.input.get('tab', None)

		if yyID is None or retrieveType is None or tab is None:
			raise ClientError('prams miss')

		if tab not in ['free', 'rmb']:
			raise ClientError('prams tab error')

		role = self.game.role
		hdCls = ObjectYYHuoDongFactory.getRoleOpenClass(yyID, role.level, role.created_time, role.vip_level)
		if hdCls is None:
			raise ClientError(ErrDefs.huodongNoOpen)

		eff = hdCls.getEffect(yyID, self.game, retrieveType, tab)
		if eff:
			yield effectAutoGain(eff, self.game, self.dbcGame, src='retrieve_get', yy_id=yyID)

		self.write({'view': eff.result if eff else {}})


# 扭蛋机扭蛋
class LuckyEggDraw(RequestHandlerTask):
	url = r'/game/yy/lucky/egg/draw'

	@coroutine
	def run(self):
		yyID = self.input.get('yyID', None)
		drawType = self.input.get('drawType', None) # 'lucky_egg_free1' 'lucky_egg_rmb1' 'lucky_egg_rmb10'

		hdCls = ObjectYYHuoDongFactory.getRoleOpenClass(yyID, self.game.role.level, self.game.role.created_time, self.game.role.vip_level)
		if hdCls is None:
			raise ClientError(ErrDefs.huodongNoOpen)

		eff = hdCls.drawEgg(yyID, drawType, self.game)
		if eff:
			yield effectAutoGain(eff, self.game, self.dbcGame, src='draw_card_%s' % drawType, yy_id=yyID)
			self.write({'view': {'result': eff.result}})


# 活动红包列表
class YYHuodongRedPacketList(RequestHandlerTask):
	url = r'/game/yy/red/packet/list'

	@coroutine
	def run(self):
		yyID = ObjectYYHuoDongFactory.getYYHuoDongRedPacketID()
		if yyID is None:
			raise ClientError(ErrDefs.huodongNoOpen)
		hdCls = ObjectYYHuoDongFactory.getRoleOpenClass(yyID, self.game.role.level, self.game.role.created_time, self.game.role.vip_level)
		if hdCls is None:
			raise ClientError(ErrDefs.huodongNoOpen)

		ObjectServerGlobalRecord.refreshYYHuoDongRedPacket()
		redPackets = ObjectServerGlobalRecord.getYYHuoDongRedPackets()

		self.write({
			'view': {
				'packets': redPackets,
			},
		})


# 发活动红包
class YYHuodongRedPacketSend(RequestHandlerTask):
	url = r'/game/yy/red/packet/send'

	@coroutine
	def run(self):
		message = self.input.get('message', None)
		if not message:
			raise ClientError(ErrDefs.hdRedPacketMissMessage)
		yyID = ObjectYYHuoDongFactory.getYYHuoDongRedPacketID()
		if yyID is None:
			raise ClientError(ErrDefs.huodongNoOpen)
		hdCls = ObjectYYHuoDongFactory.getRoleOpenClass(yyID, self.game.role.level, self.game.role.created_time, self.game.role.vip_level)
		if hdCls is None:
			raise ClientError(ErrDefs.huodongNoOpen)

		if self.game.dailyRecord.huodong_redPacket_send >= self.game.role.huodongRedPacketSend:
			raise ClientError(ErrDefs.redPacketSendLimit)

		umsg = message.decode('utf8')
		if len(umsg) > 30:
			raise ClientError('too long')
		from framework.word_filter import filterName
		if filterName(umsg):
			raise ClientError('msg invalid')

		yyObj = ObjectYYHuoDongFactory.getRoleOpenConfig(yyID, self.game.role.level, self.game.role.created_time, self.game.role.vip_level)
		if yyObj is None:
			raise ClientError(ErrDefs.huodongNoOpen)
		paramMap = yyObj.paramMap
		totalVal, totalCount = paramMap['totalVal'], paramMap['totalCount']
		self.game.dailyRecord.huodong_redPacket_send += 1
		idx = ObjectServerGlobalRecord.sendMyYYHuoDongRedPacket(self.game, totalVal, totalCount, message)
		ObjectMessageGlobal.worldSendYYHuoDongRedPacketMsg(self.game, message, idx, yyID)

		ObjectServerGlobalRecord.refreshYYHuoDongRedPacket()
		redPackets = ObjectServerGlobalRecord.getYYHuoDongRedPackets()

		self.write({
			'view': {
				'packets': redPackets,
			},
		})


# 抢活动红包
class YYHuodongRedPacketRob(RequestHandlerTask):
	url = r'/game/yy/red/packet/rob'

	@coroutine
	def run(self):
		idx = self.input.get('idx', None)
		if idx is None:
			raise ClientError('miss idx')
		yyID = ObjectYYHuoDongFactory.getYYHuoDongRedPacketID()
		if yyID is None:
			raise ClientError(ErrDefs.huodongNoOpen)
		hdCls = ObjectYYHuoDongFactory.getRoleOpenClass(yyID, self.game.role.level, self.game.role.created_time, self.game.role.vip_level)
		if hdCls is None:
			raise ClientError(ErrDefs.huodongNoOpen)

		if self.game.dailyRecord.huodong_redPacket_rob >= self.game.role.huodongRedPacketRob:
			raise ClientError(ErrDefs.redPacketRoleRobLimit)

		info, val = ObjectServerGlobalRecord.robYYHuoDongRedPacket(self.game, idx)
		self.game.dailyRecord.huodong_redPacket_rob += 1
		award = {'rmb': val}
		eff = ObjectGainAux(self.game, award)
		yield effectAutoGain(eff, self.game, self.dbcGame, src='rob_hdredpacket', yy_id=yyID)

		ObjectServerGlobalRecord.refreshYYHuoDongRedPacket()
		redPackets = ObjectServerGlobalRecord.getYYHuoDongRedPackets()

		self.write({
			'view': {
				'packets': redPackets,
				'award': award,
				'info': info
			},
		})

# 符石置换
class YYHuoDongGemExchange(RequestHandlerTask):
	url = r'/game/yy/gem/exchange'

	@coroutine
	def run(self):
		yyID = self.input.get('yyID', None)
		gemIDs = self.input.get('gemIDs', None)  # [gemID,...]
		flag = self.input.get('flag', None)  # suitID / suitNo / blank

		if len(gemIDs) > 3:
			raise ClientError('too many gems')

		gems = self.game.gems.getGems(gemIDs)
		if not gemIDs or len(gemIDs) < 2 or len(gems) != len(gemIDs) or not flag or not yyID:
			raise ClientError('param miss')

		role = self.game.role
		hdCls = ObjectYYHuoDongFactory.getRoleOpenClass(yyID, role.level, role.created_time, role.vip_level)

		record = ObjectYYBase.getRecord(yyID, self.game)
		exchange_counter = record.get('info', {}).get('exchange_counter', 0)
		if exchange_counter >= csv.yunying.yyhuodong[yyID].paramMap[hdCls.ExchangeLimit]:
			raise ClientError('gem exchange limit up')

		flagGem = gems[0]
		flagCfg = csv.gem.gem[flagGem.gem_id]
		for gem in gems[1:]:
			if gem.card_db_id or flagGem.card_db_id:
				raise ClientError('gem equiped')
			cfg = csv.gem.gem[gem.gem_id]
			if cfg.quality < 4 or flagCfg.quality < 4:
				raise ClientError('gem quality too low')
			elif cfg.quality != flagCfg.quality:
				raise ClientError('gem quality not same')

			if flag == 'blank':
				continue
			else:
				if getattr(cfg, flag, None) != getattr(flagCfg, flag, None):
					raise ClientError('gem %s not same' % flag)

		eff = hdCls.exchangeGem(self.game, gems, flag, (getattr(flagCfg, flag, None), flagCfg.quality), yyID)
		if eff:
			yield effectAutoGain(eff, self.game, self.dbcGame, src='gem_exchange', yy_id=yyID)

		self.write({'view': {'result': eff.result}})

# 包粽子
class YYHuodongBaoZongzi(RequestHandlerTask):
	url = r'/game/yy/bao/zongzi'

	@coroutine
	def run(self):
		yyID = self.input.get('yyID', None)
		plans = self.input.get('plans', None)

		if yyID is None or plans is None:
			raise ClientError('prams miss')

		if isinstance(plans, list):
			plans = {k+1: v for k,v in enumerate(plans)}

		hdCls = ObjectYYHuoDongFactory.getRoleOpenClass(yyID, self.game.role.level, self.game.role.created_time, self.game.role.vip_level)
		if hdCls is None:
			raise ClientError(ErrDefs.huodongNoOpen)

		eff = hdCls.baoZongzi(yyID, plans, self.game)
		if eff:
			yield effectAutoGain(eff, self.game, self.dbcGame, src='yy_%d' % yyID, yy_id=yyID)

		self.write({'view': eff.result if eff else {}})


@coroutine
def getReunion(dbc, roleID):
	if not roleID:
		raise Return(None)
	game = ObjectGame.getByRoleID(roleID, safe=False)
	# 在线玩家
	if game:
		raise Return(game.reunionRecord)

	# 非在线玩家
	reunionDatas = yield dbc.call_async('DBReadBy', 'ReunionRecord', {'role_db_id': roleID})
	if not reunionDatas['ret']:
		raise Return(None)
	reunionData = reunionDatas['models'][0]
	reunion = ObjectReunionRecord(None, dbc).set(reunionData).init()
	raise Return(reunion)


# 重聚活动 推荐绑定
class YYHuodongReunionBindList(RequestHandlerTask):
	url = r'/game/yy/reunion/bind/list'

	@coroutine
	def run(self):
		listType = self.input.get('listType', None)
		if listType is None:
			raise ClientError('listType miss')
		if listType not in (ReunionDefs.Friend, ReunionDefs.Recommend):
			raise ClientError('listType error')
		ret = ObjectSocietyGlobal.getReunionRecommendList(self.game, listType)

		self.write({'view': {
			'roles': ret,
			'size': len(ret),
		}})


# 重聚活动绑定邀请
class YYHuodongReunionBindInvite(RequestHandlerTask):
	url = r'/game/yy/reunion/bind/invite'

	@coroutine
	def run(self):
		msgType = self.input.get('msgType', None)
		if msgType is None:
			raise ClientError('msgType miss')

		now = nowtime_t()
		record = self.game.role.reunion
		if not self.game.role.isReunionRoleOpen or record.get('role_type', None) != ReunionDefs.ReunionRole:
			raise ClientError(ErrDefs.huodongNoOpen)

		yyID = record['info']['yyID']
		if msgType == 'world':
			if now - self.game.role.reunion.get('world_invite_time', 0) < ReunionInviteCDTime:
				raise ClientError('world invite cd')
			self.game.role.reunion['world_invite_time'] = now
			ObjectMessageGlobal.worldReunionInvite(self.game, yyID, record['info']['end_time'])
		elif msgType == 'recommend':
			role = self.input.get('role', None)
			if now - self.game.role.reunion.setdefault('invite_time', {}).get(role['id'], 0) < ReunionInviteCDTime:
				raise ClientError('recommend invite cd')
			self.game.role.reunion['invite_time'][role['id']] = now
			msg = ObjectMessageGlobal.recommendReunionInvite(self.game, role, yyID, record['info']['end_time'])
			self.pushToRole('/game/push', {
				'msg': {'msgs': [msg]},
			}, role['id'])

		self.write({'view': {'result': True}})


# 重聚活动接受邀请
class YYHuodongReunionBindJoin(RequestHandlerTask):
	url = r'/game/yy/reunion/bind/join'

	@coroutine
	def run(self):
		roleID = self.input.get('roleID', None)
		yyID = self.input.get('yyID', None)
		endTime = self.input.get('endTime', 0)

		now = nowtime_t()
		if endTime <= now:
			raise ClientError('bind invitation expired')

		if not roleID or not yyID:
			raise ClientError('param miss')

		role = self.game.role
		if self.game.role.isReunionRoleOpen:
			raise ClientError('forbidden bind')
		if role.level < ConstDefs.seniorRoleLevel or role.top6_fighting_point < ConstDefs.seniorRoleFightingPoint:
			raise ClientError('condition not satisfy')
		if role.reunion.get('bind_cd', 0) > now:
			raise ClientError('bind in cd')

		hdCls = ObjectYYHuoDongFactory.getRoleOpenClass(yyID, role.level, role.created_time, role.vip_level)
		if hdCls is None:
			raise ClientError(ErrDefs.huodongNoOpen)

		cfg = csv.yunying.yyhuodong[yyID]

		if not ObjectReunionRecord.beginBinding(roleID):
			raise ClientError('other binding')
		try:
			reunion = yield getReunion(self.dbcGame, roleID)
			if not reunion:
				raise ClientError('reunion error')
			hdCls.acceptBindInvitation(self.game, yyID, cfg.huodongID, reunion)
			ObjectYYHuoDongFactory.refreshReunionRecord(self.game, reunion, TargetDefs.ReunionFriend, 0)
		finally:
			ObjectReunionRecord.endBinding(roleID)

		self.pushToRole('/game/push', {
			'model': {'reunion_record': reunion.model}
		}, roleID)

		self.write({'view': {'result': True}})


# 重聚 奖励领取
class YYHuodongReunionAwardGet(RequestHandlerTask):
	url = r'/game/yy/reunion/award/get'

	@coroutine
	def run(self):
		yyID = self.input.get('yyID', None)
		csvID = self.input.get('csvID', None)
		awardType = self.input.get('awardType', None)

		role = self.game.role
		hdCls = ObjectYYHuoDongFactory.getRoleOpenClass(yyID, role.level, role.created_time, role.vip_level)
		if hdCls is None:
			raise ClientError(ErrDefs.huodongNoOpen)

		eff = hdCls.getEffect(yyID, csvID, self.game, awardType)

		if eff:
			yield effectAutoGain(eff, self.game, self.dbcGame, src='yy_reunion_%d_type%d_award' % (yyID, awardType))

		view = {'result': eff.result if eff else {}}

		self.write({'view': view})


# 重聚 老玩家页面数据刷新
class YYHuodongReunionRecordGet(RequestHandlerTask):
	url = r'/game/yy/reunion/record/get'

	@coroutine
	def run(self):
		roleID = self.input.get('roleID', None)
		reunion = yield getReunion(self.dbcGame, roleID)

		self.write({
			'view': {'reunion_record': reunion.reunionModel if reunion else {}}
		})


# 获取活动兑换奖励
class YYExchangeAward(RequestHandlerTask):
	url = r'/game/yy/award/exchange'

	@coroutine
	def run(self):
		yyID = self.input.get('yyID', None)
		csvID = self.input.get('csvID', None)
		count = self.input.get('count', None) # 次数
		costID = self.input.get('costID', None)
		targetID = self.input.get('targetID', None)
		if count is not None and count <= 0:
			raise ClientError('param error')

		hdCls = ObjectYYHuoDongFactory.getRoleOpenClass(yyID, self.game.role.level, self.game.role.created_time, self.game.role.vip_level)
		if hdCls is None:
			raise ClientError(ErrDefs.huodongNoOpen)
		eff = hdCls.getEffect(yyID, csvID, self.game, costID, targetID, count)
		yield effectAutoGain(eff, self.game, self.dbcGame, src='yy_%d' % yyID, yy_id=yyID)

		view = {'result': eff.result if eff else {}}

		self.write({'view': view})


# 运营活动boss开始战斗
class YYHuodongBossStart(RequestHandlerTask):
	url = r'/game/yy/huodongboss/battle/start'

	@coroutine
	def run(self):
		cardIDs = self.input.get('cardIDs', None)
		idx = self.input.get('idx', None)
		yyID = self.input.get('yyID', None)

		if cardIDs is None or idx is None:
			raise ClientError('param miss')

		if not all([x is not None for x in [cardIDs, yyID, idx]]):
			raise ClientError('param miss')

		if yyID is None or yyID != ObjectYYHuoDongFactory.getYYHuoDongBossOpenID():
			raise ClientError(ErrDefs.huodongNoOpen)

		role = self.game.role
		hdCls = ObjectYYHuoDongFactory.getRoleOpenClass(yyID, role.level, role.created_time, role.vip_level)
		if hdCls is None:
			raise ClientError(ErrDefs.huodongNoOpen)

		hdCfg = hdCls.csvFromYYID(yyID)  # huodongboss_config

		rpc = ObjectServerGlobalRecord.huodongboss_cross_client()
		if not rpc:
			raise ClientError(ErrDefs.huodongNoOpen)
		bossInfo = yield rpc.call_async('HuoDongBossInfo', role.areaKey, idx, role.id)
		if bossInfo is None:
			raise ClientError(ErrDefs.huoDongBossNotExist)

		# 每日挑战次数限制
		if bossInfo['owner']['role_id'] != role.id and self.game.dailyRecord.huodong_boss_times >= hdCfg.dailyChallengeLimit:
			raise ClientError(ErrDefs.bossDailyChallengeLimit)

		# 战斗数据
		self.game.battle = ObjectYYHuoDongBossBattle(self.game)

		ret = self.game.battle.begin(cardIDs, yyID, bossInfo['gate_id'], idx)
		self.write({
			'model': ret
		})


# 运营活动boss结束战斗
class YYHuodongBossEnd(RequestHandlerTask):
	url = r'/game/yy/huodongboss/battle/end'

	@coroutine
	def run(self):
		battleID = self.input.get('battleID', None)
		result = self.input.get('result', None)
		idx = self.input.get('idx', None)
		yyID = self.input.get('yyID', None)
		damage = self.input.get('damage', None)

		if not all([x is not None for x in [battleID, yyID, result, idx]]):
			raise ClientError('param miss')

		if yyID != ObjectYYHuoDongFactory.getYYHuoDongBossOpenID():
			raise ClientError(ErrDefs.huodongNoOpen)

		role = self.game.role
		hdCls = ObjectYYHuoDongFactory.getRoleOpenClass(yyID, role.level, role.created_time, role.vip_level)
		if hdCls is None:
			raise ClientError(ErrDefs.huodongNoOpen)

		if battleID != self.game.battle.id:
			raise ClientError('battleID error')

		damage = int(damage)
		# 伤害保护
		if damage > self.game.battle.maxDamage():
			logger.warning("role %d gym fuben damage %d cheat can max %d", self.game.role.uid, damage, self.game.battle.maxDamage())
			raise ClientError(ErrDefs.rankCheat)
		if damage < 0:
			raise ClientError('damage error')

		if result == 'win':
			# 挑战成功 再次获取boss数据 检查是否可挑战
			rpc = ObjectServerGlobalRecord.huodongboss_cross_client()
			if not rpc:
				raise ClientError(ErrDefs.huodongNoOpen)
			try:
				ownerRoleID = yield rpc.call_async('HuoDongBossUpdate', role.areaKey, idx, hdCls.makeHuoDongBossRoleModel(role))
				# 挑战他人的活动才记录成功挑战次数
				if ownerRoleID and ownerRoleID != role.id:
					self.game.dailyRecord.huodong_boss_times += 1

			except ClientError, err:
				msg = err.log_message
				raise ClientError(msg)

		# 战斗结算
		eff = self.game.battle.result(result)
		if eff:
			yield effectAutoGain(eff, self.game, self.dbcGame, src='huodongboss_%s' % yyID)

		# 战斗结算完毕
		ret = self.game.battle.end()
		self.game.battle = None

		self.write(ret)


# 运营活动boss列表
class YYHuodongBossList(RequestHandlerTask):
	url = r'/game/yy/huodongboss/list'

	@coroutine
	def run(self):
		yyID = self.input.get('yyID', None)
		size = self.input.get('size', None)

		if yyID is None or yyID != ObjectYYHuoDongFactory.getYYHuoDongBossOpenID():
			raise ClientError(ErrDefs.huodongNoOpen)

		role = self.game.role
		hdCls = ObjectYYHuoDongFactory.getRoleOpenClass(yyID, role.level, role.created_time, role.vip_level)
		if hdCls is None:
			raise ClientError(ErrDefs.huodongNoOpen)
		hdCfg = hdCls.csvFromYYID(yyID)

		rpc = ObjectServerGlobalRecord.huodongboss_cross_client()
		if not rpc:
			raise ClientError(ErrDefs.huodongNoOpen)

		huodongboss = yield rpc.call_async('HuoDongBossList', role.areaKey, role.id, size)

		self.write({
			'view': {
				'csv_id': hdCfg.id,  	# huodongboss_config.csv
				'huodongboss': huodongboss,
			}
		})


# 双十一活动主界面
class YYDouble11Main(RequestHandlerTask):
	url = r'/game/yy/double11/main'

	@coroutine
	def run(self):
		yyID = self.input.get('yyID', None)
		hdCls = ObjectYYHuoDongFactory.getRoleOpenClass(yyID, self.game.role.level, self.game.role.created_time, self.game.role.vip_level)
		if hdCls is None:
			raise ClientError(ErrDefs.huodongNoOpen)

		# 运营活动奖励未领取
		effs = ObjectYYHuoDongFactory.getRoleRegainMails(self.game)
		for eff in effs:
			yield effectAutoGain(eff, self.game, self.dbcGame, src='yy_regain')

		self.write({
			'view': {
				'lotteryInfo': hdCls.getLotteryInfo(yyID)['win']
			}
		})

# 双十一小游戏开始
class YYDouble11GameStart(RequestHandlerTask):
	url = r'/game/yy/double11/game/start'

	@coroutine
	def run(self):
		yyID = self.input.get('yyID', None)

		hdCls = ObjectYYHuoDongFactory.getRoleOpenClass(yyID, self.game.role.level, self.game.role.created_time, self.game.role.vip_level)
		if hdCls is None:
			raise ClientError(ErrDefs.huodongNoOpen)

		hdCls.gameStart(yyID, self.game)

# 双十一小游戏结束
class YYDouble11GameEnd(RequestHandlerTask):
	url = r'/game/yy/double11/game/end'

	@coroutine
	def run(self):
		yyID = self.input.get('yyID', None)
		count = self.input.get('count', None)

		if count is None:
			raise ClientError('param miss')
		if count < 0:
			raise ClientError('param error')

		hdCls = ObjectYYHuoDongFactory.getRoleOpenClass(yyID, self.game.role.level, self.game.role.created_time, self.game.role.vip_level)
		if hdCls is None:
			raise ClientError(ErrDefs.huodongNoOpen)

		eff = hdCls.gameEnd(yyID, self.game, count)
		if eff:
			yield effectAutoGain(eff, self.game, self.dbcGame, src='yy_double11_%s' % yyID)

		self.write({
			'view': {
				'result': eff.result if eff else {}
			}
		})


# 双十一刮卡
class YYDouble11CardOpen(RequestHandlerTask):
	url = r'/game/yy/double11/card/open'

	@coroutine
	def run(self):
		yyID = self.input.get('yyID', None)
		gameCsvID = self.input.get('gameCsvID', None)

		if gameCsvID is None:
			raise ClientError('param miss')

		hdCls = ObjectYYHuoDongFactory.getRoleOpenClass(yyID, self.game.role.level, self.game.role.created_time, self.game.role.vip_level)
		if hdCls is None:
			raise ClientError(ErrDefs.huodongNoOpen)

		hdCls.cardOpen(yyID, gameCsvID, self.game)


# 活动装扮界面
class YYHuoDongClothMain(RequestHandlerTask):
	url = r'/game/yy/cloth/main'

	@coroutine
	def run(self):
		yyID = self.input.get('yyID', None)
		hdCls = ObjectYYHuoDongFactory.getRoleOpenClass(yyID, self.game.role.level, self.game.role.created_time, self.game.role.vip_level)
		if hdCls is None:
			raise ClientError(ErrDefs.huodongNoOpen)

		yyObj = ObjectYYHuoDongFactory.getConfig(yyID)
		record = hdCls.refreshRecord(yyObj, self.game)
		self.write({
			'view': {"record": record}
		})


# 活动装扮 升级
class YYHuoDongClothItemUse(RequestHandlerTask):
	url = r'/game/yy/cloth/item/use'

	@coroutine
	def run(self):
		yyID = self.input.get('yyID', None)

		hdCls = ObjectYYHuoDongFactory.getRoleOpenClass(yyID, self.game.role.level, self.game.role.created_time, self.game.role.vip_level)
		if hdCls is None:
			raise ClientError(ErrDefs.huodongNoOpen)

		yyObj = ObjectYYHuoDongFactory.getConfig(yyID)
		costItems = {}
		totalExp = 0
		for itemID in yyObj.paramMap['items']:
			count = self.game.items.getItemCount(itemID)
			if count > 0:
				costItems[itemID] = count
				itemCfg = csv.items[itemID]
				totalExp += (itemCfg.specialArgsMap['exp'] * count)

		if totalExp == 0:
			raise ClientError('no item use')

		itemEffD = self.game.items.getCostItems(costItems)
		if itemEffD is None:
			raise ClientError(ErrDefs.costNotEnough)

		ret = {}
		for itemID, itemEff in itemEffD.iteritems():
			yield effectAutoGain(itemEff, self.game, self.dbcGame, src='use_item_%d' % yyID)
			if isinstance(itemEff, ObjectGainAux):
				for k, v in itemEff.result.iteritems():
					if k not in ret:
						ret[k] = [v]
					else:
						ret[k].append(v)
		ret = {k: reduce(lambda x, y: x + y, v) for k, v in ret.iteritems()}

		record = hdCls.addExp(yyID, totalExp, self.game)

		self.write({
			'view': {
				"record": record,
				"result": ret,
			}
		})


# 活动装扮 换装
class YYHuoDongClothDecorate(RequestHandlerTask):
	url = r'/game/yy/cloth/decorate'

	@coroutine
	def run(self):
		yyID = self.input.get('yyID', None)
		part = self.input.get('part', None)
		csvID = self.input.get('csvID', None)

		hdCls = ObjectYYHuoDongFactory.getRoleOpenClass(yyID, self.game.role.level, self.game.role.created_time, self.game.role.vip_level)
		if hdCls is None:
			raise ClientError(ErrDefs.huodongNoOpen)

		if not part or not csvID:
			raise ClientError('param miss')

		hdCls.decorate(yyID, csvID, part, self.game)


# 躲雪球 主界面
class YYSnowBallMain(RequestHandlerTask):
	url = r'/game/yy/snowball/main'

	@coroutine
	def run(self):
		yyID = self.input.get('yyID', None)
		hdCls = ObjectYYHuoDongFactory.getRoleOpenClass(yyID, self.game.role.level, self.game.role.created_time, self.game.role.vip_level)
		if hdCls is None:
			raise ClientError(ErrDefs.huodongNoOpen)

		yyObj = ObjectYYHuoDongFactory.getConfig(yyID)
		record = hdCls.refreshRecord(yyObj, self.game)
		nowrank = yield ObjectRankGlobal.queryRank('snowball', self.game.role.id)
		if nowrank > 0 and record['info'].get('rank', 0) != nowrank:
			record['info']['rank'] = nowrank

		self.write({
			'view': {'record': record}
		})


# 躲雪球 游戏开始
class YYSnowBallStart(RequestHandlerTask):
	url = r'/game/yy/snowball/start'

	@coroutine
	def run(self):
		yyID = self.input.get('yyID', None)
		guide = self.input.get('guide', None)
		hdCls = ObjectYYHuoDongFactory.getRoleOpenClass(yyID, self.game.role.level, self.game.role.created_time, self.game.role.vip_level)
		if hdCls is None:
			raise ClientError(ErrDefs.huodongNoOpen)

		if not guide:
			hdCls.startSnowBallGame(yyID, self.game)


# 躲雪球 游戏结束
class YYSnowBallEnd(RequestHandlerTask):
	url = r'/game/yy/snowball/end'

	@coroutine
	def run(self):
		yyID = self.input.get('yyID', None)
		point = self.input.get('point', None)
		playTime = self.input.get('playTime', None)
		role = self.input.get('role', None)
		guide = self.input.get('guide', None)

		hdCls = ObjectYYHuoDongFactory.getRoleOpenClass(yyID, self.game.role.level, self.game.role.created_time, self.game.role.vip_level)
		if hdCls is None:
			raise ClientError(ErrDefs.huodongNoOpen)

		yyObj = ObjectYYHuoDongFactory.getConfig(yyID)
		if not guide:
			if point > yyObj.paramMap['pointMax']:
				raise ClientError(ErrDefs.cheatError)

			needRefresh = hdCls.endSnowBallGame(yyObj, point, playTime, role, self.game)
			# 刷新排行
			record = hdCls.getRecord(yyID, self.game)
			if needRefresh:
				yield ObjectRankGlobal.onKeyInfoChange(self.game, 'snowball', record['info'])

			rank = yield ObjectRankGlobal.queryRank("snowball", self.game.role.id)
			if rank > 0 and record['info'].get('rank', 0) != rank:
				logger.info('role %s snow ball point %s playTime %s rank from %s to %s', self.game.role.uid, point, playTime, record['info'].get('rank', 0), rank)
				record['info']['rank'] = rank
		else:
			record = hdCls.getRecord(yyID, self.game)
			record['info']['isGuide'] = 1
			record['info']['start'] = 0  # 引导局也会发start请求


# 躲雪球 购买次数
class YYSnowBallBuy(RequestHandlerTask):
	url = r'/game/yy/snowball/buy'

	@coroutine
	def run(self):
		yyID = self.input.get('yyID', None)

		hdCls = ObjectYYHuoDongFactory.getRoleOpenClass(yyID, self.game.role.level, self.game.role.created_time, self.game.role.vip_level)
		if hdCls is None:
			raise ClientError(ErrDefs.huodongNoOpen)

		record = hdCls.getRecord(yyID, self.game)
		yyObj = ObjectYYHuoDongFactory.getConfig(yyID)
		if record['info'].get('buy_times', 0) >= yyObj.paramMap['buyTimes']:
			raise ClientError('snowball buy times limit')

		costRMB = hdCls.getSnowBallBuyCost(yyObj, record['info'].get('buy_times', 0))
		cost = ObjectCostAux(self.game, {'rmb': costRMB})
		if not cost.isEnough():
			raise ClientError(ErrDefs.buyRMBNotEnough)
		cost.cost(src='snowball_buy')
		record['info']['buy_times'] = record['info'].get('buy_times', 0) + 1


# 摩天大楼排行榜
class YYSkyscraperRanking(RequestHandlerTask):
	url = r'/game/yy/skyscraper/ranking'

	@coroutine
	def run(self):
		yyID = self.input.get('yyID', None)
		hdCls = ObjectYYHuoDongFactory.getRoleOpenClass(yyID, self.game.role.level, self.game.role.created_time, self.game.role.vip_level)
		if hdCls is None:
			raise ClientError(ErrDefs.huodongNoOpen)

		record = hdCls.getRecord(yyID, self.game)
		rank, topScorers = yield ObjectServerGlobalRecord.getYYHuoDongCrossSkyscraperRanking(self.game)
		record['info']['rank'] = rank

		self.write({
			'view': {'top_scorers': topScorers, 'rank': rank}
		})


# 摩天大楼 游戏开始
class YYSkyscraperStart(RequestHandlerTask):
	url = r'/game/yy/skyscraper/start'

	@coroutine
	def run(self):
		yyID = self.input.get('yyID', None)
		hdCls = ObjectYYHuoDongFactory.getRoleOpenClass(yyID, self.game.role.level, self.game.role.created_time, self.game.role.vip_level)
		if hdCls is None:
			raise ClientError(ErrDefs.huodongNoOpen)
		hdCls.startSkyscraperGame(yyID, self.game)


# 摩天大楼 游戏结束
class YYSkyscraperEnd(RequestHandlerTask):
	url = r'/game/yy/skyscraper/end'

	@coroutine
	def run(self):
		yyID = self.input.get('yyID', None)
		points = self.input.get('points', 0)
		floors = self.input.get('floors', 0)
		perfections = self.input.get('perfections', 0)
		playTime = self.input.get('playTime', 0)
		numAwards = self.input.get('numAwards', 0)  # 得到了奖励的数量

		hdCls = ObjectYYHuoDongFactory.getRoleOpenClass(yyID, self.game.role.level, self.game.role.created_time, self.game.role.vip_level)
		if hdCls is None:
			raise ClientError(ErrDefs.huodongNoOpen)

		if any([i < 0 for i in [points, floors, perfections, playTime, numAwards]]):
			raise ClientError('bad params')

		yyObj = ObjectYYHuoDongFactory.getConfig(yyID)
		huodongID = yyObj.huodongID

		if floors > yyObj.paramMap['maxFloor']:
			raise ClientError('bad floors')

		changed = hdCls.endSkyscraperGame(yyObj, points, floors, perfections, self.game)

		# 获得随机奖励
		eff = ObjectGainEffect(self.game, {}, None)

		for floor in hdCls.FloorMap[huodongID][:numAwards]:
			eff += ObjectGainEffect(self.game, floor.awards, None)

		if eff:
			yield effectAutoGain(eff, self.game, self.dbcGame, src='yy_skyscraper_%s' % yyID)

		if changed:
			record = hdCls.getRecord(yyID, self.game)
			yield ObjectServerGlobalRecord.sendYYHuoDongCrossSkyscraperInfo(self.game, medallvl=max(0, 0, *record['stamps1'].keys()), highScore=record['info']['high_points'], highFloor=record['info']['high_floors'])

		self.write({'view':{'result': eff.result if eff else {}}})


# 摩天大楼 奖励领取
class YYSkyscraperAwards(RequestHandlerTask):
	url = r'/game/yy/skyscraper/awards'

	@coroutine
	def run(self):
		yyID = self.input.get('yyID', None)
		csvID = self.input.get('csvID', None)
		awardType = self.input.get('awardType', None)

		hdCls = ObjectYYHuoDongFactory.getRoleOpenClass(yyID, self.game.role.level, self.game.role.created_time, self.game.role.vip_level)
		if hdCls is None:
			raise ClientError(ErrDefs.huodongNoOpen)

		eff = hdCls.getEffect(yyID, csvID, awardType, self.game)
		yield effectAutoGain(eff, self.game, self.dbcGame, src='yy_%d' % yyID, yy_id=yyID)
		lvl = 0
		record = hdCls.getExistedRecord(yyID, self.game)
		keys = record['stamps1'].keys()
		if keys:
			lvl = max(keys)
		yield ObjectServerGlobalRecord.sendYYHuoDongCrossSkyscraperInfo(self.game, medallvl=lvl, highScore=record['info']['high_points'], highFloor=record['info']['high_floors'])

		view = {'result': eff.result if eff else {}}

		self.write({'view': view})


# 摩天大楼 购买次数
class YYSkyscraperBuy(RequestHandlerTask):
	url = r'/game/yy/skyscraper/buy'

	@coroutine
	def run(self):
		yyID = self.input.get('yyID', None)

		hdCls = ObjectYYHuoDongFactory.getRoleOpenClass(yyID, self.game.role.level, self.game.role.created_time, self.game.role.vip_level)
		if hdCls is None:
			raise ClientError(ErrDefs.huodongNoOpen)

		record = hdCls.getRecord(yyID, self.game)
		yyObj = ObjectYYHuoDongFactory.getConfig(yyID)
		if record['info'].get('buy_times', 0) >= yyObj.paramMap['buyTimes']:
			raise ClientError('skyscraper buy times limit')

		costRMB = hdCls.getBuyCost(yyObj, record['info'].get('buy_times', 0))
		cost = ObjectCostAux(self.game, {'rmb': costRMB})
		if not cost.isEnough():
			raise ClientError(ErrDefs.buyRMBNotEnough)
		cost.cost(src='skyscraper_buy')
		record['info']['buy_times'] = record['info'].get('buy_times', 0) + 1

# 活动跨服红包列表
class YYHuodongCrossRedPacketList(RequestHandlerTask):
	url = r'/game/yy/cross/red/packet/list'

	@coroutine
	def run(self):
		yyID = ObjectYYHuoDongFactory.getYYHuoDongCrossRedPacketID()
		if yyID is None:
			raise ClientError(ErrDefs.huodongNoOpen)
		hdCls = ObjectYYHuoDongFactory.getRoleOpenClass(yyID, self.game.role.level, self.game.role.created_time, self.game.role.vip_level)
		if hdCls is None:
			raise ClientError(ErrDefs.huodongNoOpen)


		redPackets = yield ObjectServerGlobalRecord.getYYHuoDongCrossRedPackets(self.game)
		self.write({
			'view': {
				'packets': redPackets,
			},
		})


# 发活跨服动红包
class YYHuodongCrossRedPacketSend(RequestHandlerTask):
	url = r'/game/yy/cross/red/packet/send'

	@coroutine
	def run(self):
		message = self.input.get('message', None)
		if not message:
			raise ClientError(ErrDefs.hdRedPacketMissMessage)
		yyID = ObjectYYHuoDongFactory.getYYHuoDongCrossRedPacketID()
		if yyID is None:
			raise ClientError(ErrDefs.huodongNoOpen)
		hdCls = ObjectYYHuoDongFactory.getRoleOpenClass(yyID, self.game.role.level, self.game.role.created_time, self.game.role.vip_level)
		if hdCls is None:
			raise ClientError(ErrDefs.huodongNoOpen)

		if self.game.dailyRecord.huodong_cross_redPacket_send >= self.game.role.huodongCrossRedPacketSend:
			raise ClientError(ErrDefs.redPacketSendLimit)

		umsg = message.decode('utf8')
		if len(umsg) > 30:
			raise ClientError('too long')
		from framework.word_filter import filterName
		if filterName(umsg):
			raise ClientError('msg invalid')

		yyObj = ObjectYYHuoDongFactory.getRoleOpenConfig(yyID, self.game.role.level, self.game.role.created_time, self.game.role.vip_level)
		if yyObj is None:
			raise ClientError(ErrDefs.huodongNoOpen)
		paramMap = yyObj.paramMap
		totalVal, totalCount = paramMap['totalVal'], paramMap['totalCount']
		self.game.dailyRecord.huodong_cross_redPacket_send += 1

		# 发红包
		idx, redPackets = yield ObjectServerGlobalRecord.sendMyYYHuoDongCrossRedPacket(self.game, totalVal, totalCount, message)
		# 发送世界消息
		ObjectMessageGlobal.worldSendYYHuoDongRedPacketMsg(self.game, message, idx, yyID)

		self.write({
			'view': {
				'packets': redPackets,
			},
		})


# 抢活动跨服红包
class YYHuodongCrossRedPacketRob(RequestHandlerTask):
	url = r'/game/yy/cross/red/packet/rob'

	@coroutine
	def run(self):
		idx = self.input.get('idx', None)
		if idx is None:
			raise ClientError('miss idx')
		yyID = ObjectYYHuoDongFactory.getYYHuoDongCrossRedPacketID()
		if yyID is None:
			raise ClientError(ErrDefs.huodongNoOpen)
		hdCls = ObjectYYHuoDongFactory.getRoleOpenClass(yyID, self.game.role.level, self.game.role.created_time, self.game.role.vip_level)
		if hdCls is None:
			raise ClientError(ErrDefs.huodongNoOpen)

		if self.game.dailyRecord.huodong_cross_redPacket_rob >= self.game.role.huodongCrossRedPacketRob:
			raise ClientError(ErrDefs.redPacketRoleRobLimit)

		info, val, redPackets = yield ObjectServerGlobalRecord.robYYHuoDongCrossRedPacket(self.game, idx)
		self.game.dailyRecord.huodong_cross_redPacket_rob += 1
		award = {'rmb': val}
		eff = ObjectGainAux(self.game, award)
		yield effectAutoGain(eff, self.game, self.dbcGame, src='cross_rob_hdredpacket', yy_id=yyID)

		self.write({
			'view': {
				'packets': redPackets,
				'award': award,
				'info': info
			},
		})


# 集福赢头奖 领取连线奖励
class YYLinkAward(RequestHandlerTask):
	url = r'/game/yy/link/award/get'

	@coroutine
	def run(self):
		yyID = self.input.get('yyID', None)
		awardID = self.input.get('awardID', None)

		hdCls = ObjectYYHuoDongFactory.getRoleOpenClass(yyID, self.game.role.level, self.game.role.created_time, self.game.role.vip_level)
		if hdCls is None:
			raise ClientError(ErrDefs.huodongNoOpen)

		eff = hdCls.getLinkAwardEffect(yyID, self.game, awardID)
		yield effectAutoGain(eff, self.game, self.dbcGame, src='yy_%d' % yyID, yy_id=yyID)

		self.write({'view': eff.result if eff else {}})

# 春节返还领取奖励
class YYRMBGoldReturn(RequestHandlerTask):
	url = r'/yy/rmbgold/return'
	uri = 10048

	@coroutine
	def run(self):
		yyID = self.input.get('yyID', None)

		if yyID is None:
			raise ClientError('params miss')
		hdCls = ObjectYYHuoDongFactory.getRoleOpenClass(yyID, self.game.role.level, self.game.role.created_time, self.game.role.vip_level)
		if hdCls is None:
			raise ClientError(ErrDefs.huodongNoOpen)

		if not hdCls.isReturnTime(ObjectYYHuoDongFactory.getConfig(yyID), self.game):
			raise ClientError('Not return time yet')

		eff = hdCls.getReturn(yyID, self.game)
		if eff:
			yield effectAutoGain(eff, self.game, self.dbcGame, src='rmb_gold_return')

		self.write({'view': eff.result if eff else {}})

# 走格子使用道具
class YYGridWalkItemUse(RequestHandlerTask):
	url = r'/game/yy/gridwalk/itemuse'

	@coroutine
	def run(self):
		yyID = self.input.get('yyID', None)
		itemID = self.input.get('itemID', None)

		if any([x is None for x in (yyID, itemID)]):
			raise ClientError('params miss')
		hdCls = ObjectYYHuoDongFactory.getRoleOpenClass(yyID, self.game.role.level, self.game.role.created_time, self.game.role.vip_level)
		if hdCls is None:
			raise ClientError(ErrDefs.huodongNoOpen)
		yyObj = ObjectYYHuoDongFactory.getRoleOpenConfig(yyID, self.game.role.level, self.game.role.created_time, self.game.role.vip_level)

		eff, effTreasure = hdCls.runEffect(yyObj, self.game, ignore=True)
		if eff:
			yield effectAutoGain(eff, self.game, self.dbcGame, src='yy_gridwalk_item_gain')
		if effTreasure:
			yield effectAutoGain(effTreasure, self.game, self.dbcGame, src='yy_gridwalk_treasure')

		hdCls.itemUse(yyObj, self.game, itemID)

		eff, effTreasure = hdCls.runEffect(yyObj, self.game, ignore=False)
		if eff:
			yield effectAutoGain(eff, self.game, self.dbcGame, src='yy_gridwalk_item_gain')
		if effTreasure:
			yield effectAutoGain(effTreasure, self.game, self.dbcGame, src='yy_gridwalk_treasure')

		self.write({'view': {'effTreasure': effTreasure.result if effTreasure else {}, 'itemID': itemID}})


class YYGridWalkShop(RequestHandlerTask):
	url = r'/game/yy/gridwalk/shop'

	@coroutine
	def run(self):
		yyID = self.input.get('yyID', None)
		itemID = self.input.get('itemID', None)
		coupon_used = self.input.get('coupon_used', None)
		index = self.input.get('index', None)

		if any([x is None for x in (yyID, itemID, coupon_used, index)]):
			raise ClientError('params miss')
		hdCls = ObjectYYHuoDongFactory.getRoleOpenClass(yyID, self.game.role.level, self.game.role.created_time, self.game.role.vip_level)
		if hdCls is None:
			raise ClientError(ErrDefs.huodongNoOpen)
		yyObj = ObjectYYHuoDongFactory.getRoleOpenConfig(yyID, self.game.role.level, self.game.role.created_time, self.game.role.vip_level)

		e = hdCls.shop(yyObj, self.game, itemID, index, coupon_used)
		if e:
			yield effectAutoGain(e, self.game, self.dbcGame, src='yy_gridwalk_shop_gain')

		eff, effTreasure = hdCls.runEffect(yyObj, self.game, ignore=False)  # 商店完成，继续生效effect
		if eff:
			yield effectAutoGain(eff, self.game, self.dbcGame, src='yy_gridwalk_item_gain')
		if effTreasure:
			yield effectAutoGain(effTreasure, self.game, self.dbcGame, src='yy_gridwalk_treasure')

		self.write({'view':{'awards': e.result if e else {}, 'effTreasure': effTreasure.result if effTreasure else {}}})


class YYGridWalkMain(RequestHandlerTask):
	url = r'/game/yy/gridwalk/main'

	@coroutine
	def run(self):
		yyID = self.input.get('yyID', None)
		if yyID is None:
			raise ClientError('params miss')
		hdCls = ObjectYYHuoDongFactory.getRoleOpenClass(yyID, self.game.role.level, self.game.role.created_time, self.game.role.vip_level)
		if hdCls is None:
			raise ClientError(ErrDefs.huodongNoOpen)
		yyObj = ObjectYYHuoDongFactory.getRoleOpenConfig(yyID, self.game.role.level, self.game.role.created_time, self.game.role.vip_level)
		eff, effTreasure = hdCls.runEffect(yyObj, self.game, ignore=True)
		if eff:
			yield effectAutoGain(eff, self.game, self.dbcGame, src='yy_gridwalk_item_gain')
		if effTreasure:
			yield effectAutoGain(effTreasure, self.game, self.dbcGame, src='yy_gridwalk_treasure')

		hdCls.getThisAction(yyObj, self.game)  # 重新登录如果上一回合已经结束，刷新回合、生效effect、添加上回合记录


# 玩法通行证 购买等级
class YYPlayPassportExpBuy(RequestHandlerTask):
	url = r'/game/yy/playpassport/exp/buy'

	@coroutine
	def run(self):
		yyID = self.input.get('yyID', None)
		level = self.input.get('level', None)

		role = self.game.role
		hdCls = ObjectYYHuoDongFactory.getRoleOpenClass(yyID, role.level, role.created_time, role.vip_level)
		if hdCls is None:
			raise ClientError(ErrDefs.huodongNoOpen)
		if not level:
			raise ClientError('level prams miss')

		hdCls.buyPlayPassportLevel(self.game, yyID, level)


# 赛马主界面
class YYHorseRaceMain(RequestHandlerTask):
	url = r'/game/yy/horse/race/main'

	@coroutine
	def run(self):
		yyID = self.input.get('yyID', None)

		role = self.game.role
		hdCls = ObjectYYHuoDongFactory.getRoleOpenClass(yyID, role.level, role.created_time, role.vip_level)
		if hdCls is None:
			raise ClientError(ErrDefs.huodongNoOpen)
		yyObj = ObjectYYHuoDongFactory.getConfig(yyID)
		hdCls.refreshRecord(yyObj, self.game)

		rpcHorse = ObjectServerGlobalRecord.horse_race_cross_client()
		if not rpcHorse:
			raise ClientError("crosshorse is None")

		model = yield rpcHorse.call_async("HorseRaceMain")
		history = model.get("history", {})
		isAdd, point = hdCls.refreshBetAward(yyID, self.game, history)
		if isAdd and point > 0:
			yield ObjectServerGlobalRecord.sendRankingInfo(self.game, CrossHorseRaceRanking, role.crossRankRoleInfo(rankData=[point]))
		self.write({'view': model})


# 赛马押注
class YYHorseRaceBet(RequestHandlerTask):
	url = r'/game/yy/horse/race/bet'

	@coroutine
	def run(self):
		yyID = self.input.get('yyID', None)
		date = self.input.get('date', None)  # 第几天
		play = self.input.get('play', None)  # 第几场
		csvID = self.input.get('csvID', None)  # 哪个卡牌

		role = self.game.role
		hdCls = ObjectYYHuoDongFactory.getRoleOpenClass(yyID, role.level, role.created_time, role.vip_level)
		if hdCls is None:
			raise ClientError(ErrDefs.huodongNoOpen)
		if not all([x is not None for x in [date, play, csvID]]):
			raise ClientError('param miss')

		hdCls.isCanBetCard(yyID, self.game, date, play)

		cost = ObjectCostAux(self.game, {'rmb': ConstDefs.horseRaceBetCost})
		if not cost.isEnough():
			raise ClientError(ErrDefs.buyRMBNotEnough)

		rpcHorse = ObjectServerGlobalRecord.horse_race_cross_client()
		if not rpcHorse:
			raise ClientError("crosshorse is None")

		idx = yield rpcHorse.call_async("HorseRaceBet", self.game.role.id, date, play, csvID)
		if idx == -1:
			raise ClientError('no find csvID')

		cost.cost(src='horse_race_bet')
		hdCls.setBetCard(yyID, self.game, date, play, idx)

		model = yield rpcHorse.call_async("HorseRaceMain")
		self.write({'view': model})


# 赛马回放
class YYHorseRacePlay(RequestHandlerTask):
	url = r'/game/yy/horse/race/playback'

	@coroutine
	def run(self):
		yyID = self.input.get('yyID', None)
		date = self.input.get('date', None)  # 第几天
		play = self.input.get('play', None)  # 第几场

		role = self.game.role
		hdCls = ObjectYYHuoDongFactory.getRoleOpenClass(yyID, role.level, role.created_time, role.vip_level)
		if hdCls is None:
			raise ClientError(ErrDefs.huodongNoOpen)
		if not all([x is not None for x in [date, play]]):
			raise ClientError('param miss')

		rpcHorse = ObjectServerGlobalRecord.horse_race_cross_client()
		if not rpcHorse:
			raise ClientError("crosshorse is None")
		model = yield rpcHorse.call_async("HorseRacePlayback", date, play)

		self.write({'view': model})


# 赛马积分奖励
class YYHorseRacePointAward(RequestHandlerTask):
	url = r'/game/yy/horse/race/point/award'

	@coroutine
	def run(self):
		yyID = self.input.get('yyID', None)
		csvID = self.input.get('csvID', None)

		role = self.game.role
		hdCls = ObjectYYHuoDongFactory.getRoleOpenClass(yyID, role.level, role.created_time, role.vip_level)
		if hdCls is None:
			raise ClientError(ErrDefs.huodongNoOpen)
		if csvID is None:
			raise ClientError('csvID miss')
		if csvID not in csv.yunying.horse_race_point_award:
			raise ClientError('csvID error')

		eff = hdCls.getPointAwardEffect(yyID, self.game, csvID)
		ret = {}
		if eff:
			yield effectAutoGain(eff, self.game, self.dbcGame, src='yy_%d_horseRace_point_award' % yyID, yy_id=yyID)
			ret = eff.result

		self.write({'view': ret})


# 赛马押注奖励
class YYHorseRaceBetAward(RequestHandlerTask):
	url = r'/game/yy/horse/race/bet/award'

	@coroutine
	def run(self):
		yyID = self.input.get('yyID', None)
		date = self.input.get('date', None)  # 第几天
		play = self.input.get('play', None)  # 第几场

		role = self.game.role
		hdCls = ObjectYYHuoDongFactory.getRoleOpenClass(yyID, role.level, role.created_time, role.vip_level)
		if hdCls is None:
			raise ClientError(ErrDefs.huodongNoOpen)
		if not all([x is not None for x in [date, play]]):
			raise ClientError('param miss')

		eff = hdCls.getBetAwardEffect(yyID, self.game, date, play)
		ret = {}
		if eff:
			yield effectAutoGain(eff, self.game, self.dbcGame, src='yy_%d_horseRace_bet_award' % yyID, yy_id=yyID)
			ret = eff.result

		self.write({'view': ret})


# 赛马排行榜
class YYHorseRaceRank(RequestHandlerTask):
	url = r'/game/yy/horse/race/rank'

	@coroutine
	def run(self):
		yyID = self.input.get('yyID', None)

		role = self.game.role
		hdCls = ObjectYYHuoDongFactory.getRoleOpenClass(yyID, role.level, role.created_time, role.vip_level)
		if hdCls is None:
			raise ClientError(ErrDefs.huodongNoOpen)

		ret = yield ObjectServerGlobalRecord.getRankingInfo(self.game, CrossHorseRaceRanking)

		self.write({
			'view': {'my_rank': ret.get('rank', 0), 'ranking': ret.get('ranking', [])}
		})


# 勇者挑战 主界面
class BraveChallengeMain(RequestHandlerTask):
	url = r"/game/yy/brave_challenge/main"

	@coroutine
	def run(self):
		yyID = self.input.get("yyID", None)

		role = self.game.role
		hdCls = ObjectYYHuoDongFactory.getRoleOpenClass(yyID, role.level, role.created_time, role.vip_level)
		if hdCls is None:
			raise ClientError(ErrDefs.huodongNoOpen)

		if role.brave_challenge_record_db_id is None:
			record = yield self.rpcYYHuodong.call_async("BraveChallengeCreateRecord", role.id, yyID)
			role.brave_challenge_record_db_id = record["id"]
		else:
			record = yield self.rpcYYHuodong.call_async("BraveChallengeGetRecord", role.brave_challenge_record_db_id, role.id, yyID, 0)

		hdCls.refreshRecord(yyID, self.game)

		record["baseCfgID"] = 1
		self.write({"model": {"brave_challenge": record}})


# 勇者挑战 开始准备
class BraveChallengePrepareStart(RequestHandlerTask):
	url = r"/game/yy/brave_challenge/prepare/start"

	@coroutine
	def run(self):
		yyID = self.input.get("yyID", None)
		role = self.game.role
		hdCls = ObjectYYHuoDongFactory.getRoleOpenClass(yyID, role.level, role.created_time, role.vip_level)
		if hdCls is None:
			raise ClientError(ErrDefs.huodongNoOpen)

		if hdCls.isTimesLimit(self.game, yyID):
			raise ClientError("daily brave challenge times limit up")

		data = yield self.rpcYYHuodong.call_async("BraveChallengeStartPrepare", role.brave_challenge_record_db_id, role.id, yyID, 0)
		self.write({"view": data})


# 勇者挑战 结束准备
class BraveChallengePrepareEnd(RequestHandlerTask):
	url = r"/game/yy/brave_challenge/prepare/end"

	@coroutine
	def run(self):
		yyID = self.input.get("yyID", None)
		role = self.game.role
		hdCls = ObjectYYHuoDongFactory.getRoleOpenClass(yyID, role.level, role.created_time, role.vip_level)
		if hdCls is None:
			raise ClientError(ErrDefs.huodongNoOpen)

		cards = self.input.get("cards", None)
		if not cards or len(cards) != 3:
			raise ClientError("cards num should be 3")

		cards = sorted(cards)
		record = yield self.rpcYYHuodong.call_async("BraveChallengeEndPrepare", role.brave_challenge_record_db_id, role.id, yyID, cards, 0)

		if not record.get('game', {}).get('new_badges', []):
			flag, weight = hdCls.isTodayFirst(self.game, yyID)
			if flag:
				record = yield self.rpcYYHuodong.call_async("BraveChallengeRandomBadge", role.brave_challenge_record_db_id, role.id, yyID, weight, -1, 0)

		hdCls.addTimes(self.game, yyID)
		self.write({"model": {"brave_challenge": record}})


# 勇者挑战 布阵
class BraveChallengeDelpoy(RequestHandlerTask):
	url = r"/game/yy/brave_challenge/deploy"

	@coroutine
	def run(self):
		if self.game.role.brave_challenge_record_db_id is None:
			raise ClientError(ErrDefs.huodongNoOpen)

		role = self.game.role
		yyID = self.input.get("yyID", None)
		hdCls = ObjectYYHuoDongFactory.getRoleOpenClass(yyID, role.level, role.created_time, role.vip_level)
		if hdCls is None:
			raise ClientError(ErrDefs.huodongNoOpen)

		cards = self.input.get("cards", None)
		if cards:
			cards = hdCls.transform2list(cards)
		else:
			raise ClientError("cards miss")

		record = yield self.rpcYYHuodong.call_async("BraveChallengeDeploy", role.brave_challenge_record_db_id, role.id, yyID, cards, 0)
		self.write({"model": {"brave_challenge": record}})


# 勇者挑战 开始战斗
class BraveChallengeBattleStart(RequestHandlerTask):
	url = r"/game/yy/brave_challenge/battle/start"

	@coroutine
	def run(self):
		if self.game.role.brave_challenge_record_db_id is None:
			raise ClientError(ErrDefs.huodongNoOpen)

		role = self.game.role
		yyID = self.input.get("yyID", None)
		hdCls = ObjectYYHuoDongFactory.getRoleOpenClass(yyID, role.level, role.created_time, role.vip_level)
		if hdCls is None:
			raise ClientError(ErrDefs.huodongNoOpen)

		cards = self.input.get("cards", None)  # csvIDs
		floorID = self.input.get("floorID", 0)
		monsterID = self.input.get("monsterID", 0)

		if cards:
			cards = hdCls.transform2list(cards)
			yield self.rpcYYHuodong.call_async("BraveChallengeDeploy", role.brave_challenge_record_db_id, role.id, yyID, cards, 0)

		# 额外的加成
		extraAttrBonus = ObjectYYBraveChallenge.extraAttrBonus(yyID, self.game, cards)
		battleModel = yield self.rpcYYHuodong.call_async("BraveChallengeStartBattle", role.brave_challenge_record_db_id, role.id, yyID, floorID, monsterID, extraAttrBonus, 0)
		battleModel["level"] = self.game.role.level
		self.game.battle = battleModel
		self.write({
			"model": {"brave_challenge_battle": battleModel}
		})


# 勇者挑战 结束战斗
class BraveChallengeBattleEnd(RequestHandlerTask):
	url = r"/game/yy/brave_challenge/battle/end"

	@coroutine
	def run(self):
		if self.game.role.brave_challenge_record_db_id is None:
			raise ClientError(ErrDefs.huodongNoOpen)

		role = self.game.role
		battleID = self.input.get("battleID", None)
		if self.game.battle["id"] != battleID:
			raise ClientError("battleID error")

		floorID = self.input.get("floorID", None)
		if self.game.battle["floorID"] != floorID:
			raise ClientError("floorID error")

		result = self.input.get('result', None)
		cardStates = self.input.get('cardStates', None)
		monsterStates = self.input.get('monsterStates', None)  # {document.id: [hp, mp]}
		battleRound = self.input.get('battleRound', None)
		damage = self.input.get("damage", None)
		actions = self.input.get('actions', None)
		if isinstance(actions, list):
			actions = {idx + 1: v for idx, v in enumerate(actions)}

		if any([x is None for x in [result, cardStates, monsterStates, battleRound, actions]]):
			raise ClientError('param miss')

		cardstates = {}
		if isinstance(cardStates, list):
			for idx, state in enumerate(cardStates, 1):
				cardstates[idx] = state
		else:
			cardstates = cardStates

		formerMonsterStates = {}
		for idx, cardID in enumerate(self.game.battle['defence_cards'], 1):
			if cardID in monsterStates:
				formerMonsterStates[idx] = monsterStates[cardID]

		yyID = ObjectYYHuoDongFactory.getBraveChallengeOpenID()
		# 战斗结算 跨天也正常结算
		data = {
			"floorID": floorID,
			"result": result,
			"card_states": cardstates,
			"monster_states": formerMonsterStates,
			"battle_round": battleRound,
			"damage": damage,
		}
		resp = yield self.rpcYYHuodong.call_async("BraveChallengeEndBattle", role.brave_challenge_record_db_id, role.id, yyID, data, 0)
		hdCls = ObjectYYHuoDongFactory.getRoleOpenClass(yyID, role.level, role.created_time, role.vip_level)

		yyObj = ObjectYYHuoDongFactory.getConfig(yyID)
		basecfg = csv.brave_challenge.base[yyObj.paramMap.get('baseCfg', 1)]

		eff = ObjectGainAux(self.game, {})
		extraEff = None
		if result == "win":
			cfg = csv.brave_challenge.floor[floorID]
			if resp["first_pass"]:
				eff += ObjectGainAux(self.game, cfg.firstAward)  # 首通额外奖励
			eff += hdCls.getGold(yyID, self.game, cfg.repeatAward)
			if cfg.extraAward and resp["all_pass"]:
				extraEff = ObjectGainAux(self.game, cfg.extraAward)

		if eff:
			yield effectAutoGain(eff, self.game, self.dbcGame, src="brave_challenge_gate")
		if extraEff:
			yield effectAutoGain(extraEff, self.game, self.dbcGame, src="brave_challenge_gate_extra")

		yyObj = ObjectYYHuoDongFactory.getConfig(yyID)

		if resp["all_pass"]:
			# 通关次数
			hdCls.active(yyObj, self.game, BraveChallengeDefs.PassTimes, 1)

		# 击杀
		hdCls.active(yyObj, self.game, BraveChallengeDefs.KillCount, resp["kill"])
		# 阵亡
		hdCls.active(yyObj, self.game, BraveChallengeDefs.DieCount, resp["die"])
		# 解锁卡池
		if len(resp["record"]["add"]):
			for cardID in resp["record"]["add"]:
				hdCls.active(yyObj, self.game, BraveChallengeDefs.UnlockCard, cardID)

		ret = {
			"model": {"brave_challenge": resp["record"]},
			"view": {"award": eff.result, "all_pass": resp["all_pass"], "first_pass": resp["first_pass"], "extra_award": extraEff.result if extraEff else None},
		}
		self.write(ret)

		self.game.battle = None

		if resp["all_pass"] and resp["refresh"]:
			# 通关消耗回合数
			hdCls.active(yyObj, self.game, BraveChallengeDefs.PassRound, resp["rank_info"]["round"])

			model = self.game.role.makeBraveChallengeRankModel(resp)
			yield ObjectServerGlobalRecord.sendRankingInfo(self.game, CrossBraveChallengeRanking, model)


# 勇者挑战 选择徽章
class BraveChallengeChoose(RequestHandlerTask):
	url = r"/game/yy/brave_challenge/badge/choose"

	@coroutine
	def run(self):
		if self.game.role.brave_challenge_record_db_id is None:
			raise ClientError(ErrDefs.huodongNoOpen)

		role = self.game.role
		yyID = self.input.get("yyID", None)
		hdCls = ObjectYYHuoDongFactory.getRoleOpenClass(yyID, role.level, role.created_time, role.vip_level)
		if hdCls is None:
			raise ClientError(ErrDefs.huodongNoOpen)

		badgeID = self.input.get("badgeID", None)
		record = yield self.rpcYYHuodong.call_async("BraveChallengeChooseBadge", role.brave_challenge_record_db_id, role.id, yyID, badgeID, 0)
		yyObj = ObjectYYHuoDongFactory.getConfig(yyID)
		# 累计获得勋章
		hdCls.active(yyObj, self.game, BraveChallengeDefs.GainBadge, 1)
		# 解锁卡池
		if len(record["add"]):
			for cardID in record["add"]:
				hdCls.active(yyObj, self.game, BraveChallengeDefs.UnlockCard, cardID)

		self.write({"model": {"brave_challenge": record}})


# 勇者挑战 认输
class BraveChallengeQuit(RequestHandlerTask):
	url = r"/game/yy/brave_challenge/quit"

	@coroutine
	def run(self):
		if self.game.role.brave_challenge_record_db_id is None:
			raise ClientError(ErrDefs.huodongNoOpen)

		role = self.game.role
		yyID = self.input.get("yyID", None)
		hdCls = ObjectYYHuoDongFactory.getRoleOpenClass(yyID, role.level, role.created_time, role.vip_level)
		if hdCls is None:
			raise ClientError(ErrDefs.huodongNoOpen)

		record = yield self.rpcYYHuodong.call_async("BraveChallengeQuit", role.brave_challenge_record_db_id, role.id, yyID, 0)
		# 解锁卡池
		if len(record["add"]) > 0:
			yyObj = ObjectYYHuoDongFactory.getConfig(yyID)
			for cardID in record["add"]:
				hdCls.active(yyObj, self.game, BraveChallengeDefs.UnlockCard, cardID)

		self.write({"model": {"brave_challenge": record}})


# 勇者挑战 购买次数
class BraveChallengeBuy(RequestHandlerTask):
	url = r"/game/yy/brave_challenge/buy"

	@coroutine
	def run(self):
		if self.game.role.brave_challenge_record_db_id is None:
			raise ClientError(ErrDefs.huodongNoOpen)

		role = self.game.role
		yyID = self.input.get("yyID", None)
		hdCls = ObjectYYHuoDongFactory.getRoleOpenClass(yyID, role.level, role.created_time, role.vip_level)
		if hdCls is None:
			raise ClientError(ErrDefs.huodongNoOpen)

		yyObj = ObjectYYHuoDongFactory.getConfig(yyID)

		if not hdCls.checkBuyTimes(self.game, yyID):
			raise ClientError("brave challenge buy times limit")

		costRMB = hdCls.getBuyCost(self.game, yyID)
		cost = ObjectCostAux(self.game, {'rmb': costRMB})
		if not cost.isEnough():
			raise ClientError(ErrDefs.buyRMBNotEnough)
		cost.cost(src='brave_challenge_buy')
		hdCls.addBuyTimes(self.game, yyID)


# 勇者挑战 排行榜
class BraveChallengeRank(RequestHandlerTask):
	url = r"/game/yy/brave_challenge/rank"

	@coroutine
	def run(self):
		if self.game.role.brave_challenge_record_db_id is None:
			raise ClientError(ErrDefs.huodongNoOpen)

		role = self.game.role
		yyID = self.input.get("yyID", None)
		hdCls = ObjectYYHuoDongFactory.getRoleOpenClass(yyID, role.level, role.created_time, role.vip_level)
		if hdCls is None:
			raise ClientError(ErrDefs.huodongNoOpen)

		resp = yield ObjectServerGlobalRecord.getRankingInfo(self.game, CrossBraveChallengeRanking)

		self.write({
			"view":  resp,
		})


# 五一派遣 开始派遣
class YYDispatchBegin(RequestHandlerTask):
	url = r"/game/yy/dispatch/begin"

	@coroutine
	def run(self):
		yyID = self.input.get("yyID", None)
		role = self.game.role
		hdCls = ObjectYYHuoDongFactory.getRoleOpenClass(yyID, role.level, role.created_time, role.vip_level)
		if hdCls is None:
			raise ClientError(ErrDefs.huodongNoOpen)
		yyObj = ObjectYYHuoDongFactory.getConfig(yyID)

		csvID = self.input.get("csvID", None)
		cardIDs = self.input.get("cards", [])
		hdCls.beginDispatch(self.game, yyObj, csvID, cardIDs)

		# 宝箱类型则立即获得奖励
		if csv.yunying.dispatch[csvID].type == YYDispatchDefs.AwardBox:
			eff = hdCls.endDispatch(self.game, yyObj, csvID, False)
			if eff:
				yield effectAutoGain(eff, self.game, self.dbcGame, src="yy_%d_dispatch" % yyID)
			self.write({"view": {"result": eff.result}})


# 五一派遣 结束派遣
class YYDispatchEnd(RequestHandlerTask):
	url = r"/game/yy/dispatch/end"

	@coroutine
	def run(self):
		yyID = self.input.get("yyID", None)
		role = self.game.role
		hdCls = ObjectYYHuoDongFactory.getRoleOpenClass(yyID, role.level, role.created_time, role.vip_level)
		if hdCls is None:
			raise ClientError(ErrDefs.huodongNoOpen)

		csvID = self.input.get("csvID", None)
		flag = self.input.get("flag", None)  # 是否放弃
		if csvID is None or flag is None:
			raise ClientError("param miss")

		yyObj = ObjectYYHuoDongFactory.getConfig(yyID)
		eff = hdCls.endDispatch(self.game, yyObj, csvID, flag)
		if eff:
			yield effectAutoGain(eff, self.game, self.dbcGame, src="yy_%d_dispatch" % yyID)

		self.write({"view": {"result": eff.result}})


# 沙滩排球 开始游戏
class YYVolleyballStart(RequestHandlerTask):
	url = r"/game/yy/volleyball/start"

	@coroutine
	def run(self):
		yyID = self.input.get('yyID', None)
		role = self.game.role
		hdCls = ObjectYYHuoDongFactory.getRoleOpenClass(yyID, role.level, role.created_time, role.vip_level)
		if hdCls is None:
			raise ClientError(ErrDefs.huodongNoOpen)

		hdCls.recordStartTime(yyID, self.game)


# 沙滩排球 结束游戏
class YYVolleyballEnd(RequestHandlerTask):
	url = r"/game/yy/volleyball/end"

	@coroutine
	def run(self):
		role = self.game.role
		yyID = self.input.get("yyID", None)
		result = self.input.get("result", None)
		tasks = self.input.get("tasks", None)
		duration = self.input.get("duration", None)

		yyObj = ObjectYYHuoDongFactory.getConfig(yyID)

		hdCls = ObjectYYHuoDongFactory.getRoleOpenClass(yyID, role.level, role.created_time, role.vip_level)
		if hdCls is None:
			raise ClientError(ErrDefs.huodongNoOpen)

		if hdCls.isCheat(yyObj, self.game, duration):
			raise ClientError(ErrDefs.volleyballBanned)

		allVic = hdCls.refreshTasks(yyObj, self.game, result, tasks)

		if result == 'win':
			yield ObjectServerGlobalRecord.sendRankingInfo(self.game, CrossVolleyballlRanking, role.crossRankRoleInfo(rankData=[allVic]))


# 沙滩排球 排行榜
class YYVolleyballRank(RequestHandlerTask):
	url = r"/game/yy/volleyball/rank"

	@coroutine
	def run(self):
		yyID = self.input.get('yyID', None)
		role = self.game.role
		hdCls = ObjectYYHuoDongFactory.getRoleOpenClass(yyID, role.level, role.created_time, role.vip_level)
		if hdCls is None:
			raise ClientError(ErrDefs.huodongNoOpen)

		resp = yield ObjectServerGlobalRecord.getRankingInfo(self.game, CrossVolleyballlRanking)

		self.write({
			"view":  resp,
		})


# 沙滩刨冰 准备
class YYShavedIcePrepare(RequestHandlerTask):
	url = r"/game/yy/shaved_ice/prepare"

	@coroutine
	def run(self):
		yyID = self.input.get("yyID", None)
		role = self.game.role
		hdCls = ObjectYYHuoDongFactory.getRoleOpenClass(yyID, role.level, role.created_time, role.vip_level)
		if not hdCls:
			raise ClientError(ErrDefs.huodongNoOpen)

		yyObj = ObjectYYHuoDongFactory.getConfig(yyID)
		record = hdCls.getRecord(yyID, self.game)
		if record["info"]["times"] >= record["info"]["buy_times"] + yyObj.paramMap["times"]:
			raise ClientError("play times limit up")

		ret = hdCls.prepare(self.game, yyObj)
		record["info"]["times"] += 1

		self.write({"view": ret})


# 沙滩刨冰 开始
class YYShavedIceStart(RequestHandlerTask):
	url = r"/game/yy/shaved_ice/start"

	@coroutine
	def run(self):
		yyID = self.input.get("yyID", None)
		idx = self.input.get("idx", None)

		role = self.game.role
		hdCls = ObjectYYHuoDongFactory.getRoleOpenClass(yyID, role.level, role.created_time, role.vip_level)
		if not hdCls:
			raise ClientError(ErrDefs.huodongNoOpen)

		ret = hdCls.startDemand(self.game, idx)


# 沙滩刨冰 提交
class YYShavedIceEnd(RequestHandlerTask):
	url = r"/game/yy/shaved_ice/end"

	@coroutine
	def run(self):
		yyID = self.input.get("yyID", None)
		idx = self.input.get("idx", None)
		choices = self.input.get("choices", None)
		costTime = self.input.get("time", None)

		role = self.game.role
		hdCls = ObjectYYHuoDongFactory.getRoleOpenClass(yyID, role.level, role.created_time, role.vip_level)
		if not hdCls:
			raise ClientError(ErrDefs.huodongNoOpen)

		yyObj = ObjectYYHuoDongFactory.getConfig(yyID)
		ret = hdCls.endDemand(self.game, idx, choices, yyObj, costTime)

		self.write({"view": {"result": ret}})


# 沙滩刨冰 结束/退出
class YYShavedIceQuit(RequestHandlerTask):
	url = r"/game/yy/shaved_ice/quit"

	@coroutine
	def run(self):
		yyID = self.input.get("yyID", None)

		role = self.game.role
		hdCls = ObjectYYHuoDongFactory.getRoleOpenClass(yyID, role.level, role.created_time, role.vip_level)
		if not hdCls:
			raise ClientError(ErrDefs.huodongNoOpen)

		eff = ObjectGainAux(self.game, {})

		yyObj = ObjectYYHuoDongFactory.getConfig(yyID)
		score = role.shaved_ice_score
		eff = hdCls.quitGame(self.game, yyObj, score)
		if eff:
			effectAutoGain(eff, self.game, self.dbcGame, src="shaved_ice_%s" % yyID, yy_id=yyID)

		record = hdCls.getRecord(yyID, self.game)
		if record["info"].get("score", 0) < score:
			yield ObjectServerGlobalRecord.sendRankingInfo(self.game, CrossShavedIceRanking, self.game.role.crossRankRoleInfo(rankData=[score]))
			record["info"]["score"] = score

		self.write({
			"view": {"result": eff.result},
		})


# 沙滩刨冰 购买次数
class YYShavedIceBuy(RequestHandlerTask):
	url = r"/game/yy/shaved_ice/buy"

	@coroutine
	def run(self):
		yyID = self.input.get("yyID", None)

		role = self.game.role
		hdCls = ObjectYYHuoDongFactory.getRoleOpenClass(yyID, role.level, role.created_time, role.vip_level)
		if not hdCls:
			raise ClientError(ErrDefs.huodongNoOpen)

		yyObj = ObjectYYHuoDongFactory.getConfig(yyID)
		record = hdCls.getRecord(yyID, self.game)
		if record['info'].get('buy_times', 0) >= yyObj.paramMap['buyTimes']:
			raise ClientError("shaved ice buy times limit")

		costRMB = hdCls.getBuyCost(yyObj, record["info"].get("buy_times", 0))
		cost = ObjectCostAux(self.game, {'rmb': costRMB})
		if not cost.isEnough():
			raise ClientError(ErrDefs.buyRMBNotEnough)
		cost.cost(src='shavedice_buy')
		record['info']['buy_times'] = record['info'].get('buy_times', 0) + 1


# 沙滩刨冰 排行
class YYShavedIceRank(RequestHandlerTask):
	url = r"/game/yy/shaved_ice/rank"

	@coroutine
	def run(self):
		yyID = self.input.get("yyID", None)
		role = self.game.role
		hdCls = ObjectYYHuoDongFactory.getRoleOpenClass(yyID, role.level, role.created_time, role.vip_level)
		if not hdCls:
			raise ClientError(ErrDefs.huodongNoOpen)

		resp = yield ObjectServerGlobalRecord.getRankingInfo(self.game, CrossShavedIceRanking)

		self.write({
			"view":  resp,
		})


# 夏日挑战 战斗开始
class SummerChallengeBattleStart(RequestHandlerTask):
	url = r"/game/yy/summer_challenge/battle/start"

	@coroutine
	def run(self):
		yyID = self.input.get("yyID", None)
		role = self.game.role
		hdCls = ObjectYYHuoDongFactory.getRoleOpenClass(yyID, role.level, role.created_time, role.vip_level)
		if hdCls is None:
			raise ClientError(ErrDefs.huodongNoOpen)

		cards = self.input.get("cards", None)  # csvIDs
		gateID = self.input.get("gateID", None)

		yyObj = ObjectYYHuoDongFactory.getConfig(yyID)
		cards = transform2list(cards)

		cardIDs = list(filter(None, cards))
		if not cardIDs or len(cardIDs) != len(set(cardIDs)):
			raise ClientError("cards error")

		data = hdCls.checkBattle(yyObj, self.game, cards, gateID)
		battleModel = yield self.rpcYYHuodong.call_async("SummerChallengeStartBattle", role.id, yyID, data)
		battleModel["level"] = role.level
		self.game.battle = battleModel

		self.write({
			"model": {"summer_challenge_battle": battleModel}
		})


# 夏日挑战 战斗结束
class SummerChallengeBattleEnd(RequestHandlerTask):
	url = r"/game/yy/summer_challenge/battle/end"

	@coroutine
	def run(self):
		yyID = ObjectYYHuoDongFactory.getSummerChallengeOpenID()
		role = self.game.role
		hdCls = ObjectYYHuoDongFactory.getRoleOpenClass(yyID, role.level, role.created_time, role.vip_level)
		if hdCls is None:
			raise ClientError(ErrDefs.huodongNoOpen)

		result = self.input.get("result", None)
		gateID = self.input.get("gateID", None)
		battleID = self.input.get('battleID', None)
		actions = self.input.get("actions", None)
		choices = self.input.get("choices", {})
		skills = self.input.get("skills", {})

		if gateID != self.game.battle["gateID"]:
			raise ClientError("gateID error")
		if battleID != self.game.battle["id"]:
			raise ClientError("battleID error")

		if isinstance(actions, list):
			actions = {idx + 1: v for idx, v in enumerate(actions)}

		if isinstance(choices, list):
			choices = {idx + 1: v for idx, v in enumerate(choices)}

		# 嵌套的skills可能被转为list
		for k , v in choices.items():
			if isinstance(v, list):
				choices[k] = {idx + 1: v for idx, v in enumerate(v)}

		ret = yield self.rpcYYHuodong.call_async("SummerChallengeEndBattle", role.id, yyID, gateID, result, actions, choices)

		eff = ObjectGainAux(self.game, {})
		if result == "win":
			record = hdCls.getRecord(yyID, self.game)
			if not record.setdefault("stamps", {}).get(gateID, 0):
				record["stamps"][gateID] = 1
				cfg = csv.summer_challenge.gates[gateID]
				eff += ObjectGainAux(self.game, cfg.award)

			yyObj = ObjectYYHuoDongFactory.getConfig(yyID)
			if hdCls.HuoDongMap[yyObj.paramMap["base"]][-1] == gateID:
				record.setdefault("info", {})["all_pass"] = 1

			for k, v in record.get("stamps1", {}).items():
				if v > 1:
					record["stamps1"][k] = max(0, v - 1)

			if skills:
				stamps1 = record.setdefault("stamps1", {})
				for skillID, num in skills.iteritems():
					stamps1[skillID] = stamps1.get(skillID, 0) + num

		if eff:
			yield effectAutoGain(eff, self.game, self.dbcGame, src="summer_challenge_gate")

		self.write({"view": eff.result})


# 夏日挑战 选择buff
class SummerChallengeChoose(RequestHandlerTask):
	url = r"/game/yy/summer_challenge/choose"

	@coroutine
	def run(self):
		yyID = self.input.get("yyID", None)
		role = self.game.role
		hdCls = ObjectYYHuoDongFactory.getRoleOpenClass(yyID, role.level, role.created_time, role.vip_level)
		if hdCls is None:
			raise ClientError(ErrDefs.huodongNoOpen)

		choiceID = self.input.get("choiceID", None)
		cfg = csv.scene_story_choices[choiceID]
		record = hdCls.getRecord(yyID, self.game)
		stamps1 = record.setdefault("stamps1", {})
		for skillID, num in cfg.skills.iteritems():
			stamps1[skillID] = stamps1.get(skillID, 0) + num


# 月圆祈福 获取任务奖励
class MidAutumnDrawGetTaskAward(RequestHandlerTask):
	url = r"/game/yy/mid_autumn_draw/task_award/get"

	@coroutine
	def run(self):
		yyID = self.input.get('yyID', None)
		csvID = self.input.get('csvID', None)

		if yyID is None or csvID is None:
			raise ClientError('param miss')

		role = self.game.role
		hdCls = ObjectYYHuoDongFactory.getRoleOpenClass(yyID, role.level, role.created_time, role.vip_level)
		if hdCls is None:
			raise ClientError(ErrDefs.huodongNoOpen)

		addTimes = hdCls.getTaskAward(yyID, self.game, csvID)

		self.write({"view": addTimes})


# 月圆祈福 一键获得任务奖励
class MidAutumnDrawGetOneKeyTaskAward(RequestHandlerTask):
	url = r"/game/yy/mid_autumn_draw/task_award/get/onekey"

	@coroutine
	def run(self):
		yyID = self.input.get('yyID', None)

		if yyID is None:
			raise ClientError('param miss')

		role = self.game.role
		hdCls = ObjectYYHuoDongFactory.getRoleOpenClass(yyID, role.level, role.created_time, role.vip_level)
		if hdCls is None:
			raise ClientError(ErrDefs.huodongNoOpen)

		addTimes = hdCls.getOneKeyTaskAward(yyID, self.game)

		self.write({"view": addTimes})

# 定制礼包
class YYCustomizeGift(RequestHandlerTask):
	url = r'/game/yy/customize/gift'

	@coroutine
	def run(self):
		yyID = self.input.get('yyID', None)
		csvID = self.input.get('csvID', None)
		choose = self.input.get('choose', None)

		if yyID is None or csvID is None or choose is None:
			raise ClientError('param miss')

		role = self.game.role
		hdCls = ObjectYYHuoDongFactory.getRoleOpenClass(yyID, role.level, role.created_time, role.vip_level)
		if hdCls is None:
			raise ClientError(ErrDefs.huodongNoOpen)

		result = hdCls.saveChoose(yyID, csvID, self.game, choose)
		self.write({'view': result})
