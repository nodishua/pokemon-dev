
local Event = class("Event")

local EXPORTED_METHODS = {
	"setListenerComparer",
	"subscribeEvent",
	"subscribeGlobalEvent",
	"dispatchEvent",
	"dispatchEventToGlobal",
	"dumpAllEventListeners",
}

local Global
local GlobalObject = {
	components_ = {},
	__tostring = function()
		return "GlobalObject"
	end,
}

-- {id: component}
local EventComponentsMap = {}

--
-- event
-- data structure
--
local function disableWrite()
	error("event not writeble")
end
local event = {}
event.__index = event
event.__newindex = disableWrite
function event.new()
	return setmetatable({
		name = "",
		from = nil,
		args = nil,
		free_ = true,
	}, event)
end

function event:fill(target, name, args)
	event.__newindex = nil

	self.from = target
	self.name = name
	self.args = args
	self.free_ = false

	event.__newindex = disableWrite
	return self
end

function event:free()
	self.free_ = true
end

--
-- Event
-- component class
--
function Event:init_(target)
	EventComponentsMap[self.id_] = self

	-- keep init once for switchGlobalData
	if self.inited_ then
		return
	end

	self.inited_ = true
	self.target_ = target
	self.listeners_ = {} -- {eventname: {handler, ...}}
	self.subscribers_ = {} -- {component.id: eventname}
	self.publishers_ = {} -- {component.id: true}
	self.comparer_ = nil

	-- compatible with COW
	self.g_ = GlobalObject
	self.gm_ = EventComponentsMap

	-- event_ skip COW proxy
	local event_ = event.new()
	self.newEvent_ = function(self, eventName, eventArgs)
		local ret = event_
		if not event_.free_ then
			ret = event.new()
		end
		return ret:fill(self.target_, eventName, eventArgs)
	end
end

function Event:destroy_()
	EventComponentsMap[self.id_] = nil

	self.listeners_ = nil
	self.subscribers_ = nil
	self.publishers_ = nil
end

function Event:bind(target)
	battleComponents.setmethods(target, self, EXPORTED_METHODS)

	self:init_(target)
end

function Event:unbind(target)
	battleComponents.unsetmethods(target, EXPORTED_METHODS)

	-- compatible with COW
	local gm, id = self.gm_, self.id_
	for pubID, _ in pairs(self.publishers_) do
		if gm[pubID] then
			gm[pubID]:removeSubscriber_(id)
		end
	end

	self:destroy_()
end

function Event:setListenerComparer(f)
	self.comparer_ = f
end

-- self.listeners_[eventName] = {
-- 	array = {handler, ...},
-- 	map = {handler: target},
--  size = 1,
-- }
function Event:addEventListener_(eventName, subscriber, handler)
	local subscriberID = subscriber.id_
	local handlers = self.listeners_[eventName]
	if handlers == nil then
		if self.comparer_ then
			handlers = {
				array = nil,
				map = {},
				size = 0,
			}
		else
			handlers = {
				array = {},
				size = 0,
			}
		end
		self.listeners_[eventName] = handlers
	end
	local eventsMap = self.subscribers_[subscriberID]
	if eventsMap == nil then
		eventsMap = {}
		self.subscribers_[subscriberID] = eventsMap
	else
		-- 忽略重复event的设置
		-- 现在都是同个handler, 如 BuffModel:onTriggerEvent
		if eventsMap[eventName] then
			return
		end
	end

	-- set array dirty
	handlers.size = handlers.size + 1
	if self.comparer_ then
		handlers.array = nil
		handlers.map[handler] = subscriber.target_
	else
		table.insert(handlers.array, handler)
	end

	eventsMap[eventName] = handler

	-- self:printDebug("addEventListener_ - event: %s, subscriber: %s, handlers: %s", eventName, subscriberID, handlers.size)
end

