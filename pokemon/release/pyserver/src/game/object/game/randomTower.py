#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2014 YouMi Information Technology Inc.
'''
import copy
import random
from collections import defaultdict

import framework
from framework import todayinclock5date2int, int2date, OneDay, date2int, str2num_t
from framework.csv import csv, ConstDefs, MergeServ
from framework.helper import WeightRandomObject
from framework.distributed.helper import node_key2domains
from framework.log import logger
from framework.object import ObjectDBase, db_property
from game import ClientError
from game.session import Session
from game.globaldata import RandomTowerHuodongID, RandomTowerPointAwardMailID
from game.mailqueue import MailJoinableQueue
from game.object import RandomTowerDefs, AttrDefs, TargetDefs, YYHuoDongDefs, SceneDefs, MessageDefs, PlayPassportDefs
from game.object.game.costcsv import ObjectCostCSV
from game.object.game.card import CardSlim, ObjectCard
from game.object.game.gain import ObjectGainAux, ObjectCostAux
from game.object.game.message import ObjectMessageGlobal
from game.object.game.yyhuodong import ObjectYYHuoDongFactory
from game.object.game.role import ObjectRole


#
# ObjectRandomTower
#
class ObjectRandomTower(ObjectDBase):
	DBModel = 'RandomTower'

	RandomTowerBoardMap = {}  # {roomID: [csvIDs]}
	RandomTowerMonstersMap = {}  # {group: [cfg]}
	RandomTowerEventMap = {}  # {group: [cfg]}
	RandomTowerBuffMap = {}  # {group: [cfg]}
	MaxRoom = 0
	PointAwardVersion = 0 # 积分奖励版本
	PointAwardMap = {} # {version: [cfg.id]}

	@classmethod
	def classInit(cls):
		cls.MaxRoom = max(csv.random_tower.tower.keys())

		cls.RandomTowerBoardMap = {}
		for idx in csv.random_tower.board:
			cfg = csv.random_tower.board[idx]
			csvIDs = cls.RandomTowerBoardMap.get(cfg.room, [])
			csvIDs.append(idx)
			cls.RandomTowerBoardMap[cfg.room] = csvIDs

		cls.RandomTowerMonstersMap = {}
		for i in csv.random_tower.monsters:
			cfg = csv.random_tower.monsters[i]
			csvIDs = cls.RandomTowerMonstersMap.get(cfg.group, [])
			csvIDs.append(i)
			cls.RandomTowerMonstersMap[cfg.group] = csvIDs

		cls.RandomTowerEventMap = {}
		for i in csv.random_tower.event:
			cfg = csv.random_tower.event[i]
			csvIDs = cls.RandomTowerEventMap.get(cfg.group, [])
			csvIDs.append(i)
			cls.RandomTowerEventMap[cfg.group] = csvIDs

		cls.RandomTowerBuffMap = {}
		for i in csv.random_tower.buffs:
			cfg = csv.random_tower.buffs[i]
			csvIDs = cls.RandomTowerBuffMap.get(cfg.group, [])
			csvIDs.append(i)
			cls.RandomTowerBuffMap[cfg.group] = csvIDs

		cls.PointAwardVersion = 0
		key = MergeServ.getSrcServKeys(Session.server.key)[0]
		domains = node_key2domains(key)
		serverKey, serverIdx = domains[1], int(domains[2])
		for i in csv.random_tower.point_award_version:
			cfg = csv.random_tower.point_award_version[i]
			if framework.__language__ in cfg.languages:
				if serverKey in cfg.servers:
					serversRange = cfg.servers[serverKey]
					if int(serversRange[0]) <= serverIdx <= int(serversRange[1]) and cfg.version >= cls.PointAwardVersion:
						cls.PointAwardVersion = cfg.version

		cls.PointAwardMap = {}
		for i in csv.random_tower.point_award:
			cfg = csv.random_tower.point_award[i]
			csvIDs = cls.PointAwardMap.get(cfg.version, [])
			csvIDs.append(i)
			cls.PointAwardMap[cfg.version] = csvIDs

	def set(self, dic):
		ObjectDBase.set(self, dic)
		if not self.point_award:
			self.point_award = {}
			self.point_award_version = self.PointAwardVersion
		return self

	def init(self):
		return ObjectDBase.init(self)

	# 上一次试炼日期
	last_date = db_property('last_date')

	# 昨日房间ID
	last_room = db_property('last_room')

	# 历史最高房间ID
	history_room = db_property('history_room')

	# 当前房间ID
	def room():
		dbkey = 'room'
		def fset(self, value):
			old = self.db[dbkey]
			self.db[dbkey] = value
			if value > old:
				ObjectYYHuoDongFactory.onGeneralTask(self.game, TargetDefs.RandomTowerTimes, value - old)
		return locals()
	room = db_property(**room())

	# 卡面 {roomID: [boardID, ...]}
	boards = db_property('boards')

	# 房间信息 {count: 宝箱打开次数, pass: 是否通过（1表示通过）, board_id: 已选中的卡面, enemy: 怪物,
	# event: 事件选项, buff: buff选项, next_room_scope: 下一房间选择范围}
	room_info = db_property('room_info')

	# 卡牌血量怒气 {cardID: (hp, mp)}
	card_states = db_property('card_states')

	# 怪物血量怒气 {cardID: (hp, mp)}
	enemy_states = db_property('enemy_states')

	# 已获得的buff [buffID ...]
	buffs = db_property('buffs')

	# 历史总积分
	history_point = db_property('history_point')

	# 当日积分
	def day_point():
		dbkey = 'day_point'
		def fset(self, value):
			old = self.db[dbkey]
			self.db[dbkey] = value
			if value > old:
				self.calPointAward()
				ObjectYYHuoDongFactory.onGeneralTask(self.game, TargetDefs.RandomTowerPointDaily, 0)
				ObjectYYHuoDongFactory.onGeneralTask(self.game, TargetDefs.RandomTowerPoint, value - old)
		return locals()
	day_point = db_property(**day_point())

	# 当日排名
	day_rank = db_property('day_rank')

	# 随机库
	buff_lib = db_property('buff_lib')

	# buff 出现次数 {buffID: count}
	buff_time = db_property('buff_time')

	# event 出现次数 {eventID: count}
	event_time = db_property('event_time')

	# 被动技能使用次数 {buffID: count}
	skill_used = db_property('skill_used')

	# 累计积分奖励版本
	point_award_version = db_property('point_award_version')

	# 累计积分奖励
	point_award = db_property('point_award')

	# 跳过房间信息 {boxes: {boardID: count}, buffs: [roomID], events: {boardID: flag}, buff_index: buff房间索引}
	jump_info = db_property('jump_info')

	# 跳过步骤 1:直通高层 2:宝箱 3:加成 4:事件
	jump_step = db_property('jump_step')

	# 试炼塔 每日刷新
	def refresh(self):
		# 每日结算清理（积分奖励不清理）
		today = todayinclock5date2int()
		yesterday = date2int(int2date(today) - OneDay)
		if self.last_date != today:
			logger.info('randomTower Refresh %d , %d, roleUid %s, role: %s', self.last_date, today, self.game.role.uid, self.game.role.name)
			passRoom = self.room - 1
			if self.room_info.get('pass', 0):
				passRoom += 1
			self.history_point += self.day_point
			self.day_point = 0
			self.day_rank = 0
			self.history_room = max(passRoom, self.history_room)
			# 如果昨天没有打 为 0
			self.last_room = 0 if self.last_date != yesterday else passRoom
			self.last_date = today
			self.room = 1
			self.room_info = {'next_room_scope': (-1, 99999)}
			self.boards = {}
			self.card_states = {}
			self.enemy_states = {}
			self.buffs = []
			self.buff_lib = []
			self.buff_time = {}
			self.event_time = {}
			self.skill_used = {}

			self.jump_step = RandomTowerDefs.JumpBegin
			self.jump_info = {}

			# 初始化前三房间
			for i in xrange(self.room, self.room + 3, 1):
				if i <= ObjectRandomTower.MaxRoom:
					self.setRoomBoards(i)

			return True
		return False

	def setRoomBoards(self, roomID):
		'''
		设置房间的所有卡面
		'''
		cfg = csv.random_tower.tower[roomID]
		boards = []
		if cfg.boards:
			groupList = [cfg.limit1, cfg.limit2, cfg.limit3]
			csvBoard = csv.random_tower.board

			# 随卡面的个数
			randobj = WeightRandomObject(cfg.boards)
			boardNum, _ = randobj.getRandom()
			# {roomID: [csvIDs]}
			boardCsvIDs = copy.copy(self.RandomTowerBoardMap.get(roomID, []))
			# 先处理必选的情况（权值为 -1）
			for csvID in self.RandomTowerBoardMap.get(roomID, []):
				if boardNum < 1:
					break
				if csvBoard[csvID]['weight'] == -1:
					boardCsvIDs.remove(csvID)  # -1的删掉
					group = csvBoard[csvID]['group']
					if groupList[group-1] >= 1:
						boards.append(csvID)
						boardNum -= 1
						groupList[group-1] -= 1
			if boardNum:
				# 根据权值随机
				weights = {}
				for boardCsvID in boardCsvIDs:
					if csvBoard[boardCsvID]['weight'] != -1 and groupList[csvBoard[boardCsvID]['group']-1] >= 1:
						weights[boardCsvID] = csvBoard[boardCsvID]['weight']
				for i in xrange(boardNum):
					# 如果配置不正确，weights可能会被清完。导致卡面数量会变少
					if weights:
						randobj = WeightRandomObject(weights)
						boardCsvID, _ = randobj.getRandom()
						boards.append(boardCsvID)
						weights.pop(boardCsvID)  # 随一个就删掉（防止重复）
						group = csvBoard[boardCsvID]['group']
						groupList[group - 1] -= 1
						if groupList[group - 1] <= 0:
							# 说明该组已达上限了 是该组的全清理
							weightsCopy = copy.copy(weights)
							for csvID in weightsCopy:
								if csvBoard[csvID]['group'] == group:
									weights.pop(csvID)
		self.boards.setdefault(roomID, boards)

	def isRightChoose(self, boardID):
		'''
		选择卡面是否正确
		'''
		curRoomBoards = self.boards.get(self.room, [])
		if boardID not in curRoomBoards:
			return False
		idx = curRoomBoards.index(boardID) + 1
		low, high = self.room_info.get('next_room_scope', (-1, 99999))
		if low <= idx <= high:
			return True
		return False

	def setNextRoomScope(self):
		'''
		设置房间可选择卡面范围
		'''
		curRoomBoards = self.boards.get(self.room, [])
		nextRoomBoards = self.boards.get(self.room + 1, [])
		# 当前或下房为 开门 或者 卡面只有1个的时候
		if len(curRoomBoards) <= 1 or len(nextRoomBoards) <= 1:
			self.room_info['next_room_scope'] = (-1, 99999)
		else:
			boardID = self.room_info.get('board_id', 0)
			st = (len(nextRoomBoards) - len(curRoomBoards))/float(2)
			self.room_info['next_room_scope'] = (curRoomBoards.index(boardID)+st, curRoomBoards.index(boardID)+st+2)

	def nextRoom(self):
		'''
		进入下个房间（足够的情况下，一直保证3个房间）
		'''
		# 已经通关到最大层
		passfloor = csv.random_tower.tower[self.room].floor
		if self.room == ObjectRandomTower.MaxRoom:
			self.room_info.setdefault('pass', 1)
			ObjectYYHuoDongFactory.onGeneralTask(self.game, TargetDefs.RandomTowerFloorTimes, 1)
			ObjectYYHuoDongFactory.onGeneralTask(self.game, TargetDefs.RandomTowerFloorMax, passfloor)
			ObjectYYHuoDongFactory.onGeneralTask(self.game, TargetDefs.RandomTowerFloorSum, passfloor)
			ObjectMessageGlobal.marqueeBroadcast(self.game.role, MessageDefs.MqRandomTowerPass)
			ObjectMessageGlobal.newsRandomTowerPassMsg(self.game.role)
			ObjectYYHuoDongFactory.onTaskChange(self.game, PlayPassportDefs.RandomTower, 1)
		else:
			# 删除当前房间
			self.boards.pop(self.room)
			# 把上房间的数据清空
			self.enemy_states = {}
			self.room_info = {'next_room_scope': list(self.room_info.get('next_room_scope', (-1, 99999)))}
			self.room += 1
			# 下个房间塞怪物和事件
			self.setEnermyToRoom()
			self.setEventToRoom()
			self.setBuffToRoom()
			if self.room + 2 <= ObjectRandomTower.MaxRoom:
				# 添加下一间
				self.setRoomBoards(self.room + 2)
			floor = csv.random_tower.tower[self.room].floor
			if passfloor != floor:
				ObjectYYHuoDongFactory.onGeneralTask(self.game, TargetDefs.RandomTowerFloorTimes, 1)
				ObjectYYHuoDongFactory.onGeneralTask(self.game, TargetDefs.RandomTowerFloorMax, passfloor)
				ObjectYYHuoDongFactory.onGeneralTask(self.game, TargetDefs.RandomTowerFloorSum, passfloor)
				ObjectYYHuoDongFactory.onTaskChange(self.game, PlayPassportDefs.RandomTower, 1)

	def getBoxAwards(self, boardID):
		'''
		领取宝箱奖励
		'''
		cfg = csv.random_tower.board[boardID]
		eff = ObjectGainAux(self.game, {})
		# 首次
		count = self.room_info.get('count', 0)
		if count == 0:
			eff += self.getFirstBoxAwards(boardID)
		else:
			# 普通
			if cfg.boxType == RandomTowerDefs.CommonType:
				costRMB = ObjectCostCSV.getRandomTowerBoxCost1(count)
			# 豪华
			else:
				costRMB = ObjectCostCSV.getRandomTowerBoxCost2(count)
			cost = ObjectCostAux(self.game, {'rmb': costRMB})
			if not cost.isEnough():
				raise ClientError('cost rmb no enough')
			cost.cost(src='random_tower_box_award')
			eff += ObjectGainAux(self.game, cfg['randomLibs2'])

		self.room_info['count'] = count + 1
		return eff

	def getFirstBoxAwards(self, boardID):
		'''
		打开首次宝箱
		'''
		cfg = csv.random_tower.board[boardID]
		eff = ObjectGainAux(self.game, {})
		# 运营活动 金币双倍
		yyTimes = 1
		yyID = ObjectYYHuoDongFactory.getDoubleDropOpenID(YYHuoDongDefs.DoubleRandomTowerGold)
		if yyID:
			yyTimes = 2
		eff += ObjectGainAux(self.game, {'gold': cfg.gold * yyTimes, 'coin2': cfg.coin})
		eff += ObjectGainAux(self.game, cfg['randomLibs'])
		return eff

	def randomEnemyCards(self, boardID):
		'''
		随机怪物卡牌
		'''
		cfgBoard = csv.random_tower.board[boardID]
		csvLevel = csv.random_tower.monster_level
		csvMonsters = csv.random_tower.monsters
		cfgTower = csv.random_tower.tower[cfgBoard.room]
		historyFight = self.game.role.top6_fighting_point
		index = cfgBoard.monsterType-1
		# 先比较 再乘以系数
		baseFight = int(max(cfgTower['lowestFight'][index], historyFight) * cfgTower['fightC'][index] * cfgBoard.fightC)
		# 确定等级
		cfgLevel = None
		for i in csvLevel:
			cfg = csvLevel[i]
			if cfg['fightStart'] <= baseFight <= cfg['fightEnd']:
				cfgLevel = cfg
		# 随机怪物序列
		weights = {}
		monstersCsvIDs = self.RandomTowerMonstersMap.get(cfgBoard['monster'], [])
		for i in monstersCsvIDs:
			cfg = csvMonsters[i]
			if cfg['levelStart'] <= cfgLevel['level'] <= cfg['levelEnd']:
				weights.setdefault(i, cfg['weight'])
		randobj = WeightRandomObject(weights)
		monstersCsvID, _ = randobj.getRandom()
		# 返回怪物卡牌
		ret = {'fighting_point': baseFight, 'id': monstersCsvID}
		ret['monsters'] = []
		for index, card_id in enumerate(csvMonsters[monstersCsvID]['monsters']):
			if card_id == 0:
				ret['monsters'].append(None)
			else:
				skills = defaultdict(dict)
				for skillID in csv.cards[card_id].skillList:
					skills[skillID] = cfgLevel['skillLevel']
				ret['monsters'].append({
					'id': index+1,
					'unit_id': csv.cards[card_id].unitID,
					'card_id': card_id,
					'level': cfgLevel['level'],
					'advance': random.randint(cfgLevel['advanceStart'], cfgLevel['advanceEnd']),
					'star': random.randint(cfgLevel['starStart'], cfgLevel['starEnd']),
					'skills': skills,
					'skin_id': 0
				})
		# 计算怪物属性
		self.updateEnemyAttrs(ret)
		return ret

	def updateEnemyAttrs(self, enemy):
		'''
		更新怪物卡牌属性
		'''
		cardNum = 0
		fightPoint = 0
		for k, monster in enumerate(enemy['monsters']):
			if monster and 'attrs' not in monster:
				card = CardSlim(monster)
				attrs = ObjectCard.calcAttrs(card)
				fightingPoint = ObjectCard.calcFightingPoint(card, attrs)
				fightPoint += fightingPoint
				monster['fighting_point'] = fightingPoint
				monster['attrs'] = attrs
				cardNum += 1

		# 战力差 = 基准战力 - 实际总战力
		subFight = enemy['fighting_point'] - fightPoint
		if subFight <= 0:
			return

		hpWeight = 9.6
		attackWeight = 1.2
		defenceWeight = 1
		attackSpecialWeight = 1.2
		defenceSpecialWeight = 1
		speedWeight = 0.1
		# 根据战力差 修正 生命攻击防御
		cfgFight = csv.fighting_weight[1]
		l_fight = hpWeight*cfgFight.hp + attackWeight*cfgFight.damage + defenceWeight*cfgFight.defence + attackSpecialWeight*cfgFight.specialDamage + defenceSpecialWeight*cfgFight.specialDefence + speedWeight*cfgFight.speed
		once_rate = subFight*1.0 / l_fight / cardNum
		realFightingPoint = 0
		for k, monster in enumerate(enemy['monsters']):
			if monster:
				attrs = enemy['monsters'][k]['attrs']
				attrs['hp'] += once_rate*hpWeight
				attrs['damage'] += once_rate*attackWeight
				attrs['defence'] += once_rate*defenceWeight
				attrs['speed'] += once_rate * speedWeight
				attrs['specialDamage'] += once_rate * attackSpecialWeight
				attrs['specialDefence'] += once_rate * defenceSpecialWeight
				card = CardSlim(monster)
				realFightingPoint += ObjectCard.calcFightingPoint(card, attrs)
		# 怪物实际总战力
		enemy['fighting_point'] = realFightingPoint

	def setEnermyToRoom(self):
		'''
		将怪物塞入当前房间
		'''
		curRoomBoards = self.boards[self.room]
		monsterCards = {}
		for boardID in curRoomBoards:
			if csv.random_tower.board[boardID]['type'] == RandomTowerDefs.MonsterType:
				monsterCards[boardID] = self.randomEnemyCards(boardID)
		self.room_info['enemy'] = monsterCards

	def isCardDead(self, cardID):
		'''
		判断 卡牌是否死亡
		'''
		if cardID in self.card_states and self.card_states[cardID][0] <= 0:
			return True
		return False

	def hasDeadCard(self, battleCardIDs):
		'''
		判断 阵容中是否有死亡
		'''
		for k, v in enumerate(battleCardIDs):
			if v and self.isCardDead(v):
				return True
		return False

	def statesHasDeadCard(self):
		'''
		判断 以太卡牌是否有死亡
		'''
		for cardID, v in self.card_states.iteritems():
			hp, mp = v
			card = self.game.cards.getCard(cardID)
			if card:
				if card.level < 10:
					continue
				if hp <= 0:
					return True
		return False

	def setEnemyState(self, cardID, rawT):
		'''
		更新怪物卡牌 生命怒气
		'''
		hp, mp = rawT
		cardID = str(cardID)
		self.enemy_states[cardID] = (min(hp, 1), min(mp, 1))

	def setCardState(self, cardID, rawT):
		'''
		更新自身卡牌 生命怒气
		'''
		hp, mp = rawT
		self.card_states[cardID] = (min(hp, 1), min(mp, 1))

	def passResumeMp(self, monfloors):
		'''
		碾压 战力前10 获得200怒气
		'''
		allCards = self.game.cards.getAllCards()
		points = allCards.values()
		points.sort(key=lambda o: o.fighting_point, reverse=True)
		count = 0
		for card in points:
			if card.level < 10:
				continue
			if not self.isCardDead(card.id):
				if card.id not in self.card_states:
					self.card_states[card.id] = (1, min(1, monfloors * 200.0 / card.csvAttrs['mp1']))
				else:
					states = self.card_states[card.id]
					self.card_states[card.id] = (states[0], min(1, states[1] + monfloors * 200.0 / card.csvAttrs['mp1']))
				count += 1
				if count >= 10:
					break

	def isCanPass(self):
		'''
		是否可以碾压
		'''
		basePassRoom = 0  # 等级保底碾压
		lastPassRoom = 0  # 昨日保底碾压
		hisPassRoom = 0  # 历史最高保底碾压
		if self.last_room:
			lastPassRoom = csv.random_tower.tower[self.last_room].canPass
		if self.history_room:
			hisPassRoom = csv.random_tower.tower[self.history_room].canPass

		for i in csv.random_tower.can_pass:
			cfg = csv.random_tower.can_pass[i]
			if cfg.level <= self.game.role.level and cfg.vip <= self.game.role.vip_level:
				basePassRoom = max(cfg.canPass, basePassRoom)

		maxPassRoom = max(min(basePassRoom, hisPassRoom), lastPassRoom)
		return self.room <= maxPassRoom

	def updateSkillUsed(self):
		'''
		更新被动技能使用次数
		'''
		buffs = []
		for index, buffID in enumerate(self.buffs):
			if csv.random_tower.buffs[buffID]['buffType'] == RandomTowerDefs.BuffSkill:
				self.skill_used[buffID] = self.skill_used.get(buffID, 0) + 1
				# 如果次数使用达到限制后 自动下掉（0为无限次）
				if csv.random_tower.buffs[buffID].effectTimes == 0 or self.skill_used.get(buffID, 0) < csv.random_tower.buffs[buffID].effectTimes:
					buffs.append(buffID)
				else:
					self.skill_used.pop(buffID)
			else:
				buffs.append(buffID)
		self.buffs = buffs

	def randomEvent(self, boardID):
		'''
		随机事件组的获得
		'''
		# 先随事件组
		cfgBoard = csv.random_tower.board[boardID]
		weights = cfgBoard.event
		randobj = WeightRandomObject(weights)
		eventGroup, _ = randobj.getRandom()
		# 再随具体事件
		eventCsvIDs = copy.copy(self.RandomTowerEventMap.get(eventGroup, []))
		# 将 不满足条件的给去掉
		for csvID in self.RandomTowerEventMap.get(eventGroup, []):
			cfg = csv.random_tower.event[csvID]
			if cfg.onlyOne:
				if self.event_time.get(csvID, 0):
					eventCsvIDs.remove(csvID)
			else:
				if self.event_time.get(csvID, 0) + 1 > cfg.limit:
					eventCsvIDs.remove(csvID)

		eventCsvID = random.choice(eventCsvIDs)

		return eventCsvID

	def setEventToRoom(self):
		'''
		将事件塞入当前房间
		'''
		curRoomBoards = self.boards[self.room]
		events = {}
		for boardID in curRoomBoards:
			if csv.random_tower.board[boardID]['type'] == RandomTowerDefs.EventType:
				events[boardID] = self.randomEvent(boardID)
		self.room_info['event'] = events

	def getEventAward(self, cfgEvent, choice='choice1'):
		'''
		获得随机事件奖励
		'''
		effAward = ObjectGainAux(self.game, {})
		buffList = []
		points = 0
		num = choice[6:]
		result = cfgEvent['result'+num]
		for k, v in result.iteritems():
			if k == 'items':
				effAward += ObjectGainAux(self.game, v)
			elif k == 'buff':
				buffList.extend(v)
			elif k == 'points':
				points += v
		# 运营活动 金币双倍
		yyTimes = 1
		yyID = ObjectYYHuoDongFactory.getDoubleDropOpenID(YYHuoDongDefs.DoubleRandomTowerGold)
		if yyID:
			yyTimes = 2
		if effAward.gold > 0:
			effAward.gold = effAward.gold * yyTimes
		return effAward, buffList, points

	def randomBuff(self, boardID):
		'''
		随机buff
		'''
		# 先随buff组
		cfgBoard = csv.random_tower.board[boardID]
		weights = cfgBoard.buff
		randobj = WeightRandomObject(weights)
		buffGroup, _ = randobj.getRandom()
		# 再随具体buff
		buffCsvIDs = copy.copy(self.RandomTowerBuffMap.get(buffGroup, []))
		# 将 不满足条件的给去掉
		for csvID in self.RandomTowerBuffMap.get(buffGroup, []):
			cfg = csv.random_tower.buffs[csvID]
			if cfg.onlyOne:
				if self.buff_time.get(csvID, 0):
					buffCsvIDs.remove(csvID)
			else:
				if self.buff_time.get(csvID, 0) + 1 > cfg.limit:
					buffCsvIDs.remove(csvID)
			if cfg.belongLib != 0 and cfg.belongLib not in self.buff_lib:
				buffCsvIDs.remove(csvID)
		weights = {}
		for csvID in buffCsvIDs:
			weights[csvID] = csv.random_tower.buffs[csvID]['weight']
		buffRandobj = WeightRandomObject(weights)
		buffCsvID, _ = buffRandobj.getRandom()

		return buffCsvID

	def setBuffToRoom(self):
		'''
		将buff塞入当前房间
		'''
		curRoomBoards = self.boards[self.room]
		buffs = {}
		for boardID in curRoomBoards:
			if csv.random_tower.board[boardID]['type'] == RandomTowerDefs.BuffType:
				buffs[boardID] = self.randomBuff(boardID)
		self.room_info['buff'] = buffs

	def addBuffs(self, buffCsvID):
		'''
		添加buff 到 self.buffs
		'''
		cfg = csv.random_tower.buffs[buffCsvID]
		# 已经获得过 且 还存在的被动技能
		if cfg.buffType == RandomTowerDefs.BuffSkill and buffCsvID in self.buffs:
			if self.skill_used.get(buffCsvID, 0):
				# 第二次获得 使用次数从0开始记
				self.skill_used.pop(buffCsvID)
		else:
			self.buffs.append(buffCsvID)

	def buffSupply(self, buffID, cards=None):
		'''
		buff 补给使用
		'''
		cfg = csv.random_tower.buffs[buffID]
		supplyType = cfg.supplyType  # 补给类型
		supplyTarget = cfg.supplyTarget  # 补给目标
		supplyNum = cfg.supplyNum  # 补给参数

		supplyCards = []
		# 获取目标卡牌
		if supplyTarget == RandomTowerDefs.SupplyTargetOne:
			if not cards:
				if supplyType == RandomTowerDefs.SupplyHp and self.hasHpNotEnoughCard():
					raise ClientError('SupplyHp, cards is None')
				elif supplyType == RandomTowerDefs.SupplyMp and self.hasMpNotEnoughCard():
					raise ClientError('SupplyMp, cards is None')
				elif supplyType == RandomTowerDefs.SupplyRevive and self.statesHasDeadCard():
					raise ClientError('SupplyRevive, cards is None')
			else:
				supplyCards = cards if isinstance(cards, list) else [cards]
			for cardID in supplyCards:
				card = self.game.cards.getCard(cardID)
				if card:
					if card.level < 10:
						raise ClientError('card level error')
		elif supplyTarget == RandomTowerDefs.SupplyTargetBattle:
			supplyCards = self.game.role.huodong_cards.get(RandomTowerHuodongID, [])  # 不达到10级的不会在阵容中
		else:
			for card in self.game.cards.getCards(self.game.role.cards):
				if card.level >= 10:
					supplyCards.append(card)

		for cardID in supplyCards:
			if cardID:
				# 回血 回怒  扣血  扣怒
				if not self.isCardDead(cardID) and supplyType != RandomTowerDefs.SupplyRevive:
					hp, mp = self.card_states.get(cardID, (1, 0))
					if supplyType == RandomTowerDefs.SupplyHp:  # 回血
						self.card_states[cardID] = (min(hp+supplyNum/float(100), 1), mp)
					elif supplyType == RandomTowerDefs.SupplyMp:  # 回怒
						self.card_states[cardID] = (hp, min(mp+supplyNum/float(100), 1))
					elif supplyType == RandomTowerDefs.SupplyCutHp:  # 扣血 不能扣死
						self.card_states[cardID] = (hp-hp*(supplyNum/float(100)), mp)
					elif supplyType == RandomTowerDefs.SupplyCutMp:  # 扣怒
						self.card_states[cardID] = (hp, max(mp-supplyNum/float(100), 0))
				# 复活
				if self.isCardDead(cardID) and supplyType == RandomTowerDefs.SupplyRevive:
					_, mp = self.card_states.get(cardID, (1, 0))
					self.card_states[cardID] = (1, mp)

	def isBuffCondition(self, buffID):
		'''
		是否符合前置条件
		'''
		cfg = csv.random_tower.buffs[buffID]
		if not cfg.condition:
			return True
		if cfg.condition == RandomTowerDefs.BuffCardDead:
			return self.statesHasDeadCard()
		elif cfg.condition == RandomTowerDefs.BuffCardHp:
			return self.hasHpNotEnoughCard()
		elif cfg.condition == RandomTowerDefs.BuffCardMp:
			return self.hasMpNotEnoughCard()
		return False

	def hasHpNotEnoughCard(self):
		for cardID, state in self.card_states.iteritems():
			card = self.game.cards.getCard(cardID)
			if card:
				if card.level < 10:
					continue
				if 0 < state[0] < 1:
					return True
		return False

	def hasMpNotEnoughCard(self):
		# 如果没有card_states 默认怒气为0，也是不满怒
		if not self.card_states:
			return True
		for cardID, state in self.card_states.iteritems():
			card = self.game.cards.getCard(cardID)
			if card:
				if card.level < 10:
					continue
				if state[0] > 0 and state[1] < 1:
					return True
		return False

	def checkPointAwardVersion(self, updateVersion=True):
		"""
		积分奖励版本检测
		"""

		if self.point_award_version != self.PointAwardVersion :
			eff = ObjectGainAux(self.game, {})
			for i, flag in self.point_award.iteritems():
				if flag != 1:
					continue
				cfg = csv.random_tower.point_award[i]
				eff += ObjectGainAux(self.game, cfg.award)
				self.point_award[i] = 0
			award = eff.to_dict()
			if award:
				mail = ObjectRole.makeMailModel(self.game.role.id, RandomTowerPointAwardMailID, attachs=award)
				MailJoinableQueue.send(mail)

			if updateVersion:
				self.point_award_version = self.PointAwardVersion
				self.point_award = {}
				self.calPointAward()

			return True
		return False

	def calPointAward(self):
		'''
		计算积分奖励
		'''
		allPoint = int(self.day_point + self.history_point * 0.08)
		for i in self.PointAwardMap.get(self.point_award_version, []):
			cfg = csv.random_tower.point_award[i]
			if cfg.needPoint > allPoint:
				break
			if self.point_award.get(i, -1) == -1:
				self.point_award[i] = 1

	def getCardsAttr(self, cardIDs):
		'''
		获取卡牌的属性（加成后）
		'''
		attrsD = {}  # {attr: (const, percent)}
		for buffID in self.buffs:
			cfg = csv.random_tower.buffs[buffID]
			if cfg.buffType == RandomTowerDefs.BuffAttrAdd:
				for i in xrange(1, 99):
					attrType = "attrType%d" % i
					if attrType not in cfg or not cfg[attrType]:
						break
					attrNum = "attrNum%d" % i
					num = str2num_t(cfg[attrNum])
					const, percent = attrsD.get(AttrDefs.attrsEnum[cfg[attrType]], (0.0, 0.0))
					const += num[0]
					percent += num[1]
					attrsD[AttrDefs.attrsEnum[cfg[attrType]]] = (const, percent)

		cardsAttr, cardsAttr2 = self.game.cards.makeBattleCardModel(cardIDs, SceneDefs.RandomTower)
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
			cardAttr['fighting_point'] = ObjectCard.calcFightingPoint(card, attrs)

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
			cardAttr['fighting_point'] = ObjectCard.calcFightingPoint(card, attrs)

		return cardsAttr, cardsAttr2

	def getBuffPointAdd(self, battleRound, aliveCount):
		'''
		打怪获取积分加成
		'''
		point = 0
		for buffID in self.buffs:
			cfg = csv.random_tower.buffs[buffID]
			if cfg.buffType == RandomTowerDefs.BuffPointAdd:
				if cfg.pointType == RandomTowerDefs.PointRoundType:  # 剩余回合数
					point = (10 - battleRound) * cfg.pointValue
				elif cfg.pointType == RandomTowerDefs.PointAliveType:  # 存活数
					point = aliveCount * cfg.pointValue
				elif cfg.pointType == RandomTowerDefs.PointFloorType:  # 当前层数
					floor = csv.random_tower.tower[self.room].floor
					point = floor * cfg.pointValue
		return point

	def getJumpRoomNum(self):
		'''
		可以跳到的房间数
		'''
		jumpRoom = 0  # 等级、VIP可直通房间数
		for i in csv.random_tower.can_jump:
			cfg = csv.random_tower.can_jump[i]
			if cfg.level <= self.game.role.level and cfg.vip <= self.game.role.vip_level:
				jumpRoom = max(cfg.canJump, jumpRoom)
		return jumpRoom

	def beginJumpRoom(self):
		'''
		开始进入直通
		'''
		roomNum = self.getJumpRoomNum()
		i = random.randint(1, 3)
		boxNum = 0
		battleNum = 0
		points = 0
		eff = ObjectGainAux(self.game, {})
		# 先清空昨日数据
		self.jump_info = {}
		for idx in sorted(csv.random_tower.tower):
			if idx > roomNum:
				break
			cfg = csv.random_tower.tower[idx]
			markType = cfg["markType%d" % i]
			if not markType:
				continue
			markBoard = cfg["markBoards%d" % i]
			boardGroup = cfg["boardGroups%d" % i]
			if markType == RandomTowerDefs.BoxType:  # 宝箱
				cfgBoard = csv.random_tower.board[markBoard]
				if cfgBoard.boxType == RandomTowerDefs.SpecialType:
					boxes = self.jump_info.setdefault('boxes', {})
					boxes[markBoard] = 0
				boxNum += 1
				eff += self.getFirstBoxAwards(markBoard)
			elif markType == RandomTowerDefs.MonsterType:  # 怪物
				# 积分获得 = 等级基础积分（initPoint)*怪物积分修正系数（pointC）*战斗星级表现系数（starRate）*Vip加成（vipRate）
				cfgBoard = csv.random_tower.board[markBoard]
				initPoint = csv.random_tower.point[self.game.role.level]['initPoint']
				pointC1 = cfg['pointC'][cfgBoard.monsterType - 1]
				pointC2 = cfgBoard['pointC']
				starRate = RandomTowerDefs.StarRate.get(3)
				vipRate = self.game.role.randomTowerPointRate
				points += int(initPoint * pointC1 * pointC2 * starRate * vipRate)
				battleNum += 1
				# 战力前10 获得200怒气
				self.passResumeMp(1)
			elif markType == RandomTowerDefs.BuffType:  # buff
				buffs = self.jump_info.setdefault('buffs', [])
				# 先不随，buff阶段时选一个再随下一组。
				buffMap = {}
				for boardID in boardGroup:
					buffMap[boardID] = None
				buffs.append(buffMap)
			elif markType == RandomTowerDefs.EventType:  # 事件
				events = self.jump_info.setdefault('events', {})
				eventCsvID = self.randomEvent(markBoard)
				events[markBoard] = (eventCsvID, 0)  # 0为未选
		# 每日积分增加
		self.day_point += points
		# 宝箱计数
		ObjectYYHuoDongFactory.onGeneralTask(self.game, TargetDefs.RandomTowerBoxOpen, boxNum)
		retData = {
			'battle': battleNum,
			'points': points,
			'generalBoxes': boxNum - len(self.jump_info.get('boxes', {})),
			'award': eff
		}
		return retData

	def randomJumpBuffs(self, buffIndex):
		'''
		跳过 随机buff
		'''
		buffs = self.jump_info.get('buffs', [])
		if buffIndex <= len(buffs):
			buffMap = buffs[buffIndex-1]
			boardID = random.choice(list(buffMap.keys()))
		else:
			raise ClientError('buffIndex out the buffs')
		return boardID

	def nextRandomJumpBuffs(self):
		'''
		跳过 下一步 随机获得剩下buffs
		'''
		buffs = self.jump_info.get('buffs', [])
		buffIndex = self.jump_info.get('buff_index', 1)
		if buffIndex > len(buffs):
			return
		lenBuff = len(buffs)
		for i in range(buffIndex-1, lenBuff):
			buffMap = buffs[i]
			boardID = random.choice(list(buffMap.keys()))
			buffCsvID = buffMap.get(boardID, 0)
			self.setJumpBuff(buffCsvID)
			if i < lenBuff-1:
				# 非最后一个房间则随下一房间buffIDs
				self.doJumpInfoBuffs(i+1)
		self.jump_info['buff_index'] = len(buffs)

	def setJumpBuff(self, buffCsvID):
		'''
		跳过 获得buff
		'''
		cfgBuff = csv.random_tower.buffs[buffCsvID]
		# 记录 buff
		self.buff_time[buffCsvID] = self.buff_time.get(buffCsvID, 0) + 1
		if cfgBuff['changeLib'] != 0:
			self.buff_lib.append(cfgBuff['changeLib'])
		self.addBuffs(buffCsvID)

	def doJumpInfoBuffs(self, index):
		'''
		跳过 随下一房间buffs
		'''
		buffs = self.jump_info.setdefault('buffs', [])
		if index >= len(buffs):
			raise ClientError('buffIndex out the buffs')
		boardIDs = list(buffs[index].keys())
		for boardID in boardIDs:
			buffs[index][boardID] = self.randomBuff(boardID)

	def openJumpSpecialBox(self, boardID, openCount):
		'''
		跳过 打开豪华宝箱
		'''
		eff = ObjectGainAux(self.game, {})
		cost = ObjectCostAux(self.game, {})
		cfg = csv.random_tower.board[boardID]
		boxes = self.jump_info.get('boxes', {})
		count = boxes.get(boardID, 0)
		for i in range(count, count+openCount):
			costRMB = ObjectCostCSV.getRandomTowerBoxCost2(i+1)
			cost += ObjectCostAux(self.game, {'rmb': costRMB})
			eff += ObjectGainAux(self.game, cfg['randomLibs2'])
		return cost, eff


