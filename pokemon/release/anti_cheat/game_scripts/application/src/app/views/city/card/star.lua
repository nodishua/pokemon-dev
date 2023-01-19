
--右侧卡牌icon
local function setCardIcon(list, node, v)
	bind.extend(list, node, {
		class = "card_icon",
		props = {
			unitId = v.unitId,
			advance = v.advance,
			rarity = v.rarity,
			star = v.star,
			levelProps = {
				data = v.level,
			},
			params = {
				starScale = 0.85 * 1.12,
				starInterval = 13 * 1.12,
			},
			onNode = function (panel)
				panel:get("star"):y(-40)
			end,
		}
	})
end
--左侧碎片icon
local function setItemIcon(list, node, v)
	bind.extend(list, node, {
		class = "icon_key",
		props = {
			data = {
				key = v.key,
				num = v.num
			},
			onNode = function(panel)
				panel:setTouchEnabled(false)
					:scale(0.9)
			end
		}
	})
end
--右侧星级
local function setStarIcon(parent, star)
	parent:removeAllChildren()
	local interval = 15
	local starNum = star > 6 and 6 or star
	for i=1,starNum do
		local starIdx = star - 6
		local icon = "common/icon/icon_star_d.png"
		if i <= star then
			icon = i <= starIdx and "common/icon/icon_star_z.png" or "common/icon/icon_star.png"
		end
		ccui.ImageView:create(icon)
			:xy(99 - interval * (starNum + 1 - 2 * i), -20)
			:addTo(parent, 4, "star")
			:scale(0.35)
	end
end
--队伍中的卡牌
local function getBattleCards()
	local battleCards = {}
	local mainBattCards = gGameModel.role:read("battle_cards")
	for k,v in pairs(mainBattCards) do
		table.insert(battleCards, v)
	end
	local cardDeployment = gGameModel.role:read("card_deployment")
	local arena = cardDeployment.arena
	for k,v in pairs(arena.defence_cards or {}) do
		table.insert(battleCards, v)
	end

	return battleCards
end

local function getCostEp(skillLevel, costID, fastUpgradeNum)
	local costEp = 0
	fastUpgradeNum = fastUpgradeNum or 1
	for i=1,fastUpgradeNum do
		if csv.base_attribute.skill_level[skillLevel + i - 1] then
			costEp = costEp + csv.base_attribute.skill_level[skillLevel + i - 1]["itemNum" .. costID]
		end
	end
	return costEp
end

local RebirthTools = require "app.views.city.card.rebirth.tools"

local CardStarView = class("CardStarView", cc.load("mvc").ViewBase)

