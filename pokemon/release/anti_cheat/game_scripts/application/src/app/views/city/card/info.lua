-- @date:   2018-12-29
-- @desc: 精灵信息

local CardInfoView = class("CardInfoView", Dialog)

CardInfoView.RESOURCE_FILENAME = "card_info.json"
CardInfoView.RESOURCE_BINDING = {
	["closeBtn"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")}
		},
	},
	["leftPanel"] = "leftPanel",
	["leftPanel.level"] = "cardLevel",
	["leftPanel.levelNote"] = "cardLevelNote",
	["leftPanel.power"] = "power",
	["leftPanel.powerNote1"] = "powerNote1",
	["leftPanel.cardImg"] = "cardImg",
	["leftPanel.rarity"] = "rarity",
	["leftPanel.btnAdd"] = {
		varname = "btnAdd",
		binds = {
			event = "visible",
			idler = bindHelper.self("hasHeldItem"),
		},
	},
	["leftPanel.btnAdd.bg"] = {
		binds = {
			event = "texture",
			idler = bindHelper.self("heldItemBg")
		},
	},
	["leftPanel.btnAdd.add"] = {
		varname = "icon",
		binds = {
			event = "texture",
			idler = bindHelper.self("heldItemIcon")
		},
	},
	["item"] = "item",
	["rightPanel.btnList"] = {
		varname = "btnList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("tabDatas"),
				item = bindHelper.self("item"),
				onItem = function(list, node, k, v)
					local btn = node:get("btn")
					local txt = btn:get("txt")
					txt:text(v.name)
					btn:setTouchEnabled(not v.isSelected)
					btn:setBright(not v.isSelected)
					btn:onClick(functools.partial(list.itemClick, k))
					if v.isSelected then
						text.addEffect(txt, {glow = {color = ui.COLORS.GLOW.WHITE}, color = ui.COLORS.NORMAL.WHITE})
					else
						text.addEffect(txt, {color = ui.COLORS.NORMAL.RED})
					end
				end,
			},
			handlers = {
				itemClick = bindHelper.self("onChangePage"),
			},
		},
	},
	["rightPanel.skillPanel"] = "skillPanel",
	["rightPanel.attributePanel"] = "attributePanel",
	["skillItem"] = "skillItem",
	["rightPanel.skillPanel.list"] = {
		varname = "skillList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("skillDatas"),
				item = bindHelper.self("skillItem"),
				zawakeSkills = bindHelper.self("zawakeSkills"),
				onItem = function(list, node, k, v)
					local childs = node:multiget("level", "name", "type", "icon", "bg", "btn", "levelNote")
					childs.level:text(v.level)
					adapt.oneLinePos(childs.level, childs.levelNote, cc.p(2, 0), "right")

					uiEasy.setSkillInfoToItems({
						name = childs.name,
						icon = childs.icon,
						type1 = childs.type,
					}, v.id)

					childs.bg:z(-1)
					node:removeChildByName("zawakeBg")
					childs.icon:removeChildByName("zawakeUp")
					if dataEasy.isZawakeSkill(v.id, list.zawakeSkills) then
						ccui.ImageView:create("city/zawake/panel_z2.png")
							:alignCenter(node:size())
							:addTo(node, 0, "zawakeBg")
						ccui.ImageView:create("city/drawcard/draw/txt_up.png")
							:scale(1.2)
							:align(cc.p(1, 1), 200, 190)
							:addTo(childs.icon, 1, "zawakeUp")
						local zawakeEffectID = csv.skill[v.id].zawakeEffect[1]
						childs.name:text(csv.skill[zawakeEffectID].skillName .. childs.name:text())
					end

					bind.touch(list, node, {methods = {ended = functools.partial(list.itemClick, k ,v)}})
				end,
			},
			handlers = {
				itemClick = bindHelper.self("onSkillDetail"),
			},
		},
	},
	["itemNature"] = "itemNature",
	["subList"] = "subList",
	["rightPanel.attributePanel.upPanel.list"] = {
		varname = "list",
		binds = {
			event = "extend",
			class = "tableview",
			props = {
				data = bindHelper.self("attrDatas"),
				columnSize = 2,
				item = bindHelper.self("subList"),
				cell = bindHelper.self("itemNature"),
				onCell = function(list, node, t, v)
					local childs = node:multiget("name", "num", "icon")
					childs.name:text(v.name..":")
					childs.num:text(v.num)
					childs.icon:texture(v.icon)
				end,
			},
		},
	},
	["rightPanel.attributePanel.downPanel.pos"] = {
		binds = {
			event = "extend",
			class = "draw_attr",
			props = {
				nvalue = bindHelper.self("nvalue"),
				type = "big",
				offsetPos = {
					{x = -225, y = -285 + 50},
					{x = -145, y = -315 + 50},
					{x = -145, y = -415 + 50},
					{x = -225, y = -445 + 50},
					{x = matchLanguage({"kr", "en"}) and -360 or -305, y = -415 + 50},
					{x = matchLanguage({"kr", "en"}) and -360 or -305, y = -315 + 50},
				},
				offset = {x = 100, y = 150},
				bgScale = 0.85
			},
		},
	},
	["btnClose"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")}
		},
	},
	["rightPanel.attributePanel.upPanel.nature"] = "nature",
	["rightPanel.attributePanel.upPanel.up"] = "up",
	["rightPanel.attributePanel.upPanel.upIcon"] = "upIcon",
	["rightPanel.attributePanel.upPanel.downIcon"] = "downIcon",
	["rightPanel.attributePanel.upPanel.down"] = "down",
	["rightPanel.attributePanel.upPanel.static1"] = "static1",
	["leftPanel.gender"] = "gender",
	["starItem"] = "starItem",
	["leftPanel.starList"] = {
		varname = "starList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("starData"),
				item = bindHelper.self("starItem"),
				onItem = function(list, node, k, v)
					node:get("img"):texture(v.icon)
					node:setTouchEnabled(false)
				end,
			},

		},
	}
}

