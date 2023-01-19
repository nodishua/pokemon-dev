-- @Date 2021年8月31日
-- @Desc:  中秋祈福

local GET_TYPE = {
    GOTTEN = 0, 	--已领取
    CAN_GOTTEN = 1, --可领取
    CAN_NOT_GOTTEN = 2, --未完成
}
local MidAutumnTask = class("MidAutumnTask", Dialog)

MidAutumnTask.RESOURCE_FILENAME = "activity_midautumn_task.json"
MidAutumnTask.RESOURCE_BINDING = {
    ["topPanel.btnClose"] = {
        binds = {
            event = "touch",
            methods = {ended = bindHelper.self("onClose")},
        },
    },
    ["topPanel.txt1"] = "txt1",
    ["leftPanel.tabItem"] = "tabItem",
    ["leftPanel.tabList"] = {
        binds = {
            event = "extend",
            class = "listview",
            props = {
                data = bindHelper.self("tabDatas"),
                item = bindHelper.self("tabItem"),
                showTab = bindHelper.self("showTab"),
                onItem = function(list, node, k, v)
                    local normal = node:get("normal")
                    local selected = node:get("selected")
                    local panel
                    if v.select then
                        normal:hide()
                        panel = selected:show()
                    else
                        selected:hide()
                        panel = normal:show()
                    end
                    if v.redHint then
                        bind.extend(list, node, {
                            class = "red_hint",
                            props = {
                                state = list.showTab:read() ~= k,
                                specialTag = v.redHint,
                                listenData = {
                                    activityId = v.id,
                                },
                                onNode = function (red)
                                    red:xy(node:width() - 60, node:height() - 5)
                                end
                            },
                        })
                    end
                    panel:get("txt"):getVirtualRenderer():setLineSpacing(-5)
                    panel:get("txt"):text(v.name)
                    selected:setTouchEnabled(false)
                    bind.touch(list, normal, {methods = {ended = functools.partial(list.clickCell, k)}})
                end,
            },
            handlers = {
                clickCell = bindHelper.self("onTabClick"),
            },
        },
    },
    ["rewardPanel1"] = "rewardPanel1",
    ["rewardPanel2"] = "rewardPanel2",
    ["rewardPanel1.tips"] = "tips",
    ["rankItem"] = "rankItem",
    ["infoItem"] = "infoItem",
    ["rewardPanel1.list"] = {
        varname = "list",
        binds = {
            event = "extend",
            class = "listview",
            props = {
                asyncPreload = 5,
                data = bindHelper.self("achvDatas1"),
                item = bindHelper.self("rankItem"),
                dataOrderCmpGen = bindHelper.self("onSortCards", true),
                itemAction = {isAction = true},
                onItem = function(list, node, k, v)
                    local childs = node:multiget("achvDesc", "btnGet", "list", "got", "icon", "txtTimes")
                    childs.txtTimes:text(v.addTimes)
                    text.addEffect(childs.txtTimes, {outline={color=ui.COLORS.QUALITY_OUTLINE[5]}})
                    childs.achvDesc:text(v.desc)
                    bind.touch(list, childs.btnGet, {methods = {ended = functools.partial(list.clickCell, v.csvId)}})
                    -- 0已领取，1可领取
                    childs.got:visible(v.get == GET_TYPE.GOTTEN)
                    childs.btnGet:visible(v.get ~= GET_TYPE.GOTTEN)
                    childs.btnGet:get("txt"):text((v.get == GET_TYPE.GOTTEN) and gLanguageCsv.received or gLanguageCsv.spaceReceive)
                    if v.get ~= GET_TYPE.GOTTEN and v.get ~= GET_TYPE.CAN_GOTTEN then
                        childs.btnGet:get("txt"):setFontSize(40)
                        if v.taskParam then
                            childs.btnGet:get("txt"):text(v.progress  .. "/" .. v.taskParam)
                        else
                            local key, val = next(v.taskSpecialParam)
                            local str = v.progress .. "/" .. key
                            childs.btnGet:get("txt"):text(str)
                        end
                    end
                    --local width = childs.btnGet:get("txt"):size().width
                    --if width > 180 then
                    --    local font = 50 - (width - 180)/4
                    --    childs.btnGet:get("txt"):setFontSize(font)
                    --end
                    uiEasy.setBtnShader(childs.btnGet, childs.btnGet:get("txt"), v.get)
                end,
            },
            handlers = {
                clickCell = bindHelper.self("onGetBtn"),
            },
        },
    },
    ["rewardPanel2.list"] = {
        varname = "list2",
        binds = {
            event = "extend",
            class = "listview",
            props = {
                asyncPreload = 5,
                data = bindHelper.self("achvDatas2"),
                item = bindHelper.self("infoItem"),
                dataOrderCmpGen = bindHelper.self("onSortNotes", true),
                onItem = function(list, node, k, v)
                    local childs = node:multiget("txtTimes", "txtInfo", "get", "list")
                    local richText = rich.createByStr(string.format(gLanguageCsv.midAutumnDrawTime, v.id), 43)
                        :xy(0,80)
                        :anchorPoint(0, 0.5)
                        :addTo(childs.txtInfo, 5)
                    local str = v.hit == 1 and gLanguageCsv.midAutumnGetBestNote or gLanguageCsv.midAutumnGetNote
                    rich.createByStr(str, 40)
                        :xy(0,20)
                        :anchorPoint(0, 0.5)
                        :addTo(childs.txtInfo, 5)
                    uiEasy.createItemsToList(list, childs.list, v.stamps, {scale = 0.8})
                end,
            },
            handlers = {
                clickCell = bindHelper.self("onGetBtn"),
            },
        },
    },
    ["rewardPanel2.noAward"] = "noAward",
    ["rewardPanel1.btnGetAll"] = {
        varname = "btnGetAll",
        binds = {
            event = "touch",
            methods = {ended = bindHelper.defer(function(view)
                gGameApp:requestServer("/game/yy/mid_autumn_draw/task_award/get/onekey",function (tb)
                    gGameUI:showTip(string.format(gLanguageCsv.midAutumnGetTimes,tb.view))
                end, view.activityId)
            end)},
        },
    },
    ["rewardPanel1.btnGetAll.txt"] = "txtGetAll",
}

