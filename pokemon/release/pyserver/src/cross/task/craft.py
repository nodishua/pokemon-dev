#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2014 YouMi Information Technology Inc.
Copyright (c) 2016 TianJi Information Technology Inc.
'''

from framework.distributed import ServiceDefs
from framework.distributed.helper import node_key2domains, node_domains2key
from framework.rpc_client import rpc_coroutine
from cross.task import RPCTaskFactory
from cross.object.gglobal import ObjectCrossGlobal
from cross.object.craft_gglobal import ObjectCrossCraftServiceGlobal

import datetime
import time

from tornado.gen import Return

def game2pvpNode(gameNodeKey):
	domains = node_key2domains(gameNodeKey)
	domains[0] = 'pvp'
	return node_domains2key(domains)

def crossCraftReturn(nodeKey, value):
	return {
		'ret': value,
		'sync': ObjectCrossCraftServiceGlobal.Singleton.syncModel(nodeKey),
	}

class CrossCraftReturn(Return):
	def __init__(self, nodeKey, value=None):
		Return.__init__(self, value=crossCraftReturn(nodeKey, value))


class TCraftFactory(RPCTaskFactory):
	def craftJoin(self, nodeKey):
		# 可能idle，可能已经为node分配
		if ObjectCrossGlobal.isSerivceOK(ServiceDefs.Craft, nodeKey):
			# idle就是没有分配玩法
			if ObjectCrossGlobal.isSerivceIdle(ServiceDefs.Craft):
				return None
			return ObjectCrossCraftServiceGlobal.Singleton.dbForGame(nodeKey)
		return None

	@rpc_coroutine
	def craftGetRecord(self, nodeKey, roleKey, recordID):
		gameNodeKey, roleID = roleKey
		pvpNodeKey = game2pvpNode(gameNodeKey)
		ret = yield self.server.client(pvpNodeKey).call_async('getCrossCraftRecord', roleID, recordID)
		raise CrossCraftReturn(nodeKey, ret)

	def craftBet(self, nodeKey, myKey, roleKey, gold):
		ObjectCrossCraftServiceGlobal.Singleton.betRole(tuple(myKey), tuple(roleKey), gold)
		return crossCraftReturn(nodeKey, True)

	@rpc_coroutine
	def craftGetHistoryAndLastTime(self, nodeKey, roleKey):
		gameNodeKey, roleID = roleKey
		history = ObjectCrossCraftServiceGlobal.Singleton.getHistory(tuple(roleKey))
		lastTime = yield self.server.client(gameNodeKey).call_async('crossGetRoleLastTime', roleID)
		raise CrossCraftReturn(nodeKey, (history, lastTime))

	def craftSignSync(self, nodeKey, signup):
		ObjectCrossCraftServiceGlobal.Singleton.onGameSignUpSync(nodeKey, signup)
		return crossCraftReturn(nodeKey, True)

	def craftGetRank(self, nodeKey, roleKey, offest, size):
		ranks = ObjectCrossCraftServiceGlobal.Singleton.getRankList(offest, size)
		ret = {
			'ranks': ranks,
			'myinfo': ObjectCrossCraftServiceGlobal.Singleton.getRoleCraftInfo(tuple(roleKey)),
		}
		return crossCraftReturn(nodeKey, ret)

	def craftGetPlay(self, nodeKey, playID):
		play = ObjectCrossCraftServiceGlobal.Singleton.getPlay(playID)
		return crossCraftReturn(nodeKey, play)