-- @date: 2020-06-24
-- @desc: 鱼类详情

local FishDetailView = class("FishDetailView", cc.load("mvc").ViewBase)
FishDetailView.RESOURCE_FILENAME = "common_fish_detail.json"
FishDetailView.RESOURCE_BINDING = {
	["baseNode.icon"] = {
		binds = {
			event = "extend",
			class = "fish_icon",
			props = {
				data = bindHelper.self("data"),
				onNode = function(node)
					local size = node:size()
					node:alignCenter(size)
					node:scale(1.2)
				end,
			},
		},
	},
	["baseNode.name"] = "nodeName",
	["baseNode.content"] = "contentLabel",
	["baseNode.list"] = "list",
	["baseNode"] = "baseNode",
	["baseNode.lockPanel"] = "lockPanel",
	["baseNode.lockPanel.lock1"] = "lock1",
	["baseNode.lockPanel.numlock"] = "numlock",
	["baseNode.lockPanel.lock2"] = "lock2",
}

function FishDetailView:onCreate(params)
	self:initModel()
	local key = params.key
	self.data = {key = key}
	local cfg = csv.fishing.fish[key]

	self.nodeName:text(cfg.name)
	text.addEffect(self.nodeName, {color=ui.COLORS.QUALITY[cfg.rare + 2]}, {outline={color=ui.COLORS.QUALITY_OUTLINE[cfg.rare + 2]}})

	if self.fishLevel:read() < cfg.needLv then
		self.lockPanel:show()
		self.numlock:text(cfg.needLv)
		adapt.oneLinePos(self.lock1, {self.numlock, self.lock2}, cc.p(0, 0), "left")
	end
	local size = matchLanguage({"tw"}) and 38 or 40
	beauty.textScroll({
		list = self.list,
		strs = "#C0x5B545B#" .. cfg.desc ,
		isRich = true,
		fontSize = size,
	})
end

function FishDetailView:initModel()
	self.fishLevel = gGameModel.fishing:getIdler("level")
end

return FishDetailView