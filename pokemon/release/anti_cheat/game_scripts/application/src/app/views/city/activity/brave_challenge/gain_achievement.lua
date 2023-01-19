-- @date:   2021-03-15
-- @desc:   勇者挑战---成就称号界面

local ViewBase = cc.load("mvc").ViewBase
local BraveChallengeGainAchievementView = class("BraveChallengeGainAchievementView", ViewBase)

BraveChallengeGainAchievementView.RESOURCE_FILENAME = "activity_brave_challenge_gain_achievement.json"
BraveChallengeGainAchievementView.RESOURCE_STYLES = {
    blackLayer = true,
    clickClose = true,
}
BraveChallengeGainAchievementView.RESOURCE_BINDING = {
    ["icon"] = "icon",
    ["item"] = "item",
    ["imgBg"] = {
		binds = {
			event = "click",
			method = bindHelper.self("onClose"),
		}
    },
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

function BraveChallengeGainAchievementView:onCreate(params)
    self.sendQuit = params.sendQuit
    self.got = params.got

    local itemPanel = {}
    for id, num in csvPairs(params.itemData) do
        local item = self.item:clone():show()
        item:addTo(self.item:parent(), 2)

        bind.extend(self, item, {
            class = "icon_key",
            props = {
                data = {
                    key = id,
                    num = num,
                }
            },
        })

        table.insert(itemPanel, item)
        item:get("got"):visible(not params.got)
    end

    adapt.oneLineCenterPos(cc.p(self.gain:x(), 280), itemPanel, cc.p(5, 0))
    self.gain:visible(false)
    local title = widget.addAnimationByKey(self.icon, params.lastAnimation, "bg", "effect_loop", 10)
			    :xy(100,0)
                :scale(2)
    local wutai = widget.addAnimationByKey(self.icon, "effect/hd.skel", "wutai", "effect", 0)
                :xy(100,0)

end


function BraveChallengeGainAchievementView:onClose()
    self:addCallbackOnExit(functools.partial(self.sendQuit, true))
    ViewBase.onClose(self)
end

return BraveChallengeGainAchievementView