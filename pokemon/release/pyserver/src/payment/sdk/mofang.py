#!/usr/bin/python
# -*- coding: utf-8 -*-

from framework import nowtime_t
from framework.log import logger
from framework.helper import toUTF8Dict
from tornado.gen import coroutine, Return
from tornado.curl_httpclient import CurlAsyncHTTPClient
from payment.sdk.base import SDKBase
from payment.sdk import channelOrderID
from payment.clientdata import ClientData

import os
import json
import time
import urllib
import hashlib
import binascii
import urlparse

DealPriceMap = {
	"99.99": 3,
	"48.99": 4,
	"28.99": 5,
	"14.99": 6,
	"9.99": 7,
	"4.99": 8,
	"0.99": 9,
}


class SDKMofangAY(SDKBase):
	Channel = 'mofang_ay'
	HttpClient = None

	@classmethod
	def parseData(cls, cfg, data):
		d = dict(urlparse.parse_qsl(data))
		appid = str(d['appid'])
		appkey = cfg['apps'].get(appid, '')
		logger.info('channel `{channel}` ch_account `{uid}` status order `{orderId}` {dealPrice} coming'.format(channel=cls.Channel, **d))

		sign = hashlib.md5("appid={appid}&dealPrice={dealPrice}&extInfo={extInfo}&orderId={orderId}&productId={productId}&productName={productName}&productNum={productNum}&uid={uid}{appkey}".format(appkey=appkey, **d)).hexdigest()
		if sign != d['sign']:
			logger.error('%s sign error %s', cls.Channel, data)
			raise Exception('sign error')

		return d

	@classmethod
	@coroutine
	def closeCallback(cls, cfg, data):
		d = dict(urlparse.parse_qsl(data))
		appid = str(d['appid'])
		sdkReq = {
			'appid': appid,
			'order': d['orderId'],
		}
		try:
			fu = cls.HttpClient.fetch('%s?%s' % (cfg['closeURL'], urllib.urlencode(sdkReq)), method="GET", request_timeout=2)

			def _done(fu):
				try:
					ok = fu.result()
					logger.info('%s %s close ok', cls.Channel, sdkReq)
				except:
					logger.exception('%s %s close err', cls.Channel, sdkReq)
			fu.add_done_callback(_done)

		except:
			logger.exception('%s %s fetch err', cls.Channel, sdkReq)
			cls.initHttpClient()
			# 无所谓成功失败，通知即可

	@classmethod
	def getOrderID(cls, d):
		return d['orderId']

	@classmethod
	def getOrderResult(cls, d):
	    return True

	@classmethod
	def getClientInfo(cls, d):
		s = d['extInfo'].replace("_-", '"').replace("-_", ',')
		ret = json.loads(s, object_hook=toUTF8Dict)
		# mofang的extinfo数据不可信，用dealPrice转一下
		if d['dealPrice'] in DealPriceMap:
			ret[-1] = DealPriceMap[d['dealPrice']]
		return ret

	@classmethod
	def getOrderAmount(cls, d):
		return d['dealPrice']

	@classmethod
	def getOrderErrMsg(cls, d):
		return ""


class SDKMofangAF(SDKMofangAY):
	Channel = 'mofang_af'
	HttpClient = None

class SDKMofangIY(SDKMofangAY):
	Channel = 'mofang_iy'
	HttpClient = None

class SDKMofangIF(SDKMofangAY):
	Channel = 'mofang_if'
	HttpClient = None
