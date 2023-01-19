-- @date:   2019-07-31
-- @desc:   好感度主界面

local function setEffect(parent, effectName, scale, offsetX, offsetY, zOrder)
	local effect = parent:get("effect")
	local size = parent:size()
	local offsetX = offsetX or 0
	local offsetY = offsetY or 0
	local zOrder = zOrder or 10
	if not effect then
		effect = widget.addAnimationByKey(parent, effectName, "effect", "effect", zOrder)
			:xy(size.width/2 + offsetX, size.height/2 + offsetY)
			:scale(scale)
	else
		effect:play("effect")
	end
end

local function setSubNum(list, node, v)
	bind.extend(list, node, {
		class = "icon_key",
		props = {
			data = {
				key = v.key,
				num = v.num,
			},
			grayState = v.num <= 0 and 1 or 0,
			onNode = function(panel)
				panel:setTouchEnabled(false)
				panel:scale(0.8)
			end
		}
	})
	node:get("icon"):visible(v.num <= 0)
end
local CardFeelView = class("CardFeelView", Dialog)
CardFeelView.RESOURCE_FILENAME = "card_feel.json"
CardFeelView.RESOURCE_BINDING = {
	["btnClose"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")}
		}
	},
	["leftPanel.btnLvUp"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onOneKeyClick")}
		}
	},
	["leftPanel.btnLvUpEasy"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onLvUpEasyClick")}
		}
	},
	["leftPanel.btnLvUp.textTitle"] = {
		binds = {
			event = "effect",
			data = {color = ui.COLORS.NORMAL.WHITE, glow = {color = ui.COLORS.GLOW.WHITE}},
		},
	},
	["leftPanel.btnInfo"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onBtnInfo")}
		}
	},
	["leftPanel"] = "leftPanel",
	["leftPanel.btnSelectItem.note"] = "note",
	["leftPanel.btnSelectItem.img"] = "img",
	["leftPanel.btnSelectItem"] = {
		varname = "btnSelectItem",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onBtnSelectItem")}
		}
	},
	["leftPanel.bar"] = "progressBar",
	["item"] = "item",
	["leftPanel.itemList"] = {
		varname = "itemList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("costItemDatas"),
				item = bindHelper.self("item"),
				onItem = function(list, node, k, v)
					setSubNum(list, node, v)
					node:onTouch(functools.partial(list.itemClick, node, k, v))
				end,
				asyncPreload = 5,
			},
			handlers = {
				itemClick = bindHelper.self("onItemClick"),
			},
		},
	},
	["pageItem"] = "pageItem",
	["leftPanel.pageList"] = {
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("evolutionDatas"),
				item = bindHelper.self("pageItem"),
				onItem = function(list, node, k, v)
					node:get("normal"):visible(v.select ~= true)
					node:get("select"):visible(v.select == true)
				end,
				asyncPreload = 15,
				onAfterBuild = function (list)
					list:setItemAlignCenter()
				end
			},
			handlers = {
				itemClick = bindHelper.self("onItemClick"),
			},
		},
	},
	["leftPanel.textNum"] = "textNum",
	["rightPanel"] = "rightPanel",
	["attrItem"] = "attrItem",
	["rightPanel.attrSubList"] = "attrSubList",
	["rightPanel.attrList"] = {
		varname = "attrList",
		binds = {
			event = "extend",
			class = "tableview",
			props = {
				data = bindHelper.self("attrDatas"),
				item = bindHelper.self("attrSubList"),
				cell = bindHelper.self("attrItem"),
				asyncPreload = 6,
				columnSize = 2,
				onCell = function(list, node, k, v)
					local childs = node:multiget(
						"txtName",
						"txtNum",
						"icon"
					)
					childs.icon:texture(v.icon)
					childs.txtName:text(v.name)
					childs.txtNum:text(math.floor(v.num))
					adapt.oneLinePos(childs.txtName, childs.txtNum, cc.p(20, 0))
				end,
			},
		},
	},
	["rightPanel.effectList"] = "effectList",
	["mask"] = "mask",
}

