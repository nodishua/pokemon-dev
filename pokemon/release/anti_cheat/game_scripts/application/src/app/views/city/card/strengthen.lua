local zawakeTools = require "app.views.city.zawake.tools"

local ViewBase = cc.load("mvc").ViewBase
local CardStrengthenView = class("CardStrengthenView", ViewBase)

local STATE = {
	STRENGTHEN = 1,
	DECORATION = 2,
}

local totalSpecialTag =
{
	"advance",
	"effortValue",
	"equipStar",
	"equipStrengthen",
	"equipAwake",
	"equipSignet",
	"star",
	"skill",
	"nvalue",
	"cardFeel",
	"cardDevelop",
	"gemFreeExtract",
	"canZawake",
}

local starSpecialTag =
{
	"star",
}

local TAB_DATA = {
	[1] = {
		{
			key = "attribute",
			name = gLanguageCsv.attribute,
			viewName = "city.card.attribute"
		}, {
			key = "nvalue",
			name = gLanguageCsv.nvalue,
			viewName = "city.card.nvalue",
			redHint = {
				class = "red_hint",
				props = {
					listenData = {
						selectDbId = bindHelper.parent("selectDbId"),
					},
					specialTag = "nvalue",
					onNode = function (node)
						node:xy(266, 120)
							:z(10)
					end
				}
			},
			unlockKey = "cardNValueRecast",
		}, {
			key = "advance",
			name = gLanguageCsv.advance,
			viewName = "city.card.advance",
			redHint = {
				class = "red_hint",
				props = {
					listenData = {
						selectDbId = bindHelper.parent("selectDbId"),
					},
					specialTag = "advance",
					onNode = function (node)
						node:xy(266, 120)
							:z(10)
					end
				}
			},
		}, {
			key = "star",
			name = gLanguageCsv.star,
			viewName = "city.card.star",
			redHint = {
				class = "red_hint",
				props = {
					listenData = {
						selectDbId = bindHelper.parent("selectDbId"),
					},
					specialTag = "star",
					onNode = function (node)
						node:xy(266, 120)
							:z(10)
					end
				}
			},
		}, {
			key = "skill",
			name = gLanguageCsv.skill,
			viewName = "city.card.skill",
			redHint = {
				class = "red_hint",
				props = {
					listenData = {
						selectDbId = bindHelper.parent("selectDbId"),
					},
					specialTag = "skill",
					onNode = function (node)
						node:xy(266, 120)
							:z(10)
					end
				}
			}
		}, {
			key = "effortvalue",
			name = gLanguageCsv.effortvalue,
			viewName = "city.card.effortvalue",
			unlockKey = "cardEffort",
			redHint = {
				class = "red_hint",
				props = {
					listenData = {
						selectDbId = bindHelper.parent("selectDbId"),
					},
					specialTag = "effortValue",
					onNode = function (node)
						node:xy(266, 120)
							:z(10)
					end
				}
			},
		},{
			key = "ability",
			name = gLanguageCsv.ability,
			viewName = "city.card.ability.view",
			unlockKey = "cardAbility",
		}, {
			key = "chip",
			name = gLanguageCsv.chip,
			viewName = "city.card.chip",
			unlockKey = "chip",
			redHint = {
				class = "red_hint",
				props = {
					specialTag = "cityChipFreeExtract",
					onNode = function (node)
						node:xy(266, 120)
							:z(10)
					end
				}
			},
		},
	},
	[2] = {
		{
			key = "equipStrengthen",
			name = gLanguageCsv.equipStrengthen,
			viewName = "city.card.equip.strengthen",
			redHint = {
				class = "red_hint",
				props = {
					listenData = {
						selectDbId = bindHelper.parent("selectDbId"),
					},
					specialTag = "equipStrengthen",
					onNode = function (node)
						node:xy(270, 118)
							:z(10)
					end
				}
			},
		}, {
			key = "starUp",
			name = gLanguageCsv.starUp,
			viewName = "city.card.equip.star",
			unlockKey = "equipStarAdd",
			redHint = {
				class = "red_hint",
				props = {
					listenData = {
						selectDbId = bindHelper.parent("selectDbId"),
					},
					specialTag = "equipStar",
					onNode = function (node)
						node:xy(270, 118)
							:z(10)
					end
				}
			},
		}, {
			key = "awake",
			name = gLanguageCsv.awake,
			viewName = "city.card.equip.awake",
			unlockKey = "equipAwak",
			redHint = {
				class = "red_hint",
				props = {
					listenData = {
						selectDbId = bindHelper.parent("selectDbId"),
					},
					specialTag = "equipAwake",
					onNode = function (node)
						node:xy(270, 118)
							:z(10)
					end
				}
			},
		}, {
			key = "signet",
			name = gLanguageCsv.signet,
			viewName = "city.card.equip.signet",
			unlockKey = "equipSignet",
			redHint = {
				class = "red_hint",
				props = {
					listenData = {
						selectDbId = bindHelper.parent("selectDbId"),
					},
					specialTag = "equipSignet",
					onNode = function (node)
						node:xy(270, 118)
							:z(10)
					end
				}
			},
		},
	},
}
local STATES_TAB = {}
for _, tab in pairs(STATE) do
	for _, v in pairs(TAB_DATA[tab]) do
		STATES_TAB[v.key] = tab
	end
end

local CONDITIONS = {
	{name = gLanguageCsv.fighting, attr = "fight"},
	{name = gLanguageCsv.level, attr = "level"},
	{name = gLanguageCsv.rarity, attr = "rarity"},
	{name = gLanguageCsv.star, attr = "star"},
	{name = gLanguageCsv.getTime, attr = "getTime"}
}
local STATE_ACTION = {"standby_loop", "attack", "win_loop", "run_loop", "skill1"}

