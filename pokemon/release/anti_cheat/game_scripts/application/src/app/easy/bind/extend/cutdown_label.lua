-- 通用倒计时设置

local helper = require "easy.bind.helper"

local cutDownLabel = class("cutDownLabel", cc.load('mvc').ViewBase)

cutDownLabel.defaultProps = {
	time = nil,
	-- 倒计时总时间
	endTime = nil,
	-- 倒计时结束时间，通过结束时间和当前时间只差来计算倒计时。
	-- 赋值endtime的情况下，不用赋值time
	callFunc = nil,
	-- 每次计时count时执行，改函数返回false中断倒计时
	endFunc = nil,
	-- 倒计时结束时执行
	str_key = 'str',
	-- 倒计时文本的键值，
	-- 'str' 'clock_str' 'short_clock_str' 'daystr' 'hourstr' 'minstr' 'secstr' 'date_str' 'short_date_str' 'head_date_str'
	-- 详情参见time.lua time.getCutDown
	fontSize = nil,
	-- 文本size
	strFunc = nil,
	-- 自定义的倒计时文本函数
	delay = 0,
	-- 倒计时延时，一般都为0
	dt = 1,
	-- 倒计时刷新间隔，一般设定为1秒
	tag = nil,
	-- 倒计时tag
	textColor = nil,
	-- 倒计时文本颜色
}

function cutDownLabel:initExtend()
	if self.fontSize then
		self:setFontSize(self.fontSize)
	end
	if self.textColor then
		self:setTextColor(self.textColor)
	end
	self:enableSchedule()

	if self.onNode then
		self.onNode(self)
	end
	if self:setLabel(0) ~= false then
		self:schedule(function(dt)
			return self:setLabel(dt)
		end, self.dt, self.dt + self.delay, self.tag)
	end
end

function cutDownLabel:setLabel(dt)
	local t
	if self.time then
		self.time = self.time - dt
		t = self.time
	elseif self.endTime then
		t = self.endTime - time.getTime()
	end
	t = math.max(t, 0)
	local timeTbl = time.getCutDown(t)
	if self.strFunc then
		self:text(self.strFunc(timeTbl))
	else
		self:text(timeTbl[self.str_key])
	end
	if t <= 0 then
		if self.endFunc then
			self.endFunc()
		end
		return false
	end
	if self.callFunc then
		local ret = self.callFunc(timeTbl)
		if ret == false then
			return false
		end
	end
end

return cutDownLabel