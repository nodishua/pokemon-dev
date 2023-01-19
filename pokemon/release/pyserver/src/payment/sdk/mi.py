#!/usr/bin/python
# -*- coding: utf-8 -*-

from framework.log import logger
from framework.helper import toUTF8Dict
from tornado.gen import coroutine, Return
from payment.sdk.base import SDKBase

import hmac
import hashlib
import urlparse


class SDKMi(SDKBase):
	Channel = 'mi'
	ReturnOK = '{"errcode": "200"}'
	ReturnErr = '{"errcode": "1525"}'

	@classmethod
	def parseData(cls, cfg, data):
		d = dict(urlparse.parse_qsl(data))
		logger.info('channel `{channel}` ch_account `{uid}` status `{orderStatus}` order `{orderId}` {payFee} coming'.format(channel=cls.Channel, **d))

		validSign = d.keys()
		if 'signature' in d:
			validSign.remove('signature')
		validSign.sort()
		validSign = '&'.join(['%s={%s}' % (x, x) for x in validSign]).format(**d)
		validSign = hmac.new(cfg['appsecret'], validSign, hashlib.sha1).hexdigest()

		if validSign != d['signature']:
			logger.error('%s sign error %s', cls.Channel, data)
			raise Exception('sign error')

		return d

	@classmethod
	def getOrderID(cls, d):
		return d['orderId']

	@classmethod
	def getOrderResult(cls, d):
		return True if d['orderStatus'] == 'TRADE_SUCCESS' else False

	@classmethod
	def getClientInfo(cls, d):
		return d['cpUserInfo']

	@classmethod
	def getOrderAmount(cls, d):
		# 支付金额,单位为分,即0.01 米币
		return float(d['payFee']) / 100.

	@classmethod
	def getOrderErrMsg(cls, d):
		return d['orderStatus']


# com.youmi.blbxz.mi
class SDKMi_blbxz(SDKMi):
	Channel = 'mi_blbxz'
	ReturnOK = '{"errcode": "200"}'
	ReturnErr = '{"errcode": "1525"}'
