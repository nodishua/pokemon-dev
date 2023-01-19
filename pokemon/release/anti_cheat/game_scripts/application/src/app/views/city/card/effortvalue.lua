local STATE_TYPE = {
	ONE_AND_TEN = 1,
	ONE = 2,
	SAVE_AND_CANCEL = 3,
	SAVE = 4,
}

local TRAIN_TYPE = {
	ONE = 1,
	TEN = 2,
}
local function setEffortAdvance(effortAdvance, parent)
	local childs = parent:multiget("icon1", "txtAdvance", "icon2", "txtTip")
	text.addEffect(childs.txtAdvance, {outline={color=cc.c4b(254, 94, 60, 255)}})
	childs.txtAdvance:text(dataEasy.getRomanNumeral(effortAdvance))
	adapt.oneLineCenterPos(cc.p(childs.txtTip:x(), childs.txtAdvance:y()), {childs.icon1, childs.txtAdvance, childs.icon2}, cc.p(15, 0))
end

local CardEffortValueView = class("CardEffortValueView", cc.load("mvc").ViewBase)
CardEffortValueView.RESOURCE_FILENAME = "card_effortvalue.json"
CardEffortValueView.RESOURCE_BINDING = {
	["item"] = "item",
	["panel.list"] = {
		varname = "list",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("tabDatas"),
				item = bindHelper.self("item"),
				margin = 30,
				onItem = function(list, node, k, v)
					local childs = node:multiget("name", "icon", "num", "changeNum", "bar", "imgMax", "barBg", "currentNum")
					local name, icon = dataEasy.getEffortValueAttrData(v.cfg.attrType)
					childs.name:text(name..":")
					childs.icon:texture(icon)

					local maxVal = v.maxVal
					local currVal = cc.clampf(v.currVal - v.totalVal, 0, maxVal)
					childs.currentNum:text(v.currVal)
					if currVal then
						childs.num:text(math.floor(currVal).."/"..maxVal)
						text.addEffect(childs.num, {outline={color=ui.COLORS.OUTLINE.DEFAULT}})
						local progress = math.min(currVal / maxVal * 100, 100)
						if not v.myIdler then
							v.myIdler = idler.new(progress)
							bind.extend(list, childs.bar, {
								event = "extend",
								class = "loadingbar",
								props = {
									data = v.myIdler,
									maskImg = "city/card/effort_value/bar_red.png"
								},
							})
						else
							v.myIdler:set(progress)
						end
					end
					-- 限制可变化的值
					local num = cc.clampf(v.changeNum or 0, -currVal, v.maxVal - currVal)
					if num == -0 then
						num = 0
					end
					childs.imgMax:visible((num + currVal >= v.maxVal) and (v.changeNum ~= nil))
					if v.changeNum then
						childs.changeNum:show()
						childs.changeNum:text((num >= 0 and "+" or "")..num)
						adapt.oneLinePos(childs.currentNum, childs.changeNum, cc.p(15,0))
						if num <= 0 then
							text.addEffect(childs.changeNum, {color = ui.COLORS.NORMAL.ALERT_ORANGE})
						elseif num > 0 then
							text.addEffect(childs.changeNum, {color = ui.COLORS.NORMAL.FRIEND_GREEN})
						end
						-- 努力值变化特效
						widget.addAnimationByKey(childs.bar, "effect/nuizhifankui.skel", 'nuizhifankui', "effect", 10)
							:anchorPoint(cc.p(0.5,0.5))
							:xy(childs.barBg:width()/2, childs.barBg:height()/2+1)
							:play("effect")
					else
						childs.changeNum:hide()
					end
				end,
			},
		},
	},
	["itemAttr"] = "itemAttr",
	["itemTxt"] = "itemTxt",
	["selectPanel.btnAttr"] = {
		varname = "btnAttr",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.defer(function (view)
				return view:onBtnAttr()
			end)}
		}
	},
	["selectPanel.list"] = {
		varname = "list",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("selectDatas"),
				item = bindHelper.self("itemAttr"),
				asyncPreload = 15,
				onItem = function(list, node, k, v)
					local childs = node:multiget("list", "selected", "bg")
					local t = {}
					for k,v in pairs(v) do
						if k ~= "selected" then
							table.insert(t, {key = k, num = v})
						end
					end
					childs.bg:texture(k % 2 == 1 and "common/box/box_t.png" or "common/box/box_t1.png")
					bind.extend(list, childs.list, {
						event = "extend",
						class = "listview",
						props = {
							data = t,
							item = bindHelper.parent("itemTxt"),
							dataOrderCmp = function(a, b)
								return game.ATTRDEF_SIMPLE_ENUM_TABLE[a.key] < game.ATTRDEF_SIMPLE_ENUM_TABLE[b.key]
							end,
							onItem = function(list, item, index, value)
								local childs = item:multiget("name", "num")
								local name, _ = dataEasy.getEffortValueAttrData(game.ATTRDEF_ENUM_TABLE[value.key])
								childs.name:text(name..":")
								childs.num:text(value.num)
								text.addEffect(childs.num, {color = value.num < 0 and ui.COLORS.NORMAL.ALERT_ORANGE or ui.COLORS.NORMAL.FRIEND_GREEN})
							end,
						}
					})
					childs.selected:texture(v.selected == true and "common/icon/radio_selected.png" or "common/icon/radio_normal.png")
					bind.touch(list, childs.selected, {methods = {ended = functools.partial(list.clickCell, k, v)}})
				end,
			},
			handlers = {
				clickCell = bindHelper.self("onItemClick"),
			},
		},
	},
	["panel.normalPanel"] = {
		varname = "normalPanel",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.defer(function (view)
				return view:onTrainSelectClick(1)
			end)}
		}
	},
	["panel.highPanel"] = {
		varname = "highPanel",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.defer(function (view)
				return view:onTrainSelectClick(2)
			end)}
		}
	},
	["panel.icon"] = "icon",
	["panel.num"] = "num",
	["panel.leftPanel"] = "leftPanel",
	["panel.leftPanel.btn"] = {
		varname = "leftBtn",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.defer(function (view)
				return view:onTrainClick(TRAIN_TYPE.ONE)
			end)}
		}
	},
	["panel.rightPanel.btn"] = {
		varname = "rightBtn",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.defer(function (view)
				return view:onTrainClick(TRAIN_TYPE.TEN)
			end)}
		}
	},
	["panel.btnCustom"] = {
		varname = "btnCustom",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onCustomClick")}
		},
	},
	["panel.rightPanel"] = "rightPanel",
	["panel.leftPanel.topPanel"] = "leftTopPanel",
	["panel.rightPanel.topPanel"] = "rightTopPanel",
	["selectPanel"] = "selectPanel",
	["mask"] = {
		varname = "mask",
		binds = {
			event = "click",
			method = bindHelper.self("onMaskClick")
		}
	},
	["panel.btnAdd"] = {
		varname = "btnAdd",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onAddClick")}
		}
	},
	["panel.advancePanel"] = "advancePanel",
	["panel.advanceMaxPanel"] = "advanceMaxPanel",
	["panel.advancePanel.btn"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onAdvanceClick")}
		}
	},
	["panel"] = "panel",
	["panel.textAdvanceNote"] = "textAdvanceNote",
	["panel.textAdvance"] = "textAdvance",
	["panel.btnDetail"] = {
		varname = "btnDetail",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onBtnDetailClick")}
		}
	},
}

