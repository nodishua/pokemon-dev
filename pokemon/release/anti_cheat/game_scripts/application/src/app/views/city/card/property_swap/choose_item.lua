local PropertySwapView = require("app.views.city.card.property_swap.view")

local PropertySwapChooseView = class("PropertySwapChooseView", Dialog)
local SWAP_TYPE = PropertySwapView.SWAP_TYPE

PropertySwapChooseView.RESOURCE_FILENAME = "card_property_swap_choose_item.json"
PropertySwapChooseView.RESOURCE_BINDING = {
	["item"] = "item",
	["subList"] = "subList",
	["list"] = {
		varname = "cardList",
		binds = {
			event = "extend",
			class = "tableview",
			props = {
				data = bindHelper.self("itemDatas"),
				columnSize = 6,
				item = bindHelper.self("subList"),
				cell = bindHelper.self("item"),
				dataOrderCmpGen = bindHelper.self("onSortCardList", true),	--排序
				onCell = function(list, node, k, v)
					local children = node:multiget("icon", "name")

					bind.extend(list, children.icon, {
						class = "icon_key",
						props = {
							data = {
								key = v.key,
								num = v.num,
							},
							noListener = true,
							onNode = function(panel)
								panel:setTouchEnabled(false)
							end,
						}
					})
					children.name:text(v.name)
					bind.touch(list, node, {methods = { ended = functools.partial(list.itemClick, node, k, v)}})
				end,
				asyncPreload = 24,
			},
			handlers = {
				itemClick = bindHelper.self("onItemChoose"),
			},
		},
	},
	["btnClose"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")}
		}
	},
	["empty"] = "empty",
}

-- @param params 依次为继承类型(idler)，继承精灵dbid，被继承精灵dbid(idler)
function PropertySwapChooseView:onCreate(showTab, selectDbId, cb)
	self.cb = cb
	self.itemDatas = idlers.new()--卡牌数据
	self.showTab = showTab
	local itemDatas = {}
	local isNature = showTab == SWAP_TYPE.NATURE -- 是性格页面
	local isNvalue = showTab == SWAP_TYPE.NVALUE -- 是个体值页面
	local isEffort = showTab == SWAP_TYPE.EFFORTVALUE -- 是努力值页面
	for itemId, cfg in csvPairs(csv.items) do
		if cfg.specialArgsMap.character then
			local num = dataEasy.getNumByKey(itemId)
			if num > 0 then
				table.insert(itemDatas, {key = itemId, num = num, name = cfg.name})
			end
		end
	end
	self.empty:setVisible(#itemDatas <= 0)
	self.itemDatas:update(itemDatas)

	Dialog.onCreate(self)
end

function PropertySwapChooseView:onItemChoose(list, node, k, v)
	self.cb(nil, v.key)
	self:onClose()
end

function PropertySwapChooseView:onSortCardList(list)
	return function(a, b)
		return tonumber(a.key) < tonumber(b.key)
	end
end

return PropertySwapChooseView
