--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2019 TianJi Information Technology Inc.
--

-- pokemon新属性枚举
-- #1 hp	HP
-- #2 mp1	MP1
-- #3 initMp1 MP1初始值
-- #4 hpRecover	HP回复
-- #5 mp1Recover	MP1回复
-- X 预留 #6 mp2Recover	MP2回复
-- #7 damage	物理攻击
-- #8 specialDamage	特殊攻击
-- #9 defence	物理防御力
-- #10 specialDefence	特殊防御力
-- #11 defenceIgnore	物理防御忽视
-- #12 specialDefenceIgnore	特殊防御忽视
-- #13 speed	先手值
-- #14 strike	暴击
-- #15 strikeDamage	暴击伤害
-- #16 strikeResistance	暴击抗性
-- #17 block	格挡等级
-- #18 breakBlock	破格挡等级
-- #19 blockPower	格挡强度
-- #20 dodge	闪避
-- #21 hit	命中
-- #22 damageAdd	伤害加成
-- #23 damageSub	伤害减免
-- #24 ultimateAdd	必杀加成
-- #25 ultimateSub	必杀抗性
-- #26 suckBlood	吸血
-- #27 rebound	反弹
-- #28 cure	治疗效果
-- X 未确定 #29 natureRestraint	属性克制 X
-- #30 damageDeepen	伤害加深  	  不同于伤害加成
-- #31 damageReduce	伤害降低      不同于伤害减免
--	#32 physicalDamageAdd = 0, -- 物理攻击伤害加成
--	#33 physicalDamageSub = 0, -- 物理攻击伤害减免
--	#34 specialDamageAdd = 0, -- 特殊攻击伤害加成
--	#35 specialDamageSub = 0, -- 特殊攻击伤害减免

-- # 自然属性伤害加成
-- #36 normalDamageAdd 一般系伤害加成
-- #37 fireDamageAdd 火系伤害加成
-- #38 waterDamageAdd 水系伤害加成
-- #39 grassDamageAdd 草系伤害加成
-- #40 electricityDamageAdd 电系伤害加成
-- #41 iceDamageAdd 冰系伤害加成
-- #42 combatDamageAdd 格斗系伤害加成
-- #43 poisonDamageAdd 毒系伤害加成
-- #44 groundDamageAdd 地面系伤害加成
-- #45 flyDamageAdd 飞行系伤害加成
-- #46 superDamageAdd 超能系伤害加成
-- #47 wormDamageAdd 虫系伤害加成
-- #48 rockDamageAdd 岩石系伤害加成
-- #49 ghostDamageAdd 幽灵系伤害加成
-- #50 dragonDamageAdd 龙系伤害加成
-- #51 evilDamageAdd 恶系伤害加成
-- #52 steelDamageAdd 钢系伤害加成
-- #53 fairyDamageAdd 妖精系伤害加成

-- # 自然属性伤害减免
-- #54 normalDamageSub 一般系伤害减免
-- #55 fireDamageSub 火系伤害减免
-- #56 waterDamageSub 水系伤害减免
-- #57 grassDamageSub 草系伤害减免
-- #58 electricityDamageSub 电系伤害减免
-- #59 iceDamageSub 冰系伤害减免
-- #60 combatDamageSub 格斗系伤害减免
-- #61 poisonDamageSub 毒系伤害减免
-- #62 groundDamageSub 地面系伤害减免
-- #63 flyDamageSub 飞行系伤害减免
-- #64 superDamageSub 超能系伤害减免
-- #65 wormDamageSub 虫系伤害减免
-- #66 rockDamageSub 岩石系伤害减免
-- #67 ghostDamageSub 幽灵系伤害减免
-- #68 dragonDamageSub 龙系伤害减免
-- #69 evilDamageSub 恶系伤害减免
-- #70 steelDamageSub 钢系伤害减免
-- #71 fairyDamageSub 妖精系伤害减免

