
--
-- 查看选中角色的属性面板, 显示在屏幕中央, 只能在非自动战斗状态下, 释放技能间隙点击精灵来查看
--

local BattleAttrPanelView = class("BattleAttrPanelView", cc.load("mvc").ViewBase)

BattleAttrPanelView.RESOURCE_FILENAME = "battle_attr_panel.json"
BattleAttrPanelView.RESOURCE_BINDING = {

}

local ATTR_Tb = {
	[1] = "hpMax",
	[2] = "damage",
	[3] = "defence",
	[4] = "specialDamage",
	[5] = "specialDefence",
	[6] = "speed",
}

-- 默认隐藏 -- todo
function BattleAttrPanelView:onCreate(battleView)
	self.battleView = battleView
	-- 空白区域的点击
	local pnode = self:getResourceNode()
	pnode:onTouch(function()
		self:onCloseBtnClick()
	end)
	self:hide()

	local attrPanel = pnode:get("attrPanel")
	for i=1, 6 do
		local attrName = nodetools.get(attrPanel, "attr" .. i .. ".attrName")
		local str = ATTR_Tb[i]
		local str1 = string.upper(string.sub(str, 1, 1))
		local str2 = string.sub(str, 2)
		str = "attr" .. str1 .. str2
		if i==1 then
			str = "attrHp"
		end
		attrName:text(gLanguageCsv[str])
	end
end

-- 显示界面, 给外部用的
function BattleAttrPanelView:showPanel(objSpr)
	if not objSpr then return end
	self:show()

	self.curObjSpr = objSpr
	local res = objSpr.unitCfg.cardIcon
	local name = objSpr.unitCfg.name
	local sprModel = objSpr.model
	local level = sprModel.isMonster and sprModel.showLevel or sprModel.level
	local attr1res = ui.ATTR_ICON[objSpr.unitCfg.natureType]
	local attr2res = ui.ATTR_ICON[objSpr.unitCfg.natureType2]
	local pnode = self:getResourceNode()
	-- 头像
	bind.extend(self, pnode:get("potraitFrame"), {
		class = "card_icon",
		props = {
			unitId = sprModel.unitID,
			advance = sprModel.advance,
			star = sprModel.star,
			rarity = sprModel.rarity,
			isBoss = sprModel.isBoss
		}
	})
	local w = pnode:get("potraitFrame"):size().width
	pnode:get("potraitFrame").panel:anchorPoint(cc.p(0.5, 0.5)):xy(w/2, w/2)

	-- 名字
	pnode:get("nameText"):text(name)
	pnode:get("level"):text(level)
	-- 属性类型
	local attrIcon1 = pnode:get("attrIcon1")
	local attrIcon2 = pnode:get("attrIcon2")
	attrIcon1:texture(attr1res)
	if attr2res then
		attrIcon2:show()
			:texture(attr2res)
	else
		attrIcon2:hide()
	end

	self:showAttrs()
end

function BattleAttrPanelView:showAttrs()
	local pnode = self:getResourceNode()
	local attrPanel = pnode:get("attrPanel")
	-- 属性
	local objModel = self.curObjSpr.model
	local arrowResTb = {"common/icon/logo_arrow_green.png", "common/icon/logo_arrow_red.png"}
	for i=1, 6 do
		local attr = ATTR_Tb[i]
		local nowval = objModel[attr](objModel)
		local baseval = objModel.attrs.base[attr]
		local rate = math.floor(nowval/baseval*100)/100
		local panel = attrPanel:get("attr" .. i)

		panel:get("rate"):text("x" .. rate)
		if math.abs(rate - 1) < 1e-5 then
			panel:get("arrow"):hide()
		else
			panel:get("arrow"):show()
				:texture(rate > 1 and arrowResTb[1] or arrowResTb[2])
		end
	end
	-- 道具
	local itemInfoTb = {}
	for i=1, 2 do
		local p = pnode:get("item" .. i)
		if not itemInfoTb[i] then
			p:get("item.icon"):hide()
			p:get("item.count"):hide()
			p:get("name"):hide()
		end
	end
	-- 特性
	local speInfoTb = {}
	for i=1, 4 do
		local p = pnode:get("spePanel" .. i)
		if not speInfoTb[i] then
			p:get("iconItem.icon"):hide()
			p:get("name"):hide()
		end
	end
end


function BattleAttrPanelView:onCloseBtnClick()
	self:hide()
end

return BattleAttrPanelView

-- 点击后出现, 点击技能时 隐藏
-- 点击周围区域也隐藏
