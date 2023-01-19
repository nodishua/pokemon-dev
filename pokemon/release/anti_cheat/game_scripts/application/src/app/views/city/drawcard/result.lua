-- @date:   2019-05-13
-- @desc:   抽卡界面

local BAGMAXLEFTTIMES = {
	[1] = 0,
	[10] = 9,
}

local cost = {
	[1] = gCommonConfigCsv.drawCardUp1CostPrice,
	[10] = gCommonConfigCsv.drawCardUp10CostPrice,
}

local drawCardTools = require "app.views.city.drawcard.tools"

local function requestServer(url, cb, errCb, ...)
	gGameApp:requestServerCustom(url):onErrClose(errCb or function()
	end):params(...):doit(cb)
end

-- 抽卡的url接口
local DRAETYPE_DRAWFUNC = {
	diamond = function(cb, times, isFree, yyId, errCb)
		local stingTb = {
			[1] = "rmb1",
			[10] = "rmb10",
			free = "free1",
		}
		local str = stingTb[isFree and "free" or times]
		local url = "/game/lottery/card/draw"
		requestServer(url, cb, errCb, str)
	end,
	gold = function(cb, times, isFree, yyId, errCb)
		local stingTb = {
			[1] = "gold1",
			[10] = "gold10",
			free = "free_gold1",
		}
		local str = stingTb[isFree and "free" or times]
		local url = "/game/lottery/card/draw"
		requestServer(url, cb, errCb, str)
	end,
	equip = function(cb, times, isFree, yyId, errCb)
		local stingTb = {
			[1] = "rmb1",
			[10] = "rmb10",
			free = "free1",
		}
		local str = stingTb[isFree and "free" or times]
		local url = "/game/lottery/equip/draw"
		requestServer(url, cb, errCb, str)
	end,
	limit_sprite = function(cb, times, isFree, yyId, errCb)
		local stingTb = {
			[1] = "limit_box_rmb1",
			[10] = "limit_box_rmb10",
			free = "limit_box_free1",
		}
		local str = stingTb[isFree and "free" or times]
		local url = "/game/yy/limit/box/draw"
		requestServer(url, cb, errCb, yyId, str)
	end,
	limit = function(cb, times, isFree, yyId, errCb)
		local stingTb = {
			[1] = "limit_rmb1",
			[10] = "limit_rmb10",
		}
		local str = stingTb[times]
		local url = "/game/yy/award/draw"
		requestServer(url, cb, errCb, yyId, str)
	end,
	diamond_up = function(cb, times, isFree, yyId, errCb)
		local stingTb = {
			[1] = "limit_up_rmb1",
			[10] = "limit_up_rmb10",
		}
		local str = stingTb[times]
		local url = "/game/yy/award/draw"
		requestServer(url, cb, errCb, yyId, str)
	end,
	lucky_egg = function(cb, times, isFree, yyId, errCb)
		local stingTb = {
			[1] = "lucky_egg_rmb1",
			[10] = "lucky_egg_rmb10",
			free = "lucky_egg_free1",
		}
		local str = stingTb[isFree and "free" or times]
		local url = "/game/yy/lucky/egg/draw"
		requestServer(url, cb, errCb, yyId, str)
	end,
	self_choose = function(cb, times, isFree, yyId, errCb,choose)
		local stingTb = {
			[1] = "group_up_rmb1",
			[10] = "group_up_rmb10",
		}
		local str = stingTb[times]
		local url = "/game/lottery/card/up/draw"
		requestServer(url, cb, errCb, str,choose)
	end,
}

