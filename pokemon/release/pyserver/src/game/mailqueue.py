#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2014 YouMi Information Technology Inc.

Mail Queue
'''

from framework.dbqueue import TimerJoinableQueue

from game.object.game.gain import ObjectGainAux
from game.handler.inl_mail import sendMail

from tornado.gen import coroutine, moment
from tornado.ioloop import PeriodicCallback
from tornado.concurrent import Future


#
# MailJoinableQueue
#

class MailJoinableQueue(TimerJoinableQueue):
	MailFlushTimerSecs = 1
	Singleton = None
	GameLoading = 0
	SendingFuture = None

	def __init__(self, dbc, getOnlineByRoleID):
		TimerJoinableQueue.__init__(self, self.MailFlushTimerSecs)
		self._dbc = dbc
		self._getOnlineByRoleID = getOnlineByRoleID

		if MailJoinableQueue.Singleton is not None:
			raise ValueError('This is singleton object')
		MailJoinableQueue.Singleton = self

	def join(self, closed=True):
		print 'MailJoinableQueue joining', self.qsize()
		return TimerJoinableQueue.join(self, closed)

	@coroutine
	def _process_item(self, item):
		PeriodicCallback.stop(self)
		# 暂停mailqueue，防止脏数据
		# 保证单次进入
		while not self._closed and (MailJoinableQueue.GameLoading > 0 or MailJoinableQueue.SendingFuture is not None):
			yield moment

		MailJoinableQueue.SendingFuture = Future()
		try:
			mail, history = item
			game, safeGuard = self._getOnlineByRoleID(mail['role_db_id'])
			with safeGuard:
				yield sendMail(mail, self._dbc, game)
		except:
			raise
		finally:
			if MailJoinableQueue.SendingFuture:
				MailJoinableQueue.SendingFuture.set_result(None)
				MailJoinableQueue.SendingFuture = None
			PeriodicCallback.start(self)

	@classmethod
	def send(cls, mail):
		cls.Singleton.put((mail, None))

	@classmethod
	def beginGameLoading(cls):
		cls.GameLoading += 1
		if cls.SendingFuture:
			return cls.SendingFuture
		return moment

	@classmethod
	def endGameLoading(cls):
		cls.GameLoading -= 1


#
# ObjectMailEffect
#

class ObjectMailEffect(object):
	'''
	发送邮件奖励
	'''

	def __init__(self, mail, cb=None):
		self._mail = mail
		self._cb = cb

	def gain(self, **kwargs):
		MailJoinableQueue.Singleton.put((self._mail, None))
		if self._cb:
			self._cb()
