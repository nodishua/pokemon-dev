-- @Date:   2018-11-15
-- @Desc:

local blacklist = {}
globals.blacklist = blacklist

local insert = table.insert
local strsub = string.sub

local config = nil
local limitWord = {
	-- ascii, 中文符号，中文符号，汉字
	cn = {{1, "0", "7F"}, {2, "C2A1", "CB9F"}, {3, "E28090", "EFBFA5"}, {3, "E4B880", "E9BEA0"}},
	tw = {{1, "0", "7F"}, {2, "C2A1", "CB9F"}, {3, "E28090", "EFBFA5"}, {3, "E38080", "E9BE98"}},
}

-- 限定字符在指定范围内
local function limitLanguageWord(str)
	if not limitWord[LOCAL_LANGUAGE] then
		return false
	end
	local limit = {}
	for _, v in ipairs(limitWord[LOCAL_LANGUAGE]) do
		table.insert(limit, {v[1], tonumber(v[2], 16), tonumber(v[3], 16)})
	end
	local flag = false -- 标记是否有字符超出限定范围
	local idx = 1
	while idx <= #str do
		local curByte = string.byte(str, idx)
		local num = string.utf8charlen(curByte)
		local valid = false -- 是否有效区内的字符
		for _, v in ipairs(limit) do
			if num == v[1] then
				local character = ""
				for i = 1, v[1] do
					character = character .. string.format("%x", string.byte(str, idx+i-1, idx+i-1))
				end
				local number = tonumber(character, 16)
				if number >= v[2] and number <= v[3] then
					valid = true
					break
				end
			end
		end
		if not valid then
			return true, {idx}
		end
		idx = idx + num
	end
	return false
end

-- 将 str 中的屏蔽字替换为 repStr
local function replaceBlacklist(str, repStr)
	repStr = repStr or "*"
	local flag, t = blacklist.findBlacklist(str)
	if flag then
		table.sort(t, function(a, b)
			return a > b
		end)
		for _, v in ipairs(t) do
			local len = string.utf8charlen(string.byte(str, v))
			str = strsub(str, 1, v-1) .. repStr .. strsub(str, v+len)
		end
	end
	return str
end

-- 屏蔽词中间打空格或者字符&，如果能显示的，属违规
function blacklist.findBlacklist(str)
	if str == nil or str == "" then
		return false
	end

	local flag, t = limitLanguageWord(str)
	if flag then
		return true, t
	end

	if config == nil then
		local path = "app.defines.blacklist." .. LOCAL_LANGUAGE
		if LOCAL_LANGUAGE == 'cn' then
			-- cn must had blacklist
			config = require(path)
		else
			xpcall(function() config = require(path) end, function()
				printWarn('not exist ' .. path)
				config = false
			end)
		end
	end
	if config == false then
		return
	end

	-- 将字符与下标做映射，处理后面的屏蔽词替换
	local chars = {}
	string.gsub(str, '.', function(c)
		insert(chars, c)
	end)
	local map = {}
	if checkLanguage() then
		 -- 去除空格和标点符号
		str = string.gsub(str, "[%s%p]", "")
		if #str == 0 then
			printWarn("detected all space or punctuation")
			return true, {}
		end
		local newT = {}
		string.gsub(str, '.', function(c)
			insert(newT, c)
		end)
		local idx = 1
		for i,v in ipairs(newT) do
			while chars[idx] and v ~= chars[idx] do
				idx = idx + 1
			end
			map[i] = idx
			idx = idx + 1
		end
	else
		for i, _ in ipairs(chars) do
			map[i] = i
		end
	end

	-- 检测屏蔽字
	for _, v in pairs(config) do
		local p1, p2 = string.find(str, v, 1, true)
		if p1 and p2 then
			local t = {}
			local idx = p1
			while idx <= p2 do
				insert(t, map[idx])
				idx = idx + string.utf8charlen(string.byte(str, idx))
			end
			log.collectgarbage(collectgarbage("count"))
			collectgarbage()
			log.collectgarbage(collectgarbage("count"))
			printWarn("detected disabled word [%s]", v)
			return true, t
		end
	end
	log.collectgarbage(collectgarbage("count"))
	collectgarbage()
	log.collectgarbage(collectgarbage("count"))
	return false
end

local function listenerEventTigger(eventType)
	if eventType == ccui.TextFiledEventType.detach_with_ime then
		return true
	end
	if device.platform == "windows" then
		if eventType == ccui.TextFiledEventType.insert_text or eventType == ccui.TextFiledEventType.delete_backward then
			return true
		end
	end
end

-- 输入框添加监听，输入结束时将屏蔽字替换为 repStr
-- 输入结束时处理回调 cb, 做一些显示处理
function blacklist:addListener(input, repStr, cb)
	input:addEventListener(function(sender, eventType)
		local name = input:text()
		if listenerEventTigger(eventType) then
			name = replaceBlacklist(name, repStr)
			input:setText(name)
			if cb then
				cb(name)
			end
		end
	end)
end