-- return targetVal 目标数值 myNum 已有数值 path 图标路径(可选)
local DRAWCOST_FUNC = {
	diamond = function(self)
		local times = self.times
		local rmbCard = dataEasy.getNumByKey(game.ITEM_TICKET.rmbCard)
		if (not self.isHalf or times == 10) and
			rmbCard >= times then
			return times, rmbCard, dataEasy.getIconResByKey(game.ITEM_TICKET.rmbCard)
		end

		local cost = {[1] = gCommonConfigCsv.drawCardCostPrice, [10] = gCommonConfigCsv.draw10CardCostPrice,}
		local val = cost[times]
		if self.isHalf then
			val = val / 2
		end
		return val, self.rmb:read()
	end,
	gold = function(self)
		local times = self.times
		local goldCard = dataEasy.getNumByKey(game.ITEM_TICKET.goldCard)
		if goldCard >= times then
			return times, goldCard, dataEasy.getIconResByKey(game.ITEM_TICKET.goldCard)
		end

		local cost = {[1] = gCommonConfigCsv.drawGoldCostPrice, [10] = gCommonConfigCsv.draw10GoldCostPrice,}
		local val = cost[times]
		return val, self.gold:read()
	end,
	equip = function(self)
		local times = self.times
		local equipCard = dataEasy.getNumByKey(game.ITEM_TICKET.equipCard)
		if equipCard >= times then
			return times, equipCard, dataEasy.getIconResByKey(game.ITEM_TICKET.equipCard)
		end

		local cost = {[1] = gCommonConfigCsv.drawEquipCostPrice, [10] = gCommonConfigCsv.draw10EquipCostPrice,}
		local val = cost[times]
		return val, self.rmb:read()
	end,
	limit = function(self)
		local times = self.times
		local limitCard = dataEasy.getNumByKey(game.ITEM_TICKET.limitCard)
		if limitCard >= times then
			return times, limitCard, dataEasy.getIconResByKey(game.ITEM_TICKET.limitCard)
		end
		local cost = csv.yunying.yyhuodong[self.yyId].paramMap["RMB"..self.times]
		return cost, self.rmb:read()
	end,
	limit_sprite = function(self)
		return csv.yunying.yyhuodong[self.yyId].paramMap["RMB"..self.times], self.rmb:read()
	end,
	diamond_up = function(self)
		local times = self.times
		local diamondUpCard = dataEasy.getNumByKey(game.ITEM_TICKET.diamondUpCard)
		if diamondUpCard >= times then
			return times, diamondUpCard, dataEasy.getIconResByKey(game.ITEM_TICKET.diamondUpCard)
		else
			return csv.yunying.yyhuodong[self.yyId].paramMap["RMB"..self.times], self.rmb:read()
		end
	end,
	lucky_egg = function(self)
		local times = self.times
		local luckyEggCard = dataEasy.getNumByKey(game.ITEM_TICKET.luckyEggCard)
		if (not self.isHalf or times == 10) and luckyEggCard >= times then
			return times, luckyEggCard, dataEasy.getIconResByKey(game.ITEM_TICKET.luckyEggCard)
		end
		return csv.yunying.yyhuodong[self.yyId].paramMap["RMB"..self.times], self.rmb:read()
	end,
	self_choose = function(self)
	 	local times = self.times
		local diamondUpCard = dataEasy.getNumByKey(game.ITEM_TICKET.diamondUpCard)
		if diamondUpCard >= times then
			return times, diamondUpCard, dataEasy.getIconResByKey(game.ITEM_TICKET.diamondUpCard)
		else
			return cost[self.times], self.rmb:read()
		end
	end,
}


local ViewBase = cc.load("mvc").ViewBase
local DrawCardResultView = class("DrawCardResultView", ViewBase)

DrawCardResultView.RESOURCE_FILENAME = "drawcard_result.json"
DrawCardResultView.RESOURCE_BINDING = {
	["baseNode"] = {
		varname = "baseNode",
		binds = {
			event = "visible",
			idler = bindHelper.self("isShowResult"),
		},
	},
	["baseNode.actionPanel"] = "actionPanel",
	["item"] = "item",
	["innerList"] = "innerList",
	["baseNode.list"] = "listview",
	["baseNode.btnOk"] = {
		binds = {
			{
				event = "visible",
				idler = bindHelper.self("isShowBtn")
			},
			{
				event = "touch",
				methods = {ended = bindHelper.self("onClose")}
			},
		}
	},
	["baseNode.btnAgain"] = {
		binds = {
			{
				event = "visible",
				idler = bindHelper.self("isShowBtn"),
			},
			{
				event = "touch",
				methods = {ended = bindHelper.self("onDrawAgain")}
			},
		}
	},
	["baseNode.btnAgain.textNote"] = {
		varname = "btnAgainTextNote",
		binds = {
			event = "text",
			idler = bindHelper.self("btnText"),
		}
	},
	["baseNode.freePanel"] = {
		binds = {
			event = "visible",
			idler = bindHelper.self("isFree")
		}
	},
	["baseNode.costInfo"] = "costInfo",
	["baseNode.costInfo.textNote"] = "textNote",
	["baseNode.costInfo.textCost"] = "textCost",
	["baseNode.costInfo.imgBg"] = "imgBg",
	["baseNode.costInfo.imgIcon"] = "imgIcon",
	["effect"] = {
		varname = "effect",
		binds = {
			{
				event = "click",
				method = bindHelper.self("onClickEffect"),
			},
			{
				event = "visible",
				idler = bindHelper.self("showEffect"),
			},
		},
	},
	["clickPanel"] = {
		binds = {
			event = "click",
			method = bindHelper.self("onClickBtn"),
		},
	},
	["effectDown"] = {
		varname = "effectDown",
		binds = {
			event = "visible",
			idler = bindHelper.self("showEffectDown"),
		},
	},
	["baseNode.privilegePanel"] = "privilegePanel",
	["baseNode.equipPanel"] = "equipPanel",
	["baseNode.equipPanel.imgIcon"] = "equipImgIcon",
	["baseNode.equipPanel.textNote"] = {
		varname = "equiTextNote",
		binds = {
			{
				event = "text",
				idler = bindHelper.self("equipOtherShow"),
			},
			{
				event = "effect",
				data = {outline={color=ui.COLORS.OUTLINE.DEFAULT}},
			},
		},
	},
	["effectItem"] = "effectItem",
}

