# -*- coding: utf-8 -*-
'''
Copyright (c) 2014 YouMi Information Technology Inc.
Copyright (c) 2016 TianJi Information Technology Inc.
'''

from nsqrpc.message import unpack_message, pack_response, REQUEST, NOTIFY
from nsqrpc.topic import *
from nsqrpc.error import NoMethodError, MessageEvent

from nsqrpc.topic import RequestTopicAndChannel, ResponseTopic

import nsq
import tornado
from tornado.gen import coroutine, sleep

import functools
import datetime
import logging

logger = logging.getLogger(__name__)

try:
	import snappy
	_snappy = True
except:
	_snappy = False

class NSQServer(object):
	def __init__(self, key, readerdefs, loop=None, writerdefs=None):
		self.key = key
		self.ioloop = loop or tornado.ioloop.IOLoop.current()
		self.readerdefs = readerdefs
		self.writerdefs = writerdefs if writerdefs else readerdefs

		self.writer = nsq.Writer(io_loop=self.ioloop, snappy=_snappy, **self.writerdefs)
		self.readers = []

		self.methods = {}
		self._method_metadatas = []

		self._running = False
		self._stopping = False

	def register(self, serviceid, dispatcher, ignoreNotify=False):
		hset = set()
		for method in dir(dispatcher):
			if method[0] == '_':
				continue
			f = getattr(dispatcher, method)
			if not callable(f):
				continue
			ident = '%s|%s' % (serviceid, method)
			self.methods[ident] = f

			if f.__name__ == 'notify':
				if ignoreNotify:
					continue
				topic = NotifyTopic(method)
				channel = serviceid
			else:
				topic, channel = RequestTopicAndChannel(RPC, serviceid, method)
			if (topic, channel) not in hset:
				hset.add((topic, channel))
				self._method_metadatas.append((topic, channel, serviceid))

	def request_handle(self, serviceid, msg):
		if not self._running:
			return False

		protocol = unpack_message(msg.body)
		msgtype, msgid, method, args, dest = protocol
		if self._stopping:
			if method in ('AccountLogin', 'PayForRecharge'): # 开始关闭之后，不在处理这两个请求
				return False
		if msgtype == REQUEST:
			self.dispatch(serviceid, method, args, _Responser(self.writer, ResponseTopic(dest), msgid))
		else:
			self.dispatch(serviceid, method, args, _NullResponser())
		return True

	def start(self):
		if self._method_metadatas:
			for topic, channel, serviceid in self._method_metadatas:
				reader = nsq.Reader(message_handler=functools.partial(self.request_handle, serviceid), topic=topic, channel=channel, io_loop=self.ioloop, **self.readerdefs)
				self.readers.append(reader)
		self._running = True
		self._stopping = False

	def stop(self):
		self._stopping = True

	def close(self):
		self._running = False
		self._stopping = False
		self.methods = {}
		self.writer = None
		for reader in self.readers:
			reader.close()
		self.readers = []

	def dispatch(self, to, method, args, responser):
		try:
			ident = '%s|%s' % (to, method)
			func = self.methods.get(ident, None)
			if func is None:
				raise NoMethodError("'{0}' method not found".format(method))
			result = func(*args)
			if isinstance(result, AsyncResult):
				result.set_responser(responser)
			elif isinstance(result, NoReply):
				pass
			else:
				responser.set_result(result)

		except MessageEvent:
			raise

		except Exception as e:
			if not hasattr(e, 'to_msgpack'):
				e = str(e)
			responser.set_error(e)


class AsyncResult(object):
	def __init__(self):
		self._responser = None
		self._result = None

	def set_result(self, result, error=None):
		if self._responser is not None:
			self._responser.set_result(result, error)
		else:
			self._result = (result, error)

	def set_error(self, error, result=None):
		self.set_result(result, error)

	def set_responser(self, responder):
		self._responser = responder
		if self._result is not None:
			self._responser.set_result(*self._result)
			self._result = None

class NoReply(object):
	'''
	no error but do not reply
	'''
	pass

def notify(func):
	'''
	notify handler decorator
	'''
	def wrapper(*args, **kwargs):
		return func(*args, **kwargs)
	wrapper.__name__ = 'notify'
	return wrapper


class _Responser(object):
	def __init__(self, writer, topic, msgid):
		self._writer = writer
		self._topic = topic
		self._msgid = msgid
		self._sent = False

	def set_result(self, result, error=None):
		if not self._sent:
			self._sent = True
			_, data = pack_response(self._msgid, result, error)

			def cb(conn, ret):
				if ret != 'OK':
					logger.warning('topic %s msgid %d attempting to resend in 5s', self._topic, self._msgid)
					def resend_callback(fu):
						self._writer.pub(self._topic, data, cb)
					sleep(5).add_done_callback(resend_callback)
			self._writer.pub(self._topic, data, cb)

	def set_error(self, error):
		self.set_result(None, error=error)

class _NullResponser(object):
	def set_result(self, result, error=None):
		pass

	def set_error(self, error):
		pass
