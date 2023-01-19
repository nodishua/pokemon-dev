#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2014 YouMi Information Technology Inc.

Here Classes and Functions are use for local internal network.
'''

from framework.log import logger

import struct
import socket
import platform
import msgpack


class LANetTask(object):
	'''
	A utility class to write and read task from `NetConn` or `NetGeventConn`.
	convenient wrapper for TCP task protocol.
	the task use in local internal network.

	LANetTask: [len(4 bytes) cmd(4 bytes) syn_id(4 bytes)][data(len)]
	'''

	headStruct = struct.Struct('!III')
	synIDCounter = 1
	synIDMax = 4294967200 # 4294967296 unsigned int, 4bytes

	def __init__(self, conn, cmd = None, data = None, synID = None):
		if synID is not None:
			self.synID = synID
		else:
			self.synID = LANetTask.synIDCounter
			LANetTask.synIDCounter = LANetTask.synIDCounter + 1
			if LANetTask.synIDCounter >= LANetTask.synIDMax:
				LANetTask.synIDCounter = 1

		self.len = 0
		self.cmd = cmd
		self.data = data
		self.conn = conn

	def write(self):
		data = msgpack.packb(self.data, use_bin_type=True)
		packData = LANetTask.headStruct.pack(len(data), self.cmd, self.synID) + data
		self.conn.write(packData)

	def readBegin(self):
		return self.conn.read_bytes(LANetTask.headStruct.size, self.readHead)

	def readHead(self, data):
		self.len, self.cmd, self.synID = LANetTask.headStruct.unpack(data)
		return self.conn.read_bytes(self.len, self.readBody)

	def readBody(self, data):
		self.data = msgpack.unpackb(data, encoding='utf-8')
		self.conn.taskRecvCB(self.conn, self)

class NetConn(object):
	'''
	A managed connection class.
	convenient wrapper for `tornado.iostream`.
	'''

	conns = set()

	def __init__(self, stream, address, taskRecvCB, sockCloseCB = None, ntaskCls = LANetTask, logger_ = logger):
		'''
		``stream`` is `tornado.iostream` or `gevent.socket`.
		``address`` just for debug and display.
		when a task be received, ``taskRecvCB`` will be invoked by `ntaskCls`.
		when self connection is closed, ``sockCloseCB`` will be in invoked.
		'''
		NetConn.conns.add(self)

		# stream socket options
		sock = stream.socket
		# sock.setsockopt(socket.SOL_SOCKET, socket.SO_KEEPALIVE, 1)
		# sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
		# if platform.system() == 'Linux':
		# 	sock.setsockopt(socket.SOL_TCP, socket.TCP_KEEPIDLE, 60)
		# 	sock.setsockopt(socket.SOL_TCP, socket.TCP_KEEPINTVL, 5)
		# 	sock.setsockopt(socket.SOL_TCP, socket.TCP_KEEPCNT, 20)

		self.stream = stream
		self.address = address
		self.taskRecvCB = taskRecvCB
		self.sockCloseCB = sockCloseCB
		self.ntaskCls = ntaskCls
		self.logger = logger_ if logger_ else logger
		# self._last_read_size = None
		# self._last_cb = None
		# self._last_read_future = None

		self.stream.set_close_callback(self.onClose)
		self.recvTask = ntaskCls(self, synID = 0) # synID = 0, purpose to avoid recv task will inc LANetTask.synIDCounter
		self.logger.debug('new NetConn %s <-> %s', sock.getsockname(), sock.getpeername())


	@property
	def sock(self):
		return self.stream.socket

	def runRead(self):
		'''
		it must be non-blocking function
		'''
		self.recvTask.readBegin()

	def read_bytes(self, size, cb):
		return self.stream.read_bytes(size, cb)

	# def read_bytes(self, size, cb):
	# 	# print 'NetConn.read_bytes', self.sock.getsockname(), '<-', self.sock.getpeername(), size
	# 	def _on_read(data):
	# 		cb = self._last_cb
	# 		self._last_read_size = None
	# 		self._last_cb = None
	# 		self._last_read_future = None
	# 		cb(data)

	# 	self._last_cb = cb
	# 	if self._last_read_size is None:
	# 		self._last_read_size = size
	# 		self._last_read_future = self.stream.read_bytes(size, _on_read)
	# 	else:
	# 		if self._last_read_size == size:
	# 			pass
	# 		else:
	# 			self._last_read_future = self.stream.read_bytes(size, _on_read)
	# 	return self._last_read_future

	def readNext(self):
		'''
		it must be non-blocking function
		'''
		# old task may be in queue to be handling
		self.recvTask = self.ntaskCls(self, synID = 0)
		self.runRead()

	def write(self, data):
		self.stream.write(data)

	def send(self, cmd, data):
		'''
		return task synID
		'''
		ntask = self.ntaskCls(self, cmd, data)
		ntask.write()
		# print "NetConn.send", self.sock.getsockname(), '->', self.sock.getpeername(), 'cmd=%d, synID=%d' % (ntask.cmd, ntask.synID)
		return ntask.synID

	def close(self):
		self.stream.close()
		NetConn.conns.discard(self)
		cb = self.sockCloseCB
		self.sockCloseCB = None
		if cb:
			cb(self)

	def closed(self):
		return self.stream.closed()

	def onClose(self):
		'''
		if stream closed, it will be invoke.
		'''
		self.logger.debug('NetConn connection has left.', clientip=self.address)
		self.close()

