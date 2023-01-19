local ActivitySevenDayLoginDialog = require "app.views.city.activity.recharge_feedback.seven_day_login"

local SpringFestivalDialog = class("SpringFestivalDialog", ActivitySevenDayLoginDialog)

SpringFestivalDialog.RESOURCE_FILENAME = "activity_spring_festival.json"
SpringFestivalDialog.RESOURCE_BINDING = ActivitySevenDayLoginDialog.RESOURCE_BINDING
SpringFestivalDialog.springFestival = true

return SpringFestivalDialog