function CardEffortValueView:onCreate(dbHandler, validAreas)
	self.selectDbId = dbHandler()
	self.validAreas = validAreas

	self:initModel()
	self:initCfg()

	self.curState = idler.new()
	self.tabDatas = idlers.new()
	self.trainIndex = idler.new(1)
	self.currCost = idlertable.new({})
	self.trainType = idler.new(TRAIN_TYPE.ONE)
	self.times = idler.new(0)

	self.listIndexs = idlertable.new({})
	self.selectDatas = idlers.newWithMap({})

	self.selectPanel:hide()
	self:adaptUI()

	local _, val = csvNext(csv.card_effort)
	self.normal  = val.cost1
	self.special = val.cost2

	self.datas = {
		{panel = self.normalPanel, cost = self.normal},
		{panel = self.highPanel, cost = self.special}
	}

	local refreshTimes = 0
	idlereasy.any({self.cardId, self.effortValue, self.effortAdvance, self.level}, function()
		-- refreshTimes = refreshTimes + 1
		-- performWithDelay(self, function()
		-- 	if refreshTimes > 0 then
		-- 		refreshTimes = 0
				local cardId = self.cardId:read()
				local effortValue = self.effortValue:read()
				local effortAdvance = self.effortAdvance:read()
				local level = self.level:read()

				local cfg = csv.cards[cardId]
				local advanceLimit = gCardEffortAdvance[cfg.effortSeqID][effortAdvance].advanceLimit

				local t = {}
				self.canAdvance = true
				self.attrShowIndex = {}

				for i,v in orderCsvPairs(self.cfg) do
					local attrType = game.ATTRDEF_TABLE[v.attrType]
					local maxVal, totalVal = dataEasy.getCardEffortMax(i, cardId, attrType, effortAdvance)
					local currVal = (effortValue[attrType] or 0)
					if (currVal - totalVal) < maxVal then
						self.canAdvance = false
					end
					table.insert(t, {
						id = i,
						cfg = v,
						maxVal = maxVal,    -- 当前阶段上限
						totalVal = totalVal,  -- 之前阶段的总和
						currVal = currVal,   -- 当前拥有的数值
					})
					self.attrShowIndex[attrType] = #t
				end

				setEffortAdvance(effortAdvance, self.advancePanel)
				setEffortAdvance(effortAdvance, self.advanceMaxPanel)
				self.textAdvance:text(dataEasy.getRomanNumeral(effortAdvance))

				if self.canAdvance then
					local sign = effortAdvance < advanceLimit
					self.advancePanel:visible(sign)
					self.advanceMaxPanel:visible(not sign)
					if sign then
						local needLevel = gCardEffortAdvance[cfg.effortSeqID][effortAdvance + 1].needLevel
						self.advancePanel:get("txtLvTip"):text(string.format(gLanguageCsv.needSpriteLevelArrival, needLevel)):visible(level < needLevel)
					end

				else
					self.advancePanel:visible(false)
					self.advanceMaxPanel:visible(false)
				end
				itertools.invoke({self.normalPanel, self.highPanel, self.leftPanel, self.rightPanel, self.btnCustom}, self.canAdvance and "hide" or "show")

				adapt.oneLinePos(self.textAdvanceNote, self.textAdvance, cc.p(8,0))
				adapt.oneLinePos(self.textAdvance, self.btnDetail, cc.p(15,0))
				self.curState:notify()
				self.tabDatas:update(t)
		-- 	end
		-- end, 0)
	end)


	self.trainIndex:addListener(function (val, oldval)
		self.datas[oldval].panel:get("selected"):texture("common/icon/radio_normal.png")
		self.datas[val].panel:get("selected"):texture("common/icon/radio_selected.png")
		local t = {}
		for i,v in csvMapPairs(self.datas[val].cost) do
			table.insert(t, {id = i, num = v})
		end
		self.currCost:set(t)
	end)

	self.originLeftX = self.leftPanel:x()
	dataEasy.getListenUnlock(gUnlockCsv.effort10, function(isUnlock)
		if not isUnlock then
			self.originState = STATE_TYPE.ONE
		else
			self.originState = STATE_TYPE.ONE_AND_TEN
		end
		self.curState:set(self.originState)
	end)

	idlereasy.when(self.listIndexs, function (_, val)
		local t = {}
		local isCanSend = false
		for k,v in pairs(val) do
			if v then
				isCanSend = true
				for index,val in self.tabDatas:ipairs() do
					local attrTypeStr = game.ATTRDEF_TABLE[val:proxy().cfg.attrType]
					if self.selectDatas:atproxy(k + 1)[attrTypeStr] then
						t[index] = t[index] or 0
						t[index] = t[index] + self.selectDatas:atproxy(k + 1)[attrTypeStr]
					end
				end
			end
		end
		cache.setShader(self.rightBtn, false, isCanSend and "normal" or "hsl_gray")
		for i = 1, self.tabDatas:size() do
			self.tabDatas:atproxy(i).changeNum = t[i]
		end
	end)

	idlereasy.any({self.items, self.currCost, self.curState}, function (_, items, cost, state)
		local _, val = next(cost)
		local id      = val.id
		local idNum   = val.num
		local currNum = dataEasy.getNumByKey(id)
		local itemIcon = dataEasy.getCfgByKey(id).icon
		local times   = math.floor(currNum / val.num)
		times = times >= 10 and 10 or times

		self:setHasCurrencyInfo(id, currNum, itemIcon)

		self.times:set(times)

		times = times == 0 and 10 or times

		self:setPanelShowOrHide(times)
		if not self.canAdvance then
			self:initButtonStatus()
		end

		local func = function(panel, num)
			local childs = panel:multiget("num", "icon", "cost", "costIcon", "txt")
			childs.costIcon:hide()
			childs.cost:hide()

			childs.icon:scale(0.9)
			childs.icon:texture(itemIcon)

			local showNum = idNum*num
			childs.num:text(showNum)
			text.addEffect(childs.num,{color = currNum >= showNum and ui.COLORS.NORMAL.DEFAULT or ui.COLORS.NORMAL.ALERT_ORANGE})

			adapt.oneLineCenterPos(cc.p(panel:width()/2, panel:height()/2), {childs.txt, childs.num, childs.icon}, cc.p(10, 0))
		end

		func(self.leftTopPanel, 1)
		func(self.rightTopPanel, times)

		cache.setShader(self.leftBtn, false, state ~= STATE_TYPE.SAVE and "normal" or "hsl_gray")
	end)

