
local function getStrTime(historyTime)
	local timeTable = time.getCutDown(math.max(time.getTime() - historyTime, 0), nil, true)
	local strTime = timeTable.head_date_str
	strTime = strTime..gLanguageCsv.before
	return strTime
end

local CrossUnionFightRecordView = class("CrossUnionFightRecordView", Dialog)
CrossUnionFightRecordView.RESOURCE_FILENAME = "cross_union_fight_record.json"
CrossUnionFightRecordView.RESOURCE_BINDING = {
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
					panel:get("txt"):text(v.name)
					--adapt.setAutoText(panel:get("txt"), v.name, 240)
					selected:setTouchEnabled(false)
					bind.touch(list, normal, {methods = {ended = functools.partial(list.clickCell, k)}})
				end,
			},
			handlers = {
				clickCell = bindHelper.self("onTabClick"),
			},
		},
	},
	["goodPanel"] = "goodPanel",
	["goodPanel.item"] = "item1",
	["goodPanel.slider"] = "slider",
	["goodPanel.list"] = {
		varname = "list1",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				asyncPreload = 6,
				data = bindHelper.self("battleData"),
				item = bindHelper.self("item1"),
				dataOrderCmp = function(a, b)
					return a.idx > b.idx
				end,
				itemAction = {isAction = true},
				sliderBg = bindHelper.self("slider"),
				onItem = function(list, node, k, v)
					local tips = node:get("tips")
					local dataPlane = node:get("dataPlane")
					node:size(cc.size(1600,265))
					if v.type == "title" then
						node:size(cc.size(1600,100))
						tips:xy(800,50)
						dataPlane:hide()
						tips:show()
						tips:get("txt"):text(string.format(gLanguageCsv.roundBattle, v.round))
					else
						local childs = dataPlane:multiget("head1", "btnReplay", "head2", "txtTop", "txtTop1",
								"txtLvNode", "txtLvNode1", "txtLv", "txtLv1", "imgFlag", "imgFlag1", "imgBG", "textName",
								"textName1", "teams", "teams1", "textServe", "textServe1", "empty", "empty1")
						for _, val in pairs(childs) do
							val:show()
						end
						-- left player
						local leftData = v.left
						if itertools.isempty(leftData.userData) or leftData.troop == 0 then
							itertools.invoke({childs.imgFlag, childs.imgFlag1, childs.head1, childs.textName,
								 childs.txtTop, childs.txtLvNode, childs.txtLv, childs.teams, childs.btnReplay, childs.textServe}, "hide")
						else
							childs.empty:hide()
							bind.extend(list, childs.head1, {
								event = "extend",
								class = "role_logo",
								props = {
									logoId = leftData.userData.role_logo,
									frameId = leftData.userData.role_frame,
									level = false,
									vip = false,
								}
							})
							childs.textName:text(leftData.userData.role_name)
							childs.txtTop:text(leftData.union_name)
							childs.txtLv:text(leftData.userData.role_level)
							childs.teams:text(gLanguageCsv.team .. gLanguageCsv["symbolNumber" .. leftData.troop])
						end
						--- right player
						local rightData = v.right
						if itertools.isempty(leftData.userData) or rightData.troop == 0 then
							itertools.invoke({childs.imgFlag, childs.imgFlag1, childs.head2, childs.textName1,
								childs.txtTop1, childs.txtLvNode1, childs.txtLv1, childs.teams1, childs.btnReplay, childs.textServe1}, "hide")
						else
							childs.empty1:hide()
							bind.extend(list, childs.head2, {
								event = "extend",
								class = "role_logo",
								props = {
									logoId = rightData.userData.role_logo,
									frameId = rightData.userData.role_frame,
									level = false,
									vip = false,
								}
							})
							childs.textName1:text(rightData.userData.role_name)
							childs.txtTop1:text(rightData.union_name)
							childs.txtLv1:text(rightData.userData.role_level)
							childs.teams1:text(gLanguageCsv.team .. gLanguageCsv["symbolNumber" .. leftData.troop])
						end
						if v.result == "win" then
							childs.imgBG:texture("city/pvp/cross_arena/list_bg_1.png")
							childs.imgFlag:texture("city/pvp/craft/icon_win.png")
							childs.imgFlag1:texture("city/pvp/craft/icon_lose.png")
						else
							childs.imgBG:texture("city/pvp/cross_arena/list_bg_2.png")
							childs.imgFlag1:texture("city/pvp/craft/icon_win.png")
							childs.imgFlag:texture("city/pvp/craft/icon_lose.png")
						end
						text.addEffect(childs.txtLv, {outline = {color = ui.COLORS.OUTLINE.DEFAULT}})
						text.addEffect(childs.txtLv1, {outline = {color = ui.COLORS.OUTLINE.DEFAULT}})
						text.addEffect(childs.txtLvNode, {outline = {color = ui.COLORS.OUTLINE.DEFAULT}})
						text.addEffect(childs.txtLvNode1, {outline = {color = ui.COLORS.OUTLINE.DEFAULT}})

						--bind.touch(list, node, {methods = {ended = functools.partial(list.clickCell, k, v)}})
						bind.touch(list, childs.btnReplay, {methods = {ended = functools.partial(list.playbackBtn, k, v)}})
					end
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
						list:setScrollBarPositionFromCorner(cc.p(listX + listSize.width - x,(listSize.height - size.height) / 2 + 15))
						list:setScrollBarWidth(size.width)
						list:refreshView()
					else
						list:setScrollBarEnabled(false)
					end
				end,
			},
			handlers = {
				--clickCell = bindHelper.self("oninfoClick"),
				playbackBtn = bindHelper.self("onPlaybackClick"),
			},
		},
	},
	["emptyPanel"] = "emptyPanel",
	["emptyPanel.emptyTxt"] = "emptyTxt",
}

