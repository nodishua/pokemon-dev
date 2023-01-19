-- @desc: 卡牌特性强化

local ICON_BG = {
	[1]="city/card/ability/panel_jctx.png",
	[2]="city/card/ability/panel_pttx.png",
	[3]="city/card/ability/panel_hxtx.png"
}
local NAME_COLOR = {
	[1] = cc.c4b(97, 145, 192, 255),--基础6191c0
	[2] = cc.c4b(139, 92, 153, 255),--普通8b5c99
	[3] = cc.c4b(250, 105, 74, 255),--核心fa694a
}
--设置金币显示
local function setCostInfo(parent, myCoin, needCoin)
	local childs = parent:multiget("textNote", "textNum", "iconCoin")
	local coinColor = ui.COLORS.NORMAL.ALERT_ORANGE
	if myCoin >= needCoin then
		coinColor = ui.COLORS.NORMAL.DEFAULT
	end
	childs.textNum:text(needCoin)
	text.addEffect(childs.textNum, {color = coinColor})
	local size = parent:size()
	adapt.oneLineCenterPos(cc.p(size.width/2, size.height/2), {childs.textNote, childs.textNum, childs.iconCoin}, cc.p(15, 0))
end
--获取消耗的材料和金币
local function getCostDatas(abilities, abilityId, items)
	local abilityCsv = csv.card_ability[abilityId]
	local level = abilities[abilityCsv.position] or 0
	local costDatas = {}
	local gold = 0
	if level < abilityCsv.strengthMax then
		local costItemMap = csv.card_ability_cost[level+1]["costItemMap"..abilityCsv.strengthSeqID]
		gold = costItemMap.gold or 0
		for k,v in csvMapPairs(costItemMap) do
			if k ~= "gold" then
				table.insert(costDatas, {key = k, num = items[k] or 0, targetNum = v})
			end
		end
	end
	return costDatas, gold
end
--技能描述
local function getSkillStr(str, level, maxLevel)
	local list = string.split(str, "$")
	local desc = ""
	for i, v in pairs(list) do
		local s = v
		local pos = string.find(s, "skillLevel")
		if pos then
			local symbol = ""
			if list[i+1] and string.find(list[i+1],"^%%") then
				symbol = "%"
				list[i+1] = string.gsub(list[i+1],"^%%","")
			end
			local num = eval.doFormula(v, {skillLevel = level,math = math}, str)
			if level == 0 then
				num = 0
			end
			local nextNum = eval.doFormula(v, {skillLevel = level+1,math = math}, str)
			s = num..symbol
			local nextStr = (nextNum - num)..symbol
			if tonumber(num) < tonumber(nextNum) and level < maxLevel then
				s = string.format(gLanguageCsv.abilitySkillAddDesc, s, nextStr)
			end
			s = "#C0x60C456#+"..s.."#C0x5B545B#"
		end
		desc = desc .. s
	end
	return desc
end
--属性描述
local function getAddStr(nums, level, maxLevel, attrType, oneKeyLevel)
	local num = nums[level] or 0
	local nextNum = nums[oneKeyLevel] or 0
	local symbol = ""
	if string.find(num,"%%") then
		num = string.gsub(num,"%%","")
		symbol = "%"
	end
	if string.find(nextNum,"%%") then
		nextNum = string.gsub(nextNum,"%%","")
		symbol = "%"
	end
	local str = dataEasy.getAttrValueString(attrType, num..symbol)
	local nextStr = dataEasy.getAttrValueString(attrType, (nextNum - num)..symbol)
	if tonumber(num) < tonumber(nextNum) and level < maxLevel then
		str = string.format(gLanguageCsv.abilitySkillAddDesc, str, nextStr)
	end
	return "#C0x60C456#+" .. str .. "#C0x5B545B#"
end
--效果描述
local function setDesc(list, abilityCsv, level, oneKeyLevel)
	local desc = ""
	--effectType效果类型（1-属性;2-技能）
	local oneKeyLevel = oneKeyLevel or level + 1
	if abilityCsv.effectType == 2 then
		desc = string.format(abilityCsv.desc, getSkillStr(csv.skill[abilityCsv.skillID].describe, level, abilityCsv.strengthMax))
	end
	if abilityCsv.effectType == 1 then
		local params = {}
		for i=1,2 do
			local attrType = abilityCsv["attrType"..i]
			if attrType ~= 0 then
				table.insert(params, getLanguageAttr(attrType))
				table.insert(params, getAddStr(abilityCsv["attrNum"..i], level, abilityCsv.strengthMax, attrType, oneKeyLevel))
			end
		end
		desc = string.format(abilityCsv.desc, unpack(params))
	end
	beauty.textScroll({
		list = list,
		strs = "#C0x5B545B#" .. desc,
		isRich = true,
		verticalSpace = 10
	})
