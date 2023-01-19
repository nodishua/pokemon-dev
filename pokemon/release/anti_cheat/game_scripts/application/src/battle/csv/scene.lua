--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2019 TianJi Information Technology Inc.
--
-- SceneModel导出Csv公式用
--

local CsvScenetExport = {
	getForceNum = 0,
}

local CsvScene = battleCsv.newCsvCls("CsvScene")
battleCsv.CsvScene = CsvScene


-- 不包括假死单位
local function filterByForce(scene, force, f)
	for _, obj in scene:getHerosMap(force):order_pairs() do
		if not obj:isAlreadyDead() then
			f(obj)
		end
	end
end

-- 包括假死单位
local function filterByForceNotRealDead(scene, force, f)
	for _, obj in scene:getHerosMap(force):order_pairs() do
		if not obj:isRealDeath() then
			f(obj)
		end
	end
end

-- 获取单位在攻击队列中的排序id,没有对多次攻击进行处理,多次攻击只返回最先出手的1次
-- @comment getBhpMax(1,1) = 获取1阵营中基础生命上限最大的单位
-- @comment getAhpMax(1,1) = 获取1阵营中buff生命上限最大的单位
-- @comment gethpMax(1,1) = 获取1阵营中最终生命上限最大的单位
-- @param seat int 单位id(单位必须存在)
-- @param force int 阵营
-- @return 获取单位在攻击队列中的排序id,默认玩家阵营
function CsvScene:getObjInAttackerArrayId(seat,force)
    local attackerArray = self.model.play.attackerArray -- 未出手的攻击者队列
    local roundHasAttackedHistory = self.model.play.roundHasAttackedHistory
	local startId = 0
	local _obj = self.model:getObjectBySeat(seat)
	force = force or _obj.force

	for speedId, obj in ipairs(roundHasAttackedHistory) do
		if obj.id == _obj.id then
            return speedId
        elseif obj.force == force then
            startId = startId + 1
		end
    end

    for speedId, obj in ipairs(attackerArray) do
		if obj.id == _obj.id and obj.force == force then
            return startId + speedId
        end
    end
end

-- 获取当前场景类型
-- @link app\defines\game_defines.lua game.GATE_TYPE
-- @link battle\battle_defines.lua battle.BuffTriggerPoint
-- @link battle\battle_defines.lua battle.BuffExtraTargetType
function CsvScene:getGateType()
    return self.model.gateType
end

-- 获取额外战斗回合模式
-- @link battle\battle_defines.lua battle.ExtraBattleRoundMode
-- @return 额外回合模式 具体battle_define下定义
function CsvScene:extraBattleRoundMode()
    return self.model:getExtraBattleRoundMode()
end

-- 单边阵容中自然属性的种类数量
-- @param force int 阵营
-- @param nature1Switch bool 自然属性1
-- @param nature2Switch bool 自然属性2
-- @return 单边阵容中自然属性的种类数量
function CsvScene:countNatureTypeCount(force,nature1Switch,nature2Switch)
    local count = 0
    local recordMap = {}

    local nature1 = nature1Switch and 1 or nil
    local nature2 = nature2Switch and 2 or nil

    local recordFunc = function(natureId,obj)
        if natureId then
            local nature = obj:getNatureType(natureId)
            if nature and not recordMap[nature] then
                recordMap[nature] = true
                count = count + 1
            end
        end
    end

    filterByForce(self.model, force, function(obj)
        recordFunc(nature1,obj)
        recordFunc(nature2,obj)
    end)
    return count
end

