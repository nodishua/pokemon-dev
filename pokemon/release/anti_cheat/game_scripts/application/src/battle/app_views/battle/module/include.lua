--
-- module all
--

local battleModule = {}
globals.battleModule = battleModule

require "battle.app_views.battle.module.base"
require "battle.app_views.battle.module.notify"

battleModule.mods = {
	require("battle.app_views.battle.module.objmanager"),

	require("battle.app_views.battle.module.mainarea"),
	require("battle.app_views.battle.module.skillinfo"),
	require("battle.app_views.battle.module.speedrank"),
	require("battle.app_views.battle.module.sys"),
	require("battle.app_views.battle.module.vsinfo"),
	require("battle.app_views.battle.module.weather"),
	require("battle.app_views.battle.module.stage"),
	require("battle.app_views.battle.module.bufficon"),
	require("battle.app_views.battle.module.headnum"),
	require("battle.app_views.battle.module.frame"),
	require("battle.app_views.battle.module.linkeffect"),

	require("battle.app_views.battle.module.debugarea"),
}

battleModule.dailyActivityMods = {
	require("battle.app_views.battle.module.spec.daily_activity")
}

battleModule.craftMods = {
	require("battle.app_views.battle.module.spec.craft")
}

battleModule.bossMods = {
	require("battle.app_views.battle.module.spec.world_boss")
}

battleModule.onlineFightMods = {
	require("battle.app_views.battle.module.spec.online_fight")
}

battleModule.gymMods = {
	require("battle.app_views.battle.module.spec.gym")
}

battleModule.crossMineMods = {
	require("battle.app_views.battle.module.spec.cross_mine")
}

return battleModule