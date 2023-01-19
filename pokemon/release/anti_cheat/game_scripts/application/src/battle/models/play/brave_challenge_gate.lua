-- 勇者挑战

local BraveChallengeGate = class("BraveChallengeGate", battlePlay.Gate)
battlePlay.BraveChallengeGate = BraveChallengeGate

-- 战斗模式设置 手动
BraveChallengeGate.OperatorArgs = {
	isAuto 			= false,
	isFullManual 	= false,
	canHandle 		= true,
	canPause 		= true,
	canSpeedAni 	= true,
	canSkip 		= true,
}

BraveChallengeGate.CommonArgs = {
	AntiMode = battle.GateAntiMode.Operate
}

BraveChallengeGate.SpecEndRuleCheck = {
	battle.EndSpecialCheck.DirectWin,
}

-- 玩家单位用dbID 怪物则没有 因此用位置id
local function getForceKey(obj)
	return obj.dbID
end

function BraveChallengeGate:init(data)
	-- 先获取下场景配表中的星数条件

	self:initStarConditions()
	battlePlay.Gate.init(self, data)
end

-- 星级条件部分
function BraveChallengeGate:makeEndViewInfos(data)
	-- 星级
	local endInfo = battlePlay.Gate.makeEndViewInfos(self, data)
	endInfo.round = self.curRound
	return endInfo
end

-- function BraveChallengeGate:onceBattle(targetId, skillId)
-- 	-- 手动才有targetId
-- 	-- 记录原始操作数据
-- 	if skillId then
-- 		table.set(self.actionSend, self.curRound, self.curBattleRound, {
-- 			self.curHero.seat,	-- 当前单位
-- 			targetId,			-- 选中目标
-- 			skillId,			-- 选中技能id, 0 表示自动
-- 		})
-- 	end
-- 	battlePlay.Gate.onceBattle(self, targetId, skillId)
-- end

function BraveChallengeGate:sendParams()
	local cardStates = self:getForceState(1)
	local enemyStates = self:getForceState(2)

	local tb = self.scene.extraRecord:getEvent(battle.ExRecordEvent.campDamage)
	local totalDamage = tb and tb[1]

	return self.scene.battleID, self.data.floorID, self.result, cardStates, enemyStates, self.curRound, totalDamage, battlePlay.Gate.sendActionParams(self)
end

function BraveChallengeGate:newWaveAddObjsStrategy()
	local roleOut = self.data.roleOut

	self:addCardRoles(1, nil, roleOut)
	self:addCardRoles(2)
	self:doObjsAttrsCorrect(true, true)  -- 属性修正部分
	battlePlay.Gate.newWaveAddObjsStrategy(self)

	-- 单位初始状态的设置
	self:setCardStates()
end

function BraveChallengeGate:setCardStates()
	local gateStates = {{},{}} --记录开局时所有的单位生命/怒气 初始为0

	local gameInfo = self.data.gamemodel_data or {}
	local function setStates(idlerName, map, gateState)
		local states = gameInfo[idlerName] or {}
		for id, obj in map:pairs() do
			if self:checkObjCanToServer(obj) then
				local idx = getForceKey(obj)
				local state = states[tonumber(idx)] or states[tostring(idx)]
				if state then
					local maxHp, maxMp = obj:hpMax(), obj:mp1Max()
					obj:setHP(maxHp * state[1])
					obj:setMP1(maxMp * state[2])
				end
				gateState[idx] = {0,0}
			end
		end
	end

	setStates("monsters", self.scene:getHerosMap(2), gateStates[2])
	setStates("cards", self.scene:getHerosMap(1), gateStates[1])

	-- 保存这个表 战斗结束时使用
	self.gateStates = gateStates
end

function BraveChallengeGate:getForceState(force)
	local map = self.scene:getHerosMap(force)
	local states = self.gateStates[force]

	-- 存活的角色 其属性状态会覆盖掉原本的 {0,0}
	for id, obj in map:pairs() do
		if self:checkObjCanToServer(obj) then
			states[getForceKey(obj)] = {
				obj:hp() / obj:hpMax(),
				obj:mp1() / obj:mp1Max(),
			}
		end
	end

	return states
end

function BraveChallengeGate:needExtraRound()
	if self.curRound > self.roundLimit then
		return false
	end
	for _, obj in self.scene:ipairsHeros() do
		if obj:isFakeDeath() then return true end
	end
	return false
end

function BraveChallengeGate:checkBattleEnd()
	if self:checkBothAllRealDead() then
		return true, "win"
	end
	if self:needExtraRound() then
		return false
	end
	return battlePlay.Gate.checkBattleEnd(self)
end

function BraveChallengeGate:postEndResultToServer(cb)
	local endInfos = self:makeEndViewInfos({
		gateStar = true
	})

	gRootViewProxy:raw():postEndResultToServer(self.data.battleEndUrl, function(tb)
		cb(endInfos, tb)
	end, self:sendParams())
end

-- 战报
local BraveChallengeGateRecord = class("BraveChallengeGateRecord", BraveChallengeGate)
battlePlay.BraveChallengeGateRecord = BraveChallengeGateRecord

-- 战斗模式设置 自动
BraveChallengeGateRecord.OperatorArgs = {
	isAuto 			= true,
	isFullManual 	= false,
	canHandle 		= false,
	canPause 		= true,
	canSpeedAni 	= true,
	canSkip 		= true,
	canSkipInstant	= true
}