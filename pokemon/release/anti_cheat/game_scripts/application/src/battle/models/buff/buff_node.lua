--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2019 TianJi Information Technology Inc.
--
-- buff节点管理
--

local DeathTriggerPoints = {
	[battle.BuffTriggerPoint.onHolderDeath] = true,
	[battle.BuffTriggerPoint.onHolderRealDeath] = true,
}


local BuffNodeManager = class("BuffNodeManager")
globals.BuffNodeManager = BuffNodeManager

function BuffNodeManager:ctor(buff)
	self.buff = buff
	self.globalMgr = buff.scene.buffGlobalManager

	self.nodes = {} 	-- 以触发节点存储的格式 格式：{nodeId = nodeCfg, }
	self.nodeIds = {}	-- {nodeId, nodeId, ...}
	self.points = {} 	-- 以触发时刻点存储的格式(触发时刻点:比如在buff创建时,在角色攻击时,等) 格式：{triggerPoint = nodeCfg, }

	self.times = {} 	-- 用于那种只触发1次(或n次)就不再触发的buff,需要对应到节点,不同触发效果的次数条件可能不同 {nodeId = times}
	self.active =  {}	-- 效果是否已经触发(只记录触发,不关心是触发成功了还是触发失败了 )
	self.lifeRounds = {} 	--buff触发后效果可以维持多久(效果到期时会over掉)
	self.extraAttack = {} 	-- {point: value}

	-- 这里叫触发时刻点而不是触发时间的原因是,有些触发点并不是很直观的对应到时间上,比如角色被攻击时,这个点的时间关系不是很明确
	self.hasDeathTriggerNode = false
end

function BuffNodeManager:init(behaviors)
	behaviors = csvClone(behaviors) or {
		{nodeId = 0, triggerPoint = battle.BuffTriggerPoint.onBuffCreate}
	}
	-- 有特殊限制的先处理下 (补充0号节点给easyEffectFunc用)
	for _, node in pairs(behaviors) do
		local nodeId = node.nodeId
		if nodeId and type(nodeId) == 'number' then
			--转一下存储格式
			self.nodes[nodeId] = node
			table.insert(self.nodeIds, nodeId)

			-- 同一触发时刻可能有多个节点
			local triggerPoint = node.triggerPoint
			self.points[triggerPoint] = self.points[triggerPoint] or {}
			table.insert(self.points[triggerPoint], nodeId)

			self:preProcessWithNode(nodeId, node)
		end
	end
end

function BuffNodeManager:preProcessWithNode(nodeId, node)
	local triggerPoint = node.triggerPoint

	-- 触发次数
	if node.triggerTimes then
		if node.triggerTimes[1] <= 2 then
			self.times[nodeId] = {
				triggerType = node.triggerTimes[1],
				value = node.triggerTimes[2]
			}
		end

		-- 战斗中只能触发一次 (暂时去掉这种, 目前还没有用到)
	end

	-- 持续回合数
	if node.lastRoundsWhenTriggered then
		self.lifeRounds[nodeId] = node.lastRoundsWhenTriggered
	end

	-- 可能有死亡后触发的节点 (可能会用到,暂时还没有)
	if DeathTriggerPoints[triggerPoint] then
		self.hasDeathTriggerNode = true
	end
end


-- 与 holder 有关的触发点参数、条件判断, 触发点类型对应scene和object中的触发函数
-- 触发函数是主要的触发条件，主要决定何时触发，而其它条件则是次要判断条件，在触发时机满足的前提下，再判断次要条件是否满足
function BuffNodeManager:check(nodeId)
	local node = self.nodes[nodeId]
	if not node then return false end

	-- 增加战斗中只能触发一次的记录, 触发后就记录下来(若不触发，则可以继续添加直到触发为止)
	-- todo 需要记录 holder ,针对某个目标有效
	local function judgeTriggerTimes(info)
		if not info then
			return true
		end
		if info.triggerType == 1  then
			return info.value > 0
		elseif info.triggerType == 2 then
			return info.value > 0 and self.active[nodeId] ~= self.buff.lifeRound
		end
	end
	--触发次数的判断
	local judge = judgeTriggerTimes(self.times[nodeId])
	if not judge then return false end

	-- 如果配置了条件组合,需要先把组合的原则拿出来(c1~c5对应配表中的onSkillType等的条件顺序,目前写了5个备用条件,不够再加)
	local conditionT = {c1=true, c2=true, c3=true, c4=true, c5=true}
	-- c1.技能类型
	if node.onSkillType and not self.buff:onSkillType(node.onSkillType) then
		conditionT.c1 = false
	end
	-- c2.血量要求
	if node.onCurHP then
		local valTb = node.onCurHP
		if not self.buff:onCurHP(valTb.valueType, valTb.value, valTb.comp) then
			conditionT.c2 = false
		end
	end
	-- c3.技能伤害条件
	if node.onSkillDamage then
		local valTb = node.onSkillDamage
		if not self.buff:onSkillDamage(valTb.valueType, valTb.value, valTb.comp) then
			conditionT.c3 = false
		end
	end
	-- c4.状态类条件:手写的一些特殊状态,主要用于判断目标当前的状态
	if node.onSomeFlag then
		local valTb = node.onSomeFlag
		if not self.buff:onSomeFlag(valTb) then
			conditionT.c4 = false
		end
	end
	-- c5. --todo 还没加

	-- 最后. 条件组合结果判断
	if node.conditionExpr then
		return battleCsv.doFormula(node.conditionExpr, {conditionT = conditionT})
	else
		return not itertools.include(conditionT, function(v)
			return v == false
		end)
	end
