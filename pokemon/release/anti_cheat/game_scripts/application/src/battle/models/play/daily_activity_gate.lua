
require "battle.app_views.battle.module.include"

-- game.SCENE_TYPE.dailyGold	-- 打boss
-- game.SCENE_TYPE.dailyExp		-- 打地鼠, 敌方单位死亡后原位置立即刷怪

local DailyActivityGate = class("DailyActivityGate", battlePlay.Gate)
battlePlay.DailyActivityGate = DailyActivityGate

-- 战斗模式设置 手动
DailyActivityGate.OperatorArgs = {
	isAuto 			= false,
	isFullManual 	= false,
	canHandle 		= true,
	canPause 		= false,
	canSpeedAni 	= true,
	canSkip 		= true,
}

function DailyActivityGate:ctor(scene)
	battlePlay.Gate.ctor(self, scene)

	self.curKillMonsterCount = 0	-- 可以去掉它
	self.lastKillMonsterCount = 0

	self.gateStar = 3

	self.totalDeadMonsterHp = 0

	self.endMoreDelayTime = 1500
end


function DailyActivityGate:init(data)
	battlePlay.Gate.init(self, data)

	-- 初始化额外界面
	gRootViewProxy:proxy():addSpecModule(battleModule.dailyActivityMods)

	-- 打地鼠 刷怪的总量
	if self.scene.gateType == game.GATE_TYPE.dailyExp then
		-- 刷怪随机库
		self.monsterLib = {}
		local monsterRange = self.scene.sceneConf.monsterRange or {}
		for unitID, num in csvPairs(monsterRange) do
			for i=1, num do
				table.insert(self.monsterLib, unitID)
			end
		end
		table.sort(self.monsterLib)
		local exConditions = self.scene.sceneConf.finishPoint
		self.totalCount = exConditions.killNumber or 0		-- 总刷怪量
		if self.totalCount == 0 then
			self.totalCount = table.length(self.monsterLib)
		end
		-- 设置统计数据显示
		gRootViewProxy:notify("killCount", {curCount=0, totalCount=self.totalCount})

	-- 打boss, boss的血条总数
	elseif self.scene.gateType == game.GATE_TYPE.dailyGold then
		-- 计算血条条数
		local monsterCfg = csvClone(gMonsterCsv[self.scene.sceneID][1])
		self.bossLifeTotalCount = monsterCfg.bossLifeCount or 1
		self.bossLastLifeBarsPer = self.bossLifeTotalCount * 100	-- 这里按整数来算
		-- 显示血条 名字、头像、血条数
		local bossId
		for idx, unitId in ipairs(monsterCfg.monsters) do
			if unitId > 0 and monsterCfg.bossMark and monsterCfg.bossMark[idx] == 1 then
				bossId = unitId
			end
		end
		if bossId then
			local unitCfg = csv.unit[bossId]
			gRootViewProxy:notify("initBossLife", {
				name = unitCfg.name,
				headIconRes = unitCfg.icon,
				leftBars = self.bossLifeTotalCount,
				barsLife = self.bossLastLifeBarsPer
			})
		end
	end
end

function DailyActivityGate:setBoss(obj)
	self.curBoss = obj
	self.hpPerRatio = obj:hpMax() / self.bossLastLifeBarsPer
end

-- 敌方使用monster构造
function DailyActivityGate:createObjectModel(force, seat)
	if force == 1 then
		return ObjectModel.new(self.scene, seat)
	else
		if self.scene.gateType == game.GATE_TYPE.dailyGold then
			return BossModel.new(self.scene, seat)
		else
			return MonsterModel.new(self.scene, seat)
		end
	end
	return obj
end

function DailyActivityGate:newWaveAddObjsStrategy()
	if self.scene.gateType == game.GATE_TYPE.dailyExp then
		self:addCardRoles(1)
		local supplyRoleOutT = {}
		for seat=7, 12 do
			supplyRoleOutT[seat] = self:getMonsterFromLib()
		end
		self:addCardRoles(2, nil, supplyRoleOutT)
		self:doObjsAttrsCorrect(true, true)		-- 属性修正部分
	else
		self:addCardRoles(1)
		self:addCardRoles(2, 1, self:getEnemyRoleOutT(1))
		self:doObjsAttrsCorrect(true, true)		-- 属性修正部分
	end
	if self.scene.gateType == game.GATE_TYPE.dailyGold then
		-- 修正后，boss hp max会有更改
		self.hpPerRatio = self.curBoss:hpMax() / self.bossLastLifeBarsPer
	end
	battlePlay.Gate.newWaveAddObjsStrategy(self)
