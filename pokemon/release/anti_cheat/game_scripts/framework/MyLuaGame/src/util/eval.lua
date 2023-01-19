--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2016 TianJi Information Technology Inc.
--
-- 字符串转function
--


local eval = {}
globals.eval = eval

local nullenv = setmetatable({}, {__newindex = function(t, k, v)
	error(string.format("nullenv can not be write %s!", k))
end})

local function runFormula(f, env)
	if type(f) ~= "function" then return f end
	setfenv(f, env)
	local ret = f()
	setfenv(f, nullenv) --把env清掉
	return ret
end

-- key UI缓存，战斗不缓存（反挂）
local function run(s, env, key)
	-- 如果是数值直接返回
	local v = tonumber(s)
	if v then return v end

	return runFormula(cache.createFormula(s, key), env)
end

-- @return: prefix_str, f, next_pos
local function parseMixedFormula(s, p)
	local pos1 = s:find('%$', p)
	local pos2 = pos1 and s:find('%$', pos1+1)
	if pos1 == nil or pos2 == nil then
		return s:sub(p), nil, #s + 1
	end
	local funcStr = s:sub(pos1+1, pos2-1)
	return s:sub(p, pos1-1), funcStr, pos2+1
end

local function runMixedFormula(s, env)
	local pos, tb = 1, {}
	local ss, fs
	while pos <= #s do
		ss, fs, pos = parseMixedFormula(s, pos)
		-- 没有任何公式
		if fs == nil and #tb == 0 then return s end
		table.insert(tb, ss)
		if fs then
			-- 默认都有key能缓存
			table.insert(tb, run(fs, env, fs))
		end
	end
	return table.concat(tb)
end


-- 纯公式代码
function eval.doFormula(strOrTable, env, key)
	if strOrTable == nil then return nil end
	env = env or {}
	if type(strOrTable) == "table" then
		local ret = {}
		for i, s in ipairs(strOrTable) do
			-- 用s做为key
			local skey = key and s
			ret[i] = run(s, env, skey)
		end
		return ret
	else
		return run(strOrTable, env, key)
	end
end

-- UI上使用的，其他字符串$公式$其他字符串
-- "$math.floor(1111/skillLevel)$haha$skillLevel*2$fgd"
function eval.doMixedFormula(strOrTable, env, key)
	if strOrTable == nil then return nil end
	env = env or {}
	local ret
	if type(strOrTable) == "table" then
		local ret = {}
		for i, s in ipairs(strOrTable) do
			ret[i] = runMixedFormula(s, env)
		end
		return ret

	else
		return runMixedFormula(strOrTable, env)
	end
end

