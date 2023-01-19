-- @date: 2021-01-05
-- @desc:buff详情

local BuffInfoView = class("BuffInfoView", cc.load("mvc").ViewBase)

BuffInfoView.RESOURCE_FILENAME = "cross_mine_buff_info.json"
BuffInfoView.RESOURCE_BINDING = {
	["panel"] ={
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")},
		},
	},
	["buffPanel"] = "buffPanel",
	["buffPanel.bg"] = "buffBg",
	["buffPanel.buffImg"] = "buffImg",
	["buffPanel.buffName"] = "buffName",
	["buffPanel.buffinfoList"] = "buffinfoList",
}

function BuffInfoView:onCreate(params)
	local buffData = params.data
	local pos = params.pos
	self.buffPanel:xy(pos[1], pos[2])

	local cfg = buffData
	self.buffImg:texture(cfg.buffIcon)
	self.buffName:text(cfg.buffName)
	beauty.textScroll({
		list = self.buffinfoList,
		strs = cfg.buffDesc,
		fontSize = 40,
		effect = {color = cc.c3b(91, 84, 91)},
	})
	local height = self.buffinfoList:height()
	local interSize = self.buffinfoList:getInnerContainerSize()
	if interSize.height > height then
		self.buffinfoList:height(interSize.height)
		local difHeight = interSize.height - height
		self.buffBg:height(self.buffBg:height() + difHeight)
		self.buffImg:y(self.buffImg:y() + difHeight)
		self.buffName:y(self.buffName:y() + difHeight)
	end
end

return BuffInfoView