--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2016 TianJi Information Technology Inc.
--
-- GameNet
--

local NetManager = require("net.manager")
local GameNet = class("GameNet", NetManager)


function GameNet:ctor(game)
	self.game = game

	self.noticeUrl = 'http://192.168.1.99:18080/notice'
	self.versionUrl = 'http://192.168.1.99:18080/version'
	self.serverUrl = 'http://192.168.1.99:18080/servers'
	self.loginAddress = '192.168.1.99:16666'
	self.loginHost = '192.168.1.99'
	self.loginPort = 16666
	self.gameHost = '192.168.1.99'
	self.gamePort = 18080

	self.loginSession = require("app.servers.login.session").new(self)
	self.gameSession = require("app.servers.game.session").new(self)
	self.onlinefightSession = require("app.servers.onlinefight.session").new(self)

	NetManager.ctor(self)
end

function GameNet:initLoginUrl()
	self.noticeUrl = NOTICE_CONF_URL
	self.versionUrl = VERSION_CONF_URL
	self.serverUrl = SERVER_CONF_URL
	self.loginAddress = LOGIN_SERVRE_HOSTS_TABLE[math.random(1, #LOGIN_SERVRE_HOSTS_TABLE)]

	self.loginHost, self.loginPort = string.gmatch(self.loginAddress, '([-a-z0-9A-Z.]+):(%d+)')()
	self.loginPort = tonumber(self.loginPort)
end

function GameNet:setGameAddr(server)
	self.gameAddress = server.addr
	self.gameHost, self.gamePort = string.gmatch(self.gameAddress, '([-a-z0-9A-Z.]+):(%d+)')()
	self.gameSession:init(self.gameHost, self.gamePort, self.game.model.account:read('id'), server.key)
end

function GameNet:doLogin(userName, cb)
	self.loginSession:init(self.loginHost, self.loginPort, userName, cb)
end

function GameNet:doLoginEnd()
	self.loginSession:sleep()
end

function GameNet:doGameEnd()
	self:initLoginUrl()
	self.gameSession:sleep()
end

function GameNet:doRealtime(host, port, cb)
	local roleid = self.game.model.role:read('id')
	local serverkey = userDefault.getForeverLocalKey("serverKey", nil, {rawKey = true})
	self.onlinefightSession:init(host, port, roleid, serverkey, cb)
end

function GameNet:doRealtimeEnd()
	self.onlinefightSession:sleep()
end

function GameNet:getSessionByService(service)
	if service == "game" then
		return self.gameSession
	elseif service == "onlinefight" then
		return self.onlinefightSession
	else
		return self.loginSession
	end
end

function GameNet:updateSession(delta)
	self.loginSession:update(delta)
	self.gameSession:update(delta)
	self.onlinefightSession:update(delta)
end


return GameNet