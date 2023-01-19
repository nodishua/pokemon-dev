local ChipRatePreview = class('ChipRatePreview', cc.load('mvc').ViewBase)
ChipRatePreview.RESOURCE_FILENAME = 'chip_rate_preview.json'
ChipRatePreview.RESOURCE_BINDING = {
	['list'] = 'list',
	['listLine'] = 'listLine',
	['listLine2'] = 'listLine2',
	['item'] = 'item',
	['subTitle'] = 'subTitle',
	['bgLayer'] = 'bg',
	["txtTip"] = 'txtTip',
}

ChipRatePreview.RESOURCE_STYLES = {
	blackLayer = true,
    clickClose = true,
    backGlass = true,
}

local GROUP_PRE = {
	{type = 12, key = 'item'},
	{type = 13, key = 'rmb'}
}

local icons = {
	normalItem = 'city/card/chip/img_d_1.png',
	rarityChip2 = 'city/card/chip/img_d_2.png',
	rarityChip3 = 'city/card/chip/img_d_3.png',
	rarityChip4 = 'city/card/chip/img_d_4.png',
	rarityChip5 = 'city/card/chip/img_d_5.png',
	rarityChip6 = 'city/card/chip/img_d_6.png',
}

local ChipQualityColors = {
	[0] = cc.c4b(255, 255, 255, 255),
	[2] = cc.c4b(145, 224, 177, 255),
	[3] = cc.c4b(139, 175, 223, 255),
	[4] = cc.c4b(203, 141, 221, 255),
	[5] = cc.c4b(235, 183, 41, 255),
	[6] = cc.c4b(243, 137, 91, 255),
}

function ChipRatePreview:onCreate()
	self.item:visible(false)
	self.subTitle:visible(false)
	self.list:setScrollBarEnabled(false)
	for _, v in pairs(GROUP_PRE) do
		for _, cfg in csvPairs(csv.draw_preview) do
			if cfg.type == v.type then
				self:addRateItems(cfg, v.key)
				break
			end
		end
	end

	self.txtTip:text(gLanguageCsv.chipRatePreviewTip)
end


function ChipRatePreview:addRateItems(cfg, key)
	local title = self.subTitle:clone()
	title:visible(true)
	title:get('textTitle'):text(gLanguageCsv[key..'DrawRate'])
	self.list:pushBackCustomItem(title)
	local subList
	local size = csvSize(cfg.desc)
	if size > 5 then
		subList = self.listLine2:clone()
	else
		subList = self.listLine:clone()
	end
	subList:visible(true):setScrollBarEnabled(false)
	self.list:pushBackCustomItem(subList)
	for _, v in orderCsvPairs(cfg.desc) do
		local item = self.item:clone()
		item:visible(true)
		subList:pushBackCustomItem(item)
		item:get('icon'):texture(icons[v[1]])
		item:get('name'):text(gLanguageCsv[v[1]])
		text.addEffect(item:get('name'), {outline = {color=ui.COLORS.NORMAL.BLACK, size=2}})
		item:get('rate'):text(v[2]..'%')
		local quality = tonumber(string.sub(v[1], -1)) or 0
		item:get('name'):setTextColor(ChipQualityColors[quality])
	end
	subList:setItemAlignCenter()
end

return ChipRatePreview