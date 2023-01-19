--
-- 战斗中事件触发的效果的处理
--


--
-- EventEffect
--

local EventEffect = class('EventEffect')
battleEffect.EventEffect = EventEffect

-- @param: view 特效挂载的CViewBase，nil为Root
-- @param: target 特效挂载的cc.Node，nil为Root.raw
-- @param: args
--		delay 延迟时间
--		lifetime 生存时间
function EventEffect:ctor(view, args, target)
	self.key = nil -- given by addAndPlay
	self.queID = nil -- given by queueAppend
	self.args = args
	self.playOver = false
	self.delay = args and args.delay or 0

	self.tick = nil
	self.lifetime = args and args.lifetime
	self.view = view or gRootViewProxy:raw()
	self.target = target or self.view
	self.zOrder = args and args.zOrder or battle.EffectZOrder.none

	if device.platform == "windows" then
		self.traceback = debug.traceback()
	end

	if args then
		-- compatible with csv proxytable
		if args.delay then args.delay = nil end
		if args.lifetime then args.lifetime = nil end
	end
end

function EventEffect:play()
	if self.delay == 0 then
		self.tick = 0
		return self:onPlay()
	end
end

function EventEffect:onPlay()
end

function EventEffect:stop()
	if not self.playOver then
		self.playOver = true
		return self:onStop()
	end
end

-- @comment like 'stop', but not call 'onStop'
function EventEffect:free()
	self.playOver = true
    self:onFree()
end

function EventEffect:onFree()
end

function EventEffect:onStop()
end

function EventEffect:isStop()
	return self.playOver
end

function EventEffect:update(delta)
	if self.delay > 0 then
		self.delay = self.delay - delta
		if self.delay > 0 then
			return
		end
		delta = -self.delay
	end

	if self.tick == nil then
		self.tick = 0
		self:onPlay()
		if not self.onUpdate then
			return
		end
	end
	self.tick = self.tick + delta
	if self.lifetime and self.lifetime <= self.tick then
		delta = delta - (self.tick - self.lifetime)
		self:onUpdate(delta)
		return self:stop()
	end
	return self:onUpdate(delta)
end

function EventEffect:canUpdate()
	return (not self.playOver) and (self.onUpdate or self.delay > 0)
end

function EventEffect:debugString()
	return tostring(self)
end


--
-- OnceEventEffect
--
-- no onUpdate, no onStop
-- just onPlay with delay
--

local OnceEventEffect = class('OnceEventEffect', EventEffect)
battleEffect.OnceEventEffect = OnceEventEffect

function OnceEventEffect:play()
	if self.delay == 0 then
		self:onPlay()
		return self:free()
	end
end

function OnceEventEffect:update(delta)
	self.delay = self.delay - delta
	if self.delay > 0 then
		return
	end

	self:onPlay()
	return self:free()
end


--
-- Manager
--
-- 生命周期管理
--

local Manager = class('Manager')
battleEffect.Manager = Manager

function Manager:ctor(key)
	self.key = key
	self.effects = {} -- all except stopped
	self.updEffects = {} -- need update
	self.queHeadID = 1
	self.queTailID = 0
	self.queEffects = {} -- queued, play one by one
	self.keyCounter = 1 -- effect auto key
	self.running = true
end

function Manager:addAndPlay(key, effect)
	if key == nil then
		key = self.keyCounter
		self.keyCounter = self.keyCounter + 1
	end

	effect:play()
	if not effect:isStop() then
		-- its need manage
		self.effects[key] = effect
		effect.key = key
		-- its need update
		if effect:canUpdate() then
			self.updEffects[key] = effect
		end
	end

	gRootViewProxy:notify("effectUpdated")
	return effect
end

function Manager:delAndStop(key)
	local effect = self.effects[key]
	if effect then
		effect:stop()
		self.effects[key] = nil
		self.updEffects[key] = nil
	end

	gRootViewProxy:notify("effectUpdated")
end

function Manager:queueAppend(effect)
	self.queTailID = self.queTailID + 1
	self.queEffects[self.queTailID] = effect
	effect.queID = self.queTailID

	gRootViewProxy:notify("effectUpdated")
	return effect
end

-- 前插effect需要判断当前effect有没有在播放？
function Manager:queuePrepend(effect)
	if not effect:isStop() then
		return self:queueInsert(1, effect)
	end
	return self:queueInsert(0, effect)
end

