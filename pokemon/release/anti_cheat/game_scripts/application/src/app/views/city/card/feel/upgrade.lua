
local ViewBase = cc.load("mvc").ViewBase
local CardFeelView = class("CardFeelView", Dialog)

CardFeelView.RESOURCE_FILENAME = "card_upgrade.json"
CardFeelView.RESOURCE_BINDING = {
	["closeBtn"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")}
		},
	},
	["item"] = "upGradeItem",
	["list"] = {
		varname = "upGradeList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("upGradeData"),
				item = bindHelper.self("upGradeItem"),
				onItem = function(list, node, k, v)
					local size = node:get("icon"):size()
					local binds = {
						class = "icon_key",
						props = {
							data = {
								key = v.id,
								-- num = v.num,
							},
							grayState = v.num <= 0 and 1 or 0,
							onNode = function(node)
								node:setTouchEnabled(false)
								if v.selectEffect then
									if v.state and v.num > 0 then
										if v.selectEffect:parent() then
											v.selectEffect:removeSelf()
										end
										node:add(v.selectEffect, 10)
									else
										if v.selectEffect:parent() then
											v.selectEffect:removeSelf()
										end
									end
								end
							end,
						},
					}
					bind.extend(list, node:get("icon"), binds)

					local canUse = v.canUse or 0
					node:get("txt"):setString(canUse.."/"..v.num)
					bind.touch(list, node:get("icon"), {methods = {ended = functools.partial(list.clickCell, k, v)}})
				end,
				asyncPreload = 6,
				onAfterBuild = function(list)
					list:setItemAlignCenter()
				end
			},
			handlers = {
				clickCell = bindHelper.self("onItemClick"),
			},
		},
	},
	["sliderNum"] = {
		binds = {
			event = "text",
			idler = bindHelper.self("sliderNum")
		}
	},
	["cancelBtn.title"] = {
		binds = {
			event = "effect",
			data = {color = ui.COLORS.NORMAL.WHITE, glow = {color = ui.COLORS.GLOW.WHITE}},
		},
	},
	["sureBtn.title"] = {
		binds = {
			event = "effect",
			data = {color = ui.COLORS.NORMAL.WHITE, glow = {color = ui.COLORS.GLOW.WHITE}},
		},
	},
	["slider"] = "slider",
	["subBtn"] = {
		varname = "subBtn",
		binds = {
			event = "touch",
			longtouch = true,
			method = bindHelper.defer(function(view, node, event)
				return view:onChangeNum(node, event, -1)
			end),
		},
	},
	["addBtn"] = {
		varname = "addBtn",
		binds = {
			event = "touch",
			longtouch = true,
			method = bindHelper.defer(function(view, node, event)
				return view:onChangeNum(node, event, 1)
			end),
		},
	},
	["sureBtn"] = {
		varname = "sureBtn",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onSureClick")}
		},
	},
	["cancelBtn"] = {
		varname = "cancelBtn",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")}
		},
	},
	["btnSelectItem"] = "btnSelectItem",
	["btnSelectItem.note"] = "note",
	["btnSelectItem.img"] = "img",
	["btnSelectItem"] = {
		varname = "btnSelectItem",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onBtnSelectItem")}
		}
	},
	["txt"] = "titleTxt",
	["titleTxt1"] = "titleTxt1",
}

