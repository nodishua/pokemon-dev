#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2014 YouMi Information Technology Inc.
'''
from framework import DailyRefreshHour
from framework.helper import ClassProperty

import random
import datetime


class AttrDefs(object):
	#1 hp HP
	#2 mp1 MP1
	#3 initMp1 初始MP1
	#4 hpRecover HP回复
	#5 mp1Recover MP1回复
	#6 mp2Recover MP2回复
	#7 damage 物理攻击
	#8 specialDamage 特殊攻击
	#9 defence 物理防御力
	#10 specialDefence 特殊防御力
	#11 defenceIgnore 物理防御忽视
	#12 specialDefenceIgnore 特殊防御忽视
	#13 speed 先手值
	#14 strike 暴击
	#15 strikeDamage 暴击伤害
	#16 strikeResistance 暴击抗性
	#17 block 格挡等级
	#18 breakBlock 破格挡等级
	#19 blockPower 格挡强度
	#20 dodge 闪避
	#21 hit 命中
	#22 damageAdd 伤害加成
	#23 damageSub 伤害减免
	#24 ultimateAdd 必杀加成.
	#25 ultimateSub 必杀抗性
	#26 suckBlood 吸血
	#27 rebound 反弹
	#28 cure 治疗效果
	#29 natureRestraint 属性克制 X
	#30 damageDeepen 伤害加深     不同于伤害加成
	#31 damageReduce 伤害降低      不同于伤害减免

	#32 physicalDamageAdd # 物理攻击伤害加成
	#33 physicalDamageSub # 物理攻击伤害减免
	#34 specialDamageAdd # 特殊攻击伤害加成
	#35 specialDamageSub # 特殊攻击伤害减免

	# 自然属性伤害加成
	#36 normalDamageAdd 一般系伤害加成
	#37 fireDamageAdd 火系伤害加成
	#38 waterDamageAdd 水系伤害加成
	#39 grassDamageAdd 草系伤害加成
	#40 electricityDamageAdd 电系伤害加成
	#41 iceDamageAdd 冰系伤害加成
	#42 combatDamageAdd 格斗系伤害加成
	#43 poisonDamageAdd 毒系伤害加成
	#44 groundDamageAdd 地面系伤害加成
	#45 flyDamageAdd 飞行系伤害加成
	#46 superDamageAdd 超能系伤害加成
	#47 wormDamageAdd 虫系伤害加成
	#48 rockDamageAdd 岩石系伤害加成
	#49 ghostDamageAdd 幽灵系伤害加成
	#50 dragonDamageAdd 龙系伤害加成
	#51 evilDamageAdd 恶系伤害加成
	#52 steelDamageAdd 钢系伤害加成
	#53 fairyDamageAdd 妖精系伤害加成

	# 自然属性伤害减免
	#54 normalDamageSub 一般系伤害减免
	#55 fireDamageSub 火系伤害减免
	#56 waterDamageSub 水系伤害减免
	#57 grassDamageSub 草系伤害减免
	#58 electricityDamageSub 电系伤害减免
	#59 iceDamageSub 冰系伤害减免
	#60 combatDamageSub 格斗系伤害减免
	#61 poisonDamageSub 毒系伤害减免
	#62 groundDamageSub 地面系伤害减免
	#63 flyDamageSub 飞行系伤害减免
	#64 superDamageSub 超能系伤害减免
	#65 wormDamageSub 虫系伤害减免
	#66 rockDamageSub 岩石系伤害减免
	#67 ghostDamageSub 幽灵系伤害减免
	#68 dragonDamageSub 龙系伤害减免
	#69 evilDamageSub 恶系伤害减免
	#70 steelDamageSub 钢系伤害减免
	#71 fairyDamageSub 妖精系伤害减免

	# 自然属性治疗效果加成
	#72 normalCure 一般系治疗效果加成
	#73 fireCure 火系治疗效果加成
	#74 waterCure 水系治疗效果加成
	#75 grassCure 草系治疗效果加成
	#76 electricityCure 电系治疗效果加成
	#77 iceCure 冰系治疗效果加成
	#78 combatCure 格斗系治疗效果加成
	#79 poisonCure 毒系治疗效果加成
	#80 groundCure 地面系治疗效果加成
	#81 flyCure 飞行系治疗效果加成
	#82 superCure 超能系治疗效果加成
	#83 wormCure 虫系治疗效果加成
	#84 rockCure 岩石系治疗效果加成
	#85 ghostCure 幽灵系治疗效果加成
	#86 dragonCure 龙系治疗效果加成
	#87 evilCure 恶系治疗效果加成
	#88 steelCure 钢系治疗效果加成
	#89 fairyCure 妖精系治疗效果加成

	#90 controlPer 控制率
	#91 immuneControl 免疫控制率
	#92 pvpDamageAdd PVP伤害加成
	#93 pvpDamageSub PVP伤害减免

	#94 damageHit 伤害命中
	#95 damageDodge 伤害闪避

	hp = 'hp'
	mp1 = 'mp1'
	initMp1 = 'initMp1'
	hpRecover = 'hpRecover'
	mp1Recover = 'mp1Recover'
	mp2Recover = 'mp2Recover'
	damage = 'damage'
	specialDamage = 'specialDamage'
	defence = 'defence'
	specialDefence = 'specialDefence'
	defenceIgnore = 'defenceIgnore'
	specialDefenceIgnore = 'specialDefenceIgnore'
	speed = 'speed'
	strike = 'strike'
	strikeDamage = 'strikeDamage'
	strikeResistance = 'strikeResistance'
	block = 'block'
	breakBlock = 'breakBlock'
	blockPower = 'blockPower'
	dodge = 'dodge'
	hit = 'hit'
	damageAdd = 'damageAdd'
	damageSub = 'damageSub'
	ultimateAdd = 'ultimateAdd'
	ultimateSub = 'ultimateSub'
	suckBlood = 'suckBlood'
	rebound = 'rebound'
	cure = 'cure'
	natureRestraint = 'natureRestraint'
	damageDeepen = 'damageDeepen'
	damageReduce = 'damageReduce'

	physicalDamageAdd = 'physicalDamageAdd'
	physicalDamageSub = 'physicalDamageSub'
	specialDamageAdd = 'specialDamageAdd'
	specialDamageSub = 'specialDamageSub'

	normalDamageAdd = 'normalDamageAdd'
	fireDamageAdd = 'fireDamageAdd'
	waterDamageAdd = 'waterDamageAdd'
	grassDamageAdd = 'grassDamageAdd'
	electricityDamageAdd = 'electricityDamageAdd'
	iceDamageAdd = 'iceDamageAdd'
	combatDamageAdd = 'combatDamageAdd'
	poisonDamageAdd = 'poisonDamageAdd'
	groundDamageAdd = 'groundDamageAdd'
	flyDamageAdd = 'flyDamageAdd'
	superDamageAdd = 'superDamageAdd'
	wormDamageAdd = 'wormDamageAdd'
	rockDamageAdd = 'rockDamageAdd'
	ghostDamageAdd = 'ghostDamageAdd'
	dragonDamageAdd = 'dragonDamageAdd'
	evilDamageAdd = 'evilDamageAdd'
	steelDamageAdd = 'steelDamageAdd'
	fairyDamageAdd = 'fairyDamageAdd'

	normalDamageSub = 'normalDamageSub'
	fireDamageSub = 'fireDamageSub'
	waterDamageSub = 'waterDamageSub'
	grassDamageSub = 'grassDamageSub'
	electricityDamageSub = 'electricityDamageSub'
	iceDamageSub = 'iceDamageSub'
	combatDamageSub = 'combatDamageSub'
	poisonDamageSub = 'poisonDamageSub'
	groundDamageSub = 'groundDamageSub'
	flyDamageSub = 'flyDamageSub'
	superDamageSub = 'superDamageSub'
	wormDamageSub = 'wormDamageSub'
	rockDamageSub = 'rockDamageSub'
	ghostDamageSub = 'ghostDamageSub'
	dragonDamageSub = 'dragonDamageSub'
	evilDamageSub = 'evilDamageSub'
	steelDamageSub = 'steelDamageSub'
	fairyDamageSub = 'fairyDamageSub'

	normalCure = 'normalCure'
	fireCure = 'fireCure'
	waterCure = 'waterCure'
	grassCure = 'grassCure'
	electricityCure = 'electricityCure'
	iceCure = 'iceCure'
	combatCure = 'combatCure'
	poisonCure = 'poisonCure'
	groundCure = 'groundCure'
	flyCure = 'flyCure'
	superCure = 'superCure'
	wormCure = 'wormCure'
	rockCure = 'rockCure'
	ghostCure = 'ghostCure'
	dragonCure = 'dragonCure'
	evilCure = 'evilCure'
	steelCure = 'steelCure'
	fairyCure = 'fairyCure'

	controlPer = 'controlPer'
	immuneControl = 'immuneControl'
	pvpDamageAdd = 'pvpDamageAdd'
	pvpDamageSub = 'pvpDamageSub'

	damageHit = 'damageHit'
	damageDodge = 'damageDodge'

	attrsEnum = [
		None,
		hp,
		mp1,
		initMp1,
		hpRecover,
		mp1Recover,
		mp2Recover,
		damage,
		specialDamage,
		defence,
		specialDefence,
		defenceIgnore,
		specialDefenceIgnore,
		speed,
		strike,
		strikeDamage,
		strikeResistance,
		block,
		breakBlock,
		blockPower,
		dodge,
		hit,
		damageAdd,
		damageSub,
		ultimateAdd,
		ultimateSub,
		suckBlood,
		rebound,
		cure,
		natureRestraint,
		damageDeepen,
		damageReduce,

		physicalDamageAdd,
		physicalDamageSub,
		specialDamageAdd,
		specialDamageSub,

		normalDamageAdd,
		fireDamageAdd,
		waterDamageAdd,
		grassDamageAdd,
		electricityDamageAdd,
		iceDamageAdd,
		combatDamageAdd,
		poisonDamageAdd,
		groundDamageAdd,
		flyDamageAdd,
		superDamageAdd,
		wormDamageAdd,
		rockDamageAdd,
		ghostDamageAdd,
		dragonDamageAdd,
		evilDamageAdd,
		steelDamageAdd,
		fairyDamageAdd,

		normalDamageSub,
		fireDamageSub,
		waterDamageSub,
		grassDamageSub,
		electricityDamageSub,
		iceDamageSub,
		combatDamageSub,
		poisonDamageSub,
		groundDamageSub,
		flyDamageSub,
		superDamageSub,
		wormDamageSub,
		rockDamageSub,
		ghostDamageSub,
		dragonDamageSub,
		evilDamageSub,
		steelDamageSub,
		fairyDamageSub,

		normalCure,
		fireCure,
		waterCure,
		grassCure,
		electricityCure,
		iceCure,
		combatCure,
		poisonCure,
		groundCure,
		flyCure,
		superCure,
		wormCure,
		rockCure,
		ghostCure,
		dragonCure,
		evilCure,
		steelCure,
		fairyCure,

		controlPer,
		immuneControl,
		pvpDamageAdd,
		pvpDamageSub,

		damageHit,
		damageDodge,
	]
	attrs2Enum = {key: val for val, key in enumerate(attrsEnum)}  # AttrDefs.attrsEnum 的反向映射
	attrTotal = len(attrsEnum) - 1
	extendAttrs = set(attrsEnum[32:90])
	primaryAttrs = set(attrsEnum) - extendAttrs # 主要属性

	# 战斗力计算百分比权值类
	#
	# 13 speed 先手值
	# 14 strike 暴击
	# 15 strikeDamage 暴击伤害
	# 16 strikeResistance 暴击抗性
	# 17 block 格挡等级
	# 18 breakBlock 破格挡等级
	# 19 blockPower 格挡强度
	# 20 dodge 闪避
	# 21 hit 命中
	# 22 damageAdd 伤害加成
	# 23 damageSub 伤害减免
	# 24 ultimateAdd 必杀加成.
	# 25 ultimateSub 必杀抗性
	# 26 suckBlood 吸血
	# 27 rebound 反弹
	# 28 cure 治疗效果
	# 29 natureRestraint 属性克制 X
	# 30 damageDeepen 伤害加深     不同于伤害加成
	# 31 damageReduce 伤害降低      不同于伤害减免
	# 90 controlPer 控制率
	# 91 immuneControl 免疫控制率
	# 92 pvpDamageAdd PVP伤害加成
	# 93 pvpDamageSub PVP伤害减免
	# 94 damageHit 伤害命中
	# 95 damageDodge 伤害闪避
	fightPointPercents = set([
		strike,
		strikeDamage,
		strikeResistance,
		block,
		breakBlock,
		blockPower,
		dodge,
		hit,
		damageAdd,
		damageSub,
		ultimateAdd,
		ultimateSub,
		suckBlood,
		rebound,
		cure,
		natureRestraint,
		damageDeepen,
		damageReduce,
		controlPer,
		immuneControl,
		pvpDamageAdd,
		pvpDamageSub,
		damageHit,
		damageDodge,
	]) | extendAttrs

class CharacterDefs(object):
	# 性格
	# 1-浮躁
	# 2-勤奋
	# 3-害羞
	# 4-坦率
	# 5-认真
	# 6-胆小
	# 7-急躁
	# 8-爽朗
	# 9-天真
	# 10-怕寂寞
	# 11-勇敢
	# 12-固执
	# 13-顽皮
	# 14-大胆
	# 15-悠闲
	# 16-淘气
	# 17-乐天
	# 18-内敛
	# 19-慢吞吞
	# 20-冷静
	# 21-马虎
	# 22-温和
	# 23-温顺
	# 24-自大
	# 25-慎重

	Character0 = 0
	Character1 = 1
	Character2 = 2
	Character3 = 3
	Character4 = 4
	Character5 = 5

class NatureTypeDefs(object):
	# 自然属性定义
	# 1-一般
	# 2-火
	# 3-水
	# 4-草
	# 5-电
	# 6-冰
	# 7-格斗
	# 8-毒
	# 9-地面
	# 10- 飞行
	# 11- 超能
	# 12- 虫
	# 13- 岩石
	# 14- 幽灵
	# 15- 龙
	# 16- 恶
	# 17- 钢
	# 18- 妖精
	Normal = 1
	Fire = 2
	Water = 3
	Grass = 4
	Electricity = 5
	Ice = 6
	Combat = 7
	Poison = 8
	Ground = 9
	Fly = 10
	Super = 11
	Worm = 12
	Rock = 13
	Ghost = 14
	Dragon = 15
	Evil = 16
	Steel = 17
	Fairy = 18

class CardDefs(object):
	# 卡牌分类
	# 0-防
	# 1-攻
	# 2-技
	defenceClassify = 0
	attackClassify = 1
	skillClassify = 2

	# 品质
	# 1-白色
	# 2-绿色
	# 3-蓝色
	# 4-紫色
	# 5-橙色
	whiteQuality = 1
	greenQuality = 2
	blueQuality = 3
	purpleQuality = 4
	orangeQuality = 5

	# qualityName = [None,'白色', '绿色', '蓝色', '紫色', '橙色']
	qualityColor = [None,'#C0xFFFFFF#', '#C0x8DEB55#', '#C0x75A5FE#', '#C0xF475FF#', '#C0xFFA02D#']

	# 卡牌稀有度
	rarityB = 1
	rarityA = 2
	rarityS = 3
	raritySS = 4

class CardSkinDefs(object):
	# 属性加成类型
	# 1-相同markID
	# 2-全体
	sameMarkID = 1
	allCards = 2

class SkillDefs(object):
	# 技能激活的条件
	# 1-星级激活
	# 2-突破阶段
	starActive = 1
	advanceActive = 2

	# 技能类型;
	# 0:常规技能
	# 1:被动增加属性 （服务器只关心这条）
	# 2:光环类
	# 3:条件触发
	passiveAttr = 1

	attrsEnum = AttrDefs.attrsEnum

class ItemDefs(object):
	# 道具类型
	# 0-普通道具：无效果
	# 1-经验道具：卡牌经验道具
	# 2-体力回复道具：回复主角体力
	# 3-礼包道具
	# 4-饰品强化经验道具
	# 5-材料
	# 6-钥匙宝箱
	# 7-随机礼包
	# 8-(预留)装备觉醒道具
	# 9-好感度经验
	# 10-直接打开的随机礼包
	# 15-皮肤道具
	# 16-可选择道具的礼包
	# 17-角色头像，头像框，角色形象，称号通用获得道具
	# 18=性格道具
	# 19-限时皮肤道具
	normalType = 0
	expType = 1
	staminaType = 2
	giftType = 3
	equipStrengthType = 4
	materialType = 5
	boxkeyType = 6
	randomGiftType = 7
	feelExpType = 9
	imOpenRandGiftType = 10
	skinInMemType = 15
	chooseItemGift = 16
	roleDisplayType = 17
	characterType = 18

	# 不可配置，程序使用
	# 1003-礼包道具（内存对象）
	giftInMemType = 1003

	# 道具品质
	# 0-白色
	# 1-绿色
	# 2-蓝色
	# 3-紫色
	# 4-橙色
	whiteQuality = 0
	greenQuality = 1
	blueQuality = 2
	purpleQuality = 3
	orangeQuality = 4

	# 特定道具ID
	# 11	小型经验药水
	# 12	中型经验药水
	# 13	大型经验药水
	# 14	巨型经验药水
	smallExpPotion = 11
	middleExpPotion = 12
	bigExpPotion = 13
	largeExpPotion = 14

	# 宝石精华道具ID
	gemItemType = 529

	# 道具ID最大值
	maxID = 10000

	#有效期类型
	permanent = 0
	absoluteValid = 1
	expireValid = 2

	@classmethod
	def isItemID(cls, itemID):
		return itemID <= cls.maxID

	@classmethod
	def isGridWalkItem(cls, itemID):
		return 8112 <= itemID <= 8117


class EquipDefs(object):
	# 装备起始id
	startID = ItemDefs.maxID + 1
	# 装备id最大值
	maxID = 20000

	# 装备部位
	# 武器	1
	# 头盔	2
	# 衣服	3
	# 戒指	4
	# 圣物1	5
	# 圣物2	5
	weaponType = 1
	helmetType = 2
	clothesType = 3
	ringType = 4
	halidomType = 5

	nullPosition = -1 # db scheme default value

	@classmethod
	def isValidPosition(cls, position):
		return position >= 0 and position < 6

	@classmethod
	def isEquipID(cls, equipID):
		return cls.startID <= equipID and equipID <= cls.maxID

	# 道具品质
	# 0-白色
	# 1-绿色
	# 2-蓝色
	# 3-紫色
	# 4-橙色
	whiteQuality = 0
	greenQuality = 1
	blueQuality = 2
	purpleQuality = 3
	orangeQuality = 4

	# qualityName = ['白色', '绿色', '蓝色', '紫色', '橙色']
	qualityColor = ['#C0xFFFFFF#', '#C0x8DEB55#', '#C0x75A5FE#', '#C0xF475FF#', '#C0xFFA02D#']

	# 装备加成属性条目
	attrGainMax = 2

	attrsEnum = AttrDefs.attrsEnum

	# 刻印突破限制条件
	SignetAdvanceLimitStar = 1  # 饰品星级
	SignetAdvanceLimitAwake = 2  # 饰品觉醒

class FragmentDefs(object):
	# 碎片起始id
	startID = EquipDefs.maxID + 1
	# 碎片ID最大值
	maxID = 30000
	zawakeMaxID = 60000

	@classmethod
	def isFragmentID(cls, fragID):
		return cls.startID <= fragID and fragID <= cls.maxID

	@classmethod
	def isUniversalFragID(cls, fragID):
		return fragID in [502, 521]

	@staticmethod
	def getFragAttr(csv, fragID):
		if ZawakeDefs.isZFragID(fragID):
			cfg = csv.zawake.zawake_fragments[fragID]
			if cfg.cardID:
				unitCfg = csv.unit[csv.cards[cfg.cardID].unitID]
				unitNature = (unitCfg.natureType, unitCfg.natureType2)
			else:  # 通用碎片 无属性
				unitNature = ()
		elif FragmentDefs.isUniversalFragID(fragID):
			cfg = csv.items[fragID]
			return cfg.quality, [i for i in xrange(1, 19)]
		else:
			cfg = csv.fragments[fragID]
			unitCfg = csv.unit[csv.cards[cfg.combID].unitID]
			unitNature = (unitCfg.natureType, unitCfg.natureType2)
		return cfg.quality, unitNature

	# 碎片类型
	# 1 卡牌碎片
	# 2 装备碎片
	# 3 道具碎片
	# 4 携带道具碎片
	cardType = 1
	equipType = 2
	itemType = 3
	heldItemType = 4

	# 碎片品质
	# 0-白色
	# 1-绿色
	# 2-蓝色
	# 3-紫色
	# 4-橙色
	whiteQuality = 0
	greenQuality = 1
	blueQuality = 2
	purpleQuality = 3
	orangeQuality = 4

class HeldItemDefs(object):
	# 携带道具起始id
	startID = FragmentDefs.maxID + 1
	# 携带道具ID最大值
	maxID = 40000

	@classmethod
	def isHeldItemID(cls, heldItemID):
		return cls.startID <= heldItemID and heldItemID <= cls.maxID

	attrsEnum = AttrDefs.attrsEnum


class GemDefs(object):
	# 宝石起始id
	startID = HeldItemDefs.maxID + 1
	# 宝石ID最大值
	maxID = 50000
	# 红色品质符石
	RedQuality = 6

	@classmethod
	def isGemID(cls, gemID):
		return cls.startID <= gemID and gemID <= cls.maxID

	attrsEnum = AttrDefs.attrsEnum


class ZawakeDefs:
	MarkID = 1  # 自身系列属性加成
	CardNatureType = 2  # 指定自然属性卡牌属性加成
	CardsAll = 3  # 全体卡牌属性加成

	LevelMax = 8  # 阶段最大等级

	# 碎片id
	startID = GemDefs.maxID + 1
	maxID = 60000

	@classmethod
	def isZFragID(cls, fragID):
		return cls.startID <= fragID and fragID <= cls.maxID


class ChipDefs(object):
	# 芯片起始id
	startID = ZawakeDefs.maxID + 1
	# 芯片ID最大值
	maxID = 70000

	ResonanceQuality = 1
	ResonanceLevel = 2

	# 强化道具id
	StrengthItemIDs = [124, 123, 122]

	@classmethod
	def isChipID(cls, chipID):
		return cls.startID <= chipID and chipID <= cls.maxID


class ZawakeUnlockDefs:
	# markID相关
	Feel = 'goodFeel'  # 好感度等级

	# zawakeID相关
	EquipStarSum = 'equipStarSum'  # 饰品总星级
	EquipAwakeSum = 'equipAwakeSum'  # 饰品总觉醒
	EquipSignetAdvanceSum = 'equipSignetAdvanceSum'  # 饰品总刻印等级
	ZawakeStage = 'zawakeStage'  # Z觉醒阶段
	Star = 'star'  # 精灵星级
	NValueSum = 'nvalueSum'  # 个体值总和
	Advance = 'advance'  # 突破阶段
	Effort = 'effort'  # 精灵努力值阶段
	GemQuality = 'gemQuality'  # 符石指数

class MapDefs(object):
	# 场景类型
	# 0-全局
	# 1-世界
	# 2-章节
	# 3-精英章节
	# 4-关卡
	# 5-精英关卡
	# 6-噩梦关卡
	# 7-噩梦章节
	TypeGlobal = 0
	TypeWorld = 1
	TypeMap = 2
	TypeHeroMap = 3
	TypeGate = 4
	TypeHeroGate = 5
	TypeNightmareGate = 6
	TypeNightmareMap = 7

	# 11:金币活动;
	# 12:经验活动;
	# 13:礼物副本
	# 14:碎片副本
	# 15: 51活动副本

	TypeGold = 11
	TypeExp = 12
	TypeGift = 13
	TypeFrag = 14
	Type51Huodong = 15

	# 21: 公会副本
	# 22: 无尽之塔
	TypeUnionFuben = 21
	TypeEndless = 22

	# 23: 道馆关卡
	TypeGymGate = 23

	# 25: 勇者挑战
	BraveChallenge = 25

	# 星级奖励阶段
	# 0-青铜
	# 1-白银
	# 2-黄金
	starAwardBronze = 0
	starAwardSilver = 1
	starAwardGold = 2

	# 星级奖励领取标志
	# 0-没有奖励
	# 1-有奖励
	# 2-已领取
	starAwardNoneFlag = 0
	starAwardOpenFlag = 1
	starAwardCloseFlag = 2

	# 默认星级奖励字符串
	starAwardDefault = [0, 0, 0]

class TargetDefs(object):
	"""
	通用目标类型（主线，日常任务，运营活动任务）
	"""

	Level = 1 # 角色等级
	Gate = 2 # 通过章节关卡
	CardsTotal = 3 # 拥有卡牌数量
	CardGainTotalTimes = 4 # 卡牌获得总次数
	Vip = 5 # 达到vip等级
	FightingPoint = 6 # 战力达到多少
	CardAdvanceTotalTimes = 7 # 卡牌进阶总次数
	GateStar = 8 # 副本总星数（主线，精英，噩梦）
	CardAdvanceCount = 9 # 拥有某品质卡牌的数量
	CardStarCount = 10 # 拥有某星数卡牌的数量
	EquipAdvanceCount = 11 # 拥有某品质饰品的数量
	EquipStarCount = 12 # 拥有某星数饰品的数量
	HadCard = 13 # 拥有某卡牌
	GainCardTimes = 14 # 获得某卡牌系列的次数
	CompleteImmediate = 15 # 激活即完成（上线即完成）

	OnlineDuration = 16 # 累计在线时间
	LoginDays = 17 # 登录天数
	LianjinTimes = 18 # 购买金币次数
	GainGold = 19 # 获得金币
	CostGold = 20 # 消耗金币
	CostRmb = 21 # 消费钻石数量
	RechargeRmb = 22 # 充值钻石
	ShareTimes = 23 # 分享次数
	# KillMonster = 24 # 副本，爬塔，活动击杀怪物总数量
	SigninTimes = 25 # 签到次数
	BuyStaminaTimes = 26# 购买体力次数
	GiveStaminaTimes = 27 # 赠送好友体力
	CostStamina = 28 # 消耗体力
	GateChanllenge = 29 # 挑战普通关卡次数
	HeroGateChanllenge = 30 # 挑战精英关卡次数
	NightmareGateChanllenge = 31 # 挑战噩梦关卡次数
	HuodongChanllenge = 32 # 挑战活动副本次数
	GateSum = 33 # 累计打关卡数（普通，困难）

	CardSkillUp = 34 # 卡牌技能升级次数
	CardAdvance = 35 # 卡牌进阶次数
	CardLevelUp = 36 # 卡牌升级次数
	CardStar = 37 # 卡牌升星次数

	EquipStrength = 38 # 装备强化（升级）次数
	EquipAdvance = 39 # 装备进阶次数
	EquipStar = 40 # 装备升星次数

	ArenaBattle = 41 # 竞技场战斗次数
	ArenaBattleWin = 42 # 竞技场胜利次数
	ArenaPoint = 43 # 竞技场积分
	ArenaRank = 44 # 竞技场排名

	DrawCard = 45 # 金币钻石抽卡次数
	DrawCardRMB10 = 46 # 抽卡钻石10连抽
	DrawCardRMB1 = 47 # 抽卡钻石单抽
	DrawCardGold10 = 48 # 抽卡金币十连抽
	DrawCardGold1 = 49 # 抽卡金币单抽
	DrawCardRMB = 50 # 钻石抽卡次数
	DrawCardGold = 51 # 金币抽卡次数
	DrawEquip = 52 # 装备抽取次数
	DrawEquipRMB10 = 53 # 装备十连抽
	DrawEquipRMB1 = 54 # 装备单抽

	UnionContrib = 55 # 公会捐献次数
	UnionSpeedup = 56# 给公会成员成员加速次数
	UnionSendPacket = 57 # 公会发红包次数
	UnionRobPacket = 58 # 公会抢红包次数
	UnionFuben = 59 # 公会副本次数

	RandomTowerTimes = 60 # 随机试练塔通过房间数量
	RandomTowerBoxOpen = 61 # 随机试炼宝箱开启次数
	RandomTowerPointDaily = 62 # 随机试炼当日积分
	RandomTowerPoint = 63 # 随机试炼积分
	RandomTowerFloorTimes = 64 # 随机试炼塔累计通过层数
	WorldBossBattleTimes = 65 # 世界boss战次数
	CloneBattleTimes = 66 # 元素挑战玩法次数
	RandomTowerFloorMax = 67 # 随机试炼塔最高通过层数
	# AllCanItems = 68 # 万能碎片转换
	# CardComb = 69 # 合成卡牌次数

	DailyTaskFinish = 70 # 日常任务完成（领奖励时计入）次数
	DailyTaskAchieve = 71 # 完成日常任务到一定次数（完成就计数，不一定领奖励）
	ItemBuy = 72 # 道具贩卖
	YYHuodongOpen = 73 # 运营活动开启	(不计算该活动是否对某玩家激活)

	UnionDailyGiftTimes = 74  # 公会领取礼包次数
	UnionContribSum = 75  # 公会累计捐献经验

	UnlockPokedex = 76 # 解锁图鉴数量
	EndlessPassed = 77 # 无尽之塔通关第XX关 (配置关卡ID)
	Friends = 78 # 好友数量

	TrainerLevel = 79  # 训练家等级

	CaptureLevel = 80 # 捕捉等级
	CaptureSuccessSum = 81 # 累计捕捉成功的次数

	Explorer = 82 # 激活的探险器数量
	ExplorerComponentStrength = 83 # 探险器组件升级次数
	ExplorerAdvance = 84 # 激活/进阶探险器次数
	DispatchTaskDone = 85 # 完成派遣任务次数
	DispatchTaskQualityDone = 86 # 完成指定稀有度以上(包含)的派遣任务次数
	HeldItemStrength = 87 # 携带道具强化次数
	HeldItemAdvance = 88 # 携带道具突破次数
	EffortTrainTimes = 89 # 努力值培养次数
	EffortGeneralTrainTimes = 90 # 努力值普通培养次数
	EffortSeniorTrainTimes = 91 # 努力值高级培养次数
	CardAbilityStrength = 92  # 特性（潜能）升级次数

	EndlessChallenge = 93  # 无尽塔挑战 / 扫荡次数
	DrawItem = 94 # 探险器寻宝次数

	DrawCardUp = 95 # UP 抽卡（限定抽卡）
	DrawCardUpAndRMB = 96 # UP 抽卡和钻石抽卡

	Top6FightingPoint = 97  # TOP6战力达到多少
	UnionFragDonate = 98 # 公会碎片赠予

	TalentPointCost = 99 # 累计天赋点使用
	RandomTowerBattleWin = 100 # 以太乐园战斗胜利次数
	DispatchTask = 101 # 派遣任务次数
	CraftSignup = 102 # 报名石英大会，只记录手动报名
	DrawGemRMB = 103 # 钻石抽符石次数
	DrawGemGold = 104 # 金币抽符石次数
	DrawGem = 105 # 抽符石次数
	DrawGemUp = 106 # 限定up符石
	DrawGemUpAndRMB = 107  # 限时up符石和钻石抽符石

	FishingTimes = 108  # 钓鱼次数
	FishingWinTimes = 109  # 钓鱼成功次数
	CooperateClone = 110  # 协同元素挑战次数
	ReunionFriend = 111  # 添加绑定对象好友
	RandomTowerFloorSum = 112  # 完成指定层数以上(包含)的次数
	HuntingPass = 113  # 远征普通线路通关次数
	HuntingSpecialPass = 114  # 远征进阶线路通关次数

	DrawChipRMB = 115 # 钻石抽芯片次数
	DrawChipItem = 116 # 道具抽芯片次数
	DrawChip = 117 # 抽芯片次数

	NormalBraveChallenge = 118 # 宝可梦挑战通关

class TaskDefs(object):
	# 任务类型
	# 0=主线任务；
	# 1=日常任务
	mainType = 0
	dailyType = 1

	# 任务领取标志
	# 0-没有奖励
	# 1-有奖励
	# 2-已领取
	taskNoneFlag = 0
	taskOpenFlag = 1
	taskCloseFlag = 2

class AchievementDefs(object):
	# 0-已领取
	# 1-有奖励
	TaskAwardCloseFlag = 0
	TaskAwardOpenFlag = 1

	# 0-已领取
	# 1-有奖励
	BoxAwardCloseFlag = 0
	BoxAwardOpenFlag = 1

	# 人物成长
	Level = 1  # 战队等级
	TrainerLevel = 2  # 冒险执照等级
	TrainerPrivilege = 3  # 冒险执照特权属性点累计等级
	TalentOne = 4  # 某个天赋类型投入了x点天赋点
	TalentAll = 5  # 总天赋投入了多少点天赋点
	ExplorerActiveCount = 6  # 已激活探险器数量
	ExplorerActive = 7  # 激活指定探险器
	ExplorerLevel = 8  # 任意探险器的等级达到多少
	FightingPoint = 9  # 战力达到多少
	GoldCount = 10  # 拥有多少数量金币
	CostGoldCount = 11  # 消耗多少数量金币
	RmbCount = 12  # 拥有多少数量钻石
	CostRmbCount = 13  # 消耗多少数量钻石

	# 精灵收集
	CardCount = 14  # 精灵的收集数量（图鉴总数）
	CardNatureCount = 15  # x属性精灵的收集x个( 图鉴数量)

	# 精灵成长
	CardLevelCount = 16  # x等级的卡牌有x个
	CardAdvanceCount = 17  # x品质的卡牌有x个
	CardStarCount = 18  # x星数的卡牌有x个
	EffortGeneralTrainTimes = 19  # 任意精灵努力值普通培养x次
	EffortSeniorTrainTimes = 20  # 任意精灵努力值高级培养x次
	EquipAdvanceCount = 21  # x品质饰品有x个
	EquipAwakeCount = 22  # x觉醒饰品有x个
	HeldItemLevelCount = 23  # x等级携带道具有x个
	HeldItemQualityCount = 24  # x品质携带道具有x个
	FeelLevelCount = 25  # x等级好感度有x个

	# 副本活动
	GateChallenge = 26  # 挑战普通关卡次数
	GateStarCount = 27  # x星普通关卡x个
	GatePass = 28  # 关卡通关
	HeroGateChallenge = 29  # 挑战精英关卡次数
	HeroGateStarCount = 30  # x星精英关卡x个
	HeroGatePass = 31  # 某精英关卡通关
	GoldHuodongPassCount = 32  # 金币副本累计通关多少次
	ExpHuodongPassCount = 33  # 经验副本累计通关多少次
	GiftHuodongPassCount = 34  # 礼物副本累计通关多少次
	FragHuodongPassCount = 35  # 碎片副本累计通关多少次
	GoldHuodongPassType = 36  # 金币副本累计通关x难度
	ExpHuodongPassType = 37  # 经验副本累计通关x难度
	GiftHuodongPassType = 38  # 礼物副本累计通关x难度
	FragHuodongPassType = 39  # 碎片副本累计通关x难度
	EndlessTowerPass = 40  # 无尽塔通过第几关
	DispatchTaskCCount = 41  # C级派遣任务完成x次
	DispatchTaskBCount = 42  # B级派遣任务完成x次
	DispatchTaskACount = 43  # A级派遣任务完成x次
	DispatchTaskSCount = 44  # S级派遣任务完成x次
	DispatchTaskS2Count = 45  # S+级派遣任务完成x次

	# PVP竞技
	ArenaBattle = 46  # 竞技场战斗次数
	ArenaCoin1Count = 47  # 拥有荣誉币数量
	ArenaRank = 48  # 竞技场排名
	CraftBattle = 49  # 石英大会参加次数
	CraftTop8Count = 50  # 石英大会进入8强次数  ---- 暂未实现

	# 社交
	FriendCount = 51  # 好友数量
	FriendStaminaSend = 52  # 赠送多少次体力
	FriendStaminaRecv = 53  # 获赠多少次体力
	UnionContribGold = 54  # 公会金币捐赠累计次数
	UnionContribRmb = 55  # 公会钻石捐赠累计次数
	UnionGetRedPacketGold = 56  # 公会领取金币红包累计次数
	UnionGetRedPacketRmb = 57  # 公会领取钻石红包累计次数
	UnionGetRedPacketCoin3 = 58  # 公会领取公会币红包累计次数

	# 隐藏成就
	DrawCardRMB10 = 59  # 抽卡钻石10连抽次数
	OnlineHours = 60  # 连续在线x小时  ---- 暂未实现
	DrawItem5 = 61  # 累积使用寻宝5次次数
	ShopRefresh = 62  # 任意商店刷新累计次数
	DrawCardGold10 = 63  # 累计金币十连抽次数
	TitleCount = 64  # 称号的个数
	FigureCount = 65  # 形象解锁数量
	FrameCount = 66  # 头像框解锁数量
	LogoCount = 67  # 头像解锁数量
	StaminaCount = 68  # 体力达到x值
	MailCount = 69  # 邮箱存有邮件数
	MiniQActive = 70  # 迷你Q点击次数
	WorldChatCount = 71  # 世界频道发言次数
	CitySpriteCount = 72  # 点击主城彩蛋次数
	DrawSCard2 = 73  # 钻石十连抽同时抽出2个S级精灵
	DrawSCard3 = 74  # 钻石十连抽同时抽出3个S级精灵
	LivePoint = 75  # 累计x天活跃度达到100
	DrawGemRMB = 76  # 钻石抽符石次数
	DrawGemGold = 77  # 金币抽符石次数

	FishCount = 78  # 累计钓到x鱼x条
	FishTypeCount = 79  # 累计钓到x类型的鱼x条
	FishingLevel = 80  # 钓鱼达到x级
	SignInDays = 81  # 连续签到x天
	CardNvalueCount = 82  # 拥有x个精灵六项个体值达到x以上
	UnionFragDonate = 83  # 许愿中心累计赠送x次碎片
	FixShopRefresh = 84  # 精选商店累计手动刷新x次
	MysteryShopRefresh = 85  # 神秘商店累计手动刷新x次
	BaiBianActive = 86  # 累计点击主城百变怪x次
	RedQualityGem = 87  # 累计获得x个红色符石
	CardGemQualitySum = 88  # x个精灵的符石品质达到x
	GymAllPassTimes = 89  # 道馆副本全通关次数(不含npc馆主)
	HorseBetRightTimes = 90  # 赛马猜中第几名次数
	CardCsvIDCount = 91  # 指定cardID精灵的收集1个 ---- 图鉴数量
	CardMarkIDStar = 92  # 指定markID精灵的达到x星级
	HuntingPass = 93  # 远征普通线路通关次数
	HuntingSpecialPass = 94  # 远征进阶线路通关次数

	DrawChipRMB = 95  # 钻石抽芯片次数
	DrawChipItem = 96  # 道具抽芯片次数

class CostDefs(object):

	# 竞技场商店刷新消耗
	PVPShopRefreshCost = 'pvpshop_refresh_cost'

	#神秘商店刷新消耗
	MysteryShopRefreshCost = 'mysteryshop_refresh_cost'

	# 排位赛购买次数
	PVPPWBuyCost = 'pvppw_buy_cost'

	# 购买体力次数
	StaminaBuyCost = 'stamina_buy_cost'

	# 重置精英关卡次数
	HeroGateBuyCost = 'herogate_buy_cost'

	# 重置排位赛冷却时间
	PVPPWCDBuyCost = 'pvppw_cd_buy_cost'

	# 炼金次数
	LianJinCost = 'lianjin_cost'

	# 炼金按次数的数量修正
	LianJinGoldRate = 'lianjin_gold_rate'

	# 固定商店刷新消耗
	FixShopRefreshCost = 'fixshop_refresh_cost'

	# 公会商店刷新消耗
	UnionShopRefreshCost = 'unionshop_refresh_cost'

	# 购买技能点次数
	SkillPointBuyCost = 'skill_point_buy_cost'

	# 竞技场换一批消费
	PvpEnermysFreshCost = 'pvp_enermys_fresh_cost'

	# 角色改名
	RenameCost = 'rename_cost'

	# 签到补签
	SignInBuy = 'sign_in_buy'

	# 卡牌背包对应次数购买消耗
	CardbagBuyCost = 'cardbag_buy_cost'

	# 寻宝商店刷新
	ExplorerShopRefreshCost = 'explorershop_refresh_cost'

	# 碎片商店刷新
	FragShopRefreshCost = 'fragshop_refresh_cost'

	# 随机塔商店刷新
	RandomTowerShopRefreshCost = 'randomTowerShop_refresh_cost'

	# 试炼普通宝箱加开消耗
	RandomTowerBoxCost1 = 'random_tower_box_cost1'

	# 试炼豪华宝箱加开消耗
	RandomTowerBoxCost2 = 'random_tower_box_cost2'

	# 元素挑战战斗宝箱
	CloneBoxDrawCost = 'clone_box_draw_cost'

	# 冒险之路重置次数
	EndlessTowerResetTimesCost = 'endless_tower_reset_times_cost'

	# 世界boss购买次数
	WorldBossBuyCost = 'world_boss_buy_cost'

	# 跨服竞技场更换对手消耗
	CrossArenaFreshCost = 'cross_arena_fresh_cost'

	# 跨服竞技场排位赛购买次数
	CrossArenaPWBuyCost = 'cross_arena_pw_buy_cost'

	# 钓鱼商店刷新
	FishingShopRefreshCost = 'fishingshop_refresh_cost'

	# 进化石转化次数购买消耗
	MegaItemConvertCost = 'mega_item_convert_cost'

	# 钥石转化次数购买消耗
	MegaCommonItemConvertCost = 'mega_commonitem_convert_cost'

	# 道馆挑战加成点数购买消耗
	GymTalentPointBuyCost = 'gym_talent_point_buy_cost'

	# 道馆副本挑战购买消耗
	GymBattleBuyCost = 'gym_battle_buy_cost'

	# 道馆天赋重置消耗
	GymTalentResetCost = 'gym_talent_reset_cost'

	# 形象技能栏位解锁消耗
	FigureSkillUnlockCost = 'figure_skill_unlock_cost'

	# 饰品降星/降阶消耗
	EquipDropCost = 'equip_drop_cost'

	# 购买抢夺次数
	CrossMineRobCost = 'cross_mine_rob_buy_cost'

	# 购买报仇次数
	CrossMineRevengeCost = 'cross_mine_revenge_buy_cost'

	# 跨服矿战换一批购买
	CrossMineEnemyFreshCost = 'cross_mine_enemy_fresh_cost'

	# 购买报仇次数
	CrossMineBossCost = 'cross_mine_boss_buy_cost'

	# 公会问答购买次数消耗
	UnionQABuyCost = "union_qa_buy_cost"

	# 玩法通行证等级购买次数消耗 PlayPassportDefs.DailyTask
	PlayPassportBuyCost2 = "play_passport_buy_cost2"

	# 玩法通行证等级购买次数消耗 PlayPassportDefs.RandomTower
	PlayPassportBuyCost3 = "play_passport_buy_cost3"

	# 玩法通行证等级购买次数消耗 PlayPassportDefs.Gym
	PlayPassportBuyCost4 = "play_passport_buy_cost4"

	# 远征宝箱花费部分次数消耗
	HuntingBoxCost = "hunting_box_cost"

	# 自选限定抽卡切换消耗
	DrawCardUpChangeCost = "draw_card_up_change_cost"

class FeatureDefs(object):

	# 公会
	Union = 'union'

	# PVP竞技场开放
	PVP = 'arena'

	# 活动副本开放
	HuoDong = 'activityGate'

	# 精英关卡
	HeroGate = 'heroGate'

	# 噩梦关卡
	NightmareGate = 'nightmareGate'

	# 排行榜
	Ranks = 'rank'

	# 头衔
	Title = 'title'

	# 无尽之塔
	EndlessTower = 'endlessTower'

	# 训练师等级
	Trainer = 'trainer'

	# 溢出经验兑换
	OverflowExpExchange = 'overflowExpExchange'

	# 在线礼包
	OnlineGift = 'onlineGift'

	# VIP18
	VIPLevel18 = 'vipLevel18'

	# 派遣任务
	DispatchTask = 'dispatchTask'

	# 拳皇争霸
	Craft = 'craft'

	# 跨服王者争霸
	CrossCraft = 'crossCraft'

	# 跨服竞技场
	CrossArena = 'crossArena'

	# 世界等级
	WorldLevel = 'worldLevel'

	# 道馆
	Gym = 'gym'

	# 远征开放
	YuanZheng = 'yuanzheng'

	# 装备星级
	EquipStar = 'equip_star'

	# 聊天
	Chat = 'chat'

	# 元素挑战
	Clone = 'cloneBattle'

	# 成就
	achievement = 'achievement'

	# 重生
	Reset = 'reset'

	# 公会战
	Unionfight = 'unionFight'

	# 远征一键跳过
	YuanzhengSkip = 'yuanzheng_skip'

	# 合金矩阵
	Matrix = 'matrix'

	# 卡牌分享
	CardShare = 'cardShare'

	# 战报分享
	BattleShare = 'battleShare'

	# 探险器
	Explorer = 'explorer'

	# 试炼塔
	RandomTower = 'randomTower'

	# 特性
	CardAbility = 'cardAbility'

	# 关卡捕捉
	GateCapture = 'gateCapture'

	# 限时捕捉
	LimitCapture = 'limitCapture'

	# 抽卡累计宝箱
	DrawSumBox = 'drawSumBox'

	# 抽卡累计宝箱
	TimeLimitUpDrawSumBox = 'timeLimitUpDrawSumBox'

	# 世界聊天
	WorldChat = 'worldChat'

	# 私聊
	RoleChat = 'roleChat'

	# 以太直通
	RandomTowerJump = 'randomTowerJump'

	# 竞技场碾压
	PvpPass = 'pvpPass'

	# 宝石
	Gem = 'gem'

	# 极限培养
	ExtremityProperty = 'extremityProperty'

	# 星级技能效果
	StarEffect = 'starEffect'

	# vip显示切换
	VipDisplaySwitch = 'vipDisplaySwitch'

	# vip 贵宾
	VipDistinguished = 'vipDistinguished'

	# 钓鱼
	Fishing = 'fishing'

	# 实时对战
	CrossOnlineFight = 'onlineFight'

	# 跨服竞技场战5次
	CrossArenaPass = 'crossArenaPass'

	# 超进化
	Mega = 'mega'

	# 精灵切换分支
	CardSwitchBranch = 'cardSwitchBranch'

	# 精灵评论
	CardPostComment = 'cardPostComment'

	# 勋章
	Badge = 'badge'

	# 勋章一键升级
	BadgeOneKey = 'badgeOneKey'

	# 饰品刻印
	EquipSignet = 'equipSignet'

	# 饰品星级潜能
	EquipAbility = 'equipAbility'

	# 天赋单页重置
	SingleTalentReset = 'singleTalentReset'

	# 预设队伍
	ReadyTeam = 'readyTeam'

	# 饰品觉醒潜能
	EquipAwakeAbility = 'equipAwakeAbility'

	# 跨服资源战
	CrossMine = 'crossMine'

	# 日常助手
	DailyAssistant = 'dailyAssistant'

	# 远征
	Hunting = 'hunting'

	# 远征进阶
	SpecialHunting = 'specialHunting'

	# 远征碾压
	HuntingPass = 'huntingPass'

	# 远征进阶碾压
	SpecialHuntingPass = 'specialHuntingPass'

	# 普通勇者
	NormalBraveChallenge = 'normalBraveChallenge'

	# 部屋大作战
	CrossUnionFight = 'crossunionfight'

	# 道馆碾压
	GymSaodang = 'gymSaodang'

class YuanzhengDefs(object):
	StarCount = (1, 3, 5)
	StarRate = (1, 1.5, 2.5)


class DrawDefs(object):
	# 抽取触发类型(0从X次开始;1权值累加;2概率触发;3每X次;4第X次)
	TriggerStart = 0
	TriggerWeight = 1
	TriggerProb = 2
	TriggerEvery = 3
	TriggerOnce = 4

	TriggerTotal = 5


class DrawCardDefs(object):
	# 钻石单抽
	RMB1 = 'rmb1'
	# 钻石十连抽
	RMB10 = 'rmb10'
	# 免费单抽
	Free1 = 'free1'

	# 金币单抽
	Gold1 = 'gold1'
	# 金币十连抽
	Gold10 = 'gold10'
	# 免费单抽
	FreeGold1 = 'free_gold1'


	# 限时钻石单抽
	LimitRMB1 = 'limit_rmb1'
	# 限时钻石10连抽
	LimitRMB10 = 'limit_rmb10'
	# 远征免费宝箱
	YzFreeBox = 'yz_freebox'

	# 限时Up钻石单抽
	LimitUpRMB1 = 'limit_up_rmb1'
	# 限时Up钻石10连抽
	LimitUpRMB10 = 'limit_up_rmb10'

	# 限时宝箱钻石单抽
	LimitBoxRMB1 = 'limit_box_rmb1'
	# 限时宝箱免费钻石单抽
	LimitBoxFree1 = 'limit_box_free1'
	# 限时宝箱钻石10连抽
	LimitBoxRMB10 = 'limit_box_rmb10'

	# 自选限时Up钻石单抽
	GroupUpRMB1 = 'group_up_rmb1'
	# 自选限时Up钻石10连抽
	GroupUpRMB10 = 'group_up_rmb10'

	@staticmethod
	def LimitDrawRandomKey(drawType, yyID):
		return '%s_%s' % (drawType, yyID)

	# 金币抽卡代金券为518
	# 钻石抽卡代金券为519
	# 限时抽卡代金券为526
	# 限时Up抽卡代金券为527
	GoldDrawItem = 518
	RMBDrawItem = 519
	LimitDrawItem = 526
	LimitUpDrawItem = 527


class DrawEquipDefs(object):
	# 钻石单抽
	RMB1 = 'rmb1'
	# 钻石十连抽
	RMB10 = 'rmb10'
	# 免费单抽
	Free1 = 'free1'

	# 充值大转盘
	RechargeWheel = "recharge_wheel"

	# 活跃转盘单抽
	LivenessWheelFree1 = 'liveness_wheel_free1'
	# 活跃转盘单抽
	LivenessWheel1 = 'liveness_wheel1'
	# 活跃转盘五连
	LivenessWheel5 = 'liveness_wheel5'

	@staticmethod
	def YYDrawRandomKey(drawType, yyID):
		return '%s_%s' % (drawType, yyID)

	# 装备抽卡道具为503
	drawKey = 503

class DrawItemDefs(object):
	# 寻宝币单抽
	COIN4_1 = 'coin4_1'
	# 寻宝币5连抽
	COIN4_5 = 'coin4_5'
	# 免费单抽
	Free1 = 'free1'

	# 扭蛋免费单抽
	LuckyEggFree1 = 'lucky_egg_free1'
	# 扭蛋机单抽
	LuckyEggRMB1 = 'lucky_egg_rmb1'
	# 扭蛋机10连抽
	LuckyEggRMB10 = 'lucky_egg_rmb10'

	@staticmethod
	def YYDrawRandomKey(drawType, yyID):
		return '%s_%s' % (drawType, yyID)

	# 抽道具消耗 寻宝代券 520
	# 扭蛋机代币
	explorerKey = 520
	LuckyEggCoin = 6320


class DrawGemDefs(object):
	# 宝石钻石单抽
	RMB1 = 'rmb1'
	# 宝石钻石10连抽
	RMB10 = 'rmb10'
	# 免费单抽
	Free1 = 'free1'

	# 金币单抽
	Gold1 = 'gold1'
	# 金币十连抽
	Gold10 = 'gold10'
	# 金币免费单抽
	FreeGold1 = 'free_gold1'

	# 限时Up符石钻石单抽
	LimitUpGemRMB1 = 'limit_up_gem_rmb1'
	# 限时Up免费符石钻石单抽
	LimitUpGemFree1 = 'limit_up_gem_free1'
	# 限时Up符石钻石10连抽
	LimitUpGemRMB10 = 'limit_up_gem_rmb10'
	# 限时Up符石每日抽取上限
	DrawLimit = 'drawLimit'

	# 金币代金券
	GoldDrawItem = 530
	# 钻石代金券
	RMBDrawItem = 531

	@staticmethod
	def LimitDrawRandomKey(drawType, yyID):
		return '%s_%s' % (drawType, yyID)

class DrawChipDefs(object):
	# 芯片钻石单抽
	RMB1 = 'rmb1'
	# 芯片钻石10连抽
	RMB10 = 'rmb10'
	# 免费单抽
	Free1 = 'free1'

	# 道具单抽
	Item1 = 'item1'
	# 道具十连抽
	Item10 = 'item10'
	# 道具免费单抽
	FreeItem1 = 'free_item1'

	# 钻石代金券
	RMBDrawItem = 537
	# 抽取用道具
	DrawItem = 538

class DrawBoxDefs(object):
	# 银宝箱
	Silver = 'silver'
	# 铜宝箱
	Bronze = 'bronze'

	# 系统金宝箱
	GoldSys = 'gold_sys'
	# 非系统金宝箱
	GoldNonSys = 'gold_nonsys'

	# 金宝箱钥匙
	GoldKeyID = 4001
	# 银宝箱钥匙
	SilverKeyID = 4002
	# 铜宝箱钥匙
	BronzeKeyID = 4003

	# 金宝箱系统
	GoldSysBoxID = 4101
	# 金宝箱非系统
	GoldNonSysBoxID = 4102
	# 银宝箱
	SilverBoxID = 4103
	# 铜宝箱
	BronzeBoxID = 4104


class RechargeDefs(object):

	# 充值类型
	# 一次性充值
	OneOffType = 1
	# 按日奖励充值
	DaysType = 2
	# 礼包购买
	GiftType = 3


class HuoDongDefs(object):
	# 开放周期
	# 0=一次性、1=日循环、2=周循环
	OnceOpen = 0
	DailyOpen = 1
	WeekOpen = 2

	#活动关卡类型
	# 1=金币 2=经验 3=礼物 4=碎片 5=51活动本
	TypeGold = 1
	TypeExp = 2
	TypeGift = 3
	TypeFrag = 4
	Type51Huodong = 5

	# 礼物本 副本序列
	huodongGiftGroup1 = 1
	huodongGiftGroup2 = 2

	# 礼物本 免疫类型
	huodongGiftPhysicalImmune = 1
	huodongGiftSpecialImmune = 2



class YYHuoDongDefs(HuoDongDefs):
	# 开放周期 openType
	# 3-相对开服日期，4-相对角色创建时间
	RelateServerOpen = 3
	RelateRoleCreate = 4

	# countType
	# 计数类型0-每日、1-累计、特殊活动类型忽略
	DailyCount = 0
	SumCount = 1

	# 活动类型
	# 1=首充礼包
	# 2=登陆福利
	# 3=冲级奖金
	# 4=充值送礼
	# 5=限时魂匣抽卡
	# 6=月卡
	# 7=开饭
	# 8=活动展示
	# 9=通关奖励
	# 10=VIP奖励
	# 11=终身月卡
	# 12=道具兑换
	# 13=钻石消耗
	# 14=任务
	# 15=开服活动
	# 16=战力排行
	# 17=招财猫
	# 18=招募数码兽
	# 19=每日折扣
	# 20=限时宝箱
	# 21=VIP折扣
	# 22=等级基金
	# 23=道具折扣
	# 24=特殊元素挑战
	# 25=砸金蛋
	# 26=世界boss
	# 27=补领体力
	# 28=单笔充钻石返还
	# 29=2048游戏(废弃)
	# 30=拯救鼻涕兽(废弃)
	# 31=首冲双倍重置
	# 32=下100层游戏(废弃)
	# 33=直购礼包
	# 34=限时礼包
	# 35=通行证
	# 36=限时Up抽卡
	# 37=登录礼包
	# 38=充值大转盘
	# 39=活跃大转盘
	# 40=扭蛋机
	# 41=资源找回
	# 42=活动红包
	# 43=资源周卡
	# 44=限时up符石
	# 45=包粽子
	# 46=重聚
	# 47=碎片携带道具兑换
	# 48=国庆翻牌
	# 51=双十一
	# 52=活动装扮
	# 53=雪球
	# 55=摩天大楼
	# 54=主城精灵解冻
	# 56=集福迎新年
	# 57=跨服活动红包
	# 58=返利
	# 59=主题通行证
	# 60=走格子
	# 61=周年副本
	# 63=道具商店
	# 64=尊享限定
	# 65=五一派遣
	# 66=沙滩刨冰
	# 67=夏日挑战
	# 68=沙滩排球
	# 69=月圆祈福
	# 70=定制礼包

	FirstRecharge = 1
	LoginWeal = 2
	LevelAward = 3
	RechargeGift = 4
	TimeLimitDraw = 5
	MonthlyCard = 6
	DinnerTime = 7
	ClientShow = 8
	GateAward = 9
	VIPAward = 10
	# AllLifeCard = 11
	ItemExchange = 12
	RMBCost = 13
	GeneralTask = 14
	ServerOpen = 15
	FightRank = 16
	LuckyCat = 17
	CollectCard = 18
	DailyBuy = 19
	TimeLimitBox = 20
	VIPBuy = 21
	LevelFund = 22
	ItemBuy = 23
	YYClone = 24
	BreakEgg = 25
	WorldBoss = 26
	RegainStamina = 27
	OnceRechageAward = 28
	# Game2048 = 29
	# GameEatGreenBlock = 30
	RechargeReset = 31
	# GameGoDown100 = 32
	DirectBuyGift = 33
	LimitBuyGift = 34
	Passport = 35
	TimeLimitUpDraw = 36
	LoginGift = 37
	RechargeWheel = 38
	LivenessWheel = 39
	LuckyEgg = 40
	Retrieve = 41
	HuoDongRedPacket = 42
	WeeklyCard = 43
	TimeLimitUpDrawGem = 44
	BaoZongzi = 45
	Reunion = 46
	QualityExchange = 47
	Flop = 48
	HuoDongBoss = 49
	HalloweenSprites = 50
	Double11 = 51
	HuoDongCloth = 52
	SnowBall = 53
	SpriteUnfreeze = 54
	Skyscraper = 55
	Jifu = 56
	HuoDongCrossRedPacket = 57
	RMBGoldReturn = 58
	PlayPassport = 59
	GridWalk = 60
	BraveChallenge = 61
	HorseRace = 62
	ItemBuy2 = 63
	LuxuryDirectBuyGift = 64
	Dispatch = 65
	ShavedIce = 66
	SummerChallenge = 67
	Volleyball = 68
	MidAutumnDraw = 69
	CustomizeGift = 70

	# -1=每日登陆奖励
	# -2=双倍掉率，次数增加
	# -3=限时掉落
	EveryDayLogin = -1
	DoubleDrop = -2
	LimitDrop = -3

	# 道具兑换限制类型
	# 0-不限制
	# 1-vip
	# 2-等级
	# 3-图鉴
	# 4-头像
	# 5-皮肤
	ItemExchangeNoLimit = 0
	ItemExchangeVIPLimit = 1
	ItemExchangeLevelLimit = 2
	ItemExchangePokedexLimit = 3
	ItemExchangeLogoLimit = 4
	ItemExchangeSkinlLimit = 5

	# 任务计数类型
	# 1- 强制计数
	# 2- 只有当天计数
	# 3- 当天开始后计数
	ForceCount = 1
	OnDayCount = 2
	LaterCount = 3

	# 双倍掉落
	# 1 关卡掉落双倍
	# 2 金币副本次数增加
	# 3 经验副本次数增加
	# 4 礼物副本次数增加
	# 5 碎片副本次数增加
	# 6 点金前10次双倍产出
	# 7 体力购买前5次双倍产出
	# 8 精英副本挑战次数增加
	# 9 无尽之塔扫荡奖励双倍（首通不双倍）
	# 10 随机试炼塔金币双倍 gold字段

	DoubleDropGate = 1
	DoubleCountGold = 2
	DoubleCountExp = 3
	DoubleCountGift = 4
	DoubleCountFrag = 5
	DoubleLianjin = 6
	DoubleBuyStamina = 7
	DoubleEliteCount = 8
	DoubleEndlessSaodang = 9
	DoubleRandomTowerGold = 10

	# 限时礼包激活类型
	# 1 玩家等级激活
	# 2 通过指定关卡激活
	# 3 获得指定卡牌-填写markID (markID，不记录历史获得记录，以获得新的为主）
	# 4 创角天数-填写玩家创角后的天数，创角那一天为0
	# 5 vip等级激活
	# 6 获得某稀有度以上的卡牌后激活-填写会触发的稀有度ID(不记录历史获得记录，以获得新的为主)
	# 7 无触发条件，直接激活

	RoleLevelActive = 1
	PassGateActive = 2
	GainCardActive = 3
	RoleCreatedTimeActive = 4
	RoleVipLevelActive = 5
	GainCardRarityActive = 6
	ImmediateActive = 7


class UnionDefs(object):

	# 公会中地位定义
	# 0 非成员
	# 1 成员
	# 2 副主席
	# 3 主席
	NonePlace = 0
	MemberPlace = 1
	ViceChairmanPlace = 2
	ChairmanPlace = 3

	# 加入公会审批方式
	# 0 审批加入
	# 1 直接加入
	# 2 拒绝加入
	ApproveJoin = 0
	DirectJoin = 1
	RefuseJoin = 2

	# 公会活动状态
	# 0 关闭，可能公会等级不足（公会副本通关）
	# 1 开放
	# 2 未开放，可能会长副会长关闭（公会副本放弃）
	HDCloseFlag = 0
	HDOpenFlag = 1
	HDDisableFlag = 2

	# 公会功能
	# training 训练所
	# redpacket 红包
	# fuben 公会副本
	# contribute 捐献
	# dailygift 每日礼包
	# unionskill 公会修炼
	# unionfight 公会战
	# unionqa 公会问答
	# crossunionfight 跨服公会战
	Training = 'training'
	RedPacket = 'redpacket'
	Fuben = 'fuben'
	Contribute = 'contribute'
	DailyGift = 'dailygift'
	UnionSkill = 'unionskill'
	Unionfight = 'unionFight'
	FragDonate = 'fragdonate'
	UnionQA = "unionqa"
	CrossUnionFight = 'crossunionfight'

	# 公会历史
	# 1	%r加入公会
	# 2	%r退出公会
	# 3	%r被%c踢出公会
	# 4	%r晋级为副会长
	# 5	%r降级为会员
	# 6	%c转让会长给%r
	# 7	%r被选拔为新任会长
	# 8	%c批准%r加入公会
	HistoryDirect = 1
	HistoryQuit = 2
	HistoryKick = 3
	HistoryPromote = 4
	HistoryDemote = 5
	HistorySwap = 6
	HistoryChoose = 7
	HistoryAccept = 8

	# 公会红包类型
	PacketGold = 0
	PacketRmb = 1
	PacketCoin3 = 2

	# 公会红包标记
	PacketFlagRole = 0 #玩家红包
	PacketFlagSys = 1  #系统红包

	# 任务领取标志
	# 0-没有奖励
	# 1-有奖励
	# 2-已领取
	UnionTaskNoneFlag = 0
	UnionTaskOpenFlag = 1
	UnionTaskCloseFlag = 2

	# 执行人类型
	# 1-个人
	# 2-全公会
	UnionTaskRole = 1
	UnionTaskUnion = 2

	# 类型
	# 1-日
	# 2-周
	UnionTaskDay = 1
	UnionTaskWeek = 2

	# 培养类型
	UnionRedpacketOnce = 1  # 一次性
	UnionRedpacketMore = 2  # 循环
	UnionRedPacketDaily = 3 # 每日一次

class MailDefs(object):

	# 邮件类型
	# 全局邮件
	# 全服邮件
	# 公会邮件
	TypeGlobal = 1
	TypeServer = 2
	TypeUnion = 3
	TypeVip = 4

class FixShopDefs(object):

	# 0-固定时间
	# 1-间隔时间
	# 2-不刷新
	FixTimeRefresh = 0
	PeriodTimeRefresh = 1
	NoRefresh = 2

class TalentDefs(object):
	# 上阵前排
	BattleFront = 1
	# 上阵后排
	BattleBack = 2
	# 全体卡牌
	CardsAll = 3
	# 指定属性卡牌
	CardNatureType = 4
	# 指定属性技能
	CardNatureSkill = 5
	# 场景加成
	SceneType = 6

	AttrsTotal = 7

class MessageDefs(object):
	# Msg类型
	NormalType = 0
	UnionJoinUpType = 1 # 公会招募
	CloneInviteType = 2 # 元素挑战邀请
	RoleUnionType = 3 # 个人公会消息
	UnionRedPacketType = 4 # 公会红包
	BreakEggType = 5 # 砸金蛋消息
	WorldChatType = 6 # 世界聊天
	UnionChatType = 7 # 公会聊天
	RoleChatType = 8 # 私聊
	NewsType = 9 # 新闻
	BattleShareType = 10 # 战报分享
	WorldCardShareType = 11 # 世界精灵分享
	WorldCloneInviteType = 12 # 元素挑战世界邀请
	UnionCloneInviteType = 13 # 元素挑战公会邀请
	FriendCloneInviteType = 14 # 元素挑战好友邀请
	UnionCardShareType = 15  # 公会精灵分享
	YYHuoDongRedPacketType = 16 # 运营活动红包
	MarqueeType = 17  # 跑马灯
	WorldReunionInvite = 18  # 重聚活动世界邀请
	RecommendReunionInvite = 19  # 重聚活动推荐邀请
	YYHuoDongCrossRedPacketType = 20  # 运营活动跨服红包

	# Marquee 的 key
	MqDrawCard = 'drawCard'  # 钻石抽卡
	MqLimitDrawCardUp = 'limitDrawCardUp'  # 限定抽卡
	MqDrawHoldItem = 'drawHoldItem'  # 抽携带道具
	MqCapture = 'capture'  # 捕捉
	MqPvpTopRank = 'pvpTopRank'  # 竞技场冠军
	MqLimitDrawCard = 'limitDrawCard'  # 魂匣
	MqLimitBox = 'limitBox'  # 限时神兽
	MqRandomTowerPass = 'randomTowerPass'  # 以太乐园全通关
	MqEndlessTowerPass = 'endlessTowerPass'  # 冒险之路通关达到X
	MqCardStar = 'cardStar'  # 精灵培养到6星及以上
	MqFragCombCard = 'fragCombCard'  # S+精灵碎片合成
	MqPvpTopRankLast = 'pvpTopRankLast'  # 竞技场结算第一
	MqCraftTopRank = 'craftTopRank'  # 石英大会结算第一
	MqCardInLimitCard = 'cardInLimitCard'  # 神兽召唤抽到S+以上精灵
	MqCrossArenaTopRank = 'crossArenaTopRank'  # 跨服竞技场第一
	MqCrossArenaTopHistoryRefresh = 'crossArenaTopHistoryRefresh'  # 跨服竞技场精彩战报刷新
	MqCrossOnlineFightTopHistoryRefresh = 'crossOnlineFightTopHistoryRefresh'  # 对战竞技场精彩战报刷新
	MqCrossMineTopHistoryRefresh = 'crossMineTopHistoryRefresh'  # 跨服资源战精彩战报刷新
	MqGroupDrawCardUp = 'groupDrawCardUp'  # 自选抽卡

class TitleDefs(object):
	# 拳皇争霸
	Craft = 'craft'

	# 竞技场
	Arena = 'arena'

	# 关卡榜
	StarRank = 'star'

	# 收藏榜（图鉴）
	Pokedex = 'pokedex'

	# 跨服竞技场赛季结算
	CrossArena = 'crossArena'

	# 跨服公会战决赛
	CrossUnionFight = 'crossUnionFight'

	# 跨服石英
	CrossCraft = 'crossCraft'

	# 跨服竞技场每日结算
	CrossArenaDaily = 'crossArenaDaily'

	# 荣誉馆主
	Gym = 'gym'

	# 跨服荣誉馆主
	CrossGym = 'crossGym'

	# 钓鱼大赛
	CrossFishing = 'crossFishing'

	# 对战竞技场无限制赛
	CrossOnlineFightUnlimited = 'onlineFightUnlimited'

	# 对战竞技场公平赛
	CrossOnlineFightLimited = 'onlineFightLimited'

	# 跨服资源战赛季结算
	CrossMine = 'crossMine'

	# 跨服资源战每日结算
	CrossMineDaily = 'crossMineDaily'

	# 公会问答 公会排名称号
	UnionQAUnion = "unionQAUnion"

	# 公会问答 个人排名称号
	UnionQARole = "unionQARole"

	# 称号类别
	RoleKind = 1  # role
	UnionKind = 2  # union

	# hour 几点
	ResetTime = {
		'craft': datetime.time(hour=21),
		'arena': datetime.time(hour=21),
		'star': datetime.time(hour=DailyRefreshHour),
		'pokedex': datetime.time(hour=DailyRefreshHour),
		'crossArena': datetime.time(hour=21, minute=59, second=58),
		'crossCraft': datetime.time(hour=19),  # 小于实际结算时间
		'crossArenaDaily': datetime.time(hour=21, minute=59, second=58),
		'crossFishing': datetime.time(hour=22, minute=59, second=58),
		'onlineFightUnlimited': datetime.time(hour=20, minute=29, second=58),
		'onlineFightLimited': datetime.time(hour=20, minute=29, second=58),
		'crossMine': datetime.time(hour=21, minute=59, second=58),
		'crossMineDaily': datetime.time(hour=21, minute=59, second=58),
		"crossUnionFight": datetime.time(hour=21, minute=29, second=58),
		"unionQAUnion": datetime.time(hour=23, minute=59, second=58),
		"unionQARole": datetime.time(hour=23, minute=59, second=58),
	}

	import framework
	if framework.__language__ == "en":
		ResetTime["craft"] = datetime.time(hour=23)
		ResetTime["crossCraft"] = datetime.time(hour=22)
		ResetTime["onlineFightUnlimited"] = datetime.time(hour=22, minute=29, second=58)
		ResetTime["onlineFightLimited"] = datetime.time(hour=22, minute=29, second=58)
		ResetTime["crossMine"] = datetime.time(hour=22, minute=59, second=58)
		ResetTime["crossMineDaily"] = datetime.time(hour=22, minute=59, second=58)


class PokedexAdvanceDefs(object):
	#总数量
	TotalCount = 1

	#单属性数量
	SingleCount = 2

class SceneDefs(object):
	# 主城
	City = 0
	#关卡
	Gate = 1
	#竞技场
	Arena = 2
	# 活动副本
	HuodongFuben = 3
	#无尽之塔
	EndlessTower = 4
	# 公会副本
	UnionFuben = 5
	# 限时PVP（王者）
	Craft = 6
	# 元素挑战
	Clone = 7
	# 随机试炼塔
	RandomTower = 8
	# 公会战
	UnionFight = 9
	# 跨服石英大会
	CrossCraft = 10
	# 世界Boss
	WorldBoss = 11
	# 跨服竞技场
	CrossArena = 12
	# 跨服实时对战
	CrossOnlineFight = 13
	# 道馆
	Gym = 14
	# 活动Boss
	HuoDongBoss = 15
	# 道馆PVP
	GymPvp = 16
	# 跨服资源战PVP
	CrossMine = 17
	# 跨服资源战boss
	CrossMineBoss = 18
	# 勇者挑战
	BraveChallenge = 19
	# 远征
	Hunting = 20
	# 夏日挑战
	SummerChallenge = 21
	# 部屋大作战
	CrossUnionFight = 22


class EndlessTowerDefs(object):

	# 关卡特殊条件
	NatureTypeValid = 1 # 限制可上阵的精灵自然属性
	NatureTypeInvalid = 2 # 限制不可上阵的精灵自然属性
	SelfAttrsAmend = 3 # 我方属性修正
	EnemyAttrsAmend = 4 # 敌方属性修正
	BothAttrsAmend = 5 # 双方属性修正
	RarityLimit = 6 # 强制上阵特定稀有度的精灵数量

class EffortValueDefs(object):

	# 培养类型
	GeneralTrain = 1  # 普通培养
	SeniorTrain = 2  # 高级培养

class TrainerDefs(object):
	# 钻石扭蛋每日首次半价
	FirstRMBDrawCardHalf = 1
	# 体力上限+x
	StaminaMax = 2
	# 体力购买上限增加
	StaminaBuyTimes = 3
	# 金币购买上限增加
	LianjinBuyTimes = 4
	# 某些战斗情景可以跳过战斗
	BattleSkip = 5
	# 日常任务获得经验增加(百分比)
	DailyTaskExpRate = 6
	# 金币副本次数增加
	HuodongTypeGoldTimes = 7
	# 经验副本次数增加
	HuodongTypeExpTimes = 8
	# 经验药水购买价格下降(百分比)
	ExpItemCostFallRate = 9
	# 解锁升级属性
	TrainerAttrSkills = 10

	# 金币抽卡免费次数增加
	FreeGoldDrawCardTimes = 11
	# 点金免费次数增加
	LianjinFreeTimes = 12
	# 点金额外获得量(百分比)
	LianjinDropRate = 13
	# 体力领取
	StaminaGain = 14
	# 金币副本产出增加(百分比)
	HuodongTypeGoldDropRate = 15
	# 经验副本产出(百分比)
	HuodongTypeExpDropRate = 16
	# 公会捐献时公会币获得增加(百分比)
	UnionContribCoinRate = 17
	# 普通副本金币获得量增加(百分比)
	GateGoldDropRate = 18
	# 精英副本金币获得量增加(百分比)
	HeroGateGoldDropRate = 19

	# 副本扫荡次数开放(次数)
	GateSaoDangTimes = 20
	# 探险器寻宝额外免费次数
	DrawItemFreeTimes = 21
	# 派遣任务免费刷新次数
	DispatchTaskFreeRefreshTimes = 22
	# 礼物副本次数增加
	HuodongTypeGiftTimes = 23
	# 礼物副本产出增加(百分比)
	HuodongTypeGiftDropRate = 24
	# 碎片副本次数增加
	HuodongTypeFragTimes = 25
	# 碎片副本产出增加(百分比)
	HuodongTypeFragDropRate = 26

	# 每日首次钻石寻宝1次特权半价（探险器功能里）
	FirstRMBDrawItemHalf = 27


class PropertySwapDefs(object):
	# 继承（属性交换）
	CharacterSwap = 1
	NvalueSwap = 2
	EffortSwap = 3


class DispatchTaskDefs(object):
	# 派遣任务状态
	TaskFinish = 1       # 已完成
	TaskCanGet = 2       # 可接取
	TaskFighting = 3     # 进行中

	# 品质
	CQuality = 1
	BQuality = 2
	AQuality = 3
	SQuality = 4
	S2Quality = 5


class CardResetDefs(object):

	# 消耗类型
	cardRmbCostType = 1  		# 卡牌
	heldItemRmbCostType = 2    # 携带道具
	gemCostType = 3            # 宝石
	chipCostType = 4           # 芯片

class CardFeelEffectTypeDefs(SceneDefs):
	# 自身属性加成
	Card = 1
	# 指定元素卡牌属性加成
	CardNatureType = 2
	# 全体卡牌属性加成
	CardsAll = 3
	# 上阵前排(只针对战斗内)
	BattleFront = 4
	# 上阵后排(只针对战斗内)
	BattleBack = 5

	# 加成场景, 具体场景在SceneDefs内
	# 所有战斗场景内生效
	AllBattle = -1

class RandomTowerDefs(object):
	# 卡面类型
	MonsterType = 1       # 怪物
	BuffType = 2       	  # buff
	BoxType = 3       	  # 宝箱
	EventType = 4  		  # 事件

	StarRate = {3: 2, 2: 1.5, 1: 1}

	# 宝箱类型
	CommonType = 1  # 普通
	SpecialType = 2  # 豪华

	# buff类型
	BuffAttrAdd = 1   # 属性加成
	BuffSupply = 2    # 补给
	BuffPointAdd = 3  # 积分加成
	BuffSkill = 4     # 被动技能

	# 补给类型
	SupplyHp = 1  # 回血
	SupplyMp = 2  # 回怒
	SupplyRevive = 3  # 复活
	SupplyCutHp = 4  # 扣血
	SupplyCutMp = 5  # 扣怒

	# 补给目标
	SupplyTargetOne = 1  # 选择一只
	SupplyTargetBattle = 2  # 上阵阵容
	SupplyTargetAll = 3  # 全体

	# 前置条件
	BuffCardHp = 1  # 有残血精灵
	BuffCardMp = 2  # 有不满怒气精灵
	BuffCardDead = 3  # 有死亡精灵

	# 积分加成类型
	PointRoundType = 1  # 剩余回合数
	PointAliveType = 2  # 存活精灵数
	PointFloorType = 3  # 当前层数

	# 跳过步骤
	JumpBegin = 0  # 进入前
	JumpPoint = 1  # 直通高层 积分
	JumpBox = 2  # 宝箱
	JumpBuff = 3  # 加成
	JumpEvent = 4  # 事件
	JumpEnd = 5  # 结束

	# 宝箱打开次数类型
	BoxOpen1 = "open1"  # 开一次
	BoxOpen5 = "open5"  # 开五次


class PasspostDefs(object):
	# 购买类型
	BuyCardType = 1       # 购买通行证
	BuyExpType = 2        # 购买经验

	# 通行证类型
	CommonCardType = 1  # 普通通行证
	SpecialCardType = 2  # 直升通行证

	# 任务周期类型
	TaskDaily = 1  # 每日
	TaskWeek = 2   # 每周

	# 任务领取标志
	# 0-没有奖励
	# 1-有奖励
	# 2-已领取
	# 3-已完成(但暂不可领取)
	TaskNoneFlag = 0
	TaskOpenFlag = 1
	TaskCloseFlag = 2
	TaskAchieveFlag = 3

	# 任务类型
	# 3-普通任务
	# 4-大师专属任务
	Task = 3
	MasterTask = 4


class CardAbilityDefs(object):

	# 激活条件
	LevelType = 1  		# 精灵等级
	AdvanceType = 2     # 突破等级

	# 属性加成类型
	AttrAddScene = 1   # 指定场景内
	AttrAddAll = 2	  # 全队加成
	AttrAddOne = 3	  # 精灵自身

	# 效果类型
	EffectAttrType = 1  # 属性
	EffectSkillType = 2  # 技能

class CaptureDefs(object):
	GateType = 1 # 关卡捕捉
	LimitType = 2 # 限时捕捉

class DrawSumBoxDefs(object):
	LimitUpDrawType = 1 # 运营活动（限时 up 抽卡)
	RMBType = 2 # 钻石抽卡
	GoldType = 3 # 金币抽卡
	EquipType = 4 # 饰品抽卡
	LimitUpDrawGemType = 5 # 限定符石up抽取
	ChipType = 6 # 芯片抽卡


class RetrieveDefs(object):

	# 找回标识
	Free = 'free'  # 免费找回
	RMB = 'rmb'  # 钻石找回


class CrossArenaDefs(object):

	# 每日奖励标识
	DailyAwardNoneFlag = -1
	DailyAwardCloseFlag = 0
	DailyAwardOpenFlag = 1

	# 阶段奖励表示
	StageAwardNoneFlag = -1
	StageAwardCloseFlag = 0
	StageAwardOpenFlag = 1


class MegaDefs(object):

	# 超进化条件
	RoleLevel = 1  # 角色等级
	CardLevel = 2  # 卡牌等级

	# 超进化消耗卡牌 匹配类型
	CostCardsRarityType = 1  # 稀有度
	CostCardsMarkIDType = 2  # markID

	# 超进化材料
	MegaCommonItem = 1  # 钥石
	MegaItem = 2  # 进化石


class GymDefs(object):

	# 副本奖励
	PassAwardCloseFlag = 0
	PassAwardOpenFlag = 1

	# 加成类型
	AttrType = 1
	SkillType = 2


class DeployDefs(object):

	# 布阵类型
	GeneralType = 1  # 常规
	OneByOneType = 2  # 单挑
	WheelType = 3  # 车轮战


class BadgeDefs(object):

	# 勋章解锁条件
	AwakeLevel = 1
	TalentLevel = 2

	# 守护精灵栏位解锁条件类型
	BadgeAwake = 1


class ReunionDefs(object):
	# 任务主题
	# 1-每日签到
	# 2-相逢有时
	SignIn = 1
	Reunion = 2

	# 任务领取标志
	# 0-没有奖励
	# 1-有奖励
	# 2-已领取
	TaskNoneFlag = 0
	TaskOpenFlag = 1
	TaskCloseFlag = 2

	# 绑定类型
	# 1-好友
	# 2-推荐
	Friend = 1
	Recommend = 2

	# 角色类型
	# 1-回归玩家
	# 2-资深玩家
	ReunionRole = 1
	SeniorRole = 2

	# 奖励类型
	# 1-重聚礼包
	# 2-绑定奖励
	# 3-任务奖励
	# 4-积分奖励
	ReunionGift = 1
	BindAward = 2
	TaskAward = 3
	PointAward = 4

	# 限购类型
	# 1-当日限购
	# 2-本次活动内限购
	# 3-不限购
	DayLimit = 1
	ActLimit = 2
	NoLimit = 3

	# 进度赶超加成类型
	# 1-活动副本次数增加
	# 2-冒险之路扫荡翻倍
	# 3-关卡产出双倍
	# 4-体力购买双倍
	# 5-聚宝产出双倍
	HuodongCount = 1
	EndlessSaodang = 2
	DoubleDropGate = 3
	DoubleBuyStamina = 4
	DoubleLianjin = 5

	# 进度赶超加成持续类型
	DayCount = 1
	TimesCount = 2

	# 绑定冷却类型
	# 1-长冷却
	# 2-短冷却
	LongCD = 1
	ShortCD = 2


# 公会问答
class UnionQADefs(object):
	# 题目类型
	# 文本问答1
	# 文本问答2
	# 文本问答3
	# 图片问答
	# 小游戏
	TextQ1 = 1
	TextQ2 = 2
	TextQ3 = 3
	PictureQ = 4
	GameQ = 5

	# 小游戏类型
	# 消失的精灵
	DisappearCard = 1

	# 总排行
	TotalRankNum = 8

	# 排行
	RankNums = [6, 7, 8]
	RankSize = 50
	RankMainSize = 10


class DailyAssistantDefs(object):
	# tab类型
	Award = 1
	Draw = 2
	Signup = 3
	Fuben = 4
	Union = 5

	# 奖励领取
	UnionDailyGift = 101  # 公会每日礼包
	UnionRedpacket = 102  # 公会每日红包
	TrainerAward = 103  # 冒险执照每日奖励
	GainGold = 104  # 聚宝
	# 抽卡
	DrawCardRmb = 201  # 钻石抽卡
	DrawCardGold = 202  # 金币抽卡
	DrawEquip = 203  # 饰品抽卡
	DrawItem = 204  # 探险寻宝
	DrawGem = 205  # 抽符石
	DrawChip = 206  # 抽芯片
	# 战斗报名
	CraftSignup = 301  # 石英大会
	UnionFightSignup = 302  # 公会战
	CrossCraftSignup = 303  # 跨服石英大会
	# 快速冒险
	HuodongFuben = 401  # 日常副本
	Endless = 402  # 冒险之路
	Fishing = 403  # 钓鱼
	# 公会事宜
	UnionContrib = 501  # 公会捐献
	UnionFragDonate = 502  # 公会许愿
	UnionTrainingSpeedup = 503  # 为好友加速
	UnionFuben = 504  # 公会副本


# YYHuoDongDefs 主题通行证，玩法类型
class PlayPassportDefs(object):
	Login = 1  # 登录
	DailyTask = 2  # 日常任务累计活跃度
	RandomTower = 3  # 以太乐园通关累计层数(领取最后的宝箱算一层)
	Gym = 4  # 道馆副本累计完成次数（失败的不计，pvp, 馆主npc不计）


# 勇者挑战
class BraveChallengeDefs(object):
	# 成就类型
	PassTimes = 1  # 通关次数
	UnlockCard = 2  # 解锁指定卡牌
	PassRound = 3  # 通关回合数小于x
	KillCount = 4  # 累计击杀
	DieCount = 5  # 累计阵亡
	GainBadge = 6  # 累计获得勋章数

	# 计数类型
	TypeCount = {1, 4, 5, 6}

	# 勋章类型
	BadgeGainCard = 3  # 招募卡牌


# 远征
class HuntingDefs(object):
	# 节点类型
	BattleType = 1  # 战斗类型
	BoxType = 2  # 宝箱类型
	SupplyType = 3  # 救援类型
	MultiType = 4  # 组合类型

	# 路线类型
	RouteType = 1  # 普通
	SpecialRouteType = 2  # 进阶


# 部屋大作战
class CrossUnionFightDefs(object):
	# 阶段类型
	PreStage = 1  # 初赛
	TopStage = 2  # 决赛

	TopGroup = 5  # 决赛特殊分组为5

	# 战场类型
	BattleSix = 1   # 常规6v6
	BattleFour = 2  # 车轮4v4
	BattleOne = 3   # 单挑1v1

	# status 状态
	StatusStart = "start"     			# 周五 5:00 - 8:50
	StatusPrePrepare = "prePrepare"  	# 周五 8:50 - 20:50
	StatusPreStart = "preStart"   		# 周五 20:50 - 21:00
	StatusPreBattle = "preBattle"  		# 周五 21:00 - 战斗结束
	StatusPreOver = "preOver"    		# 周五 战斗结束 - 21:30
	StatusPreAward = "preAward"  		# 周五 21:30 - 周日 9:00
	StatusTopPrepare = "topPrepare" 	# 周日 9:00 - 20:50
	StatusTopStart = "topStart"   		# 周日 20:50 - 21:00
	StatusTopBattle = "topBattle"  		# 周日 21:00 - 战斗结束
	StatusTopOver = "topOver"    		# 周日 战斗结束 - 21:30
	StatusClosed = "closed"     		# 周日 21:30 - 下期


# 五一派遣
class YYDispatchDefs(object):
	# 派遣状态
	# 1-派遣中
	# 2-派遣结束
	DispatchStart = 1
	DispatchEnd = 2

	# 派遣要求
	# 1-委托精灵x个
	# 2-x元素精灵y个
	# 3-指定markID精灵领队
	# 4-性别为x或y的精灵z个
	# 5-身高x及以上的精灵y个
	# 6-身高x及以下的精灵y个
	# 7-体重x及以上的精灵y个
	# 8-体重x及以下的精灵y个
	# 9-卡牌好感度x以上y个
	# 10-稀有度x以上的精灵y个
	# 11-元素满足多个
	CardCount = 1
	CardNature = 2
	CardMarkID = 3
	CardGender = 4
	HeightHigh = 5
	HeightLow = 6
	WeightHeavy = 7
	WeightLight = 8
	CardFeel = 9
	CardRarity = 10
	CardNature2 = 11

	# 派遣类型
	# 1-主线派遣
	# 2-分支派遣
	# 3-宝箱
	MainDispatch = 1
	BranchDispatch = 2
	AwardBox = 3

	# 成就任务类型
	# 1-指定派遣任务
	# 2-消耗行动点数
	# 3-完成x次分支任务
	# 4-达成x次加分要求
	# 5-日常任务
	DispatchType = 1
	CostType = 2
	BranchType = 3
	ExtraType = 4
	DailyType = 5


# 沙滩排球
class YYVolleyballDefs(object):
	# 每日任务
	dailyVictory = 101  # 每日胜场
	dailyScore = 102  # 每日得分
	dailyNum = 103  # 每日场次

	# 累计任务
	allVictory = 201  # 玩家获胜总场数
	enemyCardID = 202  # 根据敌人种类完成对应任务
	outBoundTimes = 203  # 打到对方界外次数
	myCardID = 204  # 己方精灵种类
	numOfParticipation = 205  # 玩家参与总场数
	skill1Score = 206  # 技能一成功击中对手的次数
	skill2Score = 207  # 技能二成功得分的次数

	allSumTaskDone = 208  # 完成所有累计任务

	cardIDTypes = (enemyCardID, myCardID)
	tasksTypes = (
		dailyScore,
		enemyCardID,
		outBoundTimes,
		myCardID,
		skill1Score,
		skill2Score,
	)
