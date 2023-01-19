--
-- ViewBase bind effect 相关
--

-- @param event: animation
function bind.animation(view, node, b)
	local name = b.name or b.res
	local effect = widget.addAnimationByKey(node, b.res, name, b.action, b.zOrder)
	if b.pos then
		effect:xy(b.pos)
	end
	if b.scale then
		effect:scale(b.scale)
	end
end

