-- 狩猎地带

local HuntingGate = class("HuntingGate", battlePlay.Gate)
battlePlay.HuntingGate = HuntingGate

-- 战斗模式设置 手动
HuntingGate.OperatorArgs = {
	isAuto 			= false,
	isFullManual 	= false,
	canHandle 		= true,
	canPause 		= true,
	canSpeedAni 	= true,
	canSkip 		= true,
}


HuntingGate.SpecEndRuleCheck = {
	battle.EndSpecialCheck.EnemyOnlySummonOrAllDead,
}

-- 玩家单位用dbID 怪物则没有 因此用位置id
local function getForceKey(obj)
	return obj.dbID
end

function HuntingGate:newWaveAddObjsStrategy()
    local routeInfo = self.data.gamemodel_data and self.data.gamemodel_data["route_info"] or {}
	local buffs = routeInfo.buffs
    local roleOut = self.data.roleOut
	local skill_open = {}

	-- -- 读取数据 查看已有的可用的被动技能ID
	for _, buffId in pairs(buffs) do
		local buffCfg = csv.cross.hunting.buffs[buffId]
		skill_open[buffCfg.skillID] = 1
	end

	-- 将可用的skill实装给所有的己方单位
	for i = 1, 6 do
		local role = roleOut[i]
		if role then
			role.passive_skills = role.passive_skills or {}
			for skillId, skillLevel in pairs(skill_open) do
				role.passive_skills[skillId] = skillLevel
			end
		end
	end

	self:addCardRoles(1, nil, roleOut)
	self:addCardRoles(2)
	self:doObjsAttrsCorrect(true, true)		-- 属性修正部分
	battlePlay.Gate.newWaveAddObjsStrategy(self)

	-- 单位初始状态的设置
	self:setCardStates()
end

function HuntingGate:setCardStates()
	local gateStates = {{},{}}-- 里面记录了 开局时 所有的单位 但是生命/怒气 都是0
    local routeInfo = self.data.gamemodel_data and self.data.gamemodel_data["route_info"] or {}

	local function setStates(idlerName, map, gateState)
		local states = routeInfo[idlerName] or {}
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

	setStates("enemy_states", self.scene:getHerosMap(2), gateStates[2])
	setStates("card_states", self.scene:getHerosMap(1), gateStates[1])

	self.gateStates = gateStates		-- 保存这个表 战斗结束时使用
end

function HuntingGate:getForceState(force)
	local map = self.scene:getHerosMap(force)
	local states = self.gateStates[force]

	-- 仍然存活的角色 其属性状态会覆盖掉原本的 {0,0}
	for id, obj in map:pairs() do
		if self:checkObjCanToServer(obj) then
			states[getForceKey(obj)] = {
				obj:hp() / obj:hpMax(),
				obj:mp1() / obj:mp1Max(),
			}
		end
	end

	-- 己方满回合，记为战斗失败，己方阵容全部都不可用
	-- if force == 1 and self.isRoundLimitFail then
	-- 	for id, obj in map:pairs() do
	-- 		states[getForceKey(obj)] = {
	-- 			0 / obj:hpMax(),
	-- 			0 / obj:mp1Max(),
	-- 		}
	-- 	end
	-- end

	return states
end

function HuntingGate:needExtraRound()
	if self.curRound > self.roundLimit then
		return false
	end
	for _, obj in self.scene:ipairsHeros() do
		if obj:isFakeDeath() then return true end
	end
	return false
end

function HuntingGate:checkBattleEnd()
	if self:checkBothAllRealDead() then
		return true, "win"
	end
	if self:needExtraRound() then
		return false
	end
	return battlePlay.Gate.checkBattleEnd(self)
end

function HuntingGate:postEndResultToServer(cb)
	local cardStates = self:getForceState(1)
	local enemyStates = self:getForceState(2)
	local endInfos = self:makeEndViewInfos({
		gateStar = true
	})

    local tb = self.scene.extraRecord:getEvent(battle.ExRecordEvent.campDamage)
	local totalDamage = tb and tb[1]

	gRootViewProxy:raw():postEndResultToServer("/game/hunting/battle/end", function(tb)
		local view = tb.view or {}
		if next(view) then
			endInfos.cardStates = cardStates
			endInfos.enemyStates = enemyStates
			cb(endInfos, view)
		else
			-- 异常情况 返回city
			-- todo 这里要改为使用新的postEndResultToServer接口来使用onErrClose
			gGameUI:cleanStash()
			gGameUI:switchUI("city.view")
			gGameUI:showTip(gLanguageCsv.randomTimeOver)
		end
	end, self.scene.battleID, self.result, cardStates, enemyStates, totalDamage)
end