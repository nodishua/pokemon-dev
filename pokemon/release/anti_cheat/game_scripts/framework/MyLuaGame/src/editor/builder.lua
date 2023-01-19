--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2016 TianJi Information Technology Inc.
--
-- 内置编辑器
--

local ButtonNormal = "img/editor/btn_1.png"
local ButtonClick = "img/editor/btn.png"
local FontName = ui.FONT_PATH
-- local FontName = 'Times New Roman'
-- local FontName = '宋体'

local editor = {}
local iupeditor

function editor:init(scene)
	print('editor:init', self.poco, self.node)
	self.poco = nil
	if scene:getChildByName("_editor_") == nil then
		self.scene = scene
		scene.clientEditor = self
		local node = cc.Node:create()
		self.scene:addChild(node, 99999999, "_editor_")
		self.node = node
		self.itemIndex = 1
		self:initUI()
		self:initLuaLoaded()

		local ffi = require("ffi")
		if ffi.os == "Windows" then
			iupeditor = require("editor.win32.builder")
			iupeditor:init(scene)
			editor.iupeditor = iupeditor
		end

		-- self:onCSpriteStats() -- test
	end
end

function editor:getNextFlowPosition()
	local size = cc.size(0, 0)
	local maxHeight = 0
	for i = 1, self.itemIndex - 1 do
		local item = self.node:getChildByName("btnPanel"):getChildByTag(i)
		local itemSize = item:getContentSize()
		itemSize.width = itemSize.width * item:getScaleX()
		itemSize.height = itemSize.height * item:getScaleY()
		maxHeight = math.max(maxHeight, size.height + itemSize.height)
		size.width = size.width + itemSize.width
		if size.width > display.width then
			size.width = 0
			size.height = maxHeight
		end
	end
	return size.width, -size.height
end

function editor:addTestButton(txt, handleName, doubleClickDuration)
	local btn = ccui.Button:create(ButtonNormal, ButtonClick)
	btn:setTitleText(txt)
	btn:setTitleFontSize(20)
	-- btn:setOpacity(100)
	btn:setPressedActionEnabled(true)
	local lastClickTime = 0
	btn:addClickEventListener(function()
		local function callback()
			print('editor:' .. handleName)
			self[handleName](self, btn)
		end
		if doubleClickDuration then
			local nowTime = os.time()
			if nowTime - lastClickTime > doubleClickDuration then
				lastClickTime = nowTime
				self:addTipLabel(string.format("%d秒内再次点击生效", doubleClickDuration), "_reloadlua_draw_")
			else
				lastClickTime = 0
				callback()
			end
		else
			callback()
		end
	end)

	local x, y = self:getNextFlowPosition()
	x, y = x + self.uiOffset.x, y + self.uiOffset.y
	local size = btn:getContentSize()
	local node = cc.Node:create()
	node:addChild(btn)
	node:setScale(2.4)
	node:setPosition(x + size.width/2, y - size.height/2)
	node:setContentSize(size.width, size.height)
	self.node:getChildByName("btnPanel"):addChild(node, 0, self.itemIndex)
	self.itemIndex = self.itemIndex + 1
	return btn
end

function editor:initPoco()
	-- local airtest poco
	if self.poco == nil then
		local poco = require('editor.poco.poco_manager')
		-- default port number is 15004, change to another if you like
		poco:init_server(15004)
		self.poco = poco
	end
end

