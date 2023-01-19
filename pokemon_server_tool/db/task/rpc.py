#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2014 YouMi Information Technology Inc.
'''

from db.task import RPCTaskFactory
from db.task.account import TAccountFactory
from db.task.game import TGameFactory
from db.task.role import TRoleFactory
from db.task.order import TOrderFactory
from db.task.gift import TGiftFactory
from db.task.test import TTestFactory


class DBRPC(object):

	@property
	def redis(self):
		return self._server.redis

	def __init__(self, containServ):
		self._server = containServ
		self._account = TAccountFactory(self)
		self._game = TGameFactory(self)
		self._role = TRoleFactory(self)
		self._order = TOrderFactory(self)
		self._gift = TGiftFactory(self)
		self._test = TTestFactory(self)

		self.factory = []
		for k, v in self.__dict__.items():
			if isinstance(v, RPCTaskFactory):
				self.factory.append((type(v), v))

	def __getattr__(self, name):
		for cls, obj in self.factory:
			if name in cls.__dict__:
				return getattr(obj, name)
		return None


