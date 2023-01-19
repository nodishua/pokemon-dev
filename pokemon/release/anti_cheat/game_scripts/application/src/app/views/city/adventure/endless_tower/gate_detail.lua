-- @date:   2019-05-21
-- @desc:   无尽塔-关卡详情

local LIMIT_TYPE = {
	[1] = {
		typ = 1,
		note = gLanguageCsv.elementAttributeRestrictionCanBattle
	},
	[2] = {
		typ = 1,
		note = gLanguageCsv.elementAttributeRestrictionNotBattle
	},
	[3] = {
		typ = 2,
		note = gLanguageCsv.attributeCorrection,
		txt1 = gLanguageCsv.weSpirit,
		--参数
		parameter = {
			[0] = gLanguageCsv.increase,
			[1] = gLanguageCsv.reduce
		}
	},
	[4] = {
		typ = 2,
		note = gLanguageCsv.attributeCorrection,
		txt1 = gLanguageCsv.enemySpirit,
		--参数
		parameter = {
			[0] = gLanguageCsv.increase,
			[1] = gLanguageCsv.reduce
		}
	},
	[5] = {
		typ = 2,
		note = gLanguageCsv.attributeCorrection,
		txt1 = gLanguageCsv.bothSpirit,
		--参数
		parameter = {
			[0] = gLanguageCsv.increase,
			[1] = gLanguageCsv.reduce
		}
	},
	[6] = {
		typ = 3,
		note = gLanguageCsv.limitPlayingCards,
		txt1 = gLanguageCsv.forceIntoBattle,
		txt2 = gLanguageCsv.someSpriteSomeNum
	}
}

local function createImg(res, x, y, scale, parent)
	return ccui.ImageView:create(res)
		:anchorPoint(0, 0.5)
		:xy(x, y)
		:scale(scale)
		:addTo(parent, 6)
end

local function createRichTxt(str, x, y, parent)
	return rich.createByStr(str, 40)
			:anchorPoint(0, 0.5)
			:xy(x, y)
			:addTo(parent, 6)
end
--设置限制条件
local function setLimitType(sceneCsv, textNote)
	local limitData = LIMIT_TYPE[sceneCsv.limitType]
	textNote:text(limitData.note)
	local size = textNote:size()
	local x, y = size.width + 22, size.height/2
	if limitData.typ == 1 then
		for _,v in orderCsvPairs(sceneCsv.limitArg) do
			local img = createImg(ui.ATTR_ICON[v], x, y, 0.63, textNote)
			x = x + img:size().width*0.63 + 20
		end
	elseif limitData.typ == 2 then
		local richTextNote = createRichTxt("#C0x5b545b#".. limitData.txt1, x, y, textNote)
		richTextNote:formatText()
		x = x + richTextNote:size().width
		for i,v in csvPairs(sceneCsv.limitArg) do
			local color = v[2] == 0 and "#C0x60C456#" or "#C0xF76B45#"
			local icon = v[2] == 0 and "common/icon/logo_arrow_green.png" or "common/icon/logo_arrow_red.png"
			local str = "#C0x5b545b#".. getLanguageAttr(v[1])..limitData.parameter[v[2]].." "..color.. dataEasy.getAttrValueString(v[1], v[3])
			local richText = createRichTxt(str, x, y, textNote)
			richText:formatText()
			x = x + richText:size().width
			local img = createImg(icon, x, y, 1, textNote)
			x = x + img:size().width + 10
		end
	else
		local richTextNote = createRichTxt("#C0x5b545b#".. limitData.txt1, x, y, textNote)
		richTextNote:formatText()
		x = x + richTextNote:size().width + 5
		for i,v in csvPairs(sceneCsv.limitArg) do
			local img = createImg(ui.RARITY_ICON[v[1]], x, y, 0.7, textNote)
			x = x + img:size().width*0.7 + 5
			local str = "#C0x5b545b#".. string.format(limitData.txt2, "", v[2])
			str = str.. (i < itertools.size(sceneCsv.limitArg) and gLanguageCsv.symbolDot or gLanguageCsv.symbolPeriod)
			local richText = createRichTxt(str, x, y, textNote)
			richText:formatText()
			x = x + richText:size().width
		end
	end
