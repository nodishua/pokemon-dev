#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2017 TianJi Information Technology Inc.
'''
from __future__ import absolute_import

import copy
import datetime
from collections import defaultdict

import framework
from framework import *
from framework.log import logger

from gm.object.db import *
from gm.util import *


# unique
# date date 20170213
# Channel channel Str TC
# Sub_Channel Sub -channel Str YS
#AREA District Service INT 1
###########
# Created new account list [account_id]
# LOGIN login account list [account_id]
# Pay paid account DICT {account_id: {payorder.id: payorder.model}}}
# Pay_orders list [{},]


# DBArchive
class DBArchive(DBRecord):
	Collection = 'Archive'
	Indexes = [
		{
			"index": [
				("date", 1),
				("channel", 1),
				("sub_channel", 1),
				("language", 1),
				("area", 1), # Account is not partition
			],
			"name": "ArchiveIndex",
			"unique": True,
		},
		{"index": "channel"},
		{"index": "sub_channel"},
		{"index": "language"},
		{"index": "area"},
	]

	def __init__(self, db):
		self._sumDirty = True
		DBRecord.__init__(self, db)

	@property
	def uniqueKey(self):
		return (self.date, str(self.channel), str(self.sub_channel), str(self.language), self.area)

	@staticmethod
	def uniqueKeyFromQuery(d):
		return (d['date'], str(d['channel']), str(d['sub_channel']), str(d['language']), d['area'])

	def fromDB(self, db):
		self._db['create'] = set(db['create'])
		self._db['login'] = set(db['login'])
		self._db['first_pay'] = set(db['first_pay'])
		self.initSum()

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
			'date': todaydate2int(),
			'channel': 'none',
			'sub_channel': 'none',
			'language': framework.__language__,
			'area': 0,  # Unproofed data, the default is 0

			'create': [],
			'create_time': {},# {datehour: [objectid,],}
			'login': [],
			'login_time': {},# {datehour: [objectid,],}
			'pay_orders': {},# {accountID: {orderID: {slimOrder}}}
			'pay_time': {},# {datehour: [objectid,],}
			'first_pay': [],
		}

	def initSum(self):
		if not self._sumDirty:
			return
		self._sumDirty = False

		try:
			self._sum = AttrsDict({
				'create': len(self.create),
				'login': len(self.login),
				'pay_amount': sum([sumRecharges(d, self.language) for d in self.pay_orders.itervalues()]), # Clenging currency is calculated local calculated
				'pay_count': len(self.pay_orders),
				'first_pay_count': len(self.first_pay)
			})
		except:
			logger.exception("initSum Error")
			self._sum = AttrsDict({
				'create': 0,
				'login': 0,
				'pay_amount': 0, # Clenging currency is calculated local calculated
				'pay_count': 0,
				'first_pay_count': 0
			})

	@property
	def sum(self):
		self.initSum()
		return self._sum

	# output
	@property
	def ARPU(self):
		return 1.0 * self.sum.get('pay_amount', 0) / max(1, self.sum.get('login', 1))

	@property
	def ARPPU(self):
		return 1.0 * self.sum.get('pay_amount', 0) / max(1, self.sum.get('pay_count', 1))

	@property
	def payRate(self):
		return 100.0 * self.sum.get('pay_count', 0) / max(1, self.sum.get('login', 1))

	@property
	def payCountByCreated(self):
		c = 0
		for _id in self.create:
			s = objectid2str(_id)
			if s in self.pay_orders:
				c += 1
		return c

	@property
	def payAmountByCreated(self):
		return sum([sumRecharges(d, self.language) for accountID, d in self.pay_orders.iteritems() if str2objectid(accountID) in self.create])

	@property
	def payRateByCreated(self):
		return 100.0 * self.payCountByCreated / max(1, self.sum.get('create', 1))

	# Calculate
	def retentionRateWith(self, future):
		retention = len(self.create & future.login)
		return retention, 100.0 * retention / max(1, self.sum.get('create', 1))

	# Calculate the number of people within a few days
	def lostNumber(self, futureList):
		login = self.sum.get('login')

		if int2date(self.date) + len(futureList)*OneDay > datetime.datetime.now().date():
			return '-'
		elif not futureList or futureList[-1] is None:
			return 0
		else:
			s = set([])
			for future in futureList:
				s |= future.login
			s &= self.login
			return login - len(s)

	@property
	def statistics(self):
		return {
			'create': self.sum.get('create', 0),
			'login': self.sum.get('login', 0),
			'pay_count': self.sum.get('pay_count', 0),
			'pay_amount': self.sum.get('pay_amount', 0),
			'ARPU': round(self.ARPU, 2),
			'ARPPU': round(self.ARPPU, 2),
			'payRate': '%.2f%%' % round(self.payRate, 2),
			'payCountByCreated': self.payCountByCreated,
			'payAmountByCreated': self.payAmountByCreated,
			'payRateByCreated': '%.2f%%' % round(self.payRateByCreated, 2),
			'firstPayAccount': self.sum.get('first_pay_count', 0),
		}

	def addAccountLogin(self, account):
		self.login.add(account._id)

		lastTime = datetime2int(datetime.datetime.fromtimestamp(account.last_time))
		tempList = self.login_time.setdefault(str(lastTime), [])
		tempList.append(account._id)
		seen = set()
		seen_add = seen.add
		self.login_time[str(lastTime)] = [x for x in tempList if not (x in seen or seen_add(x))]

		self._sumDirty = True

	def addAccountCreated(self, account):
		# self.addAccountLogin(account)
		self.create.add(account._id)

		create_time = datetime2int(datetime.datetime.fromtimestamp(account.create_time))
		tempList = self.create_time.setdefault(str(create_time), [])
		tempList.append(account._id)
		seen = set()
		seen_add = seen.add
		self.create_time[str(create_time)] = [x for x in tempList if not (x in seen or seen_add(x))]

		self._sumDirty = True

	def addAccountAreaLogin(self, _id, login_time):
		self.login.add(_id)

		t = datetime2int(datetime.datetime.fromtimestamp(login_time))
		tempList = self.login_time.setdefault(str(t), [])
		tempList.append(_id)
		seen = set()
		seen_add = seen.add
		self.login_time[str(t)] = [x for x in tempList if not (x in seen or seen_add(x))]
		self._sumDirty = True

	def addAccountAreaCreated(self, _id, create_time):
		self.addAccountAreaLogin(_id, create_time)

		self.create.add(_id)
		t = datetime2int(datetime.datetime.fromtimestamp(create_time))
		tempList = self.create_time.setdefault(str(t), [])
		tempList.append(_id)
		seen = set()
		seen_add = seen.add
		self.create_time[str(t)] = [x for x in tempList if not (x in seen or seen_add(x))]
		self._sumDirty = True

	def addOrder(self, order):
		accountID = objectid2str(order.account_id)
		orderID = objectid2str(order._id)

		if accountID not in self.pay_orders:
			self.pay_orders[accountID] = {}
		d = self.pay_orders[accountID]
		if orderID not in d:
			d[orderID] = slimOrder(order)
			self._sumDirty = True

		t = datetime2int(datetime.datetime.fromtimestamp(order.time))
		tempList = self.pay_time.setdefault(str(t), [])
		tempList.append(order._id)
		seen = set()
		seen_add = seen.add
		self.pay_time[str(t)] = [x for x in tempList if not (x in seen or seen_add(x))]
		self._sumDirty = True

	def addAccountFirstPay(self, account):
		if account.first_pay_time > 0:
			dateInt = date2int(datetime.datetime.fromtimestamp(account.first_pay_time).date())
			if dateInt == self.date:
				self.first_pay.add(account.account_id)

	def reAddOrder(self, order):
		mapObj = KeyMapObject(order, {
			'_id': 'order_id',
		})
		self.addOrder(mapObj)


# DBDailyArchive
class DBDailyArchive(DBArchive):
	Collection = 'DailyArchive'
	Indexes = [
		{"index": "date", "unique": True},
		{"index": "language"}
	]

	@property
	def uniqueKey(self):
		return (self.date,)

	@staticmethod
	def uniqueKeyFromQuery(d):
		return (d['date'],)

	def fromDB(self, db):
		self._db['channels'] = set(db['channels'])
		self._db['sub_channels'] = set(db['sub_channels'])
		self._db['areas'] = set(db['areas'])
		self._db['create'] = set(db['create'])
		self._db['login'] = set(db['login'])
		self._db['first_pay'] = set(db['first_pay'])

	@staticmethod
	def defaultDocument(date=todaydate2int()):
		return {
			'date': date,
			'language': framework.__language__,
			'channels': [],
			'sub_channels': [],
			'areas': [],

			'create': [],
			'create_time': {},
			'login': [],
			'login_time': {},
			'pay_orders': {},
			'pay_time': {},
			'first_pay': [],
		}

	def _merge(self, other):
		self.create |= other.create
		self.login |= other.login
		self.first_pay |= other.first_pay

		# merge pay_orders
		d = self.pay_orders
		for accountID, dd in other.pay_orders.iteritems():
			if accountID not in d:
				d[accountID] = {}
			d[accountID].update(dd)
		self._sumDirty = True

		def _combine(d, s):
			for k, v in s.iteritems():
				if k not in d:
					d[k] = list(v)
				else:
					d[k] = list(set(v) | set(d[k]))
		# merge create_time
		_combine(self.create_time, other.create_time)
		# merge login_time
		_combine(self.login_time, other.login_time)
		# merge pay_time
		_combine(self.pay_time, other.pay_time)

	def addRecord(self, other):
		# other is DBArchive dict
		if isinstance(other, dict):
			other = AttrsDict(other)

		if self.date != other.date:
			logger.warning("date missmatch %d %d", self.date, other.date)
			return

		# Now only the local area is displayed
		if self.language != other.language:
			logger.warning("language missmatch %s %s", self.language, other.language)
			return

		# merge record
		self.channels.add(other.channel)
		self.sub_channels.add(other.sub_channel)
		self.areas.add(other.area)
		self._merge(other)

	def addDailyRecord(self, other):
		# other is DBDailyArchive dict
		if isinstance(other, dict):
			other = AttrsDict(other)

		# merge record
		self.channels |= other.channels
		self.sub_channels |= other.sub_channels
		self.areas |= other.areas
		self._merge(other)
