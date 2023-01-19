-- @date 2018-12-23
-- @desc 直购礼包

-- 可购买，刷新中，售罄
local STATE_TYPE = {
	canbuy = 1,
	refresh = 2,
	sellout = 3,
}

local ActivityBuyGiftView = class("ActivityBuyGiftView", cc.load("mvc").ViewBase)

ActivityBuyGiftView.RESOURCE_FILENAME = "direct_buy_gift.json"
ActivityBuyGiftView.RESOURCE_BINDING = {
	["item"] = "item",
	["list"] = {
		varname = "list",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("datas"),
				item = bindHelper.self("item"),
				itemAction = {isAction = true},
				dataOrderCmp = function(a, b)
					if a.state ~= b.state then
						return a.state < b.state
					end
					if a.sort ~= b.sort then
						return a.sort < b.sort
					end
					return a.csvId < b.csvId
				end,
				onItem = function(list, node, k, v)
					local cfg = v.cfg
					local childs = node:multiget("title", "times", "bottomPanel", "mask", "list", "subList", "item")
					childs.title:text(cfg.name)
					if cfg.refresh then
						childs.times:text(string.format(gLanguageCsv.directBuyGiftDailyBuy, v.leftTimes, cfg.limit))
						text.addEffect(childs.times, {color=ui.COLORS.QUALITY[5]})
					else
						local hint = gLanguageCsv.directBuyGiftOnetimeBuy
						if v.status == 1 then
							hint = gLanguageCsv.directBuyGiftWeek
						elseif v.status == 2 then
							hint = gLanguageCsv.directBuyGiftMonth
						end
						childs.times:text(string.format(hint, v.leftTimes, cfg.limit))
						text.addEffect(childs.times, {color=ui.COLORS.QUALITY[4]})
					end
					childs.list:removeAllChildren()
					childs.list:setScrollBarEnabled(false)
					childs.list:setGravity(ccui.ListViewGravity.bottom)
					local subList = nil
					local idx = 0
					local len = csvSize(cfg.item)
					local dx = len == 1 and childs.item:size().width/2 or 0
					for _, itemData in ipairs(dataEasy.getItemData(cfg.item)) do
						local id = itemData.key
						local num = itemData.num
						idx = idx + 1
						if idx % 2 == 1 then
							subList = childs.subList:clone():show():tag(math.floor(idx/2 + 1))
							subList:setScrollBarEnabled(false)
							subList:setTouchEnabled(false)
							childs.list:pushBackCustomItem(subList)
						end
						local item = childs.item:clone():show()
						local size = item:size()
						bind.extend(list, item, {
							class = "icon_key",
							props = {
								data = {
									key = id,
									num = num,
								},
								onNode = function(node)
									node:xy(size.width/2 + dx, size.height/2)
										:scale(0.9)
								end,
							},
						})
						subList:pushBackCustomItem(item)
					end
					childs.list:adaptTouchEnabled()
						:setItemAlignCenter()
					local btn = childs.bottomPanel:get("btn")
					local price = childs.bottomPanel:get("panel"):get("price")
					local rmbIcon = childs.bottomPanel:get("panel"):get("rmb")
					rmbIcon:visible(false)
					btn:setTouchEnabled(false)
					cache.setShader(btn, false, "normal")
					if v.rmb then
						price:text(v.rmb)
						local number = 40
						if type(v.rmb) ~= "string" then
							rmbIcon:visible(true)
							price:x(rmbIcon:width()/2 + price:width()/2 + rmbIcon:x())
							number = 70
						end
						childs.bottomPanel:get("panel"):width(price:width() + rmbIcon:width())
						childs.bottomPanel:get("panel"):x(btn:x() - number)
					elseif v.price then
						price:text(string.format(gLanguageCsv.symbolMoney, v.price))
					end
					local isInfo = (v.rmb and type(v.rmb) == "string") and true or false
					if v.state == STATE_TYPE.canbuy then
						childs.mask:hide()
						btn:setTouchEnabled(true)
						bind.touch(list, btn, {clicksafe = true, methods = {ended = functools.partial(list.clickCell, k, v)}})
						text.addEffect(price, {color = ui.COLORS.NORMAL.WHITE, glow={color=ui.COLORS.GLOW.WHITE}})
					else
						childs.mask:show()
						isInfo = false
						cache.setShader(btn, false, "hsl_gray")
						text.deleteAllEffect(price)
						text.addEffect(price, {color = ui.COLORS.DISABLED.WHITE})
						if v.state == STATE_TYPE.sellout then
							childs.mask:get("label"):text(gLanguageCsv.sellout)
						else
							childs.mask:get("label"):text(gLanguageCsv.nextDayRefresh5)
						end
					end
					local props = {
						class = "red_hint",
						props = {
							state = isInfo,
							onNode = function(panel)
								panel:xy(330, 100)
							end,
						}
					}
					bind.extend(list, childs.bottomPanel, props)
				end,
				asyncPreload = 6,
			},
			handlers = {
				clickCell = bindHelper.self("onBuyClick"),
			},
		},
	},
}

