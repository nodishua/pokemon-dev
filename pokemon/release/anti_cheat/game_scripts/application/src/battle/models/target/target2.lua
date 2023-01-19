
--	choose：1-input; 2-process

--
-- 0-env  放到前面的选目标时来设置
--
-- selectObj 参照目标, 由外部的攻击流程传入:先选择技能,再选择具体哪个攻击目标, 这时候这个选定的目标就是参照物
-- 在这种流程下,施法者自身的作用反而不那么有用了,只要这个selectObj存在就行了,就算是给自己施法,也是需要点一下自己的
-- 考虑另外一种情况, 在数码中buff是可以独立为其它目标添加另一个buff的, 这时候如果要选择出来这些目标,
-- 则要知道这个selectObj对象, 但此时不能直接通过操作或者自动操作来选择它了,配置应该同时支持这两种形式的
-- 这时候需要self来作为辅助,此时的一些区分敌我方的初步选择函数才真正是有作用的, 也就是除了selectObj外, self也需要传入...

-- local env = {}
-- env.self = self -- 自己
-- env.selectObj = selectObj -- 手动/自动选定目标, 是从外部传入的, 所以在使用选择功能时, 记得传入这个目标
-- env.force = nil -- input or selectObj
-- -- env.forceNumber = self.scene.play.ForceNumber
-- env.forceNumber = 6
-- env.rowNumber = env.forceNumber / 2

-- --
-- input
--
local input = {}
battleTarget.input = input

-- 1-常用的几种input
function input.myself()
	env.force = self.force
	env.selectObj = self
	return {self}
end

function input.selected()
	env.force = selectObj and selectObj.force or env.force
	return {selectObj}
end

function input.object(id, type)
	id = self.scene.play.operateForce == 2 and mirrorSeat(id) or id
	local object = self.scene:getObjectBySeatExcludeDead(id, type)
	env.force = object and object.force or env.force
	env.selectObj = object
	return {object}
end

function input.objectEx(force,id)
    local enemyForce = self.force == 1 and 2 or 1
    local force = force == 0 and self.force or enemyForce
	local object = self.scene:getGroupObj(force,id)
	env.force = object and object.force or env.force
	env.selectObj = object
	return {object}
end

function input.all()
	env.force = selectObj and selectObj.force or env.force
	local iter1 = itertools.iter(self.scene:getHerosMap(1):pairs())
	local iter2 = itertools.iter(self.scene:getHerosMap(2):pairs())
	local ret = itertools.values(itertools.chain({iter1, iter2}))
	table.sort(ret, function(o1, o2)
		return o1.id < o2.id
	end)
	return ret
end

function input.selfForce()
	env.force = self.force
	--env.selectObj = self
	local map = self.scene:getHerosMap(self.force)
	return itertools.values(map:order_pairs())
end

function input.enemyForce(noAlterForce)
	env.force = 3 - self.force
	local enemyForce = 3 - self.force
	local isSpellTo = self.curSkill and self.curSkill.isSpellTo
	-- noAlterForce 不填默认false, 兼容原来的
	local needAlterForce = not noAlterForce and self:needAlterForce() and isSpellTo
	if needAlterForce then
		enemyForce = self.force
	end
	env.force = enemyForce			-- 此时的默认force改变了
	local map = self.scene:getHerosMap(enemyForce)
	local ret = itertools.values(map:order_pairs())
	if needAlterForce then
		return arraytools.filter(ret, function(_, obj)
			return obj.id ~= self.id
		end)
	else
		return ret
	end
end

function input.extraHerosAll()
	env.force = selectObj and selectObj.force or env.force
	return itertools.values(self.scene.extraHeros:order_pairs())
end

function input.enemyRow(front, recursion)
	local force = (self.force == 1 and 2 or 1)
	local cnt, ret = self.scene:getRowRemain(force, front)
	if cnt == 0 and recursion then
		front = (front == 1 and 2 or 1)
		cnt, ret = self.scene:getRowRemain(force, front)
	end
	return ret
end

function input.And(input1, input2)
	local ret = {}
	local map = {}
	for _, target in ipairs(input1) do
		table.insert(ret, target)
		map[target.id] = true
	end
	for _, target in ipairs(input2) do
		if not map[target.id] then
			table.insert(ret, target)
			map[target.id] = true
		end
	end
	table.sort(ret, function(o1, o2)
		return o1.id < o2.id
	end)
	return ret
end

-- 2-选取杀死自己的目标
-- attackMeDeadObj 杀死施法者的目标(这个目标在自杀时会是自己)
function input.whokill()
	return {self.attackMeDeadObj}
