-- @date:   2020-05-26
-- @desc:   跨服竞技场-战斗记录

local function getStrTime(historyTime)
	local timeTable = time.getCutDown(math.max(time.getTime() - historyTime, 0), nil, true)
	local strTime = timeTable.head_date_str
	strTime = strTime..gLanguageCsv.before
	return strTime
end

local CrossArenaCombatRecordView = class("CrossArenaCombatRecordView", Dialog)
CrossArenaCombatRecordView.RESOURCE_FILENAME = "cross_arena_combat_record.json"
CrossArenaCombatRecordView.RESOURCE_BINDING = {
	["title.btnClose"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")},
		},
	},
	["leftPanel"] = "leftPanel",
	["leftPanel.tabItem"] = "tabItem",
	["leftPanel.tabList"] = {
		varname = "tabList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("tabDatas"),
				item = bindHelper.self("tabItem"),
				onItem = function(list, node, k, v)
					local normal = node:get("normal")
					local selected = node:get("selected")
					local panel
					if v.select then
						normal:hide()
						panel = selected:show()
						-- panel:get("txt"):setFontSize(v.fontSize) -- 选中状态排行榜奖励，50，无法放下，调整为45
					else
						selected:hide()
						panel = normal:show()
					end
					panel:get("txt"):getVirtualRenderer():setLineSpacing(-10)
					adapt.setAutoText(panel:get("txt"), v.name, 240)
					selected:setTouchEnabled(false)
					bind.touch(list, normal, {methods = {ended = functools.partial(list.clickCell, k)}})
				end,
			},
			handlers = {
				clickCell = bindHelper.self("onTabClick"),
			},
		},
	},
	["myPanel"] = "myPanel",
	["myPanel.item"] = "item",
	["myPanel.list"] = {
		varname = "list",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				asyncPreload = 4,
				data = bindHelper.self("combatDatas"),
				item = bindHelper.self("item"),
				itemAction = {isAction = true},
				dataOrderCmp = function (a, b)
					return a.time > b.time
				end,
				onItem = function(list, node, k, v)
					local childs = node:multiget(
						"imgBG",
						"head",
						"textName",
						"btnReplay",
						"btnShare",
						"imgFlag",
						"textTime",
						-- "textNum",
						"imgDownOrUp",
						"textLv",
						"textLvNote",
						"iconVip",
						"stage1",
						"stage2",
						"sever",
						"bgDefend",
						"bgAttack",
						"textNoChange"
					)
					childs.textLv:text(v.enemy_level)
					childs.textName:text(v.enemy_name)
					childs.textTime:text(getStrTime(v.time))
					-- if v.enemy_vip ~= 0 then
					-- 	childs.iconVip:texture("common/icon/vip/icon_vip"..v.enemy_vip..".png")
					-- else
					-- 	childs.iconVip:hide()
					-- end
					childs.iconVip:hide()
					childs.sever:text(string.format(gLanguageCsv.brackets, getServerArea(v.key, true)))
					adapt.oneLinePos(childs.textLvNote, {childs.textLv, childs.sever}, {cc.p(0, 0),cc.p(5, 5)})
					adapt.setTextScaleWithWidth(childs.textName, nil, 280)
					adapt.setTextScaleWithWidth(childs.textTime, nil, 500)
					if matchLanguage({"en"}) then
						childs.textTime:x(childs.textTime:x() + 80)
					end
					if v.result == "win" then
						childs.imgDownOrUp:texture("common/icon/logo_arrow_green.png")
						childs.imgDownOrUp:scaleY(1.3)
						childs.imgFlag:texture("city/pvp/craft/icon_win.png")
						childs.imgBG:texture("city/pvp/cross_arena/panel_win.png")
					else
						childs.imgDownOrUp:texture("common/icon/logo_arrow_red.png")
						childs.imgDownOrUp:scaleY(-1.3)
						childs.imgFlag:texture("city/pvp/craft/icon_lose.png")
						childs.imgBG:texture("city/pvp/cross_arena/panel_lose.png")
					end
					bind.extend(list, childs.head, {
						event = "extend",
						class = "role_logo",
						props = {
							logoId = v.enemy_logo,
							frameId = v.enemy_frame,
							level = false,
							vip = false,
						}
					})
					if v.move == 0 then
						childs.textNoChange:show()
						text.addEffect(childs.textNoChange, {outline = {color= cc.c4b(255, 91, 39,255)}})
						childs.stage1:hide()
						childs.stage2:hide()
						childs.imgDownOrUp:hide()
					else
						childs.textNoChange:hide()
						childs.stage1:show()
						childs.stage2:show()
						bind.extend(list, childs.stage1, {
							event = "extend",
							class = "stage_icon",
							props = {
								rank = v.enemy_rank + v.move,
								showStageBg = true,
								showStage = true,
								showRank = true,
								onNodeClick = nil,
								onNode = function(node)
									node:xy(60, 35)
										:z(6)
										:scale(0.9)
								end,
							}
						})
						bind.extend(list, childs.stage2, {
							event = "extend",
							class = "stage_icon",
							props = {
								rank = v.enemy_rank,
								showStageBg = true,
								showStage = true,
								showRank = true,
								onNodeClick = nil,
								onNode = function(node)
									node:xy(60, 35)
										:z(6)
										:scale(0.9)
								end,
							}
						})
					end
					if v.battle_mode == 1 then
						childs.bgAttack:show()
						childs.bgDefend:hide()
					else
						childs.bgAttack:hide()
						childs.bgDefend:show()
					end
					text.addEffect(childs.btnReplay:get("textNote"), {outline = {color=ui.COLORS.OUTLINE.WHITE}})
					bind.touch(list, childs.btnReplay, {methods = {ended = functools.partial(list.playbackBtn, k, v)}})
					-- childs.btnShare:hide()
					text.addEffect(childs.btnShare:get("textNote"), {outline = {color=ui.COLORS.OUTLINE.WHITE}})
					bind.touch(list, childs.btnShare, {methods = {ended = functools.partial(list.shareBtn, k, v)}})
					bind.touch(list, node, {methods = {ended = functools.partial(list.clickCell, v)}})
				end,
				onAfterBuild = function(list)
				end,
			},
			handlers = {
				afterBuild = bindHelper.self("onAfterBuild"),
				playbackBtn = bindHelper.self("onPlaybackClick"),
				shareBtn = bindHelper.self("onShareClick"),
				clickCell = bindHelper.self("onItemClick"),
			},
		},
	},
	["goodPanel"] = "goodPanel",
	["goodPanel.item"] = "item1",
	["goodPanel.list"] = {
		varname = "list1",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				asyncPreload = 4,
				data = bindHelper.self("bestData"),
				item = bindHelper.self("item1"),
				itemAction = {isAction = true},
				onItem = function(list, node, k, v)
					local childs = node:multiget(
						"head1",
						"textName",
						"textName1",
						"stage1",
						"stage2",
						"btnReplay",
						"head2",
						"txtTop",
						"txtTop1",
						"textTop",
						"textTop1",
						"textServe",
						"textServe1",
						"txtLvNode",
						"txtLvNode1",
						"txtLv",
						"txtLv1",
						"imgFlag",
						"imgFlag1",
						"imgBG"
					)
					childs.textName:text(v.name )
					childs.textName1:text(v.defence_name)
					bind.extend(list, childs.head1, {
						event = "extend",
						class = "role_logo",
						props = {
							logoId = v.logo,
							frameId = v.frame,
							level = false,
							vip = false,
						}
					})
					bind.extend(list, childs.head2, {
						event = "extend",
						class = "role_logo",
						props = {
							logoId = v.defence_logo,
							frameId = v.defence_frame,
							level = false,
							vip = false,
						}
					})
					bind.extend(list, childs.stage1, {
						event = "extend",
						class = "stage_icon",
						props = {
							rank = v.rank,
							showStageBg = false,
							showStage = false,
							showRank = false,
							onNodeClick = nil,
							onNode = function(node)
								node:xy(60, 35)
									:z(6)
									:scale(0.9)
							end,
						}
					})
					bind.extend(list, childs.stage2, {
						event = "extend",
						class = "stage_icon",
						props = {
							rank = v.defence_rank,
							showStageBg = false,
							showStage = false,
							showRank = false,
							onNodeClick = nil,
							onNode = function(node)
								node:xy(60, 35)
									:z(6)
									:scale(0.9)
							end,
						}
					})
					if v.result == "win" then
						childs.imgBG:texture("city/pvp/cross_arena/list_bg_1.png")
						childs.imgFlag:texture("city/pvp/craft/icon_win.png")
						childs.imgFlag1:texture("city/pvp/craft/icon_lose.png")
					else
						childs.imgBG:texture("city/pvp/cross_arena/list_bg_2.png")
						childs.imgFlag1:texture("city/pvp/craft/icon_win.png")
						childs.imgFlag:texture("city/pvp/craft/icon_lose.png")
					end
					local stageInfo = dataEasy.getCrossArenaStageByRank(v.rank)
					local stageInfo1 = dataEasy.getCrossArenaStageByRank(v.defence_rank)
					childs.txtTop:text(stageInfo.stageName.." "..stageInfo.rank)
					childs.txtTop1:text(stageInfo1.stageName.." "..stageInfo1.rank)
					childs.textServe:text(string.format(gLanguageCsv.brackets, getServerArea(v.role_key[1])))
					childs.textServe1:text(string.format(gLanguageCsv.brackets, getServerArea(v.defence_role_key[1])))
					childs.txtLv:text(v.level)
					childs.txtLv1:text(v.defence_level)
					text.addEffect(childs.txtLv, {outline = {color = ui.COLORS.OUTLINE.DEFAULT}})
					text.addEffect(childs.txtLv1, {outline = {color = ui.COLORS.OUTLINE.DEFAULT}})
					text.addEffect(childs.txtLvNode, {outline = {color = ui.COLORS.OUTLINE.DEFAULT}})
					text.addEffect(childs.txtLvNode1, {outline = {color = ui.COLORS.OUTLINE.DEFAULT}})
					adapt.oneLineCenterPos(cc.p(550, 60), {childs.textName, childs.textServe}, cc.p(0, 0))
					adapt.oneLineCenterPos(cc.p(1500, 60), {childs.textName1, childs.textServe1}, cc.p(0, 0))
					bind.touch(list, node, {methods = {ended = functools.partial(list.clickCell, k, v)}})
					bind.touch(list, childs.btnReplay, {methods = {ended = functools.partial(list.playbackBtn, k, v)}})
				end,
				onAfterBuild = function(list)
				end,
			},
			handlers = {
				clickCell = bindHelper.self("oninfoClick"),
				playbackBtn = bindHelper.self("onPlaybackClick"),
			},
		},
	},
	["emptyPanel"] = "emptyPanel",
	["emptyPanel.emptyTxt"] = "emptyTxt",
}

