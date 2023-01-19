# -*- coding: utf-8 -*-

ServerDefs = {
	"crash_ios_koudai": {
		'ip': '0.0.0.0',
		'port': 1106,
		'processes': 1,
		'debug': True,
		'tag': 'koudai',
		'mongodb': {
			'host': '127.0.0.1',
			'port': 27030,
			'db_name': 'crash_platform_koudai',
			'username': None,
			'password': None,
		},
	},

	"crash_platform": {
		'ip': '0.0.0.0',
		'port': 1104,
		'processes': 1, # 启动几个tornado进程,0表示有几个核起几个进程
		'debug': False,
		'tag': 'shuma', # 数码和口袋显示有些地方的显示不一样,'koudai',开关
		'db': {
			'host': '127.0.0.1',
			'port': 27018,
			'db_name': 'crash_platform',
			'username': None,
			'password': None,
		},
	},

	"test": {
		'ip': '0.0.0.0',
		'port': 1104,
		'tag': 'koudai',
		'debug': False,
		'mongodb': {
			'host': '127.0.0.1',
			'port': 27018,
			'dbname': 'crash_platform',
			'username': None,
			'password': None,
		},
	},

	"crash_platform_qq": {
		'ip': '0.0.0.0',
		'port': 1104,
		'tag': 'koudai',
		'mongodb': {
			'host': '127.0.0.1',
			'port': 27018,
			'dbname': 'crash_platform',
			'username': None,
			'password': None,
	},
},
}