end

function CardEffortValueView:initModel()
	self.items = gGameModel.role:getIdler("items")
	self.gold = gGameModel.role:getIdler("gold")
	self.roleLv = gGameModel.role:getIdler("level")

	idlereasy.when(self.selectDbId, function (_, selectDbId)
		local card = gGameModel.cards:find(selectDbId)
		self.effortValue   = idlereasy.assign(card:getIdler("effort_values"), self.effortValue)
		self.effortAdvance = idlereasy.assign(card:getIdler("effort_advance"), self.effortAdvance)
		self.level         = idlereasy.assign(card:getIdler("level"), self.level)
		self.cardId        = idlereasy.assign(card:getIdler("card_id"), self.cardId)
	end)
end

function CardEffortValueView:initCfg()
	local cfg = {}
	for i,v in orderCsvPairs(csv.card_effort) do
		if v.attrType ~= game.ATTRDEF_ENUM_TABLE.specialDamage and v.advance == 1 then
			cfg[i] = v
		end
	end
	self.cfg = cfg
end

-- 界面状态可分为     晋升状态      非晋升状态
-- 非晋升可分为       普通培养状态  返回确认状态
function CardEffortValueView:setPanelShowOrHide(times)

	local state = self.curState:read()
	local trainType = self.trainType:read()



	-- 是否保存的状态，努力值培养的二次确认界面
	local curSign = state >= STATE_TYPE.SAVE_AND_CANCEL
	-- 是否是多次培养状态
	local tenSign = trainType == TRAIN_TYPE.TEN

	self.selectPanel:visible(curSign and tenSign)
	self.mask:visible(curSign)
	itertools.invoke({self.btnAdd, self.normalPanel, self.highPanel}, "setTouchEnabled", not curSign)

		if not curSign then
		self.listIndexs:set({})
	end

	self.leftPanel:get("btn", "txt"):text(not curSign and string.format(gLanguageCsv.trainTimes, 1) or gLanguageCsv.spaceCancel)
	self.rightPanel:get("btn", "txt"):text(not curSign and string.format(gLanguageCsv.trainTimes, times) or gLanguageCsv.spaceSave)

	if not self.canAdvance then
	-- 只能单次的情况，实际不存在这种情况，努力值和10一起开放的
		local oneSign = state == STATE_TYPE.ONE
		self.rightPanel:visible(not oneSign)
		self.leftPanel:x(oneSign and (self.originLeftX/2 + self.rightPanel:x()/2) or self.originLeftX)
		-- 只有保存的状态
		if state == STATE_TYPE.SAVE then
			cache.setShader(self.leftBtn, false, "hsl_gray")
		end

		-- 确认和保存都存在的状态
		-- print("22222222222222222222222222333",state == STATE_TYPE.SAVE_AND_CANCEL)
		cache.setShader(self.rightBtn, false, state == STATE_TYPE.SAVE_AND_CANCEL and "hsl_gray" or "normal")

		local saveState = state >= STATE_TYPE.SAVE_AND_CANCEL
		self.leftTopPanel:visible(not saveState)
		self.rightTopPanel:visible(not saveState)
	end


