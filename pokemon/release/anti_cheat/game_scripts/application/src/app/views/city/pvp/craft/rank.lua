-- @desc: 	craft-排行榜

local TAB_Panel = {		-- panel列表
	"rankPanel",
	"rewardPanel",
}
local MINLV = csv.unlock[gUnlockCsv.craft].startLevel

local ViewBase = cc.load("mvc").ViewBase
local CraftRankView = class("CraftRankView", Dialog)
CraftRankView.RESOURCE_FILENAME = "craft_rank.json"
CraftRankView.RESOURCE_BINDING = {
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
					local role = v.role
					local childs = node:multiget("imgBg", "txtRank", "trainerIcon", "rankIcon", "txtName", "txtLv", "txtScore", "txtRecord")
					local props = {
						event = "extend",
						class = "role_logo",
						props = {
							logoId = role.logo,
							level = false,
							vip = false,
							frameId = role.frame,
							onNode = function(node)
								node:xy(104, 95)
									:z(6)
									:scale(0.9)
							end,
						}
					}
					bind.extend(list, childs.trainerIcon, props)
					childs.txtName:text(role.name)
					childs.txtLv:text(math.max(MINLV, tonumber(role.level)))
					local index = k
					childs.txtRank:visible(index > 3)
					childs.txtRank:text(index)
					childs.rankIcon:visible(index < 4)
					if index <= 3 then
						childs.imgBg:texture("city/pvp/craft/dialog_icon/iten_"..index..".png")
						childs.rankIcon:texture("city/pvp/craft/img_xz"..index..".png")
					end
					childs.imgBg:setTouchEnabled(true)
					childs.imgBg:onClick(functools.partial(list.clickHead, k, role, index))
					childs.txtScore:text(v.craft.point)
					childs.txtRecord:text(string.format(gLanguageCsv.winAndLoseNum, v.craft.win, math.min(v.craft.round, 13)-v.craft.win))
				end,
				asyncPreload = 10,
			},
			handlers = {
				clickHead = bindHelper.self("onHeadClick"),
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
				onItem = function(list, node, k, v)
					local childs = node:multiget("imgBg", "rankIcon", "itemList")
					local rankMax = v.cfg.rankMax
					if rankMax <= 3 then
						childs.imgBg:texture("city/pvp/craft/dialog_icon/iten_"..rankMax..".png")
						childs.rankIcon:texture("city/pvp/craft/img_xz"..rankMax..".png")
					else
						local cfg = csv.craft.rank
						local left = cfg[v.csvId-1].rankMax + 1
						local right = cfg[v.csvId].rankMax
						local str = left <  right and (left.."-"..right) or right

						-- 图片字创建
						bind.extend(list, node, {
							class = "text_atlas",
							props = {
								data = str,
								pathName = "craft",
								isEqualDist = false,
								align = "center",
								onNode = function(node)
									node:xy(childs.rankIcon:x(), childs.rankIcon:y())
								end,
							}
						})
						childs.rankIcon:hide()
					end

					-- 奖励列表，通用接口
					uiEasy.createItemsToList(list, childs.itemList, v.award, {margin = 11, scale = 0.8})
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

function CraftRankView:onCreate(data)
	self:initModel()
	self.datas = {}		-- 列表数据集合
	for i = 1, #TAB_Panel do
		self.datas[i] = i == 1 and data.rank or {}     -- 默认停留在第一个Tab，且数据由服务器下发获取
		if i == 2 then
			local version = getVersionContainMerge("pwAwardVer")
			for k,v in orderCsvPairs(csv.craft.rank) do
				if v.version == version then
					table.insert(self.datas[i], {csvId = k, cfg = v, award = self:getAwardBylevel(v.award)})
				end
			end
		end
		self["showData"..i] = idlers.newWithMap(self.datas[i])
	end
	-- 单场胜 奖励
	uiEasy.createItemsToList(self, self.winOnceList, self:getAwardBylevel(csv.craft.base[1].winAward), {margin = 11, scale = 0.8})
	-- 单场负奖励
	uiEasy.createItemsToList(self, self.loseOnceList, self:getAwardBylevel(csv.craft.base[1].failAward), {margin = 11, scale = 0.8})

	-- 个人排名
	self.myRanking:text((self.craftRank:read() and self.craftRank:read() > 0) and self.craftRank:read() or gLanguageCsv.craftNoRank)
	self.myRanking:setFontSize((self.craftRank:read() and self.craftRank:read() > 0) and 70 or 50)
	self.myName:text(self.roleName:read())
	if data.craft then
		self.myScore:text(data.craft.point)
		self.myRecord:text(string.format(gLanguageCsv.winAndLoseNum, data.craft.win, math.min(data.craft.round, 13)-data.craft.win))
	else -- 服务器无数据，显示积分0，战况0胜0负
		self.myScore:text("0")
		self.myRecord:text(string.format(gLanguageCsv.winAndLoseNum, 0, 0))
	end

	self.tabDatas = idlers.newWithMap({
		[1] = {name = gLanguageCsv.rankList,type = "rank", fontSize = 50},
		[2] = {name = gLanguageCsv.craftRankReward, fontSize = 43},
	})

	for i,v in ipairs(TAB_Panel) do
		self[v]:visible(false)
	end
	self.showTab = idler.new(1)		-- 初始停留在第一页
	self.rankPanel:visible(true)     -- 初始显示第一页
	self.showTab:addListener(function(val, oldval)       -- 监听Tab页变换
		self[TAB_Panel[oldval]]:visible(false)
		self[TAB_Panel[val]]:visible(true)
		self.myRankPanel:visible(val ~= 2)	-- 第二个分页，为奖励分页，不需要显示自己排名
		self.noRankPanel:visible(false)

		-- 大赛首次筹办中
		if #data.rank == 0 and val == 1 then
			self[TAB_Panel[val]]:visible(false)
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

function CraftRankView:initModel()
	local dailyRecord = gGameModel.daily_record
	local craftData = gGameModel.craft
	self.round = craftData:getIdler("round")
	self.roleName = gGameModel.role:getIdler("name")
	self.craftRank = dailyRecord:getIdler("craft_rank")
	self.id = gGameModel.role:read("id")
	self.level = gGameModel.role:read("level")
end

function CraftRankView:onTabClick(list, index)
	self.showTab:set(index)
end

function CraftRankView:onHeadClick(list, k, v, number, event)
	if self.id == v.id then return end
	local target = event.target
	local x, y = target:xy()
	local pos = target:getParent():convertToWorldSpace(cc.p(x, y))
	gGameUI:stackUI("city.chat.personal_info", nil, nil, pos, {role = v}, {speical = "rank", target = list.item:get("imgBg")})
end

function CraftRankView:getAwardBylevel(data)
	local award = {}
	for k, val in csvPairs(data) do
		if self.level >= val[1] and self.level <= val[2] then
			award = val[3]
			break
		end
	end
	return award
end

return CraftRankView
