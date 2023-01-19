#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2014 YouMi Information Technology Inc.
'''

import msgpackrpc
from msgpackrpc.server import AsyncResult
from tornado.gen import coroutine, Return

from framework.log import logger

class Client(object):
	def __init__(self, name, hostport, loop=None, timeout=24, on_reconn=None):
		self.name = name
		self.clientName = '[%s] RPC Client' % name
		self.hostport = hostport
		self.timeout = timeout
		self.client = msgpackrpc.Client(address=msgpackrpc.Address(*self.hostport), loop=loop, timeout=timeout, reconnect_limit=-1, on_reconnect=on_reconn)
		self.ioloop = self.client._loop._ioloop

	# in distributed network, name is key
	@property
	def key(self):
		return self.name

	def close(self):
		self.client.close()

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
		# self.client.notify(method, *args)
		self.call_async(method, *args)

	def _call_in_tornado(self, method, *args):
		# non-blocking
		@coroutine
		def _coroutine():
			ret = yield self._call_async_in_tornado(method, None, *args)
			# return a value from a coroutine
			raise Return(ret)
		# timeout control by `msgpackrpc.Client`, not `run_sync`
		# you can handle timeout exception in `_coroutine`
		return self.ioloop.run_sync(_coroutine)

	def _call_async_in_tornado(self, method, timeout, *args):
		if method.startswith('db'):
			method = 'DB' + method[2:]
		elif method.startswith('gm'):
			pass
		else:
			method = method[0].upper() + method[1:]
		future = self.client.call_async(method, *args)
		if timeout is not None:
			timeout = 999999999 if timeout == 0 else timeout
			# `future` is msgpackrpc.Future
			# `future.yield_future` is tonardo.concurrent.Future
			future._timeout = timeout
		return future.yield_future


def rpc_coroutine(f):
	def _wrap(*args, **kwargs):
		ar = AsyncResult()
		def _done(fu):
			try:
				r = fu.result()
				ar.set_result(r)
			except Exception as e:
				logger.exception('rpc_coroutine exception')
				if not hasattr(e, 'to_msgpack'):
					e = str(e)
				ar.set_error(e)
		co = coroutine(f)
		co(*args, **kwargs).add_done_callback(_done)
		return ar
	return _wrap

