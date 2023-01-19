local _unpack = unpack
local _msgpack = require '3rd.msgpack'
local msgpack = _msgpack.pack

globals.__TestEasy = {}

-- 属性默认显示的值
local DefaultAttr = {
	star = 5,
	classify = 0,
	level = 1,
	hp = 100000,
	mp1 = 1000,
	mp2 = 1,
	hpRecover = 1,
	mp1Recover = 1,
	mp2Recover = 1,
	damage = 10000,
	specialDamage = 10000,
	defence = 3000,
	specialDefence = 3000,
	defenceIgnore = 1,
	specialDefenceIgnore = 1,
	speed = 14,
	strike = 1,
	strikeDamage = 15000,
	strikeResistance = 1,
	block = 1,
	breakBlock = 1,
	blockPower = 1,
	dodge = 1,
	hit = 10000,
	damageAdd = 1,
	damageSub = 1,
	ultimateAdd = 0,
	ultimateSub = 0,
	damageDeepen = 1,
	damageReduce = 1,
	suckBlood = 0,
	rebound = 0,
	cure = 1,
	natureRestraint = 1,
	gatePer = 1,
	immuneGate = 1,
	skills = {},
	passive_skills = {},
	fightPoint = 0,
	controlPer = 0,
}

__TestEasy.addFuncListener = function(func,obj,listenerName)
	if obj[func] and __TestProtocol[listenerName] then
		local listenFunc = __TestDefine.MonitorFunc[listenerName] or obj[func]
		obj[func] = function(...)
			if not __TestDefine.Monitor then
				return listenFunc(...)
			end
			local _self = {__func = listenFunc}
			__TestProtocol[listenerName](_self,__TestDefine.CallState.enter,...)
			local _returnArgs = {listenFunc(...)}
			__TestProtocol[listenerName](_self,__TestDefine.CallState.exit,(({...})[1]),_unpack(_returnArgs))
			__TestEasy.excuteCHProtocol(listenerName, _self, _returnArgs, ...)
			return _unpack(_returnArgs)
		end
		__TestDefine.MonitorFunc[listenerName] = listenFunc
	end
end

__TestEasy.log = function(...)
	-- local args = {...}
	-- local _str = args[1]

	-- if #args > 1 then
	-- 	if _str and string.match(_str,"%%s") then
	-- 		local index = 1
	-- 		_str = string.gsub(_str,"%%s",function(char)
	-- 			index = index + 1
	-- 			return tostring(args[index])
	-- 		end)
	-- 		--_str = string.format(_str,unpack(args,2))
	-- 	else
	-- 		for i=2,#args do
	-- 			_str = _str .. "  " .. tostring(args[i])
	-- 		end
	-- 	end
	-- end
	-- printDebug("\n\t" .. _str)
end

-- local recordData_Id = 0
-- __TestEasy.send = function(cmd,data)
-- 	-- if not __TestDefine.NetSwitch then return end
-- 	if not data then
-- 		print("send",cmd,"data is nil")
-- 		return
-- 	end

-- 	local _data = data
-- 	if cmd == __TestDefine.ReqProtocol.Object then
-- 		_data = __TestEasy.toObject(data)
-- 	end
-- 	recordData_Id = recordData_Id + 1
-- 	-- print("Send: CS_DataRecord num:",recordData_Id)
-- 	custom_plugin.send(cmd,_data)
-- end

__TestEasy.toObject = function(obj)
	return {
		hp = obj:hp(),
		hpMax = obj:hpMax(),
		mp = obj:mp1(),
		mpMax = obj:mp1Max(),
		name = obj.unitCfg.name,
		id = obj.id,
		seat = obj.seat,
		unitId = obj.unitID,
		firstBigSkillRound = nil,
		firstKill = nil,
		skillTime = {}
	}
end

__TestEasy.toBuff = function(buff)
	return {
		cfgId = buff.cfgId,
		casterId = buff.caster and buff.caster.id or 999,
		holderId = buff.holder.id,
		lifeRound = buff.lifeRound,
		easyEffectFunc = buff.csvCfg.easyEffectFunc,
		value = buff.isNumberType and buff.buffValue or tostring(buff.buffValue),
		from = "",
		state = -1,
	}