DrawCardResultView.RESOURCE_STYLES = {
	full = true,
}

local function hasMoreCard(datas)
	local count = 0
	local hasMore = false
	for _,data in ipairs(datas) do
		for _,info in ipairs(data) do
			if info.specialFlag == "card" then
				count = count + 1
			end
			if count > 1 then
				hasMore = true
				break
			end
		end
		if hasMore then
			break
		end
	end

	return hasMore
end

--params {items, drawType, times, isFree, yyId, cb, closeCb}
function DrawCardResultView:onCreate(params)
	self:initModel()
	self.originListPos = cc.p(self.listview:xy())
	self.hasSprite = {}
	self.isJump = false
	self.isHalf = false
	self.isFirstShowCard = true
	self.showEffect = idler.new(false)
	self.showEffectDown = idler.new(false)
	self.isShowResult = idler.new(false)
	self.isShowBtn = idler.new(false)
	self.params = params
	self.isCost = idler.new(true)
	self.drawType = params.drawType
	self.checkCardCapacity = params.checkCardCapacity
	self.isFree = idler.new(params.isFree)
	self.times = params.times
	self.yyId = params.yyId
	self.selfChooseType = params.selfChooseType
	self.cb = params.cb
	self.closeCb = params.closeCb
	self.btnText = idler.new("")
	self.equipOtherShow = idler.new("")
	self.listview:setScrollBarEnabled(false)
	self.drawCount = 0 -- 标记抽卡次数 用于各个延时 判断自己所在的抽卡是否已经过期
	self.initItemTime = 5
	self.limitMax = params.limitMax
	self:playEffect(false, function()
		local items = self.params.items
		if itertools.isempty(items) then
			printWarn("抽卡返回结果为空，检查配置数据")
			return
		end
		self.hasMore = hasMoreCard(items)
		self.listview:visible(true)
		self:onInitList(items[1])

		if self.times == 10 and (self.drawType == "diamond" or self.drawType == "diamond_up" or self.drawType == "self_choose") and matchLanguage({"kr"}) then
			local count = userDefault.getForeverLocalKey("tenClickCount", 0)
			count = count + 1
			userDefault.setForeverLocalKey("tenClickCount", count)
			if count == 1 or count == 3 or count == 6 or count == 10 then
				dataEasy.showDialogToShop()
			end
		end
	end)
	idlereasy.any({self.diamondCount, self.goldCount, self.allCount, self.halfDiamondCount, self.trainerGoldCount, self.equipCount, self.drawEquipCount, self.lastDrawTime, self.items},
		function(_, diamondCount, goldCount, allCount, half, trainerCount, equipCount, drawEquipCount, lastDrawTime)
		self.isHalf = false
		self.privilegePanel:hide()
		self.isCost:set(true)
		local isFree = false
		local path = "common/icon/icon_diamond.png"
		self.equipPanel:hide()
		if self.drawType == "gold" then
			path = "common/icon/icon_gold.png"
			local leftCount = tonumber(gCommonConfigCsv.drawGoldFreeLimit) - goldCount
			local isCutDown = gCommonConfigCsv.drawGoldFreeRefreshDuration - (time.getTime() - lastDrawTime) > 0
			isFree = leftCount > 0 and not isCutDown and self.times == 1
			local addVal = dataEasy.getPrivilegeVal(game.PRIVILEGE_TYPE.FreeGoldDrawCardTimes)
			if trainerCount < addVal and self.times == 1 then
				isFree = true
			end
		elseif self.drawType == "diamond" then
			isFree = diamondCount <= 0 and self.times == 1
			-- 钻石抽卡半价逻辑判断
			-- todo 一般来说 半价抽卡只有一次机会
			local addVal = dataEasy.getPrivilegeVal(game.PRIVILEGE_TYPE.FirstRMBDrawCardHalf)
			-- local costNum = DRAWCOST[self.drawType][self.times]
			if half == 0 and not isFree and addVal ~= 0 and self.times == 1 then
				self.isHalf = true
			-- 	self.isFree:set(false)
			-- 	self.isCost:set(false)
			-- 	self.privilegePanel:show()
			-- 	local childs = self.privilegePanel:multiget("line", "textNote", "imgIcon", "textCost", "textDiscount")
			-- 	childs.textCost:text(costNum)
			-- 	childs.textDiscount:text(costNum * 0.5)
			-- 	childs.line:size(childs.textCost:size().width + 10, 7)
			-- 	adapt.oneLinePos(childs.textNote, {childs.textCost, childs.textDiscount, childs.imgIcon}, {cc.p(0,0), cc.p(5, 0), cc.p(0,0)})
			-- 	childs.line:x(childs.textCost:x() - 3)
			end
		elseif self.drawType == "limit" then
		elseif self.drawType == "limit_sprite" then
		elseif self.drawType == "diamond_up" then
		elseif self.drawType == "self_choose" then
		elseif self.drawType == "equip" then
			isFree = equipCount < 1 and self.times == 1
		end
		self.isFree:set(isFree)
		local val, myNum, pathRes = DRAWCOST_FUNC[self.drawType](self)
		if pathRes then
			path = pathRes
			val = string.format("%s/%s", myNum, val)
		end
		self.imgIcon:texture(path)
		self.textCost:text(val)

		self:refreshCostTextColor()
		local size1 = self.textCost:size()
		local size2 = self.textNote:size()
		local size3 = self.imgIcon:size()
		local width = size1.width + size2.width + size3.width + 40
		local height = 60
		self.imgBg:size(width, height)
		self.imgBg:x(width/2)
		self.costInfo:size(width, height)
		adapt.oneLineCenterPos(cc.p(width / 2, 35), {self.textNote, self.textCost, self.imgIcon}, cc.p(6, 0))
		local childs = self.privilegePanel:multiget("line", "textNote", "imgIcon", "textCost", "textDiscount")
		adapt.oneLineCenterPos(cc.p(168, 35), {childs.textNote, childs.textCost, childs.textDiscount, childs.imgIcon}, cc.p(6, 0))
		adapt.oneLinePos(childs.textNote, childs.line, cc.p(6, 0), "left")
	end)

	idlereasy.when(self.isFree, function(_, isFree)
		local count = 1
		if not isFree then
			count = self.times
		end
		self.btnText:set(string.format(gLanguageCsv.drawNum, count))
		adapt.setTextScaleWithWidth(self.btnAgainTextNote, nil, 220)
	end)
	idlereasy.any({self.isFree, self.isShowBtn, self.isCost}, function(_, isFree, isShowBtn, isCost)
		self.costInfo:visible(not isFree and isShowBtn and isCost)
	end)
	idlereasy.any({self.gold, self.rmb}, function(_, gold, rmb)
		self:refreshCostTextColor()
	end)
