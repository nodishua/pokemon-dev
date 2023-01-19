-- @Date 2021年8月31日
-- @Desc:  中秋祈福

local IMAGE_PATH ={
    "activity/midautumn_draw/txt_yyqf_fs.png",
    "activity/midautumn_draw/txt_yyqf_zj.png",
    "activity/midautumn_draw/txt_yyqf_gc.png",
    "activity/midautumn_draw/txt_yyqf_rd.png",
    "activity/midautumn_draw/txt_yyqf_sy.png",
}

local ViewBase = cc.load("mvc").ViewBase
local MidAutumnDraw = class("MidAutumnDraw", ViewBase)

MidAutumnDraw.RESOURCE_FILENAME = "activity_midautumn_draw.json"
MidAutumnDraw.RESOURCE_BINDING = {
    ["bg"] = "bg",
    ["rightPanel.btnBless"] = {
        varname = "btnBless",
        binds = {
            event = "touch",
            methods = {ended = bindHelper.self("onSure")},
        },
    },
    ["leftPanel.btnRule"] = {
        varname = "btnRule",
        binds = {
            event = "touch",
            methods = {ended = bindHelper.self("onTips")},
        },
    },
    ["leftPanel.btnTask"] = {
        varname = "btnTask",
        binds = {
            {
                event = "touch",
                methods = {ended = bindHelper.self("onRewardClick")},
            }, {
                event = "extend",
                class = "red_hint",
                props = {
                    state = true,
                    specialTag = "midAutumnTaskAward",
                    listenData = {
                        activityId =  bindHelper.self("activityId"),
                    },
                    onNode = function(node)
                        node:xy(150, 150)
                    end,
                }
            }
        }
    },
    ["rightPanel.imgTimes"] = "imgTimes",
    ["rightPanel.imgTimes.txtTimes"] = "txtTimes",
    ["ticket"] = "imgTicket",
    ["ticket.bg1"] = "bg1",
    ["ticket.bg"] = "bg",
    ["planeBless.tickets"] = "plnTickets",
    ["planeBless"] = "planeBless",
    ["leftPanel.btnRule.txt"] = {
        binds = {
            event = "effect",
            data = {outline = {color = ui.COLORS.NORMAL.WHITE, size = 4}, color = ui.COLORS.NORMAL.DEFAULT}
        }
    },
    ["leftPanel.btnTask.txt"] = {
        varname = "txtTask",
        binds = {
            event = "effect",
            data = {outline = {color = ui.COLORS.NORMAL.WHITE, size = 4}, color = ui.COLORS.NORMAL.DEFAULT}
        }
    },
    ["tips"] = {
        varname = "tips",
        binds = {
            event = "effect",
            data = {outline = {color = ui.COLORS.NORMAL.DEFAULT, size = 4}, color = ui.COLORS.NORMAL.WHITE}
        }
    },
    ["imgSpine"] = "imgSpine",
    ["heroSpine"] = "heroSpine",
    ["endTime"] = {
        varname = "endTime",
        binds = {
            event = "effect",
            data = {outline = {color = ui.COLORS.NORMAL.DEFAULT, size = 4}, color = ui.COLORS.NORMAL.WHITE}
        }
    },
}

function MidAutumnDraw:onCreate(activityId)
    gGameUI.topuiManager:createView("title", self, {onClose = self:createHandler("onClose")})
           :init({title = gLanguageCsv.midAutumnDraw, subTitle = "MidAutumn Bless"})
    self.activityId = activityId
    local activityCfg = csv.yunying.yyhuodong[self.activityId]
    self.huodongID = activityCfg.huodongID
    self.roundTime, self.ticket, self.tickets, self.ticketsAnimation, self.ticketsBone = 0, 0, {}, {}, {}
    self:initModel()
    self.addedTickets = 0
    self.commonPool, self.bestPool = {}, {}
    for i, v in orderCsvPairs(csv.yunying.mid_autumn_draw) do
        if v.huodongID == self.huodongID then
            self.roundTime = self.roundTime + 1
            if v.commonPoolID then
                table.insert(self.commonPool, v.commonPoolID.lib)
            end
            if v.bestPoolID then
                table.insert(self.bestPool, v.bestPoolID.lib)
            end
        end
    end
    idlereasy.when(self.yyhuodongs, function(_, yyhuodongs)
        local yyData = yyhuodongs[activityId] or {}
        self.drawTimes = yyData.info and yyData.info.draw_times or 0
        self.txtTimes:text(string.format(gLanguageCsv.midAutumnCanDraw, self.drawTimes))
        self.ticket = yyData.info and yyData.info.round_counter or 0 -- 签数
    end)
    self:initTickets(self.roundTime - 1)
    self:refreshAnimation()
    self.tips:text(string.format(gLanguageCsv.midAutumnTips, self.roundTime))
    self.enter = widget.addAnimationByKey(self.btnBless, "zhongqiuqifu/anniu.skel", "anniu", "effect", 10)
          :scale(0.75)
          :xy(200, 105)
    performWithDelay(self, function()
       self.enter:play("standby_loop")
    end , 0.8)
    self.player = widget.addAnimationByKey(self.heroSpine, "zhongqiuqifu/shanaiduo.skel", "hero", "standby_loop", 10)
        :scale(2)
        :xy(200, 200)
    --self:runAnimation()
    self:showEndTime()
    self.txtTimes:xy((self.txtTimes:size().width + 130)/2, self.imgTimes:size().height/2)
    self.imgTimes:size(self.txtTimes:size().width + 130, self.imgTimes:size().height)
    self.txtTask:text(gLanguageCsv.midAutumnTask)
