-- @date 2018-12-23
-- @desc 道具折扣 (折扣礼包)

local LINE_NUM = 4
-- 可购买，刷新中，售罄
local STATE_TYPE = {
	canbuy = 1,
	refresh = 2,
	sellout = 3,
}

local LOGO_RES = {
	[0] = {name = gLanguageCsv.discount, logo = "common/icon/sign_blue.png"}, -- 折
	[1] = {name = gLanguageCsv.hotness, logo = "common/icon/sign_orange.png"}, -- 热
	[2] = {name = gLanguageCsv.limit, logo = "common/icon/sign_purple.png"}, -- 限
	[3] = {name = gLanguageCsv.new, logo = "common/icon/sign_green.png"}, -- 新
}

local ActivityItemBuyView = class("ActivityItemBuyView", cc.load("mvc").ViewBase)

ActivityItemBuyView.RESOURCE_FILENAME = "activity_item_buy.json"
ActivityItemBuyView.RESOURCE_BINDING = {
	["item"] = "item",
	["subList"] = "subList",
	["list"] = {
		varname = "list",
		binds = {
			event = "extend",
			class = "tableview",
			props = {
				data = bindHelper.self("datas"),
				columnSize = LINE_NUM,
				item = bindHelper.self("subList"),
				cell = bindHelper.self("item"),
				itemAction = {isAction = true},
				onCell = function(list, node, k, v)
					local cfg = v.cfg
					local childs = node:multiget("title", "times", "bottomPanel", "mask", "logo", "logoDesc", "oldPrice")
					local name = uiEasy.setIconName(v.id, v.num)
					childs.title:text(name)
					adapt.setTextAdaptWithSize(childs.title, {size = cc.size(330, 75), vertical = "center", horizontal = "center", margin = -8, maxLine = 2})
					local size = node:size()
					bind.extend(list, node, {
						class = "icon_key",
						props = {
							data = {
								key = v.id,
								num = v.num,
							},
							onNode = function(node)
								node:xy(size.width/2, size.height/2 + 75)
							end,
						},
					})
					node:removeChildByName("logoLabel")
					if cfg.logo then
						childs.logo:show():texture(LOGO_RES[cfg.logo].logo):show()
						childs.logoDesc:show()
						if cfg.logo == 0 then
							local discount = string.format(gLanguageCsv.discount, mathEasy.getPreciseDecimal(cfg.rmbCost / cfg.rmbShow * 10, 0, true))
							if matchLanguage({"kr"}) then
								discount = string.format(gLanguageCsv.discount, (mathEasy.getPreciseDecimal((cfg.rmbShow - cfg.rmbCost)/ cfg.rmbShow * 100, 0, true)))
								childs.logoDesc:scale(0.6)
								childs.logo:scale(1.15)
							end
							if matchLanguage({"en"}) then
								discount = string.format(gLanguageCsv.discount, (mathEasy.getPreciseDecimal((cfg.rmbShow - cfg.rmbCost)/ cfg.rmbShow * 100, 0, true)))
								childs.logoDesc:scale(1.1)
								childs.logo:scale(1.15)
								childs.logoDesc:setTextAreaSize(cc.size(80,80))
							end
							childs.logoDesc:text(discount)
						else
							childs.logoDesc:text(LOGO_RES[cfg.logo].name)
						end
					else
						childs.logo:hide()
						childs.logoDesc:hide()
					end
					if cfg.refresh then
						childs.times:text(string.format(gLanguageCsv.directBuyGiftDailyBuy, v.leftTimes, cfg.buyMax))
						text.addEffect(childs.times, {color=ui.COLORS.QUALITY[5]})
					else
						childs.times:text(string.format(gLanguageCsv.directBuyGiftOnetimeBuy, v.leftTimes, cfg.buyMax))
						text.addEffect(childs.times, {color=ui.COLORS.QUALITY[4]})
					end
					childs.oldPrice:text(cfg.rmbShow)

					local btn = childs.bottomPanel:get("btn")
					local price = childs.bottomPanel:get("price")
					btn:setTouchEnabled(false)
					cache.setShader(btn, false, "normal")
					price:text(cfg.rmbCost)
					if v.state == STATE_TYPE.canbuy then
						childs.mask:hide()
						btn:setTouchEnabled(true)
						bind.touch(list, btn, {methods = {ended = functools.partial(list.clickCell, t, v)}})
						text.addEffect(price, {color = ui.COLORS.NORMAL.WHITE, glow={color=ui.COLORS.GLOW.WHITE}})
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
					adapt.oneLineCenterPos(cc.p(125, 50), {childs.bottomPanel:get("icon"), price}, cc.p(15, -5))
				end,
				asyncPreload = 8,
			},
			handlers = {
				clickCell = bindHelper.self("onBuyClick"),
			},
		},
	},
}

function ActivityItemBuyView:onCreate(activityId)
	self.activityId = activityId
	self:initModel()

	local yyCfg = csv.yunying.yyhuodong[activityId]
	local huodongID = yyCfg.huodongID
	self.datas = idlers.new()
	idlereasy.when(self.yyhuodongs, function(_, yyhuodongs)
		local yydata = yyhuodongs[activityId] or {}
		local stamps = yydata.stamps or {}
		local datas = {}
		for k, v in csvPairs(csv.yunying.itembuy) do
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
				table.insert(datas, {csvId = k, id = id, num = num, cfg = v, state = state, leftTimes = leftTimes})
			end
		end
		table.sort(datas, function(a, b)
			if a.state ~= b.state then
				return a.state < b.state
			end
			return a.csvId < b.csvId
		end)
		dataEasy.tryCallFunc(self.list, "updatePreloadCenterIndex")
		self.datas:update(datas)
	end)
end

function ActivityItemBuyView:initModel()
	self.yyhuodongs = gGameModel.role:getIdler("yyhuodongs")
	self.rmb = gGameModel.role:getIdler("rmb")
end

function ActivityItemBuyView:onBuyClick(list, k, v)
	local rmb = self.rmb:read()
	local cost = v.cfg.rmbCost
	if rmb < cost then
		uiEasy.showDialog("rmb")
	else
		gGameUI:stackUI("common.buy_info", nil, nil, {rmb = cost}, {id = v.id, num = v.num}, {maxNum = v.leftTimes, contentType = "num"}, self:createHandler("getBuyInfoCb", v.csvId))
	end
end

function ActivityItemBuyView:getBuyInfoCb(csvId, num)
	gGameApp:requestServer("/game/yy/award/get", function(tb)
		gGameUI:showGainDisplay(tb)
	end, self.activityId, csvId, num)
end


return ActivityItemBuyView