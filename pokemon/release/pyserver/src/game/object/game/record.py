#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2014 YouMi Information Technology Inc.
'''

from __future__ import absolute_import

from framework import todayinclock5date2int, todaymonth2int, nowtime_t
from framework.csv import ErrDefs,csv, ConstDefs
from framework.object import Copyable, ObjectBase, ObjectDBase, db_property

from game import ServerError, ClientError
from game.object import DrawCardDefs, DrawEquipDefs, DrawBoxDefs, YYHuoDongDefs, TitleDefs, TargetDefs, DrawItemDefs, DrawSumBoxDefs, DrawGemDefs, DrawChipDefs, AchievementDefs, FeatureDefs
from game.object.game.card import CardAttrs
from game.object.game.gain import ObjectCostAux
from game.object.game.lottery import ObjectDrawCardRandom, ObjectDrawEquipRandom, ObjectDrawItemRandom, ObjectDrawGemRandom, ObjectDrawChipRandom, ObjectDrawEffect
from game.globaldata import DrawEquipCostPrice, Draw10EquipCostPrice, MonthSignGiftDays
from game.object.game.yyhuodong import ObjectYYHuoDongFactory


#
# ObjectDailyRecord
#

class ObjectDailyRecord(ObjectDBase):
	DBModel = 'DailyRecord'

	def _fixCorrupted(self):
		self.level_up = max(0, self.level_up)

	# 日常日期
	date = db_property('date')

	# 挑战关卡次数
	gate_chanllenge = db_property('gate_chanllenge')

	# 挑战精英关卡次数
	hero_gate_chanllenge = db_property('hero_gate_chanllenge')

	# 挑战噩梦关卡次数
	nightmare_gate_chanllenge = db_property('nightmare_gate_chanllenge')

	# 挑战活动副本次数
	huodong_chanllenge = db_property('huodong_chanllenge')

	# 抽卡次数
	draw_card = db_property('draw_card')

	# 钻石半价单抽次数
	draw_card_rmb1_half = db_property('draw_card_rmb1_half')

	# 训练师等级特权免费金币抽取
	draw_card_gold1_trainer = db_property('draw_card_gold1_trainer')

	# 抽装备次数
	draw_equip = db_property('draw_equip')

	# boss战次数
	boss_gate = db_property('boss_gate')

	# boss战购买次数
	boss_gate_buy = db_property('boss_gate_buy')

	# 升级装备次数
	equip_strength = db_property('equip_strength')

	# 进阶装备次数
	equip_advance = db_property('equip_advance')

	# 卡牌技能升级
	skill_up = db_property('skill_up')

	# 卡牌升级
	level_up = db_property('level_up')

	# 关卡挑战次数字典 {gate_id:count}
	gate_times = db_property('gate_times')

	# pvp排位赛次数
	pvp_pw_times = db_property('pvp_pw_times')

	# pvp竞技场积分
	def pvp_result_point():
		dbkey = 'pvp_result_point'
		def fset(self, value):
			old = self.db[dbkey]
			if old != value:
				self.db[dbkey] = value
				for idx in csv.pwpoint_award:
					cfg = csv.pwpoint_award[idx]
					award = self.result_point_award.get(idx,None)
					if award is None and value >= cfg.needPoint:
						self.result_point_award[idx] = 1
				# 只统计加上的值
				if value > old:
					ObjectYYHuoDongFactory.onGeneralTask(self.game, TargetDefs.ArenaPoint, value - old)
		return locals()
	pvp_result_point = db_property(**pvp_result_point())

	# 竞技场换一批次数
	pvp_enermys_refresh_times = db_property('pvp_enermys_refresh_times')

	result_point_award = db_property('result_point_award')

	# 玩家上次挑战排位时间
	pvp_pw_last_time = db_property('pvp_pw_last_time')

	# 购买体力次数
	buy_stamina_times = db_property('buy_stamina_times')

	# 月卡免费购买体力次数
	buy_stamina_free_times = db_property('buy_stamina_free_times')

	# 购买排位赛次数
	buy_pw_times = db_property('buy_pw_times')

	# 道具增加排位赛次数
	item_pw_times = db_property('item_pw_times')

	# 购买重置英雄关卡次数字典 {gate_id:count}
	buy_herogate_times = db_property('buy_herogate_times')

	# 购买重置排位赛CD时间次数
	buy_pw_cd_times = db_property('buy_pw_cd_times')

	# 购买技能点次数
	buy_skill_point_times = db_property('buy_skill_point_times')

	# 炼金次数
	lianjin_times = db_property('lianjin_times')

	# 月卡免费炼金次数
	lianjin_free_times = db_property('lianjin_free_times')

	# 炼金每日礼包
	lianjin_gifts = db_property('lianjin_gifts')

	# 远征商店刷新次数
	yz_shop_refresh_times = db_property('yz_shop_refresh_times')

	# 远征刷新次数
	yz_refresh_times = db_property('yz_refresh_times')

	# 远征次数
	yz_times = db_property('yz_times')

	# 世界boss伤害排名
	boss_damage_rank = db_property('boss_damage_rank')

	# 世界boss伤害最大值
	boss_damage_max = db_property('boss_damage_max')

	# 世界boss记录伤害的公会ID
	boss_union_db_id = db_property('boss_union_db_id')

	# 聊天次数次数
	chat_times = db_property('chat_times')

	# 今日公会币获得
	union_coin = db_property('union_coin')

	# 公会副本挑战次数
	union_fb_times = db_property('union_fb_times')

	# pvp竞技场商店刷新次数
	union_shop_refresh_times = db_property('union_shop_refresh_times')

	# 固定商店刷新次数 times
	fix_shop_refresh_times = db_property('fix_shop_refresh_times')

	# 好友体力赠送列表 [Role.id]
	friend_stamina_send = db_property('friend_stamina_send')

	# 领取好友赠送体力次数
	friend_stamina_gain = db_property('friend_stamina_gain')

	# 每日分享次数
	share_times = db_property('share_times')

	# 免费抽卡次数
	dc1_free_count = db_property('dc1_free_count')

	# 免费金币抽卡次数
	gold1_free_count = db_property('gold1_free_count')

	gold1_free_last_time = db_property('gold1_free_last_time')

	# 装备免费单抽
	eq_dc1_free_counter = db_property('eq_dc1_free_counter')

	# 免费限时宝箱单抽
	limit_box_free_counter = db_property('limit_box_free_counter')

	# 每日升品次数
	card_advance_times = db_property('card_advance_times')

	# 每日累计消费钻石数
	consume_rmb_sum = db_property('consume_rmb_sum')

	# 每日累计消费钻石数
	cost_stamina_sum = db_property('cost_stamina_sum')

	# 公会训练所给别人加速次数
	union_training_speedup = db_property('union_training_speedup')

	# 公会贡献次数
	union_contrib_times = db_property('union_contrib_times')

	# 神秘商店权重
	mystery_shop_weight = db_property('mystery_shop_weight')

	# 神秘商店权重
	mystery_active_times = db_property('mystery_active_times')

	# 限时捕捉出现权重
	capture_limit_weight = db_property('capture_limit_weight')

	# 限时捕捉出现次数
	capture_limit_times = db_property('capture_limit_times')

	# 元素挑战玩法次数
	clone_times = db_property('clone_times')

	# 公会红包发红包次数
	redPacket_send_count = db_property('redPacket_send_count')

	# 公会红包抢红包次数
	redPacket_rob_count = db_property('redPacket_rob_count')

	# 当日抢的玩家红包记录[(红包类型,红包角色名,红包金额),...]
	union_redPacket_robs = db_property('union_redPacket_robs')

	# 每日获得砸金蛋次数
	breakegg_gain_times = db_property('breakegg_gain_times')

	# 每日砸金蛋获得金额数
	breakegg_amount = db_property('breakegg_amount')

	# 是否已报名拳皇争霸
	craft_sign_up = db_property('craft_sign_up')

	# 拳皇争霸排名
	craft_rank = db_property('craft_rank')

	# 王者下注信息 {rank1: (role.id, gold)}
	craft_bets = db_property('craft_bets')

	# 是否已报名公会战
	union_fight_sign_up = db_property('union_fight_sign_up')

	# 在线礼包 {starttime=开始时间, idx=礼包下标, flag=0不可领，1可领，2已领}
	online_gift = db_property('online_gift')

	# 在线礼包翻倍次数
	online_gift_double_times = db_property('online_gift_double_times')

	# 下注信息 #[unionID,gold]
	union_fight_bets = db_property('union_fight_bets')


	# 活跃度点数
	liveness_point = db_property('liveness_point')

	# 活跃度阶段奖励领取记录
	liveness_stage_award = db_property('liveness_stage_award')

	# 无尽之塔 每日重置次数
	endless_tower_reset_times = db_property('endless_tower_reset_times')

	# 公会每日礼包领取次数
	union_daily_gift_times = db_property('union_daily_gift_times')

	# 每日累计充值
	recharge_rmb_sum = db_property('recharge_rmb_sum')

	# 训练师等级每日礼包
	trainer_gift_times = db_property('trainer_gift_times')

	# 派遣任务当日派遣卡牌
	dispatch_cardIDs = db_property('dispatch_cardIDs')

	# 派遣任务免费刷新次数
	dispatch_refresh_free_times = db_property('dispatch_refresh_free_times')

	# 主城常规彩蛋奖励领取次数
	city_sprite_gift_times = db_property('city_sprite_gift_times')

	# 寻宝商店刷新次数
	explorer_shop_refresh_times = db_property('explorer_shop_refresh_times')

	# 道具免费单抽
	item_dc1_free_counter = db_property('item_dc1_free_counter')

	# 抽道具次数
	draw_item = db_property('draw_item')

	# 道具（探险寻宝）钻石半价单抽次数
	draw_item_rmb1_half = db_property('draw_item_rmb1_half')

	# 碎片商店刷新次数
	frag_shop_refresh_times = db_property('frag_shop_refresh_times')

	# 公会每日一次红包
	redPacket_daily = db_property('redPacket_daily')

	# 精灵分享次数
	card_share_times = db_property('card_share_times')

	# 随机塔商店刷新次数
	randomTower_shop_refresh_times = db_property('randomTower_shop_refresh_times')

	# 钓鱼商店刷新次数
	fishing_shop_refresh_times = db_property('fishing_shop_refresh_times')

	# 战报分享次数
	battle_share_times = db_property('battle_share_times')

	# 金币抽卡次数
	dc_gold_count = db_property('dc_gold_count')

	# 无尽塔挑战/扫荡次数
	endless_challenge = db_property('endless_challenge')

	# 扭蛋机每日免费单抽计数器
	lucky_egg_free_counter = db_property('lucky_egg_free_counter')

	# 钓鱼今日次数
	fishing_counter = db_property('fishing_counter')

	# 钓鱼今日成功次数
	fishing_win_counter = db_property('fishing_win_counter')

	# 钓鱼今日记录
	fishing_record = db_property('fishing_record')

	# 运营活动发红包次数
	huodong_redPacket_send = db_property('huodong_redPacket_send')

	# 运营活动抢红包次数
	huodong_redPacket_rob = db_property('huodong_redPacket_rob')

	# 运营活动跨服发红包次数
	huodong_cross_redPacket_send = db_property('huodong_cross_redPacket_send')

	# 运营活动跨服抢红包次数
	huodong_cross_redPacket_rob = db_property('huodong_cross_redPacket_rob')

	# 公会碎片赠予次数
	union_frag_donate_times = db_property('union_frag_donate_times')

	# 公会碎片赠予发起次数
	union_frag_donate_start_times = db_property('union_frag_donate_start_times')

	# 聊天次数
	role_chat_times = db_property('role_chat_times')

	# 宝石免费单抽
	gem_rmb_dc1_free_count = db_property('gem_rmb_dc1_free_count')

	# 钻石抽宝石次数
	draw_gem_rmb = db_property('draw_gem_rmb')

	# 宝石金币免费单抽
	gem_gold_dc1_free_count = db_property('gem_gold_dc1_free_count')

	# 金币抽宝石次数
	draw_gem_gold = db_property('draw_gem_gold')

	# 抽宝石次数(不区分金币钻石，包括免费次数)
	draw_gem = db_property('draw_gem')

	# 芯片钻石免费单抽
	chip_rmb_dc1_free_count = db_property('chip_rmb_dc1_free_count')

	# 钻石抽芯片次数
	draw_chip_rmb = db_property('draw_chip_rmb')

	# 芯片道具免费单抽
	chip_item_dc1_free_count = db_property('chip_item_dc1_free_count')

	# 道具抽芯片次数
	draw_chip_item = db_property('draw_chip_item')

	# 抽芯片次数(不区分金币钻石，包括免费次数)
	draw_chip = db_property('draw_chip')

	# 跨服竞技场挑战次数
	cross_arena_pw_times = db_property('cross_arena_pw_times')

	# 跨服竞技场更换对手次数
	cross_arena_refresh_times = db_property('cross_arena_refresh_times')

	# 跨服竞技场积分奖励 {id: flag}（-1: 未达成  0: 已领取  1: 可领取）
	cross_arena_point_award = db_property('cross_arena_point_award')

	# 跨服竞技场购买挑战次数
	cross_arena_buy_times = db_property('cross_arena_buy_times')

	# 跨服竞技场战报分享次数
	cross_arena_battle_share_times = db_property('cross_arena_battle_share_times')

	# 实时对战每日已经挑战的次数
	cross_online_fight_times = db_property('cross_online_fight_times')

	# 实时对战每日分享次数
	cross_online_fight_share_times = db_property('cross_online_fight_share_times')

	# 限时up符石免费单抽
	limit_up_gem_free_count = db_property('limit_up_gem_free_count')

	# 进化石每日购买机会
	mega_convert_buy_times = db_property('mega_convert_buy_times')

	# 每日精灵评论计数
	card_comment_counter = db_property('card_comment_counter')

	# 每日评分计数
	card_score_counter = db_property('card_score_counter')

	# 道馆成功挑战次数次数
	gym_battle_times = db_property('gym_battle_times')

	# 道馆天赋buff点购买次数
	gym_talent_point_buy_times = db_property('gym_talent_point_buy_times')

	# 道馆副本挑战购买次数
	gym_battle_buy_times = db_property('gym_battle_buy_times')

	# 活动boss发现次数
	huodong_boss_count = db_property('huodong_boss_count')

	# 活动boss挑战次数
	huodong_boss_times = db_property('huodong_boss_times')

	# 跨服资源战抢夺次数
	cross_mine_rob_times = db_property('cross_mine_rob_times')

	# 跨服资源战报仇次数
	cross_mine_revenge_times = db_property('cross_mine_revenge_times')

	# 跨服资源战 Boss 挑战次数
	cross_mine_boss_times = db_property('cross_mine_boss_times')

	# 跨服资源战抢夺购买次数
	cross_mine_rob_buy_times = db_property('cross_mine_rob_buy_times')

	# 跨服资源战报仇购买次数
	cross_mine_revenge_buy_times = db_property('cross_mine_revenge_buy_times')

	# 跨服资源战 Boss 挑战购买次数
	cross_mine_boss_buy_times = db_property('cross_mine_boss_buy_times')

	# 跨服资源战 buff喂养 {'server':{csvID:count},'role':{csvID:count}}
	cross_mine_buff_feed = db_property('cross_mine_buff_feed')

	# 跨服资源战换一批次数
	cross_mine_enemy_refresh_times = db_property('cross_mine_enemy_refresh_times')

	# 跨服资源战每日分享次数
	cross_mine_share_times = db_property('cross_mine_share_times')

	# 公会问答次数
	union_qa_times = db_property("union_qa_times")

	# 公会问答购买次数
	union_qa_buy_times = db_property("union_qa_buy_times")

	# 公会问答 每日首次参加时所在公会
	union_qa_union_db_id = db_property("union_qa_union_db_id")

	# 公会问答 每日最高分
	union_qa_top_score = db_property("union_qa_top_score")

	# 勇者挑战次数
	brave_challenge_times = db_property("brave_challenge_times")

	# 勇者挑战购买次数
	brave_challenge_buy_times = db_property("brave_challenge_buy_times")

	# 自选限定抽卡切换次数
	draw_card_up_change_times = db_property("draw_card_up_change_times")

	def renew(self):
		self.game.role.refreshUnionContribTasks(self.date)  # 里面会涉及到部分周任务重置, contrib tasks 没有单独记录日期

		self.date = todayinclock5date2int()
		self.gate_chanllenge = 0
		self.hero_gate_chanllenge = 0
		self.nightmare_gate_chanllenge = 0
		self.huodong_chanllenge = 0
		self.draw_card = 0
		self.draw_card_rmb1_half = 0
		self.draw_card_gold1_trainer = 0
		self.draw_equip = 0
		self.dc1_free_count = 0
		self.gold1_free_count = 0
		self.gold1_free_last_time = 0
		self.eq_dc1_free_counter = 0
		self.limit_box_free_counter = 0
		self.equip_strength = 0
		self.equip_advance = 0
		self.skill_up = 0
		self.level_up = 0
		self.gate_times = {}
		self.pvp_pw_times = 0
		self.item_pw_times = 0
		self.pvp_pw_last_time = 0
		self.pvp_result_point = 0
		self.pvp_enermys_refresh_times = 0
		self.result_point_award = {}
		self.buy_stamina_times = 0
		self.buy_stamina_free_times = 0
		self.buy_pw_times = 0
		self.buy_herogate_times = {}
		self.buy_pw_cd_times = 0
		self.buy_skill_point_times = 0
		self.lianjin_times = 0
		self.lianjin_free_times = 0
		self.lianjin_gifts = {}
		self.yz_shop_refresh_times = 0
		self.yz_refresh_times = 0
		self.yz_times = 0
		self.boss_gate = 0
		self.boss_gate_buy = 0
		self.boss_damage_rank = 0
		self.boss_damage_max = 0
		self.boss_union_db_id = None
		self.chat_times = 0
		self.union_coin = 0
		self.union_fb_times = 0
		self.union_shop_refresh_times = 0
		self.fix_shop_refresh_times = 0
		self.friend_stamina_send = []
		self.friend_stamina_gain = 0
		self.share_times = 0
		self.card_advance_times = 0
		self.consume_rmb_sum = 0
		self.cost_stamina_sum = 0
		self.union_training_speedup = 0
		self.union_contrib_times = 0
		self.mystery_shop_weight = 0
		self.mystery_active_times = 0
		self.capture_limit_weight = 0
		self.capture_limit_times = 0
		self.clone_times = 0
		self.redPacket_send_count = 0
		self.redPacket_rob_count = 0
		self.union_redPacket_robs = []
		self.breakegg_gain_times = 0
		self.breakegg_amount = 0
		self.craft_sign_up = False
		self.craft_rank = 0
		self.craft_bets = {}
		self.union_fight_sign_up = False
		self.online_gift = {}
		self.online_gift_double_times = 0
		self.union_fight_bets = {}
		self.liveness_point = 0
		self.liveness_stage_award = {}
		self.endless_tower_reset_times = 0
		self.union_daily_gift_times = 0
		self.recharge_rmb_sum = 0
		self.trainer_gift_times = 0
		self.dispatch_cardIDs = []
		self.dispatch_refresh_free_times = 0
		self.city_sprite_gift_times = 0
		self.explorer_shop_refresh_times = 0
		self.frag_shop_refresh_times = 0
		self.item_dc1_free_counter = 0
		self.draw_item = 0
		self.draw_item_rmb1_half = 0
		self.redPacket_daily = []
		self.card_share_times = 0
		self.randomTower_shop_refresh_times = 0
		self.fishing_shop_refresh_times = 0
		self.battle_share_times = 0
		self.dc_gold_count = 0
		self.endless_challenge = 0
		self.lucky_egg_free_counter = 0
		self.fishing_counter = 0
		self.fishing_win_counter = 0
		self.fishing_record = {}
		self.huodong_redPacket_send = 0
		self.huodong_redPacket_rob = 0
		self.union_frag_donate_times = 0
		self.union_frag_donate_start_times = 0
		self.role_chat_times = 0
		self.gem_rmb_dc1_free_count = 0
		self.draw_gem_rmb = 0
		self.gem_gold_dc1_free_count = 0
		self.draw_gem_gold = 0
		self.draw_gem = 0
		self.chip_rmb_dc1_free_count = 0
		self.draw_chip_rmb = 0
		self.chip_item_dc1_free_count = 0
		self.draw_chip_item = 0
		self.draw_chip = 0
		self.cross_arena_pw_times = 0
		self.cross_arena_refresh_times = 0
		self.cross_arena_point_award = {}
		self.cross_arena_buy_times = 0
		self.cross_arena_battle_share_times = 0
		self.cross_online_fight_times = 0
		self.cross_online_fight_share_times = 0
		self.limit_up_gem_free_count = 0
		self.mega_convert_buy_times = {}
		self.card_comment_counter = {}
		self.card_score_counter = {}
		self.gym_battle_times = 0
		self.gym_talent_point_buy_times = 0
		self.gym_battle_buy_times = 0
		self.huodong_boss_times = 0
		self.huodong_boss_count = 0
		self.cross_mine_rob_times = 0
		self.cross_mine_revenge_times = 0
		self.cross_mine_boss_times = {}
		self.cross_mine_rob_buy_times = 0
		self.cross_mine_revenge_buy_times = 0
		self.cross_mine_boss_buy_times = {}
		self.cross_mine_buff_feed = {}
		self.cross_mine_enemy_refresh_times = 0
		self.cross_mine_share_times = 0
		self.union_qa_times = 0
		self.union_qa_buy_times = 0
		self.union_qa_union_db_id = None
		self.union_qa_top_score = 0
		self.huodong_cross_redPacket_send = 0
		self.huodong_cross_redPacket_rob = 0
		self.brave_challenge_times = 0
		self.brave_challenge_buy_times = 0
		self.draw_card_up_change_times = 0


#
# ObjectMonthlyRecord
#


class ObjectMonthlyRecord(ObjectDBase):
	DBModel = 'MonthlyRecord'

	# 年月
	month = db_property('month')

	# 签到次数
	sign_in = db_property('sign_in')

	# 最新签到日
	last_sign_in_day = db_property('last_sign_in_day')

	# 最新签到csvid
	last_sign_in_idx = db_property('last_sign_in_idx')

	# 月累积签到奖励
	sign_in_gift = db_property('sign_in_gift')

	# 补签次数
	sign_in_buy_times = db_property('sign_in_buy_times')

	# 签到奖励倍数(含补签) {day: {csvid: multiple}}
	sign_in_awards = db_property('sign_in_awards')

	# 刷新时的 vip
	vip = db_property('vip')

	# vip 月度礼包领取情况
	vip_gift = db_property('vip_gift')

	# 公会副本击杀奖励次数 {csvID: times}
	union_fuben_deadly_times = db_property('union_fuben_deadly_times')

	def renew(self):
		self.month = todaymonth2int()
		self.sign_in = 0
		self.last_sign_in_day = 0
		self.last_sign_in_idx = 0
		self.sign_in_gift = {}
		self.sign_in_buy_times = 0
		self.sign_in_awards = {}
		self.union_fuben_deadly_times = {}

		from game.object.game import ObjectFeatureUnlockCSV
		if ObjectFeatureUnlockCSV.isOpen(FeatureDefs.VipDistinguished, self.game):
			self.vip = self.game.role.vip_level
			self.vip_gift = {}

	def activeSignInGift(self):
		'''
		月累计签到奖励激活
		'''
		for idx, day in MonthSignGiftDays:
			if idx in self.sign_in_gift:
				continue
			if self.sign_in >= day:
				self.sign_in_gift[idx] = 1


#
# ObjectLotteryRecord
#

class ObjectLotteryRecord(ObjectDBase):
	DBModel = 'LotteryRecord'
	ClientIgnores = set([
		'weight_info',
		'effect_info',
		'lib_weight_info',
		'lib_effect_info',
		'draw_chip_lib_counter',
	])

	# 道具单抽
	dc1_item_counter = db_property('dc1_item_counter')

	# 钻石单抽计数器
	dc1_counter = db_property('dc1_counter')

	# 钻石10连抽计数器
	dc10_counter = db_property('dc10_counter')

	# 金币单抽计数器
	dc1_gold_counter = db_property('dc1_gold_counter')

	# 金币10连抽计数器
	dc10_gold_counter = db_property('dc10_gold_counter')

	# 远征免费宝箱抽取计数器
	yz_freeBox_counter = db_property('yz_freeBox_counter')

	# {draw_card:{csvID:weight},draw_equip:{csvID:weight}}
	weight_info = db_property('weight_info')

	# {draw_card:{csvID:count},draw_equip:{csvID:count}}
	effect_info = db_property('effect_info')

	def drawCard(self, drawType, half=False):
		drawTimes = 0
		if drawType == DrawCardDefs.RMB1:
			drawTimes = self.dc1_counter
			self.game.role.checkCardCapacityEnough(1)
			if half: # 训练师等级特权半价优先
				if self.game.role.rmb < int(ConstDefs.drawCardCostPrice / 2):
					raise ClientError(ErrDefs.drawCardRMBNotEnough)
			elif self.game.items.getItemCount(DrawCardDefs.RMBDrawItem) < 1:
				if self.game.role.rmb < ConstDefs.drawCardCostPrice:
					raise ClientError(ErrDefs.drawCardRMBNotEnough)

		elif drawType == DrawCardDefs.RMB10:
			drawTimes = self.dc10_counter
			self.game.role.checkCardCapacityEnough(10)
			if self.game.items.getItemCount(DrawCardDefs.RMBDrawItem) < 10:
				if self.game.role.rmb < ConstDefs.draw10CardCostPrice:
					raise ClientError(ErrDefs.drawCardRMBNotEnough)

		elif drawType == DrawCardDefs.Free1:
			drawTimes = self.dc1_counter
			self.game.role.checkCardCapacityEnough(1)
			if self.game.dailyRecord.dc1_free_count > 0:
				raise ClientError(ErrDefs.freeDrawCardTimerNoCD)

		elif drawType == DrawCardDefs.Gold1:
			drawTimes = self.dc1_gold_counter
			if self.game.items.getItemCount(DrawCardDefs.GoldDrawItem) < 1:
				if self.game.role.gold < ConstDefs.drawGoldCostPrice:
					raise ClientError(ErrDefs.drawCardGoldNotEnough)
			if self.game.dailyRecord.dc_gold_count + 1 > self.game.role.goldDrawCardCountLimit:
				raise ClientError(ErrDefs.goldDrawLimitUp)

		elif drawType == DrawCardDefs.Gold10:
			drawTimes = self.dc10_gold_counter
			if self.game.items.getItemCount(DrawCardDefs.GoldDrawItem) < 10:
				if self.game.role.gold < ConstDefs.draw10GoldCostPrice:
					raise ClientError(ErrDefs.drawCardGoldNotEnough)
			if self.game.dailyRecord.dc_gold_count + 10 > self.game.role.goldDrawCardCountLimit:
				raise ClientError(ErrDefs.goldDrawLimitUp)

		elif drawType == DrawCardDefs.FreeGold1:
			drawTimes = self.dc1_gold_counter
			if self.game.dailyRecord.gold1_free_count + self.game.dailyRecord.draw_card_gold1_trainer >= ConstDefs.drawGoldFreeLimit + self.game.trainer.freeGoldDrawCardTimes:
				raise ClientError(ErrDefs.goldDrawFreeLimitUp)
			# if nowtime_t() - self.game.dailyRecord.gold1_free_last_time < ConstDefs.drawGoldFreeRefreshDuration:
			# 	raise ClientError(ErrDefs.goldFreeDrawCardTimerNoCD)

		def _afterGain():
			if drawType == DrawCardDefs.RMB1:
				self.dc1_counter += 1
				self.game.dailyRecord.draw_card += 1
				if half:
					self.game.dailyRecord.draw_card_rmb1_half += 1
					cost = ObjectCostAux(self.game, {'rmb': int(ConstDefs.drawCardCostPrice / 2)})
				else:
					cost = ObjectCostAux(self.game, {DrawCardDefs.RMBDrawItem: 1})
					if not cost.isEnough():
						cost = ObjectCostAux(self.game, {'rmb': ConstDefs.drawCardCostPrice})
				cost.cost(src='draw_card_rmb1')
				ObjectYYHuoDongFactory.onGeneralTask(self.game, TargetDefs.DrawCardRMB1, 1)
				ObjectYYHuoDongFactory.onGeneralTask(self.game, TargetDefs.DrawCardRMB, 1)
				ObjectYYHuoDongFactory.onGeneralTask(self.game, TargetDefs.DrawCardUpAndRMB, 1)

			elif drawType == DrawCardDefs.RMB10:
				self.dc10_counter += 1
				self.game.dailyRecord.draw_card += 10
				cost = ObjectCostAux(self.game, {DrawCardDefs.RMBDrawItem: 10})
				if not cost.isEnough():
					cost = ObjectCostAux(self.game, {'rmb': ConstDefs.draw10CardCostPrice})
				cost.cost(src='draw_card_rmb10')
				ObjectYYHuoDongFactory.onGeneralTask(self.game, TargetDefs.DrawCardRMB10, 1)
				ObjectYYHuoDongFactory.onGeneralTask(self.game, TargetDefs.DrawCardRMB, 10)
				ObjectYYHuoDongFactory.onGeneralTask(self.game, TargetDefs.DrawCardUpAndRMB, 10)

			elif drawType == DrawCardDefs.Free1:
				self.dc1_counter += 1
				self.game.dailyRecord.draw_card += 1
				self.game.dailyRecord.dc1_free_count += 1
				ObjectYYHuoDongFactory.onGeneralTask(self.game, TargetDefs.DrawCardRMB, 1)
				ObjectYYHuoDongFactory.onGeneralTask(self.game, TargetDefs.DrawCardUpAndRMB, 1)

			elif drawType == DrawCardDefs.Gold1:
				self.dc1_gold_counter += 1
				self.game.dailyRecord.draw_card += 1
				self.game.dailyRecord.dc_gold_count += 1
				cost = ObjectCostAux(self.game, {DrawCardDefs.GoldDrawItem: 1})
				if not cost.isEnough():
					cost = ObjectCostAux(self.game, {'gold': ConstDefs.drawGoldCostPrice})
				cost.cost(src='draw_card_gold1')
				ObjectYYHuoDongFactory.onGeneralTask(self.game, TargetDefs.DrawCardGold1, 1)
				ObjectYYHuoDongFactory.onGeneralTask(self.game, TargetDefs.DrawCardGold, 1)

			elif drawType == DrawCardDefs.Gold10:
				self.dc10_gold_counter += 1
				self.game.dailyRecord.draw_card += 10
				self.game.dailyRecord.dc_gold_count += 10
				cost = ObjectCostAux(self.game, {DrawCardDefs.GoldDrawItem: 10})
				if not cost.isEnough():
					cost = ObjectCostAux(self.game, {'gold': ConstDefs.draw10GoldCostPrice})
				cost.cost(src='draw_card_gold10')
				ObjectYYHuoDongFactory.onGeneralTask(self.game, TargetDefs.DrawCardGold10, 1)
				ObjectYYHuoDongFactory.onGeneralTask(self.game, TargetDefs.DrawCardGold, 10)

			elif drawType == DrawCardDefs.FreeGold1:
				self.dc1_gold_counter += 1
				self.game.dailyRecord.draw_card += 1
				if self.game.dailyRecord.draw_card_gold1_trainer < self.game.trainer.freeGoldDrawCardTimes:
					self.game.dailyRecord.draw_card_gold1_trainer += 1
				else:
					self.game.dailyRecord.gold1_free_count += 1
					self.game.dailyRecord.gold1_free_last_time = nowtime_t()
				ObjectYYHuoDongFactory.onGeneralTask(self.game, TargetDefs.DrawCardGold, 1)

		return ObjectDrawCardRandom.getRandomItems(self.game, drawType, drawTimes + 1, _afterGain)

	# 装备钻石单抽计数器
	eq_dc1_counter = db_property('eq_dc1_counter')

	# 装备钻石10连抽计数器
	eq_dc10_counter = db_property('eq_dc10_counter')

	def drawEquip(self, drawType):
		drawTimes = 0
		if drawType == DrawEquipDefs.RMB1:
			drawTimes = self.eq_dc1_counter
			if self.game.items.getItemCount(DrawEquipDefs.drawKey) < 1:
				if self.game.role.rmb < ConstDefs.drawEquipCostPrice:
					raise ClientError(ErrDefs.drawEquipRMBNotEnough)

		elif drawType == DrawEquipDefs.RMB10:
			drawTimes = self.eq_dc10_counter
			if self.game.items.getItemCount(DrawEquipDefs.drawKey) < 10:
				if self.game.role.rmb < ConstDefs.draw10EquipCostPrice:
					raise ClientError(ErrDefs.drawEquipRMBNotEnough)

		elif drawType == DrawEquipDefs.Free1:
			drawTimes = self.eq_dc1_counter
			if self.game.dailyRecord.eq_dc1_free_counter > 0:
				raise ClientError(ErrDefs.freeDrawTimerNoCD)

		def _afterGain():
			if drawType == DrawEquipDefs.RMB1:
				self.eq_dc1_counter += 1
				self.game.dailyRecord.draw_equip += 1
				self.game.role.equip_awake_frag += 1
				cost = ObjectCostAux(self.game, {DrawEquipDefs.drawKey: 1})
				if not cost.isEnough():
					cost = ObjectCostAux(self.game, {'rmb': ConstDefs.drawEquipCostPrice})
				cost.cost(src='draw_equip_rmb1')
				ObjectYYHuoDongFactory.onGeneralTask(self.game, TargetDefs.DrawEquipRMB1, 1)
				ObjectYYHuoDongFactory.onGeneralTask(self.game, TargetDefs.DrawEquip, 1)

			elif drawType == DrawEquipDefs.RMB10:
				self.eq_dc10_counter += 1
				self.game.dailyRecord.draw_equip += 10
				self.game.role.equip_awake_frag += 10
				cost = ObjectCostAux(self.game, {DrawEquipDefs.drawKey: 10})
				if not cost.isEnough():
					cost = ObjectCostAux(self.game, {'rmb': ConstDefs.draw10EquipCostPrice})
				cost.cost(src='draw_equip_rmb10')
				ObjectYYHuoDongFactory.onGeneralTask(self.game, TargetDefs.DrawEquipRMB10, 1)
				ObjectYYHuoDongFactory.onGeneralTask(self.game, TargetDefs.DrawEquip, 10)

			elif drawType == DrawEquipDefs.Free1:
				self.game.dailyRecord.eq_dc1_free_counter += 1
				self.game.dailyRecord.draw_equip += 1
				self.eq_dc1_counter += 1
				self.game.role.equip_awake_frag += 1
				ObjectYYHuoDongFactory.onGeneralTask(self.game, TargetDefs.DrawEquip, 1)

		return ObjectDrawEquipRandom.getRandomItems(self.game, drawType, drawTimes + 1, _afterGain)

	# 道具单抽计数器
	item_dc1_counter = db_property('item_dc1_counter')

	def drawItem(self, drawType):
		drawTimes = 0
		tempDrawType = drawType
		if drawType == DrawItemDefs.COIN4_1:
			drawTimes = self.item_dc1_counter

		elif drawType == DrawItemDefs.Free1:
			drawTimes = self.item_dc1_counter
			if self.game.dailyRecord.item_dc1_free_counter > self.game.trainer.drawItemFreeTimes: # 一次免费 + 特权次数
				raise ClientError(ErrDefs.freeDrawTimerNoCD)
			# 转换
			tempDrawType = DrawItemDefs.COIN4_1

		def _afterGain():
			if drawType == DrawItemDefs.COIN4_1:
				self.item_dc1_counter += 1
				self.game.dailyRecord.draw_item += 1
				ObjectYYHuoDongFactory.onGeneralTask(self.game, TargetDefs.DrawItem, 1)

			elif drawType == DrawItemDefs.Free1:
				self.game.dailyRecord.item_dc1_free_counter += 1
				self.item_dc1_counter += 1
				ObjectYYHuoDongFactory.onGeneralTask(self.game, TargetDefs.DrawItem, 1)

		return ObjectDrawItemRandom.getRandomItems(self.game, tempDrawType, drawTimes + 1, _afterGain)

	# 宝石钻石单抽计数器
	gem_rmb_dc1_counter = db_property('gem_rmb_dc1_counter')

	# 宝石钻石10连抽计数器
	gem_rmb_dc10_counter = db_property('gem_rmb_dc10_counter')

	# 宝石金币单抽计数器
	gem_gold_dc1_counter = db_property('gem_gold_dc1_counter')

	# 宝石钻石10连抽计数器
	gem_gold_dc10_counter = db_property('gem_gold_dc10_counter')

	def drawGem(self, drawType):
		drawTimes = 0
		if drawType == DrawGemDefs.RMB1:
			drawTimes = self.gem_rmb_dc1_counter
			if self.game.items.getItemCount(DrawGemDefs.RMBDrawItem) < 1:
				if self.game.role.rmb < ConstDefs.drawGemCostPrice:
					raise ClientError(ErrDefs.drawGemRMBNotEnough)
			if self.game.dailyRecord.draw_gem_rmb + 1 > self.game.role.rmbDrawGemCountLimit:
				raise ClientError(ErrDefs.rmbDrawGemLimitUp)

		elif drawType == DrawGemDefs.RMB10:
			drawTimes = self.gem_rmb_dc10_counter
			if self.game.items.getItemCount(DrawGemDefs.RMBDrawItem) < 10:
				if self.game.role.rmb < ConstDefs.draw10GemCostPrice:
					raise ClientError(ErrDefs.drawGemRMBNotEnough)
			if self.game.dailyRecord.draw_gem_rmb + 10 > self.game.role.rmbDrawGemCountLimit:
				raise ClientError(ErrDefs.rmbDrawGemLimitUp)

		elif drawType == DrawGemDefs.Free1:
			drawTimes = self.gem_rmb_dc1_counter
			if self.game.dailyRecord.gem_rmb_dc1_free_count > 0:
				raise ClientError(ErrDefs.freeDrawTimerNoCD)

		elif drawType == DrawGemDefs.Gold1:
			drawTimes = self.gem_gold_dc1_counter
			if self.game.items.getItemCount(DrawGemDefs.GoldDrawItem) < 1:
				if self.game.role.gold < ConstDefs.drawGemGoldCostPrice:
					raise ClientError(ErrDefs.drawGemGoldNotEnough)
			if self.game.dailyRecord.draw_gem_gold + 1 > self.game.role.goldDrawGemCountLimit:
				raise ClientError(ErrDefs.rmbDrawGemLimitUp)

		elif drawType == DrawGemDefs.Gold10:
			drawTimes = self.gem_gold_dc10_counter
			if self.game.items.getItemCount(DrawGemDefs.GoldDrawItem) < 10:
				if self.game.role.gold < ConstDefs.draw10GemGoldCostPrice:
					raise ClientError(ErrDefs.drawGemGoldNotEnough)
			if self.game.dailyRecord.draw_gem_gold + 10 > self.game.role.goldDrawGemCountLimit:
				raise ClientError(ErrDefs.goldDrawGemLimitUp)

		elif drawType == DrawGemDefs.FreeGold1:
			drawTimes = self.gem_gold_dc1_counter
			if self.game.dailyRecord.gem_gold_dc1_free_count > 0:
				raise ClientError(ErrDefs.freeDrawTimerNoCD)

		def _afterGain():
			if drawType == DrawGemDefs.RMB1:
				self.gem_rmb_dc1_counter += 1
				self.game.dailyRecord.draw_gem_rmb += 1
				self.game.dailyRecord.draw_gem += 1
				cost = ObjectCostAux(self.game, {DrawGemDefs.RMBDrawItem: 1})
				if not cost.isEnough():  # 代金券不足则用钻石
					cost = ObjectCostAux(self.game, {'rmb': ConstDefs.drawGemCostPrice})
				cost.cost(src='draw_gem_rmb1')
				ObjectYYHuoDongFactory.onGeneralTask(self.game, TargetDefs.DrawGemRMB, 1)
				ObjectYYHuoDongFactory.onGeneralTask(self.game, TargetDefs.DrawGem, 1)
				ObjectYYHuoDongFactory.onGeneralTask(self.game, TargetDefs.DrawGemUpAndRMB, 1)
				self.game.achievement.onCount(AchievementDefs.DrawGemRMB, 1)

			elif drawType == DrawGemDefs.RMB10:
				self.gem_rmb_dc10_counter += 1
				self.game.dailyRecord.draw_gem_rmb += 10
				self.game.dailyRecord.draw_gem += 10
				cost = ObjectCostAux(self.game, {DrawGemDefs.RMBDrawItem: 10})
				if not cost.isEnough():
					cost = ObjectCostAux(self.game, {'rmb': ConstDefs.draw10GemCostPrice})
				cost.cost(src='draw_gem_rmb10')
				ObjectYYHuoDongFactory.onGeneralTask(self.game, TargetDefs.DrawGemRMB, 10)
				ObjectYYHuoDongFactory.onGeneralTask(self.game, TargetDefs.DrawGem, 10)
				ObjectYYHuoDongFactory.onGeneralTask(self.game, TargetDefs.DrawGemUpAndRMB, 10)
				self.game.achievement.onCount(AchievementDefs.DrawGemRMB, 10)

			elif drawType == DrawGemDefs.Free1:
				self.gem_rmb_dc1_counter += 1
				self.game.dailyRecord.gem_rmb_dc1_free_count += 1
				self.game.dailyRecord.draw_gem += 1
				ObjectYYHuoDongFactory.onGeneralTask(self.game, TargetDefs.DrawGemRMB, 1)
				ObjectYYHuoDongFactory.onGeneralTask(self.game, TargetDefs.DrawGem, 1)
				ObjectYYHuoDongFactory.onGeneralTask(self.game, TargetDefs.DrawGemUpAndRMB, 1)
				self.game.achievement.onCount(AchievementDefs.DrawGemRMB, 1)

			elif drawType == DrawGemDefs.Gold1:
				self.gem_gold_dc1_counter += 1
				self.game.dailyRecord.draw_gem_gold += 1
				self.game.dailyRecord.draw_gem += 1
				cost = ObjectCostAux(self.game, {DrawGemDefs.GoldDrawItem: 1})
				if not cost.isEnough():
					cost = ObjectCostAux(self.game, {'gold': ConstDefs.drawGemGoldCostPrice})
				cost.cost(src='draw_gem_gold1')
				ObjectYYHuoDongFactory.onGeneralTask(self.game, TargetDefs.DrawGemGold, 1)
				ObjectYYHuoDongFactory.onGeneralTask(self.game, TargetDefs.DrawGem, 1)
				self.game.achievement.onCount(AchievementDefs.DrawGemGold, 1)

			elif drawType == DrawGemDefs.Gold10:
				self.gem_gold_dc10_counter += 1
				self.game.dailyRecord.draw_gem_gold += 10
				self.game.dailyRecord.draw_gem += 10
				cost = ObjectCostAux(self.game, {DrawGemDefs.GoldDrawItem: 10})
				if not cost.isEnough():
					cost = ObjectCostAux(self.game, {'gold': ConstDefs.draw10GemGoldCostPrice})
				cost.cost(src='draw_gem_gold10')
				ObjectYYHuoDongFactory.onGeneralTask(self.game, TargetDefs.DrawGemGold, 10)
				ObjectYYHuoDongFactory.onGeneralTask(self.game, TargetDefs.DrawGem, 10)
				self.game.achievement.onCount(AchievementDefs.DrawGemGold, 10)

			elif drawType == DrawGemDefs.FreeGold1:
				self.gem_gold_dc1_counter += 1
				self.game.dailyRecord.gem_gold_dc1_free_count += 1
				self.game.dailyRecord.draw_gem += 1
				ObjectYYHuoDongFactory.onGeneralTask(self.game, TargetDefs.DrawGemGold, 1)
				ObjectYYHuoDongFactory.onGeneralTask(self.game, TargetDefs.DrawGem, 1)
				self.game.achievement.onCount(AchievementDefs.DrawGemGold, 1)

		return ObjectDrawGemRandom.getRandomItems(self.game, drawType, drawTimes + 1, _afterGain)

	# 芯片钻石单抽计数器
	chip_rmb_dc1_counter = db_property('chip_rmb_dc1_counter')

	# 芯片钻石10连抽计数器
	chip_rmb_dc10_counter = db_property('chip_rmb_dc10_counter')

	# 芯片道具单抽计数器
	chip_item_dc1_counter = db_property('chip_item_dc1_counter')

	# 芯片道具10连抽计数器
	chip_item_dc10_counter = db_property('chip_item_dc10_counter')

	def drawChip(self, drawType, chooses):
		drawTimes = 0
		if drawType == DrawChipDefs.RMB1:
			drawTimes = self.chip_rmb_dc1_counter
			if self.game.items.getItemCount(DrawChipDefs.RMBDrawItem) < 1:
				if self.game.role.rmb < ConstDefs.drawChipCostPrice:
					raise ClientError(ErrDefs.drawChipRMBNotEnough)
			if self.game.dailyRecord.draw_chip_rmb + 1 > self.game.role.rmbDrawChipCountLimit:
				raise ClientError(ErrDefs.rmbDrawChipLimitUp)

		elif drawType == DrawChipDefs.RMB10:
			drawTimes = self.chip_rmb_dc10_counter
			if self.game.items.getItemCount(DrawChipDefs.RMBDrawItem) < 10:
				if self.game.role.rmb < ConstDefs.draw10ChipCostPrice:
					raise ClientError(ErrDefs.drawChipRMBNotEnough)
			if self.game.dailyRecord.draw_chip_rmb + 10 > self.game.role.rmbDrawChipCountLimit:
				raise ClientError(ErrDefs.rmbDrawChipLimitUp)

		elif drawType == DrawChipDefs.Free1:
			drawTimes = self.chip_rmb_dc1_counter
			if self.game.dailyRecord.chip_rmb_dc1_free_count > 0:
				raise ClientError(ErrDefs.freeDrawTimerNoCD)

		elif drawType == DrawChipDefs.Item1:
			drawTimes = self.chip_item_dc1_counter
			if self.game.items.getItemCount(DrawChipDefs.DrawItem) < ConstDefs.drawChipItemCostPrice:
				raise ClientError('draw item cost not enough')

		elif drawType == DrawChipDefs.Item10:
			drawTimes = self.chip_item_dc10_counter
			if self.game.items.getItemCount(DrawChipDefs.DrawItem) < ConstDefs.draw10ChipItemCostPrice:
				raise ClientError('draw item cost not enough')
			if self.game.dailyRecord.draw_chip_item + 10 > self.game.role.itemDrawChipCountLimit:
				raise ClientError('item draw limit up')

		elif drawType == DrawChipDefs.FreeItem1:
			drawTimes = self.chip_item_dc1_counter
			if self.game.dailyRecord.chip_item_dc1_free_count > 0:
				raise ClientError(ErrDefs.freeDrawTimerNoCD)

		def _afterGain():
			if drawType == DrawChipDefs.RMB1:
				self.chip_rmb_dc1_counter += 1
				self.game.dailyRecord.draw_chip_rmb += 1
				self.game.dailyRecord.draw_chip += 1
				cost = ObjectCostAux(self.game, {DrawChipDefs.RMBDrawItem: 1})
				if not cost.isEnough():  # 代金券不足则用钻石
					cost = ObjectCostAux(self.game, {'rmb': ConstDefs.drawChipCostPrice})
				cost.cost(src='draw_chip_rmb1')
				ObjectYYHuoDongFactory.onGeneralTask(self.game, TargetDefs.DrawChipRMB, 1)
				ObjectYYHuoDongFactory.onGeneralTask(self.game, TargetDefs.DrawChip, 1)
				self.game.achievement.onCount(AchievementDefs.DrawChipRMB, 1)

			elif drawType == DrawChipDefs.RMB10:
				self.chip_rmb_dc10_counter += 1
				self.game.dailyRecord.draw_chip_rmb += 10
				self.game.dailyRecord.draw_chip += 10
				cost = ObjectCostAux(self.game, {DrawChipDefs.RMBDrawItem: 10})
				if not cost.isEnough():
					cost = ObjectCostAux(self.game, {'rmb': ConstDefs.draw10ChipCostPrice})
				cost.cost(src='draw_chip_rmb10')
				ObjectYYHuoDongFactory.onGeneralTask(self.game, TargetDefs.DrawChipRMB, 10)
				ObjectYYHuoDongFactory.onGeneralTask(self.game, TargetDefs.DrawChip, 10)
				self.game.achievement.onCount(AchievementDefs.DrawChipRMB, 10)

			elif drawType == DrawChipDefs.Free1:
				self.chip_rmb_dc1_counter += 1
				self.game.dailyRecord.chip_rmb_dc1_free_count += 1
				self.game.dailyRecord.draw_chip += 1
				ObjectYYHuoDongFactory.onGeneralTask(self.game, TargetDefs.DrawChipRMB, 1)
				ObjectYYHuoDongFactory.onGeneralTask(self.game, TargetDefs.DrawChip, 1)
				self.game.achievement.onCount(AchievementDefs.DrawChipRMB, 1)

			elif drawType == DrawChipDefs.Item1:
				self.chip_item_dc1_counter += 1
				self.game.dailyRecord.draw_chip_item += 1
				self.game.dailyRecord.draw_chip += 1
				cost = ObjectCostAux(self.game, {DrawChipDefs.DrawItem: ConstDefs.drawChipItemCostPrice})
				cost.cost(src='draw_chip_item1')
				ObjectYYHuoDongFactory.onGeneralTask(self.game, TargetDefs.DrawChipItem, 1)
				ObjectYYHuoDongFactory.onGeneralTask(self.game, TargetDefs.DrawChip, 1)
				self.game.achievement.onCount(AchievementDefs.DrawChipItem, 1)

			elif drawType == DrawChipDefs.Item10:
				self.chip_item_dc10_counter += 1
				self.game.dailyRecord.draw_chip_item += 10
				self.game.dailyRecord.draw_chip += 10
				cost = ObjectCostAux(self.game, {DrawChipDefs.DrawItem: ConstDefs.draw10ChipItemCostPrice})
				cost.cost(src='draw_chip_item10')
				ObjectYYHuoDongFactory.onGeneralTask(self.game, TargetDefs.DrawChipItem, 10)
				ObjectYYHuoDongFactory.onGeneralTask(self.game, TargetDefs.DrawChip, 10)
				self.game.achievement.onCount(AchievementDefs.DrawChipItem, 10)

			elif drawType == DrawChipDefs.FreeItem1:
				self.chip_item_dc1_counter += 1
				self.game.dailyRecord.chip_item_dc1_free_count += 1
				self.game.dailyRecord.draw_chip += 1
				ObjectYYHuoDongFactory.onGeneralTask(self.game, TargetDefs.DrawChipItem, 1)
				ObjectYYHuoDongFactory.onGeneralTask(self.game, TargetDefs.DrawChip, 1)
				self.game.achievement.onCount(AchievementDefs.DrawChipItem, 1)

		return ObjectDrawChipRandom.getRandomItems(self.game, drawType, drawTimes + 1, _afterGain, chooses)

	# 自选限定抽卡单抽
	draw_card_up1_counters = db_property('draw_card_up1_counters')

	# 自选限定抽卡10连抽
	draw_card_up10_counters = db_property('draw_card_up10_counters')

	# 自选限定抽卡选择up
	draw_card_up_choose = db_property('draw_card_up_choose')

	def drawCardGroupUp(self, drawType, choose):
		if choose in csv.draw_card_up_group:
			if self.draw_card_up_choose == 0:
				self.draw_card_up_choose = choose
			elif self.draw_card_up_choose and choose != self.draw_card_up_choose:
				raise ClientError('choose error')
		else:
			raise ClientError('choose not in csv')

		drawTimes = 0
		if drawType == DrawCardDefs.GroupUpRMB1:
			drawTimes = self.draw_card_up1_counters.get(choose, 0)
			if self.game.items.getItemCount(DrawCardDefs.LimitUpDrawItem) < 1:
				if self.game.role.rmb < ConstDefs.drawCardUp1CostPrice:
					raise ClientError(ErrDefs.drawCardRMBNotEnough)

		elif drawType == DrawCardDefs.GroupUpRMB10:
			drawTimes = self.draw_card_up10_counters.get(choose, 0)
			if self.game.items.getItemCount(DrawCardDefs.LimitUpDrawItem) < 10:
				if self.game.role.rmb < ConstDefs.drawCardUp10CostPrice:
					raise ClientError(ErrDefs.drawCardRMBNotEnough)

		def _afterGain():
			if drawType == DrawCardDefs.GroupUpRMB1:
				self.draw_card_up1_counters[choose] = self.draw_card_up1_counters.get(choose, 0) + 1
				cost = ObjectCostAux(self.game, {DrawCardDefs.LimitUpDrawItem: 1})
				if not cost.isEnough():
					cost = ObjectCostAux(self.game, {'rmb': ConstDefs.drawCardUp1CostPrice})
				cost.cost(src='draw_card_%s' % drawType)
				ObjectYYHuoDongFactory.onGeneralTask(self.game, TargetDefs.DrawCardUp, 1)
				ObjectYYHuoDongFactory.onGeneralTask(self.game, TargetDefs.DrawCardUpAndRMB, 1)

			elif drawType == DrawCardDefs.GroupUpRMB10:
				self.draw_card_up10_counters[choose] = self.draw_card_up10_counters.get(choose, 0) + 1
				cost = ObjectCostAux(self.game, {DrawCardDefs.LimitUpDrawItem: 10})
				if not cost.isEnough():
					cost = ObjectCostAux(self.game, {'rmb': ConstDefs.drawCardUp10CostPrice})
				cost.cost(src='draw_card_%s' % drawType)
				ObjectYYHuoDongFactory.onGeneralTask(self.game, TargetDefs.DrawCardUp, 10)
				ObjectYYHuoDongFactory.onGeneralTask(self.game, TargetDefs.DrawCardUpAndRMB, 10)

		return ObjectDrawCardRandom.getRandomItems(self.game, DrawCardDefs.LimitDrawRandomKey(drawType, choose), drawTimes + 1, _afterGain)

	def drawCounterSum(self, drawType):
		if drawType == DrawSumBoxDefs.RMBType:
			return self.dc1_counter + self.dc10_counter * 10
		elif drawType == DrawSumBoxDefs.GoldType:
			return self.dc1_gold_counter + self.dc10_gold_counter * 10
		elif drawType == DrawSumBoxDefs.EquipType:
			return self.eq_dc1_counter + self.eq_dc10_counter * 10
		elif drawType == DrawSumBoxDefs.LimitUpDrawType:
			count = 0
			for _, v in self.draw_card_up1_counters.iteritems():
				count += v
			for _, v in self.draw_card_up10_counters.iteritems():
				count = count + v*10
			return count + self.yyhuodong_counters.get(YYHuoDongDefs.TimeLimitUpDraw, 0)
		elif drawType == DrawSumBoxDefs.ChipType:
			return self.chip_rmb_dc1_counter + self.chip_rmb_dc10_counter * 10
		else:
			raise ClientError('drawType error')

	# 运营活动相关抽卡计数器
	yyhuodong_counters = db_property('yyhuodong_counters')

	# 掉落库权值浮动 {key:{csvID:weight}}
	lib_weight_info = db_property('lib_weight_info')

	# 掉落库生效次数 {key:{csvID:count}}
	lib_effect_info = db_property('lib_effect_info')

	# 抽取芯片掉落库生效次数
	draw_chip_lib_counter = db_property('draw_chip_lib_counter')
