-- @date:   2019-10-11
-- @desc:   试练-随机塔怪物详情

local randomTowerTools = require "app.views.city.adventure.random_tower.tools"
local ViewBase = cc.load("mvc").ViewBase
local RandomTowerGateDetail = class("RandomTowerGateDetail", Dialog)

RandomTowerGateDetail.RESOURCE_FILENAME = "random_tower_gate_detail.json"
RandomTowerGateDetail.RESOURCE_BINDING = {
	["btnClose"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")},
		},
	},
	["title1"] = "title1",
	["title2"] = "title2",
	["item"] = "item",
	["enemyList"] = {
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
							isBoss = v.isBoss,
							rarity = v.rarity,
							showAttribute = true,
							onNode = function(panel)
								local x, y = panel:xy()
								node:scale(v.isBoss and 1.1 or 0.99)
							end,
						}
					})
				end,
			}
		},
	},
	["enemyFightIcon"] = "enemyFightIcon",
	["enemyFightLabel"] = "enemyFightLabel",
	["enemyFightPoint"] = "enemyFightPoint",
	["myFightPoint"] = "myFightPoint",
	["myFightLabel"] = "myFightLabel",
	["pointLabel"] = "pointLabel",
	["passInfo"] = "passInfo",
	["skipBtn"] = {
		varname = "skipBtn",
		binds = {
			event = "click",
			method = bindHelper.self("onSkipClick"),
		},
	},
	["passBtn"] = {
		varname = "passBtn",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onPassClick")},
		},
	},
	["battleBtn"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onBattleClick")},
		},
	},
}