-- # 自然属性治疗效果加成
-- #72 normalCure 一般系治疗效果加成
-- #73 fireCure 火系治疗效果加成
-- #74 waterCure 水系治疗效果加成
-- #75 grassCure 草系治疗效果加成
-- #76 electricityCure 电系治疗效果加成
-- #77 iceCure 冰系治疗效果加成
-- #78 combatCure 格斗系治疗效果加成
-- #79 poisonCure 毒系治疗效果加成
-- #80 groundCure 地面系治疗效果加成
-- #81 flyCure 飞行系治疗效果加成
-- #82 superCure 超能系治疗效果加成
-- #83 wormCure 虫系治疗效果加成
-- #84 rockCure 岩石系治疗效果加成
-- #85 ghostCure 幽灵系治疗效果加成
-- #86 dragonCure 龙系治疗效果加成
-- #87 evilCure 恶系治疗效果加成
-- #88 steelCure 钢系治疗效果加成
-- #89 fairyCure 妖精系治疗效果加成

-- 属性表
local AttrsTable = {
	hpMax	= 0, -- HP
	mp1Max	= 0, -- MP1
	initMp1	= 0, -- MP1初始值
	hpRecover	= 0, -- HP回复
	mp1Recover	= 0, -- MP1回复
	-- mp2Recover	= 0, -- MP2回复
	damage	= 0, -- 物理攻击
	specialDamage	= 0, -- 特殊攻击
	defence	= 0, -- 物理防御力
	specialDefence	= 0, -- 特殊防御力
	defenceIgnore	= 0, -- 物理防御忽视
	specialDefenceIgnore	= 0, -- 特殊防御忽视
	speed	= 0, -- 先手值
	strike	= 0, -- 暴击
	strikeDamage	= 0, -- 暴击伤害
	strikeResistance	= 0, -- 暴击抗性
	block	= 0, -- 格挡等级
	breakBlock	= 0, -- 破格挡等级
	blockPower	= 0, -- 格挡强度
	dodge	= 0, -- 闪避
	hit	= 0, -- 命中
	damageAdd	= 0, -- 伤害加成
	damageSub	= 0, -- 伤害减免
	ultimateAdd	= 0, -- 必杀加成
	ultimateSub	= 0, -- 必杀抗性
	suckBlood	= 0, -- 吸血
	rebound	= 0, -- 反弹
	cure	= 0, -- 治疗效果
	controlPer = 0, -- 控制命中率
	immuneControl = 0, -- 控制免疫率
	natureRestraint	= 0, -- 属性克制
	damageDeepen = 0, -- 伤害加深
	damageReduce = 0, -- 伤害降低
	physicalDamageAdd = 0, -- 物理攻击伤害加成
	physicalDamageSub = 0, -- 物理攻击伤害减免
	specialDamageAdd = 0, -- 特殊攻击伤害加成
	specialDamageSub = 0, -- 特殊攻击伤害减免
	--自然属性伤害加成
	normalDamageAdd = 0,
	fireDamageAdd = 0,
	waterDamageAdd = 0,
	grassDamageAdd = 0,
	electricityDamageAdd = 0,
	iceDamageAdd = 0,
	combatDamageAdd = 0,
	poisonDamageAdd = 0,
	groundDamageAdd = 0,
	flyDamageAdd = 0,
	superDamageAdd = 0,
	wormDamageAdd = 0,
	rockDamageAdd = 0,
	ghostDamageAdd = 0,
	dragonDamageAdd = 0,
	evilDamageAdd = 0,
	steelDamageAdd = 0,
	fairyDamageAdd = 0,
	--自然属性伤害减免
	normalDamageSub = 0,
	fireDamageSub = 0,
	waterDamageSub = 0,
	grassDamageSub = 0,
	electricityDamageSub = 0,
	iceDamageSub = 0,
	combatDamageSub = 0,
	poisonDamageSub = 0,
	groundDamageSub = 0,
	flyDamageSub = 0,
	superDamageSub = 0,
	wormDamageSub = 0,
	rockDamageSub = 0,
	ghostDamageSub = 0,
	dragonDamageSub = 0,
	evilDamageSub = 0,
	steelDamageSub = 0,
	fairyDamageSub = 0,
	--自然属性治疗效果加成
	normalCure = 0,
	fireCure = 0,
	waterCure = 0,
	grassCure = 0,
	electricityCure = 0,
	iceCure = 0,
	combatCure = 0,
	poisonCure = 0,
	groundCure = 0,
	flyCure = 0,
	superCure = 0,
	wormCure = 0,
	rockCure = 0,
	ghostCure = 0,
	dragonCure = 0,
	evilCure = 0,
	steelCure = 0,
	fairyCure = 0,
    --特殊模式下的加成
    --仅在竞技场、石英大会内生效
    pvpDamageAdd	= 0, -- PVP伤害加成
	pvpDamageSub	= 0, -- PVP伤害减免
	-- 以下均为战斗内部属性
	strikeDamageSub = 0, --暴击伤害减免
	-- 治疗效果 百分比提升目标治疗别人的效果
	-- healAdd 影响施法者的技能回血与addhp（大于0）
	-- A给B治疗，A提升healAdd受影响；反之B提升不受影响
	healAdd = 0,
	-- 被治疗效果 百分比提升目标所受到的治疗效果
	-- beHealAdd 影响享受治疗者的技能回血与addhp（大于0）
	-- A给B治疗，B提升beHealAdd受影响；反之A提升不受影响
	beHealAdd = 0,
    -- 来自buff的伤害加成
    damageRateAdd = 0,

    damageHit = 0, -- 伤害命中
	damageDodge = 0, -- 伤害闪避

	ignoreDamageSub = 0, -- 无视免伤
	ignoreStrikeResistance = 0, -- 无视抗暴击

	finalSkillAddRate = 0, --技能伤害加成

	finalDamageAdd = 0, -- 作用于damamge_process result字段
	finalDamageSub = 0, -- 作用于damamge_process result字段

	finalDamageDeepen = 0,
	finalDamageReduce = 0,

	mpBeAttackRecover = 0, --beAttack回怒加成

	trueDamageAdd	= 0, -- 真实伤害加成 dmgDeltaProcess
	trueDamageSub	= 0, -- 真实伤害减免 dmgDeltaProcess

	natureResistance = 0, -- 自然属性克制抵抗
}
local SaltAttrsTable = table.salttable(AttrsTable)

