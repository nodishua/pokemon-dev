-- @desc: 	activity-充值大转盘(又名充值夺宝)
-- @date:	2019-12-30 15:40:54

-- 转盘最大数量
local MAX_REWARD_NUMS = 8

-- 抽奖类型 free免费 once 单抽 all 全抽
local DRAW_TYPE = {
    free = "free",
    once = "once",
    all = "all",
}

-- 抽奖动画时间：free/once 2s all 3s
local ANI_TIME = {
    free = 2,
    once = 2,
    all = 3,
}
-- 抽奖基础圈数旋转完成后，到指定奖励需要的时间
local AIN_TIME_LESS = 1

-- 抽奖转盘基础旋转圈数 free/once 2圈 all 10圈
local ANI_ROTATION = {
    free = 2*360,
    once = 2*360,
    all = 10*360,
}

-- 定时器tag count活动倒计时 report 奖励滚动播报
local TAG = {
    count = 1,
    report = 2
}

-- @params message 服务器数据 message[1] 玩家你猜 message[2] 玩家获得奖励信息
local function initItem(node, info, add)
    -- 对服务器数据进行重组 这里的奖励目前都按只有一个的逻辑处理
    local message = info.message
    local newMessage = dataEasy.getItemData(message[2])
    local cfg, num
    if newMessage[1].key == "card" then
        cfg = csv.cards[newMessage[1].num.id]
        num = 1
    else
        cfg = dataEasy.getCfgByKey(newMessage[1].key)
        num = newMessage[1].num
    end

    -- TODO 后续再整理一下代码
    local txtMessage = node:get("message")
    -- lineSpacing 行间距
    local lineSpacing = node:height() - txtMessage:height()
    local strs = string.format(gLanguageCsv.rechargeWheelReport, message[1], cfg.name, num)
    local list = beauty.textScroll({
        size = cc.size(txtMessage:width(),  node:height()),
        strs = strs,
        isRich = true,
        verticalSpace = lineSpacing
    })

    -- 行数判断(目前仅支持两行判断)
    local lineNums = 1
    -- 这里这样判断的目的是实际生成的单行list innerContainerSize若超过node的height则判定为两行
    if list:getInnerContainerSize().height > list:height() then
        lineNums = 2
    end

    -- add true 表示需要添加到node上，false表示不需要，仅需要返回lineNums
    if not add then
        return lineNums
    end

    txtMessage:hide()
    list:height(list:getInnerContainerSize().height)
    node:height(node:height()*lineNums)
    list:anchorPoint(0, 0.5)
        :xy(0, node:height()/2)
        :addTo(node)
    list:setTouchEnabled(false)
end

local SHOW_REPORT_NUMS = 8 -- 当前播报显示区域数量
local REPORT_MAX_NUMS = 20 -- 当前播放最大展示数量

