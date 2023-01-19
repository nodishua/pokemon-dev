#!/usr/bin/python
# -*- coding: utf-8 -*-

from framework import OneDay, ZeroTime, date2int, month2int, todaydate2int, period2date, UTCTZone,todayinclock5date2int, todayinclock5elapsedays, DailyRefreshHour
from framework.csv import csv
from framework.log import logger
from framework.lru import LRUCache
from framework.helper import timeSubTime, objectid2string
from framework.wnet import WANetTask, WANetBroadcastTask

from game import globaldata
from game.globaldata import *
from game.object import TitleDefs, MessageDefs

from tornado.gen import coroutine, Return
from tornado.ioloop import PeriodicCallback

import time
import weakref
import datetime

def nowtime_t():
	return Session.TimeInSecond


def nowdate_t():
	return Session.DateNow


def nowdatetime_t():
	return Session.DateTimeInSecond


class Session(object):
	'''
	user game session
	session id given by login server
	'''

	idSessions = LRUCache(SessionMaxCapacity)
	connSessions = weakref.WeakValueDictionary()
	server = None # 由server填充
	ioloop = None # 由server填充

	# 账号登陆后，未进入相应服务器的
	# 长久没有交互的玩家，可能是僵尸
	CleanZombieTimer = None

	# 用户统计
	ActiveStageSecs = [5 * 60, 10 * 60, 30 * 60]
	ActiveStageStat = [0, 0, 0]
	StatTimer = None
	StatTimerSecs = 60 # 1分钟统计一次

	# 秒级计时器，用来替换time.time()
	TimeInSecond = None
	DateTimeInSecond = None
	SecondTimeTimer = None

	# 每日的date2int
	DateNow = None
	DateIntNow = None
	DateIntInClock5 = None
	MonthIntNow = None
	NewDayTimer = None
	NewDayInClock5Timer = None

	# 竞技场排位赛周期结算奖励
	RankAwardTimer = None

	# 元素挑战房间刷新定时器
	CloneRoomRefreshTimer = None

	# 公会副本奖励刷新定时器
	UnionFubenAwardTimer = None

	# 拳皇争霸报名开始定时器
	CraftSignUpTimer = None

	# 公会战报名开始定时器
	UnionFightSighUpTimer = None

	@classmethod
	def starTimer(cls):
		tNow = time.time()
		dtNow = datetime.datetime.utcfromtimestamp(tNow) + UTCTZone # utc时间能减少获取local timezone的时间消耗
		logger.info('localtime %s servertime %s', datetime.datetime.fromtimestamp(tNow), dtNow)

		# session清理定时器
		cls.CleanZombieTimer = PeriodicCallback(cls._onCleanZombie, 5 * 60 * 1000.)
		# cls.CleanZombieTimer = PeriodicCallback(cls._onCleanZombie, 1000.)
		cls.CleanZombieTimer.start()

		# 统计定时器
		cls.StatTimer = PeriodicCallback(cls._onStatActive, cls.StatTimerSecs * 1000.)
		cls.StatTimer.start()

		# 更新秒级定时器
		cls.DateTimeInSecond = dtNow
		cls.TimeInSecond = tNow
		cls.SecondTimeTimer = PeriodicCallback(cls._onRefreshSecond, 1000.)
		cls.SecondTimeTimer.start()

		# 更新日期定时器
		# date -s "2016-09-30 10:29:40" 改时间测试，注意各个时间点要踩过去
		# PeriodicCallback按 触发时间+间隔时间，如果触发时间不在预定点，就会导致错乱
		def startAndTimer(dtNext, timer):
			def _run(timer):
				timer.start()
				return timer.callback()
			cls.ioloop.add_timeout(dtNext - dtNow + datetime.timedelta(seconds=2), _run, timer)

		hour5 = datetime.time(hour=DailyRefreshHour)

		cls.DateNow = dtNow.date()
		cls.DateIntNow = date2int(dtNow)
		cls.DateIntInClock5 = date2int(period2date(hour5, dtNow))
		cls.MonthIntNow = month2int(dtNow)
		dtNext = datetime.datetime.combine((dtNow + OneDay).date(), ZeroTime)
		if dtNow.time() < hour5:
			dtNext5 = datetime.datetime.combine(dtNow.date(), hour5)
		else:
			dtNext5 = datetime.datetime.combine((dtNow + OneDay).date(), hour5)
		cls.NewDayTimer = PeriodicCallback(cls._onNewDay, (1 + 24 * 3600) * 1000.)
		cls.NewDayInClock5Timer = PeriodicCallback(cls._onNewDayInClock5, (1 + 24 * 3600) * 1000.)
		startAndTimer(dtNext, cls.NewDayTimer)
		startAndTimer(dtNext5, cls.NewDayInClock5Timer)

		# 竞技场排位赛周期结算奖励定时器
		dtNext = datetime.datetime.combine(dtNow.date(), PVPAwardRefreshTime)
		if dtNext < dtNow:
			dtNext += OneDay
		cls.RankAwardTimer = PeriodicCallback(cls._onRankPeriodAward, (1 + 24 * 3600) * 1000.)
		startAndTimer(dtNext, cls.RankAwardTimer)

		# 元素挑战房间刷新定时器
		dtNext = datetime.datetime.combine(dtNow.date(), CloneRefreshTime)
		if dtNext < dtNow:
			dtNext += OneDay
		cls.CloneRoomRefreshTimer = PeriodicCallback(cls._onCloneRoomRefresh, (1 + 24 * 3600) * 1000.)
		startAndTimer(dtNext, cls.CloneRoomRefreshTimer)

		# 公会副本奖励刷新定时器
		dtNext = datetime.datetime.combine(dtNow.date(), UnionFubenAwardTime)
		if dtNext < dtNow:
			dtNext += OneDay
		cls.UnionFubenAwardTimer = PeriodicCallback(cls._onUnionFubenAward, (1 + 24 * 3600) * 1000.)
		startAndTimer(dtNext, cls.UnionFubenAwardTimer)

		# 拳皇争霸报名开始定时器
		dtNext = datetime.datetime.combine(dtNow.date(), CraftSignUpDailyTimeRange[0])
		if dtNext < dtNow:
			dtNext += OneDay
		cls.CraftSignUpTimer = PeriodicCallback(cls._onCraftStartSignUp, (1 + 24 * 3600) * 1000.)
		startAndTimer(dtNext, cls.CraftSignUpTimer)

		# 公会战报名定时器
		dtNext = datetime.datetime.combine(dtNow.date(), UnionFightSignUpTimeRange[0])
		if dtNext < dtNow:
			dtNext += OneDay
		cls.UnionFightSighUpTimer = PeriodicCallback(cls._onUnionFightStartSignUp, (1 + 24 * 3600) * 1000.)
		startAndTimer(dtNext, cls.UnionFightSighUpTimer)

		# 活动开启刷新
		cls._HuoDongTimerID = 0

		# 公会事务刷新
		cls._UnionTimerID = 0

		# 服务器皮肤刷新事件
		cls._SkinTimerFuture = None
		cls._SkinNearestTime = 0

		# 服务器物品刷新事件
		cls._ItemsTimerFuture = None
		cls._ItemsNearestTime = 0

		# 服务器称号刷新事件
		cls._TitleTimerFuture = None
		cls._TitleNearestTime = 0

		# 服务器角色刷新时间(道具，称号，公会可发送的红包)
		cls._RoleTimerFuture = None
		cls._RoleNearestTime = 0

	@classmethod
	def stopTimer(cls):
		cls.CleanZombieTimer.stop()
		cls.StatTimer.stop()
		cls.SecondTimeTimer.stop()
		cls.NewDayTimer.stop()
		cls.NewDayInClock5Timer.stop()
		cls.RankAwardTimer.stop()
		cls.CloneRoomRefreshTimer.stop()
		cls.UnionFubenAwardTimer.stop()
		cls.CraftSignUpTimer.stop()
		cls.UnionFightSighUpTimer.stop()

	@classmethod
	@coroutine
	def clearSession(cls):
		fus = []
		for session in cls.idSessions.itervalues():
			future = session.onDiscard()
			if future:
				fus.append(future)
		cls.idSessions.clear()

		for future in fus:
			yield future

	@classmethod
	def getSize(cls):
		return len(cls.idSessions)

	@classmethod
	def _add(cls, session):
		if session is None:
			return
		discardSession = None
		discardItem = cls.idSessions.set(session.accountKey, session)
		if discardItem:
			discardKey, discardSession = discardItem
			try:
				logger.info('session lru discard %s %s', discardSession.accountKey, discardSession.game.role.id)
			except:
				logger.info('session lru discard %s', discardSession.accountKey)
		return discardSession

	@classmethod
	def _del(cls, session):
		if session is None:
			return
		cls.idSessions.popByKey(session.accountKey)

	@classmethod
	def _onCleanZombie(cls):
		nowTime = time.time()
		delist = []
		for accountKey, session in cls.idSessions.iteritems():
			if session.gameGuard:
				continue

			if not session.gameLoad:
				# if nowTime - session.lastTime >= 5:
				if nowTime - session.lastTime >= SessionCleanNoLoadTimerSecs:
					delist.append(session)

			else:
				# if nowTime - session.lastTime >= 5:
				if nowTime - session.lastTime >= SessionCleanZombieTimerSecs:
					delist.append(session)

		for session in delist:
			cls._del(session)
			if session.gameLoad:
				session.onDiscard()

	@classmethod
	def _onStatActive(cls):
		nowTime = time.time()
		cls.ActiveStageStat = [0 for i in xrange(len(cls.ActiveStageSecs))]
		for accountKey, session in cls.idSessions.iteritems():
			elapseTime = nowTime - session.lastTime
			for i in xrange(len(cls.ActiveStageSecs)):
				if elapseTime <= cls.ActiveStageSecs[i]:
					cls.ActiveStageStat[i] += 1
					break
		for i in xrange(len(cls.ActiveStageSecs)-1):
			cls.ActiveStageStat[i+1] += cls.ActiveStageStat[i]
		# debug
		# import objgraph
		# objgraph.show_growth()

	@classmethod
	def refreshDate(cls):
		cls._onRefreshSecond()

		cls.DateNow = cls.DateTimeInSecond.date()
		cls.DateIntNow = date2int(cls.DateNow)
		cls.MonthIntNow = month2int(cls.DateNow)

		hour5 = datetime.time(hour=DailyRefreshHour)
		cls.DateIntInClock5 = date2int(period2date(hour5, cls.DateTimeInSecond))

	@classmethod
	@coroutine
	def _onNewDay(cls):
		logger.info('_onNewDay %s', nowdatetime_t())
		cls.refreshDate()

		# 刷新玩家每月数据
		for accountKey, session in cls.idSessions.iteritems():
			if session.gameLoad and not session.game.is_gc_destroy():
				if session.game.monthlyRecord.month != cls.MonthIntNow:
					session.game.monthlyRecord.renew()

		# 公会相关刷新
		yield cls.server.rpcUnion.call_async('OnRefresh')

	@classmethod
	@coroutine
	def _onNewDayInClock5(cls):
		logger.info('_onNewDayInClock5 %s', nowdatetime_t())
		cls.refreshDate()

		from game.thinkingdata import ta
		ta.onNewDayInClock5()
		# 刷新玩家每日数据
		for accountKey, session in cls.idSessions.iteritems():
			if session.gameLoad and not session.game.is_gc_destroy():
				if session.game.dailyRecord.date != cls.DateIntInClock5:
					session.game.dailyRecord.renew()
					session.game.role.refreshOnlineGift()

		# 活动礼物本 副本组每日交换
		from game.object.game.servrecord import ObjectServerGlobalRecord
		ObjectServerGlobalRecord.huodongGiftSwap()
		# 活动碎片本 每天都随机一组
		ObjectServerGlobalRecord.randomHuodongFragGroup()

		# 活动刷新
		cls.onHuoDongRefresh()

		# 单日排行榜刷新
		from game.object.game.rank import ObjectRankGlobal
		yield ObjectRankGlobal.dayRefresh()

		# 公会相关刷新
		yield cls.server.rpcUnion.call_async('OnRefresh')
		ranks = yield cls.server.rpcUnion.call_async('OnFubenReset')
		from game.handler.inl_mail import sendUnionFubenRankAwardMail
		sendUnionFubenRankAwardMail(cls.server.dbcGame, ranks)

		# 公会战周清理节点提前
		from game.object.game.union_fight import ObjectUnionFightGlobal
		yield ObjectUnionFightGlobal.weekCClose(cls.server.rpcUnionFight)

		from game.object.game import ObjectGame
		from game.object.game.yyhuodong import ObjectYYHuoDongFactory
		from game.handler.inl import effectAutoGain
		allobjs, safeGuard = ObjectGame.getAll()
		with safeGuard:
			for game in allobjs:
				game.role.last_login_time = nowtime_t() # 在线过5点刷新，设置上次登录时间，避免出现资源回收
				ObjectYYHuoDongFactory.onLogin(game)
				ObjectYYHuoDongFactory.onNewDayClock5(game)
				# 运营活动奖励未领取
				effs = ObjectYYHuoDongFactory.getRoleRegainMails(game)
				for eff in effs:
					yield effectAutoGain(eff, game, cls.server.dbcGame, src='yy_regain')
				game.role.refreshMegaConvertTimes()

		# 世界Boss每日刷新
		yield cls._dayWorldBossRefresh()
		# 普通勇者刷新
		ObjectServerGlobalRecord.refreshNormalBraveChallenge()

	@classmethod
	def _onRefreshSecond(cls):
		cls.TimeInSecond = time.time()
		cls.DateTimeInSecond = datetime.datetime.utcfromtimestamp(cls.TimeInSecond) + UTCTZone

	@classmethod
	@coroutine
	def _onRankPeriodAward(cls):
		from game.handler.inl_mail import sendOnlineRankPeriodAwardMails

		logger.info('pvp.sendOnlineRankPeriodAwardMails')
		allRanks = yield sendOnlineRankPeriodAwardMails(cls.server.rpcArena, cls.server.dbcGame)

		# 刷新竞技场头衔
		from game.object.game.servrecord import ObjectServerGlobalRecord
		ObjectServerGlobalRecord.saveTitleRanks(TitleDefs.Arena, allRanks)

		# 竞技场结算第一 跑马灯
		for roleID, rank in allRanks.iteritems():
			if rank == 1:
				from game.object.game.cache import ObjectCacheGlobal
				role = yield ObjectCacheGlobal.queryRole(roleID)
				from game.object.game import ObjectMessageGlobal
				ObjectMessageGlobal.marqueeBroadcast(role, MessageDefs.MqPvpTopRankLast)
				ObjectMessageGlobal.newsPVPTopRankLastMsg(role)
				break

	@classmethod
	@coroutine
	def _onCloneRoomRefresh(cls):
		logger.info('ObjectCloneRoomGlobal.onRefresh')
		days = max(todayinclock5elapsedays(globaldata.GameServOpenDatetime) - todayinclock5elapsedays(nowdatetime_t()), 0)
		yield cls.server.rpcClone.call_async("OnRefresh", days)

		from game.object.game import ObjectGame
		allobjs, safeGuard = ObjectGame.getAll()
		with safeGuard:
			for game in allobjs:
				game.role.clone_room_db_id = None
				game.role.clone_deploy_card_db_id = None
				game.role.clone_room_create_time = 0
				game.role.clone_daily_be_kicked_num = 0

	@classmethod
	def startCloneYYActive(cls, yyObj):
		cls.ioloop.add_callback(cls.server.rpcClone.call_async, "YYActive", yyObj)

	@classmethod
	def startCloneYYClose(cls):
		cls.ioloop.add_callback(cls.server.rpcClone.call_async, "YYClose")

	@classmethod
	def startBraveChallengeYYActive(cls, yyID):
		cls.server.rpcYYHuodong.call_async("BraveChallengeYYStart", yyID)

	@classmethod
	def startSummerChallengeYYActive(cls, yyID):
		cls.server.rpcYYHuodong.call_async("SummerChallengeYYStart", yyID)

	@classmethod
	@coroutine
	def _onUnionFubenAward(cls):
		ranks = yield cls.server.rpcUnion.call_async('OnFubenAward')
		from game.handler.inl_mail import sendUnionFubenRankAwardMail
		sendUnionFubenRankAwardMail(cls.server.dbcGame, ranks)

	@classmethod
	def startYYFightRankTimer(cls, yyID, delta):
		if delta.total_seconds() > 0:
			cls.ioloop.add_timeout(delta, cls._onYYFightRankAward, yyID)

	@classmethod
	def startYYLimitBoxTimer(cls, yyID, delta):
		if delta.total_seconds() > 0:
			cls.ioloop.add_timeout(delta, cls._onYYLimitBoxAward, yyID)

	@classmethod
	def startYYLimitBoxEndTimer(cls, yyID, delta):
		if delta.total_seconds() > 0:
			cls.ioloop.add_timeout(delta, cls._onYYLimitBoxEnd, yyID)

	@classmethod
	def startYYSnowBallEndTimer(cls, yyID, delta):
		if delta.total_seconds() > 0:
			cls.ioloop.add_timeout(delta, cls._onYYSnowBallEnd, yyID)

	@classmethod
	@coroutine
	def _onYYFightRankAward(cls, yyID):
		from game.object.game.yyhuodong import ObjectYYFightRank
		from game.object.game.rank import ObjectRankGlobal
		from game.mailqueue import MailJoinableQueue
		from game.globaldata import INF
		logger.info('_onYYFightRankAward')

		# 战力排行邮件
		huodongID = csv.yunying.yyhuodong[yyID].huodongID
		csvID = ObjectYYFightRank.FightPointMap[huodongID][-1]
		leastFightPoint = csv.yunying.fightpointaward[csvID].fightPointRequire

		top10 = yield ObjectRankGlobal.getRankList('fight', 0, 10)
		logger.info('fight rank top10 %s', top10)

		rankRoles = yield cls.server.dbcGame.call_async('DBRankRangeByScore', 'Rank_fight',INF , leastFightPoint)
		mails = ObjectYYFightRank.onAward(yyID, top10, rankRoles)
		for mail in mails:
			MailJoinableQueue.send(mail)

	@classmethod
	@coroutine
	def _onYYLimitBoxAward(cls, yyID):
		from game.mailqueue import MailJoinableQueue
		from game.object.game.role import ObjectRole

		logger.info('_onYYLimitBoxAward')

		huodongID = csv.yunying.yyhuodong[yyID].huodongID
		rankCsv = csv.yunying.limitboxrankaward
		maxRank = 0
		csvIDs = []
		for csvID in rankCsv:
			if rankCsv[csvID].huodongID == huodongID:
				csvIDs.append(csvID)
				maxRank = max(maxRank, rankCsv[csvID].rank)

		sCsvIDs = sorted(csvIDs, key=lambda x: rankCsv[x].rank)

		# 兼容合服前后的逻辑
		aliasList = cls.server.alias if cls.server.alias else ['']
		for gameKey in aliasList:
			rankRoles = yield cls.server.dbcGame.call_async('DBSummaryRange', 'Rank_yybox',1, maxRank, gameKey)
			for k,(roleID,score) in enumerate(rankRoles):
				rank = k + 1
				# score /= 10000000000
				for csvID in sCsvIDs:
					cfg = rankCsv[csvID]
					if rank <= cfg.rank:
						idx = csvID
						while cfg:
							if score >= cfg.pointLeast:
								if idx == csvID:
									mailType = YYHuoDongLimitBoxRankAwardMailID
								else:
									mailType = YYHuoDongLimitBoxRankPointAwardMailID
								mailcfg = csv.mail[mailType]
								content = mailcfg.content % (rank)
								mail = ObjectRole.makeMailModel(roleID, mailType, content = content, attachs=cfg.award)
								MailJoinableQueue.send(mail)
								# 神兽召唤抽到S+ 跑马灯
								# awardCard = cfg.award.get('card', None)
								# if awardCard:
								# 	csvCardId = awardCard['id']
								# 	csvCard = csv.cards[csvCardId]
								# 	rarity = csv.unit[csvCard.unitID].rarity
								# 	if rarity >= 4:
								# 		from game.object.game.cache import ObjectCacheGlobal
								# 		role = yield ObjectCacheGlobal.queryRole(roleID)
								# 		from game.object.game import ObjectMessageGlobal
								# 		ObjectMessageGlobal.marqueeBroadcast(role, MessageDefs.MqCardInLimitCard, csvCard=csvCard)

								logger.info("YYLimitBox %d role %s rank %d score %d", yyID, objectid2string(roleID), rank, score)
								break
							else:
								idx += 1
								cfg = rankCsv[idx]
						break

	@classmethod
	@coroutine
	def _onYYLimitBoxEnd(cls, yyID):
		from game.object.game.rank import ObjectRankGlobal
		logger.info('_onYYLimitBoxEnd')

		yield ObjectRankGlobal.yyboxRefresh()

	@classmethod
	@coroutine
	def _onYYSnowBallEnd(cls, yyID):
		from game.object.game.rank import ObjectRankGlobal
		logger.info('_onYYSnowBallEnd_%s_rank_clear', yyID)

		yield ObjectRankGlobal.rankClear('snowball')

	@classmethod
	def _huodongRefresh(cls):
		from game.object.game.huodong import ObjectHuoDongFactory
		from game.object.game.yyhuodong import ObjectYYHuoDongFactory

		hdDelta = ObjectHuoDongFactory.refreshAndEventDelta()
		yyhdDelta = ObjectYYHuoDongFactory.refreshAndEventDelta()
		delta = filter(None, [hdDelta, yyhdDelta])
		delta.sort()
		if delta:
			logger.info('_huodongRefresh %s; %s', hdDelta, yyhdDelta)
			cls.ioloop.add_timeout(delta[0] + datetime.timedelta(seconds=1), cls._onHuoDongRefresh, cls._HuoDongTimerID)

	@classmethod
	def _onHuoDongRefresh(cls, id):
		# 防止timeout越加越多，只刷新最新的一次
		if id != cls._HuoDongTimerID:
			return
		cls._huodongRefresh()

	@classmethod
	def onHuoDongRefresh(cls):
		cls._HuoDongTimerID += 1
		# 等ObjectHuoDongFactory和ObjectYYHuoDongFactory都初始化完毕
		if cls._HuoDongTimerID >= 2:
			cls._huodongRefresh()

