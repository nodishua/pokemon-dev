--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2017 TianJi Information Technology Inc.
--

-- 战斗设置区域

local SysSetting = class('SysSetting', battleModule.CBase)

function SysSetting:ctor(parent)
	battleModule.CBase.ctor(self, parent)

	-- 由于这三个按钮实际上是图片，所以设置为可触摸
	self.speedButton = self.parent.UIWidgetBottomLeft:get("speedUp")
	self.autoButton = self.parent.UIWidgetBottomLeft:get("autoAtt")
	self.pauseButton = self.parent.UIWidgetBottomLeft:get("pause")
	self.passButton = self.parent.UIWidgetBottomLeft:get("mainSkillPass")

	self.buttonCapture = CRenderSprite.newWithNodes(cc.TEXTURE2_D_PIXEL_FORMAT_RGB_A4444, self.pauseButton, self.autoButton, self.speedButton, self.passButton)
	self.buttonCapture:addTo(self.parent.UIWidgetBottomLeft, 999):coverTo(self.pauseButton)
	if self.parent:hasGuide() then
		self.buttonCapture:hide()
	else
		self.buttonCapture:setTouchEnabled()
		performWithDelay(self.parent, function()
			self.buttonCapture:show()
		end, 1)
	end

	self.skipButton = self.parent.UIWidgetMid:get("skip")
	if self.skipButton then
		self.skipButton:hide()
	end
end

--自动战斗按钮
function SysSetting:setAutoButton(opeArgs)
	if opeArgs.canHandle and not opeArgs.isAuto then
		if self.parent.gateType == game.GATE_TYPE.newbie then
			-- do nothing

		elseif self.parent.gateType ~= game.GATE_TYPE.test and not dataEasy.isUnlock(gUnlockCsv.gateAuto) then
			self.autoButton:get("auto"):setString(gLanguageCsv.manual)
			self.autoButton:onClick(function()
				gGameUI:showTip(dataEasy.getUnlockTip(gUnlockCsv.gateSpeed2))
			end)
		else
			self.autoButton:get("disabled"):hide()
			self.autoButton:get("lock"):hide()
			local autoFight = userDefault.getForeverLocalKey("gateAuto", false)
			-- 玩法特别要求的锁定类型
			if opeArgs.lockAuto ~= nil then
				autoFight = opeArgs.lockAuto
			end
			local autoBtn = self.autoButton:get("auto")
	 		autoBtn:setString(autoFight and gLanguageCsv.auto or gLanguageCsv.manual)
			self.parent:handleOperation(battle.OperateTable.autoFight, autoFight)

			self.autoButton:onClick(function()
				autoFight = not autoFight
				autoBtn:setString(autoFight and gLanguageCsv.auto or gLanguageCsv.manual)
				-- 自动状态关闭技能面板的显示
				if autoFight then
					self:call("showSKillUIWidgets", false)	-- 隐藏技能面板
				end
				self.parent:handleOperation(battle.OperateTable.autoFight, autoFight)
				userDefault.setForeverLocalKey("gateAuto", autoFight)
			end)
		end
	else
		self.autoButton:get("auto"):setString(gLanguageCsv.auto)
	end
end

-- 暂停按钮
function SysSetting:setPauseButton(opeArgs)
	if (self.parent.gateType == game.GATE_TYPE.test or dataEasy.isUnlock(gUnlockCsv.gatePause)) and opeArgs.canPause then
		self.pauseButton:get("disabled"):hide()
		self.pauseButton:get("lock"):hide()
		self.pauseButton:onClick(function()
			if opeArgs.canPause then
				audio.pauseAllSounds()
				gGameUI:stackUI("battle.pause", nil, nil, self.parent):z(999)
			end
		end)
	end
end

