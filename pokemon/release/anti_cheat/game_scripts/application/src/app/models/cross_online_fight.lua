--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2016 TianJi Information Technology Inc.
--
-- CrossOnlineFight
--

local Base = require("app.models.base")
local CrossOnlineFight = class("CrossOnlineFight", Base)

function CrossOnlineFight:init(t)
	Base.init(self, t)

	local match_result = idlereasy.new('', 'match_result')
	self.__idlers:add('match_result', match_result)
	return self
end

function CrossOnlineFight:pushMatchResult(t)
	self.__idlers:at('match_result'):set(t.match_result)
end

return CrossOnlineFight