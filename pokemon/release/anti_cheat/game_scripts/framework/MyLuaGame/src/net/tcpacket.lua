--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2018 TianJi Information Technology Inc.
--

-- msgpack specs
-- https://github.com/msgpack/msgpack/blob/master/spec.md
------------------------------------
-- source types		output format
-- Integer			int format family (positive fixint, negative fixint, int 8/16/32/64 or uint 8/16/32/64)
-- Nil				nil
-- Boolean			bool format family (false or true)
-- Float			float format family (float 32/64)
-- String			str format family (fixstr or str 8/16/32)
-- Binary			bin format family (bin 8/16/32)
-- Array			array format family (fixarray or array 16/32)
-- Map				map format family (fixmap or map 16/32)
-- Extended			ext format family (fixext or ext 8/16/32)
------------------------------------


local _msgpack = require '3rd.msgpack'
_msgpack.set_string('binary')
_msgpack.set_number('double')

local msgpack = _msgpack.pack
local msgunpack = _msgpack.unpack

local lnconv = require 'net.lnconv'
local ntol = lnconv.ntol
local lton = lnconv.lton
local ntol_s = lnconv.ntol_s
local lton_s = lnconv.lton_s

local bit = require 'bit'
local bnot, band, bor, bxor = bit.bnot, bit.band, bit.bor, bit.bxor
local lshift, rshift, rol = bit.lshift, bit.rshift, bit.rol

local _crc = require '3rd.CRC32'
local CRC32 = _crc.CRC32

-- local _zlib = require 'util.zlib'
-- local zcompress = _zlib.compress
-- local zuncompress = _zlib.uncompress

local _lz4 = require 'util.lz4'
local zcompress = _lz4.compress
local zuncompress = _lz4.uncompress

local _aes = require 'aes'
local AESKeyHex = _aes.key128Hex
local AESEncrypt = _aes.encryptCBC
local AESDecrypt = _aes.decryptCBC

local strsub = string.sub
local strrep = string.rep
local strfmt = string.format

local InitPwdAES = 'tjshuma081610888'
local InitPwdHexAES = AESKeyHex(InitPwdAES)

--[[
WANetTask: [flag(1 byte)][...]

	flag: [1:ok_ack][2:err_ack][3:heart_syn][4:zip_flag][5:long_len_flag][6:ack_flag][7:url_flag][8:magic_flag]

		`1:ok_ack`: [syn_id(2 bytes)]
			mean is ok ack, no other data
		`2:err_ack`: [syn_id(2 bytes)]
			mean is err ack, no other data
		`3:heart_syn`: None
			mean is heart-beat syn, no other data, need client heart ack
		`4:zip_flag`:
			mean `data`: AES128_CBC(raw_data + '\0'*pad_len)
		`5:long_len_flag`:
			mean `len`(4 bytes)
		`6:ack_flag`:
			mean packet is ack, its syn_id belong to client
		`7:url_flag`:
			mean cmd is salt, urlLen and url will append
		`8:magic_flag`:
			magic binary bit: 1

	normal task: [len(*2 bytes) pad_len(1 byte) crc32(4 bytes) cmd(2 bytes) syn_id(2 bytes)][urlLen(1 byte) url(urlLen)][data(len)]

		`crc32`: crc32(data + str(cmd) + str(syn_id))
		`data`: AES128_CBC(ZIP(raw_data) + '\0'*pad_len)
]]--
--[[
synID 是请求发起方的id序号
ackID=request.synID 是请求接受方返回请求id序号，用于标识请求来源
packet内保存的synID，只是id，没有请求或相应的含义
请求为ping-pong模式，synID在请求后续操作自增1，即关联请求也是一个新的请求
通过ping-pong，逻辑上保证请求和应答的完整性
对于notify模式，可认为是没有应答的特殊ping-pong

1. c --synID1--> s --ackID1 --> c
2. c --synID2--> s --ackID2 --> c
3. s --synID11--> c --ackID11 --> s

1,2 可能是关联请求，但协议上视为两个独立请求
1,3 c/s 的synID计数器各自独立维护，判断单方递增即可
]]--

