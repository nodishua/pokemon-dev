-- @date 2021-03-12
-- @desc 赛马比赛界面
local ViewBase = cc.load("mvc").ViewBase
local HorseRaceMatch = class("HorseRaceMatch", ViewBase)

HorseRaceMatch.RESOURCE_FILENAME = "horse_race_match.json"
HorseRaceMatch.RESOURCE_BINDING = {
    ["trackBG"] = "trackBG",
    ["btn"] = {
        varname = "btn",
        binds = {
            event = "touch",
            methods = { ended = bindHelper.self("onSkip") }
        }
    },
    ["lab"] = "lab",
    ["lab.rate"] = "rate",
    ["times"] = "times",
    ["times.time"] = "time",
    ["name"] = "name",
    ["bet"] = "bet",
    ["end"] = "ended",
    ["ready"] = "ready",
    ["go"] = "go",
    ["blank"] = "blank"
}

function HorseRaceMatch:onCreate(activityId, td, cb)
    gGameUI.topuiManager:createView("city", self):init()
    self.leftMarge, self.rightMarge = {340,440,540,640}, {300,250,200,150} -- 起点终点边界
    self.activityId = activityId
    self.select = td[2]
    self.data = td[1]
    self.index = td[2]
    self.cb = cb
    self.time:text(0)
    if td[3] then
        self.btn:visible(false)
    else
        self.btn:visible(true)
    end
    local data = {}
    local t1,t2,t3 = {},{},{}
    local keys , values = {"time","sprint_time_slots","csv_id","result"}, {"endTime","crash","player","result"}
    for key, val in pairs(values) do
        t1 = {}
        for k, v in pairs(self.data) do
            local config = csv.cross.horse_race.horse_race_card[v.csv_id]
            t1[k] = v[keys[key]]
        end
        data[val] = t1
    end
    data.distance = csv.cross.horse_race.base[1].distance
    self:initRes(data)
    self:initData(data)
    self:runAnimation(data)
end

