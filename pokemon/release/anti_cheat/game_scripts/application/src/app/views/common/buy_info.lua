-- @desc: 购买/出售/使用/打开/兑换 详情框

local MonthCardView = require "app.views.city.activity.month_card"

local ViewBase = cc.load("mvc").ViewBase
local BuyInfoView = class("BuyInfoView", Dialog)

local BUY_INFO = {
	buy = 1,
	sell = 2,
	use = 3,
	open = 4,
	exchange = 5, -- 兑换
}
local TITLE = {
	gLanguageCsv.buyItem,
	gLanguageCsv.sellItem,
	gLanguageCsv.useItem,
	gLanguageCsv.openItem,
	gLanguageCsv.exchangeItem,
}
local BUTTON_TEXT = {
	gLanguageCsv.spaceBuy,
	gLanguageCsv.spaceSell,
	gLanguageCsv.spaceUse,
	gLanguageCsv.spaceOpen,
	gLanguageCsv.spaceExchange,
}

-- 价格标题
local PRICE_TITLE = {
	[1] = gLanguageCsv.cost,
	[2] = gLanguageCsv.sellingPrice,
	[3] = gLanguageCsv.cost,
	[4] = gLanguageCsv.cost,
	[5] = gLanguageCsv.cost,
}

-- 购买/兑换物品是否已达上限：1、未达堆叠上限可以购买 2、拥有数量已达堆叠上限，无法购买 3、拥有数量未达堆叠上限，但购买后数量超过上限，弹出提示
local STACK_STATE = {
	noReach = 1,
	reach = 2,
	over = 3
}

local PRICELISTMARGIN = 26

