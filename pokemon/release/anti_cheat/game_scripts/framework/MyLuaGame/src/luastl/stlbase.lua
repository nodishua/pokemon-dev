--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2017 TianJi Information Technology Inc.
--

local _strfmt = string.format
local _stlidcount = 0

local CSTLBase = class("CSTLBase")

function CSTLBase:ctor()
	_stlidcount = _stlidcount + 1
	self.__stlid = _stlidcount
end

function CSTLBase:__tostring()
	local function tostr(t)
		local tp = lua_type(t)
		if lua_type(t) == "userdata" then
			return type(t) .. " " .. tostring(t)
		end
		return tostring(t)
	end

	local stlidcount = self.__stlid or 0
	local ret = ""
	local iter_func = self.__pairs or self.__ipairs
	if iter_func ~= nil then
		ret = _strfmt("%s 0x%x = {\n", self.__cname, stlidcount)
		for k, v in iter_func(self) do
			ret = ret .. _strfmt("[%s] = %s,\n", tostr(k), tostr(v))
		end
		ret = ret .. "}"
	else
		ret = _strfmt("%s: 0x%08X", self.__cname, stlidcount)
	end
	return ret
end

function CSTLBase:print()
	print(self:__tostring())
end

function CSTLBase:retain()
end

function CSTLBase:autorelease()
end

function CSTLBase:release()
	self:clear()
end

return CSTLBase