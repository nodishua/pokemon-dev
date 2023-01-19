
local ViewBase = cc.load("mvc").ViewBase
local CardUpgradeView = class("CardUpgradeView", Dialog)

CardUpgradeView.RESOURCE_FILENAME = "card_upgrade.json"
CardUpgradeView.RESOURCE_BINDING = {
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
							end,
						},
					}
					bind.extend(list, node:get("icon"), binds)

					local canUse = v.canUse or 0
					node:get("txt"):setString(canUse.."/"..v.num)
					bind.touch(list, node:get("icon"), {methods = {ended = functools.partial(list.clickCell, k, v)}})
				end,
				asyncPreload = 6,
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
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onSureClick")}
		},
	},
	["cancelBtn"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")}
		},
	},
	["btnSelectItem"] = "btnSelectItem",
}

--type中1代表的等级一键升级，2代表好感度一键提升
function CardUpgradeView:onCreate(param, cb, type)
	if param.type == 1 then
		self.btnSelectItem:hide()
	end
	self.selectDbId = param.selectDbId
	self.cb = cb
	self:enableSchedule()
	self:initModel()
	self.selectItems = {}--选中的材料
	--items的specialArgsMap的exp
	self.upGradeData1 = {{},{},{},{},{},{}}--六个升级材料
	self.upGradeData = idlers.newWithMap(self.upGradeData1)
	idlereasy.when(self.items, function(_, items)
		for i, v in ipairs(gCardExpItemCsv) do
			local id = v.id
			self.upGradeData:at(i):modify(function(data)
				data.num = items[id] or 0
				data.id = id
				data.cfg = v
			end, true)
		end
	end)
	-- 选中特效创建
	for k,v in pairs(self.upGradeData1) do
		self.selectEffect = ccui.ImageView:create("common/icon/icon_selected_big.png")
		self.selectEffect:align(cc.p(1, 0), 180, 20)
		self.selectEffect:retain()
		self.upGradeData:atproxy(k).selectEffect = self.selectEffect
		self.upGradeData:atproxy(k).state = true
	end
	self.myAllExp = idler.new(0)
	--计算现在所有item可增加的exp
	self.selectState = idlertable.new({true,true,true,true,true,true})
	idlereasy.when(self.selectState,function(_, selectState)
		local myAllExp = 0
		for i,v in ipairs(self.upGradeData1) do
			self.upGradeData:atproxy(i).state = selectState[i]
			if selectState[i] then
				myAllExp = myAllExp + v.cfg.specialArgsMap.exp * v.num
			end
		end
		self.myAllExp:set(myAllExp)
	end)

	self.canMaxLv = idler.new(0)
	self.selectLevel = idler.new(0)
	self.sliderNum = idler.new("")
	idlereasy.any({self.roleLv,self.cardId,self.cardLv,self.currExp,self.myAllExp},function (obj,roleLv,cardId,cardLv,currExp,myAllExp)
		local needAllExp = 0
		local canMaxLv = 0
		local maxLv = csvSize(csv.base_attribute.card_level)
		for i = cardLv,maxLv do
			needAllExp = needAllExp + csv.base_attribute.card_level[i]["levelExp"..csv.cards[cardId].levelExpID]
			if ((myAllExp + currExp) < needAllExp) or (maxLv == i) then
				canMaxLv = i
				break
			end
		end
		canMaxLv = math.min(canMaxLv,roleLv)
		self.canMaxLv:set(canMaxLv)
		local selectLevel = math.min(self.selectLevel:read(),math.min(canMaxLv,roleLv) - cardLv)
		self.selectLevel:set(selectLevel)
	end)

	idlereasy.any({self.selectLevel, self.roleLv, self.currExp, self.cardLv, self.canMaxLv, self.selectState},
		function(_, selectLevel, roleLv, currExp, cardLv, canMaxLv, selectState)
		selectLevel = (cardLv+selectLevel <= roleLv) and selectLevel or canMaxLv - cardLv
		self.sliderNum:set(cardLv + selectLevel.."/"..roleLv)
		local allNeedExp = 0
		for i = cardLv,cardLv+selectLevel - 1 do
			allNeedExp = allNeedExp + csv.base_attribute.card_level[i]["levelExp"..csv.cards[self.cardId:read()].levelExpID]
		end
		local myAllExp = currExp
		local use = {}
		local complete = false
		self.selectItems = {}
		for i,v in ipairs(self.upGradeData1) do
			if selectState[i] then
				for j = 1,v.num do
					if myAllExp >= allNeedExp then
						complete = true
						break
					end
					if selectLevel ~= 0 then
						use[i] = j
						self.selectItems[v.id] = j
					end
					myAllExp = myAllExp + v.cfg.specialArgsMap.exp
				end
			end
			if complete then
				break
			end
		end
		for i=1,6 do
			self.upGradeData:atproxy(i).canUse = use[i] or 0
		end
		-- 非拖动时才设置进度
		if not self.slider:isHighlighted() then
			local percent = math.ceil(math.min(selectLevel, canMaxLv - cardLv)/(roleLv - cardLv)*100)
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
		local maxLv = self.roleLv:read()--人物等级
		local canLvUp = self.canMaxLv:read()-self.cardLv:read()
		local selectLevel = math.ceil((maxLv - self.cardLv:read())/100 * percent)
		self.selectLevel:set(math.min(selectLevel, canLvUp))
		if selectLevel >= canLvUp then
			local percent = math.ceil(math.min(selectLevel, canLvUp)/(maxLv - self.cardLv:read())*100)
			self.slider:setPercent(percent)
		end
	end)
	Dialog.onCreate(self)
end

function CardUpgradeView:initModel()
	self.roleLv = gGameModel.role:getIdler("level")
	self.items = gGameModel.role:getIdler("items")
	local card = gGameModel.cards:find(self.selectDbId)
	self.cardId = card:getIdler("card_id")
	self.cardLv = card:getIdler("level")
	self.currExp = card:getIdler("level_exp")
end

function CardUpgradeView:onItemClick(list, k, v)
	if v.num <= 0 then
		gGameUI:showTip(gLanguageCsv.selectedMaterialsNotEnough)
		return
	end
	self.selectState:proxy()[k] = not self.selectState:proxy()[k]
end

function CardUpgradeView:onAddClick()
	self.selectLevel:set(self.selectLevel:read()+1)
end

function CardUpgradeView:onReduceClick()
	self.selectLevel:set(self.selectLevel:read()-1)
end

function CardUpgradeView:onIncreaseNum(step)
	self.selectLevel:modify(function(num)
		return true, cc.clampf(num + step, 0, self.canMaxLv:read()-self.cardLv:read())
	end)
end

function CardUpgradeView:onChangeNum(node, event, step)
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

function CardUpgradeView:onClose()
	Dialog.onClose(self)
end

function CardUpgradeView:onCleanup()
	if self.selectEffect then
		self.selectEffect:release()
		self.selectEffect = nil
	end
	Dialog.onCleanup(self)
end

function CardUpgradeView:onSureClick()
	if self.myAllExp:read() == 0 then
		gGameUI:showTip(gLanguageCsv.pleaseSelectMaterials)
		return
	end
	if next(self.selectItems) == nil or self.selectLevel:read() <= 0 then
		gGameUI:showTip(gLanguageCsv.pleaseSelectTargetLevel)
		return
	end
	gGameApp:requestServer("/game/card/exp/use_items",function (tb)
		self.selectLevel:set(0)
		self:addCallbackOnExit(self.cb)
		ViewBase.onClose(self)
	end, self.selectDbId, self.selectItems)
end

return CardUpgradeView