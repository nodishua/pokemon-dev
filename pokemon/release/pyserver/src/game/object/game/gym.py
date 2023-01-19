#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2014 YouMi Information Technology Inc.
'''
from framework import str2num_t, todayinclock5date2int, int2date, nowtime_t, weekinclock5date2int, inclock5date, nowdatetime_t, DailyRefreshHour
from framework.csv import csv, ConstDefs, ErrDefs, MergeServ
from framework.helper import transform2list
from framework.log import logger
from framework.object import ObjectNoGCDBase, db_property, ObjectBase
from framework.helper import addDict
from framework.service.helper import service_key2domains, service_domains2key
from game import globaldata, ClientError
from game.object import FeatureDefs, SceneDefs, GymDefs, AttrDefs, TitleDefs
from game.globaldata import GymLeaderAwardMailID, CrossGymLeaderAwardMailID, CrossGymGeneralAwardMailID, GymPassAwardMailID
from game.object.game.levelcsv import ObjectFeatureUnlockCSV
from game.object.game.costcsv import ObjectCostCSV
from game.object.game.gain import ObjectCostAux, ObjectGainAux, ObjectGainEffect
from game.object.game.servrecord import ObjectServerGlobalRecord
from tornado.gen import coroutine, Return, sleep
import copy
import datetime


#
# ObjectGymGameGlobal
#
class ObjectGymGameGlobal(ObjectNoGCDBase):
	DBModel = 'GymGameGlobal'

	Singleton = None

	OpenLevel = 0
	OpenDateTime = None
	GymMap = {}  # gymID: [nextGymID]
	GymFirstMap = []  # [FirstGymID]

	GlobalObjsMap = {} # {areakey: ObjectGymGameGlobal}
	GlobalHalfPeriodObjsMap = {} # {areakey: ObjectGymGameGlobal}


	@classmethod
	def classInit(cls):
		cfg = csv.cross.gym.base[1]
		cls.OpenDateTime = datetime.datetime.combine(
			inclock5date(globaldata.GameServOpenDatetime) + datetime.timedelta(days=cfg.servOpenDays - 1),
			datetime.time(hour=DailyRefreshHour))

		cls.GymMap = {}
		cls.GymFirstMap = []

		cls.OpenLevel = ObjectFeatureUnlockCSV.getOpenLevel(FeatureDefs.Gym)
		for gymID in csv.gym.gym:
			cfg = csv.gym.gym[gymID]
			if cfg.preGymID:
				cls.GymMap.setdefault(cfg.preGymID, []).append(gymID)
			else:
				cls.GymFirstMap.append(gymID)

	def __init__(self, dbc):
		ObjectNoGCDBase.__init__(self, None, dbc)

	def set(self, dic):
		ObjectNoGCDBase.set(self, dic)
		self.isHalfPeriod = ObjectServerGlobalRecord.isHalfPeriod('cross_gym', self.key)
		return self

	def init(self, server, crossData):
		self.server = server
		self._cross = {}
		self.title_clear = False

		self.initCrossData(crossData)

		cls = ObjectGymGameGlobal
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

	# servkey
	key = db_property('key')

	# 跨服server key
	cross_key = db_property('cross_key')

	# 状态
	round = db_property('round')

	# 跨服csv_id
	csv_id = db_property('csv_id')

	# 副本关卡 {gymID: {degree: gateID}}
	gym_gates = db_property('gym_gates')

	# 道馆称号 {roleID: [{titleID: openTime}]}
	gym_titles = db_property('gym_titles')

	# 上期 馆主相关信息 {gymID: Object}
	last_leader_roles = db_property('last_leader_roles')

	# 上期 跨服馆员相关信息 {gymID: {pos: Object}} 默认第一位是跨服馆主
	last_cross_gym_roles = db_property('last_cross_gym_roles')

	# 当前时间的周一
	@property
	def date(self):
		return weekinclock5date2int()

	@property
	def servers(self):
		return self._cross.get('servers', [])

	@classmethod
	def isOpen(cls, areaKey):
		'''
		是否开启本服玩法
		'''
		self = cls.getByAreaKey(areaKey)
		if self.round == "closed":
			return False
		return True

	@classmethod
	def isCrossOpen(cls, areaKey):
		'''
		是否开启跨服玩法
		'''
		self = cls.getByAreaKey(areaKey)
		if cls.OpenDateTime > nowdatetime_t():
			return False
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
	def gymGate(cls, areaKey):
		'''
		道馆关卡信息
		'''
		self = cls.getByAreaKey(areaKey)
		return self.gym_gates

	@classmethod
	@coroutine
	def onGymEvent(cls, event, key, data, sync):
		'''
		玩法流程
		'''
		logger.info('ObjectGymGameGlobal.onGymEvent %s %s', key, event)

		self = cls.getByAreaKey(key)
		if sync:
			self.round = sync['round']

		ret = {}
		# 跨服道馆 crossGym
		if event == 'crossInit':
			self.last_cross_gym_roles = {}
			self.initCrossData(data.get('model', {}))
		elif event == 'crossClosed':
			lastCrossGymRoles = data['last_cross_gym_roles']
			self.onCrossClosed(lastCrossGymRoles)
		elif event == 'crossGymAward':
			crossLeaderRoleIDs = data['cross_leader_role_ids']
			crossGeneralRoleIDs = data['cross_general_role_ids']
			self.onCrossAward(crossLeaderRoleIDs, crossGeneralRoleIDs)

		# 本服道馆 gym
		elif event == 'prepare':
			self.last_leader_roles = {}
			self.last_cross_gym_roles = {}
			gymGates = data['gym_gates']
			self.onPrepare(gymGates)
		elif event == 'start':
			self.onStart()
		elif event == 'closed':
			lastLeaderRoles = data['last_leader_roles']
			self.onClosed(lastLeaderRoles)
		elif event == 'gymLeaderAward':
			leaderRoleIDs = data['leader_role_ids']
			self.onLeaderAward(leaderRoleIDs)
			# 半周期复制数据, 在这里 self 只会是 ObjectGymGameGlobal.Singleton
			for _, obj in cls.GlobalHalfPeriodObjsMap.iteritems():
				obj.round = self.round
				obj.gym_titles = copy.deepcopy(self.gym_titles)
				obj.last_leader_roles = copy.deepcopy(self.last_leader_roles)
		raise Return(ret)

	# 赛季准备 prepare
	def onPrepare(self, gymGates):
		logger.info('ObjectGymGameGlobal.onPrepare')
		self.gym_gates = gymGates

	# 赛季开始 prepare -> start
	def onStart(self):
		logger.info('ObjectGymGameGlobal.onStart')
		self.round = 'start'
		self.title_clear = False

	# 赛季结束 start -> closed
	def onClosed(self, lastLeaderRoles):
		logger.info('ObjectGymGameGlobal.onClosed')
		self.round = 'closed'
		if not self.title_clear:
			self.gym_titles = {}
			self.title_clear = True
		# 上期本服荣誉馆主
		self.last_leader_roles = lastLeaderRoles

	# 赛季结束 发荣誉馆主奖励和称号
	def onLeaderAward(self, leaderRoleIDs):
		from game.mailqueue import MailJoinableQueue
		from game.object.game.role import ObjectRole

		logger.info('ObjectGymGameGlobal.onLeaderAward')
		# {gymID: roleID}
		for gymID, roleID in leaderRoleIDs.iteritems():
			cfg = csv.gym.gym[gymID]
			award = cfg.leaderAward
			mailID = GymLeaderAwardMailID
			mail = ObjectRole.makeMailModel(roleID, mailID, contentArgs=cfg.name, attachs=award)
			MailJoinableQueue.send(mail)
			self.doGymTitle(TitleDefs.Gym, roleID)

	# 跨服 重置
	def crossReset(self):
		self.cross_key = ''
		return True

	# 跨服 初始化 init
	def initCrossData(self, crossData):
		logger.info('ObjectGymGameGlobal.initCrossData')
		# crossData = {servers; csv_id;}
		self._cross = crossData
		if crossData:
			self.csv_id = self._cross.get('csv_id', 0)
			if self.csv_id > 0 and self.csv_id in csv.cross.service:
				self.version = csv.cross.service[self.csv_id].version
			logger.info('CrossGym Init %s, csv_id %d', self.cross_key, self.csv_id)
		else:
			self.crossReset()

	# 跨服 结束
	def onCrossClosed(self, lastCrossGymRoles):
		logger.info('ObjectGymGameGlobal.onCrossClosed')
		self.cross_key = ''
		if not self.title_clear:
			self.gym_titles = {}
			self.title_clear = True
		# 上期跨服荣誉馆主/馆员
		self.last_cross_gym_roles = lastCrossGymRoles

	# 跨服 发奖励和称号
	def onCrossAward(self, crossLeaderRoleIDs, crossGeneralRoleIDs):
		from game.mailqueue import MailJoinableQueue
		from game.object.game.role import ObjectRole

		logger.info('ObjectGymGameGlobal.onCrossAward')
		# crossLeaderRoleIDs = {gymID: roleID}
		for gymID, roleID in crossLeaderRoleIDs.iteritems():
			cfg = csv.gym.gym[gymID]
			award = cfg.crossLeaderAward
			mailID = CrossGymLeaderAwardMailID
			mail = ObjectRole.makeMailModel(roleID, mailID, contentArgs=cfg.name, attachs=award)
			MailJoinableQueue.send(mail)
			self.doGymTitle(TitleDefs.CrossGym, roleID)

		# crossGeneralRoleIDs = {gymID: [roleID ...]}
		for gymID, roleIDs in crossGeneralRoleIDs.iteritems():
			for roleID in roleIDs:
				cfg = csv.gym.gym[gymID]
				award = cfg.crossSubAward
				mailID = CrossGymGeneralAwardMailID
				mail = ObjectRole.makeMailModel(roleID, mailID, contentArgs=cfg.name, attachs=award)
				MailJoinableQueue.send(mail)

	def doGymTitle(self, type, roleID):
		'''
		在线称号发放
		'''
		from game.object.game import ObjectGame
		from game.object.game.role import ObjectRole

		game = ObjectGame.getByRoleID(roleID, safe=False)
		titleID = ObjectRole.TitleRankMap[type][1]
		openTime = nowtime_t()
		if game:
			game.role.onRankTitle(titleID, openTime)
		else:
			titles = self.gym_titles.setdefault(roleID, [])
			titles.append({titleID: openTime})

	@classmethod
	def onLogin(cls, role):
		'''
		称号发放（离线玩家）
		'''
		self = cls.getByAreaKey(role.areaKey)
		titles = self.gym_titles.pop(role.id, None)
		if titles:
			for titleMap in titles:
				for titleID, openTime in titleMap.iteritems():
					role.onRankTitle(titleID, openTime)

	@classmethod
	def getGymGameModel(cls, areaKey):
		'''
		缩略model
		'''
		self = cls.getByAreaKey(areaKey)
		return {
			'crossKey': self.cross_key,
			'csvID': self.csv_id,
			'servers': self.servers,
			'date': self.date,
			'round': self.round,
			'gymGates': self.gym_gates,
			'lastLeaderRoles': self.last_leader_roles,
			'lastCrossGymRoles': self.last_cross_gym_roles,
		}

	@classmethod
	def cleanHalfPeriod(cls):
		for _, obj in cls.GlobalObjsMap.iteritems():
			if obj.isHalfPeriod: # 清除半周期状态
				ObjectServerGlobalRecord.overHalfPeroid('cross_gym', obj.key)
				obj.isHalfPeriod = ObjectServerGlobalRecord.isHalfPeriod('cross_gym', obj.key)
				obj.last_leader_roles = {}
				obj.last_cross_gym_roles = {}

		cls.GlobalHalfPeriodObjsMap = {}

	@classmethod
	@coroutine
	def onCrossCommit(cls, key, transaction):
		'''
		跨服启动commit
		'''
		logger.info('ObjectGymGameGlobal.onCrossCommit %s %s', key, transaction)

		# cross竞争资源成功
		self = cls.Singleton
		# 玩法已经被占用
		if self.cross_key != '' and self.cross_key != key:
			logger.warning('ObjectGymGameGlobal.onCrossCommit %s', self.cross_key)
			raise Return(False)

		cls.cleanHalfPeriod()
		# 直接重置
		self.crossReset()
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

	@classmethod
	def game2gym(cls, key):
		domains = service_key2domains(key)
		domains[0] = 'gym'
		return service_domains2key(domains)

	@classmethod
	def markGymRoleInfo(cls, role, cardsD):
		'''
		构造道馆 角色信息
		'''
		fightingPoint = 0
		for dbID, card in cardsD.iteritems():
			fightingPoint = fightingPoint + card['fighting_point']
		gymRoleInfo = {
			'role_id': role.id,
			'record_id': role.gym_record_db_id,
			'game_key': role.areaKey,
			'fighting_point': fightingPoint,
		}
		gymRoleInfo.update(role.competitor)
		return gymRoleInfo

	@classmethod
	def gymLeaderBattleCards(cls, game, cards):
		deployment = game.cards.deploymentForGym
		if not cards and not deployment.isExist('cards'):
			return {}
		dirty = None
		battle = {}
		if cards:
			battle['cards'] = cards
		else:
			cards, dirty = game.cards.deploymentForGym.refresh('cards', SceneDefs.GymPvp, cards)
		battle['card_attrs'], battle['card_attrs2'] = game.cards.makeBattleCardModel(cards, SceneDefs.GymPvp, dirty=dirty)
		battle['passive_skills'] = game.cards.markBattlePassiveSkills(cards, SceneDefs.GymPvp)
		return battle

	@classmethod
	def gymCrossBattleCards(cls, game, crossCards):
		deployment = game.cards.deploymentForGym
		if not crossCards and not deployment.isExist('cross_cards'):
			return {}
		dirty = None
		battle = {}
		if crossCards:
			battle['cross_cards'] = crossCards
		else:
			crossCards, dirty = game.cards.deploymentForGym.refresh('cross_cards', SceneDefs.GymPvp, crossCards)
		battle['cross_card_attrs'], battle['cross_card_attrs2'] = game.cards.makeBattleCardModel(crossCards, SceneDefs.GymPvp, dirty=dirty)
		battle['cross_passive_skills'] = game.cards.markBattlePassiveSkills(crossCards, SceneDefs.GymPvp)
		return battle

	@classmethod
	def battleInputOK(cls, game, cards, gymID):
		if gymID not in csv.gym.gym:
			raise ClientError('gymID not found')
		if cards:
			cards = transform2list(cards)
			if game.cards.isDuplicateMarkID(cards):
				raise ClientError('cards have duplicates')
			if len(filter(None, cards)) == 0:
				raise ClientError('cards all None')
		else:
			raise ClientError('cards is empty')
		return cards

	@classmethod
	def battleCanBegin(cls, game, cards, gymID, delta):
		# 是否全部通关
		if not game.role.isGymPassed(gymID):
			raise ClientError('not pass all gym gates')

		# 冷却时间
		if delta < ConstDefs.gymPwCD:
			raise ClientError(ErrDefs.rankTimerNoCD)

		# 上阵卡牌属性判断
		limitAttribute = csv.gym.gym[gymID].limitAttribute
		for id in cards:
			card = game.cards.getCard(id)
			if card:
				if not (card.natureType in limitAttribute or card.natureType2 in limitAttribute):
					raise ClientError(ErrDefs.gymNatureTypeErr)

	@classmethod
	def resetGymDatas(cls, game):
		'''
		重置上赛季数据
		'''
		self = cls.getByAreaKey(game.role.areaKey)
		role = game.role
		lastDate = role.gym_datas.get('last_date', 0)
		if lastDate != self.date:
			oldFuben = role.gym_datas.get('gym_fuben', None)
			ObjectGymGameGlobal.doPassAwardsToMail(role)
			fuben = {}
			for firstGymID in ObjectGymGameGlobal.GymFirstMap:
				fuben[firstGymID] = csv.gym.gym[firstGymID].hardDegreeID[0]
			gymGates = cls.gymGate(role.areaKey)
			recoverDate = copy.deepcopy(role.gym_datas.get('recover_date', 0))
			currentFuben = copy.deepcopy(role.gym_datas.get('gym_fuben', {}))
			currentFuben = currentFuben if currentFuben else {}
			historyJump = copy.deepcopy(role.gym_datas.get('history_jump', {}))
			historyJump = historyJump if historyJump else {}
			lastJump = copy.deepcopy(role.gym_datas.get('last_jump', {}))
			lastJump = lastJump if lastJump else {}
			for gymID in currentFuben:
				if (currentFuben.get(gymID, 0) % 10) - 1 <= 0:
					continue
				lastJump[gymID] = csv.gym.gate[gymGates[gymID][currentFuben.get(gymID, 0) - 1]].lastJump
				historyJump[gymID] = historyJump.get(gymID, 0) if historyJump.get(gymID, 0) > csv.gym.gate[gymGates[gymID][currentFuben.get(gymID, 0) - 1]].historyJump else csv.gym.gate[gymGates[gymID][currentFuben.get(gymID, 0) - 1]].historyJump
			role.gym_datas = {
				'gym_fuben': fuben,
				'gym_pass_awards': {},
				'gym_talent_trees': {},
				'gym_talent_point': 0,
				'gym_pw_last_time': 0.0,
				'cross_gym_pw_last_time': 0.0,
				'last_date': self.date,
				'recover_date': recoverDate,
				'gym_talent_reset_times': 0,
				'last_jump': lastJump,
				'history_jump': historyJump,
			}
			game.gymTalentTree.reset()
			if oldFuben:
				from game.thinkingdata import ta
				ta.track(game, event='gym_reset', last_date=lastDate, fuben=oldFuben)
			return True
		return False

	@classmethod
	def refreshGymTalentPoint(cls, game, role):
		'''
		刷新道馆挑战天赋点数
		'''
		self = cls.getByAreaKey(role.areaKey)
		now = todayinclock5date2int()
		lastRecoverDate = role.gym_datas.get('recover_date', 0)
		if now == lastRecoverDate or not self.date:
			return None

		# 没有上次恢复时间或者在最近一次道馆重置时间之前
		if not lastRecoverDate or lastRecoverDate < self.date:
			num = ConstDefs.gymRecoverFirst + ConstDefs.gymAutoRecoverPoints * (int2date(now) - int2date(self.date)).days
		else:
			num = ConstDefs.gymAutoRecoverPoints * (int2date(now) - int2date(lastRecoverDate)).days

		role.gym_datas['recover_date'] = now

		eff = ObjectGainAux(game, {'gym_talent_point': num})
		return eff

	@classmethod
	def doPassAwardsToMail(cls, role):
		'''
		通关奖励没领的发邮件里
		'''
		from game.mailqueue import MailJoinableQueue
		from game.object.game.role import ObjectRole
		passAwards = role.gym_datas.get("gym_pass_awards", {})
		award = {}
		for gymID, flag in passAwards.iteritems():
			cfg = csv.gym.gym[gymID]
			if flag == GymDefs.PassAwardOpenFlag:
				award = addDict(award, cfg.gateAward)
				passAwards[gymID] = GymDefs.PassAwardCloseFlag
		role.gym_datas["gym_pass_awards"] = passAwards
		if award:
			mailID = GymPassAwardMailID
			mail = ObjectRole.makeMailModel(role.id, mailID, attachs=award)
			MailJoinableQueue.send(mail)

	@classmethod
	def getGymPassedAward(cls, game, gymID=None):
		'''
		领取道馆副本通关奖励
		'''
		csvIDs = []
		awards = {}
		if gymID:
			flag = game.role.gym_pass_awards.get(gymID, None)
			if flag is None:
				raise ClientError('gym gates not all passed')
			elif flag == GymDefs.PassAwardCloseFlag:
				raise ClientError('gym gate award already get')
			awards = csv.gym.gym[gymID].gateAward
			csvIDs.append(gymID)
		else:
			for gymID, flag in game.role.gym_pass_awards.iteritems():
				if flag == GymDefs.PassAwardOpenFlag:
					awards = addDict(awards, csv.gym.gym[gymID].gateAward)
					csvIDs.append(gymID)

		if not csvIDs:
			raise ClientError('no gym gate award can get')

		def _afterGain():
			for csvID in csvIDs:
				game.role.gym_pass_awards[csvID] = GymDefs.PassAwardCloseFlag

		return ObjectGainEffect(game, awards, _afterGain)


#
# ObjectGymTalentTree
#
class ObjectGymTalentTree(ObjectBase):
	TalentTreeMap = {}  # talentID:[nextTalentID]
	TalentTreeDepthMap = {}  # {(treeID, depth): [talentID]}
	TalentTreeStartNode = {}  # treeID:[talentID]
	TalentCostSumMap = {}  # (seqID,level): costDict
	TalentActiveCon = []

	@classmethod
	def classInit(cls):
		cls.TalentTreeMap = {}
		cls.TalentTreeStartNode = {}
		cls.TalentCostSumMap = {}
		cls.TalentActiveCon = []
		cls.TalentTreeDepthMap = {}

		for i in csv.gym.talent_tree:
			cfg = csv.gym.talent_tree[i]
			cls.TalentActiveCon.append((i, cfg.preTreeID, cfg.prePointNum))

		for i in csv.gym.talent_buff:
			cfg = csv.gym.talent_buff[i]
			if cfg.preTalentIDs:
				for preTalentID in cfg.preTalentIDs:
					cls.TalentTreeMap.setdefault(preTalentID, []).append(i)
			else:
				cls.TalentTreeStartNode.setdefault(cfg.treeID, []).append(i)

			cls.TalentTreeDepthMap.setdefault((cfg.treeID, cfg.depth), []).append(i)

		for i in sorted(csv.gym.talent_cost):  # level
			for j in xrange(1, 99):  # seq id
				if 'cost%d' % j not in csv.gym.talent_cost[i]:
					break
				if i == 0:
					cls.TalentCostSumMap[(j, i)] = {}
				else:
					cfg = csv.gym.talent_cost[i - 1]
					preSum = cls.TalentCostSumMap[(j, i - 1)]
					cls.TalentCostSumMap[(j, i)] = addDict(preSum, cfg['cost%d' % j])

	def set(self):
		self.reset()
		return ObjectBase.set(self)

	def reset(self):
		self._talentTree = self.game.role.gym_talent_trees
		self._passive_skills = None
		self._passive_skills_global = None

	def init(self):
		return ObjectBase.init(self)

	def talentLevelUp(self, talentID):
		'''
		道馆天赋升级
		'''
		cfg = csv.gym.talent_buff[talentID]
		tree = self._talentTree.get(cfg.treeID, None)

		if tree is not None:
			talent = tree.get("talent", {})
			# 前置节点是否满足
			active = filter(lambda x: talent.get(x, 0) >= cfg.preLevel, cfg.preTalentIDs)
			if cfg.preTalentIDs and (not active):
				raise ClientError('the preTalentID level not enough')
			# 同层是否有其他已经激活
			depthNodes = ObjectGymTalentTree.TalentTreeDepthMap.get((cfg.treeID, cfg.depth), [])
			for node in depthNodes:
				if node in talent and node != talentID:
					raise ClientError('the depth have other active')
		else:
			# 前置树是否满足
			cfgTree = csv.gym.talent_tree[cfg.treeID]
			preTreeID = cfgTree.preTreeID
			if preTreeID:
				if not filter(lambda x: self._talentTree.get(x, {}).get('cost', 0) >= cfgTree.prePointNum, preTreeID):
					raise ClientError('preTree pointNum not enough')
			tree = self._talentTree.setdefault(cfg.treeID, {'cost': 0, 'talent': {}})

		oldLevel = tree['talent'].get(talentID, 0)
		if oldLevel >= cfg.levelUp:
			raise ClientError(ErrDefs.talentLevelUp)

		costCfg = csv.gym.talent_cost[oldLevel]['cost%d' % cfg.costID]
		cost = ObjectCostAux(self.game, costCfg)
		if not cost.isEnough():
			raise ClientError('gym talent levelUp cost not enough')
		cost.cost(src='gym_talent_levelUp')

		tree['cost'] = tree.get('cost', 0) + costCfg.get('gym_talent_point', 0)
		tree['talent'][talentID] = oldLevel + 1
		self.reset()

	def talentResetAll(self):
		'''
		道馆天赋重置
		'''
		if sum([tree.get('cost', 0) for tree in self._talentTree.values()]) == 0:
			raise ClientError(ErrDefs.talentResetNoIDs)

		resetTimes = self.game.role.gym_talent_reset_times
		costRMB = ObjectCostCSV.getGymTalentResetCost(resetTimes)
		cost = ObjectCostAux(self.game, {'rmb': costRMB})
		if not cost.isEnough():
			raise ClientError(ErrDefs.talentResetRmbUp)
		cost.cost(src='gym_talent_reset')

		eff = ObjectGainAux(self.game, {})
		for treeID, _, _ in ObjectGymTalentTree.TalentActiveCon:
			tree = self._talentTree.get(treeID, None)
			if tree is None:
				continue
			for talentID, level in tree.get('talent', {}).iteritems():
				cfg = csv.gym.talent_buff[talentID]
				if level > 0:
					costDict = ObjectGymTalentTree.TalentCostSumMap[(cfg.costID, level)]
					eff += ObjectGainAux(self.game, costDict)

		self.game.role.gym_datas['gym_talent_trees'] = {}
		self.reset()
		self.game.role.gym_datas['gym_talent_reset_times'] = resetTimes + 1

		return eff

	def getGymTalenetCardsAttr(self, cardIDs):
		'''
		获取道馆挑战加成后的卡牌属性
		'''
		attrsD = {}  # {attr: (const, percent)}
		for _, tree in self._talentTree.iteritems():
			for talentID, level in tree.get('talent', {}).iteritems():
				if level > 0:
					cfg = csv.gym.talent_buff[talentID]
					# 效果类型为属性加成的
					if cfg.effectType == GymDefs.AttrType:
						for i in xrange(1, 99):
							attrKey = 'attrType%d' % i
							if attrKey not in cfg or not cfg[attrKey]:
								break
							attrNumKey = 'attrNum%d' % i

							num = str2num_t(cfg[attrNumKey][level-1])
							const, percent = attrsD.get(AttrDefs.attrsEnum[cfg[attrKey]], (0.0, 0.0))
							const += num[0]
							percent += num[1]
							attrsD[AttrDefs.attrsEnum[cfg[attrKey]]] = (const, percent)

		cardsAttr, cardsAttr2 = self.game.cards.makeBattleCardModel(cardIDs, SceneDefs.Gym)
		for cardID, cardAttr in cardsAttr.iteritems():
			card = self.game.cards.getCard(cardID)
			attrs = cardAttr.setdefault('attrs', {})
			for attr, value in attrsD.iteritems():
				const, percent = value
				attrValue = attrs.get(attr, 0.0)
				if const:
					attrValue += const
				if percent:
					attrValue = attrValue * (1 + percent)
				attrs[attr] = attrValue
			cardAttr['fighting_point'] = card.calcFightingPoint(card, attrs)
		for cardID, cardAttr in cardsAttr2.iteritems():
			card = self.game.cards.getCard(cardID)
			attrs = cardAttr.setdefault('attrs', {})
			for attr, value in attrsD.iteritems():
				const, percent = value
				attrValue = attrs.get(attr, 0.0)
				if const:
					attrValue += const
				if percent:
					attrValue = attrValue * (1 + percent)
				attrs[attr] = attrValue
			cardAttr['fighting_point'] = card.calcFightingPoint(card, attrs)
		return cardsAttr, cardsAttr2

	def getPassiveSkills(self, isGlobal=False):
		if isGlobal and self._passive_skills_global is not None:
			return self._passive_skills_global

		if not isGlobal and self._passive_skills is not None:
			return self._passive_skills

		skills = {}
		for _, tree in self._talentTree.iteritems():
			for talentID, level in tree.get('talent', {}).iteritems():
				if level > 0:
					cfg = csv.gym.talent_buff[talentID]
					if cfg.effectType == GymDefs.SkillType:
						if isGlobal:
							if csv.skill[cfg.skillID].isGlobal:
								skills[cfg.skillID] = level
						else:
							if not csv.skill[cfg.skillID].isGlobal:
								skills[cfg.skillID] = level
		if isGlobal:
			self._passive_skills_global = skills
		else:
			self._passive_skills = skills
		return skills
