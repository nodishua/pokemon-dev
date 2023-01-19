
-- 随机取limit个
-- datas --> array
function battleEasy.randomGetByArray(datas,limit,judge,switch)
	-- error("deprecated")

	local ret = {}
	local count = table.length(datas)

	switch = switch or function(v)
		return v
	end

	judge = judge or function()
		return ymrand.random() > 0.5
	end

	for i=1,table.length(datas) do
		if (count <= limit) or judge(datas[i]) then
			limit = limit - 1
			table.insert(ret,switch(datas[i],(table.length(ret) + 1)))
		end
	end

	return ret
end

function battleEasy.groupReltaionInclude(t,v)
	for _,tb in ipairs(t) do
		if tb[v] then
			return true
		end
	end
	return false
end


function battleEasy.numEqual(num1,num2)
	return math.abs(num1 - num2) < 1e-5
end

function battleEasy.ifElse(pred, tv, fv)
	if pred then
		return tv
	end
	return fv
end

function battleEasy.getSkillTab(unitId)
	local unitCfg = csv.unit[unitId]
	local cardCfg = csv.cards[unitId]
	local ret = {}
	if not unitCfg and not cardCfg then
		errorInWindows("getSkillTab %d unitCfg or cardCfg exit nil",unitId)
	end

	if unitCfg then
		for _, skillId in ipairs(unitCfg.skillList) do
			ret[skillId] = 1
		end

		for _, skillId in ipairs(unitCfg.passiveSkillList) do
			ret[skillId] = 1
		end
	end

	if cardCfg then
		for _, skillId in ipairs(cardCfg.skillList) do
			ret[skillId] = 1
		end
	end

	return ret
end

-- @params ret {1,nil,2}
-- @params powerRet {0.2,0.4,0.4}
-- @return 1 or 2
function battleEasy.getItemInPowerMap(ret,powerRet)
	local sum = 0
	for i,v in pairs(powerRet) do
		if v and ret[i] then sum = sum + v end
	end

	local num = ymrand.random()
	local radio = 0
	for i=1,table.length(powerRet) do
		if ret[i] then
			radio = powerRet[i] / sum
			if radio >= num then
				return ret[i]
			else
				num = num - radio
			end
		end
	end
end

function battleEasy.isSameSkillType(typ1,typ2)
	if typ1 == battle.SkillFormulaType.fix then return true end
	if typ2 == battle.SkillFormulaType.fix then return true end
	return typ1 == typ2
end

function battleEasy.isCompleteLeave(obj)
	if obj:checkOverlaySpecBuffExit("leave") then
		return true
	end
	if obj:checkOverlaySpecBuffExit("depart") then
		for _, data in obj:ipairsOverlaySpecBuffTo("depart") do
			if data.leaveSwitch then return true end
		end
	end
	return false
end

function battleEasy.getUnifyBuffArgs(type, data, exArgs, env)
	local args = {
		buffValueFormulaEnv = env
	}
	if type == "skill_process" then
		args.buffValueFormula = data.buffValue1[exArgs.index]
	elseif type == "buff" then
		args.value = data.value
		args.buffValueFormula = data.buffValueFormula
		args.skillCfg = data.skillCfg
	end
	for k, v in pairs(exArgs) do
		args[k] = v
	end
	return args
end

function battleEasy.alterDmgRecordVals(attacker, target)
	local ret = {}

	local fillAlterRet = function(typ, alterData, priority)
		ret[typ] = ret[typ] or {}
		for processName, processValue in pairs(alterData) do
			ret[typ][processName] = ret[typ][processName] or {}
			table.insert(ret[typ][processName], {
				data = processValue,
				priority = priority
			})
		end
	end

	for _, data in attacker:ipairsOverlaySpecBuff("alterDmgRecordVal") do
		if data.assignObject == 1 or data.assignObject == 3 then
			fillAlterRet(data.typ, data.alterDmgRecordData, data.priority)
		end
	end
	for _, data in target:ipairsOverlaySpecBuff("alterDmgRecordVal") do
		if data.assignObject == 2 or data.assignObject == 3 then
			fillAlterRet(data.typ, data.alterDmgRecordData, data.priority)
		end
	end

	-- 按照priority排个序
	for _, typeTb in pairs(ret) do
		for _, processTb in pairs(typeTb) do
			table.sort(processTb, function(a, b)
				return a.priority < b.priority
			end)
		end
	end

	return ret[1] or {}, ret[2] or {}, ret[3] or {}
end

function battleEasy.getRoundTriggerId(cfgId)
	for k, v in pairs(gExtraRoundTrigger) do
		if v.cfgIds[cfgId] then
			return k
		end
	end
end

function battleEasy.resetGateAttackRecord(holder, data)
	local gate = holder.scene.play
	table.insert(gate.roundLeftHeros, data)
	for k,v in ipairs(gate.roundHasAttackedHeros) do
		if v.id == holder.id then
			table.remove(gate.roundHasAttackedHeros,k)
			table.remove(gate.hasAttackedSign,k)
			break
		end
	end
end