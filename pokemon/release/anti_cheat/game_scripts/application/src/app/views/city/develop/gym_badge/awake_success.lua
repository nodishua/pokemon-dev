local BASE_TIME = 0.08
local gymBadgeAwakeSuccessView = class("gymBadgeAwakeSuccessView", cc.load("mvc").ViewBase)

gymBadgeAwakeSuccessView.RESOURCE_FILENAME = "gym_badge_awake_success.json"
gymBadgeAwakeSuccessView.RESOURCE_BINDING = {
	["bg"] = {
		binds = {
			event = "click",
			method = bindHelper.self("onClose")
		}
	},
	["item"] = "item",
	["topList"] = "topList",
	["leftPanel"] = "leftPanel",
	["rightPanel"] = "rightPanel",
	-- ["leftTxt"] = "leftTxt",
	-- ["rightTxt"] = "rightTxt",
	["arrow"] = "arrow",
	["leftName"] = "leftName",
	["rightName"] = "rightName",
}

function gymBadgeAwakeSuccessView:playEffect(name)
	local pnode = self:getResourceNode()
	-- 结算特效
	local textEffect = CSprite.new("level/jiesuanshengli.skel")		-- 文字部分特效
	textEffect:addTo(pnode, 100)
	textEffect:setAnchorPoint(cc.p(0.5,0.5))
	textEffect:setPosition(pnode:get("title"):getPosition())
	textEffect:visible(true)
	-- 播放结算特效
	textEffect:play("xjiesuan_juexingzi")
	textEffect:addPlay("xjiesuan_juexingzi")
	textEffect:retain()

	local bgEffect = CSprite.new("level/jiesuanshengli.skel")		-- 底部特效
	bgEffect:addTo(pnode, 99)
	bgEffect:setAnchorPoint(cc.p(0.5,0.5))
	bgEffect:setPosition(pnode:get("title"):getPosition())
	bgEffect:visible(true)
	-- 播放结算特效
	bgEffect:play("jiesuan_shenglitu")
	bgEffect:addPlay("jiesuan_shenglitu_loop")
	bgEffect:retain()
end

function gymBadgeAwakeSuccessView:onCreate(data)
	local awake = data.awake
	local nextEffStrs = data.nextEffStrs
	local badgeNumb = data.badgeNumb
	local csvBadge = csv.gym_badge.badge
	local icon = csvBadge[badgeNumb].icon
	local name = csvBadge[badgeNumb].name
	self.leftPanel:get("icon"):texture(icon)
	self.rightPanel:get("icon"):texture(icon)
	self.leftName:text(name.."+"..awake)
	self.rightName:text(name.."+"..(awake + 1))
	beauty.textScroll({
		list = self.topList,
		effect = {color=ui.COLORS.NORMAL.DEFAULT},
		strs = nextEffStrs,
		isRich = true,
		margin = 20,
		align = "left",
	})
	self:playEffect("jihuo")


	uiEasy.setExecuteSequence(self.leftPanel, {delayTime = BASE_TIME})
	uiEasy.setExecuteSequence(self.leftName, {delayTime = BASE_TIME * 2})
	-- uiEasy.setExecuteSequence(self.leftTxt, {delayTime = BASE_TIME * 3})
	uiEasy.setExecuteSequence(self.arrow, {delayTime = BASE_TIME * 2})
	uiEasy.setExecuteSequence(self.rightPanel, {delayTime = BASE_TIME * 4})
	uiEasy.setExecuteSequence(self.rightName, {delayTime = BASE_TIME * 5})
	-- uiEasy.setExecuteSequence(self.rightTxt, {delayTime = BASE_TIME * 6})

	-- gGameUI:disableTouchDispatch(1 + BASE_TIME * 18)
end


return gymBadgeAwakeSuccessView
