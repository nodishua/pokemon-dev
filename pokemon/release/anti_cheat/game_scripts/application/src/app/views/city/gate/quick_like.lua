-- @date:   2020-07-28
-- @desc:   关卡-快速扫荡

local MAP_TYPE = {
	normal = 1,
	hero = 2,
	nightmare = 3,
}

local CHAPTER_NUM = {
	[MAP_TYPE.normal] = 10,
	[MAP_TYPE.hero] = 110,
	[MAP_TYPE.nightmare] = 210,
}

local ViewBase = cc.load("mvc").ViewBase
local GateQuickView = class("GateQuickView", Dialog)

local function createItemsToList(parent, list, data, params)
	params = params or {}
	local item = ccui.Layout:create()
		:size(0, 0)
		:hide()
	-- parent 是 listview 会有多余 margin 的显示
	-- item:hide():addTo(parent)
	item:retain()
	parent:onNodeEvent("exit", function()
		if item then
			item:release()
			item = nil
		end
	end)
	bind.extend(parent, list, {
		class = "listview",
		props = {
			data = dataEasy.getItemData(data),
			item = item,
			margin = params.margin,
			padding = params.padding,
			dataOrderCmp = function(a, b)
				return a.key > b.key
			end,
			onAfterBuild = params.onAfterBuild,
			onItem = function(list, node, k, v)
				bind.extend(list, node, {
					class = "icon_key",
					props = {
						data = v,
						grayState = v.grayState,
						isDouble = params.isDouble,
						onNode = function(panel)
							if params.scale then
								panel:scale(params.scale)
							end
							local bound = panel:box()
							panel:alignCenter(bound)
							node:size(bound)
							if params.onNode then
								params.onNode(panel, v)
							end
						end
					},
				})
			end,
		}
	})
	list:adaptTouchEnabled()
end

