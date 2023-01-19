#!/usr/bin/python
# -*- coding: utf-8 -*-

from framework.log import logger
from framework.helper import toUTF8Dict, objectid2string
from tornado.gen import coroutine, Return
from payment.sdk.base import SDKBase

import json
import time
import hashlib
import urlparse

class SDKTest(SDKBase):
	Channel = 'test'
	ReturnOK = '{"ret":0,"data":"Ok"}'
	ReturnErr = '{"ret":-1,"data":"Err"}'

	@classmethod
	def parseData(cls, cfg, data):
		d = dict(urlparse.parse_qsl(data))
		logger.info('channel `{channel}` ch_account `{account}` status `{orderStatus}` order `{orderId}` {amount} coming'.format(channel=cls.Channel, account=objectid2string(d['accountId']), **d))
		return d

	@classmethod
	def getOrderID(cls, d):
		return d['orderId']

	@classmethod
	def getOrderResult(cls, d):
		return True if int(d["orderStatus"]) == 1 else False

	@classmethod
	def getClientInfo(cls, d):
		return d['game_extra']

	@classmethod
	def getOrderAmount(cls, d):
		return d['amount']

	@classmethod
	def getOrderErrMsg(cls, d):
		return ""

	@classmethod
	@coroutine
	def fetchChannelOrderID(cls, cfg, d, myOrderID):
		raise Exception('not implemented')

	@classmethod
	def makeReturnDict(cls, myOrderID, d):
		raise Exception('not implemented')
