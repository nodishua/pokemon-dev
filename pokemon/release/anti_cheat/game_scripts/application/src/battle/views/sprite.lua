--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2016 TianJi Information Technology Inc.
--
-- 战斗用BattleSprite
--
-- 除了sprite之外会附在血条等额外显示
-- 这里与cc.Node同名函数重载，均作用于sprite
--

require "easy.sprite"
require "battle.views.lifebar"


globals.BattleSprite = class("BattleSprite", cc.Node)

function globals.newCSpriteWithOption(aniRes, ...)
	local sprite = newCSprite(aniRes, ...)
	local config = gEffectOptionCsv[aniRes]
	if sprite:isSpine() and config then
		sprite:getAni():setTwoColorTint(config.tintBlack)
	end
	return sprite
end

function BattleSprite:ctor(battleView, model, key, args)
	self.battleView = battleView
	self.model = model
	self.key = key
	self.args = args
	self.type = args.type
	self.spineEventMap = {} -- {event id: {effectID=effect_event.id, processID=}}
	self.debug = {enabled = false}
	self.effectDebug = {enabled = false}
	self.relationshipStatus = "showRelationship"
	-- onChangeActionTable可能会替换
	self.actionTable = {}
	-- 可能会被附身替换
	-- self.replaceView = CMap.new()
	self.skillSceneTag = CVector.new()
	-- 跟随的sprite
	self.followSprite = {} -- [key] = sprite
	self.replaceView = nil

	self.canSetVisible = true
	self.refreshBuffIconOnce = false
	self.skillJumpSwitchOnce = false
	self.recordOrderDataTb = {}
	self.lockEffectSwitch = true

	self.skins = CVector.new()
	self:resetActionTab()
end

function BattleSprite:init()
	---------
	-- from ObjectModel
	self:initUnitData()
	-- self.cardCfg = dataEasy.getCardCfg(self.unitCfg)
	-- 按照之前的数据返回 如果是怪物数据能获取的数据都在unitCfg里面可以获取到
	-- 现在默认就是cards里面的数据
	self.monsterCfg = self.model.monsterCfg
	self.force = battleEasy.getForce(self.seat)
	self.forceFaceTo = (self.force == 1) and 1 or -1		-- 保存原始的面向
	self.faceTo = self.forceFaceTo
	self.posAdjust = self:getPosAdjust()
	self.actionState = 'run'
	self.beHitTime = 200 --受击动画的时间,临时加一个值,200一个小分段好像是可以

	if self.monsterCfg and self.monsterCfg.posAdjust and self.monsterCfg.posAdjust[self.seat-6] ~= 0 then
		self.posAdjust.x = self.monsterCfg.posAdjust[self.seat-6].x
		self.posAdjust.y = self.monsterCfg.posAdjust[self.seat-6].y
	end

	local posx, posy = self:getSelfPos()
	self.posXY = cc.p(posx, posy)
	self.posZ = posy
	self._scale = nil
	self._scaleX = nil
	self._scaleY = nil
	self.battleMovePosZ = 0		-- 战斗时敌方移动到与自己水平的线上,因为前后排有1点的posz

	self.effectManager = battleEffect.Manager.new('BattleSprite.' .. self.model.id)
	self.effectProcessArgs = {} -- {processID: {target model, ..}}

	self:loadSprite(self.unitCfg.unitRes, battle.SpriteLayerZOrder.selfSpr)

	-- spine动作特殊缩放
	self.spineActionScales = {}
	self.spinePrevAction = nil
	-- 技能播放不受scaleC修正影响
	if self.unitCfg.scaleCMode == 2 then
		for _, skillID in csvPairs(self.unitCfg.skillList) do
			local skillCfg = csv.skill[skillID]
			if skillCfg and skillCfg.spineAction then
				self.spineActionScales[skillCfg.spineAction] = self.unitCfg.scale
			end
		end
	end

	self:initLifeBar()
	-- 技能克制效果的指示光圈  还有文字和底图(或许放到角色身上更好点)
	self:initNatureQuan()
	-- 出战光圈
	self:initGroundRing()

	self:setPosition(self.posXY)
	self.buffEffectMap = CMap.new() --key:特效路径,val:特效数量.为了保证同个特效只显示一个
	self.buffEffectSpriteMap = CMap.new()  --key:特效路径,val:sprite

	self.buffEffectsMap = {}		-- 保存下自身的effec和sprite的对应
	self.buffEffectsRef = {}        -- sprite 的引用计数
	-- self.buffIconsCntIdTb = {}		-- 保存对应的icon id 格式：{cntid}
	self.buffEffectHolderMap = {}
	self.buffEffectsFollowObjToScale = {}

	self.specBindEffectCache = {}
	self.effectJumpCache = {}
	-- hitPanel
	self.startYinyingPos = self.sprite:getBonePosition("yinying")
	self:updHitPanel()
