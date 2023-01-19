local CardEmbattleView = require "app.views.city.card.embattle.base"
local GymChallengeEmbattleView = class("GymChallengeEmbattleView", CardEmbattleView)

GymChallengeEmbattleView.RESOURCE_FILENAME = "gym_embattle2.json"
GymChallengeEmbattleView.RESOURCE_BINDING = {
	["battlePanel"] = "battlePanel",
	["spritePanel"] = "spriteItem",
	["textNotRole"] = "emptyTxt",
	["battlePanel.ahead.txt"] = {
		binds = {
			event = "effect",
			data = {glow={color=ui.COLORS.GLOW.WHITE}},
		},
	},
	["battlePanel.back.txt"] = {
		binds = {
			event = "effect",
			data = {glow={color=ui.COLORS.GLOW.WHITE}},
		},
	},

	["rightDown"] = "rightDown",
	["rightDown.btnChallenge"] = {
		varname = "btnChallenge",
		binds = {
			event = "touch",
			clicksafe = true,
			methods = {ended = bindHelper.self("fightBtn")}
		},
	},
	["rightDown.btnChallenge.textNote"] = {
		binds = {
			event = "effect",
			data = {glow={color=ui.COLORS.GLOW.WHITE}},
		},
	},
	["rightDown.btnOneKeySet"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("oneKeyEmbattleBtn")}
		},
	},
	["rightDown.btnOneKeySet.textNote"] = {
		binds = {
			event = "effect",
			data = {glow={color=ui.COLORS.GLOW.WHITE}},
		},
	},
	["bottomPanel"] = "bottomPanel",

	["attrItem"] = "attrItem",
	["rightTop"] = "rightTop",
	["rightTop.textNote"] = "textNote",
	["rightTop.imgBg"] = "attrBg",
	["rightTop.arrList"] = {
		varname = "arrList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("limitInfo"),
				item = bindHelper.self("attrItem"),
				textNote = bindHelper.self("textNote"),
				attrBg = bindHelper.self("attrBg"),
				onItem = function(list, node, k, v)
					node:get("imgIcon"):texture(ui.ATTR_ICON[v])
				end,
				onAfterBuild = function(list)
					-- --右对齐
					local size = list.item:size()
					local count = csvSize(list.data)
					local width = size.width * count  + list:getItemsMargin() * (count - 1)
					list:setAnchorPoint(cc.p(1,0.5))
					list:width(width)
					list:xy(cc.p(600,50))
					adapt.oneLinePos(list, list.textNote, cc.p(0,0), "right")
					list.attrBg:width(width + list.textNote:width() + 40)
					list.attrBg:x(list.textNote:x() -40)
				end
			}
		},
	},
	["textPanel.textNum"] = {
		binds = {
			event = "text",
			idler = bindHelper.self("battleNum"),
		},
	},
	["upItem"] = "upItem"
}


function GymChallengeEmbattleView:onCreate(params)
	gGameUI.topuiManager:createView("title", self, {onClose = self:createHandler("onClose", false)})
		:init({title = gLanguageCsv.formation, subTitle = "FORMATION"})

	self:initDefine(params)
	self:initParams(params)
	self:initModel(params)
	self:initRoundUIPanel()
	self:initHeroSprite()
	self:initBottomList()
	self.battleCardsData:set(self:getOneKeyCardDatas())
end

function GymChallengeEmbattleView:initDefine(params)
	self.embattleMax = csv.gym.gate[params.gateId].deployCardNumLimit
	self.panelNum = self.embattleMax    --布阵底座数量
	self.gymId = params.gymId
	self.k = params.k
end

function GymChallengeEmbattleView:initParams(params)
	params = params or {}
	self.from = game.EMBATTLE_FROM_TABLE.onekey
	self.sceneType = game.SCENE_TYPE.gym
	self.fightCb = params.fightCb
	self.limitInfo = csv.gym.gate[params.gateId].deployNatureLimit
	self.checkBattleArr = params.checkBattleArr or function()
		return true
	end
