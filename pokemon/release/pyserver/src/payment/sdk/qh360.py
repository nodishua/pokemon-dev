#!/usr/bin/python
# -*- coding: utf-8 -*-

from framework.log import logger
from framework.helper import toUTF8Dict
from tornado.gen import coroutine, Return
from payment.sdk.base import SDKBase

import json
import time
import hashlib
import urlparse


class SDK360(SDKBase):
	Channel = '360'
	ReturnOK = 'ok'
	ReturnErr = 'err'

	@classmethod
	def parseData(cls, cfg, data):
		d = dict(urlparse.parse_qsl(data))
		logger.info('channel `{channel}` ch_account `{user_id}` status `{gateway_flag}` order `{order_id}` {amount} coming'.format(channel=cls.Channel, **d))

		validSign = '{amount}#{app_ext1}#{app_ext2}#{app_key}#{app_order_id}#{app_uid}#{gateway_flag}#{order_id}#{product_id}#{sign_type}#{user_id}#{appsecret}'.format(appsecret=cfg['appsecret'], **d)
		validSign = hashlib.md5(validSign).hexdigest()

		if validSign != d['sign']:
			logger.error('%s sign error %s', cls.Channel, data)
			raise Exception('sign error')

		return d

	@classmethod
	def getOrderID(cls, d):
		return d['order_id']

	@classmethod
	def getOrderResult(cls, d):
		return True if d['gateway_flag'] == 'success' else False

	@classmethod
	def getClientInfo(cls, d):
		return d['app_ext1']

	@classmethod
	def getOrderAmount(cls, d):
		# 360是分为单位，默认是元为单位
		return float(d['amount']) / 100.

	@classmethod
	def getOrderErrMsg(cls, d):
		return d['gateway_flag']