end

-- 下部按钮的状态
function CardEffortValueView:initButtonStatus()
	local isUnlock = dataEasy.isUnlock(gUnlockCsv.customEffort)
	local state = self.curState:read()

	if isUnlock and state == STATE_TYPE.ONE_AND_TEN then
		self.btnCustom:visible(true)
		self.btnCustom:size(292,122)
		self.btnCustom:get("txt"):xy(146,61)

		self.leftPanel:get("btn"):size(292,122)
		self.rightPanel:get("btn"):size(292,122)
		self.leftPanel:get("btn"):get("txt"):x(146)
		self.rightPanel:get("btn"):get("txt"):x(146)

		self.leftPanel:x(self.leftPanel:x() - 20)
		adapt.oneLinePos(self.leftPanel, {self.rightPanel,self.btnCustom}, {cc.p(-140,0),cc.p(-80,0)})
	else
		self.btnCustom:visible(false)

		self.leftPanel:get("btn"):size(320,122)
		self.rightPanel:get("btn"):size(320,122)
		self.leftPanel:get("btn"):get("txt"):x(166)
		self.rightPanel:get("btn"):get("txt"):x(166)

		adapt.oneLinePos(self.leftPanel, self.rightPanel,cc.p(90,0))
	end
end

-- 设置消耗货币栏
function CardEffortValueView:setHasCurrencyInfo(id, num, icon)
	local childs = self.panel:multiget("txtBg", "icon", "num", "btnAdd")

	childs.num:text(num)
	childs.icon:texture(icon)

	local bgX = num < 100000 and 290 or (90 + childs.num:size().width)*1.33
	childs.icon:x(childs.txtBg:x() - bgX*0.8 - 20)
	childs.txtBg:size(bgX, 70)

	adapt.oneLinePos(childs.btnAdd, childs.num, cc.p(10,0), "right")
