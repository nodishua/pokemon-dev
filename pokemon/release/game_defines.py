#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2014 YouMi Information Technology Inc.

game server config defines
'''

from datetime import datetime

from nsq_defines import *

ServerDefs = {
	'game.dev.1': {
		'ip': '192.168.1.233',
		'port': 28879,
		'debug': True,
		'nsq': NSQDefs,
		'open_date': datetime(2021, 10, 17, 10),
		'dependent': [
		],
	},
	
	'game.dev.2': {
		'ip': '192.168.1.233',
		'port': 28878,
		'debug': True,
		'nsq': NSQDefs,
		'open_date': datetime(2021, 10, 17, 10),
		'dependent': [
		],
	},
	
	'game.cn_qd.1233': {
		'ip': '175.24.118.119',
		'port': 25888,
		'nsq': CNNSQDefs,
		'open_date': datetime(2022, 3, 28, 16),
		'dependent': [
			'anticheat',
			'chat_monitor',
			"giftdb.cn.1",
		],
	},

}


if __name__ == "__main__":
	import json
	servers = []
	for key in sorted(ServerDefs.keys()):
		cfg = ServerDefs[key]
		servers.append({
			'key': key,
			'addr': '%s:%d' % (cfg['ip'], cfg['port']),
			'open_date': cfg['open_date'].strftime('%Y-%m-%d %H:%M:%S'),
		})
	with open('./login/conf/game.json', 'w') as fp:
		json.dump(servers, fp, sort_keys=True, indent=2)
