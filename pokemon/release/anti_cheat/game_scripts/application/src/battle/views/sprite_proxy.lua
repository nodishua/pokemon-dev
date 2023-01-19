--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2016 TianJi Information Technology Inc.
--
-- 与BattleView类似
-- 实现ViewProxy接口
-- 上层代码可以不用区分BattleView和BattleSprite
--

local caption = string.caption

function BattleSprite:onViewProxyNotify(msg, ...)
	log.battle.sprite.notify(self.model.id, msg)
	local fName = 'on' .. caption(msg)
	local f = self[fName]
	if f then
		f(self, ...)
	else
		printWarn('BattleSprite no handler for msg, %s', fName)
	end
end

function BattleSprite:onViewProxyCall(msg, ...)
	log.battle.sprite.call(self.model.id, msg)
	local fName = msg
	local f = self[fName]
	if f then
		return f(self, ...)
	else
		printWarn('BattleSprite no handler for msg %s', fName)
	end
end

function BattleSprite:modelOnly()
	if self.sprite then
		self.sprite:modelOnly()
	end

	self:stopAllActions()
	self:unscheduleUpdate()
end