function CardFeelView:onCreate(cardId)
	self:initModel()
	if not cardId then
		local card = gGameModel.cards:find(self.cards:read()[1])
		cardId = card:read("card_id")
	end
	self.cardId = cardId
	self.costData = {}
	self:enableSchedule()
	self.costItemDatas = idlertable.new()
	local cardCsv = csv.cards[self.cardId]
	self.clientCurLvExp = idler.new(0)
	self.showSuccessTip = false
	self.cardMarkID = cardCsv.cardMarkID
	self.maxLimitLv = table.length(gGoodFeelCsv[cardCsv.feelType])
	self.isFirst = true
	-- 长按时客户端模拟升级
	self.clientCurLvExp = idler.new(0)
	self.clientLv = idler.new(0)
	self.canOneUp = false
	idlereasy.when(self.cardFeels, function(_, cardFeels)
		local cardFeel = cardFeels[cardCsv.cardMarkID] or {}
		local level = cardFeel.level or 0
		if self.oldClientLvEffect and level > self.oldClientLvEffect then
			self.showSuccessTip = true
		end
		self.oldClientLvEffect = level
		self.clientLv:set(level)
		self.clientCurLvExp:set(cardFeel.level_exp or 0)
	end)
	self.note:anchorPoint(0.5, 0.5)
	adapt.setTextAdaptWithSize(self.note, {str = gLanguageCsv.cardFeelViewtext, size = cc.size(220,200), vertical = "center"})
    adapt.oneLinePos(self.img, self.note, nil, "left")
	-- self.lvTouchTimes = 0.5
	self.attrDatas = idlers.new()
	idlereasy.any({self.clientLv, self.items, self.clientCurLvExp}, function(_, clientLv, items, clientCurLvExp)
		local feelCsv = gGoodFeelCsv[cardCsv.feelType]
		-- item数据
		local costItemDatas = {}
		self.canOneUp = false
		local allExp = 0
		for _,v in orderCsvPairs(cardCsv.feelItems) do
			table.insert(costItemDatas, {
				key = v,
				num = items[v] or 0,
				cfg = csv.items[v]
			})
			local feelExp = feelCsv[math.min(clientLv + 1, self.maxLimitLv)].needExp
			local num = items[v] or 0
			allExp = num * csv.items[v].specialArgsMap.feel_exp + allExp
			if clientCurLvExp + allExp >= feelExp then
				self.canOneUp = true
			end
		end
		self.costItemDatas:set(costItemDatas)
		--设置经验和进度条
		self.leftPanel:get("textLv"):text(clientLv)
		if self.showSuccessTip then
			self.showSuccessTip = false
			self.progressBar:setPercent(0)
			setEffect(self.progressBar, "effect/shengjitiao.skel", 0.8)
			setEffect(self.leftPanel, "haogan/haogan.skel", 1, 30, -100, 10)
		end
		self.clientNextLvExp = feelCsv[math.min(clientLv + 1, self.maxLimitLv)].needExp
		self.leftPanel:get("textExp1"):text(clientCurLvExp)
		self.leftPanel:get("textExp2"):text("/" .. self.clientNextLvExp)
		local percent = cc.clampf(clientCurLvExp / self.clientNextLvExp * 100, 0, 100)
		if self.maxLimitLv == clientLv then
			percent = 100
			local maxExp = feelCsv[clientLv].needExp
			self.leftPanel:get("textExp1"):text(maxExp)
			self.leftPanel:get("textExp2"):text("/" .. maxExp)
		end
		adapt.oneLinePos(self.leftPanel:get("textExp2"), self.leftPanel:get("textExp1"), nil, "right")
		if self.progressBar:getPercent() > percent or self.isFirst then
			self.isFirst = false
			self.progressBar:setPercent(percent)
		else
			transition.executeSequence(self.progressBar)
				:progressTo(0.29, percent)
				:done()
		end
		if self.oldClientLv ~= clientLv then
			-- 属性数据
			self:setAttrDatas(feelCsv, clientLv)
			--加成属性数据
			self:setAddAttrDatas(cardCsv, clientLv, self.oldClientLv)
			self.oldClientLv = clientLv
		end
	end)
	--是否选择专属道具
	local state = userDefault.getForeverLocalKey("CardFeelView", false)
	self.selectState = idler.new(state)
	idlereasy.any({self.selectState, self.costItemDatas}, function(_, selectState, costItemDatas)
		local icon = selectState and "common/icon/radio_selected.png" or "common/icon/radio_normal.png"
		self.btnSelectItem:get("img"):texture(icon)
		local sumExp = 0
		for i,v in ipairs(costItemDatas) do
			if selectState == false or (selectState == true and not v.cfg.specialArgsMap.special) then
				sumExp = sumExp + v.cfg.specialArgsMap.feel_exp * v.num
			end
		end
		self.expEnough = sumExp > 0
	end)
	--进化链数据
	self.evolutionDatas = idlers.new({})
	local existCards = {}
	for k,v in ipairs(self.cards:read()) do
		local card = gGameModel.cards:find(v)
		existCards[card:read("card_id")] = true
	end
	local evolutionDatas = {}
	local megaCard = false
	for id,v in orderCsvPairs(csv.cards) do
		if matchLanguage(v.languages) then
			megaCard = false
			if v.cardMarkID == cardCsv.cardMarkID and v.canDevelop then
				megaCard = true
			end
			if not dataEasy.isUnlock(gUnlockCsv.mega) and v.megaIndex > 0 then
				megaCard = false
			elseif not v.canDevelop and dataEasy.isUnlock(gUnlockCsv.mega) then
				megaCard = false
			end
			if megaCard then
				table.insert(evolutionDatas, {
					existCards = existCards,
					selectDevelop = v.develop,
					cfg = v,
					id = id
				})
			end
		end
	end
	table.sort(evolutionDatas,function(a,b)
		return a.id < b.id
	end)
	self.evolutionDatas:update(evolutionDatas)
	-- item1到5个
	local sizeX = self.item:size().width
	local itemNum = self.costItemDatas:size()
	self.itemList:x(self.itemList:x() + (5 - itemNum) * sizeX / 2)
	self.itemList:setItemsMargin((5 - itemNum) * sizeX / 8)
	local selectEvolution = 1
	for i,v in ipairs(evolutionDatas) do
		if v.id == cardCsv.id then
			selectEvolution = i
		end
	end
	self.selectEvolution = idler.new(selectEvolution)
	self.selectEvolution:addListener(function(val, oldval)
		local evolutionDatas = self.evolutionDatas:atproxy(val)
		local oldEvolutionDatas = self.evolutionDatas:atproxy(oldval)
		if oldEvolutionDatas then
			oldEvolutionDatas.select = false
		end
		if evolutionDatas then
			self:setLeftPanel(evolutionDatas)
			evolutionDatas.select = true
		end
	end)
	--切换精灵
	self:initPrivilegeListener()
	self.textNum:hide()
	Dialog.onCreate(self)