local function intFuncFinalWrap(attr, min)
	return function (self, getBase2)
		if type(min) == "string" then
			min = ConstSaltNumbers[min]
		end

		if getBase2 then
			local v = self.base2[attr] + self.buff[attr]
			return math.max(v, min)
		else
			local v = self.base[attr] + self.buff[attr]
			self.final[attr] = math.max(v, min)
		end
	end
end

-- 10000 = 100%
local function floatFuncFinalWrap(attr, min, start)
	return function (self, getBase2)
		if type(start) == "string" then
			start = ConstSaltNumbers[start]
		end
		if type(min) == "string" then
			min = ConstSaltNumbers[min]
		end

		if getBase2 then
			local v = (start or 0) + self.base2[attr] + self.buff[attr]
			return math.max(v / ConstSaltNumbers.wan, min)
		else
			local v = (start or 0) + self.base[attr] + self.buff[attr]
			self.final[attr] = math.max(v / ConstSaltNumbers.wan, min)
		end
	end
end

local function gateTypeWrapGen(wrap, key)
	-- local allowGateTypeTab = arraytools.hash(gateTypeTab)
    return function(self)
		if self.sceneTag[key] then
            wrap(self)
        end
    end
end

-- {
-- 	game.GATE_TYPE.arena,
-- 	game.GATE_TYPE.crossArena,
-- 	game.GATE_TYPE.craft,
-- 	game.GATE_TYPE.crossCraft,
-- 	game.GATE_TYPE.unionFight,
-- 	game.GATE_TYPE.gymLeader,
-- 	game.GATE_TYPE.crossGym,
-- 	game.GATE_TYPE.crossOnlineFight,
-- 	game.GATE_TYPE.friendFight,
-- }

