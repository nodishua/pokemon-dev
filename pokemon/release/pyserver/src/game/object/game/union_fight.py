#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2016 TianJi Information Technology Inc.
'''

from framework import period2date, inclock5date, nowdatetime_t, todaydate2int, datetimefromtimestamp, DailyRefreshHour
from framework.csv import csv
from framework.log import logger
from framework.object import db_property, ObjectNoGCDBase

from game import globaldata
from game.globaldata import *
from game.object import FeatureDefs, UnionDefs
from game.object.game.levelcsv import ObjectFeatureUnlockCSV
from game.object.game.union import ObjectUnion
from game.object.game.gain import ObjectGoodsMap

import datetime
import copy

from tornado.gen import coroutine, Return

RoleSignFields = ['id', 'name', 'logo', 'frame', 'level', 'figure', 'vip_level', 'union_fight_record_db_id', 'union_quit_time']

def model2signitem(d, fields, **kwargs):
	def _get(d, k):
		if isinstance(d, dict):
			if k in d:
				return d[k]
			return kwargs[k]
		if hasattr(d, k):
			return copy.deepcopy(getattr(d, k))
		return kwargs[k]
	dd = {k: _get(d, k) for k in fields}
	dd.update(kwargs)
	vip_hide = _get(d, 'vip_hide')
	if vip_hide:
		dd.update(vip_level=0)
	return dd

def signupItemData(role, union):
	return model2signitem(role, RoleSignFields, union_db_id=union.id)

class ObjectUnionFightGlobal(ObjectNoGCDBase):
	DBModel = 'UnionFightGameGlobal'

	Singleton = None

	OpenDateTime = None
	OpenDateTimeOneWeek = None
	OpenLevel = 0
	AutoSignVIP = 0

	AutoSignOK = False
	AutoSignRoleMap = {}
	WeekNatureLimit = {}
	StartBattleTime = None

	UnionFightSignUps = {}
	UnionFightSignRoles = {}
	UnionFightRank = {}
	ServerName = ""

	@classmethod
	def classInit(cls):
		cfg = csv.union_fight.base[1]
		openDay = cfg.servOpenDays
		cls.OpenDateTime = datetime.datetime.combine(inclock5date(globaldata.GameServOpenDatetime) + datetime.timedelta(days=openDay - 1), datetime.time(hour=DailyRefreshHour))
		weekday = cls.OpenDateTime.isoweekday()
		cls.OpenDateTimeOneWeek = cls.OpenDateTime
		if weekday >= 2: #要完整周开始
			cls.OpenDateTimeOneWeek += datetime.timedelta(days=7-weekday+1)
		cls.OpenLevel = ObjectFeatureUnlockCSV.getOpenLevel(FeatureDefs.Unionfight)
		cls.AutoSignVIP = cfg.autoSignVIP

		for roleID in cls.AutoSignRoleMap.keys():
			item = cls.AutoSignRoleMap[roleID]
			if item['level'] < cls.OpenLevel:
				cls.AutoSignRoleMap.pop(roleID)

		cls.WeekNatureLimit = {}
		for idx in csv.union_fight.nature_limit:
			cfg = csv.union_fight.nature_limit[idx]
			cls.WeekNatureLimit[cfg.weekDay] = cfg.natureLimit

	def __init__(self, dbc):
		ObjectNoGCDBase.__init__(self, None, dbc)

		if ObjectUnionFightGlobal.Singleton is not None:
			raise ValueError('This is singleton object')
		ObjectUnionFightGlobal.Singleton = self

	def init(self, rpc):
		self._rpc = rpc
		# self.reset()
		return self

	@classmethod
	def reset(cls):
		self = cls.Singleton
		ndi = todaydate2int()
		if self.date == ndi:
			return False
		logger.info('UnionFight Reset %d %s, %d', self.date, self.round, ndi)
		self.date = ndi
		# self.round = 'closed'
		self.signup = {}
		cls.initUnionFightSign({})
		cls.AutoSignOK = False

	@classmethod
	def clean(cls):
		self = cls.Singleton
		# self.round = 'closed'
		cls.AutoSignOK = False
		self.signup = {}
		for k in self.top8_vs_union:
			self.top8_vs_union[k] = []
		cls.initUnionFightSign({})

	@classmethod
	def onRoleInfo(cls, game):
		self = cls.Singleton
		role = game.role
		if game.union and game.union.isFeatureOpen(UnionDefs.Unionfight) and role.level >= cls.OpenLevel and role.union_fight_record_db_id:
			cls.AutoSignRoleMap[role.id] = signupItemData(role, game.union)
			# 刷新自动报名的玩家数据
			# 如果报名已开始则自动报名
			if not game.dailyRecord.union_fight_sign_up and cls.AutoSignOK:
				if self.date == todaydate2int() and cls.isRoleOpen(game) and cls.isCanSignUp(game.role.id, game.role.union_fight_record_db_id):
					cls.signUp(game)

			game.dailyRecord.union_fight_sign_up = role.id in self.signup
		elif role.id in cls.AutoSignRoleMap:
			cls.AutoSignRoleMap.pop(role.id, None)

	@classmethod
	def isInSign(cls):
		self = cls.Singleton
		return self.round == 'signup'

	# 是否满足完整周开放
	@classmethod
	def isOpen(cls):
		# return cls.OpenDateTime < nowdatetime_t()
		return cls.OpenDateTimeOneWeek < nowdatetime_t()

	# 是否开入口
	@classmethod
	def isOpenDay(cls):
		return cls.OpenDateTime < nowdatetime_t()

	@classmethod
	def isOpenInDay(cls):
		nowdate = nowdatetime_t()
		# return cls.OpenDateTime < nowdate and nowdate.isoweekday() in (2,3,4,5,6)
		return cls.OpenDateTimeOneWeek < nowdate and nowdate.isoweekday() in (2,3,4,5,6)

	@classmethod
	def isRoleOpen(cls,game):
		if not cls.isOpenInDay():
			return False
		union = game.union
		if union is None:
			return False
		return union.isFeatureOpen(UnionDefs.Unionfight) and game.role.level >= cls.OpenLevel

	@classmethod
	def isRoleEnter(cls,game):
		if not cls.isOpen():
			return False
		union = game.union
		if union is None:
			return False
		return union.isFeatureOpen(UnionDefs.Unionfight) and game.role.level >= cls.OpenLevel and game.role.union_fight_record_db_id

	@classmethod
	def isRoleJionTime(cls,unionQuitTime):
		if unionQuitTime == 0: #新加入的公会可以参加
			return True
		delta = inclock5date(nowdatetime_t()) - period2date(globaldata.DailyRecordRefreshTime, datetimefromtimestamp(unionQuitTime))
		if delta < datetime.timedelta(days=1):
			return False
		return True

	@classmethod
	def isCanBet(cls):
		if nowdatetime_t().isoweekday() != 6:
			return False
		self = cls.Singleton
		return self.round in ('signup',)

	@classmethod
	def getRoundInTime(cls):
		now = nowdatetime_t()
		nt = now.time()
		weekday = now.isoweekday()
		if now < cls.OpenDateTimeOneWeek:
			return 'closed'
		if nt < UnionFightSignUpTimeRange[0]:
			# 周一和周二之前是关闭状态,其他是 over 状态
			if weekday in (1, 2):
				return 'closed'
			else:
				return 'over'
		# 周日 over
		if weekday == 7:
			return "over"
		# 周一五点前是 over，五点后是 closed
		if weekday == 1:
			if nt < datetime.time(hour=5):
				return "over"
			else:
				return "closed"

		# 周六准备时间在 20:59
		if weekday == 6 and UnionFightSignUpTimeRange[0] < nt < UnionFightStart6Time:
			return 'signup'

		if UnionFightSignUpTimeRange[0] < nt < UnionFightSignUpTimeRange[1]:
			return 'signup'
		if nt < UnionFightStartTime:
			return 'prepare'
		if nt > UnionFightStartTime:
			return 'battle'
		return 'unknown'

	@classmethod
	def isCanSignUp(cls, roleID, union_fight_record_db_id):
		self = cls.Singleton
		if self.round == 'signup' and union_fight_record_db_id:
			weekday = nowdatetime_t().isoweekday()
			if weekday == 6:
				union = ObjectUnion.getUnionByRoleID(roleID)
				if union:
					# for unionID,name,logo,point in self.pre_top8_union:
					# 	if unionID == union.id:
					# 		return True
					if union.id in self.top8_vs_union:
						return True
				return False
			else:
				return True
		return False

	@classmethod
	def isRoleVipOpen(cls, role_vip):
		weekday = nowdatetime_t().isoweekday()
		# 周六不限制 vip
		if weekday == 6:
			return True
		return role_vip >= cls.AutoSignVIP


	@classmethod
	def signUp(cls, game, manual=False):
		# self = cls.Singleton
		# game.dailyRecord.unionfight_sign_up = True
		# if game.role.id not in self.signup and game.union:
		# 	self.signup[game.role.id] = (game.role.unionfight_record_db_id, game.union.id)
		# 	ObjectUnionGlobal.unionFightSign(game.role.id)

		self = cls.Singleton
		role = game.role
		if role.id in self.signup:
			if not manual:
				manual = self.signup[role.id].get('manual', False)
		self.signup[role.id] = signupItemData(role, game.union)

		cls.unionFightSign(role.id)
		game.dailyRecord.union_fight_sign_up = True

	# 开始报名 closed -> signup
	@classmethod
	def onStartSignUp(cls, rpc):
		if not ObjectFeatureUnlockCSV.isFeatureExist(FeatureDefs.Unionfight):
			return
		self = cls.Singleton
		# cls.reset()
		if not cls.isOpenInDay():
			return

		# if self.round != 'closed':
		# 	logger.warning('UnionFight onStartSignUp Status Error %s', self.round)
		# 	return

		logger.info('ObjectUnionFightGlobal.onStartSignUp')
		self.round = 'signup'

		weekday = nowdatetime_t().isoweekday()
		# 周六报名时先进行一次自动报名
		if weekday == 6:
			cls.onAutoSignUp()
			# 开赛前还有一次自动报名
			cls.AutoSignOK = False


	@classmethod
	def initAutoSignUp(cls, models):
		cls.AutoSignRoleMap = {}
		for model in models:
			if not model['union_fight_record_db_id'] or model['disable_flag']:
				continue
			roleID = model['id']
			union = ObjectUnion.getUnionByRoleID(roleID)
			if union and union.isFeatureOpen(UnionDefs.Unionfight):
				cls.AutoSignRoleMap[roleID] = signupItemData(model, union)
		logger.info('UnionFight Init AutoSign Roles %d', len(cls.AutoSignRoleMap))


	# 自动报名 signup
	@classmethod
	def onAutoSignUp(cls):
		if not ObjectFeatureUnlockCSV.isFeatureExist(FeatureDefs.Unionfight):
			return False
		self = cls.Singleton
		if not cls.isOpenInDay():
			return
		if self.round != 'signup':
			return

		from game.object.game import ObjectGame
		self = cls.Singleton
		cnt = 0
		for roleID, item in cls.AutoSignRoleMap.iteritems():
			weekday = nowdatetime_t().isoweekday()

			if not cls.isRoleJionTime(item['union_quit_time']):
				continue

			# 周六没有 vip 限制
			if weekday != 6 and item['vip_level'] < cls.AutoSignVIP:
				continue

			if self.isCanSignUp(roleID, item['union_fight_record_db_id']):
				if roleID not in self.signup:
					union = ObjectUnion.getUnionByRoleID(roleID)
					if union:
						self.signup[roleID] = item
						onlineGame = ObjectGame.getByRoleID(roleID, safe=False)
						if onlineGame:
							onlineGame.dailyRecord.union_fight_sign_up = True
						cnt += 1

		cls.initUnionFightSign(self.signup)
		cls.AutoSignOK = True
		logger.info('ObjectUnionFightGlobal.onAutoSignUp %d, %d', cnt, len(self.signup))

	@classmethod
	def initUnionFightSign(cls, signupRoles):
		cls.UnionFightSignUps = {} # {union_db_id:(signcount,membercount)}
		cls.UnionFightSignRoles = {}# {union_db_id:[roleid]} #这个传给客户端让客户端读取union.members对应name、logo等等
		self = cls.Singleton
		if signupRoles:
			for roleID,info in signupRoles.iteritems():
				union = ObjectUnion.getUnionByUnionID(info["union_db_id"])
				if union:
					cls.UnionFightSignRoles.setdefault(union.id, [])
					cls.UnionFightSignRoles[union.id].append(roleID)
					self.top8VSUnionAddRole(union.id, roleID)

			for unionID,roles in cls.UnionFightSignRoles.iteritems():
				union = ObjectUnion.getUnionByUnionID(unionID)
				cls.UnionFightSignUps[union.id] = (len(roles),len(union.members),union.name)


	@classmethod
	def unionFightSign(cls, roleID):
		union = ObjectUnion.getUnionByRoleID(roleID)
		self = cls.Singleton
		if union:
			cls.UnionFightSignRoles.setdefault(union.id, [])
			cls.UnionFightSignRoles[union.id].append(roleID)
			count = len(cls.UnionFightSignRoles[union.id])
			countmax = len(union.members)
			if count > countmax:
				count = countmax
			cls.UnionFightSignUps[union.id] = (count,countmax,union.name)
			self.top8VSUnionAddRole(union.id, roleID)

	def top8VSUnionAddRole(self, unionID, roleID):
		weekday = nowdatetime_t().isoweekday()
		if weekday != 6:
			return

		if unionID in self.top8_vs_union:
			oldRoles = self.top8_vs_union[unionID]
			if roleID not in oldRoles:
				oldRoles.append(roleID)
			self.top8_vs_union[unionID] = copy.deepcopy(oldRoles)

	@classmethod
	@coroutine
	def weekCClose(cls, rpc):
		weekday = nowdatetime_t().isoweekday()
		if weekday == 1:
			self = cls.Singleton
			self.round = "closed"
			self.top8_vs_union = {}
			rpc.call_async_always("WeekClose")

	# 报名结束 (signup, prepare) -> prepare -> prepare_ok
	@classmethod
	@coroutine
	def onStartPrepare(cls, rpc, testWeekday=None):
		if not ObjectFeatureUnlockCSV.isFeatureExist(FeatureDefs.Unionfight):
			raise Return(None)
		self = cls.Singleton
		if self.round not in  ('signup'):
		# if self.round not in  ('signup', 'prepare'):
			logger.warning('UnionFight onStartPrepare Status Error %s', self.round)
			raise Return(None)

		nowdate = nowdatetime_t()
		weekday = nowdate.isoweekday()
		if testWeekday is not None:
			weekday = testWeekday

		self.round = 'prepare'

		yield cls.refreshUnionfCards()

		yield rpc.call_async_always('StartUnionFightPrepare', self.getSignupRoles(), weekday, self.top8_vs_union)

		logger.info('ObjectUnionFightGlobal.onStartPrepare over %s', nowdatetime_t())

	def getSignupRoles(self):
		ret = []
		for roleID, item in self.signup.iteritems():
			# 不能通过 RoleID 拿，可能报了名之后换了公会
			union = ObjectUnion.getUnionByUnionID(item['union_db_id'])
			if not union:
				continue
			ret.append((
				roleID,
				item['union_fight_record_db_id'],
				item['union_db_id'],
				union.name,
				union.logo,
				union.level,
				len(union.members)
			))
		return ret

	# 开始发奖励
	# @classmethod
	# @coroutine
	# def onStartAward(cls):
	def onStartAward(cls, rankRoles, rankUnions):
		self = cls.Singleton

		nt = todaydate2int()
		if self.last_award_time == nt:
			logger.info('ObjectUnionFightGlobal.onStartAward error %s', nt)
			self.clean()
			raise Return(None)

		logger.info('ObjectUnionFightGlobal.onStartAward start %d', nt)

		self.last_award_time = nt

		from game.object.game.role import ObjectRole
		from game.mailqueue import MailJoinableQueue
		nowdate = nowdatetime_t()
		weekday = nowdate.isoweekday()
		baseCsv = csv.union_fight.base[1]

		# 报名奖励
		for roleID in self.signup.iterkeys():
			if weekday == 6:
				mail = ObjectRole.makeMailModel(roleID, UnionFightFinalAwardMailID, attachs=baseCsv.finalSignAward)
			else:
				mail = ObjectRole.makeMailModel(roleID, UnionFightPreAwardMailID, attachs=baseCsv.preSignAward)
			MailJoinableQueue.send(mail)

		#公会战战斗胜利奖励
		if weekday != 6:
			for (roleID,count) in rankRoles:
				if count <= 0:
					continue
				award = ObjectGoodsMap(None, baseCsv.winAward)
				awardCount = count
				if count > baseCsv.winLimit:
					awardCount = baseCsv.winLimit
				award *= awardCount
				mail = ObjectRole.makeMailModel(roleID, UnionFightWinAwardMailID, contentArgs=(count), attachs=award.to_dict())
				MailJoinableQueue.send(mail)

		#公会战排名奖励
		if weekday != 6:
			rankCsv = csv.union_fight.prerank
		else:
			rankCsv = csv.union_fight.finalrank
		preCsvID = 1
		for (unionID, rank) in rankUnions:
			if rank > rankCsv[preCsvID].rankMax:
				preCsvID += 1
			if preCsvID not in rankCsv:
				break
			union = ObjectUnion.getUnionByUnionID(unionID)
			award = rankCsv[preCsvID].award
			if union and award:
				for roleID in union.members:
					if roleID not in self.signup:
						continue
					mail = ObjectRole.makeMailModel(roleID, UnionFightRankAwardMailID, contentArgs=(rank), attachs=award)
					MailJoinableQueue.send(mail)

		# 奖励发放完毕 状态clean
		self.clean()

		if weekday == 6:
			# 清除跨服公会战 原有排行榜 重新算
			from game.object.game import ObjectCrossUnionFightGameGlobal
			ObjectCrossUnionFightGameGlobal.cleanPointRankList()
			unions = sorted(rankUnions, key=lambda x:x[1])
			self.top5_history.append([x[0] for x in unions[:5]]) # 保存前5
			if len(self.top5_history) > 3:
				self.top5_history = self.top5_history[-3:]

	@classmethod
	def getSlimModel(cls):
		self = cls.Singleton
		return {
			'time': self.time,
			'round': self.round,
			'signs': self.UnionFightSignUps
		}

	@classmethod
	def getUnionSignRoles(cls, unionID):
		return cls.UnionFightSignRoles.get(unionID, [])

	@classmethod
	def initUnionFightRank(cls, sceneVSInfo, pretop8Union):
		cls.UnionFightRank = {6:{}}
		for unionID,union in ObjectUnion.ObjsMap.iteritems():
			if union.isFeatureOpen(UnionDefs.Unionfight):
				# 总排名计算到6里面
				totalPoint = 0
				for w,p in  union.fight_point.iteritems():
					if w == 6:
						continue
					totalPoint += p[0]
					if w not in cls.UnionFightRank:
						cls.UnionFightRank[w] = {}
					cls.UnionFightRank[w][unionID] = (union.name, p[0], p[1])
				cls.UnionFightRank[6][unionID] = (union.name, totalPoint, 0)

		if sceneVSInfo: #周六总决赛已经跑过了
			# sceneVSInfo = {1:(unionID1,unionID2,winUnionID),...7:(unionID1,unionID2,winUnionID)}
			ranksInfo = {}
			for unionID,name,logo,point in pretop8Union:
				ranksInfo[unionID] = (0,point)
			for round,info in sceneVSInfo.iteritems():
				if info[2] > 0:
					ranksInfo[info[2]] = (ranksInfo[info[2]][0]+1, ranksInfo[info[2]][1])
			ranksInfo = [(unionID,win,point) for unionID,(win,point) in ranksInfo.iteritems()]
			ranksInfo = sorted(ranksInfo, key=lambda x:(x[1],x[2]),reverse=True)
			finalrankCsv = csv.union_fight.finalrank
			preCsvID = 1
			rank = 0
			for k,info in enumerate(ranksInfo):
				unionID = info[0]
				if unionID not in cls.UnionFightRank[6]:
					continue
				rank += 1
				if rank > finalrankCsv[preCsvID].rankMax:
					preCsvID += 1
				if preCsvID not in finalrankCsv:
					break
				cls.UnionFightRank[6][unionID] = (cls.UnionFightRank[6][unionID][0], finalrankCsv[preCsvID].point + cls.UnionFightRank[6][unionID][1], rank)

	@classmethod
	@coroutine
	def onUnionFightEvent(cls, event, data, sync):
		self = cls.Singleton
		ret = {}
		if event == "battle":
			from framework import nowdatetime_t
			import datetime
			# from game.handler.tool import ToolConsole
			now = nowdatetime_t()
			# ToolConsole.TEST_TIME = datetime.time(hour=now.hour, minute=now.minute, second=now.second)
			cls.StartBattleTime = datetime.time(hour=now.hour, minute=now.minute, second=now.second)
			# logger.info(ToolConsole.TEST_TIME)
			self.round = 'battle'

		elif event == "over":
			self.round = "over"

		elif event == "top8":
			pass

		elif event == "bet_award":
			self.onBetAward(data.get('union_fight_bets', {}))

		elif event == "start_award":
			self.onStartAward(data.get('rank_roles', {}), data.get('rank_unions', {}))

		elif event == "top8_vs_union":
			self.onTop8VSUnion(data.get("top8_vs_union", {}))

		elif event == "reset_today":
			yield cls.refreshUnionfCards()
			ret = {
				"signup":self.getSignupRoles(),
				"top8Deploys": self.top8_vs_union
			}
			self.round = "prepare"

		raise Return(ret)

	@classmethod
	@coroutine
	def refreshUnionfCards(cls):
		self = cls.Singleton
		from game.object.game import ObjectGame
		from game.handler._union_fight import refreshUnionfCardsToPVP
		try:
			allobjs, safeGuard = ObjectGame.getAll()
			with safeGuard:
				for game in allobjs:
					if game.role.id in self.signup:
						game.dailyRecord.union_fight_sign_up = True
						try:
							yield refreshUnionfCardsToPVP(self._rpc, game, force=True)
						except:
							logger.exception('UnionFight refreshUnionFightCardsToPVP error')
		except:
			logger.exception('UnionFight safeGuard error')

	# 下注奖励
	def onBetAward(self, bets):
		logger.info('ObjectUnionFightGlobal.onBetAward %s', len(bets))
		from game.mailqueue import MailJoinableQueue
		from game.object.game.role import ObjectRole
		for betRoleID, t in bets.iteritems():
			whoName, winGold, level = t
			mail = None
			if level == 'champion':
				mail = ObjectRole.makeMailModel(betRoleID, UnionFightBetWinAwardMailID, contentArgs=whoName, attachs={'gold': winGold})
			elif level == 'top8':
				mail = ObjectRole.makeMailModel(betRoleID, UnionFightBetTop8AwardMailID, contentArgs=whoName, attachs={'gold': winGold})
			elif level == 'fail':
				mail = ObjectRole.makeMailModel(betRoleID, UnionFightBetTop8FailMailID, contentArgs=whoName)
			if mail:
				MailJoinableQueue.send(mail)

	# 八强公会
	def onTop8VSUnion(self, top8VSUnion):
		self.top8_vs_union = top8VSUnion

	@classmethod
	def isTop8Union(cls, unionID):
		self = cls.Singleton
		return unionID in self.top8_vs_union

	@classmethod
	def getTop8Deploy(cls, unionID):
		self = cls.Singleton
		roleIDs = self.top8_vs_union.get(unionID, [])
		ret = []
		for roleID in roleIDs:
			if roleID not in self.signup:
				continue
			ret.append(self.signup[roleID]['union_fight_record_db_id'])

		return ret

	@classmethod
	def setTop8Deploy(cls, unionID, roles):
		self = cls.Singleton
		self.top8_vs_union[unionID] = copy.deepcopy(roles)

	@classmethod
	def inTop8(cls, unionID):
		if not unionID:
			return False
		self = cls.Singleton
		return unionID in self.top8_vs_union

	# 日期
	date = db_property('date')

	# CraftGlobal.time
	time = db_property('time')

	# 上次结算日期
	last_award_time = db_property('last_award_time')

	# UnionFightGlobal.round
	round = db_property('round')

	# 报名 {Role.id: (recordID,unionID)}
	signup = db_property('signup')

	def top8_vs_union():
		dbkey = 'top8_vs_union'
		def fset(self, value):
			if self.db[dbkey] != value:
				self.db[dbkey] = value
		return locals()
	top8_vs_union = db_property(**top8_vs_union())

	# 历史前5公会ID，用于确定跨服公会战参赛名单
	top5_history = db_property('top5_history')

	@classmethod
	def getTop5History(cls):
		self = cls.Singleton
		return self.top5_history

	@classmethod
	def clearTop5History(cls):
		self = cls.Singleton
		self.top5_history = []

