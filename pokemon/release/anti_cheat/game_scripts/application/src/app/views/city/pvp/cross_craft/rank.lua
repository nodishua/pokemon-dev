-- @desc: 	cross_craft-排行榜

local TAB_PANEL = {		-- panel列表
	"rankPanel",
	"rewardPanel",
}
local MINLV = csv.unlock[gUnlockCsv.craft].startLevel
local TOTAL_BATTLT_COUNT = 18

local ViewBase = cc.load("mvc").ViewBase
local CrossCraftRankView = class("CrossCraftRankView", Dialog)
CrossCraftRankView.RESOURCE_FILENAME = "cross_craft_rank.json"
CrossCraftRankView.RESOURCE_BINDING = {
	["topPanel.btnClose"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")}
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
						panel:get("txt"):setFontSize(v.fontSize) -- 选中状态排行榜奖励，50，无法放下，调整为45
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
	["rankPanel.rankItem"] = "rankItem",
	["rankPanel.list"] = {
		varname = "rankList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("showData1"),
				item = bindHelper.self("rankItem"),
				itemAction = {isAction = true},
				onItem = function(list, node, k, v)
					local childs = node:multiget("imgBg", "txtRank", "trainerIcon", "rankIcon", "txtName", "txtServer", "txtLv", "txtScore", "txtRecord")
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
					bind.extend(list, childs.trainerIcon, props)
					childs.txtName:text(v.name)
					childs.txtServer:text(getServerArea(v.game_key, true))
					adapt.oneLinePos(childs.txtName, childs.txtServer, cc.p(5,0), "left")
					childs.txtLv:text(math.max(MINLV, tonumber(v.level)))
					local index = k
					childs.txtRank:visible(index > 3)
					childs.txtRank:text(index)
					childs.rankIcon:visible(index < 4)
					if index <= 3 then
						childs.imgBg:texture("city/pvp/cross_craft/rank/box_phb"..index..".png")
						childs.rankIcon:texture("city/pvp/cross_craft/icon_"..index..".png")
					end
					childs.imgBg:setTouchEnabled(true)
					childs.txtScore:text(v.point)
					childs.txtRecord:text(string.format(gLanguageCsv.winAndLoseNum, v.win, math.min(v.round, TOTAL_BATTLT_COUNT)-v.win))
				end,
				asyncPreload = 10,
			},
		},
	},
	["rewardPanel"] = "rewardPanel",
	["rewardPanel.rewardItem"] = "rewardItem",   --  奖励列表
	["rewardPanel.list"] = {
		varname = "rewardList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("showData2"),
				item = bindHelper.self("rewardItem"),
				itemAction = {isAction = true},
				padding = 10,
				onItem = function(list, node, k, v)
					local childs = node:multiget("imgBg", "rankIcon", "itemList")
					local index = k
					if index <= 3 then
						childs.imgBg:texture("city/pvp/cross_craft/rank/box_phb"..index..".png")
						childs.rankIcon:texture("city/pvp/cross_craft/icon_"..index..".png")
					else
						local cfg = csv.cross.craft.rank
						local left = cfg[index-1].rankMax + 1
						local right = cfg[index].rankMax
						local str = left <  right and (left.."-"..right) or right

						-- 图片字创建
						bind.extend(list, node, {
							class = "text_atlas",
							props = {
								data = str,
								pathName = "cross_craft",
								isEqualDist = false,
								align = "center",
								onNode = function(node)
									node:xy(childs.rankIcon:xy())
									if left > 1000 then
										node:scale(0.8)
									end
								end,
							}
						})

						childs.rankIcon:hide()
					end

					-- 奖励列表，通用接口
					uiEasy.createItemsToList(list, childs.itemList, v.cfg.award, {margin = 11, scale = 0.9})
				end,
				asyncPreload = 10,
			},
		},
	},
	["rewardPanel.winOnceList"] = "winOnceList",
	["rewardPanel.loseOnceList"] = "loseOnceList",

	["myRankPanel"] = "myRankPanel",
	["myRankPanel.txtRank"] = "myRanking",
	["myRankPanel.txtName"] = "myName",
	["myRankPanel.txtScore"] = "myScore",
	["myRankPanel.txtRecord"] = "myRecord",
	["noRankPanel"] = "noRankPanel",
	["noRankPanel.txtNode"] = "noRankTxt"
}

