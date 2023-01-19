
function schedule(node, callback, delay)
	local delay = cc.DelayTime:create(delay)
	local sequence = cc.Sequence:create(delay, cc.CallFunc:create(callback))
	local action = cc.RepeatForever:create(sequence)
	node:runAction(action)
	return action
end

function performWithDelay(node, callback, delay)
	local delay = cc.DelayTime:create(delay)
	local cb = function()
		if gGameApp then
			gGameApp:onViewSchedule(node)
		end
		callback()
		if gGameApp then
			gGameApp:onViewSchedule(nil)
		end
	end
	local sequence = cc.Sequence:create(delay, cc.CallFunc:create(cb))
	node:runAction(sequence)
	return sequence
end