BuyInfoView.RESOURCE_FILENAME = "common_buy_info.json"
BuyInfoView.RESOURCE_BINDING = {
	["title"] = "title",
	["closeBtn"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")}
		},
	},
	["content"] = "content",
	["content.label"] = "ownLabel",
	["content.num"] = "numLabel",
	["content.maxNum"] = "maxNumLabel",
	["content.maxTip"] = "maxTip",
	["content.sliderPanel"] = "sliderPanel",
	["content.sliderPanel.subBtn"] = {
		varname = "sliderSubBtn",
		binds = {
			event = "touch",
			longtouch = true,
			method = bindHelper.defer(function(view, node, event)
				return view:onChangeNum(node, event, -1)
			end),
		},
	},
	["content.sliderPanel.addBtn"] = {
		varname = "sliderAddBtn",
		binds = {
			event = "touch",
			longtouch = true,
			method = bindHelper.defer(function(view, node, event)
				return view:onChangeNum(node, event, 1)
			end),
		},
	},
	["content.sliderPanel.slider"] = "slider",
	["content.numPanel"] = "numPanel",
	["content.numPanel.subBtn"] = {
		varname = "numSubBtn",
		binds = {
			event = "touch",
			longtouch = true,
			method = bindHelper.defer(function(view, node, event)
				return view:onChangeNum(node, event, -1)
			end),
		},
	},
	["content.numPanel.addBtn"] = {
		varname = "numAddBtn",
		binds = {
			event = "touch",
			longtouch = true,
			method = bindHelper.defer(function(view, node, event)
				return view:onChangeNum(node, event, 1)
			end),
		},
	},
	["content.numPanel.subTenBtn"] = {
		varname = "numSubTenBtn",
		binds = {
			event = "touch",
			longtouch = true,
			method = bindHelper.defer(function(view, node, event)
				return view:onChangeNum(node, event, -10)
			end),
		},
	},
	["content.numPanel.addTenBtn"] = {
		varname = "numAddTenBtn",
		binds = {
			event = "touch",
			longtouch = true,
			method = bindHelper.defer(function(view, node, event)
				return view:onChangeNum(node, event, 10)
			end),
		},
	},
	["buyBtn"] = {
		varname = "buyBtn",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onBuyItem")}
		},
	},
	["buyBtn.text"] = {
		varname = "buyBtnText",
		binds = {
			event = "effect",
			data = {color = ui.COLORS.NORMAL.WHITE, glow = {color = ui.COLORS.GLOW.WHITE}},
		},
	},
	["pricePanel"] = "pricePanel",
	["pricePanel.text"] = "priceDesc",
	["priceItem"] = "priceItem",
	["pricePanel.priceList"] = {
		varname = "priceList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("priceData"),
				item = bindHelper.self("priceItem"),
				priceListWidth = bindHelper.self("priceListWidth"),
				discount = bindHelper.self("discount"), -- 折扣
				flag = bindHelper.self("flag"),
				margin = PRICELISTMARGIN,
				onItem = function(list, node, k, v)
					-- original 原价 line 原价上红线 price 现价 icon 图标(无折扣，隐藏original、line)
					local childs = node:multiget("price", "icon", "original", "line")
					-- 是否有折扣
					local hasDiscount = list.discount > 0  and list.discount < 1
					-- 现价(保留整数、四舍五入)
					local price = mathEasy.getPreciseDecimal(v.cost* list.discount, 0, true)
					childs.original:visible(hasDiscount)
					childs.line:visible(hasDiscount)
					childs.price:text(price)
					childs.icon:texture(dataEasy.getIconResByKey(v.key))
					childs.original:text(v.cost)
					childs.line:width((childs.original:width()* childs.original:scale() + 18)/childs.line:scale())
					if list.flag ~= BUY_INFO.sell then
						text.addEffect(childs.price, {color = dataEasy.getNumByKey(v.key) >= price and ui.COLORS.NORMAL.DEFAULT or ui.COLORS.NORMAL.ALERT_ORANGE})
					end
					-- node 宽度计算,用于list宽度计算
					local distance = 10 -- line、price、icon间隔
					local priceWidth = childs.price:width()* childs.price:scale()
					local iconWidth = childs.icon:width()* childs.icon:scale()
					local lineWidth = hasDiscount and childs.line:width()* childs.line:scale() or 0
					local totalDistance = hasDiscount and distance*2 or distance
					local width = lineWidth + priceWidth + iconWidth + totalDistance
					node:width(width)
					-- 计算list中所有item宽度之和
					list.priceListWidth:set(list.priceListWidth:read() + width)
					-- 对齐
					if hasDiscount then
						adapt.oneLinePos(childs.line, {childs.price, childs.icon}, cc.p(distance,0), "left")
					else
						adapt.oneLinePos(childs.price, childs.icon, cc.p(distance,0), "left")
					end
				end,
				onAfterBuild = function(list)
					list.afterBuild()
				end,
			},
			handlers = {
				afterBuild = bindHelper.self("onAfterBuildPriceList"),
			},
		}
	},
	["selectPanel"] = "selectPanel",
	["selectPanel.txt"] = "selectDesc",
	["selectItem"] = "selectItem",
	["selectPanel.list"] = {
		varname = "selectList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("selectData"),
				item = bindHelper.self("selectItem"),
				selectListWidth = bindHelper.self("selectListWidth"),
				onItem = function(list, node, k, v)
					local childs = node:multiget("price", "icon", "selectPanel")
					childs.icon:texture(dataEasy.getIconResByKey(v.key))
					childs.price:text(v.val)
					childs.selectPanel:get("select"):visible(v.selected)
					-- node 宽度计算,用于list宽度计算
					local distance = 10 -- price、icon间隔
					local priceX = childs.price:x()
					local priceWidth = childs.price:width()
					local iconWidth = childs.icon:width()
					local totalDistance = distance*2
					local width = priceX + priceWidth + iconWidth + totalDistance
					node:width(width)
					-- 计算list中所有item宽度之和
					list.selectListWidth:set(list.selectListWidth:read() + width)

					adapt.oneLinePos(childs.price, childs.icon, cc.p(distance, 0), "left")
					bind.click(list, node, {method = functools.partial(list.clickCell, k, v)})
				end,
				onAfterBuild = function(list)
					list.afterBuild()
				end,
			},
			handlers = {
				afterBuild = bindHelper.self("onAfterBuildSelectList"),
				clickCell = bindHelper.self("onSelectedClick"),
			},
		}
	}
}