end

function DrawCardResultView:initModel()
	local dailyRecord = gGameModel.daily_record
	self.diamondCount = dailyRecord:getIdler("dc1_free_count") -- 钻石免费抽
	self.goldCount = dailyRecord:getIdler("gold1_free_count") -- 金币免费抽
	self.lastDrawTime = dailyRecord:getIdler("gold1_free_last_time") -- 免费金币抽取的时间
	self.allCount = dailyRecord:getIdler("draw_card") -- 总抽卡次数
	self.rmb = gGameModel.role:getIdler("rmb")
	self.gold = gGameModel.role:getIdler("gold")
	self.items = gGameModel.role:getIdler("items")
	self.cardDatas = gGameModel.role:getIdler("cards")--卡牌
	self.cardCapacity = gGameModel.role:getIdler("card_capacity")--背包容量
	self.halfDiamondCount = dailyRecord:getIdler("draw_card_rmb1_half") --半价
	self.trainerGoldCount = dailyRecord:getIdler("draw_card_gold1_trainer") --训练家特权次数
	self.equipCount = dailyRecord:getIdler("eq_dc1_free_counter") -- 装备免费单抽次数
	self.drawEquipCount = dailyRecord:getIdler("draw_equip") -- 抽装备次数
	self.dcGoldCount = dailyRecord:getIdler("dc_gold_count") -- 金币抽卡次数
	self.vip = gGameModel.role:getIdler("vip_level")
