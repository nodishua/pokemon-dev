--
-- @desc 鱼类图标
--
local helper = require "easy.bind.helper"

local fishIcon = class("fishIcon", cc.load("mvc").ViewBase)

fishIcon.defaultProps = {
	data = nil,
	onNode = nil,
	onNodeClick = nil,
	-- bool or idler
	lock = nil,
}


function fishIcon:initExtend()
	self:initModel()
	if self.panel then
		self.panel:removeFromParent()
	end
	local panel = ccui.Layout:create()
		:size(145, 145)
		:addTo(self, 1, "_equip_")

	self.panel = panel

	--品级
	local panelSize = panel:size()
	local imgBG = ccui.ImageView:create()
		:align(cc.p(0.5, 0.5), 90, 90)
		:addTo(panel, 1)
	--图标
	local icon = ccui.ImageView:create()
		:align(cc.p(0.5, 0.5), 90, 90)
		:scale(2)
		:addTo(panel, 2, "icon")
	--数量
	local num = panel:get("num")
	if not num then
		num = cc.Label:createWithTTF("", ui.FONT_PATH, 40)
			:align(cc.p(1, 0), 160, 8)
			:addTo(panel, 2, "num")
	end

	helper.callOrWhen(self.data, function (data)
		local cfg = csv.fishing.fish[data.key]
		imgBG:texture(ui.QUALITY_BOX[cfg.rare + 2])
		icon:texture(cfg.icon)
		if not data.num then
			panel:get("num"):hide()
		else
			panel:get("num"):text(data.num)
			text.addEffect(panel:get("num"), {outline={color=ui.COLORS.QUALITY_OUTLINE[cfg.rare + 2]}})
		end
		self:setLock(panel, cfg)

		if self.onNodeClick then
			panel:setTouchEnabled(true)
			bind.click(self, panel, {method = function()
				local params = {key = data.key, num = data.num, dbId = data.dbId}
				gGameUI:showFishDetail(panel, params)
			end})
		end
	end)

	if self.onNode then
		self.onNode(panel)
	end

	return self
end


function fishIcon:setLock(panel, cfg)
	if self.lock ~= nil then
		idlereasy.when(self.fishLevel, function(_, fishLevel)
			if fishLevel < cfg.needLv then
				local size = panel:size()
				ccui.ImageView:create("common/box/box_mask2.png")
					:align(cc.p(0.5, 0.5), 90, 90)
					:addTo(panel, 4, "lock")
				ccui.ImageView:create("common/btn/btn_bs.png")
					:align(cc.p(0.5, 0.5), 90, 90)
					:addTo(panel, 5, "lock")
				helper.callOrWhen(self.lock, function(lock)
					local panel = self.panel
					panel:get("lock"):visible(lock)
				end)
			end
		end)
	end
end

function fishIcon:initModel()
	self.fishLevel = gGameModel.fishing:getIdler("level")
end

return fishIcon