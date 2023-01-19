-- @date:   2019-06-10
-- @desc:   公会选择精灵
local REQUEST_TYPE = {
	--放入
	["start"] = "/game/union/training/start",
	--替换
	["replace"] = "/game/union/training/replace",
}
local UnionSelectSpriteView = class("UnionSelectSpriteView", Dialog)

UnionSelectSpriteView.RESOURCE_FILENAME = "union_select_sprite.json"
UnionSelectSpriteView.RESOURCE_BINDING = {
	["btnClose"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")}
		},
	},
	["item"] = "item",
	["subList"] = "subList",
	["list"] = {
		varname = "list",
		binds = {
			event = "extend",
			class = "tableview",
			props = {
				data = bindHelper.self("cardDatas"),
				columnSize = 7,
				item = bindHelper.self("subList"),
				cell = bindHelper.self("item"),
				itemAction = {isAction = true},
				onCell = function(list, node, k, v)
					bind.extend(list, node, {
						class = "card_icon",
						props = {
							unitId = v.unitId,
							advance = v.advance,
							rarity = v.rarity,
							star = v.star,
							grayState = v.selectState and 1 or 0,
							levelProps = {
								data = v.level,
							}
						}
					})
					node:get("mask"):visible(v.selectState):texture("img/kongbai.png")
					node:get("mask.icon"):xy(40, 40)
					bind.touch(list, node, {methods = {ended = functools.partial(list.itemClick,list:getIdx(k), v)}})
				end,
				asyncPreload = 38,
				onAfterBuild = function(list)
					list.afterBuild()
				end,
			},
			handlers = {
				itemClick = bindHelper.self("onFrameItemClick"),
				afterBuild = bindHelper.self("onAfterBuild"),
			},
		},
	},
	["maskPanel"] = "maskPanel",
	["btnSure"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClickSure")}
		},
	},
	["btnSure.title"] = {
		binds = {
			event = "effect",
			data = {color = ui.COLORS.NORMAL.WHITE, glow = {color = ui.COLORS.GLOW.WHITE}},
		},
	},
	["textNum"] = "textNum"
}

function UnionSelectSpriteView:onCreate(params)
	self.subList:setScrollBarEnabled(false)
	self.idx = params.idx
	self.requestTyp = params.requestTyp
	self.selectMax = params.selectMax or 1
	self:initModel()
	self.cardDatas = idlers.new()
	self.textNum:text("0/"..self.selectMax)
	local slots = {}
	for i,v in pairs(self.slots:read()) do
		slots[v.id] = true
	end
	local cardInfos = {}
	for i,v in pairs(self.cards:read()) do
		if not slots[v] then
			local card = gGameModel.cards:find(v)
			local cardData = card:read("card_id","skin_id", "name", "level", "star", "advance", "fighting_point")
			local cardCsv = csv.cards[cardData.card_id]
			local unitCsv = csv.unit[cardCsv.unitID]
			local unitId = dataEasy.getUnitId(cardData.card_id, cardData.skin_id)
			table.insert(cardInfos, {
				id = cardData.card_id,
				unitId = unitId,
				rarity = unitCsv.rarity,
				level = cardData.level,
				star = cardData.star,
				advance = cardData.advance,
				dbid = v,
				fight = cardData.fighting_point,
				selectState = false
			})
		end
	end
	table.sort(cardInfos, function(a,b)
		return a.fight > b.fight
	end)
	self.cardDatas:update(cardInfos)
	self.selectNum = 0
	self.selectIdx = idler.new(0)
	if self.selectMax > 1 then
		idlereasy.when(self.selectIdx, function(_, selectIdx)
			if self.cardDatas:atproxy(selectIdx) then
				local cardDatas = self.cardDatas:atproxy(selectIdx)
				if self.selectNum >= self.selectMax and cardDatas.selectState == false then
					return
				end
				self.selectNum = self.selectNum + (cardDatas.selectState == false and 1 or -1)
				self.textNum:text(self.selectNum.."/"..self.selectMax)
				cardDatas.selectState = not cardDatas.selectState
			end
		end)
	else
		--单选的情况
		self.selectIdx:addListener(function(val, oldval)
		local cardDatas = self.cardDatas:atproxy(val)
		local oldCardDatas = self.cardDatas:atproxy(oldval)
		if oldCardDatas then
			oldCardDatas.selectState = false
		end
		if cardDatas then
			self.selectNum = 1
			self.textNum:text(self.selectNum.."/"..self.selectMax)
			cardDatas.selectState = true
		end
	end)
	end
	Dialog.onCreate(self)
end

function UnionSelectSpriteView:initModel()
	local trainInfo = gGameModel.union_training
	self.slots = trainInfo:getIdler("slots")
	self.cards = gGameModel.role:getIdler("cards")--卡牌
end

function UnionSelectSpriteView:onFrameItemClick(list, t, v)
	self.selectIdx:set(t.k)
end

function UnionSelectSpriteView:onClickSure()
	local selectIdx = self.selectIdx:read()
	if self.selectNum == 0 then
		gGameUI:showTip(gLanguageCsv.pleaseSelectSprite)
		return
	end
	local cardID = self.cardDatas:atproxy(selectIdx).dbid
	gGameApp:requestServer(REQUEST_TYPE[self.requestTyp],function (tb)
		self:onClose()
	end, self.idx, cardID)
end

function UnionSelectSpriteView:onAfterBuild()
	uiEasy.setBottomMask(self.list, self.maskPanel)
end
return UnionSelectSpriteView