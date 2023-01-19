
local function setEffect(parent)
	local effect = parent:get("effect")
	local size = parent:size()
	if not effect then
		effect = widget.addAnimationByKey(parent, "effect/shengjitiao.skel", "effect", "effect", 10)
			:xy(size.width/2 + 0, size.height/2 + 0)
			:scale(1)
	else
		effect:play("effect")
	end
end

local CardAttributeView = class("CardAttributeView", cc.load("mvc").ViewBase)

CardAttributeView.RESOURCE_FILENAME = "card_attribute.json"
CardAttributeView.RESOURCE_BINDING = {
	["center.top.textTypeNum"] = {
		binds = {
			event = "text",
			idler = bindHelper.self("raceTxt")
		},
	},
	["center.top.btnInfo"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onCharacterClick")}
		},
	},
	["center.top.btnAttrInfo"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onShowAtrtInfo")}
		},
	},
	["center.top.btnChooseAttr"] = {
		varname = "btnChooseAttr",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onExchangeChooseNature")}
		},
	},
	["attrItem"] = "attrItem",
	["center.top.btnShare"] = {
		binds = {
			{
				event = "visible",
				idler = bindHelper.self("cardShareListen"),
			},
			{
				event = "touch",
				methods = {ended = bindHelper.self("onShareCard")},
			},
		},
	},
	["center.top.btnComment"] = {
		varname = "btnComment",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onBtnComment")},
		},
	},
	["center.top.btnComment.textNote"] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.WHITE}},
		}
	},
	["center.top.attrList"] = {
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("attrDatas"),
				item = bindHelper.self("attrItem"),
				onItem = function(list, node, k, v)
					node:get("imgIcon"):texture(ui.ATTR_ICON[v[1]])
					-- node:get("bg"):visible(v[2])
					node:get("bg"):hide()
				end,
			},
		},
	},
	["center.top.textSexVal"] = {
		binds = {
			event = "text",
			idler = bindHelper.self("gender"),
			method = function(gender)
				return getLanguageGender(gender)
			end,
		}
	},
	["center.top.textNature"] = {
		binds = {
			event = "text",
			idler = bindHelper.self("currSelect"),
			method = function(currSelect)
				return csv.character[currSelect].name
			end
		}
	},
	["center.levelupPanel"] = "levelupPanel",
	["center.levelupPanel.textLv"] = {
		binds = {
			event = "text",
			idler = bindHelper.self("clientLv"),
			method = function(val)
				return "Lv." .. val
			end,
		},
	},
	["center.center.btnInfo"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onAttrDetail")}
		},
	},
	["center.down"] = {
		binds = {
			event = "visible",
			idler = bindHelper.self("trammelsPanel")
		}
	},
	["center.medLvUp"] = {
		binds = {
			event = "visible",
			idler = bindHelper.self("gradePanel")
		}
	},
	["center.levelupPanel.textExp"] = "textExp",
	["center.levelupPanel.textNum"] = "textNum",
	["center.levelupPanel.progressBar"] = {
		varname = "progressBar",
		-- binds = {
		-- 	event = "extend",
 	-- 		class = "loadingbar",
		-- 	props = {
		-- 		data = bindHelper.self("expPercent"),
		-- 		maskImg = "common/icon/mask_bar_red.png"
		-- 	},
		-- },
	},
	["center.levelupPanel.btnOneKeyLvUp"] = {
		varname = "btnOneKeyLvUp",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onUpGradePanelClick")}
		},
	},
	["center.levelupPanel.btnLvUp"] = {
		varname = "btnLvUp",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onShowGradeClick")}
		},
	},
	["center.center.textLifeNum"] = {
		binds = {
			event = "text",
			idler = bindHelper.self("hpVal")
		},
	},
	["center.center.textSpeedVal"] = {
		binds = {
			event = "text",
			idler = bindHelper.self("speedVal")
		},
	},
	["center.center.textAttackNum"] = {
		binds = {
			event = "text",
			idler = bindHelper.self("damageVal")
		},
	},
	["center.center.textDefNum"] = {
		binds = {
			event = "text",
			idler = bindHelper.self("defenceVal")
		},
	},
	["center.center.textSpeAttackNum"] = {
		binds = {
			event = "text",
			idler = bindHelper.self("specialDamageVal")
		},
	},
	["center.center.textSpeDefNum"] = {
		binds = {
			event = "text",
			idler = bindHelper.self("specialDefenceVal")
		},
	},
	["medItem"] = "medItem",
	["center.medLvUp.textNote"] = "medLvUpTextNote",
	["center.medLvUp.list"] = {
		varname = "gradelist",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("itemData"),
				item = bindHelper.self("medItem"),
				onItem = function(list, node, k, v)
					node:name("item" .. k)
					bind.extend(list, node, {
						class = "icon_key",
						props = {
							data = v,
							grayState = v.num <= 0 and 1 or 0,
							onNode = function(panel)
								panel:scale(0.70)
								panel:setTouchEnabled(false)
							end,
						},
					})
					-- 特殊写法，不可参考，客户端模拟数量减少时不重新创建item，不然touch会失效
					node.num = v.num
					node.resetState = function()
						local panel = node:get("_icon_")
						panel:get("num"):text(node.num)
						local addBtn = node:get("btnAdd")
						local mask = node:get("imgMask")
						mask:hide(false)
						addBtn:visible(node.num <= 0)
						local grayState = node.num <= 0 and cc.c3b(128, 128, 128) or cc.c3b(255, 255, 255)
						panel:get("box"):color(grayState)
						panel:get("icon"):color(grayState)
					end
					node.resetState()
					node:get("textAddVal"):text(v.cfg.specialArgsMap.exp)
					node:onTouch(functools.partial(list.itemClick, node, k, v))
				end,
				asyncPreload = 6,
			},
			handlers = {
				itemClick = bindHelper.self("onItemClick"),
			},
		},
	},
	["trammelItem"] = "fetterItem",
	["innerList"] = "fetterSubList",
	["center.down.list"] = {
		varname = "fetterList",
		binds = {
			event = "extend",
			class = "tableview",
			props = {
				data = bindHelper.self("fetterData"),
				columnSize = 3,
				item = bindHelper.self("fetterSubList"),
				cell = bindHelper.self("fetterItem"),
				onCell = function(list, node, k, v)
					local fetter = csv.fetter[v.id]
					node:get("textNote"):text(fetter.name)
					if v.isShow then
						text.addEffect(node:get("textNote"), {color=ui.COLORS.NORMAL.DEFAULT})
					else
						text.addEffect(node:get("textNote"), {color=ui.COLORS.NORMAL.GRAY})
					end
				end,
				asyncPreload = 6,
			},
		}
	},
	["center.down.btnInfo"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("showFetterClick")}
		},
	},
}

