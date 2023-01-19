-- @date 2018-11-13
-- @desc 背包

local insert = table.insert

local LINE_NUM = 5
local PADDING_WIDTH = 10
local TAB_TYPE = {
	all = 0, -- 全部
	consumable = 1, -- 消耗品
	material = 2, -- 材料
	fragment = 3, -- 碎片
}
local BTN_TYPE = {
	none = 0, -- 无
	gainWay = 1, -- 获得途径
	use = 2, -- 使用
	open = 3, -- 打开
	sell = 4, -- 出售
	comb = 5, -- 万能碎片合成
	itemComb = 6, --碎片合成
}
local EXPIRE_STATE = {
	forever = 1, --永久有效
	willUnuse = 2, -- 将会失效
	willDestroy = 3, -- 将会消失
	unuse = 4, -- 失效
	destroy = 5, -- 消失
}

--端午粽子特效
local animaName = {
	[6358] = "effect_baoyu",
	[6362] = "effect_mizao",
	[6363] = "effect_mizao",
	[6360] = "effect_rou",
	[6361] = "effect_rou",
	[6359] = "effect_shuangpin",
}

-- 根据配置条目计算过期的状态
local function getExpireState(cfg)
	if not cfg.dateType or cfg.dateType == 0 then
		return EXPIRE_STATE.forever
	end
	local now = time.getTime()
	if cfg.dateType == 2 then
		local hour, min = time.getHourAndMin(cfg.expireTime, true)
		local expireTime = time.getNumTimestamp(cfg.expireDate, hour, min)
		if expireTime > now then
			local _, month, day = time.getYearMonthDay(cfg.expireDate)
			local str = string.formatex(gLanguageCsv.timeMonthDay, {month = month, day = day}) .. string.format("%02d:%02d", hour, min)
			if cfg.timeOut == 3 then
				return EXPIRE_STATE.willUnuse, string.format(gLanguageCsv.itemExpireWillUnuse, str), "#C0x60C456#"
			end
			return EXPIRE_STATE.willDestroy, string.format(gLanguageCsv.itemExpireWillDestory, str), "#C0x60C456#"
		end
		if cfg.timeOut == 3 then
			return EXPIRE_STATE.unuse, gLanguageCsv.itemExpireUnuse, "#C0xF76B45#"
		end
		return EXPIRE_STATE.destroy
	end
	return EXPIRE_STATE.forever
end

-- 判定 cfg 配置是否要在 tab 页签中显示
local function showInBag(cfg, tab)
	if not (APP_CHANNEL == "none" or APP_CHANNEL == "luo") and cfg.isShow == false then
		return false
	end
	-- 0 表示不在背包中显示
	if cfg.pageTag[1] == 0 then
		return false
	end
	-- 全部页签中显示
	if tab == 1 then
		return true
	end
	for _, v in ipairs(cfg.pageTag) do
		if v == tab - 1 then
			return true
		end
	end
	return false
end

local ViewBase = cc.load("mvc").ViewBase
local BagView = class("BagView", ViewBase)

