

local CrossMineGate = class("CrossMineGate", battlePlay.Gate)
battlePlay.CrossMineGate = CrossMineGate

-- 战斗模式设置 全自动
CrossMineGate.OperatorArgs = {
	isAuto 			= true,
	isFullManual 	= false,
	canHandle 		= false,
	canPause 		= false,
	canSpeedAni 	= true,
	canSkip 		= true,
}

function CrossMineGate:init(data)
	battlePlay.Gate.init(self, data)
	self.waveResultList = {}
	self.myDeadHpMaxSum = 0
	self.enemyDeadHpMaxSum = 0
	self.endAnimation = {res = "xianshipvp/jinjichang.skel",aniName = ""}
	gRootViewProxy:proxy():addSpecModule(battleModule.crossMineMods)
end

function CrossMineGate:newWaveAddObjsStrategy()
	self:addCardRoles(1, nil, self.data.roleOut[1][self.curWave], self.data.roleOut2[1][self.curWave],false)
	self:addCardRoles(2, nil, self.data.roleOut[2][self.curWave], self.data.roleOut2[2][self.curWave],false)
	self.myDeadHpMaxSum = 0
	self.enemyDeadHpMaxSum = 0
	self:doObjsAttrsCorrect(true, true)
	battlePlay.Gate.newWaveAddObjsStrategy(self)

	if self.curWave == 1 then
		battleEasy.deferNotifyCantClean(nil, "initPvp")
	end
end

function CrossMineGate:onNewWavePlayAni()
	self.isWaveEnd = false
	self.curWaveResult = nil
	self.curWave = self.curWave + 1		-- 波数增加
	self.curRound = 0					-- 回合数重置
	self.totalRoundBattleTurn = 0
	gRootViewProxy:notify('setTeamNumber', self.curWave, 3)
	battleEasy.queueEffect('delay', {lifetime=300})

	local count = 0
	for _, v in ipairs(self.waveResultList) do
		count = battleEasy.ifElse(v == 1, count + 1, count)
	end
	local listLength = #self.waveResultList
	battleEasy.deferNotifyCantClean(nil, "changeWave", count, listLength, self.waveResultList[listLength])
	gRootViewProxy:proxy():forceClearBuffEffects()
	self.scene:waitNewWaveAniDone()
end

function CrossMineGate:checkWaveEnd()
	if self.curWaveResult then
		return true, self.curWaveResult
	end

	local me = self:checkForceAllRealDead(1)
	local enemy = self:checkForceAllRealDead(2)
	if enemy then
		return true, 1
	elseif me then
		return true, 2
	end
	if self.curRound >= self.roundLimit and self:checkRoundEnd() and not self:needExtraRound() then
		return true, 2
	end
	return false
end

function CrossMineGate:onWaveEndSupply()
	local _, result = self:checkWaveEnd()
	table.insert(self.waveResultList, result)
	for _, obj in self.scene:ipairsHeros() do
		obj:setDead(nil,nil, {force = true, noTrigger = true})
	end
	self.isWaveEnd = true
end

function CrossMineGate:onBattleEndSupply()
	local result = self.result
	if result == 'win' then self.endAnimation.aniName = "effect_l"
	elseif result == 'fail' then self.endAnimation.aniName = "effect_r" end
end

function CrossMineGate:needExtraRound()
	if self.curRound > self.roundLimit  then
		return false
	end
	for _, obj in self.scene:ipairsHeros() do
		if obj:isFakeDeath() then return true end
	end
	return false
end

function CrossMineGate:checkBattleEnd()
	local _isEnd, _result = self:checkWaveEnd()
	if not _isEnd then
		return false
	end
	local count = 1
	for _, v in ipairs(self.waveResultList) do
		count = battleEasy.ifElse(v == _result, count + 1, count)
	end
	if self.waveCount - count < count then
		local result = battleEasy.ifElse(_result == 1, "win", "fail")
		return true, result
	end
	return false
end

