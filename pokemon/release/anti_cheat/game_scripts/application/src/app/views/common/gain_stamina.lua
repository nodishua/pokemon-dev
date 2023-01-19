-- @date: 2018-11-18
-- @desc: 购买体力

local MonthCardView = require "app.views.city.activity.month_card"
local ViewBase = cc.load("mvc").ViewBase
local GainStaminaView = class("GainStaminaView", Dialog)

GainStaminaView.RESOURCE_FILENAME = "common_gain_stamina.json"
GainStaminaView.RESOURCE_BINDING = {
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
			idler = bindHelper.self("staminaBuyRecover")
		},
	},
	["content.doublePanel"] = "doublePanel",
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
	["downPanel"] = "downPanel",
	["downPanel.item"] = "item",
	["downPanel.list"] = {
		varname = "list",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("staminaItem"),
				dataOrderCmp = function (a, b)
					if a.quality ~= b.quality then
						return a.quality < b.quality
					else
						return a.staminanum < b.staminanum
					end
				end,
				item = bindHelper.self("item"),
				asyncPreload = 6,
				onItem = function(list, node, k, v)
					bind.extend(list, node:get("icon"), {
						class = "icon_key",
						props = {
							data = {
								key = v.key,
								num = v.num,
							},
							onNode = function (node)
								bind.click(list, node, {method =  functools.partial(list.clickCell, k, v)})
								-- list:setItemAlignCenter()
							end
						},
					})
				end,
				onAfterBuild = function(list)
					list:setItemAlignCenter()
				end
			},
			handlers = {
				clickCell = bindHelper.self("onItemClick"),
			},
		},
	},
}

function GainStaminaView:onCreate()
	self:initModel()

	self.price = idler.new(0)
	self.staminaBuyRecover = idler.new(gCommonConfigCsv.staminaBuyRecover)
	self.staminaItem = idlers.newWithMap({})

	self.content:get("multiple"):hide()
	adapt.oneLineCenterPos(cc.p(775, 400), {self.content:get("icon"), self.content:get("num")})

	-- 如果vip达到上限，且今日购买次数已用完，则返回-1
	self.leftTimes = idlereasy.any({self.vipLevel, self.buyStaminaTimes, self.trainerLevel}, function(_, vipLevel, buyStaminaTimes, trainerLevel)
		local times = gVipCsv[vipLevel].buyStaminaTimes + dataEasy.getPrivilegeVal(game.PRIVILEGE_TYPE.StaminaBuyTimes)
		local leftTimes = self:refreshNumPanel(buyStaminaTimes, times)
		if leftTimes == 0 and vipLevel >= game.VIP_LIMIT then
			leftTimes = -1
		end
		local costSeq = clone(gCostCsv.stamina_buy_cost)
		local staminaBuyFreeTimes = MonthCardView.getPrivilegeAddition("staminaBuyFreeTimes")
		if staminaBuyFreeTimes then
			for i = 1, staminaBuyFreeTimes do
				table.insert(costSeq, 1, 0)
			end
		end
		local num = math.min(buyStaminaTimes + 1, table.length(costSeq))
		self.price:set(costSeq[num])
		return true, leftTimes
	end)
	idlereasy.any({self.price, self.rmb}, function(_, price, rmb)
		self.priceText:text(price)
		local color = rmb < price and ui.COLORS.NORMAL.RED or ui.COLORS.NORMAL.DEFAULT
		text.addEffect(self.priceText, {color=color})
		adapt.oneLinePos(self.priceText, self.priceNote, cc.p(10, 0), "right")
		adapt.oneLinePos(self.priceText, self.priceIcon, cc.p(10, 0))
	end)

	local item = csv.items
	local id = 0
	idlereasy.any({self.items}, function(_, items)
		local staminaItem = {}
		for k, v in pairs(items) do
			id = id + 1
			if item[k].specialArgsMap.stamina then
				table.insert(staminaItem, {key = k, num = v, quality = item[k].quality, staminanum = item[k].specialArgsMap.stamina})
			end
		end
		self.staminaItem:update(staminaItem)
		local staminaItemBool = itertools.isempty(staminaItem)
		if staminaItemBool then
			self.downPanel:hide()
		end
	end)


	Dialog.onCreate(self, {clickClose = false})
