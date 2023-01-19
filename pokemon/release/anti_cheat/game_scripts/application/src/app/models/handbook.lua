-- @Date:   2019-02-21
-- @Desc:
-- @Last Modified time: 2019-02-21
local Base = require("app.models.base")
local Handbook = class("Handbook", Base)

function Handbook:init(t)
	local idlerMap = {}
	if t._db and t._db.pokedex then
		idlerMap["isNew"] = idlereasy.new(false, "isNew")
	end
	self.__idlers = idlers.newWithMap(idlerMap, tostring(self))
	return self
end

function Handbook:syncFrom(t, new)
	local new = new or {}
	if t._db and t._db.pokedex then
		self:getRawIdler_("isNew"):set(true)
	end
end

function Handbook:getIdlerOrigin(name)
	return self:getOrNewRawIdler_(name)
end

function Handbook:syncDel(t)
	if t._db and t._db.pokedex then
		self:getRawIdler_("isNew"):set(false)
	end
end

return Handbook