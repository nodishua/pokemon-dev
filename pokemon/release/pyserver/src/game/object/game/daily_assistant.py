#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2014 YouMi Information Technology Inc.
'''
import copy

from framework.csv import csv, ConstDefs
from framework.log import logger
from framework.object import ObjectBase, GCWeakValueDictionary

from game import ServerError
from game.globaldata import UnionTrainingSpeedUpMax
from game.object import DailyAssistantDefs, FeatureDefs, DrawCardDefs, DrawEquipDefs, DrawItemDefs, UnionDefs, DrawGemDefs, CostDefs, HuoDongDefs, YYHuoDongDefs, ReunionDefs, DrawChipDefs
from game.object.game.huodong import ObjectHuoDongFactory
from game.object.game.servrecord import ObjectServerGlobalRecord
from game.object.game.yyhuodong import ObjectYYHuoDongFactory
from game.object.game.costcsv import ObjectCostCSV
from game.object.game.cross_craft import ObjectCrossCraftGameGlobal
from game.object.game.craft import ObjectCraftInfoGlobal
from game.object.game.union_fight import ObjectUnionFightGlobal
from game.object.game.gain import ObjectCostAux
from game.object.game.levelcsv import ObjectFeatureUnlockCSV
from game.object.game.fishing import ObjectCrossFishingGameGlobal


#
# ObjectGem
#
class ObjectDailyAssistant(ObjectBase):

	ObjsMap = GCWeakValueDictionary()

	TabMap = {}  # { type : [csvID, ]}

	AllowMethod = {
		DailyAssistantDefs.UnionRedpacket: 'getUnionRedpacketInput',
		DailyAssistantDefs.UnionDailyGift: 'getUnionDailyGiftInput',
		DailyAssistantDefs.TrainerAward: 'getTrainerAwardInput',
		DailyAssistantDefs.GainGold: 'getGainGoldInput',

		DailyAssistantDefs.DrawCardRmb: 'getDrawCardRmbInput',
		DailyAssistantDefs.DrawCardGold: 'getDrawCardGoldInput',
		DailyAssistantDefs.DrawEquip: 'getDrawEquipInput',
		DailyAssistantDefs.DrawItem: 'getDrawItemInput',
		DailyAssistantDefs.DrawGem: 'getDrawGemInput',
		DailyAssistantDefs.DrawChip: 'getDrawChipInput',

		DailyAssistantDefs.CraftSignup: 'getCraftSignupInput',
		DailyAssistantDefs.UnionFightSignup: 'getUnionFightSignupInput',
		DailyAssistantDefs.CrossCraftSignup: 'getCrossCraftSignupInput',

		DailyAssistantDefs.HuodongFuben: 'getHuodongFubenInput',
		DailyAssistantDefs.Endless: 'getEndlessInput',
		DailyAssistantDefs.Fishing: 'getFishingInput',

		DailyAssistantDefs.UnionContrib: 'getUnionContribInput',
		DailyAssistantDefs.UnionFragDonate: 'getUnionFragDonateInput',
		DailyAssistantDefs.UnionTrainingSpeedup: 'getUnionTrainingSpeedupInput',
	}

	@classmethod
	def csv(cls, csvID=None):
		if csvID is None:
			return csv.daily_assistant
		return csv.daily_assistant[csvID]

	@classmethod
	def classInit(cls):
		cls.TabMap = {}
		import framework
		for csvID in cls.csv():
			cfg = cls.csv(csvID)
			if framework.__language__ in cfg.languages:
				cls.TabMap.setdefault(cfg.type, set()).add(csvID)

		# ??????csv??????
		for obj in cls.ObjsMap.itervalues():
			obj.init()

	def init(self):
		self.game.role.daily_assistant.setdefault("union_contrib", 1)
		self.game.role.daily_assistant.setdefault("endless_buy_reset", 0)
		self.game.role.daily_assistant.setdefault("fishing_skip", 1)
		ObjectDailyAssistant.ObjsMap[self.game.role.id] = self
		return ObjectBase.init(self)

	@property
	def roleOpen(self):
		return ObjectFeatureUnlockCSV.isOpen(FeatureDefs.DailyAssistant, self.game)

	def itemIsLock(self, csvID):
		cfg = self.csv(csvID)
		if not self.roleOpen:
			return True
		if not cfg.inUnlock:
			return False
		return not ObjectFeatureUnlockCSV.isOpen(cfg.features, self.game)

	def getInputs(self, type, filterKeys):
		'''
		?????? ?????????input
		'''
		csvIDs = self.TabMap[type]
		inputs = {}
		for csvID in csvIDs:
			if filterKeys and csvID in filterKeys:
				continue
			if csvID == DailyAssistantDefs.UnionFuben:
				continue
			if self.itemIsLock(csvID):
				continue
			if csvID not in self.AllowMethod:
				raise ServerError("Not Implement")
			handlerInputs = getattr(self, self.AllowMethod[csvID])()
			if handlerInputs:
				inputs[csvID] = handlerInputs
		return inputs

	# ??????
	def getDrawCardRmbInput(self):
		'''
		????????????
		'''
		handlerInput = []
		if self.game.dailyRecord.dc1_free_count <= 0:
			handlerInput.append({'drawType': DrawCardDefs.Free1})
		if not handlerInput:
			return
		return handlerInput

	def getDrawCardGoldInput(self):
		'''
		????????????
		'''
		handlerInput = []
		dailyRecord = self.game.dailyRecord
		count = (ConstDefs.drawGoldFreeLimit + self.game.trainer.freeGoldDrawCardTimes) - (dailyRecord.gold1_free_count + dailyRecord.draw_card_gold1_trainer)
		if count <= 0:
			return
		for i in xrange(count):
			handlerInput.append({'drawType': DrawCardDefs.FreeGold1})
		return handlerInput

	def getDrawEquipInput(self):
		'''
		?????????
		'''
		handlerInput = []
		if self.game.dailyRecord.eq_dc1_free_counter <= 0:
			handlerInput.append({'drawType': DrawEquipDefs.Free1})
		if not handlerInput:
			return
		return handlerInput

	def getDrawItemInput(self):
		'''
		??????
		'''
		handlerInput = []
		count = (self.game.trainer.drawItemFreeTimes + 1) - self.game.dailyRecord.item_dc1_free_counter
		if count <= 0:
			return
		for i in xrange(count):
			handlerInput.append({'drawType': DrawItemDefs.Free1})
		return handlerInput

	def getDrawGemInput(self):
		'''
		?????????
		'''
		handlerInput = []
		flags = self.game.role.assistant_flags.get(DailyAssistantDefs.Draw, {})
		decompose = flags.get(DailyAssistantDefs.DrawGem, 0)
		if self.game.dailyRecord.gem_rmb_dc1_free_count <= 0:
			handlerInput.append({'drawType': DrawGemDefs.Free1, 'decompose': decompose})
		if self.game.dailyRecord.gem_gold_dc1_free_count <= 0:
			handlerInput.append({'drawType': DrawGemDefs.FreeGold1, 'decompose': decompose})
		if not handlerInput:
			return
		return handlerInput

	def getDrawChipInput(self):
		'''
		?????????
		'''
		handlerInput = []
		flags = self.game.role.assistant_flags.get(DailyAssistantDefs.Draw, {})
		up = flags.get(DailyAssistantDefs.DrawChip, [])
		if len(up) != len(set(up)):
			return
		if len(up) > ConstDefs.chipUpLimit:
			return
		if self.game.dailyRecord.chip_rmb_dc1_free_count <= 0:
			handlerInput.append({'drawType': DrawChipDefs.Free1, 'up': up})
		if self.game.dailyRecord.chip_item_dc1_free_count <= 0:
			handlerInput.append({'drawType': DrawChipDefs.FreeItem1, 'up': up})
		if not handlerInput:
			return
		return handlerInput

	# ????????????
	def getUnionRedpacketInput(self):
		'''
		??????????????????
		'''
		role = self.game.role
		if not role.union_db_id:
			return
		if not self.game.union.isFeatureOpen(UnionDefs.RedPacket):
			return
		if role.inUnionQuitCD():
			return
		handlerInput = [{}]
		return handlerInput

	def getUnionDailyGiftInput(self):
		'''
		??????????????????
		'''
		role = self.game.role
		if not role.union_db_id:
			return
		if not self.game.union.isFeatureOpen(UnionDefs.DailyGift):
			return
		if role.inUnionQuitCD():
			return
		if self.game.dailyRecord.union_daily_gift_times >= 1:
			return
		handlerInput = [{}]
		return handlerInput

	def getTrainerAwardInput(self):
		'''
		???????????????????????????
		'''
		if self.game.dailyRecord.trainer_gift_times > 0:
			return
		handlerInput = [{}]
		return handlerInput

	def getGainGoldInput(self):
		'''
		??????
		'''
		handlerInput = []
		role = self.game.role
		freeTimes = self.game.dailyRecord.lianjin_free_times
		totalLimitTimes = role.lianJinTimes + role.freeLianJinTimes  # ??????????????????
		lianjinTimes = self.game.dailyRecord.lianjin_times  # ????????????
		if lianjinTimes >= totalLimitTimes:
			return
		# ???????????????????????????
		if freeTimes >= role.freeLianJinTimes:
			costRMB = ObjectCostCSV.getLianJinCost(lianjinTimes - freeTimes)
			if costRMB > 0:
				return

		# ???????????????
		count = role.freeLianJinTimes - freeTimes
		# ?????????0 ???????????????
		costList = ObjectCostCSV.CostMap[CostDefs.LianJinCost]
		for rmb in costList:
			if rmb == 0:
				count += 1
		if count <= 0:
			return
		handlerInput.append({'count': count})
		return handlerInput

	# ????????????
	def getCraftSignupInput(self):
		'''
		??????????????????
		'''
		role = self.game.role
		if not ObjectCraftInfoGlobal.isRoleOpen(role.level):
			return
		if self.game.dailyRecord.craft_sign_up:
			return
		return [{}]

	def getUnionFightSignupInput(self):
		'''
		???????????????
		'''
		role = self.game.role
		if not ObjectUnionFightGlobal.isRoleOpen(self.game):
			return
		if not ObjectUnionFightGlobal.isRoleJionTime(role.union_quit_time):
			return
		if self.game.dailyRecord.union_fight_sign_up:
			return
		return [{}]

	def getCrossCraftSignupInput(self):
		'''
		????????????????????????
		'''
		role = self.game.role
		if not ObjectCrossCraftGameGlobal.isOpen(role.areaKey):
			return
		if not ObjectCrossCraftGameGlobal.isRoleOpen(role.level):
			return
		if ObjectCrossCraftGameGlobal.isSigned(self.game):
			return
		return [{}]

	# ????????????
	def getUnionContribInput(self):
		'''
		????????????
		'''
		role = self.game.role
		if not role.union_db_id:
			return
		if not self.game.union.isFeatureOpen(UnionDefs.Contribute):
			return
		if self.game.role.inUnionQuitCD():
			return
		idx = role.daily_assistant.get("union_contrib", 1)
		cfg = csv.union.contrib[idx]
		# ??????VIP
		if role.vip_level < cfg.vipNeed:
			return
		handlerInput = []
		levelCsv = csv.union.union_level[role.union_level]
		count = levelCsv.ContribMax - self.game.dailyRecord.union_contrib_times
		if count <= 0:
			return
		# ????????????????????????
		cost = ObjectCostAux(self.game, {})
		for i in xrange(count):
			cost += ObjectCostAux(self.game, cfg.cost)
			if not cost.isEnough():
				break
			# ??????????????????????????????
			handlerInput.append({'idx': idx})
		return handlerInput

	def getUnionFragDonateInput(self):
		'''
		????????????????????????
		'''
		role = self.game.role
		if not role.union_db_id:
			return
		if not self.game.union.isFeatureOpen(UnionDefs.FragDonate):
			return
		if role.inUnionQuitCD():
			return
		cardCsvID = role.daily_assistant.get("union_frag_donate_card_id", 0)  # cardCsvID
		if not cardCsvID:
			return
		if self.game.dailyRecord.union_frag_donate_start_times > 0:
			return
		fragID = csv.cards[cardCsvID].fragID
		if csv.fragments[fragID].donateType == 0:
			return
		handlerInput = []
		if self.game.cards.isExistedByCsvID(cardCsvID):
			cards = self.game.cards.getCardsByCsvID(cardCsvID)
			if len(cards) > 0:
				handlerInput.append({'cardID': cards[0].id})
		if len(handlerInput) <= 0:
			return
		return handlerInput

	def getUnionTrainingSpeedupInput(self):
		'''
		?????????????????????
		'''
		role = self.game.role
		if not role.union_db_id:
			return
		if not self.game.union.isFeatureOpen(UnionDefs.Training):
			return
		if role.inUnionQuitCD():
			return
		if self.game.dailyRecord.union_training_speedup >= UnionTrainingSpeedUpMax:
			return
		return [{}]

	# ????????????
	def getHuodongFubenInput(self):
		'''
		????????????
		'''
		handlerInput = []
		# ?????????????????????4???
		dailyFubens = [HuoDongDefs.TypeGold, HuoDongDefs.TypeExp, HuoDongDefs.TypeFrag, HuoDongDefs.TypeGift]
		huoDongOpens = self.game.role.getHuoDongOpens()
		for huodongID, flag in huoDongOpens.iteritems():
			if flag:
				cfgHuodong = csv.huodong[huodongID]
				if cfgHuodong.huodongType not in dailyFubens:
					continue
				obj = ObjectHuoDongFactory.getOpenConfig(huodongID)
				yet = self.game.role.huodongs.get(obj.getPeriodDateInt(), {}).get(huodongID, {}).get('times', 0)
				# ???????????? ??????????????????
				yyID = None
				addTimes = 0
				if cfgHuodong.huodongType == HuoDongDefs.TypeGold:
					addTimes += self.game.trainer.huodongTypeGoldTimes
					addTimes += self.game.privilege.huodongGoldTimes
					yyID = ObjectYYHuoDongFactory.getDoubleDropOpenID(YYHuoDongDefs.DoubleCountGold)
				elif cfgHuodong.huodongType == HuoDongDefs.TypeExp:
					addTimes += self.game.trainer.huodongTypeExpTimes
					addTimes += self.game.privilege.huodongExpTimes
					yyID = ObjectYYHuoDongFactory.getDoubleDropOpenID(YYHuoDongDefs.DoubleCountExp)
				elif cfgHuodong.huodongType == HuoDongDefs.TypeGift:
					addTimes += self.game.trainer.huodongTypeGiftTimes
					addTimes += self.game.privilege.huodongGiftTimes
					yyID = ObjectYYHuoDongFactory.getDoubleDropOpenID(YYHuoDongDefs.DoubleCountGift)
				elif cfgHuodong.huodongType == HuoDongDefs.TypeFrag:
					addTimes += self.game.trainer.huodongTypeFragTimes
					addTimes += self.game.privilege.huodongFragTimes
					yyID = ObjectYYHuoDongFactory.getDoubleDropOpenID(YYHuoDongDefs.DoubleCountFrag)
				if yyID:
					addTimes += csv.yunying.yyhuodong[yyID].paramMap['count']
				# ???????????? ????????????
				reunionTimes = 0
				if cfgHuodong.huodongType in [HuoDongDefs.TypeGold, HuoDongDefs.TypeExp, HuoDongDefs.TypeGift, HuoDongDefs.TypeFrag]:
					cfg = ObjectYYHuoDongFactory.getReunionCatchUpCfg(self.game.role, ReunionDefs.HuodongCount)
					if self.game.role.canReunionCatchUp(cfg):
						reunionTimes = cfg.params['count']
				# ??????????????????
				freeTimes = (obj.times + addTimes + reunionTimes) - yet
				if freeTimes <= 0:
					continue
				gateMap = self.game.role.huodongs_gate.get(huodongID, {})
				# ??????????????????
				maxGateID = 0
				role = self.game.role
				# ???????????? ?????????3??????????????????????????? ????????????
				if cfgHuodong.huodongType == HuoDongDefs.TypeFrag:
					gateGroup = csv.huodong_gate_fragment[ObjectServerGlobalRecord.Singleton.huodong_frag_group].gateGroup
					for gateID in gateGroup:
						index = role.HuoDongGateIndexMap[huodongID][gateID]
						if index + 1 < len(gateGroup):
							nextGateID = gateGroup[index + 1]
							if role.getHuoDongGateStar(huodongID, gateID) == 3 and role.level >= csv.scene_conf[nextGateID].openLevel:
								maxGateID = max(gateID, maxGateID)
				elif cfgHuodong.huodongType == HuoDongDefs.TypeGift:
					if ObjectServerGlobalRecord.Singleton.huodong_gift_group == HuoDongDefs.huodongGiftGroup1:
						gateGroup = cfgHuodong['gateSeq']
					else:
						gateGroup = cfgHuodong['gateSeq%d' % ObjectServerGlobalRecord.Singleton.huodong_gift_group]
					for gateID in gateGroup:
						if role.getHuoDongGateStar(huodongID, gateID) == 3:
							maxGateID = max(gateID, maxGateID)
				else:
					for gateID, star in gateMap.iteritems():
						if star == 3:  # 3???????????????
							maxGateID = max(gateID, maxGateID)
				if maxGateID:
					handlerInput.append({'huodongID': huodongID, 'gateID': maxGateID, 'times': freeTimes})
		if len(handlerInput) <= 0:
			return
		return handlerInput

	def getEndlessInput(self):
		'''
		???????????????
		'''
		role = self.game.role
		handlerInput = []
		# ????????????????????????
		if role.endless_tower_current <= role.endless_tower_max_gate:  # ???????????????
			handlerInput.append({})

		# ???????????????????????? ?????????????????????
		autoReset = role.daily_assistant.get("endless_buy_reset", 0)

		# ?????????????????????
		resetTimes = self.game.dailyRecord.endless_tower_reset_times
		if (resetTimes >= role.endlessTowerResetTimes) or (not autoReset):
			return handlerInput

		freeResetTimes = role.endlessTowerResetTimes - resetTimes
		cost = ObjectCostAux(self.game, {})
		for i in xrange(freeResetTimes):
			rmb = ObjectCostCSV.getEndlessTowerResetTimesCost(resetTimes+i)
			if rmb > 0:
				flags = role.assistant_flags.get(DailyAssistantDefs.Fuben, {})
				if not flags.get(DailyAssistantDefs.Endless, 0):
					break
				cost += ObjectCostAux(self.game, {'rmb': rmb})
				if not cost.isEnough():
					break
			handlerInput.append({})
		if len(handlerInput) <= 0:
			return
		return handlerInput

	def getFishingInput(self):
		'''
		?????? ??????
		'''
		if self.game.fishing.is_auto:
			return
		if self.game.dailyRecord.fishing_counter >= ConstDefs.fishingDailyTimes:
			return
		fishing = self.game.fishing
		if fishing.select_scene <= 0:
			return
		sceneCfg = csv.fishing.scene[fishing.select_scene]
		if not sceneCfg:
			return
		if sceneCfg.type == fishing.PlaySceneType and not ObjectCrossFishingGameGlobal.isOpen(self.game.role.areaKey):
			return
		if fishing.select_rod <= 0:
			return
		# ???????????????????????????
		if not self.game.items.isEnough({fishing.rodItemID: 1}):
			return
		if fishing.select_bait <= 0:
			return
		baitCfg = csv.fishing.bait[fishing.select_bait]
		if not self.game.items.isEnough({baitCfg.itemId: 1}):
			return
		# ?????????????????????
		if baitCfg.scene and fishing.select_scene not in baitCfg.scene:
			return
		if ObjectCrossFishingGameGlobal.isOpen(self.game.role.areaKey):
			# ????????????????????????????????????
			fishingSkip = self.game.role.daily_assistant.get("fishing_skip", 0)
			if fishingSkip:
				return
		handlerInput = [{}]
		return handlerInput