end

function DrawCardResultView:playDownEffect(isAgain)
	self.showEffect:set(false)
	self.showEffectDown:set(true)
	self.isShowResult:set(true)
	if not isAgain then
		if self.drawType == "limit" then
			local effect = widget.addAnimationByKey(self.effectDown, "effect/gongxihuode.skel", "efc1", "effect", 11)
				:alignCenter(self.effectDown:size())
				:addPlay("effect_loop")
			effect:y(effect:y() + 400)

		elseif self.drawType == "equip" then
			local size = self.effectDown:size()
			widget.addAnimationByKey(self.effectDown, "effect/gongxihuode.skel", 'efc1', "effect", 10)
				:anchorPoint(cc.p(0.5,0.5))
				:xy(size.width / 2, size.height / 4 * 3)
				:addPlay("effect_loop")
		else
			local actionName = self.params.times == 1 and "danchou_loop" or "shilianchou_loop"
			widget.addAnimationByKey(self.effectDown, "effect/chouka.skel", "efc1", actionName, 1)
				:alignCenter(self.effectDown:size())
				:scale(2)
			widget.addAnimationByKey(self.effectDown, "effect/chouka.skel", "efc2", "huode", 2)
				:alignCenter(self.effectDown:size())
				:scale(2)
		end
	end
end

function DrawCardResultView:playEffect(isAgain, cb, tb)
	local showEffect = true

	local isLimit = self.drawType == "limit"

	if (isAgain and not isLimit) or
		(not isAgain and isLimit) or
		self.drawType == "equip" then
		showEffect = false
	end
	self.showEffect:set(showEffect)
	self.isShowBtn:set(false)
	self.effect:removeAllChildren()
	local time = isAgain and 0 or 225
	if self.drawType == "equip" then
		time = 0
	elseif self.drawType == "limit" then
		if isAgain then
			local ret, spe, isFull = dataEasy.getRawTable(tb)
			local items = dataEasy.getItems(ret, spe)
			local hasCard, cards = drawCardTools.hasCard(items[1])
			if hasCard then
				-- 有卡就在此显示这张卡的剪影 至多一张卡
				widget.addAnimationByKey(self.effect, "effect/xianshichouka.skel", "effect", "effect_zhanshi", 13)
					:scale(2)
					:alignCenter(self.effect:size())
				-- 目前最多只会有一个精灵
				local cardTime = drawCardTools.addCardImg(cards, self.effect)
				time = 70 + cardTime * 30
			end
		else
			time = 0
			local size = self.effectDown:size()
			widget.addAnimationByKey(self.effectDown, "effect/xianshichouka.skel", "effect_bg", "effect_huode_loop", 10)
				:scale(2)
				:anchorPoint(cc.p(0.5,0.5))
				:xy(size.width / 2, size.height / 4 * 3)
		end
	elseif not isAgain then
		local actionName = self.params.times > 1 and "shilianchou" or "danchou"
		time = self.params.times > 1 and 225 or 70
		local efc1 = widget.addAnimationByKey(self.effect, "effect/chouka.skel", "efc", actionName, 1)
			:alignCenter(self.effect:size())
			:scale(2)
	end

	local t = 0
	self:enableSchedule():schedule(function(dt)
		t = t + dt
		if self.isJump or t >= (time / 30) then
			t = 0
			self.isJump = false
			audio.stopAllSounds()
			audio.resumeMusic()
			self:playDownEffect(isAgain)
			cb()
			return false
		end
	end, 1/60, 0, "playEffect")
end

function DrawCardResultView:onClickEffect()
	self.showEffect:set(false)
	self.isJump = true
end

