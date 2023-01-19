-- @date 2021-01-14
-- @desc kr外链弹窗

local GiftLinkView = class("GiftLinkView", cc.load("mvc").ViewBase)
GiftLinkView.RESOURCE_FILENAME = "kr_gift_link_view.json"
GiftLinkView.RESOURCE_BINDING = {
	["btn"] = {
		binds = {
			event = "touch",
			clicksafe = true,
			methods = {ended = bindHelper.self("oneOpenUrl")},
		},
	},
}
GiftLinkView.RESOURCE_STYLES = {
	full = true,
}

function GiftLinkView:onCreate()
	gGameUI.topuiManager:createView("default", self, {onClose = self:createHandler("onClose")})
		:init({title = ""})
end

function GiftLinkView:oneOpenUrl()
	local url = "https://play.google.com/store/apps/details?id=com.xp.kefu.google"
	cc.Application:getInstance():openURL(url)
end

return GiftLinkView