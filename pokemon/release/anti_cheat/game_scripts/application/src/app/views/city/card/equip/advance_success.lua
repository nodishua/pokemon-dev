local BASE_TIME = 0.08
-- @desc: 卡牌羁绊
local ViewBase = cc.load("mvc").ViewBase
local CardEquipAdvanceSuccessView = class("CardEquipAdvanceSuccessView", ViewBase)
local COLOR = {
	"#C0x5B545B#",
	"#C0x5C9970#",
	"#C0x3D8A99#",
	"#C0x8A5C99#",
	"#C0xE69900#",
	"#C0xE67422#",
}
CardEquipAdvanceSuccessView.RESOURCE_FILENAME = "card_equip_advance_success.json"
CardEquipAdvanceSuccessView.RESOURCE_BINDING = {
	["bg"] = {
		binds = {
			event = "click",
			method = bindHelper.self("onClose"),
		},
	},
	["equip1"] = {
		varname = "equip1",
		binds = {
			event = "extend",
	        class = "equip_icon",
	        props = {
	            data = bindHelper.self("leftData"),
	            onNode = function(panel)
            		local childs = panel:multiget("star", "txtLv", "txtLvNum", "imgArrow")
            		itertools.invoke({childs.txtLv, childs.txtLvNum, childs.imgArrow}, "hide")
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
            		itertools.invoke({childs.txtLv, childs.txtLvNum, childs.imgArrow}, "hide")
	            end,
	        }
	    }
	},
	["txt1"] = "txt1",
	["pos"] = "pos",
	["centerPos"] = "centerPos",
	["cardImg"] = "cardImg",
	["name1"] = "name1",
	["name2"] = "name2",
}

function CardEquipAdvanceSuccessView:onCreate(data)
	--title特效
	uiEasy.setTitleEffect(self.centerPos, "xjiesuan_juexingzi")
	self.leftData = data
	local rightData = clone(data)
	rightData.awake = data.awake + 1
	self.rightData = rightData
	local cfg = csv.equips[data.equip_id]
	local str1 = gLanguageCsv.equipAwakeDetail
	local attrTypeStr = game.ATTRDEF_TABLE[cfg.awakeAttrType1]
	local str = "attr" .. string.caption(attrTypeStr)
	local oldAwake = data.awake or 0
	local oldBaseName = oldAwake == 0 and cfg.name0 or cfg.name1..gLanguageCsv["symbolRome"..oldAwake]
	local awake = oldAwake + 1
	local baseName = cfg.name1..gLanguageCsv["symbolRome"..awake]
	local quality, numStr = dataEasy.getQuality(data.advance)
	self.name1:text(oldBaseName)
	self.name2:text(baseName)
	text.addEffect(self.name1, {color = ui.COLORS.QUALITY[quality]})
	text.addEffect(self.name2, {color = ui.COLORS.QUALITY[quality]})
	local new = string.format(str1, COLOR[quality], baseName, gLanguageCsv[str], cfg.awakeAttrNum1[awake>= cfg.awakeMax and cfg.awakeMax or awake + 1] )
	rich.createWithWidth(new, 40, nil, 1000)
		:anchorPoint(cc.p(0, 0.5))
		:addTo(self.pos)
		:xy(0, 0)
	uiEasy.setExecuteSequence(self.name1)
	uiEasy.setExecuteSequence(self.equip1)
	uiEasy.setExecuteSequence(self.cardImg, {delayTime = BASE_TIME})
	uiEasy.setExecuteSequence(self.name2, {delayTime = BASE_TIME * 2})
	uiEasy.setExecuteSequence(self.equip2, {delayTime = BASE_TIME * 2})
	uiEasy.setExecuteSequence(self.pos, {delayTime = BASE_TIME * 3})
	uiEasy.setExecuteSequence(self.txt1, {delayTime = BASE_TIME * 4})
	-- gGameUI:disableTouchDispatch(1 + BASE_TIME * 4)
end

function CardEquipAdvanceSuccessView:setStar(panel, star)
	for i=1,star do
		ccui.ImageView:create("city/card/equip/icon_star.png")
			:xy(99 - 15 * (star + 1 - 2 * i), 20)
			:addTo(panel, 4, "star")
			:scale(1)
	end
end

function CardEquipAdvanceSuccessView:onClose()
	self:addCallbackOnExit(self.cb)
	ViewBase.onClose(self)
end

return CardEquipAdvanceSuccessView