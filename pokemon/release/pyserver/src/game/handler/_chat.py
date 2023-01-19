#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2014 YouMi Information Technology Inc.

Chat Handlers
'''

import framework
from framework import nowtime_t
from framework.csv import ErrDefs, ConstDefs
from framework.log import logger
from framework.word_filter import filterName
from game import ServerError, ClientError
from game.handler.task import RequestHandlerTask
from game.object import FeatureDefs, AchievementDefs
from game.object.game import ObjectFeatureUnlockCSV
from game.object.game.message import ObjectMessageGlobal

from tornado.gen import coroutine


# 聊天
class Chat(RequestHandlerTask):
	url = r'/game/chat'

	@coroutine
	def run(self):
		if ConstDefs.chatSilent:
			raise ClientError(ErrDefs.chatSilent)
		if self.game.role.silent_flag:
			raise ClientError(ErrDefs.roleBeenSilent)

		msg = self.input.get('msg', None)
		if msg is None:
			raise ClientError('msg is miss')

		msgType = self.input.get('msgType', None)
		if msgType is None:
			raise ClientError('msgType is miss')

		correction = self.game.role.initChatLimitCorrection() # 聊天次数修正值
		# 判断次数是否太多
		if msgType == 'world':
			# 判断是否具备开启条件
			if not ObjectFeatureUnlockCSV.isOpen(FeatureDefs.WorldChat, self.game):
				raise ClientError(ErrDefs.chatNoOpen)
			if self.game.dailyRecord.chat_times >= int(self.game.role.chatTimes * correction):
				raise ClientError(ErrDefs.chatTooMuch)
		elif msgType == 'role':
			if not ObjectFeatureUnlockCSV.isOpen(FeatureDefs.RoleChat, self.game):
				raise ClientError(ErrDefs.chatNoOpen)
			if self.game.dailyRecord.role_chat_times >= int(self.game.role.roleChatTimes * correction):
				raise ClientError(ErrDefs.chatTooMuch)
		elif msgType == 'union':
			# 暂时先用世界聊天计数
			if self.game.dailyRecord.chat_times >= int(self.game.role.chatTimes * correction):
				raise ClientError(ErrDefs.chatTooMuch)

		# 消息是否合法
		umsg = msg.decode('utf8')
		if len(umsg) > 50:
			raise ClientError(ErrDefs.chatMsgTooLong)
		# tw先去掉敏感词
		if framework.__language__ != 'tw':
			if filterName(umsg):
				raise ClientError(ErrDefs.chatMsgInvalid)

		# 检查是否需要自动禁言
		self.game.role.checkNeedSilent(msg)

		if msgType == 'world':
			self.game.dailyRecord.chat_times += 1
			msg = ObjectMessageGlobal.chatWorldMsg(self.game, msg)
			self.broadcast('/game/push', {
				'msg': {'msgs': [msg]},
			})
			self.game.achievement.onCount(AchievementDefs.WorldChatCount, 1)

		elif msgType == 'union':
			if self.game.union:
				self.game.dailyRecord.chat_times += 1 # 暂时先用世界聊天计数
				msg = ObjectMessageGlobal.chatUnionMsg(self.game, msg)
				self.broadcastToUnion('/game/push', {
					'msg': {'msgs': [msg]},
				})
			else:
				raise ClientError(ErrDefs.chatNoUnion)

		elif msgType == 'role':
			self.game.dailyRecord.role_chat_times += 1
			role = self.input.get('role', None)
			if role is None:
				raise ClientError('role is miss')
			if self.game.role.id == role.get('id', None):
				raise ClientError(ErrDefs.roleChatSelf)
			msg = ObjectMessageGlobal.chatRoleMsg(self.game.role, role, msg)
			self.pushToRole('/game/push', {
				'msg': {'msgs': [msg]},
			}, role['id'])
		else:
			raise ClientError('msgType is error')


# 删除聊天
class ChatDel(RequestHandlerTask):
	url = r'/game/chat/del'

	@coroutine
	def run(self):
		roleID = self.input.get('roleID', None)
		if roleID is None:
			raise ClientError('roleID is miss')
		ObjectMessageGlobal.delChatRoleMsg(self.game.role, roleID)


class Cheat(RequestHandlerTask):
	url = r'/game/cheat'

	@coroutine
	def run(self):
		import framework
		if not hasattr(framework, '__dev__'):
			raise ClientError('not in development')
		if self.game.role.channel != 'none':
			raise ClientError('你是测试人员？')
		import game.handler.pokemon_cheat
		reload(game.handler.pokemon_cheat)
		from game.handler.pokemon_cheat import cheat_console
		msg = self.input.get('msg', None)
		if msg is None:
			raise ClientError('msg is miss')
		if msg[0] == '/':
			yield cheat_console(self, msg)
