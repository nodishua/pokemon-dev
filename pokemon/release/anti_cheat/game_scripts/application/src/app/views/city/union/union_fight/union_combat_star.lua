
--#战斗之星
--#主要用途给卡牌加buff-_-!
local ViewBase = cc.load("mvc").ViewBase
local UnionCombatStarView = class("UnionCombatStarView", Dialog)

local starConsume = 1 --战斗之星的每次消耗1
local spriteTabText = {}
for k,v in pairs(game.NATURE_ENUM_TABLE) do
	spriteTabText[v] = gLanguageCsv[k]
end

--判断职位
local function JudgmentJob(id, jobList)
	if jobList["chairman"] == id then
		return true
	end
	if jobList["viceChairmans"][id] then
		return true
	end
	return false
end

UnionCombatStarView.RESOURCE_FILENAME = "union_combat_star.json"
UnionCombatStarView.RESOURCE_BINDING = {
	["btnColse"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")}
		},
	},
	["txt"] = {
		varname = "txt",
		binds = {
			event = "effect",
			data = {outline={color=cc.c4b(59, 51, 59, 255)}},
		},
	},
	["txt2"] = {
		varname = "txt2",
		binds = {
			event = "effect",
			data = {outline={color=cc.c4b(59, 51, 59, 255)}},
		},
	},
	["btn"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("btnSave")}
		},
	},
	["sprite"] = {
		varname = "targetSprite",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("spriteBtnFunc")}
		},
	},
	["sprite.upDown"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("spriteBtnFunc")}
		},
	},
	["attr"] = {
		varname = "attr",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("attributeFunc")}
		},
	},
	["attr.upDown"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("attributeFunc")}
		},
	},
	["add.icon1"] = {
		varname = "add",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("addResult")}
		},
	},
	["add.icon2"] = {
		varname = "reduce",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("reduceResult")}
		},
	},
	["starTxt"] = "starTxt",
	["panel"] = "panel",
	["star"] = "star",
}

function UnionCombatStarView:onCreate()
	self:initModel()
	self.reduce:setOpacity(0)
	self.reduce:get("txt"):setOpacity(0)

	self.natureDatas = idler.new(0)
	--创建属性选择页签
	self.attrPanel = gGameUI:createView("common.attr_filter", self):init({
		isMultiSelect = false,
		selectDatas = self:createHandler("natureDatas"),
		panelState = self:createHandler("isShowNaturePanel"),
		btnColse = true,
	})
		:anchorPoint(0.5, 0)
		:xy(100, -100)
		:z(20)
		:scale(0.7)
	--查询选中的卡牌
	idlereasy.if_not(self.isShowNaturePanel, function()
		self.spriteIcon = self.natureDatas:read()
		self:updateFontChange()
	end)
	idlereasy.when(self.isShowNaturePanel, function(_, isShow)
		self.spriteInfo = isShow and 1 or 2
		self.targetSprite:get("upDown"):rotate(isShow and 180 or 0)
		self.attrPanel:visible(isShow)
	end)

	--影响属性（例如：特攻，速度...）
	self.attrbutePanel = gGameUI:createView("common.attribute_filter", self):init({
		selectDatas = self.oneSelfNature,
		panelState = self.isShowone,
	})
	idlereasy.if_not(self.isShowone, function()
		self.attrIcon = self.oneSelfNature:read()
		self:updateFontChange()
	end)
	idlereasy.when(self.isShowone, function(_, isShow)
		self.attrInfo = isShow and 1 or 2
		self.attr:get("upDown"):rotate(isShow and 180 or 0)
		self.attrbutePanel:visible(isShow)
	end)
	self.postX1 = self.txt:x()
	self.postX2 = self.txt2:x()
	Dialog.onCreate(self)
end

