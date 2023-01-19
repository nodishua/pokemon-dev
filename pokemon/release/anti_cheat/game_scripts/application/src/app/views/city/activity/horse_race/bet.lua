-- @date 2021-03-15
-- @desc 赛马押注界面
local HorseRaceBet = class("HorseRaceBet", Dialog)

HorseRaceBet.RESOURCE_FILENAME = "horse_race_bet.json"
HorseRaceBet.RESOURCE_BINDING = {
    ["topPanel.btnClose"] = {
        binds = {
            event = "touch",
            methods = {ended = bindHelper.self("onClose")}
        },
    },
    ["player"] = "player",
    ["betPanel.list"] = {
        varname = "bet",
        binds = {
            event = "extend",
            class = "listview",
            props = {
                data = bindHelper.self("itemData"),
                item = bindHelper.self("player"),
                backupCached = false,
                onItem = function(list, node, k, v)
                    local btn = node:get("btnBet")
                    local cost = node:get("cost")
                    local bet = node:get("get")
                    cost:get("num"):text(gCommonConfigCsv.horseRaceBetCost)
                    if v.idx ~= 0 or  (v.status ~= 2 and v.status ~= 5) or v.round ~= "prepare" then
                        cost:setVisible(false)
                        btn:get("bet"):text(gLanguageCsv.horseRaceNoBet)
                        text.addEffect(btn:get("bet"), {color = ui.COLORS.DISABLED.WHITE})
                        cache.setShader(btn, false, "hsl_gray")
                    end
                    if v.idx == k then
                        cost:setVisible(false)
                        btn:setVisible(false)
                        bet:setVisible(true)
                    end
                    local config = csv.cross.horse_race.horse_race_card[v.val.csv_id]
                    local name = node:get("name")
                    local speed = node:get("speed")
                    local stamina = node:get("stamina")
                    local sprintTime = node:get("sprintTime")
                    local sprint = node:get("sprint")
                    name:text(string.format(gLanguageCsv.horseRaceID, k, config.name))
                    speed:text(string.format(gLanguageCsv.horseRaceSpeed, config.speed))
                    stamina:text(string.format(gLanguageCsv.horseRaceStamina, config.stamina))
                    sprintTime:text(string.format(gLanguageCsv.horseRaceSprintTime, config.sprintTime/10))
                    sprint:text(string.format(gLanguageCsv.horseRaceSprint, config.sprintRandom))
                    ccui.ImageView:create(csv.unit[config.unitID].cardShow):addTo(node:get("img"), 1, "img"):alignCenter(node:get("img"):size())
                    --bind.touch(list, node, {methods = {ended = functools.partial(list.onBetClick, k, node)}})
                    bind.touch(list, node:get("btnBet"), {methods = {ended = functools.partial(list.onBetClick, v.val.csv_id, node)}})
                end,
            },
            handlers = {
                onBetClick = bindHelper.self("onBetClick"),
            },
        },
    }

}
function HorseRaceBet:onCreate(activityId, td)
    self.activityId = activityId
    self.data,self.status, self.cb = td()
    self.play = self.data:read().view.play
    self.bet = false
    self:initModel()
    local itemData = {}
    self.itemData = idlertable.new(itemData)
    idlereasy.any({self.yyhuodongs, self.status, self.data}, function(_, yyhuodongs, status, data)
        local yyData = yyhuodongs[activityId] or {}
        local players = {}
        for k, v in pairs(data.view.race_cards) do
            local date = tonumber(time.getTodayStr())
            if yyData and yyData.horse_race.bet_award and yyData.horse_race.bet_award[date] and yyData.horse_race.bet_award[date][self.play] then
                if yyData.horse_race.bet_award[date][self.play][1] or 0 > 0 then
                    self.bet = true
                end
                table.insert(players,{val = v, idx = yyData.horse_race.bet_award[date][self.play][1] + 1, status = status, round = data.view.round})
            else
                table.insert(players,{val = v, idx = 0, status = status,round = data.view.round})
            end
        end
        self.itemData:set(players)
    end)
    Dialog.onCreate(self)
end

function HorseRaceBet:initModel()
    self.yyhuodongs = gGameModel.role:getIdler("yyhuodongs")
    self.rmb = gGameModel.role:getIdler("rmb")
end

function HorseRaceBet:onBetClick(list, index, node)
    local status = self.status:read()
    if self.bet then
        gGameUI:showTip(gLanguageCsv.horseRaceAlreadyBet)
    elseif status == 3 or status == 6 or status == 1 or status == 4 or self.data:read().view.round ~= "prepare" then
        gGameUI:showTip(gLanguageCsv.horseRaceDoNotBet)
    elseif self.rmb:read() < gCommonConfigCsv.horseRaceBetCost then
        uiEasy.showDialog("rmb")
    else
        gGameUI:showDialog({
            content = string.format(gLanguageCsv.horseRaceBetTips, gCommonConfigCsv.horseRaceBetCost),
            btnType = 2,
            isRich = true,
            cb = function()
                gGameApp:requestServer("/game/yy/horse/race/bet", function(tb)
                    self.localData = tb
                end, self.activityId, self.data:read().view.date,self.play,index)
        end})
    end
end


function HorseRaceBet:onClose()
    if self.localData then
        self.data:set(self.localData)
    else
        if self.cb then
            self:addCallbackOnExit(self.cb)
        end
    end
    Dialog.onClose(self)
end

return HorseRaceBet