end

-- 3-选择攻击自己的目标
-- curAttackMeObj 当前正在攻击施法者的目标
function input.whoattack()
	return {self.curAttackMeObj}
end

-- 4-仇恨追踪的目标
-- attackMeDeadObjHatred 杀死自己的目标(这个目标一定是敌人)
function input.whohatred()
	return {self.attackMeDeadObjHatred}
end

-- 5-自己当前技能的主目标
function input.mainTarget()
	return {self:getCurTarget()}
end

-- 6-自己当前技能的所有伤害目标
function input.allDamageTargets()
	local ret = {}
	if self.curSkill then
		ret = self.curSkill:targetsMap2Array(self.curSkill.allDamageTargets)
	end
	return ret
end

--
-- input.decorator
--
input.decorator = {}
function input.decorator.nodead(targets)
	return arraytools.filter_inplace(targets, function(_, o)
		return not o:isAlreadyDead()
	end)
end

function input.decorator.nodeath(targets)
	return arraytools.filter_inplace(targets, function(_, o)
		return not o:isDeath()
	end)
end

function input.decorator.leaveExtraDeal(args,targets)
	for _, obj in ipairs(targets) do
		if obj.id == args.casterId then return {obj} end
	end
	return {}
end

function input.decorator.nobeskillselectedhint(args,targets)
	return arraytools.filter_inplace(targets, function(_, o)
		return not o:isLogicStateExit(battle.ObjectLogicState.cantBeSelect, {fromObj = self,skillFormulaType = args.skillFormulaType})
	end)
end
-- 只跟技能过程段伤害目标有关 其他不加该公式
function input.decorator.nobeskillselected(targets)
	return arraytools.filter_inplace(targets, function(_, o)
		if o.id == self.id then
			return true
		end
		return not (o:isLogicStateExit(battle.ObjectLogicState.cantBeAttack, {fromObj = self}) or o:extraBattleRoundCantAttack())
	end)
end

--
-- process
--
local process = {}
battleTarget.process = process

-- 1-通用选择类型
function process.limit(num, targets)
	return arraytools.slice(targets, 1, num or 1)
end

function process.single(targets)
	return {targets[1]}
end
process.first = process.single

--当前选择的目标
function process.curSelected(targets)
	return {selectObj}
end

function process.shuffle(targets)
	for i = 1, table.length(targets) do
		local j = ymrand.random(0, table.length(targets) - i) + i
		targets[i], targets[j] = targets[j], targets[i]
	end
	return targets
end

function process.random(num, targets)
	num = num or 1
	if num < 1 then return {} end
	if num >= table.length(targets) then return targets end
	if num == 1 then
		return {targets[ymrand.random(1, table.length(targets))]}
	end
	for i = 0, table.length(targets) - num - 1 do
		local tail = table.length(targets)
		local j = ymrand.random(1, tail)
		targets[j] = targets[tail]
		arraytools.pop(targets)
	end
	return targets
end


function process.exclude(idArray, targets)
	local hash = arraytools.hash(idArray)
	return arraytools.filter(targets, function(_, o)
		return not hash[o.seat]
	end)
end

function process.include(idArray, targets)
	local hash = arraytools.hash(idArray)
	return arraytools.filter(targets, function(_, o)
		return hash[o.seat]
	end)
end

local function searchTarget(targets, getF, greaterF, count)
	local tmpSortTb, ret = {}, {}
	for id, target in ipairs(targets) do
		local sortData = {
			val = getF(target),
			id = id
		}
		table.insert(tmpSortTb, sortData)
	end
	table.sort(tmpSortTb, function (a,b)
		return greaterF(a.val, b.val)
	end)
	for i = 1, count do
		if tmpSortTb[i] then
			table.insert(ret, targets[tmpSortTb[i].id])
		end
	end
	return ret
end

local function filtercantBeSelect(self,targets,env)
	local ret = itertools.filter(targets,function(id,obj)
		for _,data in obj:ipairsOverlaySpecBuffTo("leave", self, env) do
			return false
		end
		local skillFormulaType = self.curSelectSkill and self.curSelectSkill.skillFormulaType
		skillFormulaType = env.skillFixType or skillFormulaType
		for _,data in obj:ipairsOverlaySpecBuffTo("stealth", self, env) do
			if not data.cantBeHealHintSwitch and (battleEasy.isSameSkillType(env.skillSegType, battle.SkillFormulaType.resumeHp)
				or battleEasy.isSameSkillType(skillFormulaType, battle.SkillFormulaType.resumeHp)) then
				return true
			end
			return false
		end
		for _,data in obj:ipairsOverlaySpecBuffTo("depart", self, env) do
			if not data.cantBeHealHintSwitch and (battleEasy.isSameSkillType(env.skillSegType, battle.SkillFormulaType.resumeHp)
				or battleEasy.isSameSkillType(skillFormulaType, battle.SkillFormulaType.resumeHp)) then
				return true
			end
			return false
		end
		return true
	end)

	return ret
