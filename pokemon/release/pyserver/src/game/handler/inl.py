#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2014 YouMi Information Technology Inc.
'''

from framework import nowtime_t
from framework.csv import csv, ErrDefs
from framework.log import logger

from game import ServerError, ClientError
from game.object import UnionDefs, AchievementDefs, GemDefs, ChipDefs, CrossUnionFightDefs
from game.object.game.card import randomCharacter, randomNumericalValue
from game.object.game.gain import ObjectGainAux
from game.object.game.cross_mine import ObjectCrossMineGameGlobal

from tornado.gen import coroutine, moment, Return

import random

@coroutine
def createGemsDB(GemIDs, roleID, dbc):
	if isinstance(GemIDs, int):
		GemIDs = [GemIDs]

	gemDatas = []
	if GemIDs:
		gemDataFutures = []
		for gemID in GemIDs:
			future = dbc.call_async('DBCreate', 'RoleGem', {
				'role_db_id': roleID,
				'gem_id': gemID,
			})
			gemDataFutures.append(future)
		for future in gemDataFutures:
			gemData = yield future
			if not gemData['ret']:
				raise ServerError('db create gem error')
			gemDatas.append(gemData['model'])

	raise Return(gemDatas)

@coroutine
def createChipsDB(ChipIDs, roleID, dbc):
	if isinstance(ChipIDs, int):
		ChipIDs = [ChipIDs]

	chipDatas = []
	if ChipIDs:
		chipDataFutures = []
		for chipID in ChipIDs:
			future = dbc.call_async('DBCreate', 'RoleChip', {
				'role_db_id': roleID,
				'chip_id': chipID,
			})
			chipDataFutures.append(future)
		for future in chipDataFutures:
			chipData = yield future
			if not chipData['ret']:
				raise ServerError('db create chip error')
			chipDatas.append(chipData['model'])

	raise Return(chipDatas)

@coroutine
def createHeldItemsDB(HeldItemIDs, roleID, dbc):
	if isinstance(HeldItemIDs, int):
		HeldItemIDs = [HeldItemIDs]

	heldItemDatas = []
	if HeldItemIDs:
		heldItemDataFutures = []
		for heldItemID in HeldItemIDs:
			future = dbc.call_async('DBCreate', 'RoleHeldItem', {
				'role_db_id': roleID,
				'held_item_id': heldItemID,
			})
			heldItemDataFutures.append(future)
		for future in heldItemDataFutures:
			heldItemData = yield future
			if not heldItemData['ret']:
				raise ServerError('db create heldItem error')
			heldItemDatas.append(heldItemData['model'])

	if len(heldItemDatas) == 1:
		raise Return(heldItemDatas[0])
	raise Return(heldItemDatas)

@coroutine
def createCardsDB(cards, roleID, dbc):
	if not isinstance(cards, (list, tuple)):
		cards = [cards]

	cardDatas = []
	if cards:
		cardDataFutures = []
		for card in cards:
			cardID = card['id']
			cfg = csv.cards[cardID]
			equips = {}
			for k, v in enumerate(cfg.equipsList):
				if v not in csv.equips:
					raise ClientError('create card for equip not in csv!!')
				equips[k + 1] = {
					'equip_id': v,
					'level': 1,
					'star': 0,
					'advance': 1,
					'exp': 0,
				}
			if cfg.gender is None:
				gender = card.get('gender', None)
				if not gender:
					rnd = random.randint(0, 10000)
					gender = 1 if rnd - cfg.maleRate <= 0 else 2 # 1-?????????2-??????
			else:
				gender = cfg.gender
			star = card.get('star', cfg.star)
			character = card.get('character', randomCharacter(cfg.chaRnd))
			nvalue = card.get('nvalue', randomNumericalValue(cfg.nValueRnd))
			future = dbc.call_async('DBCreate', 'RoleCard', {
				'role_db_id': roleID,
				'card_id': cardID,
				'star': star,
				'getstar': star,
				'develop': cfg.develop,
				'equips': equips,
				'gender': gender,
				'character': character,
				'nvalue': nvalue,
			})
			cardDataFutures.append(future)

		for future in cardDataFutures:
			cardData = yield future
			if not cardData['ret']:
				raise ServerError('db create card error')
			cardDatas.append(cardData['model'])

	if len(cardDatas) == 1:
		raise Return(cardDatas[0])
	raise Return(cardDatas)

@coroutine
def effectAutoGain(eff, game, dbc, src=None, mul=None, yy_id=None):
	if eff:
		if isinstance(eff, ObjectGainAux):
			eff.imOpenRandGift2item() # ?????????????????????????????????
			if mul:
				eff *= mul

		# ObjectItemEffect??????cards??????
		if getattr(eff, 'cards', None):
			cards, _ = eff.splitCards()
			cardDatas = yield createCardsDB(cards, game.role.id, dbc)
			if not isinstance(cardDatas, list):
				cardDatas = [cardDatas]
			eff.setCardsDBL(cardDatas)

		# ?????????????????????
		if getattr(eff, 'heldItemIDs', None):
			heldItemDatas = yield createHeldItemsDB(eff.heldItemIDs, game.role.id, dbc)
			eff.setHeldItemsDBL(heldItemDatas)

		# ???????????????
		if getattr(eff, 'gemIDs', None):
			gemDatas = yield createGemsDB(eff.gemIDs, game.role.id, dbc)
			eff.setGemsDBL(gemDatas)

		# ???????????????
		if getattr(eff, 'chipIDs', None):
			chipDatas = yield createChipsDB(eff.chipIDs, game.role.id, dbc)
			eff.setChipsDBL(chipDatas)

		eff.gain(src=src,yy_id=yy_id)

		if getattr(eff, 'gemIDs', None):
			# ????????????????????????????????????RedQualityGem??????
			if src not in ["gem_exchange", ]:
				count = 0
				for csvID in eff.gemIDs:
					cfg = csv.gem.gem[csvID]
					if cfg.quality == GemDefs.RedQuality:
						count += 1
				if count > 0:
					game.achievement.onCount(AchievementDefs.RedQualityGem, count)

		if getattr(eff, 'coin13', 0) > 0:
			yield ObjectCrossMineGameGlobal.SyncCoin13(game)


@coroutine
def effectAutoCost(costEff, game, **kwargs):
	'''
	costEff: ObjectCostAux
	'''
	kwargs['inEffectAutoCost'] = True

	if costEff.coin13 > 0:
		yield ObjectCrossMineGameGlobal.SyncCoin13(game)

	errDef = kwargs.pop('errDef', 'not enough')
	if not costEff.isEnough():
		raise ClientError(errDef)
	costEff.cost(**kwargs)

	if costEff.coin13 > 0:
		yield ObjectCrossMineGameGlobal.SyncCoin13(game)


@coroutine
def battleCardsAutoDeployment(cardIDs, game, **kwargs):
	# ???????????????PVE????????????
	game.role.filterHuodongCards(cardIDs)

	# ??????????????????
	game.role.filterReadyCards(cardIDs)

	# ????????????????????? ????????????
	yield arenaBattleCardAutomicDeployment(game, cardIDs, **kwargs)

	# ????????????????????? ????????????
	yield craftBattleCardAutomicDeployment(game, cardIDs, **kwargs)

	# ????????? ????????????
	yield unionFightBattleCardAutomicDeployment(game, cardIDs, **kwargs)

	# ??????????????? ????????????
	yield crossMineBattleCardAutomicDeployment(game, cardIDs, **kwargs)

	# ?????????????????? ???????????? ????????????
	valids = game.cards.deploymentForCrossOnlineFight.filter('cards', cardIDs)
	if valids:
		from game.handler._cross_online_fight import refreshCardsToCrossOnlineFight
		yield refreshCardsToCrossOnlineFight(kwargs['cross_online_fight'], game, cards=valids)

	# ?????? ????????????
	yield huntingBattleCardAutomicDeployment(game, cardIDs, **kwargs)

	# ??????????????? ????????????
	yield crossUnionFightBattleCardAutomicDeployment(game, cardIDs, **kwargs)

	# ??????????????????????????????
	game.refreshMarkMaxFight = True

@coroutine
def createNewDailyRecord(dateInt, game, dbc):
	game.role.daily_record_db_id = None
	dailyData = yield dbc.call_async('DBCreate', 'DailyRecord', {
		'role_db_id': game.role.id,
		'date': dateInt,
	})
	if not dailyData['ret']:
		raise ServerError('db create daily record error')

	raise Return(dailyData)

@coroutine
def createNewMonthlyRecord(monthInt, game, dbc):
	game.role.monthly_record_db_id = None
	monthlyData = yield dbc.call_async('DBCreate', 'MonthlyRecord', {
		'role_db_id': game.role.id,
		'month': monthInt,
	})
	if not monthlyData['ret']:
		raise ServerError('db create monthly record error')

	raise Return(monthlyData)

@coroutine
def arenaBattleCardAutomicDeployment(game, cards, **kwargs):
	# ???????????????????????????
	valids = game.cards.deploymentForArena.filter('cards', cards)
	if valids:
		from game.handler._pvp import refreshCardsToPVP
		yield refreshCardsToPVP(kwargs['arena'], game, cards=valids)

	# ?????????????????????????????????
	validsCrossArena = game.cards.deploymentForCrossArena.filter('cards', cards)
	if validsCrossArena:
		from game.handler._cross_arena import refreshCardsToCrossArena
		yield refreshCardsToCrossArena(kwargs['cross_arena'], game, cards=validsCrossArena)

	# ????????????????????????????????????????????????
	validsCrossArenaDefence = game.cards.deploymentForCrossArena.filter('defence_cards', cards)
	if validsCrossArenaDefence:
		from game.handler._cross_arena import refreshCardsToCrossArena
		yield refreshCardsToCrossArena(kwargs['cross_arena'], game, defence_cards=validsCrossArenaDefence)

@coroutine
def craftBattleCardAutomicDeployment(game, cards, **kwargs):
	# Craft ????????????????????????
	hold_cards = game.cards.deploymentForCraft.filter('cards', cards)
	if hold_cards:
		hold_cards = game.cards.fillupByTopCards(cards, hold_cards, 10)
		from game.handler._craft import refreshCardsToPVP
		yield refreshCardsToPVP(kwargs['craft'], game, hold_cards=hold_cards)
		if len(hold_cards) < 10:
			from game.object.game.craft import ObjectCraftInfoGlobal
			ObjectCraftInfoGlobal.AutoSignRoleMap.pop(game.role.id, None)

	# Cross Craft ????????????????????????
	hold_cards = game.cards.deploymentForCrossCraft.filter('cards', cards)
	if hold_cards:
		hold_cards = game.cards.fillupByTopCards(cards, hold_cards, 12)
		from game.handler._cross_craft import refreshCardsToPVP
		yield refreshCardsToPVP(kwargs['cross_craft'], game, hold_cards=hold_cards)
		if len(hold_cards) < 12:
			from game.object.game.cross_craft import ObjectCrossCraftGameGlobal
			ObjectCrossCraftGameGlobal.AutoSignRoleMap.pop(game.role.id, None)

@coroutine
def unionFightBattleCardAutomicDeployment(game, cards, **kwargs):
	from game.object.game.union_fight import ObjectUnionFightGlobal

	newNatures = kwargs.get('newNatures', None)
	if newNatures and len(cards) != 1:
		raise ClientError('nature check cards num %s error' % len(cards))

	deployment = game.cards.deploymentForUnionFight
	wt = {2: 2, 3: 2, 4: 2, 5: 2, 6: 3}
	delCardIDs = {}
	for weekday, troopsNum in wt.iteritems():
		# ????????????
		if newNatures:
			# ?????????????????????
			weekdayLimit = ObjectUnionFightGlobal.WeekNatureLimit.get(weekday, [])
			if not weekdayLimit:
				continue

			# ??????????????????
			inDeployment = False
			for troopIdx in xrange(1, troopsNum + 1):
				if cards[0] in deployment.cards.get((weekday, troopIdx), []):
					inDeployment = True
					break

			if not inDeployment:
				continue

			if not set(newNatures) & set(weekdayLimit):
				delCardIDs[weekday] = cards
		else:

			# ?????????????????????????????????????????????????????????
			delCardIDs[weekday] = cards

	if not delCardIDs:
		raise Return(None)

	deployCards = {}
	newAutoDeploy, _ = game.cards.makeUnionFightCardInfo(delCardIDs)
	for weekday, troopsNum in wt.iteritems():
		for troopIdx in xrange(1, troopsNum + 1):
			filterCards = delCardIDs.get(weekday, [])

			if not filterCards:
				continue

			weekCards = deployment.filter((weekday, troopIdx), cards)
			if weekCards:
				deployCards[weekday] = newAutoDeploy[weekday]

	from game.handler._union_fight import refreshUnionfCardsToPVP
	yield refreshUnionfCardsToPVP(kwargs['union_fight'], game, deployCards=deployCards)

@coroutine
def crossMineBattleCardAutomicDeployment(game, cards, **kwargs):
	# ?????????????????????????????????
	validsCrossMine = game.cards.deploymentForCrossMine.filter('cards', cards)
	if validsCrossMine:
		from game.handler._cross_mine import refreshCardsToCrossMine
		yield refreshCardsToCrossMine(kwargs['cross_mine'], game, cards=validsCrossMine)

	# ?????????????????????????????????
	validsCrossMineDefence = game.cards.deploymentForCrossMine.filter('defence_cards', cards)
	if validsCrossMineDefence:
		from game.handler._cross_mine import refreshCardsToCrossMine
		yield refreshCardsToCrossMine(kwargs['cross_mine'], game, defence_cards=validsCrossMineDefence)

@coroutine
def battleCardsAutoDeploymentByNatureCheck(game, cardID, oldNatures, newNatures, **kwargs):
	if set(oldNatures) == set(newNatures):
		raise Return(None)

	kwargs['newNatures'] = newNatures

	# ????????? ??????????????????????????????
	yield unionFightBattleCardAutomicDeployment(game, [cardID], **kwargs)


@coroutine
def huntingBattleCardAutomicDeployment(game, cards, **kwargs):
	if game.role.hunting_record_db_id:
		# ????????????????????????
		yield kwargs['hunting'].call_async('RefreshHuntingCards', game.role.hunting_record_db_id, cards)
		game.role.huntingSync = 0  # ??????????????????0


@coroutine
def crossUnionFightBattleCardAutomicDeployment(game, cards, **kwargs):
	# Cross Union Fight ????????????????????????
	if game.role.cross_union_fight_record_db_id:
		for stage in [CrossUnionFightDefs.PreStage, CrossUnionFightDefs.TopStage]:
			for project in [CrossUnionFightDefs.BattleSix, CrossUnionFightDefs.BattleFour, CrossUnionFightDefs.BattleOne]:
				nCards = game.cards.deploymentForCrossUnionFight.filter((stage, project), cards)
				if nCards:
					from game.handler._cross_union_fight import refreshToCrossUnionFight
					if stage == CrossUnionFightDefs.PreStage:
						yield refreshToCrossUnionFight(game, kwargs['cross_union_fight'], deployCards=nCards, project=project)
					else:
						yield refreshToCrossUnionFight(game, kwargs['cross_union_fight'], topCards=nCards, project=project)

