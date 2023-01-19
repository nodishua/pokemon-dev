--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2018 TianJi Information Technology Inc.
--
-- session for login server
--

local Packet = require('net.tcpacket')
local Session = require('net.tcpsession')

local GameSession = class('GameSession', Session)

function GameSession:init(host, port, accountID, serverKey)
	self.accountID = accountID
	self.serverKey = serverKey
	local domains = string.split(serverKey, '.')
	self.serverID = tonumber(domains[#domains])
	assert(self.serverID ~= nil, string.format("%s was invalid game key", serverKey))
	Session.init(self, host, port)
end

function GameSession:newPacket(url, data)
	local wrapData = gGameModel:syncData()
	wrapData.id = self.accountID
	wrapData.servid = self.serverID
	wrapData.servkey = self.serverKey
	wrapData.input = data
	return Session.newPacket(self, url, wrapData)
end

function GameSession:_onInitOK()
	printInfo('%s %s ok %s:%s', tostring(self), self.sockID, self.host, self.port)
end

function GameSession:_onInitErr()
	printWarn("GameSession:_onInitErr()")
end

return GameSession