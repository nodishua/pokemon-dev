-- @Date:   2020-1-22
-- @Desc:  金币钻石返利
-- @Last Modified time:

local ActivityView = require "app.views.city.activity.view"
local ActivityRmbGoldReward = class("ActivityRmbGoldReward", Dialog)

local MAX_NUM = 6
local LEFT_SHOW_NUM = 5
ActivityRmbGoldReward.RESOURCE_FILENAME = "activity_rmbgold_reward.json"
ActivityRmbGoldReward.RESOURCE_BINDING = {
    ["bg"] = "bg",
    ["icon3"] = "icon3",
    ["btnTip"] = {
     varname = "btnTip",
     binds = {
         event = "touch",
         methods = { ended = bindHelper.self("onTips") }
     },
    },
    ["textInfo"] = "textInfo",
    ["bottonTips"] = "bottonTips",
    ["btnClose"] = {
        binds = {
            event = "touch",
            methods = { ended = bindHelper.self("onClose") }
        },
    },
    ["timePlane.imgClock"] = "imgClock",
    ["timePlane.textDayTime"] = "textDayTime",
    ["timePlane.textTimes"] = "textTimes",
    ["topPanel"] = "topPanel",
    ["topPanel.btnSure"] = {
        varname = "btnSure",
        binds = {
            event = "touch",
            methods = { ended = bindHelper.self("onSure") }
        },
    },
    ["topPanel.btnSure.get"] = "get",
    ["topPanel.textCanReward"] = "textCanReward",
    ["topPanel.textMaxReward"] = "textMaxReward",
    ["topPanel.imgDimond"] = "imgDimond",
    ["topPanel.textReward"] = "textReward",
    ["topPanel.text1"] = "text1",
    ["topPanel.text2"] = "text2",
    ["topPanel.icon1"] = "icon1",
    ["topPanel.panelEnd"] = "panelEnd",
    ["topPanel.panelEnd.textRate"] = "textEndRate",
    ["topPanel.panelEnd.textLast"] = "textLast",
    ["topPanel.panelStart"] = "panelStart",
    ["topPanel.panelStart.textNowRate"] = "textNowRate",
    ["topPanel.panelStart.textRate"] = "textRate", -- 返利比率
    ["topPanel.panelStart.leftPanel"] = "leftPanel",
    ["topPanel.panelStart.leftPanel.textNeed"] = "textNeed", -- 距下一阶段所需要的钻石
    ["topPanel.panelStart.leftPanel.icon2"] = "icon2",
    ["topPanel.panelStart.leftPanel.textCost"] = "textCost",
    ["topPanel.panelStart.leftPanel.textCost1"] = "textCost1",
    ["topPanel.info.textTime"] = "textTime", -- 倒计时
    ["topPanel.info.textTip"] = "textTip", -- 倒计时
    ["topPanel.info.imgTip"] = "imgTip", -- 倒计时

    ["bottomPanel.textSumCost"] = "textSumCost",
    ["bottomPanel.textHasCost"] = "textHasCost", --消费的钻石
    ["bottomPanel.item"] = "item",
    ["bottomPanel.item.cost"] = "cost",
    ["bottomPanel.rewardList"] = {
        varname = "rewardList",
        binds = {
            event = "extend",
            class = "listview",
            props = {
                data = bindHelper.self("boxData"),
                item = bindHelper.self("item"),
                backupCached = false,
                onItem = function(list, node, k, v)
                    local icon = node:get("icon")
                    local size = icon:size()
                    local val = {}
                    local scoreEnough = v.scoreEnough == true
                    local boxGet = v.boxGet == true
                    val.id, val.num = csvNext(v.cfg.award)
                    bind.extend(list, icon, {
                        class = "icon_key",
                        props = {
                            data = {
                                key = val.id,
                                num = val.num,
                            },
                            noListener = false,
                            onNode = function(panel)
                                if scoreEnough and not boxGet then
                                    -- 加过光效果
                                    uiEasy.sweepingEffect(icon, {speedTime = 1.0 , delayTime = 1.0, angle = 20, scaleX = 3.0})
                                    node:get("iconAwardMask"):setVisible(true)
                                    icon:setTouchEnabled(false)
                                end
                                if scoreEnough and boxGet then
                                    local panel1 = ccui.Layout:create()
                                        :size(size)
                                        :setBackGroundColorType(1)
                                        :setBackGroundColor(cc.c3b(255, 252, 237))
                                        :setBackGroundColorOpacity(102)
                                        :addTo(panel, 10, "iconMask")
                                    local text1 = ccui.Text:create(gLanguageCsv.received, "font/youmi1.ttf", 40)
                                        :alignCenter(panel:size())
                                        :addTo(panel, 10, "awardGot")
                                    if v.type == "rmb" then
                                        text.addEffect(text1, {outline = { color = cc.c4b(255, 252, 237, 255), size = 4}, color = cc.c4b(90, 90, 178, 255)})
                                    else
                                        text.addEffect(text1, {outline = { color = cc.c4b(255, 252, 237, 255), size = 4}, color = cc.c4b(194, 101, 30, 255)})
                                    end
                                end
                                panel:xy(size.width/2, size.height/2)
                                bind.touch(list, panel, {methods = {ended = functools.partial(list.clickBoxGet, k, node)}})
                                bind.touch(list,  node:get("iconAwardMask"), {methods = {ended = functools.partial(list.clickBoxGet, k, node)}})
                            end,
                        },
                    })
                    if v.type == "rmb" then
                        node:get("imgGet"):texture("activity/rmbgold_reward/sign_gou_bg2.png")
                    else
                        node:get("imgGet"):texture("activity/rmbgold_reward/sign_gou_bg1.png")
                    end
                    if scoreEnough and not boxGet then
                        if v.type == "rmb" then
                            node:get("imgNoGet"):texture("activity/rmbgold_reward/logo_zzfz2.png")
                        else
                            node:get("imgNoGet"):texture("activity/rmbgold_reward/logo_zzfj2.png")
                        end
                    elseif boxGet then
                        node:get("imgNoGet"):setVisible(false)
                        node:get("imgGet"):setVisible(true)
                        node:setTouchEnabled(false)
                    else
                        if v.type == "rmb" then
                            node:get("imgNoGet"):texture("activity/rmbgold_reward/logo_zzfz1.png")
                        else
                            node:get("imgNoGet"):texture("activity/rmbgold_reward/logo_zzfj1.png")
                        end
                        node:get("imgGet"):setVisible(false)
                        node:setTouchEnabled(false)
                    end
                    node:get("cost"):text(mathEasy.getShortNumber(v.cfg.num, 2))
                    bind.touch(list, node, {methods = {ended = functools.partial(list.clickBoxGet, k, node)}})
                end,
            },
            handlers = {
                clickBoxGet = bindHelper.self("onBoxGetClick"),
            },
        },
    }, --奖励列表
    ["bottomPanel.barBg"] = "barBg",
    ["bottomPanel.barGoldBg"] = "barGoldBg",
    ["bottomPanel.bar"] = {
        varname = "bar",
        binds = {
            event = "extend",
            class = "loadingbar",
            props = {
                data = bindHelper.self("livenessPoint1"),
                maskImg = "activity/rmbgold_reward/line_zzfz1.png"
            },
        }
    },
    ["bottomPanel.barGold"] = {
        varname = "barGold",
        binds = {
            event = "extend",
            class = "loadingbar",
            props = {
                data = bindHelper.self("livenessPoint1"),
                maskImg = "activity/rmbgold_reward/line_zzfj1.png"
            },
        }
    },
}

