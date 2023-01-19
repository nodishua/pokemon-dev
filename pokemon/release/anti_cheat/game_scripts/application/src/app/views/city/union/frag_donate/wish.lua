-- @date:   2020-02-28
-- @desc:   许愿选择精灵

local UnionFragDonateWishView = class("UnionFragDonateWishView", Dialog)

UnionFragDonateWishView.RESOURCE_FILENAME = "union_frag_donate_wish.json"
UnionFragDonateWishView.RESOURCE_BINDING = {
	["title.btnClose"] = {
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
				columnSize = 3,
				item = bindHelper.self("subList"),
				dataOrderCmpGen = bindHelper.self("onSortDatas", true),
				cell = bindHelper.self("item"),
				itemAction = {isAction = true},
				onCell = function(list, node, k, v)
					local childs = node:multiget("icon", "name", "num", "bar", "mask")
					bind.extend(list, childs.icon, {
						class = "card_icon",
						props = {
							levelProps = {
								data = v.level,
							},
							rarity = v.rarity,
							unitId = v.unitId,
							advance = v.advance,
							star = v.star,
							onNode = function(node)
								node:scale(1)
							end
						}
					})
					childs.mask:visible(v.selectState)
					uiEasy.setIconName("card", v.cardId, {node = childs.name, name = v.name, advance = v.advance, space = true})
					childs.num:text(v.num.."/"..v.needNum)
					childs.bar:percent(cc.clampf(v.num/v.needNum*100, 0, 100))
					bind.touch(list, node, {methods = {ended = functools.partial(list.itemClick, list:getIdx(k), v)}})
				end,
				asyncPreload = 9,
			},
			handlers = {
				itemClick = bindHelper.self("onFrameItemClick"),
			},
		},
	},
	["textNum"] = "textNum",
	["btnSure"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onSureClick")}
		},
	},
	["btnSure.title"] = {
		binds = {
			event = "effect",
			data = {glow = {color = ui.COLORS.GLOW.WHITE}},
		},
	},
}

function UnionFragDonateWishView:onCreate(params)
	local params = params or {}
	self.isDailySelected = params.isDailySelected or false
	self.callBack = params.callBack
	self:initModel()
	self.cardDatas = idlers.new()
	--背包里有的卡牌战力数据
	local cardDatas = {}
	for i,v in ipairs(self.cards:read()) do
		local card = gGameModel.cards:find(v)
		local cardData = card:read("card_id","skin_id", "name", "fighting_point", "level", "star", "advance")
		local cardCsv = csv.cards[cardData.card_id]
		local unitCsv = csv.unit[cardCsv.unitID]
		local fragCsv = csv.fragments[cardCsv.fragID]
		local unitId = dataEasy.getUnitId(cardData.card_id, cardData.skin_id)
		if fragCsv.donateType == 1 and (not cardDatas[cardCsv.cardMarkID] or cardDatas[cardCsv.cardMarkID].fight < cardData.fighting_point) then
			cardDatas[cardCsv.cardMarkID] = {
				cardId = cardData.card_id,
				unitId = unitId,
				name = cardData.name,
				rarity = unitCsv.rarity,
				fight = cardData.fighting_point,
				level = cardData.level,
				star = cardData.star,
				advance = cardData.advance,
				dbid = v,
				cardMarkID = cardCsv.cardMarkID,
				needNum = fragCsv.combCount,
				selectState = false,
				num = self.frags:read()[cardCsv.fragID] or 0
			}
		end
	end
	self.cardDatas:update(cardDatas)

	self.selectNum = 0
	self.selectIdx = idler.new()
	self.selectIdx:addListener(function(val, oldval)
		local oldCardData = self.cardDatas:atproxy(oldval)
		if oldCardData and val ~= oldval then
			oldCardData.selectState = false
		end
		local cardData = self.cardDatas:atproxy(val)
		if cardData then
			cardData.selectState = not cardData.selectState
			self.selectNum = cardData.selectState and 1 or 0
		end
		self.textNum:text(self.selectNum.."/1")
	end)
	Dialog.onCreate(self)
end

function UnionFragDonateWishView:initModel()
	self.cards = gGameModel.role:getIdler("cards")
	self.frags = gGameModel.role:getIdler("frags")
end
function UnionFragDonateWishView:onFrameItemClick(list, k, v)
	self.selectIdx:set(v.cardMarkID, true)
end

--点击选择卡牌
function UnionFragDonateWishView:onSureClick()
	if self.selectNum <= 0 then
		gGameUI:showTip(gLanguageCsv.notSelRole)
		return
	end
	local t = self.cardDatas:atproxy(self.selectIdx:read())
	-- 日常小助手 选择碎片
	if self.isDailySelected then
		self.callBack(t.cardId, function()
			self:onClose()
		end)
	else
		gGameApp:requestServer("/game/union/frag/donate/start", function (tb)
			self:onClose()
		end, t.dbid)
	end
end

function UnionFragDonateWishView:onSortDatas(list)
	return function(a, b)
		return a.fight > b.fight
	end
end
return UnionFragDonateWishView