-- 人物头像绑定
local helper = require "easy.bind.helper"

local roleLogo = class("roleLogo", cc.load("mvc").ViewBase)

roleLogo.defaultProps = {
	-- number:头像id, false: 不显示 or idler
	logoId = nil,
	-- number:头像框id, false: 不显示 or idler
	frameId = nil,
	-- number, false: 不显示 or idler
	level = nil,
	-- number, false or 0: 不显示 or idler
	vip = nil,
	-- vip 结点外部自定义
	onNode = nil,
	-- 点击头像回调
	onNodeClick = nil,
	isGray = false,
}

function roleLogo:showLogo(logoImg)
	local size = self.panel:size()
	if self.logoId == nil then
		errorInWindows("role_logo logoId is nil")
		self.logoId = gGameModel.role:getIdler("logo")
	end

	local mask = cc.Sprite:create("common/box/box_head_d.png")
		:alignCenter(size)
	local logoClipping = cc.ClippingNode:create(mask)
		:setAlphaThreshold(0.1)
		:size(size)
		:alignCenter(size)
		:addTo(self.panel, 3, "logoClipping")

	helper.callOrWhen(self.logoId, function(logoId)
		logoClipping:removeAllChildren()
		if logoId then
			local res = dataEasy.getRoleLogoIcon(logoId)
			local logo = ccui.ImageView:create(res)
				:alignCenter(size)
				:scale(2)
				:addTo(logoClipping, 3, "logo")

			cache.setShader(logo, false, self.isGray and "hsl_gray" or "normal")
		end
	end)
end

function roleLogo:showFrame()
	local size = self.panel:size()
	local frameImg = ccui.ImageView:create()
		:alignCenter(size)
		:addTo(self.panel, 4, "frame")
	if self.frameId == nil then
		errorInWindows("role_logo frameId is nil")
		self.frameId = gGameModel.role:getIdler("frame")
	end
	helper.callOrWhen(self.frameId, function(frameId)
		self.panel:removeChildByName("frameSpine")
		cache.setShader(frameImg, false, self.isGray and "hsl_gray" or "normal")
		if frameId == false then
			frameImg:hide()
		else
			local frameRes = dataEasy.getRoleFrameIcon(frameId)
			local isSpine = string.find(frameRes, ".skel")
			if isSpine then
				frameImg:hide()
				local frameSpine = widget.addAnimationByKey(self.panel, frameRes, "frameSpine", "effect_loop", 4)
					:alignCenter(size)

				cache.setShader(frameSpine, false, self.isGray and "hsl_gray" or "normal")
				if self.isGray then
					frameSpine:setTimeScale(0)
				end
			else
				frameImg:texture(frameRes):show()
			end
		end
	end)
	return frameImg
end

function roleLogo:showLevel()
	local size = self.panel:size()
	local levelImg = ccui.Scale9Sprite:create()
	levelImg:initWithFile(cc.rect(25, 23, 1, 1), "common/box/box_djd.png")
	levelImg:size(cc.size(72, 46))
		:align(cc.p(0.5, 0.5), 15, size.height - 5)
		:addTo(self.panel, 5, "levelImg")
	local txtLevel = label.create(0, {fontSize = 40, color = ui.COLORS.NORMAL.WHITE})
		:xy(15, size.height - 5)
		:setHorizontalAlignment(cc.TEXT_ALIGNMENT_CENTER)
		:addTo(self.panel, 6, "level")
	helper.callOrWhen(self.level, function(level)
		if level == false then
			levelImg:hide()
			txtLevel:hide()
		else
			levelImg:show()
			txtLevel:text(level):show()
		end
	end)
	return levelImg
end

function roleLogo:showVip()
	local size = self.panel:size()
	local vipImg = ccui.ImageView:create()
		:align(cc.p(0.5, 0.5), size.width / 2, -size.height * 0.1)
		:addTo(self.panel, 7, "vip")
	if self.vip == nil then
		local vipHide = gGameModel.role:read("vip_hide")
		if not vipHide then
			errorInWindows("role_logo vip is nil")
		end
		self.vip = vipHide and 0 or gGameModel.role:getIdler("vip_level")
	end
	vipImg:hide()
	helper.callOrWhen(self.vip, function(vip)
		if vip == false or vip <= 0 then
			vipImg:hide()
		else
			vipImg:texture(ui.VIP_ICON[vip]):show()
		end
	end)
	return vipImg

end

function roleLogo:initExtend()
	local logoImg = ccui.ImageView:create(dataEasy.getRoleLogoIcon(1)):scale(2)
	local bottomImg = ccui.ImageView:create("common/box/box_head_d.png")
	local size = logoImg:box()
	self:removeChildByName("_roleLogo_")
	local panel = ccui.Layout:create()
		:size(size)
		:alignCenter(self:size())
		:addTo(self, 1, "_roleLogo_")
	bottomImg:alignCenter(size)
		:addTo(panel, 2, "bottom")

	self.panel = panel
	self:showLogo(logoImg)
	self:showFrame()
	self:showLevel()
	self:showVip()

	if self.onNode then
		self.onNode(panel)
	end
	if self.onNodeClick then
		panel:setTouchEnabled(true)
		bind.touch(self, panel, {methods = {ended = function(view, node, event)
			self.onNodeClick(event)
		end}})
	end
	return self
end

return roleLogo
