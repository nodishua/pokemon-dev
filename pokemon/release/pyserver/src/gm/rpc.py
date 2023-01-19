#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2014 YouMi Information Technology Inc.
Copyright (c) 2016 TianJi Information Technology Inc.
'''
import binascii

from framework.service.rpc_client import nsqrpc_coroutine as rpc_coroutine
from nsqrpc.server import notify


class GMWebRPC(object):
	def __init__(self, server):
		self._server = server

	@property
	def server(self):
		return self._server

	@property
	def messageMap(self):
		return self._server.messageMap

	@notify
	def chatMessage(self, gameName, type, msg):
		# print gameName, type, msg
		# game\object\game\message.py
		# Msg = namedtuple('Msg', ('id', 't', 'msg', 'type', 'role', 'args'))
		t = msg[1]
		role = msg[4]
		data = {
			'gameName': gameName,
			'type': type,
			'time': t,
			'msg': msg[2],
			'roleID': binascii.hexlify(role['id']),
			'roleName': role['name'],
			'roleLevel': role['level'],
			'roleVIP': role['vip'],
		}

		que = self.messageMap['All']
		que.appendleft(data)
		while len(que) > 0:
			if t - que[-1]['time'] > 24*3600:
				que.pop()
			else:
				break


