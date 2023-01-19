#!/usr/bin/python
# -*- coding: utf-8 -*-

from framework.log import logger
from framework.helper import toUTF8Dict
from tornado.gen import coroutine, Return
from payment.sdk.base import SDKBase

import json
import time
import base64
import urllib
import hashlib
import urlparse

# Return返回值
# AppID = 6231661
# ResultCode = 1
# SecretKey = '34aG7jzN2zKcbsHbfHXIGOpEMPmPN0V6'
# Sign = hashlib.md5(str(AppID)+str(ResultCode)+SecretKey).hexdigest()
# print json.dumps({'AppID': AppID, 'ResultCode': ResultCode, 'ResultMsg': '', 'Sign': Sign})


class SDKBaidu(SDKBase):
	Channel = 'baidu'
	ReturnOK = '{"ResultCode": 1, "ResultMsg": "ok", "Sign": "32e61f8749825b00983c1e75bedf2c77", "AppID": 6231661}'
	ReturnErr = '{"ResultCode": 0, "ResultMsg": "err", "Sign": "8bed4527a168cfefa3261bf7611ddc48", "AppID": 6231661}'

	@classmethod
	def parseData(cls, cfg, data):
		d = dict(urlparse.parse_qsl(data))
		content = urllib.unquote(d['Content'])

		dd = json.loads(base64.b64decode(content), object_hook=toUTF8Dict)
		dd['OrderSerial'] = d['OrderSerial']

		logger.info('channel `{channel}` ch_account `{UID}` status `{OrderStatus}` order `{OrderSerial}` {OrderMoney} coming'.format(channel=cls.Channel, **dd))

		validSign = hashlib.md5('{AppID}{OrderSerial}{CooperatorOrderSerial}{content}{appsecret}'.format(appsecret=cfg['appsecret'], content=content, **d)).hexdigest()

		if validSign != d['Sign']:
			logger.error('%s sign error %s', cls.Channel, data)
			raise Exception('sign error')

		return dd

	@classmethod
	def getOrderID(cls, d):
		return d['OrderSerial']

	@classmethod
	def getOrderResult(cls, d):
		return True if d['OrderStatus'] == 1 else False

	@classmethod
	def getClientInfo(cls, d):
		return d['ExtInfo']

	@classmethod
	def getOrderAmount(cls, d):
		return d['OrderMoney']

	@classmethod
	def getOrderErrMsg(cls, d):
		return d['StatusMsg']

