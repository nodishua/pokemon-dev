-- @desc 世界boss副本的显示界面

local _format = string.format

local BattleOnlineFightView = class("BattleOnlineFightView", battleModule.CBase)

BattleOnlineFightView.RESOURCE_FILENAME = "battle_online_fight.json"
BattleOnlineFightView.RESOURCE_BINDING = {
	["tipBg.cutdownimg"] = "cutdownimg",
	["tipBg"] = "tipBg",
	["tipBg.waitloadingPnl.waitloadinglabel"] = {
		varname = "waitloadinglabel",
		binds = {
			event = "effect",
			data = {outline={color=cc.c4b(241, 60, 84, 255)}}
		}
	},
	["tipBg.waitloadingPnl"] = "waitloadingPnl",
	["tipBg.waitloadingPnl.effect1"] = "waitEffect1",
	["tipBg.waitloadingPnl.effect2"] = "waitEffect2",
	["tipBg.waitloadingPnl.effect3"] = "waitEffect3",
	["tipBg.waitlabel"] = {
		varname = "waitlabel",
		binds = {
			event = "effect",
			data = {outline={color=cc.c4b(241, 60, 84, 255)}}
		}
	},
}

local resPath = 'battle/online_fight/'

local ViewState = {
	null 			= 0,
	waitloading 	= 4,
	attack 			= 5,
	wait 			= 6,
	record          = 7,
}

-- call by battleModule.CBase.new
function BattleOnlineFightView:ctor(parent)
	battleModule.CBase.ctor(self, parent)

	self.root = cache.createWidget(self.RESOURCE_FILENAME)
	bindUI(self, self.root, self.RESOURCE_BINDING)
	-- self.root:addTo(parent.gameLayer):y(self.root:y() -150):show()
	self.root:addTo(parent,999):show()
	self:onHideStateTips()

	self.time = 0
	self.waitServerTime = 0
	self.state = ViewState.null
	self.defaultSpeed = 3
	-- self.waitEffect = nil
	self.exitShowTip = gLanguageCsv.onlineFightBattleGiveUpTip

	self.cutdownTime = idler.new(10)
	bind.extend(self.parent, self.cutdownimg, {
        class = 'text_atlas',
        props = {
            data = self.cutdownTime,
			align = "center",
			pathName = "online_fight_battle_cutdown",
        }
	})

	-- 显示区服
	-- dump(self.parent.data,nil,99)
	local t = self.parent.data
	self.leftHeadPnl = self.parent.UIWidgetLeft:get("infoPVP")
	self.rightHeadPnl = self.parent.UIWidgetRight:get("infoPVP")
	self.leftHeadPnl:get("level")
		:setFontSize(40)
		:anchorPoint(0,0.5)
		:x(self.leftHeadPnl:get("roleName"):x())
		:setString(getServerArea(t.role_key[1], true))
	self.leftHeadPnl:get("levelLv"):visible(false)
	self.rightHeadPnl:get("level")
		:setFontSize(40)
		:anchorPoint(1,0.5)
		:x(self.rightHeadPnl:get("roleName"):x())
		:setString(getServerArea(t.defence_role_key[1], true))
	self.rightHeadPnl:get("levellv"):visible(false)
	self:call('refreshInfoPvP')
	local play = self.parent:getPlayModel()
	local state = play.locals.state
	if state ~= ViewState.record then
		-- 暂停  默认三倍速 默认大招跳过
		self:call('setPauseBtn',"battle/pause/icon_tc.png",function()
			local content = gLanguageCsv.onlineFightBattleGiveUpTip
			if self.parent:getPlayModel().curRound <= gCommonConfigCsv.onlineFightFleeRoundLimit then
				local onlineFightFleeTime = userDefault.getForeverLocalKey("onlineFightFleeTime", {})
				if #onlineFightFleeTime >= 3 and (time.getTime() - onlineFightFleeTime[1] < 3600) then
					gGameUI:showTip(gLanguageCsv.onlineFightNoFlee)
					return
				end
				content = gLanguageCsv.onlineFightBattleFleeTip
			end

			audio.pauseAllSounds()
			gGameUI:showDialog({content = content, cb = function()
				self.parent:getPlayModel():sendExitGameMsg()
			end, btnType = 2, clearFast = true, isRich = true})
		end)
		self:call('setAutoBtn',false)
	else
		self:call('setAutoBtn',true,function(btn)
			btn:get("disabled"):show()
			btn:get("lock"):show()
		end)
	end
	self:call('setSpeedBtn',self.defaultSpeed)
	self:call('setJumpSkillBtn',true)

	self:init()
