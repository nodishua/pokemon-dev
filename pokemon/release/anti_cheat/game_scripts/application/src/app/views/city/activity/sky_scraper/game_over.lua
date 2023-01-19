--摩天高楼游戏结束
local ViewBase = cc.load("mvc").ViewBase
local SkyScraperGameOver = class("SkyScraperGameOver", ViewBase)

SkyScraperGameOver.RESOURCE_FILENAME = "sky_scraper_game_over.json"
SkyScraperGameOver.RESOURCE_BINDING = {
	["bkg"] = {
		binds = {
			event = "click",
			method = bindHelper.self("onPanelClick"),
		},
	},
	["bkg.exitText"] = "exitText",
	["pjText"] = "pjText",
	["awardBg"] = "awardBg",
	["awardBg.awardText"] = "scoreText",
	["awardBg.awardNewImg"] = "awardNewImg",
	["awardBg.awardNewText"] = "awardNewText",
	["imgOver"] = "imgOver",
	["awardText"] = "awardText",
	["item"] = "item",
	["awardList"] = "awardList",
	-------------------------------barPanel--------------------------------
	["barPanel"] = "barPanel",
	["barPanel.bar"] = {
		varname = "progressBar",
		binds = {
		  event = "extend",
		  class = "loadingbar",
		  props = {
			data = bindHelper.self("curPagePro"),
		  },
		}
	},
	["barPanel.maxText"] = "maxText",
	["barPanel.curImg"] = "curImg",
}

function SkyScraperGameOver:onCreate(closeCb, activityId, score, floor, showNew, size, tb)
	self.closeCb = closeCb
	self.activityId = activityId
	self.floor = floor
	self:initModel()
	audio.playEffectWithWeekBGM("pve_win.mp3")
	local award = tb.view.result or {}
	self.showdata:update(award)
	uiEasy.createItemsToList(self, self.awardList, award, {
		onAfterBuild = function()
			self.awardList:setItemAlignCenter()
		end,
	})
	self.curImg:get("txt"):text(floor)
	self.pjText:text(string.format(gLanguageCsv.skyScraperGameOverScore, floor))
	self.awardText:text(string.format(gLanguageCsv.skyScraperGameOverAward, size))

	self.scoreText:setString(score)
	self.awardNewImg:setVisible(showNew)
	self.awardNewText:setVisible(showNew)
end


function SkyScraperGameOver:initModel()
-- 进度条进度
	self.curPagePro = idler.new(0)
	self.showdata = idlers.newWithMap({})
  	local yycfg = csv.yunying.yyhuodong[self.activityId]
	local paramMap = yycfg.paramMap or {}
	local maxFloor = paramMap.maxFloor
	self.maxText:text(maxFloor)
	self.curPagePro:set(self.floor / maxFloor * 100)
	self.curImg:x(self.curImg:x() + self.floor / maxFloor * 830)
	--封顶大吉
	if self.floor == maxFloor then
		local textEffect = widget.addAnimation(self.imgOver, "level/newzhandoushengli.skel", "effect4", 100)
		textEffect:anchorPoint(cc.p(0.5,0.5))
			:xy(290, -410)
			:addPlay("effect4_loop")
		self.curImg:get("txt"):visible(false)
	else
		local textEffect = widget.addAnimation(self.imgOver, "level/newzhandoushengli.skel", "effect3", 100)
		textEffect:anchorPoint(cc.p(0.5,0.5))
			:xy(290, -410)
			:addPlay("effect3_loop")
	end
end

function SkyScraperGameOver:onPanelClick()
	self.closeCb()
end

return SkyScraperGameOver

