-- @date:   2019-06-05
-- @desc:   公会选择图标

local UnionSelectLogoView = class("UnionSelectLogoView", Dialog)

UnionSelectLogoView.RESOURCE_FILENAME = "union_select_logo.json"
UnionSelectLogoView.RESOURCE_BINDING = {
	["btnClose"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")}
		},
	},
	["btnSure"] = {
		varname = "btnSure",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClickSure")}
		},
	},
	["btnSure.txt"] = {
		binds = {
			event = "effect",
			data = {color = ui.COLORS.NORMAL.WHITE, glow = {color = ui.COLORS.GLOW.WHITE}},
		},
	},
	["btnCancel"] = {
		varname = "btnCancel",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")}
		},
	},
	["btnCancel.txt"] = {
		binds = {
			event = "effect",
			data = {color = ui.COLORS.NORMAL.WHITE, glow = {color = ui.COLORS.GLOW.WHITE}},
		},
	},
	["item"] = "item",
	["subList"] = "subList",
	["list"] = {
		varname = "list",
		binds = {
			event = "extend",
			class = "tableview",
			props = {
				data = bindHelper.self("logoDatas"),
				columnSize = 7,
				item = bindHelper.self("subList"),
				cell = bindHelper.self("item"),
				onCell = function(list, node, k, v)
					node:get("locked"):visible(v.unlocked == 2)
					node:get("used"):visible(v.inUse)
					node:get("selected"):visible(v.selectEffect or false)
					node:get("icon"):texture(v.icon)
					bind.touch(list, node, {methods = {ended = functools.partial(list.itemClick, list:getIdx(k), v)}})
				end,
				asyncPreload = 16,
			},
			handlers = {
				itemClick = bindHelper.self("onFrameItemClick"),
			},
		},
	},
}

function UnionSelectLogoView:onCreate(params)
	self.cb = params.cb
	self.logoDatas = idlers.new()
	local tmpData = {}
	for k,v in csvPairs(csv.union.union_logo) do
		local inUse = (params.id == k)
		local unlocked = 1--frames[k] and 1 or 2
		table.insert(tmpData,{id = k, icon = v.icon, inUse = inUse, unlocked = unlocked})
	end
	table.sort(tmpData,function(a,b)
		if a.unlocked ~= b.unlocked then
			return a.unlocked < b.unlocked
		end
		return a.id < b.id
	end)
	self.logoDatas:update(tmpData)

	self.selectFrame = idler.new(params.id)
	self.selectFrame:addListener(function(val, oldval)
		local logoDatas = self.logoDatas:atproxy(val)
		local oldlogoDatas = self.logoDatas:atproxy(oldval)
		if oldlogoDatas then
			oldlogoDatas.selectEffect = false
		end
		logoDatas.selectEffect = true
	end)
	Dialog.onCreate(self)
end

function UnionSelectLogoView:onFrameItemClick(list, t, v)
	self.selectFrame:set(t.k)
end

function UnionSelectLogoView:onClickSure()
	if self.cb then
		local selectFrame = self.selectFrame:read()
		self:addCallbackOnExit(functools.partial(self.cb, selectFrame))
		self:onClose()
	else
		gGameApp:requestServer("/game/union/logo/modify", function (tb)
			self:onClose()
		end, self.selectFrame)
	end
end

return UnionSelectLogoView