end
-- 2-属性选择类型
local function valBigger(v, vmax)
	return v > vmax
end

local function tupleBigger(v, vmax)
	if v[1] > vmax[1] then
		return true
	elseif v[1] < vmax[1] then
		return false
	else
		if v[2] > vmax[2] then
			return true
		else
			return false
		end
	end
end

function process.attr(typs, comp, count, targets)
	local sign = (comp == "max" and 1 or -1)
    local count = count or 1
    if typs == "selectAttr" then
        typs = selectObj[typs]
        selectObj[typs] = nil
    end
    local filteredTargets = filtercantBeSelect(self,targets,env)
	return searchTarget(filteredTargets, function (target)
		local typ = typs
		if type(typs) == "table" then
			typ = searchTarget(typs, function (_typ)
				return sign * target[_typ](target)
			end, valBigger, 1)[1]
		end
		return sign * target[typ](target)
    end, valBigger, count)
end

function process.attrRatio(typ, comp, count, targets)
	local sign = (comp == "max" and 1 or -1)
	if typ ~= 'hp' and typ ~= 'mp' then
		error("process.attrRatio can only use hp and mp1 attr")
	end
	local typMax = typ .. "Max"
	local filteredTargets = filtercantBeSelect(self,targets,env)
	return searchTarget(filteredTargets, function (target)
		local v1 = sign * target[typ](target)

		return {v1 / target[typMax](target), v1}
	end, tupleBigger, count)
end

-- 按要求获取选择对象属性组里的数值
function process.setSelectAttr(typs,comp,targets)
    -- local sign = (comp == "max" and 1 or -1)
	-- selectObj.selectAttr = searchTarget(typs, function (typ)
	--     return sign * selectObj[typ](selectObj)
	-- end, valBigger, 1)
	selectObj.selectAttr = typs
    return targets
end

process.hpMax = functools.partial(process.attr, "hp", "max", 1)
process.hpMin = functools.partial(process.attr, "hp", "min", 1)
process.hpRatioMax = functools.partial(process.attrRatio, "hp", "max", 1)
process.hpRatioMin = functools.partial(process.attrRatio, "hp", "min", 1)
process.attackDamageMax = functools.partial(process.attr, "damage", "max", 1)
process.attackDamageMin = functools.partial(process.attr, "damage", "min", 1)
process.defenceMax = functools.partial(process.attr, "defence", "max", 1)
process.defenceMin = functools.partial(process.attr, "defence", "min", 1)
process.mp1Max = functools.partial(process.attr, "mp1", "max", 1)
process.mp1Min = functools.partial(process.attr, "mp1", "min", 1)
process.mp1RatioMax = functools.partial(process.attrRatio, "mp1", "max", 1)
process.mp1RatioMin = functools.partial(process.attrRatio, "mp1", "min", 1)
process.specialDamageMax = functools.partial(process.attr, "specialDamage", "max", 1)
process.specialDamageMin = functools.partial(process.attr, "specialDamage", "min", 1)
process.speedMax = functools.partial(process.attr, "speed", "max", 1)
process.speedMin = functools.partial(process.attr, "speed", "min", 1)
process.specialDefenceMax = functools.partial(process.attr, "specialDefence", "max", 1)
process.specialDefenceMin = functools.partial(process.attr, "specialDefence", "min", 1)

-- 获得某项属性值, rate:类型是比例值时
local function getAttrValue(target, typ, rate)
	if rate then
		return target[typ](target)/target[typ .. "Max"](target)
	end
	return target[typ](target)
end

-- 目标某属性值 大于/小于 给定 值/比例值
function process.attrBiggerThanValue(typ, rate, comp, gVal, targets)
	local tars = {}
	for _,target in ipairs(targets) do
		local val = getAttrValue(target, typ, rate)
		if env[comp](val, gVal) then
			table.insert(tars, target)
		end
	end
	--return (comp == '>') and tars or process.exclude(tars, targets)
    return tars
end

