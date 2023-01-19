#!/usr/bin/python
# coding=utf-8

from framework import str2num_t
from framework.csv import csv
from framework.log import logger
from framework.object import ObjectBase
from game import ClientError
from game.object import BadgeDefs
from game.object.game.calculator import zeros
from game.object.game.gain import ObjectCostAux


#
# ObjectBadge
#
class ObjectBadge(ObjectBase):

	def set(self):
		self._badges = self.game.role.badges
		return ObjectBase.set(self)

	def init(self):
		self._effects = None
		return ObjectBase.init(self)

	def isBadgeOpen(self, badgeID):
		'''
		勋章是否开启
		'''
		if badgeID in self._badges:
			return True

		cfg = csv.gym_badge.badge[badgeID]
		if cfg.preBadgeID:
			if cfg.preBadgeType == BadgeDefs.AwakeLevel:
				return self._badges.get(cfg.preBadgeID, {}).get('awake', 0) >= cfg.preLevel
			else:
				levels = self._badges.get(cfg.preBadgeID, {}).get('talents', {}).values()
				if levels:
					return min(levels) >= cfg.preLevel
				else:
					return False
		return True

	def getBadge(self, badgeID):
		'''
		勋章数据
		'''
		badge = self._badges.setdefault(badgeID, {'awake': 0, 'talents': {}, 'guards': {}, 'positions': {}})
		positions = badge.get('positions', {})
		cfg = csv.gym_badge.badge[badgeID]
		if len(positions) == len(cfg.guardIDs):
			return badge

		for guardID in cfg.guardIDs:
			guardCfg = csv.gym_badge.guard[guardID]
			if guardID in positions:
				continue
			if guardCfg.isOpen and guardCfg.openCondition == BadgeDefs.BadgeAwake and guardCfg.openParam == 0:
				positions[guardID] = True
		return badge

	def talentLevelUp(self, badgeID, times=1):
		'''
		勋章天赋升级
		'''
		# 勋章是否解锁
		if not self.isBadgeOpen(badgeID):
			raise ClientError('badge locked')

		cfg = csv.gym_badge.badge[badgeID]

		badge = self.getBadge(badgeID)
		talents = badge.get('talents', {})
		for _ in xrange(times):
			talentID = cfg.talentIDs[0]  # 待升级的天赋
			currentMinLevel = talents.get(cfg.talentIDs[-1], 0)  # 末尾的天赋等级是当前最低等级

			# 是否所有天赋已满级
			if currentMinLevel >= cfg.talentMaxLevel:
				break

			if talents:
				for csvID in cfg.talentIDs:
					level = talents.get(csvID, 0)
					if level == currentMinLevel:
						talentID = csvID
						break

			# 消耗
			talentCfg = csv.gym_badge.talent[talentID]
			costItems = csv.gym_badge.talent_cost[talents.get(talentID, 0)]['cost%d' % talentCfg.costSeqID]
			cost = ObjectCostAux(self.game, costItems)
			if not cost.isEnough():
				break
			cost.cost(src='badge_talent_level_up')
			talents[talentID] = talents.get(talentID, 0) + 1

		self._effects = None

	def badgeAwake(self, badgeID):
		'''
		徽章觉醒
		'''
		# 勋章是否解锁
		if not self.isBadgeOpen(badgeID):
			raise ClientError('badge locked')

		cfg = csv.gym_badge.badge[badgeID]
		badge = self.getBadge(badgeID)
		awake = badge.get('awake', 0)

		# 是否已觉醒到最大等级
		if awake >= cfg.awakeMaxLevel:
			raise ClientError('badge awake level max')
		# 是否满足觉醒条件
		talents = badge.get('talents', {})
		# 按顺序依次升级，末尾的为当前天赋最低等级
		if talents.get(cfg.talentIDs[-1], 0) < cfg.preTalentLevel[awake]:
			raise ClientError('awake condition not satisfied')

		# 消耗
		awakeCost = csv.gym_badge.awake_cost[awake]['cost%d' % cfg.awakeCostSeqID]
		cost = ObjectCostAux(self.game, awakeCost)
		if not cost.isEnough():
			raise ClientError('badge awake cost not enough')
		cost.cost(src='badge_awake')

		badge['awake'] = awake + 1
		self._effects = None

	def setGuardCard(self, badgeID, guardID, cardID):
		'''
		设置或取消守护
		'''
		# 勋章是否解锁
		if not self.isBadgeOpen(badgeID):
			raise ClientError('badge locked')

		badge = self.getBadge(badgeID)
		positions = badge.get('positions', {})
		if not positions.get(guardID, False):
			raise ClientError('guard position not available')
		guards = badge.get('guards', {})

		# 取消守护
		if cardID == -1:
			guardCardID = guards.get(guardID, None)
			guardCard = self.game.cards.getCard(guardCardID)
			if not guardCard:
				raise ClientError('guard card undeploy error')
			guardCard.badge_guard = []
			guards[guardID] = None
		else:
			card = self.game.cards.getCard(cardID)
			if not card:
				raise ClientError('cardID error')

			if card.badge_guard:
				oldBadge, oldGuard = card.badge_guard
				if oldBadge == badgeID and oldGuard == guardID:
					raise ClientError('card already guard here')

				# 精灵 原先守护的勋章
				cardBadge = self._badges.get(oldBadge)
				if guards.get(guardID, None):
					# 待交换的守护精灵
					guardCard = self.game.cards.getCard(guards[guardID])
					guardCard.badge_guard = [oldBadge, oldGuard]
				cardBadge['guards'][oldGuard] = guards.get(guardID, None)
			else:
				if guards.get(guardID, None):
					guardCard = self.game.cards.getCard(guards[guardID])
					guardCard.badge_guard = []

			card.badge_guard = [badgeID, guardID]
			guards[guardID] = cardID

		self._effects = None

	def getBadgeAttrs(self):
		'''
		徽章加成
		'''
		if self._effects == None:
			const = zeros()
			percent = zeros()

			for badgeID, badge in self._badges.iteritems():

				awakeLevel = badge.get('awake', 0)
				awakePercent = 0
				badgeCfg = csv.gym_badge.badge[badgeID]
				if awakeLevel > 0:
					# 勋章觉醒对天赋属性的百分比加成
					awakePercent = str2num_t(badgeCfg.awakeTalentAttrs[awakeLevel - 1])[1]

					# 勋章觉醒加成
					for i in xrange(1, 99):
						attrKey = 'attrType%d' % i
						attrNumKey = 'attrNum%d' % i
						if attrKey not in badgeCfg or not badgeCfg[attrNumKey]:
							break
						attr = badgeCfg[attrKey]
						num = str2num_t(badgeCfg[attrNumKey][awakeLevel - 1])
						const[attr] += num[0]
						percent[attr] += num[1]

				# 守护精灵 对天赋属性的百分比加成
				guardPercent = 0
				guards = badge.get('guards', {})
				for _, cardID in guards.iteritems():
					if cardID:
						card = self.game.cards.getCard(cardID)
						guardCfg = csv.gym_badge.guard_effect[card.rarity]
						# 星级加成
						starPercent = str2num_t(guardCfg.starAttrs[card.star - 1])[1]
						# 突破加成
						advancePercent = str2num_t(guardCfg.advanceAttrs[card.advance - 1])[1]
						# 稀有度加成
						rarityPercent = str2num_t(guardCfg.rarityAttr)[1]
						# 属性一致加成
						naturePercent = 0
						if card.natureType in badgeCfg.nature or card.natureType2 in badgeCfg.nature:
							naturePercent = str2num_t(guardCfg.natureAttr)[1]
						# 个体值加成
						nvaluePercent = 0
						nvalueSum = sum(card.nvalue.values())
						for i in sorted(guardCfg.nvalueAttrs.keys(), reverse=True):
							if nvalueSum >= i:
								nvaluePercent = str2num_t(guardCfg.nvalueAttrs[i])[1]
								break
						# 守护加成 = (稀有度加成 + 星级加成 + 突破加成 + 个体值加成) * (1 + 属性一致加成)
						guardPercent += (starPercent + rarityPercent + advancePercent + nvaluePercent) * (1 + naturePercent)

				# 勋章天赋加成
				talentConst, talentPercent = zeros(), zeros()
				talents = badge.get('talents', {})
				for talentID, level in talents.iteritems():
					if level > 0:
						cfg = csv.gym_badge.talent[talentID]
						for i in xrange(1, 99):
							attrKey = 'attrType%d' % i
							attrNumKey = 'attrNum%d' % i
							if attrKey not in cfg or not cfg[attrNumKey]:
								break
							attr = cfg[attrKey]
							num = str2num_t(cfg[attrNumKey][level - 1])
							talentConst[attr] += num[0]
							talentPercent[attr] += num[1]

				# 最终属性加成 = 天赋属性 * (1 + 觉醒加成) * (1 + 守护加成)
				const = const + talentConst * (1 + awakePercent) * (1 + guardPercent)
			self._effects = (const, percent)
		return self._effects

	def unlockGuardPosition(self, badgeID, guardID):
		'''
		守护精灵栏位解锁
		'''
		# 勋章是否解锁
		if not self.isBadgeOpen(badgeID):
			raise ClientError('badge locked')

		badge = self.getBadge(badgeID)
		positions = badge.get('positions', {})
		if guardID not in csv.gym_badge.badge[badgeID].guardIDs:
			raise ClientError('badge has no guardID: %s' % guardID)
		if positions.get(guardID, False):
			raise ClientError('guard position already unlocked')

		cfg = csv.gym_badge.guard[guardID]
		if not cfg.isOpen:
			raise ClientError('guard position not available')

		if cfg.openCondition:
			if cfg.openCondition == BadgeDefs.BadgeAwake:
				if badge.get('awake', 0) < cfg.openParam:
					raise ClientError('badge awake level not satisfied')

		cost = ObjectCostAux(self.game, cfg.openCost)
		if not cost.isEnough():
			raise ClientError('guard open cost not enough')
		cost.cost(src='badge_guard_unlock')
		positions[guardID] = True

	def resetBadgeCache(self, card):
		if not card.badge_guard:
			return
		self._effects = None
