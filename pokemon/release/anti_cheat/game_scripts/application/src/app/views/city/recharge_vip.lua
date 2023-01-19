-- desc 尊贵vip弹窗
local RechargeVipView = class("RechargeVipView", Dialog)

RechargeVipView.RESOURCE_FILENAME = "recharge_vip.json"
RechargeVipView.RESOURCE_BINDING = {
	["btnClose"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")}
		},
	},
	["btnGo"] = {
		varname = "btnGo",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onGoClick")}
		},
	},
	["icon"] = {
		varname = "icon",
		binds = {
			{
				event = "touch",
				methods = {ended = bindHelper.self("onIconClick")}
			},
			{
				event = "extend",
				class = "red_hint",
				props = {
					specialTag = "onHonourableVip",
					onNode = function(node)
						node:xy(70, 65)
							:scale(0.3)
					end,
				}
			}
		}
	},
	["list"] = "list",
	["animation"] = "animation",
	["name"] = "name",
}

function RechargeVipView:onCreate()
	-- self.btnGo:hide() -- 策划要求，暂时先隐藏
	Dialog.onCreate(self, {clickClose = false})
	local size = self.btnGo:size()
	widget.addAnimationByKey(self.btnGo, "effect/jiantou.skel", "efc1", "effect_loop", 6)
		:xy(size.width / 2 - 60 + 20, size.height / 2)
	uiEasy.createItemsToList(self, self.list, csv.gift[100].award, { margin = 40})

	local roleVip = gGameModel.monthly_record:read("vip")
	if csvSize(gVipCsv[roleVip].monthGift) >= 1 then
		self:animationUpdata(true)
	else
		self:boxState(false)
	end

end

function RechargeVipView:onGoClick()
	cc.Application:getInstance():openURL("https://url.cn/5Ucln3U?_type=wpa&qidian=true")
end

function RechargeVipView:animationUpdata(isHas)
	if isHas then
		local vipState = gGameModel.monthly_record:read("vip_gift")
		local key, state = csvNext(vipState)
		if not state or state ~= 0 then
			widget.addAnimation(self.animation, "effect/jiedianjiangli.skel", "effect_loop", 1)
				:xy(100, 40)
				:scale(0.7)
			self:boxState(true)
		else
			self:boxState(false)
		end
	else
		self.animation:removeAllChildren()
		self:boxState(false)
	end
end

-- isHas为ture表示可以领取
function RechargeVipView:boxState(isHas)
	local str = isHas and "config/item/box/icon_fslh_2_5.png" or "city/recharge/icon_vip_gbbz.png"
	local scale = isHas and 3 or 1
	self.name:visible(isHas)
	self.icon:setEnabled(isHas)
	self.icon:scale(scale)
	self.icon:texture(str)
end

function RechargeVipView:onIconClick()
	gGameUI:stackUI("city.vip_distinguished", nil, nil, self:createHandler("animationUpdata"))
end

return RechargeVipView

