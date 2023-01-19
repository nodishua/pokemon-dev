--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2017 TianJi Information Technology Inc.
--
-- ccui.LoadingBar原生类的扩展
--

local LoadingBar = ccui.LoadingBar

function LoadingBar:percent(p)
	-- getter
	if p == nil then
		return self:getPercent()
	-- setter
	else
		self:setPercent(p)
		return self
	end
end

