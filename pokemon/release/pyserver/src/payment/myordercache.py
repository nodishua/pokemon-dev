#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2015 YouMi Information Technology Inc.
'''

import time


class MyOrderCache(object):
	def __init__(self):
		self._d = {}
		self._nl = []
		self._npop = 0

	def add(self, myOrderID, order, t, uid, rid, skey, pid, yyid, csvid):
		t = float(t)
		uid, rid, pid, yyid, csvid = int(uid), int(rid), int(pid), int(yyid), int(csvid)
		self._d[myOrderID] = (order, t, uid, rid, skey, pid, yyid, csvid)
		self._nl.append(myOrderID)

	def addByDict(self, myOrderID, order, d):
		skey = d['servkey']
		uid, rid, pid = int(d['account']), int(d['role']), int(d['productid'])
		yyid, csvid = int(d['yyid']), int(d['csvid'])
		self._d[myOrderID] = (order, time.time(), uid, rid, skey, pid, yyid, csvid)
		self._nl.append(myOrderID)

	def get(self, myOrderID):
		return self._d.get(myOrderID)

	def pop(self, myOrderID):
		self._npop += 1
		return self._d.pop(myOrderID)

	def markFlush(self):
		self._nl = []
		self._npop = 0

	def needFlush(self):
		return self._npop - len(self._nl) > len(self._d)

	def getNeedSave(self):
		ret = []
		for k in self._nl:
			if k in self._d:
				ret.append((k, self._d[k]))
		self._nl = []
		return ret

	def __len__(self):
		return len(self._d)

	def __contains__(self, myOrderID):
		return myOrderID in self._d

	def iteritems(self):
		return self._d.iteritems()

	@staticmethod
	def decodeDB(s):
		return s.split(',')

	@staticmethod
	def encodeDB(t):
		return ','.join([str(x) for x in t])

	@staticmethod
	def isOutOfTimeLimit(t, endT):
		if isinstance(t, (tuple, list)):
			return float(t[1]) < endT
		return float(t) < endT