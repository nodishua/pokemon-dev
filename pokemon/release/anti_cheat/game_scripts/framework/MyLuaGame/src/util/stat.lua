--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2017 TianJi Information Technology Inc.
--
-- 统计，求和相关
--

local stat = {}
globals.stat = stat

local function returnK(k, v)
	return k
end

-- sum(filter({[1]=1, [3]=2, [10]=3}, k>=2))
-- sumRange(2) -> sumRange(2, max) -> 5
-- sumRange(2, 3) -> 2
local summator
summator = {
	__index = function(t, k)
		if type(k) == "number" then
			if k < t.__minKey then return 0 end
			-- k > maxKey
			return rawget(t, t.__maxKey)
		end
		return summator[k]
	end,
	__newindex = function(t, k, v)
		error("you could not write in sum table " .. tostring(k))
	end,
	-- new
	new = function(h)
		-- h only int key, h[key] = count
		local minKey = itertools.min(h, returnK) or 0
		local maxKey = itertools.max(h, returnK) or 0
		local s = 0
		local obj = {__minKey = minKey, __maxKey = maxKey}
		for i = minKey, maxKey do
			s = s + (h[i] or 0)
			obj[i] = s
		end
		return setmetatable(obj, summator)
	end,
	-- sum range [s, e]
	-- e default was maxKey
	sumRange = function(t, s, e)
		e = e or t.__maxKey
		return t[e] - t[s-1]
	end,
}
stat.summator = summator
