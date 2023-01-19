--
-- 芯片面板
--

local EFFECT_LINE_NAME = {
	[2] = "effect_xian_lv",
	[3] = "effect_xian_lan",
	[4] = "effect_xian_zi",
	[5] = "effect_xian_huang",
	[6] = "effect_xian_hong",
}

local ChipTools = require('app.views.city.card.chip.tools')
local helper = require "easy.bind.helper"

local chipsPanel = class("chipsPanel", cc.load("mvc").ViewBase)

local input = {}
input.RESOURCE_FILENAME = "chips_panel.json"
input.RESOURCE_BINDING = {
	["panel"] = "panel",
	["panel1"] = "panel1",
	["panel2"] = "panel2",
}

chipsPanel.defaultProps = {
	data = nil, -- cardDBID or {[1] = chipDBID1, [3] = chipDBID2, ...}
	panelIdx = nil, -- 默认 panel
	selected = nil, -- 选中特效
	slotFlags = nil, -- 格子可选标记组
	showSuitEffect = false, -- 默认套装激活后显示套装激活效果
	onItem = nil,
	noListener = nil,
	noIdlerListener = nil, -- 可设置无监听组件，只作为初始化显示
	onNode = nil,
}

function chipsPanel:getValue(v)
	if not self.noIdlerListener then
		return v
	end
	if isIdler(v) then
		return v:read()
	end
	return v
end

function chipsPanel:initExtend()
	local node = gGameUI:createSimpleView(input, self):init()
	node:getResourceNode():alignCenter(self:size())
	self.panelIdx = self.panelIdx or ""
	for _, name in ipairs({"panel", "panel1", "panel2"}) do
		local panelName = "panel" .. self.panelIdx
		if panelName == name then
			self.nodePanel = node[name]
		else
			node[name]:removeFromParent()
		end
	end
	self.nodePanel:show()

	self.originShowSuitEffect = self.showSuitEffect
	self.data_ = {}
	self.cardChips = idlereasy.new({})
	helper.callOrWhen(self.data, function(data)
		self.resetData_ = true
		if type(data) == "table" then
			self.cardChips:set(data, true)
		else
			local card = gGameModel.cards:find(data)
			self.cardChips = idlereasy.assign(card:getIdler("chip"), self.cardChips)
		end
	end)

	helper.callOrWhen(self:getValue(self.cardChips), function(cardChips)
		for _, v in pairs(self.data_) do
			v:destroy()
		end
		self.data_ = {}
		self.chipData_ = {}
		for i = 1, 6 do
			local dbId = cardChips[i]
			if dbId then
				local chip = gGameModel.chips:find(dbId)
				local chipId = chip:read('chip_id')
				self.chipData_[i] = {
					dbId = dbId,
					chipId = chipId,
					cfg = csv.chip.chips[chipId],
				}
				if not self.noIdlerListener then
					self.data_[dbId] = idlereasy.when(chip:getIdler('level'), function(_, level)
						self:onItem_(i, dbId)
					end, true):anonyOnly(self, tostring(self) .. stringz.bintohex(dbId))
				end
			end
			self:onItem_(i, dbId)
		end
		self:calcSuitAttr()
	end)

	helper.callOrWhen(self.selected, function(selected)
		for i = 1, 6 do
			local item = self:getItem(i)
			local itemSelected = item:get("selected")
			if itemSelected then
				local itemSelectedEffect = item:get("selectedEffect")
				if not itemSelectedEffect then
					itemSelectedEffect = widget.addAnimation(item, "chip/xzk.skel", "effect_loop", 100)
						:scale(itemSelected:scale())
						:xy(itemSelected:xy())
						:rotate(60 * (i - 1))
				end
				itemSelectedEffect:visible(i == selected)
				item:z(i == selected and 9 or 5)
			end
		end
	end)
	helper.callOrWhen(self.slotFlags, function(slotFlags)
		for i = 1, 6 do
			local item = self:getItem(i)
			local itemSelected = item:get("selected")
			if itemSelected then
				itemSelected:visible(slotFlags[i] == true)
			end
		end
	end)

	if self.onNode then
		self:onNode(self.nodePanel)
	end

	return self
end

