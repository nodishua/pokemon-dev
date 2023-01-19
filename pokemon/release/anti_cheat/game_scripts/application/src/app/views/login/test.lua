
local LoginView = {}

local function newButton(s, y)
	local btn = ccui.Button:create("common/btn/btn_normal_red.png")
		:setTitleText(s)
		:setTitleFontSize(48)
		:xy(display.width + display.uiOriginMax.x - 230, y)
		:scale(0.8)
		:opacity(150)
	return btn
end

function LoginView:createTestScene()
	require "battle.models.play.include"

	local y = 800
	local btn = newButton("battle editor", y):addTo(self, 1)
	bind.touch(self, btn, {methods = {ended = function()
		gGameUI:stackUI("city.test.choose_card", nil, {full = true})
	end}})

	y = y - 120
	local btn = newButton("test战斗界面", y):addTo(self, 1)
	bind.touch(self, btn, {methods = {ended = function()
		self:createTestSceneData()
		local data = {
			sceneID = 999999,			-- 测试场景
			gateType = game.GATE_TYPE.test,
			roleOut = csvClone(csv.test_battle),
			randSeed = math.random(1, 1000000),
			moduleType = 1, 	-- 战斗选择类型默认为 1: 常规  2: 全手动
			roleLevel = 1,
			names = {"复仇者联盟", "口袋联盟"},
			preData = {},
		}
		-- only for test battle
		-- hacked some data and func
		local t = {
			_data = data,
			_modes = {baseMusic = "battle1.mp3"},
		}
		battleEntrance._switchUI(t, function()
			local t = {
				_results = {},
				_onResult = function(data, results)
					performWithDelay(gRootViewProxy:raw(), function()
						gGameUI:switchUI("login.view")
					end, 0)
				end,
				isTestScene = true,
			}
			battleEntrance._localHack.postEndResultToServer(t)
			gRootViewProxy:raw().showEndView = t._onResult

			performWithDelay(gRootViewProxy:raw(), function()
				local play = gRootViewProxy:raw()._model.scene.play
				play.OperatorArgs = battlePlay.TestGate.OperatorArgs
				play:initFightOperatorMode()
			end, 1)
			battleEntrance._localHack.postEndResultToServer(t)
			battleEntrance._localHack.showEndView(t)
		end)
	end}})

	y = y - 120
	local btn = newButton("全自动战斗技能测试", y):addTo(self, 1)
	bind.touch(self, btn, {methods = {ended = function()
		self:createTestSceneData()
		local data = {
			sceneID = 999999,			-- 测试场景
			gateType = game.GATE_TYPE.skillTest,
			-- todo
			roleOut = csvClone(csv.skill_auto_test),
			randSeed = math.random(1, 1000000),
			moduleType = 1, 	-- 战斗选择类型默认为 1: 常规  2: 全手动
			roleLevel = 1,
			names = {"复仇者联盟", "口袋联盟"},
			preData = {},
		}
		-- only for test battle
		-- hacked some data and func
		battleEntrance.battleRecord(data, 'unknown', {fromRecordFile=true})
			:run()
	end}})

	y = y - 120
	local btn = newButton("100次战斗模拟", y):addTo(self, 1)
	bind.touch(self, btn, {methods = {ended = function()
		self:createTestSceneData()
		local testTimes = 100
		local winTimes = 0
		local loseTimes = 0
		for i = 1,testTimes do
			local data = {
				sceneID = 999999,			-- 测试场景
				gateType = game.GATE_TYPE.test,
				-- todo
				roleOut = csvClone(csv.test_battle),
				randSeed = math.random(1, 1000000),
				moduleType = 1, 	-- 战斗选择类型默认为 1: 常规  2: 全手动
				roleLevel = 1,
				names = {"复仇者联盟", "口袋联盟"},
				preData = {},
			}
			-- only for test battle
			-- hacked some data and func
			local result = battleEntrance.battleRecord(data, 'unknown', {fromRecordFile=true})
			:run()
			if result.result == "win" then
				winTimes = winTimes + 1
			elseif result.result == "fail" then
				loseTimes = loseTimes + 1
			end
			print(string.format("[INFO] 当前: %d (%d vs %d)",testTimes,winTimes,loseTimes))
			print(string.format("[INFO] RunTime: (%d/%d), Seed: %d",i,testTimes,data.randSeed))
		end
		print(string.format("[INFO] 总战斗测试次数: %d 其中赢%d次 输%d次",testTimes,winTimes,loseTimes))
	end}})

	y = y - 120
	local btn = newButton("界面显示测试", y):addTo(self, 1)
	bind.touch(self, btn, {methods = {ended = function()
		package.loaded["tests.test_view"] = nil
		local func = require("tests.test_view")
		func()
	end}})