local ActivityRechargeWheelView = class("ActivityRechargeWheelView", Dialog)
ActivityRechargeWheelView.RESOURCE_FILENAME = "activity_recharge_wheel.json"
ActivityRechargeWheelView.RESOURCE_BINDING = {
    ["btnClose"] = {
        binds = {
            event = "touch",
            methods = {ended = bindHelper.self("onClose")}
        },
    },
    ["wheelPanel"] = "wheelPanel",
    ["wheelPanel.wheel"] = "wheel",
    ["wheelPanel.wheelTimeTitle"] = {
        varname = "wheelTimeTitle",
        binds = {
            event = "effect",
            data = {outline = {color = cc.c4b(128, 64, 51, 255), size = 3}},
        },
    },
    ["wheelPanel.time"] = {
        varname = "wheelTime",
        binds = {
            event = "effect",
            data = {outline = {color = cc.c4b(128, 64, 51, 255), size = 3}},
        },
    },
    ["wheelPanel.btnSkip.txtSkipAni"] = {
        binds = {
            event = "effect",
            data = {outline = {color = cc.c4b(128, 64, 51, 255), size = 3}},
        },
    },
    ["wheelPanel.btnSkip"] = {
        binds = {
            event = "click",
            method = bindHelper.self("onSkip"),
        },
    },
    ["wheelPanel.btnSkip.icon"] = "skipIcon",
    ["wheelPanel.btnRules"] = {
        binds = {
            event = "touch",
            methods = {ended = bindHelper.self("onRules")}
        },
    },

    ["recordPanel"] = "recordPanel",
    ["recordPanel.totalScore"] = "totalScore",
    ["recordPanel.todayScore"] = "todayScore",
    ["recordPanel.todayScoreSlash"] = "todayScoreSlash",
    ["recordPanel.todayScoreMax"] = "todayScoreMax",
    ["recordPanel.costOneScore"] = "costOneScore",
    ["recordPanel.costOneTitle"] = "costOneTitle",
    ["recordPanel.panel404"] = "panel404",
    ["recordPanel.panel404.title404"] = "title404",
    ["recordPanel.btnJumpToRecharge"] = {
        binds = {
            event = "touch",
            methods = {ended = bindHelper.self("jumpToRecharge")}
        },
    },
    ["recordPanel.btnOneDraw"] = {
        varname = "btnOneDraw",
        binds = {
            {
                event = "touch",
                methods = {ended = bindHelper.defer(function(view)
                    view:onDraw(DRAW_TYPE.once)
                end)}
            },
            {
                event = "extend",
                class = "red_hint",
                props = {
                    specialTag = "rechargeWheelFree",
                    listenData = {
                        activityId =  bindHelper.self("activityId")
                    },
                }
            },
        },
    },
    ["recordPanel.btnOneDraw.txtNode"] = "txtOneNode",
    ["recordPanel.btnAllDraw"] = {
        varname = "btnAllDraw",
        binds = {
            event = "touch",
            methods = {ended = bindHelper.defer(function(view)
                view:onDraw(DRAW_TYPE.all)
            end)}
        },
    },
    ["recordPanel.refreshNode1"] = "refreshNode1",
    ["recordPanel.refreshNode2"] = "refreshNode2",
    ["recordPanel.refreshNode3"] = "refreshNode3",
    ["wheelPanel.wheelPointer"] = {
        varname = "wheelPointer",
        binds = {
            event = "touch",
            methods = {ended = bindHelper.defer(function(view)
                view:onDraw(DRAW_TYPE.once)
            end)}
        },
    },

    ["showItem"] = "showItem",
    ["recordPanel.showPanel"] = "showPanel",
    ["recordPanel.showPanel.showList1"] = {
        varname = "showList1",
        binds = {
            event = "extend",
            class = "listview",
            props = {
                data = bindHelper.self("showData1"),
                item = bindHelper.self("showItem"),
                onItem = function(list, node, k, v)
                    initItem(node, v, true)
                end,
            },
        },
    },
     ["recordPanel.showPanel.showList2"] = {
        varname = "showList2",
        binds = {
            event = "extend",
            class = "listview",
            props = {
                data = bindHelper.self("showData2"),
                item = bindHelper.self("showItem"),
                onItem = function(list, node, k, v)
                    initItem(node, v, true)
                end,
            },
        },
    },
    ["recordPanel.recordTitle"] = {
        binds = {
            event = "effect",
            data = {outline = {color = cc.c4b(166, 83, 41, 255), size = 3}},
        },
    },
}

function ActivityRechargeWheelView:onCreate(activityId, tb)
    local reportMessage = tb.view.recharge_wheel_message
    self.yyCfg = csv.yunying.yyhuodong[activityId]
    self.activityId = activityId
    self.reportMessage = idlereasy.new(reportMessage or {})
    self:enableSchedule()
    adapt.setTextAdaptWithSize(self.title404, {size = cc.size(500, 200), vertical = "center", horizontal = "center"})
    -- model
	self:initModel()
    -- 转盘奖励信息显示
    self:initReward()
    -- 个人信息
    self:initMyInfo()
    -- 倒计时
    self:initCountTime()
    -- 跳过动画
    self:initSkipAni()
    -- 奖励播报
    self:initReport()
    -- 特效
    self:initSkel()

    Dialog.onCreate(self, {blackType = 1})
end

