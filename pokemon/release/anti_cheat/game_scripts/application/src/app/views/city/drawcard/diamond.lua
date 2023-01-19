local t = {}

function t.initPageItemFunc(self, curType, goldCount, diamondCount, allCount, half, trainerCount, equipCount, drawEquipCount)
	self:addEffectInRect("effect/zuanshichouka.skel")
	self.isLimitDraw:set(false)
	local isFree = diamondCount < 1
	self.isFree:set(isFree)
	self.freeTxt:text(gLanguageCsv.freeCount)
	self.txtFree:text(gLanguageCsv.free)
	text.addEffect(self.txtFree, {color = cc.c4b(177,233,126,255)})
	self.freeTimes:set("1/1")
	self.isCutDown:set(false)
	local onePath = "common/icon/icon_diamond.png"
	local tenPath = "common/icon/icon_diamond.png"
	local costOnece = gCommonConfigCsv.drawCardCostPrice
	local costTen = gCommonConfigCsv.draw10CardCostPrice
	local addVal = dataEasy.getPrivilegeVal(game.PRIVILEGE_TYPE.FirstRMBDrawCardHalf)
	if half == 0 and not isFree and addVal ~= 0 then
		self.isHalf = true
		self.isCost:set(false)
		self.privilegePanel:show()
		local childs = self.privilegePanel:multiget("line", "textNote", "imgIcon", "textCost", "textDiscount")
		childs.textCost:text(costOnece)
		childs.textDiscount:text(costOnece * 0.5)
		childs.line:size(childs.textCost:size().width + 10, 7)
		adapt.oneLinePos(childs.textNote, {childs.textCost, childs.textDiscount, childs.imgIcon}, {cc.p(0,0), cc.p(5, 0), cc.p(0,0)})
		childs.line:x(childs.textCost:x() - 3)
	else
		self.privilegePanel:hide()
		self.isCost:set(not isFree)
	end
	local rmbCard = dataEasy.getNumByKey(game.ITEM_TICKET.rmbCard)
	if not isFree and rmbCard > 0 then
		onePath = dataEasy.getIconResByKey(game.ITEM_TICKET.rmbCard)
		costOnece = string.format("%s/%s", rmbCard, 1)
	end
	if rmbCard >= 10 then
		tenPath = dataEasy.getIconResByKey(game.ITEM_TICKET.rmbCard)
		costTen = string.format("%s/%s", rmbCard, 10)
	end
	self.oneIconPath:set(onePath)
	self.tenIconPath:set(tenPath)
	self.drawOnceCost:set(costOnece)
	self.drawTenCost:set(costTen)
end

function t.isEnoughToDrawFunc(self, isTen)
	local myNumOne = self.rmb:read()
	local myNumTen = myNumOne
	local once = gCommonConfigCsv.drawCardCostPrice
	local ten = gCommonConfigCsv.draw10CardCostPrice
	local isHalf = self.isHalf

	-- 半价打折
	if isHalf then
		once = once / 2
	end

	-- 代金券
	local target = dataEasy.getNumByKey(game.ITEM_TICKET.rmbCard)
	if target > 0 then-- 至少有一张
		if not isHalf then -- 半价优先原则
			once = 1
			myNumOne = target
		end

		if target >= 10 then-- 满足十连
			ten = 10
			myNumTen = target
		end
	end

	-- return myNumOne >= once, myNumTen >= ten
	if isTen then
		return myNumTen >= ten
	else
		return myNumOne >= once
	end
end

function t.drawOneClickFunc(self)
	local isFree = self.isFree:read()
	-- 代金券
	local target = dataEasy.getNumByKey(game.ITEM_TICKET.rmbCard)
	local function cb()
		gGameApp:requestServer("/game/lottery/card/draw", function(tb)
			audio.pauseMusic()
			audio.playEffectWithWeekBGM("drawcard_one.mp3")
			local ret, spe, isFull = dataEasy.getRawTable(tb)
			local items = dataEasy.getItems(ret, spe)
			local cb
			local params = {
				items = items,
				drawType = "diamond",
				times = 1,
				isFree = isFree,
				cb = function()
					self:initAward()
				end,
			}
			gGameUI:stackUI("city.drawcard.result", nil, nil, params)
			self:initAward()
		end, isFree and "free1" or "rmb1")
	end
	if isFree or target > 0 or self.isHalf then
		cb()
	else
		dataEasy.sureUsingDiamonds(cb, gCommonConfigCsv.drawCardCostPrice)
	end
end

function t.drawTenClickFunc(self)
	local bUseDiamond = false --是否消耗钻石抽卡
	if dataEasy.getNumByKey(game.ITEM_TICKET.rmbCard) < 10 then
		bUseDiamond = true
	end
	local function requesetServer()
		gGameApp:requestServer("/game/lottery/card/draw", function(tb)
			audio.pauseMusic()
			audio.playEffectWithWeekBGM("drawcard_ten.mp3")
			local ret, spe, isFull = dataEasy.getRawTable(tb)
			local items = dataEasy.getItems(ret, spe)
			local cb
			local params = {
				items = items,
				drawType = "diamond",
				times = 10,
				isFree = false,
				cb = function()
					self:initAward()
				end,
			}
			gGameUI:stackUI("city.drawcard.result", nil, nil, params)
			if bUseDiamond then
				userDefault.setCurrDayKey("diamondDrawTips", 0)
			end
			self:initAward()
		end, "rmb10")
	end
	if bUseDiamond and (matchLanguage({"kr"}) or (userDefault.getCurrDayKey("diamondDrawTips", 1) == 1 and dataEasy.isUnlock("diamondDrawTips"))) then
		local cost = gCommonConfigCsv.draw10CardCostPrice
		gGameUI:showDialog{content = string.format(gLanguageCsv.draw10CardTips, cost), cb = function()
			requesetServer()
		end, btnType = 2, clearFast = true, isRich = true}
	else
		requesetServer()
	end
end

return t