--type中1代表的等级一键升级，2代表好感度一键提升
function CardFeelView:onCreate(param)
	if param.type == 1 then
		self.btnSelectItem:hide()
	end
	--是否选择专属道具
	self.selectSetState = param.selectState
	-- self.upGradeList:setItemAlignCenter()
	self.titleTxt:text(gLanguageCsv.feelOneKeyTitleText)
	self.titleTxt1:text(gLanguageCsv.quickText)
	self.cardMarkID = param.cardMarkID
	self.cardId = param.cardId
	local cardCsv = csv.cards[self.cardId]
	local feelCsv = gGoodFeelCsv[cardCsv.feelType]
	self:enableSchedule()
	self:initModel()
	self.selectItems = {}--选中的材料
	--items的specialArgsMap的exp
	self.upGradeData1 = {}--六个升级材料
	self.upGradeData = idlers.newWithMap(self.upGradeData1)
	idlereasy.when(self.items, function(_, items)
		for _,v in orderCsvPairs(cardCsv.feelItems) do
			table.insert(self.upGradeData1, {
				id = v,
				num = items[v] or 0,
				cfg = csv.items[v]
			})
		end
		self.upGradeData:update(self.upGradeData1)
	end)

	self.note:text(gLanguageCsv.cardFeelViewtext)
	if param.type == 2 then
		self.sureBtn:y(485)
		self.cancelBtn:y(485)
	end
    adapt.oneLineCenterPos(cc.p(160,40),{self.img, self.note}, cc.p(5, 0))
	-- 选中特效创建
	for k,v in ipairs(self.upGradeData1) do
		self.selectEffect = ccui.ImageView:create("common/icon/icon_selected_big.png")
		self.selectEffect:align(cc.p(1, 0), 180, 20)
		self.selectEffect:retain()
		self.upGradeData:atproxy(k).selectEffect = self.selectEffect
		self.upGradeData:atproxy(k).state = true
	end
	self.myAllExp = idler.new(0)
	--计算现在所有item可增加的exp
	local selectData = {}
	for k, v in ipairs(self.upGradeData1) do
		if selectSetState == true then
			if v.cfg.specialArgsMap.special == true then
				table.insert(selectData, false)
			else
				table.insert(selectData, true)
			end
		else
			table.insert(selectData, true)
		end
	end
	self.selectState = idlertable.new(selectData)
	idlereasy.when(self.selectState, function(_, selectState)
		local myAllExp = 0
		for i,v in ipairs(self.upGradeData1) do
			self.upGradeData:atproxy(i).state = selectState[i]
			if selectState[i] then
				if self.selectSetState:read() ~= true or v.cfg.specialArgsMap.special ~= true then
					myAllExp = myAllExp + v.cfg.specialArgsMap.feel_exp * v.num
				end
			end
		end
		self.myAllExp:set(myAllExp)
	end)

	idlereasy.any({self.selectSetState, self.upGradeData}, function(_, selectSetState, upGradeData)
		local icon = selectSetState and "common/icon/radio_selected.png" or "common/icon/radio_normal.png"
		self.btnSelectItem:get("img"):texture(icon)
	end)
	self.canMaxLv = idler.new(0)
	self.selectLevel = idler.new(0)
	self.sliderNum = idler.new("")
	idlereasy.any({self.cardFeels,self.myAllExp},function (obj, cardFeels, myAllExp)
		local cardFeel = cardFeels[cardCsv.cardMarkID] or {}
		local cardLv = cardFeel.level or 0
		local clientCurLvExp = cardFeel.level_exp or 0
		local needAllExp = 0
		local canMaxLv = 0
		local maxLv = table.length(feelCsv)
		for i = cardLv+1,maxLv do
			needAllExp = needAllExp + feelCsv[i].needExp
			if ((myAllExp + clientCurLvExp) < needAllExp) or (maxLv == i) then
				if maxLv == i then
					canMaxLv = i
					break
				else
					canMaxLv = i - 1
					break
				end
			end
		end
		self.canMaxLv:set(math.max(canMaxLv, cardLv))
		local selectLevel = math.min(self.selectLevel:read(),(canMaxLv - cardLv))
		self.selectLevel:set(selectLevel)
	end)

	idlereasy.any({self.selectLevel, self.cardFeels, self.canMaxLv, self.selectState},
		function(_, selectLevel, cardFeels, canMaxLv, selectState)
		local cardFeel = cardFeels[cardCsv.cardMarkID] or {}
		local cardLv = cardFeel.level or 0
		local clientCurLvExp = cardFeel.level_exp or 0
		self.canLvUp = canMaxLv - cardLv

		self.sliderNum:set(math.min((cardLv + selectLevel), canMaxLv).."/"..table.length(feelCsv))
		local allNeedExp = 0
		for i = cardLv + 1,cardLv+selectLevel do
			if i <= table.length(feelCsv) then
				allNeedExp = allNeedExp + feelCsv[i].needExp
			end
		end
		local myAllExp = clientCurLvExp
		local use = {}
		self.overflowExp = 0
		self.selectItems = {}
		for i,v in ipairs(self.upGradeData1) do
			if selectState[i] and v.num > 0 then
				local tmpExp = myAllExp + v.cfg.specialArgsMap.feel_exp * v.num
				if tmpExp >= allNeedExp then
					local useNum = math.ceil((allNeedExp - myAllExp) / v.cfg.specialArgsMap.feel_exp)
					if selectLevel ~= 0 then
						use[i] = useNum
						self.selectItems[v.id] = useNum
					end
					-- 若达到满级好感度经验
					if cardLv + selectLevel >= table.length(feelCsv) then
						myAllExp = myAllExp + v.cfg.specialArgsMap.feel_exp * useNum
						self.overflowExp = myAllExp - allNeedExp
					end
					break
				else
					if selectLevel ~= 0 then
						use[i] = v.num
						self.selectItems[v.id] = v.num
					end
				end
				myAllExp = tmpExp
			end
		end
		for i=1,#self.upGradeData1 do
			self.upGradeData:atproxy(i).canUse = use[i] or 0
		end
		-- 非拖动时才设置进度
		if not self.slider:isHighlighted() then
			local percent = math.ceil(selectLevel/(table.length(feelCsv) - cardLv)*100)
			self.slider:setPercent(percent)
		end
		cache.setShader(self.addBtn, false, ((selectLevel+cardLv) >= canMaxLv) and "hsl_gray" or  "normal")
		cache.setShader(self.subBtn, false, (selectLevel <= 0) and "hsl_gray" or  "normal")
		self.addBtn:setTouchEnabled((selectLevel+cardLv) < canMaxLv)
		self.subBtn:setTouchEnabled(selectLevel > 0)
	end)
	self.slider:setPercent(0)
	self.slider:addEventListener(function(sender,eventType)
		self:unScheduleAll()
		local percent = sender:getPercent()
		local maxLv = table.length(feelCsv)
		local cardFeel = self.cardFeels:read()[cardCsv.cardMarkID] or {}
		local cardLv = cardFeel.level or 0
		local canLvUp = self.canMaxLv:read()-cardLv
		-- self.canLvUp = canLvUp
		local selectLevel = math.ceil((maxLv - cardLv)/100 * percent)
		self.selectLevel:set(math.min(selectLevel, canLvUp))
		if selectLevel >= canLvUp then
			local percent = math.ceil(math.min(selectLevel, canLvUp)/(maxLv - cardLv)*100)
			self.slider:setPercent(percent)
		end
	end)
	if self.selectSetState:read() == true then
		for k, v in ipairs(self.upGradeData1) do
			if v.cfg.specialArgsMap.special == true then
				self.selectState:proxy()[k] = false
			end
		end
	else
		for k, v in ipairs(self.upGradeData1) do
			if v.cfg.specialArgsMap.special == true then
				self.selectState:proxy()[k] = true
			end
		end
	end
	Dialog.onCreate(self)
