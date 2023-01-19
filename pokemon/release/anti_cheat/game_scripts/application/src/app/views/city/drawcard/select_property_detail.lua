-- @date:   2021-06-25
-- @desc:   属性英雄详情

local DrawcardPropertyDetailView = class("DrawcardPropertyDetailView", cc.load("mvc").ViewBase)

DrawcardPropertyDetailView.RESOURCE_FILENAME = "drawcard_property_detail.json"

DrawcardPropertyDetailView.RESOURCE_BINDING = {
	["previewPanel"] = "previewPanel",
	["subList"] = "subList",
	["icon"] = "icon",
	["previewPanel.img1"] = "img",
	["previewPanel.list"] = {
		varname = "list",
		binds = {
			event = "extend",
			class = "tableview",
			props = {
				data = bindHelper.self("showDatas"),
				columnSize = bindHelper.self("midColumnSize"),
				item = bindHelper.self("subList"),
				cell = bindHelper.self("icon"),
				leftPadding = 0,
				topPadding = 15,
				xMargin = 30,
				yMargin = 0,
				asyncPreload = 12,
				onCell = function(list, node, k, v)
				bind.extend(list, node, {
					class =  "icon_key",
					props = {
						data = v,
					},
				})
				node:scale(0.8)
				local upIcon = cc.Sprite:create("city/drawcard/draw/txt_up.png")
										upIcon:addTo(node)
											:xy(cc.p(node:size().width-30,node:size().height))
											:z(5)
				bind.touch(list, node, {methods = {ended = functools.partial(list.clickCell, node, k, v)}})
				end,
			},
		},
	}
}

function DrawcardPropertyDetailView:onCreate(data)
	local localData = {}
	for k,v in pairs(data) do
		table.insert(localData,
			{num = v, key = "card"}
		)
	end
	local  scale = math.ceil(table.getn(data) / 3)
	self.img:height(scale * 185 - (scale-2) * 14)

	self.midColumnSize = 3
	self.showDatas = idlers.new()
	self.showDatas:update(localData)

end

return DrawcardPropertyDetailView