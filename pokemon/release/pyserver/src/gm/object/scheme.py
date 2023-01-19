#!/usr/bin/python
# -*- coding: utf-8 -*-

from __future__ import absolute_import

from .mongo import Model
from gm.util import calc_md5, datetime2str

import datetime


class User(Model):
	Collection = 'User'
	Indexes = [
		{"index": "name", "unique": True},
	]

	@staticmethod
	def default_document():
		return {
			'name': '', # GM registration name
			'pass_md5': '', # Password MD5
			'created_time': '', # Registration time
			'last_time': '', # Last login time
			'permission_level': 0, # Level
			'operated_history': [], # Operating record [(rpc, param, time), ...]
		}

	@classmethod
	def init(cls, client):
		cls.create_index(client)

		"""Default user"""
		if not cls.find_one(client, {"name": "admin"}):
			pass_md5 = calc_md5("qq123456..")
			nowS = datetime2str(datetime.datetime.now())

			cls.insert_one(client, {"name": "admin",
				"pass_md5": pass_md5, "created_time": nowS, "last_time": nowS,
				"permission_level": 999})


# class Account(DBRecord):
# 	Collection = 'Account'
# 	Indexes = [
# 		{
# 			"index": [
# 				("account_id", 1),
# 			],
# 			"unique": True,
# 		},
# 		{"index": "name"},
# 		{"index": "channel"},
# 		{"index": "sub_channel"},
# 		{"index": "created_time"},
# 		{"index": "pay_amount"},
# 		{"index": "first_pay_time"},
# 	]

# 	@staticmethod
# 	def default_document():
# 		return {
# 			'account_id': '',
# 			'name': '',
# 			'channel': '',
# 			'sub_channel': '',
# 			'created_time': '',
# 			'pay_amount': '',
# 			'first_pay_time': '',
# 		}


# class PayOrder(Model):
# 	Collection = 'PayOrder'
# 	Indexes = [
# 		{"index": "order_id", "unique": True},
# 		{"index": "account_id"},
# 		{"index": "server_key"},
# 		{"index": "time"},
# 		{"index": "channel"},
# 		{"index": "channel_order_id"},
# 	]

# 	@staticmethod
# 	def default_document():
# 		return {
# 			'order_id': '',
# 			'account_id': '',
# 			'server_key': '',
# 			'time': '',
# 			'channel': '',
# 			'channel_order_id': '',
# 		}


# class Archive(DBRecord):
# 	Collection = 'Archive'
# 	Indexes = [
# 		{
# 			"index": [
# 				("date", 1),
# 				("channel", 1),
# 				("sub_channel", 1),
# 				("language", 1),
# 				("area", 1), # Account is not partition
# 			],
# 			"name": "ArchiveIndex",
# 			"unique": True,
# 		},
# 		{"index": "channel"},
# 		{"index": "sub_channel"},
# 		{"index": "language"},
# 		{"index": "area"},
# 	]


# class DailyArchive(DBArchive):
# 	Collection = 'DailyArchive'
# 	Indexes = [
# 		{"index": "date", "unique": True},
# 	]


# class Record(Model):
# 	Collection = 'record'
# 	Indexes = [
# 		{"index": "key", "unique": True},
# 	]

# 	@staticmethod
# 	def default_document():
# 		return {
# 			"key": None,
# 			"value": None,
# 		}


# class IncModel(Model):

# 	@classmethod
# 	def inc_id(cls, client):
# 		collection = cls.get_collection(client)
# 		key = cls.Collection + "_count_id"
# 		ret = collection.find_and_modify({"key": key}, update={"$inc": {'value': 1}}, upsert=True)
# 		if ret:
# 			return ret["value"] + 1
# 		return 1