-- @param costMap {rmb = 100, gold = 400} 货币 = 单价，支持多组(目前只有单货币购买，兑换有多材料兑换，出售状态下为售价)
-- @param itemData {id, num} id  物品/商品id  物品/商品包含道具数量
-- @param params {[num(idler)], [maxNum], [flag], [discount], [contentTyp], [style]}
-- @params num(idler) 物品/商品数量
-- @params maxNum 可购买/兑换/使用上限 不传表示外部无上限 (堆叠上限和货币上限整合进这里，不在外部设置)
-- @params flag() 类型 BUY_INFO, 默认"buy"
-- @params discount 折扣-目前只支持统一折扣, 后续可以考虑拓展多货币不同折扣
-- @params contentType 进度条风格("num","slider"), 默认不显示
-- @params style 1 拥有数量:0 2 num/maxNum  默认1
-- @params selectMap {rmb = 100, gold = 400} 货币 = 单价, selectMap存在则不显示pricePanel
-- @params cb 回调方法，关闭时调用
function BuyInfoView:onCreate(costMap, itemData, params, cb)
	params = params or {}
	self:enableSchedule()
	self.cb = cb
	local id = itemData.id
	self.id = id
	local itemNum = itemData.num
	--  物品/商品包含道具数量，未传入值，实际上数量为1，区别于itemNum，itemNum用于显示，1不显示 itemNumFact用于计算，不能为空
	local itemNumFact = itemData.num or 1
	local style = params.style or 1
	local contentType = params.contentType
	self.flag = BUY_INFO[params.flag or "buy"]
	self.num = params.num and params.num() or idler.new(1)
	self.maxNum = params.maxNum or math.huge -- 默认无上限
	self.discount = params.discount or 1
	-- 购买物品数量是否超出堆叠上限
	self.stackState = STACK_STATE.noReach

	-- 标题文本设置-flag控制
	self.title:text(TITLE[self.flag])
	self.buyBtnText:text(BUTTON_TEXT[self.flag])
	local selectMap = params.selectMap
	-- 没有costMap,隐藏价格界面
	self.pricePanel:visible(costMap ~= nil and selectMap == nil)
	if costMap then
		self.priceDesc:text(PRICE_TITLE[self.flag] .. ": ")
	end
	-- 价格数据
	self.priceData = idlers.newWithMap({})
	-- 价格列表宽度(动态变化)
	self.priceListWidth =  idler.new(0)
	self.selectPanel:visible(selectMap ~= nil)
	if selectMap then
		self.selectDesc:text(PRICE_TITLE[self.flag] .. ": ")
	end
	self.selectListWidth =  idler.new(0)

	local cfg = {}
	if id ~= "card" then 
		cfg = dataEasy.getCfgByKey(id)
	end
	if cfg.type == game.ITEM_TYPE_ENUM_TABLE.staminaRecover then
		self.itemAddStamina = cfg.specialArgsMap.stamina
		local remainder
		self.canUseMaxNum, remainder = math.modf((game.STAMINA_LIMIT - gGameModel.role:read("stamina")) / self.itemAddStamina)
		self.canUseMaxNum = remainder == 0 and self.canUseMaxNum or self.canUseMaxNum + 1
	end
	self.maxTip:hide() -- 体力溢出

	-- 物品/商品相关信息
	local binds = {
		class = "icon_key",
		props = {
			data = {
				key = id,
				num = itemNum,
			},
			onNode = function(node)
				node:xy(210, 410):z(3)
			end,
		},
	}
	bind.extend(self, self.content, binds)

	local name, effect = uiEasy.setIconName(id, itemNum)
	beauty.singleTextAutoScroll({
		size = cc.size(500, 50),
		strs = {str = name, fontPath = "font/youmi1.ttf"},
		effect = {color = ui.COLORS.NORMAL.DEFAULT},
		align = "left",
	})
		:xy(322, 425)
		:addTo(self.content, 4)

	itertools.invoke({self.sliderPanel, self.numPanel}, "hide")

	-- 购买-货币变动会导致max变动
	local idlerTable = {self.num}
	if self.flag == BUY_INFO.buy then
		for k,v in csvMapPairs(costMap) do
			local money = gGameModel.role:getIdler(tostring(k))
			table.insert(idlerTable, money)
		end
	end

	idlereasy.any(idlerTable, function(_, num)
		if (self.flag == BUY_INFO.buy or self.flag == BUY_INFO.exchange) and id ~= "card" then -- 卡牌不计算上限
			-- itemStackMax-道具堆叠上限 itemBuyMax-道具可购买最大数量 params.maxNum道具外部传入上限控制 overflow_exp(溢出经验)不是货币所以单独处理
			local itemStackMax = math.floor((dataEasy.itemStackMax(id) - dataEasy.getNumByKey(id)) / itemNumFact)
			local itemBuyMax, money
			for k, v in csvMapPairs(costMap) do
				money = dataEasy.getNumByKey(k)
				itemBuyMax = itemBuyMax and itertools.min({math.floor(money/(v*self.discount)), itemBuyMax}) or math.floor(money/(v*self.discount))
			end
			self.maxNum = itertools.min({params.maxNum, itemStackMax, itemBuyMax})

			-- 购买/兑换物品是否已达上限：1、拥有数量已达上限，无法购买 2、拥有数量未达上限，但购买后数量超过上限
			if dataEasy.getNumByKey(id) >= dataEasy.itemStackMax(id) then
				self.stackState = STACK_STATE.reach
			elseif (num * itemNumFact + dataEasy.getNumByKey(id)) > dataEasy.itemStackMax(id)  then
				self.stackState = STACK_STATE.over
			end
		end

		-- num/max 显示，应与slider分离
		self.numLabel:text(num)

		self:initProductCount(style, id, contentType, num)

		self:setProductData(num, costMap)
	end)

	self.slider:addEventListener(function(sender,eventType)
		if eventType == ccui.SliderEventType.percentChanged then
			self:unScheduleAll()
			local percent = sender:getPercent()
			-- 忽略滑动最后一次0的重置
			if percent == 0 and self.lastPercent ~= 0 then
				self.lastPercent = percent
				return
			end
			self.lastPercent = percent
			local num = cc.clampf(math.ceil(self.maxNum * percent * 0.01), 1, math.max(self.maxNum, 1))
			if self.canUseMaxNum then
				percent = (math.min(num, self.canUseMaxNum) / self.maxNum) * 100
				num = cc.clampf(math.ceil(self.maxNum * percent * 0.01), 1, math.max(self.canUseMaxNum, 1))
			end
			self.num:set(num, true)
		end
	end)

	self.selectData = idlers.new()
	if self.selectPanel:visible() then
		self.selectID = idler.new()
		local data = {}
		for k, v in csvMapPairs(selectMap) do
			table.insert(data, {key = k, val = v, selected = false})
		end
		data[1].selected = true
		self.selectData:update(data)
		self.selectID:addListener(function(val, oldVal)
			if val and oldVal then
				self.selectData:atproxy(oldVal).selected = false
				self.selectData:atproxy(val).selected = true
			end
		end)
		self.selectID:set(1)
	end
	Dialog.onCreate(self)
