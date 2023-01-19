-- @date:   排行榜
local TAB_LIST = {
	"powerList",
	"collectList",
	"arenaList",
	"kingList",
	"unionList",
	"activityList",
	"craftList",
	"gateStarList", 	-- 关卡星级排行榜
}
local function itemShow(list, node, k, v, index)
	local childs = node:multiget("img", "num", "name", "iconBg", "level", "bg")
	childs.name:text(v.name)

	local props = {
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
	}
	bind.extend(list, childs.iconBg, props)
	childs.level:text(v.level)
	local index = index or k
	childs.img:visible(index <= 3)
	childs.num:visible(index > 3)
	childs.num:text(index)
	if index <= 3 then
		childs.img:texture(ui.RANK_ICON[index])
	end
	childs.iconBg:setTouchEnabled(false)
	childs.bg:setTouchEnabled(true)
	childs.bg:onClick(functools.partial(list.clickHead, k, v, index))
end

local ViewBase = cc.load("mvc").ViewBase
local RankView = class("RankView", ViewBase)
RankView.RESOURCE_FILENAME = "rank.json"
RankView.RESOURCE_BINDING = {
	["leftPanel"] = "leftPanel",
	["leftPanel.item"] = "leftItem",
	["leftPanel.list"] = {
		varname = "leftList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("leftDatas"),
				item = bindHelper.self("leftItem"),
				dataOrderCmp = function(a, b)
					return a.sortValue < b.sortValue
				end,
				itemAction = {isAction = true},
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
						panel:get("subTxt"):text(v.subName)
					end
					panel:get("txt"):text(v.name)
					selected:setTouchEnabled(false)
					bind.touch(list, normal, {methods = {ended = functools.partial(list.clickCell, k)}})
					adapt.setTextScaleWithWidth(panel:get("txt"), nil, 300)
				end,
			},
			handlers = {
				clickCell = bindHelper.self("onTabClick"),
			},
		},
	},
	["itemFight"] = "itemFight",
	["rightPanel"] = "rightPanel",
	["rightPanel.powerList"] = {
		varname = "powerList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("showData1"),
				item = bindHelper.self("itemFight"),
				scrollState = bindHelper.self("scrollState"),
				itemAction = {isAction = true},
				onBeforeBuild = function(list)
					list.scrollState:set(false)
				end,
				onAfterBuild = function(list)
					list.scrollState:set(true)
				end,
				onItem = function(list, node, k, v)
					itemShow(list, node, k, v.role)
					local item1 = node:get("item1")
					item1:hide()
					node:get("power"):text(v.fighting_point)
					local t = arraytools.filter(v.top6_cards, function (k, detail)
						if detail and detail.card_id ~= 0 then
							return true
						end
					end)
					bind.extend(list, node:get("list"), {
						class = "listview",
						props = {
							data = t,
							item = item1,
							onItem = function(list, node, k, v)
								node:get("level"):text("Lv."..v.level)
								local unitCsv = dataEasy.getUnitCsv(v.card_id, v.skin_id)
								node:get("icon"):texture(unitCsv.iconSimple)
							end,
						}
					})
				end,
			},
			handlers = {
				clickHead = bindHelper.self("onHeadClick"),
			},
		},
	},
	["itemCollect"] = "itemCollect",
	["rightPanel.collectList"] = {
		varname = "collectList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("showData2"),
				item = bindHelper.self("itemCollect"),
				scrollState = bindHelper.self("scrollState"),
				itemAction = {isAction = true},
				onBeforeBuild = function(list)
					list.scrollState:set(false)
				end,
				onAfterBuild = function(list)
					list.scrollState:set(true)
				end,
				onItem = function(list, node, k, v)
					itemShow(list, node, k, v.role, v.index)
					local childs = node:multiget("txtCollect", "txtUnlock")
					local number = v.pokedex * 100 / table.length(gHandbookArrayCsv)
					childs.txtCollect:text(string.format("%.1f%%", number))
					childs.txtUnlock:text(v.pokedex)
				end,
			},
			handlers = {
				clickHead = bindHelper.self("onHeadClick"),
			},
		},
	},
	["itemCraft"] = "itemCraft",
	["rightPanel.craftList"] = {
		varname = "craftList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("showData7"),
				item = bindHelper.self("itemCraft"),
				scrollState = bindHelper.self("scrollState"),
				itemAction = {isAction = true},
				onBeforeBuild = function(list)
					list.scrollState:set(false)
				end,
				onAfterBuild = function(list)
					list.scrollState:set(true)
				end,
				onItem = function(list, node, k, v)
					itemShow(list, node, k, v.role, v.index)
					local childs = node:multiget("txtScore", "txtRecord")
					childs.txtScore:text(v.craft.point)
					childs.txtRecord:text(string.format(gLanguageCsv.winAndLoseNum, v.craft.win, math.min(v.craft.round, 13)-v.craft.win))
				end,
			},
			handlers = {
				clickHead = bindHelper.self("onHeadClick"),
			},
		},
	},
	["itemGateStar"] = "itemGateStar",
	["rightPanel.gateStarList"] = { 	-- 关卡星级
		varname = "gateStarList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("showData8"),
				item = bindHelper.self("itemGateStar"),
				scrollState = bindHelper.self("scrollState"),
				itemAction = {isAction = true},
				onBeforeBuild = function(list)
					list.scrollState:set(false)
				end,
				onAfterBuild = function(list)
					list.scrollState:set(true)
				end,
				onItem = function(list, node, k, v)
					itemShow(list, node, k, v.role, v.index)
					local childs = node:multiget("txtStar", "txtUnion")
					childs.txtStar:text(v.star)
					childs.txtUnion:text((v.union_name == "" or not v.union_name) and gLanguageCsv.none or v.union_name)
				end,
			},
			handlers = {
				clickHead = bindHelper.self("onHeadClick"),
			},
		},
	},
	["rightPanel.arenaList"] = {
		varname = "arenaList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("showData3"),
				item = bindHelper.self("itemFight"),
				scrollState = bindHelper.self("scrollState"),
				itemAction = {isAction = true},
				onBeforeBuild = function(list)
					list.scrollState:set(false)
				end,
				onAfterBuild = function(list)
					list.scrollState:set(true)
				end,
				onItem = function(list, node, k, v)
					itemShow(list, node, k, v)
				end,
			},
			handlers = {
				clickHead = bindHelper.self("onHeadClick"),
			},
		},
	},
	["rightPanel.kingList"] = {
		varname = "kingList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("showData4"),
				item = bindHelper.self("itemFight"),
				scrollState = bindHelper.self("scrollState"),
				itemAction = {isAction = true},
				onBeforeBuild = function(list)
					list.scrollState:set(false)
				end,
				onAfterBuild = function(list)
					list.scrollState:set(true)
				end,
				onItem = function(list, node, k, v)
					itemShow(list, node, k, v)
				end,
			},
			handlers = {
				clickHead = bindHelper.self("onHeadClick"),
			},
		},
	},
	["itemUnion"] = "itemUnion",
	["rightPanel.unionList"] = {
		varname = "unionList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("showData5"),
				item = bindHelper.self("itemUnion"),
				scrollState = bindHelper.self("scrollState"),
				itemAction = {isAction = true},
				onBeforeBuild = function(list)
					list.scrollState:set(false)
				end,
				onAfterBuild = function(list)
					list.scrollState:set(true)
				end,
				onItem = function(list, node, k, v)
					local childs = node:multiget("name", "level", "bossName", "people", "img", "iconBg", "bg", "num", "icon")
					childs.name:text(v.name)
					childs.level:text(v.level)
					childs.icon:texture(csv.union.union_logo[v.logo].icon)
					childs.bossName:text(v.chairman_name)
					childs.people:text(v.members.."/"..v.member_max)
					childs.img:visible(k <= 3)
					childs.num:visible(k > 3)
					childs.num:text(k)
					if k <= 3 then
						childs.img:texture(ui.RANK_ICON[k])
					end
					childs.iconBg:setTouchEnabled(false)
					childs.bg:setTouchEnabled(true)
					childs.bg:onClick(functools.partial(list.clickHead, k, v, index))
				end,
			},
			handlers = {
				clickHead = bindHelper.self("onUnionHeadClick"),
			},
		},
	},
	["rightPanel.activityList"] = {
		varname = "activityList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("showData6"),
				item = bindHelper.self("itemFight"),
				scrollState = bindHelper.self("scrollState"),
				itemAction = {isAction = true},
				onBeforeBuild = function(list)
					list.scrollState:set(false)
				end,
				onAfterBuild = function(list)
					list.scrollState:set(true)
				end,
				onItem = function(list, node, k, v)
					itemShow(list, node, k, v)
				end,
			},
			handlers = {
				clickHead = bindHelper.self("onHeadClick"),
			},
		},
	},
	["rightPanel.bottomPanel.txtRank"] = "myRanking",
	["rightPanel.bottomPanel.txtName"] = "myName",
	["rightPanel.bottomPanel.txtStatic1"] = "txtStatic1",
	["rightPanel.bottomPanel"] = "bottomPanel",
	["rightPanel.bottomPanel.txtState1"] = {
		varname = "txtState1",
		binds = {
				event = "text",
				idler = bindHelper.self("bottomTextState1"),
		}
	},
	["rightPanel.bottomPanel.txtState2"] = {
		varname = "txtState2",
		binds = {
			event = "text",
			idler = bindHelper.self("bottomTextState2"),
		}
	},
	["rightPanel.topPanel"] = "topPanel",
	["rightPanel.topPanelFight"] = "topPanelFight",
	["rightPanel.topPanelCollect"] = "topPanelCollect",
	["rightPanel.topPanelCraft"] = "topPanelCraft",
	["rightPanel.topPanelGateStar"] = "topPanelGateStar",
	["rightPanel.topPanelUnion"] = "topPanelUnion",
	["rightPanel.bottomPanelFight"] = "bottomPanelFight",
	["rightPanel.bottomPanelFight.txtRank"] = {
		binds = {
			event = "text",
			idler = bindHelper.self("fightRank"),
		},
	},
	["rightPanel.bottomPanelFight.txtName"] = {
		binds = {
			event = "text",
			idler = bindHelper.self("roleName"),
		},
	},
	["rightPanel.bottomPanelFight.txtState1"] = {
		binds = {
			event = "text",
			idler = bindHelper.self("level"),
		},
	},
	["rightPanel.bottomPanelFight.txtState2"] = {
		binds = {
			event = "text",
			idler = bindHelper.self("power"),
			method = function(power)
				return gLanguageCsv.power..": "..power
			end,
		},
	},
	["rightPanel.bottomPanelCollect"] = "bottomPanelCollect",
	["rightPanel.bottomPanelCollect.txtRank"] = {
		binds = {
			event = "text",
			idler = bindHelper.self("cardNumRank"),
		},
	},
	["rightPanel.bottomPanelCollect.txtName"] = {
		binds = {
			event = "text",
			idler = bindHelper.self("roleName"),
		},
	},
	["rightPanel.bottomPanelCollect.txtState1"] = {
		binds = {
			event = "text",
			idler = bindHelper.self("pokedex"),
			method = function(pokedex)
				return string.format("%.1f%%", itertools.size(pokedex)* 100 / table.length(gHandbookArrayCsv))
			end,
		},
	},
	["rightPanel.bottomPanelCollect.txtState2"] = {
		binds = {
			event = "text",
			idler = bindHelper.self("pokedex"),
			method = function(pokedex)
				return itertools.size(pokedex)
			end,
		},
	},
	["rightPanel.bottomPanelUnion"] = "bottomPanelUnion",
	["rightPanel.bottomPanelUnion.txtRank"] = {
		binds = {
			event = "text",
			idler = bindHelper.self("unionRank"),
		},
	},
	["rightPanel.bottomPanelCraft"] = "bottomPanelCraft",
	["rightPanel.bottomPanelCraft.txtName"] = {
	  	binds = {
		   	event = "text",
		   	idler = bindHelper.model("role", "name"),
	  	},
	},
	["rightPanel.bottomPanelCraft.txtRank"] = {
	  	binds = {
		   	event = "text",
		   	idler = bindHelper.self("craftRank"),
			method = function(craftRank)
				return (craftRank and craftRank > 0) and craftRank or gLanguageCsv.craftNoRank
			end,
	  	},
	},
	["rightPanel.bottomPanelGateStar"] = "bottomPanelGateStar",
	["rightPanel.bottomPanelGateStar.txtRank"] = {
		binds = {
			event = "text",
			idler = bindHelper.self("gate_star_rank"),
			method = function(rank)
				return rank > 0 and rank or gLanguageCsv.craftNoRank
			end,
		},
	},
	["rightPanel.bottomPanelGateStar.txtName"] = {
		binds = {
			event = "text",
			idler = bindHelper.self("roleName"),
		},
	},
	["rightPanel.bottomPanelGateStar.txtStar"] = {
		binds = {
			event = "text",
			idler = bindHelper.self("gate_star_sum"),
		},
	},
}

