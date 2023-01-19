
print("Anti Main working...")

if arg then
	for k, v in pairs(arg) do
		print('command arg', k, v)
	end
end
STAND_ALONE = arg and arg[-1]
PLAY_PATH = arg and arg[1]
if PLAY_PATH == "--onlinefight" then -- 实时匹配模式
	PLAY_PATH = nil
	OnlineFightModel = arg[1]
end
RUN_WITH_CMD_LINE = PLAY_PATH

print("STAND_ALONE:", STAND_ALONE, "OnlineFightModel:", OnlineFightModel)
if STAND_ALONE then
	package.path = package.path .. ";./framework/MyLuaGame/?.lua;"
	package.path = package.path .. "./framework/MyLuaGame/src/?.lua;"
	package.path = package.path .. "./application/src/?.lua;"
end
print(package.path)

ANTI_AGENT = true
LUACOV_ANTI_AGENT = false

function begin_luacov( ... )
end
function end_luacov( ... )
end

if LUACOV_ANTI_AGENT then
	local LuaCovRunner = require("luacov.runner")
	function begin_luacov( ... )
		LuaCovRunner.init()
		LuaCovRunner.configuration.onlysummary = true
		table.insert(LuaCovRunner.configuration.exclude, "app/")
	end
	function end_luacov( ... )
		LuaCovRunner.shutdown()
	end
end

device = {
	platform = "agent",
}
function printInfo( ... )
end
function printWarn( ... )
end

userDefault = {
	getForeverLocalKey = function (...)
		return false
	end,
}

cc = {
	CameraBackgroundBrush = {},
	AsyncTaskPool = {},
	ResolutionPolicy = {},
	FileUtils = {
		getInstance = function (...)
			return cc.FileUtils
		end,
		getValueMapFromFile = function (...)
			return {}
		end,
		isFileExist = function (...)
			return false
		end,
	},
	Application = {
		getInstance = function (...)
			return cc.Application
		end,
		getTargetPlatform = function (...)
			return {}
		end,
	},
	SpriteFrameCache = {
		getInstance = function (...)
			return cc.SpriteFrameCache
		end,
	},
	AnimationCache = {
		getInstance = function (...)
			return cc.AnimationCache
		end,
	},
	AssetsManagerEx = {
		getInstance = function (...)
			return cc.AssetsManagerEx
		end,
		getPatchMinVersion = function (...)
			return 0
		end,
		getPatchVersion = function (...)
			return 0
		end,
	},
	UserDefault = {
		getInstance = function (...)
			return cc.UserDefault
		end,
		getIntegerForKey = function (...)
			return 0
		end,
		getBoolForKey = function (...)
			return false
		end,
	},
	Director = {
		getScheduler = function (...)
			return cc.Director
		end,
		getInstance = function (...)
			return cc.Director
		end,
		getOpenGLView = function (...)
			return cc.Director
		end,
		getFrameSize = function (...)
			return {width=0, height=0}
		end,
		getDesignResolutionSize = function (...)
			return {width=0, height=0}
		end,
		getWinSize = function (...)
			return {width=0, height=0}
		end,
		getContentScaleFactor = function (...)
			return 0
		end,
		setDesignResolutionSize = function (...)
		end,
		getTimeScale = function (...)
			return 0
		end,
		setTimeScale = function (...)
		end,
		getTextureCache = function (...)
		end,
		setProjection = function (...)
		end,
		getSafeAreaRect = function ( ... )
			return {x=0, y=0, width=0, height=0}
		end,
	},
	load = function ( ... )
		return setmetatable({}, {
			__index = function( ... )
				return function ( ... )
				end
			end
		})
	end,
}

ccs = {
	GUIReader = {
		getInstance = function ( ... )
			return ccs.GUIReader
		end
	},
}

display = {
	director = cc.Director,
	scheduler = cc.Director,
}

gGameApp = {
	requestServer = function(...)
	end,
	net = {
		sendPacket = function(...)
		end,
	}
}

gGameUI = {
	guideManager = {
		battleStageSave = function(_, cb)
			cb()
		end,
	},
}

errorInWindows = function( ... )
end

assertInWindows = function( ... )
end

cc_mathutils_random = function( ... )
end

pcall = pcall or unsafe_pcall
xpcall = xpcall or unsafe_xpcall

globals = _G

package.path = string.format('%s/?.lua;', "../../server/anti-cheat/game_scripts/application/dev/pokemon_battle")..package.path
print('package.path', package.path)

