-- @date 2020-04-27
-- @desc 购买背包容量

local CardCapacityView = class("CardCapacityView", Dialog)

CardCapacityView.RESOURCE_FILENAME = "card_buy_capacity.json"
CardCapacityView.RESOURCE_BINDING = {
	["closeBtn"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")}
		},
	},
	["content"] = "content",
	["content.num"] = {
		binds = {
			event = "text",
			data = "+" .. gCommonConfigCsv.cardBagCapacityIncrease,
		},
	},
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
	["content.leftTimesInfo"] = "leftTimesInfo"
}

function CardCapacityView:onCreate()
	self:initModel()

	self.price = idler.new(0)
	adapt.oneLineCenterPos(cc.p(775, 400), {self.Text1, self.num}, cc.p(10, 0))
	-- 如果vip达到上限,则返回-1
	self.leftTimes = idlereasy.any({self.vipLevel, self.nowBuyNum}, function(_, vipLevel, nowBuyNum)
		local times = gVipCsv[vipLevel].cardbgBuyNum
		local leftTimes = self:refreshNumPanel(nowBuyNum, times)
		if leftTimes == 0 and vipLevel >= game.VIP_LIMIT then
			leftTimes = -1
		end
		local costSeq = gCostCsv.cardbag_buy_cost
		local num = math.min(nowBuyNum + 1, table.length(costSeq))
		self.price:set(costSeq[num])
		return true, leftTimes
	end)
	idlereasy.any({self.price, self.rmb}, function(_, price, rmb)
		self.priceText:text(price)
		local color = rmb < price and ui.COLORS.NORMAL.RED or ui.COLORS.NORMAL.DEFAULT
		text.addEffect(self.priceText, {color=color})
		adapt.oneLineCenterPos(cc.p(200, -17), {self.priceNote, self.priceText, self.priceIcon}, cc.p(20, 0))
		-- adapt.oneLinePos(self.priceText, self.priceNote, cc.p(10, 0), "right")
		-- adapt.oneLinePos(self.priceText, self.priceIcon, cc.p(10, 0))
	end)

	Dialog.onCreate(self, {clickClose = false})
end

function CardCapacityView:refreshNumPanel(nowBuyNum, times)
	local leftTimes = times - nowBuyNum
	self.leftTimes1:text(leftTimes)
	local color = leftTimes > 0 and cc.c4b(116, 190, 109, 255) or ui.COLORS.NORMAL.DEFAULT
	text.addEffect(self.leftTimes1, {color=color})
	self.leftTimes2:text("/" .. times)
	--adapt.oneLinePos(self.leftTimes1, self.leftTimes2)
	adapt.oneLineCenterPos(cc.p(self.content:width()/2, self.leftTimes2:y()), {self.leftTimesInfo, self.leftTimes1, self.leftTimes2}, cc.p(0, 0))
	return leftTimes
end

function CardCapacityView:initModel()
	self.rmb = gGameModel.role:getIdler("rmb")
	self.vipLevel = gGameModel.role:getIdler("vip_level")
	self.nowBuyNum = gGameModel.role:getIdler("card_capacity_times")
	self.cardCapacity = gGameModel.role:getIdler("card_capacity")
end

function CardCapacityView:onBuyItem()
	idlereasy.do_(function(cardCapacity, leftTimes, rmb, price)
		-- -1代表会员等级也达到了上限
		if leftTimes == -1 then
			gGameUI:showTip(gLanguageCsv.cardCapacityBuyLimit)

		-- 0代表已上限，请提升vip等级
		elseif leftTimes == 0 then
			local content = {gLanguageCsv.cardCapacityBuyMax, string.format(gLanguageCsv.commonVipIncrease, gLanguageCsv.buy)}
			uiEasy.showDialog("vip", {titleName = gLanguageCsv.cardCapacityBuy, content = content})

		elseif rmb < price then
			uiEasy.showDialog("rmb")
		else
			dataEasy.sureUsingDiamonds(function ()
				gGameApp:requestServer("/game/role/card_capacity/buy", function(tb)
					gGameUI:showTip(gLanguageCsv.hasBuy)
				end)
			end, price)
		end
	end, self.cardCapacity, self.leftTimes, self.rmb, self.price)
end

return CardCapacityView