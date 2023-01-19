--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2017 TianJi Information Technology Inc.
--

local _msgpack = require '3rd.msgpack'
local msgpack = _msgpack.pack
local msgunpack = _msgpack.unpack

local strrep = string.rep
local _aes = require 'aes'
local Hex = _aes.key128Hex
local encrypt = _aes.encryptCBC
local key = Hex('tjshuma081610888')

local url = nil -- "http://192.168.1.148:1104/play_report"

-- 战报实际上传
function battleReport(t)
	if url == nil then
		url = string.gsub(FEED_BACK_URL, 'feedback', 'play_report')
	end

	-- add information in t
	local play_record = t.play_record
	t.serv_key = userDefault.getForeverLocalKey("serverKey", "", {rawKey = true})
	if APP_TAG == "tiyan_test" then
		t.serv_key = "game.trial.1"
	end
	t.role_id = gGameModel.role:read("id")
	t.role_level = gGameModel.role:read("level")
	t.role_vip = gGameModel.role:read("vip_level")
	t.battle_fighting_point = gGameModel.role:read("battle_fighting_point")
	t.patch = PATCH_VERSION
	t.min_patch = PATCH_MIN_VERSION
	t.channel = APP_CHANNEL
	t.tag = APP_TAG
	t.play_id = play_record.battleID
	t.scene_id = play_record.sceneID
	t.play_record = msgpack(play_record)

	-- msgpack
	local pad = 0
	local data = msgpack(t)
	if #data % 16 ~= 0 then
		pad = 16 - (#data % 16)
		data = data .. strrep('\0', pad)
	end
	data = encrypt(data, key)

	-- send
	local xhr = cc.XMLHttpRequest:new()
	xhr.responseType = cc.XMLHTTPREQUEST_RESPONSE_STRING
	xhr.timeout = 20
	xhr:open("POST", url)
	xhr:setRequestHeader("Content-Type", "application/json")
	local function _onReadyStateChange(...)
		-- print('handleLuaException response', xhr.status, xhr.response)
	end
	xhr:registerScriptHandler(_onReadyStateChange)
	xhr:send(msgpack{pad, data})
end

-- 全局触发崩溃、异常战报上传
function triggerBattleReport(info, traceback)
	if ANTI_AGENT then return end
	local rootView = gRootViewProxy:raw()
	if string.find(toDebugString(rootView), "BattleView") then
		local battleScene = rootView._model and rootView._model.scene
		if battleScene then
			battleScene:battleReport(info, traceback)
		end
	end
end