local PacketFlag = {}

local FlagMask = 0xFF
local MagicFlag = 0x80 -- 1000 0000
local KeyMap = {
	ok_ack = 0,
	err_ack = 1,
	heart_syn = 2,
	zip_flag = 3,
	long_len_flag = 4,
	ack_flag = 5,
	url_flag = 6,
}

function PacketFlag.new(...)
	local self = {
		flag = MagicFlag,
	}
	setmetatable(self, {
		__index = function(t, k)
			local ret = rawget(t, k)
			if ret ~= nil then return ret end
			ret = PacketFlag[k]
			if ret ~= nil then return ret end
			return PacketFlag.__getter(t, k)
		end,
		__newindex = PacketFlag.__setter,
	})
	self:ctor(...)
	return self
end

function PacketFlag:ctor(kwargs)
	kwargs = kwargs or {}
	if type(kwargs) == "number" then
		self.flag = kwargs
		return
	elseif type(kwargs) == "table" then
		if kwargs.flag then
			self.flag = kwargs.flag
			return
		end
	end

	self.ok_ack = kwargs.ok_ack or false
	self.err_ack = kwargs.err_ack or false
	self.heart_syn = kwargs.heart_syn or false
	self.zip_flag = kwargs.zip_flag or false
	self.long_len_flag = kwargs.long_len_flag or false
	self.ack_flag = kwargs.ack_flag or false
	self.url_flag = kwargs.url_flag or false
end

function PacketFlag:isValid()
	if band(self.flag, MagicFlag) ~= MagicFlag then return false end
	local normalFlag = self.zip_flag or self.long_len_flag or self.ack_flag
	local cnt = 0
	for _, x in pairs({self.ok_ack, self.err_ack, self.heart_syn, normalFlag}) do
		if x then cnt = cnt + 1 end
	end
	if cnt > 1 then return false end
	return true
end

function PacketFlag:unpack(data)
	self.flag = ntol(data)
end

function PacketFlag:pack()
	return lton(band(self.flag, 0xff), 1)
end

function PacketFlag:__getter(k)
	local dig = KeyMap[k]
	if dig then
		return band(self.flag, lshift(1, dig)) ~= 0
	end
	return nil
end

function PacketFlag:__setter(k, v)
	local dig = KeyMap[k]
	if dig then
		if v then
			self.flag = bor(self.flag, lshift(1, dig))
		else
			self.flag = band(self.flag, bxor(lshift(1, dig), 0xff))
		end
	else
		error(strfmt("packet flag no such key %s", k))
	end
	-- print('!!!! PacketFlag.set', k, v, dig, self.flag)
end

-----------------------
local Packet = class('Packet')

Packet.ReadStepStart = 0
Packet.ReadStepSynID = 1
Packet.ReadStepNormHead = 2
Packet.ReadStepNormLongHead = 3
Packet.ReadStepNormHeadExtraLen = 4
Packet.ReadStepNormHeadExtraBody = 5
Packet.ReadStepNormData = 6
Packet.ReadStepEnd = 9
Packet.ReadStepError = 10

local SynIDCounter = 1
local SynIDMax = 65500
local NormalTaskLenMax = 65535
local UrlSynID = {}

-- class method
function Packet.getNextSynID(url)
	local ret = UrlSynID[url]
	if ret ~= nil then
		UrlSynID[url] = nil
		return ret
	end
	local ret = SynIDCounter
	SynIDCounter = 1 + SynIDCounter
	if SynIDCounter >= SynIDMax then SynIDCounter = 1 end
	return ret
end

function Packet.setNextSynID(url, id)
	UrlSynID[url] = id
end

