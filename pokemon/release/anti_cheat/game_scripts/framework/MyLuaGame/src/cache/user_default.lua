--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2020 TianJi Information Technology Inc.
--
-- user default相关缓存
--

local KVCache = require "cache.kv"

local UserDefaultCache = class("UserDefaultCache", KVCache)

function UserDefaultCache:ctor()
	self.c = {}
	self.dirty = {}
	self.dirtyVersion = 0
	self.doFlush = handler(self, "flush")
end

function UserDefaultCache:clean()
	self:flush()
	self.c = {}
	self.dirty = {}
end

function UserDefaultCache:setDirty(key, onFlush)
	if self.dirty[key] == nil then
		self.dirty[key] = {count = 0, flush = onFlush}
	end

	local t = self.dirty[key]
	t.count = t.count + 1
	t.flush = onFlush
	self.dirtyVersion = self.dirtyVersion + 1
	-- maybe earlier than scene be created
	gGameUI:callUnessentialInIdle(self.doFlush)
end

function UserDefaultCache:update(key, value, onFlush)
	self:setDirty(key, onFlush)
	return KVCache.update(self, key, value)
end

function UserDefaultCache:flush()
	if self.dirtyVersion == 0 then
		return
	end

	for k, t in pairs(self.dirty) do
		t.flush()
	end
	self.dirty = {}
	self.dirtyVersion = 0
end

return UserDefaultCache

