-- @desc 个体值洗练

local function createRichTxt(str, parent)
	return rich.createByStr(str, 40, nil, nil, cc.p(0, 0.5))
		:anchorPoint(0, 0.5)
		:xy(5, 25)
		:addTo(parent, 6)
end

local CardNvalueView = class("CardNvalueView", cc.load("mvc").ViewBase)

CardNvalueView.RESOURCE_FILENAME = "card_nvalue.json"
CardNvalueView.RESOURCE_BINDING = {
	["panel.btnInfo"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onShowRule")},
		},
	},
	["panel.down.img"] = "downImg",
	["panel.down.btnReset.textNote"] = {
		varname = "btnResetText",
		binds = {
			event = "effect",
			data = {glow={color=ui.COLORS.GLOW.WHITE}}
		}
	},
	["panel.down.btnReset"] = {
		varname = "btnReset",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onNvalueClick")}
		}
	},
	["panel.down.tipPanel"] = "tipPanel",
	["panel.down.costInfo"] = "costInfo",
	["panel.down.costInfo.textCostNote"] = "textCostNote",
	["panel.down.costInfo.textCostNum"] = "textCostNum",
	["panel.down.costInfo.imgIcon"] = "imgCostIcon",
	["content.bottom.listBg"] = "listBg",
	["item"] = "item",
	["panel.down.list"] = {
		varname = "list",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("itemData"),
				item = bindHelper.self("item"),
				onItem = function(list, node, k, v)
					local showAddBtn = (v.num < (v.targetNum or 0))
					node:get("btnAdd"):visible(showAddBtn)
					node:get("imgMask"):visible(showAddBtn)
					local binds = {
						class = "icon_key",
						props = {
							data = {
								key = v.id,
								num = v.num,
								targetNum = v.targetNum,
							},
							onNode = function(panel)
								panel:setTouchEnabled(false)
							end,
						},
					}
					bind.extend(list, node, binds)
					bind.touch(list, node, {methods = {ended = functools.partial(list.clickCell, v)}})
				end,
				asyncPreload = 3,
			},
			handlers = {
				clickCell = bindHelper.self("onItemClick"),
			},
		},
	},
	["panel"] = {
		varname = "bg",
		binds = {
			event = "extend",
			class = "draw_attr",
			props = {
				nvalue = bindHelper.self("showNValue"),
				nvalueLocked = bindHelper.self("nvalueLocked"),
				effectAni = bindHelper.self("animationEffect"),
				type = "big",
				selectDbId = bindHelper.self("selectDbId"),
				offsetPos = {
					{x = -120, y = -100},
					{x = 10, y = -160},
					{x = 10, y = -260},
					{x = -120, y = -320},
					{x = matchLanguage({"kr", "en"}) and -265 or -210, y = -260},
					{x = matchLanguage({"kr", "en"}) and -265 or -210, y = -160},
				},
				lockCb = function(panel, idx, dbid, tmpLockNum, state)
					if tmpLockNum >= 6 and state == true then
						gGameUI:showDialog({title = gLanguageCsv.tips, content = gLanguageCsv.nvalueAllLockedTip, cb = function()
							gGameApp:requestServer("/game/card/nvalue/locked/switch", nil, dbid, game.ATTRDEF_SIMPLE_TABLE[idx])
						end, btnType = 2})
						return
					end
					gGameApp:requestServer("/game/card/nvalue/locked/switch", nil, dbid, game.ATTRDEF_SIMPLE_TABLE[idx])
				end,
				onNode = function (panel)
					panel:xy(350, 600)
					local view = panel:parent()
					local img = panel:get("img")
					local size = img:size()
					local effect = view.effectAni
					effect:removeFromParent()
					effect:addTo(img)
						:xy(size.width / 2, size.height / 2)
				end,
				offset = {x = 230, y = 250},
				lock = true,
			},

		},
	},
}

function CardNvalueView:showAnimation()
	if not self.showNValue then
		local tb = clone(self.realNValue:read())
		self.showNValue = idlertable.new(tb)
	end

	local timeMax = 0.3		-- 动画播放的时间
	local nValueR = self.realNValue:read()
	local nValueS = self.showNValue:read()

	local isSame = true
	for typ,num in pairs(nValueS) do
		if nValueS[typ] ~= nValueR[typ] then
			isSame = false
			break
		end
	end
	if isSame then return end 		-- 相同则不用播放动画

	local value = {}
	local t = 0
	self:enableSchedule():schedule(function (dt)
		if t == 0 then 		-- 初次运行
			for typ,_ in pairs(nValueS) do
				value[typ] = nValueR[typ] - nValueS[typ]
			end
			if self.animationEffect and self.canPlayAni then
				audio.playEffectWithWeekBGM("refinement.mp3")
				self.animationEffect:show()
				self.animationEffect:play("effect")
				self.canPlayAni = nil
			end
		end

		t = t + dt
		if t >= timeMax then 		-- 计时结束
			self:unSchedule("nValueChange")
			self.showNValue:set(clone(self.realNValue:read()))
		else 		-- 播放过度动画
			local ret = {}
			for typ,_ in pairs(nValueS) do
				ret[typ] = math.floor(nValueS[typ] + value[typ] * t / timeMax)
			end
			self.showNValue:set(ret)
		end
	end, 0.03, timeMax, "nValueChange")