-- 可以填一个值参数(目前先加hp的, 其它的貌似用的很少, 用到时候再加)
process.hpBiggerThan = functools.partial(process.attrBiggerThanValue, "hp", nil, 'moreThan')
process.hpLessThan = functools.partial(process.attrBiggerThanValue, "hp", nil, 'lessThan')
process.hpPerBiggerThan = functools.partial(process.attrBiggerThanValue, "hp", 'per', 'moreThan')
process.hpPerLessThan = functools.partial(process.attrBiggerThanValue, "hp", 'per', 'lessThan')

-- 获取技能正处于冷却时间范围内的单位
-- typ:max/min 获取最大/最小的一个单位 baseVal不生效
-- typ:moreE/lessE/equal 获取大于等于/小于等于/等于baseVal的所有单位
function process.getTargetsInSkillCdRange(typ,baseVal,targets)
    local rets = {}
    local checkTab = {
        max = env["moreThan"],
		min = env["lessThan"],
		moreE = env["moreE"],
		lessE = env["lessE"],
		equal = function(a, b) return a == b end
	}
	local curVal,targetVal, atLeastOne = 0,0,true
	local addFunc1 = function(target)
		if checkTab[typ](curVal,targetVal) then
			rets[1] = target
			targetVal = curVal
		end
	end
	local addFunc2 = function(target)
		if checkTab[typ](curVal,targetVal) then
			table.insert(rets,target)
		end
	end

	local addFunc
	if typ == "max" or typ == "min" then
		atLeastOne = true
		addFunc = addFunc1
	else
		atLeastOne = false
		targetVal = baseVal
		addFunc = addFunc2
	end

    for _,target in ipairs(targets) do
        for _, skill in target:iterSkills() do
            -- battle.MainSkillType.SmallSkill
            if skill.skillType2 == 1 then
                curVal = skill:getLeftCDRound()
                if atLeastOne then
					table.insert(rets,target)
					targetVal = curVal
                    atLeastOne = false
                else
                    addFunc(target)
                end
            end
        end
    end
    return rets
end

-- 获取一些特定特性的目标
local function getTargetByCharacterType(attrs, targets)
end

-- 获取一些特定属性的目标
local function getTargetsByNatureType(natureTypes, targets)
	local natureTypeMap = arraytools.hash(natureTypes)
	local retT = {}
	for _, target in ipairs(targets) do
		if (natureTypeMap[target:getNatureType(1)]) or (natureTypeMap[target:getNatureType(2)]) then
			table.insert(retT, target)
		end
	end
	return retT
end

-- 获取一些特定战斗Flag的目标
local function getTargetsByBattleFlag(battleFlags, targets)
	local battleFlagMap = arraytools.hash(battleFlags)
	local retT = {}
	for _, target in ipairs(targets) do
		local unitBattleFlags = target.unitCfg.battleFlag
		if unitBattleFlags then
			for _, battleFlag in ipairs(unitBattleFlags) do
				if battleFlagMap[battleFlag] then
					table.insert(retT, target)
					break
				end
			end
		end
	end
	return retT
end

local function getTargetsByBuff(ids,buffFunc,targets)
	local retT = {}
	for _, target in ipairs(targets) do
		for __, id in ipairs(ids) do
			if target[buffFunc](target, id) then
				table.insert(retT, target)
				break
			end
		end
	end
	return retT
end


local function filterTargetsByBuff(filter,targets)
	local retT = {}
	for _, target in ipairs(targets) do
		for __, buff in target:iterBuffs() do
			if filter(buff) then
				table.insert(retT, target)
				break
			end
		end
	end
	return retT
end

function process.attrDiffer(typ, natureTypes, targets)
	local retT = {}
	-- 特定属性组目标
	if typ == "natureType" then
		retT = getTargetsByNatureType(natureTypes, targets)

	-- 特定特性组目标
	elseif typ == "characterType" then
		-- retT = getTargetByCharacterType(attrs, targets)
	end
	return retT
end

function process.battleFlagDiffer(typ, battleFlags, targets)
	local retT = {}
	if typ == "battleFlag" then
		retT = getTargetsByBattleFlag(battleFlags, targets)
	end
	return retT
end

