#!/usr/bin/python
# -*- coding: utf-8 -*-

"""
YouMi Custom HTTP Connection
but it is unlike HTTP, more like msgpack packet
"""

import framework

from tornado import gen
from tornado import httputil
from tornado import iostream
from tornado import stack_context
from tornado.log import gen_log, app_log
from tornado.escape import native_str, utf8
from tornado.concurrent import Future
from tornado.httputil import RequestStartLine, HTTPHeaders
from tornado.http1connection import _ExceptionLoggingContext, _QuietException, HTTP1ConnectionParameters, HTTP1Connection, HTTP1ServerConnection

import struct
import msgpack
import collections

_swapB12S1 = lambda v: ((v & 0xAAA) >> 1) | ((v & 0x555) << 1)
_ymFlag = 0xA000

_YMHeaderDefinesMap = {
	'URI': 0x00,
	'ContentLength': 0x01,
	'Date': 0x02,
	'Code': 0x03,
	'Reason': 0x04,
	'Connection': 0x05, # 0 : close, 1 : keep-alive
}

_YMHeaderDefinesClass = collections.namedtuple('YMHeaderDefines', _YMHeaderDefinesMap.keys())
YMHeaderDefines = _YMHeaderDefinesClass(*_YMHeaderDefinesMap.values())

class NotYMConnection(Exception):
	pass