end

function BuffNodeManager:visitNodeByPoint(point, f)
	local nodeIds = self.points[point]
	if nodeIds == nil then return end
	local nodes = self.nodes
	for i = 1, table.length(nodeIds) do
		local nodeId = nodeIds[i]
		f(nodeId, nodes[nodeId])
	end
end

function BuffNodeManager:filterNodeByPoint(point, f)
	local nodeIds = self.points[point]
	if nodeIds == nil then return false end
	local nodes = self.nodes
	for i = 1, table.length(nodeIds) do
		local nodeId = nodeIds[i]
		if f(nodeId, nodes[nodeId]) then
			return true
		end
	end
	return false
end

function BuffNodeManager:trigger(nodeId)
	local node = self.nodes[nodeId]

	--加触发过的判断，在触发后效果能维持多少回合中用到, 不管是否执行成功, 只要触发过就算是触发了
	if not self.active[nodeId] then
		self.active[nodeId] = self.buff.lifeRound
	end

	--触发次数的判断
	if self.times[nodeId] then
		self.times[nodeId].value = self.times[nodeId].value - 1
	end
	-- 普通buff的触发刷新
	if nodeId == 0 and self.nodes[nodeId] and self.nodes[nodeId].triggerPoint
		~= battle.BuffTriggerPoint.onBuffTrigger and not self.buff:isSpecBuff() then
		self.buff.scene.buffGlobalManager:refreshBuffLimit(self.buff.scene,self.buff)
	end
	-- if self.isGlobalLimit then
	-- 	self.globalMgr:addType3Record(self.buff.holder.force,self.buff.cfgId)
	-- end
	return node
end

function BuffNodeManager:onTriggerEnd(nodeId, makeit)
	local node = self.nodes[nodeId]

	if makeit then
		if node.trueCall then
			for _, otherNodeId in ipairs(node.trueCall) do
				if otherNodeId ~= nodeId then	--防止node自身循环(正常情况应该不需要这种循环的,如果真的需要可以另外再加参数控制)
					self.buff:triggerByNode(otherNodeId)
				end
			end
		end
	else
		if node.falseCall then
			for _, otherNodeId in ipairs(node.falseCall) do
				if otherNodeId ~= nodeId then
					self.buff:triggerByNode(otherNodeId)
				end
			end
		end
	end

	-- buff的某个节点全部执行后，立即删除自身(包括n回合多次的)
	if (node.delSelfWhenTriggered == 1) and not(self.times[nodeId] and self.times[nodeId].value > 0) then
		self.buff:over()
	end
end

function BuffNodeManager:resetNode(nodeId)
	if self.times[nodeId] == nil then return end

	self.times[nodeId] = {
		triggerType = self.nodes[nodeId].triggerTimes[1],
		value = self.nodes[nodeId].triggerTimes[2]
	}
end

function BuffNodeManager:update(passRound)
	for nodeId, _ in self:ipairsNodes() do
		if self.lifeRounds[nodeId] and self.active[nodeId] then
			self.lifeRounds[nodeId] = self.lifeRounds[nodeId] - passRound
			if self.lifeRounds[nodeId] <= 0 then
				self.buff:over()
				return
			end
		end
	end
end

function BuffNodeManager:ipairsNodes()
	local i = 0
	return function()
		i = i + 1
		return self.nodeIds[i], self.nodes[self.nodeIds[i]]
	end
end

function BuffNodeManager:isNoDeathTrigger()
	return not self.hasDeathTriggerNode
end

-- function BuffNodeManager:isOnBuffCreateInNode0()
-- 	if not self.nodes[0] then return false end
-- 	return self.nodes[0].triggerPoint == battle.BuffTriggerPoint.onBuffCreate
-- end
-- nodeId == 0 指自身的触发逻辑
function BuffNodeManager:isNode0TriggerPoint(triggerPoint)
	if not self.nodes[0] then return false end
	return self.nodes[0].triggerPoint == triggerPoint
end

function BuffNodeManager:isTriggerPointExist(triggerPoint)
	return self.points[triggerPoint] ~= nil
end

-- @return map-style table or nil
local EmptyTable = setmetatable({}, {
	__newindex = function()
		error("EmptyTable readonly")
	end,
})
function BuffNodeManager:getExtraAttack(triggerPoint)
	if self.extraAttack[triggerPoint] == nil then
		local t = {}
		self.extraAttack[triggerPoint] = t

		-- 额外回合类型
		-- (不填默认和1相同) 1.额外行动回合不触发 2.都会触发 3.只在额外行动回合触发
		self:visitNodeByPoint(triggerPoint, function(nodeId, node)
			local v = node.extraAttackTrigger
			if v then
				t[v] = true
			end
		end)
	end

	return self.extraAttack[triggerPoint] or EmptyTable
end