GateQuickView.RESOURCE_FILENAME = "gate_quick.json"
GateQuickView.RESOURCE_BINDING = {
	["topPanel.btnClose"] = {
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
					else
						selected:hide()
						panel = normal:show()
					end
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
	["panel"] = "panel1",
	["panel.listPanel"] = "listPanel",
	["panel.list"] = {
		varname = "list",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				asyncPreload = 4,
				preloadCenter = bindHelper.self("lastIdx"),
				data = bindHelper.self("dataNormal"),
				item = bindHelper.self("listPanel"),
				itemAction = {isAction = true},
				onItem = function(list, node, k, v)
					local childs = node:multiget(
						"txtNode",
						"list",
						"item"
					)
					childs.txtNode:text(string.format(gLanguageCsv.getaSectionBoxTitle, v.chapterId))
					text.addEffect(childs.txtNode, {outline={color = cc.c4b(234, 67, 22, 255), size=4}})
					childs.item:hide()
					for key, val in ipairs(v.chapterTable) do
						local item = childs.item:clone()
						item:get("name"):text(v.chapterId.."-"..val.index)
						if val.size < 3 then
							createItemsToList(list, item:get("list"), val.item, {scale = 0.67, margin = 50})
						else
							createItemsToList(list, item:get("list"), val.item, {scale = 0.67, margin = 5})
						end
						item:get("list"):setItemAlignCenter()
						childs.list:addChild(item)
						if val.star ~= 3 then
							item:get("btn"):hide()
							item:get("btn1.txt"):text(gLanguageCsv.talentChallenge)
							-- item:get("btn1.txt"):x(item:get("btn1.txt"):x() - 35)
							item:get("btn1"):x(265)
						else
							item:get("btn"):show()
							-- item:get("btn1.txt"):x(item:get("btn1.txt"):x())
						end
						item:show()
						bind.touch(list, item:get("btn"), {methods = {ended = functools.partial(list.flagBtn, key, val)}})
						bind.touch(list, item:get("btn1"), {methods = {ended = functools.partial(list.flagBtn1, key, val)}})
					end
					childs.list:setScrollBarEnabled(false)
				end,
				onAfterBuild = function(list)
				end,
			},
			handlers = {
				flagBtn = bindHelper.self("onSweepBtnTen"),
				flagBtn1 = bindHelper.self("onSweepBtnFifty"),
			},
		},
	},
	["panel1"] = "panel2",
	["panel1.panelNormal"] = "panelNormal",
	["panel1.panelLike"] = "panelLike",
	["panel1.panelNormal.listPanel"] = "itemNormal",
	["panel1.panelNormal.list"] = {
		varname = "list1",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				asyncPreload = 5,
				preloadCenter = bindHelper.self("lastIdx1"),
				data = bindHelper.self("dataHard"),
				item = bindHelper.self("itemNormal"),
				itemAction = {isAction = true},
				onItem = function(list, node, k, v)
					local childs = node:multiget(
						"txtNode",
						"list",
						"item1"
					)
					childs.txtNode:text(string.format(gLanguageCsv.getaSectionBoxTitle, v.chapterId))
					text.addEffect(childs.txtNode, {outline={color = cc.c4b(234, 67, 22, 255), size=4}})
					childs.item1:hide()
					childs.list:removeAllChildren()
					for key, val in ipairs(v.chapterTable) do
						local item = childs.item1:clone()
						item:get("name"):text(v.chapterId.."-"..val.index)
						if val.chance == 1 then
							item:get("chanceIcon"):show()
						else
							item:get("chanceIcon"):hide()
						end
						if val.like == 1 then
							item:get("star2"):hide()
							item:get("star1"):show()
						else
							item:get("star2"):show()
							item:get("star1"):hide()
						end
						if val.surplusTimes == 0 then
							item:get("btn.txt"):text(gLanguageCsv.reChallenge)
							item:get("btn"):texture("common/btn/btn_recharge.png")
							text.addEffect(item:get("btn.txt"), {color = ui.COLORS.NORMAL.RED})
						end
						if val.star ~= 3 then
							item:get("btn.txt"):text(gLanguageCsv.talentChallenge)
						end
						bind.touch(list, item:get("icon"), {methods = {ended = functools.partial(list.likeBtn, k, key, val)}})
						if val.chanceRecharge == false then
							item:get("panel"):setTouchEnabled(true)
							bind.touch(list, item:get("panel"), {methods = {ended = functools.partial(list.chanceBtn, k, key, val)}})
						else
							item:get("panel"):setTouchEnabled(false)
						end
						if val.star ~= 3 and val.chanceRecharge == false then
							item:get("maskIcon"):show()
							-- item:get("btn"):setTouchEnabled(false)
							-- item:get("icon"):setTouchEnabled(false)
							-- item:get("list"):setTouchEnabled(false)
							-- item:get("panel"):setTouchEnabled(false)
							-- bind.touch(list, item, {methods = {ended = functools.partial(list.maskIconBtn, key, val)}})
						else
							item:get("maskIcon"):hide()
						end
						bind.touch(list, item:get("btn"), {methods = {ended = functools.partial(list.flagBtn, key, val)}})
						bind.extend(list, item:get("list"), {
							class = "icon_key",
							props = {
								data = {
									key = val.item,
								},
								onNode = function(node)
									local x, y = item:get("list"):xy()
									node:xy(x + 40, y + 35)
										:scale(0.7)
								end,
							},
						})
						childs.list:addChild(item)
						item:show()
					end
					childs.list:setScrollBarEnabled(false)
				end,
				onAfterBuild = function(list)
				end,
			},
			handlers = {
				likeBtn = bindHelper.self("onLikeBtn"),
				chanceBtn = bindHelper.self("onChanceBtn"),
				flagBtn = bindHelper.self("onSweepBtn"),
				-- maskIconBtn = bindHelper.self("onMaskIconBtn"),
			},
		},
	},
	["panel1.panelLike.listItem"] = "listItem",
	["item"] = "item",
	["panel1.panelLike.list"] = {
		varname = "panelLikeList",
		binds = {
			event = "extend",
			class = "tableview",
			props = {
				data = bindHelper.self("dataLike"),
				item = bindHelper.self("listItem"),
				cell = bindHelper.self("item"),
				columnSize = 4,
				itemAction = {isAction = true},
				onCell = function(list, node, k, v)
					local childs = node:multiget("name", "icon1", "bg", "btn", "star1", "star2", "chanceIcon", "maskIcon", "icon", "panel")
					childs.name:text(v.chapterId.."-"..v.index)
					if v.like == 1 then
						childs.star2:hide()
						childs.star1:show()
					else
						childs.star2:show()
						childs.star1:hide()
					end
					if v.surplusTimes == 0 then
						childs.btn:get("txt"):text(gLanguageCsv.reChallenge)
						-- childs.btn:get("txt"):x(251)
						childs.btn:texture("common/btn/btn_recharge.png")
						text.addEffect(childs.btn:get("txt"), {color = ui.COLORS.NORMAL.RED})
					end
					if v.star ~= 3 then
						childs.btn:get("txt"):text(gLanguageCsv.talentChallenge)
						-- childs.btn:get("txt"):x(206)
					end
					if v.chance == 1 then
						childs.chanceIcon:show()
					else
						childs.chanceIcon:hide()
					end
					bind.touch(list, childs.btn, {methods = {ended = functools.partial(list.flagBtn, k, v)}})
					bind.touch(list, childs.icon, {methods = {ended = functools.partial(list.likeBtn1, list:getIdx(k).k, v)}})
					if v.chanceRecharge == false then
						childs.panel:setTouchEnabled(true)
						bind.touch(list, childs.panel, {methods = {ended = functools.partial(list.chanceBtnLike, list:getIdx(k).k, v)}})
					else
						childs.panel:setTouchEnabled(false)
					end
					if v.star ~= 3 and v.chanceRecharge == false then
						childs.maskIcon:show()
						-- childs.btn:setTouchEnabled(false)
						-- childs.icon:setTouchEnabled(false)
						-- childs.icon1:setTouchEnabled(false)
						-- childs.panel:setTouchEnabled(false)
						-- node:setTouchEnabled(true)
						-- bind.touch(list, node, {methods = {ended = functools.partial(list.maskIconBtn, k, v)}})
					else
						childs.maskIcon:hide()
					end
					bind.extend(list, childs.icon1, {
						class = "icon_key",
						props = {
							data = {
								key = v.item,
							},
							onNode = function(node)
								local x, y = childs.chanceIcon:xy()
								node:xy(x + 20, y - 70)
									:scale(0.7)
									:z(3)
							end,
						},
					})
				end,
				onAfterBuild = function(list)
				end
			},
			handlers = {
				chanceBtnLike = bindHelper.self("onChanceBtnLike"),
				likeBtn1 = bindHelper.self("onLikeBtn1"),
				flagBtn = bindHelper.self("onSweepBtn"),
				-- maskIconBtn = bindHelper.self("onMaskIconBtn"),
			},
		},
	},
	["panel1.btnBuy1"] = {
		varname = "btnBuy1",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onChangeClick")}
		},
	},
	["panel1.btnBuy1.txt"] = "btnBuy1Txt",
	["panel1.btnBuy2"] = {
		varname = "btnBuy2",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onChanceClick")}
		},
	},
	["panel1.btnBuy2.txt"] = {
		binds = {
			{
				event = "effect",
				data = {glow = {color = ui.COLORS.GLOW.WHITE}},
			},{
				event = "text",
				idler = bindHelper.self("chanceRecharge"),
				method = function(val)
					if val then
						return gLanguageCsv.setTarget
					end
					return gLanguageCsv.confirmSelection
				end,
			},
		}
	},
	["panel1.btnBuy3"] = {
		varname = "btnBuy3",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onAllsweepclick")}
		},
	},
	["panel1.txt"] = "txt",
	["panel1.txt1"] = "txt1",
	["panel1.txt2"] = "txt2",
	["panel1.icon"] = "icon",
	["bg1"] = "bg",
	["emptyPanel"] = "emptyPanel",
}

