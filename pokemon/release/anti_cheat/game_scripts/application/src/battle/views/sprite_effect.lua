--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2019 TianJi Information Technology Inc.
--
-- 与BattleView类似
-- 实现effect相关功能
--

local function effectEvents(processID, cfg)
	if cfg == nil then return {} end
	local delay = cfg.delay -- delay是通用配置
	local ret = {}
	for key, fields in pairs(battle.EffectEventArgFields) do
		if cfg[fields[1]] then
			local args = {delay=delay, processID=processID}
			for _, field in ipairs(fields) do
				args[field] = csvClone(cfg[field])
			end
			ret[key] = args
		end
	end
	return ret
end

local function checkEventsCanPlay(id,tab,typ)
	if not tab then return true end
	if not tab[id] then return true end
	if not tab[id][typ] then return true end
	return false
end

local function checkEffectEventCheat(effectID)
	if ANTI_AGENT then return end

	checkSpecificCsvCheat("effect_event", itertools.ivalues({effectID}))
end

local function addEffectEvents(self, eventID)
	local info = self:popEffectInfo(eventID)
	-- 1 是特殊eventID，会有重复effectID
	if eventID == 1 and info == nil then return end

	local effectID, processID
	if info then
		effectID, processID = info.effectID, info.processID
	else
		-- for otherEventIDs, no process, only effect
		effectID = gEffectByEventCsv[eventID]
	end

	if self:popIgnoreEffect(processID,eventID) then return end

	local effectCfg = csv.effect_event[effectID]
	local processArgs = self:getProcessArgs(processID)
	logf.battle.sprite.event("effect_event: eventID= %s, effectID= %s, processID= %s", eventID, effectID, processID)
	if effectCfg then
		checkEffectEventCheat(effectID)

		log.battle.sprite.event(self.unitID, processArgs)
		-- 大招跳过后,这部分会直接跳过,每一个伤害段会被执行一次
		if not self.battleView:getEffectEventEnable() then
			self:dealJumpSkillEffect(processArgs)
			return
		end
		-- 特效加给其它单位
		-- if effectCfg.jumpFlag and userDefault.getForeverLocalKey("mainSkillPass", false) then
		-- 	self:onCleanEffectCache()
		-- 	self.battleView:closeEffectEventEnable()
		-- 	return
		-- end
		if processArgs then
			-- print_r_deep(processArgs,2)
			local battleView = self.battleView
			local events = effectEvents(processID, effectCfg)
			---- 或许这里用完了得清理下,会不会有连续的重复动作出现,或者技能中的多个过程段有条件的选择使用时(可能没这种需求)
			---- 不能在这里清理,策划可能会在多个effect_event的表现段配置中, 都使用了同一个过程段的目标伤害数据, 擦
			---- self.effectProcessArgs[effectCfg.processID] = nil
			for type, oneEventArgs in pairs(events) do
				for i, obj in ipairs(processArgs.viewTargets) do
					local args = clone(oneEventArgs)
					args.effectID = effectID
					args.processArgs = processArgs
					if not args.targets then
						args.targets = {}
					end
					table.insert(args.targets, battleView:onViewProxyCall('getSceneObj', tostring(obj)))
					if type == "follow" then
						args.index = i
						args.faceTo = obj.faceTo
					else
						args.faceTo = self.faceTo
					end
					args.fromSprite = self
					if type == "music" then
						type = "sound"
					end
					if checkEventsCanPlay(obj.id,processArgs.ignoreEvenet,type) then
						table.insert(battleView.effectJumpCache,battleView:onEventEffect(obj, type, args))
					else
						self:dealCantPlayEffect(processArgs, obj)
					end
				end
			end
			if processArgs.otherTargets and effectCfg.onlyTargetShow then
				for seat, obj in pairs(processArgs.otherTargets) do
					table.insert(battleView.effectJumpCache,battleView:onEventEffect(obj, 'show', {show={{hide=true}}}))
				end
			end
			if processArgs.deferList and processArgs.deferList[processArgs.process.id] then
				table.insert(battleView.effectJumpCache,battleView:onEventEffect(obj, 'callback', {func = function()
					battleView:runDefer(processArgs.deferList[processArgs.process.id])
				end,delay = 0}))
			end
		-- 没有targets就是给id自身加效果
		else
			self:onAddEffectsByCsv(processID, effectID, effectCfg)
		end
		-- 增加一个补充字段 otherEventIDs
		if effectCfg.otherEventIDs then
			for _, eventID in ipairs(effectCfg.otherEventIDs) do
				addEffectEvents(self, eventID)
			end
		end
	else
		-- eventID=1 是程序特殊模拟发送的
		if eventID ~= 1 then
			printWarn("no effect_event eventID= %s, effectID= %s, processID= %s", eventID, effectID, processID)
		end
	end
end

local function revertScaleWhenAniOver(self, aniName)
	local scale = self.spineActionScales[aniName]
	if scale and self.spinePrevAction == aniName then
		self:setScaleX(self._scaleX, true)
		self:setScaleY(self._scaleY, true)
		self.spinePrevAction = nil
	end
end

function BattleSprite:getProcessArgs(processID)
	-- print("getProcessArgs", self.model.seat, processID)
	return self.effectProcessArgs[processID]
end

