--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2017 TianJi Information Technology Inc.
--
-- 字符串辅助函数
--

local format = string.format
local find = string.find
local sub = string.sub
local concat = table.concat
local remove = table.remove

-- 首字母大写
function string.caption(s)
	return string.upper(sub(s, 1, 1)) .. sub(s, 2)
end

-- 扩展 string.format, 第一个参数是 table 进行对应值传递 ('{month}月{day}日', {day=1, month=2})
function string.formatex(str, ...)
	local args = {...}
	if type(args[1]) == "table" then
		local t = clone(args[1])
		for k, v in pairs(t) do
			-- 转译 % 内容为显示项
			t[k] = string.gsub(v, "%%", "%%%%")
		end
		local s = {}
		local p = find(str, "{")
		local q = find(str, "}", p)
		while p and q do
			local key = sub(str, p+1, q-1)
			if t[key] then
				s[#s + 1] = sub(str, 1, p-1)
				s[#s + 1] = t[key]
			else
				s[#s + 1] = sub(str, 1, q)
			end
			str = sub(str, q+1)
			p = find(str, "{")
			q = find(str, "}", p)
		end
		s[#s + 1] = str
		str = concat(s)
		remove(args, 1)
	end
	return format(str, unpack(args))
end

-- 限制字数，多余裁剪
-- @param isWord 默认按字符数限制，true按字设置
function string.utf8limit(input, length, isWord)
	local idx, pos, total = 1, 0, 0
	while idx <= #input do
		local curByte = string.byte(input, idx)
		local num = string.utf8charlen(curByte)
		total = total + (isWord and 1 or num)
		if total > length then
			return string.sub(input, 1, idx-1), total
		end
		idx = idx + num
	end
	return input, total
end

local first = {
	{{0x00, 0x7F}, 0},
	{{0xC0, 0xDF}, 1},
	{{0xE0, 0xEF}, 2},
	{{0xF0, 0xF7}, 3},
}

function string.isbin(s)
	local remain = 0
	for i = 1, #s do
		local b = s:byte(i)
		if remain == 0 then
			local flag = false
			for _, t in ipairs(first) do
				if t[1][1] <= b and b <= t[1][2] then
					remain = t[2]
					flag = true
					break
				end
			end
			if not flag then
				return true
			end
		else
			if b < 0x80 or b > 0xBF then
				return true
			end
			remain = remain - 1
		end
	end
	if remain == 0 then
		return false
	end
	return true
end

local isbin = string.isbin
function string.isobjectid(s)
	return #s == 12 and isbin(s)
end

-- local test={94,73,68,109,94,194,150,125,20,13,203,181}
-- test = string.char(unpack(test))
-- print(isbin(test))