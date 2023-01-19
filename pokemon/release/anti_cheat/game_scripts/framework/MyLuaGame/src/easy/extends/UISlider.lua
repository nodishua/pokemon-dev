--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2017 TianJi Information Technology Inc.
--
-- ccui.Slider原生类的扩展
--

local Slider = ccui.Slider

function Slider:percent(p)
	-- getter
	if p == nil then
		return self:getPercent()
	-- setter
	else
		self:setPercent(p)
		return self
	end
end