function CardAttributeView:onCreate(dbHandler, playAction)
	self.selectDbId = dbHandler()
	self.costData = {}
	self:initModel()
	self:enableSchedule()
	adapt.setTextAdaptWithSize(self.medLvUpTextNote, {size = cc.size(835,80), vertical = "center", horizontal = "center", margin = -8})
    self.medLvUpTextNote:y(self.medLvUpTextNote:y() + 5)

	self.cardShareListen = dataEasy.getListenUnlock(gUnlockCsv.cardShare)

	dataEasy.getListenUnlock(gUnlockCsv.cardComment, function(isUnlock)
		self.btnComment:visible(isUnlock)
	end)

	-- 长按时客户端模拟升级
	self.clientCurLvExp = idler.new(self.levelExp:read())
	self.clientLv = idler.new(self.cardLevel:read())
	self.clickLevelUpdata = idler.new(false)
	idlereasy.when(self.cardLevel, function(_, level)
		self.clientLv:set(level)
	end, true)
	idlereasy.when(self.levelExp, function(_, levelExp)
		self.clientCurLvExp:set(levelExp)
	end, true)

	self.showSuccessTip = false
	local maxRoleLv = table.length(gRoleLevelCsv)
	idlereasy.any({self.clientLv, self.clientCurLvExp}, function(_, level, clientCurLvExp)
		if self.showSuccessTip then
			playAction(false, true)
			self.showSuccessTip = false
	 		self.progressBar:setPercent(0)
			setEffect(self.progressBar)
		end
		local cardCsv = csv.cards[self.cardId:read()]
		local cardLevelCsv = csv.base_attribute.card_level
		self.clientNextLvExp = cardLevelCsv[level]["levelExp"..cardCsv.levelExpID]
		self.clientMaxLvNeedExp = self.clientNextLvExp - clientCurLvExp
		for i = level + 1, self.roleLv:read() do
			self.clientMaxLvNeedExp = self.clientMaxLvNeedExp + cardLevelCsv[i]["levelExp"..cardCsv.levelExpID]
		end
		self.textExp:text(clientCurLvExp .. "/" .. self.clientNextLvExp)
		local percent = cc.clampf(clientCurLvExp / self.clientNextLvExp * 100, 0, 100)
		if self.roleLv:read() == maxRoleLv and level == maxRoleLv then
			percent = 100
			local maxExp = cardLevelCsv[maxRoleLv-1]["levelExp"..cardCsv.levelExpID]
			self.textExp:text(maxExp .. "/" .. maxExp)
		end
		if self.progressBar:getPercent() > percent or self.selectDbIdChange then
	 		self.progressBar:setPercent(percent)
	 	else
			transition.executeSequence(self.progressBar)
		 		:progressTo(self.lvTouchTimes-0.01, percent)
		 		:done()
	 	end
	 	self.clickLevelUpdata:set(true, true)
	end)

	self.raceTxt = idler.new()
	self.hpVal = idler.new(0)
	self.speedVal = idler.new(0)
	self.damageVal = idler.new(0)
	self.defenceVal = idler.new(0)
	self.specialDamageVal = idler.new(0)
	self.specialDefenceVal = idler.new(0)
	idlereasy.when(self.attrs, function(_, attrs)
		for k,v in ipairs(game.ATTRDEF_SIMPLE_TABLE) do
			self[v .. "Val"]:set(math.floor(attrs[v]))
		end
	end)

	local t = {}
	for i, v in ipairs(gCardExpItemCsv) do
		local id = v.id
		table.insert(t, {num = idler.new(0), key = id, y = y, cfg = v})
	end
	self.itemData = idlers.newWithMap(t)
	self.showOneKeyUpgrade = false
	idlereasy.any({self.items, self.clickLevelUpdata}, function(_, items)
		local myAllExp = 0
		local levelExp = self.levelExp:read()
		for i, v in ipairs(gCardExpItemCsv) do
			local id = v.id
			self.itemData:atproxy(i).num = math.max(0, (items[id] or 0) - (self.costData[v.id] or 0)) --减去客户端消耗部分
			myAllExp = myAllExp + v.specialArgsMap.exp * (items[v.id] or 0)
		end
		self.showOneKeyUpgrade = (myAllExp + levelExp) >= self.clientNextLvExp
	end)

	self.fetterData = idlertable.new({})
	self.attrDatas = idlers.newWithMap({})
	idlereasy.any({self.cardDatas, self.fetters, self.cardId, self.natureChosse},function (obj, cardDatas, fetters, cardId, natureChosse)
		local cardCsv = csv.cards[cardId]
		self.raceTxt:set(cardCsv.specValue[csvSize(cardCsv.specValue)])
		local data,data1,cardIds = {},{},{}
		for i,v in ipairs(cardDatas) do
			local card = gGameModel.cards:find(v)
			-- 分解之后 选中的dbid改变 服务器的cards还没有同步过来就会导致这边find是nil
			if card then
				local cardId = card:read("card_id")
				local cardMarkID = csv.cards[cardId].cardMarkID
				if not cardIds[cardMarkID] then
					cardIds[cardMarkID] = cardId
				else
					if cardId > cardIds[cardMarkID] then
						cardIds[cardMarkID] = cardId
					end
				end
			end
		end
		local hash = itertools.map(itertools.ivalues(fetters), function(k, v) return v, k end)
		local fetterNum = csvSize(cardCsv.fetterList)
		for i=1,fetterNum do
			local fetterId = cardCsv.fetterList[i]
			local isShow = hash[fetterId] ~= nil
			data[i] = {id = fetterId,cardDatas = cardIds, isShow = isShow}
		end
		self.fetterData:set(data)
		local attrs = {}
		local unit = csv.unit[cardCsv.unitID]
		table.insert(attrs, {unit.natureType, true})
		self.btnChooseAttr:hide()
		if unit.natureType2 and natureChosse and natureChosse ~= 0 then
			table.insert(attrs,{unit.natureType2, true})
			attrs[3 - natureChosse][2] = false
			-- 20/10/26 双属性自动选最优，去掉这边切换显示
			-- self.btnChooseAttr:show()
		end
		self.attrDatas:update(attrs)
	end)

	self.trammelsPanel = idler.new(false)
	self.gradePanel = idler.new(false)
	self.showGradePanel = idler.new(true)
	idlereasy.when(self.showGradePanel, function (obj, val)
		self.trammelsPanel:set(val)
		self.gradePanel:set(not val)
		local path = "city/card/system/attribute/btn_upgrade.png"
		if not val then
			path = "common/btn/btn_cancel.png"
		end
		self.btnLvUp:loadTextureNormal(path)
	end)

	-- self.targetPos = idler.new()
	-- idlereasy.any({self.clientCurLvExp, self.clientNextLvExp},function (obj, levelExp, nextLevelExp)
	-- 	local targetPos = -100+340*(math.min(levelExp/nextLevelExp, 1))
	-- 	self.targetPos:set(targetPos)
	-- end)

	-- idlereasy.when(self.targetPos,function (obj,targetPos)
		-- self:enableSchedule():schedule(function ()
		-- 	local nowPos = spriteLevel2:y()
		-- 	if nowPos < targetPos then
		-- 		nowPos = nowPos + 10
		-- 		spriteLevel2:y(math.min(nowPos, targetPos))--240满级
		-- 	else
		-- 		nowPos = 0
		-- 		spriteLevel2:y(targetPos)
		-- 		self:unSchedule("CardAttributeView")
		-- 	end
		-- end, 0.01, 0.01, "CardAttributeView")
	-- end)
	-- idlereasy.when(self.gender,function (obj,gender)
		-- if (not gender) or (gender == 0) then
		-- 	self.sexIcon:hide()
		-- 	return
		-- end
		-- local imgPath = (gender == 1) and "common/icon/icon_man.png" or "common/icon/icon_woman.png"
		-- self.sexIcon:texture(imgPath):show()
	-- end)

	dataEasy.getListenUnlock(gUnlockCsv.onekeyLevelup, function(isUnlock)
		if not isUnlock then
			self.btnOneKeyLvUp:hide()
			local x = self.btnOneKeyLvUp:x() + self.btnOneKeyLvUp:size().width/2 - self.btnLvUp:size().width/2
			self.btnLvUp:x(x)
		end
	end)
	self.textNum:hide()