function process.buffDiffer(typ, ids, targets)
	local retT = {}
	if typ == "id" then
		retT = getTargetsByBuff(ids,'hasBuff', targets)

	elseif typ == "group" then
		retT = getTargetsByBuff(ids,'hasBuffGroup', targets)

	elseif typ == "groupFilter" then
		-- beDispel = 1
		local powersIds = ids[1]
		local groups = ids[2]
		retT = filterTargetsByBuff(function(buff)
			if itertools.include(groups,buff:group()) then
				for _power,v in pairs(powersIds) do
					if buff.csvPower[_power] ~= v then
						return false
					end
				end
				return true
			end
			return false
		end, targets)

	elseif typ == "type" then
		retT = getTargetsByBuff(ids,'hasTypeBuff', targets)
	end
	return retT
end

-- func:buffGrpProIn2Ary  args:{{},{},{},...} 数组靠前的优先
function process.randomSpec(num, func, args, targets)
	if num >= table.length(targets) then return targets end
	local condiStack = {}
	local ret = {}
	if func == "buffGrpProIn2Ary" then
		for _,groups in ipairs(args) do
			table.insert(condiStack,function(tar)
				return table.length(getTargetsByBuff(groups,'hasBuffGroup', {tar})) > 0
			end)
		end
	end

	while table.length(condiStack) > 0 do
		for _,tar in ipairs(targets) do
			if condiStack[1](tar) then
				table.insert(ret,tar)
			end
		end
		if table.length(ret) >= num then
			return process.random(num,ret)
		end
		table.remove(condiStack,1)
	end

	return ret
end

--process.natureType = functools.partial(process.attrDiffer, "natureType")
--process.characterType = functools.partial(process.attrDiffer, "characterType") --特性方面的相关信息还没有加
process.natureTypeExcept = function(natureTypes, targets)	-- todo
	-- body
end

local function getShiftedPos(obj)
	return obj.seat
end
-- 3-位置选择类型
-- 在前排有单位的情况下会移动到前排横排中央，在前排没有单位的情况下会移动到后排横排中央
-- front 是否前排
-- recursion 是否是再搜索的状态
function process.row(front, recursion, enemyForce, targets)
	local force = enemyForce and 3-env.force or env.force -- 与CsvObject:force()重名，这里强制使用env

	local s, e = 1, forceNumber-- s 起始id, e 结束id

	if force ~= 1 then
		s, e = s + forceNumber, e + forceNumber -- 根据force进行修正
	end

	if front then
		e = e - rowNumber 		-- 前排修正(id 范围缩小至 1-3)
	else
		s = s + rowNumber 		-- 后排修正(id 范围缩小至 4-6)
	end
	local ret = arraytools.filter(targets, function(_, o)
		return s <= getShiftedPos(o) and getShiftedPos(o) <= e
	end)
	local filteredRetNum = table.length(filtercantBeSelect(self,ret,env))
	if filteredRetNum == 0 and recursion then
		ret = process.row(not front, false, enemyForce, targets)
	end

	return ret
end

process.rowback = functools.partial(process.row, false, true, false)
process.rowfront = functools.partial(process.row, true, true, false)
process.rowbackor = functools.partial(process.row, false, false, false)
process.rowfrontor = functools.partial(process.row, true, false, false)


-- 移动到指定的竖排，近中心的优先
function process.column(targets)
	local force = env.force -- 与CsvObject:force()重名，这里强制使用env
	local s = 1
	if force ~= 1 then
		s = s + forceNumber
	end
	local seat = selectObj.seat - 1
	if seat >= forceNumber then
		seat = seat - forceNumber
	end
	if seat >= rowNumber then
		seat = seat - rowNumber
	end
	-- id为0,1,2就是横排的1,2,3位
	s = s + seat
	return arraytools.filter(targets, function(_, o)
		return getShiftedPos(o) == s or getShiftedPos(o)== s + rowNumber
	end)
end

local NeighbourXY = {{0, 1}, {1, 0}, {0, -1}, {-1, 0}}
local function idx2xy(idx, rowSize, rectSize)
	idx = (idx - 1) % rectSize
	return math.floor(idx / rowSize), idx % rowSize
end
local function xy2idx(x, y, rowSize, colSize)
	if x < 0 or x >= colSize then
		return nil
	end
	if y < 0 or y >= rowSize then
		return nil
	end
	return x * rowSize + y + 1
end

local pos = {
	left = {{4,5,6},{1,2,3}},
	right = {{7,8,9},{10,11,12}},
}
local posMap= {
	left = {
		[1] = {x=2, y=1},
		[2] = {x=2, y=2},
		[3] = {x=2, y=3},
		[4] = {x=1, y=1},
		[5] = {x=1, y=2},
		[6] = {x=1, y=3},
	},
	right = {
		[7] = {x=1, y=1},
		[8] = {x=1, y=2},
		[9] = {x=1, y=3},
		[10] = {x=2, y=1},
		[11] = {x=2, y=2},
		[12] = {x=2, y=3},
	},
}

