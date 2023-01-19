-- @date 2020-11-03
-- @desc 双11商店

-- 可购买，刷新中，售罄
local STATE_TYPE = {
	canbuy = 1,
	refresh = 2,
	sellout = 3,
}
local ActivityDouble11Shop = class("ActivityDouble11Shop",cc.load("mvc").ViewBase)

ActivityDouble11Shop.RESOURCE_FILENAME = "double11_shop.json"
ActivityDouble11Shop.RESOURCE_BINDING = {
	["bg"] = "bg",
	["bg2"] = "shopBg",
	["time"] = "time",
	["tip"] = {
		varname = "tip",
		binds = {
			event = "effect",
			data = {outline = {color = cc.c4b(255, 255, 235, 255),  size = 4}}
		},
	},
	------------------------------------tabPanel----------------------------------------
	["leftPanel"] = "leftPanel",
	["leftPanel.item"] = "tabItem",
	["leftPanel.item.normal.name"] = {
		binds = {
			event = "effect",
			data = {outline = {color = cc.c4b(216, 148, 115, 255),  size = 3}}
		},
	},
	["leftPanel.item.select.name"] = {
		binds = {
			event = "effect",
			data = {outline = {color = cc.c4b(129, 61, 45, 255),  size = 3}}
		},
	},
	["leftPanel.list"] = {
		varname = "tabList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("tabData"),
				item = bindHelper.self("tabItem"),
				itemAction = {isAction = true},
				showTab = bindHelper.self("showTab"),
				onItem = function(list, node, k, v)
					local normal = node:get("normal")
					local selected = node:get("select")
					local panel
					if v.select then
						normal:hide()
						panel = selected:show()
						text.addEffect(selected:get("name"), {color = ui.COLORS.NORMAL.WHITE, glow={color=ui.COLORS.GLOW.WHITE}})
					else
						selected:hide()
						panel = normal:show()
					end
					panel:get("name"):text(v.desc)
					bind.touch(list, normal, {methods = {ended = functools.partial(list.clickCellItem, k, v)}})
				end,
			},
			handlers = {
				clickCellItem = bindHelper.self("onLeftItemClick"),
			},
		},
	},
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
				leftPadding = 20,
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
					local childs = node:multiget("title", "tip", "mask", "price", "item", "icon","hot","btnBuy")
					childs.title:text(cfg.name)
					--图标
					if cfg.hot == "" then
						childs.hot:visible(false)
					else
						childs.hot:visible(true)
						childs.hot:texture(cfg.hot)
					end
					--显示限购
					if cfg.refresh then
						childs.tip:text(string.format(gLanguageCsv.directBuyGiftDailyBuy, v.leftTimes, cfg.limit))
					else
						childs.tip:text(string.format(gLanguageCsv.directBuyGiftOnetimeBuy, v.leftTimes, cfg.limit))
					end
					--icon 图标
					for _, itemData in ipairs(dataEasy.getItemData(cfg.item)) do
						local id = itemData.key
						local num = itemData.num
						bind.extend(list, childs.icon, {
							class = "icon_key",
							props = {
								data = {
									key = id,
									num = num,
								},
								onNode = function(node)
								end,
							},
						})
					end
					--原价
					childs.price:get("num"):text(cfg.oldPrice)
					local btn = childs.btnBuy
					local price = childs.btnBuy:get("text")
					local rmbIcon = childs.btnBuy:get("rmb")
					btn:setTouchEnabled(false)
					rmbIcon:visible(false)
					cache.setShader(btn, false, "normal")
					if v.rmb then
						local number = 40
						price:text(v.rmb)
						if type(v.rmb) ~= "string" then
							rmbIcon:visible(true)
							number = 70
						end
					elseif v.price then
						price:text(string.format(gLanguageCsv.symbolMoney, v.price))
					end
					if v.state == STATE_TYPE.canbuy then
						childs.mask:hide()
						btn:setTouchEnabled(true)
						bind.touch(list, btn, {clicksafe = true, methods = {ended = functools.partial(list.clickCell, k, v)}})
						text.addEffect(price, {color = ui.COLORS.NORMAL.WHITE, glow={color=ui.COLORS.GLOW.WHITE}})
					else
						childs.mask:show()
						childs.hot:visible(false)
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
					node:get("imgBoard"):setVisible(k == 1)
				end,
			},
			handlers = {
				clickCell = bindHelper.self("onBuyClick"),
			},
		},
	},
	-----------------------------------bagPanel----------------------------------------
	["bagPanel"] = "bagPanel",
	["bagPanel.subList"] = "bagSublist",
	["bagPanel.item"] = "bagItem",
	["bagPanel.item.item"] = "iconItem",
	["bagPanel.centerList"] = {
		varname = "bagList",
		binds = {
			event = "extend",
			class = "tableview",
			props = {
				data = bindHelper.self("bagDatas"),
				item = bindHelper.self("bagSublist"),
				cell = bindHelper.self("bagItem"),
				columnSize = 3,
				asyncPreload = 9,
				leftPadding = 40,
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
					local childs = node:multiget("name", "boxImg", "mask",  "btnBuy", "item","list","tip","hot")
					childs.name:text(cfg.name)
					childs.boxImg:texture(cfg.icon)
					--图标
					if cfg.hot == "" or cfg.hot == nil then
						childs.hot:visible(false)
					else
						childs.hot:visible(true)
						childs.hot:texture(cfg.hot)
					end
					childs.boxImg:texture(cfg.icon)
					--显示限购
					if cfg.refresh then
						childs.tip:text(string.format(gLanguageCsv.directBuyGiftDailyBuy, v.leftTimes, cfg.limit))
					else
						childs.tip:text(string.format(gLanguageCsv.directBuyGiftOnetimeBuy, v.leftTimes, cfg.limit))
					end
					-- icon
					childs.list:removeAllChildren()
					childs.list:setScrollBarEnabled(false)
					childs.list:setGravity(ccui.ListViewGravity.bottom)
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
									node:scale(0.7)
								end,
							},
						})
						childs.list:pushBackCustomItem(item)
					end
					childs.list:adaptTouchEnabled()
						:setItemAlignCenter()
					local btn = childs.btnBuy
					local price = childs.btnBuy:get("text")
					btn:setTouchEnabled(false)
					cache.setShader(btn, false, "normal")
					if v.rmb then
						local number = 40
						price:text(v.rmb)
						if type(v.rmb) ~= "string" then
							number = 70
						end
					elseif v.price then
						price:text(string.format(gLanguageCsv.symbolMoney, v.price))
					end
					if v.state == STATE_TYPE.canbuy then
						childs.mask:hide()
						btn:setTouchEnabled(true)
						bind.touch(list, btn, {clicksafe = true, methods = {ended = functools.partial(list.clickCell, k, v)}})
						text.addEffect(price, {color = ui.COLORS.NORMAL.WHITE, glow={color=ui.COLORS.GLOW.WHITE}})
					else
						childs.mask:show()
						childs.hot:visible(false)
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
					node:get("imgBoard"):setVisible(k == 1)
				end,
			},
			handlers = {
				clickCell = bindHelper.self("onBuyClick"),
			},
		},
	},
}
function ActivityDouble11Shop:onCreate()
	gGameUI.topuiManager:createView("default", self, {onClose = self:createHandler("onClose")})
		:init({title = gLanguageCsv.double11Shop, subTitle = "ACTIVITY"})

	self:initModel()
	local dataTab = {}
	self.tip:text(gLanguageCsv.double11ShopTip)
	for _,id in ipairs(self.yyOpen:read()) do
		local cfg = csv.yunying.yyhuodong[id]
		if cfg.type == game.YYHUODONG_TYPE_ENUM_TABLE.directBuyGift and cfg.clientParam.double11 then
			table.insert(dataTab, {desc = cfg.desc, id = id, sortWeight = cfg.sortWeight, type = cfg.clientParam.type})
		end
	end
	self.datas = dataTab
	self.timeId = dataTab[1].id
	table.sort(dataTab, function(a, b)
		if a.sortWeight ~= b.sortWeight then
			return a.sortWeight < b.sortWeight
		end
		return a.id < b.id
	end )
	local idx = dataTab[1].id

	self:initCountDown()

	if idx then
		if dataTab[1].type == "item" then
			self.singlePanel:visible(true)
			self.bagPanel:visible(false)
		elseif dataTab[1].type == "gift" then
			self.singlePanel:visible(false)
			self.bagPanel:visible(true)
		end
		self.tabData:update(dataTab)
		self.activityId:set(idx)
		self.showTab:addListener(function(val, oldval, idler)
			self.tabData:atproxy(oldval).select = false
			self.tabData:atproxy(val).select = true
		end)

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

			userDefault.setForeverLocalKey("double11ShopData", double11ShopData, {new = true})
			for _,val in ipairs(self.datas) do
				if self.activityId:read() == val.id then
					if val.type == "item" then
						dataEasy.tryCallFunc(self.singleList, "updatePreloadCenterIndex")
						self.singleDatas:update(datas)
					elseif val.type == "gift" then
						dataEasy.tryCallFunc(self.bagList, "updatePreloadCenterIndex")
						self.bagDatas:update(datas)
					end
				end
			end
		end)
	end
