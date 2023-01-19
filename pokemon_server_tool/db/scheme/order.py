#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2014 YouMi Information Technology Inc.

Payment Server Database Scheme
'''

import db.redisorm as rom
from framework import nowtime_t


class PayOrder(rom.Model):
	'''
	支付信息
	'''
	id = rom.PrimaryKey()
	account_id = rom.Integer(required=True, index=True) # Account.id
	server_key = rom.String(required=True, index=True) # game server defines
	role_id = rom.Integer(required=True, index=True) # Role.id
	time = rom.Float(default=nowtime_t, index=True) # 支付回调时间
	channel = rom.String(required=True, index=True) # 用户来源渠道
	result = rom.String(required=True, index=True) # 支付结果 ok, err
	sdkmsg = rom.String(default='') # 支付记录回调数据
	order_id = rom.String(required=True, unique=True) # 支付唯一订单号
	recharge_id = rom.Integer(required=True, index=True) # recharges.csv ID
	amount = rom.Float(required=True, index=True) # 充值金额
	recharge_flag = rom.Boolean(default=False, index=True) # 是否已经充值到游戏账户
	bad_flag = rom.Boolean(default=False, index=True) # 是否是坏账，可能cdata数据有问题，可能支付失败
