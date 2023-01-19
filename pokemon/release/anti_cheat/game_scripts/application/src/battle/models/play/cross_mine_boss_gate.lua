-- 跨服资源战boss
local CrossMineBossGate = class("CrossMineBossGate", battlePlay.Gate)
battlePlay.CrossMineBossGate = CrossMineBossGate

-- 战斗模式设置 手动
CrossMineBossGate.OperatorArgs = {
	isAuto 			= false,
	isFullManual 	= false,
	canHandle 		= true,
	canPause 		= true,
	canSpeedAni 	= true,
	canSkip 		= true,
}

CrossMineBossGate.CommonArgs = {
	AntiMode = battle.GateAntiMode.Operate
}


function CrossMineBossGate:init(data)
	battlePlay.Gate.init(self, data)
	self.bossHp = data.bossHp or {}
	self.bossHpMax = data.bossHpMax or {}
	self.bossList = {} --{obj,obj,obj}
	self.unitMaxHp = {}  -- 最大血量 {unitId:hpMax, ...}
	self.unitRemainHp = {}  -- 剩余血量 {unitId:hp, ...}
	self.dmgCount = {} -- 受到伤害 {unitId:damage, ...}

	local hp = 0
	local remainHp = 0
	for id, v in pairs(self.bossHpMax) do
		self.unitMaxHp[id] = v
		hp = hp + v
		if self.bossHp[id] then
			self.unitRemainHp[id] = self.bossHp[id]
			remainHp = remainHp + self.bossHp[id]
		end
	end
	self.maxHp = hp
	self.remainHp = remainHp

	-- gRootViewProxy:proxy():addSpecModule(battleModule.dailyActivityMods)
	self:initBossLife()
end

function CrossMineBossGate:initBossLife()
	if self.maxHp == 0 then
		return
	end
	self.bossHpRatio = self.remainHp / self.maxHp

	local monsterCfg = gMonsterCsv[self.scene.sceneID][1]
	self.originBossLifeCount = monsterCfg.bossLifeCount or 1 --完整血条条数 100
	local hpPercent = self.originBossLifeCount * self.bossHpRatio
	self.bossLifeTotalCount = math.ceil(hpPercent) -- 当前生命对应的血条条数
	self.bossLastLifeBarsPer = hpPercent * 100	-- 当前生命对应的血条条数对应的百分比
	-- 显示血条 名字、头像、血条数

	self.hpPerRatio = self.maxHp / self.originBossLifeCount / 100
	local bossId
	for _, obj in ipairs(self.bossList) do
		if obj:hp() > 0 then
			bossId = obj.orginUnitId
		end
	end
	if not bossId then
		for idx, unitId in ipairs(monsterCfg.monsters) do
			if unitId > 0 then
				bossId = unitId
			end
		end
	end
	if bossId then
		local unitCfg = csv.unit[bossId]
		--可能有三次战斗所以判断下
		gRootViewProxy:notify("initBossLife", {
			name = unitCfg.name,
			headIconRes = unitCfg.icon,
			leftBars = self.bossLifeTotalCount,
			barsLife = self.bossLastLifeBarsPer,
		})
	end
end

function CrossMineBossGate:setBoss(obj)

end

-- 敌方使用boss构造
function CrossMineBossGate:createObjectModel(force, seat)
	if force == 1 then
		return ObjectModel.new(self.scene, seat)
	else
		local obj = BossModel.new(self.scene, seat)
		table.insert(self.bossList, obj)
		return obj
	end
end

function CrossMineBossGate:onNewWave()
	battlePlay.Gate.onNewWave(self)

	local hpMax = 0
	local remainHp = 0
	local heros = self.scene:getHerosMap(2)
	for _, obj in heros:order_pairs() do
		local unitId = obj.orginUnitId
		self.unitMaxHp[unitId] = self.unitMaxHp[unitId] or obj:hpMax()
		self.unitRemainHp[unitId] = self.unitRemainHp[unitId] or obj:hp()
		remainHp = remainHp + self.unitRemainHp[unitId]
		if obj:hp() <= 0 then
			obj:setDead(nil,nil, {force = true, noTrigger = true})
		end
	end

	for _, v in pairs(self.unitMaxHp) do
		hpMax = hpMax + v
	end
	self.maxHp = hpMax
	self.remainHp = remainHp
	self:initBossLife()
end

function CrossMineBossGate:getEnemyRoleOutT(waveId)
	local data = battlePlay.Gate.getEnemyRoleOutT(self, waveId)
	for id, roleData in pairs(data[1]) do
		local unitId = roleData.roleId
		if unitId and self.unitRemainHp[unitId] and self.unitRemainHp[unitId] <= 0 then
			data[1][id] = nil
		end
	end
	return data
end

function CrossMineBossGate:newWaveAddObjsStrategy()
	self:addCardRoles(1)
	self:addCardRoles(2, 1, self:getEnemyRoleOutT(1))
	self:doObjsAttrsCorrect(false, true)

	battlePlay.Gate.newWaveAddObjsStrategy(self)
end

