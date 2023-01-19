#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2014 YouMi Information Technology Inc.

server config defines
'''

from nsq_defines import *


ServerDefs = {
        'gm': {
                'key': 'gm.dev.1',
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
                'debug': False,
        },
	'gm.cn.1': {
		'key': 'gm.cn.1',
		'game_key_prefix': ['game.cn.',],
		'statistic_scope': ['tc',],
		'nsq': CNNSQDefs,
		'http_port': 38080,
		'dependent': [
			'accountdb.cn.1',
			'giftdb.cn.1',

			"game.shenhe.1",
		],
		'mongo': {
			'host': '172.16.2.2',
			'port': 27017,
			'dbname': 'gm_web',
			'username': 'gmsystem',
			'password': '123456',
		},
		'account_mongo': {
			'host': '172.16.2.7',
			'port': 27017,
			'dbname': 'account',
			'username': 'accsystem',
			'password': '123456',
		},
		'payorder_mongo': {
			'host': '172.16.2.7',
			'port': 27017,
			'dbname': 'order',
			'username': 'accsystem',
			'password': '123456',
		},
		'gift_mongo': {
			'host': '172.16.2.7',
			'port': 27017,
			'dbname': 'gift',
			'username': 'accsystem',
			'password': '123456',
		},
		'gm_stat': 'http://127.0.0.1:9991',
		'login_log_path': '/mnt/deploy_cn/childlog',
		'debug': False,
	},

	'gm.cn_qd.1': {
		'key': 'gm.cn_qd.1',
		'game_key_prefix': ['game.cn_qd.',],
		'statistic_scope': ['tc_qd',],
		'nsq': CNNSQDefs,
		'http_port': 38081,
		'dependent': [
			'accountdb.cn.1',
			'giftdb.cn.1',

			"game.shenhe.1",
		],
		'mongo': {
			'host': '172.16.2.2',
			'port': 27017,
			'dbname': 'gm_web_qd',
			'username': 'gmsystem',
			'password': '123456',
		},
		'account_mongo': {
			'host': '172.16.2.7',
			'port': 27017,
			'dbname': 'account',
			'username': 'accsystem',
			'password': '123456',
		},
		'payorder_mongo': {
			'host': '172.16.2.7',
			'port': 27017,
			'dbname': 'order',
			'username': 'accsystem',
			'password': '123456',
		},
		'gift_mongo': {
			'host': '172.16.2.7',
			'port': 27017,
			'dbname': 'gift',
			'username': 'accsystem',
			'password': '123456',
		},
		'gm_stat': 'http://127.0.0.1:9990',
		'login_log_path': '/mnt/deploy_cn/childlog',
		'debug': False,
	},

}

