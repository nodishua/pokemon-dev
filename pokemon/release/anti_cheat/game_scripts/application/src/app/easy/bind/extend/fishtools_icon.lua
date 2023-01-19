--
-- @desc 鱼竿鱼饵图标
--

local helper = require "easy.bind.helper"

local fishToolsIcon = class("fishToolsIcon", cc.load("mvc").ViewBase)

fishToolsIcon.defaultProps = {
	data = nil,
	onNode = nil,
	-- bool or idler
	lock = nil,
	num = nil,
	noListener = nil,
}


function fishToolsIcon:initExtend()
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
		:align(cc.p(0.5, 0.5), 100, 100)
		:addTo(panel, 1)
	--图标
	local icon = ccui.ImageView:create()
		:align(cc.p(0.5, 0.5), 100, 100)
		:scale(2)
		:addTo(panel, 2, "icon")
	--数量
	local num = panel:get("num")
	if not num then
		num = cc.Label:createWithTTF("", ui.FONT_PATH, 40)
			:align(cc.p(1, 0), 170, 20)
			:addTo(panel, 2, "num")

		text.addEffect(num, {outline={color=ui.COLORS.OUTLINE.DEFAULT}})
	end

	helper.callOrWhen(self.data, function (data)
		if data.typ == 1 then
			local cfg = csv.items[data.key]
			imgBG:texture(ui.QUALITY_BOX[cfg.quality])
			icon:texture(cfg.icon)
		elseif data.typ == 2 then
			local cfg = csv.items[data.key]
			imgBG:texture(ui.QUALITY_BOX[cfg.quality])
			icon:texture(cfg.icon)
		elseif data.typ == 3 then
			--背景
			local imgBG = ccui.ImageView:create("common/box/box_portrait.png")
				:align(cc.p(0.5, 0.5), 100, 100)
				:scale(1.2)
				:addTo(panel, 1)
			--图标
			local cfg = csv.unit[data.key]
			local icon = ccui.ImageView:create(cfg.icon)
				:align(cc.p(0.5, 0.5), 100, 100)
				:scale(1.8)
				:addTo(panel, 2, "icon")
		end

		if self.lock then
			if data.typ == 1 or data.typ == 2 then
				idlereasy.when(self.fishLevel, function(_, fishLevel)
					if fishLevel < data.needLv then
						self:setLock(panel,data.typ)
					end
				end):anonyOnly(self, "lock")
			elseif data.typ == 3 then
				if data.lock == nil then
					self:setLock(panel,data.typ)
				end
			end
		end

		--数量
		local num = panel:get("num")
		if not num then
			num = cc.Label:createWithTTF("", ui.FONT_PATH, 40)
				:align(cc.p(1, 0), 170, 10)
				:addTo(panel, 2, "num")
		end

		if self.num and data.typ == 2 then
			if data.lock ~= nil then
				num:text(data.lock)
			else
				num:text(0)
			end
			local cfg = csv.items[data.key]
			text.addEffect(num, {outline={color=ui.COLORS.QUALITY_OUTLINE[cfg.quality]}})
		end

		if not self.noListener then
			bind.click(self, panel, {method = function()
			end})
		end
	end)

	if self.onNode then
		self.onNode(panel)
	end

	return self
end

function fishToolsIcon:setLock(panel,typ)
	local size = panel:size()
	local mask = "common/box/box_mask2.png"
	local scale = 1
	if typ == 3 then
		mask = "common/box/mask_portrait.png"
		scale = 1.2
	end
	ccui.ImageView:create(mask)
		:align(cc.p(0.5, 0.5), 100, 100)
		:scale(scale)
		:addTo(panel, 4, "lock")
	ccui.ImageView:create("common/btn/btn_bs.png")
		:align(cc.p(0.5, 0.5), 100, 100)
		:addTo(panel, 5, "lock")
	helper.callOrWhen(self.lock, function(lock)
		local panel = self.panel
		panel:get("lock"):visible(lock)
	end)
end

function fishToolsIcon:initModel()
	self.fishLevel = gGameModel.fishing:getIdler("level")
end

return fishToolsIcon