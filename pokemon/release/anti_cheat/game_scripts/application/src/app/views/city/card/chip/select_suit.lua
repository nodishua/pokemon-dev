local CHIPUPLIMIT = gCommonConfigCsv.chipUpLimit

local ViewBase = cc.load('mvc').ViewBase
local ChipSelectSuitView = class("ChipSelectSuitView",ViewBase)

ChipSelectSuitView.RESOURCE_FILENAME = "chip_select_suit.json"
ChipSelectSuitView.RESOURCE_BINDING = {
	["item01"] = "item01",
	["item02"] = "item02",
	["btnDelete"] = {
		binds = {
			event = 'touch',
			methods = {ended = bindHelper.self('onBtnDelete')}
		}
	},
	["btnSure"] = {
		binds = {
			event = 'touch',
			methods = {ended = bindHelper.self('onBtnSure')}
		}
	},
	["txtVal"] = "txtVal",
	["slider"] = "slider",
	["listView"] = {
		binds = {
			event = "extend",
			class = "tableview",
			props = {
				data = bindHelper.self("suitData"),
				item = bindHelper.self("item01"),
				cell = bindHelper.self("item02"),
				sliderBg = bindHelper.self("slider"),
				leftPadding = 5,
				dataOrderCmp = function(a, b)
					return a.id < b.id
				end,
				columnSize = 2,
				itemAction = {isAction = true},
				onCell = function(list, node, k, v)
					local childs = node:multiget("imgSuit","txtSuitName","txtSuitVal","suitStatus","panelInfo")
					childs.imgSuit:texture(v.icon)
					childs.txtSuitName:text(v.name)
					childs.txtSuitVal:text(string.format(gLanguageCsv.chipSuitHaveNum, v.count))
					childs.suitStatus:setSelectedState(v.select)

					childs.panelInfo:removeAllChildren()
					local height = childs.panelInfo:size().height
					local str1 = ""
					for index, str in pairs(v.str) do
						str1 = str1..str.."\n"
					end

					local richText = rich.createWithWidth(str1, 40, nil, 900, nil, cc.p(0, 0.5))
							:anchorPoint(cc.p(0, 1))
							:xy(10, height+20)
							:addTo(childs.panelInfo)

					bind.touch(list, node, {methods = {ended = functools.partial(list.clickCell, k, v)}})
				end,
				onBeforeBuild = function(list)
					local listX, listY = list:xy()
					local listSize = list:size()
					local x, y = list.sliderBg:xy()
					local size = list.sliderBg:size()
					list:setScrollBarEnabled(true)
					list:setScrollBarColor(cc.c3b(241, 59, 84))
					list:setScrollBarOpacity(255)
					list:setScrollBarAutoHideEnabled(false)
					list:setScrollBarPositionFromCorner(cc.p(listX + listSize.width - x,(listSize.height - size.height) / 2 + 5))
					list:setScrollBarWidth(size.width)
					list:refreshView()
				end,
			},
			handlers = {
				clickCell = bindHelper.self("onItemClick"),
			},
		}
	}
}
ChipSelectSuitView.RESOURCE_STYLES = {
    -- blackLayer = true,
    backGlass = true,
}



function ChipSelectSuitView:onCreate(param)
	self:initModel()
	self.suitData = idlers.new({})
	self.selectUpSuitID = {}
	self.callBack = param.callBack
	self.suitCount = {}

	self:getSelectSuitID()
	self:calculateSuitCount()
	self:onSetSuitData()

	local blackLayer = ccui.Layout:create()
		:size(display.sizeInView)
		:xy(display.board_left, 0)
		:addTo(self, -99, "__black_")
	blackLayer:setBackGroundColorType(1)
	blackLayer:setBackGroundColor(cc.c3b(0, 0, 0))
	blackLayer:setBackGroundColorOpacity(204)
	blackLayer:setTouchEnabled(true)
end


function ChipSelectSuitView:initModel()
	self.roleChips = gGameModel.role:getIdler('chips')
end

function ChipSelectSuitView:getSelectSuitID()
	local temp = userDefault.getForeverLocalKey("selectUpSuitID", {})
	for _, val in ipairs(temp) do
		if val ~= 0 then
			table.insert(self.selectUpSuitID, val)
		end
	end
	self:setSelectUI()