function RandomTowerGateDetail:onCreate(boardId, fightCb, passCb)
	self.fightCb = fightCb
	self.passCb = passCb
	local roomInfo = gGameModel.random_tower:read("room_info")
	local boardCfg = csv.random_tower.board[boardId]
	local title1 = string.utf8limit(boardCfg.name, 2, true)
	local title2 = string.sub(boardCfg.name, #title1 + 1)
	self.title1:text(title1)
	self.title2:text(title2)
	adapt.oneLinePos(self.title1, self.title2)

	local data = roomInfo.enemy[boardId] or {}
	local monsterCfg = csv.random_tower.monsters[data.id]
	local bossHash = arraytools.hash(monsterCfg.boss)
	self.enemyDatas = {}
	for _, v in ipairs(data.monsters) do
		if v.unit_id then
			local unitCfg = csv.unit[v.unit_id]
			table.insert(self.enemyDatas, {
				unitId = v.unit_id,
				level = v.level,
				advance = v.advance,
				star = v.star,
				rarity = unitCfg.rarity,
				isBoss = bossHash[v.unit_id] or false,
			})
		end
	end
	table.sort(self.enemyDatas, function(a, b)
		if a.isBoss ~= b.isBoss then
			return a.isBoss
		end
		return a.advance > b.advance
	end)
	self.enemyFightPoint:text(tostring(data.fighting_point))
	adapt.oneLinePos(self.enemyFightLabel, self.enemyFightPoint, cc.p(15, 0))
	adapt.oneLinePos(self.myFightLabel, self.myFightPoint, cc.p(15, 0))

	local calcFightingPointf = randomTowerTools.calcFightingPointFunc()
	idlereasy.when(gGameModel.role:getIdler("huodong_cards"), function (_, huodong_cards)
		local battleCardIDs = huodong_cards[game.EMBATTLE_HOUDONG_ID.randomTower] or gGameModel.role:read("battle_cards")
		local fightPintNum = 0
		for _, dbId in pairs(battleCardIDs) do
			fightPintNum = fightPintNum + calcFightingPointf(dbId)
		end
		self.myFightPoint:text(fightPintNum)
	end)

	local level = gGameModel.role:read("level")
	local basePoint = csv.random_tower.point[level].initPoint
	self.pointLabel:text(""):removeAllChildren()
	local towerC = csv.random_tower.tower[boardCfg.room].pointC[boardCfg.monsterType]
	local str = string.format(gLanguageCsv.randomTowerGateDetailPoint, basePoint * boardCfg.pointC * towerC)
	--vip额外加成
	local vipLevel = gGameModel.role:read("vip_level")
	local vipAddTip = ""
	if gVipCsv[vipLevel].randomTowerPointRate > 1 then
		local addNum = (gVipCsv[vipLevel].randomTowerPointRate - 1) * 100
		vipAddTip = string.format(gLanguageCsv.randomTowerVipPointAddTip, addNum)
	end
	rich.createByStr(str..vipAddTip, 50)
		:anchorPoint(0, 0.5)
		:addTo(self.pointLabel, 6)

	if not self:isCanPass() then
		self.passBtn:hide()
	end

	local state = userDefault.getForeverLocalKey("randomTowerSkipBattle", false)
	self.skipBtn:get("skipBtn"):setSelectedState(state)

	Dialog.onCreate(self)
end

-- 是否可以碾压
-- 1	假定玩家昨天通关了第X房间，则玩家在第A（读取配置）房间之前，均可以选择碾压战斗（当然也可以选择战斗）
-- 2	增加一个关于等级的保底碾压，等级到达Y（unlock加功能，保底碾压），且曾经通关过B房间，则即便玩家昨天没有打这个塔，也可以碾压到B房间为止的战斗
function RandomTowerGateDetail:isCanPass()
	local max = randomTowerTools.getCanPassMaxRoom()
	local room = gGameModel.random_tower:read("room")
	return room <= max
end

function RandomTowerGateDetail:onSkipClick()
	local state = userDefault.getForeverLocalKey("randomTowerSkipBattle", false)
	self.skipBtn:get("skipBtn"):setSelectedState(not state)
	userDefault.setForeverLocalKey("randomTowerSkipBattle", not state)
end

function RandomTowerGateDetail:onPassClick()
	self.passCb(self)
end

--飘字提示
function RandomTowerGateDetail:showTip(view)
	local state = userDefault.getForeverLocalKey("randomTowerSkipBattle", false)
	local battleCardIDs = gGameModel.role:read("huodong_cards")[game.EMBATTLE_HOUDONG_ID.randomTower]
	if state and itertools.isempty(battleCardIDs) then
		gGameUI:showTip(gLanguageCsv.noSpriteAvailable)
	end
end

function RandomTowerGateDetail:onBattleClick()
	-- 会存在阵容变动，需要重新获取
	local battleCardIDs = gGameModel.role:read("huodong_cards")[game.EMBATTLE_HOUDONG_ID.randomTower]
	if itertools.isempty(battleCardIDs) then
		self:goEmbattle()
		return
	end
	if self:chechEmbattle() then
		return
	end
	local state = userDefault.getForeverLocalKey("randomTowerSkipBattle", false)
	if state then
		self.fightCb(self)
		return
	end
	self:goEmbattle()
end

function RandomTowerGateDetail:goEmbattle()
	gGameUI:stackUI("city.card.embattle.random", nil, {full = true}, {
		fightCb = function(...)
			self.fightCb(self, ...)
		end,
		from = "huodong",
		fromId = game.EMBATTLE_HOUDONG_ID.randomTower,
		startCb = self:createHandler("showTip"),
	})
end

-- 检测阵容，若存在卡牌等级1的自动进布阵
function RandomTowerGateDetail:chechEmbattle()
	local battleCardIDs = gGameModel.role:read("huodong_cards")[game.EMBATTLE_HOUDONG_ID.randomTower] or gGameModel.role:read("battle_cards")
	for _, dbid in pairs(battleCardIDs) do
		local card = gGameModel.cards:find(dbid)
		if card then
			if card:read("level") < 10 then
				self:goEmbattle()
				gGameUI:showTip(gLanguageCsv.randomTowerCheckEmbattleLevel)
				return true
			end
		end
	end
end

return RandomTowerGateDetail
