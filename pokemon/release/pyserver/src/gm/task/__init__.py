#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2014 YouMi Information Technology Inc.
'''

from framework.log import logger

from tornado.gen import coroutine
from tornado.web import HTTPError

import time


class RPCTaskFactory(object):
	def __init__(self, serv):
		self._server = serv

	@property
	def dbcGM(self):
		return self._server.dbcGM

	@property
	def dbcGift(self):
		return self._server.dbcGift

	@property
	def dbcAccount(self):
		return self._server.dbcAccount

	@property
	def gameRPCs(self):
		return self._server.gameRPCs

	@property
	def gameShenheRPCs(self):
		return self._server.gameShenheRPCs

	@property
	def gameAllRPCs(self):
		RPCs = {}
		RPCs.update(self.gameRPCs)
		RPCs.update(self.gameShenheRPCs)
		return RPCs

	@property
	def server(self):
		return self._server


class GMTaskReturn(object):

	def __init__(self, msg, **kwargs):
		self.msg = msg
		self.kwargs = kwargs

	def to_msgpack(self):
		return (True, self.msg, self.kwargs)


class GMTaskError(Exception):
	pass


def gmrpc_coroutine(fn):
	def _wrap(self, *args, **kwargs):
		session = kwargs.pop('_session', None)
		if session is None:
			session = args[0]
			args = args[1:]

		ok = self.server.verifyPermission(session, fn.__name__)
		if ok != 'ok':
			raise HTTPError(504, "Sorry, You don't have enough permissions")

		logger.info('`%s` %s %s' % (session.name, fn.__name__, str(args)))
		return coroutine(fn)(self, *args, **kwargs)
	return _wrap


def gmrpc_log_coroutine(fn):
	def _wrap(self, *args, **kwargs):
		session = kwargs.pop('_session', None)
		if session is None:
			session = args[0]
			args = args[1:]

		ok = self.server.verifyPermission(session, fn.__name__)
		if ok != 'ok':
			raise HTTPError(504, "Sorry, You don't have enough permissions")

		logger.info('`%s` %s %s' % (session.name, fn.__name__, str(args)))
		# self.dbcGM.call_async('GMOpHistory', name, (fn.__name__, str(arg), time.time()))
		return coroutine(fn)(self, *args, **kwargs)
	return _wrap