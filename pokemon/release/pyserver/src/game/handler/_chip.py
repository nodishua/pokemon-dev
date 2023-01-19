#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2014 YouMi Information Technology Inc.

Chip Handlers
'''
from tornado.gen import coroutine

from framework import nowtime_t
from framework.csv import ConstDefs, ErrDefs, csv
from framework.word_filter import filterName
from game import ClientError
from game.handler.task import RequestHandlerTask
from game.handler.inl import effectAutoGain
from game.object.game.gain import ObjectCostAux, ObjectGainAux


# 芯片洗练
class ChipRecast(RequestHandlerTask):
	url = r'/game/card/chip/recast'

	@coroutine
	def run(self):
		chip = self.input.get('chip', None)
		pos1 = self.input.get('pos1', None)
		pos2 = self.input.get('pos2', None)

		if pos1 is None and pos2 is None:
			raise ClientError("select at least one attr")

		if not chip:
			raise ClientError('param miss')

		chip = self.game.chips.getChip(chip)
		cfg = csv.chip.chips[chip.chip_id]
		if cfg.startNum + cfg.acquiredLimit > len(chip.now):
			raise ClientError("chip level not enougth")
		chip.recast(pos1, pos2)

		if chip.card_db_id:
			card = self.game.cards.getCard(chip.card_db_id)
			card.calcChipAttrsAddition(card)
			card.onUpdateAttrs()


# 芯片洗练重置
class ChipRecastReset(RequestHandlerTask):
	url = r'/game/card/chip/recast/reset'

	@coroutine
	def run(self):
		chip = self.input.get('chip', None)

		if not chip:
			raise ClientError('param miss')

		chip = self.game.chips.getChip(chip)
		if not any([recastTimes for csvID, recastTimes, strengthTimes in chip.now]):
			raise ClientError('chip reset not recasted')

		cost = ObjectCostAux(self.game, {'rmb': ConstDefs.chipResetCost})
		if not cost.isEnough():
			raise ClientError('chip reset not enough cost')

		cost.cost(src='chip_reset_cost')

		for n, (csvID, recastTimes, strengthTimes) in enumerate(chip.now):
			chip.now[n] = (chip.first[n], 0, strengthTimes)

		for n, (csvID, _, strengthTimes) in enumerate(chip.before):
			chip.before[n] = (chip.first[n], 0, strengthTimes)

		if chip.card_db_id:
			card = self.game.cards.getCard(chip.card_db_id)
			card.calcChipAttrsAddition(card)
			card.onUpdateAttrs()


# 芯片强化
class ChipStrength(RequestHandlerTask):
	url = r'/game/card/chip/strength'

	@coroutine
	def run(self):
		chip = self.input.get('chip', None)
		costChips = self.input.get('costChips', [])
		costCsvIDs = self.input.get('costCsvIDs', {})

		if not all((chip, costChips or costCsvIDs)):
			raise ClientError('param miss')

		chip = self.game.chips.getChip(chip)
		chip.strengthChip(costChips, costCsvIDs)

		if chip.card_db_id:
			card = self.game.cards.getCard(chip.card_db_id)
			card.calcChipAttrsAddition(card)
			card.onUpdateAttrs()


# 芯片镶嵌更改
class ChipChange(RequestHandlerTask):
	url = r'/game/card/chip/change'

	@coroutine
	def run(self):
		cardID = self.input.get('cardID', None)
		config = self.input.get('config', None)

		if type(config) is list:  # 特殊格式转化
			config = {n: i for n,i in enumerate(config, 1)}

		if not all((cardID, config)):
			raise ClientError('param miss')
		# config中chip不重复
		chips = [chip for chip in config.values() if chip != -1]
		if len(chips) != len(set(chips)):
			raise ClientError('duplicate chips')

		card = self.game.cards.getCard(cardID)
		if not card:
			raise ClientError('bad card')

		changedCards = set()  # 导致属性变动的卡牌
		changedCards.add(card)

		positions = {}
		for pos, chipID in config.iteritems():
			if chipID == -1:  # 卸下
				chipID = card.chip.pop(pos, None)
				if chipID:
					chip = self.game.chips.getChip(chipID)
					chip.card_db_id = None
			else:
				chip = self.game.chips.getChip(chipID)
				if not chip:
					raise ClientError("bad chip")
				if chip.pos != pos:
					raise ClientError("bad pos")
				if card.chip.get(pos, None) != chipID:
					positions[pos] = chip

		for pos, chip in positions.iteritems():
			if chip.card_db_id:  # 先卸下
				oldCard = self.game.cards.getCard(chip.card_db_id)
				chip.card_db_id = None
				if oldCard:
					oldCard.chip.pop(pos, None)
					changedCards.add(oldCard)
			oldChipID = card.chip.pop(pos, None)
			if oldChipID:
				oldChip = self.game.chips.getChip(oldChipID)
				oldChip.card_db_id = None
			card.chip[pos] = chip.id
			chip.card_db_id = card.id

		with self.game.cards.fightingPointChangeParallel():
			for card in changedCards:
				card.calcChipAttrsAddition(card)
				card.onUpdateAttrs()


# 芯片锁定切换
class ChipLockedSwitch(RequestHandlerTask):
	url = r'/game/card/chip/locked/switch'

	@coroutine
	def run(self):
		chipID = self.input.get('chipID', None)
		chip = self.game.chips.getChip(chipID)
		if chip is None:
			raise ClientError('chipID error')
		chip.locked = not chip.locked


# 芯片重生
class ChipRebirth(RequestHandlerTask):
	url = r'/game/chip/rebirth'

	@coroutine
	def run(self):
		chipIDs = self.input.get('chipIDs', None)
		if chipIDs is None:
			raise ClientError("param miss")
		if len(set(chipIDs)) != len(chipIDs):
			raise ClientError("chipID duplicate")

		chips = self.game.chips.getChips(chipIDs)
		if not chips or len(chips) != len(chipIDs):
			raise ClientError("chipIDs error")

		# 重生
		cardIDSet = set()
		eff = ObjectGainAux(self.game, {})
		for chip in chips:
			eff += chip.rebirth()
			if chip.card_db_id:
				cardIDSet.add(chip.card_db_id)

		# 获得道具 金币
		if eff:
			yield effectAutoGain(eff, self.game, self.dbcGame, src='chip_rebirth')

		for cardID in cardIDSet:
			card = self.game.cards.getCard(cardID)
			card.calcChipAttrsAddition(card)
			card.onUpdateAttrs()
		
		self.write({
			'view': {
				'result': eff.result
			}
		})


# 芯片方案 新增
class ChipPlanNew(RequestHandlerTask):
	url = r'/game/chip/plan/new'

	@coroutine
	def run(self):
		chips = self.input.get("chips", None)
		name = self.input.get("name", None)

		if chips is None or name is None:
			raise ClientError("param miss")

		# 名称是否合法 允许为空字符串
		uname = name.decode('utf8')
		if filterName(uname):
			raise ClientError(ErrDefs.chipPlanNameInvalid)

		if type(chips) == list:
			chips = {n: i for n, i in enumerate(chips, 1)}

		plans = self.game.role.chip_plans
		if len(plans) == 0:
			idx = 1
		elif len(plans) == max(plans):
			idx = max(plans) + 1
		else:
			idx = min([index for index, k in enumerate(plans.keys(), 1) if index != k])
		plans[idx] = {
			"created_time": nowtime_t(),
			"name": name,
			"chips": chips
		}

		self.game.role.initChipPlanCache()

		self.write({'view': {'result': 'ok'}})


# 芯片方案 编辑/替换
class ChipPlanEdit(RequestHandlerTask):
	url = r'/game/chip/plan/edit'

	@coroutine
	def run(self):
		idx = self.input.get("id", None)
		chips = self.input.get("chips", None)
		name = self.input.get("name", None)
		top = self.input.get("top", None)

		plan = self.game.role.chip_plans.get(idx, None)
		if not plan:
			raise ClientError("chip plan not exist")

		if name is not None:
			# 名称是否合法 允许为空字符串
			uname = name.decode('utf8')
			if filterName(uname):
				raise ClientError(ErrDefs.chipPlanNameInvalid)
			plan["name"] = name

		if type(chips) == list:
			chips = {n: i for n, i in enumerate(chips, 1)}
		if chips is not None:
			plan["chips"] = chips

		if top:
			plan["created_time"] = nowtime_t()

		self.game.role.initChipPlanCache()

		self.write({'view': {'result': 'ok'}})


# 芯片方案 删除
class ChipPlanDelete(RequestHandlerTask):
	url = r'/game/chip/plan/delete'

	@coroutine
	def run(self):
		idx = self.input.get("id", None)

		if not self.game.role.chip_plans.get(idx, None):
			raise ClientError("chip plan not exist")
		self.game.role.chip_plans.pop(idx, None)
		self.game.role.initChipPlanCache()

		self.write({'view': {'result': 'ok'}})
