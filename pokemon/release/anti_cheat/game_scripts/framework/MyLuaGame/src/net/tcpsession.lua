--
-- Copyright (c) 2014 YouMi Technologies Inc.
--
-- Date: 2014-07-28 17:56:18
--


-- local _logincmd = require "net.task.logincmd_defines"
local lnconv = require 'net.lnconv'
local Packet = require 'net.tcpacket'

local _aes = require 'aes'
local AESKeyHex = _aes.key128Hex

local InitPwdAES = 'tjshuma081610888'
local InitPwdHexAES = AESKeyHex(InitPwdAES)

local RetryMax = 3
local SockIDCounter = 1

-- this timeout not in logic, and it longer than NoTransferTimeout
local SockCheckTimeout = 60

local Session = class('Session')

-- define
Session.InitTimeout = 5

-- step defines
Session.StepInitStart = 0
Session.StepInitConnected = 1
Session.StepInitCustom = 10
Session.StepInitCustomEnd = 90
Session.StepInitOK = 97
Session.StepInitErr = 98
Session.StepInitEnd = 99


-- member method
function Session:ctor(net)
	self.net = net
	self.sock = nil
	self.sockID = nil
	self.packetSendQue = CList.new()
	self.lastTransferTime = 0
	self.lastSendIdx = 1
	self.partRecv = ''
	self.leftRecv = 0
	self.recvPacket = nil
	self.noConnected = true
	self.lastTime = 0
	self.initStep = self.StepInitStart
	self.reconnTimes = RetryMax -- 重试3次
	self.sentSynIDs = {}
	self.sentCBMap = {}
end

function Session:init(host, port)
	self:close()

	-- host = "127.0.0.1" -- TEST: in home
	self.host, self.port = host, port
	self.reconnTimes = RetryMax -- 重试3次
	self.sentSynIDs = {}
	self.sentCBMap = {}
	self.initStep = self.StepInitStart

	self:initPwd()
	self:_initSock()
	self:_initSession()
end

function Session:_initSock()
	if self.sock then
		printInfo('%s %s close and new', tostring(self), self.sockID)
		self.net:removeSelectSock(self.sockID)
		self.sock:close()
	end

	self.sock = nil
	self.sockID = nil
	self:_cleanSent()

	-- new socket
	local family, addr = lnconv.getAddr(self.host)
	if "inet6" == family then
		self.sock = socket.tcp6()
	else
		self.sock = socket.tcp()
	end
	self.sock:settimeout(0) -- 非阻塞
	self.sock:setoption('keepalive', true)
	self.sock:setoption('tcp-nodelay', true)

	-- socket will be reused, so tostring(self.sock) not unique
	self.sockID = SockIDCounter
	SockIDCounter = SockIDCounter + 1
end

function Session:initPwd()
	self.pwdAES = InitPwdAES
	self.pwdHexAES = InitPwdHexAES
end

function Session:setNewPwd(pwd)
	self.pwdAES = pwd
	self.pwdHexAES = AESKeyHex(pwd)
	assert(self.pwdHexAES, string.format('pwd %s no hex', pwd))
end

function Session:reconnect()
	if not self.host then return end

	printWarn('%s %s re-connect %s %s left %d', tostring(self), self.sockID, self.host, self.port, self.reconnTimes)

	self:close()
	self.reconnTimes = self.reconnTimes - 1
	if self.reconnTimes < 0 then
		printWarn('%s %s try re-connect max limited', tostring(self), self.sockID)
		self.initStep = self.StepInitEnd
		self:_onLost()
		return
	end

	self:initPwd()
	self:_initSock()
	self.initStep = self.StepInitStart
	self:_onReconnectInit()
	self:_initSession()
end

function Session:reconnectManual()
	printInfo('reconnect manual')

	self.reconnTimes = RetryMax
	self:reconnect()
end

function Session:isShutdown()
	return self.noConnected and self.reconnTimes <= 0 and self.initStep == self.StepInitEnd
end

function Session:send(packet, sentCB)
	self.sentCBMap[packet.synID] = sentCB
	self.packetSendQue:push_back(packet)
	self.lastTransferTime = os.time()

	if self.sock == nil then
		printWarn('%s sock %s lost', tostring(self), self.sock)
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

	-- recv in select callback
	-- send in update
	self:asyncRecvUntilOnePacket()

	-- send heart packet
	local checkHeart = os.time() - self.lastTransferTime
	if checkHeart > SockCheckTimeout then
		-- avoid heart in 5s
		self.lastTransferTime = os.time() - SockCheckTimeout + 5
		printWarn("%s %s long time no heart pulse %ss", tostring(self), self.sockID, checkHeart)
		local heart = Packet.new()
		heart:setHeartSyn()
		self.packetSendQue:push_back(heart)
	end

	-- handle send packet
	while not self.packetSendQue:empty() do
		if self.sock == nil then return end
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