CardStarView.RESOURCE_FILENAME = "card_star.json"
CardStarView.RESOURCE_BINDING = {
	["selectPanel.progressBar2"] = {
		binds = {
			event = "extend",
 			class = "loadingbar",
			props = {
				data = bindHelper.self("chipBarPercent"),
				maskImg = "common/icon/mask_bar_red.png"
			},
		},
	},
	["selectPanel.textHasNum"] = {
		binds = {
			event = "text",
			idler = bindHelper.self("chipNum"),
		}
	},
	["selectPanel.textNeedNum"] = {
		binds = {
			event = "text",
			idler = bindHelper.self("chipNeed"),
		}
	},
	["selectPanel.btnFrags"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onChangeClick")}
		}
	},
	["selectPanel.btnFrags.textNote"] = {
		binds = {
			event = "effect",
			data = {color = ui.COLORS.NORMAL.WHITE, glow = {color = ui.COLORS.GLOW.WHITE}},
		},
	},
	["selectPanel.btnAdd"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onGainWayClick")}
		}
	},
	["selectPanel.textNum"] = "textNum",
	["selectPanel"] = {
		varname = "selectPanel",
		binds = {
			{
				event = "visible",
				idler = bindHelper.self("selectPanelState")
			},
			{
				event = "click",
				method = bindHelper.self("onSelectPanelClick"),
			}
		}
	},
	["selectPanel.btnCombine"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onCombClick")}
		}
	},
	["selectPanel.btnCombine.textNote"] = {
		binds = {
			event = "effect",
			data = {color = ui.COLORS.NORMAL.WHITE, glow = {color = ui.COLORS.GLOW.WHITE}},
		},
	},
	["selectPanel.btnSure"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onSureClick")}
		}
	},
	["selectPanel.btnSure.textNote"] = {
		binds = {
			event = "effect",
			data = {color = ui.COLORS.NORMAL.WHITE, glow = {color = ui.COLORS.GLOW.WHITE}},
		},
	},
	["selectPanel.empty.text"] = "txtEmpty",
	["selectPanel.bg.bgIcon"] = "bgIcon",
	["cardItem"] = "cardItem",
	["selectPanel.subList"] = "subList",
	["selectPanel.list"] = {
		varname = "list",
		binds = {
			event = "extend",
			class = "tableview",
			props = {
				data = bindHelper.self("cardInfos"),
				columnSize = 2,
				item = bindHelper.self("subList"),
				cell = bindHelper.self("cardItem"),
				onCell = function(list, node, k, v)
					local t = list:getIdx(k)
					node:name("item" .. t.k)
					bind.extend(list, node:get("iconPanel"), {
						class = "card_icon",
						props = {
							unitId = v.unitId,
							advance = v.advance,
							rarity = v.rarity,
							star = v.star,
							levelProps = {
								data = v.level,
							},
							params = {
								starScale = 0.88,
								starInterval = 14,
							}
						}
					})
					uiEasy.setIconName("card", v.id, {node = node:get("textName"), name = v.name, advance = v.advance, space = true})
					node:get("textFight"):text(v.fight)
					node:get("iconLock"):visible(v.locked)
					node:get("textPanel"):visible(v.battleType ~= nil)
					if v.battleType then
						if ui.CARD_USING_TXTS[v.battleType] then
							local txt = node:get('textPanel'):get('text')
							txt:text(gLanguageCsv[ui.CARD_USING_TXTS[v.battleType]])
							node:get('textPanel'):get('bg'):size(txt:size().width + 50, 60)
						end
					end
					adapt.oneLinePos(node:get("textFightNote"), node:get("textFight"))
					node:get("mask"):visible(v.status ~= 0)
					node:get("iconSelect"):visible(v.selectState == true)
					node:setTouchEnabled(v.status == 0)
					if v.canSelect == true and v.selectState == false then
						node:setTouchEnabled(false)
						node:get("mask"):show()
					end
					bind.touch(list, node, {methods = {ended = functools.partial(list.itemClick,list:getIdx(k), v)}})
				end,
				asyncPreload = 8,
			},
			handlers = {
				itemClick = bindHelper.self("onCardItemClick"),
			},
		},
	},

	["extremePanel"] = {
		varname = "extremePanel",
		binds = {
			{
				event = "visible",
				idler = bindHelper.self("extremePanelState")
			},
			{
				event = "click",
				method = bindHelper.self("closeExtreme"),
			}
		}
	},

	["extremePanel.imgBg.textExtremePoint"] = {
		varname = "textExtremePoint",
		binds = {
			event = "text",
			idler = bindHelper.self("extremePoint"),
		}
	},
	["extremePanel.imgBg"] = {
		varname = "btnAddExtrePoint",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onAddExtrePointClick")}
		}
	},

	["extremePanel.btnReset"] = {
		varname = "btnResetEp",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onResetEp")}
		}
	},

	["extremePanel.textResetEpCost"] = {
		varname = "textResetEpCost",
		binds = {
			event = "text",
			idler = bindHelper.self("resetEpCost"),
		}
	},
	["extremePanel.imgBg.imgIcon"] = {
		binds = {
			event = "texture",
			idler = bindHelper.self("starSkillIcon"),
		}
	},
	["extremePanel.subList"] = "extremeSubList",
	["extremePanel.item"] = "extremeItem",
	["extremePanel.list"] = {
		varname = "extremeList",
		binds = {
			event = "extend",
			class = "tableview",
			props = {
				margin = 0,
				columnSize = 2,
				data = bindHelper.self("starSkills"),
				item = bindHelper.self("extremeSubList"),
				cell = bindHelper.self("extremeItem"),
				cardId = bindHelper.self("cardId"),
				onCell = function(list, node, k, v)
					--等级
					node:get("textLv"):text(v.skillLevel)
					--技能描述
					local skillCfg = csv.skill[v.skillId]
					local desc = string.format("#C0x5b545b#%s", eval.doMixedFormula(skillCfg.describe,{skillLevel = v.skillLevel or 1,math = math},nil) or "no desc")
					local size =  matchLanguage({"kr", "en"}) and 30 or 42
					local skillContent = rich.createWithWidth(desc, size, cc.size(400,130), 400, 20)
						:anchorPoint(0, 1)
						:xy(60, 220)
						:addTo(node)
						:z(2)
					--图标
					node:get("imgIcon"):texture(v.icon)
					--消耗
					local costId = csv.skill[v.skillId].costID
					local costEp = getCostEp(v.skillLevel, costId)
					node:get("textNum3"):text(costEp)
					local skillMaxLevel = csv.cards[v.cardId].starSkillMaxLevel
					if v.skillLevel + 1 > skillMaxLevel then
						uiEasy.setBtnShader(node:get("btnAdd"), nil, 3)
					end
					bind.touch(list, node:get("btnAdd"), {methods = {ended = functools.partial(list.clickAdd, k, v, costEp)}})
				end,
				asyncPreload = 6,
			},
			handlers = {
				clickAdd = bindHelper.self("onEpUpClick"),
			},
		},
	},

	["panel"] = "panel",
	["panel.btnChange"] = {
		varname = "panelBtnChange",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onChangeClick")}
		}
	},
	["effectItem"] = "effectItem",
	["panel.effectList"] = {
		varname = "effectList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("effectStartConfig"),
				item = bindHelper.self("effectItem"),
				itemAction = {isAction = true},
				onItem = function(list, node, k, v)

					local childs = node:multiget("textNote","iconStar")
					local richText1 = rich.createWithWidth(string.format("%s%s", v.color, "x"..v.value..": "), 44, nil, 100, 5)
						:anchorPoint(0, 0.5)
						:addTo(childs.textNote, 6)

					local richText2 = rich.createWithWidth(v.str, 44, nil, 678, 5)
						:anchorPoint(0, 0.5)
						:addTo(childs.textNote, 6)

					local height1 = richText1:size().height - 46
					local height2 = richText2:size().height - 46
					richText1:y(height2 - height1 - 0)
					richText2:y(height2 / 2)
					richText2:x(richText2:x() + 100)
					node:size(879, height2 + 74)

					local starIconPath = string.format("common/icon/icon_star%s.png", v.value > v.star and "_d" or "")
					childs.iconStar:texture(starIconPath):y(node:size().height/2 + height2/2)
					childs.textNote:text("")
				end
			}
		}
	},
	["panel.costInfo"] = "costInfo",
	["panel.costInfo.textCostNote"] = "costTxt",
	["panel.costInfo.textCostNum"] = "needGoldTxt",
	["panel.costInfo.imgIcon"] = "costIcon",
	["panel.btnOk"] = {
		varname = "btnOk",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onStarClick")}
		}
	},
	["panel.btnOk.textNote"] = {
		binds = {
			event = "effect",
			data = {color = ui.COLORS.NORMAL.WHITE, glow = {color = ui.COLORS.GLOW.WHITE}},
		},
	},
	-- 极限属性按钮
	["panel.btnExtreme"] = {
		varname = "btnExtreme",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onExtremeClick")}
		}
	},
	["panel.btnExtreme.textNote"] = {
		binds = {
			event = "effect",
			data = {color = ui.COLORS.NORMAL.WHITE, glow = {color = ui.COLORS.GLOW.WHITE}},
		},
	},

	["item"] = "item",
	["panel.itemList"] = {
		varname = "itemList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("costItems"),
				item = bindHelper.self("item"),
				-- dataOrderCmp = dataEasy.sortItemCmp,
				onItem = function(list, node, k, v)
					node:name("item" .. list:getIdx(k))
					local grayState = v.num < v.targetNum and 1 or 0
					node:get("cardIcon"):visible(v.typ == "card")
					node:get("itemIcon"):visible(v.typ ~= "card")
					if v.typ == "card" then
						bind.extend(list, node:get("cardIcon"), {
							class = "card_icon",
							props = {
								cardId = v.id,
								rarity = v.rarity,
								grayState = grayState,
								onNode = function (panel)
									uiEasy.setCardNum(panel, v.num, v.targetNum, 1)
									panel:setTouchEnabled(false)
								end,
							}
						})
					else
						local binds = {
							class = "icon_key",
							props = {
								data = {
									key = v.id,
									num = v.num,
									targetNum = v.targetNum
								},
								grayState = grayState,
								onNode = function (panel)
									panel:setTouchEnabled(false)
								end,
							},
						}
						bind.extend(list, node, binds)
					end
					node:get("mask"):visible(v.num < v.targetNum)
					bind.touch(list, node, {methods = {ended = functools.partial(list.itemClick, k, v)}})
				end,
				asyncPreload = 4,
			},
			handlers = {
				itemClick = bindHelper.self("onCostItemClick"),
			},
		},
	},
}

