
local ViewBase = cc.load("mvc").ViewBase
local CardAdvanceOneKeyView = class("CardAdvanceOneKeyView", Dialog)

CardAdvanceOneKeyView.RESOURCE_FILENAME = "card_advance_onekey.json"
CardAdvanceOneKeyView.RESOURCE_BINDING = {
	["closeBtn"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")}
		}
	},
	["top.cashNum"] = "cashNum",
	["top.nameMax"] = "nameMax",
	["top.name"] = "cardName",
	["top.subBtn"] = {
		varname = "subBtn",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onReduceClick")}
		}
	},
	["top.addBtn"] = {
		varname = "addBtn",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onAddClick")}
		}
	},
	["sureBtn"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onOneKeyAdvanceClick")}
		}
	},
	["cancelBtn"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")}
		}
	},
	["cancelBtn.title"] = {
		binds = {
			event = "effect",
			data = {color = ui.COLORS.NORMAL.WHITE, glow = {color = ui.COLORS.GLOW.WHITE}},
		},
	},
	["sureBtn.title"] = {
		binds = {
			event = "effect",
			data = {color = ui.COLORS.NORMAL.WHITE, glow = {color = ui.COLORS.GLOW.WHITE}},
		},
	},
	["card"] = {
		binds = {
			event = "extend",
			class = "card_icon",
			props = {
				cardId = bindHelper.self("cardId"),
				advance = bindHelper.self("advance"),
			},
		}
	},
	["item"] = "item",
	["subList"] = "subList",
	["list"] = {
		varname = "list",
		binds = {
			event = "extend",
			class = "tableview",
			props = {
				data = bindHelper.self("itemData"),
				columnSize = 6,
				item = bindHelper.self("subList"),
				cell = bindHelper.self("item"),
				onCell = function(list, node, k, v)
					local size = node:size()
					local binds = {
						class = "icon_key",
						props = {
							data = {
								key = v.id,
								num = v.num,
							},
						},
					}
					bind.extend(list, node, binds)
				end,
				asyncPreload = 12,
			},
		}
	},
}

function CardAdvanceOneKeyView:onCreate(selectDbId, cb)
	self.selectDbId = selectDbId
	self.cb = cb
	self:initModel()

	self.itemData = idlertable.new({})

	local advance = self.advance:read()
	local cardId = self.cardId:read()
	local cardLv = self.cardLv:read()

	local needGold = {}
	local needItems = {}
	local maxAdvance = advance + 1
	local needItemsTmp = {}

	local csvCards = csv.cards[cardId]
	local needLevel = csvCards.advanceLevelReq
	local csvAdvance = gCardAdvanceCsv[csvCards.advanceTypeID]
	for i=advance, csvSize(csvAdvance) do
		maxAdvance = i
		for k,v in pairs(needItemsTmp) do
			if not needItems[i] then
				needItems[i] = {}
			end
			table.insert(needItems[i], {id = k,num = v})
		end
		local csvAdvanceMax = csv.cards[cardId].advanceMax
		if cardLv < needLevel[i] or i >= csvAdvanceMax then
			break
		end
		needGold[i+1] = (needGold[i] or 0) + csvAdvance[i].gold
		if dataEasy.getNumByKey("gold") < needGold[i+1] then
			break
		end
		local lockItem = false
		for j,v in csvPairs(csvAdvance[i].itemMap) do
			needItemsTmp[j] = (needItemsTmp[j] or 0) + v
			if dataEasy.getNumByKey(j) < needItemsTmp[j] then
				lockItem = true
				break
			end
		end
		if lockItem then
			break
		end
	end
	self.selectAdvance = idler.new(maxAdvance)
	idlereasy.when(self.selectAdvance, function(_, selectAdvance)
		local tmpItems = needItems[selectAdvance] or {}
		if next(tmpItems) then
			table.sort(tmpItems, function(a,b)
				return a.id < b.id
			end)
		end
		self.itemData:set(tmpItems)
		self.cashNum:text(needGold[selectAdvance])
		cache.setShader(self.addBtn, false, (selectAdvance >= maxAdvance) and "hsl_gray" or  "normal")
		self.addBtn:setTouchEnabled(selectAdvance < maxAdvance)
		uiEasy.setIconName("card", cardId, {node = self.nameMax, name = ui.QUALITY_COLOR_TEXT, advance = selectAdvance, space = true})
		cache.setShader(self.subBtn, false, (selectAdvance <= advance+1) and "hsl_gray" or  "normal")
		self.subBtn:setTouchEnabled(selectAdvance > advance+1)
	end)
	uiEasy.setIconName("card", cardId, {node = self.cardName, name = ui.QUALITY_COLOR_TEXT, advance = advance, space = true})

	Dialog.onCreate(self)
end

function CardAdvanceOneKeyView:initModel()
	local card = gGameModel.cards:find(self.selectDbId)
	self.advance = card:getIdler("advance")
	self.cardId = card:getIdler("card_id")
	self.cardLv = card:getIdler("level")
	self.fight = card:getIdler("fighting_point")
end

function CardAdvanceOneKeyView:onAddClick()
	self.selectAdvance:set(self.selectAdvance:read()+1)
end

function CardAdvanceOneKeyView:onReduceClick()
	self.selectAdvance:set(self.selectAdvance:read()-1)
end

function CardAdvanceOneKeyView:onOneKeyAdvanceClick()
	gGameApp:requestServer("/game/card/advance",function (tb)
		self:addCallbackOnExit(self.cb)
		ViewBase.onClose(self)
	end, self.selectDbId, self.selectAdvance:read() - self.advance:read())
end

return CardAdvanceOneKeyView
