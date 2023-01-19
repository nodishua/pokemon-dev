-- @desc: 卡牌羁绊

local CardEquipStrengthenView = class("CardEquipStrengthenView", cc.load("mvc").ViewBase)
local CardEquipView = require "app.views.city.card.equip.view"
CardEquipStrengthenView.RESOURCE_FILENAME = "card_equip_strengthen.json"
CardEquipStrengthenView.RESOURCE_BINDING = {
	["panel.upgradePanel.qualityItem"] = "qualityItem",
	["panel.strengthenPanel.levelItem"] = "levelItem",
	["item"] = "item",
	["panel.listAttr"] = {
		varname = "listAttr",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("attrDatas"),
				item = bindHelper.self("item"),
				levelItem = bindHelper.self("levelItem"),
				qualityItem = bindHelper.self("qualityItem"),
				onItem = function(list, node, k, v)
					local childs = node:multiget("name", "left", "right", "arrow")
					local attrTypeStr = game.ATTRDEF_TABLE[v.attr]
					local str = "attr" .. string.caption(attrTypeStr)
					if v.nextVal ~= 0 then
						childs.right:text(math.round(v.nextVal))
					end
					childs.right:visible(v.nextVal ~= 0)
					childs.arrow:visible(v.nextVal ~= 0)
					childs.left:text(math.round(v.currVal))
					childs.name:text(gLanguageCsv[str]..": ")
					if v.playSpine then
						if k == #list.data then
							if list.levelItem:get("spine") then
								list.levelItem:get("spine"):play("effect")
							else
								widget.addAnimationByKey(list.levelItem, "effect/shuzisaoguang.skel", "spine", "effect", 122)
									:xy(list.levelItem:size().width/2-90, list.levelItem:size().height/2 + 5)
									:scale(0.5)
							end
							if list.qualityItem:get("spine") then
								list.qualityItem:get("spine"):play("effect")
							else
								widget.addAnimationByKey(list.qualityItem, "effect/shuzisaoguang.skel", "spine", "effect", 122)
									:xy(list.qualityItem:size().width/2-90, list.qualityItem:size().height/2 + 5)
									:scale(0.5)
							end
						end
						widget.addAnimationByKey(node, "effect/shuzisaoguang.skel", "spine", "effect", 122)
							:xy(node:size().width/2-90, node:size().height/2 + 5)
							:scale(0.5)
					end
					adapt.oneLinePos(childs.name, {childs.left, childs.arrow, childs.right}, {cc.p(15, 0), cc.p(25, 0), cc.p(25, 0)}, "left")
				end,
			}
		},
	},


	["panel.strengthenPanel.btnStrengthen"] = {
		varname = "btnStrengthen",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onStrengthen")}
		},
	},
	["panel.strengthenPanel.btnOne"] = {
		varname = "btnOne",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onStrengthenOne")}
		},
	},
	["panel.strengthenPanel.btnFast"] = {
		varname = "btnFast",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onStrengthenFast")}
		},
	},
	["panel.upgradePanel.btnUpgrade"] = {
		varname = "btnUpgrade",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onAdvance")}
		},
	},
	["panel.upgradePanel.btnUpgrade.textNote"] = {
		binds = {
			event = "effect",
			data = {glow={color=ui.COLORS.GLOW.WHITE}},
		},
	},
	["panel.strengthenPanel.btnStrengthen.textNote"] = {
		binds = {
			event = "effect",
			data = {glow={color=ui.COLORS.GLOW.WHITE}},
		},
	},
	["panel.strengthenPanel"] = "strengthenPanel",
	["panel.upgradePanel"] = "upgradePanel",
	["panel.upgradePanel.list"] = "list",
	["panel.pos"] = "pos",
	["panel"] = "panel",
	["mask"] = "mask",
}

