-- @date 2021-03-12
-- @desc 赛马主界面
local ViewBase = cc.load("mvc").ViewBase
local HorseRaceView = class("HorseRaceView", ViewBase)
HorseRaceView.RESOURCE_FILENAME = "horse_race_main.json"
HorseRaceView.RESOURCE_BINDING = {
    ["bg2"] = "bg2",
    ["bg1"] = "bg1",
    ["rightPanel.textTips"] = "textTips",
    ["bg1.textTip1"] = "textTip1",
    ["bg2.textTip2"] = "textTip2",
    ["bg2.time"] = "time",
    ["bg2.minute"] = "minute",
    ["leftPanel.btnRank"] = {
        varname = "btnRank",
        binds = {
            event = "touch",
            methods = { ended = bindHelper.self("onRank") }
        }
    },
    ["leftPanel.btnHistory.history"] = "history",
    ["rightPanel.btnPoint.point"] = "point",
    ["rightPanel.btnBet.bet"] = "bet",
    ["leftPanel.btnRank.rank"] = "rank",
    ["leftPanel.btnRule.rule"] = "rule",
    ["leftPanel.btnHistory"] = {
        varname = "btnRank",
        binds = {
            {
                event = "touch",
                methods = { ended = bindHelper.self("onShowRaceRecord") }
            },{
                event = "extend",
                class = "red_hint",
                props = {
                    specialTag = "horseRaceBetAward",
                    listenData = {
                        activityId = bindHelper.self("activityId"),
                    },
                    onNode = function (node)
                        node:xy(120, 120)
                    end
                }
            }
        }
    },
    ["leftPanel.btnRule"] = {
        varname = "btnRank",
        binds = {
            event = "touch",
            methods = { ended = bindHelper.self("onShowRule") }
        }
    },
    ["rightPanel.btnBet"] = {
        varname = "btnRank",
        binds = {
            {
                event = "touch",
                methods = { ended = bindHelper.self("onBetClick") }
            },{
                event = "extend",
                class = "red_hint",
                props = {
                specialTag = "horseRaceCanBet",
                listenData = {
                    activityId = bindHelper.self("activityId"),
                },
                onNode = function (node)
                    node:xy(120, 120)
                end
                }
            }
        }
    },
    ["rightPanel.btnPoint"] = {
        varname = "btnRank",
        binds = {
            {
                event = "touch",
                methods = { ended = bindHelper.self("onPointReward") }
            },{
                event = "extend",
                class = "red_hint",
                props = {
                    specialTag = "horseRaceAward",
                    listenData = {
                        activityId = bindHelper.self("activityId"),
                    },
                    onNode = function (node)
                        node:xy(120, 120)
                    end
                }
            }
        }

    },
    ["player"] = "player",
    ["listPlayer"] = {
        varname = "btnRank",
        binds = {
            event = "extend",
            class = "listview",
            props = {
                data = bindHelper.self("itemData"),
                item = bindHelper.self("player"),
                backupCached = false,
                onItem = function(list, node, k, v)
                    local config = csv.cross.horse_race.horse_race_card[v.val.csv_id]
                    local info = node:get("bg")
                    local bet = node:get("bet"):visible(v.idx)
                    local name = info:get("textName")
                    local number = info:get("number")
                    local marge = {75, 100, 50 , 50}
                    local leftMarge = {0, 0, 50 , 50}
                    local per = node:get("per")
                    if v.status == 1 or v.status == 4 then
                        per:xy(per:x() - leftMarge[k],per:y()+marge[k])
                        info:setVisible(false)
                    else
                        info:setVisible(true)
                    end
                    text.addEffect(name, { outline = { color = ui.COLORS.OUTLINE.DEFAULT, size = 5} })
                    name:text(config.name)
                    local richText = rich.createByStr(string.format(gLanguageCsv.horseRacePerson, v.val.bet_count), 40)
                        :anchorPoint(cc.p(0.5, 0.5))
                        :xy(cc.p(info:size().width/2, 35))
                        :addTo(info,2)
                    local card = widget.addAnimation(node:get("per"), csv.unit[config.unitID].unitRes, "standby_loop", 5)
                        :alignCenter(cc.size(node:get("per"):size().width, node:get("per"):size().height-300))
                        :anchorPoint(cc.p(0.5, 0.5))
                        :setScale(2)
                    card:setSkin(csv.unit[config.unitID].skin)
                    --ccui.ImageView:create(csv.unit[config.unitID].show):addTo(node:get("per"), 1, "img"):alignCenter(node:get("per"):size())
                    bind.touch(list, node, {methods = {ended = functools.partial(list.onBetClick, k, node)}})
                    --bind.touch(list, node:get("per"), {methods = {ended = functools.partial(list.onBetClick, k, node)}})
                end,
            },
            handlers = {
                onBetClick = bindHelper.self("onBetClick"),
            },
        },
    },
    ["replay"] = {
        varname = "replay",
        binds = {
            event = "touch",
            methods = { ended = bindHelper.self("onReplay") }
        }
    },
    ["replay.text"] ="replayText",
    ["podium"] = "podium",
    ["ruleRankTitle"] = "ruleRankTitle",
    ["ruleRankItem"] = "ruleRankItem"
}
function HorseRaceView:onCreate(activityId, td)
    self.activityId = activityId
    self.data = idlertable.new(td)
    gGameUI.topuiManager:createView("default", self, {onClose = self:createHandler("onClose")})
           :init({title = gLanguageCsv.horseRace, subTitle = "HORSE RACE"})
    self:initModel()
    self:setInfo()
    self:enableSchedule()
    local itemData = {}
    self.request = 0
    self.itemData = idlertable.new(itemData)
    self.play = idler.new(1)
    self.status = idler.new(1)
    self.index = 0
    self:gameStatus()
    idlereasy.any({self.play, self.yyhuodongs, self.status, self.data},function(_, play, yyhuodongs, status, data)
        local yyData = yyhuodongs[activityId]
        local items = {}
        local turn = data.view.play
        local place = {2,1,3,4}
        if not data.view or not data.view.race_cards or itertools.size(data.view.race_cards) <= 0 then
            self.textTip2:text(gLanguageCsv.horseRaceNoMatch)
            self.podium:visible(false)
            self.time:visible(false)
            self.minute:visible(false)
            adapt.oneLineCenterPos(cc.p((lens + 450)/2 , 78),{self.textTip2,self.time,self.minute}, cc.p(10,0))
        else
            for k, v in pairs(data.view.race_cards) do
                local date = tonumber(time.getTodayStr())
                local betRewards = {}
                if yyData and yyData.horse_race and yyData.horse_race.bet_award then
                    betRewards = yyData.horse_race.bet_award
                end
                local rank = k
                if status == 4 or status == 1 then
                    rank = place[v.result ~= 0 and v.result or k]
                end
                if betRewards[date] and betRewards[date][turn] then
                    self.index = betRewards[date][turn][1] + 1
                    items[rank] = {val = v, idx = betRewards[date][turn][1] + 1 == k, status = status}
                    --table.insert(items,{val = v, idx = betRewards[date][turn][1] + 1 or 0})
                else
                    items[rank] = {val = v, idx = false, status = status}
                    --table.insert(items,{val = v, idx = 0})
                end
            end
            if status == 1 or status == 4 then
                self.podium:setVisible(true)
            else
                self.podium:setVisible(false)
            end
            play = turn
            --local status = 4
            self:timeCutdown(turn, self.timeData[status],status)
            self.itemData:set(items)
            local lens =  self.textTip2:size().width + self.time:size().width + self.minute:size().width
            if status == 4 or status == 1 then
                self.replay:setVisible(true)
            else
                self.replay:setVisible(false)
            end
            self.bg2:size(lens + 450, self.bg2:size().height)
            self.textTip2:x(lens/2 + 100)
            adapt.oneLineCenterPos(cc.p((lens + 450)/2 , 78),{self.textTip2,self.time,self.minute}, cc.p(10,0))
            if data.view.round == "closed" then
                self:inMatch(data)
            end
        end
    end)
    self:timeClock()
    self.bg1:scaleY(0.1)
    transition.executeSequence(self.bg1)
        :easeBegin("ELASTICOUT")
            :scaleTo(2, 1, 1)
        :easeEnd()
        :done()
