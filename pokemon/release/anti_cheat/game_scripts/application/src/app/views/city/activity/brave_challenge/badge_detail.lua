-- @date:   2021-03-15
-- @desc:   勇者挑战---勋章信息

local BraveChallengeBadgeDetailView = class("BraveChallengeBadgeDetailView", cc.load("mvc").ViewBase)

BraveChallengeBadgeDetailView.RESOURCE_FILENAME = "activity_brave_challenge_badge_detail.json"

BraveChallengeBadgeDetailView.RESOURCE_BINDING = {
    ["baseNode"] = "baseNode",
    ["baseNode.title"] = "title",
}

function BraveChallengeBadgeDetailView:onCreate(data)
    self.title:text(data.name)

    local richtext = rich.createWithWidth("#C0x5B545B#" .. data.desc, 36, nil, 470)
            :anchorPoint(0.5, 1)
            :addTo(self.baseNode, 10, "textNum")
    self.baseNode:height(richtext:height() + 150)
    self.title:y(richtext:height() + 90)
    richtext:xy(self.baseNode:width() / 2, richtext:height() + 40)
end

return BraveChallengeBadgeDetailView