end

-- 英文适配
function CardEffortValueView:adaptUI()
	if matchLanguage({"en"}) then
		local cardId = self.cardId:read()
		local cfg = csv.cards[cardId]

		local childs = self.advancePanel:multiget("icon1", "txtAdvance", "icon2", "txtTip","txtLvTip")
		adapt.setTextAdaptWithSize(self.advanceMaxPanel:get("txtTip"), {size = cc.size(self.advanceMaxPanel:width() - 150, 200), vertical = "center", horizontal = "center"})
		adapt.setTextAdaptWithSize(childs.txtTip, {size = cc.size(self.advancePanel:width() - 150, 200), vertical = "center", horizontal = "center"})
		adapt.setTextAdaptWithSize(childs.txtLvTip, {size = cc.size(self.advancePanel:width() - 150, 200), vertical = "center", horizontal = "center"})
		if self.level:read() < gCardEffortAdvance[cfg.effortSeqID][self.effortAdvance:read() + 1].needLevel then
			local y = 270
			childs.txtAdvance:y(y)
			childs.icon1:y(y)
			childs.icon2:y(y)
			childs.txtTip:y(self.advancePanel:get("txtAdvance"):y() - 65)
			childs.txtLvTip:y(self.advancePanel:get("txtTip"):y() - 69)
		end
	end