function CardStarView:onCreate(dbHandler)
	self.selectDbId = dbHandler()
	self:initModel()
    self.txtEmpty:anchorPoint(0.5, 0.5)
    self.txtEmpty:x(self.txtEmpty:x() + 250)
	self.costCardIDs = {}
	-- self.effectList:setScrollBarEnabled(false)
	self.chipBarPercent = idler.new(0)
	self.chipNum = idler.new(0)
	self.chipNeed = idler.new(0)
	self.needCash = idler.new(0)
	self.effectStartConfig = idlers.new()
	self.selectPanelState = idler.new(false)
	self.extremePanelState = idler.new(false)
	self.cardInfos = idlers.new()
	self.costItems = idlers.new()
	self.selectIdx = idler.new()
	self.eps = idlers.new()
	self.extremePoint = idler.new(0) --极限点
	self.starSkillIcon = idler.new()
	self.resetEpCost = idler.new(gCommonConfigCsv.cardStarSkillResetCostRMB)	--充值极限点消耗钻石
	self.starSkills = idlers.new()
	self.canResetEp = idler.new(false)
	local times = 0
	idlereasy.any({self.cardId, self.star, self.frags, self.cards, self.items, self.extremePoints},
		function(_, cardId, star, frags, cards, items, extremePoints)
			times = times + 1
			-- 减少一帧内多次重排
			performWithDelay(self, function()
				if times > 0 then
					self:refreshView()
					times = 0
				end
			end, 0)
		end
	)
	idlereasy.when(self.canResetEp, function(_, canResetEp)
		uiEasy.setBtnShader(self.btnResetEp, nil, canResetEp and 1 or 3)
	end)

	idlereasy.when(self.gold, function(_, gold)
		local cardCsv = csv.cards[self.cardId:read()]
		local csvStar = gStarCsv[cardCsv.starTypeID][self.star:read()]
		local color = (gold >= csvStar.gold) and cc.c4b(91, 84, 91, 255) or cc.c4b(249,87,114,255)
		text.addEffect(self.needGoldTxt, {color = color})
	end)
	self.selectMax = idler.new(1)
	self.selectNum = 0
	idlereasy.any({self.selectIdx, self.selectMax}, function(_, selectIdx, selectMax)
		self.textNum:text("0/"..selectMax)
		if self.cardInfos:atproxy(selectIdx) then
			local cardData = self.cardInfos:atproxy(selectIdx)
			if self.selectNum >= selectMax and cardData.selectState == false then
				return
			end
			cardData.selectState = not cardData.selectState
			local selectNum = 0
			local selectedDbId = {}
			for i = 1, self.cardInfos:size() do
				local cardInfos = self.cardInfos:atproxy(i)
				if cardInfos.selectState == true then
					selectNum = selectNum + 1
					table.insert(selectedDbId, cardInfos.dbid)
				end
			end
			self.selectNum = selectNum
			self.textNum:text(selectNum.."/"..selectMax)
			for i = 1, self.cardInfos:size() do
				local cardInfos = self.cardInfos:atproxy(i)
				cardInfos.canSelect = selectNum >= selectMax
			end
		end
	end)