end

function CardFeelView:initModel()
	self.items = gGameModel.role:getIdler("items")
	self.cards = gGameModel.role:getIdler("cards")
	--level level_exp
	self.cardFeels = gGameModel.role:getIdler("card_feels")
	self.gold = gGameModel.role:getIdler("gold")
end
--基础属性数据
function CardFeelView:setAttrDatas(feelCsv, clientLv)
	local addAttrDatas = {}
	local attrDatas = {}
	for i=1,6 do
		local num = feelCsv[clientLv]["attrNum"..i]
		local attr = game.ATTRDEF_TABLE[feelCsv[clientLv]["attrType"..i]]
		local name = gLanguageCsv["attr" .. string.caption(attr)]
		local nextNum = 0
		if clientLv < self.maxLimitLv then
			nextNum = feelCsv[clientLv + 1]["attrNum"..i]
		end
		if nextNum > num then
			table.insert(addAttrDatas, {
				name = name,
				num = nextNum - num
			})
		end
		table.insert(attrDatas, {
			name = name..":",
			num = num,
			icon = ui.ATTR_LOGO[attr]
		})
	end
	if #addAttrDatas > 0 then
		local str = "#C0x5b545b#("
		for i=1,2 do
			if addAttrDatas[i] then
				str = string.format("%s#C0x5b545b# %s#C0x60C456#+%s", str, addAttrDatas[i].name, addAttrDatas[i].num)
			end
		end
		str = str .. "#C0x5b545b# )"
		local size = self.rightPanel:get("textTip"):size()
		self.rightPanel:get("textTip"):removeAllChildren()
		rich.createByStr(str, 40)
			:anchorPoint(0, 0.5)
			:xy(size.width+20, size.height/2)
			:addTo(self.rightPanel:get("textTip"), 6)
	else
		self.rightPanel:get("textTip"):hide()
	end
	self.attrDatas:update(attrDatas)
