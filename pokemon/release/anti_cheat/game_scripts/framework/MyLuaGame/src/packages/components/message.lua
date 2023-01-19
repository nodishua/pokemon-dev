-- date 2018-06-29
-- desc 全局事件组件

local Message = class("Message")

local _listenerKeyCounter = 1
local _allMessages = {}

local EXPORTED_METHODS = {
	"registerMessage",
	"unregisterMessage",
	"unregisterTarget",
}

function Message:bind(target)
	cc.setmethods(target, self, EXPORTED_METHODS)
	-- target:enableUpdate()
	self.target_ = target
end

function Message:unbind(target)
	cc.unsetmethods(target, EXPORTED_METHODS)
	self:unregisterTarget()
end

local function _registerMessage(key, msgs, callback)
	if type(msgs) ~= "table" then
		msgs = {msgs}
	end
	for _, msg in ipairs(msgs) do
		if not _allMessages[msg] then
			_allMessages[msg] = {}
		end
		_allMessages[msg][key] = callback
	end
	return key
end

function Message:registerMessage(msgs, callback)
	return _registerMessage(self.target_, msgs, callback)
end

-- 注销掉target 上面的所有事件
function Message:unregisterTarget()
	for name, msgs in pairs(_allMessages) do
		if msgs[self.target_] then
			msgs[self.target_] = nil
			if itertools.isempty(msgs) then
				_allMessages[name] = nil
			end
		end
	end
end

-- 注销掉target 上面的msgs事件
local function _unregisterMessage(key, msgs)
	if type(msgs) ~= "table" then
		msgs = {msgs}
	end
	for _, msg in ipairs(msgs) do
		local msgsStub = _allMessages[msg]
		if msgsStub and msgsStub[key] then
			msgsStub[key] = nil
			if itertools.isempty(msgsStub) then
				_allMessages[msg] = nil
			end
		end
	end
end

function Message:unregisterMessage(msgs)
	return _unregisterMessage(self.target_, msgs)
end

function Message.sendMessage(msg, ...)
	if _allMessages[msg] then
		for target, cb in pairs(_allMessages[msg]) do
			local truncate = cb(...)
			if truncate then
				break
			end
		end
	end
end

local listenerKeyMeta = {}
listenerKeyMeta.__index = listenerKeyMeta
function listenerKeyMeta:remove()
	return _unregisterMessage(self.key, self.msgs)
end

function Message.registerMessageListener(msgs, callback)
	local key = _listenerKeyCounter
	_listenerKeyCounter = _listenerKeyCounter + 1
	_registerMessage(key, msgs, callback)
	return setmetatable({key=key, msgs=msgs}, listenerKeyMeta)
end

function Message.unregisterMessageListenerByKey(key)
	return _unregisterMessage(key.key, key.msgs)
end

return Message