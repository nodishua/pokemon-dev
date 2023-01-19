-- @date 2020-04-27
-- @desc 购买次数二级弹框

local ViewBase = cc.load("mvc").ViewBase
local BuyNumberView = class("BuyNumberView", Dialog)

BuyNumberView.RESOURCE_FILENAME = "card_buy_capacity.json"
BuyNumberView.RESOURCE_BINDING = {
	["closeBtn"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("callBackView")}
		},
	},
	["content"] = "content",
	["content.text1"] = "contentText",
	["content.num"] = "addNum",
	["content.leftTimes1"] = "leftTimes1",
	["content.leftTimes2"] = "leftTimes2",
	["pricePanel.icon"] = "priceIcon",
	["pricePanel.price"] = "priceText",
	["pricePanel.priceNote"] = "priceNote",
	["buyBtn"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onBuyItem")}
		},
	},
	["buyBtn.text"] = {
		binds = {
			event = "effect",
			data = {color = ui.COLORS.NORMAL.WHITE, glow = {color = ui.COLORS.GLOW.WHITE}},
		},
	},
	["content.leftTimesInfo"] = "leftTimesInfo",
	["title"] = "title",
}

function BuyNumberView:onCreate(params, cb)
	self.params = params
	self.cb = cb
	local vipLevel = gGameModel.role:read("vip_level")
	self.conversionNumMax = params.itemType ~= 1 and gVipCsv[vipLevel].megaItemMaxTimes or gVipCsv[vipLevel].megaCommonItemMaxTimes
	self.title:text(gLanguageCsv.conversionNum)
	self.leftTimesInfo:text(gLanguageCsv.surplusTitle)
	self.contentText:text(gLanguageCsv.hintConversionNumber)

	self.conversionChanceMax = self.params.itemType ~= 1 and gCommonConfigCsv.megaBuyChanceLimit or gCommonConfigCsv.megaCommonBuyChanceLimit
	self.leftTimes2:text("/" .. self.conversionChanceMax)		--总次数
	self.conversionBuyAddTimes = self.params.itemType ~= 1 and gCommonConfigCsv.megaBuyAddTimes or gCommonConfigCsv.megaCommonBuyAddTimes
	self.addNum:text("+" .. self.conversionBuyAddTimes)						--增加次数

	if params.icon then
		self.priceIcon:texture(params.icon)				--货币资源
	end
	self:conversionUpdata()

	Dialog.onCreate(self, {blackType = 2, clickClose = false})
end

function BuyNumberView:dataJudge()
	local megaConvertBuyTimes = gGameModel.daily_record:read("mega_convert_buy_times")
	local buyTimes = megaConvertBuyTimes and megaConvertBuyTimes[self.params.id] or 0
	local costSeq = self.params.itemType ~= 1 and "mega_item_convert_cost" or "mega_commonitem_convert_cost"
	local times = math.min(buyTimes + 1, csvSize(gCostCsv[costSeq]))
	return gCostCsv[costSeq][times], buyTimes
end

function BuyNumberView:conversionUpdata()
	local rmb, buyTimes = self:dataJudge()
	local roleRmb = gGameModel.role:read("rmb")
	self.priceText:text(rmb)					--价值数量
	text.addEffect(self.priceText, {color = roleRmb >= rmb and ui.COLORS.QUALITY_OUTLINE[1] or ui.COLORS.NORMAL.ALERT_ORANGE})
	self.leftTimes1:text(self.conversionChanceMax - buyTimes)	--用的次时
	self.leftTimes2:x(self.leftTimes1:x() + self.leftTimes1:width())
	text.addEffect(self.leftTimes1, {color = self.conversionChanceMax >= buyTimes and ui.COLORS.QUALITY_OUTLINE[1] or ui.COLORS.NORMAL.ALERT_ORANGE})
	adapt.oneLineCenterPos(cc.p(200, 0), {self.priceNote, self.priceText, self.priceIcon}, cc.p(8, 0))
	adapt.oneLineCenterPos(cc.p(800, 260), {self.leftTimesInfo, self.leftTimes1, self.leftTimes2}, cc.p(8, 0))
end

function BuyNumberView:onBuyItem()
	local rmb, buyTimes = self:dataJudge()
	if buyTimes >= self.conversionChanceMax then
		gGameUI:showTip(gLanguageCsv.purchaseLimit)
		return
	end
	local roleRmb = gGameModel.role:read("rmb")
	if roleRmb < rmb then
		gGameUI:showTip(gLanguageCsv.rmbNotEnough)
		return
	end
	local megaConvertTimes = gGameModel.role:read("mega_convert_times")
	local conversionNum = megaConvertTimes and megaConvertTimes[self.params.id] or 0
	if conversionNum + self.conversionBuyAddTimes  > self.conversionNumMax then
		gGameUI:showTip(gLanguageCsv.megaConvertTimesLimit)
		return
	end
	dataEasy.sureUsingDiamonds(function ()
		gGameApp:requestServer("/game/develop/mega/convert/buy",function (tb)
			gGameUI:showTip(gLanguageCsv.hasBuy)
			self:conversionUpdata()
		end, self.params.id)
	end, rmb)
end

function BuyNumberView:callBackView()
	self:addCallbackOnExit(self.cb)
	ViewBase.onClose(self)
end

return BuyNumberView