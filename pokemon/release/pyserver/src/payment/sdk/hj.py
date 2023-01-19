#!/usr/bin/python
# -*- coding: utf-8 -*-

from framework.log import logger
from framework.helper import toUTF8Dict
from tornado.gen import coroutine, Return
from tornado.web import HTTPError
from payment_defines import PayNotifyHost
from payment.sdk.base import SDKBase

from HJNotify.HJNotifyProxy import HJNotifyProxy

import json
import time
import base64
import urllib
import hashlib
import M2Crypto


class SDKHardCore(SDKBase):
	Channel = 'hj'
	ReturnOK = 'success'
	ReturnErr = 'fail'

	@classmethod
	def parseData(cls, cfg, data):
		channelInstance = HJNotifyProxy.getChannelInstance(cls.Channel)
		if channelInstance:
			retData = channelInstance.invokeService(data)
			if retData:
				# userNo不一定是渠道用户唯一标示，可能是昵称或者AppID
				logger.info('channel `{channel}` ch_account `{userNo}` status `{paySuccess}` order `{channelOrderNo}` {money} coming'.format(**retData))
				return retData
			else:
				logger.error('%s sign error %s', cls.Channel, data)
				raise Exception('sign error')
		else:
			raise Exception('channel error')

	@classmethod
	def getMyOrderID(cls, d):
		return d['myOrderNo']

	@classmethod
	def getOrderID(cls, d):
		return d['channelOrderNo']

	@classmethod
	def setOrderID(cls, d, orderID):
		d['channelOrderNo'] = orderID

	@classmethod
	def getOrderResult(cls, d):
		return True if d['paySuccess'] == 1 else False

	@classmethod
	def getClientInfo(cls, d):
		# 现在huawei的限制最小，100字节
		return d['cpPrivateInfo']

	@classmethod
	def getOrderAmount(cls, d):
		# 以分为单位，整形
		return float(d['money']) / 100.

	@classmethod
	def getOrderErrMsg(cls, d):
		return d['paySuccess']

	@classmethod
	@coroutine
	def payCallback(cls, handler, GET=True):
		cfg = handler.application.sdkConfig[cls.Channel] if cls.Channel in handler.application.sdkConfig else None
		data = {k: v[-1] for k, v in handler.request.arguments.iteritems()}
		ret = yield cls.recordPay(cfg, data, handler.application.myOrderCache, handler.application.orderCache, handler.application.dbcPay, handler.application.payQueue)
		raise Return(ret)


class SDKHuawei(SDKHardCore):
	Channel = 'huawei'
	ReturnOK = '{"result": 0}'
	ReturnErr = '{"result": 1}'


class SDKOppo(SDKHardCore):
	Channel = 'oppo'
	ReturnOK = 'result=OK&resultMsg=success'
	ReturnErr = 'result=FAIL&resultMsg=fail'


class SDKCoolPad(SDKHardCore):
	Channel = 'coolpad'
	ReturnOK = 'SUCCESS'
	ReturnErr = 'FAILURE'


class SDKLenovo(SDKHardCore):
	Channel = 'lenovo'
	ReturnOK = 'SUCCESS'
	ReturnErr = 'FAILURE'


