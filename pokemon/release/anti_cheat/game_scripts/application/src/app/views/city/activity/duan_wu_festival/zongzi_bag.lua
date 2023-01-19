
local ZongZiBagView = class("ZongZiBagView", Dialog)
local animaName = {}
animaName[6358] = "effect_baoyu"
animaName[6362] = "effect_mizao"
animaName[6363] = "effect_mizao"
animaName[6360] = "effect_rou"
animaName[6361] = "effect_rou"
animaName[6359] = "effect_shuangpin"

ZongZiBagView.RESOURCE_FILENAME = "activity_zongzi_bag.json"
ZongZiBagView.RESOURCE_BINDING = {
	["item"] = "item",
	["innweList"] = "innweList",
	["left.list"] = {
		varname = "list",
		binds = {
			event = "extend",
			class = "tableview",
			props = {
				data = bindHelper.self("itemData"),
				item = bindHelper.self("innweList"),
				cell = bindHelper.self("item"),
				columnSize = 5,
				itemAction = {isAction = true},
				onCell = function(list, node, k, v)
					node:get("imgSel"):visible(v.isSel)
					bind.extend(list, node, {
						class = "icon_key",
						props = {
							data = {key = v.key, num = v.num},
							onNode = function(panel)
								local t = list:getIdx(k)
								bind.click(list, panel, {method = functools.partial(list.clickCell, t, v)})
							end,
						}
					})
				end,
			},
			handlers = {
				clickCell = bindHelper.self("onItemClick"),
			},
		},
	},
	["left.title.btnClose"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")},
		},
	},
	["right"] = "right",
	["right.item"] = "itemIcon",
	["right.sliderPanel.subBtn"] = {
		varname = "sliderSubBtn",
		binds = {
			event = "touch",
			longtouch = true,
			method = bindHelper.defer(function(view, node, event)
				return view:onChangeNum(node, event, -1)
			end),
		},
	},
	["right.sliderPanel.addBtn"] = {
		varname = "sliderAddBtn",
		binds = {
			event = "touch",
			longtouch = true,
			method = bindHelper.defer(function(view, node, event)
				return view:onChangeNum(node, event, 1)
			end),
		},
	},
	["right.sliderPanel.slider"] = "slider",
	["right.num"] = "itemNum",
	["right.desc"] = "desc",
}

function ZongZiBagView:onCreate(activityId)
	self.activityId = activityId
	self.item:visible(false)
	self.num = idler.new(1)
	self.selIdx = idler.new(1)
	self.maxNum = 1
	self:enableSchedule()
	self.itemData = idlers.newWithMap({})
	idlereasy.when(gGameModel.role:getIdler("items"), function(_, items)
		local data = {}
		for i=6358, 6363 do
			if items[i] then
				table.insert(data, {key = i, num = items[i], isSel = false})
			end
		end
		self.onCloseInfo = csvSize(data)
		self.itemData:update(data)
		self:onItemClick(self, {k = 1}, data[1])
	end)

	self.selIdx:addListener(function(idx, oldval)
		if self.itemData:atproxy(oldval) then
			self.itemData:atproxy(oldval).isSel = false
		end
		self.itemData:atproxy(idx).isSel = true
	end)

	local idlerTable = {self.num}
	idlereasy.any(idlerTable, function(_, num)
		self.itemNum:text(num .. "/" .. self.maxNum)
		adapt.oneLineCenterPos(cc.p(self.right:get("btnDress"):x(), 400), {self.right:get("txt1"), self.itemNum, self.right:get("txt2")})
		self.sliderAddBtn:setTouchEnabled(num < self.maxNum)
		self.sliderSubBtn:setTouchEnabled(num > 1)
		cache.setShader(self.sliderSubBtn, false, num > 1 and "normal" or "hsl_gray")
		cache.setShader(self.sliderAddBtn, false, num < self.maxNum and "normal" or "hsl_gray")
		-- 非拖动时才设置进度
		if not self.slider:isHighlighted() then
			local percent = num / self.maxNum
			self.slider:setPercent(percent * 100)
		end
	end)

	self.slider:addEventListener(function(sender,eventType)
		self:unScheduleAll()
		local percent = sender:getPercent()
		local num = cc.clampf(math.ceil(self.maxNum * percent * 0.01), 1, math.max(self.maxNum, 1))
		self.num:set(num)
	end)

	Dialog.onCreate(self)
end

function ZongZiBagView:onItemClick(list, t, v)
	if v and v.key then
		bind.extend(self, self.itemIcon, {
			class = "icon_key",
			props = {
				data = {
					key = v.key,
					num = v.num,
				},
				noListener = true,
			}
		})
		local item = csv.items
		self.right:get("textName"):text(item[v.key].name)
		self.right:get("textLv"):text(string.format(gLanguageCsv.possessIngredient, v.num))
		self.desc:text(item[v.key].desc)
		self.maxNum = gGameModel.role:read("items")[v.key] or 0
		self.num:set(self.maxNum, true)
		self.selIdx:set(t.k, true)
		self.right:get("btnDress"):onClick(function()
			local showOver = {false}
			gGameApp:requestServerCustom("/game/role/item/use")
				:params({[v.key] = self.num:read()})
				:onResponse(function (tb)
					self.animaBa = widget.addAnimation(self, "duanwuzongzi/chizongzi.skel", animaName[v.key], 1)
						:xy(cc.p(1280, 720))
						:scale(3)
					performWithDelay(self, function()
						showOver[1] = true
						self.animaBa:removeFromParent()
						self.animaBa = nil
						gGameUI:showGainDisplay(tb, {cb = function()
							if self.onCloseInfo and  self.onCloseInfo == 0 then
								self:onClose()
							end
						end})
					end, 4)
				end)
				:wait(showOver)
				:doit(function (tb)
				end)
		end)
	end
end

function ZongZiBagView:onIncreaseNum(step)
	self.num:modify(function(num)
		return true, cc.clampf(num + step, 1, math.max(self.maxNum, 1))
	end)
end

function ZongZiBagView:onChangeNum(node, event, step)
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

return ZongZiBagView