function CrossCraftRankView:onCreate(data)
	self:initModel()
	self.showData1 = idlers.newWithMap(data.rank or {})
	local rewardData = {}
	for k, v in orderCsvPairs(csv.cross.craft.rank) do
		if v.version == self.version then
			table.insert(rewardData, {cfg = v})
		end
	end
	self.showData2 = idlers.newWithMap(rewardData)

	-- 单场胜 奖励
	uiEasy.createItemsToList(self, self.winOnceList, csv.cross.craft.base[1].winAward, {margin = 11, scale = 0.9})
	-- 单场负奖励
	uiEasy.createItemsToList(self, self.loseOnceList, csv.cross.craft.base[1].failAward, {margin = 11, scale = 0.9})

	self.myName:text(self.roleName:read())
	if data.myinfo then
		self.myScore:text(data.myinfo.point)
		self.myRecord:text(string.format(gLanguageCsv.winAndLoseNum, data.myinfo.win, math.min(data.myinfo.round, TOTAL_BATTLT_COUNT)-data.myinfo.win))
		-- 个人排名
		self.myRanking:text((data.myinfo.rank and data.myinfo.rank > 0) and data.myinfo.rank or gLanguageCsv.craftNoRank)
		self.myRanking:setFontSize((data.myinfo.rank and data.myinfo.rank > 0) and 70 or 50)
	else -- 服务器无数据，显示积分0，战况0胜0负
		self.myScore:text("0")
		self.myRecord:text(string.format(gLanguageCsv.winAndLoseNum, 0, 0))
		self.myRanking:text(gLanguageCsv.craftNoRank)
	end

	self.tabDatas = idlers.newWithMap({
		[1] = {name = gLanguageCsv.rankList,type = "rank", fontSize = 50},
		[2] = {name = gLanguageCsv.craftRankReward, fontSize = 43},
	})

	for i,v in ipairs(TAB_PANEL) do
		self[v]:visible(false)
	end
	self.showTab = idler.new(1)		-- 初始停留在第一页
	self.rankPanel:visible(true)     -- 初始显示第一页
	self.showTab:addListener(function(val, oldval)       -- 监听Tab页变换
		self[TAB_PANEL[oldval]]:visible(false)
		self[TAB_PANEL[val]]:visible(true)
		self.myRankPanel:visible(val ~= 2)	-- 第二个分页，为奖励分页，不需要显示自己排名
		self.noRankPanel:visible(false)

		-- 大赛首次筹办中
		if #data.rank == 0 and val == 1 then
			self[TAB_PANEL[val]]:visible(false)
			self.myRankPanel:visible(false)
			self.noRankPanel:visible(true)
			if self.round:read() == "prepare" or self.round:read() == "pre1" or self.round:read() == "pre1_lock" then
				self.noRankTxt:text(gLanguageCsv.craftRankGaming)
			end
		end

		self.tabDatas:atproxy(oldval).select = false     -- tab选中状态
		self.tabDatas:atproxy(val).select = true
	end)

	Dialog.onCreate(self)
end

function CrossCraftRankView:initModel()
	local dailyRecord = gGameModel.daily_record
	local craftData = gGameModel.cross_craft
	self.round = craftData:getIdler("round")
	self.roleName = gGameModel.role:getIdler("name")
	self.id = gGameModel.role:read("id")
	self.version = craftData:read("version")
end

function CrossCraftRankView:onTabClick(list, index)
	self.showTab:set(index)
end
return CrossCraftRankView