end

function LoginView:createTestSceneData()
	gGameModel.role:init({
		_db = {
			id = "1111111",
			yyhuodongs = {},
			yy_delta = {},
			yy_endtime = 0,
			figures = {},
			pokedex = {},
			skins = {},
			logos = {},
			gate_star = {
				[10102] = {star = 3},
				[10105] = {star = 3},
			},
			level = 99,
		},
	})

	local data = {}
	data = {
		sceneID = 999999,
		randSeed = math.random(1, 1000000),
		roleLevel = 99,
		talents = {{},{}},
		fightgoVal = {0,0},
		gateFirst = true,
		gateType = game.GATE_TYPE.test,
		-- 战斗选择类型默认为 1: 常规  2: 全手动
		moduleType = 1,
	}
	return data
end


-----------------------------------
-- Benchmark
-----------------------------------

local images = {
	"res/img/dazhaodi.jpg",
	"res/resources/activity/server_open/img_haibao@.png",
	"res/resources/city/friend/panel_image.png",
	"res/resources/common/bg/img_bg2.png",
	"res/resources/battle/end/win/img_bg.png",
	"res/resources/common/bg/img_bg1.png",
	"res/resources/city/gate/map/img_alldqxx.png",
	"res/resources/city/gate/map/img_fqcs.png",
	"res/resources/city/gate/map/img_spcj.png",
	"res/resources/city/gate/map/img_xbxz.png",
	"res/resources/city/gate/map/img_smbl.png",
	"res/resources/city/gate/map/img_llajdhz.png",
	"res/resources/activity/server_open/img_xszk.png",
	"res/resources/common/bg/bg_d.png",
	"res/resources/activity/regain_stamina/img_baofulei@.png",
}

local function nextWrap(f)
	if not f then return end
	return function()
		performWithDelay(gGameUI.uiRoot, function() f() end, 0.1)
	end
end

local function NodeBenchmark(nextBenchmark)
	local socket = require("socket")
	local insert = table.insert

	-- create cc.Node
	local n = 100000
	collectgarbage()
	local bmem = collectgarbage("count")
	print("create cc.Node begin", bmem)
	local bclock, btime = os.clock(), socket.gettime()
	local t = {}
	for i = 1, n do
		insert(t, cc.Node:create():retain())
	end
	local eclock, etime = os.clock(), socket.gettime()
	local emem = collectgarbage("count")
	print("create cc.Node end", emem, emem - bmem)
	gGameUI:showDialog({
		title = string.format("%d create cc.Node", n),
		content = string.format("clock: %s s\ntime: %s s\nmem: %s K\n", eclock-bclock, etime-btime, emem-bmem),
		align = "left",
		fontSize = 40,
	})

	performWithDelay(gGameUI.uiRoot, function()
		-- release cc.Node
		collectgarbage()
		local bmem = collectgarbage("count")
		print("release cc.Node begin", bmem)
		local bclock, btime = os.clock(), socket.gettime()
		for i = 1, n do
			t[i]:release()
		end
		t = nil
		local eclock, etime = os.clock(), socket.gettime()
		local emem = collectgarbage("count")
		print("release cc.Node end", emem, emem - bmem)
		gGameUI:showDialog({
			title = string.format("%d release cc.Node", n),
			content = string.format("clock: %s s\ntime: %s s\nmem: %s K\n", eclock-bclock, etime-btime, emem-bmem),
			align = "left",
			fontSize = 40,
			cb = nextWrap(nextBenchmark),
			closeCb = nextWrap(nextBenchmark),
		})
	end, 1)
