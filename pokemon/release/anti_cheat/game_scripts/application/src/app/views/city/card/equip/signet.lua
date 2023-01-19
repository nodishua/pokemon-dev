local CardEquipSignetView = class("CardEquipSignetView", cc.load("mvc").ViewBase)
local equipView = require "app.views.city.card.equip.view"
local TYPE = {
	--星级
	STAR = 1,
	--觉醒
	AWAKE = 2
}
local FIVE = 5
local DOT = {
	[0] = "city/card/equip/icon_hui.png",
	[1] = "city/card/equip/icon_lv.png",
	[2] = "city/card/equip/icon_qianlan.png",
	[3] = "city/card/equip/icon_lan.png",
	[4] = "city/card/equip/icon_qianzi.png",
	[5] = "city/card/equip/icon_zi.png",
	[6] = "city/card/equip/icon_huang.png",
	[7] = "city/card/equip/icon_cheng.png",
	[8] = "city/card/equip/icon_hong.png",
	[9] = "city/card/equip/icon_shenhong.png",
}
local CIRCLECOLOR = {
	[0] = "city/card/equip/bar_hui.png",
	[1] = "city/card/equip/bar_lv.png",
	[2] = "city/card/equip/bar_qianlan.png",
	[3] = "city/card/equip/bar_lan.png",
	[4] = "city/card/equip/bar_qianzi.png",
	[5] = "city/card/equip/bar_zi.png",
	[6] = "city/card/equip/bar_huang.png",
	[7] = "city/card/equip/bar_cheng.png",
	[8] = "city/card/equip/bar_hong.png",
	[9] = "city/card/equip/bar_shenhong.png",
}
CardEquipSignetView.RESOURCE_FILENAME = "card_equip_signet.json"
CardEquipSignetView.RESOURCE_BINDING = {
	["panel.max"] = "max",
	["panel.qualityItem"] = "qualityItem",
	["panel.passiveDetail"] = "passiveDetail",
	["panel.qualityItem.leftQuality"] = "leftQuality",
	["panel.qualityItem.rightQuality"] = "rightQuality",
	["panel.bottomPanel.itemPanel"] = "itemPanel",
	["panel.bottomPanel.list"] = "list",
	["item"] = "item",
	["panel.btnDown"] = {
		varname = "btnDown",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onDown")}
		},
	},
    ["panel.listAttr"] = {
		varname = "listAttr",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("attrDatas"),
				item = bindHelper.self("item"),
				levelItem = bindHelper.self("levelItem"),
                onItem = function(list, node, k, v)
					local childs = node:multiget(
						"name",
						"left",
						"right",
						"arrow"
					)
					childs.name:text(v.name..":")
					childs.left:text("+"..v.num)
					childs.arrow:visible(not v.isAdvance)
					childs.right:visible(not v.isAdvance)
					childs.right:text("+"..v.nextNum):visible(not v.isMax)
					childs.arrow:visible(not v.isMax)
					adapt.oneLinePos(childs.name, {childs.left, childs.arrow, childs.right}, cc.p(30,0))
				end,
			}
		},
    },
    ["panel.bottomPanel.btnUpgrade"] = {
		varname = "btnUpgrade",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onSignet")}
		},
	},
	["panel.bottomPanel.onekeyUpgrade"] = {
		varname = "onekeyUpgrade",
		binds = {
			{
				event = "touch",
				methods = {ended = bindHelper.self("onSignetOneKey")}
			},
			{
				event = "visible",
				idler = bindHelper.self("oneKeyVisible")
			},
		},
    },
    ["panel.bottomPanel.btnUpgrade.textNote"] = {
		binds = {
			event = "effect",
			data = {glow={color=ui.COLORS.GLOW.WHITE}},
		},
	},
    ["panel.btnInfo"] = {
		varname = "btnInfo",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onBtnDetailClick")}
		},
	},

	["panel.bottomPanel"] = "bottomPanel",
	["panel.bottomPanel.cost"] = "cost",
	["panel.bottomPanel.icon"] = "icon",
	["panel.bottomPanel.txt"] = "txt",
	["panel.bottomPanel.panel"] = "iconPanel",
    ["panel.pos"] = "pos",
	["panel"] = "panel",
	["panel.circle"] = "circle",
}

