
local ActivityBossGate = class("ActivityBossGate", battlePlay.Gate)
battlePlay.ActivityBossGate = ActivityBossGate

-- 战斗模式设置 手动
ActivityBossGate.OperatorArgs = {
	isAuto 			= false,
	isFullManual 	= false,
	canHandle 		= true,
	canPause 		= true,
	canSpeedAni 	= true,
	canSkip 		= false,
}

-- 敌方使用monster构造
function ActivityBossGate:createObjectModel(force, seat)
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

function ActivityBossGate:newWaveAddObjsStrategy()
	self:addCardRoles(1)
	self:addCardRoles(2, 1, self:getEnemyRoleOutT(1))
	self:doObjsAttrsCorrect(true, true)		-- 属性修正部分

	battlePlay.Gate.newWaveAddObjsStrategy(self)
end

-- 战斗结束用的各种星级评分等
function ActivityBossGate:makeEndViewInfos()
	local tb = self.scene.extraRecord:getEvent(battle.ExRecordEvent.campDamage) or {}
	local totalDamage = tb[1] or 0

	return {
		result = self.result,
		damage = totalDamage,--math.min(totalTakeDamage,self.scene.data.limitDamage)
	}
end

function ActivityBossGate:postEndResultToServer(cb)
	local endInfos = self:makeEndViewInfos()
	gRootViewProxy:raw():postEndResultToServer("/game/yy/huodongboss/battle/end", {
		cb = function(tb)
			endInfos.drop = tb.view.drop

			cb(endInfos, tb)
		end,
	}, self.scene.battleID, endInfos.result,self.scene.data.activityID, self.scene.data.idx,endInfos.damage)
end








