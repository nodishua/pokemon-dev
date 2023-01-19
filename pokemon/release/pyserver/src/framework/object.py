#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2014 YouMi Information Technology Inc.

Game Object Base
'''

from __future__ import absolute_import

from framework.csv import Csv, csv
from framework.log import logger
from framework.helper import lowerBound
from framework.dbqueue import DBJoinableQueue
from framework.service.rpc_client import Client

from tornado.concurrent import Future, chain_future

import time
import copy
import types
import functools
import itertools
import binascii
from weakref import WeakValueDictionary, WeakKeyDictionary
from collections import defaultdict

okfu = Future()
okfu.set_result({'ret': True})


def db_property(dbkey, fget=None, fset=None, fdel=None, doc=None):
	def _fget(self):
		return self._db[dbkey]
	def _fset(self, value):
		self._db[dbkey] = value
	if fdel:
		raise AttributeError('can not del db property')
	return property(fget if fget else _fget, fset if fset else _fset, None, doc)


# read only
def db_ro_property(dbkey, fget=None, doc=None):
	def _fget(self):
		return self._db[dbkey]
	return property(fget if fget else _fget, None, None, doc)


def dict_sync(base, head):
	if id(base) == id(head):
		return {}, {}, {}
	newD, updD, delD = {}, {}, {}
	for k, v in head.iteritems():
		if k in base:
			vb = base[k]
			if isinstance(v, dict):
				_newD, _updD, _delD = dict_sync(vb, v)
				if _newD:
					newD[k] = _newD
				if _updD:
					updD[k] = _updD
				if _delD:
					delD[k] = _delD
			elif v != vb:
				if v is None:
					# None对Lua而言就是nil
					delD[k] = False
				else:
					updD[k] = v
					if isinstance(v, (list, tuple)):
						newD[k] = True
		else:
			updD[k] = v
			newD[k] = True
	for k, v in base.iteritems():
		if k not in head:
			delD[k] = False
	return newD, updD, delD


#
# GCObject
#

class GCObject(object):
	# list, dict is unhashable, because it immutable
	GCObjMap = defaultdict(WeakValueDictionary) # {type: {id: obj}}

	def __init__(self):
		self.GCObjMap[str(type(self))][id(self)] = self

	def is_gc_destroy(self):
		return hasattr(self, '_destroy')

	def gc_destroy(self):
		if hasattr(self, '_destroy'):
			return
		items = self.__dict__.items()
		self._destroy = True
		self._gc_destroy(items)

		import framework
		if hasattr(framework, '__trace_object__'):
			import tornado.ioloop
			import random, datetime, objgraph, gc
			# if random.randint(0, 1) == 0:
			# 	return
			stype = str(type(self))
			idd = id(self)
			shortname = type(self).__name__ + str(id(self))
			print '_ref_print', shortname, 'after timedelta'
			def _ref_print():
				gc.collect()
				if idd not in GCObject.GCObjMap[stype]:
					print 'gc over', shortname
					return
				print '_ref_print', shortname
				o = GCObject.GCObjMap[stype][idd]
				objgraph.show_backrefs(o, filename='%s.png' % shortname, max_depth=10, refcounts=True)
			ioloop = tornado.ioloop.IOLoop.current()
			ioloop.add_timeout(datetime.timedelta(seconds=10), _ref_print)

	def _gc_destroy(self, items):
		for k, v in items:
			if isinstance(v, GCObject):
				v.gc_destroy()
			delattr(self, k)

	@staticmethod
	def other_gc_destroy(vals):
		for v in vals:
			if isinstance(v, GCObject):
				v.gc_destroy()

	@classmethod
	def objs_count_stat(cls):
		lst = ['%s: %d' % (k, len(v)) for k, v in cls.GCObjMap.iteritems() if v]
		# lst = ['%s: %d, gc %d' % (k, len(v), reduce(lambda s, o: s + 1 if o() and o().is_gc_destroy() else s, v.itervaluerefs(), 0)) for k, v in cls.GCObjMap.iteritems() if v]
		return '\n'.join(lst)

	@classmethod
	def objs_show_backrefs(cls):
		import objgraph
		for k, v in cls.GCObjMap.iteritems():
			if v:
				o = v.values()[0]
				shortname = type(o).__name__
				objgraph.show_backrefs(o, filename='%s.png' % shortname, max_depth=5, refcounts=True)

#
# GCWeakValueDictionary
#

class GCWeakValueDictionary(WeakValueDictionary):
	'''
	只为去除gc_destroy后的对象
	存在已经GC了，但是DBQueue还有引用，等DBQueue处理完，weakref就能正常释放
	只能用于GCObject
	'''

	def __setitem__(self, key, value):
		if not isinstance(value, GCObject):
			raise TypeError
		WeakValueDictionary.__setitem__(self, key, value)

	def __getitem__(self, key):
		obj = WeakValueDictionary.__getitem__(self, key)
		if obj.is_gc_destroy():
			raise KeyError, key
		else:
			return obj

	def __contains__(self, key):
		try:
			self.__getitem__(key)
		except KeyError:
			return False
		return True

	def has_key(self, key):
		return self.__contains__(key)

	def get(self, key, default=None):
		try:
			return self.__getitem__(key)
		except KeyError:
			return default

	def iteritems(self):
		for k, obj in WeakValueDictionary.iteritems(self):
			if not obj.is_gc_destroy():
				yield k, obj

	def itervaluerefs(self):
		for wr in WeakValueDictionary.itervaluerefs(self):
			obj = wr()
			if obj and not obj.is_gc_destroy():
				yield wr

	def itervalues(self):
		for obj in WeakValueDictionary.itervalues(self):
			if not obj.is_gc_destroy():
				yield obj

	def items(self):
		return list(self.iteritems())

	def valuerefs(self):
		return list(self.itervaluerefs())

	def values(self):
		return list(self.itervalues())


#
# GCWeakKeyDictionary
#

class GCWeakKeyDictionary(WeakKeyDictionary):
	'''
	只为去除gc_destroy后的对象
	存在已经GC了，但是DBQueue还有引用，等DBQueue处理完，weakref就能正常释放
	只能用于GCObject
	'''

	def __setitem__(self, key, value):
		if not isinstance(key, GCObject):
			raise TypeError
		WeakKeyDictionary.__setitem__(self, key, value)

	def __getitem__(self, key):
		if key and key.is_gc_destroy():
			raise KeyError, key
		return WeakKeyDictionary.__getitem__(self, key)

	def __contains__(self, key):
		if key and key.is_gc_destroy():
			return False
		return WeakKeyDictionary.__contains__(self, key)

	def has_key(self, key):
		return self.__contains__(key)

	def get(self, key, default=None):
		if key and key.is_gc_destroy():
			return default
		return WeakKeyDictionary.get(self, key, default)

	def iteritems(self):
		for obj, v in WeakKeyDictionary.iteritems(self):
			if not obj.is_gc_destroy():
				yield obj, v

	def iterkeyrefs(self):
		for wr in WeakKeyDictionary.iterkeyrefs(self):
			obj = wr()
			if obj and not obj.is_gc_destroy():
				yield wr

	def iterkeys(self):
		for obj in WeakKeyDictionary.iterkeys(self):
			if not obj.is_gc_destroy():
				yield obj

	def items(self):
		return list(self.iteritems())

	def keyrefs(self):
		return list(self.iterkeyrefs())

	def keys(self):
		return list(self.iterkeys())


#
# DataWatcherBase
#

class DataWatcherBase(GCObject):
	def __init__(self):
		self._dirtList = []
		self._discardList = []
		GCObject.__init__(self)

	def isModify(self):
		return False

	def syncEnd(self):
		return

	def _dfsSync(self, delDeep, ignores):
		return None, None, None

	def _onDiscard(self, dirt):
		# 整理dirtList，主要针对ObjectNoGCDBase
		if dirt:
			self._discardList.append(dirt)
			n = len(self._discardList)
			if n > 1024 and n > len(self._dirtList) / 2:
				discardL = self._discardList
				self._discardList = []
				discardS = {id(x) for x in discardL}

				# 延迟处理
				if hasattr(self, '_dirtKO'):
					discardS -= {id(x) for x in self._dirtKO.itervalues()}
					newDiscardL, leftL = [], []
					for x in discardL:
						if id(x) in discardS:
							newDiscardL.append(x)
						else:
							leftL.append(x)
					discardL = newDiscardL
					self._discardList = leftL

				GCObject.other_gc_destroy(discardL)
				self._dirtList = [x for x in self._dirtList if id(x) not in discardS]

def assertNotWatcher(v, deep):
	if isinstance(v, DataWatcherBase):
		raise ValueError('Watcher can not be contain')
	if isinstance(v, dict):
		for _, vv in v.iteritems():
			assertNotWatcher(vv, deep+1)
	elif isinstance(v, list):
		for vv in v:
			assertNotWatcher(vv, deep+1)

#
# ListWatcher
#

class ListWatcher(list, DataWatcherBase):
	'''
	只处理一维简单列表
	不记录更新删除，所有变动作为更新传给上层
	'''

	def __init__(self, l, upd):
		list.__init__(self, l)
		DataWatcherBase.__init__(self)
		self._upd = upd

	#
	# override list functions
	#
	def __setitem__(self, key, value):
		self._del(key)
		list.__setitem__(self, key, value)

	def __setslice__(self, i, j, sequence):
		n = len(self)
		ii, jj = (i%n + n) % n, (j%n + n) % n
		for k in xrange(ii, jj):
			self._del(k)
		list.__setslice__(self, i, j, sequence)

	def __getitem__(self, key):
		ret = list.__getitem__(self, key)
		if isinstance(ret, DataWatcherBase):
			return ret
		# TODO: 多game引用同一个object会有问题，各自改各自副本
		elif isinstance(ret, dict):
			dirt = self._newDDirt(key, ret)
			list.__setitem__(self, key, dirt)
			return dirt
		elif isinstance(ret, list):
			dirt = self._newLDirt(key, ret)
			list.__setitem__(self, key, dirt)
			return dirt
		return ret

	def __delitem__(self, key):
		self._del(key)
		list.__delitem__(self, key)

	def __delslice__(self, i, j):
		n = len(self)
		ii, jj = (i%n + n) % n, (j%n + n) % n
		for k in xrange(ii, jj):
			self._del(k)
		list.__delslice__(self, i, j)

	def __iadd__(self, other):
		ret = list.__iadd__(self, other)
		self._upd()
		return ret

	def __imul__(self, other):
		ret = list.__imul__(self, other)
		self._upd()
		return ret

	def append(self, x):
		list.append(self, x)
		self._upd()

	def extend(self, x):
		list.extend(self, x)
		self._upd()

	def insert(self, i, x):
		list.insert(self, i, x)
		self._upd()

	def pop(self, i=-1):
		self._del(i)
		list.pop(self, i)

	def remove(self, x):
		for i, v in enumerate(self):
			if v == x:
				self._del(i)
				list.pop(self, i)
				break

	def reverse(self):
		list.reverse(self)
		self._upd()

	def sort(self, cmp=None, key=None, reverse=False):
		list.sort(self, cmp, key, reverse)
		self._upd()

	def _del(self, idx):
		ret = list.__getitem__(self, idx)
		if isinstance(ret, DataWatcherBase):
			self._onDiscard(ret)
		self._upd()

	def _dfsUpd(self, *args):
		self._upd()

	def _newDDirt(self, key, dic):
		# print '_newDDirt !!', key
		dirt = DictWatcher(dic, self._dfsUpd)
		self._dirtList.append(dirt)
		return dirt

	def _newLDirt(self, key, l):
		# print '_newLDirt !!', key
		dirt = ListWatcher(l, self._dfsUpd)
		self._dirtList.append(dirt)
		return dirt

	#
	# override copy functions
	#
	def __deepcopy__(self, memo):
		return copy.deepcopy(list(self))

	def __copy__(self):
		# 不得随便copy，会导致gc不掉
		raise NotImplementedError('do not copy')

	#
	# override destroy functions
	#
	def _gc_destroy(self, _):
		# weakref will be None, when obj be gc
		values = self._dirtList
		del self._upd
		del self._dirtList
		del self._discardList
		GCObject.other_gc_destroy(values)


#
# DictWatcher
#

class DictWatcher(dict, DataWatcherBase):
	'''
	处理嵌套dict和子级list
	记录更新删除和数据库更新字段
	'''

	def __init__(self, dic, dbsync):
		dict.__init__(self, dic)
		DataWatcherBase.__init__(self)
		self._dbsync = dbsync
		self._newS = set()
		self._setS = set()
		self._delS = set()
		self._dirtKO = WeakValueDictionary()

	def isModify(self):
		if len(self._setS) > 0 or len(self._delS) > 0:
			return True
		for k, dirt in self._dirtKO.iteritems():
			if dirt.isModify():
				return True
		return False

	def syncEnd(self):
		self._newS = set()
		self._setS = set()
		self._delS = set()
		for k, dirt in self._dirtKO.iteritems():
			dirt.syncEnd()

	def getSyncData(self, ignores):
		return self._dfsSync(1, ignores)

	def _dfsSync(self, deep, ignores):
		'''
		构造客户端同步数据
		删除操作，深度只为2，过多的删除信息还不如直接覆盖
		ignores只忽略第一层
		'''
		newD = {x: True for x in self._newS if not (ignores and x in ignores)}
		setD = {x: copy.deepcopy(dict.get(self, x)) for x in self._newS if not (ignores and x in ignores)}

		# 基础数据
		for x in self._setS:
			if ignores and x in ignores:
				continue

			if x not in self._dirtKO:
				setD[x] = copy.deepcopy(dict.get(self, x))
			else:
				dirt = self._dirtKO[x]
				# ListWatcher比较特殊，没有实现_dfsSync
				# 直接覆盖，所以newD要进行flag
				if isinstance(dirt, ListWatcher):
					newD[x] = True
					setD[x] = copy.deepcopy(dict.get(self, x))
		delD = {x: False for x in self._delS if not (ignores and x in ignores)}

		# 嵌套数据，list，dict等
		for k, dirt in self._dirtKO.iteritems():
			if k in self._newS:
				continue
			if ignores and k in ignores:
				continue

			_new, _set, _del = dirt._dfsSync(deep + 1, None)
			# print '_dfsSync', k, _new, _set, _del
			if _new:
				if k not in newD:
					newD[k] = _new
			if _set:
				setD[k] = _set
			if _del and k not in delD:
				delD[k] = _del

		return newD, setD, delD

	def _new(self, key):
		self._newS.add(key)
		# 如果是new，子节点不在保留同步数据
		dirt = self._dirtKO.get(key, None)
		if dirt:
			dirt.syncEnd()
		self._upd(key)

	def _upd(self, key):
		# print '_upd !!', key
		self._setS.add(key)
		self._delS.discard(key)
		self._dbsync(key)

	def _del(self, key):
		# print '_del !!', key
		self._newS.discard(key)
		self._setS.discard(key)
		self._delS.add(key)
		self._onDiscard(self._dirtKO.pop(key, None))
		self._dbsync(key)

	def _newDDirt(self, key, dic):
		import framework
		if hasattr(framework, '__dev__'):
			assertNotWatcher(dic, 1)
		# print '_newDDirt !!', key
		self._onDiscard(self._dirtKO.get(key, None))
		dirt = DictWatcher(dic, functools.partial(self._dbsync, key))
		self._dirtKO[key] = dirt
		self._dirtList.append(dirt)
		return dirt

	def _newLDirt(self, key, l):
		import framework
		if hasattr(framework, '__dev__'):
			assertNotWatcher(l, 1)
		# print '_newLDirt !!', key
		self._onDiscard(self._dirtKO.get(key, None))
		dirt = ListWatcher(l, functools.partial(self._upd, key))
		self._dirtKO[key] = dirt
		self._dirtList.append(dirt)
		return dirt

	#
	# override dict functions
	#
	def __setitem__(self, key, value):
		watched = False
		if isinstance(value, DataWatcherBase):
			old = dict.__getitem__(self, key)
			if id(value) != id(old):
				raise ValueError('Watcher can not be reset')
		elif isinstance(value, dict):
			value = self._newDDirt(key, value)
			watched = True
		elif isinstance(value, list):
			value = self._newLDirt(key, value)
			watched = True

		dict.__setitem__(self, key, value)
		if value is None:
			# 对于msgpack to Lua，None为nil，即为del
			self._del(key)
		else:
			if watched:
				self._new(key)
			else:
				self._upd(key)

	def __getitem__(self, key):
		ret = dict.__getitem__(self, key)
		if isinstance(ret, DataWatcherBase):
			return ret
		elif isinstance(ret, dict):
			dirt = self._newDDirt(key, ret)
			dict.__setitem__(self, key, dirt)
			return dirt
		elif isinstance(ret, list):
			dirt = self._newLDirt(key, ret)
			dict.__setitem__(self, key, dirt)
			return dirt
		return ret

	def __delitem__(self, key):
		dict.__delitem__(self, key)
		self._del(key)

	def setdefault(self, key, default=None):
		if key not in self:
			self.__setitem__(key, default)
		return self.__getitem__(key)

	def get(self, key, *args):
		if args:
			if key not in self:
				return args[0]
		return self.__getitem__(key)

	def pop(self, key, *args):
		ret = None
		if args:
			ret = dict.pop(self, key, args[0])
		else:
			ret = dict.pop(self, key)
		self._del(key)
		return ret

	def update(self, *args, **kwargs):
		if args:
			for k, v in args[0].iteritems():
				self.__setitem__(k, v)
		for k, v in kwargs.iteritems():
			self.__setitem__(k, v)

	def clear(self):
		for k in dict.iterkeys(self):
			self._del(k)
		dict.clear(self)

	#
	# override copy functions
	#
	def __deepcopy__(self, memo):
		return copy.deepcopy(dict(self))

	def __copy__(self):
		# 不得随便copy，会导致gc不掉
		raise NotImplementedError('do not copy')

	#
	# override destroy functions
	#
	def _gc_destroy(self, _):
		# weakref will be None, when obj be gc
		values = self._dirtList
		del self._dbsync
		del self._dirtList
		del self._discardList
		GCObject.other_gc_destroy(values)


#
# Copyable
#

class Copyable(object):
	def __deepcopy__(self, memo):
		ret = copy.copy(self)
		memo[id(self)] = ret
		ret.new_deepcopy()
		# print memo.keys()

		kvs = vars(ret)
		for k, v in kvs.iteritems():
			func = functools.partial(isinstance, v)
			if not any(itertools.ifilter(func, [Csv, Client])):
				# print 'deepcopy', self, k, id(v)
				vv = copy.deepcopy(v, memo)
				memo[id(v)] = vv
				setattr(ret, k, vv)
		return ret

	def new_deepcopy(self):
		pass


#
# ReloadHooker
#

class ReloadHooker(object):
	# 热更新用，更新逻辑，不更新类成员数据
	# 类成员一定要在本类声明所有成员变量，不能在函数中声明，比如classInit
	# 没有继承ReloadHooker的类，值会发生改变
	@staticmethod
	def __reload_class_update__(clsname, name, old, new):
		# 现在这些类型都不可能是类成员
		if isinstance(old, (type, classmethod, staticmethod, property, types.ClassType, types.FunctionType, types.MethodType)):
			# 装饰器里有闭包数据，闭包是readonly的，只能覆盖
			# 但new是bound的就不能用来覆盖
			# 因为带上了cls等信息，会导致函数内使用cls指向的是newcls
			# if isinstance(old, types.FunctionType):
			# 	logger.info('reloadhook newfunc %s %s %s %s', clsname, name, type(old), type(new))
			# 	return True, new
			logger.info('reloadhook patched %s %s %s %s', clsname, name, type(old), type(new))
			return False, None
		logger.info('reloadhook useold %s %s %s %s',clsname,  name, type(old), type(new))
		# 剩下的默认是类成员，使用旧数据
		return True, old


#
# ObjectBase
#

class ObjectBase(GCObject, Copyable, ReloadHooker):
	def __init__(self, game):
		GCObject.__init__(self)
		self._game = game
		self._mem = None

	@property
	def game(self):
		return self._game

	def set(self):
		return self # for short code

	def init(self):
		self._fixCorrupted()
		return self # for short code

	def _fixCorrupted(self):
		return

	def startSync(self):
		self._mem = self.mem

	@property
	def mem(self):
		return {}

	@property
	def model(self):
		mem = self.mem
		if mem:
			return {'_mem': mem}
		return {}

	@property
	def memSync(self):
		newest = self.mem
		if self._mem is None:
			newD, setD, delD = newest, None, None
		else:
			newD, setD, delD = dict_sync(self._mem, newest)
		self._mem = newest
		return newD, setD, delD

	@property
	def modelSync(self):
		memNew, memUpd, memDel = self.memSync
		return None, None, None, memNew, memUpd, memDel


#
# ObjectDBase
#

class ObjectDBase(ObjectBase):
	'''
	不支持对象复用，dbqueue以obj为单位刷新给db server
	'''
	ClientIgnores = None # 有些字段不用sync到客户端

	def __init__(self, game, dbc):
		ObjectBase.__init__(self, game)
		self._db = None
		self._dbc = dbc
		self._dbModifyKeyS = set()
		self._changed = None
		self.lastDBSyncKeys = None

	def new_deepcopy(self):
		del self._dbc

	def startSync(self):
		ObjectBase.startSync(self)
		if self._db:
			self._db.syncEnd()
		if hasattr(self, '_clientnosync'):
			del self._clientnosync

	def onDBModify(self, key, *args):
		if self._changed:
			self._changed(self)
		# 添加到DB变动集合
		self._dbModifyKeyS.add(key)
		# ObjectGame监听
		if self._game:
			self._game.onModelWatch(self.DBModel, key)
		# 添加到数据库同步队列
		DBJoinableQueue.Singleton.put(self)

	def getDBSyncKeysAndReset(self):
		ret = self._dbModifyKeyS.copy()
		self._dbModifyKeyS.clear()
		return ret

	def restoreLastDBSyncKeys(self):
		if self.lastDBSyncKeys:
			for key in self.lastDBSyncKeys:
				self._dbModifyKeyS.add(key)

	def getDBSyncKeysSize(self):
		return len(self._dbModifyKeyS)

	def set_changed_callback(self, f):
		self._changed = f

	@property
	def db(self):
		return self._db

	@property
	def model(self):
		mem = self.mem
		if mem:
			return {'_db': self._db, '_mem': mem}
		if self._db:
			return {'_db': self._db}
		return {}

	@property
	def dbSync(self):
		if self._db is None:
			return None, None, None
		if hasattr(self, '_clientnosync'):
			newD, setD, delD = True, copy.deepcopy(self._db), None
			del self._clientnosync
		else:
			newD, setD, delD = self._db.getSyncData(self.ClientIgnores)
		self._db.syncEnd()
		return newD, setD, delD

	@property
	def modelSync(self):
		'''
		modelSync与model不同点：
		1.model返回组装好的字典；modelSync直接返回原始数据由ObjectGame进行组装
		2.model返回所有数据；modelSync返回与上次发送数据的差异
		3.modelSync返回四元组，{}和None均表示未改动，False表示删除
		'''
		dbNew, dbUpd, dbDel = self.dbSync
		memNew, memUpd, memDel = self.memSync
		return dbNew, dbUpd, dbDel, memNew, memUpd, memDel

	def modelSyncFromCache(self, cache):
		newest = copy.deepcopy(self.model)
		if cache is None:
			dNewD, dSetD, dDelD = True, newest.get('_db', None), None
			mNewD, mSetD, mDelD = True, newest.get('_mem', None), None
		else:
			dNewD, dSetD, dDelD = dict_sync(cache.get('_db', {}), newest.get('_db', {}))
			mNewD, mSetD, mDelD = dict_sync(cache.get('_mem', {}), newest.get('_mem', {}))
		return dNewD, dSetD, dDelD, mNewD, mSetD, mDelD, newest

	# normally, `id` is primary key(int) in redis scheme
	def id():
		dbkey = 'id'
		return locals()
	id = db_property(**id())

	# just for print id
	@property
	def pid(self):
		return binascii.hexlify(self.id)

	# same as `id`
	@property
	def pkey(self):
		return self.id

	def set(self, dic):
		self._db = DictWatcher(copy.deepcopy(dic), self.onDBModify)
		self._clientnosync = True
		return self # for short code

	# set触发跟客户端的sync
	# dbset触发客户端和DB服务器的sync
	# 从DB服务器获取的数据，只用set即可
	# 由Game服务器构造的数据，需要dbset
	def dbset(self, dic, modelFromDB=False):
		if not modelFromDB:
			self._servernosync = True
			DBJoinableQueue.Singleton.put(self)
		return self.set(dic)

	def setForgetFlag(self):
		self._forget = True
		DBJoinableQueue.Singleton.put(self)

	def _update_pack(self):
		# print type(self), self.id, hasattr(self, '_servernosync')
		if hasattr(self, '_servernosync'):
			del self._servernosync
			ret = copy.deepcopy(self._db)
			ret.pop('id') # id是由DB服务器分配，外部不能设置id
			return ret

		dbUpdate = self.getDBSyncKeysAndReset()
		kvs = {}
		for k in dbUpdate:
			kvs[k] = self._db[k]
		return kvs

	def needSave(self):
		if not hasattr(self, '_dbc') or self._db is None:
			return False
		if self.is_gc_destroy():
			return False
		return self.getDBSyncKeysSize() > 0

	def save_async(self, forget=False):
		if not hasattr(self, '_dbc') or self._db is None:
			return okfu
		if self.is_gc_destroy():
			return okfu

		fu = self._save_async(forget=forget)
		if getattr(self, '_delete', False):
			ret = Future()
			def done(_):
				chain_future(self._delete_async(), ret)
			fu.add_done_callback(done)
			return ret
		return fu

	def _save_async(self, forget=False):
		kvs = self._update_pack()
		forget = forget or getattr(self, '_forget', False)
		if len(kvs) == 0:
			if forget:
				return self._dbc.call_async('DBCommitObject', self.DBModel, self.pkey)
			return okfu
		# print '!!! save_async', type(self), self.pid, kvs.keys()
		self.lastDBSyncKeys = kvs.keys()
		return self._dbc.call_async('DBUpdate', self.DBModel, self.pkey, kvs, forget)

	def _delete_async(self):
		if not hasattr(self, '_dbc') or self._db is None:
			return okfu
		def done(_):
			if hasattr(self, '_dbc'):
				delattr(self, '_dbc')
		fu = self._dbc.call_async('DBDelete', self.DBModel, self.pkey, self._delay)
		fu.add_done_callback(done)
		return fu

	def delete_async(self, delay=False):
		# 只是加上标记，实际在dbqueue进行save_async时删除
		self._delete = True
		self._delay = delay # if True, data will migrate to Expired collections
		# 添加到数据库同步队列
		DBJoinableQueue.Singleton.put(self)

#
# ObjectDBaseMap
#

class ObjectDBaseMap(ObjectBase):
	'''
	self._objs: {db id: db obj}
	'''

	def __init__(self, game):
		ObjectBase.__init__(self, game)
		self._objs = {}
		self._addS = set()
		self._delS = set()
		self._updS = set()

	def __iter__(self):
		return iter(self._objs.values())

	def _new(self, dic):
		raise NotImplementedError()

	def set(self, modelL):
		if not isinstance(modelL, list):
			modelL = [modelL]
		self._objs = dict(filter(None, map(self._new, modelL)))
		self._addS = set()
		self._delS = set()
		self._updS = set()
		self._addspeakers(self._objs.keys())
		return ObjectBase.set(self)

	def init(self):
		for id in self._objs.keys():
			obj = self._objs.get(id)
			if obj is None:
				# self._objs.pop(id)
				continue
			obj.init()
		return ObjectBase.init(self)

	def save_async(self, forget=False):
		fus = [obj.save_async(forget) for obj in self._objs.itervalues()]
		future = Future()

		if len(fus) == 0:
			future.set_result(0)
			return future

		closure = [len(fus), 0]
		def allDone(fu):
			closure[1] += 1
			if closure[1] >= closure[0]:
				future.set_result(closure[0])

		map(lambda f: f.add_done_callback(allDone), fus)
		return future

	def startSync(self):
		for _id, obj in self._objs.iteritems():
			if obj:
				obj.startSync()

	@property
	def modelSync(self):
		ret = {k: (True, self._objs[k].db, None, True, self._objs[k].mem, None) for k in self._addS}
		ret.update({
			k: (None, None, False, None, None, False) for k in self._delS
		})
		self._addS.clear()
		self._delS.clear()
		return ret

	@property
	def dirtyMapSync(self):
		d = {key: self._objs[key].modelSync for key in self._updS}
		self._updS.clear()
		return d

	def _addspeakers(self, keys):
		for key in keys:
			self._objs[key].set_changed_callback(self._modifyobj)

	def _modifyobj(self, obj):
		self._updS.add(obj.id)

	def _add(self, keys):
		self._addS.update(keys)
		self._delS.difference_update(keys)
		self._addspeakers(keys)

	def _del(self, keys):
		self._addS.difference_update(keys)
		self._updS.difference_update(keys)
		self._delS.update(keys)

	#
	# override destroy functions
	#
	def _gc_destroy(self, _):
		values = self._objs.values()
		del self._objs
		GCObject.other_gc_destroy(values)


#
# ObjectNoGCBase
#

class ObjectNoGCBase(ObjectBase):
	'''
	适合公共对象，不进行GC
	'''
	def gc_destroy(self):
		return

#
# ObjectNoGCDBase
#

class ObjectNoGCDBase(ObjectDBase):
	'''
	适合公共对象，不进行GC
	'''
	def gc_destroy(self):
		return

#
# ObjectCSVRange
#

class ObjectCSVRange(ReloadHooker):
	CSVName = ''
	RangeL = []

	@classmethod
	def classInit(cls):
		cls.RangeL = []
		# csvR = getattr(csv, cls.CSVName)
		if isinstance(cls.CSVName, (tuple, list)):
			csvR = csv
			for part in cls.CSVName:
				csvR = csvR[part]
		else:
			csvR = getattr(csv, cls.CSVName)
		for idx in csvR:
			cfg = csvR[idx]
			cls.RangeL.append(cls(cfg))
			cls.RangeL.sort(key=lambda o: o.start)

	@classmethod
	def getRange(cls, rank):
		pos = lowerBound(cls.RangeL, rank, lambda o: o.start)
		if pos >= 0 and cls.RangeL[pos].inRange(rank):
			return cls.RangeL[pos]
		return None

	def __init__(self, cfg):
		self._range = cfg.range

	@property
	def start(self):
		return self._range[0]

	@property
	def end(self):
		return self._range[1]

	def inRange(self, rank):
		return self.start <= rank and rank < self.end


#
# ObjectDicAttrs
#

class ObjectDicAttrs(ReloadHooker):
	def __init__(self, dic):
		self._dic = dic

	def __iter__(self):
		return iter(self._dic.keys())

	def __getattr__(self, name):
		return self._dic.get(name, None)

	def init(self, dic):
		self._dic = dic

	def sync(self, dic):
		self._dic.update(dic)

	@property
	def model(self):
		return {'_db': self._dic}

	def to_dict(self):
		return self._dic

	def iteritems(self):
		return self._dic.iteritems()

	def iterkeys(self):
		return self._dic.iterkeys()

	def itervalues(self):
		return self._dic.itervalues()

	def modelSyncFromCache(self, cache):
		newest = copy.deepcopy(self.model)
		if cache is None:
			dNewD, dSetD, dDelD = True, newest.get('_db', None), None
			mNewD, mSetD, mDelD = True, newest.get('_mem', None), None
		else:
			dNewD, dSetD, dDelD = dict_sync(cache.get('_db', {}), newest.get('_db', {}))
			mNewD, mSetD, mDelD = dict_sync(cache.get('_mem', {}), newest.get('_mem', {}))
		return dNewD, dSetD, dDelD, mNewD, mSetD, mDelD, newest