function ActivityRmbGoldReward:onCreate(activityId)
    self.activityEnd = false
    self.rewardGet = false
    self.activityId = activityId
    self.huodongID = csv.yunying.yyhuodong[self.activityId].huodongID
    local activityCfg = csv.yunying.yyhuodong[self.activityId]
    self:initModel()
    self.rateData = {}
    self.awardData = {}
    self.csvId = {}
    for i, v in orderCsvPairs(csv.yunying.rmbgoldreturn_award) do
        local cfg = csv.yunying.yyhuodong[self.activityId]
        if cfg.huodongID == v.huodongID then
            table.insert(self.awardData, v)
            table.insert(self.csvId, i)
        end
    end
    for i, v in orderCsvPairs(csv.yunying.rmbgoldreturn_rate) do
        local cfg = csv.yunying.yyhuodong[self.activityId]
        if cfg.huodongID == v.huodongID then
            table.insert(self.rateData, v)
        end
    end
    self:resetTimeLabel()  -- 定时器

    self.showItemIdx = 1
    self.maxIdx = 0

    if activityCfg.paramMap.type == "rmb" then
        self:initRmb()
    else
        self:initGold()
    end
    --self.rewardList:setScrollBarEnabled(false);

    self.textMaxReward:text(mathEasy.getShortNumber(activityCfg.paramMap.limit))
    adapt.oneLineCenter(self.textMaxReward,self.text1, self.text2,cc.p(10, 0))
    --adapt.oneLinePos(self.textReward,self.icon1, cc.p(self.textReward:width()/4 + 10, 0), "right")
    --adapt.oneLineCenterPos(cc.p(1300,305),{self.icon1, self.textReward}, cc.p( 10, 0))

    local boxData = {}
    local newT = {}
    local nums = #self.awardData
    local progress = {}
    self.rewardList:setItemsMargin(math.max(0, self.rewardList:size().width/nums - 200))
    for i, v in pairs(self.awardData) do
        local data = {cfg = v , type = activityCfg.paramMap.type, id = self.csvId[i]}
        table.insert(boxData, data)
        table.insert(newT, v.num)
        table.insert(progress, 100/nums * i - 50/nums - 1)
    end
    self.livenessPoint1 = idler.new(0)
    self.boxData = idlertable.new(boxData)
    idlereasy.when(self.yyhuodongs, function(_, yyhuodongs)
        local yyData = yyhuodongs[activityId] or {}
        self.costNum = 0
        self.costRate = self.rateData[1] and self.rateData[1].rate or 0
        self.needCost = -1
        if activityCfg.paramMap.type == "rmb" then
            self.costNum = yyData.info and yyData.info.rmb_used or 0
        else
            self.costNum = yyData.info and yyData.info.gold_used or 0
        end
        if yyData.info and yyData.info.flag then
            cache.setShader(self.btnSure, false, "hsl_gray")
            self.btnSure:setTouchEnabled(false)
            self.get:text(gLanguageCsv.received)
            self.rewardGet = true
        elseif self.costNum == 0 then
            cache.setShader(self.btnSure, false, "hsl_gray")
        end
        for k, v in pairs(self.awardData) do
            if self.costNum >= v.num then
                self.boxData:proxy()[k].scoreEnough = true
            end
            if yyData.stamps and yyData.stamps[self.csvId[k]] == 0 then
                self.boxData:proxy()[k].boxGet = true
            end
        end
        for k, v in pairs(self.rateData) do
            if self.costNum >= v.num then
                self.costRate = v.rate
            end
            if self.needCost < 0 and v.num > self.costNum then
                self.needCost = v.num - self.costNum
            end
        end
        if self.needCost < 0 then
            self.needCost = 0;
            self.textNeed:setVisible(false)
            self.icon2:setVisible(false)
            self.textCost1:setVisible(false)
            self.textCost:text(gLanguageCsv.rmbGoldRewardMax)
        end
        self.textNeed:text(mathEasy.getShortNumber(self.needCost, 2))
        self.textHasCost:text(mathEasy.getShortNumber(self.costNum, 2))
        self.textRate:text(string.format("%d%%",math.floor(self.costRate * 100)))
        self.textEndRate:text(string.format("%d%%",math.floor(self.costRate * 100)))
        self.textReward:text(mathEasy.getShortNumber(math.min(math.ceil(self.costNum * self.costRate), activityCfg.paramMap.limit), 2))
        adapt.oneLinePos(self.textReward,self.icon1, cc.p(10, 0), "right")
        self.livenessPoint1:set(mathEasy.showProgress(progress, newT, self.costNum))
    end)

    self:fires(150,200, 300, 70, 0)
    self:fires(450,200, 200, 70, 1)
    self:fires(1000,200, 300, 70, 0.5)

    Dialog.onCreate(self, { blackType = 1 })