-- 加速按钮
function SysSetting:setSpeedButton(opeArgs)
	local speedBtn = self.speedButton:get("speed")
	local speedNum = 1
	if (self.parent.gateType == game.GATE_TYPE.test or dataEasy.isUnlock(gUnlockCsv.gateSpeed2)) and opeArgs.canSpeedAni then
		speedNum = tonumber(userDefault.getForeverLocalKey("gateSpeed", 1))
		self.speedButton:get("disabled"):hide()
		self.speedButton:get("lock"):hide()
	end
	speedBtn:setString(string.format("x%d",speedNum))
	self.parent:handleOperation(battle.OperateTable.timeScale, speedNum)
	local function changeSpeed(speed)
		if dataEasy.isUnlock(gUnlockCsv.gateSpeed3) then
			speed = speed + 1
			if speed == 4 then
				speed = 1
			end
			return speed
		else
			if speed == 2 then
				gGameUI:showTip(dataEasy.getUnlockTip(gUnlockCsv.gateSpeed3))
			end
			return (3 - speed)
		end
	end
	self.speedButton:onClick(function()
		if self.parent.gateType == game.GATE_TYPE.newbie then
			-- do nothing

		elseif self.parent.gateType ~= game.GATE_TYPE.test and not dataEasy.isUnlock(gUnlockCsv.gateSpeed2) then
			gGameUI:showTip(dataEasy.getUnlockTip(gUnlockCsv.gateSpeed2))

		elseif opeArgs.canSpeedAni then
			speedNum = changeSpeed(speedNum)
			speedBtn:setString(string.format("x%d",speedNum))
			self.parent:handleOperation(battle.OperateTable.timeScale, speedNum)
			userDefault.setForeverLocalKey("gateSpeed", speedNum)
		end
	end)
end

-- 跳过按钮
function SysSetting:setSkipButton(opeArgs)
	local function setPassCountDown(time)
		time = tonumber(time)
		local tag = battle.UITag.passCD
		self.parent:enableSchedule():unSchedule(tag)
		self.skipButton:setColor(cc.c3b(75,75,75))
		self.skipButton:get("text"):setColor(cc.c3b(75,75,75))
		self.skipButton:get("mask"):setVisible(true)
		self.skipButton:get("mask"):get("timer"):setString(time)
		self.parent:schedule(function()
			time = time - 1
			self.skipButton:get("mask"):get("timer"):setString(time)
			if time <= 0 then
				self.skipButton:get("mask"):setVisible(false)
				self.skipButton:setColor(cc.c3b(255,255,255))
				self.skipButton:get("text"):setColor(cc.c3b(255,252,237))
				return false
			end
		end,1,1,tag)
	end

	if self.parent.gateType == game.GATE_TYPE.crossMine then
		self.originPassStr = self.skipButton:get("text"):text()
		self.skipButton:get("text"):text(gLanguageCsv.crossMinePVPSkip)
	end
	text.addEffect(self.skipButton:get("text"), {glow = {color = ui.COLORS.GLOW.WHITE}})

	if opeArgs.canSkip and self.skipButton then
		self.skipButton:show()
		self.skipButton:onClick(function ()
			self:onClickPass()
		end)
		if self.parent.gateType == game.GATE_TYPE.arena and not opeArgs.canSkipInstant then
			local vipLevel = gGameModel.role:getIdler("vip_level")
			local time = gVipCsv[vipLevel:read()].arenaPassCD
			if dataEasy.getPrivilegeVal(game.PRIVILEGE_TYPE.BattleSkip, game.SCENE_TYPE.arena) then
				time = 0
			end
			setPassCountDown(time)
		elseif self.parent.gateType == game.GATE_TYPE.endlessTower then
			local time = gCommonConfigCsv.endlessTowerJumpCD
			if dataEasy.getPrivilegeVal(game.PRIVILEGE_TYPE.BattleSkip, game.SCENE_TYPE.endlessTower) then
				time = 0
			end
			setPassCountDown(time)
		elseif self.parent.gateType == game.GATE_TYPE.randomTower then
			local time = gCommonConfigCsv.randomTowerJumpCD
			if dataEasy.getPrivilegeVal(game.PRIVILEGE_TYPE.BattleSkip, game.SCENE_TYPE.randomTower) then
				time = 0
			end
			setPassCountDown(time)
		elseif self.parent.gateType == game.GATE_TYPE.worldBoss then
			local time = gCommonConfigCsv.worldBossJumpCD
			if dataEasy.getPrivilegeVal(game.PRIVILEGE_TYPE.BattleSkip, game.SCENE_TYPE.worldBoss) then
				time = 0
			end
			setPassCountDown(time)
		elseif self.parent.gateType == game.GATE_TYPE.gym then
			local time = gCommonConfigCsv.gymGateJumpCD
			if dataEasy.getPrivilegeVal(game.PRIVILEGE_TYPE.BattleSkip, game.SCENE_TYPE.gym) then
				time = 0
			end
			setPassCountDown(time)
		elseif self.parent.gateType == game.GATE_TYPE.hunting then
			local time = gCommonConfigCsv.huntingJumpCD
			if dataEasy.getPrivilegeVal(game.PRIVILEGE_TYPE.BattleSkip, game.SCENE_TYPE.hunting) then
				time = 0
			end
			setPassCountDown(time)
		elseif self.parent.gateType == game.GATE_TYPE.clone then
			if not dataEasy.isUnlock(gUnlockCsv.skipCloneBattle) then
				self.skipButton:hide()
				self.skipButton:onClick(function ()	end)
			else
				self.skipButton:get("mask"):setVisible(false)
			end
		else
			self.skipButton:get("mask"):setVisible(false)
		end
	end
