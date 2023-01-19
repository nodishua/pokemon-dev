

local CraftGateRecord = class("CraftGateRecord", battlePlay.Gate)
battlePlay.CraftGateRecord = CraftGateRecord

-- 战斗模式设置 全自动
CraftGateRecord.OperatorArgs = {
	isAuto 			= true,
	isFullManual 	= false,
	canHandle 		= false,
	canPause 		= false,
	canSpeedAni 	= true,
	canSkip 		= true,
}

--满足特殊要求用表1
CraftGateRecord.SpecEndRuleCheck1 ={
	battle.EndSpecialCheck.SoloSpecialRule,
	battle.EndSpecialCheck.LastWaveTotalDamage,
}
--不满足特殊要求用表2
CraftGateRecord.SpecEndRuleCheck2 ={
	battle.EndSpecialCheck.SoloSpecialRule,
	battle.EndSpecialCheck.HpRatioCheck,
	battle.EndSpecialCheck.FightPoint,
	battle.EndSpecialCheck.CumulativeSpeedSum,
}

local function getObjTotalDamage(obj)
	local totalDamage = 0
	for k,v in pairs(battle.DamageFrom) do
		local curDamage = obj.totalDamage[v] and obj.totalDamage[v]:get(1) or 0
		totalDamage = totalDamage + curDamage
	end
	return totalDamage
end

CraftGateRecord.UIOpition = {
	craftMods = true
}

function CraftGateRecord:init(data)
	-- local val = dataEasy.getPrivilegeVal(game.PRIVILEGE_TYPE.BattleSkip)
	-- if val == game.GATE_TYPE.arena then
	-- 	self.OperatorArgs.canSkip = true
	-- end
	self.isFinal = data.isFinal
	battlePlay.Gate.init(self, data)
	self.posByForce = {2,8}
	self.score = 0
	self.enemyScore = 0
	self.firstRoleout = {{},{}}

	if self.isFinal then --KOF式的后备成员
		self.backUp = {{},{}} -- 存roleOut 初始化
		self.waveResultList = {} --每轮次的结果 {1,2,1,2,1}
		self.loserRoleOut = {{},{}} --被淘汰的
	else
		self.waveCount = 1
	end
	self.endAnimation = {res = "xianshipvp/jinjichang.skel",aniName = ""}
	-- key:buff.csvCfg.id value:AddBuffToHero()的次数
	self.craftBuffAddTimes = {}
	self.forceToObjId = {-1,-1}    -- {[force] = obj.id}
	self:playStartAni()
end

-- 加个宝可梦开场和进场的动画
function CraftGateRecord:playStartAni()
	if self.isFinal then
		gRootViewProxy:notify('showVsPvpView',3)
	else
		gRootViewProxy:notify('showVsPvpView',2)
	end
end

function CraftGateRecord:newWaveAddObjsStrategy()
	self:addCardRoles(1,nil,nil,nil,true)
	self:addCardRoles(2,nil,nil,nil,true)
	self:doObjsAttrsCorrect(true, true)
	battlePlay.Gate.newWaveAddObjsStrategy(self)
end

function CraftGateRecord:addCardRoles(force, waveId, roleOutT, roleOutT2, onlyDelDead)
	local forces = self.scene:getHerosMap(force)
	for _, obj in forces:order_pairs() do
		if not onlyDelDead or obj:isRealDeath() then
			self.scene:onObjDel(obj)	-- 先删除旧的
		end
	end
	if not onlyDelDead then
		forces:clear()
	end
	self.scene.herosOrder = nil

	if self.curWave == 1 then --初始逻辑
		local datas = roleOutT or self.data.roleOut
		local wavesData = waveId and datas[waveId] or datas
		local datas2 = roleOutT2 or self.data.roleOut2
		local wavesData2 = waveId and datas2[waveId] or datas2

		local stepNum = (force == 1) and 0 or self.ForceNumber
		local count = 0
		for seat=1+stepNum, self.ForceNumber + stepNum do
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
				table.insert(self.backUp[force],roleData)
			end
		end

		if (force == 1) and (not waveId or waveId == 1) then	-- 记录第一波时的人数
			self.scene.forceRecordTb[1]["herosStartCount"] = count
		end
		table.insert(self.forceAdd,force)

	elseif force ~= self.waveResultList[self.curWave -1] then-- 波次轮换逻辑 特殊 失败方已在上一回合结束移除
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
		table.insert(self.forceAdd,force)		-- 记录本次添加了某一阵营的单位
		battleEasy.deferNotify(nil, "changeWave",self.waveResultList[self.curWave -1])
	end

    self.scene:createGroupObj(force,battle.SpecialObjectId.teamShiled)
end

-- 判断当前战斗是否结束 true 结束 false 胜利
function CraftGateRecord:checkBattleEnd()
    local isOnlyOneSelf = (not self.isFinal) or (not next(self.backUp[1][1])) -- 己方只存在一个单位
    local isOnlyOneEnemy = (not self.isFinal) or (not next(self.backUp[2][1])) -- 敌方只存在一个单位
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
	if ((self.curRound >= self.roundLimit and  self:checkRoundEnd()) and not self:needExtraRound()) then
		self:hpChecker()
		local isEnd,result = battlePlay.Gate.checkBattleEnd(self)
		if result =='win' and isOnlyOneEnemy or result =='fail' and isOnlyOneSelf then
			return isEnd,result
		end
	end
	return false