function CardEquipSignetView:onCreate(dbHandler)
	self.selectDbId, self.equipIndex = dbHandler()
    self:initModel()
	self.spine = widget.addAnimation(self.pos, "effect/shipinfaguang.skel", "effect_loop", 20):scale(0.75)
		 :xy(-55, 50)
	self.attrDatas = idlers.newWithMap({})

	self.csvSignetAdvance = {}
	self:initCsvSignet()

	self.callBackSign = false
	self.refreshDelayNums = 0

	local oneKeyX = self.btnUpgrade:x()
	self.oneKeyUnlock = false

	self.oneKeyVisible = idler.new()
	dataEasy.getListenUnlock(gUnlockCsv.oneKeySignet, function(isUnlock)
		self.oneKeyUnlock = isUnlock
		self.oneKeyVisible:set(isUnlock)
	end)

	idlereasy.when(self.oneKeyVisible, function(_, oneKeyVisible)
		if self.oneKeyUnlock then
			local nodeX = oneKeyVisible and oneKeyX or self.iconPanel:x()
			self.btnUpgrade:x(nodeX)
		else
			self.btnUpgrade:x(self.iconPanel:x())
		end
	end)

	idlereasy.any({self.equips, self.equipIndex, self.gold}, function (_, equips,index, gold)
		self.speedBtn = true
		local func = function()
			self:refreshData()
			if self.callBackSign then
				self.callBackSign = false
				for _, child in pairs(self.listAttr:getChildren()) do
					local spine = child:get("spine")
					if not spine then
						spine = widget.addAnimationByKey(child, "effect/shuzisaoguang.skel", "spine", "effect", 122)
							:xy(child:size().width/2, child:size().height/2 + 5)
							:scale(0.5)
					else
						spine:play("effect")
					end
				end
				self:playSpine(1)
			end
		end

		if not self.callBackSign then
			self:refreshData()
		else
			if self.refreshDelayNums == 0  then
				performWithDelay(self, function ()
					func()
				end, 1/60)
			end
			self.refreshDelayNums = self.refreshDelayNums + 1
		end
	end)
end


function CardEquipSignetView:initModel()
	idlereasy.when(self.selectDbId,function (_, selectDbId)
		local card = gGameModel.cards:find(selectDbId)
		self.equips = idlereasy.assign(card:getIdler("equips"), self.equips)
		self.fight = idlereasy.assign(card:getIdler("fighting_point"), self.fight)
	end)
	self.level = gGameModel.role:getIdler("level")
	self.gold = gGameModel.role:getIdler("gold")
	self.rmb = gGameModel.role:getIdler("rmb")
end

function CardEquipSignetView:initCsvSignet()
	for index, data in csvPairs(csv.base_attribute.equip_signet_advance) do
		if self.csvSignetAdvance[data.advanceIndex] == nil then
			self.csvSignetAdvance[data.advanceIndex] = {}
		end
		self.csvSignetAdvance[data.advanceIndex][data.advanceLevel] = data
	end
end

