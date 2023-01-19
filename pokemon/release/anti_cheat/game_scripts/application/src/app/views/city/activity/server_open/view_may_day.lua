-- @date 2020-4-30 21:46:10
-- @desc 五一嘉年华 - view

local ServerOpenDialog =  require("app.views.city.activity.server_open.view")
local MayDayServerOpenDialog = class("MayDayServerOpenDialog", ServerOpenDialog)

MayDayServerOpenDialog.RESOURCE_FILENAME = "activity_server_open_may_day.json"
MayDayServerOpenDialog.RESOURCE_BINDING = ServerOpenDialog.RESOURCE_BINDING
MayDayServerOpenDialog.clientType = "mayDay"

return MayDayServerOpenDialog