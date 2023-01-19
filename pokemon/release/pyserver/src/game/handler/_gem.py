#!/usr/bin/python
# coding=utf-8

from framework.csv import ConstDefs, ErrDefs
from framework.helper import transform2list
from framework.log import logger
from game import ClientError, ServerError
from game.handler import RequestHandlerTask
from game.handler.inl import effectAutoGain
from game.object import FeatureDefs, AttrDefs, AchievementDefs
from game.object.game import ObjectFeatureUnlockCSV
from game.object.game.gain import ObjectCostAux, ObjectGainAux
from game.object.game.gem import ObjectGem
from tornado.gen import coroutine
from game.thinkingdata import ta


# 宝石 镶嵌
class GemEquip(RequestHandlerTask):
	url = r'/game/gem/equip'

	@coroutine
	def run(self):
		if not ObjectFeatureUnlockCSV.isOpen(FeatureDefs.Gem, self.game):
			raise ClientError(ErrDefs.gemNotOpen)
		cardID = self.input.get('cardID', None)
		gemID = self.input.get('gemID', None)
		pos = self.input.get('pos', None)

		if cardID is None or not gemID or not pos:
			raise ClientError('param miss')
		card = self.game.cards.getCard(cardID)
		if card is None:
			raise ClientError('cardID error')

		gem = self.game.gems.getGem(gemID)
		if not gem:
			raise ClientError('gemID error')

		if self.game.gems.hadEquipGem(cardID, gem):
			raise ClientError('the same suitNo can not equip again')

		oldFightingPoint = card.fighting_point
		# 检查宝石槽是否开启
		self.game.gems.checkGemPosOpenCondition(card, pos)

		# 宝石是否已镶嵌于其他card身上
		if gem.card_db_id and gem.card_db_id != cardID:
			raise ClientError('gem had been equiped in other card')

		gem.card_db_id = cardID
		card.gems[pos] = gemID  # 镶嵌

		self.game.zawake.onAttrChange()

		card = self.game.cards.getCard(cardID)
		card.calcGemAttrsAddition(card)
		card.onUpdateAttrs()

		ta.card(card, event='card_gem',oldFightingPoint=oldFightingPoint,gem_equip_type='equip')


# 宝石 一键镶嵌
class GemOneKeyEquip(RequestHandlerTask):
	url = r'/game/gem/onekey/equip'

	@coroutine
	def run(self):
		if not ObjectFeatureUnlockCSV.isOpen(FeatureDefs.Gem, self.game):
			raise ClientError(ErrDefs.gemNotOpen)
		cardID = self.input.get('cardID', None)
		gemIDs = self.input.get('gemIDs', None)  # [None,...gemID]
		if cardID is None or all([x is None for x in gemIDs]):
			raise ClientError('param miss')
		card = self.game.cards.getCard(cardID)
		if card is None:
			raise ClientError('cardID error')

		gemIDs = transform2list(gemIDs, 9)
		if len(filter(None, gemIDs)) == 0:
			raise ClientError('gemIDs all None')

		gems = self.game.gems.getGems(gemIDs)

		if self.game.gems.isDuplicateGem(gems):
			raise ClientError('the same suitNo can not equip again')

		# 检查全部的gem数据是否正确
		for ind, gemID in enumerate(gemIDs):
			pos = ind + 1
			if not gemID:
				continue

			# 检查宝石槽是否开启
			self.game.gems.checkGemPosOpenCondition(card, pos)

			gem = self.game.gems.getGem(gemID)
			if not gem:
				raise ClientError('gemID error')

			# 宝石是否已镶嵌于其他card身上
			if gem.card_db_id and gem.card_db_id != cardID:
				raise ClientError('gem had been equiped in other card')

		oldFightingPoint = card.fighting_point
		# 卸下card上已镶嵌的宝石
		for gemID in card.gems.itervalues():
			cardGem = self.game.gems.getGem(gemID)
			if cardGem:
				cardGem.card_db_id = None
		card.gems.clear()

		# 镶嵌
		for ind, gemID in enumerate(gemIDs):
			pos = ind + 1
			if not gemID:
				continue
			gem = self.game.gems.getGem(gemID)
			gem.card_db_id = cardID
			card.gems[pos] = gemID

		self.game.zawake.onAttrChange()

		card = self.game.cards.getCard(cardID)
		card.calcGemAttrsAddition(card)
		card.onUpdateAttrs()
		ta.card(card, event='card_gem',oldFightingPoint=oldFightingPoint,gem_equip_type='onekey_equip')


