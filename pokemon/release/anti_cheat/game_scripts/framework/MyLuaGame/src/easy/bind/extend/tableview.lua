--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2017 TianJi Information Technology Inc.
--
-- ccui.ListView组装成tableview的形式
-- 老版本studio没有ccui.TableView，只能拿二维ccui.ListView来模拟
--

local ListViewActionTag = 2010231612
local listview = require "easy.bind.extend.listview"
local inject = require "easy.bind.extend.inject"
local helper = require "easy.bind.helper"

local tableview = class("tableview", listview)

tableview.defaultProps = {
	-- onXXXX 响应函数
	-- 数据 array table, function
	data = nil,
	-- 数据过滤 function
	dataFilter = nil,
	dataFilterGen = nil, -- return dataFilter
	-- 数据排序 function
	dataOrderCmp = nil,
	dataOrderCmpGen = nil, -- return dataOrderCmp
	-- 列数
	columnSize = 1,
	-- 行数 nil 自动
	rowSize = nil,
	-- item模板
	item = nil,
	-- cell模板
	cell = nil,
	-- 左右间距，子条目间距，nil 不改变
	xMargin = nil,
	-- 上下间距，nil 不改变
	yMargin = nil,
	-- 左右边填充，子条目间距，nil 不改变
	leftPadding = nil,
	-- 上下边填充，nil 不改变
	topPadding = nil,
	-- 异步加载, nil 不使用异步加载, >=0 预加载数量
	asyncPreload = nil,
	-- 下次刷新以当前屏幕显示内容先刷新
	preloadCenterIndex = nil,
	preloadCenter = nil, -- key in data
	preloadBottom = false,
	-- itemAction = nil,
	-- itemAction = {isAction = true, alwaysShow = true},
}

local function getRowCol(index, lineNum)
	-- after filter, index maybe nil
	if not index then
		return 0, 0
	end
	local row  = math.floor((index - 1) / lineNum) + 1
	local col = (index - 1) % lineNum + 1
	return row, col
end

function tableview:initExtend()
	self.containerPosX = self:getPositionX()
	if self.asyncPreload then
		self.asyncPreloadBackup = self.asyncPreload
		self.asyncPreload = nil
		-- may be covered by outside
		if not self.disableOnScroll then
			self:onScroll(function(event)
				if event.name == "SCROLL_TO_TOP" or event.name == "SCROLL_TO_BOTTOM" or event.name == "SCROLL_TO_LEFT" or event.name == "SCROLL_TO_RIGHT" then
					self.quick_ = true
					if self.lastItem_ and self.lastItem_.quickFor then
						self.lastItem_:quickFor()
					end
				end
			end)
		end
	else
		self.asyncPreloadBackup = 999999
	end
	self.backupCached = false

	if self.preloadCenter then
		self.preloadCenter_ = isIdler(self.preloadCenter) and self.preloadCenter:read() or self.preloadCenter
	end

	-- save original props
	self.containerSize = self:getContentSize()
	--self.rawData = self.data

	self:setRenderHint(2) -- 2D

	self.itemNodes_ = {}
	self.backupItemNodes_ = nil -- cache items
	self.dirtySort_ = false
	self.dirtyUpdate_ = false
	self.asyncLoadingPause_ = false

	local data, idler, idlers = helper.dataOrIdler(self.data)
	self.data, self.dataSource_ = data, data
	if idlers then
		idlers:addListener(function(msg, idlers)
			-- print('!!! tableview idlers msg', msg.event,self, self:getChildrenCount(),self.backupCached, dumps(msg))
			self.data = idlers:get_() -- reference it
			self.dataSource_ = self.data
			if msg.event == "init" then
				self:buildExtend()

			elseif msg.event == "remove_all" then
				self:backupOrCleanItems_()
				self:removeAllItems()
				self.dirtySort_ = true

			elseif msg.event == "update" then
				local item = self:getItemNodes(msg.key)
				if item then
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
					local item, idler = self:getItemNodes(key), self.data[key]
					if item then
						self:onItemUpdate(item, key, idler:get_())
					end
				end)

			elseif msg.event == "update_all_end" then
				if self.dirtyUpdate_ then
					self:buildExtend()
				end
				self.dirtyUpdate_ = false

			elseif msg.event == "add" or msg.event == "remove" or msg.event == "swap" then
				self.dirtyUpdate_ = true
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

