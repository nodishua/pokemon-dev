#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2014 YouMi Information Technology Inc.
Copyright (c) 2016 TianJi Information Technology Inc.
'''

class RPCTaskFactory(object):
	def __init__(self, serv):
		self.server = serv

	def __getattr__(self, name):
		return getattr(self.server, name)