BagView.RESOURCE_FILENAME = "bag.json"
BagView.RESOURCE_BINDING = {
	["leftPanel.item"] = "leftItem",
	["leftPanel.list"] = {
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("leftDatas"),
				item = bindHelper.self("leftItem"),
				itemAction = {isAction = true},
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
						panel:get("subTxt"):text(v.subName)
					end
					panel:get("txt"):text(v.name)
					selected:setTouchEnabled(false)
					bind.touch(list, normal, {methods = {ended = functools.partial(list.clickCell, k)}})
				end,
			},
			handlers = {
				clickCell = bindHelper.self("onLeftItemClick"),
			},
		},
	},
	["midPanel"] = "midPanel",
	["midPanel.item"] = "item",
	["midPanel.subList"] = "subList",
	["midPanel.list"] = {
		varname = "list",
		binds = {
			event = "extend",
			class = "tableview",
			props = {
				data = bindHelper.self("showdata"),
				columnSize = bindHelper.self("midColumnSize"),
				item = bindHelper.self("subList"),
				cell = bindHelper.self("item"),
				leftPadding = PADDING_WIDTH,
				topPadding = PADDING_WIDTH,
				itemAction = {isAction = true},
				onCell = function(list, node, k, v)
					bind.extend(list, node, {
						class = "icon_key",
						props = {
							data = {
								key = v.id,
								num = v.num,
							},
							noListener = true,
							onNode = function(node)
								node:scale(1.25)
								if v.selectEffect then
									v.selectEffect:removeSelf()
									v.selectEffect:alignCenter(node:size())
									node:add(v.selectEffect, -1)
								end
								local t = list:getIdx(k)
								bind.click(list, node, {method = functools.partial(list.itemClick, t, v)})
							end,
						},
					})
				end,
				asyncPreload = bindHelper.self("midAsyncPreload"),
			},
			handlers = {
				itemClick = bindHelper.self("onItemClick"),
			},
		},
	},
	["midPanel.info"] = {
		binds = {
			event = "visible",
			idler = bindHelper.self("info"),
		},
	},
	["rightPanel"] = "rightPanel",
	["rightPanel.numPanel.num"] = "rightNum",
	["rightPanel.numPanel.subBtn"] = {
		varname = "subBtn",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onSubItem")}
		},
	},
	["rightPanel.numPanel.addBtn"] = {
		varname = "addBtn",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onAddItem")}
		},
	},
	["rightPanel.numPanel.maxBtn"] = {
		varname = "maxBtn",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onMaxItem")}
		},
	},
	["rightPanel.leftBtn"] = {
		varname = "leftBtn",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onLeftBtnClick")}
		},
	},
	["rightPanel.leftBtn.txt"] = {
		binds = {
			event = "effect",
			data = {color = ui.COLORS.NORMAL.WHITE, glow = {color = ui.COLORS.GLOW.WHITE}},
		},
	},
	["rightPanel.rightBtn"] = {
		varname = "rightBtn",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onRightBtnClick")}
		},
	},
	["rightPanel.rightBtn.txt"] = {
		binds = {
			event = "effect",
			data = {color = ui.COLORS.NORMAL.WHITE, glow = {color = ui.COLORS.GLOW.WHITE}},
		},
	},
}

function BagView:onCreate()
	self.subList:width(self.list:width() + PADDING_WIDTH * 2)
	self.list:width(self.list:width() + PADDING_WIDTH * 2)
	self.list:x(self.list:x() - PADDING_WIDTH)
	local _, count = adapt.centerWithScreen("left", "right", {
		itemWidth = self.item:size().width,
		itemWidthExtra = 60,
	},{
		{self.subList, "width"},
		{self.list, "width"},
		{self.midPanel, "width"},
		{self.midPanel, "pos", "left"},
	})
	self.midColumnSize = LINE_NUM + count
	self.midAsyncPreload = self.midColumnSize * 5

	self:initModel()

	gGameUI.topuiManager:createView("default", self, {onClose = self:createHandler("onClose")})
		:init({title = gLanguageCsv.bag, subTitle = "BACKPACK"})

	-- 显示效果设置
	self.leftBtnPosX = self.leftBtn:x()
	self.rightBtnPosX = self.rightBtn:x()

	-- 选中标记创建
	self.selectEffect = ccui.ImageView:create("common/box/box_selected.png")
		:alignCenter(self.item:size())
		:retain()

	-- 全部 消耗品 材料 装备 碎片 携带道具
	self.leftDatas = idlers.newWithMap({
		{name = gLanguageCsv.spaceAll, subName = "ALL"},
		{name = gLanguageCsv.consumable, subName = "Consumable"},
		{name = gLanguageCsv.spaceMaterial, subName = "Material"},
		{name = gLanguageCsv.spaceFragment, subName = "Spall"},
	})

	-- idler 定义
	self.showTab = idler.new(1)
	self.showdata = idlers.new()
	self.selectItem = idlertable.new({})
	self.num = idler.new(1)
	self.maxNum = idler.new(1)
	self.info = idler.new(false)

	-- self.refreshDelayNums 刷新延迟次数, 默认0
	self.refreshDelayNums = 0
	idlereasy.any({self.items, self.frags, self.zfrags}, function()  -- 这里frags的刷新总是会二次属性，导致有异常，考虑是否可以去掉
		-- 禁止同一帧刷新连续两次刷新，连续两次属性会导致list获取显示区域中间item序号错误，根据次数延迟若干帧数刷新
		if self.refreshDelayNums > 0 then
			performWithDelay(self, function ()
				self:refreshShowData()
			end, 1/60 * self.refreshDelayNums)
			return
		end
		self:refreshShowData()
	end)

	-- idler 监听触发
	self.showTab:addListener(function(val, oldval)
		self.list:jumpToTop()
		self.leftDatas:atproxy(oldval).select = false
		self.leftDatas:atproxy(val).select = true
		dataEasy.tryCallFunc(self.list, "setItemAction", {isAction = true})
		self:refreshShowData(val)
	end)
	self.selectItem:addListener(function(val, oldval)
		if next(oldval) then
			local data = self.showdata:atproxy(oldval.k)
			if data.selectEffect ~= nil then
				data.selectEffect = nil
			end
		end
		if next(val) then
			local data = self.showdata:atproxy(val.k)
			if data.selectEffect ~= self.selectEffect then
				data.selectEffect = self.selectEffect
			end
			self:resetShowPanel(data)
			self.rightPanel:show()
		else
			self.rightPanel:hide()
		end
	end)
	idlereasy.any({self.num, self.maxNum}, function(_, num, maxNum)
		self.rightNum:text(num)
		self.subBtn:setTouchEnabled(num > 1)
		self.addBtn:setTouchEnabled(num < maxNum)
		self.maxBtn:setTouchEnabled(num < maxNum)
		cache.setShader(self.subBtn, false, num > 1 and "normal" or "hsl_gray")
		cache.setShader(self.addBtn, false, num < maxNum and "normal" or "hsl_gray")
	end)

	self.sellItems = {}
	for i,v in ipairs(gAutoSellItemsCsv) do
		local num = self.items:read()[v.id] or 0
		if num > 0 then
			table.insert(self.sellItems, {num = num, id = v.id})
		end
	end
	if #self.sellItems > 0 then
		self.isShowSellItem = true
		gGameUI:stackUI("city.shop_sell", nil, nil, self.sellItems, self:createHandler("onShowSellItem"))
	end
