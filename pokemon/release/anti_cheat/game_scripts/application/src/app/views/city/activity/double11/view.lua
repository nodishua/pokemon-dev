--双十一活动
local ViewBase = cc.load("mvc").ViewBase
local Double11View = class("Double11View",ViewBase)

local CARD_STATUS = {
    CAN_OPEN = 1,
    OPENED = 2,
    GOTTEN_AWARD = -1,
}
Double11View.RESOURCE_FILENAME = "double_11.json"
Double11View.RESOURCE_BINDING = {
    ["leftPanel"] = "leftPanel",
    ["leftPanel.textState"] = {
        varname = "textState",
        binds = {
            {
                event = "effect",
			    data = {outline = {color = cc.c3b(249, 115, 54)}}
            },
            {
                event = "visible",
                idler = bindHelper.self("status"),
                method = function(val)
                    return val == CARD_STATUS.GOTTEN_AWARD
                end,
            },
		}
    },
    ["topPanel.time"] = {
        varname = "textCountDown",
        binds = {
			event = "effect",
			data = {outline = {color = cc.c3b(249, 115, 54)}}
		}
    },
    ["topPanel.textNote"] = {
        binds = {
			event = "effect",
			data = {outline = {color = cc.c3b(249, 115, 54)}}
		}
    },
    ["leftPanel.textRecord"] = {
        binds = {
			event = "effect",
			data = {outline = {color = cc.c3b(249, 115, 54)}}
		}
    },

    ["rightPanel.openPanel.textPlayed"] = {
        binds = {
			event = "effect",
			data = {outline = {color = cc.c3b(238, 78, 50), size = 8}}
		}
    },
    ["topPanel"] = "topPanel",
    ["rightPanel.overPanel"] = "rightPanelOver",
    ["rightPanel.openPanel"] = "rightPanelOpen",
    ["leftPanel.btnRule"] = {
        binds = {
            event = "touch",
            methods = {ended = bindHelper.self("onRule")},
        },
    },
    ["leftPanel.btnTicket"] = {
        varname = "btnTicket",
        binds = {
            {
                event = "touch",
                methods = {ended = bindHelper.self("onTicketClick")},
            },
        },
    },
    ["leftPanel.item"] = "leftItem",
    ["leftPanel.list"] = {
        binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("record"),
				item = bindHelper.self("leftItem"),
				padding = 10,
                onItem = function(list, node, k, v)
                    local str =""
                    if v.id  then
                        local itemName = dataEasy.getCfgByKey(v.id).name
                        str = string.format(gLanguageCsv.double11AwardText, v.index, itemName,v.num)
                    else
                        str = string.format(gLanguageCsv.double11NotGame, v.index)
                    end
                    local richText = rich.createByStr(str, 40)
                        :addTo(node, 10)
                        :xy(2, node:height()/2)
                        :anchorPoint(cc.p(0, 0.5))
                        :formatText()
                end,
                dataOrderCmp = function (a, b)
					return a.index > b.index
				end,
			},
		}
    },
    ["rightPanel.openPanel.btnGame"] = {
        binds = {
            event = "touch",
            methods = {ended = bindHelper.self("onPlayGameClick")},
        },
    },
}

local function addVibrateToNode(view, node, state, tag)
    local steps = {
        {t1 = 0.1, t2 = 0.1, rotation = 7,},
        {t1 = 0.1, t2 = 0.1, rotation = -7,},
        {t1 = 0.1, t2 = 0.1, rotation = 7,},
        {t1 = 0.1, t2 = 0.1, rotation = -7,},
    }
    tag = tag or node:getName().."toRotationScheduleTag"
    if state then
        view:enableSchedule():schedule(function (dt)
            if tolua.isnull(node) then
                view:enableSchedule():unSchedule(tag)
                return
            end
            local seq = transition.executeSequence(node)
            for _,t in pairs(steps) do
                seq:rotateTo(t.t1, t.rotation)
            end
            seq:rotateTo(0.1, 0):done()
        end, 1, nil, tag)
    else
        view:enableSchedule():unSchedule(tag)
    end
end

