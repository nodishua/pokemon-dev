
local ViewBase = cc.load("mvc").ViewBase
local CardStarChangeSkillView = class("CardStarChangeSkillView", Dialog)

local function getEp(v)
	local cardCfg = csv.cards[v.id]
	local card = gGameModel.cards:find(v.dbid)
	local baseStar = card:read("getstar")
	local star = v.star
	local totalEp = 1
	if star > baseStar then
		for i= baseStar, star - 1 do
			local starCfg = gStarCsv[cardCfg.starTypeID][i]
			if starCfg then
				totalEp = totalEp + starCfg.costCardNum
			end
		end
	end
	return totalEp
end

CardStarChangeSkillView.RESOURCE_FILENAME = "card_star_skill.json"
CardStarChangeSkillView.RESOURCE_BINDING = {
	["closeBtn"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")}
		}
	},
	["titleTxt"] = "title",
	["item"] = "item",
	["btnList"] = {
		varname = "btnList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("tabDatas"),
				item = bindHelper.self("item"),
				onItem = function(list, node, k, v)
					local btn = node:get("btn")
					local txt = node:get("title")
					txt:text(v.name)
					btn:setBright(not v.isSelected)
					node:onClick(functools.partial(list.itemClick, k))
					if v.isSelected then
						text.addEffect(txt, {glow = {color = ui.COLORS.GLOW.WHITE}, color = ui.COLORS.NORMAL.WHITE})
					else
						text.addEffect(txt, {color = ui.COLORS.NORMAL.RED})
					end
				end,
			},
			handlers = {
				itemClick = bindHelper.self("onChangePage"),
			},
		},
	},
	["cardPanel1"] = "cardPanel1",
	["cardPanel2"] = "cardPanel2",
	["cardPanel2.card1"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onFragClick")}
		}
	},
	["cardPanel2.btnFrags"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onUniversalFragClick")}
		}
	},
	["cardPanel2.btnFrags.textNote"] = {
		binds = {
			event = "effect",
			data = {color = ui.COLORS.NORMAL.WHITE, glow = {color = ui.COLORS.GLOW.WHITE}},
		},
	},

	["barPanel"] = "barPanel",
	["barPanel.myFrags"] = "myFrags",
	["barPanel.needFrags"] = "needFrags",
	["barPanel.bar"] = "slider",
	["barPanel.subBtn"] = {
		varname = "subBtn",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onReduceClick")}
		}
	},
	["barPanel.addBtn"] = {
		varname = "addBtn",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onAddClick")}
		}
	},
	["combTipPos"] = "combTipPos",
	["changeBtn"] = {
		varname = "changeBtn",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onChangeClick")}
		}
	},
	["changeBtn.title"] = {
		varname = "btnTxt",
		binds = {
			event = "effect",
			data = {color = ui.COLORS.NORMAL.WHITE, glow = {color = ui.COLORS.GLOW.WHITE}},
		},
	},

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
			methods = {ended = bindHelper.self("onUniversalFragClick")}
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
	["selectPanel.bg.bgIcon"] = "bgIcon",
	["textTips"] = "textTips",
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
							cardId = v.id,
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
					node:get('textPanel'):visible(v.battleType ~= nil)
					if v.battleType then
						if ui.CARD_USING_TXTS[v.battleType] then
							local txt = node:get('textPanel'):get('text')
							txt:text(gLanguageCsv[ui.CARD_USING_TXTS[v.battleType]])
							uiEasy.addTextEffect1(txt)
						end
					end
					adapt.oneLinePos(node:get("textFightNote"), node:get("textFight"))
					node:get("mask"):visible(v.status ~= 0)
					node:get("iconSelect"):visible(v.selectState == true)
					node:setTouchEnabled(v.status == 0)
					if v.canSelect == false and v.selectState == false then
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
}
function CardStarChangeSkillView:onCreate(dbHandler)
	self.selectDbId = dbHandler()
	self.chipBarPercent = idler.new(0)
	self.chipNum = idler.new(0)
	self.chipNeed = idler.new(0)
	self.needCash = idler.new(0)
	self.selectPanelState = idler.new(false)
	self.cardInfos = idlers.new()
	self.selectIdx = idler.new()
	self.costNum = idler.new(0)	--精灵兑换 消耗精灵个数
	self.getNum = idler.new(0) --精灵兑换 获得极限点个数
	self.selectEpNum = idler.new(0) --选择兑换极限点的数量
	self.selectedFragId = idler.new(0)--选择的碎片ID
	self:initModel()
	--页签数据
	local tabDatas = {}
	local cardId = self.cardId:read()
	local tabDatas = {{name = gLanguageCsv.cardChange, isSelected = false},{name = gLanguageCsv.fragChange, isSelected = false},}

	self.tabIdx = idler.new(1)
	--卡牌信息
	local cardMarkCfg = csv.cards[csv.cards[cardId].cardMarkID]
	local starSkillSeqID = cardMarkCfg.starSkillSeqID
	local cardExchangeRate = csv.card_star_skill[starSkillSeqID].cardExchangeRate
	self.fragExchangeRate =  csv.card_star_skill[starSkillSeqID].fragExchangeRate
	local universalCards = csv.card_star_skill[starSkillSeqID].universalCards

	--精灵兑换
	idlereasy.any({self.costNum, self.tabIdx, self.getNum}, function(_, costNum, tabIdx, getNum)
		local cardPanel = self.cardPanel1
		cardPanel:setVisible(tabIdx == 1)
		local cardCsv = csv.cards[cardId]
		local unitCsv = csv.unit[cardCsv.unitID]
		local quality = dataEasy.getCfgByKey(csv.cards[cardId].fragID).quality
		local textColor = ui.COLORS.QUALITY[quality]
		if tabIdx == 1 then
			local grayState = costNum < 1 and 1 or 0
			local bind1s = {
				class = "card_icon",
				props = {
					cardId = cardId,
					rarity = unitCsv.rarity,
					grayState = grayState,
					advance = unitCsv.advance,
					star = unitCsv.star,
					levelProps = {
						data = unitCsv.level,
					},
					onNode = function (panel)
						panel:setTouchEnabled(false)
						local bound = panel:box()
						panel:alignCenter(bound)
						uiEasy.setCardNum(panel, costNum, nil, quality)
						if costNum == 0 then
							panel:get("num"):text(costNum)
						end
					end,
				}
			}
			bind.extend(self, cardPanel:get("card1"), bind1s)
			cardPanel:get("card1.imgAdd"):visible(grayState == 1)
			uiEasy.setIconName("card", cardId, {node = cardPanel:get("textName1"), name = cardCsv.name, advance = cardCsv.advance, space = true})
			text.addEffect(cardPanel:get("textName1"), {color = textColor})
			bind.touch(self, cardPanel:get("card1"),  {methods = {ended =function()
				self.selectPanelState:set(true)
			end}})
			local key = "star_skill_points_"..cardCsv.cardMarkID
			local num = cardExchangeRate * getNum
			bind.extend(self, cardPanel:get("card2"), {
				class = "icon_key",
				props = {
					data = {
						key = key,
						num = num,
					},
					onNode = function (panel)
						if cardExchangeRate * getNum == 0 then
							panel:get("num"):text(0)
						end
					end,
				},
			})
			uiEasy.setIconName(key, num, {node = cardPanel:get("textName2")})
			text.addEffect(cardPanel:get("textName2"), {color = textColor})
			self.barPanel:hide()
		end
	end)
	--碎片兑换
	local canMaxNum = 0--可转换的最大数量
	idlereasy.any({self.selectedFragId, self.selectEpNum, self.tabIdx, self.frags}, function(_, selectedFragId, selectEpNum, tabIdx, frags)
		local cardPanel = self.cardPanel2
		cardPanel:setVisible(tabIdx == 2)
		local cardCsv = csv.cards[cardId]
		local unitCsv = csv.unit[cardCsv.unitID]
		local quality = dataEasy.getCfgByKey(csv.cards[cardId].fragID).quality
		local textColor = ui.COLORS.QUALITY[quality]
		if tabIdx == 2 then
			--碎片兑换
			local changeNum = 0
			if selectedFragId > 0 then
				changeNum = dataEasy.getNumByKey(selectedFragId)
				local bind1s = {
					class = "icon_key",
					props = {
						data = {
							key = selectedFragId,
							num = changeNum,
						},
						onNode = function(node)
							node:setTouchEnabled(false)
						end,
					},
				}
				cardPanel:get("textName1"):text(uiEasy.setIconName(selectedFragId))
				bind.extend(self, cardPanel:get("card1.icon"), bind1s)
				text.addEffect(cardPanel:get("textName1"), {color = textColor})
			else
				cardPanel:get("textName1"):text(gLanguageCsv.selectFragment)
				text.addEffect(cardPanel:get("textName1"), {color = ui.COLORS.NORMAL.DEFAULT})
			end
			cardPanel:get("card1.imgAdd"):visible(selectedFragId == 0)
			cardPanel:get("card1.icon"):visible(selectedFragId > 0)

			local key = "star_skill_points_"..cardCsv.cardMarkID
			local num = selectEpNum
			bind.extend(self, cardPanel:get("card2"), {
				class = "icon_key",
				props = {
					data = {
						key = key,
						num = math.max(num, 1),
					},
				},
			})
			uiEasy.setIconName(key, num, {node = cardPanel:get("textName2")})
			text.addEffect(cardPanel:get("textName2"), {color = textColor})

			canMaxNum = changeNum
			--设置滑动条
			if not self.slider:isHighlighted() then
				local num = math.ceil(selectEpNum/canMaxNum*100)
				self.slider:setPercent(num)
				if canMaxNum == 0 then
					self.slider:setTouchEnabled(false)
				else
					self.slider:setTouchEnabled(true)
				end
			end
			--设置滑动条上边的显示数量
			self.barPanel:show()
			self.needFrags:text("/"..canMaxNum)
			self.myFrags:text(selectEpNum)
			adapt.oneLineCenterPos(cc.p(self.barPanel:size().width/2, self.myFrags:y()), {self.myFrags, self.needFrags})
			--加减按钮
			uiEasy.setBtnShader(self.addBtn, nil, selectEpNum + self.fragExchangeRate <= canMaxNum  and 1 or 2)
			uiEasy.setBtnShader(self.subBtn, nil, selectEpNum > 0 and 1 or 2)
		end
	end)
	self.slider:setPercent(0)
	self.slider:addEventListener(function(sender,eventType)
		if eventType == ccui.SliderEventType.percentChanged then
			local percent = sender:getPercent()
			local num = math.ceil(canMaxNum * percent / 100)
			num = math.floor(num/self.fragExchangeRate)*self.fragExchangeRate
			self.selectEpNum:set(num)
		end
	end)
	-- tab界面显示
	self.tabDatas = idlers.newWithMap(tabDatas)
	self.tabIdx:addListener(function(val, oldval, idler)
		if self.tabDatas:atproxy(oldval) then
			self.tabDatas:atproxy(oldval).isSelected = false
		end
		if self.tabDatas:atproxy(val) then
			self.tabDatas:atproxy(val).isSelected = true
		end
		--合成提示文本
		local str = ""
		if val == 1 then
			local cardCsv = csv.cards[cardId]
			local unitCsv = csv.unit[cardCsv.unitID]
			local quality = dataEasy.getCfgByKey(csv.cards[cardId].fragID).quality
			local textColor = ui.QUALITYCOLOR[quality]
			local rarity = csv.unit[cardCsv.unitID].rarity
			str = string.format(gLanguageCsv.starSkillCardChangeTips, textColor..gLanguageCsv["rarityCard"..(rarity-1)], cardExchangeRate)
		else
			str = string.format(gLanguageCsv.starSkillFragChangeTips, self.fragExchangeRate)
		end
		self.combTipPos:removeChildByName("richTxt")
		rich.createByStr(str, 40)
			:anchorPoint(0.5, 0.5)
			:addTo(self.combTipPos, 6, "richTxt")
		self.btnTxt:text(gLanguageCsv.spaceExchange)
	end)

	--精灵选择界面
	idlereasy.when(self.frags,function (_, frags)
		self:setFragsPanel()
	end)
	idlereasy.when(self.cards,function (_, cards)
		self:setCardDatas(cards,universalCards)
	end)

	idlereasy.when(self.selectIdx, function(_, selectIdx)
		self.textNum:text("0")
		if self.cardInfos:atproxy(selectIdx) then
			local cardData = self.cardInfos:atproxy(selectIdx)
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
			self.textNum:text(selectNum)
			for i = 1, self.cardInfos:size() do
				local cardInfos = self.cardInfos:atproxy(i)
				cardInfos.canSelect = true
			end
		end
	end)

	if matchLanguage({"en"}) then
		adapt.setTextAdaptWithSize(self.textTips, {size = cc.size(800, 120), vertical = "center"})
	end
	Dialog.onCreate(self)
