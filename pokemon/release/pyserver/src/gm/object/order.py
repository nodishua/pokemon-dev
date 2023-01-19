#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2017 TianJi Information Technology Inc.
'''
from __future__ import absolute_import

from framework import *

from gm.object.db import *
from gm.util import *


# uniqueget_argument
# order_id PayOrder.id int 1
##########
# account_id Account.id int 123
# server_key
# role_id Role.id int 123
# time 创建时间 float 12345.12
# recharge_id
# channel 渠道 str uc
# channel_order_id PayOrder.order_id str xxx_123

# DBOrder


class DBOrder(DBRecord):
	Collection = 'Order'
	Indexes = [
		{"index": "order_id", "unique": True},
		{"index": "account_id"},
		{"index": "server_key"},
		{"index": "time"},
		{"index": "channel"},
		{"index": "channel_order_id", "unique": True},
	]

	@property
	def uniqueKey(self):
		return (self.order_id,)

	@staticmethod
	def uniqueKeyFromQuery(d):
		return (d['order_id'],)

	@staticmethod
	def defaultDocument():
		return {
			'order_id': '',
			'account_id': '',
			'server_key': 'game.dev',
			'role_id': '',
			'time': 0.0,
			'recharge_id': 0,
			'channel': 'none',
			'sub_channel': 'none',
			'channel_order_id': '',

			# 'result': '',
			# 'amount': '',
			# 'recharge_flag': '',
			# 'bad_flag',
		}

	def set(self, order, channel, sub_channel):
		self.account_id = order.account_id
		self.server_key = order.server_key
		self.role_id = order.role_id
		self.time = order.time
		self.recharge_id = order.recharge_id
		self.channel = channel
		self.sub_channel = sub_channel
		self.channel_order_id = order.order_id