function BattleSprite:dealJumpSkillEffect(processArgs)
	if processArgs then
		-- print("not self.battleView:getEffectEventEnable()")
		for _, obj in ipairs(processArgs.viewTargets) do
			-- SegShow deferList
			if processArgs.values then
				local valueArgs = processArgs.values[obj.id]
				if valueArgs then
					for k,v in ipairs(valueArgs) do
						self.battleView:filter(battle.FilterDeferListTag.cantJump)
							:runDefer(v and v.deferList)
					end
				end
			end
		end

		if processArgs.deferList and processArgs.deferList[processArgs.process.id] then
			table.insert(self.battleView.effectJumpCache,self.battleView:onEventEffect(tostring(obj), 'callback', {func = function()
				self.battleView:filter(battle.FilterDeferListTag.cantJump)
					:runDefer(processArgs.deferList[processArgs.process.id])
			end,delay = 0}))
		end
	end
end

--播放被屏蔽的event里面不能跳过的动画
function BattleSprite:dealCantPlayEffect(processArgs, obj)
	if processArgs and processArgs.values then
		local valueArgs = processArgs.values[obj.id]
		if not valueArgs then return end
		for _, data in ipairs(valueArgs) do
			table.insert(self.battleView.effectJumpCache,self.battleView:onEventEffect(tostring(obj), 'callback', {func = function()
				self.battleView:filter(battle.FilterDeferListTag.cantJump)
					:runDefer(data.deferList)
			end,delay = 0}))
		end
	end
end

local respondEvent = {
	[sp.EventType.ANIMATION_EVENT] = function(self, eventArgs)
		local eventID = eventArgs.eventData.intValue
		log.battle.sprite.event(' ---- 触发 动画配置的事件参数 eventType= eventID=', self.id, event, eventID)
		-- print_r_deep(eventArgs, 2)
		addEffectEvents(self, eventID)
	end,
	[sp.EventType.ANIMATION_START] = function(self, eventArgs)
		-- 存在 START 1 INTERRUPT 1 START 2 END 1 的顺序
		local aniName = eventArgs.animation
		local scale = self.spineActionScales[aniName]
		if scale then
			-- TODO: 如果event effect再过程中更改scale，那这里的缩放将失效
			self.sprite:setScaleX(scale)
			self.sprite:setScaleY(scale)
			self.spinePrevAction = aniName
		end
		-- 1 特殊模拟的event id
		performWithDelay(self, function()
			addEffectEvents(self, 1)
		end, 0)
	end,
	[sp.EventType.ANIMATION_INTERRUPT] = function(self, eventArgs)
		return revertScaleWhenAniOver(self, eventArgs.animation)
	end,
	[sp.EventType.ANIMATION_END] = function(self, eventArgs)
		return revertScaleWhenAniOver(self, eventArgs.animation)
	end,
	[sp.EventType.ANIMATION_COMPLETE] = function(self, eventArgs)
			-- eventArgs
		-- +animation [string run_loop]
		-- +type [string complete]
		-- +trackIndex [number 0]
		-- +loopCount [number 2]

		-- loop动作不实现complete回调
		if battle.LoopActionMap[eventArgs.animation] then
			return
		end

		-- TODO: loop or once callback?
		if self.actionCompleteCallback then
			self.actionCompleteCallback(eventArgs.animation, eventArgs.loopCount)
			self.actionCompleteCallback = nil
		end
	end,
}

function BattleSprite:onSpriteEvent(event, eventArgs)
	respondEvent[event](self, eventArgs)
end
-- 由于spine内部事件不能保证有序 所以只能保证在同eventID的情况先进先出
function BattleSprite:popEffectInfo(eventID)
	local usedView = self:getRealUseView()
	local ret = self.spineEventMap[usedView and usedView.actionState or self.actionState]
	if ret and #ret > 0 then
		for k,v in ipairs(ret) do
            if v.eventID == eventID then
				-- print("popEffectInfo", self.model.seat, eventID)
                return table.remove(ret, k)
            end
        end
	end
	return
end

function BattleSprite:saveEffectInfo(action, processID, effectID)
	local effectCfg = csv.effect_event[effectID]
	if not effectCfg or not effectCfg.eventID then return end
	self.spineEventMap[action] = self.spineEventMap[action] or {}
	-- print("saveEffectInfo", self.model.seat, action, processID, effectID, effectCfg.eventID)
	table.insert(self.spineEventMap[action],{
		processID = processID,
		effectID = effectID,
		eventID = effectCfg.eventID,
	})
end
-- 有些表现不想要被播放
-- 比如盖欧卡的大招下的一些多余的eventID 不想要产生实际的效果
function BattleSprite:saveIgnoreEffect(processID, effectID)
	local effectCfg = csv.effect_event[effectID]
	if not effectCfg or not effectCfg.eventID then return end
	-- print("saveIgnoreEffect",effectID,processID)
	self.ignoreEffectMap = self.ignoreEffectMap or {}
	table.insert(self.ignoreEffectMap,{
		processID = processID,
		effectID = effectID,
		eventID = effectCfg.eventID,
	})
end
-- 多段会存在共享一个eventID 即连续播放一个动作
-- 所以通过processID去区分
function BattleSprite:popIgnoreEffect(processID,eventID)
	if not self.ignoreEffectMap then return false end
	-- print("popIgnoreEffect",eventID,processID)
	for k,v in ipairs(self.ignoreEffectMap) do
        -- eventID 必须相同
        -- processID 如果是同动作重复播放 需要甄别
        -- 不同动作播放时如果需要忽视则processID不存在
		if v.eventID == eventID and (v.processID == processID or not processID) then
			table.remove(self.ignoreEffectMap, k)
			return true
		end
	end
	return false