local AttrGateTypes = {
	PVP = "pvpAttrTakeEffect"
}

local AttrsFinalFuncTable = {
	hpRecover = intFuncFinalWrap('hpRecover', 'zero'),
	damage = intFuncFinalWrap('damage', 'zero'),
	specialDamage = intFuncFinalWrap('specialDamage', 'zero'),
	defence = intFuncFinalWrap('defence', 'zero'),
	specialDefence = intFuncFinalWrap('specialDefence', 'zero'),
	defenceIgnore = floatFuncFinalWrap('defenceIgnore', 'zero'),
	specialDefenceIgnore = floatFuncFinalWrap('specialDefenceIgnore', 'zero'),
	hpMax = intFuncFinalWrap('hpMax', 'one'),
	mp1Max = intFuncFinalWrap('mp1Max', 'one'),
	speed = intFuncFinalWrap('speed', 'zero'),
	initMp1 = intFuncFinalWrap('initMp1', 'zero'),

	mp1Recover = floatFuncFinalWrap('mp1Recover', 'neg1'),
	strike = floatFuncFinalWrap('strike', 'zero'),
	strikeDamage = floatFuncFinalWrap('strikeDamage', 'zero'),
	strikeResistance = floatFuncFinalWrap('strikeResistance', 'zero'),
	block = floatFuncFinalWrap('block', 'zero'),
	breakBlock = floatFuncFinalWrap('breakBlock', 'zero'),
	blockPower = floatFuncFinalWrap('blockPower', 'zero'),
	dodge = floatFuncFinalWrap('dodge', 'zero'),
	hit = floatFuncFinalWrap('hit', 'zero'),
	damageAdd = floatFuncFinalWrap('damageAdd', 'zero'),
	damageSub = floatFuncFinalWrap('damageSub', 'zero'),
	suckBlood = floatFuncFinalWrap('suckBlood', 'zero'),
	rebound = floatFuncFinalWrap('rebound', 'zero'),
	ultimateAdd = floatFuncFinalWrap('ultimateAdd', 'zero'),
	ultimateSub = floatFuncFinalWrap('ultimateSub', 'zero'),
	controlPer = floatFuncFinalWrap('controlPer', 'zero'),
	immuneControl = floatFuncFinalWrap('immuneControl', 'zero'),
    natureRestraint = floatFuncFinalWrap('natureRestraint', 'zero'),

	cure = floatFuncFinalWrap('cure', 'dot05', 'zero'),
	damageDeepen = floatFuncFinalWrap('damageDeepen', 'zero'),
	damageReduce = floatFuncFinalWrap('damageReduce', 'zero'),
	physicalDamageAdd = floatFuncFinalWrap('physicalDamageAdd', 'zero'),
	physicalDamageSub = floatFuncFinalWrap('physicalDamageSub', 'zero'),
	specialDamageAdd = floatFuncFinalWrap('specialDamageAdd', 'zero'),
	specialDamageSub = floatFuncFinalWrap('specialDamageSub', 'zero'),
	normalDamageAdd = floatFuncFinalWrap('normalDamageAdd', 'zero'),
	fireDamageAdd = floatFuncFinalWrap('fireDamageAdd', 'zero'),
	waterDamageAdd = floatFuncFinalWrap('waterDamageAdd', 'zero'),
	grassDamageAdd = floatFuncFinalWrap('grassDamageAdd', 'zero'),
	electricityDamageAdd = floatFuncFinalWrap('electricityDamageAdd', 'zero'),
	iceDamageAdd = floatFuncFinalWrap('iceDamageAdd', 'zero'),
	combatDamageAdd = floatFuncFinalWrap('combatDamageAdd', 'zero'),
	poisonDamageAdd = floatFuncFinalWrap('poisonDamageAdd', 'zero'),
	groundDamageAdd = floatFuncFinalWrap('groundDamageAdd', 'zero'),
	flyDamageAdd = floatFuncFinalWrap('flyDamageAdd', 'zero'),
	superDamageAdd = floatFuncFinalWrap('superDamageAdd', 'zero'),
	wormDamageAdd = floatFuncFinalWrap('wormDamageAdd', 'zero'),
	rockDamageAdd = floatFuncFinalWrap('rockDamageAdd', 'zero'),
	ghostDamageAdd = floatFuncFinalWrap('ghostDamageAdd', 'zero'),
	dragonDamageAdd = floatFuncFinalWrap('dragonDamageAdd', 'zero'),
	evilDamageAdd = floatFuncFinalWrap('evilDamageAdd', 'zero'),
	steelDamageAdd = floatFuncFinalWrap('steelDamageAdd', 'zero'),
	fairyDamageAdd = floatFuncFinalWrap('fairyDamageAdd', 'zero'),
	normalDamageSub = floatFuncFinalWrap('normalDamageSub', 'zero'),
	fireDamageSub = floatFuncFinalWrap('fireDamageSub', 'zero'),
	waterDamageSub = floatFuncFinalWrap('waterDamageSub', 'zero'),
	grassDamageSub = floatFuncFinalWrap('grassDamageSub', 'zero'),
	electricityDamageSub = floatFuncFinalWrap('electricityDamageSub', 'zero'),
	iceDamageSub = floatFuncFinalWrap('iceDamageSub', 'zero'),
	combatDamageSub = floatFuncFinalWrap('combatDamageSub', 'zero'),
	poisonDamageSub = floatFuncFinalWrap('poisonDamageSub', 'zero'),
	groundDamageSub = floatFuncFinalWrap('groundDamageSub', 'zero'),
	flyDamageSub = floatFuncFinalWrap('flyDamageSub', 'zero'),
	superDamageSub = floatFuncFinalWrap('superDamageSub', 'zero'),
	wormDamageSub = floatFuncFinalWrap('wormDamageSub', 'zero'),
	rockDamageSub = floatFuncFinalWrap('rockDamageSub', 'zero'),
	ghostDamageSub = floatFuncFinalWrap('ghostDamageSub', 'zero'),
	dragonDamageSub = floatFuncFinalWrap('dragonDamageSub', 'zero'),
	evilDamageSub = floatFuncFinalWrap('evilDamageSub', 'zero'),
	steelDamageSub = floatFuncFinalWrap('steelDamageSub', 'zero'),
	fairyDamageSub = floatFuncFinalWrap('fairyDamageSub', 'zero'),
	normalCure = floatFuncFinalWrap('normalCure', 'zero'),
	fireCure = floatFuncFinalWrap('fireCure', 'zero'),
	waterCure = floatFuncFinalWrap('waterCure', 'zero'),
	grassCure = floatFuncFinalWrap('grassCure', 'zero'),
	electricityCure = floatFuncFinalWrap('electricityCure', 'zero'),
	iceCure = floatFuncFinalWrap('iceCure', 'zero'),
	combatCure = floatFuncFinalWrap('combatCure', 'zero'),
	poisonCure = floatFuncFinalWrap('poisonCure', 'zero'),
	groundCure = floatFuncFinalWrap('groundCure', 'zero'),
	flyCure = floatFuncFinalWrap('flyCure', 'zero'),
	superCure = floatFuncFinalWrap('superCure', 'zero'),
	wormCure = floatFuncFinalWrap('wormCure', 'zero'),
	rockCure = floatFuncFinalWrap('rockCure', 'zero'),
	ghostCure = floatFuncFinalWrap('ghostCure', 'zero'),
	dragonCure = floatFuncFinalWrap('dragonCure', 'zero'),
	evilCure = floatFuncFinalWrap('evilCure', 'zero'),
	steelCure = floatFuncFinalWrap('steelCure', 'zero'),
	fairyCure = floatFuncFinalWrap('fairyCure', 'zero'),

    pvpDamageAdd = gateTypeWrapGen(floatFuncFinalWrap('pvpDamageAdd', 'zero'), AttrGateTypes.PVP),
	pvpDamageSub = gateTypeWrapGen(floatFuncFinalWrap('pvpDamageSub', 'zero'), AttrGateTypes.PVP),

	strikeDamageSub = floatFuncFinalWrap('strikeDamageSub', 'zero'),

	healAdd = floatFuncFinalWrap('healAdd', 'neg1'),
	beHealAdd = floatFuncFinalWrap('beHealAdd', 'neg1'),

    damageRateAdd = intFuncFinalWrap('damageRateAdd', 'zero'),

    damageDodge = floatFuncFinalWrap('damageDodge', 'zero'),
	damageHit = floatFuncFinalWrap('damageHit', 'zero'),
	ignoreDamageSub = floatFuncFinalWrap('ignoreDamageSub', 'zero'),
	ignoreStrikeResistance = floatFuncFinalWrap('ignoreStrikeResistance', 'zero'),

	finalSkillAddRate = floatFuncFinalWrap('finalSkillAddRate', 'zero'),

	finalDamageAdd = floatFuncFinalWrap('finalDamageAdd', 'zero'),
	finalDamageSub = floatFuncFinalWrap('finalDamageSub', 'zero'),

	finalDamageDeepen = floatFuncFinalWrap('finalDamageDeepen', 'zero'),
	finalDamageReduce = floatFuncFinalWrap('finalDamageReduce', 'zero'),

	mpBeAttackRecover = floatFuncFinalWrap('mpBeAttackRecover', 'zero'),

	trueDamageAdd = floatFuncFinalWrap('trueDamageAdd', 'zero'),
	trueDamageSub = floatFuncFinalWrap('trueDamageSub', 'zero'),

	natureResistance = floatFuncFinalWrap('natureResistance', 'zero'),
}