end

function CardStarView:refreshView()

	local cardId = self.cardId:read()
	local skinId = self.skinId:read()
	local star = self.star:read()
	local frags = self.frags:read()
	local extremePoints = self.extremePoints:read()

	-- local tic = os.clock()
	local cardCsv = csv.cards[cardId]
	-- 材料卡牌不能兑换碎片
	self.panelBtnChange:visible(cardCsv.cardType == 1)
	local maxStar = table.length(gStarCsv[cardCsv.starTypeID])
	--属性加成面板
	self:setEffectPanel(star, gStarEffectCsv[cardCsv.starEffectIndex])
	local csvStar = gStarCsv[cardCsv.starTypeID][star]
	--消耗材料数据
	self:setCostDatas(csvStar, cardId, cardCsv)

	self.panel:get("costInfo"):visible(star < maxStar)
	self.panel:get("btnOk"):visible(star < maxStar)
	--极限属性
	local cardMarkCfg = csv.cards[cardCsv.cardMarkID]
	local starSkillSeqID = cardMarkCfg.starSkillSeqID
	local starSkill = csv.card_star_skill[starSkillSeqID].starSkillList
	if dataEasy.isUnlock(gUnlockCsv.extremityProperty) and star >= maxStar and itertools.size(starSkill) > 0 then
		self.panel:get("btnExtreme"):show()
		self.panel:get("iconMax"):hide()
	else
		--最大星级星级
		self.panel:get("iconMax"):visible(star >= maxStar)
		self.panel:get("btnExtreme"):hide()
	end
	--碎片面板
	self:setFragsPanel(cardCsv, frags)
	--星级面板
	local unitId = dataEasy.getUnitId(cardId, skinId)
	local unitCsv = csv.unit[cardCsv.unitID]
	local v = {
		id = cardId,
		unitId = unitId,
		advance = self.advance:read(),
		rarity = unitCsv.rarity,
		star = star,
		level = self.level:read()
	}
	setCardIcon(self, self.panel:get("iconPanel1"), v)
	v.star = math.min(star + 1, maxStar)
	setCardIcon(self, self.panel:get("iconPanel2"), v)
	-- setStarIcon(self.panel:get("starPanel1"), star)
	-- setStarIcon(self.panel:get("starPanel2"), math.min(star + 1, maxStar))

	--消耗金币
	if csvStar then
		self.needCash:set(csvStar.gold)
		self.needGoldTxt:text(csvStar.gold)
		self.costInfo:visible(csvStar.gold and csvStar.gold > 0)
		local color = (dataEasy.getNumByKey("gold") >= csvStar.gold) and cc.c4b(91, 84, 91, 255) or cc.c4b(249,87,114,255)
		text.addEffect(self.needGoldTxt, {color = color})
		local x, y = self.btnOk:xy()
		self.costInfo:xy(x, y + self.btnOk:height()/2 + 30)
		adapt.oneLineCenterPos(cc.p(self.costInfo:width()/2, self.costInfo:height()/2), {self.costTxt, self.needGoldTxt, self.costIcon}, cc.p(10, 0))
	end
	--卡牌数据
	self:setCardDatas(csvStar)
	--极限属性
	if dataEasy.isUnlock(gUnlockCsv.extremityProperty) then
		self.extremePoint:set(extremePoints[cardCsv.cardMarkID] or 0)
		local starSkillSeqID = cardMarkCfg.starSkillSeqID
		self.starSkillIcon:set(csv.unit[cardMarkCfg.unitID].iconSimple)
		local starSkills = {}
		local starSkill = csv.card_star_skill[starSkillSeqID].starSkillList
		local canResetEp = false
		for k, v in ipairs(starSkill) do
			local skillLevel = self.skills:read()[v] or 0
			if skillLevel > 0 then
				canResetEp = true
			end
			starSkills[v] = {
				cardId = self.cardId:read(),
				skillId = v,
				skillLevel = skillLevel,
				clientGold = self.gold:read(),
				fastUpgradeNum = 1,
				icon = self.starSkillIcon:read(),
			}
		end
		self.canResetEp:set(canResetEp)
		self.starSkills:update(starSkills)
	end
