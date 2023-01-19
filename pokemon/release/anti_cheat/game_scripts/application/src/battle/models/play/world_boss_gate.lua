
require "battle.app_views.battle.module.include"

-- game.SCENE_TYPE.dailyGold	-- 打boss
-- game.SCENE_TYPE.dailyExp		-- 打地鼠, 敌方单位死亡后原位置立即刷怪

local ActivityWorldBossGate = class("ActivityWorldBossGate", battlePlay.Gate)
battlePlay.ActivityWorldBossGate = ActivityWorldBossGate

-- 战斗模式设置 手动
ActivityWorldBossGate.OperatorArgs = {
	isAuto 			= false,
	isFullManual 	= false,
	canHandle 		= true,
	canPause 		= false,
	canSpeedAni 	= true,
	canSkip 		= true,
}

ActivityWorldBossGate.PlayCsvFunc = {
	["damage"] = function(self,level)
		return self.damageAward[level].damage
	end
}

function ActivityWorldBossGate:ctor(scene)
	battlePlay.Gate.ctor(self, scene)

	self.curKillMonsterCount = 0	-- 可以去掉它
	self.lastKillMonsterCount = 0

	self.gateStar = 3

	self.totalDeadMonsterHp = 0
	self.recoverHp = 1

	self.endMoreDelayTime = 1500

	local yyCfg = csv.yunying.yyhuodong[scene.data.activityID]
	self.yyCsvVersion = yyCfg.huodongID
	self.boss_damage_max = scene.data.boss_damage_max

	self:initVersionInfo(ver)
end

function ActivityWorldBossGate:initVersionInfo(ver)
	self.damageAward = {}
	self.damageAwardInfo = {} -- cur next
	self.curtotalTakeDamage = 0
	for _, v in orderCsvPairs(csv.world_boss.damage_award) do
		if v.huodongID == self.yyCsvVersion then
			table.insert(self.damageAward,csvClone(v))
		end
	end
	self:refreshAwardInfoByDamage(0)
end

function ActivityWorldBossGate:refreshAwardInfoByDamage(damage)
	local start = 1
	if self.damageAwardInfo.next then
		if damage < self.damageAwardInfo.next.damage then
			return
		end
	end
	if self.damageAwardInfo.cur then
		--  最后一波
		if not self.damageAwardInfo.next then
			return
		end
		start = self.damageAwardInfo.cur.level + 1
	end

	self.damageAwardInfo = {}
	for i=start,table.length(self.damageAward) do
		local cur = self.damageAward[i]
		if damage < cur.damage then
			self.damageAwardInfo.next = cur
			break
		end
		self.damageAwardInfo.cur = cur
		-- 最后一波
		-- if i == table.length(self.damageAward) then
		-- 	self.damageAwardInfo.next = nil
		-- end
	end
end

function ActivityWorldBossGate:init(data)
	battlePlay.Gate.init(self, data)

	-- 初始化额外界面
	gRootViewProxy:proxy():addSpecModule(battleModule.bossMods)

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
			damageAward = self.damageAward,
		})
	end
end

function ActivityWorldBossGate:setBoss(obj)
	self.curBoss = obj
	self:setRecoverHp(0)

	obj.view:proxy():updateLifeBarState(false)
	-- self.hpPerRatio = obj:hpMax() / self.bossLastLifeBarsPer
end

function ActivityWorldBossGate:setRecoverHp(takeDamage)
	local rate = 1
	-- if takeDamage > 1 then
	-- 	rate = 1 - 1/takeDamage
	-- end
	self.recoverHp = self.curBoss:hpMax() * rate
end

-- 敌方使用monster构造
function ActivityWorldBossGate:createObjectModel(force, seat)
	if force == 1 then
		return ObjectModel.new(self.scene, seat)
	else
		-- boss 固定11号位置
		if seat == 11 then
			return BossModel.new(self.scene, seat)
		end
		return MonsterModel.new(self.scene, seat)
	end
end

function ActivityWorldBossGate:newWaveAddObjsStrategy()
	self:addCardRoles(1)
	self:addCardRoles(2, 1, self:getEnemyRoleOutT(1))
	self:doObjsAttrsCorrect(true, true)		-- 属性修正部分

	-- self.hpPerRatio = self.curBoss:hpMax() / self.bossLastLifeBarsPer

	battlePlay.Gate.newWaveAddObjsStrategy(self)
end

function ActivityWorldBossGate:refreshUIHp(obj)
	if self.curBoss ~= obj then return end

	local totalTakeDamage = obj:getTakeDamageRecord(battle.ValueType.normal)

	self:refreshAwardInfoByDamage(totalTakeDamage)
	self:setRecoverHp(totalTakeDamage)

	local per = 1
	local level = self.damageAwardInfo.cur and self.damageAwardInfo.cur.level or 0
	local limit = self.damageAwardInfo.next and self.damageAwardInfo.next.damage or self.damageAwardInfo.cur.damage

	if self.damageAwardInfo.cur and self.damageAwardInfo.next then
		per = (totalTakeDamage - self.damageAwardInfo.cur.damage) / (self.damageAwardInfo.next.damage - self.damageAwardInfo.cur.damage)
	elseif not self.damageAwardInfo.cur then
		per = totalTakeDamage / self.damageAwardInfo.next.damage
	end
	-- print("refreshUIHp",totalTakeDamage,level,limit)
	if totalTakeDamage > self.curtotalTakeDamage then
		self.curtotalTakeDamage = totalTakeDamage
		-- 伤害超过最终值 血量无变动
		battleEasy.deferNotifyCantJump(nil,"refreshBossHp",per,totalTakeDamage,limit,level)
	end
end

-- function ActivityWorldBossGate:excutePlayCsv(func_name)
-- 	if PlayCsvFunc[func_name] then
-- 		return functools.partial(PlayCsvFunc[func_name],self)
-- 	end
-- end

-- 战斗结束用的各种星级评分等
function ActivityWorldBossGate:makeEndViewInfos()
	local award = self.damageAwardInfo.cur and self.damageAwardInfo.cur.award or {}
	local totalTakeDamage = self.curBoss:getTakeDamageRecord(battle.ValueType.normal)
	return {
		result = self.result,
		damage = totalTakeDamage,--math.min(totalTakeDamage,self.scene.data.limitDamage)
	}
end

function ActivityWorldBossGate:postEndResultToServer(cb)
	local endInfos = self:makeEndViewInfos()
	gRootViewProxy:raw():postEndResultToServer("/game/yy/world/boss/end", {
		cb = function(tb)
			endInfos.award = tb.view.award
			endInfos.isNewRecordDamage = self.boss_damage_max < endInfos.damage
			cb(endInfos, tb)
		end,
	}, self.scene.battleID, self.scene.data.activityID, endInfos.damage)
end

function ActivityWorldBossGate:endBattleTurn(target)
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









