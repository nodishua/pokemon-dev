--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2017 TianJi Information Technology Inc.
--

-- 背景层

local Stage = class('Stage', battleModule.CBase)

function Stage:ctor(parent)
	battleModule.CBase.ctor(self, parent)

	self.frontStageLayer = self.parent.frontStageLayer
	self.stageLayer = self.parent.stageLayer
	self.stage = nil
end

-- 设置背景和前景抽出来，方便使用
function Stage:setStage(res, resType)
	if self.stage then
		self.stage:removeFromParent()
	end

	local sprite = newCSprite(res)
	sprite:setAnchorPoint(cc.p(0,0))
	sprite:setPosition(display.center)
	if resType == 2 then --前景层
		self.frontStageLayer:add(sprite)
	else
		self.stageLayer:add(sprite)
	end
	self.stage = sprite
	return sprite
end

function Stage:onAddGround(arg)
	local spos = cc.p(arg.x, arg.y)
	for i = 1, arg.xtileSize do
		spos.y = arg.y
		for j = 1,arg.ytileSize do
			local sprite = self:setStage(arg.config.res, arg.config.resType):scale(arg.config.scale)
			local oldPosX, oldPosY = sprite:getPosition()
			sprite:setPosition(cc.pAdd(cc.p(oldPosX, oldPosY), spos)) -- 位置修正
			if sprite:isSpine() then
				if arg.config.aniName then
					sprite:play(arg.config.aniName)
					sprite:addPlay("effect_loop")
				else
					sprite:play("effect_loop")
				end
				sprite:setAnimationSpeedScale(arg.config.frameScale, true)
			end
			sprite:setName(arg.id .. (i*arg.ytileSize+j))
		end
		spos.x = spos.x + arg.xlength
	end
end

function Stage:onMoveGround(arg)
	local spos = cc.p(arg.x, arg.y)
	for i = 1, arg.xtileSize do
		spos.y = arg.y
		for j = 1,arg.ytileSize do
			local name = arg.id .. (i*arg.ytileSize+j)
			local bg
			if arg.config.resType == 2 then --前景层
				bg = self.frontStageLayer:get(name)
			else
				bg = self.stageLayer:get(name)
			end
			bg:setPosition(spos)
			spos.y = spos.y + arg.ylength
		end
		spos.x = spos.x + arg.xlength
	end
end

--大招需要增加的前置动画效果
function Stage:onUltSkillPreAni1()
	-- 大招释放的时候隐藏掉不需要的UI界面	showUIWidgets
	self.parent.subModuleNotify:notify('showMain', false)
	self.parent.subModuleNotify:notify("showSpec", false)
	self.parent.subModuleNotify:notify("showLinkEffect", false)
	--self:skillPreAni(id, skillCfg, faceTo, hideHero)
end

