--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2018 TianJi Information Technology Inc.
--

local GeneralPackage = 512
local mss = GeneralPackage - 4
local maxIdleTimeout = 120 -- seconds

local strsub = string.sub

local Connection = class('Connection')

local RudpIDCounter = 1

function Connection:ctor()
	self.rudp = require('net.rudp.rudp').new(RudpIDCounter, function(b)
		self:output(b)
	end)
	RudpIDCounter = RudpIDCounter + 1
	self.sock = nil
	self.recvbuf = nil
	self.alivetime = os.time() -- 发送接收数据时间
end

function Connection:init()
	-- self:close()

	self.sock = socket.udp()
	self.sock:settimeout(0) -- 非阻塞
end

function Connection:connect(host, port)
	if not self.sock:setpeername(host, port) then
		return nil, 'setpeername error'
	end
	return 1
end

function Connection:close()
	if self.sock then
		self.rudp:close()
		self.sock:close()
		self.sock = nil
	end
end

function Connection:receive(size)
	-- receive from rudp
	while true do
		local data, err = self.rudp:receive()
		if err ~= nil then
			printWarn('receive from rudp error', err)
			return nil, err, nil
		end
		if data then
			if self.recvbuf == nil then
				self.recvbuf = data
			else
				self.recvbuf = self.recvbuf .. data
			end
		else
			break
		end
	end

	if self.recvbuf == nil or #self.recvbuf == 0 then
		return nil, 'timeout', nil
	end
	if #self.recvbuf == size then
		local data = self.recvbuf
		self.recvbuf = nil
		return data, nil, nil
	elseif #self.recvbuf < size then
		local data = self.recvbuf
		self.recvbuf = nil
		return nil, nil, data
	else
		local data = strsub(self.recvbuf, 1, size)
		self.recvbuf = strsub(self.recvbuf, size+1)
		return data, nil, nil
	end
end


function Connection:send(data)
	local total = 0
	local i = 1
	while i <= #data do
		local n, err = self.rudp:send(strsub(data, i, i+mss-1))
		if err ~= nil then
			return nil, err
		end
		i = i + mss
		total = total + n
	end
	return total
end

function Connection:rudpInput(data)
	-- local drop = math.random(1, 100)
	-- if drop > 50 then
	-- 	print('connection input drop data length', #data)
	-- 	return
	-- end
	printDebug('rudp connection input %d', #data)
	if self.rudp:input(data) then
		self.alivetime = os.time()
	end
	-- notify read
end

function Connection:output(data)
	-- local drop = math.random(1, 100)
	-- if drop > 50 then
	-- 	print('connection output drop data length', #data)
	-- 	return
	-- end
	local ret, err = self.sock:send(data)
	printDebug('rudp connection output %d %s', #data, err)
	-- print('output', string.byte(data, 1, #data))
end

function Connection:_recv()
	local data, err = self.sock:receive()
	if data then
		self:rudpInput(data)
	end
	if err then
		if err ~= 'timeout' then
			printWarn('Session recv err=%s', err)
			-- TODO: close
		end
		return false
	end
	return true
end


function Connection:update(delta)
	if self.sock == nil then return end

	delta = delta * 1000
	while self:_recv() do end
	if self.rudp:update(delta) then
		self.alivetime = os.time()
	end

	local now = os.time()
	if now - self.alivetime > maxIdleTimeout then
		printWarn('connection %d is idle, closing...', self.rudp.id)
		self:close()
	end

	if self.rudp.corrupt ~= nil then
	end
end

function Connection:getstats()
	return 0, 0, 0
end

return Connection
