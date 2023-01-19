--
--@data 2019-8-9 14:31:21
--desc 神秘商店界面(没有限购和隐藏功能版本)
--

local MonthCardView = require "app.views.city.activity.month_card"

local function onInitItem(list, node, k, v)
	node:get("imgIcon"):hide()
	node:get("imgFrag"):hide()
	bind.extend(list, node, {
		class = "icon_key",
		props = {
			data = {
				key = v.itemId,
			},
			simpleShow = true,
			specialKey = {
				maxStar = true,
			},
			onNode = function(panel)
				panel:setTouchEnabled(false)
				panel:xy(node:get("imgIcon"):xy())
					:scale(1.5)
					:z(2)
			end,
		},
	})

	local cfg = csv.mystery_shop[v.csvId]
	local number = cfg.itemCount
	node:get("textNum"):text("x" .. number)
	local costType, costNum = csvNext(cfg.costMap)
	local discount = 1 - (MonthCardView.getPrivilegeAddition("mysteryShopDiscount") or 0)
	local path = dataEasy.getIconResByKey(costType)
	node:get('btnBuy.icon'):texture(path)
	node:get('btnBuy.txt'):text(math.ceil(tonumber(costNum) * discount))
	adapt.oneLineCenterPos(cc.p(162, 55), {node:get('btnBuy.icon'), node:get('btnBuy.txt')}, cc.p(10, 0))
	uiEasy.setIconName(v.itemId, cfg.itemCount, {node = node:get("textName")})
	local limitNum = cfg.limitTimes
	local leftNum = v.leftNum
	if limitNum > 0 then
		node:get("textLimiteNum"):text(leftNum .. "/" ..limitNum)
		local color = ui.COLORS.NORMAL.FRIEND_GREEN
		if leftNum == 0 then
			color = ui.COLORS.NORMAL.ALERT_ORANGE
		end
		text.addEffect(node:get("textLimiteNum"), {color = color})
	end
	node:get("textLimiteNote"):visible(limitNum > 0)
	node:get("textLimiteNum"):visible(limitNum > 0)
	local discountDesc = cfg.discountDesc
	if discountDesc == "" and discount < 1 then
		if matchLanguage({"kr", "en"}) then
			discountDesc = string.format(gLanguageCsv.discount, tostring((1 - discount)*100))
		else
			discountDesc = string.format(gLanguageCsv.discount, discount * 10)
		end
	end
	node:get("flag"):visible(string.len(discountDesc) > 0)
	node:get("flag.textVal"):text(discountDesc)
	if matchLanguage({"kr", "en"}) then
		adapt.setTextScaleWithWidth(node:get("flag.textVal"), nil, 90)
	end
	local buyVip = cfg.vipStart
	local lvRange = cfg.levelRange
	node:get("lock"):visible(leftNum == 0)
	node:setTouchEnabled(true)
	if leftNum == 0 then
		node:setTouchEnabled(false)
		node:get("lock.textLock"):text(gLanguageCsv.sellout)
		node:get("lock.textLock"):x(207)
		node:get("lock.imgLock"):visible(false)
		node:get("lock.textTip"):visible(false)

	elseif buyVip > list.vip():read() or lvRange[1] > list.roleLv():read() then
		node:setTouchEnabled(false)
		node:get("lock.imgLock"):visible(true)
		node:get("lock.textLock"):text(gLanguageCsv.notUnlock)
		adapt.oneLinePos(node:get("lock.imgLock"), node:get("lock.textLock"))
		node:get("lock.textTip"):text(string.format(gLanguageCsv.levelAndVip, lvRange[1], buyVip))
	end
end

local ViewBase = cc.load("mvc").ViewBase
local MysteryShopView = class("MysteryShopView", ViewBase)

MysteryShopView.RESOURCE_FILENAME = "mystery_shop.json"
MysteryShopView.RESOURCE_BINDING = {
	["time.textTime"] = {
		binds = {
			event = "text",
			idler = bindHelper.self("leftTime"),
		},
	},
	["info.textCostNum"] = "textCostNum",
	["info.imgIcon"] = "imgIcon",
	["info.textRefreshNum"] = {
		varname = "refreshLabel",
		binds = {
			event = "text",
			idler = bindHelper.self("refreshNum"),
		},
	},
	["info.btnRefresh"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onRefreshItems")},
		},
	},
	["item"] = "item",
	["item.textName"] = "textName",
	["innerList"] = "innerList",
	["slider"] = "slider",
	["list"] = {
		varname = "list",
		binds = {
			event = "extend",
			class = "tableview",
			props = {
				data = bindHelper.self("itemsData"),
				item = bindHelper.self("innerList"),
				cell = bindHelper.self("item"),
				columnSize = 4,
				sliderBg = bindHelper.self("slider"),
				asyncPreload = 8,
				itemAction = {isAction = true},
				onCell = function(list, node, k, v)
					onInitItem(list, node, k, v)
					bind.touch(list, node, {methods = {ended = functools.partial(list.itemClick, list:getIdx(k), v)}})
				end,
				onBeforeBuild = function(list)
					local listX, listY = list:xy()
					local listSize = list:size()
					local x, y = list.sliderBg:xy()
					local size = list.sliderBg:size()
					list:setScrollBarEnabled(true)
					list:setScrollBarColor(cc.c3b(241, 59, 84))
					list:setScrollBarOpacity(255)
					list:setScrollBarAutoHideEnabled(false)
					list:setScrollBarPositionFromCorner(cc.p(listX + listSize.width - x, (listSize.height - size.height) / 2 + 5))
					list:setScrollBarWidth(size.width)
					list:refreshView()
				end,
				asyncPreload = 10,
			},
			handlers = {
				itemClick = bindHelper.self("onItemClick"),
				roleLv = bindHelper.self("roleLv"),
				vip = bindHelper.self("vip"),
			},
		}
	},
}