function CardEquipSignetView:refreshData()
	local equips = self.equips:read()
	local index = self.equipIndex:read()
	local gold = self.gold:read()

	local data = equips[index]
	local cfg = csv.equips[data.equip_id]
	local signet = data.signet or 0
	local signetAdvance = data.signet_advance or 0
	local nextSignet = 0
	local leftQuality = 0
	local rightQuality = 0
	local dot = signet - signetAdvance * FIVE

	self.refreshDelayNums = 0
	self.data = data
	self.isEnoughItem = true
	self.signetMax = FIVE * cfg.signetAdvanceMax or 0

	if signet > 0 then
		self.btnDown:texture("city/card/equip/icon_kyjj.png")
	else
		self.btnDown:texture("city/card/equip/icon_kyjj1.png")
	end

	self.passiveDetail:visible(dot == FIVE)
	self.bottomPanel:visible(signetAdvance < cfg.signetAdvanceMax)
	self.max:visible(signetAdvance == cfg.signetAdvanceMax)

	self:refreshCircle(signetAdvance, dot)

	itertools.invoke({self.cost, self.icon, self.txt}, "hide")
	text.addEffect(self.cost, {color = ui.COLORS.NORMAL.DEFAULT})

	local curSignetAdvance = self.csvSignetAdvance[cfg.advanceIndex][signetAdvance]
	local nextSignetAdvance = self.csvSignetAdvance[cfg.advanceIndex][signetAdvance+1]

	leftQuality = curSignetAdvance.advanceName
	rightQuality = curSignetAdvance.advanceName
	nextSignet = dot + 1
	if dot == FIVE then
		rightQuality = nextSignetAdvance.advanceName
		nextSignet = 0
	end

	local childs = self.qualityItem:multiget("leftQuality","rightQuality","arrow")

	childs.leftQuality:text(leftQuality.." "..dot..gLanguageCsv.signetLevel)
	childs.rightQuality:text(rightQuality.." "..nextSignet..gLanguageCsv.signetLevel)
	childs.arrow:visible(signet < self.signetMax)
	childs.rightQuality:visible(signet < self.signetMax)
	if matchLanguage({"kr"}) then
		adapt.oneLinePos(childs.leftQuality, {childs.arrow, childs.rightQuality}, cc.p(20,0))
	else
		adapt.oneLinePos(childs.leftQuality, {childs.arrow, childs.rightQuality}, cc.p(30,0))
	end

	if signet == self.signetMax then
		adapt.oneLinePos(childs.leftQuality,self.btnInfo,cc.p(520,0))
	else
		adapt.oneLinePos(childs.leftQuality,self.btnInfo,cc.p(750,0))
	end

	self:initAttr(signet,signetAdvance,cfg)

	local itemLen = 0
	if signetAdvance == cfg.signetAdvanceMax then

		self:refreshCircle(signetAdvance-1, FIVE)
		local preSignetAdvance = self.csvSignetAdvance[cfg.advanceIndex][signetAdvance - 1]
		leftQuality = preSignetAdvance.advanceName
		childs.leftQuality:text(leftQuality .. " " .. FIVE .. gLanguageCsv.signetLevel)
	else

		local costItemMap = csv.base_attribute.equip_signet[signet]["costItemMap"..cfg.signetStrengthSeqID]
		self.btnUpgrade:get("textNote"):text(gLanguageCsv.signet)
		if self.oneKeyUnlock then
			self.oneKeyVisible:set(true)
		end
		self.list:visible(true)
		self.itemPanel:visible(false)

		if dot == FIVE then
			--需要饰品两星
			self:setPassiveDetail(signetAdvance, cfg)
			if nextSignetAdvance.advanceLimitType == TYPE.STAR then
				if data.star < nextSignetAdvance.advanceLimitNum then
					self.limitTip = string.format(gLanguageCsv.needEquipStar, nextSignetAdvance.advanceLimitNum)
				end
			elseif nextSignetAdvance.advanceLimitType == TYPE.AWAKE then
				if data.awake <nextSignetAdvance.advanceLimitNum then
					self.limitTip = gLanguageCsv.needEquipAwake..gLanguageCsv["symbolRome"..nextSignetAdvance.advanceLimitNum]
				end
			else
				self.limitTip = 0
			end

			self.btnUpgrade:get("textNote"):text(gLanguageCsv.advance)
			self.oneKeyVisible:set(false)


			costItemMap = csv.base_attribute.equip_signet_advance_cost[signetAdvance]["costItemMap"..nextSignetAdvance.advanceSeqID]
		end

		local newT = {}
		for key,value in csvMapPairs(costItemMap) do
			if key ~= "gold" then
				local hasNum = dataEasy.getNumByKey(key)
				if value > hasNum and self.isEnoughItem then
					self.isEnoughItem = false
				end
				table.insert(newT, {
					key = key,
					targetNum = value,
					num = hasNum,
					grayState = hasNum < value and 1 or 0
				})
				self.itemPanel:get("btnAdd"):visible(false)
			else
				self.isEnoughGold = gold >= value
				self.cost:text(value)
				itertools.invoke({self.cost, self.icon, self.txt}, "show")

				text.addEffect(self.cost, {color = self.isEnoughGold and ui.COLORS.NORMAL.DEFAULT or ui.COLORS.NORMAL.ALERT_ORANGE})
				adapt.oneLineCenterPos(cc.p(self.btnUpgrade:x(), self.btnUpgrade:y() + 90), {self.txt, self.cost, self.icon})
			end
		end

		itemLen = #newT or 0
		uiEasy.createItemsToList(self, self.list, newT, {
			onAfterBuild = function (list)
				list:setItemAlignCenter()
				list:setClippingEnabled(false)
			end,
			margin = 20,
			scale = 0.9,
			onNode = function (panel, v)
				bind.click(self.list, panel, {method = function()
					jumpEasy.jumpTo("gainWay", v.key, nil, v.targetNum)
				end})
				local size = panel:size()
				local addIcon = panel:get("addIcon")
				if v.targetNum > v.num then
					if not addIcon then
						ccui.ImageView:create("common/btn/btn_add_icon.png")
							:xy(size.width/2, size.height/2)
							:addTo(panel, 60, "addIcon")
					else
						addIcon:show()
					end
				else
					if addIcon then
						addIcon:hide()
					end
				end
			end
		})
		self.list:y(180)
	end

	if signet == self.signetMax then
		self.btnDown:xy((self.max:x() + 330),350)
	else
		self.btnDown:xy(self.iconPanel:x() + itemLen * (180 - itemLen * 8),310)
	end
