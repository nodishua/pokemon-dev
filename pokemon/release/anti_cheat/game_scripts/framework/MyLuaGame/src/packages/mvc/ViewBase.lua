--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2017 TianJi Information Technology Inc.
--
-- 一个UI工程对应一个ViewBase
--

local InitStepTotal = 6
local CreateStackDeep = 0 -- TODO: some viewbase create in onCreate, how to rebuild?

local ViewBase = class("ViewBase", cc.Node)

local function printViewDebug(fmt, view, ...)
	if DEBUG < 2 then return end

	local s = tostring(view)
	local notExtend = s:match("ccui.") == nil
	if notExtend then
		printDebug(fmt, s, ...)
	end
end

local function getViewCreateTrace(level)
	return getCallTrace(level, function(tb)
		local pos = tb.source:find("/app/views/")
		return pos
	end)
end

-- @param parent: parent only be saved, no addChild
function ViewBase:ctor(app, parent, handlers)
	self.app_ = app
	self.parent_ = parent -- parent ViewBase
	self.inited_ = 0
	if device.platform == "windows" then
		self.from_ = getViewCreateTrace().desc
	end

	if handlers then
		for k, v in pairs(handlers) do
			if type(v) ~= "table" or v.__handler ~= true then
				error(string.format("%s is not handler, %s, please use ViewBase:createHandler", k, v))
			end
			self[k] = v
		end
	end

	-- check CSB resource file
	local res = self.__class and rawget(self.__class, "RESOURCE_FILENAME")
	if res then
		self:createResourceNode(res)
	end

	-- bind
	local binding = self.__class and rawget(self.__class, "RESOURCE_BINDING")
	if res and binding then
		self.deferBinds_ = {}
		self:createResourceBinding(binding)
	end

	self:enableNodeEvents()
	-- if onUpdate be implement in derived class, enable it auto
	if self.onUpdate then
		self:enableUpdate()
	end
end


-- NOTICE
-- idler objects need be created in View:onCreate or listview asyncload
-- if idler be created outside, it will leak and would be error when callback
function ViewBase:init(...)
	if self.parent_ and self.parent_.rebuiltIniting_ and not self.rebuiltIniting_ then
		-- may be child init in rebuilding parent's init
		self.initArgs_ = functools.args(...)
		self.parent_.rebuilt_[self] = true
		return self:beginRebuild()
	end

	self.inited_ = 1
	idlersystem.onViewBaseCreateBegin(self)

	-- avoid incomplete args when the nil arg fill in
	self.initArgs_ = functools.args(...)

	-- check args
	-- when ViewBase rebuild:
	-- callback may be contain upvalue which reference with released cc.Node
	-- idler may be no trigger any more
	if device.platform == "windows" then
		for i = 1, self.initArgs_:size() do
			local varg = self.initArgs_:at(i)
			if type(varg) ~= "table" or varg.__handler ~= true then
				assert(not isIdler(varg), "idler could not be onCreate's arg, it will be lost when ViewBase rebuild, use ViewBase:createHandler reimplement")
				assert(type(varg) ~= "function", "function could not be onCreate's arg, it will be problem when ViewBase rebuild, use ViewBase:createHandler replace")
			end
		end
	end

	self:onCreate_(...)
	self.inited_ = 4

	if self.rebuilding_ then
		self:onRebuild(self.parent_)
	end
	self.inited_ = 5

	idlersystem.onViewBaseCreateEnd(self)
	self.inited_ = InitStepTotal
	return self
end

function ViewBase:isRebuilding()
	return self.rebuilding_
end

function ViewBase:beginRebuild()
	-- print('!!! ViewBase:beginRebuild', self, self.RESOURCE_FILENAME)

	self.rebuilding_ = true
	self.rebuilt_ = {}
	self.rebuiltIniting_ = true

	self:ctor(self.app_, self.parent_)

	-- xpcall avoid error in init, will block other view
	local status, msg = xpcall(function()
		self:init(self.initArgs_:unpack())
	end, function(...)
		self.rebuiltIniting_ = false
		__G__TRACKBACK__(...)
	end)

	self.rebuiltIniting_ = false
	if not status then
		printError('beginRebuild error %s %s', status, msg)
		self.rebuilding_ = false
		return
	end

	-- rebuild childs
	for _, child in pairs(self:getChildren()) do
		if child.beginRebuild then
			if not self.rebuilt_[child] then
				self.rebuilt_[child] = true
				child:beginRebuild()
			end
		end
	end

	return self
end