function Event:removeSubscriber_(subscriberID)
	local eventsMap = self.subscribers_[subscriberID]
	if eventsMap == nil then return end

	-- clean eventsMap and handlers
	for eventName, handler in pairs(eventsMap) do
		eventsMap[eventName] = nil

		local handlers = self.listeners_[eventName]
		-- set array dirty
		if self.comparer_ then
			handlers.array = nil
			handlers.map[handler] = nil
			handlers.size = handlers.size - 1
		else
			table.removebyvalue(handlers.array, handler, false)
			handlers.size = table.length(handlers.array)
		end

		-- self:printDebug("removeSubscriber_ - event: %s, subscriber: %s, handlers: %s, comparer: %s", eventName, subscriberID, handlers.size, self.comparer_ and true)
	end
end

function Event:subscribeEvent(source, eventName, methodName)
	local method = self.target_[methodName]
	assert(method, "no such method")

	-- self:printDebug("subscribeEvent - source: %s %s, event: %s, method: %s", tj.type(source), source.id, eventName, methodName)

	local publisher = battleComponents.component(source, "Event")
	assert(publisher, "publisher no such component")

	self.publishers_[publisher.id_] = true

	local target = cow.proxyObject("target_", self.target_)
	publisher:addEventListener_(eventName, self, function(...)
		return method(target, ...)
	end)
end

function Event:subscribeGlobalEvent(eventName, methodName)
	-- self:printDebug("subscribeGlobalEvent - event: %s, method: %s", eventName, methodName)
	return self:subscribeEvent(self.g_, eventName, methodName)
end

-- dispatch event to target
function Event:dispatchEvent(eventName, eventArgs)
	local handlers = self.listeners_[eventName]

	-- self:printDebug("dispatchEvent - event %s, handlers: %s", eventName, handlers and handlers.size or 0)

	if handlers == nil or handlers.size == 0 then return end

	if self.comparer_ and handlers.array == nil then
		handlers.array = table.keys(handlers.map)
		local m = handlers.map
		table.sort(handlers.array, function(handler1, handler2)
			return self.comparer_(m[handler1], m[handler2])
		end)
	end

	local event = self:newEvent_(eventName, eventArgs)
	for i, handler in ipairs(handlers.array) do
		-- local target_ = handlers.map and handlers.map[handler]
		-- target_ = target_ and string.format("%s %s", tj.type(target_), target_.id)
		-- self:printDebug("dispatchEvent - dispatching event %s to handler [%s] %s", eventName, i, target_)

		handler(event)
	end
	event:free()

	return self.target_
end

function Event:dispatchEventToGlobal(eventName, eventArgs)
	-- self:printDebug("dispatchEventToGlobal - event %s", eventName)
	return self.g_:dispatchEvent(eventName, eventArgs)
end

function Event:printDebug(fmt, ...)
	local s = string.format("[Event] %s %s " .. fmt, tj.type(self.target_), self.target_.id, ...)
	release_print(s)
end

function Event:dumpAllEventListeners()
	print("---- Event:dumpAllEventListeners() ----")
	for name, listeners in pairs(self.listeners_) do
		printf("-- event: %s, handler: %s", name, handler)
	end
	return self.target_
end

function Event:initGlobal_()
	if Global then
		Global:unbind(GlobalObject)
	end

	Global = Event:create()
	Global.id_ = 0
	GlobalObject.components_["Event"] = Global
	Global:bind(GlobalObject)
end

function Event.onClearAll()
	Event:initGlobal_()
end

function Event.newGlobalData()
	local g = Event:create()
	g.id_ = 0

	return {
		Global = g,
		EventComponentsMap = {},
	}
end

function Event.switchGlobalData(newData)
	-- only to replace, no need to destroy_
	battleComponents.unsetmethods(GlobalObject, EXPORTED_METHODS)

	Global = newData.Global
	EventComponentsMap = newData.EventComponentsMap

	GlobalObject.components_["Event"] = Global
	Global:bind(GlobalObject)
end


--
-- Global
-- always existed
--
Event:initGlobal_()

return Event
