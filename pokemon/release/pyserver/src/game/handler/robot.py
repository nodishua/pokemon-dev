#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2014 YouMi Information Technology Inc.
'''

from framework.csv import csv, L10nDefs
from framework.log import logger
from framework.helper import lowerBound, upperBound, WeightRandomObject, objectid2string
from framework.name import robotNames, robotMiddles, robotPrefixs
from game import ServerError
from game.globaldata import RobotIDStart
from game.handler.inl import createCardsDB
from game.handler._pvp import refreshCardsToPVP
from game.object import SceneDefs

from collections import namedtuple
from tornado.gen import coroutine, moment, Return

import os
import copy
import random
import binascii

RobotCSV = namedtuple('RobotCSV', ['rank', 'levelRange', 'level', 'name', 'logo'])
RobotTeamCSV = namedtuple('RobotTeamCSV', ['randomWeight', 'cards'])
RobotCardCSV = namedtuple('RobotCardCSV', ['star', 'skillLevels'])


def nextNameGen():
	for p in robotPrefixs:
		for m in robotMiddles:
			for n in robotNames:
				yield p + m + n
	for p in robotPrefixs:
		for m in robotMiddles:
			for n in robotNames:
				for i in xrange(10):
					yield p + m + n + str(i)

@coroutine
def createRobots(rpc, dbc):
	import time
	from game.session import Session
	from game.object.game import ObjectGame

	st = time.time()

	# robot.csv
	robotCSVs = []
	for idx in csv.server.robot:
		cfg = csv.server.robot[idx]
		robotCSVs.append(RobotCSV(cfg.rank, cfg.levelRange, cfg.level, cfg.name, cfg.logo))
	robotCSVs.sort(key=lambda x: x.rank)

	if len(robotCSVs) == 0:
		raise Return((0, 0, 0))

	# robot_lib.csv
	robotTeams = {}
	for idx in csv.server.robot_lib:
		cfg = csv.server.robot_lib[idx]
		cardMarkIDS = set()
		team = RobotTeamCSV(cfg.randomWeight, {})
		for i in xrange(6):
			card = cfg['card%d' % (i+1)]
			if not card:
				break
			cardID = card['id']
			if cardID not in csv.cards:
				logger.warning('robot_lib ID=%d cardID=%d not existed', idx, cardID)
				continue
			cardMarkID = csv.cards[cardID].cardMarkID
			if cardMarkID in cardMarkIDS:
				logger.warning('robot_lib ID=%d cardID=%d duplicated', idx, cardID)
				continue
			cardMarkIDS.add(cardMarkID)
			skills = copy.deepcopy(cfg['skillMap%d' % (i+1)])
			team.cards[cardID] = RobotCardCSV(card.get('star', 1), skills)
		robotTeams.setdefault(cfg.level, []).append(team)

	levels = robotTeams.keys()
	robotTeamLevels = []
	for level in levels:
		randomObj = WeightRandomObject(robotTeams[level], lambda t: t.randomWeight)
		robotTeamLevels.append((level, randomObj))
	robotTeamLevels.sort(key=lambda t: t[0])

	print 'robotTeamLevels', robotTeamLevels

	# get robot rank
	ret = yield rpc.call_async('GetRankRange', 1, robotCSVs[-1].rank)
	robotRanks, rankMax = ret['ranks'], ret['rank_max']
	robotRoleModels = yield dbc.call_async('RoleGetRobots', [x[1] for x in robotRanks])
	robotRoleModels = {x['id']:x for x in robotRoleModels['models']}
	print 'robotRoleModels', len(robotRoleModels)
	print 'rankMax', rankMax

	elapset = time.time() - st
	logger.info('createRobots init cost %f s', elapset)

	# _gen = nextNameGen()
	# names = []
	# for i in xrange(robotCSVs[-1].rank + 10):
	# 	names.append(_gen.next())
	# random.shuffle(names)
	# _gen = iter(names)
	# nextName = lambda: _gen.next()

	st = time.time()
	genCount = [0]
	discardCards = []
	# robotName = '竞技先锋训练家'
	robotName = L10nDefs.RobotName

	@coroutine
	def _genRobot(cfg, rank, rr=None):
		if rr is None:
			account_id = 'robot-%06d' % rank
		else:
			roleID, pvpRecordID = rr

		level = random.randint(*cfg.level)
		logo = random.randint(*cfg.logo)
		cardLevel = random.randint(*cfg.levelRange)

		game = ObjectGame(dbc, lambda: None)
		game.disableModelWatch = True

		# role
		if rr is None:
			# print 'roleAdd', rank, account_id
			roleData = yield dbc.call_async('RoleAdd', {
				'account_id': account_id,
				'logo': logo,
				'level': level,
				'figure': 1,
			})
			if not roleData['ret']:
				roleData = yield dbc.call_async('RoleGet', {
					'account_id': account_id
				})
				# print 'RoleGet', account_id
				if not roleData['ret']:
					logger.warning('create robot role error, %s', roleData)
					raise Return(None)
			roleData = roleData['model']

		else:
			roleData = robotRoleModels[roleID]

		game.role.set(roleData)
		role = game.role

		if role.level != level:
			role.db['level'] = level # no rank
		if role.logo != logo:
			role.logo = logo

		# cards
		idx = upperBound(robotTeamLevels, cardLevel, key=lambda t: t[0])
		if idx >= len(robotTeamLevels):
			raise Return(None)
		teamLevel, randomObj = robotTeamLevels[idx]
		if teamLevel not in robotTeams:
			raise Return(None)

		team = randomObj.getRandom()

		# delete old cards
		discardCards.extend(role.cards)

		cards = [{'id': k, 'star': v.star} for k, v in team.cards.iteritems()]
		cardDatas = yield createCardsDB(cards, role.id, dbc)
		game.cards.set(cardDatas)

		# init
		game.role.initRobot()
		game.cards.init()
		role.cards = game.cards.getDBIDs()

		# cards skill level
		cardObjs = game.cards.getAllCards()
		cardDBIDs = []
		for _, card in cardObjs.iteritems():
			cardDBIDs.append(card.id)
			card.level = cardLevel
			card.skills.update(team.cards[card.card_id].skillLevels)
		# print 'game.role.cards', game.role.cards

		# PVPRecord
		if len(cardDBIDs) < 6:
			cardDBIDs.extend([None] * (6-len(cardDBIDs)))
		role.battle_cards = cardDBIDs[:6]
		# print 'battle_cards', game.role.battle_cards

		# PVPRecord
		if role.pvp_record_db_id is None:
			cards = game.role.battle_cards
			cardsD, _ = game.cards.makeBattleCardModel(cards, SceneDefs.Arena)

			dbID = max(cardsD, key=lambda x: cardsD[x]['fighting_point'])
			display = cardsD[dbID]['skin_id']
			if not display:
				display = cardsD[dbID]['card_id']

			fightingPoint = 0
			for _, model in cardsD.iteritems():
				fightingPoint += model['fighting_point']

			embattle = {
				'cards': cards,
				'defence_cards': cards,
				'card_attrs': cardsD,
				'defence_card_attrs': cardsD,
			}
			competitor = role.competitor
			competitor['name'] = robotName
			role.pvp_record_db_id = yield rpc.call_async('CreateArenaRecord', competitor, embattle, fightingPoint, display, True)
		else:
			yield refreshCardsToPVP(rpc, game, cards=role.battle_cards, defence_cards=role.battle_cards, force=True)

		# print 'rank', rank, 'roleID', objectid2string(role.id), 'pvpID', objectid2string(role.pvp_record_db_id)
		logger.info('rank %d roleID %s pvpID %s level %d %d', rank, objectid2string(role.id), objectid2string(role.pvp_record_db_id), level, cardLevel)

		# print 'pvp_record_db_id', game.role.pvp_record_db_id

		# save async
		genCount[0] += 1
		# game.role.save_async()
		# game.equips.save_async()
		# game.cards.save_async()

	# 1. rename all existed robot
	# for rrr in robotRanks:
	# 	rank, roleID, recordID = rrr
	# 	if roleID not in robotRoleModels:
	# 		continue
	# 	game = ObjectGame(dbc, lambda: None)
	# 	roleData = robotRoleModels[roleID]
	# 	game.role.set(roleData)
	# 	game.role.initRobot()
	# 	game.role.name = '%dr%d' % (int(time.time()), game.role.uid)
	# 	yield game.role.save_async()
	# yield Session.server.dbQueue.join()
	# elapset = time.time() - st
	# logger.info('rename all robot over, cost %fs', elapset)
	# st = time.time()

	# 2. gen existed robot
	for rrr in robotRanks:
		rank, roleID, recordID = rrr
		if roleID not in robotRoleModels:
			continue
		lowIdx = lowerBound(robotCSVs, rank-1, lambda x: x.rank)
		if lowIdx + 1 >= len(robotCSVs):
			break
		yield _genRobot(robotCSVs[lowIdx + 1], rank, (roleID, recordID))

	# 3. gen new robot
	lowIdx = lowerBound(robotCSVs, rankMax, lambda x: x.rank)
	robotCSVs = robotCSVs[lowIdx + 1:]
	if robotCSVs:
		ranks = [] # [(rank, cfg)]
		for cfg in robotCSVs:
			for rank in xrange(rankMax+1, cfg.rank+1):
				ranks.append((rank, cfg))
			rankMax = cfg.rank
		for rank, cfg in ranks:
			yield _genRobot(cfg, rank)

	elapset = time.time() - st
	logger.info('createRobots %d cost %f s %f op/s', genCount[0], elapset, genCount[0]/elapset)
	st = time.time()

	yield Session.server.dbQueue.join()
	yield rpc.call_async('Flush')
	if discardCards:
		for cardID in discardCards:
			yield dbc.call_async('DBDelete', 'RoleCard', cardID, False)
	yield dbc.call_async('DBCommit', True, True)

	logger.info('createRobots clean cost %f s', time.time() - st)

	raise Return((rankMax, genCount[0], elapset))