function MidAutumnTask:onCreate(id)
    self:initModel()
    self.activityId = id
    self.showTab = idler.new(1)
    self.achvDatas1 = idlers.new()
    self.achvDatas2 = idlers.new()
    self.tabDatas = idlers.newWithMap({
        [1] = {name = gLanguageCsv.midAutumnTask, redHint = "midAutumnTaskAward",id = self.activityId, type = 1},
        [2] = {name = gLanguageCsv.midAutumnBlessNote,id = self.activityId, type = 2},
    })
    local text = {[1] = gLanguageCsv.task, [2] = gLanguageCsv.midAutumnNote}


    idlereasy.when(self.yyhuodongs, function(_, yyhuodongs)
        local yyData = yyhuodongs[self.activityId] or {}
        local activityCfg = csv.yunying.yyhuodong[self.activityId]
        self.huodongID = activityCfg.huodongID

        local valsums = yyData.valsums or {}
        local data1 = {}
        local data2 = {}
        uiEasy.setBtnShader(self.btnGetAll, self.txtGetAll, 2)
        for i, v in pairs(yyData.stamps or {}) do
            if v == GET_TYPE.CAN_GOTTEN then
                uiEasy.setBtnShader(self.btnGetAll, self.txtGetAll, 1)
                break
            end
        end
        for i, v in orderCsvPairs(csv.yunying.mid_autumn_draw_tasks) do
            if v.huodongID == self.huodongID then
                local data = table.shallowcopy(v)
                data.csvId = i
                data.progress = valsums[i] or 0
                local stamps = yyData.stamps or {}
                data.get = stamps[i]
                table.insert(data1, data)
            end
        end
        local note = yyData.mid_autumn_draw or {}
        if itertools.size(note) <= 0 then
            self.noAward:show()
        else
            self.noAward:hide()
        end
        for k, v in pairs(note) do
            local value = table.deepcopy(v, true)
            value.hit = nil
            table.insert(data2, {stamps = value, hit = v.hit, id = k})
        end
        table.sort(data2, function(a,b) return a.id > b.id end)
        self.achvDatas1:update(data1)
        self.achvDatas2:update(data2)
    end)

    self.showTab:addListener(function(val, oldval)
        self.tabDatas:atproxy(oldval).select = false
        self.tabDatas:atproxy(val).select = true
        self.txt1:text(text[val])
        if self["rewardPanel"..oldval] then
            self["rewardPanel"..oldval]:hide()
        end
        self["rewardPanel"..val]:show()
    end)

    self.rewardPanel1:show()

    self.tips:text(string.format(gLanguageCsv.resetTask, time.getRefreshHour()))
    Dialog.onCreate(self)
end

function MidAutumnTask:initModel()
    self.yyhuodongs = gGameModel.role:getIdler("yyhuodongs")
end

function MidAutumnTask:onTabClick(list, index)
    self.showTab:set(index)
end

function MidAutumnTask:onGetBtn(list, csvId)
    gGameApp:requestServer("/game/yy/mid_autumn_draw/task_award/get",function (tb)
        gGameUI:showTip(string.format(gLanguageCsv.midAutumnGetTimes, tb.view))
    end, self.activityId, csvId)
end

function MidAutumnTask:onSortCards(list)
    return function(a, b)
        local va = a.get or 0.5
        local vb = b.get or 0.5
        if va ~= vb then
            return va > vb
        end
        return a.csvId < b.csvId
    end
end


return MidAutumnTask