end

function CardStarChangeSkillView:initModel()
	self.cards = gGameModel.role:getIdler("cards")
	self.cardCapacity = gGameModel.role:getIdler("card_capacity")--背包容量
	self.frags = gGameModel.role:getIdler("frags")
	idlereasy.when(self.selectDbId,function (_, selectDbId)
		self.costCardIDs = {}
		local card = gGameModel.cards:find(selectDbId)
		self.cardId = idlereasy.assign(card:getIdler("card_id"), self.cardId)
		self.star = idlereasy.assign(card:getIdler("star"), self.star)
	end)
end

function CardStarChangeSkillView:onAddClick()
	self.selectEpNum:set(self.selectEpNum:read() + self.fragExchangeRate)
end

function CardStarChangeSkillView:onReduceClick()
	self.selectEpNum:set(self.selectEpNum:read() - self.fragExchangeRate)
end
--切换页签
function CardStarChangeSkillView:onChangePage(list, k)
	self.tabIdx:set(k)
end
function CardStarChangeSkillView:onChangeClick()
	if self.tabIdx:read() == 1 then
		if #self.costCardIDs == 0 then
			gGameUI:showTip(string.format(gLanguageCsv.pleaseSelectNumber, gLanguageCsv.starSkillExchange))
			return
		end
		--精灵兑换
		gGameApp:requestServer("/game/card/star/skill/card/exchange",function (tb)
			gGameUI:showGainDisplay(tb)
			self.costNum:set(0)
			self.getNum:set(0)
			self.costCardIDs = {}
		end, self.selectDbId:read(), self.costCardIDs)
	else
		if self.selectedFragId:read() == 0 then
			gGameUI:showTip(string.format(gLanguageCsv.selectFragment))
			return
		end
		if self.selectEpNum:read() == 0 then
			gGameUI:showTip(string.format(gLanguageCsv.pleaseSelectNumber, gLanguageCsv.starSkillExchange))
			return
		end
		-- 碎片兑换
		gGameApp:requestServer("/game/card/star/skill/frag/exchange",function (tb)
			gGameUI:showGainDisplay(tb)
			self.selectEpNum:set(0)
			self.slider:setPercent(0)
			self.selectedFragId:set(0)
		end, self.selectDbId:read(), self.selectedFragId:read(), self.selectEpNum:read())
	end