function DrawCardResultView:onClickBtn()
	-- 限时神兽抽卡 点旁边快速显示全部
	if self.drawType == "limit_sprite" and self.isStartItem then
		self.initItemTime = 0
	end
end
function DrawCardResultView:isEnough2Draw()
	local targetVal, myNum = DRAWCOST_FUNC[self.drawType](self)
	return myNum >= targetVal
end

function DrawCardResultView:refreshCostTextColor()
	local isEnough = self:isEnough2Draw()
	local color = isEnough and ui.COLORS.NORMAL.DEFAULT or ui.COLORS.NORMAL.RED
	text.addEffect(self.textCost, {color=color})
end

function DrawCardResultView:onDrawAgain(list)
	self.isJump = false
	if not self:isEnough2Draw() then
		uiEasy.showDialog(itertools.include({"gold"}, self.drawType) and "gold" or "rmb")
		return
	end

	if itertools.include({"diamond", "diamond_up", "limit", "self_choose"}, self.drawType)
		and self.cardCapacity:read() - itertools.size(self.cardDatas:read()) <= BAGMAXLEFTTIMES[self.times] then
			self:showCardBagHaveBeenFullTip()
			return
	end

	if itertools.include({"limit_sprite"}, self.drawType) then
		if self.checkCardCapacity == 1 and self.cardCapacity:read() - itertools.size(self.cardDatas:read()) <= BAGMAXLEFTTIMES[self.times] then
			self:showCardBagHaveBeenFullTip()
			return
		end
	end

	if itertools.include({"gold"}, self.drawType) and not self.isFree:read() then
		local allNum = gVipCsv[self.vip:read()].goldDrawCardCountLimit
		local leftNum = allNum - (self.dcGoldCount:read() or 0)
		if leftNum < self.times then
			gGameUI:showTip(string.format(gLanguageCsv.leftTimesNotEnough, self.times))
			return
		end
	end
	if self.drawType == "lucky_egg" and self.limitMax >= 0 and self.drawCount > self.limitMax then
		if self.times == 1 then
		gGameUI:showTip(gLanguageCsv.luckyEggDrawOneMax)
	else
		gGameUI:showTip(gLanguageCsv.luckyEggDrawTenMax)
	end
		return
	end

	if self.drawType ~= "limit" then
		userDefault.setForeverLocalKey("isJumpSpriteView", true)
	else
		userDefault.setForeverLocalKey("isJumpSpriteView", false)
	end
	self.hasSprite = {}

	audio.pauseMusic()
	-- local path1 = self.times == 1 and "drawcard_one.mp3" or "drawcard_ten.mp3"
	local path2 = self.times == 1 and "drawcard_one2.mp3" or "drawcard_ten2.mp3"
	audio.playEffectWithWeekBGM(path2)


	--钻石、饰品10连抽消耗钻石二次提示
	if itertools.include({"diamond"}, self.drawType) and self:isTenDrawTipShow(game.ITEM_TICKET.rmbCard, "diamondDrawTips") then
		self:showTenDrawTipAndDraw(gCommonConfigCsv.draw10CardCostPrice)
		return
	elseif itertools.include({"equip"}, self.drawType) and self:isTenDrawTipShow(game.ITEM_TICKET.equipCard, "equipDrawTips") then
		self:showTenDrawTipAndDraw(gCommonConfigCsv.draw10EquipCostPrice)
		return
	end
	self.isShowBtn:set(false)

	local val, myNum, pathRes = DRAWCOST_FUNC[self.drawType](self)
	if not pathRes and itertools.include({"lucky_egg", "diamond", "equip", "limit", "diamond_up", "limit_sprite", "self_choose"}, self.drawType) then
		dataEasy.sureUsingDiamonds(function ()
			self:drawCard()
		end, val, function ()
			self.isShowBtn:set(true)
		end)
	else
		self:drawCard()
	end
end

function DrawCardResultView:showCardBagHaveBeenFullTip()
	gGameUI:showDialog{content = gLanguageCsv.cardBagHaveBeenFullDraw, cb = function()
		gGameUI:stackUI("city.card.bag", nil, {full = true})
	end, btnType = 2, clearFast = true}
end

function DrawCardResultView:showTenDrawTipAndDraw(costStr)
	gGameUI:showDialog{content = string.format(gLanguageCsv.draw10CardTips, costStr), cb = function()
			self.isShowBtn:set(false)
			self:drawCard()
	end, btnType = 2, clearFast = true, isRich = true}