-- member method
function Packet:ctor(session)
	self.session = session
	self.readStep = self.ReadStepStart
end

function Packet:reset()
	self.readStep = self.ReadStepStart
	self.len, self.padLen, self.crc32, self.cmd, self.synID = nil, nil, nil, nil, nil
	self.flag, self.data = nil, nil
	self.urlLen = nil
	self.rawData = nil -- 现在只是print_r用
end

function Packet:getPwdHexAES()
	return self.session.pwdHexAES
end

function Packet:nextLen()
	if self.readStep == self.ReadStepStart then
		return 1 -- flag
	elseif self.readStep == self.ReadStepSynID then
		return 2 -- syn_id
	elseif self.readStep == self.ReadStepNormHead then
		return 11 -- norm head
	elseif self.readStep == self.ReadStepNormLongHead then
		return 13 -- norm long head
	elseif self.readStep == self.ReadStepNormHeadExtraLen then
		return 1 -- url len
	elseif self.readStep == self.ReadStepNormHeadExtraBody then
		return math.ceil((self.urlLen+2)/16)*16
	elseif self.readStep == self.ReadStepNormData then
		return self.len
	end
	return 0
end

function Packet:parseEnd()
	return self:nextLen() == 0
end

function Packet:_parseErrReturn(err)
	printWarn('Packet read error, step = %d, err = %s', self.readStep, err or '')

	self.readStep = self.ReadStepError
	return false
end

