--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2017 TianJi Information Technology Inc.
--
-- 流式RichText
-- 为剧情聊天等打字机效果使用
--

require "easy.richtext"
local utf8CharSize = string.utf8charlen

globals.StreamRichText = class("StreamRichText")

function StreamRichText:ctor(str, lineWidth)
	self.raw = ccui.RichText:create()
	self.nElems = 0
	self.elems = rich.createElemsWithWidth(str, nil, nil, lineWidth)
	-- 当前显示的位置
	self.curLen = 0
	self.targetLen = 0
end

function StreamRichText:showWithLen(len)
	self:clear()
	self.targetLen = len

	-- 现在只有文字
	for _, t in ipairs(self.elems) do
		-- t[1]不要使用，可能已经被cdx autorelease了
		local _, params = t[1], t[2]
		local color, opacity, s, ttf, fontSize = unpack(params)
		local flag = self:addElement(s, color, opacity, ttf, fontSize)
		if flag then return end
	end
end

function StreamRichText:getLen()
	local wCount = 0
	for _, t in ipairs(self.elems) do
		local _, params = t[1], t[2]
		local color, opacity, s, ttf, fontSize = unpack(params)
		local i = 1
		while i <= #s do
			local byte = s:byte(i)
			i = i + utf8CharSize(byte)
			if byte ~= 10 then -- ignore `\n`
				wCount = wCount + 1
			end
		end
	end
	return wCount
end

-- 删除所有子节点
function StreamRichText:clear()
	local richtext = self.raw
	for i = self.nElems - 1, 0, -1 do
		richtext:removeElement(i)
	end
	self.nElems = 0
	self.curLen = 0
end

function StreamRichText:addElement(str, color, opacity, ttf, fontSize)
	local tag = 1 --先写死
	local i = 1
	local wCount = 0
	while i <= #str and self.curLen + wCount < self.targetLen do
		local byte = str:byte(i)
		i = i + utf8CharSize(byte)
		if byte ~= 10 then -- ignore `\n`
			wCount = wCount + 1
		end
	end
	local resultStr = str:sub(1, i - 1)

	local element = ccui.RichElementText:create(tag, color, opacity, resultStr, ttf, fontSize)
	self.raw:pushBackElement(element)
	self.nElems = self.nElems + 1
	self.curLen = self.curLen + wCount
	if self.curLen >= self.targetLen then
		return true
	end
end

