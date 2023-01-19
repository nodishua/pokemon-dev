--
-- @desc 通用设置道具项
--
local helper = require "easy.bind.helper"

local equipIcon = class("equipIcon", cc.load("mvc").ViewBase)

equipIcon.defaultProps = {
	-- {level, star, equip_id, advance} or idlertable
	-- level: 等级
	-- star: 星级
	-- equip_id: id
	-- advance:阶数
	-- ability:潜能等级
	data = nil,
	selected = false,
	onNode = nil,
	onNodeClick = nil
}


function equipIcon:initExtend()
	if self.panel then
		self.panel:removeFromParent()
	end
	local panelSize = cc.size(198, 198)
	local panel = ccui.Layout:create()
		:size(198, 198)
		:addTo(self, 1, "_equip_")
	local imgBG = ccui.ImageView:create(ui.QUALITY_BOX[1])
		:alignCenter(panelSize)
		:addTo(panel, 1)
	local imgSel = ccui.ImageView:create("common/box/box_selected.png")
		:alignCenter(panelSize)
		:visible(self.selected)
		:addTo(panel, -1, "imgSel")
	local imgArrow = ccui.ImageView:create("common/icon/icon_up.png")
		:alignCenter(panelSize)
		:xy(150, 150)
		:visible(true)
		:addTo(panel, 5, "imgArrow")

	self.panel = panel

	local size = panel:size()
	--品级
	local frameNode = ccui.ImageView:create()
		-- :alignCenter(size)
		:xy(30, 99)
		:addTo(panel, 3, "frame")
	local icon = ccui.ImageView:create()
		:alignCenter(panelSize)
		:scale(2)
		:addTo(panel, 2, "icon")


	local labelLv = panel:get("txtLv")
	if not labelLv then
		labelLv = cc.Label:createWithTTF("Lv", ui.FONT_PATH, 24)
			:align(cc.p(1, 0), 40, 30)
			:addTo(panel, 2, "txtLv")

		text.addEffect(labelLv, {outline={color=ui.COLORS.OUTLINE.DEFAULT}})
	end

	local txtLvNum = panel:get("txtLvNum")
	if not txtLvNum then
		txtLvNum = cc.Label:createWithTTF("", ui.FONT_PATH, 30)
			:align(cc.p(1, 0), 90, 30)
			:addTo(panel, 2, "txtLvNum")

		text.addEffect(txtLvNum, {outline={color=ui.COLORS.OUTLINE.DEFAULT}})
	end

	helper.callOrWhen(self.data, function (data)
		local panel = self.panel
		local cfg = csv.equips[data.equip_id]
		local quality = dataEasy.getQuality(data.advance)
		local boxRes = ui.QUALITY_BOX[quality]
		local frameRes = ui.QUALITY_FRAME[quality]
		imgBG:texture(boxRes)
		icon:texture(data.awake ~= 0 and cfg.icon2 or cfg.icon)
		panel:get("txtLvNum"):text(data.level)
		adapt.oneLinePos(labelLv, txtLvNum, cc.p(0, 0), "left")
		if data.ability and data.ability > 0 then
			self:setAbility(panel, data.ability)
		else
			self:setStar(panel, data.star)
		end
		if data.awake_ability and data.awake_ability > 0 then
			self:setAwakeAbilityInfo(panel, data.awake_ability)
		else
			self:setAwakeInfo(panel, data.awake)
		end
	end)
	if self.onNode then
		self.onNode(panel)
	end
	if self.onNodeClick then
		panel:setTouchEnabled(true)
		bind.touch(self, panel, {methods = {ended = function()
			self.onNodeClick(panel)
		end}})
	end
	return self
end

function equipIcon:setStar(panel, star)
	local size = panel:size()
	ccui.Layout:create()
		:size(size.width, 70)
		:align(cc.p(0, 0), 0, 0)
		:addTo(panel, 4, "star")
	panel:get("star"):removeAllChildren()
	for i=1,star do
		ccui.ImageView:create("city/card/equip/icon_star.png")
			:xy(99 - 12 * (star + 1 - 2 * i), 25)
			:addTo(panel:get("star"), 4, "star")
			:scale(0.8)
	end
end

function equipIcon:setAbility(panel, ability)
	local size = panel:size()
	local x = ability >= 10 and 116 or 108
	ccui.Layout:create()
		:size(size.width, 70)
		:align(cc.p(0, 0), 0, 0)
		:addTo(panel, 4, "star")
	panel:get("star"):removeAllChildren()
	ccui.ImageView:create("city/card/equip/icon_xx_d.png")
		:xy(100,25)
		:addTo(panel:get("star"), 4, "starbg")
		:scale(0.8)
	local abilityNum = cc.Label:createWithTTF(ability, "font/youmi1.ttf", 30)
		:align(cc.p(1, 0), x, 5)
		:addTo(panel:get("star"), 4, "starnum")
	text.addEffect(abilityNum, {outline = {color = cc.c3b(179,68,48),size = 2}})
end

function equipIcon:setAwakeInfo(panel, awakeLv)
	if awakeLv <= 0 then
		panel:removeChildByName("_awakeInfo")
		return
	end
	local size = panel:size()
	local awakePanel = panel:getChildByName("_awakeInfo")
	if not awakePanel then
		awakePanel = ccui.Layout:create()
			:size(128, 48)
			:anchorPoint(0.5, 0.5)
			:xy(50, size.height - 18)
			:addTo(panel, 6, "_awakeInfo")
		ccui.ImageView:create("city/card/equip/logo_jxbs.png")
			:xy(80, 24)
			:addTo(awakePanel, 1)

		cc.Label:createWithTTF(str, "font/youmi1.ttf", 34)
			:color(cc.c4b(252, 249, 203, 255))
			:xy(80, 24)
			:addTo(awakePanel, 2, "_awakeStr")
	end

	local label = awakePanel:getChildByName("_awakeStr")
	label:text(string.format(gLanguageCsv.awakeLevel, gLanguageCsv["symbolRome" .. awakeLv] or ""))
end

function equipIcon:setAwakeAbilityInfo(panel, awakeAbilityLv)
	if awakeAbilityLv <= 0 then
		panel:removeChildByName("_awakeAbilityInfo")
		return
	end
	local size = panel:size()
	local awakeAbilityPanel = panel:getChildByName("_awakeAbilityInfo")
	if not awakeAbilityPanel then
		awakeAbilityPanel = ccui.Layout:create()
			:size(128, 48)
			:anchorPoint(0.5, 0.5)
			:xy(50, size.height - 18)
			:addTo(panel, 6, "_awakeAbilityInfo")
		local vertical = ccui.Scale9Sprite:create()
		vertical:initWithFile(cc.rect(36, 24, 1, 1), "city/card/equip/box_spjx_d.png")
		vertical:size(150,50)
			:anchorPoint(0.5, 0.5)
			:xy(90,24)
			:addTo(awakeAbilityPanel)


		cc.Label:createWithTTF(str, "font/youmi1.ttf", 34)
			:color(cc.c4b(252, 249, 203, 255))
			:xy(85, 24)
			:addTo(awakeAbilityPanel, 2, "_awakeAbilityStr")
	end

	local label = awakeAbilityPanel:getChildByName("_awakeAbilityStr")
	label:text(gLanguageCsv.awake.." +"..awakeAbilityLv)
	text.addEffect(label, {outline = {color = cc.c4b(188,70,49,255), size = 2}})
end

return equipIcon