--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2017 TianJi Information Technology Inc.
--
-- AsyncLoading 异步加载相关
-- 使用协程
--

local AsyncLoading = class("AsyncLoading")

local EXPORTED_METHODS = {
	"asyncFor",
	"overFor",
	"pauseFor",
	"resumeFor",
	"quickFor",
	"isPreloadOK",
	"preloadOverFor",
}

function AsyncLoading:init_()
	self.loading = false
	self.pause = false
	self.data = nil
	self.skip = 0
end

function AsyncLoading:bind(target)
	self:init_()
	cc.setmethods(target, self, EXPORTED_METHODS)
	target:enableUpdate()
	self.target_ = target
	self.update_ = callbacks.new(target.onUpdate_, functools.partial(self.onAsyncUpdate_, self))
	target.onUpdate_ = self.update_
end

function AsyncLoading:unbind(target)
	if self.loading and self.data.cb_over then
		self.data.cb_over()
	end
	cc.unsetmethods(target, EXPORTED_METHODS)
	self:init_()
	self.update_:remove()
	-- target.onUpdate_ = self.oldUpdate_
end

-- cb_over避免涉及view相关操作
function AsyncLoading:asyncFor(cb_start, cb_over, preload, cb_preload_over)
	if self.loading then
		-- 一个view只能一个async在工作
		self:overFor()
	end
	local co = coroutine.create(function ()
		xpcall(cb_start, __G__TRACKBACK__)
	end)
	self.skip = 0
	self.data = {co = co, cb_over = cb_over, cb_preload = nil, preload = preload or 0, cb_preload_over = cb_preload_over, skip = (preload ~= nil)}
	self.pause = false
	self.loading = true
end

function AsyncLoading:onAsyncUpdate_()
	local v = self.data
	if v == nil then return end
	if not self.target_:isVisibleInGlobal() then return end
	if self.pause and v.preload <= 0 then return end
	if self.skip > 0 then
		self.skip = self.skip - 1
		return
	end


	local first = true
	while v.preload > 0 or first do
		idlersystem.onViewBaseCoroutineBegin(self.target_)
		local ret, err = coroutine.resume(v.co)
		idlersystem.onViewBaseCoroutineEnd(self.target_)
		if ret == nil or ret == false then
			self:overFor()
			break
		end
		v.preload = v.preload - 1
		first = false
		if v.preload <= 0 then
			if v.skip then
				-- may be all of the lost frames were cost in coroutine
				self.skip = math.max(10, 60 - display.director:getFrameRate())
				-- self.skip = 0
			end
		end
	end

	if v.cb_preload_over and v.preload <= 0 then
		v.cb_preload_over()
		v.cb_preload_over = nil
	end
end

function AsyncLoading:overFor()
	if self.loading then
		local v = self.data
		self.loading = false
		self.data = nil
		if v and v.cb_preload_over then
			v.cb_preload_over()
		end
		if v and v.cb_over then
			v.cb_over()
		end
	end
end

function AsyncLoading:pauseFor()
	self.pause = true
end

function AsyncLoading:resumeFor()
	self.pause = false
end

function AsyncLoading:quickFor(mode)
	local v = self.data
	if v == nil then return end

	self.skip = 0
	v.skip = false
	if mode == "sync" then
		v.preload = 999999
	end
end

function AsyncLoading:isPreloadOK()
	return self.data.preload <= 0
end

function AsyncLoading:preloadOverFor(cb_preload_over)
	if self.data == nil or self.data.preload <= 0 then
		if self.data == nil then
			printError('!!! 检查弹框创建是否在协程创建之前')
		end
		cb_preload_over()
	else
		self.data.cb_preload_over = cb_preload_over
	end
end

return AsyncLoading