end

function MidAutumnDraw:initModel()
    self.yyhuodongs = gGameModel.role:getIdler("yyhuodongs")
end

function MidAutumnDraw:runAnimation()
    local position = {x = self.btnPreview:x(), y = self.btnPreview:y()}
    local action2 = cc.EaseSineInOut:create( cc.MoveTo:create(1, cc.p(position.x, position.y + 10)))
    local action3 = cc.EaseSineInOut:create( cc.MoveTo:create(1, cc.p(position.x, position.y - 10)))
    local sequence = cc.Sequence:create(action2, action3)
    local action = cc.RepeatForever:create(sequence)
    self.btnPreview:runAction(action)
end

-- 星
function MidAutumnDraw:refreshAnimation()
    local star = ccui.ImageView:create("activity/midautumn_draw/img_ttqf_xx.png")
        :anchorPoint(0.5, 0.5)
        :xy(100, 250)
    local function getAction(node, i, x, y, from, to, stop, delay)
        local t = star:clone():show():addTo(node, 10, "star"..i):xy(x, y):scale(0)
        performWithDelay(self, function()
            local action3 = cc.EaseSineInOut:create(cc.ScaleTo:create(0.2, to))
            local sequence = cc.Sequence:create(cc.ScaleTo:create(0.2,from), cc.DelayTime:create(delay), action3, cc.DelayTime:create(0.1))
            local action = cc.RepeatForever:create(sequence)
            t:runAction(action)
        end,stop)
    end
    for i, v in ipairs(self.tickets) do
        local child = v:multiget("ticketShow", "ticket")
        if i < self.ticket and i > self.addedTickets then
            getAction(child.ticketShow,1,152, 286, 0,1.3, 0,0.6)
            getAction(child.ticketShow,2,259, 418, 0,1.3, 0.2,0.6)
            getAction(child.ticketShow,3,258, 543, 0,0.7, 0.4,0.6)
            getAction(child.ticketShow,4,155, 700, 0,1, 0.1,0.6)
            self.addedTickets = i
        end
    end
end

function MidAutumnDraw:showEndTime()
    local yyEndtime = gGameModel.role:read("yy_endtime")[self.activityId]
    local endDate = time.getDate(math.floor(yyEndtime))
    local cfg = csv.yunying.yyhuodong[self.activityId]
    endDate.hour = cfg.endTime / 100
    endDate.min = cfg.endTime % 100
    endDate.sec = 0
    bind.extend(self, self.endTime, {
        class = 'cutdown_label',
        props = {
            endTime = yyEndtime,
            strFunc = function(t)
                --return string.format("%s,%s", t.daystr, t.hourstr, t.hourstr, t.secstr)
                return string.format(gLanguageCsv.bcActivityTime, t.str)
            end,
            endFunc = function()
                -- self:gameOver()
                self.endTime:y(self.endTime:y() + 24)
                self.endTime:text(gLanguageCsv.activityOver)
            end,
        }
    })
end

function MidAutumnDraw:initTickets(num)
    local POSITION= {
        CENTER = 700,  -- 中心点， 偶数个时535
        Y = 275,  -- 每个牌子大小
        SIZE = 1125,  -- 每个所有牌子大小
    }
    num = num or 5
    local marge = POSITION.SIZE/num
    local positionX = POSITION.CENTER - math.floor(num/2) * marge + (num + 1)%2 * marge/2
    for i = 1, num do
        local a = self.plnTickets:clone()
            :addTo(self.planeBless,10)
            :xy(positionX, POSITION.Y)
            :show()
        table.insert(self.tickets, a)
        positionX = positionX + marge
        local child = a:multiget("ticketShow", "ticket")
        if i < self.ticket then
            child.ticketShow:get("txt"):texture(IMAGE_PATH[i])
            child.ticketShow:show()
            child.ticket:hide()
        else
            child.ticketShow:hide()
            child.ticket:show()
        end
    end
