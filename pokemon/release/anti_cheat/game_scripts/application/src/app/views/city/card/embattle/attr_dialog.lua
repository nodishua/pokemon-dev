
local ViewBase = cc.load("mvc").ViewBase
local CardEmbattleAttrDialog = class("CardEmbattleAttrDialog", Dialog)
local setTextColor = function (t, b)
	if b then return end
	local color = cc.c4b(182, 175, 157, 255)
	text.addEffect(t, {color=color})
end

CardEmbattleAttrDialog.RESOURCE_FILENAME = "card_embattle_attr_dialog.json"
CardEmbattleAttrDialog.RESOURCE_BINDING = {
	["btnClose"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")},
		},
	},
	["text"] = "attrText",
	["item"] = "item",
	["textItem1"] = "textItem1",
	["list"] = {
		varname = "list",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				asyncPreload = 4,
				data = bindHelper.self("buffData1"),
				item = bindHelper.self("item"),
				textItem = bindHelper.self("textItem1"),
				itemAction = {isAction = true},
				onAfterBuild = function(list)
					list.afterBuild()
				end,
				onItem = function(list, node, k, v)
					local children = node:multiget("icon", "textList", "text", "bg")
					children.icon:texture(v.icon)
					children.text:text(v.desc)
					adapt.setTextAdaptWithSize(children.text, {size = cc.size(1100,100), vertical = "center", margin = -3})
					bind.extend(list, children.textList, {
						class = "listview",
						props = {
							data = v.data,
							item = list.textItem,
							onItem = function(list, node, k, value)
								local children = node:multiget("text1", "text2")
								children.text1:text(value[1])
								children.text2:text(value[2])
								adapt.oneLinePos(children.text1, children.text2, cc.p(0, 0))
								setTextColor(children.text1, v.isGet)
								setTextColor(children.text2, v.isGet)
							end
						}
					})
					children.icon:get("mask"):visible(not v.isGet)
					setTextColor(children.text, v.isGet)

					if v.isLast then
						children.bg:hide()
					end
				end,
			},
			handlers = {
				afterBuild = bindHelper.self("initBottomType"),
			},
		},
	},
	["textItem2"] = "textItem2",
	["subList"] = "subList",
	["bottomItem"] = "bottomItem",
	["textNote1"] = "textNote1",
	["textNote3"] = "textNote3",
}

