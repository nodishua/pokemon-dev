-- @date:   2019-8-21 10:43:59
-- @desc:   商店自动出售界面

local ViewBase = cc.load("mvc").ViewBase
local ShopAutoSellView = class("ShopAutoSellView", Dialog)

ShopAutoSellView.RESOURCE_FILENAME = "shop_sell.json"
ShopAutoSellView.RESOURCE_BINDING = {
	["title.btnClose"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")},
		}

	},
	["btnSell"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onCell")},
		}
	},
	["btnSell.textNote"] = {
		binds = {
			event = "effect",
			data = {glow = {color = ui.COLORS.GLOW.WHITE}}
		}
	},
	["cost.textCost"] = "textCost",
	["cost.imgIcon"] = "imgIcon",
	["cost.textNote"] = "textNote",
	["item"] = "item",
	["list"] = {
		varname = "list",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("itemDatas"),
				item = bindHelper.self("item"),
				onItem = function(list, node, k, v)
					bind.extend(list, node:get("panel"), {
						class = "icon_key",
						props = {
							data = {
								key = v.id,
								num = v.num,
							},
						}
					})
					local cfg = dataEasy.getCfgByKey(v.id)
					local label = beauty.singleTextLimitWord(cfg.name, {fontSize = 40}, {width = 240})
						:xy(125, 26)
						:addTo(node, 2)
					text.addEffect(label, {color = ui.COLORS.NORMAL.DEFAULT})
				end,
			},
		},
	},
	["maskPanel"] = "maskPanel",
}

function ShopAutoSellView:onCreate(sellDatas, cb)
	self.itemDatas = sellDatas
	self.cb = cb
	self.reward = {}
	local allNum = 0
	for i,v in ipairs(self.itemDatas) do
		local cfg = dataEasy.getCfgByKey(v.id)
		allNum = allNum + cfg.sellPrice * v.num
	end
	self.textCost:text(mathEasy.getShortNumber(allNum, 2))
	table.insert(self.reward, {'gold', allNum})
	adapt.oneLineCenterPos(cc.p(200, 30), {self.textNote, self.textCost, self.imgIcon}, cc.p(6, 0))

	local len = #self.itemDatas
	if len < 5 then
		local x, y = self.list:xy()
		local size = self.list:size()
		y = y + size.height / 2
		local margin = self.list:getItemsMargin()
		local width = self.item:size().width * len + (len - 1) * margin
		self.list:size(width, size.height)
		self.list:anchorPoint(0.5, 0.5)
		self.list:xy(display.sizeInView.width / 2, y)
	else
		uiEasy.setBottomMask(self.list, self.maskPanel, "x")
	end
	Dialog.onCreate(self)
end

function ShopAutoSellView:onCell()
	local params = {}
	for i,v in ipairs(self.itemDatas) do
		params[v.id] = v.num
	end
	local reward = self.reward
	ViewBase.onClose(self)
	gGameApp:requestServer("/game/role/item/sell", function()
		gGameUI:showGainDisplay(reward, {raw = false})
	end, params)
end

function ShopAutoSellView:onClose()
	self:addCallbackOnExit(self.cb)
	ViewBase.onClose(self)
end

return ShopAutoSellView