end

function BattleOnlineFightView:init()
	-- self:onPlayOnlineFightState()
	self.waitloadinglabel:setText(gLanguageCsv.beWaitLoading)
	self.waitlabel:setText(gLanguageCsv.beWait)
end

-- function BattleOnlineFightView:onChangeOnlineViewState(state)
-- 	-- 1.waitloading -> attack
-- 	-- 2. attack
-- 	print("onChangeOnlineViewState",state)
-- 	if self.state ~= state then
-- 		-- if self.waitEffect then
-- 		-- 	self.waitEffect:stop()
-- 		-- 	self.waitEffect = nil
-- 		-- end
-- 		-- waitloading 中断
-- 		if self.state == 0 and state == ViewState.waitloading then
-- 			-- self.waitEffect = self.parent:onEventEffectQueue('wait')
-- 			self:playFadeEffect(self.waitEffect1,0)
-- 			self:playFadeEffect(self.waitEffect2,0.2)
-- 			self:playFadeEffect(self.waitEffect3,0.4)
-- 		else
-- 			self.waitEffect1:stopAllActions()
-- 			self.waitEffect2:stopAllActions()
-- 			self.waitEffect3:stopAllActions()
-- 		end

-- 		-- 切换表现
-- 		self.state = state
-- 	end
-- end

function BattleOnlineFightView:onUpdate(delta)

end

function BattleOnlineFightView:onPlayOnlineFightState()
	local play = self.parent:getPlayModel()
	local state = play.locals.state
	if self.state == state and state ~= ViewState.attack then return end
	-- if self.state ~= ViewState.null and state == ViewState.waitloading then return end

	local x, y = self.waitloadingPnl:getPosition()

	if state == ViewState.waitloading then
		self:refreshCutDownTime()
		self.cutdownimg:visible(true)
		self.waitloadingPnl:visible(true)
		self.waitlabel:visible(false)
		self.cutdownimg:setPosition(cc.p(x, y - 100))
		self:playFadeEffect(self.waitEffect1,0)
		self:playFadeEffect(self.waitEffect2,0.2)
		self:playFadeEffect(self.waitEffect3,0.4)
		setContentSizeOfAnchor(self.tipBg,cc.size(1065,157))
		-- self.tipBg:setContentSizeOfAnchor(cc.size(1065,157))
	elseif state == ViewState.wait or state == ViewState.attack then
		self:refreshCutDownTime()
		self.cutdownimg:setPosition(cc.p(x, y))
		self.cutdownimg:visible(true)
		self.waitloadingPnl:visible(false)
		self.waitlabel:visible(false)
		setContentSizeOfAnchor(self.tipBg,cc.size(273,141))
	elseif state == ViewState.record then
		self.cutdownimg:visible(false)
		self.waitloadingPnl:visible(false)
		self.waitlabel:visible(false)
		self.tipBg:visible(false)
		-- self.tipBg:setCfontentSizeOfAnchor(cc.size(273,141))
	end

	-- waitloading -> any stopAllActions
	if self.state == ViewState.waitloading then
		self.waitEffect1:stopAllActions()
		self.waitEffect2:stopAllActions()
		self.waitEffect3:stopAllActions()
		-- 攻击状态 补充表现
		if state == ViewState.attack then
			if not play:isNowTurnAutoFight() then
				self:call("showSKillUIWidgets",true)
			end
		end
	end

	self.state = state
	if self.state == ViewState.record then return end
	self.tipBg:visible(true)
