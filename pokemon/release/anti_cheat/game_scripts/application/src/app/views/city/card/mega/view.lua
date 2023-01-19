-- @date 2020-7-21
-- @desc 超进化主界面

local zawakeTools = require "app.views.city.zawake.tools"
local MegaView = class("MegaView", cc.load("mvc").ViewBase)

-- 道具的排序可以优化固定下：常规道具（id升序）>钥石>超级石
local function getCmpKey(key)
	local id = dataEasy.stringMapingID(key)
	local cfg = csv.card_mega_convert[id]
	if not cfg then
		return 0
	end
	return cfg.type
end

MegaView.RESOURCE_FILENAME = "card_mega.json"
MegaView.RESOURCE_BINDING = {
	["item"] = "item",
	["list"] = {
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("tabDatas"),
				item = bindHelper.self("item"),
				itemAction = {isAction = true},
				onItem = function(list, node, k, v)
					bind.extend(list, node:get("item"), {
						class = "card_icon",
						props = {
							cardId = v.id,
							rarity = v.unitCfg.rarity,
							grayState = v.isHas and 0 or 2,
							onNode = function(panel)
								panel:xy(20, 10)
									:z(5)
							end,
						}
					})
					node:get("item.select"):visible(v.isSel)
					node:get("item.hint"):visible(not v.canDevelop)
					bind.extend(list, node, {
						class = "red_hint",
						props = {
							state = not v.isSel,
							listenData = {
								megaId = v.id,
							},
							specialTag = "cardMega",
							onNode = function (node)
								node:xy(200, 180)
							end
						}
					})
					bind.touch(list, node:get("item"), {methods = {ended = functools.partial(list.clickCell, k, v)}})
				end,
				asyncPreload = 6,
			},
			handlers = {
				clickCell = bindHelper.self("onTabItemClick"),
			},
		}
	},
	["book"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("bookFunc")}
		},
	},
	["book.txt"] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.NORMAL.WHITE}},
		},
	},
	["itemPanel"] = "itemPanel",
	["itemPanel.starItem"] = "starItem",
	["itemPanel.starList"] = {
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("cardStarData"),
				item = bindHelper.self("starItem"),
				onItem = function(list, node, k, v)
					node:get("star"):texture(v.icon)
				end,
			},
		}
	},
	["itemPanel.attrItem"] = "attrItem",
	["itemPanel.attrList"] = {
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("attrDatas"),
				item = bindHelper.self("attrItem"),
				onItem = function(list, node, k, v)
					node:texture(ui.ATTR_ICON[v]):scale(0.8)
				end,
			},
		},
	},
	["animaCard"] = "animaCard",
	["panel"] = "panel",
	["panel.txt1"] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.NORMAL.WHITE}},
		},
	},
	["panel.gold"] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.NORMAL.WHITE}},
		},
	},
	["anima"] = "anima",
	["megaOk"] = "megaOk",
	["titlePanel"] = "titlePanel",
	["titlePanel.num"] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.NORMAL.WHITE}},
		},
	},
	["rightPanel"] = "rightPanel",
	["rightPanel.rule"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("ruleFunc")}
		},
	},
	["rightPanel.card.item"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.defer(function(view)
				return view:chooseCard()
			end)},
		},
	},
	["rightPanel.item"] = "rightItem",
	["rightPanel.list"] = {
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("rightDatas"),
				item = bindHelper.self("rightItem"),
				dataOrderCmp = function(a, b)
					local ka = getCmpKey(a.key)
					local kb = getCmpKey(b.key)
					if ka ~= kb then
						return ka < kb
					end
					return dataEasy.stringMapingID(a.key) < dataEasy.stringMapingID(b.key)
				end,
				onItem = function(list, node, k, v)
					local childs = node:multiget("item", "btn", "num1", "num2")
					itertools.invoke({childs.btn, childs.num1, childs.num2}, "hide")

					if v.costCards then
						local num = itertools.size(v.subCardData)
						local isEnough = num >= v.costCards.num
						childs.item:get("add"):visible(not isEnough)
						childs.num1:show():text(num)
						childs.num2:show():text("/" .. v.costCards.num)
						text.addEffect(childs.num1, {color = isEnough and ui.COLORS.NORMAL.FRIEND_GREEN or ui.COLORS.NORMAL.ALERT_ORANGE, outline = {color = ui.COLORS.NORMAL.WHITE}})
						text.addEffect(childs.num2, {outline = {color = ui.COLORS.NORMAL.WHITE}})
						adapt.oneLineCenterPos(cc.p(105, 100), {childs.num1, childs.num2})

						local cardId = v.costCards.markID or 1
						local unitID = csv.cards[cardId].unitID
						local unitCfg = csv.unit[unitID]
						bind.extend(list, childs.item, {
							class = "card_icon",
							props = {
								cardId = cardId,
								star = v.costCards.star,
								rarity = unitCfg.rarity,
								grayState = isEnough and 0 or 1,
								onNode = function(node)
									if not v.costCards.markID then
										node:getChildByName("icon"):texture("config/item/icon_sjjl.png")
									end
								end,
							}
						})
						bind.touch(list, childs.item, {methods = {ended = function()
							list.chooseCard(k, v)
						end}})
					else
						local num = v.selectNum
						local isEnough = num >= v.val
						childs.item:get("add"):visible(not isEnough)
						bind.extend(list, childs.item, {
							class = "icon_key",
							props = {
								noListener = true,
								grayState = isEnough and 0 or 1,
								data = {
									key = v.key,
									num = num,
									targetNum = v.val,
								},
								onNode = function(panel)
									panel:setTouchEnabled(false)
								end,
							},
						})
						bind.touch(list, childs.item, {methods = {ended = function()
							jumpEasy.jumpTo("gainWay", v.key, nil, v.val)
						end}})
						-- 判断是 megaStone, keyStore
						local isMegaConversion = csv.card_mega_convert[v.key]
						childs.btn:hide()
						if isMegaConversion then
							childs.btn:show()
							bind.touch(list, childs.btn, {methods = {ended = function()
								gGameUI:stackUI("city.card.mega.conversion", nil, nil, {id = v.key, num = v.val})
							end}})
						end
					end
				end,
				onAfterBuild = function(list)
					list:refreshView()
					local count = list:getChildrenCount()
					if count > 0 and count < 4 then
						local t = {0, 80, 40}
						list:setItemsMargin(t[count])
					else
						list:setItemsMargin(0)
					end
					list:setItemAlignCenter()
				end,
			},
			handlers = {
				chooseCard = bindHelper.self("chooseCard"),
			},
		},
	},
	["btn"] = {
		varname = "conversion",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("conversionClick")}
		},
	},
}

