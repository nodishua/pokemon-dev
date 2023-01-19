local CardAttrDetailView = class("CardAttrDetailView", Dialog)

CardAttrDetailView.RESOURCE_FILENAME = "card_attrdetail.json"
CardAttrDetailView.RESOURCE_BINDING = {
	["closeBtn"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")},
		},
	},
	["bottomPanel.textList"] = "textList",
	["cardName"] = "cardNameTxt",
	["list"] = "bottomList",
	["bottomPanel"] = "bottomPanel",
	["list.centerPanel.attrPanel.item"] = "attrItem",
	["list.centerPanel.attrPanel.subList"] = "attrSubList",
	["list.centerPanel.attrPanel.list"] = {
		varname = "attrList",
		binds = {
			event = "extend",
			class = "tableview",
			props = {
				data = bindHelper.self("attrDatas"),
				columnSize = 2,
				item = bindHelper.self("attrSubList"),
				cell = bindHelper.self("attrItem"),
				onCell = function(list, node, k, v)
					node:get("txt1"):setString(v.txt1 .. ":")
					node:get("txt2"):setString(v.txt2)
					node:get("icon"):loadTexture(v.icon)
					adapt.oneLinePos(node:get("txt1"), node:get("txt2"), cc.p(20, 0), "left")
				end,
				asyncPreload = 6,
			},
		},
	},
	["list.centerPanel.attrPanel1.item"] = "attrItem1",
	["list.centerPanel.attrPanel1.innerList"] = "innerList",
	["list.centerPanel.attrPanel1.list"] = {
		varname = "attrList1",
		binds = {
			event = "extend",
			class = "tableview",
			props = {
				data = bindHelper.self("damageData"),
				item = bindHelper.self("innerList"),
				cell = bindHelper.self("attrItem1"),
				columnSize = 2,
				itemAction = {isAction = true},
				onCell = function(list, node, k, v)
					node:get("txt1"):setString(v.txt .. ":")
					local num = mathEasy.getPreciseDecimal(v.num, 2)
					node:get("txt2"):setString(dataEasy.getBuffShow(num))
					adapt.oneLinePos(node:get("txt1"), node:get("txt2"), cc.p(0, 0), "left")
				end,
			}
		},
	},
	["list.centerPanel.attrdetailBtn"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onEnterProperty")}
		},
	},
	["cardPanel.cardIcon"] = "cardIcon",
}

function CardAttrDetailView:onEnterProperty()
	gGameUI:stackUI("city.card.detailed_attribute", nil, nil)
end

function CardAttrDetailView:onCreate(selectDbId)
	self.selectDbId = selectDbId
	self:initModel()
	self.bottomList:setScrollBarEnabled(false)
	self.attrSubList:setScrollBarEnabled(false)
	self.innerList:setScrollBarEnabled(false)

	self.attrDatas = {}
	for i,v in ipairs(game.ATTRDEF_SIMPLE_TABLE) do
		local data = {
			txt1 = getLanguageAttr(v),
			txt2 = 0,
			icon = ui.ATTR_LOGO[v],
		}
		table.insert(self.attrDatas, data)
	end
	self.attrDatas = idlertable.new(self.attrDatas)

	local damageName = {
		"strike",
		"damageAdd",
		"strikeDamage",
		"damageSub",
		"strikeResistance",
		"ultimateAdd",
		"block",
		"ultimateSub",
		"breakBlock",
		"cure",

		"blockPower",
		"pvpDamageAdd",
		"controlPer",
		"pvpDamageSub",
		"immuneControl",

		"physicalDamageAdd",
		"defenceIgnore",
		"physicalDamageSub",
		"specialDefenceIgnore",
		"specialDamageAdd",
		"suckBlood",
		"specialDamageSub",
		"rebound",
	}

	self.damageData = {}
	for i,v in ipairs(damageName) do
		self.damageData[i] = {txt = getLanguageAttr(v), num = ""}
	end
	self.damageData = idlertable.new(self.damageData)

	idlereasy.any({self.attrs, self.attrs2}, function(_, attrs, attrs2)
		self.attrDatas:modify(function(data)
			for i,v in ipairs(game.ATTRDEF_SIMPLE_TABLE) do
				data[i].txt2 = math.floor(attrs[v])
			end
		end, true)
		self.damageData:modify(function(data)
			for i,v in ipairs(damageName) do
				if attrs[v] ~= nil then
					data[i].num = math.floor(attrs[v])
				else
					if attrs2[v] ~= nil then
						data[i].num = math.floor(attrs2[v])
					else
						data[i].num = 0
					end
				end
			end
		end, true)
	end)

	local cardId = self.cardId:read()
	local content = csv.cards[cardId].introduction
	beauty.textScroll({
		list = self.textList,
		strs = content,
		isRich = false,
		align = "left",
	})

	-- local unitId = self.unitId:read()
	local unitCsv = dataEasy.getUnitCsv(self.cardId:read(),self.skinId:read())
	local size = self.cardIcon:getContentSize()
	local sp = cc.Sprite:create(unitCsv.cardShow)
	-- local spSize = sp:size()
	-- local soff = cc.p(unitCsv.cardShowPosC.x/unitCsv.cardShowScale, -unitCsv.cardShowPosC.y/unitCsv.cardShowScale)
	-- local ssize = cc.size(size.width/unitCsv.cardShowScale, size.height/unitCsv.cardShowScale)
	-- local rect = cc.rect((spSize.width-ssize.width)/2-soff.x, (spSize.height-ssize.height)/2-soff.y, ssize.width, ssize.height)

	sp:alignCenter(size)
		-- :scale((unitCsv.cardShowScale + 0.2) *0.8)
		-- :setTextureRect(rect)
		:addTo(self.cardIcon, 5,"icon")

	local name = csv.cards[self.cardId:read()].name
	self.cardNameTxt:text(name)

	Dialog.onCreate(self)
end

function CardAttrDetailView:initModel()
	local card = gGameModel.cards:find(self.selectDbId)
	self.cardName = card:getIdler("name")
	self.cardId = card:getIdler("card_id")
	self.advance = card:getIdler("advance")
	self.unitId = card:getIdler("unit_id")
	self.skinId = card:getIdler("skin_id")
	self.attrs = card:getIdler("attrs")
	--新加属性
	self.attrs2 = card:getIdler("attrs2")
end

return CardAttrDetailView
