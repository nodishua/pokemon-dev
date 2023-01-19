--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2017 TianJi Information Technology Inc.
--
-- Date: 2014-07-28 11:53:31
--
-- zlib for lua
-- use `zlib.uncompress`, only for zlib, can not handle with gzip
-- use 'util.zlib2' for gzip
--
local ffi = require("ffi")
ffi.cdef[[
unsigned long compressBound(unsigned long sourceLen);
int compress2(uint8_t *dest, unsigned long *destLen,
	      const uint8_t *source, unsigned long sourceLen, int level);
int uncompress(uint8_t *dest, unsigned long *destLen,
	       const uint8_t *source, unsigned long sourceLen);
]]
local zlib = ffi.load(ffi.os == "Windows" and "zlib1" or "z")

local function compress(txt)
  local n = zlib.compressBound(#txt)
  local buf = ffi.new("uint8_t[?]", n)
  local buflen = ffi.new("unsigned long[1]", n)
  local res = zlib.compress2(buf, buflen, txt, #txt, 9)
  assert(res == 0)
  return ffi.string(buf, buflen[0])
end

-- uncompress需要不停探测output bufsize
-- 不支持流式解析
-- 建议使用zlib2里的接口
local function uncompress(comp, n)
  n = n or (#comp * 2)
  local buf, buflen, res
  while true do
    if n >= 2*1024*1024 then
      print('uncompress may be data corrupted!')
      return nil
    end
    buf = ffi.new("uint8_t[?]", n)
    buflen = ffi.new("unsigned long[1]", n)
    res = zlib.uncompress(buf, buflen, comp, #comp)
    if res == 0 then break end
    print('uncompress failed!', #comp, n, buflen[0], res)
    n = n * 2
  end
  -- assert(res == 0)
  return ffi.string(buf, buflen[0])
end

--[[
-- Simple test code.
local txt = '1234567890abcdef'
print("Uncompressed size: ", #txt, txt)
local c = compress(txt)
print("Compressed size: ", #c, c)
print(string.byte(c, 1, #c))

c = {120, 156, 51, 52, 50, 54, 49, 53, 51, 183, 176, 52, 72, 76, 74, 78, 73, 77, 3, 0, 31, 152, 4, 99}
c = string.char(unpack(c))
print(#c, c)
print(string.byte(c, 1, #c))

local txt2 = uncompress(c, #txt)
print (#txt2, txt2)
assert(txt2 == txt)
]]--

local _M = {compress = compress, uncompress = uncompress}
return _M
