

--移动到某个位置上,有些大招需要调整目标的站位
function BattleSprite:moveToPosIdx(posIdx)
	local x, y
	if  posIdx < 0 then
		x, y = battle.StandingPos[99].x, battle.StandingPos[99].y
	elseif posIdx <= 6 or posIdx > 12 then -- 统一规则
		x, y = battle.StandingPos[posIdx].x, battle.StandingPos[posIdx].y
	else
		x, y = display.width-battle.StandingPos[posIdx-6].x, battle.StandingPos[posIdx-6].y
	end
	x, y = x+self.posAdjust.x, y+self.posAdjust.y
	if x and y then
		self:setPosition(cc.p(x,y))
		self:setCurPos(cc.p(x,y))
	end
end

-- 位移buff 位置变动
function BattleSprite:onDoShiftPos(posIdx, cfg)
	local x, y
	if posIdx <= 6 or posIdx > 12 then -- 统一规则
		x, y = battle.StandingPos[posIdx].x, battle.StandingPos[posIdx].y
	else
		x, y = display.width-battle.StandingPos[posIdx-6].x, battle.StandingPos[posIdx-6].y
	end
	x, y = x+self.posAdjust.x, y+self.posAdjust.y

	--移动动画
	self:onAddEventEffect('moveTo', {speed=1500, a=1000, x=x, y=y, changeFaceTo = false}, true)
	self.seat = self.model.seat
	self:setCurPos(cc.p(x,y))
	self:updHitPanel()
	self:onAddToScene()

	--移动额外动画
	for _=1,1 do
		if not cfg then break end
		local resPath = cfg.onceEffectResPath
		if not resPath or resPath == '' then break end
		local sprite = newCSprite(resPath)
		local offsetPos = cfg.onceEffectOffsetPos
		local aniName = cfg.onceEffectAniName or "effect"
		self:add(sprite, 12)
		sprite:play(aniName)
		sprite:setSpriteEventHandler(function(_type, event)
			if _type == sp.EventType.ANIMATION_COMPLETE then
				removeCSprite(sprite)
			end
		end)
		local pos = cc.p(0, 0)
		if offsetPos then
			pos = cc.pAdd(cc.p(0, 0), offsetPos)
		end
		sprite:setPosition(pos):scale(2)
	end
end
-- 计算移动的位置
function BattleSprite:getMoveToTargetPosition(posIdx, skillCfg)
	local x, y = self:getAttackPos(posIdx, skillCfg.posC, skillCfg.attackFriend)
	-- 开始播放那个场景的位置移动变化
	if (posIdx ~= self:getSeat()) and (skillCfg.cameraNear == 1 or skillCfg.cameraNear == 2) then -- posIdx 不是自己id时,表示需要移动的,可能是需要大招修正的
		self.skillNeedCameraFix = true
		local camrX = skillCfg.cameraNear_posC and skillCfg.cameraNear_posC.x or 0
		local camrY = skillCfg.cameraNear_posC and skillCfg.cameraNear_posC.y or 0
		x, y = self:getAttackPos(posIdx, cc.p(camrX, camrY), skillCfg.attackFriend)
	end
	return x, y
end

function BattleSprite:getMoveToTargetFrontPosition(posIdx, skillCfg)
	local x, y = self:getProtectPos(posIdx,cc.p(0,0))
	-- 开始播放那个场景的位置移动变化
	if (posIdx ~= self:getSeat()) and (skillCfg.cameraNear == 1 or skillCfg.cameraNear == 2) then -- posIdx 不是自己id时,表示需要移动的,可能是需要大招修正的
		self.skillNeedCameraFix = true
		local camrX = skillCfg.cameraNear_posC and skillCfg.cameraNear_posC.x or 0
		local camrY = skillCfg.cameraNear_posC and skillCfg.cameraNear_posC.y or 0
		x, y = self:getProtectPos(posIdx, cc.p(camrX, camrY))
	end
	return x, y
end
-- 移动所需要的时间
function BattleSprite:getMoveTime(posIdx, skillCfg, speed, a)
	local x, y = self:getMoveToTargetPosition(posIdx, skillCfg)
	-- 计算移动所需的时间
	local speed0 = speed or 1000
	local a = a
	local x2, y2 = self:getCurPos()
	local dis = cc.pGetLength(cc.p(x - x2, y - y2))
	local time = 0
	if a then
		local speedSquare = speed0*speed0 + 2*a*dis
		speedSquare = math.max(speedSquare, 0)
		time = (math.sqrt(speedSquare) - speed0)/a
	else
		time = dis/speed0
	end
	return time
