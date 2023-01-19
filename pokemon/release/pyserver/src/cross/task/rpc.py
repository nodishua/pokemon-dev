#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2014 YouMi Information Technology Inc.
Copyright (c) 2016 TianJi Information Technology Inc.
'''

from cross.task import RPCTaskFactory
from cross.task.console import TConsoleFactory
from cross.task.craft import TCraftFactory


class CrossRPC(object):
	def __init__(self, containServ):
		self._server = containServ
		self._console = TConsoleFactory(self._server)
		self._craft = TCraftFactory(self._server)

		self.factory = []
		for k, v in self.__dict__.items():
			if isinstance(v, RPCTaskFactory):
				self.factory.append((type(v), v))

	def __getattr__(self, name):
		for cls, obj in self.factory:
			if name in cls.__dict__:
				return getattr(obj, name)
		return None


