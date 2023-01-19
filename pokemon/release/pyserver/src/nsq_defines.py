#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2014 YouMi Information Technology Inc.
Copyright (c) 2016 TianJi Information Technology Inc.

nsq default config defines
'''


NSQDefs = {
	'reader': {
		'max_in_flight': 10,
		'nsqd_tcp_addresses': ['192.168.1.125:4150', '192.168.1.125:4140'],
		'output_buffer_size': 16 * 1024, # default 16kb
		'output_buffer_timeout': 25, # default 250ms
	},
	'writer': {
		'reconnect_interval': 5.0,
		'nsqd_tcp_addresses': ['192.168.1.125:4150', '192.168.1.125:4140'],
	},
}

CNNSQDefs = {
	'reader': {
		'nsqd_tcp_addresses': '172.16.2.14:4150',
		'output_buffer_size': 16 * 1024, # default 16kb
		'output_buffer_timeout': 25, # default 250ms
	},
	'writer': {
		'nsqd_tcp_addresses': '172.16.2.14:4150',
	},
}