end

local function AsyncLoadImageBenchmark(nextBenchmark)
	local socket = require("socket")

	-- async load image
	for i, s in ipairs(images) do
		display.textureCache:removeTextureForKey(s)
	end
	local bclock, btime = os.clock(), socket.gettime()
	local cnt = #images
	for i, s in ipairs(images) do
		display.textureCache:addImageAsync(s, function()
			cnt = cnt - 1
			if cnt <= 0 then
				local eclock, etime = os.clock(), socket.gettime()
				gGameUI:showDialog({
					title = "async load image",
					content = string.format("clock: %s s\ntime: %s s\n", eclock-bclock, etime-btime),
					align = "left",
					fontSize = 40,
					cb = nextWrap(nextBenchmark),
					closeCb = nextWrap(nextBenchmark),
				})
			end
		end)
	end
end

function LoginView:showBenchmark()
	print('---- showBenchmark ----')

	local socket = require("socket")
	local insert = table.insert
	local random = ymrand.random

	for i, s in ipairs(images) do
		images[i] = display.textureCache:checkFullPath(s)
	end

	-- sync load image
	for i, s in ipairs(images) do
		display.textureCache:removeTextureForKey(s)
	end
	local bclock, btime = os.clock(), socket.gettime()
	for i, s in ipairs(images) do
		display.textureCache:addImage(s)
	end
	local eclock, etime = os.clock(), socket.gettime()
	gGameUI:showDialog({
		title = "sync load image",
		content = string.format("clock: %s s\ntime: %s s\n", eclock-bclock, etime-btime),
		align = "left",
		fontSize = 40,
	})

	-- float division
	local n = 10000000
	bclock, btime = os.clock(), socket.gettime()
	local a
	for i = 1, n do
		a = n / i
	end
	eclock, etime = os.clock(), socket.gettime()
	gGameUI:showDialog({
		title = string.format("%d float division", n),
		content = string.format("clock: %s s\ntime: %s s\n", eclock-bclock, etime-btime),
		align = "left",
		fontSize = 40,
	})

	-- ymrand calculate
	n = 1000000
	bclock, btime = os.clock(), socket.gettime()
	for i = 1, n do
		random()
	end
	eclock, etime = os.clock(), socket.gettime()
	gGameUI:showDialog({
		title = string.format("%d ymrand calculate", n),
		content = string.format("clock: %s s\ntime: %s s\n", eclock-bclock, etime-btime),
		align = "left",
		fontSize = 40,
	})

	-- create table
	n = 1000000
	collectgarbage()
	local bmem = collectgarbage("count")
	print("create table begin", bmem)
	bclock, btime = os.clock(), socket.gettime()
	local t = {}
	for i = 1, n do
		insert(t, {})
	end
	eclock, etime = os.clock(), socket.gettime()
	local emem = collectgarbage("count")
	print("create table end", emem, emem - bmem)
	gGameUI:showDialog({
		title = string.format("%d create table", n),
		content = string.format("clock: %s s\ntime: %s s\nmem: %s K\n", eclock-bclock, etime-btime, emem-bmem),
		align = "left",
		fontSize = 40,
	})

	-- gc table
	bclock, btime = os.clock(), socket.gettime()
	t = nil
	collectgarbage()
	eclock, etime = os.clock(), socket.gettime()
	bmem = collectgarbage("count")
	print("gc table end", bmem, emem - bmem)
	gGameUI:showDialog({
		title = string.format("%d gc table", n),
		content = string.format("clock: %s s\ntime: %s s\nmem: %s K\n", eclock-bclock, etime-btime, emem-bmem),
		align = "left",
		fontSize = 40,
	})

	NodeBenchmark(AsyncLoadImageBenchmark)
end

return function(cls)
	for k, v in pairs(LoginView) do
		cls[k] = v
	end
end