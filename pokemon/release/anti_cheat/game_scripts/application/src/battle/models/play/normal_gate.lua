

local NormalGate = class("NormalGate", battlePlay.Gate)
battlePlay.NormalGate = NormalGate

-- 战斗模式设置 手动
NormalGate.OperatorArgs = {
	isAuto 			= false,
	isFullManual 	= false,
	canHandle 		= true,
	canPause 		= true,
	canSpeedAni 	= true,
	canSkip 		= false,
}

function NormalGate:init(data)
	-- 先获取下场景配表中的星数条件
	self:initStarConditions()

	battlePlay.Gate.init(self, data)
end

-- 敌方使用monster构造
function NormalGate:createObjectModel(force, seat)
	local obj
	if force == 1 then
		obj = ObjectModel.new(self.scene, seat)
	else
		obj = MonsterModel.new(self.scene, seat)
	end
	return obj
end

function NormalGate:newWaveAddObjsStrategy()
	-- 普通pve副本, 第一波加双方, 后续只加敌方
	if self.curWave == 1 then
		self:addCardRoles(1)
		self:addCardRoles(2, 1, self:getEnemyRoleOutT(1))
		self:doObjsAttrsCorrect(true, true)		-- 属性修正部分
	else
		self:addCardRoles(2, self.curWave, self:getEnemyRoleOutT(self.curWave))
		self:doObjsAttrsCorrect(false, true)
	end
	battlePlay.Gate.newWaveAddObjsStrategy(self)
end

function NormalGate:postEndResultToServer(cb)
	local oldCapture = gGameModel.capture:read("limit_sprites")
	local endInfo = self:makeEndViewInfos({
		gateStar = true
	})
	gRootViewProxy:raw():postEndResultToServer("/game/end_gate", function(tb)
		cb(endInfo, tb, oldCapture)
	end, self.scene.battleID, self.scene.sceneID, endInfo.result, endInfo.gateStar)
end