function GateQuickView:onCreate()
	self.bg:height(1119)
	self.owerCollection = idlers.new()
	self:initModel()
	self.panel1:hide()
	self.panel2:hide()
	self.panelLike:hide()
	self.showTab = idler.new(1)
	self.dataNormal = idlers.new()
	self.dataHard = idlers.new()
	self.dataLike = idlers.new()
	self.lastIdx = 1
	self.lastIdx1 = 1
	self.chance = {}
	self.chance1 = {}
	--判断是不是第一次点击
	self.hardClickFirst = false
	self.likeClickFirst = false
	--将快速扫荡的选择的关卡记录在本地
	local gateChanceData = userDefault.getForeverLocalKey("gateChanceData", {})
	for k, v in pairs(gateChanceData) do
		table.insert(self.chance, v)
	end
	local gateChanceData1 = userDefault.getForeverLocalKey("gateChanceData1", {})
	for k, v in pairs(gateChanceData1) do
		table.insert(self.chance1, v)
	end
	--对关卡收藏中选中的关卡做特殊处理，如果有被取消收藏选中也要被取消
	self:deleteUnlike()
	self.myCollectionData = {}
	--监听消耗的数据
	self.chanceData = idlers.new()
	self.chanceData1 = idlers.new()
	--监听全部清理数据
	self.chanceDataUpd = idlers.new()
	self.chanceDataUpd1 = idlers.new()
	self.chanceData:update(self.chance)
	self.chanceData1:update(self.chance1)
	self.chanceDataUpd:update(self.chance)
	self.chanceDataUpd1:update(self.chance1)
	--只看收藏保存的数据
	self.myCollection = idlers.new()
	--只看收藏按钮判断
	self.selectRecharge = idler.new(true)
	--设置目标按钮判断
	self.chanceRecharge = idler.new(true)

	local roleLevel = gGameModel.role:read("level")
	local dataNormal = {}
	local cfg = csv.scene_conf
	local map = csv.world_map
	local normalNum = CHAPTER_NUM[MAP_TYPE.normal]
	local heroNum = CHAPTER_NUM[MAP_TYPE.hero]
	for k, v in ipairs(self.mapOpen:read()) do
		if map[v].chapterType == 1 and roleLevel >= map[v].openLevel then
			table.insert(dataNormal, {
				chapterId = v - normalNum,
				chapterTable = {},
			})
		end
	end
	if not itertools.isempty(dataNormal) then
		table.sort(dataNormal, function(a, b)
			return a.chapterId < b.chapterId
		end)
	end
	for k, v in ipairs(self.gateOpen:read()) do
		local mapTmp = cfg[v].ownerId
		if map[mapTmp].chapterType == 1 and roleLevel >= map[mapTmp].openLevel then
			if cfg[v].kssdFlag == 1 then
				local index = 0
				for key, val in ipairs(map[cfg[v].ownerId].seq) do
					if v == val then
						index = key
					end
				end
				local tmp = {}
				local item = {}
				local size = 0
				for key, val in pairs(cfg[v].dropIds) do
					if type(key) == "number" then
						table.insert(tmp, {key = key, num = val})
					end
				end
				table.sort(tmp, function(a, b)
					return a.key > b.key
				end)
				for key, val in ipairs(tmp) do
					if key <= 3 then
						table.insert(item, val)
					end
					size = size + 1
				end
				table.insert(dataNormal[cfg[v].ownerId - normalNum].chapterTable, {
					chapterId = dataNormal[cfg[v].ownerId - normalNum].chapterId,
					id = v,
					item = item,
					index = index,
					size = size,
					star = self.gateStar:read()[v] and self.gateStar:read()[v].star or 0,
				})
			end
		end
	end
	local tmp = 0
 	for k, v in ipairs(dataNormal) do
		if not itertools.isempty(v.chapterTable) then
			table.sort(v.chapterTable, function(a, b)
				return a.id < b.id
			end)
		end
		tmp = tmp + 1
	end
	self.dataNormal:update(dataNormal)
	self.lastIdx = tmp

	idlereasy.any({self.chanceDataUpd, self.chanceRecharge, self.gateTimes, self.selectRecharge, self.collection}, function(_,chanceDataUpd, chanceRecharge, gateTimes, selectRecharge, collection)
		-- if self.selectRecharge:read() == true then
			local roleLevel = gGameModel.role:read("level")
			local data = {}
			for k, v in ipairs(self.mapOpen:read()) do
				if map[v].chapterType == 2 and roleLevel >= map[v].openLevel then
					table.insert(data, {
						chapterId = v - heroNum,
						chapterTable = {},
					})
				end
			end
			if not itertools.isempty(data) then
				table.sort(data, function(a, b)
					return a.chapterId < b.chapterId
				end)
			end
			for k, v in ipairs(self.gateOpen:read()) do
				local mapTmp = cfg[v].ownerId
				if map[mapTmp].chapterType == 2 and roleLevel >= map[mapTmp].openLevel then
					if cfg[v].kssdFlag == 1 then
						local tmp = 0
						for key, val in pairs(cfg[v].dropIds) do
							if type(key) == "number" then
								tmp = math.max(tmp, key)
							end
						end
						local surplusTimes = cfg[v].dayChallengeMax - (gateTimes[v] or 0)
						local like = 0
						local chance = 0
						for key, val in ipairs(collection) do
							if val == v then
								like = 1
							end
						end
						for key, val in ipairs(self.chance) do
							if val == v then
								chance = 1
							end
						end
						local index = 0
						for key, val in ipairs(map[cfg[v].ownerId].seq) do
							if v == val then
								index = key
							end
						end
						table.insert(data[cfg[v].ownerId - heroNum].chapterTable, {
							chapterId = data[cfg[v].ownerId - heroNum].chapterId,
							id = v,
							item = tmp,
							chanceRecharge = chanceRecharge,
							chance = chance,
							like = like,
							surplusTimes = surplusTimes,
							star = self.gateStar:read()[v] and self.gateStar:read()[v].star or 0,
							index = index
						})
					end
				end
			end
			local tmp1 = 0
			for k, v in ipairs(data) do
				if not itertools.isempty(v.chapterTable) then
					table.sort(v.chapterTable, function(a, b)
						return a.id < b.id
					end)
				end
				tmp1 = tmp1 + 1
			end
			self.lastIdx1 = tmp1
			dataEasy.tryCallFunc(self.list1, "updatePreloadCenterIndex")
			self.dataHard:update(data)
		-- end
	end)

	self.panel = {
		{
			node = self.panel1,
			data = self.dataNormal,
		},
		{
			node = self.panel2,
			data = self.dataHard,
		},
	}

	self.tabDatas = idlers.newWithMap({
		[1] = {name = gLanguageCsv.gateStoryBlank, fontSize = 50},
		[2] = {name = gLanguageCsv.gateDifficultBlank, fontSize = 50},
	})
	self.showTab:addListener(function(val, oldval)
		self.tabDatas:atproxy(oldval).select = false
		self.tabDatas:atproxy(val).select = true
		self.panel[oldval].node:hide()
		self.panel[val].node:show()
	end)

	idlereasy.any({self.selectRecharge, self.chanceRecharge}, function(_, selectRecharge, chanceRecharge)
		if selectRecharge == false and itertools.isempty(self.owerCollectionData) then
			self.emptyPanel:show()
		else
			self.emptyPanel:hide()
		end
		if chanceRecharge == true then
			if selectRecharge == true then
				self.btnBuy1Txt:text(gLanguageCsv.onlyCollection)
				self.panelNormal:show()
				self.panelLike:hide()
			else
				self.btnBuy1Txt:text(gLanguageCsv.seeAll)
				self.panelNormal:hide()
				self.panelLike:show()
			end
			self.txt2:hide()
		else
			self.btnBuy1Txt:text(gLanguageCsv.cleanAllChance)
			self.txt2:show()
		end
	end)

	idlereasy.any({self.chanceData, self.gateTimes, self.chanceData1, self.selectRecharge}, function(_, chanceData, gateTimes, chanceData1, selectRecharge)
		self.staminaCost = 0
		local roleLevel = gGameModel.role:read("level")
		if self.selectRecharge:read() == true then
			for k, v in ipairs(self.chance) do
				local ownerId = cfg[v].ownerId
				if roleLevel >= map[ownerId].openLevel then
					local surplusTimes = cfg[v].dayChallengeMax - (gateTimes[v] or 0)
					self.staminaCost = csv.scene_conf[v].staminaCost * surplusTimes + self.staminaCost
				end
			end
		else
			for k, v in ipairs(self.chance1) do
				local ownerId = cfg[v].ownerId
				if roleLevel >= map[ownerId].openLevel then
					local surplusTimes = cfg[v].dayChallengeMax - (gateTimes[v] or 0)
					self.staminaCost = csv.scene_conf[v].staminaCost * surplusTimes + self.staminaCost
				end
			end
		end
		self.txt1:text(self.staminaCost)
		adapt.oneLineCenterPos(cc.p(1475, 57), {self.txt, self.icon, self.txt1}, cc.p(2, 0))
	end)

	self.txt2:text(gLanguageCsv.chooseGateToSweepText)
	Dialog.onCreate(self)
