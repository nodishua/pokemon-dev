#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2014 YouMi Information Technology Inc.

server config defines
'''

from nsq_defines import *

PayNotifyHost = 'http://123.207.108.22:28081'

ServerDefs = {
	################
	'payment': {
		'key': 'payment.dev.1',
		'port': 28081,
		'nsq': NSQDefs,
		'game_key_prefix' : ['game.dev.'],
		'dependent': [
			'paymentdb.dev.1',
			'giftdb.dev.1',
		],
	},
}