function ActivityRechargeWheelView:initMyInfo()
    local paramMap = self.yyCfg.paramMap
    idlereasy.when(self.yyhuodongs, function(_, yyhuodongs)
        -- info 转盘配置信息 drawTimes 转盘积分可抽取最大次数(不包含免费次数)
        local yyhuodong = yyhuodongs[self.activityId]
        if yyhuodong and yyhuodong.info then
            local info = yyhuodong.info
            local totalScore = info.total_score or 0
            local todayScore = info.today_score or 0
            local freeCounter = info.free_counter or 0
            self.scoreDrawTimes = math.floor(totalScore/paramMap.costScore)
            self.totalScore:text(totalScore)
            self.todayScore:text(todayScore)
            self.freeDrawTimes = paramMap.free - freeCounter
        else
            self.totalScore:text(0)
            self.todayScore:text(0)
            self.freeDrawTimes = paramMap.free
            self.scoreDrawTimes = 0
        end
        if self.freeDrawTimes > 0 then
            self.costOneScore:text(0)
            self.txtOneNode:text(gLanguageCsv.freeDraw)
        else
            self.txtOneNode:text(gLanguageCsv.onceDraw)
            self.costOneScore:text(paramMap.costScore)
        end

        -- 对齐
        adapt.oneLinePos(self.todayScore, {self.todayScoreSlash, self.todayScoreMax}, {cc.p(5, 0), cc.p(5, 0)}, "left")
        adapt.oneLineCenterPos(cc.p(self.btnOneDraw:x(), self.costOneTitle:y()), {self.costOneTitle, self.costOneScore}, cc.p(10, 0))

    end)

    -- 固定信息
    self.todayScoreMax:text(paramMap.dailyScoreMax)
    self.refreshNode1:visible(paramMap.free > 0)
    self.refreshNode2:visible(paramMap.free > 0)
    self.refreshNode3:visible(paramMap.free > 0)
    -- 富文本创建提示语
    local richText = rich.createByStr(string.format(gLanguageCsv.rechargeWheelTip, paramMap.recharge, paramMap.addScore), 40)
        :anchorPoint(0, 0.5)
        :xy(self.totalScore:x(), self.totalScore:y() - 50)
        :addTo(self.recordPanel)
        :z(10)
        richText:ignoreContentAdaptWithSize(false)
        richText:setContentSize(cc.size(700,200))
end

function ActivityRechargeWheelView:initModel()
    self.yyhuodongs = gGameModel.role:getIdler("yyhuodongs")
    self.yyEndtime = gGameModel.role:getIdler("yy_endtime")
    self.skipAni = gGameModel.currlogin_dispatch:getIdlerOrigin("rechargeWheelSkip")
end

function ActivityRechargeWheelView:initReward()
    -- 组装转盘奖励信息，读取yyhuodong表clientParam字段
    self.rewardDatas = {}
    for k,v in csvMapPairs(self.yyCfg.clientParam.awards) do
        local key, value = csvNext(v)
        table.insert(self.rewardDatas, {key = key, num = value})
    end
    for i=1,MAX_REWARD_NUMS do
        local name = self.wheel:get("name"..i)
        local icon = self.wheel:get("icon"..i)
        -- 这里最多展示八个，超过不展示(策划需求)
        if name then
            name:text("") -- 将默认文本置空
            local data = self.rewardDatas[i]
            uiEasy.setIconName(data.key, data.num, {node = name})
            adapt.setTextAdaptWithSize(name, {size = cc.size(260,200), vertical = "center", horizontal = "center"})
            local simpleShow = true
            if data.key == "card" then
                simpleShow = false
            end
            bind.extend(self, icon, {
                class = "icon_key",
                props = {
                    data = data,
                    simpleShow = simpleShow,
                    onNode = function (panel)
                        panel:scale(0.9)
                    end
                },
            })
        end
    end
end

function ActivityRechargeWheelView:initSkipAni()
    idlereasy.when(self.skipAni, function(_, skipAni)
        local res = skipAni and "activity/recharge_wheel/btn_gou1.png" or "activity/recharge_wheel/btn_gou0.png"
        self.skipIcon:texture(res)
    end)
end

