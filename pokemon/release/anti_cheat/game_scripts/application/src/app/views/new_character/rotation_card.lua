-- @Date:   2019-05-23

local ViewBase = cc.load("mvc").ViewBase
local RotationCardView = class("RotationCardView", ViewBase)

RotationCardView.RESOURCE_FILENAME = "character_rotation_card.json"
RotationCardView.RESOURCE_BINDING = {
	["bottomCenterPanel.name"] = {
		varname = "nodeName",
		binds = {
			{
				event = "effect",
				data = {glow={color=ui.COLORS.GLOW.WHITE}}
			},
		}
	},
	["bottomCenterPanel.attr"] = "attr",
	["centerPanel"] = {
		binds = {
			event = "extend",
			class = "rotation_spine",
			props = {
				data = bindHelper.self("ids"),
				unitRes = bindHelper.self("unitRes"),
				textNode = bindHelper.self("nodeName"),
				icon = bindHelper.self("attr"),
				a = 500,
				b = 170,
				maxScale = 4 * 0.2,
				minScale = 2.5 * 0.2,
				-- isClockWise = true,
				onNode = function(panel, node)
					node:y(450)
				end,
				clickCb = function (panel, index)
					gGameUI:stackUI("new_character.select_card", nil, nil, index, panel.clickClose)
				end
			},
			handlers = {
				clickClose = bindHelper.self("onClose"),
			},
		}
	}
}

function RotationCardView:onCreate(cb)
	self.cb = cb
	self.ids = {}
	self.unitRes = {"koudai_miaowazhongzi2/miaowazhongzi2.skel", "koudai_xiaohuolong2/xiaohuolong2.skel", "koudai_jienigui2/jienigui_zhanshi2.skel"}
	for i,v in ipairs(csv.newbie_init[1].cards) do
		table.insert(self.ids, v.id)
	end
	local card = csv.cards[self.ids[2]]
	local unit = csv.unit[card.unitID]
	self.nodeName:text(card.name)
	self.attr:texture(ui.ATTR_ICON[unit.natureType])
end

function RotationCardView:onClose()
	self:addCallbackOnExit(self.cb)
	ViewBase.onClose(self)
end

return RotationCardView