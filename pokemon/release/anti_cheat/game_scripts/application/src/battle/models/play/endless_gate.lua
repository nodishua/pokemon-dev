
local EndlessGate = class("EndlessGate", battlePlay.Gate)
battlePlay.EndlessGate = EndlessGate

-- 战斗模式设置 手动
EndlessGate.OperatorArgs = {
	isAuto 			= false,
	isFullManual 	= false,
	canHandle 		= true,
	canPause 		= true,
	canSpeedAni 	= true,
	canSkip 		= true,
}

EndlessGate.CommonArgs = {
	AntiMode = battle.GateAntiMode.Operate
}

function EndlessGate:ctor(scene)
	battlePlay.Gate.ctor(self, scene)
end

-- 敌方使用monster构造
function EndlessGate:createObjectModel(force, seat)
	local model = force == 1 and ObjectModel or MonsterModel
	return model.new(self.scene, seat)
end

function EndlessGate:newWaveAddObjsStrategy()
	-- 普通pve副本, 第一波加双方, 后续只加敌方
	if self.curWave == 1 then
		self:addCardRoles(1)
		self:addCardRoles(2, 1, self:getEnemyRoleOutT(1))
		self:doObjsAttrsCorrect(true, true)		-- 属性修正部分
	else
		self:addCardRoles(2, self.curWave, self:getEnemyRoleOutT(self.curWave))
		self:doObjsAttrsCorrect(false, true)
	end
	battlePlay.Gate.newWaveAddObjsStrategy(self)
end

function EndlessGate:makeEndViewInfos()
	return {
		result = self.result,
		gateIdx = self.scene.sceneID - 100000,			-- 当前所处的关卡 胜利结算时要用
		gateId = self.scene.sceneID,					-- 场景ID
		battleCards = self.scene.data.battleCards
	}
end

function EndlessGate:sendParams()
	if self.scene.sceneID > gGameModel.role:read("endless_tower_max_gate") and self.result == "win" then
		return self.scene.battleID, self.scene.sceneID, self.result, self.curRound, battlePlay.Gate.sendActionParams(self)
	end
	return self.scene.battleID, self.scene.sceneID, self.result, self.curRound
end

function EndlessGate:postEndResultToServer(cb)
	gRootViewProxy:raw():postEndResultToServer("/game/endless/battle/end", function(tb)
		cb(self:makeEndViewInfos(), tb)
	end, self:sendParams())
end

function EndlessGate:onceBattle(targetId, skillId)
	-- 手动才有targetId
	-- 记录原始操作数据
	if skillId then
		table.set(self.actionSend, self.curRound, self.curBattleRound, {
			self.curHero.seat,	-- 当前单位
			targetId,			-- 选中目标
			skillId,		-- 选中技能id, 0 表示自动
		})
	end

	battlePlay.Gate.onceBattle(self, targetId, skillId)
end

-- 战报
local EndlessGateRecord = class("EndlessGateRecord", EndlessGate)
battlePlay.EndlessGateRecord = EndlessGateRecord

-- 战斗模式设置 自动
EndlessGateRecord.OperatorArgs = {
	isAuto 			= true,
	isFullManual 	= false,
	canHandle 		= false,
	canPause 		= true,
	canSpeedAni 	= true,
	canSkip 		= true,
}

function EndlessGateRecord:init(data)
	-- 录像文件过来的
	if not data.actions and not data.endlessAttrFix then
		self.OperatorArgs = EndlessGate.OperatorArgs
	end
	battlePlay.Gate.init(self, data)
	self.actionRecv = data.actions
	self.endlessAttrFix = data.endlessAttrFix -- 属性修正自动战斗
end

function EndlessGateRecord:getActionRecv()
	local action = table.get(self.actionRecv, self.curRound, self.curBattleRound)
	if action == nil then return end
	-- curHero.id
	if action[1] == 0 then return end
	return unpack(action)
end

function EndlessGateRecord:sendParams()
	return self.scene.battleID, self.scene.sceneID, self.result, self.curRound
end

function EndlessGateRecord:checkBattleEnd()
	-- for 战斗和战报不一致
	if self.scene.isBattleAllEnd then
		return true, self.result
	end
	return battlePlay.Gate.checkBattleEnd(self)
end

function EndlessGateRecord:onceBattle(targetId, skillId)
	if self.endlessAttrFix then
		battlePlay.Gate.onceBattle(self)
		return
	end

	local rCurId, rTargetId, rSkillId = self:getActionRecv()

	if (rCurId or 0) ~= 0 and rCurId ~= self.curHero.seat then
		-- print('round', self.curRound, self.curBattleRound, 'missmatch', rCurId, self.curHero.id)
		printWarn("EndlessGateRecord战斗和战报不一致")
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
