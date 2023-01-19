local config = require("app.views.topui.config")
local TopuiBase = require("app.views.topui.base")
local TopuiHuntingAreaView = class("TopuiHuntingAreaView", TopuiBase)

TopuiHuntingAreaView.RESOURCE_FILENAME = "topui_hunting_area.json"
TopuiHuntingAreaView.RESOURCE_BINDING = maptools.extend({
	config.title,
	config.gold,
	config.diamond,
	config.huntingArea,
})

function TopuiHuntingAreaView:onCreate(params)
	TopuiBase.onCreate(self, {"title"}, params)
end

function TopuiHuntingAreaView:onHuntingAreaClick()
	local isUnlock = dataEasy.isUnlock(gUnlockCsv.hunting)
	if not isUnlock then
		gGameUI:showTip(dataEasy.getUnlockTip(gUnlockCsv.hunting))
		return
	end

	local uiRoot,rootViewName = gGameUI:getTopStackUI()

	if rootViewName ~= "city.adventure.hunting.view" and rootViewName ~= "city.adventure.hunting.route"  then
		if not gGameUI:goBackInStackUI("city.adventure.hunting.view") then
			gGameApp:requestServer("/game/hunting/main", function (tb)
				gGameUI:stackUI("city.adventure.hunting.view", nil, {full = true})
			end)
		end
	end
end

return TopuiHuntingAreaView