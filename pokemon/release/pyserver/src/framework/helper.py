#!/usr/bin/python
# -*- coding: utf-8 -*-

from __future__ import absolute_import

from framework import name

import os
import sys
import time
import copy
import heapq
import random
import binascii
import traceback
from datetime import datetime, date
from collections import defaultdict

# a = {1:1,'22':22, 'xxx':3}
# print copyKV(a)
# print copyKV(a, dest={1:111,'aaa':'aaa'})
# print copyKV(a, dest={1:111,'aaa':'aaa'}, all=True)
# print copyKV(a, dest={1:111,'aaa':'aaa'}, keys=[3,'22'])
# print copyKV(a, dest={1:111,'aaa':'aaa'}, keys={3:33,'22':'yy22'})
# print copyKV(a, dest={1:111,'aaa':'aaa'}, keys={3:33,'22':'yy22'}, all=True)
# print copyKV(a, dest={1:111,'aaa':'aaa'}, keys={3:33,'22':'yy22'}, all=True, default={33:'xxx333',1:999})

def copyKV(srcD, **kwargs):
	dstD = kwargs.get('dest', {})
	defs = kwargs.get('default', {})
	copyAll = kwargs.get('all', False)
	keys = kwargs.get('keys', [])
	msgpack = kwargs.get('msgpack', False)

	# no keys = copy all
	if len(keys) == 0:
		keys = srcD.keys()

	# key rename
	keyRename = False
	if isinstance(keys, dict):
		keyRename = True
		if copyAll:
			# copy all
			tmp = {k: k for k in srcD.keys()}
			tmp.update(keys)
			keys = tmp

	# copy k-v
	for i in keys:
		x = keys[i] if keyRename else i
		if (x is None) or (i not in srcD) or (x in dstD):
			continue
		dstD[x] = srcD[i]

	# fill default
	for i in defs:
		if i not in dstD:
			dstD[i] = defs[i]

	# toMsgpackDict
	if msgpack:
		dstD = toMsgpackDict(dstD)

	return dstD

def addDict(d1, d2):
	ret = dict(d1)
	for k, v in d2.iteritems():
		if isinstance(v, dict):
			vv = addDict(v, ret.get(k, {}))
			ret[k] = vv
		elif isinstance(v, tuple):
			ret[k] = v + ret.get(k, ())
		elif isinstance(v, list):
			ret[k] = v + ret.get(k, [])
		else:
			ret[k] = v + ret.get(k, 0)
	return ret

def listCountDict(l):
	ret = {}
	for x in l:
		ret[x] = ret.get(x, 0) + 1
	return ret

# d1 - d2
def subDict(d1, d2):
	ret = dict(d1)
	for k, v in d2.iteritems():
		if isinstance(v, dict):
			vv = subDict(ret.get(k, {}), v)
			ret[k] = vv
		elif isinstance(v, (tuple, list)):
			vv = subDict(ret.get(k, {}), listCountDict(v))
			vv = [[k]*v for k, v in vv.iteritems() if v > 0]
			vv = reduce(lambda x,y: x+y, vv)
			ret[k] = vv
		else:
			vv = ret.get(k, 0) - v
			ret[k] = vv
	return ret

def clampDict(d, dmax, dmin=defaultdict(int), ddel=False):
	kdel = []
	for k, v in d.iteritems():
		if k not in dmax:
			kdel.append(k)
		else:
			if isinstance(v, dict):
				d[k] = clampDict(d[k], dmax, dmin, ddel)
			else:
				d[k] = max(min(v, dmax[k]), dmin[k])
	if ddel:
		for k in kdel:
			d.pop(k)
	return d

def toMsgpackDict(d):
	for k, v in d.items():
		if isinstance(v, datetime):
			d[k] = time.mktime(v.timetuple())
	return d

uni2utf = lambda s: s.encode('utf8')
def _decode_list(data):
	rv = []
	for item in data:
		if isinstance(item, unicode):
			item = uni2utf(item)
		elif isinstance(item, list):
			item = _decode_list(item)
		elif isinstance(item, dict):
			item = _decode_dict(item)
		rv.append(item)
	return rv

def _decode_dict(data):
	rv = {}
	for key, value in data.iteritems():
		if isinstance(key, unicode):
			key = uni2utf(key)
		if isinstance(value, unicode):
			value = uni2utf(value)
		elif isinstance(value, list):
			value = _decode_list(value)
		elif isinstance(value, dict):
			value = _decode_dict(value)
		rv[key] = value
	return rv

