
--芯片详情界面
local ChipDetailsView = class("ChipDetailsView", cc.load("mvc").ViewBase)
local ChipTools = require('app.views.city.card.chip.tools')

ChipDetailsView.RESOURCE_FILENAME = "common_chip_details.json"
ChipDetailsView.RESOURCE_BINDING = {
	["baseNode.panel.bg"] = {
		varname = "bg",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")},
		}
	},
	["baseNode"] = "baseNode",
	["baseNode.panel"] = "panel",
	["baseNode.panel.icon"] = "icon",
	["baseNode.panel.name"] = "name",
	["baseNode.panel.level"] = "level",
	["baseNode.panel.bg2"] = "bg2",
	["baseNode.panel.list"] = "list",
	["baseNode.panel.attrPanel"] = "attrPanel",
	["baseNode.panel.linePanel"] = "linePanel",
	["baseNode.panel.suitPanel"] = "suitPanel",
}

function ChipDetailsView:onCreate(param)
	local id, level
	if param.dbId then
		local chip = gGameModel.chips:find(param.dbId)
		id = chip:read('chip_id')
		level = chip:read('level')
	else
		id = param.key
		level = 1
	end

	local data = {}
	local cfg = csv.chip.chips[id]
	bind.extend(self, self.icon, {
		class = 'icon_key',
		props = {
			noListener = true,
			data = {
				key = id,
			},
			specialKey = {
				lv = level
			},
			onNode = function(panel)
				panel:get("defaultLv"):hide()
			end,
		},
	})
	uiEasy.setIconName(id, 0, {node = self.name})
	self.level:text("Lv" .. level)

	local attrCount = 0
	local lintCount = 0
	local suitCount = 0
	self.list:removeAllChildren()
	self.list:setScrollBarEnabled(false)

	local firstAttrs, secondAttrs = ChipTools.getAttrByChipId(id)
	if  param.dbId then
		firstAttrs, secondAttrs = ChipTools.getAttr(param.dbId, level, true, true)
	end

	local flag = false
	for _, data in ipairs(firstAttrs) do
		local key = data.key
		if not ChipTools.ignoreAttr(key) then
			flag = true
			local val = data.val
			local item = self.attrPanel:clone():show()
			local name = ChipTools.getAttrName(key)
			item:get("key"):text(name)
			item:get("val"):text("+" .. val)
			self.list:pushBackCustomItem(item)
			attrCount = attrCount + 1
		end
	end

	if flag then
		local item = self.linePanel:clone():show()
		self.list:pushBackCustomItem(item)
		lintCount =lintCount +1
	end

	flag = false
	for k, data in ipairs(secondAttrs) do
		local key = data.key
		flag = true
		if not key then
			local item = self.attrPanel:clone():show()
			item:get("key"):text(data.name)
			item:get("val"):text(data.val)
			text.addEffect(item:get("key"), {color = ui.COLORS.NORMAL.GRAY})
			text.addEffect(item:get("val"), {color = ui.COLORS.NORMAL.GRAY})
			self.list:pushBackCustomItem(item)
			attrCount = attrCount + 1

		elseif not ChipTools.ignoreAttr(key) then
			local val = data.val
			local item = self.attrPanel:clone():show()
			local name = ChipTools.getAttrName(key)
			item:get("key"):text(name)
			item:get("val"):text("+" .. val)
			self.list:pushBackCustomItem(item)
			attrCount = attrCount + 1
		end
	end

	if flag then
		local item = self.linePanel:clone():show()
		self.list:pushBackCustomItem(item)
		lintCount =lintCount +1
	end

	-- 添加套装属性
	local strs = {}

	local cfgData = gChipSuitCsv[cfg.suitID][cfg.quality]
	local suitAttrs = {}

	for index, data in pairs(cfgData) do
		table.insert(suitAttrs, {data.suitNum, data.suitQuality, false})
	end

	for _, data in ipairs(suitAttrs) do
		local str = ChipTools.getSuitAttrStr(cfg.suitID, data)
		table.insert(strs, {str = str})
	end

	local suitPanel = self.suitPanel:clone():show()
	local list, height = beauty.textScroll({
		list = suitPanel:get("list"),
		strs = strs,
		margin = 10,
		isRich = true,
	})
	local lastHeight = attrCount*self.attrPanel:size().height + lintCount*self.linePanel:size().height + height
	list:height(height)
	list:setTouchEnabled(false)
	suitPanel:height(height)
	self.list:pushBackCustomItem(suitPanel)
	self.bg2:size(cc.size(self.bg2:size().width, lastHeight + 30))
	self.bg:size(cc.size(self.bg:size().width, lastHeight + 305))
	self.baseNode:size(cc.size(self.bg:size().width, lastHeight + 400))
	self.panel:xy(self.baseNode:size().width/2, self.baseNode:size().height)
end


return ChipDetailsView