--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2016 TianJi Information Technology Inc.
--
-- 内置编辑器 - 战斗录像
--

local editor = {}
local _msgpack = require '3rd.msgpack'
local msgpack = _msgpack.pack
local msgunpack = _msgpack.unpack

function editor:onBattleSave()
	if not gGameUI.rootViewName:find("battle.view") then
		self:addTipLabel("no in battle!", "_battlesave_draw_")
		return
	end
	local scene = gGameUI.uiRoot:getSceneModel()
	local sceneID = scene.sceneID or 0
	--local sceneType = scene.sceneType or 0
	local gateType = scene.gateType or 0
	-- print('sceneID', scene.sceneID)
	-- print('sceneType', scene.sceneType)
	-- print('gateType', scene.gateType)
	-- print_r(scene.data)

	-- local oldCrossPvpHistory
	-- if scene.data.crossPvpHistory and scene.data.crossPvpHistory.__class then
	-- 	oldCrossPvpHistory = scene.data.crossPvpHistory
	-- 	scene.data.crossPvpHistory = nil
	-- end

	local filename = string.format("%s_%s_%s.record", sceneID, gateType, os.date("%y%m%d-%H%M%S"))
	-- print('!!! -------- g_game.model.battle.__vars')
	-- print_r(g_game.model.battle.__vars)
	-- local data = g_game.model.battle.__vars

	--local data = {sceneID = sceneID, gateType = gateType, data = scene.data, role = gGameUI.uiRoot.roleData}
	local data = {}
	for k,v in pairs(scene.data) do
		data[k] = v
	end
	data.sceneID = sceneID
	data.gateType = gateType
	data = msgpack(data)
	-- print("+++++++++++++>>>", tostring(filename))
	local fp = io.open(filename, 'wb')
	fp:write(data)
	fp:close()

	-- if oldCrossPvpHistory then
	-- 	scene.data.crossPvpHistory = oldCrossPvpHistory
	-- end

	self:addTipLabel(filename, "_battlesave_draw_")
end

local function readAndUnpack(filename)
	print('load', filename)
	local fp = io.open(filename, 'rb')
	local data
	if fp == nil then
		data = cc.FileUtils:getInstance():getDataFromFile(filename)
	else
		data = fp:read('*a')
		fp:close()
	end
	return msgunpack(data)
end

local function removeInternalTable(t)
	--data读出来会加上__raw和__proxy 这里修下型
	local ret = {}
	for k,v in pairs(t) do
		local hasRaw = false
		local newTb = {}
		if type(v) == "table" then
			for k2,v2 in pairs(v) do
				if k2 == "__raw" then
					hasRaw = true
					for k3,v3 in pairs(v2) do
						if type(v3) == "table" then
							newTb[k3] = removeInternalTable(v3)
						else
							newTb[k3] = v3
						end
					end
				end
			end
		end

		if not hasRaw then
			ret[k] = v
		else
			ret[k] = newTb
		end
	end
	print("###########")
	print_r(ret)
	return ret
end


