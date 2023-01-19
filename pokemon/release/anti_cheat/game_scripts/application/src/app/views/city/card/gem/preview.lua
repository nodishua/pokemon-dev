local function setEscInfo(list, node, k, v)
	local binds = {
		class = "listview",
		props = {
			data = v,
			item = list.itemCell,
			onItem = function(innerList, cell, kk ,vv)
				local childs = cell:multiget("textName","textVal")
				childs.textName:text(gLanguageCsv[vv.items[1]])
				childs.textVal:text(vv.items[2] .. "%")
				adapt.oneLinePos(childs.textName, childs.textVal, cc.p(10, 0), "left")
			end,
		},
	}
	bind.extend(list, node, binds)
end

local GemDrawPreview = class('GemDrawPreview', cc.load('mvc').ViewBase)
GemDrawPreview.RESOURCE_FILENAME = 'gem_preview.json'
GemDrawPreview.RESOURCE_BINDING = {
	["item"] = "item",
	["item1"] = "itemUpCell",
	["item2"] = "itemDwonCell",
	["item21"] = "itemDwonChildCell",
	['list'] = {
		varname = "list",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data              = bindHelper.self("showData"),
				item              = bindHelper.self("item"),
				itemUpCell        = bindHelper.self("itemUpCell"),
				itemDwonCell      = bindHelper.self("itemDwonCell"),
				itemDwonChildCell = bindHelper.self("itemDwonChildCell"),
				itemAction        = {isAction = true},
				asyncPreload      = 6,
				onItem = function(list, node, k, v)
					local childs = node:multiget("upList","downList")

					if v[1].key then
						childs.downList:visible(false)
						childs.upList:visible(true)

						local listW = list:size().width
						local itemSize = childs.upList:size()
						node:size(cc.size(listW, itemSize.height))

						local binds = {
							class = "listview",
							props = {
								data = v,
								item = list.itemUpCell,
								onItem = function(innerList, cell, kk ,vv)

									bind.extend(innerList, cell, {
										class = 'icon_key',
										props = {
											data = {
												key = vv.key,
											},
											specialKey = {
												leftTopLv = 1
											}
										}
									})
									if vv.info == 2 then
										local upIcon = cc.Sprite:create("city/drawcard/draw/txt_up.png")
										upIcon:addTo(cell)
											:xy(cc.p(cell:size().width-40,cell:size().height-17))
											:z(5)
									end
								end
							}
						}
						bind.extend(list, childs.upList, binds)

					else
						childs.downList:visible(true)
						childs.upList:visible(false)

						local binds = {
							class = "listview",
							props = {
								data = v,
								item = list.itemDwonCell,
								itemCell = list.itemDwonChildCell,
								onItem = function(innerList, cell, kk ,vv)
									setEscInfo(innerList, cell, kk, vv)
								end
							}
						}
						bind.extend(list, childs.downList:get("list"), binds)
					end
				end
			}
		}
	}
}

function GemDrawPreview:onCreate(activityID)
	self.showData = idlers.new()

	local up = 1
	local datas, dataEsc= {}, {}
	local gemData = csv.gem.gem

	local gemUp = csv.yunying.yyhuodong[activityID].clientParam.up
	local gemUpValueList = {}
	for _, v in ipairs(gemUp) do
		gemUpValueList[v] = true
	end

	local id = csv.yunying.yyhuodong[activityID].clientParam.priviewId
	local previewData = csv.draw_preview[id]

	for _, data in ipairs(previewData.item) do
		up = 1
		local id = gemData[data].suitID
		if id and gemUpValueList[id] then
			up = 2
		end

		if datas[up] == nil then
			datas[up] = {}
		end
		table.insert(datas[up], {key = data, quality = dataEasy.getCfgByKey(data).quality, info = up})
	end

	local func = function(list)
		table.sort(list, function(a, b)
			if a.quality ~= b.quality then
				return a.quality > b.quality
			end
			return a.key < b.key
		end)
	end

	for index, list in pairs(datas) do
		func(list)
	end

	local datas = self:setStructData(datas)

	if previewData.desc and csvSize(previewData.desc) then
		for i,v1 in ipairs(previewData.desc) do
			table.insert(dataEsc, {type = "desc", items = v1})
		end
	end

	local dataEsc = self:setStructEscData(dataEsc)

	table.insert(datas, dataEsc)

	self.showData:update(datas)
end

function GemDrawPreview:setStructData(rlist)
	local newDatas = {}
	local count = 1
	local item= {}

	for index, list in pairs(rlist) do
		for index, val in pairs(list) do
			if count%9 == 1 then
				if count > 9 then
					table.insert(newDatas, item)
				end
				item = {}
			end

			table.insert(item,val)
			count = count + 1
		end
	end

	if #item >0 then
		table.insert(newDatas, item)
	end
	return newDatas
end

function GemDrawPreview:setStructEscData(rlist)
	local newDatas = {}
	local count = 1
	local item= {}

	for index, val in pairs(rlist) do
		if count%4 == 1 then
			if count > 4 then
				table.insert(newDatas, item)
			end
			item = {}
		end

		table.insert(item,val)
		count = count + 1
	end

	if #item >0 then
		table.insert(newDatas, item)
	end
	return newDatas
end

return GemDrawPreview