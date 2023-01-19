#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2014 YouMi Information Technology Inc.

server config defines
'''

from nsq_defines import *


ServerDefs = {
	'gm': {
		'key': 'gm.dev.9',
		'nsq': NSQDefs,
		'http_port': 39081,
		'dependent': [
			'accountdb.dev.1',
			'giftdb.dev.1',
		],
		'mongo': {
		    'port': 27018,
		    'dbname': 'gm_web'
		},
		'account_mongo': {
			'port': 27018,
			'dbname': 'account'
		},
		'payorder_mongo': {
			'port': 27018,
			'dbname': 'account'
		},
		'login_log_path': '/home/pokemon_02/deploy/childlog',
		'debug': True,
	},

	'test': {
		'key': 'gm.dev.11',
		'nsq': NSQDefs,
		'http_port': 39098,
		'dependent': [
			'accountdb.dev.1',
			'giftdb.dev.1',
			'game.dev.1',
			'game.dev.2',
			'game.dev.4',
		],
		'mongo': {
		    'host': '192.168.1.98',
		    'port': 27030,
		    'dbname': 'gm_web',
		},
		'account_mongo': {
			'host': '192.168.1.98',
			'port': 27030,
			'dbname': 'xyd'
		},
		'payorder_mongo': {
			'host': '192.168.1.98',
			'port': 27030,
			'dbname': 'xyd'
		},
		'login_log_path': '/home/pokemon_02/deploy/childlog',
		'debug': True,
	},

	'back': {
		'key': 'gm.dev.11',
		'nsq': NSQDefs,
		'http_port': 39098,
		'dependent': [
			'accountdb.dev.1',
			'giftdb.dev.1',
		],
		'mongo': {
		    'host': '192.168.1.98',
		    'port': 27030,
		    'dbname': 'gm_back',
		},
		'account_mongo': {
			'host': '192.168.1.98',
			'port': 27030,
			'dbname': 'xyd'
		},
		'payorder_mongo': {
			'host': '192.168.1.98',
			'port': 27030,
			'dbname': 'xyd'
		},
		'login_log_path': '/home/pokemon_02/deploy/childlog',
		'debug': True,
	}

}

