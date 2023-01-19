--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2017 TianJi Information Technology Inc.
--
-- Widget缓存
--

local WidgetCache = {}

local guiReader = ccs.GUIReader:getInstance()
local textureCache = display.director:getTextureCache()


function WidgetCache.getWidget(res)
-- cc.CSLoader:createNode(resourceFilename)
	-- cocos studio 1.6
	local raw = guiReader:widgetFromJsonFile(res)
	translateUI(raw)
	-- adaptBtnTitle(raw)
	adaptUI(raw, res)
	return raw
end

return WidgetCache