end

function ActivityRmbGoldReward:fires(x, y, height, len, times)
    local fire1 = ccui.ImageView:create(self.fire1Image)
                     :scale(0.5)
                     :align(cc.p(0.5, 1), cc.p(x,y))
                     :addTo(self.bg, 100, "fire")
    local fire2 = ccui.ImageView:create(self.fire2Image)
                      :scale(0.5)
                      :align(cc.p(0.5, 1), cc.p(x,y))
                      :addTo(self.bg, 100, "fire")
                      :setVisible(false)
    x = x + fire1:size().width
    local nodes = {}
    for i = 1, 8 do
        table.insert(nodes, fire1:clone():addTo(self.bg, 100, "fire"):setVisible(false))
    end
    table.insert(nodes, fire2)
    for i = 1, 7 do
        table.insert(nodes, fire2:clone():addTo(self.bg, 100, "fire"):setVisible(false))
    end
    local animate = cc.Sequence:create(
            cc.DelayTime:create(times),
            cc.FadeTo:create(0, 255),
            cc.MoveTo:create(0.3,cc.p(x, y + height)),
            cc.FadeTo:create(0, 0),
            cc.CallFunc:create(function()
                for k, v in pairs(nodes) do
                    v:setVisible(true)
                    local r , length, scale = 0, len, 0.5
                    if k <= 8 then
                        r = 45 * (k -1)
                    else
                        length = len * 0.7
                        r = 45 * (k -1) + 22.5
                        scale = 0.75
                    end
                    transition.executeSequence(v, true)	-- 跟随活动列表飞出
                        :scaleTo(0,0)
                            :fadeTo(0,0)
                            :moveTo(0,x ,y + height)
                            :rotateTo(0, r)
                            :fadeTo(0.000,255)
                            :scaleTo(0.0001, scale)
                            :easeBegin("EXPONENTIALOUT")
                            :moveTo(1.3, x + length * math.sin(math.rad(r)), y + height + length * math.cos(math.rad(r)))
                            :scaleTo(1,0)
                            :easeEnd()
                          --  :easeBegin("SINEIN")
                          --  --:scaleTo(0.3,0)
                          ----:fadeTo(0.3, 0)
                          --  :easeEnd()
                    --:fadeTo(0.3, 0)
                              :done()
                end
            end),
            cc.MoveTo:create(0,cc.p(x, y)),
            cc.DelayTime:create(2))
            --cc.FadeTo:create(0, 255))
    local action = cc.RepeatForever:create(animate)
    fire1:runAction(action)
