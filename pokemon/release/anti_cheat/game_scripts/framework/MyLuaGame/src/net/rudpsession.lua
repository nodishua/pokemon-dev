--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2018 TianJi Information Technology Inc.
--

local lnconv = require 'net.lnconv'
local Packet = require 'net.tcpacket'
local Connection = require 'net.rudp.connection'

local SockIDCounter = 1

local tcpsession = require('net.tcpsession')

local Session = class('Session', tcpsession)

function Session:_initSock()
	if self.sock then
		printInfo('%s %s close and new', tostring(self), self.sockID)
		-- self.net:removeSelectSock(self.sockID)
		self.sock:close()
	end

	self.sock = nil
	self.sockID = nil
	self:_cleanSent()

	-- new socket
	self.sock = Connection.new()
	self.sock:init()
	self.sockID = SockIDCounter
	SockIDCounter = SockIDCounter + 1
end

function Session:_initSession()
	if not self.noConnected then return false end
	if self.initStep == self.StepInitStart then
		if self.lastTime == 0 then
			-- it's non-block connect
			local ret, err = self.sock:connect(self.host, self.port)
			self.lastTime = os.time()
			if ret == nil then
				if err == 'already connected' then
					self:setInitStep(self.StepInitConnected)
					return true
				elseif err ~= 'timeout' then
					printWarn('%s %s can not connect %s:%s, err=%s', tostring(self), self.sockID, self.host, self.port, err)
					self:_onClose(err)
					return false
				end
			end
			return true
		end
		-- udp 直接认为ok
		self:setInitStep(self.StepInitConnected)
	elseif self.initStep == self.StepInitConnected then
		self:setInitStep(self.StepInitOK)

	-- do custom step
	elseif self.StepInitCustom <= self.initStep and self.initStep <= self.StepInitCustomEnd then
		return true

	elseif self.initStep == self.StepInitOK then
		self.noConnected = false
		self:setInitStep(self.StepInitEnd)
		self:_onInitOK()

	elseif self.initStep == self.StepInitErr then
		self:_onInitErr()

	end
	return false
end

function Session:send(packet, sentCB)
	if self.sock == nil then
		printWarn('%s sock %s lost', tostring(self), self.sock)
		self.net:onSessionLost(packet.synID)
		return
	end
	if not self.noConnected or packet.url == "/onlinefight/login" then
		self.sentCBMap[packet.synID] = sentCB
		self.packetSendQue:push_back(packet)
		self.lastTransferTime = os.time()
	else
		printWarn('%s sock %s connecting', tostring(self), self.sock)
		self.net:onSessionLost(packet.synID)
	end
end

function Session:update(delta)
	if not self.host then return end

	if self.noConnected and self.initStep < self.StepInitEnd then
		-- _initSession until blocking
		local loop, continue
		repeat
			loop, continue = self:_initSession()
		until not loop
		if not continue then return end
	end

	if self.sock == nil then return end

	self.sock:update(delta)
	-- recv until blocking
	while self:_recv() do end

	-- handle send packet
	while not self.packetSendQue:empty() do
		local packet = self.packetSendQue:front()
		printDebug('%s %s send packet len=%d', tostring(self), self.sockID, #packet.data)
		if not self:_send(packet) then
			break
		end
		self.packetSendQue:pop_front()
		if packet.synID then
			table.insert(self.sentSynIDs, packet.synID)
			local sentCB = self.sentCBMap[packet.synID]
			self.sentCBMap[packet.synID] = nil
			if sentCB then
				sentCB()
			end
		end
	end
end

-- @return true: continue, false: blocking
function Session:_recv()
	if self.leftRecv > 0 then
		local data, err, part = self.sock:receive(self.leftRecv)
		if err ~= "timeout" then
			printDebug('%s %s recving len=%d err=%s', tostring(self), self.sockID, data and #data or (data and #part or 0), err)
		end

		if data then
			self.lastTransferTime = os.time()
			self.leftRecv = 0
			self.partRecv = self.partRecv .. data
		elseif part and #part > 0 then
			self.lastTransferTime = os.time()
			self.leftRecv = self.leftRecv - #part
			self.partRecv = self.partRecv .. part
		end
		if self.leftRecv == 0 then
			local ret = self.recvPacket:parseNext(self.partRecv)
			if not ret then
				self.recvPacket = nil
			end
		end

		if err then
			if err ~= "timeout" then
				printWarn('%s %s recv err=%s', tostring(self), self.sockID, err)
				self:_onClose(err)
			end
			return false
		end
	else
		-- new packet
		if self.recvPacket == nil then
			self.recvPacket = Packet.new(self)

		-- complete packet
		elseif self.recvPacket:parseEnd() then
			local packet = self.recvPacket
			self.recvPacket = nil
			self.net:onRecvPacket(self, packet)

		-- parse next
		else
			self.leftRecv = self.recvPacket:nextLen()
			self.partRecv = ''
		end
	end
	return true
end

-- 主动关闭
function Session:close()
	if self.sock then
		printInfo('%s %s close %s:%s', tostring(self), self.sockID, self.host, self.port)
		-- self.net:removeSelectSock(self.sockID)
		self.sock:close()
	end

	self.sock = nil
	self.sockID = nil
	self:_cleanSent()

	-- 断线必然导致recv中的那个包的数据无效
	self.lastSendIdx = 1
	self.partRecv = ''
	self.leftRecv = 0
	self.recvPacket = nil
	self.noConnected = true
	self.lastTime = 0
	self.initStep = self.StepInitEnd
end

function Session:_cleanSent()
	-- send成功的，无法再重发，在这里也不需要返回给上层，与game不同
	-- 还没有send完的，存在packetSendQue队列里，会有重发
	self.sentSynIDs = {}
	self.sentCBMap = {}
end

return Session