end

function BattleSprite:onAddToScene()
	self:setVisible(false)
	self:resetPosZ()
	self:setLocalZOrder(self.posZ)
	self:setName("object" .. self.seat)
end

function BattleSprite:resetPosZ(effectY)
	local _, y = self:getSelfPos()
	local frontRow = display.height - (effectY or y)
	local backRow = frontRow - 1
	local rowNum = 2-(math.floor((self:getSeat()+2)/3))%2
	self.posZ = (rowNum == 1) and frontRow or backRow
	self.battleMovePosZ = frontRow
end

-- 走过去	noQueue-主动技能需要加入到主队列中, 其它技能类型无序即可
function BattleSprite:onMoveToTarget(posIdx, skillCfg, noQueue, viewId, protectorTb)
	local needMove = true
	if posIdx == battle.AttackPosIndex.selfPos and not skillCfg.attackFriend then	-- 加一个需要移动的判断,原地的位置可以不移动
		needMove = false
	end

	local targetView = self.battleView:onViewProxyCall('getSceneObj', viewId)
	local usedView = self:getRealUseView()

	-- 移动的具体位置
	local x, y = usedView:getMoveToTargetPosition(posIdx, skillCfg)
	if posIdx ~= battle.AttackPosIndex.selfPos and posIdx ~= battle.AttackPosIndex.center and targetView then
		local posAdjust = targetView.posAdjust
		x = x + posAdjust.x
		y = y + posAdjust.y
	end
	-- 补充,攻击己方队友时,需要转向
	local newfaceto = skillCfg.attackFriend and -1*self.faceTo
	-- print(' ----- newfaceto=', newfaceto, skillCfg.attackFriend)
	usedView:onAddEventEffect('callback', {func = function()
		--大招场景镜头拉伸时的移动修正
		if self.skillNeedCameraFix then
			self.battleView:onViewProxyNotify('skillStartStageMove', skillCfg.cameraNear)
		end
	end}, noQueue)
	if needMove then
		usedView:onAddEventEffect('moveTo', {
			speed=1500, a=1000,
			timeScale = skillCfg.timeScale,
			delayMove = skillCfg.delayBeforeMove,
			costTime = skillCfg.moveCostTime,
			x=x, y=y,
			changeFaceTo = newfaceto
		}, noQueue)
	end
	if protectorTb then
		local z = math.max(targetView:getLocalZOrder(), self:getLocalZOrder()) + 1
		protectorTb.view:proxy():onMoveToTargetFront(protectorTb.targetID, skillCfg, targetView.posAdjust, noQueue)
		protectorTb.view:proxy():setLocalZOrder(z)
	end
end

-- 保护buff使用 移动到攻击者和被攻击者中间的位置 朝向不变
function BattleSprite:onMoveToTargetFront(posIdx,skillCfg,posAdjust,noQueue)
	local x, y = self:getMoveToTargetFrontPosition(posIdx, skillCfg)
	-- if posIdx ~= battle.AttackPosIndex.selfPos and posIdx ~= battle.AttackPosIndex.center then
	x = x + posAdjust.x
	y = y + posAdjust.y
	-- end
	-- 这里的posIdx就是目标的seat， 上面的判断应该也是多余的
	local changeFaceTo
	if (posIdx <= 6 and self:getSeat() > 6) or (self:getSeat() <= 6 and posIdx > 6) then
		changeFaceTo = -1*self.faceTo
	end
	self:onAddEventEffect('moveTo', {speed=1500, a=1000, x=x, y=y, changeFaceTo = changeFaceTo}, noQueue)
end

