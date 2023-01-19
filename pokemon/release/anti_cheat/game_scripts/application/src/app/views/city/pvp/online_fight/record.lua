-- @date 2020-8-19
-- @desc 实时匹配战斗情报

local function getStrTime(historyTime)
	local timeTable = time.getCutDown(math.max(time.getTime() - historyTime, 0), nil, true)
	local strTime = timeTable.head_date_str
	strTime = strTime..gLanguageCsv.before
	return strTime
end

local ViewBase = cc.load("mvc").ViewBase
local OnlineFightRecordView = class("OnlineFightRecordView", Dialog)

OnlineFightRecordView.RESOURCE_FILENAME = "online_fight_record.json"
OnlineFightRecordView.RESOURCE_BINDING = {
	["topPanel.btnClose"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")},
		},
	},
	["leftPanel.tabItem"] = "stateItem",
	["leftPanel.tabList"] = {
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("stateDatas"),
				item = bindHelper.self("stateItem"),
				onItem = function(list, node, k, v)
					local normal = node:get("normal")
					local selected = node:get("selected")
					local panel
					if v.select then
						normal:hide()
						panel = selected:show()
					else
						selected:hide()
						panel = normal:show()
					end
					panel:get("txt"):getVirtualRenderer():setLineSpacing(-5)
					adapt.setAutoText(panel:get("txt"), v.name)
					selected:setTouchEnabled(false)
					bind.touch(list, normal, {methods = {ended = functools.partial(list.clickCell, k)}})
				end,
			},
			handlers = {
				clickCell = bindHelper.self("onStateClick"),
			},
		},
	},
	["tabItem"] = "tabItem",
	["tabList"] = {
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("tabDatas"),
				item = bindHelper.self("tabItem"),
				onItem = function(list, node, k, v)
					node:get("name"):text(v.name)
					text.deleteAllEffect(node:get("name"))
					if v.select then
						node:get("icon"):texture("common/btn/btn_nomal_2.png")
						text.addEffect(node:get("name"), {color = ui.COLORS.NORMAL.WHITE, glow = {color = ui.COLORS.GLOW.WHITE}})
					else
						node:get("icon"):texture("common/btn/btn_nomal_3.png")
						text.addEffect(node:get("name"), {color = ui.COLORS.NORMAL.RED})
					end
					bind.touch(list, node, {methods = {ended = functools.partial(list.clickCell, k)}})
				end,
			},
			handlers = {
				clickCell = bindHelper.self("onTabClick"),
			},
		},
	},
	["item1"] = "item1",
	["list1"] = {
		varname = "list1",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("data1"),
				item = bindHelper.self("item1"),
				dataOrderCmp = function(a, b)
					return a.time > b.time
				end,
				itemAction = {isAction = true},
				onItem = function(list, node, k, v)
					local childs = node:multiget("imgBG", "imgFlag", "head", "textName", "textLvNote", "textLv", "server", "textTime",
						"btnReplay", "btnShare", "scoreNoChange", "scoreChange")
					childs.textLv:text(v.enemy.level)
					childs.textName:text(v.enemy.name)
					childs.textTime:text(getStrTime(v.time))
					childs.server:text(string.format(gLanguageCsv.brackets, getServerArea(v.enemy.game_key, true)))
					adapt.oneLinePos(childs.textName, {childs.textLvNote, childs.textLv}, {cc.p(5, 0), cc.p(0, 0)})
					adapt.setTextScaleWithWidth(childs.textName, nil, 280)
					adapt.setTextScaleWithWidth(childs.textTime, nil, 500)
					if v.result == "win" then
						childs.imgBG:texture("city/pvp/cross_arena/panel_win.png")
						childs.imgFlag:texture("city/pvp/craft/icon_win.png")
					else
						childs.imgBG:texture("city/pvp/cross_arena/panel_lose.png")
						childs.imgFlag:texture("city/pvp/craft/icon_lose.png")
					end
					childs.scoreNoChange:visible(v.delta == 0)
					childs.scoreChange:visible(v.delta ~= 0)
					if v.delta ~= 0 then
						childs.scoreChange:get("score"):text(gLanguageCsv.score .. ": " .. v.score)
						childs.scoreChange:get("arrow"):texture(v.delta > 0 and "common/icon/logo_arrow_green.png" or "common/icon/logo_arrow_red.png")
						childs.scoreChange:get("change"):text(math.abs(v.delta))
						text.addEffect(childs.scoreChange:get("change"), {color = v.delta > 0 and cc.c4b(73, 185, 115, 255) or cc.c4b(221, 95, 113, 255)})
					end
					adapt.oneLinePos(childs.scoreChange:get("score"), {childs.scoreChange:get("arrow"), childs.scoreChange:get("change")}, {cc.p(5, 0), cc.p(5, 0)})
					bind.extend(list, childs.head, {
						event = "extend",
						class = "role_logo",
						props = {
							logoId = v.enemy.logo,
							frameId = v.enemy.frame,
							level = false,
							vip = false,
						}
					})
					text.addEffect(childs.btnReplay:get("textNote"), {outline = {color=ui.COLORS.OUTLINE.WHITE}})
					bind.touch(list, childs.btnReplay, {methods = {ended = functools.partial(list.playbackBtn, k, v)}})

					text.addEffect(childs.btnShare:get("textNote"), {outline = {color=ui.COLORS.OUTLINE.WHITE}})
					bind.touch(list, childs.btnShare, {methods = {ended = functools.partial(list.shareBtn, k, v)}})
				end,
			},
			handlers = {
				playbackBtn = bindHelper.self("onPlaybackClick"),
				shareBtn = bindHelper.self("onShareClick"),
			},
		},
	},
	["item2"] = "item2",
	["list2"] = {
		varname = "list2",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("data2"),
				item = bindHelper.self("item2"),
				dataOrderCmp = function(a, b)
					return a.time > b.time
				end,
				itemAction = {isAction = true},
				onItem = function(list, node, k, v)
					local t = {
						[1] = {
							result = v.result == "win",
							name = v.name,
							game_key = v.role_key[1],
							level = v.level,
							rank = v.rank,
							score = v.score,
							logo = v.logo,
							frame = v.frame,
						},
						[2] = {
							result = v.result ~= "win",
							name = v.defence_name,
							game_key = v.defence_role_key[1],
							level = v.defence_level,
							rank = v.defence_rank,
							score = v.defence_score,
							logo = v.defence_logo,
							frame = v.defence_frame,
						},
					}
					for i = 1, 2 do
						local data = t[i]
						local childs = node:get(i == 1 and "leftPanel" or "rightPanel"):multiget("imgFlag", "head", "rank", "score", "name", "server", "txtLv", "level")
						childs.imgFlag:texture(data.result and "city/pvp/craft/icon_win.png" or "city/pvp/craft/icon_lose.png")
						childs.name:text(data.name)
						childs.server:text(string.format(gLanguageCsv.brackets, getServerArea(data.game_key, true)))
						adapt.oneLinePos(childs.name, childs.server, cc.p(5, 0))
						childs.level:text(data.level)
						childs.rank:text(gLanguageCsv.ranking .. ":" .. data.rank)
						childs.score:text(gLanguageCsv.score .. ":" .. data.score)
						bind.extend(list, childs.head, {
							event = "extend",
							class = "role_logo",
							props = {
								logoId = data.logo,
								frameId = data.frame,
								level = false,
								vip = false,
							}
						})
						text.addEffect(childs.txtLv, {outline = {color=ui.COLORS.OUTLINE.DEFAULT}})
						text.addEffect(childs.level, {outline = {color=ui.COLORS.OUTLINE.DEFAULT}})

					end
					node:get("imgBG"):texture(t[1].result and "city/pvp/cross_arena/list_bg_1.png" or "city/pvp/cross_arena/list_bg_2.png")
					text.addEffect(node:get("btnReplay.textNote"), {outline = {color=ui.COLORS.OUTLINE.WHITE}})
					bind.touch(list, node:get("btnReplay"), {methods = {ended = functools.partial(list.playbackBtn, k, v)}})

					bind.touch(list, node, {methods = {ended = functools.partial(list.itemClick, k, v)}})
				end,
			},
			handlers = {
				playbackBtn = bindHelper.self("onPlaybackClick"),
				itemClick = bindHelper.self("onItemClick"),
			},
		},
	},
	["noRankPanel"] = "noRankPanel",
}

