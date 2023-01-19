--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2017 TianJi Information Technology Inc.
--
local _M = {}

_M.schedule  = require("packages.components.schedule")
_M.asyncload = require("packages.components.asyncload")
_M.message = require("packages.components.message")

for k, v in pairs(_M) do
	cc.register(k, v)
end

return _M
