--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2017 TianJi Information Technology Inc.
--

--
-- CLifeBar
--

-- 资源路径
local heroResPsthTb = {
	-- mHp = "battle/bar_hero_blood.png",
	-- eHp = "battle/bar_enemy_blood.png",
	-- mp1 = "battle/bar_energy_yellow.png",
	-- shield = "battle/bar_shield_blue.png",

	level2 = "battle/logo_hero_level2.png",
	level = "battle/logo_hero_level.png",
}
local enemyResPsthTb = {
	level2 = "battle/logo_enemy_level2.png",
	level = "battle/logo_enemy_level.png",
}
local shieldResPathTb = {
	normal = "battle/bar_enemy_white.png",
	radius = "battle/bar_enemy_white_radius.png"
}

globals.CLifeBar = class("CLifeBar", cc.Node)

function CLifeBar:ctor(model, battleView)
	self.model = model

	self:init(battleView)
end

function CLifeBar:init(battleView)
	-- 等级框  区分敌我颜色差异
	local pnode = battleView.UIWidget:getResourceNode()
	local resTb = (self.model.force == 1) and heroResPsthTb or enemyResPsthTb
	local level = self.model.showLevel or self.model.level
	--这里暂时先把之前的有护盾条干掉，把护盾条放在血条上方
	local function initBarPanel(isShield)
		-- local str = isShield and "hpBarPanelS" or "hpBarPanel"
		-- local barPanel = pnode:get(str):clone()
		-- local res = isShield and "level" or "level2"
		-- barPanel:get("di"):loadTexture(resTb[res])
		-- local sz = barPanel:get("di"):size()
		-- local halfWidth = sz.width/2
		-- local halfHeight = sz.height/2
		-- barPanel:addTo(self, 4):xy(-halfWidth, halfHeight)
		-- barPanel:get("level"):setString(level)
		-- return barPanel

		local barPanel = pnode:get("hpBarPanel"):clone()
		-- barPanel:get("di"):loadTexture(resTb["level2"])
		local sz = barPanel:get("di"):size()
		local halfWidth = sz.width/2
		local halfHeight = sz.height/2
		barPanel:addTo(self, 4):xy(-halfWidth, halfHeight)
		barPanel:get("level"):setString(level)
		return barPanel
	end

	self.barPanel = initBarPanel()
	-- self.barPanelS = initBarPanel(true):hide()

	-- 记录下buff添加的位置起点
	local size = self.barPanel:get("di"):size()
	self.buffAddFirstPos = cc.p(-size.width/2 + 70, 55)

	-- 位置要根据左右两方来微调下
	local unitCfg = self.model.unitCfg
	self:setPosition(unitCfg.everyPos.lifePos)
	self:setScale(unitCfg.lifeScale)
	self.canSetVisible = true

	self.barCapture = CRenderSprite.newWithNodes(cc.TEXTURE2_D_PIXEL_FORMAT_RGB_A4444, self.barPanel)
	self.barCapture:addTo(self, 5):coverTo(self.barPanel):setCaptureOffest(cc.p(0, 13))
	self.updateCount = 0
	self.lastPer = {
		hpPer = 0,
		mpPer = 0,
		shieldPer = 0,
		mpOverflowPer = 0
	}
	self.barPanel:get("shieldBar"):setPercent(0)
	self.barPanel:get("hpBar"):setPercent(0)
	self.barPanel:get("mpBar"):setPercent(0)
	self.barPanel:get('mpOverflowBar'):setPercent(0)
end

local function calcWith(args)
	local hp = args.hp
	local hpMax = args.hpMax
	local shieldHp = args.shieldHp
	local delayHp = args.delayHp
	local specialShieldHp = args.specialShieldHp
	local normalShieldHp = shieldHp - specialShieldHp
	-- 层级：hp > delay > cover > shield > specialShield
	local hpPer, shieldPer, delayPer = 0, 0, 0

	local maxProgress = hp + shieldHp > hpMax and hp + shieldHp or hpMax
	local minHpPer = math.min(hp / hpMax * 100, 10)
	delayHp = cc.clampf(delayHp, 0, hp)
	delayPer = hp / maxProgress * 100
	hpPer = (hp - delayHp) / maxProgress * 100
	if delayPer < minHpPer then
		delayPer = minHpPer
		hpPer = (hp - delayHp) / hp * minHpPer
	end

	local specialShieldStatus = specialShieldHp > 0
	-- 从左向右和从右向左区分
	shieldPer = specialShieldStatus and (maxProgress - hp - specialShieldHp) / maxProgress * 100 or (hp + shieldHp) / maxProgress * 100

	-- 需要cover的量
	local coverPer = (maxProgress - hp - shieldHp) / maxProgress * 100

	args.hpPer = hpPer
	args.shieldPer = shieldPer
	args.shieldStatus = normalShieldHp > 0
	args.delayPer = delayPer
	args.delayStatus = delayHp > 0
	args.specialShieldStatus = specialShieldStatus
	args.coverPer = coverPer
	args.coverStatus = specialShieldHp > 0 and coverPer > 0 -- 有特殊护盾出现时coverBar负责遮挡普通护盾条和特殊护盾特效
end