class YMConnection(HTTP1Connection):
	"""Implements the YouMi Custom HTTP protocol.
	"""

	sizeStruct = struct.Struct('!H') # H	unsigned short	integer	2

	def read_response(self, delegate):
		return self._read_message(delegate)

	@gen.coroutine
	def _read_message(self, delegate):
		need_delegate_close = False
		try:
			# read size (2 bytes)
			size_future = self.stream.read_bytes(2)
			if self.params.header_timeout is None:
				size_data = yield size_future
			else:
				try:
					size_data = yield gen.with_timeout(
						self.stream.io_loop.time() + self.params.header_timeout,
						size_future,
						io_loop=self.stream.io_loop)
				except gen.TimeoutError:
					self.close()
					raise gen.Return(False)

			size_data = self.sizeStruct.unpack(size_data)[0]
			if (size_data & 0xF000) != _ymFlag:
				raise NotYMConnection(size_data)
			size = _swapB12S1(size_data & 0x0FFF)

			# read header (`size` bytes)
			header_future = self.stream.read_bytes(size)
			if self.params.header_timeout is None:
				header_data = yield header_future
			else:
				try:
					header_data = yield gen.with_timeout(
						self.stream.io_loop.time() + self.params.header_timeout,
						header_future,
						io_loop=self.stream.io_loop)
				except gen.TimeoutError:
					self.close()
					raise gen.Return(False)
			start_line, headers = self._parse_headers(header_data)

			if self.is_client:
				pass # ignore client code
			else:
				self._response_start_line = start_line
				self._request_headers = headers

			self._disconnect_on_finish = not self._can_keep_alive(
				start_line, headers)
			need_delegate_close = True
			with _ExceptionLoggingContext(app_log):
				header_future = delegate.headers_received(start_line, headers)
				if header_future is not None:
					yield header_future

			if self.stream is None:
				# We've been detached.
				need_delegate_close = False
				raise gen.Return(False)

			skip_body = False
			if self.is_client:
				pass # ignore client code
			else:
				pass

			if not skip_body:
				body_future = self._read_body(
					start_line.code if self.is_client else 0, headers, delegate)
				if body_future is not None:
					if self._body_timeout is None:
						yield body_future
					else:
						try:
							yield gen.with_timeout(
								self.stream.io_loop.time() + self._body_timeout,
								body_future, self.stream.io_loop)
						except gen.TimeoutError:
							gen_log.info("Timeout reading body from %s",
										 self.context)
							self.stream.close()
							raise gen.Return(False)
			self._read_finished = True

			if not self._write_finished or self.is_client:
				need_delegate_close = False
				with _ExceptionLoggingContext(app_log):
					delegate.finish()
			# If we're waiting for the application to produce an asynchronous
			# response, and we're not detached, register a close callback
			# on the stream (we didn't need one while we were reading)
			if (not self._finish_future.done() and
					self.stream is not None and
					not self.stream.closed()):
				self.stream.set_close_callback(self._on_connection_close)
				yield self._finish_future
			if self.is_client and self._disconnect_on_finish:
				self.close()
			if self.stream is None:
				raise gen.Return(False)
		except httputil.HTTPInputError as e:
			gen_log.info("Malformed HTTP message from %s: %s",
						 self.context, e)
			self.close()
			raise gen.Return(False)
		finally:
			if need_delegate_close:
				with _ExceptionLoggingContext(app_log):
					delegate.on_connection_close()
			self._clear_callbacks()
		raise gen.Return(True)


	def _parse_headers(self, data):
		data = msgpack.unpackb(data, encoding = 'utf-8')
		return RequestStartLine('POST', '/%d' % data[YMHeaderDefines.URI], 'HTTP/1.1'), \
		HTTPHeaders({
			'Accept' : '*/*',
			'Content-Type' : 'application/x-www-form-urlencoded',
			'Content-Length' : str(data[YMHeaderDefines.ContentLength]),
			'Connection' : "keep-alive" if data.get(YMHeaderDefines.Connection, 0) == 1 else "close",
		})

	def _read_body(self, code, headers, delegate):
		if "Content-Length" in headers:
			content_length = int(headers["Content-Length"])

			if content_length > self._max_body_size:
				raise httputil.HTTPInputError("Content-Length too long")
		else:
			content_length = None

		if content_length is not None:
			return self._read_fixed_body(content_length, delegate)
		return None

	def write_headers(self, start_line, headers, chunk=None, callback=None):
		if self.is_client:
			pass # ignore client code
		else:
			self._response_start_line = start_line
			self._chunking_output = False

		if 'Content-Length' in headers:
			self._expected_content_remaining = int(headers['Content-Length'])
		else:
			self._expected_content_remaining = None

		future = None
		if self.stream.closed():
			future = self._write_future = Future()
			future.set_exception(iostream.StreamClosedError())
		else:
			if callback is not None:
				self._write_callback = stack_context.wrap(callback)
			else:
				future = self._write_future = Future()
			data = self._format_headers(start_line, headers)
			if chunk:
				data += self._format_chunk(chunk)
			self._pending_write = self.stream.write(data)
			self._pending_write.add_done_callback(self._on_write_complete)
		return future

	def _format_headers(self, start_line, headers):
		data = {
			YMHeaderDefines.Code : int(start_line.code),
			YMHeaderDefines.Reason : utf8(str(start_line.reason)),
			YMHeaderDefines.ContentLength : int(headers['Content-Length']),
			YMHeaderDefines.Date : framework.nowtime_t(),
		}
		data = msgpack.packb(data, use_bin_type = True)
		size_data = self.sizeStruct.pack(_swapB12S1(len(data) & 0x0FFF) | _ymFlag)
		return size_data + data

class YMServerConnection(HTTP1ServerConnection):
	@gen.coroutine
	def _server_request_loop(self, delegate):
		try:
			while True:
				conn = YMConnection(self.stream, False,
									   self.params, self.context)
				request_delegate = delegate.start_request(self, conn)
				try:
					ret = yield conn.read_response(request_delegate)
				except (iostream.StreamClosedError,
						iostream.UnsatisfiableReadError):
					return
				except _QuietException:
					# This exception was already logged.
					conn.close()
					return
				except NotYMConnection:
					gen_log.error("NotYMConnection, closing connection(%s).", self.stream.getpeername()[0])
					conn.close()
					return
				except Exception:
					gen_log.error("Uncaught exception, closing connection(%s).", self.stream.getpeername()[0], exc_info=True)
					conn.close()
					return
				if not ret:
					return
				yield gen.moment
		finally:
			delegate.on_close(self)
