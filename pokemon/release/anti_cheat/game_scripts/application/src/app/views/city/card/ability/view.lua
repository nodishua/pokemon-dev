-- @desc: 卡牌特性

local ICON_BG = {
	[1] = "city/card/ability/panel_jctx.png",
	[2] = "city/card/ability/panel_pttx.png",
	[3] = "city/card/ability/panel_hxtx.png"
}
local ICON_SCALE = {
	[1] = 0.82,
	[2] = 0.9,
	[3] = 1
}
--特性强化消耗品
local COST_ITEMID = {850, 851}
local abilityStrengthenTools = require "app.views.city.card.ability.tools"
local CardAbilityView = class("CardAbilityView", cc.load("mvc").ViewBase)

CardAbilityView.RESOURCE_FILENAME = "card_ability.json"
CardAbilityView.RESOURCE_BINDING = {
	["strengthenPanel"] = "strengthenPanel",
	["closePanel"] = {
		varname = "closePanel",
		binds = {
			event = "click",
			method = bindHelper.self("onClosePanel")
		},
	},
	["panel.costInfo1.btnAdd"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.defer(function(view)
				return view:onDetailClick(1)
			end)}
		},
	},
	["panel.costInfo2.btnAdd"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.defer(function(view)
				return view:onDetailClick(2)
			end)}
		},
	},
	["abilityPanel"] = "abilityPanel",
	["panel"] = "panel",
	["item"] = "item",
	["barBg"] = "barBg",
	["bar"] = "bar",
	["bar1"] = "bar1",
}
function CardAbilityView:onCreate(dbHandler)
	self.selectDbId = dbHandler()
	self:initModel()
	self.selectPos = idler.new(0)
	--创建图案
	idlereasy.when(self.cardId, function(_, cardId)
		self.abilityPanel:removeAllChildren()
		local csvCards = csv.cards[self.cardId:read()]
		--特性索引ID
		local cfg = gCardAbilityCsv[csvCards.abilitySeqID]
		--底图资源
		local size = self.abilityPanel:size()
		local baseSrc = ""
		for i = 1, table.maxn(cfg) do
			local v = cfg[i]
			if v then
				baseSrc = v.baseSrc
				local item = self.item:clone():show()
					:xy(size.width/2 + v.pos.x, size.height/2 + v.pos.y)
					:name("item"..i)
					:addTo(self.abilityPanel, 20 - i)

				bind.touch(self, item, {
					longtouch = 0.2,
					scaletype = 0,
					method = function(list, node, event)
						self:onItemClick(event, node, i, v)
					end
				})
				item:get("select"):scale(ICON_SCALE[v.type])
				item:get("icon"):texture(v.icon):scale(ICON_SCALE[v.type] * 2)
				item:get("iconBg"):texture(ICON_BG[v.type])
				item:get("textLv"):scale(ICON_SCALE[v.type] + 0.1)
				item:get("lvBg"):scale(ICON_SCALE[v.type] + 0.1)
				--连线
				for _, prePos in orderCsvPairs(v.preAbilityID) do
					self:setAngleByPos(item, v.id, prePos, false)
				end
			end
		end
		self.panel:get("imgBG"):texture(baseSrc)
		self.abilities:notify()
	end)
	--刷新特性等级, self.advance, self.cardLv
	idlereasy.when(self.abilities, function(_, abilities)
		local csvCards = csv.cards[self.cardId:read()]
		--特性索引ID
		local cfg = gCardAbilityCsv[csvCards.abilitySeqID]
		for i = 1, table.maxn(cfg) do
			local v = cfg[i]
			if v then
				local item = self.abilityPanel:get("item"..i)
				if item then
					item:get("select"):visible(self.selectPos:read() == i)
					local level = abilities[i] or 0
					if v.iconGray == "" then
						cache.setShader(item:get("icon"), false, (level == 0) and "hsl_gray_white" or "normal")
					else
						item:get("icon"):texture((level == 0) and v.iconGray or v.icon)
					end
					cache.setShader(item:get("iconBg"), false, level == 0 and "hsl_gray_white" or "normal")
					item:get("textLv"):text(level.."/"..v.strengthMax)

					if not self.oldLv[i] then
						self.oldLv[i] = {}
					end
					--连线
					for k,prePos in orderCsvPairs(v.preAbilityID) do
						local preLv = abilities[prePos] or 0
						--播放激活动画
						local isActive = false
						if self.oldLv[i][prePos] == 0 and preLv == 1 then
							isActive = true
						end
						self:setAngleByPos(item, v.id, prePos, isActive)
						self.oldLv[i][prePos] = preLv
					end
				end
			end
		end
	end)
	--刷新可激活特效
	idlereasy.any({self.abilities, self.advance, self.cardLv}, function(_, abilities)
		local csvCards = csv.cards[self.cardId:read()]
		--特性索引ID
		local cfg = gCardAbilityCsv[csvCards.abilitySeqID]
		for i = 1, table.maxn(cfg) do
			local v = cfg[i]
			if v then
				local item = self.abilityPanel:get("item"..i)
				if item then
					local level = abilities[i] or 0
					--可激活（前置条件满足，不包括金币和材料）
					local conditionStr = abilityStrengthenTools.getConditionStr(self.selectDbId:read(), v.id)
					if #conditionStr == 0 and level == 0 then
						abilityStrengthenTools.setEffect({
							parent = item,
							spinePath = "figure/touxiang.json",
							effectName = "effect_shiyongzhong_loop",
							scale = (ICON_SCALE[v.type]) - 0.3,
							zOrder = 9
						})
					else
						local effect = item:get("effect")
						if effect then
							effect:hide()
						end
					end
				end
			end
		end
	end)
	self.selectPos:addListener(function(val, oldval)
		local oldItem = self.abilityPanel:get("item"..oldval)
		if oldItem then
			oldItem:get("select"):hide()
		end
		local selectItem = self.abilityPanel:get("item"..val)
		if selectItem then
			selectItem:get("select"):show()
			abilityStrengthenTools.setEffect({
				parent = selectItem:get("select"),
				spinePath = "figure/touxiang.json",
				effectName = "effect_xuanzhong",
				scale = selectItem:get("select"):scale()
			})
		end
	end)
	idlereasy.when(self.items, function(_, items)
		for i,id in pairs(COST_ITEMID) do
			local childs = self.panel:get("costInfo"..i):multiget("textCostNum", "imgIcon")
			local icon = csv.items[id].icon
			childs.textCostNum:text(mathEasy.getShortNumber(items[id] or 0, 2))
			childs.imgIcon:texture(icon):scale(1.12)
		end
	end)

	self.refreshData = idlertable.new({cardDbid = self.selectDbId:read(), id = 0})
	self.strengthen = nil
	self.strengthen = gGameUI:createView("city.card.ability.strengthen", self.strengthenPanel):init(
		self:createHandler("refreshData"),
		self:createHandler("onClosePanel")
	)
	self:onClosePanel()
