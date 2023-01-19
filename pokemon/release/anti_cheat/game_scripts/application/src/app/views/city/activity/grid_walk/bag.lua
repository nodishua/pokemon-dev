-- @date 2021-03-16
-- @desc 走格子-背包界面

local gridWalkTools = require "app.views.city.activity.grid_walk.tools"
local ViewBase = cc.load("mvc").ViewBase
local GridWalkBagView = class("GridWalkBagView", ViewBase)
GridWalkBagView.RESOURCE_FILENAME = "grid_walk_bag.json"
GridWalkBagView.RESOURCE_BINDING = {
	["closePanel"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")},
		},
	},
	["item"] = "item",
	["bgPanel.bg"] = "bg",
	["bgPanel.empty"] = "empty",
	["bgPanel.list"] = {
		varname = "list",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("itemDatas"),
				item = bindHelper.self("item"),
				onItem = function(list, node, k, v)
					local childs = node:multiget("icon", "txt")
					local str = beauty.singleTextLimitWord(v.name, {fontSize = childs.txt:getFontSize()}, {width = 240, onlyText = true})
					childs.txt:text(str)
					local binds = {
						class = "icon_key",
						props = {
							data = {
								key = v.key,
								num = v.val,
							},
						},
					}
					bind.extend(list, childs.icon, binds)
				end,
				onAfterBuild = function(list)
					list:setItemAlignCenter()
					list.afterBuild()
				end,
			},
			handlers = {
				afterBuild = bindHelper.self("onAfterBuild"),
			},
		},
	}
}

function GridWalkBagView:onCreate()
	self.itemDatas = idlers.new()
	local data = {}
	local isEmpty = true
	for k, itemID in pairs(gridWalkTools.CARDSBAG_ID) do
		local cfg = dataEasy.getCfgByKey(itemID)
		local val = dataEasy.getNumByKey(itemID)
		if val > 0 then
			table.insert(data, {key = itemID, val = val, name = cfg.name})
			isEmpty = false
		end
	end
	if isEmpty then
		self.empty:show()
	else
		self.itemDatas:update(data)
	end
end

function GridWalkBagView:onAfterBuild()
	local listWidth = self.list:width()
	if listWidth > 0 then
		self.bg:width(listWidth + 70)
	end
end

return GridWalkBagView