-- @date 2020-4-30 22:02:23
-- @desc 双旦嘉年华 - placard

local ServerOpenPlacardDialog =  require("app.views.city.activity.server_open.placard")
local DoubleYearsDayServerOpenPlacardDialog = class("DoubleYearsDayServerOpenPlacardDialog", ServerOpenPlacardDialog)

DoubleYearsDayServerOpenPlacardDialog.RESOURCE_FILENAME = "activity_server_open_placard_double_years_day.json"
DoubleYearsDayServerOpenPlacardDialog.RESOURCE_BINDING = ServerOpenPlacardDialog.RESOURCE_BINDING
DoubleYearsDayServerOpenPlacardDialog.clientType = "doubleYearsDay"

return DoubleYearsDayServerOpenPlacardDialog