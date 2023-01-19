#!/usr/bin/python
# -*- coding: utf-8 -*-
# 测试用SDK

from framework.log import logger
from payment.sdk.base import SDKBase

import urlparse
import binascii


class SDKTest(SDKBase):
	Channel = 'sdktest'
	ReturnOK = 'ok'
	ReturnErr = 'error'

	@classmethod
	def parseData(cls, cfg, data):
		d = dict(urlparse.parse_qsl(data))
		logger.info('channel `{channel}` status `{OrderStatus}` order `{OrderSerial}` {OrderMoney} coming'.format(channel=cls.Channel, **d))
		return d

	@classmethod
	def getOrderID(cls, d):
		return d['OrderSerial']

	@classmethod
	def getOrderResult(cls, d):
		return True if int(d["OrderStatus"]) == 1 else False

	@classmethod
	def getClientInfo(cls, d):
		ret = d['ExtInfo'].split(",")
		ret[0] = binascii.unhexlify(ret[0])
		ret[1] = binascii.unhexlify(ret[1])
		return ret

	@classmethod
	def getOrderAmount(cls, d):
		return d['OrderMoney']

	@classmethod
	def getOrderErrMsg(cls, d):
		return d['StatusMsg']

