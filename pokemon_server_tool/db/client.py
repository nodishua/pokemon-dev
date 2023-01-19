#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2014 YouMi Information Technology Inc.
'''
import defines
from framework.rpc_client import Client as ClientBase

class Client(ClientBase):

	def __init__(self, name, loop=None):
		self.servName = defines.ClientDefs[name]['server']
		hostport = (defines.ServerDefs[self.servName]['host'], defines.ServerDefs[self.servName]['port'])
		ClientBase.__init__(self, name, hostport, loop, timeout=None)

		self.clientName = '[%s] DB RPC Client' % name
		print self.clientName, 'connect to', self.hostport#, self.call('_hello', self.clientName)

