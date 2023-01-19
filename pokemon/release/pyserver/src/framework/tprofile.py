#!/usr/bin/python
# -*- coding: utf-8 -*-

import os
import time

class TimeProfile(object):
	def __init__(self):
		self.d = {}

	def record(self, obj, mark):
		from tornado.iostream import BaseIOStream
		from framework.net import NetConn

		if isinstance(obj, BaseIOStream):
			pass
		elif isinstance(obj, NetConn):
			obj = obj.stream

		if obj not in self.d:
			self.d[obj] = {}
		self.d[obj][mark] = time.time()


prof = TimeProfile()
		