end

-- 刷新圆圈状态
function CardEquipSignetView:refreshCircle(signetAdvance, dot)
	for i = 1, FIVE do
		local imgDot = self.circle:get("dot"..i)
		if i > dot then
			imgDot:visible(false)
		else
			imgDot:texture(DOT[signetAdvance])
			imgDot:visible(true)
		end
	end

	local childs = self.circle:multiget("circleColor","circlePos")
	childs.circleColor:visible(false)
	childs.circlePos:removeAllChildren()
	if dot ~= 0 then
		self:setProgress(childs.circlePos,cc.p(195,193),dot - 1)
		childs.circlePos:rotate(216)
	end
end


function CardEquipSignetView:setPassiveDetail(signetAdvance,cfg)
	local nextSignetAdvance = self.csvSignetAdvance[cfg.advanceIndex][signetAdvance+1]
	local detail = {}
	for j=1,math.huge do
		local signetAttr = nextSignetAdvance["attrType"..j]
		if not signetAttr or signetAttr == 0 then
			break
		end
		local attrTypeStr = game.ATTRDEF_TABLE[signetAttr]
		local str = "attr".. string.caption(attrTypeStr)
		table.insert(detail,{
			name = gLanguageCsv[str],
			num = dataEasy.getAttrValueString(signetAttr, nextSignetAdvance["attrNum"..j])
		})
	end
	local strAttr = ""
	for i=1,#detail do
		strAttr = strAttr..detail[i].name.."+"..detail[i].num.."  "
	end
	local scene = ""
    for k,val in csvMapPairs(nextSignetAdvance.sceneType) do
        local num = val
        local text = game.SCENE_TYPE_STRING_TABLE[num]
        scene = scene..gLanguageCsv[text]
        if k < table.getn(nextSignetAdvance.sceneType) then
            scene = scene..gLanguageCsv.signetAnd
        end
    end
	local str = string.format(gLanguageCsv.signetBeiDong,nextSignetAdvance.advanceLevel,scene)
	if matchLanguage{"kr"} then
		strAttr = str.." "..strAttr
	else
		strAttr = str..strAttr
	end
	self.passiveDetail:text(strAttr)
