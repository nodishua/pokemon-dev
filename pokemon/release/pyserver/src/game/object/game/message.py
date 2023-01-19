#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2014 YouMi Information Technology Inc.
'''

from __future__ import absolute_import

from framework import nowtime_t
from framework.csv import csv, L10nDefs
from framework.log import logger
from framework.object import ReloadHooker, ObjectDBase, db_ro_property, db_property

from game.globaldata import ChatMessageMax, AppNotifyInternalPassword
from game.object import CardDefs, EquipDefs, MessageDefs
from game.object import UnionDefs

from tornado.gen import coroutine

import json
import struct
from collections import deque, namedtuple


Msg = namedtuple('Msg', ('id', 't', 'msg', 'type', 'role', 'args'))

#
# ObjectMessageGlobal
#

class ObjectMessageGlobal(ReloadHooker):

	ServerKey = ''
	MsgID = 0
	ID = None

	WorldQue = None # 世界消息
	NewsQue = None # 新闻消息
	UnionQueMap = None # 公会消息 {Union.id: que}
	RoleQueMap = None # 个人消息 {Role.id: que}

	MarqueeMap = {}

	OnChat = None
	AppNotifyStream = None
	AppNotifyClosed = True

	Singleton = None

	def __init__(self, servKey, onChat):
		ObjectMessageGlobal.ServerKey = servKey
		ObjectMessageGlobal.OnChat = onChat
		ObjectMessageGlobal.WorldQue = deque(maxlen=ChatMessageMax)
		ObjectMessageGlobal.NewsQue = deque(maxlen=ChatMessageMax)
		ObjectMessageGlobal.UnionQueMap = {}
		ObjectMessageGlobal.RoleQueMap = {}

		if ObjectMessageGlobal.Singleton is not None:
			raise ValueError('This is singleton object')
		ObjectMessageGlobal.Singleton = self

	@classmethod
	def classInit(cls):
		cls.MarqueeMap = {}
		for idx in csv.marquee:
			cfg = csv.marquee[idx]
			cls.MarqueeMap[cfg.key] = cfg.isActive

	@classmethod
	def set(cls, model):
		cls.ID = model['id']
		msgID = 0
		for v in model['queues']:
			name, idx = v['name'], v['id']
			msgs = []
			for msg in v['messages']:
				msgs.append(Msg(*msg))
			if msgs:
				msgID = max(msgID, msgs[-1].id)
			if name == 'world':
				cls.WorldQue = deque(msgs, maxlen=ChatMessageMax)
			elif name == 'news':
				cls.NewsQue = deque(msgs, maxlen=ChatMessageMax)
			elif name == 'union':
				cls.UnionQueMap[idx] = deque(msgs, maxlen=ChatMessageMax)
			elif name == 'role':
				cls.RoleQueMap[idx] = deque(msgs, maxlen=ChatMessageMax)
		cls.MsgID = msgID

	@classmethod
	def save_async(cls, dbc):
		queues = [
			{'name': 'world', 'messages': list(cls.WorldQue)},
			{'name': 'news', 'messages': list(cls.NewsQue)},
		]
		for unionID, que in cls.UnionQueMap.iteritems():
			queues.append({
				'name': 'union',
				'id': unionID,
				'messages': list(que),
			})
		for roleID, que in cls.RoleQueMap.iteritems():
			queues.append({
				'name': 'role',
				'id': roleID,
				'messages': list(que),
			})
		return dbc.call_async('DBUpdate', 'MessageGlobal', cls.ID, {'queues': queues}, False)

	@classmethod
	def removeWorldQueMsg(cls, roleID):
		for msg in list(cls.WorldQue):
			if msg.role['id'] == roleID:
				cls.WorldQue.remove(msg)

	@classmethod
	def worldMsg(cls, msg):
		cls.MsgID += 1
		model = Msg(cls.MsgID, nowtime_t(), msg, MessageDefs.NormalType, None, None)
		cls.WorldQue.append(model)

	@classmethod
	def chatWorldMsg(cls, game, msg, type=MessageDefs.WorldChatType, args=None):
		cls.MsgID += 1
		role = game.role.chatRoleModel
		model = Msg(cls.MsgID, nowtime_t(), msg, type, role, args)
		cls.WorldQue.append(model)
		if type == MessageDefs.WorldChatType:
			cls.OnChat('world', model)
		return model

	@classmethod
	def newsMsg(cls, msg, type=MessageDefs.NewsType, args=None):
		cls.MsgID += 1
		model = Msg(cls.MsgID, nowtime_t(), msg, type, None, args)
		cls.NewsQue.append(model)

	@classmethod
	def unionMsg(cls, union, msg):
		cls.MsgID += 1
		model = Msg(cls.MsgID, nowtime_t(), msg, MessageDefs.NormalType, None, None)
		que = cls.UnionQueMap.setdefault(union.id, deque(maxlen=ChatMessageMax))
		que.append(model)

	@classmethod
	def chatUnionMsg(cls, game, msg, type=MessageDefs.UnionChatType, args=None):
		cls.MsgID += 1
		role = game.role.chatRoleModel
		model = Msg(cls.MsgID, nowtime_t(), msg, type, role, args)
		que = cls.UnionQueMap.setdefault(game.union.id, deque(maxlen=ChatMessageMax))
		que.append(model)
		if type == MessageDefs.UnionChatType:
			cls.OnChat('union', model)
		return model

	@classmethod
	def roleMsg(cls, role, msg, type=MessageDefs.RoleChatType):
		cls.MsgID += 1
		model = Msg(cls.MsgID, nowtime_t(), msg, type, None, None)
		que = cls.RoleQueMap.setdefault(role.id, deque(maxlen=ChatMessageMax))
		que.append(model)

	@classmethod
	def chatRoleMsg(cls, gameRole, toRole, msg, type=MessageDefs.RoleChatType, args=None):
		cls.MsgID += 1
		# 发给对方的消息
		role = gameRole.chatRoleModel
		model = Msg(cls.MsgID, nowtime_t(), msg, type, role, args)
		que = cls.RoleQueMap.setdefault(toRole['id'], deque(maxlen=ChatMessageMax))
		que.append(model)

		# 己方消息存档
		# 只保存id，其余信息客户端会处理
		if args:
			toRole.update(args)
		model2 = Msg(cls.MsgID, nowtime_t(), msg, type, {'id': gameRole.id}, toRole)
		que = cls.RoleQueMap.setdefault(gameRole.id, deque(maxlen=ChatMessageMax))
		que.append(model2)

		if type == MessageDefs.RoleChatType:
			cls.OnChat('role', model)
		return model

	# 跑马灯渠道
	@classmethod
	def marqueeMsg(cls, msg, type=MessageDefs.MarqueeType, args=None):
		cls.MsgID += 1
		model = Msg(cls.MsgID, nowtime_t(), msg, type, None, args)
		return model

	# 钻石抽卡
	@classmethod
	def marqueeDrawCardMsg(cls, role, card, key):
		if card.star < 3:
			return
		d = {'name': role.name, 'star': str(card.star), 'card': card.name}
		msg = cls.marqueeMsg(L10nDefs.MarqueeCardInPub.format(**d), args={'key': key})
		return msg

	# 限定抽卡
	@classmethod
	def marqueeLimitDrawCardUpMsg(cls, role, card, key):
		if card.star < 3:
			return
		d = {'name': role.name, 'star': str(card.star), 'card': card.name}
		msg = cls.marqueeMsg(L10nDefs.MarqueeCardInLimitDrawUp.format(**d), args={'key': key})
		return msg

	# 自选抽卡
	@classmethod
	def marqueeGroupDrawCardUpMsg(cls, role, card, key):
		if card.star < 3:
			return
		d = {'name': role.name, 'star': str(card.star), 'card': card.name}
		msg = cls.marqueeMsg(L10nDefs.MarqueeCardInGroupDrawUp.format(**d), args={'key': key})
		return msg

	# 魂匣
	@classmethod
	def marqueeLimitDrawCardMsg(cls, role, card, key):
		if card.star < 3:
			return
		d = {'name': role.name, 'star': str(card.star), 'card': card.name}
		msg = cls.marqueeMsg(L10nDefs.MarqueeCardInLimitDraw.format(**d), args={'key': key})
		return msg

	# 限时神兽
	@classmethod
	def marqueeLimitBoxMsg(cls, role, card, key):
		if card.star < 3:
			return
		d = {'name': role.name, 'star': str(card.star), 'card': card.name}
		msg = cls.marqueeMsg(L10nDefs.MarqueeCardInLimitBox.format(**d), args={'key': key})
		return msg

	# 抽携带道具
	@classmethod
	def marqueeDrawHoldItemMsg(cls, role, holdItem, key):
		cfg = csv.held_item.items[holdItem.held_item_id]
		if cfg.quality < 4:
			return
		d = {'name': role.name, 'holdItem': cfg.name}
		msg = cls.marqueeMsg(L10nDefs.MarqueeHoldItemInDraw.format(**d), args={'key': key})
		return msg

	# 捕捉
	@classmethod
	def marqueeCaptureMsg(cls, role, card, key):
		if card.star < 3:
			return
		d = {'name': role.name, 'star': str(card.star), 'card': card.name}
		msg = cls.marqueeMsg(L10nDefs.MarqueeCardInCapture.format(**d), args={'key': key})
		return msg

	# 竞技场冠军
	@classmethod
	def marqueePvpTopRankMsg(cls, role, key):
		msg = cls.marqueeMsg(L10nDefs.MarqueePVPTopRank.format(name=role.name), args={'key': key})
		return msg

	# 精灵培养到6星及以上
	@classmethod
	def marqueeCardStarMsg(cls, role, card, key):
		if card.star < 6:
			return
		d = {'name': role.name, 'star': str(card.star), 'card': card.name}
		msg = cls.marqueeMsg(L10nDefs.MarqueeCardStar.format(**d), args={'key': key})
		return msg

	# S+精灵碎片合成
	@classmethod
	def marqueeFragCombCardMsg(cls, role, card, key):
		if card.star < 4:
			return
		d = {'name': role.name, 'star': str(card.star), 'card': card.name}
		msg = cls.marqueeMsg(L10nDefs.MarqueeCardInCombine.format(**d), args={'key': key})
		return msg

	# 以太乐园全通关
	@classmethod
	def marqueeRandomTowerPassMsg(cls, role, key):
		msg = cls.marqueeMsg(L10nDefs.MarqueeRandomMax.format(name=role.name), args={'key': key})
		return msg

	# 冒险之路通关达到X
	@classmethod
	def marqueeEndlessTowerPassMsg(cls, role, num, key):
		num = int(num % 100000)
		if num not in [50, 100, 150, 200, 250, 300, 350, 400, 450, 500, 550, 600]:
			return
		msg = cls.marqueeMsg(L10nDefs.MarqueeEndlessArrive.format(name=role.name, num=num), args={'key': key})
		return msg

	# 竞技场结算第一
	@classmethod
	def marqueePVPTopRankLastMsg(cls, role, key):
		msg = cls.marqueeMsg(L10nDefs.MarqueePVPTopRankLast.format(name=role.get('name', '')), args={'key': key})
		return msg

	# 石英大会结算第一
	@classmethod
	def marqueeCraftTopRankMsg(cls, role, key):
		msg = cls.marqueeMsg(L10nDefs.MarqueeCraftTopRank.format(name=role.get('name', '')), args={'key': key})
		return msg

	# 神兽召唤抽到S+以上精灵
	@classmethod
	def marqueeCardInLimitCardMsg(cls, role, csvCard, key):
		if csvCard.star < 4:
			return
		d = {'name': role.get('name', ''), 'star': str(csvCard.star), 'card': csvCard.name}
		msg = cls.marqueeMsg(L10nDefs.MarqueeCardInLimitCard.format(**d), args={'key': key})
		return msg

	# 跨服竞技场第一
	@classmethod
	def marqueeCrossArenaTopRankMsg(cls, role, key):
		msg = cls.marqueeMsg(L10nDefs.MarqueeCrossArenaTopRank.format(name=role.name), args={'key': key})
		return msg

	# 跨服竞技场精彩战报刷新
	@classmethod
	def marqueeCrossArenaTopHistoryRefreshMsg(cls, key):
		msg = cls.marqueeMsg(L10nDefs.MarqueeCrossArenaTopHistoryRefresh, args={'key': key})
		return msg

	# 对战竞技场精彩战报刷新
	@classmethod
	def marqueeCrossOnlineFightTopHistoryRefreshMsg(cls, key):
		msg = cls.marqueeMsg(L10nDefs.MarqueeCrossOnlineFightTopHistoryRefresh, args={'key': key})
		return msg

	# 跨服资源战精彩战报刷新
	@classmethod
	def marqueeCrossMineTopHistoryRefreshMsg(cls, key):
		msg = cls.marqueeMsg(L10nDefs.MarqueeCrossMineTopHistoryRefresh, args={'key': key})
		return msg

	@classmethod
	def modelSync(cls, msgID, game):
		if msgID >= cls.MsgID:
			return None
		ret = {}
		msgs = cls._listNewMsg(msgID, cls.WorldQue)
		if msgs:
			ret['world'] = msgs
		msgs = cls._listNewMsg(msgID, cls.NewsQue)
		if msgs:
			ret['news'] = msgs

		if game.union:
			msgs = cls._listNewMsg(msgID, cls.UnionQueMap.get(game.union.id, None))
			if msgs:
				ret['union'] = msgs

		#同步私聊
		msgs = cls._listNewMsg(msgID, cls.RoleQueMap.get(game.role.id, None))
		if msgs:
			ret['role'] = msgs

		if not ret:
			return None
		msgs = reduce(lambda x,y: x + y, ret.values())
		return {'msgID': cls.MsgID, 'msgs': msgs}

	@classmethod
	def roleNotify(cls, roleID, notifyID, args=None):
		cfg = csv.notify_message[notifyID]
		msg = cfg.content
		if args:
			msg = msg % args
		cls._notifyApp('role', notifyID, 0, cfg.subject, msg, roleID)

	@classmethod
	def _listNewMsg(cls, msgID, que):
		if que is None:
			return None
		ret = []
		for msg in reversed(que):
			if msg.id > msgID:
				ret.append(msg)
			else:
				break
		return ret

	@classmethod
	def _notifyApp(cls, msgType, notifyType, msgID, title, msg, arg=None):
		if cls.AppNotifyClosed:
			return

		jdata = json.dumps({'cmd': 'gamepush', 'keepalive': True, 'serv': cls.ServerKey, 'params': {
			'msgtype': msgType,
			'msgid': msgID,
			'pwd': AppNotifyInternalPassword,
			'ntftype': notifyType,
			'ttl': title,
			'msg': msg,
			'arg': arg,
		}})
		data = struct.pack('!I', len(jdata)) + jdata
		cls.AppNotifyStream.write(data)

	@classmethod
	def newsLogin(cls, role, msg):
		cls.newsMsg(msg, args={'role1': role.chatRoleModel})

	@classmethod
	def newsCardMsg(cls, role, card, cfrom):
		# 小于3星不显示
		if card.star < 3:
			return

		card.display()
		d = {'name': role.name, 'star': str(card.star), 'card': card.name}
		args = {'role1': role.chatRoleModel, 'card1': card.id}
		if cfrom == 'pub': # 普通抽卡
			cls.newsMsg(L10nDefs.NewsCardInPub.format(**d), args=args)
		elif cfrom == 'comb': # 合成
			cls.newsMsg(L10nDefs.NewsCardInCombine.format(**d), args=args)
		elif cfrom == 'limit_draw': # 魂匣
			cls.newsMsg(L10nDefs.NewsCardInLimitDraw.format(**d), args=args)
		elif cfrom == 'limit_draw_up': # 限定抽卡up
			cls.newsMsg(L10nDefs.NewsCardInLimitDrawUp.format(**d), args=args)
		elif cfrom == 'group_draw_up': # 自选抽卡up
			cls.newsMsg(L10nDefs.NewsCardInGroupDrawUp.format(**d), args=args)
		elif cfrom == 'capture': # 捕抓
			cls.newsMsg(L10nDefs.NewsCardInCapture.format(**d), args=args)
		elif cfrom == 'limitbox': # 限时神兽
			cls.newsMsg(L10nDefs.NewsCardInLimitBox.format(**d), args=args)
		elif cfrom == 'other':
			cls.newsMsg(L10nDefs.NewsCardInOther.format(**d), args=args)

	@classmethod
	def newsHoldItemMsg(cls, role, holdItem, cfrom):
		cfg = csv.held_item.items[holdItem.held_item_id]
		if cfg.quality < 4:
			return
		d = {'name': role.name, 'holdItem': cfg.name}
		args = {'role1': role.chatRoleModel}
		if cfrom == 'draw': # 饰品抽卡
			cls.newsMsg(L10nDefs.NewsHoldItemInDraw.format(**d), args=args)
		# elif cfrom == 'comb':
		# 	cls.newsMsg(L10nDefs.NewsEquipInCombine.format(**d))
		# elif cfrom == 'box':
		# 	cls.newsMsg(L10nDefs.NewsEquipInBox.format(**d))
		# elif cfrom == 'other':
		# 	cls.newsMsg(L10nDefs.NewsEquipInOther.format(**d))

	@classmethod
	def newsCardAdvanceMsg(cls, role, card):
		d = {
			9: L10nDefs.NewsCardAdvance9,
			10: L10nDefs.NewsCardAdvance10,
			11: L10nDefs.NewsCardAdvance11,
			12: L10nDefs.NewsCardAdvance12,
			13: L10nDefs.NewsCardAdvance13,
			14: L10nDefs.NewsCardAdvance14,
			15: L10nDefs.NewsCardAdvance15,
			16: L10nDefs.NewsCardAdvance16,
			17: L10nDefs.NewsCardAdvance17,
			18: L10nDefs.NewsCardAdvance18,
			19: L10nDefs.NewsCardAdvance19,
		}
		msg = d.get(card.advance, None)
		if msg is None:
			return
		card.display()
		cls.newsMsg(msg.format(name=role.name, card=card.name), args={'role1': role.chatRoleModel, 'card1': card.id})

	@classmethod
	def newsCardStarMsg(cls, role, card):
		if card.star < 5:
			return
		card.display()
		msg = L10nDefs.NewsCardStar.format(name=role.name, card=card.name, star=card.star)
		cls.newsMsg(msg, args={'role1': role.chatRoleModel, 'card1': card.id})

	@classmethod
	def newsBreakEggMsg(cls, name, rate, amount, gainType):
		typemap = {'rmb': L10nDefs.RmbText, 'gold': L10nDefs.GoldText}
		gainType = typemap.get(gainType)
		cls.newsMsg(L10nDefs.NewsBreakEgg.format(name=name, amount=amount, gainType=gainType, rate=rate), type=MessageDefs.BreakEggType)

	@classmethod
	def newsPVPTopRankMsg(cls, role):
		cls.newsMsg(L10nDefs.NewsPVPTopRank.format(name=role.name), args={'role1': role.chatRoleModel})

	@classmethod
	def newsRandomTowerPassMsg(cls, role):
		cls.newsMsg(L10nDefs.NewsRandomMax.format(name=role.name), args={'role1': role.chatRoleModel})

	@classmethod
	def newsEndlessTowerPassMsg(cls, role, num):
		num = int(num % 100000)
		if num not in [50, 100, 150, 200, 250, 300, 350, 400, 450, 500, 550, 600]:
			return
		cls.newsMsg(L10nDefs.NewsEndlessArrive.format(name=role.name, num=num), args={'role1': role.chatRoleModel})

	@classmethod
	def newsPVPTopRankLastMsg(cls, role):
		chatRoleModel = {
			'id': role.get('id', ''),
			'name': role.get('name', ''),
			'logo': role.get('logo', 0),
			'frame': role.get('frame', 0),
			'title': role.get('title_id', 0),
			'level': role.get('level', 0),
			'vip': role.get('vip_level', 0),
		}
		cls.newsMsg(L10nDefs.NewsPVPTopRankLast.format(name=role.get('name', '')), args={'role1': chatRoleModel})

	@classmethod
	def newsCraftTopRankMsg(cls, role):
		chatRoleModel = {
			'id': role.get('id', ''),
			'name': role.get('name', ''),
			'logo': role.get('logo', 0),
			'frame': role.get('frame', 0),
			'title': role.get('title_id', 0),
			'level': role.get('level', 0),
			'vip': role.get('vip_level', 0),
		}
		cls.newsMsg(L10nDefs.NewsCraftTopRank.format(name=role.get('name', '')), args={'role1': chatRoleModel})

	@classmethod
	def newsCrossArenaTopRankMsg(cls, role):
		cls.newsMsg(L10nDefs.NewsCrossArenaTopRank.format(name=role.name), args={'role1': role.chatRoleModel})

	@classmethod
	def newsCrossArenaTopHistoryRefreshMsg(cls):
		cls.newsMsg(L10nDefs.NewsCrossArenaTopHistoryRefresh, args={'role1': {}})

	@classmethod
	def newsCrossOnlineFightTopHistoryRefreshMsg(cls):
		cls.newsMsg(L10nDefs.NewsCrossOnlineFightTopHistoryRefresh, args={})

	@classmethod
	def newsCrossMineTopHistoryRefreshMsg(cls):
		cls.newsMsg(L10nDefs.NewsCrossMineTopHistoryRefresh, args={})

	@classmethod
	def worldCardShareMsg(cls, game, card):
		card.display()
		cls.chatWorldMsg(game, L10nDefs.NewsCardShare.format(name=game.role.name, card=card.name), MessageDefs.WorldCardShareType, args={'card1': card.id})

	@classmethod
	def unionCardShareMsg(cls, game, card):
		card.display()
		cls.chatUnionMsg(game, L10nDefs.NewsCardShare.format(name=game.role.name, card=card.name), MessageDefs.UnionCardShareType, args={'card1': card.id})

	@classmethod
	def worldCloneInviteMsg(cls, game, msgFormat, roomID, csvID):
		cls.chatWorldMsg(game, L10nDefs.WorldCloneInvite % msgFormat, MessageDefs.WorldCloneInviteType, {'nature_room_id': roomID, 'nature_id': csvID})

	@classmethod
	def unionCloneInviteMsg(cls, game, msgFormat, roomID, csvID):
		cls.chatUnionMsg(game, L10nDefs.UnionCloneInvite % msgFormat, MessageDefs.UnionCloneInviteType, {'nature_room_id': roomID, 'nature_id': csvID})

	@classmethod
	def friendCloneInviteMsg(cls, game, toRole, msgFormat, roomID, csvID):
		msg = cls.chatRoleMsg(game.role, toRole, L10nDefs.FriendCloneInvite % msgFormat, MessageDefs.FriendCloneInviteType, {'nature_room_id': roomID, 'nature_id': csvID})
		return msg

	@classmethod
	def worldReunionInvite(cls, game, yyID, end_time):
		cls.chatWorldMsg(game, L10nDefs.ReunionInvite.format(name=game.role.name), MessageDefs.WorldReunionInvite, {'roleID': game.role.id, 'yyID': yyID, 'end_time': end_time})

	@classmethod
	def recommendReunionInvite(cls, game, toRole, yyID, end_time):
		msg = cls.chatRoleMsg(game.role, toRole, L10nDefs.ReunionInvite.format(name=game.role.name), MessageDefs.RecommendReunionInvite, {'roleID': game.role.id, 'yyID': yyID, 'end_time': end_time})
		return msg

	@classmethod
	def unionJoinUpMsg(cls, game):
		desc = game.union.join_desc
		if not desc:
			desc = L10nDefs.unionJoinupDesc
		msg = L10nDefs.unionJoinupInvite.format(name=game.union.name, desc=desc)
		args = {
			'union1': game.union.id,
		}
		cls.chatWorldMsg(game, msg, MessageDefs.UnionJoinUpType, args)

	@classmethod
	def unionSendRedPacketMsg(cls, game, name):
		msg = L10nDefs.UnionRedPacketSend.format(role=game.role.name)
		cls.chatUnionMsg(game, msg, type=MessageDefs.UnionRedPacketType)

	@classmethod
	def unionGetRedPacketMsg(cls, game, packet_flag, packet_type, role_send, count):
		msg = ''
		typeMap = {0: L10nDefs.GoldText, 1: L10nDefs.RmbText, 2: L10nDefs.SoulText}
		if packet_flag == UnionDefs.PacketFlagRole:
			msg = L10nDefs.UnionRedPacketGetRole.format(role_get=game.role.name, role_send=role_send, count=count, type=typeMap[packet_type])
		if packet_flag == UnionDefs.PacketFlagSys:
			msg = L10nDefs.UnionRedPacketGetSys.format(role_get=game.role.name, count=count, type=typeMap[packet_type])
		cls.chatUnionMsg(game, msg, type=MessageDefs.UnionRedPacketType)

	@classmethod
	def whereNameShareBattleMsg(cls, battleName):
		d = {
			'arena': L10nDefs.arena,
			'crossArena': L10nDefs.crossArena,
			'onlineFight': L10nDefs.onlineFight,
			'crossMine': L10nDefs.crossMine,
		}
		whereName = d.get(battleName, None)
		if whereName is None:
			return
		return whereName

	@classmethod
	def worldShareBattleMsg(cls, game, battleID, enemyName, src, crossKey):
		# 目前只有竞技场
		whereName = cls.whereNameShareBattleMsg(src)
		if crossKey:
			argsD = {'battleID': battleID, 'from': src, 'crossKey': crossKey}
		else:
			argsD = {'battleID': battleID, 'from': src}
		cls.chatWorldMsg(game, L10nDefs.battleShare.format(where=whereName, enemy=enemyName), MessageDefs.BattleShareType, args=argsD)

	@classmethod
	def worldSendYYHuoDongRedPacketMsg(cls, game, message, idx, yyID):
		cls.chatWorldMsg(game, L10nDefs.HuoDongRedPacket.format(role_name=game.role.name, message=message), MessageDefs.YYHuoDongRedPacketType, args={'hd_redPacket_idx': idx, 'yy_id': yyID})

	@classmethod
	def marqueeBroadcast(cls, role, key, **kwargs):
		if not cls.MarqueeMap.get(key, 0):
			return
		msg = None
		# 钻石抽卡
		if key == MessageDefs.MqDrawCard:
			msg = cls.marqueeDrawCardMsg(role, kwargs['card'], key)
		# 限定抽卡up
		elif key == MessageDefs.MqLimitDrawCardUp:
			msg = cls.marqueeLimitDrawCardUpMsg(role, kwargs['card'], key)
		# 自选抽卡up
		elif key == MessageDefs.MqGroupDrawCardUp:
			msg = cls.marqueeGroupDrawCardUpMsg(role, kwargs['card'], key)
		# 魂匣
		elif key == MessageDefs.MqLimitDrawCard:
			msg = cls.marqueeLimitDrawCardMsg(role, kwargs['card'], key)
		# 限时神兽
		elif key == MessageDefs.MqLimitBox:
			msg = cls.marqueeLimitBoxMsg(role, kwargs['card'], key)
		# 抽携带道具
		elif key == MessageDefs.MqDrawHoldItem:
			msg = cls.marqueeDrawHoldItemMsg(role, kwargs['holdItem'], key)
		# 捕捉
		elif key == MessageDefs.MqCapture:
			msg = cls.marqueeCaptureMsg(role, kwargs['card'], key)
		# 竞技场冠军
		elif key == MessageDefs.MqPvpTopRank:
			msg = cls.marqueePvpTopRankMsg(role, key)
		# 碎片合成S+精灵
		elif key == MessageDefs.MqFragCombCard:
			msg = cls.marqueeFragCombCardMsg(role, kwargs['card'], key)
		# 精灵培养到6星及以上
		elif key == MessageDefs.MqCardStar:
			msg = cls.marqueeCardStarMsg(role, kwargs['card'], key)
		# 以太乐园全通关
		elif key == MessageDefs.MqRandomTowerPass:
			msg = cls.marqueeRandomTowerPassMsg(role, key)
		# 冒险之路通关达到X
		elif key == MessageDefs.MqEndlessTowerPass:
			msg = cls.marqueeEndlessTowerPassMsg(role, kwargs['num'], key)
		# 竞技场结算第一
		elif key == MessageDefs.MqPvpTopRankLast:
			msg = cls.marqueePVPTopRankLastMsg(role, key)
		# 石英大会结算第一
		elif key == MessageDefs.MqCraftTopRank:
			msg = cls.marqueeCraftTopRankMsg(role, key)
		# 神兽召唤抽到S+以上精灵
		elif key == MessageDefs.MqCardInLimitCard:
			msg = cls.marqueeCardInLimitCardMsg(role, kwargs['csvCard'], key)
		# 跨服竞技场第一
		elif key == MessageDefs.MqCrossArenaTopRank:
			msg = cls.marqueeCrossArenaTopRankMsg(role, key)
		# 跨服竞技场精彩战报刷新
		elif key == MessageDefs.MqCrossArenaTopHistoryRefresh:
			msg = cls.marqueeCrossArenaTopHistoryRefreshMsg(key)
		# 对战竞技场精彩战报刷新
		elif key == MessageDefs.MqCrossOnlineFightTopHistoryRefresh:
			msg = cls.marqueeCrossOnlineFightTopHistoryRefreshMsg(key)
		# 跨服资源战精彩战报刷新
		elif key == MessageDefs.MqCrossMineTopHistoryRefresh:
			msg = cls.marqueeCrossMineTopHistoryRefreshMsg(key)

		if not msg:
			return
		data = {
			'msg': {'msgs': [msg]},
		}
		from game.session import Session
		Session.broadcast('/game/push', data)

	@classmethod
	def delChatRoleMsg(cls, gameRole, roleID):
		que = cls.RoleQueMap.setdefault(gameRole.id, deque(maxlen=ChatMessageMax))
		newQue = deque(maxlen=ChatMessageMax)
		for model in que:
			if model.role['id'] == roleID:
				continue
			if model.args is not None and model.args.get('id', None) == roleID:
				continue
			newQue.append(model)
		cls.RoleQueMap[gameRole.id] = newQue
