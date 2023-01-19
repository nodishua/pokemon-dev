--
--  战斗失败界面 -- 无尽塔界面
--

local BattleEndFailView = require "battle.app_views.battle.battle_end.pve_fail"
local BattleEndlessFailView = class("BattleEndlessFailView", BattleEndFailView)

BattleEndlessFailView.RESOURCE_FILENAME = "battle_end_pve_fail.json"
BattleEndlessFailView.RESOURCE_BINDING = {
	["eggBtn.text"] = BTN_TEXT_OUTLINE,
	["promoteBtn.text"] = BTN_TEXT_OUTLINE,
	["strengthBtn.text"] = BTN_TEXT_OUTLINE,
	["backBtn.text"] = BTN_TEXT_GLOW,
	["againBtn.text"] = BTN_TEXT_GLOW,
	["dungeonsBtn.text"] = BTN_TEXT_GLOW,
	["reStartBtn.text"] = BTN_TEXT_GLOW,
	["backCityBtn.text"] = BTN_TEXT_GLOW,
	["eggBtn"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onEggBtnClick")}
		},
	},
	["promoteBtn"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onPromoteBtnClick")}
		},
	},
	["strengthBtn"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onStrengthBtnClick")}
		},
	},
	["backBtn"] = {
		varname = "backBtn",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onBackBtnClick")}
		},
	},
	["againBtn"] = {
		varname = "againBtn",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onAgainBtnClick")}
		},
	},
	["dungeonsBtn"] = {
		varname = "dungeonsBtn",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onDungeonsBtnClick")}
		},
	},
	["reStartBtn"] = {
		varname = "reStartBtn",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onReStartBtnClick")}
		},
	},
	["backCityBtn"] = {
		varname = "backCityBtn",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onBackCityBtnClick")}
		},
	},
	["bkg"] = {
		varname = "bkg",
		binds = {
			event = "click",
			method = bindHelper.self("onBgClick"),
		},
	},
	["exitText"] = "exitText",
}

-- 重开
-- 与 BattlePauseView:onRestartBtnClick 同理
function BattleEndlessFailView:playRecord()
	local entrance = self.battleView.entrance
	entrance:restart()
end


return BattleEndlessFailView

