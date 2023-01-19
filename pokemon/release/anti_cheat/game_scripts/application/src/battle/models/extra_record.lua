--
-- 记录场景下的额外数据
-- battle.ExRecordEvent
--


local BattleExRecord = class("BattleExRecord")
globals.BattleExRecord = BattleExRecord

--battle.MainSkillType --> battle.ExRecordEvent
local RecordEventMap = {
	[battle.MainSkillType.NormalSkill] = battle.ExRecordEvent.spellNormalSkill,
	[battle.MainSkillType.SmallSkill] = battle.ExRecordEvent.spellSmallSkill,
    [battle.MainSkillType.BigSkill] = battle.ExRecordEvent.spellBigSkill,
    [battle.MainSkillType.PassiveSkill] = 0,
}

local function checkLimit(eventName, ...)
	local data = table.getWithKeys(self.exRecordTbl[eventName], {...})
	if not data then return true end
	return	data.val < data.limit
end

-- 技能施放记录条件判断
local function checkSkillRecordConditions(diff, objId)
    local canRecord = true
    if not diff or diff<0 or not objId then
        return false
    end
    return canRecord
end

local function init_table(record, ...)
	local keys = {...}
	return table.getWithKeys(record, keys) or {}
end

local function init_number(record, ...)
	local keys = {...}
	return table.getWithKeys(record, keys) or 0
end

local function check_true() return true end
local function check_false() return false end

local EventFuncMap = {
	default = {
		init = init_number,
		check = check_true,
		process = function(t, val)
			if type(val) == "number" then
				return t + val
			end
			return val
		end,
	},
	limit = {
		init = init_table,
		check = function(t)
			if t.val then return t.val < t.limit end
			return true
		end,
		process = function(t, val)
			t.val = math.min(t.val + val, t.limit)
			return t
		end,
	},
	set = {
		init = init_table,
		check = check_true,
		process = function(t, val) return val end,
	},
	insert = {
		init = init_table,
		check = check_true,
		process = function(t, val)
			table.insert(t, val)
			return t
		end
	},
	addNumber = {
		init = init_number,
		check = check_true,
		process = function(t, val)
			return t + val
		end
	},
	skillType = {
		init = init_number,
		check = function(t, val, objId)
			local canRecord = true
			if not val or val < 0 or not objId then
				return false
			end
			return canRecord
		end,
		process = function(t, val)
			return t + val
		end
	},
    momentBuffDamage = {
        init = init_table,
        check = check_true,
        process = function(t, val)
			t[1] = val
            t[2] = t[2] and t[2] + val or val
            return t
		end
    },
}

local EventTypeMap = {
    [battle.ExRecordEvent.lockHpDamage] = EventFuncMap.set,
    [battle.ExRecordEvent.lockHpTriggerTime] = EventFuncMap.set,
    [battle.ExRecordEvent.transferState] = EventFuncMap.set,
    [battle.ExRecordEvent.copyState] = EventFuncMap.set,
    [battle.ExRecordEvent.dispelSuccess] = EventFuncMap.set,
    [battle.ExRecordEvent.totalHp] = EventFuncMap.set,
    [battle.ExRecordEvent.lockHpTriggerState] = EventFuncMap.set,
    [battle.ExRecordEvent.keepHpUnChangedTriggerState] = EventFuncMap.set,

	[battle.ExRecordEvent.copyOrTransferBuff] = EventFuncMap.insert,
    [battle.ExRecordEvent.skillEffectLimit] = EventFuncMap.insert,

	[battle.ExRecordEvent.spellNormalSkill] = EventFuncMap.skillType,
    [battle.ExRecordEvent.spellSmallSkill] = EventFuncMap.skillType,
    [battle.ExRecordEvent.spellBigSkill] = EventFuncMap.skillType,
	[battle.ExRecordEvent.spellSkillTotal] = EventFuncMap.skillType,
	[battle.ExRecordEvent.momentBuffDamage] = EventFuncMap.momentBuffDamage,
}

local refreshFunc = {
	[battle.TimeIntervalType.wave] = {
		battle.ExRecordEvent.skillEffectLimit
	}
}

local function getEventName(eventName)
	return RecordEventMap[eventName] or eventName
end

function BattleExRecord:ctor()
    self.exRecordTbl = {}  --    { [eventName]={ [key]={}, ... }, ... }
    self.eventName2Key = {} -- {[eventName] = key}
end

function BattleExRecord:_getRecord(eventName)
	if not eventName then return {} end

	if not self.exRecordTbl[eventName] then
		self.exRecordTbl[eventName] = {}
	end

	return self.exRecordTbl[eventName]
end

function BattleExRecord:getKeyByEventName(eventName)
	eventName = getEventName(eventName)
    self.eventName2Key[eventName] = self.eventName2Key[eventName] or 0
    self.eventName2Key[eventName] = self.eventName2Key[eventName] + 1
    return self.eventName2Key[eventName]
end

function BattleExRecord:addExRecord(eventName, data, ...)
    local key1 = ...
    if not eventName or not key1 then
        return
    end

	eventName = getEventName(eventName)

	local center = EventTypeMap[eventName]
	if not center then
		center = EventFuncMap.default
	end

	local t = center.init(self:_getRecord(eventName), ...)
    if not center.check(t, data, key1) then
        return
    end

	t = center.process(t, data)

	local keys = {...}
	table.setWithKeys(self:_getRecord(eventName), keys, t)

    -- if updateFunc[eventName] then
    --     updateFunc[eventName](self, eventName, data, ... )
    -- else
    --     if type(data) == "number"  then
    --         local oldData = table.get(self.exRecordTbl[eventName], ... ) or 0
    --         setEventValue(self, eventName,data + oldData , ... )
    --     else
    --         setEventValue(self, eventName,data, ... )
    --     end
    -- end
end

function BattleExRecord:getEvent(eventName)
	eventName = getEventName(eventName)
    return self:_getRecord(eventName)
end

function BattleExRecord:getEventByKey(eventName, ...)
    if not eventName then
        return
    end

	eventName = getEventName(eventName)
	-- 可以是nil
	if self.exRecordTbl[eventName] then
		return table.get(self.exRecordTbl[eventName], ...)
	end
end

function BattleExRecord:cleanEventByKey(eventName, key)
	eventName = getEventName(eventName)
    if not eventName or not self.exRecordTbl[eventName] then
        return
    end

	if key then
		local t = self:_getRecord(eventName)
		t[key] = nil
	else
		self.exRecordTbl[eventName] = nil
	end
end

function BattleExRecord:refreshEventRecord(timeType)
	if not refreshFunc[timeType] then return end
	for _, event in ipairs(refreshFunc[timeType]) do
		self:cleanEventByKey(event)
	end
end
