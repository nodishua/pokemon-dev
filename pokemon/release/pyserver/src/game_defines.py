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
		'ip': '0.0.0.0',
		'port': 28879,
		'debug': True,
		'nsq': NSQDefs,
		'open_date': datetime(2016, 9, 17, 10),
		'dependent': [
			'chat_monitor',
			"giftdb.dev.1",
		],
	},
	'game.dev.2': {
		'ip': '0.0.0.0',
		'port': 28878,
		'debug': True,
		'nsq': NSQDefs,
		'open_date': datetime(2020, 3, 23, 10),
		'dependent': [
			'anticheat',
			'chat_monitor',
			"giftdb.dev.1",
			"card_comment.dev.6",
			"card_score.dev.6",
		],
	},
	'game.dev.3': {
		'ip': '0.0.0.0',
		'port': 28877,
		'debug': True,
		'nsq': NSQDefs,
		'open_date': datetime(2016, 9, 17, 10),
		'dependent': [
			'chat_monitor',
			"giftdb.dev.1",
		],
	},
	'game.dev.4': {
		'ip': '0.0.0.0',
		'port': 28876,
		'debug': True,
		'nsq': NSQDefs,
		'open_date': datetime(2020, 9, 17, 10),
		'dependent': [
			'chat_monitor',
			"giftdb.dev.1",
			"card_comment.dev.6",
			"card_score.dev.6",
		],
	},
	'game.dev.5': {
		'ip': '0.0.0.0',
		'port': 28875,
		'debug': True,
		'nsq': NSQDefs,
		'open_date': datetime(2016, 9, 17, 10),
		'dependent': [
			'chat_monitor',
			"giftdb.dev.1",
		],
	},
	'game.dev.6': {
		'ip': '0.0.0.0',
		'port': 28874,
		'debug': True,
		'nsq': NSQDefs,
		'open_date': datetime(2016, 9, 17, 10),
		'dependent': [
			'chat_monitor',
			"giftdb.dev.1",
		],
	},
	'game.dev.7': {
		'ip': '0.0.0.0',
		'port': 28873,
		'debug': True,
		'nsq': NSQDefs,
		'open_date': datetime(2020, 3, 23, 10),
		'dependent': [
		],
	},
	'game.dev.8': {
		'ip': '0.0.0.0',
		'port': 28872,
		'debug': True,
		'nsq': NSQDefs,
		'open_date': datetime(2020, 3, 1, 10),
		'dependent': [
		],
	},
	'game.dev.9': {
		'ip': '0.0.0.0',
		'port': 28871,
		'debug': True,
		'shushu': True,
		'nsq': NSQDefs,
		'open_date': datetime(2020, 3, 1, 10),
		'dependent': [
			'anticheat',
			'chat_monitor',
			"giftdb.dev.1",
			"card_comment.dev.6",
			"card_score.dev.6",
		],
	},
	'game.dev.10': {
		'ip': '0.0.0.0',
		'port': 28872,
		'debug': True,
		'nsq': NSQDefs,
		'open_date': datetime(2020, 3, 1, 10),
		'dependent': [
		],
	},
	'game.dev.11': {
		'ip': '0.0.0.0',
		'port': 28872,
		'debug': True,
		'nsq': NSQDefs,
		'open_date': datetime(2020, 3, 1, 10),
		'dependent': [
		],
	},
	'game.dev.12': {
		'ip': '0.0.0.0',
		'port': 28878,
		'debug': True,
		'nsq': NSQDefs,
		'open_date': datetime(2020, 3, 23, 10),
		'dependent': [
			'anticheat',
			'chat_monitor',
			"giftdb.dev.1",
			"card_comment.dev.6",
			"card_score.dev.6",
		],
	},
	'game.dev.13': {
		'ip': '0.0.0.0',
		'port': 28879,
		'debug': True,
		'nsq': NSQDefs,
		'open_date': datetime(2020, 3, 23, 10),
		'dependent': [
			'anticheat',
			'chat_monitor',
			"giftdb.dev.1",
			"card_comment.dev.6",
			"card_score.dev.6",
		],
	},

	'gamemerge.dev.1': {
		'ip': '0.0.0.0',
		'port': 28878,
		'debug': True,
		'shushu': True,
		'nsq': NSQDefs,
		'open_date': datetime(2020, 3, 23, 10),
		'merged': True,
		'alias': ['game.dev.2', 'game.dev.6'],
		'dependent': [
			'anticheat',
			'chat_monitor',
			"giftdb.dev.1",
			"card_comment.dev.6",
			"card_score.dev.6",
		],
	},

	'gamemerge.cn.1': {
		'ip': '0.0.0.0',
		'port': 10888,
		'debug': True,
		'nsq': NSQDefs,
		'open_date': datetime(2019, 12, 4, 10),
		'merged': True,
		'alias': ['game.cn.1', 'game.cn.2', 'game.cn.3', 'game.cn.4', 'game.cn.5'],
		'dependent': [
			'anticheat',
			'chat_monitor',
			"giftdb.dev.1",
			"card_comment.dev.6",
			"card_score.dev.6",
		],
	},
}

if __name__ == "__main__":
	import json
	servers = []
	for key in sorted(ServerDefs.keys()):
		cfg = ServerDefs[key]
		if 'alias' in cfg:
			for k in cfg['alias']:
				servers.append({
					'key': k,
					'addr': '%s:%d' % (cfg['ip'], cfg['port']),
					'open_date': cfg['open_date'].strftime('%Y-%m-%d %H:%M:%S'),
				})
		else:
			servers.append({
				'key': key,
				'addr': '%s:%d' % (cfg['ip'], cfg['port']),
				'open_date': cfg['open_date'].strftime('%Y-%m-%d %H:%M:%S'),
			})
	s = json.dumps(servers, sort_keys=True, indent=2)
	print s
