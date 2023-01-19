--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2018 TianJi Information Technology Inc.
--
-- @desc 处理需要描边操作的字体
--

local text = {}
globals.text = text

-- @param   -- effects  = {"italic" = {color = cc.c3b,  size= xxx, }, .....}
--
-- node:设置的节点
-- effects:  {}						特别效果
-- fontSize: float值 				字体大小
-- fontColor: cc.c3b(r,g,b)值 		字体颜色
-- outlineSize: int值				描边大小
-- outlineColor: cc.c4b(r,g,b,a)	描边颜色, cc.c3b()无效
-- glowColor: cc.c4b(r,g,b,a)		发光颜色
-- shadowColor: cc.c3b(r,g,b)		投影颜色
-- shadowoffset: cc.size(x,y)		投影偏移量
-- shadowSize: float值				投影偏大小


local textEffect = {}

-- 倾斜
function textEffect.italic(node, args)
	node:setRotationSkewX(12)
end

-- 描边
function textEffect.outline(node, args)
	local size = args.size or ui.DEFAULT_OUTLINE_SIZE
	node:enableOutline(args.color, size)
end

-- 发光
function textEffect.glow(node, args)
	node:enableGlow(args.color)
end

-- 阴影
function textEffect.shadow(node, args)
	node:enableShadow(args.color, args.offset, args.size)
end

-- 加粗
function textEffect.bold(node)
	if tolua.type(node) == "ccui.Text" then
		node:getVirtualRenderer():enableBold()
	else
		node:enableBold()
	end
end

function textEffect.color(node, color)
	node:setTextColor(color)
end

function textEffect.size(node, size)
	if tolua.type(node) == "cc.Label" and size then
		node:setSystemFontSize(size)
	elseif tolua.type(node) == "ccui.Text" and size then
		node:setFontSize(size)
	else
		assert(false, "invalid node type, use ccui.Text or Label can set fontSize")
	end
end

-- @parm effects  = {"italic" = {color = cc.c3b,  size= xxx, }, .....}
-- set text effect style
function text.addEffect(node, effects)
	for effect, args in pairs(effects) do
		effect = string.lower(effect)
		textEffect[effect](node, args)
	end
end

local parms = {
	italic = cc.LabelEffect.NORMAL,
	outline = cc.LabelEffect.OUTLINE,
	shadow = cc.LabelEffect.SHADOW,
	glow = cc.LabelEffect.GLOW,
}

-- @parm 强制删除一些效果，其实就是把效果变为设置为默认参数
function text.deleteEffect(node, effects)
	if not effects then return end

	if effects == 'all' then
		-- textEffect.font(node, {color = cc.c3b(255, 255, 255)})
		node:disableEffect()
		return
	end

	for _, effect in ipairs(effects) do
		effect = string.lower(effect)
		node:disableEffect(parms[effect])
	end
end

-- 删除所有效果
function text.deleteAllEffect(node)
	return text.deleteEffect(node, 'all')
end