end

function CardAbilityView:initModel()
	self.gold = gGameModel.role:getIdler("gold")
	self.items = gGameModel.role:getIdler("items")
	idlereasy.when(self.selectDbId,function (_, selectDbId)
		self.oldLv = {}
		if assertInWindows(selectDbId, "val:%s", tostring(selectDbId)) then
			return
		end
		local card = gGameModel.cards:find(selectDbId)
		self.cardId = idlereasy.assign(card:getIdler("card_id"), self.cardId)
		--card下的 abilities {posIdx: strengthLevel}
		self.abilities = idlereasy.assign(card:getIdler("abilities"), self.abilities)
		self.advance = idlereasy.assign(card:getIdler("advance"), self.advance)
		self.cardLv = idlereasy.assign(card:getIdler("level"), self.cardLv)
	end)
end
--设置连线的位置夹角
function CardAbilityView:setAngleByPos(item, nowID, prePos, isActive)
	local nowCsv = csv.card_ability[nowID]
	local preCsv = csv.card_ability[gCardAbilityCsv[nowCsv.abilitySeqID][prePos].id]
	local x = preCsv.pos.x-nowCsv.pos.x
	local y = preCsv.pos.y-nowCsv.pos.y
	local preLv = self.abilities:read()[prePos] or 0
	--距离
	local s = math.sqrt(math.pow(x,2)+math.pow(y,2))
	--角度
	local r = math.atan2(x,y)*180/math.pi
	r = r > 0 and r - 270 or r + 90
	local barBg = item:get("barBg"..prePos)
	local height = self.barBg:size().height
	if not barBg then
		barBg = self.barBg:clone():show()
			:xy(100 + x/2, 100 + y/2)
			:name("barBg"..prePos)
			:setRotation(r)
			:size(s,height)
			:addTo(item, 1)
	end
	local bar = item:get("bar"..prePos)
	if not bar then
		bar = self.bar:clone():show()
			:setCapInsets(cc.rect(36, 0, 1, 1))
			:xy(100 + x/2, 100 + y/2)
			:name("bar"..prePos)
			:setRotation(r)
			:size(s,height)
			:addTo(item, 2)
	end
	local precent = (preLv == 0 or isActive) and 20 or 100
	if bar:getPercent() == 20 or bar:getPercent() == 100 then
		bar:setPercent(precent)
	end
	if isActive then
		transition.executeParallel(item:get("bar"..prePos))
			:progressTo(0.8, 100)
	end
end
--显示强化面板
function CardAbilityView:onItemClick(event, item, i, v)
	self.selectPos:set(i, true)
	self.strengthenPanel:show()
	self.closePanel:show()
	self.refreshData:set({cardDbid = self.selectDbId:read(), id = v.id})
end
function CardAbilityView:onDetailClick(index)
	gGameUI:stackUI("common.gain_way", nil, nil, COST_ITEMID[index])
end
--隐藏强化面板
function CardAbilityView:onClosePanel()
	self.strengthenPanel:hide()
	self.closePanel:hide()
	self.selectPos:set(0)
end
return CardAbilityView