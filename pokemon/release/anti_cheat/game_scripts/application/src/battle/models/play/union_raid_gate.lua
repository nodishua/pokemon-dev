
require "battle.app_views.battle.module.include"

local UnionRaidGate = class("UnionRaidGate", battlePlay.Gate)
battlePlay.UnionRaidGate = UnionRaidGate

-- 战斗模式设置 手动
UnionRaidGate.OperatorArgs = {
	isAuto 			= false,
	isFullManual 	= false,
	canHandle 		= true,
	canPause 		= true,
	canSpeedAni 	= true,
	canSkip 		= true,
}


function UnionRaidGate:init(data)
	battlePlay.Gate.init(self, data)

	-- 初始化额外界面
	gRootViewProxy:proxy():addSpecModule(battleModule.dailyActivityMods)
	if data.hpMax == 0 then
		self.maxHp = 0
		self.remainHp = 0
	else
		self.maxHp = data.hpMax --可能是0
		self.remainHp = data.hpMax - data.damage
	end
	self.dmgCount = 0
	self.dmgAdjust = 0
	self:initBossLife()
end

-- 可能hpmax与服务器不一致, 客户端使用服务器同步的hpmax，但是hp修正为min(local.hpmax, remote.hp)
function UnionRaidGate:initBossLife()
	if self.maxHp == 0 then
		-- 这里return 在后面onNewWave中会重新init
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
	for idx, unitId in ipairs(monsterCfg.monsters) do
		if unitId > 0 and monsterCfg.bossMark and monsterCfg.bossMark[idx] == 1 then
			bossId = unitId
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

function UnionRaidGate:setBoss(obj)
	self.curBoss = obj
	if self.maxHp == 0 then
		self.maxHp = self.curBoss:hpMax()
	end
end

-- 敌方使用boss构造
function UnionRaidGate:createObjectModel(force, seat)
	if force == 1 then
		return ObjectModel.new(self.scene, seat)
	else
		return BossModel.new(self.scene, seat)
	end
end

function UnionRaidGate:onNewWave()
	battlePlay.Gate.onNewWave(self)

	local boss = self.curBoss

	if self.maxHp and self.maxHp ~= 0 then
		local adjust = false
		-- hpmax may be diff between client and server
		if boss:hpMax() - self.maxHp > 1 then
			printWarn("union boss hpMax client %.2f > server %.2f", boss:hpMax(), self.maxHp)
			self.maxHp = boss:hpMax()
			self.remainHp = boss:hpMax()
			adjust = true
		end

		-- remainHp <= hpMax, use remain in anyway
		-- remainHp > hpMax, adjust it
		if self.remainHp - boss:hpMax() > 1 or self.remainHp == 0 then
			if self.remainHp - boss:hpMax() > 1 then
				self.dmgAdjust = self.remainHp - boss:hpMax()
				printWarn("adjust union boss damage %.2f", self.dmgAdjust)
			end
			self.remainHp = boss:hpMax()
			adjust = true
		end

		if adjust then
			self:initBossLife()
		end
		boss:setHP(self.remainHp, self.remainHp)
	end
end

-- 计算boss血条s 数据
function UnionRaidGate:calcBossLifeBarsLostHp()
	local boss = self.curBoss

	local curPer = boss:hp() / self.hpPerRatio
	local lostHpPer = math.max(0, self.bossLastLifeBarsPer - curPer)
	local lostHpNum = math.max(0, self.remainHp - boss:hp())

	self.dmgCount = lostHpNum + self.dmgAdjust
	self.bossLastLifeBarsPer = curPer

	return lostHpPer
end

function UnionRaidGate:gateDoOnObjectBeAttacked(objId)
	local boss = self.curBoss
	if not boss or boss.id ~= objId then return end
	local lostPer = self:calcBossLifeBarsLostHp()
	battleEasy.deferNotifyCantJump(nil, "bossLostHp", {lostHpPer=lostPer})
end


function UnionRaidGate:makeEndViewInfos()
	self.result = "win"
	return {
		result = self.result,
		damage = self.dmgCount,
		hpMax = self.maxHp,
	}
end

-- 发请求后 直接返回城镇
function UnionRaidGate:postEndResultToServer(cb)
	gRootViewProxy:raw():postEndResultToServer("/game/union/fuben/end", function(tb)
		cb(self:makeEndViewInfos(), tb)
	end, self.scene.battleID, self.scene.sceneID, self.result, self.dmgCount, self.maxHp)
end

function UnionRaidGate:onBattleEndSupply()
	local boss = self.curBoss
	if boss and not boss:isAlreadyDead() then
		self.dmgCount = self.remainHp - boss:hp()
	else
		self.dmgCount = self.remainHp
	end
	self.dmgCount = math.max(self.dmgCount + self.dmgAdjust, 0)
end

function UnionRaidGate:newWaveAddObjsStrategy()
	self:addCardRoles(1)
	self:addCardRoles(2, 1, self:getEnemyRoleOutT(1))
	self:doObjsAttrsCorrect(false, true)
	-- if self.curWave == 1 then
		-- gRootViewProxy:notify('enterAnimation', self.scene:getForceIDs(1), self.scene:getForceIDs(2))
	-- else
		-- todo 第二波 问过策划 表示 应该不存在的
		-- gRootViewProxy:notify('enterAnimation', nil, self.scene:getForceIDs(2))
	-- end

	battlePlay.Gate.newWaveAddObjsStrategy(self)
end