function CLifeBar:update(args)
	if args.needCalc then
		calcWith(args)
		self.specialShieldStatus = args.specialShieldStatus
	end

	local hpPer, shieldPer, shieldStatus = args.hpPer,args.shieldPer, args.shieldStatus
	local delayPer, delayStatus = args.delayPer, args.delayStatus
	local coverPer, coverStatus = args.coverPer, args.coverStatus
	local curBarPanel = self.barPanel

	local function doCaptureShow()
		self.updateCount = self.updateCount - 1
		if self.updateCount > 0 then return end

		-- capture static sprite by render target
		if not self.specialShieldStatus then -- 对图片做的优化会影响到特效显示
			self.barCapture:show()
		end
	end

	local function checkBarStatus(barName, status)
		local curBar = curBarPanel:get(barName)
		local barVisible = curBar:visible()
		status = status or false
		if status ~= barVisible then
			curBar:visible(status)
			self.updateCount = self.updateCount + 1
			performWithDelay(self, doCaptureShow, 0)
		end
	end

	local function setBarPercent(barName, barPer, recordName)
		if not barPer then return end
		local perInt = math.ceil(barPer)
		if self.lastPer[recordName] ~= perInt then
			self.lastPer[recordName] = perInt
			self.updateCount = self.updateCount + 1
			transition.executeSequence(curBarPanel:get(barName))
				:progressTo(0.1, barPer)
				:func(doCaptureShow)
				:done()
		end
	end

	checkBarStatus("shieldBar", shieldStatus)
	checkBarStatus("delayBar", delayStatus)

	setBarPercent("hpBar", hpPer, "hpPer")
	setBarPercent("shieldBar", shieldPer, "shieldPer")
	setBarPercent("delayBar", delayPer, "delayPer")

	checkBarStatus("coverBar", coverStatus)
	setBarPercent("coverBar", coverPer, "coverPer")

	local sz = curBarPanel:get("di"):size()
	local halfWidth = sz.width/2
	local halfHeight = sz.height/2

	if self.specialShieldStatus then
		self.barPanel:get("shieldBar"):setDirection(1)
		self.barPanel:get("shieldBar"):loadTexture(shieldResPathTb.radius)
		widget.addAnimationByKey(self.barPanel, battle.SpriteRes.fireShield, 'hpBarSprite', "xuetiao_loop", 1)
			:xy(halfWidth + 25, halfHeight - 15)
			:setScaleX(1.85)
			:addPlay("xuetiao_loop")
	else
		self.barPanel:get("shieldBar"):setDirection(0)
		self.barPanel:get("shieldBar"):loadTexture(shieldResPathTb.normal)
		self.barPanel:removeChildByName("hpBarSprite")
	end

	if args.mp then
		local mp = args.mp
		local mpMax = args.mpMax
		local mpOverflow = args.mpOverflow
		local mpPer, mpOverflowPer = 0, 0
		local mp1OverflowData = args.mp1OverflowData

		mpPer = math.min((mp + mpOverflow), mpMax) / mpMax * 100
		mpOverflowPer = math.min(mpOverflow, mpMax) / mpMax * 100

		local mpOverflowStatus = (not mp1OverflowData or (mp1OverflowData and mp1OverflowData.mode ~= 1)) and mpOverflow > 0
		local realMpPer = mp / mpMax * 100

		checkBarStatus("mpOverflowBar", mpOverflowStatus)
		setBarPercent("mpBar", mpPer, "mpPer")

		if realMpPer >= 100 then
			local mankuangEffect = "xuetiao_mankuang_loop"
			if mpOverflowStatus then
				curBarPanel:get("mpBar"):setScaleY(1.5)
				curBarPanel:get("mpOverflowBar"):setScaleY(1.5)
				mankuangEffect = "xuetiao_mankuang2_loop"
			end
			widget.addAnimationByKey(self, battle.SpriteRes.mainSkill, 'mpBarSprite', "xuetiao_mankuang", 10)
				:xy(halfWidth-110, halfHeight-103)
				:addPlay(mankuangEffect)
		else
			curBarPanel:get("mpBar"):setScaleY(1)
			curBarPanel:get("mpOverflowBar"):setScaleY(1)
			self:removeChildByName("mpBarSprite")
		end

		--有溢出怒气保存buff时 mpPer 会大于100
		setBarPercent("mpOverflowBar", mpOverflowPer, "mpOverflowPer")

		if mp1OverflowData and mp1OverflowData.mode == 1 then
			local mp1PointLimit = math.floor(mp1OverflowData.limit / mp1OverflowData.rate)
			local mp1Point = math.floor(args.mpOverflow / mp1OverflowData.rate)

			local mp1BarSize = curBarPanel:get("mpBar"):size()
			local mpBarX, mpBarY = curBarPanel:get("mpBar"):xy()
			local posX = mpBarX - mp1BarSize.width/2

			local mp1PointNode = cc.Node:create()
			self:removeChildByName("mp1PointNode")
			self:addChild(mp1PointNode, 10, 'mp1PointNode')
			local interval = mp1BarSize.width/mp1PointLimit
			mp1Point = mp1Point or 0
			for i = 1, math.max(mp1Point, mp1PointLimit) do
				local action = "kong_effect_loop"
				if i <= mp1Point then
					action = "jihuo_effect_loop"
				end
				widget.addAnimationByKey(mp1PointNode, "buff/nuqidian/nuqidian.skel", 'mp1PointLimit'..i, action, 10)
					:xy(interval*i-72, mpBarY+8)
					:scale(2)
			end
		else
			self:removeChildByName("mp1PointNode")
		end
	end


	if self.updateCount > 0 then
		-- remove static, show widget to show move
		self.barCapture:hide()
	end
end

function CLifeBar:setVisibleEnable(enable)
	self.canSetVisible = enable
end

function CLifeBar:setVisible(visible)
	if not self.canSetVisible then
		return
	end
	cc.Node.setVisible(self, visible)
end