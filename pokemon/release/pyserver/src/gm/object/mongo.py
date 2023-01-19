#!/usr/bin/python
# -*- coding: utf-8 -*-


from pymongo import UpdateOne, InsertOne

import copy


class ObjectDictAttrs(dict):

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
			super(ObjectDictAttrs, self).__setattr__(key, value)
		super(ObjectDictAttrs, self).__setitem__(key, value)


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
	def find(cls, client, query={}, hint=None, sort=None, limit=0, skip=0):
		collection = cls.get_collection(client)
		data_cursor = collection.find(query, limit=limit, skip=skip)
		_amount = data_cursor.count()
		if _amount == 0:
			return None
		if hint:
			data_cursor = data_cursor.hint(hint)
		if sort:
			data_cursor = data_cursor.sort(sort)

		def _data_gen():
			while 1:
				try:
					ret = data_cursor.next()
					ret = cls.get_document(ret)
				except StopIteration:
					break
				except:
					raise
				yield ret

		return (_data_gen(), _amount)

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
			doc["id"] = cls.inc_id() or doc["id"]
		return collection.insert_one(doc)

	@classmethod
	def insert_many(cls, client, dataL, ordered=True):
		collection = cls.get_collection(client)
		docL = []
		for data in dataL:
			doc = cls._get_document(data)
			if "id" in doc:
				doc["id"] = cls.inc_id() or doc["id"]
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
				doc["id"] = self.inc_id() or doc["id"]
			dataL.append(InsertOne(doc))

		return collection.bulk_write(dataL, ordered=ordered)
