local ViewBase = cc.load("mvc").ViewBase
local ExplorerDrawItemSuccessView = class("ExplorerDrawItemSuccessView", ViewBase)

ExplorerDrawItemSuccessView.RESOURCE_FILENAME = "explore_draw_item_success.json"
ExplorerDrawItemSuccessView.RESOURCE_BINDING = {
	["bg"] = {
		binds = {
			event = "click",
			method = bindHelper.self("onClose")
		}
	},
	["btnSure"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")}
		}
	},
	["btn"] = {
		varname = "btn",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onAgain")}
		}
	},
	["item"] = "item",
	["costPanel"] = "costPanel",
	["costPanel.icon"] = "icon",
	["costPanel.num"] = "num",
	["costPanel.numNote"] = "numNote",
	["pos"] = "pos",
	["txt"] = "txt",
}

function ExplorerDrawItemSuccessView:onCreate(viewData, params)
	self:initModel()
	self.isStandby = params()
	local pnode = self:getResourceNode()
	widget.addAnimationByKey(pnode, "effect/gongxihuode.skel", 'gongxihuode', "effect", 10)
		:anchorPoint(cc.p(0.5,0.5))
		:xy(pnode:width()/2, pnode:height() - 300)
		:addPlay("effect_loop")
	local t = {}
	for i,v in ipairs(viewData.result) do
		table.insert(t, {key = v[1][1], num = v[1][2]})
	end
	local key, value = viewData.result.extra[1][1], viewData.result.extra[1][2]
	if #t == 1 then
		for i = 1, 5 do
			self:getResourceNode():get("pos"..i):hide()
		end
		local item = self.item:clone():show()
		item:addTo(self.pos)
			:alignCenter(self.pos:size())
		--普通的一抽
		bind.extend(self, item, {
			class = "explore_icon",
			props = {
				data = t[1],
				effect = "drawcard",
				onNode = function (node)
					node:scale(1.2)
				end
			}
		})
		local name, effect = uiEasy.setIconName(t[1].key, num)
		beauty.singleTextLimitWord(name, {fontSize = 40}, {width =  240})
			:xy(self.pos:size().width/2, 0)
			:addTo(item, 10)
		self.type = "one"
		self.btn:get("txt"):text(gLanguageCsv.drawItemOne)
	else
		--伍连抽
		self.icon:texture(dataEasy.getIconResByKey("rmb"))
		self.num:text(gCommonConfigCsv.draw5ItemCostPrice)
		self.pos:hide()
		table.sort(t, function (a, b)
			local aCfg = dataEasy.getCfgByKey(a.key)
			local bCfg = dataEasy.getCfgByKey(b.key)
			if aCfg.quality ~= bCfg.quality then
				return aCfg.quality < bCfg.quality
			end
			return a.key < b.key
		end)

		for i = 1, 5 do
			local item = self.item:clone():show()
			local node = self:getResourceNode():get("pos"..i)

			item:addTo(node)
				:alignCenter(node:size())
			bind.extend(self, item, {
				class = "explore_icon",
				props = {
					data = t[i],
					effect = "drawcard",
					onNode = function (node)
						node:scale(1.2)
					end
				}
			})
			local name, effect = uiEasy.setIconName(t[i].key, num)
			beauty.singleTextLimitWord(name, {fontSize = 40}, {width =  240})
				:xy(node:size().width/2, 0)
				:addTo(item, 10)
		end
		self.type = "five"
		self.btn:get("txt"):text(gLanguageCsv.drawItemFive)
	end
	local ticket = self.items:read()[game.ITEM_TICKET.card4] or 0
	local isHalf = self.itemDiamondHalfCount:read() == 0 and dataEasy.getPrivilegeVal(game.PRIVILEGE_TYPE.FirstRMBDrawItemHalf) ~= 0
	if (self.type == "one" and ticket > 0 and not isHalf) or (self.type == "five" and ticket >= 5) then
		local str = self.items:read()[game.ITEM_TICKET.card4] .. "/1"
		if self.type == "five" and ticket >= 5 then
			str = self.items:read()[game.ITEM_TICKET.card4] .. "/5"
		end
		self.num:text(str)
		self.icon:texture(dataEasy.getIconResByKey(game.ITEM_TICKET.card4))
	else
		if self.type == "one" then
			local price = gCommonConfigCsv.drawItemCostPrice
			if isHalf then
				price = gCommonConfigCsv.drawItemCostPrice/2
			end
			self.num:text(price)
			-- 颜色判断
			idlereasy.when(self.rmb, function (_, rmb)
				local oneCostColor = self.rmb:read() < price and ui.COLORS.NORMAL.RED or ui.COLORS.NORMAL.WHITE -- 单抽金额是否足够
				text.addEffect(self.num, {color=oneCostColor})
			end)
		else
			self.num:text(gCommonConfigCsv.draw5ItemCostPrice)
			-- 颜色判断
			idlereasy.when(self.rmb, function (_, rmb)
				local fiveCostColor = self.rmb:read() < gCommonConfigCsv.draw5ItemCostPrice and ui.COLORS.NORMAL.RED or ui.COLORS.NORMAL.WHITE -- 五连抽金额是否足够
				text.addEffect(self.num, {color=fiveCostColor})
			end)
		end
		self.icon:texture(dataEasy.getIconResByKey("rmb"))
	end
	local size = self.costPanel:size()
	adapt.oneLineCenterPos(cc.p(size.width/2, size.height/2), {self.numNote, self.num, self.icon}, cc.p(10, 0))
	local str = string.format(gLanguageCsv.extraGetCoin4, viewData.result.extra[1][2], dataEasy.getIconResByKey(viewData.result.extra[1][1]))
	local richtext = rich.createByStr(str, 40, nil, nil, cc.p(0, 0))
	richtext:addTo(self.txt)
		:alignCenter(self.txt:size())