end

function BuyInfoView:initProductCount(style, id, contentType, num)
	if style == 1 then    -- 工程整合两个pannel出来
		if id == "card" then
			self.ownLabel:hide()
			self.maxNumLabel:hide()
		else
			self.ownLabel:show()
			self.maxNumLabel:text(dataEasy.getNumByKey(id)) -- 当前拥有数量
			adapt.oneLinePos(self.ownLabel, self.maxNumLabel, cc.p(20, 0))
		end
		self.numLabel:hide()
	else
		self.ownLabel:hide()
		self.numLabel:show()
		self.maxNumLabel:text("/" .. math.max(self.maxNum, 1))
		adapt.oneLinePos(self.numLabel, self.maxNumLabel)
	end

	local flag1 = num > 1
	local flag2 = num < self.maxNum
	if self.canUseMaxNum and self.flag == BUY_INFO.use then
		flag2 = num < self.canUseMaxNum
		self.maxTip:hide()
		if num >= self.canUseMaxNum then
			self.maxTip:show()
			self.unScheduleAll()
			if (self.itemAddStamina * num + gGameModel.role:read("stamina")) == game.STAMINA_LIMIT then
				self.maxTip:text(gLanguageCsv.energyFull)
				text.addEffect(self.maxTip, {color=ui.COLORS.NORMAL.DEFAULT})
			else
				self.maxTip:text(gLanguageCsv.energyOverflow)
				text.addEffect(self.maxTip, {color=ui.COLORS.NORMAL.ALERT_ORANGE})
			end
		end
		adapt.oneLinePos(self.numLabel, {self.maxNumLabel, self.maxTip}, {cc.p(0, 0), cc.p(10, 0)})
	end
	local flag3 = flag1 and "normal" or "hsl_gray"
	local flag4 = flag2 and "normal" or "hsl_gray"
	if contentType == "slider" then
		self.sliderSubBtn:setTouchEnabled(flag1)
		self.sliderAddBtn:setTouchEnabled(flag2)
		cache.setShader(self.sliderSubBtn, false, flag3)
		cache.setShader(self.sliderAddBtn, false, flag4)
		self.sliderPanel:show()
		self.numPanel:hide()
	elseif contentType == "num" then
		self.numSubBtn:setTouchEnabled(flag1)
		self.numAddBtn:setTouchEnabled(flag2)
		cache.setShader(self.numSubBtn, false, flag3)
		cache.setShader(self.numAddBtn, false, flag4)
		self.numSubTenBtn:setTouchEnabled(flag1)
		self.numAddTenBtn:setTouchEnabled(flag2)
		cache.setShader(self.numSubTenBtn, false, flag3)
		cache.setShader(self.numAddTenBtn, false, flag4)
		self.numPanel:get("num"):text(num)

		self.sliderPanel:hide()
		self.numPanel:show()
	else
		self.sliderPanel:hide()
		self.numPanel:hide()
	end
