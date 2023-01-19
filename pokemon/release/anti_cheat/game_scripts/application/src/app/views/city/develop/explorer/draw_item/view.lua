local ExplorerDrawItemView = class("ExplorerDrawItemView", cc.load("mvc").ViewBase)

ExplorerDrawItemView.RESOURCE_FILENAME = "explore_draw_item_view.json"
ExplorerDrawItemView.RESOURCE_BINDING = {
	["onePanel.btn"] = {
		varname = "oneBtn",
		binds = {
			{
				event = "touch",
				methods = {ended = bindHelper.self("onBtnOneClick")}
			},
			{
				event = "extend",
				class = "red_hint",
				props = {
					specialTag = "explorerFind",
					onNode = function(node)
						node:xy(node:x()-35,  node:y()-20)
					end,
				}
			}
		}
	},
	["fivePanel.btn"] = {
		varname = "fiveBtn",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onBtnFiveClick")}
		}
	},
	["fivePanel.btn.txt"] = {
		binds = {
			event = "effect",
			data = {outline = {color = cc.c4b(204,75,52,255), size = 4}}
		}
	},
	["onePanel.btn.txt"] = {
		binds = {
			event = "effect",
			data = {outline = {color = cc.c4b(28,114,154,255), size = 4}}
		}
	},
	["btnPreview"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onBtnPreviewClick")}
		}
	},
	["onePanel.costPanel"] = "oneCostPanel",
	["onePanel.specialTimes"] = "specialTimesPanel",
	["onePanel.specialTimes.time"] = "specialTimes",
	["onePanel.btn.num"] = "oneCostNum",
	["onePanel.btn.icon"] = "oneCostIcon",
	["onePanel.btn.originalNum"] = "originalNum",
	["onePanel.btn.line"] = "originalNumLine",
	["onePanel.btn.textNote"] = "textNote",
	["fivePanel.costPanel"] = "fiveCostPanel",
	["fivePanel.btn.num"] = "fiveCostNum",
	["fivePanel.btn.textNote"] = "textNoteFive",
	["fivePanel.btn.icon"] = "fiveCostIcon",
	["onePanel.costPanel.time"] = "oneTime",
	["onePanel.costPanel.time1"] = "oneTime1",
	["onePanel.btn.free"] = "oneFreePanel",
	["topRightPanel.txt1"] = "txt1",
	["topRightPanel.txt2"] = "txt2",
	["topRightPanel.txt3"] = "txt3",
	["topRightPanel.txt"] = "txt",
	["topRightPanel.num"] = "num",
	["topRightPanel.bg"] = "topRightBg",
}