-- delay onItem to next frame
-- avoid many times in one frame
function tableview:onItem_(node, k, v)
	if node.listviewAction_ == true then
		node.listviewAction_ = false
		for _, baseList in pairs(item:getChildren()) do
			for _, baseNode in pairs(baseList:getChildren()) do
				baseNode:stopAllActionsByTag(ListViewActionTag)
			end
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

function tableview:backupOrCleanItems_()
	for _, item in pairs(self.itemNodes_) do
		listview.backupOrCleanItems_(item)
	end
	listview.backupOrCleanItems_(self)
end

function tableview:buildExtend()
	self.itemSize = self.rowSize
	self.asyncPreloadLeft = self.asyncPreloadBackup
	local cellProps = {
		data = nil,
		itemSize = self.columnSize,
		item = self.cell,
		margin = self.xMargin,
		padding = self.leftPadding,
		asyncPreload = nil,
		onItem = self.onCell,
		onItemUpdate = self.onCellUpdate or self.onCell,
		onItemIndex = self.onCellIndex,
		onItemClick = self.onCellClick,
		onAfterBuild = function() self:onAfterListBuild_() end,
		backupCached = false,
		itemAction = {isAction = false},
	}
	self.cellProps = cellProps
	if self.yMargin then
		self:setItemsMargin(self.yMargin)
	end

	self.padding = self.topPadding
	self.minPreloadRow = nil

	self.st = os.clock()
	-- print('!!!tableview start', self)
	return listview.buildExtend(self)
end

function tableview:building()
	self.itemSize = self.itemSize or 999999
	-- 当前最小加载到的行数
	local iter
	local data, orderKeys = self.data, self.orderKeys_
	local maxRowSize = getRowCol(itertools.size(self.orderKeys_), self.columnSize)
	if self.preloadBottom then
		self.preloadCenterIndex = #orderKeys
	end
	self.preloadCenterPos = self.preloadCenterIndex or (self.keyHash_[self.preloadCenter_] and getRowCol(self.keyHash_[self.preloadCenter_], self.columnSize))
	local function getRowData(row)
		local rowData = nil
		for j = 1, self.columnSize do
			local idx = (row - 1) * self.columnSize + j
			if idx > self.itemSize then
				break
			end
			local key = orderKeys[idx]
			if key then
				rowData = rowData or {}
				rowData[j] = data[key]
			end
		end
		return row, rowData
	end
	if self.preloadCenterPos then
		self.minPreloadIdx = nil
		iter = helper.extendDataIter(function(row, cnt)
			self.minPreloadIdx = math.min(self.minPreloadIdx or math.huge, row)
			return getRowData(row)
		end, maxRowSize, self.preloadCenterPos)
	else
		if self:getDirection() == ccui.ListViewDirection.horizontal then
			self:jumpToLeft()
		else
			self:jumpToTop()
		end
		local i = 0
		iter = function()
			i = i + 1
			return getRowData(i)
		end
	end

	self.preloadCenterIndex = nil
	self.preloadCenter_ = nil
	local preloadCenterIndexAdaptFirst_ = self.preloadCenterIndexAdaptFirst_
	self.preloadCenterIndexAdaptFirst_ = nil

	if gGameUI.guideManager:isInGuiding() then
		self.itemAction = nil
	end

	-- 1. sync, call in tableview:makeItem when inject
	-- 2. async, call when coroutine end
	local cnt = 0
	self.onAfterListBuild_ = function()
		while true do
			if cnt == nil or cnt >= maxRowSize then
				self.onAfterListBuild_ = function() end

				self.quick_ = nil
				self.lastItem_ = nil
				self:refreshView()
				self:setShowCenterIndex(-1)
				self:cleanBackupItems_()
				return self:onAfterBuild()
			end
			cnt = cnt + 1
			local k, v = iter()
			local item = self:makeItem(k, v)
			self:onItemAction(item, cnt, k)

			if cnt == 1 and self.preloadCenterPos then
				local idx = self.padding and 1 or 0
				self:setShowCenterIndex(idx)
				self:setCurSelectedIndex(idx)
				self:refreshView()
			end
			-- 加载 asyncPreload 后如果第1个加载了，显示到头位置
			if preloadCenterIndexAdaptFirst_ and self.asyncPreloadLeft and self.asyncPreloadLeft >=0 and self.minPreloadIdx == 1 then
				self:setShowCenterIndex(-1)
			end
			if item.asyncPreload then
				-- wait onAfterBuild call
				break
			end
		end
	end
	self:onAfterListBuild_()

	self:resetItemAction()
