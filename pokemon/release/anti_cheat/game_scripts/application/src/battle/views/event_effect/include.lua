--
-- event effect all
--

local battleEffect = {}
globals.battleEffect = battleEffect

require "battle.views.event_effect.effect"
require "battle.views.event_effect.effect1"
require "battle.views.event_effect.effect2"
require "battle.views.event_effect.callback_debug"

--[[

damageSeg	总伤害的百分比,需要取总伤害
hpSeg	加血分段
soundArgs	全局-音效路径
music 全局-背景音乐
showCards	0-正常；1-隐藏
effect	按照特效相对应的元素配置(移动速度只对飞行特效生效，存活之间只对子物体特效生效)
shaker	全局-震屏的起始，结束的时间，震屏的幅度
moveArgs	受击目标的表现（位移，大小，旋转）
show	显示隐藏

]]--

local EventEffectMap = {
	-- effect1.lua
	sound = battleEffect.Sound, -- 全局-音效路径
	damageSeg = battleEffect.SegShow, -- 总伤害的百分比,需要取总伤害
	hpSeg = battleEffect.SegShow, -- 加血分段
	shaker = battleEffect.Shaker, -- 全局-震屏
	music = battleEffect.Music, -- 全局-背景音乐
	move = battleEffect.Move, -- 位移
	show = battleEffect.Show, -- 0-正常；1-隐藏
	effect = battleEffect.SpriteEffect, -- 播放特效
	delay = battleEffect.Delay, -- 延迟
	zOrder = battleEffect.ZOrder,	--z轴设置

	-- effect2.lua
	moveByDis = battleEffect.MoveByDis, --移动多少距离
	moveByTime = battleEffect.MoveByTime, --移动多少时间
	moveTo = battleEffect.MoveTo, --移动到
	comeBack = battleEffect.ComeBack, -- 精灵回归动画
	callback = battleEffect.Callback, --回调
	follow = battleEffect.Follow, --跟随
	wait = battleEffect.Wait, --等待，外部stop
	jump = battleEffect.Jump, --大招跳过
	control = battleEffect.Control, --单位控件
	onceEffect = battleEffect.OnceEffect -- 一次性特效

	-- flashTo = 5, --瞬移
	-- faceTo = 6, --面向
}

function globals.newEventEffect(type, view, args, target)
	local cls = EventEffectMap[type]
	return cls.new(view, args, target)
end

return battleEffect