-- showTab 1.公平赛 2.无限制赛
function OnlineFightRecordView:onCreate(showTab)
	-- 我的对决，精彩对决
	self.stateDatas = idlers.newWithMap({
		[1] = {name = gLanguageCsv.onlineFightRecordType1},
		[2] = {name = gLanguageCsv.onlineFightRecordType2},
	})
	self.tabDatas = idlers.newWithMap({
		[1] = {name = gLanguageCsv.onlineFightLimited},
		[2] = {name = gLanguageCsv.onlineFightUnlimited},
	})
	self.datas = {
		[1] = {
			[1] = {
				data = table.deepcopy(gGameModel.cross_online_fight:read("limited_history"), true),
			},
			[2] = {
				data = table.deepcopy(gGameModel.cross_online_fight:read("unlimited_history"), true),
			},
		},
		[2] = {
			[1] = {
				data = table.deepcopy(gGameModel.cross_online_fight:read("limited_top_battle_history"), true),
			},
			[2] = {
				data = table.deepcopy(gGameModel.cross_online_fight:read("unlimited_top_battle_history"), true),
			},
		},
	}
	for i = 1, 2 do
		self["data" .. i] = idlers.new()
		self["list" .. i]:hide()
	end

	self.showState = idler.new(self._showState or 1)
	self.showTab = idler.new(self._showTab or showTab)
	idlereasy.any({self.showState, self.showTab}, function(_, state, tab)
		for i = 1, 2 do
			if state ~= i then
				self.stateDatas:atproxy(i).select = false
				self["list" .. i]:hide()
			end
		end
		self.stateDatas:atproxy(state).select = true
		self["list" .. state]:show()
		for i = 1, 2 do
			if tab ~= i then
				self.tabDatas:atproxy(i).select = false
			end
		end
		self.tabDatas:atproxy(tab).select = true
		local data = self.datas[state][tab].data
		self["data" .. state]:update(data)
		self.noRankPanel:visible(itertools.size(data) == 0)
	end)
	Dialog.onCreate(self)