end

__TestEasy.toValueType = function(values)
	local str
	for _,key in pairs(battle.ValueType) do
		local value = tonumber(values:get(key))
		if str then
			str = str .. "|" .. value
		else
			str = value
		end
	end
	return str
end

-- 推入策划的命令
-- @params envStr [string] [like "BuffModel/init"]
-- @params tb	  [command]
-- @example
--[[
	__TestEasy.pushCHProtocol("BuffModel/init",{
		type = "counter", -- 计数
		condition = "buffID == 11111",
		output = {"Buff初始化次数",0}
	})
]]
__TestEasy.pushCHProtocol = function(envStr, tb)
	__TestDefine.chProtocol[envStr].protocol = __TestDefine.chProtocol[envStr].protocol or {}
	table.insert(__TestDefine.chProtocol[envStr].protocol, tb)
end

-- 清理策划的命令
__TestEasy.clearCHProtocol = function(envStr, tb)
	__TestDefine.chProtocol[envStr].protocol = {}
end

local statisticTypes = {
	["counter"] = function(ret)
		if not ret then return 0 end
		return ret + 1
	end,
	["sum"] = function(ret, val)
		if not ret then return 0 end
		if type(val) == "table" then
			return "val_sum_with_table"
		end
		return ret + val
	end,
	["array"] = function(ret, val)
		if not ret then return {} end
		if type(val) == "table" then
			table.insert(ret, dumps(val))
		else
			table.insert(ret, val)
		end
		return ret
	end,
}
-- 执行策划的命令
__TestEasy.excuteCHProtocol = function(key, ...)
	local data = __TestDefine.chProtocol[key]

	if data and data.changeArgs then
		data.changeArgs(...)
	end

	if data and data.protocol and table.length(data.protocol) > 0 then
		local env = data.makeEnv(...)
		local extraData = __TestDefine.historyBattleInfo.extraData or {}
		local value

		for k,v in ipairs(data.protocol) do
			local call = statisticTypes[v.type]
			value = extraData[v.output[1]]
			if value == nil then value = call() end
			if eval.doFormula(v.condition, env) then
				if v.output[2] then
					value = call(value, eval.doFormula(v.output[2], env))
				else
					value = call(value)
				end

			end
			extraData[v.output[1]] = value
		end

		__TestDefine.historyBattleInfo.extraData = extraData
	end
end

-- 服务器自动测试 获取战报
__TestEasy.gainBattleRecord = function(data)
	-- local data = {  -- 手动填充数据
	-- 	gateType = 2,
	-- 	left = {0, 0, 0, 11, 0, 0},
	-- 	right = {0, 0, 12, 0, 0, 0}
	-- }
	-- normal 6v6; 跨服竞技场 12v12; 单挑石英 1v1; 跨服石英 3v3
	local gate
	local normalGateType = game.GATE_TYPE.test
	if data.sceneID >= 1000 then
		gate = require "app.views.city.test.gate.pve_gate"
		normalGateType = csv.scene_conf[data.sceneID].gateType
	elseif data.sceneID == game.GATE_TYPE.crossArena then
		gate = require "app.views.city.test.gate.cross_arena_gate"
	else
		gate = require "app.views.city.test.gate.normal_gate"
	end

	local gameEnvData = {
		sceneID = data.sceneID,
		randSeed = math.random(1, 1000000),
		roleLevel = 1,
		talents = {{},{}},
		fightgoVal = {0,0},
		gateFirst = true,
		gateType = normalGateType,
		-- 战斗选择类型默认为 1: 常规  2: 全手动
		moduleType = 1,
	}

	data.DefaultAttr = DefaultAttr
	local roleOutTab,gateType = gate:getFightRoleData(data)
	if #roleOutTab == 0 then return end
	gameEnvData.gateType = gateType or gameEnvData.gateType

	gameEnvData.roleOut = roleOutTab[1]
	gameEnvData.roleOut2 = roleOutTab[1]
	return msgpack(gameEnvData)
end

return __TestEasy