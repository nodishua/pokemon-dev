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

import M2Crypto

import os
import json
import base64
import time
import urllib
import hashlib
import binascii
import urlparse

RechargeMap = {
	3: 9999,
	4: 4899,
	5: 2899,
	6: 1499,
	7: 999,
	8: 499,
	9: 99,
}

DealPriceMap = {
	9999: 3,
	4899: 4,
	2899: 5,
	1499: 6,
	999: 7,
	499: 8,
	99: 9,
}

class SDKZhuodong(SDKBase):
	Channel = 'zd'
	ReturnOK = '{"state":{"code":0,"msg":""}}'
	ReturnErr = '{"state":{"code":-1,"msg":"error"}}'
	HttpClient = None

	@classmethod
	def parseData(cls, cfg, data):
		d = json.loads(data, object_hook=toUTF8Dict)
		logger.info('channel `{channel}` ch_account `{uid}` status `True` order `{payment_id}` {price} coming'.format(channel=cls.Channel, **d))

		sign = 'cp_id={cp_id}&cp_order_id={cp_order_id}&currency={currency}&ext={ext}&game_id={game_id}&payment_id={payment_id}&price={price}&role_id={role_id}&role_name={role_name}&server_id={server_id}&server_name={server_name}&timestamp={timestamp}&uid={uid}&secret={secret}'.format(secret=cfg['appsecret'], **d)
		sign = hashlib.sha256(sign).hexdigest()

		if sign != d['sign']:
			logger.error('%s sign error %s', cls.Channel, data)
			raise Exception('sign error')

		return d

	@classmethod
	@coroutine
	def closeCallback(cls, cfg, data):
		d = json.loads(data, object_hook=toUTF8Dict)
		cp_id = cfg['cpid']
		game_id = cfg['gameid']
		cp_order_id = d['cp_order_id']
		server_id = d['server_id']
		uid = d['uid']

		timestamp = int(nowtime_t())
		sdkReq = {
			'cp_id': cp_id,
			'game_id': game_id,
			'send_result_list': [{
				'server_id': server_id,
				'uid': uid,
				'cp_order_id': cp_order_id,
				'send_status': 1,
				'item_list': [{
					'item_name': '钻石',
					'num': 100,
					'balance_before': 85,
					'balance_after': 185,
				}],
				'send_time': timestamp,
			}],
			'time_stamp': timestamp,
		}
		sign = "cp_id={cp_id}&game_id={game_id}&send_result_list[0].cp_order_id={cp_order_id}&send_result_list[0].item_list[0].balance_after=185&send_result_list[0].item_list[0].balance_before=85&send_result_list[0].item_list[0].item_name=钻石&send_result_list[0].item_list[0].num=100&send_result_list[0].send_status=1&send_result_list[0].send_time={timestamp}&send_result_list[0].server_id={server_id}&send_result_list[0].uid={uid}&time_stamp={timestamp}&secret={secretkey}".format(cp_id=cp_id, game_id=game_id, cp_order_id=cp_order_id, server_id=server_id, uid=uid, timestamp=timestamp, secretkey=cfg['appsecret'])
		sign = hashlib.sha256(sign).hexdigest()
		sdkReq['sign'] = sign

		try:
			fu = cls.HttpClient.fetch(cfg['closeURL'], method="POST", request_timeout=2, body=json.dumps(sdkReq))

			def _done(fu):
				try:
					response = fu.result()
					ret = json.loads(response.body, object_hook=toUTF8Dict)
					if ret['ret_code'] == 0:
						logger.info('%s %s close ok', cls.Channel, sdkReq)
					else:
						logger.info('%s %s close error %s', cls.Channel, sdkReq, ret['ret_msg'])
				except:
					logger.exception('%s %s close err', cls.Channel, sdkReq)
			fu.add_done_callback(_done)
		except:
			logger.exception('%s %s fetch err', cls.Channel, sdkReq)
			cls.initHttpClient()
			# 无所谓成功失败，通知即可

	@classmethod
	def getOrderID(cls, d):
		return d['payment_id']

	@classmethod
	def getOrderResult(cls, d):
		return True

	@classmethod
	def getClientInfo(cls, d):
		cdata = ClientData(d['ext'])
		if cdata.rechargeID in RechargeMap:
			if int(d['price']) != RechargeMap[cdata.rechargeID]: # 临时修复
				logger.error('%s %s clientdata error, got %s, %s', cls.Channel, d['payment_id'], d['price'], d['ext'])
				return [cdata.accountID, cdata.roleID, cdata.serverKey, DealPriceMap[int(d['price'])]]

		return d['ext']

	@classmethod
	def getOrderAmount(cls, d):
		return d['price']

	@classmethod
	def getOrderErrMsg(cls, d):
		return ""