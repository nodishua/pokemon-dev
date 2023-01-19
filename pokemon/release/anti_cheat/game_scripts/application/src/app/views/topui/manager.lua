-- @date: 2018-10-24
-- @desc: 根据不同的界面加载独立的topui界面

local TopuiManager = class("TopuiManager")

function TopuiManager:ctor()
	self.map = {}
	self.mapIDCounter = 0
	self.topView = 0
end

function TopuiManager:createView(name, parent, handlers)
	name = name or "default"
	local viewName = string.format("topui.views.%s", name)
	-- createView 的 init 外层调用
	local view = gGameUI:createView(viewName, parent, handlers)
	self.mapIDCounter = self.mapIDCounter + 1
	self.topView = view
	self.map[view] = {
		parent = parent,
		name = name,
		view = view,
		id = self.mapIDCounter,
	}
	view:onNodeEvent("exit", functools.partial(self.removeView, self, view))
	return view
end

function TopuiManager:removeView(view)
	local info = self.map[view]
	-- info可能为nil，stash时有retain
	-- exit只表明从当前节点移除，不代表被清理
	if info then
		if view == self.topView then
			self.topView = nil
		end
		self.map[view] = nil
		view:removeSelf()
		return true
	end
end

function TopuiManager:updateTitle(title, subTitle)
	if self.topView == nil then
		local maxID = 0
		for k, info in pairs(self.map) do
			if maxID < info.id then
				maxID = info.id
				self.topView = info.view
			end
		end
	end

	local info = self.map[self.topView]
	if info then
		info.view:updateTitle(title, subTitle)
	end
end

return TopuiManager