-- 统计阵营中携带有某个buff或者buff组的目标人头数
-- @param force int 阵营
-- @param buffCfgIDs table buff表id组
-- @param buffGroupIDs table group组
-- @return 统计阵营中携带有某个buff或者buff组的目标人头数
function CsvScene:countObjByBuff(force, buffCfgIDs, buffGroupIDs)
	local hashTb1 = {}
	local hashTb2 = {}
	if buffCfgIDs then
		if type(buffCfgIDs) ~= "table" then
			hashTb1[buffCfgIDs] = true
		else
			hashTb1 = arraytools.hash(buffCfgIDs)
		end
	end
	if buffGroupIDs then
		if type(buffGroupIDs) ~= "table" then
			hashTb2[buffGroupIDs] = true
		else
			hashTb2 = arraytools.hash(buffGroupIDs)
		end
	end

	local count = 0
	filterByForce(self.model, force, function(obj)
		-- 不能被攻击的排除掉
		-- if not obj:cantBeAttack() then
		-- 	local hasBuff = itertools.include(obj:iterBuffs(), function(buff)
		-- 		return hashTb1[buff.cfgId] or hashTb2[buff:group()]
		-- 	end)
		-- 	if hasBuff then
		-- 		count = count + 1
		-- 	end
		-- end
		local hasBuff = itertools.include(obj:iterBuffs(), function(buff)
			return hashTb1[buff.cfgId] or hashTb2[buff:group()]
		end)
		if hasBuff then
			count = count + 1
		end
	end)
	return count
end

-- 统计阵营中自然属性的目标人头数
-- @param force int 阵营
-- @param natureIdx int 自然属性类型id
-- @param nature int 具体自然属性id
-- @return 统计阵营中自然属性的目标人头数
function CsvScene:countObjByNature(force, natureIdx, nature)
	local count = 0
	filterByForce(self.model, force, function(obj)
		if obj:getNatureType(natureIdx or 1) == nature then
			count = count + 1
		end
	end)
	return count
end

-- 统计阵营中存在该自然属性的目标人头数
-- @param force int 阵营
-- @param nature int 具体自然属性id(不论第一或第二)
-- @return 统计阵营中存在该自然属性的目标人头数
function CsvScene:countObjByNatureExit(force, nature)
	local count = 0
	filterByForce(self.model, force, function(obj)
		if obj:getNatureType(1) == nature or obj:getNatureType(2) == nature then
			count = count + 1
		end
	end)
	return count
end


-- 统计阵营中人数
-- @param force int 阵营
-- @return 阵营中人数
function CsvScene:countForceNum(force)
	return self.model:getForceNum(force)
end

-- 统计阵营中人数
-- @param force int 阵营
-- @param ... array 阵营过滤题条件
-- @return 阵营中人数
function CsvScene:countForceFilterNum(force, csvObj, ...)
	local tars = self.model:getFilterObjects(force, csvObj and {fromObj = csvObj.model}, ...)
	return table.length(tars)
end

-- 统计阵营中最多的自然属性,只计算精灵的第一属性
-- @param force int 阵营
-- @return 统计阵营中最多的自然属性,只计算精灵的第一属性
function CsvScene:getMaxNatureInForce(force)
    local data = {nature = -1,count = 0}
	local countArray = {}

	filterByForce(self.model, force, function(obj)
        local nature = obj:getNatureType(1)
        countArray[nature] = countArray[nature] or 0
	    countArray[nature] = countArray[nature] + 1
	    if countArray[nature] > data.count or (countArray[nature] == data.count and nature > data.nature) then
	        data.count = countArray[nature]
	        data.nature = nature
        end
    end)

    return data.nature
end

-- 统计阵营中相关battleFlag的目标人头数
-- @param force int 阵营
-- @param flag int battleFlag
-- @return 统计阵营中最多的自然属性,只计算精灵的第一属性
function CsvScene:countObjByFlag(force, flag)
	local count = 0
	filterByForce(self.model, force, function(obj)
		if obj.battleFlag[flag] then
			count = count + 1
		end
	end)
	return count
end

-- 对阵营中某些buff组的buff.Overlay进行求和
-- @comment sumBuffOverlayByGroupInForce(1,11,22,33)
-- @param force int 阵营
-- @param ... int buffIDs 类11,22,33
-- @return 对阵营中某些buff组的buff.Overlay进行求和
function CsvScene:sumBuffOverlayByGroupInForce(force, ...)
	local sum = 0
	local buffIDs = {...}
	filterByForce(self.model, force, function(obj)
		for _, id in ipairs(buffIDs) do
			sum = sum + obj:getBuffGroupArgSum("overlayCount", id)
		end
	end)
	return sum
