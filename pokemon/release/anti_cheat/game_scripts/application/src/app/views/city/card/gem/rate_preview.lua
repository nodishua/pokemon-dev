local GemRatePreview = class('GemRatePreview', cc.load('mvc').ViewBase)
GemRatePreview.RESOURCE_FILENAME = 'gem_rate_preview.json'
GemRatePreview.RESOURCE_BINDING = {
	['list'] = 'list',
	['listLine'] = 'listLine',
	['listLine2'] = 'listLine2',
	['item'] = 'item',
	['subTitle'] = 'subTitle',
	['bgLayer'] = 'bg'
}

local cfgs = {
	{type = 9, key = 'gold'},
	{type = 10, key = 'rmb'}
}

local icons = {
	normalItem = 'city/card/gem/img_hs.png',
	rarityGem2 = 'city/card/gem/img_green.png',
	rarityGem3 = 'city/card/gem/img_blue.png',
	rarityGem4 = 'city/card/gem/img_purple.png',
	rarityGem5 = 'city/card/gem/img_yellow.png',
	rarityGem6 = 'city/card/gem/img_red.png',
}

local gemQualityColors = {
	[0] = cc.c4b(255, 255, 255, 255),
	[2] = cc.c4b(145, 224, 177, 255),
	[3] = cc.c4b(139, 175, 223, 255),
	[4] = cc.c4b(203, 141, 221, 255),
	[5] = cc.c4b(235, 183, 41, 255),
	[6] = cc.c4b(243, 137, 91, 255),
}

function GemRatePreview:onCreate()
	widget.addAnimationByKey(self.bg, 'fushichouqu/ryl.skel', "effectBg", "effect_loop", -1)
		:alignCenter(self.bg:size())
	self.bg:scale(2)
	self.item:visible(false)
	self.subTitle:visible(false)
	self.list:setScrollBarEnabled(false)
	for _, v in pairs(cfgs) do
		for _, cfg in csvPairs(csv.draw_preview) do
			if cfg.type == v.type then
				self:addRateItems(cfg, v.key)
				break
			end
		end
	end
end

GemRatePreview.RESOURCE_STYLES = {
	full = true,
}

function GemRatePreview:addRateItems(cfg, key)
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
		item:get('name'):setTextColor(gemQualityColors[quality])
	end
	subList:setItemAlignCenter()
end

return GemRatePreview