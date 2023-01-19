-- @date 2020-1-20 21:46:10
-- @desc 鼠年嘉年华 - view

local ServerOpenDialog =  require("app.views.city.activity.server_open.view")
local SpringFestivalServerOpenDialog = class("SpringFestivalServerOpenDialog", ServerOpenDialog)

SpringFestivalServerOpenDialog.RESOURCE_FILENAME = "activity_server_open_spring_festival.json"
SpringFestivalServerOpenDialog.RESOURCE_BINDING = ServerOpenDialog.RESOURCE_BINDING
SpringFestivalServerOpenDialog.clientType = "springFestival"

return SpringFestivalServerOpenDialog