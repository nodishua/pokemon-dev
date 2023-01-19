local BASE_TIME = 0.08
local HeldItemTools = require "app.views.city.card.helditem.tools"
local function getAttrNum(cfg, level, advance, i)
	-- 属性显示
	local attrNumRates = cfg.attrNumRates
	local advanceAttrTab = csv.held_item.advance_attrs[advance]
	local advAttrNum = advanceAttrTab["attrNum" .. cfg.advanceAttrSeq]
	local advAttrRate = advanceAttrTab["attrRate" .. cfg.advanceAttrSeq]
	local lvAttrNum = csv.held_item.level_attrs[level]["attrNum" .. cfg.strengthAttrSeq]
	return attrNumRates[i] * advAttrRate[i] * (lvAttrNum[i] + advAttrNum[i])
end
local function setItemIcon(list, node, v)
	bind.extend(list, node, {
		class = "icon_key",
		props = {
			data = {
				key = v.csvId,
				csvId = v.csvId,
				dbId = v.dbId,
			},
			specialKey = {
				lv = v.lv,
			},
			onNode = function(panel)
				panel:setTouchEnabled(false)
			end
		}
	})
end
local function createAttrRichText(parent, csvId, advance)
	parent:show()
	local cfg = csv.held_item.items[csvId]
	local data = {}
	data.cfg = cfg
	cfg.advance = advance
	cfg.csvId = csvId
	local resultStr = HeldItemTools.getStrinigByData(2, data)
	local targetStr = table.concat({resultStr}, '\n')

	local richText = rich.createByStr("#C0x5B545B#" .. targetStr, 40, nil)
		:anchorPoint(0, 0.5)
		:xy(220, 23)
		:addTo(parent, 10, "attrText")
	richText:formatText()
	adapt.oneLinePos(richText, parent:get("arrow"), cc.p(8, 2), "left")
end
local HeldItemCommonSuccessView = class("HeldItemCommonSuccessView", cc.load("mvc").ViewBase)

HeldItemCommonSuccessView.RESOURCE_FILENAME = "held_item_common_success.json"
HeldItemCommonSuccessView.RESOURCE_BINDING = {
	["bg"] = {
		binds = {
			event = "click",
			method = bindHelper.self("onClose")
		},
	},
	["centerPanel"] = "centerPanel",
	["item"] = "item",
	["centerPanel.subList"] = "subList",
	["centerPanel.list"] = {
		varname = "list",
		binds = {
			event = "extend",
			class = "tableview",
			props = {
				data = bindHelper.self("attrDatas"),
				columnSize = 2,
				item = bindHelper.self("subList"),
				cell = bindHelper.self("item"),
				onCell = function(list, node, k, v)
					local childs = node:multiget("note", "txt1", "txt2", "icon", "iconArrow")
					childs.note:setString(v.note)
					childs.txt1:setString(math.floor(v.txt1))
					childs.txt2:setString(math.floor(v.txt2))
					childs.icon:loadTexture(v.icon)

					local idx = list:getIdx(k).k
					local baseDelay = BASE_TIME * (3 + idx)
					uiEasy.setExecuteSequence({childs.icon, childs.note}, {delayTime = baseDelay})
					uiEasy.setExecuteSequence(childs.txt1, {delayTime = baseDelay + BASE_TIME})
					uiEasy.setExecuteSequence(childs.iconArrow, {delayTime = baseDelay + BASE_TIME * 2})
					uiEasy.setExecuteSequence(childs.txt2, {delayTime = baseDelay + BASE_TIME * 3})
				end,
				asyncPreload = 6,
			},
		},
	},
	["titlePos"] = "titlePos",
	["centerPos"] = "centerPos",
	["descNote"] = "descNote",
}
function HeldItemCommonSuccessView:onCreate(params)
	self.dbId = params.dbId
	self:initModel()
	local cfg = csv.held_item.items[self.heldItemId]
	self.attrDatas = idlers.new()
	local attrDatas = {}
	for i,v in ipairs(cfg.attrTypes) do
		local data = {}
		local attr = game.ATTRDEF_TABLE[v]
		local note = gLanguageCsv["attr" .. string.caption(attr)]
		data.note = note
		data.txt1 = getAttrNum(cfg, params.level, params.advance, i)
		data.txt2 = getAttrNum(cfg, self.newLevel, self.newAdvance, i)
		data.icon = ui.ATTR_LOGO[attr]
		table.insert(attrDatas, data)
	end
	self.attrDatas:update(attrDatas)
	self:setCenterPanel(cfg, params.level, params.advance, 1, params.typ)
	self:setCenterPanel(cfg, self.newLevel, self.newAdvance, 2, params.typ)
	local effectName = "xjiesuan_qianghuazi"
	if params.typ == "advance" then
		effectName = "xjiesuan_tupozi"
	end
	--title特效
	uiEasy.setTitleEffect(self.centerPos, effectName)
	--突破
	self.descNote:hide()
	if cfg.effect2LevelAdvSeq[1] == self.newAdvance and params.typ == "advance" then
		self.descNote:show()
		createAttrRichText(self.descNote, self.heldItemId, self.newAdvance)
		self.centerPanel:y(self.centerPos:y() + 40)

		uiEasy.setExecuteSequence(self.descNote, {delayTime = BASE_TIME * 5})
	end
	--战力
	self:setFight(params.fight, params.cardDbId)

	-- gGameUI:disableTouchDispatch(1 + BASE_TIME * 12)
