--
-- @desc 通用设置道具项
--
local helper = require "easy.bind.helper"

local stageIcon = class("stageIcon", cc.load("mvc").ViewBase)
stageIcon.defaultProps = {
	rank = nil,
	showStageBg = false,
	showStage = true,
	showRank = false,
	onNode = nil,
	onNodeClick = nil
}

function stageIcon:initExtend()
	if self.panel then
		self.panel:removeFromParent()
	end
	local panelSize = cc.size(198, 198)
	local panel = ccui.Layout:create()
		:size(198, 198)
		:alignCenter(self:size())
		:addTo(self, 1, "_stage_")
	self.panel = panel

	helper.callOrWhen(self.rank, function(rank)
		local stageData = dataEasy.getCrossArenaStageByRank(rank)
		--icon
		local imgIcon = ccui.ImageView:create(stageData.icon)
			:xy(panelSize.width/2, 118)
			:scale(2)
			:addTo(panel, 1, "icon")
		--titleBg
		if self.showStageBg then
			ccui.ImageView:create("city/pvp/cross_arena/dzqb_bg_dw.png")
				:xy(panelSize.width / 2, 50)
				:addTo(panel, 5, "titleImgBg")
				:scale(194/146)
		end
		--title
		if self.showStage then
			local stageName = self.showRank == false and stageData.stageName or stageData.stageName..stageData.rank
			local title = label.create(stageName, {fontPath = "font/youmi1.ttf", fontSize = 30, color = ui.COLORS.NORMAL.WHITE})
				:x(panelSize.width / 2)
				:y(self.showStageBg == true and 50 or 19)
				:setHorizontalAlignment(cc.TEXT_ALIGNMENT_CENTER)
				:addTo(panel, 6, "title")
			local color = self.showStageBg == true and ui.COLORS.NORMAL.WHITE or ui.COLORS.NORMAL.BLACK
			text.addEffect(title, {color = color})

			if self.showRank == true then
				text.addEffect(title, {outline = {color= cc.c4b(216, 90, 104, 255), size = 3}})
				title:setBMFontSize(32)
				title:y(52)
			end
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
return stageIcon