end
--加成属性数据
function CardFeelView:setAddAttrDatas(cardCsv, clientLv, oldClientLv)
	local effectCsv = gGoodFeelEffectCsv[cardCsv.cardMarkID]
	local effectDatas = {}
	for k,v in pairs(effectCsv) do
		local noteColor = "#C0x5B545B#"
		local numColor = "#C0x60C456#"
		if k > clientLv then
			noteColor = "#C0xB7B09E#"
			numColor = "#C0xB7B09E#"
		end
		local str = ""
		local effectSum = 0
		for i=1,6 do
			local num = dataEasy.getAttrValueString(v["attrType"..i], v["attrNum"..i])
			if num ~= "" then
				effectSum = effectSum + 1
				if effectSum > 1 then
					str = string.format("%s%s,", str, noteColor)
				end
				local attr = game.ATTRDEF_TABLE[v["attrType"..i]]
				local name = gLanguageCsv["attr" .. string.caption(attr)]
				str = string.format("%s%s %s%s+%s", str, noteColor, name, numColor, num)

			end
		end
		if effectSum == 6 then
			str = string.format("%s+%s", numColor, dataEasy.getAttrValueString(v["attrType"..1], v["attrNum"..1]))
		end
		if v.natureType ~= 0 then
			local titleTxt = gLanguageCsv[game.NATURE_TABLE[v.natureType]]..gLanguageCsv.xi
			str = string.format(v.desc, titleTxt, str)
		else
			str = string.format(v.desc, str)
		end
		table.insert(effectDatas, {
			str = noteColor .. string.format(gLanguageCsv.feelLevelNote, k) .. str,
			verticalSpace = 10,
			level = v.level
		})
	end
	table.sort(effectDatas, function(a,b)
		return a.level < b.level
	end )
	beauty.textScroll({
		list = self.effectList,
		strs = effectDatas,
		isRich = true,
		fontSize = 40
	})
	for i,v in ipairs(effectDatas) do
		if oldClientLv and v.level > oldClientLv and v.level <= clientLv then
			local box = self.effectList:getChildren()[i]
			setEffect(box, "haogandujiesuo/shuzhibianhua.skel", 1, 0, 5)
		end
	end
end
--左侧面板
function CardFeelView:setLeftPanel(evolutionDatas)
	local childs = self.leftPanel:multiget(
		"textLv",
		"textExp",
		"bar",
		"cardIcon",
		"textTip",
		"iconRarity",
		"textCardName",
		"iconAttr1",
		"iconAttr2",
		"btnSelectItem"
	)
	local unitCsv = csv.unit[evolutionDatas.cfg.unitID]
	local size = childs.cardIcon:size()
	local STATE_ACTION = {"standby_loop", "attack", "win_loop", "run_loop"}
	childs.cardIcon:removeAllChildren()
	local cardSprite = widget.addAnimation(childs.cardIcon, unitCsv.unitRes, STATE_ACTION[1], 5)
		:xy(size.width/2, 0)
		:scale(unitCsv.scaleU*2.3)
	cardSprite:setSkin(unitCsv.skin)
	childs.iconAttr1:texture(ui.ATTR_ICON[unitCsv.natureType])
	childs.iconAttr2:hide()
	if unitCsv.natureType2 then
		childs.iconAttr2:texture(ui.ATTR_ICON[unitCsv.natureType2]):show()
	end
	childs.textTip:visible(evolutionDatas.existCards[evolutionDatas.id] ~= true)
	childs.textCardName:text(evolutionDatas.cfg.name)
	childs.iconRarity:texture(ui.RARITY_ICON[unitCsv.rarity])
	adapt.oneLinePos(childs.textCardName, {childs.iconRarity, childs.textTip}, cc.p(8,0), "right")
	adapt.oneLinePos(childs.textCardName, {childs.iconAttr1, childs.iconAttr2}, cc.p(8,0))
