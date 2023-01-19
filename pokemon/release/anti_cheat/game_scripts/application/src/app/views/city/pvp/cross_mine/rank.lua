-- @date:   2020-12-24
-- @desc:   跨服商业街-排行榜

local ICON_BG = {
	"common/icon/logo_yellow.png",
	"common/icon/logo_blue.png",
	"common/icon/logo_green.png",
	"common/icon/logo_gray.png",
}


local function __initItem(list, node, k, v, sign)
	local childs = node:multiget("textName","textLv","imgRank","textRank","head","textFightPoint","textServer","textLvNote")
	childs.textName:text(v.name)
	childs.textLv:text(v.level)
	adapt.oneLinePos(childs.textName, {childs.textLvNote, childs.textLv}, cc.p(10, 0))
	childs.textServer:text(string.format(gLanguageCsv.brackets, getServerArea(v.game_key, true)))
	local rank  = v.rank
	if not sign  then
		rank  = v.server_buff_feed_rank
	end
	if rank > 10 then
		childs.imgRank:visible(false)
		childs.textRank:text(rank)
	else
		childs.textRank:visible(false)
		childs.imgRank:texture(string.format("city/pvp/cross_mine/icon_kfzy_ph%d.png", rank))
	end

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
	if sign then
		childs.textFightPoint:text(v.fighting_point)
	else
		childs.textFightPoint:text(v.server_buff_feed)
	end
	bind.touch(list, node, {methods = {ended = functools.partial(list.clickCell, k, v)}})
end

local CrossMineRankView = class("CrossMineRankView", Dialog)
CrossMineRankView.RESOURCE_FILENAME = "cross_mine_rank.json"
CrossMineRankView.RESOURCE_BINDING = {
	["title.btnClose"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")},
		},
	},
	["title.textTitle1"] = "textTitle1",
	["title.textTitle2"] = "textTitle2",
	["rankPanel.textFightPoint"]   = "textFightPoint",
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
	["rankPanel"] = "rankPanel",
	["rankPanel.down.textName"] = "myName",
	["rankPanel.down.textRank"] = "myRank",
	["rankPanel.down.textFightPoint"] ="myFightPoint",
	["rankPanel.down.textLv"] = "myLv",
	["emptyPanel"] = "emptyPanel",
	["item"] = "item",
	["rankPanel.listFight"] = {
		varname = "listFight",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data       = bindHelper.self("rankDatas"),
				item       = bindHelper.self("item"),
				itemAction = {isAction = true},
				showTab    = bindHelper.self("showTab"),
				onItem     = function(list, node, k, v)
					local sign = list.showTab:read() == 1
					__initItem(list, node, k, v, sign)
				end,
				scrollState = bindHelper.self("scrollState"),
				onBeforeBuild = function(list)
					list.scrollState:set(false)
				end,
				onAfterBuild = function(list)
					list.scrollState:set(true)
				end,
			},
			handlers = {
				clickCell = bindHelper.self("onItemClick"),
			},
		},
	},
}

function CrossMineRankView:onCreate(fight, donate)
	self:initModel()
	self.emptyPanel:hide()

	self.fightDatas =  fight.rank.ranks or {}
	self.donateDatas =  donate.rank.ranks or  {}

	self.tabDatas = idlers.newWithMap({
		[1] = {name = gLanguageCsv.crossMinePVPRankTop01, fontSize = 50},
		[2] = {name = gLanguageCsv.crossMinePVPRankTop02, fontSize = 50},
	})

	self.panel = {
		{
			mark = #self.fightDatas == 11,
			data = self.fightDatas,
			txtNode = gLanguageCsv.power,
			name = "role"
		},
		{
			mark = #self.donateDatas == 11,
			data = self.donateDatas,
			txtNode = gLanguageCsv.crossMineDonate,
			name = "feed"
		},
	}

	self.rankDatas   = idlers.new({})
	self.showTab     = idler.new(1)
	self.scrollState = idler.new(true)

	self.showTab:addListener(function(val, oldval)
		self.tabDatas:atproxy(oldval).select = false
		self.tabDatas:atproxy(val).select = true

		self.textFightPoint:text(self.panel[val].txtNode)

		self:initMyInfo(fight.rank.myInfo)
		self.rankDatas:update(self.panel[val].data)

		local isempty = itertools.isempty(self.panel[val].data)
		self.emptyPanel:visible(isempty)
		self.rankPanel:visible(not isempty)
		self.scrollState:set(true)
	end)

	local container = self.listFight:getInnerContainer()

	self.listFight:onScroll(function(event)
		local y = container:getPositionY()

		local panel = self.panel[self.showTab:read()]
		if y >= -10 and self.scrollState:read() and panel.mark then
			local offset = #(panel.data)
			panel.mark = false
			gGameApp:requestServer("/game/cross/mine/rank", function (tb)

				if tolua.isnull(self) then
					return --界面关闭了 回调不执行
				end

				for i, v in ipairs(tb.view.rank.ranks) do
					table.insert(panel.data, v)
				end

				panel.mark = #tb.view.rank.ranks == 10
				self.rankDatas:update(panel.data)
				self.listFight:jumpToItem(offset - 3, cc.p(0, 1), cc.p(0, 1))
			end, panel.name, offset, 10)
		end
	end)

	Dialog.onCreate(self)
end

function CrossMineRankView:initModel()
	self.record = gGameModel.cross_mine:getIdler("role")
	self.roleName = gGameModel.role:read("name")
	self.roleLevel = gGameModel.role:read("level")
	self.roleTop12 = gGameModel.role:read("top12_fighting_point")
end

function CrossMineRankView:initMyInfo(info)
	local sign = self.showTab:read() == 1
	if info then
		local rank = sign and info.rank or info.server_buff_feed_rank
		local point = sign and info.fighting_point or info.server_buff_feed
		self.myLv:text(info.level)
		self.myName:text(info.name)
		self.myFightPoint:text(point)
		self.myRank:text(rank == 0 and gLanguageCsv.noRank or rank)
	else
		local point = sign and self.roleTop12 or 0
		self.myFightPoint:text(point)
		self.myName:text(self.roleName)
		self.myLv:text(self.roleLevel)
	end
end

-- 选择
function CrossMineRankView:onTabClick(list, index)
	self.scrollState:set(false)
	self.showTab:set(index)
end

-- 查看个人信息
function CrossMineRankView:onItemClick(list, k, v)
	gGameApp:requestServer("/game/cross/mine/role/info", function(tb)
		gGameUI:stackUI("city.pvp.cross_mine.personal_info", nil, {clickClose = true, blackLayer = true}, tb.view)
	end,v.record_db_id, v.game_key, v.rank)
end



return CrossMineRankView