end

function BattleSprite:onProcessArgs(processID, args)
	if not args.viewTargets then
		args.viewTargets = args.targets
	end
	for _, obj in ipairs(args.targets) do
		local protectData = obj:getEventByKey(battle.ExRecordEvent.protectTarget)
		if protectData and protectData.showProcess then
			local protectObj = protectData.obj
			if not itertools.include(args.viewTargets,protectObj) then
				table.insert(args.viewTargets,protectObj)
				if args.values and not args.values[protectObj.id] and args.values[obj.id] then
					args.values[protectObj.id] = clone(args.values[obj.id])
					for k,v in pairs(args.values[protectObj.id]) do
						v.value = battleEasy.valueTypeTable()
					end
				end
			end
		end
	end

	-- print("onProcessArgs", self.model.seat, processID)
	self.effectProcessArgs[processID] = args
end

function BattleSprite:onProcessDel(processID)
	-- print("onProcessDel", self.model.seat, processID, dumps(self.spineEventMap))
	self.effectProcessArgs[processID] = nil
end

function BattleSprite:setSkillJumpSwitch(switch)
	self.skillJumpSwitchOnce = switch
end

-- 不排队，针对无需序列化的特效
-- 与CBattle_V的不同在于，BattleSprite被移除后，相关特效也结束
-- 暂时没有重名被覆盖的需求
-- 暂时还没有出现需要自己手动cancel取消动画的
function BattleSprite:onEventEffect(type, args)
	-- local target = self.sprite -- root -> sprite
	local target = args.target or self -- TODO: bad smell, args.target was ambiguity
	local effect = newEventEffect(type, self, args, target)
	return self.effectManager:addAndPlay(nil, effect)
end

-- 排队，针对需要序列化的特效，作用在自身BattleSprite上
function BattleSprite:onEventEffectQueue(type, args)
	local target = self
	local effect = newEventEffect(type, self, args, target)
	return self.effectManager:queueAppend(effect)
end

function BattleSprite:onEventEffectCancel(effect)
	if effect.key then
		self.effectManager:delAndStop(effect.key)
	elseif effect.queID then
		self.effectManager:queueErase(effect.queID)
	end
end

function BattleSprite:onCleanEffectCache()
	local curActionState = self.actionState
	for action,actionTab in pairs(self.spineEventMap) do
		self.actionState = action
        while (next(actionTab)) do
            local _,data = next(actionTab)
            addEffectEvents(self, data.eventID)
        end
	end
	self.actionState = curActionState

	for k,v in ipairs(self.battleView.effectJumpCache) do
		self.battleView:onEventEffectCancel(v)
	end
	self.battleView.effectJumpCache = {}
	local units = self.battleView:onViewProxyCall("getSceneObjs")
	for k1,v1 in pairs(units) do
        v1.spineEventMap = {} -- 清空其他save表现
		for k,v in ipairs(v1.effectJumpCache) do
			v1:onEventEffectCancel(v)
		end
	end

	self.effectJumpCache = {}
	self:onUltJumpEnd()
end

function BattleSprite:globalEventEffectQueue(type, args)
	return self.battleView:onEventEffectQueueFor(self, type, args)
end

-- noQueue-默认是使用序列化的,填写该值时,则不使用序列化的了
function BattleSprite:onAddEventEffect(type, args, noQueue)
	if not noQueue then
		return self:globalEventEffectQueue(type, args)
	else
		return self:onEventEffect(type, args)
	end
end

-- for model easy
function BattleSprite:onAddEffectsByCsv(processID, effectID, effectCfg, selects)
	local target = self
	local events = effectEvents(processID, effectCfg)
	for type, args in pairs(events) do
		if selects == nil or selects[type] then
			args.effectID = effectID
			args.faceTo = self.faceTo
			args.onComplete = function() end
			local effect = newEventEffect(type, self, args, target)
			table.insert(self.effectJumpCache,self.effectManager:addAndPlay(nil, effect))
		end
	end
end

