#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2014 YouMi Information Technology Inc.
Copyright (c) 2016 TianJi Information Technology Inc.
'''

from framework.distributed import ServiceDefs

class DiscoveryRPC(object):
	def __init__(self, containServ):
		self._server = containServ

	@property
	def server(self):
		return self._server

	# TODO: discovery启动一定时间内不该接受查询请求，需要等待各服务来注册

	# 只管理address，不对服务是否可用进行验证
	def node_query(self, key):
		d = self.server.nodeInfos.get(key, {})
		return key, d.get('address', None), d.get('states', None)

	# 寻找可用的跨服服务器
	def service_query(self, service, nodeKey):
		keys = list(self.server.services[service])
		keys.sort(key=lambda k: self.server.nodeOrders[k])
		for key in keys:
			if key not in self.server.nodeInfos:
				continue
			states = self.server.nodeInfos[key]['states']
			strOrList = states.get(service, None)
			# list 是固定的服务
			if isinstance(strOrList, (list, tuple)):
				if nodeKey in strOrList:
					return self.node_query(key)
			# str 是通用的服务
			elif strOrList == ServiceDefs.Idle:
				return self.node_query(key)
		return None, None, None

