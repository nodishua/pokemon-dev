
local ViewBase = cc.load("mvc").ViewBase
local CardSkillBuyPointView = class("CardSkillBuyPointView", Dialog)

CardSkillBuyPointView.RESOURCE_FILENAME = "card_skill_buypoint.json"
CardSkillBuyPointView.RESOURCE_BINDING = {
	["closeBtn"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")},
		},
	},
	["cancelBtn"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")},
		},
	},
	["sureBtn"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onSureBtnClick")},
		},
	},
	["note1"] = "note1",
	["vip"] = "vip",
	["note2"] = "note2",
	["surplusNum"] = "surplusNum",
	["surplusNum"] = {
		varname = "surplusNum",
		binds = {
			event = "text",
			idler = bindHelper.self("surplusNumTxt")
		}
	},
	["note3"] = "note3",
	["note4"] = "note4",
	["rmbIcon"] = "rmbIcon",
	["rmbNum"] = "rmbNum",
	["note5"] = "note5",
	["pointNum"] = "pointNum",
	["note6"] = "note6",
	["bg"] = "bg",
}

function CardSkillBuyPointView:onCreate(cb)
	self.cb = cb
	self:initModel()
	local vipLevel = self.vipLevel:read()
	local vipCfg = gVipCsv[vipLevel]
	local buySkillPointTimes = self.buySkillPointTimes:read()
	self.surplusNumTxt = idler.new(vipCfg.buySkillPointTimes - buySkillPointTimes)
	local costRmb = gCostCsv.skill_point_buy_cost
	local buyTimes = cc.clampf(buySkillPointTimes + 1, 1, table.length(costRmb))
	self.cost = costRmb[buyTimes]
	self.rmbNum:text(self.cost)
	self.pointNum:text(20)
	if vipLevel == 0 then
		self.vip:hide()
		self.note1:text(gLanguageCsv.youAreNotVIP)
		adapt.oneLineCenterPos(cc.p(self.bg:x(), self.note1:y()), {self.note1, self.note2, self.surplusNum, self.note3}, cc.p(15, 0))
	else
		self.vip:texture("common/icon/vip/icon_vip"..vipLevel..".png"):show()
		adapt.oneLineCenterPos(cc.p(self.bg:x(), self.note1:y()), {self.note1, self.vip, self.note2, self.surplusNum, self.note3}, cc.p(15, 0))
	end
	self.note4:anchorPoint(0, 0.5)
	self.note4:x(self.note1:x() - self.note1:width() * self.note1:anchorPoint().x)
	adapt.oneLinePos(self.note4, {self.pointNum, self.note5, self.rmbNum, self.rmbIcon}, cc.p(10, 0), "left")
	self.note6:x(self.bg:x())
	Dialog.onCreate(self, {clickClose = false})
end

function CardSkillBuyPointView:initModel()
	self.vipLevel = gGameModel.role:getIdler("vip_level")
	self.buySkillPointTimes = gGameModel.daily_record:getIdler("buy_skill_point_times")
	self.rmb = gGameModel.role:getIdler("rmb")
end

function CardSkillBuyPointView:onSureBtnClick()
	if self.surplusNumTxt:read() <= 0 then
		gGameUI:showTip(gLanguageCsv.insufficientPurchaseTimes)
		return
	end
	if self.rmb:read() < self.cost then
		gGameUI:showTip(gLanguageCsv.buyRMBNotEnough)
		return
	end
	self:addCallbackOnExit(self.cb)
	ViewBase.onClose(self)
end
return CardSkillBuyPointView
