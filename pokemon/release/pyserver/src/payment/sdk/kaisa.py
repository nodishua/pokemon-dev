#!/usr/bin/python
# -*- coding: utf-8 -*-

from framework.log import logger
from framework.helper import toUTF8Dict
from tornado.gen import coroutine
from payment.sdk.base import SDKBase
from payment.clientdata import ClientData

import json
import hashlib
import urlparse
import base64

RechargeMap = {
	1: 4.99,
	2: 12.99,

	102: 0.99,
	103: 1.99,
	104: 2.99,
	105: 3.99,
	106: 4.99,
	107: 8.99,
	108: 14.99,
	109: 19.99,
	110: 25.99,
	111: 29.99,
	112: 49.99,
	113: 99.99,

	1101: 0.99,
	1102: 1.99,
	1103: 2.99,
	1104: 3.99,
	1105: 4.99,
	1106: 8.99,
	1107: 12.99,
	1108: 14.99,
	1109: 19.99,
	1110: 25.99,
	1111: 29.99,
	1112: 49.99,
	1113: 99.99,
}

class SDKKaisa(SDKBase):
	Channel = 'ks'
	ReturnOK = json.dumps({"state": 1, "msg": "成功"})
	ReturnErr = json.dumps({"state": 0, "msg": "fail"})
	HttpClient = None

	@classmethod
	def parseData(cls, cfg, data):
		d = dict(urlparse.parse_qsl(data))
		logger.info('channel `{channel}` ch_account `{uid}` status `True` order `{oid}` coming'.format(channel=cls.Channel, **d))

		sign = d['time'] + cfg['ks_key2'] + d['oid'] + d['doid'] + d['dsid'] + d['uid'] + d['money'] + d['coin']
		sign = hashlib.md5(sign).hexdigest()
		if sign != d['sign']:
			logger.error('%s sign error %s', cls.Channel, data)
			raise Exception('sign error')
		return d

	@classmethod
	def getOrderResult(cls, d):
		return True

	@classmethod
	def getOrderID(cls, d):
		return d['oid']

	@classmethod
	def getClientInfo(cls, d):
		if d['dext'][0] == '[' and d['dext'][-1] == ']':
			 data = d['dext']
		else:
			data = base64.b64decode(d['dext'])

		cdata = ClientData(data)

		if float(d['money']) != float(RechargeMap[cdata.rechargeID]):
			logger.error('%s %s recharge amount error', cls.Channel, cls.getOrderID(d))
			return None
		return data

	@classmethod
	def getOrderAmount(cls, d):
		return float(d['money'])

	@classmethod
	def getOrderErrMsg(cls, d):
		return ''