end

-- 边缘UI初始化
function GymChallengeEmbattleView:initRoundUIPanel()
	adapt.centerWithScreen("left", "right", nil, {
		{self.rightDown, "pos", "right"},
		{self.rightTop, "pos", "right"},
	})
	if itertools.size(self.limitInfo) == 0 then
		self.rightTop:hide()
	end
end

function GymChallengeEmbattleView:limtFunc(dbid, card_id,skin_id, fighting_point, level, star, advance, created_time, nature_choose, inBattle)
	local hashMap = itertools.map(self.limitInfo or {}, function(k, v) return v, 1 end)
	local cardCsv = csv.cards[card_id]
	local unitCsv = csv.unit[cardCsv.unitID]
	-- csvSize(self.limitInfo) == 0 不限制
	if csvSize(self.limitInfo) == 0 or hashMap[unitCsv.natureType] or hashMap[unitCsv.natureType2] then
		return CardEmbattleView.limtFunc(self, dbid, card_id,skin_id, fighting_point, level, star, advance, created_time, nature_choose, inBattle)
	else
		return nil
	end
end


-- 给界面上的精灵添加拖拽功能
function GymChallengeEmbattleView:initHeroSprite()
	self.heroSprite = {}
	--初始化精灵容器
	for i = 1, self.embattleMax do
		local tmpPanel = self.upItem:clone():addTo(self.battlePanel, 2, "panel"..i)
		tmpPanel:show()
		self.heroSprite[i] = {sprite = tmpPanel, dbid = nil, idx = i}
	end
	local intervalX = 50
	local itemWidth = self.upItem:width()
	local battleSize = self.battlePanel:size()
	local posXStart = 0
	if self.embattleMax <= 6 then
		local width = (itemWidth + intervalX) * (self.embattleMax - 1)
		posXStart =  battleSize.width/2 - width / 2
		for i = 1, self.embattleMax do
			self.heroSprite[i].sprite:xy(posXStart + (i - 1) * (itemWidth + intervalX), battleSize.height/2 + 110)
		end
	else
		local width = (itemWidth + intervalX) * (math.ceil(self.embattleMax / 2) - 1)
		posXStart =  battleSize.width / 2 - width / 2
		local height = self.upItem:height()
		for i = 1, self.embattleMax do
			local ii = self.embattleMax - math.floor(self.embattleMax / 2)
			if i <= math.ceil(self.embattleMax / 2) then
				self.heroSprite[i].sprite:xy(posXStart + (i - 1) * (itemWidth + intervalX), battleSize.height/2 + 120 + height/2 +5 )
			else
				self.heroSprite[i].sprite:xy(posXStart + (i - ii - 1) * (itemWidth + intervalX), battleSize.height/2 + 120 - height/2  - 5)
			end
		end
	end

	--上阵下阵操作
	local oldBattleHash = {}
	idlereasy.when(self.clientBattleCards,function (_, battle)
		local battleNum = 0
		local equal = true
		for i = 1, self.embattleMax do
			local spriteTb = self.heroSprite[i]
			local item = spriteTb.sprite
			local dbid = battle[i]
			spriteTb.sprite:get("tagIdx"):text(string.format(gLanguageCsv.unionFightRound, i))
			item:onTouch(functools.partial(self.onBattleCardTouch, self, i))
			if dbid then
				local data = gGameModel.cards:find(dbid)
				item:get("add"):hide()
				local info = item:get("info"):show()
				local childs = info:multiget("head", "level", "text", "fightPoint", "attr1", "attr2")
				childs.fightPoint:text(data:read("fighting_point"))
				adapt.oneLineCenterPos(cc.p(170, 50),{childs.text,childs.fightPoint}, cc.p(5, 0))
				childs.level:text("Lv" .. data:read("level"))
				local unitID = dataEasy.getUnitId(data:read("card_id"),data:read("skin_id"))
				local unitCsv = csv.unit[unitID]
				local attr1 = unitCsv.natureType
				local attr2 = unitCsv.natureType2
				childs.attr1:texture(ui.ATTR_ICON[attr1])
				childs.attr2:visible(attr2 and true or false)
				adapt.oneLineCenterPos(cc.p(170, 140),{childs.level,childs.attr1, childs.attr2}, cc.p(5, 0))
				if attr2 then
					childs.attr2:texture(ui.ATTR_ICON[attr2])
				end
				info:removeChildByName("starPanel")
				uiEasy.getStarPanel(data:read("star"), {align = "center", interval = -5})
					:scale(0.35)
					:xy(170, 100)
					:addTo(info, 2)

				bind.extend(self, childs.head, {
					class = "card_icon",
					props = {
						unitId = unitID,
						rarity = data:read("rarity"),
						advance = data:read("advance"),
						onNode = function(panel)
							panel:xy(-6, -6)
						end,
					},
				})
				battleNum = battleNum + 1
			else
				item:get("add"):show()
				item:get("info"):hide()
			end
			if not oldBattleHash[battle[i]] and battle[i] then
				equal = false
			end
		end
		if not equal or (itertools.size(oldBattleHash) ~= battleNum) then
			oldBattleHash = itertools.map(battle, function(k, v) return v, k end)
		end
		self.battleNum:set(battleNum.."/"..self.embattleMax)
	end)
