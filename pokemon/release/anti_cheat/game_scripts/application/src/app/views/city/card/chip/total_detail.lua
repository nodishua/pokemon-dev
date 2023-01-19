local ChipTools = require('app.views.city.card.chip.tools')

local RES_POS = {
	90,615,1130,1640
}

local function initTitlePanel(list, node, v, x)
	local listW = list:size().width
	local cell = list.item01:clone()
			:anchorPoint(cc.p(0, 0.5))
			:xy(x, 36)
			:addTo(node)
			:show()
	local childs = cell:multiget("txtTitle", "img01", "img02")
	childs.txtTitle:text(v.title)
	adapt.oneLineCenterPos(cc.p(800,50), {childs.img02,childs.txtTitle,childs.img01}, cc.p(10,0))
end

local function initAttrPanel(list, node, v)
	node:size(cc.size(listW, 73))
	local cell = list.item02:clone()
			:anchorPoint(cc.p(0, 0.5))
			:xy(0, 36)
			:addTo(node)
			:show()
	for index =1, 3 do
		local item = cell:get("item0"..index)
		item:visible(false)
	end

	for index, data in pairs(v) do

		local item = cell:get("item0"..index)
		item:visible(true)

		local childs = item:multiget("imgAttr", "txtAttrName", "txtAttrCount")
		childs.txtAttrCount:text("+"..data.val)
		childs.txtAttrName:text(getLanguageAttr(data.attr))

		if ui.ATTR_LOGO[data.attr] and not string.match(data.val, '%%') then
			childs.imgAttr:texture(ui.ATTR_LOGO[data.attr])
			adapt.oneLinePos(childs.imgAttr, {childs.txtAttrName,childs.txtAttrCount}, {cc.p(5,0), cc.p(10,0)})

		else
			childs.imgAttr:visible(false)
			childs.txtAttrName:xy(childs.imgAttr:xy())
			text.addEffect(childs.txtAttrCount, {color = cc.c3b(145,225,177)})
			adapt.oneLinePos(childs.txtAttrName, childs.txtAttrCount,  cc.p(10,0))
		end
	end
end


local function initCompareAttrPanel(list, node, v)
	node:size(cc.size(listW, 73))
	local cell = list.item02:clone()
			:anchorPoint(cc.p(0, 0.5))
			:xy(0, 36)
			:addTo(node)
			:show()
	for index =1, 3 do
		local item = cell:get("item0"..index)
		item:visible(false)
		-- local x,y = item:xy()
		-- item:xy(x + 133*(index - 1), y)
	end

	for index, data in pairs(v) do

		local item = cell:get("item0"..index)
		item:visible(true)

		local childs = item:multiget("icon", "text", "val", "up1", "upVal", "upIcon", "up2")

		if type(data.val) == "table" then
			-- {左侧值, 右侧值, 对比数值(界面显示颜色等), 对比显示值}
			itertools.invoke({childs.up1, childs.upVal, childs.upIcon, childs.up2}, "show")
			childs.val:text(data.val[1])
			childs.upVal:text(data.val[4])
			if data.val[3] == 0 then
				childs.upIcon:hide()
				text.addEffect(childs.upVal, {color=cc.c4b(183, 176, 158, 255)})

			elseif data.val[3] > 0 then
				childs.upIcon:texture("common/icon/logo_arrow_green.png")
				text.addEffect(childs.upVal, {color=ui.COLORS.QUALITY_DARK[2]})
			else
				childs.upIcon:texture("common/icon/logo_arrow_red.png")
				text.addEffect(childs.upVal, {color=ui.COLORS.QUALITY_DARK[6]})
			end
			-- adapt.oneLinePos(childs.up1, {childs.upVal, childs.upIcon, childs.up2})
		-- else
		-- 	itertools.invoke({childs.up1, childs.upVal, childs.upIcon, childs.up2}, "hide")
		-- 	childs.val:text("+" .. v.val)
		end

		childs.text:text(getLanguageAttr(data.attr))
		if ui.ATTR_LOGO[data.attr] and not (string.match(data.val[1], '%%') or string.match(data.val[4], '%%')) then
			childs.icon:texture(ui.ATTR_LOGO[data.attr])
			adapt.oneLinePos(childs.icon, {childs.text, childs.val, childs.up1, childs.upVal, childs.upIcon, childs.up2},  cc.p(10,0))
		else
			childs.icon:visible(false)
			childs.text:xy(childs.icon:xy())
			adapt.oneLinePos(childs.text, {childs.val, childs.up1, childs.upVal, childs.upIcon, childs.up2},  cc.p(10,0))
		end
		-- childs.txtAttrCount:text("+"..data.val)
		-- childs.txtAttrName:text(getLanguageAttr(data.attr))

		-- if ui.ATTR_LOGO[data.attr] and not string.match(data.val, '%%') then
		-- 	childs.imgAttr:texture(ui.ATTR_LOGO[data.attr])
		-- 	adapt.oneLinePos(childs.imgAttr, {childs.txtAttrName,childs.txtAttrCount}, {cc.p(5,0), cc.p(10,0)})

		-- else
		-- 	childs.imgAttr:visible(false)
		-- 	childs.txtAttrName:xy(childs.imgAttr:xy())
		-- 	text.addEffect(childs.txtAttrCount, {color = cc.c3b(145,225,177)})
		-- 	adapt.oneLinePos(childs.txtAttrName, childs.txtAttrCount,  cc.p(10,0))
		-- end
	end