end

function HorseRaceView:timeClock()
    local lastRequestTime = 0
    self.errorTime = nil
    self:unSchedule("clock")
    self:schedule(function()
        if not self.data:read().view or not self.data:read().view.race_cards then
            return
        end
        local status = self.status:read()
        local turn = self.data:read().view.play or 1
        local round = self.data:read().view.round
        if (status == 4 and round ~= "closed") or (status == 1  and round ~= "closed") or (status == 2  and round ~= "prepare") or (status == 5  and round ~= "prepare") then
            if (self.date[turn*2] - time.getTime()) < 0 and (status == 3 or status == 1) then
                -- 异常卡秒，连续请求间隔 10
                if time.getTime() - lastRequestTime > 10 then
                    self.errorTime = 10
                    lastRequestTime = time.getTime()
                    if self.request ~= 1 and self:isActivityOpen() then
                        self.request = 1
                        gGameApp:requestServer("/game/yy/horse/race/main", function(tb)
                            if tb.view.round == "closed" then
                                self.data:set(tb)
                            end
                            self.request = 0
                        end, self.activityId)
                    end
                end
            end
        else
            self.errorTime = nil
            return
        end
        return
    end, 1, 0, "clock")
end

function HorseRaceView:onBetClick()
    gGameUI:stackUI("city.activity.horse_race.bet", nil, nil, self.activityId, self:createHandler("returnDate"))
