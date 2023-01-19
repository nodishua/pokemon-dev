--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2020 TianJi Information Technology Inc.
--


math.newrandomseed()
-- if ymrand no init, the rand result are same
if ymrand then
	ymrand.randomseed(os.time() + math.random())
	-- for statis in ymrand.random
	ymrand.randCount = 0
	local ymrandom = ymrand.random
	ymrand.random = function(...)
		ymrand.randCount = ymrand.randCount + 1
		return ymrandom(...)
	end
end

local r = math.random(5, 10)
for i = 1, r do
	math.random()
	cc.random()
end

-- 参考Python相关库函数
local random = {}
globals.random = random

-- choice([1,2,3])
-- Return a random element from the non-empty sequence seq.
function random.choice(seq)
	assert(seq and next(seq), "seq is empty")
	return seq[math.random(1, table.length(seq))]
end

-- Return a k length list of unique elements chosen from the population sequence. Used for random sampling without replacement.
function random.sample(population, k, random)
	random = random or math.random
	local n = table.length(population)
	if k == 0 then return {} end
	if k >= n then return population end
	local ret, hash = {}, {}
	if n > 50 then
		-- its good for big table
		for i = 1, k do
			local r = random(1, n)
			while hash[r] do
				r = random(1, n)
			end
			hash[r] = true
		end
		for i, _ in pairs(hash) do
			table.insert(ret, population[i])
		end
	else
		for i = 1, n do
			table.insert(hash, i)
		end
		for i = 1, k do
			local r = random(i, n)
			hash[r], hash[i] = hash[i], hash[r]
			table.insert(ret, population[hash[i]])
		end
	end
	return ret
end

-- Shuffle the sequence x in place.
function random.shuffle(x, random)
	random = random or math.random
	local n = table.length(x)
	for i = 1, n do
		local j = random(0, n - i) + i
		x[i], x[j] = x[j], x[i]
	end
	return x
end

-- Return a random floating point number N such that low <= N <= high and with the specified mode between those bounds.
-- http://en.wikipedia.org/wiki/Triangular_distribution
function random.triangular(low, high, mode)
	u = math.random()
	c = 0.5
	if mode then
		c = 1.0 * (mode - low) / (high - low)
	end
	if u > c then
		u = 1.0 - u
		c = 1.0 - c
		low, high = high, low
	end
	return low + (high - low) * (u * c) ^ 0.5
end