local LEFT_BTN_DATAS = {{
		key = "develop",
		icon = "city/card/system/attribute/icon_evolution.png",
		txt = gLanguageCsv.levelUp,
		click = "onEvoClick",
	}, {
		key = "feel",
		icon = "city/card/system/attribute/icon_liking.png",
		txt = gLanguageCsv.like,
		unlockKey = "cardLike",
		click = "onSkinClick",
	}, {
		key = "reborn",
		icon = "city/card/system/attribute/icon_renascence.png",
		txt = gLanguageCsv.reborn,
		unlockKey = "cardReborn",
		click = "onRebornClick",
	}, {
		key = "swap",
		icon = "city/card/system/attribute/icon_inheritance.png",
		txt = gLanguageCsv.inherit,
		unlockKey = "cardSwap",
		click = "onSwapClick",
	},
	{
		key = "skin",
		icon = "city/card/system/attribute/icon_fashionabledress.png",
		txt = gLanguageCsv.skin,
		unlockKey = "skin",
		click = "onCardSkinClick",
	},
}
local LEFT_BTN_MARGINS = {
	[2] = 80,
	[3] = 40,
	[4] = 30,
	[5] = 10,
}

CardStrengthenView.RESOURCE_FILENAME = "card_strengthen.json"
CardStrengthenView.RESOURCE_BINDING = {
	["btnItem"] = "btnItem",
	["right.list"] = {
		varname = "msgList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("tabDatas"),
				item = bindHelper.self("btnItem"),
				curState = bindHelper.self("curState"),
				itemAction = {isAction = true},
				onItem = function(list, node, k, v)
					node:name(v.key)
					local clickBtn = node:get("btnClick")
					local normalBtn = node:get("btnNormal")
					clickBtn:visible(v.select or false)
					normalBtn:visible(not v.select)
					clickBtn:get("textNote"):text(v.name)
					normalBtn:get("textNote"):text(v.name)
					adapt.setTextScaleWithWidth(clickBtn:get("textNote"), nil, 240)
					if not matchLanguage({"cn", "tw"}) then
						-- 美术要求 英文等未选中状态放大
						normalBtn:get("textNote"):scale(clickBtn:get("textNote"):scale() * 1.1)
					else
						normalBtn:get("textNote"):scale(clickBtn:get("textNote"):scale())
					end
					if v.redHint then
						list.state = v.select ~= true
						bind.extend(list, normalBtn, v.redHint)
					end
					uiEasy.updateUnlockRes(v.unlockKey, node, {justRemove = not v.unlockKey, pos = cc.p(240, 110)})
						:anonyOnly(list, list:getIdx(k))
					bind.touch(list, normalBtn, {methods = {ended = functools.partial(list.clickCell, k, v)}})
				end,
				asyncPreload = 9,
			},
			handlers = {
				clickCell = bindHelper.self("onTabItemClick"),
			},
		},
	},
	["left.btnItem"] = "leftBtnItem",
	["left.btnList"] = {
		varname = "btnList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("leftBtnDatas"),
				item = bindHelper.self("leftBtnItem"),
				margin = bindHelper.self("leftBtnMargin"),
				onItem = function(list, node, k, v)
					node:name(v.key)
					local childs = node:multiget("imgIcon", "textNote")
					childs.textNote:text(v.txt)
					childs.imgIcon:texture(v.icon)
					uiEasy.updateUnlockRes(v.unlockKey, node, {justRemove = not v.unlockKey, pos = cc.p(120, 120)})
						:anonyOnly(list, list:getIdx(k))
					if v.key == "develop" then
						bind.extend(list, node:get("imgIcon"), {
							class = "red_hint",
							props = {
								state = true,
								listenData = {
									selectDbId = bindHelper.parent("selectDbId"),
								},
								specialTag = "cardDevelop",
								onNode = function (node)
									node:xy(120, 110)
								end
							}
						})
					end
					if v.key == "feel" then
						bind.extend(list, node:get("imgIcon"), {
							class = "red_hint",
							props = {
								state = true,
								listenData = {
									selectDbId = bindHelper.parent("selectDbId"),
								},
								specialTag = "cardFeel",
								onNode = function (node)
									node:xy(120, 110)
								end
							}
						})
					end
					text.addEffect(childs.textNote, {outline = {color = ui.COLORS.NORMAL.WHITE}})
					bind.touch(list, node, {methods = {ended = functools.partial(list.clickCell, v)}})
				end,
				onAfterBuild = function (list)
					list:setItemAlignCenter()
				end
			},
			handlers = {
				clickCell = bindHelper.self("onLeftBtnItemClick"),
			},
		},
	},
	["item"] = "item",
	["cardPanel.list"] = {
		varname = "cardList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("cardDatas"),
				item = bindHelper.self("item"),
				padding = 6,
				addLimit = true,
				-- backupCached = false,
				dataOrderCmpGen = bindHelper.self("onSortCardList", true),
				onItem = function(list, node, k, v)
					node:setName("item" .. list:getIdx(k))
					local size = node:size()
					bind.extend(list, node, {
						class = "card_icon",
						props = {
							unitId = v.unitId,
							advance = v.advance,
							star = v.star,
							rarity = v.rarity,
							lock = v.lock,
							selected = v.isSel,
							levelProps = {
								data = v.level,
							},
							params = {
								starScale = 0.85,
								starInterval = 13,
							},
							onNode = function(panel)
								panel:xy(65, 0)
									:scale(1.12)
								panel:get("frame"):scale(1.07)
								panel:get("rarity")
									:align(cc.p(0.5, 0.5))
									:xy(38, 162)
									:scale(0.7)
								panel:get("imgSel")
									:scale(0.94)
								local size = panel:size()
								local lock = panel:get("lock")
								lock:texture("common/btn/icon_s1.png")
								lock:x(lock:x() - size.width - 10)
								lock:y(lock:y() - 30)
								lock:scale(1/1.12)
							end,
						}
					})


					bind.extend(list, node:get("redHint"), {
						class = "red_hint",
						props = {
							specialTag = v.battle == 1 and totalSpecialTag or starSpecialTag,
							listenData = {
								selectDbId = v.dbid,
							},
						}
					})

					local battle = node:get("battle") and 1 or 2
					node:get("imgFlag"):visible(v.battle == 1)
					bind.touch(list, node, {methods = {ended = function()
						return list.clickCell(k, v)
					end}})
				end,
				asyncPreload = 6,
				preloadCenter = bindHelper.self("selectDbId"),
			},
			handlers = {
				clickCell = bindHelper.self("onCardItemClick"),
			},
		},
	},
	["attrItem"] = "attrItem",
	["left"] = "left",
	["left.attrList"] = {
		varname = "attrList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("attrDatas"),
				item = bindHelper.self("attrItem"),
				onItem = function(list, node, k, v)
					node:get("imgIcon"):texture(ui.ATTR_ICON[v])
				end,
			},
		},
	},
	["cardPanel"] = {
		binds = {
			event = "extend",
			class = "sort_menus",
			props = {
				data = bindHelper.self("sortDatas"),
				width = 309,
				expandUp = true,
				btnClick = bindHelper.self("onSortMenusBtnClick", true),
				onNode = function(node)
					node:xy(-1103, -475):z(18)
				end,
			},
		}
	},
	["left.imgFlag"] = "imgFlag",
	["left.textName"] = "cardNameTxt",
	["left.imgNameBG"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onChangeNameClick")}
		},
	},
	["starItem"] = "starItem",
	["left.btnLock"] = {
		varname = "btnLock",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onLockClick")}
		}
	},
	["left.starList"] = {
		varname = "starList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("starDatas"),
				item = bindHelper.self("starItem"),
				onItem = function(list, node, k, v)
					node:get("imgStar"):texture(v.icon)
				end,
				asyncPreload = 6,
			}
		},
	},
	["left.heroNode"] = {
		varname = "heroNode",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onCardClick")}
		},
	},
	["left.btnHeldItem1"] = "btnHeldItemBg",
	["left.btnHeldItem"] = {
		varname = "btnHeldItem",
		binds = {
			{
				event = "touch",
				methods = {ended = bindHelper.self("onAddClick")}
			},
			{
				event = "extend",
				class = "red_hint",
				props = {
					listenData = {
						selectDbId = bindHelper.self("selectDbId"),
					},
					specialTag = {
						"heldItem",
						"heldItemLevelUp",
						"heldItemAdvanceUp",
					},
					onNode = function (node)
						node:xy(144, 140)
					end
				}
			},
		},
	},
	["left.btnHeldItem.imgBG"] = {
		varname = "heldItemImgBg",
		binds = {
			event = "texture",
			idler = bindHelper.self("heldItemBg")
		},
	},
	["left.btnHeldItem.imgIcon"] = {
		varname = "heleItemIcon",
		binds = {
			event = "texture",
			idler = bindHelper.self("heldItemIcon")
		},
	},
	["left.btnEquip.textNote"] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.NORMAL.WHITE}},
		},
	},
	["left.zawake"] = {
		varname = "btnZawake",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onZawakeClick")}
		},
	},
	["left.gem"] = {
		varname = "btnGem",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onGemClick")}
		},
	},
	["left.manuals.txt"] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.NORMAL.WHITE}},
		},
	},
	["left.manuals"] = {
		varname = "manuals",
		binds = {
			{
				event = "touch",
				methods = {ended = bindHelper.self("onManualsClick")}
			},
			{
				event = "extend",
				class = "red_hint",
				props = {
					specialTag = "battleManuals",
					onNode = function(node)
						node:xy(105, 102)
					end,
				}
			}
		}
	},
	["left.gem.btn"] = {
		binds = {
			event = "extend",
			class = "red_hint",
			props = {
				specialTag = "gemFreeExtract",
				listenData = {
					selectDbId = bindHelper.self("selectDbId"),
				},
				onNode = function(node)
					node:xy(145, 132)
					node:scale(0.8)
				end,
			},
		},
	},
	["left.zawake.btn"] = {
		binds = {
			event = "extend",
			class = "red_hint",
			props = {
				specialTag = "canZawake",
				listenData = {
					selectDbId = bindHelper.self("selectDbId"),
				},
				onNode = function(node)
					node:xy(145, 132)
					node:scale(0.8)
				end,
			},
		},
	},
	["left.gem.textNote"] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.NORMAL.WHITE}},
		},
	},
	["left.zawake.textNote"] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.NORMAL.WHITE}},
		},
	},
	["left.btnEquip"] = {
		varname = "btnEquip",
		binds = {
			{
				event = "touch",
				methods = {ended = bindHelper.self("onEquipClick")}
			},
			{
				event = "extend",
				class = "red_hint",
				props = {
					state = true,
					listenData = {
						selectDbId = bindHelper.self("selectDbId"),
					},
					specialTag = {
						"equipStar",
						"equipStrengthen",
						"equipAwake",
						"equipSignet",
					},
					onNode = function (node)
						node:xy(190, 200)
					end
				}
			}
		},
	},
	["left.textFight"] = "textFight",
	["left.textFightPoint"] = {
		varname = "textFightPoint",
		binds = {
			event = "text",
			idler = bindHelper.self("fightNum"),
			method = function(val)
				return string.format("%s%s%s", gLanguageCsv.playmindgames, ": ", val)
			end
			-- class = "text_atlas",
			-- props = {
			-- 	data = bindHelper.self("fightNum"),
			-- 	pathName = "zhanli",
			-- 	align = "center",
			-- },
		},
	},
}
CardStrengthenView.RESOURCE_STYLES = {
	full = true,
}

