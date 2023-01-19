--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2017 TianJi Information Technology Inc.
--
-- csv相关辅助函数
--

-- 测试手机端配置读取用
-- device.platform = "xxxxxx"
-- EDITOR_ENABLE = true

if device.platform == "windows" then
	require "easy.table_override"
end

local type = lua_type

local CsvReservedKeys = {
	__sorted = true,
	__size = true,
	__default = true,
}

local ProtectWritePass = {
	__sorted = true,
	__size = true,
	__default = true,

	-- csv sync with server
	yunying = true,

	-- TODO: better way to change csv row values
	roomIdx = true,
	hpMaxC = true,
	mp1MaxC = true,
}

local csvNameT = {}
function globals.getCsv(csvName)
	if csvName == nil then return nil end
	if csvNameT[csvName] then return csvNameT[csvName] end
	csvNameT[csvName] = loadstring("return " .. csvName)()
	return csvNameT[csvName]
end

function globals.getMonsterCsv(csvName)
	if csvName == nil then return nil end
	local nstr = string.gsub(csvName, '%.', function(c)
		return '_'
	end)
	nstr = "csv.Load"..string.sub(nstr,5)
	return loadstring(nstr .. "() return " .. csvName)()
end

function globals.csvSize(csv)
	if csv.__size == nil then
		local size = 0
		for k, v in csvMapPairs(csv) do
			size = size + 1
		end
		-- csv.__size = size
		return size
	end
	return csv.__size
end

function globals.csvNext(t)
	local nk, nv = next(t)
	while nk and string.sub(nk,1,2) == "__" do
		nk, nv = next(t,nk)
	end
	return nk,nv
end

-- csv id 只可能是整数
function globals.csvPairs(t)
	return function (_, idx)
		local nk, nv = next(t, idx)
		while nk ~= nil and type(nk) ~= "number" do
			nk, nv = next(t, nk)
		end
		return nk, nv
	end, t, nil
end

--key 排除'__'开头的
function globals.csvMapPairs(t)
	return function (_, idx)
		local nk, nv = next(t, idx)
		while nk and (string.sub(nk,1,2) == "__") do
			nk, nv = next(t, nk)
		end
		return nk, nv
	end, t, nil
end

-- 只给csv按key的顺序来遍历
--普通table不能用，因为遍历过程中涉及到remove以及insert,以后有这需求再加
function globals.orderCsvPairs(t)
	if t.__sorted == nil then
		local sorted = {}
		for k, v in pairs(t) do
			if type(k) == "number" then
				table.insert(sorted, k)
			end
		end
		table.sort(sorted)
		t.__sorted = sorted
	end
	local sidx = nil
	return function (_, idx)
		local sk, nk = next(t.__sorted, sidx)
		sidx = sk
		return nk, t[nk]
	end, t, nil
end

local function getRealRaw(t)
	local prev = t
	t = table.getraw(t)
	while t ~= prev do
		prev = t
		t = table.getraw(t)
	end
	return t
end

--把__default里的数据全塞回去并且把__size与__default全置为nil
function globals.csvClone(t)
	if not t then return nil end
	if type(t) ~= "table" then return t end
	local function _parse(t)
		local ret = {}
		local mt, default = getmetatable(getRealRaw(t))
		if mt and type(mt.__index) == "table" then
			default = mt.__index
		end
		for k, v in pairs(t) do
			if type(v) == 'table' then
				ret[k] = _parse(v)
			else
				ret[k] = v
			end
		end
		if default then
			default = _parse(default) -- default结构里不会再设置_setDefalutMeta
			for dk, dv in pairs(default) do
				if ret[dk] == nil then
					ret[dk] = dv
				end
			end
		end
		ret.__size = nil
		ret.__default = nil
		ret.__sorted = nil
		return ret
	end
	return _parse(t)
end

function globals.csvNumSum(t)
	if type(t) ~= "table" then return nil end
	local s = 0
	for k, v in pairs(t) do
		if not CsvReservedKeys[k] then
			local vt = type(v)
			if vt == "number" then
				s = s + v
			elseif vt == "table" then
				s = s + csvNumSum(v)
			end
		end
	end
	return s
end

function globals.csvReadOnlyInWindows(t, name)
	if device.platform ~= "windows" then
		return t
	end

	return table.proxytable(t, nil, nil, function(t, k, v)
		if ProtectWritePass[k] then
			return true
		end
		error(string.format("dont write %s in read only mode! do not set %s, %s!", name, k, v))
	end)
end
