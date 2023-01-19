#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2014 YouMi Information Technology Inc.

Account Server Database Scheme
'''

import db.redisorm as rom
from framework import nowtime_t


class Account(rom.Model):
	'''
	玩家信息
	'''
	id = rom.PrimaryKey()
	name = rom.String(required=True, unique=True) # 用户绑定的注册名，渠道账号ID
	tc_uid = rom.String(default='', index=True) # 天赐SDK UID，迁移用
	channel = rom.String(default='none', index=True) # 用户来源渠道
	language = rom.String(default='cn', index=True) # 用户来源语言
	pass_md5 = rom.String(required=True) # 用户密码
	created_time = rom.Float(default=nowtime_t) # 注册时间
	last_time = rom.Float(default=nowtime_t, index=True) # 上次操作时间
	role_infos = rom.Msgpack(default=dict) # 账号信息 {ServKey: {id: Role.id, name: Role.name, level: Role.level, logo: Role.logo, vip: Role.vip_level}}


class GMAccount(rom.Model):
	'''
	GM信息
	'''
	id = rom.PrimaryKey()
	name = rom.String(required=True, unique=True) # GM的注册名
	pass_md5 = rom.String(required=True) # 密码MD5
	created_time = rom.Float(default=nowtime_t) # 注册时间
	last_time = rom.Float(default=nowtime_t) # 上次登陆时间
	permission_level = rom.Integer(default=0) # 权限级别
	operated_history = rom.Msgpack(default=list) # 操作记录 [(rpc, param, time), ...]