end

function ExplorerDrawItemSuccessView:onAgain()
	local ticket = self.items:read()[game.ITEM_TICKET.card4] or 0
	local isHalf = self.itemDiamondHalfCount:read() == 0 and dataEasy.getPrivilegeVal(game.PRIVILEGE_TYPE.FirstRMBDrawItemHalf) ~= 0
	if self.type == "one" then
		if gVipCsv[self.vip:read()].drawItemCountLimit == self.totalTime:read() then
			gGameUI:showTip(gLanguageCsv.todayDrawItemLimit)
			return
		end

		-- 优先判断半价
		if isHalf and param ~= "free1" and self.rmb:read() < gCommonConfigCsv.drawItemCostPrice/2 then
			uiEasy.showDialog("rmb")
			return
		end

		if not isHalf and ticket == 0 and self.rmb:read() < gCommonConfigCsv.drawItemCostPrice and param ~= "free1" then
			uiEasy.showDialog("rmb")
			return
		end
		if (isHalf and param ~= "free1") or (not isHalf and ticket == 0 and param ~= "free1") then
			dataEasy.sureUsingDiamonds(function ()
				self:onClose(1)
			end, isHalf and gCommonConfigCsv.drawItemCostPrice/2 or gCommonConfigCsv.drawItemCostPrice)
		else
			self:onClose(1)
		end
	else
		if gVipCsv[self.vip:read()].drawItemCountLimit == self.totalTime:read() then
			gGameUI:showTip(gLanguageCsv.todayDrawItemLimit)
			return

		elseif gVipCsv[self.vip:read()].drawItemCountLimit - self.totalTime:read() < 5 then
			gGameUI:showTip(gLanguageCsv.todayDrawItemTimesLessFive)
			return
		end

		if ticket < 5 and self.rmb:read() < gCommonConfigCsv.draw5ItemCostPrice then
			uiEasy.showDialog("rmb")
			return
		end
		if ticket < 5 then
			dataEasy.sureUsingDiamonds(function ()
				self:onClose(5)
			end, gCommonConfigCsv.draw5ItemCostPrice)
		else
			self:onClose(5)
		end
	end
end

function ExplorerDrawItemSuccessView:initModel()
	self.rmb = gGameModel.role:getIdler("rmb")
	self.items = gGameModel.role:getIdler("items")
	self.vip = gGameModel.role:getIdler("vip_level")
	self.freeTime = gGameModel.daily_record:getIdler("item_dc1_free_counter")
	self.totalTime = gGameModel.daily_record:getIdler("draw_item")
	self.itemDiamondHalfCount = gGameModel.daily_record:getIdler("draw_item_rmb1_half")
end

function ExplorerDrawItemSuccessView:onClose(ticket)
	local isStandby = self.isStandby
	ViewBase.onClose(self)
	if type(ticket) == "number" then
		isStandby:set(ticket)
	else
		isStandby:set(true)
	end
end

return ExplorerDrawItemSuccessView