end


function ActivityRmbGoldReward:initRmb()
    self.fire1Image = "activity/rmbgold_reward/img_b2.png"
    self.fire2Image = "activity/rmbgold_reward/img_b1.png"
    self.imgTip:texture("activity/rmbgold_reward/box_zzfz_1.png")
    self.bg:texture("activity/rmbgold_reward/img_zzfz.png")
    self.icon1:texture("common/icon/icon_diamond.png")
    self.icon2:texture("common/icon/icon_diamond.png")
    self.icon3:texture("common/icon/icon_diamond.png")
    self.imgClock:texture("activity/rmbgold_reward/logo_time1.png")
    --self.bar:texture("activity/rmbgold_reward/sign_gou_bg2.png")
    --self.barBG:texture("activity/rmbgold_reward/line_zzfz2.png")
    self.barGold:setVisible(false)
    self.barGoldBg:setVisible(false)
    text.addEffect(self.cost, {color =  cc.c4b(16, 130, 218, 255)})
    text.addEffect(self.textSumCost, {color =  cc.c4b(35, 135, 229, 255)})
    text.addEffect(self.textCost, {color =  cc.c4b(13, 79, 177, 255)})
    text.addEffect(self.textCost1, {color =  cc.c4b(13, 79, 177, 255)})
    text.addEffect(self.textInfo, {color =  cc.c4b(97, 212, 253, 255)})
    text.addEffect(self.textDayTime, {color =  cc.c4b(60, 233, 210, 255)})
    text.addEffect(self.textTimes, {color =  cc.c4b(60, 233, 210, 255)})
    text.addEffect(self.text1, {color =  cc.c4b(90, 90, 178,  255)})
    text.addEffect(self.text2, {color =  cc.c4b(90, 90, 178, 255)})
    text.addEffect(self.textTip, {color =  cc.c4b(145, 130, 32, 255)})
    text.addEffect(self.textTime, {color =  cc.c4b(145, 130, 32, 255)})
    text.addEffect(self.textMaxReward, {color =  cc.c4b(20, 169, 222, 255)})
    text.addEffect(self.textCanReward, {color =  cc.c4b(20, 169, 222, 255)})
    text.addEffect(self.textHasCost, {color =  cc.c4b(90, 90, 178, 255)})
    text.addEffect(self.bottonTips, {color =  cc.c4b(122, 167, 189, 255)})
    text.addEffect(self.textNowRate, { outline = { color = cc.c4b(13, 79, 177, 255), size = 6} })
    text.addEffect(self.textRate, { outline = { color = cc.c4b(13, 79, 177, 255), size = 10} })
    text.addEffect(self.textNeed, { outline = { color = cc.c4b(13, 79, 177, 255), size = 6} })
    if #self.rateData <= 1 then
        self.textInfo:text(gLanguageCsv.rmbRewardFixTips)
        self.textNowRate:text(gLanguageCsv.rateFixInfo)
        self.textLast:text(gLanguageCsv.rateFixInfo)
        self.textEndRate:x(self.textEndRate:x() - 70)
        self.leftPanel:setVisible(false)
        self.btnTip:setVisible(false)
    else
        self.textInfo:text(gLanguageCsv.rmbRewardTips)
        self.textNowRate:text(gLanguageCsv.rateInfo)
        self.leftPanel:setVisible(true)
        self.btnTip:setVisible(true)
    end
    self.bottonTips:text(gLanguageCsv.rmbRewardBottonTips)
    if self.activityEnd then
        self.imgTip:texture("activity/rmbgold_reward/box_zzfz_2.png")
        self.panelStart:setVisible(false)
        self.panelEnd:setVisible(true)
        self.btnSure:setVisible(true)
        self.text1:setVisible(false)
        self.text2:setVisible(false)
        self.textMaxReward:setVisible(false)
        text.addEffect(self.textTip, {color =  cc.c4b(255, 255, 255, 255)})
        text.addEffect(self.textTime, {color =  cc.c4b(255, 255, 255, 255)})
        text.addEffect(self.textEndRate,  { outline = { color = cc.c4b(13, 79, 177, 255), size = 10} })
        text.addEffect(self.textLast, { outline = { color = cc.c4b(13, 79, 177, 255), size = 6} })
        self.textInfo:text(gLanguageCsv.rmbRewardEndTips)
        self.bottonTips:text(gLanguageCsv.rmbRewardEndBottonTips)
        self.textTip:text(gLanguageCsv.activityEnd)
    end