end

function ActivityDouble11Shop:initModel()
	self.yyhuodongs = gGameModel.role:getIdler("yyhuodongs")
	self.yyOpen = gGameModel.role:getIdler('yy_open')
	self.rmb = gGameModel.role:getIdler('rmb')
	self.level = gGameModel.role:read("level")
	self.activityId = idler.new()
	self.tabData = idlers.new()
	self.singleDatas = idlers.new()
	self.bagDatas = idlers.new()
	self.showTab = idler.new(1)
end

function ActivityDouble11Shop:onLeftItemClick(list, idx, v)
	if self.activityId:read() ~= v.id then
		self.activityId:set(v.id)
		self.showTab:set(idx)
		for _,val in ipairs(self.datas) do
			if v.id == val.id then
				if val.type == "item" then
					dataEasy.tryCallFunc(self.singleList, "setItemAction", {isAction = true})
					self.singlePanel:visible(true)
					self.bagPanel:visible(false)
				elseif val.type == "gift" then
					dataEasy.tryCallFunc(self.bagList, "setItemAction", {isAction = true})
					self.singlePanel:visible(false)
					self.bagPanel:visible(true)
				end
			end
		end

	end
end

function ActivityDouble11Shop:onBuyClick(list, k, v)
	local activityId = self.activityId:read()
	if not v.rmb then
		gGameApp:payDirect(self, {rechargeId = v.cfg.rechargeID, yyID = activityId, csvID = v.csvId, name = v.cfg.name, buyTimes = v.buyTimes}, self.clientBuyTimes)
			:serverCb(function()
				local cfg = csv.yunying.directbuygift[v.csvId]
				gGameUI:showGainDisplay(cfg.item, {raw = false})
			end)
			:doit()
	else
		if self.rmb:read() < v.rmb then
			uiEasy.showDialog("rmb", nil, {dialog = false})
			return
		end
		dataEasy.sureUsingDiamonds(function()
			gGameApp:requestServer("/game/yy/award/get", function(tb)
				self.clientBuyTimes:notify()
				local cfg = csv.yunying.directbuygift[v.csvId]
				gGameUI:showGainDisplay(cfg.item, {raw = false})
			end, activityId, v.csvId)
		end,v.rmb)

	end
end

--倒计时
function ActivityDouble11Shop:initCountDown()
	local textTime = self.time
	local yyCfg = csv.yunying.yyhuodong[self.timeId]
	local hour, min = time.getHourAndMin(yyCfg.endTime)
	local endTime = time.getNumTimestamp(yyCfg.endDate,hour,min)
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

return ActivityDouble11Shop