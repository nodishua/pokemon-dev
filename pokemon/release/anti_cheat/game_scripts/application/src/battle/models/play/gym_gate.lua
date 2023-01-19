

local GymGate = class("GymGate", battlePlay.Gate)
battlePlay.GymGate = GymGate

GymGate.CommonArgs = {
	AntiMode = battle.GateAntiMode.Operate
}

local checkBattleEnd1 = function(self)
	local isOnlyOneSelf = not self.backUp[1][self.forceWaveNum[1]+1] or not next(self.backUp[1][self.forceWaveNum[1]+1]) -- 己方只存在一个单位
	local isOnlyOneEnemy = not self.backUp[2][self.forceWaveNum[2]+1] or not next(self.backUp[2][self.forceWaveNum[2]+1]) -- 敌方只存在一个单位
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
		if self.hpChecker then self:hpChecker() end
		local isEnd,result = battlePlay.Gate.checkBattleEnd(self)
		if result =='win' and isOnlyOneEnemy or result =='fail' and isOnlyOneSelf then
			return isEnd,result
		end
	end
	return false
end

local onBattleEndSupply1 = function(self)
	local result = self.result
	if result == 'win' then self.endAnimation.aniName = "effect_l"
	elseif result == 'fail' then self.endAnimation.aniName = "effect_r" end
end

local function getObjTotalDamage(obj)
	local totalDamage = 0
	for k,v in pairs(battle.DamageFrom) do
		local curDamage = obj.totalDamage[v] and obj.totalDamage[v]:get(1) or 0
		totalDamage = totalDamage + curDamage
	end
	return totalDamage
end

local posByForce = {2,8}

local allFuncs = {
	[game.DEPLOY_TYPE.GeneralType] = {
	},
	[game.DEPLOY_TYPE.OneByOneType] = {
		checkBattleEnd = checkBattleEnd1,
		onBattleEndSupply = onBattleEndSupply1,
		SpecEndRuleCheck1 ={
			battle.EndSpecialCheck.SoloSpecialRule,
			battle.EndSpecialCheck.LastWaveTotalDamage,
		},
		SpecEndRuleCheck2 ={
			battle.EndSpecialCheck.SoloSpecialRule,
			battle.EndSpecialCheck.HpRatioCheck,
			battle.EndSpecialCheck.FightPoint,
			battle.EndSpecialCheck.CumulativeSpeedSum,
		},
		hpChecker = function(self)
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
		end,
		needExtraRound = function(self)
			if self.curRound > self.roundLimit  then
				return false
			end
			local me = self.scene:getObject(self.forceToObjId[1])
			local enemy = self.scene:getObject(self.forceToObjId[2])
			if (me and me:isFakeDeath()) or (enemy and enemy:isFakeDeath()) then
				return true
			end
			return false
		end,
		refreshUIHp = function(self)
			local selfHpRatio,enemyHpRatio = -1,-1
			local me = self.scene:getObject(self.forceToObjId[1])
			local enemy = self.scene:getObject(self.forceToObjId[2])
			if me then
				selfHpRatio = me:hp() / me:hpMax()
			end
			if enemy then
				enemyHpRatio = enemy:hp() / enemy:hpMax()
			end
			battleEasy.deferNotify(nil, "changeHpMp",{
				selfHpRatio = selfHpRatio,
				enemyHpRatio = enemyHpRatio,
			})
		end,
		refreshUIMp = function(self)
			local selfMpRatio,enemyMpRatio = -1,-1
			local me = self.scene:getObject(self.forceToObjId[1])
			local enemy = self.scene:getObject(self.forceToObjId[2])
			if me then
				selfMpRatio = me:mp1() / me:mp1Max()
			end
			if enemy then
				enemyMpRatio = enemy:mp1() / enemy:mp1Max()
			end
			battleEasy.deferNotify(nil, "changeHpMp",{
				selfMpRatio = selfMpRatio,
				enemyMpRatio = enemyMpRatio,
			})
		end,
		getFirstRoleOut = function(self, force)
			local roleDatas = self.backUp[force][self.forceWaveNum[force]]
			return roleDatas[posByForce[force]]
		end,
	},
	[game.DEPLOY_TYPE.WheelType] = {
		checkBattleEnd = checkBattleEnd1,
		needExtraRound = function(self)
			if self.curRound > self.roundLimit  then
				return false
			end
			for _, obj in self.scene:ipairsHeros() do
				if obj:isFakeDeath() then return true end
			end
			return false
		end,
		onNewWavePlayAni = function(self)
			self.curWave = self.curWave + 1		-- 波数增加
			self.curRound = 0					-- 回合数重置
			self.totalRoundBattleTurn = 0
			local leftFix,rightFix = 0, 0
			if self.curWave > 1  then
				local waveResult = self.waveResultList[self.curWave - 1]
				if waveResult == 1 then
					rightFix = 1
				elseif waveResult == 2 then
					leftFix = 1
				elseif waveResult == 3 then
					rightFix,leftFix = 1, 1
				end
			end
			gRootViewProxy:notify('setWaveNumber', self.curWave, self.waveCount)
			gRootViewProxy:notify('SetGymNumber', self.forceWaveNum[1] + leftFix, self.forceWaveNum[2] + rightFix)
			battleEasy.queueEffect('delay', {lifetime=300})
			self.scene:waitNewWaveAniDone()
		end,
	},
}