end

--合成按钮
function CardStarChangeSkillView:onCombClick()
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
--万能碎片
function CardStarChangeSkillView:onUniversalFragClick()
	gGameUI:stackUI("city.card.star_changefrags", nil, nil, self.selectDbId:read())
end

--加号按钮获取途径
function CardStarChangeSkillView:onGainWayClick()
	local fragsId = csv.cards[self.cardId:read()].fragID
	local fragCsv = csv.fragments[fragsId]
	local chipNeedNum = fragCsv.combCount
	gGameUI:stackUI("common.gain_way", nil, nil, fragsId, nil, chipNeedNum)
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

--设置碎片面板
function CardStarChangeSkillView:setFragsPanel()
	local fragID = csv.cards[self.cardId:read()].fragID
	local fragCsv = csv.fragments[fragID]
	local chipNeedNum = fragCsv.combCount
	local myFragsNum = dataEasy.getNumByKey(fragID)
	--fragIcon
	bind.extend(self, self.selectPanel:get("iconPanel"), {
		class = "icon_key",
		props = {
			data = {
				key = fragID,
				num = myFragsNum
			},
			onNode = function(panel)
				panel:setTouchEnabled(false)
					:scale(0.9)
			end
		}
	})

	self.chipNum:set(myFragsNum)
	self.chipNeed:set("/"..chipNeedNum)
	local percent = cc.clampf(myFragsNum / chipNeedNum * 100, 0, 100)
	self.chipBarPercent:set(percent)
