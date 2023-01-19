--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2018 TianJi Information Technology Inc.
--
-- CSprite缓存
--

local CSpriteCache = class("CSpriteCache")

local spriteCounter = 0

local insert = table.insert
local itertools = itertools


function CSpriteCache:ctor()
	-- 所有创建的资源，包括spine, sprite, plist
	self.autoRelease = {} -- {id=true or false or cb}
	self.lifeMap = {} -- {id={tick, lifetime}}
	self.all = CMap.new()
end

function CSpriteCache:insert(sprite, autoRelease)
	if sprite.spriteID then
		self.autoRelease[sprite.spriteID] = nil
		local inCache = self.all:find(sprite.spriteID)
		if inCache then
			printWarn("%s %d already in cache !!!", tostring(sprite), sprite.spriteID)
			if autoRelease then
				self.autoRelease[spriteID] = true
			end
			return sprite
		end
	end

	spriteCounter = spriteCounter + 1
	local spriteID = spriteCounter
	sprite.spriteID = spriteID
	sprite:retain()
	self.all:insert(spriteID, sprite)
	if autoRelease then
		self.autoRelease[spriteID] = true
	end
	return sprite
end

function CSpriteCache:find(spriteID)
	return self.all:find(spriteID)
end

function CSpriteCache:erase(spriteID, releaseCb)
	-- local sprite = self.all:find(spriteID)
	-- if sprite then
	-- 	self.autoRelease[spriteID] = releaseCb or true
	-- end

	-- 战斗中当帧回收，提高复用
	local sprite = self.all:erase(spriteID)
	if sprite then
		if releaseCb then
			releaseCb()
		end
		-- removeCSprite will be put it in other cache
		sprite:release():removeSelfToCache()
	end
end

function CSpriteCache:clear()
	spriteCounter = 0
	self.autoRelease = {}
	self.lifeMap = {}
	for k, v in self.all:pairs() do
		v:release()
	end
	self.all:clear()
end

function CSpriteCache:setLifeTime(spriteID, time)
	local t = self.lifeMap[spriteID]
	if t == nil then
		t = {0, time}
		self.lifeMap[spriteID] = t
	end
	t[2] = time
end

function CSpriteCache:update(delta)
	if not itertools.isempty(self.autoRelease) then
		for k, flagOrCb in pairs(self.autoRelease) do
			if flagOrCb then
				local sprite = self.all:erase(k)
				if sprite then
					if type(flagOrCb) == "function" then
						flagOrCb()
					end
					-- removeCSprite will be put it in other cache
					sprite:release():removeSelfToCache()
				end
			end
		end
		self.autoRelease = {}
	end

	for k, v in pairs(self.lifeMap) do
		v[1] = v[1] + delta
		if v[1] >= v[2] then -- tick >= time
			self.autoRelease[spriteID] = true
			self.lifeMap[k] = nil
		end
	end
end

return CSpriteCache