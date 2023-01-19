--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2018 TianJi Information Technology Inc.
--
-- idler computer
--

local type = type
local checkbool = checkbool
local insert = table.insert

-- idler and idlercomputer diff
-- 1. idler had value, idlercomputer had idler
-- 2. idler could set and get, idlercomputer only could get
local idlercomputer = clone(idler)
globals.idlercomputer = idlercomputer
idlercomputer.__idlercomputer = true
idlercomputer.__class = idlercomputer
idlercomputer.__index = idlercomputer
idlercomputer.__cname = "idlercomputer"

idlercomputer.set = nil
idlercomputer.modify = nil

function globals.isIdlerComputer(t)
	return type(t) == "table" and t.__idlercomputer == true
end

-- @param obj: idler object
-- @param f: compute new value to set self
function idlercomputer.new(obj, f, noInit)
	local self = setmetatable({
		listeners = {}, -- downstream
		tickets = {}, -- upstream listen key
		oldval = nil,
		working = false,
		__cid = idlercomputer.newid(),
	}, idlercomputer)

	idlercomputer.placeNew(self, obj, f, noInit)
	idlersystem.addIdler(self)
	return self
end

function idlercomputer.placeNew(self, obj, f, noInit)
	if obj then
		local key = obj:addListener(function(val, oldval, _)
			local setit, newval = f(self, val)
			if setit then
				-- if need compare newval and oldval, this could be do in f
				return self:changed_(newval, true)
			end
			return self:changed_(self.oldval)
		end, noInit)
		self.tickets[1] = key
	end
	return self
end

-- @param filter: idlerfilter or function
-- @param preprocess: table or function
-- @param f: be called when filter return true
-- @param ...: idler objects
-- @default: preprocess={clearlast=false}
function idlercomputer.combine(filter, preprocess, f, objs)
	local self = idlercomputer.new()
	local mark, changed = {}, {}
	if type(preprocess) == "function" then
		preprocess = {f = preprocess}
	end

	for i, obj in ipairs(objs) do
		-- noInit=true
		local key = obj:addListener(function(val, oldval, _)
			if self.listeners == nil then return end
			mark[i] = obj:get_() -- idlers's val is msg
			changed[i] = true
			if filter(mark, changed, i, #objs) then
				if preprocess and preprocess.f then
					mark = preprocess.f(mark, objs)
				end
				local setit, newval = f(self, unpack(mark, 1, #objs))
				if setit then
					self:changed_(newval)
				end
				self:changed_(self.oldval)
				if preprocess and preprocess.clearlast then
					mark = {}
				end
				changed = {}
			end
		end, true)
		-- init mark
		mark[i] = obj:get_()
		changed[i] = true
		self.tickets[i] = key
	end

	-- init oldval
	for i, obj in ipairs(objs) do
		if filter(mark, changed, i, #objs) then
			if preprocess and preprocess.f then
				mark = preprocess.f(mark, objs)
			end
			local setit, newval = f(self, unpack(mark, 1, #objs))
			if setit then
				self.oldval = newval
			end
			if preprocess and preprocess.clearlast then
				mark = {}
			end
			changed = {}
			break
		end
	end
	return self
end

function idlercomputer:deafen()
	for k, key in pairs(self.tickets) do
		key:detach()
	end
	self.tickets = {}
end

function idlercomputer:destroy()
	-- destroy may be call in:
	-- idlersystem.addAnonymousOnlyIdler
	-- idlersystem.onViewBaseCleanup
	if self.listeners == nil then return end
	local tickets = self.tickets
	self.tickets = nil
	for k, key in pairs(tickets) do
		key:detach()
	end
	return idler.destroy(self)
end

-- match up with idlereasy for local scope anonymous only one usage
function idlercomputer:anonyOnly(view, key)
	assert(view, "anonyOnly force give view param, check your code")
	idlersystem.addAnonymousOnlyIdler(self, view, key)
	return self
end