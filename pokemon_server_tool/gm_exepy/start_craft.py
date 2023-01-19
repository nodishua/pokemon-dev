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
	rpcCraft = server.rpcCraft

	from game.object.game.craft import ObjectCraftInfoGlobal

	yield ObjectCraftInfoGlobal.onStartCraft(rpcCraft)

	raise Return(None)

if __name__ == '__main__':
	print 'in __main__'