function editor:onBattleLoad()
	if self.node:getChildByName("_battlelist_") then
		self.node:removeChildByName("_battlelist_")
		return
	end
	local fs = require "editor.fs"
	local files = fs.listAllFiles(".", function (name)
		return name:match("%.play$")
	end, false)

	local list = ccui.ListView:create()
	list:setAnchorPoint(cc.p(0.5, 0.5))
	list:setContentSize(cc.size(1550, 900))
	list:setBackGroundColorType(ccui.LayoutBackGroundColorType.solid)
	list:setBackGroundColor(cc.c3b(0, 0, 0))
	list:setBackGroundColorOpacity(50)
	list:setPosition(display.cx, display.cy)
	list:setItemsMargin(5)
	local idx = 1
	local datas = {}
	for name, time in pairs(files) do
		table.insert(datas, {name = name, time = time})
	end
	table.sort(datas, function(a, b)
		return a.name < b.name
	end)
	for _, v in ipairs(datas) do
		local name = v.name
		local time = v.time

		local menuText = string.format("%2d %s", idx, name)
		local ffi = require("ffi")
		if ffi.os == "Windows" then
			local iconv = require "editor.win32.ansi2unicode"
			menuText = iconv.a2u(menuText)
		end

		local text = ccui.Text:create(menuText, FONT_PATH, 72)
		text:getVirtualRenderer():setTextColor(cc.c4b(0, 255, 0, 255))
		text:enableOutline(cc.c4b(0, 0, 0, 255), 3)
		-- text:setTouchScaleChangeEnabled(true)
		text:setTouchEnabled(true)
		text:addTouchEventListener(function(sender, eventType)
			text:scale((eventType == ccui.TouchEventType.ended or eventType == ccui.TouchEventType.canceled) and 1 or 1.05)
			if eventType == ccui.TouchEventType.ended then
				self.node:removeChildByName("_battlelist_")
				local data = readAndUnpack(name)
				if name:match("%.play$") then
					local playName = data[1]
					if type(data[2]) == 'table' then
						data = data[2]
					else
						data = msgunpack(data[2])
					end
					self:playBattle(playName, data)
					return
				end

				-- local ui = gGameUI:switchUI("battle.view", data.data, data.sceneID)
				-- self:addTipLabel("no in battle!", "_battlesave_draw_", tostring(ui))
				-- ui:initData(data.data, data.sceneID)
				-- ui:setRoleData(data.role) --给战斗结算显示用，与战斗逻辑无关
			end
		end)
		list:pushBackCustomItem(text)
		idx = idx + 1
	end
	self.node:removeChildByName("_battlelist_")
	self.node:addChild(list, 0, "_battlelist_")
end

local readRecordMap
readRecordMap = {
	record = function(name)
		local data = readAndUnpack(name)
		return removeInternalTable(data)
	end,
	recordv2 = function(name)
		local data = readRecordMap.record(name)
		dump(data, "recordv2")
		return removeInternalTable(msgunpack(data.play_record))
	end
}

local function recordCheck(name)
	for k, _ in pairs(readRecordMap) do
		if name:match("%." .. k .. "$") then return true, k end
	end
	return false
end

local function recordGet(name)
	for k, _ in pairs(readRecordMap) do
		if name:match("%." .. k .. "$") then return true end
	end
	return false
end

function editor:onCraftBattleLoad()
	if self.node:getChildByName("_battlelist_") then
		self.node:removeChildByName("_battlelist_")
		return
	end
	local fs = require "editor.fs"
	local files = fs.listAllFiles(".", function (name)
		return recordCheck(name)
	end, false)

	local list = ccui.ListView:create()
	list:setAnchorPoint(cc.p(0.5, 0.5))
	list:setContentSize(cc.size(1550, 900))
	list:setBackGroundColorType(ccui.LayoutBackGroundColorType.solid)
	list:setBackGroundColor(cc.c3b(0, 0, 0))
	list:setBackGroundColorOpacity(50)
	list:setPosition(display.cx, display.cy)
	list:setItemsMargin(5)
	local idx = 1
	local datas = {}
	for name, time in pairs(files) do
		table.insert(datas, {name = name, time = time})
	end
	table.sort(datas, function(a, b)
		return a.name < b.name
	end)

	local result, recordType
	for _, v in ipairs(datas) do
		local name = v.name
		local time = v.time
		-- print("保存的数据信息++++>>>", tostring(name))

		local menuText = string.format("%2d %s", idx, name)
		local ffi = require("ffi")
		if ffi.os == "Windows" then
			local iconv = require "editor.win32.ansi2unicode"
			menuText = iconv.a2u(menuText)
		end

		local text = ccui.Text:create(menuText, FONT_PATH, 72)
		text:getVirtualRenderer():setTextColor(cc.c4b(0, 255, 0, 255))
		text:enableOutline(cc.c4b(0, 0, 0, 255), 3)
		-- text:setTouchScaleChangeEnabled(true)
		text:setTouchEnabled(true)
		text:addTouchEventListener(function(sender, eventType)
			text:scale((eventType == ccui.TouchEventType.ended or eventType == ccui.TouchEventType.canceled) and 1 or 1.05)
			if eventType == ccui.TouchEventType.ended then
				text:scale(1)
				self.node:removeChildByName("_battlelist_")
				result, recordType = recordCheck(name)
				if result and readRecordMap[recordType] then
					self:playCraftBattle(name, readRecordMap[recordType](name))
					return
				end
			end
		end)
		list:pushBackCustomItem(text)
		idx = idx + 1
	end
	self.node:removeChildByName("_battlelist_")
	self.node:addChild(list, 0, "_battlelist_")