function MegaView:onCreate(cardId,cb)
	self.topUi = gGameUI.topuiManager:createView("default", self, {onClose = self:createHandler("onClose")})
		:init({title = gLanguageCsv.megaHouse, subTitle = "EVOLUTION MEGA"})
	self:initModel()
	self.anima:hide()
	self.cardId = cardId
	self.cb = cb
	self.attrDatas = idlers.newWithMap({})
	self.rightDatas = idlers.newWithMap({})

	self.selectedData = {}	--保存当前卡牌的信息 {key, cardId, megaIndex, cardDbid, subCardData}
	self.tabDatas = idlers.new({})
	self.cardSelected = idler.new(1)	--选择卡牌
	self.cardStarData = idlers.new({})	--主卡牌的星星
	idlereasy.any({self.cards, self.items}, function(_, cards, items)
		local data = {}
		local cardIdData = {}
		for _, dbid in ipairs(cards) do
			local card = gGameModel.cards:find(dbid)
			if card then
				local cardId = card:read("card_id")
				cardIdData[cardId] = true
			end
		end
		for i,v in pairs(gCardsMega) do
			local cardCsv = csv.cards[v.key]
			local unitCfg = csv.unit[cardCsv.unitID]
			table.insert(data, {
				id = v.key,
				unitCfg = unitCfg,
				canDevelop = v.canDevelop,
				whetherMega = v.canDevelop and 1 or 0,
				isSel = false,
				isHas = cardIdData[v.key] ~= nil,
				megaIndex = i,
				dbid = dbid,
				markId = cardCsv.cardMarkID,
			})
		end
		table.sort(data, function(a, b)
			if a.whetherMega ~= b.whetherMega then
				return a.whetherMega > b.whetherMega
			end
			if a.unitCfg.rarity ~= b.unitCfg.rarity then
				return a.unitCfg.rarity > b.unitCfg.rarity
			end
			return a.id < b.id

		end)
		self.tabDatas:update(data)

		if self.cardId then
			local find = false
			for i, v in ipairs(data) do
				if v.id == self.cardId and v.canDevelop then
					find = true
					self.cardSelected:set(i)
					break
				end
			end
			if not find then
				local markId = csv.cards[self.cardId].cardMarkID
				for i, v in ipairs(data) do
					if v.markId == markId and v.canDevelop then
						find = true
						self.cardSelected:set(i)
						break
					end
				end
			end
		end

		local selected = self.cardSelected:read()
		self:onTabItemClick(nil, selected, self.tabDatas:atproxy(selected))
	end)

	self.cardSelected:addListener(function(val, oldval)
		self.tabDatas:atproxy(oldval).isSel = false
		self.tabDatas:atproxy(val).isSel = true
	end)

	idlereasy.when(self.gold, functools.partial(self.costGoldUpdate, self))