local SixDimensionAttrs = {
	-- 六维属性
	hpMax = true,
	mp1Max = true,
	specialDamage = true,
	damage = true,
	defence = true,
	specialDefence = true
}

globals.ObjectAttrs = class("ObjectAttrs")

ObjectAttrs.AttrsTable = AttrsTable
ObjectAttrs.SixDimensionAttrs = SixDimensionAttrs

local function checkAttrsTableCheat()
	for k, v in pairs(AttrsTable) do
		if math.abs(SaltAttrsTable[k] - v) > 1e-5 then
			exitApp("close your cheating software")
		end
	end
end

-- 获取属性转换比例
function globals.getAttrTransformRate(attrName)

	if not AttrsFinalFuncTable[attrName] then
		errorInWindows("getAttrTransformRate %s is not attrName",attrName)
		return 1
	end

	local _self = {
		base = {[attrName] = 1},
		buff = {[attrName] = 0},
		final = {[attrName] = 0}
	}
	AttrsFinalFuncTable[attrName](_self)
	return 1 / _self.final[attrName]
end

function ObjectAttrs:ctor()
	checkAttrsTableCheat()

	-- 基础属性
	self.base = table.salttable(AttrsTable)
	self.base2 = table.salttable(AttrsTable)
	-- buff等所加
	self.buff = table.salttable(AttrsTable)
	-- 光环
	self.aura = table.salttable(AttrsTable)
	-- 计算结果
	self.final = table.salttable(AttrsTable)
    -- 当前场景,适用场景属性
    self.sceneTag = {}

	-- default final value
	self:calcFinal()
