--管理Buff逻辑中全局性的部分

globals.BuffGlobalModel = class("BuffGlobalModel")

local BuffLimitType = {
	object = 1,
	holderForce = 2,
}

function BuffGlobalModel:ctor()
	self.triggerType3Record = {{},{}} -- key:force-cfgID value:{limit,time}
	self.damageLinkRecord = {} -- force - objid -cfgID
	self.buffLinkRecord = {} --key:src * 100 + dst value:{fixValue,groups,cfgID}
	self.buffTriggerTypeRecord = {} -- [1] = {'lockHp' = 1,'reborn' = 2}

	self.triggerLimitRecordTb = {}
	for k,v in pairs(BuffLimitType) do
		self.triggerLimitRecordTb[v] = {}
	end
	self.cfgIdToLimitType = {} -- 映射表
	self.effectToBuffs = {}
end

-- function BuffGlobalModel:initType3Record(force,cfgID,lim)
-- 	if not self.triggerType3Record[force][cfgID] then
-- 		self.triggerType3Record[force][cfgID] = {limit = lim,time = 0}
-- 	end
-- end

-- function BuffGlobalModel:addType3Record(force,cfgID)
-- 	self.triggerType3Record[force][cfgID].time = self.triggerType3Record[force][cfgID].time + 1
-- end

-- function BuffGlobalModel:isType3Exceed(force,cfgID)
-- 	return self.triggerType3Record[force][cfgID].time >= self.triggerType3Record[force][cfgID].limit
-- end

-- function BuffGlobalModel:resetType3Record(force,cfgID)
-- 	self.triggerType3Record[force][cfgID].time = 0
-- end

function BuffGlobalModel:setDamageLinkRecord(objID,cfgID,value,oneWayKey,casterId)
	if not self.damageLinkRecord[cfgID] then
		self.damageLinkRecord[cfgID] = {}
	end
	self.damageLinkRecord[cfgID][objID] = {value = value,oneWay = oneWayKey,casterId = casterId}
end

function BuffGlobalModel:cleanDamageLinkRecord(objID,cfgID)
	self.damageLinkRecord[cfgID][objID] = nil
end

function BuffGlobalModel:getDamageLinkObjs(objID,cfgID) --exclude objID
	if not self.damageLinkRecord[cfgID] then
		return {}
	end
	if self.damageLinkRecord[cfgID][objID].oneWay == 1 then
		return {}
	end
	local casterId = self.damageLinkRecord[cfgID][objID].casterId
	local ret = {}
	for k,v in pairs(self.damageLinkRecord[cfgID]) do
		if k ~= objID and v.casterId == casterId and v.oneWay ~= 2 then
			table.insert(ret,k)
		end
	end
	table.sort(ret)
	return ret
end

function BuffGlobalModel:getDamageLinkValue(objID,cfgID)
	if not self.damageLinkRecord[cfgID] then
		return nil
	end
	return self.damageLinkRecord[cfgID][objID].value
end

function BuffGlobalModel:setBuffLinkValue(srcObjID,dstObjID,fixValue,groups,cfgId)
	if not self.buffLinkRecord[srcObjID] then
		self.buffLinkRecord[srcObjID] = {}
	end
	self.buffLinkRecord[srcObjID][dstObjID] = {fixValue = fixValue,groups = groups,cfgId = cfgId}
end

function BuffGlobalModel:getAllBuffLinkValue(srcObjID)
	return self.buffLinkRecord[srcObjID]
end

function BuffGlobalModel:onBuffLinkOver(cfgId)
	local toDelTb = {}
	for k,v in pairs(self.buffLinkRecord) do
		for k2,v2 in pairs(v) do
			if v.cfgId == cfgId then
				table.insert(toDelTb,{srcObjID = k,dstObjID = k2})
			end
		end
	end
	table.sort(toDelTb,function(a,b)
		if a.srcObjID ~= b.srcObjID then
			return a.srcObjID < b.srcObjID
		else
			return a.dstObjID < b.dstObjID
		end
	end)
	for k,v in ipairs(toDelTb) do
		self.buffLinkRecord[v.srcObjID][v.dstObjID] = nil
	end
end

function BuffGlobalModel:recordBuffTriggerType(objID,buffType)
	if not self.buffTriggerTypeRecord[objID] then
		self.buffTriggerTypeRecord[objID] = {}
	end
	if not self.buffTriggerTypeRecord[objID][buffType] then
		self.buffTriggerTypeRecord[objID][buffType] = 1
	else
		self.buffTriggerTypeRecord[objID][buffType] = self.buffTriggerTypeRecord[objID][buffType] + 1
	end
