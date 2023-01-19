--
-- SegShow
--
-- damageSeg 总伤害的百分比,需要取总伤害
-- hpSeq	加血分段
-- processArgs == skill<args>
-- args == csv.effect_event[effectID]

local _min = math.min
local _max = math.max

local SegShow = class('SegShow', battleEffect.EventEffect)
battleEffect.SegShow = SegShow

function SegShow:onPlay()
	self.idx = 1
	self.model = self.view.model -- view应该是BattleSprite
	self.viewKey = self.view.key
	self.segs = self.args.damageSeg or self.args.hpSeg
	self.intervals = self.args.segInterval
	self.waitTick = self.intervals[1]

	if not self.args.processArgs or not self.args.processArgs.values[self.model.id] then
		local processId = (self.args.processArgs and self.args.processArgs.process) and self.args.processArgs.process.id or -1
		local unitId = self.model and self.model.unitID or -1
		errorInWindows( "SegShow Args valueArgs nil,unitId = %s,processCfg id = %s",unitId,processId)
		return self:free()
	end

	self.valueArgs = self.args.processArgs.values[self.model.id]	-- 格式: {[segid]={}, [segid]={}, ,,}
	if self.args.processArgs.buffTb then
		self.buffArgs = self.args.processArgs.buffTb[self.model.id]
	end

	self.type = self.args.processArgs.process.segType
	self.numShow = self.type == self.args.processArgs.showType
	if self.type == battle.SkillSegType.damage then
		self.view:beHit(0, 0)
	end
end

function SegShow:onUpdate(delta)
	local battleView = gRootViewProxy:raw()

	-- BattleSprite be removed, view was cc.Node
	local existed = gRootViewProxy:call('isObjExisted', self.viewKey)
	if not existed then
		return self:free()
	end

	local endSeg = table.length(self.segs)

	if self.type == battle.SkillSegType.damage then
		self.view:beHit(delta)
	end
	if self.tick >= self.waitTick and battleView then
		local valueArg = self.valueArgs[self.idx] or {}
		if not assertInWindows(valueArg, 'effect_event seg is missed!!') then
			local v = valueArg.value and valueArg.value:get() or 0
			-- local vailidV = valueArg.segValidValue or 0
			-- if self.idx == 1 and self.isLastProcess then
			-- 	gRootViewProxy:notify("setUltAccEnable",false)
			-- end
			-- 表现相关的执行 (后续会将其它计算都去掉,只使用这一个来表现)
			if self.idx == 1 then
				if self.buffArgs then
					battleView:runDefer(self.buffArgs)
				end
			end

			battleView:runDefer(valueArg and valueArg.deferList)

			if self.numShow then
				-- 显示总伤害或者总治疗
				gRootViewProxy:notify('showNumber', {delta = v, skillId = self.args.processArgs.skillId, typ = self.type})
			end

			--受击动画
			if self.type == battle.SkillSegType.damage then
				--这个时间暂定,后面根据美术动画效果修改
				self.view:beHit(0, 600)
			end
		end

		self.idx = self.idx + 1
		if self.idx > endSeg or not self.valueArgs[self.idx] then
			if self.type == battle.SkillSegType.damage then	--这里的延迟可能会因为被杀死导致不存在了
				-- todo: 这里需要修改为至少等待一段 beHitTime 时间的
				-- 下面的这个会加入到统一的queue中,实际上不是和自身的动作时间相关的
				battleEasy.effect(self.view.model, function()
					local existed = gRootViewProxy:call('isObjExisted', self.viewKey)
					if not existed then return end
					if self.view.actionState == "hit" then
						self.view:setActionState(battle.SpriteActionTable.standby)
					end
				end, {delay = self.view:getLeftBeHitTime()})
			end
			return self:stop()
		end
		-- log.segShow.onUpdate("self.waitTick: ", self.waitTick, "self.intervals[self.idx]: ", self.intervals[self.idx])
		self.waitTick = self.waitTick + self.intervals[self.idx] or 0
	end
end

function SegShow:onFree()
end

function SegShow:onStop()
end


--
-- Sound
--
-- soundArgs	全局-音效路径
--

