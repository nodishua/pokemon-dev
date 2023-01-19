#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2014 YouMi Information Technology Inc.

Society Handlers
'''

from framework.csv import ErrDefs
from framework.log import logger
from framework.distributed.helper import multi_future
from game import ServerError, ClientError
from game.handler.task import RequestHandlerTask
from game.globaldata import FriendListMax, FriendsMax
from game.object.game import ObjectGame
from game.object.game.yyhuodong import ObjectYYHuoDongFactory
from game.object.game.society import ObjectSociety, ObjectSocietyGlobal
from game.object import SceneDefs, AchievementDefs, TargetDefs

from tornado.gen import coroutine, Return


@coroutine
def getFriendSociety(dbc, roleID):
	game = ObjectGame.getByRoleID(roleID, safe=False)
	# 在线玩家
	if game:
		raise Return(game.society)

	# 非在线玩家
	societyDatas = yield dbc.call_async('DBReadBy', 'Society', {'role_db_id': roleID})
	if not societyDatas['ret']:
		raise ServerError('db read society error')
	societyData = societyDatas['models'][0]
	society = ObjectSociety(None, dbc).set(societyData).init()
	raise Return(society)


# 申请好友请求
class SocietyFriendAskfor(RequestHandlerTask):
	url = r'/game/society/friend/askfor'

	@coroutine
	def run(self):
		roleIDs = self.input.get('roleIDs', None)

		if roleIDs is None:
			raise ClientError('roleIDs is miss')

		only = len(roleIDs) == 1
		for roleID in roleIDs:
			try:
				# 是否已经是好友
				if self.game.society.isFriend(roleID):
					raise ClientError(ErrDefs.friendAlready)
				# 是否是自己
				if self.game.role.id == roleID:
					raise ClientError(ErrDefs.friendAskforSelf)

				friendSociety = yield getFriendSociety(self.dbcGame, roleID)
				self.game.society.askforFriend(friendSociety)

			except:
				if only:
					raise


# 接受好友请求
class SocietyFriendAccept(RequestHandlerTask):
	url = r'/game/society/friend/accept'

	@coroutine
	def run(self):
		roleID = self.input.get('roleID', None)
		auto = self.input.get('auto', None)

		if roleID is None and auto is None:
			raise ClientError('param is miss')

		bindRole = self.game.role.reunionBindRole
		needRefresh = False

		if roleID:
			friendSociety = yield getFriendSociety(self.dbcGame, roleID)
			self.game.society.acceptFriend(roleID, friendSociety)
			if bindRole == roleID:
				needRefresh = True

		elif auto:
			roleIDs = self.game.society.acceptFriendAutoBegin()
			friendSocietysL = []
			for roleID in roleIDs:
				friendSociety = yield getFriendSociety(self.dbcGame, roleID)
				friendSocietysL.append(friendSociety)
				if bindRole == roleID:
					needRefresh = True
			self.game.society.acceptFriendAutoEnd(friendSocietysL)

			refuseFlag = False
			if self.game.society.friend_reqs:
				refuseFlag = True
				# 剩下的 全部拒绝掉
				self.game.society.rejectFriendAuto()

			self.write({'view': {
				'refuseFlag': refuseFlag,
			}})

		if needRefresh:
			from game.handler._yyhuodong import getReunion
			reunion = yield getReunion(self.dbcGame, self.game.role.reunion['info']['role_id'])
			ObjectYYHuoDongFactory.refreshReunionRecord(self.game, reunion, TargetDefs.ReunionFriend, 0)


# 拒绝好友请求
class SocietyFriendReject(RequestHandlerTask):
	url = r'/game/society/friend/reject'

	@coroutine
	def run(self):
		roleID = self.input.get('roleID', None)
		auto = self.input.get('auto', None)

		if roleID is None and auto is None:
			raise ClientError('param is miss')

		if roleID:
			self.game.society.rejectFriend(roleID)

		elif auto:
			self.game.society.rejectFriendAuto()


# 删除好友
class SocietyFriendDelete(RequestHandlerTask):
	url = r'/game/society/friend/delete'

	@coroutine
	def run(self):
		roleID = self.input.get('roleID', None)

		if roleID is None:
			raise ClientError('roleID is miss')

		# 是否已经是好友
		if not self.game.society.isFriend(roleID):
			raise ClientError(ErrDefs.friendNone)

		friendSociety = yield getFriendSociety(self.dbcGame, roleID)
		self.game.society.deleteFriend(roleID, friendSociety)


# 赠送好友体力
class SocietyFriendSendStamina(RequestHandlerTask):
	url = r'/game/society/friend/stamina/send'

	@coroutine
	def run(self):
		roleID = self.input.get('roleID', None)
		auto = self.input.get('auto', None)

		if roleID is None and auto is None:
			raise ClientError('param is miss')

		send = 0
		if roleID:
			# 是否已经是好友
			if not self.game.society.isFriend(roleID):
				raise ClientError(ErrDefs.friendNone)

			friendSociety = yield getFriendSociety(self.dbcGame, roleID)
			send = self.game.society.sendStamina(roleID, friendSociety)
			if send > 0:
				self.game.achievement.onCount(AchievementDefs.FriendStaminaSend, 1)

		elif auto:
			roleIDs = self.game.society.sendStaminaAutoBegin()
			allFriendSociety = yield multi_future({roleID:getFriendSociety(self.dbcGame, roleID) for roleID in roleIDs})
			send = self.game.society.sendStaminaAutoEnd(allFriendSociety.values())
			if send > 0:
				self.game.achievement.onCount(AchievementDefs.FriendStaminaSend, len(roleIDs))
		self.write({'view':{'send':send}})

# 领取好友体力
class SocietyFriendRecvStamina(RequestHandlerTask):
	url = r'/game/society/friend/stamina/recv'

	@coroutine
	def run(self):
		roleID = self.input.get('roleID', None)
		auto = self.input.get('auto', None)

		if roleID is None and auto is None:
			raise ClientError('param is miss')

		recv = 0
		if roleID:
			# 是否已经是好友
			if not self.game.society.isFriend(roleID):
				raise ClientError(ErrDefs.friendNone)

			recv = self.game.society.recvStamina(roleID)

		elif auto:
			recv = self.game.society.recvStaminaAuto()
		logger.info('role %d %s recv stamina %d', self.game.role.uid, self.game.role.pid, recv)

		self.write({'view':{'recv':recv}})

# 换一批申请列表
class SocietyFriendList(RequestHandlerTask):
	url = r'/game/society/friend/list'

	@coroutine
	def run(self):
		ret = ObjectSocietyGlobal.getRandomFriends(self.game)

		self.write({'view': {
			'roles': ret,
			'size': len(ret),
		}})

# 在线好友列表
class SocietyFriendOnlineList(RequestHandlerTask):
	url = r'/game/society/friend/online/list'

	@coroutine
	def run(self):
		ret = ObjectSocietyGlobal.getOnlineFriends(self.game)

		self.write({'view': {
			'roles': ret,
			'size': len(ret),
		}})

@coroutine
def getSocietyRole(dbc, roleID=None, roleName=None, uid=None):
	if roleID:
		ret = ObjectSocietyGlobal.RoleCache.getByKey(roleID)
		if ret:
			raise Return([ret])

		model = yield dbc.call_async('DBRead', 'Role', roleID, True)
		if not model['ret'] or 'robot' in model['model']['account_id']:
			raise ClientError(ErrDefs.friendSearchNoSuchRole)

		ret = ObjectSocietyGlobal.onRoleInfoByModel(model['model'])
		raise Return([ret])

	roles = []
	if uid:
		ret = ObjectSocietyGlobal.getFriendByUID(uid)
		if ret:
			roles.append(ret)
		else:
			model = yield dbc.call_async('DBReadBy', 'Role', {'uid': uid})
			if model['ret'] and len(model['models']) > 0:
				role = model['models'][0]
				if 'robot' not in role['account_id']:
					ret = ObjectSocietyGlobal.onRoleInfoByModel(role)
					roles.append(ret)

	if roleName:
		ret = ObjectSocietyGlobal.getFriendsByName(roleName)
		if ret:
			ret = filter(lambda x: x['uid'] != uid, ret)
			roles.extend(ret)
		else:
			models = yield dbc.call_async('DBReadByPattern', 'Role', {'name': {'pattern': roleName}}, FriendListMax)
			if models['ret']:
				ret = [ObjectSocietyGlobal.onRoleInfoByModel(model) for model in models['models'] if 'robot' not in model['account_id']]
				ret = filter(lambda x: x['uid'] != uid, ret)
				roles.extend(ret)

	if not roles:
		raise ClientError(ErrDefs.friendSearchNoSuchRole)
	raise Return(roles)

# 搜索申请好友
class SocietyFriendSearch(RequestHandlerTask):
	url = r'/game/society/friend/search'

	@coroutine
	def run(self):
		roleID = self.input.get('roleID', None)
		roleName = self.input.get('roleName', None)
		roleIDs = self.input.get('roleIDs', None)
		uid = self.input.get('uid', None)

		if roleID is None and roleName is None and roleIDs is None and uid is None:
			raise ClientError('param is miss')

		if roleIDs:
			roles = []
			for roleID in roleIDs:
				if roleID == self.game.role.id:
					continue

				role = yield getSocietyRole(self.dbcGame, roleID=roleID)
				roles += role

			self.write({'view': {
				'roles': roles,
				'size': len(roles),
			}})

		else:
			if roleID and roleID == self.game.role.id:
				raise ClientError(ErrDefs.friendSearchMyself)

			if roleName and roleName == self.game.role.name:
				raise ClientError(ErrDefs.friendSearchMyself)

			if uid and uid == self.game.role.uid:
				raise ClientError(ErrDefs.friendSearchMyself)

			roles = yield getSocietyRole(self.dbcGame, roleID, str(roleName), uid)
			self.write({'view': {
				'roles': roles,
				'size': len(roles),
			}})

# 好友挑战
class SocietyFriendFight(RequestHandlerTask):
	url = r'/game/society/friend/fight'

	@coroutine
	def run(self):
		roleID = self.input.get('roleID', None)
		recordID = self.input.get('recordID', None)
		if roleID is None:
			raise ClientError('roleID is miss')
		if recordID is None:
			raise ClientError('friend not in arena')

		cards = self.game.role.battle_cards
		cardsD, cardsD2 = self.game.cards.makeBattleCardModel(cards, SceneDefs.Arena)
		embattle = {
			'cards': cards,
			'card_attrs': cardsD,
			'card_attrs2': cardsD2,
		}

		role = self.game.role
		model = yield self.rpcArena.call_async('FriendFight', role.competitor, embattle, roleID, recordID)
		self.write({
			'model': {
				'qiecuo': model,
			}
		})

# 加入黑名单
class SocietyAddBlackList(RequestHandlerTask):
	url = r'/game/society/blacklist/add'

	@coroutine
	def run(self):
		roleID = self.input.get('roleID', None)

		if roleID is None:
			raise ClientError('roleID is miss')

		if roleID == self.game.role.id:
			raise ClientError('cant add self')

		if roleID in self.game.society.black_list:
			raise ClientError(ErrDefs.societyBlackListHasAdd)

		self.game.society.black_list.append(roleID)

# 从黑名单中移除
class SocietyRemoveBlackList(RequestHandlerTask):
	url = r'/game/society/blacklist/remove'

	@coroutine
	def run(self):
		roleID = self.input.get('roleID', None)

		if roleID is None:
			raise ClientError('roleID is miss')

		if roleID not in self.game.society.black_list:
			raise ClientError(ErrDefs.societyBlackListNoThis)

		self.game.society.black_list.remove(roleID)
