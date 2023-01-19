#!/usr/bin/python
# -*- coding: utf-8 -*-

from __future__ import absolute_import

import copy
import pymongo
from pymongo import UpdateOne, InsertOne

from object import ObjectDictAttrs
# from object.scheme import Statistics


class Client(object):
	__Singleton = None

	def __init__(self, host, port, dbname, username=None, password=None, uri=None):
		self.host = host
		self.port = port
		self.dbname = dbname
		self.username = username
		self.password = password
		self.uri = uri
		self.connected = False
		self.connect()

	def connect(self):
		if self.connected:
			return

		if self.uri:
			self._conn = pymongo.MongoClient(self.uri)
		elif self.username and self.password:
			self._conn = pymongo.MongoClient(self.host, self.port,
				username=self.username, password=self.password)
		else:
			self._conn = pymongo.MongoClient(self.host, self.port)
		self._dbc = self._conn[self.dbname]
			# self._dbc.authenticate(self.username, self.password)
		self.connected = True

	@classmethod
	def get_instance(cls, host, port, dbname, username=None, password=None):
		if cls.__Singleton:
			return cls.__Singleton
		cls.__Singleton = Client(host, port, dbname, username, password)
		return cls.__Singleton

	@property
	def DBClient(self):
		return self._dbc

	def close(self):
		if not self.connected:
			return
		self.connected = False
		if self.username and self.password:
			self._dbc.logout()
		self._conn.close()


class Model(object):
	Collection = ''
	Indexes = []

	@classmethod
	def init(cls, client):
		cls.create_index(client)

	@classmethod
	def create_index(cls, client):
		collection = cls.get_collection(client)
		for index in copy.deepcopy(cls.Indexes):
			idx = index.pop("index")
			collection.create_index(idx, **index)

	@classmethod
	def inc_id(cls, client):
		return None

	@staticmethod
	def default_document():
		return {}

	@classmethod
	def get_collection(cls, client):
		collection = getattr(client, cls.Collection)
		return collection

	@classmethod
	def _get_document(cls, dic):
		default = cls.default_document()
		default.update(dic)
		return default

	@classmethod
	def get_document(cls, dic):
		return ObjectDictAttrs(cls._get_document(dic))

	@classmethod
	def find(cls, client, query={}, hint=None, sort=None, limit=0, skip=0, distinct=None):
		collection = cls.get_collection(client)
		data_cursor = collection.find(query)
		if data_cursor.count() == 0:
			return []

		if hint:
			data_cursor.hint(hint)
		if skip:
			data_cursor.skip(skip)
		if limit:
			data_cursor.limit(limit)
		if sort:
			data_cursor.sort(*sort)

		if distinct:
			return data_cursor.distinct(distinct)

		return (cls.get_document(r) for r in data_cursor)

	@classmethod
	def find_one(cls, client, query):
		collection = cls.get_collection(client)
		data = collection.find_one(query)
		if not data:
			return None
		return cls.get_document(data)

	@classmethod
	def insert_one(cls, client, data):
		collection = cls.get_collection(client)
		doc = cls._get_document(data)
		if "id" in doc:
			doc["id"] = cls.inc_id(client) or doc["id"]
		return collection.insert_one(doc)

	@classmethod
	def insert_many(cls, client, dataL, ordered=True):
		collection = cls.get_collection(client)
		docL = []
		for data in dataL:
			doc = cls._get_document(data)
			if "id" in doc:
				doc["id"] = cls.inc_id(client) or doc["id"]
			docL.append(doc)
		return collection.insert_many(docL, ordered=ordered)

	@classmethod
	def update(cls, client, query, update, upsert=False, multi=False):
		collection = cls.get_collection(client)
		return collection.update(query, update, upsert=upsert, multi=multi)

	@classmethod
	def bulk_write(cls, client, update=[], insert=[], upsert=False, ordered=True):
		"""r = collection.bulk_write(
			[
				UpdateOne({"_id": 110}, {"$set": {"ident": "abc"}}, upsert=False),
				UpdateOne({"_id": 111}, {"$set": {"ident": "lkj"}}, upsert=False)
			],
			ordered=ordered
		)
		r.bulk_api_result: {'nModified': 1, 'nUpserted': 0, 'nMatched': 2,
			'writeErrors': [], 'upserted': [], 'writeConcernErrors': [], 'nRemoved': 0, 'nInserted': 0}

		update: [(query, update),(...)...]
		insert: [{...}, {...}]"""
		collection = cls.get_collection(client)

		dataL = []
		for data in update:
			dataL.append(UpdateOne(*data, upsert=upsert))

		for data in insert:
			doc = cls._get_document(data)
			if "id" in doc:
				doc["id"] = self.inc_id(client) or doc["id"]
			dataL.append(InsertOne(doc))

		return collection.bulk_write(dataL, ordered=ordered)

	@classmethod
	def count(cls, client, query={}):
		collection = cls.get_collection(client)
		return collection.find(query).count()

	@classmethod
	def find_and_modify(cls, client, query, update, upsert=False):
		collection = cls.get_collection(client)
		return collection.find_and_modify(query, update, upsert=upsert)

	@classmethod
	def aggregate(cls, client, pipeline):
		collection = cls.get_collection(client)
		return collection.aggregate(pipeline)


class IncModel(Model):
	CurrentID = None

	@classmethod
	def init(cls, client):
		cls.create_index(client)

		# 需要加锁
		# ID = cls.count(client)
		# if ID > 0:
		# 	data_cursor = cls.find(client, sort=("id", pymongo.ASCENDING), skip=ID-1)
		# 	for data in data_cursor:
		# 		ID = max(ID, data["id"])
		# cls.CurrentID = ID + 1

		from object.scheme import Statistics

		r = Statistics.find_one(client, {"key": cls.Collection + "_count_id"})
		if not r:
			Statistics.insert_one(client, {"key": cls.Collection + "_count_id", "value": 1})

	@classmethod
	def inc_id(cls, client):
		# ID = cls.CurrentID
		# cls.CurrentID += 1
		# return ID

		from object.scheme import Statistics

		ret = Statistics.find_and_modify(client,
			{"key": cls.Collection + "_count_id"}, update={"$inc": {'value': 1}})
		if not ret:
			raise "not %s"% cls.Collection
		return ret["value"]



if __name__ == '__main__':
	class b(Model):
		Collection = 'test'

	print '123123'
	d = Client.get_instance("172.16.2.2", 27017, "test", 'gmsystem', '123456')
	print d
	data, c = b.find(d.DBClient, limit=1, skip=2)
	print data, c
	for i in data:
		print i
