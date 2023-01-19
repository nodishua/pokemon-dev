#!/usr/bin/python
# -*- coding: utf-8 -*-

from framework.log import logger
from framework.helper import toUTF8Dict
from tornado.gen import coroutine, Return, sleep
from payment.sdk.base import SDKBase

import os
import time
import hmac
import json
import hashlib
import base64
import urllib
import urlparse


# QQ和WX支付流程特殊
# 该SDK除了payment_server，game_server也会用到
# http://wiki.open.qq.com/wiki/%E6%B8%B8%E6%88%8F%E6%8E%A5%E5%85%A5%E7%B1%B3%E5%A4%A7%E5%B8%88%E6%B5%81%E7%A8%8B
class SDKQQ(SDKBase):
	'''
	SDKQ的支付回调由客户端构造
	正确性检查由game server
	'''
	Channel = 'qq'
	ReturnOK = 'OK'
	ReturnErr = 'Err'
	HttpClient = None

	SessionID = 'openid'
	SessionType = 'kp_actoken'
	SignPrefix = '/v3/r'

	@classmethod
	def parseData(cls, cfg, data):
		# print data
		d = json.loads(data, object_hook=toUTF8Dict)
		dd = json.loads(d['token'], object_hook=toUTF8Dict)
		d['tokenD'] = dd

		logger.info('channel `{channel}` ch_account `{ch_account}` status `True` order `{order}` {amount} coming'.format(ch_account=dd.get('openid', ''), **d))

		sign = hashlib.md5("{time}{channel}{account}{servid}{servkey}{role}{productid}{balance}{save_amt}{order}{token}youmi".format(**d)).hexdigest()

		if sign != d['sign']:
			logger.error('%s sign error %s', cls.Channel, data)
			raise Exception('sign error')

		return d

	# like ('%s_%d_%d_%d_%d_%d_%d', os.date("%y%m%d"), g_game.model.role.area, roleID, balance, save_amt, amount, time)
	@classmethod
	def getOrderID(cls, d):
		return d['order']

	@classmethod
	def getOrderResult(cls, d):
		return True

	@classmethod
	def getClientInfo(cls, d):
		return (d['account'], d['role'], d['servkey'], d['productid'])

	@classmethod
	def getOrderAmount(cls, d):
		# 支付金额,单位为元
		return d['amount']

	@classmethod
	def getOrderErrMsg(cls, d):
		return 'no err msg'

	#############################

	@classmethod
	@coroutine
	def payCallback(cls, handler, GET=True):
		cfg = handler.application.sdkConfig[cls.Channel]
		if GET:
			data = handler.request.query
		else:
			data = handler.request.body

		d = cls.parseData(cfg, data)
		dd = d['tokenD']
		openid = dd.get('openid', '')
		openkey = dd.get('payToken', dd.get('accessToken', ''))
		pf = dd.get('pf', '')
		pfkey = dd.get('pf_key', '')
		zoneid = d['servid']
		save_amt = d['save_amt']
		amount = d['amount'] * 10 # amount单位是元，save_amt单位是钻石
		application = handler.application
		@coroutine
		def _task():
			# 由于部分充值渠道充值有延时，建议在收到支付成功的回调以后接下来的2分钟内，间隔15秒重复调用查询余额的接口。查余额的过程中查询是否到账可以根据查余额返回的 “save_amt：累计充值金额的游戏币数量”的变化判断.
			for i in xrange(8):
				ret = yield cls.queryBalanceRequest(openid, openkey, pf, pfkey, zoneid)
				if save_amt + amount <= int(ret['save_amt']):
					yield cls.recordPay(cfg, data, application.myOrderCache, application.orderCache, application.dbcPay, application.payQueue)
					raise Return(True)
				elif save_amt == int(ret['save_amt']):
					yield sleep(15)
				else:
					logger.warning('channel `{channel}` ch_account `{ch_account}` order `{order}` query result error, {save_amt} + {amount}*10 > {ret_amt}'.format(ch_account=openid, ret_amt=ret['save_amt'], **d))
					raise Return(False)

		_task() # run in coroutine
		raise Return(cls.ReturnOK)

	#############################

	# game server 使用
	@classmethod
	def initInGameServer(cls):
		cls.initHttpClient()
		with open('sdk.conf', 'rb') as fp:
			cls.sdkConfig = json.load(fp, object_hook=toUTF8Dict)

	@classmethod
	def parseDataTokenToGame(cls, data, isRaw):
		d = json.loads(data, object_hook=toUTF8Dict)
		if not isRaw:
			d = json.loads(d['token'], object_hook=toUTF8Dict)
		dd = {
			'openid': d.get('openid', ''),
			'openkey': d.get('payToken', d.get('accessToken', '')),
			'pf': d.get('pf', ''),
			'pfkey': d.get('pf_key', ''),
		}
		for k, v in dd.iteritems():
			if len(v) == 0:
				logger.warning('%s is empty, %s', k, data)
		return dd

	@classmethod
	def makeSignURLAndCookie(cls, url, appkey, d):
		# in sand box, wx and qq are same appid and key
		# d['appid'] = '1105274265' # in sand box
		# appkey = 'AMGQSbhHNmre1OQBjeRh3VcamMAoXqr3' # in sand box
		o = urlparse.urlparse(url)
		prepath = urllib.quote_plus(cls.SignPrefix + o.path)
		sign = urllib.quote_plus(urllib.urlencode([x for x in sorted(d.items())]))
		sign = 'GET&%s&%s' % (prepath, sign)
		appkey = appkey + '&'
		sign = base64.b64encode(hmac.new(appkey, sign, hashlib.sha1).digest())
		d['sig'] = sign

		cookieD = {
			'session_id': cls.SessionID,
			'session_type': cls.SessionType,
			'org_loc': urllib.quote_plus(o.path),
		}
		cookie = {
			"Cookie": '; '.join(['%s=%s' % t for t in cookieD.iteritems()])
		}
		return url + '?' + urllib.urlencode(d), cookie

	@classmethod
	@coroutine
	def queryBalanceRequest(cls, openid, openkey, pf, pfkey, zoneid):
		if cls.HttpClient is None:
			raise Exception('no http client')

		cfg = cls.sdkConfig[cls.Channel]
		url, cookie = cls.makeSignURLAndCookie(cfg['queryBalanceURL'], cfg['paykey'], {
			'appid': cfg['payid'],
			'openid': openid,
			'openkey': openkey,
			'pf': pf,
			'pfkey': pfkey,
			'zoneid': zoneid,
			'ts': int(time.time()),
		})

		try:
			# print url
			# print cookie
			response = yield cls.HttpClient.fetch(url, method="GET", headers=cookie)
		except:
			cls.initHttpClient()
			raise

		if response.error:
			raise Exception('%s sdk query error %s' % (cls.Channel, response.error))
		else:
			# debug
			# print cls.Channel, 'return', response.body
			dd = json.loads(response.body, object_hook=toUTF8Dict)
			if dd['ret'] == 0:
				raise Return(dd)
			else:
				logger.warning(url)
				logger.warning(cookie)
				raise Exception(dd['msg'])

	@classmethod
	@coroutine
	def payRequest(cls, openid, openkey, pf, pfkey, zoneid, amt, billno):
		if cls.HttpClient is None:
			raise Exception('no http client')

		cfg = cls.sdkConfig[cls.Channel]
		url, cookie = cls.makeSignURLAndCookie(cfg['payURL'], cfg['paykey'], {
			'appid': cfg['payid'],
			'openid': openid,
			'openkey': openkey,
			'pf': pf,
			'pfkey': pfkey,
			'zoneid': zoneid,
			'ts': int(time.time()),
			'amt': amt,
			'billno': billno,
		})

		try:
			# print url
			# print cookie
			response = yield cls.HttpClient.fetch(url, method="GET", headers=cookie)
		except:
			cls.initHttpClient()
			raise

		if response.error:
			raise Exception('%s sdk pay error %s' % (cls.Channel, response.error))
		else:
			# debug
			# print cls.Channel, 'return', response.body
			dd = json.loads(response.body, object_hook=toUTF8Dict)
			if dd['ret'] == 0:
				raise Return(dd)
			else:
				logger.warning(url)
				logger.warning(cookie)
				raise Exception(dd['msg'])


class SDKWX(SDKQQ):
	Channel = 'wx'
	HttpClient = None

	SessionID = 'hy_gameid'
	SessionType = 'wc_actoken'
