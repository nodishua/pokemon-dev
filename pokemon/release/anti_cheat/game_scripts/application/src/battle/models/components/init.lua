--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2021 TianJi Information Technology Inc.
--
-- like cocos\framework\package_support.lua
--

globals.battleComponents = {}

local loaded_packages = {}
local id_counter = 1

local g_data
local bind_targets

function battleComponents.register(name, package)
	loaded_packages[name] = package
	printInfo("battleComponents.register() - register module %s", name)
end

local bind_
bind_ = function(target, ...)
	local t = type(target)
	assert(t == "table" or t == "userdata", string.format("battleComponents.bind() - invalid target, expected is object, actual is %s", t))
	local names = {...}
	assert(#names > 0, "battleComponents.bind() - package names expected")

	if not target.components_ then target.components_ = {} end
	for _, name in ipairs(names) do
		assert(type(name) == "string" and name ~= "", string.format("battleComponents.bind() - invalid package name \"%s\"", name))
		if not target.components_[name] then
			local cls = loaded_packages[name]
			for __, depend in ipairs(cls.DEPENDS or {}) do
				if not target.components_[depend] then
					bind_(target, depend)
				end
			end
			local component = cls:create()
			component.id_ = id_counter
			id_counter = id_counter + 1
			target.components_[name] = component
			component:bind(target)
		end
	end

	bind_targets[target] = true
	return target
end
battleComponents.bind = bind_

function battleComponents.unbindAll(target)
	if not target.components_ then return end

	bind_targets[target] = nil
	for name, component in pairs(target.components_) do
		component:unbind(target)
		target.components_[name] = nil
	end
	return target
end

function battleComponents.setmethods(target, component, methods)
	local componentName = tj.type(component)
	for _, name in ipairs(methods) do
		local method = component[name]
		assert(target[name] == nil, "target already had the method " .. name)
		target[name] = function(self, ...)
			-- compatible with COW
			return method(self.components_[componentName], ...)
		end
	end
end

function battleComponents.component(target, name)
	if target.components_ then
		return target.components_[name]
	end
end

function battleComponents.unbind(target, ...)
	if not target.components_ then return end

	local names = {...}
	assert(#names > 0, "battleComponents.unbind() - invalid package names")

	for _, name in ipairs(names) do
		assert(type(name) == "string" and name ~= "", string.format("battleComponents.unbind() - invalid package name \"%s\"", name))
		local component = target.components_[name]
		assert(component, string.format("battleComponents.unbind() - component \"%s\" not found", tostring(name)))
		component:unbind(target)
		target.components_[name] = nil
	end
	return target
end

function battleComponents.unsetmethods(target, methods)
	for _, name in ipairs(methods) do
		target[name] = nil
	end
end

function battleComponents.components(target)
	return target.components_ or {}
end

-- TODO: weaktable not final solution.
-- event.Global will leak in less removeSubscriber_
function battleComponents.clearAll()
	for target, _ in pairs(bind_targets) do
		battleComponents.unbindAll(target)
		bind_targets[target] = nil
	end

	for name, cls in pairs(loaded_packages) do
		if cls.onClearAll then
			cls.onClearAll()
		end
	end
end

function battleComponents.newGlobalData()
	local ret = {
		bind_targets = {},
	}
	for name, cls in pairs(loaded_packages) do
		if cls.newGlobalData then
			ret[name] = cls.newGlobalData()
		end
	end
	return ret
end

function battleComponents.switchGlobalData(newData)
	local old = g_data
	g_data = newData
	bind_targets = newData.bind_targets
	for name, cls in pairs(loaded_packages) do
		if cls.switchGlobalData then
			cls.switchGlobalData(newData[name])
		end
	end
	return old
end

--
-- load components
--
local _M = {
	require("battle.models.components.event.init")
}

for _, cls in ipairs(_M) do
	battleComponents.register(tostring(cls), cls)
end

--
-- init global data
--
battleComponents.switchGlobalData(battleComponents.newGlobalData())
