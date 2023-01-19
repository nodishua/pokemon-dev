-- @date:   2019-9-24 17:41:26
-- @desc:   多选礼包界面

local ViewBase = cc.load("mvc").ViewBase
local GiftChooseView = class("GiftChooseView", Dialog)

GiftChooseView.RESOURCE_FILENAME = "gift_choose.json"
GiftChooseView.RESOURCE_BINDING = {
	["title.btnClose"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")},
		}
	},
	["btnOpen"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onOpen")},
		}
	},
	["btnSell.textNote"] = {
		binds = {
			event = "effect",
			data = {glow = {color = ui.COLORS.GLOW.WHITE}}
		}
	},
	["open.textNum"] = "textNum",
	["item"] = "item",
	["list"] = {
		varname = "list",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("itemDatas"),
				item = bindHelper.self("item"),
				onItem = function(list, node, k, v)
					bind.extend(list, node:get("panel"), {
						class = "icon_key",
						props = {
							data = {
								key = v.key,
								num = v.num,
							},
							onNode = function(node)
								bind.click(list, node, {method = functools.partial(list.itemClick, node, k, v)})
							end,
						}
					})
					node:removeChildByName("label")		-- 添加前先移除，防止重复添加导致叠在一起
					local cfg = {}
					if v.key == "card" then
						local cardCfg = csv.cards[v.num]
						cfg = csv.unit[cardCfg.unitID]
					else
						cfg = dataEasy.getCfgByKey(v.key)
					end
					local label = beauty.singleTextLimitWord(cfg.name, {fontSize = 40}, {width = 240})
						:xy(125, 26)
						:addTo(node, 2, "label")
					text.addEffect(label, {color = ui.COLORS.NORMAL.DEFAULT})
					node:get("choose"):visible(v.isSel)
				end,
			},
			handlers = {
				itemClick = bindHelper.self("onItemClick"),
			},
		},
	},
	["sliderPanel.slider"] = "slider",
	["sliderPanel.subBtn"] = {
		varname = "sliderSubBtn",
		binds = {
			event = "touch",
			longtouch = true,
			method = bindHelper.defer(function(view, node, event)
				return view:onChangeNum(node, event, -1)
			end),
		},
	},
	["sliderPanel.addBtn"] = {
		varname = "sliderAddBtn",
		binds = {
			event = "touch",
			longtouch = true,
			method = bindHelper.defer(function(view, node, event)
				return view:onChangeNum(node, event, 1)
			end),
		},
	},
	["rightBg"] = "rightBg"
}

function GiftChooseView:onCreate(itemDatasId, params, cb)
	self.itemDatasId = itemDatasId
	self.itemDatas = idlers.new()	--礼包数据
	self:enableSchedule()

	local itemDatas = {}
	local cfg = dataEasy.getCfgByKey(itemDatasId)
	for k,v in csvMapPairs (cfg.specialArgsMap) do
		if not v.card then
			for k2,v2 in csvMapPairs(v) do
				table.insert(itemDatas, {key = k2, num = v2,  isSel = false, choose = k})
			end
		end

		if v.card then
			for k2,v2 in csvMapPairs(v.card) do
				table.insert(itemDatas, {key = "card", num = v2,  isSel = false, choose = k})
			end
		end
	end
	table.sort(itemDatas, dataEasy.sortItemCmp)
	self.itemDatas:update(itemDatas)
	self.choose = idler.new(1)	-- 默认勾选礼包第一个
	self.choose:addListener(function(val, oldval)
		if self.itemDatas:atproxy(oldval) then
			self.itemDatas:atproxy(oldval).isSel = false
		end
		self.itemDatas:atproxy(val).isSel = true
		self.params = {key = itemDatas[val].key, num = itemDatas[val].num}
	end)

	self.cb = cb
	local percent = 0.5
	self.slider:setPercent(percent * 100)
	self.num = params.num and params.num() or idler.new(1)
	self.maxNum = params.maxNum or 1
	idlereasy.when(self.num, function(_, num)
			self.sliderSubBtn:setTouchEnabled(num > 1)
			self.sliderAddBtn:setTouchEnabled(num < self.maxNum)
			cache.setShader(self.sliderSubBtn, false, num > 1 and "normal" or "hsl_gray")
			cache.setShader(self.sliderAddBtn, false, num < self.maxNum and "normal" or "hsl_gray")
			self.textNum:text(self.num:read().."/"..self.maxNum)
		-- 非拖动时才设置进度
		if not self.slider:isHighlighted() then
			local percent = num / self.maxNum
			self.slider:setPercent(percent * 100)
		end
	end)
	self.slider:addEventListener(function(sender,eventType)
		self:unScheduleAll()
		local percent = sender:getPercent()
		local num = cc.clampf(math.ceil(self.maxNum * percent * 0.01), 1, self.maxNum)
		self.num:set(num)
	end)

	local sizeMax = self.list:width()
	local len = #itemDatas
	local x, y = self.list:xy()
	local size = self.list:size()
	y = y + size.height / 2
	local margin = self.list:getItemsMargin()
	local width = sizeMax < self.item:size().width * len + (len - 1) * margin and sizeMax or self.item:size().width * len + (len - 1) * margin
	self.list:size(width, size.height)
	self.list:anchorPoint(0.5, 0.5)
	self.list:xy(display.sizeInView.width / 2, y)
	self.list:onScroll(function(event)
		local num = self.list:getIndex(self.list:getRightmostItemInCurrentView())
		self.rightBg:visible(num+1 < len)
	end)
	Dialog.onCreate(self)
end

function GiftChooseView:onOpen()
	local num = self.num:read()
	local choose = self.itemDatas:atproxy(self.choose:read()).choose
	local key = self.params.key
	local nums = self.params.num
	local name = uiEasy.setIconName(key, nums)
	if nums > 1 and key ~= "card" and key ~= "explore" then
		name = gLanguageCsv.symbolBracketLeft .. name .. "x" .. nums .. gLanguageCsv.symbolBracketRight
	end
	gGameUI:showDialog({
		strs = {
			string.format(gLanguageCsv.sureProp, name, num)
		},
		isRich = true,
		cb = function ()
			self:addCallbackOnExit(functools.partial(self.cb, num, choose))
			ViewBase.onClose(self)
		end,
		btnType = 2,
	})
end


function GiftChooseView:onItemClick(list, panel, k, v)
	if self.choose:read() ~= k then
		self.choose:set(k)
	else
		gGameUI:showItemDetail(panel, self.params)
	end
end

function GiftChooseView:onIncreaseNum(step)
	self.num:modify(function(num)
		return true, cc.clampf(num + step, 1, self.maxNum)
	end)
end

function GiftChooseView:onChangeNum(node, event, step)
	if event.name == "click" then
		self:unScheduleAll()
		self:onIncreaseNum(step)

	elseif event.name == "began" then
		self:schedule(function()
			self:onIncreaseNum(step)
		end, 0.05, 0, 100)

	elseif event.name == "ended" or event.name == "cancelled" then
		self:unScheduleAll()
	end
end

return GiftChooseView