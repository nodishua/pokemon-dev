#!/usr/bin/python
# -*- coding: utf-8 -*-

from framework.log import logger
from framework.helper import toUTF8Dict
from tornado.gen import coroutine, Return
from payment.sdk.base import SDKBase

import hashlib
import urlparse


class SDKOuwan(SDKBase):
	Channel = 'ouwan'
	ReturnOK = 'success'
	ReturnErr = 'error'

	@classmethod
	def parseData(cls, cfg, data):
		d = dict(urlparse.parse_qsl(data, keep_blank_values=True))
		logger.info('channel `{channel}` ch_account `{openid}` status `{order_status}` order `{order_id}` {money} coming'.format(channel=cls.Channel, **d))

		validSign = d.keys()
		if 'sign' in d:
			validSign.remove('sign')
		validSign.sort()
		validSign = ''.join(['%s={%s}' % (x, x) for x in validSign]).format(**d)
		validSign = hashlib.md5(validSign + cfg['server_secret']).hexdigest()

		if validSign != d['sign']:
			logger.error('%s sign error %s', cls.Channel, data)
			raise Exception('sign error')

		return d

	@classmethod
	def getOrderID(cls, d):
		return d['order_id']

	@classmethod
	def getOrderResult(cls, d):
		return True if d['order_status'] == '1' else False

	@classmethod
	def getClientInfo(cls, d):
		return d['callback']

	@classmethod
	def getOrderAmount(cls, d):
		# 实际到账的人民币金额（单位人民币分）
		return float(d['money']) / 100.

	@classmethod
	def getOrderErrMsg(cls, d):
		return d['remark']


# com.youmi.blbxz.ouwan
class SDKOuwan_blbxz(SDKOuwan):
	Channel = 'ouwan_blbxz'
	ReturnOK = 'success'
	ReturnErr = 'error'
	HttpClient = None
