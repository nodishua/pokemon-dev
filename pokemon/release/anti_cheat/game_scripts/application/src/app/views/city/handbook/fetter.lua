--
-- @data 2019-7-22 11:05:43
-- @desc: 图鉴羁绊
--

local function setItemToList(list, node, item, id, open)
	local cardCfg = csv.cards[id]
	local unitCfg = csv.unit[cardCfg.unitID]
	bind.extend(list, item:get("head"), {
		class = "card_icon",
		props = {
			cardId = id,
			rarity = unitCfg.rarity,
			grayState = open and 0 or 2,
			onNode = function(panel)
				panel:scale(0.8)
			end,
		}
	})
	local color = open and ui.COLORS.NORMAL.DEFAULT or ui.COLORS.NORMAL.GRAY
	text.addEffect(item:get("textName"), {color = color})
	item:get("textName"):text(cardCfg.name)
	item:get("textName"):setFontSize(30)
	node:get("list"):pushBackCustomItem(item)
	node:get("list"):adaptTouchEnabled()
end

local HandBookFetterView = class("HandBookFetterView", cc.load("mvc").ViewBase)

HandBookFetterView.RESOURCE_FILENAME = "handbook_fetter.json"
HandBookFetterView.RESOURCE_BINDING = {
	["baseNode.textName"] = "nodeName",
	["item"] = "item",
	["roleItem"] = "roleItem",
	["baseNode.list"] = {
		varname = "list",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("fetterDatas"),
				subItem = bindHelper.self("roleItem"),
				cardId = bindHelper.self("cardIdIdler"),
				item = bindHelper.self("item"),
				itemAction = {isAction = true, alwaysShow = true},
				onItem = function(list, node, k, data)
					node:removeChildByName('richtext')
					node:get("list"):setScrollBarEnabled(false)
					local fetter = csv.fetter[data.id]
					local imgTitle = node:get("title.imgBg")
					local txtTitle = node:get("title.textName")
					txtTitle:text(fetter.name)
					if matchLanguage({"en"}) then
						imgTitle:size(txtTitle:size().width + 50, imgTitle:size().height)
						node:get("title"):anchorPoint(0, 0.5)
						imgTitle:anchorPoint(0, 0.5)
						txtTitle:anchorPoint(0, 0.5)
						node:get("title"):x(node:get("title"):x() - 328)
						txtTitle:x(txtTitle:x() + 25)
						adapt.oneLinePos(txtTitle, node:get("textTip"), cc.p(-100,0))
					else
						adapt.setTextScaleWithWidth(node:get("title.textName"), nil, 300)
					end
					local cardState = {}
					-- 不显示自己，显示上有些问题
					-- table.insert(cardState,{id = list.cardId:read(),state = data.pokedex[list.cardId:read()]~= nil})
					local isEqual, canUsed = false, true
					for i,v in ipairs(fetter.cards) do
						local csvCards = csv.cards[v]
						local isInClude = data.pokedex[v] ~= nil
						table.insert(cardState,{id = data.cardDatas[csvCards.cardMarkID] or v,state = isInClude})
						if not isInClude then
							canUsed = false
						end
					end
					for _,v in ipairs(cardState) do
						setItemToList(list, node, list.subItem:clone():show(), v.id, v.state)
					end
					local path1 = "common/box/box_jb_00.png"
					local path2 = "common/box/tag__jb_01.png"
					local outLineColor = cc.c4b(166, 151, 149, 255)
					if canUsed then
						path1 = "common/box/box_jb_01.png"
						path2 = "common/box/tag__jb_00.png"
						outLineColor = cc.c4b(229, 103, 92, 255)
					end
					node:get("imgBg"):texture(path1)
					node:get("title.imgBg"):texture(path2)
					text.addEffect(node:get("title.textName"), {outline = {color = outLineColor, size = 3}})
					node:get("textTip"):visible(not canUsed)
					-- adapt.oneLinePos(node:get("title.imgBg"), node:get("textTip"), cc.p(50,0))
					local strs = {}
					local color = canUsed and "#C0xF76B45#" or ""
					for i,v in csvPairs(fetter.attrMap) do
						local name = getLanguageAttr(i)
						local str = string.format("#C0x5B545B#%s"..gLanguageCsv.improve.." %s",name, dataEasy.getAttrValueString(i, v))--EF3453
						table.insert(strs,str)
					end
					local str = table.concat(strs, " ")
					local richText = rich.createWithWidth(str, 40, nil, 1000)
						:setAnchorPoint(cc.p(0, 0.5))
						:xy(38, 244)
						:addTo(node, 10, "richtext")
				end,
			}
		},
	},
	["baseNode.tip"] = "tip",
}

function HandBookFetterView:onCreate(params)
	self:initModel()
	self.cardIdIdler = params.selCardId()
	self.fetterDatas = idlers.newWithMap({})
	idlereasy.any({self.cardDatas, self.cardIdIdler, self.pokedex}, function(_, cardDatas, cardId, pokedex)
		local cardCsv = csv.cards[cardId]
		local data,cardIds = {},{}
		for i,v in ipairs(cardDatas) do
			local card = gGameModel.cards:find(v)
			-- 分解之后 选中的dbid改变 服务器的cards还没有同步过来就会导致这边find是nil
			if card then
				local cardId = card:read("card_id")
				local cardMarkID = csv.cards[cardId].cardMarkID
				local originCardId = cardIds[cardMarkID]
				if not originCardId or cardId > originCardId then
					cardIds[cardMarkID] = cardId
				end
			end
		end
		local fetterNum = csvSize(cardCsv.fetterList)
		for i=1,fetterNum do
			data[i] = {id = cardCsv.fetterList[i], cardDatas = cardIds, pokedex = pokedex}
		end
		self.fetterDatas:update(data)
		self.tip:visible(fetterNum<=0)
		local attrTab = {}
		local unit = csv.unit[cardCsv.unitID]
		table.insert(attrTab, unit.natureType)
		if unit.natureType2 then
			table.insert(attrTab, unit.natureType2)
		end
	end)
end

function HandBookFetterView:initModel()
	self.cardDatas = gGameModel.role:getIdler("cards")
	self.pokedex = gGameModel.role:getIdler("pokedex")
end

return HandBookFetterView