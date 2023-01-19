#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2016 TianJi Information Technology Inc.
'''

from __future__ import absolute_import

from framework.log import logger
from framework.loop import AsyncLoop
from framework.rpc_client import Client

from tornado.gen import *
from msgpackrpc.error import TimeoutError

import copy
import time
import heapq
import random
import msgpack
import datetime
import functools
from collections import namedtuple

# 任务最大等待时间
PlayMaxWaitTime = 5

PlayInfo = namedtuple('PlayInfo', ('playID', 'playType', 'playRoles', 'send_time', 'send_rpc'))


class RPClient(Client):
	def __init__(self, idx, *args, **kwargs):
		Client.__init__(self, 'agent%02d' % idx, *args, **kwargs)
		self.last_time = time.time()
		self.play_count = 0
		self.agent_idx = idx
		self.agent_state = None


class AgentManager(object):
	def __init__(self, server, agents):
		self.server = server
		self.ioloop = server.ioloop
		self.agentRPCs = {}
		self.closedAgents = {}
		self.playMap = {}
		self.playResults = {}
		self.typeMap = {
			'test': {
				'play': self.playMap,
				'result': self.playResults,
				'method': 'hello',
			},
		}

		for idx, hostpost in enumerate(agents, 1):
			self.agentRPCs[idx] = RPClient(idx, hostpost, loop=AsyncLoop(self.ioloop), timeout=PlayMaxWaitTime)

	def checkAllAgents(self):
		def _onCheck(rpc, fu):
			try:
				ret = fu.result()
				old = rpc.play_count
				rpc.agent_state = ret
				rpc.play_count = ret[0]
				if old != rpc.play_count:
					logger.info('%s state %s' % (rpc.name, ret))
			except:
				self._repaireAgent(rpc)

		fus = []
		for idx, rpc in self.agentRPCs.iteritems():
			fu = rpc.call_async('getState')
			fus.append((fu, rpc))
		map(lambda t: t[0].add_done_callback(functools.partial(_onCheck, t[1])), fus)

	def setTypeMap(self, maps):
		self.typeMap = maps

	def _onPlayDone(self, playType, playID, rpc, fu):
		playMap = self.typeMap[playType]['play']
		playResults = self.typeMap[playType]['result']

		try:
			result = fu.result()
		except Exception, e:
			logger.warning('%s play %s %d error %s:%s' % (rpc.name, playType, playID, type(e), e))
			playMap.pop(playID, None)
			# if agent was closed, may be e is TimeoutError
			if not isinstance(e, TimeoutError):
				self._repaireAgent(rpc)
			return

		info = playMap.pop(playID, None)
		playResults[playID] = result
		if info:
			logger.info('%s play %s %d roles %s result %s', rpc.name, info.playType, info.playID, info.playRoles, result)
		else:
			logger.info('%s play %s %d result %s', rpc.name, playType, playID, result)
		rpc.last_time = time.time()
		rpc.play_count -= 1

	def _sendPlay(self, playType, playID, playModel, playRoles):
		if len(self.agentRPCs) == 0:
			return False

		st = time.time()
		agentIdx, rpc = random.choice(self.agentRPCs.items())
		playMap = self.typeMap[playType]['play']
		rpcMethod = self.typeMap[playType]['method']

		# rpc call
		data = msgpack.packb(playModel, use_bin_type=True)
		fu = None
		while len(self.agentRPCs) > 0:
			try:
				fu = rpc.call_async(rpcMethod, self.server.name, playID, data)
				break
			except Exception, e:
				# 会有StreamClosedError
				# call_async已经将报错信息放入Future来统一处理
				logger.warning('%s play %s %d error %s:%s' % (rpc.name, playType, playID, type(e), e))
				self._repaireAgent(rpc)
				agentIdx, rpc = random.choice(self.agentRPCs.items())

		data = None
		if fu is None:
			return False

		# future
		rpc.play_count += 1
		playMap[playID] = PlayInfo(playID, playType, playRoles, st, agentIdx)
		fu.add_done_callback(functools.partial(self._onPlayDone, playType, playID, rpc))
		return True

	def _syncPlayResult(self, playType):
		playResults = self.typeMap[playType]['result']
		d = copy.copy(playResults)
		playResults.clear()
		return d

	def _syncPlays(self, playType, plays):
		left = set(plays) - set(self.typeMap[playType]['play'].keys()) - set(self.typeMap[playType]['result'].keys())
		return list(left)

	@coroutine
	def _tryAgent(self, rpc):
		while not self.server.servStop:
			try:
				yield sleep(2)
				ret = yield rpc.call_async('getState')
				rpc.agent_state = ret
				rpc.play_count = ret[0]
			except:
				continue
			break

		if rpc.agent_idx in self.closedAgents:
			logger.info('agent %s come back' % rpc.name)
			self.closedAgents.pop(rpc.agent_idx)
			self.agentRPCs[rpc.agent_idx] = rpc

	def _repaireAgent(self, rpc):
		# 可能其他future已经关闭改rpc
		if rpc.agent_idx in self.agentRPCs:
			self.agentRPCs.pop(rpc.agent_idx)
			self.closedAgents[rpc.agent_idx] = rpc
			for type, d in self.typeMap.iteritems():
				playMap = d['play']
				reque = []
				for playID, info in playMap.iteritems():
					if info.send_rpc == rpc.agent_idx:
						playMap[playID] = info._replace(send_time=0, send_rpc=0)
						reque.append(playID)
				if reque:
					logger.warning('%d %s plays need re-queue %s' % (len(reque), type, reque))

			logger.warning('agent %s lost' % rpc.name)
			self._tryAgent(rpc)

			logger.info('existed agents %d %s' % (len(self.agentRPCs), [(rpc.name, rpc.hostport) for k, rpc in self.agentRPCs.iteritems()]))

