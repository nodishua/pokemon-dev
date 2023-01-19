-- @date: 2019-07-03 17:15:34
-- @desc:设置音效界面

local SettingView = require("app.views.city.setting.view")
local BTN_TYPE = SettingView.BTN_TYPE
local BTN_DATA = SettingView.BTN_DATA

local STATE = {
	OPEN = 100,
	CLOSE = 0,
}

local function setBtnState(btn,btnType,state)
	local t = BTN_DATA[btnType]
	if btnType == BTN_TYPE.BTN then
		btn:texture(state and t.resNormal or t.resSelected)
		local img = btn:get("btnImg")
		if state then
			img:xy(30,30)		-- 固定位置
		else
			img:xy(100,30)		-- 固定位置
		end
	elseif btnType == BTN_TYPE.RADIO then
		btn:get("btnImg"):visible(state)
	end
end

local ViewBase = cc.load("mvc").ViewBase
local SettingVoiceView = class("SettingVoiceView", ViewBase)
SettingVoiceView.RESOURCE_FILENAME = "setting_voice.json"
SettingVoiceView.RESOURCE_BINDING = {
	["centerPanel"] = "centerPanel",
	["centerPanel.itemBgVoice.btn"] = {
		varname = "itemBgVoiceBtn",
		binds = {
			event = "click",
			method = bindHelper.self("onBgVoiceOpen"),
		},
	},
	["centerPanel.itemBgVoice.slider"] = "bgSlider",
	["centerPanel.itemBattleVoice.btn"] = {
		varname = "itemBattleVoiceBtn",
		binds = {
			event = "click",
			method = bindHelper.self("onBattleVocieOpen"),
		},
	},
	["centerPanel.itemBattleVoice.slider"] = "btSlider",
	["centerPanel.slidrBg"] = "sliderBg",
	["centerPanel.item"] = "listItem",
	["centerPanel.musicList"] = {
		varname = "musicList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("listData"),
				item = bindHelper.self("listItem"),
				sliderBg = bindHelper.self("sliderBg"),
				margin = 8,
				onItem = function(list, node, k, v)
					local children = node:multiget("switch", "musicName", "voiceImg", "check")
					children.musicName:text(v.cfg.name)
					children.voiceImg:visible(v.inTest)
					children.check:setSelectedState(v.selected)
					children.switch:setSelectedState(v.inTest)
					bind.touch(list, node, {methods = {ended = functools.partial(list.playMusic, k, v)}})
					children.switch:onEvent(functools.partial(list.playTestMusic, k, v))
				end,
				onBeforeBuild = function(list)
					if list.sliderBg:visible() then
						local listX, listY = list:xy()
						local listSize = list:size()
						local x, y = list.sliderBg:xy()
						local size = list.sliderBg:size()
						list:setScrollBarEnabled(true)
						list:setScrollBarColor(cc.c3b(241, 59, 84))
						list:setScrollBarOpacity(255)
						list:setScrollBarAutoHideEnabled(false)
						list:setScrollBarPositionFromCorner(cc.p(listX + listSize.width - x,(listSize.height - size.height) / 2 + 5))
						list:setScrollBarWidth(size.width)
						list:refreshView()
					else
						list:setScrollBarEnabled(false)
					end
				end,
			},
			handlers = {
				playMusic = bindHelper.self("onPlayMusic"),
				playTestMusic = bindHelper.self("onPlayTestMusic"),
			},
		},
	},
	["centerPanel.text"] = "bottomText",
}

local function setSlider(idler, slider, btn, cbSet, cbGet)
	idler:set(cbGet())
	idlereasy.when(idler, function (obj, val)
		local state = val == STATE.CLOSE
		slider:setPercent(val)
		setBtnState(btn,BTN_TYPE.BTN,state)
		cbSet(val)
	end)
	slider:addEventListener(function(sender,eventType)
		if eventType == ccui.SliderEventType.percentChanged then
			idler:set(sender:getPercent())
		end
	end)
end

function SettingVoiceView:onCreate()
	-- 初始化 按钮和音量条
	self.bgVoiceState = idler.new()
	setSlider(self.bgVoiceState, self.bgSlider, self.itemBgVoiceBtn, function (val)
		local volume = val / 100.0
		audio.setMusicVolume(volume)
		userDefault.setForeverLocalKey("musicVolume", val, {rawKey = true})
	end, function ()
		return userDefault.getForeverLocalKey("musicVolume", 100, {rawKey = true})
	end)

	self.battleVoiceState = idler.new()
	setSlider(self.battleVoiceState, self.btSlider, self.itemBattleVoiceBtn, function (val)
		local volume = val / 100.0
		audio.setSoundsVolume(volume)
		userDefault.setForeverLocalKey("effectVolume", val, {rawKey = true})
	end, function ()
		return userDefault.getForeverLocalKey("effectVolume", 100, {rawKey = true})
	end)

	self.sliderBg:setVisible(csvSize(csv.citysound) > 3)

	-- 当前设置的背景音乐
	local curMusicIdx = userDefault.getForeverLocalKey("musicIdx", 1)
	local listData = {}
	for k, v in orderCsvPairs(csv.citysound) do
		table.insert(listData, {
			cfg = v,
			selected = (curMusicIdx == k), -- 选择
			inTest = false, -- 试听
		})
	end
	self.listData = idlers.newWithMap(listData)
end

-- 战斗声音
function SettingVoiceView:onBattleVocieOpen()
	local state = self.battleVoiceState:read() > STATE.CLOSE
	self.battleVoiceState:set(state and STATE.CLOSE or STATE.OPEN)
end

-- 背景声音
function SettingVoiceView:onBgVoiceOpen()
	local state = self.bgVoiceState:read() > STATE.CLOSE
	self.bgVoiceState:set(state and STATE.CLOSE or STATE.OPEN)
end

function SettingVoiceView:onCleanup()
	if self.inTest then
		local idx = userDefault.getForeverLocalKey("musicIdx", 1)
		audio.playMusic(csv.citysound[idx].path)
	end
	ViewBase.onCleanup(self)
end

function SettingVoiceView:onPlayMusic(list, idx, v)
	for k, listData in self.listData:pairs() do
		local data = listData:proxy()
		data.inTest = false
		data.selected = (k == idx)
	end
	audio.playMusic(v.cfg.path, true, true)
	userDefault.setForeverLocalKey("musicIdx", idx)
end

-- 当前试听的背景音乐 path == nil 表示恢复原本的音乐播放
function SettingVoiceView:onPlayTestMusic(list, idx, v)
	local selectMusicData = nil
	for k, listData in self.listData:pairs() do
		local data = listData:proxy()
		if k == idx then
			data.inTest = not data.inTest
			self.inTest = data.inTest
		else
			data.inTest = false
		end
		if data.selected then
			selectMusicData = data
		end
	end
	if self.inTest then
		audio.playMusic(v.cfg.path, true, true)
	else
		audio.playMusic(selectMusicData.cfg.path)
	end
end

return SettingVoiceView