#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2016 TianJi Information Technology Inc.
'''

from framework import period2date, inclock5date, nowdatetime_t, datetimefromtimestamp, DailyRefreshHour, nowdate_t
from framework.csv import csv, MergeServ
from framework.log import logger
from framework.object import db_property, ObjectNoGCDBase
from framework.service.helper import service_key2domains, gamemerge2game, service_key

from game import globaldata
from game.globaldata import *
from game.object import FeatureDefs, UnionDefs, CrossUnionFightDefs, SceneDefs, TitleDefs
from game.object.game.union_fight import ObjectUnionFightGlobal
from game.object.game.levelcsv import ObjectFeatureUnlockCSV
from game.object.game.servrecord import ObjectServerGlobalRecord
from game.object.game.union import ObjectUnion

import datetime
import copy
import random
import binascii

from tornado.gen import coroutine, Return


class ObjectCrossUnionFightGameGlobal(ObjectNoGCDBase):
	DBModel = 'CrossUnionFightGameGlobal'

	Singleton = None

	OpenDateTime = None
	OpenLevel = 0

	GlobalObjsMap = {}  # {areakey: ObjectCrossUnionFightGameGlobal}
	GlobalHalfPeriodObjsMap = {}  # {areakey: ObjectCrossUnionFightGameGlobal}

	RankAwardMap = {}  # {(type, rank): award}

	@classmethod
	def classInit(cls):
		cfg = csv.cross.union_fight.base[1]
		cls.OpenLevel = ObjectFeatureUnlockCSV.getOpenLevel(FeatureDefs.CrossUnionFight)

		openDay = cfg.servOpenDays
		cls.OpenDateTime = datetime.datetime.combine(
			inclock5date(globaldata.GameServOpenDatetime) + datetime.timedelta(days=openDay - 1),
			datetime.time(hour=DailyRefreshHour))

		# 排行奖励
		cls.RankAwardMap = {}
		for i in sorted(csv.cross.union_fight.rank_award):
			cfg = csv.cross.union_fight.rank_award[i]
			cls.RankAwardMap.setdefault((cfg.type, cfg.rank), cfg.award)

	def __init__(self, dbc):
		ObjectNoGCDBase.__init__(self, None, dbc)

	def set(self, dic):
		ObjectNoGCDBase.set(self, dic)
		self.isHalfPeriod = ObjectServerGlobalRecord.isHalfPeriod('cross_union_fight', self.key)
		return self

	def init(self, server, crossData):
		self.server = server
		self._cross = {}

		self.initCrossData(crossData)

		cls = ObjectCrossUnionFightGameGlobal
		cls.GlobalObjsMap[self.key] = self
		# global对象 key与当前服key对应
		if self.key == self.server.key:
			cls.Singleton = self

		# 是在半周期的话
		if self.isHalfPeriod:
			srcServs = MergeServ.getSrcServKeys(self.key)
			for srcServ in srcServs:
				cls.GlobalHalfPeriodObjsMap[srcServ] = self

		return self

	@classmethod
	def getByAreaKey(cls, key):
		return cls.GlobalHalfPeriodObjsMap.get(key, cls.Singleton)

	# 初始化 init
	def initCrossData(self, crossData):
		# crossData = {servers; csv_id; date; status}
		self._cross = crossData
		if crossData:
			self.join_unions = set(self._cross.get('join_unions', []))
			self.join_roles = set(self._cross.get('join_roles', []))
			self.status = self._cross.get('status', 'closed')
			self.csv_id = self._cross.get('csv_id', 0)
			self.date = self._cross.get('date', 0)
			logger.info('Cross Union Fight Init %s %s %s, csv_id %d', self.cross_key, self.date, self.status, self.csv_id)
		else:
			self.join_unions = set()
			self.join_roles = set()
			self.reset()

	def reset(self):
		self.status = 'closed'
		self.cross_key = ''
		return True

	def clean(self):
		self.pre_bet_success = []
		self.last_round_results = {}
		self.last_point_ranks = {}
		self.last_bets = {}
		self.last_unions = {}
		self.last_roles = {}
		self.last_battle_groups = {}

	@classmethod
	def isOpenDay(cls):
		return cls.OpenDateTime < nowdatetime_t()

	@classmethod
	def isCrossOpen(cls, areaKey):
		'''
		是否开启跨服玩法
		'''
		self = cls.getByAreaKey(areaKey)
		if not cls.isOpenDay():
			return False
		if self.cross_key == '' or self.status == "closed":
			return False
		return True

	@classmethod
	def isRoleOpen(cls, game):
		'''
		玩家是否满足条件
		'''
		if not cls.isOpenDay():
			return False
		union = game.union
		if not union:
			return False
		return union.isFeatureOpen(UnionDefs.CrossUnionFight) and game.role.level >= cls.OpenLevel

	@classmethod
	def isRoleEnter(cls, game):
		'''
		玩法开启且玩家满足条件
		'''
		role = game.role
		if not cls.isCrossOpen(role.areaKey):
			return False
		if not role.cross_union_fight_record_db_id:
			return False
		if not cls.isRoleOpen(game):
			return False
		return True

	@classmethod
	def isRoleJoinTime(cls, unionQuitTime, days):
		'''
		新加入的公会是否可以参加
		'''
		if unionQuitTime == 0:
			return True
		delta = inclock5date(nowdatetime_t()) - period2date(globaldata.DailyRecordRefreshTime, datetimefromtimestamp(unionQuitTime))
		if delta < datetime.timedelta(days=days):
			return False
		return True

	@classmethod
	def isCanBet(cls, areaKey, group):
		'''
		是否可押注
		'''
		self = cls.getByAreaKey(areaKey)
		if group != CrossUnionFightDefs.TopGroup:
			ret = self.status == CrossUnionFightDefs.StatusPrePrepare
		else:
			ret = self.status == CrossUnionFightDefs.StatusTopPrepare
		return ret

	@classmethod
	def isInPrepare(cls, areaKey):
		'''
		是否在准备期间
		'''
		self = cls.getByAreaKey(areaKey)
		ret = False
		if "Prepare" in self.status:
			ret = True
		return ret

	@classmethod
	def canDecompose(cls, areaKey):
		'''
		是否能分解
		'''
		self = cls.getByAreaKey(areaKey)
		ret = True
		gameStatus = ['prePrepare', 'preStart', 'preBattle', 'topPrepare', 'topStart', 'topBattle']
		if self.status in gameStatus:
			ret = False
		return ret

	@classmethod
	def cross_client(cls, areaKey, cross_key=None):
		'''
		获取cross rpc
		'''
		self = cls.getByAreaKey(areaKey)
		if cross_key is None:
			cross_key = self.cross_key
		if cross_key == '':
			return None
		container = self.server.container
		client = container.getserviceOrCreate(cross_key)
		return client

	@classmethod
	@coroutine
	def onCrossCommit(cls, key, transaction):
		'''
		跨服启动commit
		'''
		logger.info('ObjectCrossUnionFightGameGlobal.onCrossCommit %s %s', key, transaction)

		# cross竞争资源成功
		self = cls.Singleton
		if self.cross_key != '' and self.cross_key != key:
			logger.warning('ObjectCrossUnionFightGameGlobal.onCrossCommit %s', self.cross_key)
			raise Return(False)

		cls.cleanHalfPeriod()
		# 直接重置
		self.reset()
		self.cross_key = key
		raise Return(True)

	@classmethod
	def cleanHalfPeriod(cls):
		'''
		半周期合服，清理相关数据
		'''
		for _, obj in cls.GlobalObjsMap.iteritems():
			if obj.isHalfPeriod:  # 清除半周期状态
				ObjectServerGlobalRecord.overHalfPeroid('cross_union_fight', obj.key)
				obj.isHalfPeriod = ObjectServerGlobalRecord.isHalfPeriod('cross_union_fight', obj.key)
				# TODO 清理数据
				obj.last_round_results = {}
				obj.last_point_ranks = {}

		cls.GlobalHalfPeriodObjsMap = {}

	@classmethod
	@coroutine
	def onCrossEvent(cls, event, key, data, sync):
		'''
		玩法流程
		'''
		logger.info('ObjectCrossUnionFightGameGlobal.onCrossEvent %s %s', key, event)
		self = cls.getByAreaKey(key)
		if sync:
			self.status = sync['status']
		ret = {}
		if event == 'init':
			self.initCrossData(data.get('model', {}))
			self.clean()
		if event == 'pointRank':
			rank = yield self.calcUnionFightPointRank()
			ret["union_fight_point_rank"] = rank
		elif event == 'joinUnions':
			self.join_unions = set(data['union_ids'])  # 全部参赛公会名单
		# 初赛
		elif event == 'unionsMembers':
			unionsMembers = yield self.onPrePrepare(data['union_ids'])
			ret["unions_members"] = unionsMembers
		elif event == 'prePrepare':
			self.join_roles = set(data['role_ids'])  # 全部参赛玩家名单
			ObjectUnionFightGlobal.clearTop5History()
		elif event == 'preStart':
			pass
		elif event == 'preBattle':
			pass
		elif event == 'preOver':
			lastPreRanks = data.get('last_ranks', {})
			lastBets = data.get('last_bets', {})
			preResults = data.get('last_results', {})
			self.onPreOver(preResults, lastBets, lastPreRanks)
		elif event == 'preAward':
			unionRoles = data.get('union_roles', {})
			self.onPreAwards(unionRoles, key)
		# 决赛
		elif event == 'topPrepare':
			pass
		elif event == 'topStart':
			pass
		elif event == 'topBattle':
			pass
		elif event == 'topOver':
			lastTopRanks = data.get('last_ranks', [])
			lastBets = data.get('last_bets', {})
			topResults = data.get('last_results', {})
			self.onTopOver(topResults, lastBets, lastTopRanks)
		elif event == 'topAward':
			unionRoles = data.get('union_roles', {})
			self.onTopAwards(unionRoles, key)
		elif event == 'closed':
			self.onClosed()
			self.last_unions = data.get('last_unions', {})
			self.last_roles = data.get('last_roles', {})
			self.last_battle_groups = data.get('last_battle_groups', {})

		raise Return(ret)

	@coroutine
	def calcUnionFightPointRank(self):
		'''
		计算公会战积分排行
		'''
		top5History = ObjectUnionFightGlobal.getTop5History()
		unionPoints = {}  # {unionID: point}
		for top5Ranks in top5History:
			for rank, unionID in enumerate(top5Ranks, 1):
				cfg = csv.union_fight.rank_point[rank]
				point = 0
				if cfg:
					point = cfg.point
				unionPoints[unionID] = unionPoints.get(unionID, 0) + point

		_, language, _ = service_key2domains(self.server.key)
		unions = unionPoints.items()
		unions = sorted(unions, key=lambda x: x[1], reverse=True)
		ranks = []
		for unionID, point in unions:
			try:
				model = yield self.server.rpcUnion.call_async('GetUnionModel', unionID)
				if not model:
					continue
			except Exception, e:
				logger.warning('ObjectCrossUnionFightGameGlobal.calcUnionFightPointRank not this union %s', binascii.hexlify(unionID))
				continue

			# 公会等级判断
			if model['level'] < ObjectUnion.FeatureMap.get(UnionDefs.CrossUnionFight, 999999):
				continue
			info = {
				'game_key': service_key('game', model['area'], language),
				'union_db_id': unionID,
				'union_name': model['name'],
				'union_logo': model['logo'],
				'point': point,
			}
			ranks.append(info)
		self.union_fight_point_rank = ranks
		raise Return(ranks)

	@coroutine
	def onPrePrepare(self, unionIDs):
		'''
		获取公会名单、玩家名单
		'''
		_, language, _ = service_key2domains(self.server.key)
		unionsMap = {}
		for unionID in unionIDs:
			try:
				unionModel = yield self.server.rpcUnion.call_async('GetUnionModel', unionID)
				if not unionModel:
					logger.warning('ObjectCrossUnionFightGameGlobal.onPrePrepare not this union %s', binascii.hexlify(unionID))
					continue
			except Exception, e:
				logger.warning('ObjectCrossUnionFightGameGlobal.onPrePrepare not this union %s', binascii.hexlify(unionID))
				continue

			chairmanID = unionModel['chairman_db_id']
			members = unionModel['members']
			newMembers = {}
			for roleID, memberRole in members.iteritems():
				if memberRole['level'] < self.OpenLevel:
					continue
				# 三周没有进行过公会行为
				lasttime = memberRole['lasttime']
				lastdt = datetimefromtimestamp(lasttime)
				delta = (nowdate_t() - lastdt.date()).days
				if delta >= 21:
					continue
				newMembers[roleID] = memberRole
			unionsMap[unionID] = {
				'members':	 		newMembers,
				'chairman_db_id': 	chairmanID,
				'game_key': 		service_key('game', unionModel['area'], language),
			}
		raise Return(unionsMap)

	def onPreOver(self, preResults, lastBets, lastPreRanks):
		'''
		初赛 排行、战报和竞猜
		'''
		logger.info('ObjectCrossUnionFightGameGlobal.onPreOver')
		self.last_round_results = preResults
		self.last_point_ranks = lastPreRanks
		self.last_bets = lastBets

	def onPreAwards(self, unionRoles, key):
		'''
		初赛 发排名奖励 竞猜奖励
		'''
		logger.info('ObjectCrossUnionFightGameGlobal.onPreRankAwards')
		for group, preRanks in self.last_point_ranks.iteritems():
			if group <= 4:
				self.onRankAward(unionRoles, preRanks, CrossUnionFightDefs.PreStage, group)
		# 发初赛竞猜奖励
		self.onBetAward(CrossUnionFightDefs.PreStage, key)

	def onTopOver(self, topResults, lastBets, lastTopRanks):
		'''
		决赛 排行、战报和竞猜
		'''
		logger.info('ObjectCrossUnionFightGameGlobal.onTopOver')
		self.last_round_results.update(topResults)
		self.last_bets = lastBets
		self.last_point_ranks.update(lastTopRanks)

	def onTopAwards(self, unionRoles, key):
		'''
		决赛 发排名奖励 竞猜奖励
		'''
		logger.info('ObjectCrossUnionFightGameGlobal.onTopRankAwards')
		topRanks = self.last_point_ranks.get(CrossUnionFightDefs.TopGroup, {})
		self.onRankAward(unionRoles, topRanks, CrossUnionFightDefs.TopStage, CrossUnionFightDefs.TopGroup)
		# 发决赛竞猜奖励
		self.onBetAward(CrossUnionFightDefs.TopStage, key)

	def onClosed(self):
		'''
		跨服结束
		'''
		logger.info('ObjectCrossUnionFightGameGlobal.onClosed')
		self.status = 'closed'
		self.cross_key = ''
		self.union_fight_point_rank = []
		self.join_unions = set()
		self.join_roles = set()

	def onRankAward(self, unionRoles, ranks, stage, group):
		'''
		发排名奖励
		'''
		from game.mailqueue import MailJoinableQueue
		from game.object.game.role import ObjectRole
		count = 0
		roleRanks = {}  # {roleID: rank}
		for i, rankInfo in enumerate(ranks):
			unionID = rankInfo.get("union_db_id", None)
			roleIDs = []
			if unionID:
				roleIDs = unionRoles.get(unionID, [])
			count += len(roleIDs)
			rank = i + 1
			for roleID in roleIDs:
				award = self.RankAwardMap.get((stage, rank), {})
				if stage == CrossUnionFightDefs.PreStage:  # 初赛
					mailID = CrossUnionFightPreRankAwardMailID
				else:
					mailID = CrossUnionFightTopRankAwardMailID
					if rank == 1:
						roleRanks[roleID] = rank
				mail = ObjectRole.makeMailModel(roleID, mailID, contentArgs=rank, attachs=award)
				MailJoinableQueue.send(mail)
		# 决赛称号
		if stage == CrossUnionFightDefs.TopStage:
			from game.object.game.servrecord import ObjectServerGlobalRecord
			ObjectServerGlobalRecord.saveTitleRanks(TitleDefs.CrossUnionFight, roleRanks)
		logger.info('ObjectCrossUnionFightGameGlobal.onRankAward stage %d group %d unions %d roles %d', stage, group, len(unionRoles), count)

	def onBetAward(self, stage, key):
		'''
		发押注奖励
		'''
		from game.mailqueue import MailJoinableQueue
		from game.object.game.role import ObjectRole
		winCount = 0
		failCount = 0
		roleWinCount = {}  # {roleID: count}
		roleFailCount = {}  # {roleID: count}
		cfg = csv.cross.union_fight.base[1]
		unionBets = {}
		if stage == CrossUnionFightDefs.PreStage:
			for group, bets in self.last_bets.iteritems():
				if group != CrossUnionFightDefs.TopGroup:
					unionBets.update(bets)
		else:
			unionBets = self.last_bets.get(CrossUnionFightDefs.TopGroup, {})
		for unionID, betInfo in unionBets.iteritems():
			roleKeys = betInfo.get("role_keys", [])
			success = betInfo.get("success", False)
			for roleKey in roleKeys:
				gameKey = roleKey[0]
				roleID = roleKey[1]
				if gameKey == key:
					if success:  # 成功
						winCount += 1
						count = roleWinCount.setdefault(roleID, 0)
						roleWinCount[roleID] = count + 1
					else:  # 失败
						failCount += 1
						count = roleFailCount.setdefault(roleID, 0)
						roleFailCount[roleID] = count + 1

		# 初赛
		if stage == CrossUnionFightDefs.PreStage:
			# 初赛有押中
			for roleID, count in roleWinCount.iteritems():
				if count == 4 and (roleID not in self.pre_bet_success):
					self.pre_bet_success.append(roleID)
				mailID = CrossUnionFightPreBetAwardMailID
				winAward = {}
				# 押中
				for i in range(count):
					dictSum(winAward, cfg.preBetWinAward)
				# 失败
				failCount = roleFailCount.get(roleID, 0)
				if 0 < failCount < 4:
					for i in range(failCount):
						dictSum(winAward, cfg.preBetFailAward)
				mail = ObjectRole.makeMailModel(roleID, mailID, contentArgs=count, attachs=winAward)
				MailJoinableQueue.send(mail)
			# 初赛全失败
			for roleID, count in roleFailCount.iteritems():
				if count == 4:
					mailID = CrossUnionFightPreBetAwardFailMailID
					failAward = {}
					for i in range(count):
						dictSum(failAward, cfg.preBetFailAward)
					mail = ObjectRole.makeMailModel(roleID, mailID, attachs=failAward)
					MailJoinableQueue.send(mail)
		else:
			# 决赛有押中
			for roleID, count in roleWinCount.iteritems():
				mailID = CrossUnionFightTopBetAwardMailID
				winAward = {}
				# 押中
				for i in range(count):
					dictSum(winAward, cfg.top4BetWinAward)
				# 失败
				failCount = roleFailCount.get(roleID, 0)
				if 0 < failCount < 4:
					for i in range(failCount):
						dictSum(winAward, cfg.top4BetFailAward)
				# 额外奖励
				if roleID in self.pre_bet_success:
					dictSum(winAward, cfg.extraAward)
				mail = ObjectRole.makeMailModel(roleID, mailID, contentArgs=count, attachs=winAward)
				MailJoinableQueue.send(mail)
			# 决赛全失败
			for roleID, count in roleFailCount.iteritems():
				if count == 4:
					mailID = CrossUnionFightTopBetAwardFailMailID
					failAward = {}
					for i in range(count):
						dictSum(failAward, cfg.top4BetFailAward)
					mail = ObjectRole.makeMailModel(roleID, mailID, attachs=failAward)
					MailJoinableQueue.send(mail)

		logger.info('ObjectCrossUnionFightGameGlobal.onBetAward %d win %d fail %d', stage, winCount, failCount)

	@classmethod
	def makeCardsAttr(cls, game, project, cardIDs):
		'''
		获取卡牌属性
		'''
		cardAttr1 = {}
		cardAttr2 = {}
		if project == CrossUnionFightDefs.BattleSix:
			cardsD11, cardsD12 = game.cards.makeBattleCardModel(cardIDs[:6], SceneDefs.CrossUnionFight)
			cardsD21, cardsD22 = game.cards.makeBattleCardModel(cardIDs[6:12], SceneDefs.CrossUnionFight)
			cardAttr1.update(cardsD11)
			cardAttr1.update(cardsD21)
			cardAttr2.update(cardsD12)
			cardAttr2.update(cardsD22)
		elif project == CrossUnionFightDefs.BattleFour:
			cardsD11, cardsD12 = game.cards.makeBattleCardModel(cardIDs[:6], SceneDefs.CrossUnionFight)
			cardsD21, cardsD22 = game.cards.makeBattleCardModel(cardIDs[6:12], SceneDefs.CrossUnionFight)
			cardsD31, cardsD32 = game.cards.makeBattleCardModel(cardIDs[12:18], SceneDefs.CrossUnionFight)
			cardAttr1.update(cardsD11)
			cardAttr1.update(cardsD21)
			cardAttr1.update(cardsD31)
			cardAttr2.update(cardsD12)
			cardAttr2.update(cardsD22)
			cardAttr2.update(cardsD32)
		else:
			cardsD11, cardsD12 = game.cards.makeBattleCardModel(cardIDs[:3], SceneDefs.CrossUnionFight)
			cardsD21, cardsD22 = game.cards.makeBattleCardModel(cardIDs[3:6], SceneDefs.CrossUnionFight)
			cardsD31, cardsD32 = game.cards.makeBattleCardModel(cardIDs[6:9], SceneDefs.CrossUnionFight)
			cardAttr1.update(cardsD11)
			cardAttr1.update(cardsD21)
			cardAttr1.update(cardsD31)
			cardAttr2.update(cardsD12)
			cardAttr2.update(cardsD22)
			cardAttr2.update(cardsD32)
		return cardAttr1, cardAttr2

	@classmethod
	def delOldCards(cls, deployment, stage):
		'''
		删掉原来布阵
		'''
		for key, keyCards in deployment.cards.iteritems():
			ty, project = key
			if ty == stage:
				deployment.popCardsByKey(key)

	@classmethod
	def makeLastModel(cls, areaKey):
		'''
		结束后的上期model
		'''
		return {
			'last_top_point_ranks': cls.getLastTopRanks(areaKey),
			'last_battle_groups': cls.getLastBattleGroups(areaKey),
			'unions': cls.getLastUnions(areaKey),
			'roles': cls.getLastRoles(areaKey),
		}

	@classmethod
	def getCrossGameModel(cls, areaKey):
		'''
		缩略model
		'''
		self = cls.getByAreaKey(areaKey)
		servers = []
		if self._cross:
			servers = self.servers
		return {
			'date': self.date,
			'status': self.status,
			'csv_id': self.csv_id,
			'servers': servers,
			'cross_key': self.cross_key,
		}

	@classmethod
	def markCrossUnionFightRoleInfo(cls, role, cardsD):
		roleInfo = {
			'role_db_id': role.id,
			'record_id': role.cross_union_fight_record_db_id,
			'server_key': role.areaKey,
			'role_name': role.name,
			'role_level': role.level,
			'role_logo': role.logo,
			'role_frame': role.frame,
			'role_figure': role.figure,

			'union_db_id': role.union_db_id,
		}

		union = ObjectUnion.getUnionByUnionID(role.union_db_id)
		if union:
			roleInfo['union_logo'] = union.logo
			roleInfo['union_name'] = union.name
			if union.chairman_db_id == role.id:
				roleInfo['chairman_id'] = role.id
				roleInfo['chairman_name'] = role.name
				roleInfo['chairman_figure'] = role.figure
				roleInfo['chairman_title'] = role.title_id

		fightingPoint = 0
		for dbID, card in cardsD.iteritems():
			fightingPoint = fightingPoint + card['fighting_point']
		if fightingPoint:
			roleInfo["fighting_point"] = fightingPoint
		return roleInfo

	@classmethod
	@coroutine
	def getUnionFightPointRank(cls, areaKey):
		self = cls.getByAreaKey(areaKey)
		if not self.union_fight_point_rank:
			ranks = yield self.calcUnionFightPointRank()
		else:
			ranks = self.union_fight_point_rank
		raise Return((ranks, list(self.join_unions)))

	@classmethod
	def isInJoinUnions(cls, areaKey, unionID):
		'''
		公会是否入选
		'''
		self = cls.getByAreaKey(areaKey)
		return self.inJoinUnions(unionID)

	def inJoinUnions(self, unionID):
		return unionID in self.join_unions

	@classmethod
	def isInJoinRoles(cls, areaKey, roleID):
		'''
		玩家是否入选
		'''
		self = cls.getByAreaKey(areaKey)
		return roleID in self.join_roles

	@classmethod
	def rankOneUnionDisplay(cls, areaKey):
		self = cls.getByAreaKey(areaKey)
		display = {}
		topRanks = self.last_point_ranks.get(CrossUnionFightDefs.TopGroup, [])
		if len(topRanks) == 0 or self.status != "closed":
			return display
		display['union_db_id'] = topRanks[0]['union_db_id']
		display['union_name'] = topRanks[0]['union_name']
		display['server_key'] = topRanks[0]['server_key']
		return display

	# server_key
	key = db_property('key')

	# 跨服server key
	cross_key = db_property('cross_key')

	# 日期
	date = db_property('date')

	# 跨服csv_id
	csv_id = db_property('csv_id')

	# 赛季状态
	status = db_property('status')

	# 区服
	@property
	def servers(self):
		return self._cross.get('servers', [])

	# 上期 排行榜 {组别: [CrossUnionFightRankPoint]} 决赛用5
	last_point_ranks = db_property('last_point_ranks')

	# 上期初/决赛 竞猜 {组别: {公会ID: [CrossUnionFightBet]} 决赛用5
	last_bets = db_property('last_bets')

	# 上期回顾 战报 {组别: {轮次: {战场: [CrossUnionFightResultInfo]}}} 决赛用5
	last_round_results = db_property('last_round_results')

	# 初赛全部竞猜正确名单 [roleID]
	pre_bet_success = db_property('pre_bet_success')

	# 公会战积分排行
	union_fight_point_rank = db_property('union_fight_point_rank')

	# 上期公会
	last_unions = db_property('last_unions')

	# 上期玩家
	last_roles = db_property('last_roles')

	# 上期战斗组 {组别: [unionID]}  决赛用5
	last_battle_groups = db_property('last_battle_groups')

	@classmethod
	def getStatus(cls, areaKey):
		self = cls.getByAreaKey(areaKey)
		return self.status

	@classmethod
	def getRankList(cls, areaKey):
		self = cls.getByAreaKey(areaKey)
		return self.last_point_ranks

	@classmethod
	def getLastTopRanks(cls, areaKey):
		self = cls.getByAreaKey(areaKey)
		return self.last_point_ranks.get(CrossUnionFightDefs.TopGroup, [])

	@classmethod
	def getLastRoundResults(cls, areaKey, group=None):
		self = cls.getByAreaKey(areaKey)
		if not group:
			return self.last_round_results
		else:
			results = {group: self.last_round_results.get(group, {})}
			return results

	@classmethod
	def getLastBets(cls, areaKey):
		self = cls.getByAreaKey(areaKey)
		return self.last_bets

	@classmethod
	def getLastUnions(cls, areaKey):
		self = cls.getByAreaKey(areaKey)
		return self.last_unions

	@classmethod
	def getLastRoles(cls, areaKey):
		self = cls.getByAreaKey(areaKey)
		return self.last_roles

	@classmethod
	def getLastBattleGroups(cls, areaKey):
		self = cls.getByAreaKey(areaKey)
		return self.last_battle_groups

	@classmethod
	def getLastDeployRoles(cls, areaKey, stage, unionID):
		self = cls.getByAreaKey(areaKey)
		unionInfo = self.last_unions.get(unionID, {})
		if stage == CrossUnionFightDefs.PreStage:
			deployRoles = unionInfo.get('pre_deploy_roles', [])
		else:
			deployRoles = unionInfo.get('top_deploy_roles', [])
		return deployRoles

	@classmethod
	def cleanPointRankList(cls):
		self = cls.Singleton
		self.union_fight_point_rank = []


def dictSum(d1, d2):
	''' 把d2的内容加到d1里'''
	t = copy.copy(d2)
	for key in d1:
		if key in t:
			t[key] += d1[key]
	d1.update(t)