end

function DrawCardResultView:isTenDrawTipShow(key, KeyStr)
	self.bUseDiamond = dataEasy.getNumByKey(key) < 10
	return 	self.times == 10
			and (self.bUseDiamond and (matchLanguage({"kr"})
				or userDefault.getCurrDayKey("equipDrawTips", 1) == 1 and dataEasy.isUnlock("equipDrawTips")))
end


function DrawCardResultView:drawCard()
	local callback = function(tb)
	self:playEffect(true, function()
		local ret, spe, isFull = dataEasy.getRawTable(tb)
		local items = dataEasy.getItems(ret, spe)
		self.hasMore = hasMoreCard(items)
		if self.drawType == "equip" then
			items[1].equip_awake_frag = self.times
		end
		self.listview:visible(true)
		self:onInitList(items[1])
		self:refreshCostTextColor()
		if self.times == 10 and itertools.include({"diamond","diamond_up","self_choose"},self.drawType) and matchLanguage({"kr"}) then
			local count = userDefault.getForeverLocalKey("tenClickCount", 0)
			count = count + 1
			userDefault.setForeverLocalKey("tenClickCount", count)
			if count == 1 or count == 3 or count == 6 or count == 10 then
				dataEasy.showDialogToShop()
			end
		end
		end, tb)
		if self.cb then
			self.cb(tb)
		end
		if self.bUseDiamond then
			if self.drawType == "diamond" then
				userDefault.setCurrDayKey("diamondDrawTips", 0)
			elseif self.drawType == "equip" then
				userDefault.setCurrDayKey("equipDrawTips", 0)
			end
		end
	end
	DRAETYPE_DRAWFUNC[self.drawType](callback, self.times, self.isFree:read(), self.yyId, function()
			self.isShowBtn:set(true)
		end, self.selfChooseType)
end

