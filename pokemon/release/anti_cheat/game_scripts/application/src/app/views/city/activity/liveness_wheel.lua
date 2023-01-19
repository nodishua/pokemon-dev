-- @desc: 	activity-活跃夺宝
-- @date:	2020-1-8 14:42:04

-- 转盘最大数量
local MAX_REWARD_NUMS = 10

-- 抽奖类型 free免费 once 单抽 all 全抽
local DRAW_TYPE = {
    free = "liveness_wheel_free1",
    once = "liveness_wheel1",
    five = "liveness_wheel5",
}

-- 免费次数上限
local FREE = 1

-- taskList间距
local TASK_LIST_MARGIN = 34

-- 定时器tag count活动倒计时 wheel 转盘
local TAG = {
    count = 1,
    wheel = 2,
}

-- 动画相关参数
-- 目前动画分三个阶段：1、前三格，每格0.5s 2、中间基础2圈，每格0.1s 3、最后三格，每格0.5s
-- 中间不是严格的2圈20格，需要根据最后停留的奖励位置去计算具体格数
-- dt-基础时间间隔，用于定时器执行和计算
-- stage1Nums 第一阶段跳动格数 stage1Time 第一阶段每格跳动时间间隔
-- stage2Nums 第二阶段跳动格数(这里是基础格数，实际需要根据最终停留的格子进行及计算)
-- stage3Nums 第三阶段跳动格数，stage3Time 第三阶段每格跳动时间间隔
-- showTime 抽中奖励后的展示时间
local ANI_PARAMS = {
    dt = 0.1,
    stage1Nums = 3,
    stage3Nums = 3,
    stage2Nums =  MAX_REWARD_NUMS*2,
    stage1Time  = 0.5,
    stage2Time = 0.1,
    stage3Time = 0.5,
    showTime = 0.5,
}

local ActivityLivenessWheelView = class("ActivityLivenessWheelView", Dialog)
ActivityLivenessWheelView.RESOURCE_FILENAME = "activity_liveness_wheel.json"
ActivityLivenessWheelView.RESOURCE_BINDING = {
    ["btnClose"] = {
        binds = {
            event = "touch",
            methods = {ended = bindHelper.self("onClose")}
        },
    },
    ["wheelPanel"] = "wheelPanel",
    ["wheelPanel.lessNums"] = "lessNums",
    ["selected"] = "selectedItem",

    ["time"] = "wheelTime",
    ["btnSkip"] = {
        binds = {
            event = "click",
            method = bindHelper.self("onSkip"),
        },
    },
    ["btnSkip.icon"] = "skipIcon",

    ["taskPanel"] = "taskPanel",
    ["taskItem"] = "taskItem",
    ["taskPanel.todayGetTitle"] = "todayGetTitle",
    ["taskPanel.todayGetTimes"] = "todayGetTimes",
    ["taskPanel.todayGetTotal"] = "todayGetTotal",
    ["taskPanel.taskList"] = {
        varname = "taskList",
        binds = {
            event = "extend",
            class = "listview",
            props = {
                data = bindHelper.self("taskDatas"),
                item = bindHelper.self("taskItem"),
                margin = TASK_LIST_MARGIN,
                itemAction = {isAction = true},
                onItem = function(list, node, k, v)
                    local childs = node:multiget("content", "curState", "totalState")
                    childs.content:text(v.cfg.desc)
                    childs.curState:text(v.progress[1])
                    childs.totalState:text("/"..v.progress[2])
                    if v.state == 1 then
                        childs.curState:hide()
                        childs.totalState:text(gLanguageCsv.complete)
                        childs.totalState:setTextColor(cc.c3b(66, 167, 56))
                    end
                    adapt.oneLinePos(childs.totalState, childs.curState, cc.p(0, 0), "right")
                end,
            },
        },
    },
    ["btnOnceDraw"] = {
        varname = "btnOnceDraw",
        binds = {
            event = "touch",
            methods = {ended = bindHelper.defer(function(view)
                view:onDraw(DRAW_TYPE.once)
            end)}
        },
    },
    ["btnOnceDraw.txtNode"] = {
        binds = {
            event = "effect",
            data = {outline = {color = ui.COLORS.OUTLINE.BLUE}},
        },
    },
    ["btnOnceDraw.freeIcon"] = "onceFreeIcon",
    ["btnFiveDraw"] = {
        varname = "btnFiveDraw",
        binds = {
            event = "touch",
            methods = {ended = bindHelper.defer(function(view)
                view:onDraw(DRAW_TYPE.five)
            end)}
        },
    },
    ["btnFiveDraw.txtNode"] = {
        binds = {
            event = "effect",
            data = {outline = {color = ui.COLORS.OUTLINE.ORANGE}},
        },
    },
    ["btnRules"] = {
        binds = {
            event = "touch",
            methods = {ended = bindHelper.self("onRules")}
        },
    },
}

