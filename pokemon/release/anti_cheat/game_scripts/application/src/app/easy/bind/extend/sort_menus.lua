--
-- 下拉菜单
--
local listview = require "easy.bind.extend.listview"
local inject = require "easy.bind.extend.inject"
local helper = require "easy.bind.helper"

local sortMenus = class("sortMenus", cc.load("mvc").ViewBase)

local menus = {}
menus.RESOURCE_FILENAME = "common_sort_menus.json"
menus.RESOURCE_BINDING = {
	["btn1"] = "btn1",
	["btn2"] = "btn2",
	["btn3"] = "btn3",
	["btn4"] = "btn4",
	["listBg"] = "listBg",
	["item"] = "item",
	["list"] = "list",
}

sortMenus.defaultProps = {
	-- idler(array), 条目名称
	data = nil,
	showSelected = nil,
	width = 308,
	-- item 的高度
	height = 80,
	btnWidth = 332,
	btnHeight = 122,
	btnClick = nil,
	-- 1.img:btn_normal, 2.img:btn_normal_1, 3.img:btn_normal_2
	btnType = 1,
	-- btn点击操作后的额外操作处理
	btnTouch = nil,
	-- 菜单默认向下展开
	expandUp = false,
	-- 默认最多显示5条数据
	maxCount = 5,
	-- 排序列表显示隐藏
	showSortList = nil,
	locked = nil,
	nowSelected = 1,
	-- 创建后对 menus node 的处理
	onNode = nil,
	defaultTitle = nil,
	showLock = true,
}

