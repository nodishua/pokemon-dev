-- @date 2021-03-10
-- @desc 礼券商店

-- 可购买，刷新中，售罄
local STATE_TYPE = {
	canbuy = 1,
	refresh = 2,
	sellout = 3,
}

local CouponShop = class("CouponShop",cc.load("mvc").ViewBase)

CouponShop.RESOURCE_FILENAME = "coupon_shop.json"
CouponShop.RESOURCE_BINDING = {
	["time"] = "time",
    ------------------------------------couponPanel----------------------------------------
    ["couponPanel.text"] = "couponText",
	-----------------------------------singlePanel----------------------------------------
	["singlePanel"] = "singlePanel",
	["singlePanel.subList"] = "singleSublist",
	["singlePanel.item"] = "singleItem",
	["singlePanel.centerList"] = {
		varname = "singleList",
		binds = {
			event = "extend",
			class = "tableview",
			props = {
				data = bindHelper.self("singleDatas"),
				item = bindHelper.self("singleSublist"),
				cell = bindHelper.self("singleItem"),
				columnSize = 4,
				asyncPreload = 12,
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
				onCell = function(list, node, k, v)
					local cfg = v.cfg
					local childs = node:multiget("title", "tip", "mask", "item", "icon","num","btnBuy")
					local name, effect = uiEasy.setIconName(v.id, v.num)
					childs.title:text(name)
					if matchLanguage({"en", "kr"}) then
						adapt.setTextAdaptWithSize(childs.title, {size = cc.size(node:width() - 150, 120), vertical = "center", horizontal = "center", margin = -5, maxLine= 2})
					end
					text.addEffect(childs.title, effect)
					--显示限购
					if cfg.refresh then
						childs.tip:text(string.format(gLanguageCsv.directBuyGiftDailyBuy, v.leftTimes, cfg.buyMax))
					else
						childs.tip:text(string.format(gLanguageCsv.directBuyGiftOnetimeBuy, v.leftTimes, cfg.buyMax))
						text.addEffect(childs.tip, {color=ui.COLORS.QUALITY[4]})
					end
					--icon 图标
					bind.extend(list, childs.icon, {
						class = "icon_key",
						props = {
							data = {
								key = v.id,
								num = v.id == "card" and v.num or nil,
							},
							onNode = function(node)
								node:scale(1.2)
							end,
							simpleShow = true,
						},
					})
					if v.id ~= "card" then
						childs.num:text("x"..v.num):show()
					else
						childs.num:hide()
					end
					local btn = childs.btnBuy
					local price = childs.btnBuy:get("text")
					local coupon = childs.btnBuy:get("coupon")
					btn:setTouchEnabled(false)
					cache.setShader(btn, false, "normal")
					price:text(v.costNum)
					local iconSize = coupon:getBoundingBox()
					local txtSize = price:size()
					coupon:x(btn:width()/2 - iconSize.width - txtSize.width/2 + 20)
					adapt.oneLinePos(coupon, price, cc.p(10, 0), "left")
					if v.state == STATE_TYPE.canbuy then
						childs.mask:hide()
						btn:setTouchEnabled(true)
						bind.touch(list, btn, {clicksafe = true, methods = {ended = functools.partial(list.clickCell, k, v)}})
						text.addEffect(price, {outline = {color = cc.c4b(129,61,45,25),  size = 10}, color = ui.COLORS.NORMAL.WHITE, glow={color=ui.COLORS.GLOW.WHITE}})
					else
						childs.mask:show()
						cache.setShader(btn, false, "hsl_gray")
						text.deleteAllEffect(price)
						text.addEffect(price, {color = ui.COLORS.DISABLED.WHITE})
						if v.state == STATE_TYPE.sellout then
							childs.mask:get("label"):text(gLanguageCsv.sellout)
						else
							childs.mask:get("label"):text(gLanguageCsv.nextDayRefresh5)
						end
					end
					list:setRenderHint(0)
				end,
			},
			handlers = {
				clickCell = bindHelper.self("onBuyClick"),
			},
		},
	}
}

function CouponShop:onCreate(activityId)
	self.activityId = activityId
	self:initTitle()
	self:initModel()
	self:initCountDown()
	self:initData()
	self.couponNum = 0

	local yyCfg = csv.yunying.yyhuodong[self.activityId]
	local huodongID = yyCfg.huodongID

	-- 客户端模拟购买次数变动了通知
	self.clientBuyTimes = idler.new(true)
	idlereasy.any({self.yyhuodongs, self.clientBuyTimes}, function(_, yyhuodongs, clientBuyTimes)
		local yydata = yyhuodongs[self.activityId] or {}
		local stamps = yydata.stamps or {}
		local datas = {}
		for k, v in csvPairs(csv.yunying.itembuy2) do
			if v.huodongID == huodongID then
				local state = STATE_TYPE.canbuy
				local leftTimes = math.max(0, v.buyMax - (stamps[k] or 0))
				if leftTimes == 0 then
					if v.refresh then
						state = STATE_TYPE.refresh
					else
						state = STATE_TYPE.sellout
					end
				end
				local id, num = csvNext(v.item)
				local costId, costNum = csvNext(v.costMap)
				table.insert(datas, {csvId = k, id = id, num = num, costId = costId, costNum = costNum, cfg = v, state = state, leftTimes = leftTimes})
			end
		end
		table.sort(datas, function(a, b)
			if a.state ~= b.state then
				return a.state < b.state
			end
			return a.csvId < b.csvId
		end)
		dataEasy.tryCallFunc(self.singleList, "updatePreloadCenterIndex")
		self.singleDatas:update(datas)

		local couponNum = dataEasy.getNumByKey(self.itemID)

		self.couponNum = couponNum
		self.couponText:text(self.couponNum)
	end)
end

function CouponShop:initModel()
	self.yyhuodongs = gGameModel.role:getIdler("yyhuodongs")
	self.yyOpen = gGameModel.role:getIdler('yy_open')
	self.singleDatas = idlers.new()
end


function CouponShop:initData()
	self.itemID = 6393
end

function CouponShop:initTitle()
	gGameUI.topuiManager:createView("title", self, {onClose = self:createHandler("onClose")})
		:init({title = gLanguageCsv.couponShop, subTitle = "ACTIVITY SHOP"})
end

function CouponShop:onBuyClick(list, k, v)
	if self.couponNum < v.cfg.costMap[v.costId] then
		uiEasy.showDialog(self.itemID)
		return
	end
	gGameUI:stackUI("common.buy_info", nil, nil,
		v.cfg.costMap,
		{id = v.id, num = v.num},
		{maxNum = v.leftTimes, contentType = "slider", style = 2},
	    self:createHandler("getBuyInfoCb", v.csvId)
	)
end

function CouponShop:getBuyInfoCb(csvId, num)
	gGameApp:requestServer("/game/yy/award/get", function(tb)
		gGameUI:showGainDisplay(tb)
	end, self.activityId, csvId, num)
end

--倒计时
function CouponShop:initCountDown()
	local textTime = self.time
	local endTime = gGameModel.role:read("yy_endtime")[self.activityId] or 0
	bind.extend(self, textTime, {
		class = 'cutdown_label',
		props = {
			endTime = endTime,
			endFunc = function()
				self.time:text(gLanguageCsv.activityOver)
			end,
		}
	})
end

return CouponShop