end

-- for each listview
function tableview:makeItem(k, v)
	if type(v) ~= "table" then
		error("tableview need 2d table")
	end

	local view = self.parent_
	local node = self.item:clone()
	-- props会被clone，是考虑有不同属性值的更改
	-- handlers不会被克隆，是考虑行为是以传入相关响应参数来实现逻辑
	local props = clone(self.cellProps)
	local handlers = self.__handlers
	props.data = v
	self.asyncPreloadLeft = self.asyncPreloadLeft - self.columnSize
	if self.asyncPreloadLeft < 0 then
		props.asyncPreload = math.max(0, self.columnSize + self.asyncPreloadLeft)
	else
		-- avoid listview in async insert before the sync part
		props.onAfterBuild = nil
	end

	-- tableview need pass handlers to sub-listview
	-- asyncPreload will be in here, initExtend
	local item = inject(listview, view, node, handlers, helper.props(view, node, props))
		:initExtend({row = k, k = self.columnSize * (k-1)})
	self.itemNodes_[k] = item
	self:onItem(item, k, v)
	local idx = self:onItemIndex(k, v)
	if self.padding then
		local pos = idx and (idx + 1) or (self:getChildrenCount() - 1)
		self:insertCustomItem(item, pos)

	elseif idx then
		self:insertCustomItem(item, idx)
	else
		self:pushBackCustomItem(item)
	end

	item:setTouchEnabled(false)
	-- 去掉内部 list 裁剪
	item:setClippingEnabled(false)
	if self.quick_ and item.quickFor then
		item:quickFor()
	end
	if self.asyncLoadingPause_ and item.pauseFor then
		item:pauseFor()
	end
	self.lastItem_ = item

	return item:tag(k):show()
end

function tableview:onItemAction(item, cnt, pos)
	if self.itemAction and self.itemAction.isAction then
		if self.asyncPreloadLeft and self.asyncPreloadLeft >= 0 then
			-- 获得界面需要移动的item数量，不然数量过多动画时间太长
			local max = getRowCol(itertools.size(self.orderKeys_), self.columnSize)
			local count = max
			count = math.min(count, self.asyncPreloadLeft)
			local isVertical = self:getDirection() == ccui.ScrollViewDir.vertical
			if isVertical then
				count = math.min(#self.orderKeys_, math.ceil(self:height()/self.item:height()))
			else
				count = math.min(#self.orderKeys_, math.ceil(self:width()/self.item:width()))
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
			for _, baseList in pairs(item:getChildren()) do
				for _, baseNode in pairs(baseList:getChildren()) do
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
			end
		else
			if not self.itemAction.alwaysShow then
				self.itemAction = nil
			end
		end
	end
end

-- onItem = self.onCell,
-- function tableview:onCell(node, k, v)
-- end

-- onItemUpdate = self.onCellUpdate,
-- function tableview:onCellUpdate(node, k, v)
-- end

function tableview:onItemIndex(k, v)
	if self.dirtySort_ then
		self:filterSortData_()
	end
	if self.preloadCenterPos then
		return k < self.preloadCenterPos and 0
	end
	return k-1
end

function tableview:getIdx(k)
	if self.dirtySort_ then
		self:filterSortData_()
	end
	local idx = self.keyHash_[k]
	local row, col = getRowCol(idx, self.columnSize)
	return {row = row, col = col, k = idx}
end

function tableview:getItemNodes(key)
	local idx = self:getIdx(key)
	local listNode = self.itemNodes_[idx.row]
	if not listNode then
		return nil
	end
	return listNode.itemNodes_[idx.col]
end

-- onItemClick = self.onCellClick,
-- function tableview:onCellClick(node, k, v)
-- end

function tableview:onAfterBuild()
	-- print('!!!tableview over cost', self, os.clock()-self.st)
end

-- wrap like asyncload
-- NOTE: tableview could not enableAsyncload
function tableview:pauseFor()
	self.asyncLoadingPause_ = true
	for k, item in pairs(self.itemNodes_) do
		if item.pauseFor then
			item:pauseFor()
		end
	end
end

function tableview:resumeFor()
	self.asyncLoadingPause_ = false
	for k, item in pairs(self.itemNodes_) do
		if item.resumeFor then
			item:resumeFor()
		end
	end
end

return tableview
