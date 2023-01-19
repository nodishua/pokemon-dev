-- @date 2020-06-28
-- @desc 钓鱼背包


local LINE_NUM = 4
local PADDING_WIDTH = 25

local FishingBagView = class('FishingBagView', Dialog)
FishingBagView.RESOURCE_FILENAME = 'fishing_bag.json'

FishingBagView.RESOURCE_BINDING = {
	["title.btnClose"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")}
		},
	},
	["btn"] = "btnItem",
	["left.list"] = {
		varname = "btnList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("btnDatas"),
				item = bindHelper.self("btnItem"),
				itemAction = {isAction = true},
				onItem = function(list, node, k, v)
					local normal = node:get("btnNormal")
					local selected = node:get("btnSelected")
					selected:visible(v.selected)
					normal:visible(not v.selected)
					normal:get("txt"):text(v.txt)
					selected:get("txt"):text(v.txt)

					bind.touch(list, normal, {methods = {ended = functools.partial(list.clickCell, k, v)}})
				end,
			},
			handlers = {
				clickCell = bindHelper.self("onSelectClick"),
			},
		},
	},
	["center"] = "center",
	["center.item"] = "item",
	["center.subList"] = "subList",
	["center.list"] = {
		varname = "list",
		binds = {
			event = "extend",
			class = "tableview",
			props = {
				data = bindHelper.self("itemDatas"),
				columnSize = LINE_NUM,
				item = bindHelper.self("subList"),
				cell = bindHelper.self("item"),
				leftPadding = PADDING_WIDTH,
				topPadding = PADDING_WIDTH,
				itemAction = {isAction = true},
				onCell = function(list, node, k, v)
					bind.extend(list, node, {
						class = "fishtools_icon",
						props = {
							data = {
								key = v.id,
								typ = v.typ,
								needLv = v.needLv,
								lock = v.isLock,
							},
							onNode = function(node)
								if v.selectEffect then
									v.selectEffect:removeSelf()
									v.selectEffect:align(cc.p(0.5, 0.5), 100, 100)
									node:add(v.selectEffect, -1)

									local selected = "common/box/box_selected.png"
									local scale = 1
									if v.typ == 3 then
										selected = "common/box/box_portrait_select.png"
										scale = 0.9
									end
									v.selectEffect:scale(scale)
									v.selectEffect:texture(selected)
								end
							end,
							lock = true,
							num = true,
						},
					})
					local t = list:getIdx(k)
					node:get("use"):visible(v.isUse)

					local mask = "common/box/mask_fangd.png"
					local scale = 1
					local txtScale = 1
					if v.typ == 3 then
						mask = "common/box/mask_d.png"
						scale = 1.2
						txtScale = 0.7
					end
					node:get("use"):texture(mask)
					node:get("use"):scale(scale)
					node:get("use"):get("txt")
						:scale(txtScale)
						:xy(node:get("use"):width()/2, node:get("use"):height()/2)
					text.addEffect(node:get("use"):get("txt"), {outline = {color = cc.c4b(91, 84, 91, 255), size = 3}})

					bind.click(list, node, {method = functools.partial(list.itemClick, t, v)})
				end,
			},
			handlers = {
				itemClick = bindHelper.self("onItemClick"),
			},
		},
	},
	["rightRod"] = "rightRod",
	["rightRod.specialGet"] = "rodSpecialGet",
	["rightRod.value"] = "rodVal",
	["rightRod.value.speed"] = "rodValSpe",
	["rightRod.value.speed.name"] = "rodSpeName",
	["rightRod.value.speed.txt"] = "rodSpeTxt",
	["rightRod.value.upSpeed"] = "rodValUpSpe",
	["rightRod.value.upSpeed.name"] = "rodUpSpeName",
	["rightRod.value.upSpeed.txt"] = "rodUpSpeTxt",
	["rightRod.value.scaleUp"] = "rodValScaleUp",
	["rightRod.value.scaleUp.name"] = "rodScaleUpName",
	["rightRod.value.scaleUp.txt"] = "rodScaleUpTxt",
	["rightRod.value.autoSuccessRate"] = "rodValAutoSuccessRate",
	["rightRod.value.autoSuccessRate.name"] = "rodAutoSuccessRateName",
	["rightRod.value.autoSuccessRate.txt"] = "rodAutoSuccessRateTxt",
	["rightRod.value.waitTime"] = "rodValWaitTime",
	["rightRod.value.waitTime.name"] = "rodWaitTimeName",
	["rightRod.value.waitTime.txt"] = "rodWaitTimeTxt",
	["rightRod.get.btnBuy"] = {
		varname = "rodBtnBuy",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onRodBtnBuy")}
		},
	},
	["rightRod.get.btnUse"] = {
		varname = "rodBtnUse",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onBtnUse")}
		},
	},
	["rightRod.get.lockTip"] = "rodGetLock",
	["rightRod.get.lockTip.cost"] = "rodLockCost",
	["rightRod.get.costTip"] = "rodGetCost",
	["rightRod.get.costTip.cost"] = "rodCostCost",
	["rightRod.get.costTip.cost2"] = "rodCostCost2",
	["rightRod.get.costTip.icon"] = "rodCostIcon",
	["rightBait"] = "rightBait",
	["rightBait.specialGet"] = "baitSpecialGet",
	["rightBait.get.btnBuy"] = {
		varname = "baitBtnBuy",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onBaitBtnBuy")}
		},
	},
	["rightBait.get.btnUse"] = {
		varname = "baitBtnUse",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onBtnUse")}
		},
	},
	["rightBait.get.costTip"] = "baitGetCost",
	["rightBait.get.lockTip"] = "baitGetLock",
	["rightBait.get.lockTip.cost"] = "baitLockCost",
	["rightBait.get.costTip.cost"] = "baitCostCost",
	["rightBait.get.costTip.cost2"] = "baitCostCost2",
	["rightBait.get.costTip.icon"] = "baitCostIcon",
	["rightBait.value"] = "baitVal",
	["rightBait.value.lowerRange"] = "baitValLowerRange",
	["rightBait.value.lowerRange.name"] = "baitLowerRangeName",
	["rightBait.value.lowerRange.txt"] = "baitLowerRangeTxt",
	["rightBait.value.lowerWait"] = "baitValLowerWait",
	["rightBait.value.lowerWait.name"] = "baitLowerWaitName",
	["rightBait.value.lowerWait.txt"] = "baitLowerWaitTxt",
	["rightBait.value.autoSuccessRate"] = "baitValAutoSuccessRate",
	["rightBait.value.autoSuccessRate.name"] = "baitAutoSuccessRateName",
	["rightBait.value.autoSuccessRate.txt"] = "baitAutoSuccessRateTxt",
	["rightPartner"] = "rightPartner",
	["rightPartner"] = "rightPartner",
	["rightPartner.get.cost.need.need1"] = "partnerNeed1",
	["rightPartner.get.cost.need.need2"] = "partnerNeed2",
	["rightPartner.get.cost.need.txt"] = "partnerTxt",
	["rightPartner.get.cost"] = "partnerGetCost",
	["rightPartner.get.cost.cost.cost"] = "partnerCostCost",
	["rightPartner.get.cost.cost.cost2"] = "partnerCostCost2",
	["rightPartner.get.cost.cost.icon"] = "partnerCostIcon",
	["rightPartner.get.btnBuy"] = {
		varname = "partnerBtnBuy",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onPartnerBtnBuy")}
		},
	},
	["rightPartner.get.btnUse"] = {
		varname = "partnerBtnUse",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onBtnUse")}
		},
	},
}

