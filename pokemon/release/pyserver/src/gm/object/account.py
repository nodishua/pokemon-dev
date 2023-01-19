#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2017 TianJi Information Technology Inc.
'''
from __future__ import absolute_import

from framework import *
from framework.log import logger

from gm.object.db import *
from gm.util import *


# unique
# account_id Account.id int 1
##########
# name account.name str QQ_xxxxx
# Channel channel Str TC
# Sub_Channel Sub -channel Str YS
# Create_time Create time float 12345.12
# LOGIN_AREAS Login District Server [Area]
# Pay_ORDERS Paid Account List [Order,]
# Pay_amount Total Inte 123
# fIRST_PAY_TIME for the first paid time float 123123.123

# DBAccount

class DBAccount(DBRecord):
	Collection = 'Account'
	Indexes = [
		{"index": "account_id", "unique": True},
		{"index": "name"},
		{"index": "channel"},
		{"index": "sub_channel"},
		{"index": "create_time"},
		{"index": "first_pay_time"},
	]

	@property
	def uniqueKey(self):
		return (self.account_id,)

	@staticmethod
	def uniqueKeyFromQuery(d):
		return (d['account_id'],)

	def fromDB(self, db):
		self._db['login_areas'] = set(db['login_areas'])

	def toDB(self):
		ret = {}
		ret.update(self._db)

		for k, v in ret.iteritems():
			if isinstance(v, set):
				v = list(v)
			ret[k] = v
		return ret

	@staticmethod
	def defaultDocument():
		return {
			'account_id': 0,
			'name': 'none',
			'channel': 'none',
			'sub_channel': 'none',
			'create_time': 0.0,
			'login_areas': [],
			'pay_orders': {},
			'pay_amount': 0,
			'first_pay_time': -1.0,
			'last_time': 0.0,
		}

	def set(self, account, channel, subChannel):
		self.name = account.name
		self.create_time = account.create_time
		self.last_time = account.last_time
		self.channel = channel
		self.sub_channel = subChannel

	def addLogin(self, area):
		self.login_areas.add(area)

	def addOrder(self, order):
		orderID = objectid2str(order._id)

		# if self.channel == "none":
		# 	return

		if self.first_pay_time > 0:
			self.first_pay_time = min(order.time, self.first_pay_time)
		else:
			self.first_pay_time = order.time

		if orderID not in self.pay_orders:
			self.pay_orders[orderID] = slimOrder(order)
			self.pay_amount = sumRecharges(self.pay_orders, getServerLanguageByChannel(self.channel, self.sub_channel))
			self.login_areas.add(getServerArea(order.server_key))

		if self.first_pay_time > 0:
			return self.first_pay_time
		return None

	def reAddOrder(self, order):
		mapObj = KeyMapObject(order, {
			'_id': 'order_id',
		})
		self.addOrder(mapObj)