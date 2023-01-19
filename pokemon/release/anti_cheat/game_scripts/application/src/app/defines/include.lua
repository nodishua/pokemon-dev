--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2017 TianJi Information Technology Inc.
--

-- assets will be destroy when game inited ok
local assets = cc.AssetsManagerEx:getInstance()
globals.PATCH_MIN_VERSION = assets:getPatchMinVersion()
globals.PATCH_VERSION = assets:getPatchVersion()
printInfo('PATCH_MIN_VERSION %d', PATCH_MIN_VERSION)
printInfo('PATCH_VERSION %d', PATCH_VERSION)

require "app.defines.dev_defines"
require "app.defines.app_defines"
require "app.defines.game_defines"
require "app.defines.ui_defines"
require "battle.battle_defines"

require "app.defines.config_defines"