function FishingBagView:onCreate(showTab, senceID)
	Dialog.onCreate(self)
	self:initModel()

	-- 选中标记创建
	self.selectEffect = ccui.ImageView:create("common/box/box_selected.png")
		:alignCenter(self.item:size())
		:retain()

	self.selectItemRefresh = true
	self.showTab = idler.new(showTab or 1)
	self.itemDatas = idlers.new({})
	self.selectItem = idler.new(1)
	idlereasy.any({self.fishLevel,self.items,self.showTab,self.partner,self.selectRod,self.selectBait,self.selectPartner},
		function(_, fishLevel,items,val,partner,selectRod,selectBait,selectPartner)
		-- 图标和简介
		local itemDatas = {}
		if val == 1 then
			for k,v in csvPairs(csv.fishing.rod) do
				itemDatas[k] = {
					csvID = k,
					id = v.itemId,
					name = v.name,
					desc = v.desc,
					extraSpeed = v.extraSpeed,
					lowerSpeed = v.lowerSpeed,
					extraZone = v.extraZone,
					extraProbability = v.extraProbability,
					lowerWait = v.lowerWait,
					needLv = v.needLv,
					cost = v.cost,
					typ = 1,
					isLock = items[v.itemId],
					fishLevel = fishLevel,
					isUse = selectRod == k,
				}
			end
		elseif val == 2 then
			for k,v in csvPairs(csv.fishing.bait) do
				local map = itertools.map(csv.fishing.bait[k].scene, function(_, v) return v, true end)
				if map[senceID] then
					table.insert(itemDatas, {
						csvID = k,
						id = v.itemId,
						name = v.name,
						desc = v.desc,
						cost = v.cost,
						lowerRandom = v.lowerRandom,
						lowerWait = v.lowerWait,
						extraProbability = v.extraProbability,
						needLv = v.needLv,
						typ = 2,
						isLock = items[v.itemId],
						fishLevel = fishLevel,
						isUse = selectBait == k,
					})
				end
			end
			table.sort(itemDatas, function(a,b)
				return a.csvID < b.csvID
			end)
		elseif val == 3 then
			for k,v in csvPairs(csv.fishing.partner) do
				itemDatas[k] = {
					csvID = k,
					id = v.unitId,
					name = v.name,
					desc = v.desc,
					cost = v.cost,
					needLv = v.needLv,
					typ = 3,
					isLock = partner[k],
					fishLevel = fishLevel,
					isUse = selectPartner == k,
				}
			end
		end
		if self.selectItemRefresh then
			self.selectItemRefresh = false
			local index = 1
			for k, data in pairs(itemDatas) do
				if data.isUse then
					index = k
					break
				end
			end
			self.selectItem:set(index)
		end
		local selectItem = self.selectItem:read()
		if itemDatas[selectItem] then
			itemDatas[selectItem].selectEffect = self.selectEffect
		end
		self.itemDatas:update(itemDatas)
		self.idx = val

		self.selectItem:notify()
	end)

	local btnDatas = {
		{txt = gLanguageCsv.rod, selected = false},
		{txt = gLanguageCsv.bait, selected = false},
		{txt = gLanguageCsv.partner, selected = false},
	}
	self.btnDatas = idlers.new(btnDatas)
	self.btnDatas:update(btnDatas)

	self.panel = {self.rightRod, self.rightBait, self.rightPartner}

	self.showTab:addListener(function(val, oldval, idler)
		self.btnDatas:atproxy(oldval).selected = false
		self.btnDatas:atproxy(val).selected = true
	end)

	self.selectItem:addListener(function(val, oldval)
		local oldData = self.itemDatas:atproxy(oldval)
		if val ~= oldval and oldData and oldData.selectEffect ~= nil then
			oldData.selectEffect = nil
		end
		local data = self.itemDatas:atproxy(val)
		if data then
			if val ~= oldval and data.selectEffect ~= self.selectEffect then
				data.selectEffect = self.selectEffect
			end
			self:resetShowPanel(data, self.idx)
		end
	end)