end

-- 获取随机库中的 Monsters
function DailyActivityGate:getMonsterFromLib()
	if not next(self.monsterLib) then return end
	local idx = ymrand.random(1, table.length(self.monsterLib))
	local unitID = self.monsterLib[idx]
	table.remove(self.monsterLib, idx)

	local roleData = {
		roleId = unitID,
		level = self.scene.sceneLevel,
		skillLevel = self.scene.skillLevel,
		showLevel = self.scene.showLevel,
		roleForce = 2,
		isMonster = true,
		advance = 0,
	}
	return roleData
end

-- 经验本中,怪物被打死后立即原地刷新一个
-- 放到了每一轮战斗结束后添加
function DailyActivityGate:addMonstersOnBattleTurnEnd()
	local supplyRoleOutT = {}
	for seat=7, 12 do
		local obj = self.scene:getObjectBySeatExcludeDead(seat)
		if not obj then
			supplyRoleOutT[seat] = self:getMonsterFromLib()
		end
	end
	self:addCardRoles(2, nil, supplyRoleOutT, nil, true)
end

-- 计算boss血条s 数据
function DailyActivityGate:calcBossLifeBarsLostHp()
	local boss = self.curBoss
	local curPer = math.ceil(boss:hp() / self.hpPerRatio)
	local lostHpPer = math.max(0, self.bossLastLifeBarsPer - curPer)

	self.bossLastLifeBarsPer = curPer
	self.bossLostLifePer = math.ceil(100 - boss:hp()/boss:hpMax() * 100)

	return lostHpPer
end

-- 关卡内的掉落
-- 掉落与进度有关, 每百分比固定掉落，达到某个节点后再额外掉落, 在技能结束时计算
function DailyActivityGate:calcBossDrop()
	if self.scene.gateType == game.GATE_TYPE.dailyGold then
		local boss = self.curBoss
		if not boss then return end

		local lastPer = self.curBossLifePer or 1
		local curPer = cc.clampf(boss:hp()/boss:hpMax(), 0, 1)
		self.curBossLifePer = curPer
		local lostPer = cc.clampf(math.floor((lastPer - curPer)*100), 0, 100)	-- 打掉的百分点
		local nodePer = cc.clampf(math.floor((1 - curPer)*100), 0, 100)				-- 达到的节点
		local dropTb = {nPer = lostPer, nNode = nodePer, tostrModel = tostring(boss)}
		return dropTb
	end
end

-- 死亡时掉落相关的, 计算的是死亡的数量
function DailyActivityGate:calcDeathDrop(deathObjId)   --这里的deathObjId 是位置(seat)
	if self.scene.gateType == game.GATE_TYPE.dailyExp then
		if deathObjId <= 6 then return end	-- 只有敌方才掉落
		local addCount = self.curKillMonsterCount - self.lastKillMonsterCount
		self.lastKillMonsterCount = self.curKillMonsterCount
		local deathObj = self.scene:getObjectBySeat(deathObjId)
		local dropTb = {nPer = addCount, nNode = self.curKillMonsterCount, tostrModel = tostring(deathObj)}
		local tb = self.scene.extraRecord:getEvent(battle.ExRecordEvent.totalHp) or {}
		self.totalDeadMonsterHp = self.totalDeadMonsterHp + (tb[deathObjId] or 0)
		return dropTb
	end
end

-- 一些关卡内的元素需要关卡做的特殊处理部分
-- boss被攻击时血条的显示
function DailyActivityGate:gateDoOnObjectBeAttacked(objId)
	if self.scene.gateType == game.GATE_TYPE.dailyGold then
		local boss = self.curBoss
		if not boss or boss.id ~= objId then return end

		local lostPer = self:calcBossLifeBarsLostHp()
		battleEasy.deferNotifyCantJump(nil, "bossLostHp", {lostHpPer=lostPer})
	end
end

-- 技能结束时, 金钱本要计算boss掉落的金钱
function DailyActivityGate:gateDoOnSkillEnd()
	if self.scene.gateType == game.GATE_TYPE.dailyGold then
		return self:calcBossDrop()
	end
