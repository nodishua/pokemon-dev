--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2019 TianJi Information Technology Inc.
--
--
-- csv使用的定义
-- 如果只在csv中使用的功能则在CsvXXX中留函数
-- 如果逻辑中也要使用，增在XXXModel中实现，在这里导出
--

local GlobalBaseEnv

battleCsv.Model2CsvCls = {
	ObjectModel = battleCsv.CsvObject,
	MonsterModel = battleCsv.CsvObject,
	BossModel = battleCsv.CsvObject,
	ObjectExtraModel = battleCsv.CsvObject,
	SceneModel = battleCsv.CsvScene,
	SkillModel = battleCsv.CsvSkill,
	BuffSkillModel = battleCsv.CsvSkill,
	PassiveSkillModel = battleCsv.CsvSkill,
	BuffModel = battleCsv.CsvBuff,
}

-- 有些不必导入到全局空间
local IgnoreGlobalFuncNames = {
	__index = true,
	__newindex = true,
	new = true, -- 构造函数
	force = true, -- CsvObject和makeFindEnv.force同名
	level = true,
	sumBuffOverlayByGroup = true, -- CsvObject和CsvScene有同名函数
	getDamageState = true,
	getDamageStateByTarget = true,
}

-- easy func in global
-- self:skillLv(123) -> skillLv(123)
local function exportFuncForGlobal(objKey, cls)
	for k, f in pairs(cls) do
		if not IgnoreGlobalFuncNames[k] and type(f) == "function" then
			assert(GlobalBaseEnv[k] == nil, string.format("%s `%s` already in protected env", type(cls), k))
			GlobalBaseEnv[k] = function(...)
				local env = GlobalBaseEnv._exEnv
				return f(env[objKey], ...)
			end
		end
	end
end


-- 是否在表中存在
local function exitInTab(a,tab)
	for _,v in pairs(tab) do
		if a == v then return true end
	end
	return false
end

-- 防止<>同csv的尖括号配置格式冲突
-- ifElse(more(a, 1), 2, 3) * 4
local function more(a, b)
	return a > b
end

local function less(a, b)
	return a < b
end

local function moreE(a, b)
	return a >= b
end

local function lessE(a, b)
	return a <= b
end

-- 性能暂不考虑，消耗比三元运算and or大
-- ifElse(moreE(self:star(),8), 6, 4)
-- ==>
-- ifMoreE(self:star(), 8, 6, 4)
local function ifMore(a, b, tv, fv)
	if a > b then
		return tv
	end
	return fv
end

local function ifLess(a, b, tv, fv)
	if a < b then
		return tv
	end
	return fv
end

local function ifMoreE(a, b, tv, fv)
	if a >= b then
		return tv
	end
	return fv
end

local function ifLessE(a, b, tv, fv)
	if a <= b then
		return tv
	end
	return fv
end

-- 防止出现被除数为0
local function div(lef, rig, min)
	if rig == 0 then return min end
	return lef / rig
end

-- false, nil, 0 = 0
-- other = 1
local function to10(v)
	if v == nil or v == false or v == 0 then
		return 0
	end
	return 1
end

-- false, nil, 0 = false
-- other = true
local function tobool(v)
	if v == nil or v == false or v == 0 then
		return false
	end
	return true
end

local function exitInArray(array, str)
	return itertools.include(array, battle.CsvStrToMap[str.."Iter"])
end

-- 防止{}table格式同csv的花括号配置格式冲突
local function list(...)
	-- 现在战斗中公式不缓存，无需deepcopy
	return {...}
end
-- 获取数值表类型的值
local function getValueTab(tab,typ)
	if tab and tab.__valueTypeTable then
		return tab:get(typ)
	end
	return 0
end

