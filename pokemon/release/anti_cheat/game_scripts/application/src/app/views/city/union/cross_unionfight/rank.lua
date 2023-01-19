-- @date:   2021-09-08
-- @desc:   1.排行榜界面

local RankView = class("RankView", Dialog)

local SHOW_TYPE = {
	PRELIMINARY = 1,
	FINALMATCH = 2,
}

RankView.RESOURCE_FILENAME = "cross_union_fight_rank.json"
RankView.RESOURCE_BINDING = {
	["preliminaryPanel"] = "preliminaryPanel",
	["finalMatchPanel"] = "finalMatchPanel",
    ["preliminaryPanel.item"] = "item",
    ["finalMatchPanel.finalMatchItem"] = "finalMatchItem",
    ["leftItem"] = "leftItem",
	["duckPanel"] = "duckPanel",
	["duckPanel.txt"] = "duckTxt",
    ["bg.btnClose"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")}
		},
	},
    ["leftList"] = {
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("btnsAttr"),
				item = bindHelper.self("leftItem"),
				margin = 15,
				onItem = function(list, node, k, v)
					local normal = node:get("normal")
					local selected = node:get("selected")
					local panel
					if v.select then
						normal:hide()
						panel = selected:show()
						panel:get("txt"):setFontSize(50)
					else
						selected:hide()
						panel = normal:show()
					end
					panel:get("txt"):getVirtualRenderer():setLineSpacing(-10)
					adapt.setAutoText(panel:get("txt"),v.name,240)
					selected:setTouchEnabled(false)
					bind.touch(list, normal, {methods = {ended = functools.partial(list.clickCell, k)}})
				end,
			},
			handlers = {
				clickCell = bindHelper.self("onLeftButtonClick"),
			},
		}
	},
	["bg.titleText"] = "title",
	["bg.titleText.bg"] = "bg",
    ["preliminaryPanel.list"] = {
		varname = "list",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("preData"),
				item = bindHelper.self("item"),
                margin = 0,
				onItem = function(list, node, k, v)
					local childs = node:multiget("rankIcon", "unionIcon", "unionName", "serverKey", "winNum", "aliveCount", "point", "bg", "rankNum", "groupItem")
					if v.group ~= nil then
						node:height(98)
						childs.groupItem:show()
						childs.bg:color(cc.c3b(228, 224, 209))
						childs.groupItem:get("txt"):text(string.format(gLanguageCsv.crossUnionFightTeam,v.group))
						childs.rankIcon:hide()
						childs.unionIcon:hide()
						childs.unionName:hide()
						childs.serverKey:hide()
						childs.winNum:hide()
						childs.aliveCount:hide()
						childs.point:hide()
						childs.bg:hide()
						childs.rankNum:hide()
					else
						node:height(130)
						childs.groupItem:hide()
						childs.rankIcon:show()
						childs.unionIcon:show()
						childs.unionName:show()
						childs.serverKey:show()
						childs.winNum:show()
						childs.aliveCount:show()
						childs.point:show()
						childs.bg:show()
						childs.rankNum:show()
						if v[1].rank % 2 == 0 then
							childs.bg:show()
						else
							childs.bg:hide()
						end
						childs.unionName:text(v.union_name)
						childs.serverKey:text(getServerArea(v.server_key, false))
						childs.winNum:text(v.win_num)
						childs.aliveCount:text(v.alive_count)
						childs.point:text(v.point)
						if v[1].rank <= 3 then
							childs.rankIcon:texture(ui.RANK_ICON[v[1].rank])
						elseif v[1].rank <= 10 then
							childs.rankIcon:texture(ui.RANK_ICON[4])
							childs.rankNum:text(4)
						else
							childs.rankNum:text(4)
						end
						childs.unionIcon:texture(csv.union.union_logo[v.union_logo].icon)
					end
				end,
			},
		},
	},
	["finalMatchPanel.finalMatchList"] = {
		varname = "finalMatchList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("topData"),
				item = bindHelper.self("finalMatchItem"),
                margin = 20,
				onItem = function(list, node, k, v)
					local childs = node:multiget("rankIcon", "unionIcon", "unionName", "serverKey", "winNum", "aliveCount", "point", "bg", "rankNum")
					childs.unionName:text(v.union_name)
					childs.serverKey:text(getServerArea(v.server_key, false))
					childs.winNum:text(v.win_num)
					childs.aliveCount:text(v.alive_count)
					childs.point:text(v.point)
					if k <= 3 then
						childs.rankIcon:texture(ui.RANK_ICON[k])
					elseif k<= 10 then
						childs.rankIcon:texture(ui.RANK_ICON[4])
						childs.rankNum:text(k)
					else
						childs.rankIcon:hide()
						childs.rankNum:text(k)
					end
					childs.unionIcon:texture(csv.union.union_logo[v.union_logo].icon)
				end,
			},
		},
	},
}
function RankView:onLeftButtonClick(list, index)
	self.leftButtonTab:set(index)