local Sound = class('Sound', battleEffect.EventEffect)
battleEffect.Sound = Sound

function Sound:onPlay()
	local args = self.args.music and self.args.music or self.args.sound
	local isLoop = args.loop > 0
	local battleView = gRootViewProxy:raw()

	if args.bgmChanged then
		audio.pauseMusic()
		battleView.bgmChanged = true
	end
	self.handle = audio.playEffectWithWeekBGM(args.res, isLoop) -- , {musicLens = 4, weekOpen = true}
	-- no loop sound set free
	if not isLoop then
		self:free()
	end
end

function Sound:onStop()
	if self.handle then
		--循环音效有个bug 如果两个人一先一后播放同个循环音效 先stop的会把后的也stop掉
		--以后有需要的话 可以对handle做个引用计数，毕竟循环音效不多
		audio.stopSound(self.handle)
		self.handle = nil
	end
end

function Sound:debugString()
	local args = self.args.music and self.args.music or self.args.sound
	return string.format("Sound: %s", args.res)
end

--
-- Music
--
-- music 全局-背景音乐
--

local Music = class('Music', battleEffect.OnceEventEffect)
battleEffect.Music = Music

local musicOp = {
	play = audio.playMusic,
	stop = audio.stopMusic,
	pause = audio.pauseMusic,
	resume = audio.resumeMusic,
}

function Music:onPlay()
	local args = self.args.music
	local battleView = gRootViewProxy:raw()

	if args.res then
		musicOp[args.op](args.res, args.isLoop or false)
	else
		musicOp[args.op]()
	end

	if args.bgmChanged then
		battleView.bgmChanged = true
	end
end

function Music:debugString()
	local args = self.args.music
	return string.format("Music: %s", args.res)
end


--
-- ShowCards
--
-- showCards	1-在目标队列里的都显示;2-只显示自己和敌方被攻击对像
--

local ShowCards = class('ShowCards', battleEffect.EventEffect)
battleEffect.ShowCards = ShowCards

function ShowCards:onPlay()
	--在目标队列里的都显示
	if self.args.showCards == 1 then
		for k = 1, SELF_HERO_COUNT do
			if self.showCardIDs[k] then
				local obj = self.showCardIDs[k]
				if obj  then
					gRootViewProxy:notify('processSkillTargetHide',tostring(obj),false)
				end
			end
		end

	-- 只显示自己和敌方被攻击对像
	elseif self.args.showCards == 2 then
		for k = 1, SELF_HERO_COUNT do
			local obj = self.showCardIDs[k]
			local flag = obj and (not obj:isDeath()) and obj.id ~= self.owner.id
			if flag then
				for k, v in pairs(self.sputteringTargets) do
					if obj.id == v.id then
						flag = false
					end
				end
			end
			if flag then
				gRootViewProxy:notify('processSkillTargetHide',tostring(obj), true)
			else
				gRootViewProxy:notify('processSkillTargetHide',tostring(obj), false)
			end
		end
	end
end

function ShowCards:onStop()

end


--
-- Shaker
--
-- shaker	全局-震屏的起始，结束的时间，震屏的幅度
-- {shaker = {beginT=0;endT=100;disx=10;disy=10;count=11;interval=200;isRepeat=false}} --比数码那边多套了一层
--

local Shaker = class('Shaker', battleEffect.EventEffect)
battleEffect.Shaker = Shaker

function Shaker:onPlay()
	-- 全局
	self.view = gRootViewProxy:raw()
	self.target = self.view
	local shakerArgs = self.args.shaker
	self:resetShaker()
	self.disx = shakerArgs.disx or 0
	self.disy = shakerArgs.disy or 0
	self.isRepeat = shakerArgs.isRepeat
	if self.isRepeat and self.args.segInterval then
		self.timeList = self.args.segInterval
		self.timer = 0
		self.seg = 1
	end
	if self:shakerCountOver() then
		self:stop()
	end
end

function Shaker:onStop()
	self.target:setPosition(0, 0)
end