end

local ICON_SCALE = {
	[1] = 1.1,
	[2] = 1,
	[3] = 0.9
}
local abilityStrengthenTools = require "app.views.city.card.ability.tools"
local CardAbilityStrengthenView = class("CardAbilityStrengthenView", cc.load("mvc").ViewBase)

CardAbilityStrengthenView.RESOURCE_FILENAME = "card_ability_strengthen.json"
CardAbilityStrengthenView.RESOURCE_BINDING = {
	["panel.btnSure"] = {
		varname = "btnStrengthen",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onStrengthenClick")}
		},
	},
	["panel.btnSureOne"] = {
		varname = "btnStrengthenOneKey",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onStrengthenOneKeyClick")}
		},
	},
	-- ["panel.btnSureOne"] = "btnStrengthenOneKey",
	["panel.btnClose"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("cb")}
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
	["panel.descList"] = "descList",
	["panel.textLvNum"] = "textLvNum",
	["panel.textLvMaxNum"] = "textLvMaxNum",
	["panel.textNum"] = "textNum",
	["panel.iconArrow"] = "iconArrow",
	["panel.textNextNum"] = "textNextNum",
	["panel.textCondition1"] = "textCondition1",
	["panel.textCondition2"] = "textCondition2",
	["panel.costInfo"] = "costInfo",
	["panel.iconMax"] = "iconMax",
	["panel.imgMax"] = "imgMax",
	["panel"] = "panel",
	["item"] = "item",
}
function CardAbilityStrengthenView:onCreate(refreshData, cb)
	self.itemList:setClippingEnabled(false)
	self.refreshData = refreshData()
	self.cb = cb
	self:initModel()
	self.eventDatas = idlers.new()
	--用来控制从二级界面的回调
	self.oneKeyLevel = idler.new(0)
	-- strengthSeqID costItemMap1
	idlereasy.any({self.abilities, self.items, self.refreshData}, function(_, abilities, items)
		local abilityCsv = csv.card_ability[self.abilityId]
		if abilityCsv then
			local strengthMax = abilityCsv.strengthMax
			self.textName:text(abilityCsv.name)
			text.addEffect(self.textName, {color = NAME_COLOR[abilityCsv.type]})
			self.iconPanel:get("icon"):texture(abilityCsv.icon):scale(ICON_SCALE[abilityCsv.type] * 2)
			self.iconPanel:get("iconBg"):texture(ICON_BG[abilityCsv.type]):scale(ICON_SCALE[abilityCsv.type])
			local level = abilities[abilityCsv.position] or 0
			--当前等级
			self.textLvNum:text(level)
			self.level = level
			self.textLvMaxNum:text("/"..strengthMax)
			adapt.oneLinePos(self.textLvNum, self.textLvMaxNum, cc.p(3, 0), "left")
			--强化等级
			self.textNum:text(level == 0 and gLanguageCsv.notActivatedTip or "Lv"..level):setFontSize(level == 0 and 40 or 50)
			self.textNextNum:text("Lv"..math.min(level + 1, strengthMax))

			local isMax = level >= strengthMax
			itertools.invoke({self.iconMax, self.imgMax}, isMax and "show" or "hide")
			itertools.invoke({self.btnStrengthen, self.iconArrow, self.textNextNum}, not isMax and "show" or "hide")

			--前置条件
			local conditionStr = abilityStrengthenTools.getConditionStr(self.selectDbId, self.abilityId)
			for i=1,2 do
				if conditionStr[i] then
					self["textCondition"..i]:show():text(conditionStr[i])
				else
					self["textCondition"..i]:hide()
				end
			end
			local btnTitle = (level == 0) and gLanguageCsv.spaceActive or gLanguageCsv.spaceStrengthen
			self.btnStrengthen:get("textNote"):text(btnTitle)

			uiEasy.setBtnShader(self.btnStrengthen, self.btnStrengthen:get("textNote"), (#conditionStr == 0) and 1 or 3)
			uiEasy.setBtnShader(self.btnStrengthenOneKey, self.btnStrengthenOneKey:get("textNote"), (#conditionStr == 0) and 1 or 3)
			--消耗金币和材料的数据
			local costDatas, needCoin = getCostDatas(abilities, self.abilityId, items)
			self.eventDatas:update(costDatas)
			--材料居中
			if #costDatas == 1 or #costDatas == 2 then
				local itemWidth = self.item:size().width
				local offx = #costDatas * itemWidth + (#costDatas - 1) * 120
				self.itemList:x(953 - offx / 2)
			end
			--条件满足 显示金币消耗
			local showCostInfo = next(conditionStr) == nil and needCoin > 0
			self.costInfo:visible(showCostInfo)
			if showCostInfo then
				setCostInfo(self.costInfo, self.gold:read(), needCoin)
			end
			--描述跟随等级变化
			setDesc(self.descList, abilityCsv, level)

			if dataEasy.isUnlock(gUnlockCsv.potentialOneKey) and not isMax then
				self.btnStrengthen:x(673)
				self.btnStrengthenOneKey:show()
				self.btnStrengthenOneKey:x(1233)
				self.costInfo:x(673)
			else
				self.btnStrengthen:x(953)
				self.btnStrengthenOneKey:hide()
				self.costInfo:x(953)
			end
			self.oneKeyLevel:set(0)
		end
	end)
	idlereasy.when(self.oneKeyLevel, function(_, oneKeyLevel)
		if oneKeyLevel ~= 0 then
			local abilityCsv = csv.card_ability[self.abilityId]
			if abilityCsv then
				setDesc(self.descList, abilityCsv, self.level, oneKeyLevel)
				self.textNextNum:text(oneKeyLevel)
			end
			self:onStrengthenClick()
		end
	end)
end

function CardAbilityStrengthenView:initModel()
	self.gold = gGameModel.role:getIdler("gold")
	self.items = gGameModel.role:getIdler("items")
	idlereasy.when(self.refreshData,function (_, refreshData)
		self.selectDbId = refreshData.cardDbid
		self.abilityId = refreshData.id
		if assertInWindows(self.selectDbId, "val:%s", tostring(self.selectDbId)) then
			return
		end
		local card = gGameModel.cards:find(self.selectDbId)
		self.advance = idlereasy.assign(card:getIdler("advance"), self.advance)
		self.cardId = idlereasy.assign(card:getIdler("card_id"), self.cardId)
		self.cardLv = idlereasy.assign(card:getIdler("level"), self.cardLv)
		--card下的 abilities {posIdx: strengthLevel}
		self.abilities = idlereasy.assign(card:getIdler("abilities"), self.abilities)
	end)
end

--点击消耗物品
function CardAbilityStrengthenView:onCostItemClick(list, k, v)
	gGameUI:stackUI("common.gain_way", nil, nil, v.key, nil, v.targetNum)
end
--强化按钮
function CardAbilityStrengthenView:onStrengthenClick()
	local conditionStr = abilityStrengthenTools.getConditionStr(self.selectDbId, self.abilityId, true)
	if #conditionStr > 0 then
		gGameUI:showTip(gLanguageCsv.activeSlotNotEnough)
		return
	end
	local costDatas, needCoin = getCostDatas(self.abilities:read(), self.abilityId, self.items:read())
	for k,v in pairs(costDatas) do
		if v.num < v.targetNum then
			gGameUI:showTip(gLanguageCsv.materialsNotEnough)
			return
		end
	end
	if self.gold:read() < needCoin then
		gGameUI:showTip(gLanguageCsv.goldNotEnough)
		return
	end

	local abilities = self.abilities:read()
	local cfg = csv.card_ability[self.abilityId]
	local showOver = {false}
	local upLevel = self.oneKeyLevel:read() == 0 and 1 or self.oneKeyLevel:read() - self.level
	gGameApp:requestServerCustom("/game/card/ability/strength")
		:params(self.selectDbId, cfg.position, upLevel)
		:onResponse(function (tb)
			local str = abilities[cfg.position] == 1 and gLanguageCsv.activeSuccess or gLanguageCsv.strengthenSuccess
			gGameUI:showTip(str)
			abilityStrengthenTools.setEffect({
				parent = self.panel:get("pos"),
				spinePath = "effect/texing_saoguang.skel",
				effectName = "effect"
			})
			showOver[1] = true
		end)
		:wait(showOver)
		:doit()
end

function CardAbilityStrengthenView:onStrengthenOneKeyClick()
	local conditionStr = abilityStrengthenTools.getConditionStr(self.selectDbId, self.abilityId, true)
	if #conditionStr > 0 then
		gGameUI:showTip(gLanguageCsv.activeSlotNotEnough)
		return
	end
	local costDatas, needCoin = getCostDatas(self.abilities:read(), self.abilityId, self.items:read())
	for k,v in pairs(costDatas) do
		if v.num < v.targetNum then
			gGameUI:showTip(gLanguageCsv.materialsNotEnough)
			return
		end
	end
	-- gGameUI:stackUI("city.card.ability.strengthen_onekey", nil, {clickClose = true, blackLayer = true}, self:createHandler("sendParams"))
	gGameUI:stackUI("city.card.ability.strengthen_onekey", nil, {clickClose = true, blackLayer = true}, {refreshData = self.refreshData:read(), oneKeyLevel = self.oneKeyLevel})
end

function CardAbilityStrengthenView:sendParams()
	return self.refreshData, self.oneKeyLevel
end

return CardAbilityStrengthenView