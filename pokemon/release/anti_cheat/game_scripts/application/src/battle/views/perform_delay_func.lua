
require "battle.views.manage_cd"

local PerformDelayFunc = class("PerformDelayFunc")
globals.PerformDelayFunc = PerformDelayFunc

function PerformDelayFunc:ctor(delayTime, func, args)
	self.startCd = CManageCd.new(delayTime)
	self.func = func
	self.args = args
	self.processOver = false
end

--使命是否结束
function PerformDelayFunc:isOver()
	if self.processOver then
		return true
	end
	return false
end

function PerformDelayFunc:update(delta)
	self.startCd:update(delta)
	if self.startCd:isCdOk() then
		self.processOver = true
		if self.args then
			self.func(unpack(self.args))
		else
			self.func()
		end
	end
end