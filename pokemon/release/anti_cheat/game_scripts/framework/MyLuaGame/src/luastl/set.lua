--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2017 TianJi Information Technology Inc.
--

local CSet = class("CSet", require("luastl.map"))
globals.CSet = CSet

function CSet:insert(key)
	return CMap.insert(self, key, true)
end

function CSet:find(key, defval)
	return CMap.find(self, key, false)
end

function CSet:equal(rhs)
	return CMap.equal(self, rhs)
end

return CSet