function ViewBase:endRebuild()
	-- print('!!! ViewBase:endRebuild', self, self.RESOURCE_FILENAME)

	-- rebuild childs
	for _, child in pairs(self:getChildren()) do
		if child.endRebuild then
			child:endRebuild()
		end
	end

	self.rebuilding_ = nil
	self.rebuilt_ = nil
	self.rebuiltIniting_ = nil

	return self
end

function ViewBase:tearDown()
	-- print('!!! ViewBase:tearDown', self)

	-- tearDown childs
	if self.resourceNode_ then
		self.resourceNode_:removeSelf()
		self.resourceNode_ = nil
	end
	for _, child in pairs(self:getChildren()) do
		if child.tearDown then
			-- print('child', self, child:name(), child)
			child:tearDown()
		else
			child:removeSelf()
		end
	end
end

function ViewBase:getApp()
	return self.app_
end

function ViewBase:getResourceNode(path)
	if path then
		return nodetools.get(self.resourceNode_, path)
	else
		return self.resourceNode_
	end
end

function ViewBase:createHandler(name, ...)
	local val = self[name]
	if type(val) == "function" then
		local method = self.__class[name]
		assert(type(method) == "function", "ViewBase:createHandler() - not such method in class")
		local vargs = functools.args(...)
		return functools.tablefunc({__handler=true}, function(t, ...)
			if tolua.isnull(self) then
				return
			end

			local method = self.__class[name]
			assert(type(method) == "function", "ViewBase:createHandler() - not such method in class")
			if vargs:size() == 0 then
				return method(self, ...)
			else
				local vargs2 = vargs + functools.args(...)
				return method(self, vargs2:unpack())
			end
		end)

	else
		return functools.tablefunc({__handler=true}, function()
			return self[name]
		end)
	end
end

function ViewBase:createResourceNode(resourceFilename)
	if self.resourceNode_ then
		self.resourceNode_:removeSelf()
		self.resourceNode_ = nil
	end
	self.resource_ = resourceFilename
	self.resourceNode_ = cache.createWidget(resourceFilename)
	self:addChild(self.resourceNode_)
end

function ViewBase:createResourceBinding(binding)
	assert(self.resourceNode_, "ViewBase:createResourceBinding() - not load resource node")
	bindUI(self, self.resourceNode_, binding)
end

function ViewBase:deferUntilCreated(f)
	-- created and defer run over
	if self.deferBinds_ == nil then
		return f()
	end
	return table.insert(self.deferBinds_, f)
end

function ViewBase:enableUpdate()
	if self.updating_ then return end
	self.updating_ = true
	self:scheduleUpdate(function(...)
		-- 不能作为闭包缓存onUpdate_，可能会有component重载
		return self:onUpdate_(...)
	end)
end

function ViewBase:disableUpdate()
	self.updating_ = false
	self:unscheduleUpdate()
end

function ViewBase:isUpdateEnabled()
	return self.updating_ or false
end

function ViewBase:onCreate_(...)
	-- local ProFi = require '3rd.profi'
	-- ProFi:start()

	self._cbsOnExit = {}

	local st = os.clock()
	printViewDebug('ViewBase:onCreate_ start %s', self)

	if self.onCreate then
		CreateStackDeep = CreateStackDeep + 1
		self:onCreate(...)
		CreateStackDeep = CreateStackDeep - 1
	end
	self.inited_ = 2

	-- 延迟绑定
	if self.deferBinds_ then
		local binds = self.deferBinds_
		self.deferBinds_ = nil
		for _, f in pairs(binds) do
			f()
		end
	end
	self.inited_ = 3

	printViewDebug('ViewBase:onCreate_ end %s %s', self, os.clock() - st)

	-- ProFi:stop()
	-- ProFi:writeReport( self.__class.__cname.."_20190103_1032.txt" )


	return self
end

function ViewBase:onUpdate_(delta)
	if self.updating_ and self.onUpdate then
		return self:onUpdate(delta)
	end
end

function ViewBase:assertInited()
	local s
	if self.inited_ == 0 then
		s = string.format("%s(%s), if you want removeSelf in onCreate, plz try performWithDelay or you not init() when create", tj.type(self), self:name())
	elseif self.inited_ < InitStepTotal then
		s = string.format("%s(%s), may be error in init(), it would cause next other error, inited=%d", tj.type(self), self:name(), self.inited_)
	end

	if s then
		performWithDelay(gGameUI.scene, function ()
			errorInWindows(s)
		end, 0)
	end
