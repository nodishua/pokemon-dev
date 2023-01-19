#!/usr/bin/python
# -*- coding: utf-8 -*-

from framework.log import logger
from framework.helper import toUTF8Dict, objectid2string
from tornado.gen import coroutine, Return
from payment.sdk.base import SDKBase

import os
import json
import time
import hashlib
import urlparse
import binascii

DINGURL = "https://oapi.dingtalk.com/robot/send?access_token=3403d624d312fe3107dc86b02c5e488e734dac99c62d5f204715670e5853c08a"
DINGHEADERS = {
	'Content-Type': 'application/json; charset=UTF-8'
}

class SDKTJGame(SDKBase):
	Channel = 'tjgame'
	ReturnOK = '{"ret":0,"data":"Ok"}'
	ReturnErr = '{"ret":-1,"data":"Err"}'
	CodeCache = set([])

	@classmethod
	def parseData(cls, cfg, data):
		d = dict(urlparse.parse_qsl(data))
		logger.info('channel `{channel}` ch_account `{account}` status `{orderStatus}` order `{orderId}` {amount} coming'.format(channel=cls.Channel, account=objectid2string(d['accountId']), **d))
		return d

	@classmethod
	def getOrderID(cls, d):
		return d['orderId']

	@classmethod
	def getOrderResult(cls, d):
		return True if int(d["orderStatus"]) == 1 else False

	@classmethod
	def getClientInfo(cls, d):
		return d['game_extra']

	@classmethod
	def getOrderAmount(cls, d):
		return d['amount']

	@classmethod
	def getOrderErrMsg(cls, d):
		return ""

	@classmethod
	@coroutine
	def fetchChannelOrderID(cls, cfg, d, myOrderID):
		raise Exception('not implemented')

	@classmethod
	def makeReturnDict(cls, myOrderID, d):
		raise Exception('not implemented')

	@classmethod
	@coroutine
	def createCallback(cls, handler, GET=True):
		if cls.HttpClient is None:
			raise Exception('no http client')

		if GET:
			data = handler.request.query
		else:
			data = handler.request.body
		d = dict(urlparse.parse_qsl(data))

		ret = binascii.hexlify(os.urandom(4))
		cls.CodeCache.add(ret)
		logger.info("params `%s` code `%s`", data, ret)

		try:
			ding = {
				"msgtype": "text",
				"text": {
					"content": "%s 支付验证码 " % d['amount'] + ret
				},
			}
			response = yield cls.HttpClient.fetch(DINGURL, method="POST", headers=DINGHEADERS, body=json.dumps(ding))
		except:
			cls.initHttpClient()
			raise

		raise Return("code see dingding")

	@classmethod
	@coroutine
	def payCallback(cls, handler, GET=True):
		cfg = handler.application.sdkConfig[cls.Channel]
		if GET:
			data = handler.request.query
		else:
			data = handler.request.body
		d = dict(urlparse.parse_qsl(data))

		code = d.get('code', None)
		if code not in cls.CodeCache:
			raise Exception('code error')
		cls.CodeCache.discard(code)

		ret = yield cls.recordPay(cfg, data, handler.application.myOrderCache, handler.application.orderCache, handler.application.dbcPay, handler.application.payQueue)

		try:
			ding = {
				"msgtype": "text",
				"text": {
					"content": "钻石%s 支付验证码 %s 已被 %s 使用" % (d['amount'], d['code'], d['game_extra'])
				},
			}
			response = yield cls.HttpClient.fetch(DINGURL, method="POST", headers=DINGHEADERS, body=json.dumps(ding))
		except:
			cls.initHttpClient()
			raise

		raise Return(ret)