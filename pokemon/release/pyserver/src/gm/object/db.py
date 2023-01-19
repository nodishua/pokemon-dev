#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2017 TianJi Information Technology Inc.
'''
from __future__ import absolute_import

import copy
import traceback
from tornado.gen import Return

from framework.lru import LRUCache
from framework.log import logger
from framework.object import db_property

from pymongo import MongoClient


# DBMeta
class DBMetaClass(type):

	def __new__(cls, name, bases, dict):
		defaultDocument = dict.get('defaultDocument', None)
		if defaultDocument:
			defaultDocument = defaultDocument.__func__
		else:
			for baseCls in reversed(bases):
				if hasattr(baseCls, 'defaultDocument'):
					defaultDocument = getattr(baseCls, 'defaultDocument')
					break

		if defaultDocument:
			fields = defaultDocument().keys()
			for field in fields:
				if field in dict:
					continue
				dict[field] = db_property(field)

		model = type.__new__(cls, name, bases, dict)
		return model


class DBMeta(object):
	__metaclass__ = DBMetaClass


# DBRecord
class DBRecord(DBMeta):
	Collection = ''
	Indexes = []

	def __init__(self, db):
		default = self.defaultDocument()
		default.update(db)
		self._db = default
		self.fromDB(self._db)

	def __iter__(self):
		return iter(self._db.keys())

	@property
	def _id(self):
		return self._db['_id']

	def fromDB(self, db):
		pass

	def toDB(self):
		ret = {}
		ret.update(self._db)
		return ret

	@staticmethod
	def defaultDocument():
		return {}

	@staticmethod
	def uniqueKeyFromQuery(d):
		raise NotImplementedError()

	@property
	def uniqueKey(self):
		raise NotImplementedError()

	def toDict(self):
		return copy.deepcopy(self._db)


	def iteritems(self):
		return self._db.iteritems()

	def iterkeys(self):
		return self._db.iterkeys()

	def itervalues(self):
		return self._db.itervalues()


############
# mongo helper
############

class MongoDB(object):
	__Singleton = None

	def __init__(self, cfg):
		self.cfg = cfg
		self.init()

	def init(self):
		self.host = self.cfg.get('host', 'localhost')
		self.port = self.cfg['port']
		self.dbname = self.cfg['dbname']
		self.username = self.cfg.get('username', None)
		self.password = self.cfg.get('password', None)

		self.connected = False
		self.connect()

	def connect(self):
		if self.connected:
			return

		if self.username and self.password:
			self._conn = MongoClient(self.host, self.port,
				username=self.username, password=self.password)
		else:
			self._conn = MongoClient(self.host, self.port)

		self._dbc = self._conn[self.dbname]
		self.connected = True

	@classmethod
	def get_instance(cls, cfg):
		if cls.__Singleton:
			return cls.__Singleton
		cls.__Singleton = MongoDB(cfg)
		return cls.__Singleton

	@property
	def client(self):
		return self._dbc

	def close(self):
		if not self.connected:
			return
		self.connected = False
		if self.username and self.password:
			self._dbc.logout()
		self._conn.close()


def mongoCreateCollection(client, dbcls):
	collection = getattr(client, dbcls.Collection)
	# if collection.count() == 0:
	# 	collection.insert_one(dbcls.defaultDocument())
	indexes = copy.deepcopy(dbcls.Indexes)
	for index in indexes:
		idx = index.pop("index")
		collection.create_index(idx, **index)


def mongoCreate(client, dbcls, data={}):
	collection = getattr(client, dbcls.Collection)
	doc = dbcls.defaultDocument()
	doc.update(data)
	result = collection.insert_one(doc)
	doc['_id'] = result.inserted_id
	return dbcls(doc)


def mongoSave(client, dbrecord):
	collection = getattr(client, dbrecord.Collection)
	db = dbrecord.toDB()

	if '_id' not in db:
		result = collection.insert_one(db)
		dbrecord._db['_id'] = result.inserted_id
	else:
		_id = db.pop("_id")
		result = collection.update({"_id": _id}, {"$set": db})
	return result


def mongoFindOne(client, dbcls, query, onlyData=False):
	collection = getattr(client, dbcls.Collection)
	data = collection.find_one(query)
	if data is None:
		return None
	if onlyData:
		return data
	return dbcls(data)


def mongoFind(client, dbcls, query={}, hint=None, sort=None, limit=0, skip=0):
	collection = getattr(client, dbcls.Collection)
	cursor = collection.find(query, limit=limit, skip=skip)
	if cursor is None:
		return None
	if hint:
		cursor = cursor.hint(hint)
	if sort:
		cursor = cursor.sort(sort)
	return [dbcls(data) for data in cursor]


def mongoAggregate(client, dbcls, pipeline, limit=0):
	collection = getattr(client, dbcls.Collection)
	commandCursor = collection.aggregate(pipeline, limit=10)
	return [data for data in commandCursor]


# 计算数据总数
def mongoCount(client, dbcls, query):
	collection = getattr(client, dbcls.Collection)
	return collection.find(query).count()


############
# db helper
############

class AttrsDict(dict):

	def __init__(self, dic=None):
		dict.__init__(self)
		if dic:
			assert isinstance(dic, dict), "must be dict object"
			for k, v in dic.items():
				setattr(self, k, v)

	def __setattr__(self, key, value):
		self.__setitem__(key, value)

	def __setitem__(self, key, value):
		if isinstance(key, (str, unicode)):
			super(AttrsDict, self).__setattr__(key, value)
		super(AttrsDict, self).__setitem__(key, value)


class KeyMapObject(object):
	def __init__(self, obj, map):
		self._obj = obj
		self._map = map

	def __getattr__(self, name):
		return getattr(self._obj, self._map.get(name, name))


# DBCache
class DBCache(object):
	Enabled = False
	Cache = LRUCache(100)
	AccountChannelCache = LRUCache(1000)

	@classmethod
	def get(cls, dbcls, keyOrQuery, forget=False):
		if not cls.Enabled:
			return None

		tkey = keyOrQuery
		if isinstance(keyOrQuery, dict):
			tkey = dbcls.uniqueKeyFromQuery(keyOrQuery)

		tkey = (dbcls.__name__,) + tkey
		ret = cls.Cache.popByKey(tkey) if forget else cls.Cache.getValue(tkey)

		return ret

	@classmethod
	def set(cls, dbrecord):
		if not cls.Enabled:
			return None

		tkey = (type(dbrecord).__name__,) + dbrecord.uniqueKey

		return cls.Cache.set(tkey, dbrecord)

	@classmethod
	def saveAllMongo(cls, client, forget=False):
		for key, dbrecord in cls.Cache.iteritems():
			try:
				# print 'save mongo', key, getattr(dbrecord, 'name', None)
				mongoSave(client, dbrecord)
			except Exception as e:
				logger.exception('save mongo %s %s exception', key, dbrecord._id)
				print dbrecord.toDict()
				print e
		if forget:
			cls.Cache.clear()

	@classmethod
	def getAccountChannel(cls, accountID):
		return cls.AccountChannelCache.getValue(accountID)

	@classmethod
	def setAccountChannel(cls, accountID, channel):
		cls.AccountChannelCache.set(accountID, channel)


def DBSave(client, dbrecord, forget=False):
	result = mongoSave(client, dbrecord)
	if forget:
		DBCache.get(type(dbrecord), dbrecord.uniqueKey, forget=True)
	return result

def DBFind(client, dbcls, query, hint=None, sort=None, limit=0, skip=0, noCache=False):
	# from mongo
	dbrecords = mongoFind(client, dbcls, query, hint=hint, sort=sort, limit=limit, skip=skip)
	if dbrecords is None:
		return None
	ret = []
	for dbrecord in dbrecords:
		cache = DBCache.get(dbcls, dbrecord.uniqueKey)
		if cache:
			ret.append(cache)
		else:
			if not noCache:
				pop = DBCache.set(dbrecord)
				if pop:
					mongoSave(client, pop[1])
			ret.append(dbrecord)
	return ret


def DBFindOne(client, dbcls, query):
	# from cache
	dbrecord = DBCache.get(dbcls, query)
	if dbrecord:
		return dbrecord
	# from mongo
	dbrecord = mongoFindOne(client, dbcls, query)
	if dbrecord is None:
		return None
	pop = DBCache.set(dbrecord)
	if pop:
		mongoSave(client, pop[1])
	return dbrecord


def DBCreateOne(client, dbcls, data):
	dbrecord = mongoCreate(client, dbcls, data)
	pop = DBCache.set(dbrecord)
	if pop:
		mongoSave(client, pop[1])
	return dbrecord


def DBFindOrCreate(client, dbcls, query):
	dbrecord = DBFindOne(client, dbcls, query)
	if dbrecord:
		return dbrecord
	dbrecord = mongoCreate(client, dbcls, query)
	pop = DBCache.set(dbrecord)
	if pop:
		mongoSave(client, pop[1])
	return dbrecord


def DBFindOrCreateSingleton(client, dbcls):
	mongoCreateCollection(client, dbcls)

	collection = getattr(client, dbcls.Collection)
	if collection.find().count() == 0:
		collection.insert_one(dbcls.defaultDocument())

	return mongoFindOne(client, dbcls, {})


def DBGetAccountChannel(client, accountID):
	# from account channel cache
	channel = DBCache.getAccountChannel(accountID)
	if channel:
		return channel

	from gm.object.account import DBAccount
	query = {'account_id': accountID}
	# from cache
	dbrecord = DBCache.get(DBAccount, query)
	if dbrecord is None:
		# from mongo
		dbrecord = mongoFindOne(client, DBAccount, query)
		if dbrecord is None:
			return None, None
	channel = (dbrecord.channel, dbrecord.sub_channel)
	DBCache.setAccountChannel(accountID, channel)
	return channel


def DBAggregate(client, dbcls, pipeline):
	result = mongoAggregate(client, dbcls, pipeline)
	return result


def DBCount(client, dbcls, query):
	return mongoCount(client, dbcls, query)