-- @date:   2020-12-29
-- @desc:   工会-精灵问答

local function getStrTime(historyTime)
	local timeTable = time.getCutDown(math.max(time.getTime() - historyTime, 0), nil, true)
	local strTime = timeTable.head_date_str
	strTime = strTime..gLanguageCsv.before
	return strTime
end

local CHOOSENUM = {8, 6, 7}

local UnionAnswerRankView = class("UnionAnswerRankView", Dialog)
UnionAnswerRankView.RESOURCE_FILENAME = "union_answer_rank.json"
UnionAnswerRankView.RESOURCE_BINDING = {
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
						panel:get("txt"):setFontSize(v.fontSize) -- 选中状态排行榜奖励，50，无法放下，调整为45
					else
						selected:hide()
						panel = normal:show()
					end
					panel:get("txt"):getVirtualRenderer():setLineSpacing(-10)
					adapt.setAutoText(panel:get("txt"), v.name, 240)
					adapt.setTextScaleWithWidth(panel:get("txt"), nil, 50)
					selected:setTouchEnabled(false)
					bind.touch(list, normal, {methods = {ended = functools.partial(list.clickCell, k)}})
				end,
			},
			handlers = {
				clickCell = bindHelper.self("onTabClick"),
			},
		},
	},
	["list1"] = "list1",
	["item"] = "item",
	["list"] = {
		varname = "list",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("roleData"),
				item = bindHelper.self("item"),
				margin = 10,
				asyncPreload = 4,
				onItem = function(list, node, k, v)
					local childs = node:multiget("imgIcon", "head", "textName", "textFightPoint", "textRank1", "textRank2", "server", "textName1")
					uiEasy.setRankIcon(k, childs.imgIcon, childs.textRank1, childs.textRank2)
					childs.textName:text(v.name)
					childs.textName1:text(v.name1)
					childs.textFightPoint:text(v.score)
					childs.server:text(string.format(gLanguageCsv.brackets, getServerArea(v.gameKey, true)))
					bind.extend(list, childs.head, {
						event = "extend",
						class = "role_logo",
						props = {
							logoId = v.logo,
							frameId = v.frame,
							level = false,
							vip = false,
						}
					})
				end,
			},
			handlers = {
			},
		},
	},
	["list1"] = {
		varname = "list1",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("unionData"),
				item = bindHelper.self("item"),
				margin = 10,
				asyncPreload = 4,
				onItem = function(list, node, k, v)
					local childs = node:multiget("imgIcon", "head", "textName", "textFightPoint", "textRank1", "textRank2", "server", "textName1")
					uiEasy.setRankIcon(k, childs.imgIcon, childs.textRank1, childs.textRank2)
					childs.textName:text(v.name)
					childs.textFightPoint:text(v.score)
					childs.textName1:text(v.name1)
					childs.server:text(string.format(gLanguageCsv.brackets, getServerArea(v.gameKey, true)))
					local imgBg = ccui.ImageView:create(csv.union.union_logo[v.logo].icon)
						:addTo(childs.head)
						:scale(2)
						:xy(childs.head:size().width/2, childs.head:size().height/2)
				end,
			},
			handlers = {
			},
		},
	},
	["down"] = "downPanel",
	["btn1"] = {
		varname = "btn1",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.defer(function(view)
				return view:onBtn(1)
			end)}
		},
	},
	["btn2"] = {
		varname = "btn2",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.defer(function(view)
				return view:onBtn(2)
			end)}
		},
	},
	["btn3"] = {
		varname = "btn3",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.defer(function(view)
				return view:onBtn(3)
			end)}
		},
	},
	["emptyPanel"] = "emptyPanel",
}

