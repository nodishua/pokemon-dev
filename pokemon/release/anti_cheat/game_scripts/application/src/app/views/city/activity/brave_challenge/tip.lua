-- @date: 2018-10-18
-- @desc: 通用飘字

local BraveChallengeTipView = class("BraveChallengeTipView", cc.load("mvc").ViewBase)
BraveChallengeTipView.RESOURCE_FILENAME = "activity_brave_challenge_tip.json"
BraveChallengeTipView.RESOURCE_BINDING = {
	["baseNode"] = "baseNode",
	["baseNode.img"] = "imgBg",
	["baseNode.list"] = "list",
	["baseNode.btn"] = "btn"
}
function BraveChallengeTipView:onCreate(params)

	local list = beauty.textScroll({
		list = self.list,
		strs = params.strs,
		isRich = true,
		fontSize = 40,
	})

	local containSize = self.list:getInnerContainerSize()
	local size = self.list:size()
	local dot = containSize.height - size.height
	if dot > 0 then
		self.list:size(containSize)
		local imgSize = self.imgBg:size()
		self.imgBg:size(cc.size(imgSize.width, imgSize.height + dot))
	end

	self.baseNode:xy(params.pos)

end




return BraveChallengeTipView