function ActivityLivenessWheelView:onCreate(activityId)
    self.yyCfg = csv.yunying.yyhuodong[activityId]
    self.activityId = activityId
    self:enableSchedule()

    -- model
	self:initModel()
    -- 转盘奖励信息显示
    self:initReward()
    -- 数据相关
    self:initData()
    -- 倒计时
    self:initCountTime()
    -- 跳过动画
    self:initSkipAni()
    -- 特效
    self:initSkel()
    -- 初始化选中奖励
    self:setSelectedReward(1)

    Dialog.onCreate(self, {blackType = 1})
end

function ActivityLivenessWheelView:initModel()
    self.yyhuodongs = gGameModel.role:getIdler("yyhuodongs")
    self.yyEndtime = gGameModel.role:getIdler("yy_endtime")
    self.skipAni = gGameModel.currlogin_dispatch:getIdlerOrigin("livenessWheelSkip")
end

function ActivityLivenessWheelView:initReward()
    -- 组装转盘奖励信息，读取yyhuodong表clientParam字段
    self.rewardDatas = {}
    for k,v in csvMapPairs(self.yyCfg.clientParam.awards) do
        local key, value = csvNext(v)
        table.insert(self.rewardDatas, {key = key, num = value})
    end
    for i=1,MAX_REWARD_NUMS do
        local reward = self.wheelPanel:get("reward"..i)
        if reward then
            local childs = reward:multiget("name", "icon", "num", "numBg", "normal")
            local data = self.rewardDatas[i]
            local name, effect = uiEasy.setIconName(data.key, data.num, {node = childs.name})
            childs.name:hide()
            local label = beauty.singleTextLimitWord(childs.name:text(), {fontSize = childs.name:getFontSize()}, {width = 240})
                :xy(childs.name:xy())
                :addTo(reward, childs.name:z())
                :color(effect.color)
            local simpleShow = true
            local iconData = {key = data.key}
            if data.key == "card" then
                simpleShow = false
                iconData = data
                childs.num:hide()
                childs.numBg:hide()
            else
                childs.num:text(data.num)
                -- 美术需求，不超过两位数，背景不缩短，数字居中处理
                if string.utf8len(data.num) > 2 then
                    childs.numBg:width(childs.num:width() + 18)
                end
                childs.num:x(childs.numBg:x() - childs.numBg:width()/2 + childs.num:width()/2)
            end
            bind.extend(self, childs.icon, {
                class = "icon_key",
                props = {
                    data = iconData,
                    simpleShow = simpleShow,
                    onNode = function (panel)
                        panel:scale(0.8)
                    end
                },
            })
        end
    end
end

function ActivityLivenessWheelView:initData()
    local paramMap = self.yyCfg.paramMap
    self.taskDatas = idlers.newWithMap({})
    idlereasy.when(self.yyhuodongs, function(_, yyhuodongs)
        -- info 转盘配置信息 drawTimes 转盘可抽取最大次数(不包含免费次数)
        local yyhuodong = yyhuodongs[self.activityId] or {}
        -- todayTimes-今日获取次数 self.drawTimes-抽取次数 self.freeDrawTimes-免费抽取剩余次数
        local info = yyhuodong.info or {}
        local freeCounter = info.free_counter or 0
        local todayTimes = info.gain_times or 0
        self.drawTimes = info.total_times or 0
        self.freeDrawTimes = FREE - freeCounter
        self.lessNums:text(self.drawTimes)
        self.onceFreeIcon:visible(self.freeDrawTimes > 0)
        self.todayGetTimes:text(math.min(todayTimes, paramMap.maxGainTimes))

        -- 任务相关
        local huodongID = self.yyCfg.huodongID
        if yyhuodong then
            local stamps = yyhuodong.stamps or {}
            local yyProgress = gGameModel.role:getYYHuoDongTasksProgress(self.activityId) or {}
            local datas = {}
            for k, v in csvPairs(csv.yunying.generaltask) do
                if v.huodongID == huodongID then
                    table.insert(datas, {csvId = k, cfg = v, state = stamps[k], progress = yyProgress[k]})
                end
            end
            self.taskDatas:update(datas)
        end
    end)

    -- 固定信息
    self.todayGetTotal:text("/"..paramMap.maxGainTimes..")")
    adapt.oneLineCenterPos(cc.p(self.taskPanel:width()/2, self.todayGetTitle:y()), {self.todayGetTitle, self.todayGetTimes, self.todayGetTotal})