function CrossMineGate:makeEndViewInfos()
	local mvpCardIn, mvpPosId = self:whoHighestDamageFromStats(1, 3)
	-- 直接跳过没有伤害记录 取队伍1
	mvpPosId = mvpPosId or next(self.data.roleOut[1][1])
	if not self.data.roleOut[1][mvpCardIn][mvpPosId] then
		mvpCardIn = 1
		mvpPosId = next(self.data.roleOut[1][1])
	end

	return {
		result = self.result,
		mvpCardIn = mvpCardIn,
		mvpPosId = mvpPosId,
		waveResult = self.waveResultList,
	}
end

function CrossMineGate:getHpRatio(force)
	local HpSum = 0
	local HpMaxSum = force == 1 and self.myDeadHpMaxSum or self.enemyDeadHpMaxSum
	for k = ((force - 1) * 6 + 1), 6 * force do
		local obj = self.scene:getObjectBySeat(k)
		if obj and self:checkObjCanToServer(obj) then
			HpSum = HpSum + obj:hp()
			HpMaxSum = HpMaxSum + obj:hpMax()
		end
	end
	return HpSum / HpMaxSum
end

function CrossMineGate:postEndResultToServer(cb)
	if self.hasPost then
		return
	end
	self.hasPost = true
	local endInfos = self:makeEndViewInfos()
	-- 每波胜负
	local status = {}
	for _, v in ipairs(self.waveResultList) do
		table.insert(status, v == 1 and "win" or "fail")
	end
	table.insert(status, endInfos.result)
	-- 是否精彩战斗
	local cfg = csv['cross']['mine']['base'][1]
	local isTopBattle = false
	local winHpRatio = endInfos.result == "win" and self:getHpRatio(1) or self:getHpRatio(2)
	if cfg and cfg["topBattleRound"] <= self.curRound
		and cfg["topBattleLastHP"] >= winHpRatio then
			isTopBattle = true
	end
	gRootViewProxy:raw():postEndResultToServer("/game/cross/mine/battle/end", function(tb)
		cb(endInfos, tb)
	end, endInfos.result, status, isTopBattle)
end

function CrossMineGate:recordDamageStats()
	for _, obj in self.scene:ipairsHeros() do
		if self:checkObjCanCalcDamage(obj) then
			local totalDamage = 0
			for k,v in pairs(obj.totalDamage) do
				totalDamage = totalDamage + v:get(battle.ValueType.normal)
			end
			local force = obj.force
			local id = obj.id
			local data ={
				posId = obj.seat,
				damageVal = totalDamage
			}
			self.scene.extraRecord:addExRecord(battle.ExRecordEvent.unitsDamage, data, force, self.curWave, id)
		end
	end
end

function CrossMineGate:recordCampDamageStats()
	return
end

function CrossMineGate:onPassOneWave(cb)
	-- 防止连续点击
	if self.passOneWaveCallBack then
		return
	end

	for _, obj in self.scene:ipairsHeros() do
		if not obj:isAlreadyDead() then
			obj.view:proxy():onPassOneWaveClean()
		end
	end
	gRootViewProxy:proxy():onPassOneWaveClean()
	gRootViewProxy:notify('updateLinkEffect', false)

	self.passOneWaveCallBack = cb
	self.scene:waitJumpOneWave()
end

function CrossMineGate:onWaveEffectClean()
	if self.passOneWaveCallBack then
		self.passOneWaveCallBack()
		self.passOneWaveCallBack = nil
	end
	-- 清除所有残留的单位 清空全体护盾引用
	self.scene.forceRecordObject = {}
	gRootViewProxy:notify('sceneClearAll')
end

-- 跨服资源战pvp战报
local CrossMineGateRecord = class("CrossMineGateRecord", battlePlay.CrossMineGate)
battlePlay.CrossMineGateRecord = CrossMineGateRecord

-- 战斗模式设置 手动
CrossMineGateRecord.OperatorArgs = {
	isAuto 			= true,
	isFullManual 	= false,
	canHandle 		= false,
	canPause 		= true,
	canSpeedAni 	= true,
	canSkip 		= true,
}