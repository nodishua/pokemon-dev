--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2017 TianJi Information Technology Inc.
--
-- Created by IntelliJ IDEA.
-- User: Administrator
-- Date: 2015/7/24
-- Time: 16:27
-- To change this template use File | Settings | File Templates.
--
require "ymdump"
EXCEPTION_TAG = "cocos-lua"

local function LuaJavaSendReport_(msg,trace)
	print("Android begin")
	local info = msg.."\r\n"..trace
	local tag = EXCEPTION_TAG
	local args = { info,tag }
	local sigs = "(Ljava/lang/String;Ljava/lang/String;)Z"
	local className = "com/netease/nis/bugrpt/CrashHandler"
	local luaj = require "cocos.cocos2d.luaj"
	local ok,ret = luaj.callStaticMethod(className,"sendReportsBridge",args,sigs)
	if not ok then
		print("luaj error:", ret)
	else
		print("The ret is:", ret)
	end
	print("Android end")
end

LuaJavaSendReport = LuaJavaSendReport_

local function LuaObjectCSendReport_(msg,trace)
	print("IOS begin")
	local params = {
		name = msg,
		stack = trace
	}
	local className = "NTESBugrptInternalInterface"
	local luaoc = require "cocos.cocos2d.luaoc"
	local ok,ret = luaoc.callStaticMethod(className,"sendLuaReportsToServer",params)
	if not ok then
		print("luaj error:", ret)
	else
		print("The ret is:", ret)
	end
	print("IOS end")
end

LuaObjectCSendReport = LuaObjectCSendReport_

local function isPlatformSupportOCBridge()
	local supportObjectCBridge  = false
	local targetPlatform = cc.Application:getInstance():getTargetPlatform()
	if (cc.PLATFORM_OS_IPHONE == targetPlatform) or (cc.PLATFORM_OS_IPAD == targetPlatform) or (cc.PLATFORM_OS_MAC == targetPlatform)  then
		supportObjectCBridge = true
	end
	return supportObjectCBridge
end

local function isPlatformSupportJavaBridge()
	local supportJavaBridge = false
	local targetPlatform = cc.Application:getInstance():getTargetPlatform()
	if (cc.PLATFORM_OS_ANDROID == targetPlatform) then
		supportJavaBridge = true
	end
	return supportJavaBridge
end

local function post2TJCrashCollector(msg, trace)
	local exception = tostring(msg).."\n"..trace
	local reqUrl = string.format("%s/exception?app=%s&patch=%d&min_patch=%d&lang=%s&channel=%s&tag=%s&account=%s&server=%s&role=%s&exception=%s", REPORT_CONF_URL, APP_VERSION, PATCH_VERSION, PATCH_MIN_VERSION, LOCAL_LANGUAGE, APP_CHANNEL, APP_TAG, stringz.bintohex(gGameModel.role:read("account_id")), gGameApp.serverInfo.key, stringz.bintohex(gGameModel.role:read("id")), string.urlencode(exception))
	local reqBody = json.encode({msg = msg, trace = trace})

	local xhr = cc.XMLHttpRequest:new()
	xhr.responseType = cc.XMLHTTPREQUEST_RESPONSE_STRING
	xhr.timeout = 20
	xhr:open("POST", reqUrl)
	xhr:setRequestHeader("Content-Type", "application/x-json")
	local function _onReadyStateChange(...)
		print('handleLuaException response', xhr.status, xhr.response)
	end
	xhr:registerScriptHandler(_onReadyStateChange)
	xhr:send()
end

handleLuaExceptionIdx = 1 -- 自增报错计数

local function handleLuaException_(msg)
	if msg == nil then return end

	-- tw gm迁移, 临时关闭
	if LOCAL_LANGUAGE == "tw" then
		return
	end

	print("handleLuaException begin", isPlatformSupportJavaBridge(), isPlatformSupportOCBridge())
	--
	-- no 163 bugrpt anymore!
	--
	-- if (isPlatformSupportJavaBridge() == true) then
	-- 	--call java function
	-- 	LuaJavaSendReport(tostring(msg), debug.traceback())
	-- elseif (isPlatformSupportOCBridge() == true) then
	-- 	--call oc function
	-- 	LuaObjectCSendReport(tostring(msg), debug.traceback())
	-- end

	-- kr安卓母包有误，使用 cc.XMLHttpRequest 发送异常
	if LOCAL_LANGUAGE ~= "kr" then
		print('--------- ymdump.sendException')
		if handleLuaExceptionIdx == 1 then
			ymdump.sendException(tostring(msg).."\n"..debug.traceback())
		end
	else
		print('--------- post2TJCrashCollector')
		post2TJCrashCollector(tostring(msg), debug.traceback())
	end

	handleLuaExceptionIdx = handleLuaExceptionIdx + 1
	print("handleLuaException end")
end

handleLuaException = handleLuaException_

function errorInWindows(fmt, ...)
	local msg = string.format(tostring(fmt), ...)
	triggerBattleReport("error:"..msg, debug.traceback())
	if device.platform == "windows" then
		error(msg)
	else
		local curIdx = handleLuaExceptionIdx
		msg = string.format("[%d] ", curIdx) .. msg
		printWarnStack(msg)
		handleLuaException_(msg)
		handleLuaExceptionIdx = curIdx
	end
end

function assertInWindows(cond, fmt, ...)
	if device.platform == "windows" then
		local msg = string.format(tostring(fmt), ...)
		assert(cond, msg)
	else
		if not cond then
			local curIdx = handleLuaExceptionIdx
			local msg = string.format(tostring(fmt), ...)
			msg = string.format("[%d] ", curIdx) .. msg
			printWarnStack(msg)
			handleLuaException_(msg)
			handleLuaExceptionIdx = curIdx
			return true
		end
	end
end

function sendExceptionInMobile(s)
	if device.platform == "windows" then
		print(s)
	else
		ymdump.sendException(s)
	end
end