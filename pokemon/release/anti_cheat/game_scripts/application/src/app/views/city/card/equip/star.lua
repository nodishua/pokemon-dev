local CardEquipStarView = class("CardEquipStarView", cc.load("mvc").ViewBase)

local equipView = require "app.views.city.card.equip.view"
CardEquipStarView.RESOURCE_FILENAME = "card_equip_star.json"
CardEquipStarView.RESOURCE_BINDING = {
	["item"] = "item",
	["potentialItem"] = "potentialItem",
	["panel.starPanel.list"] = {
		varname = "starList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("attrDatas"),
				item = bindHelper.self("item"),
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
					adapt.oneLinePos(childs.name, {childs.left, childs.arrow, childs.right}, {cc.p(15, 0), cc.p(25, 0), cc.p(25, 0)}, "left")

				end,
			}
		},
	},
	["panel.potentialPanel.list"] = {
		varname = "potentialList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("attrPotentialDatas"),
				item = bindHelper.self("potentialItem"),
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
					adapt.oneLinePos(childs.name, {childs.left, childs.arrow, childs.right}, {cc.p(15, 0), cc.p(25, 0), cc.p(25, 0)}, "left")

				end,
			}
		},
	},
	["panel.starPanel"] = "starPanel",
	["panel.starPanel.none"] = "none",
	["panel.starPanel.arrow"] = "arrow",
	["panel.starPanel.leftStar"] = "leftStar",
	["panel.starPanel.rightStar"] = "rightStar",
	["panel.starPanel.name"] = "starName",

	["panel.potentialPanel"] = "potentialPanel",
	["panel.potentialPanel.name"] = "potentialName",
	["panel.potentialPanel.arrow"] = "potentialArrow",

	["panel.potentialPanel.talentLeftEffect"] = "talentLeftEffect",
	["panel.potentialPanel.talentRightEffect"] = "talentRightEffect",

	["panel.potentialPanel.arrow1"] = "effectArrow",
	["panel.potentialPanel.none"] = "potentialNone",
	["panel.potentialPanel.rightPotential"] = "rightPotential",
	["panel.potentialPanel.leftPotential"] = "leftPotential",
	["panel.bottomPanel"] = "bottomPanel",
	["panel.bottomPanel.itemPanel"] = "itemPanel",
	["panel.max"] = "max",
	["panel.potentialPanel.talentName"] = "talentName",
	["panel.potentialPanel.talentEffect"] = "talentEffect",
	["panel.potentialPanel.leftPotential.starNum"] = {
		varname = "leftStarNum",
		binds = {
			event = "effect",
			data = {outline = {color = cc.c3b(179,68,48),size = 2}}
		},
	},
	["panel.potentialPanel.rightPotential.starNum"] = {
		varname = "rightStarNum",
		binds = {
			event = "effect",
			data = {outline = {color = cc.c3b(179,68,48),size = 2}}
		},
	},
	["panel.btnStarPotential"] = {
		varname = "btnStarPotential",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("starPotential")}
		},
	},
	["panel.btnStarPotential.textNote"] = {
		binds = {
			event = "effect",
			data = {glow={color=ui.COLORS.GLOW.WHITE}},
		},
	},
	["panel.btnDown"] = {
		varname = "btnDown",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onDown")}
		},
	},
	["panel.bottomPanel.btnUpgrade"] = {
		varname = "btnUpgrade",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onUp")}
		},
	},
	["panel.bottomPanel.btnUpgrade.textNote"] = {
		binds = {
			event = "effect",
			data = {glow={color=ui.COLORS.GLOW.WHITE}},
		},
	},
	["panel.bottomPanel.btnUpgradeAfter"] = {
		varname = "btnUpgradePotential",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onUpgradePotential")}
		},
	},
	["panel.bottomPanel.btnUpgradeAfter.textNote"] = {
		binds = {
			event = "effect",
			data = {glow={color=ui.COLORS.GLOW.WHITE}},
		},
	},
	["panel.bottomPanel.btnUpgradeAfterFast"] = {
		varname = "btnUpgradePotentialFast",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onUpgradePotentialFast")}
		},
	},
	["panel.bottomPanel.icon"] = {
		varname = "icon",
		binds = {
			event = "visible",
			idler = bindHelper.self("isShowGold")
		},
	},
	["panel.bottomPanel.txt"] = {
		varname = "txt",
		binds = {
			event = "visible",
			idler = bindHelper.self("isShowGold")
		},
	},
	["panel.bottomPanel.cost"] = {
		varname = "cost",
		binds = {
			event = "visible",
			idler = bindHelper.self("isShowGold")
		},
	},
	["panel.pos"] = "pos",
}

