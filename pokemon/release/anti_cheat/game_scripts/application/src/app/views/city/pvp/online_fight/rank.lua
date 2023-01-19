-- @date 2020-8-14
-- @desc 实时匹配排行

local STEP = 10

local function initItem(list, node, k, v)
	local childs = node:multiget("imgRank", "txtRank", "head", "txtName", "txtLv", "txtLevel", "txtServer", "txtScore")
	childs.txtName:text(v.name)
	childs.txtLevel:text(v.level)
	adapt.oneLinePos(childs.txtName, {childs.txtLv, childs.txtLevel}, {cc.p(20, 0), cc.p(0, 0)})
	childs.txtServer:text(string.format(gLanguageCsv.brackets, getServerArea(v.game_key, true)))
	childs.txtScore:text(v.score)
	bind.extend(list, childs.head, {
		class = "role_logo",
		props = {
			logoId = v.logo,
			level = false,
			vip = false,
			frameId = v.frame,
			onNode = function(node)
				node:xy(104, 95)
					:z(6)
					:scale(0.9)
			end,
		}
	})
	if k <= 7 then
		childs.imgRank:show():texture("city/pvp/online_fight/display/icon_dzjjc_" .. k .. ".png")
		childs.txtRank:hide()
	else
		childs.imgRank:hide()
		childs.txtRank:show():text(k)
	end
end

local OnlineFightRankView = class("OnlineFightRankView", Dialog)

OnlineFightRankView.RESOURCE_FILENAME = "online_fight_rank.json"
OnlineFightRankView.RESOURCE_BINDING = {
	["topPanel.btnClose"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")},
		},
	},
	["leftPanel.tabItem"] = "tabItem",
	["leftPanel.tabList"] = {
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
				clickCell = bindHelper.self("onTabClick"),
			},
		},
	},
	["myRankPanel"] = "myRankPanel",
	["noRankPanel"] = "noRankPanel",
	["item"] = "item",
	["list1"] = {
		varname = "list1",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("data1"),
				item = bindHelper.self("item"),
				itemAction = {isAction = true},
				onItem = initItem,
				scrollState = bindHelper.self("scrollState"),
				onBeforeBuild = function(list)
					list.scrollState:set(false)
				end,
				onAfterBuild = function(list)
					list.scrollState:set(true)
				end,
			},
		},
	},
	["list2"] = {
		varname = "list2",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("data2"),
				item = bindHelper.self("item"),
				itemAction = {isAction = true},
				onItem = initItem,
				scrollState = bindHelper.self("scrollState"),
				onBeforeBuild = function(list)
					list.scrollState:set(false)
				end,
				onAfterBuild = function(list)
					list.scrollState:set(true)
				end,
			},
		},
	},
}

function OnlineFightRankView:onCreate(showTab, data)
	local childs = self.myRankPanel:multiget("txtName", "txtLv", "txtLevel")
	childs.txtName:text(gGameModel.role:read("name"))
	childs.txtLevel:text(gGameModel.role:read("level"))
	adapt.oneLinePos(childs.txtName, {childs.txtLv, childs.txtLevel}, {cc.p(10, 0), cc.p(0, 0)})

	self.tabDatas = idlers.newWithMap({
		[1] = {name = gLanguageCsv.onlineFightUnlimited},
		[2] = {name = gLanguageCsv.onlineFightLimited},
	})
	self.datas = {
		[1] = {
			rank = gGameModel.cross_online_fight:read("unlimited_rank"), -- # 无限制排名
			score = gGameModel.cross_online_fight:read("unlimited_score"), -- # 无限制积分
			data = {},
			offset = 0,
		},
		[2] = {
			rank = gGameModel.cross_online_fight:read("limited_rank"), -- # 公平赛排名
			score = gGameModel.cross_online_fight:read("limited_score"), -- # 公平赛积分
			data = {},
			offset = 0,
		},
	}
	for i, v in ipairs(self.datas) do
		self["data" .. i] = idlers.new()
		local list = self["list" .. i]
		list:hide()
		local container = list:getInnerContainer()
		list:onScroll(function(event)
			local y = container:getPositionY()
			if y >= -10 and self.scrollState:read() then
				self:sendProtocol()
			end
		end)
	end
	self.scrollState = idler.new(true)
	self.showTab = idler.new(showTab)
	self:initData(data)
	self.showTab:addListener(function(val, oldval)
		self.tabDatas:atproxy(oldval).select = false
		self.tabDatas:atproxy(val).select = true
		self["list" .. oldval]:hide()
		self["list" .. val]:show()
		local data = self.datas[val]
		local childs = self.myRankPanel:multiget("txtRank", "txtScore")
		childs.txtRank:text(data.rank ~= 0 and data.rank or gLanguageCsv.noRank)
		childs.txtScore:text(data.score or "--")
		if data.offset == 0 then
			self:sendProtocol()
		end
	end)
	Dialog.onCreate(self)
end

function OnlineFightRankView:onTabClick(list, index)
	self.showTab:set(index)
end

function OnlineFightRankView:sendProtocol()
	local showTab = self.showTab:read()
	if self.datas[showTab].isEnd or self.isRequest then
		return
	end
	self.isRequest = true
	gGameApp:requestServer("/game/cross/online/rank", function (tb)
		self.isRequest = false
		self:initData(tb.view.rank)
	end, showTab, self.datas[showTab].offset, STEP)
end

function OnlineFightRankView:initData(data)
	local showTab = self.showTab:read()
	self.datas[showTab].data = arraytools.merge_inplace(self.datas[showTab].data, {data})
	local offset = self.datas[showTab].offset
	self.datas[showTab].offset = offset + #data
	self["data" .. showTab]:update(self.datas[showTab].data)
	self["list" .. showTab]:jumpToItem(offset - 3, cc.p(0, 1), cc.p(0, 1))
	if #data < STEP then
		self.datas[showTab].isEnd = true
	end
	self.noRankPanel:visible(#self.datas[showTab].data == 0)
end

return OnlineFightRankView