


local SimpleActivityGate = class("SimpleActivityGate", battlePlay.Gate)
battlePlay.SimpleActivityGate = SimpleActivityGate

-- 战斗模式设置 手动
SimpleActivityGate.OperatorArgs = {
	isAuto 			= false,
	isFullManual 	= false,
	canHandle 		= true,
	canPause 		= true,
	canSpeedAni 	= true,
	canSkip 		= true,
}

SimpleActivityGate.SpecEndRuleCheck = {
	battle.EndSpecialCheck.DirectWin,
}

function SimpleActivityGate:init(data)
	-- 先获取下场景配表中的星数条件
	--self:initStarConditions()
	self.gateStar = 3

	-- 活动副本中的圣诞副本去掉跳过
	if self.scene.gateType == game.GATE_TYPE.simpleActivity then
		self.OperatorArgs = clone(SimpleActivityGate.OperatorArgs)
		self.OperatorArgs.canSkip = false
	end

	battlePlay.Gate.init(self, data)
end

-- 敌方使用monster构造
function SimpleActivityGate:createObjectModel(force, seat)
	local obj
	if force == 1 then
		obj = ObjectModel.new(self.scene, seat)
	else
		obj = MonsterModel.new(self.scene, seat)
	end
	return obj
end

function SimpleActivityGate:newWaveAddObjsStrategy()
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

function SimpleActivityGate:doObjsAttrsCorrect(isLeftC, isRightC)
	battlePlay.Gate.doObjsAttrsCorrect(self, isLeftC,isRightC)
	if self.scene.gateType == game.GATE_TYPE.fragment then
		local enemyMarkIDTb = {}
		for _, obj in self.scene.enemyHeros:order_pairs() do
			local markID = obj.markID
			enemyMarkIDTb[markID] = true
		end
		for _, obj in self.scene.heros:order_pairs() do
			local markID = obj.markID
			if enemyMarkIDTb[markID] then
				--满怒
				obj:setMP1(obj:mp1Max(),obj:mp1Max())
			end
		end
	end
end
-- 星级条件部分
-- function SimpleActivityGate:makeEndViewInfos()
-- 	if self.endInfos then return self.endInfos end

-- 	-- 星级

-- 	self.endInfos = {
-- 		result = self.result,
-- 	}
-- 	return self.endInfos
-- end

function SimpleActivityGate:postEndResultToServer(cb)
	local endInfos = self:makeEndViewInfos()
	gRootViewProxy:raw():postEndResultToServer("/game/huodong/end", function(tb)
		cb(endInfos, tb)
	end, self.scene.battleID, self.scene.sceneID, self.result, self.gateStar,0,0)
end