-- 变身时 重新加载Unit
function BattleSprite:onSortReloadUnit(args)
	--unitID相同重复变身
	if self.unitID == self.model.unitID then
		return
	end
	-- 删除绑定单位的特效
	for _,data in ipairs(self.specBindEffectCache) do
		removeCSprite(data.effect)
	end
	-- 主动停止holderAction特效,只是停止播放，但并不删除内容
	self:stopAllHolderAction()

	self.specBindEffectCache = {}

	-- 防止本身的actionTable被改变
	self:resetActionTab()
	self:reloadUnit(args)

	-- 重新加载血条的位置
	-- local size = self.lifebar.barPanel:get("di"):size()
	-- self.lifebar.buffAddFirstPos = cc.p(-size.width/2 + 70, 55)
	local unitCfg = self.model.unitCfg
	self.lifebar:setPosition(unitCfg.everyPos.lifePos)
	self.lifebar:setScale(unitCfg.lifeScale)
	self.refreshBuffIconOnce = true
	-- 重新播放绑定单位的特效 或者延迟到回合开始自动播放
	self:onPlayUnitSpecBind()
	--重新加载形象
	-- self:onAddEventEffect('callback', {func = function()
	-- 	-- 防止本身的actionTable被改变
	-- 	self:resetActionTab()
	-- 	self:reloadUnit()
	-- end}, noQueue)
end

-- 技能开始前
function BattleSprite:onSkillBefore(skillStartTb, skillType, noQueue, args)
	-- 技能前加的buff的表现函数
	self:onAddEventEffect('callback', {func = function()
		if skillStartTb then		-- and self.model.disposeDatasOnSkillStart[skillId]
			self.battleView:runDefer(skillStartTb['skillStartAddBuffsPlayFuncs'])
		end
	end}, noQueue)
	-- 技能前触发的buff效果的表现函数
	self:onAddEventEffect('callback', {func = function()
		if skillStartTb then
			self.battleView:runDefer(skillStartTb['skillStartTriggerBuffsPlayFuncs'])
		end
	end}, noQueue)

	self:pushApplySkillSceneTag(args)
	if args and args.isBigSkill then
		if self ~= self:getRealUseView() then
			self:setVisible(false)
		end
	end
end

-- 动画
function BattleSprite:onPlayAction(action, time, noQueue)
	if not action then return end

	if self.isPausing then
		-- 暂停时不播放动画,只修改状态
		return
	end

	local usedView = self:getRealUseView()
	-- 循环action不用等待
	if battle.LoopActionMap[action] then
		table.insert(self.battleView.effectJumpCache,usedView:onAddEventEffect('effect', {action=action, lifetime=time}, noQueue))
		return
	end
	-- onComplete just for SpriteEffect.onUpdate
	table.insert(self.battleView.effectJumpCache,usedView:onAddEventEffect('effect', {action=action, lifetime=time, onComplete=function()
	end}, noQueue))
end

-- 大招跳过的显示数字
function BattleSprite:onUltJumpShowNum(params)
	self:onAddEventEffect('callback', {func = function()
		-- 简单处理一下总伤害显示完后的清理
		self.battleView:onViewProxyNotify('showNumber', params)
	end}, false)
end

local idCmp = function(obj1, obj2)
	return obj1.id < obj2.id
end

-- 大招跳过 先返回
function BattleSprite:onUltJumpEnd()
	self:onResetSkillEnd()
	-- 平滑下动作连接
	self:onAddEventEffect("callback", {func=function()
		self:setActionState(battle.SpriteActionTable.standby)
		performWithDelay(self.battleView,function()
			-- 大招跳过重置技能表现回调开关
			-- 只是为了大招跳过添加的效果？
			-- 延迟一帧
			self.battleView:resetEffectEventEnable()
		end,0)
	end}, false)
end

function BattleSprite:onResetSkillEnd(skillType)
	-- 大招场景移动恢复,恢复和返回同时进行
	self:onAddEventEffect('callback', {func = function()
		if self.skillNeedCameraFix then
			self.skillNeedCameraFix = false
			self.battleView:onViewProxyNotify('skillEndStageMoveBack')
		end
		-- 增加一个技能中大招修改过music后的对应修改
		if self.battleView.bgmChanged then
			audio.resumeMusic()
			self.battleView.bgmChanged = false
		end
	end}, false)
    -- TODO:被动技能表现问题，临时修正
	--显示目标(简单点把所有目标都设置显示一遍)  + 重设每个单位的zorder
	if skillType == battle.SkillType.NormalSkill or skillType == battle.SkillType.PassiveCombine then
		self:onAddEventEffect('callback', {func = function()
			local objs = self.battleView:onViewProxyCall('getSceneAllObjs')
			for _, objSpr in maptools.order_pairs(objs, idCmp) do
				if not objSpr:isComeBacking() and objSpr.id ~= self.id then
					objSpr:resetPos()
				end
			end
		end}, false)
	end
