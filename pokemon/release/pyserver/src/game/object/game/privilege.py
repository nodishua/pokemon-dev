#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2014 YouMi Information Technology Inc.
'''

from framework.csv import csv
from framework.object import ObjectBase

class ObjectPrivilege(ObjectBase):
	'''
	月卡权限
	'''

	def init(self):
		self._privileges = set() # 月卡权限

		return ObjectBase.init(self)

	def active(self, pid):
		if pid in self._privileges:
			return
		self._privileges.add(pid)

	def discard(self, pid):
		if pid not in self._privileges:
			return
		self._privileges.discard(pid)

	def _total(self, field):
		count = 0
		for pid in self._privileges:
			v = csv.month_card_privilege[pid][field]
			if v:
				count += v
		return count

	# 月卡点金额外获得比例
	@property
	def lianJinRate(self):
		return self._total('lianjinRate')

	# 月卡体力上限
	@property
	def staminaExtraMax(self):
		return self._total('staminaExtraMax')

	# 月卡技能点上限
	@property
	def skillPointExtraMax(self):
		return self._total('skillPointExtraMax')

	# 月卡排位赛冷却时间
	@property
	def pwNoCD(self):
		for pid in self._privileges:
			cfg = csv.month_card_privilege[pid]
			if cfg.pwNoCD:
				return True
		return False

	# 月卡炼金免费次数
	@property
	def lianJinFreeTimes(self):
		return self._total('lianjinFreeTimes')

	# 月卡体力购买免费次数
	@property
	def staminaBuyFreeTimes(self):
		return self._total('staminaBuyFreeTimes')

	# 聚宝暴击概率
	@property
	def lianJinUpstart(self):
		upstart = {}
		for pid in self._privileges:
			v = csv.month_card_privilege[pid]['lianJinUpstart']
			if v:
				for kk, vv in v.iteritems():
					upstart[kk] = vv + upstart.get(kk, 0)
		return upstart

	# 金币副本次数
	@property
	def huodongGoldTimes(self):
		return self._total('huodongGoldTimes')

	# 金币副本产量增加
	@property
	def huodongGoldDropRate(self):
		return self._total('huodongGoldDropRate')

	# 经验副本次数
	@property
	def huodongExpTimes(self):
		return self._total('huodongExpTimes')

	# 经验副本产量增加
	@property
	def huodongExpDropRate(self):
		return self._total('huodongExpDropRate')

	# 碎片副本次数
	@property
	def huodongFragTimes(self):
		return self._total('huodongFragTimes')

	# 碎片副本产量增加
	@property
	def huodongFragDropRate(self):
		return self._total('huodongFragDropRate')

	# 礼物副本次数
	@property
	def huodongGiftTimes(self):
		return self._total('huodongGiftTimes')

	# 礼物副本产量增加
	@property
	def huodongGiftDropRate(self):
		return self._total('huodongGiftDropRate')

	# 碎片商店刷新上限增加
	@property
	def fragShopRefreshLimit(self):
		return self._total('fragShopRefreshLimit')

	# 神秘商店购买折扣
	@property
	def mysteryShopDiscount(self):
		return self._total('mysteryShopDiscount')

	# 普通商店购买折扣
	@property
	def fixShopDiscount(self):
		return self._total('fixShopDiscount')