-- 目标周围一格单位, 十字范围
function process.near(targets)
	local positionMap = selectObj.force == 1 and posMap.left or posMap.right
	local position = selectObj.force == 1 and pos.left or pos.right
	local selfIdx = positionMap[getShiftedPos(selectObj)]
	local idMap = {}
	idMap[position[selfIdx.x][selfIdx.y]] = true
	for _, xy in ipairs(NeighbourXY) do
		local x = xy[1] + selfIdx.x
		local y = xy[2] + selfIdx.y
		if (x>0 and x<=2) and (y>0 and y<=3) then
			idMap[position[x][y]] = true
		end
	end
	return arraytools.filter(targets, function(_, o)
		return idMap[getShiftedPos(o)]
	end)
end

--策划填写公式： input:enemyForce|nodead  process:curSelected|sputtering(0.5)
-- 溅射目标 rate:存储不同目标的受到的溅射伤害比例
function process.sputtering(rate,targets)
	for idx, target in ipairs(targets) do
		target:addExRecord(battle.ExRecordEvent.sputtering, {rate = rate})
	end
	return targets
end
--策划填写公式： input:enemyForce|nodead  process:curSelected|penetrate(0.5)
--穿透目标
function process.penetrate(rate, targets)
	for _, target in ipairs(targets) do
		target:addExRecord(battle.ExRecordEvent.penetrate, {rate = rate})
	end
	return targets
end

-- 通用从targets中选择位于 row, column 的目标
local function serachTargetsByRowColumn(targets, row, column, useOriginPos)
	local retT = {}	--保存最终筛选出来的目标集合
	local posIdInfoTb = {}	--目标阵营的位置信息
	local rowTb = {}	-- 存要找的行中的目标
	local colTb = {}	-- 存要找的列中的目标

	-- 先获目标单位的最新的行列信息
	for _, target in ipairs(targets) do
		local scene = target.scene
		posIdInfoTb[getShiftedPos(target)] = scene.placeIdInfoTb[getShiftedPos(target)]	-- todo 当用 useOriginPos 时,需要使用储存原始位置信息的表
	end

	-- pid 1,2,3  4,5,6
	if row and (row == 1 or row == 2) then	-- 1-前排， 2-后排
		itertools.each(posIdInfoTb, function(id, _)
			if posIdInfoTb[id]['row'..row] then
				rowTb[id] = true
			end
		end)
	end
	-- pid 1,4  2,5  3,6
	if column and (column == 1 or column ==2 or column == 3) then	-- 1, 2, 3 -列
		itertools.each(posIdInfoTb, function(id, _)
			if posIdInfoTb[id]['column'..column] then
				colTb[id] = true
			end
		end)
	end
	-- 选择行列目标
	local emptyRowTb = next(rowTb)
	local emptyColTb = next(colTb)
	if emptyRowTb or emptyColTb then	-- 不都是空的，表示有行或者列的选择
		for _, target in ipairs(targets) do
			local i = getShiftedPos(target)
			if (rowTb[i] and colTb[i]) or (rowTb[i] and not emptyColTb) or (not emptyRowTb and colTb[i]) then
				table.insert(retT, target)
			end
		end
	end
	return retT
end
-- 通用的row选择, 以 selectObj 为 行列值的来源, selectObj 未指定时,用 self
-- function process.rowNormal(targets)
-- 	local row, column
-- 	if selectObj then
-- 		row, _ = getRowAndColumn(selectObj)
-- 	else
-- 		row, _ = getRowAndColumn(self)
-- 	end
-- 	return serachTargetsByRowColumn(targets, row, column)
-- end

-- 目标所在行的目标
function process.targetRow(targets)
	local row, _ = getRowAndColumn(selectObj)
	row = math.max(1, math.min(row, 2))	-- 超出范围之外的默认就是参照物所在的那行
	return serachTargetsByRowColumn(targets, row, column)
end

-- 目标身前的目标, 以 selectObj 为 行列值的来源
function process.targetFront(targets)
	local row, column = getRowAndColumn(selectObj)
	row = math.max(1, math.min(-1 + row, 2))	-- 超出范围之外的默认就是参照物所在的那行
	return serachTargetsByRowColumn(targets, row, column)