end

function CardAttributeView:initModel()
	idlereasy.when(self.selectDbId, function(_, cardID)
		self.selectDbIdChange = true
		local card = gGameModel.cards:find(cardID)
		self.gender = idlereasy.assign(card:getIdler("gender"), self.gender)
		self.cardId = idlereasy.assign(card:getIdler("card_id"), self.cardId)
		self.cardLevel = idlereasy.assign(card:getIdler("level"), self.cardLevel)
		self.attrs = idlereasy.assign(card:getIdler("attrs"), self.attrs)
		self.fetters = idlereasy.assign(card:getIdler("fetters"), self.fetters)
		self.currSelect = idlereasy.assign(card:getIdler("character"), self.currSelect)
		self.levelExp = idlereasy.assign(card:getIdler("level_exp"), self.levelExp)
		self.natureChosse = idlereasy.assign(card:getIdler("nature_choose"), self.natureChosse)
	end)
	self.cardDatas = gGameModel.role:getIdler("cards")
	self.items = gGameModel.role:getIdler("items")
	self.rmb = gGameModel.role:getIdler("rmb")
	self.roleLv = gGameModel.role:getIdler("level")
	self.shareTimes = gGameModel.daily_record:getIdler("card_share_times")
end

function CardAttributeView:onExchangeChooseNature()
	local cardId =self.cardId:read()
	local dbId = self.selectDbId:read()
	local cardCsv = csv.cards[cardId]
	local unit = csv.unit[cardCsv.unitID]
	local natureTypeTb = {unit.natureType, unit.natureType2}
	local chooseId = self.natureChosse:read()
	local cb = function()
		gGameApp:requestServer("/game/card/nature/choose",function (tb)
			gGameUI:showTip(gLanguageCsv.chooseNatureTypeSuccess)
		end, dbId, 3 - chooseId)
	end

	local str = string.format(gLanguageCsv.chooseNatureText, ui.ATTR_ICON[natureTypeTb[chooseId]], ui.ATTR_ICON[natureTypeTb[3 - chooseId]])
	gGameUI:showDialog({content = str, cb = cb, btnType = 2, isRich = true})