end

function MegaView:initModel()
	self.pokedex = gGameModel.role:getIdler("pokedex")
	self.cards = gGameModel.role:getIdler("cards")
	self.items = gGameModel.role:getIdler("items")
	self.gold = gGameModel.role:getIdler("gold")
end

--选中某个需要超进化的卡牌时初始化他的基本信息
function MegaView:onTabItemClick(list, k, v)
	-- 未拥有的卡牌显示
	if not v.canDevelop then
		gGameUI:showTip(gLanguageCsv.comingSoon)
		return
	end
	self.cardId = v.id
	self.megaOk:visible(v.isHas)

	if k ~= self.cardSelected:read() or not self.selectedData.subCardData then
		self.selectedData = {key = "main", cardId = v.id, megaIndex = v.megaIndex, subCardData = {}}
	end

	--卡牌信息
	self.itemPanel:get("icon"):texture(ui.RARITY_ICON[v.unitCfg.rarity])
	local attrDatas = {}
	table.insert(attrDatas, v.unitCfg.natureType)
	if v.unitCfg.natureType2 then
		table.insert(attrDatas, v.unitCfg.natureType2)
	end
	self.attrDatas:update(attrDatas)

	--卡牌特效
	if self.cardSprite then
		self.cardSprite:removeFromParent()
		self.cardSprite = nil
	end
	self.cardSprite = widget.addAnimation(self.animaCard, v.unitCfg.unitRes, "standby_loop", 5)
		:alignCenter(self.animaCard:size())
		:scale(v.unitCfg.scaleU*3)
		:y(-100)
	self.cardSprite:setSkin(v.unitCfg.skin)

	--主卡牌
	self:cardItemUpdate()

	local cfg = csv.card_mega[v.megaIndex]
	-- 材料消耗
	local data = {}
	if csvSize(cfg.costCards) > 0 then
		table.insert(data, {costCards = cfg.costCards, subCardData = self.selectedData.subCardData})
	end
	for k, v in csvMapPairs(cfg.costItems) do
		if k ~= "gold" then
			table.insert(data, {key = k, val = v, selectNum =  dataEasy.getNumByKey(k)})
		end
	end
	self.rightDatas:update(data)
	self.cardSelected:set(k, true)

	self:costGoldUpdate()

	--condition[1]等于1是角色等级 等于2是卡牌等级
	local conditionStr = cfg.condition[1] == 1 and string.format(gLanguageCsv.roleLevelReach, cfg.condition[2]) or string.format(gLanguageCsv.roleCardLevelReach, cfg.condition[2])
	self.titlePanel:get("num"):text(conditionStr)

	bind.extend(self, self.conversion, {
		class = "red_hint",
		props = {
			listenData = {
				megaId = v.id,
			},
			specialTag = "cardMega",
			onNode = function (node)
				node:xy(400, 160)
			end
		}
	})
