

require "battle.models.include"


local function call(f, ...)
	if f == nil then return end
	return f(...)
end

local function null_func(...)
end

-- like BattleView:showEndView
local function showEndView(t, self, results)
	-- 测试场景不检测结果 PVP模式开着precheck 不一致的话会在后面弹框拦回去
	if not (t._modes and t._modes.fromRecordFile) and not t._isTestScene and not t._preCheck then
		local ok = not t._results or t._results.result == results.result or t._results == results.result
		if not ok then
			print("==== results in now", dumps(results))
			print("==== t._results in early", dumps(t._results))
		end
		assert(ok, "战斗结果不一致")
	end

	t._results = results
	return call(t._onResult, t._data, t._results)
end

-- like BattleView:postEndResultToServer
local function postEndResultToServer(t, self, url, cbOrT, ...)
	checkGGCheat()
	if gGameModel.battle then
		gGameModel.battle:checkCheat()
	end

	if type(cbOrT) == "function" then
		cbOrT = {cb = cbOrT}
	end
	local cb = cbOrT.cb
	cbOrT.cb = nil

	local hackCb = function(...)
		cb(...)
		-- battle.loading -> battle.view
		call(t._onPostResp)
		gRootViewProxy = t._oldViewProxy
	end
	local onErrClose = cbOrT.onErrClose
	cbOrT.onErrClose = function(...)
		if onErrClose then
			onErrClose(...)
		else
			gGameUI:switchUI("city.view")
		end
		gRootViewProxy = t._oldViewProxy
	end

	local req = gGameApp:requestServerCustom(url):params(...)
	-- see requestFuncs
	-- {onErrClose = f} -> req.onErrClose(req, f)
	for k, v in pairs(cbOrT) do
		req[k](req, v)
	end
	return req:doit(hackCb)
end

local lastListenerKey
local function _switchUI(t, onBattleViewCreated, onLoadingViewCreated)
	assert(type(t) == "table", "_switchUI need battleEntrance " .. type(t))
	local data, modes = t._data, t._modes

	if onBattleViewCreated or onLoadingViewCreated then
		if lastListenerKey then
			lastListenerKey:remove()
			lastListenerKey = nil
		end

		local listenerKey
		listenerKey = gGameUI:registerMessageListener("switchUI", function(name)
			if name == "battle.loading" then
				call(onLoadingViewCreated)
				lastListenerKey = listenerKey
			elseif name == "battle.view" then
				call(onBattleViewCreated)
				listenerKey:remove()
			end
		end)
	end

	if gGameUI.rootViewName == "city.view" then
		gGameUI:switchUIAndStash("battle.loading", data, data.sceneID, modes, t)
	else
		gGameUI:switchUI("battle.loading", data, data.sceneID, modes, t)
	end
end

local _localHack = {}
-- BattleView:postEndResultToServer
-- skip request, and callback with server data
function _localHack.postEndResultToServer(t)
	local results = t._results
	assert(results, "battle results was nil")

	local oldPost = gRootViewProxy:raw().postEndResultToServer
	gRootViewProxy:raw().postEndResultToServer = function(self, url, cbOrT)
		printDebug("postEndResultToServer %s be hacked in local", url)
		gRootViewProxy:raw().postEndResultToServer = oldPost
		checkGGCheat()
		if gGameModel.battle then
			gGameModel.battle:checkCheat()
		end

		local cb = type(cbOrT) == "function" and cbOrT or cbOrT.cb
		return cb(results.serverData)
	end
end

-- like BattleView:showEndView
-- save the local play result
function _localHack.showEndView(t)
	local oldShow = gRootViewProxy:raw().showEndView
	gRootViewProxy:raw().showEndView = function(self, results)
		assert(results, "battle results was nil")

		printDebug("showEndView be hacked in local")
		gRootViewProxy:raw().showEndView = oldShow

		t._results = results
		oldShow(self, results)
		call(t._onResult, t._data, t._results)
	end
end

-- BattleLoadingView:onRunBattleModel
-- wait post response
function _localHack.onRunBattleModel(t)
	local runBattleInLoading = t._runBattleInLoading
	assert(runBattleInLoading, "runBattleInLoading was nil")
	assert(gGameUI.rootViewName == "battle.loading", "root view was not battle.loading")

	local oldRun = gRootViewProxy:raw().onRunBattleModel
	gRootViewProxy:raw().onRunBattleModel = function(self)
		printDebug("onRunBattleModel be hacked in local")
		gRootViewProxy:raw().onRunBattleModel = oldRun

		if t._post then
			t._onPostResp = function()
				oldRun(self)
				t._postRespOver = true
			end
		end

		runBattleInLoading()

		-- change BattleLoadingView state to LOADING_STATE.loadOver
		if not t._post then
			oldRun(self)
		end
	end
