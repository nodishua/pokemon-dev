local ActivitySevenDayLoginDialog = require "app.views.city.activity.recharge_feedback.seven_day_login"

local LoginGiftDialog = class("LoginGiftDialog", ActivitySevenDayLoginDialog)

LoginGiftDialog.RESOURCE_FILENAME = "activity_seven_day_login.json"
LoginGiftDialog.RESOURCE_BINDING = ActivitySevenDayLoginDialog.RESOURCE_BINDING

return LoginGiftDialog