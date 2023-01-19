--
-- 敌方怪
--

globals.MonsterModel = class("MonsterModel", ObjectModel)

function MonsterModel:ctor(scene, seat)
	ObjectModel.ctor(self, scene, seat)
end

function MonsterModel:init(data)
	self:initMonsterSkillData(data)

	self.isMonster = data.isMonster
	self.isBoss = data.isBoss
	self.showLevel = data.showLevel
	self.monsterCfg = gMonsterCsv[self.scene.sceneID][self.scene.play.curWave]
	ObjectModel.init(self, data)

	self.star = self.data.star or self.unitCfg.star or 0
end

function MonsterModel:initMonsterSkillData(data)
	-- 怪物方技能等级默认使用角色自身等级
	-- data.skills = table.defaulttable(function()
	-- 	return data.skillLevel
	-- end)

	data.skills = {}
	local skills = data.skills
	local unitCfg = csv.unit[data.roleId]

	for _, skillID in ipairs(unitCfg.skillList) do
		if not skills[skillID] then
			skills[skillID] = data.skillLevel
		end
	end

	for _, skillID in ipairs(unitCfg.passiveSkillList) do
		if not skills[skillID] then
			skills[skillID] = data.skillLevel
		end
	end
end

-- 怪物属性读表
function MonsterModel:onInitAttributes()
	if self.type == battle.ObjectType.Summon or self.type == battle.ObjectType.SummonFollow then
		return ObjectModel.onInitAttributes(self)
	end
	self:setBaseData(self:getMonsterData())
end

function MonsterModel:checkUnitCheat()
	if ANTI_AGENT then return end

	checkSpecificCsvCheat("unit", itertools.ivalues({self.unitID}))
end

-- 获取怪物的roleOut数据
function MonsterModel:getMonsterData()
	self:checkUnitCheat()

	local base = csvClone(csv.base_attribute[self.attributeType].base_attribute[self.level])	--基础属性表
	-- unit表对属性的修正 (直接乘即可)
	for _, key in ipairs(game.ATTRDEF_TABLE) do
		if not base[key] then base[key] = 0 end
		-- 修正
		local multi = self.unitCfg[key .. "C"] or 1
		base[key] = base[key] * multi
		-- 等级成长加成
		local add = self.unitCfg[key .. "Grow"] or 0
		base[key] = base[key] + add * self.level
	end
	return base
end

function MonsterModel:getSummonerLevel()
	return self.showLevel
end

