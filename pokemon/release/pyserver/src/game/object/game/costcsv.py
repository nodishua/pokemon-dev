#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2014 YouMi Information Technology Inc.
'''

from framework.csv import csv
from framework.object import ReloadHooker

from game.object import CostDefs

#
# ObjectCostCSV
#

class ObjectCostCSV(ReloadHooker):

	CostMap = {}

	@classmethod
	def classInit(cls):
		for idx in csv.cost:
			cfg = csv.cost[idx]
			if len(cfg.service) == 0:
				continue
			cls.CostMap[cfg.service] = cfg

		cls._initPVPShopRefreshCost()
		cls._initPWBuyCost()
		cls._initStaminaBuyCost()
		cls._initHeroGateBuyCost()
		cls._initPWCDBuyCost()
		cls._initLianJinCost()
		cls._initLianJinGoldRate()
		cls._initUnionShopRefreshCost()
		cls._initSkillPointBuyCost()
		cls._initPvpEnermysFreshCost()
		cls._initMysteryShopRefreshCost()
		cls._initRenameCost()
		cls._initSignInBuyCost()
		cls._initCardbagBuyCost()
		cls._initFixShopRefreshCost()
		cls._initExplorerShopRefreshCost()
		cls._initFragShopRefreshCost()
		cls._initRandomTowerShopRefreshCost()
		cls._initRandomTowerBoxCost1()
		cls._initRandomTowerBoxCost2()
		cls._initEndlessTowerResetTimesCost()
		cls._initWorldBossBuyCost()
		cls._initCrossArenaFreshCost()
		cls._initCrossArenaPWBuyCost()
		cls._initFishingShopRefreshCost()
		cls._initMegaItemConvertBuyCost()
		cls._initMegaCommonItemConvertBuyCost()
		cls._initGymTalentPointBuyCost()
		cls._initGymBattleBuyCost()
		cls._initGymTalentResetCost()
		cls._initFigureSkillUnlockCost()
		cls._initEquipDropCost()
		cls._initCrossMineRobBuyCost()
		cls._initCrossMineRevengeBuyCost()
		cls._initCrossMineBossBuyCost()
		cls._initCrossMineEnemyFreshCost()
		cls._initUnionQABuyCost()
		cls._initPlayPassportBuyCost2()
		cls._initPlayPassportBuyCost3()
		cls._initPlayPassportBuyCost4()
		cls._initHuntingBoxCost()
		cls._initDrawCardUpChangeCost()

	@classmethod
	def getSeqCost(cls, idx, times):
		cfg = csv.cost[idx]
		lst = cfg.seqParam
		maxT = min(len(lst) - 1, times)
		return lst[maxT]

	# 固定商店刷新消耗
	@classmethod
	def _initFixShopRefreshCost(cls):
		cfg = cls.CostMap[CostDefs.FixShopRefreshCost]
		cls.CostMap[CostDefs.FixShopRefreshCost] = cfg.seqParam

	@classmethod
	def getFixShopRefreshCost(cls, times):
		lst = cls.CostMap[CostDefs.FixShopRefreshCost]
		maxT = min(len(lst) - 1, times)
		return lst[maxT]

	# 竞技场商店刷新消耗
	@classmethod
	def _initPVPShopRefreshCost(cls):
		cfg = cls.CostMap[CostDefs.PVPShopRefreshCost]
		cls.CostMap[CostDefs.PVPShopRefreshCost] = cfg.seqParam

	@classmethod
	def getPVPShopRefreshCost(cls, times):
		lst = cls.CostMap[CostDefs.PVPShopRefreshCost]
		maxT = min(len(lst) - 1, times)
		return lst[maxT]

	@classmethod
	def _initMysteryShopRefreshCost(cls):
		cfg = cls.CostMap[CostDefs.MysteryShopRefreshCost]
		cls.CostMap[CostDefs.MysteryShopRefreshCost] = cfg.seqParam

	@classmethod
	def getMysteryShopRefreshCost(cls, times):
		lst = cls.CostMap[CostDefs.MysteryShopRefreshCost]
		maxT = min(len(lst) - 1, times)
		return lst[maxT]

	# 排位赛购买次数
	@classmethod
	def _initPWBuyCost(cls):
		cfg = cls.CostMap[CostDefs.PVPPWBuyCost]
		cls.CostMap[CostDefs.PVPPWBuyCost] = cfg.seqParam

	@classmethod
	def getPWBuyCost(cls, times):
		lst = cls.CostMap[CostDefs.PVPPWBuyCost]
		maxT = min(len(lst) - 1, times)
		return lst[maxT]

	# 购买体力次数
	@classmethod
	def _initStaminaBuyCost(cls):
		cfg = cls.CostMap[CostDefs.StaminaBuyCost]
		cls.CostMap[CostDefs.StaminaBuyCost] = cfg.seqParam

	@classmethod
	def getStaminaBuyCost(cls, times):
		lst = cls.CostMap[CostDefs.StaminaBuyCost]
		maxT = min(len(lst) - 1, times)
		return lst[maxT]

	# 购买技能点次数
	@classmethod
	def _initSkillPointBuyCost(cls):
		cfg = cls.CostMap[CostDefs.SkillPointBuyCost]
		cls.CostMap[CostDefs.SkillPointBuyCost] = cfg.seqParam

	@classmethod
	def getSkillPointBuyCost(cls, times):
		lst = cls.CostMap[CostDefs.SkillPointBuyCost]
		maxT = min(len(lst) - 1, times)
		return lst[maxT]

	# 重置精英关卡次数
	@classmethod
	def _initHeroGateBuyCost(cls):
		cfg = cls.CostMap[CostDefs.HeroGateBuyCost]
		cls.CostMap[CostDefs.HeroGateBuyCost] = cfg.seqParam

	@classmethod
	def getHeroGateBuyCost(cls, times):
		lst = cls.CostMap[CostDefs.HeroGateBuyCost]
		maxT = min(len(lst) - 1, times)
		return lst[maxT]

	# 重置排位赛冷却时间
	@classmethod
	def _initPWCDBuyCost(cls):
		cfg = cls.CostMap[CostDefs.PVPPWCDBuyCost]
		cls.CostMap[CostDefs.PVPPWCDBuyCost] = cfg.seqParam

	@classmethod
	def getPWCDBuyCost(cls, times):
		lst = cls.CostMap[CostDefs.PVPPWCDBuyCost]
		maxT = min(len(lst) - 1, times)
		return lst[maxT]

	# 炼金次数
	@classmethod
	def _initLianJinCost(cls):
		cfg = cls.CostMap[CostDefs.LianJinCost]
		cls.CostMap[CostDefs.LianJinCost] = cfg.seqParam

	@classmethod
	def getLianJinCost(cls, times):
		lst = cls.CostMap[CostDefs.LianJinCost]
		maxT = min(len(lst) - 1, times)
		return lst[maxT]

	# 炼金按次数的数量修正
	@classmethod
	def _initLianJinGoldRate(cls):
		cfg = cls.CostMap[CostDefs.LianJinGoldRate]
		cls.CostMap[CostDefs.LianJinGoldRate] = cfg.seqParam

	@classmethod
	def getLianJinGoldRate(cls, times):
		lst = cls.CostMap[CostDefs.LianJinGoldRate]
		maxT = min(len(lst) - 1, times)
		return lst[maxT]

	# 公会商店刷新消耗
	@classmethod
	def _initUnionShopRefreshCost(cls):
		cfg = cls.CostMap[CostDefs.UnionShopRefreshCost]
		cls.CostMap[CostDefs.UnionShopRefreshCost] = cfg.seqParam

	@classmethod
	def getUnionShopRefreshCost(cls, times):
		lst = cls.CostMap[CostDefs.UnionShopRefreshCost]
		maxT = min(len(lst) - 1, times)
		return lst[maxT]

	# 竞技场换一批消费
	@classmethod
	def _initPvpEnermysFreshCost(cls):
		cfg = cls.CostMap[CostDefs.PvpEnermysFreshCost]
		cls.CostMap[CostDefs.PvpEnermysFreshCost] = cfg.seqParam

	@classmethod
	def getPvpEnermysFreshCost(cls, times):
		lst = cls.CostMap[CostDefs.PvpEnermysFreshCost]
		maxT = min(len(lst) - 1, times)
		return lst[maxT]

	# 角色改名
	@classmethod
	def _initRenameCost(cls):
		cfg = cls.CostMap[CostDefs.RenameCost]
		cls.CostMap[CostDefs.RenameCost] = cfg.seqParam

	@classmethod
	def getRenameCost(cls, times):
		lst = cls.CostMap[CostDefs.RenameCost]
		maxT = min(len(lst) - 1, times)
		return lst[maxT]

	# 签到补签
	@classmethod
	def _initSignInBuyCost(cls):
		cfg = cls.CostMap[CostDefs.SignInBuy]
		cls.CostMap[CostDefs.SignInBuy] = cfg.seqParam

	@classmethod
	def getSignInBuyCost(cls, times):
		lst = cls.CostMap[CostDefs.SignInBuy]
		maxT = min(len(lst) - 1, times)
		return lst[maxT]

	# 卡牌背包对应次数购买消耗
	@classmethod
	def _initCardbagBuyCost(cls):
		cfg = cls.CostMap[CostDefs.CardbagBuyCost]
		cls.CostMap[CostDefs.CardbagBuyCost] = cfg.seqParam

	@classmethod
	def getCardbagBuyCost(cls, times):
		lst = cls.CostMap[CostDefs.CardbagBuyCost]
		maxT = min(len(lst) - 1, times)
		return lst[maxT]

	# 寻宝商店刷新消耗
	@classmethod
	def _initExplorerShopRefreshCost(cls):
		cfg = cls.CostMap[CostDefs.ExplorerShopRefreshCost]
		cls.CostMap[CostDefs.ExplorerShopRefreshCost] = cfg.seqParam

	@classmethod
	def getExplorerShopRefreshCost(cls, times):
		lst = cls.CostMap[CostDefs.ExplorerShopRefreshCost]
		maxT = min(len(lst) - 1, times)
		return lst[maxT]

	# 碎片商店刷新消耗
	@classmethod
	def _initFragShopRefreshCost(cls):
		cfg = cls.CostMap[CostDefs.FragShopRefreshCost]
		cls.CostMap[CostDefs.FragShopRefreshCost] = cfg.seqParam

	@classmethod
	def getFragShopRefreshCost(cls, times):
		lst = cls.CostMap[CostDefs.FragShopRefreshCost]
		maxT = min(len(lst) - 1, times)
		return lst[maxT]

	# 随机塔商店刷新消耗
	@classmethod
	def _initRandomTowerShopRefreshCost(cls):
		cfg = cls.CostMap[CostDefs.RandomTowerShopRefreshCost]
		cls.CostMap[CostDefs.RandomTowerShopRefreshCost] = cfg.seqParam

	@classmethod
	def getRandomTowerShopRefreshCost(cls, times):
		lst = cls.CostMap[CostDefs.RandomTowerShopRefreshCost]
		maxT = min(len(lst) - 1, times)
		return lst[maxT]

	# 试炼普通宝箱加开消耗
	@classmethod
	def _initRandomTowerBoxCost1(cls):
		cfg = cls.CostMap[CostDefs.RandomTowerBoxCost1]
		cls.CostMap[CostDefs.RandomTowerBoxCost1] = cfg.seqParam

	@classmethod
	def getRandomTowerBoxCost1(cls, times):
		lst = cls.CostMap[CostDefs.RandomTowerBoxCost1]
		maxT = min(len(lst) - 1, times)
		return lst[maxT]

	# 试炼豪华宝箱加开消耗
	@classmethod
	def _initRandomTowerBoxCost2(cls):
		cfg = cls.CostMap[CostDefs.RandomTowerBoxCost2]
		cls.CostMap[CostDefs.RandomTowerBoxCost2] = cfg.seqParam

	@classmethod
	def getRandomTowerBoxCost2(cls, times):
		lst = cls.CostMap[CostDefs.RandomTowerBoxCost2]
		maxT = min(len(lst) - 1, times)
		return lst[maxT]

	# 冒险之路重置次数
	@classmethod
	def _initEndlessTowerResetTimesCost(cls):
		cfg = cls.CostMap[CostDefs.EndlessTowerResetTimesCost]
		cls.CostMap[CostDefs.EndlessTowerResetTimesCost] = cfg.seqParam

	@classmethod
	def getEndlessTowerResetTimesCost(cls, times):
		lst = cls.CostMap[CostDefs.EndlessTowerResetTimesCost]
		maxT = min(len(lst) - 1, times)
		return lst[maxT]

	# 世界boss购买次数
	@classmethod
	def _initWorldBossBuyCost(cls):
		cfg = cls.CostMap[CostDefs.WorldBossBuyCost]
		cls.CostMap[CostDefs.WorldBossBuyCost] = cfg.seqParam

	@classmethod
	def getWorldBossBuyCost(cls, times):
		lst = cls.CostMap[CostDefs.WorldBossBuyCost]
		maxT = min(len(lst) - 1, times)
		return lst[maxT]

	# 跨服竞技场更换对手
	@classmethod
	def _initCrossArenaFreshCost(cls):
		cfg = cls.CostMap[CostDefs.CrossArenaFreshCost]
		cls.CostMap[CostDefs.CrossArenaFreshCost] = cfg.seqParam

	@classmethod
	def getCrossArenaFreshCost(cls, times):
		lst = cls.CostMap[CostDefs.CrossArenaFreshCost]
		maxT = min(len(lst) - 1, times)
		return lst[maxT]

	# 跨服竞技场排位赛购买次数
	@classmethod
	def _initCrossArenaPWBuyCost(cls):
		cfg = cls.CostMap[CostDefs.CrossArenaPWBuyCost]
		cls.CostMap[CostDefs.CrossArenaPWBuyCost] = cfg.seqParam

	@classmethod
	def getCrossArenaPWBuyCost(cls, times):
		lst = cls.CostMap[CostDefs.CrossArenaPWBuyCost]
		maxT = min(len(lst) - 1, times)
		return lst[maxT]

	# 钓鱼商店刷新消耗
	@classmethod
	def _initFishingShopRefreshCost(cls):
		cfg = cls.CostMap[CostDefs.FishingShopRefreshCost]
		cls.CostMap[CostDefs.FishingShopRefreshCost] = cfg.seqParam

	@classmethod
	def getFishingShopRefreshCost(cls, times):
		lst = cls.CostMap[CostDefs.FishingShopRefreshCost]
		maxT = min(len(lst) - 1, times)
		return lst[maxT]

	# 进化石转化次数购买
	@classmethod
	def _initMegaItemConvertBuyCost(cls):
		cfg = cls.CostMap[CostDefs.MegaItemConvertCost]
		cls.CostMap[CostDefs.MegaItemConvertCost] = cfg.seqParam

	@classmethod
	def getMegaItemConvertBuyCost(cls, times):
		lst = cls.CostMap[CostDefs.MegaItemConvertCost]
		maxT = min(len(lst) - 1, times)
		return lst[maxT]

	# 钥石转化次数购买
	@classmethod
	def _initMegaCommonItemConvertBuyCost(cls):
		cfg = cls.CostMap[CostDefs.MegaCommonItemConvertCost]
		cls.CostMap[CostDefs.MegaCommonItemConvertCost] = cfg.seqParam

	@classmethod
	def getMegaCommonItemConvertBuyCost(cls, times):
		lst = cls.CostMap[CostDefs.MegaCommonItemConvertCost]
		maxT = min(len(lst) - 1, times)
		return lst[maxT]

	# 道馆挑战加成点数购买
	@classmethod
	def _initGymTalentPointBuyCost(cls):
		cfg = cls.CostMap[CostDefs.GymTalentPointBuyCost]
		cls.CostMap[CostDefs.GymTalentPointBuyCost] = cfg.seqParam

	@classmethod
	def getGymTalentPointBuyCost(cls, times):
		lst = cls.CostMap[CostDefs.GymTalentPointBuyCost]
		maxT = min(len(lst) - 1, times)
		return lst[maxT]

	# 道馆副本挑战购买
	@classmethod
	def _initGymBattleBuyCost(cls):
		cfg = cls.CostMap[CostDefs.GymBattleBuyCost]
		cls.CostMap[CostDefs.GymBattleBuyCost] = cfg.seqParam

	@classmethod
	def getGymBattleBuyCost(cls, times):
		lst = cls.CostMap[CostDefs.GymBattleBuyCost]
		maxT = min(len(lst) - 1, times)
		return lst[maxT]

	# 道馆挑战加成点数购买
	@classmethod
	def _initGymTalentResetCost(cls):
		cfg = cls.CostMap[CostDefs.GymTalentResetCost]
		cls.CostMap[CostDefs.GymTalentResetCost] = cfg.seqParam

	@classmethod
	def getGymTalentResetCost(cls, times):
		lst = cls.CostMap[CostDefs.GymTalentResetCost]
		maxT = min(len(lst) - 1, times)
		return lst[maxT]

	# 形象技能栏位解锁
	@classmethod
	def _initFigureSkillUnlockCost(cls):
		cfg = cls.CostMap[CostDefs.FigureSkillUnlockCost]
		cls.CostMap[CostDefs.FigureSkillUnlockCost] = cfg.seqParam

	@classmethod
	def getFigureSkillUnlockCost(cls, times):
		lst = cls.CostMap[CostDefs.FigureSkillUnlockCost]
		maxT = min(len(lst) - 1, times)
		return lst[maxT]

	# 饰品降星/降阶
	@classmethod
	def _initEquipDropCost(cls):
		cfg = cls.CostMap[CostDefs.EquipDropCost]
		cls.CostMap[CostDefs.EquipDropCost] = cfg.seqParam

	@classmethod
	def getEquipDropCost(cls, times):
		lst = cls.CostMap[CostDefs.EquipDropCost]
		maxT = min(len(lst) - 1, times)
		return lst[maxT]

	# 跨服资源战购买抢夺次数
	@classmethod
	def _initCrossMineRobBuyCost(cls):
		cfg = cls.CostMap[CostDefs.CrossMineRobCost]
		cls.CostMap[CostDefs.CrossMineRobCost] = cfg.seqParam

	@classmethod
	def getCrossMineRobBuyCost(cls, times):
		lst = cls.CostMap[CostDefs.CrossMineRobCost]
		maxT = min(len(lst) - 1, times)
		return lst[maxT]

	# 跨服资源战购买报仇次数
	@classmethod
	def _initCrossMineRevengeBuyCost(cls):
		cfg = cls.CostMap[CostDefs.CrossMineRevengeCost]
		cls.CostMap[CostDefs.CrossMineRevengeCost] = cfg.seqParam

	@classmethod
	def getCrossMineRevengeBuyCost(cls, times):
		lst = cls.CostMap[CostDefs.CrossMineRevengeCost]
		maxT = min(len(lst) - 1, times)
		return lst[maxT]

	# 跨服资源战购买 Boss 挑战次数
	@classmethod
	def _initCrossMineBossBuyCost(cls):
		cfg = cls.CostMap[CostDefs.CrossMineBossCost]
		cls.CostMap[CostDefs.CrossMineBossCost] = cfg.seqParam

	@classmethod
	def getCrossMineBossBuyCost(cls, times):
		lst = cls.CostMap[CostDefs.CrossMineBossCost]
		maxT = min(len(lst) - 1, times)
		return lst[maxT]

	# 跨服资源战购买更换对手次数
	@classmethod
	def _initCrossMineEnemyFreshCost(cls):
		cfg = cls.CostMap[CostDefs.CrossMineEnemyFreshCost]
		cls.CostMap[CostDefs.CrossMineEnemyFreshCost] = cfg.seqParam

	@classmethod
	def getCrossMineEnemyFreshCost(cls, times):
		lst = cls.CostMap[CostDefs.CrossMineEnemyFreshCost]
		maxT = min(len(lst) - 1, times)
		return lst[maxT]

	# 公会问答次数购买消耗
	@classmethod
	def _initUnionQABuyCost(cls):
		cfg = cls.CostMap[CostDefs.UnionQABuyCost]
		cls.CostMap[CostDefs.UnionQABuyCost] = cfg.seqParam

	@classmethod
	def getUnionQABuyCost(cls, times):
		lst = cls.CostMap[CostDefs.UnionQABuyCost]
		maxT = min(len(lst) - 1, times)
		return lst[maxT]

	# 玩法通行证等级购买次数消耗 PlayPassportDefs.DailyTask
	@classmethod
	def _initPlayPassportBuyCost2(cls):
		cfg = cls.CostMap[CostDefs.PlayPassportBuyCost2]
		cls.CostMap[CostDefs.PlayPassportBuyCost2] = cfg.seqParam

	@classmethod
	def getPlayPassportBuyCost2(cls, times):
		lst = cls.CostMap[CostDefs.PlayPassportBuyCost2]
		maxT = min(len(lst) - 1, times)
		return lst[maxT]

	# 玩法通行证等级购买次数消耗 PlayPassportDefs.RandomTower
	@classmethod
	def _initPlayPassportBuyCost3(cls):
		cfg = cls.CostMap[CostDefs.PlayPassportBuyCost3]
		cls.CostMap[CostDefs.PlayPassportBuyCost3] = cfg.seqParam

	@classmethod
	def getPlayPassportBuyCost3(cls, times):
		lst = cls.CostMap[CostDefs.PlayPassportBuyCost3]
		maxT = min(len(lst) - 1, times)
		return lst[maxT]

	# 玩法通行证等级购买次数消耗 PlayPassportDefs.Gym
	@classmethod
	def _initPlayPassportBuyCost4(cls):
		cfg = cls.CostMap[CostDefs.PlayPassportBuyCost4]
		cls.CostMap[CostDefs.PlayPassportBuyCost4] = cfg.seqParam

	@classmethod
	def getPlayPassportBuyCost4(cls, times):
		lst = cls.CostMap[CostDefs.PlayPassportBuyCost4]
		maxT = min(len(lst) - 1, times)
		return lst[maxT]

	# 远征宝箱打开消耗
	@classmethod
	def _initHuntingBoxCost(cls):
		cfg = cls.CostMap[CostDefs.HuntingBoxCost]
		cls.CostMap[CostDefs.HuntingBoxCost] = cfg.seqParam

	@classmethod
	def getHuntingBoxCost(cls, times):
		lst = cls.CostMap[CostDefs.HuntingBoxCost]
		maxT = min(len(lst) - 1, times)
		return lst[maxT]

	# 自选限定抽卡切换消耗
	@classmethod
	def _initDrawCardUpChangeCost(cls):
		cfg = cls.CostMap[CostDefs.DrawCardUpChangeCost]
		cls.CostMap[CostDefs.DrawCardUpChangeCost] = cfg.seqParam

	@classmethod
	def getDrawCardUpChangeCost(cls, times):
		lst = cls.CostMap[CostDefs.DrawCardUpChangeCost]
		maxT = min(len(lst) - 1, times)
		return lst[maxT]