-- 主动关闭
function Session:close()
	if self.sock then
		printInfo('%s %s close %s:%s', tostring(self), self.sockID, self.host, self.port)
		self.net:removeSelectSock(self.sockID)
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

-- 关闭login或者game，且不重连
function Session:sleep()
	if self.sock then
		printInfo('%s %s sleep %s:%s', tostring(self), self.sockID, self.host, self.port)
	end

	self.host = nil -- 防止reconnect
	self:close()
	self.initStep = self.StepInitEnd
end

function Session:setInitStep(step)
	self.initStep = step
end

function Session:newPacket(url, data)
	local packet = Packet.new(self)
	packet:setSynData(url, data)
	return packet
end

function Session:_initSession()
	if not self.noConnected then return false end
	if self.initStep == self.StepInitStart then
		if self.lastTime == 0 then
			-- it's non-block connect
			local family, addr = lnconv.getAddr(self.host)
			printInfo('%s %s start to connect %s %s', tostring(self), self.sockID, addr, self.port)
			local ret, err = self.sock:connect(addr, self.port)
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

				-- timeout, use select wait
				self.net:selectSock(self.sockID, self.sock, false, true, self.InitTimeout, function(r, w, err)
					if w then
						printInfo('%s %s connected %s:%s', tostring(self), self.sockID, self.host, self.port)
						self:setInitStep(self.StepInitConnected)

					else
						self:_onClose(err)
					end
				end)
			end
		end

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

-- @param timeout: nil is use NetManager:_select time delta
function Session:asyncRecvUntilOnePacket(timeout)
	if self.sock == nil or self.recving then return end
	self.recving = true
	local sockID = self.sockID
	self.net:selectSock(self.sockID, self.sock, true, false, timeout, function(r, w, err)
		self.recving = false
		-- sock be closed, r=true, err=closed
		if self.sock == nil then
			-- closed in logic
			r, w = false, false
			err = "closed"

		-- old sock event
		-- in `reconnect` or `initSock`, the close and new come together
		-- but ymasync.select callback was async
		-- so need check the sockID when self.sock not nil
		elseif sockID ~= self.sockID then
			printInfo('%s %s old event %d %s %s %s', tostring(self), self.sockID, sockID, r, w, err)
			return
		end

		if r then
			while true do
				if self.leftRecv > 0 then
					local data, recvErr, part = self.sock:receive(self.leftRecv)
					printDebug('%s %s recving len=%d err=%s', tostring(self), sockID, data and #data or #part, recvErr)

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
						-- discard when error
						if not ret then
							self.recvPacket = nil
							break
						end
					end

					if recvErr then
						-- jump to next block
						if recvErr == "timeout" then
							err = self.net:onTimeout(self) or err
						else
							err = recvErr
						end
						break
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
			end
		end

		if err then
			printWarn('%s %s recv err=%s', tostring(self), sockID, err)
			if self.sock then
				self:_onClose(err)
			end
		end
	end)
end

-- @return true 当前packet发送成功，从队列里移除
function Session:_send(packet)
	-- if ok: number, nil, nil
	-- if err: nil, string, number
	local index, err, lastIndex = self.sock:send(packet.data, self.lastSendIdx)
	printDebug('%s %s sending len=%d last=%d index=%s pindex=%s err=%s', tostring(self), self.sockID, #packet.data, self.lastSendIdx, index, lastIndex, err)
	printDebug('%s %s states %s %s %s', tostring(self), self.sockID, self.sock:getstats())

	if err and err ~= 'timeout' then
		printWarn('%s %s can not be sent err=%s pindex=%d', tostring(self), self.sockID, err, lastIndex)
		self:_onClose(err)
		return false
	end

	if index or lastIndex then
		self.lastTransferTime = os.time()
		self.lastSendIdx = (index or lastIndex) + 1
	end

	if self.lastSendIdx >= #packet.data then
		self.lastSendIdx = 1
		return true
	end
	return false
end

function Session:_cleanSent()
	-- send成功的，无法再重发，只能错误返回给上层
	-- 还没有send完的，存在packetSendQue队列里，会有重发
	local sentSynIDs, sentCBMap = self.sentSynIDs, self.sentCBMap
	self.sentSynIDs = {}
	self.sentCBMap = {}
	self.net:onInterruptedPakcet(sentSynIDs)
	for synID, cb in pairs(sentCBMap) do
		cb()
	end
end

-- 非主动sock关闭，单次网络错
function Session:_onClose(err)
	printWarn("%s %s onClose err=%s", tostring(self), self.sockID, err)

	self:reconnect()
end

-- 重试也出错，放弃重试
function Session:_onLost()
	-- TODO: may be request send ok, but no recv in long long time
	printWarn("%s %s onLost", tostring(self), self.sockID)

	local packet = self.packetSendQue:front()
	if packet ~= nil then
		self.net:onSessionLost(packet.synID)
	end
end

function Session:_onReconnectInit()
	-- self.packetSendQue:clear()
	self.lastSendIdx = 1
end

function Session:_onInitOK()
end

function Session:_onInitErr()
end

return Session