end

function ActivityLivenessWheelView:initSkipAni()
    idlereasy.when(self.skipAni, function(_, skipAni)
        local res = skipAni and "activity/liveness_wheel/radio_selected.png" or "activity/liveness_wheel/radio_normal.png"
        self.skipIcon:texture(res)
    end)
end

function ActivityLivenessWheelView:initCountTime()
    local id = self.activityId
    local tag = TAG.count
    local yyEndtime = self.yyEndtime:read()
    self:unSchedule(tag)
    local countdown = 0
    if yyEndtime[id] then
        countdown = yyEndtime[id] - time.getTime()
    end

    bind.extend(self, self.wheelTime, {
        class = 'cutdown_label',
        props = {
            tag = tag,
            time = countdown,
            endFunc = function()
                self:onClose()
            end
        }
    })
end

function ActivityLivenessWheelView:onDraw(drawType)
    if drawType == DRAW_TYPE.once then
        if self.freeDrawTimes <= 0 and self.drawTimes <= 0 then
            gGameUI:showTip(gLanguageCsv.livenessWheelTimesNotEnough)
            return
        end

        if self.freeDrawTimes > 0 then
            drawType = DRAW_TYPE.free
        end
    elseif drawType == DRAW_TYPE.five then
        if self.drawTimes < 5 then
            gGameUI:showTip(gLanguageCsv.livenessWheelTimesNotEnough)
            return
        end
    end

    local showOver = {false}
    gGameApp:requestServerCustom("/game/yy/award/draw")
        :params(self.activityId, drawType)
        :onResponse(function(tb)
            -- 转盘动画-是否跳过判断
            local aniTime = 0
            local stopIndex = 1
            if not self.skipAni:read() then
                stopIndex, aniTime = self:getAniParams(drawType, tb)
                self:wheelAni(stopIndex)
            end
            performWithDelay(self, function()
                showOver[1] = true
            end, aniTime)
        end)
        :wait(showOver)
        :doit(function(tb)
            gGameUI:showGainDisplay(tb)
            self.wheelSkel:play("effect_loop")
        end)
end

function ActivityLivenessWheelView:wheelAni(stopIndex)
    -- 特效
    self.wheelSkel:play("effect")
    -- stage2Nums 第二阶段跳动格数，需计算，额外再减1的原因是，起始停留在第一格，但stopIndex的计算是包含了第一格，所以应再减1
    local dt = ANI_PARAMS.dt
    local stage1Nums = ANI_PARAMS.stage1Nums
    local stage3Nums = ANI_PARAMS.stage3Nums
    local stage2Nums =  ANI_PARAMS.stage2Nums + stopIndex - (ANI_PARAMS.stage1Nums + ANI_PARAMS.stage3Nums) - 1
    local stage1Time  = ANI_PARAMS.stage1Time
    local stage2Time = ANI_PARAMS.stage2Time
    local stage3Time = ANI_PARAMS.stage3Time

    self:unSchedule(TAG.wheel)
    -- count 定时器计数，每基时间间隔计数一次，用于格数跳动的实现
    -- current 当前停留奖励序号，1-MAX_REWARD_NUMS，每次动画开始初始默认停留1(策划需求)
    local count = 0
    local current = 1
    -- stage1Count 第一阶段总count stage2Count第二阶段总count stage3Count 第三阶段总count
    local stage1Count = (stage1Nums*stage1Time)/dt
    local stage2Count = (stage2Nums*stage2Time)/dt
    local stage3Count = (stage3Nums*stage3Time)/dt
    -- 动画开始前，位置设置到奖励图标1
    self:setSelectedReward(current)
    self:schedule(function(time)
        count = count + 1
        -- isWheel-是否跳动 stageCurrCount-当前阶段已执行的总count oneBoxCount-当前阶段单个格子跳动需要花费count计数，每个阶段不一样，默认1
        local isWheel = false
        local stageCurrCount = 0
        local oneBoxCount = 1
        if count <= stage1Count  then
            oneBoxCount = stage1Time/dt
            stageCurrCount = count
        elseif count>stage1Count and count <= stage1Count + stage2Count then
            oneBoxCount = stage2Time/dt
            stageCurrCount = count - stage1Count
        elseif count > stage1Count + stage2Count and count <= stage1Count + stage2Count + stage3Count then
            oneBoxCount = stage3Time/dt
            stageCurrCount = count - stage1Count - stage2Count
        else
            self:unSchedule(TAG.wheel)
        end

        if count <= stage1Count + stage2Count + stage3Count then
            isWheel = stageCurrCount/oneBoxCount == math.floor(stageCurrCount/oneBoxCount)
        end

        -- 跳动实现
        if isWheel then
            current = current + 1
            if current > MAX_REWARD_NUMS then
                current = 1
            end
            self:setSelectedReward(current)
        end
    end, dt, dt, TAG.wheel)
