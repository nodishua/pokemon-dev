local t = {}

function t.initPageItemFunc(self, curType, goldCount, diamondCount, allCount, half, trainerCount, equipCount, drawEquipCount)
	local parent = self.imgBG
	widget.addAnimationByKey(parent, "effect/xiedaidaoju.skel", "effectBg", "effect_loop", 999)
		-- :scale(2)
		:alignCenter(parent:size())
	self.isLimitDraw:set(false)
	local isFree = equipCount < 1
	self.isFree:set(isFree)
	self.isCost:set(not isFree)
	self.freeTxt:text(gLanguageCsv.freeCount)
	self.txtFree:text(gLanguageCsv.free)
	text.addEffect(self.txtFree, {color = cc.c4b(177,233,126,255)})
	self.freeTimes:set("1/1")
	self.isCutDown:set(false)
	local onePath = "common/icon/icon_diamond.png"
	local tenPath = "common/icon/icon_diamond.png"
	local costOnece = gCommonConfigCsv.drawEquipCostPrice
	local costTen = gCommonConfigCsv.draw10EquipCostPrice
	local equipCard = dataEasy.getNumByKey(game.ITEM_TICKET.equipCard)
	if not isFree and equipCard > 0 then
		onePath = dataEasy.getIconResByKey(game.ITEM_TICKET.equipCard)
		costOnece = string.format("%s/%s", equipCard, 1)
	end
	if equipCard >= 10 then
		tenPath = dataEasy.getIconResByKey(game.ITEM_TICKET.equipCard)
		costTen = string.format("%s/%s", equipCard, 10)
	end
	self.oneIconPath:set(onePath)
	self.tenIconPath:set(tenPath)
	self.drawOnceCost:set(costOnece)
	self.drawTenCost:set(costTen)
end

function t.isEnoughToDrawFunc(self, isTen)
	local myNumOne = self.rmb:read()
	local myNumTen = myNumOne
	local once = gCommonConfigCsv.drawEquipCostPrice
	local ten = gCommonConfigCsv.draw10EquipCostPrice

	-- 代金券
	local target = dataEasy.getNumByKey(game.ITEM_TICKET.equipCard)
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
	self.canClick:set(false)
	local isFree = self.isFree:read()
	-- 代金券
	local target = dataEasy.getNumByKey(game.ITEM_TICKET.equipCard)
	local function cb()
		gGameApp:requestServer("/game/lottery/equip/draw", function(tb)
			local effect = self.imgBG:getChildByName("effectBg")
			if effect then
				effect:play("effect")
				performWithDelay(effect, function()
					self.canClick:set(true)
					effect:play("effect_loop")
					local ret, spe, isFull = dataEasy.getRawTable(tb)
					local items = dataEasy.getItems(ret, spe)
					items[1].equip_awake_frag = 1
					local params = {
						items = items,
						drawType = "equip",
						times = 1,
						isFree = false,
					}
					gGameUI:stackUI("city.drawcard.result", nil, {full = false}, params)
				end, 90 / 30)
			end
		end, isFree and "free1" or "rmb1")
	end
	if isFree or target > 0 then
		cb()
	else
		dataEasy.sureUsingDiamonds(cb, gCommonConfigCsv.drawEquipCostPrice)
	end
end

function t.drawTenClickFunc(self)
	local bUseDiamond = false --是否消耗钻石抽卡
	if dataEasy.getNumByKey(game.ITEM_TICKET.equipCard) < 10 then
		bUseDiamond = true
	end
	local function requesetServer()
		self.canClick:set(false)
		gGameApp:requestServer("/game/lottery/equip/draw", function(tb)
			local effect = self.imgBG:getChildByName("effectBg")
			if effect then
				effect:play("effect")
				performWithDelay(effect, function()
					self.canClick:set(true)
					effect:play("effect_loop")

					local ret, spe, isFull = dataEasy.getRawTable(tb)
					local items = dataEasy.getItems(ret, spe)
					items[1].equip_awake_frag = 10
					local params = {
						items = items,
						drawType = "equip",
						times = 10,
						isFree = false,
					}
					gGameUI:stackUI("city.drawcard.result", nil, {full = false}, params)
				end, 90 / 30)
			end
			if bUseDiamond then
				userDefault.setCurrDayKey("equipDrawTips", 0)
			end
		end, "rmb10")
	end

	if bUseDiamond and matchLanguage({"kr"}) or (userDefault.getCurrDayKey("equipDrawTips", 1) == 1 and dataEasy.isUnlock("equipDrawTips")) then
		local cost = gCommonConfigCsv.draw10EquipCostPrice
		gGameUI:showDialog{content = string.format(gLanguageCsv.draw10CardTips, cost), cb = function()
			requesetServer()
		end, btnType = 2, clearFast = true, isRich = true}
	else
		requesetServer()
	end
end

return t