end

function HeldItemCommonSuccessView:initModel()
	local item = gGameModel.held_items:find(self.dbId)
	local itemData = item:read("held_item_id", "advance", "level", "card_db_id")
	self.heldItemId = itemData.held_item_id
	self.newLevel = itemData.level
	self.newAdvance = itemData.advance
	self.cardDbId = itemData.card_db_id
end

function HeldItemCommonSuccessView:setCenterPanel(cfg, level, advance, oldOrNew, typ)
	local childs = self.centerPanel:multiget(
		"card1",
		"card2",
		"name1",
		"name2",
		"level1",
		"level2",
		"cardImg"
	)
	local cardNode = childs["card"..oldOrNew]
	local nameNode = childs["name"..oldOrNew]
	local levelNode = childs["level"..oldOrNew]
	--等级和名字
	local levelStr = "Lv".. level
	if typ == "advance" then
		levelStr = advance > 0 and "+".. advance or ""
	end
	levelNode:text(levelStr)
	nameNode:text(cfg.name)
	text.addEffect(nameNode, {color = ui.COLORS.QUALITY[cfg.quality]})
	text.addEffect(levelNode, {color = ui.COLORS.QUALITY[cfg.quality]})
	adapt.oneLineCenterPos(cc.p(cardNode:x(), nameNode:y()), {nameNode, levelNode}, cc.p(8, 0))
	--icon
	setItemIcon(self, cardNode, {
		csvId = self.heldItemId,
		isExc = csvSize(cfg.exclusiveCards) > 0,
		lv = level,
		dbId = self.dbId,
	})
	--动画
	local baseDelay = BASE_TIME * (oldOrNew == 1 and 0.1 or 2)
	uiEasy.setExecuteSequence(cardNode, {delayTime = baseDelay})
	uiEasy.setExecuteSequence(nameNode, {delayTime = baseDelay})
	uiEasy.setExecuteSequence(levelNode, {delayTime = baseDelay})
	if oldOrNew == 2 then
		uiEasy.setExecuteSequence({childs.cardImg}, {delayTime = BASE_TIME})
	end
end
function HeldItemCommonSuccessView:setFight(oldFight, cardDbId)
	local childs = self.centerPanel:multiget(
		"fight1",
		"fight2",
		"fightBg"
	)
	if cardDbId == nil then
		itertools.invoke({childs.fight1, childs.fight2, childs.fightBg}, "hide")
	else
		local newFight = gGameModel.cards:find(cardDbId):read("fighting_point")
		childs.fight1:text(oldFight)
		childs.fight2:text(newFight)

		uiEasy.setExecuteSequence(childs.fightBg, {delayTime = BASE_TIME * 3})
		uiEasy.setExecuteSequence(childs.fight1, {delayTime = BASE_TIME * 4})
		uiEasy.setExecuteSequence(childs.fight2, {delayTime = BASE_TIME * 5})
	end
end

return HeldItemCommonSuccessView
