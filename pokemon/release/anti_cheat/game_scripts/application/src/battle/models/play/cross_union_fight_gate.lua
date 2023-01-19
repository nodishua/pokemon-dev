
local CrossUnionFightGate = class("CrossUnionFightGate", battlePlay.Gate)
battlePlay.CrossUnionFightGate = CrossUnionFightGate

-- 战斗模式设置 全自动
CrossUnionFightGate.OperatorArgs = {
	isAuto 			= true,
	isFullManual 	= false,
	canHandle 		= false,
	canPause 		= false,
	canSpeedAni 	= true,
	canSkip 		= true,
}

CrossUnionFightGate.SpecEndRuleCheck ={
	battle.EndSpecialCheck.AllHpRatioCheck,
	battle.EndSpecialCheck.ForceNum,
	battle.EndSpecialCheck.FightPoint,
}

function CrossUnionFightGate:init(data)
	self.battleType = data.battleType -- 1:6v6赛程  2:4v4赛程  3:1v1赛程
	self.battleTimes = data.battleTimes -- 真实战斗次数
	self.defenceBattleTimes = data.defenceBattleTimes -- 敌方真实战斗次数
	local csvBase = csv.cross.union_fight.base[1]
	self.waveCount = csvBase.sceneCount[self.battleType]
	self.roundLimit = csvBase.roundLimit[self.battleType]
	self.attrCorrectMapSceneID = csvBase.attrCorrectMap[self.battleType]
	self.dbIDtb = {}

	self.UIOpition.craftMods = self.battleType == 3
	self.isFinal = self.UIOpition.craftMods

	battlePlay.Gate.init(self, data)
	self.endAnimation = {res = "xianshipvp/jinjichang.skel", aniName = ""}

	-- 1v1赛程
	self.posByForce = {2, 8}
	self.forceToObjId = {-1, -1}
	self.firstRoleout = {{}, {}}
	self.backUp = {{},{}} 		-- 存roleOut 初始化
	self.waveResultList = {} 	-- 每轮次的结果 {1,2,1,2,1}
	self.loserRoleOut = {{},{}} -- 被淘汰的

	self:playStartAni()
end

-- 加个宝可梦开场和进场的动画
function CrossUnionFightGate:playStartAni()
	if self.UIOpition.craftMods then
		gRootViewProxy:notify('showVsPvpView',3)
	else
		gRootViewProxy:notify('showVsPvpView', 1)
	end
end

function CrossUnionFightGate:newWaveAddObjsStrategy()
	self:addCardRoles(1,nil,nil,nil,true)
	self:addCardRoles(2,nil,nil,nil,true)
	self:doObjsAttrsCorrect(true, true)
	battlePlay.Gate.newWaveAddObjsStrategy(self)
end

function CrossUnionFightGate:addCardRoles(force, waveId, roleOutT, roleOutT2, onlyDelDead)
	if self.battleType ~= 3 then -- 6v6和4v4走原来的
		battlePlay.Gate.addCardRoles(self, force)
		return
	end
	local forces = self.scene:getHerosMap(force)
	for _, obj in forces:order_pairs() do
		if not onlyDelDead or obj:isRealDeath() then
			self.scene:onObjDel(obj)
		end
	end
	if not onlyDelDead then forces:clear() end
	self.scene.herosOrder = nil

	if self.curWave == 1 then
		local datas = roleOutT or self.data.roleOut
		local wavesData = waveId and datas[waveId] or datas
		local datas2 = roleOutT2 or self.data.roleOut2
		local wavesData2 = waveId and datas2[waveId] or datas2

		local stepNum = (force == 1) and 0 or self.ForceNumber
		local count = 0
		for seat = 1 + stepNum, self.ForceNumber + stepNum do
			local roleData = wavesData[seat]
			local pos = self.posByForce[force]
			if roleData and not self.scene:getObjectBySeat(pos) then
				count = count + 1
				local obj = self:createObjectModel(force, pos)
				if wavesData2 and next(wavesData2) then
					roleData.role2Data = wavesData2[seat]
				end
				obj:init(roleData)
				forces:insert(obj.id, obj)
				self.forceToObjId[force] = obj.id
				self.firstRoleout[force] = roleData
			elseif roleData and self.scene:getObjectBySeat(pos) then
				if wavesData2 and next(wavesData2) then
					roleData.role2Data = wavesData2[seat]
				end
				table.insert(self.backUp[force], roleData)
			end
		end
		if (force == 1) and (not waveId or waveId == 1) then
			self.scene.forceRecordTb[1]["herosStartCount"] = count
		end
		table.insert(self.forceAdd, force)
	elseif force ~= self.waveResultList[self.curWave - 1] then
		local roleData = self.backUp[force][1]
		if not next(roleData) then
			return
		end
		local pos = self.posByForce[force]
		local obj = self:createObjectModel(force, pos)
		obj:init(roleData)
		forces:insert(obj.id, obj)
		self.forceToObjId[force] = obj.id
		if self.backUp[force][2] then
			table.insert(self.loserRoleOut[force],self.firstRoleout[force])
			self.firstRoleout[force] = self.backUp[force][1]
			self.backUp[force][1] = self.backUp[force][2]
			self.backUp[force][2] = {}
		else
			table.insert(self.loserRoleOut[force],self.firstRoleout[force])
			self.firstRoleout[force] = self.backUp[force][1]
			self.backUp[force][1] = {}
		end
		table.insert(self.forceAdd,force)
		battleEasy.deferNotify(nil, "changeWave", self.waveResultList[self.curWave - 1])
	end

    self.scene:createGroupObj(force, battle.SpecialObjectId.teamShiled)