end

function BattleSprite:initLifeBar()
	-- 血条
	self.lifebar = CLifeBar.new(self.model, self.battleView)
	self:add(self.lifebar, battle.SpriteLayerZOrder.lifebar, "lifebar")
end

function BattleSprite:initNatureQuan()
	self.natureQuan = cc.Node:create()
	self.natureQuan:hide():anchorPoint(0.5, 1):xy(self.unitCfg.everyPos.hitPos)
	self:add(self.natureQuan, battle.SpriteLayerZOrder.quan, "nature_quan")

	-- 指示光圈里面的文字和底图, 又加了一个图标
	local size = self.natureQuan:getContentSize()
	local textDi = ccui.ImageView:create(battle.SpriteRes.natureQuanTxtDi) -- 中间的文字区域底图
	textDi:addTo(self.natureQuan, -5)
		:xy(size.width/2, size.height/2)
	self.natureQuan.textDi = textDi
	newCSprite(battle.SpriteRes.natureQuan)
		:addTo(self.natureQuan, 1)
		:xy(size.width/2, size.height/2)
		:play("xuanzhong_loop")
end

function BattleSprite:initGroundRing()
	-- widget.addAnimation(self, battle.SpriteRes.groundRing, "effect_loop", battle.SpriteLayerZOrder.ground)
	self.groundRing = newCSprite(battle.SpriteRes.groundRing)
	self.groundRing:addTo(self, battle.SpriteLayerZOrder.ground)
		:hide()
		:play("effect_loop")
end

function BattleSprite:initUnitData()
	self.id = self.model.id
	self.seat = self.model.seat
	self.unitID = self.model.unitID
	self.unitCfg = csv.unit[self.unitID]
	self.unitSpecBind = self.unitCfg.specBind
	self.unitRes = self.model.unitRes or self.unitCfg.unitRes -- 外部改变初始化的精灵对象
	self.cardID = self.model.cardID
	self.cardCfg = csv.cards[self.unitCfg.cardID]
end
-- TODO: 实际生效的坐标
function BattleSprite:getSeat()
	return self.seat
end

function BattleSprite:loadSprite(res,zOrder,args)
	if res then
		self.sprite = newCSprite(res)
        self.sprite:setPosition(cc.p(0,0))
		self.sprite:setSpriteEventHandler(handler(self, self.onSpriteEvent))
		self:add(self.sprite, zOrder)
		self:setScale(1)
		self:setSkin(args)
	end
end

function BattleSprite:reloadUnit(args)
    -- 防止从缓存池中取出时坐标被改变
	local resetPos = cc.p(self.sprite:getPositionX(),self.sprite:getPositionY())
	local visible = self.sprite:isVisible()
	self.sprite:removeAnimation()

	self:initUnitData()
	self._scale = nil
	self._scaleX = nil
	self._scaleY = nil
    self.actionState = 'run'

	self:loadSprite(self.unitRes, battle.SpriteLayerZOrder.selfSpr, args)
	self.sprite:setPosition(resetPos)
	self.sprite:setVisible(visible)
    self:setActionState(battle.SpriteActionTable.standby)
end

function BattleSprite:addToLayer(layerName)
    local layer = self.battleView[layerName]
    if layer then
        self:retain()
        self:removeFromParent()
        layer:add(self,999)
        self:release()
    end
end

function BattleSprite:updateLifeBarState(isShow)
    self.lifebar:setVisible(isShow)
    self.lifebar.canSetVisible = isShow
end

function BattleSprite:pauseAnimation()
	self.isPausing = true
	if self.sprite then
		self.sprite:pause()
	end
	for k,v in pairs(self.buffEffectsMap) do
		v:pause()
	end
end

function BattleSprite:resumeAnimation()
	self.isPausing = nil
	if self.sprite then
		self.sprite:resume()
	end
	for k,v in pairs(self.buffEffectsMap) do
		v:resume()
	end
end

