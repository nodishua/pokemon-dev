#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2016 TianJi Information Technology Inc.
'''

from __future__ import absolute_import

from framework.log import logger
from framework.agentmgr import AgentManager


class CrossAgentManager(AgentManager):
	def __init__(self, server, agents):
		AgentManager.__init__(self, server, agents)
		# cross_craft
		self.playMap = {}
		self.playResults = {}

		self.setTypeMap({
			'cross_craft': {
				'play': self.playMap,
				'result': self.playResults,
				'method': 'newCrossCraftRecord',
			}
		})

	# 跨服王者争霸
	def sendCraftPlay(self, playObj):
		return self._sendPlay('cross_craft', playObj.id, playObj.db, (playObj.role_key, playObj.defence_role_key))

	def syncCraftPlayResults(self):
		return self._syncPlayResult('cross_craft')

	def syncCraftPlays(self, plays):
		return self._syncPlays('cross_craft', plays)