end

function CrossUnionFightGate:doObjsAttrsCorrect(isLeftC, isRightC)
	local sceneID = self.scene.sceneID
	if isLeftC then
		self.scene.forceRecordTb[1]["totalFightPoint"] = self.scene:getTotalForceFightPoint(1)
	end
	-- 场景波次属性修正
	if isRightC then
		local cfg = self:getMonsterCsv(sceneID,self.curWave)
		if cfg then
			for _, obj in self.scene.enemyHeros:order_pairs() do
				obj:objAttrsCorrectMonster(cfg)
			end
		end
		self.scene.forceRecordTb[2]["totalFightPoint"] = self.scene:getTotalForceFightPoint(2)
	end
	-- 场景属性修正
	local cfgl = gSceneAttrCorrect[self.attrCorrectMapSceneID]
	local cfgr = gSceneAttrCorrect[-self.attrCorrectMapSceneID]
	-- 战力属性修正
	local leftTotalCP = self.scene.forceRecordTb[1]["totalFightPoint"] or 0
	local rightTotalCP = self.scene.forceRecordTb[2]["totalFightPoint"] or 0

	-- battle_fix 玩法属性修正
	local battleFixCfgl, battleFixCfgr = self:getBattleFixCfg()

	for _, obj in self.scene:ipairsHeros() do
		if isLeftC and obj:serverForce() == 1 then
			if cfgl then obj:objAttrsCorrectScene(cfgl) end
			if battleFixCfgl then obj:objAttrsCorrect(battleFixCfgl) end
			if leftTotalCP < rightTotalCP then
				obj:objAttrsCorrectCP(leftTotalCP, rightTotalCP)
			end
		elseif isRightC and obj:serverForce() == 2 then
			if cfgr then obj:objAttrsCorrectScene(cfgr) end
			if battleFixCfgr then obj:objAttrsCorrect(battleFixCfgr) end
			if leftTotalCP > rightTotalCP then
				obj:objAttrsCorrectCP(leftTotalCP, rightTotalCP)
			end
		end
		if not obj:isAlreadyDead() then
            local key = obj.seat
			self.scene.extraRecord:addExRecord(battle.ExRecordEvent.totalHp, obj:hpMax(), key)
		end
	end

	for i = 1, self.ObjectNumber do
		local obj = self.scene:getObjectBySeatExcludeDead(i)
		if obj then
			obj:setHP(obj:hpMax()*obj.hpScale, obj:hpMax()*obj.hpScale)
			obj:setMP1(obj:mp1Max()*obj.mp1Scale+obj:initMp1(), obj:mp1Max()*obj.mp1Scale+obj:initMp1())
		end
	end
	self.states = {}
	self:setdbidTb()
end

function CrossUnionFightGate:getBattleFixCfg()
	local function getAttrMap(data)
		local ret = {}
		for attrName, attrValue in pairs(data) do
			if ObjectAttrs.AttrsTable[attrName] then ret[attrName..'C'] = attrValue end
		end
		return ret
	end
	-- 配表中战斗次数配到10, 实际战斗次数超过10, 按10来算
	local finalData
	local cfgl, cfgr = {}, {}
	local csvData = csv.cross.union_fight.battle_fix
	for _, data in orderCsvPairs(csvData) do
		if data.type == self.battleType then
			if data.battleTimes == self.battleTimes then
				cfgl = getAttrMap(data)
			end
			if data.battleTimes == self.defenceBattleTimes then
				cfgr = getAttrMap(data)
			end
			finalData = data
		end
	end
	if not next(cfgl) then cfgl = getAttrMap(finalData) end
	if not next(cfgr) then cfgr = getAttrMap(finalData) end
	return cfgl, cfgr
end

