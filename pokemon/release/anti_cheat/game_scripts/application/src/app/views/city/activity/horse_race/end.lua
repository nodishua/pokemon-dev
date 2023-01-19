-- @date 2021-03-15
-- @desc 赛马结算界面
local ViewBase = cc.load("mvc").ViewBase
local HorseRaceEnd = class("HorseRaceEnd", ViewBase)

HorseRaceEnd.RESOURCE_FILENAME = "horse_race_end.json"
HorseRaceEnd.RESOURCE_BINDING = {
    ["replay"] = {
        binds = {
            event = "touch",
            methods = {ended = bindHelper.self("onReplay")}
        },
    },
    ["one"] = "one",
    ["two"] = "two",
    ["three"] = "three",
    ["four"] = "four",
    ["bg1"] = "bg1",
    ["replay.text"] = "text"
}
function HorseRaceEnd:onCreate(activityId, td, cb)
    gGameUI.topuiManager:createView("default", self, {onClose = self:createHandler("onClose")})
        :init({title = gLanguageCsv.horseRace, subTitle = "HORSE RACE"})
    self.activityId = activityId
    self.index = td[2]
    self.cb = cb
    self.data = td[1]
    local one = 1
    self:initModel()
    local itemData = {}
    local players = {"one", "two", "three", "four"}
    for i, v in pairs(players) do
        local rank = players[self.data[i].result] or players[i]
        local config = csv.cross.horse_race.horse_race_card[self.data[i].csv_id]
        text.addEffect(self.text, {outline = {color = cc.c4b(218, 112, 21, 255), size = 3}})
        --ccui.ImageView:create(csv.unit[config.unitID].show):addTo(self[rank]:get("player"), 1, "imgs"):alignCenter(self[rank]:get("player"):size())
        local  card = widget.addAnimation(self[rank]:get("player"), csv.unit[config.unitID].unitRes, "standby_loop", 5)
              :alignCenter(cc.size(self[rank]:get("player"):size().width, self[rank]:get("player"):size().height-300))
              :anchorPoint(cc.p(0.5, 0.5))
              :setScale(2)
        card:setSkin(csv.unit[config.unitID].skin)
        if self.index and self.index > 0 then
            self[v]:get("bet"):setVisible(i == self.data[self.index].result)
        else
            self[v]:get("bet"):setVisible(false)
        end
        if self.data[i].result == 1 then
            one = i
        end
    end
    if self.index and self.index > 0 then
        local cfg = csv.cross.horse_race.horse_race_card[self.data[self.index].csv_id]
        local richText = rich.createByStr(string.format(gLanguageCsv.horseRaceHasBet, csv.unit[cfg.unitID].name, self.data[self.index].result), 50)
            :size(700,300)
            :xy(500,800)
            :addTo(self.bg1, 10)
            :ignoreContentAdaptWithSize(false)
    else
        local cfg = csv.cross.horse_race.horse_race_card[self.data[one].csv_id]
        local richText = rich.createByStr(string.format(gLanguageCsv.horseRaceNotBet, csv.unit[cfg.unitID].name), 50)
            :size(700,300)
            :xy(500,800)
            :addTo(self.bg1, 10)
            :ignoreContentAdaptWithSize(false)
    end
end

function HorseRaceEnd:initModel()
    self.yyhuodongs = gGameModel.role:getIdler("yyhuodongs")
end

function HorseRaceEnd:onReplay()
    local data = self.data
    local activityId = self.activityId
    local index = self.index
    ViewBase.onClose(self)
    gGameUI:stackUI("city.activity.horse_race.match", nil, nil, activityId, {data, index})
end

function HorseRaceEnd:onClose()
    ViewBase.onClose(self)
    gGameUI:goBackInStackUI("city.activity.horse_race.view")
end

return HorseRaceEnd