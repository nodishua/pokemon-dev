local equipView = require "app.views.city.card.equip.view"
local CardEquipAwakeView = class("CardEquipAwakeView", cc.load("mvc").ViewBase)
local COLOR = {
	cc.c4b(91, 84, 91, 255),--"#C0x5B545B#",
	cc.c4b(92, 153, 112, 255),--"#C0x5C9970#",
	cc.c4b(61, 138, 153, 255),--"#C0x3D8A99#",
	cc.c4b(138, 92, 153, 255),--"#C0x8A5C99#",
	cc.c4b(230, 153, 0, 255),--"#C0xE69900#",
	cc.c4b(230, 116, 34, 255),--"#C0xE67422#",
}
CardEquipAwakeView.RESOURCE_FILENAME = "card_equip_awake.json"
CardEquipAwakeView.RESOURCE_BINDING = {
	["panel.max"] = "max",
	["panel.btnDown"] = {
		varname = "btnDown",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onDown")}
		},
	},
	["panel.bottomPanel"] = "bottomPanel",
	["panel.bottomPanel.itemPanel"] = "itemPanel",
	["panel.bottomPanel.cost"] = "cost",
	["panel.bottomPanel.icon"] = "icon",
	["panel.bottomPanel.txt"] = "txt",
	["panel.bottomPanel.btnAwake"] = {
		varname = "btnAwake",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onAwake")}

		},
	},
	["panel.bottomPanel.btnAwake.textNote"] = {
		binds = {
			event = "effect",
			data = {glow={color=ui.COLORS.GLOW.WHITE}},
		},
	},
	["panel.bottomPanel.btnAwakeFast"] = {
		varname = "btnAwakeFast",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onAwakeAbilityFast")}
		},
	},

	["panel.pos"] = "pos",
	["item"] = "item",
	["panel.list"] = {
		varname = "list",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("showTexts"),
				item = bindHelper.self("item"),
				onItem = function(list, node, k, v)
					local childs = node:multiget(
						"name",
						"left",
						"right",
						"arrow"
					)
					childs.name:text(v.name..":")
					childs.left:text("+"..v.num)
					childs.right:text("+"..v.nextNum):visible(not v.isMax)
					childs.arrow:visible(not v.isMax)
					if matchLanguage({"kr"}) then
						adapt.oneLinePos(childs.name, {childs.left, childs.arrow, childs.right}, cc.p(10,0))
					elseif v.type == "ability" then
						adapt.oneLinePos(childs.name, {childs.left, childs.arrow, childs.right}, {cc.p(5, 0), cc.p(20, 0), cc.p(20, 0)}, "left")
					else
						adapt.oneLinePos(childs.name, {childs.left, childs.arrow, childs.right}, cc.p(30,0))
					end
				end,
			}
		},
	},
	["panel.namePanel"] = "namePanel",
	---------------------------awakeAbility-------------------------------------
	["panel.btnAwakeAbility"] = {
		varname = "btnAwakeAbility",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onAwakeAbility")}
		},
	},
	["panel.btnAwakeAbility.txt"] = {
		binds = {
			event = "effect",
			data = {glow={color=ui.COLORS.GLOW.WHITE}},
		},
	},
	["panel.abilityNamePanel"] = "abilityNamePanel",
	["panel.abilityNamePanel.name1"] = "abilityLeft",
	["panel.abilityNamePanel.name2"] = "abilityRight",
	["panel.abilityNamePanel.arrow"] = "abilityArrow",

	["panel.namePanel"] = "namePanel",

}

