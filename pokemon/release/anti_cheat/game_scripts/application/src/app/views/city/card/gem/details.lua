
--符石详情界面
local ViewBase = cc.load("mvc").ViewBase
local GemDetailsView = class("GemDetailsView", ViewBase)
local GemTools = require('app.views.city.card.gem.tools')

local QUALITY_MIN = 2
local QUALITY_MAX = 6

GemDetailsView.RESOURCE_FILENAME = "gem_details.json"
GemDetailsView.RESOURCE_BINDING = {
	["panel.intensify"] = {
		varname = "intensify",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("intensifyFunc")},
		}
	},
	["panel.inlay"] = {
		varname = "inlay",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("inlayFunc")},
		}
	},
	["panel.icon"] = "icon",
	["panel.quality"] = "quality",
	["panel.list"] = "list",
	["panel.txt"] = "txt",
	["panel.name"] = "name",
	["panel.panelLab"] = "panelLab",
	["panel.property"] = "property",
	["panel.quile"] = "quile",
	["panel.item"] = "item",
	["panel.mask"] = "mask",
	['panel'] = 'panel'
}

-- @from:1 打开 2关闭 (强化和镶嵌)
function GemDetailsView:onCreate(param)
	self.slotIdx = param.slotIdx
	local txt = self.inlay:get('txt')
	local str = gLanguageCsv.spaceDischarge
	self.cardID = param.cardID
	if param.dbid then
		local gems = gGameModel.cards:find(self.cardID):read('gems')
		if gems[self.slotIdx] then
			str = gLanguageCsv.spaceExchange2
		else
			str = gLanguageCsv.spaceInlay
		end
	end
	txt:text(str)
	self.mask:visible(false)

	if param.dbid then
		self.dbid = param.dbid
	else
		self.unEquip = true
		self.dbid = gGameModel.cards:find(self.cardID):read('gems')[self.slotIdx]
	end
	self.cb = param.cb

	local gem = gGameModel.gems:find(self.dbid)
	idlereasy.when(gem:getIdler('level'), function (_, level)
		self:initPanel(self.panel, self.dbid, level)
	end)

	self.txt:visible(false)
	self.panelLab:visible(false)

	local pos = param.pos
	local align = param.align
	local x
	local width = self.panel:size().width
	if align == 'left' then
		x = pos.x - width / 2
	else
		x = pos.x + width / 2
	end
	local p = self:getResourceNode():convertToNodeSpace(cc.p(x, 0))
	self.panel:x(p.x)

	if param.dbid and param.slotIdx then
		local gems = gGameModel.cards:find(self.cardID):read('gems')
		if gems[self.slotIdx] then
			local gem = gGameModel.gems:find(gems[self.slotIdx])
			self:createSmallPanel(param, gems[self.slotIdx], gem:read('level'))
		end
	end
end

function GemDetailsView:initPanel(panel, dbid, level)
	local gem = gGameModel.gems:find(dbid)
	local childs = panel:multiget('list', 'quality', 'name', 'quile', 'property', 'icon', 'panelLab', 'txt', 'item')
	childs.list:removeAllChildren()
	childs.list:setScrollBarEnabled(false)
	local data = {}
	local id = gem:read('gem_id')
	local cfg = dataEasy.getCfgByKey(id)
	local quality = cfg.quality
	local qualityTxt = "qualityNum"..quality
	childs.quality:text(csv.gem.quality[level][qualityTxt])
	childs.name:text(cfg.name)
	text.addEffect(childs.name, {color=ui.COLORS.QUALITY_DARK[quality]})


	if not csv.gem.gem[id] or not csv.gem.gem[id].gemDescribe then
		childs.property:visible(false)
		childs.quile:y(self.property:y())
		childs.quality:y(self.property:y())
	else
		childs.property:text(csv.gem.gem[id].gemDescribe)
	end

	bind.extend(self, childs.icon, {
		class = 'icon_key',
		props = {
			data = {
				key = id,
			},
			noListener = true,
			specialKey = {
				leftTopLv = level
			},
			onNode = function(panel)
			end
		}
	})

	for i = 1, math.huge do
		if cfg['attrType'..i] and cfg['attrType'..i] ~= 0 and cfg['attrNum'..i] and cfg['attrNum'..i][level] then
			local attrKey = game.ATTRDEF_TABLE[cfg['attrType'..i]]
			attrKey = 'attr'..attrKey:gsub("^%l", string.upper)
			local item = childs.txt:clone():show()
			item:get("txt"):text(gLanguageCsv[attrKey])
			item:get("number"):text('+'..dataEasy.getAttrValueString(cfg["attrType"..i], cfg['attrNum'..i][level]))
			item:get("number"):x(item:get("txt"):width()+10)
			dataEasy.tryCallFunc(childs.list, "updatePreloadCenterIndex")
			childs.list:pushBackCustomItem(item)
		else
			break
		end
	end

	childs.item:visible(false)
	--套装属性
	local gemData = gGameModel.cards:find(self.cardID):read('gems')
	local isDress = false
	local suitID = cfg.suitID
	if suitID then
		for k,v in pairs(gemData) do
			if dbid == v then
				isDress = true
			end
		end
		local qualitys = {}
		if isDress then
			local suitQuality = {}
			for i = QUALITY_MIN, QUALITY_MAX do
				suitQuality[i] = 0
			end
			for i = 1, 9 do
				local gemdbid = gemData[i]
				if gemdbid then
					local gem = gGameModel.gems:find(gemdbid)
					local cfg = csv.gem.gem[gem:read('gem_id')]
					if cfg.suitID == suitID then
						for j = QUALITY_MIN, cfg.quality do
							suitQuality[j] = suitQuality[j] + 1
						end
					end
				end
			end
			for k = 1, 9 do
				for i = QUALITY_MIN, QUALITY_MAX do
					if suitQuality[i] >= k then
						qualitys[k] = i
					end
				end
			end
		end

		local item = childs.item:clone():show()
		childs.list:pushBackCustomItem(item)
		local _, suitCfg = next(gGemSuitCsv[suitID])
		for i = 1, 9 do
			if suitCfg[i] then
				self:showText(childs, i, qualitys[i], cfg)
			end
		end
	end

