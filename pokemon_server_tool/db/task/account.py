#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2014 YouMi Information Technology Inc.

Account Server Database Task
'''

import db.redisorm as orm
import db.scheme.account as DBSA
from db.task import RPCTaskFactory

from framework.log import logger

import time

class TAccountFactory(RPCTaskFactory):
	def accountAdd(self, data):
		account = None
		ret = {'ret': False}
		try:
			account = DBSA.Account(**data)
			account.save()
			ret = {'ret': True, 'model': account.to_dict()}

		except orm.ORMError, e:
			orm.session.forget(account)
			ret = {'ret': False, 'err': str(e), 'err_type': type(e).__name__}

		return ret

	def accountLogin(self, name, pass_md5):
		account = None
		ret = {'ret': False}
		try:
			account = DBSA.Account.get_by(name=name)
			if account:
				account.last_time = time.time()
				if account.pass_md5 == pass_md5:
					ret = {'ret': True, 'model': account.to_dict()}

		except orm.ORMError, e:
			ret = {'ret': False, 'err': str(e), 'err_type': type(e).__name__}

		finally:
			if account:
				account.save()
				# enter game server之后再forget
				# orm.session.forget(account)

		return ret

	def accountRoleCheckin(self, account_id, serv_key, info):
		account = None
		try:
			account = DBSA.Account.get(account_id)
			if account:
				account.last_time = time.time()
				if serv_key in account.role_infos:
					if info:
						account.role_infos[serv_key] = info
				else:
					account.role_infos[serv_key] = info

		finally:
			if account:
				account.save()
				orm.session.forget(account)

	def accountQuery(self, account_id):
		account = None
		ret = {'ret': False}
		try:
			account = DBSA.Account.get(account_id)
			if account:
				ret = {'ret': True, 'model': account.to_dict()}

		except orm.ORMError, e:
			ret = {'ret': False, 'err': str(e), 'err_type': type(e).__name__}

		finally:
			if account:
				orm.session.forget(account)

		return ret

	def accountQueryByName(self, name):
		account = None
		ret = {'ret': False}
		try:
			account = DBSA.Account.get_by(name=name)
			if account:
				ret = {'ret': True, 'model': account.to_dict()}

		except orm.ORMError, e:
			ret = {'ret': False, 'err': str(e), 'err_type': type(e).__name__}

		finally:
			if account:
				orm.session.forget(account)

		return ret

	def gmAdd(self, data):
		account = None
		ret = {'ret': False}
		try:
			account = DBSA.GMAccount.get_by(name=data['name'])
			if account:
				return {'ret': False, 'err': 'existed_name'}

			account = DBSA.GMAccount(**data)
			account.save()
			ret = {'ret': True, 'model': account.to_dict()}

		except orm.ORMError, e:
			orm.session.forget(account)
			ret = {'ret': False, 'err': str(e), 'err_type': type(e).__name__}

		return ret

	def gmLogin(self, name, pass_md5):
		account = None
		ret = {'ret': False}
		try:
			account = DBSA.GMAccount.get_by(name=name)
			if account:
				account.last_time = time.time()
				account.save()

				if account.pass_md5 == pass_md5:
					ret = {'ret': True, 'model': account.to_dict()}
				else:
					return {'ret': False, 'err': 'pass_error'}
			else:
				return {'ret': False, 'err': 'no_account'}

		except orm.ORMError, e:
			orm.session.forget(account)
			ret = {'ret': False, 'err': str(e), 'err_type': type(e).__name__}

		return ret

	def gmOpHistory(self, name, opT):
		account = None
		ret = {'ret': False}
		try:
			account = DBSA.GMAccount.get_by(name=name)
			if account:
				account.last_time = time.time()
				account.operated_history.append(opT)
				if len(account.operated_history) > 1000:
					account.operated_history = account.operated_history[-1000:]
				account.save()

				ret = {'ret': True}
			else:
				return {'ret': False, 'err': 'no_account'}

		except orm.ORMError, e:
			orm.session.forget(account)
			ret = {'ret': False, 'err': str(e), 'err_type': type(e).__name__}

		return ret

