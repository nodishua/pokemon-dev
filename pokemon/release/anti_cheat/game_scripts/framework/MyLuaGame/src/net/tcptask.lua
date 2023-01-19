--
-- Copyright (c) 2014 YouMi Technologies Inc.
-- Copyright (c) 2018 TianJi Information Technology Inc.
--

require 'net.tcpacket'

local Packet = require('net.tcpacket')

local nettask = {classes={}, urls={}}
globals.nettask = nettask

function nettask.registerTask(cls)
	nettask.classes[type(cls)] = cls
	nettask.urls[cls.Url] = cls
	-- url=/service/api
	local cut = string.find(cls.Url, "/", 2)
	cls.Service = string.sub(cls.Url, 2, cut-1)
	printInfo("%s task be register %s for %s", tostring(cls), cls.Url, cls.Service)
end

function nettask.registerTasks(t)
	for _, cls in ipairs(t) do
		nettask.registerTask(cls)
	end
end

function nettask.registerDefaultTask(cls)
	nettask.default = cls
end

function nettask.getClassByUrl(url)
	return nettask.urls[url] or nettask.default
end

--------------------------

local TaskBase = class('TaskBase')
-- TaskBase.Cmd = nil -- auto set from taskdefines.lua
TaskBase.Url = nil -- define in derived task class
TaskBase.Service = nil -- auto set in nettask.registerTask

function TaskBase:ctor(session, packet, ackCB)
	self.session = session

	-- self.cmd = packet.cmd
	self.url = packet.url
	self.synID = packet.synID
	self.data = packet.data
	self.isClientReq = packet:isAck()

	self.ackCB = ackCB
end

-- when recv, after run login
function TaskBase:run()
end

function TaskBase:ackOk()
	local packet = Packet.new(self.session)
	packet:setOkAck(self.synID)
	return packet
end

function TaskBase:ackErr()
	local packet = Packet.new(self.session)
	packet:setOkErr(self.synID)
	return packet
end

-- ping 发起请求 c->s 客户端主动发起，一般调用这里的都是发送关联请求
function TaskBase:synPacket(url, data)
	if not self.isClientReq then error("the request packet was come from server, you need ackPacket") end
	local packet = Packet.new(self.session)
	packet:setSynData(url, data)
	return packet
end

-- pong 响应请求 s->c 服务器主动发起
function TaskBase:ackPacket(url, data)
	if self.isClientReq then error("the request packet was gen by client, you need synPacket") end
	local packet = Packet.new(self.session)
	packet:setAckData(url, self.synID, data)
	return packet
end

function TaskBase:ackCallBack()
	if not self.ackCB then
		return
	end

	local ackCB = self.ackCB
	self.ackCB = nil
	if self.data.ret then
		return ackCB(self.data, nil)
	else
		return ackCB(nil, self.data)
	end
end


return TaskBase