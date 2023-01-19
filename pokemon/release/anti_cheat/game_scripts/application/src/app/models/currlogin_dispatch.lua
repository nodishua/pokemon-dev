-- @Date:   2020-1-2 17:42:29
-- @Desc:	本次登陆缓存数据
local CurrLoginDispatch = class("CurrLoginDispatch", require("app.models.base"))

function CurrLoginDispatch:init(t)
	local idlerMap = {}
	for k,v in pairs(t) do
		idlerMap[k] = idlereasy.new(v, k)
	end
	self.__idlers = idlers.newWithMap(idlerMap, tostring(self))
	return self
end

function CurrLoginDispatch:getIdlerOrigin(name)
	return self:getOrNewRawIdler_(name)
end

return CurrLoginDispatch