local getEffectPositionByPos = {
	[0] = function(sprite, offsetPos)
		-- 默认特效是添加在角色的“yinying”的骨骼位置！
		local pos = sprite.startYinyingPos
		local yinYingPos = cc.p(pos.x * sprite:getScaleX(), pos.y)
		return cc.pAdd(yinYingPos, offsetPos)
	end,
	[1] = function(sprite, offsetPos)
		local headPos = sprite.unitCfg.everyPos.headPos
		return cc.pAdd(headPos, offsetPos)
	end,
	[2] = function(sprite, offsetPos)
		local hitPos = sprite.unitCfg.everyPos.hitPos -- 这里不用乘scale了，因为root因为放大计算进去了
		return cc.pAdd(hitPos, offsetPos)
	end,
	[3] = function(sprite, offsetPos) -- 己方阵营中心
		local cx = (battle.StandingPos[2].x + battle.StandingPos[5].x)/2
		cx = (sprite.model.force == 1) and cx or display.width - cx
		return cc.pAdd(cc.p(cx, battle.StandingPos[2].y), offsetPos)
	end,
	[4] = function(sprite, offsetPos) --  敌方阵营中心
		local cx = (battle.StandingPos[2].x + battle.StandingPos[5].x)/2
		cx = (sprite.model.force == 1) and display.width - cx or cx
		return cc.pAdd(cc.p(cx, battle.StandingPos[2].y), offsetPos)
	end,
	[5] = function(sprite, offsetPos) --  场景中心
		return cc.pAdd(cc.p(battle.StandingPos[13].x, battle.StandingPos[2].y), offsetPos)
	end,
	[6] = function(sprite, offsetPos)	-- 不跟随精灵
		local heroPos = {}
		heroPos.x,heroPos.y = sprite:xy()
		return cc.pAdd(heroPos, offsetPos)
	end,
}
-- 添加buff特效
function BattleSprite:addBuffEffect(effectRes, pos, deep, cfgOffsetPos, aniName, showEffect, selfTurn, effectAniType, overlayType, assignLayer)
	-- 这里暂时没有缓存,等后面 cache 功能完善后,加入到cache中
	if not effectRes or effectRes == "" then return end
	local scaleNum = 2

	local effectMap, effectRef = self:getViewTb(pos)
	local effectKey = self:getBuffEffectKey(effectRes, aniName, effectAniType)
	local sprite = effectMap[effectKey]

	if sprite and (overlayType == battle.BuffOverlayType.Coexist or overlayType == battle.BuffOverlayType.Overlay or overlayType == battle.BuffOverlayType.OverlayDrop) then
		-- 不是默认类型或者叠加buff后续直接播放动画
		return sprite:play(aniName)
	end

	effectRef[effectKey] = effectRef[effectKey] or 0
	effectRef[effectKey] = effectRef[effectKey] + 1

	if effectRef[effectKey] <= 0 then
		return
	end

	if not sprite then
		sprite = newCSpriteWithOption(effectRes)
		sprite:scale(scaleNum)
		effectMap[effectKey] = sprite
		if pos >= 3 and pos <= 6 then
			table.insert(self.battleView.buffEffectsToHide,sprite)
		else
			table.insert(self.buffEffectsFollowObjToScale,sprite)
			self:updateBuffeffectsScale()
		end
	end

	sprite.buffUseSameResCount = sprite.buffUseSameResCount or 0	-- 使用相同特效资源的buff,只需要存在一个即可
	sprite.buffUseSameResCount = sprite.buffUseSameResCount + 1
	sprite.showEffect = showEffect
	-- buff的光效特效 先判断循环的
	if sprite:play(aniName) == false then
		sprite:play("effect")
	end

	local layerEffectX, layerEffectY = 0, 0
	if sprite.buffUseSameResCount <= 1 then
		local useLayer = self.battleView:getAssignLayer(assignLayer)
		if useLayer then
			local posZ = deep
			if assignLayer == battle.AssignLayer.gameLayer then
				local lineNum = 10000
				local posIdx = math.floor(deep / lineNum)
				local rate = 1

				if posIdx == 0 then
					posZ = deep / lineNum * (display.height - battle.StandingPos[1].y)
				elseif posIdx == 3 then
					posZ = (deep - lineNum*posIdx) + (display.height - battle.StandingPos[3].y)
				else
					posZ = (deep/lineNum - posIdx)  * (battle.StandingPos[posIdx].y - battle.StandingPos[posIdx + 1].y) + (display.height - battle.StandingPos[posIdx].y)
				end

			end
			useLayer:add(sprite)
			sprite:setLocalZOrder(posZ)
			if pos < 3 then layerEffectX, layerEffectY = self:getCurPos() end
		else
			-- 角色层
			self:add(sprite, deep)
		end
	end

	-- 先添加父物体 再决定位置
	local offsetPos = cc.p(cfgOffsetPos.x - layerEffectX, cfgOffsetPos.y - layerEffectY)
	if self.model.force == 2 then
		offsetPos = cc.p(-offsetPos.x, offsetPos.y)
	end

	local effectPosition = getEffectPositionByPos[pos](self, offsetPos) -- 物体的坐标点

	-- 只在技能attacting期间内showEffect才会生效
	-- 特效没有被隐藏锁住或者配置中配置了显示才显示
	local show = battleEasy.ifElse(self.lockEffectSwitch, true, showEffect)
	if cfgOffsetPos.flip then
		sprite:setScaleX(scaleNum)
	else
		sprite:setScaleX(self.faceTo * scaleNum)
	end
	sprite:setVisible(show)
	sprite:setPosition(effectPosition)

	-- 只有跟随yinying骨骼，才需不断更新位置
	-- TODO: 暂时不跟随骨骼，yinying位置资源有问题
	-- if pos == 0 then
	-- 	local function skelMove()
	-- 		-- local pos = self.sprite:getBonePosition("yinying")
	-- 		-- effectPosition = cc.p(pos.x * self:getScaleX(), pos.y)
	-- 		sprite:setPosition(effectPosition)
	-- 	end
	-- 	self:scheduleUpdate(skelMove)
	-- end
end

