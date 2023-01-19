#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2014 YouMi Information Technology Inc.
'''

from __future__ import absolute_import

from framework import nowtime_t, todayelapsedays, datetimefromtimestamp
from framework.csv import ErrDefs, ConstDefs
from framework.lru import LRUCache
from framework.object import ReloadHooker, ObjectDBase, db_property
from framework.helper import copyKV

from game import ServerError, ClientError
from game.globaldata import FriendsMax, FriendSendStamina, FriendSendStaminaTimesMax, FriendRecvStaminaTimesMax, FriendListMax, RobotIDStart, StaminaLimitMax
from game.object import AchievementDefs, ReunionDefs

import copy
import random
import math
from weakref import WeakValueDictionary


#
# ObjectSociety
#

class ObjectSociety(ObjectDBase):
	DBModel = 'Society'

	# Role.id
	def role_db_id():
		dbkey = 'role_db_id'
		return locals()
	role_db_id = db_property(**role_db_id())

	# 好友列表 [Role.id]
	def friends():
		dbkey = 'friends'

		def fset(self, value):
			self.db[dbkey] = value
		return locals()
	friends = db_property(**friends())

	# 好友申请列表 [Role.id]
	def friend_reqs():
		dbkey = 'friend_reqs'

		def fset(self, value):
			self.db[dbkey] = value
		return locals()
	friend_reqs = db_property(**friend_reqs())

	# 好友体力可领取列表 [Role.id]
	def stamina_recv():
		dbkey = 'stamina_recv'

		def fset(self, value):
			self.db[dbkey] = value
		return locals()
	stamina_recv = db_property(**stamina_recv())

	# 黑名单列表 [Role.id]
	def black_list():
		dbkey = 'black_list'
		def fset(self, value):
			self.db[dbkey] = value
		return locals()
	black_list = db_property(**black_list())

	def askforFriend(self, friendSociety):
		'''
		申请好友请求
		'''
		if len(self.friends) >= FriendsMax:
			raise ClientError(ErrDefs.friendMax)

		if len(friendSociety.friend_reqs) >= FriendsMax:
			raise ClientError(ErrDefs.friendFriendReqMax)

		if self.game.role.id in friendSociety.friend_reqs:
			return

		if self.game.role.id in friendSociety.black_list:
			return

		friendSociety.friend_reqs.append(self.game.role.id)

	def acceptFriend(self, roleID, friendSociety):
		'''
		接受好友请求
		'''
		if len(self.friends) >= FriendsMax:
			raise ClientError(ErrDefs.friendMax)

		if len(friendSociety.friends) >= FriendsMax:
			raise ClientError(ErrDefs.friendFriendMax)

		# 清理申请列表
		if self.game.role.id in friendSociety.friend_reqs:
			friendSociety.friend_reqs.remove(self.game.role.id)
		if roleID in self.friend_reqs:
			self.friend_reqs.remove(roleID)
		# 增加好友列表
		if self.game.role.id not in friendSociety.friends:
			friendSociety.friends.append(self.game.role.id)
		if roleID not in self.friends:
			self.friends.append(roleID)

	def acceptFriendAutoBegin(self):
		size = FriendsMax - len(self.friends)
		ret = []
		for roleID in self.friend_reqs:
			if size <= 0:
				return ret
			if roleID not in self.friends:
				ret.append(roleID)
				size -= 1
		return ret

	def acceptFriendAutoEnd(self, friendSocietysL):
		size = FriendsMax - len(self.friends)
		for friendSociety in friendSocietysL:
			if size <= 0:
				return

			if len(friendSociety.friends) >= FriendsMax:
				continue

			roleID = friendSociety.role_db_id
			# 清理申请列表
			if self.game.role.id in friendSociety.friend_reqs:
				friendSociety.friend_reqs.remove(self.game.role.id)
			if roleID in self.friend_reqs:
				self.friend_reqs.remove(roleID)
			# 增加好友列表
			if self.game.role.id not in friendSociety.friends:
				friendSociety.friends.append(self.game.role.id)
			if roleID not in self.friends:
				self.friends.append(roleID)

			size -= 1

	def rejectFriend(self, roleID):
		'''
		拒绝好友请求
		'''
		if roleID in self.friend_reqs:
			self.friend_reqs.remove(roleID)

	def rejectFriendAuto(self):
		'''
		拒绝好友请求
		'''
		self.friend_reqs = []

	def deleteFriend(self, roleID, friendSociety):
		'''
		删除好友
		'''
		if self.game.role.id in friendSociety.friends:
			friendSociety.friends.remove(self.game.role.id)
		if roleID in self.friends:
			self.friends.remove(roleID)

	def sendStamina(self, roleID, friendSociety):
		'''
		赠送好友体力
		'''
		if len(self.game.dailyRecord.friend_stamina_send) >= FriendSendStaminaTimesMax:
			raise ClientError(ErrDefs.friendStaminaSendMax)

		send = 0
		if roleID not in self.game.dailyRecord.friend_stamina_send:
			self.game.dailyRecord.friend_stamina_send.append(roleID)
			send = FriendSendStamina

		if self.game.role.id not in friendSociety.stamina_recv:
			friendSociety.stamina_recv.append(self.game.role.id)

		return send

	def sendStaminaAutoBegin(self):
		size = FriendSendStaminaTimesMax - len(self.game.dailyRecord.friend_stamina_send)
		ret = []
		for roleID in self.friends:
			if size <= 0:
				return ret
			if roleID not in self.game.dailyRecord.friend_stamina_send:
				ret.append(roleID)
				size -= 1
		return ret

	def sendStaminaAutoEnd(self, friendSocietysL):
		size = FriendSendStaminaTimesMax - len(self.game.dailyRecord.friend_stamina_send)
		sendCount = 0
		for friendSociety in friendSocietysL:
			if size <= 0:
				return sendCount * FriendSendStamina

			roleID = friendSociety.role_db_id
			if roleID not in self.game.dailyRecord.friend_stamina_send:
				sendCount += 1
				self.game.dailyRecord.friend_stamina_send.append(roleID)

			if self.game.role.id not in friendSociety.stamina_recv:
				friendSociety.stamina_recv.append(self.game.role.id)

			size -= 1
		return sendCount * FriendSendStamina

	def recvStamina(self, roleID):
		'''
		领取好友体力
		'''
		if self.game.role.stamina >= StaminaLimitMax:
			raise ClientError(ErrDefs.staminaCanNotGive)

		if self.game.dailyRecord.friend_stamina_gain >= FriendRecvStaminaTimesMax:
			raise ClientError(ErrDefs.friendStaminaRecvMax)

		if roleID not in self.stamina_recv:
			raise ClientError(ErrDefs.friendStaminaNone)

		self.game.role.stamina += FriendSendStamina
		self.game.dailyRecord.friend_stamina_gain += 1
		self.stamina_recv.remove(roleID)

		self.game.achievement.onCount(AchievementDefs.FriendStaminaRecv, 1)
		return FriendSendStamina

	def recvStaminaAuto(self):
		if self.game.role.stamina >= StaminaLimitMax:
			raise ClientError(ErrDefs.staminaCanNotGive)

		size = FriendRecvStaminaTimesMax - self.game.dailyRecord.friend_stamina_gain
		size = min(size, len(self.stamina_recv))
		limitCount = int(math.ceil((StaminaLimitMax - self.game.role.stamina) * 1.0 / FriendSendStamina))
		if size > limitCount:
			self.game.role.stamina += FriendSendStamina * limitCount
			self.game.dailyRecord.friend_stamina_gain += limitCount
			for i in xrange(limitCount):
				self.stamina_recv.pop()
			return FriendSendStamina * limitCount

		self.game.role.stamina += FriendSendStamina * size
		self.game.dailyRecord.friend_stamina_gain += size
		self.stamina_recv = []

		self.game.achievement.onCount(AchievementDefs.FriendStaminaRecv, size)
		return FriendSendStamina * size
	def isFriend(self, roleID):
		return roleID in self.friends


#
# ObjectPVPDefenceCards
#

class ObjectPVPDefenceCards(ReloadHooker):

	__slots__ = ('cards', 'cardAttrs', 'fightgo_val')

	def __init__(self, cards, cardAttrs, fightgo_val):
		self.cards = cards
		self.cardAttrs = copy.deepcopy(cardAttrs)
		self.fightgo_val = fightgo_val

# for WeakValueDictionary value
class Dict(dict):
	pass

#
# ObjectSocietyGlobal
#

class ObjectSocietyGlobal(ReloadHooker):

	RoleCache = None # {Role.id, {...}}
	CardsCache = None # {Role.id, ObjectPVPDefenceCards}
	UIDCache = WeakValueDictionary()
	Singleton = None

	def __init__(self):
		ObjectSocietyGlobal.RoleCache = LRUCache(1000)
		ObjectSocietyGlobal.CardsCache = LRUCache(1000)

		if ObjectSocietyGlobal.Singleton is not None:
			raise ValueError('This is singleton object')
		ObjectSocietyGlobal.Singleton = self

	@classmethod
	def init(cls, roles):
		for d in roles:
			cls.onRoleInfoByModel(d)

	@classmethod
	def onRoleInfo(cls, game):
		d = Dict({
			'id': game.role.id,
			'uid': game.role.uid,
			'name': game.role.name,
			'last_time': game.role.last_time,
			'logo': game.role.logo,
			'frame': game.role.frame,
			'figure': game.role.figure,
			'level': game.role.level,
			'vip_level': game.role.vip_level_display,
			'battle_fighting_point': game.role.battle_fighting_point,
			'pvp_record_db_id': game.role.pvp_record_db_id,
			'top6_fighting_point': game.role.top6_fighting_point,
			'reunion_open': game.role.isReunionRoleOpen,
		})
		model = copy.deepcopy(d)
		cls.RoleCache.set(game.role.id, model)
		cls.UIDCache[game.role.uid] = model

	@classmethod
	def onRoleInfoByModel(cls, d):
		keys = ('id', 'uid', 'name', 'last_time', 'logo', 'frame', 'figure', 'level', 'vip_level', 'battle_fighting_point', 'pvp_record_db_id', 'top6_fighting_point', 'reunion_open')
		model = Dict(copyKV(d, keys=keys))
		if d.get('vip_hide', False):
			model['vip_level'] = 0
		# 机器人不可加为好友，不入RoleCache
		# TODO: 判断是不是机器人
		if 'robot' in d['account_id']:
			return model
		cls.RoleCache.set(model['id'], model)
		cls.UIDCache[model['uid']] = model
		return model

	@classmethod
	def onCardsInfo(cls, roleID, defenceCards, defenceCardAttrs, defenceFightgoVal):
		ret = ObjectPVPDefenceCards(defenceCards, defenceCardAttrs, defenceFightgoVal)
		# 对于防守阵容为空的数据，不存放到缓存中
		if not defenceCardAttrs:
			return ret

		obj = cls.CardsCache.getValue(roleID)
		if obj:
			obj.cards = ret.cards
			obj.cardAttrs = ret.cardAttrs
			obj.fightgo_val = ret.fightgo_val
			ret = obj

		elif not cls.CardsCache.full():
			cls.CardsCache.set(roleID, ret)

		return ret

	@classmethod
	def getRandomFriends(cls, game):
		s = set(cls.RoleCache) - set(game.society.friends)
		s.discard(game.role.id)
		if len(s) < FriendListMax:
			roleIDs = s
		else:
			roleIDs = random.sample(s, FriendListMax)
		return [cls.RoleCache.getValue(roleID) for roleID in roleIDs]

	@classmethod
	def getReunionRecommendList(cls, game, listType):
		if listType == ReunionDefs.Recommend:
			roleIDs = set(cls.RoleCache) - set(game.society.friends)
			roleIDs.discard(game.role.id)
		elif listType == ReunionDefs.Friend:
			roleIDs = set(game.society.friends)

		roles = []
		for roleID in roleIDs:
			role = cls.RoleCache.getValue(roleID)
			if not role:
				continue
			offDays = todayelapsedays(datetimefromtimestamp(role['last_time']))
			if role['level'] >= ConstDefs.seniorRoleLevel and offDays <= ConstDefs.seniorRoleOffline and role.get('top6_fighting_point', 0) >= ConstDefs.seniorRoleFightingPoint and not role.get('reunion_open', False):
				roles.append(role)

		if len(roles) < FriendListMax:
			return roles
		else:
			return random.sample(roles, FriendListMax)

	@classmethod
	def getOnlineFriends(cls, game):
		ret = []
		now = nowtime_t()
		for roleID in game.society.friends:
			friend = cls.RoleCache.getValue(roleID)
			# 10 分钟内容有操作的用户为在线用户
			if friend and (now - friend['last_time']) <= 60 * 10:
				ret.append(friend)
		return ret

	@classmethod
	def getFriendsByName(cls, name):
		ret = []
		for roleID in cls.RoleCache:
			d = cls.RoleCache.getValue(roleID)
			if d['name'].find(name) > -1:
				ret.append(roleID)
		return [cls.RoleCache.getByKey(roleID) for roleID in ret]

	@classmethod
	def getFriendByUID(cls, uid):
		return cls.UIDCache.get(uid, None)
