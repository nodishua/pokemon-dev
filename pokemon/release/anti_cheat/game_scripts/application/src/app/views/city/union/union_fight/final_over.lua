-- @date:   2020-02-25
-- @desc:   公会战界面

local unionTools = require "app.views.city.union.tools"
local UnionFightFinalOverView = class("UnionFightFinalOverView", cc.load("mvc").ViewBase)

UnionFightFinalOverView.RESOURCE_FILENAME = "union_fight_final_over.json"
UnionFightFinalOverView.RESOURCE_BINDING = {
	["bg1"] = "bg1",
	["title"] = "title",
	["childPanel"] = "childPanel",
}

function UnionFightFinalOverView:onCreate(dialogHandler)
	local x, y = self.childPanel:xy()
	local size = self.childPanel:size()
	local w, h = size.width, size.height
	self.view = gGameUI:createView("city.union.union_fight.top8_info_view"):init(true, true, dialogHandler)
		:addTo(self.childPanel, 999)
		:xy(- 420, -210)
		:scale(0.95)

	local x, y = self.bg1:xy()
	local node = self:getResourceNode()
	local parentSize = self.bg1:size()
	local spinePath = "effect/zuanshichouka.skel"
	widget.addAnimationByKey(node, spinePath, "Main_Ani", "effect_yhhh_loop", 99)
		:xy(x + 200, 30)
		:scale(2.1)
	self.bg1:hide()
end

return UnionFightFinalOverView