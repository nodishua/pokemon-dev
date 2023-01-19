--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2018 TianJi Information Technology Inc.
--


local lnconv = require 'net.lnconv'
local ntol = lnconv.ntol
local lton = lnconv.lton
local ntol_s = lnconv.ntol_s
local lton_s = lnconv.lton_s

local bit = require 'bit'
local bnot, band, bor, bxor = bit.bnot, bit.band, bit.bor, bit.bxor
local lshift, rshift, rol = bit.lshift, bit.rshift, bit.rol

local strsub = string.sub
local strrep = string.rep
local strfmt = string.format

local Tag = {
	ping = 0,
	eof = 1,
	corrupt = 2,
	request = 3, -- +2
	missing = 4, -- +2
	ack = 5, -- +2(id) // less then id package confirmed delivery
	normal = 6, -- +2(id) + data
}

local MaxRtoTimeout = 120 * 60 * 1000 -- (ms)


-- [tag(length) (2 byte) id(2 byte)][data(len)]

local function fillHeader(id, length)
	return lton_s(length, 2, id, 2)
end

-- keepalive package
local function keepalive()
	return lton_s(Tag.ping, 2)
end

-- terminate package
local function terminate()
	return lton_s(Tag.eof, 2)
end

-- corrupt package
local function corrupt()
	return lton_s(Tag.corrupt, 2)
end

-- request package
local function request(id)
	return fillHeader(id, Tag.request)
end

-- missing package
local function missing(id)
	return fillHeader(id, Tag.missing)
end

-- ack package
local function ack(id)
	return fillHeader(id, Tag.ack)
end