function BattleSprite:deleteBuffEffect(effectRes, aniName, pos, effectAniType)

	local effectMap, effectRef = self:getViewTb(pos)
	local effectKey = self:getBuffEffectKey(effectRes, aniName, effectAniType)

	effectRef[effectKey] = effectRef[effectKey] or 0
	effectRef[effectKey] = effectRef[effectKey] - 1

	local sprite = effectMap[effectKey]
	if sprite then
		--这个计数的作用只是标记相同特效资源只添加一次，那么删除这个特效的时候这个计数应该是直接清零而不是减一
        sprite.buffUseSameResCount = sprite.buffUseSameResCount - 1
		if sprite.buffUseSameResCount == 0 then
			effectMap[effectKey] = nil
			if pos >= 3 and pos <= 6 then
				for k,v in ipairs(self.battleView.buffEffectsToHide) do
					if v.spriteID == sprite.spriteID then
						table.remove(self.battleView.buffEffectsToHide,k)
						break
					end
				end
			else
				for k,v in ipairs(self.buffEffectsFollowObjToScale) do
					if v.spriteID == sprite.spriteID then
						table.remove(self.buffEffectsFollowObjToScale,k)
						break
					end
				end
				if not next(self.buffEffectsFollowObjToScale) then
					self:unscheduleUpdate()
				end
			end
		    removeCSprite(sprite)
		end
	end
end
local holderActionMap
--buff作用于持有者的显示效果。目前只有暂停动作一种，后续可能扩展
holderActionMap = {
	pause = {
		onBuff = function(self,isOver)
			if not isOver then
				self:pauseSprite()
			else
				self:resumeSprite()
			end
		end,
	},
	hideOthers = {
		onBuff = function(self,isOver,args)
			self:alterLockEffectRecord(isOver)
		end,
	},
	hide = {
		onBuff = function(self,isOver,args)
			self:onSetSpriteVisible(isOver)
			if isOver then
				self.lifebar:setVisibleEnable(isOver)
				self.lifebar:setVisible(isOver)
			else
				self.lifebar:setVisible(isOver)
				self.lifebar:setVisibleEnable(isOver)
			end
		end,
	},
	hideAdvanced = {
		onBuff = function(self,isOver,args)
			local switch = isOver
			if args ~= nil then
				switch = battleEasy.ifElse(not isOver, args, not args)
			end
			self:onSetSpriteVisible(switch)
			if switch then
				self.lifebar:setVisibleEnable(switch)
				self.lifebar:setVisible(switch)
			else
				self.lifebar:setVisible(switch)
				self.lifebar:setVisibleEnable(switch)
			end
			-- 隐藏buff特效
			self:alterLockEffectRecord(switch)
		end,
	},
	hideSprite = {
		onBuff = function(self,isOver,args)
			self:onSetSpriteVisible(isOver)
		end,
	},
	move = {
		onBuff = function(self,isOver,args)
			local x,y= self:getCurPos()
			local rate = battleEasy.ifElse(isOver,-1,1)
			local force = battleEasy.ifElse(self.force == 1,-1,1)
			local pos = {
				x = battleEasy.ifElse(args.x ,args.x*rate*force + x ,x),
				y = battleEasy.ifElse(args.y ,args.y*rate + y ,y),
			}
			if isOver then
				self:onAddEventEffect('moveTo', {speed=args.speed, a=1000, x=pos.x, y=pos.y, knockUpBack = true})
			else
				self:onAddEventEffect('moveTo', {speed=args.speed, a=1000, x=pos.x, y=pos.y, knockUp = true})
			end
		end,
	},
	opacity = {
		onBuff = function(self,isOver,args)
			local transParency = math.min(math.floor((args or 1) *255),255)

			if isOver then
				self:setSpriteOpacity(255)
			else
				self:setSpriteOpacity(transParency)
			end
		end
	},
	onceEffect = {
		onBuff = function(self,isOver,args)
			local timePos = args.timePos or 0
			local isPlay = isOver and timePos == 1
			isPlay = isPlay or (not isOver and timePos == 0)

			if isPlay then
				self.battleView:onViewProxyCall("onFrameOnceEffect", {
					tostrModel = self.key,
					resPath = args.onceEffectResPath,
					aniName = args.onceEffectAniName or "effect",
					pos = args.onceEffectPos or 0,
					offsetPos = args.onceEffectOffsetPos or {x=0,y=0},
					assignLayer = args.onceEffectAssignLayer or 4,
					wait = args.onceEffectWait or false,
					delay = args.onceEffectDelay or 0
				})
			end
		end
	},
	wait = {
		onBuff = function(self,isOver,args)
			local timePos = args.timePos or 0
			local isPlay = isOver and timePos == 1
			isPlay = isPlay or (not isOver and timePos == 0)

			if isPlay then
				self.battleView:onEventEffectQueueFront('wait', {lifetime = args.lifetime})
			end
		end
	},
	changeImage = {
		onBuff = function(self,isOver,args)
			if isOver then
				self:onSetSpriteVisible(true)
				removeCSprite(self.changeImageSprite)
				self.changeImageSprite = nil
			else
				self:onSetSpriteVisible(false)
				local resetPos = cc.p(self.sprite:getPositionX(),self.sprite:getPositionY())
				if self.changeImageSprite then
					self.changeImageSprite:removeAnimation()
				end
				local unitCfg = csv.unit[args]
				local unitRes = unitCfg.unitRes
				self.changeImageSprite = newCSprite(unitRes)
				self:add(self.changeImageSprite, battle.SpriteLayerZOrder.selfSpr)
				self.changeImageSprite:setPosition(resetPos)
				self.changeImageSprite:play(battle.SpriteActionTable.standby)
				self.changeImageSprite:setScaleX(self.faceTo * unitCfg.scaleX * unitCfg.scale * unitCfg.scaleC)
				self.changeImageSprite:setScaleY(unitCfg.scale * unitCfg.scaleC)
			end
		end
	},
	shader = {
		onBuff = function(self, isOver, args)
			if isOver then
				self.sprite:setGLProgram("normal")
			else
				if args.switch == 4 then
					-- 石化效果
					local brightnessCard = args.extraArgs[1] or {}
					local brightness = brightnessCard[self.cardID] or 0.8 -- 个别sprite亮度特殊处理

					self.sprite:setShihuaShader(brightness)
				else
					self.sprite:setHSLShader(args.extraArgs[1],args.extraArgs[2],args.extraArgs[3],args.extraArgs[4],args.extraArgs[5],args.switch)
				end
			end
		end
	},
	playAni = {
		onBuff = function(self, isOver, args)
			local effectMap, effectRef = self:getViewTb(args.pos)
			local effectKey = self:getBuffEffectKey(args.effectRes, args.aniName, args.effectAniType)
			local sprite = effectMap[effectKey]
			if not sprite then
				return
			end

			local function reset()
				sprite.holderActionVisible = nil
				sprite:setVisible(true)
			end

			if isOver then
				if args.hide then
					reset()
				end
				sprite:play(args.aniName)
			else
				self.battleView:onEventEffect(nil, 'callback', {func = function()
					if args.hide then
						sprite.holderActionVisible = false
						sprite:setVisible(false)
					else
						reset()
					end
					sprite:play(args.newAniName)
				end, delay = args.delay or 0})
			end
		end
	}

}
-- 特效分了两部分:一部分是通用显示的特效: 图标、文字、身上特效等; 另一部分是某些效果函数自带的效果, 如加血时的回血效果等

