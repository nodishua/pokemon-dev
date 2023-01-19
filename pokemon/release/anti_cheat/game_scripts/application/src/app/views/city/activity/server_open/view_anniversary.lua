-- @date 2020-4-30 21:46:10
-- @desc 五一嘉年华 - view

local ServerOpenDialog =  require("app.views.city.activity.server_open.view")
local AnniversaryServerOpenDialog = class("AnniversaryServerOpenDialog", ServerOpenDialog)

AnniversaryServerOpenDialog.RESOURCE_FILENAME = "activity_server_open_anniversary.json"
AnniversaryServerOpenDialog.RESOURCE_BINDING = ServerOpenDialog.RESOURCE_BINDING
AnniversaryServerOpenDialog.clientType = "anniversary"

return AnniversaryServerOpenDialog