function CrossUnionFightRecordView:onCreate(data, index, unionId)
	self:initModel()
	self.showTab = idler.new(1)
	self.unionId = unionId
	self.allData = data[index] or {} -- 战区数据
	self.battleData = idlers.new()
	self.tabDatas = idlers.newWithMap({
		[1] = {name = gLanguageCsv.crossUnionFightEmbattle1, fontSize = 50},
		[2] = {name = gLanguageCsv.crossUnionFightEmbattle2, fontSize = 50},
		[3] = {name = gLanguageCsv.crossUnionFightEmbattle3, fontSize = 50},
	})
	self.showTab:addListener(function(val, oldval)
		self.tabDatas:atproxy(oldval).select = false
		self.tabDatas:atproxy(val).select = true
		if itertools.isempty(self.allData[val]) then
			self.emptyPanel:show()
			self.goodPanel:hide()
		else
			self.emptyPanel:hide()
			self.goodPanel:show()
		end
		self.battleData:update(self:getUserInfoDataTable(self.allData[val]))
	end)

	Dialog.onCreate(self)
end

function CrossUnionFightRecordView:getUserInfoDataTable(data)
	local battleData = {}
	local round, index = 1,1
	for i, v in pairs(data or {}) do
		local tb = table.shallowcopy(v)
		if tb.round ~= round then
			table.insert(battleData, {type = "title", round = round, idx = index})
			index = index + 1
			round = tb.round
		end
		tb.left.userData = self.userInfo[tb.left.role_db_id] or {}
		tb.right.userData = self.userInfo[tb.right.role_db_id] or {}

		if self.unionId and tb.right.union_db_id == self.unionId then
			local tmp = tb.right
			tb.right = tb.left
			tb.left = tmp
			if tb.result == "win" then
				tb.result = "fail"
			else
				tb.result = "win"
			end
			--else
			--	tb.left.userData = self.userInfo[tb.left.role_db_id] or {}
			--	tb.right.userData = self.userInfo[tb.right.role_db_id] or {}
		end
		tb.idx = index
		table.insert(battleData, tb)
		index = index + 1
	end
	table.insert(battleData, {type = "title", round = round, idx = index})
	self.slider:setVisible(#battleData > 6)
	return battleData
end

function CrossUnionFightRecordView:initModel()
	self.userInfo = gGameModel.cross_union_fight:read("roles")
end

function CrossUnionFightRecordView:onPlaybackClick(list, k, v)
	local interface = "/game/cross/union/fight/playrecord/get"
	gGameModel:playRecordBattle(v.play_id, v.cross_key, interface, 0, nil)
end

function CrossUnionFightRecordView:oninfoClick(list, k, v)
end

function CrossUnionFightRecordView:onItemClick(k, v)
end

function CrossUnionFightRecordView:onTabClick(list, index)
	self.showTab:set(index)
end

return CrossUnionFightRecordView