-- 套装变动时显示新增的套装激活效果
function chipsPanel:calcSuitAttr()
	local cardChips = table.deepcopy(self.cardChips:read(), true)
	local suitAttr = ChipTools.getSuitAttrByCard(cardChips)
	if self.resetData_ or not self.showSuitEffect then
		self.resetData_ = false
		self.suitAttr_ = suitAttr
		self.cardChips_ = cardChips
		return
	end
	local flags = {}
	for idx = 1, 6 do
		if cardChips[idx] and cardChips[idx] ~= self.cardChips_[idx] then
			flags[idx] = 1
		end
	end
	local newSuitActive = false
	for suitID, data in pairs(suitAttr) do
		for i = #data, 1, -1 do
			local flag = self.suitAttr_[suitID] and self.suitAttr_[suitID][i] and self.suitAttr_[suitID][i][3]
			-- 之前已激活更高的套装，现在没有更高的
			if flag == true then
				break
			end
			if data[i][3] == true then
				newSuitActive = true
				local count = 0
				for idx = 1, 6 do
					-- 激活过的对应栏位标记为激活的套装数
					if self.chipData_[idx] and self.chipData_[idx].cfg.suitID == suitID and self.chipData_[idx].cfg.quality >= data[i][2] then
						count = count + 1
						flags[idx] = data[i][1]
						if count >= data[i][1] then
							break
						end
					end
				end
			end
		end
	end
	for idx, count in pairs(flags) do
		local effectName = "effect_chacao" .. (count == 1 and "" or tostring(count))
		local item = self:getItem(idx)
		local effect = item:get("effect_chacao")
		if not effect then
			effect = widget.addAnimationByKey(item, "chip/fushi.skel", "effect_chacao", effectName, 100)
				:scale(2)
				:rotate(60 * idx)
				:xy(item:width()/2, item:height()/2)
		end
		effect:play(effectName)
	end
	if newSuitActive then
		local suitImg = self:get("suitImg_")
		if not suitImg then
			suitImg = cc.Sprite:create("city/card/chip/txt_tzjh.png")
				:xy(400, 300)
				:addTo(self, 100, "suitImg_")
		end
		suitImg:stopAllActions()
		suitImg:scale(0)
		suitImg:opacity(255)
		transition.executeSequence(suitImg)
			:easeBegin("ELASTICOUT", 0.7)
				:scaleTo(0.5, 1)
			:easeEnd()
			:delay(0.5)
			:fadeOut(0.5)
			:done()
	end
	self.suitAttr_ = suitAttr
	self.cardChips_ = cardChips
end

function chipsPanel:getItem(k)
	return self.nodePanel:get("chip" .. k)
end

function chipsPanel:onItem_(k, dbId)
	local item = self:getItem(k)
	if self.noListener then
		item:setTouchEnabled(false)
	end
	local scale = item:get("bg"):scale()
	local effect = item:get("effect_line")
	if not effect then
		local pos = item:get("bg"):convertToWorldSpace(cc.p(96, 55))
		pos = item:convertToNodeSpace(pos)
		effect = widget.addAnimationByKey(item, "chip/fushi.skel", "effect_line", "effect_xian_di_loop", -2)
			:scale(2 * scale)
			:rotate(60 * (k - 2))
			:xy(pos)
	end
	local defaultLv = item:get("defaultLv")
	if defaultLv then
		defaultLv:removeFromParent()
	end

	local cardChips = self.cardChips:read()
	if dbId then
		local chip = gGameModel.chips:find(dbId)
		local chipData = chip:read("chip_id", "card_db_id", "level")
		local cfg = csv.chip.chips[chipData.chip_id]
		local quality = cfg.quality
		item:get("bg"):show():texture(string.format("city/card/chip/img_d_%d.png", quality))
		bind.extend(self, item, {
			class = "icon_key",
			props = {
				data = {
					key = chipData.chip_id,
					dbId = chipData.card_db_id,
				},
				noListener = true,
				simpleShow = true,
				onNode = function(panel)
					local res = cfg.icon
					res = string.gsub(res, "/chip/icon_", "/chip/img/img_")
					panel:get("icon"):texture(res)
					panel:name("box"):show():scale(scale)
					panel:setTouchEnabled(false)
				end,
			},
		})
		local lv = cc.Label:createWithTTF("Lv." .. chipData.level, ui.FONT_PATH, 30 - math.floor(10*(1-scale)))
			:align(cc.p(0.5, 0), item:width()/2, item:height()/10)
			:addTo(item, 6, "defaultLv")
		text.addEffect(lv, {color=ui.COLORS.NORMAL.WHITE,outline={color=ui.COLORS.NORMAL.DEFAULT,size=3}})

		local effectName = EFFECT_LINE_NAME[self.chipData_[k].cfg.quality]
		effect:show()
		if self.resetData_ or not self.showSuitEffect or cardChips[k] == self.cardChips_[k] then
			effect:play(effectName .. "_loop")
		else
			effect:play(effectName)
			effect:addPlay(effectName .. "_loop")
		end
	else
		item:get("bg"):hide()
		if item:get("box") then
			item:get("box"):hide()
		end
		effect:play("effect_xian_di_loop")
	end
	if self.onItem then
		self:onItem(item, k, dbId)
	end
end

function chipsPanel:pauseSuitEffect()
	self.showSuitEffect = false
end

function chipsPanel:resumeSuitEffect()
	self.showSuitEffect = self.originShowSuitEffect
end


return chipsPanel