#!/usr/bin/python
# -*- coding: utf-8 -*-

from framework import nowtime_t
from framework.log import logger
from framework.helper import objectid2string
from tornado.gen import coroutine, Return
from tornado.web import HTTPError
from tornado.curl_httpclient import CurlAsyncHTTPClient
from payment.clientdata import ClientData
from payment.sdk import channelOrderID

import os
import json
import base64
import hashlib
import urlparse
import binascii


class SDKBase(object):
	Channel = 'none'
	ReturnOK = 'ok'
	ReturnErr = 'err'
	HttpClient = None

	@classmethod
	def initHttpClient(cls):
		if cls.HttpClient:
			cls.HttpClient.close()
		cls.HttpClient = CurlAsyncHTTPClient()

	@classmethod
	def parseData(cls, cfg, data):
		raise Exception('not implemented')

	@classmethod
	def getChannel(cls, d):
		return cls.Channel

	@classmethod
	def getMyOrderID(cls, d):
		raise Exception('not implemented')

	@classmethod
	def getOrderID(cls, d):
		raise Exception('not implemented')

	@classmethod
	def setOrderID(cls, d, orderID):
		# 只有某些渠道需要自己构建订单ID才需要实现
		raise Exception('not implemented')

	@classmethod
	def getOrderResult(cls, d):
		raise Exception('not implemented')

	@classmethod
	def getClientInfo(cls, d):
		raise Exception('not implemented')

	@classmethod
	def getOrderAmount(cls, d):
		# 充值金额，单位元
		raise Exception('not implemented')

	@classmethod
	def getOrderErrMsg(cls, d):
		raise Exception('not implemented')

	@classmethod
	@coroutine
	def recordPay(cls, cfg, data, myOrderCache, orderCache, dbcPay, payQueue, dbcGift=None):
		if len(data) == 0:
			logger.warning('%s pay empty data', cls.Channel)
			# 反正数据不对，重发也没有意义
			raise Return(cls.ReturnOK)

		dd = {}
		orderID = None
		try:
			dd = cls.parseData(cfg, data)
			# 苹果官方需要进行查询
			if cls.Channel == 'apple':
				yield cls.verifyReceipt(cfg, dd)

			# 苹果给客户端的返回结果需要额外数据
			retOKDef = cls.ReturnOK
			if cls.Channel in ('apple', 'ls'):
				retOKDef = cls.getReturnOK(dd)

			# 重复通知的可能
			orderOK = cls.getOrderResult(dd)
			orderRawID = cls.getOrderID(dd)

			# 某些渠道需要自己构建订单ID，现有Gionee
			# Meizu已经无需create
			# Vivo需要create，但支付回调有sign和clientinfo，按照回调来
			mycdata = None
			if len(orderRawID) == 0:
				myOrderRawID = cls.getMyOrderID(dd)
				myOrderID = channelOrderID(cls.getChannel(dd), myOrderRawID)
				if myOrderID not in myOrderCache:
					raise Exception('no such my order id')
				orderRawID, _, uid, rid, skey, pid, yyid, csvid = myOrderCache.pop(myOrderID)
				mycdata = ClientData((uid, rid, skey, pid, '', yyid, csvid))
				cls.setOrderID(dd, orderRawID)

			# 加前缀是为方便检索，这样order_id应该是唯一的
			orderID = channelOrderID(cls.getChannel(dd), orderRawID)
			prevOK = orderCache.popByKey(orderID)
			if prevOK is not None:
				# 上次SDK通知失败，这次是成功的才处理
				# 这里只是cache优化，由数据库unique保证正确
				if prevOK is False and orderOK is True:
					pass
				else:
					orderCache.set(orderID, orderOK)
					logger.info('%s %s already sent %s %s', cls.getChannel(dd), orderRawID, prevOK, orderOK)
					if cls.Channel == 'lp_gift':
						ret = yield dbcGift.call_async('OrderGiftQuery', dd['orderID'])
						raise Return(cls.getReturnOK(ret))
					else:
						raise Return(cls.ReturnOK)

			cdata = ClientData(cls.getClientInfo(dd))
			badFlag, model = cdata.makeModel()
			if badFlag:
				# 针对某些渠道自己构建订单ID，不再将client info通知给回调的情况
				if mycdata:
					badFlag, model = mycdata.makeModel()
					if not badFlag:
						cdata = mycdata

			if badFlag:
				logger.error('%s client info error %s', cls.getChannel(dd), cls.getClientInfo(dd))
				# 反正数据不对，重发也没有意义
				raise Return(retOKDef)

			model.update({
				'time': nowtime_t(),
				'channel': cls.getChannel(dd),
				'result': 'ok' if orderOK else 'err',
				'order_id': orderID,
				'sdkmsg': str(data),
				'amount': float(cls.getOrderAmount(dd)),
			})
			# 去重应该在yield之前，否则无法保证原子性
			# 后续出错只能去log里找了
			orderCache.set(orderID, orderOK)

			# 支付失败
			if not orderOK:
				logger.warning('%s pay failed %s', cls.getChannel(dd), cls.getOrderErrMsg(dd))
				model['bad_flag'] = True
				badFlag = True

			ret = yield dbcPay.call_async('PayOrderAdd', model)
			if ret['ret']:
				# 使用统一的数据库字段字典
				model = ret['model']
			else:
				# 重复通知
				if ret['err'].find("duplicate key error") != -1:
					logger.info('%s %s already in db', cls.getChannel(dd), orderRawID)
					# True or True，可能只是重复通知，中间服务器可能重启了
					# False or True，不可能
					# True or False，收到订单但未给钻石(可能cdata不对)，由服务器重启时入队列
					# False or False，上次通知是支付失败
					if cls.Channel == 'lp_gift':
						ret = yield dbcGift.call_async('OrderGiftQuery', dd['orderID'])
						raise Return(cls.getReturnOK(ret))
					else:
						model = ret['model']
						if model['result'] == 'ok' or model['recharge_flag']:
							raise Return(retOKDef)

				else:
					logger.error('db create order error %s', ret['err'])
					badFlag = True

			# 坏数据就先记录后运营处理
			if badFlag:
				raise Return(retOKDef)


			if cls.Channel == 'lp_gift':
				logger.info('channel `{channel}` gift `{gift}` order (`{order_id}`, `{id_}`) {amount:.2f} recharge ok'.format(id_=objectid2string(model['id']), gift=dd['giftID'], **model))
				ret = yield dbcGift.call_async('OrderGiftGen', dd['orderID'], int(dd['giftID']), [])
				yield dbcPay.call_async('PayOrderRecharge', model['id'])
				raise Return(cls.getReturnOK(ret))
			else:
				payQueue.put((model, 0))
				raise Return(retOKDef)

		# 正常返回
		except Return as ret:
			# mofang需要成功后手动关闭订单
			try:
				yield cls.closeCallback(cfg, data)
			except:
				pass
			raise ret

		# 异常就让sdk再次发送
		except:
			# 等渠道重复通知时再次尝试充值
			orderCache.popByKey(orderID)
			logger.exception('%s pay exception\n%s\n', cls.getChannel(dd), str(data))
			if isinstance(cls.ReturnErr, HTTPError):
				raise cls.ReturnErr
			raise Return(cls.ReturnErr)

	@classmethod
	@coroutine
	def closeCallback(cls, cfg, data):
		raise Return(True)

	@classmethod
	@coroutine
	def payCallback(cls, handler, GET=True):
		# print 'query', handler.request.query
		# print 'body', handler.request.body
		# print 'arguments', handler.request.arguments
		# print 'body_arguments', handler.request.body_arguments

		cfg = handler.application.sdkConfig[cls.Channel]
		if GET:
			data = handler.request.query
		else:
			data = handler.request.body

		# tt渠道特殊
		if 'sign' in handler.request.headers:
			data = (data, handler.request.headers['sign'])

		ret = yield cls.recordPay(cfg, data, handler.application.myOrderCache, handler.application.orderCache, handler.application.dbcPay, handler.application.payQueue, handler.application.dbcGift)
		raise Return(ret)

	@classmethod
	def parseCreateParam(cls, cfg, data):
		'''
		channel=gionee&amount=10.5&productid=2&product=月卡&time=123123123.4&account=1&channelid=xxxx&servkey=game&role=998&sign=0f602f0ef91485921a83d31e0d55deef
		'''
		d = dict(urlparse.parse_qsl(base64.b64decode(data)))
		if cls.Channel != d.get('channel', ''):
			logger.error('%s channel error %s', cls.Channel, d.get('channel', ''))
			raise Exception('channel error')

		logger.info('channel `{channel}` serv `{servkey}` role `{role}` product `{productid}` {amount} creating'.format(**d))

		validSign = hashlib.md5('{time}{channel}{account}{channelid}{servkey}{role}{productid}{amount}{yyid}{csvid}{signsecret}'.format(signsecret='youmi', **d)).hexdigest()

		if validSign != d['sign']:
			logger.error('%s sign error %s', cls.Channel, data)
			raise Exception('sign error')

		d['amount'] = float(d['amount'])
		d['time'] = float(d['time'])
		d['role'] = d['role']
		d['account'] = d['account']
		d['productid'] = int(d['productid'])
		d['yyid'] = int(d['yyid'])
		d['csvid'] = int(d['csvid'])
		return d

	@classmethod
	def makeMyOrderID(cls, d):
		return '%s%s' % (d['role'], binascii.hexlify(os.urandom(8)))

	@classmethod
	@coroutine
	def fetchChannelOrderID(cls, cfg, d, myOrderID):
		raise Exception('not implemented')

	@classmethod
	def makeReturnDict(cls, myOrderID, d):
		raise Exception('not implemented')

	@classmethod
	@coroutine
	def recordCreate(cls, cfg, data, myOrderCache):
		d = cls.parseCreateParam(cfg, data)
		myOrderID = cls.makeMyOrderID(d)
		orderID, dd = yield cls.fetchChannelOrderID(cfg, d, myOrderID)
		if orderID:
			myOrderCache.addByDict(channelOrderID(cls.Channel, myOrderID), orderID, d)
		ret = cls.makeReturnDict(myOrderID, dd)
		raise Return(json.dumps(ret, ensure_ascii=False))

	@classmethod
	@coroutine
	def createCallback(cls, handler, GET=True):
		if cls.HttpClient is None:
			raise Exception('no http client')

		cfg = handler.application.sdkConfig[cls.Channel]
		if GET:
			data = handler.request.query
		else:
			data = handler.request.body

		ret = yield cls.recordCreate(cfg, data, handler.application.myOrderCache)
		raise Return(ret)

	@classmethod
	@coroutine
	def verifyReceipt(cls, cfg, d):
		raise Exception('not implemented')

