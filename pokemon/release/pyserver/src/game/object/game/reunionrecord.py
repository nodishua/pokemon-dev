#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2014 YouMi Information Technology Inc.
'''

from __future__ import absolute_import

from framework.csv import csv, ConstDefs
from framework.object import ObjectDBase, db_property
from framework.log import logger

from game.object import ReunionDefs

#
# ObjectReunionRecord
#

class ObjectReunionRecord(ObjectDBase):
	'''
	ReunionRecord
	'''
	DBModel = 'ReunionRecord'

	BindingRoles = set() # 绑定过程中的回归玩家id，模拟锁

	# 回归玩家db id
	role_db_id = db_property('role_db_id')

	# 重聚活动csvID
	yyID = db_property('yyID')

	# 绑定对象
	bind_role_db_id = db_property('bind_role_db_id')

	# 绑定历史
	bind_history = db_property('bind_history')

	# 绑定积分
	bind_point = db_property('bind_point')

	# 全目标记录
	targets = db_property('targets')

	# 最后上线日期
	last_date = db_property('last_date')

	# 累计登录天数
	login_days = db_property('login_days')

	# 协作任务领取状态
	stamps = db_property('stamps')

	# 任务计数
	valsums = db_property('valsums')

	# 任务额外信息
	valinfo = db_property('valinfo')

	# 结束时间
	end_time = db_property('end_time')

	def initReunionRecord(self, yyID, endTime):
		self.yyID = yyID
		self.end_time = endTime
		self.bind_role_db_id = None
		self.bind_point = 0
		self.targets = {}
		self.last_date = 0
		self.login_days = 0
		self.valsums = {}
		self.valinfo = {}
		self.stamps = {}

	def countBindCD(self):
		# 绑定任务全部完成
		if self.targets['cur'] == self.targets['all']:
			return ConstDefs.longBindCD
		# 回归玩家累计登录天数限制
		if self.login_days >= ConstDefs.reunionLoginDays:
			return ConstDefs.longBindCD
		return ConstDefs.shortBindCD

	@property
	def reunionModel(self):
		model = {
			'role_db_id': self.role_db_id,
			'bind_role_db_id': self.bind_role_db_id,
			'bind_point': self.bind_point,
			'bind_history': self.bind_history,
			'stamps': self.stamps,
			'valsums': self.valsums,
			'yyID': self.yyID,
			'end_time': self.end_time,
		}
		return model

	@classmethod
	def onLogin(cls, game, reunion):
		from game.object.game.yyhuodong import ObjectYYReunion
		if game.role.isReunionRoleOpen:
			ObjectYYReunion.refreshRoleReunion(game, reunion)
		else:
			endTime = game.role.reunion.get('info', {}).get('end_time', 0)
			roleType = game.role.reunion.get('role_type', None)
			game.role.reunion['role_type'] = 0
			if roleType == ReunionDefs.SeniorRole:
				game.role.sendReunionClosedNoticeMail(reunion, endTime)

	@classmethod
	def beginBinding(cls, roleID):
		# 绑定回归玩家是需要原子操作，这里模拟锁的方式
		if roleID in cls.BindingRoles:
			return False
		cls.BindingRoles.add(roleID)
		return True

	@classmethod
	def endBinding(cls, roleID):
		cls.BindingRoles.discard(roleID)
