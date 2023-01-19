--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2019 TianJi Information Technology Inc.
--
--
-- 战斗逻辑对象
--

local abs = math.abs
local _max = math.max
local _min = math.min
local _floor = math.floor

local PassiveSkillTypes = battle.PassiveSkillTypes


globals.ObjectModel = class("ObjectModel")

ObjectModel.IDCounter = 100 -- 100前的预留，比如位置

-- class hack
-- 属性getter, hpMax()最终值
for attr, _ in pairs(ObjectAttrs.AttrsTable) do
	ObjectModel[attr] = function(self, shapeState)
		-- 多形态的情况下获取需要的形态属性
		if self.multiShapeTb then
			if shapeState then
				-- 0:获取另一形态属性 1、2：获取指定形态属性
				if shapeState == 2 or (shapeState == 0 and self.multiShapeTb[1] == 1) then
					return self.attrs:getBase2FinalAttr(attr)
				end
			else
				-- 根据当前形态获取对应属性，并且开关开启时
				if self.multiShapeTb[1] == 2 and self.multiShapeTb[3][attr] then
					return self.attrs:getBase2FinalAttr(attr)
				end
			end
		end

		return self.attrs:getFinalAttr(attr)
	end
end

function ObjectModel:ctor(scene, seat)
	self.scene = scene
	self.view = nil -- view object proxy

	ObjectModel.IDCounter = ObjectModel.IDCounter + 1
	self.id = ObjectModel.IDCounter
	self.seat = seat

	self.attrs = ObjectAttrs.new() -- 属性
	self.skills = {} -- 主动技能 0
	self.passiveSkills = {} -- 被动技能 2 3
	self.skillsOrder = {} -- {skillID1, ...} 技能更新顺序
	self.triggerSkillsOrder = {} -- {trigger type: {skillID1, ...}} 被动技能更新顺序
	self.passiveSkillsOrder = {} -- {skillID1, ...} 被动技能更新顺序

	self.curSkill = nil -- 当前施放的skill
	self.curSelectSkill = nil -- 当前选中的skill
	self.curTargetId = nil -- 当前选择的target

	self.state = battle.ObjectState.none -- 初始化单位状态
	-- keep data safe by salttable
	self.hpTable = table.salttable({0, 0, 0})  -- [1]:正式的血 [2]:只用于显示 [3]:实际血量,可以计算溢出部分
	self.mp1Table = table.salttable({0, 0, 0}) -- [1]:正式的mp [2]:只用于显示 [3]:保存溢出的怒气

	-- buff
	self.buffs = self.scene:createBuffCollection()

	-- 光环buff（加给别人，但自己会记录）
	self.auraBuffs = self.scene:createBuffMap()

	self.buffOverlayCount = {} -- buff叠加类型为6 表示不同目标相同buff.cfgId时的叠加计数 格式 {buffCfgId = count}
	self.changeUnitIDTb = {} --记录自身受到多个变身buff影响时的unitID, 格式:{{buff1,变身前unitID1},{}}，按顺序从buff中取对应的unitID,判断存在性
	self.buffGroupEnchance = {{},{}} --记录自身受到提升或削减其他buff效果的buff {buffGroupID = {buffID = buff的value应该相乘的值}}
	self.speedPriority = 0 -- 移动绝对优先级

	self.battleRound = {[1] = 0,[2] = 0} --1:出手后的时间点 2:出手前的时间点
	self.battleRoundAllWave = {[1] = 0,[2] = 0}
	self.closeSkillType2 = {} --关闭的技能选择 0:普攻 1:小技能 2:大招

	self.ignoreDamageInBattleRound = false
	self.ignoreToAttack = false -- 忽视本次出手

	self.totalDamage = {} -- 总伤害量(包括溢出部分)
	self.totalResumeHp = {} -- 总治疗量(包括溢出部分)
	self.totalTakeDamage = {} -- 总承伤量(每波记录)

	self.recordBuffDataTb = {} -- buff数据记录
 	self.extraRoundData = CList.new() -- 额外回合数据

	self.skillIdToReplaceRecord = {} --技能id对应的替换记录
	self.skillReplaceReocrd = {} --技能替换记录

	self.triggerEnv = {} -- 触发环境

	-- env,公式计算用
	self.protectedEnv = battleCsv.makeProtectedEnv(self)

	-- event
	battleComponents.bind(self, "Event")
	self:setListenerComparer(BuffModel.BuffCmp)
 end

function ObjectModel:init(data)
	self.data = csvClone(data)
	self.dbID = data.cardId
	self.unitID = data.roleId
	self.orginUnitId = data.roleId --保存初始object的unitID 为变身后的原始记录
	self.level = data.level		-- 等级, 对于怪物来说是场景配置的level
	-- self.advance = data.advance -- TODO: 暂时无用
	self.force = (self.seat <= self.scene.play.ForceNumber) and 1 or 2
	self.fightPoint = data.fightPoint or 0
	-- unit.csv
	self.unitCfg = csv.unit[self.unitID]
	if not self.unitCfg then
		error(string.format("no unit config id = %s", self.unitID))
	end
	-- 等策划配置完全后投放使用,外网默认self.star = 0,优先读data.star 没有再读unit.star

	self.type = data.type or battle.ObjectType.Normal
	self.star = data.star or 0
	self.starEffect = data.starEffect or -1
	self.attributeType = self.unitCfg.attributeType -- 属性类型elites, monster
	self.natureType = self.unitCfg.natureType
	self.natureType2 = self.unitCfg.natureType2
	self.rarity = self.unitCfg.rarity
	self.summonCalDamage = self.unitCfg.summonCalDamage -- 召唤物是否参与伤害计算 默认false
	self.battleFlag = {}
	self.cardID = self.unitCfg.cardID
	-- card  (默认为cards表,怪物使用 monster_cards 表)
	self.cardCfg = csv.cards[self.cardID]
	self.markID = self.cardCfg and self.cardCfg.cardMarkID or 0
	self.state = battle.ObjectState.normal

	-- 当前多形态的状态,第一个是当前形态，初始是第一形态,切换形态需要修改，第二个是保存的小技能cd，第三个是属性开关
	self.multiShapeTb = data.role2Data and {1,{},{}} or nil

	-- attributes 初始化
	self:onInitAttributes()
	self.skillInfo = data.skills or {} -- {{skillID = skillLevel}, {skillID = skillLevel}}
	self.passiveSkillInfo = data.passive_skills or {}
	self.attackerCurSkill = {} -- 当前受到的技能
	self.tagSkills = {}

	self.skillsMap = {}	-- 映射关系

	-- 技能
	self:onInitSkills(self.skillInfo, self.passiveSkillInfo)

	-- 开局血量比例
	self.hpScale = data.hpScale
	self.mp1Scale = data.mp1Scale

	self:addObjViewToScene()
	self.faceTo = self.view:proxy():getFaceTo()
	self.view:proxy():setActionState('standby_loop') --刚开始是standby吧
	-- TEST: 初始化为满怒气值
	-- self:setMP1(self:mp1Max(), self:mp1Max())

	-- scene_attr_correct.csv

	self.effectPower = csv.effect_power[self.unitCfg.effectPowerId] -- 效果触发控制
	if self.unitCfg.battleFlag then
		for _,flag in csvPairs(self.unitCfg.battleFlag) do
			self.battleFlag[flag] = true
		end
	end
	-- 总伤害
	for _,v in pairs(battle.DamageFrom) do
		self.totalDamage[v] = battleEasy.valueTypeTable()
	end
	-- 总恢复
	for _,v in pairs(battle.ResumeHpFrom) do
		self.totalResumeHp[v] = battleEasy.valueTypeTable()
	end

	for _, v in pairs(battle.TriggerEnvType) do
		self.triggerEnv[v] = CVector.new()
	end

	self:onInitPassData()
	self:setHP(self:hpMax(), self:hpMax())

	-- 初始化怒气值为initMp1属性
	self:setMP1(self:initMp1(), self:initMp1())
end

function ObjectModel:addObjViewToScene()
    local args = {type = battle.SpriteType.Normal}
	self.view = gRootViewProxy:getProxy('onSceneAddObj', tostring(self), readOnlyProxy(self, {
		hp = function()
			return self:hp(true)
		end,
		mp1 = function()
			return self:mp1(true)
		end,
		setHP = function(_, v)
			return self:setHP(nil, v)
		end,
		setMP1 = function(_, v)
			return self:setMP1(nil, v)
		end,
	}), args)
end

-- 跟回合 波数有关的数据
function ObjectModel:onInitPassData()
	for i=1,self.scene.play.curWave do
		-- 总承伤
		if not self.totalTakeDamage[i] then
			self.totalTakeDamage[i] = battleEasy.valueTypeTable()
		end
	end
end

function ObjectModel:onInitAttributes()
	self.attrs:setSceneTag(self.scene.sceneTag)
	self:setBaseData(self.data)
end

function ObjectModel:setBaseData(base)
	local demonCorrect = battleEasy.ifElse(self.force == 1,self.scene.sceneConf.demonCorrectSelf ,self.scene.sceneConf.demonCorrect)
	local csv_fix = nil
	if demonCorrect then
		csv_fix = gSceneDemonCorrectCsv[demonCorrect][self.scene.play.curWave] or gSceneDemonCorrectCsv[demonCorrect][1]
	end

	if csv_fix then
		local gateFix = self.scene.play:getTopCardsAttrAvg(6)
		local selfForceStr = self.force == 1 and "self" or ""
		local seatExtraFix = csv_fix.seatExtraFix
		local seatExtraFixVal = seatExtraFix[self.seat] or 1
		for key, v in pairs(gateFix) do
			-- scene_demon_correct 修正
			local fixArg = csv_fix[key .. selfForceStr]
			if fixArg[1] and fixArg[2] then
				local rowNum = 2-(math.floor((self.seat+2)/3))%2
				local fixVal = battleEasy.ifElse(rowNum == 1, fixArg[1], fixArg[2])
				base[key] = math.floor(v * fixVal * seatExtraFixVal)
				if base.role2Data then
					base.role2Data[key] = math.floor(v * fixVal * seatExtraFixVal)
				end
			end
		end
	end
	self.attrs:setBase(base)
end

function ObjectModel:checkSkillCheat()
	if ANTI_AGENT then return end

	checkSpecificCsvCheat("skill", itertools.ikeys(itertools.chain({self.skills, self.passiveSkills})))
end

function ObjectModel:onInitPreSkills(skillLevels, additionalPassive)
	local replaceMap = {}

	for skillID, skillLevel in pairs(maptools.extend({skillLevels, additionalPassive})) do
		local skillCfg = csv.skill[skillID]
		if skillCfg.skillArgs then
			for _, data in csvPairs(skillCfg.skillArgs) do
				if type(data) == "table" and data.replaceSkill then
					replaceMap = maptools.extend({replaceMap, data.replaceSkill})
				end
			end
		end
	end

	return replaceMap
end

function ObjectModel:onInitSkills(skillLevels, additionalPassive)
	self.skills = {}
	self.passiveSkills = {}
	self.tagSkills = {}

	local replaceMap = self:onInitPreSkills(skillLevels, additionalPassive)

	local function switchSkillID(skillID)
		return replaceMap[skillID] or skillID
	end

	local function insertTagSkill(skillID, skillCfg, level)
		if skillCfg and skillCfg.skillType2 == battle.MainSkillType.TagSkill then
			self.tagSkills[skillID] = level
			return true
		end
	end

	local function insertSkill(ret, skillID, level)
		local skillCfg = csv.skill[skillID]
		if not insertTagSkill(skillID, skillCfg, level) and not ret[skillID] then
			ret[skillID] = newSkillModel(self.scene, self, skillID, level)
		end
	end

	for skillID,skillLevel in pairs(skillLevels) do
		skillID = switchSkillID(skillID)
		local skillCfg = csv.skill[skillID]
		if not skillCfg then return false end --如果技能通过id拿不到就return，这样会造成单方面攻击的现象且被攻击的对象因为没有技能效果可能变成透明
		if skillCfg.skillType == battle.SkillType.NormalSkill then
			self.skills[skillID] = newSkillModel(self.scene, self, skillID, skillLevel)
		elseif (skillCfg.skillType == battle.SkillType.PassiveAura) or (skillCfg.skillType == battle.SkillType.PassiveSkill) then
			self.passiveSkills[skillID] = newSkillModel(self.scene, self, skillID, skillLevel)
		else
			insertTagSkill(skillID, skillCfg, skillLevel)
		end
	end

	for _, skillID in ipairs(self.unitCfg.skillList) do
		-- if not self.skills[skillID] then
		-- 	self.skills[skillID] = newSkillModel(self.scene, self, skillID, skillLevels[skillID] or 1)
		-- end
		insertSkill(self.skills, switchSkillID(skillID), skillLevels[skillID] or 1)
	end

	for _, skillID in ipairs(self.unitCfg.passiveSkillList) do
		-- if not self.passiveSkills[skillID] then
		-- 	self.passiveSkills[skillID] = newSkillModel(self.scene, self, skillID, skillLevels[skillID] or 1)
		-- end
		insertSkill(self.passiveSkills, switchSkillID(skillID), skillLevels[skillID] or 1)
	end

	for skillID, skillLevel in pairs(additionalPassive) do
		-- if not self.passiveSkills[skillID] then
		-- 	self.passiveSkills[skillID] = newSkillModel(self.scene, self, skillID, skillLevel)
		-- end
		insertSkill(self.passiveSkills, switchSkillID(skillID), skillLevel)
	end

	-- 合体技
	if self.unitCfg.combinationSkillId then
		self.passiveSkills[self.unitCfg.combinationSkillId] = newSkillModel(self.scene,self,self.unitCfg.combinationSkillId,skillLevel)
	end
	-- 变身后需要更新 updateStateInfoTb
	-- 存在先变身 然后执行 onSkillRefresh
	self:updateSkillsOrder()
	self:checkSkillCheat()
	self:resetReplaceSkillRecord()

	for skillID, skill in self:iterSkills() do
		skill:updateStateInfoTb()
	end
