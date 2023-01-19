#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
huanxi2394fd79a1ad32ff2e2db603da
'''

from framework.log import logger
from tornado.gen import coroutine, Return

'''
同步脚本
'''
# def exec_func(rpcServer):
# 	logger.info('i am exec_func')
# 	ret = []
# 	ret.append(str(rpcServer.dbcAccount))
# 	ret.append(str(rpcServer.dbcGame))

# 	from game.object.game import ObjectGame
# 	ret.append(ObjectGame.ObjsMap.keys())

# 	return ret

'''
异步脚本
'''
# @coroutine
# def exec_coroutine(rpcServer):
# 	logger.info('i am exec_coroutine')
# 	ret = []
# 	ret.append(str(rpcServer.dbcAccount))
# 	ret.append(str(rpcServer.dbcGame))

# 	from game.object.game import ObjectGame
# 	ret.append(ObjectGame.ObjsMap.keys())

# 	game = ObjectGame.ObjsMap.get(5968)
# 	if game:
# 		game.role.gold = 99999

# 	raise Return(ret)

'''
接口替换，修复bug用
'''
logger.info('!!!')
@coroutine
def exec_coroutine(rpcServer):
	from framework import todayinclock5date2int, nowdatetime_t, int2time
	from framework.object import ObjectBase
	from framework.csv import csv, ErrDefs
	from framework.log import logger
	from framework.helper import getL10nCsvValue

	from game import ServerError, ClientError
	from game import globaldata
	from game.object import TaskDefs
	from game.object.game.gain import ObjectGainAux

	from tornado.gen import coroutine, Return
	import datetime

	from game.object.game.role import ObjectRole


	def stamina():
		dbkey = 'stamina'
		def fget(self):
			self.refreshStamina()
			return self.db[dbkey]
		def fset(self, value):
			'''
			+=: fget and fset
			= : fset
			'''
			# from framework.log import logger
			# logger.info('infix stamina')
			from game.globaldata import StaminaLimitMax
			from game.object import TargetDefs, AchievementDefs
			from game.object.game.union import ObjectUnionContribTask
			old = self.db[dbkey]
			self.db[dbkey] = max(0, min(value, StaminaLimitMax))
			if value < old:
				ObjectUnionContribTask.onCount(self.game, TargetDefs.CostStamina, old - value)
				self.game.mysteryShop.onStaminaConsume(self.game, old - value)
				self.game.capture.onStaminaConsume(old - value)
			elif value > old:
				self.game.achievement.onTargetTypeCount(AchievementDefs.StaminaCount)
		return locals()

	from framework.object import db_property
	ObjectRole.stamina = db_property(**stamina())

	raise Return('ok')


if __name__ == '__main__':
	print 'in __main__'
