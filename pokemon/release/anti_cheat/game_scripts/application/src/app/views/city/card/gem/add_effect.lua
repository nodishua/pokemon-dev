--加成效果
local GemAddEffectView = class("GemAddEffectView", cc.load("mvc").ViewBase)

GemAddEffectView.RESOURCE_FILENAME = "gem_add_effect.json"
GemAddEffectView.RESOURCE_BINDING = {
	["imgBg"] = {
		binds = {
			event = "click",
			method = bindHelper.self("onClose"),
		}
	},
	["resonance"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("btnResonance")}
		},
	},
	["resonance.title"] = {
		binds = {
			{
				event = "effect",
				data = {outline = {color = ui.COLORS.NORMAL.WHITE}}
			},
		}
	},
	["itemList"] = "itemList",
	["list"] = "list",
	["suitPanel"] = "suitPanel",
	["effect"] = "effect",
	["harm"] = "harm",
	["item2"] = "item2",
	["suitItem"] = "suitItem",
	["noItem"] = "noItem",
}

function GemAddEffectView:onCreate(cardDbid, index)
	self.cardDbid = cardDbid
	self.index = index
	self.pushSuitNum = 0
	self.list:setScrollBarEnabled(false)
	self.itemList:setScrollBarEnabled(false)
	self.suitPanel:get("suitList"):setScrollBarEnabled(false)
	local pushBackTab = function(str)
		local item2 = self.item2:clone():show()
		item2:get("title"):text(str)
		local x = item2:get("title"):x()
		item2:get("right"):x(item2:get("title"):width() / 2 + 40 + x)
		item2:get("left"):x(-item2:get("title"):width() / 2 - 40 + x)
		self.list:pushBackCustomItem(item2)
	end

	pushBackTab(gLanguageCsv.basicAttribute)
	-- --属性加成
	self:onAttrData()

	pushBackTab(gLanguageCsv.resonanceAttr)
	-- --套装加成
	self:onSuitData()

	pushBackTab(gLanguageCsv.indexAttr)
	-- --指数加成
	self:onIndexData()
	self.list:adaptTouchEnabled()
end

function GemAddEffectView:onAttrData()
	local gems = gGameModel.cards:find(self.cardDbid):read('gems')
	local effectData = {}
	for k,dbid in pairs(gems) do
		local gem = gGameModel.gems:find(dbid)
		local cfg = csv.gem.gem[gem:read('gem_id')]
		local level = gem:read('level')
		for i = 1, math.huge do
			if cfg['attrType'..i] and cfg['attrType'..i] ~= 0 and cfg['attrNum'..i] and cfg['attrNum'..i][level] then
				if not effectData[cfg['attrType'..i]] then
					effectData[cfg['attrType'..i]]  = {}
					table.insert(effectData[cfg['attrType'..i]], cfg['attrNum'..i][level])
				else
					table.insert(effectData[cfg['attrType'..i]], cfg['attrNum'..i][level])
				end
			else
				break
			end
		end
	end

	if csvSize(effectData) == 0 then
		local noItem = self.noItem:clone():show()
		noItem:get("txt"):text(gLanguageCsv.gemNestNotArrt1)
		self.list:pushBackCustomItem(noItem)
	else
		self:onDispose(effectData)
	end
end