end

-- 大招跳过按钮
function SysSetting:setPassButton(opeArgs)
	local passOpen = userDefault.getForeverLocalKey("mainSkillPass", false)
	local imgOpen = self.passButton:get("imgOpen")
	local imgClose = self.passButton:get("imgClose")
	imgOpen:visible(passOpen)
	imgClose:visible(not passOpen)
	if (self.parent.gateType == game.GATE_TYPE.test or dataEasy.isUnlock(gUnlockCsv.ultraAcc)) then
		self.passButton:show()
	else
		self.passButton:hide()
	end
	self.passButton:onClick(function()
		local passOpen = userDefault.getForeverLocalKey("mainSkillPass", false)
		if passOpen then
			-- 关闭状态
			print("MainSkillPass Close")
		else
			-- 开启状态
			print("MainSkillPass Open")
		end
		passOpen = not passOpen
		userDefault.setForeverLocalKey("mainSkillPass", passOpen)
		imgOpen:visible(passOpen)
		imgClose:visible(not passOpen)
	end)
end

function SysSetting:onSetOperators(opeArgs)
	--自动战斗按钮
	self:setAutoButton(opeArgs)

	-- 暂停按钮
	self:setPauseButton(opeArgs)

	-- 加速按钮
	self:setSpeedButton(opeArgs)

	-- 跳过按钮
	self:setSkipButton(opeArgs)

	-- 大招跳过按钮
	self:setPassButton(opeArgs)

	self.buttonCapture:refresh()
end

function SysSetting:onClickPass()
	if self.parent.gateType == game.GATE_TYPE.crossMine then
		self.parent:handleOperation(battle.OperateTable.passOneWave)
	else
		if self.parent.isModelPass then
			return
		end
		self.parent.isModelPass = true
		self.parent:handleOperation(battle.OperateTable.pass)
	end
end

function SysSetting:onNewBattleRound(args)
	if not (self.parent.gateType == game.GATE_TYPE.crossMine and args.wave and args.totalWave) then
		return
	end
	if not self.isLastWave and args.wave >= args.totalWave then
		self.isLastWave = true
		if self.originPassStr then
			self.skipButton:get("text"):text(self.originPassStr)
		end
	end
end

function SysSetting:onClose()
	self.buttonCapture:hide()
end

function SysSetting:setPauseBtn(texture,onClick)
	if texture then
		self.pauseButton:get("settingImg"):loadTexture(texture)
	end

	if onClick then
		self.pauseButton:onClick(onClick)
	end

	self.buttonCapture:refresh()
end

function SysSetting:setSpeedBtn(speedNum)
	local speedBtn = self.speedButton:get("speed")
	speedBtn:setString(string.format("x%d",speedNum))
	self.parent:handleOperation(battle.OperateTable.timeScale, speedNum)

	self.buttonCapture:refresh()
end

function SysSetting:setJumpSkillBtn(passOpen)
	local imgOpen = self.passButton:get("imgOpen")
	local imgClose = self.passButton:get("imgClose")
	imgOpen:visible(passOpen)
	imgClose:visible(not passOpen)
	userDefault.setForeverLocalKey("mainSkillPass", passOpen)

	self.buttonCapture:refresh()
end

function SysSetting:setAutoBtn(isAuto, clickCall)
	local autoBtn = self.autoButton:get("auto")
	autoBtn:setString(isAuto and gLanguageCsv.auto or gLanguageCsv.manual)
	self.parent:handleOperation(battle.OperateTable.autoFight, isAuto)

	if clickCall then
		self.autoButton:onClick(functools.partial(clickCall,self.autoButton))
	end

	self.buttonCapture:refresh()
end

return SysSetting