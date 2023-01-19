local ChipTools = require('app.views.city.card.chip.tools')

local RESONANCE_TYPE =
{
	[1] = {
		name = gLanguageCsv.chipResonanceDetail03,
		getStrFunc= function(index,param, str)
			str = "        "..string.format(gLanguageCsv.chipResonanceDetail01, index, param[1], ui.QUALITYCOLOR[param[2]], gLanguageCsv[ui.QUALITY_COLOR_TEXT[param[2]]], str)
			return str
		end
	},
	[2] = {
		name = gLanguageCsv.chipResonanceDetail04,
		getStrFunc= function(index, param, str)
			str = "        "..string.format(gLanguageCsv.chipResonanceDetail02,index, param[1], param[2],str)
			return str
		end
	}
}


local ChipResonancePreviewView = class("ChipResonancePreviewView", Dialog)

ChipResonancePreviewView.RESOURCE_FILENAME = "chip_resonance_detail.json"
ChipResonancePreviewView.RESOURCE_BINDING = {
	['btnClose'] ={
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self('onClose')}
		}
	},
	["list"] = "list",
}

function ChipResonancePreviewView:onCreate()
	local strs = {}
	table.insert(strs, "")
	for typ, group in pairs(gChipResonanceCsv) do
		if RESONANCE_TYPE[typ] then
			table.insert(strs, RESONANCE_TYPE[typ].name)
			for _, datas in pairs(group) do

				-- datas 数据无法更改，导致排序失败，通过list转换，排序
				local list = {}
				for index, data in ipairs(datas) do
					table.insert(list, data )
				end
				table.sort(list, function(v1, v2) return v1.priority < v2.priority end)

				for i, cfg in ipairs(list) do
					local attrs = {}
					for index = 1, math.huge do
						local key = cfg["attrType"..index]
						if key and key ~= 0 then
							local str = dataEasy.getAttrValueString(key, cfg["attrNum"..index])
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
					local str = ""
					for index, data in ipairs(attrs) do
						local name = ChipTools.getAttrName(data.key)
						str = str .. string.format("#C0x5B545B##F36#%s#C0x5C9970##F44#+%s",name, data.val)
						if attrs[index + 1] then
							str = str.."#C0x5B545B##F36#, "
						end

					end

					str = RESONANCE_TYPE[typ].getStrFunc(i, cfg.param, str)

					table.insert(strs, str)
				end
			end
			table.insert(strs, "")
		end
	end

	beauty.textScroll({
		list = self.list,
		strs = strs,
		isRich = true,
	})

	Dialog.onCreate(self)
end


return ChipResonancePreviewView