end
--目标身后的目标
function process.targetBack(targets)
	local row, column = getRowAndColumn(selectObj)
	row = math.max(1, math.min(1 + row, 2))	-- 超出范围之外的默认就是参照物所在的那行
	return serachTargetsByRowColumn(targets, row, column)
end
--目标所在列
function process.targetColumn(targets)
	local _, column = getRowAndColumn(selectObj)
	return serachTargetsByRowColumn(targets, row, column)
end

-- 自身所自行的目标
function process.selfRow(targets)
	local row, _ = getRowAndColumn(self)
	row = math.max(1, math.min(row, 2))	-- 超出范围之外的默认就是参照物所在的那行
	return serachTargetsByRowColumn(targets, row, column)
end
-- 自身身前的目标
function process.selfFront(targets)
	local row, column = getRowAndColumn(self)
	row = math.max(1, math.min(-1 + row, 2))	-- 超出范围之外的默认就是参照物所在的那行
	return serachTargetsByRowColumn(targets, row, column)
end
-- 自身身后的目标
function process.selfBack(targets)
	local row, column = getRowAndColumn(self)
	row = math.max(1, math.min(1 + row, 2))	-- 超出范围之外的默认就是参照物所在的那行
	return serachTargetsByRowColumn(targets, row, column)
end
-- 自身所在列
function process.selfColumn(targets)
	local _, column = getRowAndColumn(self)
	return serachTargetsByRowColumn(targets, row, column)
end
-- 前排随机
function process.frontRowRandom(limit,targets)
	local targets2 = process.row(true, true, false, targets)
	return process.random(limit,targets2)
end
-- 后排随机
function process.backRowRandom(limit,targets)
	local targets2 = process.row(false, true, false, targets)
	return process.random(limit,targets2)
end

local function searchPriorTargets(self, targets, priorValFunc)
	if table.length(targets) == 0 then
		return targets
	end

	local tmpTargets, vals = {}, {}
	local selfVal = priorValFunc(self)

	for _, target in ipairs(targets) do
		local curVal = priorValFunc(target)
		if not tmpTargets[curVal] then
			tmpTargets[curVal] = {}
			if curVal ~= selfVal then
				table.insert(vals, curVal)
			end
		end
		table.insert(tmpTargets[curVal], target)
	end

	if tmpTargets[selfVal] then
		return tmpTargets[selfVal]
	else
		local val = vals[ymrand.random(1, table.length(vals))]
		return tmpTargets[val]
	end
end

-- 选取一列 与自己同列优先
function process.selfColumnPrior(targets)
	local function getPriorValue(target)
		local _, column = getRowAndColumn(target)
		return column
	end
    return searchPriorTargets(self, targets, getPriorValue)
end