end

function CardEffortValueView:onTrainClick(trainType)
	if self.curState:read() <= STATE_TYPE.ONE then
		local times = trainType == TRAIN_TYPE.ONE and 1 or self.times:read()

		if self.times:read() == 0 then
			gGameUI:showTip(gLanguageCsv.effortMaterialNotEnough)
			return
		end
		gGameApp:requestServer("/game/card/effort/train",function (tb)
			self:request(tb)
		end, self.selectDbId, self.trainIndex, times)
	else
		if trainType == TRAIN_TYPE.ONE then
			--取消
			if self.curState:read() ~= STATE_TYPE.SAVE then
				self.curState:set(self.originState)
			else
				gGameUI:showTip(gLanguageCsv.effortNotCancel)
			end
		else
			--保存
			self:saveTrain()
		end
	end

end
function CardEffortValueView:onCustomClick()
	if self.times:read() == 0 then
		gGameUI:showTip(gLanguageCsv.effortMaterialNotEnough)
		return
	end
	local have
	local times
	for i,v in ipairs(self.currCost:read()) do
		if v.id ~= "gold" then
			local idx = self.trainIndex:read()
			have = dataEasy.getNumByKey(v.id)
			times =  math.min(math.floor(have / v.num),100)
			local dbid = self.selectDbId:read()
			gGameUI:stackUI("city.card.effortvalue_custom", nil, nil,self.trainIndex:read(),v.id,times, dbid,self:createHandler("request"))
		end
	end

end
function CardEffortValueView:onTrainSelectClick(index)
	self.trainIndex:set(index)
end

function CardEffortValueView:request(tb)
	self.selectDatas:update(tb.view.result)
	if #tb.view.result == 1 then
		local isOnlySave = true
		local sum = 0
		for k,v in pairs(tb.view.result[1]) do
			local changeVal = v
			if self.attrShowIndex[k] then
				local data = self.tabDatas:atproxy(self.attrShowIndex[k])
				changeVal = cc.clampf(changeVal, data.totalVal - data.currVal, data.maxVal + data.totalVal - data.currVal)
			end
			sum = sum + changeVal
			if changeVal < 0 then
				isOnlySave = false
			end
		end
		-- 0, 1, 1 isOnlySave = true
		-- 0, 0, 0 isOnlySave = false
		if sum <= 0 then
			isOnlySave = false
		end
		self.trainType:set(TRAIN_TYPE.ONE)
		self.curState:set(isOnlySave and STATE_TYPE.SAVE or STATE_TYPE.SAVE_AND_CANCEL)
		self.listIndexs:set({[0] = true}, true)
		if self.selectPanel:isVisible() then
			-- 客户端本地存储属性推荐状态
			local attrState = userDefault.getForeverLocalKey("attrRecommondedState")
			self:onBtnAttr(attrState)
		end
	else
		self.trainType:set(TRAIN_TYPE.TEN)
		self.sign = true
		self.curState:set(STATE_TYPE.SAVE_AND_CANCEL)

		-- 客户端本地存储属性推荐状态
		local attrState = userDefault.getForeverLocalKey("attrRecommondedState")
		self:onBtnAttr(attrState)
	end
end

