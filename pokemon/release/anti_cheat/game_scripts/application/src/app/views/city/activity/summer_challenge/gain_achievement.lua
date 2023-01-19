-- @date:   2021-07-07
-- @desc:   夏日挑战---成就称号界面

local ViewBase = cc.load("mvc").ViewBase
local SummerChallengeGainAchievementView = class("SummerChallengeGainAchievementView", ViewBase)

SummerChallengeGainAchievementView.RESOURCE_FILENAME = "summer_challenge_gain_achievement.json"
SummerChallengeGainAchievementView.RESOURCE_BINDING = {
    ["icon.imgLight"] = "imgLight",
    ["icon.imgLight1"] = "imgLight1",
    ["item"] = "item",
    ["gain"] = {
		varname = "gain",
        binds = {
			{
				event = "effect",
				data = {outline = {color = cc.c4b(91, 84, 91, 255), size = 4}}
			},
		}
    },
}
SummerChallengeGainAchievementView.RESOURCE_STYLES = {
    blackLayer = true,
    clickClose = true,
}

function SummerChallengeGainAchievementView:onCreate(params)

    bind.extend(self, self.item, {
        class = "icon_key",
        props = {
            data = {
                key = params.itemId,
            }
        },
    })

    local animate = cc.RotateBy:create(15, 360)
    local animate1 = cc.RotateBy:create(6, -360)
    self.imgLight:runAction(cc.RepeatForever:create(animate))
    self.imgLight1:runAction(cc.RepeatForever:create(animate1))
end

return SummerChallengeGainAchievementView