#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2014 YouMi Information Technology Inc.
Copyright (c) 2016 TianJi Information Technology Inc.
'''

import datetime
from collections import namedtuple

CrossCraftStartWeakDay = (1, 5)

# 拳皇争霸流程
# key: (idx, next)
CraftRoundInfo = namedtuple('CraftRoundInfo', ('idx', 'roundIdx', 'next', 'time'))
CraftRoundNextMap = {
	'closed': CraftRoundInfo(-3, 0, 'signup', datetime.time(hour=0)),
	'signup': CraftRoundInfo(-2, 0, 'prepare', datetime.time(hour=10)),
	'prepare': CraftRoundInfo(-1, 0, 'pre11', datetime.time(hour=18, minute=50)),

	# 每轮持续4分钟，其中3分钟为比赛准备阶段倒计时，准备阶段倒计时剩1分钟时无法挑战阵容，还有1分钟为战斗阶段
	'pre11': CraftRoundInfo(11, 1, 'pre12', datetime.time(hour=19)),
	'pre12': CraftRoundInfo(12, 2, 'pre13', datetime.time(hour=19, minute=4)),
	'pre13': CraftRoundInfo(13, 3, 'pre14', datetime.time(hour=19, minute=8)),
	'pre14': CraftRoundInfo(14, 4, 'pre21', datetime.time(hour=19, minute=12)),

	'pre21': CraftRoundInfo(21, 5, 'pre22', datetime.time(hour=19, minute=16)),
	'pre22': CraftRoundInfo(22, 6, 'pre23', datetime.time(hour=19, minute=20)),
	'pre23': CraftRoundInfo(23, 7, 'pre24', datetime.time(hour=19, minute=24)),
	'pre24': CraftRoundInfo(24, 8, 'halftime', datetime.time(hour=19, minute=28)),

	'halftime': CraftRoundInfo(28, 8, 'prepare2', datetime.time(hour=19, minute=32)),
	'prepare2': CraftRoundInfo(29, 8, 'pre31', datetime.time(hour=18, minute=50)),

	'pre31': CraftRoundInfo(31, 9, 'pre32', datetime.time(hour=19)),
	'pre32': CraftRoundInfo(32, 10, 'pre33', datetime.time(hour=19, minute=4)),
	'pre33': CraftRoundInfo(33, 11, 'pre34', datetime.time(hour=19, minute=8)),
	'pre34': CraftRoundInfo(34, 12, 'top64', datetime.time(hour=19, minute=12)),

	'top64': CraftRoundInfo(41, 1, 'top32', datetime.time(hour=19, minute=16)),
	'top32': CraftRoundInfo(42, 2, 'top16', datetime.time(hour=19, minute=20)),
	'top16': CraftRoundInfo(43, 3, 'final1', datetime.time(hour=19, minute=24)),

	'final1': CraftRoundInfo(51, 1, 'final2', datetime.time(hour=19, minute=28)),
	'final2': CraftRoundInfo(52, 2, 'final3', datetime.time(hour=19, minute=32)),
	'final3': CraftRoundInfo(53, 3, 'over', datetime.time(hour=19, minute=36)),
	'over': CraftRoundInfo(54, 4, 'closed', datetime.time(hour=19, minute=40)),
}


# 任务最大等待时间
PlayMaxWaitTime = 5