function Shaker:resetShaker()
	local shakerArgs = self.args.shaker
	self.lastTime = shakerArgs.lastTime or (shakerArgs.endT - shakerArgs.beginT)
	self.count = shakerArgs.count or 1
	self.dur = 0
	self.wait = shakerArgs.beginT or 0
	self.interval = shakerArgs.interval or 0
end

function Shaker:waiting()
	return self.wait >= 0
end

function Shaker:shakerIng()
	return self.dur > 0
end

function Shaker:shakerCountOver()
	return self.count <= 0
end

function Shaker:needRepeat()
	if not self.timeList or not self.seg then
		return false
	end

	return self.timeList[self.seg + 1]
end

function Shaker:repeatWaiting()
	return self.timeList[self.seg + 1] > self.timer
end

function Shaker:onUpdate(delta)
	if self.timer then self.timer = self.timer + delta end
	if self:shakerIng() then 					-- 震动中
		self.dur = self.dur - delta
		if self.dur > 0 then
			local x = math.random(-self.disx, self.disx)
			local y = math.random(-self.disy, self.disy)
			self.target:setPosition(x, y)
		else
			self.target:setPosition(0, 0)
		end
	elseif self:shakerCountOver() then 			-- 没有剩余次数
		-- 播放结束
		if self:needRepeat() then
			if not self:repeatWaiting() then
				-- 记录数据
				self.seg = self.seg + 1 		-- 次数+1
				self.timer = 0
				self.target:setPosition(0, 0)
				self:resetShaker()
			end
		else
			return self:stop()
		end
	elseif self:waiting() then 					-- 等待中
		-- 判断等待状况
		self.wait = self.wait - delta
		if self.wait < 0 then
			if self.count > 0 then
				self.dur = self.lastTime
				self.wait = self.interval
			end
			self.count = self.count - 1
		end
	else
		return self:stop()
	end
end

function Shaker:onStop()
	self.target:setPosition(0, 0)
end

function Shaker:debugString()
	local t = self.dur or 0
	local seg = ""
	if self.seg then
		seg = string.format("%s/%s", self.seg, table.length(self.timeList))
	end
	return string.format("Shaker: %5.2f %s", t, seg)
end

--
-- Move
--
-- moveArgs	受击目标的表现（位移，大小，旋转）
-- scale = ScaleTo
-- rot = RotateTo
-- x,y = MoveTo - getPosition -> MoveBy
--

local Move = class('Move', battleEffect.OnceEventEffect)
battleEffect.Move = Move

function Move:onPlay()
	log.battle.event_effect.move("受击目标表现！！！")
	-- --每次可以多个一起显示的？
	self.targets = self.args.targets or {}
	-- 根据技能施法者的面向来定
	local faceTo = 1
	if self.args.faceTo then
		faceTo = (self.args.faceTo == 1) and 1 or -1
	end
	local ret = self:adaptArgs(faceTo)
	-- self.target 是战斗场景中的 battleSprite, 和数码中的那个 纯spine的ani有点区别, 所以这里不能直接用 getPosition()
	-- 设置为 0,0 的意思,是从当前所在的位置开始计算偏移的距离,当前为 (0, 0) 点,后续配置的多段move都是以当前初始点的位置来做变化的
	local lastX, lastY = 0, 0			-- -- self.target:getPosition()
	for _,arg in ipairs(ret)  do
		if arg.t == nil then break end	--
		local t = arg.t/1000.0
		t = _max(t, 0.01)	-- 貌似时间为0时,动作都没有正确执行,具体原因不明
		local deltaX, deltaY = 0, 0
		local function actFunc()
			local spawn = transition.executeSpawn(self.target)
			spawn:delay(t)
			if arg.rot then
				spawn:rotateTo(t, arg.rot*faceTo)
			end
			if arg.scale then
				spawn:scaleTo(t, arg.scale)
			end
			if arg.x or arg.y then
				arg.x = arg.x and arg.x*faceTo or lastX
				arg.y = arg.y or lastY
				deltaX, deltaY = arg.x - lastX, arg.y - lastY
				lastX, lastY = arg.x, arg.y
				spawn:moveBy(t, deltaX, deltaY)
			end
			spawn:done()
		end
		local function actFunc2()	-- 用来同步保存坐标的,
			local posx, posy = self.target:getCurPos()
			log.battle.event_effect.move("seat= , before:", self.target.seat, posx, posy)
			-- print("before:", posx, posy)
			posx, posy = posx + deltaX, posy + deltaY
			self.target:setCurPos(cc.p(posx, posy))
			log.battle.event_effect.move("seat= , after:", self.target.seat, posx, posy)
			-- print("after:", posx, posy)
		end
		local sequence = transition.executeSequence(self.target)
		if arg.delay then
			sequence:delay(arg.delay/1000.0)
		end
		sequence:func(actFunc)
				:func(actFunc2)
				:done()
	end
