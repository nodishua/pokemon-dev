#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2014 YouMi Information Technology Inc.
'''

from game.object import TargetDefs

def predGen(t, p, sp):
	# 角色等级
	if t == TargetDefs.Level:
		return (t, lambda g, _: g.role.level >= p)

	# 通过章节关卡
	elif t == TargetDefs.Gate:
		return (t, lambda g, _: g.role.getGateStar(p) > 0)

	# 拥有卡牌数量
	elif t == TargetDefs.CardsTotal:
		return (t, lambda g, _: len(g.role.cards) >= p)

	# 达到vip等级
	elif t == TargetDefs.Vip:
		return (t, lambda g, _: g.role.vip_level >= p)

	# 卡牌获得总次数
	elif t == TargetDefs.CardGainTotalTimes:
		return (t, lambda g, _: g.role.card_gain_times >= p)

	# 战力达到多少
	elif t == TargetDefs.FightingPoint:
		return (t, lambda g, _: g.role.battle_fighting_point >= p)

	# TOP6战力达到多少
	elif t == TargetDefs.Top6FightingPoint:
		return (t, lambda g, _: g.role.top6_fighting_point >= p)

	# 卡牌进阶总次数
	elif t == TargetDefs.CardAdvanceTotalTimes:
		return (t, lambda g, _: g.role.card_advance_times >= p)

	# 副本总星数（主线，精英，噩梦）
	elif t == TargetDefs.GateStar:
		return (t, lambda g, _: g.role.gateStarSum >= p)

	# 拥有某品质卡牌的数量
	elif t == TargetDefs.CardAdvanceCount:
		if isinstance(sp, dict):
			num, adv = sp.items()[0]
		else:
			num, adv = sp, p
		return (t, lambda g, _: g.cards.countAdvanceCards(adv) >= num)

	# 拥有某星数卡牌的数量
	elif t == TargetDefs.CardStarCount:
		if isinstance(sp, dict):
			num, star = sp.items()[0]
		else:
			num, adv = sp, p
		return (t, lambda g, _: g.cards.countStarCards(star) >= num)

	# 拥有某品质饰品的数量
	elif t == TargetDefs.EquipAdvanceCount:
		if isinstance(sp, dict):
			num, adv = sp.items()[0]
		else:
			num, adv = sp, p
		return (t, lambda g, _: g.cards.countAdvanceEquips(adv) >= num)

	# 拥有某星数饰品的数量
	elif t == TargetDefs.EquipStarCount:
		if isinstance(sp, dict):
			num, star = sp.items()[0]
		else:
			num, adv = sp, p
		return (t, lambda g, _: g.cards.countStarEquips(star) >= num)

	# 拥有某卡牌
	elif t == TargetDefs.HadCard:
		return (t, lambda g, _: g.cards.isExistedByCsvID(p))

	# 获得某卡牌系列的次数
	elif t == TargetDefs.GainCardTimes:
		# TODO:
		pass

	# 激活即完成（上线即完成）
	elif t == TargetDefs.CompleteImmediate:
		return (t, lambda g, _: True)

	# 竞技场排名
	elif t == TargetDefs.ArenaRank:
		return (t, lambda g, _: g.role.pvp_record_db_id and 0 < g.role.pw_rank <= p)

	# 解锁图鉴数量
	elif t == TargetDefs.UnlockPokedex:
		return (t, lambda g, _: len(g.role.pokedex) >= p)

	# 无尽之塔通关第XX关 (配置关卡ID)
	elif t == TargetDefs.EndlessPassed:
		return (t, lambda g, _: g.role.endless_tower_max_gate >= p)

	# 好友数量
	elif t == TargetDefs.Friends:
		return (t, lambda g, _: len(g.society.friends) >= p)

	# 训练家等级
	elif t == TargetDefs.TrainerLevel:
		return (t, lambda g, _: g.role.trainer_level >= p)

	# 捕捉等级
	elif t == TargetDefs.CaptureLevel:
		return (t, lambda g, _: g.capture.level >= p)

	# 累计捕捉成功的次数
	elif t == TargetDefs.CaptureSuccessSum:
		return (t, lambda g, _: g.capture.success_sum >= p)

	# 激活的探险器数量
	elif t == TargetDefs.Explorer:
		return (t, lambda g, _: g.explorer.countActiveExplorers() >= p)

	# 随机试炼当日积分
	elif t == TargetDefs.RandomTowerPointDaily:
		return (t, lambda g, _: g.randomTower.day_point >= p)

	# 完成指定稀有度的派遣任务次数
	elif t == TargetDefs.DispatchTaskQualityDone:
		if isinstance(sp, dict):
			num, quality = sp.items()[0]
		else:
			num, quality = sp, p
		return (t, lambda g, v: v >= num)

	# 其它判定直接按计数器来
	return (t, lambda _, v: v >= p)

def dailyCounter(game, t):
	if t == TargetDefs.GateChanllenge:
		return game.dailyRecord.gate_chanllenge

	elif t == TargetDefs.HeroGateChanllenge:
		return game.dailyRecord.hero_gate_chanllenge

	elif t == TargetDefs.HuodongChanllenge:
		# 活动副本总数，统一一个计数器
		return game.dailyRecord.huodong_chanllenge

	elif t == TargetDefs.EndlessChallenge:
		return game.dailyRecord.endless_challenge

	elif t == TargetDefs.ArenaBattle:
		return game.dailyRecord.pvp_pw_times

	elif t == TargetDefs.DrawCard:
		return game.dailyRecord.draw_card

	elif t == TargetDefs.WorldBossBattleTimes:
		return game.dailyRecord.boss_gate

	elif t == TargetDefs.EquipStrength:
		return game.dailyRecord.equip_strength

	elif t == TargetDefs.EquipAdvance:
		return game.dailyRecord.equip_advance

	elif t == TargetDefs.CardSkillUp:
		return game.dailyRecord.skill_up

	elif t == TargetDefs.LianjinTimes:
		return game.dailyRecord.lianjin_times

	elif t == TargetDefs.ShareTimes:
		return game.dailyRecord.share_times

	elif t == TargetDefs.CardAdvance:
		return game.dailyRecord.card_advance_times

	elif t == TargetDefs.BuyStaminaTimes:
		return game.dailyRecord.buy_stamina_times

	elif t == TargetDefs.CostRmb:
		return game.dailyRecord.consume_rmb_sum

	elif t == TargetDefs.CardLevelUp:
		return game.dailyRecord.level_up

	elif t == TargetDefs.CloneBattleTimes:
		return game.dailyRecord.clone_times

	elif t == TargetDefs.NightmareGateChanllenge:
		return game.dailyRecord.nightmare_gate_chanllenge

	elif t == TargetDefs.UnionContrib:
		return game.dailyRecord.union_contrib_times

	elif t == TargetDefs.DrawGem:
		return game.dailyRecord.draw_gem

	elif t == TargetDefs.FishingTimes:
		return game.dailyRecord.fishing_counter

	elif t == TargetDefs.FishingWinTimes:
		return game.dailyRecord.fishing_win_counter

	return None