end

function GateQuickView:initModel()
	self.owerCollectionData = {}
	self.gateOpen = gGameModel.role:getIdler("gate_open") -- 开放的关卡列表
	self.collection = gGameModel.role:getIdler("mop_up_collection") -- 收藏的的关卡列表
	for k, v in ipairs(self.collection:read()) do
		table.insert(self.owerCollectionData, v)
	end
	self.owerCollection:update(self.owerCollectionData)
	self.gateStar = gGameModel.role:getIdler("gate_star") -- 星星数量
	self.mapOpen = gGameModel.role:getIdler("map_open") -- 开放的章节地图列表 -- 现在吧key当成是chapterId
	self.gateTimes = gGameModel.daily_record:getIdler("gate_times")
	self.roleLv = gGameModel.role:getIdler("level")
	self.buyHerogateTimes = gGameModel.daily_record:getIdler("buy_herogate_times")
	self.vipLevel = gGameModel.role:getIdler("vip_level")
	-- self.privilegeSweepTimes = dataEasy.getPrivilegeVal(game.PRIVILEGE_TYPE.GateSaoDangTimes) or 0
	self.buyHerogateTimes = gGameModel.daily_record:getIdler("buy_herogate_times")
	self.rmb = gGameModel.role:getIdler("rmb")
