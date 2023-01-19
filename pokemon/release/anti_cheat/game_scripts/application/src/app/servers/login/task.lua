--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2018 TianJi Information Technology Inc.
--
-- login task from server
--

require "ymdump"

local TaskBase = require 'net.tcptask'

--------------------------
-- local TLoginCheck
-- 登录
--
-- client send data scheme
-- {
-- 	name <str> 用户名
-- }
--
-- client recv data scheme
-- {
-- 	ret <bool> 是否成功
-- 	session_pwd <*str> 会话协议密码
-- 	err <*str> 错误描述
-- }
--

local TLoginCheck = class('TLoginCheck', TaskBase)
TLoginCheck.Url = "/login/check"

function TLoginCheck:run()
	self.session.initStep = self.session.StepInitLoginConfirm
	printInfo('login packet %s', self.data.ret)

	if not self.data.ret then
		self.session._initData = {ret = false, err = self.data.err, version = self.data.version}
		self.session.initStep = self.session.StepInitErr
		return
	end

	-- for login session
	if #self.data.session_pwd == 16 then
		self.session:setNewPwd(self.data.session_pwd)
	end

	-- for dev
	if self.data.is_new then
		gGameUI:showTip("这是新号"..self.data.account.name)
	end

	ymdump.setUserInfo("account", self.data.account.name or "")

	-- 服务器返回的name是相关sdk返回的结果
	local model = self.session.net.game.model
	model:syncFromServer({model = {account = {_db = self.data.account}}})

	-- 实名认证用account.name
	sdk.onLogin(self.data.account.name)

	return self:synPacket("/login/confirm", {
		name = self.data.name,
	})
end

--------------------------
-- local TLoginConfirm
-- 登录确认
--
-- client send data scheme
-- <bool> 是否确认
--
-- client recv data scheme
-- <bool> 是否确认
--

local TLoginConfirm = class('TLoginConfirm', TaskBase)
TLoginConfirm.Url = "/login/confirm"

function TLoginConfirm:run()
	self.session.initStep = self.session.StepInitOK
	printInfo('login confirm packet ack')

	self.session._initData = {
		ret = true,
		servers = self.data.servers,
		-- name = self.net.game.model.account.name,
		-- channel = self.net.game.model.account.channel,
		-- role_infos = self.net.game.model.account.role_infos,
		-- is_new = self.net.game.model.account.is_new,
	}
end

--------------------------
-- local TLoginEnterServer
-- 登录服务器
--
-- client send data scheme
-- {
-- 	server <str> 选择服务器的URL
-- }
--
-- client recv data scheme
-- <bool> 是否确认
--

local TLoginEnterServer = class('TLoginEnterServer', TaskBase)
TLoginEnterServer.Url = "/login/enter_server"

function TLoginEnterServer:run()
	printInfo('login enter server ack %s', self.data.ret and 'ok' or 'err')

	ymdump.setUserInfo("server", self.data.serv_key or "")

	self:ackCallBack()
	-- /game/login报错，停留在选服界面，所以先不关闭login，等/game/login完成后清理
end


--------------------------
-- local TLoginEnterOK
-- 登录服务器
--
-- client send data scheme
-- {
-- }
--

local TLoginEnterOK = class('TLoginEnterOK', TaskBase)
TLoginEnterOK.Url = "/login/ok"

function TLoginEnterOK:run()
end

nettask.registerTasks({
	TLoginCheck,
	TLoginConfirm,
	TLoginEnterServer,
	TLoginEnterOK,
})