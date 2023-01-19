#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2014 YouMi Information Technology Inc.

Account Server Database Task
'''

import db.redisorm as orm
import db.scheme.gift as DBSG
from db.task import RPCTaskFactory

import os
import time
import binascii


class TGiftFactory(RPCTaskFactory):
	def giftGen(self, giftID, size, opts):
		ret = []
		while size > 0:
			key = binascii.hexlify(os.urandom(8))
			gift = None
			try:
				gift = DBSG.Gift(key=key, csv_id=giftID, opt_server_keys=opts)
				gift.save()
				ret.append(key)

			except:
				size += 1

			finally:
				size -= 1
				if gift:
					orm.session.forget(gift)
		return ret

	def giftExisted(self, key, serverKey, accountID):
		gift = None
		ret = {'ret': False}
		try:
			gift = DBSG.Gift.get_by(key=key)
			if gift:
				if gift.account_db_id != 0:
					if gift.account_db_id == accountID:
						ret = {'ret': False, 'err': 'gift_used'}
					else:
						ret = {'ret': False, 'err': 'gift_other_used'}
				else:
					if gift.opt_server_keys and serverKey not in gift.opt_server_keys:
						ret = {'ret': False, 'err': 'gift_cannot_use'}
					else:
						ret = {'ret': True, 'model': gift.to_dict()}
			else:
				ret = {'ret': False, 'err': 'no_gift'}

		except orm.ORMError, e:
			ret = {'ret': False, 'err': str(e), 'err_type': type(e).__name__}

		finally:
			if gift:
				orm.session.forget(gift)

		return ret

	def giftUse(self, key, serverKey, accountID):
		gift = None
		ret = {'ret': False}
		try:
			gift = DBSG.Gift.get_by(key=key)
			if gift:
				if gift.account_db_id != 0:
					if gift.account_db_id == accountID:
						ret = {'ret': False, 'err': 'gift_used'}
					else:
						ret = {'ret': False, 'err': 'gift_other_used'}
				else:
					if gift.opt_server_keys and serverKey not in gift.opt_server_keys:
						ret = {'ret': False, 'err': 'gift_cannot_use'}
					else:
						gift.use_time = time.time()
						gift.account_db_id = accountID
						gift.use_server_key = serverKey
						ret = {'ret': True}
			else:
				ret = {'ret': False, 'err': 'no_gift'}

		except orm.ORMError, e:
			ret = {'ret': False, 'err': str(e), 'err_type': type(e).__name__}

		finally:
			if gift:
				gift.save()
				orm.session.forget(gift)

		return ret
