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
local MidAutumnDrawMask = class("MidAutumnDrawMask", ViewBase)

MidAutumnDrawMask.RESOURCE_FILENAME = "activity_midautumn_maks.json"
MidAutumnDrawMask.RESOURCE_BINDING = {
     ["btnClose"] = {
         varname = "btnClose",
         binds = {
             event = "touch",
             methods = {ended = bindHelper.self("onClose")},
         },
     },
     ["mask.txtPlane"] ="txtPlane",
     ["mask.spine.img"] ="img",
}

function MidAutumnDrawMask:onCreate(activityId, params)
    self.cb = params.cb
    rich.createByStr(string.format(gLanguageCsv.midAutumnGetTicket, gLanguageCsv["midAutumnTicket" .. params.times - 1]), 40)
        :xy(405,124)
        :anchorPoint(0.5, 0.5)
        :addTo(self.txtPlane, 5)
    rich.createByStr(string.format(gLanguageCsv.midAutumnGetTicketInfo, params.num), 40)
        :xy(405,45)
        :anchorPoint(0.5, 0.5)
        :addTo(self.txtPlane, 5)
    local star = ccui.ImageView:create(IMAGE_PATH[params.times - 1])
        :anchorPoint(0.5, 0.5)
        :xy(210, 420)
        :addTo(self.img)
    self.img:texture("activity/midautumn_draw/icon_yyqf_whd2.png")
end

function MidAutumnDrawMask:onClose()
    self:addCallbackOnExit(self.cb)
    ViewBase.onClose(self)
end

return MidAutumnDrawMask
