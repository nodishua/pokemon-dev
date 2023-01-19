#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2014 YouMi Information Technology Inc.

Game Server Database Task
'''

from __future__ import absolute_import

import db.redisorm as orm
import db.scheme.game as DBSG
from db.task import RPCTaskFactory
from framework.log import logger
from framework.helper import randomName

import os
import time
import binascii


class TRoleFactory(RPCTaskFactory):
	def roleAdd(self, data):
		ret = {'ret': False}
		try:
			role = None
			for i in xrange(4):
				try:
					# 新注册玩家随机取名
					if 'name' not in data:
						data['name'] = randomName()
					if i >= 3:
						data['name'] += binascii.hexlify(os.urandom(1))

					role = DBSG.Role(**data)
					role.save()
					break
				except orm.UniqueKeyViolation, e:
					orm.session.forget(role)
					if str(e).find('Role:name') > 0:
						continue
					raise
				except:
					raise

			ret = {'ret': True, 'model': role.to_dict()}

		except orm.ORMError, e:
			logger.exception('roleAdd Exception')
			orm.session.forget(role)
			ret = {'ret': False, 'err': str(e), 'err_type': type(e).__name__}

		return ret

	def roleGet(self, data):
		# logger.info('roleGet data %s', data)
		ret = {'ret': False}
		try:
			roleL = DBSG.Role.get_by(account_id=data['account_id'])
			role = None
			if 'area' in data:
				for r in roleL:
					# logger.info('account %d role %d area %d name %s', r.account_id, r.id, r.area, r.name)
					if r.area == data['area']:
						role = r
						break
			else:
				if len(roleL) == 1:
					role = roleL[0]

				elif len(roleL) == 0:
					# 数据迁移
					conn = orm.util.get_connection()
					if conn:
						roleID = conn.hget('Role:account_id:__uidx', data['account_id'])
						if roleID:
							role = DBSG.Role.get(int(roleID))

			if role:
				role.last_time = time.time()
				role.save()

				ret = {'ret': True, 'model': role.to_dict()}

		except orm.ORMError, e:
			logger.exception('roleGet Exception')
			orm.session.forget(role)
			ret = {'ret': False, 'err': str(e), 'err_type': type(e).__name__}

		return ret

	def roleGetRobots(self, roleIDs):
		from game.globaldata import RobotIDStart

		ret = {'ret': False}
		try:
			objs = DBSG.Role.get(roleIDs)
			robotRoles = []
			try:
				for role in objs:
					if role.account_id >= RobotIDStart:
						robotRoles.append(role.to_dict())
			except orm.ORMError, e:
				logger.exception('roleGetRobots Exception')

			ret = {'ret': True, 'models': robotRoles}

		except orm.ORMError, e:
			logger.exception('roleGetRobots Exception')
			ret = {'ret': False, 'err': str(e), 'err_type': type(e).__name__}

		return ret