end

function FishingBagView:resetShowPanel(data, index)
	self.panel[1]:visible(index == 1)
	self.panel[2]:visible(index == 2)
	self.panel[3]:visible(index == 3)
	-- 图标
	bind.extend(self, self.panel[index], {
		class = "fishtools_icon",
		props = {
			data = {
				key = data.id,
				typ = data.typ,
			},
			onNode = function(node)
				node:align(cc.p(0.5, 0.5), self.panel[index]:get("icon"):x() - 35, self.panel[index]:get("icon"):y() - 35)
					:scale(1.3)
					:z(3)
			end,
		},
	})

	-- 名字
	self.panel[index]:get("name"):text(data.name)
	-- 描述list
	local desc = data.desc
	local cfg = csv.items[data.id]
	if index == 1 or index == 2 then
		desc = cfg.desc
	end
	beauty.textScroll({
		list = self.panel[index]:get("list"),
		strs = "#C0x5B545B#" .. desc,
		isRich = true,
		align = "center",
	})

	-- 鱼竿详情panel
	if index == 1 then
		-- 属性加成
		self.rodSpeTxt:text("+"..data.extraSpeed*100 .."%")
		self.rodValSpe:visible(data.extraSpeed ~= 0)
		adapt.oneLinePos(self.rodSpeName, self.rodSpeTxt, cc.p(30, 0), "left")

		self.rodUpSpeTxt:text("-"..data.lowerSpeed*100 .."%")
		self.rodValUpSpe:visible(data.lowerSpeed ~= 0)
		adapt.oneLinePos(self.rodUpSpeName, self.rodUpSpeTxt, cc.p(30, 0), "left")

		self.rodScaleUpTxt:text("+"..(data.extraZone - 1)*100 .."%")
		self.rodValScaleUp:visible(data.extraZone ~= 0)
		adapt.oneLinePos(self.rodScaleUpName, self.rodScaleUpTxt, cc.p(30, 0), "left")

		self.rodAutoSuccessRateTxt:text("+"..data.extraProbability*100 .."%")
		self.rodValAutoSuccessRate:visible(data.extraProbability ~= 0)
		adapt.oneLinePos(self.rodAutoSuccessRateName, self.rodAutoSuccessRateTxt, cc.p(30, 0), "left")

		self.rodWaitTimeTxt:text("-"..data.lowerWait*100 .."%")
		self.rodValWaitTime:visible(data.lowerWait ~= 0)
		adapt.oneLinePos(self.rodWaitTimeName, self.rodWaitTimeTxt, cc.p(30, 0), "left")

		local numShow = {}
		if data.extraSpeed ~= 0 then
			table.insert(numShow, "extraSpeed")
		end
		if data.lowerSpeed ~= 0 then
			table.insert(numShow, "lowerSpeed")
		end
		if data.extraZone ~= 0 then
			table.insert(numShow, "extraZone")
		end
		if data.extraProbability ~= 0 then
			table.insert(numShow, "extraProbability")
		end
		if data.lowerWait ~= 0 then
			table.insert(numShow, "lowerWait")
		end
		local tabLength = table.length(numShow)
		for i=1,tabLength do
			local pos = (5 - i)/2*90
			if numShow[i] == "extraSpeed" then
				self.rodValSpe:y(pos)
			elseif numShow[i] == "lowerSpeed" then
				self.rodValUpSpe:y(pos)
			elseif numShow[i] == "extraZone" then
				self.rodValScaleUp:y(pos)
			elseif numShow[i] == "extraProbability" then
				self.rodValAutoSuccessRate:y(pos)
			elseif numShow[i] == "lowerWait" then
				self.rodValWaitTime:y(pos)
			end
		end

		-- 需要等级
		local key, num = csvNext(data.cost)
		self.rodGetLock:visible(data.fishLevel < data.needLv)
		self.rodLockCost:text(string.format(gLanguageCsv.fishingLvNotEnough, data.needLv))
		self.rodBtnBuy:setTouchEnabled(data.fishLevel >= data.needLv)
		cache.setShader(self.rodBtnBuy, false, data.fishLevel >= data.needLv and "normal" or "hsl_gray")
		self.rodBtnUse:setTouchEnabled(data.fishLevel >= data.needLv)
		cache.setShader(self.rodBtnUse, false, data.fishLevel >= data.needLv and "normal" or "hsl_gray")

		local isLock = data.isLock
		self.rodBtnBuy:visible(isLock == nil)
		self.rodBtnUse:visible(isLock ~= nil)
		if isLock == nil then
			self.rodGetCost:visible(key ~= nil)
			self.rodSpecialGet:visible(key == nil)
			if key ~= nil then
				self.rodCostCost2:text(num)
				self.rodCostIcon:texture(dataEasy.getIconResByKey(key))
				adapt.oneLineCenterPos(cc.p(165, self.rodCostCost:y()), {self.rodCostCost, self.rodCostCost2, self.rodCostIcon}, cc.p(5, 0))
			else
				itertools.invoke({self.rodBtnBuy, self.rodBtnUse}, "hide")
			end
		else
			itertools.invoke({self.rodGetCost, self.rodSpecialGet}, "hide")
		end

	-- 鱼饵详情panel
	elseif index == 2 then
		-- 属性加成
		self.baitLowerRangeTxt:text("-"..data.lowerRandom*100 .."%")
		self.baitValLowerRange:visible(data.lowerRandom ~= 0)
		adapt.oneLinePos(self.baitLowerRangeName, self.baitLowerRangeTxt, cc.p(30, 0), "left")

		self.baitLowerWaitTxt:text("-"..data.lowerWait*100 .."%")
		self.baitValLowerWait:visible(data.lowerWait ~= 0)
		adapt.oneLinePos(self.baitLowerWaitName, self.baitLowerWaitTxt, cc.p(30, 0), "left")

		self.baitAutoSuccessRateTxt:text("+"..data.extraProbability*100 .."%")
		self.baitValAutoSuccessRate:visible(data.extraProbability ~= 0)
		adapt.oneLinePos(self.baitAutoSuccessRateName, self.baitAutoSuccessRateTxt, cc.p(30, 0), "left")

		local numShow = {}
		if data.lowerRandom ~= 0 then
			table.insert(numShow, "lowerRandom")
		end
		if data.lowerWait ~= 0 then
			table.insert(numShow, "lowerWait")
		end
		if data.extraProbability ~= 0 then
			table.insert(numShow, "extraProbability")
		end
		local tabLength = table.length(numShow)
		for i=1,tabLength do
			local pos = (3 - i)/2*90
			if numShow[i] == "lowerRandom" then
				self.baitValLowerRange:y(pos)
			elseif numShow[i] == "lowerWait" then
				self.baitValLowerWait:y(pos)
			elseif numShow[i] == "extraProbability" then
				self.baitValAutoSuccessRate:y(pos)
			end
		end

		-- 需要等级
		self.baitGetLock:visible(data.fishLevel < data.needLv)
		self.baitLockCost:text(string.format(gLanguageCsv.fishingLvNotEnough, data.needLv))
		self.baitBtnBuy:setTouchEnabled(data.fishLevel >= data.needLv)
		cache.setShader(self.baitBtnBuy, false, data.fishLevel >= data.needLv and "normal" or "hsl_gray")
		self.baitBtnUse:setTouchEnabled(data.fishLevel >= data.needLv)
		cache.setShader(self.baitBtnUse, false, data.fishLevel >= data.needLv and "normal" or "hsl_gray")

		local key, num = csvNext(data.cost)
		self.baitBtnBuy:visible(key ~= nil)
		self.baitBtnUse:visible(key ~= nil)
		self.baitGetCost:visible(key ~= nil)
		self.baitSpecialGet:visible(key == nil)
		self.baitGetLock:x(key == nil and 400 or 310)
		if key ~= nil then
			self.baitCostCost2:text(num)
			self.baitCostIcon:texture(dataEasy.getIconResByKey(key))
			adapt.oneLineCenterPos(cc.p(150, self.baitCostCost:y()), {self.baitCostCost, self.baitCostCost2, self.baitCostIcon}, cc.p(5, 0))
		end
		if data.isLock ~= nil and key == nil then
			self.baitBtnBuy:show()
			self.baitBtnUse:show()
			self.baitBtnBuy:setTouchEnabled(false)
			cache.setShader(self.baitBtnBuy, false, "hsl_gray")
		elseif data.isLock ~= nil then
			self.baitBtnUse:show()
			self.baitBtnUse:setTouchEnabled(true)
			cache.setShader(self.baitBtnUse, false, "normal")
		elseif data.isLock == nil and key == nil then
			self.baitBtnBuy:hide()
			self.baitBtnUse:hide()
		end

	-- 伙伴详情panel
	elseif index == 3 then
		-- 需要等级
		if data.fishLevel < data.needLv then
			text.addEffect(self.partnerTxt, {color = cc.c4b(183, 176, 158, 255)})
			text.addEffect(self.partnerNeed2, {color = cc.c4b(183, 176, 158, 255)})
		else
			text.addEffect(self.partnerTxt, {color = cc.c4b(91, 84, 91, 255)})
			text.addEffect(self.partnerNeed2, {color = cc.c4b(91, 84, 91, 255)})
		end
		local cfg = csv.unit[data.id]
		if self.pokedex:read()[cfg.cardID] == nil then
			text.addEffect(self.partnerNeed1, {color = cc.c4b(183, 176, 158, 255)})
		else
			text.addEffect(self.partnerNeed1, {color = cc.c4b(91, 84, 91, 255)})
		end
		self.partnerBtnBuy:setTouchEnabled(data.fishLevel >= data.needLv and self.pokedex:read()[cfg.cardID] ~= nil)
		cache.setShader(self.partnerBtnBuy, false, data.fishLevel >= data.needLv and self.pokedex:read()[cfg.cardID] ~= nil and "normal" or "hsl_gray")

		self.partnerTxt:text(data.needLv)
		adapt.oneLinePos(self.partnerNeed2, self.partnerTxt, cc.p(0, 0), "left")

		local key, num = csvNext(data.cost)
		self.partnerCostCost2:text(num)
		self.partnerCostIcon:texture(dataEasy.getIconResByKey(key))
		adapt.oneLineCenterPos(cc.p(175, self.partnerCostCost:y()), {self.partnerCostCost, self.partnerCostCost2, self.partnerCostIcon}, cc.p(5, 0))

		self.partnerBtnBuy:visible(data.isLock == nil)
		self.partnerBtnUse:visible(data.isLock ~= nil)
		self.partnerGetCost:visible(data.isLock == nil)
	end