function DrawCardResultView:onInitList(items)
	self.listview:removeAllItems()
	local len = #items
	local count = 0
	self.isShowHero = false
	local innerList
	local tag = "drawCardResult"
	self.drawCount = self.drawCount + 1
	local drawCount = self.drawCount
	-- 为点旁边加速 添加的变量
	local i = 5
	self:enableSchedule():unSchedule(tag)
	self:enableSchedule():schedule(function ()
		i = i + 1
		if not self.isShowHero and i >= self.initItemTime then
			i = 0
			self.isStartItem = true
			self.listview:jumpToBottom()
			count = count + 1
			local info = items[count]
			local cfg = info[1] and dataEasy.getCfgByKey(info[1]) or {}
			if self.selectHero then
				info = {new = true, dbid = self.choosed_dbid}
			elseif self:tryStackUI2choose1(info[1]) then
				count = count - 1
				self.selectHero = true
				return
			end
			local val = count % 5
			if val == 1 then
				-- 尾部
				if innerList then
					local panel = ccui.Layout:create():size(10, 245)
					-- panel:setBackGroundColorType(1)
					-- panel:setBackGroundColor(cc.c3b(200, 0, 0))
					-- panel:setBackGroundColorOpacity(100)
					innerList:pushBackCustomItem(panel)
				end
				innerList = self.innerList:clone()
				innerList:setScrollBarEnabled(false)
				self.listview:pushBackCustomItem(innerList)
				local panel = ccui.Layout:create():size(10, 245)
				-- panel:setBackGroundColorType(1)
				-- panel:setBackGroundColor(cc.c3b(200, 0, 0))
				-- panel:setBackGroundColorOpacity(100)
				innerList:pushBackCustomItem(panel)
				innerList:show()
			end
			local item = self.item:clone()
			self.selectHero = false
			local isHero, isNewHero = false, false
			local cardId
			if info.new ~= nil then
				isNewHero = info.new
				isHero = true
				local card = gGameModel.cards:find(info.dbid)
				cardId = card:read("card_id")
				cfg = csv.cards[cardId]
				local isJumpSpriteView = userDefault.getForeverLocalKey("isJumpSpriteView", false)
				local rarity = csv.unit[cfg.unitID].rarity
				if not isJumpSpriteView --[[or rarity >= gCommonConfigCsv.showCardRarityMin or (info.new and not self.hasSprite[cardId])]] then
					self.isShowHero = true
					local showBtn = nil
					if self.isFirstShowCard and self.hasMore then
						showBtn = true
						self.isFirstShowCard = false
					elseif self.isFirstShowCard and not self.hasMore then
						showBtn = false
						self.isFirstShowCard = false
					elseif not self.isFirstShowCard and self.hasMore and isJumpSpriteView then
						showBtn = false
					end
					gGameUI:stackUI("common.gain_sprite", nil, {full = true}, info, self.hasSprite, showBtn, self:createHandler("changeState"))
				end
			end
			local nameStr = cfg.name
			local label = beauty.singleTextLimitWord(nameStr, {fontSize = 40}, {width = 240})
				:xy(94, -60)
				:addTo(item:get("item"), 2)
			text.addEffect(label, {color = ui.COLORS.NORMAL.DEFAULT})
			item:get("item"):get("textName"):visible(false)
			item:get("item"):get("imgNew"):visible(isNewHero)
			bind.extend(self, item:get("item"), {
				class = "icon_key",
				props = {
					data = {
						key = isHero and "card" or info[1],
						num = isHero and cardId or info[2],
					},
					effect = "drawcard",
					onNode = function(panel)
						panel:scale(1.25)
					end,
				},
			})
			item:hide()
			innerList:pushBackCustomItem(item)
			local listItem = item:clone()
			listItem:xy(1258, 200)
			self.actionPanel:add(listItem)
			listItem:show()
			val = val == 0 and 5 or val
			local listx, listy = self.listview:xy()
			local pos = self.listview:getParent():convertToWorldSpace(cc.p(listx, listy))
			pos = self.actionPanel:convertToNodeSpace(pos)
			local margin = self.innerList:getItemsMargin()
			local listMargin = self.listview:getItemsMargin()
			local itemSize = self.item:size()
			local innerSize = self.innerList:size()
			local x = (pos.x + 10 + margin + itemSize.width / 2) + (val - 1) * (itemSize.width + margin)
			local y = pos.y + innerSize.height / 2
			if count <= 5 then
				y = pos.y + innerSize.height / 2 + innerSize.height + listMargin
			end
			if len == 1 then
				x, y = 1258, 520
				listItem:xy(x, y)
				innerList:setTouchEnabled(false)
				self.listview:setTouchEnabled(false)
				self.listview:xy(self.originListPos.x + 10 + margin * 2 + itemSize.width * 2, self.originListPos.y - innerSize.height * 0.5)
			end

			self:playAction(listItem, cc.p(x, y), function()
				listItem:removeFromParent()
				if drawCount ~= self.drawCount then return end
				item:show()
				local state = count >= len
				self.isShowBtn:set(state)
				self.isFirstShowCard = count >= len
				if count >= len then
					userDefault.setForeverLocalKey("isJumpSpriteView", false)
					if self.drawType == "equip" then
						self.equipOtherShow:set(string.format(gLanguageCsv.getOtherItemNum, items.equip_awake_frag))
						adapt.oneLineCenterPos(cc.p(400, 25), {self.equiTextNote, self.equipImgIcon})
						self.equipPanel:show()
					end
				end
			end)
		end

		return not (count == len)
	end, 0.01, 0, tag)
end

function DrawCardResultView:selectSprite(dbid)
	self.choosed_dbid = dbid
	self.isShowHero = false
end

function DrawCardResultView:changeState()
	self.isShowHero = false
end

function DrawCardResultView:tryStackUI2choose1(id)
	if not id then
		return
	end
	if drawCardTools.is2choose1item(id) then
		self.isShowHero = true
		gGameUI:stackUI("city.drawcard.choose", nil, nil, id, self:createHandler("selectSprite"))
		return true
	end
end

function DrawCardResultView:playAction(node, perPos, func)
	if not func then
		func = function()
			self.isShowBtn:set(true)
		end
	end
	node:scale(0)
	node:stopAllActions()
	transition.executeSequence(node)
		:moveTo(0.1, perPos.x, perPos.y)
		:func(func)
		:done()

	transition.executeSequence(node)
		:rotateTo(0.1, 720)
		:done()

	transition.executeSequence(node)
		:scaleTo(0.1, 1)
		:done()
end

function DrawCardResultView:onClose()
	userDefault.setForeverLocalKey("isJumpSpriteView", false)
	local closeCb = self.closeCb
	ViewBase.onClose(self)
	if closeCb then
		closeCb()
	end
end

return DrawCardResultView