end

function BuffGlobalModel:getBuffTriggerTime(objID,buffType)
	if not self.buffTriggerTypeRecord[objID] then
		return 0
	end
	if not self.buffTriggerTypeRecord[objID][buffType] then
		return 0
	end
	return self.buffTriggerTypeRecord[objID][buffType]
end

function BuffGlobalModel:cleanBuffTriggerTimeRecord()
	self.buffTriggerTypeRecord = {}
end

-- 针对个人,阵营buff触发次数限制
function BuffGlobalModel:initBuffCfgLimit(cfgId,data)
	local ret = {
		type = data.type,
		limit = data.limit,
		-- rule = data.rule or 1, -- 1:触发次数 2:个数限制<目前只限制阵营>
	}
	return ret
end
-- 记录,刷新触发次数
function BuffGlobalModel:refreshBuffLimit(scene,buff)
	-- 不存在次数限制
	if not buff.gateLimit then return end
	-- 初始化映射表
	if not self.cfgIdToLimitType[buff.cfgId] then
		self.cfgIdToLimitType[buff.cfgId] = true
		for _,v in ipairs(buff.gateLimit) do
			if v.scenes then
				if itertools.include(v.scenes,scene.gateType) then
					self.cfgIdToLimitType[buff.cfgId] = self:initBuffCfgLimit(buff.cfgId,v)
				end
			else
				self.cfgIdToLimitType[buff.cfgId] = self:initBuffCfgLimit(buff.cfgId,v)
			end
		end
	end

	-- 当前玩法不存在次数限制以及不存在通用玩法次数限制
	if self.cfgIdToLimitType[buff.cfgId] == true then
		return
	end
	local def = self.cfgIdToLimitType[buff.cfgId]
	-- absForce存在时 只有属于该阵营才有触发次数限制
	if def.absForce and def.absForce ~= buff.holder.force and (def.type == BuffLimitType.object
	or def.type == BuffLimitType.holderForce) then
		self.cfgIdToLimitType[buff.cfgId] = true
		return
	end
	-- print("refreshBuffLimit",buff.cfgId,def.type,def.limit,debug.traceback())
	local ret
	if not self.triggerLimitRecordTb[def.type][buff.cfgId] then
		self.triggerLimitRecordTb[def.type][buff.cfgId] = {}
	end
	ret = self.triggerLimitRecordTb[def.type][buff.cfgId]
	local record
	local holder = buff.holder
	if def.type == BuffLimitType.object then
		ret[holder.id] = ret[holder.id] or {limit = def.limit,time = 0}
		record = ret[holder.id]
	elseif def.type == BuffLimitType.holderForce then
		ret[holder.force] = ret[holder.force] or {limit = def.limit,time = 0}
		record = ret[holder.force]
	end

	-- local firstClean = false
	if record.time < record.limit then
		record.time = record.time + 1
		-- firstClean = (record.time == record.limit)
	else
		record.time = record.limit
	end
end

-- 刷新相同buff效果存在个数
function BuffGlobalModel:refreshBuffEffectNums(buff, limitNum)
	local easyEffectFunc = buff.csvCfg.easyEffectFunc
	if not self.effectToBuffs[easyEffectFunc] then
		self.effectToBuffs[easyEffectFunc] = CVector.new()
	end

	while self.effectToBuffs[easyEffectFunc]:size() >= limitNum do
		local ovreBuff = self.effectToBuffs[easyEffectFunc]:pop_front()
		ovreBuff:over()
	end

	self.effectToBuffs[easyEffectFunc]:push_back(buff)
end

-- buff是否可以被添加
function BuffGlobalModel:checkBuffCanAdd(buff,holder)
	local def = self.cfgIdToLimitType[buff.cfgId]
	if not buff.csvCfg.gateLimit then return true end
	if not def or def == true then return true end
	local data = self.triggerLimitRecordTb[def.type][buff.cfgId]
	if not data then return true end
	if def.type == BuffLimitType.object then
		-- print("checkBuffCanAdd",data[holder.id].time,data[holder.id].limit,debug.traceback())
        if not data[holder.id] then return true end
		return data[holder.id].time < data[holder.id].limit
	elseif def.type == BuffLimitType.holderForce then
        if not data[holder.force] then return true end
		return data[holder.force] and data[holder.force].time < data[holder.force].limit
	end
	return true
end