end

local ViewBase = cc.load("mvc").ViewBase
local EndlessTowerGateDetail = class("EndlessTowerGateDetail", Dialog)
EndlessTowerGateDetail.RESOURCE_FILENAME = "endless_tower_gate_detail.json"
EndlessTowerGateDetail.RESOURCE_BINDING = {
	["btnClose"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")},
		},
	},
	["item"] = "item",
	["enemyList"] = {
		varname = "enemyList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				asyncPreload = 6,
				padding = 10,
				data = bindHelper.self("combatDatas"),
				item = bindHelper.self("item"),
				itemAction = {isAction = true},
				onItem = function(list, node, k, v)
					node:get("icon"):hide()
					bind.extend(list, node, {
						class = "card_icon",
						props = {
							unitId = v.id,
							advance = v.advance,
							levelProps = {
								data = v.level,
							},
							isBoss = v.isBoss,
							rarity = v.rarity,
							showAttribute = true,
							onNode = function(panel)
								local x, y = panel:xy()
								node:scale(v.isBoss and 1 or 0.9)
							end,
						}
					})
				end,
			}
		},
	},
	["rewardList"] = {
		varname = "rewardList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				asyncPreload = 6,
				padding = 10,
				data = bindHelper.self("rewardDatas"),
				item = bindHelper.self("item"),
				onItem = function(list, node, k, v)
					node:get("icon"):visible(v.showIcon == 1)
					local size = node:size()
					local binds = {
						class = "icon_key",
						props = {
							data = {
								key = v.key,
								num = v.num,
							},
							onNode = function(node)
								node:xy(size.width/2-14, size.height/2)
							end,
						},
					}
					bind.extend(list, node, binds)
				end,
			}
		},
	},
	["sweepBtn.btn"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onSweepClick")},
		},
	},
	["skipBtn.skipNote"] = "skipNote",
	["skipBtn"] = {
		varname = "selectSkip",
		binds = {
			event = "click",
			method = bindHelper.self("onSkipClick"),
		},
	},
	["battleBtn.btn"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onBattleClick")},
		},
	},
	["battleBtn.title"] = {
		binds = {
			event = "effect",
			data = {color = ui.COLORS.NORMAL.WHITE, glow = {color = ui.COLORS.GLOW.WHITE}},
		}
	},
	["videoBtn.btn"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onVideoClick")},
		},
	},
	["videoBtn.title"] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.WHITE}},
		},
	},
	["sureBtn.btn"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")},
		},
	},
	["sureBtn.title"] = {
		binds = {
			event = "effect",
			data = {color = ui.COLORS.NORMAL.WHITE, glow = {color = ui.COLORS.GLOW.WHITE}},
		}
	},
	["battleBtn"] = "battleBtn",
	["sweepBtn"] = "sweepBtn",
	["sureBtn"] = "sureBtn",
	["title1"] = "title1",
	["title2"] = "title2",
	["title3"] = "title3",
	["rewardNote"] = "rewardNote",
	["rewardImg"] = "rewardImg",
	["conditionNote"] = "conditionNote",
	["gateText"] = "gateText",
}

