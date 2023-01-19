--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2019 TianJi Information Technology Inc.
--
-- 实现effect相关功能
--


-- 不排队，针对无需序列化的特效
-- 暂时没有重名被覆盖的需求
-- 暂时还没有出现需要自己手动cancel取消动画的
function BattleView:onEventEffect(id, typ, args)
	-- sprite is BattleSprite
	local sprite
	if id then
		id = tostring(id)
		sprite = self:onViewProxyCall("getSceneObj", id)
	end

	local view = sprite or self
	local target = sprite or view
	local effect = newEventEffect(typ, view, args, target)
	return self.effectManager:addAndPlay(nil, effect)
end

-- 排队，针对需要序列化的特效，作用在自身BattleView上
function BattleView:onEventEffectQueue(type, args)
	local target = self
	local effect = newEventEffect(type, self, args, target)
	return self.effectManager:queueAppend(effect)
end

function BattleView:onEventEffectQueueFront(type, args)
	local target = self
	local effect = newEventEffect(type, self, args, target)
	return self.effectManager:queuePrepend(effect)
end


-- 排队，针对需要序列化的特效，作用在view上
-- 战斗中表现大部分需要序列化，且需要判定播放完成后才进入下一回合
function BattleView:onEventEffectQueueFor(view, type, args)
	local target = view
	local effect = newEventEffect(type, view, args, target)
	return self.effectManager:queueAppend(effect)
end

-- function BattleView:onEventEffectQueueInsretCur(view, type, args)
-- 	local target = view
-- 	local effect = newEventEffect(type, view, args, target)
-- 	return self.effectManager:queueInsert(1, effect)
-- end


function BattleView:onEventEffectCancel(effect)
	if effect.key then
		self.effectManager:delAndStop(effect.key)
	elseif effect.queID then
		self.effectManager:queueErase(effect.queID)
	end
end


----------------------------------
-- defer
----------------------------------

local globalDeferListKey = 1--"global"
local popDebug = setmetatable({}, {__mode = "k"})

local function deferListKey(skillID, processID, segID)
	local key
	if skillID or processID or segID then
		key = ""
		if skillID then key = key .. string.format("skill_%s|", skillID) end
		if processID then key = key .. string.format("process_%s|", processID) end
		if segID then key = key .. string.format("seg_%s|", segID) end
		key = key .. math.random()
	end
	return key or globalDeferListKey
end

local function getDeferMapKeys(self)
	return tostring(dumps(itertools.keys(self.deferListMap)))
end

-- TODO: 先按原有模式替换，但在curViewEffectPlayFuncsTb处理上是有问题的

-- 收集表现相关的函数, 主要是 和战斗单位相关的表现,
-- like SceneModel:setCurViewEffectPlayFuncsTb
function BattleView:pushDeferList(skillID, processID, segID)
	local key = deferListKey(skillID, processID, segID)
	local list = CVector.new()
	if key == globalDeferListKey then
		self.deferListMap:push_front(list)
	else
		self.deferListMap:push_back(list)
	end

	self.curDeferList = list


	-- if STACK_MODE then
	-- 	return key
	-- end

	-- if assertInWindows(not self.deferListMap[key], "deferListMap[%s] not empty, overlap it?!", key) then
	-- 	return
	-- end

	-- local list = {}
	-- self.deferListMap[key] = list
	-- self.curDeferList = list
	-- print('!!! pushDeferList', key,list,self.deferListMap:size(), getDeferMapKeys(self))
	return key
end

-- 复制一份当前的表现内容,发给对应的表现目标去存储,等待播放时播放
-- 实际上在使用技能时是发给 技能的使用者,由它去按每个小段去调用这些表现
-- like SceneModel:cloneNowPlayFuncs
function BattleView:popDeferList(key)
	key = key or globalDeferListKey
	local list

	if self.deferListMap:empty() then
		errorInWindows("deferListMap is empty key?!", key)
		return
	end
	-- if STACK_MODE then
	-- 	list = self.deferListMap:pop_back()
	-- 	self.curDeferList = self.deferListMap:back()
	-- 	-- print(string.format("popDeferList key:%s, deferListSize:%s, deferMapSize:%s",key,list:size(),self.deferListMap:size()))
	-- else
	-- 	if assertInWindows(list, "deferListMap[%s] is nil?!", key) then
	-- 		return
	-- 	end
	-- 	self.deferListMap[key] = nil
	-- 	-- back to global list
	-- 	self.curDeferList = self.deferListMap[globalDeferListKey]
	-- end


	-- 存在直接调用全局表现,则从前面弹出
	if key == globalDeferListKey then
		-- TODO: check self.disposeDatasOnSkillEnd['skillEndRecoverMp']
		-- printWarnStack("pop global list")
		list = self.deferListMap:pop_front()
		self:pushDeferList() -- global
	else
		list = self.deferListMap:pop_back()
		self.curDeferList = self.deferListMap:back()
	end

	-- print('!!! popDeferList', key, list, self.deferListMap:size(), getDeferMapKeys(self))

	if device.platform == "windows" then
		popDebug[list] = debug.traceback()
	end
	return list
end

-- like SceneModel:insertPlayFunc
function BattleView:addCallbackToCurDeferList(f,tag)
	if self.curDeferList == nil then
		assertInWindows(self.curDeferList, "curDeferList is nil?! %s", getDeferMapKeys(self))
		return
	end

	self.curDeferList:push_back({func = f,tag = tag or battle.FilterDeferListTag.none})
	-- table.insert(self.curDeferList, {func = f,tag = tag or battle.FilterDeferListTag.none})
