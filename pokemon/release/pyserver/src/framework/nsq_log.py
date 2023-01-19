# -*- coding: utf-8 -*-
'''
Copyright (c) 2014 YouMi Information Technology Inc.
Copyright (c) 2016 TianJi Information Technology Inc.

remote log handler with nsq
'''

# from framework.nsq_defines import LogWriterNSQDefs
from nsq_defines import NSQDefs as LogWriterNSQDefs
import nsqrpc

import nsq
import tornado.ioloop

import logging


try:
	unicode
	_unicode = True
except NameError:
	_unicode = False


class NSQWriteStream(object):
	def __init__(self, name, stream):
		self.nsqrpc = nsqrpc.NSQClient('log', writerdefs=LogWriterNSQDefs['writer'], loop=tornado.ioloop.IOLoop.current())
		self.stream = stream
		self.logtopic = None

	def flush(self):
		self.stream.flush()

	def write(self, msg):
		stream = self.stream

		fs = "%s\n"
		if not _unicode: #if no unicode support...
			stream.write(fs % msg)
		else:
			try:
				ufs = u'%s\n'
				try:
					stream.write(ufs % msg)
				except UnicodeEncodeError:
					if getattr(stream, 'encoding', None):
						stream.write((ufs % msg).encode(stream.encoding))
					else:
						stream.write(fs % msg)
			except UnicodeError:
				stream.write(fs % msg.encode("UTF-8"))

		# self.nsqrpc.notify('logArchive', msg, self.logtopic)
		self.nsqrpc.notify('LogArchive', msg)

		# for test
		# print 'call begin'
		# ret = self.nsqrpc.call('logArchive', msg)
		# print 'call end', ret

		# print 'call async begin'
		# fu = self.nsqrpc.call_async('logArchive', msg)
		# loop = tornado.ioloop.IOLoop.current()
		# ret = [None]
		# from tornado.gen import coroutine
		# @coroutine
		# def _run():
		# 	ret[0] = yield fu
		# loop.run_sync(_run)
		# print 'call async end', ret

class NSQHandler(logging.StreamHandler):
	def __init__(self, name):
		logging.StreamHandler.__init__(self)
		self.nsqwriter = NSQWriteStream(name, self.stream)
		self.stream = self.nsqwriter

	def setLogTopic(self, topic):
		self.stream.logtopic = topic

	def close(self):
		logging.StreamHandler.close(self)

	def emit(self, record):
		try:
			msg = self.format(record)
			stream = self.stream.write(msg)
			# self.flush() # for performance, need test
		except (KeyboardInterrupt, SystemExit):
			raise
		except:
			self.handleError(record)