function EndlessTowerGateDetail:onCreate(idx, gateId, handler)
	self.gateId = gateId or 100000 + idx
	self.handler = handler
	self.idx = idx
	self:initModel()
	self.title2:text(idx)
	adapt.oneLinePos(self.title1, {self.title2, self.title3}, cc.p(5, 0))
	local sceneCsv = csv.endless_tower_scene[self.gateId]
	setLimitType(sceneCsv, self.conditionNote)

	self.gateText:text(sceneCsv.gateDesc)

	local function getCfgData(cfg, isBoss)
		local data = {}
		for _, v in ipairs(cfg) do
			local unitCfg = csv.unit[v.unitId]
			table.insert(data, {
				id = v.unitId,
				level = v.level,
				advance = v.advance,
				rarity = unitCfg.rarity,
				isBoss = isBoss,
			})
		end
		table.sort(data, function(a,b)
			return a.advance > b.advance
		end )
		return data
	end
	local bossDatas = getCfgData(sceneCsv.boss, true)
	local monsterDatas = getCfgData(sceneCsv.monsters, false)
	self.combatDatas = arraytools.merge({bossDatas, monsterDatas})

	self.rewardDatas = idlertable.new()
	idlereasy.any({self.maxGateId, self.curChallengeId}, function(_, maxGateId, curChallengeId)
		local isFirst = self.gateId > maxGateId
		self.isFirst = isFirst
		local rewardNote = isFirst and gLanguageCsv.firstPassAward or gLanguageCsv.sweepingReward
		self.rewardImg:visible(isFirst)
		self.rewardNote:text(rewardNote)
		local canSweep = curChallengeId == self.gateId and not isFirst
		--首通或者可扫荡 的时候可挑战
		local canBattle = isFirst or canSweep
		--可挑战 显示挑战按钮 跳过布阵按钮
		self.skipNote:visible(canBattle)
		self.selectSkip:visible(canBattle)
		self.battleBtn:visible(canBattle)
		--可扫荡显示扫荡按钮
		self.sweepBtn:visible(canSweep)
		--不可挑战 显示确认按钮
		self.sureBtn:visible(not canBattle)
		local iconType = isFirst and "st" or "gl"
		self.item:get("icon"):texture(string.format("city/adventure/endless_tower/icon_%s.png", iconType))
		local tmpRewardDatas = isFirst and sceneCsv.firstAwardShow or sceneCsv.saodangAwardShow
		local rewardDatas = {}
		for _,v in csvPairs(tmpRewardDatas) do
			table.insert(rewardDatas, {
				key = v[1],
				num = v[2],
				showIcon = v[3],
			})
		end

		-- 首通 优先显示
		table.sort(rewardDatas, function(a, b)
			if a.showIcon ~= b.showIcon then
				return a.showIcon > b.showIcon
			end
			return dataEasy.sortItemCmp(a, b)
		end)
		self.rewardDatas:set(rewardDatas)
	end)
	local state = userDefault.getForeverLocalKey("endlessTowerSkipBattle", false)
	self.selectSkip:get("skipBtn"):setSelectedState(state)
	Dialog.onCreate(self)
end