end

-- 技能结束
function BattleSprite:onObjSkillEnd(skillEndTb, skillType, noQueue)
	self:onAddEventEffect('callback', {func = function()
		-- 先显示下在技能结束时加的buff的表现函数(注意,这类buff实际上是在技能动作开始前就已经添加了,只是现在才显示)
		if skillEndTb then
			self.battleView:runDefer(skillEndTb['skillEndAddBuffsPlayFuncs'])
		end
		-- 技能结束时触发的buff效果的表现函数
		if skillEndTb then
			self.battleView:runDefer(skillEndTb['skillEndTriggerBuffsPlayFuncs'])
		end
		-- 掉落的显示
		if skillEndTb and skillEndTb['skillEndDrops'] then
			-- 掉落动画
			self.battleView:onViewProxyNotify("dropShow", skillEndTb['skillEndDrops'])
		end
	end}, noQueue)

	if self.battleView:getEffectEventEnable() then
		self:onResetSkillEnd(skillType,noQueue)
	end

	self:onAddEventEffect('callback', {func = function()
		-- 删除技能中死亡的目标
		if skillEndTb then
			self.battleView:runDefer(skillEndTb['skillEndDeleteDeadObjs'])
		end

		if skillType == battle.SkillType.NormalSkill or skillType == battle.SkillType.PassiveCombine then
			-- 攻击结束时,处理部分记录数据
			-- 简单处理一下总伤害显示完后的清理
			-- self.battleView:onViewProxyNotify('showNumber', {close = true})
			-- 大招时隐藏的UI显示出来(自动战斗和敌方仍然不显示)
			if (self.model.force == 1) and not self.battleView:getSceneModel().autoFight then
				self.battleView:onViewProxyNotify('showMain', true)
			end
		end
		-- -- 不是大招跳过在这里重置技能表现回调开关
		-- if not isJumpBigSkill then
		-- 	self.battleView:resetEffectEventEnable()
		-- end

		-- print("!!!!!!!!!! self.effectProcessArgs = {}",self.model.id)
		-- self.effectProcessArgs = {}
	end}, noQueue)



end

-- 移动回来
-- posIdx 位置代码
-- flashBack是否闪回
-- aotoBack 返回动画是否无序 与noQueue冲突
function BattleSprite:onComeBack(posIdx, noQueue, skillCfg, aotoBack,protectorViews)
	local function comeBack(view)
		if skillCfg.flashBack then	-- 是否闪回
			view:onResetPos()
		else
			-- if aotoBack then
			-- 	battleEasy.queueEffect(function()
			-- 		self:onAddEventEffect('comeBack', {}, true)
			-- 	end)
			-- else
			local args = {
				delayMove = skillCfg.delayBeforeBack,
				costTime = skillCfg.backCostTime,
				timeScale = skillCfg.timeScale,
			}
			view:onAddEventEffect('comeBack', args, noQueue)
			-- end
		end
	end

	if protectorViews then
		for k,v in ipairs(protectorViews) do
			comeBack(v:proxy())
		end
	end

	if posIdx == battle.AttackPosIndex.selfPos and not skillCfg.attackFriend then
		-- do nothing
		return
	end
	local usedView = self:getRealUseView()
	comeBack(usedView)
	--移动回原位置
end

-- 移动回来结束
function BattleSprite:onAfterComeBack(afterComeBackTb, noQueue)

	self:onAddEventEffect('callback', {func = function()
		-- 技能后加 mp
		if afterComeBackTb then
			self.battleView:runDefer(afterComeBackTb['afterComeBackRecoverMp'])
		end
	end}, noQueue)
end

function BattleSprite:onResetPos()
    self:onAddEventEffect("callback", {func=function()
		self:resetPos()
	end})
end

function BattleSprite:onObjSkillOver(noQueue)
    self:onAddEventEffect('callback', {func = function()
		self:popApplySkillSceneTag()
	end},  noQueue)
end