local ffi = require "ffi"
print('platform', ffi.os)
if ffi.os == "Windows" then
	ffi.cdef [[
	int  _setmode(
			int _FileHandle,
			int _Mode
	);
	int _fileno(
		void* _Stream
	);
	]]
	local _O_BINARY = 0x8000
	ffi.C._setmode(ffi.C._fileno(io.stdin), _O_BINARY)
	ffi.C._setmode(ffi.C._fileno(io.stdout), _O_BINARY)
	ffi.C._setmode(ffi.C._fileno(io.stderr), _O_BINARY)

	package.path = string.format('%s/?.lua;', "./application/dev/pokemon_battle")..package.path
	print('package.path', package.path)
end

require "anti_lib"
require "battle.models.scene"
require "battle.models.cow_proxy"
require "battle.app_views.battle.battle_entrance.include"

-- print('g_enable_cow', g_enable_cow, cow.isEnable())

local cow_init_for_online = false
local cow_battleModelInit = cow.battleModelInit
local cow_battleModelDestroy = cow.battleModelDestroy
local cow_proxyObjectWatchBegin = cow.proxyObjectWatchBegin
local cow_proxyObjectWatchEnd = cow.proxyObjectWatchEnd



local _msgpack = require '3rd.msgpack'
_msgpack.set_string('binary')
_msgpack.set_number('double')

local msgpack = _msgpack.pack
local _msgunpack = _msgpack.unpack

local function msgunpack(data)
	if type(data) == "string" then
		return _msgunpack(data)
	end
	return data
end

last_traceback = nil
function __G__TRACKBACK__(msg)
	print("----------------------------------------")
	print("LUA ERROR: " .. tostring(msg) .. "\n")
	print(debug.traceback())
	print("----------------------------------------")
	last_traceback = "LUA ERROR: " .. tostring(msg) .. "\n" .. debug.traceback()
end

local function main()
	-- avoid memory leak
	-- collectgarbage("setpause", 1000)
	-- collectgarbage("setstepmul", 5000)
	-- collectgarbage("stop")
	-- collectgarbage() --立即gc

	IS_DEBUG = false
	PVP_DEBUG = false
	DEBUG_FRAME = false

	LOCAL_LANGUAGE = 'cn'
	print('LOCAL_LANGUAGE', LOCAL_LANGUAGE)

	battleEntrance.preloadConfig()
	battleEntrance.unloadConfig = null_func
end

local battleTotal = 0
local gcCycle = 100

function gc(force)
	battleTotal = battleTotal + 1
	if force or battleTotal % gcCycle == 0 then
		print('Lua gc', collectgarbage("count"), collectgarbage(), collectgarbage("count"))
		print('Lua mem', collectgarbage('count'), 'KB')
	end
end

-- function print( ... )
-- end

local function null_func(...)
end

local function runBattleData(data)
	cow.battleModelInit()

	local scene = cow.proxyObject("scene", SceneModel.new())
	ymrand.randomseed(data.randSeed)
	ymrand.randCount = 0
	gRootViewProxy = ViewProxy.new()
	gRootViewProxy:modelOnly()

	scene:init(data.sceneID, data, true)
	scene:setAutoFight(true)

	scene.play.postEndResultToServer = null_func
	scene.guide.checkGuide = function(_, cb)
		cb()
	end

	while not scene.isBattleAllEnd do
		scene:update(game.FRAME_TICK)
	end

	cow.battleModelDestroy()
	-- 释放所有组件
	battleComponents.clearAll()

	return scene.play
end

local function runBattle(battle)
	begin_luacov()

	local data = battle:getData()
	local play = runBattleData(data)

	gc()

	end_luacov()
	return play
end