function Double11View:onCreate(activityId, data)
    self.activityId = activityId
    gGameUI.topuiManager:createView("title", self, {onClose = self:createHandler("onClose")})
        :init({title = gLanguageCsv.double11, subTitle = gLanguageCsv.double11Subtitle})
    self:initGameCfg()
    self:initModel()
    self:initGameStatus()
    self:initData()
    self:initCountDown()
    self.lotteryInfo = data.view.lotteryInfo
end

function Double11View:initGameCfg()
    self.gameCfg = {}
    for k, cfg in orderCsvPairs(csv.yunying.double11_game) do
        if cfg.huodongID == csv.yunying.yyhuodong[self.activityId].huodongID then
            self.gameCfg[cfg.game] = {itemId = cfg.itemID, csvId = k}
        end
    end
end

function Double11View:initModel()
    self.yyhuodongs = gGameModel.role:getIdler("yyhuodongs")
    self.played = idler.new(false)
    self.status = idler.new()
    self.nowGameIndex = idler.new(0)   --现在的场次
    self.showIndex = idler.new(1)   --显示预告的场次
    self.gameOver = idler.new(false)  --游戏是否结束
    self.record = idlers.new()
end

function Double11View:initData()
    idlereasy.any({self.yyhuodongs, self.nowGameIndex},function(_, yyhuodong, nowIndex)
        local yydata = yyhuodong[self.activityId] or {}
        local data = yydata.double11 or {}
        local record = {}
        for i = 1, #self.gameCfg do
            local csvId = self.gameCfg[i].csvId
            if i <= nowIndex then
                if data[csvId] then
                    record[i] = {index = i, id = self.gameCfg[i].itemId, num = data[csvId].red_packet_num}
                else
                    record[i] = {index = i}
                end
            end
        end
        self.record:update(record)
        local index = nowIndex
        if nowIndex > #self.gameCfg then
            index = #self.gameCfg
        end
        local csvId = self.gameCfg[index].csvId
        if data[csvId] then
            self.played:set(true)
            self.status:set(self.gameCfg[index].card_status)
        else
            self.played:set(false)
        end
        addVibrateToNode(self, self.btnTicket, data[csvId] and data[csvId].card_status == CARD_STATUS.CAN_OPEN, "double11CardStatus")
    end)

    local yyCfg = csv.yunying.yyhuodong[self.activityId]
    local gameTime = yyCfg.paramMap.gameTime
    idlereasy.any({self.nowGameIndex, self.gameOver, self.showIndex, self.played},function(_, nowGameIndex, gameOver, showIndex, played)
        if gameOver or nowGameIndex > #self.gameCfg then
            self.rightPanelOpen:hide()
            self.rightPanelOver:show()
            return false
        else
            self.rightPanelOpen:show()
            self.rightPanelOver:hide()
            local oneDayCount = self.oneDayCount
            local day = math.ceil(showIndex / oneDayCount) --第几天
            local todayIndex = showIndex % oneDayCount == 0 and oneDayCount or showIndex % oneDayCount --当天的第几场
            local hour1, min1 = time.getHourAndMin(gameTime[todayIndex][1])
            local hour2, min2 = time.getHourAndMin(gameTime[todayIndex][2])
            local timeStr = string.format("%02d:%02d--%02d:%02d", hour1, min1, hour2,min2)
            self.rightPanelOpen:get("textTipTime"):text(string.format(gLanguageCsv.double11Time, showIndex) .. timeStr)
            self.rightPanelOpen:get("imgAward"):texture(dataEasy.getCfgByKey(self.gameCfg[showIndex].itemId).icon)
            bind.click(self, self.rightPanelOpen:get("imgAward"), {method = function()
				local params = {key = self.gameCfg[showIndex].itemId}
				gGameUI:showItemDetail(self.rightPanelOpen:get("imgAward"), params)
            end})

            if played == true and showIndex == nowGameIndex then
                self.rightPanelOpen:get("btnGame"):hide()
                self.rightPanelOpen:get("textPlayed"):show()
            else
                self.rightPanelOpen:get("btnGame"):show()
                self.rightPanelOpen:get("textPlayed"):hide()
            end
        end
    end)
end

