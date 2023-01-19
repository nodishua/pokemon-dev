#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2014 YouMi Information Technology Inc.

Here Classes and Functions are use for logic.
'''

from wnet import WANetTask
from net import LANetTask

from tornado.gen import coroutine, Return

class LogicTask(object):

	def __init__(self, nett, session = None):
		if self.cmd != nett.cmd:
			raise TypeError('Net cmd %d miss match Logic cmd %d!' % (nett.cmd, self.cmd))
		self.ntask = nett
		self.session = session

	@property
	def data(self):
		return self.ntask.data

	@property
	def server(self):
		return self.session.server

	@property
	def dbcAccount(self):
		return self.session.server.dbcAccount

	@property
	def whiteList(self):
		return self.session.server.whiteList

	@property
	def logger(self):
		return self.ntask.conn.logger

	@property
	def address(self):
		return self.ntask.conn.address

	@coroutine
	def run(self):
		raise NotImplementedError()

	# @param 	fRun	the function to decorate
	#					must return Ack Class and Data
	@classmethod
	def wrapToLANetAck(cls, fRun):
		'''
		local internal network ack packet
		'''
		@coroutine
		def _run(self, *args, **kwargs):
			co = coroutine(fRun)
			ret = yield co(self, *args, **kwargs)
			if ret is None:
				raise Return(None)
			cls, data = ret
			raise Return(LANetTask(self.ntask.conn, cls.cmd, data, self.ntask.synID))
		return _run

	# @param 	fRun	the function to decorate
	#					must return Ack Class and Data
	@classmethod
	def wrapToWANetAck(cls, fRun):
		'''
		remote extenal network ack packet
		'''
		@coroutine
		def _run(self, *args, **kwargs):
			co = coroutine(fRun)
			ret = yield co(self, *args, **kwargs)
			if ret is None:
				raise Return(None)
			cls, data = ret
			raise Return(WANetTask(self.ntask.conn, cls.cmd, data, self.ntask.synID, self.session.aesPwd if self.session else None))
		return _run

	def makeWANetAck(self, ackCls, ackData, aesPwd):
		return WANetTask(self.ntask.conn, ackCls.cmd, ackData, self.ntask.synID, aesPwd)