end

local function initResonancePanel(list, node, v, x)
	local listW = list:size().width

	node:size(cc.size(listW, 72))
	local resonanceCsv = csv.chip.resonance[v.id]
	local param = resonanceCsv.param
	local str = ""

	if resonanceCsv.type == 1 then
		str = string.format(gLanguageCsv.chipAttr01, param[1], ui.QUALITY_DARK_COLOR[param[2]], gLanguageCsv[ui.QUALITY_COLOR_TEXT[param[2]]])
	else
		str = string.format(gLanguageCsv.chipAttr07, param[1], param[2])
	end

	local richText = rich.createWithWidth(str, 40, nil, 1000, nil, cc.p(0, 0.5))
			:anchorPoint(cc.p(0, 0.5))
			:xy(RES_POS[1]+x, 36 )
			:addTo(node)

	local attrs = {}
	for index = 1, math.huge do
		local key = resonanceCsv["attrType"..index]
		if key and key ~= 0 then
			local str = dataEasy.getAttrValueString(key, resonanceCsv["attrNum"..index])
			local t = {}
			t.key = key
			t.val = str
			table.insert(attrs, t)
		else
			break
		end
	end

	local attrs = ChipTools.getBaseAttr(attrs)
	table.sort(attrs, function(v1, v2) return v1.key < v2.key end)
	for index, data in ipairs(attrs) do
		local name = ChipTools.getAttrName(data.key)
		str = string.format("#C0xFFFCED#%s #C0x91e1b1#+%s",name, data.val)

		local richText = rich.createWithWidth(str, 40, nil, 1000, nil, cc.p(0, 0.5))
				:anchorPoint(cc.p(0, 0.5))
				:xy(RES_POS[index+1]+x, 36)
				:addTo(node)
	end
end

local function initBlankPanel(list, node, sign)
	local listW = list:size().width
	node:size(cc.size(listW, 300))

	local str = sign == 1 and gLanguageCsv.chipHaveNot or gLanguageCsv.chipHaveNotResonance
	local txtTip = node:get("txtTip")
	txtTip:text(str)
	txtTip:visible(true)
	txtTip:xy(listW/2, 150)
end

local ViewBase = cc.load("mvc").ViewBase
local ChipTotalAttrView = class("ChipTotalAttrView", ViewBase)


ChipTotalAttrView.RESOURCE_FILENAME = "chip_base_attr.json"
ChipTotalAttrView.RESOURCE_BINDING = {
	["item"] = "item",
	["item01"] = "item01",
	["item02"] = "item02",
	["item03"] = "item03",
	["item04"] = "item04",
	["list"] = {
		varname = "list",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("showDatas"),
                item = bindHelper.self("item"),
                item01 = bindHelper.self("item01"),
                item02 = bindHelper.self("item02"),
                item03 = bindHelper.self("item03"),
				itemAction = {isAction = true},
                onItem = function(list, node, k, v)
                	if v.sign == 1 then
                		initTitlePanel(list,node, v, 0)

                	elseif v.sign == 2 then
                		if v.id == 0 then
                			initBlankPanel(list, node, 2)
                		else
                			initResonancePanel(list, node, v, 0)
                		end

                	else
                		if #v == 0 then
                			initBlankPanel(list, node, 1)
                		else
                			initAttrPanel(list,node, v)
                		end
                	end
				end,
				onAfterBuild = function(list)
					local containerSize = list:getInnerContainerSize()
					local size = list:getContentSize()

					if containerSize.height <= size.height then
						list:setTouchEnabled(false)
					end
				end,
			}
		}
	},
	["compareList"] = {
		varname = "compareList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("showCompareDatas"),
                item = bindHelper.self("item03"),
                item01 = bindHelper.self("item01"),
                item02 = bindHelper.self("item04"),
                -- item03 = bindHelper.self("item03"),
				itemAction = {isAction = true},
                onItem = function(list, node, k, v)
                	if v.sign == 1 then
                		initTitlePanel(list,node, v, 200)

                	elseif v.sign == 2 then
                		if v.id == 0 then
                			initBlankPanel(list, node, 2)
                		else
                			initResonancePanel(list, node,v, 200)
                		end

                	else
                		if #v == 0 then
                			initBlankPanel(list, node, 1)
                		else
                			initCompareAttrPanel(list,node, v)
                		end
                	end
				end,
				onAfterBuild = function(list)
					local containerSize = list:getInnerContainerSize()
					local size = list:getContentSize()

					if containerSize.height <= size.height then
						list:setTouchEnabled(false)
					end
				end,
			}
		}
	},
	["btnResonance"] = {
		binds = {
			event = 'touch',
			methods = {ended = bindHelper.self('onBtnResonance')}
		}
	},
}

