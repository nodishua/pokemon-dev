#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2014 YouMi Information Technology Inc.
Copyright (c) 2018 TianJi Information Technology Inc.
'''

class Service(object):
	def __init__(self, name, container):
		servicename, language, id = name.split('.')
		self.name = name
		self.servicename = servicename
		self.language = language
		self.id = id

		self._container = container

class RemoteService(Service):
	pass