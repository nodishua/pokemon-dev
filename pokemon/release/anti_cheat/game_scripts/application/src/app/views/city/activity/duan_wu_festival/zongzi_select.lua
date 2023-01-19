local ViewBase = cc.load("mvc").ViewBase
local ZongziSelectView = class("ZongziSelectView", Dialog)

local animaName = {}
animaName[6358] = "effect_baoyu"
animaName[6362] = "effect_mizao"
animaName[6363] = "effect_mizao"
animaName[6360] = "effect_rou"
animaName[6361] = "effect_rou"
animaName[6359] = "effect_shuangpin"

ZongziSelectView.RESOURCE_FILENAME = "activity_zongzi_select.json"
ZongziSelectView.RESOURCE_BINDING = {
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
					local cfg = dataEasy.getCfgByKey(v.key)
					local label = beauty.singleTextLimitWord(cfg.name, {fontSize = 40}, {width = 240})
						:xy(125, 26)
						:addTo(node, 2, "label")
					text.addEffect(label, {color = ui.COLORS.NORMAL.DEFAULT})
					node:get("choose"):visible(v.isSel)
				end,
				onAfterBuild = function (list)
					list:setItemAlignCenter()
				end
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
	["rightBg"] = "rightBg",
	["imgBg1"] = "imgBg1",
}

function ZongziSelectView:initModel( )
	self.itemModels = gGameModel.role:getIdler("items")
	self.choose = idler.new(1)	-- 默认勾选礼包第一个
	self.itemDatas = idlers.new()	--粽子数据
	self.num = idler.new(1)
	self.maxNum = 0
end
function ZongziSelectView:onCreate()
	self:initModel()
	self:enableSchedule()
	self.list:y(670)
	idlereasy.when(self.itemModels, function(_,  items)
		local itemDatas = {}
		for k,v in pairs(items) do
			if k >= 6358 and k <= 6363 then
				table.insert(itemDatas, {key = k, num = v, isSel = false,quality = csv.items[k].quality})
			end
		end

		if #itemDatas > 0  then
			self.imgBg1:hide()
			table.sort(itemDatas, function(a,b)
				return a.quality > b.quality
			end)
			local choose = self.choose:read()
			if not itemDatas[choose] or itemDatas[choose].key ~= self.lastChooseKey then
				choose = 1
			end
			self.choose:set(choose)
			itemDatas[choose].isSel = true
			self.itemDatas:update(itemDatas)
			self.maxNum = itemDatas[choose].num
			self.num:modify(function(val)
				return true, self.maxNum
			end, true)
			self.textNum:text(self.num:read().."/"..self.maxNum)
		else
			self.imgBg1:show()
		end

		local len = #itemDatas
		self.rightBg:visible(len>5)
		self.list:onScroll(function(event)
			local num = self.list:getIndex(self.list:getRightmostItemInCurrentView())
			self.rightBg:visible(num == 4 and len == 6)
		end)
	end)

	self.choose:addListener(function(val, oldval)
		if self.itemDatas:atproxy(oldval) then
			self.itemDatas:atproxy(oldval).isSel = false
		end
		local itemProxy = self.itemDatas:atproxy(val)
		itemProxy.isSel = true
		self.maxNum = itemProxy.num
		self.num:modify(function(val)
			return true, self.maxNum
		end, true)
		self.textNum:text(self.num:read().."/"..self.maxNum)
		if not self.slider:isHighlighted() then
			local percent = self.num:read() / self.maxNum
			self.slider:setPercent(percent * 100)
		end
	end)
	self.slider:setPercent(0)
	idlereasy.when(self.num, function(_, num)
		self.sliderSubBtn:setTouchEnabled(num > 1)
		self.sliderAddBtn:setTouchEnabled(num < self.maxNum)
		cache.setShader(self.sliderSubBtn, false, num > 1 and "normal" or "hsl_gray")
		cache.setShader(self.sliderAddBtn, false, num < self.maxNum and "normal" or "hsl_gray")
		if num <= 1 or num >= self.maxNum then
			self:unScheduleAll()
		end
		self.textNum:text(num.."/"..self.maxNum)
		-- 非拖动时才设置进度
		if not self.slider:isHighlighted() then
			local percent = num / self.maxNum
			self.slider:setPercent(percent * 100)
		end
	end)

	self.slider:addEventListener(function(sender,eventType)
		self:unScheduleAll()
		local percent = sender:getPercent()
		local num = cc.clampf(math.ceil(self.maxNum* percent * 0.01), 1, self.maxNum)
		self.num:set(num)
	end)
	Dialog.onCreate(self)
end

function ZongziSelectView:onOpen()
	local choose = self.choose:read()
	local key = self.itemDatas:atproxy(choose).key
	local showOver = {false}
	gGameApp:requestServerCustom("/game/role/item/use")
		:params({[key] = self.num:read()})
		:onResponse(function (tb)
			self.lastChooseKey = key
			self.animaBa = widget.addAnimation(self, "duanwuzongzi/chizongzi.skel", animaName[key], 1)
				:xy(cc.p(1280, 720))
				:scale(3)
			performWithDelay(self, function()
				showOver[1] = true
				self.animaBa:removeFromParent()
				self.animaBa = nil
				gGameUI:showGainDisplay(tb)
			end, 4)
		end)
		:wait(showOver)
		:doit(function (tb)
	end)
end

function ZongziSelectView:onItemClick(list, panel, k, v)
	if self.choose:read() ~= k then
		self.choose:set(k)
	else
		gGameUI:showItemDetail(panel, v)
	end
end

function ZongziSelectView:onIncreaseNum(step)
	self.num:modify(function(num)
		return true, cc.clampf(num + step, 1, self.maxNum)
	end)
end

function ZongziSelectView:onChangeNum(node, event, step)
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

return ZongziSelectView