function HorseRaceMatch:initData(data)
    local raceConfig = csv.cross.horse_race.horse_race_card
    -- 比赛路程算法
    local strength = {}  -- 精灵体力
    self.ls = {}  -- 地图路径表 (偏移值) （单位 像素）
    local sumLs = 0 -- 累计偏移值 （单位 像素）
    local oneDistance = {0,0,0,0} -- （单位 米）
    self.speed = {400, 450, 300, 350}  -- 速度 （单位 米/秒）
    local crash = data.crash -- {{0},{},{0},{0}}  -- 冲刺时间点 （单位 秒）
    local crashRate = {1, 1, 4, 2}  -- 冲刺比例
    local crashGetTime = {1, 1, 1, 1} -- 冲刺持续时间 （单位 秒）
    local crashTime = {0, 0, 0, 0} -- 冲刺剩余时间
    local len = {0, 0, 0, 0}  -- 已跑距离 （单位 米）
    local allDistance = data.distance  -- 赛道距离 （单位 米）
    local distance = {allDistance, allDistance, allDistance, allDistance} -- 剩余总长度（单位 米）
    local cost = {20,30,10,10}  -- 每秒消耗的体力
    local recovery = {10,10,10,10}  -- 每秒体力回复
    local one, flag= 1, 0  -- 第一名，地图开始移动标志
    local tali = {0,0,0,0} -- 体力恢复标志
    local rate = 1  -- 路径和像素比 （米：像素 = 1：rate）
    local fixDistance = 0 -- 位移修正，解决一个精灵单秒内冲刺过猛
    local playerEndTime = data.endTime -- {5.725,5.0888888888,7.63333,6.54285714285}  -- 跑完所用的时间(服务器)
    self.costTime = {0,0,0,0} -- 跑完耗时(本地)
    self.tempValue = {{},{},{},{}} -- 每秒的路径记录（单位 像素）
    self.secLen = {{},{},{},{}} -- 每秒的跑的距离记录（单位 像素）
    local maxTime = 600  -- 最大时间上限
    local maxStrength = {}
    local rank = {1,1,1,1}  -- 当前名次
    self.weak = {{},{},{},{}} -- 虚弱时间点
    for key, val in pairs(data.player) do
        local playerInfo = raceConfig[val]
        strength[key] = playerInfo.stamina
        maxStrength[key] = playerInfo.stamina
        self.speed[key] = playerInfo.speed / 10
        crashRate[key] = playerInfo.sprintMultiple
        --crashGetTime[key] = playerInfo.sprintTime
        cost[key] = playerInfo.staminaCost
        recovery[key] = playerInfo.staminaRecovery
    end

    self.maxTimes = math.ceil(math.max(playerEndTime[1], playerEndTime[2],playerEndTime[3], playerEndTime[4]))
    local function  theOne()
        local top, maxLen = 1, 0
        for k, v in pairs(len) do
            if v > maxLen then
                maxLen = v
                top = k
            end
        end
        return top
    end
    for i = 1, self.maxTimes + 1 do
        for k = 1, 4 do  -- 计算比赛真实距离
            local tl = 0
            if strength[k] < maxStrength[k] * 0.5 and strength[k] > 0 then
                tl = - csv.cross.horse_race.base[1].sMultiple2
                table.insert(self.weak[k],i)
            elseif strength[k] <= 0 then
                tl = - csv.cross.horse_race.base[1].sMultiple1
                table.insert(self.weak[k],i)
            end
            for key, val in pairs(crash[k] or {}) do  -- 冲刺判定
                if val == i then
                    crashTime[k] = crashGetTime[k]
                    break
                end
            end
            local dis = 0
            if i >= maxTime then
                dis = 500
            else
                dis = self.speed[k] * ((crashTime[k] > 0 and crashRate[k] or 0) + 1 + tl)
            end
            oneDistance[k] = dis
            -- 计算比赛的耗时
            if len[k] + dis >= allDistance then
                -- 已经到达终点，
                self.costTime[k] = self.costTime[k] + (allDistance - len[k]) / dis  -- dis是距离但也可以当速度
                len[k] = allDistance
                self.secLen[k][i] = allDistance - (len[k-1] or 0)
            else
                self.costTime[k] = self.costTime[k] + 1
                len[k] = len[k] + dis
                self.secLen[k][i] = dis
            end
            crashTime[k] = crashTime[k] -1  --不做判断，反正是覆盖
            distance[k] = distance[k] - self.speed[k]
            if tali[k] == 0 then  -- 体力恢复相关
                strength[k] = math.max(strength[k] - cost[k], 0)
            else
                strength[k] = math.min(strength[k] + recovery[k], maxStrength[k])
            end
            if strength[k] == maxStrength[k] then
                tali[k] = 0
            end
            if strength[k] == 0 then
                tali[k] = 1
            end
            self.tempValue[k][i] = len[k] * rate
        end -- 计算比赛真实距离
        for l = 1, 4 do
            if self.leftMarge[l] + len[l] * rate >= display.size.width * 0.618  then  -- 镜头开始移动
                flag = 1
            end
        end
        local tone = theOne()
        if  tone ~= one then
            one = tone
        end
        if len[one] * rate >= display.size.width * 0.5  then  -- 镜头开始移动  one 可以替换成想锁定的选手
            flag = 1
        else
            flag = 0
        end
        local abv = (self.secLen[one][i] + (self.secLen[one][i-1] or 0))/2
        local abc = (self.secLen[one][i] + (self.secLen[one][i+1] or self.secLen[one][i]))/2
        if flag == 1 then  --移动镜头距离
            local maxMove = self.maxBg:size().width - display.size.width - 600
            -- 地图最大可移动距离  图片大小 - 屏幕大小
            if maxMove >= len[one] * rate - display.size.width * 0.5 then
                local lens = abc * 0.4 + abv * 0.4 + self.secLen[one][i] * 0.2 + (self.ls[i-1] or 0)
                self.ls[i] = len[one] * rate - display.size.width * 0.5
            else
                self.ls[i] =  maxMove
            end
        end
    end
end