end

function MegaView:costGoldUpdate()
	local cfg = csv.card_mega[self.selectedData.megaIndex]
	local costGold = cfg.costItems.gold
	if costGold then
		self.panel:show()
		self.panel:get("gold"):text(costGold)
		local roleGold = gGameModel.role:read("gold")
		text.addEffect(self.panel:get("gold"), {color = roleGold >= costGold and ui.COLORS.NORMAL.DEFAULT or ui.COLORS.NORMAL.ALERT_ORANGE})
		adapt.oneLineCenterPos(cc.p(400, 40), {self.panel:get("txt1"), self.panel:get("gold"), self.panel:get("icon")}, cc.p(8, 0))
	else
		self.panel:hide()
	end
end

function MegaView:cardStarUpdate(star)
	local cfg = csv.card_mega[self.selectedData.megaIndex]
	star = star or cfg.card[2]
	local cardStarData = {}
	local starIdx = star - 6
	for i=1,6 do
		local icon = "common/icon/icon_star_d.png"
		if i <= star then
			icon = i <= starIdx and "common/icon/icon_star_z.png" or "common/icon/icon_star.png"
		end
		table.insert(cardStarData, {icon = icon})
	end
	self.cardStarData:update(cardStarData)
end

function MegaView:cardItemUpdate()
	local dbid = self.selectedData.cardDbid
	local star, advance
	if dbid then
		local card = gGameModel.cards:find(dbid)
		star = card:read("star")
		advance = card:read("advance")
	end
	uiEasy.setIconName("card", self.cardId, {node = self.itemPanel:get("name"), advance = advance, space = true})
	self:cardStarUpdate(star)

	local megaIndex = self.selectedData.megaIndex
	local cfg = csv.card_mega[megaIndex]
	local dbid = self.selectedData.cardDbid
	local txt1 = self.rightPanel:get("card.txt1")
	local txt2 = self.rightPanel:get("card.txt2")
	txt1:text(dbid and 1 or 0)
	txt2:text("/" .. 1)
	text.addEffect(txt1, {color = dbid and ui.COLORS.NORMAL.FRIEND_GREEN or ui.COLORS.NORMAL.ALERT_ORANGE, outline = {color = ui.COLORS.NORMAL.WHITE}})
	text.addEffect(txt2, {outline = {color = ui.COLORS.NORMAL.WHITE}})
	adapt.oneLineCenterPos(cc.p(140, -20), {txt1, txt2})

	self.rightPanel:get("card.item.add"):visible(dbid == nil)

	local cardId, star = cfg.card[1], cfg.card[2]
	local skinId = 0
	local unitID = csv.cards[cardId].unitID
	local unitCfg = csv.unit[unitID]
	local rarity = unitCfg.rarity
	local advance = false
	local level = false
	if dbid then
		local card = gGameModel.cards:find(dbid)
		cardId = card:read("card_id")
		skinId = card:read("skin_id")
		star = card:read("star")
		advance = card:read("advance")
		level = card:read("level")
	end
	local unitID = dataEasy.getUnitId(cardId, skinId)
	local item = self.rightPanel:get("card.item")
	bind.extend(self, item, {
		class = "card_icon",
		props = {
			unitId = unitID,
			star = star,
			rarity = rarity,
			advance = advance,
			levelProps = {
				data = level,
			},
			grayState = dbid and 0 or 1,
			onNode = function(node)
				node:scale(1.3)
				node:alignCenter(item:size())
			end,
		}
	})