function ExplorerDrawItemView:onCreate()
	gGameUI.topuiManager:createView("default", self, {onClose = self:createHandler("onClose")}):init(
		{title = gLanguageCsv.explorerDrawItem, subTitle = "EXPLORER"})
	self:initModel()
	adapt.setTextAdaptWithSize(self.txt1, {str = gLanguageCsv.updateDrawTimes, size = cc.size(560, 100), vertical = "center", horizontal = "center", margin = -5, maxLine = 2})
	adapt.oneLinePos(self.txt1, {self.txt2, self.txt3})
	self.isCutDown = idler.new(false)
	self.isStandby = idler.new(true)	-- 抽奖特效状态：1、true, 待机状态 2、false, 抽奖后状态 3、1和5代表抽1次和5次
	self.fiveCostIcon:texture(dataEasy.getIconResByKey("rmb"))
	self.fiveCostNum:text(gCommonConfigCsv.draw5ItemCostPrice)
	idlereasy.any({self.items, self.itemFreeCounter, self.rmb, self.itemDiamondHalfCount}, function (_, items, itemFreeCounter, rmb, itemDiamondHalfCount)
		local val = dataEasy.getPrivilegeVal(game.PRIVILEGE_TYPE.DrawItemFreeTimes)
		local ticket = items[game.ITEM_TICKET.card4] or 0
		local isFree = itemFreeCounter == 0
		local isSpecial = val + 1 > itemFreeCounter
		local isHalf = itemDiamondHalfCount == 0 and dataEasy.getPrivilegeVal(game.PRIVILEGE_TYPE.FirstRMBDrawItemHalf) ~= 0
		self:initUI(ticket, isFree, isSpecial, isHalf)
		if isSpecial and not isFree then
			local leftTimes = val - itemFreeCounter + 1
			self.specialTimes:text(string.format("%d/%d", leftTimes,val))
		elseif not isFree and not isSpecial then
			if isHalf then
				self.oneCostNum:text(gCommonConfigCsv.drawItemCostPrice/2)
				self.oneCostIcon:texture(dataEasy.getIconResByKey("rmb"))
				self.originalNum:text(gCommonConfigCsv.drawItemCostPrice)
				self.originalNumLine:width(self.originalNum:getContentSize().width + 10)
				adapt.oneLineCenterPos(cc.p(self.oneBtn:width()/2, self.oneCostNum:y()), {self.originalNumLine, self.oneCostNum, self.oneCostIcon}, cc.p(10, 0))
				self.originalNum:x(self.originalNumLine:x())
			else
				local items = {self.oneCostNum, self.oneCostIcon}
				if ticket > 0 then
					self.oneCostNum:text(string.format("%s/%s", ticket, 1))
					self.oneCostIcon:texture(dataEasy.getIconResByKey(game.ITEM_TICKET.card4))
					table.insert(items, 1, self.textNote)
				else
					self.oneCostNum:text(gCommonConfigCsv.drawItemCostPrice)
					self.oneCostIcon:texture(dataEasy.getIconResByKey("rmb"))
				end
				adapt.oneLineCenterPos(cc.p(self.oneBtn:width()/2, self.oneCostNum:y()), items, cc.p(10, 0))
			end
			self.isCutDown:set(true)
		end
		if ticket >= 5 then
			self.textNoteFive:show()
			self.fiveCostNum:text(ticket .. "/5")
			self.fiveCostIcon:texture(dataEasy.getIconResByKey(game.ITEM_TICKET.card4))
			adapt.oneLineCenterPos(cc.p(self.fiveBtn:width()/2, self.fiveCostNum:y()), {self.textNoteFive, self.fiveCostNum, self.fiveCostIcon}, cc.p(10, 0))
		else
			self.fiveCostIcon:texture(dataEasy.getIconResByKey("rmb"))
			self.fiveCostNum:text(gCommonConfigCsv.draw5ItemCostPrice)
			adapt.oneLineCenterPos(cc.p(self.fiveBtn:width()/2, self.fiveCostNum:y()),{self.fiveCostNum, self.fiveCostIcon})
		end

		-- 钻石颜色判断
		local oneCostColor = (rmb < gCommonConfigCsv.drawItemCostPrice and ticket <= 0) and ui.COLORS.NORMAL.RED or ui.COLORS.NORMAL.WHITE -- 单抽金额或钥匙是否足够
		if isHalf then
			oneCostColor = rmb < gCommonConfigCsv.drawItemCostPrice/2 and ui.COLORS.NORMAL.RED or ui.COLORS.NORMAL.ALERT_GREEN
		end
		local fiveCostColor = (rmb < gCommonConfigCsv.draw5ItemCostPrice and ticket < 5) and ui.COLORS.NORMAL.RED or ui.COLORS.NORMAL.WHITE -- 五连抽金额或钥匙是否足够

		text.addEffect(self.oneCostNum, {color=oneCostColor})
		text.addEffect(self.fiveCostNum, {color=fiveCostColor})

	end)
	idlereasy.when(self.isCutDown, function (_, val)
		if val then
			local currTime = time.getTodayStrInClock()
			if time.getTodayStrInClock() == time.getTodayStr() then
				--当天。 就是拿hour减就好了。
				local currTime = time.getTimeTable()
				local hour = currTime.hour - 5
				local min = currTime.min
				local sec = currTime.sec
				local lastTime = 86400 - hour * 3600 - min * 60 - sec
				self.lastTime = lastTime
			else
				local currTime = time.getTimeTable()
				local hour = currTime.hour
				local min = currTime.min
				local sec = currTime.sec
				local lastTime = 18000 - hour * 3600 - min * 60 - sec
				self.lastTime = lastTime
			end
		end
	end)

	self:enableSchedule():schedule(function (dt)
		if self.isCutDown:read() then
			self.lastTime = self.lastTime - 1
			self.oneTime:text(time.getCutDown(self.lastTime).str)
			adapt.oneLinePos(self.oneTime1, self.oneTime)
			if self.lastTime == 0 then
				self.isCutDown:set(false)
				return false
			end
		end
	end, 1, 0, "drawCardSchedule")
	idlereasy.any({self.totalTime, self.vip}, function (_, val, vip)
		self.num:text(val.."/"..gVipCsv[vip].drawItemCountLimit)
		adapt.oneLinePos(self.txt, self.num)
		self.topRightBg:size(self.txt:size().width + self.num:size().width - 50, 150)
		text.addEffect(self.num, {color = val < gVipCsv[vip].drawItemCountLimit and ui.COLORS.NORMAL.LIGHT_GREEN or ui.COLORS.NORMAL.ALERT_YELLOW})
	end)

	-- 抽奖特效
	self.spineChoujiang = widget.addAnimationByKey(self:getResourceNode(), "tanxianchoujiang/jixiegongchang.skel", 'choujianghou', "standby_loop", 0)
		:anchorPoint(cc.p(0.5,0.5))
		:xy(self:getResourceNode():width()/2, self:getResourceNode():height()/2)
		:scale(2)
	idlereasy.when(self.isStandby, function (_, val)
		if type(val) == "boolean" then
			if val then
				self.spineChoujiang:play("standby_loop")
			else
				self.spineChoujiang:play("choujianghou_loop")
			end
		else
			if val == 1 then
				self:onBtnOneClick(false)
			elseif val == 5 then
				self:onBtnFiveClick(false)
			else
				printWarn("val must be 1 or 5, current val is %", val)
			end
		end
	end)
end