end

function CardEquipSignetView:initAttr(signet,signetAdvance,cfg)
	self.signetAdvanceData = {}
	local t = {}
	for i=1,math.huge do
		local signetAttr = cfg["signetAttrType" .. i]
		if not signetAttr or signetAttr == 0 then
			break
		end
		local attrTypeStr = game.ATTRDEF_TABLE[signetAttr]
		local str = "attr" .. string.caption(attrTypeStr)
		local num, nextNum = dataEasy.getAttrValueAndNextValue(signetAttr, cfg["signetAttrNum"..i][signet] or 0, cfg["signetAttrNum"..i][signet + 1] or 0)
		if (signetAdvance + 1) * FIVE == signet then
			nextNum = num
		end
		table.insert(t, {
			name = gLanguageCsv[str],
			num = math.floor(num),
			nextNum = math.floor(nextNum),
			isMax = signet >= self.signetMax,
			isAdvance = signet == (signetAdvance + 1 ) * FIVE or signetAdvance == cfg.signetAdvanceMax
		})

		if not self.signetAdvanceData[i] then
			self.signetAdvanceData[i] = {num1 = num, num2 = nextNum}
		end
	end
	self.listAttr:setAnchorPoint(cc.p(0,1))
	self.listAttr:size(516,#t * 60)
	self.listAttr:y(self.qualityItem:y()-30)
	self.attrDatas:update(t)
	self.passiveDetail:y(self.listAttr:y() -10 - self.passiveDetail:height()/2 - #t * 60)
end

--刻印
function CardEquipSignetView:onSignet()
	if not self.speedBtn  then
		return
	end
	self.speedBtn = false
	local fight = self.fight:read()
	local equips = self.equips:read()
	local index = self.equipIndex:read()
	local data = equips[index]
	local cfg = csv.equips[data.equip_id]
	local signet = data.signet or 0
	local signetAdvance = data.signet_advance or 0
	local limitTip = self.limitTip or 0
	if not self.isEnoughItem then
		self.speedBtn = true
		gGameUI:showTip(gLanguageCsv.equipNotEnoughSignetItems)
		return
	end
	if self.isEnoughGold == false then
		self.speedBtn = true
		gGameUI:showTip(gLanguageCsv.cardSignetGoldNotEnough)
		return
	end
	local showOver = {false}
	local textBD = matchLanguage({"kr"}) and self.passiveDetail:text() or string.sub(self.passiveDetail:text(),10)
	--突破
	if signet == (signetAdvance + 1) * FIVE then
		gGameApp:requestServerCustom("/game/equip/signet/advance")
		:onErrCall(function()
			self.speedBtn = true
		end)
		:params(self.selectDbId, cfg.part)
		:onResponse(function (tb)
			idlereasy.do_(function (equips, index)
				self:playSpine(1, function()
					gGameUI:stackUI("city.card.equip.success", nil, {blackLayer = true}, {
						leftItem = data,
						rightItem = equips[index],
						type = "signetAdvance",
						fight = fight,
						cardDbid = self.selectDbId:read(),
						leftQuality = self.leftQuality:text(),
						rightQuality = self.rightQuality:text(),
						textBD = textBD,
						limitTip = limitTip,
						isMax = signetAdvance == cfg.signetAdvanceMax - 1,
						signetAdvanceData = self.signetAdvanceData,
					})
					showOver[1] = true
				end)
			end, self.equips, self.equipIndex)
			end)
		:wait(showOver)
		:doit(function()
		end)
		return
	end

	self.callBackSign = true
	gGameApp:requestServer("/game/equip/signet", function(tb)
	end, self.selectDbId, cfg.part)
end

function CardEquipSignetView:onSignetOneKey()
	if not self.isEnoughItem then
		gGameUI:showTip(gLanguageCsv.equipNotEnoughSignetItems)
		return
	end
	if self.isEnoughGold == false then
		gGameUI:showTip(gLanguageCsv.cardSignetGoldNotEnough)
		return
	end
	gGameUI:stackUI("city.card.equip.fast_signet", nil, nil, self.selectDbId:read(), self.data.equip_id, self:createHandler("playSpine"))
end

function CardEquipSignetView:playSpine(timeScale, callback)
	local spine = self.pos:get("effect")
	if spine then
		spine:setTimeScale(timeScale or 1)
		spine:play("fangguang2")
	else
		spine = widget.addAnimationByKey(self.pos, "koudai_gonghuixunlian/gonghuixunlian.skel", "effect", "fangguang2", 10000)
		spine:xy(self.pos:size().width/2, 0)
	end

	spine:setSpriteEventHandler(function(event, eventArgs)
		if callback then
			callback()
		end
	end, sp.EventType.ANIMATION_COMPLETE)
end

function CardEquipSignetView:onDown()
	local signetNum = self.data.signet or 0
	local signetAdvance = self.data.signet_advance or 0
	if signetNum <= 0 then
		gGameUI:showTip(gLanguageCsv.currentSignetCannotReduced)
		return
	end
	local cfg = csv.equips[self.data.equip_id]
	local costCfg = gCostCsv.equip_drop_cost
	local idx1 = math.min(signetNum, table.length(costCfg))
	local costRmb = costCfg[idx1]
	gGameUI:showDialog({
		strs = {
			string.format(gLanguageCsv.equipStarDownCost,costRmb),
			string.format(gLanguageCsv.equipStarDownReturn, gLanguageCsv.signet)
		},
		align = "left",
		isRich = true,
		cb = function ()
			if costRmb > self.rmb:read() then
				gGameUI:showTip(gLanguageCsv.rmbNotEnough)
				return
			end
			gGameApp:requestServer("/game/equip/signet/drop",function (tb)
				local award = {}
				for i=0,signetNum-1 do
					for k,v in csvMapPairs(csv.base_attribute.equip_signet[i]["costItemMap"..cfg.signetStrengthSeqID]) do
						-- if k ~= "gold" then
						if not award[k] then
							award[k] = 0
						end
						award[k] = award[k] + v
						-- end
					end
				end
				for i=0,signetAdvance-1 do
					for key,v in csvPairs(csv.base_attribute.equip_signet_advance) do
						if signetAdvance == cfg.signetAdvanceMax then
							signetAdvance = signetAdvance - 1
						end
						if v.advanceIndex == cfg.advanceIndex and v.advanceLevel == signetAdvance + 1 then
							for k,val in csvMapPairs(csv.base_attribute.equip_signet_advance_cost[i]["costItemMap"..v.advanceSeqID]) do
								-- if k ~= "gold" then
								if not award[k] then
									award[k] = 0
								end
								award[k] = award[k] + val
								-- end
							end
						end
					end

				end
				gGameUI:showGainDisplay(award)
			end, self.selectDbId, cfg.part)
		end,
		btnType = 1,
		clearFast = true,
		dialogParams = {clickClose = false},
	})
end

function CardEquipSignetView:setProgress(parent,pos,level)
	level = level or 0
	local percent = level * 100 / FIVE
	local signetAdvance = self.data.signet_advance or 0
	local res = CIRCLECOLOR[signetAdvance]
	if self.signetMax == FIVE * signetAdvance then
		res = CIRCLECOLOR[signetAdvance - 1]
	end
	local left = cc.ProgressTimer:create(cc.Sprite:create(res))
	left:setType(cc.PROGRESS_TIMER_TYPE_RADIAL)
	parent:addChild(left)
	left:setPosition(pos)
	left:setPercentage(percent)
end

function CardEquipSignetView:onBtnDetailClick()
	local data = clone(self.data)
	gGameUI:stackUI("city.card.equip.singnet_info", nil, nil, data)
end

return CardEquipSignetView