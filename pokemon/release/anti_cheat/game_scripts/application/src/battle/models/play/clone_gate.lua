

local CloneGate = class("CloneGate", battlePlay.Gate)
battlePlay.CloneGate = CloneGate

-- 战斗模式设置 全自动
CloneGate.OperatorArgs = {
	isAuto 			= false,
	isFullManual 	= false,
	canHandle 		= true,
	canPause 		= true,
	canSpeedAni 	= true,
	canSkip 		= true,
}

function CloneGate:init(data)
	local canJump = dataEasy.getPrivilegeVal(game.PRIVILEGE_TYPE.BattleSkip, game.GATE_TYPE.clone)
	if canJump then
		self.OperatorArgs.canSkip = true
	end
	battlePlay.Gate.init(self, data)
end

function CloneGate:newWaveAddObjsStrategy()
	self:addCardRoles(1)
	self:addCardRoles(2)
	self:doObjsAttrsCorrect(true, true)
	battlePlay.Gate.newWaveAddObjsStrategy(self)
end

-- 有排名、排名变化(通过战前保存旧的排名来计算)、翻牌奖励
function CloneGate:postEndResultToServer(cb)
	local endInfos = self:makeEndViewInfos()
	local battleView = gRootViewProxy:raw()

	local cbFunc = function(tb)
		if not battleView.modes.fromRecordFile then
			endInfos.freeBox = tb.view.freeBox
		end
		cb(endInfos, tb)
	end

	battleView:postEndResultToServer("/game/clone/battle/end", {
		cb = cbFunc,
		onErrClose = function(tb)
			if tb and tb.err ~= "cloneRoomOutDate" and tb.err ~= "ErrCloneRoomNotExists" then return end
			gGameUI:switchUI("city.view")
			gGameUI:goBackInStackUI("city.adventure.clone_battle.base")
		end,
	}, endInfos.result) -- 敌方排名、胜负
end

function CloneGate:getMonsterCsv(sceneId,waveId)
	sceneId = sceneId or self.scene.sceneID
	return csvClone(gMonsterCsv[sceneId][1])
end


-- 战报
local CloneGateRecord = class("CloneGateRecord", CloneGate)
battlePlay.CloneGateRecord = CloneGateRecord

-- 战斗模式设置 手动
CloneGateRecord.OperatorArgs = {
	isAuto 			= true,
	isFullManual 	= false,
	canHandle 		= false,
	canPause 		= true,
	canSpeedAni 	= true,
	canSkip 		= true,
}

function CloneGateRecord:init(data)
	battlePlay.Gate.init(self, data)
end
