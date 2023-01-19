-- @date: 2020-03-19
-- @desc:成就弹窗

local AchievementTipView = class("AchievementTipView", cc.load("mvc").ViewBase)
AchievementTipView.RESOURCE_FILENAME = "common_achievement_tip.json"
AchievementTipView.RESOURCE_BINDING = {
	["panel"] = "panel",
	["panel.bg"] = "bg",
	["panel.text1"] = {
		varname = "text1",
		binds = {
			event = "effect",
			data = {outline = {color = cc.c4b(224, 106, 85, 255)}},
		},
	},
	["panel.text2"] = {
		varname = "text2",
		binds = {
			event = "effect",
			data = {outline = {color = cc.c4b(224, 106, 85, 255)}},
		},
	},
	["panel.text3"] = {
		varname = "text3",
		binds = {
			event = "effect",
			data = {outline = {color = cc.c4b(201, 140, 60, 255)}},
		},
	},
	["panel.icon"] = "icon",
}
function AchievementTipView:onCreate(csvId, cfg)
	self.csvId = csvId
	local iconPath = csv.achievement.achievement[cfg.type].icon
	self.icon:texture(icon)
	self.text2:text(cfg.title)
	self.text3:text(cfg.point)

	local delay1 = 3 -- 停留时间
	local delay2 = 2
	local x, y = self:xy()
	-- 动画效果
	transition.executeSequence(self.panel)
		:delay(delay1)
		:moveBy(delay2, 0, 100)
		:func(functools.partial(self.onClose, self))
		:done()

	transition.executeSequence(self.icon):delay(delay1):fadeOut(delay2):done()
	transition.executeSequence(self.bg):delay(delay1):fadeOut(delay2):done()
	transition.executeSequence(self.text1):delay(delay1):fadeOut(delay2):done()
	transition.executeSequence(self.text2):delay(delay1):fadeOut(delay2):done()
	transition.executeSequence(self.text3):delay(delay1):fadeOut(delay2):done()

	-- self.panel:setTouchEnabled(true)
	-- bind.touch(self, self.panel, {methods = {ended = function()
	-- 		local inGuiding, guideId = gGameUI.guideManager:isInGuiding()
	-- 		if inGuiding then
	-- 			return
	-- 		end
	-- 		local _, viewName = gGameUI:getTopStackUI()
	-- 		if viewName == "city.achievement" then
	-- 			return
	-- 		end
	-- 		gGameUI:stackUI("city.achievement", nil, {full = true})
	-- 	end}})
	if self.text2:width() > self.text1:width() then
		adapt.oneLinePos(self.text2, self.icon, cc.p(20, 15),"right")
		adapt.oneLinePos(self.text2, self.text3, cc.p(60, 0),"left")
	else
		adapt.oneLinePos(self.text1, self.icon, cc.p(20, 15),"right")
		adapt.oneLinePos(self.text1, self.text3, cc.p(60, 0), "left")
	end
	self.bg:x(self.text3:x() - 265)
	self.text3:y(self.bg:y())
end

function AchievementTipView:onClose()
	self.panel:stopAllActions()
	-- 只是显示内容，不需要用 onClose，直接移出
	self:removeSelf()
end

function AchievementTipView:onMoveUp()
	local h = self.panel:size().height + 20
	local x, y = self:xy()
	transition.executeSequence(self)
		:moveTo(0.3, x, y + h)
		:done()
end

return AchievementTipView