# ---------------------------- skin begin
	@classmethod
	def _skinRefresh(cls, ndt):
		if cls._SkinTimerFuture is None:
			# 代表第一个加入进来的定时器
			cls._onSkinRefresh()
		else:
			# 不是第一个了
			if cls._SkinNearestTime > ndt:
				cls.ioloop.remove_timeout(cls._SkinTimerFuture)
				cls._onSkinRefresh()

	@classmethod
	def _onSkinRefresh(cls):
		# 清空玩家数据
		cls._SkinTimerFuture = None
		cls._SkinNearestTime = 0

		from game.object.game import ObjectGame
		allobjs, safeGuard = ObjectGame.getAll()
		with safeGuard:
			nearestTime = float('Inf')
			nowt = cls.TimeInSecond
			for game in allobjs:
				# 所有待删除的皮肤id缓存起来
				skinsDeleted = []
				for skinID in game.role.skins:
					deadline = game.role.skins[skinID]
					if deadline <= 0:
						# 碰到永久皮肤
						continue
					elif deadline > nowt:
						if nearestTime > deadline:
							nearestTime = deadline + 1
					else:
						## 执行清理操作
						skinsDeleted.append(skinID)
				if skinsDeleted:
					rawLogo = game.role.logo
					if rawLogo in csv.role_logo:
						roleLogoSkinID = csv.role_logo[rawLogo].skinID
						for skinID in skinsDeleted:
							if skinID == roleLogoSkinID:
								game.role.logo = 1 if 1 in game.role.logos else 2
								break

				# 清除所有
				for skinID in skinsDeleted:
					game.role.skins.pop(skinID, None)

				for skinID in skinsDeleted:
					cardMarkID = csv.card_skin[skinID].markID
					cards = game.cards.getCardsByMarkID(cardMarkID)
					for card in cards:
						if card.skin_id == skinID:
							card.skin_id = 0

				game.role._initCardSkin()
				game.role.onCardSkinRefresh(skinsDeleted)

		if nearestTime != float('Inf'):
			cls._SkinTimerFuture = cls.ioloop.add_timeout(nearestTime, cls._onSkinRefresh)
			cls._SkinNearestTime = nearestTime

	@classmethod
	def onSkinRefresh(cls, ndt):
		cls._skinRefresh(ndt)