end

function MegaView:chooseCard(list, k, v)
	self.selectedData.chooseIdx = k
	gGameUI:stackUI("city.card.mega.choose_card", nil, nil, self.selectedData, self:createHandler("itemCallback"))
end

--	选中卡牌后回调刷新
-- self.selectedData.clickBtn 等于1是本体回到，2是材料精灵回到
-- 当回到是table则是多选，根据配置暂时只有精灵材料用到
function MegaView:itemCallback()
	if self.selectedData.chooseIdx then
		self.rightDatas:atproxy(self.selectedData.chooseIdx).subCardData = self.selectedData.subCardData
	else
		self:cardItemUpdate()
	end
end

--超进化特效
function MegaView:animaFunc(cardId)
	self.megaOk:hide()
	self.cardSprite:hide()
	self.anima:show()
	self.topUi:hide()
	audio.playEffectWithWeekBGM("maga.mp3")
	local unitID1 = csv.cards[cardId].unitID
	local unitID2 = csv.cards[self.cardId].unitID
	local unitRes1, unitRes2 = csv.unit[unitID1].unitRes, csv.unit[unitID2].unitRes
	self.animaHou = widget.addAnimationByKey(self.anima, "chaojinhua/chaojinhua.skel", "hou", "chaojinhua_effect_hou", 1)
		:alignCenter(self.anima:size())
		:scale(2)

	self.cardSprite1 = widget.addAnimationByKey(self.anima, unitRes1, "cards1", "standby_loop", 3)
		:alignCenter(self.anima:size())
	self.cardSprite2 = widget.addAnimationByKey(self.anima, unitRes2, "cards2", "standby_loop", 2)
		:alignCenter(self.anima:size())
	self.cardSprite2:hide()

	self.animaQian = widget.addAnimationByKey(self.anima, "chaojinhua/chaojinhua.skel", "qian", "chaojinhua_effect_qian", 4)
		:alignCenter(self.anima:size())
		:scale(2)

	local name = "juese_move"
	local action = cc.RepeatForever:create(cc.Sequence:create(
		cc.CallFunc:create(function()
			local posx, posy = self.animaHou:getPosition()
			local sx, sy = self.animaHou:getScaleX(), self.animaHou:getScaleY()
			local bxy = self.animaHou:getBonePosition(name)
			local rotation = self.animaHou:getBoneRotation(name)
			local scaleX = self.animaHou:getBoneScaleX(name)
			local scaleY = self.animaHou:getBoneScaleY(name)
			self.cardSprite1:rotate(-rotation)
				:scaleX(scaleX*2)
				:scaleY(scaleY*2)
				:xy(cc.p(bxy.x * sx + posx , bxy.y * sy + posy))
			self.cardSprite2:rotate(-rotation)
				:scaleX(scaleX*2)
				:scaleY(scaleY*2)
				:xy(cc.p(bxy.x * sx + posx , bxy.y * sy + posy))
		end)
	))
	self.cardSprite1:runAction(action)
	self.cardSprite2:runAction(action)

	performWithDelay(self, function( ... )
		local switch = 2
		local color = {255,255,255,1}
		self.cardSprite1:setHSLShader(color[1],color[2],color[3],color[4],color[5],switch)
	end, 2)

	performWithDelay(self, function()
		self.cardSprite1:hide()
		self.cardSprite2:show()
	end, 5.5)

	performWithDelay(self, function()
		self.cardSprite:show()
		self.cardSprite1:removeAllChildren()
		self.cardSprite2:removeAllChildren()
		self.anima:removeAllChildren()
		self.anima:hide()
		self.animaQian = nil
		self.animaHou = nil
		self.topUi:show()
		local isHas = self.tabDatas:atproxy(self.cardSelected:read()).isHas
		self.megaOk:visible(isHas)
	end, 7.5)
end