function editor:initUI()
	self.uiOffset = cc.p(100, 100)

	local btn = ccui.Button:create(ButtonNormal, ButtonClick)
	btn:setTitleText("内置编辑器")
	btn:setTitleFontSize(20)
	btn:setOpacity(100)
	btn:setPressedActionEnabled(true)
	btn:setScale(1)
	btn:setPosition(cc.p(300 + display.uiOrigin.x, display.height - 100))
	self.node:addChild(btn)
	local showBtnPanel = false

	if MainArgs and MainArgs.poco then
		self:initPoco()
	end

	btn:addClickEventListener(function()
		self:initPoco()

		btn:runAction(cc.Sequence:create(
			cc.CallFunc:create(function()
				btn:setVisible(false)
			end),
			cc.DelayTime:create(1),
			cc.CallFunc:create(function()
				btn:setVisible(true)
			end)
		))
		showBtnPanel = not showBtnPanel
		self.node:getChildByName("btnPanel"):setVisible(showBtnPanel)
	end)

	local btnPanel = ccui.Layout:create()
	btnPanel:setAnchorPoint(cc.p(0, 0))
	btnPanel:setPosition(cc.p(300 + display.uiOrigin.x, display.height - 100))
	btnPanel:setContentSize(cc.size(1200, 300))
	btnPanel:setTouchEnabled(false)
	btnPanel:setVisible(false)
	btnPanel:setName("btnPanel")
	-- btnPanel:setBackGroundColorType(1)
	-- btnPanel:setBackGroundColor(cc.c3b(150, 0, 0))
	btnPanel:setScale(2/3)
	self.node:addChild(btnPanel)


	self:addTestButton("CSV刷新", "onReloadCsv", 5)
	self:addTestButton("LUA热更新", "onReloadLua")
	self:addTestButton("Node定位", "onNodeLocate")
	self:addTestButton("仅定位spine", "onSpineLocate")
	self:addTestButton("战斗定位", "onBattleLocate")

	self.uiOffset = cc.p(100, -50)
	self.itemIndex = 1
	self:addTestButton("保存战斗", "onBattleSave")
	self:addTestButton("加载战斗", "onBattleLoad")
	self:addTestButton("加载王者", "onCraftBattleLoad")
	self:addTestButton("战斗回归测试", "onBattleTest")

	self.uiOffset = cc.p(100, -200)
	self.itemIndex = 1
	self:addTestButton("显示绑定", "onShowBind")
	self:addTestButton("执行脚本", "onRunLua")
	self:addTestButton("开始Profile", "onProfile")
	self:addTestButton("开始LuaDebug", "onLuaDebug")
	self:addTestButton("CSprite统计", "onCSpriteStats")

	self.uiOffset = cc.p(100, -350)
	self.itemIndex = 1
	self:addTestButton("内网开发命令", "onCheatRequest")
	-- self:addTestButton("实时匹配", "onSyncFight") -- 废弃
end


function editor:visitChangedFiles(dir, cb)
	if not dir then
		return
	end
	local fs = require "editor.fs"
	local files = fs.listAllFiles(dir, function (name)
		return name:match("%.lua$")
	end, true)

	for name, time in pairs(files) do
		local old = self.luaModifyTimes[name]
		if old == nil or old[1] ~= time[1] or old[2] ~= time[2] then
			self.luaModifyTimes[name] = time
			cb(name)
		end
	end
end

function editor:initLuaLoaded()
	if self.luaModifyTimes then return end
	local targetPlatform = cc.Application:getInstance():getTargetPlatform()
	if cc.PLATFORM_OS_WINDOWS ~= targetPlatform then return end
	self.luaModifyTimes = {}

	package.path = string.format("%s%s?.lua;%s?.lua", package.path, 'src/', 'cocos/')
	self:visitChangedFiles("./src", function() end)
end

function editor:onReloadCsv()
	-- os.execute("cd ..\\..\\tools\\csv2lua\\ && python csv2lua_dev.py")
	-- os.execute("xcopy ..\\..\\tools\\csv2lua\\config\\*.* .\\src\\config\\ /e /y")

	os.execute(string.format("..\\..\\tools\\csv2lua\\csv2src.exe --input=../../config/game_dev --output=./src/config --language %s", LOCAL_LANGUAGE))
	print('gen csv2lua ok')

	self:onRefreshCsv()
end

local function _setDefalutMeta(t)
	local strsub = string.sub
	for k, v in pairs(t) do
		if type(k) == 'string' and type(v) == 'table' then
			if strsub(k, 1, 2) ~= '__' then
				print (k,v)
				_setDefalutMeta(v)
			end
		elseif t.__default and type(k) == 'number' and type(v) == 'table' then
			setmetatable(v, t.__default)
		end
	end
end