-- offset 向右偏差 self.queHeadID -> self.queTailID
function Manager:queueInsert(offset, effect)
	for i = self.queTailID, self.queHeadID + offset , -1 do
		self.queEffects[i].queID = i + 1
		self.queEffects[i + 1] = self.queEffects[i]
	end

	self.queTailID = self.queTailID + 1
	self.queEffects[self.queHeadID+offset] = effect
	effect.queID = self.queHeadID+offset

	gRootViewProxy:notify("effectUpdated")
	return effect
end

function Manager:queueClear()
	for id, effect in pairs(self.queEffects) do
		effect:stop()
	end
	self.queHeadID = 1
	self.queTailID = 0
	self.queEffects = {}

	gRootViewProxy:notify("effectUpdated")
end

function Manager:queueErase(id)
	local effect = self.queEffects[id]
	if effect then
		if id == self.queHeadID then
			effect:stop()
		else
			effect:free()
		end
	end

	gRootViewProxy:notify("effectUpdated")
end

function Manager:queueSize()
	return self.queTailID - self.queHeadID + 1
end

function Manager:queueInfo()
	local head, ret = self.queHeadID, {}
	while head <= self.queTailID do
		local effect = self.queEffects[head]
		table.insert(ret, string.format("%d. %s", head, effect:debugString()))
		head = head + 1
	end
	return ret
end

function Manager:update(delta)
	if not self.running then return false end

	local updated = false
	for key, effect in pairs(self.updEffects) do
		updated = true
		effect:update(delta)
		if not effect:canUpdate() then
			self.updEffects[key] = nil
			if effect:isStop() then
				self.effects[key] = nil
			end
		end
	end
	local updatedFirst = false
	while self.running and self.queHeadID <= self.queTailID do
		updated = true
		local effect = self.queEffects[self.queHeadID]
		if effect:isStop() then
			log.effect.stop(self.key, tostring(effect), self.queHeadID, '/', self.queTailID)
			self.queEffects[self.queHeadID] = nil
			self.queHeadID = self.queHeadID + 1
			if self.queHeadID <= self.queTailID then
				effect = self:getHeadEffect()
				-- 队列中存在已经stop的effect http://172.81.227.66:1104/crashinfo?_id=9337&type=1
				if not effect:isStop() then
					effect:play()
					if self.playCallback then
						self.playCallback(self, self.queHeadID, effect)
					end
				end
			end
		else
			-- stop when first no-stop effect
			if updatedFirst then
				break
			end

			effect:update(delta)
			updatedFirst = true
		end
	end
	return updated
end

function Manager:getHeadEffect()
	if (self.queTailID - self.queHeadID) >= 1 and self.queEffects[self.queHeadID].zOrder > self.queEffects[self.queHeadID + 1].zOrder
	or self.queEffects[self.queHeadID].zOrder == battle.EffectZOrder.dead then
		for i=self.queTailID,self.queHeadID + 1,-1 do
			if self.queEffects[i-1].zOrder > self.queEffects[i].zOrder then
				self:exchangeEffect(i-1,i)
			end
		end
	end
	-- print(string.format("!!!!!!!!!!!!! getHeadEffect queID:%s ,zOrder:%s Head:%s Tail:%s",self.queEffects[self.queHeadID].queID,self.queEffects[self.queHeadID].zOrder,self.queHeadID,self.queTailID),self.queEffects[self.queHeadID])
	return self.queEffects[self.queHeadID]
end

function Manager:exchangeEffect(lef,rig)
	self.queEffects[lef].queID,self.queEffects[rig].queID = self.queEffects[rig].queID,self.queEffects[lef].queID
	self.queEffects[lef],self.queEffects[rig] = self.queEffects[rig],self.queEffects[lef]
end

function Manager:clear()
	self:queueClear()
	for key, effect in pairs(self.effects) do
		effect:stop()
	end
	self.effects = {}
	self.updEffects = {}
end

function Manager:resume()
	self.running = true
end

function Manager:pause()
	self.running = false
end

function Manager:setEffectPlayCallback(f)
	self.playCallback = f
end

function Manager:passOneWaveClear()
	for id, effect in pairs(self.queEffects) do
		if not (effect.args and effect.args.cleanTag and effect.args.cleanTag == battle.FilterDeferListTag.cantClean) then
			self:queueErase(id)
		end
	end

	for key, effect in pairs(self.effects) do
		if not (effect.args and effect.args.cleanTag and effect.args.cleanTag == battle.FilterDeferListTag.cantClean) then
			self:delAndStop(key)
		end
	end
end