end

-- 统计阵营所有单位当前血量和
-- @param force int 阵营
-- @return 统计阵营所有单位当前血量和
function CsvScene:countHPSumByForce(force)
	local sum = 0
	filterByForce(self.model, force, function(obj)
		sum = sum + obj:hp()
	end)
	return sum
end

-- 统计阵营所有单位最大血量和
-- @param force int 阵营
-- @return 统计阵营所有单位最大血量和
function CsvScene:countHPMaxSumByForce(force)
	local sum = 0
	filterByForce(self.model, force, function(obj)
		sum = sum + obj:hpMax()
	end)
	return sum
end

-- 获取当前大回合
-- @return 当前大回合
function CsvScene:getNowRound()
	return self.model.play.curRound
end

-- 获取当前战斗回合
-- @return 获取当前战斗回合
function CsvScene:getNowBattleRound()
	return self.model.play.curBattleRound
end

-- 特殊个体是否存在 例如 全体护盾的对象
-- @param force int 阵营
-- @param objId int 13:全体护盾
-- @return true or false
function CsvScene:specialObjExit(force,objId)
    if self.model.forceRecordObject[force] then
        local obj = self.model.forceRecordObject[force][objId]
        if obj and not obj:isDeath() then
            return true
        end
    end
    return false
end

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
local pos = {
	left = {{4,5,6},{1,2,3}},
	right = {{7,8,9},{10,11,12}},
}

local NeighbourXY = {{0, 1}, {1, 0}, {0, -1}, {-1, 0}}

-- 获取目标的周围单位数量
-- @param selectObj object 单位
-- @return 获取目标的周围单位数量
function CsvScene:getObjNearCount(selectObj)
    local selectObj = selectObj.model
    local targets = self.model:getHerosMap(selectObj.force)
    local positionMap = selectObj.force == 1 and posMap.left or posMap.right
	local position = selectObj.force == 1 and pos.left or pos.right
	local selfIdx = positionMap[selectObj.seat]
	local seatMap = {}
	for _, xy in ipairs(NeighbourXY) do
		local x = xy[1] + selfIdx.x
		local y = xy[2] + selfIdx.y
		if (x>0 and x<=2) and (y>0 and y<=3) then
			seatMap[position[x][y]] = true
		end
	end
    local count = 0
	filterByForce(self.model, selectObj.force, function(obj)
		if seatMap[obj.seat] then
			count = count + 1
		end
	end)
	return count
end

-- 获取含有不定个自然属性的单位属性
-- @comment getNatureCount(1,1,2)
-- @param force int 阵营
-- @param ... int 自然属性类型 1,2
-- @return 获取含有不定个自然属性的单位属性
function CsvScene:getNatureCount(force,...)
    local calNatureTypeTab = {...}
	local natures = {}
	local count = 0
	filterByForceNotRealDead(self.model, force, function(obj)
        local typ
        for id,beCollect in ipairs(calNatureTypeTab) do
            if beCollect then
                typ = obj:getNatureType(id)
                if not natures[typ] then
                    count = count + 1
                    natures[typ] = true
                end
            end
        end
	end)
	return count
end

-- 获取对应位置上单位指定类型技能的释放次数
-- @comment getSpellCountBySeatAndType(1, 0)
-- @param seat int 座位
-- @param skillType2 int 技能类型2
-- @return 对应位置上单位指定类型技能的释放次数
function CsvScene:getSpellCountBySeatAndType(seat, skillType2)
	local obj = self.model:getObjectBySeat(seat)
	local key = obj and obj.id
	return self.model.extraRecord:getEventByKey(skillType2, key) or 0
end

-- 执行玩法公式
-- @comment getNatureCount(1,1,2)
-- @param func_name string 方法名
-- @param ... args 方法参数
function CsvScene:excutePlayCsv(func_name,...)
	local gate = self.model.play
	local func = gate:excutePlayCsv(func_name)
	if not func then return end
	return func(...)
end

