#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2014 YouMi Information Technology Inc.

Here Classes and Functions are use for remote extenal network.
'''

from net import NetConn
from framework.log import logger

import lz4
import zlib
import time
import math
import struct
import socket
import random
import msgpack
import binascii
import platform
from Crypto.Cipher import AES


from tornado.gen import coroutine

class WANetTaskFlag(object):

	flagStruct = struct.Struct('!B') # B	unsigned char	integer	1
	flagMask = 0xFF
	magicFlag = 0x80 # 1000 0000
	okACKBit = 0
	errACKBit = 1
	heartSynBit = 2
	zipFlagBit = 3
	longLenFlagBit = 4
	ackFlagBit = 5
	urlFlagBit = 6

	def __init__(self, ok_ack = False, err_ack = False, heart_syn = False, zip_flag = False, long_len_flag = False, ack_flag = False, url_flag = False, old_flag = None):
		self.flag = self.magicFlag if old_flag is None else old_flag.flag
		self.ok_ack = ok_ack
		self.err_ack = err_ack
		self.heart_syn = heart_syn
		self.zip_flag = zip_flag
		self.long_len_flag = long_len_flag
		self.ack_flag = ack_flag
		self.url_flag = url_flag

	def is_valid(self):
		if (self.flag & self.magicFlag) != self.magicFlag:
			return False
		cnt = 0
		for x in [self.ok_ack, self.err_ack, self.heart_syn, any([self.zip_flag, self.long_len_flag, self.ack_flag])]:
			cnt += 1 if x else 0
		# cnt = 0 when it is normal task, no zip, not long, send syn
		if cnt > 1:
			return False
		return True

	def __str__(self):
		return '%s ok_ack %d err_ack %d heart_syn %d zip_flag %d long_len_flag %d ack_flag %d url_flag %d' % (object.__str__(self), self.ok_ack, self.err_ack, self.heart_syn, self.zip_flag, self.long_len_flag, self.ack_flag, self.url_flag)

	@property
	def ok_ack(self):
		return True if (self.flag & (1 << self.okACKBit)) > 0 else False

	@ok_ack.setter
	def ok_ack(self, b):
		if b:
			self.flag |= (1 << self.okACKBit)
		else:
			self.flag &= (self.flagMask ^ (1 << self.okACKBit))

	@property
	def err_ack(self):
		return True if (self.flag & (1 << self.errACKBit)) > 0 else False

	@err_ack.setter
	def err_ack(self, b):
		if b:
			self.flag |= (1 << self.errACKBit)
		else:
			self.flag &= (self.flagMask ^ (1 << self.errACKBit))

	@property
	def heart_syn(self):
		return True if (self.flag & (1 << self.heartSynBit)) > 0 else False

	@heart_syn.setter
	def heart_syn(self, b):
		if b:
			self.flag |= (1 << self.heartSynBit)
		else:
			self.flag &= (self.flagMask ^ (1 << self.heartSynBit))

	@property
	def zip_flag(self):
		return True if (self.flag & (1 << self.zipFlagBit)) > 0 else False

	@zip_flag.setter
	def zip_flag(self, b):
		if b:
			self.flag |= (1 << self.zipFlagBit)
		else:
			self.flag &= (self.flagMask ^ (1 << self.zipFlagBit))

	@property
	def long_len_flag(self):
		return True if (self.flag & (1 << self.longLenFlagBit)) > 0 else False

	@long_len_flag.setter
	def long_len_flag(self, b):
		if b:
			self.flag |= (1 << self.longLenFlagBit)
		else:
			self.flag &= (self.flagMask ^ (1 << self.longLenFlagBit))

	@property
	def ack_flag(self):
		return True if (self.flag & (1 << self.ackFlagBit)) > 0 else False

	@ack_flag.setter
	def ack_flag(self, b):
		if b:
			self.flag |= (1 << self.ackFlagBit)
		else:
			self.flag &= (self.flagMask ^ (1 << self.ackFlagBit))

	@property
	def url_flag(self):
		return True if (self.flag & (1 << self.urlFlagBit)) > 0 else False

	@url_flag.setter
	def url_flag(self, b):
		if b:
			self.flag |= (1 << self.urlFlagBit)
		else:
			self.flag &= (self.flagMask ^ (1 << self.urlFlagBit))

	@classmethod
	def getLen(cls):
		return cls.flagStruct.size

	def pack(self):
		return self.flagStruct.pack(self.flag)

	def unpack(self, data):
		self.flag, = self.flagStruct.unpack(data)

class WANetOkAckTask(object):
	bodyStruct = struct.Struct('!H') # H	unsigned short	integer	2
	def __init__(self, conn, synID):
		self.conn = conn
		self.synID = synID
	def readBegin(self):
		return self.conn.read_bytes(self.bodyStruct.size, self.readHead)
	def readHead(self, data):
		self.synID = self.bodyStruct.unpack(data)
		return self.readBody(None)
	def readBody(self, data):
		self.conn.taskRecvCB(self.conn, self)
	def write(self):
		flag = WANetTaskFlag(ok_ack = True)
		self.conn.stream.write(flag.pack() + self.bodyStruct.pack(self.synID))

class WANetErrAckTask(object):
	bodyStruct = struct.Struct('!H') # H	unsigned short	integer	2
	def __init__(self, conn, synID):
		self.conn = conn
		self.synID = synID
	def readBegin(self):
		return self.conn.read_bytes(self.bodyStruct.size, self.readHead)
	def readHead(self, data):
		self.synID = self.bodyStruct.unpack(data)
		return self.readBody(None)
	def readBody(self):
		self.conn.taskRecvCB(self.conn, self)
	def write(self):
		flag = WANetTaskFlag(err_ack = True)
		self.conn.stream.write(flag.pack() + self.bodyStruct.pack(self.synID))

class WANetHeartSynTask(object):
	def __init__(self, conn):
		self.conn = conn
	def readBegin(self):
		return self.readHead(None)
	def readHead(self, data):
		return self.readBody(None)
	def readBody(self, data):
		self.conn.taskRecvCB(self.conn, self)
	def write(self):
		flag = WANetTaskFlag(heart_syn = True)
		self.conn.stream.write(flag.pack())

class WANetTask(object):
	'''
	A utility class to write and read task from `NetConn` or `NetGeventConn`.
	convenient wrapper for TCP task protocol.
	the task use in remote extenal network.

	WANetTask: [flag(1 byte)][...]

	flag: [1:ok_ack][2:err_ack][3:heart_syn][4:zip_flag][5:long_len_flag][6:ack_flag][7-8:magic_flag]

		`1:ok_ack`: [syn_id(2 bytes)]
			mean is ok ack, no other data
		`2:err_ack`: [syn_id(2 bytes)]
			mean is err ack, no other data
		`3:heart_syn`: None
			mean is heart-beat syn, no other data, need client heart ack
		`4:zip_flag`:
			mean `data`: AES128_CBC(raw_data + '\0'*pad_len)
		`5:long_len_flag`:
			mean `len`(4 bytes)
		`6:ack_flag`:
			mean packet is ack, its syn_id belong to client
		`7:url_flag`:
			mean cmd is salt, urlLen and url will append
		`8:magic_flag`:
			magic binary bit: 1

	normal task: [len(*2 bytes) pad_len(1 byte) crc32(4 bytes) cmd(2 bytes) syn_id(2 bytes)][urlLen(1 byte) url(urlLen)][data(len)]

		`crc32`: crc32(data + str(cmd) + str(syn_id))
		`data`: AES128_CBC(ZIP(raw_data) + '\0'*pad_len)

	'''

	headStruct = struct.Struct('!HBIHHB')
	headLongStruct = struct.Struct('!IBIHHB')
	synIDCounter = 1
	synIDMax = 65500 # 65536 unsigned short, 2bytes
	normalTaskLenMax = 65535
	AESIV = 'YouMi_Technology'
	AESPWD = 'tjshuma081610888'

	def __init__(self, conn, cmd = None, url = None, data = None, synID = None, pwd = None):
		self.len = 0
		self.uncompressLen = 0
		self.cmd = cmd
		self.url = url
		self.flag = None
		self.ackID = None
		self.firstReadTime = None
		self.fullReadTime = None

		if pwd is not None:
			self.pwd = pwd
		else:
			self.pwd = WANetTask.AESPWD

		if synID is not None:
			self.synID = synID
			self.ackID = synID
		else:
			self.synID = WANetTask.synIDCounter
			WANetTask.synIDCounter = WANetTask.synIDCounter + 1
			if WANetTask.synIDCounter >= WANetTask.synIDMax:
				WANetTask.synIDCounter = 1

		if url is not None:
			self.cmd = random.randint(1, 65500)

		self.data = data
		self.conn = conn

	@property
	def logger(self):
		return self.conn.logger

	def write(self):
		if self.conn is None:
			raise Exception("WANetTask no conn for write")

		flag = WANetTaskFlag(zip_flag = True, ack_flag = True if self.ackID else False, url_flag = True)
		pad_len = 0
		data = msgpack.packb(self.data, use_bin_type=True)
		urldata = "%s%s%s" % (self.url, chr(random.randint(1, 255)), chr(random.randint(1, 255)))

		# print 'url and flag', self.url, flag
		# print 'after msgpack', len(data), [ord(x) for x in data]

		if len(data) < 32:
			flag.zip_flag = False
			zdata = data
		else:
			# zdata = zlib.compress(data)
			zdata = lz4.compress(data)
			if len(data) <= len(zdata):
				flag.zip_flag = False
				zdata = data
			else:
				# print 'after zlib', len(zdata)
				pass

		if len(zdata) % 16 != 0:
			pad_len = 16 - len(zdata) % 16
			zdata += '\0' * pad_len
		if len(urldata) % 16 != 0:
			url_pad_len = 16 - len(urldata) % 16
			urldata += '\0' * url_pad_len

		# print 'urldata', repr(urldata)
		# print 'aes pwd', repr(self.pwd), binascii.hexlify(self.pwd)

		aes = AES.new(self.pwd, AES.MODE_CBC, WANetTask.AESIV)
		zdata = aes.encrypt(zdata)
		aes = AES.new(WANetTask.AESPWD, AES.MODE_CBC, WANetTask.AESIV)
		urldata = aes.encrypt(urldata)

		crc = zlib.crc32(zdata) & 0xffffffff
		crc = zlib.crc32(str(self.cmd), crc) & 0xffffffff
		crc = zlib.crc32(str(self.synID), crc) & 0xffffffff
		crc = zlib.crc32(self.url, crc) & 0xffffffff

		# print 'after AES encrypt', len(zdata), [ord(x) for x in zdata]
		# print 'write crc', crc

		packObj = WANetTask.headStruct
		if len(zdata) > WANetTask.normalTaskLenMax:
			packObj = WANetTask.headLongStruct
			flag.long_len_flag = True

		self.conn.stream.write(flag.pack())
		self.conn.stream.write(packObj.pack(len(zdata), pad_len, crc, self.cmd, self.synID, len(self.url)))
		self.conn.stream.write(urldata)
		self.conn.stream.write(zdata)

		# print 'write len(pack data) =', len(packData)

	def readBegin(self):
		# print 'readBegin', self, WANetTaskFlag.getLen()
		return self.conn.read_bytes(WANetTaskFlag.getLen(), self.readFlagAndTask)

	def readFlagAndTask(self, data):
		self.firstReadTime = time.time()
		self.flag = WANetTaskFlag()
		self.flag.unpack(data)

		# print 'readFlagAndTask', self, self.flag

		try:
			if not self.flag.is_valid():
				raise Exception('invalid task! (flag is wrong, %s)' % bin(self.flag.flag))
		except:
			self.destroy()
			raise

		if self.flag.ok_ack:
			ntask = WANetOkAckTask(self.conn, None)
			return ntask, ntask.readBegin()
		elif self.flag.err_ack:
			ntask = WANetErrAckTask(self.conn, None)
			return ntask, ntask.readBegin()
		elif self.flag.heart_syn:
			ntask = WANetHeartSynTask(self.conn)
			return ntask, ntask.readBegin()

		packStruct = self.getPackStruct()
		# print packStruct.size
		return self, self.conn.read_bytes(packStruct.size, self.readHead)

	def readHead(self, data):
		packStruct = self.getPackStruct()
		self.len, self.pad_len, self.crc, self.cmd, self.synID, self.url_len = packStruct.unpack(data)
		self.uncompressLen = self.len
		if self.flag.url_flag:
			urlLen = int(math.ceil((self.url_len+2)/16.0)*16)
			# print 'urlLen', urlLen
			return self.conn.read_bytes(urlLen, self.readHeadExtra)
		return self.conn.read_bytes(self.len, self.readBody)

	def readHeadExtra(self, data):
		aes = AES.new(WANetTask.AESPWD, AES.MODE_CBC, WANetTask.AESIV)
		data = aes.decrypt(data)
		self.url = data[:self.url_len]
		# print 'url', repr(data), self.url_len, data[:self.url_len]
		return self.conn.read_bytes(self.len, self.readBody)

	def readBody(self, data):
		recvLen = len(data)
		try:
			crc = zlib.crc32(data) & 0xffffffff
			crc = zlib.crc32(str(self.cmd), crc) & 0xffffffff
			crc = zlib.crc32(str(self.synID), crc) & 0xffffffff
			crc = zlib.crc32(self.url, crc) & 0xffffffff
			if crc != self.crc:
				raise Exception('invalid task! (crc is wrong, l=%x, n=%x)' % (crc, self.crc))

			# print 'data', [ord(x) for x in data]

			aes = AES.new(self.pwd, AES.MODE_CBC, WANetTask.AESIV)
			data = aes.decrypt(data)

			# print 'aes_password', self.pwd
			# print 'after decrypt', [ord(x) for x in data]

			if self.pad_len > 0:
				data = data[:-self.pad_len]
			# print 'after unpadding', [ord(x) for x in data]
			if self.flag.zip_flag:
				# data = zlib.decompress(data)
				data = lz4.uncompress(data)

			# print 'after unzip', [ord(x) for x in data]
			self.uncompressLen = len(data)
			self.data = msgpack.unpackb(data, encoding='utf-8')

			# print 'after msgunpack', self.data
		except:
			self.destroy()
			logger.warning('readBody error! flag: %s, url: %s, len %d, recvLen %d, dataLen: %d' % (str(self.flag), str(self.url), self.len, recvLen, len(data)))
			# logger.debug('%s', ' '.join(['%d' % ord(x) for x in data])) # dangerous when data too large
			raise

		self.fullReadTime = time.time()
		self.conn.taskRecvCB(self.conn, self)

	def getPackStruct(self):
		if self.flag is None:
			return None
		packStruct = WANetTask.headStruct
		if self.flag.long_len_flag:
			packStruct = WANetTask.headLongStruct
		return packStruct

	def destroy(self):
		if self.conn:
			self.conn.close()
		self.conn = None
		self.forgetData()

	def forgetData(self):
		del self.data

	@property
	def ioTime(self):
		return self.fullReadTime - self.firstReadTime

#
# WANetBroadcastTask
#
# broadcast for all session, and fill synID and pwd in run
#
class WANetBroadcastTask(WANetTask):
	def __init__(self, url=None, data=None):
		WANetTask.__init__(self, None, url=url, data=data)

	def writeOne(self, conn, synID, pwd):
		self.conn = conn
		self.synID = synID
		self.pwd = pwd
		WANetTask.write(self)
		self.conn = None
		self.synID = None
		self.pwd = None

#
# WANetConn
#
class WANetConn(NetConn):
	def __init__(self, stream, address, taskRecvCB, sockCloseCB = None, ntaskCls = WANetTask, logger = None, aesPwd = None):

		NetConn.__init__(self, stream, address, taskRecvCB, sockCloseCB, ntaskCls, logger)
		self.heartLastTime = time.time()
		self.aesPwd = aesPwd

	def readNext(self):
		self.recvTask = self.ntaskCls(self, synID = 0, pwd = self.aesPwd)
		self.runRead()

	def send(self, cmd, data):
		ntask = self.ntaskCls(self, cmd, data, pwd = self.aesPwd)
		ntask.write()
		return ntask.synID

	def setAESPwd(self, pwd):
		if self.aesPwd != pwd:
			self.aesPwd = pwd
			if self.recvTask:
				self.recvTask.pwd = pwd
			# self.recvTask = self.ntaskCls(self, synID = 0, pwd = self.aesPwd)
			# self.runRead()

#
# WANetClientConn
#
# must be established when client connection coming
#
class WANetClientConn(WANetConn):
	def __init__(self, *args, **kwargs):
		WANetConn.__init__(self, *args, **kwargs)
		self.aesPwd = None

	def close(self):
		try:
			# graceful close for client LUA socket
			if self.stream and not self.stream.closed():
				self.stream.fileno().shutdown(socket.SHUT_RDWR)
		except Exception, e:
			self.logger.warning(e)
		WANetConn.close(self)