end

function BuyInfoView:setProductData(num, costMap)
	-- 非拖动时才设置进度
	local percent = math.floor(num / self.maxNum * 100)
	self.slider:setPercent(percent)

	-- 刷新价格列表显示(价格panel显示状态下执行)
	if self.pricePanel:visible() then
		local data = {}
		for k,v in csvMapPairs(costMap) do
			-- key消耗道具id,用于获取图标, cost当前消耗数量,用于数量显示
			table.insert(data, {key = k, cost = v*num})
		end
		-- 重置priceListWidth
		self.priceListWidth:set(0)
		self.priceData:update(data)
	end
end

function BuyInfoView:onIncreaseNum(step)
	self.num:modify(function(num)
		-- 特殊体验处理，如果数量为1，加10，则为加到10
		if num == 1 and step == 10 then
			return true, cc.clampf(10, 1, math.max(self.maxNum, 1))
		end
		return true, cc.clampf(num + step, 1, math.max(self.maxNum, 1))
	end)
end

function BuyInfoView:onChangeNum(node, event, step)
	if event.name == "click" then
		self:unScheduleAll()
		self:onIncreaseNum(step)

	elseif event.name == "began" then
		self:schedule(function()
			self:onIncreaseNum(step)
		end, 0.05, 0, 1)

	elseif event.name == "ended" or event.name == "cancelled" then
		self:unScheduleAll()
	end
