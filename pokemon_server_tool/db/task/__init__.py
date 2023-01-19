#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2014 YouMi Information Technology Inc.
'''

class RPCTaskFactory(object):
	def __init__(self, serv):
		self.server = serv

	def __getattr__(self, name):
		return getattr(self.server, name)


class DBTaskError(Exception):
    'Base class for all db task errors'

