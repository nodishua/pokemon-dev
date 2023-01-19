-- @Date:   2019-02-22
-- @Desc:
-- @Last Modified time: 2019-02-22
local CurrDayDispatch = class("CurrDayDispatch", require("app.models.base"))

function CurrDayDispatch:init(t)
	local idlerMap = {}
	for k,v in pairs(t) do
		idlerMap[k] = idlereasy.new(userDefault.getCurrDayKey(k, v), k)
		idlereasy.when(idlerMap[k], function(_, val)
			userDefault.setCurrDayKey(k, val)
		end)
	end
	self.__idlers = idlers.newWithMap(idlerMap, tostring(self))
	return self
end

function CurrDayDispatch:getIdlerOrigin(name)
	return self:getOrNewRawIdler_(name)
end

return CurrDayDispatch