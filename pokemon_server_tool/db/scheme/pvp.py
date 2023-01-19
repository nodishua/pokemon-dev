#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2014 YouMi Information Technology Inc.

PVP Server Database Scheme
'''

# 注意！！！default={}，default=[]是错误的，对象会被引用
# 包括函数所生成的对象
# 除非常量，其余一定要使用函数重新生成 default=dict，default=list
# redisorm\columns.py 207

import db.redisorm as rom
from framework import nowtime_t, todaydate2int

class PVPRecord(rom.Model):
	'''
	pvp竞技场记录
	'''
	id = rom.PrimaryKey()
	role_db_id = rom.Integer(required=True, unique=True) # Role.id
	role_name = rom.String(default='') # Role.name
	role_logo = rom.Integer(default=1) # Role.logo
	role_level = rom.Integer(default=1) # Role.level
	pw_rank = rom.Integer(required=True, index=True) # 排位赛排名
	pw_history = rom.Msgpack(default=list) # 排位赛战斗历史（最多10条） [{t:时间, r:结果, brid:PVPPlayRecord.id, rkmov:排名差, pname:对手名字, pid:对手Role.id, prid:对手PVPRecord.id, plogo:对手头像, pfight:对手战斗力, plevel:对手等级, pfightgo:对手先手值}, ...]
	pw_rank_top = rom.Integer(required=True) # 排位赛排名历史最高
	defence_cards = rom.Msgpack(default=lambda: [(0, 0, 0)] * 6) # 被动防御部署卡牌列表 [(RoleCard.id, RoleCard.card_id, RoleCard.skin_id)]
	defence_card_attrs = rom.Msgpack(default=dict) # 被动防御卡牌离线属性，结构上与model不同，参见makePWCardInfo
	fightgo_val = rom.Integer(default=0) #先手值
	talents = rom.Msgpack(default=dict) #天赋相关
	fighting_point = rom.Integer(required=True, index=True) # 被动防御卡牌战斗力总和
	worship_roleIDs = rom.Msgpack(default=list) #今日膜拜过的人
	pvp_refresh_last_date = rom.Integer(default=0) #上次刷新时间
	enemy_ranks = rom.Msgpack(default=list) #4个敌方排名


class PVPPlayRecord(rom.Model):
	'''
	pvp竞技场战斗记录
	'''
	id = rom.PrimaryKey()
	date = rom.Integer(required=True, index=True, default=todaydate2int) # 战斗日期
	time = rom.Float(required=True, default=nowtime_t) # 战斗时间
	rand_seed = rom.Integer(required=True) # 战斗随机种子
	role_db_id = rom.Integer(required=True) # 主动进攻方Role.id
	record_db_id = rom.Integer(required=True) # 主动进攻方PVPRecord.id
	name = rom.String(required=True) # 主动进攻方角色名字
	logo = rom.Integer(required=True) # 主动进攻方角色头像ID
	rank = rom.Integer(required=True) # 主动进攻方原排名
	rank_top = rom.Integer(required=True) # 主动进攻方原最高排名
	cards = rom.Msgpack(default=lambda: [(0, 0)] * 6) # 主动进攻部署卡牌列表 [(RoleCard.id, RoleCard.card_id)]
	card_attrs = rom.Msgpack(default=dict) # 主动进攻卡牌离线属性
	fightgo_val = rom.Integer(default=0) #先手值
	talents = rom.Msgpack(default=dict) #天赋相关
	defence_role_db_id = rom.Integer(required=True) # 被动防御方Role.id
	defence_record_db_id = rom.Integer(required=True) # 被动防御方PVPRecord.id
	defence_name = rom.String(required=True) # 被动防御方角色名字
	defence_logo = rom.Integer(required=True) # 被动防御方角色头像ID
	defence_rank = rom.Integer(default=dict) # 被动防御方原排名
	defence_cards = rom.Msgpack(default=lambda: [(0, 0)] * 6) # 被动防御部署卡牌列表 [(RoleCard.id, RoleCard.card_id)]
	defence_card_attrs = rom.Msgpack(default=dict) # 被动防御卡牌离线属性
	defence_fightgo_val = rom.Integer(default=0) #被动防御先手值
	defence_talents = rom.Msgpack(default=dict) #被动防御天赋相关
	result = rom.Integer(default=0, index=True) # 战斗结果（可进行位运算） 0x00 未知 0x01 客户端运算胜利 0x02 客户端运算失败 0x04 服务器运算胜利 0x08 服务器运算失败


class PVPGlobal(rom.Model):
	'''
	pvp服务器全局记录
	'''
	id = rom.PrimaryKey()
	pw_ranks = rom.Msgpack(default=dict) # 排位赛总排名 {rank:(Role.id, PVPRecord.id)}
	pw_rank_max = rom.Integer(default=0) # 排位最大下标
	be_worship_roles = rom.Msgpack(default=dict) # 被膜拜次数{roleID:count}
	global_refresh_last_date = rom.Integer(default=0) #上次刷新时间


class PVPGlobalHistory(rom.Model):
	'''
	pvp服务器全局记录历史
	'''
	id = rom.PrimaryKey()
	award_time = rom.Integer(required=True, index=True) # 结算日期时间 14120913
	pw_role_ranks = rom.Msgpack(default=dict) # 排位赛离线玩家排名 {Role.id:rank}
	pw_all_ranks = rom.Msgpack(default=dict) # 排位赛总排名 {Role.id:rank}


class CraftRecord(rom.Model):
	'''
	拳皇争霸记录
	'''
	id = rom.PrimaryKey()
	role_db_id = rom.Integer(required=True, index=True) # Role.id
	role_name = rom.String(default='') # Role.name
	role_logo = rom.Integer(default=1) # Role.logo
	role_level = rom.Integer(default=1) # Role.level
	history = rom.Msgpack(default=list) # 战斗历史 [{t:时间, r:结果, brid:CraftPlayRecord.id, pname:对手名字, pid:对手Role.id, prid:对手CraftRecord.id, plogo:对手头像, point:所得积分}, ...]
	cards = rom.Msgpack(default=list) # 部署卡牌列表 [(RoleCard.id, RoleCard.card_id, RoleCard.skin_id)]
	card_attrs = rom.Msgpack(default=dict) # 被动防御卡牌离线属性，结构上与model不同，参见makePWCardInfo
	talents = rom.Msgpack(default=dict) #天赋相关


class CraftPlayRecord(rom.Model):
	'''
	拳皇争霸战斗记录
	'''
	id = rom.PrimaryKey()
	date = rom.Integer(required=True, index=True, default=todaydate2int) # 战斗日期
	time = rom.Float(required=True, default=nowtime_t) # 战斗时间
	round = rom.String(required=True, index=True) # 战斗场次，预选赛pre1...pre10，决赛final1...final3
	rand_seed = rom.Integer(required=True) # 战斗随机种子
	role_db_id = rom.Integer(required=True) # 选手1 Role.id
	record_db_id = rom.Integer(required=True) # 选手1 CraftRecord.id
	name = rom.String(required=True) # 选手1角色名字
	logo = rom.Integer(required=True) # 选手1角色头像ID
	level = rom.Integer(required=True) # 选手1角色等级
	cards = rom.Msgpack(default=list) # 选手1部署卡牌列表 [(RoleCard.id, RoleCard.card_id, RoleCard.skin_id)]
	card_attrs = rom.Msgpack(default=dict) # 选手1卡牌离线属性
	talents = rom.Msgpack(default=dict) # 选手1天赋
	defence_role_db_id = rom.Integer(required=True) # 选手2 Role.id
	defence_record_db_id = rom.Integer(required=True) # 选手2 CraftRecord.id
	defence_name = rom.String(required=True) # 选手2方角色名字
	defence_logo = rom.Integer(required=True) # 选手2方角色头像ID
	defence_level = rom.Integer(required=True) # 选手2方角色等级
	defence_cards = rom.Msgpack(default=list) # 选手2部署卡牌列表 [(RoleCard.id, RoleCard.card_id, RoleCard.skin_id)]
	defence_card_attrs = rom.Msgpack(default=dict) # 选手2卡牌离线属性
	defence_talents = rom.Msgpack(default=dict) #选手2天赋
	result = rom.String(default='unknown', index=True) # 选手1的战斗结果 unknown win fail tie
	point = rom.Integer(default=0) # 选手1的积分
	defence_point = rom.Integer(default=0) # 选手2的积分


class CraftGlobal(rom.Model):
	'''
	拳皇争霸服务器全局记录
	'''
	id = rom.PrimaryKey()
	date = rom.Integer(default=todaydate2int) # 战斗日期
	time = rom.Float(default=nowtime_t) # 战斗时间
	round = rom.String(default='pre1') # 战斗场次，预选赛pre1...pre10，决赛final1...final3, over
	craft_roles = rom.Msgpack(default=dict) # 拳皇争霸总信息 {Role.id: CraftRoleInfo}
	robots = rom.Msgpack(default=dict) # 机器人数据 {roleID: CraftRecord}
	top8_plays = rom.Msgpack(default=dict) # 8强战斗记录 {1: {role1: CraftRoleInfo, role2: CraftRoleInfo, result: CraftResultInfo, cards1:[cards], cards2:[cards]}} key参见Top8PlayKeyMap
	round_results = rom.Msgpack(default=dict) # 战局总记录 {pre1: {min(Role1.id, Role2.id): CraftResultInfo)}}


class CraftGlobalHistory(rom.Model):
	'''
	拳皇争霸服务器全局记录历史
	'''
	id = rom.PrimaryKey()
	award_time = rom.Integer(required=True, index=True) # 结算日期时间 14120913
	craft_all_ranks = rom.Msgpack(default=dict) # 拳皇争霸总排名 {Role.id:rank}
	top8 = rom.Msgpack(default=list) # 前8 [Role.id]
	top8_plays = rom.Msgpack(default=dict) # CraftGlobal.top8_plays 昨天之前的不再有意义
	robots = rom.Msgpack(default=dict) # 机器人数据 {roleID: CraftRecord}
	role_infos = rom.Msgpack(default=dict) # 真人数据 {roleID: (round, win, point)}


class UnionFightRecord(rom.Model):
	'''
	公会战记录
	'''
	id = rom.PrimaryKey()
	role_db_id = rom.Integer(required=True, index=True) # Role.id
	role_name = rom.String(default='') # Role.name
	role_logo = rom.Integer(default=1) # Role.logo
	role_level = rom.Integer(default=1) # Role.level
	cards = rom.Msgpack(default=dict) # 部署卡牌列表 {2day:{1队:[(RoleCard.id, RoleCard.card_id, RoleCard.skin_id)],2队:[]},3:,4:,5:,6:{1:[],2:[],3:[]}}
	card_attrs = rom.Msgpack(default=dict) # 被动防御卡牌离线属性，结构上与model不同，参见makePWCardInfo
	talents = rom.Msgpack(default=dict) #天赋相关
	union_db_id = rom.Integer(default=0) # union_db_id

class UnionFightPlayRecord(rom.Model):
	'''
	公会战战斗记录
	'''
	id = rom.PrimaryKey()
	date = rom.Integer(required=True, index=True, default=todaydate2int) # 战斗日期
	time = rom.Float(required=True, default=nowtime_t) # 战斗时间
	rand_seed = rom.Integer(required=True) # 战斗随机种子
	role_db_id = rom.Integer(required=True) # 选手1 Role.id
	record_db_id = rom.Integer(required=True) # 选手1 UnionFightRecord.id
	name = rom.String(required=True) # 选手1角色名字
	logo = rom.Integer(required=True) # 选手1角色头像ID
	level = rom.Integer(required=True) # 选手1角色等级
	cards = rom.Msgpack(default=list) # 选手1部署卡牌列表 [(RoleCard.id, RoleCard.card_id, RoleCard.skin_id)]
	card_attrs = rom.Msgpack(default=dict) # 选手1卡牌离线属性
	talents = rom.Msgpack(default=dict) # 选手1天赋
	card_states = rom.Msgpack(default=dict) #选手1卡牌的血量怒气信息 {cardID=(hp,mp1)}
	defence_role_db_id = rom.Integer(required=True) # 选手2 Role.id
	defence_record_db_id = rom.Integer(required=True) # 选手2 UnionFightRecord.id
	defence_name = rom.String(required=True) # 选手2方角色名字
	defence_logo = rom.Integer(required=True) # 选手2方角色头像ID
	defence_level = rom.Integer(required=True) # 选手2方角色等级
	defence_cards = rom.Msgpack(default=list) # 选手2部署卡牌列表 [(RoleCard.id, RoleCard.card_id, RoleCard.skin_id)]
	defence_card_attrs = rom.Msgpack(default=dict) # 选手2卡牌离线属性
	defence_talents = rom.Msgpack(default=dict) #选手2天赋
	defence_card_states = rom.Msgpack(default=dict) #选手2卡牌的血量怒气信息 {cardID=(hp,mp1)}
	result = rom.String(default='unknown', index=True) # 选手1的战斗结果 unknown win fail tie


class CrossCraftRecord(rom.Model):
	'''
	跨服拳皇争霸记录
	'''
	id = rom.PrimaryKey()
	role_db_id = rom.Integer(required=True, index=True) # Role.id
	serv_key = rom.String(default='') # server key
	role_name = rom.String(default='') # Role.name
	role_logo = rom.Integer(default=1) # Role.logo
	role_level = rom.Integer(default=1) # Role.level
	cards = rom.Msgpack(default=list) # 部署卡牌列表 [(RoleCard.id, RoleCard.card_id, RoleCard.skin_id)]
	card_attrs = rom.Msgpack(default=dict) # 被动防御卡牌离线属性，结构上与model不同，参见makePWCardInfo
	talents = rom.Msgpack(default=dict) #天赋相关
	history = rom.Msgpack(default=list) # 战斗历史，用作craft cross结束后的保存

class CrossCraftPlayRecord(rom.Model):
	'''
	跨服拳皇争霸战斗记录
	'''
	id = rom.PrimaryKey()
	date = rom.Integer(required=True, index=True) # cross开始日期
	time = rom.Float(required=True, default=nowtime_t) # 战斗时间
	cross_id = rom.Integer(required=True, index=True) # cross分配的ID
	round = rom.String(required=True, index=True) # 战斗场次，预选赛pre1...pre10，决赛final1...final3
	rand_seed = rom.Integer(required=True) # 战斗随机种子
	role_key = rom.Msgpack(required=True) # 选手1 (server key, Role.id)
	record_db_id = rom.Integer(required=True) # 选手1 CraftRecord.id
	name = rom.String(required=True) # 选手1角色名字
	logo = rom.Integer(required=True) # 选手1角色头像ID
	level = rom.Integer(required=True) # 选手1角色等级
	cards = rom.Msgpack(default=list) # 选手1部署卡牌列表 [(RoleCard.id, RoleCard.card_id, RoleCard.skin_id)]
	card_attrs = rom.Msgpack(default=dict) # 选手1卡牌离线属性
	talents = rom.Msgpack(default=dict) # 选手1天赋
	defence_role_key = rom.Msgpack(required=True) # 选手2 (server key, Role.id)
	defence_record_db_id = rom.Integer(required=True) # 选手2 CraftRecord.id
	defence_name = rom.String(required=True) # 选手2方角色名字
	defence_logo = rom.Integer(required=True) # 选手2方角色头像ID
	defence_level = rom.Integer(required=True) # 选手2方角色等级
	defence_cards = rom.Msgpack(default=list) # 选手2部署卡牌列表 [(RoleCard.id, RoleCard.card_id, RoleCard.skin_id)]
	defence_card_attrs = rom.Msgpack(default=dict) # 选手2卡牌离线属性
	defence_talents = rom.Msgpack(default=dict) #选手2天赋
	result = rom.String(default='unknown', index=True) # 选手1的战斗结果 unknown win fail tie
	point = rom.Integer(default=0) # 选手1的积分
	defence_point = rom.Integer(default=0) # 选手2的积分