end

function ActivityRmbGoldReward:initGold()
    self.fire1Image = "activity/rmbgold_reward/img_y2.png"
    self.fire2Image = "activity/rmbgold_reward/img_y1.png"
    self.imgTip:texture("activity/rmbgold_reward/box_zzfj_1.png")
    self.bg:texture("activity/rmbgold_reward/img_zzfj.png")
    self.icon1:texture("common/icon/icon_gold.png")
    self.icon2:texture("common/icon/icon_gold.png")
    self.icon3:texture("common/icon/icon_gold.png")
    self.imgClock:texture("activity/rmbgold_reward/logo_time2.png")
    --self.bar:texture("activity/rmbgold_reward/sign_gou_bg1.png")
    --self.barBG:texture("activity/rmbgold_reward/line_zzfj2.png")
    self.bar:setVisible(false)
    self.barBg:setVisible(false)
    text.addEffect(self.cost, {color =  cc.c4b(227, 115, 29, 255)})
    text.addEffect(self.textSumCost, {color =  cc.c4b(232, 76, 147, 255)})
    text.addEffect(self.textCost, {color =  cc.c4b(194, 101, 30, 255)})
    text.addEffect(self.textCost1, {color =  cc.c4b(194, 101, 30, 255)})
    text.addEffect(self.textInfo, {color =  cc.c4b(248, 222, 76, 255)})
    text.addEffect(self.textDayTime, {color =  cc.c4b(255, 215, 143, 255)})
    text.addEffect(self.textTimes, {color =  cc.c4b(255, 215, 143, 255)})
    text.addEffect(self.text1, {color =  cc.c4b(194, 101, 30, 255)})
    text.addEffect(self.text2, {color =  cc.c4b(194, 101, 30, 255)})
    text.addEffect(self.textTip, {color =  cc.c4b(194, 101, 30,255)})
    text.addEffect(self.textTime, {color =  cc.c4b(194, 101, 30, 255)})
    text.addEffect(self.textMaxReward, {color =  cc.c4b(232, 76, 147, 255)})
    text.addEffect(self.textCanReward, {color =  cc.c4b(232, 76, 147, 255)})
    text.addEffect(self.textHasCost, {color =  cc.c4b(255, 140, 59, 255)})
    text.addEffect(self.bottonTips, {color =  cc.c4b(193, 158, 130, 255)})
    text.addEffect(self.textNowRate, { outline = {color = cc.c4b(194, 101, 30, 255), size = 6}})
    text.addEffect(self.textRate, { outline = {color = cc.c4b(255, 247, 245,255), size = 10}, color = cc.c4b(232, 76, 147, 255)})
    text.addEffect(self.textNeed, { outline = {color = cc.c4b(194, 101, 30, 255), size = 6}})
    if #self.rateData <= 1 then
        self.textInfo:text(gLanguageCsv.goldRewardFixTips)
        self.textNowRate:text(gLanguageCsv.rateFixInfo)
        self.textLast:text(gLanguageCsv.rateFixInfo)
        self.textEndRate:x(self.textEndRate:x() - 70)
        self.leftPanel:setVisible(false)
        self.btnTip:setVisible(false)
    else
        self.textInfo:text(gLanguageCsv.goldRewardTips)
        self.textNowRate:text(gLanguageCsv.rateInfo)
        self.leftPanel:setVisible(true)
        self.btnTip:setVisible(true)
    end
    self.bottonTips:text(gLanguageCsv.goldRewardBottonTips)
    if self.activityEnd then
        self.imgTip:texture("activity/rmbgold_reward/box_zzfj_2.png")
        self.panelStart:setVisible(false)
        self.panelEnd:setVisible(true)
        self.btnSure:setVisible(true)
        self.text1:setVisible(false)
        self.text2:setVisible(false)
        self.textMaxReward:setVisible(false)
        text.addEffect(self.textTip, {color =  cc.c4b(255, 255, 255, 255)})
        text.addEffect(self.textTime, {color =  cc.c4b(255, 255, 255, 255)})
        text.addEffect(self.textEndRate, {outline = {color = cc.c4b(255, 247, 245,255), size = 10}})
        text.addEffect(self.textLast, { outline = {color = cc.c4b(194, 101, 30, 255), size = 6}})
        self.textInfo:text(gLanguageCsv.goldRewardEndTips)
        self.bottonTips:text(gLanguageCsv.goldRewardEndBottonTips)
        self.textTip:text(gLanguageCsv.activityEnd)
    end
