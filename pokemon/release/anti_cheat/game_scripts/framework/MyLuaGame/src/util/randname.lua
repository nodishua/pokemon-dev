--
-- Author: sir.huangwei@gmail.com
-- Date: 2015-05-29 11:16:08
--

local _strformat = string.format
local _randomseed = math.randomseed
local _random = math.random

_randomseed(os.time() - 1400000000)

local config = nil

function globals.randomName()
	if config == nil then
		local path = "app.defines.randname." .. LOCAL_LANGUAGE
		xpcall(function() config = require(path) end, function()
			printWarn('not exist ' .. path)
			config = require("app.defines.randname.en")
		end)
	end
	local names, nameCenters, namePrefixs = config.names, config.nameCenters, config.namePrefixs
	nameCenters = nameCenters or {''}

    local n1 = _random(1, #names)
    local n2 = _random(1, #nameCenters)
    local n3 = _random(1, #namePrefixs)
    local ret
    if LOCAL_LANGUAGE ~= 'cn' and LOCAL_LANGUAGE ~= 'tw' then
    	ret = string.format("%s %s", namePrefixs[n3], names[n1])
    else
    	ret = namePrefixs[n3] .. nameCenters[n2] .. names[n1]
    end
    if #ret > 18 then
    	return randomName()
    end
    return ret
end