end

function GateQuickView:onTabClick(list, index)
	self.showTab:set(index)
	if index == 1 then
		self.bg:height(1119)
		self.bg:show()
	else
		idlereasy.when(self.selectRecharge, function (_, selectRecharge)
			if selectRecharge == true then
				self.bg:height(1008)
				self.bg:show()
			else
				self.bg:hide()
			end
		end)
	end
end

function GateQuickView:onItemClick(list, panel, k, v)
	gGameUI:showItemDetail(panel, {key = v.key, num = v.num})
end

function GateQuickView:onChangeClick()
	if self.likeClickFirst == false then
		local cfg = csv.scene_conf
		local map = csv.world_map
		local normalNum = CHAPTER_NUM[MAP_TYPE.normal]
		local heroNum = CHAPTER_NUM[MAP_TYPE.hero]
		idlereasy.any({self.chanceDataUpd1 , self.chanceRecharge, self.gateTimes, self.owerCollection, self.myCollection}, function(_, chanceDataUpd1, chanceRecharge, gateTimes, owerCollection, myCollection)
			local dataLike = {}
			local roleLevel = gGameModel.role:read("level")
			for k, v in ipairs(owerCollection) do
				local surplusTimes = cfg[v:read()].dayChallengeMax - (gateTimes[v:read()] or 0)
				local like = 0
				local chance = 0
				for key, val in ipairs(myCollection) do
					if val:read().id == v:read() then
						like = 1
					end
				end
				local tmp = 0
				for key, val in pairs(cfg[v:read()].dropIds) do
					if type(key) == "number" then
						if tmp > key then
								tmp = tmp
						else
							tmp = key
						end
					end
				end
				for key, val in ipairs(self.chance1) do
					if val == v:read() then
						chance = 1
					end
				end
				local index = 0
				for key, val in ipairs(map[cfg[v:read()].ownerId].seq) do
					if v:read() == val then
						index = key
					end
				end
				local chapterId = cfg[v:read()].ownerId - heroNum
				if roleLevel >= map[cfg[v:read()].ownerId].openLevel then
					table.insert(dataLike, {
						chapterId = chapterId,
						id = v:read(),
						item = tmp,
						like = like,
						chanceRecharge = chanceRecharge,
						chance = chance,
						surplusTimes = surplusTimes,
						star = self.gateStar:read()[v:read()] and self.gateStar:read()[v:read()].star or 0,
						index = index
					})
				end
			end
			table.sort(dataLike, function(a, b)
				return a.id < b.id
			end)
			self.dataLike:update(dataLike)
		end)
		self.likeClickFirst = true
	end
	if self.chanceRecharge:read() == false then
		if self.selectRecharge:read() == true then
			self.chance = {}
			self.chanceData:update(self.chance)
			self.chanceDataUpd:update(self.chance)
		else
			self.chance1 = {}
			self.chanceData1:update(self.chance1)
			self.chanceDataUpd1:update(self.chance1)
		end
	else
		self.selectRecharge:modify(function(val)
			return true, not val
		end)
	end