function CardStrengthenView:onCreate(selectTabKey, selectDbId, closeHandler)
	self.closeHandler = closeHandler
	self:initModel()
	self.heldItemListen = dataEasy.getListenShow(gUnlockCsv.heldItem)

	if not selectDbId then
		selectDbId = self:getSelectedCardDBID()
	end
	self.dressState = idler.new(false)
	self.selectDbId = idler.new(self._selectDbId or selectDbId)
	self.cardActionState = idler.new(1)

	local curState = STATES_TAB[selectTabKey] or STATE.STRENGTHEN
	self.curState = idler.new(self._curState or curState)

	-- 左边按钮数据(需判断unlock)
	self.leftBtnMargin = idler.new(0)
	self.leftBtnDatas = idlertable.new({})
	-- self:updateLeftBtnDatas()

	-- 标签数据(需判断unlock)
	self.tabDatas = idlers.new()
	self:initTabDatasListeners()
	self:updateTabDatas()
	self.btnGem:get("textNote"):text(gLanguageCsv.gemTitle)
	uiEasy.updateUnlockRes(gUnlockCsv.cardUnlock, self.btnLock, {pos = cc.p(90, 90)})
	uiEasy.updateUnlockRes(gUnlockCsv.equip, self.btnEquip, {pos = cc.p(140, 170)})
	uiEasy.updateUnlockRes(gUnlockCsv.heldItem, self.btnHeldItem, {pos = cc.p(120, 110)})
	uiEasy.updateUnlockRes(gUnlockCsv.gem, self.btnGem, {pos = cc.p(140, 170)})
	uiEasy.updateUnlockRes(gUnlockCsv.zawake, self.btnZawake, {pos = cc.p(155, 165)})
	dataEasy.getListenShow(gUnlockCsv.cardUnlock, function(isShow)
		self.btnLock:visible(isShow)
	end)
	idlereasy.any({dataEasy.getListenShow(gUnlockCsv.gem), self.curState}, function(_, isShow, curState)
		self.btnGem:visible(isShow and curState ~= STATE.DECORATION)
	end)
	self.heldItemBg = idler.new("common/box/box_carry.png")
	self.heldItemIcon = idler.new("city/card/helditem/icon_jiahao.png")
	local resortTimes = 0
	idlereasy.any({self.heldItemListen, self.curState, gGameModel.role:getIdler("items")}, function(_, isShow, curState)
		resortTimes = resortTimes + 1
		performWithDelay(self, function()
			if resortTimes > 0 then
				resortTimes = 0
				if isShow and curState ~= STATE.DECORATION then
					self.btnHeldItem:visible(true)
					self.btnHeldItemBg:visible(true)
					local selDbId = self.selectDbId:read()
					local card = gGameModel.cards:find(selDbId)
					local heldItemID = card:read("held_item")
					self:onResetHeldItemIcon(heldItemID)
				else
					self.btnHeldItem:visible(false)
					self.btnHeldItemBg:visible(false)
				end
			end
		end, 0)
	end)
	self.manuals:visible(dataEasy.isShow(gUnlockCsv.battleManuals))

	if selectTabKey and not tonumber(selectTabKey) then
		local target = selectTabKey
		selectTabKey = nil
		for i,v in self.tabDatas:ipairs() do
			if v:proxy().key == target then
				selectTabKey = i
				break
			end
		end
	end
	selectTabKey = tonumber(selectTabKey) or 1
	self.selectTabKey = idler.new(self._selectTabKey or selectTabKey)
	self.selectTabPair = idlertable.new({
		state = self.curState:read(),
		idx = self.selectTabKey:read(),
	})

	--显示右侧面板，进战斗界面恢复
	self.rightTabView = {
		[STATE.STRENGTHEN] = {},
		[STATE.DECORATION] = {}
	}

	self.rightCurrIdx = self._rightCurrIdx or {
		[STATE.STRENGTHEN] = self.selectTabKey:read(),
		[STATE.DECORATION] = 1,
	}
	self.equipIndex = idler.new(1)

	self.curState:addListener(handler(self, "onCurStateChanged"))
	self.selectTabPair:addListener(handler(self, "onSelectPairChanged"))

	self.cardDatas = idlers.new()--卡牌数据

	--true是降序，false升序
	self.tabOrder = idler.new(true)
	self.seletSortKey = idler.new(1)
	self.sortDatas = idlertable.new(itertools.map(CONDITIONS, function(k, v) return v.name end))--排序数据

	self.cardsChanged = idler.new(true)
	idlereasy.any({self.battleCards, self.cards, self.cardsChanged},function (obj, battleCards, cards)
		-- 分解之后有可能选中的dbid被分解了 所以需要重新选择一遍
		local selDbId = self.selectDbId:read()
		if not selDbId or not itertools.include(cards, selDbId) then
			selDbId = self:getSelectedCardDBID()
			self.selectDbId:set(selDbId)
		end
		local hash = itertools.map(itertools.ivalues(battleCards), function(k, v) return v, k end)
		local selectCardIndex
		local tmpCardDatas = {}
		-- idlereasy.any 时序问题，两个值都变动，但 battleCards 这个先到了，cards 还是旧数据
		for k, dbid in ipairs(cards) do
			local card = gGameModel.cards:find(dbid)
			if card then
				local cardData = card:read("card_id", "unit_id","skin_id", "fighting_point", "level", "star", "advance", "locked", "name", "created_time", "equips", "effort_values")
				local battle = hash[dbid] and 1 or 2
				local cardCsv = csv.cards[cardData.card_id]
				local unitId = dataEasy.getUnitId(cardData.card_id, cardData.skin_id)
				local unitCsv = csv.unit[unitId]
				tmpCardDatas[dbid] = {
					id = cardData.card_id,
					markId = cardCsv.cardMarkID,
					name = cardData.name,
					unitId = unitId,
					num = 1,
					rarity = unitCsv.rarity,
					fight = cardData.fighting_point,
					level = cardData.level,
					star = cardData.star,
					getTime = cardData.created_time,
					dbid = dbid,
					advance = cardData.advance,
					lock = cardData.locked or false,
					battle = battle,
					isSel = selDbId == dbid,
					equips = cardData.equips,
					effortValue = cardData.effort_values
				}
			end
		end
		self.cardDatas:update(tmpCardDatas,function(v) return v.dbid end)
	end)

	idlereasy.view_defer(self, "any", {self.seletSortKey, self.tabOrder}, function (_, seletSortKey, tabOrder, cardDatas)
		dataEasy.tryCallFunc(self.cardList, "filterSortItems", not self.sortMenusClick)
	end)

	self.selectDbId:addListener(handler(self, "onSelectDbIdChanged"))

	-- 超进化 dbid 不变，cardId 变动，z觉醒开关更新
	idlereasy.any({dataEasy.getListenShow(gUnlockCsv.zawake), self.curState, self.selectDbId, self.cardId}, function(_, isShow, curState, selectDbId)
		-- 特殊 show 也要满足 servers 配置条件
		if isShow and curState ~= STATE.DECORATION and dataEasy.isInServer("zawake") then
			local zawakeID = self:getZawakeID(selectDbId)
			if zawakeID then
				self.btnZawake:show()
				return
			end
		end
		self.btnZawake:hide()
	end)

	self:initLeftBtnDatasListeners()

	self.cardSprite = nil
	local function changeCardRes(unitCfg)
		if self.cardSprite then
			self.cardSprite:removeFromParent()
		end
		local size = self.heroNode:getContentSize()
		self.cardSprite = widget.addAnimation(self.heroNode, unitCfg.unitRes, STATE_ACTION[1], 5)
			:xy(size.width/2, 0)
		self.cardSprite:scale(unitCfg.scaleU*3)
		self.cardSprite:setSkin(unitCfg.skin)
	end

	idlereasy.when(self.locked, function (_, lock)
		self.btnLock:get("lockImg"):texture(lock and "common/btn/btn_s.png" or "common/btn/btn_ks.png")
	end)

	self.starDatas = idlertable.new({})
	idlereasy.when(self.star, handler(self, "onCardStarChanged"))
	idlereasy.any({self.fightNum, self.level, self.advance}, function ( _, fightNum, level, advance)
		local selectCard = self.cardDatas:atproxy(self.selectDbId)
		selectCard.fightNum = fightNum
		selectCard.level = level
		selectCard.advance = advance
	end)

	self.attrDatas = idlers.newWithMap({})
	idlereasy.any({self.cardId, self.skinId}, functools.handler(self, "onCardUnitIDChanged", changeCardRes))

	idlereasy.when(self.cardActionState, function (_, cardState)
		self.cardSprite:setSpriteEventHandler()
		if cardState ~= 1 then
			local state = self.curState:read()
			local index = self.selectTabKey:read()
			if self.rightTabView[state][index] then
				--提高层级代码先注释掉
				-- local size = self.heroNode:getContentSize()
				-- local pos = gGameUI:getConvertPos(self.heroNode, self.rightTabView[state][index])
				-- self.cardSprite:retain()
				-- self.cardSprite:removeFromParent()
				-- self.cardSprite:addTo(self.rightTabView[state][index], 2)
				-- 	:xy(pos.x, pos.y)
				-- self.cardSprite:release()
				local size = self.heroNode:getContentSize()
				self.cardSprite:retain()
				self.cardSprite:removeFromParent()
				self.cardSprite:addTo(self.heroNode, 5)
					:xy(size.width/2, 0)
				self.cardSprite:release()
			end
			local count = 0
			self.cardSprite:setSpriteEventHandler(function(event, eventArgs)
				if cardState == 4  then
					count = count + 1
					if count > 5 then
						self.cardSprite:setSpriteEventHandler()
						self.cardActionState:set(1)
					end
				else
					self.cardSprite:setSpriteEventHandler()
					self.cardActionState:set(1)
				end

			end, sp.EventType.ANIMATION_COMPLETE)
		else
			local size = self.heroNode:getContentSize()
			self.cardSprite:retain()
			self.cardSprite:removeFromParent()
			self.cardSprite:addTo(self.heroNode, 5)
				:xy(size.width/2, 0)
			self.cardSprite:release()
		end
		if cardState == 4 then
			self.cardSprite:play(STATE_ACTION[cardState], false)
			for i = 2,5 do
				self.cardSprite:addPlay(STATE_ACTION[cardState])
			end
		else
			self.cardSprite:play(STATE_ACTION[cardState])
		end
		local cardCfg = csv.cards[self.cardId:read()]
		local soundsEffect = cardCfg.soundsEffect or {}
		if soundsEffect[STATE_ACTION[cardState]] then
			audio.playEffectWithWeekBGM(soundsEffect[STATE_ACTION[cardState]])
		end
	end)
	idlereasy.any({self.cardId,self.skinId, self.cardName, self.advance},function (_, cardId, skinId,name, advance)
		uiEasy.setIconName("card", cardId, {node = self.cardNameTxt, name = name, advance = advance, space = true})

		local v = self.cardDatas:atproxy(self.selectDbId)

		local cardCsv = csv.cards[cardId]
		local unitCsv = csv.unit[cardCsv.unitID]

		v.id = cardId
		v.rarity = unitCsv.rarity

		v.unitId = dataEasy.getUnitId(cardId, skinId)
		self:updateLeftBtnDatas()
	end)

	local pos = gGameUI:getConvertPos(self.left)
	self.effect = widget.addAnimation(self, "effect/shengji.skel", "effect", 3)
		:xy(pos.x, pos.y - 400)
		:hide()
	self.img = ccui.ImageView:create("battle/txt_pz.png")
		:addTo(self, 10)
		:scale(2)
		:xy(pos.x, pos.y + 100)
		:hide()
