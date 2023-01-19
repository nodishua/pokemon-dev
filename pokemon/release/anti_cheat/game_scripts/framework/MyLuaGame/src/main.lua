--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2017 TianJi Information Technology Inc.
--
-- 主入口
--
print("Game Main working...")

require "exception_handler"
require "battle_report"

local lastLuaExceptionMsg
function __G__TRACKBACK__(exceptionMsg)
	local msg = string.format("[%d] %s\n", handleLuaExceptionIdx, tostring(exceptionMsg))
	local str = "LUA ERROR: " .. msg
	setLogColor(CONSOLE_COLOR.Light_Red)
	print("----------------------------------------")
	print(str)
	print(debug.traceback())
	print("----------------------------------------")
	if device.platform == "windows" then
		tracebackWithCode()
		print("----------------------------------------")
	end
	setLogColor(CONSOLE_COLOR.Default)

	-- 若报错信息与上一条相同，忽略显示
	if lastLuaExceptionMsg == exceptionMsg then
		return
	end
	lastLuaExceptionMsg = exceptionMsg
	triggerBattleReport("crash:"..str, debug.traceback())
	handleLuaException(msg)
	if DEBUG > 1 then
		-- 正式线上不显示详细信息
		str = str .. debug.traceback() .. "\n"
	end
	gGameUI:showDialogModel({
		title = gLanguageCsv.raise_exception,
		content = str,
		align = "left",
		fontSize = 30,
		dialogParams = {clickClose = false},
	})
end

function __G__GCCOUNT__()
	return collectgarbage("count")
end

local function main()
	require "lib"

	sdk.trackEvent(1)

	-- for win args
	if device.platform == "windows" then
		local fp = io.open(".args", "rb")
		local data = fp:read('*a')
		fp:close()

		require "json"
		globals.MainArgs = json.decode(data)

		print('MainArgs', dumps(MainArgs))
	end

	-- for debug log
	cc.FileUtils:getInstance():setPopupNotify(true)
	if device.platform == "windows" or APP_CHANNEL == "none" then
		DEBUG = 2
		CC_SHOW_FPS = true
	else
		log.disable()
	end
	if device.platform ~= "windows" then
		EDITOR_ENABLE = false
	end
	print("DEBUG", DEBUG)
	log.log("log is enabled")
	printDebug("printDebug is enabled")
	printInfo("printInfo is enabled")

	-- gc
	print("gc stop", collectgarbage("stop"))

	require("app.game_app"):create():run("login.view")

	if MainArgs and MainArgs.robot then
		cc.FileUtils:getInstance():addSearchResolutionsOrder("robot")
		require "robot.main"
	end

	-- TEST: FPS no limit, and also disable vsync in your gpu controller
	-- cc.Director:getInstance():setAnimationInterval(0.0001)
	-- TEST: disable dirty draw optimize mode
	-- cc.Director:getInstance():setDirtyDrawEnable(false)
	-- TEST: to see which sprite in hierarchy batch mode
	-- cc.Director:getInstance():setHierarchyDebugDraw(true)
end

local status, msg = xpcall(main, __G__TRACKBACK__)
if not status then
	print('xpcall game main error', status, msg)
end