function BattleSprite:onNewBattleTurn()
	-- self.effectProcessArgs = {}
	-- 每个新回合判断身上 1.有锁的buff 显示showEffect为true的buff的Effect 2.否则显示所有buff的effect
	local flag = (not self.lockEffectSwitch)
	self:objToHideEff(flag)

	self:onPlayBuffHolderAction()
	-- unit表上 specBind
	self:onPlayUnitSpecBind()
end

function BattleSprite:onPlayUnitSpecBind()
	-- !!! bind 只能用作常规取值 不能涉及到随机数运算有关的方法
	local effect,ani
	for k,data in ipairs(self.unitSpecBind) do
		if not self.specBindEffectCache[k] then
			local node = nodetools.get(self, unpack(data.node))
			effect = newCSprite(data.effect)

			node:addChild(effect,data.pos[3])

			effect:setPosition(cc.p(data.pos[1],data.pos[2]))
			effect:setScale(data.scale or 1)
			effect:setScaleX(self.faceTo * (data.scale or 1))

			self.specBindEffectCache[k] = {
				effect = effect,
				lastIndex = 0
			}
		end

		local _data = self.specBindEffectCache[k]
		local index = battleCsv.doFormula(data.bind,{
			self = self.model
		})
		-- 适配lua的数组表
		index = index + 1
		if _data.lastIndex ~= index then
			ani = data.action[index]
			if ani then
				_data.effect:play(ani)
				_data.lastIndex = index
			else
				errorInWindows("specBind(%s) action not has index(%s) ",self.unitID,index)
			end
		end
	end
end

function BattleSprite:onAttacting(isAttacting, noQueue)
	self:onAddEventEffect('callback', {func = function()
		if not isAttacting then
			self.battleView:onViewProxyNotify('showLinkEffect', true)
		end
		self.battleView:onViewProxyNotify('updateLinkEffect', isAttacting, self.key)

		local objs = gRootViewProxy:call("getSceneAllObjs")
		local usedView = self:getRealUseView()
		-- for key, sprite in pairs(objs) do
		-- 	usedView = sprite
		-- 	if sprite.key == self.key then
		-- 		usedView = self:getRealUseView() or usedView
		-- 	end
		-- 	usedView:objToHideEff(isAttacting, self)
		-- end
		usedView:objToHideEff(isAttacting, self)

		-- 记录表现后还原
		if isAttacting then
			self.sprite._opacity = self.sprite:opacity()
			self.sprite:opacity(255)
		else
			self.sprite:opacity(self.sprite._opacity)
		end
	end}, noQueue)
end

function BattleSprite:onDead(effectRes, callback)
	self:setDebugEnabled(false)
	self:setEffectDebugEnabled(false)

	if not self.actionTable[battle.SpriteActionTable.death]:empty() then
		-- 有死亡动画播动画
		-- self:setActionState(battle.SpriteActionTable.death)
		self:onAddEventEffect('effect', {action=battle.SpriteActionTable.death, onComplete = callback})
		return
	end

	-- 一般单位死亡
	effectRes = effectRes or "effect/death.skel"
	local removeSprite = function ()
		-- 清空战斗场景的死亡特效
		if self.battleView.deathCache ~= nil then
			for _, v in ipairs(self.battleView.deathCache) do
				v:removeSelf()
			end
			self.battleView.deathCache = {}
		end
	end
	local hitPos = self.unitCfg.everyPos.hitPos

	self.lifebar:setVisible(false)

	-- todo 播放一个死亡动画
	transition.executeSequence(self.sprite)
		:fadeOut(0.4)
		:done()
	transition.executeSequence(self.sprite)
		:delay(0.1)
		:moveBy(1.2, hitPos.x, hitPos.y)
		:done()
	transition.executeSequence(self.sprite)
		:delay(0.1)
  		:scaleTo(1, 0.01)
  		:func(removeSprite)
  		:func(callback or function() end)
  		:done()

	local sprite = newCSprite(effectRes)
	self:add(sprite)
	arraytools.push(self.battleView.deathCache, sprite)
	sprite:setLocalZOrder(999999)
	sprite:anchorPoint(0.5, 0.5):scale(2)
	sprite:play("effect")
	sprite:setTimeScale(1.15)
end

-- 播放被点击的动作动画
function BattleSprite:onBeAttackPlayAni()
	self:play("beAttack")
	self:setSpriteEventHandler(function(event, eventArgs)
		if event == sp.EventType.ANIMATION_COMPLETE then
			self:play("standby_loop")
		end
	end)