end

function CardStrengthenView:initModel()
	self.cards = gGameModel.role:getIdler("cards")
	self.battleCards = gGameModel.role:getIdler("battle_cards")
	self.roleLevel = gGameModel.role:getIdler("level")
end

function CardStrengthenView:onCleanup()
	self._selectDbId = self.selectDbId:read()
	self._selectTabKey = self.selectTabKey:read()
	self._curState = self.curState:read()
	self._rightCurrIdx = self.rightCurrIdx
	ViewBase.onCleanup(self)
end

function CardStrengthenView:onCurStateChanged(curState, prevState)
	if self.topView then
		gGameUI.topuiManager:removeView(self.topView)
	end
	self:updateTabDatas()
	self.btnEquip:visible(curState ~= STATE.DECORATION)
	self.btnList:visible(curState ~= STATE.DECORATION)

	if curState == STATE.DECORATION then
		self.topView = gGameUI.topuiManager:createView("default", self, {onClose = self:createHandler("onCloseDecoration")})
			:init({title = gLanguageCsv.accessories, subTitle = "ORNAMENTS"})
		if not self.equipView then
			self.equipView = gGameUI:createView("city.card.equip.view", self):init(self:createHandler("sendParamsEquip"))
		else
			self.equipIndex:set(1)
			self.equipView:show()
		end
	else
		self.topView = gGameUI.topuiManager:createView("default", self, {onClose = self:createHandler("onClose")})
			:init({title = gLanguageCsv.strengthen, subTitle = "STRENGTHEN"})
		if self.equipView then
			self.equipView:hide()
		end
	end

	local idx = self.rightCurrIdx[curState] or 1
	self.selectTabKey:set(idx)
	self.selectTabPair:set({
		state = curState,
		idx = idx,
	})
