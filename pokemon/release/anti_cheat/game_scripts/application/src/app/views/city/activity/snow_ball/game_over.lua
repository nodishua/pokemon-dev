--躲雪球游戏结束
local SnowballGameOver = class("SnowballGameOver", cc.load("mvc").ViewBase)

SnowballGameOver.RESOURCE_FILENAME = "snow_ball_game_over.json"
SnowballGameOver.RESOURCE_BINDING = {
	["bkg"] = {
		binds = {
			event = "click",
			method = bindHelper.self("onPanelClick"),
		},
	},
	["bkg.exitText"] = "exitText",
	["awardBg"] = "awardBg",
	["awardBg.awardText"] = "awardText",
	["awardBg.awardNewImg"] = "awardNewImg",
	["awardBg.awardNewText"] = "awardNewText",
}

function SnowballGameOver:onCreate(parent,score, showNew, guide)
	self.parent = parent
	audio.playEffectWithWeekBGM("pve_win.mp3")
	local pnode = self:getResourceNode()

	local textEffect = widget.addAnimation(pnode, "level/newzhandoushengli.skel", "effect3", 100)
	textEffect:anchorPoint(cc.p(0.5,0.5))
		:xy(pnode:get("title"):getPosition())
		:addPlay("effect3_loop")

	self.awardText:setString(score)
	if guide == 0 then
		self.awardNewImg:setVisible(false)
		self.awardNewText:text(gLanguageCsv.snowBallGuideTips)
			:show()
	else
		self.awardNewImg:setVisible(showNew)
		self.awardNewText:setVisible(showNew)
	end
end


function SnowballGameOver:onPanelClick()
	self.parent:onClose()
end

return SnowballGameOver

