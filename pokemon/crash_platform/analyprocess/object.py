# -*- coding: utf-8 -*-
from __future__ import absolute_import

import copy
import collections


class DBCache(object):

	def __init__(self, collection, db={}):
		self.collection = collection
		self._db = db

	@property
	def length(self):
		return len(self._db)

	def clear(self):
		self._db.clear()

	def set(self, key, dic):
		record = DBRecord(dic)
		self._db[key] = record
		return record

	def get(self, key, default=None):
		return self._db.get(key, default)

	def saveToDB(self, client):
		d = []
		for record in self._db.itervalues():
			_set = {}
			for k, v in record.flush_change():
				_set[k] = v
			if not _set:
				continue
			d.append(({"_id": record._id}, {"$set": _set}))

		if not d:
			return
		self.collection.bulk_write(client, update=d)


class LRUCache(DBCache):

	def __init__(self, collection, capacity=10000):
		DBCache.__init__(self, collection, db=collections.OrderedDict())
		self.capacity = capacity

	def set(self, key, dic):
		self._db.pop(key, None)

		if len(self._db) >= self.capacity:
			self._db.popitem(last=False)
		return DBCache.set(self, key, dic)

	def get(self, key, default=None):
		d = self._db.pop(key, None)
		if not d:
			return default
		self._db[key] = d
		return d


class DBRecord(object):

	def __init__(self, dic):
		fields = dic.keys()
		for field in fields:
			assert isinstance(field, (str, unicode)), "%s not string"% field

			if isinstance(dic[field], dict):
				dic[field] = DBRecord(dic[field])
			if isinstance(dic[field], list):
				dic[field] = ChangeList(dic[field])
			self.__dict__[field] = dic[field]

		object.__setattr__(self, "_dic", dic)
		object.__setattr__(self, "_change", {})

	def __iter__(self):
		return iter(self._dic.keys())

	def __contains__(self, key):
		return key in self._dic

	def __setattr__(self, key, value):
		self._dic[key] = value
		self._change[key] = value
		object.__setattr__(self, key, value)

	def __getitem__(self, key):
		return self._dic[key]

	def __setitem__(self, key, value):
		self.__setattr__(key, value)

	def to_dict(self):
		dic = copy.deepcopy(self._dic)
		for k, v in dic.iteritems():
			if isinstance(v, DBRecord):
				dic[k] = v.to_dict()
		return dic

	def iteritems(self):
		return self._dic.iteritems()

	def iterkeys(self):
		return self._dic.iterkeys()

	def itervalues(self):
		return self._dic.itervalues()

	def check_change(self):
		data = []
		for k, v in self._dic.iteritems():
			if isinstance(v, DBRecord):
				d = v.check_change()
				for k2, v2 in d:
					data.append((k + "." + k2, v2))
			elif isinstance(v, ChangeList):
				if v.check_change():
					data.append((k, v))
			else:
				if k in self._change:
					data.append((k, v))

		return data

	def clear_change(self):
		self._change.clear()
		for v in self.itervalues():
			if isinstance(v, DBRecord):
				v.clear_change()
			if isinstance(v, ChangeList):
				v.clear_change()

	def flush_change(self):
		change = self.check_change()
		self.clear_change()
		return change

	def get(self, key, default=None):
		return self._dic.get(key, default)


class ChangeList(list):

	def __init__(self, lis):
		list.__init__(self, lis)
		self._change = False

	def __setitem__(self, key, value):
		if not self._change:
			if value != self[key]:
				self._change = True
		list.__setitem__(self, key, value)

	def append(self, p_object):
		if not self._change:
			self._change = True
		list.append(self, p_object)

	def check_change(self):
		return self._change

	def clear_change(self):
		self._change = False