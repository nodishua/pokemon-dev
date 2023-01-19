--
--

local CManageCd = class("CManageCd")
globals.CManageCd = CManageCd

function CManageCd:ctor(cdTime,cdCountLimit)
	self.tick = 0
	self.cdTime = cdTime
	self.cdCountLimit = cdCountLimit or 9999999
	self.cdCount = 0
end

function CManageCd:CdOk()
	self.tick = self.cdTime
end

function CManageCd:isCdOk()
	if self.cdCount < self.cdCountLimit and self.tick >= self.cdTime then
		return true
	end
	return false
end

function CManageCd:reset(cdTime,cdCountLimit)
	self.tick = 0
	self.cdTime = cdTime
	self.cdCountLimit = cdCountLimit or 9999999
	self.cdCount = 0
end

function CManageCd:start(cdTime)
	self.cdTime = cdTime or self.cdTime
	self.tick = 0
	self.cdCount = self.cdCount + 1
end

function CManageCd:update(cdDelta)
	self.tick = self.tick + cdDelta
end

function CManageCd:nextDelta()
	if self:isCdOk() then
		return 0
	end
	return self.cdTime - self.tick
end