end

function GateQuickView:onChanceClick()
	self.chanceRecharge:modify(function(val)
		if val == false then
			userDefault.setForeverLocalKey("gateChanceData", self.chance, {new = true})
			userDefault.setForeverLocalKey("gateChanceData1", self.chance1, {new = true})
		end
		return true, not val
	end)
end


function GateQuickView:checkSweep(v, times)
	local staminaCost = csv.scene_conf[v.id].staminaCost
	local curStamina = dataEasy.getStamina()
	if curStamina < staminaCost  then
		gGameUI:stackUI("common.gain_stamina")
		return false
	end
	self.curMopUpNum = math.min(times, math.floor(curStamina / staminaCost))
	return true
end

function GateQuickView:checkAllSweep()
	local curStamina = dataEasy.getStamina()
	if self.staminaCost == 0 then
		gGameUI:showTip(gLanguageCsv.timeNotEnoughToSweepAll)
		return false
	end
	if curStamina < self.staminaCost then
		gGameUI:stackUI("common.gain_stamina")
		return false
	end
	return true
end

function GateQuickView:onSweepBtnTen(list, key, val)
	local times = 10
	-- if self.privilegeSweepTimes >= 10 or csv.vip[self.vipLevel:read() + 1].saodangCountOpen >= 10 or csv.common_config[5003].value <= self.roleLv:read() then
	if dataEasy.getSaoDangState(times).canSaoDang then
		if not self:checkSweep(val, times) then
			return
		end
		local oldCapture = gGameModel.capture:read("limit_sprites")
		local roleLv = self.roleLv:read()
		gGameApp:requestServer("/game/saodang",function (tb)
			local items = tb.view.result
			table.insert(items, {exp=0, items=tb.view.extra, isExtra=true})
			gGameUI:stackUI("city.gate.sweep", nil, nil, {
				sweepData = items,
				oldRoleLv = roleLv,
				cb = self:createHandler("onSweepBtnTen", list, key, val),
				checkCb = self:createHandler("checkSweep", val, times),
				hasExtra = true,
				from = "gate",
				oldCapture = oldCapture,
				isDouble = dataEasy.isGateIdDoubleDrop(val.id),
				gateId = val.id,
				catchup = tb.view.catchup
			})
		end,val.id, self.curMopUpNum)
	else
		gGameUI:showTip(gLanguageCsv.saodangMultiRoleNotEnough)
	end
end

function GateQuickView:onSweepBtnFifty(list, key, val)
	if val.star ~= 3 then
		gGameUI:stackUI("city.gate.section_detail.view", nil, nil, val.id, val.chapterId)
		return
	end
	local times = 50
	-- local vipTimes = self.vipLevel:read() ~= 0 and csv.vip[self.vipLevel:read()].saodangCountOpen or 0
	-- if self.privilegeSweepTimes >= 50 or vipTimes >= 50 or self.roleLv:read() >= csv.common_config[5003].value then
	if dataEasy.getSaoDangState(times).canSaoDang then
		if not self:checkSweep(val, times) then
			return
		end
		local oldCapture = gGameModel.capture:read("limit_sprites")
		local roleLv = self.roleLv:read()
		gGameApp:requestServer("/game/saodang",function (tb)
			local items = tb.view.result
			table.insert(items, {exp=0, items=tb.view.extra, isExtra=true})
			gGameUI:stackUI("city.gate.sweep", nil, nil, {
				sweepData = items,
				oldRoleLv = roleLv,
				cb = self:createHandler("onSweepBtnFifty", list, key, val),
				checkCb = self:createHandler("checkSweep", val, times),
				hasExtra = true,
				from = "gate",
				oldCapture = oldCapture,
				isDouble = dataEasy.isGateIdDoubleDrop(val.id),
				gateId = val.id,
				catchup = tb.view.catchup
			})
		end,val.id, self.curMopUpNum)
	else
		gGameUI:showTip(gLanguageCsv.saodangMultiRoleNotEnough)
	end
end

