-- @date 2021-03-11
-- @desc 走格子-小店界面

local gridWalkTools = require "app.views.city.activity.grid_walk.tools"
local ViewBase = cc.load("mvc").ViewBase
local GridWalkShop = class("GridWalkShop", Dialog)

GridWalkShop.RESOURCE_FILENAME = "grid_walk_shop.json"
GridWalkShop.RESOURCE_BINDING = {
	["btnClose"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onTouchClose")},
		},
	},
	["txt"] = {
		binds = {
			event = "effect",
			data = {outline = {color = cc.c3b(107, 131, 60)}},
		},
	},
	["txt1"] = {
		binds = {
			event = "effect",
			data = {outline = {color = cc.c3b(242, 81, 97), size = 6}},
		},
	},
	["item"] = "item",
	["list"] = {
		varname = "list",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("shopDatas"),
				item = bindHelper.self("item"),
				onItem = function(list, node, k, v)
					local childs = node:multiget("title", "num", "icon", "price", "costIcon")
					local key, val = csvNext(v.items)
					local cfg = dataEasy.getCfgByKey(key)
					childs.icon:texture(cfg.icon)
					childs.title:text(cfg.name)
					childs.num:text("x" .. val)
					local key1, val1 = csvNext(v.prices)
					childs.costIcon:texture(dataEasy.getIconResByKey(key1))
					childs.price:text(val1)
					text.addEffect(childs.price, {glow = {color = ui.COLORS.GLOW.WHITE}})
					adapt.oneLineCenterPos(cc.p(node:width()/2, childs.costIcon:y()), {childs.costIcon, childs.price}, cc.p(20, 0))
					bind.touch(list, node, {methods = {ended = functools.partial(list.clickBuy, k, v)}})
				end,
				onAfterBuild = function(list)
					list:setItemAlignCenter()
				end
			},
			handlers = {
				clickBuy = bindHelper.self("onBuyClick"),
			},
		},
	},
	["panel1.txt"] = {
		binds = {
			event = "text",
			idler = bindHelper.self("iconNum"),
		},
	},
	["panel2.txt"] = {
		binds = {
			event = "text",
			idler = bindHelper.self("djqNum"),
		},
	},
}

function GridWalkShop:onCreate(params)
	local event = params.event
	self.iconNum = params.iconNum
	self.djqNum = idler.new(dataEasy.getNumByKey(gridWalkTools.ITEMS.voucher))
	self.callBack = params.callBack
	-- 第几个事件
	self.index = params.index
	self:initModel()
	self.shopDatas = idlers.new()

	local data = {}
	for i=0, 3 do
		local outcome = event.params["outcome"..i]
		if outcome > 0 then
			local cfg = csv.yunying.grid_walk_shop[outcome]
			table.insert(data, {csvID = outcome, cfg = cfg, items = cfg.items, prices = cfg.prices})
		end
	end
	self.shopDatas:update(data)
end

function GridWalkShop:initModel()
	self.gridWalk = gGameModel.role:read("grid_walk")
	self.shopDatas = idlers.new()
	self.num = idler.new(1)
end

function GridWalkShop:onBuyClick(list, k, v)
	-- 如果自己有代金券，则显示选择框，没有则直接显示价格框
	local count =  dataEasy.getNumByKey(gridWalkTools.ITEMS.voucher)
	local key, val = csvNext(v.items)
	self.num:set(v.csvID)
	if count > 0 and v.cfg.type == 1 then
		local priceKey, priceVal = csvNext(v.prices)
		local selectMap = {[gridWalkTools.ITEMS.voucher] = 1, [priceKey] = priceVal}
		gGameUI:stackUI("common.buy_info", nil, nil,
			v.prices,
			{id = key, num = val},
			{selectMap = selectMap},
			self:createHandler("selectCallBack")
		)
	else
		gGameUI:stackUI("common.buy_info", nil, nil,
			v.prices,
			{id = key, num = val},
			nil,
			self:createHandler("onlySendBuy")
		)
	end
end

function GridWalkShop:onlySendBuy(num)
	self:sendBuy()
end

function GridWalkShop:selectCallBack(num, selectID)
	self:sendBuy(selectID == 1, false)
end

function GridWalkShop:sendBuy(isUsed, isclose)
	if isUsed == nil then
		isUsed = false
	end
	local itemID = isclose and 0 or self.num:read()
	gGameApp:requestServer("/game/yy/gridwalk/shop", function(tb)
		gGameUI:showGainDisplay(tb.view.awards, {cb = function ()
			local iconOffset = 0
			if not isUsed and not isclose then
				local cfg = csv.yunying.grid_walk_shop[itemID]
				local prices = cfg.prices
				local priceKey, priceVal = csvNext(prices)
				if priceKey == gridWalkTools.BADGE_ID then
					iconOffset = priceVal
				end
			end
			self:onClose(isclose and 0 or 1, tb.view.effTreasure, tb.view.awards, iconOffset)
		end})
	end, self.gridWalk.yy_id, itemID, isUsed, self.index - 1)
end

function GridWalkShop:onTouchClose()
	gGameUI:showDialog({
		content = gLanguageCsv.gridWalkShopTips,
		cb = function()
			self:sendBuy(nil, true)
		end,
		btnType = 2,
	})
end

function GridWalkShop:onClose(hasBuy, effTreasure, awards, iconOffset)
	local params = {hasBuy = hasBuy == 1, awards = awards, effTreasure = effTreasure, iconOffset = iconOffset}
	self:addCallbackOnExit(functools.partial(self.callBack, params))
	ViewBase.onClose(self)
end

return GridWalkShop