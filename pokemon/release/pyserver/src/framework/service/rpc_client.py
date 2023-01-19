#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2014 YouMi Information Technology Inc.
Copyright (c) 2018 TianJi Information Technology Inc.
'''

from framework.log import logger

from nsqrpc.server import AsyncResult
from tornado.gen import coroutine, Return

import functools

class Client(object):
	def __init__(self, name, client):
		self.name = name
		self.service_id = name if len(name.split('.')) == 3 else None
		self.client = client
		self.ioloop = self.client.ioloop

	def close(self):
		pass

	def call(self, method, *args):
		return self._call_in_tornado(method, *args)

	def call_async(self, method, *args):
		return self._call_async_in_tornado(method, None, *args)

	def call_async_timeout(self, method, timeout, *args):
		self.client.enableTimeout()
		return self._call_async_in_tornado(method, timeout, *args)

	def call_async_always(self, method, *args):
		return self._call_async_in_tornado(method, 0, *args)

	def notify(self, method, *args):
		self.client.notify(method, *args)

	def _call_in_tornado(self, method, *args):
		# non-blocking
		@coroutine
		def _coroutine():
			ret = yield self._call_async_in_tornado(method, None, *args)
			# return a value from a coroutine
			raise Return(ret)
		return self.ioloop.run_sync(_coroutine)

	def _call_async_in_tornado(self, method, timeout, *args):
		if method.startswith('db'):
			logger.warning('method %s should use startswith DB', method)
			method = 'DB' + method[2:]
		elif method.startswith('gm'):
			pass
		else:
			method = method[0].upper() + method[1:]
		future = self.client.call_async(method, *args, service_id=self.service_id)
		if timeout is not None:
			timeout = 999999999 if timeout == 0 else timeout
			future.timeout = timeout
		return future

DINGHEADERS = {
	'Content-Type': 'application/json; charset=UTF-8'
}
# 运维机器人
DingURL = "https://oapi.dingtalk.com/robot/send?access_token=cf33ac5c154294f61591e4da4e7150f8448c2d5207a82dae73397253ae967c9e"

def ding(msg):
	import requests
	import framework
	params = {
		"msgtype": "markdown",
		"markdown": {
			"title": "CallError",
			"text": "## " + 'CallError' + "\n\n"  + framework.__server_key__ + "\n\n" + msg + "\n",
		}
	}
	x = requests.post(DingURL, json=params, headers=DINGHEADERS)
	if x.status_code != 200:
		logger.warning('%s', x.text)

def nsqrpc_coroutine(f):
	@functools.wraps(f)
	def _wrap(*args, **kwargs):
		ar = AsyncResult()

		def _done(fu):
			try:
				r = fu.result()
				ar.set_result(r)
			except Exception as e:
				logger.exception('nsqrpc_coroutine exception')
				err = e
				if not hasattr(err, 'to_msgpack'):
					err = str(err)
				ar.set_error(err)

				from nsqrpc.error import CallError
				if isinstance(e, CallError):
					ding(str(e))
		co = coroutine(f)
		co(*args, **kwargs).add_done_callback(_done)
		return ar
	return _wrap