end

function CardStarView:initModel()
	self.gold = gGameModel.role:getIdler("gold")
	self.items = gGameModel.role:getIdler("items")
	self.frags = gGameModel.role:getIdler("frags")
	self.cards = gGameModel.role:getIdler("cards")
	self.cardCapacity = gGameModel.role:getIdler("card_capacity")--背包容量
	self.extremePoints = gGameModel.role:getIdler("star_skill_points")--极限点
	idlereasy.when(self.selectDbId,function (_, selectDbId)
		self.costCardIDs = {}
		local card = gGameModel.cards:find(selectDbId)
		self.level = idlereasy.assign(card:getIdler("level"), self.level)
		self.cardId = idlereasy.assign(card:getIdler("card_id"), self.cardId)
		self.skinId = idlereasy.assign(card:getIdler("skin_id"), self.skinId)
		self.fight = idlereasy.assign(card:getIdler("fighting_point"), self.fight)
		self.advance = idlereasy.assign(card:getIdler("advance"), self.advance)
		self.attrs = idlereasy.assign(card:getIdler("attrs"), self.attrs)
		self.skills = idlereasy.assign(card:getIdler("skills"), self.skills)
		self.star = idlereasy.assign(card:getIdler("star"), self.star)
	end)
end
--设置碎片面板
function CardStarView:setFragsPanel(cardCsv, frags)
	local fragCsv = csv.fragments[cardCsv.fragID]
	local chipNeedNum = fragCsv.combCount
	local myFragsNum = dataEasy.getNumByKey(cardCsv.fragID)--frags[cardCsv.fragID] or 0
	--fragIcon
	setItemIcon(self, self.selectPanel:get("iconPanel"), {
		key = cardCsv.fragID,
		num = myFragsNum
	})
	self.chipNum:set(myFragsNum)
	self.chipNeed:set("/"..chipNeedNum)
	local percent = cc.clampf(myFragsNum / chipNeedNum * 100, 0, 100)
	self.chipBarPercent:set(percent)