end

function ActivityLivenessWheelView:onSkip()
    self.skipAni:modify(function(val)
        return true, not val
    end)
end

-- @params: drawType 抽取类型 gainData 下发奖励数据
function ActivityLivenessWheelView:getAniParams(drawType, gainData)
    -- 组装服务器数据
    local newGainData = dataEasy.mergeRawDate(gainData)

    -- -- 奖励停留说明：目前服务会将同类型奖励累加后下发过来，故无法准确知道转盘获取的奖励具体是哪些，且全部抽取获得多个奖励后，只停留在一个奖励上
    -- -- 目前停留规则：若能找到对应奖励类型、数量，则停留其上，不能，停留在该类型的最小数量栏上，若没有对应类型，则类型不对，属于错误
    -- -- 以上已和策划沟通
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

    local aniTime = ANI_PARAMS.dt*(ANI_PARAMS.stage2Nums + stopIndex - (ANI_PARAMS.stage1Nums + ANI_PARAMS.stage3Nums)) + ANI_PARAMS.stage1Time*ANI_PARAMS.stage1Nums + ANI_PARAMS.stage3Time*ANI_PARAMS.stage3Nums + ANI_PARAMS.showTime
    return stopIndex, aniTime
end

function ActivityLivenessWheelView:initSkel()
    local pNode = self:getResourceNode()
    -- 整体特效
    self.wheelSkel = widget.addAnimationByKey(pNode, "huoyueduobao/huoyueduobao.skel", 'wheelSkel', "effect_loop", 2)
    self.wheelSkel:anchorPoint(cc.p(0.5,0.5))
        :xy(display.sizeInView.width/2, display.sizeInView.height/2)
        :scale(2)
    -- 选中特效
    self.selectedSkel = widget.addAnimationByKey(self.wheelPanel, "huoyueduobao/huoyueduobao.skel", 'selectedSkel', "effect_kuang_loop", 10)
    self.selectedSkel:anchorPoint(cc.p(0.5,0.5))
        :xy(self.wheelPanel:get("reward1"):x(), self.wheelPanel:get("reward1"):y())  -- 默认停在第一个奖励上
        :scale(2)
end

function ActivityLivenessWheelView:onRules()
    gGameUI:stackUI("common.rule", nil, nil, self:createHandler("getRuleContext"), {width = 1000})
end

function ActivityLivenessWheelView:getRuleContext(view)
    local c = adaptContext
    local context = {
        c.clone(view.title, function(item)
            item:get("text"):text(gLanguageCsv.rules)
        end),
        c.noteText(121),
        c.noteText(68001, 68006),
    }
    return context
end

function ActivityLivenessWheelView:setSelectedReward(index)
    local selectedItem = self.selectedItem:clone()
    selectedItem:show()
    if self.wheelSelected then
       self.wheelSelected:removeFromParent()
    end
    self.wheelSelected = selectedItem
    self.wheelSelected:addTo(self.wheelPanel:get("reward"..index), 1):xy(self.selectedItem:width()/2,self.selectedItem:height()/2)
    self.selectedSkel:xy(self.wheelPanel:get("reward"..index):x(), self.wheelPanel:get("reward"..index):y())
end

return ActivityLivenessWheelView