end

local function _runBattleModel(t)
	local data = t._data

	local title = string.format("\n\n\t\tbattle %s model run - seed=%s, scene=%s\n\n", t._record and "record" or "", data.randSeed, data.sceneID)
	printInfo(title)
	log.battle(title)

	collectgarbage()
	local mem = collectgarbage("count")
	local clock = os.clock()

	cow.battleModelInit()
	battleEntrance.preloadConfig()

	local scene = cow.proxyObject("scene", SceneModel.new())
	ymrand.randomseed(data.randSeed)
	ymrand.randCount = 0
	-- gRootViewProxy:raw()的现在就这两个
	t._oldViewProxy = gRootViewProxy
	gRootViewProxy = ViewProxy.new({
		postEndResultToServer = t._post and functools.partial(postEndResultToServer, t) or null_func,
		showEndView = functools.partial(showEndView, t),
	})
	gRootViewProxy:modelOnly()

	scene:init(data.sceneID, data, t._record)

	scene:setAutoFight(true)

	-- 1. Gate:onOver - makeEndViewInfos
	-- 2. SceneModel:playEnd - isBattleAllEnd
	-- 3. postEndResultToServer
	-- 4. showEndView
	while not scene.isBattleAllEnd do
		scene:update(game.FRAME_TICK)

		if t._timeLimit then
			if os.clock() - clock > t._timeLimit then
				break
			end
		end
	end

	cow.battleModelDestroy()
	-- 释放所有组件
	battleComponents.clearAll()
	if not t._preCheck then
		battleEntrance.unloadConfig()
	end

	collectgarbage()
	local curMem = collectgarbage("count")
	printInfo('_runBattleModel over mem %.2fKB cost %.2fKB %.3fs', curMem, curMem - mem, os.clock() - clock)

	if not t._post then
		gRootViewProxy = t._oldViewProxy
	end
	local result = scene.play:makeEndViewInfos()
	t._results = result
	if t._check or t._preCheck then
		return scene.play:compareRecrodResult(t._checkResult)
	end
	return result
end


-----------------------------------
-- local

local localRunnerFuncs = {__cname = "localRunnerFuncs"}
localRunnerFuncs.__index = localRunnerFuncs
function localRunnerFuncs.post(t)
	assert(not t._record, "record could not post to server")
	t._post = true
	return t
end

function localRunnerFuncs.timeLimit(t, limit)
	t._timeLimit = limit
	return t
end

function localRunnerFuncs.preCheck(t, result, cb)
	if dev.CLOSE_PVP_PRECHECK then
		return t
	end
	assert(not t._post, "check record could not post to server")
	assert(t._record, "only record could be check")
	t._preCheck = true
	t._onPreCheckFailed = cb
	t._checkResult = result or t._results
	return t
end

-- @return result
-- no view to display, only model run
-- endpoint
function localRunnerFuncs.run(t)
	return _runBattleModel(t)
end

-- @return bool whether result is equal
-- no view to display, only model run
-- endpoint
function localRunnerFuncs.check(t, result)
	assert(not t._post, "check record could not post to server")
	assert(t._record, "only record could be check")
	t._check = true
	t._checkResult = result
	return _runBattleModel(t)
end

-- endpoint
function localRunnerFuncs.show(t)
	if t._preCheck then
		local same = _runBattleModel(t)
		if not same then
			return call(t._onPreCheckFailed)
		end
	end
	_switchUI(t, function()
		_localHack.postEndResultToServer(t)
	end)
end

function localRunnerFuncs.enter(t)
	_switchUI(t)
end

-----------------------------------
-- battleEntrance

battleEntrance._switchUI = _switchUI
battleEntrance._runBattleModel = _runBattleModel
battleEntrance._localHack = _localHack

-- it support [run, show, enter]
function battleEntrance.battle(data, modes)
	assert(data.sceneID, "no sceneID")
	return setmetatable({
		_data = data,
		_modes = modes,
	}, localRunnerFuncs)
end

-- it support [run, check, show]
function battleEntrance.battleRecord(data, results, modes)
	assert(data.sceneID, "no sceneID")
	modes = modes or {}
	modes.isRecord = true
	return setmetatable({
		_data = data,
		_results = results,
		_record = true,
		_post = false,
		_modes = modes,
	}, localRunnerFuncs)
end

