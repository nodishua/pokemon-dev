--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2017 TianJi Information Technology Inc.
--
-- local and network data type conversion
--require "socket.core"

local bit = require 'bit'
local bnot, band, bor, bxor = bit.bnot, bit.band, bit.bor, bit.bxor
local lshift, rshift, rol = bit.lshift, bit.rshift, bit.rol

local char = string.char
local tinsert = table.insert
local strrep = string.rep

local M = {}

local function _ntol(data, start, len)
	local ret = 0
	for i = 1, len do
		ret = lshift(ret, 8) + data:byte(start+i, start+i)
	end
	return ret
end


function M.ntol(data)
	return _ntol(data, 0, #data)
end

function M.lton(n, l)
	local ret = ''
	local i = 0
	while n ~= 0 do
		ret = ret .. char(band(n, 0xff))
		n = rshift(n, 8)
		i = i + 1
		if l ~= nil and i > l then error('lton exceed pack length') end
	end
	if l ~= nil and i ~= l then
		ret = ret .. strrep('\0', l - i)
	end
	return ret:reverse()
end

-- self.len, self.padLen, self.crc32, self.cmd, self.synID = ntol_s(data, 4, 1, 4, 2, 2)
function M.ntol_s(data, ...)
	local len = select('#', ...)
	local ret = {}
	local start = 0
	for i = 1, len do
		local l = select(i, ...)
		tinsert(ret, _ntol(data, start, l))
		start = start + l
	end
	return unpack(ret)
end

-- lton_s(self.len, 4, self.padLen, 1, self.crc32, 4, self.cmd, 2, self.synID, 2)
function M.lton_s(...)
	local ret = ''
	local len = select('#', ...)
	if len % 2 ~= 0 then error('lton_s the parameters not pairs') end
	len = len / 2
	for i = 1, len do
		local v, l = select(i*2-1, ...)
		ret = ret .. M.lton(v, l)
	end
	return ret
end

function M.getAddr(host)
	local result = socket.dns.getaddrinfo(host)
	local ipv4 = nil
	if result then
		for k,v in pairs(result) do
			if v.family == "inet6" then
				print('net is ipv6')
				return v.family, v.addr
			else
				ipv4 = v
			end
		end
	end
	if ipv4 then
		return ipv4.family, ipv4.addr
	end
end

return M