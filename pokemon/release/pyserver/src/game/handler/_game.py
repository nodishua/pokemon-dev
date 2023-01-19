#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2014 YouMi Information Technology Inc.

Game Handlers
'''
from framework import nowdatetime_t, int2datetime, nowtime_t, todayinclock5date2int, is_qq_channel,period2date, date2int, nowtime2period, datetime2timestamp, is_none, todayinclock5elapsedays
from framework.log import logger
from framework.csv import csv, ErrDefs, ConstDefs
from framework.helper import toUTF8Dict, getL10nCsvValue, transform2list
from framework.distributed.helper import multi_future
from framework.word_filter import filterName

from game import ServerError, ClientError
from game import globaldata
from game.globaldata import NightmareHuodongID, UnionFubenHuodongID, ShopRefreshPeriods, ShopRefreshItem
from game.handler.task import RequestHandlerTask
from game.handler.inl import createCardsDB, createNewDailyRecord, createNewMonthlyRecord
from game.handler.inl import effectAutoGain
from game.handler.inl_mail import sendRankPeriodAwardMail, sendMail
from game.handler._pvp import refreshCardsToPVP, makeBattleModel
from game.handler._cross_online_fight import refreshCardsToCrossOnlineFight
from game.object import MailDefs, YYHuoDongDefs, MapDefs, TitleDefs, TargetDefs, UnionDefs, SceneDefs, FeatureDefs, AchievementDefs, MessageDefs, CrossArenaDefs, ReunionDefs, PlayPassportDefs, CrossUnionFightDefs
from game.object.game import ObjectFeatureUnlockCSV, ObjectGymGameGlobal, ObjectReunionRecord
from game.object.game.cross_arena import ObjectCrossArenaGameGlobal
from game.object.game.cross_union_fight import ObjectCrossUnionFightGameGlobal
from game.object.game.gain import ObjectCostAux, ObjectGainAux
from game.object.game.wmap import ObjectMap
from game.object.game.role import ObjectRole
from game.object.game.battle import ObjectGateBattle, ObjectGateSaoDang
from game.object.game.shop import ObjectUnionShop, ObjectFixShop, ObjectMysteryShop, ObjectExplorerShop, ObjectFragShop, ObjectEquipShop, ObjectRandomTowerShop, ObjectFishingShop
from game.object.game.yyhuodong import ObjectYYHuoDongFactory, ObjectYYReunion, ObjectYYHuoDongBoss
from game.object.game.gift import ObjectGift
from game.object.game.mail import ObjectMailGlobal
from game.object.game.rank import ObjectRankGlobal
from game.object.game.union import ObjectUnion
from game.object.game.costcsv import ObjectCostCSV
from game.object.game.society import ObjectSocietyGlobal
from game.object.game.servrecord import ObjectServerGlobalRecord
from game.object.game.monstercsv import ObjectMonsterCSV
from game.object.game.craft import ObjectCraftInfoGlobal
from game.object.game.message import ObjectMessageGlobal
from game.object.game.union_fight import ObjectUnionFightGlobal
from game.object.game.cross_craft import ObjectCrossCraftGameGlobal
from game.object.game.cache import ObjectCacheGlobal
from game.object.game.cross_fishing import ObjectCrossFishingGameGlobal
from game.object.game.cross_mine import ObjectCrossMineGameGlobal
from game.thinkingdata import ta

from payment.sdk.qq import SDKQQ

from tornado.gen import coroutine, Return

import copy
import time
import json
import binascii
import random


# 游戏登陆
class GameLogin(RequestHandlerTask):
	url = r'/game/login'

	@coroutine
	def _run(self):
		from game.mailqueue import MailJoinableQueue

		gameLoad = self.session.gameLoad
		try:
			if not gameLoad:
				yield MailJoinableQueue.beginGameLoading()
			yield self.loading()
		except:
			raise
		finally:
			if not gameLoad:
				MailJoinableQueue.endGameLoading()

	@coroutine
	def loading(self):
		# 这些数据login时都需要判断
		dailyData = None
		monthlyData = None
		newRole = False

		# 是否在缓存中
		if not self.session.gameLoad:

			# 新登录
			query = {'account_id': self.accountID}
			query['area'] = self.gameServID
			# 为了fix时用role_id查询
			if self.accountID is None:
				query['role_id'] = self.roleID
			roleData = yield self.dbcGame.call_async('RoleGet', query)

			########################################
			# existed role
			if roleData['ret']:
				self.game.role.set(roleData['model'])

				if self.game.role.disable_flag:
					from game.session import Session
					# Session.discardSession(self.session)
					raise ClientError(ErrDefs.roleBeenDisabled)

				# read cards, heldItems
				futures = {}

				@coroutine
				def readCards():
					cardsData = yield self.dbcGame.call_async('DBMultipleRead', 'RoleCard', self.game.role.cards)
					if not cardsData['ret']:
						raise ServerError('db query cards error')
					self.game.cards.set(cardsData['models'])
				futures['cards'] = readCards()

				if self.game.role.held_items:
					@coroutine
					def readHeldItems():
						heldItemsData = yield self.dbcGame.call_async('DBMultipleRead', 'RoleHeldItem', self.game.role.held_items)
						if not heldItemsData['ret']:
							raise ServerError('db query heldItems error')
						self.game.heldItems.set(heldItemsData['models'])
					futures['heldItems'] = readHeldItems()

				if self.game.role.gems:
					@coroutine
					def readGems():
						gemsData = yield self.dbcGame.call_async('DBMultipleRead', 'RoleGem', self.game.role.gems)
						if not gemsData['ret']:
							raise ServerError('db query gems error')
						self.game.gems.set(gemsData['models'])
					futures['gems'] = readGems()

				if self.game.role.chips:
					@coroutine
					def readChips():
						chipsData = yield self.dbcGame.call_async('DBMultipleRead', 'RoleChip', self.game.role.chips)
						if not chipsData['ret']:
							raise ServerError('db query chips error')
						self.game.chips.set(chipsData['models'])
					futures['chips'] = readChips()

				yield multi_future(futures, rasie_exc=True)
			########################################
			# add newbie role
			else:
				newRole = True
				cfg = csv.newbie_init[1]

				roleData = yield self.dbcGame.call_async('RoleAdd', {
					'account_id': self.accountID,
					'area': self.gameServID,
					# 'name': self.input.get('name', randomName()), # name 在db_server那直接判重和随机
					'channel': self.input.get('channel', 'none'),
					'stamina': csv.base_attribute.role_level[1].staminaMax,
					'gold': cfg.gold,
					'rmb': cfg.rmb,
				})
				if not roleData['ret']:
					raise ServerError('db create newbie role error')
				self.game.role.set(roleData['model'])

				# newbie give award
				eff = ObjectGainAux(self.game, cfg.items)
				yield effectAutoGain(eff, self.game, self.dbcGame, src='newbie')

				# newbie give a free card
				newbieCards = filter(None, cfg.defaultCards)
				if newbieCards:
					cardDatas = yield createCardsDB(newbieCards, self.game.role.id, self.dbcGame)
					self.game.cards.addCards(cardDatas, loading=True)

				if self.servMerged: # 合服的区新建角色
					self.game.role.name = '%s.s%s' % (self.game.role.name, self.game.role.area)

			########################################
			# same logic between existed and newbie

			role = self.game.role
			futures = {}

			# DailyRecord
			@coroutine
			def fetchDailyRecord():
				if role.daily_record_db_id:
					dailyData = yield self.dbcGame.call_async('DBRead', 'DailyRecord', role.daily_record_db_id, False)
					if not dailyData['ret']:
						raise ServerError('db read daily record error')
				else:
					dailyData = yield createNewDailyRecord(todayinclock5date2int(), self.game, self.dbcGame)
					role.daily_record_db_id = dailyData['model']['id']
				self.game.dailyRecord.set(dailyData['model'])
			futures['dailyRecord'] = fetchDailyRecord()

			# MonthlyRecord
			@coroutine
			def fetchMonthlyRecord():
				if role.monthly_record_db_id:
					monthlyData = yield self.dbcGame.call_async('DBRead', 'MonthlyRecord', role.monthly_record_db_id, False)
					if not monthlyData['ret']:
						raise ServerError('db read monthly record error')
				else:
					monthlyData = yield createNewMonthlyRecord(self.MonthIntNow, self.game, self.dbcGame)
					role.monthly_record_db_id = monthlyData['model']['id']
				self.game.monthlyRecord.set(monthlyData['model'])
			futures['monthlyRecord'] = fetchMonthlyRecord()

			# LotteryRecord
			@coroutine
			def fetchLotteryRecord():
				if role.lottery_db_id:
					lotteryData = yield self.dbcGame.call_async('DBRead', 'LotteryRecord', role.lottery_db_id, False)
					if not lotteryData['ret']:
						raise ServerError('db read lottery record error')
				else:
					lotteryData = yield self.dbcGame.call_async('DBCreate', 'LotteryRecord', {
						'role_db_id': role.id,
					})
					role.lottery_db_id = lotteryData['model']['id']
				self.game.lotteryRecord.set(lotteryData['model'])
			futures['lotteryRecord'] = fetchLotteryRecord()

			# Society
			@coroutine
			def fetchSociety():
				if role.society_db_id:
					societyData = yield self.dbcGame.call_async('DBRead', 'Society', role.society_db_id, False)
					if not societyData['ret']:
						raise ServerError('db read society error')
				else:
					societyData = yield self.dbcGame.call_async('DBCreate', 'Society', {
						'role_db_id': role.id,
					})
					role.society_db_id = societyData['model']['id']
				self.game.society.set(societyData['model'])
			futures['society'] = fetchSociety()

			# capture
			@coroutine
			def fetchCapture():
				if role.capture_db_id:
					captureData = yield self.dbcGame.call_async('DBRead', 'Capture', role.capture_db_id, False)
					if not captureData['ret']:
						raise ServerError('db read capture error')
				else:
					captureData = yield self.dbcGame.call_async('DBCreate', 'Capture', {
						'role_db_id': role.id,
					})
					role.capture_db_id = captureData['model']['id']
				self.game.capture.set(captureData['model'])
			futures['capture'] = fetchCapture()

			# fishing
			@coroutine
			def fetchFishing():
				if role.fishing_db_id:
					fishingData = yield self.dbcGame.call_async('DBRead', 'Fishing', role.fishing_db_id, False)
					if not fishingData['ret']:
						raise ServerError('db read fishing error')
				else:
					fishingData = yield self.dbcGame.call_async('DBCreate', 'Fishing', {
						'role_db_id': role.id,
					})
					role.fishing_db_id = fishingData['model']['id']
				self.game.fishing.set(fishingData['model'])
			futures['fishing'] = fetchFishing()

			# FixShop
			@coroutine
			def readFixShop():
				if role.fix_shop_db_id:
					shopData = yield self.dbcGame.call_async('DBRead', 'FixShop', role.fix_shop_db_id, False)
					if not shopData['ret']:
						raise ServerError('db read fix shop error')
					self.game.fixShop.set(shopData['model'])
			futures['fixShop'] = readFixShop()

			# MysteryShop
			@coroutine
			def readMysteryShop():
				if role.mystery_shop_db_id:
					shopData = yield self.dbcGame.call_async('DBRead', 'MysteryShop', role.mystery_shop_db_id, False)
					if not shopData['ret']:
						raise ServerError('db read mystery shop error')
					self.game.mysteryShop.set(shopData['model'])
			futures['mysteryShop'] = readMysteryShop()

			# UnionShop
			@coroutine
			def readUnionShop():
				if role.union_shop_db_id:
					shopData = yield self.dbcGame.call_async('DBRead', 'UnionShop', role.union_shop_db_id, False)
					if not shopData['ret']:
						raise ServerError('db read union shop error')
					self.game.unionShop.set(shopData['model'])
			futures['unionShop'] = readUnionShop()

			# ObjectExplorerShop
			@coroutine
			def readExplorerShop():
				if role.explorer_shop_db_id:
					shopData = yield self.dbcGame.call_async('DBRead', 'ExplorerShop', role.explorer_shop_db_id, False)
					if not shopData['ret']:
						raise ServerError('db read explorer shop error')
					self.game.explorerShop.set(shopData['model'])
			futures['explorerShop'] = readExplorerShop()

			# ObjectFragShop
			@coroutine
			def readFragShop():
				if role.frag_shop_db_id:
					shopData = yield self.dbcGame.call_async('DBRead', 'FragShop', role.frag_shop_db_id, False)
					if not shopData['ret']:
						raise ServerError('db read frag shop error')
					self.game.fragShop.set(shopData['model'])
			futures['fragShop'] = readFragShop()

			# ObjectRandomTowerShop
			@coroutine
			def readRandomTowerShop():
				if role.random_tower_shop_db_id:
					shopData = yield self.dbcGame.call_async('DBRead', 'RandomTowerShop', role.random_tower_shop_db_id, False)
					if not shopData['ret']:
						raise ServerError('db read randomTower shop error')
					self.game.randomTowerShop.set(shopData['model'])
			futures['randomTowerShop'] = readRandomTowerShop()

			# ObjectEquipShop
			@coroutine
			def readEquipShop():
				if role.equip_shop_db_id:
					shopData = yield self.dbcGame.call_async('DBRead', 'EquipShop', role.equip_shop_db_id, False)
					if not shopData['ret']:
						raise ServerError('db read equip shop error')
					self.game.equipShop.set(shopData['model'])
			futures['equipShop'] = readEquipShop()

			# ObjectFishingShop
			@coroutine
			def readFishingShop():
				if role.fishing_shop_db_id:
					shopData = yield self.dbcGame.call_async('DBRead', 'FishingShop', role.fishing_shop_db_id, False)
					if not shopData['ret']:
						raise ServerError('db read fishing shop error')
					self.game.fishingShop.set(shopData['model'])
			futures['fishingShop'] = readFishingShop()

			# RandomTower
			@coroutine
			def readRandomTower():
				if role.random_tower_db_id:
					recordData = yield self.dbcGame.call_async('DBRead', 'RandomTower', role.random_tower_db_id, False)
					if not recordData['ret']:
						raise ServerError('db read randomTower record error')
					self.game.randomTower.set(recordData['model'])

			futures['randomTower'] = readRandomTower()

			# ReunionRecord
			@coroutine
			def fetchReunionRecord():
				if role.reunion_record_db_id:
					reunionData = yield self.dbcGame.call_async('DBRead', 'ReunionRecord', role.reunion_record_db_id, False)
					if not reunionData['ret']:
						raise ServerError('db read reunion error')
				else:
					reunionData = yield self.dbcGame.call_async('DBCreate', 'ReunionRecord', {
						'role_db_id': role.id,
					})
					role.reunion_record_db_id = reunionData['model']['id']
				self.game.reunionRecord.set(reunionData['model'])
			futures['reunionRecord'] = fetchReunionRecord()

			yield multi_future(futures, rasie_exc=True)

			# fetch pvp deployment
			if role.pvp_record_db_id:
				ret = yield self.rpcArena.call_async('GetArenaBattleCards', role.pvp_record_db_id)
				deployment = self.game.cards.deploymentForArena
				deployment.deploy('cards', ret['cards'])
				deployment.deploy('defence_cards', ret['defence_cards'])

			# fetch craft deployment
			if role.craft_record_db_id:
				cards = yield self.rpcCraft.call_async('GetCraftBattleCards', role.craft_record_db_id)
				deployment = self.game.cards.deploymentForCraft
				deployment.deploy('cards', cards)

			# fetch cross craft deployment
			if role.cross_craft_record_db_id:
				cards = yield self.rpcPVP.call_async('GetCrossCraftBattleCards', role.cross_craft_record_db_id)
				deployment = self.game.cards.deploymentForCrossCraft
				deployment.deploy('cards', cards)

			# fetch cross online fight deployment
			if role.cross_online_fight_record_db_id:
				cards = yield self.rpcPVP.call_async('GetCrossOnlineFightBattleCards', role.cross_online_fight_record_db_id)
				deployment = self.game.cards.deploymentForCrossOnlineFight
				deployment.deploy('cards', cards)

			# fetch union_fight deployment
			if role.union_fight_record_db_id:
				cards = yield self.rpcUnionFight.call_async('GetUnionFightBattleCards', role.union_fight_record_db_id)
				deployment = self.game.cards.deploymentForUnionFight
				for weekday, troops in cards.iteritems():
					for troopsIdx, cs in troops.iteritems():
						deployment.deploy((weekday, troopsIdx), cs)

			# fetch cross arena deployment
			if role.cross_arena_record_db_id:
				ret = yield self.rpcPVP.call_async('GetCrossArenaBattleCards', role.cross_arena_record_db_id)
				deployment = self.game.cards.deploymentForCrossArena
				deployment.deploy('cards', ret['cards'])
				deployment.deploy('defence_cards', ret['defence_cards'])

			# fetch gym deployment
			if role.gym_record_db_id:
				ret = yield self.rpcGym.call_async('GetGymBattleCards', role.gym_record_db_id)
				deployment = self.game.cards.deploymentForGym
				deployment.deploy('cards', ret['cards'])
				deployment.deploy('cross_cards', ret['cross_cards'])

			# fetch cross mine deployment
			if role.cross_mine_record_db_id:
				ret = yield self.rpcPVP.call_async('GetCrossMineBattleCards', role.cross_mine_record_db_id)
				deployment = self.game.cards.deploymentForCrossMine
				deployment.deploy('cards', ret['cards'])
				deployment.deploy('defence_cards', ret['defence_cards'])

		# 在缓存中
		else:

			role = self.game.role
			if role.disable_flag:
				from game.session import Session
				# Session.discardSession(self.session)
				raise ClientError(ErrDefs.roleBeenDisabled)

		role.huntingSync = 0
		# TODO: 修完anti-cheat问题后关闭
		role.pw_playing_db_id = None

		########################################
		# same logic between cached and newlogin

		# 收集发送上来的sdk信息
		# QQ的信息会失效，每次查询前就得重新获取
		if 'sdkinfo' in self.input:
			jstr = self.input.get('sdkinfo')
			self.game.sdkInfo = SDKQQ.parseDataTokenToGame(jstr, True)

		# 如果是QQ渠道的，先查询一把余额
		if is_qq_channel(self.game.role.channel):
			# 这里是特殊写法
			from game.server import Server
			Server.getBalanceQQRMBSync(self.game)

		# 推送给sdk游戏信息处理队列
		needIdentityAward = False
		if self.session.sdkInfo:
			needIdentityAward = self.session.sdkInfo.get('age', 0) > 0
			self.session.sdkInfo = None

		# 主动更新或刷新
		if self.game.dailyRecord.date != todayinclock5date2int():
			self.game.dailyRecord.renew()

		if self.game.monthlyRecord.month != self.MonthIntNow:
			self.game.monthlyRecord.renew()
		if role.random_tower_db_id:
			self.game.randomTower.refresh()
			self.game.randomTower.checkPointAwardVersion(False)

		# 假如商店日期已过，就清零，等打开商店界面时再构造数据
		if role.union_shop_db_id:
			if self.game.unionShop.isPast():
				role.union_shop_db_id = None
				ObjectUnionShop.addFreeObject(self.game.unionShop)
				self.game.unionShop = ObjectUnionShop(self.game, self.dbcGame)
		if role.explorer_shop_db_id:
			if self.game.explorerShop.isPast():
				role.explorer_shop_db_id = None
				ObjectExplorerShop.addFreeObject(self.game.explorerShop)
				self.game.explorerShop = ObjectExplorerShop(self.game, self.dbcGame)
		if role.frag_shop_db_id:
			if self.game.fragShop.isPast():
				role.frag_shop_db_id = None
				ObjectFragShop.addFreeObject(self.game.fragShop)
				self.game.fragShop = ObjectFragShop(self.game, self.dbcGame)
		if role.random_tower_shop_db_id:
			if self.game.randomTowerShop.isPast():
				role.random_tower_shop_db_id = None
				ObjectRandomTowerShop.addFreeObject(self.game.randomTowerShop)
				self.game.randomTowerShop = ObjectRandomTowerShop(self.game, self.dbcGame)
		if role.equip_shop_db_id:
			if self.game.equipShop.isPast():
				role.equip_shop_db_id = None
				ObjectEquipShop.addFreeObject(self.game.equipShop)
				self.game.equipShop = ObjectEquipShop(self.game, self.dbcGame)
		if role.fishing_shop_db_id:
			if self.game.fishingShop.isPast():
				role.fishing_shop_db_id = None
				ObjectFishingShop.addFreeObject(self.game.fishingShop)
				self.game.fishingShop = ObjectFishingShop(self.game, self.dbcGame)

		if role.mystery_shop_db_id is None:
			yield getMysteryShop(self.game, self.dbcGame)

		# 标记已加载
		self.session.gameLoad = True

		# 新建、重登都重新初始化
		self.game.init()

		# new craft record
		# 涉及cards逻辑计算，需要在init之后
		if role.craft_record_db_id is None and role.level >= ObjectCraftInfoGlobal.OpenLevel:
			if len(role.top_cards) >= 10:
				cards = role.top_cards[:10]
				cardsD, cardsD2 = self.game.cards.makeBattleCardModel(cards, SceneDefs.Craft)
				passiveSkills = self.game.cards.markBattlePassiveSkills(cards, SceneDefs.Craft)
				role.craft_record_db_id = yield self.rpcCraft.call_async('CreateCraftRecord', role.competitor, {'cards': cards, 'card_attrs': cardsD, 'card_attrs2': cardsD2, 'passive_skills': passiveSkills})
				deployment = self.game.cards.deploymentForCraft
				deployment.deploy('cards', cards)

		# new cross craft record
		# 涉及cards逻辑计算，需要在init之后
		if role.cross_craft_record_db_id is None and role.level >= ObjectCrossCraftGameGlobal.OpenLevel:
			if len(role.top_cards) >= 12:
				cards = role.top_cards[:12]
				cardsD, cardsD2 = self.game.cards.makeBattleCardModel(cards, SceneDefs.CrossCraft)
				passiveSkills = self.game.cards.markBattlePassiveSkills(cards, SceneDefs.CrossCraft)
				role.cross_craft_record_db_id = yield self.rpcPVP.call_async('CreateCrossCraftRecord', role.competitor, {'cards': cards, 'card_attrs': cardsD, 'card_attrs2': cardsD2, 'passive_skills': passiveSkills})
				deployment = self.game.cards.deploymentForCrossCraft
				deployment.deploy('cards', cards)

		# 公会战数据
		if role.union_fight_record_db_id is None and role.level >= ObjectUnionFightGlobal.OpenLevel:
			competitor = role.competitor
			competitor['union_db_id'] = role.union_db_id
			cards, cardIDs = self.game.cards.makeUnionFightCardInfo()
			cardsD1, cardsD2 = self.game.cards.makeBattleCardModel(cardIDs, SceneDefs.UnionFight)
			passiveSkills = self.game.cards.markBattlePassiveSkills(cardIDs, SceneDefs.UnionFight)
			role.union_fight_record_db_id = yield self.rpcUnionFight.call_async('CreateUnionFightRoleRecord', competitor, {'cards': cards, 'card_attrs': cardsD1, 'card_attrs2': cardsD2, 'passive_skills': passiveSkills})
			deployment = self.game.cards.deploymentForUnionFight
			for weekday, troops in cards.iteritems():
				for troopsIdx, cs in troops.iteritems():
					deployment.deploy((weekday, troopsIdx), cs)

		# 跨服公会战数据
		if role.cross_union_fight_record_db_id:
			cards = yield self.rpcPVP.call_async('GetCrossUnionFightBattleCards', role.cross_union_fight_record_db_id)
			deployment = self.game.cards.deploymentForCrossUnionFight
			# ty 初/决； groupID 战场
			for ty, battleCards in cards.iteritems():
				for project, gCards in battleCards.iteritems():
					# 不存在的卡自动下阵
					isNotExist = False
					for i, cardID in enumerate(gCards):
						if not self.game.cards.getCard(cardID):
							gCards[i] = None
							isNotExist = True
					if isNotExist:
						from game.handler._cross_union_fight import refreshToCrossUnionFight
						if ty == CrossUnionFightDefs.PreStage:
							yield refreshToCrossUnionFight(self.game, self.rpcPVP, deployCards=gCards, project=project)
						else:
							yield refreshToCrossUnionFight(self.game, self.rpcPVP, topCards=gCards, project=project)
					deployment.deploy((ty, project), gCards)

		if not role.cross_union_fight_record_db_id and role.level >= ObjectCrossUnionFightGameGlobal.OpenLevel and role.union_db_id:
			competitor = role.competitor
			competitor['title'] = role.title_id
			# 随机战场 (初赛/决赛一样）
			project = random.choice([1, 2, 3])
			cards, cardIDs = self.game.cards.makeCrossUnionFightCardInfo(project)
			cardsD1, cardsD2 = ObjectCrossUnionFightGameGlobal.makeCardsAttr(self.game, project, cardIDs)
			passiveSkills = self.game.cards.markBattlePassiveSkills(cardIDs, SceneDefs.CrossUnionFight)
			embattle = {
				'cards': cards,
				'card_attrs': cardsD1,
				'card_attrs2': cardsD2,
				'passive_skills': passiveSkills,
				'top_card_attrs': cardsD1,
				'top_card_attrs2': cardsD2,
				'top_passive_skills': passiveSkills,
			}
			ret = yield self.rpcPVP.call_async('CreateCrossUnionFightRoleRecord', competitor, embattle, project)
			role.cross_union_fight_record_db_id = ret['id']
			cards = ret['cards']
			deployment = self.game.cards.deploymentForCrossUnionFight
			# ty 初/决； groupID 战场
			for ty, battleCards in cards.iteritems():
				for pj, gCards in battleCards.iteritems():
					deployment.deploy((ty, pj), gCards)

		# 查询公会状态
		training = None
		if ObjectFeatureUnlockCSV.isOpen(FeatureDefs.Union, self.game) or role.union_db_id or role.union_join_que:
			ret = yield self.rpcUnion.call_async('OnLogin', role.id, role.unionMemberModel, role.union_join_que)
			role.syncUnion(ret['sync']['role'])
			self.game.cards.syncTrainingExp(ret['sync'].get('card_exp', None))
			if self.game.union:
				self.game.union.init(ret['model']['union'], ret['time'])
				if 'view' in ret:
					deployment = self.game.cards.deploymentForUnionTraining
					deployment.deploy('cards', ret['view'])

				# 公会训练营model数据
				from game.handler._union import unionCallAsync, refreshUnionTraining
				yield refreshUnionTraining(self.rpcUnion, self.game) # 同步最新的卡牌数据, 经验在OnLogin时已经取走，这里要同步下, unionCallAsync可能取不到经验
				training = yield unionCallAsync(self.rpcUnion, 'TrainingOpen', role, 0)

		# 查询元素挑战中的卡牌使用状态
		if role.clone_room_db_id or role.clone_deploy_card_db_id:
			ret = yield self.rpcClone.call_async("CloneGet", role.id)
			from game.handler._clone import updateRoleCLoneRoomInfo
			updateRoleCLoneRoomInfo(role, ret['room'], False)

		# 跨服竞技场数据 离线玩家处理
		if role.cross_arena_record_db_id:
			ObjectCrossArenaGameGlobal.onLogin(role)

		# 道馆数据 离线玩家处理
		if role.gym_record_db_id:
			ObjectGymGameGlobal.onLogin(role)

		# 跨服资源战 离线玩家处理
		if role.cross_mine_record_db_id:
			ObjectCrossMineGameGlobal.SyncCoin13(self.game)

		# 登录时间
		role.last_time = nowtime_t()

		ObjectYYHuoDongFactory.onLogin(self.game)
		ObjectYYHuoDongFactory.onTaskChange(self.game, PlayPassportDefs.Login, 1)
		if role.level > 1: # 1级可能是未完成建号流程的
			ObjectSocietyGlobal.onRoleInfo(self.game)

		ObjectCraftInfoGlobal.onRoleInfo(self.game)
		ObjectUnionFightGlobal.onRoleInfo(self.game)
		ObjectCrossCraftGameGlobal.onRoleInfo(self.game)

		# 充值缓存清理
		if role.recharges_cache:
			for t in role.recharges_cache:
				if len(t)==4: # 可能存在的更新前的老订单
					rechargeID, orderID, yyID, csvID = t
					role.buyRecharge(rechargeID, orderID, yyID, csvID)
				else:
					rechargeID, orderID, yyID, csvID, rePro = t
					role.buyRecharge(rechargeID, orderID, yyID, csvID, rePro=rePro)
			role.recharges_cache = []

		# 体力
		role.refreshStamina()
		# 技能点
		role.refreshSkillPoint()
		# 进化石转化次数恢复
		role.refreshMegaConvertTimes()
		# 在线礼包
		role.refreshOnlineGift()
		# 主城效果精灵
		role.refreshCitySprites()
		# 成就, 需要在 ObjectYYHuoDongFactory.onLogin 之后调用，运营活动会对一些数值提高上限，比如体力，技能点
		self.game.achievement.initWatchTarget()

		# refresh offline rank period award
		if role.pvp_record_db_id:
			timeRanks = yield self.rpcArena.call_async('GetOfflineRankPeriodAward', role.id)
			if timeRanks:
				timeRanks.reverse()
				for awardTime, rank in timeRanks:
					awardTime = datetime2timestamp(int2datetime(awardTime))
					yield sendRankPeriodAwardMail(self.game.role.id, self.game, rank, self.dbcGame, awardTime)
					logger.info('pvp award time %s rank %s roleID %s', awardTime, rank, binascii.hexlify(role.id))

		# recv global mail
		mailsCount = ObjectMailGlobal.countMails()
		if role.global_mail_idx < mailsCount:
			mailThumbs = ObjectMailGlobal.getMails(role.global_mail_idx)
			for thumb in mailThumbs:
				sendFlag = False
				if thumb.get('mtype', None) == MailDefs.TypeGlobal:
					sendFlag = True
				elif thumb.get('mtype', None) == MailDefs.TypeServer and thumb['time'] >= role.created_time:
					sendFlag = True
				elif thumb.get('mtype', None) == MailDefs.TypeVip and self.game.role.vip_level >= thumb['beginVip'] and self.game.role.vip_level <= thumb['endVip']:
					sendFlag = True
				if sendFlag:
					role.addMailThumb(thumb['db_id'], thumb['subject'], thumb['time'], thumb['type'], thumb['sender'], True, thumb['hasattach'])
			role.global_mail_idx = mailsCount

		# recv union mail
		if self.game.union:
			mailsCount = self.game.union.countMails()
			if role.union_mail_idx < mailsCount:
				mailThumbs = self.game.union.getMails(role.union_mail_idx)
				for thumb in mailThumbs:
					if thumb['time'] < role.union_join_time:
						continue
					role.addMailThumb(thumb['db_id'], thumb['subject'], thumb['time'], thumb['type'], thumb['sender'], True, thumb['hasattach'])
			role.union_mail_idx = mailsCount

		# 实名注册奖励邮件
		if needIdentityAward:
			mail = ObjectRole.makeMailModel(self.game.role.id, globaldata.IdentityAwardMailID)
			yield sendMail(mail, self.dbcGame, self.game)

		# recv newbie mail
		if newRole:
			# 处理钻石返还  若为空则其他区服已返还
			rmbReturn = self.session.rmbReturn
			if rmbReturn:
				vip = rmbReturn.get("vip", 0)
				rmb = rmbReturn.get("rmb", 0)
				role = self.game.role
				if rmb:
					role.setRMBWithoutRecord(rmb + role.rmb)
					role.addVIPExp(int(rmb/2))

				logger.info('roleID %s rmbReturn vip %s rmb %s', role.pid, vip, rmb)

		yield ObjectRankGlobal.onKeyInfoChange(self.game, 'fight')
		yield ObjectRankGlobal.onKeyInfoChange(self.game, 'achievement')
		# yield ObjectRankGlobal.onKeyInfoChange(self.game, 'pokedex')
		# yield ObjectRankGlobal.onKeyInfoChange(self.game, 'star')

		# 运营活动奖励未领取
		effs = ObjectYYHuoDongFactory.getRoleRegainMails(self.game)
		for eff in effs:
			yield effectAutoGain(eff, self.game, self.dbcGame, src='yy_regain')

		# 刷新重聚活动数据
		if role.reunion.get('info', {}).get('role_id', None) and role.reunion.get('role_type', None):
			from game.handler._yyhuodong import getReunion
			reunion = yield getReunion(self.dbcGame, role.reunion['info']['role_id'])
			ObjectReunionRecord.onLogin(self.game, reunion)

		# 钓鱼大赛自动未领取奖励
		ObjectCrossFishingGameGlobal.onRoleLogin(self.game)

		# 活动开启，减轻客户端YYGetActive请求次数，直接使用game model数据即可
		self.game.role.refreshYYOpen()

		# 排行榜称号
		role.refreshRankTitle()
		# 刷新运营活动计数器
		role.refreshYYCounter()

		# 头衔上线走马灯
		idx = self.game.role.title_id
		if idx > 0:
			cfg = csv.title[idx]
			if cfg and cfg["type"] == 1:
				message = getL10nCsvValue(cfg, 'message')
				if message:
					msg = message.format(idx=idx, name=role.name)
					ObjectMessageGlobal.newsLogin(role, msg)

		# 记录相关登录信息到log，方便后续检查问题和推送给tc数据后台
		logger.info('%schannel %s account %s role %d %s level %d vip %d gold %d rmb %d stamina %d battle %d top6 %d', 'new role ' if newRole else '', self.game.role.channel, binascii.hexlify(self.game.role.account_id), self.game.role.uid, binascii.hexlify(self.game.role.id), self.game.role.level, self.game.role.vip_level, self.game.role.gold, self.game.role.rmb, self.game.role.stamina, self.game.role.battle_fighting_point, self.game.role.top6_fighting_point)

		ta.track(self.game, event='login')
		# 服务器记录刷新
		model = self.game.model
		model.update(union_training=training)
		wview = {
			'model': model,
			'server_time': nowtime_t(),
			'server_openTime': datetime2timestamp(globaldata.GameServOpenDatetime),
			'global_record': ObjectServerGlobalRecord.modelSync(0),
		}
		# weekday = nowdatetime_t().isoweekday()
		# if weekday == 6:
		# 	wview['top8Union'] = ObjectUnionFightGlobal.Singleton.pre_top8_union
		self.write(wview)
		self.game.startSync()

		# with open('model_data.py', 'wb') as fp:
		# 	fp.write(str(self.game.model))


# 关卡战斗开始
class GameStartGate(RequestHandlerTask):
	url = r'/game/start_gate'

	@coroutine
	def run(self):
		gateID = self.input.get('gateID', None)
		gateType = ObjectMap.queryGateType(gateID)

		if gateID not in csv.scene_conf or gateType is None:
			raise ClientError('gateID error')

		# 战斗数据
		cards = None
		if gateType == MapDefs.TypeNightmareGate:
			cards = self.game.role.huodong_cards.get(NightmareHuodongID, self.game.role.battle_cards)
		else:
			cards = self.game.role.battle_cards
		if cards is None:
			raise ClientError('cards error')

		self.game.battle = ObjectGateBattle(self.game)
		ret = self.game.battle.begin(gateID, cards)
		self.write({
			'model': ret
		})
		# DEBUG:
		# if gateID == 101:
		# 	gates = [101,102,103,201,202,203,204,205,206,207,208,301,302,303,304,305,306,307,308,401,402,403,404,405,406,407,408,501,502,503,504,505,506,507,508,509,510,601,602,603,604,605,606,607,608,609,610,701,702,703,704,705,706,707,708,709,710,801,802,803,804,805,806,807,808,809,810,901,902,903,904,905,906,907,908,909,910,1001,1002,1003,1004,1005,1006,1007,1008,1009,1010,1101,1102,1103,1104,1105,1106,1107,1108,1109,1110,1201,1202,1203,1204,1205,1206,1207,1208,1209,1210,1301,1302,1303,1304,1305,1306,1307,1308,1309,1310,1401,1402,1403,1404,1405,1406,1407,1408,1409,1410,1501,1502,1503,1504,1505,1506,1507,1508,1509,1510,1601,1602,1603,1604,1605,1606,1607,1608,1609,1610,1701,1702,1703,1704,1705,1706,1707,1708,1709,1710,1801,1802,1803,1804,1805,1806,1807,1808,1809,1810,1901,1902,1903,1904,1905,1906,1907,1908,1909,1910,2001,2002,2003,2004,2005,2006,2007,2008,2009,2010,2101,2102,2103,2104,2105,2106,2107,2108,2109,2110,2201,2202,2203,2204,2205,2206,2207,2208,2209,2210,2301,2302,2303,2304,2305,2306,2307,2308,2309,2310,2401,2402,2403,2404,2405,2406,2407,2408,2409,2410,2501,2502,2503,2504,2505,2506,2507,2508,2509,2510]

		# 	hgates = [10101,10102,10103,10201,10202,10203,10204,10301,10302,10303,10304,10401,10402,10403,10404,10501,10502,10503,10504,10505,10601,10602,10603,10604,10605,10701,10702,10703,10704,10705,10801,10802,10803,10804,10805,10901,10902,10903,10904,10905,11001,11002,11003,11004,11005,11101,11102,11103,11104,11105,11201,11202,11203,11204,11205,11301,11302,11303,11304,11305,11401,11402,11403,11404,11405,11501,11502,11503,11504,11505,11601,11602,11603,11604,11605,11701,11702,11703,11704,11705,11801,11802,11803,11804,11805,11901,11902,11903,11904,11905,12001,12002,12003,12004,12005,12101,12102,12103,12104,12105,12201,12202,12203,12204,12205,12301,12302,12303,12304,12305,12401,12402,12403,12404,12405,12501,12502,12503,12504,12505]

		# 	gs = gates + hgates
		# 	for gateID in gs:
		# 		try:
		# 			battle = ObjectGateBattle(self.game)
		# 			battle.begin(gateID, self.game.role.battle_cards)
		# 			battle.result('win', 3)
		# 			battle.end()
		# 		except:
		# 			pass


# 关卡战斗结束
class GameEndGate(RequestHandlerTask):
	url = r'/game/end_gate'

	@coroutine
	def run(self):
		if not isinstance(self.game.battle, ObjectGateBattle):
			raise ServerError('gate battle miss')

		battleID = self.input.get('battleID', None)
		gateID = self.input.get('gateID', None)
		result = self.input.get('result', None)
		star = self.input.get('star', None)

		if any([x is None for x in [battleID, gateID, result, star]]):
			raise ClientError('param miss')
		if gateID != self.game.battle.gateID:
			raise ClientError('gateID error')
		if battleID != self.game.battle.id:
			raise ClientError('battleID error')

		oldStar = self.game.role.gate_star.get(gateID, {}).get('star',0)
		# 战斗结算
		eff = self.game.battle.result(result, star)
		effAll = ObjectGainAux(self.game, {})
		if eff:
			effAll += eff
		gateType = ObjectMap.queryGateType(gateID)

		# 噩梦关卡 （自动领取 首通和三星奖励）
		effFirst = ObjectGainAux(self.game, {})
		effStar3 = ObjectGainAux(self.game, {})
		if result == 'win' and gateType == MapDefs.TypeNightmareGate:
			# 首通
			effFirst = self.game.role.getGateExtraAwarrd(gateID, 'win')
			effAll += effFirst
			# 三星奖励
			effStar3 = self.game.role.getGateExtraAwarrd(gateID, 'star3')
			effAll += effStar3

		yield effectAutoGain(effAll, self.game, self.dbcGame, src='gate_drop_%d' % gateID)

		# 成就计数
		if result == 'win':
			if gateType == MapDefs.TypeGate or gateType == MapDefs.TypeHeroGate:
				ObjectYYHuoDongFactory.onGeneralTask(self.game, TargetDefs.GateSum, 1)
		if result == 'win':
			cnt = ObjectMonsterCSV.getMonsterCount(gateID)

		# 战斗结算完毕
		ret = self.game.battle.end()

		# 触发活动Boss
		# ObjectYYHuoDongFactory.onHuoDongBoss(self.game, csv.scene_conf[gateID].staminaCost)
		cards = self.game.battle.cardIDs
		self.game.battle = None
		if eff:
			ret['view']['drop'] = eff.result
		if gateType == MapDefs.TypeNightmareGate:
			ret['view']['first'] = effFirst.result
			ret['view']['star3'] = effStar3.result

		self.write(ret)


# 数据同步
class GameSync(RequestHandlerTask):
	url = r'/game/sync'

	@coroutine
	def run(self):
		self.write({'server_time': nowtime_t()})


# 扫荡
class GameSaoDang(RequestHandlerTask):
	url = r'/game/saodang'

	@coroutine
	def run(self):
		gateID = self.input.get('gateID', None)
		times = self.input.get('times', None)
		itemID = self.input.get('itemID', None)
		targetNum = self.input.get('targetNum', None)

		if gateID is None or times is None or times < 1:
			raise ClientError('param is error')

		# 体力是否足够
		cfg = csv.scene_conf[gateID]
		if self.game.role.stamina < cfg.staminaCost:
			raise ClientError(ErrDefs.gateStaminaNotEnough)

		# 每日体力消耗上限
		if ConstDefs.dailyStaminaCostMax - self.game.dailyRecord.cost_stamina_sum < cfg.staminaCost:
			raise ClientError(ErrDefs.dailyStaminaCostLimit)

		if self.game.trainer.gateSaoDangTimes >= times:
			pass
		elif self.game.role.multiSaoDangCountOpen < times:
			raise ClientError(ErrDefs.saodangMultiVIPNotEnough)

		if cfg.staminaCost > 0:
			stamina = min(self.game.role.stamina, ConstDefs.dailyStaminaCostMax - self.game.dailyRecord.cost_stamina_sum)
			stamina = max(stamina, 0)
			if stamina < times * cfg.staminaCost:
				times = int(stamina / cfg.staminaCost)

		todayTimes = self.game.dailyRecord.gate_times.get(gateID, 0)
		addTimes = 0
		# 运营活动 精英关卡次数
		if ObjectMap.queryGateType(gateID) == MapDefs.TypeHeroGate:
			buyTimes = self.game.dailyRecord.buy_herogate_times.get(gateID, 0)
			if buyTimes == 0:
				yyID = ObjectYYHuoDongFactory.getDoubleDropOpenID(YYHuoDongDefs.DoubleEliteCount)
				if yyID:
					addTimes = csv.yunying.yyhuodong[yyID].paramMap['count']

		maxTimes = csv.scene_conf[gateID].dayChallengeMax + addTimes
		if todayTimes >= maxTimes:
			raise ClientError(ErrDefs.saodangGateTimesNotEnough)
		if todayTimes + times > maxTimes:
			times = maxTimes - todayTimes

		# 战斗数据
		battle = ObjectGateSaoDang(self.game)
		times = battle.begin(gateID, times, itemID, targetNum)

		# 战斗结算
		eff = battle.result()
		yield effectAutoGain(eff, self.game, self.dbcGame, src='gate_saodang_drop_%d' % gateID)

		# 战斗结算完毕
		ret = battle.end()

		# 触发活动Boss
		# ObjectYYHuoDongFactory.onHuoDongBoss(self.game, battle.times * cfg.staminaCost)

		# 成就计数
		gateType = ObjectMap.queryGateType(gateID)
		if gateType == MapDefs.TypeGate or gateType == MapDefs.TypeHeroGate:
			ObjectYYHuoDongFactory.onGeneralTask(self.game, TargetDefs.GateSum, times)

		cnt = ObjectMonsterCSV.getMonsterCount(gateID) * times
		self.write(ret)

		ta.track(self.game, event='saodang',gate_id=gateID,count=times,ret=ret)


# 精英关卡批量扫荡
class GameSaoDangBatch(RequestHandlerTask):
	url = r'/game/saodang/batch'

	@coroutine
	def run(self):
		gateIDs = self.input.get('gateIDs', None)  # scene_conf配表的csvID列表
		if gateIDs is None:
			raise ClientError('param is error')

		all_eff = ObjectGainAux(self.game, {})
		result = []
		extra = {}
		err = ""
		staminaCost = 0
		for idx, gateID in enumerate(gateIDs):
			times = 3  # 目前写死3次，以后有变化可改成读表
			# 体力是否足够
			cfg = csv.scene_conf[gateID]
			if self.game.role.stamina < cfg.staminaCost:
				err = ErrDefs.gateStaminaNotEnough
				break

			if ConstDefs.dailyStaminaCostMax - self.game.dailyRecord.cost_stamina_sum < cfg.staminaCost:
				err = ErrDefs.dailyStaminaCostLimit
				break

			if self.game.trainer.gateSaoDangTimes >= times:
				pass
			elif self.game.role.multiSaoDangCountOpen < times:
				continue

			if cfg.staminaCost > 0:
				stamina = min(self.game.role.stamina, ConstDefs.dailyStaminaCostMax - self.game.dailyRecord.cost_stamina_sum)
				stamina = max(stamina, 0)
				if stamina < times * cfg.staminaCost:
					times = int(stamina / cfg.staminaCost)

			todayTimes = self.game.dailyRecord.gate_times.get(gateID, 0)
			addTimes = 0
			# 运营活动 精英关卡次数
			if ObjectMap.queryGateType(gateID) == MapDefs.TypeHeroGate:
				buyTimes = self.game.dailyRecord.buy_herogate_times.get(gateID, 0)
				if buyTimes == 0:
					yyID = ObjectYYHuoDongFactory.getDoubleDropOpenID(YYHuoDongDefs.DoubleEliteCount)
					if yyID:
						addTimes = csv.yunying.yyhuodong[yyID].paramMap['count']

			maxTimes = csv.scene_conf[gateID].dayChallengeMax + addTimes
			if todayTimes >= maxTimes:
				# 今日次数用光了
				continue

			if todayTimes + times > maxTimes:
				times = maxTimes - todayTimes

			# 战斗数据
			battle = ObjectGateSaoDang(self.game)
			battle.begin(gateID, times)

			# 战斗结算
			eff = battle.result()
			all_eff += eff

			# 战斗结算完毕
			ret = battle.end()
			# 合并ret
			for res in ret['view']['result']:
				res['gateId'] = gateID
			result += ret['view']['result']
			for itemID, itemCount in ret['view']['extra'].iteritems():
				if itemID not in extra:
					extra[itemID] = itemCount
				else:
					extra[itemID] += itemCount

			# 成就计数
			gateType = ObjectMap.queryGateType(gateID)
			if gateType == MapDefs.TypeGate or gateType == MapDefs.TypeHeroGate:
				ObjectYYHuoDongFactory.onGeneralTask(self.game, TargetDefs.GateSum, times)

			staminaCost += times * cfg.staminaCost

		# 触发活动Boss
		# ObjectYYHuoDongFactory.onHuoDongBoss(self.game, staminaCost)

		if not result and err:
			raise ClientError(err)

		yield effectAutoGain(all_eff, self.game, self.dbcGame, src='gate_saodang_batch_drop')
		self.write({
			'view': {
				'result': result,
				'extra': extra,
			}
		})


# 精英关卡批量扫荡关卡收藏
class GameSaoDangBatchFavorites(RequestHandlerTask):
	url = r'/game/saodang/batch/favorites'

	@coroutine
	def run(self):
		gateID = self.input.get('gateID', None)
		if gateID is None:
			raise ClientError('param is error')
		collection = self.game.role.mop_up_collection
		if gateID in collection:
			collection.remove(gateID)
		else:
			collection.append(gateID)


# 排行榜排名
class GameRank(RequestHandlerTask):
	url = r'/game/rank'

	@coroutine
	def run(self):
		rtype = self.input.get('type', None)
		offest = self.input.get('offest', 0)
		size = self.input.get('size', 50)
		role = self.game.role

		if rtype == 'pokedex':
			role.cardNum_rank = yield ObjectRankGlobal.queryRank('pokedex', role.id, tied=True)
			ret = yield ObjectRankGlobal.getRankList('pokedex',offest, size)
			self.write({'view': {
				'rank': ret,
				'offest': offest,
				'size': size,
			}})

		elif rtype == 'fight':
			role.fight_rank = yield ObjectRankGlobal.queryRank('fight', role.id)
			ret = yield ObjectRankGlobal.getRankList('fight',offest, size)
			self.write({'view': {
				'rank': ret,
				'offest': offest,
				'size': size,
			}})

		elif rtype == 'card1fight':
			role.card1fight_rank = yield ObjectRankGlobal.queryRank('card1fight',self.game.cards.maxFightPointCardID)
			ret = yield ObjectRankGlobal.getRankList('card1fight',offest, size)
			self.write({'view': {
				'rank': ret,
				'offest': offest,
				'size': size,
			}})

		elif rtype == 'star':
			role.gate_star_rank = yield ObjectRankGlobal.queryRank('star', role.id)
			ret = yield ObjectRankGlobal.getRankList('star',offest, size)
			self.write({'view': {
				'rank': ret,
				'offest': offest,
				'size': size,
			}})

		elif rtype == 'random_tower':
			if role.random_tower_db_id:
				self.game.randomTower.day_rank = yield ObjectRankGlobal.queryRank('random_tower', role.id)
			ret = yield ObjectRankGlobal.getRankList('random_tower', offest, size)
			self.write({'view': {
				'rank': ret,
				'offest': offest,
				'size': size,
			}})

		elif rtype == 'yybox':
			ret = yield ObjectRankGlobal.getRankList('yybox',offest, size, self.game.role.areaKey)
			self.write({'view': {
				'rank': ret,
				'offest': offest,
				'size': size,
			}})

		elif rtype == 'achievement':
			role.achievement_rank = yield ObjectRankGlobal.queryRank('achievement', role.id, tied=True)
			ret = yield ObjectRankGlobal.getRankList('achievement', offest, size)
			self.write({'view': {
				'rank': ret,
				'offest': offest,
				'size': size,
			}})

		elif rtype == 'craft':
			self.game.dailyRecord.craft_rank, info = yield ObjectRankGlobal.queryRank('craft', role.id, withInfo=True)
			ret = yield ObjectRankGlobal.getRankList('craft', offest, size)
			view = {
				'rank': ret,
				'offest': offest,
				'size': size,
			}
			if info:
				view.update(info)
			self.write({'view':view})

		elif rtype == 'endless':
			role.endless_rank = yield ObjectRankGlobal.queryRank('endless', role.id)
			ret = yield ObjectRankGlobal.getRankList('endless', offest, size)
			self.write({'view': {
				'rank': ret,
				'offest': offest,
				'size': size,
			}})
		elif rtype == 'snowball':
			ret = yield ObjectRankGlobal.getRankList('snowball', offest, size)
			self.write({'view': {
				'rank': ret,
				'offest': offest,
				'size': size,
			}})

		else:
			# 活动副本小排行榜
			myrank, score = yield ObjectRankGlobal.queryRank(rtype, role.id, withInfo=True)
			ret = yield ObjectRankGlobal.getRankList(rtype, offest, size)
			self.write({'view': {
				'rank': ret,
				'myrank': myrank,
				'score': score,
				'offest': offest,
				'size': size,
			}})


# 领取礼包
class GameGift(RequestHandlerTask):
	url = r'/game/gift'

	@coroutine
	def run(self):
		key = self.input.get('key', None)

		if key is None:
			raise ClientError('gift key is miss')

		ret = yield self.dbcGift.call_async('GiftExisted', key, self.servKey, self.game.role.account_id)
		if not ret['ret']:
			if ret['err'] == 'gift_cannot_use':
				raise ClientError(ErrDefs.giftNoExisted)
			elif ret['err'] == 'gift_used':
				raise ClientError(ErrDefs.giftOpened)
			elif ret['err'] == 'gift_other_used':
				raise ClientError(ErrDefs.giftOtherOpened)
			elif ret['err'] == 'no_gift':
				raise ClientError(ErrDefs.giftNoExisted)
			raise ClientError(ErrDefs.giftOtherOpened)

		gift = ObjectGift(self.game, self.dbcGame)
		gift.set(ret['model']).init()
		eff = gift.getEffect()

		cfg = csv.gift[gift.csv_id]
		if cfg.giftType == 0:
			accountID = self.game.role.account_id
		else:
			accountID = None # 固定礼包可以多人使用

		# 先修改数据库，再给奖励
		ret = yield self.dbcGift.call_async('GiftUse', key, self.servKey, accountID)
		# 可能有人抢先使用
		if not ret['ret']:
			raise ClientError(ErrDefs.giftOtherOpened)

		yield effectAutoGain(eff, self.game, self.dbcGame, src='gift_%d' % gift.csv_id)
		self.write({'view': {'award': eff.result, 'csv_id': gift.csv_id}})


# 获取固定商店数据
class GameFixShopGet(RequestHandlerTask):
	url = r'/game/fixshop/get'

	@coroutine
	def run(self):
		yield getShopModel(self.game, self.dbcGame)


# 固定商店购买
class GameFixShopBuy(RequestHandlerTask):
	url = r'/game/fixshop/buy'

	@coroutine
	def run(self):
		idx = self.input.get('idx', None)
		shopID = self.input.get('shopID', None)
		itemID = self.input.get('itemID', None)
		count = self.input.get('count', 1) # 只增对限购类型生效
		if not all([x is not None for x in [idx, shopID, itemID]]):
			raise ClientError('param miss')
		if count <= 0:
			raise ClientError('param error')

		if self.game.role.fix_shop_db_id is None:
			raise ClientError(ErrDefs.fixShopNotExisted)
		# 商店过期 重新生成商店
		if self.game.fixShop.isPast():
			yield getShopModel(self.game, self.dbcGame)
			raise ClientError(ErrDefs.fixShopRefresh)
		discount = self.game.privilege.fixShopDiscount
		eff = self.game.fixShop.buyItem(idx, shopID, itemID, count, src='fixshop_buy', discount=discount)
		yield effectAutoGain(eff, self.game, self.dbcGame, src='fixshop_buy')


# 刷新固定商店
class GameFixShopRefresh(RequestHandlerTask):
	url = r'/game/fixshop/refresh'

	@coroutine
	def run(self):
		if self.game.role.fix_shop_db_id is None:
			raise ClientError(ErrDefs.fixShopNotExisted)
		# 是否代金券刷新 钻石刷新可不传
		itemRefresh = self.input.get('itemRefresh', None)
		if not itemRefresh:
			refreshTimes = self.game.dailyRecord.fix_shop_refresh_times
			if refreshTimes >= self.game.role.shopRefreshLimit:
				raise ClientError(ErrDefs.shopRefreshUp)
			costRMB = ObjectCostCSV.getFixShopRefreshCost(refreshTimes)
			cost = ObjectCostAux(self.game, {'rmb': costRMB})
			if not cost.isEnough():
				raise ClientError("cost rmb not enough")
			self.game.dailyRecord.fix_shop_refresh_times = refreshTimes + 1
		else:
			cost = ObjectCostAux(self.game, {ShopRefreshItem: 1})
			if not cost.isEnough():
				raise ClientError("cost item not enough")
		cost.cost(src='fixshop_refresh')
		yield getShopModel(self.game, self.dbcGame, True)
		self.game.achievement.onCount(AchievementDefs.ShopRefresh, 1)
		self.game.achievement.onCount(AchievementDefs.FixShopRefresh, 1)

@coroutine
def getShopModel(game, dbc, refresh=False):
	if game.role.fix_shop_db_id:
		if refresh or game.fixShop.isPast():
			items = ObjectFixShop.makeShopItems(game)
			game.fixShop.makeShop(items)
	else:
		last_time = nowtime_t()
		roleID = game.role.id
		items = ObjectFixShop.makeShopItems(game)
		ret = yield dbc.call_async('DBCreate', 'FixShop', {
			'role_db_id': roleID,
			'items': items,
			'last_time': last_time,
		})
		model = ret['model']
		game.role.fix_shop_db_id = model['id']
		game.fixShop = ObjectFixShop(game, dbc).set(model).init()
	raise Return(game.fixShop)


# 保存布阵阵容
class GameBattleCard(RequestHandlerTask):
	url = r'/game/battle/card'

	@coroutine
	def run(self):
		battleCardIDs = self.input.get('battleCardIDs', None)

		if not battleCardIDs:
			raise ClientError(ErrDefs.battleCardCountLimit)

		self.game.role.deployBattleCards(battleCardIDs)

		futures = {}
		sync = self.game.role.deployments_sync.get('arena_defence_cards', False)
		if sync and self.game.role.pvp_record_db_id:
			futures['arena_defence_cards'] = refreshCardsToPVP(self.rpcArena, self.game, defence_cards=self.game.role.battle_cards)

		sync = self.game.role.deployments_sync.get('cross_online_fight', False)
		if sync and self.game.role.cross_online_fight_record_db_id:
			futures['cross_online_fight'] = refreshCardsToCrossOnlineFight(self.rpcPVP, self.game, cards=self.game.role.battle_cards)

		yield multi_future(futures)

# 保存活动上阵阵容
class GameHuodongCard(RequestHandlerTask):
	url = r'/game/huodong/card'

	@coroutine
	def run(self):
		huodongID = self.input.get('huodongID', None)
		battleCardIDs = self.input.get('battleCardIDs', None)

		if battleCardIDs is None or huodongID is None:
			raise ClientError('param miss')

		self.game.role.deployHuodongCards(huodongID, battleCardIDs)

# 购买道具（使用金币、钻石等）
class BuyItem(RequestHandlerTask):
	url = r'/game/buy_item'

	@coroutine
	def run(self):
		itemID = self.input.get('itemID', None)
		itemCount = self.input.get('itemCount', 1)
		if itemID is None or itemID not in csv.items:
			raise ClientError('itemID error')
		if itemCount <= 0:
			raise ClientError('itemCount error')

		cfg = csv.items[itemID]

		if self.game.items.getItemCount(itemID) + itemCount > cfg.stackMax:
			raise ClientError('itemCount error')

		if 'buy_level' in cfg.specialArgsMap and self.game.role.level < cfg.specialArgsMap['buy_level']:
			raise ClientError(ErrDefs.buyItemLevelLimit)

		cost = None
		if 'buy_gold' in cfg.specialArgsMap:
			cost = ObjectCostAux(self.game, {'gold': cfg.specialArgsMap['buy_gold']})
		elif 'buy_rmb' in cfg.specialArgsMap:
			cost = ObjectCostAux(self.game, {'rmb': cfg.specialArgsMap['buy_rmb']})

		if not cost:
			raise ClientError('param error')

		cost *= itemCount
		if not cost.isEnough():
			raise ClientError("cost not enough")
		cost.cost(src='buy_item')

		eff = ObjectGainAux(self.game, {itemID: itemCount})
		yield effectAutoGain(eff, self.game, self.dbcGame, src='buy_item')

# 购买经验药水
class BuyExpItem(RequestHandlerTask):
	url = r'/game/exp/buy_item'

	@coroutine
	def run(self):
		itemID = self.input.get('itemID', None)
		itemCount = self.input.get('itemCount', 1)
		if itemID is None or itemID not in csv.items:
			raise ClientError('itemID error')
		if itemCount <= 0:
			raise ClientError('itemCount error')

		cfg = csv.items[itemID]
		needLevel = cfg.specialArgsMap['buy_level']
		needRmb = cfg.specialArgsMap['buy_rmb'] * itemCount
		if self.game.role.level < needLevel:
			raise ClientError(ErrDefs.buyItemLevelLimit)

		needRmb = int(needRmb * (1 - self.game.trainer.expItemCostFailRate))
		if needRmb <= 0:
			needRmb = 1
		cost = ObjectCostAux(self.game, {'rmb': needRmb})
		if not cost.isEnough():
			raise ClientError("cost rmb not enough")
		cost.cost(src='exp_buy_item')
		eff = ObjectGainAux(self.game, {itemID: itemCount})
		yield effectAutoGain(eff, self.game, self.dbcGame, src='exp_buy_item')

# 购买精灵球
class BuyBallItem(RequestHandlerTask):
	url = r'/game/ball/buy_item'

	@coroutine
	def run(self):
		itemID = self.input.get('itemID', None)
		itemCount = self.input.get('itemCount', 1)
		if itemID is None or itemID not in csv.items:
			raise ClientError('itemID error')
		if itemCount <= 0:
			raise ClientError('itemCount error')

		cfg = csv.items[itemID]
		needLevel = cfg.specialArgsMap['buy_level']
		needGold = cfg.specialArgsMap['buy_gold'] * itemCount
		if self.game.role.level < needLevel:
			raise ClientError(ErrDefs.buyItemLevelLimit)

		cost = ObjectCostAux(self.game, {'gold': needGold})
		if not cost.isEnough():
			raise ClientError("cost gold not enough")
		cost.cost(src='ball_buy_item')
		eff = ObjectGainAux(self.game, {itemID: itemCount})
		yield effectAutoGain(eff, self.game, self.dbcGame, src='ball_buy_item')

# 天赋升级
class TalentLevelUpReady(RequestHandlerTask):
	url = r'/game/talent/levelup_ready'

	@coroutine
	def run(self):
		talentID = self.input.get('talentID', None)
		if talentID is None:
			raise ClientError('talentID miss')

		if talentID not in csv.talent:
			raise ClientError('talentID error')

		self.game.talentTree.talentLevelUp(talentID)

# 天赋刷新
class TalentLevelUpEnd(RequestHandlerTask):
	url = r'/game/talent/levelup_end'

	@coroutine
	def run(self):
		talentIDs = self.input.get('talentIDs', None)
		if talentIDs is None:
			raise ClientError('talentIDs miss')

		self.game.talentTree.updateRelatedCards(talentIDs)

# 天赋重置
class TalentReset(RequestHandlerTask):
	url = r'/game/talent/reset'

	@coroutine
	def run(self):
		treeID = self.input.get('treeID', None)
		if treeID and not ObjectFeatureUnlockCSV.isOpen(FeatureDefs.SingleTalentReset, self.game):
			raise ClientError('not open')

		ret = self.game.talentTree.talentResetAll(treeID)

		self.write({
			'view': {
				'gold': ret[0],
				'talent_point': ret[1],
			}
		})


# 通用玩家缩略信息(排行榜等)
class GameRoleInfo(RequestHandlerTask):
	url = r'/game/role_info'

	@coroutine
	def run(self):
		roleID = self.input.get('roleID', None)

		if roleID is None:
			raise ClientError('roleID is miss')

		# if roleID and roleID == self.game.role.id:
		# 	raise ClientError(ErrDefs.friendSearchMyself)

		ret = yield ObjectCacheGlobal.queryRole(roleID)
		if not ret:
			raise ClientError(ErrDefs.gameRankRoleInfoErr)
		ret['union_name'] = ObjectUnion.queryUnionName(roleID)
		self.write({'view': ret})


# 通用卡牌缩略信息(排行榜等)
class GameCardInfo(RequestHandlerTask):
	url = r'/game/card_info'

	@coroutine
	def run(self):
		cardID = self.input.get('cardID', None)

		if cardID is None:
			raise ClientError('cardID is miss')

		ret = yield ObjectCacheGlobal.queryCard(cardID)
		if not ret:
			raise ClientError(ErrDefs.gameRankCardInfoErr)
		self.write({'view': ret})

@coroutine
def getMysteryShop(game, dbc, refresh=False):
	# 存在商店，判断是否过期
	# 强制刷新
	if game.role.mystery_shop_db_id:
		if refresh or game.mysteryShop.isPast():
			if refresh:
				game.mysteryShop.refresh_times += 1
			items = ObjectMysteryShop.makeShopItems(game)
			game.mysteryShop.makeShop(items)
	else:
		last_time = nowtime_t()
		roleID = game.role.id
		items = ObjectMysteryShop.makeShopItems(game)
		ret = yield dbc.call_async('DBCreate', 'MysteryShop', {
			'role_db_id': roleID,
			'items': items,
			'last_time': last_time,
		})
		model = ret['model']
		game.role.mystery_shop_db_id = model['id']
		game.mysteryShop = ObjectMysteryShop(game, dbc).dbset(model).init()
	raise Return(game.mysteryShop)


# 获取神秘商店
class MysteryShopGet(RequestHandlerTask):
	url = r'/game/mystery/get'

	@coroutine
	def run(self):
		if not self.game.mysteryShop.isOpening():
			raise ClientError(ErrDefs.shopHasClosed)
		yield getMysteryShop(self.game, self.dbcGame)


# 刷新神秘商店
class MysteryShopRefresh(RequestHandlerTask):
	url = r'/game/mystery/refresh'

	@coroutine
	def run(self):
		if not self.game.mysteryShop.isOpening():
			raise ClientError(ErrDefs.shopHasClosed)

		if self.game.mysteryShop.refresh_times >= self.game.role.mysteryRefresh:
			raise ClientError('refresh times used up')
		costRMB = ObjectCostCSV.getMysteryShopRefreshCost(self.game.mysteryShop.refresh_times)
		cost = ObjectCostAux(self.game, {'rmb': costRMB})
		if not cost.isEnough():
			raise ClientError(ErrDefs.pvpShopRefreshRMBNotEnough)
		cost.cost(src='mystery_shop_refresh')
		yield getMysteryShop(self.game, self.dbcGame, True)
		self.game.achievement.onCount(AchievementDefs.MysteryShopRefresh, 1)


class MysteryShopBuy(RequestHandlerTask):
	url = r'/game/mystery/buy'

	@coroutine
	def run(self):
		if not self.game.mysteryShop.isOpening():
			raise ClientError(ErrDefs.shopHasClosed)

		idx = self.input.get('idx', None)
		shopID = self.input.get('shopID', None)
		itemID = self.input.get('itemID', None)
		count = self.input.get('count', 1) # 只增对限购类型生效
		if not all([x is not None for x in [idx, shopID, itemID]]):
			raise ClientError('param miss')

		oldID = self.game.mysteryShop.id
		mysteryShop = yield getMysteryShop(self.game, self.dbcGame)
		if oldID != mysteryShop.id:
			#商店已经刷新
			raise ClientError(ErrDefs.fixShopRefresh)

		discount = self.game.privilege.mysteryShopDiscount
		eff = mysteryShop.buyItem(idx, shopID, itemID, count, src='mystery_shop_buy', discount=discount)
		yield effectAutoGain(eff, self.game, self.dbcGame, src='mystery_shop_buy')


# 战报分享
class GameBattleShare(RequestHandlerTask):
	url = r'/game/battle/share'

	@coroutine
	def run(self):
		if not ObjectFeatureUnlockCSV.isOpen(FeatureDefs.BattleShare, self.game):
			raise ClientError('locked')
		if self.game.role.silent_flag:
			raise ClientError(ErrDefs.roleBeenSilent)
		battleID = self.input.get('battleID', None)
		enemyName = self.input.get('enemyName', None)
		src = self.input.get('from', None)
		crossKey = self.input.get('crossKey', None)
		if not all([x is not None for x in [battleID, enemyName, src]]):
			raise ClientError('param miss')

		if src == 'arena':
			if self.game.dailyRecord.battle_share_times >= ConstDefs.shareTimesLimit:
				raise ClientError('arena share times is limit')
		elif src == 'crossArena':
			if self.game.dailyRecord.cross_arena_battle_share_times >= ConstDefs.shareTimesLimit:
				raise ClientError('cross arena share times is limit')
		elif src == 'onlineFight':
			if self.game.dailyRecord.cross_online_fight_share_times >= ConstDefs.shareTimesLimit:
				raise ClientError('cross arena share times is limit')
		elif src == 'crossMine':
			if self.game.dailyRecord.cross_mine_share_times >= ConstDefs.shareTimesLimit:
				raise ClientError('cross mine share times is limit')

		ObjectMessageGlobal.worldShareBattleMsg(self.game, battleID, enemyName, src, crossKey)

		if src == 'arena':
			self.game.dailyRecord.battle_share_times += 1
		elif src == 'crossArena':
			self.game.dailyRecord.cross_arena_battle_share_times += 1
		elif src == 'onlineFight':
			self.game.dailyRecord.cross_online_fight_share_times += 1
		elif src == 'crossMine':
			self.game.dailyRecord.cross_mine_share_times += 1

# 阵容同步设置
class DeploymentSync(RequestHandlerTask):
	url = r'/game/deployment/sync'

	@coroutine
	def run(self):
		key = self.input.get('key', None)
		flag = self.input.get('flag', False)

		if not isinstance(flag, bool):
			raise ClientError('flag type error')

		self.game.role.deployments_sync[key] = flag

		if key == 'arena_defence_cards':
			sync = self.game.role.deployments_sync[key]
			if sync and self.game.role.pvp_record_db_id:
				yield refreshCardsToPVP(self.rpcArena, self.game, defence_cards=self.game.role.battle_cards)
				model = yield makeBattleModel(self.game, self.rpcArena, self.dbcGame, False)
				self.write({'model': model})
		elif key == 'cross_online_fight':
			sync = self.game.role.deployments_sync[key]
			if sync and self.game.role.cross_online_fight_record_db_id:
				yield refreshCardsToCrossOnlineFight(self.rpcPVP, self.game, cards=self.game.role.battle_cards)
				self.write({
					'model': {
						'cross_online_fight': {'cards': self.game.role.battle_cards},
					}
				})


# 刷新碎片商店
class FragShopRefresh(RequestHandlerTask):
	url = r'/game/frag/shop/refresh'

	@coroutine
	def run(self):
		if not self.game.role.frag_shop_db_id:
			raise ClientError(ErrDefs.shopNotExisted)
		# 是否代金券刷新 钻石刷新可不传
		itemRefresh = self.input.get('itemRefresh', None)
		if not itemRefresh:
			refreshTimes = self.game.dailyRecord.frag_shop_refresh_times
			if refreshTimes >= self.game.role.fragShopRefreshLimit:
				raise ClientError(ErrDefs.shopRefreshUp)
			costRMB = ObjectCostCSV.getFragShopRefreshCost(refreshTimes)
			cost = ObjectCostAux(self.game, {'rmb': costRMB})
			if not cost.isEnough():
				raise ClientError("cost rmb not enough")
			self.game.dailyRecord.frag_shop_refresh_times = refreshTimes + 1
		else:
			cost = ObjectCostAux(self.game, {ShopRefreshItem: 1})
			if not cost.isEnough():
				raise ClientError("cost item not enough")
		cost.cost(src='frag_shop_refresh')
		yield getFragShopModel(self.game, self.dbcGame, True)
		self.game.achievement.onCount(AchievementDefs.ShopRefresh, 1)

# 碎片商店购买
class FragShopBuy(RequestHandlerTask):
	url = r'/game/frag/shop/buy'

	@coroutine
	def run(self):
		idx = self.input.get('idx', None)
		shopID = self.input.get('shopID', None)
		itemID = self.input.get('itemID', None)
		count = self.input.get('count', 1) # 只增对限购类型生效
		if not all([x is not None for x in [idx, shopID, itemID]]):
			raise ClientError('param miss')
		if count <= 0:
			raise ClientError('param error')
		if not self.game.role.frag_shop_db_id:
			raise ClientError(ErrDefs.shopNotExisted)
		# 商店过期了
		oldID = self.game.fragShop.id
		fragShop = yield getFragShopModel(self.game, self.dbcGame)
		if oldID != fragShop.id:
			raise ClientError(ErrDefs.shopRefresh)
		eff = self.game.fragShop.buyItem(idx, shopID, itemID, count, src='frag_shop_buy')
		yield effectAutoGain(eff, self.game, self.dbcGame, src='frag_shop_buy')


# 获取碎片商店数据
class FragShopGet(RequestHandlerTask):
	url = r'/game/frag/shop/get'

	@coroutine
	def run(self):
		yield getFragShopModel(self.game, self.dbcGame)


@coroutine
def getFragShopModel(game, dbc, refresh=False):
	if game.role.frag_shop_db_id:
		# 强制刷新 或 过期
		if refresh or game.fragShop.isPast():
			game.role.frag_shop_db_id = None
			ObjectFragShop.addFreeObject(game.fragShop)
			game.fragShop = ObjectFragShop(game, dbc)
	# 重新生成商店
	if not game.role.frag_shop_db_id:
		last_time = nowtime_t()
		roleID = game.role.id
		items = ObjectFragShop.makeShopItems(game)
		model = ObjectFragShop.getFreeModel(roleID, items, last_time)  # 回收站中取
		fromDB = False
		if model is None:
			ret = yield dbc.call_async('DBCreate', 'FragShop', {
				'role_db_id': roleID,
				'items': items,
				'last_time': last_time,
			})
			model = ret['model']
			fromDB = True
		game.role.frag_shop_db_id = model['id']
		game.fragShop = ObjectFragShop(game, dbc).dbset(model, fromDB).init()

	raise Return(game.fragShop)

@coroutine
def getEquipShopModel(game, dbc, refresh=False):
	if game.role.equip_shop_db_id:
		# 强制刷新 或 过期
		if refresh or game.equipShop.isPast():
			game.role.equip_shop_db_id = None
			ObjectEquipShop.addFreeObject(game.equipShop)
			game.equipShop = ObjectEquipShop(game, dbc)
	# 重新生成商店
	if not game.role.equip_shop_db_id:
		last_time = nowtime_t()
		roleID = game.role.id
		items = ObjectEquipShop.makeShopItems(game)
		model = ObjectEquipShop.getFreeModel(roleID, items, last_time)
		fromDB = False
		if model is None:
			ret = yield dbc.call_async('DBCreate', 'EquipShop', {
				'role_db_id': roleID,
				'items': items,
				'last_time': last_time,
			})
			model = ret['model']
			fromDB = True
		game.role.equip_shop_db_id = model['id']
		game.equipShop = ObjectEquipShop(game, dbc).dbset(model, fromDB).init()

	raise Return(game.equipShop)

# 进入捕捉
class GameCapture(RequestHandlerTask):
	url = r'/game/capture/enter'

	@coroutine
	def run(self):
		captureType = self.input.get('captureType', None)
		index = self.input.get('index', None)
		if any([x is None for x in [captureType, index]]):
			raise ClientError('param miss')
		self.game.capture.enter(captureType, index)

# 捕捉精灵
class CaptureEnter(RequestHandlerTask):
	url = r'/game/capture'

	@coroutine
	def run(self):
		captureType = self.input.get('captureType', None)
		index = self.input.get('index', None)
		itemID = self.input.get('itemID', None)
		if any([x is None for x in [captureType, index, itemID]]):
			raise ClientError('param miss')

		eff = self.game.capture.capture(captureType, index, itemID)
		if eff:
			yield effectAutoGain(eff, self.game, self.dbcGame, src='capture')
			if eff.getCardsObjD():
				for _, obj in eff.getCardsObjD().iteritems():
					ObjectMessageGlobal.newsCardMsg(self.game.role, obj, 'capture')
					ObjectMessageGlobal.marqueeBroadcast(self.game.role, MessageDefs.MqCapture, card=obj)
					ObjectYYHuoDongFactory.onGeneralTask(self.game, TargetDefs.CaptureSuccessSum, 1)

		self.write({
			"view": {
				"result": eff.result if eff else {},
				"scene_times": self.game.capture.scene_times
			}
		})
		ta.track(self.game, event='capture',capture_result=eff.result if eff else {},target_card_id=index)

# 饰品商店获取
class EquipShopGet(RequestHandlerTask):
	url = r'/game/equipshop/get'

	@coroutine
	def run(self):
		yield getEquipShopModel(self.game, self.dbcGame)

# 饰品商店购买
class EquipShopBuy(RequestHandlerTask):
	url = r'/game/equipshop/buy'

	@coroutine
	def run(self):
		idx = self.input.get('idx', None)
		shopID = self.input.get('shopID', None)
		itemID = self.input.get('itemID', None)
		count = self.input.get('count', 1) # 只增对限购类型生效
		if not all([x is not None for x in [idx, shopID, itemID]]):
			raise ClientError('param miss')
		if not self.game.role.equip_shop_db_id:
			raise ClientError(ErrDefs.shopNotExisted)
		if count <= 0:
			raise ClientError('param error')
		# 商店过期了
		oldID = self.game.equipShop.id
		equipShop = yield getEquipShopModel(self.game, self.dbcGame)
		if oldID != equipShop.id:
			raise ClientError(ErrDefs.shopRefresh)
		eff = self.game.equipShop.buyItem(idx, shopID, itemID, count, src='equip_shop_buy')
		yield effectAutoGain(eff, self.game, self.dbcGame, src='equip_shop_buy')

# 抽卡累计宝箱
class DrawSumBox(RequestHandlerTask):
	url = r'/game/draw/sum/box/get'

	@coroutine
	def run(self):
		csvID = self.input.get('csvID', None)
		if csvID is None:
			raise ClientError('param miss')

		eff = self.game.role.getDrawSumBox(csvID)
		yield effectAutoGain(eff, self.game, self.dbcGame, src='draw_sum_box')

		self.write({'view':  {'award': eff.result}})


# 预设队伍修改名字
class GameReadyCardRename(RequestHandlerTask):
	url = r'/game/ready/card/rename'

	@coroutine
	def run(self):
		if not ObjectFeatureUnlockCSV.isOpen(FeatureDefs.ReadyTeam, self.game):
			raise ClientError('readyTeam not open')
		idx = self.input.get('idx', None)
		name = self.input.get('name', None)

		if idx is None or name is None:
			raise ClientError('param miss')
		if not name:
			raise ClientError('name is empty')

		# 名称是否合法
		uname = name.decode('utf8')
		# if len(name) > 21:
		# 	raise ClientError(ErrDefs.unionNameTooLong)
		if filterName(uname):
			raise ClientError(ErrDefs.deployNameInvalid)

		info = self.game.role.ready_cards.setdefault(idx, {'name': '', 'cards': [None, None, None, None, None, None]})
		info["name"] = name
		self.write({'view': {'result': 'ok'}})


# 预设队伍布阵保存
class GameReadyCardDeploy(RequestHandlerTask):
	url = r'/game/ready/card/deploy'

	@coroutine
	def run(self):
		if not ObjectFeatureUnlockCSV.isOpen(FeatureDefs.ReadyTeam, self.game):
			raise ClientError('readyTeam not open')
		idx = self.input.get('idx', None)
		cardIDs = self.input.get('cardIDs', None)  # 空阵容就空数组

		if idx is None or cardIDs is None:
			raise ClientError('param miss')

		self.game.role.deployReadyCards(idx, cardIDs)
