#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2014 YouMi Information Technology Inc.

Payment Server Database Scheme
'''

import db.redisorm as rom


class Gift(rom.Model):
	'''
	礼包
	'''
	id = rom.PrimaryKey()
	key = rom.String(required=True, unique=True) # 礼包码
	csv_id = rom.Integer(required=True, index=True) # 礼包CSV ID
	opt_server_keys = rom.Msgpack(default=list) # 可领取的区服，为空表示全服使用
	use_server_key = rom.String(default='') # 领取的区服
	use_time = rom.Float(default=0) # 领取时间
	account_db_id = rom.Integer(default=0, index=True) # 领取者Account.id