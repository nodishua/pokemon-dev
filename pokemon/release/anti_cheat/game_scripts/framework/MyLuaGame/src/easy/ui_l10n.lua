--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2017 TianJi Information Technology Inc.
--
-- 主要是进行多语言版本的UI本地化翻译
--

local config = nil

-- @param node: cocos2dx node
function globals.translateUI(node)
	if config == nil then
		local path = "app.defines.l10n." .. LOCAL_LANGUAGE
		xpcall(function() config = require(path) end, function()
			printWarn('not exist ' .. path)
			config = false
		end)
	end
	-- cocos2dx_lua_loader may be no raise any error
	if config == false or config == nil then
		return
	end
	local function translateStr(object, getMethod, setMethod)
		if getMethod then
			local val = config[getMethod(object)]
			if val then
				setMethod(object, val)
			end
		end
	end

	local function translateAll(object)
		for _, child in pairs(object:getChildren()) do
			translateStr(child, child.getString, child.setString)
			-- translateStr(child, child.getStringValue, child.setText)
			translateStr(child, child.getPlaceHolder, child.setPlaceHolder)
			translateStr(child, child.getTitleText, child.setTitleText)
			translateAll(child)
		end
	end
	translateAll(node)
end
