-- @date 2020-1-20 22:02:23
-- @desc 鼠年嘉年华 - placard

local ServerOpenPlacardDialog =  require("app.views.city.activity.server_open.placard")
local SpringFestivalServerOpenPlacardDialog = class("SpringFestivalServerOpenPlacardDialog", ServerOpenPlacardDialog)

SpringFestivalServerOpenPlacardDialog.RESOURCE_FILENAME = "activity_server_open_placard_spring_festival.json"
SpringFestivalServerOpenPlacardDialog.RESOURCE_BINDING = ServerOpenPlacardDialog.RESOURCE_BINDING
SpringFestivalServerOpenPlacardDialog.clientType = "springFestival"

return SpringFestivalServerOpenPlacardDialog