end

function CardNvalueView:onCreate(dbHandler)
	self.stopAni = false
	self.showNValue = nil
	self.selectDbId = dbHandler()
	self:initModel()
	for _,v in ipairs(game.ATTRDEF_SIMPLE_TABLE) do
		self[v] = idler.new("")
	end
	self.canClick = true
	self.havePerfect = false
	self.lockNum = idler.new(0)

	-- 特效动画 需另外绑定
	self.animationEffect = widget.addAnimation(self:getResourceNode(), "effect/xilian.skel", "effect", 0)
	self.animationEffect:hide()
	self.animationEffect:setSpriteEventHandler(function(_type, event)
			if _type == sp.EventType.ANIMATION_COMPLETE then
				self.animationEffect:hide()
			end
		end)

	-- self.showNValue	-- 与表现绑定的idler
	-- self.realNValue	-- 保存实际值的idler

	--洗练材料
	local csvItems = csv.card_recast
	local tmpRecastData = {}
	for k,v in ipairs(csvItems) do
		tmpRecastData[v["lockNum"]] = v.costItems
	end
	self.nvalueGold = idler.new(0)
	self.nvalueRmb = idler.new(0)
	self.lackMaterial = idler.new(false)--false表示材料充足可以洗练
	self.itemData = idlertable.new({})
	idlereasy.when(self.nvalueLocked, function (_, nvalueLocked)
		local tmpLockNum = 0
		for i,v in ipairs(game.ATTRDEF_SIMPLE_TABLE) do
			if nvalueLocked[v] then
				tmpLockNum = tmpLockNum + 1
			end
		end
		self.lockNum:set(tmpLockNum)
	end)
	idlereasy.any({self.lockNum, self.items}, function(_, lockNum, items)
		local nvalueData = tmpRecastData[lockNum]
		local tmpItemsData = {}
		self.lackMaterial:set(false)
		for i,v in csvPairs(nvalueData) do
			local myItemNum = items[i] or 0
			table.insert(tmpItemsData,{id = i, num = myItemNum, targetNum = v})
			if myItemNum < v then
				self.lackMaterial:set(true)
			end
		end
		if nvalueData.gold then
			table.insert(tmpItemsData,{id = "gold", num = nvalueData.gold})
		end
		self.nvalueGold:set(nvalueData.gold)
		-- self.listBg:setContentSize(cc.size((#tmpItemsData < 3) and 560 or 814,296))
		self.itemData:set(tmpItemsData)
		self.nvalueRmb:set(nvalueData.rmb)
		self.textCostNum:text(nvalueData.rmb)
		self.costInfo:visible(nvalueData.rmb and nvalueData.rmb > 0 or false)
		adapt.oneLineCenterPos(cc.p(self.costInfo:width()/2, self.costInfo:height()/2), {self.textCostNote, self.textCostNum, self.imgCostIcon}, cc.p(6, 0))

		if lockNum >= 6 then
			cache.setShader(self.btnReset, false, "hsl_gray")
			text.deleteAllEffect(self.btnResetText)
			text.addEffect(self.btnResetText, {color = ui.COLORS.DISABLED.WHITE})
		else
			cache.setShader(self.btnReset, false, "normal")
			text.addEffect(self.btnResetText, {color = ui.COLORS.NORMAL.WHITE, glow={color=ui.COLORS.GLOW.WHITE}})
		end
	end)
	self.upGradeData1 = {{},{},{},{},{},{}}--六个升级材料
	self.upGradeData = idlers.newWithMap(self.upGradeData1)
	idlereasy.when(self.items, function(_, items)
		for i, v in ipairs(gCardExpItemCsv) do
			local id = v.id
			self.upGradeData:at(i):modify(function(data)
				data.num = items[id] or 0
				data.quality = v.quality
				data.id = id
			end, true)
		end
	end)
	idlereasy.any({self.realNValue, self.nvalueLocked}, function(_, nvalue, nvalueLocked)
		local havePerfect = false
		for typ, num in pairs(nvalue) do
			if num >= game.NVALUE_ATTR_LIMIT and not nvalueLocked[typ] then
				havePerfect = true
			end
		end
		self.havePerfect = havePerfect
		if self.stopAni then
			local v = clone(self.realNValue:read())
			self.showNValue:set(v)
		else
			self:showAnimation()
		end
	end)

	local text1Panel = self.tipPanel:get("text1Panel")
	local text2Panel = self.tipPanel:get("text2Panel")
	self:enableSchedule()
	if not matchLanguage({"cn", "tw", "kr"}) then
		self.tipPanel:size(820, 50)
		self.tipPanel:x(self.tipPanel:x() - 150)
		adapt.oneLinePos(self.tipPanel, self.downImg, nil, "right")
	end
	idlereasy.when(self.selectDbId,function (_, selectDbId)
		local size = self.tipPanel:size()
		text1Panel:x(size.width)
		text2Panel:x(1)
		local isMax = false
		local i = 0

		self:unSchedule("CardNvalueView")
		self:schedule(function ()
			if text1Panel:getChildrenCount() == 0 then
				text2Panel:x(1)
				self:unSchedule("CardNvalueView")
			else
				local x1 = i%2 == 0 and size.width or 1
				local x2 = i%2 == 0 and 1 or size.width
				text1Panel:x(x1)
				text2Panel:x(x2)
				transition.executeSequence(text1Panel)
					:moveTo(0.3, x1 - size.width, 25)
					:done()
				transition.executeSequence(text2Panel)
					:moveTo(0.3, x2 - size.width, 25)
					:done()
			end
			i = i + 1
		end, 5, 5, "CardNvalueView")
	end)

	idlereasy.when(self.nvalueRecastTotal, function(_, nvalueRecastTotal)
		--当前值
		local nowValue = 0
		--再洗练多少次达到下一级
		local needTimes = 0
		--下一级的值
		local nextValue = 0
		for i,v in orderCsvPairs(csv.nvalue_min_value) do
			if nvalueRecastTotal >= (v.nvalueTimes - 1) and nowValue < v.minValue then
				nowValue = v.minValue
			end
			if nvalueRecastTotal < (v.nvalueTimes - 1) and nextValue == 0 then
				needTimes = (v.nvalueTimes - 1) - nvalueRecastTotal
				nextValue = v.minValue
			end
		end
		if nextValue == 0 then
			self:unSchedule("CardNvalueView")
			text2Panel:x(0)
		end
		text1Panel:removeAllChildren()
		text2Panel:removeAllChildren()
		if nextValue > 0 then
			createRichTxt(string.format(gLanguageCsv.nvalueTip1, needTimes, nextValue), text1Panel)
		end
		createRichTxt(string.format(gLanguageCsv.nvalueTip2, nowValue), text2Panel)
	end)

end

function CardNvalueView:initModel()
	self.items = gGameModel.role:getIdler("items")
	self.rmb = gGameModel.role:getIdler("rmb")
	self.gold = gGameModel.role:getIdler("gold")
	idlereasy.when(self.selectDbId,function (_, selectDbId)
		local card = gGameModel.cards:find(selectDbId)
		self.stopAni = true
		self.realNValue = idlereasy.assign(card:getIdler("nvalue"), self.realNValue)
		self.stopAni = false
		self.nvalueLocked = idlereasy.assign(card:getIdler("nvalue_locked"),self.nvalueLocked)
		self.nvalueRecastTotal = idlereasy.assign(card:getIdler("nvalue_recast_total"),self.nvalueRecastTotal)
	end)
end

function CardNvalueView:onItemClick(_, v)
	gGameUI:stackUI("common.gain_way", nil, nil, v.id, nil, v.targetNum)
end

function CardNvalueView:onNvalueClick()
	if not self.canClick then
		return
	end
	if self.lockNum:read() >= 6 then
		gGameUI:showTip(gLanguageCsv.nvalueAllLocked)
		return
	end
	local rmb = self.nvalueRmb:read()
	if rmb and rmb > 0 and self.rmb:read() < rmb then
		uiEasy.showDialog("rmb", {onClose = self:createHandler("onClose")})
		return
	end
	local gold = self.nvalueGold:read()
	if gold and gold > 0 and self.gold:read() < gold then
		gGameUI:showTip(gLanguageCsv.nvalueLackGold)
		return
	end
	if self.lackMaterial:read() then
		gGameUI:showTip(gLanguageCsv.nvalueLackMaterial)
		return
	end
	self.canClick = false
	local function recastCb(isHavePerfect)
		local function cb()
			gGameApp:requestServer("/game/card/nvalue/recast",function (tb)
				self.canPlayAni = true 		-- 用这个变量控制动画播放 否则 任何数据变动都会导致动画播放
				self.canClick = true
			end, self.selectDbId)
		end
		if rmb and rmb > 0 then
			dataEasy.sureUsingDiamonds(cb, rmb, function ()
				self.canClick = true
				if isHavePerfect then
					self.havePerfect = true
				end
			end)
		else
			cb()
		end
	end
	if self.havePerfect then
		gGameUI:showDialog({content = "#C0x5B545B#" .. gLanguageCsv.perfectNvalueTips, btnStr = gLanguageCsv.nvalueContinue, cb = function()
			self.havePerfect = false
			recastCb(true)
		end, closeCb = function()
			self.canClick = true
		end, btnType = 2, isRich = true})
		return
	end
	recastCb()
end

function CardNvalueView:onShowRule()
	gGameUI:stackUI("common.rule", nil, nil, self:createHandler("getRuleContext"))
end

function CardNvalueView:getRuleContext(view)
	local c = adaptContext
	local context = {
		c.clone(view.title, function(item)
			item:get("text"):text(gLanguageCsv.nvalueText)
		end),
		c.noteText(73001, 73003),
	}
	return context
end

return CardNvalueView