function RankView:initData(type, serverData, offset, index, list)
	local isCanDown = #serverData == 10
	if offset == 0 then
		self.datas[index] = serverData
	else
		for i,v in ipairs(serverData) do
			table.insert(self.datas[index],v)
		end
	end
	local len = #self.datas[index]
	if index == 2 then
		local pokedex = 0
		local index1 = 0
		for i=1, len do
			local val = self.datas[index][i]
			if i == 1 then
				pokedex = val.pokedex
				index1 = i
				val.index = index1
			else
				if pokedex == val.pokedex then
					val.index = index1
				else
					pokedex = val.pokedex
					index1 = i
					val.index = i
				end
			end
		end
	end
	self.isCanDown = false

	self["showData"..index]:update(self.datas[index])
	gGameUI:disableTouchDispatch(0.01)
	list:jumpToItem(offset - 4, cc.p(0, 1), cc.p(0, 1))
	-- self.isCanDown = #self.datas[index] %10 == 0
	-- 每个步长都是10 只要刷新更新数量不足10个就说明已经没了
	local maxCount = type == "craft" and 50 or 100
	self.isCanDown = isCanDown and len < maxCount
end

function RankView:sendProtocol(type, offset, index, list)
	if self.isRequest then
		return
	end
	self.isRequest = true
	if offset < 100 then
		if type == "union" then
			gGameApp:requestServer("/game/union/rank",function (tb)
				self.isRequest = false
				self:initData(type, tb.view.unions, offset, index, list)
			end, offset, offset + 10 > 100 and 100 - offset or 10)
		else
			local max = type == "craft" and 50 or 100 -- 排行榜上限 默认100 限时pvp与功能里面排行榜显示数量保持一致
			gGameApp:requestServer("/game/rank",function (tb)
				if tolua.isnull(self) then
					return --界面关闭了 回调不执行
				end
				self.isRequest = false
				if type == "craft" then
					if tb.view.craft then
						self.bottomPanelCraft:get("txtScore"):text(tb.view.craft.point)
						self.bottomPanelCraft:get("txtRecord"):text((string.format(gLanguageCsv.winAndLoseNum, tb.view.craft.win, math.min(tb.view.craft.round, 13) - tb.view.craft.win)))
					else -- 服务器无数据，显示积分0，战况0胜0负
						self.bottomPanelCraft:get("txtScore"):text("0")
						self.bottomPanelCraft:get("txtRecord"):text(string.format(gLanguageCsv.winAndLoseNum, 0, 0))
					end
				end
				self:initData(type, tb.view.rank, offset, index, list)
			end, type, offset, offset + 10 > max and max - offset or 10)
		end
	end