end

-- function ObjectAttrs:setGateType(gateType)
--     self.gateType = gateType
-- end

function ObjectAttrs:setSceneTag(sceneTag)
    self.sceneTag = sceneTag or {}
end

function ObjectAttrs:setBase(data)
	data.hpMax = data.hp
	data.mp1Max = data.mp1
	data.damageHit = data.damageHit or 10000
	local base = clone(AttrsTable)
	local base2 = clone(AttrsTable)
	for attr, _ in pairs(base) do
		if data[attr] ~= nil then
			base[attr] = data[attr]
			base2[attr] = data.role2Data and data.role2Data[attr] or data[attr]
		end
		self.aura[attr] = 1
	end

	self.base = table.salttable(base)
	self.base2 = table.salttable(base2)
	self:calcFinal()
end

function ObjectAttrs:correct(cfg)
	for attr, _ in pairs(AttrsTable) do
		local v = cfg[attr .. "C"]
		if v ~= nil then
			self.base[attr] = self.base[attr] * v
			self.base2[attr] = self.base2[attr] * v	-- 多形态一起修正
		end
	end
	self:calcFinal()
end

function ObjectAttrs:calcFinal()
	for attr, f in pairs(AttrsFinalFuncTable) do
		f(self)
	end
end

function ObjectAttrs:updateMaxBaseAttr(attr, val)
	self.base[attr] = math.max(self.base[attr], val)
	AttrsFinalFuncTable[attr](self)
