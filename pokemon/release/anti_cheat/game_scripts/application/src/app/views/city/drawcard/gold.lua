local t = {}

function t.initPageItemFunc(self, curType, goldCount, diamondCount, allCount, half, trainerCount, equipCount, drawEquipCount)
	self:addEffectInRect("effect/jingbichouka.skel")
	self.isLimitDraw:set(false)
	local isCutDown = gCommonConfigCsv.drawGoldFreeRefreshDuration - (time.getTime() - self.lastDrawTime:read()) > 0
	local isFree = goldCount < tonumber(gCommonConfigCsv.drawGoldFreeLimit) and not isCutDown
	local isCutDownShow
	local addVal = dataEasy.getPrivilegeVal(game.PRIVILEGE_TYPE.FreeGoldDrawCardTimes)
	local freeTimes
	if trainerCount < addVal then
		--有特权次数
		isFree = true
		self.freeTxt:text(gLanguageCsv.privilegeCount)
		self.txtFree:text(gLanguageCsv.privilege)
		text.addEffect(self.txtFree, {color = cc.c4b(255,241,1,255)})
		isCutDownShow = false
		freeTimes = (addVal - trainerCount).."/"..addVal
	else
		self.freeTxt:text(gLanguageCsv.freeCount)
		self.txtFree:text(gLanguageCsv.free)
		text.addEffect(self.txtFree, {color = cc.c4b(177,233,126,255)})
		freeTimes = (gCommonConfigCsv.drawGoldFreeLimit - goldCount) .. "/"..gCommonConfigCsv.drawGoldFreeLimit
		--无特权次数
		isCutDownShow = goldCount < tonumber(gCommonConfigCsv.drawGoldFreeLimit) and isCutDown
	end
	self.isFree:set(isFree)
	self.isCost:set(not isFree)
	self.isCutDown:set(isCutDownShow, true)
	self.freeTimes:set(freeTimes)
	local onePath = "common/icon/icon_gold.png"
	local tenPath = "common/icon/icon_gold.png"
	local costOnece = gCommonConfigCsv.drawGoldCostPrice
	local costTen = gCommonConfigCsv.draw10GoldCostPrice
	local goldCard = dataEasy.getNumByKey(game.ITEM_TICKET.goldCard)
	if not isFree and goldCard > 0 then
		onePath = dataEasy.getIconResByKey(game.ITEM_TICKET.goldCard)
		costOnece = string.format("%s/%s", goldCard, 1)
	end
	if goldCard >= 10 then
		tenPath = dataEasy.getIconResByKey(game.ITEM_TICKET.goldCard)
		costTen = string.format("%s/%s", goldCard, 10)
	end
	self.oneIconPath:set(onePath)
	self.tenIconPath:set(tenPath)
	self.drawOnceCost:set(costOnece)
	self.drawTenCost:set(costTen)
end

function t.isEnoughToDrawFunc(self, isTen)
	local myNumOne = self.gold:read()
	local myNumTen = myNumOne
	local once = gCommonConfigCsv.drawGoldCostPrice
	local ten = gCommonConfigCsv.draw10GoldCostPrice

	-- 代金券
	local target = dataEasy.getNumByKey(game.ITEM_TICKET.goldCard)
	if target > 0 then-- 至少有一张
		once = 1
		myNumOne = target

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
	gGameApp:requestServer("/game/lottery/card/draw", function(tb)
		audio.pauseMusic()
		audio.playEffectWithWeekBGM("drawcard_one.mp3")
		local ret, spe, isFull = dataEasy.getRawTable(tb)
		local items = dataEasy.getItems(ret, spe)
		local params = {
			items = items,
			drawType = "gold",
			times = 1,
			isFree = isFree,
		}
		gGameUI:stackUI("city.drawcard.result", nil, nil, params)
	end, isFree and "free_gold1" or "gold1")
end

function t.drawTenClickFunc(self)
	gGameApp:requestServer("/game/lottery/card/draw", function(tb)
		audio.pauseMusic()
		audio.playEffectWithWeekBGM("drawcard_ten.mp3")
		local ret, spe, isFull = dataEasy.getRawTable(tb)
		local items = dataEasy.getItems(ret, spe)
		local params = {
			items = items,
			drawType = "gold",
			times = 10,
			isFree = false,
		}
		gGameUI:stackUI("city.drawcard.result", nil, nil, params)
	end, "gold10")
end

return t