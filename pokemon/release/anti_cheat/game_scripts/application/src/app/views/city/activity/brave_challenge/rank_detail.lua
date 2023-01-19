-- @date:   2021-03-15
-- @desc:   勇者挑战---排名信息

local LINE_NUM = 40
local LINE_HIGHT = 50
local BraveChallengeRankDetailView = class("BraveChallengeRankDetailView", cc.load("mvc").ViewBase)

BraveChallengeRankDetailView.RESOURCE_FILENAME = "activity_brave_challenge_rank_detail.json"

BraveChallengeRankDetailView.RESOURCE_BINDING = {
    ["baseNode"] = "baseNode",
    ["baseNode.title1.txt"] = {
		binds = {
			event = "effect",
			data = {outline = {color = cc.c4b(212, 86, 95, 255), size = 2}}
		}
	},
	["baseNode.title2.txt"] = {
		binds = {
			event = "effect",
			data = {outline = {color = cc.c4b(212, 86, 95, 255), size = 2}}
		}
	},
}

function BraveChallengeRankDetailView:onCreate(datas)
	self.baseNode:get("list1"):setScrollBarEnabled(false)
	self.baseNode:get("list2"):setScrollBarEnabled(false)
    local item = self.baseNode:get("item")
	local function setCards(list, st, ed)
		list:removeAllChildren()
		for i = st, ed do
			local node = item:clone()
			list:pushBackCustomItem(node)
			local data = datas.brave_challenge_rank_info.deployments[i]
			if data ~= 0 then
				local cardCfg = csv.brave_challenge.cards[data]
				local cardId = csv.cards[cardCfg.cardID]
				local unitCsv = csv.unit[cardId.unitID]
				node:get("icon"):texture(unitCsv.iconSimple)
				node:show()
			else
				node:get("icon"):hide()
			end
		end
	end
	setCards(self.baseNode:get("list1"), 1, 3)
	setCards(self.baseNode:get("list2"), 4, 6)
end

return BraveChallengeRankDetailView