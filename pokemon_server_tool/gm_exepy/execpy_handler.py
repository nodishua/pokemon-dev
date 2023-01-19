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
def exec_func(rpcServer):
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

	from game.handler._game import BuyExpItem

	@coroutine
	def run_fix(self):
		# logger.info('run_fix')
		from framework.csv import csv
		from game.object.game.gain import ObjectGainAux, ObjectCostAux
		from game.handler.inl import effectAutoGain
		from game import ClientError

		itemID = self.input.get('itemID', None)
		itemCount = self.input.get('itemCount', 1)
		if itemID is None or itemID not in csv.items:
			raise ClientError('itemID error')
		if itemCount <= 0:
			raise ClientError('itemCount error')

		cfg = csv.items[itemID]
		needLevel = cfg.specialArgsMap['buy_level']
		needRmb = cfg.specialArgsMap['buy_rmb'] * itemCount
		if self.game.role.level < needLevel:
			raise ClientError(ErrDefs.buyItemLevelLimit)

		needRmb = int(needRmb * (1 - self.game.trainer.expItemCostFailRate))
		if needRmb <= 0:
			needRmb = 1
		cost = ObjectCostAux(self.game, {'rmb': needRmb})
		if not cost.isEnough():
			raise ClientError("cost rmb not enough")
		cost.cost(src='exp_buy_item')
		eff = ObjectGainAux(self.game, {itemID: itemCount})
		yield effectAutoGain(eff, self.game, self.dbcGame, src='exp_buy_item')

	BuyExpItem.run = run_fix


if __name__ == '__main__':
	print 'in __main__'