function CrossMineBossGate:doObjsAttrsCorrect(isLeftC, isRightC)
	battlePlay.Gate.doObjsAttrsCorrect(self, isLeftC, isRightC)

	if isRightC then
		for _, obj in ipairs(self.bossList) do
			local unitId = obj.orginUnitId
			if self.bossHpMax[unitId] then
				obj.attrs:setBaseAttr("hpMax", self.bossHpMax[unitId])
				obj.attrs:setBase2Attr("hpMax", self.bossHpMax[unitId])
			end
			if self.bossHp[unitId] then
				obj:setHP(self.bossHp[unitId], self.bossHp[unitId])
			end
		end
	end
end


-- 计算boss血条s 数据
function CrossMineBossGate:calcBossLifeBarsLostHp()
	local remainHp = 0
	for _, obj in ipairs(self.bossList) do
		if not obj:isAlreadyDead() then
			local unitId = obj.orginUnitId
			remainHp = remainHp + obj:hp()
			local lostHpNum = math.max(0, self.unitRemainHp[unitId] - obj:hp())
			self.dmgCount[unitId] = lostHpNum
		end
	end
	local curPer = remainHp / self.hpPerRatio
	local lostHpPer = math.max(0, self.bossLastLifeBarsPer - curPer)
	self.bossLastLifeBarsPer = curPer

	return lostHpPer
end

function CrossMineBossGate:gateDoOnObjectBeAttacked(objId)
	if not itertools.include(self.bossList, function(obj) return obj.id == objId end) then
		return
	end
	local lostPer = self:calcBossLifeBarsLostHp()
	battleEasy.deferNotifyCantJump(nil, "bossLostHp", {lostHpPer=lostPer})
end


function CrossMineBossGate:makeEndViewInfos()
	self.result = "win"
	local totalDmg = 0
	for _, v in pairs(self.dmgCount) do
		totalDmg = totalDmg + v
	end
	return {
		result = self.result,
		damage = totalDmg,
		hpMax = self.maxHp,
	}
end

-- function CrossMineBossGate:onceBattle(targetId, skillId)
-- 	-- 手动才有targetId
-- 	-- 记录原始操作数据
-- 	if skillId then
-- 		table.set(self.actionSend, self.curRound, self.curBattleRound, {
-- 			self.curHero.seat,	-- 当前单位
-- 			targetId,			-- 选中目标
-- 			skillId,		-- 选中技能id, 0 表示自动
-- 		})
-- 	end

-- 	battlePlay.Gate.onceBattle(self, targetId, skillId)
-- end

function CrossMineBossGate:sendParams()
	return self.scene.battleID, self.dmgCount, battlePlay.Gate.sendActionParams(self)
end

function CrossMineBossGate:postEndResultToServer(cb)
	gRootViewProxy:raw():postEndResultToServer("/game/cross/mine/boss/battle/end", {cb=function(tb)
		cb(self:makeEndViewInfos(), tb)
	end}, self:sendParams())
end

function CrossMineBossGate:onBattleEndSupply()
	for _, obj in ipairs(self.bossList) do
		if self:checkObjCanToServer(obj) then
			local unitId = obj.orginUnitId
			if not obj:isAlreadyDead() then
				self.dmgCount[unitId] = self.unitRemainHp[unitId] - obj:hp()
			else
				self.dmgCount[unitId] = self.unitRemainHp[unitId]
			end
			self.dmgCount[unitId] = math.max(self.dmgCount[unitId], 0)
		end
	end
end

-- 跨服资源战boss 战报
local CrossMineBossGateRecord = class("CrossMineBossGateRecord", CrossMineBossGate)
battlePlay.CrossMineBossGateRecord = CrossMineBossGateRecord

function CrossMineBossGateRecord:init(data)
	-- 录像文件过来的
	if not data.actions then
		self.OperatorArgs = CrossMineBossGate.OperatorArgs
	end
	battlePlay.CrossMineBossGate.init(self, data)
	self.actionRecv = data.actions
end

function CrossMineBossGateRecord:getActionRecv()
	local action = table.get(self.actionRecv, self.curRound, self.curBattleRound)
	if action == nil then return end
	-- curHero.id
	if action[1] == 0 then return end
	return unpack(action)
end

function CrossMineBossGateRecord:sendParams()
	return self.scene.battleID, self.dmgCount
end

function CrossMineBossGateRecord:checkBattleEnd()
	-- for 战斗和战报不一致
	if self.scene.isBattleAllEnd then
		return true, self.result
	end
	return battlePlay.Gate.checkBattleEnd(self)
end

function CrossMineBossGateRecord:onceBattle(targetId, skillId)
	local rCurId, rTargetId, rSkillId = self:getActionRecv()

	if (rCurId or 0) ~= 0 and rCurId ~= self.curHero.seat then
		printWarn("CrossMineBossGateRecord战斗和战报不一致")
		self.result = "fail"
		self.scene.isBattleAllEnd = true
		self:onOver()
		return
	end

	-- rSkillId == 0是之前旧写法和补位
	if (rSkillId or 0) ~= 0 then
		self.scene.autoFight = false
		battlePlay.Gate.onceBattle(self, rTargetId, rSkillId)
		self.scene.autoFight = true
		if self.waitInput then
			error("why input be wait in record")
		end
		return
	end

	battlePlay.Gate.onceBattle(self, targetId, skillId)
end
