#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2014 YouMi Information Technology Inc.
'''

import db.scheme.game as DBSG
import db.redisorm as DBORM
from framework.helper import toMsgpackDict

from mprpc import RPCServer


class DBRPCServer(object):

	@property
	def redis(self):
		return self.server.redis

	# def __init__(self, containServ):
	# 	self.server = containServ

	def TestBenchmarkSave(self, data):
		import os
		import random
		import binascii

		print time.time(),'hello TestBenchmarkSave'

		role = DBSG.Role(account_id = random.randint(1, 9999), name = 'test'+ binascii.hexlify(str(random.randint(1, 9999))))
		try:
			role.save()
			ret = toMsgpackDict(role.to_dict())
			ret.update({'ret':True})

		except DBORM.ORMError, e:
			ret = {'ret':False, 'err':str(e), 'err_type':type(e).__name__}

		return ['server TestBenchmark', data, str(self.redis), ret]


	def TestBenchmarkGet(self, data):
		import time
		import random
		import binascii

		print time.time(), 'hello TestBenchmarkGet', data
		if data == 'begin':
			random.seed(12345)
			# role = DBSG.Role(account_id = 1234567890, name = 'test1234567890')
			# role.save()
			return ['server TestBenchmarkGet', str(self.redis)]

		role = DBSG.Role.get_by(account_id = random.randint(1, 10000))
		# role = DBSG.Role.get_by(name = 'test' +binascii.hexlify(str(random.randint(1, 10000))) )
		
		if role:
			if isinstance(role, list):
				ret = toMsgpackDict(role[0].to_dict())
			else:
				ret = toMsgpackDict(role.to_dict())
		else:
			ret = None

		return ['server TestBenchmarkGet', str(self.redis), ret]