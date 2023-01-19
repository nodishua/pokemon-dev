-- @date:   2021-03-15
-- @desc:   勇者挑战---选择勋章
local BCAdapt = require("app.views.city.activity.brave_challenge.adapt")

local BADGE_TYPE = {
    normal  = 1,  --普通
    rare    = 2, -- 稀有勋章
    forever = 3, -- 永久勋章
}
local ViewBase = cc.load("mvc").ViewBase
local BraveChallengeSelectBadgeView = class("BraveChallengeSelectBadgeView",ViewBase)

BraveChallengeSelectBadgeView.RESOURCE_FILENAME = "activity_brave_challenge_select_badge.json"

BraveChallengeSelectBadgeView.RESOURCE_BINDING = {
    ["normal"] = "normal",
    ["rare"] = "rare",
    ["rare.title"] = {
        binds = {
			{
				event = "effect",
				data = {outline = {color = cc.c4b(244,144,15, 255), size = 4}}
			},
		}
    },
     ["rare.rarity"] = {
        binds = {
            {
                event = "effect",
                data = {outline = {color = cc.c4b(244,144,15, 255), size = 4}}
            },
        }
    },
    ["forever"] = "forever",
    ["forever.title"] = {
        binds = {
            {
                event = "effect",
                data = {outline = {color = cc.c4b(210,68,73, 255), size = 4}}
            },
        }
    },
    ["forever.rarity"] = {
        binds = {
            {
                event = "effect",
                data = {outline = {color = cc.c4b(210,68,73, 255), size = 4}}
            },
        }
    },
    ["panel1"] = "panel1",
    ["panel2"] = "panel2",
    ["panel3"] = "panel3",
    ["btnSure"] = {
        varname = "btnSure",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onSure")}
		},
	},
}

function BraveChallengeSelectBadgeView:onCreate(data)
    self.activityId = gGameModel.brave_challenge:read("yyID")
    self.selectNum = idler.new(0)
    self.badges = data or {}
    self.selectBadge = {}

    self.panelCell = {
        self.normal,
        self.rare,
        self.forever,
    }

    for kk, vv in ipairs(self.badges) do
        table.insert(self.selectBadge, vv[1])
    end
    local badgeCfg = csv.brave_challenge.badge

    for k, v in ipairs(self.selectBadge) do
        local item = self.panelCell[badgeCfg[v].rarity]:clone():show()
        item:get("title"):text(badgeCfg[v].name)

        beauty.textScroll({
            list = item:get("desc"),
            strs = "#C0x5B545B#" .. badgeCfg[v].desc,
            align = "center",
            fontSize = ui.FONT_SIZE,
            isRich = true,
        })
        item:get("desc"):setItemAlignCenter()
        item:get("icon"):texture(badgeCfg[v].iconResPath)
        item:get("select"):visible(false)
        bind.touch(self, item, {methods = {ended = functools.partial(self.onBadgeClick, self, k)}})

        item:addTo(self["panel"..k], 2, "item")
            :xy(self["panel"..k]:width() / 2, self["panel"..k]:height() / 2)
    end

    idlereasy.when(self.selectNum, function(_, selectNum)
        for i = 1, 3 do
            self["panel"..i]:get("item"):get("select"):visible(false)
        end
        if selectNum ~= 0 then
            self["panel"..selectNum]:get("item"):get("select"):visible(true)
        end
        self.btnSure:setEnabled(selectNum ~= 0)
    end)
end

function BraveChallengeSelectBadgeView:onBadgeClick(idx)
    self.selectNum:set(idx)
end

function BraveChallengeSelectBadgeView:onSure()
    if self.selectNum:read() == 0 then
        gGameUI:showTip(gLanguageCsv.braveChallengeTip05)
        return
    end
    gGameUI:disableTouchDispatch(nil, false)
    local effect = widget.addAnimationByKey(self["panel"..self.selectNum:read()], "effect/xunzhangxuanze.skel", "select", "effect", 100)
        :xy(self["panel"..self.selectNum:read()]:width() / 2,self["panel"..self.selectNum:read()]:height() / 2)
        :scale(2)

    self:runAction(cc.Sequence:create(
        cc.DelayTime:create(0.3),
        cc.CallFunc:create(function()
             gGameUI:disableTouchDispatch(nil, true)
             gGameApp:requestServer(BCAdapt.url("choose"), function(tb)

                    self:onClose()
            end, self.selectBadge[self.selectNum:read()], self.activityId)
         end),
    nil))
end

return BraveChallengeSelectBadgeView