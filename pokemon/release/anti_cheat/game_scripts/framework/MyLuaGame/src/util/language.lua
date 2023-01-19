--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2017 TianJi Information Technology Inc.
--
-- 语言本地化处理
--

local format = string.format

-- @desc 返回本地化描述文字的字段
function globals.getL10nField(field)
	if LOCAL_LANGUAGE == 'cn' then
		return field
	else
		return format('%s_%s', field, LOCAL_LANGUAGE)
	end
end

-- @desc 返回本地化描述文字
function globals.getL10nStr(csv, field)
	if LOCAL_LANGUAGE == 'cn' then
		return csv[field]
	else
		return csv[format('%s_%s', field, LOCAL_LANGUAGE)]
	end
end

-- @desc 判断是否是本地版本
function globals.checkLanguage(language)
	language = language or 'cn'
	return LOCAL_LANGUAGE == language
end

-- @desc 判断t是否包含本地语言
function globals.matchLanguage(t)
	t = t or {}
	for k,v in pairs(t) do
		if v == LOCAL_LANGUAGE then
			return true
		end
	end
	return false
end

-- @desc 根据servKey获得tag
function globals.getServerTag(servKey)
	return string.split(servKey, ".")[2]
end

-- 从servKey中获取区服id
-- 默认判定合服处理, gamemerge.cn.1 -> csv.server.merge[servKey].serverID
function globals.getServerId(servKey, isOrgin)
	if gDestServer[servKey] then
		return gDestServer[servKey].id
	end
	if not isOrgin and gServersMergeID[servKey] then
		return csv.server.merge[gServersMergeID[servKey]].serverID
	end
	return tonumber(string.split(servKey, ".")[3])
end

-- 从servKey中获取区服area，如官方1区, showShort：true显示为 官方.S1
-- 默认判定合服处理, gamemerge.cn.1 -> 官方1区
-- 登录服和跨服中匹配的服务器需要显示给定服，玩家区服信息一般默认合服显示
function globals.getServerArea(servKey, showShort, isOrgin)
	local tag = getServerTag(servKey)
	local id = getServerId(servKey, isOrgin)
	local channelName = SERVER_MAP[tag] and SERVER_MAP[tag].name or ""
	if showShort then
		local str = "S" .. id
		if channelName ~= "" then
			str = string.format("%s.%s", channelName, str)
		end
		return str
	end
	return string.format("%s%d%s", channelName, id, (matchLanguage({"kr"}) and "" or gLanguageCsv.serverArea))
end

-- 从servKey中获取区服名, 如皮卡丘
-- 默认判定合服处理
function globals.getServerName(servKey, isOrgin)
	local tag = getServerTag(servKey)
	local id = getServerId(servKey, isOrgin)
	local mergeKey = string.format("game.%s.%s", tag, id)
	if not SERVERS_INFO[mergeKey] then
		return ""
	end
	return SERVERS_INFO[mergeKey].name
end

-- 获得合服后的名称缩写, 非合服返回原名
function globals.getShortMergeRoleName(name)
	local gameKey = userDefault.getForeverLocalKey("serverKey", nil, {rawKey = true})
	if gServersMergeID[gameKey] then
		local id = getServerId(gameKey)
		local pos = string.find(name, string.format(".s%d$", id))
		if pos then
			return string.sub(name, 1, pos-1)
		end
	end
	return name
end

-- 判断是否包含当前服, servKey 可为 gamemerge.cn.1
function globals.isCurServerContainMerge(servKey)
	local gameKey = userDefault.getForeverLocalKey("serverKey", nil, {rawKey = true})
	if gDestServer[servKey] then
		return itertools.include(gDestServer[servKey].servers, gameKey)
	end
	return servKey == gameKey
end

-- key: pwAwardVer randomTowerAwardVer craftAwardVer
function globals.getVersionContainMerge(key)
	local gameKey = userDefault.getForeverLocalKey("serverKey", nil, {rawKey = true})
	local mergeId = gServersMergeID[gameKey]
	local version = mergeId and csv.server.merge[mergeId][key] or 0
	return version
end

function globals.getMergeServers(servers)
	local hash = {}
	-- 按序加入
	local mergeServers = {}
	for _, server in ipairs(servers) do
		local tag = getServerTag(server)
		local id = getServerId(server)
		local mergeKey = string.format("game.%s.%s", tag, id)
		if not hash[mergeKey] then
			hash[mergeKey] = true
			table.insert(mergeServers, mergeKey)
		end
	end
	return mergeServers
end