end

function HorseRaceView:returnDate()
    local callBackFun = function()
        if self:isActivityOpen() then
            gGameApp:requestServer("/game/yy/horse/race/main", function(tb)
                self.data:set(tb)
            end, self.activityId)
        end
    end
    return self.data, self.status, callBackFun
end

function HorseRaceView:setInfo()
    local yyEndtime = gGameModel.role:read("yy_endtime")[self.activityId]
    local times = csv.cross.horse_race.base[1].time
    local cfg = csv.yunying.yyhuodong[self.activityId]
    local endDate = time.getDate(math.floor(yyEndtime))
    endDate.hour = cfg.endTime / 100
    endDate.min = cfg.endTime % 100
    --self.textTips:text(string.format(gLanguageCsv.horseRaceEndTime, endDate.year, endDate.month, endDate.day, endDate.hour, endDate.min))
    self.textTip1:text(string.format(gLanguageCsv.horseRaceActive, times[2], times[4]))
    text.addEffect(self.rank, {outline = { color = cc.c4b(109, 105, 109, 255), size = 3}})
    text.addEffect(self.bet, {outline = { color = cc.c4b(109, 105, 109, 255), size = 3}})
    text.addEffect(self.point, {outline = { color = cc.c4b(109, 105, 109, 255), size = 3}})
    text.addEffect(self.history, {outline = { color = cc.c4b(109, 105, 109, 255), size = 3}})
    text.addEffect(self.rule, {outline = { color = cc.c4b(109, 105, 109, 255), size = 3}})
    text.addEffect(self.replayText, {outline = {color = cc.c4b(218, 112, 21, 255), size = 3}})
    text.addEffect(self.textTips, {color=ui.COLORS.WHITE, outline={color=ui.COLORS.BLACK, size = 5}})
    local countdown = math.floor(yyEndtime) - time.getTime()
    bind.extend(self, self.textTips, {
        class = 'cutdown_label',
        props = {
            time = countdown,
            strFunc = function(t)
                return string.format(gLanguageCsv.horseRaceEndTime, t.str)
            end,
            endFunc = function()
                self.textTips:text(gLanguageCsv.activityOver)
            end,
        }
    })
end