end


function BattleSprite:onDealBuffEffectsMap(iconResPath, cfgId, isIconFrame)
	return gRootViewProxy:notify('dealBuffEffectsMap', self, iconResPath, cfgId, isIconFrame)
end

-- 头顶上的buff图标们
function BattleSprite:onShowBuffIcon(iconResPath, cfgId, overlayCount)
	return gRootViewProxy:notify('showBuffIcon', self, iconResPath, cfgId, overlayCount)
end

-- 头顶上的buff飘字
function BattleSprite:onShowBuffText(textResPath)
	return gRootViewProxy:notify('showBuffText', self, textResPath)
end

-- 被免疫buff的飘字
function BattleSprite:onShowBuffImmuneEffect(group)
	local groupRelation = gBuffGroupRelationCsv[group]
	if groupRelation and groupRelation.immuneEffect then
		gRootViewProxy:notify('showBuffText', self, string.format(battle.ShowHeadNumberRes.txtTypeImmune,groupRelation.immuneEffect))
	end
	return
end

-- 更换战斗场景
function BattleSprite:onAlterBattleScene(args)
	self.battleView:onEventEffect(nil, 'callback', {func = function()
		gRootViewProxy:notify('alterBattleScene', args)
	end, delay = args.delay or 0})
end

-- 天气刷新
function BattleSprite:onWeatherRefresh(buff)
	return gRootViewProxy:notify('weatherRefresh', self, buff)
end

-- 删除图标
function BattleSprite:onDelBuffIcon(cfgId)
	return gRootViewProxy:notify('delBuffIcon', self, cfgId)
end

-- 表现函数，扣血， 1:加血, 2:吸收
function BattleSprite:onShowHeadNumber(args)
	return gRootViewProxy:notify('showHeadNumber', self, args)
end
-- 表现函数, 单位飘字
function BattleSprite:onShowHeadText(args)
	local parms = args.args
	local delay = (parms.delay or 0)

	-- 闪避的时候，角色增加一个闪避效果，
	-- 增加一个闪避的抖动效果
	if parms.miss then
		local backTime = 0.15  			-- 后退时间
		local backX = - 40*self.faceTo  -- x轴偏移量
		local backY = 0					-- y轴偏移量
		local backDelay = 0.1			-- 后退之后和回归原位的延迟时间
		-- 后退效果
		transition.executeSequence(self)
			:delay(delay)
			:moveBy(backTime, backX, backY)
			:delay(backDelay)
			:moveBy(backTime, -backX, -backY)
			:done()
	end
	return gRootViewProxy:notify('showHeadText', self, args)
end

function BattleSprite:onShowBuffContent(contentRes)
	if not contentRes or contentRes == '' then return end
	if not self then return end
	local sprite = newCSprite(contentRes)
	if not sprite then return end

	-- buff文字的位置随角色移动
	self:add(sprite, 9999)
	-- buff文字的位置可以通过配置调整
	local pos = self.unitCfg.everyPos.hitPos
	sprite:setPosition(pos)
	-- 停1会儿 上浮 消失
	local function remove()
		removeCSprite(sprite)
	end
 	transition.executeSequence(sprite)
		:delay(1)
		--:moveBy(2, 0, 120)
		:fadeOut(0.25)
  		:func(remove)
  		:done()
end

function BattleSprite:onUpdateLifebar(args)
	if args.skillType == battle.SkillType.NormalSkill and args.mainSkillType ~= battle.MainSkillType.BigSkill then
		self.lifebar:setVisible(true)
	end
	self.lifebar:update(args)
end

function BattleSprite:showSkillSelectTextState(targetType, restraintType,immuneInfo)
	--  标记哪些克制效果可以显示，(友方不显示, 只显示选中的提示外圈)
	local res
	if targetType == 0 then
		--res = nil
	elseif immuneInfo then
		res = battle.RestraintTypeIcon[immuneInfo]
	else
		res = battle.RestraintTypeIcon[restraintType]
	end


	-- 指示光圈里面再显示克制内容
	self.natureQuan:show()
	self.natureQuan.textDi:hide()
	if res then
		self.natureQuan.textDi:show()
		self.natureQuan.textDi:loadTexture(res)
	end
end