function CardEquipAwakeView:onCreate(dbHandler)
	self.selectDbId, self.equipIndex = dbHandler()
	self:initModel()
	self.spine = widget.addAnimation(self.pos, "effect/shipinfaguang.skel", "effect_loop", 20):scale(0.75)
	 	:xy(-55, 50)
	self.showTexts = idlers.newWithMap({})
	idlereasy.any({self.equips, self.equipIndex,self.gold, self.awakeAbilityFastUnlock}, function (_, equips, index,gold, awakeAbilityFastUnlock)
		local data = equips[index]
		local cfg = csv.equips[data.equip_id]
		self.data = data
		local str1 = gLanguageCsv.equipAwakeDetail
		local t = {}
		local awake = data.awake or 0
		local nextAwake = awake >= cfg.awakeMax and cfg.awakeMax or awake + 1

		local ability = data.awake_ability or 0
		local nextAbility = ability >= cfg.awakeAbilityMax and cfg.awakeAbilityMax or ability + 1
		--潜能
		if ability > 0 and awake == cfg.awakeMax and dataEasy.isUnlock(gUnlockCsv.equipAwakeAbility) then
			self.abilityNamePanel:visible(true)
			self.namePanel:visible(false)
			local childs = self.abilityNamePanel:multiget(
				"name1",
				"name2",
				"arrow"
			)
			childs.name1:text("+"..ability)
			childs.name2:text("+"..nextAbility):visible(ability < cfg.awakeAbilityMax)
			childs.arrow:visible(ability < cfg.awakeAbilityMax)
			adapt.oneLinePos(childs.name1, {childs.arrow, childs.name2}, cc.p(30,0))
			local awakwAbility = {}
			for i=1,math.huge do
				local awakAttr = cfg["awakeAbilityAttrType" .. i]
				if not awakAttr or awakAttr == 0 then
					break
				end
				local attrTypeStr = game.ATTRDEF_TABLE[awakAttr]
				local str = "attr" .. string.caption(attrTypeStr)
				local num, nextNum = dataEasy.getAttrValueAndNextValue(awakAttr, cfg["awakeAbilityAttrNum"..i][ability] or 0, cfg["awakeAbilityAttrNum"..i][nextAbility])
				table.insert(awakwAbility, {name = gLanguageCsv[str], num = num, nextNum = nextNum,isMax = ability >= cfg.awakeAbilityMax,type = "ability"})
			end
			self.showTexts:update(awakwAbility)
			itertools.invoke({self.cost, self.icon, self.txt}, "hide")
			for key,v in csvMapPairs(csv.base_attribute.equip_awake_ability[ability]["costItemMap"..cfg.awakeAbilitySeqID]) do
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
				elseif v > 0 then
					self.cost:text(v)
					self.cost:show()
					self.icon:show()
					self.txt:show()
					self.isEnoughGold = gold >= v
					text.addEffect(self.cost, {color = gold >= v and ui.COLORS.NORMAL.DEFAULT or ui.COLORS.NORMAL.ALERT_ORANGE})
				end
			end
		elseif ability == 0 and awake == cfg.awakeMax and dataEasy.isUnlock(gUnlockCsv.equipAwakeAbility) then
			self.abilityNamePanel:visible(false)
			self.namePanel:visible(true)
			local childs = self.namePanel:multiget(
				"name1",
				"name2",
				"arrow"
			)
			local name1 = (gLanguageCsv["symbolRome"..awake] or "")
			local name2 = gLanguageCsv["symbolRome"..nextAwake]
			if awake == 0 then
				name1 = gLanguageCsv.notAwake
			end
			childs.name1:text(name1)
			childs.name2:text(name2):visible(awake < cfg.awakeMax)
			childs.arrow:visible(awake < cfg.awakeMax)
			adapt.oneLinePos(childs.name1, {childs.arrow, childs.name2}, cc.p(30,0))
			for i=1,math.huge do
				local awakAttr = cfg["awakeAttrType" .. i]
				if not awakAttr or awakAttr == 0 then
					break
				end
				local attrTypeStr = game.ATTRDEF_TABLE[awakAttr]
				local str = "attr" .. string.caption(attrTypeStr)
				local num, nextNum = dataEasy.getAttrValueAndNextValue(awakAttr, cfg["awakeAttrNum"..i][awake] or 0, cfg["awakeAttrNum"..i][nextAwake])
				table.insert(t, {
					name = gLanguageCsv[str],
					num = num,
					nextNum = nextNum,
					isMax = awake >= cfg.awakeMax,
					type = "awake",
				})
			end
			self.showTexts:update(t)
			itertools.invoke({self.cost, self.icon, self.txt}, "hide")
			for key,v in csvMapPairs(csv.base_attribute.equip_awake_ability[ability]["costItemMap"..cfg.awakeAbilitySeqID]) do
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
				elseif v > 0 then
					self.cost:text(v)
					self.cost:show()
					self.icon:show()
					self.txt:show()
					self.isEnoughGold = gold >= v
					text.addEffect(self.cost, {color = gold >= v and ui.COLORS.NORMAL.DEFAULT or ui.COLORS.NORMAL.ALERT_ORANGE})
				end
			end
		--觉醒
		else
			self.abilityNamePanel:visible(false)
			self.namePanel:visible(true)
			local childs = self.namePanel:multiget(
				"name1",
				"name2",
				"arrow"
			)
			local name1 = (gLanguageCsv["symbolRome"..awake] or "")
			local name2 = gLanguageCsv["symbolRome"..nextAwake]
			if awake == 0 then
				name1 = gLanguageCsv.notAwake
			end
			childs.name1:text(name1)
			childs.name2:text(name2):visible(awake < cfg.awakeMax)
			childs.arrow:visible(awake < cfg.awakeMax)
			adapt.oneLinePos(childs.name1, {childs.arrow, childs.name2}, cc.p(30,0))
			for i=1,math.huge do
				local awakAttr = cfg["awakeAttrType" .. i]
				if not awakAttr or awakAttr == 0 then
					break
				end
				local attrTypeStr = game.ATTRDEF_TABLE[awakAttr]
				local str = "attr" .. string.caption(attrTypeStr)
				local num, nextNum = dataEasy.getAttrValueAndNextValue(awakAttr, cfg["awakeAttrNum"..i][awake] or 0, cfg["awakeAttrNum"..i][nextAwake])
				table.insert(t, {
					name = gLanguageCsv[str],
					num = num,
					nextNum = nextNum,
					isMax = awake >= cfg.awakeMax,
					type = "awake",
				})
			end
			self.showTexts:update(t)

			itertools.invoke({self.cost, self.icon, self.txt}, "hide")
			for key,v in csvMapPairs(csv.base_attribute.equip_awake[awake]["costItemMap"..cfg.awakeSeqID]) do
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
				elseif v > 0 then
					self.cost:text(v)
					self.cost:show()
					self.icon:show()
					self.txt:show()
				end
			end
		end
		self.btnAwakeAbility:visible(dataEasy.isShow(gUnlockCsv.equipAwakeAbility) and ability == 0 and awake == cfg.awakeMax)
		self.bottomPanel:visible(awake ~= cfg.awakeMax or ability > 0 )
		self.max:visible(awake == cfg.awakeMax and ability == 0)
		uiEasy.setBtnShader(self.btnAwake, nil, ability ~= cfg.awakeAbilityMax and 1 or 3)
		if awakeAbilityFastUnlock and (dataEasy.isShow(gUnlockCsv.equipAwakeAbility) and ability >= 0 and awake == cfg.awakeMax) then
			self.btnAwake:x(238 - 290)
			self.btnAwakeFast:x(238 + 290)
				:show()
			if ability == cfg.awakeAbilityMax then
				self.btnAwakeFast:loadTextureNormal("common/btn/btn_normal.png")
				self.btnAwakeFast:get("textNote"):setTextColor(ui.COLORS.NORMAL.WHITE)
				self.btnAwakeFast:get("textNote"):enableGlow(ui.COLORS.GLOW.WHITE)
				uiEasy.setBtnShader(self.btnAwakeFast, nil, 3)
			else
				self.btnAwakeFast:loadTextureNormal("common/btn/btn_recharge.png")
				self.btnAwakeFast:get("textNote"):disableEffect()
				self.btnAwakeFast:get("textNote"):setTextColor(ui.COLORS.NORMAL.RED)
				uiEasy.setBtnShader(self.btnAwakeFast, nil, 1)
			end
		else
			self.btnAwake:x(238)
			self.btnAwakeFast:hide()
		end
		if data.star < cfg.awakeStar[awake + 1] then
			--需要饰品两星
			self.cost:show()
			self.icon:hide()
			self.txt:hide()
			self.cost:text(string.format(gLanguageCsv.needEquipStar, cfg.awakeStar[awake + 1]))
			text.addEffect(self.cost, {color = ui.COLORS.NORMAL.ALERT_ORANGE})
		end
		if awake > 0 or ability> 0 then
			self.btnDown:texture("city/card/equip/icon_jj.png")
		else
			self.btnDown:texture("city/card/equip/icon_jj_h.png")
		end
		self.btnDown:x(awake == cfg.awakeMax and ability == 0 and (self.max:x() + 327) or (self.max:x() + 177))
	end)
