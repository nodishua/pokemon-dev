-- @date 2021-03-16
-- @desc 走格子-幸运转盘界面

-- 转盘最大数量
local MAX_REWARD_NUMS = 8

-- 抽奖动画时间：free/once 2s all 3s
local ANI_TIME = 2

-- 抽奖基础圈数旋转完成后，到指定奖励需要的时间
local AIN_TIME_LESS = 1

-- 抽奖转盘基础旋转圈数 free/once 2圈 all 10圈
local ANI_ROTATION = 2*360

local gridWalkTools = require "app.views.city.activity.grid_walk.tools"
local ViewBase = cc.load("mvc").ViewBase
local GridWalkWheelView = class("GridWalkWheelView", ViewBase)
GridWalkWheelView.RESOURCE_FILENAME = "grid_walk_wheel.json"
GridWalkWheelView.RESOURCE_BINDING = {
    ["wheelPanel"] = "wheelPanel",
    ["wheelPanel.wheel"] = "wheel",
    ["wheelPanel.wheelPointer"] = {
        varname = "wheelPointer",
        binds = {
            event = "touch",
            methods = {ended = bindHelper.self("onDraw")}
        },
    },
}

function GridWalkWheelView:onCreate(params)
	self.event = params.event
	self.callBack = params.callBack

	self:initModel()
    -- 转盘奖励信息显示
    self:initReward()
    -- 特效
    self:initSkel()
end

function GridWalkWheelView:initModel()
    self.yyhuodongs = gGameModel.role:getIdler("yyhuodongs")
	self.yyId = gGameModel.role:read("grid_walk").yy_id
	self.opened = idler.new(false)
end

function GridWalkWheelView:initReward()
    -- 组装转盘奖励信息，读取yyhuodong表clientParam字段
    self.rewardDatas = {}
    local huodongID = csv.yunying.yyhuodong[self.yyId].huodongID
    local cfg = gridWalkTools.getCfgByEventFromEvents(gridWalkTools.EVENTS.goodLuck, huodongID)
    for k,v in csvMapPairs(cfg.params.items) do
        table.insert(self.rewardDatas, {key = v[1], num = v[2]})
    end
    for i=1, MAX_REWARD_NUMS do
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

function GridWalkWheelView:onDraw()
    self.wheelPointer:setTouchEnabled(false)
    self.wheelSkel:play("effect_chou")
    local aniTime = 0
    local aniRotationTotal = 0
    local aniRotationLess = 0
    aniTime, aniRotationTotal, aniRotationLess = self:getAniParams()
    self:wheelAni(aniTime, aniRotationTotal, aniRotationLess)

    performWithDelay(self, function()
    	local tb = {}
    	local award = self.rewardDatas[self.event.params.outcome + 1]
    	tb[award.key] = award.num
        if award.key == gridWalkTools.BADGE_ID then
            self.badgeNum = award.num
        end
    	local function cb()
			self.opened:set(true)
    		self:onClose()
    	end
        gGameUI:showGainDisplay(tb, {cb = cb})
        self.wheelSkel:play("effect_loop")
        self.wheelPointer:setTouchEnabled(true)
    end, aniTime)
end

function GridWalkWheelView:wheelAni(aniTime, aniRotationTotal, aniRotationLess)
    self.wheel:setRotation(0)
    transition.executeSequence(self.wheel, true)
        :easeBegin("EXPONENTIALOUT")
            :rotateBy(aniTime - AIN_TIME_LESS, aniRotationTotal - aniRotationLess)
            :rotateBy(AIN_TIME_LESS, aniRotationLess + 360)
        :easeEnd()
        :done()
end

function GridWalkWheelView:getAniParams()
    local aniTime = ANI_TIME
    local aniRotation = ANI_ROTATION

    local stopIndex = self.event.params.outcome + 1
    local lessTime = ((MAX_REWARD_NUMS - stopIndex + 1)/MAX_REWARD_NUMS)*360
    aniRotation = aniRotation + lessTime

    return aniTime, aniRotation, lessTime
end

function GridWalkWheelView:initSkel()
    self.wheelSkel = widget.addAnimationByKey(self.wheelPanel, "gridwalk/jianglidzp.skel", 'wheelSkel', "effect_loop", 2)
    self.wheelSkel:anchorPoint(cc.p(0.5,0.5))
        :xy(self.wheelPointer:x(), self.wheelPointer:y() - 10)
        :scale(2)
end

function GridWalkWheelView:onClose()
	if self.opened:read() == true then
		self:addCallbackOnExit(functools.partial(self.callBack, self.badgeNum))
		ViewBase.onClose(self)
	end
end

return GridWalkWheelView
