-- @date 2018-12-23
-- @desc 直购礼包

-- 可购买，刷新中，售罄
local STATE_TYPE = {
	canbuy = 1,
	refresh = 2,
	sellout = 3,
}

local ActivityView = require "app.views.city.activity.view"
local ActivityDirectBuyGiftView = class("ActivityDirectBuyGiftView", cc.load("mvc").ViewBase)

ActivityDirectBuyGiftView.RESOURCE_FILENAME = "activity_direct_buy_gift.json"
ActivityDirectBuyGiftView.RESOURCE_BINDING = {
	["rightPanel"] = "rightPanel",
	["rightPanel.item"] = "rightItem",
	["rightPanel.list"] = {
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("rightData"),
				item = bindHelper.self("rightItem"),
				showTab = bindHelper.self("showTab"),
				onItem = function(list, node, k, v)
					local normal = node:get("normal")
					local selected = node:get("selected")
					local panel
					if v.select then
						normal:hide()
						panel = selected:show()
					else
						selected:hide()
						panel = normal:show()
					end
					panel:get("name"):text(v.desc)
					if matchLanguage({"kr"}) then
						adapt.setTextScaleWithWidth(panel:get("name"), nil, 250)
					elseif matchLanguage({"en"}) then
						adapt.setTextAdaptWithSize(panel:get("name"), {size = cc.size(255, 70), vertical = "center", horizontal = "center", margin = -5, maxLine = 2})
					end
					bind.extend(list, node, {
						class = "red_hint",
						props = {
							specialTag = "activityDirectBuyGiftExternal",
							state = list.showTab:read() ~= k,
							listenData = {
								id = v.id,
								huodongID = csv.yunying.yyhuodong[v.id].huodongID,
							},
							onNode = function(panel)
								panel:xy(280, 120)
							end,
						},
					})

					bind.touch(list, normal, {methods = {ended = functools.partial(list.clickCellItem, k, v)}})
				end,
			},
			handlers = {
				clickCellItem = bindHelper.self("onLeftItemClick"),
			},
		},
	},
	["item"] = "item",
	["listitem"] = "listitem",
	["list"] = {
		varname = "list",
		binds = {
			event = "extend",
			class = "tableview",
			props = {
				data = bindHelper.self("datas"),
				item = bindHelper.self("listitem"),
				cell = bindHelper.self("item"),
				columnSize = bindHelper.self("rightColumnSize"),
				asyncPreload = 9,
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
					local childs = node:multiget("title", "times", "bottomPanel", "mask", "list", "item", "icon")
					childs.title:text(cfg.name)
					childs.title:x(node:width()/2)
					childs.title:y(640)
					adapt.setTextAdaptWithSize(childs.title, {size = cc.size(330, 70), vertical = "top", horizontal = "center", margin = -8, maxLine = 2})
					childs.icon:texture(cfg.icon)
					if cfg.refresh then
						childs.times:text(string.format(gLanguageCsv.directBuyGiftDailyBuy, v.leftTimes, cfg.limit))
						text.addEffect(childs.times, {color=ui.COLORS.DISABLED.YELLOW})
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
					local idx = 0
					local len = csvSize(cfg.item)
					local dx = len == 1 and childs.item:size().width/2 or 0
					for _, itemData in ipairs(dataEasy.getItemData(cfg.item)) do
						local id = itemData.key
						local num = itemData.num
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
										:scale(0.8)
								end,
							},
						})
						childs.list:pushBackCustomItem(item)
					end

					childs.list:adaptTouchEnabled()
						:setItemAlignCenter()
					local btn = childs.bottomPanel:get("btn")
					local panel = childs.bottomPanel:get("panel")
					local price = childs.bottomPanel:get("panel"):get("price")
					local rmbIcon = childs.bottomPanel:get("panel"):get("rmb")
					btn:setTouchEnabled(false)
					rmbIcon:visible(false)
					cache.setShader(btn, false, "normal")
					if v.rmb then
						local number = 40
						price:text(v.rmb)
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
					if matchLanguage({"en"}) then
						price:anchorPoint(0.5, 0.5)
						panel:x(btn:size().width/2)
						childs.mask:get("img"):size(childs.mask:get("label"):size().width + 45, childs.mask:get("img"):size().height)
					end
					local props = {
						class = "red_hint",
						props = {
							state = isInfo,
							onNode = function(panel)
								panel:xy(355, 110)
							end,
						}
					}
					bind.extend(list, childs.bottomPanel, props)
					list:setRenderHint(0)
				end,
			},
			handlers = {
				clickCell = bindHelper.self("onBuyClick"),
			},
		},
	},
	["icon404"] = "icon404",
	["bg404"] = "bg404",
	["rightBg"] = "rightBg",
	["time"] = "time",
}

