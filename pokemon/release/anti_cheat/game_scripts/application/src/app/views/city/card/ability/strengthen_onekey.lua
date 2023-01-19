-- @desc: 一键卡牌强化

local NAME_COLOR = {
	[1] = cc.c4b(97, 145, 192, 255),--基础6191c0
	[2] = cc.c4b(139, 92, 153, 255),--普通8b5c99
	[3] = cc.c4b(250, 105, 74, 255),--核心fa694a
}

local ICON_SCALE = {
	[1] = 1.1,
	[2] = 1,
	[3] = 0.9
}

local ICON_BG = {
	[1]="city/card/ability/panel_jctx.png",
	[2]="city/card/ability/panel_pttx.png",
	[3]="city/card/ability/panel_hxtx.png"
}

--获取消耗的材料和金币
local function getCostDatas(abilities, abilityId, items, num)
	local abilityCsv = csv.card_ability[abilityId]
	local level = abilities[abilityCsv.position] or 0
	local costDatas = {}
	local gold = 0
	local tmp = level
	-- if level < abilityCsv.strengthMax then
	-- 	local costItemMap = csv.card_ability_cost[level+1]["costItemMap"..abilityCsv.strengthSeqID]
	-- 	gold = costItemMap.gold or 0
	-- 	for k,v in csvMapPairs(costItemMap) do
	-- 		if k ~= "gold" then
	-- 			table.insert(costDatas, {key = k, num = items[k] or 0, targetNum = v})
	-- 		end
	-- 	end
	-- end
	for i = level, num - 1 do
		if level < abilityCsv.strengthMax then
			local costItemMap = csv.card_ability_cost[i+1]["costItemMap"..abilityCsv.strengthSeqID]
			gold = costItemMap.gold and gold + costItemMap.gold or gold + 0
			tmp = tmp + 1
			for k,v in csvMapPairs(costItemMap) do
				if k ~= "gold" then
					local isSame = false
					for _, val in ipairs(costDatas) do
						if val.key == k then
							val.targetNum = val.targetNum + v
							isSame = true
						end
						if val.num < val.targetNum then
							return costDatas, gold, tmp - 1
						end
					end
					if isSame == false then
						table.insert(costDatas, {key = k, num = items[k] or 0, targetNum = v})
					end
					-- if v.num < v.targetNum then
					-- 	return costDatas, gold, tmp
					-- end
				end
			end
		end
	end
	return costDatas, gold
end

local abilityStrengthenTools = require "app.views.city.card.ability.tools"

local ViewBase = cc.load("mvc").ViewBase
local CardAbilityStrengthenOneKeyView = class("CardAbilityStrengthenOneKeyView", ViewBase)



