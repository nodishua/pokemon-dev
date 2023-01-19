#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2014 YouMi Information Technology Inc.
'''
from framework import nowtime_t
from framework.csv import csv
from framework.log import logger
from framework.object import ObjectBase

from game.object import FeatureDefs, AchievementDefs, MapDefs, HuoDongDefs, GemDefs
from game.object.game import ObjectMap
from game.object.game.gain import ObjectGainAux
from game.object.game.levelcsv import ObjectFeatureUnlockCSV


#
# ObjectAchievement
#

class ObjectAchievement(ObjectBase):
	def __init__(self, game, achieveID):
		ObjectBase.__init__(self, game)
		self._achieveID = achieveID
		self._csv = csv.achievement.achievement_task[achieveID]
		self._DB = self.game.role.achievement_tasks  # {csv_id: (flag, time)} (可领:1  已领: 0)

	@property
	def id(self):
		return self._achieveID

	@property
	def type(self):
		return self._csv.type

	@property
	def targetType(self):
		return self._csv.targetType

	@property
	def targetArg(self):
		return self._csv.targetArg

	@property
	def targetArg2(self):
		return self._csv.targetArg2

	@property
	def yyID(self):
		return self._csv.yyID

	def setAchieved(self):
		'''
		设置 成就任务 状态
		'''
		task = self._DB.get(self.id, None)
		# 只记录 没有达成过的
		if not task:
			self._DB[self.id] = (AchievementDefs.TaskAwardOpenFlag, nowtime_t())

	def hasAchieved(self):
		return self._DB.get(self.id, None) is not None

#
# ObjectAchieveMap
#
class ObjectAchieveMap(ObjectBase):

	WatchTargetMap = {
		# 人物成长
		AchievementDefs.Level: ('Role', 'level'),
		AchievementDefs.TrainerLevel: ('Role', 'trainer_level'),
		AchievementDefs.TrainerPrivilege: ('Role', 'trainer_attr_skills'),
		AchievementDefs.TalentOne: ('Role', 'talent_trees'),
		AchievementDefs.TalentAll: ('Role', 'talent_trees'),
		AchievementDefs.ExplorerActiveCount: ('Role', 'explorers'),
		AchievementDefs.ExplorerActive: ('Role', 'explorers'),
		AchievementDefs.ExplorerLevel: ('Role', 'explorers'),
		AchievementDefs.FightingPoint: ('Role', 'top6_fighting_point'),
		AchievementDefs.CostRmbCount: ('Role', 'rmb_consume'),
		AchievementDefs.SignInDays: ('Role', 'sign_in_days'),
		# 精灵收集
		AchievementDefs.CardCount: ('Role', 'pokedex'),
		AchievementDefs.CardNatureCount: ('Role', 'pokedex'),
		AchievementDefs.CardCsvIDCount: ('Role', 'pokedex'),
		# 精灵成长
		AchievementDefs.CardAdvanceCount: ('RoleCard', 'advance'),
		AchievementDefs.CardLevelCount: ('RoleCard', 'level'),
		AchievementDefs.CardStarCount: ('RoleCard', 'star'),
		AchievementDefs.EquipAdvanceCount: ('RoleCard', 'equips'),
		AchievementDefs.EquipAwakeCount: ('RoleCard', 'equips'),
		AchievementDefs.HeldItemLevelCount: ('RoleHeldItem', 'level'),
		AchievementDefs.HeldItemQualityCount: ('Role', 'held_items'),
		AchievementDefs.FeelLevelCount: ('Role', 'card_feels'),
		AchievementDefs.CardNvalueCount: ('RoleCard', 'nvalue'),
		AchievementDefs.CardGemQualitySum: ('RoleCard', 'gems'),
		AchievementDefs.CardMarkIDStar: ('RoleCard', 'star'),
		# 副本活动
		AchievementDefs.GateStarCount: ('Role', 'gate_star'),
		AchievementDefs.GatePass: ('Role', 'gate_star'),
		AchievementDefs.HeroGateStarCount: ('Role', 'gate_star'),
		AchievementDefs.HeroGatePass: ('Role', 'gate_star'),
		AchievementDefs.EndlessTowerPass: ('Role', 'endless_tower_max_gate'),
		AchievementDefs.ArenaRank: ('Role', 'pw_rank'),
		AchievementDefs.FishingLevel: ('Fishing', 'level'),
		AchievementDefs.FishCount: ('Fishing', 'fish'),
		AchievementDefs.FishTypeCount: ('Fishing', 'fish'),
		# 社交
		AchievementDefs.FriendCount: ('Society', 'friends'),
		# 隐藏任务
		AchievementDefs.TitleCount: ('Role', 'titles'),
		AchievementDefs.FigureCount: ('Role', 'figures'),
		AchievementDefs.FrameCount: ('Role', 'frames'),
	}
	WatchModelMap = {}  # {model:{column: [target]}}
	TargetMap = {}  # {targetType : {targetType2: [csvId, ...]}}

	# 监听 但需多处onTargetTypeCount触发的类型
	MoreWatchTargetList = [
		AchievementDefs.LogoCount,
		AchievementDefs.StaminaCount,
		AchievementDefs.MailCount,
		AchievementDefs.GoldHuodongPassType,
		AchievementDefs.ExpHuodongPassType,
		AchievementDefs.GiftHuodongPassType,
		AchievementDefs.FragHuodongPassType,
		AchievementDefs.CardGemQualitySum,
	]

	AchievementLevelMap = {}  # {type: [csvId, ...]}
	AchievementTaskMap = {}  # {type: [csvId, ...]}

	@classmethod
	def classInit(cls):
		cls.WatchModelMap = {}
		for target, mc in cls.WatchTargetMap.iteritems():  # 实现WatchModelMap结构 {model: {column: [target]}}
			columnMap = cls.WatchModelMap.setdefault(mc[0], {})
			targetList = columnMap.setdefault(mc[1], [])
			targetList.append(target)

		# 成就等级
		cls.AchievementLevelMap = {}
		for i in csv.achievement.achievement_level:
			cfg = csv.achievement.achievement_level[i]
			if cfg.level <= 0:
				continue
			csvIDs = cls.AchievementLevelMap.get(cfg.type, [])
			csvIDs.append(i)
			cls.AchievementLevelMap[cfg.type] = csvIDs

		# 成就任务
		cls.TargetMap = {}
		cls.AchievementTaskMap = {}
		for i in csv.achievement.achievement_task:
			cfg = csv.achievement.achievement_task[i]
			csvIDs = cls.AchievementTaskMap.get(cfg.type, [])
			csvIDs.append(i)
			cls.AchievementTaskMap[cfg.type] = csvIDs

			cls.TargetMap.setdefault(cfg.targetType, {})
			taskIDs = cls.TargetMap[cfg.targetType].get(cfg.targetType2, [])
			taskIDs.append((i, cfg.sort))
			cls.TargetMap[cfg.targetType][cfg.targetType2] = taskIDs

		for targetType in cls.TargetMap:
			for targetType2 in cls.TargetMap[targetType]:
				l = cls.TargetMap[targetType][targetType2]
				cls.TargetMap[targetType][targetType2] = [item[0] for item in sorted(l, key=lambda x: x[1])]

	def set(self):
		self._unlock = False
		return ObjectBase.set(self)

	def init(self):
		self._unlock = ObjectFeatureUnlockCSV.isOpen(FeatureDefs.achievement, self.game)
		return ObjectBase.init(self)

	def _fixCorrupted(self):
		if not ObjectFeatureUnlockCSV.isOpen(FeatureDefs.achievement, self.game):
			return
		# 处理线上数据 货币计数方式问题
		coinDict = {}
		coinDict[AchievementDefs.GoldCount] = self.game.role.gold
		coinDict[AchievementDefs.RmbCount] = self.game.role.rmb
		coinDict[AchievementDefs.ArenaCoin1Count] = self.game.role.coin1
		for k, v in coinDict.iteritems():
			if not self.game.role.achievement_counter.get(k, 0) and v > 0:
				self.game.role.achievement_counter[k] = v

		# 累计拥有红色品质符石成就
		if self.game.role.achievement_counter.get(AchievementDefs.RedQualityGem, None) is None:
			count = 0
			gems = self.game.gems.getGems(self.game.role.gems)
			for gem in gems:
				cfg = csv.gem.gem[gem.gem_id]
				if cfg.quality == GemDefs.RedQuality:
					count += 1
			if count > 0:
				self.game.achievement.onCount(AchievementDefs.RedQualityGem, count)
			else:
				self.game.role.achievement_counter[AchievementDefs.RedQualityGem] = 0

	def initWatchTarget(self):
		if self._unlock:
			for model, v in self.WatchModelMap.iteritems():
				for column, _ in v.iteritems():
					self.onWatch(model, column)

			for target in self.MoreWatchTargetList:
				self.onTargetTypeCount(target)

			# TODO 特写处理石英报名目标改小 登录自动刷新，下周删除
			targetType = AchievementDefs.CraftBattle
			count = self.game.role.achievement_counter.get(targetType, 0)
			for targetType2 in ObjectAchieveMap.TargetMap[targetType]:
				for csvID in ObjectAchieveMap.TargetMap[targetType][targetType2]:
					achieveObj = ObjectAchievement(self.game, csvID)
					if achieveObj.hasAchieved():
						continue
					if count >= achieveObj.targetArg:
						achieveObj.setAchieved()
					else:
						break

	def onWatch(self, model, column):
		if not ObjectFeatureUnlockCSV.isOpen(FeatureDefs.achievement, self.game):
			return
		# 监控每次变化  不是WatchTargetMap条件的变化 就直接return掉
		if model not in self.WatchModelMap or column not in self.WatchModelMap[model]:
			return
		targetTypes = self.WatchModelMap[model][column]
		for targetType in targetTypes:
			self.onTargetTypeCount(targetType)

	def onTargetTypeCount(self, targetType):
		if not ObjectFeatureUnlockCSV.isOpen(FeatureDefs.achievement, self.game):
			return
		if targetType not in self.TargetMap:
			return
		for targetType2 in self.TargetMap[targetType]:
			for achieveID in self.TargetMap[targetType][targetType2]:
				achieveObj = ObjectAchievement(self.game, achieveID)
				if achieveObj.hasAchieved():
					continue
				flag = self.achievementTaskCount(achieveObj.targetType, achieveObj.targetArg, achieveObj.targetArg2)
				if flag:
					achieveObj.setAchieved()
				else:
					break

	def onLevelUp(self):
		if self._unlock:
			return
		self._unlock = ObjectFeatureUnlockCSV.isOpen(FeatureDefs.achievement, self.game)
		if self._unlock:
			self.init()

	def onCount(self, targetType, n):
		if not ObjectFeatureUnlockCSV.isOpen(FeatureDefs.achievement, self.game):
			return
		if n <= 0:
			return
		if targetType not in ObjectAchieveMap.TargetMap:
			return

		oldCount = self.game.role.achievement_counter.get(targetType, 0)
		count = oldCount + n
		self.game.role.achievement_counter[targetType] = count
		for targetType2 in ObjectAchieveMap.TargetMap[targetType]:
			for csvID in ObjectAchieveMap.TargetMap[targetType][targetType2]:
				achieveObj = ObjectAchievement(self.game, csvID)
				if achieveObj.hasAchieved():
					continue
				if count >= achieveObj.targetArg:
					achieveObj.setAchieved()
				else:
					break

	def onYYCount(self, yyID, targetType, n, sp):
		'''
		有YYID版本的成就计数
		'''
		if not ObjectFeatureUnlockCSV.isOpen(FeatureDefs.achievement, self.game):
			return
		if n <= 0:
			return
		if targetType not in ObjectAchieveMap.TargetMap:
			return
		role = self.game.role
		from game.object.game import ObjectYYHuoDongFactory
		hdCls = ObjectYYHuoDongFactory.getRoleOpenClass(yyID, role.level, role.created_time, role.vip_level)
		if hdCls is None:
			return
		record = hdCls.getRecord(yyID, self.game)
		count = 0
		# 赛马猜中累计
		if targetType == AchievementDefs.HorseBetRightTimes:
			horseRace = record.setdefault('horse_race', {})
			achievementCounter = horseRace.setdefault('achievement_counter', {})
			# sp 是 rank
			count = achievementCounter.setdefault(sp, 0) + n
			achievementCounter[sp] = count

		for targetType2 in ObjectAchieveMap.TargetMap[targetType]:
			for csvID in ObjectAchieveMap.TargetMap[targetType][targetType2]:
				achieveObj = ObjectAchievement(self.game, csvID)
				if achieveObj.hasAchieved():
					continue
				if achieveObj.yyID != yyID:
					continue
				if achieveObj.targetArg2 and achieveObj.targetArg2 != sp:
					continue
				if count >= achieveObj.targetArg:
					achieveObj.setAchieved()
				else:
					break

	def getAchievementTaskAward(self, taskID):
		'''
		获取成就任务奖励
		'''
		cfg = csv.achievement.achievement_task[taskID]
		# 获得成就点
		points = self.game.role.achievement_points.get(cfg.type, 0) + cfg.point
		self.game.role.achievement_points[cfg.type] = points

		allPoints = self.allAchievementPoints

		self.achievementActiveBox(cfg.type, points)
		self.achievementActiveBox(0, allPoints)

		# 获得奖励
		eff = ObjectGainAux(self.game, cfg.award)
		return eff

	def achievementActiveBox(self, type, points):
		'''
		成就宝箱激活
		'''
		csvIDs = self.AchievementLevelMap.get(type, [])
		for csvID in csvIDs:
			cfgLevel = csv.achievement.achievement_level[csvID]
			if points >= cfgLevel.point and csvID not in self.game.role.achievement_box_awards:
				self.game.role.achievement_box_awards[csvID] = AchievementDefs.BoxAwardOpenFlag

	@property
	def allAchievementPoints(self):
		'''
		总成就点
		'''
		allPoints = 0
		for k, points in self.game.role.achievement_points.iteritems():
			allPoints += points
		return allPoints

	@property
	def allAchievementLevel(self):
		'''
		总成就等级
		'''
		csvIDs = self.AchievementLevelMap.get(0, [])
		points = self.allAchievementPoints
		level = 0
		for csvID in csvIDs:
			cfg = csv.achievement.achievement_level[csvID]
			if points < cfg.point:
				break
			level = cfg.level
		return level

	def achievementTaskCount(self, t, p, sp):
		'''
		成就任务 监听的计数
		'''
		# 角色等级
		if t == AchievementDefs.Level:
			return self.game.role.level >= p

		# 训练家等级
		elif t == AchievementDefs.TrainerLevel:
			return self.game.role.trainer_level >= p

		# 冒险执照特权属性点累计等级
		elif t == AchievementDefs.TrainerPrivilege:
			total = 0
			for k, v in self.game.role.trainer_attr_skills.iteritems():
				total += v
			return total >= p

		# 某个天赋类型投入了x点天赋点
		elif t == AchievementDefs.TalentOne:
			talent = self.game.role.talent_trees.get(sp, {})
			return talent.get('cost', 0) >= p

		# 总天赋投入了多少点天赋点
		elif t == AchievementDefs.TalentAll:
			total = 0
			for k, v in self.game.role.talent_trees.iteritems():
				total += v.get('cost', 0)
			return total >= p

		# 已激活探险器数量
		elif t == AchievementDefs.ExplorerActiveCount:
			total = 0
			for k, v in self.game.role.explorers.iteritems():
				if v.get('advance', 0) >= 1:
					total = total+1
			return total >= p

		# 激活指定探险器
		elif t == AchievementDefs.ExplorerActive:
			explorer = self.game.role.explorers.get(sp, {})
			return explorer.get('advance', 0) >= 1

		# 任意探险器的等级达到多少
		elif t == AchievementDefs.ExplorerLevel:
			maxLevel = 0
			for k, v in self.game.role.explorers.iteritems():
				maxLevel = max(v.get('advance', 0), maxLevel)
			return maxLevel >= p

		# 战力达到多少
		elif t == AchievementDefs.FightingPoint:
			return self.game.role.top6_fighting_point >= p

		# 消耗多少数量钻石
		elif t == AchievementDefs.CostRmbCount:
			return self.game.role.rmb_consume >= p

		# 精灵的收集数量（总数） ---- 图鉴数量
		elif t == AchievementDefs.CardCount:
			return len(self.game.role.pokedex) >= p

		# x属性精灵的收集x个 ---- 图鉴数量
		elif t == AchievementDefs.CardNatureCount:
			total = 0
			for cardID, v in self.game.role.pokedex.iteritems():
				unitID = csv.cards[cardID].unitID
				if sp == csv.unit[unitID].natureType or sp == csv.unit[unitID].natureType2:
					total += 1
			return total >= p

		# 指定cardID精灵的收集1个 ---- 图鉴数量
		elif t == AchievementDefs.CardCsvIDCount:
			return sp in self.game.role.pokedex

		# x等级的卡牌有x个
		elif t == AchievementDefs.CardLevelCount:
			return self.game.cards.countLevelCards(sp) >= p

		# x品质的卡牌有x个
		elif t == AchievementDefs.CardAdvanceCount:
			return self.game.cards.countAdvanceCards(sp) >= p

		# x星数的卡牌有x个
		elif t == AchievementDefs.CardStarCount:
			return self.game.cards.countStarCards(sp) >= p

		# x品质饰品有x个
		elif t == AchievementDefs.EquipAdvanceCount:
			return self.game.cards.countAdvanceEquips(sp) >= p

		# x觉醒饰品有x个
		elif t == AchievementDefs.EquipAwakeCount:
			return self.game.cards.countAwakeEquips(sp) >= p

		# x等级携带道具有x个
		elif t == AchievementDefs.HeldItemLevelCount:
			return self.game.heldItems.countLevelHeldItems(sp) >= p

		# x品质携带道具有x个
		elif t == AchievementDefs.HeldItemQualityCount:
			return self.game.heldItems.countQualityHeldItems(sp) >= p

		# x等级好感度有x个
		elif t == AchievementDefs.FeelLevelCount:
			total = 0
			for k, v in self.game.role.card_feels.iteritems():
				if v.get('level', 0) >= sp:
					total += 1
			return total >= p

		# x星普通关卡x个
		elif t == AchievementDefs.GateStarCount:
			return self.game.role.countStarGate(MapDefs.TypeGate, sp) >= p

		# 某普通关卡通关
		elif t == AchievementDefs.GatePass:
			return self.game.role.getGateStar(sp) >= 1

		# x星精英关卡x个
		elif t == AchievementDefs.HeroGateStarCount:
			return self.game.role.countStarGate(MapDefs.TypeHeroGate, sp) >= p

		# 某精英关卡通关
		elif t == AchievementDefs.HeroGatePass:
			return self.game.role.getGateStar(sp) >= 1

		# 无尽塔通过第几关
		elif t == AchievementDefs.EndlessTowerPass:
			return self.game.role.endless_tower_max_gate >= sp

		# 竞技场排名
		elif t == AchievementDefs.ArenaRank:
			if self.game.role.pw_rank <= 0:
				return False
			return self.game.role.pw_rank <= p

		# 好友数量
		elif t == AchievementDefs.FriendCount:
			return len(self.game.society.friends) >= p

		# 金币副本累计通关x难度
		elif t == AchievementDefs.GoldHuodongPassType:
			return (self.game.role.getHuoDongGateIndex(HuoDongDefs.TypeGold) + 1) >= sp

		# 经验副本累计通关x难度
		elif t == AchievementDefs.ExpHuodongPassType:
			return (self.game.role.getHuoDongGateIndex(HuoDongDefs.TypeExp) + 1) >= sp

		# 礼物副本累计通关x难度
		elif t == AchievementDefs.GiftHuodongPassType:
			return (self.game.role.getHuoDongGateIndex(HuoDongDefs.TypeGift) + 1) >= sp

		# 碎片副本累计通关x难度
		elif t == AchievementDefs.FragHuodongPassType:
			return (self.game.role.getHuoDongGateIndex(HuoDongDefs.TypeFrag) + 1) >= sp

		# 称号数量
		elif t == AchievementDefs.TitleCount:
			return len(self.game.role.titles) >= p

		# 形象解锁数量
		elif t == AchievementDefs.FigureCount:
			return len(self.game.role.figures) >= p

		# 头像框解锁数量
		elif t == AchievementDefs.FrameCount:
			return len(self.game.role.frames) >= p

		# 头像解锁数量
		elif t == AchievementDefs.LogoCount:
			return self.game.role.countLogos() >= p

		# 体力值达到x值
		elif t == AchievementDefs.StaminaCount:
			return self.game.role.stamina >= p

		# 邮箱存有邮件数
		elif t == AchievementDefs.MailCount:
			return (len(self.game.role.mailbox) + len(self.game.role.read_mailbox)) >= p

		# 钓到x鱼数量
		elif t == AchievementDefs.FishCount:
			return self.game.fishing.fish.get(sp, {}).get('counter', 0) >= p

		# 钓到x类型鱼数量
		elif t == AchievementDefs.FishTypeCount:
			count = self.game.fishing.fishCount(sp)
			return count >= p

		# 钓鱼等级达到x级
		elif t == AchievementDefs.FishingLevel:
			return self.game.fishing.level >= p

		# 连续签到天数
		elif t == AchievementDefs.SignInDays:
			return self.game.role.sign_in_days >= p

		# 拥有x个六项个体值达到x以上的精灵
		elif t == AchievementDefs.CardNvalueCount:
			return self.game.cards.countNvalueCards(sp) >= p

		# x个精灵宝石品质指数达到x
		elif t == AchievementDefs.CardGemQualitySum:
			return self.game.gems.countCardGemQualitySum(sp) >= p

		# 指定markID精灵的达到x星级； sp=markID, p=star
		elif t == AchievementDefs.CardMarkIDStar:
			return self.game.cards.countMarkIDStarCards(sp, p) >= 1

		return False

