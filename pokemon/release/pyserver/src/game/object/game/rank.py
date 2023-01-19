#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2014 YouMi Information Technology Inc.
'''

from __future__ import absolute_import

from framework import nowtime_t
from framework.csv import csv
from framework.log import logger
from framework.object import ObjectCSVRange, ReloadHooker, ObjectDBase, db_property
from framework.helper import copyKV, WeightRandomObject, upperBound
from game import ServerError
from game.object import FeatureDefs, TitleDefs
from game.object.game.gain import ObjectGainAux
from game.object.game.levelcsv import ObjectFeatureUnlockCSV
from game.globaldata import WorldBossRoleAwardMailID, WorldBossUnionAwardMailID, WorldBossServerAwardMailID
from game.object.game.yyhuodong import ObjectYYHuoDongFactory
from game.object.game.union import ObjectUnion

import copy
from collections import namedtuple, defaultdict
from tornado.gen import coroutine, Return
from game.helper import getPWAwardVersion, getRandomTowerAwardVersion

#
# ObjectPWAwardRange
#

class ObjectPWAwardRange(ObjectCSVRange):
	CSVName = 'pwaward'
	RangeL = []

	@classmethod
	def classInit(cls):
		version = cls.getRangeLVersion()
		cls.RangeL = []
		if isinstance(cls.CSVName, (tuple, list)):
			csvR = csv
			for part in cls.CSVName:
				csvR = csvR[part]
		else:
			csvR = getattr(csv, cls.CSVName)
		for idx in csvR:
			cfg = csvR[idx]
			if cfg.version != version:
				continue
			cls.RangeL.append(cls(cfg))
		cls.RangeL.sort(key=lambda o: o.start)

	def __init__(self, cfg):
		ObjectCSVRange.__init__(self, cfg)
		self._periodAward = cfg.periodAward

	@property
	def periodAward(self):
		return self._periodAward

	@classmethod
	def getRangeLVersion(cls):
		return getPWAwardVersion()

#
# ObjectPWAwardEffect
#

class ObjectPWAwardEffect(ObjectGainAux):
	def __init__(self, game, award):
		ObjectGainAux.__init__(self, game, award)

	def gain(self, **kwargs):
		ObjectGainAux.gain(self, **kwargs)

class ObjectArenaFlopAwardRandom(object):

	WinFlopWeight = None
	LoseFlopWeight = None

	WinGroups = set()
	LoseGroups = set()

	FlopShowWeights = {} # {group: WeightRandomObject}

	@classmethod
	def classInit(cls):
		cls.WinFlopWeight = None
		cls.LoseFlopWeight = None
		cls.WinGroups = set()
		cls.LoseGroups = set()
		cls.FlopShowWeights = {}

		winWeights = []
		loseWeights = []
		showWeights = defaultdict(list)

		for idx in csv.pwflop_award:
			cfg = csv.pwflop_award[idx]
			flag = cfg.group[0]
			if flag == 'W':
				cls.WinGroups.add(cfg.group)
				winWeights.append((idx, cfg.weight))
			elif flag == 'L':
				cls.LoseGroups.add(cfg.group)
				loseWeights.append((idx, cfg.weight))
			showWeights[cfg.group].append((idx, cfg.showWeight))
		cls.WinFlopWeight = WeightRandomObject(winWeights)
		cls.LoseFlopWeight = WeightRandomObject(loseWeights)
		for k, weights in showWeights.iteritems():
			cls.FlopShowWeights[k] = WeightRandomObject(weights)

	@classmethod
	def flop(cls, iswin):
		if iswin:
			weightObj = cls.WinFlopWeight
			groups = cls.WinGroups
		else:
			weightObj = cls.LoseFlopWeight
			groups = cls.LoseGroups
		idx, _ = weightObj.getRandom()
		others = groups - set([csv.pwflop_award[idx].group])
		others = [cls.FlopShowWeights[o].getRandom()[0] for o in others]
		return {
			'award': csv.pwflop_award[idx].award,
			'show': [csv.pwflop_award[i].award for i in others],
		}

#
# ObjectRandomTowerAwardRange
#

class ObjectRandomTowerAwardRange(ObjectPWAwardRange):
	CSVName = ('random_tower', 'rank_award')
	RangeL = []

	def __init__(self, cfg):
		ObjectCSVRange.__init__(self, cfg)
		self._periodAward = cfg.periodAward

	@property
	def periodAward(self):
		return self._periodAward

	@classmethod
	def getRangeLVersion(cls):
		return getRandomTowerAwardVersion()


RankCache_Limit = 50
RankCardFight_Limit = 1000
#
# ObjectRankGlobal
#

class ObjectRankGlobal(ReloadHooker):

	Singleton = None

	Fields = {
		'fight': ('fighting_point', 'top6_cards'),
		'star': ('star', ),
		'pokedex': ('pokedex',),
		'endless': ('endless', 'fighting_point'),
		'craft': ('craft', ),
		'random_tower': ('random_tower', ),
		'yybox': ('box_point',),
		'achievement': ('achievement',),
		'snowball': ('snowball',),
	}

	def __init__(self, dbc, rpcArena, serverAlias):
		self._dbc = dbc
		self._rpcArena = rpcArena
		self.serverAlias = serverAlias
		self._top50Info = {}
		self._top50Model = {} # top50 model [(id, model)]
		self._roleSlims = {} # {id: slim}
		self._inited = False

		if ObjectRankGlobal.Singleton is not None:
			raise ValueError('This is singleton object')
		ObjectRankGlobal.Singleton = self

	def _init_top50(self):
		for rankName in ('fight', 'star', 'pokedex', 'endless', 'craft', 'random_tower', 'yybox', 'achievement', 'snowball'):
			if rankName == 'yybox' and self.serverAlias:
				for gameKey in self.serverAlias:
					elements = self._dbc.call('DBGetRankSize', 'Rank_%s' % rankName, 1, RankCache_Limit, gameKey)
					self.setTopModel(rankName, elements, gameKey)
			else:
				elements = self._dbc.call('DBGetRankSize', 'Rank_%s' % rankName, 1, RankCache_Limit, '')
				self.setTopModel(rankName, elements)

	def setTopModel(self, rankName, elements, gameKey=''):
		iscardrank = rankName == 'card1fight'
		models = []
		for element in elements:
			if iscardrank:
				models.append((element['id'], element))
			else:
				self._roleSlims[element['id']] = element['role']
				models.append((element['id'], {key: element[key] for key in self.Fields[rankName]}))
		if gameKey:
			rankName = '%s_%s' % (rankName, gameKey.split('_')[-1])
		self._top50Model[rankName] = models

	def init(self):
		self._init_top50()
		self._refreshTop50('fight')
		self._refreshTop50('star')
		self._refreshTop50('pokedex')
		self._refreshTop50('endless')
		self._refreshTop50('craft')
		self._refreshTop50('random_tower')
		self._refreshTop50('achievement')
		self._refreshTop50('snowball')
		if self.serverAlias:
			for gameKey in self.serverAlias:
				self._refreshTop50('%s_%s' % ('yybox', gameKey.split('_')[-1]))
		else:
			self._refreshTop50('yybox')

		# init tiny rank
		names = ['huodong_1', 'huodong_2', 'huodong_3', 'huodong_4']
		self._tinys = {}
		for name in names:
			data = self._dbc.call('DBReadsert', 'TinyRank', {'name': name}, False)
			if not data['ret']:
				raise ServerError('db readsert TinyRank %s error' % name)
			rank = ObjectTinyRank(self._dbc)
			rank.set(data['model']).init()
			self._tinys[name] = rank

	def _refreshTop50(self, rankName):
		iscardrank = rankName == 'card1fight'
		top50 = []
		for roleID, model in self._top50Model[rankName]:
			if iscardrank:
				top50.append(model)
			else:
				slim = self._roleSlims[roleID]
				d = {
					'role': slim,
					'union_name': ObjectUnion.queryUnionName(roleID),
				}
				d.update(model)
				top50.append(d)
		self._top50Info[rankName] = top50

	@classmethod
	@coroutine
	def dayRefresh(cls):
		logger.info('rank dayRefresh')
		self = cls.Singleton

		# 活动副本小排行榜重置
		names = ['huodong_1', 'huodong_2', 'huodong_3', 'huodong_4']
		for name in names:
			self._tinys[name].clean()

		# 榜单保存，用于头衔
		from game.object.game.role import ObjectRole
		from game.object.game.servrecord import ObjectServerGlobalRecord
		maxRank = max(10, ObjectRole.getRankTitleMax(TitleDefs.Pokedex))
		ret = yield ObjectRankGlobal.getRankList('pokedex', 0, maxRank)
		ranks = {model['role']['id']: i for i, model in enumerate(ret, 1)}
		ObjectServerGlobalRecord.saveTitleRanks(TitleDefs.Pokedex, ranks)

		maxRank = max(10, ObjectRole.getRankTitleMax(TitleDefs.StarRank))
		ret = yield ObjectRankGlobal.getRankList('star', 0, maxRank)
		ranks = {model['role']['id']: i for i, model in enumerate(ret, 1)}
		ObjectServerGlobalRecord.saveTitleRanks(TitleDefs.StarRank, ranks)

		# 发试炼排行奖励
		from game.mailqueue import MailJoinableQueue
		from game.handler.inl_mail import getRankRandomTowerAwardMail

		ret = yield self._dbc.call_async('DBGetRankSize', 'Rank_random_tower', 1, 999999, '')
		randonTowerRanks = {model['role']['id']: i for i, model in enumerate(ret, 1)}
		for roleID, rank in randonTowerRanks.iteritems():
			mail = getRankRandomTowerAwardMail(roleID, rank)
			if mail:
				MailJoinableQueue.send(mail)

		self.rankClear('random_tower')

	@classmethod
	@coroutine
	def rankClear(cls, key):
		logger.info('rank:%s clear'%key)
		self = cls.Singleton
		self._top50Info[key] = []
		yield self._dbc.call_async('DBDrop','Rank_%s'%key) #清空

	@classmethod
	@coroutine
	def yyboxRefresh(cls):
		logger.info('rank yybox refresh')
		self = cls.Singleton
		for key in self._top50Info.keys():
			if 'yybox' in key:
				self._top50Info[key] = []
		yield self._dbc.call_async('DBDrop','Rank_yybox') #清空

	@classmethod
	@coroutine
	def queryRank(cls, rankName, key, withInfo=False, tied=False, gameKey=''):
		# withInfo 原始数据信息
		# tied 并列排名
		self = cls.Singleton
		if rankName in self._tinys:
			ret = self._tinys[rankName].query(key)
		else:
			gameKey = gameKey if rankName == 'yybox' and self.serverAlias else ''
			ret = yield self._dbc.call_async('DBRank', 'Rank_%s'%rankName, key, tied, gameKey)
		if withInfo:
			raise Return(ret)
		raise Return(ret[0])

	@classmethod
	@coroutine
	def queryScore(cls, rankName, key):
		# TODO: check
		self = cls.Singleton
		ret = yield self._dbc.call_async('DBRedisZScore', 'Rank_%s'%rankName,key)
		raise Return(ret)

	@classmethod
	@coroutine
	def queryRankRoleInfo(cls, roleID):
		raise Exception('deprecated')

	@classmethod
	@coroutine
	def queryRankCardInfo(cls, cardID):
		self = cls.Singleton
		if cardID in self.card_models:
			raise Return(self.card_models[cardID])
		else:
			ret = yield self._dbc.call_async('DBReadSlimCards', [cardID])
			if not ret['ret']:
				raise Return(False)
			raise Return(ret['models'][0])

	@classmethod
	@coroutine
	def getRankList(cls, key, offest, size, gameKey=''):
		if offest + size > RankCardFight_Limit:
			raise Return([])

		self = cls.Singleton
		if key in self._tinys:
			raise Return(self._tinys[key].ranks[offest:offest + size])
		if offest + size <= RankCache_Limit:
			if key == 'yybox' and self.serverAlias:
				raise Return(self._top50Info['%s_%s' % ('yybox', gameKey.split('_')[-1])][offest:offest + size])
			else:
				raise Return(self._top50Info[key][offest:offest + size])
		elif key == 'pvp':
			# 只能请求前50
			raise Return([])
		else:
			gameKey = gameKey if key == 'yybox' and self.serverAlias and gameKey else ''
			ret = yield self._dbc.call_async('DBGetRankSize', 'Rank_' + key, offest + 1, offest + size, gameKey)
			if key != 'card1fight':
				for model in ret:
					model['union_name'] = ObjectUnion.queryUnionName(model['id'])
			raise Return(ret)

	@classmethod
	@coroutine
	def onClearRoleRank(cls, roleID):
		self = cls.Singleton
		keys = ['endless', 'pokedex', 'fight', 'star'] # endless, fight 要一起清理，endless会用到fight里的战力来显示
		yield self._dbc.call_async('DBRankClearRole', roleID, ['Rank_%s' % k for k in keys])
		for key in keys:
			elements = yield self._dbc.call_async('DBGetRankSize', 'Rank_%s' % key, 1, RankCache_Limit, '')
			self.setTopModel(key, elements)
			self._refreshTop50(key)

	@classmethod
	@coroutine
	def onKeyInfoChange(cls, game, key, args=None):
		self = cls.Singleton
		rank = None
		refresh = False # force refresh
		if key == 'pokedex':
			model = {
				'role': game.role.rankRoleModel,
				'pokedex': len(game.role.pokedex),
			}
			rank = yield self._dbc.call_async('DBRankRoleAdd', 'Rank_pokedex', game.role.id, model, '')
			if rank != game.role.cardNum_rank:
				game.role.cardNum_rank = rank

		elif key == 'star':
			model = {
				'role': game.role.rankRoleModel,
				'star': game.role.gateStarSum,
			}
			rank = yield self._dbc.call_async('DBRankRoleAdd', 'Rank_star', game.role.id, model, '')
			if rank != game.role.gate_star_rank:
				game.role.gate_star_rank = rank

		elif key == 'fight':
			top6 = []
			for cardID, card_id, skin_id in game.role.top12_cards[:6]:
				d = {'card_id': card_id, 'skin_id': skin_id, 'level': 0}
				if cardID:
					card = game.cards.getCard(cardID)
					d['level'] = card.level
				top6.append(d)
			model = {
				'role': game.role.rankRoleModel,
				'fighting_point': game.role.top6_fighting_point,
				'top6_cards': top6,
			}
			rank = yield self._dbc.call_async('DBRankRoleAdd', 'Rank_fight', game.role.id, model, '')
			if rank != game.role.fight_rank:
				game.role.fight_rank = rank

		elif key.startswith('huodong_'): # 活动副本小排行榜
			self._tinys[key].update(game, args)

		elif key == 'endless':
			model = {
				'role': game.role.rankRoleModel,
				'endless': game.role.endless_tower_max_gate,
			}
			if game.role.endless_tower_max_gate > 0:
				rank = yield self._dbc.call_async('DBRankRoleAdd', 'Rank_endless', game.role.id, model, '')
				if rank != game.role.endless_rank:
					game.role.endless_rank = rank

		elif key == 'random_tower':
			model = {
				'role': game.role.rankRoleModel,
				'random_tower': {
					'day_point': game.randomTower.day_point,
					'room': game.randomTower.room,
				},
			}
			if game.randomTower.day_point > 0:
				rank = yield self._dbc.call_async('DBRankRoleAdd', 'Rank_random_tower', game.role.id, model, '')

		elif key == 'achievement':
			model = {
				'role': game.role.rankRoleModel,
				'achievement': game.achievement.allAchievementPoints,
			}
			if game.achievement.allAchievementPoints > 0:
				rank = yield self._dbc.call_async('DBRankRoleAdd', 'Rank_achievement', game.role.id, model, '')
				if rank != game.role.achievement_rank:
					game.role.achievement_rank = rank

		elif key == 'craft':
			models = {}
			for roleID, t in args.iteritems():
				round, win, point = t
				models[roleID] = {
					'craft': {
						'round': round,
						'win': win,
						'point': point,
					}
				}
			succeed = yield self._dbc.call_async('DBRankRoleAddBulk', 'Rank_craft', models)
			if len(models) != succeed:
				logger.warning('DBRankRoleAddBulk %s total %d succeed %d', 'Rank_craft', len(models), succeed)
			refresh = True

		elif key == 'card1fight':  # 需要优化，如果fightChangeCards数量多，会导致速度很慢
			maxrank = 199999999
			cards = list(game.cards.fightChangeCards) # may be changed during iteration
			game.cards.fightChangeCards.clear()
			# for card in cards:
			# 	rank = yield self._dbc.call_async('DBRankCardAdd', 'Rank_card1fight', card.id, card.rankModel)
			# 	if rank < maxrank: # 排名越小 即越大
			# 		maxrank = rank
			# rank = maxrank
			# if rank != game.role.card1fight_rank:
			# 	game.role.card1fight_rank = rank

		elif key == 'yybox':
			record = args
			model = {
				'role': game.role.rankRoleModel,
				'box_point': record.get('box_point', 0),
				'game_key': game.role.areaKey,
			}
			gameKey = game.role.areaKey if key == 'yybox' and self.serverAlias else ''
			rank = yield self._dbc.call_async('DBRankRoleAdd', 'Rank_yybox', game.role.id, model, gameKey)
			recordInfo = record.setdefault('info', {})
			if rank != recordInfo.get('rank', 0):
				recordInfo['rank'] = rank
			refresh = True
		elif key == 'snowball':
			info = args
			model = {
				'role': game.role.rankRoleModel,
				'snowball': {
					'point': info.get('top_point', 0),
					'time': info.get('top_time', 0),
					'role': info.get('top_role', 0),
				}
			}
			rank = yield self._dbc.call_async('DBRankRoleAdd', 'Rank_snowball', game.role.id, model, '')
			if rank != info.get('rank', 0):
				logger.info('role uid<%s> snow ball rank from %s to %s', game.role.uid, info.get('rank', 0), rank)
				info['rank'] = rank
			refresh = True

		if refresh or (rank and rank <= RankCache_Limit):
			if key == 'yybox' and self.serverAlias:
				gameKey = game.role.areaKey
				elements = yield self._dbc.call_async('DBGetRankSize', 'Rank_%s' % key, 1, RankCache_Limit, gameKey)
				self.setTopModel(key, elements, gameKey)
				self._refreshTop50('%s_%s' % (key, gameKey.split('_')[-1]))
			else:
				elements = yield self._dbc.call_async('DBGetRankSize', 'Rank_%s' % key, 1, RankCache_Limit, '')
				self.setTopModel(key, elements, '')
				self._refreshTop50(key)


TinyRankLimit = 100

class ObjectTinyRank(ObjectDBase):
	DBModel = 'TinyRank'

	def __init__(self, dbc):
		ObjectDBase.__init__(self, None, dbc)

		self._existed = set()

	def init(self):
		if self.ranks:
			self._existed = {v['id'] for v in self.ranks}

	def update(self, game, score=0):
		role = game.role.rankRoleModel
		role['score'] = score
		role['lasttime'] = int(nowtime_t())

		if role['id'] in self._existed:
			for v in self.ranks:
				if v['id'] == role['id']:
					if role['score'] < v['score']:
						return
					v.update(role)
					break
			self.ranks.sort(key=lambda x: (x['score'], x['lasttime']), reverse=True)
		else:
			self.ranks.append(role)
			self._existed.add(role['id'])
			self.ranks.sort(key=lambda x: (x['score'], x['lasttime']), reverse=True)
			if len(self.ranks) > TinyRankLimit:
				self.ranks = self.ranks[:TinyRankLimit]

	def query(self, roleID):
		if roleID in self._existed:
			for i, role in enumerate(self.ranks, 1):
				if role['id'] == roleID:
					return i, role['score']
		return 0, 0

	def clean(self):
		self.ranks = []
		self._existed = set()

	# 排行榜名字
	name = db_property('name')
	# 排行榜
	ranks = db_property('ranks')
