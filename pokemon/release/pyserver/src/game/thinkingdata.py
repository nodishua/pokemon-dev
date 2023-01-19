#!/usr/bin/python
# -*- coding: utf-8 -*-

from framework import nowdatetime_t
from framework.helper import objectid2string
# from framework.code_coverage import code_coverage, tj_coverage
from game.object import FeatureDefs, ItemDefs
from game.session import Session
from framework.csv import csv, ConstDefs
from framework.log import logger
from game.globaldata import *
import os
from tornado.ioloop import PeriodicCallback
from game.important_data import *

from tgasdk.sdk import TGAnalytics, LoggingConsumer, BatchConsumer, AsyncBatchConsumer
import json

#rarity [3] = "S"	[4] = "S+"	[5] = "SS"
rarityLimit = 3
def pretty_src(src):
	v = src.split('_')
	if v and v[-1].isdigit():
		return '_'.join(v[:-1])
	return src

class TJTA(object):
	def __init__(self):
		# self.ta = TGAnalytics(BatchConsumer(url, appid))
		# self.ta = TGAnalytics(AsyncBatchConsumer(SERVER_URI,APP_ID,flush_size=200,queue_size=100000))
		self.ta = None
		self.periodicTimer = None
		self.itemMap = {} # {pid:{key:(src,type),data:{id:count}}}
		self.eventMap = {} # {(pid,event,carddbid):{id:count}}
		self.randomTowerMap = {} # {pid:{id:count}}
	def init(self, path):
		if not os.path.exists(path):
			os.makedirs(path)
		self.ta = TGAnalytics(LoggingConsumer(path, bufferSize=20))
		logger.info('tjta init, path %s', path)

		self.periodicTimer = PeriodicCallback(self.onPeriodic, 30 * 60 * 1000.)
		self.periodicTimer.start()
	# 用户属性
	def user(self, game, params):
		properties = {}
		if 'login' in params:
			properties.update({
				'role_name': game.role.name,
				'level': game.role.level, # 当前等级
				'fighting_point': game.role.top6_fighting_point, # 当前战力
				'vip_level': game.role.vip_level, # 当前VIP等级
				'current_gold_stock': game.role.gold, # 当前金币存量
				'current_diamond_consumption': game.role.rmb_consume, # 当前钻石消耗量
				'current_diamond_stock': game.role.rmb, # 当前钻石存量
				'friend_number': len(game.society.friends), # 好友数量
				# 'phone_number': game.role.union_db_id, # 手机号
				# 'current_gamelevel': game.role.union_db_id, # 当前停留关卡
				'final_login_time': self.getNnowdatetime(), # 最后一次登陆时间
				'card_number': len(game.role.pokedex), # 精灵解锁数量
				'top12_cards': [v[1] for v in game.role.top12_cards] # top12精灵列表
			})

			heldItems = {}
			for key in game.role.held_items:
				heldItem = game.heldItems.getHeldItem(key)
				if heldItem.quality >= 5: # 橙色
					heldItems[heldItem.held_item_id] = heldItems.get(heldItem.held_item_id, 0) + 1
			properties['held_items'] = json.dumps(heldItems)

			stockData = {}
			# 货币
			for key in stockCoin:
				num = game.role.db.get(key,0)
				if num > 0:
					stockData[key] = num
			# item
			for key in stockItems:
				num = game.role.items.get(key,0)
				if num > 0:
					stockData['item_%s'%key] = num

			properties.update(stockData)

			# 关卡进度
			properties['endless_tower_max_gate'] = game.role.endless_tower_max_gate # 冒险之路最大关卡
			if game.role.gym_fuben:
				properties['gym_last_date'] = game.role.gym_datas.get('last_date', 0)
				for gymid, level in game.role.gym_fuben.iteritems(): # 道馆当前进度
					properties['gym_%d' % gymid] = level

		if 'order_pay' in params:
			totalRechargeTimes = 0
			for rechargeID, d in game.role.recharges.iteritems():
				if rechargeID == FreeVIPRechargeID:
					continue
				if rechargeID not in csv.recharges:
					continue
				totalRechargeTimes += d.get('cnt', 0)
			properties.update({
				'final_recharge_time': self.getNnowdatetime(), # 最后充值时间
				'lastest_recharge_amount': params['recharge_amount'], # 最近充值金额
				'lastest_recharge_id': params['recharge_id'], # 首充商品id
				'lastest_recharge_yy_id': params['yy_id'],
				'lastest_recharge_csv_id': params['csv_id'],
				'total_recharge_times': totalRechargeTimes, # 充值次数
				'total_recharge_amount': game.role.vipSum, # 充值总量
			})
		if 'union' in params:
			properties.update({
				'union_db_id': objectid2string(game.role.union_db_id) if game.role.union_db_id else '', # 加入/退出/创建公会时上报
			})
		if len(properties) > 0:
			try:
				self.ta.user_set(account_id = game.role.pid, properties = properties)
			except Exception as e:
				#异常处理
				logger.info(e)

		# user_setOnce
		properties = {}
		if 'login' in params:
			properties.update({
				# 'reg_time': self.getNnowdatetime(), # 账号注册时间
				'role_create_time': game.role.created_time, # 角色创建时间
				'server_open_time': self.getNnowdatetime(), # 服务器开放时间
				'server_id': Session.server.key, # 服务器id
				# 'server_name': Session.server.servShowName, # 服务器名称
				# 'channel_id': 1, # 渠道id
				'main_account_id': objectid2string(game.role.account_id), # 所属账户
			})
		if 'order_pay' in params:
			properties.update({
				'first_recharge_time': self.getNnowdatetime(), # 首次付费时间
				'first_recharge_amount': params['recharge_amount'], # 首充金额
				'first_recharge_id': params['recharge_id'], # 首充商品id
				'first_recharge_yy_id': params['yy_id'],
				'first_recharge_csv_id': params['csv_id'],
			})
		if len(properties) > 0:
			try:
				self.ta.user_setOnce(account_id = game.role.pid, properties = properties)
			except Exception as e:
				#异常处理
				logger.info(e)

	# 普通事件
	# 登录
	def login(self, game, event, **kwargs):
		self.user(game, {'login'})
		properties = {'#time':self.getNnowdatetime()}
		# 登录的时候记录大于5星的卡牌
		for dbid in game.role.cards:
			card = game.cards.getCard(dbid)
			if card and card.star > 5 and (card.card_id in importantCards or card.rarity >= rarityLimit):
				oldStar = properties.get('card_%s'%card.card_id)
				if not oldStar or (oldStar and oldStar < card.star):
					properties['card_%s'%card.card_id] = card.star
		self.ta.track(account_id=game.role.pid, event_name=event, properties=properties)

	# 用户注册
	def register(self, game, event, **kwargs):
		self.ta.track(account_id=game.role.pid, event_name=event, properties={'#time':self.getNnowdatetime(),'card_id':kwargs.get('card_id',None)})

	# 新手引导事件	用户进行新手引导
	def guide(self, game, event, **kwargs):
		self.ta.track(account_id=game.role.pid, event_name=event, properties={'#time':self.getNnowdatetime(),'guide_id':kwargs.get('guide_id',None)})

	# 升级日志	用户升级	用户升级后	previous_level	升级前等级	数值
	def levelUp(self, game, event, **kwargs):
		self.ta.track(account_id=game.role.pid, event_name=event, properties={'#time':self.getNnowdatetime(),'level':game.role.level})

	# vip_levelup	VIP升级日志	vip用户升级	用户升级后	previous_level	升级前等级	数值
	def vipLevelUp(self, game, event, **kwargs):
		self.ta.track(account_id=game.role.pid, event_name=event, properties={'#time':self.getNnowdatetime(),'vip_level':game.role.vip_level})

	# 货币和item
	# @tj_coverage
	def good(self, game, eff, **kwargs):
		if not self.ta:
			return

		from game.object.game.gain import ObjectGainAux, ObjectCostAux
		from game.object.game.item import ObjectItemEffect
		from game.object.game.frag import FragEffect
		try:
			src = kwargs.get('src','')
			src = pretty_src(src)
			yyID = kwargs.get('yy_id',None)
			if isinstance(eff, ObjectGainAux):
				self.preTrack(game.role.pid, src, 'gain', yyID)
				if eff.gold > 0:
					self.itemCount(game.role.pid,'gold',eff.gold)
				if eff.rmb > 0:
					self.itemCount(game.role.pid,'rmb',eff.rmb)
				if eff.recharge_rmb > 0:
					self.itemCount(game.role.pid,'rmb',eff.recharge_rmb)
				if eff._stamina > 0:
					self.itemCount(game.role.pid,'stamina',eff._stamina)
				if eff._skill_point > 0:
					self.itemCount(game.role.pid,'skill_point',eff._skill_point)
				if eff._coin1 > 0:
					self.itemCount(game.role.pid,'coin1',eff._coin1)
				if eff._coin2 > 0:
					self.itemCount(game.role.pid,'coin2',eff._coin2)
				if eff._coin3 > 0:
					self.itemCount(game.role.pid,'coin3',eff._coin3)
				if eff._coin4 > 0:
					self.itemCount(game.role.pid,'coin4',eff._coin4)
				if eff._coin5 > 0:
					self.itemCount(game.role.pid,'coin5',eff._coin5)
				if eff._coin6 > 0:
					self.itemCount(game.role.pid,'coin6',eff._coin6)
				if eff._coin7 > 0:
					self.itemCount(game.role.pid,'coin7',eff._coin7)
				if eff._coin8 > 0:
					self.itemCount(game.role.pid,'coin8',eff._coin8)
				if eff._coin9 > 0:
					self.itemCount(game.role.pid,'coin9',eff._coin9)
				if eff._coin10 > 0:
					self.itemCount(game.role.pid,'coin10',eff._coin10)
				if eff._coin11 > 0:
					self.itemCount(game.role.pid,'coin11',eff._coin11)
				if eff._coin12 > 0:
					self.itemCount(game.role.pid,'coin12',eff._coin12)
				if eff._talent_point > 0:
					self.itemCount(game.role.pid,'talent_point',eff._talent_point)
				if eff._gym_talent_point > 0:
					self.itemCount(game.role.pid,'gym_talent_point',eff._gym_talent_point)
				for itemID, count in eff.items.iteritems():
					self.itemCount(game.role.pid,'item_%d' % itemID,count)
				for card in eff.cards:
					self.itemCount(game.role.pid,'card_%d' % card['id'],1)
				for fragID, count in eff._fragsD.iteritems():
					self.itemCount(game.role.pid,'frag_%d' % fragID,count)
				for gemID in eff.gemIDs:
					self.itemCount(game.role.pid,'gem_%d' % gemID,1)
				for heldItemID in eff.heldItemIDs:
					self.itemCount(game.role.pid,'heldItem_%d' % heldItemID,1)
			elif isinstance(eff, ObjectCostAux):
				self.preTrack(game.role.pid, src, 'cost', yyID)
				if eff.gold > 0:
					self.itemCount(game.role.pid,'gold',eff.gold)
				if eff.rmb > 0:
					self.itemCount(game.role.pid,'rmb',eff.rmb)
				if eff._coin1 > 0:
					self.itemCount(game.role.pid,'coin1',eff._coin1)
				if eff._coin2 > 0:
					self.itemCount(game.role.pid,'coin2',eff._coin2)
				if eff._coin3 > 0:
					self.itemCount(game.role.pid,'coin3',eff._coin3)
				if eff._coin4 > 0:
					self.itemCount(game.role.pid,'coin4',eff._coin4)
				if eff._coin5 > 0:
					self.itemCount(game.role.pid,'coin5',eff._coin5)
				if eff._coin6 > 0:
					self.itemCount(game.role.pid,'coin6',eff._coin6)
				if eff._coin7 > 0:
					self.itemCount(game.role.pid,'coin7',eff._coin7)
				if eff._coin8 > 0:
					self.itemCount(game.role.pid,'coin8',eff._coin8)
				if eff._coin9 > 0:
					self.itemCount(game.role.pid,'coin9',eff._coin9)
				if eff._coin10 > 0:
					self.itemCount(game.role.pid,'coin10',eff._coin10)
				if eff._coin11 > 0:
					self.itemCount(game.role.pid,'coin11',eff._coin11)
				if eff._coin12 > 0:
					self.itemCount(game.role.pid,'coin12',eff._coin12)
				for itemID, count in eff.items.iteritems():
					self.itemCount(game.role.pid,'item_%d' % itemID,count)
				if eff._cards:
					for card in eff._cards:
						self.itemCount(game.role.pid,'card_%d' % card.card_id,1)
				if eff._gems:
					for gem in eff._gems:
						self.itemCount(game.role.pid,'gem_%d' % gem.gem_id,1)
				if eff._heldItems:
					for heldItem in eff._heldItems:
						self.itemCount(game.role.pid,'heldItem_%d' % heldItem.held_item_id,1)
			elif isinstance(eff, ObjectItemEffect):
				self.preTrack(game.role.pid, src, 'cost', yyID)
				self.itemCount(game.role.pid,'item_%d' % eff.itemID,eff.count)
			elif isinstance(eff, FragEffect):
				self.decrease(game.role.pid, {'reasons_str': src, 'yy_id':yyID, 'frag_%d' % eff._fragID:eff._combCount})
		except Exception as e:
			#异常处理
			logger.info(e)

	def preTrack(self, pid, src, typ, yyID):
		if pid not in self.itemMap:
			self.itemMap[pid] = {'key':(src,typ), 'data':{'yy_id':yyID, 'reasons_str':src}, 'time': self.getNnowdatetime()}
		elif self.itemMap[pid]['key'] != (src,typ):
			if self.itemMap[pid]['data'] > 2:
				if self.itemMap[pid]['key'][1] == 'gain':
					self.increase(pid, self.itemMap[pid]['data'], self.itemMap[pid]['time'])
				else:
					self.decrease(pid, self.itemMap[pid]['data'], self.itemMap[pid]['time'])
			self.itemMap[pid] = {'key':(src,typ), 'data':{'yy_id':yyID, 'reasons_str':src}, 'time': self.getNnowdatetime()}

	def onShutdown(self):
		if not self.ta:
			return
		try:
			self.onPeriodic()
			for pid,v in self.itemMap.iteritems():
				if v['data'] > 2:
					if v['key'][1] == 'gain':
						self.increase(pid, v['data'], v['time'])
					if v['key'][1] == 'cost':
						self.decrease(pid, v['data'], v['time'])
			self.ta.flush()
		except Exception as e:
			#异常处理
			logger.info(e)

	def itemCount(self, pid, key, count):
		arrs = key.split('_')
		if arrs[0] == 'card':
			cardID = int(arrs[1])
			unitID = csv.cards[cardID].unitID
			rarity = csv.unit[unitID].rarity
			if not (cardID in importantCards or rarity >= rarityLimit):
				return
		elif arrs[0] == 'frag':
			cardID = csv.fragments[int(arrs[1])].combID
			unitID = csv.cards[cardID].unitID
			rarity = csv.unit[unitID].rarity
			if not (cardID in importantCards or rarity >= rarityLimit):
				return
		elif arrs[0] == 'gem' and csv.gem.gem[int(arrs[1])].quality < 4:
			return
		elif arrs[0] == 'heldItem' and csv.held_item.items[int(arrs[1])].quality < 4:
			return
		elif arrs[0] == 'item' and int(arrs[1]) not in importantItems:
			return
		self.itemMap[pid]['data'][key] = self.itemMap[pid]['data'].get(key, 0) + count

	def increase(self, pid, properties, time=None):
		if not time:
			time = self.getNnowdatetime()
		properties.update({'#time':time})
		self.ta.track(account_id=pid, event_name="increase", properties=properties)

	def decrease(self, pid, properties, time=None):
		if not time:
			time = self.getNnowdatetime()
		properties.update({'#time':time})
		self.ta.track(account_id=pid, event_name="decrease", properties=properties)

	# self.eventMap = {(pid,event,carddbid):{id:count}}
	def onPeriodic(self):
		for key,data in self.eventMap.iteritems():
			try:
				self.ta.track(account_id=key[0], event_name=key[1], properties=data)
			except Exception as e:
				#异常处理
				logger.info(e)
		self.eventMap = {}

	# 付费相关
	def orderPay(self, game, event, **kwargs):
		rechargeID = kwargs['recharge_id']
		increaseNumber = kwargs['increase_number']
		cfg = csv.recharges[rechargeID]
		properties = {
			'recharge_amount':cfg.rmb,
			'recharge_id':rechargeID,
			'yy_id':kwargs['yy_id'],
			'csv_id':kwargs['csv_id'],
			'gain_rmb':increaseNumber,
			'channel': kwargs['channel'],
			'#time':self.getNnowdatetime()
		}
		self.ta.track(account_id=game.role.pid, event_name=event, properties=properties)
		if increaseNumber > 0:
			self.increase(game.role.pid, {
				'rmb':increaseNumber, # 增加的数量
				'reasons_str':'充值', # 变化原因
				'yy_id':kwargs['yy_id']
			})
			properties.update({'order_pay':True})
			self.user(game, properties)

	# 卡牌养成相关
	def cardLevelUp(self, card, event, **kwargs):
		# if card.id not in card.game.cards.top20Cards:
		# 	return
		# card_level_up	精灵升级
		pid = card.game.role.pid
		key = (pid,event,card.id)
		if not self.eventMap.get(key,False):
			self.eventMap[key] = {}
		self.eventMap[key].update({
			'card_id': card.card_id,# 精灵id
			'current_level': card.level,# 当前等级
			'current_fighting_point': card.fighting_point,# 当前战力
			'#time':self.getNnowdatetime()
		})
		addLevel = kwargs.get('addLevel', 1) + self.eventMap[key].get('promote_level',0)
		addFightingPoint = kwargs.get('addFightingPoint', 0) + self.eventMap[key].get('promote_fighting_point',0)
		self.eventMap[key]['promote_level'] = addLevel
		self.eventMap[key]['promote_fighting_point'] = addFightingPoint

	def cardStarUp(self, card, event, **kwargs):
		# card_star_up	精灵升星
		if card.star <= 5:
			return
		properties = {
			'card_id': card.card_id,# 精灵id
			'current_star': card.star,# 当前星级
			'promote_fighting_point': kwargs.get('addFightingPoint', 0),# 升战力
			'current_fighting_point': card.fighting_point,# 当前战力
			'#time':self.getNnowdatetime()
		}
		self.ta.track(account_id=card.game.role.pid, event_name=event, properties=properties)

	def cardAdvanceUp(self, card, event, **kwargs):
		# card_advance_up 精灵突破等级提升
		properties = {
			'card_id': card.card_id,# 精灵id
			'current_advance': card.advance,# 当前突破等级
			'promote_advance': kwargs.get('addAdvance', 0),# 提升突破等级
			'promote_fighting_point': kwargs.get('addFightingPoint', 0),# 提升战力
			'current_fighting_point': card.fighting_point,# 当前战力
			'#time':self.getNnowdatetime()
		}
		self.ta.track(account_id=card.game.role.pid, event_name=event, properties=properties)

	def cardSkillLevelUp(self, card, event, **kwargs):
		# if card.id not in card.game.cards.top20Cards:
		# 	return
		# card_skill_level_up 精灵技能等级提升
		skillID = kwargs.get('skill_id', 0)
		pid = card.game.role.pid
		key = (pid,event,card.id,skillID)
		if not self.eventMap.get(key,False):
			self.eventMap[key] = {}
		self.eventMap[key].update({
			'card_id': card.card_id,# 精灵id
			'skill_id':  skillID,# 技能id
			'current_skill_level':  kwargs.get('skill_level', 0),# 当前技能等级
			'current_fighting_point': card.fighting_point,# 当前战力
			'#time':self.getNnowdatetime()
		})
		addFightingPoint = kwargs.get('addFightingPoint', 0) + self.eventMap[key].get('promote_fighting_point',0)
		self.eventMap[key]['promote_fighting_point'] = addFightingPoint

	def effortTrain(self, card, event, **kwargs):
		# if card.id not in card.game.cards.top20Cards:
		# 	return
		# card_effort_train 精灵努力值提升
		currentCultivate = 0
		oldCultivate = 0
		for k,v in card.effort_values.iteritems():
			currentCultivate += v
		oldValues = kwargs.get("oldValues")
		for v in oldValues:
			oldCultivate += v
		properties = {
			'card_id': card.card_id,# 精灵id
			'train_type': card.effortTypeMap['trainType'],# 培养类型
			'train_times': card.effortTypeMap['trainTime'],# 消耗货币数量
			'promote_cultivate': currentCultivate-oldCultivate,# 提升培养总值
			'current_cultivate': currentCultivate,# 当前培养总值
			'current_advance': card.effort_advance,# 当前阶段
			'advance_up_or_not': card.isEnoughEffortAdvance(card.effort_advance),# 是否升阶
			'promote_fighting_point': card.fighting_point-kwargs.get("oldFightingPoint"),# 提升宝可梦战力
			'current_fighting_point': card.fighting_point,# 当前宝可梦战力
			'#time':self.getNnowdatetime()
		}
		self.ta.track(account_id=card.game.role.pid, event_name=event, properties=properties)

	def nvalue(self, card, event, **kwargs):
		# nvalue 精灵个体值提升
		cost = kwargs.get('cost')
		oldFightingPoint = kwargs.get('oldFightingPoint',0)
		properties = {
			'card_id': card.card_id,# 精灵id
			'defence': card.nvalue['defence'],# 当前生命值
			'specialDefence': card.nvalue['specialDefence'],# 当前速度值
			'hp': card.nvalue['hp'],# 当前物攻值
			'specialDamage': card.nvalue['specialDamage'],# 当前物防值
			'speed': card.nvalue['speed'],# 当前特攻值
			'damage': card.nvalue['damage'],# 当前特防值
			'cost_rmb': cost.rmb,# 消耗钻石数
			'cost_gold': cost.gold,# 消耗金币
			'cost_capsule_number': cost.items.get(19,0),# 消耗胶囊
			'current_capsule_number': card.game.role.items.get(19,0),# 当前胶囊存量
			'promote_fighting_point': card.fighting_point - oldFightingPoint,# 提升宝可梦战力
			'current_fighting_point': card.fighting_point,# 当前宝可梦战力
			'#time':self.getNnowdatetime()
		}
		self.ta.track(account_id=card.game.role.pid, event_name=event, properties=properties)

	def ability(self, card, event, **kwargs):
		# ability 精灵潜能激活
		oldFightingPoint = kwargs.get('oldFightingPoint',0)
		position = kwargs.get('position', 1)
		cfg = card.CardAbilityMap[(card.abilitySeqID, position)]
		strengthCostSeq = cfg['strengthSeqID']
		level = card.abilities.get(position, 0)
		properties = {
			'card_id': card.card_id,# 精灵id
			'ability_id': position,# 潜能id
			'current_ability_level': level,# 当前潜能等级
			'promote_fighting_point': card.fighting_point - oldFightingPoint,# 提升宝可梦战力
			'current_fighting_point': card.fighting_point,# 当前宝可梦战力
			'#time':self.getNnowdatetime()
		}
		self.ta.track(account_id=card.game.role.pid, event_name=event, properties=properties)

	def cardStarLevelUp(self, card, event, **kwargs):
		# card_ultimate_property_up	精灵极限属性提升
		oldFightingPoint = kwargs.get('oldFightingPoint',0)
		properties = {
			'card_id': card.card_id,# 精灵id
			'card_star_skill_id': kwargs.get('skillID', 0),# 属性id
			'card_star_skill_level': kwargs.get('level', 0),# 当前属性等级
			'cost_ultimate_point': kwargs.get('costNum', 0),# 极限点消耗
			'current_ultimate_point': card.game.role.star_skill_points.get(card.markID,0),# 当前极限点剩余
			'promote_fighting_point': card.fighting_point - oldFightingPoint,# 提升宝可梦战力
			'current_fighting_point': card.fighting_point,# 当前宝可梦战力
			'#time':self.getNnowdatetime()
		}
		self.ta.track(account_id=card.game.role.pid, event_name=event, properties=properties)

	def cardFeelLevelUp(self, card, event, **kwargs):
		# card_feel_level_up 精灵好感度等级提升
		markID = kwargs.get('mark_id', 0)
		pid = card.game.role.pid
		key = (pid,event,markID)
		if not self.eventMap.get(key,False):
			self.eventMap[key] = {}
		self.eventMap[key].update({
			'card_id': markID,# 精灵id
			'current_feel_level': kwargs.get('level', 0),# 当前好感度等级
			'#time':self.getNnowdatetime()
		})
		addLevel = kwargs.get('addLevel', 0) + self.eventMap[key].get('promote_feel_level',0)
		self.eventMap[key]['promote_feel_level'] = addLevel

	def cardCharacterSwap(self, card, event, **kwargs):
		# card_character_swap 精灵性格交换
		oldFightingPoint = kwargs.get('oldFightingPoint',0)
		properties = {
			'card_id': card.card_id,# 精灵id
			'target_card_id': kwargs.get('target_card_id'),# 交换目标id
			'swap_type': kwargs.get('swap_type'),# 交换类型
			'previous_character': kwargs.get('previous_character'),# 之前的性格
			'current_character': card.character,# 当前的性格
			'promote_fighting_point': card.fighting_point - oldFightingPoint,# 提升宝可梦战力
			'current_fighting_point': card.fighting_point,# 当前宝可梦战力
			'#time':self.getNnowdatetime()
		}
		self.ta.track(account_id=card.game.role.pid, event_name=event, properties=properties)

	def cardGem(self, card, event, **kwargs):
		# card_gem 符石装备变动
		oldFightingPoint = kwargs.get('oldFightingPoint',0)
		idList = []
		levelList = []
		gems = card.game.gems.getGems(card.gems.values())
		for gem in gems:
			idList.append(gem.gem_id)
			levelList.append(gem.level)

		properties = {
			'card_id': card.card_id,# 精灵id
			'gem_equip_type': kwargs.get('gem_equip_type'),# 装备类型
			# 'current_gem_point': equip.equip_id,# 当前符石指数
			'current_gem_id_list': idList,# 当前符石id列表
			'current_gem_level_list': levelList,# 当前符石等级列表
			'promote_fighting_point': card.fighting_point - oldFightingPoint,# 提升宝可梦战力
			'current_fighting_point': card.fighting_point,# 当前宝可梦战力
			'#time':self.getNnowdatetime()
		}
		self.ta.track(account_id=card.game.role.pid, event_name=event, properties=properties)
	# 饰品相关
	def cardEquipLevelUp(self, equip, event, **kwargs):
		# if equip.card.id not in equip.card.game.cards.top20Cards:
		# 	return
		# card_equip_level_up 精灵饰品强化
		pid = equip.game.role.pid
		key = (pid,event,equip.card.card_id,equip.equip_id)
		if not self.eventMap.get(key,False):
			self.eventMap[key] = {}
		self.eventMap[key].update({
			'card_id': equip.card.card_id,# 精灵id
			'equip_id': equip.equip_id,# 首饰id
			'current_equip_level': equip.level,# 当前饰品等级
			'current_quality': equip.advance,# 当前品质
			'current_fighting_point': equip.card.fighting_point,# 当前战力
			'#time':self.getNnowdatetime()
		})
		addLevel = kwargs.get('addLevel', 0) + self.eventMap[key].get('promote_equip_level',0)
		self.eventMap[key]['promote_equip_level'] = addLevel

	def cardEquipStarUp(self, equip, event, **kwargs):
		# card_equip_star_up 精灵饰品升星
		properties = {
			'card_id': equip.card.card_id,# 精灵id
			'equip_id': equip.equip_id,# 首饰id
			'current_equip_star_level': equip.star,# 当前首饰星级
			'promote_fighting_point': kwargs.get('addFightingPoint', 0),# 提升战力
			'current_fighting_point': equip.card.fighting_point,# 当前战力
			'#time':self.getNnowdatetime()
		}
		self.ta.track(account_id=equip.game.role.pid, event_name=event, properties=properties)

	def cardEquipStarDown(self, equip, event, **kwargs):
		# card_equip_star_down 精灵饰品降星
		properties = {
			'card_id': equip.card.card_id,# 精灵id
			'equip_id': equip.equip_id,# 首饰id
			# 'get_star_stone_number': kwargs,# 获得星石
			# 'get_gold': kwargs.get('gold', 0),# 获得金钱
			'current_fighting_point': equip.card.fighting_point,# 当前战力
			# 'current_star_stone_number': kwargs,# 当前星石存量
			'#time':self.getNnowdatetime()
		}
		self.ta.track(account_id=equip.game.role.pid, event_name=event, properties=properties)

	def cardEquipAwakeUp(self, equip, event, **kwargs):
		# card_equip_awake_up 精灵饰品升阶
		oldFightingPoint = kwargs.get('oldFightingPoint',0)
		properties = {
			'card_id': equip.card.card_id,# 精灵id
			'equip_id': equip.equip_id,# 首饰id
			'current_equip_advance': equip.awake,# 当前饰品阶段
			'promote_fighting_point': equip.card.fighting_point - oldFightingPoint,# 提升宝可梦战力
			'current_fighting_point': equip.card.fighting_point,# 当前宝可梦战力
			'#time':self.getNnowdatetime()
		}
		self.ta.track(account_id=equip.game.role.pid, event_name=event, properties=properties)

	def cardEquipAwakeDown(self, equip, event, **kwargs):
		# card_equip_awake_down	精灵饰品降阶
		getItemId = 0
		getItemNumber = 0
		count = kwargs.get('count',1)
		for x in xrange(1,count+1):
			csvAwake = csv.base_attribute.equip_awake[x]
			itemField = 'costItemMap%d' % equip.awakeSeqID
			for k,v in csvAwake[itemField].iteritems():
				getItemId = k
				getItemNumber += v
		properties = {
			'card_id': equip.card.card_id,# 精灵id
			'equip_id': equip.equip_id,# 首饰id
			'cost_rmb': count*ConstDefs.dropEquipAwakeNeedRmb,# 消耗钻石
			'get_item_id': getItemId,# 获得道具id
			'get_item_number': getItemNumber,# 获得道具数量
			'#time':self.getNnowdatetime()
		}
		self.ta.track(account_id=equip.game.role.pid, event_name=event, properties=properties)

	# 角色养成相关
	def explorerComponentStrength(self, game, event, **kwargs):
		# explorer_component_strength	探险器组件升级
		properties = {
			'explorer_id': kwargs.get('explorer_id'),# 探险器id
			'explorer_component_id': kwargs.get('explorer_component_id'),# 探险器组件id
			'current_component_level': kwargs.get('current_component_level'),# 当前组件等级
			'explorer_advance': kwargs.get('explorer_advance'),# 探险器当前阶段
			'#time':self.getNnowdatetime()
		}
		self.ta.track(account_id=game.role.pid, event_name=event, properties=properties)
	def explorerAdvance(self, game, event, **kwargs):
		# explorer_advance	探险器进阶
		properties = {
			'explorer_id': kwargs.get('explorer_id'),# 探险器id
			'explorer_advance': kwargs.get('explorer_advance'),# 探险器当前阶段
			'#time':self.getNnowdatetime()
		}
		self.ta.track(account_id=game.role.pid, event_name=event, properties=properties)
	def talentLevelUp(self, game, event, **kwargs):
		# talent_level_up	天赋升级
		properties = {
			'talent_type': kwargs.get('talent_type'),# 天赋类型
			'talent_id': kwargs.get('talent_id'),# 天赋id
			'current_talent_level': kwargs.get('current_talent_level'),# 当前天赋等级
			'cost_talent_number': kwargs.get('cost_talent_number'),# 消耗天赋点
			'current_talent_number': game.role.talent_point,# 当前剩余天赋点
			'total_cost_talent_number': kwargs.get('total_cost_talent_number'),# 当前总投入天赋点
			'#time':self.getNnowdatetime()
		}
		self.ta.track(account_id=game.role.pid, event_name=event, properties=properties)
	def trainerSkillLevelUp(self, game, event, **kwargs):
		# trainer_skill_level_up	冒险执照能力升级
		skillId = kwargs.get('skill_id')
		properties = {
			'skill_id': skillId,# 能力id
			'current_level': game.role.trainer_skills[skillId],# 当前等级
			'current_trainer_level': game.role.trainer_level,# 当前执照等级
			'current_license_exp': game.role.trainer_exp,# 当前特权经验
			'#time':self.getNnowdatetime()
		}
		self.ta.track(account_id=game.role.pid, event_name=event, properties=properties)
	def trainerLevelUp(self, game, event, **kwargs):
		# trainer_level_up	冒险执照升级
		properties = {
			'current_trainer_level': game.role.trainer_level,# 当前执照等级
			'#time':self.getNnowdatetime()
		}
		self.ta.track(account_id=game.role.pid, event_name=event, properties=properties)

	# 公会相关
	def createUnion(self, game, event, **kwargs):
		# create_union	创建公会
		properties = {
			'union_db_id': objectid2string(game.role.union_db_id),# 公会id
			'union_name': game.role.union_name,# 公会名称
			'#time':self.getNnowdatetime()
		}
		self.user(game, {'union'})
		self.ta.track(account_id=game.role.pid, event_name=event, properties=properties)

	def applyUnion(self, game, event, **kwargs):
		# apply_union	申请公会
		properties = {
			'union_db_id': objectid2string(kwargs.get('union_id')),# 公会id
			'#time':self.getNnowdatetime()
		}
		self.user(game, {'union'})
		self.ta.track(account_id=game.role.pid, event_name=event, properties=properties)

	def joinUnion(self, game, event, **kwargs):
		# join_union	加入公会
		properties = {
			'union_db_id': objectid2string(game.role.union_db_id),# 公会id
			'union_name': game.role.union_name,# 公会名称
			'#time':self.getNnowdatetime()
		}
		self.user(game, {'union'})
		self.ta.track(account_id=game.role.pid, event_name=event, properties=properties)

	def leaveUnion(self, game, event, **kwargs):
		# leave_union	离开公会
		properties = {
			'#time':self.getNnowdatetime()
		}
		self.user(game, {'union'})
		self.ta.track(account_id=game.role.pid, event_name=event, properties=properties)

	def unionBonusPush(self, game, event, **kwargs):
		# union_bonus_push	发红包
		properties = {
			'union_db_id': objectid2string(game.role.union_db_id),# 公会id
			'union_name': game.role.union_name,# 公会名称
			'bonus_type': kwargs.get('bonus_type'),# 红包类型
			'#time':self.getNnowdatetime()
		}
		self.ta.track(account_id=game.role.pid, event_name=event, properties=properties)

	def unionDonate(self, game, event, **kwargs):
		# union_donate	公会捐献
		properties = {
			'union_db_id': objectid2string(game.role.union_db_id),# 公会id
			'union_name': game.role.union_name,# 公会名称
			'donate_type': kwargs.get('donate_type'),# 捐献类型
			'#time':self.getNnowdatetime()
		}
		self.ta.track(account_id=game.role.pid, event_name=event, properties=properties)

	def unionSkillLevelUp(self, game, event, **kwargs):
		# union_skill_level_up	公会技能修炼
		skillID = kwargs.get('union_skill_id')
		level = game.role.union_skills.get(skillID, 0)
		properties = {
			'union_db_id': objectid2string(game.role.union_db_id),# 公会id
			'union_name': game.role.union_name,# 公会名称
			'union_skill_id': skillID,# 公会技能id
			'current_union_skill_level': level,# 公会技能当前等级
			'#time':self.getNnowdatetime()
		}
		self.ta.track(account_id=game.role.pid, event_name=event, properties=properties)

	def fragmentWishing(self, game, event, **kwargs):
		# fragment_wishing	碎片许愿
		fragID = kwargs.get('fragment_id')
		quality = csv.fragments[fragID].quality
		properties = {
			'union_db_id': objectid2string(game.role.union_db_id),# 公会id
			'union_name': game.role.union_name,# 公会名称
			'fragment_id': fragID,# 碎片id
			'fragment_quality': quality,# 碎片id
			'current_times': 1-game.dailyRecord.union_frag_donate_start_times,# 当前剩余次数
			'#time':self.getNnowdatetime()
		}
		self.ta.track(account_id=game.role.pid, event_name=event, properties=properties)

	def fragmentDonate(self, game, event, **kwargs):
		# fragment_donate	碎片捐献
		fragID = kwargs.get('fragment_id')
		quality = csv.fragments[fragID].quality
		properties = {
			'union_db_id': objectid2string(game.role.union_db_id),# 公会id
			'union_name': game.role.union_name,# 公会名称
			'fragment_id': fragID,# 碎片id
			'fragment_quality': quality,# 碎片id
			'current_times': ConstDefs.unionFragDonateTimes-game.dailyRecord.union_frag_donate_times,# 当前剩余次数
			'#time':self.getNnowdatetime()
		}
		self.ta.track(account_id=game.role.pid, event_name=event, properties=properties)

	def unionFuben(self, game, event, **kwargs):
		# union_fuben	公会副本
		properties = {
			'union_db_id': objectid2string(kwargs['union_db_id']),# 公会id
			'union_name': kwargs['union_name'],# 公会名称
			'gateID': kwargs['gateID'],# 副本id
			'#time':self.getNnowdatetime()
		}
		self.ta.track(account_id=game.role.pid, event_name=event, properties=properties)

	def endGate(self, game, event, **kwargs):
		# end_gate 关卡结算
		ret = kwargs.get('ret')
		cardIDs = kwargs.get('cards')
		cardList =[]
		for dbid in cardIDs:
			card = game.cards.getCard(dbid)
			if card:
				cardList.append(card.card_id)
		result = ret['view']['result']
		isFirst = kwargs['old_star'] == 0 and result == 'win'
		properties = {
			'gate_id': kwargs.get('gate_id'),# 关卡id
			'is_first': isFirst,# 是否首次通关
			'battle_result': result,# 结果
			'card_list': cardList,# 上场精灵列表
			'get_star_number': ret['view'].get('star',0),# 获得星级
			'#time':self.getNnowdatetime()
		}
		self.ta.track(account_id=game.role.pid, event_name=event, properties=properties)

	def endArena(self, game, event, **kwargs):
		# end_arena 竞技场结束
		result = kwargs.get('result')
		cardList = []
		for k,v in result['model']['arena']['record']['card_attrs'].iteritems():
			cardList.append(v['card_id'])
		properties = {
			'card_list': cardList,# 上场精灵列表
			'battle_result': result['view'].get('result'),# 结果
			'#time':self.getNnowdatetime()
		}
		self.ta.track(account_id=game.role.pid, event_name=event, properties=properties)

	def endCrossArena(self, game, event, **kwargs):
		# end_cross_arena 跨服竞技场结束
		result = kwargs.get('result')
		cardList = []
		record = result['model']['cross_arena']['record']
		for group in sorted(record['cards'].keys()):
			cards = record['cards'][group]
			for dbid in cards:
				if dbid:
					v = record['card_attrs'][dbid]
					cardList.append(v['card_id'])
				else:
					cardList.append(0)
		properties = {
			'card_list': cardList,# 上场精灵列表
			'battle_result': result['view'].get('result'),# 结果
			'#time':self.getNnowdatetime()
		}
		self.ta.track(account_id=game.role.pid, event_name=event, properties=properties)

	def craftSignup(self, game, event, **kwargs):
		# craft_signup 报名石英
		properties = {
			'#time':self.getNnowdatetime()
		}
		self.ta.track(account_id=game.role.pid, event_name=event, properties=properties)

	# 冒险之路
	def endlessBattle(self, game, event, **kwargs):
		# endless_battle	战斗结算
		properties = {
			'gate_id': kwargs.get('gate_id'),# 关卡id
			'battle_result': kwargs.get('battle_result'),# 结果
			'#time':self.getNnowdatetime()
		}
		self.ta.track(account_id=game.role.pid, event_name=event, properties=properties)
	def endlessLevelReset(self, game, event, **kwargs):
		# endless_level_reset	关卡重置
		properties = {
			'current_reset_number': kwargs.get('current_reset_number'),# 重置次数
			# 'result': equip.equip_id,# 结果
			'#time':self.getNnowdatetime()
		}
		self.ta.track(account_id=game.role.pid, event_name=event, properties=properties)
	def endlessMoppingUp(self, game, event, **kwargs):
		# endless_mopping_up
		properties = {
			'mopping_up_number': kwargs.get('mopping_up_number'),# 扫荡关卡数
			'#time':self.getNnowdatetime()
		}
		self.ta.track(account_id=game.role.pid, event_name=event, properties=properties)

	# 元素挑战
	def clone(self, game, event, **kwargs):
		# clone	元素挑战
		properties = {
			'battle_result': kwargs.get('battle_result',None),# 结果
			'#time':self.getNnowdatetime()
		}
		self.ta.track(account_id=game.role.pid, event_name=event, properties=properties)

	# 以太乐园
	def randomTower(self, game, event, **kwargs):
		# 以太乐园 random_tower 以太乐园结算
		if game.role.pid not in self.randomTowerMap:
			self.randomTowerMap[game.role.pid] = {}
		self.randomTowerMap[game.role.pid].update({
			'room': kwargs.get('room'),# 房间id
			'history_point': kwargs.get('history_point'),# 获得积分
			'#time':self.getNnowdatetime()
		})
	# 下线的时候调用
	def syncLast(self, pid):
		if not self.ta:
			return
		try:
			data = self.randomTowerMap.pop(pid,{})
			if len(data) > 0:
				self.ta.track(account_id=pid, event_name='random_tower', properties=data)
		except Exception as e:
			logger.exception(e)
		try:
			v = self.itemMap.pop(pid, None)
			if v and v['data'] > 2:
				if v['key'][1] == 'gain':
					self.increase(pid, v['data'], v['time'])
				if v['key'][1] == 'cost':
					self.decrease(pid, v['data'], v['time'])
		except Exception as e:
			logger.exception(e)
	# 5点调用
	def onNewDayInClock5(self):
		if not self.ta:
			return
		try:
			for pid,data in self.randomTowerMap.iteritems():
				if len(data) > 0:
					self.ta.track(account_id=pid, event_name='random_tower', properties=data)
		except Exception as e:
			logger.exception(e)
		self.randomTowerMap = {}
	# 捕捉
	def capture(self, game, event, **kwargs):
		# 活动	capture
		captureResult = kwargs.get('capture_result',{})
		result = 'fail'
		if len(captureResult) > 0:
			result = 'win'
		properties = {
			'capture_result': result,# 捕捉结果
			'target_card_id': kwargs.get('target_card_id',None),# 目标精灵id
			'#time':self.getNnowdatetime()
		}
		self.ta.track(account_id=game.role.pid, event_name=event, properties=properties)

	# 钓鱼
	def fishing(self, game, event, **kwargs):
		# 活动	fishing
		properties = {
			'current_fishing_level': game.fishing.level,# 当前钓鱼等级
			'target_fish_id': kwargs.get('target_fish_id',None),# 目标鱼id
			'get_prize_list': kwargs.get('get_prize_list',None),# 获得奖励列表
			'fishing_result': kwargs.get('fishing_result',None),# 钓鱼结果
			'fish_map_id': game.fishing.select_scene,# 地图id
			'#time':self.getNnowdatetime()
		}
		self.ta.track(account_id=game.role.pid, event_name=event, properties=properties)

	# 卡牌养成
	# @tj_coverage
	def card(self, card, event, **kwargs):
		if not self.ta:
			return
		try:
			# card_level_up	精灵升级
			# if 'card_level_up' == event:
			# 	self.cardLevelUp(card, event, **kwargs)
			# card_star_up	精灵升星
			if 'card_star_up' == event:
				self.cardStarUp(card, event, **kwargs)
			# card_advance_up 精灵突破等级提升
			elif 'card_advance_up' == event:
				self.cardAdvanceUp(card, event, **kwargs)
			# card_skill_level_up 精灵技能等级提升
			# elif 'card_skill_level_up' == event:
			# 	self.cardSkillLevelUp(card, event, **kwargs)
			# card_effort_train 精灵努力值提升
			elif 'effort_train' == event:
				self.effortTrain(card, event, **kwargs)
			# nvalue 精灵个体值提升
			elif 'nvalue' == event:
				self.nvalue(card, event, **kwargs)
			# ability 精灵潜能激活
			elif 'ability' == event:
				self.ability(card, event, **kwargs)
			# card_ultimate_property_up	精灵极限属性提升
			elif 'card_star_level_up' == event:
				self.cardStarLevelUp(card, event, **kwargs)
			# card_feel_level_up 精灵好感度等级提升
			elif 'card_feel_level_up' == event:
				self.cardFeelLevelUp(card, event, **kwargs)
			# card_character_swap 精灵性格交换
			elif 'card_character_swap' == event:
				self.cardCharacterSwap(card, event, **kwargs)
			# card_gem_equip 符石装备变动
			elif 'card_gem' == event:
				self.cardGem(card, event, **kwargs)
		except Exception as e:
			logger.info(e)
	# 饰品相关
	# @tj_coverage
	def equip(self, equip, event, **kwargs):
		if not self.ta:
			return
		try:
			# card_equip_level_up 精灵饰品强化
			# if 'card_equip_level_up' == event:
			# 	self.cardEquipLevelUp(equip, event, **kwargs)
			# card_equip_star_up 精灵饰品升星
			if 'card_equip_star_up' == event:
				self.cardEquipStarUp(equip, event, **kwargs)
			# card_equip_star_down 精灵饰品降星
			elif 'card_equip_star_down' == event:
				self.cardEquipStarDown(equip, event, **kwargs)
			# card_equip_awake_up 精灵饰品升阶
			elif 'card_equip_awake_up' == event:
				self.cardEquipAwakeUp(equip, event, **kwargs)
			# card_equip_awake_down	精灵饰品降阶
			elif 'card_equip_awake_down' == event:
				self.cardEquipAwakeDown(equip, event, **kwargs)
		except Exception as e:
			logger.info(e)

	# 道馆重置, 上期的进度
	def gymReset(self, game, event, **kwargs):
		properties = {
			'gym_last_date': kwargs['last_date']
		}
		for gymid, level in kwargs['fuben'].iteritems():
			properties['gym_%d' % gymid] = level
		self.ta.track(account_id=game.role.pid, event_name=event, properties=properties)

	# 狩猎地带开始
	def huntingBegin(self, game, event, **kwargs):
		properties = {
			'route': kwargs['route'],
		}
		self.ta.track(account_id=game.role.pid, event_name=event, properties=properties)

	# 狩猎地带战斗胜利
	def huntingBattleWin(self, game, event, **kwargs):
		node = kwargs['node']
		if 10 <= node % 100 <= 15: # 其中达到 10/11/12/13/14/15层的玩家数量和次数
			properties = {
				'route': kwargs['route'],
				'gate_id': kwargs['gate_id'],
				'node': node,
			}
			self.ta.track(account_id=game.role.pid, event_name=event, properties=properties)

	# @tj_coverage
	def track(self, game, event, **kwargs):
		if not self.ta:
			return
		try:
			if 'register' == event:
				self.register(game, event, **kwargs)
			elif 'login' == event:
				self.login(game, event, **kwargs)
			elif 'guide' == event:
				self.guide(game, event, **kwargs)
			elif 'level_up' == event:
				self.levelUp(game, event, **kwargs)
			elif 'vip_level_up' == event:
				self.vipLevelUp(game, event, **kwargs)
			elif 'order_pay' == event:
				self.orderPay(game, event, **kwargs)
			# explorer_component_strength	探险器组件升级
			elif 'explorer_component_strength' == event:
				self.explorerComponentStrength(game, event, **kwargs)
			# explorer_advance	探险器进阶
			elif 'explorer_advance' == event:
				self.explorerAdvance(game, event, **kwargs)
			# talent_level_up	天赋升级
			elif 'talent_level_up' == event:
				self.talentLevelUp(game, event, **kwargs)
			# trainer_skill_level_up	冒险执照能力升级
			elif 'trainer_skill_level_up' == event:
				self.trainerSkillLevelUp(game, event, **kwargs)
			# trainer_level_up	冒险执照升级
			elif 'trainer_level_up' == event:
				self.trainerLevelUp(game, event, **kwargs)
			# create_union	创建公会
			elif 'create_union' == event:
				self.createUnion(game, event, **kwargs)
			# apply_union	申请公会
			elif 'apply_union' == event:
				self.applyUnion(game, event, **kwargs)
			# join_union	加入公会
			elif 'join_union' == event:
				self.joinUnion(game, event, **kwargs)
			# leave_union	离开公会
			elif 'leave_union' == event:
				self.leaveUnion(game, event, **kwargs)
			# union_bonus_push	发红包
			elif 'union_bonus_push' == event:
				self.unionBonusPush(game, event, **kwargs)
			# union_donate	公会捐献
			elif 'union_donate' == event:
				self.unionDonate(game, event, **kwargs)
			# union_skill_level_up	公会技能修炼
			elif 'union_skill_level_up' == event:
				self.unionSkillLevelUp(game, event, **kwargs)
			# fragment_wishing	碎片许愿
			elif 'fragment_wishing' == event:
				self.fragmentWishing(game, event, **kwargs)
			# fragment_donate	碎片捐献
			elif 'fragment_donate' == event:
				self.fragmentDonate(game, event, **kwargs)
			# union_fuben	公会副本
			elif 'union_fuben' == event:
				self.unionFuben(game, event, **kwargs)
			# end_gate 关卡结算
			elif 'end_gate' == event:
				self.endGate(game, event, **kwargs)
			# end_arena 竞技场结束
			elif 'end_arena' == event:
				self.endArena(game, event, **kwargs)
			# end_cross_arena 跨服竞技场结束
			elif 'end_cross_arena' == event:
				self.endCrossArena(game, event, **kwargs)
			# craft_signup 报名石英
			# elif 'craft_signup' == event:
			# 	self.craftSignup(game, event, **kwargs)
			# endless_battle	战斗结算
			elif 'endless_battle' == event:
				self.endlessBattle(game, event, **kwargs)
			# 	endless_level_reset	关卡重置
			elif 'endless_level_reset' == event:
				self.endlessLevelReset(game, event, **kwargs)
			# 	endless_mopping_up
			elif 'endless_mopping_up' == event:
				self.endlessMoppingUp(game, event, **kwargs)
			# clone	元素挑战
			elif 'clone' == event:
				self.clone(game, event, **kwargs)
			# 以太乐园 random_tower 以太乐园结算
			elif 'random_tower' == event:
				self.randomTower(game, event, **kwargs)
			# 捕捉	capture
			elif 'capture' == event:
				self.capture(game, event, **kwargs)
			# 钓鱼	fishing
			elif 'fishing' == event:
				self.fishing(game, event, **kwargs)
			# 道馆重置, 上期的进度 gym_reset
			elif 'gym_reset' == event:
				self.gymReset(game, event, **kwargs)
			# 狩猎地带开始
			elif 'hunting_begin' == event:
				self.huntingBegin(game, event, **kwargs)
			# 狩猎地带战斗胜利
			elif 'hunting_battle_win' == event:
				self.huntingBattleWin(game, event, **kwargs)

		except Exception as e:
			logger.exception(e)

	# 内网改时间测试
	def getNnowdatetime(self):
		#import datetime
		#return datetime.datetime(2020, 9, 15, 10)
		return nowdatetime_t()

ta = TJTA()
