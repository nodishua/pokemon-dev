-- @date:   2021-04-19
-- @desc:   狩猎地带 -- 关卡信息

local ROUTE_TYPE = {
    normal = 1,
    elite = 2,
}
local ENEMY_TYPE = {
	[1] = "city/adventure/hunting/icon_pt.png",
	[2] = "city/adventure/hunting/icon_jy.png",
	[3] = "city/adventure/exp/icon_zj.png",
}

local BIND_EFFECT = {
	event = "effect",
	data = {outline = {color = cc.c4b(91, 84, 91, 255),  size = 4}}
}

local HuntingGateDetailView = class("HuntingGateDetailView", Dialog)
HuntingGateDetailView.RESOURCE_FILENAME = "hunting_gate_detail.json"
HuntingGateDetailView.RESOURCE_BINDING = {
    ["titleBg.btnClose"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")},
		},
	},
	["battleBtn.title"] = {
		binds = {
			event = "effect",
			data = {glow = {color = cc.c4b(255, 255, 255, 255)}},
		},
	},
    ["battleBtn"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onBattleClick")},
		},
	},
	["passBtn.title"] = {
		binds = {
			event = "effect",
			data = {glow = {color = cc.c4b(255, 255, 255, 255)}},
		},
	},
	["passBtn"] = {
		varname = "passBtn",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onPassClick")},
		},
	},
    ["infoPanel"] = "infoPanel",
    ["infoPanel.lvText"] = {
		binds = BIND_EFFECT
	},
    ["infoPanel.level"] = {
		binds = BIND_EFFECT
	},
    ----------------enemyPanel----------------
    ["enemyPanel"] = "enemyPanel",
    ["enemyPanel.item"] = "item",
    ["enemyPanel.enemyList"] = {
		varname = "enemyList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				asyncPreload = 6,
				padding = 10,
				data = bindHelper.self("enemyDatas"),
				item = bindHelper.self("item"),
				itemAction = {isAction = true},
				onItem = function(list, node, k, v)
					bind.extend(list, node, {
						class = "card_icon",
						props = {
							unitId = v.unitId,
							advance = v.advance,
							levelProps = {
								data = v.level,
							},
							star = v.star,
							rarity = v.rarity,
							showAttribute = false,
							onNode = function(panel)
							end,
						}
					})
				end,
			}
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
    ----------------awardPanel----------------
    ["awardPanel"] = "awardPanel",
    ["awardPanel.awardList"] = "awardList",
}

function HuntingGateDetailView:onCreate(data, enemyId, route, node, cb)
	self.data = data.defence_role_info or {}
	self.route = route
	self.enemyId = enemyId
	self.node = node
	self.enemyDatas = {}
	self.cb = cb
    self:initInfoPanel()
    self:initEnemyPanel()
    self:initAwardPanel()
	self:initSkipBtn()
	self:initPassBtn()
    Dialog.onCreate(self)
end

function HuntingGateDetailView:initInfoPanel()
	local cfg = csv.cross.hunting.gate
    bind.extend(self, self.infoPanel:get("icon"), {
        event = "extend",
        class = "role_logo",
        props = {
            logoId = self.data.logo,
            level = false,
            vip = false,
            frameId = self.data.frame,
        }
    })
    self.infoPanel:get("name"):text(self.data.name)
    self.infoPanel:get("area"):text(getServerArea(self.data.game_key))
    self.infoPanel:get("type"):texture(ENEMY_TYPE[cfg[self.enemyId].type])
    self.infoPanel:get("level"):text(self.data.level)
	adapt.oneLineCenterPos(cc.p(self.infoPanel:get("icon"):size().width / 2, self.infoPanel:get("level"):y()), {self.infoPanel:get("lvText"), self.infoPanel:get("level")}, cc.p(0, 0), "left")
end

function HuntingGateDetailView:initEnemyPanel()
	local fighting_point = 0
	for _, v in pairs(self.data.defence_card_attrs) do
		local unitID = csv.cards[v.card_id].unitID
		local unitCfg = csv.unit[unitID]
		table.insert(self.enemyDatas, {
			unitId = unitID,
			level = v.level,
			advance = v.advance,
			rarity = unitCfg.rarity,
			star = v.star,
		})
		fighting_point = fighting_point + v.fighting_point
	end
	table.sort(self.enemyDatas, function(a,b)
		return a.advance > b.advance
	end)
    self.infoPanel:get("fightPoint"):text(fighting_point)
end

function HuntingGateDetailView:initAwardPanel()
	local cfg = csv.cross.hunting.gate
	uiEasy.createItemsToList(self, self.awardList, cfg[self.enemyId].dropsView, {onNode = function(panel,v)
		if v.key ~= "gold" then
			ccui.ImageView:create("city/adventure/endless_tower/icon_gl.png")
				:anchorPoint(1, 0.5)
				:xy(panel:width() - 5, panel:height() - 25)
				:addTo(panel, 15)
		end
	end})
	self.awardList:setTouchEnabled(true)