end

--点击确定
function CardStarChangeSkillView:onSureClick()
	self.costCardIDs = {}
	local totalGet = 0
	for i,v in self.cardInfos:pairs() do
		local v = v:proxy()
		if v.selectState then
			table.insert(self.costCardIDs, v.dbid)
			totalGet = totalGet + getEp(v)
		end
	end
	self.costNum:set(#self.costCardIDs)
	self.getNum:set(totalGet)
	self.selectPanelState:set(false)
end
--点击空白
function CardStarChangeSkillView:onSelectPanelClick()
	self.selectPanelState:set(false)
end

--设置卡牌数据
function CardStarChangeSkillView:setCardDatas(cards,universalCards)
	local cardCsv = csv.cards[self.cardId:read()]
	self.selectNum = 0
	self.selectIdx:set(0)

	local cardMarkID = csv.cards[self.cardId:read()].cardMarkID
	local hash = dataEasy.inUsingCardsHash()
	if universalCards then
		universalCards = itertools.map(universalCards, function(k, v) return v, k end)
	else
		universalCards = {}
	end
	local cardInfos = {}
	for i,v in pairs(cards) do
		local card = gGameModel.cards:find(v)
		if card then
			local cardData = card:read("card_id", "name","fighting_point","locked",  "level", "star", "advance")
			local cardCsv = csv.cards[cardData.card_id]
			local unitCsv = csv.unit[cardCsv.unitID]
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
					-- status 0可消耗 1锁定 2训练中 3队伍中 4星级限制
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

--点击选择卡牌
function CardStarChangeSkillView:onCardItemClick(list, k, v)
	local card = gGameModel.cards:find(v.dbid)
	local baseStar = card:read("getstar")
	if v.selectState == false and (v.star > baseStar or v.level > 1 or v.advance > 1 or self:getDevelopState(v.dbid)) then
		gGameUI:showDialog({content = gLanguageCsv.starSkillChangeTips, cb = function()
			self.selectIdx:set(k.k, true)
		end, btnType = 2, isRich = true})
	else
		self.selectIdx:set(k.k, true)
	end
end

function CardStarChangeSkillView:getDevelopState(dbid)
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

function CardStarChangeSkillView:onFragClick()
	local params = {selectedFragId = self.selectedFragId, cardId = self.cardId:read()}
	gGameUI:stackUI("city.card.star_selectfrag", nil, nil, params)
end

return CardStarChangeSkillView