end

-- 鱼竿购买
function FishingBagView:onRodBtnBuy()
	local data = self.itemDatas:atproxy(self.selectItem:read())
	local contentType = "num"
	if data.typ == 1 then
		contentType = nil
	end
	local costMap = {}
	local key, num = csvNext(data.cost)
	costMap[key] = num
	gGameUI:stackUI("common.buy_info", nil, nil,
		costMap,
		{id = data.id},
		{maxNum = nil, contentType = nil},
		self:createHandler("rodBuyInfo")
	)
end

-- 鱼竿购买服务器
function FishingBagView:rodBuyInfo(count)
	local data = self.itemDatas:atproxy(self.selectItem:read())
	local typ = "rod"
	gGameApp:requestServer("/game/fishing/item/unlock",function (tb)
		gGameUI:showTip(gLanguageCsv.hasBuy)
	end, typ, data.csvID)
end

-- 鱼饵购买
function FishingBagView:onBaitBtnBuy()
	local data = self.itemDatas:atproxy(self.selectItem:read())
	local costMap = {}
	local key, num = csvNext(data.cost)
	costMap[key] = num
	gGameUI:stackUI("common.buy_info", nil, nil,
		costMap,
		{id = data.id},
		{maxNum = nil, contentType = "num"},
		self:createHandler("baitBuyInfo")
	)
