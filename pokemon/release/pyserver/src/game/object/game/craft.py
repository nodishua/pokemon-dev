#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2016 TianJi Information Technology Inc.
'''

from framework import inclock5date, nowdatetime_t, todaydate2int, nowtime_t, todayinclock5elapsedays, nowtime2int, DailyRefreshHour
from framework.csv import ErrDefs, csv, MergeServ
from framework.log import logger
from framework.object import db_property, ObjectNoGCDBase
from framework.helper import model2NamedTuple, randomRobotName

from game import globaldata, ClientError
from game.globaldata import *
from game.helper import getCraftRankAwardVersion
from game.object import FeatureDefs, TitleDefs, MessageDefs
from game.object.game.gain import ObjectGoodsMap, ObjectCostAux
from game.object.game.levelcsv import ObjectFeatureUnlockCSV

import re
import copy
import bisect
import random
import datetime
from collections import namedtuple, deque

from tornado.gen import coroutine, moment, sleep, Return


RoleSignFields = ['id', 'name', 'logo', 'frame', 'level', 'figure', 'title_id', 'vip_level', 'craft_record_db_id']

RobotCSVCard = namedtuple('RobotCSVCard', ['card', 'levelC', 'star', 'advance', 'damageC', 'defenceC', 'hpC'])
RobotCSVLine = namedtuple('RobotCSVLine', ['id', 'cards'])

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

class ObjectCraftInfoGlobal(ObjectNoGCDBase):
	DBModel = 'CraftGameGlobal'

	Singleton = None

	OpenDateTime = None
	OpenWeekday = None
	OpenLevel = 0
	AutoSignVIP = 0
	NumMax = 0

	RobotDailyLevelList = []
	RobotLevelCardMap = {}

	AutoSignRoleMap = {} # {Role.id: (name, logo, level, vip_level, craft_record_db_id)} craft_record_db_id必须>0

	RoundNumRE = re.compile(r"(pre|final)(?P<num>\d+)(_lock)?")
	FinalRatio = 56. / 1024 # 1024参赛，预选赛结束还没淘汰的比率
	SignMinNum = 147 # ceil(8 * 1024 / 56)，最少参赛人数

	@classmethod
	def classInit(cls):
		cfg = csv.craft.base[1]
		cls.OpenDateTime = datetime.datetime.combine(inclock5date(globaldata.GameServOpenDatetime) + datetime.timedelta(days=cfg.servOpenDays - 1), datetime.time(hour=DailyRefreshHour))
		cls.NumMax = cfg.numMax
		cls.OpenLevel = ObjectFeatureUnlockCSV.getOpenLevel(FeatureDefs.Craft)
		cls.AutoSignVIP = cfg.autoSignVIP
		cls.RobotDailyLevelList = []
		cls.RobotLevelCardMap = {}
		if ObjectFeatureUnlockCSV.isFeatureExist(FeatureDefs.Craft):
			cls.OpenWeekday = cfg.openWeekday
		else: # 未开放把开放星期置空来限制
			cls.OpenWeekday = tuple()

		# robot_level.csv
		for idx in sorted(csv.craft.robot_level.keys()):
			cfg = csv.craft.robot_level[idx]
			cls.RobotDailyLevelList.append(cfg.levelRange)

		# robot_card.csv
		for idx in csv.craft.robot_card:
			cfg = csv.craft.robot_card[idx]
			cards = []
			for i in xrange(1, 11):
				card = RobotCSVCard(cfg['card%d' % i], cfg['levelC%d' % i], cfg['star%d' % i], cfg['advance%d' % i], cfg['damageC%d' % i], cfg['defenceC%d' % i], cfg['hpC%d' % i])
				cards.append(card)
			line = RobotCSVLine(idx, cards)
			cls.RobotLevelCardMap.setdefault(cfg.levelMax, []).append(line)

		for roleID in cls.AutoSignRoleMap.keys():
			item = cls.AutoSignRoleMap[roleID]
			if item['vip_level'] < cls.AutoSignVIP:
				cls.AutoSignRoleMap.pop(roleID)

	def __init__(self, dbc):
		ObjectNoGCDBase.__init__(self, None, dbc)

		if ObjectCraftInfoGlobal.Singleton is not None:
			raise ValueError('This is singleton object')
		ObjectCraftInfoGlobal.Singleton = self

	def init(self, rpc, data):
		self._rpc = rpc
		self._battleMessages = deque(maxlen=CraftBattleMessageMax)
		self.top8_plays = {} # 今日8强战斗记录

		self.autoSignOK = False
		self.robotNum = 0

		self._msginc = 0 # battle message 增量，辅助 broadcast
		self._broadcastime = 0

		if data:
			self.round = data['round']
			self.time = data['time']
			self.top8_plays = data['top8_plays']
		return self

	@classmethod
	@coroutine
	def onCraftEvent(cls, event, data, sync):
		if event != 'new_play':
			logger.info('ObjectCraftInfoGlobal.onCraftEvent %s', event)

		self = cls.Singleton
		if sync:
			self.round = sync['round']
			self.time = sync['time']
			self.top8_plays = sync['top8_plays']

		if 'last_rank_roles' in data:
			self.onRefreshRank(data['last_rank_roles'])

		ret = {}
		if event == 'prepare':
			self.onAutoSignUp()
			yield self.onStartPrepare()
			# 强刷一遍在线玩家的record
			from game.object.game import ObjectGame
			from game.handler._craft import refreshCardsToPVP
			try:
				allobjs, safeGuard = ObjectGame.getAll()
				with safeGuard:
					for game in allobjs:
						if game.role.id in self.signup:
							game.dailyRecord.craft_sign_up = True
							try:
								yield refreshCardsToPVP(self._rpc, game, force=True)
							except:
								logger.exception('refreshCardsToPVP error')
			except:
				logger.exception('safeGuard error')

			ret['signup'] = self.signup.values()

		elif event == 'matches':
			self.onStartRound()

		elif event == 'play':
			self.onPlayStart()

		elif event == 'new_play':
			self.onNewPlay(data['battle_message'])

		elif event == 'over':
			self.onOver()
			self.clean()

		elif event == 'bet_award':
			self.onBetAward(data.get('craft_bets', {})) # if none bet, key craft_bets not in data

		elif event == 'battle_award':
			self.onBattleAward(data['craft_roles'])

		elif event == 'rank_award':
			yield self.onRankAward(data['craft_ranks'])

		raise Return(ret)

	@classmethod
	def getRoundInTime(cls):
		dt = nowdatetime_t()
		if dt.isoweekday() not in cls.OpenWeekday:
			return "closed"
		nt = nowdatetime_t().time()
		if nt < CraftSignUpDailyTimeRange[0]:
			return 'closed'
		if CraftSignUpDailyTimeRange[0] < nt < CraftSignUpDailyTimeRange[1]:
			return 'signup'
		if nt < CraftBattleDailyTime:
			return 'prepare'
		if nt > CraftBattleDailyTime:
			return 'battle'
		return 'unknown'

	# 初始化自动报名map
	@classmethod
	def initAutoSignUp(cls, models):
		cls.AutoSignRoleMap = {}
		for model in models:
			if not model['craft_record_db_id'] or model['disable_flag'] or model['top_cards'] < 10:
				continue
			cls.AutoSignRoleMap[model['id']] = model2signitem(model, RoleSignFields)
		logger.info('Craft Init AutoSign Roles %d', len(cls.AutoSignRoleMap))

	@classmethod
	def isTodayOpen(cls):
		dt = nowdatetime_t()
		if cls.OpenDateTime == dt:
			return True
		if cls.OpenDateTime > dt:
			return False
		return dt.isoweekday() in cls.OpenWeekday

	@classmethod
	def isOpen(cls):
		return cls.OpenDateTime < nowdatetime_t()

	@classmethod
	def isRoleOpen(cls, level):
		return level >= cls.OpenLevel and cls.OpenDateTime < nowdatetime_t()

	# 是否可以报名
	@classmethod
	def isCanSignUp(cls, game):
		self = cls.Singleton
		if self.round != 'signup' or not game.role.craft_record_db_id:
			return False
		if game.role.vip_level < cls.AutoSignVIP and len(self.signup) >= cls.NumMax: # vip 等级大于自动报名的，不受人数限制
			return False
		return True

	@classmethod
	def isCanBet(cls):
		self = cls.Singleton
		return self.round in ('signup',)

	@classmethod
	def onRoleInfo(cls, game):
		self = cls.Singleton
		role = game.role
		if role.vip_level >= cls.AutoSignVIP and role.level >= cls.OpenLevel and role.craft_record_db_id:
			if len(role.top_cards) < 10:
				game.dailyRecord.craft_sign_up = role.id in self.signup
				return
			cls.AutoSignRoleMap[role.id] = model2signitem(role, RoleSignFields)

			# 刷新自动报名的玩家数据
			# 如果报名已开始则自动报名
			if not game.dailyRecord.craft_sign_up and self.autoSignOK:
				if self.date == todaydate2int() and cls.isRoleOpen(game.role.level) and cls.isCanSignUp(game):
					cls.signUp(game)
		game.dailyRecord.craft_sign_up = role.id in self.signup

	def reset(self):
		ndi = todaydate2int()
		if self.date == ndi:
			return False

		logger.info('Craft Reset %d %s, %d', self.date, self.round, ndi)
		self.date = ndi
		self.time = int(nowtime_t())
		self.round = 'closed'
		self.signup = {}
		# self.yesterday_top8_plays = copy.deepcopy(self.top8_plays)
		self.top8_plays = {}
		self.buffs = []

		self._battleMessages = deque(maxlen=CraftBattleMessageMax)

		self.autoSignOK = False
		return True

	def clean(self):
		# 战斗结束，奖励完毕后就进行clean，等过天之后进行reset
		logger.info('Craft Clean %d %s', self.date, self.round)
		self.time = int(nowtime_t())
		self.round = 'closed'
		self.signup = {}
		self.yesterday_top8_plays = copy.deepcopy(self.top8_plays)
		self.top8_plays = {}
		self.buffs = []

		self._battleMessages = deque(maxlen=CraftBattleMessageMax)

		self.autoSignOK = False

	# 自动/手动报名
	# 报名
	@classmethod
	def signUp(cls, game, cards=None, manual=False):
		self = cls.Singleton
		role = game.role
		if role.id in self.signup:
			if not manual:
				manual = self.signup[role.id].get('manual', False)
		self.signup[role.id] = model2signitem(role, RoleSignFields, manual=manual)
		game.dailyRecord.craft_sign_up = True

	# 获取上阵卡牌
	@classmethod
	def isSigned(cls, game):
		self = cls.Singleton
		signed = game.role.id in self.signup
		game.dailyRecord.craft_sign_up = signed
		return signed

	@classmethod
	def isInSign(cls):
		self = cls.Singleton
		return self.round == 'signup'

	@classmethod
	def isInBattle(cls):
		self = cls.Singleton
		if self.round[:7] != 'prepare':
			return self.round[:3] in ('pre', 'fin')
		return False

	@classmethod
	def isOver(cls):
		self = cls.Singleton
		return self.round in ('over', 'closed')

	@classmethod
	def getYesterdayTop8(cls, ti):
		self = cls.Singleton
		if ti != self.yesterday_refresh_time:
			return self.yesterday_top8_plays
		return None

	# 开始报名 closed -> signup
	@classmethod
	def onStartSignUp(cls, rpc):
		self = cls.Singleton
		if self.round == 'signup': # 重启可能导致过次进入
			logger.warning('Craft already in %s', self.round)
			return

		self.reset()
		if self.round != 'closed':
			logger.warning('Craft onStartSignUp Status Error %s', self.round)
			return

		logger.info('ObjectCraftInfoGlobal.onStartSignUp')
		self.round = 'signup'
		self.time = int(nowtime_t())
		self.makeRandomBuff()

	# 自动报名 signup
	@classmethod
	def onAutoSignUp(cls):
		self = cls.Singleton
		cnt = 0
		for roleID, item in self.AutoSignRoleMap.iteritems():
			if roleID not in self.signup:
				self.signup[roleID] = item
				cnt += 1

		self.autoSignOK = True
		logger.info('ObjectCraftInfoGlobal.onAutoSignUp %d, %d', cnt, len(self.signup))

	# 通知 craft service 开始
	@classmethod
	@coroutine
	def onStartCraft(cls, rpc):
		self = cls.Singleton
		if self.round != 'signup':
			logger.warning('Craft onStartCraft Status Error %s', self.round)
			raise Return(None)

		logger.info('ObjectCraftInfoGlobal.onStartCraft')
		yield rpc.call_async('StartCraft', self.buffs, False)

	# 报名结束 signup -> prepare
	@coroutine
	def onStartPrepare(self):
		logger.info('ObjectCraftInfoGlobal.onStartPrepare')

		self._battleMessages = deque(maxlen=CraftBattleMessageMax)
		self.autoSignOK = False

		# 清空game里的榜单
		from game.object.game.rank import ObjectRankGlobal
		yield ObjectRankGlobal.rankClear('craft')

		# 构造机器人
		yield self._makeRobots()

		# 创建机器人CraftRecord
		ret = yield self._rpc.call_async('CreateRobotCraftRecordBulk', self.robots.values())
		logger.info('ObjectCraftInfoGlobal.onStartPrepare Create Robot CraftRecord Finished %s', ret)

		# 机器人进入参赛名单
		for roleID, d in self.robots.iteritems():
			self.signup[roleID] = model2signitem(d, RoleSignFields, craft_record_db_id=roleID, vip_level=0, vip_hide=False)

	# 每局准备阶段开始 (pre1, pre2, ..., final3)
	def onStartRound(self):
		logger.info('ObjectCraftInfoGlobal.onStartRound %s', self.round)
		self._battleMessages = deque(maxlen=CraftBattleMessageMax)
		self.broadcast()

	# 每局准备阶段结束 (pre1, ..., final3) -> (pre1_lock, ..., final3_lock)
	def onPlayStart(self):
		if self.round[-4:] != 'lock':
			self.round += '_lock'
		logger.info('ObjectCraftInfoGlobal.onPlayStart %s', self.round)

	# 有新战斗结果
	def onNewPlay(self, playMsg):
		roleID1, roleID2 = playMsg['roles']
		item1 = self.signup[roleID1]
		if roleID2:
			item2 = self.signup[roleID2]
			self._battleMessages.append((playMsg['round'], (roleID1, item1['name']), (roleID2, item2['name']), playMsg['result'], playMsg['points'], playMsg['streak']))

			# 根据策略进行广播
			self._msginc += 1
			if self.round[:5] == 'final' or self._msginc > 100 or nowtime_t () - self._broadcastime > 10:
				self.broadcast()

	# 更新排行榜
	@coroutine
	def onRefreshRank(self, roles):
		from game.object.game.rank import ObjectRankGlobal
		import time
		roles = {roleID: t for roleID, t in roles.iteritems() if 'robot' not in roleID}
		yield ObjectRankGlobal.onKeyInfoChange(None, 'craft', roles)

	# 全部结束 final3 -> over
	def onOver(self):
		logger.info('ObjectCraftInfoGlobal.onOver')
		self.yesterday_top8_plays = copy.deepcopy(self.top8_plays)

	# 根据等级读取奖励
	def getAwardByLevel(self, awardList, level):
		for start, end, award in awardList:
			if level >= start and level <= end:
				return award

		# 配置错误，但保证玩法正常结束
		return {}

	# 战斗奖励
	def onBattleAward(self, roles):
		logger.info('ObjectCraftInfoGlobal.onBattleAward %s', len(roles))
		from game.mailqueue import MailJoinableQueue
		from game.object.game.role import ObjectRole
		# 发战斗奖励
		for roleID, t in roles.iteritems():
			round, win, point, level = t
			lose, award = min(round, 13) - win, None
			if win > 0:
				award = ObjectGoodsMap(None, self.getAwardByLevel(csv.craft.base[1].winAward, level))
				award *= win
			if lose > 0:
				award2 = ObjectGoodsMap(None, self.getAwardByLevel(csv.craft.base[1].failAward, level))
				award2 *= lose
				if award:
					award += award2
				else:
					award = award2
			if award:
				mail = ObjectRole.makeMailModel(roleID, CraftRoundAwardMailID, contentArgs=(win, lose, point), attachs=award.to_dict())
				MailJoinableQueue.send(mail)

	# 排行奖励
	@coroutine
	def onRankAward(self, ranks):
		logger.info('ObjectCraftInfoGlobal.onRankAward %s', len(ranks))
		from game.mailqueue import MailJoinableQueue
		from game.object.game.role import ObjectRole
		# 发排行奖励
		pre, j = 1, 1
		version = getCraftRankAwardVersion()
		for idx in sorted(csv.craft.rank.keys()):
			cfg = csv.craft.rank[idx]
			if cfg.version != version:
				continue
			for i in xrange(pre, cfg.rankMax + 1):
				while j <= len(ranks):
					roleID, level = ranks[j]
					j += 1
					if 'robot' not in roleID:
						mail = ObjectRole.makeMailModel(roleID, CraftRankAwardMailID, contentArgs=i, attachs=self.getAwardByLevel(cfg.award, level))
						MailJoinableQueue.send(mail)
						break
			pre = cfg.rankMax + 1
			if j > len(ranks):
				break

		# 石英大会结算第一 跑马灯
		roleID, _ = ranks[1]
		from game.object.game.cache import ObjectCacheGlobal
		role = yield ObjectCacheGlobal.queryRole(roleID)
		from game.object.game import ObjectMessageGlobal
		ObjectMessageGlobal.marqueeBroadcast(role, MessageDefs.MqCraftTopRank)
		ObjectMessageGlobal.newsCraftTopRankMsg(role)

	# 下注奖励
	def onBetAward(self, bets):
		logger.info('ObjectCraftInfoGlobal.onBetAward %s', len(bets))
		from game.mailqueue import MailJoinableQueue
		from game.object.game.role import ObjectRole
		for betRoleID, t in bets.iteritems():
			whoName, winGold, level = t
			mail = None
			if level == 'champion':
				mail = ObjectRole.makeMailModel(betRoleID, CraftBetWinAwardMailID, contentArgs=whoName, attachs={'gold': winGold})
			elif level == 'top8':
				mail = ObjectRole.makeMailModel(betRoleID, CraftBetTop8AwardMailID, contentArgs=whoName, attachs={'gold': winGold})
			elif level == 'fail':
				mail = ObjectRole.makeMailModel(betRoleID, CraftBetTop8FailMailID, contentArgs=whoName)
			if mail:
				MailJoinableQueue.send(mail)

	@classmethod
	def getSlimModel(cls):
		self = cls.Singleton
		return {
			'time': self.time,
			'round': self.round,
			'signup': len(self.signup),
			'battle_messages': list(self._battleMessages),
			'top8_plays': self.top8_plays,
			'yesterday_refresh_time': self.yesterday_refresh_time,
			'buffs': self.buffs,
		}

	def broadcast(self):
		self._msginc = 0
		self._broadcastime = nowtime_t()
		data = {
			'model': {
				'craft': {
					'battle_messages': list(self._battleMessages),
				}
			}
		}
		from game.session import Session
		Session.broadcast('/game/push', data, filter=lambda g: not g.role.craft_record_db_id)

	def makeRandomBuff(self):
		count = random.choice([1, 2])
		buffs = []
		ids = set(csv.craft.buffs.keys())
		for _ in xrange(count):
			if ids:
				csvid = random.choice(list(ids))
				buffs.append(csvid)
				ids.discard(csvid)
		self.buffs = buffs
		logger.info('Craft Buffs %s', self.buffs)

	# 构造机器人
	@coroutine
	def _makeRobots(self):
		from game.object.game.card import ObjectCard, randomCharacter, randomNumericalValue

		# robot_num.csv
		self.robotNum = 0
		for idx in sorted(csv.craft.robot_num.keys()):
			cfg = csv.craft.robot_num[idx]
			if cfg.realNum >= len(self.signup):
				self.robotNum = cfg.totalNum - len(self.signup)
				break
		self.robotNum = max(self.robotNum + len(self.signup), self.SignMinNum) - len(self.signup)
		days = todayinclock5elapsedays(globaldata.GameServOpenDatetime)
		robotLevelRange = self.RobotDailyLevelList[min(days, len(self.RobotDailyLevelList) - 1)]
		robotLevels = [random.randint(*robotLevelRange) for i in xrange(self.robotNum)]

		logger.info('Craft Start Make Robots %d, Total %d', self.robotNum, self.robotNum + len(self.signup))

		# robot_card.csv
		self.robots = {}
		fakeCard = ObjectCard(None, None)
		fakeCard.new_deepcopy() # just for delete dbc

		areas = None
		import framework
		if MergeServ.isServMerged(framework.__server_key__):
			areas = MergeServ.getSrcServAreas(framework.__server_key__)

		levelArray = sorted(self.RobotLevelCardMap.keys())
		for idx, level in enumerate(robotLevels, 1):
			if idx % 100 == 0:
				logger.info('Craft Making Robots %d / %d', idx, len(robotLevels))
			roleID = 'robot-%06d' % idx # 机器人RoleID
			group = min(bisect.bisect_left(levelArray, level), len(levelArray) - 1)
			cfg = random.choice(self.RobotLevelCardMap[levelArray[group]])
			# make card
			roleCards = []
			roleCardAttrs = {}
			for cardIdx, cfg2 in enumerate(cfg.cards, 1):
				card_id = cfg2.card
				if card_id not in csv.cards:
					continue
				cardCfg = csv.cards[card_id]
				equips = {}
				for k, v in enumerate(cardCfg.equipsList):
					if v not in csv.equips:
						equips = None
						break
					equips[k + 1] = {
						'equip_id': v,
						'level': 1,
						'star': 0,
						'advance': 1,
						'exp': 0,
						'awake': 0,
					}
				if equips is None:
					continue
				cardID = 'card-%07d' % cardIdx
				fakeCard.set({
					'id': cardID,
					'role_db_id': roleID,
					'card_id': card_id,
					'skin_id': 0,
					'advance': random.randint(*cfg2.advance),
					'star': random.randint(*cfg2.star),
					'develop': cardCfg.develop,
					'level': int(level * random.uniform(*cfg2.levelC)),
					'character': randomCharacter(cardCfg.chaRnd),
					'nvalue': randomNumericalValue(cardCfg.nValueRnd),
					'skills': {},
					'skill_level': [],
					'effort_values': {},
					'effort_advance': 1,
					'equips': equips,
					'fetters': [],
					'fighting_point': 0,
					'held_item': None,
					'abilities': {},
				}).initRobot()
				roleCards.append(cardID)
				attrs = fakeCard.battleModel(False, False, 0)

				# 强制修正
				attrs['attrs']['hp'] *= random.uniform(*cfg2.hpC)
				attrs['attrs']['damage'] *= random.uniform(*cfg2.damageC)
				attrs['attrs']['defence'] *= random.uniform(*cfg2.defenceC)
				attrs['fighting_point'] = ObjectCard.calcFightingPoint(fakeCard, attrs['attrs'])
				roleCardAttrs[cardID] = attrs
				yield moment

			# make role
			# 数据格式参照 role.competitor, embattle
			name = randomRobotName()
			if areas:
				name = '%s.s%d' % (name, areas[random.randint(0, len(areas)-1)])
			self.robots[roleID] = {
				'id': roleID,
				'name': name,
				'level': level,
				'logo': random.randint(1, 2),
				'frame': 1,
				'figure': random.choice([1, 2, 3, 7, 27]),
				'title_id': 0,

				'cards': roleCards,
				'card_attrs': roleCardAttrs,
			}

		logger.info('Craft End Make Robots %d, Total %d', len(self.robots), len(self.robots) + len(self.signup))

	# 日期
	date = db_property('date')

	# CraftGlobal.time
	time = db_property('time')

	# CraftGlobal.round
	round = db_property('round')

	# 每日特色buff [csv_id, ...]
	buffs = db_property('buffs')

	# 报名 {Role.id: RoleSignItem}
	signup = db_property('signup')

	# 昨天前20下注 {Role.id: {role: (name, level, vip_level, craft_record_db_id), rank: 上次排名, rate: 赔率, gold: {Role.id: gold}}}
	bet = db_property('bet')

	# 昨天8强战斗记录 BattleCraftGlobal.top8_plays
	def yesterday_top8_plays():
		dbkey = 'yesterday_top8_plays'
		def fset(self, value):
			self.db[dbkey] = value
			self.yesterday_refresh_time = nowtime2int()
		return locals()
	yesterday_top8_plays = db_property(**yesterday_top8_plays())

	# yesterday的刷新时间
	yesterday_refresh_time = db_property('yesterday_refresh_time')
