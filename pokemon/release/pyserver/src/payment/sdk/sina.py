#!/usr/bin/python
# -*- coding: utf-8 -*-

from framework.log import logger
from framework.helper import toUTF8Dict
from tornado.gen import coroutine, Return
from payment.sdk.base import SDKBase

import hashlib
import urlparse


class SDKSina(SDKBase):
	Channel = 'sina'
	ReturnOK = 'OK'
	ReturnErr = 'ERR'

	@classmethod
	def parseData(cls, cfg, data):
		d = dict(urlparse.parse_qsl(data))
		logger.info('channel `{channel}` ch_account `{order_uid}` status `true` order `{order_id}` {actual_amount} coming'.format(channel=cls.Channel, **d))

		validSign = d.keys()
		if 'signature' in d:
			validSign.remove('signature')
		validSign.sort()
		validSign = '|'.join(['%s|{%s}' % (x, x) for x in validSign]).format(**d)
		validSign = hashlib.sha1('%s|%s' % (validSign, cfg['appsecret'])).hexdigest()

		if validSign != d['signature']:
			logger.error('%s sign error %s', cls.Channel, data)
			raise Exception('sign error')

		return d

	@classmethod
	def getOrderID(cls, d):
		return d['order_id']

	@classmethod
	def getOrderResult(cls, d):
		return True

	@classmethod
	def getClientInfo(cls, d):
		return d['pt']

	@classmethod
	def getOrderAmount(cls, d):
		# 支付金额,单位为分,即0.01 米币
		return float(d['actual_amount']) / 100.

	@classmethod
	def getOrderErrMsg(cls, d):
		return d.get('error', '')


