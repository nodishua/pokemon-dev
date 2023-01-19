#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
huanxi2394fd79a1ad32ff2e2db603da
'''

from framework.log import logger
from tornado.gen import coroutine, Return

@coroutine
def exec_coroutine(rpcServer):
	from framework.log import logger
	from tornado.gen import coroutine, Return
	from game.object.game import ObjectGame
	from game.session import Session
	from framework.helper import string2objectid

	server = rpcServer.game
	dbcGame = server.dbcGame
	rpcPVP = server.rpcPVP
	rpcUnion = server.rpcUnion

	from framework.csv import csv

	from game.object.game.gain import ObjectGainAux
	from game.object.game.card import ObjectCardRebirthFactory
	from game.handler.inl import effectAutoGain
	from game.handler._pvp import refreshCardsToPVP
	from game.object.game.yyhuodong import ObjectYYHuoDongFactory
	from framework import nowdatetime_t, todayinclock5elapsedays
	from game.object.game.union_fight import ObjectUnionFightGlobal

	obj = ObjectUnionFightGlobal.Singleton
	if obj.round == "prepare":
		obj.round = 'signup'
		yield ObjectUnionFightGlobal.onStartPrepare(server.rpcUnionFight)

if __name__ == '__main__':
	print 'in __main__'

