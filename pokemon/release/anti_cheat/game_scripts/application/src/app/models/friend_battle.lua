--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2016 TianJi Information Technology Inc.
--
-- FriendBattle 好友切磋
--

local GameBattleModel = require("app.models.battle")
local FriendBattle = class("FriendBattle", GameBattleModel)


FriendBattle.DefaultGateID = game.GATE_TYPE.friendFight


function FriendBattle:getPreDataForEnd(roleOut)
	return {}
end

return FriendBattle