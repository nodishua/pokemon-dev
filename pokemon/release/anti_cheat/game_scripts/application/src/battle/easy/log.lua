--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2020 TianJi Information Technology Inc.
--
-- Log相关

function battleEasy.logHerosInfo(scene)
	-- 打印属性
	lazylog.battle.gate.allHerosInfo(" ---- 打印双方角色血量和怒气信息：", function()
		for _, obj in scene.heros:order_pairs() do
			printDebug(' -- 己方: seat=%s, hp=%s, mp=%s',
					obj.seat, obj:hp(), obj:mp1())
		end
		for _, obj in scene.enemyHeros:order_pairs() do
			printDebug(' -- 敌方: seat=%s, hp=%s, mp=%s',
					obj.seat, obj:hp(), obj:mp1())
		end
	end)
end
