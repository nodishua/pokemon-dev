#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2014 YouMi Information Technology Inc.
Copyright (c) 2016 TianJi Information Technology Inc.
'''

from framework import nowtime2int, nowtime_t, todaydate2int
from framework.csv import csv
from framework.log import logger
from framework.object import ObjectDBase, db_property, ObjectCSVRange
from framework.distributed import ServiceDefs
from framework.distributed.helper import multi_future

from tornado.gen import coroutine, sleep
from tornado.concurrent import Future

from cross.globaldata import *

import copy
import random
import datetime


#
# ObjectCrossGlobal
#

class ObjectCrossGlobal(ObjectDBase):
	DBModel = 'CrossGlobal'

	Singleton = None

	def __init__(self, dbc):
		ObjectDBase.__init__(self, None, dbc)

		if ObjectCrossGlobal.Singleton is not None:
			raise ValueError('This is singleton object')
		ObjectCrossGlobal.Singleton = self

	def init(self, server):
		self.server = server

		# set service states
		self.server.reset_service_states(copy.deepcopy(self.services))

		return ObjectDBase.init(self)

	# 玩法状态 {service: str or list}
	# str  是通用服务
	# list 是指定服务
	def services():
		dbkey = 'services'
		def fget(self):
			return self.db[dbkey]
		def fset(self, value):
			self.db[dbkey] = value
			self.server.reset_service_states(value)
		return locals()
	services = db_property(**services())

	service_configs = db_property('service_configs')

	@classmethod
	def initServiceState(cls, service):
		self = cls.Singleton
		self.services[service] = ServiceDefs.Idle
		self.service_configs.pop(service, None)

	@classmethod
	def setServiceState(cls, service, state):
		self = cls.Singleton
		self.services[service] = state
		self.server.set_service_state(service, state)

	# idle or already
	@classmethod
	def isSerivceOK(cls, service, nodeKey):
		self = cls.Singleton
		if service not in self.services:
			return False
		strOrList = self.services[service]
		if isinstance(strOrList, (tuple, list)):
			return nodeKey in strOrList
		elif strOrList == ServiceDefs.Idle:
			return True
		return False

	# idle
	@classmethod
	def isSerivceIdle(cls, service):
		self = cls.Singleton
		if service not in self.services:
			return False
		strOrList = self.services[service]
		if isinstance(strOrList, (tuple, list)):
			return False
		elif strOrList == ServiceDefs.Idle:
			return True
		return False

	@classmethod
	@coroutine
	def onServiceCheck(cls):
		self = cls.Singleton
		csv.reload()

		logger.info('onServiceCheck %s, %s', self.services, self.service_configs)

		dt = datetime.datetime.now()
		#　②. 跨服王者之战每周举行2次，分别为周一和周五
		craftStart = dt.isoweekday() in CrossCraftStartWeakDay
		# DEBUG:
		# craftStart = True

		# cross需要处理协商过程
		ignore = set()
		keys = []
		for idx in csv.cross.service:
			cfg = csv.cross.service[idx]
			if cfg.cross == '' or cfg.cross == self.server.key:
				keys.append(idx)

		while len(ignore) < len(keys):
			query = {}
			newkeys = list(set(keys) - set(ignore)) + list(ignore)
			for idx in newkeys:
				cfg = csv.cross.service[idx]
				if cfg.service in query:
					continue

				ignore.add(cfg.id)
				if cfg.date != todaydate2int():
					continue
				if self.services.get(cfg.service, None) != ServiceDefs.Idle:
					continue

				if craftStart and cfg.service == 'craft':
					fu = self.server.transaction_commit(cfg.servers, cfg.service)
					query[cfg.service] = (cfg.id, fu)

			yield sleep(1)
			if query:
				query = {(s, t[0]): t[1] for s, t in query.iteritems()}
				result = yield multi_future(query) # raise -> Exception
				for t, ret in result.iteritems():
					cfg = csv.cross.service[t[1]]
					ignore.add(cfg.id)
					if isinstance(ret, Exception):
						ignore.discard(cfg.id)
					else:
						logger.info('transaction_commit %s %s', t, ret)
						if ret:
							self._onServiceStart(cfg)
			else:
				break

		logger.info('onServiceCheck finished')

	def _onServiceStart(self, cfg):
		self.service_configs[cfg.service] = cfg.id
		self.setServiceState(cfg.service, cfg.servers)

		if cfg.service == ServiceDefs.Craft:
			from cross.object.craft_gglobal import ObjectCrossCraftServiceGlobal
			ObjectCrossCraftServiceGlobal.Singleton.onInit(cfg.id, cfg.servers)