end

function CardFeelView:initModel()
	self.roleLv = gGameModel.role:getIdler("level")
	self.items = gGameModel.role:getIdler("items")
	self.cardFeels = gGameModel.role:getIdler("card_feels")
	self.gold = gGameModel.role:getIdler("gold")
end

function CardFeelView:onItemClick(list, k, v)
	if v.num <= 0 then
		gGameUI:showTip(gLanguageCsv.selectedMaterialsNotEnough)
		return
	end
	if self.selectSetState:read() == true then
		if self.upGradeData1[k].cfg.specialArgsMap.special == true then
			gGameUI:showTip(gLanguageCsv.feelOneKeyText)
			return
		end
	end
	self.selectState:proxy()[k] = not self.selectState:proxy()[k]
end

function CardFeelView:onAddClick()
	self.selectLevel:set(self.selectLevel:read()+1)
end

function CardFeelView:onReduceClick()
	self.selectLevel:set(self.selectLevel:read()-1)
end

function CardFeelView:onIncreaseNum(step)
	self.selectLevel:modify(function(num)
		return true, cc.clampf(num + step, 0, self.canLvUp)
	end)
end

function CardFeelView:onChangeNum(node, event, step)
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

function CardFeelView:onClose()
	Dialog.onClose(self)
end

function CardFeelView:onCleanup()
	if self.selectEffect then
		self.selectEffect:release()
		self.selectEffect = nil
	end
	Dialog.onCleanup(self)
end

function CardFeelView:onSureClick()
	if self.myAllExp:read() == 0 then
		gGameUI:showTip(gLanguageCsv.pleaseSelectMaterials)
		return
	end
	if next(self.selectItems) == nil or self.selectLevel:read() <= 0 then
		gGameUI:showTip(gLanguageCsv.pleaseSelectTargetLevel)
		return
	end
	local cardCfg = csv.cards[self.cardId]
	-- 需求上是希望小的礼物先吃掉，服务器乱序消耗，底层保护是客户端有消耗，但服务器计算不用消耗会有个错误提示

	local selectItems = table.deepcopy(self.selectItems, true)
	if self.overflowExp > 0 then
		local overflowExp = self.overflowExp
		for i = #self.upGradeData1, 1, -1 do
			local id = self.upGradeData1[i].id
			if selectItems[id] then
				local feelExp = self.upGradeData1[i].cfg.specialArgsMap.feel_exp
				if selectItems[id] * feelExp <= overflowExp then
					overflowExp = overflowExp - selectItems[id] * feelExp
					selectItems[id] = nil
				end
			end
		end
	end

	gGameApp:requestServer("/game/card/feel/use_items",function (tb)
		-- self.selectLevel:set(0)
		-- self:addCallbackOnExit(self.cb)
		ViewBase.onClose(self)
	end, self.cardMarkID, selectItems)
end

function CardFeelView:onBtnSelectItem()
	userDefault.setForeverLocalKey("CardFeelView", not self.selectSetState:read())
	self.selectSetState:set(not self.selectSetState:read())
	if self.selectSetState:read() == true then
		for k, v in ipairs(self.upGradeData1) do
			if v.cfg.specialArgsMap.special == true then
				self.selectState:proxy()[k] = false
			end
		end
	else
		for k, v in ipairs(self.upGradeData1) do
			if v.cfg.specialArgsMap.special == true then
				self.selectState:proxy()[k] = true
			end
		end
	end
end

return CardFeelView