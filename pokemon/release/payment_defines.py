#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2014 YouMi Information Technology Inc.

server config defines
'''

from nsq_defines import *

PayNotifyHost = 'http://192.168.1.233:28081'

ServerDefs = {
	################
	'payment.dev.1': {
		'key': 'payment.dev.1',
		'port': 28082,
		'nsq': NSQDefs,
		'game_key_prefix' : ['game.cn.', "game.cn_qd.", "game.cn_ly1."],
		'dependent': [
			'paymentdb.dev.1',
			'giftdb.dev.1',
			'game.shenhe.1',
			'game.dev.1',
		],
	},

	'payment.cn.1': {
		'key': 'payment.cn.1',
		'port': 28081,
		'nsq': CNNSQDefs,
		'game_key_prefix' : ['game.cn.', "game.cn_qd.", "game.cn_ly1."],
		'dependent': [
			'paymentdb.cn.1',
			'giftdb.cn.1',
			'game.shenhe.1',
		],
	},
}

