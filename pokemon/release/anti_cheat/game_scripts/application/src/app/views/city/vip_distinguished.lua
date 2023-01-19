
-- desc 尊贵vip奖励弹窗
local VipDistinguishedView = class("VipDistinguishedView", Dialog)

VipDistinguishedView.RESOURCE_FILENAME = "vip_distinguished.json"
VipDistinguishedView.RESOURCE_BINDING = {
	["title.btnClose"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")}
		},
	},
	["btnSell"] = {
		varname = "btnSell",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("btnSellClick")}
		},
	},
	["list"] = "list",
	["text1"] = "text1",
	["text2"] = "text2",
}

function VipDistinguishedView:onCreate(cb)
	self.roleVip = gGameModel.monthly_record:read("vip")
	local vipState = gGameModel.monthly_record:read("vip_gift")
	self.cb = cb
	self.isHas = true

	local id, state = csvNext(vipState)
	if state and state == 0 then
		uiEasy.setBtnShader(self.btnSell, false, 2)
		self.btnSell:get("textNote"):text(gLanguageCsv.received)
	end
	self.text1:text(gLanguageCsv.giftsHint1)
	self.text2:text(gLanguageCsv.giftsHint2)
	if matchLanguage({"en"}) then
		adapt.setTextAdaptWithSize(self.text1, {size = cc.size(960, 200), vertical = "center", horizontal = "center", margin = -5, maxLine= 2})
		self.text2:setPositionY(885)
	end

	uiEasy.createItemsToList(self, self.list, gVipCsv[self.roleVip].monthGift, {margin = 40, onAfterBuild = function(list)
			list:setItemAlignCenter()
		end,})

	Dialog.onCreate(self)
end

function VipDistinguishedView:btnSellClick()
	gGameApp:requestServer("/game/role/vip/month/gift", function(tb)
		self.isHas = false
		gGameUI:showGainDisplay(tb.view, {raw = false, cb = function()
				uiEasy.setBtnShader(self.btnSell, false, 2)
				self.btnSell:get("textNote"):text(gLanguageCsv.received)
			end})
	end)

end

function VipDistinguishedView:onClose()
	if self.cb then
		self.cb(self.isHas)
	end
	Dialog.onClose(self)
end

return VipDistinguishedView