function BattleSprite:getFaceTo()
	return self.faceTo
end

--方便查显示问题
-- function BattleSprite:setVisible(visible)
-- 	print("BattleSprite:setVisible",self.id,visible)
--
-- 	print(debug.traceback("Stack trace"))
--
-- 	cc.Node.setVisible(self,visible)
-- end

-- 危险 请勿使用
function BattleSprite:pauseSprite()
	self.isPausing = true
	if self.sprite then
		self.sprite:pause()
	end
end

function BattleSprite:resumeSprite()
	self.isPausing = nil
	if self.sprite then
		self.sprite:resume()
	end
end

function BattleSprite:setPlaySpeed(val)
	if self.sprite then
		self.sprite:setAnimationSpeedScale(val)
	end
end

function BattleSprite:setSpriteOpacity(opacity)
	self.sprite:setCascadeOpacityEnabled(true)
	self.sprite:setOpacity(opacity)
	self.sprite._opacity = opacity
end

function BattleSprite:objToBlank(args)
	transition.executeSequence(self)
		:scaleTo(args.startLast/1000, args.scale)
		:delay(args.delayLast/1000)
		:scaleTo(args.endLast/1000, 1)
		:done()
end

function BattleSprite:objToHideEff(flag)
	-- 如果身上没有锁的buff 走进入的原逻辑, 否则隐藏除showEffect为true的Effect
	flag = battleEasy.ifElse(self.lockEffectSwitch, flag, true)
	for _, v in pairs(self.buffEffectsMap) do
		local isShow = v.showEffect or not flag
		-- 优先应用holderAction的显隐
		if v.holderActionVisible ~= nil then
			isShow = v.holderActionVisible
		end
		v:setVisible(isShow)
	end

	for _, v in pairs(self.followSprite) do
		v:objToHideEff(flag, self)
	end

	gRootViewProxy:notify('setBuffIconVisible', self, true)
end

function BattleSprite:setGLProgram(programName)
	self.sprite:setGLProgram(programName)
	for k,v in pairs(self.buffEffectsMap) do
		v:setGLProgram(programName)
	end
end

function BattleSprite:setScale(value, force)
	self.scaleX = nil
	self.scaleY = nil
	cc.Node.setScale(self, 1) -- 在此需调用原本的 防止变化
	if value ~= self._scale or force then
		self._scale = value
		-- self.sprite:setScale(value)
		self:setScaleX(self.faceTo * value, force)
		self:setScaleY(value, force)
	end
end

-- 针对只设置方向，不设置缩放的特殊接口
-- 这个接口影响面比setScaleX小
-- @prame faceTo: 朝向的绝对值
function BattleSprite:setShowFaceTo(faceTo)
	if faceTo > 0 and self._scaleX > 0 then return end
	if faceTo < 0 and self._scaleX < 0 then return end

	if self._scaleX or self._scaleX == 0 then
		self._scaleX = faceTo > 0 and 1 or -1
	else
		self._scaleX = -self._scaleX
	end
	local sx = self.sprite:getScaleX()
	self.sprite:setScaleX(-sx)
end

function BattleSprite:setScaleX(value, force)
	cc.Node.setScaleX(table.getraw(self), 1) -- 在此需调用原本的 防止变化
	-- if not force then
	-- 	value = value * self.unitCfg.scaleX
	-- end
	if value ~= self._scaleX or force then
		self._scaleX = value
		self.sprite:setScaleX(value * self.unitCfg.scaleX * self.unitCfg.scale * self.unitCfg.scaleC)
	end
end

function BattleSprite:setScaleY(value, force)
	cc.Node.setScaleY(table.getraw(self), 1) -- 在此需调用原本的 防止变化
	if value ~= self._scaleY or force then
		self._scaleY = value
		self.sprite:setScaleY(value * self.unitCfg.scale * self.unitCfg.scaleC)
	end
end

function BattleSprite:getScale()
	return self._scale or 1
end

function BattleSprite:getScaleX()
	return self._scaleX or 1
end

function BattleSprite:getScaleY()
	return self._scaleY or 1
end

--------------
-- from model

function BattleSprite:getMovePosZ()
	return self.battleMovePosZ
end

