local ViewBase = cc.load("mvc").ViewBase
local SnowBallView = class("SnowBallView",ViewBase)

SnowBallView.RESOURCE_FILENAME = "snow_ball_view.json"
SnowBallView.RESOURCE_BINDING = {
    ["centerPanel.btnGame"] = {
        varname = "btnGame",
        binds = {
            {
                event = "touch",
                methods = {ended = bindHelper.self("onPlayGameClick")},
            },
            {
                event = "extend",
                class = "red_hint",
                props = {
                  state = bindHelper.self("gameRedHint"),
                  onNode = function(node)
                    node:xy(450, 200)
                  end,
                }
            }
        },
    },
    ["centerPanel.textTipTime"] = {
        varname = "textTipTime",
        binds = {
			event = "effect",
            data = {outline = {color = cc.c4b(82, 76, 85, 255), size = 4}}
		}
    },

    ["centerPanel.btnAdd"] = {
        varname = "btnAdd",
        binds = {
            event = "touch",
            methods = {ended = bindHelper.self("onAddClick")},
        },
    },

    ["rightDownPanel.btnAward"] = {
        binds = {
            {
            event = "touch",
            methods = {ended = bindHelper.self("onRewardClick")},
            },
            {
                event = "extend",
                class = "red_hint",
                props = {
                  state = bindHelper.self("awardRedHint"),
                  onNode = function(node)
                    node:xy(200, 200)
                  end,
                }
            }
        },
    },
    ["rightDownPanel.btnRank"] = {
        binds = {
            event = "touch",
            methods = {ended = bindHelper.self("onRankClick")},
        },
    },
    ["rightDownPanel.btnRule"] = {
        binds = {
            event = "touch",
            methods = {ended = bindHelper.self("onRuleClick")},
        },
    },
}

function SnowBallView:onCreate(activityId, data)
    self.activityId = activityId
    gGameUI.topuiManager:createView("title", self, {onClose = self:createHandler("onClose")})
        :init({title = gLanguageCsv.snowBallGame, subTitle = "SNOW GAME"})
    self:initModel()
end

function SnowBallView:initModel()
    self.yyhuodongs = gGameModel.role:getIdler("yyhuodongs")
    self.awardRedHint = idler.new(false)
    self.gameRedHint = idler.new(false)
    self.cost = 0
    self.times = 0
    self.canBuy = false
    self.canPlay = false
    local paramMap = csv.yunying.yyhuodong[self.activityId].paramMap
    idlereasy.when(self.yyhuodongs, function(_, yyhuodongs)
        local yydata = yyhuodongs[self.activityId] or {}
        local info = yydata.info or {
            isGuide = 0,
            buy_times = 0,
            top_point = 0,
            rank = 0,
            times = 0,
            total_point = 0,
            days = 0,
            top_time = 0,
            sign = 0,
            top_role = 0,
        }
        self.roleData = info
        self.snowData = yydata.snowball
        self.times =  paramMap.times + info.buy_times - info.times
        self.canBuy = info.buy_times < paramMap.buyTimes
        self.canPlay = self.times > 0
        local buyCost = paramMap.buyCost
        self.gameRedHint:set(self.times > 0)
        self.awardRedHint:set(false)
        for _,v in pairs(yydata.stamps or {}) do
            if v == 1 then
              self.awardRedHint:set(true)
              break
            end
        end
        self.cost = info.buy_times + 1 <= itertools.size(buyCost) and buyCost[info.buy_times + 1] or buyCost[itertools.size(buyCost)]
        self.textTipTime:text(gLanguageCsv.todayNumber..self.times)
        adapt.oneLineCenterPos(cc.p(310, 280), {self.textTipTime ,self.btnAdd}, {cc.p(5,0)})

        if info.isGuide == 0 then
            self.btnGame:get("Image_36"):texture("activity/snow_ball/txt_xqdbs_ksjx.png")
        else
            self.btnGame:get("Image_36"):texture("activity/snow_ball/txt_xqdbs_ksyx.png")
        end
    end)
end

function SnowBallView:onPlayGameClick()
    if self.canPlay then
        gGameUI:stackUI("city.activity.snow_ball.choose_role", nil, {blackLayer = true}, self.activityId)
    else
        gGameUI:showTip(gLanguageCsv.gameTimesLimit)
    end
end
function SnowBallView:onRewardClick()
    gGameUI:stackUI("city.activity.snow_ball.reward", nil, {blackLayer = true}, self.activityId)
end
function SnowBallView:onRankClick()
    gGameApp:requestServer("/game/rank", function(tb)
		gGameUI:stackUI("city.activity.snow_ball.rank", nil, nil, tb.view, self.roleData)
	end, "snowball", 0, 50)
end

function SnowBallView:onAddClick()
    if self.canBuy == false then
        gGameUI:showTip(gLanguageCsv.buyTimesLimit)
        return
    end
    local strTips = gLanguageCsv.buyGameTimes
    gGameUI:showDialog({
        cb = function()
            if self.cost > gGameModel.role:read("rmb") then
                uiEasy.showDialog("rmb")
            else
                gGameApp:requestServer("/game/yy/snowball/buy", function(tb)
                    gGameUI:showTip(gLanguageCsv.buySuccess)
                end, self.activityId)
            end
        end,
		title = gLanguageCsv.spaceTips,
		content = string.format(strTips, self.cost),
		isRich = true,
		btnType = 2,
		clearFast = true,
		dialogParams = {clickClose = false},
	})
end
function SnowBallView:onRuleClick()
    gGameUI:stackUI("common.rule", nil, nil, self:createHandler("getRuleContext"), {width = 1000})
end

function SnowBallView:getRuleContext(view)
    local c = adaptContext
    local context = {
        c.clone(view.title, function(item)
            item:get("text"):text(gLanguageCsv.rules)
        end),
        c.noteText(110001, 110100),
    }
    return context
end

return SnowBallView