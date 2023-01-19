-- @date 2020-8-31
-- @desc 训练家重聚 充值活动

-- 可购买，刷新中，售罄
local STATE_TYPE = {
	canbuy = 1,
	refresh = 2,
	sellout = 3,
}

local ReunionRechargeView = class("ReunionRechargeView", cc.load("mvc").ViewBase)

ReunionRechargeView.RESOURCE_FILENAME = "reunion_recharge.json"
ReunionRechargeView.RESOURCE_BINDING = {
	["topPanel.title"] = {
		binds = {
			event = "effect",
			data = {
				outline = {color = cc.c4b(233, 79, 18, 255), size = 4},
				shadow = {color = cc.c4b(195, 109, 72, 255), offset = cc.size(0,-6), size = 6}
			},
		},
	},
	["topPanel.title_0"] = {
		binds = {
			event = "effect",
			data = {
				outline = {color = cc.c4b(242, 122, 96, 255), size = 5},
				color = cc.c4b(254, 255, 51, 255),
			},
		},
	},
	["item"] = "item",
	["list"] = {
		varname = "list",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("datas"),
				item = bindHelper.self("item"),
				dataOrderCmp = function(a, b)
					if a.state ~= b.state then
						return a.state < b.state
					end
					return a.csvId < b.csvId
				end,
				itemAction = {isAction = true},
				onItem = function(list, node, k, v)
					local cfg = v.cfg
					local childs = node:multiget("list", "times", "title", "bottomPanel", "mask", "icon", "item")
					childs.title:text(cfg.name)
					childs.icon:texture(cfg.res)

					if v.status == 3 then
						childs.times:visible(false)
					else
						--活动内
						local hint = gLanguageCsv.activityBuyLimit
						if v.status == 1 then --当日
							hint = gLanguageCsv.directBuyGiftDailyBuy
						end
						childs.times:visible(true)
						childs.times:text(string.format(hint, v.leftTimes, cfg.limitNum))
					end
					childs.list:removeAllChildren()
					childs.list:setScrollBarEnabled(false)
					childs.list:setGravity(ccui.ListViewGravity.bottom)
					childs.list:width(480)

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
					price:text(string.format(gLanguageCsv.symbolMoney, v.price))

					if v.state == STATE_TYPE.canbuy then
						childs.mask:hide()
						btn:setTouchEnabled(true)
						bind.touch(list, btn, {clicksafe = true, methods = {ended = functools.partial(list.clickCell, k, v)}})
						text.addEffect(price, {color = ui.COLORS.NORMAL.WHITE, glow={color=ui.COLORS.GLOW.WHITE}})
					else
						childs.mask:show()
						-- isInfo = false
						cache.setShader(btn, false, "hsl_gray")
						text.deleteAllEffect(price)
						text.addEffect(price, {color = ui.COLORS.DISABLED.WHITE})
						if v.state == STATE_TYPE.sellout then
							childs.mask:get("label"):text(gLanguageCsv.sellout)
						else
							childs.mask:get("label"):text(gLanguageCsv.nextDayRefresh5)
						end
					end
				end,
				asyncPreload = 5,
			},
			handlers = {
				clickCell = bindHelper.self("onBuyClick"),
			},
		},
	},
}

function ReunionRechargeView:onCreate(yyID)
	self.yyID = yyID
	local cfg = csv.yunying.yyhuodong[yyID]
	-- self.huodongID = cfg.huodongID
	self:initModel()


	self.datas = idlers.new()
	-- 客户端模拟购买次数变动了通知
	self.clientBuyTimes = idler.new(true)
	idlereasy.any({self.reunion, self.clientBuyTimes}, function(_, reunion, clientBuyTimes)
		local recharge = reunion.recharge or {}
		local datas = {}
		for k, v in csvPairs(csv.yunying.reunion_recharge) do
			if v.huodongID == cfg.huodongID then
				local state = STATE_TYPE.canbuy
				local buyTimes = recharge[k] and recharge[k][1] or 0
				buyTimes = dataEasy.getPayClientBuyTimes("directBuyData", self.yyID, k, buyTimes)
				local leftTimes = math.max(0, v.limitNum - buyTimes)
				local status = v.limitType
				if leftTimes == 0 then
					-- if v.refresh then
					-- 	state = STATE_TYPE.refresh
					-- else
					state = STATE_TYPE.sellout
					-- end
				end

				local price = csv.recharges[v.rechargeID].rmbDisplay

				table.insert(datas, {csvId = k, cfg = v, state = state, buyTimes = buyTimes, leftTimes = leftTimes, price = price})
			end
		end
		dataEasy.tryCallFunc(self.list, "updatePreloadCenterIndex")
		self.datas:update(datas)
	end)
end

function ReunionRechargeView:initModel()
	self.reunion = gGameModel.role:getIdler("reunion")
end

function ReunionRechargeView:onBuyClick(list, k, v)
	gGameApp:payDirect(self, {rechargeId = v.cfg.rechargeID, yyID = self.yyID, csvID = v.csvId, name = v.cfg.name, buyTimes = v.buyTimes}, self.clientBuyTimes)
		:serverCb(function()
			local cfg = csv.yunying.reunion_recharge[v.csvId]
			gGameUI:showGainDisplay(cfg.item, {raw = false})
		end)
		:doit()
end

return ReunionRechargeView