end

function GemDetailsView:showText(node, suitNum, quality, cfg)
	local addQuality = quality or cfg.quality
	local data = gGemSuitCsv[cfg.suitID][addQuality][suitNum]
	if data == nil then
		return
	end
	local color = "#C0x60C456#"
	if not quality then
		color = "#C0xB7B09E#"
	end

	local txt1 = string.format(gLanguageCsv.numSuit, suitNum)
	txt1 = data.suitName .. string.format("%s(%s)%s", txt1, gLanguageCsv[ui.QUALITY_COLOR_TEXT[addQuality]], gLanguageCsv.symbolColon)
	local txt2
	for i = 1, math.huge do
		if data["attrType" .. i] and data["attrType" .. i] ~= 0 then
			local attrTypeStr = game.ATTRDEF_TABLE[data["attrType"..i]]
			local name = gLanguageCsv["attr"..string.caption(attrTypeStr)]
			if txt2 then
				txt2 = txt2 .. '  ' .. name .. '+' .. dataEasy.getAttrValueString(data["attrType" .. i], data["attrNum" .. i])
			else
				txt2 = name .. '+' .. dataEasy.getAttrValueString(data["attrType" .. i], data["attrNum" .. i])
			end
		else
			break
		end
	end

	local itemTxt = node.panelLab:clone():show()
	local richText = rich.createWithWidth(color .. txt1 .. txt2 .. color, 40, cc.size(700,50), 700, 0)
		:anchorPoint(0, 1)
	itemTxt:height(richText:height())
	richText:addTo(itemTxt)
		:y(richText:height())
		:z(2)

	node.list:pushBackCustomItem(itemTxt)
end

function GemDetailsView:createSmallPanel(param, dbid)
	local pos = param.pos
	local align = param.align == 'left' and 'right' or 'left'
	local x
	local width = self.panel:size().width
	if align == 'left' then
		x = pos.x - width / 2
	else
		x = pos.x + width / 2
	end
	local p = self:getResourceNode():convertToNodeSpace(cc.p(x, 0))
	local smallPanel = self.panel:clone():addTo(self:getResourceNode(), 100)
	smallPanel:x(p.x)
	self:initPanel(smallPanel, dbid, gGameModel.gems:find(dbid):read('level'))
	smallPanel:get('bg'):height(900)
	smallPanel:get('intensify'):visible(false)
	smallPanel:get('inlay'):visible(false)
	local size = smallPanel:size()
	ccui.ImageView:create("city/card/helditem/bag/icon_cd.png")
		:align(cc.p(0.5, 0.5), 30, size.height - 40)
		:addTo(smallPanel:get('icon'), 9999, "isEquiped")
		:xy(150, 150)
end

--强化
function GemDetailsView:intensifyFunc( ... )
	gGameUI:stackUI('city.card.gem.strengthen', nil, nil, self.dbid)
end

--镶嵌
function GemDetailsView:inlayFunc( ... )
	if self.unEquip then
		local cardID = self.cardID
		local slotIdx = self.slotIdx
		self:onClose()
		GemTools.unEquipGem(cardID, slotIdx)
		return
	end
	local gems = gGameModel.cards:find(self.cardID):read('gems')
	local flag = gems[self.slotIdx]
	local cardID = self.cardID
	local slotIdx = self.slotIdx
	local dbid = self.dbid
	self:onClose()
	if flag then
		GemTools.swapGem(cardID, slotIdx, dbid)
	else
		GemTools.equipGem(cardID, slotIdx, dbid)
	end
end

--关闭页签是销毁外围引用数据
function GemDetailsView:onCleanup()
	self:addCallbackOnExit(self.cb)
	ViewBase.onCleanup(self)
end

return GemDetailsView