CardAbilityStrengthenOneKeyView.RESOURCE_FILENAME = "card_ability_strengthen_onekey.json"
CardAbilityStrengthenOneKeyView.RESOURCE_BINDING = {
	["panel.btnSure"] = {
		varname = "btnStrengthen",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onStrengthenClick")}
		},
	},
	["title.btnClose"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")}
		},
	},
	["item"] = "item",
	["panel.itemList"] = {
		varname = "itemList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("eventDatas"),
				item = bindHelper.self("item"),
				onItem = function(list, node, k, v)
					local grayState = v.num < v.targetNum and 1 or 0
					local childs = node:multiget("itemPanel", "textName")
					local binds = {
						class = "icon_key",
						props = {
							data = {
							key = v.key,
								num = v.num,
								targetNum = v.targetNum
							},
							grayState = grayState,
							onNode = function (panel)
								panel:setTouchEnabled(false)
							end,
						},
					}
					bind.extend(list, childs.itemPanel, binds)
					node:get("mask"):visible(v.num < v.targetNum)
					bind.touch(list, node, {methods = {ended = functools.partial(list.itemClick, k, v)}})
				end,
			},
			handlers = {
				itemClick = bindHelper.self("onCostItemClick"),
			},
		},
	},
	["panel.iconPanel"] = "iconPanel",
	["panel.textName"] = "textName",
	["panel.textLvNum"] = "textLvNum",
	["panel.textLvMaxNum"] = "textLvMaxNum",
	["panel.textNote1"] = "textNote1",
	["panel.textNum"] = "textNum",
	["panel.icon"] = "icon",
	["panel.numPanel"] = "numPanel",
	["panel"] = "panel",
	["panel.numPanel.subBtn"] = {
		varname = "numSubBtn",
		binds = {
			event = "touch",
			longtouch = true,
			method = bindHelper.defer(function(view, node, event)
				return view:onChangeNum(node, event, -1)
			end),
		},
	},
	["panel.numPanel.addBtn"] = {
		varname = "numAddBtn",
		binds = {
			event = "touch",
			longtouch = true,
			method = bindHelper.defer(function(view, node, event)
				return view:onChangeNum(node, event, 1)
			end),
		},
	},
}
function CardAbilityStrengthenOneKeyView:onCreate(params)
	self:enableSchedule()
	self.itemList:setClippingEnabled(false)
	-- self.refreshData, self.oneKeyLevel = params()
	self.refreshData = params.refreshData
	self.oneKeyLevel = params.oneKeyLevel
	self:initModel()
	self.eventDatas = idlers.new()
	local abilityCsv = csv.card_ability[self.abilityId]

	if abilityCsv then
		local strengthMax = abilityCsv.strengthMax
		self.textName:text(abilityCsv.name)
		text.addEffect(self.textName, {color = NAME_COLOR[abilityCsv.type]})
		self.iconPanel:get("icon"):texture(abilityCsv.icon):scale(ICON_SCALE[abilityCsv.type] * 2)
		self.iconPanel:get("iconBg"):texture(ICON_BG[abilityCsv.type]):scale(ICON_SCALE[abilityCsv.type])
		local level = self.abilities:read()[abilityCsv.position] or 0
		--当前等级
		self.level = level + 1
		self.textLvNum:text(level)
		self.textLvMaxNum:text("/"..strengthMax)
		local _, _, materialMax = getCostDatas(self.abilities:read(), self.abilityId, self.items:read(), strengthMax)
		self.maxNum = materialMax or 20
		adapt.oneLinePos(self.textLvNum, self.textLvMaxNum, cc.p(3, 0), "left")
		self.num = idler.new(self.maxNum)
		--前置条件
		local conditionStr = abilityStrengthenTools.getConditionStr(self.selectDbId, self.abilityId)

		uiEasy.setBtnShader(self.btnStrengthen, self.btnStrengthen:get("textNote"), (#conditionStr == 0) and 1 or 3)
	end
	idlereasy.any({self.abilities, self.items, self.num, self.gold}, function(_, abilities, items, num, gold)
		self.numPanel:get("num"):text(num)
		local abilityCsv = csv.card_ability[self.abilityId]
		self.numSubBtn:setTouchEnabled(num > self.level)
		self.numAddBtn:setTouchEnabled(num < self.maxNum)
		cache.setShader(self.numSubBtn, false, num > self.level and "normal" or "hsl_gray")
		cache.setShader(self.numAddBtn, false, num < self.maxNum and "normal" or "hsl_gray")
		if abilityCsv then
			--消耗金币和材料的数据
			local costDatas, needCoin= getCostDatas(abilities, self.abilityId, items, num)
			self.textNum:text(needCoin)
			local color = gold < needCoin and ui.COLORS.NORMAL.RED or ui.COLORS.NORMAL.DEFAULT
			text.addEffect(self.textNum, {color=color})
			adapt.oneLineCenterPos(cc.p(1710, 835), {self.textNote1, self.textNum, self.icon}, cc.p(15, 0))
			self.eventDatas:update(costDatas)
			--材料居中
			if #costDatas == 1 or #costDatas == 2 then
				local itemWidth = self.item:size().width
				local offx = #costDatas * itemWidth + (#costDatas - 1) * 120
				self.itemList:x(self.btnStrengthen:x() - offx / 2)
			end
		end
	end)
end

function CardAbilityStrengthenOneKeyView:initModel()
	self.gold = gGameModel.role:getIdler("gold")
	self.items = gGameModel.role:getIdler("items")
	self.selectDbId = self.refreshData.cardDbid
	self.abilityId = self.refreshData.id
	if assertInWindows(self.selectDbId, "val:%s", tostring(self.selectDbId)) then
		return
	end
	local card = gGameModel.cards:find(self.selectDbId)
	self.advance = idlereasy.assign(card:getIdler("advance"), self.advance)
	self.cardId = idlereasy.assign(card:getIdler("card_id"), self.cardId)
	self.cardLv = idlereasy.assign(card:getIdler("level"), self.cardLv)
	--card下的 abilities {posIdx: strengthLevel}
	self.abilities = idlereasy.assign(card:getIdler("abilities"), self.abilities)
end

--点击消耗物品
function CardAbilityStrengthenOneKeyView:onCostItemClick(list, k, v)
	gGameUI:stackUI("common.gain_way", nil, nil, v.key, nil, v.targetNum)
end
--强化按钮
function CardAbilityStrengthenOneKeyView:onStrengthenClick()
	local conditionStr = abilityStrengthenTools.getConditionStr(self.selectDbId, self.abilityId, true)
	if #conditionStr > 0 then
		gGameUI:showTip(gLanguageCsv.activeSlotNotEnough)
		return
	end
	local costDatas, needCoin = getCostDatas(self.abilities:read(), self.abilityId, self.items:read(), self.num:read())
	for k,v in pairs(costDatas) do
		if v.num < v.targetNum then
			gGameUI:showTip(gLanguageCsv.materialsNotEnough)
			return
		end
	end
	if self.gold:read() < needCoin then
		uiEasy.showDialog("gold", nil, {dialog = true})
		return
	end

	-- local abilities = self.abilities:read()
	-- local cfg = csv.card_ability[self.abilityId]
	-- local showOver = {false}
	-- gGameApp:requestServerCustom("/game/card/ability/strength")
	-- 	:params(self.selectDbId, cfg.position)
	-- 	:onResponse(function (tb)

	-- 	end)
	-- 	:wait(showOver)
	-- 	:doit()
	self.oneKeyLevel:set(self.num:read())
	self:onClose()
end

function CardAbilityStrengthenOneKeyView:onIncreaseNum(step)
	self.num:modify(function(num)
		-- 特殊体验处理，如果数量为1，加10，则为加到10
		return true, cc.clampf(num + step, self.level, math.max(self.maxNum, 1))

	end)
end

function CardAbilityStrengthenOneKeyView:onChangeNum(node, event, step)
	if event.name == "click" then
		self:unScheduleAll()
		self:onIncreaseNum(step)

	elseif event.name == "began" then
		self:schedule(function()
			self:onIncreaseNum(step)
		end, 0.05, 0, 1)


	elseif event.name == "ended" or event.name == "cancelled" then
		self:unScheduleAll()
	end
end

return CardAbilityStrengthenOneKeyView