function CardEquipStarView:onCreate(dbHandler)

	self.panel = panel
	self.selectDbId, self.equipIndex = dbHandler()
	self:initModel()
	self.spine = widget.addAnimation(self.pos, "effect/shipinfaguang.skel", "effect_loop", 20):scale(0.75)
	 	:xy(-55, 50)
	self.attrDatas = idlertable.new({})
	self.attrPotentialDatas = idlertable.new({})
	self.originX = self.btnDown:x()
	self.isShowGold = idler.new(true)
	self.startPotentialFastUnlock = dataEasy.getListenUnlock(gUnlockCsv.starPotentialFast)
	idlereasy.any({self.equips, self.equipIndex, self.gold, self.startPotentialFastUnlock}, function (_, equips, index, gold, startPotentialFastUnlock)
		local data = equips[index]
		local cfg = csv.equips[data.equip_id]
		self.data = data
		self.starNum = data.star
		self.none:visible(data.star == 0)
		self.arrow:visible(data.star ~= cfg.starMax)
		if data.star ~= 0 then
			self:setStar(self.leftStar, data.star)
		end
		self.leftStar:visible(data.star ~= 0 and data.ability == 0)
		self.rightStar:visible(data.star ~= cfg.starMax and data.ability == 0)
		if data.star < cfg.starMax then
			self:setStar(self.rightStar, data.star + 1)
		end
		adapt.oneLinePos(self.starName, {self.none, self.leftStar, self.arrow, self.rightStar}, {cc.p(10, 0), cc.p(25, 0), cc.p(25, 0), cc.p(25, 0)}, "left")
		self.ability = data.ability or 0
		self.potentialNone:visible(false)
		self.potentialArrow:visible(self.ability ~= cfg.abilityMax and self.ability > 0 and data.star == cfg.starMax)
		if self.ability ~= 0 then
			self.talentLeftEffect:text("+"..cfg.abilityAttr[self.ability])
			self.leftStarNum:text(self.ability)
			end
		if self.ability > 0 and self.ability < cfg.abilityMax and data.star == cfg.starMax then
			self.talentRightEffect:text("+"..cfg.abilityAttr[self.ability + 1])
			self.rightStarNum:text(self.ability + 1)
		end
		self.isShowGold:set(not data.star == cfg.starMax)
		if self.ability >= 0 and self.starNum == cfg.starMax then
			for key,v in csvMapPairs(csv.base_attribute.equip_ability[self.ability]["costItemMap"..cfg.abilitySeqID]) do
				if key ~= "gold" then
					local hasNum = dataEasy.getNumByKey(key)
					self.itemPanel:get("btnAdd"):visible(hasNum < v)
					bind.extend(self, self.itemPanel, {
						class = "icon_key",
						props = {
							data = {
								key = key,
								num = hasNum,
								targetNum = v,
							},
							grayState = hasNum < v and 1 or 0,
							onNode = function (panel)
								bind.click(self, panel, {method = function()
									jumpEasy.jumpTo("gainWay", key, nil, v)
								end})
							end
						},
					})
					self.isEnoughItems = hasNum >= v
					self.btnUpgradePotential:xy(250,160)
					if startPotentialFastUnlock then
						self.btnUpgradePotential:xy(250 - 290,160)
						self.btnUpgradePotentialFast:xy(250 + 290,160)
					end
				else
					self.isShowGold:set(v > 0)
					self.cost:text(v)
					self.isEnoughGold = gold >= v
					text.addEffect(self.cost, {color = gold >= v and ui.COLORS.NORMAL.DEFAULT or ui.COLORS.NORMAL.ALERT_ORANGE})
					self.btnUpgradePotential:xy(239,95)
					if startPotentialFastUnlock then
						self.btnUpgradePotential:xy(239 - 290, 95)
						self.btnUpgradePotentialFast:xy(239 + 290, 95)
					end
					adapt.oneLineCenterPos(cc.p(self.btnUpgradePotential:x(), self.btnUpgradePotential:y() + 90), {self.txt, self.cost, self.icon})
				end
			end
		else
			for key,v in csvMapPairs(csv.base_attribute.equip_star[data.star]["costItemMap"..cfg.starSeqID]) do
				if key ~= "gold" then
					local hasNum = dataEasy.getNumByKey(key)
					self.itemPanel:get("btnAdd"):visible(hasNum < v)
					bind.extend(self, self.itemPanel, {
						class = "icon_key",
						props = {
							data = {
								key = key,
								num = hasNum,
								targetNum = v,
							},
							grayState = hasNum < v and 1 or 0,
							onNode = function (panel)
								bind.click(self, panel, {method = function()
									jumpEasy.jumpTo("gainWay", key, nil, v)
								end})
							end
						},
					})
					self.isEnoughItems = hasNum >= v
				else
					self.isShowGold:set(v > 0)
					self.cost:text(v)
					self.isEnoughGold = gold >= v
					text.addEffect(self.cost, {color = gold >= v and ui.COLORS.NORMAL.DEFAULT or ui.COLORS.NORMAL.ALERT_ORANGE})
					adapt.oneLineCenterPos(cc.p(self.btnUpgrade:x(), self.btnUpgrade:y() + 90), {self.txt, self.cost, self.icon})
				end
			end
		end
		self.btnUpgrade:visible(data.star ~= cfg.starMax)
		self.bottomPanel:visible(data.star ~= cfg.starMax or (data.star == cfg.starMax and data.ability > 0))

		self.max:visible(data.star == cfg.starMax and data.ability == 0)
		self.btnStarPotential:visible(dataEasy.isShow(gUnlockCsv.equipAbility) and data.star == cfg.starMax and data.ability == 0)
		self.starPanel:visible(data.star <= cfg.starMax and data.ability == 0)
		self.starList:visible(data.star <= cfg.starMax and data.ability == 0)

		self.potentialList:visible(data.star == cfg.starMax)
		self.btnUpgradePotential:visible(data.ability > 0)
		self.btnUpgradePotentialFast:visible(data.ability > 0 and startPotentialFastUnlock)
		self.potentialPanel:visible(self.ability > 0)

		self.leftPotential:visible(data.ability ~= 0)
		self.rightPotential:visible(data.ability ~= cfg.abilityMax and data.star == cfg.starMax )
		self.talentRightEffect:visible(data.ability ~= cfg.abilityMax and data.star == cfg.starMax )
		self.effectArrow:visible(data.ability ~= cfg.abilityMax and data.star == cfg.starMax)

		uiEasy.setBtnShader(self.btnUpgradePotential, nil, data.ability ~= cfg.abilityMax and 1 or 3)
		if data.ability == cfg.abilityMax then
			self.btnUpgradePotentialFast:loadTextureNormal("common/btn/btn_normal.png")
			self.btnUpgradePotentialFast:get("textNote"):setTextColor(ui.COLORS.NORMAL.WHITE)
			self.btnUpgradePotentialFast:get("textNote"):enableGlow(ui.COLORS.GLOW.WHITE)
			uiEasy.setBtnShader(self.btnUpgradePotentialFast, nil, 3)
		else
			self.btnUpgradePotentialFast:loadTextureNormal("common/btn/btn_recharge.png")
			self.btnUpgradePotentialFast:get("textNote"):disableEffect()
			self.btnUpgradePotentialFast:get("textNote"):setTextColor(ui.COLORS.NORMAL.RED)
			uiEasy.setBtnShader(self.btnUpgradePotentialFast, nil, 1)
		end

		adapt.oneLinePos(self.potentialName, {self.leftPotential, self.potentialArrow,self.rightPotential}, {cc.p(5, 0), cc.p(25, 0), cc.p(25, 0)}, "left")
		if matchLanguage({"kr"}) then
			adapt.oneLinePos(self.talentName, {self.talentLeftEffect, self.effectArrow,self.talentRightEffect}, {cc.p(0, 0), cc.p(15, 0), cc.p(15, 0)}, "left")
		else
			adapt.oneLinePos(self.talentName, {self.talentLeftEffect, self.effectArrow,self.talentRightEffect}, {cc.p(0, 0), cc.p(25, 0), cc.p(25, 0)}, "left")
		end
		local t = {}
		for i=1,math.huge do
			local attr, currVal, nextVal = equipView.getAttrNum(data, i, "star")  --   self:getAttrNum(data, i)
			if attr == 0 then
				break
			end
			table.insert(t, {attr = attr, currVal = currVal, nextVal = nextVal})
		end
		self.attrDatas:set(t)
		local ability = {}
		for i=1,math.huge do
			local attr, currVal, nextVal = equipView.getAttrNum(data, i, "ability")  --   self:getAttrNum(data, i)
			if attr == 0 then
				break
			end
			table.insert(ability, {attr = attr, currVal = currVal, nextVal = nextVal})
		end
		self.attrPotentialDatas:set(ability)
		if data.star > 0 then
			self.btnDown:texture("city/card/equip/icon_star_down2.png")
		else
			self.btnDown:texture("city/card/equip/icon_star_down1.png")
		end
		self.btnDown:x((data.star ~= cfg.starMax or (data.star == cfg.starMax and data.ability > 0)) and self.originX - 150 or self.originX)
	end)