end

-- 对于像是回合开始回合结束类的,不需要做延迟播放处理,可以直接将动画播放的函数发到显示队列中
-- like SceneModel:pushCurPlayFuncsToQueue
function BattleView:flushCurDeferList()
	if self.curDeferList == nil then
		assertInWindows(self.curDeferList, "curDeferList is nil?! %s", getDeferMapKeys(self))
		return
	end

	-- run current list
	local key
	local list = self.curDeferList
	self.curDeferList = nil

	for k,l in self.deferListMap:ipairs() do
		-- print("!!! flushCurDeferList",k,list,l)
		if list == l then
			self.deferListMap:erase(k)
			if k == globalDeferListKey then
				self:pushDeferList() -- global
			else
				self.curDeferList = self.deferListMap:back()
			end
			break
		end
	end

	-- list = self:popDeferList()

	-- for k, l in pairs(self.deferListMap) do
	-- 	if list == l then
	-- 		key = k
	-- 		self.deferListMap[k] = nil
	-- 		if k == globalDeferListKey then
	-- 			self:pushDeferList() -- global
	-- 		end
	-- 		break
	-- 	end
	-- end

	-- print('!!! flushCurDeferList', key, list, getDeferMapKeys(self))
	self:runDeferToQueue(list)
end

-- 这里和原始的不同，原始的会丢掉一些队列，这里先全部显示
-- 正常的应该只有global队列
function BattleView:flushAllDeferList()
	local list = self.deferListMap[globalDeferListKey]

	while not self.deferListMap:empty() do
		list = self.deferListMap:pop_front()
		if not list:empty() then
			self:runDeferToQueue(list)
		end
	end
	--  print("flushAllDeferList clear self.deferListMap")
	-- self.deferListMap:clear()

	self:pushDeferList()
	return

	-- if list then
	-- 	self:runDeferToQueue(list)

	-- 	local newList = {}
	-- 	self.deferListMap[globalDeferListKey] = newList
	-- 	if self.curDeferList == list then
	-- 		self.curDeferList = newList
	-- 	end
	-- end

	-- -- run all list
	-- if next(self.deferListMap) then
	-- 	for k, list in pairs(self.deferListMap) do
	-- 		if table.length(list) > 0 then
	-- 			printWarn("deferListMap[%s] defer %d effects in flush", k, table.length(list))
	-- 			self:runDeferToQueue(list)
	-- 		end
	-- 	end
	-- end
	-- self.deferListMap = {}
	-- self.curDeferList = nil
	-- self:pushDeferList() -- global

	-- print_r(popDebug)
end

function BattleView:runDeferToQueue(list)
	if not list then return end

	for i, f in list:ipairs() do
		if self:filterTagCheck(f.tag) then
			self:onEventEffectQueue('callback', {func = f.func, cleanTag = f.tag})
		end
	end
	popDebug[list] = nil
	self.filterMap = {}

	-- for i, f in ipairs(list) do
	-- 	if table.length(self.filterMap) == 0 or (table.length(self.filterMap) > 0
	-- 		and self.filterMap[f.tag]) then
	-- 		self:onEventEffectQueue('callback', {func = f.func})
	-- 	end
	-- end
	-- popDebug[list] = nil
	-- self.filterMap = {}
end

function BattleView:runDeferToQueueFront(list)
	if not list then return end

	while list:size() > 0 do
		local f = list:pop_back()

		if self:filterTagCheck(f.tag) then
			self:onEventEffectQueueFront('callback', {func = f.func, cleanTag = f.tag})
		end
	end
	popDebug[list] = nil
	self.filterMap = {}
end

-- 用来执行表现函数的辅助函数
-- 因为各子界面中不一定有具体的执行者, 所以通过这个辅助函数来查找对应的view后去执行相关表现
function BattleView:runDefer(list)
	if not list then return end

	for i, f in list:ipairs() do
		if self:filterTagCheck(f.tag) then
			-- 使用的是无序化的，且callback无需target
			self:onEventEffect(nil, 'callback', {func = f.func})
		end
	end
	popDebug[list] = nil
	self.filterMap = {}


	-- for i, f in ipairs(list) do
	-- 	if table.length(self.filterMap) == 0 or (table.length(self.filterMap) > 0
	-- 		and self.filterMap[f.tag]) then
	-- 		-- 使用的是无序化的，且callback无需target
	-- 		self:onEventEffect(nil, 'callback', {func = f.func})
	-- 	end
	-- end
	-- popDebug[list] = nil
	-- self.filterMap = {}
end

function BattleView:filterTagCheck(tag)
	return table.length(self.filterMap) == 0 or (table.length(self.filterMap) > 0
		and self.filterMap[tag])
end

-- 过滤执行表现
function BattleView:filter(tag)
	self.filterMap[tag] = true
	return self
end

function BattleView:setEffectDebugEnabled(flag)
	return BattleSprite.setEffectDebugEnabled(self, flag)
end

function BattleView:setEffectDebugBreakpoint(cb)
	self.effectManager:resume()
	if cb == nil then
		self.effectManager:setEffectPlayCallback(nil)
		return
	end

	self.effectManager:setEffectPlayCallback(function(...)
		if cb(...) then
			self.effectManager:resume()
		else
			self.effectManager:pause()
		end
	end)
end