end

--判断是否到周四，是则清理数据
function RankView:judgeClearData(val)
	if self.status == "closed" and time.getNowDate().wday == 4 then
		self.topData = {}
		self.preData = {}
		self.duckPanel:show()
		self.title:hide()
		self.duckTxt:text(gLanguageCsv.crossArenaNoRank)
	end

	--客户端战斗没有模拟结束不能查看排行榜
	if not self.model.finish then
		if self.status == "preOver" then
			self.preData = {}
			self.duckPanel:show()
			self.duckTxt:text(gLanguageCsv.crossArenaNoRank)
		elseif self.status == "topOver" then
			self.topData = {}
			if val == 2 then
				self.duckPanel:show()
			end
			self.duckTxt:text(gLanguageCsv.crossArenaNoRank)
		end
	end
end

function RankView:onCreate(rankData, model)
    Dialog.onCreate(self)

	self.model = model
	self.duckPanel:hide()
	self.item:hide()
	self.finalMatchItem:hide()
	self.leftItem:hide()
	self.preliminaryPanel:hide()
	self.finalMatchPanel:hide()
	self:initModel(rankData)
	self.panel = {
		{
			node = self.preliminaryPanel,
			data = self.preData,
		},
		{
			node = self.finalMatchPanel,
			data = self.topData,
		},
	}

    local leftButtonName = {
		{name = gLanguageCsv.preliminary},
		{name = gLanguageCsv.finalMatch},
	}
	self.btnsAttr = idlers.newWithMap(leftButtonName)
	self.leftButtonTab = idler.new(1)
	self.leftButtonTab:addListener(function (val, oldval)
		self.btnsAttr:atproxy(oldval).select = false
		self.btnsAttr:atproxy(val).select = true
		self.panel[oldval].node:hide()
		self.panel[val].node:show()
		self.bg:visible(val == 1)
		self.title:get("redLine"):visible(val == 1)
		local isempty = itertools.isempty(self.panel[val].data)
		self.duckPanel:visible(isempty)
		self.title:visible(not isempty)
		self.duckTxt:text(gLanguageCsv.crossArenaNoRank)
		self:judgeClearData(val)
	end)
end

function RankView:initModel(data)
	self.status = gGameModel.cross_union_fight:read("status")
	--初赛数据处理
	local t = {}
	local count = 1
	if not itertools.isempty(data.last_ranks) then
		for k, v in pairs(data.last_ranks) do
			if k < 5 then
				table.insert(t, {group = count})
				count = count + 1
				table.sort(v,function(a, b)
					if a.point > b.point then
						return true
					elseif a.point == b.point then
						return a.alive_count > b.alive_count
					end
					return false
				end)
				for nk, nv in ipairs(v) do
					table.insert(nv,{rank = nk})
					table.insert(t, nv)
				end
			end
		end
	end
	--决赛数据处理
	if not itertools.isempty(data.last_ranks[5]) then
		table.sort(data.last_ranks[5],function(a, b)
			if a.point > b.point then
				return true
			elseif a.point == b.point then
				return a.alive_count > b.alive_count
			end
			return false
		end)
	end
	self.preData = t
	self.topData = data.last_ranks[5] or {}
end

return RankView