-- 获取当前回合出手单位的排序信息
-- @param paramName 字段名 (buffCfgId, reset, atOnce)
-- @return 对应字段 or nil
function CsvScene:getNowRoundInfo(paramName)
	local data = self.model.play.curHeroRoundInfo
	return data and data[paramName]
end

-- 获取公式单位敌对阵营
-- @param csvObj 公式单位
-- @return 敌对阵营
function CsvScene:getEnemyForce(csvObj)
	return csvObj:force() == 1 and 2 or 1
end

-- 获取当前额外攻击模式 (5节点到下一个5节点之间是同一个值)
-- 和CsvObject:getExAttackMode相同
-- @return 默认返回0
function CsvScene:getExtraRoundMode()
	return self.model.extraRoundMode or 0
end

-- 获取process运算结果
-- @param input 目标 {方法名,参数,参数,...} 例 front(前排)
-- @param output 输出 {方法名,参数,参数,...} 例 allWithBuff(所有单位存在该buff)
-- @return 运算结果
function CsvScene:countObjBy(force, fromObj, inputs, output)
	-- local keys = {...}
	-- local output = keys[table.length(keys)]

	local inputMap = {
		-- 前排
		front = function(obj)
			return (obj.seat >= 1 and obj.seat <= 3) or (obj.seat >= 7 and obj.seat <= 9)
		end,
		back = function(obj)
			return (obj.seat >= 4 and obj.seat <= 6) or (obj.seat >= 10 and obj.seat <= 12)
		end,
		excludeRealDead = function(obj)  -- 包括假死
			return not obj:isRealDeath()
		end,
		filterLevevl1 = function(obj)
			if self.model:getFilterObject(obj.id, {fromObj = fromObj and fromObj.model}, battle.FilterObjectType.excludeObjLevel1) then
				return true
			end
			return false
		end
	}

	local outputMap = {
		-- 所有前置单位都需要有这个buff
		allWithBuff = function(obj, data)
			return (itertools.include(obj:iterBuffs(), function(buff)
				return buff.cfgId == data[2]
			end) and 1 or "returnZero")
		end,
	}

	local count = 0
	for _, obj in self.model:getHerosMap(force):order_pairs() do
		local result = true
		for _, inputKey in ipairs(inputs) do
			result = result and inputMap[inputKey](obj)
		end
		if not inputMap["excludeRealDead"] then result = (not obj:isAlreadyDead()) and result end
		if result then
			local switch = outputMap[output[1]] and outputMap[output[1]](obj, output) or 1
			-- 返回 returnZero 则直接返回0
			-- 返回 return 则返回当前值
			-- 否则 count 按switch结果增加
			if switch == "returnZero" then return 0
			elseif switch == "return" then return count
			else
				count = count + switch
			end
		end
	end
	return count
end

local conditionFunc = {
    [1] = function(obj,cmp,value) --最大值
        cmp = cmp or value - 1
        if value > cmp then
            return true
        end
        return false
    end,
    [2] = function(obj,cmp,value) --最小值
        cmp = cmp or value + 1
        if value < cmp then
            return true
        end
        return false
    end,
}

local getAttrObjectFuncByCondi = function(attr,from)
    return function(self,force,...)
        local value
        local funcTab = {}
        for _,v in ipairs({...}) do
            funcTab[table.length(funcTab) + 1] = conditionFunc[v]
        end
--        for _force=1,2 do
--            if _force == force then
--            end
--        end
        for _,obj in self.model:getHerosMap(force):order_pairs() do
            local temp = obj.attrs[from][attr]
            for i,f in ipairs(funcTab) do
                if not f(obj,value,temp) then break end
                if i == table.length(funcTab) then value = temp end
            end
        end
        return value
    end
end

for attr, _ in pairs(ObjectAttrs.AttrsTable) do
    CsvScene['getB'..attr] = getAttrObjectFuncByCondi(attr,"base")
    CsvScene['getA'..attr] = getAttrObjectFuncByCondi(attr,"buff")
    CsvScene["get"..attr] = getAttrObjectFuncByCondi(attr,"final")
end

battleCsv.exportToCsvCls(CsvScene, CsvScenetExport)
