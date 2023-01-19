#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2014 YouMi Information Technology Inc.
'''

from framework.csv import csv
from framework.log import logger
from tornado.gen import moment, Return, coroutine

import random

# 构造机器人
@coroutine
def makeRobot(roleID, cardCsvIDs, advance, star, level, skillLevel, fightingPoint, **kwargs):
	from framework.helper import randomRobotName
	from game.object.game.card import ObjectCard, randomCharacter, randomNumericalValue

	fakeCard = ObjectCard(None, None)
	fakeCard.new_deepcopy()  # just for delete dbc

	name = kwargs.get('name', None)
	if not name:
		name = randomRobotName()
	fightingPoint = fightingPoint / len(cardCsvIDs) # 单卡战力

	# make card
	roleCards = []
	roleCardAttrs = {}
	num = min(len(cardCsvIDs), 12)
	for i in xrange(1, num+1):
		cardCsvID = cardCsvIDs[i-1]
		cardCfg = csv.cards[cardCsvID]

		skills = {}
		skill_level = []
		for skillID in csv.cards[cardCsvID].skillList:
			skill_level.append(skillLevel)
			skills[skillID] = skillLevel
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
		cardID = 'card-%07d' % i
		fakeCard.set({
			'id': cardID,
			'role_db_id': roleID,
			'card_id': cardCsvID,
			'skin_id': 0,
			'advance': advance,
			'star': star,
			'develop': cardCfg.develop,
			'level': level,
			'character': randomCharacter(cardCfg.chaRnd),
			'nvalue': randomNumericalValue(cardCfg.nValueRnd),
			'skills': skills,
			'skill_level': skill_level,
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
		attrs['fighting_point'] = ObjectCard.calcFightingPoint(fakeCard, attrs['attrs'])

		# 战力差 = 基准战力 - 实际总战力
		subfight = fightingPoint - attrs['fighting_point']
		if subfight > 0:
			hpWeight = 20
			damageWeight = 4
			defenceWeight = 1
			specialDamageWeight = 4
			specialDefenceWeight = 1
			speedWeight = 0
			# 根据战力差 修正
			cfg = csv.fighting_weight[cardCfg.fightingWeight]
			l_fight = hpWeight*cfg.hp + damageWeight*cfg.damage + defenceWeight*cfg.defence + specialDamageWeight*cfg.specialDamage + specialDefenceWeight*cfg.specialDefence + speedWeight*cfg.speed
			once_rate = subfight*1.0 / l_fight
			attrs['attrs']['hp'] += once_rate*hpWeight
			attrs['attrs']['damage'] += once_rate*damageWeight
			attrs['attrs']['defence'] += once_rate*defenceWeight
			attrs['attrs']['specialDamage'] += once_rate * specialDamageWeight
			attrs['attrs']['specialDefence'] += once_rate * specialDefenceWeight
			attrs['attrs']['speed'] += once_rate * speedWeight

		# 强制修正
		attrs['attrs']['hp'] *= kwargs.get('hpC', 1)
		attrs['attrs']['damage'] *= kwargs.get('damageC', 1)
		attrs['attrs']['defence'] *= kwargs.get('defenceC', 1)
		attrs['attrs']['specialDamage'] *= kwargs.get('specialDamageC', 1)
		attrs['attrs']['specialDefence'] *= kwargs.get('specialDefenceC', 1)
		attrs['attrs']['speed'] *= kwargs.get('speedC', 1)
		attrs['fighting_point'] = ObjectCard.calcFightingPoint(fakeCard, attrs['attrs'])

		roleCardAttrs[cardID] = attrs
		yield moment

	# make role
	robot = {
		'id': roleID,
		'name': name,
		'level': level,  # 用怪物等级
		'logo': random.randint(1, 2),
		'frame': 1,
		'figure': random.choice([1, 2, 3, 7, 27]),
		'vip': 0,

		'cards': roleCards,
		'card_attrs': roleCardAttrs,

		'defence_cards': roleCards,
		'defence_card_attrs': roleCardAttrs,
	}

	raise Return(robot)

def setRobotCard(card, cardId, advance, star, level, **kwargs):
	from game.object.game.card import randomCharacter, randomNumericalValue
	cfg = csv.cards[cardId]

	character = kwargs.get('character', None)
	if character is None:
		character = randomCharacter(cfg.chaRnd)
	nvalue = kwargs.get('nvalue', None)
	if not nvalue:
		nvalue =randomNumericalValue(cfg.nValueRnd)
	abilities = kwargs.get('abilities', {})

	skills = {}
	skill_level = []
	skillLevels = kwargs.get('skillLevels', None)
	least = min(len(skillLevels), len(cfg.skillList))
	for i in xrange(least):
		skillID = cfg.skillList[i]
		skills[skillID] = skillLevels[i]
		skill_level.append(skillLevels[i])
	for skillID in cfg.skillList:
		if skillID not in skills:
			skills[skillID] = 1
			skill_level.append(1)
			logger.info('card %d skill %d', cardId, skillID)

	equips = {}
	equipStar = kwargs.get('equipStar', 0)
	equipLevel = kwargs.get('equipLevel', 1)
	equipAwake = kwargs.get('equipAwake', 0)
	equipAdvance = kwargs.get('equipAdvance', 1)
	for i, v in enumerate(cfg.equipsList):
		if v not in csv.equips:
			equips = None
			break
		equips[i + 1] = {
			'equip_id': v,
			'level': equipLevel,
			'star': equipStar,
			'advance': equipAdvance,
			'exp': 0,
			'awake': equipAwake,
		}

	cardID = 'card-%07d' % cardId
	card.set({
		'id': cardID,
		'role_db_id': None,
		'card_id': cardId,
		'skin_id': 0,
		'advance': advance,
		'star': star,
		'develop': cfg.develop,
		'level': level,
		'character': character,
		'nvalue': nvalue,
		'skills': skills,
		'skill_level': skill_level,
		'effort_values': {},
		'effort_advance': 1,
		'equips': equips,
		'fighting_point': 0,
		'held_item': None,
		'abilities': abilities,
		'zawake_skills': [],
	}).initRobot()