# 宝石 卸下（含一键卸下 多个）
class GemUnload(RequestHandlerTask):
	url = r'/game/gem/unload'

	@coroutine
	def run(self):
		if not ObjectFeatureUnlockCSV.isOpen(FeatureDefs.Gem, self.game):
			raise ClientError(ErrDefs.gemNotOpen)
		gemIDs = self.input.get('gemIDs', None)  # [dbIds]
		if gemIDs is None:
			raise ClientError('param miss')

		gemIDs = transform2list(gemIDs, 9)
		if len(filter(None, gemIDs)) == 0:
			raise ClientError('gemIDs all None')

		for gemID in gemIDs:
			if not gemID:
				continue
			gem = self.game.gems.getGem(gemID)
			if not gem:
				raise ClientError('gemID error')
			elif not gem.card_db_id:
				raise ClientError('gem has no equip')
			pos = gem.getGemPos()
			# 卸下
			if pos is not None:
				card = self.game.cards.getCard(gem.card_db_id)
				oldFightingPoint = card.fighting_point
				card.gems.pop(pos, None)
				gem.card_db_id = None

				card.calcGemAttrsAddition(card)
				card.onUpdateAttrs()
				ta.card(card, event='card_gem',oldFightingPoint=oldFightingPoint,gem_equip_type='unload')
			else:
				raise ClientError('card has no this gem')

		self.game.zawake.onAttrChange()



# 宝石 更换
class GemSwap(RequestHandlerTask):
	url = r'/game/gem/swap'

	@coroutine
	def run(self):
		if not ObjectFeatureUnlockCSV.isOpen(FeatureDefs.Gem, self.game):
			raise ClientError(ErrDefs.gemNotOpen)
		oldGemID = self.input.get('oldGemID', None)  # dbId
		newGemID = self.input.get('newGemID', None)  # dbId
		if not all([x is not None for x in [oldGemID, newGemID]]):
			raise ClientError('param miss')

		oldGem = self.game.gems.getGem(oldGemID)
		newGem = self.game.gems.getGem(newGemID)
		gems = {'oldGem': oldGem, 'newGem': newGem}
		for key, gem in gems.items():
			if not gem:
				raise ClientError('%sID error' % key)
		if not oldGem.card_db_id:
			raise ClientError('oldGem has no equip')
		if newGem.card_db_id:
			raise ClientError('newGem had equip')

		pos = oldGem.getGemPos()
		if pos:
			card = self.game.cards.getCard(oldGem.card_db_id)
			oldFightingPoint = card.fighting_point
			if self.game.gems.hadEquipGem(oldGem.card_db_id, newGem, pos):
				raise ClientError('the same gemCsvID can not equip again')
			card.gems[pos] = newGemID
			oldGem.card_db_id = None
			newGem.card_db_id = card.id

			self.game.zawake.onAttrChange()

			card.calcGemAttrsAddition(card)
			card.onUpdateAttrs()
			ta.card(card, event='card_gem',oldFightingPoint=oldFightingPoint,gem_equip_type='swap')
		else:
			raise ClientError('card has no this oldGem')



# 宝石 槽内换位
class GemPosChange(RequestHandlerTask):
	url = r'/game/gem/pos/change'

	@coroutine
	def run(self):
		if not ObjectFeatureUnlockCSV.isOpen(FeatureDefs.Gem, self.game):
			raise ClientError(ErrDefs.gemNotOpen)
		gemID = self.input.get('gemID', None)  # dbId
		pos = self.input.get('pos', None)

		if gemID is None:
			raise ClientError('gemID miss')
		if pos is None:
			raise ClientError('pos miss')

		gem = self.game.gems.getGem(gemID)
		if not gem:
			raise ClientError('gemID error')
		if not gem.card_db_id:
			raise ClientError('gem not equiped')

		card = self.game.cards.getCard(gem.card_db_id)
		if not card or not card.exist_flag:
			raise ClientError('card not exist')

		oldFightingPoint = card.fighting_point
		# 检查宝石槽是否开启
		self.game.gems.checkGemPosOpenCondition(card, pos)

		oldGemID = card.gems.get(pos, None)
		oldPos = gem.getGemPos()
		if oldGemID:
			card.gems[oldPos] = oldGemID
		else:
			card.gems.pop(oldPos)

		card.gems[pos] = gemID

		ta.card(card, event='card_gem',oldFightingPoint=oldFightingPoint,gem_equip_type='pos_change')