-- 特效处理  默认每个buff只有一个特效,如果想要播放多个特效,可以通过节点创建子buff来实现,这样可以保持配表字段简洁
-- 如果特效是需要重复播放的,也可重复使用
-- 外部控制的播放特效 (主要是和表现上做同步) skillTimePint:播放特效的时间点, 1-技能前、2-技能后、3-立即

-- 特效通常不需要再精确序列化播放,只要注意控制 技能前 技能后 每回合时等几个特殊时间点即可
-- 部分特殊节点触发的buff,如被击时触发,可能需要另外再做同步表现(segShow中)

local playBuffEffects = {
	iconEffect = function(self, buffArgs)
		local cfg = buffArgs.csvCfg
		if cfg.iconResPath and cfg.iconResPath ~= '' then
			self:onShowBuffIcon(cfg.iconResPath, buffArgs.cfgId, buffArgs.overlayCount)
		end
	end,
	onceEffect = function(self, buffArgs)
		local cfg = buffArgs.csvCfg
		if not buffArgs.isOnceEffectPlayed and cfg.onceEffectResPath and cfg.onceEffectResPath ~= '' then
			self.battleView:onViewProxyCall("onFrameOnceEffect", {
				tostrModel = buffArgs.tostrModel,
				resPath = cfg.onceEffectResPath,
				aniName = cfg.onceEffectAniName,
				pos = cfg.onceEffectPos,
				offsetPos = cfg.onceEffectOffsetPos,
				assignLayer = cfg.onceEffectAssignLayer,
				wait = cfg.onceEffectWait,
				delay = cfg.onceEffectDelay or 0
			})
		end
	end,
	textEffect = function(self, buffArgs)
		local cfg = buffArgs.csvCfg
		if not buffArgs.args.cantShowText then
			if cfg.textResPath and cfg.textResPath ~= '' then
				self.battleView:onEventEffect(nil, 'callback', {func = function()
					self:onShowBuffText(cfg.textResPath)
				end, delay = cfg.onceEffectDelay or 0})
			end
		end
	end,
	mainEffect = function(self, buffArgs)
		local cfg = buffArgs.csvCfg
		if cfg.effectResPath and cfg.effectResPath ~= '' then
			local showPrior = battleEasy.ifElse(cfg.holderActionType.typ and cfg.holderActionType.typ == "hideOthers", true, false)
			local aniName = cfg.effectAniName[buffArgs.aniSelectId]
			local effectShowOnAttack = showPrior or cfg.effectShowOnAttack or false

			-- http://172.81.227.66:1104/crashinfo?_id=9337&type=1 确认报错原因 添加临时日志
			-- local errWave, errRound, errBRound = self.model.scene.play.curWave, self.model.scene.play.curRound, self.model.scene.play.curBattleRound
			self.battleView:onEventEffect(nil, 'callback', {func = function()
				-- if not self or not self.addBuffEffect then
				-- 	errorInWindows("playBuffAniEffect error cfgId:%d resPath:%s wave %s round %s battleRound %s",
				-- 	buffArgs.cfgId, cfg.effectResPath, errWave, errRound, errBRound)
				-- 	return
				-- end
				self:addBuffEffect(cfg.effectResPath, cfg.effectPos, cfg.deepCorrect, cfg.effectOffsetPos,
				aniName, effectShowOnAttack, buffArgs.isSelfTurn, cfg.effectAniChoose.type, cfg.overlayType, cfg.effectAssignLayer)
			end, delay = cfg.effectResDelay or 0})
		end
	end,
	dispelEffect = function(self, buffArgs)
		local cfg = buffArgs.csvCfg
		-- 驱散BUFF
		if buffArgs.dispel then
			self.battleView:onViewProxyCall("onFrameOnceEffect", {
				tostrModel = buffArgs.tostrModel,
				resPath = 'buff/qusan/qusan.skel',
				aniName = "effect",
				pos = 2,
				offsetPos = cfg.onceEffectOffsetPos,
				assignLayer = cfg.onceEffectAssignLayer,
				wait = cfg.onceEffectWait,
				delay = cfg.onceEffectDelay or 0
			})
		end
	end,
	skinEffect = function(self, buffArgs)
		local cfg = buffArgs.csvCfg
		-- 切换皮肤
		if cfg.skin then
			local skinArgs = {buffId = buffArgs.id, isRestore = false, skinName = cfg.skin}
			self:setSkin(skinArgs)
		end
	end,
	holderActionEffect = function(self, buffArgs)
		local cfg = buffArgs.csvCfg
		-- playTriggerPointEffect
		if cfg.holderActionType then
			if cfg.holderActionType.typ then
				self:addBuffHolderAction(buffArgs.id, cfg.holderActionType.typ, cfg.holderActionType.args, cfg.holderActionType.playTime)
			elseif cfg.holderActionType.list then
				local deferKey = self.battleView:pushDeferList(buffArgs.id, "holderActionType")

				for k, v in ipairs(cfg.holderActionType.list) do
					self:addBuffHolderAction(buffArgs.id.."_"..k, v.typ, v.args, v.playType)
				end
				self.battleView:runDeferToQueueFront(self.battleView:popDeferList(deferKey))
			end
		end
	end,
	LinkEffect = function(self, buffArgs)
		local cfg = buffArgs.csvCfg
		if cfg.linkEffect then
			gRootViewProxy:notify('addLinkEffect',
				buffArgs.tostrModel,
				buffArgs.tostrCaster,
				cfg.linkEffect,
				buffArgs.id
			)
		end
	end
}