end
--设置材料数据
function CardStarView:setCostDatas(csvStar, cardId, cardCsv)
	--升星消耗
	local costItems = {}
	local rarityData = {}
	if csvStar then
		if csvStar.costCardNum > 0 then
			local unitCsv = csv.unit[cardCsv.unitID]
			local rarity = unitCsv.rarity
			if cardCsv.megaIndex > 0 then
				local cardMarkID = csv.cards[self.cardId:read()].cardMarkID
				local cards = self.cards:read()
				for i,v in pairs(cards) do
					local card = gGameModel.cards:find(v)
					local card_id = gGameModel.cards:find(v):read("card_id")
					local cardCsv = csv.cards[card_id]
					if cardCsv.cardMarkID == cardMarkID and rarity > csv.unit[cardCsv.unitID].rarity then
						rarity = csv.unit[cardCsv.unitID].rarity
					end
				end
			end
			table.insert(costItems, {
				id = cardCsv.cardMarkID,
				rarity = rarity,
				num = 0,
				targetNum = csvStar.costCardNum,
				typ = "card"
			})
		end
		for k,v in csvPairs(csvStar.costItems) do
			table.insert(costItems,{id = k,num = dataEasy.getNumByKey(k),targetNum = v})
		end
	end
	self.costItems:update(costItems)
