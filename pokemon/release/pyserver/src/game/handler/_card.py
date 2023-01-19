#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2014 YouMi Information Technology Inc.

Card Handlers
'''
from framework import nowtime_t
from framework.csv import csv, ErrDefs, ConstDefs
from framework.word_filter import filterName
from framework.log import logger

from game import ServerError, ClientError
from game.handler.inl import effectAutoGain, battleCardsAutoDeployment, battleCardsAutoDeploymentByNatureCheck
from game.handler.task import RequestHandlerTask
from game.object.game import ObjectFeatureUnlockCSV
from game.object.game.card import ObjectCardRebirthFactory, ObjectCardRebirthBase, ObjectCard
from game.object.game.message import ObjectMessageGlobal
from game.object.game.gain import ObjectGainAux, ObjectCostAux
from game.object import FragmentDefs, ItemDefs, EffortValueDefs, PropertySwapDefs, CardResetDefs, FeatureDefs, CardAbilityDefs, AchievementDefs, CardSkinDefs
from game.object.game.costcsv import ObjectCostCSV
from game.globaldata import NValueRecastCountMax
from game.object.game.shop import ObjectCardSkinShop
from game.thinkingdata import ta

from tornado.gen import coroutine
import copy


# 卡牌使用经验药水
class CardExpByUseItem(RequestHandlerTask):
	url = r'/game/card/exp/use_item'

	@coroutine
	def run(self):
		cardID = self.input.get('cardID', None)
		itemID = self.input.get('itemID', None)
		itemCount = self.input.get('itemCount', 1)

		card = self.game.cards.getCard(cardID)
		if card is None:
			raise ClientError('cardID error')
		if itemID is None:
			raise ClientError('itemID error')
		if itemCount <= 0:
			raise ClientError('itemCount error')

		itemEff = self.game.items.getCostItem(itemID, itemCount)
		if itemEff is None:
			raise ClientError('item %d not enough' % itemID)

		itemEff.gain(card=card, src='use_exp_item')

# 卡牌使用经验药水
class CardExpByUseItems(RequestHandlerTask):
	url = r'/game/card/exp/use_items'

	@coroutine
	def run(self):
		cardID = self.input.get('cardID', None)
		items = self.input.get('items', None)

		card = self.game.cards.getCard(cardID)
		if card is None:
			raise ClientError('cardID error')
		if items is None or len(items) == 0:
			raise ClientError('items error')

		isMax = False
		for itemID, itemCount in items.iteritems():
			if itemCount <= 0:
				raise ClientError('item %d count error' % itemID)
			itemEff = self.game.items.getCostItem(itemID, itemCount)
			if itemEff is None:
				raise ClientError('item %d not enough' % itemID)

			itemEff.gain(card = card, src='use_exp_item')
			if itemCount != itemEff.count:
				isMax = True
				break

# 卡牌进阶
class CardAdvance(RequestHandlerTask):
	url = r'/game/card/advance'

	@coroutine
	def run(self):
		cardID = self.input.get('cardID', None)
		count = self.input.get('count', 1)
		card = self.game.cards.getCard(cardID)
		if card is None:
			raise ClientError('cardID error')

		self.game.badge.resetBadgeCache(card)
		card.cardAdvance(count)
		self.game.zawake.onAttrChange()

# 卡牌技能升级
class CardSkillLevelUp(RequestHandlerTask):
	url = r'/game/card/skill/level/up'

	@coroutine
	def run(self):
		cardID = self.input.get('cardID', None)
		skillID = self.input.get('skillID', None)
		addLevel = self.input.get('addLevel', None)

		card = self.game.cards.getCard(cardID)
		if card is None:
			raise ClientError('cardID error')
		if skillID is None:
			raise ClientError('skillID error')
		if (not isinstance(addLevel, int)) or (addLevel <= 0):
			raise ClientError('addLevel error')
		if skillID not in card.skills:
			raise ServerError('no this skillID %d' % skillID)
		if skillID not in csv.skill:
			raise ServerError('no this skillID %d csv' % skillID)

		if skillID in card.starSkillList:
			card.updateStarSkill(skillID, addLevel)
		else:
			card.updateSkill(skillID, addLevel)


# 卡牌升星
class CardStar(RequestHandlerTask):
	url = r'/game/card/star'

	@coroutine
	def run(self):
		cardID = self.input.get('cardID', None)
		costCardIDs = self.input.get('costCardIDs', None)
		card = self.game.cards.getCard(cardID)
		if card is None:
			raise ClientError('param error')
		csvStar = ObjectCard.CardsMarkStarMap.get((card.starTypeID, card.star), None)

		costCards = self.game.cards.getCostCards(costCardIDs, cardID)
		for costCard in costCards:
			if costCard.markID != card.markID and costCard.card_id not in csvStar.universalCards:
				raise ClientError('costCards error')
		yield battleCardsAutoDeployment(costCardIDs, self.game, **self.rpcs)

		self.game.badge.resetBadgeCache(card)
		card.riseStar(costCards)
		self.game.zawake.onAttrChange()

# 卡牌进化
class CardDevelop(RequestHandlerTask):
	url = r'/game/card/develop'

	@coroutine
	def run(self):
		cardID = self.input.get('cardID', None)
		branch = self.input.get('branch', None)
		card = self.game.cards.getCard(cardID)
		if card is None:
			raise ClientError('cardID error')
		oldCardID = card.card_id

		oldNatures = (card.natureType, card.natureType2)
		card.riseDevelop(branch)
		self.game.pokedex.addPokedex([card.id])
		newNatures = (card.natureType, card.natureType2)

		yield battleCardsAutoDeploymentByNatureCheck(self.game, cardID, oldNatures, newNatures, **self.rpcs)

		zawakeIDOld = csv.cards[oldCardID].zawakeID
		zawakeIDNew = csv.cards[card.card_id].zawakeID
		if zawakeIDOld and zawakeIDOld != zawakeIDNew:
			eff = self.game.zawake.reset(zawakeIDOld, auto=True)
			if eff:
				yield effectAutoGain(eff, self.game, self.dbcGame, src='zawake_reset_from_develop')
				self.write({"view": eff.result})


# 卡牌切换分支
class CardSwitchBranch(RequestHandlerTask):
	url = r'/game/card/switch/branch'

	@coroutine
	def run(self):
		cardID = self.input.get('cardID', None)
		branch = self.input.get('branch', None)
		if branch is None:
			raise ClientError('param error')
		card = self.game.cards.getCard(cardID)
		if card is None:
			raise ClientError('cardID error')
		oldCardID = card.card_id

		if not ObjectFeatureUnlockCSV.isOpen(FeatureDefs.CardSwitchBranch, self.game):
			raise ClientError(ErrDefs.levelLessNoOpened)

		oldNatures = (card.natureType, card.natureType2)
		card.switchBranch(branch)
		self.game.pokedex.addPokedex([card.id])
		newNatures = (card.natureType, card.natureType2)

		yield battleCardsAutoDeploymentByNatureCheck(self.game, cardID, oldNatures, newNatures, **self.rpcs)

		zawakeIDOld = csv.cards[oldCardID].zawakeID
		zawakeIDNew = csv.cards[card.card_id].zawakeID
		if zawakeIDOld and zawakeIDOld != zawakeIDNew:
			eff = self.game.zawake.reset(zawakeIDOld, auto=True)
			if eff:
				yield effectAutoGain(eff, self.game, self.dbcGame, src='zawake_reset_from_branch_switch')
				self.write({"view": eff.result})


# 卡牌使用好感度经验药水
class CardFeelByUseItems(RequestHandlerTask):
	url = r'/game/card/feel/use_items'

	@coroutine
	def run(self):
		markID = self.input.get('markID', None)
		items = self.input.get('items', None)

		if items is None or len(items) == 0:
			raise ClientError('items error')
		if self.game.feels.isFeelExpUp(markID):
			raise ClientError(ErrDefs.cardFeelLevelUp)

		# 道具不足 客户端提供的数量有问题
		if not self.game.items.isEnough(items):
			raise ClientError(ErrDefs.itemsCountError)

		cnt = 0
		for itemID, count in items.iteritems():
			if count <= 0:
				raise ClientError('item %d count error' % itemID)
			itemEff = self.game.items.getCostItem(itemID, count)
			if itemEff is None:
				raise ClientError('item %d not enough' % itemID)
			cnt += count
			itemEff.gain(markID=markID, src='feel_use_item')
		self.game.feels.updateRelatedCards()
		self.game.zawake.onAttrChange()

# 卡牌好感度一键到底
class CardFeelToMax(RequestHandlerTask):
	url = r'/game/card/feel/tomax'

	@coroutine
	def run(self):
		markID = self.input.get('markID', None)
		flag = self.input.get('flag', False) # 仅用通用礼物
		if markID is None:
			raise ClientError('markID error')
		if self.game.feels.isFeelExpUp(markID):
			raise ClientError(ErrDefs.cardFeelLevelUp)

		cnt = 0
		for itemID in csv.cards[markID].feelItems:
			if flag and csv.items[itemID].specialArgsMap.get('special', False):
				continue
			count = self.game.items.getItemCount(itemID)
			if count > 0:
				eff = self.game.items.getCostItem(itemID, count)
				eff.gain(markID=markID, src='feel_tomax')
				remain = self.game.items.getItemCount(itemID)
				cnt += count - remain
				if remain > 0:
					break
		self.game.feels.updateRelatedCards()
		self.game.zawake.onAttrChange()


# 卡牌重生
class CardRebirth(RequestHandlerTask):
	url = r'/game/card/rebirth'

	@coroutine
	def run(self):
		cardID = self.input.get('cardID', None)
		card = self.game.cards.getCard(cardID)
		if card is None:
			raise ClientError('cardID error')
		if card.locked:
			raise ClientError('card is locking')
		# 重生
		effAll = card.getRebirthEff()
		if effAll:
			yield effectAutoGain(effAll, self.game, self.dbcGame, src='card_rebirth')

		self.game.badge.resetBadgeCache(card)
		self.game.zawake.onAttrChange()

		card.calcUnitAttrsAddition(card)
		card.calcStarAttrsAddition(card)
		card.calcAdvanceAttrsAddition(card)
		card.calcEquipsAttrsAddition(card)
		card.calcPassiveSkillAttrsAddition(card)
		card.calcAbilityAttrsAddition(card)
		card.calcEquipSignetAdvanceAttrsAddition(card)
		card.onUpdateAttrs()

		self.write({
			'view': {
				'result': effAll.result
			}
		})


# 卡牌分解
class CardDecompose(RequestHandlerTask):
	url = r'/game/card/decompose'

	@coroutine
	def run(self):
		cardIDs = self.input.get('cardIDs', None)
		if cardIDs is None:
			raise ClientError('param miss')

		cards = self.game.cards.getCostCards(cardIDs)
		if len(cards) > 5:
			raise ClientError('card error')
		yield battleCardsAutoDeployment(cardIDs, self.game, **self.rpcs)

		cost = ObjectCostAux(self.game, {})
		cost.setCostCards(cards) # 提前，getDecomposeEff 里面会重新设置 star

		eff = ObjectGainAux(self.game, {})
		for card in cards:
			eff += card.getRebirthEff()
			eff += card.getDecomposeEff()

		# 消耗卡牌
		cost.cost(src='card_decompose')

		if eff:
			yield effectAutoGain(eff, self.game, self.dbcGame, src='card_decompose')

		self.game.zawake.onAttrChange()
		self.write({
			'view': {
				'result': eff.result
			}
		})


# 购买皮肤
class CardSkinBuy(RequestHandlerTask):
	url = r'/game/card/skin/buy'

	@coroutine
	def run(self):
		# 1.先检查skin合法
		skinID = self.input.get('skinID', None)
		# itemID = self.input.get('itemID', None)
		if skinID is None or skinID not in csv.card_skin:
			raise ClientError('skinID error')

		eff = self.game.role.buySkin(skinID)
		if eff:
			yield effectAutoGain(eff, self.game, self.dbcGame, src='card_skin_buy')

# 使用皮肤/激活限时皮肤
class CardSkinUse(RequestHandlerTask):
	url = r'/game/card/skin/use'

	@coroutine
	def run(self):
		skinID = self.input.get('skinID', None)
		cardID = self.input.get('cardID', None)

		if skinID is None:
			raise ClientError('skinID error')

		card = self.game.cards.getCard(cardID)
		if card is None:
			raise ClientError("carID error")

		oldSkinID = card.skin_id
		if skinID == 0:
			# 使用默认皮肤
			card.skin_id = 0
		elif skinID in self.game.role.skins:
			# 检查皮肤是否过期
			if self.game.role.skins[skinID] != 0 and self.game.role.skins[skinID] <= nowtime_t():
				raise ClientError('skin expired')

			# 检查对应card
			if skinID in csv.cards[card.card_id].skinSkillMap:
				card.skin_id = skinID
			else:
				raise ClientError('skinID error')
		else:
			raise ClientError(ErrDefs.skinNotOwn)

# 卡牌重命名
class CardRename(RequestHandlerTask):
	url = r'/game/card/rename'

	@coroutine
	def run(self):
		cardID = self.input.get('cardID', None)
		name = self.input.get('name', None)
		if name is None:
			raise ClientError('name is miss')
		card = self.game.cards.getCard(cardID)
		if card is None:
			raise ClientError('cardID error')
		uname = name.decode('utf8')
		# if len(name) > 21:
		# 	raise ClientError(ErrDefs.roleNameTooLong)
		if filterName(uname):
			raise ClientError(ErrDefs.roleNameInvalid)
		if card.name != name:
			cost = ObjectCostAux(self.game, {'rmb': ConstDefs.cardRenameRMBCost})
			if not cost.isEnough():
				raise ClientError(ErrDefs.roleNameRMBNotEnough)
			cost.cost(src='card_rename')
			card.name = name
			self.game.cards.deploymentForUnionTraining.put(card.id)
			self.write({'view': {'result': 'ok'}})
		else:
			self.write({'view': {'result': 'ok'}})

# 卡牌锁定切换
class CardLockedSwitch(RequestHandlerTask):
	url = r'/game/card/locked/switch'

	@coroutine
	def run(self):
		cardID = self.input.get('cardID', None)
		card = self.game.cards.getCard(cardID)
		if card is None:
			raise ClientError('cardID error')
		card.locked = not card.locked

# 卡牌个体值锁定状态切换
class CardNValueLockedSwitch(RequestHandlerTask):
	url = r'/game/card/nvalue/locked/switch'

	@coroutine
	def run(self):
		cardID = self.input.get('cardID', None)
		attr = self.input.get('attr', None)
		card = self.game.cards.getCard(cardID)
		if card is None:
			raise ClientError('cardID error')

		lockedCount = 0
		for k in card.nvalue_locked:
			if card.nvalue_locked[k]:
				lockedCount += 1
		if lockedCount >= NValueRecastCountMax and not card.nvalue_locked.get(attr, False):
			raise ClientError("can not lock")

		if attr in card.nvalue_locked:
			card.nvalue_locked[attr] = not card.nvalue_locked[attr]
		else:
			card.nvalue_locked[attr] = True
		card.nvalue_locknum_recast_total = 0
		card.nvalue_locknum_recast_process = 0


# 卡牌个体值洗炼
class CardNValueRecast(RequestHandlerTask):
	url = r'/game/card/nvalue/recast'

	@coroutine
	def run(self):
		cardID = self.input.get('cardID', None)
		card = self.game.cards.getCard(cardID)
		if card is None:
			raise ClientError('cardID error')
		lockedCount = 0
		for k in card.nvalue_locked:
			if card.nvalue_locked[k]:
				lockedCount += 1
		if lockedCount >= NValueRecastCountMax:
			raise ClientError('locked all can not recast')
		cost = ObjectCostAux(self.game, card.CardRecastMap[lockedCount].costItems)
		if not cost.isEnough():
			raise ClientError("recast item not enough")
		cost.cost(src='recast_cost')
		oldFightingPoint = card.fighting_point
		card.nvalueRecast()
		card.nvalue_cost_rmb_total += cost.rmb
		self.game.badge.resetBadgeCache(card)
		self.game.zawake.onAttrChange()
		card.calcNValueAttrsAddition(card)
		card.onUpdateAttrs()

		ta.card(card, event='nvalue',oldFightingPoint=oldFightingPoint,cost=cost)


# 卡牌努力值培养
class CardEffortTrain(RequestHandlerTask):
	url = r'/game/card/effort/train'

	@coroutine
	def run(self):
		cardID = self.input.get('cardID', None)
		trainType = self.input.get('trainType', None)
		trainTime = self.input.get('trainTime', None)

		if any([x is None for x in [cardID, trainType, trainTime]]):
			raise ClientError('param miss')
		card = self.game.cards.getCard(cardID)
		if card is None:
			raise ClientError('cardID error')
		if trainTime <= 0:
			raise ClientError('trainTime error')
		if trainType != EffortValueDefs.GeneralTrain and trainType != EffortValueDefs.SeniorTrain:
			raise ClientError("trainType error")

		# 当阶段阶段培养满了
		if card.isEnoughEffortAdvance(card.effort_advance):
			raise ClientError('effort need advance')

		# 最大阶段能突破 说明已经培养满了
		if card.isEnoughEffortAdvance(card.advanceLimit):
			raise ClientError('effort train max')

		# 计算消耗 返回可培养的次数
		time = card.costEffortTrain(trainType, trainTime)
		# 努力值培养
		result = card.effortTrain(trainType, time)

		self.game.zawake.onAttrChange()

		self.write({
			'view': {
				'result': result
			}
		})

# 卡牌努力值培养保存
class CardEffortSave(RequestHandlerTask):
	url = r'/game/card/effort/save'

	@coroutine
	def run(self):
		# 传客户端选择好的 努力值索引。
		effortIndexs = self.input.get('effortIndexs', None)
		cardID = self.input.get('cardID', None)
		if any([x is None for x in [cardID, effortIndexs]]):
			raise ClientError('param miss')
		card = self.game.cards.getCard(cardID)
		if card is None:
			raise ClientError('cardID error')
		oldValues = card.effort_values.values()
		oldFightingPoint = card.fighting_point
		card.saveEffortValue(effortIndexs)
		card.calcEffortAttrsAddition(card)
		card.onUpdateAttrs()
		ta.card(card, event='effort_train',oldValues=oldValues,oldFightingPoint=oldFightingPoint)


# 卡牌努力值突破
class CardEffortAdvance(RequestHandlerTask):
	url = r'/game/card/effort/advance'

	@coroutine
	def run(self):
		cardID = self.input.get('cardID', None)
		if cardID is None:
			raise ClientError('param miss')
		card = self.game.cards.getCard(cardID)
		if card is None:
			raise ClientError('cardID error')
		if card.effort_advance == card.advanceLimit:
			raise ClientError('effort advance is max')
		values = ObjectCard.CardEffortAdvanceMap.get((card.effortSeqID, card.effort_advance + 1), {})
		if card.level < values.get('needLevel', 0):
			raise ClientError('level is not enough ')
		if not card.isEnoughEffortAdvance(card.effort_advance):
			raise ClientError('effort can not advance')
		card.effort_advance = card.effort_advance + 1
		self.game.zawake.onAttrChange()
		card.calcEffortAdvanceAttrsAddition(card)
		card.onUpdateAttrs()


# 卡牌继承（交换）
class CardPropertySwap(RequestHandlerTask):
	url = r'/game/card/property/swap'

	@coroutine
	def run(self):
		cardID = self.input.get('cardID', None)
		targetCardID = self.input.get('targetCardID', None)
		swapType = self.input.get('swapType', None)
		if any([x is None for x in [cardID, targetCardID, swapType]]):
			raise ClientError('param miss')
		card = self.game.cards.getCard(cardID)
		targetCard = self.game.cards.getCard(targetCardID)
		if card is None or targetCard is None:
			raise ClientError('cardID or targetCardID error')

		card.propertySwap(targetCard, swapType)
		self.game.zawake.onAttrChange()

		# 两个卡牌属性加成都更新
		if swapType == PropertySwapDefs.EffortSwap:  # 努力值
			card.calcEffortAttrsAddition(card)
			targetCard.calcEffortAttrsAddition(targetCard)
			card.calcEffortAdvanceAttrsAddition(card)
			targetCard.calcEffortAdvanceAttrsAddition(targetCard)
		elif swapType == PropertySwapDefs.NvalueSwap:  # 个体值
			self.game.badge.resetBadgeCache(card)
			self.game.badge.resetBadgeCache(targetCard)
			card.calcNValueAttrsAddition(card)
			targetCard.calcNValueAttrsAddition(targetCard)
		else:
			oldFightingPoint = card.fighting_point
			previousCharacter = card.character
			card.calcCharacterAddtsAddition(card)
			targetCard.calcCharacterAddtsAddition(targetCard)
			ta.card(card, event='card_character_swap',oldFightingPoint=oldFightingPoint,target_card_id=targetCard.card_id,swap_type=swapType,previous_character=previousCharacter)
		with self.game.cards.fightingPointChangeParallel():
			card.onUpdateAttrs()
			targetCard.onUpdateAttrs()

# 卡牌好感度交换
class CardFeelSwap(RequestHandlerTask):
	url = r'/game/card/feel/swap'

	@coroutine
	def run(self):
		cardID = self.input.get('cardID', None)
		targetCardID = self.input.get('targetCardID', None)
		if any([x is None for x in [cardID, targetCardID]]):
			raise ClientError('param miss')

		if cardID not in self.game.role.pokedex or targetCardID not in self.game.role.pokedex:
			raise ClientError('card not in pokedex')

		self.game.feels.swapFeel(cardID, targetCardID)
		self.game.feels.updateRelatedCards()
		self.game.zawake.onAttrChange()

# 卡牌分享
class CardShare(RequestHandlerTask):
	url = r'/game/card/share'

	@coroutine
	def run(self):
		if not ObjectFeatureUnlockCSV.isOpen(FeatureDefs.CardShare, self.game):
			raise ClientError('locked')
		if self.game.role.silent_flag:
			raise ClientError(ErrDefs.roleBeenSilent)
		cardID = self.input.get('cardID', None)
		shareType = self.input.get('from', None)

		card = self.game.cards.getCard(cardID)
		if card is None:
			raise ClientError('cardID error')
		if shareType not in ['world', 'union']:
			raise ClientError('shareType error')
		if self.game.dailyRecord.card_share_times >= ConstDefs.shareTimesLimit:
			raise ClientError('share times is limit')

		if shareType == 'world':
			ObjectMessageGlobal.worldCardShareMsg(self.game, card)
		elif shareType == 'union':
			ObjectMessageGlobal.unionCardShareMsg(self.game, card)
		self.game.dailyRecord.card_share_times += 1


# 卡牌特性 激活/强化
class CardAbilityStrength(RequestHandlerTask):
	url = r'/game/card/ability/strength'

	@coroutine
	def run(self):
		if not ObjectFeatureUnlockCSV.isOpen(FeatureDefs.CardAbility, self.game):
			raise ClientError('locked')
		cardID = self.input.get('cardID', None)
		position = self.input.get('position', None)
		upLevel = self.input.get('upLevel', 1)  # 提升的等级 不传则默认1级
		if cardID is None or position is None:
			raise ClientError('param miss')
		if upLevel <= 0:
			raise ClientError('upLevel error')
		card = self.game.cards.getCard(cardID)
		oldFightingPoint = card.fighting_point
		# 特性 激活/强化
		card.abilityStrength(position, upLevel)

		cfg = card.CardAbilityMap[(card.abilitySeqID, position)]
		selfFlag = False
		allFlag = False
		for i in xrange(1, 99):
			at = 'attrType%d' % i
			if at not in cfg or not cfg[at]:
				break
			if cfg['attrAddType%d' % i] == CardAbilityDefs.AttrAddOne:  # 自身
				selfFlag = True
			elif cfg['attrAddType%d' % i] == CardAbilityDefs.AttrAddAll:  # 全体
				if card.abilities.get(position, 0) > self.game.cards.getMaxAbilityLevel(card.markID, position):
					allFlag = True
			elif cfg['attrAddType%d' % i] == CardAbilityDefs.AttrAddScene:  # 场景
				continue
		if allFlag:
			self.game.cards.onCardsAbilityChange()
		# 自身属性加成
		if selfFlag:
			card.onUpdateAbility()

		ta.card(card, event='ability',oldFightingPoint=oldFightingPoint,position=position)

# 卡牌使用性格道具
class CardCharacterByUseItems(RequestHandlerTask):
	url = r'/game/card/character/use_items'

	@coroutine
	def run(self):
		cardID = self.input.get('cardID', None)
		itemID = self.input.get('itemID', None)

		card = self.game.cards.getCard(cardID)
		if card is None:
			raise ClientError('cardID error')

		itemEff = self.game.items.getCostItem(itemID, 1)
		if itemEff is None:
			raise ClientError('item %d not enough' % itemID)
		cost = ObjectCostAux(self.game, {'rmb': ConstDefs.characterSwapCostRmb})
		if not cost.isEnough():
			raise ClientError('cost not enough')
		cost.cost(src='use_character_items')
		itemEff.gain(card = card, src='use_character_items')

		card.calcCharacterAddtsAddition(card)
		card.onUpdateAttrs()

# 卡牌选择自然属性
class CardNatureChoose(RequestHandlerTask):
	url = r'/game/card/nature/choose'

	@coroutine
	def run(self):
		cardID = self.input.get('cardID', None)
		choose = self.input.get('choose', None)

		card = self.game.cards.getCard(cardID)
		if card is None:
			raise ClientError('cardID error')
		if choose not in (1, 2):
			raise ClientError('choose error')
		if choose == 2 and not card.natureType2:
			raise ClientError('choose error')

		card.nature_choose = choose

# 满星技能卡牌兑换
class CardStarSkillCardExchange(RequestHandlerTask):
	url = r'/game/card/star/skill/card/exchange'

	@coroutine
	def run(self):
		cardID = self.input.get('cardID', None)
		costCardIDs = self.input.get('costCardIDs', None)
		card = self.game.cards.getCard(cardID)
		if card is None:
			raise ClientError('param error')
		if card.star < 12:
			raise ClientError("card star not enough")
		cfg = csv.card_star_skill[card.starSkillSeqID]
		if cfg is None:
			raise ClientError("config not exists")
		costCards = self.game.cards.getCostCards(costCardIDs, cardID)
		for costCard in costCards:
			if costCard.markID != card.markID and costCard.card_id not in cfg.universalCards:
				raise ClientError('costCards error')
		yield battleCardsAutoDeployment(costCardIDs, self.game, **self.rpcs)

		eff = card.addStarSkillPointByCostCards(costCards)
		yield effectAutoGain(eff, self.game, self.dbcGame, src='star_skill_card_exchange')

		self.write({"view": eff.result})

# 满星技能碎片兑换
class CardStarSkillFragExchange(RequestHandlerTask):
	url = r'/game/card/star/skill/frag/exchange'

	@coroutine
	def run(self):
		cardID = self.input.get('cardID', None)
		costFragID = self.input.get('costFragID', None)
		costFragNum = self.input.get('costFragNum', None)
		if not costFragID or costFragNum is None:
			raise ClientError('param miss')
		card = self.game.cards.getCard(cardID)
		if card is None:
			raise ClientError('param error')
		if card.star < 12:
			raise ClientError("card star not enough")
		cfg = csv.cards[card.card_id]
		if costFragID not in (cfg.fragID, cfg.zawakeFragID):
			raise ClientError('cost fragID error')

		cost = ObjectCostAux(self.game, {costFragID: costFragNum})
		if not cost.isEnough():
			raise ClientError('cost not enough')
		cost.cost(src='star_skill_decompose')

		eff = card.addStarSkillPointByCostfrag(costFragNum)
		yield effectAutoGain(eff, self.game, self.dbcGame, src='star_skill_frag_exchange')

		self.write({"view": eff.result})

# 满星技能重置
class CardStarSkillReset(RequestHandlerTask):
	url = r'/game/card/star/skill/reset'

	@coroutine
	def run(self):
		cardID = self.input.get('cardID', None)
		if cardID is None:
			raise ClientError('param miss')
		card = self.game.cards.getCard(cardID)
		if card is None:
			raise ClientError('param error')
		if card.star < 12:
			raise ClientError('card star not enough')

		cost = ObjectCostAux(self.game, {'rmb': ConstDefs.cardStarSkillResetCostRMB})
		if not cost.isEnough():
			raise ClientError('cost not enough')
		cost.cost(src="star_skill_reset")

		eff = card.starSkillReset()
		yield effectAutoGain(eff, self.game, self.dbcGame, src='star_skill_reset')

		self.write({"view": eff.result})

# 精灵评论
class CardCommentList(RequestHandlerTask):
	url = r'/game/card/comment/list'

	@coroutine
	def run(self):
		cardID = self.input.get('cardID', None)
		offset = self.input.get('offset', 0)
		size = self.input.get('size', 50)
		if cardID is None or offset is None or size is None:
			raise ClientError('param miss')

		markID = csv.cards[cardID].cardMarkID
		view = yield self.rpcCardComment.call_async_timeout("CardCommentList", 15, {
			"role": self.game.role.makeCardCommentRoleModel(),
			"markID": markID,
			'offset': offset,
			'size': size
		})

		self.write({"view": view})

# 精灵评论
class CardCommentSend(RequestHandlerTask):
	url = r'/game/card/comment/send'

	@coroutine
	def run(self):
		if not ObjectFeatureUnlockCSV.isOpen(FeatureDefs.CardPostComment, self.game):
			raise ClientError('unlock limit')

		if self.game.role.silent_flag:
			raise ClientError(ErrDefs.roleBeenSilent)

		markNum = 0
		for counter in self.game.dailyRecord.card_comment_counter.itervalues():
			if counter >= ConstDefs.cardCommentDailyMarkSendTimes:
				markNum += 1
		if markNum >= ConstDefs.cardCommentDailyMarkNum:
			raise ClientError('card comment daily maik num limit')

		cardID = self.input.get('cardID', None)
		content = self.input.get('content', None)
		if cardID is None or content is None:
			raise ClientError('param miss')
		if cardID not in csv.pokedex or not csv.pokedex[cardID].isOpen:
			raise ClientError("card not open")

		markID = csv.cards[cardID].cardMarkID
		if self.game.dailyRecord.card_comment_counter.get(markID, 0) >= ConstDefs.cardCommentDailyMarkSendTimes:
			raise ClientError('card comment daily mark send times limit')

		ucontent = content.decode('utf8')
		if len(ucontent) > ConstDefs.cardCommentWordCount:
			raise ClientError("card comment content too long")
		if filterName(ucontent):
			raise ClientError("card comment content invalid")

		self.game.dailyRecord.card_comment_counter[markID] = self.game.dailyRecord.card_comment_counter.get(markID, 0) + 1

		commentID = yield self.rpcCardComment.call_async_timeout("CardCommentSend", 15, self.game.role.makeCardCommentRoleModel(), markID, content)

		self.write({'view': {'commentID': commentID}})

# 精灵评论删除
class CardCommentDel(RequestHandlerTask):
	url = r'/game/card/comment/del'

	@coroutine
	def run(self):
		commentID = self.input.get('commentID', None)
		if commentID is None:
			raise ClientError('param miss')

		yield self.rpcCardComment.call_async_timeout("CardCommentDel", 15, self.game.role.makeCardCommentRoleModel(), commentID)

# 对精灵评论评价
class CardCommentEvaluate(RequestHandlerTask):
	url = r'/game/card/comment/evaluate'

	@coroutine
	def run(self):
		commentID = self.input.get('commentID', None)
		evaluateType = self.input.get('evaluateType', None)
		if commentID is None or evaluateType is None:
			raise ClientError('param miss')

		# like 点赞
		# dislike 踩
		# revokeLike 撤销点赞
		# revokeDislike 撤销踩
		if evaluateType not in ('like', 'dislike', 'revokeLike', 'revokeDislike'):
			raise ClientError('param error')

		yield self.rpcCardComment.call_async_timeout("CardCommentEvaluate", 15, self.game.role.makeCardCommentRoleModel(), commentID, evaluateType)

# 获取精灵评分
class CardCommentScore(RequestHandlerTask):
	url = r'/game/card/score/get'

	@coroutine
	def run(self):
		cardID = self.input.get('cardID', None)
		if cardID is None:
			raise ClientError('param miss')

		markID = csv.cards[cardID].cardMarkID
		resp = yield self.rpcCardScore.call_async_timeout("CardScoreGet", 15, self.game.role.id, markID)

		self.write({'view': resp})

# 精灵评分
class CardCommentscoreSend(RequestHandlerTask):
	url = r'/game/card/score/send'

	@coroutine
	def run(self):
		cardID = self.input.get('cardID', None)
		score = self.input.get('score', None)
		if cardID is None or score is None:
			raise ClientError('param miss')
		if cardID not in csv.pokedex or not csv.pokedex[cardID].isOpen:
			raise ClientError("card not open")
		if not isinstance(score, int) or score <= 0 or score > 10:
			raise ClientError("score error")

		markID = csv.cards[cardID].cardMarkID
		if not self.game.pokedex.isExistedByMarkID(markID):
			raise ClientError('pokedex not active')

		if self.game.dailyRecord.card_score_counter.get(markID, 0) >= ConstDefs.cardScoreDailyChangeTimes:
			raise ClientError('card score daily cahnge times limit')

		self.game.dailyRecord.card_score_counter[markID] = self.game.dailyRecord.card_score_counter.get(markID, 0) + 1

		yield self.rpcCardScore.call_async_timeout("CardScoreSend", 15, self.game.role.id, self.game.role.areaKey, markID, score)

# 精灵评分排行榜
class CardCommentPointRank(RequestHandlerTask):
	url = r'/game/card/score/rank'

	@coroutine
	def run(self):
		offset = self.input.get('offset', 0)
		size = self.input.get('size', 50)

		ranks = yield self.rpcCardScore.call_async_timeout("CardScoreRank", 15, offset, size)

		self.write({"view": {"ranks": ranks}})

# 精灵战力排行榜
class CardFightRank(RequestHandlerTask):
	url = r'/game/card/fight/rank'

	@coroutine
	def run(self):
		cardID = self.input.get('cardID', None)
		offset = self.input.get('offset', 0)
		size = self.input.get('size', 50)
		if cardID is None:
			raise ClientError('param miss')

		markID = csv.cards[cardID].cardMarkID
		resp = yield self.rpcCardFight.call_async("CardFightRank", self.game.role.makeCardFightRoleModel(), markID, offset, size)

		self.write({"view": resp})

# 精灵皮肤商店购买
class CardSkinShopBuy(RequestHandlerTask):
	url = r'/game/card/skin/shop/buy'

	@coroutine
	def run(self):
		csvID = self.input.get('csvID', None)
		count = self.input.get('count', 1)
		if csvID is None:
			raise ClientError('param miss')
		if count <= 0:
			raise ClientError('param error')

		cardSkinShop = ObjectCardSkinShop(self.game)
		eff = cardSkinShop.buyItem(csvID, count, src='card_skin_shop_buy')
		yield effectAutoGain(eff, self.game, self.dbcGame, src='card_skin_shop_buy')

# Z觉醒培养
class ZawakeStrength(RequestHandlerTask):
	url = r'/game/card/zawake/strength'

	@coroutine
	def run(self):
		zawakeID = self.input.get('zawakeID', None)
		stage = self.input.get('stage', None)
		level = self.input.get('level', None)

		if not all((zawakeID, stage, level)):
			raise ClientError('param miss')

		self.game.zawake.strength(zawakeID, stage, level)
		self.game.zawake.onAttrChange()

# Z觉醒重置
class ZawakeReset(RequestHandlerTask):
	url = r'/game/card/zawake/reset'

	@coroutine
	def run(self):
		zawakeID = self.input.get('zawakeID', None)

		if not zawakeID:
			raise ClientError('param miss')

		eff = self.game.zawake.reset(zawakeID)
		if eff:
			yield effectAutoGain(eff, self.game, self.dbcGame, src='zawake_reset')
		self.game.zawake.onAttrChange()

# Z觉醒兑换
class ZawakeExchange(RequestHandlerTask):
	url = r'/game/card/zawake/exchange'

	@coroutine
	def run(self):
		csvID = self.input.get('csvID', None)
		cardID = self.input.get('cardID', None)
		fragID = self.input.get('fragID', None)
		num = self.input.get('num', None)

		if not csvID:
			raise ClientError('param miss')

		if not (cardID or (fragID and num)):
			raise ClientError('param miss')

		if cardID and (fragID or num):
			raise ClientError('too many params')

		if cardID:
			costCards = self.game.cards.getCostCards([cardID])  # 判断一些前置条件
			yield battleCardsAutoDeployment([cardID], self.game, **self.rpcs)

			eff = self.game.zawake.exchangeCard(csvID, costCards[0])
		else:  # fragID and num
			eff = self.game.zawake.exchangeFrag(csvID, fragID, num)
		if eff:
			yield effectAutoGain(eff, self.game, self.dbcGame, src='zawake_exchange')
			self.write({"view": eff.result})

# Z觉醒退出
class ZawakeQuit(RequestHandlerTask):
	url = r'/game/card/zawake/quit'

	@coroutine
	def run(self):
		self.game.zawake.onAttrChange()