class SDKGionee(SDKHardCore):
	Channel = 'gionee'
	ReturnOK = 'success'
	ReturnErr = 'fail'
	HttpClient = None

	@classmethod
	@coroutine
	def fetchChannelOrderID(cls, cfg, d, myOrderID):
		sdkReq = {
			'player_id': str(d['role']),
			'api_key': cfg['appkey'],
			'deal_price': str(d['amount']),
			'total_fee': str(d['amount']),
			'deliver_type': '1',
			'out_order_no': myOrderID,
			'subject': str(d['product']),
			'submit_time': time.strftime("%Y%m%d%H%M%S"),
		}

		sign = '{api_key}{deal_price}{deliver_type}{out_order_no}{subject}{submit_time}{total_fee}'.format(**sdkReq)
		sign = cls.rsaSign(cfg['privatekey'], sign)
		sdkReq['sign'] = sign

		try:
			# print json.dumps(sdkReq)
			response = yield cls.HttpClient.fetch(cfg['createURL'], method="POST", body=json.dumps(sdkReq))
		except:
			cls.initHttpClient()
			raise

		if response.error:
			raise Exception('%s sdk create order error %s' % (cls.Channel, response.error))
		else:
			# debug
			# print cls.Channel, 'return', response.body
			dd = json.loads(response.body, object_hook=toUTF8Dict)
			if dd['status'] == '200010000':
				orderID = dd['order_no']
			else:
				raise Exception(dd['description'])

		raise Return((orderID, dd))

	@classmethod
	def makeReturnDict(cls, myOrderID, d):
		return {
			'mOutOrderNo': myOrderID,
			'mSubmitTime': d['submit_time'],
		}

	@staticmethod
	def chunk_split(body, chunk_len=64, end="\n"):
		data = ""
		for i in xrange(0, len(body), chunk_len):
			data += body[i:min(i + chunk_len, len(body))] + end
		return data

	@staticmethod
	def rsaSign(pem, data, algo='sha1'):
		pem = SDKGionee.chunk_split(pem)
		pem = "-----BEGIN PRIVATE KEY-----\n" + pem + "-----END PRIVATE KEY-----\n"
		bio = M2Crypto.BIO.MemoryBuffer(pem)
		rsa = M2Crypto.RSA.load_key_bio(bio)
		prvkey = M2Crypto.EVP.PKey(md=algo)
		prvkey.assign_rsa(rsa)
		prvkey.sign_init()
		prvkey.sign_update(data)
		signature = base64.b64encode(prvkey.sign_final())
		return signature


class SDKVivo(SDKHardCore):
	Channel = 'vivo'
	ReturnOK = 'HTTP/1.1 200 OK'
	ReturnErr = HTTPError(403, 'HTTP/1.1 403 Forbidden')
	HttpClient = None

	@classmethod
	@coroutine
	def fetchChannelOrderID(cls, cfg, d, myOrderID):
		sdkReq = {
			'version': '1.0.0',
			'signMethod': 'MD5',

			'cpId': cfg['cpId'],
			'appId': cfg['appId'],
			'cpOrderNumber': myOrderID,
			'notifyUrl': PayNotifyHost + '/vivo/payment',

			'orderTime': time.strftime("%Y%m%d%H%M%S"),
			'orderAmount': int(d['amount']),
			'orderTitle': str(d['product']),
			'orderDesc': str(d['product']),
			'extInfo': json.dumps([d['account'], d['role'], d['servkey'], d['productid']]),
		}

		sign = hashlib.md5('appId={appId}&cpId={cpId}&cpOrderNumber={cpOrderNumber}&extInfo={extInfo}&notifyUrl={notifyUrl}&orderAmount={orderAmount}&orderDesc={orderDesc}&orderTime={orderTime}&orderTitle={orderTitle}&version={version}&{cpKey}'.format(cpKey=hashlib.md5(cfg['cpKey']).hexdigest().lower(), **sdkReq)).hexdigest().lower()
		sdkReq['signature'] = sign

		try:
			# print urllib.urlencode(sdkReq)
			response = yield cls.HttpClient.fetch(cfg['createURL'], method="POST", body=urllib.urlencode(sdkReq))
		except:
			cls.initHttpClient()
			raise

		if response.error:
			raise Exception('%s sdk create order error %s' % (cls.Channel, response.error))
		else:
			# debug
			# print cls.Channel, 'return', response.body
			dd = json.loads(response.body, object_hook=toUTF8Dict)
			if dd['respCode'] == '200':
				orderID = dd['orderNumber']
			else:
				raise Exception(dd['respMsg'])

		# 只向渠道服务器通知，payment服务器不再记录自己订单
		raise Return((None, dd))
		# raise Return((orderID, dd))

	@classmethod
	def makeReturnDict(cls, myOrderID, d):
		return {
			'transNo': d['orderNumber'],
			'accessKey': d['accessKey'],
		}