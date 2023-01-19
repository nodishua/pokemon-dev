-- @date:   2019-06-21
-- @desc:   携带道具突破详情界面

local HeldItemTools = require "app.views.city.card.helditem.tools"

local MINHEIGHT = 640
local MAXHEIGHT = 973

local function onInitItem(list, node, k, v)
	local title = gLanguageCsv.advance .. " +" .. v.advance
	if v.advance == list.advance then
		title = title .. string.format("(%s)", gLanguageCsv.current)
	end
	local skillLv = v.rellyAdvance and v.rellyAdvance + 1 or v.advance + 1
	node:get("textTitle"):text(title)
	local isLock = list.advance < v.advance
	local strTab = {}
	for i,attrId in ipairs(v.attr) do
		local efcInfo = csv.held_item.effect[attrId]
		local str = efcInfo.desc
		local params = {}
		-- 是否专属
		local startIdx = 1
		if itertools.size(efcInfo.exclusiveCards) > 0 then
			-- 是专属的话 第一个参数就是英雄名字
			local markId = efcInfo.exclusiveCards[1]
			local cardMarkCfg = csv.cards[markId]
			local unitCfg = csv.unit[cardMarkCfg.unitID]
			table.insert(params, cardMarkCfg.name)
			if not isLock then
				local natureType = unitCfg.natureType
				local color = ui.ATTRCOLOR[game.NATURE_TABLE[natureType]]
				str = HeldItemTools.insertColor(str, color, true, startIdx, true)
			end
			startIdx = startIdx + 1
		end
		local defaultColor = "#C0x5B545B#"
		if isLock then
			defaultColor = "#C0xB7B09E#"
		end
		-- 属性类型
		if efcInfo.type == 1 then
			for i=1,100 do
				if not efcInfo["attrNum" .. i] then
					break
				end
				local efcVal = efcInfo["attrNum" .. i][v.idx]
				local efcType = efcInfo["attrType" .. i]
				table.insert(params, dataEasy.getAttrValueString(efcType, efcVal))
			end

			str = HeldItemTools.insertColor(str, ui.QUALITYCOLOR[2], false, startIdx, false, defaultColor)
		-- 技能类型
		elseif efcInfo.type == 2 then
			local desc = csv.skill[efcInfo.skillID].describe
			-- 技能描述是一长段话 需要对公式那部分单独处理颜色
			desc = HeldItemTools.insertSkillDescColor(desc, ui.QUALITYCOLOR[2], defaultColor)
			table.insert(params, eval.doMixedFormula(desc, {skillLevel = skillLv, math = math}))
		end
		local targetStr = string.format(str, unpack(params))
		table.insert(strTab, targetStr)
	end
	local content = table.concat(strTab, '\n')
	if v.isNew then
		content = content .. "#Icommon/icon/txt_new.png#"
	end
	local color = "#C0x5B545B#"
	if isLock then
		color = "#C0xB7B09E#"
	end
	local richText = rich.createWithWidth(color .. content, 40, nil, 920)
			:anchorPoint(0, 1)
			:x(25)
			:addTo(node, 10, "attrText")
	local size = richText:size()
	local height = size.height + 50
	node:size(960, height)
	node:get("textTitle"):y(height - 25)
	richText:y(height - 50)
	list.baseNodeHeight:modify(function(val)
		return true, val + height
	end)
end


local HeldItemBreachView = class("HeldItemBreachView", Dialog)

HeldItemBreachView.RESOURCE_FILENAME = "held_item_info.json"
HeldItemBreachView.RESOURCE_BINDING = {
	["baseNode"] = "baseNode",
	["baseNode.imgBg"] = "imgBg",
	["item"] = "item",
	["baseNode.list"] = {
		varname = "list",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("infos"),
				item = bindHelper.self("item"),
				advance = bindHelper.self("advance"),
				baseNodeHeight = bindHelper.self("baseNodeHeight"),
				onItem = function(list, node, k, v)
					onInitItem(list, node, k, v)
				end,
				onAfterBuild = function(list)
					list.afterBuild()
				end,
			},
			handlers = {
				afterBuild = bindHelper.self("onAfterBuild")
			},
		},
	},
}