function CardEquipStrengthenView:onCreate(dbHandler)
	self.selectDbId, self.equipIndex, self.tabKey, self.state = dbHandler()

	self:enableSchedule()
	self:initModel()

 	self.shiningSpine = widget.addAnimation(self.pos, "effect/shipinfaguang.skel", "effect_loop", 20):scale(0.75)
	 	:xy(-55, 50)
	self.attrDatas = idlers.newWithMap({})
	self.baseT = {}
	for i,v in csvMapPairs(csv.base_attribute.equip_advance) do
		self.baseT[v.equip_id] = self.baseT[v.equip_id] or {}
		self.baseT[v.equip_id][v.stage] = v
	end

	idlereasy.any({self.equips, self.equipIndex, self.level, self.gold, self.tabKey}, function (_, equips, index, level, gold, tabKey)
		local data = equips[index]
		self.upLevel = 0
		local newGold = gold
		local cfg = csv.equips[data.equip_id]
		local currLevelLimit = cfg.strengthMax[data.advance]
		if data.level < currLevelLimit then
			for i = data.level, currLevelLimit do
				local cost = csv.base_attribute.equip_strength[i]["costGold"..cfg.strengthSeqID]
				newGold = newGold - cost
				if newGold < 0 then
					self.upLevel = i
					break
				elseif i == currLevelLimit then
					self.upLevel = currLevelLimit
				end
			end
		end
		self.data = data
		-- 如果切换，则暂停一键强化动画，但当次一键强化除外
		-- model sync 早于 schdule
		self:onOneKeyPlayEnd(true)
		-- 有一键强化时，先不直接刷新，由动画播放
		if not self.isOneKeyBegin then
			self:update(data, level, gold)
		end
	end)
	--快速升级unlock
	dataEasy.getListenUnlock(gUnlockCsv.fastStrengthen, function(isUnlock)
		nodetools.invoke(self.strengthenPanel, {"btnFast", "txt5", "txt6"}, isUnlock and "show" or "hide")
		local posX = self.btnFast:x()
		if isUnlock then
			posX = (posX + self.btnStrengthen:x())/2
		end
		self.btnOne:x(posX)
		if matchLanguage({"en"}) then
			self.strengthenPanel:get("txt5"):x(self.strengthenPanel:get("txt3"):x())
			adapt.oneLinePos(self.strengthenPanel:get("txt5"), self.strengthenPanel:get("txt6"), cc.p(5,0), "left")
		end
	end)
end