end

-- 鱼竿购买服务器
function FishingBagView:baitBuyInfo(count)
	local data = self.itemDatas:atproxy(self.selectItem:read())
	gGameApp:requestServer("/game/fishing/bait/buy",function (tb)
		gGameUI:showTip(gLanguageCsv.hasBuy)
	end, data.csvID, count)
end

-- 伙伴激活
function FishingBagView:onPartnerBtnBuy()
	local data = self.itemDatas:atproxy(self.selectItem:read())
	local key, num = csvNext(data.cost)
	if key == "rmb" and num > self.rmb:read() then
		uiEasy.showDialog("rmb")
	elseif key == "gold" and num > self.gold:read() then
		uiEasy.showDialog("gold")
	else
		local typ = "partner"
		local function cb()
			gGameApp:requestServer("/game/fishing/item/unlock",function (tb)
				gGameUI:showTip(gLanguageCsv.hasBuy)
			end, typ, data.csvID)
		end
		if key == "rmb" then
			dataEasy.sureUsingDiamonds(cb, num)
		else
			cb()
		end
	end
end

-- 渔具使用
function FishingBagView:onBtnUse()
	local itemType = {"rod", "bait", "partner"}
	local data = self.itemDatas:atproxy(self.selectItem:read())
	if data.isLock == nil then
		gGameUI:showTip(gLanguageCsv.noBaitCount)
		return
	end
	if (data.typ == 1 and self.selectRod:read() == data.csvID) or (data.typ == 2 and self.selectBait:read() == data.csvID) or (data.typ == 3 and self.selectPartner:read() == data.csvID) then
		gGameUI:showTip(gLanguageCsv.useSuccess)
	else
		if self.isAuto:read() == true then
			gGameUI:showTip(gLanguageCsv.switchToolsNeedStopAutoFishing)
		else
			gGameApp:requestServer("/game/fishing/prepare",function (tb)
				gGameUI:showTip(gLanguageCsv.useSuccess)
			end, itemType[data.typ], data.csvID)
		end
	end
end

-- 点击渔具页签
function FishingBagView:onSelectClick(list, index)
	-- 选择的渔具
	self.selectItemRefresh = true
	dataEasy.tryCallFunc(self.list, "setItemAction", {isAction = true})
	self.showTab:set(index)
end

-- 点击item
function FishingBagView:onItemClick(list, t, v)
	t.data = v
	-- 选择的item
	self.selectItem:set(t.k)
end

function FishingBagView:initModel()
	self.fishLevel = gGameModel.fishing:getIdler("level")
	self.partner = gGameModel.fishing:getIdler("partner")
	self.items = gGameModel.role:getIdler("items")
	self.selectRod = gGameModel.fishing:getIdler("select_rod")
	self.selectBait = gGameModel.fishing:getIdler("select_bait")
	self.selectPartner = gGameModel.fishing:getIdler("select_partner")
	self.pokedex = gGameModel.role:getIdler("pokedex")--卡牌
	self.rmb = gGameModel.role:getIdler("rmb")
	self.gold = gGameModel.role:getIdler("gold")
	self.isAuto = gGameModel.fishing:getIdler("is_auto")
end

return FishingBagView