end

function BagView:onShowSellItem()
	self.isShowSellItem = false
end

function BagView:onCleanup()
	self.selectEffect:release()
	ViewBase.onCleanup(self)
end

function BagView:initModel()
	self.items = gGameModel.role:getIdler("items")
	self.frags = gGameModel.role:getIdler("frags")
	self.zfrags = gGameModel.role:getIdler("zfrags")
	self.stamina = gGameModel.role:getIdler("stamina")
end

function BagView:onLeftItemClick(list, index)
	self.showTab:set(index)
end

function BagView:onItemClick(list, t, v)
	t.data = v
	self.selectItem:set(t)
end

function BagView:onSubItem()
	self.num:modify(function(val)
		return true, val - 1
	end)
end

function BagView:onAddItem()
	self.num:modify(function(val)
		return true, val + 1
	end)
end

function BagView:onMaxItem()
	self.num:set(self.maxNum)
end

function BagView:onLeftBtnClick()
	self:onBtnClick(self.leftBtn, self.leftBtnState)
end

function BagView:onRightBtnClick()
	self:onBtnClick(self.rightBtn, self.rightBtnState)
end

function BagView:onBtnClick(node, state)
	local data = self.showdata:atproxy(self.selectItem:read().k)
	local id = data.id
	local cfg = data.cfg
	local maxNum = self.maxNum:read()

	-- 处理一些不弹出使用框的逻辑
	if state == BTN_TYPE.use or state == BTN_TYPE.open then
		if cfg.type == game.ITEM_TYPE_ENUM_TABLE.staminaRecover and self.stamina:read() >= game.STAMINA_LIMIT then
			gGameUI:showTip(gLanguageCsv.staminaFull)
			return
		end

		-- 礼包默认开启数量调到max, 体力使用，多选1，礼包仍为1
		if cfg.type == game.ITEM_TYPE_ENUM_TABLE.gift or cfg.type == game.ITEM_TYPE_ENUM_TABLE.randomGift then
			self.num:set(maxNum)
		end
	end

	local function useOrOpen(flag)
		if cfg.type == game.ITEM_TYPE_ENUM_TABLE.chooseGift then
			gGameUI:stackUI("city.gift_choose", nil, nil,
				id,
				{num = self:createHandler("num"), maxNum = maxNum, flag = flag},
				self:createHandler("onUseCb", id, cfg)
			)
			return
		end

		if maxNum <= 1 then
			self:onUseCb(id, cfg, maxNum)
			return
		end

		gGameUI:stackUI("common.buy_info", nil, nil,
			nil,
			{id = id},
			{num = self:createHandler("num"), maxNum = maxNum, flag = flag, contentType = "slider", style = 2},
			self:createHandler("onUseCb", id, cfg)
		)
	end

	if state == BTN_TYPE.gainWay then
		jumpEasy.jumpTo("gainWay", id)
	elseif state == BTN_TYPE.itemComb then
		gGameUI:stackUI("city.card.star_combfrags", nil, nil, id)
	elseif state == BTN_TYPE.comb then
		gGameUI:stackUI("city.card.star_changefrags")
	elseif cfg.use and cfg.use ~= "" then
			jumpEasy.jumpTo(cfg.use)
	elseif state == BTN_TYPE.use then
		useOrOpen("use")
	elseif state == BTN_TYPE.open then
		useOrOpen("open")
	elseif state == BTN_TYPE.sell then
		if maxNum <= 1 then
			self:onSellCb(id, maxNum)
		else
			gGameUI:stackUI("common.buy_info", nil, nil,
				{gold = cfg.sellPrice or 0},
				{id = id},
				{num = self:createHandler("num"), maxNum = maxNum, flag = "sell", contentType = "slider", style = 2},
				self:createHandler("onSellCb", id)
			)
		end
	end