end

local function getCloseXY(targets, objPosTb, selfPos, per)
	per = 1 - per
	local maxX, maxY, minX, minY = -math.huge, -math.huge, math.huge, math.huge
	for id, pos in pairs(objPosTb) do
		maxX = _max(maxX,pos.x)
		minX = _min(minX,pos.x)
		maxY = _max(maxY,pos.y)
		minY = _min(minY,pos.y)
	end
	local targetPos = cc.p((maxX + minX) / 2, (maxY + minY) / 2)
	local xdis, ydis = (targetPos.x - selfPos.x), (targetPos.y - selfPos.y)

	return xdis * per, ydis * per
end

-- 屏幕上绝对坐标转换为相对位置
-- 补充: 整体中心移动的
-- 整体移动时, 需要根据自己当前的位置换算为要移动的距离
-- 整体是指本次受击的所有目标群体, 以过程段为单位。
-- 整体移动分为以下几种:  整体移动的中心为目标群体的中心, 根据前后排123列计算谁在中心,
-- -- 1. 群体中的每个个体，往x/y轴方向移动 d 距离 (这个是目前常规的x/y相对移动, 平移)，
-- -- 2  群体中的每个个体, 往固定位置的 absX/Y 处移动, (这个是目前的绝对位置移动, 会把个体往 absX/Y处做移动, 同时配置absX/Y时会重叠到一个点上)
-- 3. 中心 移动到 某个点 处(绝对位置,需要转换, 和之前上面的absX/Y 不一样, 这个是整体中心往这边移动, 各目标相对位置仍然保持不变)，
-- 4. 周围目标 往 中心 靠拢, 收缩 d 距离, (收缩时以全体都在的时候为依据来处理收缩, 相当于缩短间距,处于中间一列的目标y轴不需要缩短,x轴缩短)
-- 参数配置: {teamClose=per} 	teamClose:中心靠近比例
function Move:adaptArgs(faceTo)
	local node = self.target
	if not node then
		return
	end
	faceTo = faceTo or 1
	local nodeX, nodeY = node:getPosition()
	local pos = node:getParent():convertToWorldSpace(cc.p(nodeX, nodeY))
	local worldPos = gGameUI.uiRoot:convertToNodeSpace(pos)
	local worldX, worldY = worldPos.x, worldPos.y
	local ret = clone(self.args.move)
	-- 绝对位置坐标转换
	for _, arg in ipairs(ret) do

		if arg.absX or arg.absY then
			arg.absX = arg.absX and ( (faceTo == 1) and arg.absX or (display.width - arg.absX) )	--翻转
			local ax = arg.absX and faceTo*(arg.absX - worldX)
			local ay = arg.absY and (arg.absY - worldY)
			if ax then
				arg.x = arg.x and arg.x + ax or ax
			end
			if ay then
				arg.y = arg.y and arg.y + ay or ay
			end
		end

		if arg.teamClose then	-- 靠拢收缩(因为这个值是按归位时目标之间的距离来收缩的,所以在多次靠拢时可能会有点问题,尽量一个技能中就用一两次吧)
			arg.delay = arg.delay and arg.delay + 20 		--todo 防止出错local func = function()

			if not self.objPosTb then
				local objPosTb = {}
				local selfPos
				for _, obj in pairs(self.targets) do
					if obj then
						local px, py = obj:getCurPos()
						px = (faceTo == 1) and px or (display.width - px)
						objPosTb[obj.id] = cc.p(px, py)
						if obj.id == node.id then
							selfPos = cc.p(px, py)
						end
					end
				end
				self.objPosTb = objPosTb
				self.selfPos = selfPos
			end
			local x, y = getCloseXY(self.targets, self.objPosTb, self.selfPos, arg.teamClose)
			arg.x = arg.x and arg.x + x or x
			arg.y = arg.y and arg.y + y or y
		end
	end
	return ret