end

function MidAutumnDraw:onSure()
    if self.drawTimes > 0  then
        gGameUI:disableTouchDispatch(1.3)
        self.enter:play("effect")
        self.player:play("effect")
        performWithDelay(self, function()
            self.enter:play("standby_loop")
            self.player:play("standby_loop")
            gGameApp:requestServer("/game/yy/award/draw", function(tb)
                if tb.view.hit == 1 then
                    gGameUI:stackUI("common.gain_display", nil, nil, tb, {cb = self:createHandler("onTicketRotation"), tips = {str = gLanguageCsv.midAutumnGet, foneSize = 50, position = {x = 1270,y = 900}, anchorPoint = {x = 0.5, y =0.5}}})
                else
                    gGameUI:stackUI("common.gain_display", nil, nil, tb, {cb = self:createHandler("onShowTicket")})
                end
            end, self.activityId, "blessing")
        end, 1.3)
    else
        gGameUI:showTip(gLanguageCsv.noTicketDraw)
    end
end

function MidAutumnDraw:onShowTicket()
    gGameUI:stackUI("city.activity.mid_autumn_draw_mask", nil, {blackLayer = true}, self.activityId, {cb = self:createHandler("onTicketRotation"), num = self.roundTime - 1, times = self.ticket})
end

function MidAutumnDraw:onTicketRotation()
    for i, v in pairs(self.tickets) do
        local child = v:multiget("ticketShow", "ticket", "txt")
        if i < self.ticket then
            child.ticketShow:get("txt"):texture(IMAGE_PATH[i])
            child.ticketShow:show()
            child.ticket:hide()
        else
            child.ticketShow:hide()
            child.ticketShow:hide()
            child.ticket:show()
        end
        if i == self.ticket - 1 then
            child.ticketShow:hide()
            child.ticket:hide()
            local anim = widget.addAnimationByKey(v, "zhongqiuqifu/zhongqiupaizi.skel", nil, "effect_fanzhuan", 1)
                :scale(0.5)
                :xy(111, 207)
            local nodes = child.ticketShow:get("txt"):clone():show():addTo(v, 10):texture(IMAGE_PATH[i])
            local action = cc.RepeatForever:create(
                    cc.Sequence:create(
                    cc.CallFunc:create(function()
                        local posx, posy = anim:getPosition()
                        local sx, sy = anim:getScaleX(), anim:getScaleY()
                        local bxy = anim:getBonePosition("wenzi")
                        local rotation = anim:getBoneRotation("wenzi")
                        local scaleX = anim:getBoneScaleX("wenzi")
                        local scaleY = anim:getBoneScaleY("wenzi")
                        nodes:rotate(-rotation)
                             :scaleX(scaleX/2)
                             :scaleY(scaleY/2)
                             :xy(cc.p(bxy.x * sx + posx, bxy.y * sy + posy))
                        if scaleX == 1 and rotation == 0 then
                            child.ticketShow:show()
                            nodes:removeFromParent()
                            anim:removeFromParent()
                            self:refreshAnimation()
                        end
                    end)
            ))
            nodes:runAction(action)
            --self.ticketsAnimation[i] = anim
            --self.ticketsBone[i] = nodes
        else
            if self.ticketsAnimation[i] then
                self.ticketsAnimation[i]:removeFromParent()
                self.ticketsAnimation[i] = nil
            end
            if self.ticketsBone[i] then
                self.ticketsBone[i]:removeFromParent()
                self.ticketsBone[i] = nil
            end
        end
    end
end

function MidAutumnDraw:onTips()
    gGameUI:stackUI("common.rule", nil, nil, self:createHandler("getRuleContext"), {width = 1000})
end

function MidAutumnDraw:getRuleContext(view)
    local c = adaptContext
    local context = {
        c.clone(view.title, function(item)
            item:get("text"):text(gLanguageCsv.midAutumnRule)
        end),
        c.noteText(125301, 125400)
    }
    return context
end

function MidAutumnDraw:onRewardClick()
    gGameUI:stackUI("city.activity.mid_autumn_draw_task", nil, {blackLayer = false}, self.activityId)
end

return MidAutumnDraw