function Packet:parseNext(data)
	if self.readStep == self.ReadStepStart then

		-- check flag
		self.flag = PacketFlag.new()
		self.flag:unpack(data)
		if not self.flag:isValid() then return self:_parseErrReturn('flag invalid') end

		-- print('recv flag', string.byte(data, 1, #data))

		-- next step
		if self.flag.ok_ack or self.flag.err_ack then
			self.readStep = self.ReadStepSynID
		elseif self.flag.heart_syn then
			self.readStep = self.ReadStepEnd
		elseif self.flag.long_len_flag then
			self.readStep = self.ReadStepNormLongHead
		else
			self.readStep = self.ReadStepNormHead
		end

	elseif self.readStep == self.ReadStepSynID then

		if #data ~= 2 then return self:_parseErrReturn(strfmt('len of synID is %d (2 ok)', #data)) end

		-- read synID
		self.synID = ntol(data)
		self.readStep = self.ReadStepEnd

	elseif self.readStep == self.ReadStepNormHead then

		if #data ~= 11 then return self:_parseErrReturn(strfmt('len of normal head is %d (11 ok)', #data)) end

		-- read normal head
		self.len, self.padLen, self.crc32, self.cmd, self.synID = ntol_s(data, 2, 1, 4, 2, 2)
		self.readStep = self.ReadStepNormData
		if self.flag.url_flag then
			self.readStep = self.ReadStepNormHeadExtraLen
		end

	elseif self.readStep == self.ReadStepNormLongHead then

		if #data ~= 13 then return self:_parseErrReturn(strfmt('len of normal long head is %d (13 ok)', #data)) end

		-- read normal long head
		self.len, self.padLen, self.crc32, self.cmd, self.synID = ntol_s(data, 4, 1, 4, 2, 2)
		self.readStep = self.ReadStepNormData
		if self.flag.url_flag then
			self.readStep = self.ReadStepNormHeadExtraLen
		end

	elseif self.readStep == self.ReadStepNormHeadExtraLen then

		self.urlLen = string.byte(data, 1, 1)
		self.readStep = self.ReadStepNormHeadExtraBody

		-- print('recv url len', self.urlLen)

	elseif self.readStep == self.ReadStepNormHeadExtraBody then

		local n = math.ceil((self.urlLen+2)/16)*16
		if #data ~= n then return self:_parseErrReturn(strfmt('len of url is %d (%d ok)', #data, n)) end

		data = AESDecrypt(data, InitPwdHexAES)
		self.url = strsub(data, 1, self.urlLen)
		self.readStep = self.ReadStepNormData

		-- print('recv url', self.url)

	elseif self.readStep == self.ReadStepNormData then

		if #data ~= self.len then return self:_parseErrReturn(strfmt('len of data is %d (%d ok)', #data, self.len)) end

		-- print('recv data', string.byte(data, 1, #data))

		-- crc32 check
		local crc32
		if self.flag.url_flag then
			crc32 = band(CRC32(data .. self.cmd .. self.synID .. self.url), 0xffffffff)
		else
			crc32 = band(CRC32(data .. self.cmd .. self.synID), 0xffffffff)
		end

		-- print('recv crc', crc32==self.crc32,  crc32, self.crc32)
		if crc32 ~= self.crc32 then return self:_parseErrReturn('crc32 invalid') end

		-- cmd to url
		if self.url == nil then
			self.url = nettask.cmd2url[self.cmd]
		end
		if self.url == nil then
			error("no url in packet")
		end

		-- print('aes pwd', tostring(self.session), self:getPwdHexAES())
		data = AESDecrypt(data, self:getPwdHexAES())
		-- print('after aes', string.byte(data, 1, #data))

		if self.padLen > 0 then
			data = strsub(data, 1, -1-self.padLen)
			-- print('after unpadding', #data)
		end

		if self.flag.zip_flag then
			-- TODO: [130,167,98,97,110,112,105,99,107,132,164,100,111,110,101,146,194,194,170,105,110,112,117,116,115,116,101,112,115,144,167,111,102,102,108,105,110,101,146,194,194,164,115,116,101,112,0,163,114,101,116,195]
			-- zip_flag 异常，recv flag = 200
			local old = data
			data = zuncompress(data) or old
			-- print('after unzip', #data)
		end

		-- for debug
		-- print('before msgunpack', #data, '=', string.byte(data, 1, #data))

		-- if dev.DEBUG_MODE then
			xpcall(function()
				self.data = msgunpack(data)
			end, function(msg)

				-- http://172.81.227.66:1104/crashinfo?_id=3060&type=1
				-- AESDecrypt could not be nil
				-- but zuncompress will be, data = nil
				if self.url == "/game/push" then
					-- http://172.81.227.66:1104/crashinfo?_id=3040&type=1
					-- cause by /game/push in the most
					-- the bug need to be fix with server
					self.data = {ret = true}
					self.readStep = self.ReadStepEnd
					return
				end

				__G__TRACKBACK__(msg)
				local packdata = self.flag:pack()
				local head = string.format("flag %d, len %d, padLen %d, crc32 %d, cmd %d, synID %d, url %s", string.byte(packdata, 1, #packdata) , self.len, self.padLen, self.crc32, self.cmd, self.synID, self.url)
				local b64 = mime.b64(data)
				print('err msgunpack base64:', #data, #b64)
				sendExceptionInMobile('[string "net.tcpacket"]:390:err msgunpack base64:\n\nstack traceback:\n'..head..'\n'..b64)

				-- let task cause the system error and no retry
				self.data = {ret = false, err = 'msgunpack_error'}
			end)
		-- else
		-- 	self.data = msgunpack(data)
		-- end

		-- print('after msgunpack')
		-- print_r(self.data)

		self.readStep = self.ReadStepEnd
	end
	return true
end

function Packet:setSynData(url, data)
	self:_setData(url, Packet.getNextSynID(url), nil, data)
end

function Packet:setAckData(url, ackID, data)
	self:_setData(url, nil, ackID, data)
end

function Packet:_setData(url, synID, ackID, data)
	self:reset()

	-- self.cmd = nettask.url2cmd[url]
	-- if self.cmd == nil then
	-- 	error(string.format("no such cmd define %s", url))
	-- end
	self.cmd = math.random(65535)
	self.url = url
	self.synID = synID or ackID
	self.flag = PacketFlag.new{zip_flag = true, ack_flag = ackID, url_flag = true}
	self.padLen = 0
	self.urlLen = #url
	self.rawData = data

	local urldata = strfmt("%s%s%s", url, string.char(math.random(255)), string.char(math.random(255)))

	local pdata = msgpack(data)
	local zdata = nil
	-- must be compress
	zdata = zcompress(pdata)

	-- if #pdata < 32 then
	-- 	self.flag.zip_flag = false
	-- 	zdata = pdata
	-- else
	-- 	zdata = zcompress(pdata)
	-- 	if #pdata < #zdata then
	-- 		self.flag.zip_flag = false
	-- 		zdata = pdata
	-- 	end
	-- end

	-- for debug
	-- print('after msgpack', string.byte(pdata, 1, #pdata))
	-- print('after zip', string.byte(zdata, 1, #zdata))

	-- padding \0
	if #zdata % 16 ~= 0 then
		self.padLen = 16 - (#zdata % 16)
		zdata = zdata .. strrep('\0', self.padLen)
	end
	if #urldata % 16 ~= 0 then
		local padLen = 16 - (#urldata % 16)
		urldata = urldata .. strrep('\0', padLen)
	end

	-- for debug
	-- print('after padding', string.byte(zdata, 1, #zdata))
	printDebug('aes pwd %s %s', tostring(self.session), self:getPwdHexAES())

	zdata = AESEncrypt(zdata, self:getPwdHexAES())
	self.crc32 = band(CRC32(zdata .. self.cmd .. self.synID .. self.url), 0xffffffff)

	urldata = AESEncrypt(urldata, InitPwdHexAES)

	-- for debug
	-- print('pwdHexAES', self:getPwdHexAES())
	-- print('after AESEncrypt', string.byte(zdata, 1, #zdata))
	-- ddata = AESDecrypt(zdata, self:getPwdHexAES())
	-- print('AESDecrypt', string.byte(ddata, 1, #ddata))

	self.len = #zdata
	-- long head
	local len = 2
	if self.len > NormalTaskLenMax then
		self.flag.long_len_flag = true
		len = 4
	end

	-- for debug
	-- print('len', self.len)
	-- print('padLen', self.padLen)
	-- print('crc32', self.crc32)
	-- print('cmd', self.cmd)
	-- print('synID', self.synID)
	-- print('pack flag', string.byte(self.flag:pack()))
	-- local a = lton_s(self.len, len, self.padLen, 1, self.crc32, 4, self.cmd, 2, self.synID, 2)
	-- print('pack head', string.byte(a, 1, #a))
	-- print('pack zdata', string.byte(zdata, 1, #zdata))


	local dataHead = lton_s(self.len, len, self.padLen, 1, self.crc32, 4, self.cmd, 2, self.synID, 2, self.urlLen, 1)
	self.data = self.flag:pack() .. dataHead .. urldata .. zdata
end

function Packet:setOkAck(ackID)
	self:reset()

	self.synID = ackID
	self.flag = PacketFlag.new{ok_ack = true}

	self.data = self.flag:pack() .. lton(self.synID, 2)
end

function Packet:setErrAck(ackID)
	self:reset()

	self.synID = ackID
	self.flag = PacketFlag.new{err_ack = true}

	self.data = self.flag:pack() .. lton(self.synID, 2)
end

function Packet:setHeartSyn()
	self:reset()

	self.flag = PacketFlag.new{heart_syn = true}

	self.data = self.flag:pack()
end

function Packet:isOkAck()
	if self.flag.ok_ack then return self.synID end
end

function Packet:isErrAck()
	if self.flag.err_ack then return self.synID end
end

function Packet:isHeartSyn()
	return self.flag.heart_syn
end

function Packet:isAck()
	return self.flag.ack_flag
end

function Packet:isSyn()
	return not self:isAck()
end

return Packet
