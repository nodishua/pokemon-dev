-- 随机试炼塔

local RandomGate = class("RandomGate", battlePlay.Gate)
battlePlay.RandomGate = RandomGate

-- 战斗模式设置 手动
RandomGate.OperatorArgs = {
	isAuto 			= false,
	isFullManual 	= false,
	canHandle 		= true,
	canPause 		= true,
	canSpeedAni 	= true,
	canSkip 		= true,
}

-- 玩家单位用dbID 怪物则没有 因此用位置id
local function getForceKey(obj)
	return obj.dbID
end

function RandomGate:init(data)
	-- 先获取下场景配表中的星数条件
	self:initStarConditions()
	battlePlay.Gate.init(self, data)
end

function RandomGate:newWaveAddObjsStrategy()
	local buffs = self.data.gamemodel_data and self.data.gamemodel_data["buffs"] or {}
	local skills = self.data.gamemodel_data and self.data.gamemodel_data["skill_used"] or {}

	local roleOut = self.data.roleOut
	local skill_open = {}

	-- 读取数据 查看已有的可用的被动技能ID
	for _, buffId in pairs(buffs) do
		local count = skills[buffId] or 0
		local buffCfg = csv.random_tower.buffs[buffId]
		-- 是被动技能类型
		if buffCfg.buffType == 4 then
			-- 仍有足够的使用次数
			local hasTimes = buffCfg.effectTimes == 0 or count < buffCfg.effectTimes
			if hasTimes then
				skill_open[buffCfg.passiveSkill] = 1
			end
		end
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

function RandomGate:setCardStates()
	local gateStates = {{},{}}-- 里面记录了 开局时 所有的单位 但是生命/怒气 都是0

	local function setStates(idlerName, map, gateState)
		local states = self.data.gamemodel_data[idlerName] or {}
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

function RandomGate:getForceState(force)
	local map = self.scene:getHerosMap(force)
	local states = self.gateStates[force]

	if force == 1 and self.result == "win" then
		-- 针对活着的己方单位进行一些恢复
		local addHp = (tonumber(gCommonConfigCsv.randomTowerBattleHp) or 0) / 100
		local addMp = (tonumber(gCommonConfigCsv.randomTowerBattleMp) or 0)
		for id, obj in map:pairs() do
			if self:checkObjCanToServer(obj) then
				local addHpNum = obj:hpMax() * addHp
				obj:setHP(obj:hp() + addHpNum)
				obj:setMP1(obj:mp1() + addMp)
			end
		end
	end

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

function RandomGate:checkBattleEnd()
	if self:checkBothAllRealDead() then
		return true, "win"
	end
	return battlePlay.Gate.checkBattleEnd(self)
end

function RandomGate:postEndResultToServer(cb)
	local cardStates = self:getForceState(1)
	local enemyStates = self:getForceState(2)
	local endInfos = self:makeEndViewInfos({
		gateStar = true
	})

	gRootViewProxy:raw():postEndResultToServer("/game/random_tower/end", function(tb)
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
	end, self.scene.battleID, self.result, endInfos.gateStar, cardStates, enemyStates, self.curRound)
end
