function GateQuickView:onSweepBtn(list, key, val)
	if val.star ~= 3 then
		gGameUI:stackUI("city.gate.section_detail.view", nil, nil, val.id, val.chapterId)
		return
	end
	local cfg = csv.scene_conf
	local surplusTimes = 0
	idlereasy.when(self.gateTimes, function(_, gateTimes)
		surplusTimes = cfg[val.id].dayChallengeMax - (gateTimes[val.id] or 0)
	end)
	if surplusTimes == 0 then
		local buyTimeMax = gVipCsv[self.vipLevel:read()].buyHeroGateTimes
		local buyHerogateTimes = self.buyHerogateTimes:read()
		if (buyHerogateTimes[val.id] or 0) >= buyTimeMax then
			gGameUI:showTip(gLanguageCsv.herogateBuyMax)
			return
		end
		local strs = {
			"#C0x5b545b#"..string.format(gLanguageCsv.resetNumberEliteLevels1,gCostCsv.herogate_buy_cost[(buyHerogateTimes[val.id] or 0) + 1]),
			"#C0x5b545b#"..string.format(gLanguageCsv.resetNumberEliteLevels2,buyHerogateTimes[val.id] or 0,buyTimeMax)
		}
		gGameUI:showDialog({content = strs, cb = function()
			if self.rmb:read() < gCostCsv.herogate_buy_cost[(buyHerogateTimes[val.id] or 0) + 1] then
				uiEasy.showDialog("rmb", nil, {dialog = true})
				return
			end
			gGameApp:requestServer("/game/role/hero_gate/buy",function()
				gGameUI:showTip(gLanguageCsv.resetSuccess)
			end, val.id)
		end, btnType = 2, isRich = true, dialogParams = {clickClose = false}})
		return
	end
	local times = 3
		if not self:checkSweep(val, times) then
			return
		end
		local oldCapture = gGameModel.capture:read("limit_sprites")
		local roleLv = self.roleLv:read()
		gGameApp:requestServer("/game/saodang",function (tb)
			local items = tb.view.result
			table.insert(items, {exp=0, items=tb.view.extra, isExtra=true})
			gGameUI:stackUI("city.gate.sweep", nil, nil, {
				sweepData = items,
				oldRoleLv = roleLv,
				cb = self:createHandler("onSweepBtn", list, key, val),
				checkCb = self:createHandler("checkSweep", val, times),
				hasExtra = true,
				from = "gate",
				oldCapture = oldCapture,
				isDouble = dataEasy.isGateIdDoubleDrop(val.id),
				gateId = val.id,
				catchup = tb.view.catchup
			})
		end,val.id, times)
end

function GateQuickView:onAllsweepclick(list, key, val)
	local cfg = csv.scene_conf
	local map = csv.world_map
	local roleLevel = gGameModel.role:read("level")
	local chanceData = {}
	for k, v in ipairs(self.chance) do
		local ownerId = cfg[v].ownerId
		if roleLevel >= map[ownerId].openLevel then
			if v ~= 0 then
				table.insert(chanceData, v)
			end
		end
	end
	local chanceData1 = {}
	for k, v in ipairs(self.chance1) do
		local ownerId = cfg[v].ownerId
		if roleLevel >= map[ownerId].openLevel then
			if v ~= 0 then
				table.insert(chanceData1, v)
			end
		end
	end
	if self.selectRecharge:read() == true then
		if itertools.isempty(chanceData) then
			gGameUI:showTip(gLanguageCsv.pleaseChanceGate)
		elseif self.chanceRecharge:read() == false then
			gGameUI:showTip(gLanguageCsv.pleaseCheckFirst)
		else
			if not self:checkAllSweep() then
				return
			end
			local oldCapture = gGameModel.capture:read("limit_sprites")
			local roleLv = self.roleLv:read()
			gGameApp:requestServer("/game/saodang/batch",function (tb)
				local items = tb.view.result
				table.insert(items, {exp=0, items=tb.view.extra, isExtra=true})
				gGameUI:stackUI("city.gate.sweep", nil, nil, {
					sweepData = items,
					oldRoleLv = roleLv,
					cb = self:createHandler("onAllsweepclick", list, key, val),
					checkCb = self:createHandler("checkAllSweep"),
					hasExtra = true,
					from = "allGate",
					oldCapture = oldCapture,
					isDouble = dataEasy.isGateIdDoubleDrop(chanceData[1]),
					catchup = tb.view.catchup
				})
			end, chanceData)
		end
	else
		if itertools.isempty(chanceData1) then
			gGameUI:showTip(gLanguageCsv.pleaseChanceGate)
		elseif self.chanceRecharge:read() == false then
			gGameUI:showTip(gLanguageCsv.pleaseCheckFirst)
		else
			if not self:checkAllSweep() then
				return
			end
			local oldCapture = gGameModel.capture:read("limit_sprites")
			local roleLv = self.roleLv:read()
			gGameApp:requestServer("/game/saodang/batch",function (tb)
				local items = tb.view.result
				table.insert(items, {exp=0, items=tb.view.extra, isExtra=true})
				gGameUI:stackUI("city.gate.sweep", nil, nil, {
					sweepData = items,
					oldRoleLv = roleLv,
					cb = self:createHandler("onAllsweepclick", list, key, val),
					checkCb = self:createHandler("checkAllSweep"),
					hasExtra = true,
					from = "allGate",
					oldCapture = oldCapture,
					isDouble = dataEasy.isGateIdDoubleDrop(chanceData1[1]),
					catchup = tb.view.catchup
				})
			end, chanceData1)
		end
	end
