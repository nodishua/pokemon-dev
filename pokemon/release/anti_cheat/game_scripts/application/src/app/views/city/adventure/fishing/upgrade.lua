-- @Date: 2020-07-22
-- @Desc: 钓鱼升级
local ViewBase = cc.load("mvc").ViewBase
local FishingUpgradeView = class("FishingUpgradeView", ViewBase)

FishingUpgradeView.RESOURCE_FILENAME = "fishing_upgrade.json"
FishingUpgradeView.RESOURCE_BINDING = {
	["back"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")},
		},
	},
	["top"] = {
		varname = "imgInfo",
		binds = {
			event = "extend",
			class = "text_atlas",
			props = {
				data = bindHelper.self("fishLevel"),
				align = "center",
				pathName = "lv_big",
				isEqualDist = false,
				onNode = function(panel)
					panel:xy(415, 200)
				end,
			}
		}
	},
}

function FishingUpgradeView:onCreate(cb)
	self.cb = cb
	audio.playEffectWithWeekBGM("role_levelup.mp3")
	self:initModel()

	local fishLevel = self.fishLevel:read()

	-- 升级特效
	local pnode = self.imgInfo
	local size = pnode:size()

	local effect = CSprite.new("level/jiesuanshengli.skel")		-- 文字部分特效
	effect:addTo(pnode, 1)
	effect:setAnchorPoint(cc.p(0.5, 0.5))
	effect:xy(pnode:width()/2 + 15, -345)
	effect:play("shengji_loop")
end

function FishingUpgradeView:initModel()
	self.fishLevel = gGameModel.fishing:getIdler("level")
end

function FishingUpgradeView:onClose()
	self:addCallbackOnExit(self.cb)
	ViewBase.onClose(self)
end

return FishingUpgradeView