function BattleSprite:getSelfPos()
	local seat = self:getSeat()
	local x, y
	if  seat < 0 then
		x, y = battle.StandingPos[99].x, battle.StandingPos[99].y
	elseif seat <= 6 or seat > 12 then -- 统一规则
		x, y = battle.StandingPos[seat].x, battle.StandingPos[seat].y
	else
		x, y = display.width-battle.StandingPos[seat-6].x, battle.StandingPos[seat-6].y
	end
	return x+self.posAdjust.x, y+self.posAdjust.y
end

-- 保存当前坐标位置
function BattleSprite:setCurPos(ccpos)
	self.posXY = ccpos
end

--获取目标当前所在的位置
function BattleSprite:getCurPos()
	return self.posXY.x, self.posXY.y
end

function BattleSprite:curPosEqual(x, y)
	return self.posXY.x == x and self.posXY.y == y
end

-- 获得攻击的显示位置
function BattleSprite:getAttackPos(posIdx, adjust, attackFriendFix)
	local seat = self:getSeat()
	local x, y
	local attackFriendFaceto = attackFriendFix and -1 or 1	--攻击友方时的面向调整
	if posIdx == battle.AttackPosIndex.selfPos then
		return self:getSelfPos()
	elseif posIdx <= 6 or posIdx == battle.AttackPosIndex.center then
		x, y = battle.AttackPos[posIdx].x, battle.AttackPos[posIdx].y
	else
		x, y = display.width-battle.AttackPos[posIdx-6].x, battle.AttackPos[posIdx-6].y
	end
	-- 有缩放修正，要对x偏移修正
	local scaleC = 1
	if self.unitCfg.scaleCMode == 1 then
		scaleC = self.unitCfg.scaleC
	end
	x, y = x+self.faceTo*adjust.x*scaleC*attackFriendFaceto, y+adjust.y-1
	return x, y
end

-- 保护的显示位置 posIdx为1-12 对应的身前位置
function BattleSprite:getProtectPos(posIdx,adjust)
	local x, y
	if posIdx <= 6 or posIdx >= 13 then
		x, y = battle.ProtectPos[posIdx].x, battle.ProtectPos[posIdx].y
	else
		x, y = display.width-battle.ProtectPos[posIdx-6].x, battle.ProtectPos[posIdx-6].y
	end
	local scaleC = 1
	if self.unitCfg.scaleCMode == 1 then
		scaleC = self.unitCfg.scaleC
	end
	x, y = x+self.faceTo*adjust.x*scaleC, y+adjust.y-1
	return x+self.posAdjust.x, y+self.posAdjust.y
end

-- 更新 点击面板的位置
function BattleSprite:updHitPanel()
	local panel = self.battleView:onViewProxyCall("getObjHitPanel", self.seat)
	if panel then
		panel:setVisible(true)
		panel:setEnabled(true)
		panel:setTouchEnabled(true)
		--panel:setAnchorPoint(cc.p(0.5, 0.5))
		--用于检查位置
		-- panel:setBackGroundColorType(1)
		-- panel:setBackGroundColor(cc.c3b(200, 0, 0))
		-- panel:setBackGroundColorOpacity(100)
		local posx, posy = self:getSelfPos()
		local hitPos = self.model.unitCfg.everyPos.hitPos
		posx = posx + hitPos.x
		posy = posy + hitPos.y
		panel:setAnchorPoint(0.5,0)
		panel:setPosition(posx, posy)

		local size = self.model.unitCfg.rectSize
		panel:setContentSize(cc.size(size.x, size.y))
	end
end

-- come from BattleView:onUpdate :onViewProxyNotify("update", delta)
-- so only view effect in here be updated
function BattleSprite:onUpdate(delta)
	return self.effectManager:update(delta)
end

-- 替换一般动作表中的动作名
-- 有对应popAction的需要增加from
function BattleSprite:onPushAction(state, action, from)
	if self.actionTable[state] == nil then
		self.actionTable[state] = CList.new()
	end
	-- printDebug("onPushAction",state,action)
	self.actionTable[state]:push_front({
		action = action,
		from = from,
	})
end

function BattleSprite:onPopAction(state, from)
	-- printDebug("onPopAction",state)
	for k,v in self.actionTable[state]:pairs() do
		if v.from == from then
			self.actionTable[state]:erase(k)
			break
		end
	end
end

function BattleSprite:getActionName(state)
	local data = self.actionTable[state] and self.actionTable[state]:front()
	return data and data.action
end

