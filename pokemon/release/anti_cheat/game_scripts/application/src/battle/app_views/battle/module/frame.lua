--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2017 TianJi Information Technology Inc.
--

local FramePre = class('FramePre', battleModule.CBase)

function FramePre:ctor(parent)
	battleModule.CBase.ctor(self, parent)

	-- 一帧内要去播放的表现
	self.singleCallCache = {}
	self.keysCache = {}
end

function FramePre:onNewBattleRound(args)
end

function FramePre:onClose()
end

function FramePre:onUpdateOver()
	-- if device.platform == "windows" then
	-- 	if next(self.singleCallCache) then
	-- 		dump(self.singleCallCache)
	-- 	end
	-- end
	self.singleCallCache = {}
end

function FramePre:onSingleCallInFrame(msg, keyMap, filter, data)
	if not self.singleCallCache[msg] then
		self.singleCallCache[msg] = {}
	end

	if table.length(self.singleCallCache[msg]) > 0 then
		local result
		for _, v in ipairs(self.singleCallCache[msg]) do
			result = true
			for _, key in ipairs(keyMap) do
				result = result and filter(data[key], v[key], key)
				if not result then
					break
				end
			end

			if result then
				return false
			end
		end
	end

	table.insert(self.singleCallCache[msg], data)
	return true
end

function FramePre:onFrameOnceEffect(data)
	if not self.keysCache["onceEffect"] then
		self.keysCache["onceEffect"] = itertools.keys(data)
	end
	if self:onSingleCallInFrame('onceEffect', self.keysCache["onceEffect"], function(v1, v2, key)
		if key == "offsetPos" then
			return v1.x == v2.x and v1.y == v2.y
		elseif key == "delay" or key == "lifetime" then
			if v2 == nil and v1 == 0 then return true end
		end
		return v1 == v2
	end, data) then
		self.parent:onEventEffect(nil, 'onceEffect', data)
	end
end

return FramePre