end

-- 角色死亡时, 关卡需要做的处理
function DailyActivityGate:gateDoOnObjectDead(deathObjId)
	-- 打地鼠 杀怪数量统计
	if self.scene.gateType == game.GATE_TYPE.dailyExp then
		if deathObjId > 6 then
			self.scene.extraRecord:addExRecord(battle.ExRecordEvent.killNumber, 1, "Val")
			self.curKillMonsterCount = self.scene.extraRecord:getEventByKey(battle.ExRecordEvent.killNumber,"Val") or 0
			--同时死亡好几只精灵，会导致击杀数错误
			--battleEasy.deferNotify(nil, "killCount", {curCount=self.curKillMonsterCount, totalCount=self.totalCount})
			-- 死亡掉落
			local dropTb = self:calcDeathDrop(deathObjId)
			if dropTb then
				battleEasy.deferNotify(nil, "dropShow", dropTb)
			end
		end
	end
end

-- 流程补充点：
-- turn结束时, 打死的地鼠要刷新下
function DailyActivityGate:onTurnStartSupply()
	if self.scene.gateType == game.GATE_TYPE.dailyExp then
		battleEasy.deferNotify(nil, "killCount", {curCount=self.curKillMonsterCount, totalCount=self.totalCount})
		self:addMonstersOnBattleTurnEnd()
		self:doObjsAttrsCorrect(false, true)		-- 属性修正部分
	end
end

-- 回合round结束, 收集掉落
function DailyActivityGate:onRoundEndSupply()
	battleEasy.deferNotify(nil, "roundEndDropCollection")
end

-- 战斗结束时也收集下, 可能直接结束了
function DailyActivityGate:onBattleEndSupply()
	if self.scene.gateType == game.GATE_TYPE.dailyExp then
		battleEasy.deferNotify(nil, "killCount", {curCount=self.curKillMonsterCount, totalCount=self.totalCount})
	end
	battleEasy.deferNotify(nil, "roundEndDropCollection")
end

-- 战斗结束用的各种星级评分等
function DailyActivityGate:makeEndViewInfos()
	-- 战斗积分
	-- 战斗进度
	local percent = 0
	local score = 0
	local rankNode = 1
	local function getNode(huodongId, curVal)
		huodongId = huodongId or 1
		local cfg = csv.huodong[huodongId] or {}
		local rankShow = cfg.rankShow or {}
		local node = 1
		for i, val in ipairs(rankShow) do
			if val > curVal then
				break
			else
				node = i
			end
		end
		return node
	end
	if self.scene.gateType == game.GATE_TYPE.dailyGold then
		percent = self.bossLostLifePer or 0
		local tb = self.scene.extraRecord:getEvent(battle.ExRecordEvent.campDamage) or {}
		score = tb[1] or 0  -- 这里储存的时候友方为1 敌方为2
		rankNode = getNode(1, percent)
	elseif self.scene.gateType == game.GATE_TYPE.dailyExp then
		percent = self.curKillMonsterCount or 0
		score = self.totalDeadMonsterHp or 0
		rankNode = getNode(2, percent)
	end

	return {
		result = self.result,
		socre = score,
		percent = percent,
		rankNode = rankNode
	}
end

function DailyActivityGate:postEndResultToServer(cb)
	local endInfos = self:makeEndViewInfos()
	gRootViewProxy:raw():postEndResultToServer("/game/huodong/end", function(tb)
		cb(endInfos, tb)
	end, self.scene.battleID, self.scene.sceneID, self.result, self.gateStar, endInfos.percent, endInfos.socre)
end

function DailyActivityGate:endBattleTurn(target)
	if self.scene.gateType == game.GATE_TYPE.dailyGold then
		-- 攻击结束时 要根据boss血量距离上一次的变化 播放转阶段动画
		self.curBoss:playAniAfterBattleTurn()
	end
	-- 判断本次turn是否有死亡目标,有的话就加一个短暂的时间延迟
	local endDelay = 500
	if self.battleTurnInfoTb["hasDeadObj"] then
		endDelay = 1500	--删除的延迟
	end
	battleEasy.queueEffect(function()
		battleEasy.queueEffect('delay', {lifetime=endDelay})
	end)
	battlePlay.Gate.endBattleTurn(self, target)
end









