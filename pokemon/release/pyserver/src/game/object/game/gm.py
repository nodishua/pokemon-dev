#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2014 YouMi Information Technology Inc.
'''

from __future__ import absolute_import

from framework import todaydate2int, nowtime_t
from framework.csv import Csv
from framework.object import ObjectDBase, db_property, ObjectNoGCDBase

import time
import copy


# src update to dst
def updateDict(src, dst):
	for k, v in src.iteritems():
		vv = dst.get(k, None)
		if isinstance(vv, dict):
			dst[k] = updateDict(v, vv)
		else:
			dst[k] = v
	return dst

#
# ObjectGMYYConfig
#

class ObjectGMYYConfig(ObjectNoGCDBase):
	'''
	GMYYConfig是公共对象，不进行GC
	'''
	DBModel = 'GMYYConfig'

	Singleton = None

	def __init__(self, dbc):
		ObjectDBase.__init__(self, None, dbc)
		self._cache = None
		self._cacheVersion = 0
		self._csvVersion = 0

		ObjectGMYYConfig.Singleton = self

	@classmethod
	def isNewCsvModel(cls, ver):
		self = cls.Singleton
		if self._csvVersion != Csv.Version or self._cache is None:
			return True
		elif self._cacheVersion > ver:
			return True
		return False

	@classmethod
	def getCsvModel(cls):
		self = cls.Singleton
		if self._csvVersion != Csv.Version or self._cache is None:
			self._csvVersion = Csv.Version
			self._cacheVersion = int(time.time() - 1400000000)
			d = copy.deepcopy(Csv.DictCache)
			dd = d['yunying']
			updateDict(self.yyhuodong, dd['yyhuodong'])
			updateDict(self.login_weal, dd['loginweal'])
			updateDict(self.level_award, dd['levelaward'])
			updateDict(self.recharge_gift, dd['rechargegift'])
			updateDict(self.placard, dd['placard'])
			self._cache = {
				'version': self._cacheVersion,
				'data': d,
			}
		return self._cache

	# yyhuodong.csv的在线配置
	def yyhuodong():
		dbkey = 'yyhuodong'
		def fset(self, value):
			self.db[dbkey] = value
			self._cache = None
		return locals()
	yyhuodong = db_property(**yyhuodong())

	# loginweal.csv的在线配置
	def login_weal():
		dbkey = 'login_weal'
		def fset(self, value):
			self.db[dbkey] = value
			self._cache = None
		return locals()
	login_weal = db_property(**login_weal())

	# level_award.csv的在线配置
	def level_award():
		dbkey = 'level_award'
		def fset(self, value):
			self.db[dbkey] = value
			self._cache = None
		return locals()
	level_award = db_property(**level_award())

	# recharge_gift.csv的在线配置
	def recharge_gift():
		dbkey = 'recharge_gift'
		def fset(self, value):
			self.db[dbkey] = value
			self._cache = None
		return locals()
	recharge_gift = db_property(**recharge_gift())

	# placard.csv的在线配置
	def placard():
		dbkey = 'placard'
		def fset(self, value):
			self.db[dbkey] = value
			self._cache = None
		return locals()
	placard = db_property(**placard())