end

function ObjectModel:updateSkillsOrder()
	self.skillsOrder = itertools.keys(self.skills)
	table.sort(self.skillsOrder, function(id1, id2)
		return id1 > id2
	end)

	local triggerSkillsOrder = {}
	for skillID, skill in pairs(self.passiveSkills) do
		if triggerSkillsOrder[skill.skillType] == nil then
			triggerSkillsOrder[skill.skillType] = {skillID}
		else
			table.insert(triggerSkillsOrder[skill.skillType], skillID)
		end
	end
	for typ, order in pairs(triggerSkillsOrder) do
		table.sort(order, function(id1, id2)
			local prior1 = csv.skill[id1].passivePriority
			local prior2 = csv.skill[id2].passivePriority
			if prior1 and prior2 and prior1 ~= prior2 then
				return prior1 < prior2
			else
				return id1 < id2
			end
		end)
	end

	local types = {
		triggerSkillsOrder[battle.SkillType.PassiveAura],
		triggerSkillsOrder[battle.SkillType.PassiveSkill],
		triggerSkillsOrder[battle.SkillType.PassiveSummon],
		triggerSkillsOrder[battle.SkillType.PassiveCombine],
	}
	self.triggerSkillsOrder = triggerSkillsOrder
	self.passiveSkillsOrder = arraytools.merge(arraytools.compact(types))

	local buffData = self:getOverlaySpecBuffData(battle.OverlaySpecBuff.changeSkillNature)
	if buffData.refreshAll then
		buffData.refreshAll()
end
end

function ObjectModel:onAddSkills(skillLevels)
	if not (skillLevels and next(skillLevels)) then return end

	local addSkills = {}
	for skillID,skillLevel in pairs(skillLevels) do
		local skillCfg = csv.skill[skillID]
		if not skillCfg then return false end --如果技能通过id拿不到就return，这样会造成单方面攻击的现象且被攻击的对象因为没有技能效果可能变成透明
		if skillCfg.skillType == battle.SkillType.NormalSkill then
			self.skills[skillID] = newSkillModel(self.scene, self, skillID, skillLevel)
			addSkills[skillID] = self.skills[skillID]
		elseif (skillCfg.skillType == battle.SkillType.PassiveAura) or (skillCfg.skillType == battle.SkillType.PassiveSkill) then
			self.passiveSkills[skillID] = newSkillModel(self.scene, self, skillID, skillLevel)
			addSkills[skillID] = self.passiveSkills[skillID]
		else
			insertTagSkill(skillID, skillCfg, skillLevel)
		end
	end

	self:updateSkillsOrder()
	self:checkSkillCheat()

	for skillID, skill in self:iterSkills() do
		if addSkills[skillID] then
			skill:updateStateInfoTb()
		end
	end
end

function ObjectModel:cantBeAttack()
	if self:isDeath() then -- 死
		return true
	end
	return false
end

-- 初始化完成后的被动触发 (不在创建后立即触发, 因为可能有其它同伴也在创建, 等都创建好后再一起触发被动, 保证光环效果能覆盖全)
function ObjectModel:initedTriggerPassiveSkill(isNotTrigger)
	--目前流程暂定为先触发进场被动，后触发光环技能
	if not isNotTrigger then
		self:onPassive(PassiveSkillTypes.enter)
	end

	-- 不能在由7节点触发的环境下执行下面的逻辑
	if self:triggerOriginEnvCheck(battle.TriggerEnvType.PassiveSkill, PassiveSkillTypes.enter) then return end

	self:onPassive("Aura")
	if not isNotTrigger then

		self:triggerBuffOnPoint(battle.BuffTriggerPoint.onHolderAfterEnter)
	end
end

function ObjectModel:hp(show)
	return self.hpTable[show and 2 or 1]
end

function ObjectModel:getCurSkill()
	local gate = self.scene.play
	local curHero = gate.curHero
	return curHero and curHero.curSkill
end

--获取技能类型
function ObjectModel:getSkillType()
	local gate = self.scene.play
	local curHero = gate.curHero
	local skillType = nil
	local mainSkillType = nil
	-- 在技能释放中只有大招情况下隐藏血条
	if curHero and curHero.curSkill then
		skillType = curHero.curSkill.skillType
		mainSkillType = curHero.curSkill.skillType2
	end
	return skillType, mainSkillType
end

function ObjectModel:getSkillByType2(type2)
	for skillID, skill in self:iterSkills() do
		if skill.skillType2 == type2 then
			return skill
		end
	end
end
-- 需要计算溢出伤害的时候都要调用该方法
function ObjectModel:addHp(v)
	local hp = self:hp() + v
	-- 记录死亡时的溢出值
	-- 1. 当前血量(最小为0) + 累加值小于0 记录溢出伤害
	-- 2. 当前血量为0并且累加值大于0时
	-- 	2.1 当前血量 = 当前血量 + 累加值 + 溢出伤害
	--  2.2 溢出伤害 = min(累加值 + 溢出伤害, 0)
	if hp < 0 then
		self.hpTable[3] = self.hpTable[3] + hp
	elseif self:hp() == 0 and v > 0 then
		v = v + self.hpTable[3]
		self.hpTable[3] = math.min(v, 0)
		hp = self:hp() + v
	end
	self:setHP(hp)
end

function ObjectModel:setHP(v, vShow)
	logf.battle.object.setHP('setHP selfSeat= %d, hp Real= %f, hp Show= %f', self.seat, v or -9999, vShow or -9999)
	local hpMax = self:hpMax()
	local _v = v and cc.clampf(v, 0, hpMax)
	local _vShow = vShow and cc.clampf(vShow, 0, hpMax)
	self.hpTable[1] = _v or self.hpTable[1]
	self.hpTable[2] = _vShow or self.hpTable[2]
	--_vShow到底有用么

	-- if self.freezeHp and self.freezeHp > 0 then
	-- 	showHp = showHp - self.freezeHp
	-- end
	-- 死亡时血条不再变动
	if not self:isDeath() then
		local skillType, mainSkillType = self:getSkillType()
		-- battleEasy.deferNotify(self.view, "updateLifebar", {hpPer = showHp/hpMax*100, skillType = skillType, mainSkillType = mainSkillType})
		battleEasy.deferNotify(self.view, "updateLifebar", {skillType = skillType, mainSkillType = mainSkillType})
	end
	--这里再刷新一遍护盾 如果有护盾的话 上面的逻辑会覆盖护盾的数据
	self:refreshShield()
end

function ObjectModel:mp1(show)
	return self.mp1Table[show and 2 or 1]
end

function ObjectModel:mpOverflow()
	return self.mp1Table[3]
end

function ObjectModel:updateMp1Overflow(mp1, oldMp1, mp1Max, mp1OverflowData, changeOverflowFromBuff)
	local mpOverflow = self:mpOverflow()
	if mp1OverflowData and mp1 then
		local mode = mp1OverflowData.mode
		if mode ~= 1 then
			local function dealMp1AndMpOverflow( affectNormalMp )
				local changeMp1 = mp1 - oldMp1
				mpOverflow = mpOverflow + changeMp1
				mp1 = oldMp1
				if affectNormalMp then
					-- 能够影响普通怒气
					if mpOverflow > mp1OverflowData.limit then
						mp1 = mp1 + (mpOverflow - mp1OverflowData.limit)
					elseif mpOverflow < 0 then
						mp1 = mp1 + mpOverflow
					end
				end
				mpOverflow = cc.clampf(mpOverflow, 0, mp1OverflowData.limit)
			end

			local isCharging = self.curSkill and self.curSkill.chargeRound
			if isCharging and mp1OverflowData.extraArgs.changeMpOverflowInCharge then
				-- 技能蓄力时根据配置决定是否先处理溢出怒气
				dealMp1AndMpOverflow(mp1OverflowData.extraArgs.affectNormalMpInCharge)
			elseif changeOverflowFromBuff then
				-- 来源addMp1的buff根据配置决定是否先处理溢出怒气
				dealMp1AndMpOverflow(mp1OverflowData.extraArgs.affectNormalMpFromBuff)
			elseif (mp1 < oldMp1 and mode == 3) then
				-- 比之前怒气减少且mode为3先处理溢出怒气
				dealMp1AndMpOverflow(true)
			end
		end
		if mp1 > mp1Max then
			-- 当前怒气大于最大值了,存入额外怒气
			mpOverflow = (mp1 - mp1Max) * (mode == 1 and 1 or mp1OverflowData.rate) + mpOverflow
			mpOverflow = cc.clampf(mpOverflow , 0, mp1OverflowData.limit)
		end
	end

	return mp1, mpOverflow
end

function ObjectModel:setMP1(v, vShow, args)
	args = args or {}
	--如果有锁怒buff 且 怒气为上升状态时 不更新 mp1
	if not args.ignoreLockMp1Add and self.lockMp1Add and self:mp1() < v then
		return
	end

	logf.battle.object.setMP1(' setMP1 selfSeat= %d, mp Real= %f, mp Show= %f', self.seat, v or -9999, vShow or -9999)
	local oldMp1 = self:mp1()
	local mp1Max = self:mp1Max()
	local resumeMpOverflow = math.max(v - mp1Max, 0)

	local mp1OverflowData = self:getOverlaySpecBuffByIdx("mp1OverFlow")
	local mpOverflow
	v, mpOverflow = self:updateMp1Overflow(v, oldMp1, mp1Max, mp1OverflowData, args.changeMpOverflow)

	v = v and cc.clampf(v, 0, mp1Max)
	vShow = vShow and cc.clampf(vShow, 0, mp1Max)

	self.mp1Table = table.salttable({v or self.mp1Table[1], vShow or self.mp1Table[2], mpOverflow})

	battleEasy.deferNotify(self.view, "updateLifebar", {
		mp1OverflowData = mp1OverflowData,
		mp = v,
		mpOverflow = self:mpOverflow(),
		mpMax = mp1Max,
	})

	if oldMp1 and oldMp1 ~= v then
		self:triggerBuffOnPoint(battle.BuffTriggerPoint.onHolderMp1Change, self)
	end
	if resumeMpOverflow > 0 then
		self:triggerBuffOnPoint(battle.BuffTriggerPoint.onHolderMp1Overflow, {
			resumeMpOverflow = resumeMpOverflow
		})
	end
	--这里再刷新一遍护盾 如果有护盾的话 上面的逻辑会覆盖护盾的数据
	self:refreshShield()
	self.scene.play:refreshUIMp()
end

