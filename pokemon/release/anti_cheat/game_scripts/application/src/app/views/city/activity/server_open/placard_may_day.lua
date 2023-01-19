-- @date 2020-4-30 22:02:23
-- @desc 五一嘉年华 - placard

local ServerOpenPlacardDialog =  require("app.views.city.activity.server_open.placard")
local MayDayServerOpenPlacardDialog = class("MayDayServerOpenPlacardDialog", ServerOpenPlacardDialog)

MayDayServerOpenPlacardDialog.RESOURCE_FILENAME = "activity_server_open_placard_may_day.json"
MayDayServerOpenPlacardDialog.RESOURCE_BINDING = ServerOpenPlacardDialog.RESOURCE_BINDING
MayDayServerOpenPlacardDialog.clientType = "mayDay"

return MayDayServerOpenPlacardDialog