end


--
-- Show
--
-- show	显示隐藏 -- 支持多个连续的显示隐藏
--

local Show = class('Show', battleEffect.OnceEventEffect)
battleEffect.Show = Show

function Show:onPlay()
	local args = self.args.show

	for _,arg in ipairs(args) do
		if arg.hide == nil then break end
		local sequence = transition.executeSequence(self.view)
		if arg.delay then
			sequence:delay(arg.delay/1000.0)
		end
		local function doShow()
			self.view:setVisible(not arg.hide)
		end
		local function showBack()
			self.view:setVisible(arg.hide)
		end
		sequence:func(doShow)
		if arg.lastTime then
			sequence:delay(arg.lastTime/1000.0)
			sequence:func(showBack)
		end
		sequence:done()
	end
end


--
-- Delay
--
-- delay	延时
-- lifetime 持续时间
--

local Delay = class('Delay', battleEffect.EventEffect)
battleEffect.Delay = Delay

function Delay:onUpdate(delta)
end

function Delay:debugString()
	return string.format("Delay: %5.2f", self.lifetime - (self.tick or 0))
end

--
-- SpriteEffect
--
-- effectType 特效类型（0播放本体spine动作;1播放res特效）
-- effectRes 特效资源或动作名
-- effectArgs 特效参数
-- {offsetX=0;offsetY=0;zorder=-1;aniName=;aniloop=false;flytime=0;flyX=0;flyY=0;lastTime=0;lifetime=1000}
-- 位置偏移/层级/特效名/是否循环/飞行速度/飞行距离/存活时间（单位ms)
-- onComplete 特效播放结束或者lifetime时间到
--

local SpriteEffect = class('SpriteEffect', battleEffect.EventEffect)
battleEffect.SpriteEffect = SpriteEffect

