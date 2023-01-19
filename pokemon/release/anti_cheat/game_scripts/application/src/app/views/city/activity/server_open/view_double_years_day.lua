-- @date 2020-4-30 21:46:10
-- @desc 双旦嘉年华 - view

local ServerOpenDialog =  require("app.views.city.activity.server_open.view")
local DoubleYearsDayServerOpenDialog = class("DoubleYearsDayServerOpenDialog", ServerOpenDialog)

DoubleYearsDayServerOpenDialog.RESOURCE_FILENAME = "activity_server_open_double_years_day.json"
DoubleYearsDayServerOpenDialog.RESOURCE_BINDING = ServerOpenDialog.RESOURCE_BINDING
DoubleYearsDayServerOpenDialog.clientType = "doubleYearsDay"

return DoubleYearsDayServerOpenDialog