end

-- @ desc choose 多选1礼包需要传入字段 choose1，choose2，...
function BagView:onUseCb(id, cfg, num, choose)
	if cfg.type == game.ITEM_TYPE_ENUM_TABLE.staminaRecover then
		gGameApp:requestServer("/game/role/stamina/use_item", function(tb)
			gGameUI:showTip(gLanguageCsv.useSuccess)
		end, id, num)
	elseif cfg.type == game.ITEM_TYPE_ENUM_TABLE.chooseGift then
		gGameApp:requestServer("/game/role/gift/choose", function(tb)
			gGameUI:showGainDisplay(tb)
		end, id, num, choose)
	else
		local showOver = {false}
		gGameApp:requestServerCustom("/game/role/item/use")
			:params({[id] = num})
			:onResponse(function (tb)
				local time = 0
				if animaName[id] then
					if self.animaZongzi then
						self.animaZongzi:play(animaName[id])
					else
						self.animaZongzi = widget.addAnimation(self, "duanwuzongzi/chizongzi.skel", animaName[id], 10)
							:xy(cc.p(1280, 720))
							:scale(3)
					end
					time = 3
				end
				performWithDelay(self, function()
					showOver[1] = true
					gGameUI:showGainDisplay(tb)
				end, time)
			end)
			:wait(showOver)
			:doit(function (tb)
			end)
	end
end

function BagView:onSellCb(id, num)
	if dataEasy.isFragment(id) then
		gGameApp:requestServer("/game/role/frag/sell_many", function(tb)
			gGameUI:showTip(gLanguageCsv.sellSuccess)
		end, {[id] = num})
	else
		gGameApp:requestServer("/game/role/item/sell", function(tb)
			gGameUI:showTip(gLanguageCsv.sellSuccess)
		end, {[id] = num})
	end
end

