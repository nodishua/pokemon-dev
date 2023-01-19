--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2017 TianJi Information Technology Inc.
--
-- label辅助
--

globals.label = {}

-- @param params: {pos, anchorPoint, fontPath, fontSize, color, effect}
function label.create(str, params)
	params = params or {}
	local anchorPoint = params.anchorPoint or cc.p(0.5, 0.5)
	local fontPath = params.fontPath or ui.FONT_PATH
	local fontSize = params.fontSize or ui.FONT_SIZE
	local pos = params.pos or cc.p(0,0)
	local obj = cc.Label:createWithTTF(str, fontPath, fontSize)
	obj:setAnchorPoint(anchorPoint)
	obj:setPosition(pos)
	if params.color then
		obj:setTextColor(params.color)
	end
	if params.effect then
		text.addEffect(obj, params.effect)
	else
		text.deleteEffect(obj, "all")
	end
	return obj
end