function UnionAnswerRankView:onCreate(tb)
	self:initModel()
	-- self.tabList:hide()
	self.showTab = idler.new(1)
	self.list:setScrollBarEnabled(false)
	self.list1:setScrollBarEnabled(false)
	self.rankType = idler.new(1)
	local data = tb.view
	self.roleData = idlers.new({})
	self.unionData = idlers.new({})

	self.panel = {
		{
			node = self.list1,
		},
		{
			node = self.list,
		},
	}

	idlereasy.when(self.rankType, function (_, rankType)
		self.btn1:setBright(rankType == 1)
		self.btn2:setBright(rankType == 2)
		self.btn3:setBright(rankType == 3)
		text.addEffect(self.btn1:get("txt"), {color = rankType == 1 and ui.COLORS.NORMAL.WHITE or ui.COLORS.NORMAL.RED})
		text.addEffect(self.btn2:get("txt"), {color = rankType == 2 and ui.COLORS.NORMAL.WHITE or ui.COLORS.NORMAL.RED})
		text.addEffect(self.btn3:get("txt"), {color = rankType == 3 and ui.COLORS.NORMAL.WHITE or ui.COLORS.NORMAL.RED})
		local roleData = {}
		local unionData = {}
		if data[CHOOSENUM[rankType]] and data[CHOOSENUM[rankType]].role_ranks then
			for k, v in ipairs(data[CHOOSENUM[rankType]].role_ranks) do
				table.insert(roleData, {logo = v.logo, name = v.name, score = v.score, gameKey = v.game_key, frame = v.frame, name1 = v.union_name})
			end
		end
		if data[CHOOSENUM[rankType]] and data[CHOOSENUM[rankType]].union_ranks then
			for k, v in ipairs(data[CHOOSENUM[rankType]].union_ranks) do
				table.insert(unionData, {logo = v.logo, name = v.name, score = v.score, gameKey = v.game_key, name1 = v.chairman})
			end
		end
		self.roleData:update(roleData)
		self.unionData:update(unionData)
		-- self.emptyPanel:visible(itertools.isempty(unionData))
	end)

	self.tabDatas = idlers.newWithMap({
		[1] = {name = gLanguageCsv.unionRank, fontSize = 50},
		[2] = {name = gLanguageCsv.personalRank, fontSize = 50},
	})

	self.showTab:addListener(function(val, oldval)
		self.tabDatas:atproxy(oldval).select = false
		self.tabDatas:atproxy(val).select = true
		self.panel[oldval].node:hide()
		self.panel[val].node:show()
	end)

	idlereasy.any({self.rankType, self.showTab}, function (_, rankType, showTab)
		local childs = self.downPanel:multiget("num", "textRank", "textName", "textName1", "server")
		local downData = {}
		if data[CHOOSENUM[rankType]] then
			if showTab == 2 then
				downData = data[CHOOSENUM[rankType]].my_rank
				childs.textName:text(self.roleId)
				childs.textName1:text(self.unionName)
				self.emptyPanel:visible(itertools.isempty(data[CHOOSENUM[rankType]].role_ranks))
				self.downPanel:visible(not itertools.isempty(data[CHOOSENUM[rankType]].role_ranks))
			else
				downData = data[CHOOSENUM[rankType]].my_union_rank
				childs.textName:text(self.unionName)
				childs.textName1:text(self.members[self.chairmanId].name)
				self.emptyPanel:visible(itertools.isempty(data[CHOOSENUM[rankType]].union_ranks))
				self.downPanel:visible(not itertools.isempty(data[CHOOSENUM[rankType]].role_ranks))
			end
			if downData.rank ~= 0 then
				childs.textRank:text(downData.rank)
			else
				childs.textRank:text(gLanguageCsv.noRank)
			end
			childs.num:text(downData.score)
			childs.server:text(string.format(gLanguageCsv.brackets, getServerArea(self.gameKey, true)))
		else
			self.downPanel:hide()
			self.emptyPanel:show()
		end
	end)

	Dialog.onCreate(self)
end

function UnionAnswerRankView:initModel()
	self.unionName = gGameModel.union:read("name")
	self.chairmanId = gGameModel.union:read("chairman_db_id")
	self.members = gGameModel.union:read("members")
	self.roleId = gGameModel.role:read("name")
	self.gameKey = gGameModel.role:read("game_key")
end

function UnionAnswerRankView:onBtn(index)
	self.rankType:set(index)
end

function UnionAnswerRankView:onTabClick(list, index)
	self.showTab:set(index)
end

return UnionAnswerRankView
