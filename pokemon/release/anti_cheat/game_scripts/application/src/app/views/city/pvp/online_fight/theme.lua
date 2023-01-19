-- @date 2020-8-13
-- @desc 实时匹配主题更新

local OnlineFightThemeView = class("OnlineFightThemeView", cc.load("mvc").ViewBase)

OnlineFightThemeView.RESOURCE_FILENAME = "online_fight_theme.json"
OnlineFightThemeView.RESOURCE_BINDING = {
	["title"] = {
		binds = {
			event = "effect",
			data = {outline = {color = cc.c4b(50, 18, 6, 255)}},
		},
	},
	["desc"] = {
		varname = "desc",
		binds = {
			event = "effect",
			data = {outline = {color = cc.c4b(50, 18, 6, 255)}},
		},
	},
}

function OnlineFightThemeView:onCreate()
	local themeId = gGameModel.cross_online_fight:read("theme_id")
	local themeCfg = csv.cross.online_fight.theme[themeId]
	self.desc:text(gLanguageCsv.onlineFightTheme .. themeCfg.desc)
end

return OnlineFightThemeView