local MustBeCompleteActions = {
	attack = true,
	skill1 = true,
	skill2 = true,
	skill3 = true,
}
-- 设置人物动作
function BattleSprite:setActionState(state, onComplete)
	if not state then return end
	if self.actionState == "win_loop" then return end
	if self.actionState == state then
		if not battle.LoopActionMap[state] then
			if not self.actionCompleteCallback then
				self.actionCompleteCallback = onComplete
			end
			self:onPlayState(state)
		end
		return
	end

	-- TODO: callback按sprite保存还是按action来保存？
	if self.actionCompleteCallback then
		-- if MustBeCompleteActions[self.actionState] then
		-- 	errorInWindows("action %s not be completed, now play %s !!!", self.actionState, state)
		-- end
		self.actionCompleteCallback()
	end
	self.actionState = state
	self.actionCompleteCallback = onComplete
	self:onPlayState(state)
end

function BattleSprite:onPlayState(state)
    if not state then return end
	local action = self:getActionName(state) or state
    self.sprite:play(action)
end

-- 为在setActionState之后增加onComplete用
function BattleSprite:addActionCompleteListener(cb)
	self.actionCompleteCallback = self.actionCompleteCallback and callbacks.new(self.actionCompleteCallback, cb) or cb
	return self.actionCompleteCallback
end

function BattleSprite:showGuide(str, lastTime, cb)
	local w = 368
	local h = 162
	if not self.qipao then
		self.qipao = newCSprite()
		self.qipao:setContentSize(cc.size(w, h))
		local lpos = self.unitCfg.everyPos.lifePos
		self.qipao:addTo(self.battleView.gameLayer, battle.SpriteLayerZOrder.qipao)
			:xy(cc.p(self:getPositionX() + lpos.x, self:getPositionY() + lpos.y + 20)):anchorPoint(1, 0)

		local qipaoDi = cc.Scale9Sprite:create("city/gate/bg_dialog.png")
		qipaoDi:setCapInsets(CCRectMake(40, 60, 1, 1))
		qipaoDi:size(cc.size(w, h))
		qipaoDi:xy(cc.p(w/2, h/2))
		self.qipao:add(qipaoDi)
		if self.force == 1 then
			qipaoDi:setScaleX(-1)
			self.qipao:xy(cc.p(lpos.x + w, lpos.y + 20))
		end
	end
	self.qipao:show()
	self.qipao:removeChildByName("richText")

	local richtext = rich.createWithWidth("#C0x5b545b#" .. str, 30, deltaSize, w - 35)
	richtext:setAnchorPoint(cc.p(0, 1))
	local height = richtext:getContentSize().height
	richtext:xy(25, h - (h - 17 - height) / 2)
	self.qipao:add(richtext, 3, "richText")

	transition.executeSequence(self.qipao)
		:delay((lastTime or 1000)/1000.0)
		:func(function()
			if self.qipao then
				self.qipao:hide()
			end
			if cb then
				cb()
			end
		end)
		:done()
end

-- 技能结束给单位恢复显示状态
-- 统一恢复，防止技能混乱带来的BUG
function BattleSprite:resetPos()
	self:setVisible(true)
	self:setLocalZOrder(self.posZ)
	self:setRotation(0)		--默认恢复 原来的角度
	self:stopAllActions()
	self:setActionState(battle.SpriteActionTable.standby)
	self:moveToPosIdx(self:getSeat())
	self:setScaleX(self.forceFaceTo)
	self:setScaleY(1)
end

function BattleSprite:resetActionTab()
	for _, action in pairs(battle.SpriteActionTable) do
		-- todo 对于一般单位 没有死亡动画 所以不能一开始就配置
		self.actionTable[action] = CList.new()
		if action ~= battle.SpriteActionTable.death then
			self:onPushAction(action, action)
		end
	end
end

-- todo 这个字段未来可以升级为状态机
-- 目前只用于检测是否处于返回动画中
function BattleSprite:isComeBacking(bool)
	if bool ~= nil then
		self.comeBacking = bool
	end
	return self.comeBacking
end

function BattleSprite:setSkin(args)
	if not args then args = {buffId = -1, isRestore = false} end
	args.skinName = args.skinName or self.unitCfg.skin
	if args.isRestore then
		for k, v in self.skins:ipairs() do
			if v.buffId == args.buffId then
				self.skins:erase(k)
				if k <= self.skins:size() then return end
				break
			end
		end
	else
		self.skins:push_back(args)
	end
	local skinName = self.skins:back() and self.skins:back().skinName
	if not skinName then return end
	local ani = self.sprite:getAni()
	ani:setSkin(skinName)
	ani:setToSetupPose()
