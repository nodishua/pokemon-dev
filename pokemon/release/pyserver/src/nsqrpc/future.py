# -*- coding: utf-8 -*-
'''
Copyright (c) 2014 YouMi Information Technology Inc.
Copyright (c) 2016 TianJi Information Technology Inc.
'''

from nsqrpc.error import RPCError, CallError

from tornado.gen import coroutine
from tornado.concurrent import Future

import time


class NSQFuture(Future):
	def __init__(self, loop, timeout, callback=None, topic=None):
		Future.__init__(self)
		self.loop = loop
		self.timeout = timeout
		self.topic = topic
		self.time = time.time()
		if callback:
			self.add_done_callback(callback)

	def join(self):
		# like `run_sync`
		self.loop.add_future(self, lambda future: self.loop.stop())
		while not (self._done or self.loop._stopped):
			self.loop.start()

	def get(self):
		self.join()

		if not self._done:
			if not self.loop._stopped:
				raise RPCError('joined but not done')
			else:
				raise RPCError('io loop not running')

		return self.result()

	def set_exception(self, exception):
		if not isinstance(exception, RPCError):
			exception = CallError.from_msgpack(exception, self.topic)
		Future.set_exception(self, exception)

	def step_timeout(self):
		if self.timeout is None:
			return False
		if self.timeout < 1:
			return True
		else:
			self.timeout -= 1
			return False
