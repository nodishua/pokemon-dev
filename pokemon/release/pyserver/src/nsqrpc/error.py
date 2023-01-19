# -*- coding: utf-8 -*-
'''
Copyright (c) 2014 YouMi Information Technology Inc.
Copyright (c) 2016 TianJi Information Technology Inc.
'''

class RPCError(Exception):
	def to_msgpack(self):
		return [self.message]

	@staticmethod
	def from_msgpack(message):
		return RPCError(message)

class TimeoutError(RPCError):
	pass

class NSQError(RPCError):
	pass

class NoMethodError(RPCError):
	pass

class CallError(RPCError):
	def __init__(self, msg, topic=None, **kwargs):
		RPCError.__init__(self, '%s, topic %s' % (msg, topic) if topic else msg)
		self.msg = msg
		self.kwargs = kwargs

	def to_msgpack(self):
		return self.msg

	@staticmethod
	def from_msgpack(msgpack, topic=None):
		# server-side may be not python
		msg, kwargs = '', {}
		if isinstance(msgpack, str):
			msg = msgpack
		elif isinstance(msgpack, Exception):
			return msgpack
		elif isinstance(msgpack, dict):
			msg = msgpack.pop('msg')
			kwargs = msgpack.pop('kwargs')
		else:
			msg = str(msgpack)
		return CallError(msg, topic=topic, **kwargs)


# https://pynsq.readthedocs.org/en/latest/message.html
# http://wiki.jikexueyuan.com/project/nsq-guide/tcp_protocol_spec.html
# finish
# requeue
# touch
class MessageEvent(Exception):
	CODE = '.finish'

class RequeueMessage(MessageEvent):
	CODE = '.requeue'

class TouchMessage(MessageEvent):
	CODE = '.touch'

class DispatcherInvaild(Exception):
	pass
