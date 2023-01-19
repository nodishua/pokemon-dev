#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2014 YouMi Information Technology Inc.

Game Server Database Scheme
'''

# 注意！！！default={}，default=[]是错误的，对象会被引用
# 包括函数所生成的对象
# 除非常量，其余一定要使用函数重新生成 default=dict，default=list
# redisorm\columns.py 207

import db.redisorm as rom
from framework import nowtime_t, todaydate2int, todaymonth2int, todayinclock5date2int, nowtime2int

import random


class Role(rom.Model):
	'''
	主角基础属性
	'''
	id = rom.PrimaryKey()
	account_id = rom.Integer(required=True, index=True) # Account.id
	channel = rom.String(default='none', index=True) # 用户来源渠道，只有QQ消费钻石的时候用
	area = rom.Integer(default=1) # 账号所选区服，合服用
	name = rom.String(required=True, unique=True) # 角色名字
	personal_sign = rom.String(default="") # 个性签名
	created_time = rom.Float(default=nowtime_t) # 创建时间
	last_time = rom.Float(default=nowtime_t, index=True) # 上次操作时间
	logo = rom.Integer(default=1) # 角色头像ID
	level = rom.Integer(default=1, index=True) # 主角等级
	stamina = rom.Integer(default=100) # 主角当前体力值
	stamina_last_recover_time = rom.Float(default=nowtime_t) # 玩家上次体力恢复时间
	skill_point = rom.Integer(default=20) # 主角当前技能点数
	skill_point_last_recover_time = rom.Float(default=nowtime_t) # 玩家上次技能点数恢复时间
	level_exp = rom.Integer(default=0) # 当前等级下玩家积累的经验
	sum_exp = rom.Integer(default=0) # 当前玩家积累的总经验
	gold = rom.Integer(default=0) # 金币
	rmb = rom.Integer(default=0) # RMB钻石
	qq_rmb = rom.Integer(default=0) # QQ托管钻石
	qq_recharge = rom.Integer(default=0) # QQ充值总额
	coin1 = rom.Integer(default=0) # 代币1 - 竞技场
	coin2 = rom.Integer(default=0) # 代币2 - 远征
	coin3 = rom.Integer(default=0) # 代币3 - 公会
	coin4 = rom.Integer(default=0) # 代币4 - 合金精华
	rmb_consume = rom.Integer(default=0) # RMB钻石消耗
	talent_point = rom.Integer(default=0) # 天赋点
	fightgo = rom.Integer(default=0) # 先手值
	equip_awake_frag = rom.Integer(default=0) # 装备觉醒碎片数量
	vip_level = rom.Integer(default=0, index=True) # 当前玩家VIP等级
	cards = rom.Msgpack(default=list) # 玩家卡牌RoleCard.id列表 [RoleCard.id]
	items = rom.Msgpack(default=dict) # 玩家道具字典 {item_id:count}
	frags = rom.Msgpack(default=dict) # 玩家碎片字典 {frag_id:count}
	metals = rom.Msgpack(default=list) # 玩家合金列表 [RoleMetal.id]
	world_open = rom.Msgpack(default=list) # 开放的世界地图列表 [world_id]
	map_open = rom.Msgpack(default=list) # 开放的章节地图列表 [map_id]
	gate_open = rom.Msgpack(default=list) # 开放的关卡列表 [gate_id]
	gate_star = rom.Msgpack(default=dict) # 关卡星级字典 {gate_id:{star:0,chest:-1表示未达成 1表示可领取 0表示已领取,win_award:-1表示未达成 1表示可领取 0表示已领取,star3_award:-1表示未达成 1表示可领取 0表示已领取}}
	map_star = rom.Msgpack(default=dict) # 章节星级字典 {map_id:{star_award:[0,0,0]}}
	daily_task = rom.Msgpack(default=dict) # 日常任务字典{date:{task_id:{arg:0, flag:0}}} flag参见TaskDefs
	main_task = rom.Msgpack(default=dict) # 主线任务字典 {task_id:{arg:0, flag:0}} flag参见TaskDefs
	huodongs = rom.Msgpack(default=dict) # 活动字典 {date:{huodong_id:{times:今日次数, last_time:今日挑战时间}, ...}}
	huodongs_gate = rom.Msgpack(default=dict) # 活动通关字典 {huodong_id:{gateID:star}}
	yyhuodongs = rom.Msgpack(default=dict) # 运营活动字典 各活动异构 -1表示未达成 1表示可领取 0表示已领取
	newbie_guide = rom.Msgpack(default=list) # 新手指引 含有已完成的阶段
	client_flag = rom.Integer(default=0) # 客户端事件标记，服务器不使用
	recharges = rom.Msgpack(default=dict) # 购买的充值字典 {csv_id:{cnt:0, date:20141206, orders:[PayOrder.id], reset:0 or yyid or -yyid}}
	recharges_cache = rom.Msgpack(default=list) # 离线充值缓存 [(rechargeID, orderID)]
	gifts = rom.Msgpack(default=dict) # 已领取礼包字典 {gift_id: 0, -gift_type: 0}
	stable_drop_weights = rom.Msgpack(default=dict) # 玩家稳定掉落概率权值字典 {stable_drop_id:weight}
	battle_cards = rom.Msgpack(default=lambda: [0] * 6) # 出战部署卡牌RoleCard.id列表
	huodong_cards = rom.Msgpack(default=dict) # 活动关卡部署卡牌RoleCard.id列表 {huodongID:[]}
	enter_battle_cards = rom.Msgpack(default=lambda: [0] * 6) # 出战部署卡牌RoleCard.id列表
	enter_huodong_cards = rom.Msgpack(default=dict) # 活动关卡部署卡牌RoleCard.id列表 {huodongID:[]}
	daily_record_db_id = rom.Integer(default=0) # 当日 DailyRecord.id
	monthly_record_db_id = rom.Integer(default=0) # 当月 MonthlyRecord.id
	pvp_record_db_id = rom.Integer(default=0) # pvp竞技场数据 PVPRecord.id
	pw_playing_db_id = rom.Integer(default=0) # 排位赛主动战斗排队中的数据 PVPPlayRecord.id
	pw_shop_db_id = rom.Integer(default=0) # pvp竞技场商店数据 PVPShop.id
	yz_record_db_id = rom.Integer(default=0) # 远征数据 PVPRecord.id
	yz_shop_db_id = rom.Integer(default=0) # 远征商店数据 PVPShop.id
	fix_shop_db_id = rom.Integer(default=0) # 固定商店数据 FixShop.id
	lottery_db_id = rom.Integer(default=0) # 抽奖数据 LotteryRecord.id
	society_db_id = rom.Integer(default=0) # 社交数据 Society.id
	mailbox = rom.Msgpack(default=list) # 邮件缩略数据 [{db_id:Mail.id, subject:Mail.subject, time:Mail.time, type=Mail.type, sender:Mail.sender, global:Mail.role_db_id==0}, ...]
	read_mailbox = rom.Msgpack(default=list) # 已读邮件数据 [Mail, ...]
	tw_top_floor = rom.Integer(default=1) # 无尽之塔最高楼层，未通关，twawards CSV ID
	card_advance_times = rom.Integer(default=0) # 卡牌进阶总次数
	card_star_times = rom.Integer(default=0) # 卡牌升星总次数
	global_mail_idx = rom.Integer(default=0) # 收取全局邮件的游标
	cardNum_rank = rom.Integer(default=0) # cardNum rank排名，这里只是客户端显示用，不加索引，正确数据从RankGlobal获取
	fight_rank = rom.Integer(default=0) # fight rank排名
	gate_star_rank = rom.Integer(default=0) # gate star排名
	card1fight_rank = rom.Integer(default=0) # 单张卡牌战斗力排名
	pw_rank = rom.Integer(default=0) # 竞技场排名（缓存）
	battle_fighting_point = rom.Integer(default=0) # 卡牌战斗力
	top6_fighting_point = rom.Integer(default=0) # 历史最高前6卡牌战斗力
	union_db_id = rom.Integer(default=0) # 公会数据 Union.id
	union_last_db_id = rom.Integer(default=0) # 上次离开的公会id
	union_shop_db_id = rom.Integer(default=0) # 公会商店数据 UnionShop.id
	union_training_db_id = rom.Integer(default=0) # 公会训练所数据 UnionTraining.id
	union_join_time = rom.Float(default=0) # 加入公会时间
	union_quit_time = rom.Float(default=0) # 退出公会时间
	union_last_time = rom.Float(default=0) # 上次操作公会时间
	union_join_que = rom.Msgpack(default=list) # 申请加入的公会列表(最多三个,RoleJoinUnionPendingMax)
	union_huodongs = rom.Msgpack(default=dict) # 公会活动{huodong: {各活动异构}}
	union_mail_idx = rom.Integer(default=0) # 收取公会邮件的游标
	union_fb_award = rom.Msgpack(default=dict) # 公会副本奖励{union_fuben.csv ID: (最近领取月份, 次数)}
	disable_flag = rom.Boolean(default=False) # GM封号
	silent_flag = rom.Boolean(default=False) # GM禁言
	sign_in_count = rom.Integer(default=0) # 总的签到次数
	sign_in_gift = rom.Msgpack(default=lambda: [1, -1]) # [id,flag:-1 未达成 1 可领取]
	pw_rank_award = rom.Msgpack(default=dict) # {id:flag:-1: 未达成 0: 已领取 1: 可领取}
	vip_gift = rom.Msgpack(default=dict) # {vip_level:flag  0: 已购买}
	talent_trees = rom.Msgpack(default=dict) # {treeID:{['cost']:talent_point,talentID:level}}
	rename_count = rom.Integer(default=0) # 重命名的次数
	heirlooms = rom.Msgpack(default=dict) # 神器 {idx: {属性: 成长值}}
	snowball_maxpoint = rom.Integer(default=0) # 历史最佳雪球得分
	luckyegg_count = rom.Integer(default=-1) # 公会扭蛋游戏火神兽个数,-1表示没开始
	luckyegg_times = rom.Integer(default=0) # 公会扭蛋游戏局内次数，获得奖励后重置
	mystery_shop_db_id = rom.Integer(default=0) # 神秘商店数据 MysteryShop.id
	clone_room_db_id = rom.Integer(default=0) # 所选择的克隆人房间CloneRoom.id
	clone_room_last_date = rom.Integer(default=0) # 日期, CloneRoom.date
	clone_world_invite_last_time = rom.Float(default=0) # 上次克隆人房间邀请时间
	clone_union_invite_last_time = rom.Float(default=0) # 上次克隆人房间邀请时间
	achievement = rom.Msgpack(default=dict) # 成就字典 {id:flag}
	achieve_counter = rom.Msgpack(default=dict) # 各类成就计数器
	achieve_point = rom.Integer(default=0) # 成就积分
	achieve_rank = rom.Integer(default=0) # 成就 rank排名
	achieve_fightgo = rom.Integer(default=0) # 成就获得的速度奖励
	craft_record_db_id = rom.Integer(default=0) # 拳皇争霸数据 CraftRecord.id
	cross_craft_record_db_id = rom.Integer(default=0) # 跨服拳皇争霸数据 CrossCraftRecord.id
	top10_cards = rom.Msgpack(default=lambda: [(0, 0, 0)] * 10) # 玩家前10卡牌RoleCard.id列表 [(RoleCard.id, RoleCard.card_id, RoleCard.skin_id)]
	top12_cards = rom.Msgpack(default=lambda: [(0, 0, 0)] * 10) # 玩家前12卡牌RoleCard.id列表 [(RoleCard.id, RoleCard.card_id, RoleCard.skin_id)]
	skins = rom.Msgpack(default=dict) # 拥有的所有皮肤 {skin_id:time} 皮肤id和过期时间
	galaxys = rom.Msgpack(default=dict) # {cardMarkID:{useID,buyList}}
	galaxy_energy = rom.Integer(default=0) #星座能量
	galaxy_rank = rom.Integer(default=0) # 星座 rank排名
	unionfight_record_db_id = rom.Integer(default=0) # 公会战数据 UnionFightRecord.id
	titles = rom.Msgpack(default=dict) # 头衔 {id: dateint}
	title_id = rom.Integer(default=0) # 玩家选择的头衔, -1表示置空
	yy2048_gold = rom.Msgpack(default=list) # [date,point,gold] 2048游戏当日还未结算的金币
	cross_craft_sign_up_date = rom.Integer(default=0) # 报名跨服拳皇争霸日子

class RoleCard(rom.Model):
	'''
	主角卡牌
	'''
	id = rom.PrimaryKey()
	role_db_id = rom.Integer(required=True, index=True) # Role.id
	card_id = rom.Integer(required=True) # 卡牌CSV ID
	advance = rom.Integer(default=1) # 卡牌进阶
	star = rom.Integer(default=1) # 卡牌星级
	develop = rom.Integer(default=1) # 卡牌进化
	level = rom.Integer(default=1) # 卡牌等级
	level_exp = rom.Integer(default=0) # 当前等级下卡牌积累的经验
	sum_exp = rom.Integer(default=0) # 卡牌当前获得的总经验
	innate_skill_level = rom.Integer(default=1) # 主动天生技能等级
	skills = rom.Msgpack(default=dict) # 激活的卡牌技能id列表 {skill_id:level}
	fight_soul = rom.Msgpack(default=dict) # 激活的卡牌斗魂id列表 {id:{level,exp}}
	equips = rom.Msgpack(default=dict) # 装备 {1:{equipd_id,star,level,advance,exp},2:{...},...}
	fetters = rom.Msgpack(default=list) # 已激活的宿命列表
	feel_level = rom.Integer(default=1) # 卡牌好感度等级
	feel_sum_exp = rom.Integer(default=0) # 卡牌好感度总经验
	feel_level_exp = rom.Integer(default=0) # 卡牌当前等级下好感度经验
	fighting_point = rom.Integer(default=0) # 卡牌战斗力
	first_card2frag = rom.Boolean(default=False) # 是否第一次转换为碎片
	db_attrs = rom.Msgpack(default=dict) # 进前1000名才有记录
	skin_id = rom.Integer(default=0) # 当前使用的皮肤，0表示未使用
	metals = rom.Msgpack(default=lambda: [[0,0,0,0],[0,0,0,0,0,0],[0,0,0,0,0,0,0,0]])
	metal_matrix = rom.Msgpack(default=lambda:[0,0,0]) #合金指令 [id,id,id] 其中id>0表示激活的id;id<0表示重复激活的id;0表示未激活
	matrix_active_award = rom.Msgpack(default=dict) #激活类型奖励{type:flag} flag:-1表示未激活 1表示可领取 0表示已领取

class RoleMetal(rom.Model):
	'''
	主角合金
	'''
	id = rom.PrimaryKey()
	role_db_id = rom.Integer(required=True, index=True) # Role.id
	card_db_id = rom.Integer(default=0) # 合金上的RoleCard.id, 0表示没有被装备上
	metal_id = rom.Integer(required=True) # 合金CSV ID
	advance = rom.Integer(default=1) # 合金进阶等级
	level = rom.Integer(default=1) # 合金强化等级
	position = rom.Integer(default=-1) # 合金槽位位置，(组别*10+组别序号)。 -1表示未装备
	exist_flag = rom.Boolean(default=True, index=True) # 是否存在（可能已经被熔炼）


class DailyRecord(rom.Model):
	'''
	日常记录
	凌晨5点刷新
	'''
	id = rom.PrimaryKey()
	date = rom.Integer(required=True, index=True, default=todayinclock5date2int) # 日常日期
	role_db_id = rom.Integer(required=True, unique=True) # Role.id
	gate_chanllenge = rom.Integer(default=0) # 挑战关卡次数
	hero_gate_chanllenge = rom.Integer(default=0) # 挑战精英关卡次数
	nightmare_gate_chanllenge = rom.Integer(default=0) # 挑战噩梦关卡次数
	huodong_chanllenge = rom.Integer(default=0) # 挑战活动副本次数
	draw_card = rom.Integer(default=0) # 抽卡次数
	draw_equip = rom.Integer(default=0) # 抽装备次数
	dc1_free_count = rom.Integer(default=0) # 免费抽卡次数
	gold1_free_count = rom.Integer(default=0) # 免费金币抽卡次数
	gold1_free_last_time = rom.Float(default=0) # 玩家上次免费金币抽卡时间
	eq_dc1_free_counter = rom.Integer(default=0) # 免费装备单抽
	limit_box_free_counter = rom.Integer(default=0) # 免费限时宝箱单抽
	draw_gold1_metal = rom.Integer(default=0) # 抽合金金币单抽次数
	draw_gold10_metal = rom.Integer(default=0) # 抽合金金币10连抽次数
	draw_gold1_free_metal = rom.Integer(default=0) # 抽合金金币免费次数
	draw_rmb1_metal = rom.Integer(default=0) # 抽合金钻石单抽次数
	draw_rmb10_metal = rom.Integer(default=0) # 抽合金钻石10连抽次数
	draw_rmb1_free_metal = rom.Integer(default=0) # 抽合金钻石免费次数
	draw_gold_metal = rom.Integer(default=0) #任务记录专用
	draw_rmb_metal = rom.Integer(default=0) #任务记录专用
	metal_strength = rom.Integer(default=0) #任务记录专用
	equip_advance = rom.Integer(default=0) # 强化装备次数
	equip_zhulian = rom.Integer(default=0) # 铸炼装备次数
	skill_up = rom.Integer(default=0) # 卡牌技能升级
	level_up = rom.Integer(default=0) # 卡牌升级
	gate_times = rom.Msgpack(default=dict) # 关卡挑战次数字典 {gate_id:count}
	pvp_pw_times = rom.Integer(default=0) # pvp排位赛次数
	pvp_pw_last_time = rom.Float(default=0) # 玩家上次挑战排位时间
	pvp_shop_refresh_times = rom.Integer(default=0) # pvp竞技场商店刷新次数
	pvp_result_point = rom.Integer(default=0) # 竞技场积分
	pvp_enermys_refresh_times = rom.Integer(default=0) # 竞技场换一批次数
	result_point_award = rom.Msgpack(default=dict) # 竞技场积分奖励 {id:flag:-1: 未达成 0: 已领取 1: 可领取}
	buy_stamina_times = rom.Integer(default=0) # 购买体力次数
	buy_pw_times = rom.Integer(default=0) # 购买排位赛次数
	item_pw_times = rom.Integer(default=0) # 道具增加排位赛次数
	buy_herogate_times = rom.Msgpack(default=dict) # 购买重置英雄关卡次数字典 {gate_id:count}
	buy_pw_cd_times = rom.Integer(default=0) # 购买重置排位赛CD时间次数
	buy_skill_point_times = rom.Integer(default=0) # 购买技能点次数
	lianjin_times = rom.Integer(default=0) # 炼金次数
	yz_shop_refresh_times = rom.Integer(default=0) # 远征商店刷新次数
	yz_refresh_times = rom.Integer(default=0) # 远征刷新次数
	yz_times = rom.Integer(default=0) # 远征次数
	boss_gate = rom.Integer(default=0) # boss战次数
	boss_gate_buy = rom.Integer(default=0) # boss战购买次数
	boss_damage_rank = rom.Integer(default=0) # 世界boss伤害排名
	boss_damage_max = rom.Integer(default=0) # 世界boss伤害最大值
	chat_times = rom.Integer(default=0) # 聊天次数
	union_coin = rom.Integer(default=0) # 今日公会币获得
	union_fb_times = rom.Integer(default=0) # 公会副本挑战次数
	union_shop_refresh_times = rom.Integer(default=0) # 公会商店刷新次数
	union_redPacket_robs = rom.Msgpack(default=list) # 当日抢的玩家红包记录[(红包类型,红包角色名,红包金额),...]
	fix_shop_refresh_times = rom.Msgpack(default=dict) # 固定商店刷新次数 {group:times}
	fix_shop_buy = rom.Msgpack(default=dict) # 固定商品购买次数 {fix_shop.csv ID:count} 2-每日限定
	friend_stamina_send = rom.Msgpack(default=list) # 好友体力赠送列表 [Role.id]
	friend_stamina_gain = rom.Integer(default=0) # 领取好友赠送体力次数
	share_times = rom.Integer(default=0) # 每日分享次数
	union_mail_send_count = rom.Integer(default=0) # 每日发送公会邮件次数
	card_advance_times = rom.Integer(default=0) # 每日升品次数
	consume_rmb_sum = rom.Integer(default=0) #每日累计消费钻石数
	union_snowball_free = rom.Integer(default=0) # 雪球游戏免费使用次数
	union_snowball_award = rom.Msgpack(default=dict) # 雪球总奖励
	union_snowball_maxpoint = rom.Integer(default=0) # 今日最佳雪球得分
	union_luckyegg = rom.Integer(default=0) # 扭蛋游戏局数
	union_luckyegg_free = rom.Integer(default=0) # 扭蛋游戏免费使用次数
	union_training_speedup = rom.Integer(default=0) # 公会训练所给别人加速次数
	union_training_be_speedup_history = rom.Msgpack(default=list) # 公会训练所被别人加速历史，最多6条 [Role.name]
	union_contrib_times = rom.Integer(default=0) # 公会贡献+研究所贡献次数
	mystery_shop_weight = rom.Float(default=0) # 神秘商店权重
	mystery_active_times = rom.Integer(default=0) # 神秘商店激活次数
	clone_times = rom.Integer(default=0) # 克隆人玩法次数
	redPacket_send_count = rom.Integer(default=0) # 公会红包发红包次数
	redPacket_rob_count = rom.Integer(default=0) # 公会红包抢红包次数
	breakegg_gain_times = rom.Integer(default=0) # 每日获得砸金蛋次数
	breakegg_amount = rom.Float(default=0) # 每日砸金蛋获得金额数
	craft_sign_up = rom.Boolean(default=False) # 是否已报名拳皇争霸
	craft_rank = rom.Integer(default=0) # 拳皇争霸排名
	craft_bets = rom.Msgpack(default=dict) # 自己的下注额 {Role.id: gold}
	unionfight_sign_up = rom.Boolean(default=False) # 是否已报名公会战
	online_gift = rom.Msgpack(default=dict) # 在线礼包 {starttime=开始时间, idx=礼包下标, flag=0不可领，1可领，2已领}
	online_gift_double_times = rom.Integer(default=0) # 在线礼包翻倍次数
	unionfight_bets = rom.Msgpack(default=list) # 下注信息 #[unionID,gold]
	cross_craft_bets = rom.Msgpack(default=lambda: (0, None, None)) # 跨服王者下注信息 (金额，0偶数、1奇数，(server key, roleID))

class MonthlyRecord(rom.Model):
	'''
	每月记录
	自然月刷新
	'''
	id = rom.PrimaryKey()
	month = rom.Integer(required=True, index=True, default=todaymonth2int) # 年月
	role_db_id = rom.Integer(required=True, unique=True) # Role.id
	sign_in = rom.Integer(default=0) # 签到次数
	last_sign_in_day = rom.Integer(default=0) # 最新签到日
	last_sign_in_award = rom.Integer(default=0) # 最新签到奖励倍数

class LotteryRecord(rom.Model):
	'''
	抽奖记录
	'''
	id = rom.PrimaryKey()
	role_db_id = rom.Integer(required=True, unique=True) # Role.id
	dc1_gold_counter = rom.Integer(default=0) # 金币单抽
	dc10_gold_counter = rom.Integer(default=0) # 金币10连抽
	dc1_counter = rom.Integer(default=0) # 钻石单抽计数器
	dc10_counter = rom.Integer(default=0) # 钻石10连抽计数器
	eq_dc1_counter = rom.Integer(default=0) # 装备钻石单抽计数器
	eq_dc10_counter = rom.Integer(default=0) # 装备钻石10连抽计数器
	yz_freeBox_counter = rom.Integer(default=0) # 远征免费宝箱抽取计数器
	metal1_gold_counter = rom.Integer(default=0) # 合金金币单抽
	metal10_gold_counter = rom.Integer(default=0) # 合金金币10连抽
	metal1_counter = rom.Integer(default=0) # 合金钻石单抽计数器
	metal10_counter = rom.Integer(default=0) # 合金钻石10连抽计数器
	weight_info = rom.Msgpack(default=lambda: {'draw_card': {},'draw_equip': {}}) # 权值浮动 {draw_card:{csvID:weight},draw_equip:{csvID:weight},后续新增的在这里添加无效了,须在代码里保护}
	effect_info = rom.Msgpack(default=lambda: {'draw_card': {},'draw_equip': {}}) # 生效次数 {draw_card:{csvID:count},draw_equip:{csvID:count},后续新增的在这里添加无效了,须在代码里保护}

class PVPShop(rom.Model):
	'''
	pvp竞技场商店
	每日刷新，刷新时间由ShopRefreshTime控制
	'''
	id = rom.PrimaryKey()
	date = rom.Integer(required=True, index=True) # 商店创建日期+时间
	role_db_id = rom.Integer(required=True, index=True) # Role.id
	items = rom.Msgpack(required=True) # 商店商品列表 [(商店CSV ID, 商品CSV ID)]
	buy = rom.Msgpack(default=dict) # 已购买商店格子下标（0下标开始） {index:1}
	discard_flag = rom.Boolean(default=False, index=True) # 是否已废弃

class Mail(rom.Model):
 	'''
	邮件
	'''
	id = rom.PrimaryKey()
	role_db_id = rom.Integer(required=True, index=True) # Role.id, 0的话是全局邮件
	time = rom.Float(default=nowtime_t) # 发送时间
	type = rom.Integer(default=1) # 邮件类型CSV ID
	sender = rom.String(default='') # 发件人
	subject = rom.String(default='') # 邮件标题
	content = rom.String(default='') # 邮件内容
	attachs = rom.Msgpack(default=dict) # 附件{CSV_ID:count}
	deleted_flag = rom.Boolean(default=False, index=True) # 是否已删除，全局邮件不能设为Ture
	newbie_name = rom.String(default='', index=True) # 新建玩家的邮件，Account.name


class MailGlobal(rom.Model):
	'''
	全局全服邮件
	'''
	id = rom.PrimaryKey()
	mails = rom.Msgpack(default=list) # 全局邮件邮件缩略数据 [{db_id:Mail.id, subject:Mail.subject, time:Mail.time, type=Mail.type, mtype=邮件类型, sender:Mail.sender}, ...]


class YZRecord(rom.Model):
	'''
	远征记录
	'''
	id = rom.PrimaryKey()
	role_db_id = rom.Integer(required=True, unique=True) # Role.id
	yz_pass_floor = rom.Integer(default=0) # 代表已通过的层数
	yz_states = rom.Msgpack(default=dict) # 远征卡牌剩余数据 {RoleCard.id:[血量差值,能量差值], ...}
	yz_enemy_states = rom.Msgpack(default=dict) # 远征敌方卡牌剩余数据 {RoleCard.id:[血量差值,能量差值], ...}
	yz_floor_info = rom.Msgpack(default=dict) #{1:{},2:{},3:{}} #{['pass'] = True}
	star_count = rom.Integer(default=0) # 星级数
	buffID_list = rom.Msgpack(default=list) #拥有的buffIDs
	day_point = rom.Integer(default=0) # 当日积分
	day_rank = rom.Integer(default=0) # 当日积分排名
	history_point = rom.Integer(default=0) # 历史积分(除去当日)
	point_award = rom.Msgpack(default=dict) # 远征积分奖励{id 0: 已领取}
	last_date = rom.Integer(default=todayinclock5date2int) # 上一次远征时间
	last_floor = rom.Integer(default=0) # 上次远征所到达的层数
	skip_flag = rom.Integer(default=0) # 一键跳过标识 0:还没选择过 1:选择不跳过 2:跳过过程处理中 3:跳过结束
	skip_buff_floors = rom.Msgpack(default=dict) # 一键跳过各个buff层信息
	skip_box_floors = rom.Msgpack(default=dict) # 一键跳过各个宝箱层信息{floor:count}

class YZShop(rom.Model):
	'''
	远征商店
	每日刷新，刷新时间由ShopRefreshTime控制
	'''
	id = rom.PrimaryKey()
	date = rom.Integer(required=True, index=True) # 商店创建日期
	role_db_id = rom.Integer(required=True, index=True) # Role.id
	items = rom.Msgpack(required=True) # 商店商品列表 [(商店CSV ID, 商品CSV ID)]
	buy = rom.Msgpack(default=dict) # 已购买商店格子下标（0下标开始） {index:1}
	discard_flag = rom.Boolean(default=False, index=True) # 是否已废弃

class GMYYConfig(rom.Model):
	'''
	运营动态配置
	'''
	id = rom.PrimaryKey()
	yyhuodong = rom.Msgpack(default=dict) # yyhuodong.csv的在线配置，结构与csv相同
	login_weal = rom.Msgpack(default=dict) # loginweal.csv的在线配置，结构与csv相同
	level_award = rom.Msgpack(default=dict) # levelaward.csv的在线配置，结构与csv相同
	recharge_gift = rom.Msgpack(default=dict) # rechargegift.csv的在线配置，结构与csv相同
	placard = rom.Msgpack(default=dict) # placard.csv的在线配置，结构与csv相同


class Union(rom.Model):
	'''
	公会
	'''
	id = rom.PrimaryKey()
	name = rom.String(required=True, unique=True) # 公会名称
	logo = rom.Integer(default=lambda: random.randint(1, 10)) # 公会头像ID
	created_time = rom.Float(default=nowtime_t) # 公会创建时间
	level = rom.Integer(default=1, index=True) # 公会等级
	contrib = rom.Float(default=0, index=True) # 公会总贡献值
	day_contrib = rom.Float(default=0) # 公会当日贡献值计数
	last_date = rom.Integer(default=todayinclock5date2int) # 结算日期时间
	intro = rom.String(default='') # 公会简介
	join_type = rom.Integer(default=0) # 0 审批加入 1 直接加入 2 拒绝加入
	join_level = rom.Integer(default=0) # 申请加入公会的角色等级限制
	chairman_db_id = rom.Integer(required=True, unique=True) # 公会会长 Role.id
	vice_chairmans = rom.Msgpack(default=list) # 公会副会长 [Role.id, ...]
	members = rom.Msgpack(default=dict) # 公会成员 {Role.id: {id:Role.id, lg:Role.logo, n:Role.name, lvl:Role.level, fp:战力, lt:上次登录时间, rps:发送红包消费钻石, rpsc:发送红包总个数, rpr:抢红包得到钻石, rprc:抢红包总个数}, ...}
	join_notes = rom.Msgpack(default=dict) # 加入公会申请 {id: {t:申请时间, id:Role.id, lg:Role.logo, n:Role.name, lvl:Role.level, fp:战力}, ...}
	history = rom.Msgpack(default=list) # 公会历史（最多100条） [{t:时间, tp:类型, r:参数, c:参数}, ...]
	huodongs = rom.Msgpack(default=dict) # 公会开启活动参数 {huodong: {flag:UnionDefs}}
	mails = rom.Msgpack(default=list) # 公会邮件邮件缩略数据 [{db_id:Mail.id, subject:Mail.subject, time:Mail.time, type=Mail.type, mtype=邮件类型, sender:Mail.sender}, ...]
	fb_month = rom.Integer(default=todaymonth2int) # 公会副本重置月份
	fb_award_date = rom.Integer(default=todaydate2int) # 公会副本奖励日期 21:30
	fb_reset_date = rom.Integer(default=todaydate2int) # 公会副本重置日期 5:00
	fb_states = rom.Msgpack(default=dict) # 公会副本战斗进度状态 {union_fuben.csv ID: {damage: 伤害值, time: 通关时间, hpmax: 总血量, award: 周期内奖励是否已发送, fail: 未通关次数, members: {Role.id: 伤害值}, buff: 加成百分比}}
	fb_extra_history = rom.Msgpack(default=list) # 副本额外奖励分配记录 [(roleID, time)]
	institute = rom.Msgpack(default=dict) # 公会研究所{模块ID:{分支ID:{level, contrib, level_contrib}}}
	snowball_points = rom.Msgpack(default=dict) # 雪球玩法得分 {Role.id: (point, time)}
	luckyegg_points = rom.Msgpack(default=dict) # 扭蛋玩法得分 {Role.id: (point, time)}
	fight_playrecord_info = rom.Msgpack(default=dict) # 公会战记录{sceneNum:{battle_field:{round:[{r:结果, brid:UnionFightPlayRecord.id, sname:己方名字, sid:己方Role.id, srid:己方UnionFightRecord.id, slogo:己方头像, slevel:己方等级, swinc:己方连胜数, suname:己方公会名, sque:己方队列, shp:己方血量, pname:对手名字, pid:对手Role.id, prid:对手UnionFightRecord.id, plogo:对手头像, plevel:对手等级, pwinc:对手连胜数, puname:对手公会名, pque:对手队列, php:对手血量,}, ...]}}}
	fight_play_dead_info = rom.Msgpack(default=dict) # 公会战记录{sceneNum:{battle_field:{round:[roleID]}}}
	fight_point = rom.Msgpack(default=dict) # 公会战积分 {2:(point,maxWinCount),...,6:(point,maxWinCount)}

class UnionShop(rom.Model):
	'''
	公会商店
	每日刷新，刷新时间由ShopRefreshTime控制
	'''
	id = rom.PrimaryKey()
	date = rom.Integer(required=True, index=True) # 商店创建日期
	role_db_id = rom.Integer(required=True, index=True) # Role.id
	items = rom.Msgpack(required=True) # 商店商品列表 [(商店CSV ID, 商品CSV ID)]
	buy = rom.Msgpack(default=dict) # 已购买商店格子下标（0下标开始） {index:1}
	discard_flag = rom.Boolean(default=False, index=True) # 是否已废弃


class UnionDomain(rom.Model):
	'''
	公会领地
	'''
	id = rom.PrimaryKey()
	occupy_union_db_id = rom.Integer(default=0, index=True) # 占领该领地的Union.id
	chanllenge_union_db_id = rom.Integer(default=0, index=True) # 挑战该领地的Union.id
	last_state = rom.Integer(default=0, index=True) # 该领地状态
	last_state_time = rom.Float(default=0) # 状态最后更新时间


class UnionTraining(rom.Model):
	'''
	公会训练所
	从属于Role
	'''
	id = rom.PrimaryKey()
	role_db_id = rom.Integer(required=True, index=True) # Role.id
	created_time = rom.Float(default=0) # 训练所创建时间(换公会发生改变)
	slots = rom.Msgpack(default=dict, required=True) # 训练所栏位 {idx: {who: RoleCard.id（0表示空）, last_time: 经验奖励最后更新时间, card:缓存客户端显示用的属性}}
	opened = rom.Msgpack(default=dict) # 栏位开通
	offline_exp = rom.Msgpack(default=dict) # 离线经验获得（别人的加速）{idx: exp}
	offline_speedup = rom.Msgpack(default=dict) # 离线被别人加速 {date: [roleName]}
	client_exp_show = rom.Msgpack(default=dict) # 离线经验获得（纯客户端显示）


class UnionRedPacket(rom.Model):
	'''
	公会红包
	从属于Union
	'''
	id = rom.PrimaryKey()
	union_db_id = rom.Integer(required=True, index=True) # union.id
	packet_flag = rom.Integer(default=0, required=True) # 0:玩家红包 1:系统红包
	packet_type = rom.Integer(default=0, required=True) # 0:金币红包 1:钻石红包 2:神器红包
	date = rom.Integer(default=0) # 上次重置时间
	created_time = rom.Float(default=0) # 创建红包时间
	role_db_id = rom.Integer(default=0) # Role.id
	role_name = rom.String(default="") # 角色名字
	total_val = rom.Integer(default=0) # 总量
	total_count = rom.Integer(default=0) # 总个数
	members = rom.Msgpack(default=dict) # 公会成员 {Role.id: {id:Role.id, lg:Role.logo, n:Role.name, vip:Role.vip_level, val:val}, ...}
	discard_flag = rom.Boolean(default=False, index=True) # 是否已废弃

class FixShop(rom.Model):
	'''
	固定商店
	'''
	id = rom.PrimaryKey()
	role_db_id = rom.Integer(required=True, index=True) # Role.id
	items = rom.Msgpack(default=dict) # 商店商品列表 {group:[(商店CSV ID, 商品CSV ID)]}
	buy = rom.Msgpack(default=dict) # 已购买商店格子下标（0下标开始） {group:{index:1}}
	fix_buy = rom.Msgpack(default=dict) # 已购买固定商品 {fix_shop.csv ID:count} 1-账号限定
	last_time = rom.Msgpack(default=dict) # 商店刷新时间 {group:time}


class Society(rom.Model):
	'''
	社交
	'''
	id = rom.PrimaryKey()
	role_db_id = rom.Integer(required=True, unique=True) # Role.id
	friends = rom.Msgpack(default=list) # 好友列表 [Role.id]
	friend_reqs = rom.Msgpack(default=list) # 好友申请列表 [Role.id]
	stamina_recv = rom.Msgpack(default=list) # 好友体力可领取列表 [Role.id]
	black_list = rom.Msgpack(default=list) # 黑名单列表 [Role.id]


class ServerGlobalRecord(rom.Model):
	'''
	服务器全局记录
	'''
	id = rom.PrimaryKey()
	fight_rank_history = rom.Msgpack(default=dict) # 战力排行历史 {yyID:[排名缓存]}
	yyhuodongs_open = rom.Msgpack(default=dict) # 记录运营活动开始日期，只用于3-相对开服日期
	clone_monsters = rom.Msgpack(default=list) # 克隆兽列表
	craft_ranks = rom.Msgpack(default=dict) # 争霸排行榜，头衔用 {roleID: rank}
	pw_ranks = rom.Msgpack(default=dict) # 竞技场排行榜，头衔用
	gate_star_ranks = rom.Msgpack(default=dict) # 星级排行榜，头衔用
	card1fight_ranks = rom.Msgpack(default=dict) # 驯兽排行榜，头衔用
	card_num_ranks = rom.Msgpack(default=dict) # 卡牌排行榜，头衔用
	role_tiles = rom.Msgpack(default=dict) # 玩家头衔 {roleID: titleID}
	last_time = rom.Float(default=0) # 最近更新时间


class ServerDailyRecord(rom.Model):
	'''
	服务器日常记录
	'''
	id = rom.PrimaryKey()
	date = rom.Integer(index=True, default=todaydate2int) # 日常日期
	version = rom.Integer(default=0) # 版本号
	ch_accounts = rom.Msgpack(default=dict) # 渠道登录账号 {channel:[Account.id], ...}
	ch_newbies = rom.Msgpack(default=dict) # 新增渠道角色账号 {channel:[Account.id], ...}
	ch_newaccounts = rom.Msgpack(default=dict) # 新增用户账号 {channel:[Account.id], ...}
	ch_amounts = rom.Msgpack(default=dict) # 渠道用户充值 {channel:{Account.id:amount}, ...}
	amounts = rom.Float(default=0) # 充值总金额
	rmb_consume = rom.Msgpack(default=dict) # 钻石消耗总额 {from:count}
	rmb_sys_produce = rom.Msgpack(default=dict) # 系统产出钻石总额（非充值）{from:count}
	before_rmb_left = rom.Integer(default=0) # 上一天的钻石结余
	before_rmb_consume = rom.Integer(default=0) # 上一天的消费总额
	before_rmb_produce = rom.Integer(default=0) # 上一天的产出总额（加上充值）


class MysteryShop(rom.Model):
	'''
	神秘商店
	每日刷新，刷新时间由ShopRefreshTime控制
	'''
	id = rom.PrimaryKey()
	role_db_id = rom.Integer(required=True, index=True) # Role.id
	date = rom.Integer(required=True, index=True) # 商店创建日期
	items = rom.Msgpack(required=True) # 商店商品列表 [(商店CSV ID, 商品CSV ID)]
	buy = rom.Msgpack(default=dict) # 已购买商店格子下标（0下标开始） {index:1}
	discard_flag = rom.Boolean(default=False, index=True) # 是否已废弃
	last_active_time = rom.Float(default=0) # 商店上次激活时间
	refresh_times = rom.Integer(default=0)	# 商店刷新次数


class CloneRoom(rom.Model):
	'''
	克隆人玩法房间
	'''
	id = rom.PrimaryKey()
	date = rom.Integer(required=True) # 日期, 12点刷新
	csv_id = rom.Integer(required=True) # 对应的clone_monster.csv ID
	places = rom.Msgpack(default=dict) # {idx: {id, name, play, card={pwModel}, top_card={pwModel}}} 房间位置, idx从1开始
	leader = rom.Integer(default=0) # 队长的Role.id
	fast = rom.Boolean(default=True) # 是否允许快速加入
	discard_flag = rom.Boolean(default=False, index=True) # 是否已废弃


class CraftInfoGlobal(rom.Model):
	'''
	拳皇争霸全局数据
	'''
	id = rom.PrimaryKey()
	date = rom.Integer(default=0) # 日期
	time = rom.Float(default=nowtime_t) # CraftGlobal.time
	round = rom.String(default='closed') # CraftGlobal.round, closed, signup, prepare, prepare_ok
	signup = rom.Msgpack(default=dict) # 报名 {Role.id: RoleSignItem}
	bet = rom.Msgpack(default=dict) # 昨天前20下注 {Role.id: {info: ObjectRankGlobal.BaseRoleInfos, rank: 上次排名, rate: 赔率, gold: {Role.id: gold}}}
	yesterday_top8_plays = rom.Msgpack(default=dict) # 昨天8强战斗记录 CraftGlobal.top8_plays
	yesterday_refresh_time = rom.Integer(default=nowtime2int) # yesterday的刷新时间
	top8_plays = rom.Msgpack(default=dict) # 今日8强战斗记录 CraftGlobal.top8_plays
	robots = rom.Msgpack(default=dict) # 机器人数据 {roleID: CraftRecord}

class UnionFightGlobal(rom.Model):
	'''
	工会战全局数据
	'''
	id = rom.PrimaryKey()
	date = rom.Integer(default=0) # 日期
	last_award_time = rom.Integer(default=0) # 上次结算日期
	signup = rom.Msgpack(default=dict) # 报名 {Role.id: (recordID,unionID)}
	round = rom.String(default='closed') # closed, signup, prepare, over, battle
	roles_win = rom.Msgpack(default=dict) #胜场数 {weekday:{roleID:winCount}}
	last_pkey_max = rom.Integer(default=1) # 上次playrecord最大dbkey
	last_role = rom.Msgpack(default=list) # 预选赛最后一个玩家[lastround,roleID,unionID]
	pre_top8_union = rom.Msgpack(default=list) # 周六决赛前前8公会[(unionID,name,logo,point)]
	scene_vs_info = rom.Msgpack(default=dict) #8强对阵信息{1:(unionID1,unionID2,winUnionID),...7:(unionID1,unionID2,winUnionID)}
	final_battle_info = rom.Msgpack(default=dict) #8强对阵每轮信息 {sceneNum:(field, round, lastUnionID)}
	role_ranks = rom.Msgpack(default=dict) #角色连胜数排名{weekday:[(roleID,roleName,unionName,score)]}
	bet = rom.Msgpack(default=dict) #{unionID:{rank:,name:,logo:,level:,rate:,gold:{roleID:gold}}}
	dead_rounds = rom.Msgpack(default=dict) # {field:{round:{union_db_id:(deadcount,membercount,name)}}}
	final_dead_rounds = rom.Msgpack(default=dict) # {sceneNum:{round:{unionID: (deadcount, membercount, name)}}}


class CrossCraftGameGlobal(rom.Model):
	'''
	拳皇争霸跨服数据
	'''
	id = rom.PrimaryKey()
	cross_key = rom.String(default='') # 跨服server key
	date = rom.Integer(default=0) # 日期, 用来验证是否跟cross匹配
	bet1 = rom.Msgpack(default=dict) # 本服第一天下注 {Role.id: (金额，0偶数、1奇数)}
	signup = rom.Msgpack(default=dict) # 本服报名 {Role.id: RoleSignItem}
	last_top8_plays = rom.Msgpack(default=dict) # 昨天8强战斗记录 CraftGlobal.top8_plays
	last_refresh_time = rom.Integer(default=nowtime2int) # yesterday的刷新时间
	last_ranks = rom.Msgpack(default=list) # 昨天的排行榜