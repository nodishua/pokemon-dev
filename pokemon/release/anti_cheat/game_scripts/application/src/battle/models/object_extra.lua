-- 战斗额外对象

globals.ObjectExtraModel = class("ObjectExtraModel", ObjectModel)
local PassiveSkillTypes = battle.PassiveSkillTypes

function ObjectExtraModel:ctor(scene, seat)
	ObjectModel.ctor(self, scene, seat)
end

function ObjectExtraModel:init(data)
	self.followArgs = data.followArgs
	ObjectModel.init(self, data)
end

function ObjectExtraModel:addObjViewToScene()
    local args = {
		type = battle.SpriteType.Follower,
		offsetPos = cc.p(self.followArgs.x or -100, self.followArgs.y or 100)
	}
	self.view = gRootViewProxy:getProxy('onSceneAddObj', tostring(self), readOnlyProxy(self, {
		hp = function()
			return self:hp(true)
		end,
		mp1 = function()
			return self:mp1(true)
		end,
		setHP = function(_, v)
			return self:setHP(nil, v)
		end,
		setMP1 = function(_, v)
			return self:setMP1(nil, v)
		end,
	}), args)
end

function ObjectExtraModel:delBuffsWithSelf()
	-- 删除目标为该单位的buff
	local enemyForce = self.force == 1 and 2 or 1
	for _, obj in self.scene.extraHeros:order_pairs() do
		if not obj:isAlreadyDead()
			and (obj:isBeInSneer() and obj:getSneerObj() and obj:getSneerObj().id == self.id) then
			for _, buff in obj:iterBuffsWithEasyEffectFunc("sneer") do
				if buff.csvCfg.easyEffectFunc == 'sneer' then
					buff:overClean()
				end
			end
		end
	end
end

function ObjectExtraModel:recordRealDeadHpMaxSum()
end

-- 额外单位死亡不给攻击者加怒气
function ObjectExtraModel:addAttackerMpOnSelfDead(attacker)
end