end
--长按升级
function CardFeelView:onItemClick(list, node, k, v, event)
	local function checkUseItem(count, ignoreBox)
		count = count or 1
		if v.num <= 0 then
			if not ignoreBox then
				gGameUI:stackUI("common.gain_way", nil, nil, v.key)
			end
		elseif self:canLevelUp() then
			v.num = v.num - count
			setSubNum(list, node, v)
			self.costData[v.key] = self.costData[v.key] and (self.costData[v.key] + count) or count
			-- 每吃一颗药就增加本地经验
			self.clientCurLvExp:modify(function(oldVal)
				return true, oldVal + v.cfg.specialArgsMap.feel_exp
			end)
			self.textNum:show():text("x"..self.costData[v.key])
			self:checkCanLvUp(k, v)
			if not node.lvUpEffect then
				node.lvUpEffect = widget.addAnimation(node, "koudai_gonghuixunlian/gonghuixunlian.skel", "fangguang", 10)
					:xy(81, 6)
					:scale(0.8)
			else
				node.lvUpEffect:play("fangguang")
			end
			return true

		else
			gGameUI:showTip(gLanguageCsv.feelReachedFullLevel)
		end
	end
	if event.name == "began" then
		self.lvTouchTimes = 0.3
		self.count = 1
		-- local interval = 0.5
		self:schedule(function()
			self.lvTouchTimes = math.max(self.lvTouchTimes - 0.03, 0.05)
			-- interval = interval + 0.1
			-- if interval >= self.lvTouchTimes then
			--	interval = 0
				if not checkUseItem(self.count, self.lvTouchTimes ~= 0.27) then
					return false
				end
			-- end
		end, 0.1, 0, "feelLvUp")

	elseif event.name == "moved" then
		if not self.lvTouchBeganPos then
			self.lvTouchBeganPos = node:getTouchBeganPosition()
		end
		local dx = math.abs(event.x - self.lvTouchBeganPos.x)
		local dy = math.abs(event.y - self.lvTouchBeganPos.y)
		if dx >= ui.TOUCH_MOVE_CANCAE_THRESHOLD or dy >= ui.TOUCH_MOVE_CANCAE_THRESHOLD then
			self:unSchedule("feelLvUp")
		end

	elseif event.name == "ended" or event.name == "cancelled" then
		self:unSchedule("feelLvUp")
		self.lvTouchBeganPos = nil
		self:sendRequeat()
		self.textNum:hide()
	end
end
--同步等级经验
function CardFeelView:checkCanLvUp(idx, data)
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
--是否到达最大等级
function CardFeelView:canLevelUp()
	local cardLv = self.clientLv:read()
	if cardLv < self.maxLimitLv then
		return true
	end
	return false
end
--消耗道具请求
function CardFeelView:sendRequeat(cb)
	if not itertools.isempty(self.costData) then
		-- 请求回来清空会导致本地数据计算有问题 升级纯本地模拟
		local data = self.costData
		self.costData = {}
		gGameApp:requestServer("/game/card/feel/use_items", function()
			if cb then
				cb()
			end
		end, self.cardMarkID, data)
	else
		if cb then
			cb()
		end
	end
end
--一键升级
function CardFeelView:onOneKeyClick()
	if not self:canLevelUp() then
		gGameUI:showTip(gLanguageCsv.feelReachedFullLevel)
		return
	end
	if not self.expEnough then
		gGameUI:showTip(gLanguageCsv.materialsNotEnough)
		return
	end
	gGameUI:showDialog({content = gLanguageCsv.wantUpgradeWithOneClick, cb = function()
		gGameApp:requestServer("/game/card/feel/tomax", function (tb)

		end, self.cardMarkID, self.selectState)
	end, btnType = 2})
end

--快速升级
function CardFeelView:onLvUpEasyClick()
	if not self:canLevelUp() then
		gGameUI:showTip(gLanguageCsv.feelReachedFullLevel)
		return
	end
	if self.canOneUp then
		gGameUI:stackUI("city.card.feel.upgrade", nil, nil, {cardMarkID = self.cardMarkID, cardId = self.cardId, type = 2, selectState = self.selectState})    -- 传type = 1代表的是等级一键提升
	else
		gGameUI:showTip(gLanguageCsv.materialsNotEnough)
	end
end

--复选框
function CardFeelView:onBtnSelectItem()
	local state = userDefault.getForeverLocalKey("CardFeelView", false)
	self.selectState:set(not state)
	userDefault.setForeverLocalKey("CardFeelView", not state)
end
--切换精灵
function CardFeelView:initPrivilegeListener()
	uiEasy.addTouchOneByOne(self.mask, {ended = function(pos, dx, dy)
		if math.abs(dx) > 100 and math.abs(dx) > math.abs(dy) then
			local dir = dx > 0 and -1 or 1
			self.selectEvolution:modify(function(val)
				val = cc.clampf(val + dir, 1, self.evolutionDatas:size())
				return true, val
			end)
		end
	end})
end
--规则
function CardFeelView:onBtnInfo()
	gGameUI:stackUI("common.rule", nil, nil, self:createHandler("getRuleContext"), {width = 880})
end
function CardFeelView:getRuleContext(view)
	local c = adaptContext
	local context = {
		c.clone(view.title, function(item)
			item:get("text"):text(gLanguageCsv.savorableOpinionStatement)
		end),
		c.noteText(61001, 61020),
	}
	return context
end
return CardFeelView