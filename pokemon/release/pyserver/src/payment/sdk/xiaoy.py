#!/usr/bin/python
# -*- coding: utf-8 -*-

from framework.log import logger
from framework.helper import toUTF8Dict
from tornado.gen import coroutine, Return
from payment.sdk.base import SDKBase
from payment.clientdata import ClientData

import json
import time
import hashlib
import urlparse
import urllib
import M2Crypto
import base64

RechargeMap = {
	1: 30,
	2: 88,
	3: 648,
	4: 328,
	5: 198,
	6: 98,
	7: 60,
	8: 30,
	9: 6,

	101: 1,
	102: 6,
	103: 12,
	104: 18,
	105: 25,
	106: 30,
	107: 60,
	108: 98,
	109: 128,
	110: 168,
	111: 198,
	112: 328,
	113: 648,
}

XiaoY_PUBLIC_KEY = 'MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDn+y22ezJKN3JEwev6bV0UA6uOYuFnqr6HRg/eFZXwqVmVA5Nw4HEqBgQ68XuDaZW71mnNOG/T3Icr/6HVdH3ldEIJVc/+iW4yHnKwJXJXLhfmTnsMOINBuKkaSnLEqDlqFUe0gFPjDr/Wi4as0z7hivghkFmGpCBaNX7MCeK11wIDAQAB'

class SDKXiaoY(SDKBase):
	Channel = "xy51"
	ReturnOK = 'success'
	ReturnErr = 'fail'

	@classmethod
	def parseData(cls, cfg, data):
		d = json.loads(data)
		logger.info('channel `{channel}` ch_account status `True` order `{xiaoyTradeNo}` coming'.format(channel=cls.Channel, **d))

		data = "appId={appId}&attach={attach}&cashFee={cashFee}&corpId={corpId}&orderCreateTime={orderCreateTime}&orderExpireTime={orderExpireTime}&outTradeNo={outTradeNo}&totalFee={totalFee}&xiaoyTradeNo={xiaoyTradeNo}".format(**d)
		if not cls.rsaVerify(XiaoY_PUBLIC_KEY, data, urllib.unquote(d['sign'])):
			logger.error('%s sign error %s', cls.Channel, data)
			raise Exception('sign error')
		return d

	@classmethod
	def getOrderID(cls, d):
		return d['xiaoyTradeNo']

	@classmethod
	def getOrderResult(cls, d):
		return True

	@classmethod
	def getClientInfo(cls, d):
		cdata = ClientData(d['attach'])
		if RechargeMap[cdata.rechargeID] != int(d['totalFee'])/100: # 订单总金额（单位：分）
			logger.error('%s %s recharge amount error', cls.Channel, cls.getOrderID(d))
			return None
		return d['attach']

	@classmethod
	def getOrderAmount(cls, d):
		return float(d['totalFee']) / 100 # 订单总金额（单位：分）

	@classmethod
	def getOrderErrMsg(cls, d):
		return 'none'

	@staticmethod
	def chunk_split(body, chunk_len=64, end="\n"):
		data = ""
		for i in xrange(0, len(body), chunk_len):
			data += body[i:min(i + chunk_len, len(body))] + end
		return data

	@staticmethod
	def rsaVerify(pem, data, sign, algo='md5'):
		pem = SDKXiaoY.chunk_split(pem)
		pem = "-----BEGIN PUBLIC KEY-----\n" + pem + "-----END PUBLIC KEY-----\n"
		bio = M2Crypto.BIO.MemoryBuffer(pem)
		rsa = M2Crypto.RSA.load_pub_key_bio(bio)
		pubkey = M2Crypto.EVP.PKey(md=algo)
		pubkey.assign_rsa(rsa)
		pubkey.verify_init()
		pubkey.verify_update(data)
		signature = base64.b64decode(sign)
		return pubkey.verify_final(signature)