end

function GymChallengeEmbattleView:createMovePanel(data)
	if self.movePanel then
		self.movePanel:removeSelf()
	end
	local movePanel = self.spriteItem:clone():addTo(self:getResourceNode(), 1000)
	bind.extend(self, movePanel, {
		class = "card_icon",
		props = {
			unitId = data.unit_id,
			advance = data.advance,
			rarity = data.rarity,
			star = data.star,
			levelProps = {
				data = data.level,
			},
			onNode = function(panel)
				panel:xy(-2, -2)
			end,
		}
	})
	movePanel:show()
	self.movePanel = movePanel
	return movePanel
end


function GymChallengeEmbattleView:onBattleCardTouch(i, event)
	local dbid = self.clientBattleCards:read()[i]
	if not dbid then
		return
	end
	local data = self:getCardAttrs(dbid)
	if event.name == "began" then
		self:createMovePanel(data)
		self.selectIndex:set(i)
		self.heroSprite[i].sprite:get("info"):hide()
		self.heroSprite[i].sprite:get("add"):show()
		self.movePanel:xy(event.x, event.y)
	elseif event.name == "moved" then
		self:moveMovePanel(event)
	elseif (event.name == "ended" or event.name == "cancelled") then
		self.heroSprite[i].sprite:get("info"):show()
		self.heroSprite[i].sprite:get("add"):hide()
		self:deleteMovingItem()
		if event.y < 340 then
			-- 下阵
			self:onCardClick(data, true)
		else
			local targetIdx = self:whichEmbattleTargetPos(event)
			if targetIdx  then
				if targetIdx ~= i then
					self:onCardMove(data, targetIdx, true)
					audio.playEffectWithWeekBGM("formation.mp3")
				else
					self:onCardMove(data, targetIdx, false)
				end
			else
				self:onCardMove(data, i, false)
			end
		end
	end
end

--是否跟换
function GymChallengeEmbattleView:whichEmbattleTargetPos(p)
	for i, v in pairs(self.heroSprite) do
		local item = v.sprite
		local rect = item:box()
		local pos = item:getParent():convertToWorldSpace(cc.p(rect.x, rect.y))
		rect.x, rect.y = pos.x, pos.y
		if cc.rectContainsPoint(rect, p) then
			return i
		end
	end
end


function GymChallengeEmbattleView:onClose()
	local date = gGameModel.gym:read("date")
	local battleCards = self.clientBattleCards:read()
	local battleCardsHex = {}
	for k, v in pairs(battleCards) do
		battleCardsHex[k] = stringz.bintohex(v)
	end
	local ViewBase = cc.load("mvc").ViewBase
	ViewBase.onClose(self)
end

return GymChallengeEmbattleView