-- @date 2020-09-16 11:46:17
-- @desc 国庆中秋嘉年华 - placard

local ServerOpenPlacardDialog =  require("app.views.city.activity.server_open.placard")
local NationalMidAutumnServerOpenPlacardDialog = class("NationalMidAutumnServerOpenPlacardDialog", ServerOpenPlacardDialog)

NationalMidAutumnServerOpenPlacardDialog.RESOURCE_FILENAME = "activity_server_open_placard_national_mid_autumn.json"
NationalMidAutumnServerOpenPlacardDialog.RESOURCE_BINDING = ServerOpenPlacardDialog.RESOURCE_BINDING
NationalMidAutumnServerOpenPlacardDialog.clientType = "national"

return NationalMidAutumnServerOpenPlacardDialog