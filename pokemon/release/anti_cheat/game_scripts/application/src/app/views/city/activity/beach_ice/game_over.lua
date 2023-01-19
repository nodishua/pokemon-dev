-- @date:   2021-06-09
-- @desc:   沙滩刨冰 -- 游戏结束

local SCORE_TYPE = {	-- (1-完美;2-良好;3-错一个;4-错两个;-5-错三个)
	perfect = 1,
	good = 2,
	bad = 3,
}


local ViewBase = cc.load("mvc").ViewBase
local BeachIceGameOverView = class("BeachIceGameOverView",ViewBase)


BeachIceGameOverView.RESOURCE_FILENAME = "beach_ice_game_over.json"
BeachIceGameOverView.RESOURCE_BINDING = {
    ["text"] = "text",
    ["bg"] = "bg",
    ["bg.box"] = "box",
    ["perfectText"] = "perfectText",
    ["perfectScore"] = "perfectScore",
    ["goodText"] = "goodText",
    ["goodScore"] = "goodScore",
    ["badText"] = "badText",
    ["badScore"] = "badScore",
    ["btnSure"] = {
        binds = {
        event = "touch",
        methods = {ended = bindHelper.self("onClick")},
        },
    }
}

function BeachIceGameOverView:onCreate(params)
    self.cb = params.cb
    self.awards = params.award
    local score = {}
    for k,v in orderCsvPairs(csv.yunying.shaved_ice_base) do
        if v.huodongID == params.huodongID then
            score = v.score
            break
        end
    end
    self.perfectText:text(string.format(gLanguageCsv.perfectNumber, params.perfectNum))
    self.goodText:text(string.format(gLanguageCsv.goodPeople, params.goodNum))
    self.badText:text(string.format(gLanguageCsv.numberOfDefects, params.badNum))
    self.perfectScore:text(string.format(gLanguageCsv.bonusPoints, score[SCORE_TYPE.perfect] * params.perfectNum))
    self.goodScore:text(string.format(gLanguageCsv.bonusPoints, score[SCORE_TYPE.good] * params.goodNum))
    self.badScore:text(string.format(gLanguageCsv.bonusPoints, score[SCORE_TYPE.bad] * params.badNum))
    local all = score[SCORE_TYPE.perfect] * params.perfectNum + score[SCORE_TYPE.good] * params.goodNum +score[SCORE_TYPE.bad] * params.badNum
    self.text:text(string.format(gLanguageCsv.settlementPoints, params.perfectNum + params.goodNum + params.badNum, all))

    local boxSpine = widget.addAnimationByKey(self.bg, "effect/jiedianjiangli.skel", "boxBg", "effect_loop", 10)
        :xy(self.box:x(), self.box:y() - 50)
        :anchorPoint(0.5, 0.5)
    bind.touch(self, self.box, {methods = {ended = function()
        self:onClick()
    end}})
    uiEasy.addVibrateToNode(self, self.box, true)
end

function BeachIceGameOverView:onClick()
    gGameUI:showGainDisplay(self.awards, {
        cb = function()
            if self.cb then
                self.cb()
            end
            ViewBase.onClose(self)
        end
    })
end

return BeachIceGameOverView