# 宝石 强化（一键强化 需传level）
class GemStrength(RequestHandlerTask):
	url = r'/game/gem/strength'

	@coroutine
	def run(self):
		if not ObjectFeatureUnlockCSV.isOpen(FeatureDefs.Gem, self.game):
			raise ClientError(ErrDefs.gemNotOpen)
		gemID = self.input.get('gemID', None)  # dbId
		level = self.input.get('level', None)
		if gemID is None:
			raise ClientError('param miss')
		gem = self.game.gems.getGem(gemID)
		if not gem:
			raise ClientError('gemID error')
		elif gem.level >= level:
			raise ClientError('level error')

		gem.strengthGem(gemID, level)

		cardID = gem.card_db_id

		if cardID:
			self.game.zawake.onAttrChange()

			card = self.game.cards.getCard(cardID)
			card.calcGemAttrsAddition(card)
			card.onUpdateAttrs()

			self.game.achievement.onTargetTypeCount(AchievementDefs.CardGemQualitySum)


# 宝石 分解
class GemDecompose(RequestHandlerTask):
	url = r'/game/gem/decompose'

	@coroutine
	def run(self):
		if not ObjectFeatureUnlockCSV.isOpen(FeatureDefs.Gem, self.game):
			raise ClientError(ErrDefs.gemNotOpen)
		gemIDs = self.input.get('gemIDs', None)  # [gemID]
		if gemIDs is None:
			raise ClientError('param miss')
		if len(set(gemIDs)) != len(gemIDs):
			raise ClientError('have the sample gemID')
		gems = []
		for gemID in gemIDs:
			gem = self.game.gems.getGem(gemID)
			if not gem:
				raise ClientError('gemIDs error')
			if gem.card_db_id:
				raise ClientError('gem equiped')
			gems.append(gem)

		eff = self.game.gems.decomposeGems(gems)  # ObjectGainAux

		# 删除分解的宝石
		cost = ObjectCostAux(self.game, {})
		cost.setCostGems(gems)
		if not cost.isEnough():
			raise ClientError('gem decompose cost not enough')
		cost.cost(src='gem_decompose')

		# 分解返还精华和金币
		if eff:
			yield effectAutoGain(eff, self.game, self.dbcGame, src='gem_decompose')

		self.write({
			'view': eff.result
		})


# 宝石 重生
class GemRebirth(RequestHandlerTask):
	url = r'/game/gem/rebirth'

	@coroutine
	def run(self):
		if not ObjectFeatureUnlockCSV.isOpen(FeatureDefs.Gem, self.game):
			raise ClientError(ErrDefs.gemNotOpen)
		gemIDs = self.input.get('gemIDs', None)  # [dbId]
		if gemIDs is None:
			raise ClientError('param miss')
		if len(set(gemIDs)) != len(gemIDs):
			raise ClientError('have the sample gemID')
		gems = self.game.gems.getGems(gemIDs)
		if not gems:
			raise ClientError('gemIDs error')

		# 重生
		cardIDSet = set()
		eff = ObjectGainAux(self.game, {})
		for gem in gems:
			eff += self.game.gems.rebirthGem(gem)
			cardID = gem.card_db_id
			if cardID:
				cardIDSet.add(cardID)
		# 获得重生返回的精华和金币
		if eff:
			yield effectAutoGain(eff, self.game, self.dbcGame, src='gem_rebirth')
		for cardID in cardIDSet:
			card = self.game.cards.getCard(cardID)
			card.calcGemAttrsAddition(card)
			card.onUpdateAttrs()

		self.game.zawake.onAttrChange()
		self.game.achievement.onTargetTypeCount(AchievementDefs.CardGemQualitySum)

		self.write({
			'view': {
				'result': eff.result
			}
		})