function process.targetAnd(func1, args1, func2, args2, targets)
	local ret = {}
	local map = {}

	args1[#args1 + 1] = targets
	for _, target in ipairs(process[func1](table.unpack(args1))) do
		table.insert(ret, target)
		map[target.id] = true
	end

	args2[#args2 + 1] = targets
	for _, target in ipairs(process[func2](table.unpack(args2))) do
		if not map[target.id] then
			table.insert(ret, target)
			map[target.id] = true
		end
	end

	table.sort(ret, function(o1, o2)
		return o1.id < o2.id
	end)
	return ret
end

-- 4-条件选择类型
-- 拥有buffid的

-- 拥有buffGroupId的

-- 目标是xx属性类型的/目标是被自身属性克制的类型的？ 待定
-- target.attributeType

-- 5-特殊功能
-- 标记筛选出来的目标,一般是最后使用, 按照筛选出来的目标的id顺序递增, 基础数字为 10000
function process.paintFlagNum(targets)
	local sn = 10000
	for _, target in ipairs(targets) do
		sn = sn + 1
		target.paintFlagNum = sn
	end
	return targets
end

-- filtercantBeSelect 时过滤掉对应的buffgroup
-- 需要加在相关判断之前
function process.ignoreBuffGroup(ids, targets)
	env.ignoreBuffGroup = ids
	return targets
end



-- 选择上一过程段的目标(以后用到时再加)


-- todo:
-- 目前的选择目标设定中,有个不太好的地方，
-- 之前的写法, 选择目标是默认了带有阵营属性的, 这样会导致有些时候, 比如混乱状态攻击队友时, 需要转换阵营,
-- 但之前的逻辑都是按照这个目标刚开始的阵营来选择的, 所以这时候可能就会有问题了,
-- 那些填 敌方前排、敌方目标周围的之类的配置, 现在都需要一并跟着修改，这样后面如果出现类似的状态多了,可能会比较混乱

-- 所以考虑修改成 统一不带阵营的方式, 因为在初始时, 技能中会指定选择攻击敌方还是己方, 这样，相当于就已经把具体的阵营id确定好了,
-- 然后那个手动点击角色身体标进行攻击的主要目标, 在某些选择中将变为参照物的一种特殊情况,
-- 后面的选择逻辑, 就只需要在此基础上继续筛选就行

-- 因为这种选择，已经把那个默认的 caster 给去掉了, 所以后续的选择逻辑中, 就不存在 什么己方 敌方之分了,
-- 新的后续选择逻辑将变成: 在 场上的左右两方某阵营中, 选择 某行、列、某个id或和某个参照有xx位置关联/有xx关系的目标。
-- 无论是 己方前排 还是 敌方前排，还是混乱了后敌方前排变为己方前排， 处理的都是 从某个阵营中 选择 前排目标，只是阵营在最开始时作了改变而已
-- 这样选择逻辑就可以脱离 那个进行阵营选择的目标 而独立存在了, 这样也能够在 像是天气等非战斗单位类的模块中也能够比较简单的应用，
--


-- 若采用这种形式时, 因为选择中不再带有默认阵营属性的caster目标了, 此时需要在选择开始前先处理下阵营的选择, 先获得这个阵营值
-- 像是上面中了 混乱 的目标，阵营将先处理为目标自己的阵营， 然后在进行 行列xxx的 筛选

-- 新的选择方式, 将只会保留以下内容:
-- 	1)阵营: 0-全体,  1-阵营1,  2-阵营2
--			(需要加一个前置的阵营预处理部分,专门处理下面的情况和上面的混乱的情况)
--			注意: 阵营1和阵营2, 可能会根据角色在游戏中的阵营而出现变化,
--			比如: 游戏中玩家A控制的某个角色的技能配置为: 攻击敌方单体, 正常来说, 玩家是在左边的, 阵营是1, 此时敌方阵营就是2,
--			但在同步对战这种在场景内站位顺序产生左右反转的时候, 另一方玩家的客户端看到玩家A是在右边, 则A的阵营此时是2, A的敌方阵营就是1了。
--			所以, 这里的这个 阵营属性， 是根据 当前使用选择目标逻辑的角色来确定的
--		有些情况下, 阵营可能不是直接就能填出来的, 比如某些角色创建的一些天气效果, 天气中的配置可能不会带有明确的阵营属性
-- 		所以这时候, 就需要用 阵营预处理 函数进行阵营的转化 了

-- 2)参照物: 当前选择的目标 (在某些选择方式中是必须存在的, 比如某个目标 所在行/所在列/身前/身后/周围 的目标, 这个目标的嘲讽目标等等)
--			没有目标时将变成自身

-- 3)选择逻辑: xxxxxxx (选择逻辑仍然使用 process 中的写法形式, 管道式的写法)

-- 一些特殊选择的逻辑, 可能不需要上面的某个内容, 比如
--			自身 -- 这种就是设定参照物为自己即可, 选择逻辑中 self() 则表示参照物自身
--			某个id的角色-- 直接从全体中选择这个id的角色即可


-- 另外, 考虑把 input 和 process 的区分给去掉, 因为这两个实际上都是对目标进行选择, 只不过选择的内容详细不一样而已
-- input实际上就是 先从全体中进行选择出来的目标

-- {force=0, refObj= xxx, process="xxxx"} -- force不填时,就默认为全体

local newChooseProcess = {}
battleTarget.newChooseProcess = newChooseProcess

-- 获取阵营值 (阵营预处理函数)
function battleTarget.getForceVal(obj, friendOrEnemy)
	-- body
end


-- function process.backRowRandom(limit,targets)
-- 	local targets2 = process.row(false,targets)
-- 	return process.random(limit,targets2)
-- end

-- 所有process后加Exclude时代表
-- funcExclude(inputForce)
--[[
	ret = {}
	for obj in inputForce:
		if obj not in func(inputForce):
			obj insert to ret
	retrun ret
]]

local exportExcludeFunc = {
	"buffDiffer",
	"row"
}

for _,funcName in ipairs(exportExcludeFunc) do
	process[funcName.."Exclude"] = function(...)
		local n = select("#", ...)
		local targets = select(n, ...) -- the last arg in ...
		local ret = process[funcName](...)
		return arraytools.filter(targets, function(_, obj)
			for k,v in ipairs(ret) do
				if v.id == obj.id then
					return false
				end
			end
			return true
		end)
	end
end