function CardEquipStrengthenView:update(data, level, gold)
	local cfg = csv.equips[data.equip_id]
	local advance = data.advance
	local currLevelLimit = cfg.strengthMax[advance]
	level = level or self.level:read()
	gold = gold or self.gold:read()
	local t = {}
	local maxLevel = cfg.strengthMax[csvSize(cfg.strengthMax)]

	if data.level < currLevelLimit then
		for i=1, math.huge do
			local attr, currVal, nextVal = CardEquipView.getAttrNum(data, i, "strengthen")
			if attr == 0 then
				break
			end
			table.insert(t, {attr = attr, currVal = currVal, nextVal = nextVal})
		end
		local childs = self.levelItem:multiget("name","arrow", "leftPanel", "rightPanel")
		local leftLevelTxt = childs.leftPanel:get("level")
		local rightLevelTxt = childs.rightPanel:get("level")
		leftLevelTxt:text(data.level)
		rightLevelTxt:text(data.level + 1)
		local leftLv = childs.leftPanel:get("lv")
		local rightLv = childs.rightPanel:get("lv")
		adapt.oneLinePos(leftLv, leftLevelTxt, nil, "left")
		adapt.oneLinePos(rightLv, rightLevelTxt, nil, "left")
		childs.leftPanel:size(leftLv:size().width + leftLevelTxt:size().width, childs.leftPanel:size().height)
		childs.rightPanel:size(rightLv:size().width + rightLevelTxt:size().width, childs.rightPanel:size().height)
		adapt.oneLinePos(childs.name,{childs.leftPanel, childs.arrow, childs.rightPanel}, {cc.p(15, 0), cc.p(25, 0), cc.p(25, 0)}, "left")
		local cost = csv.base_attribute.equip_strength[data.level]["costGold"..cfg.strengthSeqID]
		childs = self.strengthenPanel:multiget("cost", "icon", "txt")
		text.addEffect(childs.cost, {color = gold >= cost and ui.COLORS.NORMAL.DEFAULT or ui.COLORS.NORMAL.ALERT_ORANGE})
		self.isEnoughGoldStrengthen = gold >= cost
		childs.cost:text(cost)
		adapt.oneLineCenterPos(cc.p(self.btnStrengthen:x(), self.btnStrengthen:y() + 90), {childs.txt, childs.cost, childs.icon})
		childs.cost:visible(cost > 0)
		childs.icon:visible(cost > 0)
		childs.txt:visible(cost > 0)
	else
		for i=1,math.huge do
			local attr, currVal, nextVal = CardEquipView.getAttrNum(data, i, "advance")
			if attr == 0 then
				break
			end
			table.insert(t, {attr = attr, currVal = currVal, nextVal = nextVal})
		end
		local currQuality, currNumStr = dataEasy.getQuality(data.advance)
		local nextQuality, nextNumStr = dataEasy.getQuality(data.advance + 1)

		local childs = self.qualityItem:multiget("name", "arrow", "leftQuality", "rightQuality")
		childs.leftQuality:text(gLanguageCsv[ui.QUALITY_COLOR_SINGLE_TEXT[currQuality]]..currNumStr)
		childs.rightQuality:text(gLanguageCsv[ui.QUALITY_COLOR_SINGLE_TEXT[nextQuality]]..nextNumStr)
		text.addEffect(childs.leftQuality,{color = currQuality == 1 and ui.COLORS.NORMAL.DEFAULT or ui.COLORS.QUALITY[currQuality]})
		text.addEffect(childs.rightQuality,{color = nextQuality == 1 and ui.COLORS.NORMAL.DEFAULT or ui.COLORS.QUALITY[nextQuality]})

		if matchLanguage({"cn", "tw", "kr"}) then
			adapt.oneLinePos(childs.name, {childs.leftQuality, childs.arrow, childs.rightQuality}, {cc.p(15, 0), cc.p(25, 0), cc.p(25, 0)}, "left")
		elseif matchLanguage({"en"}) then
			childs.name:y(79)
			childs.leftQuality:x(9)
			adapt.oneLinePos(childs.leftQuality, {childs.arrow, childs.rightQuality}, {cc.p(25, 0), cc.p(25, 0)}, "left")
		end

		local newT = {}
		self.isEnoughItem = true
		for k,v in csvMapPairs(gEquipAdvanceCsv[data.equip_id][data.advance].costItemMap) do
			local hasNum = dataEasy.getNumByKey(k)
			if v > hasNum and self.isEnoughItem then
				self.isEnoughItem = false
			end
			table.insert(newT, {key = k, targetNum = v, num = hasNum, grayState = hasNum < v and 1 or 0})
		end

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
							-- :anchorPoint(0.5, 0.5)
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
		childs = self.upgradePanel:multiget("cost", "icon", "txt")
		local cost = gEquipAdvanceCsv[data.equip_id][data.advance].costGold
		local currRoleLimitLevel = cfg.roleLevelMax[data.advance]
		itertools.invoke({childs.icon, childs.txt}, "visible", level >= currRoleLimitLevel)
		if level < currRoleLimitLevel then
			childs.cost:text(string.format(gLanguageCsv.equipAdvanceAddLevelCondition, currRoleLimitLevel))
			text.addEffect(childs.cost, {color = ui.COLORS.NORMAL.ALERT_ORANGE})
		else
			childs.cost:text(cost)
			text.addEffect(childs.cost, {color = gold >= cost and ui.COLORS.NORMAL.DEFAULT or ui.COLORS.NORMAL.ALERT_ORANGE})
			adapt.oneLinePos(childs.txt, {childs.cost, childs.icon})
			adapt.oneLineCenterPos(cc.p(self.btnUpgrade:x(), self.btnUpgrade:y() + 90), {childs.txt, childs.cost, childs.icon})
			childs.cost:visible(cost > 0)
			childs.icon:visible(cost > 0)
			childs.txt:visible(cost > 0)
		end
		self.isEnoughLevel = level >= currRoleLimitLevel
		self.isEnoughGoldAdvance = gold >= cost
	end
	self.attrDatas:update(t)
	self.strengthenPanel:visible(data.level < currLevelLimit)
	self.upgradePanel:visible(data.level >= currLevelLimit)
end

function CardEquipStrengthenView:onStrengthen()
	local cfg = csv.equips[self.data.equip_id]
	if not self.isEnoughGoldStrengthen then
		gGameUI:showTip(gLanguageCsv.strengthGoldNotEnough)
		return
	end
	self.shiningSpine:hide()
	gGameApp:requestServer("/game/equip/strength",function (tb)
		performWithDelay(self, function()
			self:playSpine(1, function ()
				self.shiningSpine:show()
			end)
			gGameUI:showTip(gLanguageCsv.strengthenSuccess)
			audio.playEffectWithWeekBGM("circle.mp3")
		end, 0.01)
	end, self.selectDbId, cfg.part, 1)
end

function CardEquipStrengthenView:playSpine(timeScale, callback)
	local spine = self.pos:get("effect")
	if spine then
		spine:setTimeScale(timeScale or 1)
		spine:play("fangguang2")
	else
		spine = widget.addAnimationByKey(self.pos, "koudai_gonghuixunlian/gonghuixunlian.skel", "effect", "fangguang2", 10000)
		spine:xy(self.pos:size().width/2, 0)
	end

	self.shiningSpine:hide()
	for k,v in self.attrDatas:ipairs() do
		v:proxy().playSpine = true
		performWithDelay(self, function()
			v:proxy().playSpine = false
		end, 0.2)
	end
	spine:setSpriteEventHandler(function(event, eventArgs)
		if callback then
			callback()
		end
	end, sp.EventType.ANIMATION_COMPLETE)
