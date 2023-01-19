--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2016 TianJi Information Technology Inc.
--
-- GameModelBase
--


local isIdlertable = isIdlertable

local messageComponent = cc.load("message")

local function tupd(base, tb, tbnew)
	for k, v in pairs(tb) do
		if base[k] == nil then
			base[k] = v
		else
			if tbnew and tbnew[k] == true then
				base[k] = v
			else
				local bv = base[k]
				if type(bv) == "table" then
					if type(v) ~= "table" then
						printError('model sync upd date type mismatch! %s, %s', type(bv), type(v))
					end
					tupd(bv, v, tbnew and tbnew[k] or nil)
				else
					base[k] = v
				end
			end
		end
	end
end

local function tdel(base, tb)
	for k, v in pairs(tb) do
		if type(v) == "table" then
			local bb = base[k]
			if type(bb) ~= "table" then
				printError('model sync del date type mismatch! %s, %s', type(bb), type(v))
			end
			tdel(bb, v)
		elseif v == false then
			base[k] = nil
		end
	end
end

local GameModelBase = class("GameModelBase")

function GameModelBase:ctor(game)
	self.game = game
	self.__idlers = nil
	self.__model = {}
end

function GameModelBase:init(t)
	if t._mem == nil and t._db == nil then
		printWarn("no any data in model %s?", tostring(self))
		print(dumps(t))
	end

	local model = t._db or t._mem or {}
	if t._mem and model ~= t._mem then
		table.merge(model, t._mem)
	end
	self.__model = model

	local idlerMap = {}
	self.__idlers = idlers.newWithMap(idlerMap, tostring(self))

	return self
end

-- internal usage
function GameModelBase:getRawIdler_(name)
	if name == nil then
		return self.__idlers
	end

	if self.__idlers == nil then
		return errorInWindows("model __idlers is nil, name(%s)", tostring(name))
	end
	local ret = self.__idlers:at(name)
	-- nil也是正常值，得看外部如何处理
	return ret
end
local getRawIdler_ = GameModelBase.getRawIdler_

function GameModelBase:getOrNewRawIdler_(name)
	local idler = getRawIdler_(self, name)
	if idler == nil then
		local v = self.__model[name]
		if v ~= nil then
			-- idler live in game model, not belong to view
			idlersystem.skipAddIdlerMark(1)
			idler = idlereasy.new(v, name)
			self.__idlers:add(name, idler)
		end
	end
	return idler
end
local getOrNewRawIdler_ = GameModelBase.getOrNewRawIdler_

function GameModelBase:getValue_(name)
	assert(name, "name is nil")

	local idler = getRawIdler_(self, name)
	if idler == nil then
		return self.__model[name]
	end
	return idler:read()
end
local getValue_ = GameModelBase.getValue_


function GameModelBase:fastRead_(...)
	local v1, v2, v3, v4, v5, v6, v7 = ...
	if v1 == nil then
		-- __idlers no read()
		errorInWindows("model __idlers no read for itself, params for name key be need")
		return true, nil
	elseif v7 ~= nil then
		return false
	end

	if v2 == nil then
		local o = getValue_(self, v1)
		return true, o
	elseif v3 == nil then
		local o1 = getValue_(self, v1)
		local o2 = getValue_(self, v2)
		return true, {
			[v1] = o1,
			[v2] = o2,
		}
	elseif v4 == nil then
		local o1 = getValue_(self, v1)
		local o2 = getValue_(self, v2)
		local o3 = getValue_(self, v3)
		return true, {
			[v1] = o1,
			[v2] = o2,
			[v3] = o3,
		}
	elseif v5 == nil then
		local o1 = getValue_(self, v1)
		local o2 = getValue_(self, v2)
		local o3 = getValue_(self, v3)
		local o4 = getValue_(self, v4)
		return true, {
			[v1] = o1,
			[v2] = o2,
			[v3] = o3,
			[v4] = o4,
		}
	elseif v6 == nil then
		local o1 = getValue_(self, v1)
		local o2 = getValue_(self, v2)
		local o3 = getValue_(self, v3)
		local o4 = getValue_(self, v4)
		local o5 = getValue_(self, v5)
		return true, {
			[v1] = o1,
			[v2] = o2,
			[v3] = o3,
			[v4] = o4,
			[v5] = o5,
		}
	elseif v7 == nil then
		local o1 = getValue_(self, v1)
		local o2 = getValue_(self, v2)
		local o3 = getValue_(self, v3)
		local o4 = getValue_(self, v4)
		local o5 = getValue_(self, v5)
		local o6 = getValue_(self, v6)
		return true, {
			[v1] = o1,
			[v2] = o2,
			[v3] = o3,
			[v4] = o4,
			[v5] = o5,
			[v6] = o6,
		}
	end
	return false
end
local fastRead_ = GameModelBase.fastRead_

-- external usage

function GameModelBase:getIdler(name)
	return idlereasy.assign(getOrNewRawIdler_(self, name))
end

function GameModelBase:multigetIdler(...)
	local v1, v2 = ...
	if v2 == nil then
		return idlereasy.assign(getOrNewRawIdler_(self, v1))
	else
		return idlereasyArgs.newWithFunc(function(i, k)
			return idlereasy.assign(getOrNewRawIdler_(self, k))
		end, ...)
	end
end

function GameModelBase:read(...)
	local flag, ret = fastRead_(self, ...)
	if flag then
		return ret
	else
		ret = {}
		for _, name in ipairs({...}) do
			ret[name] = getValue_(self, name)
		end
		return ret
	end
end

function GameModelBase:syncFrom(t, new)
	local new = new or {}
	if t._mem then
		self:updSync(t._mem, new._mem)
	end

	if t._db then
		self:updSync(t._db, new._db)
	end

	if t._mem == nil and t._db == nil then
		-- 这个model是服务器通过view返回的，服务器没有维护这个model
		if self.__idlers == nil then
			self:init({_mem=t})
			return
		end
		self:updSync(t, new)
	end
end

function GameModelBase:updSync(tb, tbnew)
	if self.__idlers == nil then return end

	local manual = true
	for k, v in pairs(tb) do
		local o = self.__idlers:at(k)
		local t = self.__model[k]

		-- put in model
		if t == nil then
			self.__model[k] = v
		else
			if (tbnew and (tbnew == true or tbnew[k] == true)) then
				self.__model[k] = v
			else
				if type(t) == "table" then
					tupd(t, v, tbnew and tbnew[k] or nil)
				else
					self.__model[k] = v
				end
			end
		end

		-- put in idlers when it existed
		if o == nil then
		else
			manual = false
			if (tbnew and (tbnew == true or tbnew[k] == true)) then
				o:set(v)
			else
				if isIdlertable(o) then
					o:modify(function(val)
						tupd(val, v, tbnew and tbnew[k] or nil)
					end, true)
				else
					o:set(v)
				end
			end
		end
	end

	-- notify the changes of mine
	if manual then
		self.__idlers:notify()
	end
end

function GameModelBase:syncDel(t)
	if t._mem then
		self:delSync(t._mem)
	end
	if t._db then
		self:delSync(t._db)
	end
end

function GameModelBase:delSync(tb)
	if self.__idlers == nil then return end

	for k, v in pairs(tb) do
		if type(v) == "table" then
			local o = self.__idlers:at(k)
			local t = self.__model[k]

			if t then
				tdel(t, v)
			end

			if o then
				o:modify(function(val)
					tdel(val, v)
				end, true)
			end

		elseif v == false then
			self.__idlers:remove(k)
			self.__model[k] = nil
		end
	end
end

return GameModelBase
