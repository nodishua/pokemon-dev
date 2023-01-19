-- @date: 2018-11-21
-- @desc: 宝箱详情

local ViewBase = cc.load("mvc").ViewBase
local BoxDetailView = class("BoxDetailView", Dialog)
BoxDetailView.RESOURCE_FILENAME = "common_box_detail.json"
BoxDetailView.RESOURCE_BINDING = {
	["title"] = "titleLabel",
	["btnClose"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")}
		},
	},
	["content"] = "contentLabel",
	["btnOk"] = {
		varname = "btnOk",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClickOk")}
		},
	},
	["btnOk.title"] = {
		varname = "btnText",
		binds = {
			{
				event = "effect",
				data = {glow={color=ui.COLORS.GLOW.WHITE}},
			},
			{
				event = "text",
				idler = bindHelper.self("btnText"),
			},
		},
	},
	["list"] = "list",
}

-- @param params: {data, [state], [title], [content], [cb]}
-- state 1表示可领取 0表示已领
function BoxDetailView:onCreate(params)
	self.cb = params.cb
	self.data = params.data
	self.state = params.state or 1
	self.clearFast = params.clearFast
	local btnState = self.state == 1 and "normal" or "hsl_gray"
	cache.setShader(self.btnOk, false, btnState)
	self.btnText = idler.new(params.btnText or gLanguageCsv.commonTextOk)
	if self.state ~= 1 then
		self.btnText:set(params.btnText or gLanguageCsv.received)
	end
	self.btnOk:setTouchEnabled(self.state == 1)
	if params.title then
		self.titleLabel:text(params.title)
	end
	if params.content then
		adapt.setTextAdaptWithSize(self.contentLabel, {str = params.content, size = cc.size(1000, 168), vertical = "center", horizontal = "center"})
	end
	uiEasy.createItemsToList(self, self.list, self.data, {
		onAfterBuild = function(list)
			list:adaptTouchEnabled()
				:setItemAlignCenter()
		end,
	})

	Dialog.onCreate(self)
end

function BoxDetailView:onClickOk()
	if self.state ~= 1 then
		return
	end
	self:addCallbackOnExit(self.cb)
	if self.clearFast then
		ViewBase.onClose(self)
	else
		Dialog.onClose(self)
	end
	return self
end

return BoxDetailView