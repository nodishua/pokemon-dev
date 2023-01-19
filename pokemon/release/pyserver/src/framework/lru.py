#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2014 YouMi Information Technology Inc.
'''


'''
Least Recently Used cache

'''
import sys
import collections


class LRUCache(object):
	def __init__(self, capacity=sys.maxint):
		self.capacity = capacity
		self.cache = collections.OrderedDict()

	def getByKey(self, key):
		try:
			value = self.cache.pop(key)
			self.cache[key] = value
			return value
		except KeyError:
			return None

	def getValue(self, key):
		return self.cache.get(key, None)

	def set(self, key, value):
		'''
		返回值: 被pop的LRU item
		'''
		ret = None
		try:
			self.cache.pop(key)
		except KeyError:
			if len(self.cache) >= self.capacity:
				ret = self.cache.popitem(last=False)
		self.cache[key] = value
		return ret

	def pop(self):
		'''
		返回值: value
		'''
		if len(self.cache) == 0:
			return None
		return self.cache.popitem(last=False)[1]

	def popByKey(self, key):
		'''
		返回值: LRU item
		'''
		return self.cache.pop(key, None)

	def reCapacity(self, capacity):
		popn = len(self.cache) - capacity
		ret = []
		while popn > 0:
			popn -= 1
			ret.append(self.cache.popitem(last=False))
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



if __name__ == '__main__':
	a = LRUCache(2)
	print a.set(1, 1)
	print a.set(2, 2)
	print a.set(3, 3)
	print a.set(2, 22)
	print list(a)
	print set(a)
	print a.cache
	a.cache.get(3)
	print a.cache