function ObjectModel:refreshShield()
	-- self.teamShield = self.scene.forceRecordTb[self.force]['teamShield']
	-- 当前单体护盾值
	local buffData = self:getOverlaySpecBuffData("shield")
	local shieldHp = self:shieldHp()
	-- self.shieldHp = 0
	-- 存在护盾护盾状态为true
	-- local shieldStatus = (shieldHp > 0) --or (self.freezeHp and self.freezeHp  > 0)
	-- 当前全体护盾值
	-- local teamShieldHp = self.teamShield and self.teamShield.hp or 0
	-- 全体护盾最大值
	-- local teamMaxShield = self.scene.forceRecordTb[self.force]['maxShield'] or 0
	-- 全体护盾最大值 + 单体护盾最大值
	local maxShield = math.max(buffData.shieldMaxTotal or 0,self:hpMax())-- teamMaxShield + self.maxShield

	-- 当前冰冻中的血量值
	--self.freezeHp = self.freezeHp or 0
	-- local shieldPercent = maxShield <= 0 and 0 or 100 * (self.shieldHp + teamShieldHp)/maxShield  --有护盾的情况下maxShield一定大于
	-- local shieldPercent = maxShield <= 0 and 0 or 100 * shieldHp/maxShield  --有护盾的情况下maxShield一定大于

	local skillType, mainSkillType = self:getSkillType()

	log.battle.object.shield("seat:"..self.seat.." common shieldHpMax:", maxShield, "common shieldHp:", shieldHp)
	-- if shieldPercent <= 0 or shieldStatus then
	-- 	-- battleEasy.deferEffect(tostring(self), "CLifeBar.update2", {shieldPer = shiledPercent, shieldStatus = shieldStatus, from = "shield"})
	-- 	battleEasy.deferNotify(self.view, "updateLifebar", {shieldPer = shieldPercent, shieldStatus = shieldStatus, from = "shield", skillType = skillType, mainSkillType = mainSkillType})
	-- end
	self:refreshLifeBar()
end

function ObjectModel:shieldHp(filterBuff)
	if filterBuff then
		local mark = {}
		local hp = 0
		for _,data in self:ipairsOverlaySpecBuff("shield") do
			if itertools.include(filterBuff, data.cfgId) then
				hp = hp + math.max(data.shieldHp, 0)
			end
		end
		return hp
	else
		local buffData = self:getOverlaySpecBuffData("shield")
		return buffData.shieldTotal or 0
	end
end

function ObjectModel:specialShieldHp()
	local hp = 0
	for _, data in self:ipairsOverlaySpecBuff("shield") do
		if data.showType ~= 0 then
			hp = hp + data.shieldHp
		end
	end
	return hp
end

function ObjectModel:addShieldHp(val, calcList)
	local buffData = self:getOverlaySpecBuffData("shield")
	local delBuffList, beAttackShieldList = {}, {}
	val = math.floor(val)
	local oldVal = val

	-- 扣除护盾总量
	local shieldTotal = calcList and self:shieldHp(calcList) or buffData.shieldTotal
	buffData.shieldTotal = math.max(buffData.shieldTotal + ((shieldTotal + val > 0) and val or -shieldTotal),0)

	-- 扣除各buff的护盾量
	for _,data in self:ipairsOverlaySpecBuff("shield") do
		if not calcList or itertools.include(calcList, data.cfgId) then
			val = val + data.shieldHp
			beAttackShieldList[data.cfgId] = 1 -- 受击标记
			if val <= 0 then
				data.shieldHp = 0
				delBuffList[data.id] = true
				beAttackShieldList[data.cfgId] = 2 -- 破碎标记
			else
				data.shieldHp = val
				break
			end
		end
	end

	if val > oldVal then
		self:triggerBuffOnPoint(battle.BuffTriggerPoint.onHolderShieldChange, {
			-- 待删除护盾buff的cfgId
			beAttackShield = beAttackShieldList
		})
		self:delBuff(delBuffList)
	end
end

function ObjectModel:refreshLifeBar()
	if self:isDeath() then return end

	local hp = self.hpTable[1]
	local hpMax = self:hpMax()
	local shieldHp = self:shieldHp()
	local specialShieldHp = self:specialShieldHp()
	local delayHp = self:delayDamage()

	battleEasy.deferNotify(self.view, "updateLifebar", {
		needCalc = true,
		hp = hp,
		hpMax = hpMax,
		shieldHp = shieldHp,
		specialShieldHp = specialShieldHp,
		delayHp = delayHp,
	})

	self.scene.play:refreshUIHp(self)
end

function ObjectModel:delayDamage()
	local totalDamage = 0
	for k,data in self:ipairsOverlaySpecBuff(battle.OverlaySpecBuff.delayDamage) do
		for _,v in ipairs(data.damageTb) do
			for _,val in ipairs(v) do
				totalDamage = totalDamage + val
			end
		end
	end
	return totalDamage
end

local function iterWithOrder(vals, order, skillsMap)
	local i, k, v = 0, nil, nil
	local n = table.length(order)
	return function ()
		while i < n do
			i = i + 1
			k = (skillsMap and skillsMap[order[i]]) or order[i]
			v = vals[k]
			-- may be v is nil, it be deleted
			if v then
				return k, v
			end
		end
	end, order, 0
end

function ObjectModel:iterSkills()
	return iterWithOrder(self.skills, self.skillsOrder, self.skillsMap)
end

local function filterBuffNotOver(id, buff)
	return not buff.isOver
end

-- 遍历中新增是安全的，order是独立的
-- 遍历中删除是安全的，会跳过被删的
function ObjectModel:iterBuffs()
	-- use buff index by default
	return self.buffs:order_pairs()
end

function ObjectModel:iterBuffsWithEasyEffectFunc(key)
	return self.buffs:getQuery()
		:group("easyEffectFunc", key)
		:order_pairs()
end

function ObjectModel:queryBuffsWithGroup(buffGroupID)
	local query = self.buffs:getQuery()

	local cache = self.scene:getConvertGroupCache()
	if cache and cache.convertGroup == buffGroupID then
		-- order with buffs.defaultindex
		for group, _ in pairs(cache.assignGroup) do
			query:groups("+", "groupID", group)
		end
	end

	query:groups("+", "groupID", buffGroupID)
	return query
end