function UnionCombatStarView:initModel()
	local numStar = gGameModel.union_fight:read("union_info").battle_star_num
	numStar = numStar <= 0 and 0 or numStar
	self.starTxt:text(numStar..'/'..starConsume)			--战斗之星的数量
	self.star:x(self.starTxt:x() - self.starTxt:width())
	self.dataTab = idlers.new({})
	self.spriteInfo = 2									--目标精灵状态1打开2关闭
	self.attrInfo = 2									--目标属性状态1打开2关闭
	self.result = 1										--默认是增加效果的
	self.upDownText = gLanguageCsv.increase
	self.isShowNaturePanel = idler.new(false)			--打开或关闭精灵页签
	self.oneSelfNature = idler.new(0)					--选中的属性(特攻，速度等)
	self.isShowone = idler.new(false)
	self.roleId = gGameModel.role:read("id")
	local unionInfo = gGameModel.union
	self.chairmanId = unionInfo:read("chairman_db_id")  --会长ID 长度12
	self.viceChairmans = unionInfo:read("vice_chairmans")--副会长ID 长度12

end
--选择影响的精灵类型
function UnionCombatStarView:spriteBtnFunc()
	self.spriteInfo = self.spriteInfo == 1 and 2 or 1
	self.isShowNaturePanel:set(self.spriteInfo == 1)
end

--影响属性
function UnionCombatStarView:attributeFunc()
	self.attrInfo = self.attrInfo == 1 and 2 or 1
	self.isShowone:set(self.attrInfo == 1)
end

--增加效果
function UnionCombatStarView:addResult()
	self.add:setOpacity(255)
	self.add:get("txt"):setOpacity(255)
	self.reduce:setOpacity(0)
	self.reduce:get("txt"):setOpacity(0)
	self.result = 1
	self.upDownText = gLanguageCsv.increase
	self:updateFontChange()
end

--减少效果
function UnionCombatStarView:reduceResult()
	self.reduce:setOpacity(255)
	self.reduce:get("txt"):setOpacity(255)
	self.add:setOpacity(0)
	self.add:get("txt"):setOpacity(0)
	self.result = -1
	self.upDownText = gLanguageCsv.reduce
	self:updateFontChange()
end

--字体变动
function UnionCombatStarView:updateFontChange()
	if self.spriteIcon and self.spriteIcon>=1 and self.attrIcon and self.attrIcon>=1 then
		local text = gLanguageCsv.attrSprite
		local attrTypeStr = game.ATTRDEF_TABLE[self.attrIcon]
		local arrtTab = gLanguageCsv["attr"..string.caption(attrTypeStr)]
		self.txt:text(spriteTabText[self.spriteIcon]..text..self.upDownText.."10%"..arrtTab)
		self.txt:x(self.postX1 - self.txt:width()/2+self.txt2:width()/2)
		self.txt2:x(self.postX2 - self.txt:width()/2+self.txt2:width()/2)
	end
end

--保存
function UnionCombatStarView:btnSave()
	local numStar = gGameModel.union_fight:read("union_info").battle_star_num
	--是否有战斗之星
	if numStar <= 0 then
		gGameUI:showTip(gLanguageCsv.combatStarNot)
		return
	end
	--选择精灵
	if not self.spriteIcon or self.spriteIcon <= 0 then
		gGameUI:showTip(gLanguageCsv.addtionSprite)
		return
	end
	--选择属性
	if not self.attrIcon or self.attrIcon <=0 then
		gGameUI:showTip(gLanguageCsv.addtionAttr)
		return
	end
	--只有会长和副会长才能使用战斗之星
	local jobList = {}
	jobList["chairman"] = self.chairmanId
	local tmpViceChairmans = {}
	for k,v in ipairs(self.viceChairmans) do
		tmpViceChairmans[v] = true
	end
	jobList["viceChairmans"] = tmpViceChairmans
	if not JudgmentJob(self.roleId, jobList) then
		gGameUI:showTip(gLanguageCsv.unionOnlyChairman)
		return false
	end

	gGameApp:requestServer("/game/union/fight/battle/star/set",function(tb)
		numStar = numStar -1
		self.starTxt:text(numStar..'/'..starConsume)
		ViewBase.onClose(self)
	end,self.spriteIcon, self.attrIcon, self.result)

end

return UnionCombatStarView