end

function GateQuickView:onLikeBtn(list, k, key, val)
	local index = 0
	for k, v in ipairs(self.collection:read()) do
		if v == val.id then
			index = k
			break
		end
	end
	if index == 0 then
		local charge = false
		for k, v in ipairs(self.myCollectionData) do
			if v.id == val.id then
				table.remove(self.myCollectionData, k)
				self.myCollection:update(self.myCollectionData)
				charge = true
				break
			end
		end
		if not charge then
			table.insert(self.owerCollectionData, val.id)
		end
		gGameUI:showTip(gLanguageCsv.collectSucceed)
	else
		for k, v in ipairs(self.owerCollectionData) do
			if v == val.id then
				table.remove(self.owerCollectionData, k)
				break
			end
		end
		gGameUI:showTip(gLanguageCsv.collectCancel)
	end
	-- self.myCollection:update(self.myCollectionData)
	self.owerCollection:update(self.owerCollectionData)
	-- local like = self.dataHard:atproxy(k).chapterTable[key].like
	-- self.dataHard:atproxy(k).chapterTable[key].like = like == 1 and 0 or 1
	gGameApp:requestServer("/game/saodang/batch/favorites", nil, val.id)
end

function GateQuickView:onLikeBtn1(list, key, val)
	gGameApp:requestServer("/game/saodang/batch/favorites", nil, val.id)
	local index = 0
	for k, v in ipairs(self.myCollectionData) do
		if v.id == val.id then
			index = k
			break
		end
	end
	if index == 0 then
		table.insert(self.myCollectionData, {id = val.id})
		gGameUI:showTip(gLanguageCsv.collectCancel)
	else
		table.remove(self.myCollectionData, index)
		gGameUI:showTip(gLanguageCsv.collectSucceed)
	end
	self.myCollection:update(self.myCollectionData)
	-- local like = self.dataLike:atproxy(key).like
	-- self.dataLike:atproxy(key).like = like == 1 and 0 or 1
end

function GateQuickView:onChanceBtn(list, k, key, val)
	local tmp = 0
	local index = 0
	for k, v in ipairs(self.chance) do
		if v == val.id then
			tmp = 1
			index = k
			break
		end
	end
	if tmp == 0 then
		table.insert(self.chance, val.id)
	else
		table.remove(self.chance, index)
	end
	table.sort(self.chance, function(a, b)
		return  a < b
	end)
	self.chanceData:update(self.chance)
	local chance = self.dataHard:atproxy(k).chapterTable[key].chance
	self.dataHard:atproxy(k).chapterTable[key].chance = chance == 1 and 0 or 1
end

function GateQuickView:onChanceBtnLike(list, key, val)
	local tmp = 0
	local index = 0
	for k, v in ipairs(self.chance1) do
		if v == val.id then
			tmp = 1
			index = k
			break
		end
	end
	if tmp == 0 then
		table.insert(self.chance1, val.id)
	else
		table.remove(self.chance1, index)
	end
	table.sort(self.chance1, function(a, b)
		return  a < b
	end)
	self.chanceData1:update(self.chance1)
	local a = self.dataLike:atproxy(k)
	local chance = self.dataLike:atproxy(key).chance
	self.dataLike:atproxy(key).chance = chance == 1 and 0 or 1
end

function GateQuickView:onClose()
	if self.chanceRecharge:read() == false then
		local strs = {
			"#C0x5b545b#"..gLanguageCsv.noSaveToQuit
		}
		gGameUI:showDialog({content = strs, cb = function()
			ViewBase.onClose(self)
		end, btnType = 2, isRich = true, dialogParams = {clickClose = false}})
		return
	end
	ViewBase.onClose(self)
end

function GateQuickView:onShowDetail(list, node, key, val)
	gGameUI:showItemDetail(node, {key = val.item.key, num = val.item.num})
end

function GateQuickView:deleteUnlike()
	local index = 0
	for k, v in ipairs(self.chance1) do
		if not itertools.include(self.collection:read(), v) then
			index = index + 1
		end
	end
	if index ~= 0 then
		for i = 1, index do
			local tmp = 0
			for k, v in ipairs(self.chance1) do
				if not itertools.include(self.collection:read(), v) then
					tmp = k
					break
				end
			end
			table.remove(self.chance1, tmp)
		end
	end
end

return GateQuickView
