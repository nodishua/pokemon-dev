#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2014 YouMi Information Technology Inc.
Copyright (c) 2016 TianJi Information Technology Inc.
'''

from framework.object import ObjectBase
from framework.lru import LRUCache

from game.object.game import ObjectGame
from game.object.game.card import ObjectCard

from weakref import WeakValueDictionary
from tornado.gen import Return, coroutine

#
# ObjectCacheGlobal
#
class ObjectCacheGlobal(ObjectBase):
	Singleton = None

	def __init__(self):
		self.roles = LRUCache(1000)
		self.cards = LRUCache(1000)
		self.dbc = None

		if ObjectCacheGlobal.Singleton is not None:
			raise ValueError('This is singleton object')
		ObjectCacheGlobal.Singleton = self

	def init(self, server):
		self.server = server
		self.dbc = server.dbcGame

	@classmethod
	@coroutine
	def queryRole(cls, roleID):
		self = cls.Singleton

		game = ObjectGame.getByRoleID(roleID, safe=False)
		if game: # online role
			role = self.role2display(game.role)
			self.roles.set(roleID, role)
		else:
			role = self.roles.getByKey(roleID)
			if role is None:
				# query from storage
				role = yield self.dbc.call_async('GetSlimRole', roleID)
				self.roles.set(roleID, role)
		raise Return(role)

	@classmethod
	@coroutine
	def queryCard(cls, cardID):
		self = cls.Singleton

		card = ObjectCard.CardsObjsMap.get(cardID, None)
		if card: # online card
			card = self.card2display(card)
			self.cards.set(cardID, card)
		else:
			card = self.cards.getByKey(cardID)
			if card is None:
				# query from storage
				card = yield self.dbc.call_async('GetSlimCard', cardID)
				if not card['attrs']: # 删除卡牌是异步操作，可能取到已删除的卡牌，没有attrs数据
					from game.object.game.card import CardSlim
					cardTmp = CardSlim(card)
					attrs = ObjectCard.calcAttrs(cardTmp)
					card['attrs'] = attrs
					raise Return(card)
				self.cards.set(cardID, card)
		raise Return(card)

	@classmethod
	def popRole(cls, roleID):
		self = cls.Singleton
		self.roles.popByKey(roleID)

	@classmethod
	def popCard(cls, cardID):
		self = cls.Singleton
		self.cards.popByKey(cardID)

	@staticmethod
	def card2display(card):
		keys = ('id', 'name', 'card_id', 'advance', 'star', 'level', 'gender', 'character', 'nvalue', 'skills', 'fighting_point', 'skin_id', 'zawake_skills')
		display = {key: getattr(card, key) for key in keys}
		display['attrs'] = card.csvAttrs
		display['role_name'] = card.game.role.name
		if card.held_item:
			heldItem = card.game.heldItems.getHeldItem(card.held_item)
			display['held_item'] = {
				'held_item_id': heldItem.held_item_id,
				'level': heldItem.level,
				"advance": heldItem.advance
			}
		return display

	@staticmethod
	def role2display(role):
		keys = ('id', 'account_id', 'uid', 'name', 'personal_sign', 'last_time', 'logo', 'frame', 'figure', 'title_id', 'level', 'vip_level', 'battle_fighting_point')
		rolecache = {key: getattr(role, key) for key in keys}
		rolecache['collect_num'] = len(role.pokedex)
		if role.vip_hide:
			rolecache['vip_level'] = 0
		cardscache = []
		cards = role.game.cards.getCards(role.battle_cards)
		for card in cards:
			cardscache.append({
				'id': card.id,
				'name': card.name,
				'card_id': card.card_id,
				'advance': card.advance,
				'star': card.star,
				'level': card.level,
				'skin_id': card.skin_id,
			})
		rolecache['cards'] = cardscache
		return rolecache
