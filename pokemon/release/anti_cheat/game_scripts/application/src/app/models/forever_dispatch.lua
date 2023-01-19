-- @Date:   2019-02-22
-- @Desc:
-- @Last Modified time: 2019-02-22
local ForeverDispatch = class("ForeverDispatch", require("app.models.base"))

function ForeverDispatch:init(t)
	local idlerMap = {}
	for k,v in pairs(t) do
		idlerMap[k] = idlereasy.new(userDefault.getForeverLocalKey(k, v), k)
		idlereasy.when(idlerMap[k], function(_, val)
			userDefault.setForeverLocalKey(k, val)
		end)
	end
	self.__idlers = idlers.newWithMap(idlerMap, tostring(self))
	return self
end

function ForeverDispatch:getIdlerOrigin(name)
	return self:getOrNewRawIdler_(name)
end

return ForeverDispatch