function ExplorerDrawItemView:initUI(ticket, isFree, isSpecial, isHalf)
	local str = ""
	local flag = isFree or isSpecial
	if isFree then
		str = gLanguageCsv.freeOnce
	elseif isSpecial then
		str = gLanguageCsv.privilege
	end
	self.oneFreePanel:text(str)
	self.oneFreePanel:visible(flag)
	self.oneCostPanel:visible(not flag)
	self.oneCostIcon:visible(not flag)
	self.oneCostNum:visible(not flag)
	self.originalNum:visible(isHalf and not flag)
	self.originalNumLine:visible(isHalf and not flag)
	self.textNote:visible(not isHalf and not isSpecial and not isHalf and ticket > 0)
	self.specialTimesPanel:visible(isSpecial and not isFree)
	self.textNoteFive:hide()
end

function ExplorerDrawItemView:initModel()
	self.rmb = gGameModel.role:getIdler("rmb")
	self.items = gGameModel.role:getIdler("items")
	self.vip = gGameModel.role:getIdler("vip_level")
	self.totalTime = gGameModel.daily_record:getIdler("draw_item")
	self.itemFreeCounter = gGameModel.daily_record:getIdler("item_dc1_free_counter")
	self.itemDiamondHalfCount = gGameModel.daily_record:getIdler("draw_item_rmb1_half")
end

function ExplorerDrawItemView:onBtnOneClick( isEffect )
	local param
	local val = dataEasy.getPrivilegeVal(game.PRIVILEGE_TYPE.DrawItemFreeTimes)
	-- 总次数小于免费次数+特权次数
	if self.itemFreeCounter:read() < val + 1 then
		param = "free1"
	else
		param = "coin4_1"
	end

	local ticket = self.items:read()[game.ITEM_TICKET.card4] or 0
	local isHalf = self.itemDiamondHalfCount:read() == 0 and dataEasy.getPrivilegeVal(game.PRIVILEGE_TYPE.FirstRMBDrawItemHalf) ~= 0
	if gVipCsv[self.vip:read()].drawItemCountLimit == self.totalTime:read() and param ~= "free1" then -- 特权和免费次数不计入总次数内
		gGameUI:showTip(gLanguageCsv.todayDrawItemLimit)
		return
	end

	-- 优先判断半价
	if isHalf and param ~= "free1" and self.rmb:read() < gCommonConfigCsv.drawItemCostPrice/2 then
		uiEasy.showDialog("rmb")
		return
	end

	if not isHalf and ticket == 0 and self.rmb:read() < gCommonConfigCsv.drawItemCostPrice and param ~= "free1" then
		uiEasy.showDialog("rmb")
		return
	end
	print(self.itemDiamondHalfCount:read(), dataEasy.getPrivilegeVal(game.PRIVILEGE_TYPE.FirstRMBDrawItemHalf), isHalf, ticket)
	if type(isEffect) ~= "boolean" and ((isHalf and param ~= "free1") or (not isHalf and ticket == 0 and param ~= "free1")) then
		dataEasy.sureUsingDiamonds(function ()
			self:drawItem(param, isEffect)
		end, isHalf and gCommonConfigCsv.drawItemCostPrice/2 or gCommonConfigCsv.drawItemCostPrice)
	else
		self:drawItem(param, isEffect)
	end
end

function ExplorerDrawItemView:onBtnFiveClick( isEffect )
	if gVipCsv[self.vip:read()].drawItemCountLimit == self.totalTime:read() then
		gGameUI:showTip(gLanguageCsv.todayDrawItemLimit)
		return
	elseif gVipCsv[self.vip:read()].drawItemCountLimit - self.totalTime:read() < 5 then
		gGameUI:showTip(gLanguageCsv.todayDrawItemTimesLessFive)
		return
	end
	local ticket = self.items:read()[game.ITEM_TICKET.card4] or 0
	if ticket < 5 and self.rmb:read() < gCommonConfigCsv.draw5ItemCostPrice then
		uiEasy.showDialog("rmb")
		return
	end
	if type(isEffect) ~= "boolean" and ticket < 5 then
		dataEasy.sureUsingDiamonds(function ()
			self:drawItem("coin4_5", isEffect)
		end, gCommonConfigCsv.draw5ItemCostPrice)
	else
		self:drawItem("coin4_5", isEffect)
	end
end

function ExplorerDrawItemView:drawItem(param, isEffect)
	local showOver = {false}
	gGameApp:requestServerCustom("/game/lottery/item/draw")
		:params(param)
		:onResponse(function ()
			local delay = 0
			if isEffect then
				self.spineChoujiang:play("choujiang")
				delay = 119/30
			end
			performWithDelay(self, function ()
					showOver[1] = true
				end, delay)
		end)
		:wait(showOver)
		:doit(function (tb)
			self.isStandby:set(false)
			gGameUI:stackUI("city.develop.explorer.draw_item.success", nil, {blackLayer = true, clickClose = true}, tb.view, self:createHandler("sendParams"))
		end)
end

function ExplorerDrawItemView:onBtnPreviewClick()
	gGameUI:stackUI("city.drawcard.preview", nil, {blackLayer = true, clickClose = true}, "component")
end

function ExplorerDrawItemView:sendParams()
	return self.isStandby
end

return ExplorerDrawItemView