end

function CardEquipAwakeView:initModel()
	idlereasy.when(self.selectDbId,function (_, selectDbId)
		local card = gGameModel.cards:find(selectDbId)
		self.equips = idlereasy.assign(card:getIdler("equips"), self.equips)
		self.fight = idlereasy.assign(card:getIdler("fighting_point"), self.fight)
	end)
	self.level = gGameModel.role:getIdler("level")
	self.gold = gGameModel.role:getIdler("gold")
	self.rmb = gGameModel.role:getIdler("rmb")
	self.awakeAbilityFastUnlock = dataEasy.getListenUnlock(gUnlockCsv.awakePotentialFast)
end

function CardEquipAwakeView:onAwake()
	local fight = self.fight:read()
	local data = clone(self.data)
	local cfg = csv.equips[data.equip_id]
	local awake = data.awake or 0
	local awakeAbility = data.awake_ability or 0
	local currLevelLimit = cfg.awakeRoleLevelMax[awake + 1]
	if self.level:read() < currLevelLimit then
		gGameUI:showTip(gLanguageCsv.currentLevelNotAvailable)
		return
	end

	if data.star < cfg.awakeStar[awake + 1] then
		gGameUI:showTip(gLanguageCsv.equipNotEnoughStar)
		return
	end

	local showOver = {false}
	--潜能
	if awakeAbility >= 0 and awake == cfg.awakeMax and dataEasy.isUnlock(gUnlockCsv.equipAwakeAbility) then
		if awakeAbility == cfg.awakeAbilityMax then
			gGameUI:showTip(gLanguageCsv.awakeAbilityMax)
			return false
		end
		if self.isEnoughItems == false then
			gGameUI:showTip(gLanguageCsv.equipNotEnoughAwakeItems)
			return
		end
		if self.isEnoughGold == false then
			gGameUI:showTip(gLanguageCsv.goldNotEnough)
			return
		end
		gGameApp:requestServerCustom("/game/equip/awake/ability")
		:params(self.selectDbId, cfg.part)
		:onResponse(function (tb)
			idlereasy.do_(function (equips, index)
				self:playSpine(1, function()
					showOver[1] = true
				end)
			end, self.equips, self.equipIndex)
			end)
		:wait(showOver)
		:doit()
	--觉醒
	else
		local key, value = csvNext(csv.base_attribute.equip_awake[awake]["costItemMap"..cfg.awakeSeqID])
		local hasNum = dataEasy.getNumByKey(key)
		if hasNum < value then
			gGameUI:showTip(gLanguageCsv.equipNotEnoughAwakeItems)
			return
		end
		gGameApp:requestServerCustom("/game/equip/awake")
		:params(self.selectDbId, cfg.part)
		:onResponse(function (tb)
			idlereasy.do_(function (equips, index)
				self:playSpine(1, function()
					gGameUI:stackUI("city.card.equip.success", nil, {blackLayer = true}, {
						leftItem = data,
						rightItem = equips[index],
						type = "awake",
						fight = fight,
						cardDbid = self.selectDbId:read()
					})
					showOver[1] = true
				end)
			end, self.equips, self.equipIndex)
			end)
		:wait(showOver)
		:doit()
	end