-- from-触发被动技能的来源, 后续可用来避免由被动技能再次触发被动
function ObjectModel:onPassive(typ, target, args, from)
	-- 被动技能类型默认是 3 光环2算作被动技能类型
	if table.length(self.passiveSkillsOrder) == 0 then
		return
	end

	self.triggerEnv[battle.TriggerEnvType.PassiveSkill]:push_back(typ)

	--print('!!! onPassive', self.id, typ, target and target.id, orders and #orders)

	for skillID, skill in iterWithOrder(self.passiveSkills, self.passiveSkillsOrder) do
		self:onOnePassiveTrigger(skill, typ, target, args, from)
	end

	self.triggerEnv[battle.TriggerEnvType.PassiveSkill]:pop_back()
end

-- 触发一个被动技能
function ObjectModel:onOnePassiveTrigger(skill, typ, target, args, from)
	local roundId = self.scene.play.battleRoundTriggerId
	if roundId and gExtraRoundTrigger[roundId] and gExtraRoundTrigger[roundId].forbiddenPassiveSkill[typ] then
		return
	end
	if skill.onTrigger then
		--print(skillID, skill, skill.type, skill.skillType)
		if typ == skill.type or (typ == "Aura" and skill.skillType == battle.SkillType.PassiveAura)
		or ((typ == PassiveSkillTypes.roundStartAttack or (typ == PassiveSkillTypes.roundEnd and args.roundFlag == battle.PassiveRoundEndFlag.SelfBattleTurn) or typ == PassiveSkillTypes.roundStart ) and skill.skillType == battle.SkillType.PassiveCombine) then
			-- 简单修改下,这里会有点问题,如果目标又选敌方 又选己方时, 会有问题
			-- 真正是对应触发类型再算目标，避免开场没选择ID的问题
			if not target then
				for i, processCfg in ipairs(skill.processes) do
					if processCfg.targetType == 0 then
						target = self
						break
					else
						--print('!!! self.scene.play.nowChooseID', self.scene.play.nowChooseID)
						local tar = self.scene.play:autoChoose(nil,3-self.force)
						local defaultChooseID = self.scene.play.nowChooseID or tar.seat
						target = self.scene:getObjectBySeatExcludeDead(defaultChooseID)
						break
					end
				end
			end
			log.battle.object.onPassive("角色seat=", self.seat, "触发了被动: 类型=", typ, "passiveSkill.id=", skill.id)
			skill:onTrigger(typ, target or self, args)
		end
	end
end

-- 一个小的战斗轮次开始了, 可能这时候不是自己的行动轮次，
-- 只是进行部分逻辑同步, 如果是自己的轮次时, 需要处理下部分buff的触发(onHolderBattleTurnStart onHolderBattleTurnEnd)
function ObjectModel:onNewBattleTurn()
	-- 在自己的攻击回合 小回合数增加
	local roundId = self.scene.play.battleRoundTriggerId
	local disableNewTurn = false
	if roundId and gExtraRoundTrigger[roundId] then
		disableNewTurn = gExtraRoundTrigger[roundId].disableBattleState == 1
	end
	local isSelfTurn = (self.scene.play.curHero.id == self.id)
	if isSelfTurn then
		if self:nextExtraAttack() then
			self:onNewExtraBattleTurn()
		else
			if not disableNewTurn then
				self.battleRound[2] = self.battleRound[2] + 1
				self.battleRoundAllWave[2] = self.battleRoundAllWave[2] + 1
				if self.scene:getExtraBattleRoundMode() ~= battle.ExtraBattleRoundMode.normal then
					self:addExRecord(battle.ExRecordEvent.extraBattleRound, 1)
				end
			end
		end
		if not disableNewTurn then
			self:addExRecord(battle.ExRecordEvent.roundAttackTime, 1)
		end
	end

	-- 在涉及到scene:beInExtraAttack()的所有triggerPoint之前更新
	-- 注意gate中onNewBattleTurn的遍历顺序，或新增的triggerPoint早于onNewBattleTurn的情况
	if isSelfTurn then
		self.scene.extraRoundMode = self:beInExtraAttack()
	end

	if self:onNewBattleTurnInDead() then
		return
	end
	self.flashBack = false 				-- 闪回

	-- 保持逻辑和显示血量一致
	self:setHP(self:hp(), self:hp())
	self:setMP1(self:mp1(), self:mp1())
	--新一轮开始护盾的刷新
	self:refreshShield()
	self:cleanEventByKey(battle.ExRecordEvent.protectTarget) -- 清理下保护标记
	-- 在自己的攻击回合内触发
	-- 被动技能触发
	if isSelfTurn then
		self:onPassive(PassiveSkillTypes.roundStartAttack)
		self:onPassive(PassiveSkillTypes.cycleRound)
		-- 判断回合开始前的buff (buff的状态同步, 当前是行动turn时才可触发buff)
		self:triggerBuffOnPoint(battle.BuffTriggerPoint.onHolderBattleTurnStart,self)
	end

	self:updateSkillState(isSelfTurn)

	battleEasy.queueNotifyFor(self.view, 'newBattleTurn')
end

function ObjectModel:onBattleTurnEnd()
	local roundId = self.scene.play.battleRoundTriggerId
	local disableEndTurn = false
	if roundId and gExtraRoundTrigger[roundId] then
		disableEndTurn = gExtraRoundTrigger[roundId].disableBattleState == 2
	end
	-- 加血扣血，血量均可能低于配置
	self:onPassive(PassiveSkillTypes.hpLess)
	-- 加血扣血，血量均可能低于配置(实时监测)
	self:onPassive(PassiveSkillTypes.dynamicHpLess, self)

	-- 友方存在血量低于xxx的时候触发
	local teamArgs = {objs = self.scene:getHerosMap(self.force)}
	self:onPassive(PassiveSkillTypes.teamHpLess, self, teamArgs)
	-- 友方存在血量低于xxx的时候触发(实时监测)
	self:onPassive(PassiveSkillTypes.dynamicTeamHpLess, self, teamArgs)

	self.once = false
	-- 被动技能触发
	local isSelfTurn = (self.scene.play.curHero.id == self.id)
	if self:beInExtraAttack() then --curHero未必是self
		self:onExtraAttackEnd()
	else
		if isSelfTurn then
			if not disableEndTurn then
				self.battleRound[1] = self.battleRound[1] + 1
				self.battleRoundAllWave[1] = self.battleRoundAllWave[1] + 1
			end
			-- 自己的战斗回合结束
			-- print(string.format("-------新战斗回合结束，波次%s，大回合%s，战斗回合1 %s，战斗回合2 %s，角色ID %s",self.scene.play.curWave,
			-- 	self.scene.play.curRound,self.battleRound[1],self.battleRound[2],self.id))
			--这类型配表中加了个参数,区分攻击回合结束和大回合结束
			self:onPassive(PassiveSkillTypes.roundEnd, self, {roundFlag = battle.PassiveRoundEndFlag.SelfBattleTurn})
		end
		-- 判断回合结束的buff是否需要移除 (buff的状态同步, 当前是行动turn时才可触发buff)
	end
	if isSelfTurn then
		self:triggerBuffOnPoint(battle.BuffTriggerPoint.onHolderBattleTurnEnd,self)
		-- 策划要求技能开始释放到6节点之间的伤害都计入统计
		battleEasy.deferNotify(nil, 'showNumber', {close = true})
	end
	-- 抵挡战斗回合伤害
	if not disableEndTurn then
		self.ignoreDamageInBattleRound = false
	end

	-- 复活默认触发节点
	-- self:processReborn()
	self.scene:addObjViewToBattleTurn(self,"playBuffHolderAction")
end

function ObjectModel:onNewBattleTurnInDead()
	if not self:isFakeDeath() then return end
	local isSelfTurn = (self.scene.play.curHero.id == self.id)

	if isSelfTurn then
		if not self.scene:beInExtraAttack() then
			self:addExRecord(battle.ExRecordEvent.rebornRound, 1)
		end
		self:triggerBuffOnPoint(battle.BuffTriggerPoint.onHolderBattleTurnStart,self)
		self:triggerBuffOnPoint(battle.BuffTriggerPoint.onHolderBattleTurnEnd,self)
	end
	-- print("onNewBattleTurnInDead",self.id,self.isDead)
	-- 可能在触发节点后复活
	return self:isDeath()
end

-- 额外的战斗回合
function ObjectModel:onNewExtraBattleTurn()
	local curExtraData = self.extraRoundData:pop_back()
	if curExtraData then
		self.exAttackTargetID = curExtraData.exAttackTargetID
		self.exAttackSkillID = curExtraData.exAttackSkillID
		self.exAttackArgs = curExtraData.extraArgs
		self:setExtraAttackMode(curExtraData.mode)
		self.exAttackBattleTriggerRound = curExtraData.exAttackBattleTriggerRound
	end

end

function ObjectModel:addExtraBattleData(extraTargetId,extraSkillId,mode,extraArgs)
	self.extraRoundData:push_back({
		exAttackTargetID = extraTargetId,
		exAttackSkillID = extraSkillId,
		mode = mode,
		extraArgs = extraArgs,
		exAttackBattleTriggerRound = self.scene.play.curBattleRound,
	})
end

-- 额外回合结束
function ObjectModel:onExtraAttackEnd()
	if self.exAttackBattleTriggerRound == self.scene.play.curBattleRound then
		return
	end
	self:clearExtraBattleDataByMode(self.exAttackMode)

	self.exAttackTargetID = nil
	self.exAttackSkillID = nil
	self.exAttackMode = nil
	self.exAttackArgs = nil
end

-- 按mode清理额外回合数据
function ObjectModel:clearExtraBattleDataByMode(mode)
	if mode == battle.ExtraAttackMode.counter then
		self:removeSkillType2Data('counterAttack')
		if self.curSkill and self.curSkill.skillType2 ~= battle.MainSkillType.SmallSkill then
			self.curSkill.spellRound = self.curSkill.spellRound - 1
		end
		-- self:onBuffEffectedLogicState("counterAttack",{
		-- 	isOver = true
		-- })
	-- elseif self.exAttackMode == battle.ExtraAttackMode.combo then
	-- elseif self.exAttackMode == battle.ExtraAttackMode.syncAttack
	-- 	or  self.exAttackMode == battle.ExtraAttackMode.inviteAttack then

	end
end

function ObjectModel:recordInfoBeforeWave()
	local state = self.curSkill and self.curSkill.chargeRound
	self:addExRecord(battle.ExRecordEvent.chargeStateBeforeWave, state and true or false)
end

function ObjectModel:onNewWave()
	self:recordInfoBeforeWave()
	self.battleRound[1] = 0
	self.battleRound[2] = 0
	for skillID, skill in self:iterSkills() do
		skill:resetOnNewWave()
	end
	-- 此处不填写参数 point 为了在新回合的时候 及时触发buff们的update
	self:triggerBuffOnPoint()
	-- 清空额外技能数据
	self.curSkill = nil
	for _,data in self.extraRoundData:pairs() do
		self:clearExtraBattleDataByMode(data.mode)
	end
	if self.multiShapeTb then
		-- 重置双形态的cd数据
		self.multiShapeTb[2] = {}
	end
	self.extraRoundData:clear()
	self.exAttackTargetID = nil
	self.exAttackArgs = nil
	self.exAttackSkillID = nil
	self.exAttackMode = nil
	self.exAttackBattleTriggerRound = nil
	self.totalTakeDamage[self.scene.play.curWave] = battleEasy.valueTypeTable()
	self:refreshShield()
	if self.type == battle.ObjectType.Normal then
		local exObj = self.scene:getObjectBySeatExcludeDead(self.seat, battle.ObjectType.SummonFollow)
		if exObj then exObj:onNewWave() end
	end
end

function ObjectModel:onNewRound()
	--复活流程
	if self:isFakeDeath() and not self:canReborn() then
		-- 当没有复活时， -- todo
		self.state = battle.ObjectState.realDead
		return
	end

	-- 记录回合开始时,角色的mp值
	-- 混乱在每大回合也会清理一次,这样每回合重新放技能前,技能目标的提示选择仍然是正常的敌方,
	-- 但实际攻击目标就是己方的,如果策划要让技能提示目标也是己方的, 则混乱的判断需要提前到产生技能目标之前
	-- 也就是每次技能前判断技能的施法者的状态
	-- 大回合触发
	self:onPassive(PassiveSkillTypes.round)
	self:onPassive(PassiveSkillTypes.roundStart)

	for skillID, skill in self:iterSkills() do
		skill:resetOnNewRound()
	end
	-- 大回合清理
	self:cleanEventByKey(battle.ExRecordEvent.roundSyncAttackTime)
end

function ObjectModel:onEndRound()
	gRootViewProxy:proxy():pushDeferList('onEndRound')

	-- 大回合结束触发,和回合触发有点早晚的差别,但第1回合不触发
	self:onPassive(PassiveSkillTypes.roundEnd, self, {roundFlag = battle.PassiveRoundEndFlag.Round})
	-- 技能相关播放序列晚于onPassive内的播放序列 所以需要两次queueEffect嵌套
	local playInEndRound = gRootViewProxy:proxy():popDeferList("onEndRound")
	battleEasy.queueEffect(function()
		battleEasy.queueEffect(function()
			gRootViewProxy:proxy():runDefer(playInEndRound)
		end)
	end)
end

--是否已经死了，只是单纯从血量判断上，从敌人开始放技能，血量减到0就代表死了，只是还没setDead
--还能继续站着受攻击而已，choose状态等逻辑可以提早无视自己的存在
--choose的标准
function ObjectModel:isAlreadyDead()
	if self:isDeath() then
		return true
	end
	return self:hp() <= 0
end

-- 真正意义上的死 需要有个标记
function ObjectModel:isDeath()
	return self:isRealDeath() or self:isFakeDeath()
end

function ObjectModel:isFakeDeath()
	return self.state == battle.ObjectState.dead or self:isRebornState()
end

function ObjectModel:isRebornState()
	return self.state == battle.ObjectState.reborn
end

function ObjectModel:isRealDeath()
	return self.state == battle.ObjectState.realDead
end

-- 真正释放技能攻击
function ObjectModel:spellAttack()
	local skill = self.curSkill
	if skill then
		-- 真正释放技能的时候隐藏掉相关提示信息：克制箭头提示 脚下光圈 克制光圈提示
		battleEasy.deferNotify(nil, 'hideAllObjsSkillTips')
		battleEasy.deferNotify(nil, 'showHero', {typ = "showAll", hideLife=true})
		gRootViewProxy:proxy():flushCurDeferList()

		self:onPassive(PassiveSkillTypes.attack, nil, nil, (skill.skillType == battle.SkillType.NormalSkill) and -100)
		self:triggerBuffOnPoint(battle.BuffTriggerPoint.onHolderToAttack,self)

		if self.ignoreToAttack then
			self.curSkill = nil
			return false
		end


		self:triggerBuffOnPoint(battle.BuffTriggerPoint.onHolderBeForeSkillSpellTo,self)
		gRootViewProxy:proxy():flushCurDeferList()
		if self:isDeath() or not self:canAttack() then return false end
		local target = self:getCurTarget()

		-- 先知效果
		if self:onProphet(skill, target) then
			return false
		end

		skill:spellTo(target)
		return true
	end
	return false
end

-- 先知反击效果流程
function ObjectModel:onProphet(skill, target)
	-- 额外回合 已经是补偿回合 没有先知buff直接return
	if self:beInExtraAttack() or self.scene.play.battleRoundTriggerId or not self.scene:hasTypeBuff("prophet") then
		return
	end

	local buff
	local mustHitObjs, cantHitObjs = {}, {}
	local targets, processCfgId = self:getProphetTargets(skill, target)
	local hashTargets = {}
	for _, v in ipairs(targets) do
		hashTargets[v.id] = true
	end

	local enemyForce = self.force == 1 and 2 or 1
	for _, obj in self.scene:getHerosMap(enemyForce):order_pairs() do
		if obj:checkOverlaySpecBuffExit(battle.OverlaySpecBuff.prophet) then
			local randret = randret or ymrand.random()
			local isEffect = false
			for _, data in obj:ipairsOverlaySpecBuff(battle.OverlaySpecBuff.prophet) do
				if data:getProb(self) > randret then
					isEffect = true
					if hashTargets[obj.id] then
						self.scene.play.battleRoundTriggerId = self.scene.play.battleRoundTriggerId or data.triggerId
						buff = buff or obj.buffs:find(data.id)
						obj:onProphetAttack(skill, self, data)
						obj:triggerBuffOnPoint(battle.BuffTriggerPoint.onBuffTrigger, {
							buffId = buff.id,
							attacker = self,
						})
					end
					break
				end
			end
			if isEffect then
				if hashTargets[obj.id] then
					table.insert(mustHitObjs, obj.id)
				else
					table.insert(cantHitObjs, obj.id)
				end
			end
		end
	end

	if buff then
		local data = {
			obj = self,
			reset = buff.id,
			buffCfgId = buff.cfgId,
			targetId = target.id,
			newSkillId = skill.id,
			mustHit = mustHitObjs,
			cantHit = arraytools.hash(cantHitObjs),
			processCfgId = processCfgId,
		}
		data.mode = battle.ExtraBattleRoundMode.reset
		battleEasy.resetGateAttackRecord(self, data)
	end

	return buff ~= nil
end
-- 预计算技能攻击单位
function ObjectModel:getProphetTargets(skill, target)
	local targets, processCfgId = {}
	for i, processCfg in ipairs(skill.processes) do
		if processCfg.segType == battle.SkillSegType.damage then
			targets = skill:onProcessGetTargets(processCfg, target)
			processCfgId = processCfg.id
			break
		end
	end
	return targets, processCfgId
end

-- 获取当前目标
function ObjectModel:getCurTarget()
	return self.curTargetId and self.scene:getObject(self.curTargetId) or nil
end

-- 是否为相同阵营
function ObjectModel:isSameForce(obj)
	return (obj and obj.force) == self.force
end

-- 当前是否在蓄力充能中
function ObjectModel:isSelfInCharging()
	return self.curSkill and self.curSkill:isChargeSkill() and self.curSkill:isCharging()
end

-- 是不是已经蓄力好了
function ObjectModel:isSelfChargeOK()
	return self.curSkill and self.curSkill:isChargeSkill() and self.curSkill:isChargeOK()
end

-- 被控制
function ObjectModel:isSelfControled()
	-- for _, typ in ipairs(battle.BeControlled) do
	-- 	if self[typ] and self[typ] > 0 then
	-- 		return true
	-- 	end
	-- end
	return self:isLogicStateExit(battle.ObjectLogicState.cantAttack)
end
-- 检测自身的状态能不能攻击 和 有没有技能可用的
function ObjectModel:canAttack()
	-- 是否是没技能的木桩
	if not next(self.skills) then
		return false
	end

	-- 是否在技能蓄力中
	if self:isSelfInCharging() then
		return false
	end

	-- 是否有被控制
	-- 目前可能拥有的被控制状态有: stun sleeping  silence(半个)
	if self:isSelfControled() then
		return false
	end

	-- 如果存在指定攻击对象ID
	if self.exAttackTargetID then
		local tar = self.scene:getFilterObject(self.exAttackTargetID, {fromObj = self},
			battle.FilterObjectType.noAlreadyDead,
			battle.FilterObjectType.excludeObjLevel1
		)

		-- 指定攻击对象不存在 & (要攻击的阵营 == 自身阵营 & 自身阵营没有可被攻击单位)
		if not tar and (self.exAttackArgs and self.exAttackArgs.isFixedForce
			and self.exAttackArgs.targetForce == self.force and table.length(self:getCanAttackObjs(self.force)) == 0) then
			return false
		end
	end

	-- 强制进行skill释放可释放判定
	local canUse
	for skillID, skill in self:iterSkills() do
		canUse = skill:canSpell()
		if canUse then
			-- 额外技能不存在
			-- 额外技能存在且为当前遍历技能
			if not (self.exAttackSkillID and self.exAttackSkillID ~= skillID) then
				return true
			end
		end
	end

	-- 对面存在血量大于0的单位
	-- local ret = self:getCanAttackObjs(3-self.force)
	-- if table.length(ret) == 0 then return false end

	return false
end

function ObjectModel:getCanAttackObjs(force)
	local ret
	if force == self.force then
		ret = self.scene:getFilterObjects(force, {fromObj = self},
			battle.FilterObjectType.excludeEnvObj,
			battle.FilterObjectType.noAlreadyDead,
			battle.FilterObjectType.excludeObjLevel1
		)
	else
		ret = self.scene:getFilterObjects(force, {fromObj = self},
			battle.FilterObjectType.noAlreadyDead,
			battle.FilterObjectType.excludeObjLevel1
		)
	end
	return ret
end

function ObjectModel:toAttack(attack, target)
	local skillID = attack.skill
	local skill = self.skills[skillID]

	if skill == nil then
		errorInWindows("unit:%d skill(%s) is nil",self.unitID,skillID)
		return
	end

	self.curSkill = skill

	-- 蓄力技能,先只记录充能开始的时刻
	if skill:isChargeSkill() and not skill:isChargeOK() then
		if not target then
			return
		end
		skill:startCharge()
		-- obj 改变姿态为充能姿态
		-- todo
		-- obj 记录一个充能中的状态, 在此状态中, 如果受到控制类效果时,充能状态会被打断
		self.chargeSkillTargetId = target.id 		-- 记录当前的目标
		return
	end

	-- 显示技能名字
	battleEasy.deferNotify(nil, 'showSkillName', skillID)

	local tar = target
	-- 检查 obj 的混乱状态, 是攻击技能时, 会攻击己方的目标, 随机选择一个己方目标, 如果只有自己时不触发混乱
	-- 额外邀战参数不触发魅惑
	if skill.cfg.damageFormula and self:isBeInConfusion() and
		not (self.exAttackArgs and self.exAttackArgs.isFixedForce) then
		-- local ignoreStealthId
		-- if self.stealthIgnoreInfo then
		-- 	ignoreStealthId = self.stealthIgnoreInfo.ignoreId
		-- end
		local selfSideObjs, enemySideObjs, needSelfForce, prob = self:getConfusionCheckInfos()
		local enemyForce = self.force == 2 and 1 or 2
		local randret = ymrand.random()
		local force = self.force
		local ret

		if table.length(selfSideObjs) == 0 and (table.length(enemySideObjs) == 0 or needSelfForce) then -- 目标为空
			return
		elseif table.length(selfSideObjs) == 0 or prob > randret then -- 攻击敌方
			ret = enemySideObjs
			force = enemyForce
		else -- 攻击己方
			-- !!! 在混乱状态下要注意技能释放过程中 target2下enemyForce变更的情况
			ret = selfSideObjs
		end
		-- TODO: table.length(ret) = 0崩溃临时修正
		if table.length(ret) > 0 then
			local confusionObjId = ret[ymrand.random(1, table.length(ret))].id
			tar = self.scene:getObject(confusionObjId)
		end
	end

	-- crash web 3245
	if not tar then
		-- errorInWindows("unit:%d skill(%s) target is nil",self.unitID,skillID)
		return
	end

	self.curTargetId = tar.id
	log.battle.object.toAttack(' 当前被攻击的目标 target.id =', self.curTargetId or ' no target ?')
	gRootViewProxy:proxy():flushCurDeferList()
	if skill:canSpell() then
		self:spellAttack()
	end
end

function ObjectModel:getConfusionCheckInfos()
	local selfSideObjs = self:getCanAttackObjs(self.force)
	local enemyForce = self.force == 2 and 1 or 2
	local enemySideObjs = self:getCanAttackObjs(enemyForce)
	local prob = math.huge
	local needSelfForce
	for _, data in self:ipairsOverlaySpecBuff("confusion") do
		if data.prob < prob then
			prob = data.prob
			needSelfForce = data.needSelfForce
		elseif data.prob == prob then
			needSelfForce = data.needSelfForce or needSelfForce
		end
	end
	return selfSideObjs, enemySideObjs, needSelfForce, prob
end

--加血
function ObjectModel:resumeHp(caster,val, args)
	local valueTab = battleEasy.valueTypeTable() --1:治疗量 2:溢出治疗量 3:有效治疗量
	if val < 0 then
		errorInWindows("回血类效果需配置正值 hp:%s, val:%s",self:hp(),val)
		return valueTab
	end
	if self:checkOverlaySpecBuffExit("lockResumeHp") and not args.ignoreLockResume then return valueTab end

	local value = val
	-- 自身被治疗效果加成
	if not args.ignoreBeHealAddRate then
		value = _floor(value * (1 + self:beHealAdd()))
		log.battle.object.resumeHp(" 治疗加成 healAdd=", value - val, self:beHealAdd())
	end
	local hp = self:hp() + value
	valueTab:add(value)
	if hp > self:hpMax() then
		-- 从治疗数字中减去溢出的部分
		valueTab:add(hp - self:hpMax(),battle.ValueType.overFlow)
		hp = self:hpMax()
	end
	valueTab:add(value - valueTab:get(battle.ValueType.overFlow),battle.ValueType.valid)
	logf.battle.object.resumeHp(" id=%s, 当前hp:%f + 改变值:%f -> 最终hp:%f", self.id, self:hp(), value, hp)

	if caster then
		-- 统计治疗部分的数据
		caster.totalResumeHp[args.from]:addTable(valueTab)
	end

	battleEasy.deferNotify(self.view, "showHeadNumber", {typ=1, num=value, args = args or {}})
	self:addHp(value)
	-- 加血触发buff节点
	self:triggerBuffOnPoint(battle.BuffTriggerPoint.onHolderHpAdd, {
		resumeHp = valueTab,
		resumeHpFrom = args.from,
		resumeHpFromKey = args.fromKey,
		obj = caster,
	})
	return valueTab
end

--复活之类的特殊用处重置HP，不吃BUFF
function ObjectModel:resetHp(val, args)
	local hp = val
	if hp - self:hpMax() > -1e-5 then
		-- value = value - (hp - self:hpMax()) -- 从治疗数字中减去溢出的部分
		hp = self:hpMax()
	end
	logf.battle.object.resetHp(" id=%s, 改变值:%f -> 最终hp:%f", self.id, val, hp)
	battleEasy.deferNotify(self.view, "showHeadNumber", {typ=1, num=hp, args=args or {}})
	self:setHP(hp,hp)
end

-- 死亡逻辑 attacker:死亡时杀死自己的目标,有可能是自身 force:强行真死，不判复活
-- 部分被动技能的触发,需要放到对应的动画表现时刻
-- 被动技能的触发点,后面处理,暂时先保持这样,这可能会成为后期实际数据和表现不一致的主要来源,因为纯战斗逻辑中没有时间区分
-- 实际战斗暂时还无法知道动画进行到了什么程度
function ObjectModel:setDead(attacker,killDamage,deadArgs)
	if self:isDeath() then return end

	-- cow预计算
	self:cowPreCalcRecord()

	deadArgs = deadArgs or {force = false}
	if not deadArgs.beAttackZOrder then
		self.scene:updateBeAttackZOrder()
		deadArgs.beAttackZOrder = self.scene.beAttackZOrder
	end

	self.state = battle.ObjectState.dead
	self.attackMeDeadObj = attacker
	self.killMeDamageValues = killDamage and killDamage or battleEasy.valueTypeTable()
	logf.battle.object.dead('setDead self.seat=%s attacker.id=%s', self.seat, attacker and attacker.id)

	if self.scene.play.gateDoOnObjectDead then
		self.scene.play:gateDoOnObjectDead(self.seat)
	end

	-- 自己死亡时,对方的击杀增加 mp: 从常量表获取
	self:addAttackerMpOnSelfDead(attacker)

	if not (deadArgs.noTrigger and deadArgs.noTrigger == true) then
		local deathBuff = gRootViewProxy:proxy():pushDeferList(self.id, 'deathBuff')
		-- 相关被动技能的触发
		self:onPassive(PassiveSkillTypes.beDeathAttack) -- 各种死都触发时用的效果
		if attacker then
			attacker:onPassive(PassiveSkillTypes.kill, attacker)
		end
		-- 死亡时触发的buff
		self:triggerBuffOnPoint(battle.BuffTriggerPoint.onHolderDeath, {
			killerID = self.attackMeDeadObj.seat
		})
		self.scene:addListViewToBattleTurn(self, gRootViewProxy:proxy():popDeferList(deathBuff))
	end

	self:delBuffsWithSelf()
	-- 真死 假死
	-- 这里要移动到 技能结束后去做,技能结束时去判断是否能复活, 战斗回合结束时去做是否删除的操作
	if deadArgs.force then
		self:processRealDeath(deadArgs.beAttackZOrder, deadArgs.noTrigger)
	else
		if self:canReborn() then -- 复活判断
			-- 假死处理
			self:processFakeDeath()
		else
			-- 真死处理
			self:processRealDeath(deadArgs.beAttackZOrder, deadArgs.noTrigger)
		end
	end
	-- 正常单位死亡 同位置的召唤跟随单位也设置死亡
	if self.type == battle.ObjectType.Normal then
		local extraObj = self.scene:getObjectBySeatExcludeDead(self.seat, battle.ObjectType.SummonFollow)
		if extraObj then extraObj:setDead(attacker,killDamage,deadArgs) end
	end
end

function ObjectModel:delBuffsWithSelf()
	-- 删除目标为该单位的buff
	local enemyForce = self.force == 1 and 2 or 1
	for _, obj in self.scene:getHerosMap(enemyForce):order_pairs() do
		if not obj:isAlreadyDead()
			and (obj:isBeInSneer() and obj:getSneerObj() and obj:getSneerObj().id == self.id) then
			for _, buff in obj:iterBuffsWithEasyEffectFunc("sneer") do
				if buff.csvCfg.easyEffectFunc == 'sneer' then
					buff:overClean()
				end
			end
		end
	end
end

-- 假死状态处理
function ObjectModel:processFakeDeath()
	logf.battle.object.fakeDead(" seat:%d 假死",self.seat)
	-- 先触发被动
	self:onPassive(PassiveSkillTypes.fakeDead)	-- 触发假死
	-- 再假死时触发的buff -- todo

	-- 移除buff 除复活BUFF之外
	-- 清除除了某种类型以外的所有BUFF,同样要考虑到castBuff的影响
	-- 假死不删除标记，表里noDelWhenFakeDeath不填 直接删除 填了 1 就不删除
	self:clearBuff(function(buff)
		local noDelBuff = (buff.csvCfg.noDelWhenFakeDeath == 1)
		return buff.csvCfg.easyEffectFunc ~= "reborn" and not noDelBuff
	end)


	self:fakeDeathCleanData()

	-- 显示在别处处理，这里不用加
	self:processReborn()
end

-- 真死状态处理
local DeleteWithModelMap = {
	"changeUnit",
	"changeToRandEnemyObj",
	"changeImage",
}

function ObjectModel:processRealDeath(realDeadOrder, noTrigger)
	logf.battle.object.realDead(" seat:%d 真死",self.seat)
	if self:isRealDeath() then return end
	-- 记录真死状态,区别于假死
	self.state = battle.ObjectState.realDead
	if not (noTrigger and noTrigger == true) then
		-- 触发被动技能
		self:onPassive(PassiveSkillTypes.realDead)	-- 触发真死
		-- 触发buff
		local realDeathBuff = gRootViewProxy:proxy():pushDeferList(self.id, 'realDeathBuff')
		self:triggerBuffOnPoint(battle.BuffTriggerPoint.onHolderRealDeath, {
			killerID = self.attackMeDeadObj.seat
		})
		self.attackMeDeadObj:triggerBuffOnPoint(battle.BuffTriggerPoint.onHolderMakeTargetRealDeath,self)
		self.scene:addListViewToBattleTurn(self, gRootViewProxy:proxy():popDeferList(realDeathBuff))
	end

	-- 加入移除记录中
	self.scene.play:recordDamageStats()
	self.scene:addObjToBeDeleted(self)

	self.scene:setDeathRecord(self,realDeadOrder)

	self:realDeathCleanData()
	self:recordRealDeadHpMaxSum()
end
-- 换波时清理
function ObjectModel:processRealDeathClean()
	logf.battle.object.realDead(" seat:%d 真死",self.seat)
	if self:isRealDeath() then return end
	self.state = battle.ObjectState.realDead

	self:realDeathCleanData()
end

function ObjectModel:recordRealDeadHpMaxSum()
	-- 记录敌我双方真死精灵的hpMax总和
	if self.scene.play.myDeadHpMaxSum and self.seat <= 6 then
		self.scene.play.myDeadHpMaxSum = self.scene.play.myDeadHpMaxSum + self:hpMax()
	elseif self.scene.play.enemyDeadHpMaxSum and self.seat > 6 then
		self.scene.play.enemyDeadHpMaxSum = self.scene.play.enemyDeadHpMaxSum + self:hpMax()
	end
end

function ObjectModel:fakeDeathCleanData()
	self.killMeDamageValues = nil
	self.scene:cleanObjInExtraRound(self)

	self:deleteAuraBuffs()
end

function ObjectModel:realDeathCleanData()
	-- 死亡后删除所有buff
	-- DeleteWithModelMap: 在单位被移除时一起清除
	local query = self:getBuffQuery()
		:groups_init_with_all()
		:groups_sub_array("-", "easyEffectFunc", "+", DeleteWithModelMap)
	self:clearBuff(nil, query)

	self:fakeDeathCleanData()
end

function ObjectModel:hasExtraBattleRound()
	return false
end

-- buff新机制的触发时机 (像是无敌这类比较特殊的buff，buff只管理状态，具体逻辑交给角色obj自身处理)
-- trigger:表示触发buff当前的触发者或者叫驱动者
-- curTimeInfoTb:记录buff被触发时的具体时间数据{回合时间, 触发者, 技能id, 过程段id, 具体第几个过程分段, 自己的触发节点, 自身相关的主buff, 主buff触发节点}
function ObjectModel:triggerBuffOnPoint(triggerPoint, trigger)
	-- release_print(' ----- triggerBuffOnPoint =', self.id, triggerPoint, trigger, self.buffs:size())

	if not self:effectPowerControl(battle.EffectPowerType.triggerPoint, triggerPoint) then
		return
	end

	if BuffModel.IterAllPointsMap[triggerPoint] then
	for _, buff in self:iterBuffs() do
		if buff:isTrigger(triggerPoint, trigger) then
			-- 记录触发者,防止castBuff时出现自身调用的死循环(主要针对创建时就触发的node类型)
			buff:updateWithTrigger(triggerPoint, trigger)
		end
	end
		return
end

	self:dispatchEvent(triggerPoint, trigger)
end

-- 伤害计算的部分, 挪到了object下面, 这样能方便其它地方调用
-- 计算自身对目标造成的伤害 target:目标 , damage:公式伤害值
function ObjectModel:calcInternalDamage(attacker,damage,damageProcessId,damageArgs)
	local damage, damageArgs = battleEasy.runDamageProcess(damage,attacker,self,damageProcessId,damageArgs)
	return _floor(damage), damageArgs
end

function ObjectModel:beAttack(attacker,damage,damageProcessId,damageArgs)
	self.curAttackMeObj = attacker
	-- 代表不是同时的伤害,并且不是延迟伤害
	if not damageArgs.processId and not damageArgs.isDefer then
		self.scene:updateBeAttackZOrder()
	end
	damageArgs.beAttackZOrder = damageArgs.beAttackZOrder or self.scene.beAttackZOrder

	if attacker then
		for _,buff in self:iterBuffs() do
			buff:refreshExtraTargets(battle.BuffExtraTargetType.holderBeAttackFrom,{attacker})
		end
	end

	local needAttackerRecord = (attacker and not damageArgs.noDamageRecord)
	local curWave = self.scene.play.curWave
	local damageValueTab = battleEasy.valueTypeTable() --1:伤害量 2:溢出伤害量 3:有效伤害量
	-- 单位已经死亡
	if self:isDeath() then
		if needAttackerRecord then
			attacker.totalDamage[damageArgs.from]:add(damage,battle.ValueType.overFlow)
			attacker.totalDamage[damageArgs.from]:add(damage)
		end
		-- battleEasy.deferNotify(self.view, "showHeadNumber", {typ=0, num=damage, args={}})
		self.totalTakeDamage[curWave]:add(damage,battle.ValueType.overFlow)
		self.scene:setDeathRecord(self,damageArgs.beAttackZOrder)
		self.scene:runBeAttackDefer(self.id)
		return damageValueTab,damageArgs
	end

	local damage,damageArgs = self:calcInternalDamage(attacker,damage,damageProcessId,damageArgs)
	local isFullHp = abs(self:hp() - self:hpMax()) < 1e-5

	damageValueTab:add(damage)
	if damageArgs.extraValueF then
		damageValueTab:add(damageArgs.extraValueF)
	end

	local totalDamage = 0
	for _,v in pairs(attacker.totalDamage) do
		totalDamage = totalDamage + v:get(battle.ValueType.normal)
	end
	logf.battle.object.causeDamage(" seat:%d 伤害类型: %d, damage:%f , 总伤害:%f", attacker and attacker.seat or -99, damageArgs.from, damage,totalDamage)

	if needAttackerRecord then
		attacker.totalDamage[damageArgs.from]:add(damageValueTab:get(battle.ValueType.normal))
	end

	--如果有睡眠buff时,把状态清理掉 一个skill只清一次
	if self:checkOverlaySpecBuffExit(battle.OverlaySpecBuff.sleepy) and damageArgs.isLastDamageSeg
		and damageArgs.from == battle.DamageFrom.skill and not self.scene:beInExtraAttack() and not damageArgs.beHitNotWakeUp then
		-- 移除睡眠类型的buff
		self:processBeHitWakeUp(attacker)
	end

	if damage == 0 then
		self.scene:runBeAttackDefer(self.id)
		return damageValueTab,damageArgs
	end

	local hp = self:hp() - damage

	if needAttackerRecord then
		self.scene.play:recordScoreStats(attacker, damage)
	end

	damageValueTab:add(((hp < 0) and abs(hp) or 0),battle.ValueType.overFlow)
	damageValueTab:add(damage - damageValueTab:get(battle.ValueType.overFlow),battle.ValueType.valid)

	logf.battle.object.beAttack(" %d 攻击-> %d, 当前hp:%f - damage:%f -> 最终hp:%f", attacker and attacker.seat or -99, self.seat, self:hp(), damage, hp)
	-- if not (hp > 0) and self.hpTable[3] < 0 then
	-- 	hp = hp + self.hpTable[3]
	-- end  --溢出伤害累加

	self.totalTakeDamage[curWave]:addTable(damageValueTab)
	self:addHp(-damage)

	if damageArgs.isLastDamageSeg then
		self:triggerBuffOnPoint(battle.BuffTriggerPoint.onHolderHpChange, {
			lostHp = damageValueTab, -- beAttack时损失的血量
			damageArgs = damageArgs,
			damageProcessId = damageProcessId,
		})
	end

	self:beAttackRecoverMp(attacker, damage, hp)

	-- 6. buff和被动的一些触发 (可能要根据一些特殊状态改变这些触发的顺序, 可能也要调整上述计算步骤大类的顺序)
	--注意,下面的被动技能,都是在当前瞬间触发的,如果需要做一些延迟处理,可以修改onPassive,加一个参数标记延迟,统一处理
	-- 触动被动技能/buff 暂时先忽略由buff中来的各种伤害
	-- -99 directDamage
	-- -1 反弹伤害
	-- 被攻击触发的被动只触发一次
	self:onBeAttack(attacker, damageArgs, {
		isFullHp = isFullHp,
	})

	if needAttackerRecord then
		attacker.totalDamage[damageArgs.from]:addTable(damageValueTab,battle.ValueType.overFlow,battle.ValueType.valid)
	end

	-- 最后一段结束 清理相关ID延后的伤害
	if damageArgs.isLastDamageSeg then
		self:befoceSetDead(attacker, damage, damageArgs, damageValueTab)
		self.scene:runBeAttackDefer(self.id)
	end
	return damageValueTab,damageArgs
end

function ObjectModel:beAttackRecoverMp(attacker, damage, hp)
	-- 被击触发恢复 mp,需要额外计算伤害溢出时增加的(数码中会有某些技能需要使用死之前的mp值) (表现的mp放到了 segShow 中)
	-- todo 护盾的伤害会触发被击的这些效果吗？？ 应该不算吧
	if not self.cantRecoverMp then --有不回复Mp的buff时不计算
		local correctCfg = self.scene:getSceneAttrCorrect(self:serverForce())
		local commonPreMp = gCommonConfigCsv and gCommonConfigCsv.lostOnePercentHpAddMp or 1
		local perMp = correctCfg.lostBloodMp1 or 1
		local perHpMp = 1 / self:hpMax() * 100 * commonPreMp * perMp	-- 损失每百分之1hp加的mp
		local mp = damage * perHpMp
		if hp < 0 then
			local realDamage = damage + hp
			mp = realDamage * perHpMp
		end
		local mp1Correct = mp * (1.0 + self:mp1Recover() + self:mpBeAttackRecover())
		self:setMP1(self:mp1() + mp1Correct)
	end

	-- 收到伤害时 有的技能配置了 使收到伤害的人固定恢复MP
	if attacker and attacker.curSkill then
		local curSkill = attacker.curSkill
		local skillCfg = curSkill.cfg
		local mp1Correct = skillCfg.hurtMp1 and skillCfg.hurtMp1 * (1.0 + self:mp1Recover()) or 0 --修正值
		self:setMP1(self:mp1() + mp1Correct)
	end
end

-- 被攻击时触发的被动和buff节点
function ObjectModel:onBeAttack(attacker, damageArgs, exArgs)
	if damageArgs.from ~= battle.DamageFrom.skill or self.once then
		return
	end
	self:onPassive(PassiveSkillTypes.beAttack, nil, damageArgs)
	self:onPassive(PassiveSkillTypes.beDamage, attacker, damageArgs)
	self:onPassive(PassiveSkillTypes.beSpecialDamage, attacker, damageArgs)
	self:onPassive(PassiveSkillTypes.beNatureDamage, attacker, damageArgs)
	self:onPassive(PassiveSkillTypes.beNonNatureDamage, attacker, damageArgs)
	self:onPassive(PassiveSkillTypes.beSpecialNatureDamage, attacker, damageArgs)

	-- 满血被攻击时触发被动
	self:onPassive(PassiveSkillTypes.beDamageIfFullHp, attacker, exArgs)
	-- 暴击时触发被动
	self:onPassive(PassiveSkillTypes.beStrike, attacker, damageArgs)

	-- 被击时触发的buff
	self:triggerBuffOnPoint(battle.BuffTriggerPoint.onHolderBeHit, self)
	self.once = true
end

function ObjectModel:befoceSetDead(attacker, damage, damageArgs, damageValueTab)
	if self:hp() > 0 then
		return
	end

	damageArgs.beAttackToDeath = true
	local killMeDamageValues = battleEasy.valueTypeTable()
	killMeDamageValues:add(damageValueTab)
	if damageArgs.from == battle.DamageFrom.skill then
		local curSkill = self:getCurSkill()
		if curSkill then
			local skillRealDamage = curSkill:getTargetDamage(self)
			-- 击杀目标后记录公式傷害
			if skillRealDamage then
				killMeDamageValues:add(-damage + skillRealDamage)
			end
		end
	end
	-- 只在死亡相关节点区间内生效
	self:setDead(attacker,killMeDamageValues,{
		force = damageArgs.ignoreFakeDeath,
		beAttackZOrder = damageArgs.beAttackZOrder
	})
end

-- ①.玩家的基础命中属性和闪躲属性
-- 攻击方命中等级 < 受击方闪避属性时，命中几率为0%
-- 攻击方命中等级>=受击方闪避属性时，命中几率计算公式如下：
-- 命中概率 = （攻击方命中-受击方闪避）/10000
-- ②.技能上自身所携带的命中几率修正
--   每个招式都有命中值设定，命中的取值范围在0～100。
--   通过技能命中值乘以命中修正，产生实际的命中率，并以命中率进行命中判定。
--   （可能会存在特殊必中的技能设定存在）
--   例如：攻击方命中等级为11000，受攻击方闪躲等级为2000
--   技能上配置的命中值为,80，那么最后该次攻击的闪避概率为
--  （11000-2000）/10000*80% = 90% * 80% = 72%
function ObjectModel:isHit(target, skillCfg)
	local delta = self:hit() - target:dodge()
	log.battle.object.isHit(" 加成前目标的闪避率=", target:dodge(), "命中率=", self:hit())
	if delta <= 0 then
		return false
	end
	local prob = delta
	local cfgHit = skillCfg.skillHit
	local rand = 0
	local crand = ymrand.random(1, 5)
	for i=1, crand do
		rand = ymrand.random()
	end

	local isHit = prob > rand
	log.battle.object.isHit(" 最终命中率=", prob, "本次随机值=", rand, "是否命中=", isHit)
	return isHit
end
-- 伤害命中
-- function ObjectModel:isDamageHit(target)
-- 	-- 是否有伤害必中buff
-- 	if self:checkOverlaySpecBuffExit("damgeMustHit") then
-- 		return true
-- 	end
-- 	local delta = (self:damageHit() - target:damageDodge())
-- 	if delta <= 0 then
-- 		return false
-- 	end
-- 	local prob = ymrand.random()
-- 	return delta > prob
-- end

-- 攻击方暴击等级 < 受攻击方暴击抗性等级 时，暴击几率为0%
-- 攻击方暴击等级 > 受攻击方暴击抗性等级 时，暴击几率计算公式如下
-- n = （攻击方对应攻击类型暴击等级 - 受攻击方对应攻击类型暴击抗性等级）
-- 攻击暴击概率 = n /10000
-- 例如：攻击方暴击等级为2000，受攻击方暴击抗性等级为1000，那么最后该次攻击的暴击概率为
-- （200-100）/ 1000 = 100/1000  = 10%
-- 无视抗暴击最多把暴击抗性减到0
-- function ObjectModel:isStrike(target)
-- 	local resist = target:strikeResistance()
-- 	if self.ignoreStrikeResistanceBuff then
-- 		resist = _max((resist - self.ignoreStrikeResistanceBuff.rate/ConstSaltNumbers.wan), 0)
-- 	end
-- 	local delta = self:strike() - resist
-- 	if delta <= 0 then
-- 		return false
-- 	end
-- 	return delta > ymrand.random()
-- end

-- 受攻击方格挡等级 <= 攻击方破格挡等级 时，格挡几率为0%
-- 受攻击方格挡等级 >  攻击方破格挡等级 时，格挡几率计算公式如下
-- 闪避概率 = （受攻击方格挡等级 - 攻击方破格挡等级）/10000
-- 例如：攻击方破格挡等级为1000，受攻击方格挡等级为2000，那么最后该次攻击的闪避概率为
-- （2000-1000）/ 10000 = 10%
-- function ObjectModel:isBeBlock(target)
-- 	local delta = target:block() - self:breakBlock()
-- 	if delta <= 0 then
-- 		return false
-- 	end
-- 	return delta > ymrand.random()
-- end

-- 补充两个计算属性的函数, 一是简化写法, 二是为了方便判断有 自身有特殊buff--能力弱化的buff时 的处理
-- 扣血 扣mp不算能力弱化,而且 hp mp不在下面的属性表中计算
function ObjectModel:objAddBuffAttr(attr, delta)
	if self.beInImmuneAllAttrsDownState and (self.beInImmuneAllAttrsDownState > 0) then
		-- view 被免疫的要显示什么吗??
	end
	if not ObjectAttrs.AttrsTable[attr] then
		return
	end
	self.attrs:addBuffAttr(attr, delta)
end

function ObjectModel:objAddBaseAttr(attr, delta)
	if self.beInImmuneAllAttrsDownState and (self.beInImmuneAllAttrsDownState > 0) then
		-- view 要显示什么吗??
	end
	if not ObjectAttrs.AttrsTable[attr] then
		return
	end
	self.attrs:addBaseAttr(attr, delta)
end

function ObjectModel:objAttrsCorrect(cfg)
	self.attrs:correct(cfg)
	self:setHP(self:hpMax(), self:hpMax())	-- 血量同步下
	for k,v in ipairs(cfg.buffGroup or {}) do
		local args = {
			lifeRound = v.lifeTime,
			prob = v.prob,
			value = v.value,
			buffValue1 = v.value,
			isSceneBuff = true,
		}
		local newBuff = addBuffToHero(v.id, self, nil, args)
		-- 技能成功并且附加了指定buff的时候触发的被动技能
		if newBuff then
			self:onPassive(PassiveSkillTypes.additional, self, {buffCfgId = newBuff.cfgId})
		end
	end
end

function ObjectModel:objAttrsCorrectMonster(cfg)
	if self.doneMonsterCorrect then return end
	self:objAttrsCorrect(cfg)
	self.doneMonsterCorrect = true
end

function ObjectModel:objAttrsCorrectScene(cfg)
	if self.doneSceneCorrect then return end
	self:objAttrsCorrect(cfg)
	local mp1 = self:mp1()
	self:setMP1(cfg.addMp1+mp1, cfg.addMp1+mp1)
	self.doneSceneCorrect = true
end

function ObjectModel:objAttrsCorrectCP(leftTotalCP, rightTotalCP)
	local minTotalCP = math.min(leftTotalCP, rightTotalCP)
	local maxTotalCP = math.max(leftTotalCP, rightTotalCP)

	if maxTotalCP == 0 then return end

	local fightPointRate = minTotalCP / maxTotalCP

	local attrsCorrectCfg = {}
	for _, v in orderCsvPairs(csv.combat_power_correction) do
		local combatPowerLimit = v.combatPowerLimit[self.scene.gateType] or math.huge
		if fightPointRate < v.fightPointRate[1] and fightPointRate >= v.fightPointRate[2]
			and maxTotalCP >= combatPowerLimit then
			attrsCorrectCfg = v.attr
			break
		end
	end
	for attr, delta in pairs(attrsCorrectCfg) do
		self:objAddBaseAttr(attr, delta)
	end
end

function ObjectModel:onBuffEffectedHolder(buff)
	local type = buff.csvCfg.easyEffectFunc
	-- 自身有蓄力回合
	if self.curSkill and self.curSkill.chargeRound then
		local curChargeArgs = self.curSkill.chargeArgs
		local breakChargingData = self:getOverlaySpecBuffByIdx("breakCharging")
		-- 受到控制类型buff(在非延迟的情况下)或受到打断蓄力buff  结束蓄力技能
		if (not curChargeArgs.effectDelay and battle.ControllBuffType[type]) or (breakChargingData and breakChargingData.mode == 1) then
			self.view:proxy():setActionState(battle.SpriteActionTable.standby) 	-- 目标恢复站立姿态
			self.curSkill:interrupt(battle.SkillInterruptType.charge, buff.cfgId) -- 技能被打断了
		end
	end
	-- 触发某些被动技能的效果
end

function ObjectModel:getBuffQuery()
	return self.buffs:getQuery()
end

-- 对添加在object上的buff进行移除， 提供两种移除判定方式
-- @parm buffType:移除的buff类型，为"all"时移除所有buff， buffId为添加buff的Id
-- PS:注意考虑castBuff的影响，实际上是可能有类型之外的被清掉的
function ObjectModel:clearBuff(filter, query)
	filter = filter or function(buff) return true end

	-- iter query buffs
	if query then
		for _, buff in query:order_pairs() do
			if filter(buff) then
				buff:overClean()
			end
		end
		return
	end

	-- iter all buffs
	for _, buff in self:iterBuffs() do
		if filter(buff) then
			buff:overClean()
		end
	end
end

-- 删除自己为他人添加的光环类型的buff
-- TODO: https://git.tianji-game.com/tjgame/pokemon_battle/merge_requests/1118
function ObjectModel:deleteAuraBuffs()
	for _, buff in self.auraBuffs:order_pairs() do
		buff:overClean()
	end
	self.auraBuffs:clear()
end

function ObjectModel:delBuff(buffIds, triggerCtrlEnd)
	-- local delBuffList = type(buffIds) == "number" and {[buffIds] = true} or buffIds
	local overTb
	if triggerCtrlEnd then
		overTb = {triggerCtrlEnd = true}
	end

	-- unpack buffIds to buffId
	local buffId
	if type(buffIds) == "number" then
		buffId = buffIds
	else
		local size = table.nums(buffIds)
		if size == 0 then
			return
		elseif size == 1 then
			buffId = next(buffIds)
		end
	end

	if buffId then
		local buff = self.buffs:find(buffId)
		if buff then
			buff:over(overTb)
		end

	else
		-- len(buffIds) <= 1 in most cases
		for _,buff in self:iterBuffs() do
			if buffIds[buff.id] then
				buff:over(overTb)
			end
		end
	end
end

-- 通过buffID获取相关buff信息
function ObjectModel:getBuff(buffCsvID)
	return self.buffs:getQuery()
		:group("cfgId", buffCsvID)
		:first(filterBuffNotOver)
end

function ObjectModel:hasBuff(buffCsvID)
	return self:getBuff(buffCsvID) ~= nil
end


-- 是否拥有此buff组的buff
function ObjectModel:hasBuffGroup(buffGroupID)
	return not self:queryBuffsWithGroup(buffGroupID)
		:empty(filterBuffNotOver)
end

-- 是否拥有某种类型的buff
function ObjectModel:hasTypeBuff(buffType)
	return not self.buffs:getQuery()
		:group("easyEffectFunc", buffType)
		:empty()
end

function ObjectModel:getBuffOverlayCount(buffCsvID)
	local buff = self:getBuff(buffCsvID)
	if not buff then
		return 0
	end
	return buff:getOverLayCount()
end

-- 获取buff的参数
function ObjectModel:getBuffGroupArgSum(arg, buffGroupID)
	local sum = 0
	-- Coexist和CoexistLifeRound类型的buff会重复计算overlayCount，需要去重
	if arg == "overlayCount" then
		local cfgIds = {}
		for k, buff in self:queryBuffsWithGroup(buffGroupID):order_pairs() do
			if not buff.isOver and not cfgIds[buff.cfgId] then
				sum = sum + buff:getOverLayCount()
				cfgIds[buff.cfgId] = true
			end
		end

	else
		for k, buff in self:queryBuffsWithGroup(buffGroupID):order_pairs() do
			if not buff.isOver then
				sum = sum + buff[arg]
			end
		end
	end
	return sum
end

-- 获取buff的参数
function ObjectModel:getBuffGroupFuncSum(funcName, buffGroupID)
	local sum = 0
	for k, buff in self:queryBuffsWithGroup(buffGroupID):order_pairs() do
		if not buff.isOver then
			sum = sum + buff[funcName](buff)
		end
	end
	return sum
end

--针对叠加类型6 不同目标相同cfgId的buff的叠加计数
function ObjectModel:getSameBuffCount(buffCsvID)
	return self.buffs:getQuery()
		:group("cfgId", buffCsvID)
		:count()
end

function ObjectModel:getNatureType(natureId)
	local type2 = self:getNature(2)
	if not type2 or natureId == 1 then
		return self:getNature(1)
	else
		return type2
	end
end

function ObjectModel:getNature(idx)
	local buffData = self:getOverlaySpecBuffData(battle.OverlaySpecBuff.changeObjNature)
	if buffData.getType then
		local type = buffData:getType(idx)
		if type and type > 0 then
			return type
		end
	end
	if idx == 1 then
		return self.natureType
	else
		return self.natureType2
	end
end

function ObjectModel:getExtraRound(excludeExtraBattleRound)
	local round = 0
	round = round + (self:getEventByKey(battle.ExRecordEvent.rebornRound) or 0)
	-- 排除额外战斗回合
	if excludeExtraBattleRound then
		round = round - (self:getEventByKey(battle.ExRecordEvent.extraBattleRound) or 0)
	end
	return round
end

--获取战斗回合 skillTimePos 1:获取回合后的时间点
function ObjectModel:getBattleRound(skillTimePos, excludeExtraBattleRound)
	local round = (skillTimePos == 1 and self.battleRound[1] or self.battleRound[2])
	return round + self:getExtraRound(excludeExtraBattleRound)
end

--获取不限定波次的战斗回合
function ObjectModel:getBattleRoundAllWave(skillTimePos, excludeExtraBattleRound)
	local round = (skillTimePos == 1 and self.battleRoundAllWave[1] or self.battleRoundAllWave[2])
	return round + self:getExtraRound(excludeExtraBattleRound)
end

--获取当前实际位置
function ObjectModel:getRealPos()
	return self.seat
end

--获取自己是前排还是后排
function ObjectModel:frontOrBack()
	if self.seat <= 3 or (self.seat <= 9 and self.seat >= 7) then
		return 1
	else
		return 2
	end
end

function ObjectModel:updAttackerCurSkillTab(skill,isDelete)
	if not skill:isNormalSkillType() then return end
	local index = table.length(self.attackerCurSkill)
	local curSkill = self.attackerCurSkill[index]
	if isDelete then
		if curSkill and curSkill.id == skill.id and curSkill.owner.id == skill.owner.id then
			table.remove(self.attackerCurSkill,index)
		end
	else
		if not curSkill or (curSkill and curSkill.id ~= skill.id and curSkill.owner.id ~= skill.owner.id) then
			table.insert(self.attackerCurSkill,skill)
		end
	end
end

function ObjectModel:getStar()
	return self.star
end

-- 技能指示器 getTargetsHint
function ObjectModel:cantBeSelectCheck(env)
	-- 离场无法被选中
	if self:checkOverlaySpecBuffExit("leave") then
		return true
	end

	if self:checkOverlaySpecBuffExit("stealth") then
		-- 存在隐身buff无法被无视
		for _,data in self:ipairsOverlaySpecBuffTo("stealth", env.fromObj) do
			-- 如果当前技能类型是回血, 1. 不能被治疗指示器选中 2.不能被敌方治疗技能选中
			if battleEasy.isSameSkillType(env.skillFormulaType,battle.SkillFormulaType.resumeHp) then
				if data.cantBeHealHintSwitch or env.fromObj.force ~= self.force then
					return true
				end
			-- 隐身时无法被伤害技能指示器选中
			elseif env.skillFormulaType == nil or battleEasy.isSameSkillType(env.skillFormulaType,battle.SkillFormulaType.damage) then
				return true
			end
		end
	end

	if self:checkOverlaySpecBuffExit("depart") then
		for _,data in self:ipairsOverlaySpecBuffTo("depart", env.fromObj) do
			if battleEasy.isSameSkillType(env.skillFormulaType,battle.SkillFormulaType.resumeHp) then
				if data.cantBeHealHintSwitch then
					return true
				end
			elseif env.skillFormulaType == nil or battleEasy.isSameSkillType(env.skillFormulaType,battle.SkillFormulaType.damage) then
				return true
			end
		end
	end

	return false
end
-- isSelfControled
function ObjectModel:cantAttackCheck(env)
	local leaveCheck  = false
	if self:checkOverlaySpecBuffExit("leave") then
		for _,data in self:ipairsOverlaySpecBuffTo("leave", env.fromObj) do
			if not data.canAttack then
				leaveCheck = true
			end
		end
	end
	local departCheck = false
	if self:checkOverlaySpecBuffExit("depart") then
		for _,data in self:ipairsOverlaySpecBuffTo("depart", env.fromObj) do
			if not data.canAttack then
				leaveCheck = true
			end
		end
	end

	if self:checkOverlaySpecBuffExit("stun")
		or self:checkOverlaySpecBuffExit("changeImage")
		or self:checkOverlaySpecBuffExit("freeze")
		or self:checkOverlaySpecBuffExit("sleepy")
		or leaveCheck or departCheck then
		return true
	end

	return false
end
-- object:checkBuffCanBeAdd
function ObjectModel:cantBeAddBuffCheck(env)
	-- 对于隐身 旧离场 新离场自己给自己加的buff, 该函数返回判断为false
	-- 对于是否能加上 还需要在checkBuffAddConditions再进行判断
	if not env.fromObj or env.fromObj.id ~= self.id then
		for _,data in self:ipairsOverlaySpecBuffTo("leave", env.fromObj, env) do
			return true
		end

		if self:checkOverlaySpecBuffExit("stealth") then
			for _,data in self:ipairsOverlaySpecBuffTo("stealth", env.fromObj, env) do
				if data.cantBeAttackSwitch then
					if data.cantBeAddBuffSwitch then return true
					-- 己方加的buff是可添加上的，敌方给加的buff是不可添加的
					elseif not data.cantBeAddBuffSwitch and env.fromObj and env.fromObj.force ~= self.force then
						return true
					end
				end
			end
		end

		if self:checkOverlaySpecBuffExit("depart") then
			for _,data in self:ipairsOverlaySpecBuffTo("depart", env.fromObj, env) do
				if data.leaveSwitch then return true end
				if data.cantBeAttackSwitch then
					if data.cantBeAddBuffSwitch then return true
					elseif not data.cantBeAddBuffSwitch and env.fromObj and env.fromObj.force ~= self.force then
						return true
					end
				end
			end
		end
	end
	return false
end
-- 技能伤害段
function ObjectModel:cantBeAttackCheck(env)
	-- 离场无法被攻击
	if self:checkOverlaySpecBuffExit("leave") then
		return true
	end

	if self:checkOverlaySpecBuffExit("stealth") then
		-- 存在隐身buff无法被无视 或 隐身buff无法被攻击
		for _,data in self:ipairsOverlaySpecBuffTo("stealth", env.fromObj) do
			-- 存在不能被过程段选中 就不能被过程段选中
			if data.cantBeAttackSwitch then
				return true
			end
		end
	end

	if self:checkOverlaySpecBuffExit("depart") then
		for _,data in self:ipairsOverlaySpecBuffTo("depart", env.fromObj) do
			if data.cantBeAttackSwitch then
				return true
			end
		end
	end

	return false
end
-- canSpell()
function ObjectModel:cantUseSkillCheck(env)
	-- 沉默配置
	if self:checkOverlaySpecBuffExit("silence") then
		for _,data in self:ipairsOverlaySpecBuff("silence") do
			-- 沉默的技能存在
			if env.skillId then
				if data.closeSkill[env.skillId] then return true end
			end
			-- 沉默的技能类型存在
			if env.skillType2 then
				if data.closeSkillType2[env.skillType2] then return true end
			end
		end
		-- 无法沉默时不生效
	end

	-- 混乱配置
	if self:checkOverlaySpecBuffExit("confusion") then
		for _, data in self:ipairsOverlaySpecBuff("confusion") do
			if env.skillType2 then
				if data.closeSkillType2[env.skillType2] then return true end
			end
		end
	end

	if env.skillType2 then
		if self:isSKillType2Close(env.skillType2) then return true end
	end

	return false
end

local logicStateExtraCheck = {
	[battle.ObjectLogicState.cantBeSelect] = ObjectModel.cantBeSelectCheck,
	[battle.ObjectLogicState.cantAttack] = ObjectModel.cantAttackCheck,
	[battle.ObjectLogicState.cantBeAddBuff] = ObjectModel.cantBeAddBuffCheck,
	[battle.ObjectLogicState.cantBeAttack] = ObjectModel.cantBeAttackCheck,
	[battle.ObjectLogicState.cantUseSkill] = ObjectModel.cantUseSkillCheck,
}

-- env
-- skillType2: 技能类型2
-- skillId: 技能id
-- toObj: 针对目标
function ObjectModel:isLogicStateExit(index,env)
	-- local ret = false
	-- local _ret

	-- if logicStateExtraCheck[index] and ret then
	-- 	_ret = logicStateExtraCheck[index](self,env or {})
	-- 	ret = battleEasy.ifElse(_ret == nil,ret,_ret)
	-- end

	return logicStateExtraCheck[index](self,env or {})
end

function ObjectModel:addExRecord(eventName, args, ...)
	self.scene.extraRecord:addExRecord(eventName, args, self.id, ...)
end

function ObjectModel:getEventByKey(eventName, ...)
	return self.scene.extraRecord:getEventByKey(eventName, self.id, ...)
end

function ObjectModel:cleanEventByKey(eventName, ...)
	return self.scene.extraRecord:cleanEventByKey(eventName, self.id, ...)
end

function ObjectModel:effectPowerControl(key, trigger)
	local controlEvent = self.effectPower[key]
	if not controlEvent then return true end
	if type(controlEvent) == 'table' then
		if trigger and controlEvent[trigger] == 0 then return false end
	else
		if controlEvent == 0 then return false end
	end
	return true
end

function ObjectModel:serverForce()
	return self.scene.play.operateForce == 1 and self.force or (3 - self.force)
end

function ObjectModel:serverSeat()
	return self.scene.play.operateForce == 1 and self.seat or battleEasy.mirrorSeat(self.seat)
end

function ObjectModel:getTakeDamageRecord(valueKey, needCurWave)
	local sumTakeDamage = 0
	if needCurWave then
		sumTakeDamage = self.totalTakeDamage[self.scene.play.curWave]:get(valueKey)
	else
		for _, v in ipairs(self.totalTakeDamage) do
			sumTakeDamage = sumTakeDamage + v:get(valueKey)
		end
	end
	return sumTakeDamage
end

function ObjectModel:needAlterForce()
	if not self.curSkill then return false end
	-- 以伤害类型打己方且处于混乱状态或嘲讽状态 改变阵营
	if self:isSameForce(self:getCurTarget()) and (self:isBeInConfusion() or self:isBeInSneer())
		and self.curSkill:isSameType(battle.SkillFormulaType.damage) then
		return true
	end
	return false
end

function ObjectModel:triggerOriginEnvCheck(typ, val)
	if self.triggerEnv[typ]:empty() then return false end
	return	self.triggerEnv[typ]:front() == val
end

function ObjectModel:updateSkillState(isSelfTurn)
	self.skillsMap = {}
	for skillID, skill in self:iterSkills() do
		skill:updateStateInfoTb()
		if isSelfTurn and skill.skillType2 == battle.MainSkillType.BigSkill and skill.stateInfoTb.canSpell and self.unitCfg.combinationSkillId then
			local combSkillId = self.unitCfg.combinationSkillId
			if self.passiveSkills[combSkillId] and self.passiveSkills[combSkillId]:isCanUseCombineSkill(battle.CombineSkillType.spellBigSkill) then
				self.skillsMap[skillID] = combSkillId
				self.skills[combSkillId] = self.passiveSkills[combSkillId]
				self.skills[combSkillId]:updateStateInfoTb()
			end
		end
	end
end

function ObjectModel:getBaseAttr(attr)
	if self.multiShapeTb then
		return self.multiShapeTb[1] == 1 and self.attrs.base[attr] or self.attrs.base2[attr]
	end

	return self.attrs.base[attr]
end

function ObjectModel:getRealFinalAttr(attr)
	if self.multiShapeTb then
		return self.multiShapeTb[1] == 1 and self.attrs.final[attr] or self.attrs:getBase2RealFinalAttr(attr)
	end

	return self.attrs.final[attr]
end

-- 记录cow第一遍预计算的数据
function ObjectModel:cowPreCalcRecord()
	if self.scene.play.preCalcLethalDatas then
		local filter = function(data)
			return not (data:checkToObj() and data:checkCondition())
		end
		for _,__ in self:ipairsOverlaySpecBuff(battle.OverlaySpecBuff.lethalProtect, filter) do
			self.scene.play.preCalcLethalDatas[1][self.id] = true
			break
		end
		if not self:checkOverlaySpecBuffExit(battle.OverlaySpecBuff.lethalProtect) then
			table.insert(self.scene.play.preCalcLethalDatas[2], self.id)
		end
	end
end

local slayAddMp1Funcs = {
	[game.GATE_TYPE.crossArena] = function(attacker)
		local scene = attacker.scene
		local correctCfg = scene:getSceneAttrCorrect(attacker:serverForce())
		local slayAddMp1Fix = 1
		if scene.play.curWave == 1 or scene.play.curWave == 3 then
			slayAddMp1Fix = (correctCfg.slayAddMp1Fix and correctCfg.slayAddMp1Fix[1]) or 1
		else
			slayAddMp1Fix = (correctCfg.slayAddMp1Fix and correctCfg.slayAddMp1Fix[2]) or 1
		end
		return slayAddMp1Fix
	end
}

local function addObjMp1(obj, addValue)
	local mp1Correct = addValue * (1.0 + obj:mp1Recover())
	obj:setMP1(obj:mp1() + mp1Correct)
end

function ObjectModel:addAttackerMpOnSelfDead(attacker)
	if not attacker or attacker.id == self.id or not self:effectPowerControl(battle.EffectPowerType.killAddMp1) then	-- todo: 可能还需要判断是不是技能触发的死亡
		return
	end

	local slayAddMp1Fix = slayAddMp1Funcs[self.scene.gateType] and slayAddMp1Funcs[self.scene.gateType](attacker) or 1
	local slayAddMp = gCommonConfigCsv and gCommonConfigCsv.slayAddMp or 0
	addObjMp1(attacker, slayAddMp * slayAddMp1Fix)
	-- 这里不需要额外记录显示, 此时仍然位于 技能的过程段流程之内,属于过程段中的表现效果
	-- 不需要你个鬼
	battleEasy.deferNotify(nil,'showMP1Award',{mp = ':'..tostring(slayAddMp), key = tostring(attacker)})

	if attacker.curSkill and attacker.curSkill.skillType == battle.SkillType.PassiveCombine then
		-- 合体技时需要同时增加释放合体技的两个人的怒气
		local combineObj = attacker.combineObj
		addObjMp1(combineObj, slayAddMp)
		battleEasy.deferNotify(nil,'showMP1Award',{mp = ':'..tostring(slayAddMp), key = tostring(combineObj)})
	end
end

function ObjectModel:getSummonerLevel()
	-- 获取作为召唤者时的等级
	return self.level
end

function ObjectModel:setCsvObject(obj)
	self.csvObject = obj
end

function ObjectModel:getCsvObject()
	return self.csvObject
end

function ObjectModel:toHumanString()
	return string.format("ObjectModel: %s(%s)", self.id, self.seat)
end

require "battle.models.object_buff"