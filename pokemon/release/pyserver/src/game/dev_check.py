#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2014 YouMi Information Technology Inc.
Copyright (c) 2020 TianJi Information Technology Inc.
'''

import json
import os.path

import framework
from framework.distributed.helper import node_key2domains

def checkCross():
	if not os.path.isdir("../release"):
		print 'no release dir in parent, ignore checkCross'

	with open('../release/cross/defines.json', 'rb') as fp:
		d = json.load(fp)

	with open('../release/alpha/defines.json', 'rb') as fp:
		d2 = json.load(fp)
		d.update(d2)

	h = {}
	for _, dd in d.iteritems():
		services = dd['services']
		for svc in services:
			domains = node_key2domains(svc['name'])
			serviceName, serverKey, serverIdx = domains[0], domains[1], int(domains[2])
			if serviceName not in h:
				h[serviceName] = {}
			h[serviceName][serverKey] = max(serverIdx, h[serviceName].get(serverKey, 0))

	from framework.csv import csv

	for id in csv.cross.service:
		cfg = csv.cross.service[id]
		if cfg.cross.find('.') == -1:
			continue
		domains = node_key2domains(cfg.cross)
		serviceName, serverKey, serverIdx = domains[0], domains[1], int(domains[2])
		if serverKey == 'dev':
			continue
		if serviceName not in h:
			raise Exception('no such service ' + serviceName)
		if serverIdx > h[serviceName].get(serverKey, 0):
			raise Exception('no more cross server for %s, max config was %s' % (cfg.cross, h[serviceName].get(serverKey, 0)))


if hasattr(framework, '__dev__'):
	checkCross()