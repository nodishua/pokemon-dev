--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2018 TianJi Information Technology Inc.
--
-- net网络管理器
--
-- Net Task come from sever
-- c --Packet--> s
-- s --Packet--Task--> c
--

require 'json'

require 'net.tcptask'

local _zlib = require('3rd.zlib2')
local zuncompress = _zlib.uncompress

local _strfmt = string.format

local NoTransferTimeout = 30

-- err defines
globals.NetError = {
	TimeoutClosed = "timeout_closed",
}

local NetManager = class("NetManager")

-- member method
function NetManager:ctor()
	self.taskQue = CList.new() -- other task queue ?
	self.ackCBMap = {}

	self.socksMap = {}
	self.deletedSocksMap = nil
	self.selecting = false
	self.selector = ymasync.new_selector()
end

function NetManager:selectSock(sockID, sock, read, write, timeout, cb)
	if self.socksMap[sockID] ~= nil then
		error("the sock already in select, only one event callback existed in the same time")
	end

	self.socksMap[sockID] = {
		sock = sock,
		read = read,
		write = write,
		cb = cb,
		endtime = timeout and (os.time() + timeout),
	}
end

function NetManager:removeSelectSock(sockID)
	-- may be in selecting
	if not self.deletedSocksMap then
		self.deletedSocksMap = {}
	end
	self.deletedSocksMap[sockID] = true
end

-- must be implement
function NetManager:getSessionByService(service)
	error("NetManager:getSessionByService need be implement!")
end

function NetManager:sendPacket(url, data, ackCB, sentCB)
	local cls = nettask.getClassByUrl(url)
	local session = self:getSessionByService(cls.Service)
	local packet = session:newPacket(url, data)

	print('------------------------------>>>>')
	print('[SEND]', _strfmt('url = %s, %s = %d, len = %d',
		url,
		packet:isSyn() and "synID" or "ackID", packet.synID,
		packet.len)
	)
	print("\n"..((DEBUG < 2) and '' or dumps(data, true)))
	print('------------------------------>>>>')

	if ackCB then
		self.ackCBMap[packet.synID] = ackCB
	end
	session:send(packet, sentCB)
end

function NetManager:sendHttpRequest(reqType, reqUrl, reqBody, resType, cb)
	local xhr = cc.XMLHttpRequest:new()
	xhr.responseType = resType
	-- xhr.timeout = 5
	xhr:open(reqType, reqUrl)
	if reqType == 'GET' then
		xhr:setRequestHeader("Accept-Encoding", "gzip")
	end
	local function _onReadyStateChange(...)
		local encode = string.match(xhr:getAllResponseHeaders(), "Content%-Encoding:%s*(gzip)")
		if encode == 'gzip' then
			xhr.responseType = cc.XMLHTTPREQUEST_RESPONSE_BLOB
			xhr.response = zuncompress(xhr.response)
		end
		cb(xhr)
	end
	if cb then xhr:registerScriptHandler(_onReadyStateChange) end
	if reqBody then xhr:send(reqBody)
	else xhr:send() end
end

function NetManager:doGET(reqUrl, cb)
	log.get(reqUrl)
	return self:sendHttpRequest("GET", reqUrl, nil, cc.XMLHTTPREQUEST_RESPONSE_BLOB, function(xhr)
		if xhr.status == 200 then
			cb(xhr.response)
		else
			if #xhr.response > 0 then
				cb(xhr.response)
			else
				logf.get('err %s %s', xhr.status, xhr.statusText)
				cb(nil, xhr.statusText)
			end
		end
	end)
end

function NetManager:onUpdate(delta)
	self:_select()

	self:updateSession(delta)
	self:processTask(limit)
end

-- must be implement
function NetManager:updateSession(delta)
	error("NetManager:updateSession need be implement!")
end

function NetManager:processTask(limit)
	limit = limit or 999999
	if limit <= 0 then return end

	while not self.taskQue:empty() do
		local task = self.taskQue:pop_front()
		local packet
		if __G__TRACKBACK__ then
			local status, ret = xpcall(function()
				return task:run()
			end, __G__TRACKBACK__)
			if status then
				packet = ret
			else
				-- like onInterruptedPakcet, but non-atomic for logic run
				-- only for hide connecting
				if task.ackCB then
					task.ackCB(nil, {
						ret = false,
						err = "process_task_error",
					})
				end
			end
		else
			packet = task:run()
		end

		if packet ~= nil then
			-- 现在packet只发给来时的server，没有发往其它server需求
			print('------------------------------>>>>')
			print('[TASK SEND]', _strfmt('url = %s, %s = %d, len = %d',
				packet.url,
				packet:isSyn() and "synID" or "ackID", packet.synID,
				packet.len)
			)
			print("\n"..((DEBUG < 2) and '' or dumps(packet.rawData, true)))
			print('------------------------------>>>>')
			packet.rawData = nil -- 打印完释放

			packet.session:send(packet)
		end

		limit = limit - 1
		if limit <= 0 then break end
	end