def toUTF8Dict(d):
	return _decode_dict(d)

def isToday(tm):
	return date.fromtimestamp(tm) == date.today()

def fileLineFuncT(deep=1):
	frame = sys._getframe(deep)
	# print frame.f_code.co_filename  #当前文件名，可以通过__file__获得
	# print frame.f_code.co_name  #当前函数名
	# print frame.f_lineno #当前行号
	return (os.path.basename(frame.f_code.co_filename), frame.f_lineno, frame.f_code.co_name)

def fileLineFuncS(deep=1):
	frame = sys._getframe(deep)
	# print frame.f_code.co_filename  #当前文件名，可以通过__file__获得
	# print frame.f_code.co_name  #当前函数名
	# print frame.f_lineno #当前行号
	return "%s(%d) %s: " % (os.path.basename(frame.f_code.co_filename), frame.f_lineno, frame.f_code.co_name)

def reseedRandom():
	random.seed(getRandomSeed())

def getRandomSeed():
	# If os.urandom is available, this method does the same thing as
	# random.seed (at least as of python 2.6).  If os.urandom is not
	# available, we mix in the pid in addition to a timestamp.
	try:
		seed = long(binascii.hexlify(os.urandom(16)), 16)
	except NotImplementedError:
		seed = int(time.time() * 1000) ^ os.getpid()
	return seed

def lowerBound(lst, target, key=lambda x: x):
	low = 0
	high = len(lst) - 1
	while low <= high:
		mid = (low + high) >> 1
		midv = key(lst[mid])
		if midv < target:
			low = mid + 1
		elif midv > target:
			high = mid - 1
		else:
			return mid
	return low - 1

def upperBound(lst, target, key=lambda x: x):
	low = 0
	high = len(lst) - 1
	while low <= high:
		mid = (low + high) >> 1
		midv = key(lst[mid])
		if midv < target:
			low = mid + 1
		elif midv > target:
			high = mid - 1
		else:
			return mid
	return low


class WeightRandomObject(object):
	'''
	带权重的随机库
	支持 [(id, weight), ...]
	支持 {id : weight, ...}
	'''

	def __init__(self, weights, wgetter=lambda t: t[1]):
		self.weights = weights
		self.wgetter = wgetter
		self.weightSum = 0

		if isinstance(weights, list) or isinstance(weights, tuple):
			for x in weights:
				self.weightSum += wgetter(x)
		elif isinstance(weights, dict):
			for x in weights.iteritems():
				self.weightSum += wgetter(x)

		if self.weightSum == 0:
			raise ValueError()

	def getRandom(self):
		rnd = random.randint(1, self.weightSum)
		if isinstance(self.weights, list) or isinstance(self.weights, tuple):
			for x in self.weights:
				rnd -= self.wgetter(x)
				if rnd <= 0:
					return x
		elif isinstance(self.weights, dict):
			for x in self.weights.iteritems():
				rnd -= self.wgetter(x)
				if rnd <= 0:
					return x
		raise ValueError()

	@classmethod
	def onceRandom(cls, weights, wgetter=lambda t: t[1]):
		'''
		适用于一次性随机，没有缓存优化的场景
		'''
		weightSum = 0
		if isinstance(weights, list) or isinstance(weights, tuple):
			for x in weights:
				weightSum += wgetter(x)
		elif isinstance(weights, dict):
			for x in weights.iteritems():
				weightSum += wgetter(x)

		if weightSum == 0:
			raise ValueError()

		rnd = random.randint(1, weightSum)
		if isinstance(weights, list) or isinstance(weights, tuple):
			for x in weights:
				rnd -= wgetter(x)
				if rnd <= 0:
					return x
		elif isinstance(weights, dict):
			for x in weights.iteritems():
				rnd -= wgetter(x)
				if rnd <= 0:
					return x
		raise ValueError()

	@classmethod
	def onceSample(cls, weights, num, wgetter=lambda t: t[1]):
		if num >= len(weights):
			return weights

		weightSum = 0
		if isinstance(weights, list) or isinstance(weights, tuple):
			for x in weights:
				weightSum += wgetter(x)
			weights = list(weights)
		elif isinstance(weights, dict):
			for x in weights.iteritems():
				weightSum += wgetter(x)
			weights = dict(weights)

		if weightSum == 0:
			raise ValueError()

		ret = []
		for i in xrange(num):
			rnd = random.randint(1, weightSum)
			if isinstance(weights, list):
				for idx, x in enumerate(weights):
					rnd -= wgetter(x)
					if rnd <= 0:
						ret.append(x)
						weightSum -= wgetter(x)
						del weights[idx]
						break
			elif isinstance(weights, dict):
				for x in weights.iteritems():
					rnd -= wgetter(x)
					if rnd <= 0:
						ret.append(x)
						weightSum -= wgetter(x)
						del weights[x[0]]
						break
		return ret