function GemAddEffectView:onSuitData()
	local gems = gGameModel.cards:find(self.cardDbid):read('gems')
	local info = true
	-- 所有已激活符石套装id对应品质 {1 = {{quality = 4}, {quality = 2}, {quality = 2}}
	local map = {}
	for _, dbid in pairs(gems) do
		local data = gGameModel.gems:find(dbid)
		local cfg = csv.gem.gem[data:read('gem_id')]
		if cfg.suitID then
			map[cfg.suitID] = map[cfg.suitID] or {}
			table.insert(map[cfg.suitID], {quality = cfg.quality})
		end
	end


	-- 激活的套装
	local suitQualitys = {}
	for suitID, tbl in pairs(map) do
		table.sort(tbl, function(a, b)
			return a.quality > b.quality
		end)
		local _, cfg = next(gGemSuitCsv[suitID])
		for i = 1, #tbl do
			if cfg[i] then
				table.insert(suitQualitys, {suitID = suitID, suitNum = i, quality = tbl[i].quality})
			end
		end
	end


	local pushSuitDataFunc = function(data)
		local suitPanel
		for k, v in ipairs(data) do
			if k % 3 == 1 then
				suitPanel = self.suitPanel:clone():show()
				self.list:pushBackCustomItem(suitPanel)
			end
			local itemSuit = self.suitItem:clone():show()
			itemSuit:get("icon"):texture(ui.GEM_SUIT_ICON[v.suitID])
			itemSuit:get("num"):text('x' .. v.suitNum ..":")
			local showAttr = 1
			local suitData = gGemSuitCsv[v.suitID][v.quality][v.suitNum]
			itemSuit:get("name"):text(string.format("%s(%s)", suitData.suitName, gLanguageCsv[ui.QUALITY_COLOR_TEXT[v.quality]]))
			text.addEffect(itemSuit:get("name"), {color=ui.COLORS.QUALITY_DARK[v.quality]})
			for i = 1, math.huge do
				if suitData["attrType"..i] and suitData["attrType"..i] ~= 0 then
					local attrTypeStr = game.ATTRDEF_TABLE[suitData["attrType"..i]]
					local name = gLanguageCsv["attr"..string.caption(attrTypeStr)]
					adapt.setTextAdaptWithSize(itemSuit:get("txt"..i), {str = name, size = cc.size(230,80), vertical = "center", horizontal = "center", margin = -5, maxLine = 2})
					adapt.oneLinePos(itemSuit:get("txt"..i), itemSuit:get("num"..i), cc.p(-7, 0))
					itemSuit:get("num"..i):text(' +'..dataEasy.getAttrValueString(suitData["attrType"..i], suitData["attrNum"..i]))
					showAttr = i
				else
					break
				end
			end
			if showAttr == 1 then
				for i = 1, 3 do
					itemSuit:get("txt"..i):visible(showAttr >= i)
					itemSuit:get("num"..i):visible(showAttr >= i)
				end
				itemSuit:get("txt1"):y(itemSuit:get("txt2"):y())
				itemSuit:get("num1"):y(itemSuit:get("num2"):y())

			elseif showAttr == 2 then
				itemSuit:get("txt3"):visible(false)
				itemSuit:get("num3"):visible(false)
				for i = 1, 2 do
					itemSuit:get("txt"..i):y(itemSuit:get("txt"..i):y() - 30)
					itemSuit:get("num"..i):y(itemSuit:get("num"..i):y() - 30)
				end
			end
			suitPanel:get("suitList"):pushBackCustomItem(itemSuit)
			-- 单行内容才进行居中显示
			if #data < 3 then
				suitPanel:get("suitList"):setItemAlignCenter()
			end
		end
	end

	if #suitQualitys == 0 then
		local noItem = self.noItem:clone():show()
		noItem:get("txt"):text(gLanguageCsv.gemNestNotArrt2)
		self.list:pushBackCustomItem(noItem)
	else
		pushSuitDataFunc(suitQualitys)
	end
end

--#@ info是个比较特殊的参数，相同属性如：
--#@ 物攻同时拥有百分比加成和固定加成就要分开显示
--#@ 百分比加成没有图标
function GemAddEffectView:onDispose(data, index, info)
	local itemNum = 0
	local itemList
	for k,v in pairs(data) do
		local num = 0
		if index then
			k = v.key
			num = v.num
		else
			for k1,v1 in pairs(v) do
				num = num + v1
			end
		end
		if k then
			local attrKey = game.ATTRDEF_TABLE[k]
			local iconAttr = attrKey
			local attrKey = 'attr'..attrKey:gsub("^%l", string.upper)
			local name = gLanguageCsv[attrKey]
			itemNum = itemNum + 1
			if itemNum % 3 == 1 then
				itemList = self.itemList:clone():show()
				self.list:pushBackCustomItem(itemList)
			end
			if game.ATTRDEF_SHOW_NUMBER[k] then
				local item = self.effect:clone():show()
				item:get("name"):text(name)
				item:get("num"):text('+'..num)
				item:get("icon"):texture(ui.ATTR_LOGO[iconAttr])
				if info then
					item:get("icon"):visible(false)
					text.addEffect(item:get("num"), {color = ui.COLORS.NORMAL.FRIEND_GREEN})
					local width1 = item:get("name"):x() - item:get("icon"):x() - item:get("icon"):width()/2
					item:get("name"):x(item:get("icon"):x() - item:get("icon"):width()/2)
					item:get("num"):x(item:get("name"):x() + item:get("name"):width() + 30)
				end
				itemList:pushBackCustomItem(item)
			else
				local item = self.harm:clone():show()
				item:get("name"):text(name)
				item:get("num"):x(item:get("name"):width() + item:get("name"):x() + 20)
				item:get("num"):text('+'..dataEasy.getAttrValueString(k ,num))
				itemList:pushBackCustomItem(item)
			end

		end
	end
end

function GemAddEffectView:onIndexData()
	local cardsId = gGameModel.cards:find(self.cardDbid):read("card_id")
	local gemQualitySeqID = csv.cards[cardsId].gemQualitySeqID
	local indexData = {}
	local info1, info2 = true, true
	local indexNum1, indexNum2 = 0, 0
	for _,v in orderCsvPairs(csv.gem.quality_attrs) do
		if gemQualitySeqID == v.gemQualitySeqID and v.qualityNum <= self.index then
			for i = 1, math.huge do
				if v['attrType'..i] and v['attrType'..i] ~= 0 then
					local attrTypeStr = game.ATTRDEF_TABLE[v["attrType"..i]]
					local name = gLanguageCsv["attr"..string.caption(attrTypeStr)]
					if not indexData[1] or not indexData[2] then
						indexData[1] = indexData[1] or {}
						indexData[2] = indexData[2] or {}
						local _, info = dataEasy.parsePercentStr(v["attrNum"..i])
						--0 含%的数字, 1不含
						local point = info == 1 and 1 or 2
						table.insert(indexData[point], {key = v["attrType"..i], num = dataEasy.getAttrValueString(v['attrType'..i] ,v["attrNum"..i])})
					else
						info1, info2 = true, true
						indexNum1, indexNum1 = 0, 0
						local _, percent = dataEasy.parsePercentStr(v['attrType'..i], v["attrNum"..i])
						local pos = string.find(v["attrNum"..i],'%%')
						if percent == 1 and not pos then
							for k2,v2 in pairs(indexData[1]) do
								if v['attrType'..i] == v2.key then
									info1 = false
									indexData[1][K2].num = v2.num + dataEasy.getAttrValueString(v['attrType'..i] ,v["attrNum"..i])
								end
							end
							if info1 then
								table.insert(indexData[1], {key = v["attrType"..i], num = dataEasy.getAttrValueString(v['attrType'..i] ,v["attrNum"..i])})
							end
						else
							for k2,v2 in pairs(indexData[2]) do
								if v['attrType'..i] == v2.key then
									info2 = false
									indexNum1 = dataEasy.parsePercentStr(v["attrNum"..i])
									indexNum2 = dataEasy.parsePercentStr(v2.num)
									indexData[2][k2].num = dataEasy.getPercentStr(indexNum2 + indexNum1, 0)
								end
							end
							if info2 then
								table.insert(indexData[2], {key = v["attrType"..i], num = dataEasy.getAttrValueString(v['attrType'..i] ,v["attrNum"..i])})
							end
						end
					end
				else
					break
				end
			end
		end
	end

 	if #indexData == 0 then
		local noItem = self.noItem:clone():show()
		noItem:get("txt"):text(gLanguageCsv.gemNestNotArrt3)
		self.list:pushBackCustomItem(noItem)
	else
		table.sort(indexData[1], function(a, b)
			return a.key < b.key
		end)
		table.sort(indexData[2], function(a, b)
			return a.key < b.key
		end)
		self:onDispose(indexData[1], true)
		self:onDispose(indexData[2], true, true)
	end
end

-- --共鸣效果
function GemAddEffectView:btnResonance()
	gGameUI:stackUI("city.card.gem.resonance", nil, nil)
end

return GemAddEffectView