end

function OnlineFightRecordView:onCleanup()
	self._showState = self.showState:read()
	self._showTab = self.showTab:read()
	ViewBase.onCleanup(self)
end

function OnlineFightRecordView:onStateClick(list, index)
	self.showState:set(index)
end

function OnlineFightRecordView:onTabClick(list, index)
	self.showTab:set(index)
end

function OnlineFightRecordView:onPlaybackClick(list, k, v)
	-- 战斗是否有数据
	if v.frames and v.frames[2] <= 0 then
		gGameUI:showTip(gLanguageCsv.noPlayBack)
		return
	end
	gGameModel:playRecordBattle(v.play_record_id, v.cross_key, "/game/cross/online/playrecord/get", 2)
end

function OnlineFightRecordView:onShareClick(list, k, v)
	if v.frames and v.frames[2] <= 0 then
		gGameUI:showTip(gLanguageCsv.noPlayBack)
		return
	end
	local battleShareTimes = gGameModel.daily_record:read("cross_online_fight_share_times")
	if battleShareTimes >= gCommonConfigCsv.shareTimesLimit then
		gGameUI:showTip(gLanguageCsv.shareTimesNotEnough)
		return
	end
	local leftTimes = gCommonConfigCsv.shareTimesLimit - battleShareTimes
	gGameUI:showDialog({
		cb = function()
			gGameApp:requestServer("/game/battle/share", function(tb)
				gGameUI:showTip(gLanguageCsv.recordShareSuccess)
			end, v.play_record_id, v.enemy.name, "onlineFight", v.cross_key)
		end,
		isRich = false,
		btnType = 2,
		content = string.format(gLanguageCsv.shareBattleNote, leftTimes .. "/" .. gCommonConfigCsv.shareTimesLimit),
	})
end

function OnlineFightRecordView:onItemClick(list, k, v)
	local showTab = self.showTab:read()
	local interface = "/game/cross/online/playrecord/get"
	gGameModel:playRecordDeployInfo(v.play_record_id, v.cross_key, interface, function(personalInfo)
		gGameUI:stackUI("city.pvp.online_fight.record_info", nil, nil, personalInfo, showTab)
	end)
end

return OnlineFightRecordView