def randomName():
	import framework
	if framework.__language__ == 'tw':
		return random.choice(name.twNamePrefixs) + random.choice(name.twNames)
	return random.choice(name.namePrefixs) + random.choice(name.names)

def randomRobotName():
	import framework
	if framework.__language__ == 'tw':
		return random.choice(name.twRobotPrefixs) + random.choice(name.twRobotNames)
	return random.choice(name.robotPrefixs) + random.choice(name.robotNames)

def getL10nCsvValue(csv, field):
	import framework
	raw = getattr(csv, field)
	if framework.__language__ != 'cn':
		field = '%s_%s' % (field, framework.__language__)
		return getattr(csv, field, raw)
	return raw

def getModelValue(d, k):
	if isinstance(d, dict):
		return d[k]
	if hasattr(d, k):
		# d may be ObjectBase
		return copy.deepcopy(getattr(d, k))

def model2NamedTuple(d, tCls, **kwargs):
	def _get(d, k):
		if isinstance(d, dict):
			if k in d:
				return d[k]
			return kwargs[k]
		if hasattr(d, k):
			# d may be ObjectBase
			return copy.deepcopy(getattr(d, k))
		return kwargs[k]

	l = [_get(d, k) for k in tCls._fields]
	return tCls(*l)

def timeSubTime(t1, t2):
	d = datetime.now().date()
	t1 = datetime.combine(d, t1)
	t2 = datetime.combine(d, t2)
	return t1 - t2

def transform2list(d, least=6):
	if isinstance(d, dict):
		return [d.get(i, None) for i in xrange(1, least+1)]
	else:
		if len(d) < least:
			d += [None for _ in xrange(least-len(d))]
		return d

def objectid2string(id):
	return binascii.hexlify(id)

def string2objectid(s):
	return binascii.unhexlify(s)

'''
Written January 4, 2012 by Josiah Carlson
Released into the public domain.

I've only ever needed this once, but I had to learn the descriptor protocol.
Works just like a property, except that what you decorate gets the class
instead of the instance.

class Example(object):
	@ClassProperty
	def foo(cls):
		return cls._foo

	@foo.setter
	def foo(cls, value):
		cls._foo = value

	@foo.deleter
	def foo(cls):
		del cls._foo

'''

class ClassProperty(object):
	def __init__(self, fget, fset=None, fdel=None):
		self.get = fget
		self.set = fset
		self.delete = fdel

	def __get__(self, obj, cls=None):
		if cls is None:
			cls = type(obj)
		return self.get(cls)

	def __set__(self, obj, value):
		cls = type(obj)
		self.set(cls, value)

	def __delete__(self, obj):
		cls = type(obj)
		self.delete(cls)

	def getter(self, get):
		return ClassProperty(get, self.set, self.delete)

	def setter(self, set):
		return ClassProperty(self.get, set, self.delete)

	def deleter(self, delete):
		return ClassProperty(self.get, self.set, delete)


class SimplePriorityQueue(object):
	'''Variant of Queue that retrieves open entries in priority order (lowest first).

	Entries are typically tuples of the form:  (priority number, data).
	'''

	def __init__(self, l):
		self.queue = l if l is not None else []
		heapq.heapify(self.queue)

	def qsize(self, len=len):
		return len(self.queue)

	def put(self, item, heappush=heapq.heappush):
		heappush(self.queue, item)

	def get(self, heappop=heapq.heappop):
		return heappop(self.queue)

	def smallest(self):
		if self.queue:
			return self.queue[0]
		return None

	def __len__(self, len=len):
		return len(self.queue)


class ExceptionGuard(object):
	def __init__(self, suppress=True):
		self.suppress = suppress

	def __enter__(self):
		return self

	def __exit__(self, type, value, tb):
		if self.suppress and value:
			from framework.log import logger
			logger.exception('Caught By ExceptionGuard\n' + ''.join(traceback.format_stack(tb.tb_frame)), exc_info=(type, value, tb))
		return self.suppress