function ActivityDirectBuyGiftView:onCreate()
	gGameUI.topuiManager:createView("default", self, {onClose = self:createHandler("onClose")})
		:init({title = gLanguageCsv.specialGiftBag, subTitle = "SPECIAL GIFT BAG"})

	self:initModel()
	local dataTab = {}

	for _,id in ipairs(self.yyOpen:read()) do
		local cfg = csv.yunying.yyhuodong[id]
		if cfg.type == game.YYHUODONG_TYPE_ENUM_TABLE.directBuyGift and (cfg.independent == 1  or cfg.independent == 2) and not cfg.clientParam.double11 then
			table.insert(dataTab, {desc = cfg.desc, id = id, sortWeight = cfg.sortWeight})
		end
	end

	table.sort(dataTab, function(a, b)
		if a.sortWeight ~= b.sortWeight then
			return a.sortWeight < b.sortWeight
		end
		return a.id < b.id
	end )
	local idx = dataTab[1].id

	self.time:hide()
	if idx then
		self.icon404:visible(false)
		self.bg404:visible(false)
		self.rightData:update(dataTab)
		self.activityId:set(idx)
		self.rightColumnSize = 3
		self.showTab:addListener(function(val, oldval, idler)
			self.rightData:atproxy(oldval).select = false
			self.rightData:atproxy(val).select = true
			local cfg = csv.yunying.yyhuodong[self.activityId:read()]
			if cfg.clientParam.isShowCountDown ~= false then
				self.time:show()
				local uiIcon = self.time:get("icon")
				local uiTimeLabel = self.time:get("title")
				local uiTime = self.time:get("time")
				ActivityView.setCountdown(self, self.activityId:read(), uiTimeLabel, uiTime, {labelChangeCb = function()
					adapt.oneLinePos(uiTime, {uiTimeLabel, uiIcon}, cc.p(5, 0), "right")
				end, tag = 1})
			else
				self.time:hide()
			end
		end)

		local timeVisibel = csv.yunying.yyhuodong[idx].clientParam
		self.time:visible(timeVisibel.isShowCountDown ~= false)

		gGameModel.currday_dispatch:getIdlerOrigin("activityDirectBuyGift"):set(true)
		-- 客户端模拟购买次数变动了通知
		self.clientBuyTimes = idler.new(true)
		idlereasy.any({self.yyhuodongs, self.clientBuyTimes, self.activityId}, function(_, yyhuodongs, clientBuyTimes, activityId)
			local huodongID = csv.yunying.yyhuodong[activityId].huodongID
			local yydata = yyhuodongs[activityId] or {}
			local stamps = yydata.stamps or {}
			local datas = {}
			for k, v in csvPairs(csv.yunying.directbuygift) do
				if v.huodongID == huodongID and self.level >= v.levelLimit then
					local state = STATE_TYPE.canbuy
					local buyTimes = stamps[k] or 0
					buyTimes = dataEasy.getPayClientBuyTimes("directBuyData", activityId, k, buyTimes)
					local leftTimes = math.max(0, v.limit - buyTimes)
					local status = v.status
					if leftTimes == 0 then
						if v.refresh then
							state = STATE_TYPE.refresh
						else
							state = STATE_TYPE.sellout
						end
					end
					--# 判断是免费还是钻石和钱
					local rmb, price
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

			if not self.isTabChange then
				dataEasy.tryCallFunc(self.list, "updatePreloadCenterIndex")
			else
				self.isTabChange = false
			end
			self.datas:update(datas)
		end)
	else
		self.rightBg:visible(false)
	end
end

function ActivityDirectBuyGiftView:initModel()
	self.yyhuodongs = gGameModel.role:getIdler("yyhuodongs")
	self.yyOpen = gGameModel.role:getIdler('yy_open')
	self.level = gGameModel.role:read("level")
	self.activityId = idler.new()
	self.rightData = idlers.new()
	self.datas = idlers.new()
	self.showTab = idler.new(1)
	self.rightItem:visible(false)
end

function ActivityDirectBuyGiftView:onLeftItemClick(list, idx, v)
	if self.activityId:read() ~= v.id then
		dataEasy.tryCallFunc(self.list, "setItemAction", {isAction = true})
		self.isTabChange = true
		self.activityId:set(v.id)
		self.showTab:set(idx)
	end
end

function ActivityDirectBuyGiftView:onBuyClick(list, k, v)
	local activityId = self.activityId:read()
	if not v.rmb then
		gGameApp:payDirect(self, {rechargeId = v.cfg.rechargeID, yyID = activityId, csvID = v.csvId, name = v.cfg.name, buyTimes = v.buyTimes}, self.clientBuyTimes)
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
		end, activityId, v.csvId)
	end
end

return ActivityDirectBuyGiftView