end

function HuntingGateDetailView:initSkipBtn( )
	local state = userDefault.getForeverLocalKey("huntingSkipBattle", false)
	self.selectSkip:get("skipBtn"):setSelectedState(state)
end

function HuntingGateDetailView:initPassBtn()
	local unlockKey = self.route == 1 and "huntingPass" or "specialHuntingPass"
	local lastMaxNode = gGameModel.hunting:read("hunting_route")[self.route].last_max_node
	local hisMaxNode = gGameModel.hunting:read("hunting_route")[self.route].history_max_node
	local lastCanPass = 0
	local historyCanPass = 0
	if csv.cross.hunting.route[lastMaxNode] then
		lastCanPass = csv.cross.hunting.route[lastMaxNode].lastCanPass
	end
	if csv.cross.hunting.route[hisMaxNode] then
		historyCanPass = csv.cross.hunting.route[hisMaxNode].historyCanPass
	end
	local canPassNode = math.max(lastCanPass, historyCanPass)
	dataEasy.getListenUnlock(unlockKey, function(isShow)
		self.passBtn:visible(isShow and (self.node % 100) <= canPassNode)
	end)
end

function HuntingGateDetailView:onBattleClick()
	-- 会存在阵容变动，需要重新获取
	local battleCardIDs = gGameModel.hunting:read("hunting_route")[self.route].cards or {}
	local skip = userDefault.getForeverLocalKey("huntingSkipBattle", false)
	if skip then
		if not itertools.isempty(battleCardIDs) and self:checkEmbattle() then
			self:skipEmbattleToFight()
		else
			self:goEmbattle()
		end
	else
		if not self:checkEmbattle() then
			gGameUI:showTip(gLanguageCsv.randomTowerCheckEmbattleLevel)
		end
		self:goEmbattle()
	end
end

--碾压
function HuntingGateDetailView:onPassClick()
	local cb = self.cb
	gGameApp:requestServer("/game/hunting/battle/pass", function(tb)
		self:addCallbackOnExit(function()
			gGameUI:showGainDisplay(tb.view.drop,{cb = cb})
		end)
		Dialog.onClose(self)
	end, self.route, self.node, self.enemyId)
end

function HuntingGateDetailView:skipEmbattleToFight()
	local battleCards = gGameModel.hunting:read("hunting_route")[self.route].cards or {}
	local cardStates = gGameModel.hunting:read("hunting_route")[self.route].card_states or {}
	local cards = {}
	if itertools.isempty(battleCards) then
		gGameUI:showTip(gLanguageCsv.noSpriteAvailable)
		return
	end
	if itertools.size(cardStates) == 0 then
		--没有缓存则取主场景布阵
		local cardDatas = gGameModel.role:read("battle_cards")
		cards = table.shallowcopy(cardDatas)
	else
		local myCards = gGameModel.role:read("cards")--判断自己是否有这张卡 以防卡片被分解
		local cardDatas = {}
		local hash = itertools.map(myCards, function(k, v) return v, k end)
		for k, dbid in pairs(battleCards) do
			if hash[dbid] then
				cardDatas[k] = dbid
			end
		end
		cards = cardDatas
	end
	battleEntrance.battleRequest("/game/hunting/battle/start", self.route, self.node, self.enemyId, cards)
		:onStartOK(function(data)
			gGameUI:goBackInStackUI("city.adventure.hunting.route")
		end)
		:show()
end

function HuntingGateDetailView:goEmbattle()
	local skip = userDefault.getForeverLocalKey("huntingSkipBattle", false)
	if skip then
		self:skipEmbattleToFight()
	else
		gGameUI:stackUI("city.card.embattle.hunting", nil, {full = true}, {
			fightCb = function(view, battleCards)
				battleEntrance.battleRequest("/game/hunting/battle/start", self.route, self.node, self.enemyId, battleCards)
					:onStartOK(function(data)
						gGameUI:goBackInStackUI("city.adventure.hunting.route")
					end)
					:show()
			end,
			route = self.route,
			from = game.EMBATTLE_FROM_TABLE.hunting ,
		})
	end
end

-- 检测阵容，若存在卡牌等级1的自动进布阵
function HuntingGateDetailView:checkEmbattle()
	local battleCardIDs = gGameModel.hunting:read("hunting_route")[self.route].cards or gGameModel.role:read("battle_cards")
	for _, dbid in pairs(battleCardIDs) do
		local card = gGameModel.cards:find(dbid)
		if card then
			if card:read("level") < 10 then
				return false
			end
		end
	end
	return true
end

--跳过布阵复选框
function HuntingGateDetailView:onSkipClick()
	local state = userDefault.getForeverLocalKey("huntingSkipBattle", false)
	self.selectSkip:get("skipBtn"):setSelectedState(not state)
	userDefault.setForeverLocalKey("huntingSkipBattle", not state)
end

return HuntingGateDetailView