function Double11View:initGameStatus()
    local yyCfg = csv.yunying.yyhuodong[self.activityId]
    local gameTime = yyCfg.paramMap.gameTime
    self.canPlay = idler.new(false)    --是否可以游戏

    local beginDateStamp = time.getNumTimestamp(yyCfg.beginDate, 0, 0)
    local stamps = {}
    local oneDayCount = 0
    for index, times in orderCsvPairs(gameTime) do
        local hour1, min1 = time.getHourAndMin(times[1], true)
        local hour2, min2 = time.getHourAndMin(times[2], true)
        stamps[index] = {[1] = hour1 * 3600 + min1 * 60, [2] = hour2 * 3600 + min2 * 60}
        oneDayCount = oneDayCount + 1
    end
    self.oneDayCount = oneDayCount
    local timeStamp = {} --每场的时间戳
    for i = 1, #self.gameCfg do
        local day = math.ceil(i / oneDayCount) --第几天
        local index = i % oneDayCount == 0 and oneDayCount or i % oneDayCount --当天的第几场
        local a = stamps[index][1]
        timeStamp[i] = {
            beginStamps = beginDateStamp + (day -1) * 24 * 3600 + stamps[index][1],
            endStamps = beginDateStamp + (day - 1) * 24 * 3600 + stamps[index][2]}
    end

    local function getNowIndex(  )
        local endTime = timeStamp[#self.gameCfg].endStamps
        local nowTime = time.getTime()
        if nowTime > endTime then
            self.nowGameIndex:set(#self.gameCfg + 1)
            self.gameOver:set(true)
        else
            local nowIndex = 1
            local showIndex = 1
            for index, times in ipairs(timeStamp) do
                if nowTime >= times.beginStamps then
                    nowIndex = index
                end
                if nowTime >= times.endStamps then
                    showIndex = index + 1
                end
            end

            if nowTime >= timeStamp[nowIndex].beginStamps and nowTime < timeStamp[nowIndex].endStamps then
                self.canPlay:set(true)
            else
                self.canPlay:set(false)
            end
            self.nowGameIndex:set(nowIndex)
            self.showIndex:set(showIndex)
        end
    end
    getNowIndex()
    self:enableSchedule():schedule(getNowIndex, 1 ,0)
end

function Double11View:onRule()
    gGameUI:stackUI("common.rule", nil, nil, self:createHandler("getRuleContext"), {width = 1000})
end

function Double11View:getRuleContext(view)
    local c = adaptContext
    local context = {
        c.clone(view.title, function(item)
            item:get("text"):text(gLanguageCsv.rules)
        end),
        c.noteText(152),
        c.noteText(108001, 108100),
    }
    return context
end

function Double11View:onTicketClick()
    local huodongID = csv.yunying.yyhuodong[self.activityId].huodongID
    if self.nowGameIndex:read() == 0 then
        gGameUI:showTip(gLanguageCsv.double11GameTips)
        return
    end
    local nowIndex = self.nowGameIndex:read()
    local index = nowIndex
    if nowIndex > #self.gameCfg then
        index = #self.gameCfg
    end
    local csvId = self.gameCfg[index].csvId
    local data = self.lotteryInfo[csvId]
    gGameUI:stackUI("city.activity.double11.lottery", nil, nil, huodongID, self.nowGameIndex:read(), self.activityId, data, csvId)
end

function Double11View:onPlayGameClick()
    if self.canPlay:read() == false then
        gGameUI:showTip(gLanguageCsv.double11GameTips)
        return false
    end
    gGameUI:stackUI("city.activity.double11.game", nil, nil, self.activityId, self.nowGameIndex:read())
end

--倒计时
function Double11View:initCountDown()
	local textTime = self.textCountDown
	local yyCfg = csv.yunying.yyhuodong[self.activityId]
	local hour, min = time.getHourAndMin(yyCfg.endTime)
    local endTime = time.getNumTimestamp(yyCfg.endDate,hour,min)
    bind.extend(self, textTime, {
		class = 'cutdown_label',
		props = {
			endTime = endTime,
			strFunc = function(t)
				return t.str
			end,
			endFunc = function()
				textTime:text(gLanguageCsv.activityOver)
			end,
		}
	})
end
return Double11View