function MysteryShopView:onCreate()
	self.itemsData = idlers.newWithMap({})
	self.leftTime = idler.new("")
	self.refreshNum = idler.new("")

	self:initModel()
	self:refreshDatas()

	adapt.setTextAdaptWithSize(self.textName, {size = cc.size(370, 80), vertical = "center", horizontal = "center", margin = -4, maxLine = 2})

	gGameUI.topuiManager:createView("default", self, {onClose = self:createHandler("onClose")})
		:init({title = gLanguageCsv.mysteryShop, subTitle = "MYSTERYSHOP"})

	self:enableSchedule():schedule(function()
		local isOpen, delta = uiEasy.isOpenMystertShop()
		if not isOpen then
			gGameUI:showTip(gLanguageCsv.mysteryShopClose)
			performWithDelay(self, function()
				self:onClose()
			end, 1/60)

			return false
		else
			local t = time.getCutDown(delta)
			self.leftTime:set(t.str)
		end
	end, 1, 0, 1)

	idlereasy.any({self.refreshItems, self.vip}, function(_, refreshItems, vip)
		local costTab = gCostCsv.mysteryshop_refresh_cost
		local idx = math.min(refreshItems + 1, table.length(costTab))
		local cost = self:getCostNum(refreshItems)
		self.textCostNum:text(cost)
		adapt.oneLinePos(self.textCostNum, self.imgIcon, nil, "left")
		local refreshTimes = gVipCsv[vip].mysteryRefresh
		local leftNum = refreshTimes - refreshItems
		self.refreshNum:set(leftNum .. "/" .. refreshTimes)
		local color = ui.COLORS.NORMAL.FRIEND_GREEN
		if leftNum == 0 then
			color = ui.COLORS.NORMAL.ALERT_ORANGE
		end
		text.addEffect(self.refreshLabel, {color = color})
	end)
end

function MysteryShopView:getCostNum(curTimes)
	curTimes = curTimes or self.refreshItems:read()
	local costTab = gCostCsv.mysteryshop_refresh_cost
	local idx = math.min(curTimes + 1, table.length(costTab))

	return costTab[idx]
end

function MysteryShopView:initModel()
	self.mysteryShopLastTime = gGameModel.mystery_shop:getIdler("last_active_time") -- 上次出现的时间
	self.items = gGameModel.mystery_shop:getIdler("items") -- 售卖物品
	self.refreshItems = gGameModel.mystery_shop:getIdler("refresh_times") -- 刷新次数
	self.buy = gGameModel.mystery_shop:getIdler("buy") -- 已购买下标
	self.lastTimes = gGameModel.mystery_shop:getIdler("last_times") -- 上次刷新时间
	self.vip = gGameModel.role:getIdler("vip_level")
	self.roleLv = gGameModel.role:getIdler("level")
	-- self.shopLimit = gGameModel.role:getIdler("shop_limit")
end

function MysteryShopView:refreshDatas()
	local t = {}
	for k,v in pairs(self.items:read()) do
		local cfg = csv.mystery_shop[v[1]]
		-- 目前只可购买一次
		local buyNum = self.buy:read()[k] and 1 or 0
		table.insert(t, {pos = k, csvId = v[1], itemId = v[2], leftNum = 1 - buyNum})
	end
	table.sort(t, function(a, b)
		return a.pos < b.pos
	end)
	self.itemsData:update(t)
end

function MysteryShopView:onRefreshItems()
	local refreshTimes = gVipCsv[self.vip:read()].mysteryRefresh
	if refreshTimes - self.refreshItems:read() <= 0 then
		gGameUI:showTip(gLanguageCsv.refreshTimesNotEnough)
		return
	end
	local str = string.format(gLanguageCsv.shopRefreshCommonBox, self:getCostNum())
	gGameUI:showDialog{strs = "#C0x5B545B#"..str, cb = function ()
		gGameApp:requestServer("/game/mystery/refresh", function()
			dataEasy.tryCallFunc(self.list, "setItemAction", {isAction = true})
			self:refreshDatas()
			gGameUI:showTip(gLanguageCsv.refreshSuccessful)
		end)
	end, btnType = 2, isRich = true, dialogParams = {clickClose = false}}
end

function MysteryShopView:onItemClick(list, t, v)
	if v.leftNum <= 0 then
		return
	end
	local cfg = csv.mystery_shop[v.csvId]

	local discount = 1 - (MonthCardView.getPrivilegeAddition("mysteryShopDiscount") or 0)
	gGameUI:stackUI("common.buy_info", nil, nil, cfg.costMap, {id = v.itemId, num = cfg.itemCount}, {discount = discount}, self:createHandler("buyItemCallBack", cfg, t, v))
end

function MysteryShopView:buyItemCallBack(cfg, t, v)
	gGameApp:requestServer("/game/mystery/buy", function(tb)
		gGameUI:showGainDisplay({{v.itemId, cfg.itemCount}}, {raw = false})
		self.itemsData:atproxy(t.k).leftNum = self.itemsData:atproxy(t.k).leftNum - 1
	end, v.pos, v.csvId, v.itemId)
end

return MysteryShopView