function ActivityBuyGiftView:onCreate(activityId)
	self.activityId = activityId
	self:initModel()
	gGameModel.currday_dispatch:getIdlerOrigin("activityDirectBuyGift"):set(true)
	local yyCfg = csv.yunying.yyhuodong[activityId]
	local huodongID = yyCfg.huodongID
	self.datas = idlers.new()
	-- 客户端模拟购买次数变动了通知
	self.clientBuyTimes = idler.new(true)

	idlereasy.any({self.yyhuodongs, self.clientBuyTimes}, function(_, yyhuodongs)
		local yydata = yyhuodongs[activityId] or {}
		local stamps = yydata.stamps or {}
		local datas = {}
		for k, v in csvPairs(csv.yunying.directbuygift) do
			if v.huodongID == huodongID and self.level >= v.levelLimit then
				local state = STATE_TYPE.canbuy
				local buyTimes = stamps[k] or 0
				buyTimes = dataEasy.getPayClientBuyTimes("directBuyData", activityId, k, buyTimes)
				local leftTimes = math.max(0, v.limit - buyTimes)
				if leftTimes == 0 then
					if v.refresh then
						state = STATE_TYPE.refresh
					else
						state = STATE_TYPE.sellout
					end
				end
				local rmb, price, status
				status = v.status
				if v.rmbCost == 0 then
					rmb = gLanguageCsv.freeToReceive
				elseif v.rmbCost >= 1 then
					rmb = v.rmbCost
				else
					price = csv.recharges[v.rechargeID].rmbDisplay
				end
				table.insert(datas, {csvId = k, cfg = v, state = state, buyTimes = buyTimes, leftTimes = leftTimes, price = price, rmb = rmb, status = status, sort = v.sort})
			end
		end
		dataEasy.tryCallFunc(self.list, "updatePreloadCenterIndex")
		self.datas:update(datas)
	end)
end

function ActivityBuyGiftView:initModel()
	self.yyhuodongs = gGameModel.role:getIdler("yyhuodongs")
	self.level = gGameModel.role:read("level")
end

function ActivityBuyGiftView:onBuyClick(list, k, v)
	if not v.rmb then
		gGameApp:payDirect(self, {rechargeId = v.cfg.rechargeID, yyID = self.activityId, csvID = v.csvId, name = v.cfg.name, buyTimes = v.buyTimes}, self.clientBuyTimes)
			:serverCb(function()
				local cfg = csv.yunying.directbuygift[v.csvId]
				gGameUI:showGainDisplay(cfg.item, {raw = false})
			end)
			:doit()
	else
		gGameApp:requestServer("/game/yy/award/get", function(tb)
			self.clientBuyTimes:notify()
			local cfg = csv.yunying.directbuygift[v.csvId]
			gGameUI:showGainDisplay(cfg.item, {raw = false})
		end, self.activityId, v.csvId)
	end
end

return ActivityBuyGiftView