end

function editor:onBattleLocate()
	local function onClose()
	end

	local function onSelected()
	end

	if gGameUI.rootViewName:find("battle.view") then
		-- self.iupeditor:showBattleStackOutside(gGameUI.uiRoot)
		self.iupeditor:showBattleStack(gGameUI.uiRoot, onClose, onSelected)
	end
end

function editor:onBattleTest()
	local fs = require "editor.fs"
	local records = fs.listAllFiles("../battle_testcase", function (name)
		return name:match("%.record$")
	end, false)
	local plays = fs.listAllFiles("../battle_testcase", function (name)
		return name:match("%.play$")
	end, false)

	local fp
	local printInfo_ = printInfo
	fp = io.open(string.format("battle_testcase_%s.log", os.date("%y%m%d-%H%M%S")), "wb")
	local function log(...)
		print(...)
		if fp then
			local s = table.concat({...}, "\t")
			fp:write(s)
			fp:write("\n")
		end
	end
	printInfo = function(fmt, ...)
		printInfo_(fmt, ...)
		if fp then
			fp:write(string.format(fmt, ...))
		end
	end
	local printInfoBackup = printInfo

	-- no battleEntrance.unloadConfig for quick
	local oldUnloadConfig = battleEntrance.unloadConfig
	battleEntrance.unloadConfig = function() end

	local errs = {}
	local i = 0
	local nplays = itertools.size(plays)
	local nplayerr = 0
	for filename, _ in pairs(plays) do
		i = i + 1
		log(string.format("====== %d/%d", i, nplays), filename)
		local data = readAndUnpack(filename)
		local playName = data[1]
		if type(data[2]) == 'table' then
			data = data[2]
		else
			data = msgunpack(data[2])
		end

		xpcall(function()
			self:playBattle(playName, data, true)
		end, function(msg)
			printInfo = printInfoBackup
			nplayerr = nplayerr + 1
			table.insert(errs, filename)
			log(string.format("!!!! ====== %d/%d testcase error", i, nplays), filename)
			log(msg)
			log(debug.traceback())
			self:addTipLabel(string.format("[%d/%d] %s error", i, nplays, filename), "_testcase_")
		end)
	end

	i = 0
	local nrecords = itertools.size(records)
	local nrecorderr = 0
	for filename, _ in pairs(records) do
		i = i + 1
		log(string.format("====== %d/%d", i, nrecords), filename)
		local data = readAndUnpack(filename)

		xpcall(function()
			self:playCraftBattle(filename, data, true)
		end, function(msg)
			printInfo = printInfoBackup
			table.insert(errs, filename)
			nrecorderr = nrecorderr + 1
			log(string.format("!!!! ====== %d/%d testcase error", i, nrecords), filename)
			log(msg)
			log(debug.traceback())
			self:addTipLabel(string.format("[%d/%d] %s error", i, nrecords, filename), "_testcase_")
		end)
	end

	-- revert back
	battleEntrance.unloadConfig = oldUnloadConfig

	self:addTipLabel(string.format("%d plays %d error\n%d records %d error", nplays, nplayerr, nrecords, nrecorderr), "_testcase_")
	if #errs then
		log("")
		log("====== error play&records", #errs, "======")
		for i, filename in ipairs(errs) do
			log(i, filename)
		end
		log("")
	end

	if fp then
		fp:close()
	end
	printInfo = printInfo_
end

local function fakeModel()
	-- 假造数据，防止报错
	idlersystem.skipAddIdlerMark(2)
	if gGameModel.role.__idlers == nil then
		gGameModel.role:init({_db = {
			id = "1111111",
			name = 'test',
			level = 1,
			level_exp = 1,
			sum_exp = 1,
			yy_delta = {},
			yy_endtime = 0,
			yyhuodongs = {},
			gate_star = {},
			figures = {},
			pokedex = {},
			logos = {},
			raw_logos = {},
			skins = {},
		}})

		gGameModel.daily_record:init({_db = {
			id = "2222",
			cross_online_fight_times = 0,
		}})

	end
	if gGameModel.capture.__idlers == nil then
		gGameModel.capture:init({_db = {
			limit_sprites = {},
		}})
	end
end

local function showRecord(t)
	if t._preCheck then
		local same = battleEntrance._runBattleModel(t)
		if not same then
			return call(t._onPreCheckFailed)
		end
	end
	local isLoginView = gGameUI.rootViewName == "login.view"
	battleEntrance._switchUI(t, function()
		if isLoginView then
			gRootViewProxy:raw().showEndView = function(data, results)
				performWithDelay(gRootViewProxy:raw(), function()
					gGameUI:switchUI("login.view")
				end, 0)
			end
			gRootViewProxy:call("backToLogin")
		end
		battleEntrance._localHack.postEndResultToServer(t)
	end)
end

-- local callgrindDebug = "view"
-- local proFiDebug = "MyProfilingReport.8s3c.txt"
local memoryDebug = false

-- curl -X POST "https://git.tianji-game.com/api/v4/projects/78/issues/3/notes" --insecure -H  "accept: application/json" -H  "Private-Token: xxxx" -d "body=hello,iamtest"
local gitlabUrl = "https://git.tianji-game.com/api/v4/projects/78/issues/3/notes"
local gitlabToken = nil

function editor:playBattle(name, data, onlyRun)
	print('playBattle', name, onlyRun)

	local battle
	if name == 'craft' then
		battle = require('app.models.craft_battle').new(gGameModel):init(data)
	elseif name == 'arena'then
		battle = require('app.models.arena_battle').new(gGameModel):init(data)
	elseif name == 'cross_arena'then
		battle = require('app.models.cross_arena_battle').new(gGameModel):init(data)
	elseif name == 'gate' then
		if data.gate_id > 100000 then
			battle = require('app.models.endless_battle').new(gGameModel):init(data)
		else
			battle = require("app.models.battle").new(gGameModel):init(data)
		end
		battle.result = "fail"
	elseif name == 'union_fight' then
		battle = require('app.models.union_fight_battle').new(gGameModel):init(data)
	elseif name == 'cross_craft' or name == 'crosscraft' then
		battle = require('app.models.cross_craft_battle').new(gGameModel):init(data)
	elseif name == 'cross_mine' then
		battle = require('app.models.cross_mine_battle').new(gGameModel):init(data)
	elseif name == 'endless' then
		battle = require('app.models.endless_battle').new(gGameModel):init(data)
	elseif name == 'onlinefight' or name == 'cross_online' then
		battle = require('app.models.cross_online_fight_battle').new(gGameModel):init(data)
	elseif name == 'brave_challenge' then
		battle = require('app.models.brave_challenge_battle').new(gGameModel):init(data)
	end

	fakeModel()

	local data = battle:getData()
	if data.preData and data.preData.cardsInfo then
		data.preData.cardsInfo = {}
	end

	-- onlyRun = true -- test

	local result = battle.result or data.result
	local modes = {noShowEndRewards = true}
	if result == "unknown" then
		modes.fromRecordFile = true
	end

	-- [ProFi debug]
	local ProFi
	if proFiDebug then
		ProFi = require '3rd.ProFi'
		ProFi:start()
		ProFi:setCallDeepMode(true)
	end

	local record = battleEntrance.battleRecord(data, result, modes)
	if onlyRun then
		record:run()
	else
		showRecord(record)
		local listenerKey
		listenerKey = gGameUI:registerMessageListener("switchUI", function(name)
			if name == "battle.view" then
				performWithDelay(gGameUI.uiRoot, function()
					local model = gGameUI.uiRoot._model
					local scene = model.scene
					scene:setAutoFight(true)
				end, 1)
				listenerKey:remove()
			end
		end)
	end

	-- [ProFi debug]
	if proFiDebug then
		ProFi:stop()
		ProFi:writeReport(proFiDebug)
	end
end

function editor:loadAndPlayBattle(name, isShow)
	battleEntrance.unloadConfig = function() end

	if name:match("%.play$") then
		local data = readAndUnpack(name)
		local playName = data[1]
		if type(data[2]) == 'table' then
			data = data[2]
		else
			data = msgunpack(data[2])
		end

		self:playBattle(playName, data, not isShow)
	else

		local data = readAndUnpack(name)
		local record = removeInternalTable(data)
		self:playCraftBattle(name, record, not isShow)
	end
end

function editor:playCraftBattle(filename, data, onlyRun)
	print('playCraftBattle', filename, data.gateType, onlyRun)

	fakeModel()

	local printInfo_ = printInfo

	local notes = {}
	local record
	if data.gateType == 'arena' or data.gateType == 'craft' then
		record = battleEntrance.battleRecord(data, data.result, {noShowEndRewards=true})
	else
		record = battleEntrance.battleRecord(data, 'unknown', {fromRecordFile=true})
	end

	-- [callgrind debug]
	local sceneUpdate = SceneModel.update
	if callgrindDebug then
		local callgrind = require("3rd.lua-callgrind")

		SceneModel.update = function(self, ...)
			if self.framesInScene == 100 then
				callgrind.start(callgrindDebug)
			elseif self.framesInScene == 105 then
				callgrind.stop()
				SceneModel.update = sceneUpdate
			end

			return sceneUpdate(self, ...)
		end
	end

	-- [ProFi debug]
	local ProFi
	if proFiDebug then
		ProFi = require '3rd.ProFi'
		ProFi:start()
		ProFi:setCallDeepMode(true)
	end

	-- [memory debug]
	collectgarbage()
	local gc = collectgarbage
	local mem = collectgarbage("count")
	local clock = os.clock()
	if memoryDebug then
		collectgarbage("stop") -- check mem cost
		collectgarbage = function(opt, ...)
			if opt == "count" then
				return gc(opt, ...)
			end
		end
	end

	-- [gitlab]
	if gitlabToken then
		printInfo = function(fmt, ...)
			if fmt:find("result=%%s") then
				table.insert(notes, string.format(fmt, ...))
			end
			return printInfo_(fmt, ...)
		end
	end


	-- run
	if onlyRun then
		record:run()
	else
		showRecord(record)
	end
	record = nil
	table.insert(notes, string.format('playCraftBattle %s cost %.3fs', filename, os.clock() - clock))

	-- [memory debug]
	if memoryDebug then
		collectgarbage = gc

		collectgarbage()
		local curMem = collectgarbage("count")
		print(string.format('playCraftBattle over mem %.2fKB cost %.2fKB %.3fs', curMem, curMem - mem, os.clock() - clock))
		notes[#notes] = string.format('playCraftBattle %s mem %.2fKB cost %.2fKB %.3fs', filename, curMem, curMem - mem, os.clock() - clock)
	end

	-- [ProFi debug]
	if proFiDebug then
		ProFi:stop()
		ProFi:writeReport(proFiDebug)
	end

	-- [gitlab]
	if gitlabToken and (not proFiDebug and not callgrindDebug) then
		local data = table.concat(notes, "\n")
		local xhr = cc.XMLHttpRequest:new()
		xhr.responseType = cc.XMLHTTPREQUEST_RESPONSE_STRING
		xhr.timeout = 20
		xhr:open("POST", gitlabUrl)
		xhr:setRequestHeader("accept", "application/json")
		xhr:setRequestHeader("Private-Token", gitlabToken)
		local function _onReadyStateChange(...)
			print('gitlabToken response:', xhr.status, xhr.response)
		end
		xhr:registerScriptHandler(_onReadyStateChange)
		xhr:send(string.format("body=%s", data))
	end

	printInfo = printInfo_
end
return editor