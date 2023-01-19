--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2018 TianJi Information Technology Inc.
--
-- onlinefight task from server
--

local TaskBase = require 'net.tcptask'

local TOnlineFightLogin = class('TOnlineFightLogin', TaskBase)
TOnlineFightLogin.Url = "/onlinefight/login"

function TOnlineFightLogin:run()
	printInfo('onlinefight login package %s', self.data.ret)
	if not self.data.ret then
		self.session._initData = {ret = false, err = self.data.err}
		self.session.initStep = self.session.StepInitErr
		return
	end
	self.session.initStep = self.session.StepInitOK
	printInfo('onlinefight login packet ack')

	if self.data.cross_online_fight_banpick then
		local model = self.session.net.game.model
		model:syncFromServer({model = {cross_online_fight_banpick = self.data.cross_online_fight_banpick}})
		self.data.cross_online_fight_banpick = nil
	end

	if self.data.cross_online_fight_battle then
		local model = self.session.net.game.model
		model:syncFromServer({model = {cross_online_fight_battle = self.data.cross_online_fight_battle}})
		self.data.cross_online_fight_battle = nil
	end

	if self.data.remotes then
		local model = self.session.net.game.model
		model.battle:fromServer(self.data.remotes)
		self.data.remotes = nil
	end

	if self.data.banpick then
		local model = self.session.net.game.model
		model.cross_online_fight_banpick:fromServer(self.data.banpick)
		self.data.banpick = nil
	end
	self.session._initData = self.data
end

local TOnlineFightPush = class('TOnlineFightPush', TaskBase)
TOnlineFightPush.Url = "/onlinefight/push"

function TOnlineFightPush:run()
	if self.data.cross_online_fight_battle then
		local model = self.session.net.game.model
		model:syncFromServer({model = {cross_online_fight_battle = self.data.cross_online_fight_battle}})
		self.data.cross_online_fight_battle = nil
	end
	if self.data.cross_online_fight_banpick then
		local model = self.session.net.game.model
		model:syncFromServer({model = {cross_online_fight_banpick = self.data.cross_online_fight_banpick}})
		self.data.cross_online_fight_banpick = nil
	end

	if self.data.remotes then
		local model = self.session.net.game.model
		model.battle:fromServer(self.data.remotes,self.data.rand_counts)
		self.data.remotes = nil
	end
	if self.data.banpick then
		local model = self.session.net.game.model
		model.cross_online_fight_banpick:fromServer(self.data.banpick)
		self.data.banpick = nil
	end
end

local TOnlineFightInput = class('TOnlineFightInput', TaskBase)
TOnlineFightInput.Url = "/onlinefight/input"

function TOnlineFightInput:run()
	self:ackCallBack()
end

local TOnlineFightAttack = class('TOnlineFightAttack', TaskBase)
TOnlineFightAttack.Url = "/onlinefight/attack"

function TOnlineFightAttack:run()
	self:ackCallBack()
end

local TOnlineFightBanPick = class('TOnlineFightBanPick', TaskBase)
TOnlineFightBanPick.Url = "/onlinefight/banpick"

function TOnlineFightBanPick:run()
	self:ackCallBack()
end

local TOnlineFightNetTest = class('TOnlineFightNetTest', TaskBase)
TOnlineFightNetTest.Url = "/onlinefight/net/test"

function TOnlineFightNetTest:run()
	if self.data.ret then
		local rtt1 = self.data.server_time - self.data.client_time
		local rtt2 = socket.gettime() * 1000 - self.data.client_time
		-- print('rtt1:', rtt1, 'rtt2:', rtt2)
		-- print('!!!', socket.gettime() * 1000)
		if CC_SHOW_FPS == true then
			local str = string.format("rtt1: %.2f ms\nrtt2: %.2f ms", rtt1, rtt2)
			local onlineFightText = gGameUI.scene:get("onlineFightText")
			if not onlineFightText then
				onlineFightText = ccui.Text:create("", "font/youmi1.ttf", 40)
					:anchorPoint(cc.p(0, 0))
					:xy(10, 320)
					:addTo(gGameUI.scene, 1000, "onlineFightText")
				text.addEffect(onlineFightText, {color = ui.COLORS.NORMAL.WHITE, outline = {color = ui.COLORS.NORMAL.DEFAULT}})
			end
			onlineFightText:text(str):show()
			onlineFightText:stopAllActions()
			performWithDelay(onlineFightText, function()
				onlineFightText:hide()
			end, 5)
		end
	end
	self:ackCallBack()
end

local TOnlineFightControl = class('TOnlineFightControl', TaskBase)
TOnlineFightControl.Url = "/onlinefight/control"

function TOnlineFightControl:run()
	self:ackCallBack()
end

nettask.registerTasks({
	TOnlineFightLogin,
	TOnlineFightPush,
	TOnlineFightInput,
	TOnlineFightAttack,
	TOnlineFightNetTest,
	TOnlineFightControl,
})
