#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2014 YouMi Information Technology Inc.

Trainer Handlers
'''
from framework.csv import csv, ErrDefs
from framework.log import logger
from game import ClientError
from game.handler._endlesstower import EndlessTowerReset
from game.handler._role import RoleLianjinTotalAward
from game.object import FeatureDefs, DailyAssistantDefs
from game.handler.task import RequestHandlerTask
from game.object.game import ObjectDailyAssistant
from game.object.game.levelcsv import ObjectFeatureUnlockCSV

from game.handler import _lottery as lottery
from game.handler import _union as union
from game.handler import _role as roleHandler
from game.handler import _trainer as trainer
from game.handler import _craft as craft
from game.handler import _cross_craft as crosscraft
from game.handler import _union_fight as unionfight
from game.handler import _huodong as huodong
from game.handler import _endlesstower as endless
from game.handler import _fishing as fishing

from tornado.gen import coroutine
import copy

HandlersMap = {
	DailyAssistantDefs.UnionRedpacket: union.UnionRedPacketOnekey,
	DailyAssistantDefs.UnionDailyGift: union.UnionDailyGift,
	DailyAssistantDefs.TrainerAward: trainer.TrainerDailyAward,
	DailyAssistantDefs.GainGold: roleHandler.RoleLianJin,

	DailyAssistantDefs.DrawCardRmb: lottery.LotteryCardDraw,
	DailyAssistantDefs.DrawCardGold: lottery.LotteryCardDraw,
	DailyAssistantDefs.DrawEquip: lottery.LotteryEquipDraw,
	DailyAssistantDefs.DrawItem: lottery.LotteryItemDraw,
	DailyAssistantDefs.DrawGem: lottery.LotteryGemDraw,
	DailyAssistantDefs.DrawChip: lottery.LotteryChipDraw,

	DailyAssistantDefs.CraftSignup: craft.CraftSignUp,
	DailyAssistantDefs.UnionFightSignup: unionfight.UnionFightSignup,
	DailyAssistantDefs.CrossCraftSignup: crosscraft.CrossCraftSignUp,

	DailyAssistantDefs.HuodongFuben: huodong.HuoDongSaoDang,
	DailyAssistantDefs.Endless: endless.EndlessTowerSaodang,
	DailyAssistantDefs.Fishing: fishing.FishingOneKey,

	DailyAssistantDefs.UnionContrib: union.UnionContrib,
	DailyAssistantDefs.UnionFragDonate: union.UnionFragDonateStart,
	DailyAssistantDefs.UnionTrainingSpeedup: union.UnionTrainingSpeedUp,
}


# 日常小助手 一键
class DailyAssistantOneKey(RequestHandlerTask):
	url = r'/game/daily/assistant/onekey'

	@coroutine
	def run(self):
		if not ObjectFeatureUnlockCSV.isOpen(FeatureDefs.DailyAssistant, self.game):
			raise ClientError(ErrDefs.levelLessNoOpened)
		input_back = self.input

		type = self.input.get('type', None)
		filterKeys = self.input.get('filterKeys', None)  # 过滤掉的任务
		flags = self.input.get('flags', None)  # 客户端弹窗的选择
		if type is None:
			raise ClientError('param miss')
		if type not in ObjectDailyAssistant.TabMap:
			raise ClientError('params error')
		if flags is not None:
			# 无尽塔是否消耗钻石重置; 抽符石是否自动分解
			if type in [DailyAssistantDefs.Fuben, DailyAssistantDefs.Draw]:
				self.game.role.assistant_flags[type] = flags

		self.type = type
		self.data = {}
		self.key = None
		self.keyDataD = {}
		self.keyDataL = []
		self.count = 0

		# {csvID: handlerInput}
		inputs = self.game.dailyAssistant.getInputs(type, filterKeys)
		for csvID in inputs:
			self.key = csvID
			self.keyDataD = {}
			self.keyDataL = []
			self.count = 0
			handlerInputs = inputs[csvID]
			for handlerInput in handlerInputs:
				self.input = handlerInput
				try:
					# 无尽塔特殊预先判断是否重置
					role = self.game.role
					if csvID == DailyAssistantDefs.Endless and role.endless_tower_current > role.endless_tower_max_gate:
						if not role.isResetEndless():
							break
						yield EndlessTowerReset.run.__get__(self, EndlessTowerReset)()

					yield HandlersMap[csvID].run.__get__(self, HandlersMap[csvID])()

					if csvID == DailyAssistantDefs.GainGold:  # 聚宝后 领取宝箱
						yield RoleLianjinTotalAward.run.__get__(self, RoleLianjinTotalAward)()
					elif csvID == DailyAssistantDefs.Endless:  # 无尽塔扫荡后 重置
						if not role.isResetEndless():
							break
						yield EndlessTowerReset.run.__get__(self, EndlessTowerReset)()

				except ClientError as e:
					self.data.setdefault(self.key, {}).update({'errorID': e.log_message})

		self.input = input_back
		self.real_write()

	def write(self, ret):
		if not ret:
			return
		# 快速冒险（数据量大，特殊累加处理）
		if self.type == DailyAssistantDefs.Fuben:
			if self.key == DailyAssistantDefs.Endless:
				for award in ret['view']['result']:
					dictSum(self.keyDataD, award)
				self.data[self.key] = self.keyDataD
			elif self.key == DailyAssistantDefs.HuodongFuben:
				dictSum(self.keyDataD, ret['view']['result'])
				self.data[self.key] = self.keyDataD
			elif self.key == DailyAssistantDefs.Fishing:
				self.data[self.key] = ret['view']  # 捕捞只有一次调用
		# 战斗报名
		elif self.type == DailyAssistantDefs.Signup:
			if len(ret.get('model', {})) > 0:
				self.data[self.key] = 1  # 表示报名成功
		else:
			# 抽卡
			if self.type == DailyAssistantDefs.Draw:
				result = ret['view']['result']
			# 奖励领取、公会事宜
			else:
				result = ret['view']
			self.keyDataL.append(result)
			self.data[self.key] = self.keyDataL

	def real_write(self):
		views = {'view': self.data}
		RequestHandlerTask.write(self, views)


# 日常小助手 选择
class DailyAssistantSet(RequestHandlerTask):
	url = r'/game/daily/assistant/set'

	@coroutine
	def run(self):
		if not ObjectFeatureUnlockCSV.isOpen(FeatureDefs.DailyAssistant, self.game):
			raise ClientError(ErrDefs.levelLessNoOpened)

		csvID = self.input.get('csvID', None)
		value = self.input.get('value', None)

		if csvID is None or value is None:
			raise ClientError('param miss')

		assistant = self.game.dailyAssistant
		if csvID not in assistant.csv():
			raise ClientError('csvID error')
		if assistant.itemIsLock(csvID):
			raise ClientError('item no open')

		dailyAssistant = self.game.role.daily_assistant
		if csvID == DailyAssistantDefs.UnionContrib:
			if value not in csv.union.contrib:
				raise ClientError('unionContrib value error')
			dailyAssistant["union_contrib"] = value
		elif csvID == DailyAssistantDefs.UnionFragDonate:
			if not self.game.cards.isExistedByCsvID(value):
				raise ClientError('unionFragDonate value error')
			dailyAssistant["union_frag_donate_card_id"] = value
		elif csvID == DailyAssistantDefs.Endless:
			if value not in (0, 1):
				raise ClientError('endless value error')
			dailyAssistant["endless_buy_reset"] = value
		elif csvID == DailyAssistantDefs.Fishing:
			if value not in (0, 1):
				raise ClientError('fishing value error')
			dailyAssistant["fishing_skip"] = value


def dictSum(d1, d2):
	''' 把d2的内容加到d1里'''
	t = copy.copy(d2)
	for key in d1:
		if key in t:
			t[key] += d1[key]
	d1.update(t)
