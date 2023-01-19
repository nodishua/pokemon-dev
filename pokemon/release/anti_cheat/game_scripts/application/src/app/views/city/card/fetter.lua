-- @desc: 卡牌羁绊

local function setItemToList(list, node, item, id, open)
	local cardCfg = csv.cards[id]
	local unitCfg = csv.unit[cardCfg.unitID]
	bind.extend(list, item:get("icon"), {
		class = "card_icon",
		props = {
			cardId = id,
			rarity = unitCfg.rarity,
			grayState = open and 0 or 2,
			onNode = function(panel)
				panel:xy(-4, -4)
			end,
		}
	})
	local color = open and ui.COLORS.NORMAL.DEFAULT or ui.COLORS.NORMAL.GRAY
	text.addEffect(item:get("name"), {color = color})
	item:get("name"):text(cardCfg.name)
	item:get("mask"):visible(false)
	node:get("list"):pushBackCustomItem(item)
	node:get("list"):adaptTouchEnabled()
end

local CardFetterView = class("CardFetterView", Dialog)

CardFetterView.RESOURCE_FILENAME = "card_fetter.json"
CardFetterView.RESOURCE_BINDING = {
	["closeBtn"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")}
		},
	},
	["infoBtn"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onFetterInfo")}
		},
	},
	["subItem"] = "subItem",
	["item"] = "item",
	["list"] = {
		varname = "list",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("fetterDatas"),
				cardId = bindHelper.self("cardId"),
				subItem = bindHelper.self("subItem"),
				item = bindHelper.self("item"),
				onItem = function(list, node, k, v)
					local cardId = list.cardId
					local subItem = list.subItem
					local fetter = csv.fetter[v.id]
					local pokedex = gGameModel.role:read("pokedex")
					local cardState = {}
					table.insert(cardState,{id = cardId,state = true})
					for _,cardMarkID in ipairs(fetter.cards) do
						local cardId = v.cardDatas[cardMarkID] or cardMarkID
						table.insert(cardState,{
							id = cardId,
							state = pokedex[cardMarkID] ~= nil
						})
					end
					node:get("bg"):texture(string.format("city/card/system/fetter/box_pop_panel%d.png", v.isShow and 7 or 5))
					node:get("titleBg"):texture(string.format("city/card/system/fetter/box_pop_panel%d.png", v.isShow and 8 or 6))
					local title1 = node:get("title1")
					title1:text(fetter.name)
					if matchLanguage({"en"}) then
						adapt.setTextAdaptWithSize(title1, {size = cc.size(380,200), vertical = "center", horizontal = "center"})
					end
					node:get("title2"):visible(not v.isShow)
					node:get("txtPos"):removeAllChildren()
					local strs = {}
					for _,v in ipairs(cardState) do
						setItemToList(list, node, subItem:clone():show(), v.id, v.state)
					end
					local index = 0
					local n = csvSize(fetter.attrMap)
					local color = v.isShow and "#C0xF76B45#" or ""
					local format = "#C0x5B545B#%s%s%s %s "
					if matchLanguage({"en"}) then
						format = format .. "\n"
					end
					for i,v in csvPairs(fetter.attrMap) do
						index = index + 1
						local name = getLanguageAttr(i)
						local str = string.format(format, name, gLanguageCsv.improve, color, dataEasy.getAttrValueString(i, v))--EF3453
						table.insert(strs, str)
						if index < n then
							table.insert(strs, "\n")
						end
					end
					local str = table.concat(strs,"")
					local width = matchLanguage({"kr"}) and 470 or 350
					local fontSize = matchLanguage({"en"}) and 35 or 44
					local richText = rich.createWithWidth(str, fontSize, nil, width, 24)
					richText:setAnchorPoint(cc.p(0, 0.5))
					node:get("txtPos"):addChild(richText)
				end,
			}
		},
	},
}

function CardFetterView:onCreate(fetterDatas, cardId)
	self.cardId = cardId
	self.fetterDatas = fetterDatas
	self.item:get("list"):setScrollBarEnabled(false)
	Dialog.onCreate(self)
end

function CardFetterView:onClose()
	if self._closecb then
		self._closecb()
	end
	return Dialog.onClose(self)
end

function CardFetterView:onFetterInfo()
	gGameUI:stackUI("common.rule", nil, nil, self:createHandler("getRuleContext"), {width = 860})
end

function CardFetterView:getRuleContext(view)
	local c = adaptContext
	local context = {
		c.clone(view.title, function(item)
			item:get("text"):text(gLanguageCsv.fetterInfo)
		end),
		c.noteText(54001, 54003),
	}
	return context
end
return CardFetterView