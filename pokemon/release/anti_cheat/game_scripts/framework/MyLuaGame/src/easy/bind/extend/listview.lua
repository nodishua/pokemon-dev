--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2017 TianJi Information Technology Inc.
--
-- ccui.ListView的react形式的扩展
--
local ListViewActionTag = 2010231611
local helper = require "easy.bind.helper"

local listview = class("listview", cc.load("mvc").ViewBase)

listview.defaultProps = {
	-- onXXXX 响应函数
	-- 数据 array table, function
	data = nil,
	-- 数据过滤 function
	dataFilter = nil,
	dataFilterGen = nil, -- return dataFilter
	-- 数据排序 function
	dataOrderCmp = nil,
	dataOrderCmpGen = nil, -- return dataOrderCmp
	-- 数量 nil 自动
	itemSize = nil,
	-- item模板
	item = nil,
	-- 间距，nil 不改变
	margin = nil,
	-- 起始和最后填充，nil 不改变
	padding = nil,
	-- 异步加载, nil 不使用异步加载, >=0 预加载数量
	asyncPreload = nil,

	enterCount = nil,
	-- 下次刷新以当前屏幕显示内容先刷新
	preloadCenterIndex = nil,
	preloadCenter = nil, -- key in data
	preloadBottom = false,
	backupCached = true, -- backupOrCleanItems_ will be enabled

	addLimit  = false,
	-- itemAction
	--   isAction:是否有动画
	--   actionTime(0.4):单个item移动表现时间
	--   duration(0.15): item出现间隔
	--   durationLimit(0.3):当前屏所有item出现间隔限定时长
	--   alwaysShow:是否数据变动刷新时再显示动画表现
	-- itemAction = nil,
	-- itemAction = {isAction = true, alwaysShow = true},
}

-- @return idler, val
local function getValue(idler)
	if isIdler(idler) then
		-- read() better than get_(), its read only
		-- idler may be had nest idler, so sad... get_() back
		return idler, idler:get_()
	end
	return nil, idler
end

