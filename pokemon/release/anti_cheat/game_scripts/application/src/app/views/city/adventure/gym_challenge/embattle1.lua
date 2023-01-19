local ViewBase = cc.load("mvc").ViewBase
local CardEmbattleView = require "app.views.city.card.embattle.base"
local GymChallengeEmbattleView = class("GymChallengeEmbattleView", CardEmbattleView)

GymChallengeEmbattleView.RESOURCE_FILENAME = "gym_embattle1.json"
GymChallengeEmbattleView.RESOURCE_BINDING = {
	["btnGHimg"] = {
		varname = "btnGHimg",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onTeamBuffClick")}
		}
	},
	["battlePanel"] = "battlePanel",
	["spritePanel"] = "spriteItem",
	["textNotRole"] = "emptyTxt",
	["fightNote"] = "fightNote",
	["fightNote.textFightPoint"] = {
		binds = {
			event = "text",
			idler = bindHelper.self("fightSumNum"),
		},
	},
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

	["rightDown.btnSave"] = {
		varname = "btnSave",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("saveBtn")}
		},
	},
	["rightDown.btnSave.textNote"] = {
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
}


function GymChallengeEmbattleView:onCreate(params)
	gGameUI.topuiManager:createView("title", self, {onClose = self:createHandler("onClose", false)})
		:init({title = gLanguageCsv.formation, subTitle = "FORMATION"})

	self.spriteItem:get("attrBg"):hide()
	self:initDefine(params)
	self:initParams(params)
	self:initModel(params)
	self:checkTeamBuffOpen()
	self:initRoundUIPanel()
	self:initHeroSprite()
	self:initBottomList()
	self.haveSaved = false -- 是否保存过阵容
	if self.from == game.EMBATTLE_FROM_TABLE.gymChallenge then
		local battleCards = self.battleCardsData:read()
		if itertools.size(battleCards) == 0 then
			battleCards = self:getOneKeyCardDatas()
			self.battleCardsData:set(battleCards)
		end
	elseif self.from == game.EMBATTLE_FROM_TABLE.onekey then
		local battleCards = self:getOneKeyCardDatas()
		self.battleCardsData:set(battleCards)
	end
end

function GymChallengeEmbattleView:initDefine(params)
	--最大可上阵数
	if params.gateId then
		self.embattleMax = csv.gym.gate[params.gateId].deployCardNumLimit
	else
		self.embattleMax = 6
	end
	self.panelNum = 6    --布阵底座数量
	self.gymId = params.gymId
end

function GymChallengeEmbattleView:initParams(params)
	params = params or {}
	self.from =  params.from
	self.sceneType = game.SCENE_TYPE.gym
	self.fightCb = params.fightCb
	self.saveCb = params.saveCb
	if params.gateId then
		self.limitInfo = csv.gym.gate[params.gateId].deployNatureLimit
	else
		self.limitInfo = params.limitInfo
	end
	self.checkBattleArr = params.checkBattleArr or function()
		return true
	end
end

function GymChallengeEmbattleView:initRoundUIPanel()
	adapt.centerWithScreen("left", "right", nil, {
		{self.fightNote, "pos", "right"},
		{self.rightDown, "pos", "right"},
		{self.rightTop, "pos", "right"},
	})
	if itertools.size(self.limitInfo) == 0 then
		self.rightTop:hide()
	end

	self.btnChallenge:visible(self.fightCb and true or false)
	self.btnSave:visible(self.saveCb and true or false)
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

function GymChallengeEmbattleView:whichEmbattleTargetPos(p)
	for i, v in pairs(self.heroSprite) do
		local item = self.battlePanel:get("item"..i)
		local rect = item:box()
		local pos = item:getParent():convertToWorldSpace(cc.p(rect.x, rect.y))
		rect.x, rect.y = pos.x, pos.y
		if cc.rectContainsPoint(rect, p) then
			return i
		end
	end
end

function GymChallengeEmbattleView:saveBtn(sender)
	self.saveCb(self, self.clientBattleCards, self.battleCardsData, false)
end


function GymChallengeEmbattleView:onClose(sendRequeat)
	if sendRequeat == true then

	else
		if self.saveCb then
			if not self.haveSaved or not itertools.equal(self.clientBattleCards:read(), self.battleCardsData:read()) then
				local params = {
					cb = function()
						self.saveCb(self, self.clientBattleCards, self.battleCardsData, true)
					end,
					cancelCb = function()
						ViewBase.onClose(self)
					end,
					btnType = 2,
					content = gLanguageCsv.gymOutCanNotChangeEmbattle,
					clearFast = true,
				}
				gGameUI:showDialog(params)
			else
				ViewBase.onClose(self)
			end
		else
			if self.from == game.EMBATTLE_FROM_TABLE.gymChallenge then
				local date = gGameModel.gym:read("date")
				local battleCards = self.clientBattleCards:read()
				local battleCardsHex = {}
				for k, v in pairs(battleCards) do
					battleCardsHex[k] = stringz.bintohex(v)
				end
				userDefault.setForeverLocalKey("gym_emabttle"..self.gymId, battleCardsHex, {new = true})
			end
			ViewBase.onClose(self)
		end
	end
end


return GymChallengeEmbattleView