end

function CardAttributeView:onCharacterClick()
	gGameUI:stackUI("city.card.character", nil, nil, self.cardId:read(), self.currSelect:read())
end

function CardAttributeView:onAttrDetail()
	gGameUI:stackUI("city.card.attrdetail", nil, nil, self.selectDbId:read())
end

function CardAttributeView:onShowGradeClick()
	self.showGradePanel:modify(function(val)
		return true, not val
	end)
end

function CardAttributeView:onUpGradePanelClick()
	--满级飘字
	if self.cardLevel:read() >= self.roleLv:read() then
		gGameUI:showTip(gLanguageCsv.cardLevelReachedLimit)
		return
	end
	if not self.showOneKeyUpgrade then
		gGameUI:showTip(gLanguageCsv.levelUpNoEnough)
		return
	end
	gGameUI:stackUI("city.card.upgrade", nil, nil, {selectDbId = self.selectDbId:read(), type = 1}, self:createHandler("isSuccess"))    -- 传type = 1代表的是等级一键提升
end

function CardAttributeView:isSuccess()
	self.showSuccessTip = true
	self.clientLv:notify()
end
function CardAttributeView:showFetterClick()
	gGameUI:stackUI("city.card.fetter", nil, nil, self.fetterData:read(), self.cardId:read())