ChipTotalAttrView.RESOURCE_STYLES = {
    blackLayer = true,
    clickClose = true,
    backGlass = true,
}

function ChipTotalAttrView:onCreate(param)
	self.typ = param.typ
	-- self.cardDBID = param.cardDBID
	self.curPlan = param.curPlan
	self.cardPlan = param.cardPlan

	self.showDatas = idlertable.new({})
	self.showCompareDatas = idlertable.new({})

	self.typeData = {
		[1] = {
			idler = self.showDatas,
			getAttrs = function()
				local firstAttrs, secondAttrs = ChipTools.getAttrs(self.cardPlan)
				ChipTools.setAttrCollect(firstAttrs, secondAttrs)
				return firstAttrs
			end,
			getResonanceAttr = function()
				local list = ChipTools.getResonanceAttr(self.cardPlan)
				return list
			end
		},
		[2] = {
			idler = self.showCompareDatas,
			getAttrs = function()
				local ret = ChipTools.getAttrsValueCmp(self.curPlan, self.cardPlan)
				return ret
			end,
			getResonanceAttr = function()
				local list = ChipTools.getResonanceAttr(self.curPlan)
				return list
			end
		}
	}

		self.list:visible(self.typ == 1)
		self.compareList:visible(self.typ == 2)
		self:getTotalAttrs()
end


function ChipTotalAttrView:arrangeData(desList, priList)
	local tempData = {}
	for index, data in pairs(priList) do
		if index%3 == 1 and index > 1 then
			table.insert(desList, tempData)
			tempData = {}
		end
		table.insert(tempData, data)
	end

	if #tempData > 0 then
		table.insert(desList, tempData)
		tempData = {}
	end
end

function ChipTotalAttrView:getTotalAttrs()
	local tempShowDatas = {}
	table.insert(tempShowDatas, {sign = 1, title = gLanguageCsv.basicAttribute})



	local attrs = {}
	local firstAttrs = self.typeData[self.typ].getAttrs()

	for index = 1, math.huge do
		if not firstAttrs[index] then
			break

		elseif table.nums(firstAttrs[index]) > 0 then

			if attrs[index] == nil then
				attrs[index] = {}
			end

			for _, attr in ipairs(game.ATTRDEF_TABLE) do
				local key = game.ATTRDEF_ENUM_TABLE[attr]
				if firstAttrs[index][key] then
					table.insert(attrs[index], {attr = attr, key = key, val = firstAttrs[index][key]})
				end
			end
		end
	end

	if table.nums(attrs) == 0 then
		table.insert(tempShowDatas, {})
	else
		for _, list in pairs(attrs) do
			self:arrangeData(tempShowDatas, list)
		end
	end

	table.insert(tempShowDatas, {sign = 1, title =gLanguageCsv.chipResonance})

	local list = self.typeData[self.typ].getResonanceAttr()


	if #list == 0 then
		table.insert(tempShowDatas, {sign = 2, id = 0})
	else
		table.sort(list, function(v1, v2) return v1[2] < v2[2] end)
		for index, val in ipairs(list) do
			table.insert(tempShowDatas, {sign = 2, id = val[1]})
		end
	end

	self.typeData[self.typ].idler:set(tempShowDatas)
end

function ChipTotalAttrView:onBtnResonance()
	gGameUI:stackUI('city.card.chip.resonance_preview')
end

return ChipTotalAttrView