#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2014 YouMi Information Technology Inc.
'''

from framework import todayinclock5elapsedays
from framework.csv import csv, MergeServ
from framework.helper import WeightRandomObject, transform2list
from framework.log import logger
from framework.object import ObjectNoGCDBase, db_property

from game import globaldata, ClientError
from game.globaldata import CrossArenaFinishAwardMailID, CrossArena7DayAwardMailID
from game.object import FeatureDefs, TitleDefs, MessageDefs
from game.object.game.message import ObjectMessageGlobal
from game.object.game.levelcsv import ObjectFeatureUnlockCSV
from game.object.game.robot import makeRobot

import random
from collections import defaultdict

from game.object.game.servrecord import ObjectServerGlobalRecord
from tornado.gen import coroutine, Return, sleep


#
# ObjectCrossArenaGameGlobal
#
class ObjectCrossArenaGameGlobal(ObjectNoGCDBase):
	DBModel = 'CrossArenaGameGlobal'

	Singleton = None

	OpenLevel = 0
	RobotName = None

	StageMap = {}  # 段位 {version: [csvID]}

	StageAwardMap = {}  # 段位奖励 {(version,stageID): [csvID]}

	StageStartRankMap = {}  # 段位起始排名 {(version,stageID): startRank}

	GlobalObjsMap = {}  # {areakey: ObjectCrossArenaGameGlobal}
	GlobalHalfPeriodObjsMap = {}  # {areakey: ObjectCrossArenaGameGlobal}

	@classmethod
	def classInit(cls):
		cfg = csv.cross.arena.base[1]
		cls.RobotName = cfg.robotName
		cls.OpenLevel = ObjectFeatureUnlockCSV.getOpenLevel(FeatureDefs.CrossArena)

		# 段位
		cls.StageMap = {}
		cls.StageAwardMap = {}
		for i in sorted(csv.cross.arena.stage):
			cfg = csv.cross.arena.stage[i]
			stages = cls.StageMap.setdefault(cfg.version, [])
			stages.append(i)
			csvIDs = cls.StageAwardMap.setdefault((cfg.version, cfg.stageID), [])
			csvIDs.append(i)
			startRank = cls.StageStartRankMap.setdefault((cfg.version, cfg.stageID), cfg.range[0])
			cls.StageStartRankMap[(cfg.version, cfg.stageID)] = min(cfg.range[0], startRank)

	def __init__(self, dbc):
		ObjectNoGCDBase.__init__(self, None, dbc)

	def set(self, dic):
		ObjectNoGCDBase.set(self, dic)
		self.isHalfPeriod = ObjectServerGlobalRecord.isHalfPeriod('cross_arena', self.key)
		return self

	def init(self, server, crossData):
		self.server = server
		self._roleRankMap = {}  # {roleID: CrossArenaRoleInfo}
		self._cross = {}

		self.initCrossData(crossData)

		cls = ObjectCrossArenaGameGlobal
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
	def cleanHalfPeriod(cls):
		'''
		半周期结束，清理相关数据
		'''
		for _, obj in cls.GlobalObjsMap.iteritems():
			if obj.isHalfPeriod: # 清除半周期状态
				ObjectServerGlobalRecord.overHalfPeroid('cross_arena', obj.key)
				obj.isHalfPeriod = ObjectServerGlobalRecord.isHalfPeriod('cross_arena', obj.key)
				obj.last_ranks = []
				obj.top_battle_history = []

		cls.GlobalHalfPeriodObjsMap = {}

	@classmethod
	def getByAreaKey(cls, key):
		return cls.GlobalHalfPeriodObjsMap.get(key, cls.Singleton)

	# server_key
	key = db_property('key')

	# 跨服server key
	cross_key = db_property('cross_key')

	# 上期排行榜
	last_ranks = db_property('last_ranks')

	# 赛季状态
	round = db_property('round')

	# 排行奖励已领取 段位 {roleID: {1: sevenStage, 2: finishStage} 缓存
	period_award_stages = db_property('period_award_stages')

	# 跨服csv_id
	csv_id = db_property('csv_id')

	# 精彩战报
	top_battle_history = db_property('top_battle_history')

	@property
	def servers(self):
		return self._cross.get('servers', [])

	@property
	def date(self):
		return self._cross.get('date', 0)

	@classmethod
	def isOpen(cls, areaKey):
		'''
		是否开启玩法
		'''
		self = cls.getByAreaKey(areaKey)
		if self.cross_key == '' or self.round == "closed":
			return False
		return True

	@classmethod
	def isRoleOpen(cls, level):
		'''
		玩家是否达到开启条件
		'''
		return level >= cls.OpenLevel

	@classmethod
	def getRound(cls, areaKey):
		self = cls.getByAreaKey(areaKey)
		return self.round

	@classmethod
	def getVersion(cls, areaKey):
		self = cls.getByAreaKey(areaKey)
		return self.version

	@classmethod
	def getCrossKey(cls, areaKey):
		self = cls.getByAreaKey(areaKey)
		return self.cross_key

	@classmethod
	def getDate(cls, areaKey):
		self = cls.getByAreaKey(areaKey)
		return self.date

	@classmethod
	def getCsvID(cls, areaKey):
		self = cls.getByAreaKey(areaKey)
		return self.csv_id

	@classmethod
	def getTopBattleHistory(cls, areaKey):
		self = cls.getByAreaKey(areaKey)
		return self.top_battle_history

	@classmethod
	@coroutine
	def onCrossEvent(cls, event, key, data, sync):
		'''
		玩法流程
		'''
		logger.info('ObjectCrossArenaGameGlobal.onCrossEvent %s %s', key, event)

		self = cls.getByAreaKey(key)
		if sync:
			self.round = sync['round']

		ret = {}
		if event == 'init':
			self.initCrossData(data.get('model', {}))
		elif event == 'prepare':
			# 给 cross 传开服天数
			days = self.onPrepare()
			ret["open_server_days"] = days
		elif event == 'robot':
			# 从 cross 拿机器人数量
			openday = data['open_day']
			robotRanks = data['robot_ranks']
			ret['robots'] = yield self.onMakeRobots(key, openday, robotRanks)
		elif event == 'start':
			self.onStart()
		elif event == 'rankTitle':
			roleRanks = data.get('role_ranks', {})
			self.onRankTitle(roleRanks)
		elif event == 'refreshTopHistory':
			self.refreshTopHistoryMsg()
		elif event == 'sevenDaysAward':
			roleRanks = data.get('role_ranks', {})
			self.onSevenDaysAward(roleRanks)
		elif event == 'closed':
			lastRanks = data.get('last_ranks', [])
			topBattleHistory = data.get('top_battle_history', [])
			self.onClosed(lastRanks, topBattleHistory)
		elif event == 'finishAward':
			roleRanks = data.get('role_ranks', {})
			self.onFinishAward(roleRanks)

		raise Return(ret)

	# 初始化 init
	def initCrossData(self, crossData):
		# crossData = {servers; csv_id; date; round}
		self._cross = crossData
		if crossData:
			self.round = self._cross.get('round', 'closed')
			self.csv_id = self._cross.get('csv_id', 0)
			if self.csv_id > 0:
				self.version = csv.cross.service[self.csv_id].version
			logger.info('Cross Arena Init %s %s %s, csv_id %d', self.cross_key, self.date, self.round, self.csv_id)
		else:
			self.reset()

	# 开始准备 init -> prepare
	def onPrepare(self):
		logger.info('ObjectCrossArenaGameGlobal.onPrepare')

		# 开服天数
		days = todayinclock5elapsedays(globaldata.GameServOpenDatetime)
		return days

	# 构建机器人 prepare -> robots
	@coroutine
	def onMakeRobots(self, key, openday, robotRanks):
		if len(robotRanks) <= 0:
			raise Return({})
		# 构建机器人
		makeRobots = yield self.makeRobots(key, openday, robotRanks)
		robots = makeRobots['robots']
		arenaRoleInfos = makeRobots['arenaRoleInfos']

		# 创建机器人 CrossArenaRecord
		total = len(robots)
		if total > 100:
			step = 100
			count = total / step
			for idx in xrange(count):
				left, right = idx * step, (idx+1) * step
				if idx == count-1:
					right = total
				ret = yield self.server.rpcPVP.call_async('CreateRobotCrossArenaRecordBulk', robots[left:right])
				logger.info('ObjectCrossArenaGameGlobal.onMakeRobots. Create Robot CrossArenaRecord Finished %d, [%d, %d) %s', idx, left, right, ret)
		else:
			ret = yield self.server.rpcPVP.call_async('CreateRobotCrossArenaRecordBulk', robots)
			logger.info('ObjectCrossArenaGameGlobal.onMakeRobots. Create Robot CrossArenaRecord Finished %s', ret)
		raise Return(arenaRoleInfos)

	# 赛季开始 robots -> start
	def onStart(self):
		logger.info('ObjectCrossArenaGameGlobal.onStart')
		self.round = 'start'
		# 清空上期排行
		self.last_ranks = []
		self._roleRankMap = {}
		self.period_award_stages = {}
		self.top_battle_history = []

	# 每日结算排行称号
	def onRankTitle(self, roleRanks):
		logger.info('ObjectCrossArenaGameGlobal.onRankTitle')
		from game.object.game.servrecord import ObjectServerGlobalRecord
		ObjectServerGlobalRecord.saveTitleRanks(TitleDefs.CrossArenaDaily, roleRanks)

	# 7日赛季奖励 start -> sevenDaysAward
	def onSevenDaysAward(self, roleRanks):
		logger.info('ObjectCrossArenaGameGlobal.onSevenDaysAward')
		self.onRankAward(roleRanks, 1)

	# 赛季结束 sevenDaysAward -> closed
	def onClosed(self, lastRanks, topBattleHistory):
		logger.info('ObjectCrossArenaGameGlobal.onClosed')
		self.round = 'closed'
		self.cross_key = ''
		self.last_ranks = lastRanks
		self.top_battle_history = topBattleHistory

	# 赛季排名奖励 closed -> onFinishAward
	def onFinishAward(self, roleRanks):
		logger.info('ObjectCrossArenaGameGlobal.onFinishAward')
		self.onRankAward(roleRanks, 2)

	def reset(self):
		'''
		赛季初始化 数据重置
		'''
		self.round = 'closed'
		self.cross_key = ''
		return True

	@classmethod
	@coroutine
	def onCrossCommit(cls, key, transaction):
		'''
		跨服启动commit
		'''
		logger.info('ObjectCrossArenaGameGlobal.onCrossCommit %s %s', key, transaction)

		# cross竞争资源成功
		self = cls.Singleton
		# 玩法已经被占用
		if self.cross_key != '' and self.cross_key != key:
			logger.warning('ObjectCrossArenaGameGlobal.onCrossCommit %s', self.cross_key)
			raise Return(False)

		cls.cleanHalfPeriod()
		# 直接重置
		self.reset()
		self.cross_key = key
		raise Return(True)

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

	@coroutine
	def makeRobots(self, key, openday, robotRanks):
		total = len(robotRanks)
		logger.info('Cross Arena Start Make Robots %d', total)

		robots = []
		arenaRoleInfos = {} # {rank: info}
		roleLevel = 1
		baseFightingPoint = 0
		# 基准战力
		for i in sorted(csv.cross.arena.robot):
			cfg = csv.cross.arena.robot[i]
			if cfg.daysRange[0] <= openday < cfg.daysRange[1]:
				roleLevel = cfg.level
				baseFightingPoint = cfg.fightingPoint
				break
		# logger.info('openday %d, base fighting_point %d', openday, baseFightingPoint)
		for idx, rank in enumerate(robotRanks, 1):
			if idx % 100 == 0:
				logger.info('Cross Arena Making Robots %d / %d', idx, total)
			# 战力修正
			for i in sorted(csv.cross.arena.robot_fix):
				cfg = csv.cross.arena.robot_fix[i]
				if cfg.range[0] <= rank < cfg.range[1]:
					fightingPoint = baseFightingPoint * cfg.fightC # 两队战力之和
					fixCsvID = i
					break
			# 战力==>>怪物等级
			fightingPoint = fightingPoint / 2 # 上述为两队之和
			# logger.info('rank %d, expect fighting_point %f', rank, fightingPoint)
			kwargs = None
			level = None
			for i in sorted(csv.cross.arena.robot_monster_level):
				cfg = csv.cross.arena.robot_monster_level[i]
				if cfg.fightStart <= fightingPoint < cfg.fightEnd:
					level = cfg.level
					kwargs = {
						'level': cfg.level,
						'advance': random.randint(cfg.advanceStart, cfg.advanceEnd),
						'star': random.randint(cfg.starStart, cfg.starEnd),
						'skillLevel': cfg.skillLevel,
						'name': self.RobotName,

						# 属性修正
						'hpC': cfg.hpC,
						'speedC': cfg.speedC,
						'damageC': cfg.damageC,
						'defenceC': cfg.defenceC,
						'specialDamageC': cfg.specialDamageC,
						'specialDefenceC': cfg.specialDefenceC,
					}
					break
			# 怪物卡牌CsvIDs
			cardCsvIDs = []
			randomList = []
			for i in sorted(csv.cross.arena.robot_monsters):
				cfg = csv.cross.arena.robot_monsters[i]
				if cfg.levelStart <= level <= cfg.levelEnd and fixCsvID in cfg.rangeFixs:
					randomList.append(i)
			monsterCsvID = random.choice(randomList)
			cfgMonster = csv.cross.arena.robot_monsters[monsterCsvID]
			cardCsvIDs.extend(cfgMonster.monsters1)
			cardCsvIDs.extend(cfgMonster.monsters2)

			roleID = self.server.getRobotObjectID(idx, 'cross_arena', key)  # 机器人RoleID
			# 构造单个机器人
			robot = yield makeRobot(roleID, cardCsvIDs, fightingPoint=fightingPoint, **kwargs)
			cards = robot.get("cards", [])
			cardsMap = defaultdict(dict)
			cardsMap[1] = transform2list(cards[:6])
			cardsMap[2] = transform2list(cards[6:12])
			robot["cards"] = cardsMap

			defenceCards = robot.get("defence_cards", [])
			defenceCardsMap = defaultdict(dict)
			defenceCardsMap[1] = transform2list(defenceCards[:6])
			defenceCardsMap[2] = transform2list(defenceCards[6:12])
			robot["defence_cards"] = defenceCardsMap

			robots.append(robot)

			display = 1
			# 构造 arenaRoleInfo
			if len(cards) > 0:
				cardAttrs = robot.get("card_attrs", {})
				cardAttr = cardAttrs.get(cards[0], {})
				if cardAttr:
					display = cardAttr['card_id']
			# 实际战力
			realFightingPoint = 0
			for id, cardAttr in robot["defence_card_attrs"].iteritems():
				realFightingPoint = realFightingPoint + cardAttr['fighting_point']
			# logger.info('rank %d, got fighting_point %f', rank, realFightingPoint)
			arenaRoleInfos[rank] = {
				'role_db_id': roleID,
				'name': robot["name"],
				'level': robot["level"],
				'logo': robot["logo"],
				'frame': robot["frame"],
				'figure': robot["figure"],
				'vip': robot["vip"],

				'display': display,
				'record_db_id': roleID,
				'fighting_point': realFightingPoint,
			}

		ret = {
			"robots": robots,
			"arenaRoleInfos": arenaRoleInfos
		}
		logger.info('Cross Arena End Make Robots %d', len(robots))
		raise Return(ret)

	@classmethod
	def getRankList(cls, areaKey, offest, size, roleID):
		'''
		结束后的排行榜
		'''
		self = cls.getByAreaKey(areaKey)
		if self.cross_key == '' or self.round == 'closed':
			if not self._roleRankMap:
				for rank, role in enumerate(self.last_ranks, 1):
					self._roleRankMap[role['role_db_id']] = role
			return {
				'ranks': self.last_ranks[offest:offest + size],
				'myinfo': self._roleRankMap.get(roleID, None),
			}
		return None

	def getStageRank(self, rank):
		'''
		段位内排名
		'''
		stageID = 0
		stageRank = 0
		for i in ObjectCrossArenaGameGlobal.StageMap[self.version]:
			cfg = csv.cross.arena.stage[i]
			if cfg.range[0] <= rank < cfg.range[1]:
				stageID = cfg.stageID
				stageRank = rank - ObjectCrossArenaGameGlobal.StageStartRankMap[(self.version, cfg.stageID)] + 1
				break
		return stageID, stageRank

	def onRankAward(self, roleRanks, type):
		'''
		赛季奖励（7日和结束）
		'''
		from game.mailqueue import MailJoinableQueue
		from game.object.game.role import ObjectRole
		from game.object.game import ObjectGame

		logger.info('ObjectCrossArenaGameGlobal.onRankAward %s', len(roleRanks))

		csvIDs = ObjectCrossArenaGameGlobal.StageMap[self.version]
		for roleID, rank in roleRanks.iteritems():
			if 'rbt' in roleID:  # robot
				continue
			stageID, stageRank = self.getStageRank(rank)
			for i in csvIDs:
				cfg = csv.cross.arena.stage[i]
				if cfg.range[0] <= rank < cfg.range[1]:
					mailID = None
					award = None
					key = None
					if type == 1: # 7日
						mailID = CrossArena7DayAwardMailID
						award = cfg.periodAward
						key = 'seven_award_stage'
					else:
						mailID = CrossArenaFinishAwardMailID
						award = cfg.finishAward
						key = 'finish_award_stage'
					mail = ObjectRole.makeMailModel(roleID, mailID, contentArgs=(cfg.stageName, stageRank), attachs=award)
					MailJoinableQueue.send(mail)

					game = ObjectGame.getByRoleID(roleID, safe=False)
					if game:
						game.role.cross_arena_datas[key] = cfg.id
					else:
						self.period_award_stages.setdefault(roleID, {})[type] = cfg.id
					break
		if type == 2:
			# 跨服竞技场赛季称号
			from game.object.game.servrecord import ObjectServerGlobalRecord
			ObjectServerGlobalRecord.saveTitleRanks(TitleDefs.CrossArena, roleRanks)

	def refreshTopHistoryMsg(self):
		# 精彩战报刷新 跑马灯
		ObjectMessageGlobal.marqueeBroadcast(None, MessageDefs.MqCrossArenaTopHistoryRefresh)
		ObjectMessageGlobal.newsCrossArenaTopHistoryRefreshMsg()

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
			'round': self.round,
			'csvID': self.csv_id,
			'servers': servers,
			'lastRanks': self.last_ranks[:10],
		}

	@classmethod
	def markCrossArenaRoleInfo(cls, role, cardsD):
		'''
		构造跨服竞技场 角色信息
		'''
		display = role.cross_arena_datas.get("last_display", 0)
		if not display:
			dbID = max(cardsD, key=lambda x: cardsD[x]['fighting_point'])
			display = cardsD[dbID]['card_id']
			role.cross_arena_datas["last_display"] = display
		fightingPoint = 0
		for dbID, card in cardsD.iteritems():
			fightingPoint = fightingPoint + card['fighting_point']
		crossArenaRoleInfo = {
			'role_db_id': role.id,
			'display': display,
			'record_db_id': role.cross_arena_record_db_id,
			'game_key': role.areaKey,
			'fighting_point': fightingPoint,
		}
		crossArenaRoleInfo.update(role.competitor)
		return crossArenaRoleInfo

	@classmethod
	def resetCrossAreanDatas(cls, role):
		'''
		重置上赛季数据
		'''
		self = cls.getByAreaKey(role.areaKey)
		display = role.cross_arena_datas.get('last_display', 0)
		role.cross_arena_datas = {
			'stage_awards': {},
			'seven_award_stage': 0,
			'finish_award_stage': 0,
			'last_display': display,
		}

	@classmethod
	def onLogin(cls, role):
		'''
		赛季奖励段位（离线玩家）
		'''
		self = cls.getByAreaKey(role.areaKey)
		stages = self.period_award_stages.pop(role.id, None)
		if stages:
			if not role.cross_arena_datas.get("seven_award_stage", 0):
				role.cross_arena_datas["seven_award_stage"] = stages.get(1, 0)
			if not role.cross_arena_datas.get("finish_award_stage", 0):
				role.cross_arena_datas["finish_award_stage"] = stages.get(2, 0)

	@classmethod
	def getCrossArenaCards(cls, role):
		'''
		初始化布阵队伍
		'''
		cards = role.top_cards[:12]
		if len(cards) < 2:
			raise ClientError("Cross arena cards must be greater than 2")
		cardsMap = {}  # {1:[card.id], 2:[card.id]} （队伍一 / 队伍二）
		# 保证每支队伍至少有一只
		if len(cards) < 7:
			cardsMap[2] = transform2list(cards[:1])
			cardsMap[1] = transform2list(cards[1:6])
		else:
			cardsMap[1] = transform2list(cards[:6])
			cardsMap[2] = transform2list(cards[6:12])
		return cardsMap, cards

