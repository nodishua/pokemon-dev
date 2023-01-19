local BASE_TIME = 0.08


local function setName(data, textNode)
	local cfg = csv.equips[data.equip_id]
	local baseName
	if data.awake ~= 0  then
		baseName = cfg.name1..gLanguageCsv["symbolRome"..data.awake]
	else
		baseName = cfg.name0
	end
	local currQuality, currNumStr = dataEasy.getQuality(data.advance)
	textNode:text(baseName..currNumStr)
	text.addEffect(textNode,{color = currQuality == 1 and ui.COLORS.NORMAL.DEFAULT or ui.COLORS.QUALITY[currQuality]})
end
-- @desc: 卡牌羁绊
local ViewBase = cc.load("mvc").ViewBase
local CardEquipSuccessView = class("CardEquipSuccessView", ViewBase)
local CardEquipView = require "app.views.city.card.equip.view"
CardEquipSuccessView.RESOURCE_FILENAME = "card_equip_success.json"
CardEquipSuccessView.RESOURCE_BINDING = {
	["textBD"] = "textBD",
	["item1"] = "item1",
	["item2"] = "item2",
	["item3"] = "item3",
	["equip1"] = {
		varname = "equip1",
		binds = {
			event = "extend",
	        class = "equip_icon",
	        props = {
	            data = bindHelper.self("leftData"),
	            onNode = function(panel)
            		local childs = panel:multiget("star", "txtLv", "txtLvNum", "imgArrow")
            		itertools.invoke({childs.star, childs.txtLv, childs.txtLvNum, childs.imgArrow}, "hide")
	            end,
	        }
        }
	},
	["equip2"] = {
		varname = "equip2",
		binds = {
			event = "extend",
	        class = "equip_icon",
	        props = {
	            data = bindHelper.self("rightData"),
	            onNode = function(panel)
	        		local childs = panel:multiget("star", "txtLv", "txtLvNum", "imgArrow")
            		itertools.invoke({childs.star, childs.txtLv, childs.txtLvNum, childs.imgArrow}, "hide")
	            end,
	        }
	    }
	},
	["starPanel.leftPos"] = "leftPos",
	["starPanel.rightPos"] = "rightPos",
	["potentialPanel.leftPos"] = "leftPotentialPos",
	["potentialPanel.rightPos"] = "rightPotentialPos",
	["potentialPanel"] = "potentialPanel",
	["potentialPanel.leftPos.textNote"] = {
		varname = "leftPotentialText",
		binds = {
			event = "effect",
			data = {outline = {color = cc.c3b(179,68,48),size = 2}}
		},
	},
	["potentialPanel.rightPos.textNote"] = {
		varname = "righttPotentialText",
		binds = {
			event = "effect",
			data = {outline = {color = cc.c3b(179,68,48),size = 2}}
		},
	},
	["starPanel"] = "starPanel",
	["bg"] = {
		binds = {
			event = "click",
			method = bindHelper.self("onClose")
		},
	},
	["centerPos"] = "centerPos",
	["fight1"] = "fight1",
	["fight2"] = "fight2",
	["fightBg"] = "fightBg",
	["icon"] = "icon",
	["limitTip"] = "limitTip",
}
-- leftItem, rightItem, type
function CardEquipSuccessView:onCreate(params)
	audio.playEffectWithWeekBGM("advance_suc.mp3")
	self.leftData = params.leftItem
	self.rightData = params.rightItem
	self.cb = params.cb
	local t = {}
	local effectName = "xjiesuan_tupozi"
	if params.type == "star" then
		effectName = "xjiesuan_shengxingzi"
		self:setStar(self.leftPos, self.leftData.star)
		self:setStar(self.rightPos, self.rightData.star)
		uiEasy.setExecuteSequence(self.leftPos)
		uiEasy.setExecuteSequence(self.rightPos, {delayTime = BASE_TIME * 2})
	end
	if params.type == "ability" then
		self.leftPotentialText:text(self.leftData.ability)
		self.righttPotentialText:text(self.rightData.ability)
		uiEasy.setExecuteSequence(self.leftPotentialPos)
		uiEasy.setExecuteSequence(self.rightPotentialPos, {delayTime = BASE_TIME * 2})
		effectName = "xjiesuan_shengxingzi"
	end

	if params.type == "awake" then
		effectName = "xjiesuan_juexingzi"
	end
	-- 道具名称
	local childs = self.item3:multiget("name1", "name2")
	setName(self.leftData, childs.name1)
	setName(self.rightData, childs.name2)
	if params.type == "signet" then
		effectName = "xjiesuan_keyinzi"
		childs.name1:text(params.leftQuality)
		childs.name2:text(params.rightQuality)
	end
	self.textBD:visible(false)
	if params.type == "signetAdvance" then
		self.rightData = params.leftItem
		childs.name1:text(params.leftQuality)
		childs.name2:text(params.rightQuality)
		if params.isMax then
			childs.name2:text(params.leftQuality)
		end
		if params.limitTip ~= 0 then
			self.textBD:text(params.textBD)
			self.limitTip:text("("..params.limitTip..")"):visible(true)
			text.addEffect(self.textBD, {color = cc.c4b(183, 176, 158, 255)})
		else
			self.textBD:text(params.textBD)
			self.limitTip:visible(false)
			text.addEffect(self.textBD, {color = cc.c4b(96, 196, 86, 255)})
		end
		self.textBD:visible(true)
	end
	uiEasy.setExecuteSequence(childs.name1)
	uiEasy.setExecuteSequence(childs.name2, {delayTime = BASE_TIME * 2})

	uiEasy.setExecuteSequence(self.equip1)
	uiEasy.setExecuteSequence(self.equip2, {delayTime = BASE_TIME * 2})
	uiEasy.setExecuteSequence(self.icon, {delayTime = BASE_TIME})

	--title特效
	uiEasy.setTitleEffect(self.centerPos, effectName)
	--战力
	local card = gGameModel.cards:find(params.cardDbid)
	self.fight1:text(params.fight)
	self.fight2:text(card:read("fighting_point"))

	uiEasy.setExecuteSequence(self.fightBg, {delayTime = BASE_TIME * 3})
	uiEasy.setExecuteSequence(self.fight1, {delayTime = BASE_TIME * 4})
	uiEasy.setExecuteSequence(self.fight2, {delayTime = BASE_TIME * 5})

	self.starPanel:visible(params.type == "star")

	self.potentialPanel:visible(params.type == "ability")
	self.leftPotentialPos:visible(self.leftData.ability == 0)
	-- self.item3:visible(params.type ~= "star")
	for i=1,2 do
		local showtype = params.type == 'quick' and 'advance' or params.type
		local attr, currVal, nextVal = CardEquipView.getAttrNum(params.leftItem, i, showtype)--params.rightItem
		if params.type == 'quick' then
			local _
			_, nextVal = CardEquipView.getAttrNum(params.rightItem, i, params.type)
		elseif params.type == 'signetAdvance' and params.signetAdvanceData[i] then
			currVal = params.signetAdvanceData[i].num1
			nextVal = params.signetAdvanceData[i].num2
		end
		local childs = self["item"..i]:multiget("note", "name1", "name2", "icon", "arrow")
		if attr ~= 0 and nextVal ~= 0 then
			local attrTypeStr = game.ATTRDEF_TABLE[attr]
			local str = "attr" .. string.caption(attrTypeStr)
			childs.note:text(gLanguageCsv[str]..":")
			local name1 = currVal
			local name2 = nextVal
			if type(name1) == "number" then
				name1 = math.round(currVal)
			end
			if type(name2) == "number" then
				name2 = math.round(nextVal)
			end
			childs.name1:text("+"..name1)
			childs.name2:text("+"..name2)
			local baseDelay = BASE_TIME * (5 + i)
			if ui.ATTR_LOGO[attrTypeStr] then
				childs.icon:texture(ui.ATTR_LOGO[attrTypeStr])
				adapt.oneLinePos(childs.note, childs.icon, cc.p(30,0), "right")
				uiEasy.setExecuteSequence(childs.icon, {delayTime = baseDelay})
			else
				childs.icon:hide()
			end

			uiEasy.setExecuteSequence(childs.note, {delayTime = baseDelay})
			uiEasy.setExecuteSequence(childs.name1, {delayTime = baseDelay + BASE_TIME})
			uiEasy.setExecuteSequence(childs.arrow, {delayTime = baseDelay + BASE_TIME * 2})
			uiEasy.setExecuteSequence(childs.name2, {delayTime = baseDelay + BASE_TIME * 3})
		else
			itertools.invoke({childs.note, childs.name1, childs.name2, childs.icon, childs.arrow}, "hide")
		end
	end

	-- gGameUI:disableTouchDispatch(1 + BASE_TIME * 3)
end

function CardEquipSuccessView:setStar(panel, star)
	if star > 0 then
		for i=1,star do
			ccui.ImageView:create("city/card/equip/icon_star.png")
				:xy(99 - 15 * (star + 1 - 2 * i), 20)
				:addTo(panel, 4, "star")
				:scale(0.8)
		end
	-- else
		-- label.create(gLanguageCsv.none, {fontSize = 40, color = ui.COLORS.NORMAL.DEFAULT})
		-- 	:addTo(panel)
		-- 	:xy(panel:size().width/2, 20)
	end
end

function CardEquipSuccessView:onClose()
	self:addCallbackOnExit(self.cb)
	ViewBase.onClose(self)
end


return CardEquipSuccessView