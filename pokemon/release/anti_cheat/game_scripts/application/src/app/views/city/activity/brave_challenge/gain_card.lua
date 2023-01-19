-- @date:   2021-03-15
-- @desc:   勇者挑战---解锁精灵界面

local ViewBase = cc.load("mvc").ViewBase
local BraveChallengeGainCardView = class("BraveChallengeGainCardView", ViewBase)

BraveChallengeGainCardView.RESOURCE_FILENAME = "activity_brave_challenge_gain_card.json"

BraveChallengeGainCardView.RESOURCE_BINDING = {
	["spine"] = "spine",
	["condition"] = {
		varname = "condition",
        binds = {
			{
				event = "effect",
				data = {outline = {color = ui.COLORS.OUTLINE.DEFAULT}}
			},
		}
	},
	["rarityIcon"] = "rarityIcon",
	["conditionTxt"] = {
		varname = "conditionTxt",
        binds = {
			{
				event = "effect",
				data = {outline = {color = ui.COLORS.OUTLINE.DEFAULT}}
			},
		}
    },
    ["imgBg"] = {
		binds = {
			event = "click",
			method = bindHelper.self("onClose"),
		}
	},
	["cardName"] = {
		varname = "cardName",
        binds = {
			{
				event = "effect",
				data = {outline = {color = ui.COLORS.OUTLINE.DEFAULT}}
			},
		}
    },
}

function BraveChallengeGainCardView:onCreate(csvId, cb)
	self.cb = cb

	local val = csv.brave_challenge.cards[csvId]
	local unitId = csv.cards[val.cardID].unitID
	local unitCsv = csv.unit[unitId]

	local wutai = widget.addAnimationByKey(self.spine, "effect/hd.skel", "bg", "effect", 10)
			wutai:xy(300,300)

	local cardSprite = widget.addAnimationByKey(self.spine, unitCsv.unitRes, "spine", "standby_loop", 11)
			:scale(unitCsv.scale * 1.5)
			:xy(300,50)

	self.rarityIcon:texture("common/icon/icon_rarity".. (val.rarity + 1) ..".png")
	self.cardName:text(val.desc)
	self.conditionTxt:text(val.unlockdesc2)

	adapt.oneLineCenterPos(cc.p(1280, self.condition:y()), {self.condition, self.conditionTxt}, cc.p(0, 0))
end

function BraveChallengeGainCardView:onClose()
	self:addCallbackOnExit(self.cb)
	ViewBase.onClose(self)
end

return BraveChallengeGainCardView