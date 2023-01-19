--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2018 TianJi Information Technology Inc.
--
-- game task from server
--

require "ymdump"

local TaskBase = require 'net.tcptask'

--------------------------
-- TGame
-- game通用task, 针对c->s pingpong 请求响应模式
--
-- @see GameSession:newPacket
-- client send data scheme
-- {
-- 	id <*int> accountID
-- 	servkey <*str> serverKey
--  csv <int> csv版本号
--  msg <int> 走马灯、聊天消息id
--  sync <table> 客户端向服务器同步数据
-- 	input <table> 请求数据
-- }
--
-- client recv data scheme
-- {
-- 	ret <bool> 是否成功
-- 	err <*str> 错误描述
--  session_pwd <*str> 会话协议密码
--  view <*table> 界面数据
--  model <*table> game model覆盖数据
--  sync <*table> game model同步数据
--  csv <*table> csv数据
--  msg <*table> 走马灯、聊天消息数据
-- }
--

local TGame = class('TGame', TaskBase)
-- TGame.Url = ""
TGame.Service = "game"

function TGame:run()
	if self.data.ret and self.data.session_pwd and #self.data.session_pwd == 16 then
		self.session:setNewPwd(self.data.session_pwd)
	end

	if self.data.model and self.data.model.role then
		ymdump.setUserInfo("role", stringz.bintohex(self.data.model.role._db.id or ""))
	end

	-- model, sync
	local model = self.session.net.game.model
	self.data = model:syncFromServer(self.data)
	-- csv
	-- msg
	return self:ackCallBack()
end

function TGame:ackCallBack()
	if not self.ackCB then
		return
	end

	-- no return packet in game logic callback
	local ackCB = self.ackCB
	self.ackCB = nil
	if self.data.ret then
		ackCB(self.data, nil)
	else
		ackCB(nil, self.data)
	end
end

--------------------------
-- TGamePush
-- 服务器推送
--
--

local TGamePush = class('TGamePush', TGame)
TGamePush.Url = "/game/push"

function TGamePush:run()
	if self.data.buy_recharge then
		local model = self.session.net.game.model
		model.role:pushBuyRecharge(self.data.buy_recharge)
		self.data.buy_recharge = nil
	end

	if self.data.cross_online_fight then
		local model = self.session.net.game.model
		model.cross_online_fight:pushMatchResult(self.data.cross_online_fight)
		self.data.cross_online_fight = nil
	end

	TGame.run(self)
end


nettask.registerTasks({
	TGamePush,
})

nettask.registerDefaultTask(TGame)