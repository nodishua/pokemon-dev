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


class SDKApple(SDKBase):
	Channel = 'apple'
	ReturnOK = '0'
	ReturnErr = '-1'
	HttpClient = None

	@classmethod
	def parseData(cls, cfg, data):
		d = json.loads(data, object_hook=toUTF8Dict)
		apple = d['apple']
		appleD = json.loads(apple, object_hook=toUTF8Dict)
		d['apple'] = appleD
		d['apple_sandbox'] = (data.find('Sandbox') >= 0)

		sign = hashlib.md5("{time}{channel}{account}{servkey}{role}{productid}{applejson}youmi".format(applejson=apple, **d)).hexdigest()

		if sign != d['sign']:
			logger.error('%s sign error %s', cls.Channel, d)
			raise Exception('sign error')

		return d

	@classmethod
	@coroutine
	def verifyReceipt(cls, cfg, d):
		# https://developer.apple.com/library/ios/releasenotes/General/ValidateAppStoreReceipt/Chapters/ValidateRemotely.html#//apple_ref/doc/uid/TP40010573-CH104-SW1
		sdkReq = {
			'receipt-data': base64.b64encode(d['apple']['receipt']),
		}

		try:
			# print json.dumps(sdkReq)
			urlKey = 'sandbox_receiptURL' if d['apple_sandbox'] else 'receiptURL'
			response = yield cls.HttpClient.fetch(cfg[urlKey], method="POST", body=json.dumps(sdkReq))
		except:
			cls.initHttpClient()
			raise

		if response.error:
			raise Exception('%s sdk create order error %s' % (cls.Channel, response.error))
		else:
			# debug
			# print cls.Channel, 'return', response.body
			dd = json.loads(response.body, object_hook=toUTF8Dict)
			d.update(dd)
			d['productid'] = int(d['receipt']['product_id'].split('_')[1])

			logger.info('channel `{channel}` ch_account `` status `{status}` order `{transaction_id}` {product_id} coming'.format(channel=cls.Channel, status=d['status'], **d['receipt']))

			if dd['status'] == 0:
				pass
			else:
				raise Exception(dd['status'])

	@classmethod
	def getOrderID(cls, d):
		return d['receipt']['transaction_id']

	@classmethod
	def getOrderResult(cls, d):
		return True if d['status'] == 0 else False

	@classmethod
	def getClientInfo(cls, d):
		return (d['account'], d['role'], d['servkey'], d['productid'])

	@classmethod
	def getOrderAmount(cls, d):
		return 0

	@classmethod
	def getOrderErrMsg(cls, d):
		return d['status']

	@classmethod
	def getReturnOK(cls, d):
		return d['apple']['arrayIndex']

