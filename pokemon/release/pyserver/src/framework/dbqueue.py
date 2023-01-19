#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2014 YouMi Information Technology Inc.

DB LRU Queue
'''

from framework import nowtime_t
from framework.lru import LRUCache
from framework.log import logger
from tornado.gen import coroutine, moment
from tornado.ioloop import PeriodicCallback
from toro import JoinableQueue


class TimerJoinableQueue(JoinableQueue, PeriodicCallback):
	def __init__(self, flushSecs):
		PeriodicCallback.__init__(self, self._process, flushSecs * 1000)
		JoinableQueue.__init__(self)
		self._preGet = None
		self._joined = False
		self._closed = False
		self._flushSecs = flushSecs

	def _item_wrap(self, item):
		return (item, nowtime_t())

	def _put_done(self, fu, item):
		return

	def put(self, item, deadline=None):
		ret = JoinableQueue.put(self, self._item_wrap(item), deadline)
		ret.add_done_callback(lambda fu: self._put_done(fu, item))
		return ret

	def _get_done(self, fu):
		return

	def get(self, deadline=None):
		ret = JoinableQueue.get(self, deadline)
		ret.add_done_callback(self._get_done)
		return ret

	def join(self, closed=True):
		self._joined = True
		self._closed = closed
		return self._process()

	def qsize(self):
		return (1 if self._preGet else 0) + JoinableQueue.qsize(self)

	@coroutine
	def _process_item(self, item):
		pass

	@coroutine
	def _on_closed(self):
		pass

	@coroutine
	def _process(self):
		nowTM = nowtime_t()

		try:
			while self.qsize() > 0:
				if not self._preGet:
					self._preGet = yield self.get()
				item, tm = self._preGet
				if not self._joined and nowTM - tm < self._flushSecs:
					break
				self._preGet = None

				yield self._process_item(item)
				del item
				yield moment

		except:
			logger.exception('%s Exception queuing %d' % (type(self), self.qsize()))

		finally:
			if self._closed:
				yield self._on_closed()


class DBJoinableQueue(TimerJoinableQueue):
	# TODO: It doesn't matter whether DB Object is hot
	# When the timer arrives, it may cause the large object to refresh more performance consumption
	DBFlushTimerSecs = 10
	Singleton = None

	def __init__(self):
		TimerJoinableQueue.__init__(self, self.DBFlushTimerSecs)
		self._lru = LRUCache()
		self._dbcGame = None
		self._flushOK = False

		if DBJoinableQueue.Singleton is not None:
			raise ValueError('This is singleton object')
		DBJoinableQueue.Singleton = self

	def _item_wrap(self, item):
		return id(item)

	def _put_done(self, _, item):
		self._lru.set(id(item), TimerJoinableQueue._item_wrap(self, item))

	def put(self, item, deadline=None):
		if id(item) in self._lru:
			# 保持queue和lru大小一致，否则queue会无限变长导致内存泄露
			self._put_done(None, item)
			ret = moment
		else:
			ret = JoinableQueue.put(self, self._item_wrap(item), deadline)
			ret.add_done_callback(lambda fu: self._put_done(None, item))
		return ret

	def _get_done(self, fu):
		fu._result = self._lru.pop()

	def join(self, closed=True):
		print 'DBJoinableQueue joining', self.qsize()
		return TimerJoinableQueue.join(self, closed)

	def qsize(self):
		return (1 if self._preGet else 0) + self._lru.size()

	@coroutine
	def _process_item(self, item):
		dbObj = item
		try:
			ret = yield dbObj.save_async()
			if not ret['ret']:
				logger.warning('DBJoinableQueue process err %s', str(ret))
			if not self._dbcGame:
				self._dbcGame = getattr(dbObj, '_dbc', None)
		except Exception as e:
			dbObj.restoreLastDBSyncKeys()
			logger.warning('%s %s process error, keys %s', dbObj.DBModel, dbObj.pid, dbObj.lastDBSyncKeys)
			raise e


	@coroutine
	def _on_closed(self):
		if self._dbcGame and not self._flushOK:
			yield self._dbcGame.call_async('DBCommit', True, True)
			self._flushOK = True