# ---------------------------- skin end

	@classmethod
	def _onRoleRefresh(cls):
		cls._RoleTimerFuture = None
		cls._RoleNearestTime = 0

		from game.object.game import ObjectGame
		allobjs, safeGuard = ObjectGame.getAll()
		with safeGuard:
			nearestTime = float('Inf')
			for game in allobjs:
				# 道具
				deadline = game.items.expireItems()
				if deadline and nearestTime > deadline:
					nearestTime = deadline + 1

				# 称号
				deadline = game.role.expireTitles()
				if deadline and nearestTime > deadline:
					nearestTime = deadline + 1

				# 公会可发送红包
				deadline = game.role.expireUnionCanSendPacket()
				if deadline and nearestTime > deadline:
					nearestTime = deadline + 1

		if nearestTime != float('Inf'):
			cls._RoleTimerFuture = cls.ioloop.add_timeout(nearestTime, cls._onRoleRefresh)
			cls._RoleNearestTime = nearestTime

	@classmethod
	def onRoleRefresh(cls, ndt):
		if cls._RoleTimerFuture is None:
			# 代表第一个加入进来的定时器
			cls._onRoleRefresh()
		else:
			# 不是第一个了
			if cls._RoleNearestTime > ndt:
				cls.ioloop.remove_timeout(cls._RoleTimerFuture)
				cls._onRoleRefresh()

	@classmethod
	@coroutine
	def _onCraftStartSignUp(cls):
		from game.object.game.craft import ObjectCraftInfoGlobal

		if not ObjectCraftInfoGlobal.isTodayOpen():
			raise Return(None)

		ObjectCraftInfoGlobal.onStartSignUp(cls.server.rpcCraft)

		nt = nowdatetime_t().time()
		# 自动报名
		cls.ioloop.add_timeout(timeSubTime(CraftAutoSignUpDailyTime, nt), ObjectCraftInfoGlobal.onAutoSignUp)

		# 结束报名
		cls.ioloop.add_timeout(timeSubTime(CraftSignUpDailyTimeRange[1], nt), ObjectCraftInfoGlobal.onStartCraft, cls.server.rpcCraft)

	@classmethod
	def _onUnionFightStartSignUp(cls):
		from game.object.game.union_fight import ObjectUnionFightGlobal
		from game.object.game.levelcsv import ObjectFeatureUnlockCSV
		from game.object import FeatureDefs
		if not ObjectFeatureUnlockCSV.isFeatureExist(FeatureDefs.Unionfight):
			return False

		if not ObjectUnionFightGlobal.isOpenInDay():
			return None

		ObjectUnionFightGlobal.onStartSignUp(cls.server.rpcUnionFight)
		now = nowdatetime_t()
		nt = now.time()
		weekday = now.isoweekday()
		# 自动报名
		cls.ioloop.add_timeout(timeSubTime(UnionFightAutoSignUpTime, nt), ObjectUnionFightGlobal.onAutoSignUp)
		# 结束报名，开始匹配
		if weekday == 6:
			cls.ioloop.add_timeout(timeSubTime(UnionFightStart6Time, nt), ObjectUnionFightGlobal.onStartPrepare, cls.server.rpcUnionFight)
		else:
			cls.ioloop.add_timeout(timeSubTime(UnionFightSignUpTimeRange[1], nt), ObjectUnionFightGlobal.onStartPrepare, cls.server.rpcUnionFight)

	@classmethod
	@coroutine
	def _dayWorldBossRefresh(cls):
		from game.mailqueue import MailJoinableQueue
		from game.object.game.union import ObjectUnion
		from game.object.game.role import ObjectRole
		from game.object.game.yyhuodong import ObjectYYHuoDongFactory

		# 发世界boss排行奖励
		yyID = ObjectYYHuoDongFactory.getYYWorldBossOpenID()
		if yyID is None:
			yyID = ObjectYYHuoDongFactory.getYYLastWorldBossOpenID()
		if yyID:
			ObjectYYHuoDongFactory.setYYLastWorldBossOpenID()
		else:
			return

		ndi = todayinclock5date2int()
		yyCfg = csv.yunying.yyhuodong[yyID]

		# 开始活动第一天不需要发奖励
		if ndi <= yyCfg.beginDate:
			return
		# 过了活动结束日期不发奖励
		if ndi > yyCfg.endDate:
			return

		logger.info("_dayWorldBossRefresh start")

		huodongID = yyCfg.huodongID
		baseCsv = csv.world_boss.base
		serverTargetAward = None
		for csvID in baseCsv:
			if baseCsv[csvID].huodongID == huodongID:
				serverTargetAward = baseCsv[csvID].serverTargetAward

		roleRankCsv = csv.world_boss.role_rank_award
		csvIDs = []
		for csvID in roleRankCsv:
			if roleRankCsv[csvID].huodongID == huodongID:
				csvIDs.append(csvID)
		roleSCsvIDs = sorted(csvIDs, key=lambda x: roleRankCsv[x].rank)

		unionRankCsv = csv.world_boss.union_rank_award
		csvIDs = []
		for csvID in unionRankCsv:
			if unionRankCsv[csvID].huodongID == huodongID:
				csvIDs.append(csvID)
		unionSCsvIDs = sorted(csvIDs, key=lambda x: unionRankCsv[x].rank)

		rankResult = yield cls.server.rpcYYHuodong.call_async("WorldBossDayEnd", yyID, huodongID)
		finishGoal = rankResult['finishGoal']
		rankRoles = rankResult['rankRoles']
		rankUnions = rankResult['rankUnions']

		for idx, roleID in enumerate(rankRoles):
			rank = idx + 1
			# 个人排名奖励
			for csvID in roleSCsvIDs:
				cfg = roleRankCsv[csvID]
				if rank <= cfg.rank:
					mail = ObjectRole.makeMailModel(roleID, WorldBossRoleAwardMailID, contentArgs=(rank),attachs=cfg.award)
					MailJoinableQueue.send(mail)
					break

			# 全服目标奖励
			if finishGoal and serverTargetAward:
				mail = ObjectRole.makeMailModel(roleID, WorldBossServerAwardMailID, attachs=serverTargetAward)
				MailJoinableQueue.send(mail)

		# 公会排名奖励
		for idx, unionID in enumerate(rankUnions):
			rank = idx + 1
			for csvID in unionSCsvIDs:
				cfg = unionRankCsv[csvID]
				if rank <= cfg.rank:
					union = ObjectUnion.getUnionByUnionID(unionID)
					if union:
						for roleID in union.members:
							mail = ObjectRole.makeMailModel(roleID, WorldBossUnionAwardMailID, contentArgs=(rank), attachs=cfg.award)
							MailJoinableQueue.send(mail)
					break

		logger.info("_dayWorldBossRefresh end")

	@classmethod
	def popSession(cls, accountKey):
		if not accountKey:
			return None
		session = Session.idSessions.popByKey(accountKey)
		cls._del(session)
		return session

	@classmethod
	def getSession(cls, accountKey):
		if not accountKey:
			return None
		ret = Session.idSessions.getByKey(accountKey)
		if ret:
			ret.lastTime = cls.TimeInSecond
		return ret

	@classmethod
	def setSession(cls, session):
		# 重登陆按accountKey来恢复
		# session会因为LRU原因而失效
		oldSession = Session.popSession(session.accountKey)
		if oldSession and oldSession.ltaskRunning: # 上一个ltask可能因为nsq原因导致卡住，避免玩家进行多次操作，比如领取邮件，加入这个拦截
			cls._add(oldSession)
			raise Exception('ltask_running')
		if oldSession:
			oldSession.copyToNew(session)
			oldSession.onDiscard()

		discardSession = cls._add(session)
		if discardSession:
			discardSession.onDiscard()

	@classmethod
	def setSessionCapacity(cls, capacity):
		items = cls.idSessions.reCapacity(capacity)
		for _, session in items:
			cls._del(session)
			session.onDiscard()

	@classmethod
	def discardSession(cls, session):
		cls.popSession(session.accountKey)
		session.onDiscard()

	@classmethod
	def discardSessionByAccountKey(cls, accountKey):
		session = cls.popSession(accountKey)
		if session:
			session.onDiscard()

	@classmethod
	def lostSessionConn(cls, conn):
		session = cls.connSessions.get(conn, None)
		if session:
			session.onLostConn()

	#
	# 实例方法
	#
	def __init__(self, servID, accountID, accountName, sessionPwd, sdkInfo, rmbReturn):
		from game.object.game import ObjectGame

		self.servID = servID
		self.accountID = accountID
		self.accountName = accountName
		self.sessionPwd = sessionPwd
		self.sdkInfo = sdkInfo
		self.rmbReturn = rmbReturn
		self.clientSynID = 0
		self.clientLastResponseCache = None
		self.lastTime = Session.TimeInSecond # 用于session清理
		self.gameDate = Session.DateIntNow # 用于游戏判定跨日
		self.game = ObjectGame(self.server.dbcGame, self.setSafeGuard)
		self.gameLoad = False
		self.gameMove = False
		self.gameGuard = False
		self.lastConn = None
		self.isNewConn = False
		self.ltaskRunning = False

	# 合服依然唯一
	@property
	def accountKey(self):
		return (self.servID, self.accountID)

	def clearAll(self):
		'''
		discard之后清理
		'''

		if not self.gameMove:
			self.game.gc_destroy()

		del self.servID
		del self.accountID
		del self.sessionPwd
		del self.clientSynID
		del self.clientLastResponseCache
		del self.lastTime
		del self.game
		self.gameLoad = False
		if self.lastConn and not self.lastConn.closed():
			self.lastConn.close()
		self.lastConn = None

	def changeNewSynID(self, synID):
		if synID < self.clientSynID:
			self.clientLastResponseCache = None
			return False
		elif synID == self.clientSynID:
			# 可能是客户端重连，没有收到上次返回数据
			# 但如果没有last缓存，则失效
			return self.isLastRepeatedPost()
		else:
			self.clientLastResponseCache = None
		self.clientSynID = synID
		return True

	def isLastRepeatedPost(self):
		return self.clientLastResponseCache is not None

	@property
	def clientLastResponse(self):
		return self.clientLastResponseCache

	@clientLastResponse.setter
	def clientLastResponse(self, data):
		self.clientLastResponseCache = None
		# 4 is /game/login, do not need save
		if self.clientSynID > 4:
			self.clientLastResponseCache = data

	def canSendTask(self):
		# the condition was not safe fully but simple
		# the task will be unpack error in client because the password was wrong under some cases
		if self.gameLoad and self.lastConn and not self.lastConn.closed() and not self.isNewConn:
			# 4 is /game/login
			if self.clientSynID > 4:
				return True
		return False

	def sendTaskToClient(self, url, data):
		if self.canSendTask():
			ntask = WANetTask(self.lastConn, url=url, data=data, pwd=self.sessionPwd)
			Session.server.sendTask(ntask)

	@staticmethod
	def broadcastTask(url, data):
		ntask = WANetBroadcastTask(url, data)
		Session.server.sendTask(ntask)

	@classmethod
	def broadcast(cls, url, data, filter=None, roles=None):
		data['ret'] = True
		from game.object.game import ObjectGame
		if roles is not None:
			for toRoleID in roles:
				game = ObjectGame.getByRoleID(toRoleID, safe=False)
				if game:
					if filter and filter(game):
						continue
					session = cls.idSessions.getByKey(game.role.accountKey)
					if session:
						session.sendTaskToClient(url, data)
		else:
			allobjs, safeGuard = ObjectGame.getAll()
			with safeGuard:
				for game in allobjs:
					if filter and filter(game):
						continue
					session = cls.idSessions.getByKey(game.role.accountKey)
					if session:
						session.sendTaskToClient(url, data)

	def copyToNew(self, session):
		'''
		在线用户重新登录
		'''
		if self.gameMove:
			return

		session.game = self.game
		session.gameLoad = self.gameLoad
		session.lastTime = Session.TimeInSecond

		self.gameLoad = False
		self.gameMove = True

	def setSafeGuard(self, flag):
		self.gameGuard = flag

	def setClientConn(self, conn):
		if self.lastConn == conn:
			return
		if self.lastConn:
			self.lastConn.close()
		if conn is None:
			self.lastConn = None
			self.isNewConn = False
			return

		self.lastConn = conn
		self.isNewConn = True
		conn.setAESPwd(self.sessionPwd)

		Session.connSessions[self.lastConn] = self

	def getPwdForNewConn(self):
		if self.isNewConn:
			self.isNewConn = False
			return self.sessionPwd

	def onLostConn(self):
		if self.gameLoad:
			pass
			# logger.info('Conn Close, role uid %s', self.game.role.uid)
		if self.gameMove:
			pass
			# logger.info('game moved')

	def onDiscard(self):
		'''
		异步非阻塞
		'''
		def _end(fu):
			# print 'session clear', self, self.accountKey
			self.clearAll()

		future = None
		if self.gameLoad:
			# 先从Cache中pop掉，然后做相关清理
			# 已经进入清理流程，不予许外部获取到
			from game.object.game import ObjectGame
			ObjectGame.popByRoleID(self.game.role.id)

			future = self._syncLast()
			future.add_done_callback(_end)
		else:
			_end(future)
		return future

	@coroutine
	def _syncLast(self):
		# 在session结束前，刷新部分数据

		role = self.game.role
		# 刷新在线礼包
		role.refreshOnlineGift(isEnd=True)

		from game.thinkingdata import ta
		ta.syncLast(role.pid)

		# 刷新竞技场数据
		if role.pvp_record_db_id:
			from game.handler._pvp import refreshCardsToPVP
			try:
				yield refreshCardsToPVP(Session.server.rpcArena, self.game, force=True)
			except:
				logger.exception('defenceDeploy error')

			# 顺便刷新到好友系统
			# from game.object.game.society import ObjectSocietyGlobal
			# ObjectSocietyGlobal.onCardsInfo(self.game.role.id, cardDCSs, cardsD, fightgoVal)

		# 刷新公会member数据
		if role.union_db_id or role.union_join_que:
			from game.handler._union import refreshUnionMember, refreshUnionTraining
			try:
				refreshUnionMember(Session.server.rpcUnion, role)
				if role.unionMemberRefreshFuture:
					yield role.unionMemberRefreshFuture
			except:
				logger.exception('RefreshUnionMember error')

			try:
				refreshUnionTraining(Session.server.rpcUnion, self.game)
			except:
				logger.exception('refreshUnionTraining error')

		# 刷新拳皇争霸数据
		if role.craft_record_db_id:
			from game.handler._craft import refreshCardsToPVP
			try:
				yield refreshCardsToPVP(Session.server.rpcCraft, self.game, force=True)
			except:
				logger.exception('craftDeploy error')

		# 刷新工会战数据
		if role.union_fight_record_db_id:
			from game.handler._union_fight import refreshUnionfCardsToPVP
			try:
				yield refreshUnionfCardsToPVP(Session.server.rpcUnionFight, self.game, force=True)
			except:
				logger.exception('unionFiDeploy error')

		# 刷新跨服王者争霸数据
		if role.cross_craft_record_db_id:
			from game.handler._cross_craft import refreshCardsToPVP
			try:
				yield refreshCardsToPVP(Session.server.rpcPVP, self.game, force=True)
			except:
				logger.exception('crossCraftDeploy error')

		# 刷新跨服竞技场数据
		if role.cross_arena_record_db_id:
			from game.handler._cross_arena import refreshCardsToCrossArena
			try:
				yield refreshCardsToCrossArena(Session.server.rpcPVP, self.game, force=True)
			except:
				logger.exception('crossArenaDeploy error')

		# 刷新实时匹配对战
		if role.cross_online_fight_record_db_id:
			from game.handler._cross_online_fight import refreshCardsToCrossOnlineFight
			try:
				yield refreshCardsToCrossOnlineFight(Session.server.rpcPVP, self.game, force=True)
			except:
				logger.exception('crossOnlineFightDeploy error')

		# 刷新跨服竞技场数据
		if role.cross_mine_record_db_id:
			from game.handler._cross_mine import refreshCardsToCrossMine
			try:
				yield refreshCardsToCrossMine(Session.server.rpcPVP, self.game, force=True)
			except:
				logger.exception('crossMineDeploy error')

		logger.info('channel %s account %s role %d %s level %d vip %d gold %d rmb %d stamina %d battle %d top6 %d', self.game.role.channel, objectid2string(self.game.role.account_id), self.game.role.uid, self.game.role.pid, self.game.role.level, self.game.role.vip_level, self.game.role.gold, self.game.role.rmb, self.game.role.stamina, self.game.role.battle_fighting_point, self.game.role.top6_fighting_point)

		try:
			# 通知db server清除相关model object
			yield self.game.save_async(True)
		except:
			logger.exception('save_async error')
