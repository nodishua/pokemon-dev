#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2014 YouMi Information Technology Inc.
Copyright (c) 2016 TianJi Information Technology Inc.
'''
from __future__ import absolute_import

import sys
import time

import msgpackrpc
from tornado.gen import coroutine, Return, sleep
from tornado.ioloop import PeriodicCallback, IOLoop
from tornado.concurrent import Future, chain_future

from framework.log import logger
from framework.loop import AsyncLoop
from framework.rpc_client import rpc_coroutine, Client
from framework.distributed import ServiceDefs
from framework.distributed.service import Service
from framework.distributed.helper import multi_future, ClientFuture

from msgpackrpc.error import TransportError

GameServInternalPassword = 'huanxi2394fd79a1ad32ff2e2db603da'
NodeCallTimeout = 5
NodeCommitTimeout = 4*NodeCallTimeout # 防止组织者挂了，参与者一直阻塞死等

class NodeClient(Client):
	def __init__(self, node, name, hostport, loop=None, timeout=24, on_reconn=None):
		self.node = node
		Client.__init__(self, name, hostport, loop, timeout, on_reconn)

	def call_async(self, method, *args):
		try:
			ret = Client.call_async(self, method, *args)
		except Exception as e:
			if isinstance(e, TransportError):
				self.node.on_node_lost(self.name)
			raise e
		return ret

class Node(msgpackrpc.Server):
	@property
	def ioloop(self):
		return self._loop._ioloop

	def __init__(self, key, dispatcher, onTransactionCommit=None, loop=None):
		self.key = key
		self.serviceStates = {}
		self.nodeName = '[%s] RPC Distributed Node' % key

		self.tscVotes = {} # {transaction: (key, time)}
		self.tscCommits = {}
		if onTransactionCommit:
			self.onTransactionCommit = onTransactionCommit

		self.stopped = False
		self.nodeClients = {} # {key: rpc_client or future}
		self.nodeInfos = {} # {key: {address, states, last_time}}
		self.discoveryClient = None
		self.discoveryHelloTimer = None
		msgpackrpc.Server.__init__(self, dispatcher, loop)

	def listen(self, address):
		self._address = address # Session._address
		msgpackrpc.Server.listen(self, address)

	def start(self):
		msgpackrpc.Server.start(self)
		self.connect_discovery()

	def stop(self):
		self.stopped = True
		if self.discoveryHelloTimer:
			self.discoveryHelloTimer.stop()

		msgpackrpc.Server.stop(self)
		msgpackrpc.Server.close(self)

	'''
	RPC Client Manager
	'''
	def connect(self, key):
		address = self.nodeInfos.get(key, {}).get('address', None)
		last_time = self.nodeInfos.get(key, {}).get('last_time', 0)
		# 1小时过期重新discovery
		if time.time() - last_time > 1 * 3600.:
			address = None
		if address:
			if key in self.nodeClients:
				return
			client = NodeClient(self, key, address, self._loop)
			self.nodeClients[key] = client
		else:
			self.nodeClients.pop(key, None)
			return self.discovery(key=key)

	# always return client, may be connected, may be conencting, may be not existed
	def client(self, key):
		self.connect(key)
		ret = self.nodeClients.get(key, None)
		if isinstance(ret, Client):
			return ret

		fu = Future()
		def _connect(_):
			self.connect(key)
			ret = self.nodeClients.get(key, None)
			if isinstance(ret, Client):
				fu.set_result(ret)
			else:
				ret.add_done_callback(lambda _: sleep(1).add_done_callback(_connect))
		ret.add_done_callback(_connect)
		return ClientFuture(key, fu)

	# choose one client for service, or designated client
	def service(self, service, clientKey=None):
		return Service(self, service, clientKey=clientKey)

	def broadcast(self, clientKeys, method, *args):
		if clientKeys and not isinstance(clientKeys, (tuple, list)):
			clientKeys = [clientKeys]

		result = {}
		for key in clientKeys:
			client = self.client(key)
			result[key] = client.call_async_timeout(method, NodeCallTimeout, *args)
		return multi_future(result)

	def wait_clients_ok(self, clientKeys, checkMethod, checkRet=None):
		ret = Future()

		def _hello(cb):
			self.broadcast(clientKeys, checkMethod).add_done_callback(cb)

		def _check(fu):
			try:
				result = fu.result()
			except Exception as e:
				sleep(1).add_done_callback(lambda _: _hello(_check))
				return

			if len(clientKeys) == len(result):
				for k, accept in result.iteritems():
					if checkRet and not checkRet(accept):
						sleep(1).add_done_callback(lambda _: _hello(_check))
						return
					# 如果返回不是True，重试
					if accept is not True:
						sleep(1).add_done_callback(lambda _: _hello(_check))
						return
				logger.info('wait_clients_ok %s', clientKeys)
				ret.set_result(True)

		_hello(_check)
		return ret

	def clear(self):
		self.nodeInfos = {}

	def set_service_state(self, service, state):
		self.serviceStates[service] = state

	def reset_service_states(self, states):
		self.serviceStates = states

	def set_discovery(self, address):
		self.discoveryClient = Client('discovery', address, self._loop)

	def connect_discovery(self):
		if self.discoveryClient and not self.discoveryHelloTimer:
			flag = [None]
			def check(fu):
				ret = 'ok'
				try:
					fu.result()
				except Exception as e:
					ret = 'failed in %s' % str(e)
				finally:
					self.discoveryHelloTimer.start()
				if flag[0] != ret:
					if ret == 'ok':
						logger.info('discovery connected')
					else:
						logger.warning('discovery lost, %s', ret)
						self.clear()
					flag[0] = ret

			def hello():
				self.discoveryHelloTimer.stop()
				fu = self.discoveryClient.call_async('_fw_hello', self.key, self.address.unpack(), self.serviceStates)
				fu.add_done_callback(check)
			self.discoveryHelloTimer = PeriodicCallback(hello, 30000, self.ioloop)
			self.discoveryHelloTimer.start()

	def on_node_lost(self, key):
		client = self.nodeClients.pop(key, None)
		if isinstance(client, Client):
			client.close()
		self.nodeInfos.pop(key, None)

	def discovery(self, key=None, service=None):
		ret = Future()
		if self.discoveryClient:
			def checkin(fu):
				try:
					k, address, states = fu.result()
					ret.set_result((k, address, states))
					self.nodeClients.pop(key, None)
					if k and address and states is not None:
						client = NodeClient(self, k, address, self._loop)
						self.nodeInfos[k] = {
							'address': address,
							'states': states,
							'last_time': time.time(),
						}
						self.nodeClients[k] = client

				except Exception as e:
					# logger.warning('discovery %s error %s', key, e)
					self.on_node_lost(key)
					ret.set_result((None, None, None))

			if key:
				fu = self.discoveryClient.call_async_timeout('node_query', 1, key)
				self.nodeClients[key] = fu
			elif service:
				fu = self.discoveryClient.call_async_timeout('service_query', 1, service, self.key)
			fu.add_done_callback(checkin)

		else:
			ret.set_exception(Exception('no discovery'))
		return ret

	'''
	RPC framework
	'''
	# inherit from `msgpackrpc.Server.dispatch`
	def dispatch(self, method, param, responder):
		if method == '_fw_hello':
			key, address, states = param
			address = (responder._sendable._stream.getpeername()[0], address[1]) # 用sock的ip比较准确，配置的可能是内网ip
			param = (key, address, states)
			result = self._fw_hello(*param)
			responder.set_result(result)

		elif hasattr(self, method):
			old, self._dispatcher = self._dispatcher, self
			msgpackrpc.Server.dispatch(self, method, param, responder)
			self._dispatcher = old

		else:
			msgpackrpc.Server.dispatch(self, method, param, responder)

	def _fw_hello(self, key, address, states):
		if key not in self.nodeInfos:
			logger.info('_fw_hello %s %s %s', key, address, states)
		elif states != self.nodeInfos[key]['states']:
			logger.info('_fw_hello %s %s %s -> %s states changed', key, address, self.nodeInfos[key]['states'], states)

		self.nodeInfos[key] = {
			'address': address,
			'states': states,
			'last_time': time.time(),
		}
		return 'ok', self.key, self.address.unpack(), self.serviceStates

	@rpc_coroutine
	def _exec_py(self, src):
		if src.find(GameServInternalPassword) < 0:
			raise Return(None)

		ret = None
		try:
			exec(src)
			if 'exec_func' in locals():
				ret = exec_func(self)
			if 'exec_coroutine' in locals():
				ret = yield exec_coroutine(self)
		except Exception, e:
			logger.exception('_exec_py Error')
			raise Return(str(e))
		raise Return(ret)

	'''
	二阶段提交
	'''
	def _vote_transaction(self, key, transaction):
		if transaction in self.tscCommits:
			return self.tscCommits[transaction]
		if transaction not in self.tscVotes:
			self.tscVotes[transaction] = (key, time.time())
		else:
			if time.time() - self.tscVotes[transaction][1] > NodeCommitTimeout:
				self.tscVotes[transaction] = (key, time.time())
			elif key < self.tscVotes[transaction]:
				self.tscVotes[transaction] = (key, time.time())
		return self.tscVotes[transaction][0]

	@rpc_coroutine
	def _commit_transaction(self, key, transaction):
		if transaction in self.tscCommits:
			raise Return(self.tscCommits[transaction])
		if transaction not in self.tscVotes:
			raise Return('error')
		if key == self.tscVotes[transaction][0]:
			self.tscVotes.pop(transaction)
			# commited状态需要上层应用手动清理
			self.tscCommits[transaction] = key
			if self.onTransactionCommit:
				ret = yield self.onTransactionCommit(self, key, transaction)
				if ret is False:
					raise Return('refuse')
			raise Return(key)
		else:
			raise Return(self.tscVotes[transaction][0])

	def _committed_over(self, key, transaction):
		if key == self.tscCommits.get(transaction, None):
			self.tscCommits.pop(transaction)
		return True

	# commit transaction to servers
	# transaction for server is race resource
	def transaction_commit(self, keys, transaction):
		ret = Future()

		def over_phase(fu):
			try:
				result = fu.result()
			except Exception as e:
				result = {}

			# over状态保证之前的清理完毕
			ok = False
			if len(keys) == len(result):
				for k, accept in result.iteritems():
					if accept is not True:
						break
				ok = True
			if ok:
				logger.info('transaction %s over %s', transaction, result)
			else:
				self.broadcast(keys, '_committed_over', self.key, transaction).add_done_callback(over_phase)

		def commit_phase(fu):
			try:
				result = fu.result()
			except Exception as e:
				ret.set_exception(e)
				return

			logger.info('transaction %s commit %s', transaction, result)
			# 一定需要所有server都确认，才能开启该玩法
			if len(keys) == len(result):
				for k, accept in result.iteritems():
					# 如果返回不是str，那一般都是Exception，重试
					if not isinstance(accept, str):
						ret.set_exception(Exception('%s node commit exception %s' % (k, accept)))
						return
					# 有其它候选cross，放弃
					if accept != self.key:
						ret.set_result(False)
						return
				# 获取全部资源commit成功
				ret.set_result(True)
				# commit资源使用完毕，持续性事务由逻辑上层来判断
				self.broadcast(keys, '_committed_over', self.key, transaction).add_done_callback(over_phase)
			else:
				ret.set_exception(Exception('some node not responsed in commit'))

		def vote_phase(fu):
			try:
				result = fu.result()
			except Exception as e:
				ret.set_exception(e)
				return

			logger.info('transaction %s vote %s', transaction, result)
			# 一定需要所有server都确认，才能开启该玩法
			if len(keys) == len(result):
				for k, accept in result.iteritems():
					# 如果返回不是str，那一般都是Exception，重试
					if not isinstance(accept, str):
						ret.set_exception(Exception('%s node vote exception %s' % (k, accept)))
						return
					# 有其它候选cross，放弃
					if accept != self.key:
						ret.set_result(False)
						return
				# 获取全部资源vote成功
				self.broadcast(keys, '_commit_transaction', self.key, transaction).add_done_callback(commit_phase)
			else:
				ret.set_exception(Exception('some node not responsed in vote'))

		self.broadcast(keys, '_vote_transaction', self.key, transaction).add_done_callback(vote_phase)
		return ret

