-- @date:   2019-10-22
-- @desc:   随机塔buff提示弹窗

local RandomTowerBuffDetailView = class("RandomTowerBuffDetailView", cc.load("mvc").ViewBase)

RandomTowerBuffDetailView.RESOURCE_FILENAME = "random_tower_buff_detail.json"
RandomTowerBuffDetailView.RESOURCE_BINDING = {
	["touchPanel"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")},
		}
	},
	["baseNode.list"] = "list",
	["baseNode.bg"] = "bg",
	["baseNode"] = "baseNode",
}
function RandomTowerBuffDetailView:onCreate(params)
	local buffCfg = csv.random_tower.buffs[params.buffId]
	beauty.textScroll({
		list = self.list,
		strs = "#C0x5B545B#" .. buffCfg.desc,
		isRich = true,
		fontSize = 40,
	})
	local size = self.baseNode:size()
	local pos = params.pos
	local x = pos.x + size.width / 2 + 200
	local y = pos.y - size.height / 2
	local size = self.bg:size()
	y = math.max(size.height / 2, y)
	y = math.min(y, display.height - size.height / 2)
	self.baseNode:xy(x, y)
end

return RandomTowerBuffDetailView