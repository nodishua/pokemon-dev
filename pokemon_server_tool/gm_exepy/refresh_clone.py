#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
huanxi2394fd79a1ad32ff2e2db603da
'''

from framework.log import logger
from tornado.gen import coroutine, Return

@coroutine
def exec_coroutine(rpcServer):
	from game.session import Session

	yield Session._onCloneRoomRefresh()


if __name__ == '__main__':
	print 'in __main__'
