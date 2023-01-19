

local CrossArenaGate = class("CrossArenaGate", battlePlay.ArenaGate)
battlePlay.CrossArenaGate = CrossArenaGate

-- 战斗模式设置 全自动
CrossArenaGate.OperatorArgs = {
	isAuto 			= true,
	isFullManual 	= false,
	canHandle 		= false,
	canPause 		= false,
	canSpeedAni 	= true,
	canSkip 		= true,
}

CrossArenaGate.SpecEndRuleCheck ={
	battle.EndSpecialCheck.AllHpRatioCheck,
	battle.EndSpecialCheck.FightPoint,
	battle.EndSpecialCheck.CumulativeSpeedSum,
}

function CrossArenaGate:init(data)
	battlePlay.Gate.init(self, data)


	-- 每轮次的结果, 1友方阵容输, 2敌方阵容输, 3平局
	self.waveResultList = {}
	self.endAnimation = {res = "xianshipvp/jinjichang.skel",aniName = ""}
	self.craftBuffAddTimes = {}
	self:playStartAni()
end

-- 加个宝可梦开场和进场的动画
function CrossArenaGate:playStartAni()
	--gRootViewProxy:notify('showVsPvpView', 1)
end

function CrossArenaGate:newWaveAddObjsStrategy()
	-- 第一波加双方 后续看死亡情况加
	if self.curWave == 1 then
		self:addCardRoles(1, nil, self.data.roleOut[1][1], self.data.roleOut2[1][1], true)
		self:addCardRoles(2, nil, self.data.roleOut[2][1], self.data.roleOut2[2][1], true)
		self:doObjsAttrsCorrect(true, true)
	else
		if self.waveResultList[self.curWave - 1] == 3 then
			self:addCardRoles(1, nil, self.data.roleOut[1][2], self.data.roleOut2[1][2], false)
			self:addCardRoles(2, nil, self.data.roleOut[2][2], self.data.roleOut2[2][2], false)
			self:doObjsAttrsCorrect(true, true)
		else
			local chosseForce = self.waveResultList[self.curWave - 1]
			self:addCardRoles(chosseForce, nil, self.data.roleOut[chosseForce][2],self.data.roleOut2[chosseForce][2], false)
			if chosseForce == 1 then
				self:doObjsAttrsCorrect(true, false)
			else
				self:doObjsAttrsCorrect(false, true)
			end
		end
	end
	battlePlay.Gate.newWaveAddObjsStrategy(self)
	-- 防止左右同时死亡
	self.mayBeMeWin = (self.myFightPointSum > self.enemyFightPointSum) and 'win' or 'fail'
	if self.myFightPointSum == self.enemyFightPointSum then
		self.mayBeMeWin = (self.mySpeedSum > self.enemySpeedSum) and 'win' or 'fail'
	end
end

function CrossArenaGate:addCardRoles(force, waveId, roleOutT, roleOutT2, onlyDelDead)
	battlePlay.Gate.addCardRoles(self, force, waveId, roleOutT, roleOutT2, onlyDelDead)

	if force == 1 then
		self.myHpSum, self.myHpMaxSum, self.myFightPointSum, self.mySpeedSum = self:getSumInfo(force)
		self.myDeadHpMaxSum = 0
	else
		self.enemyHpSum, self.enemyHpMaxSum, self.enemyFightPointSum, self.enemySpeedSum = self:getSumInfo(force)
		self.enemyDeadHpMaxSum = 0
	end
end