end

function BattleOnlineFightView:onHideStateTips()
	-- self.cutdownimg:visible(false)
	-- self.waitloadinglabel:visible(false)
	-- self.waitlabel:visible(false)
	if self.state == ViewState.record then return end
	self.state = ViewState.null
	self.tipBg:visible(false)
end

function BattleOnlineFightView:onNewBattleRound(args)
	-- local play = self.parent:getPlayModel()
	-- local state = play.locals.state
	-- if state == ViewState.waitloading then return end
	-- if state == ViewState.record then return end
	local play = self.parent:getPlayModel()
	if play.locals.scene_state == game.SYNC_SCENE_STATE.waitloading then return end

	-- 加速
	local lerpFrame = play:isLocalSlow()
	if lerpFrame then
		display.director:getScheduler():setTimeScale(gCommonConfigCsv.onlineFightLateSpeedUpTime)
	else
		display.director:getScheduler():setTimeScale(self.defaultSpeed)
	end

	local offline = play:getoffLineTb()
	for i=1,2 do
		if offline then
			self:playerOffline(play.operateForce == i and self.leftHeadPnl or self.rightHeadPnl,offline[i])
		end
	end
	self:onPlayOnlineFightState()
end

function BattleOnlineFightView:playerOffline(userNode,isOffLine)
	local roleImg = userNode:get("roleImg")
	-- 掉线 且 掉线提示字存在
	if isOffLine and userNode:get('offlineText') then return end
	-- -- 没有掉线 且 掉线提示文字不存在
	-- print('[TODO: TempLog] not isOffLine',not isOffLine,not roleImg:get('offlineText'),roleImg:get('offlineText'))
	if not isOffLine and userNode:get('offlineText') == nil then return end

	userNode:removeChildByName("offlineText")

	cache.setShader(roleImg, false, isOffLine and "hsl_gray" or "normal")
	if isOffLine then
		label.create(gLanguageCsv.onlineFightOffline, {
			fontPath = "font/youmi1.ttf",
			fontSize = 40,
			effect = {color = ui.COLORS.NORMAL.WHITE, outline = {color = ui.COLORS.NORMAL.DEFAULT}},
		}):addTo(userNode, roleImg:z() + 1, "offlineText")
			:xy(roleImg:xy())
	end
	self:call('refreshInfoPvP')
end

function BattleOnlineFightView:refreshCutDownTime()
	local play = self.parent:getPlayModel()
	local t = play:getCountDown()
	printDebug(t.clock_str,t.secstr)
	-- local time = math.max(math.ceil(countDown - os.time()),0)
	local sec = t.sec
	local timeScale = display.director:getScheduler():getTimeScale()
	-- self.cutdownTime:set(t.sec)
	self.cutdownimg:stopAllActions()
	if t.sec <= 0 then return end
	self.cutdownimg:runAction(cc.Repeat:create(
		cc.Sequence:create(
			cc.CallFunc:create(function()
				self.cutdownTime:set(sec)
				sec = sec - 1
			end),
			cc.ScaleTo:create(0.2 * timeScale, 1),
			cc.DelayTime:create(0.6 * timeScale),
			cc.ScaleTo:create(0.2 * timeScale, 1.3),
			cc.CallFunc:create(function()
				if sec == 0 then self.tipBg:visible(false) end
			end)
		),t.sec
	))
end

function BattleOnlineFightView:playFadeEffect(node,delay)
	node:runAction(cc.Sequence:create(
		cc.DelayTime:create(delay),
		cc.CallFunc:create(function()
			node:runAction(cc.RepeatForever:create(
				cc.Sequence:create(
					cc.FadeIn:create(1),
					cc.FadeOut:create(2)
				)
			))
		end)
	))
end

function BattleOnlineFightView:onSceneOver(result)
	self.cutdownimg:stopAllActions()
	self.waitEffect1:stopAllActions()
	self.waitEffect2:stopAllActions()
	self.waitEffect3:stopAllActions()
end

return BattleOnlineFightView