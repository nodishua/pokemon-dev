--
--@data 2019-8-8 20:49:11
--desc 神秘商店出现界面
--

local ViewBase = cc.load("mvc").ViewBase
local MysteryShopShowView = class("MysteryShopShowView", ViewBase)

MysteryShopShowView.RESOURCE_FILENAME = "mystery_shop_show.json"
MysteryShopShowView.RESOURCE_BINDING = {
	["closePanel"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")},
		},
	},
}

function MysteryShopShowView:onCreate(params)
	gGameUI:disableTouchDispatch(0.5)
end

function MysteryShopShowView:onClose()
	ViewBase.onClose(self)
end

return MysteryShopShowView