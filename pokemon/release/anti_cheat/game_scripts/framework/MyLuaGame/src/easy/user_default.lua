-- @date: 2018-11-16
-- @desc: 本地数据存储
-- @TODO: http://bug.tianji-game.com/browse/CXNBKF-185

local ccUserDefault = cc.UserDefault:getInstance()
local isCleanup = false

local userDefault = {}
globals.userDefault = userDefault

-- @desc 启动游戏后的首次调用，自动清理数据
local function onCleanup()
	if isCleanup then
		return
	end
	isCleanup = true
	cache.cleanUserDefault()

	-- 清理活动不在 yyhuodong 里和 过期30天 的
	local data = userDefault.getForeverLocalKey("activity", {})
	local newData = {}
	local function validActivity(id)
		local cfg = csv.yunying.yyhuodong[id]
		if not cfg then
			return false
		end
		local hour = time.getHourAndMin(cfg.endTime, true)
		local endTime = time.getNumTimestamp(cfg.endDate, hour)
		if time.getTime() -  endTime >= 30 * 24 * 3600 then
			return false
		end
		return true
	end
	for k, v in pairs(data) do
		if validActivity(k) then
			newData[k] = v
		end
	end
	userDefault.setForeverLocalKey("activity", newData, {new = true})
end

-- @desc 转换为关联帐号的key
local function getUserKey(key, raw)
	if raw then
		return key
	end
	local id = gGameModel.role:read("id")
	if assertInWindows(id, "user_default getUserKey is nil, key(%s)", tostring(key)) then
		return ""
	end
	return string.format("%s_%s", stringz.bintohex(id), key)
end

-- @desc 将 data 的 key 转换为 string
local function tryToStringKeyTable(data)
	if type(data) ~= "table" then
		return data
	end
	local t = {}
	for k,v in pairs(data) do
		local val = v
		if type(v) == "table" then
			val = tryToStringKeyTable(v)
		end
		t[tostring(k)] = val
	end
	return t
end

-- @desc 将 data 的 key 尝试转换为 number
local function tryToNumberKeyTable(data)
	if type(data) ~= "table" then
		return data
	end
	local t = {}
	for k,v in pairs(data) do
		local val = v
		if type(v) == "table" then
			val = tryToNumberKeyTable(v)
		end
		t[tonumber(k) or k] = val
	end
	return t
end

-- @desc 按天记录数据，freshHour之后认为是当天
-- @params raw: true 则为解析的 string key，不转换为 number
-- @param params: {freshHour, rawKey, rawData}
-- rawKey: 默认转换 key 关联帐号
-- rawData: 默认转换 key 为 number，true 则为 json.decode 解析的 string key，不转换为 number
function userDefault.getCurrDayKey(key, default, params)
	params = params or {}
	local userKey = getUserKey(key, params.rawKey)
	local t = cache.queryUserDefault(userKey, function()
		local str = ccUserDefault:getStringForKey(userKey, "")
		if str == "" then
			-- empty save in cache
			return
		end
		return json.decode(str)
	end)

	local currTime = time.getTodayStrInClock(params.freshHour)
	local ret = t and t[currTime] or default
	if params.rawData then
		return clone(ret)
	end
	return tryToNumberKeyTable(ret)
end

-- @desc 按天获取数据，freshHour之后认为是当天
-- @param params: {new, delete,  freshHour, rawKey}
function userDefault.setCurrDayKey(key, data, params)
	params = params or {}
	local userKey = getUserKey(key, params.rawKey)
	if data == nil or (type(data) == "table" and next(data) == nil) then
		cache.updateUserDefault(userKey, nil, function()
			ccUserDefault:deleteValueForKey(userKey)
		end)
		return
	end
	if params.new then
		cache.updateUserDefault(userKey, nil, function()
			ccUserDefault:deleteValueForKey(userKey)
		end)
	end

	local currTime = time.getTodayStrInClock(params.freshHour)
	local newData = {}
	if type(data) ~= "table" then
		newData[currTime] = data
	else
		newData[currTime] = userDefault.getCurrDayKey(key, {}, maptools.extend({params, {rawData = true}}))
		assert(type(newData[currTime]) == "table", string.format("key(%s) already exist and was not table", key))
		for k,v in pairs(tryToStringKeyTable(data)) do
			if params.delete then
				newData[currTime][k] = nil
			else
				newData[currTime][k] = v
			end
		end
	end

	cache.updateUserDefault(userKey, newData, function()
		ccUserDefault:setStringForKey(userKey, json.encode(newData))
	end)
end

-- @desc 按 key 值记录永久数据
-- @param params: {rawKey, rawData}
function userDefault.getForeverLocalKey(key, default, params)
	params = params or {}
	local userKey = getUserKey(key, params.rawKey)
	local t = cache.queryUserDefault(userKey, function()
		local str = ccUserDefault:getStringForKey(userKey, "")
		if str == "" then
			-- empty save in cache
			return
		end
		return {raw = json.decode(str)}
	end)

	if t == nil then
		return default
	end
	if params.rawData then
		return clone(t.raw)
	end
	t.itable = t.itable or tryToNumberKeyTable(t.raw)
	return t.itable
end

-- @desc 按 key 值获取永久数据
-- @param params: {new, delete, rawKey}
function userDefault.setForeverLocalKey(key, data, params)
	params = params or {}
	if not params.rawKey then
		onCleanup()
	end
	local userKey = getUserKey(key, params.rawKey)
	if data == nil or (type(data) == "table" and next(data) == nil)then
		cache.updateUserDefault(userKey, nil, function()
			ccUserDefault:deleteValueForKey(userKey)
		end)
		return
	end
	if params.new then
		cache.updateUserDefault(userKey, nil, function()
			ccUserDefault:deleteValueForKey(userKey)
		end)
	end

	local newData = data
	if type(data) == "table" then
		newData = userDefault.getForeverLocalKey(key, {}, maptools.extend({params, {rawData = true}}))
		assert(type(newData) == "table", string.format("key(%s) already exist and was not table", key))
		for k,v in pairs(tryToStringKeyTable(data)) do
			if params.delete then
				newData[k] = nil
			else
				newData[k] = v
			end
		end
	end

	cache.updateUserDefault(userKey, {raw = newData}, function()
		ccUserDefault:setStringForKey(userKey, json.encode(newData))
	end)
end
