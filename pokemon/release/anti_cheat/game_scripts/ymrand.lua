local ffi = require("ffi")
local bit = require 'bit'
local bnot, band, bor, bxor = bit.bnot, bit.band, bit.bor, bit.bxor
local lshift, rshift, rol = bit.lshift, bit.rshift, bit.rol

-- #define N        (624)       // length of state vector
-- #define M        (397)       // a period parameter
-- #define K        (0x9908B0DFU)      // a magic constant
-- #define hiBit(u)       ((u) & 0x80000000U)   // mask all but highest   bit of u
-- #define loBit(u)       ((u) & 0x00000001U)   // mask all but lowest    bit of u
-- #define loBits(u)      ((u) & 0x7FFFFFFFU)   // mask  the highest   bit of u
-- #define mixBits(u, v)  (hiBit(u)|loBits(v))  // move hi bit of u to hi bit of v

local N = 624
local M = 397
local K = 0x9908B0DF

local function hiBit(u)
	return band(u, 0x80000000)
end

local function loBit(u)
	return band(u, 0x00000001)
end

local function loBits(u)
	return band(u, 0x7FFFFFFF)
end

local function mixBits(u, v)
	return bor(hiBit(u), loBits(v))
end

-- unsigned int state[ 624 + 1 ];
-- unsigned int *next;
-- int left;
-- int count;

local RakNetRandom = {}
RakNetRandom.__index = RakNetRandom

ffi.cdef[[
struct c_s {
	unsigned int state[ 624 + 1 ];

	unsigned int x;
	unsigned int y;
	unsigned int s0;
	unsigned int s1;
	unsigned int a;
	unsigned int b;
};
]]

function RakNetRandom.new()
	local c = ffi.new("struct c_s", {left = 0, count = 0})
	ffi.fill(c.state, 624+1)

	return setmetatable({
		left = -1,
		next = 0,
		count = 0,

		c = c,
	}, RakNetRandom)
end

-- register unsigned int x = ( seed | 1U ) & 0xFFFFFFFFU, *s = state;
-- register int j;
-- for ( left = 0, *s++ = x, j = N; --j;
-- 	*s++ = ( x *= 69069U ) & 0xFFFFFFFFU )
-- 	;
function RakNetRandom:seedMT(seed)
	self.count = 0

	-- local x = band(bor(seed, 1), 0xFFFFFFFF)
	local c = self.c
	c.x = band(bor(seed, 1), 0xFFFFFFFF)

	local s = 0
	local state = self.c.state
	self.left = 0
	-- *s++ = x
	state[s] = c.x
	s = s + 1
	for j = 2, N do
		c.x = band(c.x * 69069, 0xFFFFFFFF)
		state[s] = c.x
		-- print('===s', s, state[s])
		s = s + 1
	end
end

-- register unsigned int * p0 = state, *p2 = state + 2, *pM = state + M, s0, s1;
-- register int j;

-- if ( left < -1 )
-- 	seedMT( 4357U );

-- left = N - 1, next = state + 1;

-- for ( s0 = state[ 0 ], s1 = state[ 1 ], j = N - M + 1; --j; s0 = s1, s1 = *p2++ )
-- 	* p0++ = *pM++ ^ ( mixBits( s0, s1 ) >> 1 ) ^ ( loBit( s1 ) ? K : 0U );

-- for ( pM = state, j = M; --j; s0 = s1, s1 = *p2++ )
-- 	* p0++ = *pM++ ^ ( mixBits( s0, s1 ) >> 1 ) ^ ( loBit( s1 ) ? K : 0U );

-- s1 = state[ 0 ], *p0 = *pM ^ ( mixBits( s0, s1 ) >> 1 ) ^ ( loBit( s1 ) ? K : 0U );

-- s1 ^= ( s1 >> 11 );

-- s1 ^= ( s1 << 7 ) & 0x9D2C5680U;

-- s1 ^= ( s1 << 15 ) & 0xEFC60000U;

-- return ( s1 ^ ( s1 >> 18 ) );

local function xorBits(p, c)
	c.a = rshift(mixBits(c.s0, c.s1), 1)
	c.b = loBit(c.s1)
	if c.b ~= 0 then
		c.b = K
	else
		c.b = 0
	end
	return bxor(bxor(p, c.a), c.b)