end

function ActivityRmbGoldReward:initModel()
    self.yyhuodongs = gGameModel.role:getIdler("yyhuodongs")
    self.rmbUsed = gGameModel.role:getIdler("rmb_used")
    self.goldUsed = gGameModel.role:getIdler("gold_used")
end


function ActivityRmbGoldReward:resetTimeLabel()
    local yyEndtime = gGameModel.role:read("yy_endtime")[self.activityId]
    -- 2020.12.21 05:00:00-2020.12.21 05:00:00
    local _, startTime = time.getActivityOpenDate(self.activityId)
    local cfg = csv.yunying.yyhuodong[self.activityId]
    local openDate = time.getDate(startTime)
    openDate.hour = cfg.beginTime / 100
    openDate.min = cfg.beginTime % 100
    openDate.sec = 0
    local endDate = time.getDate(math.floor(yyEndtime - 86400 * cfg.paramMap.returnDays))
    endDate.hour = cfg.endTime / 100
    endDate.min = cfg.endTime % 100
    endDate.sec = 0
    local openTime = string.format("%d.%02d.%02d %02d:%02d:%02d", openDate.year, openDate.month, openDate.day, openDate.hour, openDate.min, openDate.sec)
    local endTime = string.format("%d.%02d.%02d %02d:%02d:%02d", endDate.year, endDate.month, endDate.day, endDate.hour, endDate.min, endDate.sec)
    self.textTimes:text(string.format("%s-%s", openTime, endTime))
    local countdown = time.getTimestamp(endDate) - time.getTime()
    if countdown <= 0 then
        self.activityEnd = true
        self.textTip:setVisible(false)  -- 领取时间不再倒计时
        self.textTime:y(self.textTime:y() + 24)
        self.textTime:text(gLanguageCsv.activityOver)
    else
        bind.extend(self, self.textTime, {
            class = 'cutdown_label',
            props = {
                time = countdown,
                endFunc = function()
                    -- self:gameOver()
                    self.textTip:setVisible(false)
                    self.textTime:y(self.textTime:y() + 24)
                    self.textTime:text(gLanguageCsv.activityOver)
                end,
            }
        })
    end
