
--符石详情界面
local GemDetailsView = class("GemDetailsView", cc.load("mvc").ViewBase)
local GemTools = require('app.views.city.card.gem.tools')

GemDetailsView.RESOURCE_FILENAME = "common_gem_details.json"
GemDetailsView.RESOURCE_BINDING = {
	["baseNode.inlay"] = {
		varname = "inlay",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("inlayFunc")},
		}
	},
	["baseNode.bg"] = {
		varname = "bg",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")},
		}
	},
	["baseNode.confirm"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("confirmClick")},
		}
	},
	["baseNode.confirm.text"] = {
		varname = "confirmText",
		binds = {
			event = "effect",
			data = {glow = {color = ui.COLORS.GLOW.WHITE}},
		}
	},
	["baseNode"] = "baseNode",
	["baseNode.icon"] = "icon",
	["baseNode.quality"] = "quality",
	["baseNode.list"] = "list",
	["baseNode.txt"] = "txt",
	["baseNode.name"] = "name",
	["baseNode.panelLab"] = "panelLab",
	["baseNode.property"] = "property",
	["baseNode.quile"] = "quile",
	["baseNode.item"] = "item",
}

function GemDetailsView:onCreate(param, cb)
	local id, level
	local gem = gGameModel.gems:find(param.dbId)
	self.dbid = param.dbId
	self.dissatisfy = param.dissatisfy
	id = gem:read('gem_id')
	level = gem:read('level')
	self.cb = cb
	local data = {}
	local cfg = dataEasy.getCfgByKey(id)
	self.item:visible(false)
	local quality = cfg.quality
	local qualityTxt = "qualityNum"..quality
	self.quality:text(csv.gem.quality[level][qualityTxt])
	self.name:text(cfg.name)
	text.addEffect(self.name, {color=ui.COLORS.QUALITY_DARK[quality]})

	if csv.gem.gem[id] then
		self.property:text(csv.gem.gem[id].gemDescribe)
	else
		self.property:visible(false)
		self.quile:y(self.property:y())
		self.quality:y(self.property:y())
	end


	local str = gLanguageCsv.gemPlac
	local pos = param.pos
	local p = self:getResourceNode():convertToNodeSpace(cc.p(pos.x, 0))
	local x, y = p.x+ 35, pos.y - 85
	if param.align == 'left' then
		str = gLanguageCsv.discharge
		y = pos.y + 65
	end
	self.confirmText:text(str)
	self.baseNode:xy(x, y)
	self.align = param.align

	self.list:setScrollBarEnabled(false)
	bind.extend(self, self.icon, {
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
		if cfg['attrType'.. i] and cfg['attrType' .. i] ~= 0 and cfg['attrNum' .. i] and cfg['attrNum' .. i][level] then
			local attrKey = game.ATTRDEF_TABLE[cfg['attrType'..i]]
			attrKey = 'attr' .. attrKey:gsub("^%l", string.upper)
			local item = self.txt:clone()
			item:get("txt"):text(gLanguageCsv[attrKey])
			item:get("number"):text('+' .. dataEasy.getAttrValueString(cfg["attrType" .. i], cfg['attrNum' .. i][level]))
			item:get("number"):x(item:get("txt"):width()+10)
			dataEasy.tryCallFunc(self.list, "updatePreloadCenterIndex")
			self.list:pushBackCustomItem(item)
		else
			break
		end
	end

	--套装属性
	local suitID = csv.gem.gem[id].suitID
	local data = gGemSuitCsv[suitID] and gGemSuitCsv[suitID][quality]
	local color = "#C0xB7B09E#"
	if data then
		local item = self.item:clone():show()
		self.list:pushBackCustomItem(item)

		for i=1,9 do
			if data[i] then
				local txt1 = string.format(gLanguageCsv.numSuit, data[i].suitNum)
				txt1 = data[i].suitName .. string.format("%s(%s)%s", txt1, gLanguageCsv[ui.QUALITY_COLOR_TEXT[quality]], gLanguageCsv.symbolColon)
				local txt2
				for k = 1, math.huge do
					if data[i]["attrType" .. k] and data[i]["attrType" .. k] ~= 0 then
						local attrTypeStr = game.ATTRDEF_TABLE[data[i]["attrType" .. k]]
						local name = gLanguageCsv["attr"..string.caption(attrTypeStr)]
						if txt2 then
							txt2 = txt2 .. '  ' .. name .. '+' .. dataEasy.getAttrValueString(data[i]["attrType" .. k], data[i]["attrNum" .. k])
						else
							txt2 = name .. '+' .. dataEasy.getAttrValueString(data[i]["attrType" .. k], data[i]["attrNum" .. k])
						end
					else
						break
					end
				end

				local itemTxt = self.panelLab:clone():show()
				local richText = rich.createWithWidth(color .. txt1 .. txt2 .. color, 40, cc.size(700,90), 700, 0)
					:anchorPoint(0, 1)
				itemTxt:height(richText:height())
				richText:addTo(itemTxt)
					:y(itemTxt:height())
					:z(2)
				self.list:pushBackCustomItem(itemTxt)
			end
		end
	end
	self.txt:visible(false)
	self.panelLab:visible(false)
end

function GemDetailsView:confirmClick()
	if not self.dissatisfy then
		gGameUI:showTip(gLanguageCsv.gemUpperLimit)
		return
	end
	if self.cb then
		self.cb(self.dbid, self.align)
	end
	self:onClose()
end

-- function GemDetailsView:onCleanup()
-- 	ViewBase.onCleanup(self)
-- end

return GemDetailsView