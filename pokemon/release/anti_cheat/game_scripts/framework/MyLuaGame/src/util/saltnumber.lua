--
-- Copyright (c) 2014 YouMi Technologies Inc.
-- Copyright (c) 2020 TianJi Information Technology Inc.
--
-- safe table protect for client, defeat cheater
--

local ObjectCounter = 0
local Objects = setmetatable({}, {__mode = 'v'})
local DeltaSum = 0


function globals.updateSaltNumber(delta)
	-- 现在通过跟服务器交互后，在_modelUpdSync中进行增量方式的地址更改
	-- 如果没有触发gc，Objects里的数据会越来越多，导致一次update性能低下
	do return end

	DeltaSum = DeltaSum + delta
	if DeltaSum < 1 then return end
	DeltaSum = 0

	if gGameUI.rootViewName ~= "ui.city" then
		return
	end

	local cnt = 0
	for _, obj in pairs(Objects) do
		obj:permute()
		cnt = cnt + 1
	end

	-- print('!!!! updateSaltNumber', ObjectCounter, cnt)
end

-- 暂时只有战斗在用
function globals.clearAllSaltNumber()
	printInfo('clearAllSaltNumber %d %d', ObjectCounter, itertools.size(Objects))

	ObjectCounter = 0
	Objects = setmetatable({}, {__mode = 'v'})
end

function globals.isSaltNumber(t)
	return type(t) == "table" and t.__issalt
end


-- 数据加盐保护

globals.SaltNumber = {}
SaltNumber.__index = SaltNumber

function SaltNumber.new(...)
	ObjectCounter = ObjectCounter + 1
	local id = ObjectCounter
	local obj = setmetatable({__id = id, __issalt = true}, SaltNumber)
	obj:ctor(...)
	Objects[id] = obj
	return obj
end

function SaltNumber:ctor(v)
	self(v)
end

function SaltNumber:__call(v)
	-- getter
	if v == nil then
		v = self.pt[1] * self.pt[2] + self.pt[3]
		-- in luajit use bitop to compare
		local delta = v - self.val * 1.0
		if math.abs(delta) > 1e-5 then
			errorInWindows('salt delta too big %s %s %s', delta, v, self.val)
			error("close your cheating software")
		end
		return self(self.val)

	-- setter
	else
		local salt = math.random(100847) + math.random()
		local flag = math.random(2)
		if flag == 1 then
			salt = -salt
		end
		local n = math.floor(v / salt) + math.random(11)
		local res = v - (n * salt)
		self.pt = {salt, n, res}
		self.val = v
		return v
	end
end

function SaltNumber:permute()
	self(self())
end

-- local a = SaltNumber.new(1234567890)
-- print(a.val[1], a.val[2], a.val[3])
-- print(a())
-- for i = 1, 1000 do
-- 	print('----')
-- 	a:permute()
-- 	print(a.val[1], a.val[2], a.val[3])
-- 	print(a())
-- end