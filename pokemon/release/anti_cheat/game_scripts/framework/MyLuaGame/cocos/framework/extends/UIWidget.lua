--[[

Copyright (c) 2014-2017 Chukong Technologies Inc.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

]]

local Widget = ccui.Widget

function Widget:onTouch(callback)
	self:addTouchEventListener(function(sender, state)
		local event = {x = 0, y = 0, target = sender}
		if state == 0 then
			local pos = self:getTouchBeganPosition()
			event.x, event.y = pos.x, pos.y
			event.name = "began"

		elseif state == 1 then
			local pos = self:getTouchMovePosition()
			event.x, event.y = pos.x, pos.y
			event.name = "moved"

		elseif state == 2 then
			local pos = self:getTouchEndPosition()
			event.x, event.y = pos.x, pos.y
			event.name = "ended"
		else
			local pos = self:getTouchEndPosition()
			event.x, event.y = pos.x, pos.y
			event.name = "cancelled"
		end
		callback(event)
	end)
	return self
end

function Widget:onClick(callback)
	self:addClickEventListener(function(sender)
		local pos = self:getTouchEndPosition()
		local event = {x = pos.x, y = pos.y, target = sender}
		callback(event)
	end)
	return self
end

function Widget:onLongTouch(delay, callback)
	local isBegan = false
	local sequence
	self:addTouchEventListener(function(sender, state)
		local event = {x = 0, y = 0, target = sender}
		if state == 0 then
			local pos = self:getTouchBeganPosition()
			event.x, event.y = pos.x, pos.y
			event.name = "began"
			sequence = cc.Sequence:create(cc.DelayTime:create(delay), cc.CallFunc:create(function()
				callback(event)
				isBegan = true
				if sequence then
					sequence:autorelease()
					sequence = nil
				end
			end))
			sequence:retain()
			self:runAction(sequence)

		elseif state == 1 then
			local pos = self:getTouchMovePosition()
			event.x, event.y = pos.x, pos.y
			event.name = "moved"
			callback(event)

		elseif state == 2 or state == 3 then
			local pos = self:getTouchEndPosition()
			event.x, event.y = pos.x, pos.y
			if state == 2 then
				event.name = "ended"
			else
				event.name = "cancelled"
			end
			if isBegan then
				callback(event)
				isBegan = false
			else
				event.name = "click"
				callback(event)
			end
			if sequence then
				self:stopAction(sequence)
				sequence:autorelease()
				sequence = nil
			end
		end
	end)

	return self
end