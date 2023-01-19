#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2014 YouMi Information Technology Inc.
'''
from defines import ServerDefs
from framework.rpc_client import Client as ClientBase

class Client(ClientBase):

	def __init__(self, name, loop=None, timeout=10):
		self.servName = name
		hostport = (ServerDefs[self.servName]['ip'], ServerDefs[self.servName]['rpc_port'])
		ClientBase.__init__(self, name, hostport, loop, timeout)

		self.clientName = '[%s] Game RPC Client' % name
		print self.clientName, 'connect to', self.hostport#, self.call('_hello', self.clientName)


