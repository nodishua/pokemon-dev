-- @date:   2020-03-16
-- @desc:   公会战预告界面

local UnionFightCloseView = class("UnionFightCloseView", cc.load("mvc").ViewBase)

UnionFightCloseView.RESOURCE_FILENAME = "union_fight_closed_view.json"
UnionFightCloseView.RESOURCE_BINDING = {
	["note"] = {
		binds = {
			event = "effect",
			data = {outline = {color = cc.c4b(82, 48, 28, 255), size = 6}},
		},
	},
	["text"] = {
		varname = "text",
		binds = {
			event = "effect",
			data = {outline = {color = cc.c4b(82, 48, 28, 255), size = 6}},
		},
	},
}

function UnionFightCloseView:onCreate(refreshHandle)
	self.refreshHandle = refreshHandle
	self:initSpine()
	self:startTimeLabel()
end

function UnionFightCloseView:initSpine()
	local spinePath = "union_fight/gonghuizhanjiemian.skel"
	local node = self:getResourceNode()
	local ani = widget.addAnimationByKey(node, spinePath, "main_ani", nil, 98)
		:alignCenter(node:size())
		:scale(2)
end

function UnionFightCloseView:startTimeLabel()
	-- 选择最接近的时间 周二至周六 每天早上9：30
	local nowTime = time.getNowDate()
	local nowTimestamp = time.getTimestamp(nowTime)

	local wday1 = time.getWeekStrInClock() -- 本周周一日期
	local hour, min = dataEasy.getTimeStrByKey("unionFight", "signUpStart", true)
	local targetTimestamp = time.getNumTimestamp(wday1, hour, min)
	targetTimestamp = targetTimestamp + 24 * 3600 -- 本周周二早上9：30
	if targetTimestamp < nowTimestamp then -- 当前不在周二
		targetTimestamp = targetTimestamp + 24 * 3600 * 7 -- 下周周二早上9：30
	end
	local timestamp = targetTimestamp - nowTimestamp

	if timestamp < 0 then
		timestamp = timestamp + 24 * 3600
	end

	local tag = 03031825
	local delay = 1 -- 固定时间刷新一次(秒)
	self:enableSchedule():unSchedule(tag)
	self:enableSchedule()
		:schedule(function(dt)
			local cd = time.getCutDown(timestamp)
			self.text:text(cd.str)
			if timestamp <= 0 then
				self.refreshHandle()
				timestamp = 2
				-- self:enableSchedule():unSchedule(tag)
			end
			timestamp = timestamp - 1
		end, delay, 0, tag)
end

return UnionFightCloseView