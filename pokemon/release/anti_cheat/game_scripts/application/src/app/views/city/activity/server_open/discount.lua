-- @Date:   2019-05-28
-- @Desc:
-- @Last Modified time: 2019-9-10 16:51:02
local STATE_TYPE = {
	canReceive = 1,
	noReach = 2,
	received = 3,
}
local ServerOpenDiscountView = class("ServerOpenDiscountView", cc.load("mvc").ViewBase)
ServerOpenDiscountView.RESOURCE_FILENAME = "activity_server_open_discount.json"
ServerOpenDiscountView.RESOURCE_BINDING = {
	["newPrice.num"] = "newNum",
	["oldPrice.num"] = "oldNum",
	["item"] = "item",
	["list"] = {
		varname = "list",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("datas"),
				item = bindHelper.self("item"),
				margin = 20,
				onItem = function(list, node, k, v)
					bind.extend(list, node, {
						class = "icon_key",
						props = {
							data = v,
							onNode = function(panel)
								panel:y(210)
							end
						},
					})
					if matchLanguage({"en"}) then
						node:get("name"):setContentSize(220, 130)
					end
					node:get("name"):text(uiEasy.setIconName(v.key))
					node:get("name"):getVirtualRenderer():setLineSpacing(-10)
					text.addEffect(node:get("name"), {outline = {color = ui.COLORS.OUTLINE.WHITE}})
				end,
				onAfterBuild = function(list)
					list:setItemAlignCenter()
				end
			},
		},
	},
	-- ["day"] = "day",
	-- ["time"] = "time",
	["buyBtn"] = {
		varname = "buyBtn",
		binds = {
			event = "touch",
			clicksafe = true,
			methods = {ended = bindHelper.self("onBuy")}
		}
	},
	["txt"] = {
		varname = "txt",
		binds = {
			{
				event = "effect",
				data = {outline = {color = cc.c4b(255,238,204,255), size = 4}, color = cc.c4b(166,141,116,255)}
			},
		}
	}
}

function ServerOpenDiscountView:onCreate(activityId, data, params, isFirst)
	self.activityId = activityId

	self.currDay, self.showTab, self.tabIndex = params()
	self:initModel()
	self.data = data
	self.datas = idlertable.new({})
	self.originX = self.list:x()

	idlereasy.any({self.currDay, self.showTab, self.yyhuodongs, self.tabIndex}, function (_, day, index, yyhuodongs, tabIndex)
		if tabIndex == -1 then
			return
		end
		local yydata = yyhuodongs[self.activityId] or {}
		local valinfo = yydata.valinfo or {}
		local data = self.data[index][tabIndex]
		if data then
			local key, value = csvNext(data[1].cfg.costMap)
			self.newNum:text(value)
			key, value = csvNext(data[1].cfg.priceShow)
			self.oldNum:text(value)
			local itemData = {}
			for k, v in csvMapPairs(data[1].cfg.award) do
				if k == "cards" then
					for _, id in ipairs(v) do
						table.insert(itemData, {key = "card", num = id})
					end
				else
					table.insert(itemData, {key = k, num = v})
				end
			end
			self.datas:set(itemData)
			local countType = data[1].cfg.countType
			-- self:countDown(data[1].cfg.countType, day, index)
			self.txt:text(string.format(gLanguageCsv.activityBuyLimit, 0, data[1].cfg.buyMax))
			if valinfo[data[1].id] and valinfo[data[1].id].times and valinfo[data[1].id].times > 0 then
				cache.setShader(self.buyBtn, false, "hsl_gray")
				self.txt:text(string.format(gLanguageCsv.activityBuyLimit, 1, data[1].cfg.buyMax))
				self.buyBtn:get("label"):text(gLanguageCsv.sellout)
				self.buyBtn:setTouchEnabled(false)
			elseif index > day then
				cache.setShader(self.buyBtn, false, "hsl_gray")
				self.buyBtn:get("label"):text(gLanguageCsv.rushToPurchase)
				self.buyBtn:setTouchEnabled(false)
			elseif countType ~= 2 and index <= day then
				cache.setShader(self.buyBtn, false, "normal")
				self.buyBtn:get("label"):text(gLanguageCsv.rushToPurchase)
				self.buyBtn:setTouchEnabled(true)
			elseif countType == 2 and day > index then
				cache.setShader(self.buyBtn, false, "hsl_gray")
				self.buyBtn:get("label"):text(gLanguageCsv.overdue)
				self.buyBtn:setTouchEnabled(false)
			elseif countType == 2 and day == index then
				cache.setShader(self.buyBtn, false, "normal")
				self.buyBtn:get("label"):text(gLanguageCsv.rushToPurchase)
				self.buyBtn:setTouchEnabled(true)
			end
		end
	end, "discount")
end

function ServerOpenDiscountView:initModel()
	self.yyhuodongs = gGameModel.role:getIdler("yyhuodongs")
	self.yyEndtime = gGameModel.role:read("yy_endtime")
	self.rmb = gGameModel.role:getIdler("rmb")
end
-- function ServerOpenDiscountView:countDown(countType, currDay, currIndex)
-- 	self:enableSchedule():unSchedule(2)
-- 	local countdown
-- 	if countType == 2 and currDay == currIndex then
-- 		local beginTime = csv.yunying.yyhuodong[self.activityId].beginTime/ 100
-- 		local currDay = time.getTodayStrInClock(beginTime)
-- 	    countdown = time.getNumTimestamp(currDay, beginTime) + 60 * 60 * 24 - time.getTime()
-- 	elseif countType == 1 then
-- 		countdown = self.yyEndtime[self.activityId] - time.getTime()
-- 	else
-- 		-- self.day:text(0)
-- 		-- self.time:text("00:00:00")
-- 		return
-- 	end
-- 	self:schedule(function()
-- 		countdown = countdown - 1
-- 		local t = time.getCutDown(countdown)
-- 		-- self.day:text(countdown > 0 and t.day or 0)
-- 		-- self.time:text(countdown > 0 and t.str or "00:00:00")
-- 		if countdown <= 0 then
-- 			return false
-- 		end
-- 	end, 1, 1, 2)
-- end

function ServerOpenDiscountView:onBuy()
	local data = self.data[self.showTab:read()][self.tabIndex:read()][1]
	local key, value = csvNext(data.cfg.costMap)
	if value > self.rmb:read() then
		uiEasy.showDialog("rmb")
	else
		local content = string.format(gLanguageCsv.serverOpenDiscount, value)
		gGameUI:showDialog({content = dataEasy.getTextScrollStrs(content),
			cb = function()
				gGameApp:requestServer("/game/yy/award/get", function(tb)
					gGameUI:showGainDisplay(tb)
				end, self.activityId, data.id)
			end,
			btnType = 2,
			isRich = true,
			dialogParams = {clickClose = false},
			clearFast = true,
		})
	end
end

return ServerOpenDiscountView