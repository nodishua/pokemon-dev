-- @date 2021-07-06
-- @desc 夏日商店

local BaseShopView = require "app.views.city.activity.coupon_shop"
local SummerShopView = class("SummerShopView", BaseShopView)
SummerShopView.RESOURCE_FILENAME = "summer_shop.json"
SummerShopView.RESOURCE_BINDING = BaseShopView.RESOURCE_BINDING

function SummerShopView:initData()
	self.itemID = 6394

end

function SummerShopView:initTitle()
	gGameUI.topuiManager:createView("title", self, {onClose = self:createHandler("onClose")})
		:init({title = gLanguageCsv.summerShop, subTitle = "QUALIFIED SHOP"})
end

return SummerShopView