function BattleSprite:onPlayBuffAniEffect(buffArgs, aniEffects)
	if not buffArgs.csvCfg then return end
	-- 默认全部播放
	if not aniEffects then
		for k, f in pairs(playBuffEffects) do
			f(self, buffArgs)
		end
	else
		for _, v in pairs(aniEffects) do
			playBuffEffects[v](self, buffArgs)
		end
	end
end

-- buff控制单位表现队列
-- playType: nil: 程序控制 1: 排队播放
function BattleSprite:addBuffHolderAction(id, typ, args, playType)
	if not typ then return end
	if not self.buffEffectHolderMap[typ] then
		self.buffEffectHolderMap[typ] = {
			isPlayId = nil,
			datas = CList.new(),
		}
	end

	if playType == 1 then
		battleEasy.deferCallback(function()
			self:onPlayBuffHolderAction(typ, {
				id = id, args = args
			}, false)
		end)
		return
	end

	local ret = self.buffEffectHolderMap[typ]
	local data
	for _,v in ret.datas:pairs() do
		if v.id == id then
			data = v
			break
		end
	end

	if not data then
		data = {
			id = id, args = args,ref = 0,idx = ret.datas.counter + 1
		}
		ret.datas:push_back(data)
	end
	data.args = args
	data.ref = data.ref + 1

	if data.ref > 1 then
		-- 更新一下表现
		self:onPlayBuffHolderAction(typ, data, false)
	elseif data.ref == 0 then
		-- 计数异常，清理buff
		ret.datas:erase(data.idx)
	end
end

function BattleSprite:delBuffHolderAction(id,typ, playType)
	if not typ then return end
	if not self.buffEffectHolderMap[typ] then
		self.buffEffectHolderMap[typ] = {
			isPlayId = nil,
			datas = CList.new(),
		}
	end

	if playType == 1 then return end

	local ret = self.buffEffectHolderMap[typ]
	local data, showEndAction, nextPlayIdx
	for k,v in ret.datas:pairs() do
		if v.id == id then
			data = v
			-- back不一定是正在播放的data,用当前正在播放的id来判断
			showEndAction = ret.isPlayId == id
		elseif v.ref > 0 then
			-- 能够接下来播放的data
			nextPlayIdx = v.idx
		end
	end

	-- 删除表现相关逻辑先被触发
	if not data then
		data = {
			id = id, ref = 0, idx = ret.datas.counter + 1
		}
		ret.datas:push_back(data)
	end

	data.ref = data.ref - 1
	if data.ref ~= 0 then return end

	data = ret.datas:erase(data.idx)
	-- 当现有的effect已经被播放且队列中不存在可播放的effect 播放over的action
	if showEndAction and not playType then
		if not nextPlayIdx then
			self:onPlayBuffHolderAction(typ, data, true)
			ret.isPlayId = nil
		else
			self:onPlayBuffHolderAction(typ, ret.datas:index(nextPlayIdx), false)
		end
	end
end

function BattleSprite:onPlayBuffHolderAction(typ, data, isOver)
	-- 播放全部表现
	if not typ then
		local _data
		for k,v in pairs(self.buffEffectHolderMap) do
			_data = v.datas:back()
			if holderActionMap[k] and v.datas:size() > 0 and (v.isPlayId == nil or v.isPlayId ~= _data.id) and _data.ref > 0 then
				v.isPlayId = holderActionMap[k].onBuff(self,false,_data.args) or _data.id
			end
		end
		return
	end

	if holderActionMap[typ] then
		self.buffEffectHolderMap[typ].isPlayId = holderActionMap[typ].onBuff(self, isOver, data.args) or data.id
	end
end