end

function CardStrengthenView:onSelectPairChanged(selected, old)
	local state = selected.state
	local idx = selected.idx
	-- print('!!! any', state, idx, dumps(old), dumps(selected))

	local oldidx = old and old.idx
	if old then
		local oldstate = old.state
		local oldview = self.rightTabView[oldstate][oldidx]
		if oldview then
			oldview:hide()
			if oldidx ~= idx or oldstate ~= state then
				self.rightTabView[oldstate][oldidx] = nil
				oldview:onClose()
			end
		end
	end

	local oldTabDatas = self.tabDatas:atproxy(oldidx)
	local curTabDatas = self.tabDatas:atproxy(idx)
	local viewName = curTabDatas.viewName
	local key = curTabDatas.key
	dataEasy.setTodayCheck(key, self.selectDbId:read())

	local view = self.rightTabView[state][idx]
	if not view and viewName then
		view = gGameUI:createView(viewName, self)
		self.rightTabView[state][idx] = view

		-- 适配处理，子界面相对中间块和右边块的中心
		if view:x() == 0 then
			adapt.centerWithScreen(nil, "right", nil, {
				{view, "pos", "center"},
			})
		end
		if state == STATE.DECORATION then
			view:init(self:createHandler("sendParamsEquip"))

		elseif idx == 1 or idx == 3 then
			view:init(self:createHandler("selectDbId"), self:createHandler("playAction"))

		elseif idx == 6 then
			-- 努力值培养10次的遮罩点击 cardList 和 msgList 才响应，其他地方无响应
			local validAreas = {}
			for _, node in pairs({self.cardList, self.msgList}) do
				local rect = node:box()
				local nodePos = node:parent():convertToWorldSpace(cc.p(rect.x, rect.y))
				rect.x = nodePos.x
				rect.y = nodePos.y
				table.insert(validAreas, rect)
			end
			view:init(self:createHandler("selectDbId"), validAreas)
		else
			view:init(self:createHandler("selectDbId"))
		end
	end

	if view then
		self.rightCurrIdx[state] = idx
		view:show()
	end

	if oldTabDatas then
		oldTabDatas.select = false
	end
	curTabDatas.select = true

	local cardState = self.cardActionState:read()
	if self.cardSprite and cardState ~= 1 and view then
		-- local pos = gGameUI:getConvertPos(self.heroNode, self.rightTabView[state][idx])
		local size = self.heroNode:getContentSize()
		self.cardSprite:retain()
		self.cardSprite:removeFromParent()
		self.cardSprite:addTo(self.heroNode, 2)
			:xy(size.width/2, 0)
			-- :xy(pos.x, pos.y)
		self.cardSprite:release()
		self.cardSprite:show()
	end