GymGate.OperatorArgs = {
	isAuto 			= false,
	isFullManual 	= false,
	canHandle 		= true,
	canPause 		= true,
	canSpeedAni 	= true,
	canSkip 		= true,
}

function GymGate:init(data)
	battlePlay.Gate.init(self, data)
	local sceneID = data.sceneID
	local cfg = csv.gym.gate[sceneID]
	self.deployType = cfg.deployType
	self.forceWaveNum = {1, 1}            --阵容当前波数
	self.backUp = {{},{}}                 --阵容信息 {{force = {wave = {seat = info}, ...}, ...}, ...}
	self.backUp2 = {{},{}}
	self.forceWaveCount = {0, 0}          --阵容最大波数
	self.forceToObjId = {-1,-1}           -- {[force] = obj.id} 单挑判定用
	self.waveResultList = {}              -- 波次结果 1:我方赢 2:敌方赢 3:同归于尽
	self.mayBeMeWin = false

	if self.deployType == game.DEPLOY_TYPE.OneByOneType then
		gRootViewProxy:proxy():addSpecModule(battleModule.gymMods)
		self.endAnimation = {res = "xianshipvp/jinjichang.skel",aniName = ""}
	end

	self:setAllFuncs(data)
	self:syncBackup()
end

function GymGate:setAllFuncs(data)
	for k,v in pairs(allFuncs[self.deployType]) do
		self[k] = v
	end
end

function GymGate:syncBackup()
	if self.deployType == game.DEPLOY_TYPE.GeneralType then
		self.forceWaveCount = {1, self.waveCount}
		self.backUp[1][1] = self.data.roleOut
		self.backUp2[1][1] = self.data.roleOut2
		for i=1, self.forceWaveCount[2] do
			local waveRoleOutT = self:getEnemyRoleOutT(i)
			table.insert(self.backUp[2], waveRoleOutT and waveRoleOutT[i] or {})
			table.insert(self.backUp2[2], {})
		end
	elseif self.deployType == game.DEPLOY_TYPE.OneByOneType then
		local roundLimit = csv.gym.gate[self.data.sceneID].deployCardNumLimit
		self.forceWaveCount[1] = 0
		self.forceWaveCount[2] = math.max(0, self.waveCount + 1 - roundLimit)
		local meDatas = self.data.roleOut
		local meDatas2 = self.data.roleOut2
		for i=1, roundLimit do
			if meDatas[i] then
				self.forceWaveCount[1] = self.forceWaveCount[1] + 1
				table.insert(self.backUp[1], {[posByForce[1]]=meDatas[i]})
				table.insert(self.backUp2[1], {[posByForce[1]]=meDatas2[i]})
			end
		end
		local sceneCsv = csv.scene_conf[self.scene.sceneID]
		local advanceTb = {}
		for _, v in ipairs(sceneCsv.monsters or {}) do
			table.insert(advanceTb, v.advance)
		end
		for _, v in ipairs(sceneCsv.boss or {}) do
			table.insert(advanceTb, v.advance)
		end
		for i=1, self.forceWaveCount[2] do
			local waveRoleOutT = self:getEnemyRoleOutT(i)
			local objData = waveRoleOutT and waveRoleOutT[i][1+self.ForceNumber]
			if objData then
				objData.advance = advanceTb[i]
			end
			table.insert(self.backUp[2], {[posByForce[2]]=objData})
			table.insert(self.backUp2[2], {})
		end
	elseif self.deployType == game.DEPLOY_TYPE.WheelType then
		self.forceWaveCount[1] = self.data.roleOut[1] and table.length(self.data.roleOut[1]) or 0
		self.forceWaveCount[2] = math.max(0, self.waveCount + 1 - self.forceWaveCount[1])
		self.backUp[1] = self.data.roleOut[1]
		self.backUp2[1] = self.data.roleOut2[1]
		for i=1, self.forceWaveCount[2] do
			local waveRoleOutT = self:getEnemyRoleOutT(i)
			table.insert(self.backUp[2], waveRoleOutT and waveRoleOutT[i] or {})
			table.insert(self.backUp2[2], {})
		end
	else
		self.backUp = self.data.roleOut
		self.backUp2 = self.data.roleOut2
	end
	self.seeBoss = false --待定