function ActivityRechargeWheelView:initCountTime()
    local id = self.activityId
    local tag = TAG.count
    local yyEndtime = self.yyEndtime:read()
    self:unSchedule(tag)
    local countdown = 0
    if yyEndtime[id] then
        countdown = yyEndtime[id] - time.getTime()
    end
    self:schedule(function()
        countdown = countdown - 1
        self.wheelTime:text(time.getCutDown(countdown, true).str)
        if countdown <= 0 then
            self:onClose()
            return false
        end
    end, 1, 0, tag)
end

function ActivityRechargeWheelView:jumpToRecharge()
    jumpEasy.jumpTo("recharge")
end

function ActivityRechargeWheelView:onDraw(drawType)
    if self.freeDrawTimes <= 0 and self.scoreDrawTimes <= 0 then
        gGameUI:showTip(gLanguageCsv.rechargeWheelScoreNotEnough)
        return
    end
    if drawType == DRAW_TYPE.once then
        if self.freeDrawTimes > 0 then
            drawType = DRAW_TYPE.free
        end
    elseif drawType == DRAW_TYPE.all then

    else
        printWarn("wrong type", drawType)
        return
    end

    -- 单抽 2圈 1.5s 全抽 10圈 3s
    local showOver = {false}
    gGameApp:requestServerCustom("/game/yy/award/draw")
        :params(self.activityId, drawType)
        :onResponse(function(tb)
            -- 转盘动画-是否跳过判断
            local aniTime = 0
            local aniRotationTotal = 0
            local aniRotationLess = 0
            if not self.skipAni:read() then
                aniTime, aniRotationTotal, aniRotationLess = self:getAniParams(drawType, tb)
                self:wheelAni(aniTime, aniRotationTotal, aniRotationLess)
                if drawType == DRAW_TYPE.all then
                    self.wheelSkel:play("effect_shilianchou")
                else
                    self.wheelSkel:play("effect_chou")
                end
            end
            performWithDelay(self, function()
                showOver[1] = true
            end, aniTime)
        end)
        :wait(showOver)
        :doit(function(tb)
            gGameUI:showGainDisplay(tb)
            self.wheelSkel:play("effect_loop")
            gGameApp:requestServer("/game/yy/active/get", function(tb)
                self.reportMessage:set(tb.view.recharge_wheel_message)
            end)
        end)
end

function ActivityRechargeWheelView:initReport()
    idlereasy.when(self.reportMessage, function(_, reportMessage)
        self:showReport(reportMessage)
    end)
end

function ActivityRechargeWheelView:showReport(reportMessage)
    -- lineTotalNums 奖励播报总行数，超过8行需要滚动显示，不超过8行不用滚动(目前逻辑)
    local newReportMessage = {}
    local lineTotalNums = 0
    -- 计算每个奖励播报需要两行显示还是1行显示 setMaxLineWidth
    for i,v in ipairs(reportMessage) do
        local lineNums = initItem(self.showItem, {message = v}, false)
        lineTotalNums = lineTotalNums + lineNums
        table.insert(newReportMessage, {message = v, lineNums = lineNums})
    end

    local showData1 = {}
    local showData2 = {}
    local reportSize = itertools.size(newReportMessage)
    if lineTotalNums <= SHOW_REPORT_NUMS then
        showData1 = arraytools.first(newReportMessage, reportSize)
    else
        showData1 = arraytools.first(newReportMessage, reportSize)
        showData2 = arraytools.first(newReportMessage, reportSize)
    end

    self.panel404:visible(lineTotalNums == 0)

    if not self.showData1 then
        self.showData1 = idlers.newWithMap(showData1)
    else
        self.showData1:update(showData1)
    end
    if not self.showData2 then
        self.showData2 = idlers.newWithMap(showData2)
    else
        self.showData2:update(showData2)
    end


    -- 计算list高度及位置及动画设置 height1-showList1高度 height1-showList2高度
    local height1 = 0
    local height2 = 0
    local itemHeight = self.showItem:height()
    local showPanelHeight = self.showPanel:height()
    for i,v in ipairs(showData1) do
        height1 = height1 + itemHeight*v.lineNums
    end
    for i,v in ipairs(showData2) do
        height2 = height2 + itemHeight*v.lineNums
    end
    self.showList1:height(height1)
    self.showList1:y(showPanelHeight - height1)
    self.showList2:height(height2)
    self.showList2:y(showPanelHeight - height1 - height2)
    if height2 > 0 then
        local tag = TAG.report
        self:unSchedule(4)
        self:schedule(function()
            if self.showList1:y() >= itemHeight*SHOW_REPORT_NUMS then
                self.showList1:y(self.showList2:y()-self.showList1:height())
            end
            if self.showList2:y() >= itemHeight*SHOW_REPORT_NUMS then
                self.showList2:y(self.showList1:y()-self.showList2:height())
            end
            local targetY1 = self.showList1:y() + itemHeight
            local targetY2 = self.showList2:y() + itemHeight
            transition.executeSequence(self.showList1)
                :moveTo(0.1, 0, targetY1)
                :done()
            transition.executeSequence(self.showList2)
                :moveTo(0.1, 0, targetY2)
                :done()
        end, 1, 1, 4)
    end