end
--设置卡牌数据
function CardStarView:setCardDatas(csvStar)
	self.selectNum = 0
	self.selectIdx:set(0)
	local cards = self.cards:read()
	local cardMarkID = csv.cards[self.cardId:read()].cardMarkID
	local hash = dataEasy.inUsingCardsHash()
	local universalCards = {}
	if csvStar and csvStar.universalCards then
		universalCards = itertools.map(csvStar.universalCards, function(k, v) return v, k end)
	end
	local cardInfos = {}
	for i,v in pairs(cards) do
		local card = gGameModel.cards:find(v)
		if card then
			local cardData = card:read("card_id","unit_id", "skin_id","name","fighting_point","locked",  "level", "star", "advance")
			local cardCsv = csv.cards[cardData.card_id]

			local unitId = dataEasy.getUnitId(cardData.card_id, cardData.skin_id)
			local unitCsv = csv.unit[cardData.unit_id]
			local status = 0
			if cardData.locked then
				status = 1
			elseif hash[v] then
				status = 3
			elseif cardData.star > self.star:read() then
				status = 4
			end
			if (cardCsv.cardMarkID == cardMarkID and self.selectDbId:read() ~= v) or universalCards[cardData.card_id] then
				local tmpCardInfo = {
					id = cardData.card_id,
					unitId = unitId,
					rarity = unitCsv.rarity,
					attr1 = unitCsv.natureType,
					attr2 = unitCsv.natureType2,
					level = cardData.level,
					star = cardData.star,
					name = cardData.name,
					locked = cardData.locked,
					advance = cardData.advance,
					fight = cardData.fighting_point,
					dbid = v,
					selectState = false,
					-- status 0可消耗 1锁定 4星级限制
					status = status,
					battleType = hash[v],
					universal = universalCards[cardData.card_id]
				}
				table.insert(cardInfos, tmpCardInfo)
			end
		end
	end
	self.selectPanel:get("empty"):visible(#cardInfos == 0)
	self.bgIcon:visible(#cardInfos ~= 0)
	table.sort(cardInfos,function(a,b)
		if a.universal and not b.universal then
			return true
		elseif not a.universal and b.universal then
			return false
		end
		return a.fight > b.fight
	end)
	self.cardInfos:update(cardInfos)
end
--设置加成面板
function CardStarView:setEffectPanel(star, effectCfg)
	local keys = itertools.keys(effectCfg)
	local c1 = "#C0x5B545B##F44#"
	local c2 = "#C0x60C456##F44#"
	table.sort(keys)
	local datas = {}

	for k1, i in ipairs(keys) do
		local v = effectCfg[i]
		local str = ""
		local args = {}
		local color = i > star and "#C0xB7B09E#" or "#C0x5B545B#"
		local color1 = i <= star and c1 or "#C0xB7B09E#"
		local color2 = i <= star and c2 or "#C0xB7B09E#"
		for k,v in csvPairs(v.attrNum) do
			local attr = game.ATTRDEF_TABLE[k]
			local name = gLanguageCsv["attr" .. string.caption(attr)]
			local effectNum = "+"..dataEasy.getAttrValueString(k,v)
			table.insert(args, color1..name..color2..effectNum)
		end

		str = table.concat(args, " ")
		str = str..color1..(v.effectDesc or "")
		datas[k1] = {
			str = str,
			value = i,
			star = star,
			color = color,
		}
	end

	self.effectStartConfig:update(datas)
end

--加号按钮获取途径
function CardStarView:onGainWayClick()
	local fragsId = csv.cards[self.cardId:read()].fragID
	local fragCsv = csv.fragments[fragsId]
	local chipNeedNum = fragCsv.combCount
	gGameUI:stackUI("common.gain_way", nil, nil, fragsId, nil, chipNeedNum)
end
--合成按钮
function CardStarView:onCombClick()
	-- 精灵背包满时提示无法合成
	if itertools.size(self.cards:read()) >= self.cardCapacity:read() then
		gGameUI:showTip(gLanguageCsv.cardBagHaveBeenFull)
		return
	end
	local cardCsv = csv.cards[self.cardId:read()]
	cardCsv = csv.cards[cardCsv.cardMarkID]
	local fragCsv = csv.fragments[cardCsv.fragID]

	if self.chipNum:read() < fragCsv.combCount then
		gGameUI:showTip(gLanguageCsv.fragCombfragNotEnough)
		return
	end
	local strs = {
		string.format("#C0x5b545b#"..gLanguageCsv.wantConsumeFragsCombCard, fragCsv.combCount, "#C0x60C456#"..fragCsv.name.."#C0x5b545b#", "#C0x60C456#"..cardCsv.name)
	}
	gGameUI:showDialog({content = strs, cb = function()
		gGameApp:requestServer("/game/role/frag/comb",function (tb)
			gGameUI:stackUI("common.gain_sprite", nil, {full = true}, tb.view, nil, false, self:createHandler("resetSelectNum"))
		end,cardCsv.fragID)
	end, btnType = 2, isRich = true, clearFast = true})
end

function CardStarView:resetSelectNum()
	self.selectNum = 0
end

--点击选择卡牌
function CardStarView:onCardItemClick(list, k, v)
	local card = gGameModel.cards:find(v.dbid)
	local baseStar = card:read("getstar")
	if v.selectState == false and (v.star > baseStar or v.level > 1 or v.advance > 1 or self:getDevelopState(v.dbid)) then
		gGameUI:showDialog({content = gLanguageCsv.tipsForSelectingMaterials, cb = function()
			self.selectIdx:set(k.k, true)
		end, btnType = 2, isRich = true})
	else
		self.selectIdx:set(k.k, true)
	end
end
function CardStarView:getDevelopState(dbid)
	local card = gGameModel.cards:find(dbid)
	local effortValue = card:read("effort_values")
	local equips = card:read("equips")
	local skills = card:read("skills")
	local cardId = card:read("card_id")
	for k,v in pairs(skills) do
		if v > 1 then
			return true
		end
	end
	local cardCsv = csv.cards[cardId]
	local fragCsv = csv.fragments[cardCsv.fragID]
	if fragCsv.combID < cardId then
		return true
	end
	for k,v in pairs(effortValue) do
		if v > 0 then
			return true
		end
	end
	for k,v in pairs(equips) do
		if v.level > 1 or v.star > 0 or v.awake > 0 then
			return true
		end
	end
	return false
end
--点击确定
function CardStarView:onSureClick()
	self.costCardIDs = {}
	local rarityData = {}
	for i,v in self.cardInfos:pairs() do
		local v = v:proxy()
		if v.selectState then
			table.insert(self.costCardIDs, v.dbid)
		end
	end

	self.costItems:atproxy(1).num = self.selectNum
	self.selectPanelState:set(false)
end
--点击空白
function CardStarView:onSelectPanelClick()
	self.selectPanelState:set(false)
end
--点击消耗物品
function CardStarView:onCostItemClick(list, k, v)
	if v.typ == "card" then
		-- self.selectNum = v.num
		self.selectMax:set(v.targetNum)
		self.selectPanelState:set(not self.selectPanelState:read())
	else
		gGameUI:stackUI("common.gain_way", nil, nil, v.id, nil, v.targetNum)
	end
end

--极限点消耗物品
function CardStarView:onStarSkillCostItemClick()
	self.selectMax:set(1)
	self.selectPanelState:set(true)
end

function CardStarView:onChangeClick()
	if self.star:read() == 12 and not dataEasy.isUnlock(gUnlockCsv.extremityProperty) then
		gGameUI:showTip(gLanguageCsv.cardStarMaxErr)
		return
	end
	gGameUI:stackUI("city.card.star_changefrags", nil, nil, self.selectDbId:read())
end

function CardStarView:onStarClick()
	if self.star:read() == 12 then
		gGameUI:showTip(gLanguageCsv.cardStarMaxErr)
		return
	end
	if dataEasy.getNumByKey("gold") < self.needCash:read() then
		gGameUI:showTip(gLanguageCsv.starNoEnoughGold)
		return
	end
	for i,v in self.costItems:ipairs() do
		local v = v:proxy()
		if v.num < v.targetNum then
			gGameUI:showTip(gLanguageCsv.starMaterialsNotEnough)
			return
		end
	end
	local fight = self.fight:read()
	local attrs = clone(self.attrs:read())

	local function requestServer()
		gGameApp:requestServer("/game/card/star",function (tb)
			self.selectNum = 0
			gGameUI:stackUI("city.card.common_success", nil, {blackLayer = true},
				self.selectDbId:read(),
				fight,
				{starOld = true, attrs = attrs, skills = self.skills:read()}
			)
			audio.playEffectWithWeekBGM("star.mp3")
		end, self.selectDbId, self.costCardIDs)
	end
	--star更高的精灵提示
	local hasMoreStar = false
	for i,v in self.cardInfos:pairs() do
		local v = v:proxy()
		if v.star > self.star:read() then
			hasMoreStar = true
		end
	end
	if hasMoreStar then
		local str = gLanguageCsv.moreStarTips
		gGameUI:showDialog({content = str, cb = requestServer, btnType = 2, clearFast = true})
	else
		requestServer()
	end
end


function CardStarView:onExtremeClick()
	self.extremePanelState:set(true)
end

function CardStarView:closeExtreme()
	self.extremePanelState:set(false)
end

function CardStarView:onAddExtrePointClick( )
	gGameUI:stackUI("city.card.star_changestarskill", nil, nil, self:createHandler("selectDbId"))
end

function CardStarView:onResetEp()
	if gGameModel.role:read("rmb")  < self.resetEpCost:read() then
		uiEasy.showDialog("rmb")
	else
		if self.canResetEp:read() == false then
			gGameUI:showTip(gLanguageCsv.haveNotUpStarSkill)
			return false
		end
		local cardId = self.cardId:read()
		local name = csv.unit[csv.cards[cardId].unitID].name
		local quality = dataEasy.getCfgByKey(csv.cards[cardId].fragID).quality
		local textColor = ui.QUALITYCOLOR[quality]
		gGameUI:showDialog({title = "", content = string.format(gLanguageCsv.starSkillResetTips,self.resetEpCost:read(),textColor..name), cb = function()
			gGameApp:requestServer("/game/card/star/skill/reset",function (tb)
				gGameUI:showGainDisplay(tb)
			end, self.selectDbId:read())
		end, btnType = 2, isRich = true,})
	end
end

function CardStarView:onEpUpClick(list, k, v, cost)
	local skillMaxLevel = csv.cards[v.cardId].starSkillMaxLevel
	if v.skillLevel + 1 > skillMaxLevel then
		gGameUI:showTip(gLanguageCsv.starSkillMaxTips)
		return
	end
	if self.extremePoint:read() >= cost then
		gGameApp:requestServer("/game/card/skill/level/up",function (tb)
		end, self.selectDbId, v.skillId, v.fastUpgradeNum)
	else
		self:onAddExtrePointClick()
	end
end


return CardStarView