globals.__TestDefine = {}

__TestDefine.CallState = {
	enter = 1,
	exit = 2,
}

__TestDefine.MonitorFunc = {}
__TestDefine.Monitor = false -- 战斗监控
__TestDefine.TestSceneID = 999999
__TestDefine.ReadRecordFolderPath = ".\\recordLog"
__TestDefine.historyBattleInfo = {}
__TestDefine.allHistoryBattleInfo = {}
__TestDefine.closeRandFix = false	-- 伤害波动
__TestDefine.randSeedSwitch = false	-- 随机种子开关
__TestDefine.sameSpeedRandFix = false -- 相同速度随机出手开关
__TestDefine.buffId = {}
__TestDefine.chProtocol = {}

-- args
-- time: 添加 or 触发次数
__TestDefine.UnitRules = {
	[1] = {
		{typ = "buffTriggerTime",check = "buffId == 1",args = "lessE(time,1)"}, -- 触发添加次数 不超过1次
		{typ = "buffTriggerTime",check = "buffId == 1",args = "lessE(time,1)"}, -- 触发添加次数 不超过1次
	},
}

return __TestDefine