end


function ActivityRmbGoldReward:onBoxGetClick(list, index, node)
    local data = self.boxData:proxy()[index]
    if self.costNum >= data.cfg.num and not data.boxGet then
        local showOver = {false}
        gGameApp:requestServerCustom("/game/yy/award/get")
            :params(self.activityId, data.id)
            :onResponse(function (tb)
                node:get("imgNoGet"):setVisible(false)
                node:get("imgGet"):setVisible(true)
                showOver[1] = true
            end)
            :wait(showOver)
            :doit(function (tb)
                gGameUI:showGainDisplay(tb)
            end)
    end
end

function ActivityRmbGoldReward:onSure()
    if self.costNum > 0 and not self.rewardGet then
        gGameApp:requestServer("/yy/rmbgold/return", function(tb)
            performWithDelay(self, function()
                gGameUI:showGainDisplay(tb)
            end, 0)
        end, self.activityId, self.huodongID)
    else
        gGameUI:showTip(gLanguageCsv.noRmbGoldRewardGet)
        --gGameUI:showDialog({title = gLanguageCsv.spaceTips, content = gLanguageCsv.noRmbGoldRewardGet, fontSize = 50, isRich = false, btnType = 2, cb = function() end })
    end
end

function ActivityRmbGoldReward:onTips()
    gGameUI:stackUI("common.rule", nil, nil, self:createHandler("getRuleContext"), {width = 800})
end

function ActivityRmbGoldReward:getRuleContext(view)
    local c = adaptContext
    local context = {
        c.clone(view.title, function(item)
            item:get("text"):text(gLanguageCsv.rmbGoldRewardRules)
        end), gLanguageCsv.ruleInfo
    }
    for k, v in pairs(self.rateData) do
        table.insert(context, c.clone(view.rateTips, function(item)
            local childs = item:multiget("text1", "text2","text3")
            childs.text1:text(string.format(gLanguageCsv.ruleRate, gLanguageCsv["symbolNumber" .. k]))
            childs.text2:text(mathEasy.getShortNumber(v.num, 2))
            childs.text3:text( math.floor(v.rate * 100) .. "%")
        end))
    end
    return context
end


return ActivityRmbGoldReward