function CrossArenaCombatRecordView:onCreate()
	self:initModel()
	self.emptyPanel:hide()
	self.myPanel:hide()
	self.goodPanel:hide()
	self.combatDatas = self.record:read().history
	self.bestData = self.bestRecord:read()
	-- self.tabList:hide()
	self.showTab = idler.new(1)

	self.panel = {
		{
			node = self.myPanel,
			data = self.combatDatas,
			txtNode = gLanguageCsv.noBattleRecord
		},
		{
			node = self.goodPanel,
			data = self.bestData,
			txtNode = gLanguageCsv.noBestRecord
		},
	}

	self.tabDatas = idlers.newWithMap({
		[1] = {name = gLanguageCsv.myBattle, fontSize = 50},
		[2] = {name = gLanguageCsv.bestBattle, fontSize = 50},
	})

	if self.tmp == 2 then
		self.showTab:set(2)
	end
	self.showTab:addListener(function(val, oldval)
		self.tabDatas:atproxy(oldval).select = false
		self.tabDatas:atproxy(val).select = true
		self.panel[oldval].node:hide()
		self.panel[val].node:show()
		local isempty = itertools.isempty(self.panel[val].data)
		self.emptyPanel:visible(isempty)
		self.emptyTxt:text(self.panel[val].txtNode)
	end)

	Dialog.onCreate(self)
