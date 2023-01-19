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
import urlparse


class SDKLJ(SDKBase):
	Channel = 'lj'
	ReturnOK = 'success'
	ReturnErr = 'fail'

	@classmethod
	def parseData(cls, cfg, data):
		d = dict(urlparse.parse_qsl(data))
		logger.info('channel `{channelLabel}` ch_account `` status `true` order `{orderId}` {price} coming'.format(**d))
		# 棱镜有两个sign
		validSign = hashlib.md5('{orderId}{price}{callbackInfo}{productSecret}'.format(productSecret=cfg['productSecret'], **d)).hexdigest()
		if validSign != d['sign']:
		    logger.error('%s sign error %s', d['channelLabel'], d)
		    raise Exception('sign error')
		
		sign2 = hashlib.md5('callbackInfo={callbackInfo}&channelCode={channelCode}&channelLabel={channelLabel}&channelOrderId={channelOrderId}&freePrice={freePrice}&orderId={orderId}&price={price}&sdkCode={sdkCode}&version={version}&{productSecret}'.format(productSecret=cfg['productSecret'], **d)).hexdigest()
		if sign2 != d['sign2']:
		    logger.error('%s sign error %s', d['channelLabel'], d)
		    raise Exception('sign error')

		return d

	@classmethod
	def getChannel(cls, d):
		return d.get('channelLabel', cls.Channel)

	@classmethod
	def getOrderID(cls, d):
		return d['orderId']

	@classmethod
	def getOrderResult(cls, d):
		return True

	@classmethod
	def getClientInfo(cls, d):
		return base64.b64decode(d['callbackInfo'])

	@classmethod
	def getOrderAmount(cls, d):
		# 充值金额，整数，单位分
		return (float(d['price']) + float(d['freePrice'])) / 100.

	@classmethod
	def getOrderErrMsg(cls, d):
		return 'none'

	# 废弃
	# @classmethod
	# @coroutine
	# def payCallback(cls, handler, GET=True):
	# 	cfg = handler.application.sdkConfig[cls.Channel]
	# 	data = {k: v[-1] for k, v in handler.request.arguments.iteritems()}
	# 	ret = yield cls.recordPay(cfg, data, handler.application.myOrderCache, handler.application.orderCache, handler.application.dbcPay, handler.application.payQueue)
	# 	raise Return(ret)