end

function CardStrengthenView:onSelectDbIdChanged(val, oldval)
	local oldCard = self.cardDatas:atproxy(oldval)
	if oldCard then
		oldCard.isSel = false
	end
	self.cardDatas:atproxy(val).isSel = true

	local curIdx = self.selectTabKey:read()
	local key = self.tabDatas:at(curIdx) and self.tabDatas:at(curIdx).key
	dataEasy.setTodayCheck(key, val)

	self:changeCard(val)
end

function CardStrengthenView:changeCard(selectDbId)
	local card = gGameModel.cards:find(selectDbId)
	gGameModel.cards:removeNewFlag(selectDbId)
	self.cardId = idlereasy.assign(card:getIdler("card_id"), self.cardId)
	self.fightNum = idlereasy.assign(card:getIdler("fighting_point"), self.fightNum)
	self.cardName = idlereasy.assign(card:getIdler("name"), self.cardName)
	self.unitId = idlereasy.assign(card:getIdler("unit_id"), self.unitId)
	self.skinId = idlereasy.assign(card:getIdler("skin_id"), self.skinId)
	self.star = idlereasy.assign(card:getIdler("star"), self.star)
	self.advance = idlereasy.assign(card:getIdler("advance"), self.advance)
	self.locked = idlereasy.assign(card:getIdler("locked"), self.locked)
	self.level = idlereasy.assign(card:getIdler("level"), self.level)
	local heldItemID = card:read("held_item")
	self.cardActionState:set(3, true)
	local unitCsv = dataEasy.getUnitCsv(self.cardId:read(), self.skinId:read())

	self.imgFlag:texture(ui.RARITY_ICON[unitCsv.rarity])

	self:onResetHeldItemIcon(heldItemID)

	self:updateLeftBtnDatas()
end

function CardStrengthenView:onCardStarChanged(_, star)
	local selectCard = self.cardDatas:atproxy(self.selectDbId)
	selectCard.star = star

	local starDatas = {}
	local starIdx = star - 6
	for i=1,6 do
		local icon = "common/icon/icon_star_d.png"
		if i <= star then
			icon = i <= starIdx and "common/icon/icon_star_z.png" or "common/icon/icon_star.png"
		end
		table.insert(starDatas, {icon = icon})
	end
	self.starDatas:set(starDatas)
end

function CardStrengthenView:onCardUnitIDChanged(changeCardRes, _, cardid,skinId)
	local attrDatas = {}
	local unit =  dataEasy.getUnitCsv(cardid, skinId)
	changeCardRes(unit)

	table.insert(attrDatas, unit.natureType)
	if unit.natureType2 then
		table.insert(attrDatas, unit.natureType2)
	end
	self.attrDatas:update(attrDatas)
end

function CardStrengthenView:initLeftBtnDatasListeners()
	local h = handler(self, "updateLeftBtnDatas")
	for k, v in ipairs(LEFT_BTN_DATAS) do
		if v.unlockKey then
			dataEasy.getListenUnlock(v.unlockKey, h)
		end
	end
end