end

function RankView:adapUI()
	local adaptWidth =  self.itemCraft:multiget("bg")
	local adaptPos1 =  self.itemCraft:multiget("img", "num", "iconBg", "name", "txt", "level")
	local adaptPos2 =  self.itemCraft:multiget("txtScore", "txtRecord")
	local topAdapt1 = self.topPanelCraft:multiget("txtRank", "txtName")
	local topAdapt2 = self.topPanelCraft:multiget("txtScore", "txtRecord")
	local bottomAdapt1 = self.bottomPanelCraft:multiget("bg")
	local bottomAdapt2 = self.bottomPanelCraft:multiget("txtRank", "txtName")
	local bottomAdapt3 = self.bottomPanelCraft:multiget("txtRecord", "txtScore")

	local itemFightWidth = self.itemFight:multiget("bg")
	local itemFightPos1 =  self.itemFight:multiget("img", "num", "iconBg", "name", "txt", "level")
	local itemFightPos2 =  self.itemFight:multiget("list")
	local topItemFightAdapt1 = self.topPanelFight:multiget("txtRank", "txtName")
	local topItemFightAdapt2 = self.topPanelFight:multiget("txtState2")
	local bottomPanelAdapt1 = self.bottomPanel:multiget("bg")
	local bottomPanelAdapt2 = self.bottomPanel:multiget("txtRank", "txtName")
	local bottomPanelAdapt3 = self.bottomPanel:multiget("txtStatic1", "txtState2", "txtState1")
	local bottomFightAdapt1 = self.bottomPanelFight:multiget("txtName")
	local bottomFightAdapt2 = self.bottomPanelFight:multiget("txtStatic1", "txtState1", "txtState2")

	local itemUnionWidth = self.itemUnion:multiget("bg")
	local itemUnionPos1 =  self.itemUnion:multiget("img", "num", "txt", "level", "iconBg", "name", "icon")
	local itemUnionPos2 =  self.itemUnion:multiget("people", "bossName")
	local topItemUnionAdapt1 = self.topPanelUnion:multiget("txtRank", "txtName", "txtState1")
	local topItemUnionAdapt2 = self.topPanelUnion:multiget("txtState2", "txtState3")
	local bottomUnionAdapt1 = self.bottomPanelUnion:multiget("bg")
	local bottomUnionAdapt2 = self.bottomPanelUnion:multiget("txtRank", "txtName", "txtStatic1", "none", "txtState1")
	local bottomUnionAdapt3 = self.bottomPanelUnion:multiget("txtState2", "txtState3")

	local itemCollectWidth = self.itemCollect:multiget("bg")
	local itemCollectPos1 =  self.itemCollect:multiget("img", "num", "iconBg", "name", "txt", "level")
	local itemCollectPos2 =  self.itemCollect:multiget("txtCollect", "icon1", "txtUnlock", "icon2")
	local topItemCollectAdapt1 = self.topPanelCollect:multiget("txtRank", "txtName")
	local topItemCollectAdapt2 = self.topPanelCollect:multiget("txtState1", "txtState2")
	local bottomCollectAdapt1 = self.bottomPanelCollect:multiget("bg")
	local bottomCollectAdapt2 = self.bottomPanelCollect:multiget("txtRank", "txtName")
	local bottomCollectAdapt3 = self.bottomPanelCollect:multiget("txtState1", "txtState2")

	local itemGateStarWidth =  self.itemGateStar:multiget("bg")
	local itemGateStarPos1 =  self.itemGateStar:multiget("img", "num", "iconBg", "name", "txt", "level")
	local itemGateStarPos2 =  self.itemGateStar:multiget("txtStar", "txtUnion")
	local topItemGateStarAdapt1 = self.topPanelGateStar:multiget("txtRank", "txtName")
	local topItemGateStarAdapt2 = self.topPanelGateStar:multiget("txtStar", "txtUnion")
	local bottomGateStarAdapt1 = self.bottomPanelGateStar:multiget("bg")
	local bottomGateStarAdapt2 = self.bottomPanelGateStar:multiget("txtRank", "txtName")
	local bottomGateStarAdapt3 = self.bottomPanelGateStar:multiget("txtStar", "txtUnion")

	adapt.centerWithScreen("left", "right", nil, {
		{self.leftPanel, "pos", "left"},
		{self.rightPanel, "pos", "left"},


		{self.craftList, "width"},
		{self.itemCraft, "width"},
		{adaptWidth, "width"},
		{adaptPos1, "pos", "left"},
		{adaptPos2, "pos", "right"},
		{self.topPanelCraft, "width"},
		{self.topPanelCraft, "pos", "right"},
		{topAdapt1, "pos", "left"},
		{topAdapt2, "pos", "right"},
		{self.bottomPanelCraft, "pos", "right"},
		{bottomAdapt1, "width"},
		{bottomAdapt2, "pos", "left"},
		{bottomAdapt3, "pos", "right"},

		{self.activityList, "width"},
		{self.powerList, "width"},
		{self.arenaList, "width"},
		{self.kingList, "width"},
		{self.itemFight, "width"},
		{itemFightWidth, "width"},
		{itemFightPos1, "pos", "left"},
		{self.topPanelFight, "width"},
		{self.topPanelFight, "pos", "right"},
		{topItemFightAdapt1, "pos", "left"},
		{self.bottomPanel, "pos", "right"},
		{bottomPanelAdapt1, "width"},
		{bottomPanelAdapt2, "pos", "left"},
		{bottomPanelAdapt3, "pos", "right"},
		{bottomFightAdapt2, "pos", "right"},


		{self.unionList, "width"},
		{self.itemUnion, "width"},
		{itemUnionWidth, "width"},
		{itemUnionPos1, "pos", "left"},
		{itemUnionPos2, "pos", "right"},
		{self.topPanelUnion, "width"},
		{self.topPanelUnion, "pos", "right"},
		{topItemUnionAdapt1, "pos", "left"},
		{topItemUnionAdapt2, "pos", "right"},
		{self.bottomPanelUnion, "pos", "right"},
		{bottomUnionAdapt1, "width"},
		{bottomUnionAdapt2, "pos", "left"},
		{bottomUnionAdapt3, "pos", "right"},

		{self.collectList, "width"},
		{self.itemCollect, "width"},
		{itemCollectWidth, "width"},
		{itemCollectPos1, "pos", "left"},
		{itemCollectPos2, "pos", "right"},
		{self.topPanelCollect, "width"},
		{self.topPanelCollect, "pos", "right"},
		{topItemCollectAdapt1, "pos", "left"},
		{topItemCollectAdapt2, "pos", "right"},
		{self.bottomPanelCollect, "pos", "right"},
		{bottomCollectAdapt1, "width"},
		{bottomCollectAdapt2, "pos", "left"},
		{bottomCollectAdapt3, "pos", "right"},

		{self.gateStarList, "width"},
		{self.itemGateStar, "width"},
		{itemGateStarWidth, "width"},
		{itemGateStarPos1, "pos", "left"},
		{itemGateStarPos2, "pos", "right"},
		{self.topPanelGateStar, "width"},
		{self.topPanelGateStar, "pos", "right"},
		{topItemGateStarAdapt1, "pos", "left"},
		{topItemGateStarAdapt2, "pos", "right"},
		{self.bottomPanelGateStar, "pos", "right"},
		{bottomGateStarAdapt1, "width"},
		{bottomGateStarAdapt2, "pos", "left"},
		{bottomGateStarAdapt3, "pos", "right"},

	})