-- 技能施放前的头像移动动画
function Stage:onUltSkillPreAni2(id, skillCfg, hideHero)
	local bg = newCSprite(battle.StageRes.cutRes)
	local bg2 = newCSprite(battle.StageRes.cutRes)
	local st = newCSprite(battle.StageRes.cutRes)

	local hero = newCSprite("config/big_hero/normal/"..skillCfg.effectBigName[1]..".png")
	local heroBg = newCSprite("config/big_hero/normal/"..skillCfg.effectBigName[1]..".png")

	local combSt,combHero,combHeroBg
	local isCombineSkill = skillCfg.skillType == battle.SkillType.PassiveCombine
	if isCombineSkill then
		combSt = newCSprite(battle.StageRes.cutRes)
		combHero = newCSprite("config/big_hero/normal/"..skillCfg.effectBigName[2]..".png")
		combHeroBg = newCSprite("config/big_hero/normal/"..skillCfg.effectBigName[2]..".png")
	end

	local clipNode = cc.ClippingNode:create(st)
	local aniNode = cc.Node:create()

	local ownerSpr = self.parent:onViewProxyCall('getSceneObj', id)
	local faceTo = ownerSpr.faceTo

	local isHide = false
	local hide = function()
		if isHide then return end
		isHide = true
		for _, obj in pairs(hideHero) do
			self.parent:onEventEffect(obj, 'show', {show={{hide=true}}})
		end
	end

	local effectFront = isCombineSkill and "htj_effect" or "effect"

	-- 横屏图
	bg:play(effectFront.."_hou")
	bg:setSpriteEventHandler(function(event, eventArgs)
		if event == sp.EventType.ANIMATION_COMPLETE then
			removeCSprite(bg)
			removeCSprite(bg2)
			removeCSprite(st)
			removeCSprite(hero)
			removeCSprite(heroBg)
			if isCombineSkill then
				removeCSprite(combSt)
				removeCSprite(combHero)
				removeCSprite(combHeroBg)
			end
			hide()
			aniNode:removeFromParent()
			self:skillStageEffect(id, skillCfg)
		end
	end)
	bg:scale(faceTo*1.42, 1.2):setPositionY(-20)

	-- 英雄头像
	local heroNode = cc.Node:create()
	hero:setPositionX(-420)
	heroBg:setPositionX(-420)
	hero:setPositionY(0)
	heroBg:setPositionY(0)
	local heroNodeScaleX = 1
	if skillCfg.effectBigFlip then
		heroNodeScaleX = -1
	end

	local effectBigPos = skillCfg.effectBigPos
	if effectBigPos.x ~= 0 then
		hero:setPositionX(hero:getPositionX() + effectBigPos.x)
		heroBg:setPositionX(heroBg:getPositionX() + effectBigPos.x)
	end

	if effectBigPos.y ~= 0 then
		hero:setPositionY(hero:getPositionY() + effectBigPos.y)
		heroBg:setPositionY(heroBg:getPositionY() + effectBigPos.y)
	end

	hero:scale(heroNodeScaleX*1.35, 1.35)
	heroBg:scale(heroNodeScaleX*1.4, 1.4)
	heroBg:setGLProgram("color"):setUniformVec3("color", cc.Vertex3F(0.93, 0.07, 0.41))
	st:xy(0, 0):scale(1, 1):play(effectFront.."_zhezhao")
	heroNode:add(heroBg, 1):add(hero, 2):xy(-500, -500):scale(1.2)
	clipNode:scale(faceTo*1.2,1.2)
	clipNode:add(heroNode)

	transition.executeSequence(heroNode)
		:delay(0.5)
		:easeBegin("IN")
			:spawnBegin()
				:moveTo(0.33, 0, 0)
				:scaleTo(0.33, 1)
			:spawnEnd()
		:easeEnd()
		:easeBegin("IN")
			:moveBy(0.33, -50, -50)
			:moveBy(0.33, 50, 50)
		:easeEnd()
		:easeBegin("OUT")
			:spawnBegin()
				:moveTo(0.5, 1136, 640)
				:scaleTo(0.5, 0.1)
				:func(hide) -- 隐藏不在攻击范围的所有目标
			:spawnEnd()
		:easeEnd()
		:done()

	-- 横屏图
	bg2:play(effectFront.."_qian")
	bg2:setScaleX(faceTo)

	-- 文字(特效说删了这个)
	-- if faceTo == 1 then
	-- 	name:play("effect_Z_mingzi")
	-- else
	-- 	name:play("effect_Y_mingzi")
	-- end
	local scaleY = 2
	if display.uiOrigin.y ~= 0 then
		local value = display.sizeInPixels.height
		scaleY = scaleY * ((value + display.uiOrigin.y) / (value))
	end

	-- 使用X轴位移 和 以Y轴为准的整体缩放 控制特效的位置和大小
	aniNode:add(bg, 1):add(clipNode, 2):add(bg2, 3):scale(scaleY):setPosition(display.center)
	aniNode:x(aniNode:x() - faceTo * display.uiOrigin.x)

	if isCombineSkill then
		local combClipNode = cc.ClippingNode:create(combSt)

		local combHeroNode = cc.Node:create()
		combHero:setPositionX(-420)
		combHeroBg:setPositionX(-420)
		combHero:setPositionY(0)
		combHeroBg:setPositionY(0)

		if effectBigPos.combX and effectBigPos.combX ~= 0 then
			combHero:setPositionX(combHero:getPositionX() + effectBigPos.combX)
			combHeroBg:setPositionX(combHeroBg:getPositionX() + effectBigPos.combX)
		end

		if effectBigPos.combY and effectBigPos.combY ~= 0 then
			combHero:setPositionY(combHero:getPositionY() + effectBigPos.combY)
			combHeroBg:setPositionY(combHeroBg:getPositionY() + effectBigPos.combY)
		end

		combHero:scale(heroNodeScaleX*1.35, -1 * 1.35)
		combHeroBg:scale(heroNodeScaleX*1.4, -1 * 1.4)
		combHeroBg:setGLProgram("color"):setUniformVec3("color", cc.Vertex3F(0.93, 0.07, 0.41))
		combSt:xy(0, 0):scale(1, 1):play(effectFront.."_zhezhao")
		combHeroNode:add(combHeroBg,1):add(combHero, 2):xy(-500, -500):scale(1.2)

		combClipNode:scale(-1 * faceTo*1.2,-1 * 1.2)
		combClipNode:add(combHeroNode)

		transition.executeSequence(combHeroNode)
			:delay(0.5)
			:easeBegin("IN")
				:spawnBegin()
					:moveTo(0.33, 0, 0)
					:scaleTo(0.33, 1)
				:spawnEnd()
			:easeEnd()
			:easeBegin("IN")
				:moveBy(0.33, -50, -50)
				:moveBy(0.33, 50, 50)
			:easeEnd()
			:easeBegin("OUT")
				:spawnBegin()
					:moveTo(0.5, 1136, 640)
					:scaleTo(0.5, 0.1)
					:func(hide) -- 隐藏不在攻击范围的所有目标
				:spawnEnd()
			:easeEnd()
			:done()

		aniNode:add(combClipNode, 2)
	end

	self.parent.layer:add(aniNode)
