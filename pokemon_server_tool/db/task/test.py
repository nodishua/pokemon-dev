#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2014 YouMi Information Technology Inc.

'''

import db.scheme.account as DBSA
import db.redisorm as DBORM
from db.task import RPCTaskFactory

import datetime
import time

class TTestFactory(RPCTaskFactory):
	def _hello(self, data):
		print data, 'say hello to DBRPCServer'
		return 'DBRPCServer say hello'

	def testSleep(self, data):
		print 'testSleep', time.time(), data
		time.sleep(2)
		return 'i sleep 2s'