end

function CardEquipAwakeView:onDown()
	local awakeNum = self.data.awake
	local awakeAbilityNum = self.data.awake_ability or 0
	if awakeNum <= 0 and awakeAbilityNum <= 0 then
		gGameUI:showTip(gLanguageCsv.currentAwakeCannotReduced)
		return
	end

	local cfg = csv.equips[self.data.equip_id]
	local costCfg = gCostCsv.equip_drop_cost
	local idx1 = math.min(awakeNum, table.length(costCfg))
	local costRmb = 0
	local strs = {}
	local award = {}
	local btnType = 1
	if awakeAbilityNum > 0 then
		local cfg = csv.equips[self.data.equip_id]
		local idx1 = math.min(cfg.awakeMax + awakeAbilityNum, table.length(costCfg))
		costRmb = costCfg[idx1]
		btnType = 2
		strs = {
			string.format(gLanguageCsv.equipAwakeAbilityDownCost,costRmb)
		}
		for i=0,awakeAbilityNum-1 do
			for k,v in csvMapPairs(csv.base_attribute.equip_awake_ability[i]["costItemMap"..cfg.awakeAbilitySeqID]) do
				-- if k ~= "gold" then
				if not award[k] then
					award[k] = 0
				end
				award[k] = award[k] + v
				-- end
			end
		end
	else
		costRmb = costCfg[awakeNum]
		strs = {
			string.format(gLanguageCsv.equipStarDownCost,costRmb),
			string.format(gLanguageCsv.equipStarDownReturn, gLanguageCsv.awake)
		}
	end
	gGameUI:showDialog({
		strs = strs,
		align = "left",
		isRich = true,
		cb = function ()
			if costRmb > self.rmb:read() then
				gGameUI:showTip(gLanguageCsv.rmbNotEnough)
				return
			end
			gGameApp:requestServer("/game/equip/awake/drop",function (tb)
				for i=0,awakeNum-1 do
					for k,v in csvMapPairs(csv.base_attribute.equip_awake[i]["costItemMap"..cfg.awakeSeqID]) do
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
		btnType = btnType,
		clearFast = true,
		dialogParams = {clickClose = false},
	})
end
function CardEquipAwakeView:playSpine(timeScale, callback)
	for _, child in pairs(self.list:getChildren()) do
		local spine = child:get("spine")
		if not spine then
			spine = widget.addAnimationByKey(child, "effect/shuzisaoguang.skel", "spine", "effect", 122)
				:xy(child:get("arrow"):x() - 40, child:size().height/2 + 5)
				:scale(0.5)
		else
			spine:xy(child:get("arrow"):x() - 40, child:size().height/2 + 5)
				:play("effect")
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

--觉醒潜能
function CardEquipAwakeView:onAwakeAbility()
	local data = clone(self.data)
	local cfg = csv.equips[data.equip_id]
	local awakeAbility = data.awake_ability or 0
	if not dataEasy.isUnlock(gUnlockCsv.equipAwakeAbility) then
		gGameUI:showTip(dataEasy.getUnlockTip(gUnlockCsv.equipAwakeAbility))
		return
	end
	self.btnAwakeAbility:visible(false)
	self:playSpine(1,nil)
	self.max:visible(false)
	self.abilityNamePanel:visible(true)
	self.namePanel:visible(false)
	self.abilityLeft:text("+"..awakeAbility)
	self.abilityRight:text("+"..awakeAbility + 1)
	self.bottomPanel:visible(true)
	self.btnDown:x(self.max:x() + 180)
	local awakwAbility = {}
	for i=1,math.huge do
		local awakAttr = cfg["awakeAbilityAttrType" .. i]
		if not awakAttr or awakAttr == 0 then
			break
		end
		local attrTypeStr = game.ATTRDEF_TABLE[awakAttr]
		local str = "attr" .. string.caption(attrTypeStr)
		local num, nextNum = dataEasy.getAttrValueAndNextValue(awakAttr, cfg["awakeAbilityAttrNum"..i][awakeAbility] or 0, cfg["awakeAbilityAttrNum"..i][awakeAbility + 1])
		table.insert(awakwAbility, {name = gLanguageCsv[str], num = num, nextNum = nextNum,isMax = awakeAbility >= cfg.awakeAbilityMax,type = "ability"})
	end
	self.showTexts:update(awakwAbility)
end



--一键升星
function CardEquipAwakeView:onAwakeAbilityFast()
	local data = clone(self.data)
	local cfg = csv.equips[data.equip_id]
	local awake = data.awake or 0
	local awakeAbility = data.awake_ability or 0
	local currLevelLimit = cfg.awakeRoleLevelMax[awake + 1]
	if awakeAbility == cfg.awakeAbilityMax then
		gGameUI:showTip(gLanguageCsv.awakeAbilityMax)
		return false
	end
	if self.level:read() < currLevelLimit then
		gGameUI:showTip(gLanguageCsv.currentLevelNotAvailable)
		return
	end

	if data.star < cfg.awakeStar[awake + 1] then
		gGameUI:showTip(gLanguageCsv.equipNotEnoughStar)
		return
	end

	if self.isEnoughItems == false then
		gGameUI:showTip(gLanguageCsv.equipNotEnoughAwakeItems)
		return
	end
	if self.isEnoughGold == false then
		gGameUI:showTip(gLanguageCsv.goldNotEnough)
		return
	end

	gGameUI:stackUI("city.card.equip.fast_awake", nil, nil, self.selectDbId:read(), self.data.equip_id, self:createHandler("playSpine"))
end

return CardEquipAwakeView