--
-- Callback debugString
--


local Callback = battleEffect.Callback

local function upsTable(info)
	local ret = {}
	for i = 1, info.nups do
		local k, v = debug.getupvalue(info.func, i)
		ret[k] = v
	end
	return ret
end

local function kvTableToString(t)
	local arr = itertools.map(t, function(k, v)
		return string.format("%s=%s", toDebugString(k), toDebugString(v))
	end)
	return table.concat(arr, ", ")
end

local funcInfoDump = {
	["src/battle/easy/effect.lua"] = function(info)
		-- battleEasy.queueNotify
		-- battleEasy.queueNotifyFor
		local t = upsTable(info)
		local view = t.view and toDebugString(t.view) or "BattleView"
		return string.format("easy/effect:%d [%s]:%s", info.linedefined, view, t.msg)
	end,

	["src/util/functools.lua"] = function(info)
		local t = upsTable(info)
		if t.upv1 then
			local info2 = debug.getinfo(t.f)
			-- print_r(info2)
			local f2 = string.format("%s:%d", info2.source, info2.linedefined)

			local view = toDebugString(t.upv1)
			return string.format("[%s]:%s(%s)", view, f2, t.upv2)
		end
	end,

	["src/battle/views/sprite_normal.lua"] = function(info)
		local t = upsTable(info)
		if t.isAttacting ~= nil then
			return string.format("sprite_normal:%d, [%s]:objToHideEff(%s)", info.linedefined, toDebugString(t.self), t.flag)
		end
		if t.self then
			local self = toDebugString(t.self)
			t.self = nil
			return string.format("sprite_normal:%d, [%s] {%s}", info.linedefined, self, kvTableToString(t))
		end
	end,

	["src/battle/views/event_effect/effect1.lua"] = function(info)
		local t = upsTable(info)
		if t.self then
			local self = toDebugString(t.self)
			t.self = nil
			return string.format("%s:%d, [%s] {%s}", info.source, info.linedefined, self, kvTableToString(t))
		end
	end,
}

function Callback:debugString()
	local info = debug.getinfo(self.args.func)

	local s
	if funcInfoDump[info.source] then
		s = funcInfoDump[info.source](info)
	end
	if s == nil then
		s = string.format("%s:%d", info.source, info.linedefined)

		-- print_r(info)
		-- for i = 1, info.nparams do
		-- 	local k, v = debug.getlocal(info.func, i)
		-- 	print(string.format("param %s=%s", k, tostring(v)))
		-- end
		-- for i = 1, info.nups do
		-- 	local k, v = debug.getupvalue(info.func, i)
		-- 	print(string.format("up %s=%s", k, tostring(v)))
		-- end
	end

	return string.format("Callback: %s", s)
end