function listview:filterSortData_()
	local data = self.data
	local filter = self.dataFilter
	local cmp = self.dataOrderCmp

	if self.dataFilterGen then
		filter = self.dataFilterGen()
		self.dataFilter = filter
	end
	if self.dataOrderCmpGen then
		cmp = self.dataOrderCmpGen()
		self.dataOrderCmp = cmp
	end

	if filter then
		data = itertools.filter(self.dataSource_, function(k, v)
			if isIdler(v) then v = v:get_() end
			return filter(k, v)
		end)
		self.data = data
	end

	if cmp then
		self.orderKeys_ = itertools.keys(data)
		table.sort(self.orderKeys_, function(k1, k2)
			local v1, v2 = data[k1], data[k2]
			if isIdler(v1) then v1 = v1:get_() end
			if isIdler(v2) then v2 = v2:get_() end
			return cmp(v1, v2)
		end)
		-- keyHash = {key in data: idx}
		self.keyHash_ = arraytools.hash(self.orderKeys_, true)
	else
		self.orderKeys_ = itertools.keys(data)
		table.sort(self.orderKeys_)
		self.keyHash_ = arraytools.hash(self.orderKeys_, true)
	end

	self.dirtySort_ = false

	-- print('!!! filterSortData_ end', #self.orderKeys_)
end

function listview:backupOrCleanItems_()
	-- no cache
	if not self.backupCached then
		for key, item in pairs(self.itemNodes_) do
			if item.listenerKey_ then
				item.listenerKey_:detach()
				item.listenerKey_ = nil
			end
			item.idler_ = nil
		end
		self.itemNodes_ = {}
		return
	end

	-- item.listenerKey_ also be saved durably, its used for reorder
	-- key is same, item also same in default
	self.backupItemNodes_ = self.backupItemNodes_ or {}
	for key, item in pairs(self.itemNodes_) do
		item:retain()
		local old = self.backupItemNodes_[key]
		if old and old ~= item then
			if old.listenerKey_ then
				old.listenerKey_:detach()
				old.listenerKey_ = nil
			end
			old.idler_ = nil
			old:autorelease()
			printWarn("duplicated key %s in listview %s %s", key, old, item)
		end
		self.backupItemNodes_[key] = item
	end
	self.itemNodes_ = {}
end

function listview:cleanBackupItems_()
	if self.backupItemNodes_ then
		for k, item in pairs(self.backupItemNodes_) do
			if item.listenerKey_ then
				item.listenerKey_:detach()
				item.listenerKey_ = nil
			end
			item.idler_ = nil
			item:autorelease()
			-- release lua object bind with ccui.layout
			tolua.setpeer(item, nil)
		end
		self.backupItemNodes_ = nil
	end
end

function listview:forceUpdate(autoFocus)
	if autoFocus then
		if self.preloadCenter then
			self.preloadCenter_ = isIdler(self.preloadCenter) and self.preloadCenter:read() or self.preloadCenter
		else
			self:updatePreloadCenterIndex()
			-- -- ListView::interceptTouchEvent will set the selected index
			-- local idx = self:getCurSelectedIndex()
			-- -- may be coroutine not finished, so idx not valid
			-- if idx >= 0 then
			-- 	local item = self:getItem(idx)
			-- 	local key = item.key_
			-- 	self.preloadCenter_ = key
			-- end
		end
	else
		self.preloadCenter_ = self.orderKeys_[1] -- first
		self.preloadCenterIndex = nil
	end
	self:buildExtend()
end

-- @comment only support sort by manually
function listview:filterSortItems(autoFocus)
	autoFocus = (autoFocus == nil) and true or autoFocus

	local oldOrder = self.orderKeys_
	self:filterSortData_()
	if itertools.equal(oldOrder, self.orderKeys_) then
		return
	end

	self:forceUpdate(autoFocus)
end

-- @param {row, k} tableview 的行，列
function listview:initExtend(params)
	self.params = params
	if self.asyncPreload then
		self.enterCount = self.asyncPreload * 2
		self:enableAsyncload()
		-- may be covered by outside
		if not self.disableOnScroll then
			if self.addLimit then
				local direction = self:getDirection()
				local container = self:getInnerContainer()
				local listSize  = self:getContentSize()
				self:onScroll(function(event)
					local size = self:getInnerContainerSize()

					if direction == ccui.ListViewDirection.horizontal then
						local size = self:getInnerContainerSize()
						local x = container:getPositionX()
						local dot = size.width - listSize.width + x

						if dot < 100 or event.name == "SCROLL_TO_LEFT" then
							self.enterCount = self.enterCount + self.asyncPreload*2
							self:resumeFor()
							self:quickFor()
						end
					else

						local y = container:getPositionY()
						if y > -100 or event.name == "SCROLL_TO_TOP" then
							self.enterCount = self.enterCount + self.asyncPreload*2
							self:resumeFor()
							self:quickFor()
						end
					end
				end)
			else
				self:onScroll(function(event)
					if event.name == "SCROLL_TO_TOP" or event.name == "SCROLL_TO_BOTTOM" or event.name == "SCROLL_TO_LEFT" or event.name == "SCROLL_TO_RIGHT" then
						self:quickFor()
					end
				end)
			end
		end
	end
	if self.preloadCenter then
		self.preloadCenter_ = isIdler(self.preloadCenter) and self.preloadCenter:read() or self.preloadCenter
	end

	-- save original props
	self.containerSize = self:getContentSize()
	--self.rawData = self.data

	self:setRenderHint(1) -- 1D

	self.itemNodes_ = {}
	self.backupItemNodes_ = nil -- cache items
	self.dirtySort_ = false

	local data, idler, idlers = helper.dataOrIdler(self.data)
	self.data, self.dataSource_ = data, data
	if idlers then
		idlers:addListener(function(msg, idlers)
			-- print('!!! listview idlers msg', msg.event,self, self:getChildrenCount(),self.backupCached, dumps(msg))

			self.data = idlers:get_() -- reference it
			self.dataSource_ = self.data
			if msg.event == "init" then
				self:cleanDirtyNodes_()
				self:buildExtend()

			elseif msg.event == "add" then
				self.dirtySort_ = true
				if self.backupCached then
					self:filterSortItems()
				else
					-- TODO listview 构建数据才50个，但第100个数据发生变动直接设置会报错
					-- insert or append
					-- if order be disturbed, the behavior undefined
					self:makeItem(msg.key, msg.val, msg.idler)
				end

			elseif msg.event == "remove_all" then
				self:removeAllAndBackup()
				self:cleanDirtyNodes_()
				self.dirtySort_ = true

			elseif msg.event == "remove" then
				self.dirtySort_ = true
				if self.backupCached then
					self:filterSortItems()
				else
					local item = self.itemNodes_[msg.key]
					self.itemNodes_[msg.key] = nil
					if item then
						if item.listenerKey_ then
							item.listenerKey_:detach()
							item.listenerKey_ = nil
						end
						self:removeItem(self:getIndex(item))
					end
					-- keep relative order by outside
					-- if order be disturbed, the behavior undefined
				end

			elseif msg.event == "swap" then
				self.dirtySort_ = true
				local item1 = self.itemNodes_[msg.key1]
				local item2 = self.itemNodes_[msg.key2]
				if item1 and item2 then
					item1.key_, item2.key_ = msg.key2, msg.key1
					self.itemNodes_[msg.key1], self.itemNodes_[msg.key2] = item2, item1
					self:swapItem(self:getIndex(item1), self:getIndex(item2))
				else
					printWarn("swap item no exist %d %d, %s %s", msg.key1, msg.key2, tostring(item1), tostring(item2))
				end

			elseif msg.event == "update" then
				local item = self.itemNodes_[msg.key]
				if item and item.listenerKey_ == nil then
					self:onItemUpdate(item, msg.key, msg.idler:get_())
				end

			elseif msg.event == "refresh" then
				local iter
				if msg.keys then
					iter = itertools.iter(pairs(msg.keys))
				else
					if self.dirtySort_ then
						self:filterSortData_()
					end
					iter = itertools.iter(ipairs(self.orderKeys_))
				end
				itertools.each(iter, function(_, key)
					local item, idler = self.itemNodes_[key], self.data[key]
					self:onItemUpdate(item, key, idler:get_())
				end)
			end
		end)

	elseif idler then
		idler:addListener(function(data)
			self.data = data
			self.dataSource_ = data
			self:buildExtend()
		end)

	else
		self:buildExtend()
	end
	return self
end

-- init and filterSortItems will invoke buildExtend
-- but filterSortItems only adjust the order, no need clean dirty, it will be update by onItem
function listview:buildExtend()
	-- 默认不显示滑动条
	self:setScrollBarEnabled(false)

	-- 0: STENCIL 1: SCISSOR
	-- self:setClippingType(1) --不可见范围内的item做隐藏 renderTexture会出现问题先注掉
	-- self:setClippingEnabled(false)

	self:removeAllAndBackup()
	self:filterSortData_()

	local _, margin = getValue(self.margin)
	if margin then
		self:setItemsMargin(margin)
	end

	if self.padding then
		local width, height = self.containerSize.width, self.containerSize.height
		if self:getDirection() == ccui.ListViewDirection.horizontal then
			width = self.padding
		else
			height = self.padding
		end
		local panel = ccui.Layout:create():size(width, height)
		-- panel:setBackGroundColorType(1)
		-- panel:setBackGroundColor(cc.c3b(200, 0, 0))
		-- panel:setBackGroundColorOpacity(100)
		self:pushBackCustomItem(panel:clone())
		self:pushBackCustomItem(panel)
	end
	self.minPreloadIdx = nil

	if gGameUI.guideManager:isInGuiding() then
		self.itemAction = nil
	end
	self:onBeforeBuild()
	if self.asyncPreload then
		self:asyncFor(handler(self, "building"), nil, self.asyncPreload, handler(self, "resetItemAction"))
	else
		self:building()
		self:resetItemAction()
	end

	return self
end

function listview:building()
	-- local st = os.clock()

	self.itemSize = self.itemSize or 999999
	local iter
	local data, orderKeys = self.data, self.orderKeys_
	if self.preloadBottom then
		self.preloadCenterIndex = #orderKeys
	end
	self.preloadCenterPos = self.preloadCenterIndex or self.keyHash_[self.preloadCenter_]
	if self.preloadCenterPos then
		self.minPreloadIdx = nil
		iter = helper.extendDataIter(function(k, cnt)
			self.minPreloadIdx = math.min(self.minPreloadIdx or math.huge, k)
			return orderKeys[k], data[orderKeys[k]]
		end, itertools.size(self.orderKeys_), self.preloadCenterPos)
	else
		if self:getDirection() == ccui.ListViewDirection.horizontal then
			self:jumpToLeft()
		else
			self:jumpToTop()
		end
		local i = 0
		iter = function()
			i = i + 1
			if orderKeys[i] == nil then return end
			return orderKeys[i], data[orderKeys[i]]
		end
	end
	self.preloadCenterIndex = nil
	self.preloadCenter_ = nil -- no center any more, only in first show
	-- self.preloadBottom = nil -- no botoom any more, only in first show
	local preloadCenterIndexAdaptFirst_ = self.preloadCenterIndexAdaptFirst_
	self.preloadCenterIndexAdaptFirst_ = nil

	-- k is the key in data
	local cnt = 0
	itertools.each(iter, function(k, v)
		if cnt >= self.itemSize then return end
		cnt = cnt + 1
		local idler, v = getValue(v)
		local item = self:makeItem(k, v, idler)
		self:onItemAction(item, cnt, self.keyHash_[k])

		if cnt == 1 and self.preloadCenterPos then
			local idx = self.padding and 1 or 0
			self:setShowCenterIndex(idx)
			self:setCurSelectedIndex(idx)
			self:refreshView()
		end
		-- 加载 asyncPreload 后如果第1个加载了，显示到头位置
		if preloadCenterIndexAdaptFirst_ and self.asyncPreload == cnt and self.minPreloadIdx == 1 then
			self:setShowCenterIndex(-1)
		end
		-- print('iter', self, cnt, k, self:getShowCenterIndex())
		if self.asyncPreload then
			if self.addLimit then
				if cnt >= self.enterCount then
					self.pauseFor()
				end
			end

			coroutine.yield()
		end
	end)

	self:refreshView()
	self:cleanBackupItems_()
	self:setShowCenterIndex(-1)
	self:onAfterBuild_()

	-- print('------------ listview build end', #self.orderKeys_, #self:getItems())
	-- print('!!!listview over cost', self, os.clock()-st)
end

local function _reset(node, baseNode)
	if not node then
		return
	end

	-- node.copyProperties exported in new engine after 2020/01/19
	-- TODO: may be some properties be changed, be careful
	if false and node.copyProperties then
		node:copyProperties(baseNode)
	else
		node:xy(baseNode:x(), baseNode:y())
		node:scale(baseNode:scaleX(), baseNode:scaleY())
		node:visible(baseNode:visible())
	end
	for _, child in pairs(baseNode:getChildren()) do
		-- may be the child tag or name be changed
		_reset(node:get(child:name()), child)
	end
end

local function resetItem(node, baseNode)
	if baseNode == nil then return end
	-- print('!!! resetItem', self, node, k, tag, node:parent())

	-- cloned widget may be moved by insertCustomItem
	local parent = node:parent()
	local x, y
	if parent then
		x, y = node:xy()
	end

	_reset(node, baseNode)

	if parent then
		node:xy(x, y):show()
	end
end

function listview:makeItem(k, v, idler)
	local item, baseForReset
	if self.backupItemNodes_ and self.backupItemNodes_[k] then
		item, baseForReset = self.backupItemNodes_[k], self.item
		item:autorelease()
		self.backupItemNodes_[k] = nil
	else
		item = self.item:clone()
	end
	item.key_ = k
	item:stopAllActions()
	if not self.keyHash_[k] then
		return item
	end
	self.itemNodes_[k] = item

	if idler then
		if item.idler_ ~= idler then
			-- redo listen
			if item.listenerKey_ then
				item.listenerKey_:detach()
			end
			item.idler_ = idler
			item.listenerKey_ = idler:addListener(function(v, oldval, idler)
				if self.keyHash_[k] then
					self:onItem_(item, k, v)
				end
			end, true)
			resetItem(item, baseForReset)
			self:onItem(item, k, idler:get_())

		elseif self.itemAction and self.itemAction.isAction then
			resetItem(item, baseForReset)
			self:onItem(item, k, idler:get_())
		end
	else
		resetItem(item, baseForReset)
		self:onItem(item, k, v)
	end

	if self.onItemClick then
		bind.touch(self, item, {methods = {ended = function()
			self:setCurSelectedIndex(self:getIndex(item))
			return self:onItemClick(item, k, v)
		end}})
	end

	local idx = self:onItemIndex(k, v)
	if self.padding then
		local pos = idx and (idx + 1) or (self:getChildrenCount() - 1)
		if pos <= self:getChildrenCount() then
			self:insertCustomItem(item, pos)
		end
	elseif idx then
		if idx <= self:getChildrenCount() then
			self:insertCustomItem(item, idx)
		end
	else
		self:pushBackCustomItem(item)
	end

	return item:tag(idx or -1):show()
end

function listview:onItemAction(item, cnt, pos)
	if self.itemAction and self.itemAction.isAction then
		if not self.asyncPreload or cnt <= self.asyncPreload then
			-- 获得界面需要移动的item数量，不然数量过多动画时间太长
			local max = #self.orderKeys_
			local count = max
			if self.asyncPreload then
				count = math.min(count, self.asyncPreload)
			end
			local isVertical = self:getDirection() == ccui.ScrollViewDir.vertical
			if self.backupCached then
				if isVertical then
					count = math.min(count, math.ceil(self:height()/(self.item:height() + self:getItemsMargin())))
				else
					count = math.min(count, math.ceil(self:width()/(self.item:width() + self:getItemsMargin())))
				end
			end
			count = math.max(count, 1)

			local index = cnt
			-- 中心定位显示处理 10 11 9 12 8 13 ... count 为 5 时，动画表现8先
			if self.preloadCenterPos then
				local min = self.preloadCenterPos - math.floor((count-1)/2)
				if min + count > #self.orderKeys_ then
					min = #self.orderKeys_ - count + 1
				end
				min = math.max(min, 1)
				index = cc.clampf(pos - min + 1, 1, count)
			end

			local itemAction = self.itemAction
			local actionTime = itemAction.actionTime or 0.4
			local duration = math.min((itemAction.duration or 0.15) , (itemAction.durationLimit or 0.3) / count)
			local listSize = self:size()
			item.listviewAction_ = true
			for _, baseNode in pairs(item:getChildren()) do
				local x, y = baseNode:xy()
				if isVertical then
					baseNode:y(y - listSize.height + self.item:height())
				else
					baseNode:x(x + listSize.width + self.item:width())
				end
				local delayTime = (index - 1) * duration + 0.01
				baseNode:stopAllActionsByTag(ListViewActionTag)
				local action = transition.executeSequence(baseNode)
					:delay(delayTime)
					:easeBegin("EXPONENTIALOUT")
						:moveTo(actionTime, x, y)
					:easeEnd()
					:func(function()
						baseNode:xy(x, y)
					end)
					:done()
				action:setTag(ListViewActionTag)
			end
		else
			if not self.itemAction.alwaysShow then
				self.itemAction = nil
			end
		end
	end
end

function listview:onBeforeBuild()
end

function listview:onAfterBuild_()
	self:onAfterBuild()
end

function listview:onAfterBuild()
end

-- when the node be created
function listview:onItem(node, k, v)
end

function listview:onItemUpdate(node, k, v)
	return self:onItem_(node, k, v)
end

-- @return: nil表示pushback
function listview:onItemIndex(k, v)
	if self.dirtySort_ then
		self:filterSortData_()
	end
	local idx = self.keyHash_[k]
	if self.preloadCenterPos then
		return idx < self.preloadCenterPos and 0
	end
	return idx-1
end

-- function listview:onItemClick(node, k, v)
-- end

-- 如果是 tableview，这将 item 的 k 改成 {row, col, k}
function listview:getIdx(k)
	if self.dirtySort_ then
		self:filterSortData_()
	end
	local idx = self.keyHash_[k]
	if self.params and self.params.row then
		idx = {row = self.params.row, col = k, k = (self.params.k or 0) + k}
	end
	return idx
end

-- delay onItem to next frame
-- avoid many times in one frame
function listview:onItem_(node, k, v)
	if tolua.isnull(node) then
		return
	end
	if node.listviewAction_ == true then
		node.listviewAction_ = false
		for _, baseNode in pairs(node:getChildren()) do
			baseNode:stopAllActionsByTag(ListViewActionTag)
		end
	end
	self.dirtyNodes_ = self.dirtyNodes_ or {}
	local exist = self.dirtyNodes_[node] ~= nil
	self.dirtyNodes_[node] = {k, v}
	-- dirtyNodes is map
	if not exist then
		node:retain()
		gGameUI:addViewDelayCall(self, functools.partial(self.onDirtyUpdate, self))
	end
end

function listview:removeAllAndBackup()
	if self.asyncPreload then
		self:overFor()
	end
	self:backupOrCleanItems_()
	self:removeAllItems()
end

function listview:cleanDirtyNodes_()
	if self.dirtyNodes_ == nil then return end

	for node, kv in pairs(self.dirtyNodes_) do
		node:autorelease()
	end
	self.dirtyNodes_ = nil
end

function listview:onDirtyUpdate()
	if self.dirtyNodes_ == nil then return end

	for node, kv in pairs(self.dirtyNodes_) do
		local k, v = unpack(kv)
		if self.keyHash_[k] then
			resetItem(node, self.item)
			self:onItem(node, k, v)
		end
		node:autorelease()
	end
	self.dirtyNodes_ = nil
end

function listview:setItemAction(itemAction)
	self.itemAction = itemAction
end

function listview:resetItemAction()
	if self.itemAction and not self.itemAction.alwaysShow then
		self.itemAction = nil
	end
end

-- 设置当前中心位置
function listview:updatePreloadCenterIndex()
	self:refreshView()
	local currentItem = self:getCenterItemInCurrentView()
	if currentItem then
		-- getIndex 返回值下标从0开始
		self.preloadCenterIndex = self:getIndex(currentItem) + 1 - (self.padding and 1 or 0)
		-- 调用的时候界面还在协成加载，导致当前位置并不是实际目标位置
		if self.minPreloadIdx then
			self.preloadCenterIndex = self.preloadCenterIndex + (self.minPreloadIdx - 1)
		end
	end
end

-- 设置当前中心位置; 自适应标记若加载了第一行，则显示开头
function listview:updatePreloadCenterIndexAdaptFirst()
	self:updatePreloadCenterIndex()
	self.preloadCenterIndexAdaptFirst_ = true
end

return listview
