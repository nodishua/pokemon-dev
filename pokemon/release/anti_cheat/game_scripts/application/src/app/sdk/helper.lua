--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2019 TianJi Information Technology Inc.
--
-- sdk helper
--


-- 当前运行平台
local targetPlatform = cc.Application:getInstance():getTargetPlatform()

-- @params bundle: data string, may be was json encoded
function sdk.callPlatformFunc(funcName, bundle, callback)
	if ((cc.PLATFORM_OS_IPHONE == targetPlatform) or (cc.PLATFORM_OS_IPAD == targetPlatform)) then
		local luaoc = require "cocos.cocos2d.luaoc"
		luaoc.callStaticMethod("SDKDelegate", "proxy", {
			funcName = funcName,
			bundle = bundle,
			callback = callback
		})
	else
		local luaj = require "cocos.cocos2d.luaj"
		luaj.callStaticMethod("www/tianji/finalsdk/MessageHandler", "msgFromLua", {
			[1] = funcName,
			[2] = bundle,
			[3] = callback
		})
	end
end

-- IMPORTANT:
-- OpenGL context will be lost when enter to background.
-- At this time OpenGL context may not be re-create by Android system.
-- So, please do the operation after it is totally enter foreground.
function sdk.callbackFromSDK(cb)
	performWithDelay(gGameUI.scene, cb, 0)
end

-- @desc 获取电量
function sdk.getBattery(cb)
	if ((cc.PLATFORM_OS_WINDOWS == targetPlatform) or (cc.PLATFORM_OS_IPHONE == targetPlatform) or (cc.PLATFORM_OS_IPAD == targetPlatform)) then
		return cb()
	end
	sdk.callPlatformFunc("getBattery", "data", function(info)
		printInfo("sdk.getBattery back info = %s", info)
		cb(info)
	end)
end

-- @desc 是否是刘海屏 1是 0否
function sdk.isHasNotchScreen(cb)
	if display.isNotchSceen ~= nil then
		cb(display.isNotchSceen)
		return
	end
	sdk.callPlatformFunc("isHasNotchScreen", "data", function(info)
		printInfo("sdk.isHasNotchScreen back info = %s | %s", type(info), info)
		display.isNotchSceen = tonumber(info)
		cb(tonumber(info))
	end)
end

function sdk.isHiddenLoginButton()
	sdk.callPlatformFunc("isHiddenLoginButton", "", function(info)
		if info == "true" then
		end
	end)
end

-- @desc 通知消息设置
-- @params cb 1 true 0 false
function sdk.notification(data, cb)
	local jsonStr = json.encode(data)
	sdk.callPlatformFunc("notification", jsonStr, function(info)
		printInfo("sdk.notification back info = %s", info)
		if cb then
			cb(tonumber(info))
		end
	end)
end