local function packMessage(id, data)
	return fillHeader(id, #data + Tag.normal) .. data
end

local Queue = class('Queue')

function Queue:ctor()
	self.head = nil
	self.tail = nil
end

--- m {id, next}
function Queue:push(m)
	if self.tail == nil then
		self.head = m
		self.tail = m
	else
		self.tail.next = m
		self.tail = m
	end
end

function Queue:pop(id)
	if self.head == nil then
		return nil
	end

	local m = self.head
	if m.id ~= id then
		return nil
	end

	self.head = m.next
	m.next = nil
	if self.head == nil then
		self.tail = nil
	end
	return m
end


function Queue:insert(m)
	local pre = nil
	local cur = self.head

	while cur ~= nil do
		if cur.id == m.id then
			return
		end
		if cur.id > m.id then
			-- insert here
			if pre == nil then
				self.head = m -- insert head
			else
				pre.next = m
			end
			m.next = cur
			return
		end
		pre = cur
		cur = cur.next
	end
end

local function getID(s, max)
	local id = ntol(s)
	-- 每个逻辑包都有一个 16bit 的序号，从 0 开始编码，如果超过 64K 则回到 0 。
	-- 通讯过程中，如果收到一个数据包和之前的数据包 id 相差正负 32K ，则做一下更合理的调整。
	-- 例如，如果之前收到的序号为 2 ，而下一个包是 FFFF ，则认为是 2 这个序号的前三个，而不是向后一个很远的序号。
	-- |id-max| > 32k
	if id > max + 0x8000 then
		id = id - 0x10000
	elseif id < max-0x8000 then
		id = id + 0x10000
	end
	return id
end

local Rudp = class('Rudp')

function Rudp:ctor(id, output)
	self.id = id
	self.sendQueue = Queue.new()
	self.recvQueue = Queue.new()
	self.sendHistory = Queue.new()
	self.sendAgain = {}

	self.triggerTime = 0
	self.output = output


	self.corrupt = nil
	self.sendid = 0
	self.recvMin = 0
	self.recvMax = 0
	self.lastAck = 0

	-- timestamp
	self.current = socket.gettime()
	self.lastSend = self.current
	self.lastRecv = self.current

	-- configure
	self.expired = 10
	self.heartbeat = 20 -- seconds
	self.rto = 500 -- retransmission timeout (ms)
end

function Rudp:receive()
	if self.corrupt ~= nil then
		return nil, self.corrupt
	end

	local m = self.recvQueue:pop(self.recvMin)
	if m == nil then
		return nil, nil
	end

	self.recvMin = self.recvMin + 1
	return m.data
end


function Rudp:send(data)
	if self.corrupt ~= nil then
		return nil, self.corrupt
	end

	local size = #data
	if size == 0 then
		return 0
	end

	local m = {
		id = self.sendid,
		data = data,
		retries = 0,
		time = socket.gettime(),
	}
	self.sendid = self.sendid + 1
	if self.sendid > 0xffff then
		self.sendid = 0
	end
	self.sendQueue:push(m)
	self:update(0) -- 立即发送
	return size
end

-- input [0 13 0 0 227 199 243 102 214 4 103 75]
-- input [0 23 0 0 104 101 108 108 111 32 102 114 111 109 32 108 117 97 32 117 100 112]
function Rudp:input(data)
	-- print('input', string.byte(data, 1, #data))
	local flag = false
	self.lastRecv = socket.gettime()
	local sz = #data
	local i = 1
	while i <= sz do
		local tag = strsub(data, i, i+1)
		tag = ntol(tag)
		i = i + 2
		if tag == Tag.ping then
			-- TODO:
		elseif tag == Tag.eof then
			self.corrupt = 'eof'
			return
		elseif tag == Tag.corrupt then
			self.corrupt = 'remote eof'
			return
		elseif tag == Tag.request or tag == Tag.missing then
			if sz < 2 then
				self.corrupt = 'size error'
				return
			end
			local id = getID(strsub(data, i, i+1), self.recvMax)
			i = i + 2
			if tag == Tag.request then
				self:addRequest(id)
			else
				self:addMissing(id)
			end
		elseif tag == Tag.ack then
			if sz < 2 then
				self.corrupt = 'size error'
				return
			end
			local id = getID(strsub(data, i, i+1), self.recvMax)
			i = i + 2
			printDebug('rudp %d receive ack %d', self.id, id)
			self:clearSendHistory(id)
		else
			local length = tag - Tag.normal
			if sz - i + 1 < length + 2 then
				self.corrupt = 'size error'
				return
			end
			local id = getID(strsub(data, i, i+1), self.recvMax)
			i = i + 2
			local valid = self:insertRecvQueue(id, strsub(data, i, i+length-1))
			if valid then
				flag = true
			end
			i = i + length
		end
	end
	return flag
end

function Rudp:update(delta)
	if self.corrupt ~= nil then
		return
	end
	-- self.triggerTime = self.triggerTime + delta
	-- if self.triggerTime < 100 then
	-- 	return
	-- end
	-- self.triggerTime = 0

	self.current = socket.gettime()

	if self.current - self.lastRecv > self.heartbeat then
		printWarn('rudp %d is stale %ds', self.id, self.current - self.lastRecv)
		self.corrupt = 'corrupt'
		return
	end

	local flag = false
	local t = {}
	-- 1. request missing
	self:requestMissing(t)
	-- 2. reply request
	self:replyRequest(t)
	-- 3. reply ack
	self:replayAck(t)
	-- 4. retransmission
	self:retransmission(t)
	-- 5. send message
	flag = self:sendMessage(t)
	-- 6. send heartbeat
	if #t == 0 then
		if self.current - self.lastSend > self.heartbeat / 2 then
			self:sendHeartbeat(t)
		end
	end
	if #t > 0 then
		self.lastSend = self.current
	end

	for _, b in ipairs(t) do
		self.output(b)
	end
	return flag
end

function Rudp:clearSendHistory(id)
	local m = self.sendHistory.head
	while m ~= nil and m.id < id do
		m = m.next
	end
	self.sendHistory.head = m
	if m == nil then
		self.sendHistory.tail = nil
	end
end

function Rudp:requestMissing(t)
	local id = self.recvMin
	local m = self.recvQueue.head
	while m ~= nil do
		if m.id < id then
			error('error')
		end
		if m.id > id then
			for i = id, m.id do
				printWarn('request missing %d', i)
				table.insert(t, request(i))
			end
		end
		id = id + 1
		m = m.next
	end
end

function Rudp:replyRequest(t)
	table.sort(self.sendAgain)
	local history = self.sendHistory.head
	for _, id in ipairs(self.sendAgain) do
		while true do
			if history == nil or id < history.id then
				-- expired
				table.insert(t, missing(id))
				break
			elseif id == history.id then
				table.insert(t, packMessage(id, history.data))
				break
			end
			history = history.next
		end
	end
	self.sendAgain = {}
end

function Rudp:replayAck(t)
	local id = self.recvMin
	local m = self.recvQueue.head
	while m ~= nil and m.id <= id do
		if m.id < id then
			error('error')
		end
		id = id + 1
		m = m.next
	end
	if id == self.lastAck then
		return
	end
	printDebug('rudp %d send ack %d', self.id, id)
	self.lastAck = id
	table.insert(t,ack(id))
end

function Rudp:retransmission(t)
	local m = self.sendHistory.head
	while m ~= nil do
		local rto = self.rto * (m.retries + 1)
		if rto > MaxRtoTimeout then
			rto = MaxRtoTimeout
		end
		if (self.current - m.time) * 1000 > rto then
			m.retries = m.retries + 1
			m.time = self.current
			table.insert(t, packMessage(m.id, m.data))
			printDebug('retransmission package %d, retries %d', m.id, m.retries)
		end
		m = m.next
	end
end

function Rudp:sendMessage(t)
	local flag = false
	local m = self.sendQueue.head
	while m ~= nil do
		table.insert(t, packMessage(m.id, m.data))
		printDebug('sendMessage package %d', m.id)
		m = m.next
		flag = true
	end

	if self.sendQueue.head ~= nil then
		if self.sendHistory.tail == nil then
			self.sendHistory.head = self.sendQueue.head
			self.sendHistory.tail = self.sendQueue.tail
		else
			self.sendHistory.tail.next = self.sendQueue.head
			self.sendHistory.tail = self.sendQueue.tail
		end
		self.sendQueue.head = nil
		self.sendQueue.tail = nil
	end
	return flag
end

function Rudp:sendHeartbeat(t)
	table.insert(t, keepalive())
end

function Rudp:addRequest(id)
	table.insert(self.sendAgain, id)
end

function Rudp:addMissing(id)
	self:insertRecvQueue(id, nil)
end

function Rudp:insertRecvQueue(id, data)
	-- printDebug('rudp insertRecvQueue id %d, length %d', id, #data)
	if id < self.recvMin then
		printWarn('already recv %d, length %d', id, data and #data or 0)
		return
	end
	local m = {
		id=id,
		data=data,
	}
	if id > self.recvMax or self.recvQueue.head == nil then
		self.recvQueue:push(m)
		self.recvMax = id
	else
		self.recvQueue:insert(m)
	end
	return true
end

function Rudp:close()
	if self.corrupt ~= nil then
		self.output(corrupt())
	else
		self.output(terminate())
	end
	self.corrupt = 'eof'
end

return Rudp