--转化
function MegaView:conversionClick()
	if not self.selectedData.cardDbid then
		gGameUI:showTip(gLanguageCsv.megaMaterialsNotEnough)
		return
	end

	local cfg = csv.card_mega[self.selectedData.megaIndex]
	if csvSize(cfg.costCards) ~= 0 then
		if itertools.size(self.selectedData.subCardData) < cfg.costCards.num then
			gGameUI:showTip(gLanguageCsv.megaMaterialsNotEnough)
			return
		end
	end

	local card = gGameModel.cards:find(self.selectedData.cardDbid)
	if cfg.condition[1] == 1 and gGameModel.role:read("level") < cfg.condition[2] then
		gGameUI:showTip(gLanguageCsv.cardDissatisfy)
		return
	end
	if cfg.condition[1] == 2 and card:read("level") < cfg.condition[2] then
		gGameUI:showTip(string.format(gLanguageCsv.roleCardLevelReach, cfg.condition[2]))
		return
	end

	for key, val in csvMapPairs(cfg.costItems) do
		if key ~= "gold" then
			local num = dataEasy.getNumByKey(key)
			if num < val then
				gGameUI:showTip(gLanguageCsv.megaMaterialsNotEnough)
				return
			end
		end
	end

	local roleGold = gGameModel.role:read("gold")
	if cfg.costItems.gold and roleGold < cfg.costItems.gold then
		gGameUI:showTip(gLanguageCsv.goldNotEnough)
		return
	end

	local attrs = clone(card:read("attrs"))
	local cardId = card:read("card_id")
	local id = card:read("id")
	local oldFight = card:read("fighting_point")
	local branch = csv.cards[self.cardId].branch
	local data = {}
	for k in pairs(self.selectedData.subCardData) do
		table.insert(data, k)
	end
	local isHas = self.tabDatas:atproxy(self.cardSelected:read()).isHas
	local tip = gLanguageCsv.whetherMega

	local zawakeID = csv.cards[cardId].zawakeID
	local zawakeStage, zawakeLevel = zawakeTools.getMaxStageLevel(zawakeID)
	if zawakeStage then
		local name = csv.cards[cardId].name
		local stageStr = gLanguageCsv['symbolRome' .. zawakeStage]
		tip = string.format(gLanguageCsv.zawakeMegaTip, name, stageStr)
	end
	gGameUI:showDialog({title = gLanguageCsv.spaceTips, content = tip, isRich = true, fontSize = 50, btnType = 2, cb = function ()
		local showOver = {false}
		local cardDbid = self.selectedData.cardDbid
		self.selectedData.cardDbid = nil
		self.selectedData.subCardData = nil
		gGameApp:requestServerCustom("/game/develop/mega")
			:params(id, branch, data)
			:onResponse(function (tb)
				self:animaFunc(cardId)
				performWithDelay(self, function()
					self.anima:hide()
					if self.cb then
						self.cb()
					end
					showOver[1] = true
				end, 7.5)
			end)
			:wait(showOver)
			:doit(function(tb)
				local cb = function()
	 				gGameUI:stackUI("city.card.common_success", nil, {blackLayer = true},
						cardDbid,
						oldFight,
						{
							cardOld = cardId,
							attrs = attrs,
							mega = true,
						}
					)
				end
				if not itertools.isempty(tb.view) then
					gGameUI:showGainDisplay(tb.view, {cb = cb})
				else
					cb()
				end
			end)
	end})
end

--图鉴
function MegaView:bookFunc()
	gGameUI:stackUI("city.handbook.view", nil, {full = true}, {cardId = self.cardId}) --卡牌不存在时，dbid也就拿不到了
end

--规则
function MegaView:ruleFunc()
	gGameUI:stackUI("common.rule", nil, nil, self:createHandler("getRuleContext"), {width = 1300})
end

function MegaView:getRuleContext(view)
	local content = {95001, 95010}
	local c = adaptContext
	local context = {
		c.clone(view.title, function(item)
			item:get("text"):text(gLanguageCsv.megaHouse)
		end),
		c.noteText(unpack(content)),
	}
	return context
end

return MegaView