end

function ActivityRechargeWheelView:wheelAni(aniTime, aniRotationTotal, aniRotationLess)
    self.wheel:setRotation(0)
    transition.executeSequence(self.wheel, true)
        :easeBegin("EXPONENTIALOUT")
            :rotateBy(aniTime - AIN_TIME_LESS, aniRotationTotal - aniRotationLess)
            :rotateBy(AIN_TIME_LESS, aniRotationLess + 360)
        :easeEnd()
        :done()
end

function ActivityRechargeWheelView:onSkip()
    self.skipAni:modify(function(val)
        return true, not val
    end)
end

-- @params: drawType 抽取类型 gainData 下发奖励数据
function ActivityRechargeWheelView:getAniParams(drawType, gainData)
    local aniTime = ANI_TIME[drawType]
    local aniRotation = ANI_ROTATION[drawType]

    -- 组装服务器数据
    local newGainData = dataEasy.mergeRawDate(gainData)

    -- 奖励停留说明：目前服务会将同类型奖励累加后下发过来，故无法准确知道转盘获取的奖励具体是哪些，且全部抽取获得多个奖励后，只停留在一个奖励上
    -- 目前停留规则：若能找到对应奖励类型、数量，则停留其上，不能，停留在该类型的最小数量栏上，若没有对应类型，则类型不对，属于错误
    -- 以上已和策划沟通
    local stopReward = newGainData[1]
    -- stopIndex 转盘停留奖励，minStopIndex 同类型最小奖励 minStopNum 同类型最小奖励数量
    local stopIndex, minStopIndex, minStopNum
    for i,v in ipairs(self.rewardDatas) do
        if v.key == stopReward.key then
            if v.num == stopReward.num then
                stopIndex = i
            end
            if not minStopNum then
                minStopIndex = i
                minStopNum = v.num
            else
                if minStopNum > v.num then
                    minStopIndex = i
                    minStopNum = v.num
                end
            end
        end
    end

    -- 没有对应类型奖励，默认停留在转盘第一个
    if not minStopIndex then
        minStopIndex = 1
    end

    if not stopIndex then
        stopIndex = minStopIndex
    end

    local lessTime = ((MAX_REWARD_NUMS - stopIndex + 1)/MAX_REWARD_NUMS)*360
    aniRotation = aniRotation + lessTime

    return aniTime, aniRotation, lessTime
end

function ActivityRechargeWheelView:initSkel()
    self.wheelSkel = widget.addAnimationByKey(self.wheelPanel, "zhuanpan/zhuanpan.skel", 'wheelSkel', "effect_loop", 2)
    self.wheelSkel:anchorPoint(cc.p(0.5,0.5))
        :xy(self.wheelPointer:x(), self.wheelPointer:y() - 10)
        :scale(2)
end

function ActivityRechargeWheelView:onRules()
    gGameUI:stackUI("common.rule", nil, nil, self:createHandler("getRuleContext"), {width = 1000})
end

function ActivityRechargeWheelView:getRuleContext(view)
    local c = adaptContext
    local context = {
        c.clone(view.title, function(item)
            item:get("text"):text(gLanguageCsv.rules)
        end),
        c.noteText(122),
        c.noteText(69001, 69008),
    }
    return context
end

return ActivityRechargeWheelView
