-- @date 2020-4-30 22:02:23
-- @desc 双旦嘉年华 - placard

local ServerOpenPlacardDialog =  require("app.views.city.activity.server_open.placard")
local AnniversaryServerOpenPlacardDialog = class("AnniversaryServerOpenPlacardDialog", ServerOpenPlacardDialog)

AnniversaryServerOpenPlacardDialog.RESOURCE_FILENAME = "activity_server_open_placard_anniversary.json"
AnniversaryServerOpenPlacardDialog.RESOURCE_BINDING = ServerOpenPlacardDialog.RESOURCE_BINDING
AnniversaryServerOpenPlacardDialog.clientType = "anniversary"

return AnniversaryServerOpenPlacardDialog