

local ArenaGate = class("ArenaGate", battlePlay.Gate)
battlePlay.ArenaGate = ArenaGate

-- 战斗模式设置 全自动
ArenaGate.OperatorArgs = {
	isAuto 			= true,
	isFullManual 	= false,
	canHandle 		= false,
	canPause 		= false,
	canSpeedAni 	= true,
	canSkip 		= true,
}

function ArenaGate:init(data)
	battlePlay.Gate.init(self, data)

	self:playStartAni()
end

-- 加个宝可梦开场和进场的动画
function ArenaGate:playStartAni()
	gRootViewProxy:notify('showVsPvpView',1)
end

function ArenaGate:newWaveAddObjsStrategy()
	self:addCardRoles(1)
	self:addCardRoles(2)
	self:doObjsAttrsCorrect(true, true)
	battlePlay.Gate.newWaveAddObjsStrategy(self)
end

-- 没有星级 有胜负
function ArenaGate:makeEndViewInfos()
	local _, mvpPosId = self:whoHighestDamageFromStats(1)
	return {
		result = self.result,
		mvpPosId = mvpPosId,
	}
end

-- 有排名、排名变化(通过战前保存旧的排名来计算)、翻牌奖励
function ArenaGate:postEndResultToServer(cb)
	local endInfos = self:makeEndViewInfos()
	local data = self.scene.data
	gRootViewProxy:raw():postEndResultToServer("/game/pw/battle/end", function(tb)
		cb(endInfos, tb)
	end, data.preData.rightRank, endInfos.result) -- 敌方排名、胜负
end

-- 战报
local ArenaGateRecord = class("ArenaGateRecord", ArenaGate)
battlePlay.ArenaGateRecord = ArenaGateRecord

-- 战斗模式设置 手动
ArenaGateRecord.OperatorArgs = {
	isAuto 			= true,
	isFullManual 	= false,
	canHandle 		= false,
	canPause 		= true,
	canSpeedAni 	= true,
	canSkip 		= true,
	canSkipInstant	= true
}

function ArenaGateRecord:init(data)
	battlePlay.Gate.init(self, data)
end