function BattleSprite:beHit(delta, init)
	if init then
		self.beHitTime = init
		if self.beHitTime > 0 then
			self:setActionState(battle.SpriteActionTable.hit)
		end
	else
		self.beHitTime = self.beHitTime - delta
		if self.beHitTime <= 0 then
			self:setActionState(battle.SpriteActionTable.standby)
		end
	end
end

function BattleSprite:getLeftBeHitTime()
	return self.beHitTime or 0
end

function BattleSprite:onReloadUnit(layerName)
	self:reloadUnit()
    if layerName then
        self:addToLayer(layerName)
    end
end

function BattleSprite:onShowHeldItemEffect(itemId)
	local itemCfg = csv.held_item.items[itemId]
	local iconRes = itemCfg.icon
	local quality = itemCfg.quality
	local hitPos = self.unitCfg.everyPos.hitPos
	local x = hitPos.x
	local y = hitPos.y + 150
	local panel = ccui.Layout:create()
	:size(300,300)
	:anchorPoint(0.5,0)
	:xy(self:getPositionX() + x, self:getPositionY() + y)
	:z(battle.SpriteLayerZOrder.qipao + 10)
	:addTo(self.battleView.gameLayer)
	local effPath = "daojuchufa/daojuchufa.skel"
	local effect = newCSprite(effPath)
	if not effect then return end
	local aniName = "effect"
	effect:play(aniName)
	effect:setSpriteEventHandler(function(_type, event)
		if _type == sp.EventType.ANIMATION_COMPLETE then
			removeCSprite(effect)
		end
	end)
	effect:setPosition(cc.p(150,150))
	panel:addChild(effect, 1)
	local boxRes = ui.QUALITY_BOX[quality]
	local fgRes = string.format("common/icon/panel_icon_k%d.png", quality)
	local box = ccui.ImageView:create(boxRes)
	:xy(150,100)
	:z(2)
	:hide()
	:addTo(panel)
	local icon = ccui.ImageView:create(iconRes)
	:xy(150,100)
	:z(3)
	:scale(2)
	:hide()
	:addTo(panel)
	local fg = ccui.ImageView:create(fgRes)
	:xy(150,100)
	:z(4)
	:hide()
	:addTo(panel)
	transition.executeSequence(panel)
	:delay(0.3)
	:func(function()
		box:show()
		icon:show()
		fg:show()
	end)
	:moveBy(0.4, 0, 70)
	:delay(1.3)  -----消失
	:func(function ()
		panel:removeFromParent()
	end)
	:done()

	-- body
end

function BattleSprite:onShowCounterAttackText(key)
	self.battleView:onEventEffect(nil, 'callback', {func = function()
		self:onShowBuffText(battle.ShowHeadNumberRes.txtFj)
	end, delay = 0})
end

function BattleSprite:onPlayCharge(args,isOver)
	if not args then return end
	if isOver then
		self:onPopAction(battle.SpriteActionTable.standby,"charge")
		if args.endCharing then
			table.insert(self.battleView.effectJumpCache,self:onAddEventEffect('effect', {
				action=args.endCharing.action,
				lifetime=args.endCharing.lifeTime,
				onComplete = function()
					self:onPlayState(battle.SpriteActionTable.standby)
				end
			}))
		else
			self:onPlayState(battle.SpriteActionTable.standby)
		end
	else
		self:onPushAction(battle.SpriteActionTable.standby,args.charing.action,"charge")
		if args.startCharing then
			table.insert(self.battleView.effectJumpCache,self:onAddEventEffect('effect', {
				action=args.startCharing.action,
				lifetime=args.startCharing.lifeTime,
				onComplete = function()
					if args.charing then
						self:onPlayState(battle.SpriteActionTable.standby)
					end
				end
			}))
		else
			self:onPlayState(battle.SpriteActionTable.standby)
		end
	end
end

