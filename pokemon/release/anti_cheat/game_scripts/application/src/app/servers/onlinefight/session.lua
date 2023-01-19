--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2018 TianJi Information Technology Inc.
--
-- session for onlinefight server
--

local Packet = require('net.tcpacket')
local Session = require('net.rudpsession')

local OnlineFightBattleSession = class('OnlineFightBattleSession', Session)

OnlineFightBattleSession.StepInitToLogin = Session.StepInitCustom
OnlineFightBattleSession.StepInitWaitLogin = Session.StepInitCustom + 1
OnlineFightBattleSession.StepInitLoginConfirm = Session.StepInitCustom + 2

function OnlineFightBattleSession:init(host, port, roleID, serverKey, cb)
	self.roleID = roleID
	self.serverKey = serverKey
	self._initCB = cb
	local domains = string.split(serverKey, '.')
	self.serverID = tonumber(domains[#domains])
	assert(self.serverID ~= nil, string.format("%s was invalid game key", serverKey))
	self.lastNetTestTime = 0 -- ms
	Session.init(self, host, port)
end

function OnlineFightBattleSession:setInitStep(step)
	local old = self.initStep
	if old == self.StepInitConnected and step == self.StepInitOK then
		-- insert custom step
		self.initStep = self.StepInitToLogin
	else
		self.initStep = step
	end
end

function OnlineFightBattleSession:_initSession()
	local ret = Session._initSession(self)
	if not ret or self.initStep < self.StepInitConnected then
		return ret
	end

	if self.initStep == self.StepInitToLogin then
		printInfo('%s %s login to %s:%s', tostring(self), self.sockID, self.host, self.port)
		self:setInitStep(self.StepInitWaitLogin)
		self:_onSendLogin()

	elseif self.initStep == self.StepInitWaitLogin or self.initStep == self.StepInitLoginConfirm then
		return false, true
	end

	return false
end

function OnlineFightBattleSession:_onSendLogin()
	self.net:sendPacket("/onlinefight/login", {
		role_id = self.roleID,
		serv_key = self.serverKey,
	})
end

function OnlineFightBattleSession:update(delta)
	if self.host and self.sock then
		self.lastNetTestTime = self.lastNetTestTime + delta
		if self.lastNetTestTime > 2 then
			self.lastNetTestTime = 0
			self.net:sendPacket("/onlinefight/net/test", {
				client_time = socket.gettime() * 1000,
			})
		end
	end
	Session.update(self, delta)
end

function OnlineFightBattleSession:newPacket(url, input)
	-- local wrapData = {
	-- 	input = data,
	-- }
	return Session.newPacket(self, url, input)
end

function OnlineFightBattleSession:_onInitOK()
	printInfo('%s %s ok %s:%s', tostring(self), self.sockID, self.host, self.port)

	if self._initCB then
		local ret, err = self._initData
		if not ret or not ret.ret then
			ret, err = nil, ret
		end
		self._initCB(ret, err)
		self._initCB, self._initData = nil, nil
	end
end

function OnlineFightBattleSession:_onInitErr()
	printWarn("OnlineFightBattleSession:_onInitErr()")
	self.host = nil
	self:close()

	if self._initCB then
		self._initCB(nil, self._initData)
		self._initCB, self._initData = nil, nil
	else
		gGameModel.battle.error:set(self._initData.err)
	end
end

-- 非主动sock关闭，单次网络错
function OnlineFightBattleSession:_onClose(err)
	printWarn("OnlineFightBattleSession._onClose")

	Session._onClose(self, err)
end

-- 重试也出错，放弃重试
function Session:_onLost()
	printWarn("%s %s onLost", tostring(self), self.sockID)

	gGameModel.battle.error:set('network_on_lost')
end

return OnlineFightBattleSession