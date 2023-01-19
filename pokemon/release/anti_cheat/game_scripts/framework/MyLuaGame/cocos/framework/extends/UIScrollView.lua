
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

local ScrollView = ccui.ScrollView

function ScrollView:onEvent(callback)
    if callback == nil then
        return self:disableEventListener()
    end
    self:addEventListener(function(sender, eventType)
        local event = {target = sender, type = eventType}
        if eventType == 0 then
            event.name = "SCROLL_TO_TOP"
        elseif eventType == 1 then
            event.name = "SCROLL_TO_BOTTOM"
        elseif eventType == 2 then
            event.name = "SCROLL_TO_LEFT"
        elseif eventType == 3 then
            event.name = "SCROLL_TO_RIGHT"
        elseif eventType == 4 then
            event.name = "SCROLLING"
        elseif eventType == 5 then
            event.name = "BOUNCE_TOP"
        elseif eventType == 6 then
            event.name = "BOUNCE_BOTTOM"
        elseif eventType == 7 then
            event.name = "BOUNCE_LEFT"
        elseif eventType == 8 then
            event.name = "BOUNCE_RIGHT"
        elseif eventType == 9 then
            event.name = "CONTAINER_MOVED"
        elseif eventType == 10 then
            event.name = "SCROLLING_BEGAN"
        elseif eventType == 11 then
            event.name = "SCROLLING_ENDED"
        elseif eventType == 12 then
            event.name = "AUTOSCROLL_BEGAN"
        elseif eventType == 13 then
            event.name = "AUTOSCROLL_ENDED"
        end
        callback(event)
    end)
    return self
end

ScrollView.onScroll = ScrollView.onEvent

function ScrollView:scheduleUpdate(callback)
    -- ScrollView本身会拦截update，需要靠getInnerContainer来驱动
    self:getInnerContainer():scheduleUpdateWithPriorityLua(callback, 0)
    return self
end