-- 判断当前战斗是否结束 true 结束 false 胜利
function CrossArenaGate:checkBattleEnd()
	-- 第二波
	if self.curWave == 2 then
		if self:checkBothAllRealDead() then
			local result
			if self.waveResultList[1] == 3 then result = self.mayBeMeWin
			elseif self.waveResultList[1] == 1 then  result = 'fail'
			elseif self.waveResultList[1] == 2 then  result = 'win' end
			return true, result
		end
		if self.waveResultList[1] ~= 2 and self:checkForceAllRealDead(1) then
			return true,'fail'
		end
		if self.waveResultList[1] ~= 1 and self:checkForceAllRealDead(2) then
			return true,'win'
		end
		if self.curRound >= self.roundLimit and self:checkRoundEnd() and not self:needExtraRound() then
			local _, result = battlePlay.Gate.checkBattleEnd(self)
			if result == 'win' and self.waveResultList[1] ~= 1 then return true,'win'
			elseif result == 'fail' and self.waveResultList[1] ~= 2 then return true,'fail' end
		end
	end
	-- 第三波
	if self.curWave == 3 then
		-- 0.全死的情况
		if self:checkBothAllRealDead() then
			return true, self.mayBeMeWin
		end
		-- 1.先判断己方死光了没
		if self:checkForceAllRealDead(1) then
			return true,'fail'
		end
		-- 2.判断对方死光了没
		if self:checkForceAllRealDead(2) then
			return true,'win'
		end
		-- 3.然后判断回合数是否超了
		if self.curRound >= self.roundLimit and self:checkRoundEnd() and not self:needExtraRound() then
			return battlePlay.Gate.checkBattleEnd(self)
		end
	end
	return false
end

function CrossArenaGate:getSumInfo(force)
	local HpSum = 0
	local HpMaxSum = 0
	local FightPointSum = 0
	local SpeedSum = 0
	for k = ((force - 1) * 6 + 1), 6 * force do
		local obj = self.scene:getObjectBySeat(k)
		if obj and self:checkObjCanToServer(obj) then
			HpSum = HpSum + obj:hp()
			HpMaxSum = HpMaxSum + obj:hpMax()
			FightPointSum = FightPointSum + obj.fightPoint
			SpeedSum = SpeedSum + obj:speed()
		end
	end
	return HpSum, HpMaxSum, FightPointSum, SpeedSum
end

function CrossArenaGate:checkWaveEnd()
	local me = self:checkForceAllRealDead(1)
	local enemy = self:checkForceAllRealDead(2)
	if me and enemy then return true, 3
	elseif me then return true, 1
	elseif enemy then return true, 2 end
	if self.curRound >= self.roundLimit and self:checkRoundEnd() and not self:needExtraRound() then
		local _,result = self:specialEndCheck()
		return true,result
	end
	return false
end

function CrossArenaGate:onWaveEndSupply()
	if self.waveResultList == nil then
		self.waveResultList = {}
		self.endAnimation = {res = "xianshipvp/jinjichang.skel",aniName = ""}
	end
	local _,result = self:checkWaveEnd()
	local objMap
	if result == 'win' then
		result = 2
		objMap = self.scene:getHerosMap(2)
	elseif result == 'fail' then
		result = 1
		objMap = self.scene:getHerosMap(1)
	end
	-- 删除上一波废弃单位
	if objMap then
		for _,obj in objMap:order_pairs() do
			obj:setDead(nil,nil, {force = true, noTrigger = true})
		end
	end

	table.insert(self.waveResultList, result)
end

function CrossArenaGate:onBattleEndSupply()
	local _,result = self:checkBattleEnd()
	if result == 'win' then self.endAnimation.aniName = "effect_l"
	elseif result == 'fail' then self.endAnimation.aniName = "effect_r" end
end

function CrossArenaGate:needExtraRound()
	if self.curRound > self.roundLimit  then
		return false
	end
	for _, obj in self.scene:ipairsHeros() do
		if obj:isFakeDeath() then return true end
	end
	return false
end

-- 数据记录相关: 记录项、值s
function CrossArenaGate:recordDamageStats()
	for _, obj in self.scene:ipairsHeros() do
		if self:checkObjCanCalcDamage(obj) then
			local totalDamage = 0
			for k,v in pairs(obj.totalDamage) do
				totalDamage = totalDamage + v:get(battle.ValueType.normal)
			end
			local force = obj.force
			local id = obj.id
			local group = 1
			if self.curWave == 1 then group = 1
			elseif self.curWave == 2 then
				if force == 1 and self.waveResultList[1] ~= 2 then group = 2
				elseif force == 2 and self.waveResultList[1] ~= 1 then group = 2
				else group = 1 end
			elseif self.curWave == 3 then group = 2 end
			local data ={
				posId = obj.seat,
				damageVal = totalDamage
			}
			-- 实际存储为 [force][group][id] = data
			self.scene.extraRecord:addExRecord(battle.ExRecordEvent.unitsDamage, data, force, group, id)
		end
	end
