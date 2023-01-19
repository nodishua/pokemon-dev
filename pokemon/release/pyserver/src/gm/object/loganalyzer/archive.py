#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2017 TianJi Information Technology Inc.
'''
from __future__ import absolute_import, division

import framework
from gm.object.db import *

import ast


# DBOfflineLogInfo
class DBOfflineLogInfo(DBRecord):
	Collection = 'OfflineLogInfo'
	Indexes = [
		{"index": "server_key", "unique": True,},
	]

	@property
	def uniqueKey(self):
		return (self.server_key,)

	@staticmethod
	def uniqueKeyFromQuery(d):
		return (d['server_key'],)

	@staticmethod
	def defaultDocument():
		return {
			'server_key': 'none',
			'cur_date': 20190801,
			'cur_pos': 0,
			'mtime': 0.0,
		}


class DBLogRole(DBRecord):
	Collection = 'LogRole'
	Indexes = [
		{
			"index": [
				("language", 1),
				("server_key", 1),
				("role_id", 1)
			],
			"unique": True,
		},
		{"index": "server_key"},
		{"index": "role_id"},
		{"index": "role_uid"},
		{"index": "account_id"},
		{"index": "channel"},
		{"index": "language"},
		{"index": "last_time"},
		{"index": "createtime"}
	]

	@property
	def uniqueKey(self):
		return (self.language, self.server_key, self.role_id)

	@staticmethod
	def uniqueKeyFromQuery(d):
		return (d['language'], d['server_key'], d['role_id'])

	@staticmethod
	def defaultDocument():
		return {
			'language': framework.__language__,
			'server_key': 'none',
			'role_id': 'none',
			'role_uid': 'none',
			'level': 0,
			'vip': 0,
			'rmb': 0,
			'gold': 0,
			'account_id': 'none',
			'channel': 'none',
			'last_time': 0.0,
			'createtime': 0.0,
		}

	def set(self, account, channel, role_uid,
		level, vip, rmb, gold, timeStamp, createtime=None):
		self.account_id, self.channel, self.role_uid = account, channel, role_uid
		self.level, self.vip, self.rmb, self.gold = level, vip, rmb, gold
		self.last_time = timeStamp
		if createtime:
			self.createtime = createtime


class DBLogRoleArchive(DBRecord):
	Collection = 'LogRoleArchive'
	Indexes = [
		{
			"index": [
				("date", 1),
				("language", 1),
				("server_key", 1),
			],
			"unique": True,
		},
		{"index": "date"},
		{"index": "server_key"},
		{"index": "role_id"},
		{"index": "role_uid"},
		{"index": "channel"},
		{"index": "language"},
	]

	@property
	def uniqueKey(self):
		return (self.date, self.language, self.server_key)

	@staticmethod
	def uniqueKeyFromQuery(d):
		return (d['date'], d['language'], d['server_key'])

	@staticmethod
	def defaultDocument(**kwargs):
		return {
			'date': kwargs.get('date', 'none'),
			'language': kwargs.get('language', framework.__language__),
			'server_key': kwargs.get('server_key', 'none'),
			'login': {},
			'create': {},
			'level': {},
			'vip': {},
			'gain': {},
			'cost': {},
		}

	def set(self, role_id, detailDs, level=None, vip=None, create=None):
		if detailDs not in self.login:
			self.login[detailDs] = []
		if role_id not in self.login[detailDs]:
			self.login[detailDs].append(role_id)

		if create:
			if detailDs not in self.create:
				self.create[detailDs] = []
			if role_id not in self.create[detailDs]:
				self.create[detailDs].append(role_id)
		if level:
			if level not in self.level:
				self.level[level] = []
			if role_id not in self.level[level]:
				self.level[level].append(role_id)
		if vip:
			if vip not in self.vip:
				self.vip[vip] = []
			if role_id not in self.vip[vip]:
				self.vip[vip].append(role_id)

	def addRecord(self, other):

		def _add(n, o):
			for k in o:
				if k not in n:
					n[k] = []
				n[k] = list(set(n[k] + o[k]))

		_add(self.level, other.level)
		_add(self.vip, other.vip)
		_add(self.login, other.login)
		_add(self.create, other.create)

	# 计算留存
	def retentionRateWith(self, future):
		create = set([])
		login = set([])
		for k in self.create:
			create |= set(self.create[k])
		for k in future.login:
			login |= set(future.login[k])
		retention = len(create & login)
		return retention, 100.0 * retention / max(1, len(create))

	@property
	def sum(self):
		create = set([])
		login = set([])
		for k in self.create:
			create |= set(self.create[k])
		for k in self.login:
			login |= set(self.login[k])
		return {
			"create": len(create),
			"login": len(login)
		}


# LogItemArchive
class DBLogItemArchive(DBRecord):
	Collection = 'LogItemArchive'
	Indexes = [
		{
			"index": [
				("date", 1),
				("language", 1),
				("server_key", 1),
				("from_key", 1)
			],
			"unique": True,
		},
		{"index": "date"},
		{"index": "server_key"},
		{"index": "from_key"},
		{"index": "language"},
	]

	@property
	def uniqueKey(self):
		return (self.date, self.language, self.server_key, self.from_key)

	@staticmethod
	def uniqueKeyFromQuery(d):
		return (d['date'], d['language'], d['server_key'], d['from_key'])

	@staticmethod
	def defaultDocument(**kwargs):
		return {
			'date': kwargs.get('date') or 'none',
			'language': kwargs.get('language') or framework.__language__,
			'server_key': kwargs.get('server_key') or 'none',
			'from_key': kwargs.get('from_key') or 'none',
			'gain': kwargs.get('gain') or {},
			'cost': kwargs.get('cost') or {},
		}

	def set(self, t, detailDs, dic, role_id):
		if t == 'gain':
			r = self.gain
		elif t == 'cost':
			r = self.cost
		else:
			print '!! err t %s'% t
			return

		if detailDs not in r:
			r[detailDs] = {}

		# Number of statistics
		if '__count__' not in r[detailDs]:
			r[detailDs]['__count__'] = 0
		r[detailDs]['__count__'] += 1

		# People Counting
		if '__participation__' not in r[detailDs]:
			r[detailDs]['__participation__'] = []
		if role_id not in r[detailDs]['__participation__']:
			r[detailDs]['__participation__'].append(role_id)

		for k, v in dic.items():

			# Skip these two statistics
			if k == "carddbIDs" or k == "heldItemdbIDs":
				continue

			elif k == "gold" or k == "rmb":
				if k not in r[detailDs]:
					r[detailDs][k] = 0

				try:
					r[detailDs][k] += v
				except Exception as e:
					print '!! error k: %s, v: %s %s'% (k, v, type(v))
					print e
					continue

			elif k == "items" and isinstance(v, list):
				for item in v:
					try:
						classifyName = self.classifyGameItem(item[0])
						if classifyName is None:
							continue
						if classifyName not in r[detailDs]:
							r[detailDs][classifyName] = r"{}"
						r[detailDs][classifyName] = self._convert(r[detailDs][classifyName], item[0], item[1])

					except Exception as e:
						print '!! error item: %s'% item
						print e

			elif isinstance(k, int):
				classifyName = self.classifyGameItem(k)
				if classifyName not in r[detailDs]:
					r[detailDs][classifyName] = r"{}"
				r[detailDs][classifyName] = self._convert(r[detailDs][classifyName], k, v)

			elif isinstance(k, (unicode, str)):
				if k.startswith('coin'):
					if 'coins' not in r[detailDs]:
						r[detailDs]['coins'] = r"{}"
					r[detailDs]['coins'] = self._convert(r[detailDs]['coins'], k, v)

				else:
					if k not in r[detailDs]:
						r[detailDs][k] = "[]"
					r[detailDs][k] = self._convert(r[detailDs][k], k, v)

			else:
				print '!! error dic key: %s %s'% (k, type(k))
				continue

	def _convert(self, src, k, v):
		obj = ast.literal_eval(src)
		if isinstance(obj, dict) and isinstance(v, int):
			if k not in obj:
				obj[k] = v
			else:
				obj[k] += v
		elif isinstance(obj, list):
			obj.append(v)
		else:
			print '!! error src, k, v: %s %s %s'% (src, k,)

		return str(obj)

	def classifyGameItem(self, k):
		if not isinstance(k, int):
			return None

		if k <= 10000:
			name = 'Items'
		elif 10000 < k <= 20000:
			name = 'Equips'
		elif 20000 < k <= 30000:
			name = 'Fragments'
		elif 30000 < k <= 40000:
			name = 'MetalOrHeldItem'
		else:
			name = 'Unknown'
		return name
