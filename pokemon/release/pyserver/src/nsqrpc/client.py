# -*- coding: utf-8 -*-
'''
Copyright (c) 2014 YouMi Information Technology Inc.
Copyright (c) 2016 TianJi Information Technology Inc.
'''

from nsqrpc.message import pack_request, unpack_message, pack_notify, REQUEST, NOTIFY
from nsqrpc.topic import *
from nsqrpc.future import NSQFuture
from nsqrpc.error import TimeoutError

import nsq
import tornado.ioloop
from tornado.ioloop import PeriodicCallback
import datetime
import functools
import logging

logger = logging.getLogger(__name__)

try:
	import snappy
	_snappy = True
except:
	_snappy = False

import time

class NSQClient(object):
	ZombieDuration = 5 * 60 # second

	def __init__(self, key, writerdefs, timeout=None, loop=None, readerdefs=None):
		if loop is None:
			loop = tornado.ioloop.IOLoop.current()

		if key[0] == '@':
			key = 'c_' + key[1:]

		self.key = key
		self.timeout = timeout
		self.ioloop = loop
		self.futures = {} # {msgID: future}
		self.readerdefs = readerdefs if readerdefs else writerdefs
		self.writerdefs = writerdefs

		self.reader = nsq.Reader(message_handler=self.response_handle, topic=ResponseTopic(self.key), channel=ServiceRespChannel, io_loop=self.ioloop, **self.readerdefs)
		self.writer = nsq.Writer(client_id=key, io_loop=loop, snappy=_snappy, **self.writerdefs)

		self.cleanZombieTimer = PeriodicCallback(self.cleanZombie, 5 * 60 * 1000.)
		self.cleanZombieTimer.start()

		self._rpc_error_warpper = None
		self._periodic_callback = None

		if timeout:
			self.enableTimeout()

	def wrap_rpc_error(self, wrapper):
		self._rpc_error_warpper = wrapper

	def enableTimeout(self):
		if self._periodic_callback is None:
			self.attach_periodic_callback(self.step_timeout, 1000) # each 1s

	def attach_periodic_callback(self, callback, callback_time):
		if self._periodic_callback is not None:
			self.dettach_periodic_callback()

		self._periodic_callback = PeriodicCallback(callback, callback_time)
		self._periodic_callback.start()
		return self._periodic_callback

	def dettach_periodic_callback(self):
		if self._periodic_callback is not None:
			self._periodic_callback.stop()
		self._periodic_callback = None

	def response_handle(self, msg):
		protocol = unpack_message(msg.body)
		msgtype, msgid, error, result, _ = protocol
		future = self.futures.pop(msgid, None)
		if not future:
			# print 'msgid %d future not existed' % msgid
			return True
		# old resp msg, ignore this msg and reset the msgid
		# if future.time > msg.timestamp/1e9:
		# 	self.futures[msgid] = future
		# 	return True

		if error: # error
			if self._rpc_error_warpper:
				error = self._rpc_error_warpper(error)
			future.set_exception(error)
		else:
			future.set_result(result)
		return True

	def close(self):
		self.cleanZombieTimer.stop()
		self.dettach_periodic_callback()
		futures = self.futures.values()
		for future in futures:
			future.set_exception('closed')
		self.futures = {}
		self.reader.close()
		self.reader = None
		self.writer = None

	def checkReader(self):
		if self.reader.stale:
			logger.warning("%s reader stale, create new reader", self.key)
			self.reader = nsq.Reader(message_handler=self.response_handle, topic=ResponseTopic(self.key), channel=ServiceRespChannel, io_loop=self.ioloop, **self.readerdefs)

	def call(self, method, *args, **kwargs):
		return self.call_async(method, *args, **kwargs).get()

	def call_async(self, method, *args, **kwargs):
		service_id = kwargs.get('service_id', None)
		return self.send_request(method, args, type=REQUEST, service_id=service_id)

	def notify(self, method, *args):
		self.send_request(method, args, type=NOTIFY)

	def send_request(self, method, args, type=REQUEST, service_id=None):
		future = None
		if type == REQUEST:
			msgid, data = pack_request(method, args, self.key)
			topic = ClientTopic(RPC if service_id else GLOBAL, service_id, method)
			# print topic, 'send_request', method, args, msgid

			future = NSQFuture(self.ioloop, self.timeout, topic=method)
			self.futures[msgid] = future
			future.add_done_callback(lambda _: self.futures.pop(msgid, None))
		else:
			msgid, data = pack_notify(method, args)
			topic = NotifyTopic(method)

		def cb(conn, ret):
			if ret != 'OK' and future:
				if True:
					logger.warning('topic %s msgid %d method %s attempting to resend in 5s', topic, msgid, method)
					resend_callback = functools.partial(self.writer.pub, topic=topic, msg=data, callback=cb)
					self.ioloop.add_timeout(datetime.timedelta(seconds=5), resend_callback)
				else:
					self.futures.pop(msgid, None)
					future.set_exception(ret)
		self.writer.pub(topic, data, callback=cb)
		return future

	def cleanZombie(self):
		nowTime = time.time()
		dels = []
		for msgid, future in self.futures.iteritems():
			if nowTime - future.time >= self.ZombieDuration:
				dels.append(msgid)
		for msgid in dels:
			# print 'msg %d was zombie' % msgid
			future = self.futures.pop(msgid, None)
			if future:
				future.set_exception('zombie timeout')

	def step_timeout(self):
		timeouts = []
		for msgid, future in self.futures.iteritems():
			if future.step_timeout():
				timeouts.append(msgid)

		if len(timeouts) == 0:
			return

		# self.ioloop.stop()
		for timeout in timeouts:
			future = self.futures.pop(timeout)
			future.set_exception(TimeoutError("%d Request timed out" % timeout))
		# self.loop.start()