end

function BuyInfoView:onBuyItem()
	local needRmb = false
	local showCost = 0
	if self.flag == BUY_INFO.buy then
		-- 货币不足的时候的处理
		for k,v in self.priceData:pairs() do
			local key = v:read().key
			local cost = mathEasy.getPreciseDecimal(v:read().cost* self.discount, 0, true)
			local num = dataEasy.getNumByKey(key)
			if num < cost then
				uiEasy.showDialog(key, nil, {dialog = true})
				return
			end
		end
	end

	for k,v in self.priceData:pairs() do
		local key = v:read().key
		if key == "rmb" then
			needRmb = true
			showCost = mathEasy.getPreciseDecimal(v:read().cost* self.discount, 0, true)
			break
		end
	end

	-- 购买/兑换已达上限处理
	if self.stackState == STACK_STATE.reach then
		local name = string.gsub(BUTTON_TEXT[self.flag], "%s+", "") -- 去掉空格
		gGameUI:showTip(gLanguageCsv.itemStackReachMax, name)
		return
	end

	-- 购买/兑换当前未达上限，购买后超过上限处理
	local function buycb(num, selectID)
		if (self.flag == BUY_INFO.buy or self.flag == BUY_INFO.exchange) and needRmb then
			dataEasy.sureUsingDiamonds(function ()
				if selectID then
					self:addCallbackOnExit(functools.partial(self.cb, num, selectID))
				else
					self:addCallbackOnExit(functools.partial(self.cb, num))
				end
				ViewBase.onClose(self)
			end, showCost)
		else
			if selectID then
				self:addCallbackOnExit(functools.partial(self.cb, num, selectID))
			else
				self:addCallbackOnExit(functools.partial(self.cb, num))
			end
			ViewBase.onClose(self)
		end
	end
	local num = self.num:read()
	if self.stackState == STACK_STATE.over then
		local name = string.gsub(BUTTON_TEXT[self.flag], "%s+", "") -- 去掉空格
		gGameUI:showDialog{content = string.format(gLanguageCsv.itemStackOverMax, name), cb = function()
			buycb(num)
		end, btnType = 2, clearFast = true, align = "left"}
	else
		if self.selectID then
			local data = self.selectData:atproxy(self.selectID:read())
			local num = dataEasy.getNumByKey(data.key)
			local cost = data.val
			if cost > num then
				uiEasy.showDialog(data.key, nil, {dialog = true})
			else
				buycb(num, self.selectID:read())
			end
		else
			buycb(num)
		end
	end
end

-- @desc 设置价格列表位置居中显示
function BuyInfoView:onAfterBuildPriceList()
	local num = itertools.size(self.priceData) -- 价格列表数量
	self.priceList:width(PRICELISTMARGIN*(num - 1) + self.priceListWidth:read())
	adapt.oneLineCenterPos(cc.p(self.pricePanel:width()/2, self.priceDesc:y()), {self.priceDesc, self.priceList}, cc.p(0, -self.priceList:height()/2))
end

-- @desc 设置价格复选框位置居中显示
function BuyInfoView:onAfterBuildSelectList()
	local num = itertools.size(self.selectData)
	self.selectList:width(self.selectListWidth:read())
	adapt.oneLineCenterPos(cc.p(self.selectPanel:width()/2, self.selectDesc:y()), {self.selectDesc, self.selectList}, cc.p(0, -self.selectList:height()/2))
end

function BuyInfoView:onSelectedClick(list, k, v)
	self.selectID:set(k)
end

return BuyInfoView
