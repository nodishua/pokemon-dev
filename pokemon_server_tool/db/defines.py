#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2014 YouMi Information Technology Inc.

server config defines
'''

ServerDefs = {
	'game': {
		'redis': {
			'host': '0.0.0.0',
			'port': 26379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 27776,
		'log_topic': 'game',
	},
	'game_dev': {
		'redis': {
			'host': '0.0.0.0',
			'port': 26380,
			'db': 0,
			'password': 'redis123',
		},
		'host': '0.0.0.0',
		'port': 37776,
		'log_topic': 'game_dev',
	},
	'game_dev2': {
		'redis': {
			'host': '0.0.0.0',
			'port': 26381,
			'db': 0,
			'password': 'redis123',
		},
		'host': '192.168.1.125',
		'port': 47776,
		'log_topic': 'game_dev2',
	},
	'game_dev3': {
		'redis': {
			'host': '0.0.0.0',
			'port': 26381,
			'db': 1,
			'password': 'redis123',
		},
		'host': '192.168.1.125',
		'port': 57776,
		'log_topic': 'game_dev2',
	},
	'game_dev4': {
		'redis': {
			'host': '0.0.0.0',
			'port': 26479,
			'db': 0,
			'password': 'redis123',
		},
		'host': '192.168.1.125',
		'port': 57777,
		'log_topic': 'game_dev4',
	},
	'account': {
		'redis': {
			'host': '0.0.0.0',
			'port': 26379,
			'db': 1,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 27777,
		'log_topic': 'global',
	},
	# gm 和 account 共用同一个db_server
	'gm': {
		'redis': {
			'host': '0.0.0.0',
			'port': 26379,
			'db': 1,
			'password': 'redis123',
		},
		'host': '0.0.0.0',
		'port': 27777,
		'log_topic': 'global',
	},
	'payment': {
		'redis': {
			'host': '0.0.0.0',
			'port': 26379,
			'db': 2,
			'password': 'redis123',
		},
		'host': '0.0.0.0',
		'port': 27778,
		'log_topic': 'global',
	},
	'gift': {
		'redis': {
			'host': '0.0.0.0',
			'port': 26379,
			'db': 3,
			'password': 'redis123',
		},
		'host': '0.0.0.0',
		'port': 27779,
		'log_topic': 'global',
	},
	'gmweb': {
		'redis': {
			'host': '0.0.0.0',
			'port': 26379,
			'db': 4,
			'password': 'redis123',
		},
	},
	'cross': {
		'redis': {
			'host': '0.0.0.0',
			'port': 26379,
			'db': 5,
			'password': 'redis123',
		},
		'host': '0.0.0.0',
		'port': 27780,
		'log_topic': 'global',
	},
	'cross_dev': {
		'redis': {
			'host': '0.0.0.0',
			'port': 26379,
			'db': 6,
			'password': 'redis123',
		},
		'host': '0.0.0.0',
		'port': 27781,
		'log_topic': 'global',
	},


	##########################

	# tc-shuma-01
	# 123.207.108.22(公)
	# 10.104.187.76(内)
	'account_qq': {
		'redis': {
			'host': '0.0.0.0',
			'port': 10379,
			'db': 1,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 27777,
		'log_topic': 'global',
	},
	# gm 和 account 共用同一个db_server
	'gm_qq': {
		'redis': {
			'host': '0.0.0.0',
			'port': 10379,
			'db': 1,
			'password': 'redis123',
		},
		'host': '0.0.0.0',
		'port': 27777,
		'log_topic': 'global',
	},
	'payment_qq': {
		'redis': {
			'host': '0.0.0.0',
			'port': 10379,
			'db': 2,
			'password': 'redis123',
		},
		'host': '0.0.0.0',
		'port': 27778,
		'log_topic': 'global',
	},
	'gift_qq': {
		'redis': {
			'host': '0.0.0.0',
			'port': 10379,
			'db': 3,
			'password': 'redis123',
		},
		'host': '123.207.108.22',
		'port': 27779,
		'log_topic': 'global',
	},
	# 独立redis
	'gmweb_qq': {
		'redis': {
			'host': '0.0.0.0',
			'port': 11379,
			'db': 4,
			'password': 'redis123',
		},
	},

	# tc-shuma-02
	# 123.207.111.69(公)
	# 10.104.174.86(内)
	'game_qq01': {
		'redis': {
			'host': '0.0.0.0',
			'port': 10379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 10777,
		'log_topic': 'game_qq01',
	},
	'game_qq02': {
		'redis': {
			'host': '0.0.0.0',
			'port': 11379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 11777,
		'log_topic': 'game_qq02',
	},
	'game_qq03': {
		'redis': {
			'host': '0.0.0.0',
			'port': 12379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 12777,
		'log_topic': 'game_qq03',
	},
	'game_qq04': {
		'redis': {
			'host': '0.0.0.0',
			'port': 13379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 13777,
		'log_topic': 'game_qq04',
	},
	'game_qq05': {
		'redis': {
			'host': '0.0.0.0',
			'port': 14379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 14777,
		'log_topic': 'game_qq05',
	},
	'game_qq06': {
		'redis': {
			'host': '0.0.0.0',
			'port': 15379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 15777,
		'log_topic': 'game_qq06',
	},
	'game_qq07': {
		'redis': {
			'host': '0.0.0.0',
			'port': 16379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 16777,
		'log_topic': 'game_qq07',
	},
	'game_qq08': {
		'redis': {
			'host': '0.0.0.0',
			'port': 17379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 17777,
		'log_topic': 'game_qq08',
	},

	'cross_qq01': {
		'redis': {
			'host': '0.0.0.0',
			'port': 18379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 10666,
		'log_topic': 'global',
	},

	# tc-shuma-03
	# 115.159.183.222(公)
	# 10.105.207.210(内)
	'game_qq09': {
		'redis': {
			'host': '0.0.0.0',
			'port': 10379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 10777,
		'log_topic': 'game_qq09',
	},
	'game_qq10': {
		'redis': {
			'host': '0.0.0.0',
			'port': 11379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 11777,
		'log_topic': 'game_qq10',
	},
	'game_qq11': {
		'redis': {
			'host': '0.0.0.0',
			'port': 12379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 12777,
		'log_topic': 'game_qq11',
	},
	'game_qq12': {
		'redis': {
			'host': '0.0.0.0',
			'port': 13379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 13777,
		'log_topic': 'game_qq12',
	},
	'game_qq13': {
		'redis': {
			'host': '0.0.0.0',
			'port': 14379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 14777,
		'log_topic': 'game_qq13',
	},
	'game_qq14': {
		'redis': {
			'host': '0.0.0.0',
			'port': 15379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 15777,
		'log_topic': 'game_qq14',
	},
	'game_qq15': {
		'redis': {
			'host': '0.0.0.0',
			'port': 16379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 16777,
		'log_topic': 'game_qq15',
	},
	'game_qq16': {
		'redis': {
			'host': '0.0.0.0',
			'port': 17379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 17777,
		'log_topic': 'game_qq16',
	},

	'cross_qq02': {
		'redis': {
			'host': '0.0.0.0',
			'port': 18379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 10666,
		'log_topic': 'global',
	},

	'cross_qq03': {
		'redis': {
			'host': '0.0.0.0',
			'port': 18379,
			'db': 1,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 10667,
		'log_topic': 'global',
	},

	# tc-shuma-04
	# 115.159.83.118(公)
	# 10.105.246.50(内)
	'game_qq17': {
		'redis': {
			'host': '0.0.0.0',
			'port': 10379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 10777,
		'log_topic': 'game_qq17',
	},
	'game_qq18': {
		'redis': {
			'host': '0.0.0.0',
			'port': 11379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 11777,
		'log_topic': 'game_qq18',
	},
	'game_qq19': {
		'redis': {
			'host': '0.0.0.0',
			'port': 12379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 12777,
		'log_topic': 'game_qq19',
	},
	'game_qq20': {
		'redis': {
			'host': '0.0.0.0',
			'port': 13379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 13777,
		'log_topic': 'game_qq20',
	},
	'game_qq21': {
		'redis': {
			'host': '0.0.0.0',
			'port': 14379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 14777,
		'log_topic': 'game_qq21',
	},
	'game_qq22': {
		'redis': {
			'host': '0.0.0.0',
			'port': 15379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 15777,
		'log_topic': 'game_qq22',
	},
	'game_qq23': {
		'redis': {
			'host': '0.0.0.0',
			'port': 16379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 16777,
		'log_topic': 'game_qq23',
	},
	'game_qq24': {
		'redis': {
			'host': '0.0.0.0',
			'port': 17379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 17777,
		'log_topic': 'game_qq24',
	},

	'cross_qq04': {
		'redis': {
			'host': '0.0.0.0',
			'port': 18379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 10666,
		'log_topic': 'global',
	},

	'cross_qq05': {
		'redis': {
			'host': '0.0.0.0',
			'port': 18379,
			'db': 1,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 10667,
		'log_topic': 'global',
	},

	# tc-shuma-05
	# 115.159.44.187(公)
	# 10.105.235.38(内)
	'game_qq25': {
		'redis': {
			'host': '0.0.0.0',
			'port': 10379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 10777,
		'log_topic': 'game_qq25',
	},
	'game_qq26': {
		'redis': {
			'host': '0.0.0.0',
			'port': 11379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 11777,
		'log_topic': 'game_qq26',
	},
	'game_qq27': {
		'redis': {
			'host': '0.0.0.0',
			'port': 12379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 12777,
		'log_topic': 'game_qq27',
	},
	'game_qq28': {
		'redis': {
			'host': '0.0.0.0',
			'port': 13379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 13777,
		'log_topic': 'game_qq28',
	},
	'game_qq29': {
		'redis': {
			'host': '0.0.0.0',
			'port': 14379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 14777,
		'log_topic': 'game_qq29',
	},
	'game_qq30': {
		'redis': {
			'host': '0.0.0.0',
			'port': 15379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 15777,
		'log_topic': 'game_qq30',
	},
	'game_qq31': {
		'redis': {
			'host': '0.0.0.0',
			'port': 16379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 16777,
		'log_topic': 'game_qq31',
	},
	'game_qq32': {
		'redis': {
			'host': '0.0.0.0',
			'port': 17379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 17777,
		'log_topic': 'game_qq32',
	},

	'cross_qq06': {
		'redis': {
			'host': '0.0.0.0',
			'port': 18379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 10666,
		'log_topic': 'global',
	},

	'cross_qq07': {
		'redis': {
			'host': '0.0.0.0',
			'port': 18379,
			'db': 1,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 10667,
		'log_topic': 'global',
	},

	# tc-shuma-06
	# 115.159.125.78(公)
	# 10.105.125.91(内)
	'game_qq33': {
		'redis': {
			'host': '0.0.0.0',
			'port': 10379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 10777,
		'log_topic': 'game_qq33',
	},
	'game_qq34': {
		'redis': {
			'host': '0.0.0.0',
			'port': 11379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 11777,
		'log_topic': 'game_qq34',
	},
	'game_qq35': {
		'redis': {
			'host': '0.0.0.0',
			'port': 12379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 12777,
		'log_topic': 'game_qq35',
	},
	'game_qq36': {
		'redis': {
			'host': '0.0.0.0',
			'port': 13379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 13777,
		'log_topic': 'game_qq36',
	},
	'game_qq37': {
		'redis': {
			'host': '0.0.0.0',
			'port': 14379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 14777,
		'log_topic': 'game_qq37',
	},
	'game_qq38': {
		'redis': {
			'host': '0.0.0.0',
			'port': 15379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 15777,
		'log_topic': 'game_qq38',
	},
	'game_qq39': {
		'redis': {
			'host': '0.0.0.0',
			'port': 16379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 16777,
		'log_topic': 'game_qq39',
	},
	'game_qq40': {
		'redis': {
			'host': '0.0.0.0',
			'port': 17379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 17777,
		'log_topic': 'game_qq40',
	},

	'cross_qq08': {
		'redis': {
			'host': '0.0.0.0',
			'port': 18379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 10666,
		'log_topic': 'global',
	},

	'cross_qq09': {
		'redis': {
			'host': '0.0.0.0',
			'port': 18379,
			'db': 1,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 10667,
		'log_topic': 'global',
	},

	# tc-shuma-07
	# 115.159.102.209(公)
	# 10.105.208.165(内)
	'game_qq41': {
		'redis': {
			'host': '0.0.0.0',
			'port': 10379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 10777,
		'log_topic': 'game_qq41',
	},
	'game_qq42': {
		'redis': {
			'host': '0.0.0.0',
			'port': 11379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 11777,
		'log_topic': 'game_qq42',
	},
	'game_qq43': {
		'redis': {
			'host': '0.0.0.0',
			'port': 12379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 12777,
		'log_topic': 'game_qq43',
	},
	'game_qq44': {
		'redis': {
			'host': '0.0.0.0',
			'port': 13379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 13777,
		'log_topic': 'game_qq44',
	},
	'game_qq45': {
		'redis': {
			'host': '0.0.0.0',
			'port': 14379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 14777,
		'log_topic': 'game_qq45',
	},
	'game_qq46': {
		'redis': {
			'host': '0.0.0.0',
			'port': 15379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 15777,
		'log_topic': 'game_qq46',
	},
	'game_qq47': {
		'redis': {
			'host': '0.0.0.0',
			'port': 16379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 16777,
		'log_topic': 'game_qq47',
	},
	'game_qq48': {
		'redis': {
			'host': '0.0.0.0',
			'port': 17379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 17777,
		'log_topic': 'game_qq48',
	},

	'cross_qq10': {
		'redis': {
			'host': '0.0.0.0',
			'port': 18379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 10666,
		'log_topic': 'global',
	},

	'cross_qq11': {
		'redis': {
			'host': '0.0.0.0',
			'port': 18379,
			'db': 1,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 10667,
		'log_topic': 'global',
	},

	# tc-shuma-08
	# 115.159.3.100(公)
	# 10.105.202.147(内)
	'game_qq49': {
		'redis': {
			'host': '0.0.0.0',
			'port': 10379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 10777,
		'log_topic': 'game_qq49',
	},
	'game_qq50': {
		'redis': {
			'host': '0.0.0.0',
			'port': 11379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 11777,
		'log_topic': 'game_qq50',
	},
	'game_qq51': {
		'redis': {
			'host': '0.0.0.0',
			'port': 12379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 12777,
		'log_topic': 'game_qq51',
	},
	'game_qq52': {
		'redis': {
			'host': '0.0.0.0',
			'port': 13379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 13777,
		'log_topic': 'game_qq52',
	},
	'game_qq53': {
		'redis': {
			'host': '0.0.0.0',
			'port': 14379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 14777,
		'log_topic': 'game_qq53',
	},
	'game_qq54': {
		'redis': {
			'host': '0.0.0.0',
			'port': 15379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 15777,
		'log_topic': 'game_qq54',
	},
	'game_qq55': {
		'redis': {
			'host': '0.0.0.0',
			'port': 16379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 16777,
		'log_topic': 'game_qq55',
	},
	'game_qq56': {
		'redis': {
			'host': '0.0.0.0',
			'port': 17379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 17777,
		'log_topic': 'game_qq56',
	},

	'cross_qq12': {
		'redis': {
			'host': '0.0.0.0',
			'port': 18379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 10666,
		'log_topic': 'global',
	},

	'cross_qq13': {
		'redis': {
			'host': '0.0.0.0',
			'port': 18379,
			'db': 1,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 10667,
		'log_topic': 'global',
	},

	# tc-shuma-09
	# 115.159.22.50(公)
	# 10.105.197.220(内)
	'game_qq57': {
		'redis': {
			'host': '0.0.0.0',
			'port': 10379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 10777,
		'log_topic': 'game_qq57',
	},
	'game_qq58': {
		'redis': {
			'host': '0.0.0.0',
			'port': 11379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 11777,
		'log_topic': 'game_qq58',
	},
	'game_qq59': {
		'redis': {
			'host': '0.0.0.0',
			'port': 12379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 12777,
		'log_topic': 'game_qq59',
	},
	'game_qq60': {
		'redis': {
			'host': '0.0.0.0',
			'port': 13379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 13777,
		'log_topic': 'game_qq60',
	},
	'game_qq61': {
		'redis': {
			'host': '0.0.0.0',
			'port': 14379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 14777,
		'log_topic': 'game_qq61',
	},
	'game_qq62': {
		'redis': {
			'host': '0.0.0.0',
			'port': 15379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 15777,
		'log_topic': 'game_qq62',
	},
	'game_qq63': {
		'redis': {
			'host': '0.0.0.0',
			'port': 16379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 16777,
		'log_topic': 'game_qq63',
	},
	'game_qq64': {
		'redis': {
			'host': '0.0.0.0',
			'port': 17379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 17777,
		'log_topic': 'game_qq64',
	},

	'cross_qq14': {
		'redis': {
			'host': '0.0.0.0',
			'port': 18379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 10666,
		'log_topic': 'global',
	},

	'cross_qq15': {
		'redis': {
			'host': '0.0.0.0',
			'port': 18379,
			'db': 1,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 10667,
		'log_topic': 'global',
	},

	# tc-shuma-10
	# 115.159.99.91(公)
	# 10.105.192.46(内)
	'game_qq65': {
		'redis': {
			'host': '0.0.0.0',
			'port': 10379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 10777,
		'log_topic': 'game_qq65',
	},
	'game_qq66': {
		'redis': {
			'host': '0.0.0.0',
			'port': 11379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 11777,
		'log_topic': 'game_qq66',
	},
	'game_qq67': {
		'redis': {
			'host': '0.0.0.0',
			'port': 12379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 12777,
		'log_topic': 'game_qq67',
	},
	'game_qq68': {
		'redis': {
			'host': '0.0.0.0',
			'port': 13379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 13777,
		'log_topic': 'game_qq68',
	},
	'game_qq69': {
		'redis': {
			'host': '0.0.0.0',
			'port': 14379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 14777,
		'log_topic': 'game_qq69',
	},
	'game_qq70': {
		'redis': {
			'host': '0.0.0.0',
			'port': 15379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 15777,
		'log_topic': 'game_qq70',
	},
	'game_qq71': {
		'redis': {
			'host': '0.0.0.0',
			'port': 16379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 16777,
		'log_topic': 'game_qq71',
	},
	'game_qq72': {
		'redis': {
			'host': '0.0.0.0',
			'port': 17379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 17777,
		'log_topic': 'game_qq72',
	},

	'cross_qq16': {
		'redis': {
			'host': '0.0.0.0',
			'port': 18379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 10666,
		'log_topic': 'global',
	},

	'cross_qq17': {
		'redis': {
			'host': '0.0.0.0',
			'port': 18379,
			'db': 1,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 10667,
		'log_topic': 'global',
	},

	# tc-shuma-11
	# 115.159.36.101(公)
	# 10.105.26.65(内)
	'game_qq73': {
		'redis': {
			'host': '0.0.0.0',
			'port': 10379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 10777,
		'log_topic': 'game_qq73',
	},
	'game_qq74': {
		'redis': {
			'host': '0.0.0.0',
			'port': 11379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 11777,
		'log_topic': 'game_qq74',
	},
	'game_qq75': {
		'redis': {
			'host': '0.0.0.0',
			'port': 12379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 12777,
		'log_topic': 'game_qq75',
	},
	'game_qq76': {
		'redis': {
			'host': '0.0.0.0',
			'port': 13379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 13777,
		'log_topic': 'game_qq76',
	},
	'game_qq77': {
		'redis': {
			'host': '0.0.0.0',
			'port': 14379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 14777,
		'log_topic': 'game_qq77',
	},
	'game_qq78': {
		'redis': {
			'host': '0.0.0.0',
			'port': 15379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 15777,
		'log_topic': 'game_qq78',
	},
	'game_qq79': {
		'redis': {
			'host': '0.0.0.0',
			'port': 16379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 16777,
		'log_topic': 'game_qq79',
	},
	'game_qq80': {
		'redis': {
			'host': '0.0.0.0',
			'port': 17379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 17777,
		'log_topic': 'game_qq80',
	},

	'cross_qq18': {
		'redis': {
			'host': '0.0.0.0',
			'port': 18379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 10666,
		'log_topic': 'global',
	},

	'cross_qq19': {
		'redis': {
			'host': '0.0.0.0',
			'port': 18379,
			'db': 1,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 10667,
		'log_topic': 'global',
	},

	# tc-shuma-12
	# 115.159.59.152(公)
	# 10.133.200.249(内)
	'game_qq81': {
		'redis': {
			'host': '0.0.0.0',
			'port': 10379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 10777,
		'log_topic': 'game_qq81',
	},
	'game_qq82': {
		'redis': {
			'host': '0.0.0.0',
			'port': 11379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 11777,
		'log_topic': 'game_qq82',
	},
	'game_qq83': {
		'redis': {
			'host': '0.0.0.0',
			'port': 12379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 12777,
		'log_topic': 'game_qq83',
	},
	'game_qq84': {
		'redis': {
			'host': '0.0.0.0',
			'port': 13379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 13777,
		'log_topic': 'game_qq84',
	},
	'game_qq85': {
		'redis': {
			'host': '0.0.0.0',
			'port': 14379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 14777,
		'log_topic': 'game_qq85',
	},
	'game_qq86': {
		'redis': {
			'host': '0.0.0.0',
			'port': 15379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 15777,
		'log_topic': 'game_qq86',
	},
	'game_qq87': {
		'redis': {
			'host': '0.0.0.0',
			'port': 16379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 16777,
		'log_topic': 'game_qq87',
	},
	'game_qq88': {
		'redis': {
			'host': '0.0.0.0',
			'port': 17379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 17777,
		'log_topic': 'game_qq88',
	},

	'cross_qq20': {
		'redis': {
			'host': '0.0.0.0',
			'port': 18379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 10666,
		'log_topic': 'global',
	},

	'cross_qq21': {
		'redis': {
			'host': '0.0.0.0',
			'port': 18379,
			'db': 1,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 10667,
		'log_topic': 'global',
	},

	# tc-shuma-13
	# 182.254.216.172(公)
	# 10.133.194.88(内)
	'game_qq89': {
		'redis': {
			'host': '0.0.0.0',
			'port': 10379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 10777,
		'log_topic': 'game_qq89',
	},
	'game_qq90': {
		'redis': {
			'host': '0.0.0.0',
			'port': 11379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 11777,
		'log_topic': 'game_qq90',
	},
	'game_qq91': {
		'redis': {
			'host': '0.0.0.0',
			'port': 12379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 12777,
		'log_topic': 'game_qq91',
	},
	'game_qq92': {
		'redis': {
			'host': '0.0.0.0',
			'port': 13379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 13777,
		'log_topic': 'game_qq92',
	},
	'game_qq93': {
		'redis': {
			'host': '0.0.0.0',
			'port': 14379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 14777,
		'log_topic': 'game_qq93',
	},
	'game_qq94': {
		'redis': {
			'host': '0.0.0.0',
			'port': 15379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 15777,
		'log_topic': 'game_qq94',
	},
	'game_qq95': {
		'redis': {
			'host': '0.0.0.0',
			'port': 16379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 16777,
		'log_topic': 'game_qq95',
	},
	'game_qq96': {
		'redis': {
			'host': '0.0.0.0',
			'port': 17379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 17777,
		'log_topic': 'game_qq96',
	},

	'cross_qq22': {
		'redis': {
			'host': '0.0.0.0',
			'port': 18379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 10666,
		'log_topic': 'global',
	},

	'cross_qq23': {
		'redis': {
			'host': '0.0.0.0',
			'port': 18379,
			'db': 1,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 10667,
		'log_topic': 'global',
	},

	# tc-shuma-14
	# 182.254.241.252(公)
	# 10.133.200.54(内)
	'game_qq97': {
		'redis': {
			'host': '0.0.0.0',
			'port': 10379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 10777,
		'log_topic': 'game_qq97',
	},
	'game_qq98': {
		'redis': {
			'host': '0.0.0.0',
			'port': 11379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 11777,
		'log_topic': 'game_qq98',
	},
	'game_qq99': {
		'redis': {
			'host': '0.0.0.0',
			'port': 12379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 12777,
		'log_topic': 'game_qq99',
	},
	'game_qq100': {
		'redis': {
			'host': '0.0.0.0',
			'port': 13379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 13777,
		'log_topic': 'game_qq100',
	},
	'game_qq101': {
		'redis': {
			'host': '0.0.0.0',
			'port': 14379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 14777,
		'log_topic': 'game_qq101',
	},
	'game_qq102': {
		'redis': {
			'host': '0.0.0.0',
			'port': 15379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 15777,
		'log_topic': 'game_qq102',
	},
	'game_qq103': {
		'redis': {
			'host': '0.0.0.0',
			'port': 16379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 16777,
		'log_topic': 'game_qq103',
	},
	'game_qq104': {
		'redis': {
			'host': '0.0.0.0',
			'port': 17379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 17777,
		'log_topic': 'game_qq104',
	},

	'cross_qq24': {
		'redis': {
			'host': '0.0.0.0',
			'port': 18379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 10666,
		'log_topic': 'global',
	},

	'cross_qq25': {
		'redis': {
			'host': '0.0.0.0',
			'port': 18379,
			'db': 1,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 10667,
		'log_topic': 'global',
	},

	# tc-shuma-15
	# 115.159.200.184(公)
	# 10.105.58.19(内)
	'game_qq105': {
		'redis': {
			'host': '0.0.0.0',
			'port': 10379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 10777,
		'log_topic': 'game_qq105',
	},
	'game_qq106': {
		'redis': {
			'host': '0.0.0.0',
			'port': 11379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 11777,
		'log_topic': 'game_qq106',
	},
	'game_qq107': {
		'redis': {
			'host': '0.0.0.0',
			'port': 12379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 12777,
		'log_topic': 'game_qq107',
	},
	'game_qq108': {
		'redis': {
			'host': '0.0.0.0',
			'port': 13379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 13777,
		'log_topic': 'game_qq108',
	},
	'game_qq109': {
		'redis': {
			'host': '0.0.0.0',
			'port': 14379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 14777,
		'log_topic': 'game_qq109',
	},
	'game_qq110': {
		'redis': {
			'host': '0.0.0.0',
			'port': 15379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 15777,
		'log_topic': 'game_qq110',
	},
	'game_qq111': {
		'redis': {
			'host': '0.0.0.0',
			'port': 16379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 16777,
		'log_topic': 'game_qq111',
	},
	'game_qq112': {
		'redis': {
			'host': '0.0.0.0',
			'port': 17379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 17777,
		'log_topic': 'game_qq112',
	},

	'cross_qq26': {
		'redis': {
			'host': '0.0.0.0',
			'port': 18379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 10666,
		'log_topic': 'global',
	},

	'cross_qq27': {
		'redis': {
			'host': '0.0.0.0',
			'port': 18379,
			'db': 1,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 10667,
		'log_topic': 'global',
	},

	# tc-shuma-16
	# 115.159.185.23(公)
	# 10.105.6.156(内)
	'game_qq113': {
		'redis': {
			'host': '0.0.0.0',
			'port': 10379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 10777,
		'log_topic': 'game_qq113',
	},
	'game_qq114': {
		'redis': {
			'host': '0.0.0.0',
			'port': 11379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 11777,
		'log_topic': 'game_qq114',
	},
	'game_qq115': {
		'redis': {
			'host': '0.0.0.0',
			'port': 12379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 12777,
		'log_topic': 'game_qq115',
	},
	'game_qq116': {
		'redis': {
			'host': '0.0.0.0',
			'port': 13379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 13777,
		'log_topic': 'game_qq116',
	},
	'game_qq117': {
		'redis': {
			'host': '0.0.0.0',
			'port': 14379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 14777,
		'log_topic': 'game_qq117',
	},
	'game_qq118': {
		'redis': {
			'host': '0.0.0.0',
			'port': 15379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 15777,
		'log_topic': 'game_qq118',
	},
	'game_qq119': {
		'redis': {
			'host': '0.0.0.0',
			'port': 16379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 16777,
		'log_topic': 'game_qq119',
	},
	'game_qq120': {
		'redis': {
			'host': '0.0.0.0',
			'port': 17379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 17777,
		'log_topic': 'game_qq120',
	},

	'cross_qq28': {
		'redis': {
			'host': '0.0.0.0',
			'port': 18379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 10666,
		'log_topic': 'global',
	},

	'cross_qq29': {
		'redis': {
			'host': '0.0.0.0',
			'port': 18379,
			'db': 1,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 10667,
		'log_topic': 'global',
	},

	# tc-shuma-17
	# 115.159.145.94(公)
	# 10.105.24.66(内)
	'game_qq121': {
		'redis': {
			'host': '0.0.0.0',
			'port': 10379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 10777,
		'log_topic': 'game_qq121',
	},
	'game_qq122': {
		'redis': {
			'host': '0.0.0.0',
			'port': 11379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 11777,
		'log_topic': 'game_qq122',
	},
	'game_qq123': {
		'redis': {
			'host': '0.0.0.0',
			'port': 12379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 12777,
		'log_topic': 'game_qq123',
	},
	'game_qq124': {
		'redis': {
			'host': '0.0.0.0',
			'port': 13379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 13777,
		'log_topic': 'game_qq124',
	},
	'game_qq125': {
		'redis': {
			'host': '0.0.0.0',
			'port': 14379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 14777,
		'log_topic': 'game_qq125',
	},
	'game_qq126': {
		'redis': {
			'host': '0.0.0.0',
			'port': 15379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 15777,
		'log_topic': 'game_qq126',
	},
	'game_qq127': {
		'redis': {
			'host': '0.0.0.0',
			'port': 16379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 16777,
		'log_topic': 'game_qq127',
	},
	'game_qq128': {
		'redis': {
			'host': '0.0.0.0',
			'port': 17379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 17777,
		'log_topic': 'game_qq128',
	},

	# tc-shuma-18
	# 115.159.62.109(公)
	# 10.105.125.78(内)
	'game_qq129': {
		'redis': {
			'host': '0.0.0.0',
			'port': 10379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 10777,
		'log_topic': 'game_qq129',
	},
	'game_qq130': {
		'redis': {
			'host': '0.0.0.0',
			'port': 11379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 11777,
		'log_topic': 'game_qq130',
	},
	'game_qq131': {
		'redis': {
			'host': '0.0.0.0',
			'port': 12379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 12777,
		'log_topic': 'game_qq131',
	},
	'game_qq132': {
		'redis': {
			'host': '0.0.0.0',
			'port': 13379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 13777,
		'log_topic': 'game_qq132',
	},
	'game_qq133': {
		'redis': {
			'host': '0.0.0.0',
			'port': 14379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 14777,
		'log_topic': 'game_qq133',
	},
	'game_qq134': {
		'redis': {
			'host': '0.0.0.0',
			'port': 15379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 15777,
		'log_topic': 'game_qq134',
	},
	'game_qq135': {
		'redis': {
			'host': '0.0.0.0',
			'port': 16379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 16777,
		'log_topic': 'game_qq135',
	},
	'game_qq136': {
		'redis': {
			'host': '0.0.0.0',
			'port': 17379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 17777,
		'log_topic': 'game_qq136',
	},

	# tc-shuma-19_1
	# 115.159.185.212(公)
	# 10.154.3.101(内)
	'game_qq137': {
		'redis': {
			'host': '0.0.0.0',
			'port': 10379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 10777,
		'log_topic': 'game_qq137',
	},
	'game_qq138': {
		'redis': {
			'host': '0.0.0.0',
			'port': 11379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 11777,
		'log_topic': 'game_qq138',
	},
	'game_qq139': {
		'redis': {
			'host': '0.0.0.0',
			'port': 12379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 12777,
		'log_topic': 'game_qq139',
	},
	'game_qq140': {
		'redis': {
			'host': '0.0.0.0',
			'port': 13379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 13777,
		'log_topic': 'game_qq140',
	},
	'game_qq141': {
		'redis': {
			'host': '0.0.0.0',
			'port': 14379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 14777,
		'log_topic': 'game_qq141',
	},
	'game_qq142': {
		'redis': {
			'host': '0.0.0.0',
			'port': 15379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 15777,
		'log_topic': 'game_qq142',
	},
	'game_qq143': {
		'redis': {
			'host': '0.0.0.0',
			'port': 16379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 16777,
		'log_topic': 'game_qq143',
	},
	'game_qq144': {
		'redis': {
			'host': '0.0.0.0',
			'port': 17379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 17777,
		'log_topic': 'game_qq144',
	},

	# tc-shuma-19_2
	# 115.159.204.87(公)
	# 10.154.15.165(内)
	'game_qq145': {
		'redis': {
			'host': '0.0.0.0',
			'port': 10379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 10777,
		'log_topic': 'game_qq145',
	},
	'game_qq146': {
		'redis': {
			'host': '0.0.0.0',
			'port': 11379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 11777,
		'log_topic': 'game_qq146',
	},
	'game_qq147': {
		'redis': {
			'host': '0.0.0.0',
			'port': 12379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 12777,
		'log_topic': 'game_qq147',
	},
	'game_qq148': {
		'redis': {
			'host': '0.0.0.0',
			'port': 13379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 13777,
		'log_topic': 'game_qq148',
	},
	'game_qq149': {
		'redis': {
			'host': '0.0.0.0',
			'port': 14379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 14777,
		'log_topic': 'game_qq149',
	},
	'game_qq150': {
		'redis': {
			'host': '0.0.0.0',
			'port': 15379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 15777,
		'log_topic': 'game_qq150',
	},
	'game_qq151': {
		'redis': {
			'host': '0.0.0.0',
			'port': 16379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 16777,
		'log_topic': 'game_qq151',
	},
	'game_qq152': {
		'redis': {
			'host': '0.0.0.0',
			'port': 17379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 17777,
		'log_topic': 'game_qq152',
	},

	# tc-shuma-19_3
	# 115.159.197.96(公)
	# 10.154.22.134(内)
	'game_qq153': {
		'redis': {
			'host': '0.0.0.0',
			'port': 10379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 10777,
		'log_topic': 'game_qq153',
	},
	'game_qq154': {
		'redis': {
			'host': '0.0.0.0',
			'port': 11379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 11777,
		'log_topic': 'game_qq154',
	},
	'game_qq155': {
		'redis': {
			'host': '0.0.0.0',
			'port': 12379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 12777,
		'log_topic': 'game_qq155',
	},
	'game_qq156': {
		'redis': {
			'host': '0.0.0.0',
			'port': 13379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 13777,
		'log_topic': 'game_qq156',
	},
	'game_qq157': {
		'redis': {
			'host': '0.0.0.0',
			'port': 14379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 14777,
		'log_topic': 'game_qq157',
	},
	'game_qq158': {
		'redis': {
			'host': '0.0.0.0',
			'port': 15379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 15777,
		'log_topic': 'game_qq158',
	},
	'game_qq159': {
		'redis': {
			'host': '0.0.0.0',
			'port': 16379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 16777,
		'log_topic': 'game_qq159',
	},
	'game_qq160': {
		'redis': {
			'host': '0.0.0.0',
			'port': 17379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 17777,
		'log_topic': 'game_qq160',
	},

	# tc-shuma-20
	# 115.159.197.143(公)
	# 10.105.114.112(内)
	'game_qq161': {
		'redis': {
			'host': '0.0.0.0',
			'port': 10379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 10777,
		'log_topic': 'game_qq161',
	},
	'game_qq162': {
		'redis': {
			'host': '0.0.0.0',
			'port': 11379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 11777,
		'log_topic': 'game_qq162',
	},
	'game_qq163': {
		'redis': {
			'host': '0.0.0.0',
			'port': 12379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 12777,
		'log_topic': 'game_qq163',
	},
	'game_qq164': {
		'redis': {
			'host': '0.0.0.0',
			'port': 13379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 13777,
		'log_topic': 'game_qq164',
	},
	'game_qq165': {
		'redis': {
			'host': '0.0.0.0',
			'port': 14379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 14777,
		'log_topic': 'game_qq165',
	},
	'game_qq166': {
		'redis': {
			'host': '0.0.0.0',
			'port': 15379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 15777,
		'log_topic': 'game_qq166',
	},
	'game_qq167': {
		'redis': {
			'host': '0.0.0.0',
			'port': 16379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 16777,
		'log_topic': 'game_qq167',
	},
	'game_qq168': {
		'redis': {
			'host': '0.0.0.0',
			'port': 17379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 17777,
		'log_topic': 'game_qq168',
	},

	# tc-shuma-21
	# 123.206.176.146(公)
	# 10.154.11.226(内)
	'game_qq169': {
		'redis': {
			'host': '0.0.0.0',
			'port': 10379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 10777,
		'log_topic': 'game_qq169',
	},
	'game_qq170': {
		'redis': {
			'host': '0.0.0.0',
			'port': 11379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 11777,
		'log_topic': 'game_qq170',
	},
	'game_qq171': {
		'redis': {
			'host': '0.0.0.0',
			'port': 12379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 12777,
		'log_topic': 'game_qq171',
	},
	'game_qq172': {
		'redis': {
			'host': '0.0.0.0',
			'port': 13379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 13777,
		'log_topic': 'game_qq172',
	},
	'game_qq173': {
		'redis': {
			'host': '0.0.0.0',
			'port': 14379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 14777,
		'log_topic': 'game_qq173',
	},
	'game_qq174': {
		'redis': {
			'host': '0.0.0.0',
			'port': 15379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 15777,
		'log_topic': 'game_qq174',
	},
	'game_qq175': {
		'redis': {
			'host': '0.0.0.0',
			'port': 16379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 16777,
		'log_topic': 'game_qq175',
	},
	'game_qq176': {
		'redis': {
			'host': '0.0.0.0',
			'port': 17379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 17777,
		'log_topic': 'game_qq176',
	},
	'game_qq177': {
		'redis': {
			'host': '0.0.0.0',
			'port': 18379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 18777,
		'log_topic': 'game_qq177',
	},
	'game_qq178': {
		'redis': {
			'host': '0.0.0.0',
			'port': 19379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 19777,
		'log_topic': 'game_qq178',
	},
	'game_qq179': {
		'redis': {
			'host': '0.0.0.0',
			'port': 20379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 20777,
		'log_topic': 'game_qq179',
	},
	'game_qq180': {
		'redis': {
			'host': '0.0.0.0',
			'port': 21379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 21777,
		'log_topic': 'game_qq180',
	},
	'game_qq181': {
		'redis': {
			'host': '0.0.0.0',
			'port': 22379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 22777,
		'log_topic': 'game_qq181',
	},
	'game_qq182': {
		'redis': {
			'host': '0.0.0.0',
			'port': 23379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 23777,
		'log_topic': 'game_qq182',
	},
	'game_qq183': {
		'redis': {
			'host': '0.0.0.0',
			'port': 24379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 24777,
		'log_topic': 'game_qq183',
	},
	'game_qq184': {
		'redis': {
			'host': '0.0.0.0',
			'port': 25379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 25777,
		'log_topic': 'game_qq184',
	},
	'game_qq185': {
		'redis': {
			'host': '0.0.0.0',
			'port': 26379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 26777,
		'log_topic': 'game_qq185',
	},
	'game_qq186': {
		'redis': {
			'host': '0.0.0.0',
			'port': 27379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 27777,
		'log_topic': 'game_qq186',
	},
	'game_qq187': {
		'redis': {
			'host': '0.0.0.0',
			'port': 28379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 28777,
		'log_topic': 'game_qq187',
	},
	'game_qq188': {
		'redis': {
			'host': '0.0.0.0',
			'port': 29379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 29777,
		'log_topic': 'game_qq188',
	},
	'game_qq189': {
		'redis': {
			'host': '0.0.0.0',
			'port': 30379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 30777,
		'log_topic': 'game_qq189',
	},
	'game_qq190': {
		'redis': {
			'host': '0.0.0.0',
			'port': 31379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 31777,
		'log_topic': 'game_qq190',
	},
	'game_qq191': {
		'redis': {
			'host': '0.0.0.0',
			'port': 32379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 32777,
		'log_topic': 'game_qq191',
	},
	'game_qq192': {
		'redis': {
			'host': '0.0.0.0',
			'port': 33379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 33777,
		'log_topic': 'game_qq192',
	},

	# tc-shuma-22
	# 182.254.212.221(外)
	# 10.105.44.132(内)
	'game_qq193': {
		'redis': {
			'host': '0.0.0.0',
			'port': 10379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 10777,
		'log_topic': 'game_qq193',
	},
	'game_qq194': {
		'redis': {
			'host': '0.0.0.0',
			'port': 11379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 11777,
		'log_topic': 'game_qq194',
	},
	'game_qq195': {
		'redis': {
			'host': '0.0.0.0',
			'port': 12379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 12777,
		'log_topic': 'game_qq195',
	},
	'game_qq196': {
		'redis': {
			'host': '0.0.0.0',
			'port': 13379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 13777,
		'log_topic': 'game_qq196',
	},
	'game_qq197': {
		'redis': {
			'host': '0.0.0.0',
			'port': 14379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 14777,
		'log_topic': 'game_qq197',
	},
	'game_qq198': {
		'redis': {
			'host': '0.0.0.0',
			'port': 15379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 15777,
		'log_topic': 'game_qq198',
	},
	'game_qq199': {
		'redis': {
			'host': '0.0.0.0',
			'port': 16379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 16777,
		'log_topic': 'game_qq199',
	},
	'game_qq200': {
		'redis': {
			'host': '0.0.0.0',
			'port': 17379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 17777,
		'log_topic': 'game_qq200',
	},

	# tc-shuma-23
	# 118.89.106.131(外)
	# 10.105.0.10(内)
	'game_qq201': {
		'redis': {
			'host': '0.0.0.0',
			'port': 10379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 10777,
		'log_topic': 'game_qq201',
	},
	'game_qq202': {
		'redis': {
			'host': '0.0.0.0',
			'port': 11379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 11777,
		'log_topic': 'game_qq202',
	},
	'game_qq203': {
		'redis': {
			'host': '0.0.0.0',
			'port': 12379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 12777,
		'log_topic': 'game_qq203',
	},
	'game_qq204': {
		'redis': {
			'host': '0.0.0.0',
			'port': 13379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 13777,
		'log_topic': 'game_qq204',
	},
	'game_qq205': {
		'redis': {
			'host': '0.0.0.0',
			'port': 14379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 14777,
		'log_topic': 'game_qq205',
	},
	'game_qq206': {
		'redis': {
			'host': '0.0.0.0',
			'port': 15379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 15777,
		'log_topic': 'game_qq206',
	},
	'game_qq207': {
		'redis': {
			'host': '0.0.0.0',
			'port': 16379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 16777,
		'log_topic': 'game_qq207',
	},
	'game_qq208': {
		'redis': {
			'host': '0.0.0.0',
			'port': 17379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 17777,
		'log_topic': 'game_qq208',
	},

	# tc-shuma-24
	# 118.89.105.93(外)
	# 10.105.49.147(内)
	'game_qq209': {
		'redis': {
			'host': '0.0.0.0',
			'port': 10379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 10777,
		'log_topic': 'game_qq209',
	},
	'game_qq210': {
		'redis': {
			'host': '0.0.0.0',
			'port': 11379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 11777,
		'log_topic': 'game_qq210',
	},
	'game_qq211': {
		'redis': {
			'host': '0.0.0.0',
			'port': 12379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 12777,
		'log_topic': 'game_qq211',
	},
	'game_qq212': {
		'redis': {
			'host': '0.0.0.0',
			'port': 13379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 13777,
		'log_topic': 'game_qq212',
	},
	'game_qq213': {
		'redis': {
			'host': '0.0.0.0',
			'port': 14379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 14777,
		'log_topic': 'game_qq213',
	},
	'game_qq214': {
		'redis': {
			'host': '0.0.0.0',
			'port': 15379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 15777,
		'log_topic': 'game_qq214',
	},
	'game_qq215': {
		'redis': {
			'host': '0.0.0.0',
			'port': 16379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 16777,
		'log_topic': 'game_qq215',
	},
	'game_qq216': {
		'redis': {
			'host': '0.0.0.0',
			'port': 17379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 17777,
		'log_topic': 'game_qq216',
	},

	# tc-shuma-25
	# 123.206.192.74(外)
	# 10.105.84.76(内)
	'game_qq217': {
		'redis': {
			'host': '0.0.0.0',
			'port': 10379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 10777,
		'log_topic': 'game_qq217',
	},
	'game_qq218': {
		'redis': {
			'host': '0.0.0.0',
			'port': 11379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 11777,
		'log_topic': 'game_qq218',
	},
	'game_qq219': {
		'redis': {
			'host': '0.0.0.0',
			'port': 12379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 12777,
		'log_topic': 'game_qq219',
	},
	'game_qq220': {
		'redis': {
			'host': '0.0.0.0',
			'port': 13379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 13777,
		'log_topic': 'game_qq220',
	},
	'game_qq221': {
		'redis': {
			'host': '0.0.0.0',
			'port': 14379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 14777,
		'log_topic': 'game_qq221',
	},
	'game_qq222': {
		'redis': {
			'host': '0.0.0.0',
			'port': 15379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 15777,
		'log_topic': 'game_qq222',
	},
	'game_qq223': {
		'redis': {
			'host': '0.0.0.0',
			'port': 16379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 16777,
		'log_topic': 'game_qq223',
	},
	'game_qq224': {
		'redis': {
			'host': '0.0.0.0',
			'port': 17379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 17777,
		'log_topic': 'game_qq224',
	},



	######################################
	# 繁体版本

	# tc-shuma-tw-login
	# 119.28.17.230
	'account_tw': {
		'redis': {
			'host': '0.0.0.0',
			'port': 10379,
			'db': 1,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 27777,
		'log_topic': 'global',
	},
	# gm 和 account 共用同一个db_server
	'gm_tw': {
		'redis': {
			'host': '0.0.0.0',
			'port': 10379,
			'db': 1,
			'password': 'redis123',
		},
		'host': '0.0.0.0',
		'port': 27777,
		'log_topic': 'global',
	},
	'payment_tw': {
		'redis': {
			'host': '0.0.0.0',
			'port': 10379,
			'db': 2,
			'password': 'redis123',
		},
		'host': '0.0.0.0',
		'port': 27778,
		'log_topic': 'global',
	},
	'gift_tw': {
		'redis': {
			'host': '0.0.0.0',
			'port': 10379,
			'db': 3,
			'password': 'redis123',
		},
		'host': '119.28.17.230',
		'port': 27779,
		'log_topic': 'global',
	},
	# 独立redis
	'gmweb_tw': {
		'redis': {
			'host': '0.0.0.0',
			'port': 11379,
			'db': 4,
			'password': 'redis123',
		},
	},

	# tc-shuma-tw-01
	# 119.28.61.236
	'game_tw01': {
		'redis': {
			'host': '0.0.0.0',
			'port': 10379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 10777,
		'log_topic': 'game_tw01',
	},

	# tc-shuma-tw-02
	# 119.28.62.238
	'game_tw02': {
		'redis': {
			'host': '0.0.0.0',
			'port': 10379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 10777,
		'log_topic': 'game_tw02',
	},

	# tc-shuma-tw-03
	# 119.28.66.108
	'game_tw03': {
		'redis': {
			'host': '0.0.0.0',
			'port': 10379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 10777,
		'log_topic': 'game_tw03',
	},

	# tc-shuma-tw-04
	# 119.28.68.19
	'game_tw04': {
		'redis': {
			'host': '0.0.0.0',
			'port': 10379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 10777,
		'log_topic': 'game_tw04',
	},

	# tc-shuma-tw-05
	# 119.28.67.201
	'game_tw05': {
		'redis': {
			'host': '0.0.0.0',
			'port': 10379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 10777,
		'log_topic': 'game_tw05',
	},

	# tc-shuma-tw-06
	# 119.28.62.228
	'game_tw06': {
		'redis': {
			'host': '0.0.0.0',
			'port': 10379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 10777,
		'log_topic': 'game_tw06',
	},

	# tc-shuma-tw-07
	# 119.28.62.228
	'game_tw07': {
		'redis': {
			'host': '0.0.0.0',
			'port': 10379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 10777,
		'log_topic': 'game_tw07',
	},

	# tc-shuma-tw-08
	# 119.28.65.196
	'game_tw08': {
		'redis': {
			'host': '0.0.0.0',
			'port': 10379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 10777,
		'log_topic': 'game_tw08',
	},

	# tc-shuma-tw-09
	# 119.28.68.176
	'game_tw09': {
		'redis': {
			'host': '0.0.0.0',
			'port': 10379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 10777,
		'log_topic': 'game_tw09',
	},

	# tc-shuma-tw-10
	# 119.28.66.236
	'game_tw10': {
		'redis': {
			'host': '0.0.0.0',
			'port': 10379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 10777,
		'log_topic': 'game_tw10',
	},

	# tc-shuma-tw-11
	# 119.28.17.78
	'game_tw11': {
		'redis': {
			'host': '0.0.0.0',
			'port': 10379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 10777,
		'log_topic': 'game_tw11',
	},

	# tc-shuma-tw-12
	# 119.28.69.62
	'game_tw12': {
		'redis': {
			'host': '0.0.0.0',
			'port': 10379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 10777,
		'log_topic': 'game_tw12',
	},

	# tc-shuma-tw-13
	# 119.28.62.213
	'game_tw13': {
		'redis': {
			'host': '0.0.0.0',
			'port': 10379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 10777,
		'log_topic': 'game_tw13',
	},


	'game_tw14': {
		'redis': {
			'host': '0.0.0.0',
			'port': 10379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 10777,
		'log_topic': 'game_tw14',
	},
	'game_tw15': {
		'redis': {
			'host': '0.0.0.0',
			'port': 10379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 10777,
		'log_topic': 'game_tw15',
	},
	'game_tw16': {
		'redis': {
			'host': '0.0.0.0',
			'port': 10379,
			'db': 0,
			'password': 'redis123',
		},
		'host': '127.0.0.1',
		'port': 10777,
		'log_topic': 'game_tw16',
	},
}

ClientDefs = {
	# 内部服务器
	'game_db': {'server': 'game'},
	'game_db_dev': {'server': 'game_dev'},
	'game_db_dev2': {'server': 'game_dev2'},
	'game_db_dev3': {'server': 'game_dev3'},
	'game_db_dev4': {'server': 'game_dev4'},
	'account_db': {'server': 'account'},
	'gm_db': {'server': 'gm'},
	'payment_db': {'server': 'payment'},
	'gift_db': {'server': 'gift'},
	'cross_db': {'server': 'cross'},
	'cross_db_dev': {'server': 'cross_dev'},

	# QQ登录支付服务器
	'account_db_qq': {'server': 'account_qq'},
	'gm_db_qq': {'server': 'gm_qq'},
	'payment_db_qq': {'server': 'payment_qq'},
	'gift_db_qq': {'server': 'gift_qq'},

	# TW登录支付服务器
	'account_db_tw': {'server': 'account_tw'},
	'gm_db_tw': {'server': 'gm_tw'},
	'payment_db_tw': {'server': 'payment_tw'},
	'gift_db_tw': {'server': 'gift_tw'},

	# QQ跨服服务器
	'cross_db_qq01': {'server': 'cross_qq01'},
	'cross_db_qq02': {'server': 'cross_qq02'},
	'cross_db_qq03': {'server': 'cross_qq03'},
	'cross_db_qq04': {'server': 'cross_qq04'},
	'cross_db_qq05': {'server': 'cross_qq05'},
	'cross_db_qq06': {'server': 'cross_qq06'},
	'cross_db_qq07': {'server': 'cross_qq07'},
	'cross_db_qq08': {'server': 'cross_qq08'},
	'cross_db_qq09': {'server': 'cross_qq09'},
	'cross_db_qq10': {'server': 'cross_qq10'},
	'cross_db_qq11': {'server': 'cross_qq11'},
	'cross_db_qq12': {'server': 'cross_qq12'},
	'cross_db_qq13': {'server': 'cross_qq13'},
	'cross_db_qq14': {'server': 'cross_qq14'},
	'cross_db_qq15': {'server': 'cross_qq15'},
	'cross_db_qq16': {'server': 'cross_qq16'},
	'cross_db_qq17': {'server': 'cross_qq17'},
	'cross_db_qq18': {'server': 'cross_qq18'},
	'cross_db_qq19': {'server': 'cross_qq19'},
	'cross_db_qq20': {'server': 'cross_qq20'},
	'cross_db_qq21': {'server': 'cross_qq21'},
	'cross_db_qq22': {'server': 'cross_qq22'},
	'cross_db_qq23': {'server': 'cross_qq23'},
	'cross_db_qq24': {'server': 'cross_qq24'},
	'cross_db_qq25': {'server': 'cross_qq25'},
	'cross_db_qq26': {'server': 'cross_qq26'},
	'cross_db_qq27': {'server': 'cross_qq27'},
	'cross_db_qq28': {'server': 'cross_qq28'},
	'cross_db_qq29': {'server': 'cross_qq29'},
	'cross_db_qq30': {'server': 'cross_qq30'},

	# QQ游戏服务器
	'game_db_qq01': {'server': 'game_qq01'},
	'game_db_qq02': {'server': 'game_qq02'},
	'game_db_qq03': {'server': 'game_qq03'},
	'game_db_qq04': {'server': 'game_qq04'},
	'game_db_qq05': {'server': 'game_qq05'},
	'game_db_qq06': {'server': 'game_qq06'},
	'game_db_qq07': {'server': 'game_qq07'},
	'game_db_qq08': {'server': 'game_qq08'},

	'game_db_qq09': {'server': 'game_qq09'},
	'game_db_qq10': {'server': 'game_qq10'},
	'game_db_qq11': {'server': 'game_qq11'},
	'game_db_qq12': {'server': 'game_qq12'},
	'game_db_qq13': {'server': 'game_qq13'},
	'game_db_qq14': {'server': 'game_qq14'},
	'game_db_qq15': {'server': 'game_qq15'},
	'game_db_qq16': {'server': 'game_qq16'},

	'game_db_qq17': {'server': 'game_qq17'},
	'game_db_qq18': {'server': 'game_qq18'},
	'game_db_qq19': {'server': 'game_qq19'},
	'game_db_qq20': {'server': 'game_qq20'},
	'game_db_qq21': {'server': 'game_qq21'},
	'game_db_qq22': {'server': 'game_qq22'},
	'game_db_qq23': {'server': 'game_qq23'},
	'game_db_qq24': {'server': 'game_qq24'},

	'game_db_qq25': {'server': 'game_qq25'},
	'game_db_qq26': {'server': 'game_qq26'},
	'game_db_qq27': {'server': 'game_qq27'},
	'game_db_qq28': {'server': 'game_qq28'},
	'game_db_qq29': {'server': 'game_qq29'},
	'game_db_qq30': {'server': 'game_qq30'},
	'game_db_qq31': {'server': 'game_qq31'},
	'game_db_qq32': {'server': 'game_qq32'},

	'game_db_qq33': {'server': 'game_qq33'},
	'game_db_qq34': {'server': 'game_qq34'},
	'game_db_qq35': {'server': 'game_qq35'},
	'game_db_qq36': {'server': 'game_qq36'},
	'game_db_qq37': {'server': 'game_qq37'},
	'game_db_qq38': {'server': 'game_qq38'},
	'game_db_qq39': {'server': 'game_qq39'},
	'game_db_qq40': {'server': 'game_qq40'},

	'game_db_qq41': {'server': 'game_qq41'},
	'game_db_qq42': {'server': 'game_qq42'},
	'game_db_qq43': {'server': 'game_qq43'},
	'game_db_qq44': {'server': 'game_qq44'},
	'game_db_qq45': {'server': 'game_qq45'},
	'game_db_qq46': {'server': 'game_qq46'},
	'game_db_qq47': {'server': 'game_qq47'},
	'game_db_qq48': {'server': 'game_qq48'},

	'game_db_qq49': {'server': 'game_qq49'},
	'game_db_qq50': {'server': 'game_qq50'},
	'game_db_qq51': {'server': 'game_qq51'},
	'game_db_qq52': {'server': 'game_qq52'},
	'game_db_qq53': {'server': 'game_qq53'},
	'game_db_qq54': {'server': 'game_qq54'},
	'game_db_qq55': {'server': 'game_qq55'},
	'game_db_qq56': {'server': 'game_qq56'},

	'game_db_qq57': {'server': 'game_qq57'},
	'game_db_qq58': {'server': 'game_qq58'},
	'game_db_qq59': {'server': 'game_qq59'},
	'game_db_qq60': {'server': 'game_qq60'},
	'game_db_qq61': {'server': 'game_qq61'},
	'game_db_qq62': {'server': 'game_qq62'},
	'game_db_qq63': {'server': 'game_qq63'},
	'game_db_qq64': {'server': 'game_qq64'},

	'game_db_qq65': {'server': 'game_qq65'},
	'game_db_qq66': {'server': 'game_qq66'},
	'game_db_qq67': {'server': 'game_qq67'},
	'game_db_qq68': {'server': 'game_qq68'},
	'game_db_qq69': {'server': 'game_qq69'},
	'game_db_qq70': {'server': 'game_qq70'},
	'game_db_qq71': {'server': 'game_qq71'},
	'game_db_qq72': {'server': 'game_qq72'},

	'game_db_qq73': {'server': 'game_qq73'},
	'game_db_qq74': {'server': 'game_qq74'},
	'game_db_qq75': {'server': 'game_qq75'},
	'game_db_qq76': {'server': 'game_qq76'},
	'game_db_qq77': {'server': 'game_qq77'},
	'game_db_qq78': {'server': 'game_qq78'},
	'game_db_qq79': {'server': 'game_qq79'},
	'game_db_qq80': {'server': 'game_qq80'},

	'game_db_qq81': {'server': 'game_qq81'},
	'game_db_qq82': {'server': 'game_qq82'},
	'game_db_qq83': {'server': 'game_qq83'},
	'game_db_qq84': {'server': 'game_qq84'},
	'game_db_qq85': {'server': 'game_qq85'},
	'game_db_qq86': {'server': 'game_qq86'},
	'game_db_qq87': {'server': 'game_qq87'},
	'game_db_qq88': {'server': 'game_qq88'},

	'game_db_qq89': {'server': 'game_qq89'},
	'game_db_qq90': {'server': 'game_qq90'},
	'game_db_qq91': {'server': 'game_qq91'},
	'game_db_qq92': {'server': 'game_qq92'},
	'game_db_qq93': {'server': 'game_qq93'},
	'game_db_qq94': {'server': 'game_qq94'},
	'game_db_qq95': {'server': 'game_qq95'},
	'game_db_qq96': {'server': 'game_qq96'},

	'game_db_qq97': {'server': 'game_qq97'},
	'game_db_qq98': {'server': 'game_qq98'},
	'game_db_qq99': {'server': 'game_qq99'},
	'game_db_qq100': {'server': 'game_qq100'},
	'game_db_qq101': {'server': 'game_qq101'},
	'game_db_qq102': {'server': 'game_qq102'},
	'game_db_qq103': {'server': 'game_qq103'},
	'game_db_qq104': {'server': 'game_qq104'},

	'game_db_qq105': {'server': 'game_qq105'},
	'game_db_qq106': {'server': 'game_qq106'},
	'game_db_qq107': {'server': 'game_qq107'},
	'game_db_qq108': {'server': 'game_qq108'},
	'game_db_qq109': {'server': 'game_qq109'},
	'game_db_qq110': {'server': 'game_qq110'},
	'game_db_qq111': {'server': 'game_qq111'},
	'game_db_qq112': {'server': 'game_qq112'},

	'game_db_qq113': {'server': 'game_qq113'},
	'game_db_qq114': {'server': 'game_qq114'},
	'game_db_qq115': {'server': 'game_qq115'},
	'game_db_qq116': {'server': 'game_qq116'},
	'game_db_qq117': {'server': 'game_qq117'},
	'game_db_qq118': {'server': 'game_qq118'},
	'game_db_qq119': {'server': 'game_qq119'},
	'game_db_qq120': {'server': 'game_qq120'},

	'game_db_qq121': {'server': 'game_qq121'},
	'game_db_qq122': {'server': 'game_qq122'},
	'game_db_qq123': {'server': 'game_qq123'},
	'game_db_qq124': {'server': 'game_qq124'},
	'game_db_qq125': {'server': 'game_qq125'},
	'game_db_qq126': {'server': 'game_qq126'},
	'game_db_qq127': {'server': 'game_qq127'},
	'game_db_qq128': {'server': 'game_qq128'},

	'game_db_qq129': {'server': 'game_qq129'},
	'game_db_qq130': {'server': 'game_qq130'},
	'game_db_qq131': {'server': 'game_qq131'},
	'game_db_qq132': {'server': 'game_qq132'},
	'game_db_qq133': {'server': 'game_qq133'},
	'game_db_qq134': {'server': 'game_qq134'},
	'game_db_qq135': {'server': 'game_qq135'},
	'game_db_qq136': {'server': 'game_qq136'},

	'game_db_qq137': {'server': 'game_qq137'},
	'game_db_qq138': {'server': 'game_qq138'},
	'game_db_qq139': {'server': 'game_qq139'},
	'game_db_qq140': {'server': 'game_qq140'},
	'game_db_qq141': {'server': 'game_qq141'},
	'game_db_qq142': {'server': 'game_qq142'},
	'game_db_qq143': {'server': 'game_qq143'},
	'game_db_qq144': {'server': 'game_qq144'},

	'game_db_qq145': {'server': 'game_qq145'},
	'game_db_qq146': {'server': 'game_qq146'},
	'game_db_qq147': {'server': 'game_qq147'},
	'game_db_qq148': {'server': 'game_qq148'},
	'game_db_qq149': {'server': 'game_qq149'},
	'game_db_qq150': {'server': 'game_qq150'},
	'game_db_qq151': {'server': 'game_qq151'},
	'game_db_qq152': {'server': 'game_qq152'},

	'game_db_qq153': {'server': 'game_qq153'},
	'game_db_qq154': {'server': 'game_qq154'},
	'game_db_qq155': {'server': 'game_qq155'},
	'game_db_qq156': {'server': 'game_qq156'},
	'game_db_qq157': {'server': 'game_qq157'},
	'game_db_qq158': {'server': 'game_qq158'},
	'game_db_qq159': {'server': 'game_qq159'},
	'game_db_qq160': {'server': 'game_qq160'},

	'game_db_qq161': {'server': 'game_qq161'},
	'game_db_qq162': {'server': 'game_qq162'},
	'game_db_qq163': {'server': 'game_qq163'},
	'game_db_qq164': {'server': 'game_qq164'},
	'game_db_qq165': {'server': 'game_qq165'},
	'game_db_qq166': {'server': 'game_qq166'},
	'game_db_qq167': {'server': 'game_qq167'},
	'game_db_qq168': {'server': 'game_qq168'},

	'game_db_qq169': {'server': 'game_qq169'},
	'game_db_qq170': {'server': 'game_qq170'},
	'game_db_qq171': {'server': 'game_qq171'},
	'game_db_qq172': {'server': 'game_qq172'},
	'game_db_qq173': {'server': 'game_qq173'},
	'game_db_qq174': {'server': 'game_qq174'},
	'game_db_qq175': {'server': 'game_qq175'},
	'game_db_qq176': {'server': 'game_qq176'},
	'game_db_qq177': {'server': 'game_qq177'},
	'game_db_qq178': {'server': 'game_qq178'},
	'game_db_qq179': {'server': 'game_qq179'},
	'game_db_qq180': {'server': 'game_qq180'},
	'game_db_qq181': {'server': 'game_qq181'},
	'game_db_qq182': {'server': 'game_qq182'},
	'game_db_qq183': {'server': 'game_qq183'},
	'game_db_qq184': {'server': 'game_qq184'},
	'game_db_qq185': {'server': 'game_qq185'},
	'game_db_qq186': {'server': 'game_qq186'},
	'game_db_qq187': {'server': 'game_qq187'},
	'game_db_qq188': {'server': 'game_qq188'},
	'game_db_qq189': {'server': 'game_qq189'},
	'game_db_qq190': {'server': 'game_qq190'},
	'game_db_qq191': {'server': 'game_qq191'},
	'game_db_qq192': {'server': 'game_qq192'},

	'game_db_qq193': {'server': 'game_qq193'},
	'game_db_qq194': {'server': 'game_qq194'},
	'game_db_qq195': {'server': 'game_qq195'},
	'game_db_qq196': {'server': 'game_qq196'},
	'game_db_qq197': {'server': 'game_qq197'},
	'game_db_qq198': {'server': 'game_qq198'},
	'game_db_qq199': {'server': 'game_qq199'},
	'game_db_qq200': {'server': 'game_qq200'},

	'game_db_qq201': {'server': 'game_qq201'},
	'game_db_qq202': {'server': 'game_qq202'},
	'game_db_qq203': {'server': 'game_qq203'},
	'game_db_qq204': {'server': 'game_qq204'},
	'game_db_qq205': {'server': 'game_qq205'},
	'game_db_qq206': {'server': 'game_qq206'},
	'game_db_qq207': {'server': 'game_qq207'},
	'game_db_qq208': {'server': 'game_qq208'},

	'game_db_qq209': {'server': 'game_qq209'},
	'game_db_qq210': {'server': 'game_qq210'},
	'game_db_qq211': {'server': 'game_qq211'},
	'game_db_qq212': {'server': 'game_qq212'},
	'game_db_qq213': {'server': 'game_qq213'},
	'game_db_qq214': {'server': 'game_qq214'},
	'game_db_qq215': {'server': 'game_qq215'},
	'game_db_qq216': {'server': 'game_qq216'},

	'game_db_qq217': {'server': 'game_qq217'},
	'game_db_qq218': {'server': 'game_qq218'},
	'game_db_qq219': {'server': 'game_qq219'},
	'game_db_qq220': {'server': 'game_qq220'},
	'game_db_qq221': {'server': 'game_qq221'},
	'game_db_qq222': {'server': 'game_qq222'},
	'game_db_qq223': {'server': 'game_qq223'},
	'game_db_qq224': {'server': 'game_qq224'},

	######################################
	# 繁体版本
	'game_db_tw01': {'server': 'game_tw01'},
	'game_db_tw02': {'server': 'game_tw02'},
	'game_db_tw03': {'server': 'game_tw03'},
	'game_db_tw04': {'server': 'game_tw04'},
	'game_db_tw05': {'server': 'game_tw05'},
	'game_db_tw06': {'server': 'game_tw06'},
	'game_db_tw07': {'server': 'game_tw07'},
	'game_db_tw08': {'server': 'game_tw08'},
	'game_db_tw09': {'server': 'game_tw09'},
	'game_db_tw10': {'server': 'game_tw10'},
	'game_db_tw11': {'server': 'game_tw11'},
	'game_db_tw12': {'server': 'game_tw12'},
	'game_db_tw13': {'server': 'game_tw13'},
	'game_db_tw14': {'server': 'game_tw14'},
	'game_db_tw15': {'server': 'game_tw15'},
	'game_db_tw16': {'server': 'game_tw16'},
}