end

function CardEquipStarView:setStar(panel, star)
	panel:removeAllChildren()
	for i=1,star do
		ccui.ImageView:create("city/card/equip/icon_star.png")
			:anchorPoint(cc.p(0, 0.5))
			:xy((i - 1) * 32, 25)
			:addTo(panel, 4, "star")
			:scale(1)
	end
	panel:size(cc.size(star * 32 + 15, 53))
end

function CardEquipStarView:initModel()
	idlereasy.when(self.selectDbId,function (_, selectDbId)
		local card = gGameModel.cards:find(selectDbId)
		self.equips = idlereasy.assign(card:getIdler("equips"), self.equips)
		self.fight = idlereasy.assign(card:getIdler("fighting_point"), self.fight)
	end)
	self.gold = gGameModel.role:getIdler("gold")
	self.rmb = gGameModel.role:getIdler("rmb")
	self.level = gGameModel.role:getIdler("level")
end

function CardEquipStarView:onUp()
	local cfg = csv.equips[self.data.equip_id]
	local leftData = clone(self.data)
	if not self.isEnoughItems then
		gGameUI:showTip(gLanguageCsv.equipNotEnoughStarItems)
		return
	end
	if not self.isEnoughGold then
		gGameUI:showTip(gLanguageCsv.cardStarGoldNotEnough)
		return
	end
	local fight = self.fight:read()
	local showOver = {false}
	gGameApp:requestServerCustom("/game/equip/star")
		:params(self.selectDbId, cfg.part)
		:onResponse(function (tb)
			idlereasy.do_(function (equips, index)
				audio.playEffectWithWeekBGM("circle.mp3")
				self:playSpine(1, function()
					gGameUI:stackUI("city.card.equip.success", nil, {blackLayer = true}, {
						leftItem = leftData,
						rightItem = equips[index],
						type = "star",
						fight = fight,
						cardDbid = self.selectDbId:read()
					})
					showOver[1] = true
				end, 1)
			end, self.equips, self.equipIndex)
			end)
		:wait(showOver)
		:doit()
