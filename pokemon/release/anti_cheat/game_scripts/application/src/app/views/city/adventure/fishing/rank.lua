-- @date 2020-07-09
-- @desc 钓鱼大赛排行榜


local FishingRankView = class('FishingRankView', Dialog)
FishingRankView.RESOURCE_FILENAME = 'fishing_rank.json'

FishingRankView.RESOURCE_BINDING = {
	["title.btnClose"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")}
		},
	},
	["left.item"] = "btnItem",
	["left.list"] = {
		varname = "btnList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("btnDatas"),
				item = bindHelper.self("btnItem"),
				onItem = function(list, node, k, v)
					local normal = node:get("normal")
					local selected = node:get("selected")
					selected:visible(v.selected)
					normal:visible(not v.selected)
					normal:get("txt"):text(v.txt)
					local maxHeight = selected:getSize().height - 40
					adapt.setAutoText(selected:get("txt"), v.txt, maxHeight)
					if matchLanguage({"cn", "tw"}) then
						selected:get("txt"):setFontSize(v.fontSize)
					end
					if matchLanguage({"en"}) then
						adapt.setAutoText(normal:get("txt"), nil, 300)
					else
						normal:get("txt"):getVirtualRenderer():setLineSpacing(-10)
					end
					selected:get("txt"):getVirtualRenderer():setLineSpacing(-10)

					bind.touch(list, normal, {methods = {ended = functools.partial(list.clickCell, k)}})
				end,
			},
			handlers = {
				clickCell = bindHelper.self("onSelectClick"),
			},
		},
	},
	["right.reward.reward.item"] = "rewardItem",   --  奖励列表
	["right.reward.reward.list"] = {
		varname = "rewardList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("showData"),
				item = bindHelper.self("rewardItem"),
				padding = 10,
				itemAction = {isAction = true},
				onItem = function(list, node, k, v)
					local childs = node:multiget("bg", "icon", "txtRank", "list")
					local index = k
					local cfg = csv.cross.fishing.rank
					childs.txtRank:visible(index > 4)
					if index <= 3 then
						childs.icon:show()
						childs.txtRank:hide()
						childs.bg:texture("city/pvp/cross_craft/rank/box_phb"..index..".png")
						childs.icon:texture("city/pvp/cross_craft/icon_"..index..".png")
					elseif index == 4 and cfg[4].rankMax == 10 then
						childs.icon:show()
						childs.txtRank:hide()
						childs.bg:texture("city/pvp/cross_craft/rank/box_phb4.png")
						childs.icon:texture("city/pvp/cross_craft/icon_4.png")
					elseif index > 3 and cfg[4].rankMax ~= 10 then
						childs.icon:hide()
						childs.txtRank:show()
						local left = cfg[index-1].rankMax + 1
						local right = cfg[index].rankMax
						local str = left < right and (left.."-"..right) or right

						childs.txtRank:text(str)
					end

					-- 奖励列表，通用接口
					uiEasy.createItemsToList(list, childs.list, v.cfg.award, {margin = 11, scale = 0.9})
				end,
				asyncPreload = 10,
			},
		},
	},
	["right.rank.item"] = "rankItem",   --  排行列表
	["right.rank.list"] = {
		varname = "rankList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("rankData"),
				item = bindHelper.self("rankItem"),
				padding = 10,
				itemAction = {isAction = true},
				onItem = function(list, node, k, v)
					local childs = node:multiget("rank", "head", "name", "Lv", "Lv1", "score", "count", "txtRank", "server")
					local index = k

					-- 头像
					bind.extend(list, childs.head, {
						event = "extend",
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

					-- 名次
					childs.rank:get("txt"):visible(index > 3)
					childs.rank:visible(index <= 10)
					childs.txtRank:visible(index > 10)
					if index == 1 then
						childs.rank:texture("city/rank/icon_jp.png")
					elseif index == 2 then
						childs.rank:texture("city/rank/icon_yp.png")
					elseif index == 3 then
						childs.rank:texture("city/rank/icon_tp.png")
					elseif index >= 4 and index <= 10 then
						childs.rank:texture("common/icon/icon_four.png")
						childs.rank:get("txt"):text(index)
					elseif index > 10 then
						childs.txtRank:text(index)
					end

					childs.name:text(v.name)
					childs.server:text(string.format(gLanguageCsv.brackets, getServerArea(v.game_key, true)))
					adapt.oneLinePos(childs.name, childs.server, cc.p(10, 0), "left")
					childs.Lv1:text(v.level)
					adapt.oneLinePos(childs.Lv, childs.Lv1, cc.p(2, 0), "left")
					childs.score:text(v.point)
					childs.count:text(v.special_fish_num)
				end,
				asyncPreload = 10,
			},
		},
	},
	["right.reward.server.item"] = "serverItem",	--  服务器列表
	["right.reward.server.subList"] = "subList",
	["right.reward.server.list"] = {
		varname = "serverList",
		binds = {
			event = "extend",
			class = "tableview",
			props = {
				data = bindHelper.self("serverData"),
				item = bindHelper.self("subList"),
				cell = bindHelper.self("serverItem"),
				xMargin = 22,
				columnSize = 9,
				onCell = function(list, node, k, v)
					local childs = node:multiget("txt")
					childs.txt:text(getServerArea(v, true, true))
				end,
			},
		},
	},
	["right"] = "right",
	["right.rank.txtCount"] = "txtCount",
	["right.rank.down.rank"] = "myRank",
	["right.rank.down.name"] = "myName",
	["right.rank.down.score"] = "myScore",
	["right.rank.down.count"] = "myCount",
}