function CardEmbattleAttrDialog:onCreate(teamBuffs)
	local csvHalo = csv.battle_card_halo
	local buffData = {} -- 已激活buff的效果
	local buffData1 = {} -- 第一类buff
	local buffData2 = {} -- 第二类buff
	for id, cfg in csvPairs(csvHalo) do
		local isGet = false -- 是否激活
		if cfg.type == 1 then
			local attrData = {}
			for i = 1, 3 do
				if cfg["attrType"..i] ~= 0 then
					local attr = cfg["attrType"..i]
					local value = cfg["attrValue"..i]
					local attrS = gLanguageCsv["attr" .. string.caption(game.ATTRDEF_TABLE[attr])]

					if teamBuffs[id] then -- 此buff已经激活
						isGet = true
						local percent = false
						local val = value
						if string.find(val, "%%") then -- 如果有%号
							val = string.sub(val, 1, #val - 1)
							percent = true
						end
						val = tonumber(val)
						buffData[attrS] = buffData[attrS] or {attr = attr, percent = percent, value = 0}
						buffData[attrS].value = buffData[attrS].value + val
					end

					value = "+" .. dataEasy.getAttrValueString(attr, value)
					table.insert(attrData, {attrS, value})
				end
			end
			table.insert(buffData1, {
				id = id,
				icon = cfg.icon,
				desc = cfg.desc,
				isGet = isGet,
				data = attrData
			})
		elseif cfg.type == 2 then
			self.bottomIcon = cfg.icon
			self.bottomDesc = cfg.desc
			local args = cfg.args
			local arg = args[1] -- todo 目前 我们指关心单数的属性 复数的不考虑

			if teamBuffs[id] then -- 此buff已经激活
				isGet = true
			end
			local attrS = gLanguageCsv["attr" .. string.caption(game.ATTRDEF_TABLE[cfg.attrType1])]

			table.insert(buffData2, {
				attr = arg[1],
				num = "+" .. arg[2],
				str1 = attrS,
				str2 = "+" .. dataEasy.getAttrValueString(cfg.attrType1, cfg.attrValue1),
				isGet = isGet,
			})
		end
	end
	table.sort(buffData1, function(a, b)
		return a.id < b.id
	end)

	local dataLen1 = #buffData1
	local dataLen2 = #buffData2
	if dataLen2 <= 0 then
		buffData1[dataLen1].isLast = true
	end

	self.buffData1 = buffData1
	self.buffData2 = buffData2

	local attrStrings = {}
	for attrS, tb in pairs(buffData) do
		local str = attrS .. "+" .. dataEasy.getAttrValueString(tb.attr, tb.value)
		if tb.percent then
			str = str.."%"
		end
		table.insert(attrStrings, {
			attrId = tb.attr,
			str = str
		})
	end
	table.sort(attrStrings, function(a, b)
		return a.attrId < b.attrId
	end)

	local t = {}
	for _, strTb in pairs(attrStrings) do
		table.insert(t, strTb.str)
	end

	self.attrText:text(table.concat(t, ", "))
	self.textNote1:text(gLanguageCsv.teamHaloTitle)
	if not matchLanguage({"cn", "tw"}) then
		adapt.setTextAdaptWithSize(self.textNote1, {size = cc.size(1650,200), margin = -3})
    	self.textNote1:y(self.textNote1:y() - 55)

		adapt.setTextAdaptWithSize(self.textNote3, {size = cc.size(1650,200), margin = -8})
    	self.textNote3:y(self.textNote3:y() - 55)
	end
	Dialog.onCreate(self)
end

function CardEmbattleAttrDialog:initBottomType()
	local columnCountMax = 3
	local bottomItem = self.bottomItem:clone():show()
	local children = bottomItem:multiget("icon", "text", "list", "bg")
	children.bg:hide()
	children.icon:texture(self.bottomIcon)
	children.text:text(self.bottomDesc)
	local isTypeGet = false

	-- 关闭滚动
	children.list:setScrollBarEnabled(false)
	self.subList:setScrollBarEnabled(false)
	local subList = self.subList:clone()
	local rowHeight = subList:size().height
	local rowCount = 0
	local curChildrenCount = 0
	local curChildrenLength = 0
	local function resetSubList()
		children.list:pushBackCustomItem(subList)
		rowCount = rowCount + 1
		curChildrenCount = 0
		curChildrenLength = 0
		subList = self.subList:clone()
	end

	for _, data in pairs(self.buffData2) do
		local item = self.textItem2:clone()
		local itemChildren = item:multiget("text1", "text2", "text3", "icon")
		itemChildren.icon:texture(ui.ATTR_ICON[data.attr])
		itemChildren.text1:text(data.num)
		itemChildren.text2:text(data.str1)
		itemChildren.text3:text(data.str2)

		setTextColor(itemChildren.text1, data.isGet)
		setTextColor(itemChildren.text2, data.isGet)
		setTextColor(itemChildren.text3, data.isGet)

		if data.isGet then
			isTypeGet = true
		end

		-- local grayState = data.isGet and "normal" or "hsl_gray"
		-- cache.setShader(item, false, grayState)

		local size = item:size()
		local size1 = itemChildren.text2:size()
		local size2 = itemChildren.text3:size()
		local width = size.width
		local height = size.height

		adapt.oneLinePos(itemChildren.text2, itemChildren.text3, cc.p(0, 0))
		item:size(width + size1.width + size2.width, height)

		local curWidth = item:size().width
		-- 如果太长了 要提前换行
		if curChildrenLength + curWidth > subList:size().width then
			resetSubList()
		end

		curChildrenLength = curChildrenLength + curWidth
		curChildrenCount = curChildrenCount + 1
		subList:pushBackCustomItem(item)

		-- 满足一行上限 更新
		if curChildrenCount >= columnCountMax then
			resetSubList()
		end
	end

	if curChildrenCount > 0 then
		resetSubList()
	end

	-- 插入一行后 根据行数 自适应list 和 item高度
	local outSize = children.list:size()
	local subHeight = math.max((rowCount - 1), 0) * self.subList:size().height
	children.list:size(outSize.width, outSize.height + subHeight)
	local bottomItemSize = bottomItem:size()
	bottomItem:size(bottomItemSize.width, bottomItemSize.height + subHeight)
	children.icon:y(children.icon:y() + subHeight)
	children.text:y(children.text:y() + subHeight)
	setTextColor(children.text, isTypeGet)
	children.icon:get("mask"):visible(not isTypeGet)

	if rowCount > 0 then
		self.list:pushBackCustomItem(bottomItem)
	end
end

return CardEmbattleAttrDialog

