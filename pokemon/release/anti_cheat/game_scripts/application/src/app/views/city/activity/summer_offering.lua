-- @date 2021-07-09
-- @desc 夏日祭整合入口

local BaseActivityView = require "app.views.city.activity.anniversary"
local ActivitySummerOfferingView = class("ActivitySummerOfferingView", BaseActivityView)

local YY_TYPE = game.YYHUODONG_TYPE_ENUM_TABLE

ActivitySummerOfferingView.RESOURCE_FILENAME = "activity_summer_offering.json"
ActivitySummerOfferingView.RESOURCE_BINDING = {
	["bg"]  = "bg",
	["beachIce"]  = "shavedIce",
	["volleyball"] ="volleyball",
	["shop"] = "shop",
	["summerChallenge"] = "summerChallenge",
	["countdown"] = {
		varname = "countdown",
		binds = {
			{
				event = "effect",
				data = {outline = {color = cc.c4b(91, 84, 91, 255), size = 4}}
			},
		}
	},
}

function ActivitySummerOfferingView:onCreate(params)
	self:createTitle()
	self:enableSchedule()
	self.isRunning = false
	self:createTable()
	for _, v in ipairs(params) do
		local cfg = csv.yunying.yyhuodong[v.id]
		if self.tb[cfg.type] then
			self.tb[cfg.type].data = v
		end
	end
	self:refreshPanel()
end

function ActivitySummerOfferingView:createTitle()
	local topUI = gGameUI.topuiManager:createView("default", self, {onClose = self:createHandler("onClose")})
		:init({title = gLanguageCsv.summerActivity, subTitle = "SUMMER"})
end

function ActivitySummerOfferingView:bindClick(node, data, isOver)
	bind.touch(self, node, {methods = {ended = function()
		if data then
			if isOver then
				gGameUI:showTip(gLanguageCsv.activityOver)
			else
				self:onItemClick(data)
			end
		else
			gGameUI:showTip(gLanguageCsv.huodongNoOpen)
		end
	end}})
end

function ActivitySummerOfferingView:createTable()
	local summerChallengeRedHintPos = matchLanguage({"kr"}) and cc.p(295, 95) or cc.p(280, 95)

	self.tb = {
		[YY_TYPE.shavedIce] = {
			node = self.shavedIce,
			redHintPos = cc.p(250, 95),
		},
		[YY_TYPE.summerChallenge] = {
			node = self.summerChallenge,
			redHintPos = summerChallengeRedHintPos,
		},
		[YY_TYPE.volleyball] = {
			node = self.volleyball,
			redHintPos = cc.p(255, 98),
		},
		[YY_TYPE.itemBuy2] = {
			node = self.shop,
			redHintPos = cc.p(280, 100),
		},
	}
end
return ActivitySummerOfferingView