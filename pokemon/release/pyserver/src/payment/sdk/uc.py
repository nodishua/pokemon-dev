#!/usr/bin/python
# -*- coding: utf-8 -*-

from framework.log import logger
from framework.helper import toUTF8Dict
from tornado.gen import coroutine, Return
from payment.sdk.base import SDKBase

import json
import time
import base64
import hashlib


class SDKUC(SDKBase):
	Channel = 'uc'
	ReturnOK = 'SUCCESS'
	ReturnErr = 'FAILURE'

	@classmethod
	def parseData(cls, cfg, data):
		d = json.loads(data, object_hook=toUTF8Dict)
		dd = d['data']
		logger.info('channel `{channel}` ch_account `{accountId}` status `{orderStatus}` order `{orderId}` {amount} coming'.format(channel=cls.Channel, **dd))

		validSign = 'accountId={accountId}amount={amount}callbackInfo={callbackInfo}cpOrderId={cpOrderId}creator={creator}failedDesc={failedDesc}gameId={gameId}orderId={orderId}orderStatus={orderStatus}payWay={payWay}{apiKey}'.format(apiKey=cfg['apiKey'], **dd)
		validSign = hashlib.md5(validSign).hexdigest()

		if validSign != d['sign']:
			logger.error('%s sign error %s', cls.Channel, data)
			raise Exception('sign error')

		return dd

	@classmethod
	def getOrderID(cls, d):
		return d['orderId']

	@classmethod
	def getOrderResult(cls, d):
		return True if d['orderStatus'] == 'S' else False

	@classmethod
	def getClientInfo(cls, d):
		return d['callbackInfo']

	@classmethod
	def getOrderAmount(cls, d):
		return d['amount']

	@classmethod
	def getOrderErrMsg(cls, d):
		return d['failedDesc']


	@classmethod
	@coroutine
	def recordCreate(cls, cfg, data, myOrderCache):
		# UC充值的sign需要服务器组装，这里是特殊写法，并不需要与SDK服务器交互
		d = json.loads(base64.b64decode(data))
		if cls.Channel != d.get('channel', ''):
			logger.error('%s channel error %s', cls.Channel, d.get('channel', ''))
			raise Exception('channel error')

		validSign = hashlib.md5('{time}{channel}{accountId}{serverId}{roleId}{callbackInfo}{signsecret}'.format(signsecret='youmi', **d)).hexdigest()

		if validSign != d['sign']:
			logger.error('%s sign error %s', cls.Channel, data)
			raise Exception('sign error')

		d.pop('time')
		d.pop('channel')
		d.pop('sign')
		d['sign'] = hashlib.md5(''.join(['%s=%s' % (k, d[k]) for k in sorted(d.keys())]) + cfg['apiKey']).hexdigest()
		d['signType'] = 'MD5'

		raise Return(json.dumps(d, ensure_ascii=False))