end

function ChipSelectSuitView:calculateSuitCount()
	local roleChips = self.roleChips:read()
	for index, dbid in pairs(roleChips) do
		local chip = gGameModel.chips:find(dbid)
		local cfg = csv.chip.chips[chip:read("chip_id")]
		self.suitCount[cfg.suitID] = (self.suitCount[cfg.suitID] or 0)+1
	end
end

function ChipSelectSuitView:onSetSuitData()
	local suitHash = {}
	for _, val in ipairs(self.selectUpSuitID) do
		suitHash[val] = true
	end

	local suitDatas = {}
	for index, cfg in ipairs(csv.chip.suits) do
		local tempData = {}
		if not suitDatas[cfg.suitID] then
			tempData.id = cfg.suitID
			tempData.icon = cfg.suitIcon
			tempData.name = cfg.suitName
			tempData.select = suitHash[cfg.suitID] or false
			tempData.count = self.suitCount[cfg.suitID] or 0

			local cfgData = gChipSuitCsv[cfg.suitID][6]
			local attrs = {}
			local count = 1
			for val, cfg in pairs(cfgData) do
				local str = string.format(gLanguageCsv.chipSuitCount, val, "")
				if cfg.skillID and cfg.skillID ~= 0 then
					str = str.."#C0xFFFCED#"..string.gsub(csv.skill[cfg.skillID].describe, "#C0x5B545B#", "#C0xFFFCED#")
					str = string.gsub(str, "#C0x5c9970#", "#C0x91e1b1#")
				else

					for index = 1, math.huge do

						local attrT = cfg["attrType"..index]
						if attrT and attrT ~= 0 then
							local attrN = dataEasy.getAttrValueString(attrT, cfg["attrNum"..index])

							str = str .. string.format(gLanguageCsv.chipSuit01,getLanguageAttr(attrT), attrN)
						end

						local nextAttrT = cfg["attrType"..(index + 1)]
						if nextAttrT and nextAttrT ~= 0 then
							str =str.."#C0xFFFCED#, "
						else
							break
						end
					end
				end
				tempData.str = tempData.str or {}
				tempData.str[count] = str
				count = count + 1
			end
			suitDatas[cfg.suitID] = tempData
		end
	end
	self.suitData:update(suitDatas)
end

function ChipSelectSuitView:onBtnDelete()
	ViewBase.onClose(self)
end

function ChipSelectSuitView:onBtnSure()
	local temp = {}
	for index = 1, CHIPUPLIMIT do
		temp[index] = self.selectUpSuitID[index] or 0
	end
	userDefault.setForeverLocalKey("selectUpSuitID", temp)
	if self.callBack then
		self.callBack()
	end
	ViewBase.onClose(self)
end

function ChipSelectSuitView:setSelectUI()
	local x, y = self.txtVal:xy()
	local parent = self.txtVal:parent()
	self.txtVal:visible(false)
	local richText = parent:get("txtval2")
	local str = string.format(gLanguageCsv.chipSuitHasSelect, #self.selectUpSuitID, CHIPUPLIMIT)
	if richText then
		richText:removeFromParent()
	end
		richText = rich.createWithWidth(str, 40, nil, 1039, nil, cc.p(0, 0.5))
			:anchorPoint(cc.p(0, 0.5))
			:xy(x, y)
			:addTo(parent, 10, "txtval2")

end

function ChipSelectSuitView:onItemClick(list, k,v)
	local count = 0
	 for index, id in ipairs(self.selectUpSuitID) do
	 	if id == v.id then
	 		count = index
	 	end
	end

	if count >0 then
		table.remove(self.selectUpSuitID, count)
		self.suitData:atproxy(v.id).select = false
	else
		if #self.selectUpSuitID >= CHIPUPLIMIT then
			gGameUI:showTip(gLanguageCsv.chipSuitTip01)

		else
			table.insert(self.selectUpSuitID, v.id)
			self.suitData:atproxy(v.id).select = true

		end

	end

	self:setSelectUI()
end


return ChipSelectSuitView