end

function CardAttributeView:checkCanLvUp(idx, data)
	-- 本地计算升级经验和等级 不然有可能会导致定时器在走 服务器数据还没同步过来的情况
	local lvExp = self.clientCurLvExp:read()
	local showSuccessTip = true --true
	while lvExp >= self.clientNextLvExp do
		if self:canLevelUp() then
			self.showSuccessTip = showSuccessTip
			showSuccessTip = false
			lvExp = lvExp - self.clientNextLvExp
			self.clientCurLvExp:set(lvExp)
			self.clientLv:modify(function(val)
				return true, val + 1
			end)
		else
			self.clientCurLvExp:modify(function(val)
				return true, self.clientNextLvExp
			end)
			break
		end
	end
end

function CardAttributeView:onItemClick(list, node, k, v, event)
	local function checkUseItem(count, ignoreBox)
		count = count or 1
		if node.num <= 0 then
			if not ignoreBox then
				--等级不足飘字
				if self.roleLv:read() < v.cfg.specialArgsMap.buy_level then
					gGameUI:showTip(string.format(gLanguageCsv.buyInfoTip, v.cfg.specialArgsMap.buy_level))
					return
				end
				-- discount-折扣 price-现价 = 原价*折扣 maxBuyNum-可购买最大数量
				local discount = 1- dataEasy.getPrivilegeVal(game.PRIVILEGE_TYPE.ExpItemCostFallRate)
				local original = v.cfg.specialArgsMap.buy_rmb
				local price = mathEasy.getPreciseDecimal(v.cfg.specialArgsMap.buy_rmb* discount, 0, true)
				local maxBuyNum = 100
				self.key = v.key
				gGameUI:stackUI("common.buy_info", nil, nil,
					{rmb = original},
					{id = v.key},
					{maxNum = maxBuyNum, discount = discount, contentType = "num"},
					self:createHandler("showBuyInfo")
				)
			end

		elseif self:canLevelUp() then
			node.num = node.num - count
			node.resetState()
			self.costData[v.key] = self.costData[v.key] and (self.costData[v.key] + count) or count
			-- 每吃一颗药就增加本地经验
			self.clientCurLvExp:modify(function(oldVal)
				return true, oldVal + v.cfg.specialArgsMap.exp * count
			end)
			self.textNum:show():text("x"..self.costData[v.key])
			-- self:upgradeFloatingWord(v.cfg.specialArgsMap.exp * count)
			self:checkCanLvUp(k, v)
			if not node.lvUpEffect then
				node.lvUpEffect = widget.addAnimation(node, "koudai_gonghuixunlian/gonghuixunlian.skel", "fangguang", 10)
					:xy(65, 0)
					:scale(0.8)
			else
				node.lvUpEffect:play("fangguang")
			end
			audio.playEffectWithWeekBGM("square.mp3")
			return true

		else
			gGameUI:showTip(gLanguageCsv.cardLevelReachedLimit)
		end
	end
	if event.name == "began" then
		self.selectDbIdChange = false
		self.lvTouchTimes = 0.5
		self.count = 1
		local interval = 0.5
		local function onUse()
			self.lvTouchTimes = math.max(self.lvTouchTimes - 0.03, 0.05)
			interval = interval + 0.1
			if interval >= self.lvTouchTimes then
				interval = 0
				-- self.count = math.min(node.num, self.count + 1)
				self.count = cc.clampf(self.count, 1, math.floor(self.clientMaxLvNeedExp/v.cfg.specialArgsMap.exp))
				if not checkUseItem(self.count, self.lvTouchTimes ~= 0.47) then
					return false
				end
			end
		end
		if onUse() ~= false then
			self:schedule(onUse, 0.05, 0.05, "attrLvUp")
		end

	elseif event.name == "moved" then
		if not self.lvTouchBeganPos then
			self.lvTouchBeganPos = node:getTouchBeganPosition()
		end
		local dx = math.abs(event.x - self.lvTouchBeganPos.x)
		local dy = math.abs(event.y - self.lvTouchBeganPos.y)
		if dx >= ui.TOUCH_MOVE_CANCAE_THRESHOLD or dy >= ui.TOUCH_MOVE_CANCAE_THRESHOLD then
			self:unSchedule("attrLvUp")
		end

	elseif event.name == "ended" or event.name == "cancelled" then
		self:unSchedule("attrLvUp")
		self.lvTouchBeganPos = nil
		self:sendRequeat()
		self.textNum:hide()
	end