end
--快速升级
function CardEquipStrengthenView:onStrengthenFast()
	self.oldFight = self.fight:read()
	self.leftData = clone(self.data)
	gGameUI:stackUI("city.card.equip.fast_strengthen", nil, nil, self.selectDbId:read(), self.data.equip_id, self:createHandler("onSuccess"))
end

function CardEquipStrengthenView:onSuccess(isAdvance)
	self.shiningSpine:hide()
	self:playSpine(1, function ()
		self.shiningSpine:show()
	end)
	if isAdvance then
		idlereasy.do_(function (equips, index)
			gGameUI:stackUI("city.card.equip.success", nil, {blackLayer = true}, {
				leftItem = self.leftData,
				rightItem = clone(equips[index]),
				type = "quick",
				fight = self.oldFight,
				cardDbid = self.selectDbId:read()
			})
		end, self.equips, self.equipIndex)
	else
		gGameUI:showTip(gLanguageCsv.strengthenSuccess)
	end
end
function CardEquipStrengthenView:onStrengthenOne()
	local cfg = csv.equips[self.data.equip_id]
	if not self.isEnoughGoldStrengthen then
		gGameUI:showTip(gLanguageCsv.strengthGoldNotEnough)
		return
	end

	local originData = clone(self.data)
	local currLevel = self.data.level - 1
	local i = self.data.level - 1
	local targetLv = self.upLevel
	self.shiningSpine:hide()
	-- 取消遮罩，动画中可点击其他按钮
	-- 但strengthenPanel不可重复点击
	self.mask:hide()

	self.isOneKeyBegin = true
	gGameApp:requestServer("/game/equip/strength",function (tb)
		-- self.mask:show()
		self.isOneKeyPlaying = true
		self.strengthenPanel:setEnabled(false)
		self:schedule(function (dt)
			i = i + 1
			local newData = clone(originData)
			newData.level = i
			self:update(newData)
			self:playSpine(1)
			audio.playEffectWithWeekBGM("circle.mp3")
			if i == targetLv then
				self:onOneKeyPlayEnd()
			end
		end, 0.1, 0.01, "strength")
	end, self.selectDbId, cfg.part, targetLv, true)
end

function CardEquipStrengthenView:onOneKeyPlayEnd(isBreak)
	if not self.isOneKeyPlaying then return end

	gGameUI:showTip(gLanguageCsv.strengthenSuccess)
	self:unScheduleAll()

	self.isOneKeyPlaying = false
	self.isOneKeyBegin = false
	self.mask:hide()
	self.shiningSpine:visible(not isBreak)
	self.strengthenPanel:setEnabled(true)
end

function CardEquipStrengthenView:initModel()
	idlereasy.when(self.selectDbId,function (_, selectDbId)
		local card = gGameModel.cards:find(selectDbId)
		self.equips = idlereasy.assign(card:getIdler("equips"), self.equips)
		self.fight = idlereasy.assign(card:getIdler("fighting_point"), self.fight)
	end)
	self.gold = gGameModel.role:getIdler("gold")
	self.level = gGameModel.role:getIdler("level")
end

function CardEquipStrengthenView:onAdvance()
	if not self.isEnoughLevel then
		gGameUI:showTip(gLanguageCsv.currentLevelNotAvailable)
		return
	end
	if not self.isEnoughItem then
		gGameUI:showTip(gLanguageCsv.equipNotEnoughAdvanceItems)
		return
	end

	if not self.isEnoughGoldAdvance then
		gGameUI:showTip(gLanguageCsv.equipAdvanceGoldNotEnough)
		return
	end
	self.shiningSpine:hide()
	local fight = self.fight:read()
	local cfg = csv.equips[self.data.equip_id]
	local leftData = clone(self.data)

	local showOver = {false}
	gGameApp:requestServerCustom("/game/equip/advance")
		:params(self.selectDbId, cfg.part)
		:onResponse(function (tb)
			self:playSpine(1, function()
				self.shiningSpine:show()
				showOver[1] = true
			end)
		end)
		:wait(showOver)
		:doit(function (tb)
			idlereasy.do_(function (equips, index)
				gGameUI:stackUI("city.card.equip.success", nil, {blackLayer = true}, {
					leftItem = leftData,
					rightItem = equips[index],
					type = "advance",
					fight = fight,
					cardDbid = self.selectDbId:read()
				})
			end, self.equips, self.equipIndex)
		end)
end

return CardEquipStrengthenView