function CardStrengthenView:updateLeftBtnDatas()
	local t = {}
	for k, v in ipairs(LEFT_BTN_DATAS) do
		local show = true
		if v.unlockKey then
			show = dataEasy.isShow(v.unlockKey)
		end

		if show and v.key == "skin" then
			if self.cardId  then
				show = dataEasy.isShowSkinIcon(self.cardId:read())
			else
				show = false
			end
		end

		if show then
			table.insert(t, v)
		end
	end
	self.leftBtnMargin:set(LEFT_BTN_MARGINS[#t] or 0)
	self.leftBtnDatas:set(t)
end

function CardStrengthenView:initTabDatasListeners()
	local h = handler(self, "updateTabDatas")
	for tab, data in pairs(TAB_DATA) do
		for idx, v in pairs(data) do
			if v.unlockKey then
				dataEasy.getListenShow(v.unlockKey, h)
			end
		end
	end
end

function CardStrengthenView:updateTabDatas()
	local t = {}
	local curState = self.curState:read()
	for idx, v in pairs(TAB_DATA[curState]) do
		local show = true
		if v.unlockKey then
			show = dataEasy.isShow(v.unlockKey)
		end
		if show then
			t[idx] = clone(v)
		end
	end
	self.tabDatas:update(t)
end

function CardStrengthenView:sendParamsEquip()
	return self.selectDbId, self.equipIndex, self.selectTabKey, self.curState
end

function CardStrengthenView:onTabItemClick(list, index, v)
	if v.unlockKey and not dataEasy.isUnlock(v.unlockKey) then
		gGameUI:showTip(dataEasy.getUnlockTip(v.unlockKey))
	else
		self.selectTabKey:set(index)
		self.selectTabPair:modify(function(t)
			return true, {
				state = t.state,
				idx = index,
			}
		end)
	end
end

function CardStrengthenView:onCardItemClick(list, k, v)
	self.selectDbId:set(v.dbid)
end

function CardStrengthenView:onLockClick()
	if not dataEasy.isUnlock(gUnlockCsv.cardUnlock) then
		gGameUI:showTip(dataEasy.getUnlockTip(gUnlockCsv.cardUnlock))
		return
	end
	gGameApp:requestServer("/game/card/locked/switch",function (tb)
		gGameUI:showTip((not self.locked:read()) and gLanguageCsv.unlockSuccess or gLanguageCsv.lockSuccess)
		self.cardDatas:atproxy(self.selectDbId).lock = self.locked:read()
	end, self.selectDbId)
end

function CardStrengthenView:onChangeNameClick()
	local card = gGameModel.cards:find(self.selectDbId:read())
	gGameUI:stackUI("city.card.changename", nil, nil, {
		typ = "card",
		name = card:read("name"),
		cost = gCommonConfigCsv.cardRenameRMBCost,
		titleTxt = gLanguageCsv.spriteRename,
		requestParams = {self.selectDbId:read()},
		cb = function ()
			gGameUI:showTip(gLanguageCsv.spriteRenameSuccess)
		end
	})
end

function CardStrengthenView:onCardClick()
	local old = self.cardActionState:read()
	local rand
	repeat
		rand = math.random(2, #STATE_ACTION)
	until rand ~= old
	self.cardActionState:set(rand, true)
end

function CardStrengthenView:onLeftBtnItemClick(list, v)
	if v.unlockKey and not dataEasy.isUnlock(v.unlockKey) then
		gGameUI:showTip(dataEasy.getUnlockTip(v.unlockKey))
		return
	end
	self[v.click](self)
end

function CardStrengthenView:onResetHeldItemIcon(dbId)
	self.btnHeldItem:removeChildByName("exclusive")
	self.btnHeldItem:removeChildByName("textLv")
	self.btnHeldItem:removeChildByName("textLvNum")
	local bg = "common/box/box_carry.png"
	local icon = "city/card/helditem/icon_jiahao.png"
	local scale = 1
	local state = false
	if dbId then
		state = true
		local data = gGameModel.held_items:find(dbId):read("level", "held_item_id")
		local cfg = csv.held_item.items[data.held_item_id]
		icon = cfg.icon
		local quality = cfg.quality
		bg = string.format("city/card/helditem/panel_icon_%d.png", quality)
		if csvSize(cfg.exclusiveCards) > 0 then
			ccui.ImageView:create("common/icon/txt_zs.png")
				:xy(61, 130)
				:addTo(self.btnHeldItem, 6, "exclusive")
		end
		local lb1 = cc.Label:createWithTTF("Lv", ui.FONT_PATH, 30)
			:xy(61, 0)
			:addTo(self.btnHeldItem, 8, "textLv")
		local lb2 = cc.Label:createWithTTF(data.level, ui.FONT_PATH, 38)
			:xy(61, 0)
			:addTo(self.btnHeldItem, 8, "textLvNum")
		scale = 1.7
		adapt.oneLineCenterPos(cc.p(61, -10), {lb1, lb2}, cc.p(5, 3))
		text.addEffect(lb1, {outline = {color = ui.COLORS.OUTLINE.DEFAULT}})
		text.addEffect(lb2, {outline = {color = ui.COLORS.OUTLINE.DEFAULT}})
		if self.btnHeldItem:get("spine") then
			self.btnHeldItem:get("spine"):show()
			self.btnHeldItem:get("spine"):play("effect_loop")
		else
			widget.addAnimationByKey(self.btnHeldItem, "effect/yuanxingsaoguang.skel", "spine", "effect_loop", 100)
				:xy(self.btnHeldItem:size().width/2, self.btnHeldItem:size().height/2)
		end
		self.heldItemImgBg:scale(1)

	else
		if self.btnHeldItem:get("spine") then
			self.btnHeldItem:get("spine"):hide()
		end
		self.heldItemImgBg:scale(1.3)
	end
	self.dressState:set(state, true)
	self.heldItemBg:set(bg)
	self.heldItemIcon:set(icon)
	self.heleItemIcon:scale(scale)
end

function CardStrengthenView:onAddClick()
	if not dataEasy.isUnlock(gUnlockCsv.heldItem) then
		gGameUI:showTip(dataEasy.getUnlockTip(gUnlockCsv.heldItem))
		return
	end
	gGameUI:stackUI("city.card.helditem.bag", nil, nil, self.selectDbId:read(), self:createHandler("onResetHeldItemIcon"))
end

function CardStrengthenView:onEquipClick()
	if not dataEasy.isUnlock(gUnlockCsv.equip) then
		gGameUI:showTip(dataEasy.getUnlockTip(gUnlockCsv.equip))
		return
	end
	self.curState:set(STATE.DECORATION)
end

function CardStrengthenView:onZawakeClick()
	if not dataEasy.isUnlock(gUnlockCsv.zawake) then
		gGameUI:showTip(dataEasy.getUnlockTip(gUnlockCsv.zawake))
		return
	end
	local zawakeID = self:getZawakeID(self.selectDbId:read())
	gGameUI:stackUI("city.zawake.view", nil, nil, {zawakeID = zawakeID, cb = self:createHandler("onZawakeSelectDbIdChange")})
end

function CardStrengthenView:onZawakeSelectDbIdChange(dbId)
	self.selectDbId:set(dbId)
	dataEasy.tryCallFunc(self.cardList, "forceUpdate", true)
end

function CardStrengthenView:onGemClick()
   	if not dataEasy.isUnlock(gUnlockCsv.gem) then
		gGameUI:showTip(dataEasy.getUnlockTip(gUnlockCsv.gem))
		return
	end
	gGameUI:stackUI("city.card.gem.view", nil, nil, self.selectDbId:read())
end

function CardStrengthenView:onAccClick()
end

function CardStrengthenView:onEvoClick()
	gGameUI:stackUI("city.card.evolution_base", nil, nil, self.selectDbId:read())
end

function CardStrengthenView:onSkinClick()
	local feelItems = csv.cards[self.cardId:read()].feelItems
	if csvSize(feelItems) <= 0 then
		gGameUI:showTip(gLanguageCsv.notDevelopFeel)
		return
	end
	gGameUI:stackUI("city.card.feel.view", nil, nil, self.cardId:read())
end

function CardStrengthenView:onRebornClick()
	if not gGameUI:goBackInStackUI("city.card.rebirth.view") then
		gGameUI:stackUI("city.card.rebirth.view", nil, nil, 1, self:createHandler("resetSelDbId"), self:createHandler("cardsChanged"))
	end
end

function CardStrengthenView:onSwapClick()
	gGameUI:stackUI("city.card.property_swap.view", nil, nil, nil, self.selectDbId:read())
end

function CardStrengthenView:onCardSkinClick()
	gGameUI:stackUI("city.card.skin.view", nil, nil,self.selectDbId:read())
end

--战斗手册
function CardStrengthenView:onManualsClick()
	gGameUI:stackUI("city.card.helditem.battle_manuals")
end

function CardStrengthenView:onSortCardList(list)
	local seletSortKey = self.seletSortKey:read()
	local attrName = CONDITIONS[seletSortKey].attr
	local tabOrder = self.tabOrder:read()
	return function(a, b)
		if a.battle ~= b.battle then
			return a.battle < b.battle
		end
		local attrA = a[attrName]
		local attrB = b[attrName]
		if attrA ~= attrB then
			if tabOrder then
				return attrA > attrB
			else
				return attrA < attrB
			end
		end
		if a.markId ~= b.markId then
			return a.markId < b.markId
		end
		return a.fight > b.fight
	end
end

function CardStrengthenView:onSortMenusBtnClick(panel, node, k, v, oldval)
	self.sortMenusClick = true
	if oldval == k then
		self.tabOrder:modify(function(val)
			return true, not val
		end)
	else
		self.tabOrder:set(true)
	end
	self.seletSortKey:set(k)
	self.sortMenusClick = false
end

function CardStrengthenView:getZawakeID(dbid)
	local card = gGameModel.cards:find(dbid)
	if not card then
		return
	end
	local cardId = card:read("card_id")
	local zawakeID = csv.cards[cardId].zawakeID
 	if zawakeTools.isOpenByStage(zawakeID) then
		return zawakeID
	end
end

function CardStrengthenView:getSelectedCardDBID()
	local battleCards = self.battleCards:read()
	local cards = self.cards:read()
	local hash = itertools.map(itertools.ivalues(battleCards), function(k, v) return v, k end)
	local tmpCardDatas = {}
	for k, dbid in ipairs(cards) do
		local card = gGameModel.cards:find(dbid)
		local cardData = card:read("card_id", "fighting_point")
		local battle = hash[dbid] and 1 or 2
		local cardCsv = csv.cards[cardData.card_id]
		table.insert(tmpCardDatas, {
			id = cardData.card_id,
			fight = cardData.fighting_point,
			dbid = dbid,
			battle = battle,
		})
	end
	table.sort(tmpCardDatas, function(a, b)
		if a.battle ~= b.battle then
			return a.battle < b.battle
		end
		local attrA = a["fight"]
		local attrB = b["fight"]
		if attrA ~= attrB then
			return attrA > attrB
		end

		return a.id < b.id
	end)

	return tmpCardDatas[1] and tmpCardDatas[1].dbid
end

function CardStrengthenView:onCloseDecoration()
	self.curState:set(STATE.STRENGTHEN)
end

function CardStrengthenView:playAction(force, isFloatingWord)
	if force == nil then
		force = true
	end
	self.cardActionState:set(3, force)
	self.effect:visible(true)
	self.effect:play("effect")
	performWithDelay(self.left, function()
		self.effect:visible(false)
	end, 1)
	if isFloatingWord then
		local pos = gGameUI:getConvertPos(self.left)
		self.img:show():xy(pos.x, pos.y - 200)
		transition.executeSequence(self.img)
			:moveBy(0.45, 0, 100)
			:func(function ()
				self.img:hide()
			end)
			:done()
	end
end

function CardStrengthenView:resetSelDbId()
	local selDbId = self:getSelectedCardDBID()
	self.selectDbId:set(selDbId)
	self.cardDatas:atproxy(selDbId).isSel = true
end

function CardStrengthenView:onClose()
	local cb = self.closeHandler
	ViewBase.onClose(self)
	if cb then
		cb()
	end
end

return CardStrengthenView