end

function CardAttributeView:showBuyInfo(num)
	gGameApp:requestServer("/game/exp/buy_item",function (tb)
		gGameUI:showTip(gLanguageCsv.hasBuy)
	end, self.key, num)
end

function CardAttributeView:upgradeFloatingWord(str)
	local x, y = self.progressBar:xy()
	local advanceNum = cc.Label:createWithTTF("exp+" .. str, ui.FONT_PATH, 54)
		:align(cc.p(0.5, 0.5), x, y + 40)
		:addTo(self.levelupPanel, 11)
	text.addEffect(advanceNum, {color=cc.c4b(0, 255, 0,255), outline={color=cc.c4b(44,44,44,255), size=3}})
	transition.executeSequence(advanceNum)
		:moveBy(0.4, 0, 50)
		:fadeOut(0.1)
		:func(function ()
			advanceNum:removeSelf()
		end)
		:done()
end

function CardAttributeView:canLevelUp()
	local cardLv = self.clientLv:read()
	local roleLv = self.roleLv:read()
	if cardLv < roleLv then
		return true
	end
	return false
end

function CardAttributeView:sendRequeat(cb)
	if not itertools.isempty(self.costData) then
		-- 请求回来清空会导致本地数据计算有问题 升级纯本地模拟
		local data = self.costData
		self.costData = {}
		gGameApp:requestServer("/game/card/exp/use_items", function()
			if cb then
				cb()
			end
		end, self.selectDbId, data)
	else
		if cb then
			cb()
		end
	end
end

function CardAttributeView:onShowAtrtInfo()
	gGameUI:stackUI("city.card.nature_attr_info", nil, nil, self.selectDbId:read())
end

-- 评论
function CardAttributeView:onBtnComment()
	gGameApp:requestServer("/game/card/comment/list", function(tb)
		gGameApp:requestServer("/game/card/score/get",function (score)
			gGameUI:stackUI("city.card.comment", nil, {full = true}, self.cardId:read(), tb.view, score.view)
		end, self.cardId:read())
	end, self.cardId:read(), 0, 20)
end

function CardAttributeView:onShareCard()
	if self.shareTimes:read() >= gCommonConfigCsv.shareTimesLimit then
		gGameUI:showTip(gLanguageCsv.shareTimesNotEnough)
		return
	end
	gGameUI:stackUI("city.card.share_tip", nil, nil, self.selectDbId:read())
end

return CardAttributeView