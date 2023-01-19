--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2016 TianJi Information Technology Inc.
--
-- CloneBattle 王者战斗, 战报回放
--

local GameBattleModel = require("app.models.battle")
local CloneBattle = class("CloneBattle", GameBattleModel)

CloneBattle.DefaultGateID = game.GATE_TYPE.clone
CloneBattle.OmitEmpty = false

return CloneBattle