function SpriteEffect:onPlay()
	local typ = self.args.effectType or 0
	local res = self.args.effectRes or self.args.action
	local args = self.args.effectArgs or {}
	local battleView = gRootViewProxy:raw()

	self.onComplete = self.args.onComplete
	if self.onComplete then
		local callback = self.onComplete
		self.onComplete = function()
			-- lifetime或动作播放结束
			if self.onComplete then
				self.onComplete = nil
				callback()
				self:stop()
			end
		end
	end

	local function actFunc()
		-- 0播放本体spine动作
		if typ == 0 then
			self.view:setActionState(res, self.onComplete)

		-- 1播放res特效
		elseif typ == 1 then
			local faceTo = self.args.faceTo		-- 这个faceto是根据 施法者的faceto来定的
			local viewScale = 3 				-- 默认的放大值 TODO: 现在是2倍分辨率，后续跟策划配置一起改
			local pos = cc.p(0, 0)
			if args.offsetX and args.offsetY then
				pos = cc.p(faceTo*args.offsetX, args.offsetY)		-- x轴 ×方向
			end
			self.sprite = newCSprite(res)
			assert(self.sprite, 'ERROR!!! effectArgs add res error, not find the res:', res)

			self.sprite:setAnchorPoint(cc.p(0.5, 0.5))
			args.scale = args.scale or 1
			if args.addTolayer == 0 then
				self.sprite:setScaleX(2.35)
				self.sprite:setScaleY(2)
			else
				self.sprite:setScaleX(faceTo*viewScale*args.scale)
				self.sprite:setScaleY(viewScale*args.scale)
			end

			if args.screenPos then	-- 添加到屏幕上, 使用相对于屏幕的坐标
				if args.screenPos == 0 then
					pos = cc.pAdd(pos, display.center)
				elseif args.screenPos == 1 then
					local x, y = self.target:getCurPos()
					local effectPos = cc.p(x, y)
					pos = cc.pAdd(pos, effectPos)
				end
				self.sprite:setPosition(pos)
				if args.addTolayer == 1 then
					battleView.effectLayerUpper:add(self.sprite, args.zorder or 0)
				elseif args.addTolayer == 0 then
					battleView.stageLayer:add(self.sprite, args.zorder or 0)
				else
					battleView.effectLayerLower:add(self.sprite, args.zorder or 0)	-- 修改为新建的层,该层不会随着大招效果屏幕拉伸
				end
			else
				self.sprite:setPosition(pos)
				self.view:add(self.sprite, args.zorder or 0)
			end

			if self.sprite:isSpine() then
				if args.aniName then
					self.sprite:play(args.aniName)
				else
					args.aniLoop = self.sprite:play("effect_loop")
					if not args.aniLoop then
						self.sprite:play("effect")
					end
				end
			end

			local function remove()
				self:stop()
			end

			-- 特效的删除
			-- 循环特效
			if args.aniLoop then
				-- 有飞行类动作时,飞完了删除
				if args.flytime and args.flyX and args.flyY then
					transition.executeSequence(self.sprite)
						:moveBy(args.flytime/1000.0, args.flyX*faceTo, args.flyY)
						:func(remove)
						:done()
				else	-- 如果没有配置时间的话, 就给个默认1秒时间
					transition.executeSequence(self.sprite)
						:delay(args.lastTime and args.lastTime/1000.0 or 1)
						:func(remove)
						:done()
				end

			-- 一次性特效播放完就删除 (可能需要自己配置删除时间的)
			else
				if args.lastTime then
					transition.executeSequence(self.sprite)
						:delay(args.lastTime/1000.0)
						:func(remove)
						:done()
				else
					self.sprite:setSpriteEventHandler(function(_type, event)
						if _type == sp.EventType.ANIMATION_COMPLETE then
							removeCSprite(self.sprite)
						end
					end)
				end
			end
		end
	end

	local sequence = transition.executeSequence(self.view)
	if args.delay then
		sequence:delay(args.delay/1000.0)
	end
	sequence:func(actFunc):done()

	if not self.onComplete then
		self:stop()
	end
end

function SpriteEffect:onUpdate(delta)
end

function SpriteEffect:onStop()
	if self.onComplete then
		-- 当前动作如果被中止了,要把相应的回调事件销毁
		if self.view.actionCompleteCallback == self.onComplete then
			-- print("destory self.view.actionCompleteCallback")
			self.view.actionCompleteCallback = nil
		end
		self.onComplete()
	end
end

function SpriteEffect:stop()
	if self.sprite then
		self.sprite:stopAllActions()
		removeCSprite(self.sprite)
		self.sprite = nil
	end
	battleEffect.EventEffect.stop(self)
end

function SpriteEffect:debugString()
	local args = self.args.effectArgs or {}
	local res = self.args.effectRes or self.args.action
	if args.aniName then
		res = string.format("%s#%s", res, args.aniName)
	end
	local obj = toDebugString(self.view)
	return string.format("SpriteEffect: %s -> %s", res, obj)
end

--
-- zOrder
--
-- zOrder	显示隐藏 -- 支持多个连续的显示隐藏
--

local ZOrder = class('ZOrder', battleEffect.OnceEventEffect)
battleEffect.ZOrder = ZOrder

function ZOrder:onPlay()
	local args = self.args.zOrder

	for _,arg in ipairs(args)  do
		local zval = arg.zorder
		if not zval then break end
		local sequence = transition.executeSequence(self.view)
		if arg.delay then
			sequence:delay(arg.delay/1000.0)
		end
		local zval0 = self.view:getLocalZOrder() -- 保留原始zOrder 赋初值防止报错
		local function setZOrder()
			zval0 = self.view:getLocalZOrder()-- 再次赋值zOrder 确保正确
			self.view:setLocalZOrder(zval0 + zval)
		end
		local function setZOrderBack()
			self.view:setLocalZOrder(zval0)
		end
		sequence:func(setZOrder)
		if arg.lastTime then
			sequence:delay(arg.lastTime/1000.0)
			sequence:func(setZOrderBack)
		end
		sequence:done()
	end
end