-- 移动位置筛选(目标移动到某个位置处或者某个目标身前,是目标时返回目标posid)
-- 修改为以第一个过程段的目标来选择, 这样填写正确的话是一定能选出确定的目标来的
-- 0-屏幕中央  1-单体 2-横排前排  3-横排后排  4-竖排  5-原地  6-竖排前方(固定)  7-竖排后方目标  8-横排中心固定(这里没有前后排的区分了)
-- 6 竖排位置的前方的(位置固定,不管前排有没有目标存在)， 7竖排后方目标(后排无目标为前排，位置不固定)
function BattleSprite:getMoveToTargetPos(skillCfg, targets)
	local posChoose = skillCfg.posChoose
	-- 0-屏幕中央, 5-原地
	if posChoose == 0 then return battle.AttackPosIndex.center end
	if posChoose == 5 then return battle.AttackPosIndex.selfPos end

	-- 初始化为原位置
	local posIdx = battle.AttackPosIndex.selfPos
	if table.length(targets) > 0 then
		local targetViews = {}
		local spr
		for _, obj in ipairs(targets) do
			spr = self.battleView:onViewProxyCall("getSceneObjById",obj.id) or obj
			table.insert(targetViews,{
				seat = spr.seat,
				force = spr.force
			})
		end
		-- 1-单体
		-- 4-竖排
		if posChoose == 1 or posChoose == 4 then
			posIdx = targetViews[1].seat

		-- 6-位置固定在前排的目标, 1、2、3竖排
		elseif posChoose == 6 then
			local idx = targetViews[1].seat
			local column = (idx-1)%3+1
			posIdx = (idx > 6) and (column + 6) or column

		-- 7-竖排后方的
		elseif posChoose == 7 then
			posIdx = targetViews[table.length(targetViews)].seat

		-- 8-横排固定中心的
		elseif posChoose == 8 then
			local idx = targetViews[1].seat
			local row = (math.floor((idx+2)/3)-1)%2+1	-- 行数
			local seat = 2+ (row-1)*3
			posIdx = (idx > 6) and (seat + 6) or seat

		-- 常规横排类型的
		-- 2-横排前排
		-- 3-横排后排
		else
			local idx = 0
			local cnt = 0
			for _, spr in ipairs(targetViews) do
				local isAttack = skillCfg.hintTargetType == 1
				local curTargetIsChooseTarget 	-- 攻击敌方的技能不应该被其中治疗己方的过程段影响其释放位置 反之治疗技能也不能被攻击过程影响
				if isAttack then
					curTargetIsChooseTarget = spr.force ~= self.force
				else
					curTargetIsChooseTarget = spr.force == self.force
				end
				if curTargetIsChooseTarget then
					local column =(spr.seat-1)%3+1
					if column == 2 then
						return spr.seat
					end
					idx = idx + spr.seat
					cnt = cnt + 1
				end
			end
			-- posIdx = math.floor(idx/#targets)
			if cnt > 0 then
				posIdx = math.floor(idx/cnt)
			else
				printWarn("no targets be choose in targets %d when posChoose %d", table.length(targets), posChoose)
			end
		end
	end
	logf.battle.skill('移动到目标位置: posIdx= %s', posIdx)
	return posIdx
end

-- 移除场外 召唤回场内 修改状态
function BattleSprite:onStageChange(status)
	-- self:setVisible(status)
	-- self:setVisibleEnable(status)
	self.seat = self.model.seat
	self:resetPos()
	self:updHitPanel()
	self:onAddToScene()
end

function BattleSprite:onRecordOrderData(type, args)
	if not self.recordOrderDataTb[type] then
		self.recordOrderDataTb[type] = CVector.new()
	end
	self.recordOrderDataTb[type]:push_back(args)
end

-- 逃跑动画
function BattleSprite:onEscape(args)
	local x, y = 0, 0
	if self.seat <= 6 then
		x = -display.width / 2
		y = battle.StandingPos[self.seat].y
	else
		x = display.width * 1.5
		y = battle.StandingPos[self.seat - 6].y
	end
	self:onAddEventEffect('moveTo', {
		speed=150, a=100,
		delayMove = args.delayMove or 0,
		costTime = args.costTime or 1000,
		x=x, y=y,
		changeFaceTo = -1*self.faceTo
	}, false)
end

-- 跳过一波 清除所有动画
function BattleSprite:onPassOneWaveClean()
	self:setActionState(battle.SpriteActionTable.standby)

	for k,v in ipairs(self.effectJumpCache) do
		self:onEventEffectCancel(v)
	end
	self.effectJumpCache = {}

	self.effectManager:passOneWaveClear()

	for key, sprite in pairs(self.buffEffectsMap) do
		removeCSprite(sprite)
	end
	self.buffEffectsMap = {}
	self.buffEffectsRef = {}
end