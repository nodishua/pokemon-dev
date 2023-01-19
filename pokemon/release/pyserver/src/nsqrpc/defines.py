#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2014 YouMi Information Technology Inc.
Copyright (c) 2016 TianJi Information Technology Inc.

nsq default config defines
'''

NSQLookups = [
	'http://192.168.1.222:4161',
]

MainNSQ = [
	'192.168.1.222:4150',
]

ReaderNSQDefs = {
	# 'lookupd_http_addresses': NSQLookups,
	# 'max_in_flight': 10,
	'nsqd_tcp_addresses': MainNSQ,
}

WriterNSQDefs = {
	'nsqd_tcp_addresses': MainNSQ,
}
