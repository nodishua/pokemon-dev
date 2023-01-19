--
-- BOSS模块
--

globals.BossModel = class("BossModel", MonsterModel)

-- boss当前生命值 所处的阶段
local bossLifeStage = {
	intact = 1,			-- 完好
	minor = 2,			-- 轻伤
	serious = 3,		-- 重伤
	death = 4,			-- 死亡
}

-- changeAction转阶段动画 changeActionFrame帧数 standbyAction待机动画 受击动画
local hpToAction = {
	[bossLifeStage.intact] = {changeAction = nil, changeActionFrame = nil, standbyAction = "standby_loop", hitAction = "hit"},
	[bossLifeStage.minor] = {changeAction = "change1", changeActionFrame = 55, standbyAction = "standby_loop2", hitAction = "hit2"},
	[bossLifeStage.serious] ={changeAction = "change2", changeActionFrame = 65, standbyAction = "standby_loop3", hitAction = "hit3"},
	[bossLifeStage.death] = {changeAction = nil, changeActionFrame = nil, standbyAction = "use error action name to replace normal", hitAction = nil},
}

function BossModel:ctor(scene, seat)
	MonsterModel.ctor(self, scene, seat)
	self.isBoss = true
end

function BossModel:init(data)
	MonsterModel.init(self, data)
	self.huodongCsv = csv.huodong_drop[self.scene.sceneID]

	if self.huodongCsv then
		local hpPerTb = self.huodongCsv.node
		if not hpPerTb then error(string.format("huodong_drop not find node line in sceneId: %s",self.scene.sceneID)) end

		local hpToStage = {
			[bossLifeStage.intact] = 0,
			[bossLifeStage.minor] = 20,
			[bossLifeStage.serious] = 60,
			[bossLifeStage.death] = 100,
		}

		-- 配表位置是固定值
		hpToStage[bossLifeStage.minor] = hpPerTb[2]
		hpToStage[bossLifeStage.serious] = hpPerTb[3]
		self.hpToStage = hpToStage
		self.curStage = self:getCurStage()

		-- todo 这个death2 这么写是因为目前只有金币BOSS有死亡动作 如果有更多 应该放在配表中
		self.view:notify('pushAction', battle.SpriteActionTable.death, "death2")
	end
end

-- 根据已经损失的生命值获取当前阶段
function BossModel:getCurStage()
	if not self.huodongCsv then error("no stage in boss") end
	local bossLostLifePer = 100 * (1 - self:hp()/self:hpMax()) -- 已损失生命值
	local curStage = bossLifeStage.intact
	for stage, lostPer in pairs(self.hpToStage) do
		if bossLostLifePer >= lostPer and stage > curStage then
			curStage = stage
		end
	end
	log.battle(string.format("==============boss lost hp %s==========================",bossLostLifePer))
	return curStage
end

function BossModel:beAttack(attacker,damage,damageProcessId,extraArgs)
	if self.scene.gateType == game.GATE_TYPE.worldBoss then
		if extraArgs.from == battle.DamageFrom.buff then
			local limit = self:hpMax()*gCommonConfigCsv.worldBossDamageLimitRate
			-- if damage > limit then
			-- 	errorInWindows("world boss damage(%d) to limit(%d) from buff(%d)",damage,limit,extraArgs.buffCfgId or 0)
			-- end
			damage = math.min(damage,limit)
		end
	end
	local damage,damageArgs = MonsterModel.beAttack(self, attacker, damage, damageProcessId, extraArgs)

	local play = self.scene.play

	-- 记录boss的掉血,然后等待去表现
	if play.gateDoOnObjectBeAttacked then
		play:gateDoOnObjectBeAttacked(self.id)
	end

	return damage,damageArgs
end

function BossModel:setHP(v, vShow)
	MonsterModel.setHP(self, v, vShow)
	if self.scene.gateType == game.GATE_TYPE.worldBoss then
		MonsterModel.setHP(self, self.scene.play.recoverHp)
	end
end


-- boss多阶段变化 todo 目前只有金币本会调用
function BossModel:playAniAfterBattleTurn()
	if not self.huodongCsv then error("no stage in boss") end
	local stage = self:getCurStage()
	local isChange = stage ~= self.curStage -- and not self:isAlreadyDead()

	if isChange then
		local changeNum = stage - self.curStage -- 转了几个阶段 可能一次有两三个
		local view = self.view
		local stanAc, hitAc
		if changeNum > 1 and self:isAlreadyDead() then --转了多个阶段被秒 只勃死亡动画
			stage = bossLifeStage.death
			local actionTb = hpToAction[stage]
			battleEasy.queueNotifyFor(view, 'playAction', actionTb.changeAction)
		else
			for st = self.curStage, stage do
				local actionTb = hpToAction[st]
				if actionTb.changeAction and st ~= self.curStage then
					local time = actionTb.changeActionFrame and actionTb.changeActionFrame * game.FRAME_TICK or 20
					battleEasy.queueNotifyFor(view, 'playAction', actionTb.changeAction)
				end
				if actionTb.standbyAction then
					stanAc = actionTb.standbyAction
				end
				if actionTb.hitAction then
					hitAc = actionTb.hitAction
				end
			end
		end
		if stage ~= bossLifeStage.death then
			battleEasy.queueEffect(function()
				if stanAc then
					battleEasy.queueNotifyFor(view, 'pushAction', battle.SpriteActionTable.standby, stanAc)
				end
				if hitAc then
					battleEasy.queueNotifyFor(view, 'pushAction', battle.SpriteActionTable.hit, hitAc)
				end
			end)
			battleEasy.queueNotifyFor(view, 'playAction', battle.SpriteActionTable.standby)
		end
		self.curStage = stage
	end

	return isChange
end