end

function CrossArenaCombatRecordView:initModel()
	self.record = gGameModel.cross_arena:getIdler("record")
	self.bestRecord = gGameModel.cross_arena:getIdler("topBattleHistory")
	if not self.tmp then
		self.tmp = 0
	end
end

function CrossArenaCombatRecordView:onPlaybackClick(list, k, v)
	local interface = "/game/cross/arena/playrecord/get"
	gGameModel:playRecordBattle(v.play_record_id, v.cross_key, interface, 0, nil)
end

function CrossArenaCombatRecordView:oninfoClick(list, k, v)
	local interface = "/game/cross/arena/playrecord/get"
	local personalInfo = gGameModel:playRecordDeployInfo(v.play_record_id, v.cross_key, interface,
		function(personalInfo)
			gGameUI:stackUI("city.pvp.cross_arena.record_info", nil, {clickClose = true, blackLayer = true}, personalInfo)
		end
	)
end

function CrossArenaCombatRecordView:onItemClick(k, v)
	gGameApp:requestServer("/game/cross/arena/role/info", function(tb)
		gGameUI:stackUI("city.pvp.cross_arena.personal_info", nil, {clickClose = true, blackLayer = true}, tb.view)
	end,v.enemy_record_id, v.key, v.enemy_rank)
end

function CrossArenaCombatRecordView:onTabClick(list, index)
	self.showTab:set(index)
	self.tmp = index
end

function CrossArenaCombatRecordView:onShareClick(list, k, v)
	local battleShareTimes = gGameModel.daily_record:read("cross_arena_battle_share_times")
	if battleShareTimes >= gCommonConfigCsv.shareTimesLimit then
		gGameUI:showTip(gLanguageCsv.shareTimesNotEnough)
		return
	end
	local leftTimes = gCommonConfigCsv.shareTimesLimit - battleShareTimes
	local params = {
		cb = function()
			gGameApp:requestServer("/game/battle/share", function(tb)
				gGameUI:showTip(gLanguageCsv.recordShareSuccess)
			end, v.play_record_id, v.enemy_name, "crossArena", v.cross_key)
		end,
		isRich = false,
		btnType = 2,
		content = string.format(gLanguageCsv.shareBattleNote, leftTimes .. "/" .. gCommonConfigCsv.shareTimesLimit),
	}
	gGameUI:showDialog(params)
end

return CrossArenaCombatRecordView
