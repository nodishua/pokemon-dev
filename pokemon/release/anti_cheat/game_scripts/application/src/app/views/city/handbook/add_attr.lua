-- @date:   2019-4-1
-- @desc:   图鉴属性增加

local HandbookAttrAddView = class("HandbookAttrAddView", cc.load("mvc").ViewBase)

HandbookAttrAddView.RESOURCE_FILENAME = "handbook_attadd.json"
HandbookAttrAddView.RESOURCE_BINDING = {
	["panel"] = {
		binds = {
			event = "click",
			method = bindHelper.self("onClose"),
		},
	},
	["panel.item"] = "item",
	["panel.innerList"] = "innerList",
	["panel.list"] = {
		binds = {
			event = "extend",
			class = "tableview",
			props = {
				data = bindHelper.self("attrDatas"),
				item = bindHelper.self("innerList"),
				cell = bindHelper.self("item"),
				columnSize = 3,
				onCell = function(list, node, k, v)
					local attrTypeStr = game.ATTRDEF_TABLE[k]
					local str = "attr" .. string.caption(v.key)
					node:get("textName"):text(gLanguageCsv[str])
					local data = mathEasy.getPreciseDecimal(v.val, 2)
					adapt.setTextScaleWithWidth(node:get("textNum"), "+" .. data .. "%", 160)
					node:get("imgIcon"):texture(ui.ATTR_LOGO[v.key])
					adapt.oneLinePos(node:get("imgIcon"), node:get("textName"), cc.p(8, 0), "left")
					adapt.oneLinePos(node:get("textName"), node:get("textNum"), nil, "left")
				end,
				dataOrderCmp = function(a, b)
					return a.idx < b.idx
				end,
			},
		},
	},
}

function HandbookAttrAddView:onCreate(params)
	self:initModel()
	gGameModel.handbook:getIdlerOrigin("isNew"):set(false)

	local attrDatas = {
		[1] = {idx = 1, val = 0, key = "hp"},
		[7] = {idx = 2, val = 0, key = "damage"},
		[8] = {idx = 3, val = 0, key = "specialDamage"},
		[9] = {idx = 4, val = 0, key = "defence"},
		[10] = {idx = 5, val = 0, key = "specialDefence"},
		[13] = {idx = 6, val = 0, key = "speed"},
	}
	for cardId,_ in pairs(self.pokedex:read()) do
		local csvData = gHandbookCsv[cardId]
		if csvData then
			for i=1,math.huge do
				local attrType = csvData["attrType"..i]
				if not attrType then
					break
				end
				local val, numType = dataEasy.parsePercentStr(csvData["attrValue"..i])
				val = mathEasy.getPreciseDecimal(val, 2)
				attrDatas[attrType].val = attrDatas[attrType].val + val
			end
		end
	end
	local starAdd = {}
	for k,v in ipairs(self.cards:read()) do
		local card = gGameModel.cards:find(v)
		local cardId = card:read("card_id")
		local star = card:read("star")
		local cardCsv = csv.cards[cardId]
		local cardMarkID = cardCsv.cardMarkID
		local pokedexDevelopCsv = gPokedexDevelop[cardMarkID][star]
		local val, numType = dataEasy.parsePercentStr(pokedexDevelopCsv.attrValue1)
		val = mathEasy.getPreciseDecimal(val, 2)
		starAdd[cardMarkID] = starAdd[cardMarkID] or {typ = pokedexDevelopCsv.attrType1, val = val}
		if starAdd[cardMarkID].val < val then
			starAdd[cardMarkID].val = val
		end
	end
	for k,v in pairs(starAdd) do
		attrDatas[v.typ].val = attrDatas[v.typ].val + v.val
	end
	self.attrDatas = idlers.newWithMap(attrDatas)
end

function HandbookAttrAddView:initModel()
	self.pokedex = gGameModel.role:getIdler("pokedex")--卡牌
	self.cards = gGameModel.role:getIdler("cards")
end

return HandbookAttrAddView