end

function CardEquipStarView:onDown()
	local starNum = self.data.star
	local abilityNum = self.data.ability
	if starNum <= 0 then
		gGameUI:showTip(gLanguageCsv.currentStarCannotReduced)
		return
	end
	local cfg = csv.equips[self.data.equip_id]
	local costCfg = gCostCsv.equip_drop_cost
	local costRmb = 0

	local strs1 = {}
	local award = {}
	if abilityNum > 0 then
		local cfg = csv.equips[self.data.equip_id]
		local idx1 = math.min(abilityNum + cfg.starMax, table.length(costCfg))
		costRmb = costCfg[idx1]
		strs1 = {
			string.format(gLanguageCsv.equipStarDownCost, costRmb),
			string.format(gLanguageCsv.equipStarDownReturn, gLanguageCsv.starUp)
		}
		for i=0,abilityNum-1 do
			for k,v in csvMapPairs(csv.base_attribute.equip_ability[i]["costItemMap"..cfg.abilitySeqID]) do
				-- if k ~= "gold" then
				if not award[k] then
					award[k] = 0
				end
				award[k] = award[k] + v
				-- end
			end
		end
	else
		costRmb = costCfg[starNum]
		strs1 = {
			string.format(gLanguageCsv.equipStarDownCost, costRmb),
			string.format(gLanguageCsv.equipStarDownReturn, gLanguageCsv.starUp)
		}
	end
	gGameUI:showDialog({
		strs = strs1,
		align = "left",
		isRich = true,
		cb = function ()
			if costRmb > self.rmb:read() then
				gGameUI:showTip(gLanguageCsv.dropEquipStarRmbUp)
				return
			end
			gGameApp:requestServer("/game/equip/star/drop",function (tb)
				for i=0,starNum-1 do
					for k,v in csvMapPairs(csv.base_attribute.equip_star[i]["costItemMap"..cfg.starSeqID]) do
						-- if k ~= "gold" then
						if not award[k] then
							award[k] = 0
						end
						award[k] = award[k] + v
						-- end
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

function CardEquipStarView:playSpine(timeScale, callback, type)
	local list= {}
	if type == 1 then
		list = self.starList:getChildren()
	elseif type == 2 then
		list = self.potentialList:getChildren()
	end
	for _, child in pairs(list) do
		local spine = child:get("spine")
		if not spine then
			spine = widget.addAnimationByKey(child, "effect/shuzisaoguang.skel", "spine", "effect", 122)
				:xy(child:get("arrow"):x() - 40, child:size().height/2 + 5)
				:scale(0.5)
		else
			spine:play("effect")
		end
	end

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
--星级潜能
function CardEquipStarView:starPotential()
	local cfg = csv.equips[self.data.equip_id]
	if not dataEasy.isUnlock(gUnlockCsv.equipAbility) then
		gGameUI:showTip(dataEasy.getUnlockTip(gUnlockCsv.equipAbility))
		return
	end
	self.max:visible(false)
	self.starPanel:visible(false)
	self.potentialPanel:visible(true)
	self.btnStarPotential:visible(false)
	self.bottomPanel:visible(true)
	self.btnUpgradePotential:visible(true)
	self.btnUpgradePotentialFast:visible(dataEasy.isUnlock(gUnlockCsv.starPotentialFast))
	self:playSpine(1,nil)
	self.rightStarNum:text(1)
	self.potentialNone:visible(true)
	self.potentialArrow:visible(true)
	self.effectArrow:visible(true)
	self.talentLeftEffect:text("+0%")
	self.talentRightEffect:text("+"..cfg.abilityAttr[self.ability + 1])
	adapt.oneLinePos(self.itemPanel,self.btnDown,cc.p(331,0))
	adapt.oneLinePos(self.potentialName, {self.potentialNone, self.potentialArrow,self.rightPotential}, {cc.p(5, 0), cc.p(25, 0), cc.p(25, 0)}, "left")
	adapt.oneLinePos(self.talentName, {self.talentLeftEffect, self.effectArrow,self.talentRightEffect}, {cc.p(0, 0), cc.p(25, 0), cc.p(25, 0)}, "left")
	self.btnUpgradePotential:xy(239,95)
	if dataEasy.isUnlock(gUnlockCsv.starPotentialFast) then
		self.btnUpgradePotential:xy(239 - 290, 95)
		self.btnUpgradePotentialFast:xy(239 + 290, 95)
	end
	if self.isShowGold:read() then
		adapt.oneLineCenterPos(cc.p(self.btnUpgradePotential:x(), self.btnUpgradePotential:y() + 90), {self.txt, self.cost, self.icon})
	end
end


function CardEquipStarView:onUpgradePotential()
	local cfg = csv.equips[self.data.equip_id]
	if self.ability == cfg.abilityMax then
		gGameUI:showTip(gLanguageCsv.abilityMax)
			return false
	end
	if not self.isEnoughItems then
		gGameUI:showTip(gLanguageCsv.equipNotEnoughStarItems)
		return
	end
	if not self.isEnoughGold then
		gGameUI:showTip(gLanguageCsv.cardStarGoldNotEnough)
		return
	end
	local fight = self.fight:read()
	local showOver = {false}
	gGameApp:requestServerCustom("/game/equip/ability")
	:params(self.selectDbId, cfg.part)
	:onResponse(function (tb)
		idlereasy.do_(function (equips, index)
			audio.playEffectWithWeekBGM("circle.mp3")
			self:playSpine(1, function()
				showOver[1] = true
			end, 2)
		end, self.equips, self.equipIndex)
		end)
	:wait(showOver)
	:doit()
end

--一键升星
function CardEquipStarView:onUpgradePotentialFast()
	local cfg = csv.equips[self.data.equip_id]
	if self.ability == cfg.abilityMax then
		gGameUI:showTip(gLanguageCsv.abilityMax)
			return false
	end
	if not self.isEnoughItems then
		gGameUI:showTip(gLanguageCsv.equipNotEnoughStarItems)
		return
	end
	if not self.isEnoughGold then
		gGameUI:showTip(gLanguageCsv.cardStarGoldNotEnough)
		return
	end
	gGameUI:stackUI("city.card.equip.fast_star", nil, nil, self.selectDbId:read(), self.data.equip_id, self:createHandler("playSpine", 1, nil, 2))
end

return CardEquipStarView