function sortMenus:initExtend()
	local width = self.width
	local height = self.height
	self.showSortList = self.showSortList or idler.new(false)
	self.lock = self.locked or idler.new(0)

	local node = gGameUI:createSimpleView(menus, self):init()
	node.item:size(width, height)
		:hide()
	node.item:get("bg")
		:size(width, height)
	for i=1,4 do
		if i ~= self.btnType then
			node["btn"..i]:hide()
		end
	end
	local btn = node["btn"..self.btnType]
	local btnTitle = btn:get("title")
	local btnWidth = self.btnWidth or width
	local color = ui.COLORS.NORMAL.WHITE
	if self.btnType == 1 then
		btn:size(btnWidth, self.btnHeight or height + 40)
	elseif self.btnType == 2 then
		btn:size(btnWidth, self.btnHeight or height + 20)
	elseif self.btnType == 3 then
		btn:size(btnWidth, self.btnHeight or height + 20)
	elseif self.btnType == 4 then
		color = ui.COLORS.NORMAL.RED
		btn:size(btnWidth, self.btnHeight or height + 40)
	end
	text.addEffect(btnTitle, {glow = {color = ui.COLORS.GLOW.WHITE}, color = color})
	btn:get("img"):x(btnWidth - 57 * (self.btnType == 2 and 0.9 or 1))
	bind.touch(node, btn, {methods = {ended = function(view, sender)
		self.showSortList:modify(function(val)
			return true, not val
		end)
		if self.btnTouch then
			self.btnTouch(sender)
		end
	end}})

	idlereasy.when(self.showSortList, function (obj, show)
		if self.expandUp then
			btn:get("img"):rotate((not show) and 0 or 180)
		else
			btn:get("img"):rotate(show and 0 or 180)
		end
		node.list:visible(show)
		node.listBg:visible(show)
	end)

	self.stateData = idlers.new()
	if self.showSelected then
		self.showSelected = isIdler(self.showSelected) and self.showSelected or idler.new(self.showSelected)
	else
		self.showSelected = idler.new(1)
	end
	local isFirst = true
	idlereasy.any({self.data, self.lock}, function(obj, data, lock)
		local maxCount = math.min(self.maxCount,#data)
		local baseX = btn:x() - width/2 - 12
		local marg = (maxCount - 1) * 10
		if not self.expandUp then
			node.listBg:size(width + 24, height * maxCount + 86 + marg)
				:anchorPoint(0, 1)
				:xy(baseX, btn:y() - btn:size().height/2)
			node.list:size(width, height * maxCount + marg)
				:anchorPoint(0, 1)
				:xy(baseX+10, node.listBg:y() - 40)
		else
			node.listBg:size(width + 24, height * maxCount + 86 + marg)
				:anchorPoint(0, 0)
				:xy(baseX, btn:y() + btn:size().height/2)
			node.list:size(width, height * maxCount + marg)
				:xy(baseX+10, node.listBg:y() + 46)

		end
		self.showSortList:set(false)

		local nowSelected = cc.clampf(self.showSelected:read(), 1, #data)
		local t = {}
		for i,v in ipairs(data) do
			t[i] = {name = v, lock = (lock ~= 0 and i >= lock), selected = (i == nowSelected)}
		end
		self.stateData:update(t)
		-- 首次相同不用重复触发
		if not isFirst or nowSelected ~= self.showSelected:read() then
			self.showSelected:set(nowSelected, true)
		end
	end):notify()

	local view = self.parent_
	local handlers = self.__handlers
	local props = {
		data = self.stateData,
		item = node.item,
		onItem = functools.partial(self.onItem_, self),
		onItemClick = functools.partial(self.onItemClick, self),
	}
	inject(listview, view, node.list, handlers, helper.props(view, node.list, props))
		:initExtend()


	helper.callOrWhen(self.defaultTitle, function(defaultTitle)
		btnTitle:text(defaultTitle)
	end)

	self.showSelected:addListener(function(val, oldval)
		if self.stateData:atproxy(oldval) then
			self.stateData:atproxy(oldval).selected = false
		end
		if self.stateData:atproxy(val) then
			self.stateData:atproxy(val).selected = true
			if not self.defaultTitle then
				btnTitle:text(self.stateData:atproxy(val).name)
			end
			local xPos
			if self.btnType ~= 2 then
				xPos = self.btnWidth and self.btnWidth/2 - 30 or width/2 - 30
			else
				xPos = self.btnWidth and self.btnWidth/2 - 20 or width/2 - 20
			end
			btnTitle:x(xPos)
			-- text.addEffect(btnTitle, {glow = {color = ui.COLORS.GLOW.WHITE}, color = ui.COLORS.NORMAL.WHITE})
			if not matchLanguage({"cn", "tw"}) then
				adapt.setTextScaleWithWidth(btnTitle, nil, self.btnWidth - 100)
			end
		end
	end)
	btn:show()
	if self.onNode then
		self.onNode(node)
	end
	isFirst = false
	return self
end

function sortMenus:onItem_(list, node, k, v)
	local title = node:get("title")
	if self.btnType ~= 2 then
		title:x(44)
	else
		title:x(10)
	end
	node:get("bg"):visible(v.selected)
	title:text(v.name)
	local color = v.selected and ui.COLORS.NORMAL.WHITE or ui.COLORS.NORMAL.RED
	title:setTextColor(color)
	local lock = node:get("lock")
	if v.lock then
		if lock then
			lock:show()
		elseif self.showLock then
			lock = ccui.ImageView:create("common/btn/btn_lock.png")
				:align(cc.p(0.5, 0.5), 0, title:y())
				:addTo(node, 4, "lock")
			adapt.oneLinePos(title, lock, cc.p(10, 0), "left")
		end
	else
		if lock then
			lock:hide()
		end
	end

	local width = math.max(self.width - 308 + 230, 230)
	title:anchorPoint(0.5, 0.5)
	title:x(title:x() + width/2)
	adapt.setTextScaleWithWidth(title, nil, width)

	if self.onItem then
		self:onItem(node, k, v)
	end
end

function sortMenus:onItemClick(list, node, k, v)
	local oldval = self.showSelected:read()
	if not v.lock then
		self.showSelected:set(k)
		self.showSortList:set(false)
	end
	self.btnClick(node, k, v, oldval)
end

return sortMenus