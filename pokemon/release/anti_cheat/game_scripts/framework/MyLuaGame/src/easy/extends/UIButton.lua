--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2017 TianJi Information Technology Inc.
--
-- ccui.Button原生类的扩展
--

local Button = ccui.Button

function Button:text(s)
	-- getter
	if s == nil then
		return self:getTitleText()
	-- setter
	else
		self:setTitleText(s)
		return self
	end
end