end

function ViewBase:onExit()
	printViewDebug('ViewBase:onExit %s', self)

	self:assertInited()

	-- clear dirty call
	self.app_.ui:delViewDelayCall(self)

	self:disableUpdate()
	-- clear components
	local names = table.keys(cc.components(self))
	if #names > 0 then
		cc.unbind(self, unpack(names))
	end
	return cc.Node.onExit(self)
end

function ViewBase:onCleanup()
	-- NOTE: widget内部node会有两次cleanup消息，一次是Node，一次是ProtectedNode
	printViewDebug('ViewBase:onCleanup %s %s %s', self, self.__inject, self:getName())

	idlersystem.onViewBaseCleanup(self)
	return cc.Node.onCleanup(self)
end

function ViewBase:onClose()
	printViewDebug('ViewBase:onClose %s', self)

	self:delayCallOnExit()
	self:removeSelf()
end

function ViewBase:onRebuild(parent)
end

function ViewBase:onBeforeChildViewCreate(name, handlers)
	if not self.rebuilding_ then return end

	-- call from GameUI:stackUI or View:onCreate
	local view = self:getChildByName(name)
	-- print('!!! onBeforeChildViewCreate', self, name, view)

	if view then
		if not self.rebuilt_[view] then
			view:ctor(self.app_, self, handlers)
		end
		self.rebuilt_[view] = true
	end
	return view
end

function ViewBase:onStackHide(skipHash)
	if self.stackShows_ ~= nil then return end
	skipHash = skipHash or {}
	self.stackShows_ = {}
	for _, child in pairs(self:getChildren()) do
		if child:isVisible() then
			self.stackShows_[child] = true
		end
		-- skip child in current node path
		if not skipHash[child] then
			child:hide()
		end
	end
end

function ViewBase:onStackShow()
	if self.stackShows_ == nil then return end
	local stackShows_ = self.stackShows_
	self.stackShows_ = nil
	for _, child in pairs(self:getChildren()) do
		if stackShows_[child] then
			child:show()
		end
	end
end


function ViewBase:addCallbackOnExit(cb, front)
	if cb == nil then return self end
	assert(self._cbsOnExit, string.format("%s ViewBase add callback after exited", tostring(self)))
	if front then
		table.insert(self._cbsOnExit, 1, cb)
	else
		table.insert(self._cbsOnExit, cb)
	end
	return self
end

function ViewBase:delayCallOnExit()
	local cbs = self._cbsOnExit
	self._cbsOnExit = nil
	-- error if cbs == nil
	if cbs then
		if next(cbs) then
			performWithDelay(gGameUI.scene, function()
				for _, cb in ipairs(cbs) do
					cb()
				end
			end, 0)
		end
	else
		errorInWindows("ViewBase delayCallOnExit be call more then once or onCreate not be call")
	end
end

-- easy for bind.XXXX
-- view:bind("button_1"):touch(...):text(...)
function ViewBase:bindEasy(pathOrNode)
	local node = pathOrNode
	if type(pathOrNode) == "string" then
		node = nodetools.get(self.resourceNode_, path)
	end
	if node == nil then return end

	return functools.chaincall(bind, self, node)
end

-- easy for node listen idler
-- importance is when view close, auto unlisten idler
function ViewBase:nodeListenIdler(pathOrNode, pathOrIdler, f)
	local node = pathOrNode
	if type(pathOrNode) == "string" then
		node = nodetools.get(self.resourceNode_, path)
	end
	if node == nil then return end

	-- idler in ViewBase
	local idler = pathOrIdler
	if type(pathOrIdler) == "string" then
		idler = self[pathOrIdler]
	end
	if idler == nil then return end

	return node:listenIdler(idler, f)
end

-- auto gen components on-off
local supportComponents = {
	"schedule",
	"asyncload",
	"message",
}
for _, name in ipairs(supportComponents) do
	local capname = string.caption(name)
	-- enableSchedule()
	ViewBase[string.format("enable%s", capname)] = function(self)
		local components = cc.components(self)
		if not components[name] then
			cc.bind(self, name)
		end
		return self
	end

	-- disableSchedule()
	ViewBase[string.format("disable%s", capname)] = function(self)
		local components = cc.components(self)
		if components[name] then
			cc.unbind(self, name)
		end
		return self
	end

	-- isScheduleEnabled()
	ViewBase[string.format("is%sEnabled", capname)] = function(self)
		local components = cc.components(self)
		return components[name] ~= nil
	end
end

return ViewBase