function CardInfoView:onCreate(cardData)
	self.hasHeldItem = idler.new(false)
	self.heldItemBg = idler.new("common/box/box_carry.png")
	self.heldItemIcon = idler.new("common/btn/btn_add_icon.png")
	local held_item = cardData.held_item
	self.cardData = cardData
	self.zawakeSkills = self.cardData.zawake_skills
	local scale = 1
	if held_item then
		self.hasHeldItem:set(true)
		scale = 2
		local cfg = csv.held_item.items[held_item.held_item_id]
		self.heldItemIcon:set(cfg.icon)
		self.heldItemBg:set(string.format("city/card/helditem/panel_icon_%d.png", cfg.quality))

		if csvSize(cfg.exclusiveCards) > 0 then
			ccui.ImageView:create("common/icon/txt_zs.png")
				:xy(104, 180)
				:addTo(self.btnAdd, 16, "exclusive")
		end
		local lb1 = cc.Label:createWithTTF("Lv", ui.FONT_PATH, 30)
			:xy(154, 60)
			:addTo(self.btnAdd, 8, "textLv")
		local lb2 = cc.Label:createWithTTF(held_item.level, ui.FONT_PATH, 38)
			:xy(154, 60)
			:addTo(self.btnAdd, 8, "textLvNum")

		text.addEffect(lb1, {outline = {color = ui.COLORS.OUTLINE.DEFAULT}})
		text.addEffect(lb2, {outline = {color = ui.COLORS.OUTLINE.DEFAULT}})
		adapt.oneLineCenterPos(cc.p(110, 33), {lb1, lb2}, cc.p(5, 3))
		local panelSize = {height = 1350, width = 900}
		local panel = ccui.Layout:create()
			:addTo(self, 1)
			:setAnchorPoint(cc.p(0.5, 0.5))
			:alignCenter(panelSize)

		bind.click(self, self.btnAdd, {method = function()
			local params = {key = held_item.held_item_id, advance = held_item.advance, level = held_item.level}
			gGameUI:showItemDetail(panel, params)
		end})
	end
	self.icon:scale(scale)
	local desc = csv.character[cardData.character].name
	if csvSize(csv.character[cardData.character].attrMap) ~= 0 then
		desc = desc .. gLanguageCsv.symbolBracketLeft
		self.nature:text(desc)
		local t = {}
		for i,v in csvMapPairs(csv.character[cardData.character].attrMap) do
			local num = string.match(v,"%d+")
			table.insert(t, {id = i, num = num})
		end
		table.sort(t, function (a, b)
			return tonumber(a.num) > tonumber(b.num)
		end)
		self.up:text(getLanguageAttr(t[1].id)..math.abs(t[1].num - 100).."%")
		self.down:text(getLanguageAttr(t[2].id)..math.abs(t[2].num - 100).."%")
		adapt.oneLinePos(self.nature, {self.up, self.upIcon, self.down, self.downIcon, self.static1}, cc.p(5, 0))
	else
		self.nature:text(desc)
		itertools.invoke({self.up, self.upIcon, self.down, self.downIcon, self.static1}, "hide")
	end
	if cardData.gender == 0 then
		self.gender:hide()
	elseif cardData.gender == 1 then
		self.gender:texture("other/gain_sprite/icon_man.png")
	else
		self.gender:texture("other/gain_sprite/icon_woman.png")
	end
	self:initModel()

	local unit = dataEasy.getUnitCsv(cardData.card_id, cardData.skin_id)
	local childs = self.leftPanel:multiget("rarity", "name", "attr1", "attr2", "starList", "cardImg", "masterName", "masterNameNote")
	childs.rarity:texture(ui.RARITY_ICON[unit.rarity])
	childs.masterName:text(cardData.role_name or self.myName:read())
	adapt.oneLineCenterPos(cc.p(self.cardImg:x(), childs.masterName:y()), {childs.masterNameNote, childs.masterName}, cc.p(25, 0))
	childs.name:text(uiEasy.setIconName("card", cardData.card_id, {node = childs.name, name = cardData.name, advance = cardData.advance, space = true}))
	childs.attr2:visible(unit.natureType2 ~= nil)
	if unit.natureType2 then
		childs.attr2:texture(ui.ATTR_ICON[unit.natureType2])
	end
	childs.attr1:texture(ui.ATTR_ICON[unit.natureType])
	childs.starList:setScrollBarEnabled(false)
	local starTemp = ccui.ImageView:create("common/icon/icon_star.png"):scale(1)
	starTemp:hide()
	local size = starTemp:box()
	local starData = {}
	local starIdx = cardData.star - 6
	for i=1,6 do
		local icon = "common/icon/icon_star_d.png"
		if i <= cardData.star then
			icon = i <= starIdx and "common/icon/icon_star_z.png" or "common/icon/icon_star.png"
		end
		table.insert(starData,{icon = icon})
	end
	self.starData = idlertable.new(starData)
	local size = childs.cardImg:size()
	childs.cardImg:removeAllChildren()
	local cardSprite = widget.addAnimation(childs.cardImg, unit.unitRes, "standby_loop", 5)
		:xy(size.width / 2, size.height * 0.05)
		:scale(unit.scale)
	cardSprite:setSkin(unit.skin)


	self.cardLevel:text(cardData.level)
	adapt.oneLineCenterPos(cc.p(self.rarity:x(), self.cardLevel:y()), {self.cardLevelNote, self.cardLevel}, cc.p(5, 3))
	self.power:text(cardData.fighting_point)
	adapt.oneLineCenterPos(cc.p(self.cardImg:x(), self.power:y()), {self.powerNote1, self.power}, cc.p(25, 0))
	self.tabDatas = {
		{name = gLanguageCsv.spaceAttribute, isSelected = true, panel = self.attributePanel},
		-- {name = gLanguageCsv.spaceSpeciality, isSelected = false},
		{name = gLanguageCsv.spaceSkill, isSelected = false, panel = self.skillPanel},
	}
	self.tabDatas = idlers.newWithMap(self.tabDatas)
	self.showPage = idler.new(1)
	self.showPage:addListener(function(val, oldval, idler)
		self.tabDatas:atproxy(oldval).isSelected = false
		self.tabDatas:atproxy(val).isSelected = true
		if self.tabDatas:atproxy(oldval).panel then
			self.tabDatas:atproxy(oldval).panel:hide()
		end
		if self.tabDatas:atproxy(val).panel then
			self.tabDatas:atproxy(val).panel:show()
		end
	end)
	self.skillDatas = {}
	local skillList = dataEasy.getCardSkillList(cardData.card_id, cardData.skin_id)
	for _,skillId in csvPairs(skillList) do
		table.insert(self.skillDatas, {id = skillId, level = cardData.skills[skillId] or 1})
	end
	table.sort(self.skillDatas, function (a, b)
		return a.id <= b.id
	end)
	self.attrDatas = {}
	for i,v in ipairs(game.ATTRDEF_SIMPLE_TABLE) do
		assertInWindows(cardData.attrs[v], "cardId(%s) attrs(%s) %s is nil", self.cardData.card_id, dumps(cardData.attrs), v)
		local data = {
			name = getLanguageAttr(v),
			num = math.floor(cardData.attrs[v] or 0),
			icon = ui.ATTR_LOGO[v],
		}
		self.attrDatas[i] =  data
	end
	self.nvalue = cardData.nvalue

	-- 特效
	local pnode = self.leftPanel
	widget.addAnimationByKey(pnode, "effect/jinhuajiemian.skel", 'spineDown', "effect_down2_loop", 3)
		:anchorPoint(cc.p(0.5,0.5))
		:xy(470, 240)
	widget.addAnimationByKey(pnode, "effect/jinhuajiemian.skel", 'spineUp', "effect_up_loop", 5)
		:anchorPoint(cc.p(0.5,0.5))
		:xy(470, 240)

	Dialog.onCreate(self)
end

function CardInfoView:initModel()
	self.level = gGameModel.role:getIdler("level")
	self.levelExp = gGameModel.role:getIdler("level_exp")
	self.cards = gGameModel.role:getIdler("cards")
	self.battleCards = gGameModel.role:getIdler("battle_cards")
	self.personalSign = gGameModel.role:getIdler("personal_sign")
	self.logo = gGameModel.role:getIdler("logo")
	self.myName = gGameModel.role:getIdler("name")
end

function CardInfoView:onChangePage(list, k)
	self.showPage:set(k)
end

function CardInfoView:onSkillDetail(list, k, v)
	local view = gGameUI:stackUI("common.skill_detail", nil, {clickClose = true, dispatchNodes = list}, {
		skillId = v.id,
		skillLevel = v.level,
		cardId = self.cardData.card_id,
		star = self.cardData.star,
		isZawake = dataEasy.isZawakeSkill(v.id, self.cardData.zawake_skills)
	})
	local panel = view:getResourceNode()
	local x, y = panel:xy()
	panel:xy(x - 60, y)
end

return CardInfoView
