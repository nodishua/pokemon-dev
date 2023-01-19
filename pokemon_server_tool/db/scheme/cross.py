#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2014 YouMi Information Technology Inc.

Cross Server Database Scheme
'''

import db.redisorm as rom
from framework import nowtime_t, nowtime2int


class CrossGlobal(rom.Model):
	'''
	跨服信息
	'''
	id = rom.PrimaryKey()
	services = rom.Msgpack(default=dict) # 玩法状态 {service: str or list}
	service_configs = rom.Msgpack(default=dict) # 玩法状态 {service: service.csv ID}


class CrossCraftServiceGlobal(rom.Model):
	'''
	拳皇争霸全局数据
	'''
	id = rom.PrimaryKey()
	servers = rom.Msgpack(default=list) # 参与的server [node key list]
	csv_id = rom.Integer(default=0) # service.csv的CSV ID
	date = rom.Integer(default=0) # 开始日期
	time = rom.Float(default=nowtime_t) # round切换时间
	round = rom.String(default='closed') # 轮次
	signup = rom.Msgpack(default=dict) # 报名角色信息 {(node key, Role.id): RoleSignItem}
	craft_roles = rom.Msgpack(default=dict) # 最新轮次信息 {(node key, Role.id): CraftRoleInfo}
	last_craft_roles = rom.Msgpack(default=dict) # 保护重启后恢复craft_roles
	bet2 = rom.Msgpack(default=dict) # 第2天比赛日区服的前64名战力玩家下注 {(node key, Role.id): {info: ObjectRankGlobal.BaseRoleInfos, rank: 战力排名, rate: 赔率, gold: {(node key, Role.id): gold}}}
	top8_plays = rom.Msgpack(default=dict) # 8强战斗记录 {(teamkey, playkey): {role1: CraftRoleInfo, role2: CraftRoleInfo, result: CraftResultInfo, cards1:[cards], cards2:[cards]}} key参见Top8PlayKeyMap
	round_results = rom.Msgpack(default=dict) # 战局总记录 {pre1: {min(Role1.id, Role2.id): CraftResultInfo)}}
	play_id = rom.Integer(default=1) # 战报id，为了重启后不冲突