----------------------------------------------------
-- arena battle
----------------------------------------------------
function startArena(data)
	-- print('initArena data size', #data)
	local startTime = os.clock()
	data = msgunpack(data)
	-- print('initArena play record', data.date, data.name, data.defence_name)

	t = {
		model = {
			arena_battle = data,
		}
	}
	local model = require("app.models.game").new()
	model:syncFromServer(t)
	-- print('initArena', os.clock() - startTime)

	local play = runBattle(model.battle)
	return play.result
end


----------------------------------------------------
-- craft battle
----------------------------------------------------
function startCraft(data)
	-- print('initCraft data size', #data)
	local startTime = os.clock()
	data = msgunpack(data)
	-- print('initCraft play record', data.date, data.name, data.defence_name)
	t = {
		model = {
			craft_playrecords = {[1]=data},
		}
	}
	local model = require("app.models.game").new()
	model:syncFromServer(t)
	-- print('initCraft', os.clock() - startTime)

	local battle = model.craft_playrecords:find(1)
	local play = runBattle(battle)
	return play.result, play.score, play.enemyScore
end

----------------------------------------------------
-- union fight battle
----------------------------------------------------
function startUnionFight(data)
	data = msgunpack(data)
	t = {
		model = {
			union_fight_playrecords = {[1]=data},
		}
	}
	local model = require("app.models.game").new()
	model:syncFromServer(t)

	local battle = model.union_fight_playrecords:find(1)
	local play = runBattle(battle)
	-- temporary fix when int key in result map, must be str
	local states = play.states
	for k, v in pairs(states) do
		if type(k) == "number" then
			states[k] = nil
		end
	end
	return play.result, states
end

----------------------------------------------------
-- cross union fight battle
----------------------------------------------------
function startCrossUnionFight(data)
	data = msgunpack(data)
	t = {
		model = {
			cross_union_fight_playrecords = {[1]=data},
		}
	}
	local model = require("app.models.game").new()
	model:syncFromServer(t)

	local battle = model.cross_union_fight_playrecords:find(1)
	local play = runBattle(battle)
	-- temporary fix when int key in result map, must be str
	local states = play.states
	for k, v in pairs(states) do
		if type(k) == "number" then
			states[k] = nil
		end
	end
	return play.result, states
end

----------------------------------------------------
-- cross craft battle
----------------------------------------------------
function startCrossCraft(data)
	local startTime = os.clock()
	data = msgunpack(data)
	t = {
		model = {
			cross_craft_playrecords = {[1]=data},
		}
	}
	local model = require("app.models.game").new()
	model:syncFromServer(t)

	local battle = model.cross_craft_playrecords:find(1)
	local play = runBattle(battle)
	return play.result, play.score, play.enemyScore
end

-- battle 主线, 精英，噩梦关卡
-- endless_battle 无尽之塔
-- random_tower_battle 随机塔 (not support)
-- union_fuben_battle 公会副本 (not support)
function startGateBattle(data)
	local startTime = os.clock()
	data = msgunpack(data)
	local gate_id = data.gate_id
	local name = 'battle' -- 根据gate_id区分是什么战斗
	if csv.endless_tower_scene[gate_id] ~= nil then
		name = 'endless_battle'
	else
	end

	t = {
		model = {
			-- battle = data,
		}
	}
	t.model[name] = data
	local model = require("app.models.game").new()
	model:syncFromServer(t)
	local battle = model.battle
	battle.getPreDataForEnd = function() return {} end
	local play = runBattle(battle)
	return play.result
end

-- endless_battle 无尽之塔
function startEndlessBattle(data)
	data = msgunpack(data)
	t = {
		model = {
			endless_playrecords = {[1]=data},
		}
	}
	local model = require("app.models.game").new()
	model:syncFromServer(t)

	local battle = model.endless_playrecords:find(1)
	local play = runBattle(battle)
	return play.result
end

-- cross_mine_boss_battle 跨服资源战boss战
function startCrossMineBossBattle(data)
	data = msgunpack(data)
	t = {
		model = {
			cross_mine_boss_battle = data
		}
	}
	local model = require("app.models.game").new()
	model:syncFromServer(t)

	local battle = model.battle
	battle.getPreDataForEnd = function() return {} end
	local play = runBattle(battle)
	return play.result, play.dmgCount
end

-- brave_challenge_battle 勇者挑战
function startBraveChallengeBattle(data)
	data = msgunpack(data)
	t = {
		model = {
			brave_challenge_battle = data
		}
	}
	local model = require("app.models.game").new()
	model:syncFromServer(t)

	local battle = model.battle
	battle.getPreDataForEnd = function() return {} end
	local play = runBattle(battle)
	return play.result
end

-- summer_challenge_battle 夏日挑战
function startSummerChallengeBattle(data)
	data = msgunpack(data)
	t = {
		model = {
			summer_challenge_battle = data
		}
	}
	local model = require("app.models.game").new()
	model:syncFromServer(t)

	local battle = model.battle
	battle.getPreDataForEnd = function() return {} end
	local play = runBattle(battle)
	return play.result
end

-- cross_mine_battle 跨服资源战 pvp
function startCrossMineBattle(data)
	data = msgunpack(data)
	t = {
		model = {
			cross_mine_battle = data
		}
	}
	local model = require("app.models.game").new()
	model:syncFromServer(t)

	local battle = model.battle
	battle.getPreDataForEnd = function() return {} end
	local play = runBattle(battle)
	return play.result
end

-- cross_arena_battle 跨服竞技场
function startCrossArenaBattle(data)
	data = msgunpack(data)
	t = {
		model = {
			cross_arena_battle = data
		}
	}
	local model = require("app.models.game").new()
	model:syncFromServer(t)

	local battle = model.battle
	battle.getPreDataForEnd = function() return {} end
	local play = runBattle(battle)
	return play.result
end


-- 实时对战战报 cross_online_fight play record
function startCrossOnlineFightRecord(data)
	data = msgunpack(data)
	t = {
		model = {
			cross_online_fight_playrecords = {[1]=data},
		}
	}
	local model = require("app.models.game").new()
	model:syncFromServer(t)
	local battle = model.cross_online_fight_playrecords:find(1)
	local data = battle:getData()

	cow.battleModelInit()
	local scene = cow.proxyObject("scene", SceneModel.new())
	ymrand.randomseed(data.randSeed)
	ymrand.randCount = 0
	gRootViewProxy = ViewProxy.new()
	gRootViewProxy:modelOnly()

	scene:init(data.sceneID, data, true)
	scene:setAutoFight(true)

	scene.play.postEndResultToServer = null_func
	scene.play.makeEndViewInfos = null_func
	scene.guide.checkGuide = function(_, cb)
		cb()
	end
	while not scene.isBattleAllEnd do
		scene:update(game.FRAME_TICK)
	end
	cow.battleModelDestroy()
	return scene.play.result
end

-- 实时对战 cross_online_fight
allCrossOnlineFightBattles = {} -- {id: {scene, randObjId, cowData, battleComponentsData}}
crossOnlineFightRandCounts = {}

-- { "randomseed",  _randomseed },
-- { "random",      _random },
-- // for anti-cheat, one lua state more rand objs by huangwei 2020/5/21
-- { "obj_new",         _obj_new },
-- { "obj_delete",      _obj_delete },
-- { "obj_randomseed",  _obj_randomseed },
-- { "obj_random",      _obj_random },

function startCrossOnlineFightBattle(id, data)
	-- cow init in main
	if not cow_init_for_online then
		cow.battleModelInit = function()
		end
		cow.battleModelDestroy = function()
		end

		cow_battleModelInit()
		cow_init_for_online = true
	end

	-- print('startCrossOnlineFightBattle', string.len(data))
	data = msgunpack(data)

	t = {
		model = {
			cross_online_fight_battle = data,
		}
	}
	local model = require("app.models.game").new()
	model:syncFromServer(t)

	local battle = model.battle
	data = battle:getData()
	data.operateForce = 1

	local battleComponentsData = battleComponents.newGlobalData()
	battleComponents.switchGlobalData(battleComponentsData)

	local cowData = cow.newCowData()
	cow.switchCowData(cowData)
	local scene = cow.proxyObject("scene", SceneModel.new())

	-- randomseed 修改
	local oldrandom = ymrand.random
	local randObjId = ymrand.obj_new()
	ymrand.obj_randomseed(randObjId, data.randSeed)
	ymrand.random = function(...)
		crossOnlineFightRandCounts[id] = crossOnlineFightRandCounts[id] + 1
		ymrand.randCount = crossOnlineFightRandCounts[id]
		return ymrand.obj_random(randObjId, ...)
	end
	ymrand.randCount = 0

	allCrossOnlineFightBattles[id] = {scene, randObjId, cowData, battleComponentsData}
	crossOnlineFightRandCounts[id] = 0

	gRootViewProxy = ViewProxy.new()
	gRootViewProxy:modelOnly()

	scene:init(data.sceneID, data, false)
	scene:setAutoFight(false)
	scene.play.postEndResultToServer = null_func
	scene.play.runOneFrame = null_func
	scene.play.makeEndViewInfos = null_func
	scene.guide.checkGuide = function(_, cb)
		cb()
	end

	while not scene.play.waitInput and not scene.isBattleAllEnd do
		scene:update(game.FRAME_TICK)
	end

	ymrand.random = oldrandom

	local who = scene.play:getCurHeroSeat()
	local result = scene.play.result or ""
	local status = {}
	for i = 1, 12 do
		local obj = scene:getObjectBySeat(i)
		if obj then
			status[i] = {obj:hp(), obj:mp1(), obj.state}
		else
			status[i] = {0, 0, 0}
		end
	end
	status = msgpack(status)
	local wonderful = false
	if result ~= "" then
		wonderful = scene.play:isWonderfulRecord()
	end

	return who, result, wonderful, "", ymrand.randCount
end

function inputCrossOnlineFightBattle(id, data)
	local current, target, skill = unpack(msgunpack(data))
	local scene, randObjId, cowData, battleComponentsData = unpack(allCrossOnlineFightBattles[id])
	local oldrandom = ymrand.random
	ymrand.random = function(...)
		crossOnlineFightRandCounts[id] = crossOnlineFightRandCounts[id] + 1
		ymrand.randCount = crossOnlineFightRandCounts[id]
		return ymrand.obj_random(randObjId, ...)
	end

	battleComponents.switchGlobalData(battleComponentsData)

	cow.switchCowData(cowData)

	battlePlay.Gate.setAttack(scene.play, target, skill)
	scene:update(game.FRAME_TICK)
	while not scene.play.waitInput and not scene.isBattleAllEnd do
		scene:update(game.FRAME_TICK)
	end

	ymrand.random = oldrandom

	local who = scene.play:getCurHeroSeat()
	local result = scene.play.result or ""

	if scene.isBattleAllEnd or scene.play.result == "error" then
		closeCrossOnlineFightBattle(id)
	end

	local status = {}
	for i = 1, 12 do
		local obj = scene:getObjectBySeat(i)
		if obj then
			status[i] = {obj:hp(), obj:mp1(), obj.state}
		else
			status[i] = {0, 0, 0}
		end
	end
	status = msgpack(status)
	local wonderful = false
	if result ~= "" then
		wonderful = scene.play:isWonderfulRecord()
	end

	return who, result, wonderful, status, ymrand.randCount
end

function closeCrossOnlineFightBattle(id)
	local v = allCrossOnlineFightBattles[id]
	if v ~= nil then
		local scene, randObjId = unpack(v)
		ymrand.obj_delete(randObjId)
		allCrossOnlineFightBattles[id] = nil
		crossOnlineFightRandCounts[id] = nil
		gc(true)
	end
	-- print('left cross_online_fight_battle', #allCrossOnlineFightBattles)
end

function removeInternalTable(t)
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
	return ret
end

function getTestRecordDataByPlay(data)
	local t = {}
	local playName = data[1]
	local playModel = msgunpack(data[2])
	local monitor = playModel.monitor
	local model = nil
	local battle = nil

	if playName == "arena" then
		t = {model = {arena_battle = playModel}}
		model = require("app.models.game").new()
		model:syncFromServer(t)
		battle = model.battle
	elseif playName == "craft" then
		t = {model = {craft_playrecords = {[1]=playModel}}}
		model = require("app.models.game").new()
		model:syncFromServer(t)
		battle = model.craft_playrecords:find(1)
	elseif playName == "union_fight" then
		t = {model = {union_fight_playrecords = {[1]=playModel}}}
		model = require("app.models.game").new()
		model:syncFromServer(t)
		battle = model.union_fight_playrecords:find(1)
	elseif playName == "cross_union_fight" then
		t = {model = {cross_union_fight_playrecords = {[1]=playModel}}}
		model = require("app.models.game").new()
		model:syncFromServer(t)
		battle = model.cross_union_fight_playrecords:find(1)
	elseif playName == "cross_craft" then
		t = {model = {cross_craft_playrecords = {[1]=playModel}}}
		model = require("app.models.game").new()
		model:syncFromServer(t)
		battle = model.cross_craft_playrecords:find(1)
	elseif playName == "cross_arena" then
		t = {model = {cross_arena_playrecords = {[1]=playModel}}}
		model = require("app.models.game").new()
		model:syncFromServer(t)
		battle = model.cross_arena_playrecords:find(1)
	else
		error("not find play type " .. playName)
	end

	data = battle:getData()
	data.monitor = monitor

	return data
end

local testRecordFirst = false
function testRecordRequire()
	if not testRecordFirst then
		testRecordFirst = true
		require "app.views.city.test.test_define"
		require "app.views.city.test.test_easy"
		require "app.views.city.test.test_protocol"
		__TestDefine.Monitor = true
	end
end

function startTestRecordBattle(data)
	data = msgunpack(data)

	if table.getn(data) == 2 then
		data = getTestRecordDataByPlay(data)
	else
		data = removeInternalTable(data)
	end

	battleTotal = battleTotal + 1
	begin_luacov()

	testRecordRequire()

	if data.monitor ~= nil then
		for i in pairs(data.monitor) do
			local v = data.monitor[i]
			__TestEasy.pushCHProtocol(v.key, {type = v.type, condition = v.condition, output = {v.outputName, v.outputRecord}})
		end
	end

	cow.battleModelInit()

	local scene = cow.proxyObject("scene", SceneModel.new())
	ymrand.randomseed(data.randSeed)
	ymrand.randCount = 0
	gRootViewProxy = ViewProxy.new()
	gRootViewProxy:modelOnly()

	scene:init(data.sceneID, data, true)
	scene:setAutoFight(true)

	scene.play.postEndResultToServer = null_func
	scene.guide.checkGuide = function(_, cb)
		cb()
	end

	while not scene.isBattleAllEnd do
		scene:update(game.FRAME_TICK)
	end

	cow.battleModelDestroy()

	if battleTotal % gcCycle == 0 then
		print('Lua gc', collectgarbage("count"), collectgarbage(), collectgarbage("count"))
		print('Lua mem', collectgarbage('count'), 'KB')
	end

	local statistic = onTestRecordBattleStatistic()
	local monitor = nil

	if data.monitor ~= nil then
		monitor = __TestDefine.historyBattleInfo.extraData
		for i in pairs(data.monitor) do
			__TestEasy.clearCHProtocol(data.monitor[i].key, {})
		end
	end

	end_luacov()
	return scene.play.result, statistic, monitor
end

function startCreateRecord(data)
	testRecordRequire()
	data = msgunpack(data)
	return "win", __TestEasy.gainBattleRecord(data)
end

function onTestRecordBattleStatistic()
	local battleInfo = __TestDefine.historyBattleInfo[1]
	local allBattleInfo = __TestDefine.allHistoryBattleInfo

	local statistic = {}

	if not battleInfo then
		return statistic
	end

	local getValueInValueTypeTableArray = function(i,tableName,key,valueKey)
		if #allBattleInfo > 1 then
			local avgValue = 0
			for _,battleInfo in ipairs(allBattleInfo) do
				if battleInfo[i][tableName][key] then
					avgValue = avgValue + battleInfo[i][tableName][key]:get(valueKey)
				end
			end

			return math.ceil(avgValue / #allBattleInfo)
		else
			if not battleInfo[i][tableName][key] then return 0 end
			return battleInfo[i][tableName][key]:get(valueKey)
		end
	end

	local getValueInValueTypeTable = function(i,tableName,valueKey)
		if #allBattleInfo > 1 then
			local avgValue = 0
			for _,battleInfo in ipairs(allBattleInfo) do
				if battleInfo[i][tableName] then
					avgValue = avgValue + battleInfo[i][tableName]:get(valueKey)
				end
			end

			return math.ceil(avgValue / #allBattleInfo)
		else
			if not battleInfo[i][tableName] then return 0 end
			return battleInfo[i][tableName]:get(valueKey)
		end
	end

	local getNumber = function(i,...)
		local len = #allBattleInfo
		if len > 1 then
			local avgValue = nil
			for k,battleInfo in ipairs(allBattleInfo) do
				local data = table.get(battleInfo[i],...)
				if data then
					avgValue = (avgValue or 0) + data
				end
				if len == k and avgValue then avgValue = math.ceil(avgValue / len) end
			end
			return avgValue
		end
		return table.get(battleInfo[i],...)
	end

	local getString = function(i,...)
		return table.get(battleInfo[i],...)
	end

	local valueType = battle.ValueType.normal
	for i=1,12 do
		if battleInfo[i] then
			statistic[tostring(i)] = {
				['seat'] = getString(i, 'seat') or 0,
				['name'] = getString(i, 'name') or '',
				['dmgSkill'] = getValueInValueTypeTableArray(i, 'totalDamage', battle.DamageFrom.skill,valueType) or 0,
				["dmgBuff"] = getValueInValueTypeTableArray(i, "totalDamage", battle.DamageFrom.buff,valueType) or 0,
				["dmgRebound"] = getValueInValueTypeTableArray(i,"totalDamage", battle.DamageFrom.rebound,valueType) or 0,
				["dmgAllocate"] = getValueInValueTypeTableArray(i, "totalDamage", battle.DamageFromExtra.allocate,valueType) or 0,
				["dmgLink"] = getValueInValueTypeTableArray(i, "totalDamage", battle.DamageFromExtra.link,valueType) or 0,
				["validDamage"] = getValueInValueTypeTable(i, "_totalDamage", battle.ValueType.valid) or 0,
				["totalDamage"] = getValueInValueTypeTable(i, "_totalDamage", valueType) or 0,
				["extraHerosDamage"] = getNumber(i, "extraHerosDamage") or 0,
				["totalTake"] = getValueInValueTypeTableArray(i,"totalTakeDamage", valueType) or 0,
				["rhpSkill"] = getValueInValueTypeTableArray(i, "totalResumeHp", battle.ResumeHpFrom.skill,valueType) or 0,
				["rhpBuff"] = getValueInValueTypeTableArray(i, "totalResumeHp", battle.ResumeHpFrom.buff,valueType) or 0,
				["rhpSuckblood"] = getValueInValueTypeTableArray(i, "totalResumeHp",battle.ResumeHpFrom.suckblood,valueType) or 0,
				["rhpSpecial"] = getNumber(i, "resumeSpecialHp") or 0,
				["totalResumeHp"] = getValueInValueTypeTable(i, "_totalResumeHp",valueType) or 0,
				["kill"] = getNumber(i,"kill") or 0,
				["firstKill"] = getNumber(i, "firstKill") or 0,
				["skillTime"] = getNumber(i, "skillTime", battle.MainSkillType.BigSkill) or 0,
				["firstBigSkillRound"] = getNumber(i,"firstBigSkillRound") or 20,
				["deadBigRound"] = getNumber(i, "deadBigRound") or 20,
				["beAttack"] = getNumber(i, "beAttack") or 0,
				["beAttackStrike"] = getNumber(i, "beAttackStrike") or 0,
				["beAttackBlock"] = getNumber(i, "beAttackBlock") or 0,
				["onceMaxDamage"] = getNumber(i, "onceMaxDamage") or 0,
				["totalRound"] = getNumber(i, "totalRound") or 0,
			}
		end
	end

	return statistic
end

-------------------------------------------
-- STAND ALONE LUA ANTI AGENT

local function input_from_file(path)
	local fp = io.open(path, "rb")
	if fp == nil then
		error(path .. " not existed !!!")
	end
	local data = fp:read("*a")
	fp:close()

	local t = msgunpack(data)
	-- for k, v in pairs(t) do
	-- 	print(k, v)
	-- end

	print('play:', path, #data, type(t))
	return t
end

local function input_from_stdin()
	while true do
		local magicFlag = io.stdin:read("*l")
		if magicFlag == "-TJ-" then
			break
		end
		-- EOF
		if magicFlag == nil or magicFlag == "bye" then
			os.exit(0)
		end
	end
	local size = io.stdin:read("*l")
	size = tonumber(size)
	-- EOF
	if size == nil then
		os.exit(0)
	end

	local data = ''
	while size > 0 do
		local v = io.stdin:read(size)
		size = size - #v
		data = data .. v
	end

	-- EOF
	if data == nil or data == "bye" then
		os.exit(0)
	end
	-- print('input_from_stdin', #data)
	-- io.stdout:flush()

	local t = msgunpack(data)
	return t

	--PLAY_PATH = io.stdin:read("*l")
	---- EOF
	--print('PLAY_PATH', PLAY_PATH)
	--if PLAY_PATH == nil or PLAY_PATH == "bye" then
	--	os.exit(0)
	--end
	--print('input:', PLAY_PATH)
	--return input_from_file(PLAY_PATH)
end

local function stand_alone_main()
	-- avoid memory leak
	-- collectgarbage("setpause", 1000)
	-- collectgarbage("setstepmul", 5000)
	-- collectgarbage("stop")
	-- collectgarbage() --立即gc

	DEBUG = 2

	IS_DEBUG = false
	PVP_DEBUG = false
	DEBUG_FRAME = false

	LOCAL_LANGUAGE = 'cn'
	print('LOCAL_LANGUAGE', LOCAL_LANGUAGE)
	io.stdout:flush()

	battleEntrance.preloadConfig()
	battleEntrance.unloadConfig = null_func

	while true do
		local t
		if RUN_WITH_CMD_LINE then
			t = input_from_file(PLAY_PATH)
		else
			t = input_from_stdin()
		end

		local battleType = t[1]
		if battleType == nil then
			-- may be *.record
			runBattleData(t)
			return
		end

		-- print(t[1])
		io.stdout:flush()

		local result = 'error'
		local point1, point2 = 0, 0
		local states = nil
		local damages = nil
		local statistics = nil
		local monitor = nil
		local record = nil
		if battleType == "arena" then -- 竞技场
			xpcall(function()
				result = startArena(t[2])
			end, __G__TRACKBACK__)
		elseif battleType == "craft" then -- 石英大会
			xpcall(function()
				result, point1, point2 = startCraft(t[2])
			end, __G__TRACKBACK__)
		elseif battleType == "unionfight" then -- 公会战
			xpcall(function()
				result, states = startUnionFight(t[2])
			end, __G__TRACKBACK__)
		elseif battleType == "crosscraft" then -- 跨服石英大会
			xpcall(function()
				result, point1, point2 = startCrossCraft(t[2])
			end, __G__TRACKBACK__)
		elseif battleType == "gate" then
			xpcall(function()
				result = startGateBattle(t[2])
			end, __G__TRACKBACK__)
		elseif battleType == "endless" then -- 冒险之路战报
			xpcall(function()
				result = startEndlessBattle(t[2])
			end, __G__TRACKBACK__)
		elseif battleType == "crossmineboss" then -- 跨服资源战boss战
			xpcall(function()
				result, damages = startCrossMineBossBattle(t[2])
			end, __G__TRACKBACK__)
		elseif battleType == "onlinefight" then -- 对战竞技场战报
			xpcall(function()
				result = startCrossOnlineFightRecord(t[2])
			end, __G__TRACKBACK__)
		elseif battleType == "testbattle" then --战斗测试
			xpcall(function()
				result, statistics, monitor = startTestRecordBattle(t[2])
			end, __G__TRACKBACK__)
		elseif battleType == "createrecord" then -- 生成战报
			xpcall(function()
				result, record = startCreateRecord(t[2])
			end, __G__TRACKBACK__)
		elseif battleType == "bravechallenge" or battleType == "brave_challenge" then -- 勇者挑战
			xpcall(function()
				result = startBraveChallengeBattle(t[2])
			end, __G__TRACKBACK__)
		elseif battleType == "summerchallenge" then -- 勇者挑战
			xpcall(function()
				result = startSummerChallengeBattle(t[2])
			end, __G__TRACKBACK__)
		elseif t[1] == "crossmine" then -- 跨服资源战 pvp
			xpcall(function()
				result = startCrossMineBattle(t[2])
			end, __G__TRACKBACK__)
		elseif t[1] == "crossarena" then -- 跨服竞技场
			xpcall(function()
				result = startCrossArenaBattle(t[2])
			end, __G__TRACKBACK__)
		elseif battleType == "crossunionfight" then -- 跨服公会战
			xpcall(function()
				result, states = startCrossUnionFight(t[2])
			end, __G__TRACKBACK__)
		else
			-- error(battleType)
			printWarn("no such %s", battleType)
		end

		if RUN_WITH_CMD_LINE then
			return
		end

		local ret = {
			result = result,
			point1 = point1,
			point2 = point2,
			damages = damages,
			states = states,
			statistics = statistics,
			monitor = monitor,
			record = record,
			traceback = last_traceback,
		}
		-- print_r(ret)
		local data = msgpack(ret)
		-- write length
		io.stderr:write('' .. #data .. '\n')
		io.stderr:write(data)
		io.stderr:flush()
		io.stdout:flush()
	end
end

local function onlinefight_main()
	DEBUG = 2
	IS_DEBUG = false
	PVP_DEBUG = false
	DEBUG_FRAME = false

	LOCAL_LANGUAGE = 'cn'
	print('LOCAL_LANGUAGE', LOCAL_LANGUAGE)
	io.stdout:flush()

	while true do
		local id = io.stdin:read(12)
		if id == nil then
			os.exit(0)
		end
		local action = io.stdin:read("*l")
		if action == nil then
			os.exit(0)
		end
		local size = io.stdin:read("*l")
		size = tonumber(size)
		if size == nil then
			os.exit(0)
		end
		local data = ''
		while size > 0 do
			local v = io.stdin:read(size)
			size = size - #v
			data = data .. v
		end
		-- EOF
		if data == nil or data == "bye" then
			os.exit(0)
		end

		local who, result, wonderful, status, randcount = 0, "", false, "", 0
		if action == "start" then
			xpcall(function()
				who, result, wonderful, status, randcount = startCrossOnlineFightBattle(id, data)
			end, __G__TRACKBACK__)
		elseif action == "input" then
			xpcall(function()
				who, result, wonderful, status, randcount = inputCrossOnlineFightBattle(id, data)
			end, __G__TRACKBACK__)
		elseif action == "close" then
			xpcall(function()
				closeCrossOnlineFightBattle(id)
			end, __G__TRACKBACK__)
		end

		-- response
		local response = {
			id = id,
			next = who,
			result = result,
			wonderful = wonderful,
			status = status,
			rand_cnt = randcount,
			traceback = last_traceback,
		}
		data = msgpack(response)
		-- write length
		io.stderr:write('' .. #data .. '\n')
		io.stderr:write(data)
		io.stderr:flush()
		io.stdout:flush()
	end
end

if STAND_ALONE then
	if OnlineFightModel then
		main = onlinefight_main
	else
		main = stand_alone_main
	end
end

xpcall(main, __G__TRACKBACK__)