function EndlessTowerGateDetail:initModel()
	self.cards = gGameModel.role:getIdler("cards")
	self.roleLv = gGameModel.role:getIdler("level")
	--已挑战的最大关卡id
	self.maxGateId = gGameModel.role:getIdler("endless_tower_max_gate")
	--当前挑战的关卡id
	self.curChallengeId = gGameModel.role:getIdler("endless_tower_current")
	self.battleCards = idlertable.new({})
	local sceneCsv = csv.endless_tower_scene[self.gateId]
	local limitType = sceneCsv.limitType
	local limitArg = sceneCsv.limitArg
	idlereasy.when(gGameModel.role:getIdler("huodong_cards"), function (_, huodong_cards)
		self.isChangeBattleCards = false
		local battleCards = huodong_cards[game.EMBATTLE_HOUDONG_ID.endlessTower]
		local curBattleCards = battleCards or table.deepcopy(gGameModel.role:read("battle_cards"), true)
		-- self.battleCards:set(battleCards or
		local hashMap = itertools.map(limitArg or {}, function(k, v) return v, 1 end)
		local t = {}
		for i,dbid in pairs(curBattleCards) do
			local card = gGameModel.cards:find(dbid)
			local card_id = card:read("card_id")
			local cardCsv = csv.cards[card_id]
			local unitCsv = csv.unit[cardCsv.unitID]
			if not limitType or (limitType > 2 and limitType < 7) or (limitType == 1 and (hashMap[unitCsv.natureType] or hashMap[unitCsv.natureType2])) or
			 (limitType == 2 and (not hashMap[unitCsv.natureType] and not hashMap[unitCsv.natureType2])) then
				t[i] = dbid
			elseif dbid then
				self.isChangeBattleCards = true
			end
		end
		self.battleCards:set(t)
	end)
	self.rarityDatas = {}
	--所有卡牌数量
	self.allCardCount = 0
	idlereasy.when(self.cards,function (_, cards)
		local hashMap = itertools.map(limitArg or {}, function(k, v) return v, 1 end)
		local all = {}
		local maxFightPoint = -1
		for k, dbid in ipairs(cards) do
			local card = gGameModel.cards:find(dbid)
			local cardData = card:read("card_id", "fighting_point", "level", "star", "advance", "created_time")
			local cardCsv = csv.cards[cardData.card_id]
			local unitCsv = csv.unit[cardCsv.unitID]
			-- 没有筛选条件或者满足筛选条件
			if not limitType or (limitType > 2 and limitType < 7) or (limitType == 1 and (hashMap[unitCsv.natureType] or hashMap[unitCsv.natureType2])) or
				(limitType == 2 and (not hashMap[unitCsv.natureType] and not hashMap[unitCsv.natureType2])) then
				if cardData.fighting_point > maxFightPoint then
					maxFightPoint = cardData.fighting_point
					self.maxFightPointDbId = dbid
				end
				self.allCardCount = self.allCardCount + 1
			end

			local rarity = unitCsv.rarity
			if not self.rarityDatas[rarity] then
				self.rarityDatas[rarity] = 0
			end
			self.rarityDatas[rarity] = self.rarityDatas[rarity] + 1
		end
	end)
end

--扫荡按钮
function EndlessTowerGateDetail:onSweepClick()
	local oldCapture = gGameModel.capture:read("limit_sprites")
	gGameApp:requestServer("/game/endless/saodang", function(tb)
		local datas = {}
		for i,v in ipairs(tb.view.result) do
			local t = {items = {}}
			for key,vv in pairs(v) do
				if key ~= "gold" then
					t.items[key] = vv
				else
					t.gold = vv
				end
			end
			table.insert(datas, t)
		end
		gGameUI:stackUI("city.gate.sweep", nil, nil, {
			sweepData = datas,
			oldRoleLv = self.roleLv:read(),
			showType = 2,
			hasExtra = false,
			startGateId = self.gateId,
			from = "endlessTower",
			oldCapture = oldCapture,
			isDouble = dataEasy.isGateIdDoubleDrop(self.gateId),
		})
		if self.handler then
			self.handler(self.idx, true)
		end
	end, self.gateId)
end
--跳过布阵复选框
function EndlessTowerGateDetail:onSkipClick()
	local state = userDefault.getForeverLocalKey("endlessTowerSkipBattle", false)
	self.selectSkip:get("skipBtn"):setSelectedState(not state)
	userDefault.setForeverLocalKey("endlessTowerSkipBattle", not state)
end
--战斗按钮
function EndlessTowerGateDetail:onBattleClick()
	local sceneCsv = csv.endless_tower_scene[self.gateId]
	local limitType = sceneCsv.limitType
	local limitArg = sceneCsv.limitArg
	-- 属性6 的特判
	if limitType == 6 then
		for _,v in csvPairs(limitArg) do
			if (self.rarityDatas[v[1]] or 0) < v[2] then
				gGameUI:showTip(gLanguageCsv.notHasRole)
				return
			end
		end
	end
	-- 全部下阵之后 并且没有符合要求的阵容
	if self.allCardCount < 1 and self.battleCards:size() < 1 then
		gGameUI:showTip(gLanguageCsv.notHasRole)
		return
	end
	local state = userDefault.getForeverLocalKey("endlessTowerSkipBattle", false)
	-- 有过剔除阵容的就都要进入布阵界面
	if state and self:correctEnbattle() and not self.isChangeBattleCards then
		self:startFighting()
		return
	end
	local limitInfo = {}
	limitInfo[limitType] = limitArg
	gGameUI:stackUI("city.card.embattle.endless", nil, {full = true}, {
		from = "huodong",
		fromId = game.EMBATTLE_HOUDONG_ID.endlessTower,
		limitInfo = limitInfo,
		startCb = self:createHandler("showTip"),
		fightCb = self:createHandler("startFighting"),
		checkBattleArr = self:createHandler("correctEnbattle"),
		team = true,
	})
end
--飘字提示
function EndlessTowerGateDetail:showTip(view)
	local state = userDefault.getForeverLocalKey("endlessTowerSkipBattle", false)
	if state and not self:correctEnbattle() then
		gGameUI:showTip(gLanguageCsv.lineupInconsistency)
	end
	if self.allCardCount > 0 and self.battleCards:size() < 1 then
		self.battleCards:proxy()[1] = self.maxFightPointDbId
	end
	local sceneCsv = csv.endless_tower_scene[self.gateId]
	setLimitType(sceneCsv, view.textLimit)
	return table.deepcopy(self.battleCards:proxy(), true)
end
--判断阵容是否符合
function EndlessTowerGateDetail:correctEnbattle(battleCards)
	battleCards = battleCards or self.battleCards:read()
	local sceneCsv = csv.endless_tower_scene[self.gateId]
	local limitData = LIMIT_TYPE[sceneCsv.limitType]
	if limitData.typ == 1 then
		for k,v in pairs(battleCards) do
			local card = gGameModel.cards:find(v)
			local cardId = card:read("card_id")
			local cardCsv = csv.cards[cardId]
			local unitCsv = csv.unit[cardCsv.unitID]
			local attr1 = unitCsv.natureType
			local attr2 = unitCsv.natureType2
			local hash = itertools.map(sceneCsv.limitArg, function(k, v) return v, k end)
			--sceneCsv.limitType == 2 限制不可上阵，其中一个满足 则不符合
			if (sceneCsv.limitType == 2 and hash[attr1])
				or (attr2 and sceneCsv.limitType == 2 and hash[attr2]) then
					return false
			end
			--sceneCsv.limitType == 1 限制可上阵，两个都不满足则不符合
			if (sceneCsv.limitType == 1) and not hash[attr1] and (not attr2 or (attr2 and not hash[attr2])) then
					return false
			end
		end
	elseif limitData.typ == 3 then
		local tmpRarity = {}
		for k,v in pairs(battleCards) do
			local card = gGameModel.cards:find(v)
			local cardId = card:read("card_id")
			local cardCsv = csv.cards[cardId]
			local rarity = csv.unit[cardCsv.unitID].rarity
			if not tmpRarity[rarity] then
				tmpRarity[rarity] = 0
			end
			tmpRarity[rarity] = tmpRarity[rarity] + 1
		end
		for _,v in csvPairs(sceneCsv.limitArg) do
			--v[1]属性的精灵数量小于v[2] 则不符合
			if not tmpRarity[v[1]] or tmpRarity[v[1]] < v[2] then
				return false
			end
		end
	end
	return true
end

--开始战斗
function EndlessTowerGateDetail:startFighting(view)
	if not self:correctEnbattle() then
		gGameUI:showTip(gLanguageCsv.lineupInconsistency)
		return
	end
	local gateId = self.gateId
	local isFirst = self.isFirst
	local battleCards = table.deepcopy(self.battleCards, true)

	battleEntrance.battleRequest("/game/endless/battle/start", gateId, battleCards)
		:onStartOK(function(data)
			if view then
				view:onClose(false)
				view = nil
			end
	
			if not tolua.isnull(self) then
				ViewBase.onClose(self)
			end

			data.isFirst = isFirst -- BattleEndlessWinView
			data.battleCards = battleCards -- EndlessGate:makeEndViewInfos
		end)
		:show()
end

--通关录像按钮
function EndlessTowerGateDetail:onVideoClick()
	gGameApp:requestServer("/game/endless/plays/list",function (tb)
		gGameUI:stackUI("city.adventure.endless_tower.battle_video", nil, {dialog = true}, tb.view.latesPlays or {})
	end,self.gateId)
end

return EndlessTowerGateDetail