-- 总血量百分比 人数 战斗力
function CrossUnionFightGate:checkBattleEnd()
	if self.battleType == 3 then
		local isOnlyOneSelf = (not self.backUp[1][1]) or (not next(self.backUp[1][1])) -- 己方只存在一个单位或者没有
    	local isOnlyOneEnemy = (not self.backUp[2][1]) or (not next(self.backUp[2][1])) -- 敌方只存在一个单位或者没有
		-- 0 全死的情况
		local allDead = self:checkBothAllRealDead()
		if allDead then
			if isOnlyOneSelf and isOnlyOneEnemy and table.length(self.scene.realDeathRecordTb) > 0 then
				return self:bothRealDeadSpecCheck()
			elseif isOnlyOneSelf then
				return true, "fail"
			elseif isOnlyOneEnemy then
				return true, "win"
			end
		end
		-- 1.先判断己方死光了没
		if self:checkForceAllRealDead(1) and isOnlyOneSelf then
			return true, "fail"
		end
		-- 2.判断对方死光了没
		if self:checkForceAllRealDead(2) and isOnlyOneEnemy then
			return true, "win"
		end
		-- 3.波数判断, 超过波数上限时就结束
		-- 额外回合最多一回合
		if ((self.curRound >= self.roundLimit and  self:checkRoundEnd()) and not self:checkHaveFakeDead()) then
			local isEnd, result = battlePlay.Gate.checkBattleEnd(self)
			if result =='win' and isOnlyOneEnemy or result =='fail' and isOnlyOneSelf then
				return isEnd, result
			end
		end
		return
	end
	return battlePlay.Gate.checkBattleEnd(self)
end

function CrossUnionFightGate:checkWaveEnd()
	local me = self:checkForceAllRealDead(1)
	local enemy = self:checkForceAllRealDead(2)
	if me and enemy then return true, 3
	elseif me then return true, 2
	elseif enemy then  return true, 1 end

	if (self.curRound >= self.roundLimit and self:checkRoundEnd()) and not self:checkHaveFakeDead() then
		local _, result = self:specialEndCheck()
		return true, result
	end
	return false
end

function CrossUnionFightGate:onBattleEndSupply()
	local _, result = self:checkBattleEnd()
	if result == 'win' then self.endAnimation.aniName = "effect_l"
	elseif result == 'fail' then self.endAnimation.aniName = "effect_r" end
end

function CrossUnionFightGate:checkHaveFakeDead()
	for i = 1, self.ObjectNumber do
		local obj = self.scene:getObjectBySeat(i)
		if obj and obj:isFakeDeath() then return true end
	end
	return false
end

function CrossUnionFightGate:setdbidTb()
	for i = 1, self.ObjectNumber do
		local obj = self.scene:getObjectBySeat(i)
		if obj and self:checkObjCanToServer(obj) then
			self.dbIDtb[i] = obj.dbID
		end
	end
end

function CrossUnionFightGate:setCardStates()
	local winForce = 2
	if self.result == 'win' then winForce = 1 end
	for i = 1, self.ObjectNumber do
		local obj = self.scene:getObjectBySeat(i)
		if obj and self:checkObjCanToServer(obj) then
			if not self.states[obj.dbID] then
				self.states[obj.dbID] = {}
			end
			local hpRatio, mpRatio = obj:hp() / obj:hpMax(), obj:mp1() / obj:mp1Max()
			if self.battleType ~= 1 then mpRatio = 0 end  -- 4v4和1v1怒气都不继承
			self.states[obj.dbID][1] = hpRatio
			self.states[obj.dbID][2] = mpRatio
		elseif self.dbIDtb[i] then
			if not self.states[self.dbIDtb[i]] then
				self.states[self.dbIDtb[i]] = {}
			end
			self.states[self.dbIDtb[i]][1] = 0
			self.states[self.dbIDtb[i]][2] = 0
		end
	end
end

function CrossUnionFightGate:makeEndViewInfos()
	self:setCardStates()
	return {
		result = self.result,
		states = self.states
	}
end

function CrossUnionFightGate:onWaveEndSupply()
	if self.battleType ~= 3 then -- 6v6和4v4走原来的
		battlePlay.Gate.onWaveEndSupply(self)
		return
	end
	local _, meWin = self:checkWaveEnd()
	if meWin == 'win' then meWin = 1
	elseif meWin == 'fail' then meWin = 2 end
	local me = self.scene:getObject(self.forceToObjId[1])
	local enemy = self.scene:getObject(self.forceToObjId[2])
	local whoToDead
	-- 这里只对双方都存活有效
	if meWin == 1 then
		whoToDead = self.scene:getHerosMap(2)
	elseif meWin == 2 then
		whoToDead = self.scene:getHerosMap(1)
	end
	-- may be both dead nil
	if whoToDead then
		for _,obj in whoToDead:order_pairs() do
			obj:setDead(nil,nil, {force = true, noTrigger = true})
		end
	end
	table.insert(self.waveResultList, meWin)
end
