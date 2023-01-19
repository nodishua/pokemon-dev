#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2014 YouMi Information Technology Inc.
Copyright (c) 2016 TianJi Information Technology Inc.
'''

from tornado.gen import sleep
from tornado.iostream import StreamClosedError
from tornado.concurrent import Future, chain_future
from msgpackrpc.error import TimeoutError, TransportError

from framework.log import logger
from framework.rpc_client import Client
from framework.distributed import ServiceDefs

okfu = Future()
okfu.set_result(None)

'''
维护rpc client，封装断线超时等异常处理
加入service与server无关，则可以进行rpc client自动切换
'''
class Service(object):
	# node 是自己的节点
	# serive 是需要访问的服务
	# clientKey 是强制指定的服务器
	def __init__(self, node, service, clientKey=None):
		self.node = node
		self.service = service
		self.clientKey = clientKey
		self.client = None
		self.waitClientKey = False

	def _try_client_key(self):
		if self.waitClientKey:
			return
		self.waitClientKey = True
		fu = self.node.discovery(service=self.service)
		def foundKey(fu):
			key, address, states = fu.result()
			self.clientKey = key
			self.waitClientKey = False
		fu.add_done_callback(foundKey)

	def _try_client(self):
		if self.clientKey is None:
			return self._try_client_key()
		self.client = self.node.client(self.clientKey)

	def _call(self, method, *args):
		if self.client:
			return self.client.call_async_timeout(method, 5, *args)
		else:
			self._try_client()
			ret = Future()
			ret.set_exception(StreamClosedError('client not connected'))
			return ret

	def call_async(self, method, *args):
		ret = Future()
		preE = [None]
		fu = self._call(method, *args)

		def check(fu):
			try:
				ret.set_result(fu.result())
			except Exception as e:
				if str(preE[0]) != str(e):
					logger.warning('node %s call %s service %s error %s', self.node.key, self.clientKey, self.service, e)
					preE[0] = e
				# 如果是逻辑异常，则raise到上层
				isLogicE = not isinstance(e, (StreamClosedError, TransportError, TimeoutError))
				if isLogicE or self.node.stopped:
					ret.set_exception(e)
					return
				sleep(1).add_done_callback(lambda _: self._call(method, *args).add_done_callback(check))

		fu.add_done_callback(check)
		return ret

	def notify(self, method, *args):
		if not self.client:
			self._try_client()
		if self.client:
			self.client.notify(method, *args)
