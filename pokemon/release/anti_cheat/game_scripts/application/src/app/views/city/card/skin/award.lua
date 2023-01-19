local NATIVE_BUFF_OBJ = {
	gLanguageCsv.skinBuff1,
	gLanguageCsv.skinBuff2,
}

local SkinAwardView = class("SkinAwardView", Dialog)

SkinAwardView.RESOURCE_FILENAME = "card_skin_reward.json"
SkinAwardView.RESOURCE_BINDING = {
	["textName"] = "txtName",

	["item"] = "item",
	["itemAttr"] = "itemAttr",
	["heroNode"] = "heroNode",
	["imgLimitBg"] = "imgLimitBg",
	["labelInfo"] = "labelInfo",
	["panelNature"] = "panelNature",
	["panelNature.txtBuffObj"] = "txtBuffObj",
	["panelNature.infoList"] = {
		varname = "attrList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("skinNativeDatas"),
				item = bindHelper.self("itemAttr"),
				itemCell = bindHelper.self("item"),
				onItem = function(list, node, k, v)
					local binds = {
						class = "listview",
						props = {
							data = v,
							item = list.itemCell,
							onItem = function(innerList, cell, kk ,vv)
								local childs = cell:multiget("title","num")
								childs.title:text(getLanguageAttr(vv.attrType))
								childs.num:text("+"..dataEasy.getAttrValueString(vv.attrType, vv.attrValue))
								adapt.oneLinePos(childs.title, childs.num, cc.p(5, 0), "left")
								local oldWidth = cell:width()
								local titWidth = childs.title:width()
								local numWidth = childs.num:width()
								local newWidth = titWidth+numWidth+5
								if newWidth > oldWidth then
									cell:width(newWidth)
								end
							end
						}
					}
					bind.extend(list, node, binds)
				end
			}
		}
	},
}

function SkinAwardView:onCreate(skinid, time)
	self.skinID            = skinid
	self.time              = time or 0
	self.skinNativeDatas   = idlers.new({})

	self.skins = gGameModel.role:getIdler("skins")
	self:setSkinInfo()


	-- 恭喜获得特效
	local pnode = self:getResourceNode()
	widget.addAnimationByKey(pnode, "effect/pifuhuoqu.skel", 'pifuhuoqu', "effect", 1)
		:anchorPoint(cc.p(0.5,0.5))
		:scale(2)
		:xy(pnode:width()/2, pnode:height()/2 - 40)
		:addPlay("effect_loop")

	Dialog.onCreate(self)
end


-- 设置皮肤属性
function SkinAwardView:setSkinInfo()

	local skinCsv = gSkinCsv[self.skinID]
	--创建列表
	local attrDatas = {}
	local index = 0

	index = skinCsv["attrAddType"]
	self.txtBuffObj:text(NATIVE_BUFF_OBJ[index])

	local temp = {}
	for i=1,6 do
		if i%3 == 1 then
			if i > 3 then
				attrDatas[#attrDatas + 1] = temp
			end
			temp = {}
		end

		local attrType = skinCsv["attrType"..i]
		if attrType and attrType ~= 0 then
			table.insert(temp, {attrType = attrType, attrValue = skinCsv["attrNum"..i]})
		end
	end
	if #temp > 0 then
		attrDatas[#attrDatas + 1] = temp
	end
	self.skinNativeDatas:update(attrDatas)

	-- 名称设置
	self.txtName:text(skinCsv.name)

	-- 皮肤展示
	local unitId = dataEasy.getUnitId(nil, self.skinID)
	local unit = csv.unit[unitId]
	local size = self.heroNode:getContentSize()
	self.cardSprite = widget.addAnimation(self.heroNode, unit.unitRes, "standby_loop", 5)
		:xy(size.width/2, 0)
	self.cardSprite:scale(unit.scaleU*3)
	self.cardSprite:setSkin(unit.skin)

	local sign = self.time ~= 0

	self.imgLimitBg:visible(sign)
	self.labelInfo:visible(sign)
	self.labelInfo:text(string.format(gLanguageCsv.skinTip04,self.time))

	if sign then
		local skins = self.skins:read()
		if skins[self.skinID] == 0 then
			gGameUI:showTip(gLanguageCsv.skinTip08)
		end
	end

end

function SkinAwardView:onClose()
	self:addCallbackOnExit(self.cb)
	Dialog.onClose(self)
end


return SkinAwardView