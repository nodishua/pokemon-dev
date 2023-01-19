-- @desc: 	activity-单笔充钻石返还
-- @date:	2020-1-15 10:45:42

-- 定时器tag集合
local TAG = {
    count = 1,
}

-- 最大充值商品数量
local MAX_RECHARGE_NUMS = 7

-- 单笔充值商品状态
local RECHARGE_STATE = {
    got = 0,    -- 已领取
    get = 1,    -- 可领取
    none = 2,   -- 不可领取
}

local OnceRechargeAwardView = class("OnceRechargeAwardView", Dialog)
OnceRechargeAwardView.RESOURCE_FILENAME = "activity_once_recharge_award.json"
OnceRechargeAwardView.RESOURCE_BINDING = {
    ["btnClose"] = {
        binds = {
            event = "touch",
            methods = {ended = bindHelper.self("onClose")}
        },
    },
    ["time"] = "countTime",
    ["btnRules"] = {
        binds = {
            event = "touch",
            methods = {ended = bindHelper.self("onRules")}
        },
    },
    ["tips"] = {
        binds = {
            event = "effect",
            data = {outline={color=cc.c4b(25, 85, 168, 255)}},
        },
    },
}

function OnceRechargeAwardView:onCreate(activityId)
    self.yyCfg = csv.yunying.yyhuodong[activityId]
    self.activityId = activityId
    self:enableSchedule()

    -- model
	self:initModel()
    -- 充值信息
    self:initRecharge()
    -- 倒计时
    self:initCountTime()
    -- 特效
    self:initSkel()

    Dialog.onCreate(self, {blackType = 1})
end

function OnceRechargeAwardView:initModel()
    self.yyhuodongs = gGameModel.role:getIdler("yyhuodongs")
    self.yyEndtime = gGameModel.role:getIdler("yy_endtime")
end

function OnceRechargeAwardView:initRecharge()
    local cfg = csv.yunying.oncerechage
    idlereasy.when(self.yyhuodongs, function (obj, yyhuodongs)
        local yydata = yyhuodongs[self.activityId] or {}
        local stamps = yydata.stamps or {}
        local rechargeDatas = {}
        for k,v in orderCsvPairs(csv.yunying.oncerechage) do
            if self.yyCfg.huodongID == v.huodongID then
                local data = {}
                data.csvId = k
                data.cfg = v
                data.state = stamps[k] and stamps[k] or RECHARGE_STATE.none
                table.insert(rechargeDatas, data)
            end
        end

        for i=1,MAX_RECHARGE_NUMS do
            local info = rechargeDatas[i]
            local node = self:getResourceNode():get("rechargeItem"..i)
            node:visible(info ~= nil)
            local childs = node:multiget("txtTitleNode", "rechargeNum", "iconDiamondTtitle", "icon", "txtDescNode", "awardNum", "btnRecharge", "txtGot")
            if info then
                childs.rechargeNum:text(info.cfg.needRmb)
                childs.icon:texture(info.cfg.icon)
                local awardKey,awardNum = csvNext(info.cfg.award)
                childs.awardNum:text(awardNum)
                text.addEffect(childs.txtDescNode, {outline={color=cc.c4b(61, 133, 204, 255), size=3}})
                bind.touch(self, childs.btnRecharge, {methods = {ended = function()
                    self:onRechargeClick(info.state, info.csvId)
                end}})
                childs.btnRecharge:get("txtNode"):text(info.state == RECHARGE_STATE.none and gLanguageCsv.goRecharge.."!" or gLanguageCsv.onlineGiftGet)
                childs.btnRecharge:visible(info.state ~= RECHARGE_STATE.got)
                childs.txtGot:visible(info.state == RECHARGE_STATE.got)
                adapt.oneLineCenterPos(cc.p(213, 504), {childs.txtTitleNode, childs.rechargeNum, childs.iconDiamondTtitle},cc.p(5, 0))
                -- 充值/领取特效
                node:removeChildByName("rechargeAndGotSkel")
                if info.state ~= RECHARGE_STATE.got then
                    local rechargeAndGotSkel = widget.addAnimationByKey(node, "chongzhifanzuan/chongzhifanzuan.skel", 'rechargeAndGotSkel', "effect_kechongzhi_loop", 99)
                    rechargeAndGotSkel:anchorPoint(cc.p(0.5,0.5))
                        :xy(childs.btnRecharge:x(), childs.btnRecharge:y())
                        :scale(2)
                    if info.state == RECHARGE_STATE.get then
                        rechargeAndGotSkel:play("effect_kelingqu_loop")
                    end
                end
            end
        end
    end)
end

function OnceRechargeAwardView:onRechargeClick(state, csvId)
    if state == RECHARGE_STATE.none then
        jumpEasy.jumpTo("recharge")
    elseif state == RECHARGE_STATE.get then
        gGameApp:requestServer("/game/yy/award/get", function(tb)
            gGameUI:showGainDisplay(tb)
        end, self.activityId, csvId)
    else
        printWarn("error state")
    end
end

function OnceRechargeAwardView:initCountTime()
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
        self.countTime:text(time.getCutDown(countdown, true).str)
        if countdown <= 0 then
            self:onClose()
            return false
        end
    end, 1, 0, tag)
end

function OnceRechargeAwardView:initSkel()
    local pNode = self:getResourceNode()
    local bgSkel = widget.addAnimationByKey(pNode, "chongzhifanzuan/chongzhifanzuan.skel", 'bgSkel', "effect_shanguang_loop", 99)
    bgSkel:anchorPoint(cc.p(0.5,0.5))
        :xy(pNode:width()/2, pNode:height()/2)
        :scale(2)

end

function OnceRechargeAwardView:onRules()
    gGameUI:stackUI("common.rule", nil, nil, self:createHandler("getRuleContext"), {width = 750})
end

function OnceRechargeAwardView:getRuleContext(view)
    local c = adaptContext
    local context = {
        c.clone(view.title, function(item)
            item:get("text"):text(gLanguageCsv.rules)
        end),
        c.noteText(71001, 71004),
    }
    return context
end

return OnceRechargeAwardView
