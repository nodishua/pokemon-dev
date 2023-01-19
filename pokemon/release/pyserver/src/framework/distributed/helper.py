#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2014 YouMi Information Technology Inc.
Copyright (c) 2016 TianJi Information Technology Inc.
'''
from __future__ import absolute_import

import sys
import time

from tornado.gen import coroutine, Return, sleep
from tornado.ioloop import IOLoop
from tornado.concurrent import Future, chain_future

from msgpackrpc.error import TimeoutError

from framework.log import logger


class ClientFuture(object):
	def __init__(self, key, fu):
		self.client = None
		self.key = key
		self.calls = []
		self.fu = fu
		self.timeout = None
		fu.add_done_callback(self._fu_done)

	def _fu_done(self, fu):
		self.client = fu.result()
		for call in self.calls:
			f = getattr(self.client, call[0])
			ret = call[1]
			if call[0] in ('call_async', 'call_async_always', 'notify'):
				fu = f(call[2], *call[3])
			else:
				fu = f(call[2], call[3], *call[4])
			if fu:
				chain_future(fu, ret)
		self.calls = []
		self.fu = None
		if self.timeout:
			IOLoop.current().remove_timeout(self.timeout)
			self.timeout = None

	def _fu_timeout(self):
		for call in self.calls:
			ret = call[1]
			ret.set_exception(TimeoutError('client timeout'))
		self.calls = []
		self.timeout = None

	def call(self, method, *args):
		if self.client:
			return self.client.call(method, *args)

		@coroutine
		def _coroutine():
			yield self.fu
			ret = yield self.client.call_async_always(method, *args)
			raise Return(ret)
		return IOLoop.current().run_sync(_coroutine)

	def call_async(self, method, *args):
		if self.client:
			return self.client.call_async(method, *args)
		ret = Future()
		self.calls.append(('call_async', ret, method, args))
		return ret

	def call_async_timeout(self, method, timeout, *args):
		if self.client:
			return self.client.call_async_timeout(method, timeout, *args)
		ret = Future()
		self.calls.append(('call_async_timeout', ret, method, timeout, args))
		# 简单处理，但凡有一个timeout发生，calls中全部future均弹出
		if self.timeout is None:
			self.timeout = IOLoop.current().add_timeout(time.time() + timeout, self._fu_timeout)
		return ret

	def call_async_always(self, method, *args):
		if self.client:
			return self.client.call_async_always(method, *args)
		ret = Future()
		self.calls.append(('call_async_always', ret, method, args))
		return ret

	def notify(self, method, *args):
		if self.client:
			return self.client.notify(method, *args)
		self.calls.append(('notify', None, method, args))



def multi_future(d, rasie_exc=False):
	keys = list(d.keys())
	d = d.values()
	unfinished_d = set(d)

	future = Future()
	if not d:
		future.set_result({} if keys is not None else [])
	def callback(f):
		unfinished_d.remove(f)
		if not unfinished_d:
			result_list = []
			has_except = False
			for index, i in enumerate(d):
				try:
					result_list.append(i.result())
				except Exception as e:
					has_except=True
					result_list.append(e)
					logger.exception("multi_future error, %s", keys[index])
			if rasie_exc and has_except:
				for result in result_list:
					if isinstance(result, Exception):
						future.set_exception(result)
						break
			else:
				future.set_result(dict(zip(keys, result_list)))
	for f in d:
		f.add_done_callback(callback)
	return future


# node key命名规范
# service.[language.]id
# game.tw.1

def node_key2id(key):
	domains = key.split('.')
	return int(domains[-1])

def node_key2domains(key):
	domains = key.split('.')
	if len(domains) == 3:
		return domains
	return [domains[0], None, domains[1]]

def node_key(service, id, language=None):
	domains = filter(lambda t: t is not None, [service, language, id])
	return '.'.join(domains)

def node_domains2key(domains):
	domains = filter(lambda t: t is not None, domains)
	return '.'.join(domains)

# serv key命名规范
# server_[language](%02d)id
# game_qq123, game_tw01, pvp_qq01

def serv_key2domains(key):
	l = key.split('_')
	id = filter(lambda t: t.isdigit(), l[1])
	lang = l[1][:-len(id)]
	return [l[0], None if lang == 'qq' else lang, int(id)]