end

function GainStaminaView:refreshNumPanel(buyStaminaTimes, times)
	local leftTimes = times - buyStaminaTimes
	self.leftTimes1:text(leftTimes)
	local color = leftTimes > 0 and cc.c4b(116, 190, 109, 255) or ui.COLORS.NORMAL.DEFAULT
	text.addEffect(self.leftTimes1, {color=color})
	self.leftTimes2:text("/" .. times)
	adapt.oneLinePos(self.leftTimes1, self.leftTimes2)

	local isDouble, paramMaps = dataEasy.isDoubleHuodong("buyStamina")

	self.doublePanel:visible(isDouble)

	if isDouble then
		local text1 = self.doublePanel:get("text1")
		local text2 = self.doublePanel:get("text2")
		local text3 = self.doublePanel:get("text3")
		local maxTimes = paramMaps[1].count or 0 -- 只读取第一个
		local showCount = math.max(maxTimes - buyStaminaTimes, 0)
		color = showCount == 0 and ui.COLORS.NORMAL.ALERT_ORANGE or cc.c4b(116, 190, 109, 255)
		text.addEffect(text2, {color = color})
		text2:text(showCount)
		text3:text(string.format("/%s)", maxTimes))
		adapt.oneLinePos(text1, {text2, text3}, cc.p(0,0))
	end
	return leftTimes
end

function GainStaminaView:initModel()
	self.rmb = gGameModel.role:getIdler("rmb")
	self.roleLevel = gGameModel.role:getIdler("level")
	self.vipLevel = gGameModel.role:getIdler("vip_level")
	self.buyStaminaTimes = gGameModel.daily_record:getIdler("buy_stamina_times")
	self.stamina = gGameModel.role:getIdler("stamina")
	self.trainerLevel = gGameModel.role:getIdler("trainer_level")
	self.items = gGameModel.role:getIdler("items")
end

function GainStaminaView:onBuyItem()
	idlereasy.do_(function(stamina, leftTimes, rmb, price)
		local sureBuy = function()
			dataEasy.sureUsingDiamonds(function ()
				gGameApp:requestServer("/game/role/stamina/buy", function(tb)
					gGameUI:showTip(gLanguageCsv.staminaBuySuccess)
				end)
			end, price)
		end
		if stamina >= game.STAMINA_LIMIT then
			gGameUI:showTip(gLanguageCsv.staminaLimitToUse)

		elseif leftTimes == -1 then
			-- 已上限，明日再来
			gGameUI:showTip(gLanguageCsv.commonVipMax, gLanguageCsv.staminaBuy)

		elseif leftTimes == 0 then
			-- 已上限，提升vip
			uiEasy.showDialog("vip", {titleName = gLanguageCsv.staminaBuy}, {dialog = true})

		elseif rmb < price then
			uiEasy.showDialog("rmb", nil, {dialog = true})
		elseif (gCommonConfigCsv.staminaBuyRecover + gGameModel.role:read("stamina")) > game.STAMINA_LIMIT then
			local params = {
				cb = sureBuy,
				isRich = true,
				btnType = 2,
				content = gLanguageCsv.buyEnergyOverflowTips,
			}
			gGameUI:showDialog(params)
		else
			sureBuy()
		end
	end, self.stamina, self.leftTimes, self.rmb, self.price)
end

function GainStaminaView:onItemClick(list, k, v)
	if self.stamina:read() >= game.STAMINA_LIMIT then
		gGameUI:showTip(gLanguageCsv.staminaFull)
		return
	end
	if v.num <= 1 then
		self:onUseCb(v.key, v.num)
		return
	end

	gGameUI:stackUI("common.buy_info", nil, nil,
		nil,
		{id = v.key},
		{num = self:createHandler("num"), maxNum = v.num, flag = "use", contentType = "slider", style = 2},
		self:createHandler("onUseCb", v.key)
	)
end

function GainStaminaView:onUseCb(id, num)
	gGameApp:requestServer("/game/role/stamina/use_item", function(tb)
		gGameUI:showTip(gLanguageCsv.useSuccess)
	end, id, num)
end

return GainStaminaView