function HorseRaceMatch:runAnimation(data)
    local endTime , index= self.maxTimes, 1
    local obj = self.obj
    local flag = {0,0,0,0}
    local runFlag = {0,0,0,0}
    self.go:runAction(cc.Sequence:create(
        cc.CallFunc:create(function() self.ready:setVisible(true) end),
        cc.DelayTime:create(1),
        cc.CallFunc:create(function() self.ready:setVisible(false) self.go:setVisible(true)  end),
        cc.DelayTime:create(1),
        cc.CallFunc:create(function()  self.go:setVisible(false) end)
    ))
    self:enableSchedule():schedule(function (dt)
        self.time:text(math.floor(math.min(self.maxTimes,index - 1)/10))
        if endTime <= -2 then
            self.ended:setVisible(true)
            --self:onSkip()cc.FadeIn:create(1),
            --					cc.FadeOut:create(2)
            --self.ended:setVisible(true)
        end
        endTime = endTime -1
        if endTime > -2 then
            for k, v in pairs(obj) do
                if runFlag[k] == 0 then
                    self.animation[k]:play("run_loop")
                    runFlag[k] = 1
                end
                local a = math.ceil(self.costTime[k])
                local less = a - index
                if less >= 0 then
                    v:runAction(cc.Sequence:create(
                        cc.MoveTo:create((self.costTime[k] - index >=0 and 1 or self.costTime[k] - index + 1)/10, cc.p(self.tempValue[k][index] + self.leftMarge[k], v:y()))
                    ))
                    self.icon[k]:runAction(cc.Sequence:create(
                        cc.MoveTo:create((less > 0 and 1 or less + 1)/10, cc.p(83 + self.tempValue[k][index] * (670 / data.distance), self.icon[k]:y()))
                    ))
                    self.animation[k]:setTimeScale(math.min(self.secLen[k][index]/self.speed[k], 4))
                    if index < self.maxTimes + 2 then
                        for i, val in pairs(data.crash[k] or {}) do
                            if val == index then
                                self.sprint[k]:setVisible(true)
                                break
                            else
                                self.sprint[k]:setVisible(false)
                            end
                        end
                        for i, val in pairs(self.weak[k]) do
                            if val == index then
                                self.weakness[k]:setVisible(true)
                                break
                            else
                                self.weakness[k]:setVisible(false)
                            end
                        end
                    end
                end
            end
            self.maxBg:runAction(cc.Sequence:create(
                cc.MoveTo:create(1/10, cc.p(self.maxBg:size().width/2 - (self.ls[index] or 0), self.maxBg:y()))
            ))
            self.treeBg:runAction(cc.Sequence:create(
                cc.MoveTo:create(1/10, cc.p(self.montBg:size().width/2 - (self.ls[index] or 0) * 0.8, self.treeBg:y()))
            ))
            self.montBg:runAction(cc.Sequence:create(
                cc.MoveTo:create(1/10, cc.p(self.montBg:size().width/2 - (self.ls[index] or 0) * 0.6, self.montBg:y()))
            ))
            self.could:runAction(cc.Sequence:create(
                cc.MoveTo:create(1/10, cc.p(self.could:size().width/2 - (self.ls[index] or 0) * 0.4, self.could:y()))
            ))
        end
        index = index + 1
    end, 1/10, 2, "delayTime")
    local ranks = {1,1,1,1}
    local function reRank()
        for i, v in pairs(obj) do
            local rank = 1
            for j = 1, 4 do
                if j ~= i and obj[j]:x() - self.leftMarge[j] > v:x() - self.leftMarge[i] then
                    rank = rank + 1
                end
            end
            ranks[i] = rank
        end
    end
    local times = 0
    local beyond = {0,0,0,0}
    self:enableSchedule():schedule(function (dt)
        for i, v in pairs(obj) do
            beyond[i] = beyond[i] - 1
            if v:x() >= data.distance + self.leftMarge[i] - 10 then
                local name = v:get("name")
                name:visible(true)
            else
                if beyond[i] < 0 then
                    local name = v:get("name"):setVisible(false)
                    name:get("tip"):visible(false)
                    name:get("beyond"):visible(true)
                end
            end
            if v:x() >= data.distance + self.leftMarge[i] - 10 and flag[i] == 0 then
                local node = v:get("name"):setVisible(true)
                self.sprint[i]:setVisible(false)
                self.weakness[i]:setVisible(false)
                node:get("tip"):visible(true)
                node:get("beyond"):visible(false)
                node:get("tip"):get("rank"):text(string.format(gLanguageCsv.horseRaceRecordRank, data.result[i]))
                self.animation[i]:play("win_loop")
                self.animation[i]:setTimeScale(1)
                flag[i] = 1
            end
        end
        for i, v in pairs(obj) do
            for key, val in pairs(obj) do
                if key ~= i and val:x() - self.leftMarge[key] < v:x() - self.leftMarge[i] + 10 and ranks[i] > ranks[key] and times > 30  and flag[i] == 0 then
                    v:get("name"):setVisible(true)
                    --name:setVisible(true)
                    --name:get("tip"):visible(false)
                    --name:get("beyond"):visible(true)
                    if beyond[i] < 0 then
                        transition.executeSequence(v:get("name"):get("beyond"))
                            :fadeTo(0,255)
                            :easeBegin("SINEOUT")
                            :fadeTo(1,0)
                            :easeEnd()
                            :done()
                    end
                    beyond[i] = 10
                end
            end
        end
        reRank()
        times = times + 1
    end, 1/10, 2, "places")
    performWithDelay(self, function()
        self:unScheduleAll()
        self:onSkip()
    end, math.ceil(self.maxTimes/10) + 4)