end

function RankView:onCreate(data)
	self:initModel()
	self:adapUI()
	self.isCanDown = true
	self.scrollState = idler.new(true)
	self.datas = {}
	local originData = data
	for i = 1, itertools.size(TAB_LIST) do
		self.datas[i] = i == 1 and originData or {}
		self["showData"..i] = idlers.newWithMap(self.datas[i])
	end
	local originBottomX1 = self.txtState1:x()
	local originBottomX2 = self.txtState2:x()
	gGameUI.topuiManager:createView("default", self, {onClose = self:createHandler("onClose")})
		:init({title = gLanguageCsv.rankList, subTitle = "RANKING LIST"})
	self.bottomTextState1 = idler.new("")
	self.bottomTextState2 = idler.new("")
	local leftDatas = {
		[1] = {sortValue = 1, name = gLanguageCsv.fighting,type = "fight", subName = "Fight", top = self.topPanelFight, bottom = self.bottomPanelFight},
		[2] = {sortValue = 2, name = gLanguageCsv.collectRate,type = "pokedex", subName = "CollectRate", top = self.topPanelCollect, bottom = self.bottomPanelCollect},
		-- [3] = {name = gLanguageCsv.arena, subName = "Arena"},
		-- [4] = {name = gLanguageCsv.craft, subName = "KingFight"},
		[5] = {sortValue = 5, name = gLanguageCsv.spaceGuild, unlockKey = "union", subName = "Union", type = "union", top = self.topPanelUnion, bottom = self.bottomPanelUnion},
		[7] = {sortValue = 7, name = gLanguageCsv.craft, unlockKey = "craft", subName = "Craft", type = "craft", top = self.topPanelCraft, bottom = self.bottomPanelCraft},
		[8] = {sortValue = 8, name = gLanguageCsv.gateStar, subName = "Accumulated stars", type = "star", top = self.topPanelGateStar, bottom = self.bottomPanelGateStar},
	}
	self.leftDatas = idlers.new()
	local showData = {}
	local function refreshData(idx, isUnlock)
		showData[idx] = isUnlock
		local t = {}
		for k, v in pairs(leftDatas) do
			if showData[k] == true then
				t[k] = v
			end
		end
		self.leftDatas:update(t)
	end
	for k, v in pairs(leftDatas) do
		if not v.unlockKey then
			refreshData(k, true)
		else
			dataEasy.getListenUnlock(v.unlockKey, functools.partial(refreshData, k))
		end
	end

	local unionId = gGameModel.role:getIdler("union_db_id")
	local isUnion = true
	local childs = self.bottomPanelUnion:multiget("txtRank", "txtName", "txtStatic1", "txtState1", "txtState2", "txtState3")
	if unionId:read() then
		itertools.invoke({childs.txtRank, childs.txtName, childs.txtStatic1, childs.txtState1, childs.txtState2, childs.txtState3}, "show")
		self.bottomPanelUnion:get("none"):hide()
		idlereasy.any({self.unionName, self.unionLevel, self.chairmanId, self.members}, function (_, unionName, unionLevel, chairmanId, members)
			childs.txtName:text(unionName)
			childs.txtState1:text(unionLevel)
			local chairman = members[chairmanId]
			childs.txtState3:text(chairman.name)
			local currNum = itertools.size(members)
			local maxNum = csv.union.union_level[unionLevel].memberMax
			childs.txtState2:text(currNum.."/"..maxNum)

			-- 关卡星级 当前玩家数据
			self.bottomPanelGateStar:get("txtUnion"):text(unionName)  -- 默认无
		end)
	else
		self.bottomPanelUnion:get("none"):show()
		itertools.invoke({childs.txtRank, childs.txtName, childs.txtStatic1, childs.txtState1, childs.txtState2, childs.txtState3}, "hide")

		-- 关卡星级 当前玩家数据
		self.bottomPanelGateStar:get("txtUnion"):text(gLanguageCsv.none)  -- 默认无
	end

	-- 石英大会的个人相关数据在协议下行里才有，第一次大开时，设为空，避免显示出UI工程上的默认值
	self.bottomPanelCraft:get("txtScore"):text("")
	self.bottomPanelCraft:get("txtRecord"):text("")

	for i,v in ipairs(TAB_LIST) do
		self[v]:visible(false)
	end
	self.showTab = idler.new(1)
	self.powerList:visible(true)
	self.showTab:addListener(function(val, oldval, idler)
		self[TAB_LIST[oldval]]:visible(false)
		self[TAB_LIST[val]]:visible(true)
		-- 切换页签的时候刷新数据
		if val ~= oldval then
			self.datas[val] = {}
			self["showData"..val]:update({})
		end

		dataEasy.tryCallFunc(self[TAB_LIST[val]], "setItemAction", {isAction = true})
		if self.leftDatas:atproxy(val).type and #self.datas[val] == 0 then
			self:sendProtocol(self.leftDatas:atproxy(val).type, 0, val, self[TAB_LIST[val]])
		end
		self.leftDatas:atproxy(oldval).select = false
		self.leftDatas:atproxy(val).select = true
		self.leftDatas:atproxy(oldval).top:hide()
		self.leftDatas:atproxy(oldval).bottom:hide()
		self.leftDatas:atproxy(val).top:show()
		self.leftDatas:atproxy(val).bottom:show()
	end)
	for i, v in ipairs(TAB_LIST) do
		local container = self[v]:getInnerContainer()
		self[v]:onScroll(function(event)
			local y = container:getPositionY()
			if y >= -10 and self.isCanDown and self.leftDatas:atproxy(i).type then
				self.isCanDown = false
				self:sendProtocol(self.leftDatas:atproxy(i).type,#self.datas[i],i,self[v])
			end
		end)
	end
end

function RankView:initModel()
	self.roleName = gGameModel.role:getIdler("name")
	self.level = gGameModel.role:getIdler("level")
	self.fightRank = gGameModel.role:getIdler("fight_rank")
	self.power = gGameModel.role:getIdler("top6_fighting_point")
	self.id = gGameModel.role:read("id")
	self.pokedex = gGameModel.role:getIdler("pokedex")
	self.cardNumRank = gGameModel.role:getIdler("cardNum_rank")
	self.unionId = gGameModel.role:getIdler("union_db_id")
	self.gate_star_rank = gGameModel.role:getIdler("gate_star_rank")
	self.gate_star_sum = gGameModel.role:getIdler("gate_star_sum")
	if self.unionId:read() then
		self.unionRank = gGameModel.union:getIdler("rank")
		self.unionName = gGameModel.union:getIdler("name")
		self.unionLevel = gGameModel.union:getIdler("level")
		self.chairmanId = gGameModel.union:getIdler("chairman_db_id")
		self.members = gGameModel.union:getIdler("members")

	end
	self.craftRank = gGameModel.daily_record:getIdler("craft_rank")
end

function RankView:onTabClick(list, index)
	self.showTab:set(index)
end

function RankView:onUnionHeadClick(list, k, v, number, event)
	gGameUI:stackUI("city.union.join.detail", nil, nil, k, v, nil, self:createHandler("unionCb"))
end

function RankView:unionCb()
	ViewBase.onClose(self)
	gGameUI:stackUI("city.union.view", nil, {full = true})
end

function RankView:onHeadClick(list, k, v, number, event)
	if self.id == v.id then return end
	local target = event.target
	local x, y = target:xy()
	local pos = target:getParent():convertToWorldSpace(cc.p(x, y))
	gGameUI:stackUI("city.chat.personal_info", nil, {clickClose = true, dispatchNodes = list:parent()}, pos, {role = v}, {speical = "rank", target = list.item:get("bg"), disableTouch = true})
end

return RankView