end

function RakNetRandom:reloadMT()
	local p0 = 0
	local p2 = 2
	local pm = M
	local c = self.c
	local state = self.c.state

	if self.left < -1 then
		self:seedMT(4357)
	end

	self.left = N - 1
	self.next = 1

	c.s0 = state[0]
	c.s1 = state[1]
	for j = 1, N - M do
		state[p0] = xorBits(state[pm], c)
		p0, pm = p0 + 1, pm + 1

		c.s0 = c.s1
		-- s1 = *p2++
		c.s1 = state[p2]
		p2 = p2 + 1
	end

	pm = 0
	for j = 2, M do
		state[p0] = xorBits(state[pm], c)
		p0, pm = p0 + 1, pm + 1

		c.s0 = c.s1
		-- s1 = *p2++
		c.s1 = state[p2]
		p2 = p2 + 1
	end

	-- print('!!! p0', p0,state[p0])
	-- print('!!! p2', p2,state[p2])
	-- print('!!! pm', pm,state[pm])
	-- print(state[0])

	c.s1 = state[0]
	state[p0] = xorBits(state[pm], c)
	c.s1 = bxor(c.s1, rshift(c.s1, 11))
	c.s1 = bxor(c.s1, band(lshift(c.s1, 7), 0x9D2C5680))
	c.s1 = bxor(c.s1, band(lshift(c.s1, 15), 0xEFC60000))
	c.s1 = bxor(c.s1, rshift(c.s1, 18))

	-- for i = 0, N do
	-- 	print('===i', i, state[i])
	-- end
	return c.s1
end

-- unsigned int y;

-- if ( --left < 0 )
-- 	return ( reloadMT(state, next, left) );

-- y = *next++;

-- y ^= ( y >> 11 );

-- y ^= ( y << 7 ) & 0x9D2C5680U;

-- y ^= ( y << 15 ) & 0xEFC60000U;

-- return ( y ^ ( y >> 18 ) );

function RakNetRandom:randomMT()
	self.count = self.count + 1

	self.left = self.left - 1
	if self.left < 0 then
		return self:reloadMT()
	end

	local c = self.c
	c.y = self.c.state[self.next]
	self.next = self.next + 1
	c.y = bxor(c.y, rshift(c.y, 11))
	c.y = bxor(c.y, band(lshift(c.y, 7), 0x9D2C5680))
	c.y = bxor(c.y, band(lshift(c.y, 15), 0xEFC60000))
	c.y = bxor(c.y, rshift(c.y, 18))
	return c.y
end

-- ( ( double ) randomMT(state, next, left) / 4294967296.0 );
function RakNetRandom:frandomMT()
	return self:randomMT() / 4294967296.0
end

---------------
-- TEST CODE --

-- local ymrand = require('ymrand')
-- ymrand.randomseed(1234)
-- for i = 1, 1000 do
-- 	print(i, ymrand.random(10000))
-- end
-- for i = 1, 1000 do
-- 	print(i, ymrand.random())
-- end


-- local r = RakNetRandom.new()
-- r:seedMT(1234)
-- for i = 1, 1000 do
-- 	print(i, 1 + (r:randomMT() % 10000))
-- end
-- for i = 1, 1000 do
-- 	print(i, r:frandomMT())
-- end

-- TEST CODE --
---------------

local g = RakNetRandom.new()
local objs = {}
local objcounter = 0

ymrand = {}
function ymrand.randomseed(seed)
	g:seedMT(seed)
end

function ymrand.random(m, n)
	if m and n then
		return m + (g:randomMT() % (n - m + 1))
	end
	if m then
		return 1 + (g:randomMT() % m)
	end
	return g:frandomMT()
end

function ymrand.obj_new()
	objcounter = objcounter + 1
	objs[objcounter] = RakNetRandom.new()
	return objcounter
end

function ymrand.obj_delete(id)
	objs[id] = nil
end

function ymrand.obj_randomseed(id, seed)
	local g = objs[id]
	g:seedMT(seed)
end

function ymrand.obj_random(id, m, n)
	local g = objs[id]
	if m and n then
		return m + (g:randomMT() % (n - m + 1))
	end
	if m then
		return 1 + (g:randomMT() % m)
	end
	return g:frandomMT()
end