end

function NetManager:onRecvPacket(session, packet)
	setLogColor(CONSOLE_COLOR.Light_Blue_Green)
	print('------------------------------<<<<')
	setLogColor(CONSOLE_COLOR.Light_Purple)
	print('[RECV]', _strfmt('url = %s, synID = %d, len = %d',
		packet.url,
		packet.synID,
		packet.len)
	)
	local ignore = dev.REQUEST_LOG_IGNORE[packet.url]
	setLogColor(CONSOLE_COLOR.Light_Blue_Green)
	print("\n"..((ignore or DEBUG < 2) and '' or dumps(packet.data, true)))
	setLogColor(CONSOLE_COLOR.Light_Blue_Green)
	print('------------------------------<<<<')
	setLogColor(CONSOLE_COLOR.Default)

	if packet:isHeartSyn() then
		session.lastTransferTime = os.time()
		return
	end

	local ackCB
	if packet:isAck() and packet.synID then
		ackCB = self.ackCBMap[packet.synID]
		self.ackCBMap[packet.synID] = nil
	end
	local cls = nettask.getClassByUrl(packet.url)
	local task = cls.new(session, packet, ackCB)
	self.taskQue:push_back(task)
end

function NetManager:onInterruptedPakcet(synIDs)
	for _, synID in ipairs(synIDs) do
		local ackCB = self.ackCBMap[synID]
		if ackCB then
			local err = {
				ret = false,
				err = "network_interrupted",
				system = true,
				synID = synID,
			}
			ackCB(nil, err)
			self.ackCBMap[synID] = nil
		end
	end
end

function NetManager:onSessionLost(syncID)
	local err = {
		ret = false,
		err = 'network_lost',
		system = true,
	}
	local ackCB = self.ackCBMap[syncID]
	if ackCB then
		ackCB(nil, err)
	end
end

function NetManager:onTimeout(session)
	local delta = os.time() - session.lastTransferTime
	if delta > NoTransferTimeout then
		printWarn("zero transfer timeout %s", delta)
		return NetError.TimeoutClosed
	end
end

function NetManager:_select()
	if self.selecting or itertools.isempty(self.socksMap) then
		return
	end
	self.selecting = true

	local rl, wl, socks = nil, nil, self.socksMap
	local deleteds = self.deletedSocksMap
	self.socksMap = {}
	self.deletedSocksMap = nil

	local noEvent = true
	local time = os.time()
	for sockID, info in pairs(socks) do
		local delete = deleteds and deleteds[sockID]
		if delete then
			socks[sockID] = nil
		else
			if info.read then
				rl = rl or {}
				arraytools.push(rl, info.sock)
				noEvent = false
			end
			if info.write then
				wl = wl or {}
				arraytools.push(wl, info.sock)
				noEvent = false
			end
			if info.endtime then
				noEvent = false
			end
		end
	end

	if noEvent then
		self.selecting = false
		return
	end

	-- print("!!! ymasync.select", socks, rl and #rl, wl and #wl)
	-- select callback is async
	ymasync.select(self.selector, rl, wl, 0.1, function (rl, wl, err)
		-- print("!!! ymasync.select ret", dumps(itertools.keys(socks)), rl and #rl, wl and #wl, err)
		if err and err ~= "timeout" then
			-- under win32, the closed sock will raise error, Socket operation on nonsocket
			printWarn("select error: %s", err)
		end

		local time = os.time()
		for sockID, info in pairs(socks) do
			local sock = info.sock
			local r = rl and rl[sock]
			local w = wl and wl[sock]
			local delete = self.deletedSocksMap and self.deletedSocksMap[sockID]
			if delete then
				printInfo("select %s delete", sockID)
				info.cb(false, false, "closed")
			elseif r or w then
				printDebug("select %s %s%s event", sockID, r and 'r' or '', w and 'w' or '')
				-- err will be detected in recv or send
				info.cb(r, w, nil)
			elseif info.endtime and time >= info.endtime then
				printInfo("select %s endtime", sockID)
				info.cb(false, false, "timeout")
			else
				-- select next
				local newInfo = self.socksMap[sockID]
				self.socksMap[sockID] = newInfo or info
			end
		end
		self.selecting = false
		-- select more in current frame, may be more quick
		return self:_select()
	end)
end

return NetManager