-- @date 2021-03-10
-- @desc 走格子-道具卡使用二次确认界面
local gridWalkTools = require "app.views.city.activity.grid_walk.tools"
local ViewBase = cc.load("mvc").ViewBase
local ConfirmationUseCard = class("ConfirmationUseCard", ViewBase)
ConfirmationUseCard.RESOURCE_FILENAME = "grid_walk_use_card.json"
ConfirmationUseCard.RESOURCE_BINDING = {
	["btnYes"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onYesClick")}
		},
	},
	["btnNo"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")},
		},
	},
	["txt"] = {
		varname = "txt",
		binds = {
			event = "effect",
			data = {outline = {color = cc.c3b(209, 52, 55), size = 6}},
		},
	},
	["cardPos"] = "cardPos",
}

function ConfirmationUseCard:onCreate(params)
	self.callBack = params.callBack
	local card = params.card
	local itemID = params.itemID
	local cfg = csv.items[itemID]
	local desc = cfg.desc
	if itemID == gridWalkTools.ITEMS.steeringCard then
		desc = string.format(gLanguageCsv.gridWalkSteerTips, params.steps)
	end
	self.txt:text(desc)
	local card = card:clone()
		:anchorPoint(0.5, 0.5)
		:xy(0, 0)
		:scale(1.5)
		:addTo(self.cardPos)
	card:get("txt"):hide()
end

function ConfirmationUseCard:onYesClick()
	self:addCallbackOnExit(self.callBack)
	self:onClose()
end

return ConfirmationUseCard