end

function CraftGateRecord:hpChecker()
	local me = self.scene:getObject(self.forceToObjId[1])
	local myHpRatio = 0
	if me then
		myHpRatio = me:hp()/me:hpMax()
	end
	local enemy = self.scene:getObject(self.forceToObjId[2])
	local enemyHpRatio = 0
	if enemy then
		enemyHpRatio = enemy:hp()/enemy:hpMax()
	end
	--双方精灵，都大于A%
	local ratioBorder = gCommonConfigCsv.craftHpRatioBorder or 1
	if myHpRatio - ratioBorder > 1e-6 and enemyHpRatio - ratioBorder > 1e-6 then
		self.SpecEndRuleCheck = self.SpecEndRuleCheck1
		return
	end
	self.SpecEndRuleCheck = self.SpecEndRuleCheck2
end

function CraftGateRecord:onBattleEndSupply()
	local result = self.result
	if result == 'win' then self.endAnimation.aniName = "effect_l"
	elseif result == 'fail' then self.endAnimation.aniName = "effect_r" end
end

function CraftGateRecord:checkWaveEnd()
	local me = self:checkForceAllRealDead(1)
	local enemy = self:checkForceAllRealDead(2)
	if me and enemy then return true, 3
	elseif me then return true, 2
	elseif enemy then  return true, 1 end
	if self.curRound >= self.roundLimit and self:checkRoundEnd() and not self:needExtraRound() then
		self:hpChecker()
		local _,result = self:specialEndCheck()
		return true,result
	end
	return false
end

function CraftGateRecord:onWaveEndSupply()
	local _,meWin = self:checkWaveEnd()
	if meWin == 'win' then meWin = 1
	elseif meWin == 'fail' then meWin = 2 end
	local me = self.scene:getObject(self.forceToObjId[1])
	local enemy = self.scene:getObject(self.forceToObjId[2])
	local whoToDead
	--这里只对双方都存活有效
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

	if self.isFinal then
		table.insert(self.waveResultList, meWin)

		if me then
			me.lastWaveTotalDamage = getObjTotalDamage(me)
		end
		if enemy then
			enemy.lastWaveTotalDamage = getObjTotalDamage(enemy)
		end
	end
end

function CraftGateRecord:needExtraRound()
	local me = self.scene:getObject(self.forceToObjId[1])
	local enemy = self.scene:getObject(self.forceToObjId[2])
	if (me and me:isFakeDeath()) or (enemy and enemy:isFakeDeath()) then
		return true
	end
	return false
end

-- function CraftGateRecord:refreshUIHp()
-- 	local selfHpRatio,enemyHpRatio = -1,-1
-- 	local me = self.scene:getObject(self.forceToObjId[1])
-- 	local enemy = self.scene:getObject(self.forceToObjId[2])
-- 	if me then
-- 		selfHpRatio = me:hp() / me:hpMax()
-- 	end
-- 	if enemy then
-- 		enemyHpRatio = enemy:hp() / enemy:hpMax()
-- 	end
-- 	battleEasy.deferNotify(nil, "changeHpMp",{
-- 		selfHpRatio = selfHpRatio,
-- 		enemyHpRatio = enemyHpRatio,
-- 	})
-- end

-- function CraftGateRecord:refreshUIMp()
-- 	local selfMpRatio,enemyMpRatio = -1,-1
-- 	local me = self.scene:getObject(self.forceToObjId[1])
-- 	local enemy = self.scene:getObject(self.forceToObjId[2])
-- 	if me then
-- 		selfMpRatio = me:mp1() / me:mp1Max()
-- 	end
-- 	if enemy then
-- 		enemyMpRatio = enemy:mp1() / enemy:mp1Max()
-- 	end
-- 	battleEasy.deferNotify(nil, "changeHpMp",{
-- 		selfMpRatio = selfMpRatio,
-- 		enemyMpRatio = enemyMpRatio,
-- 	})
-- end

-- 数据记录
function CraftGateRecord:recordScoreStats(attacker, score)
	if attacker and self:checkObjCanCalcDamage(attacker) then
        local key = attacker.force
		self.scene.extraRecord:addExRecord(battle.ExRecordEvent.score, score, key)
	end
end

function CraftGateRecord:recordDamageStats()
	for _, obj in self.scene:ipairsHeros() do
		if self:checkObjCanCalcDamage(obj) then
			local totalDamage = 0
			for k,v in pairs(obj.totalDamage) do
				totalDamage = totalDamage + v:get(battle.ValueType.normal)
			end
			local key = obj.force
			local id = obj.id
			local data = {
				posId = obj.seat,
				damageVal = totalDamage
			}
			self.scene.extraRecord:addExRecord(battle.ExRecordEvent.unitsDamage, data, key, id)
		end
	end
end

function CraftGateRecord:makeEndViewInfos()
	local ratio = csv.craft.base[1].damageScoreRatio
	local score,enemyScore = 0,0
	local tb = self.scene.extraRecord:getEvent(battle.ExRecordEvent.score)
	if tb then
		tb[1] = tb[1] or 0
		tb[2] = tb[2] or 0
		score = math.floor(tb[1] / ratio)
		enemyScore = math.floor(tb[2] / ratio)
	end
	self.score = score
	self.enemyScore = enemyScore
	return {result = self.result,score = self.score}
end