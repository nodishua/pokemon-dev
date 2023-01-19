--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2017 TianJi Information Technology Inc.
--

-- schedule 定时器相关

local Schedule = class("Schedule")

local EXPORTED_METHODS = {
	"schedule",
	"unSchedule",
	"unScheduleAll",
}

function Schedule:init_()
	self.scheduleIdx = -1 --默认从-1开始 -2 -3...
	self.scheduleCbMap = {} --所有schedule 都缓存在这里
	self.scheduleCbOrder = nil --schedule有序化, nil为dirty
end

function Schedule:bind(target)
	self:init_()
	cc.setmethods(target, self, EXPORTED_METHODS)
	target:enableUpdate()
	self.target_ = target
	self.update_ = callbacks.new(target.onUpdate_, functools.partial(self.onScheduleUpdate_, self))
	target.onUpdate_ = self.update_
end

function Schedule:unbind(target)
	cc.unsetmethods(target, EXPORTED_METHODS)
	self:init_()
	self.update_:remove()
end

-- 一帧最多回调一次
function Schedule:schedule(cb, dt, delay, tag)
	return self:_schedule(tag, {
		cb = cb,
		dt = dt,
		delay = delay or 0,
	})
end

function Schedule:_schedule(tag, info)
	if tag == nil then
		tag = self.scheduleIdx
		self.scheduleIdx = self.scheduleIdx - 1
	end
	--@param cb  回调函数
	--@param dt   间隔多少时间执行回调 单位 秒
	--@param delay 下次距离执行回调还有多久 单位 秒
	--@param fixed 固定dt进行回调，否则一帧最多回调一次
	--已经存在的直接覆盖
	self.scheduleCbMap[tag] = info
	self.scheduleCbOrder = nil
	return tag
end

function Schedule:unSchedule(tag, docb)
	if docb and self.scheduleCbMap[tag] then
		self.scheduleCbMap[tag].cb(0)
	end
	self.scheduleCbMap[tag] = nil
	self.scheduleCbOrder = nil
end

function Schedule:unScheduleAll()
	self.scheduleCbMap = {}
	self.scheduleCbOrder = nil
end

function Schedule:onScheduleUpdate_(target, delta)
	if self.scheduleCbOrder == nil or #self.scheduleCbOrder == 0 then
		-- 保证tag是递增的
		local sorted = {}
		for k,v in pairs(self.scheduleCbMap) do
			table.insert(sorted, {tag = k, str = tostring(k)})
		end
		table.sort(sorted, function(a, b)
			return a.str < b.str
		end)
		self.scheduleCbOrder = {}
		for _, data in ipairs(sorted) do
			table.insert(self.scheduleCbOrder, data.tag)
		end
	end

	gGameApp:onViewSchedule(target)
	local over = 0
	for _, tag in ipairs(self.scheduleCbOrder) do
		local v = self.scheduleCbMap[tag]
		-- v.cb可能导致后续的schedule被清理
		if v then
			--确保要在下一帧才开始执行v.cb,因为有些cdx对象初始化后当帧拿到的数据还没刷新
			if v.delay < 0 then
				local ret = v.cb(v.dt)
				--函数内部返回false 代表此schedule结束
				if ret == false then
					self.scheduleCbMap[tag] = nil
					over = over + 1
				else
					v.delay = v.dt + v.delay
				end
			end
			v.delay = v.delay - delta
		end
	end
	if over > 0 then
		self.scheduleCbOrder = nil
	end
	gGameApp:onViewSchedule(nil)
end


return Schedule