function HorseRaceView:gameStatus()
    local times = csv.cross.horse_race.base[1].time
    local today = tonumber(time.getTodayStr())
    -- 1 20 - 次日05， 2 ，05-11.57 ， 3 11.57-12, 4 12-13,5 13-19.57,6 19.57-20
    self.date = {time.getNumTimestamp(today,times[1]), time.getNumTimestamp(today,times[2]), time.getNumTimestamp(today,times[3]), time.getNumTimestamp(today,times[4])}
    local mins = 60 * 3
    local timeData = {{self.date[4],self.date[1] + 86400}, {self.date[1], self.date[2] - mins}, {self.date[2]-mins, self.date[2]}, {self.date[2], self.date[3]}, {self.date[3], self.date[4] - mins}, {self.date[4] - mins, self.date[4]}}
    for i, v in pairs(timeData) do
        if v[1] <= time.getTime() and v[2] > time.getTime() then
            self.status:set(i)
        end
    end
end

function HorseRaceView:onShowRule()
    gGameUI:stackUI("common.rule", nil, nil, self:createHandler("getRuleContext"), {width = 1500})
end

function HorseRaceView:onReplay()
    gGameUI:stackUI("city.activity.horse_race.match", nil, nil, self.activityId, {self.data:read().view.race_cards, self.index})
end

function HorseRaceView:getRuleContext(view)
    local c = adaptContext
    local context = {
        c.clone(view.title, function(item)
            item:get("text"):text(gLanguageCsv.rules)
        end),
        c.noteText(121001,121101),
        c.clone(self.ruleRankTitle)
    }
	local huodongID = csv.yunying.yyhuodong[self.activityId].huodongID
    for k, v in orderCsvPairs(csv.yunying.horse_race_bet_award) do
		if v.huodongID == huodongID then
            table.insert(context, c.clone(self.ruleRankItem, function(item)
                local childs = item:multiget("textRuleRank", "textRuleScore", "list", "rank")
                local rank = childs.rank:get("rank" .. v.rank)
                if rank then
                    rank:visible(true)
                    childs.textRuleRank:visible(false)
                else
                    childs.textRuleRank:text(v.rank)
                end
                childs.textRuleScore:text(v.point)
                uiEasy.createItemsToList(view, childs.list, v.award)
            end))
        end
	end
    return context
end
function HorseRaceView:onShowRaceRecord()
    gGameUI:stackUI("city.activity.horse_race.race_record", nil, nil, self.activityId, self:createHandler("returnData"))
end

function HorseRaceView:initModel()
    self.yyOpen = gGameModel.role:getIdler('yy_open')
    self.yyhuodongs = gGameModel.role:getIdler("yyhuodongs")
    self.yyEndtime = gGameModel.role:read("yy_endtime")[self.activityId]
    local today = tonumber(time.getTodayStr())
    local times = csv.cross.horse_race.base[1].time
    local mins = 60 * 3
    local fun = function(cb)
        if self.request ~= 1 and self:isActivityOpen() then
            self.request = 1
            performWithDelay(self, function()
                gGameApp:requestServer("/game/yy/horse/race/main", function(tb)
                    self.data:set(tb)
                    if cb then
                        cb()
                    end
                    self.request = 0
                end, self.activityId)
            end,  1)
        end
    end
    self.timeData = {{time = time.getNumTimestamp(today,times[1]) + 86400,string = gLanguageCsv.horseRaceNextOpenTip, cb = fun},
        {time = time.getNumTimestamp(today,times[2]) - mins, string = gLanguageCsv.horseRaceTip},
        {time = time.getNumTimestamp(today,times[2]),string = gLanguageCsv.horseRaceStartTip, str = gLanguageCsv.horseRaceBetClose, cb = fun},-- 强制推送
        {time = time.getNumTimestamp(today,times[3]),string = gLanguageCsv.horseRaceOpenTip, cb = fun},
        {time = time.getNumTimestamp(today,times[4]) - mins,string = gLanguageCsv.horseRaceTip},
        {time = time.getNumTimestamp(today,times[4]),string = gLanguageCsv.horseRaceStartTip, str = gLanguageCsv.horseRaceBetClose, cb = fun}}   -- 强制推送
end

