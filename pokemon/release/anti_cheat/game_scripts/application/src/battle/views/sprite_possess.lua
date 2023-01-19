globals.BattlePossessSprite = class("BattlePossessSprite", BattleSprite)

function BattlePossessSprite:loadSprite(res,zOrder,args)
	if self.args.res then
		self.sprite = newCSprite(self.args.res)
        self.sprite:setPosition(cc.p(0,0))
		self.sprite:setSpriteEventHandler(handler(self, self.onSpriteEvent))
		self:add(self.sprite, zOrder)
		self:setScale(1)
	end
end

function BattlePossessSprite:init()
	BattleSprite.init(self)
	-- z轴要特殊处理
	self.holderView = gRootViewProxy:call("getSceneObj", self.args.targetKey)
	self.holderView:addFollowSpr(self)
	-- self.holderView:add(self, battle.SpriteLayerZOrder.possess)

	self.casterView = gRootViewProxy:call("getSceneObj", self.args.casterKey)
	self.casterView:addReplaceView(self)

	self.isDirty = false

	self._holderPos = cc.p(self.holderView:getPosition())
	self._holderVis = self.holderView:isVisible()
	self._holderZOrder = self.holderView:getLocalZOrder()
	self:setActionState(battle.SpriteActionTable.standby)
end

function BattlePossessSprite:getHolderVisible()
	return self.holderView:isVisible() and self.holderView:getSpriteVisible()
end

function BattlePossessSprite:onFixedUpdate(delta)
	if self.isDirty then return end
	if self._holderVis ~= self:getHolderVisible() then
		self._holderVis = self:getHolderVisible()
		self:setVisible(self._holderVis)
	end

	if self._holderPos.x ~= self.holderView:getPositionX() or self._holderPos.y == self.holderView:getPositionY() then
		self._holderPos.x, self._holderPos.y = self.holderView:getPosition()
		local posAdjust = self:getPosAdjust()
		local x, y = self._holderPos.x+posAdjust.x, self._holderPos.y+posAdjust.y
		self:setPosition(cc.p(x,y))
		self:setCurPos(cc.p(self._holderPos.x, self._holderPos.y))
	end

	if self._holderZOrder ~= self.holderView:getLocalZOrder() then
		self._holderZOrder = self.holderView:getLocalZOrder()
		self:setLocalZOrder(self._holderZOrder + 1)
	end
end

function BattlePossessSprite:onAddToScene()
	BattleSprite.onAddToScene(self)

	self:resetPosZ(self._holderPos.y - 1)
	self:setLocalZOrder(self.posZ)
end

-- function BattlePossessSprite:getPosAdjust()
-- 	local offsetPos = self.args.offsetPos
-- 	return cc.p(self.forceFaceTo * offsetPos.x or 0, offsetPos.y or 0)
-- end

function BattlePossessSprite:popEffectInfo(eventID)
	return self.casterView:popEffectInfo(eventID)
end

function BattlePossessSprite:getProcessArgs(processID)
	return self.casterView:getProcessArgs(processID)
end

function BattlePossessSprite:popIgnoreEffect(processID,eventID)
	return self.casterView:popIgnoreEffect(processID,eventID)
end

function BattlePossessSprite:getSeat()
	return self.args.targetSeat
end

function BattlePossessSprite:initLifeBar()
end

function BattlePossessSprite:initNatureQuan()
end

function BattlePossessSprite:initGroundRing()
end

function BattlePossessSprite:updHitPanel()
end

function BattlePossessSprite:setDirty(isOver)
	self.isDirty = isOver
end

function BattlePossessSprite:showHero(isShow, args)
	self:setVisible(isShow)
end

function BattlePossessSprite:checkSceneTag(args)
	if args then
		return args.isPossessAttack
	end
	return false
end

function BattlePossessSprite:sceneDelObj(layer)
	self.holderView:removeFollowSpr(self)
	self.casterView:removeReplaceView(self)
	self:removeSelf()
end

function BattlePossessSprite:objToHideEff(isAttacting, playView)
	local dirtyTag, visible = isAttacting, not isAttacting
	local args = playView.skillSceneTag:back()
	local isBigSkill = args and args.isBigSkill
	-- 1.附身代替本体释放技能 大招:本体隐藏
	-- 如果是替换的表现 则由自己控制
	if self.casterView == playView then
		playView:objToHideEff(isAttacting)
		if isBigSkill then
			self.casterView:setVisible(visible)
		end
		-- 自身控制相关表现
		visible = isAttacting
		self:setDirty(dirtyTag)
		self:setVisible(visible)
	else
		-- 2.技能表现是他人时, 大招时一直隐藏
		if isBigSkill then
			self:setDirty(dirtyTag)
			self:setVisible(visible)
		end
	end

	-- -- TODO: 更好的控制表现的方式
	-- local args = playView.skillSceneTag:back()
	-- if args and args.isBigSkill then
	-- 	self:setDirty(dirtyTag)
	-- 	self:setVisible(visible)
	-- end
end

-- function BattlePossessSprite:objToHideEffOther(isAttacting, playView)
-- 	-- 如果是替换的表现 则由自己控制
-- 	if self.casterView:getRealUseView() == self then return end
-- 	-- TODO: 更好的控制表现的方式
-- 	local args = playView.skillSceneTag:back()
-- 	if args and args.isBigSkill then
-- 		self:setDirty(isAttacting)
-- 		self:setVisible(not isAttacting)
-- 	end
-- end

-- function BattlePossessSprite:moveToPosIdx()
-- 	local x, y = self.posAdjust.x, self.posAdjust.y
-- 	self:setPosition(cc.p(x, y))
-- 	self:setCurPos(cc.p(x, y))
-- end

-- function BattlePossessSprite:getSelfPos()
-- 	return self.posAdjust.x, self.posAdjust.y
-- end

-- function BattlePossessSprite:setCurPos()
-- 	self.posXY = cc.p(0, 0)
-- end

-- function BattlePossessSprite:getAttackPos(posIdx, adjust, needConfusionFix)
-- 	local x, y = BattleSprite.getAttackPos(self, posIdx, adjust, needConfusionFix)
-- 	local originX, originY = BattleSprite.getSelfPos(self)
-- 	return x - originX, y - originY
-- end