
require "battle.app_views.battle.battle_entrance.local"


local function call(f, ...)
	if f == nil then return end
	return f(...)
end

local _switchUI = battleEntrance._switchUI
local _runBattleModel = battleEntrance._runBattleModel
local _localHack = battleEntrance._localHack


-----------------------------------
-- remote
local remoteRunnerFuncs = {__cname = "remoteRunnerFuncs"}
remoteRunnerFuncs.__index = remoteRunnerFuncs

-- call after requestServer response back
-- by requestFuncs.doit
function remoteRunnerFuncs.onStartOK(t, cb)
	t._onStartOK = cb
	return t
end

-- see requestFuncs
function remoteRunnerFuncs.onRequestCustom(t, cb)
	t._onRequestCustom = cb
	return t
end

-- call in showEndView
function remoteRunnerFuncs.onResult(t, cb)
	t._onResult = cb
	return t
end

-- no view to display, only model run
-- chain or endpoint
function remoteRunnerFuncs.run(t)
	t._isRun = true
	t._runStarted = true

	-- localRunnerFuncs
	-- may be show() would be replace it
	t._runBattle = function()
		_runBattleModel(t)
		t._runOver = true
	end

	local req = gGameApp:requestServerCustom(t._startUrl)
		:params(unpack(t._startArgs, 1, t._startArgsN))
	call(t._onRequestCustom, req)
	req:doit(function(response)
		local data = gGameModel.battle:getData()
		call(t._onStartOK, data)

		t._data = data
		call(t._runBattle)
	end)
	return t
end

-- endpoint
function remoteRunnerFuncs.show(t)
	t._isShow = true

	local function showBattleAfterRunOrResp()
		assert(t._data, "battle data was nil")
		_switchUI(t, function()
			-- avoid sent twice request for the battle in both run and show
			if t._runOver then
				assert(t._postRespOver, "request must be done before battle.view")
				_localHack.postEndResultToServer(t)
			end
		end, function()
			if t._runBattleInLoading then
				_localHack.onRunBattleModel(t)
			end
		end)
	end

	-- run before show
	if t._runStarted or t._runOver then
		-- run over (should be false, run and show be call in the same frame in normally)
		if t._runOver then
			return showBattleAfterRunOrResp()
		end

		-- running before show
		-- move _runBattle to battle.loading
		t._runBattleInLoading = t._runBattle
		t._runBattle = showBattleAfterRunOrResp

		if t._onResult then
			local f = t._onResult
			t._onResult = function()
				f(t._data, t._results)
			end
		end
		return
	end

	-- show, no run
	local req = gGameApp:requestServerCustom(t._startUrl)
		:params(unpack(t._startArgs, 1, t._startArgsN))
	call(t._onRequestCustom, req)
	req:doit(function(response)
		local battle = gGameModel.battle
		local data = battle:getData()
		call(t._onStartOK, data)

		assert(data, "battle data was nil")
		t._data = data
		_switchUI(t, function()
			battle:checkCheat()
			_localHack.showEndView(t)
		end)
	end)
end

-- special for pause and restart
-- notice onStartOK will be call again but something destroy like in EndlessTowerGateDetail:startFighting
function remoteRunnerFuncs.restart(t)
	local _runStarted = t._runStarted
	local _runOver = t._runOver

	assert(t._isRun or t._isShow, "remote entrance no run and show")

	-- clear
	t._runStarted = false
	t._runOver = false
	t._runBattle = nil
	t._runBattleInLoading = nil

	t._data = nil
	t._results = nil

	-- retry
	if t._isRun then
		t:run()
	end
	if t._isShow then
		t:show()
	end
end

-- it support [run + show, run, show]
function battleEntrance.battleRequest(startUrl, ...)
	local nargs = select("#", ...)
	local args = {...}
	args = table.flatArray(args, nargs)

	return setmetatable({
		_startUrl = startUrl,
		_startArgsN = nargs,
		_startArgs = args,

		-- localRunnerFuncs
		_data = nil,
		_post = true,
		_modes = nil,
	}, remoteRunnerFuncs)
end