function FishingRankView:onCreate(data)
	self.data = data
	self:initModel()

	self.serverList:setScrollBarEnabled(false)
	self.subList:setScrollBarEnabled(false)
	self.rankList:setScrollBarEnabled(false)
	self.rewardList:setScrollBarEnabled(false)

	self.btnDatas = idlers.new(btnDatas)
	self.showTab = idler.new(1)
	self.rankData = idlers.newWithMap(self.data.ranks or {})
	self.serverData = idlers.newWithMap(getMergeServers(self.data.servers or {}))

	-- 特殊鱼
	local specialFishName = csv.fishing.fish[csv.cross.fishing.base[1].specialFish].name
	self.txtCount:text(string.format(gLanguageCsv.specialFishNum, specialFishName))

	-- 我的排行
	self.myRank:text(self.data.rank ~= 0 and self.data.rank or gLanguageCsv.noRank)
	self.myName:text(self.roleName)
	self.myScore:text(self.data.point)
	self.myCount:text(self.data.special_fish_num)

	-- 左侧页签按钮
	local btnDatas = {
		{txt = gLanguageCsv.rankList, selected = false, fontSize = 50},
		{txt = gLanguageCsv.craftRankReward, selected = false, fontSize = 45},
	}
	self.btnDatas:update(btnDatas)

	-- 奖励列表
	local rewardData = {}
	for k, v in orderCsvPairs(csv.cross.fishing.rank) do
		table.insert(rewardData, {cfg = v})
	end
	self.showData = idlers.newWithMap(rewardData)

	-- 左侧页签按钮点击
	self.showTab:addListener(function(val, oldval, idler)
		self.btnDatas:atproxy(oldval).selected = false
		self.btnDatas:atproxy(val).selected = true

		self:resetShowPanel(val)
	end)

	Dialog.onCreate(self)
end

function FishingRankView:initModel()
	self.roleName = gGameModel.role:read("name")
end

function FishingRankView:resetShowPanel(index)
	self.right:get("noRank"):visible(self.data.ranks[1] == nil and index == 1)
	self.right:get("rank"):visible(self.data.ranks[1] ~= nil and index == 1)
	self.right:get("reward"):visible(index == 2)
end

-- 点击排行榜页签
function FishingRankView:onSelectClick(list, index)
	self.showTab:set(index)
end

return FishingRankView