-- 技能结束时删除特效   buffArgs:
-- {
-- 	id =
-- 	cfg =
-- 	dispel =
-- 	tostrModel =
-- }
function BattleSprite:onDeleteBuffEffect(buffArgs)
	local battleView = self.battleView
	local cfg = buffArgs.cfg

	-- local actionType = cfg.holderActionType and cfg.holderActionType.typ
	-- if actionType and holderActionMap[actionType] then
	-- 	battleView:onEventEffect(nil,'callback', {func = function()
	-- 		holderActionMap[actionType].onBuff(self,true,cfg.holderActionType.args)
	-- 	end, delay = 0})
	-- end

	if cfg.holderActionType then
		if cfg.holderActionType.typ then
			self:delBuffHolderAction(buffArgs.id, cfg.holderActionType.typ)
		elseif cfg.holderActionType.list then
			for k, v in csvPairs(cfg.holderActionType.list) do
				-- cfg.holderActionType.playType = 1
				self:delBuffHolderAction(buffArgs.id.."_"..k, v.typ, v.playType)
			end
		end
	end


	self:deleteBuffEffect(cfg.effectResPath,cfg.effectAniName[buffArgs.aniSelectId],cfg.effectPos,cfg.effectAniChoose.type)

	if cfg.effectOnEnd and cfg.effectOnEnd.res then
		battleView:onViewProxyCall("onFrameOnceEffect", {
			tostrModel = buffArgs.tostrModel,
			resPath = cfg.effectOnEnd.res,
			aniName = cfg.effectOnEnd.aniName,
			pos = cfg.effectOnEnd.pos or 2,
			offsetPos = cfg.onceEffectOffsetPos,
			assignLayer = cfg.onceEffectAssignLayer,
			wait = cfg.onceEffectWait,
			delay = cfg.onceEffectDelay or 0
		})
	end

	-- 皮肤还原
	if cfg.skin then
		local skinArgs = {buffId = buffArgs.id, isRestore = true, skinName = cfg.skin}
		self:setSkin(skinArgs)
	end

	self:onDelBuffIcon(buffArgs.cfgId)
    self:onDelBuffShader(buffArgs)
	gRootViewProxy:notify('delLinkEffect', buffArgs.id)
end

--播放buff表现shader
function BattleSprite:onPlayBuffShader(buffArgs)
    local buffshader = buffArgs.buffshader
    local switch, extraArgs = csvNext(buffshader)
    -- for k,v in pairs(buffshader) do
    --     if type(v) == "table" then
    --         extraArgs = v
    --         switch = k
    --     end
    -- end

	local args = {
		buffId = buffArgs.buffId,
		switch = switch,
		extraArgs = extraArgs
	}
	self:addBuffHolderAction(buffArgs.buffId, "shader", args)
end

function BattleSprite:onDelBuffShader(buffArgs)
	local cfg = buffArgs.cfg
    if cfg.buffshader and csvSize(cfg.buffshader) ~= 0 then
		self:delBuffHolderAction(buffArgs.cfgId, "shader")
    end
end

function BattleSprite:getBuffEffectKey(effectRes, aniName, effectAniType)
	local aniName = aniName or "effect_loop"
	local effectKey = effectRes
	-- 同个资源会存在同时播放不同的特效,因为各个特效的层级不同
	if effectAniType == 0 then effectKey = effectKey .. "|" .. aniName end
	return effectKey
end

function BattleSprite:getViewTb(pos)
	-- local isGlobalView = (pos == 3 or pos == 4 or pos == 5)
	-- local effectMap = isGlobalView and self.battleView.buffEffectsMap or self.buffEffectsMap
	-- local effectRef = isGlobalView and self.battleView.buffEffectsRef or self.buffEffectsRef
	local effectMap = self.buffEffectsMap
	local effectRef = self.buffEffectsRef
	local force = self.model.force
	if pos == 4 then force = 3 - force end

	if pos == 3 or pos == 4 then
		if force == 1 then
			effectMap = self.battleView.buffEffectsSelfMap
			effectRef = self.battleView.buffEffectsSelfRef
		elseif force == 2 then
			effectMap = self.battleView.buffEffectsEnemyMap
			effectRef = self.battleView.buffEffectsEnemyRef
		end
	elseif pos == 5 then
		effectMap = self.battleView.buffEffectsMap
		effectRef = self.battleView.buffEffectsRef
	end
	return effectMap, effectRef
end

function BattleSprite:onAddBuffHolderAction(id, typ, args, playType)
	self:addBuffHolderAction(id, typ, args, playType)
end

function BattleSprite:onDelBuffHolderAction(id,typ, playType)
	self:delBuffHolderAction(id,typ, playType)
end

function BattleSprite:updateBuffeffectsScale()
	self:scheduleUpdate(function()
		local alterScaleX = 2 * math.abs(self:getScaleX())
		local alterScaleY = 2 * self:getScaleY()
		for _, sprite in ipairs(self.buffEffectsFollowObjToScale) do
			local curScaleX = sprite:getScaleX()
			-- lua5.3版本起 1/(-0) 和 1/0 的结果一致, 都是正无穷大inf
			-- 而在之前版本中则不一致, 前者是-inf, 后者是inf
			local signX = battleEasy.ifElse((1 / curScaleX) > 0, 1, -1)
			local curScaleY = sprite:getScaleY()
			if alterScaleX ~= signX * curScaleX then sprite:setScaleX(signX * alterScaleX) end
			if alterScaleY ~= curScaleY then sprite:setScaleY(alterScaleY) end
		end
	end)
end