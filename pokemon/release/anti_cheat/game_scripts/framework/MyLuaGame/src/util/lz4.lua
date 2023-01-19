--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2017 TianJi Information Technology Inc.
--
-- Date: 2015-06-23 11:53:31
--
-- lz4 for lua
--

local ffi = require("ffi")
local lz4 = require("lz4")

local ffi_typeof = ffi.typeof
local ffi_sizeof = ffi.sizeof
local ffi_copy = ffi.copy
local ffi_string = ffi.string

ffi.cdef [[
	typedef struct {
		uint32_t len;
	} lz4_hdr_t;
]]

local buf_ct = ffi_typeof("char[?]")
local hdr_ct = ffi_typeof("lz4_hdr_t")
local hdr_len = ffi_sizeof(hdr_ct)

printInfo = printInfo or print
local htonl, ntohl
if ffi.abi("le") then
	-- little-endian
	printInfo('lz4 little-endian')
	htonl = bit.bswap
else
	-- big-endian, same as network-order, do nothing
	printInfo('lz4 big-endian')
	htonl = function (b) return b end
end
ntohl = htonl	-- reverse is the same

local _lz4_compress = lz4.compress
local _lz4_decompress = lz4.decompress
local _lz4_compressBound = lz4.compressBound

local function lz4_hdr_write(buf, len)
	if ffi_sizeof(buf) < hdr_len then
		return nil, "invalid buffer length"
	end

	local hdr = hdr_ct()
	--hdr.sig = htonl(lz4_signature)
	-- hdr.len = htonl(len)
	hdr.len = len
	ffi_copy(buf, hdr, hdr_len)

	return true
end

local function lz4_hdr_read(src)
	if #src < hdr_len then
		return nil, "invalid source length"
	end

	local hdr = hdr_ct()
	ffi_copy(hdr, src, hdr_len)
	--hdr.sig = ntohl(hdr.sig)
	-- hdr.len = ntohl(hdr.len)

	-- if hdr.sig ~= lz4_signature then
	-- 	return nil, "lz4 signature mismatch"
	-- end

	return hdr
end

local function lz4_compress_core(src, clz4_compressor)
	-- local dest_len = _lz4_compressBound(#src)
	local hdr_buf = buf_ct(hdr_len)

	local ok, errmsg = lz4_hdr_write(hdr_buf, #src)
	if not ok then
		return nil, errmsg
	end

	local dest_buf = clz4_compressor(src, #src)
	if dest_buf then
		return ffi_string(hdr_buf, hdr_len) .. dest_buf
	else
		return nil, "compression failed"
	end
end

local function lz4_decompress_core(src, dest_len)
	-- local dest_buf = buf_ct(dest_len)
	local dest_buf = _lz4_decompress(dest_len, src, #src)
	if dest_buf then
		return dest_buf
	else
		return nil, "decompression failed"
	end
end

local function lz4_compress(src, level)
	if not src or #src == 0 then
		return nil, "invalid source (is nil or is a empty string)"
	end

	-- ref: https://github.com/Cyan4973/lz4/blob/master/programs/lz4io.c#L308
	if not level or level < 3 then
		return lz4_compress_core(src, _lz4_compress)
	else
		assert(false)
		-- return lz4_compress_core(src, clz4.LZ4_compressHC)
	end
end

local function lz4_decompress(src, _)
	if not src or #src == 0 then
		return nil, "invalid source (is nil or is a empty string)"
	end

	local hdr, errmsg = lz4_hdr_read(src)
	if not hdr then
		return nil, errmsg
	end

	return lz4_decompress_core(src:sub(hdr_len + 1), hdr.len)
end

-----------------
-- local function compress(txt)
--   local buflen = lz4_compressBound(#txt)
--   local buf = ffi.new("uint8_t[?]", buflen)
--   local len = lz4_compress(buf, buflen, txt, #txt)
--   assert(len > 0)
--   return ffi.string(buf, len)
-- end

-- local function uncompress(comp, n)
--   buflen = n or (#comp * 2)
--   local buf, len
--   while true do
--     if buflen >= 2*1024*1024 then
--       print('uncompress may be data corrupted!')
--       return nil
--     end
--     buf = ffi.new("uint8_t[?]", buflen)
--     len = lz4_decompress(buf, buflen, comp, #comp)
--     if len > 0 then break end
--     print('uncompress failed!', #comp, buflen, len)
--     buflen = buflen * 2
--   end
--   return ffi.string(buf, len)
-- end

--[[
-- Simple test code.
local txt = '1234567890abcdef'
print("Uncompressed size: ", #txt, txt)
local c = lz4_compress(txt)
print("Compressed size: ", #c, c)
print(string.byte(c, 1, #c))

local txt2 = lz4_decompress(c, #txt)
print (#txt2, txt2)
assert(txt2 == txt)
]]--

return {compress = lz4_compress, uncompress = lz4_decompress}