local function makeGlobalBaseEnv(exEnv)
	if GlobalBaseEnv then
		rawset(GlobalBaseEnv, '_exEnv', exEnv)
		return GlobalBaseEnv
	end

	assert(gFormulaConst, "gFormulaConst is nil")
	GlobalBaseEnv = {
		c = gFormulaConst,

		-- non-intrusive code
		-- anti-agent will hack the ymrand.random function
		random = function(...)
			return ymrand.random(...)
		end,

		select = select,
		min = math.min,
		max = math.max,
		div = div,
		clamp = cc.clampf,
		to10 = to10,

		ifElse = battleEasy.ifElse,
		ifMore = ifMore,
		ifLess = ifLess,
		ifMoreE = ifMoreE,
		ifLessE = ifLessE,
		more = more,
		less = less,
		moreE = moreE,
		lessE = lessE,

		exitInTab = exitInTab,

		getValueTab = getValueTab,

		moreThan = more,
		lessThan = less,
		moreEqualThan = moreE,
		lessEqualThan = lessE,
		list = list,

		exitInArray = exitInArray,

		battle = battle,

		-- 外部传入的env
		_exEnv = exEnv,
	}
	local p = GlobalBaseEnv

	-- buffRHpIdx 来自buff的治疗
	for k,v in pairs(battle.ResumeHpFrom) do
		p[k.."RHpIdx"] = v
	end

	-- normalValIdx 正常数值
	for k,v in pairs(battle.ValueType) do
		p[k.."ValIdx"] = v
	end

	-- buffDmgIdx 来自buff的伤害
	for k,v in pairs(battle.DamageFrom) do
		p[k.."DmgIdx"] = v
	end

	exportFuncForGlobal("self", battleCsv.CsvObject)
	-- exportFuncForGlobal("target", battleCsv.CsvObject)
	-- exportFuncForGlobal("owner", battleCsv.CsvObject)
	-- exportFuncForGlobal("caster", battleCsv.CsvObject)
	-- exportFuncForGlobal("holder", battleCsv.CsvObject)
	-- exportFuncForGlobal("attacker", battleCsv.CsvObject)
	exportFuncForGlobal("scene", battleCsv.CsvScene)
	exportFuncForGlobal("skill", battleCsv.CsvSkill)
	exportFuncForGlobal("buff", battleCsv.CsvBuff)

	p.__index = p

	setmetatable(p, {
		__newindex = function(t, k, v)
			error("you could not write in GlobalBaseEnv with " .. k)
		end,
	})
	return p
end

-- 延后, 因为gFormulaConst在battle loading时生效
-- makeGlobalBaseEnv()

function battleCsv.doFormula(strOrTable, env, key)
	if env.fillEnv then
		env:fillEnv(makeGlobalBaseEnv(env))
	else
		setmetatable(env, makeGlobalBaseEnv(env))
	end

	return eval.doFormula(strOrTable, env, key)
end


-- 设置本次筛选的作用单位的环境，作为扩展环境
-- TODO: 需要改造
function battleCsv.makeFindEnv(caster, selectedObj, args)
	local forceNumber = battlePlay.Gate.ForceNumber
	local env = {
		self = caster, -- 自己
		selectObj = selectedObj, -- 手动/自动选定目标, 是从外部传入的, 所以在使用选择功能时, 记得传入这个目标
		skillSegType = args and args.skillSegType,
		skillFixType = args and args.skillFixType,
		force = selectedObj and selectedObj.force or caster.force,
		forceNumber = forceNumber,
		rowNumber = forceNumber / 2,
		getRowAndColumn = battleEasy.getRowAndColumn,

		csvSelf = battleCsv.CsvObject.new(caster),
		csvSelectObj = battleCsv.CsvObject.new(selectedObj),
	}
	env.env = env
	return env
end

function battleCsv.makeProtectedEnv(obj, skill, buff)
	local scene = (obj and obj.scene) or (scene and scene.scene) or (buff and buff.scene)
	assert(scene, "no scene be contained in params")
	local p = {
		scene = battleCsv.CsvScene.new(scene),
	}
	p.env = p

	if obj then
		p.self = battleCsv.CsvObject.new(obj)
	end

	if skill then
		p.skill = battleCsv.CsvSkill.new(skill)
		p.owner = p.self
	end

	if buff then
		p.buff = battleCsv.CsvBuff.new(buff)
		p.caster = (buff.caster and buff.caster == obj) and p.self or battleCsv.CsvObject.new(buff.caster)
		p.holder = battleCsv.CsvObject.new(buff.holder)
		p.target = p.holder -- 策划可能会习惯把holder作为target
		p.fromSkillLevel = buff.fromSkillLevel
	end


	local pp = protectedEnv(p)
	pp:fillEnv(makeGlobalBaseEnv(pp), true)

	return pp
end

