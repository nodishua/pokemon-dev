#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2014 YouMi Information Technology Inc.

cross server config defines
'''

from agent_defines import *

ServerDefs = {
	'cross': {
		'db': 'cross_db',
		'host': '0.0.0.0',
		'port': 58888,
		'anti_server': AntiServers,
		'discovery': 'discovery',
		'key': 'cross.dev.1',
		'log_topic': 'cross',
	},

	'cross_dev': {
		'db': 'cross_db_dev',
		'host': '0.0.0.0',
		'port': 58887,
		'anti_server': AntiServers,
		'discovery': 'discovery',
		'key': 'cross.dev.2',
		'log_topic': 'cross',
	},

	# tc-shuma-02
	# 123.207.111.69(公)
	# 10.104.174.86(内)
	'cross_qq01': {
		'db': 'cross_db_qq01',
		'host': '0.0.0.0',
		'port': 58888,
		'anti_server': QQAntiServers,
		'discovery': 'discovery_qq',
		'key': 'cross.1',
		'log_topic': 'cross',
	},

	# tc-shuma-03
	# 115.159.183.222(外)
	# 10.105.207.210(内)
	'cross_qq02': {
		'db': 'cross_db_qq02',
		'host': '0.0.0.0',
		'port': 58888,
		'anti_server': QQAntiServers,
		'discovery': 'discovery_qq',
		'key': 'cross.2',
		'log_topic': 'cross_qq02',
	},
	'cross_qq03': {
		'db': 'cross_db_qq03',
		'host': '0.0.0.0',
		'port': 58889,
		'anti_server': QQAntiServers,
		'discovery': 'discovery_qq',
		'key': 'cross.3',
		'log_topic': 'cross_qq03',
	},

	# tc-shuma-04
	# 115.159.83.118(外)
	# 10.105.246.50(内)
	'cross_qq04': {
		'db': 'cross_db_qq04',
		'host': '0.0.0.0',
		'port': 58888,
		'anti_server': QQAntiServers,
		'discovery': 'discovery_qq',
		'key': 'cross.4',
		'log_topic': 'cross_qq04',
	},
	'cross_qq05': {
		'db': 'cross_db_qq05',
		'host': '0.0.0.0',
		'port': 58889,
		'anti_server': QQAntiServers,
		'discovery': 'discovery_qq',
		'key': 'cross.5',
		'log_topic': 'cross_qq05',
	},

	# tc-shuma-05
	# 115.159.44.187(外)
	# 10.105.235.38(内)
	'cross_qq06': {
		'db': 'cross_db_qq06',
		'host': '0.0.0.0',
		'port': 58888,
		'anti_server': QQAntiServers,
		'discovery': 'discovery_qq',
		'key': 'cross.6',
		'log_topic': 'cross_qq06',
	},
	'cross_qq07': {
		'db': 'cross_db_qq07',
		'host': '0.0.0.0',
		'port': 58889,
		'anti_server': QQAntiServers,
		'discovery': 'discovery_qq',
		'key': 'cross.7',
		'log_topic': 'cross_qq07',
	},

	# tc-shuma-06
	# 115.159.125.78(外)
	# 10.105.125.91(内)
	'cross_qq08': {
		'db': 'cross_db_qq08',
		'host': '0.0.0.0',
		'port': 58888,
		'anti_server': QQAntiServers,
		'discovery': 'discovery_qq',
		'key': 'cross.8',
		'log_topic': 'cross_qq08',
	},
	'cross_qq09': {
		'db': 'cross_db_qq09',
		'host': '0.0.0.0',
		'port': 58889,
		'anti_server': QQAntiServers,
		'discovery': 'discovery_qq',
		'key': 'cross.9',
		'log_topic': 'cross_qq09',
	},

	# tc-shuma-07
	# 115.159.102.209(外)
	# 10.105.208.165(内)
	'cross_qq10': {
		'db': 'cross_db_qq10',
		'host': '0.0.0.0',
		'port': 58888,
		'anti_server': QQAntiServers,
		'discovery': 'discovery_qq',
		'key': 'cross.10',
		'log_topic': 'cross_qq10',
	},
	'cross_qq11': {
		'db': 'cross_db_qq11',
		'host': '0.0.0.0',
		'port': 58889,
		'anti_server': QQAntiServers,
		'discovery': 'discovery_qq',
		'key': 'cross.11',
		'log_topic': 'cross_qq11',
	},

	# tc-shuma-08
	# 115.159.3.100(外)
	# 10.105.202.147(内)
	'cross_qq12': {
		'db': 'cross_db_qq12',
		'host': '0.0.0.0',
		'port': 58888,
		'anti_server': QQAntiServers,
		'discovery': 'discovery_qq',
		'key': 'cross.12',
		'log_topic': 'cross_qq12',
	},
	'cross_qq13': {
		'db': 'cross_db_qq13',
		'host': '0.0.0.0',
		'port': 58889,
		'anti_server': QQAntiServers,
		'discovery': 'discovery_qq',
		'key': 'cross.13',
		'log_topic': 'cross_qq13',
	},

	# tc-shuma-09
	# 115.159.22.50(外)
	# 10.105.197.220(内)
	'cross_qq14': {
		'db': 'cross_db_qq14',
		'host': '0.0.0.0',
		'port': 58888,
		'anti_server': QQAntiServers,
		'discovery': 'discovery_qq',
		'key': 'cross.14',
		'log_topic': 'cross_qq14',
	},
	'cross_qq15': {
		'db': 'cross_db_qq15',
		'host': '0.0.0.0',
		'port': 58889,
		'anti_server': QQAntiServers,
		'discovery': 'discovery_qq',
		'key': 'cross.15',
		'log_topic': 'cross_qq15',
	},

	# tc-shuma-10
	# 115.159.99.91(外)
	# 10.105.192.46(内)
	'cross_qq16': {
		'db': 'cross_db_qq16',
		'host': '0.0.0.0',
		'port': 58888,
		'anti_server': QQAntiServers,
		'discovery': 'discovery_qq',
		'key': 'cross.16',
		'log_topic': 'cross_qq16',
	},
	'cross_qq17': {
		'db': 'cross_db_qq17',
		'host': '0.0.0.0',
		'port': 58889,
		'anti_server': QQAntiServers,
		'discovery': 'discovery_qq',
		'key': 'cross.17',
		'log_topic': 'cross_qq17',
	},

	# tc-shuma-11
	# 115.159.36.101(外)
	# 10.105.26.65(内)
	'cross_qq18': {
		'db': 'cross_db_qq18',
		'host': '0.0.0.0',
		'port': 58888,
		'anti_server': QQAntiServers,
		'discovery': 'discovery_qq',
		'key': 'cross.18',
		'log_topic': 'cross_qq18',
	},
	'cross_qq19': {
		'db': 'cross_db_qq19',
		'host': '0.0.0.0',
		'port': 58889,
		'anti_server': QQAntiServers,
		'discovery': 'discovery_qq',
		'key': 'cross.19',
		'log_topic': 'cross_qq19',
	},

	# tc-shuma-12
	# 115.159.59.152(外)
	# 10.133.200.249(内)
	'cross_qq20': {
		'db': 'cross_db_qq20',
		'host': '0.0.0.0',
		'port': 58888,
		'anti_server': QQAntiServers,
		'discovery': 'discovery_qq',
		'key': 'cross.20',
		'log_topic': 'cross_qq20',
	},
	'cross_qq21': {
		'db': 'cross_db_qq21',
		'host': '0.0.0.0',
		'port': 58889,
		'anti_server': QQAntiServers,
		'discovery': 'discovery_qq',
		'key': 'cross.21',
		'log_topic': 'cross_qq21',
	},

	# tc-shuma-13
	# 182.254.216.172(外)
	# 10.133.194.88(内)
	'cross_qq22': {
		'db': 'cross_db_qq22',
		'host': '0.0.0.0',
		'port': 58888,
		'anti_server': QQAntiServers,
		'discovery': 'discovery_qq',
		'key': 'cross.22',
		'log_topic': 'cross_qq22',
	},
	'cross_qq23': {
		'db': 'cross_db_qq23',
		'host': '0.0.0.0',
		'port': 58889,
		'anti_server': QQAntiServers,
		'discovery': 'discovery_qq',
		'key': 'cross.23',
		'log_topic': 'cross_qq23',
	},

	# tc-shuma-14
	# 182.254.241.252(外)
	# 10.133.200.54(内)
	'cross_qq24': {
		'db': 'cross_db_qq24',
		'host': '0.0.0.0',
		'port': 58888,
		'anti_server': QQAntiServers,
		'discovery': 'discovery_qq',
		'key': 'cross.24',
		'log_topic': 'cross_qq24',
	},
	'cross_qq25': {
		'db': 'cross_db_qq25',
		'host': '0.0.0.0',
		'port': 58889,
		'anti_server': QQAntiServers,
		'discovery': 'discovery_qq',
		'key': 'cross.25',
		'log_topic': 'cross_qq25',
	},

	# tc-shuma-15
	# 115.159.200.184(外)
	# 10.105.58.19(内)
	'cross_qq26': {
		'db': 'cross_db_qq26',
		'host': '0.0.0.0',
		'port': 58888,
		'anti_server': QQAntiServers,
		'discovery': 'discovery_qq',
		'key': 'cross.26',
		'log_topic': 'cross_qq26',
	},
	'cross_qq27': {
		'db': 'cross_db_qq27',
		'host': '0.0.0.0',
		'port': 58889,
		'anti_server': QQAntiServers,
		'discovery': 'discovery_qq',
		'key': 'cross.27',
		'log_topic': 'cross_qq27',
	},

	# tc-shuma-16
	# 115.159.185.23(外)
	# 10.105.6.156(内)
	'cross_qq28': {
		'db': 'cross_db_qq28',
		'host': '0.0.0.0',
		'port': 58888,
		'anti_server': QQAntiServers,
		'discovery': 'discovery_qq',
		'key': 'cross.28',
		'log_topic': 'cross_qq28',
	},
	'cross_qq29': {
		'db': 'cross_db_qq29',
		'host': '0.0.0.0',
		'port': 58889,
		'anti_server': QQAntiServers,
		'discovery': 'discovery_qq',
		'key': 'cross.29',
		'log_topic': 'cross_qq29',
	},

	######################################
	# 繁体版本
	# tc-shuma-tw-01
	# 119.28.61.236
	'cross_tw01': {
		'db': 'cross_db_tw01',
		'host': '0.0.0.0',
		'port': 58888,
		'anti_server': TWAntiServers,
		'discovery': 'discovery_tw',
		'key': 'cross.tw.1',
		'log_topic': 'cross',
	},
}