function HorseRaceView:timeCutdown(gameNum, datas, status)  -- 押注倒计时
    local times = csv.cross.horse_race.base[1].time
    local dt = math.floor(datas.time - time.getTime())
    if status == 1 then
        local date = time.getDate(math.floor(self.yyEndtime - 86400))
        local t = {
            year = date.year,
            month = date.month,
            day = date.day,
            hour = times[4] or 0,
            min =  0,
            sec = 0
        }
        local nowTime = time.getTimestamp(t)
        if datas.time - time.getTime() >= 33000 then  -- > 9小时 跨天了
            dt = math.floor(datas.time - 86400 - time.getTime())
        end

        if time.getTime() > nowTime then
            self.textTip2:text(gLanguageCsv.horseRaceOver)
        else
            self.textTip2:text(string.format(datas.string, times[1]))
        end
        self.time:text("")
        self.time:setVisible(false)
        self.minute:text("")
        self.minute:setVisible(false)
        --self.time:setVisible(false)
    elseif status == 4 then
        self.textTip2:text(string.format(datas.string, times[3]))
        self.time:text("")
        self.time:setVisible(false)
        self.minute:text("")
        self.minute:setVisible(false)
        --self.time:setVisible(false)
    else
        if datas.str then
            self.minute:text(string.format(datas.str, gameNum))
            self.minute:setVisible(true)
        else
            self.minute:text("")
            self.minute:setVisible(true)
        end
        self.textTip2:text(string.format(datas.string, gameNum))
        --self.time:setVisible(true)
        self.time:text("")
        self.time:setVisible(true)
    end
    if self.errorTime then
        dt = self.errorTime
    end
    --self:enableSchedule()--:unSchedule("cutdown")
    self:unSchedule("cutdown")
    self.time:text(time.getCutDown(dt).str)
    self:schedule(function()
        dt = dt - 1
        if dt < 0 then
            if not self.errorTime then
                if datas.cb then
                    local callBack = function()
                        local status = self.status:read()%6
                        self.status:set(status + 1)
                        if status + 1 == 5  or status + 1 == 2 then
                            self.play:set(self.data:read().view.play)
                        end
                    end
                    datas.cb(callBack)
                else
                    local status = self.status:read()%6
                    self.status:set(status + 1)
                    if status + 1 == 5  or status + 1 == 2 then
                        self.play:set(self.data:read().view.play)
                    end
                end
            end
            dt = math.max(dt,0)
        end
        self.time:text(time.getCutDown(dt).str)
    end, 1, 0, "cutdown")
end

function HorseRaceView:onRank()
    gGameApp:requestServer("/game/yy/horse/race/rank", function(tb)
        gGameUI:stackUI("city.activity.horse_race.rank", nil, nil, self.activityId, tb.view)
    end, self.activityId)
end

function HorseRaceView:inMatch(data)
    local date = data.view.date
    local play = data.view.play
    local match = userDefault.getForeverLocalKey("horseRaceData", {})
    local today = tonumber(time.getTodayStr())
    local times = csv.cross.horse_race.base[1].time
    local timeData = {{time.getNumTimestamp(today,times[2]), time.getNumTimestamp(today,times[2]) + 30*60}, {time.getNumTimestamp(today,times[4]), time.getNumTimestamp(today,times[4]) + 60 * 30}}
    for i, v in pairs(timeData) do
        if v[1] <= time.getTime() and v[2] > time.getTime() and (self.status:read() == 4 or self.status:read() == 1) then
            if not match[date] or not match[date][play] then
                if not match[date] then
                    match[date] = {}
                    match[date][play] = 1
                    userDefault.setForeverLocalKey("horseRaceData", match)
                else
                    match[date][play] = 1
                    userDefault.setForeverLocalKey("horseRaceData", match)
                end
                gGameUI:goBackInStackUI("city.activity.horse_race.view")
                gGameUI:stackUI("city.activity.horse_race.match", nil, nil, self.activityId, {self.data:read().view.race_cards, self.index, true})
            end
        end
    end
end

function HorseRaceView:onPointReward()
    gGameUI:stackUI("city.activity.horse_race.point_reward", nil, nil, self.activityId)
end

function HorseRaceView:returnData()
    return self.data, self.status
end

function HorseRaceView:isActivityOpen()
    for i, v in pairs(self.yyOpen:read()) do
        if v == self.activityId then
            return true
        end
    end
    return false
end

return HorseRaceView