end

function ObjectAttrs:setBaseAttr(attr, val)
	self.base[attr] = val
	AttrsFinalFuncTable[attr](self)
	-- if attr == "speed" then
	-- 	print(string.format("--------速度属性，基础：%s，buff：%s，最终：%s",self.base[attr],self.buff[attr],self.final[attr]))
	-- end
end

function ObjectAttrs:setBase2Attr(attr, val)
	self.base2[attr] = val
end

function ObjectAttrs:setBuffAttr(attr, val)
	self.buff[attr] = val
	AttrsFinalFuncTable[attr](self)
	-- if attr == "speed" then
	-- 	print(string.format("--------速度属性，基础：%s，buff：%s，最终：%s",self.base[attr],self.buff[attr],self.final[attr]))
	-- end
end

function ObjectAttrs:addBaseAttr(attr, delta)
	self.base[attr] = delta + self.base[attr]
	AttrsFinalFuncTable[attr](self)
	-- if attr == "speed" then
	-- 	print(string.format("--------速度属性，基础：%s，buff：%s，最终：%s",self.base[attr],self.buff[attr],self.final[attr]))
	-- end
end

function ObjectAttrs:addBase2Attr(attr, delta)
	self.base2[attr] = delta + self.base2[attr]
end

function ObjectAttrs:addBuffAttr(attr, delta)
	self.buff[attr] = delta + self.buff[attr]
	AttrsFinalFuncTable[attr](self)
	-- if attr == "speed" then
	-- 	print(string.format("--------速度属性，基础：%s，buff：%s，最终：%s",self.base[attr],self.buff[attr],self.final[attr]))
	-- end
end

function ObjectAttrs:addAuraAttr(attr, delta)
	self.aura[attr] = self.aura[attr] + delta
end

function ObjectAttrs:getFinalAttr(attr)
	return self.final[attr] * math.max(self.aura[attr],0)
end

function ObjectAttrs:getBase2FinalAttr(attr)
	return AttrsFinalFuncTable[attr](self, true) * math.max(self.aura[attr],0)
end

function ObjectAttrs:getBase2RealFinalAttr(attr)
	return AttrsFinalFuncTable[attr](self, true)
end

function ObjectAttrs:cloneFinalAttr()
	local ret = {}
	for attr, f in pairs(AttrsTable) do
		ret[attr] = (self.buff[attr] + self.base[attr])
	end
	return ret
end