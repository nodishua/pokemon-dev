--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2019 TianJi Information Technology Inc.
--
-- effect相关easy功能
-- easy在battle相关类中抽离出来
--
-- BattleSprite和BattleView都有effectManager
-- 均能实现effect功能，但流程细节差异
--
-- BattleView：
--     onEventEffect         无序执行，有id时会获取BattleSprite作为effect的target
--     onEventEffectQueue 	 有序执行，target是BattleView
--     onEventEffectQueueFor 有序执行，target是参数view，一般是BattleSprite
-- BattleView中modelWait会等队列为空后执行下个逻辑流程
--
-- BattleSprite：
--     onEventEffect         无序执行，target是自己
--     onEventEffectQueue 	 有序执行，target是自己
-- BattleSprite的队列只是播放顺序控制，不影响逻辑流程
-- BattleSprite被移除后，相关特效也结束，生命周期与BattleView不同
--
-- 将来可能使用到：
-- 多BattleSprite同时进行。那就不能像现在都挂到BattleView上
-- view.parallel(sprite1.sequence, sprite2.sequence, ...)
--
-- BattleSprite未完整播放，流程要往下继续，且BattleSprite本身需要依次播放
-- view.wait(sprite1.sequence1)
-- view.wait(sprite1.sequence2, sprite2.sequence1)
-- view.wait(sprite2.sequence2, sprite3.sequence1)
--

--------------------------------------
-- event effect
-- for effectManager(battleEffect.Manager)
--------------------------------------

function battleEasy.effect(id, fOrStr, args)
	local typ = type(fOrStr)
	if typ == "function" then
		gRootViewProxy:proxy():onEventEffect(id, 'callback', {
			func = fOrStr,
			delay = args and args.delay,
			lifetime = args and args.lifetime,
		})
	elseif typ == "string" then
		gRootViewProxy:proxy():onEventEffect(id, fOrStr, args)
	else
		error("only function or string be allowed")
	end
end

function battleEasy.queueEffect(fOrStr, args)
	local typ = type(fOrStr)
	if typ == "function" then
		gRootViewProxy:proxy():onEventEffectQueue('callback', {
			func = fOrStr,
			delay = args and args.delay,
			lifetime = args and args.lifetime,
			zOrder = args and args.zOrder,
		})
	elseif typ == "string" then
		gRootViewProxy:proxy():onEventEffectQueue(fOrStr, args)
	else
		error("only function or string be allowed")
	end
end

function battleEasy.queueNotify(msg, ...)
	assert(type(msg) == "string", "msg not string type")

	local args = {...}
	gRootViewProxy:proxy():onEventEffectQueue('callback', {func=function()
		gRootViewProxy:notify(msg, unpack(args))
	end})
end

function battleEasy.queueZOrderNotify(msg,zOrder, ...)
	assert(type(msg) == "string", "msg not string type")

	local args = {...}
	gRootViewProxy:proxy():onEventEffectQueue('callback', {func=function()
		gRootViewProxy:notify(msg, unpack(args))
	end,zOrder = zOrder})
end

function battleEasy.queueNotifyFor(view, msg, ...)
	assert(view, "view is nil, plz use queueNotify")
	assert(type(msg) == "string", "msg not string type")

	local args = {...}
	gRootViewProxy:proxy():onEventEffectQueue('callback', {func=function()
		view:notify(msg, unpack(args))
	end})
end


--------------------------------------
-- defer effect queue
-- for deferListMap
--------------------------------------

function battleEasy.deferEffect(...)
	error("temporary")

	return gRootViewProxy:proxy():addCallbackToCurDeferList(...)
end

function battleEasy.deferCallback(f)
	return gRootViewProxy:proxy():addCallbackToCurDeferList(f)
end

function battleEasy.deferNotify(view, msg, ...)
	local f = functools.handler(view or gRootViewProxy, "notify", msg, ...)
	return gRootViewProxy:proxy():addCallbackToCurDeferList(f)
end

--function battleEasy.deferEffectCantJump(...)
--	error("temporary")

--	return gRootViewProxy:proxy():addCallbackToCurDeferListAndCantJump(...)
--end

function battleEasy.deferCallbackCantJump(f)
	return gRootViewProxy:proxy():addCallbackToCurDeferList(f,battle.FilterDeferListTag.cantJump)
end

function battleEasy.deferNotifyCantJump(view, msg, ...)
	local f = functools.handler(view or gRootViewProxy, "notify", msg, ...)
	return gRootViewProxy:proxy():addCallbackToCurDeferList(f,battle.FilterDeferListTag.cantJump)
end

function battleEasy.deferNotifyCantClean(view, msg, ...)
	local f = functools.handler(view or gRootViewProxy, "notify", msg, ...)
	return gRootViewProxy:proxy():addCallbackToCurDeferList(f,battle.FilterDeferListTag.cantClean)
end