function battleCsv.makeDamageProcessEnv(attacker,target,record,attr)
	local scene = (attacker and attacker.scene) or (target and target.scene)
	assert(scene, "no scene be contained in params")
	local p = {
		arg = record.args,
		scene = battleCsv.CsvScene.new(scene),
	}
	p.env = p

	-- 构造一个obectAttr单位
	p.setBaseAttr = ObjectAttrs.setBaseAttr
	p.addBaseAttr = ObjectAttrs.addBaseAttr
	p.updateMaxBaseAttr = ObjectAttrs.updateMaxBaseAttr
	p.isAttr = functools.partial(function(attrTab,key)
		return attrTab[key] and true or false
	end, ObjectAttrs.AttrsTable)

	local _attr,_args = {}
	for name, v in pairs(attr) do
		_attr[name] = 0
		if not ObjectAttrs.AttrsTable[name] then
			p[name] = v
		else
			p[name] = function(self)
				return self.final[name]
			end
		end
	end

	p.base = table.salttable(_attr)
	p.base2 = table.salttable(_attr)
	p.buff = table.salttable(_attr)
	p.final = table.salttable(attr)
	-- 以下接口提供给策划使用
	p.setValue = functools.partial(function(self,keys,values)
		for idx,key in ipairs(keys) do
			if self.isAttr(key) then
				self:setBaseAttr(key,values[idx])
			else
				self[key] = values[idx]
			end
		end
		return self
	end, p)

	p.updateMaxValue = functools.partial(function(self,keys,values)
		for idx,key in ipairs(keys) do
			if self.isAttr(key) then
				self:updateMaxBaseAttr(key,values[idx])
			else
				self["G_"..key] = math.max(self["G_"..key] or 0, values[idx])
			end
		end
		return self
	end, p)

	if attacker then
		p.attacker = battleCsv.CsvObject.new(attacker)
	end

	if target then
		p.target = battleCsv.CsvObject.new(target)
	end

	return p
end

-- @return: 1 set in env(may be nil), 2 get other data(always)
local function getVarForEnv(protected, args, key)
	local pobj = rawget(protected, key)
	local obj = args[key]
	if obj then
		if pobj then
			assert(pobj.model == obj, string.format("%s not same in protected, %s, %s", key, tostring(pobj.model), tostring(obj)))
			return nil, obj
		else
			local cls = battleCsv.Model2CsvCls[tj.type(obj)]
			if cls then
				return cls.new(obj), obj
			end
			return obj, obj
		end
	else
		return nil, pobj and pobj.model
	end
end

-- @param: args 如果只是为了刷新变量，args可为nil
function battleCsv.fillFuncEnv(protected, args)
	-- local scene = obj.scene
	-- local info = {selfReduce = scene:reduceHeroCount(obj.force),
	-- 			targetReduce = scene:reduceHeroCount(obj:getEnermyForce()),
	-- 			selfFightSoul = scene.fightSoulKinds[obj.force],
	-- 			targetFightSoul = scene.fightSoulKinds[obj:getEnermyForce()]}

	args = args or {}

	local added = {}
	local selfEnv, self = getVarForEnv(protected, args, "self")
	-- print(protected, 'getVarForEnv self', selfEnv, self )
	args.self = nil
	if selfEnv then
		added.self = selfEnv
	end
	if self then
		if self.curAttackMeObj then
			added.attackMeObj = battleCsv.CsvObject.new(self.curAttackMeObj)
		end
	end

	local skillEnv, skill = getVarForEnv(protected, args, "skill")
	args.skill = nil
	if skillEnv then
		added.skill = skillEnv
		added.owner = protected.obj
	end
	-- TODO: 需要拿到一个即时的level?
	added.skillLevel = skill and skill:getLevel() or 1

	local targetEnv, target = getVarForEnv(protected, args, "target")
	-- print(protected, 'getVarForEnv target', targetEnv, target)
	added.target = targetEnv
	args.target = nil

	local buffEnv, buff = getVarForEnv(protected, args, "buff")
	args.buff = nil
	if buffEnv then
		added.buff = buffEnv
		added.caster = battleCsv.CsvObject.new(buff.caster)
		added.holder = battleCsv.CsvObject.new(buff.holder)
		added.target = added.target or added.holder -- 策划可能会习惯把holder作为target
		added.fromSkillLevel = buff.fromSkillLevel
	end

	for k, v in pairs(args) do
		args[k] = getVarForEnv(protected, args, k)
	end

	for k, v in pairs(added) do
		assert(args[k] == nil, string.format("`%s` already in args", k))
		args[k] = v
	end

	-- if selfEnv then
	-- 	-- easy func in global
	-- 	-- self:skillLv(123) -> skillLv(123)
	-- 	-- exportFuncForGlobal(args, battleCsv.CsvObject, selfEnv)
	-- 	setGlobalObj(args, battleCsv.CsvObject, selfEnv)
	-- end

	return protected:fillEnvInFront(args)
end

function battleCsv.makeEnv(args)
	local protected = battleCsv.makeProtectedEnv(args.self, args.skill, args.buff)
	args.self = nil
	args.skill = nil
	args.buff = nil
	return battleCsv.fillFuncEnv(protected, args)
end