function editor:onRefreshCsv()
	csv = table.getraw(csv)
	local backupYunying = clone(csv.yunying)

	-- local changed = {}
	-- self:visitChangedFiles("./src/config", function(name)
	-- 	local luaname = name:sub(7, #name-4):gsub("/", ".")
	-- 	if luaname == "config.csv" then
	-- 		return
	-- 	end

	-- 	package.loaded[luaname] = nil
	-- 	-- require(luaname)
	-- 	print('reload', luaname)
	-- 	-- table.insert(changed, luaname)
	-- end)

	-- 配表动态加载
	for k, v in pairs(package.loaded) do
		if string.find(k, "^config") then
			print("reload clear", k, package.preload[k])
			package.loaded[k] = nil
			package.preload[k] = nil
		end
	end

	package.loaded["app.defines.config_defines"] = nil
	require("app.defines.config_defines")

	csv.yunying = backupYunying
	-- _setDefalutMeta(csv)

	self:visitChangedFiles("./src/config", function() end)

	-- 有缓存道具配表
	package.loaded["app.easy.data"] = nil
	require("app.easy.data")

	-- local list = table.concat(changed, "\n")
	local list = "csv reload ok"
	self:addTipLabel(list, "_reloadcsv_draw_")
end

local preStack
function editor:onNodeLocate()
	local eventDispatcher = display.director:getEventDispatcher()
	self.locateEnabled = not self.locateEnabled
	if not self.locateEnabled and iupeditor then
		iupeditor:hideNodesStack()
	end
	if self.locateListner then
		self.node:removeChildByName("_locate_draw_")
		return
	end

	local function dfs(deep, node, pos)
		local all = {}
		local childs = node:getChildren()
		for i = #childs, 1, -1 do
			local child = childs[i]
			if child ~= self.node and child:isVisible() then
				local ret, path = dfs(deep + 1, child, pos)
				if ret then
					-- all = itertools.merge({all, path})
					table.insert(path, node)
					return true, path
				end
			end
		end

		-- ignore cc.Node and cc.Layer and ccui.Layout
		local ty = tolua.type(node)
		if self.onlyLocateSpine then
			if ty ~= "sp.SkeletonAnimation" then
				return false
			end
		else
			if ty == "cc.Node" or ty == "cc.Layer" or ty == "ccui.Layout" or ty == "sp.SkeletonAnimation" then
				return false
				-- return true, all
			end
		end


		-- if node.hitTest and node:hitTest(pos) then
		-- 	-- print('!!! hit', deep, node:getLocalZOrder(), tostring(node), tolua.type(node))
		-- 	return true, {node}
		if node:getParent() then
			local box = node:getBoundingBox()
			local lpos = node:getParent():convertToNodeSpace(pos)
			if cc.rectContainsPoint(box, lpos) then
				-- print('!!! inbox', deep, node:getLocalZOrder(), tostring(node), tolua.type(node), lpos.x, lpos.y, box.x, box.y, box.width, box.height)
				return true, {node}
				-- return true, itertools.merge({all, {node}})
			end
		end
		return false
		-- return true, all
	end

	local listener = cc.EventListenerMouse:create()
	local stack = ""
	listener:registerScriptHandler(function(event)
		if not self.locateEnabled then return end
		-- print('------move')
		local x, y = event:getCursorX(), event:getCursorY()
		local ret, path = dfs(1, self.scene, cc.p(x, y))
		self.node:removeChildByName("_locate_draw_")
		if ret then
			local node = cc.Node:create()
			self.node:addChild(node, 0, "_locate_draw_")
			stack = ""
			for i = 1, #path - 1 do
				local child = path[i]
				local draw = self:getDebugBox(child, string.format("%d", i), cc.c4f(1 - i / #path, i / #path, 0, 1 - i / #path))

				stack = stack .. string.format("%d_%s_%s_%s\n", i, tolua.type(child), child:getTag(), child:getName())
				node:addChild(draw, #path - i)
			end

			-- local label = cc.Label:createWithTTF(stack, FONT_PATH, 16)
			-- label:setTextColor(cc.c4b(255, 255, 255, 50))
			-- label:enableOutline(cc.c4b(0, 0, 0, 255), 1)
			-- label:setAnchorPoint(0, 0)
			-- node:addChild(label)

			if iupeditor and stack ~= preStack then
				iupeditor:showNodesStack(path, function()
					self.locateEnabled = false
					if self.locateListner then
						self.node:removeChildByName("_locate_draw_")
						return
					end
				end, function(idx)
					local child = path[idx]
					self.node:removeChildByName("_highlight_draw_")
					local draw = self:getDebugBox(child, string.format("%d", idx), cc.c4f(1, 1, 1, 1), 4)
					self.node:addChild(draw, 0, "_highlight_draw_")
					draw:runAction(cc.Sequence:create(
						cc.DelayTime:create(2),
						cc.CallFunc:create(function()
							draw:removeFromParent()
						end)
					))
				end)
			end
			preStack = stack
		end
	end, cc.Handler.EVENT_MOUSE_MOVE)

	listener:registerScriptHandler(function(event)
		if not self.locateEnabled then return end
		local statusLines = string.split(stack, "\n")
		local genString = "self.node."
		local name = ""
		for i = 1, #statusLines do
			local line = statusLines[#statusLines + 1 - i]
			if string.find( line, "name:" ) and not string.find(line, ".json") then
				_, _, name = string.find(line, "name:(.-) ")
				genString = genString..name.."."
			end
		end
		genString = string.sub(genString, 1, -2)
		local handle = io.popen("set /p=\""..genString.."\"<nul | clip")
		handle:close()
	end, cc.Handler.EVENT_MOUSE_UP)

	eventDispatcher:addEventListenerWithFixedPriority(listener, -1)
	self.locateListner = listener
end

function editor:onSpineLocate(btn)
	self.onlyLocateSpine = not self.onlyLocateSpine
	if self.onlyLocateSpine then
		btn:setTitleText("不定位spine")
	else
		btn:setTitleText("仅定位spine")
	end
end

function editor:onReloadLua()
	local changed = {}
	self:visitChangedFiles("./src", function(name)
		local luaname = name:sub(7, #name-4):gsub("/", ".")
		table.insert(changed, luaname)
	end)
	self:visitChangedFiles(dev.DEV_PATH, function(name)
		local luaname = name:sub(7, #name-4):gsub("/", ".")
		luaname = luaname:sub(luaname:find("%.")+1)
		if luaname:find("^src%.") then
			luaname = luaname:sub(5)
		end
		if not luaname:find("app.defines") then
			table.insert(changed, luaname)
		end
	end)

	local list = ""
	local csvChanged = false
	for i, path in ipairs(changed) do
		print(i, path, package.loaded[path], package.preload[path], 'lua changed!!!')
		-- 删除src.zip时用的preload默认加载器，否则require不会读取本地文件
		package.preload[path] = nil
		if package.loaded[path] then
			if not path:find("^config") then
				package.loaded[path] = nil
				require(path)
			else
				csvChanged = true
			end
			list = list .. string.format("%2d %s\n", i, path)
		end
	end
	if csvChanged then
		self:onRefreshCsv()
	end

	-- special for adventure
	package.loaded["app.views.city.adventure.pve"] = nil
	package.loaded["app.views.city.adventure.pvp"] = nil

	-- refresh battle loaded file
	for k, v in pairs(package.loaded) do
		if k:find("^battle") or k:find("^app.views.battle") then
			package.loaded[k] = nil
			-- print(k, "reload")
		end
	end

	self:addTipLabel(list, "_reloadlua_draw_")
end

function editor:addTipLabel(txt, tagName)
	self.node:removeChildByName(tagName)
	if txt == "" then return end

	local label = cc.Label:createWithTTF(txt, FontName, 90)
	label:setPosition(display.sizeInView.width / 2, display.sizeInView.height / 2)
	label:setTextColor(cc.c4b(255, 0, 0, 100))
	label:enableOutline(cc.c4b(0, 0, 0, 255), 3)
	self.node:addChild(label, 0, tagName)
	performWithDelay(label, function()
		self.node:removeChildByName(tagName)
	end, 6)
end

function editor:getDebugBox(child, text, color, lineWidth, textColor)
	return tjuidebug.getDebugBox(child, text, color, lineWidth, textColor)
end

local function dfsvis(node, visible)
	if node == nil then return true end
	if visible[node] ~= nil then return visible[node] end
	if not node:isVisible() then return false end
	visible[node] = dfsvis(node:getParent(), visible)
	return visible[node]
end

function editor:onShowBind()
	local dispatcher = display.director:getEventDispatcher()
	if self.bindListner then
		self.node:removeChildByName("_show_bind_")
		dispatcher:removeEventListener(self.bindListner)
		self.bindListner = nil
		return
	end

	local bindNode = cc.Node:create()
	self.node:addChild(bindNode, 0, "_show_bind_")
	local draws, visible = {}, {}
	traverseBindNode(function(node, name)
		-- dfsvis(node, visible) and
		if  node:isVisible() and node:getParent() then
			if name:match("bind") then
				name = name:sub(6, -2)
			end
			local c4f = cc.c4f(math.random(), math.random(), math.random(), 1)
			local draw = self:getDebugBox(node, name, c4f, 1, cc.convertColor(c4f, "4b"))
			-- node:addChild(draw) ?? no show
			table.insert(draws,  {node = node, draw = draw})
		end
	end)
	for _, draw in ipairs(draws) do
		bindNode:addChild(draw.draw)
		draw.draw:get("label"):hide()
	end

	local listener = cc.EventListenerMouse:create()
	listener:registerScriptHandler(function(event)
		local x, y = event:getCursorX(), event:getCursorY()
		local pos = cc.p(x, y)
		for _, xx in ipairs(draws) do
			if not tolua.isnull(xx.node) and xx.node:getParent() then
				local box = xx.node:getBoundingBox()
				local lpos = xx.node:getParent():convertToNodeSpace(pos)
				if cc.rectContainsPoint(box, lpos) then
					xx.draw:get("label"):show()
				else
					xx.draw:get("label"):hide()
				end
			end
		end
	end, cc.Handler.EVENT_MOUSE_MOVE)
	dispatcher:addEventListenerWithFixedPriority(listener, -1)
	self.bindListner = listener
end

local profileBeginCallbacks = {}
local profileEndCallbacks = {}
function globals.onEditorProfile(bfunc, efunc)
	table.insert(profileBeginCallbacks, bfunc)
	table.insert(profileEndCallbacks, efunc)
end

local profileBegin = false
local ProFi = require '3rd.ProFi'
function editor:onProfile()
	if profileBegin then
		ProFi:stop()
		ProFi:writeReport('MyProfilingReport.txt')
		for _, f in ipairs(profileEndCallbacks) do
			f()
		end
		profileBeginCallbacks, profileEndCallbacks = {}, {}
		self:addTipLabel("end profile, check MyProfilingReport.txt", "_profile_draw_")
	else
		self:addTipLabel("begin profile", "_profile_draw_")
		for _, f in ipairs(profileBeginCallbacks) do
			f()
		end
		ProFi:start()
	end
	profileBegin = not profileBegin
end

function editor:onLuaDebug()
	require("luaide.LuaDebug")("localhost", 7003)
end

local lastCheckMsg = nil
function editor:onCheatRequest()
	if self.node:getChildByName("_cheat_request_") then
		self.node:removeChildByName("_cheat_request_")
		return
	end
	if gGameUI.rootViewName ~= "city.view" then
		self:addTipLabel("must in city.view!", "_battlesave_draw_")
		return
	end

	local panel = ccui.Layout:create()
	panel:setContentSize(cc.size(0, 0))
	panel:setPosition(cc.p(display.cx + display.uiOrigin.x, display.cy))

	-- 服务器快捷请求列表
	local allFiles = require("app.editor.cheat_request_files")
	local files = allFiles.default
	for name, data in pairs(allFiles) do
		if name ~= "default" then
			if gGameUI.guideManager:findNodeByName(gGameUI.scene, nil, name) then
				print("onCheatRequest in:", name)
				files = data
				break
			end
		end
	end

	local list = ccui.ListView:create()
	list:setAnchorPoint(cc.p(0.5, 0.5))
	list:setContentSize(cc.size(1750, 900))
	list:setBackGroundColorType(ccui.LayoutBackGroundColorType.solid)
	list:setBackGroundColor(cc.c3b(0, 0, 0))
	list:setBackGroundColorOpacity(150)
	-- list:setGravity(ccui.ListViewGravity.centerHorizontal)
	list:setItemsMargin(5)
	for _, data in ipairs(files) do
		local text = ccui.Text:create(string.format("    %-25s\t%s", data.key, data.desc), FONT_PATH, 72)
		text:getVirtualRenderer():setTextColor(cc.c4b(0, 255, 0, 200))
		text:enableOutline(cc.c4b(0, 0, 0, 255), 3)
		-- text:setTouchScaleChangeEnabled(true)
		text:setTouchEnabled(true)
		text:addTouchEventListener(function(sender, eventType)
			if eventType == ccui.TouchEventType.began then
				text:scale(1.05)

			elseif eventType == ccui.TouchEventType.ended then
				text:scale(1)
				self.node:removeChildByName("_cheat_request_")
				gGameApp:requestServer("/game/cheat", nil, data.key)

			elseif eventType == ccui.TouchEventType.canceled then
				text:scale(1)
			end
		end)
		list:pushBackCustomItem(text)
	end
	panel:addChild(list, 0)

	-- 自定义请求
	local input = ccui.EditBox:create(cc.size(600, 100), "img/editor/input.png")
	input:setPosition(cc.p(0, -500))
	input:setFontSize(72)
	input:setFontColor(ui.COLORS.NORMAL.DEFAULT)
	if lastCheckMsg then
		input:setText(lastCheckMsg)
	end
	panel:addChild(input, 1)
	local btn = ccui.Button:create(ButtonNormal, ButtonClick)
	btn:setTitleText("自定义请求")
	btn:setTitleFontSize(20)
	btn:setPosition(cc.p(0, -600))
	btn:setScale(2)
	btn:addClickEventListener(function()
		local msg = input:getText()
		print("/game/cheat msg is: ", msg)
		if msg ~= "" then
			lastCheckMsg = msg
			self.node:removeChildByName("_cheat_request_")
			gGameApp:requestServer("/game/cheat", nil, msg)
		else
			self:addTipLabel("msg is empty!", "_battlesave_draw_")
		end
	end)
	panel:addChild(btn, 2)

	self.node:removeChildByName("_cheat_request_")
	self.node:addChild(panel, 0, "_cheat_request_")
end

local battleModule = require "editor.battle"
for k, v in pairs(battleModule) do
	editor[k] = v
end

local runModule = require "editor.run"
for k, v in pairs(runModule) do
	editor[k] = v
end

local statsModule = require "editor.stats"
for k, v in pairs(statsModule) do
	editor[k] = v
end

--[[
function editor:onSyncFight()
	-- gGameApp.net:doRealtime('192.168.1.96', 1234, {battle_cards={761, 0,0,0,0,0, 1981, 0,0,0,0,0}, solo=true}, function(ret, err)
	gGameApp.net:doRealtime('192.168.1.96', 1234, {battle_cards={761, 0,0,0,0,0}, solo=true}, function(ret, err)
		if ret then
			print_r(ret)
			local battleData = gGameModel.battle:getData()
			print("!!!!!!!!!!!!!!",gGameModel,dump(battleData,nil,999))
			-- battleData.gateType = game.GATE_TYPE.test
			battleData.operateForce = ret.operate_force
			local t = {
				_data = battleData,
				_modes = {baseMusic = "battle1.mp3"},
			}
			battleEntrance._switchUI(t, function()
				local t = {
					_results = {},
					_onResult = function(data, results)
						gGameApp.net:doRealtimeEnd()
						performWithDelay(gRootViewProxy:raw(), function()
							gGameUI:switchUI("city.view")
						end, 0)
					end,
					_isTestScene = true,
				}
				-- battleEntrance._localHack.postEndResultToServer(t)
				gRootViewProxy:raw().showEndView = t._onResult
				battleEntrance._localHack.showEndView(t)
				-- performWithDelay(gRootViewProxy:raw(), function()
				-- 	local play = gRootViewProxy:raw()._model.scene.play
				-- 	play.OperatorArgs = battlePlay.SyncFightGate.OperatorArgs
				-- 	play:initFightOperatorMode()
				-- end, 1)
				-- battleEntrance._localHack.postEndResultToServer(t)
			end)
		end
		if err then
			gGameUI:showTip(err.err)
		end
	end)
end
]]--

return editor