function BagView:refreshShowData(changeTab)
	if not changeTab then
		-- 非切换状态下，每刷新一次，次数+1，一帧后减一，防止同一帧刷新多次
		self.refreshDelayNums = self.refreshDelayNums + 1
		performWithDelay(self, function ()
			self.refreshDelayNums = math.max((self.refreshDelayNums - 1), 0)
		end, 1/60)
	end

	-- 获取该页签的有效数据
	local data = {}
	local showTab = changeTab or self.showTab:read()
	idlereasy.do_(function(items, frags, zfrags)
		for id, num in itertools.chain({items, frags, zfrags}) do
			local cfg = dataEasy.getCfgByKey(id)
			if showInBag(cfg, showTab) then
				local state, info, effect = getExpireState(cfg)
				-- 过期的不加到数据里
				if state ~= EXPIRE_STATE.destroy then
					insert(data, {id = id, num = num, cfg = cfg, expireState = state, expireInfo = info, expireInfoEffect = effect})
				end
			end
		end
	end, self.items, self.frags, self.zfrags)

	-- 排序
	local tabValue = {
		[TAB_TYPE.consumable] = 1,
		[TAB_TYPE.material] = 2,
		[TAB_TYPE.fragment] = 3,
	}
	local function cmpValue(v)
		local val = 3
		if v.expireState == EXPIRE_STATE.willUnuse or v.expireState == EXPIRE_STATE.willDestroy then
			val = 1

		elseif v.expireState == EXPIRE_STATE.forever then
			val = 2
		end
		return val * 100 + (tabValue[v.cfg.pageTag[1]] or 9) * 10
	end
	table.sort(data, function(a, b)
		local va = cmpValue(a)
		local vb = cmpValue(b)
		if va ~= vb then
			return va < vb
		end
		if a.cfg.sortType ~= b.cfg.sortType then
			return a.cfg.sortType > b.cfg.sortType
		end
		if a.cfg.sortValue ~= b.cfg.sortValue then
			return a.cfg.sortValue > b.cfg.sortValue
		end
		if a.cfg.quality ~= b.cfg.quality then
			return a.cfg.quality > b.cfg.quality
		end
		return a.id < b.id
	end)

	-- 刷新选中道具
	local lastSelect = self.selectItem:read()
	local index = nil
	if #data == 0 then
		-- 空的时候清除右侧选中道具

	elseif changeTab or not lastSelect.data then
		index = 1
	else
		for i, v in ipairs(data) do
			if v.id == lastSelect.data.id then
				index = i
				break
			end
		end
		if not index then
			index = math.min(lastSelect.k or 1, #data)
		end
	end

	self.selectItem:set({})

	-- 设置数据，选把当前数据上的选中状态清除
	if index then
		if not changeTab and not self.isShowSellItem then
			dataEasy.tryCallFunc(self.list, "updatePreloadCenterIndexAdaptFirst")
		end
		data[index].selectEffect = self.selectEffect
		self.showdata:update(data)
		self.selectItem:set({k = index, data = data[index]})
		self.info:set(false)
	else
		self.showdata:update({})
		self.info:set(true)
	end
end

function BagView:resetShowPanel(data)
	self.num:set(1)
	self.maxNum:set(data.num)
	bind.extend(self, self.rightPanel, {
		class = "icon_key",
		props = {
			data = {
				key = data.id,
			},
			noListener = true,
			simpleShow = true,
			onNode = function(node)
				node:xy(self.rightPanel:get("icon"):xy())
					:scale(2)
					:z(3)
			end,
		},
	})

	-- 设置按钮状态
	local btnData = data.cfg.effBtn
	local btnCount = itertools.size(btnData)
	self.leftBtnState = BTN_TYPE.none
	self.rightBtnState = BTN_TYPE.none
	if btnCount == 0 then
		nodetools.invoke(self.rightPanel, {"leftBtn", "rightBtn"}, "hide")

	elseif btnCount == 1 then
		self.leftBtn:x((self.leftBtnPosX + self.rightBtnPosX) / 2)
		self.leftBtnState = btnData[1]
	else
		self.leftBtn:x(self.leftBtnPosX)
		self.rightBtn:x(self.rightBtnPosX)
		self.leftBtnState = btnData[1]
		self.rightBtnState = btnData[2]
	end

	local function showBtnName(btn, state)
		if state == BTN_TYPE.use then
			btn:get("txt"):text(gLanguageCsv.spaceUse)
		elseif state == BTN_TYPE.open then
			btn:get("txt"):text(gLanguageCsv.spaceOpen)
		elseif state == BTN_TYPE.sell then
			btn:get("txt"):text(gLanguageCsv.spaceSell)
		elseif state == BTN_TYPE.gainWay then
			btn:get("txt"):text(gLanguageCsv.gainWay)
		elseif state == BTN_TYPE.comb then
			btn:get("txt"):text(gLanguageCsv.spaceComb)
		elseif state == BTN_TYPE.itemComb then
			btn:get("txt"):text(gLanguageCsv.spaceComb)
		else
			btn:hide()
			return
		end
		btn:show()
		return true
	end
	showBtnName(self.leftBtn, self.leftBtnState)
	showBtnName(self.rightBtn, self.rightBtnState)
	self.rightPanel:get("numPanel"):visible(false)

	local labelWidth = 694
	local labelHeight = 564
	local labelPosX = 10
	-- 设置name
	local name = self.rightPanel:get("nameList")
	local list = beauty.singleTextAutoScroll({
		list = name,
		size = cc.size(labelWidth, 80),
		align = "left",
		strs = {
			str = uiEasy.setIconName(data.id),
			effect = {color = cc.c4b(91, 84, 91, 255)},
		},
		fontSize = 60,
	})
	if not name then
		list:xy(labelPosX, labelHeight + 12)
			:addTo(self.rightPanel, 3, "nameList")
	end
	local strs = {{str = "#C0x5B545B#" .. uiEasy.getIconDesc(data.id, data.num)}}
	if data.cfg.desc1 and data.cfg.desc1 ~= "" then
		table.insert(strs, {fontSize = 10})
		table.insert(strs, {str = "#C0xB0B09E#" .. data.cfg.desc1})
	end
	-- 过期信息显示
	if data.expireInfo then
		table.insert(strs, {fontSize = 10})
		table.insert(strs, {str = data.expireInfoEffect .. data.expireInfo})
	end
	self.rightPanel:removeChildByName("descList")
	local list = beauty.textScroll({
		size = cc.size(labelWidth, labelHeight - 200),
		strs = strs,
		isRich = true,
	})
	list:xy(labelPosX, 200)
		:addTo(self.rightPanel, 3, "descList")
end

return BagView