end

function GymGate:newWaveAddObjsStrategy()
	if self.curWave == 1 then
		self:addCardRoles(1, nil, self.backUp[1][1], self.backUp2[1][1], true)
		self:addCardRoles(2, nil, self.backUp[2][1], self.backUp2[2][1], true)
		self:doObjsAttrsCorrect(true, true)

		if self.deployType == game.DEPLOY_TYPE.OneByOneType then
			battleEasy.deferNotify(nil, "initPvp")
		end
	else
		if self.waveResultList[self.curWave - 1] == 3 then
			self.forceWaveNum[1] = self.forceWaveNum[1] + 1
			self.forceWaveNum[2] = self.forceWaveNum[2] + 1
			self:addCardRoles(1, nil, self.backUp[1][self.forceWaveNum[1]], false)
			self:addCardRoles(2, nil, self.backUp[2][self.forceWaveNum[2]], false)
			self:doObjsAttrsCorrect(true, true)
		else
			local chosseForce = 3 - self.waveResultList[self.curWave - 1]
			self.forceWaveNum[chosseForce] = self.forceWaveNum[chosseForce] + 1
			self:addCardRoles(chosseForce, nil, self.backUp[chosseForce][self.forceWaveNum[chosseForce]], self.backUp2[chosseForce][self.forceWaveNum[chosseForce]], false)
			self:doObjsAttrsCorrect(chosseForce == 1, chosseForce ~= 1)
		end
	end
	battlePlay.Gate.newWaveAddObjsStrategy(self)
end

function GymGate:addCardRoles(force, waveId, roleOutT, roleOutT2, onlyDelDead)
	battlePlay.Gate.addCardRoles(self, force, waveId, roleOutT, roleOutT2, onlyDelDead)

	if self.deployType == game.DEPLOY_TYPE.OneByOneType then
		if self.curWave ~= 1 then
			battleEasy.deferNotify(nil, "changeWave",self.waveResultList[self.curWave -1])
		end
		for _, obj in self.scene:getHerosMap(force):order_pairs() do
			self.forceToObjId[force] = obj.id
			break
		end
	end
end

function GymGate:createObjectModel(force, seat)
	local obj
	if force == 1 then
		obj = ObjectModel.new(self.scene, seat)
	else
		obj = MonsterModel.new(self.scene, seat)
	end
	return obj
end

function GymGate:doObjsAttrsCorrect(isLeftC, isRightC)
	battlePlay.Gate.doObjsAttrsCorrect(self, isLeftC, isRightC)

	local cfg = csv.gym.gate[self.data.sceneID] or {}
	local function updateAttrs(obj)
		for __, eff in ipairs(cfg.specialEff or {}) do
			local function getBaseAddVal(oriVal)
				local val = eff[4]
				if string.find(val, "%%") then
					val = string.gsub(val, "%%", "")
					val = tonumber(val) / 100.0 * oriVal
				end
				if eff[3] > 0 then
					val = -val
				end
				return val
			end

			if itertools.include(eff[1], function(nature)
				return nature == obj:getNatureType(1) or nature == obj:getNatureType(2) end) then
				local key = game.ATTRDEF_TABLE[eff[2]]
				key = key == "hp" and "hpMax" or key
				key = key == "mp1" and "mp1Max" or key

				local baseVal = getBaseAddVal(obj.attrs.base[key])
				local base2Val = getBaseAddVal(obj.attrs.base2[key])

				obj.attrs:addBaseAttr(key, baseVal)
				obj.attrs:addBase2Attr(key, base2Val)
				obj:setHP(obj:hpMax(), obj:hpMax())
			end
		end
	end

	for _, obj in self.scene:ipairsHeros() do
		if isLeftC and obj.force == 1 or isRightC and obj.force == 2 then
			updateAttrs(obj)
		end
	end