end

function HorseRaceMatch:initRes(data)
    local imgSize = data.distance + 784 + 778
    self.node = self.trackBG:getParent()
    -- 赛道第一层
    self.maxBg = ccui.Layout:create()
        :size(imgSize,720)
        :anchorPoint(0.5, 0.5)
        :xy(imgSize/2 ,735)
        :addTo(self.node, 5, "maxBg")
    self.bg2 = cc.Sprite:create("activity/horse_race/qidian.png")
        :setScale(2)
        :anchorPoint(0.5, 0.5)
        :xy(784/2 + 200 ,346)--784
        :addTo(self.maxBg, 5, "bg2")
    self.bg1 = cc.Sprite:create("activity/horse_race/paodao_04.png")
        :setScaleY(2)
        :setScaleX(data.distance - 500)
        :anchorPoint(0.5, 0.5)
        :xy(imgSize/2 - 150,105)
        :addTo(self.maxBg, 5, "bg1")
    self.bg3 = cc.Sprite:create("activity/horse_race/zhongdian.png")
        :setScale(2)
        :anchorPoint(0.5, 0.5)
        :xy(data.distance + 895,346)
        :addTo(self.maxBg, 5, "bg3")
    -- 跑道
    self.bg4 = cc.Sprite:create("activity/horse_race/dimian_03.png")
        :setScaleY(2)
        :setScaleX(2)
        :anchorPoint(0.5, 0.5)
        :xy(0,103)
        :addTo(self.maxBg, 3, "bg4")
    -- 背景层
    -- 树，草丛
    self.treeBg = ccui.Layout:create()
        :size(imgSize,720)
        :anchorPoint(0.5, 0.5)
        :xy(imgSize/2 ,1334)
        :addTo(self.node, 4, "treeBg")
    local size = 0
    local count = 0
    while(size <= imgSize + 1560)
    do
        cc.Sprite:create("activity/horse_race/dimian_03.png")
            :setScaleY(2)
            :setScaleX(2)
            :anchorPoint(0.5, 0.5)
            :xy(count * 1560 *2 - 50,103)
            :addTo(self.maxBg, 3, "bg4")
        count = count + 1
        size = size + 1560 *2 - 50
    end
    size = 0
    while(size <= imgSize)
    do
        local randes =  math.random(1, 5)
        local marge =  math.random(500, 1000)
        local pic = math.random(4)
        local z = math.random(5, 30)
        if randes > 3 then
            cc.Sprite:create("activity/horse_race/shu_0"..pic ..".png")
                :setScale(2)
                :anchorPoint(0.5, 0.5)
                :xy(0 + size,0 + 230)
                :addTo(self.treeBg, 5, "shu" .. size)
        end
        cc.Sprite:create("activity/horse_race/caocong_0"..pic..".png")
            :setScale(2)
            :anchorPoint(0.5, 0.5)
            :xy(0 + size,0 + z)
            :addTo(self.treeBg, 5, "cao" .. size)
        size = size  + marge
    end
    -- 山
    self.montBg = ccui.Layout:create()
        :size(imgSize,720)
        :anchorPoint(0.5, 0.5)
        :xy(imgSize/2 ,1440)
        :addTo(self.node, 3, "montBg")
    size = 0
    local topMarg = {10, 50, -25, 65,110}
    while(size <= imgSize)
    do
        local marge =  math.random(1200, 1600)
        local pic = math.random(5)
        cc.Sprite:create("activity/horse_race/shan_0"..pic ..".png")
            :setScale(2)
            :anchorPoint(0.5, 0.5)
            :xy(0+size,topMarg[pic])
            :addTo(self.montBg, 5, "shan" .. size)
        size = size  + marge
    end
    -- 云
    self.could = ccui.Layout:create()
        :size(imgSize,720)
        :anchorPoint(0.5, 0.5)
        :xy(imgSize/2 ,1750)
        :addTo(self.node, 2, "could")
    size = 0
    while(size <= imgSize)
    do
        local marge =  math.random(1200, 1600)
        local pic = math.random(2)
        cc.Sprite:create("activity/horse_race/yun_0"..pic ..".png")
            :setScale(2)
            :anchorPoint(0.5, 0.5)
            :xy(0 + size,0)
            :addTo(self.could, 5, "shan" .. size)
        size = size  + marge
    end


    self.icon = {}
    self.obj = {}
    self.animation = {}
    self.weakness = {}
    self.sprint = {}
    local STATE_ACTION = {"standby_loop", "attack", "win_loop", "run_loop"}
    for k, v in pairs(data.player) do
        local p = ccui.Layout:create()
            :size(500,800)
            :xy(self.leftMarge[k],50 + k * 200 - 400)
            :anchorPoint(0.5, 0.5)
            :setScale(1)
            :addTo(self.maxBg, 20 - k, "play"..k)
        local sprint = self.blank:clone():addTo(p, 25):xy(0,100):setVisible(false):alignCenter(p:size())
        widget.addAnimationByKey(sprint, "effect/saipao.skel","sprint","chongci_loop",5):setScale(1.2):anchorPoint(cc.p(0.5, 0.5)):alignCenter(cc.size(sprint:size().width + 50, sprint:size().height -100))
        local weak = self.blank:clone():addTo(p, 25):xy(0,100):setVisible(false):alignCenter(p:size())
        widget.addAnimationByKey(weak, "effect/saipao.skel","weak","xuruo_loop",5):setScale(2):anchorPoint(cc.p(0.5, 0.5)):alignCenter(cc.size(weak:size().width - 0, weak:size().height -100))
        --widget.addAnimationByKey(blank, "effect/saipao.skel","sprint","chongci_loop",5):anchorPoint(cc.p(0.5, 0.5)):alignCenter(cc.size(blank:size().width - 0, blank:size().height -100))
        local rank = self.name:clone():addTo(p, 20):xy(300,680):setVisible(false):anchorPoint(cc.p(0.5, 0.5))
        text.addEffect(rank:get("tip"):get("rank"), { outline = { color = cc.c4b(218, 105, 64, 255), size = 4}})
        local config = csv.cross.horse_race.horse_race_card[v]
        local ani = widget.addAnimation(p, csv.unit[config.unitID].unitRes, "standby_loop", 5)
            :anchorPoint(cc.p(0.5, 0.5))
            :alignCenter(p:size())
            :setScale(2)
        ani:setSkin(csv.unit[config.unitID].skin)
        local ico = nil
        local pos ={-145,75,275,455}
        if k == self.select then  -- 753 -83
            self.bet:clone():addTo(self.maxBg,20 - k):xy(592 + self.leftMarge[k] -500 ,pos[k])
            self.bet:clone():addTo(self.maxBg,20 - k):xy(data.distance  + self.leftMarge[k] + 600 - 770,pos[k])
            ico= cc.Sprite:create("activity/horse_race/icon_horserace_select.png")
                :setScale(1)
                :anchorPoint(0.5, 0.5)
                :xy(83 ,135)
                :addTo(self.lab, 3, "icon"..k)
            cc.Sprite:create(csv.unit[config.unitID].icon)
                :setScale(1)
                :anchorPoint(0.5, 0.5)
                :xy(60 ,80)
                :addTo(ico, 3, "icons"..k)
        else
            ico= cc.Sprite:create("activity/horse_race/icon_horserace_normal.png")
                :setScale(1)
                :anchorPoint(0.5, 0.5)
                :xy(83 ,135)
                :addTo(self.lab, 3, "icon"..k)
            cc.Sprite:create(csv.unit[config.unitID].icon)
                :setScale(1)
                :anchorPoint(0.5, 0.5)
                :xy(55 ,65)
                :addTo(ico, 3, "icons"..k)
        end
        table.insert(self.obj, p)
        table.insert(self.animation, ani)
        table.insert(self.icon, ico)
        table.insert(self.weakness, weak)
        table.insert(self.sprint, sprint)
    end
    --self.animation[1]:play("win_loop")
end

function HorseRaceMatch:onSkip()
    local activityId = self.activityId
    local data = self.data
    local index = self.index
    --if self.cb then
    --    self.cb()
    --end
    ViewBase.onClose(self)
    gGameUI:stackUI("city.activity.horse_race.end", nil, nil, activityId, {data, index})
end

function HorseRaceMatch:onClose()
    ViewBase.onClose(self)
end

return HorseRaceMatch