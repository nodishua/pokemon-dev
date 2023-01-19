--
-- @date 2019-7-19 12:12:11
-- @desc 属性详情界面
--

local NatureAttrInfoView = class("NatureAttrInfoView", Dialog)

NatureAttrInfoView.RESOURCE_FILENAME = "card_nature_attr.json"
NatureAttrInfoView.RESOURCE_BINDING = {
	["topList"] = "topList",
	["textNote2"] = "textNote2",
	["rightList"] = "rightList",
	["title.btnClose"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")}
		},
	},
	["item"] = "item",
	["curFlag"] = "curFlag",
	["list"] = {
		varname = "list",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("attrDatas"),
				item = bindHelper.self("curFlag"),
				natureTypes = bindHelper.self("natureTypes"),
				cell = bindHelper.self("item"),
				onItem = function(list, node, k, v)
					local key = v.key
					local attrKey = game.NATURE_ENUM_TABLE[key]
					node:get("imgIcon"):visible(itertools.include(list.natureTypes, attrKey))
					local data = {}
					for i,name in ipairs(game.NATURE_TABLE) do
						table.insert(data, v.data[name])
					end
					bind.extend(list, node:get("list"), {
						class = "listview",
						props = {
							data = data,
							item = list.cell,
							onItem = function(curlist, cell, _, vv)
								cell:get("textNote"):text(vv)
								local color = ui.COLORS.NORMAL.DEFAULT
								if vv > 1 then
									color = ui.COLORS.NORMAL.FRIEND_GREEN
								elseif vv < 1 then
									color = ui.COLORS.NORMAL.RED
								elseif vv == 0 then
									color = ui.COLORS.NORMAL.ALERT_ORANGE
								end
								text.addEffect(cell:get("textNote"), {color = color})
							end,
						}
					})
				end,
			},
		},
	},
}

function NatureAttrInfoView:onCreate(selectDbId)
	self.rightList:setScrollBarEnabled(false)
	self.topList:setScrollBarEnabled(false)
	adapt.setAutoText(self.textNote2,self.textNote2:text(), nil)
	local card = gGameModel.cards:find(selectDbId)
	self.cardId = card:read("card_id")
	local unitID = csv.cards[self.cardId].unitID
	local unit = csv.unit[unitID]
	self.natureTypes = {unit.natureType}
	if unit.natureType2 then
		table.insert(self.natureTypes, unit.natureType2)
	end
	self.attrDatas = idlers.newWithMap({})
	local t = {}
	for i,vals in orderCsvPairs(csv.base_attribute.nature_matrix) do
		table.insert(t, {key = game.NATURE_TABLE[i], data = vals})
	end
	self.attrDatas:update(t)

	Dialog.onCreate(self)
end

return NatureAttrInfoView