end

function GymGate:checkWaveEnd()
	local me = self:checkForceAllRealDead(1)
	local enemy = self:checkForceAllRealDead(2)
	if me and enemy then return true, 3
	elseif me then return true, 2
	elseif enemy then  return true, 1 end
	if self.curRound >= self.roundLimit and self:checkRoundEnd() and not self:needExtraRound() then
		if self.hpChecker then self:hpChecker() end
		local _,result = self:specialEndCheck()
		return true,result or 2
	end
	return false
end

function GymGate:onWaveEndSupply()
	local _,meWin = self:checkWaveEnd()
	if meWin and meWin == 'win' then meWin = 1
	elseif meWin == 'fail' then meWin = 2 end
	table.insert(self.waveResultList, meWin)

	if self.deployType == game.DEPLOY_TYPE.OneByOneType then
		local me = self.scene:getObject(self.forceToObjId[1])
		local enemy = self.scene:getObject(self.forceToObjId[2])
		local whoToDead
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
		if me then
			me.lastWaveTotalDamage = getObjTotalDamage(me)
		end
		if enemy then
			enemy.lastWaveTotalDamage = getObjTotalDamage(enemy)
		end
	end
end


function GymGate:makeEndViewInfos()
	local _, mvpPosId = self:whoHighestDamageFromStats(1)

	return {
		result = self.result,
		mvpPosId = mvpPosId,
		actions = self:sendActionParams(),
	}
end

function GymGate:postEndResultToServer(cb)
	local tb = self.scene.extraRecord:getEvent(battle.ExRecordEvent.campDamage)
	local totalDamage = tb and tb[1]
	totalDamage = totalDamage or 0
	gRootViewProxy:raw():postEndResultToServer("/game/gym/gate/end", {cb=function(tb)
		cb(self:makeEndViewInfos(), tb)
	end}, self.scene.battleID, self.scene.sceneID, self.result, totalDamage)
end

-- 回放
local GymGateRecord = class("GymGateRecord", GymGate)
battlePlay.GymGateRecord = GymGateRecord

GymGateRecord.OperatorArgs = {
	isAuto 			= true,
	isFullManual 	= false,
	canHandle 		= false,
	canPause 		= true,
	canSpeedAni 	= true,
	canSkip 		= true,
}

function GymGateRecord:init(data)
	battlePlay.GymGate.init(self, data)
	self.actionRecv = data.actions
end

function GymGateRecord:getActionRecv()
	local action = table.get(self.actionRecv, self.curRound, self.curBattleRound)
	if action == nil then return end
	if action[1] == 0 then return end
	return unpack(action)
end

function GymGateRecord:onceBattle(targetId, skillId)
	local rCurId, rTargetId, rSkillId = self:getActionRecv()

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

-- 道馆馆主
local GymLeaderGate = class("GymLeaderGate", battlePlay.ArenaGate)
battlePlay.GymLeaderGate = GymLeaderGate

function GymLeaderGate:init(data)
	battlePlay.Gate.init(self, data)
end

function GymLeaderGate:postEndResultToServer(cb)
	gRootViewProxy:raw():postEndResultToServer("/game/gym/leader/battle/end", function(tb)
		cb(self:makeEndViewInfos(), tb)
	end, self.result, gGameModel.battle.gym_id)
end

-- 跨服道馆
local CrossGymGate = class("CrossGymGate", battlePlay.GymLeaderGate)
battlePlay.CrossGymGate = CrossGymGate

function CrossGymGate:postEndResultToServer(cb)
	gRootViewProxy:raw():postEndResultToServer("/game/cross/gym/battle/end", function(tb)
		cb(self:makeEndViewInfos(), tb)
	end, self.result, gGameModel.battle.gym_id, gGameModel.battle.pos)
end

-- 馆主和跨服馆主记录
local GymLeaderGateRecord = class("GymLeaderGateRecord", battlePlay.ArenaGateRecord)
battlePlay.GymLeaderGateRecord = GymLeaderGateRecord