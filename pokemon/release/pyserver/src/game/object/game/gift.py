#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2014 YouMi Information Technology Inc.
'''

from __future__ import absolute_import

from framework import todaydate2int, inclock5date, datetimefromtimestamp, int2date
from framework.csv import csv, ErrDefs
from framework.service.rpc_client import Client

from game import ServerError, ClientError
from game.object.game.gain import ObjectGainEffect as ObjectGiftEffect


#
# ObjectGift
#

class ObjectGift(object):
	def __init__(self, game, dbc):
		self.game = game

	def set(self, dic):
		self._db = dic
		return self

	def init(self):
		return self

	# 礼包码
	def key():
		def fget(self):
			return self._db['key']
		return locals()
	key = property(**key())

	# 礼包CSV ID
	def csv_id():
		def fget(self):
			return self._db['csv_id']
		return locals()
	csv_id = property(**csv_id())

	def getEffect(self):
		cfg = csv.gift[self.csv_id]
		role = self.game.role
		num = role.gifts.get(cfg.id, 0)
		numType = role.gifts.get(-cfg.type, 0)

		if todaydate2int() >= cfg.endDate:
			raise ClientError(ErrDefs.giftOutOfDate)

		if num >= cfg.numMax:
			raise ClientError(ErrDefs.giftSameMax)
		if numType >= cfg.typeMax:
			raise ClientError(ErrDefs.giftSameTypeMax)

		date = inclock5date(datetimefromtimestamp(self.game.role.created_time))
		if date < int2date(cfg.validRoleCreatedDateRange[0]) or date >int2date(cfg.validRoleCreatedDateRange[1]):
			raise ClientError(ErrDefs.giftOutOfCreatedDate)

		def _afterGain():
			if cfg.id not in role.gifts:
				role.gifts[cfg.id] = 1
			else:
				role.gifts[cfg.id] += 1
			if -cfg.type not in role.gifts:
				role.gifts[-cfg.type] = 1
			else:
				role.gifts[-cfg.type] += 1
		return ObjectGiftEffect(self.game, cfg.award, _afterGain)

