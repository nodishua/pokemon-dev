--符石品质指数
local QualityIndexView = class("QualityIndexView", Dialog)

QualityIndexView.RESOURCE_FILENAME = "gem_index.json"
QualityIndexView.RESOURCE_BINDING = {
	["btnClose"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")}
		}
	},
	["item"] = "item",
	["list"] = {
		varname = "list",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("qualityDatas"),
				item = bindHelper.self("item"),
				itemAction = {isAction = true},
				onItem = function(list, node, k, v)
					node:get("name"):text(v.name)
					node:get("name"):x(0)
					local width = list:width() - node:get("name"):width()
					local richText = rich.createWithWidth(v.txt, 40, nil, width)
						:anchorPoint(0, 1)

					richText:xy(node:get("name"):x() + node:get("name"):width(), richText:height())
						:addTo(node)
						:z(2)
					node:height(richText:height())
					node:get('name'):y(node:height())
					local color = v.selfct and cc.c4b(91, 84, 91, 255) or cc.c4b(183, 176, 158, 255)
					text.addEffect(node:get("name"), {color = color})
				end,
			},
		}
	},
	["index"] = "index",
}

function QualityIndexView:onCreate(dbidId, index)
	self.list:y(348)
		:height(622)
		:setItemsMargin(13)
	local index = index or 0
	self.index:text(index)
	local cardId = gGameModel.cards:find(dbidId):read("card_id")
	local qualityId = csv.cards[cardId].gemQualitySeqID
	local qualityData = {}
	self.qualityDatas = idlers.new({})
	local color1, color2 = "#C0x5B545B#", "#C0x60c456#"
	local gemSelect = true
	for k,v in orderCsvPairs(csv.gem.quality_attrs) do
		if qualityId == v.gemQualitySeqID then
			if v.qualityNum > index then
				color1 = "#C0xB7B09E#"
				color2 = "#C0xB7B09E#"
				gemSelect = false
			else
				gemSelect = true
			end
			local txt1 = string.format(gLanguageCsv.indexNumEffect, v.qualityNum)
			local txt2 = ''
			local arrData = {}
			for i = 1, math.huge do
				if v['attrType'..i] and v['attrType'..i] ~= 0 then
					local attrTypeStr = game.ATTRDEF_TABLE[v["attrType"..i]]
					local name = gLanguageCsv.card..color1..gLanguageCsv["attr"..string.caption(attrTypeStr)]
					if matchLanguage({"en"}) then
						name = color1..gLanguageCsv["attr"..string.caption(attrTypeStr)]
					end
					if i >= 2 then
						txt2 = txt2..', '..name..color2..'+'..dataEasy.getAttrValueString(v['attrType'..i] ,v["attrNum"..i])..color2..color1
					else
						txt2 = txt2..name..color2..'+'..dataEasy.getAttrValueString(v['attrType'..i] ,v["attrNum"..i])..color2..color1
					end
					arrData[i] = dataEasy.getAttrValueString(v['attrType'..i] ,v["attrNum"..i])
				else
					break
				end
			end

			local arr = arrData[1]
			local arrInfo = true
			--如果6个属性加成一样简化
			if #arrData == 6 then
				for k,v in pairs(arrData) do
					if v ~= arr then
						arrInfo = false
					end
				end
				if arrInfo then
					txt2 =  gLanguageCsv.card..gLanguageCsv.basicAttribute..color2..'+'..arr
					if matchLanguage({"en"}) then
						txt2 =  gLanguageCsv.basicAttribute..color2..'+'..arr
					end
				end
			end
			table.insert(qualityData, {name = txt1, txt = color1..txt2, selfct = gemSelect})
		end
	end

	self.qualityDatas:update(qualityData)
	self.item:visible(false)

	Dialog.onCreate(self)
end

return QualityIndexView