end

-- 大招需要的背景变化效果
function Stage:skillStageEffect(id, skillCfg)
	local node = self.parent:onViewProxyCall('getSceneObj', id)
	if node == nil then return end
	local blankTime = skillCfg.blankTime
	local scaleArgs = skillCfg.scaleArgs
	if skillCfg.cameraNear == 1 or skillCfg.cameraNear == 2 then
		blankTime = skillCfg.cameraNear_blankTime
		scaleArgs = skillCfg.cameraNear_scaleArgs
	end
	if not blankTime or (blankTime <= 0) then return end

	if scaleArgs.scale and scaleArgs.scale ~= 1 then
		node:objToBlank(scaleArgs)
	end
	local battleView = self.parent
	local args = {
		delay = 0,
		offsetX=0,
		offsetY=0,
		zorder=0,
		aniName="dazhao_bj",
		scale = 2,
		aniloop=false,
		screenPos = 0,
		lastTime=blankTime,
		addTolayer = 0
	}
	local effect = self.parent:onEventEffect(nil,'effect',{effectType = 1,effectRes = battle.StageRes.daZhaoBJ,effectArgs = args,onComplete = function() end,faceTo = 1})
	table.insert(self.parent.effectJumpCache,effect)
end

--大招场景层移动,需要在上面的动画过程结束时才开始 (暂时也都放在一起了,或者分开写?)
function Stage:onSkillStartStageMove(cameraNear)
	local scale = (cameraNear == 2) and 1.15 or 0.85
	transition.executeParallel(self.stageLayer)
		--:moveBy(0.8, 0, -56)
		:scaleTo(0.8, scale)

	transition.executeParallel(self.parent.gameLayer)
		--:moveBy(0.8, 0, -56)
		:scaleTo(0.8, scale)

	transition.executeParallel(self.parent.effectLayer)
		--:moveBy(0.8, 0, -56)
		:scaleTo(0.8, scale)
end

--大招场景层移动恢复
function Stage:onSkillEndStageMoveBack()
	transition.executeParallel(self.stageLayer)
		:moveTo(0.3, 0, 0)
		:scaleTo(0.3, 1)

	transition.executeParallel(self.parent.gameLayer)
		:moveTo(0.3, 0, display.fightLower)
		:scaleTo(0.3, 1)

	transition.executeParallel(self.parent.effectLayer)
		:moveTo(0.3, 0, display.fightLower)
		:scaleTo(0.3, 1)
end

-- 更换战斗场景
function Stage:onAlterBattleScene(args)
	if not self.bgSprGroup then self.bgSprGroup = {} end
	if self.bgSprGroup[args.buffId] then
		self.bgSprGroup[args.buffId]:removeSelf()
		self.bgSprGroup[args.buffId] = nil
	end
	-- 换场景
	if not args.restore then
		-- 隐藏之前的背景
		for _, v in pairs(self.bgSprGroup) do
			v:hide()
		end
		if args.aniName then
			local bgSpr = newCSprite(args.resPath)
			self.parent.stageLayer:add(bgSpr, 9999)
			bgSpr:setPosition(display.center)
			local x, y = bgSpr:getPosition()
			bgSpr:setPosition(x + args.x, y + args.y):scale(2)
			bgSpr:play(args.aniName .. "_loop")
			self.bgSprGroup[args.buffId] = bgSpr
		else
			local bgSpr = cc.Sprite:create(args.resPath)
			bgSpr:xy(display.center):scale(2)
			self.parent.stageLayer:add(bgSpr, 9999)
			self.bgSprGroup[args.buffId] = bgSpr
		end
	else
		local maxBuffID = -1
		for k, _ in pairs(self.bgSprGroup) do
			if k > maxBuffID then maxBuffID = k end
		end
		if maxBuffID ~= -1 then self.bgSprGroup[maxBuffID]:show() end
	end
end
return Stage