function HeldItemBreachView:onCreate(params)
	local advance = params.data.advance
	self.advance = advance
	self.params = params
	-- self.event = event
	-- self.offPos = offPos or {}
	self.baseNodeHeight = idler.new(0)
	local cfg = params.data.cfg
	local csvId = params.data.csvId
	local csvTab = csv.held_item.items
	local maxAdvance = cfg.advanceMax
	local t = {}
	local effectOpenTab = {}
	local openLvTab = {}
	local count = 0
	for i=1,math.huge do
		local attrId = cfg["effect"..i]
		if not attrId or attrId == 0 then
			break
		end
		local v = cfg[string.format("effect%dLevelAdvSeq", i)]
		count = count + 1
		local openLv = v[1]
		if not effectOpenTab[openLv] then
			effectOpenTab[openLv] = {}
		end
		table.insert(effectOpenTab[openLv], attrId)
		openLvTab[openLv] = true
	end
	-- 用来记录已经显示过的内容
	local showData = {}
	for i=1,count do
		local v = cfg[string.format("effect%dLevelAdvSeq", i)]
		local isNew = true
		if advance >= v[1] then
			isNew = false
		end
		local flag = 0
		for k,vv in ipairs(v) do
			if vv <= maxAdvance and not showData[vv] then
				showData[vv] = true
				flag = flag + 1
				-- 新增只需要一次
				if flag > 1 then
					isNew = false
				end
				local allAttrs = {}
				for openLv,_ in pairs(openLvTab) do
					if vv >= openLv then
						for _,attrId in pairs(effectOpenTab[openLv]) do
						 	table.insert(allAttrs, attrId)
						end
					end
				end
				table.insert(t, {attr = allAttrs, advance = vv, idx = k, cfg = data, isNew = isNew})
			end
		end
	end
	table.sort(t, function(a, b)
		return a.advance < b.advance
	end)
	for i=2, math.huge do
		local nowData = t[i]
		local beforeData = t[i - 1]
		if not nowData then
			break
		end
		local delta = nowData.advance - beforeData.advance
		for j=1,delta - 1 do
			local newData = clone(beforeData)
			newData.isNew = false
			newData.advance = newData.advance + j
			newData.rellyAdvance = beforeData.advance
			table.insert(t, i - 1 + j, newData)
		end
	end

	self.infos = idlertable.new(t)

	Dialog.onCreate(self, {noBlackLayer = true,clickClose = true})
end

function HeldItemBreachView:onAfterBuild(list)
	local lenght = self.infos:size()
	local targetHeight = math.max(MINHEIGHT, self.baseNodeHeight:read())
	targetHeight = math.min(MAXHEIGHT, targetHeight)
	local width = self.baseNode:size().width
	self.baseNode:size(width, targetHeight)
	-- 背景图片周围有阴影 稍微大一点
	self.imgBg:size(width + 10, targetHeight + 5)
	self.imgBg:y(targetHeight / 2)
	self.list:size(960, targetHeight - 50)
	self.list:y(25)
	local h = self.params.target:getBoundingBox().height
	local y = self.params.y - targetHeight / 2 - h / 2
	local cx, cy = self:resetPosition(self.params.x, y)
	local offx, offy = self.params.offx or 0, self.params.offy or 0
	self.baseNode:xy(cx + offx, cy + offy)
end

function HeldItemBreachView:resetPosition(x, y)
	local targetx, targety = x, y
	local node = self:getResourceNode()
	local box = node:getBoundingBox()
	local height = display.size.height
	local width = display.size.width
	local size = self.baseNode:size()
	local topY = y + size.height / 2
	local downY = y - size.height / 2
	if topY > height then
		-- 50是topUI的预留高度
		targety = height - 50 - size.height / 2
	elseif downY < 0 then
		-- 20:底下稍微 预留一点
		targety = size.height / 2 + 20
	end

	local leftX = x - size.width / 2
	-- 20:左边稍微 预留一点
	if leftX < 0 then
		targetx = size.width / 2 + 20
	elseif leftX > width then
		targetx = width - size.width / 2 - 20
	end

	return targetx, targety
end

return HeldItemBreachView