end

function BattleSprite:stopAllHolderAction()
	for typ, effect in pairs(self.buffEffectHolderMap) do
		if effect.isPlayId then
			-- 正在播放中,寻找正在播放的data
			for _,v in effect.datas:pairs() do
				if v.id == effect.isPlayId then
					-- 只停止播放特效,并不删除
					self:onPlayBuffHolderAction(typ, v, true)
					effect.isPlayId = nil
					break
				end
			end
		end
	end
end

function BattleSprite:onSetSpriteVisible(visible)
	self.sprite:setVisible(visible)
end

function BattleSprite:getSpriteVisible()
	return self.sprite:isVisible()
end

function BattleSprite:getPosAdjust()
	local offsetPos = self.args.offsetPos or cc.p(0, 0)
	return cc.p(self.forceFaceTo * offsetPos.x, offsetPos.y)
end

function BattleSprite:updateFaceTo(force)
	self.force = force
	self.forceFaceTo = (self.force == 1) and 1 or -1
	self.faceTo = self.forceFaceTo
	self:setScaleX(self.forceFaceTo)
end

function BattleSprite:alterLockEffectRecord(isOver)
	self.lockEffectSwitch = isOver
end

function BattleSprite:setVisibleEnable(enable)
	self.canSetVisible = enable
end

function BattleSprite:setVisible(visible)
	if not self.canSetVisible then
		return
	end

	cc.Node.setVisible(table.getraw(self), visible)
end

-- view: 替换的view,
-- tag: 场景
-- 简单处理
function BattleSprite:addReplaceView(view, tag)
	-- local ret = self.replaceView:find(tag)
	-- if not ret then
	-- 	ret = CVector.new()
	-- 	self.replaceView:insert(tag, ret)
	-- end
	-- ret:push_back(view)
	self.replaceView = view
end

function BattleSprite:removeReplaceView(view)
	self.replaceView = nil
end

function BattleSprite:checkSceneTag(tag)
end

function BattleSprite:getRealUseView()
	local view = self
	if self.replaceView and self.replaceView:checkSceneTag(self.skillSceneTag:back()) then
		view = self.replaceView
	end
	return view
end

-- local SkillSceneChangeFuncMap = {
-- 	[battle.SpriteSkillSceneTag.None] = function(battleSprite)

-- 	end
-- }
-- 目前只考虑进入的情况
function BattleSprite:pushApplySkillSceneTag(args)
	-- if self.skillSceneTag:empty() or self.skillSceneTag:back() ~= tag then
	-- 	if SkillSceneChangeFuncMap[tag] then
	-- 		SkillSceneChangeFuncMap[tag](self)
	-- 	end
	-- end
	self.skillSceneTag:push_back(args)
	-- 当前tag下不是本体在生效
	-- if self ~= self:getRealUseView() then
	-- 	self:getRealUseView():setDirty(true)
	-- end
end

function BattleSprite:popApplySkillSceneTag()
	-- if self ~= self:getRealUseView() then
	-- 	self:getRealUseView():setDirty(false)
	-- end
	self.skillSceneTag:pop_back()
end

function BattleSprite:showHero(isShow, args)
	if args.obj then
		-- 显示出战光圈
		self.groundRing:setVisible(isShow and (self.key == args.obj))
	end
	self.lifebar:setVisible(isShow and not args.hideLife)
	self:setVisible(isShow)
end

-- TODO: 可以统一管理跟随对象的属性？
function BattleSprite:addFollowSpr(spr, args)
	self.followSprite[spr.key] = spr
end

function BattleSprite:removeFollowSpr(spr)
	self.followSprite[spr.key] = nil
end

function BattleSprite:sceneDelFollowObj(layer)
	-- 删除附身
	for _, FollowSpr in pairs(self.followSprite) do
		gRootViewProxy:notify('sceneDelObj', FollowSpr.key)
	end
end

function BattleSprite:sceneDelObj(layer)
	self:unscheduleUpdate()
	self:retain()
	self:sceneDelFollowObj(layer)
	self:removeSelf()
	layer:addChild(self)
	self:release()
end

-- function BattleSprite:objToHideEffOther(isAttacting)
-- end

require "battle.views.sprite_normal"
require "battle.views.sprite_effect"
require "battle.views.sprite_proxy"
require "battle.views.sprite_debug"
