#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2014 YouMi Information Technology Inc.
'''

from framework.csv import csv, ErrDefs
from framework.helper import objectid2string
from framework.object import ObjectBase
from framework.log import logger
from game import ClientError, ServerError
from game.object import FragmentDefs
from game.thinkingdata import ta

#
# ObjectFragsMap
#


class ObjectFragsMap(ObjectBase):

	AutoCombMap = {}

	@classmethod
	def classInit(cls):
		cls.AutoCombMap = {}
		for i in csv.fragments:
			cfg = csv.fragments[i]
			if cfg.autoComb and cfg.combCount > 0:
				cls.AutoCombMap[i] = cfg.combCount


	def __iter__(self):
		return iter(self._frags.keys())

	def set(self):
		self._frags = self.game.role.frags
		return ObjectBase.set(self)

	def _fixCorrupted(self):
		popL = []
		for fragID, count in self._frags.iteritems():
			if count <= 0:
				popL.append(fragID)
		for fragID in popL:
			self._frags.pop(fragID)

	def getTotalSize(self):
		return reduce(lambda x, y: x + y, self._frags.values())

	def getTypeSize(self):
		return len(self._frags)

	def isEnough(self, fragsD):
		for fragID, count in fragsD.iteritems():
			if count <= 0:
				raise ServerError('frag %d %d cheat' % (fragID, count))
			if FragmentDefs.isFragmentID(fragID):
				if self._frags.get(fragID, 0) < count:
					return False
		return True

	def addFrag(self, fragID, count):
		if not FragmentDefs.isFragmentID(fragID):
			return False
		if count <= 0:
			raise ServerError('frag %d %d cheat' % (fragID, count))

		cfg = csv.fragments[fragID]
		old = self._frags.get(fragID, 0)
		self._frags[fragID] = min(old + count, cfg.stackMax)
		self.onFragsAdd([fragID])
		return True

	def addFrags(self, fragsD):
		for fragID, count in fragsD.iteritems():
			if count <= 0:
				raise ServerError('frag %d %d cheat' % (fragID, count))
			if not FragmentDefs.isFragmentID(fragID):
				continue

		for fragID, count in fragsD.iteritems():
			if not FragmentDefs.isFragmentID(fragID):
				continue
			cfg = csv.fragments[fragID]
			old = self._frags.get(fragID, 0)
			self._frags[fragID] = min(old + count, cfg.stackMax)
		self.onFragsAdd(fragsD.keys())
		return True

	def onFragsAdd(self, fragsL):
		'''
		自动合成
		现在只限于道具合成
		'''
		for fragID in fragsL:
			fragCount = self.AutoCombMap.get(fragID, None)
			if fragCount:
				while fragCount <= self._frags.get(fragID, 0):
					fragEff = self.getCombFrag(fragID)
					if fragEff:
						fragEff.gain(src='frag_auto_comb')

	def costFrags(self, fragsD):
		for fragID, count in fragsD.iteritems():
			if not FragmentDefs.isFragmentID(fragID):
				continue
			if count <= 0:
				raise ServerError('frag %d %d cheat' % (fragID, count))
			if self._frags.get(fragID, 0) < count:
				return False

		for fragID, count in fragsD.iteritems():
			if not FragmentDefs.isFragmentID(fragID):
				continue
			self._frags[fragID] -= count
			if self._frags[fragID] <= 0:
				self._frags.pop(fragID)
		return True

	def getCombFrag(self, fragID, count=1):
		if not FragmentDefs.isFragmentID(fragID) or fragID not in csv.fragments:
			raise ClientError('fragID error')

		cfg = csv.fragments[fragID]
		if self._frags.get(fragID, 0) < cfg.combCount * count:
			raise ClientError(ErrDefs.fragCombfragNotEnough)

		return FragEffect(self.game, fragID, count)

	def getCombFrags(self, fragsL):
		for fragID in fragsL:
			if not FragmentDefs.isFragmentID(fragID):
				continue
			cfg = csv.fragments[fragID]
			if self._frags.get(fragID, 0) < cfg.combCount:
				return None

		ret = {}
		for fragID in fragsL:
			if not FragmentDefs.isFragmentID(fragID):
				continue
			ret[fragID] = FragEffect(self.game, fragID)
		return ret


#
# FragEffect
#

class FragEffect(ObjectBase):
	def __init__(self, game, fragID, count=1):
		ObjectBase.__init__(self, game)

		cfg = csv.fragments[fragID]
		self._frags = self.game.role.frags
		self._fragID = fragID
		self._combID = cfg.combID
		self._combCount = cfg.combCount
		self._cardID = self._combID if cfg.type == FragmentDefs.cardType else None
		self._equipID = self._combID if cfg.type == FragmentDefs.equipType else None
		self._itemID = self._combID if cfg.type == FragmentDefs.itemType else None
		self._heldItemID = self._combID if cfg.type == FragmentDefs.heldItemType else None
		self._obj = None
		self._heldItemObjL = []
		self._first = False
		self._count = count

	@property
	def cardID(self):
		return self._cardID

	@property
	def equipID(self):
		return self._equipID

	@property
	def itemID(self):
		return self._itemID

	@property
	def heldItemID(self):
		return self._heldItemID

	def setDB(self, db):
		'''
		外部生成数据库数据
		'''
		if not isinstance(db, list):
			db = [db]
		self._db = db
		self._first = self._db[0]['card_id'] not in self.game.role.pokedex

	def getObj(self):
		'''
		外部获取服务器装备对象
		'''
		return self._obj

	def setHeldItemDB(self, db):
		'''
		外部生成数据库数据
		'''
		if not isinstance(db, list):
			db = [db]
		self._heldItemdbL = db

	def getHeldItemObjL(self):
		'''
		外部获取服务器对象
		'''
		return self._heldItemObjL

	@property
	def view(self):
		if self._obj:
			return {'db_id': self._obj.id, 'first': self._first}
		elif self._heldItemObjL:
			heldItemdbIDs = [objectid2string(obj.id) for obj in self._heldItemObjL]
			return {self._heldItemID: self._count, 'heldItemdbIDs': heldItemdbIDs}
		else:
			return {self._itemID: self._count}

	def gain(self, **kwargs):
		src = kwargs.get('src', None)
		count = self._count
		self._frags[self._fragID] -= self._combCount * count
		if self._frags[self._fragID] <= 0:
			self._frags.pop(self._fragID)
		if src:
			logger.info('role %d %s cost for %s, %s', self.game.role.uid, self.game.role.pid, src, {self._fragID: self._combCount * count})

		result = {}
		objD = None
		heldItemObjD = None
		if self.cardID:
			objD = self.game.cards.addCards(self._db)
			result['cards'] = [{'id': self.cardID}]
		elif self.itemID:
			self.game.items.addItem(self.itemID, count)
			result[self.itemID] = count
		elif self.heldItemID:
			heldItemObjD = self.game.heldItems.addHeldItems(self._heldItemdbL)
			result[self.heldItemID] = count

		if objD:
			_, self._obj = objD.popitem()
			result['carddbIDs'] = [(self._obj.pid, self._first)]
		if heldItemObjD:
			heldItemdbIDs = []
			for dbID, obj in heldItemObjD.iteritems():
				self._heldItemObjL.append(obj)
				heldItemdbIDs.append(objectid2string(dbID))
			result['heldItemdbIDs'] = heldItemdbIDs

		if src:
			logger.info('role %d %s gain from %s, %s', self.game.role.uid, self.game.role.pid, src, result)
		ta.good(self.game, self, **kwargs)