function CardEffortValueView:saveTrain()
	idlereasy.do_(function (indexs)
		local t = {}
		for k,v in pairs(indexs) do
			if v then
				table.insert(t, k)
			end
		end
		if #t == 0 then
			gGameUI:showTip(gLanguageCsv.firstChooseNeedAttr)
		else
			gGameApp:requestServer("/game/card/effort/save",function (tb)
				self.curState:set(self.originState)
			end, self.selectDbId, t)
		end
	end, self.listIndexs)
end

function CardEffortValueView:onMaskClick(node, event)
	local trainType = self.trainType:read()
	if trainType == TRAIN_TYPE.ONE then
		gGameUI:showTip(gLanguageCsv.effortValueOneMask)
	else
		if self.validAreas then
			local inArea = false
			for _, area in ipairs(self.validAreas) do
				if cc.rectContainsPoint(area, cc.p(event.x, event.y)) then
					inArea = true
					break
				end
			end
			if not inArea then
				return
			end
		end
		gGameUI:showDialog{strs = gLanguageCsv.effortCancel, cb = function ()
			self.curState:set(self.originState)
		end, btnType = 2}
	end
end

function CardEffortValueView:onItemClick(list, k, v)
	self.selectDatas:atproxy(k).selected = not self.selectDatas:atproxy(k).selected
	self.listIndexs:modify(function(indexs)
		indexs[k-1] = self.selectDatas:atproxy(k).selected
		return true, indexs
	end, true)
end

-- @desc 属性推荐保存切换
function CardEffortValueView:onBtnAttr(state)
	self.btnAttrSelected = not self.btnAttrSelected
	if state ~= nil then
		self.btnAttrSelected = state
	end

	userDefault.setForeverLocalKey("attrRecommondedState", self.btnAttrSelected)
	self.btnAttr:texture(self.btnAttrSelected == true and "common/icon/radio_selected.png" or "common/icon/radio_normal.png")

	for i=1,itertools.size(self.selectDatas) do
		if self.selectDatas:atproxy(i) then
			local attrs = self.selectDatas:atproxy(i)
			local total = 0		-- total 为当前属性栏权重总和，大于0为推荐保存属性栏
			for k,v in pairs(attrs) do
				if k ~= "selected" then
					local weight = gCommonConfigCsv["attr" .. string.caption(k)]
					total = total + v*weight
				end
			end
			if total > 0 then
				self.selectDatas:atproxy(i).selected = self.btnAttrSelected
				self.listIndexs:modify(function(indexs)
					indexs[i-1] = self.selectDatas:atproxy(i).selected
					return true, indexs
				end, true)
			end
		end
	end
end

-- 获取材料
function CardEffortValueView:onAddClick()
	local _, val = next(self.currCost:read())
	jumpEasy.jumpTo("gainWay", val.id)
end

-- 提升 注:前后self.effortAdvance的值是不同的，不能统一
function CardEffortValueView:onAdvanceClick()
	local cfg = csv.cards[self.cardId:read()]
	local selectDbId = self.selectDbId:read()

	local needLevel = gCardEffortAdvance[cfg.effortSeqID][self.effortAdvance:read() + 1].needLevel
	if self.level:read() < needLevel then
		gGameUI:showTip(string.format(gLanguageCsv.needSpriteLevelArrival, needLevel))
		return
	end

	local card = gGameModel.cards:find(selectDbId)
	local fight = card:read("fighting_point")
	local showOver = {false}
	gGameApp:requestServerCustom("/game/card/effort/advance")
		:params(self.selectDbId)
		:onResponse(function (tb)
			showOver[1] = true
		end)
		:wait(showOver)
		:doit(function (tb)
			gGameUI:stackUI("city.card.common_success", nil, {blackLayer = true},
				selectDbId,
				fight,
				{effortAdvance = self.effortAdvance:read()}
			)
		end)
end

-- 详情
function CardEffortValueView:onBtnDetailClick()
	gGameUI:stackUI("city.card.effortvalue_detail", nil, nil, self.effortAdvance:read(), self.cardId:read())
end

return CardEffortValueView