end

--记录总伤害 原逻辑也没有统计总阵营伤害
function CrossArenaGate:recordCampDamageStats()
	return
end

function CrossArenaGate:getHpRation()
	local myHpRatio = 0
	local myHpSum, myAliveHpMaxSum = self:getSumInfo(1)
	myHpRatio = myHpSum / (myAliveHpMaxSum + self.myDeadHpMaxSum)
	local enemyHpRatio = 0
	local enemyHpSum, enemyAliveHpMaxSum = self:getSumInfo(2)
	enemyHpRatio = enemyHpSum / (enemyAliveHpMaxSum + self.enemyDeadHpMaxSum)
	return myHpRatio, enemyHpRatio
end

-- 没有星级 有胜负
function CrossArenaGate:makeEndViewInfos()
	local myHpRatio, enemyHpRatio = self:getHpRation()
	local totalRounds  = self:getTotalRounds()
	local isTopBattle = false
	if totalRounds > 4 and ((self.result == "win" and myHpRatio < 0.5 )
		or (self.result == "fail" and enemyHpRatio < 0.5)) then
		isTopBattle = true
	end
	local mvpCardIn, mvpPosId = self:whoHighestDamageFromStats(1, 2)
	return {
		result = self.result,
		mvpCardIn = mvpCardIn,
		mvpPosId = mvpPosId,
		isTopBattle = isTopBattle,
	}
end

-- 有排名、排名变化(通过战前保存旧的排名来计算)、翻牌奖励
function CrossArenaGate:postEndResultToServer(cb)
	local endInfos = self:makeEndViewInfos()
	local data = self.scene.data
	gRootViewProxy:raw():postEndResultToServer("/game/cross/arena/battle/end", function(tb)
		cb(endInfos, tb)
	end, data.preData.rightRank, endInfos.result, endInfos.isTopBattle) -- 敌方排名、胜负
end

-- 跨服竞技场 策划要求不显示波数
function CrossArenaGate:onNewWavePlayAni()
	self.curWave = self.curWave + 1		-- 波数增加
	self.curRound = 0					-- 回合数重置
	self.totalRoundBattleTurn = 0
	-- wave的波数设置
	--gRootViewProxy:notify('setWaveNumber', self.curWave, self.waveCount)
	--gRootViewProxy:notify('playWaveAni', self.curWave, self.waveCount)
	local preLoser
	if self.curWave == 1 then preLoser = 0
	else preLoser = self.waveResultList[self.curWave - 1] end
	gRootViewProxy:notify('setTeamNumber', self.curWave, preLoser)
	battleEasy.queueEffect('delay', {lifetime=300})
	self.scene:waitNewWaveAniDone()
end

function CrossArenaGate:doObjsAttrsCorrect(isLeftC, isRightC)
	battlePlay.Gate.doObjsAttrsCorrect(self, isLeftC, isRightC)
	local cfg = {}
	local csvData = csv.cross.arena.cross_arena_battle_fix
	for k, v in ipairs(csvData) do
		cfg[v["attrType"]..'C'] = v["attrFix"]
	end
	if isLeftC then
		for i = 1, 6 do
			local obj = self.scene:getObjectBySeat(i)
			if obj then obj:objAttrsCorrect(cfg) end
		end
	end
	if isRightC then
		for i = 7, 12 do
			local obj = self.scene:getObjectBySeat(i)
			if obj then obj:objAttrsCorrect(cfg) end
		end
	end
end

-- 战报
local CrossArenaGateRecord = class("CrossArenaGateRecord", CrossArenaGate)
battlePlay.CrossArenaGateRecord = CrossArenaGateRecord

-- 战斗模式设置 手动
CrossArenaGateRecord.OperatorArgs = {
	isAuto 			= true,
	isFullManual 	= false,
	canHandle 		= false,
	canPause 		= true,
	canSpeedAni 	= true,
	canSkip 		= true,
	canSkipInstant	= true
}

function CrossArenaGateRecord:init(data)

	self.craftBuffAddTimes = {}

	battlePlay.Gate.init(self, data)
end
