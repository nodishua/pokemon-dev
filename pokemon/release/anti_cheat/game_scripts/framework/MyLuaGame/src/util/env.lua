--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2019 TianJi Information Technology Inc.
--
-- protected env
--

-- 初始化protected env，后续只要对__index赋值即可
local nullenv = setmetatable({}, {
	__index = function(t, k)
		error(string.format("nullenv can not be read `%s`!", k))
	end,
	__newindex = function(t, k, v)
		error(string.format("nullenv can not be write `%s`!", k))
	end}
)

function globals.protectedEnv(p)
	p = p or {}

	p.itertools = itertools
	p.arraytools = arraytools
	p.maptools = maptools
	p.functools = functools
	p.tostring = tostring
	p.ipairs = ipairs
	p.pairs = pairs
	p.print = print
	p.table = table
	p.string = string
	p.math = math
	p.type = type
	p.ymrand = ymrand

	local __supers = {}
	local __fixed = {}

	-- p -> env -> base
	p.__index = function(t, k)
		for _, t in ipairs(__supers) do
			local v = t[k]
			if v ~= nil then
				return v
			end
		end
		return nil
	end
	p.__newindex = function(t, k, v)
		error(string.format("protected env %s can not be write %s!", tostring(t), k))
	end

	-- fixed 固定，无法通过reset去除
	p.fillEnv = function(self, env, fixed)
		local fixExisted = __fixed[env]
		if fixExisted then
			return self
		end

		if fixed then
			__fixed[env] = true
		end
		table.insert(__supers, env)
		return self
	end
	p.fillEnvInFront = function(self, env)
		table.insert(__supers, 1, env)
		return self
	end
	p.resetEnv = function(self)
		local n = #__supers
		for i = n, 1, -1 do
			if not __fixed[__supers[i]] then
				table.remove(__supers, i)
			end
		end
		return self
	end

	return setmetatable(p, p)
end



---------------------
-- TEST

-- local function runFormula(f, env)
-- 	if type(f) ~= "function" then return f end
-- 	setfenv(f, env)
-- 	local ret = f()
-- 	setfenv(f, nullenv) --把env清掉
-- 	return ret
-- end


-- local a = "outsiede"

-- local pp = protectedEnv.new({
-- 	testf = function()
-- 		print('testf', a, self, obj)
-- 		obj2.a = "obj456"
-- 		-- obj3 = 'xxx'
-- 		env.ttt = "ttt in testf"
-- 	end,
-- 	self = 1234,
-- })
-- print('pp=', pp)

-- local ee2 = {
-- 	obj = 456,
-- 	obj2 = {}
-- }
-- local ee = pp:fillEnv(ee2)

-- runFormula(function()
-- 	print('env=', env)
-- 	print('obj=', obj)
-- 	testf()
-- end, ee)
-- for k, v in pairs(ee) do
-- 	print('ee:', k, v)
-- end
-- for k, v in pairs(ee2) do
-- 	print('ee2:', k, v)
-- end

-- pp:resetEnv()
-- runFormula(function()
-- 	print('env=', env)
-- 	print('obj=', obj)
-- 	testf()
-- end, ee)