# -*- coding: utf-8 -*-

import sys
import datetime
import collections

import tornado.ioloop


class Cache(object):

	def __init__(self, dic, ioloop=None):
		self.ioloop = ioloop or tornado.ioloop.current()
		self._dic = dic

	def get(self, key, default=None):
		return self._dic.get(key, default)

	def set(self, key, value):
		self._dic[key] = value

	def clear(self):
		for k in self._dic:
			if isinstance(self._dic[k], set):
				self._dic[k] = set([])
			elif isinstance(self._dic[k], int):
				self._dic[k] = 0
			elif isinstance(self._dic[k], list):
				self._dic[k] = []
			else:
				self._dic[k] = ''

	def start(self, hour=0):
		timerHour = datetime.time(hour=hour)
		dtNow = datetime.datetime.now()
		dtNext = datetime.datetime.combine(dtNow.date(), timerHour)
		if dtNow.time() > timerHour:
			dtNext += datetime.timedelta(days=1)

		self.timer = tornado.ioloop.PeriodicCallback(self.clear, 24*3600*1000, io_loop=self.ioloop)
		self.startAndTimer(dtNext, self.timer)

	def startAndTimer(self, dtNext, timer):
		def _run(timer):
			timer.start()
			return timer.callback()

		self.ioloop.add_timeout(dtNext - datetime.datetime.now(), _run, timer)

	def stop(self):
		self.timer.stop()


class SimpleLRUCache(object):
	def __init__(self, capacity=sys.maxint):
		self.capacity = capacity
		self.cache = collections.OrderedDict()

	def get(self, key):
		try:
			value = self.cache.pop(key)
			self.cache[key] = value
			return value
		except KeyError:
			return None

	def set(self, key, value):
		ret = None
		try:
			self.cache.pop(key)
		except KeyError:
			if len(self.cache) >= self.capacity:
				ret = self.cache.popitem(last=False)
		self.cache[key] = value
		return ret

	def size(self):
		return len(self.cache)

	def __len__(self):
		return len(self.cache)

	def __contains__(self, item):
		return item in self.cache

	def __iter__(self):
		return self.cache.__iter__()

	def iteritems(self):
		return self.cache.iteritems()

	def iterkeys(self):
		return self.cache.iterkeys()

	def itervalues(self):
		return self.cache.itervalues()

	def full(self):
		return self.capacity <= len(self.cache)

	def clear(self):
		self.cache.clear()