#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2014 YouMi Information Technology Inc.
Copyright (c) 2018 TianJi Information Technology Inc.

implement LogicTask and BaseHandler together in here
new server framework use TCPServer, and the logic code compatible with RequestHandler
'''

# --------------------------
# -- TGame
# -- game通用task, 针对c->s pingpong 请求响应模式
# --
# -- client send data scheme
# -- {
# -- 	id <str> accountID
# -- 	syn <int> synID
# --  csv <int> csv版本号
# --  msg <int> 走马灯、聊天消息id
# -- 	input <table> 请求数据
# -- }
# --
# -- client recv data scheme
# -- {
# -- 	ret <bool> 是否成功
# -- 	err <*str> 错误描述
# --  view <*table> 请求响应数据
# --  model <*table> game model覆盖数据
# --  sync <*table> game model同步数据
# --  csv <*table> csv数据
# --  msg <*table> 走马灯、聊天消息数据
# -- }
# --

import sys
import lz4
import time
import zlib
import os.path
import traceback
import msgpack
import binascii
from Crypto.Cipher import AES

from game.object.game import ObjectFeatureUnlockCSV
from tornado.gen import coroutine, Return

from game import AuthError, ServerError, ClientError
from game.session import Session
from game.object import MailDefs, AchievementDefs, FeatureDefs
from game.object.game.gm import ObjectGMYYConfig
from game.object.game.mail import ObjectMailGlobal
from game.object.game.rank import ObjectRankGlobal
from game.object.game.message import ObjectMessageGlobal
from game.object.game.yyhuodong import ObjectYYHuoDongFactory
from game.object.game.society import ObjectSocietyGlobal
from game.object.game.servrecord import ObjectServerGlobalRecord
from game.object.game.cross_mine import ObjectCrossMineGameGlobal

from framework import todayinclock5date2int, nowtime_t, weekinclock5date2int
from framework.csv import csv, ErrDefs
from framework.log import logger
from framework.wnet import WANetTask
import copy


def areaKey2Area(areakey):
	return int(areakey.split('.')[-1])


class RequestHandlerTask(object):
	url = None
	disabled = False

	def __init__(self, app, nett):
		self.application = app
		self.ntask = nett
		self.session = None
		self.ackData = None
		self.errData = None
		self.finished = False
		self.initTime = time.time()
		self.beginRunTime = 0
		self.endRunTime = 0
		self.loged = False

	@property
	def logger(self):
		return self.ntask.conn.logger

	@property
	def server(self):
		return self.session.server

	@property
	def rpcs(self):
		d = {
			'arena': self.rpcArena,
			'cross_arena': self.rpcPVP,
			'craft': self.rpcCraft,
			'cross_craft': self.rpcPVP,
			'cross_online_fight': self.rpcPVP,
			'union_fight': self.rpcUnionFight,
			'gym': self.rpcGym,
			'card_fight': self.rpcCardFight,
			'cross_mine': self.rpcPVP,
			'hunting': self.rpcHunting,
			'cross_union_fight': self.rpcPVP,
		}
		return d

	@property
	def dbcGame(self):
		return self.application.dbcGame

	@property
	def dbcGift(self):
		return self.application.dbcGift

	@property
	def rpcPVP(self):
		return self.application.rpcPVP

	@property
	def rpcArena(self):
		return self.application.rpcArena

	@property
	def rpcUnion(self):
		return self.application.rpcUnion

	@property
	def rpcCraft(self):
		return self.application.rpcCraft

	@property
	def rpcClone(self):
		return self.application.rpcClone

	@property
	def rpcUnionFight(self):
		return self.application.rpcUnionFight

	@property
	def rpcYYHuodong(self):
		return self.application.rpcYYHuodong

	@property
	def rpcGym(self):
		return self.application.rpcGym

	@property
	def rpcHunting(self):
		return self.application.rpcHunting

	@property
	def rpcAnti(self):
		return self.application.rpcAnti

	@property
	def rpcCardFight(self):
		return self.application.rpcCardFight

	@property
	def rpcCardComment(self):
		return self.application.rpcCardComment

	@property
	def rpcCardScore(self):
		return self.application.rpcCardScore

	@property
	def mailQueue(self):
		return self.application.mailQueue

	@property
	def sdkQueue(self):
		return self.application.sdkQueue

	@property
	def servKey(self):
		return self.application.servKey

	@property
	def servName(self):
		return self.application.servName

	@property
	def servMerged(self):
		return self.application.servMerged

	@property
	def roleNameCache(self):
		return self.application.roleNameCache

	@property
	def servNode(self):
		return self.application.servNode

	@property
	def game(self):
		return self.session.game

	@property
	def gameServID(self):
		return self.session.servID

	@property
	def TimeInSecond(self):
		return Session.TimeInSecond

	@property
	def DateIntNow(self):
		return Session.DateIntNow

	@property
	def DateIntInClock5(self):
		return Session.DateIntInClock5

	@property
	def MonthIntNow(self):
		return Session.MonthIntNow

	def prepare(self):
		# self.logger.info(self.ntask.flag)
		# self.logger.info(self.ntask.url)
		# self.logger.info('synID %d ackID %d', self.ntask.synID, self.ntask.ackID)
		# self.logger.info(self.ntask.data)

		data = self.ntask.data
		self.input = data.pop('input', {})
		self.sync = data
		# lua的msgpack会把顺序数值下标的table认为是list
		# input肯定是lua table
		if isinstance(self.input, list):
			self.input = {i+1: self.input[i] for i in xrange(len(self.input))}

		accountID = data.get('id', 0)
		serverID = data.get('servid', None)
		serverKey = data.get('servkey', None)
		# serverID = areaKey2Area(serverKey)
		session = Session.getSession((serverID, accountID))
		if session is None:
			self.logger.warning('AuthError session not existed for %s %s' % (serverKey, (serverID, accountID)))
			raise AuthError()
		if session.ltaskRunning:
			raise ClientError(ErrDefs.ltaskRunning)
		session.ltaskRunning = True
		self.session = session
		# session will change the WANetClientConn AES pwd
		session.setClientConn(self.ntask.conn)

		synID = self.ntask.synID
		if accountID != self.session.accountID:
			self.logger.warning('AuthError accountID error %d, %d' % (accountID, self.session.accountID))
			raise AuthError()
		if not self.session.changeNewSynID(synID):
			self.logger.warning('AuthError changeNewSynID error %d, %d' % (synID, self.session.clientSynID))
			raise AuthError()

		self.accountID = accountID

	@coroutine
	def request_begin(self):
		# 黑名单检测
		# from game.object.game.gm import ObjectBlackList
		# ip = self.request.remote_ip
		# if ip in ObjectBlackList.blackList:
		# 	raise ClientError('ip in blacklist!')

		# 更新日常记录
		# NOTE: 这里可能有临界点问题，到相关逻辑处理时日期已经改变
		ndi = todayinclock5date2int()
		if ndi != self.game.dailyRecord.date:
			self.game.dailyRecord.renew()
			# 进化石转化次数恢复
			self.game.role.refreshMegaConvertTimes()

		# # 更新每周记录
		# if weekinclock5date2int() != self.game.weeklyRecord.date:
		# 	self.game.weeklyRecord.renew()

		# 更新每月记录
		if self.MonthIntNow != self.game.monthlyRecord.month:
			self.game.monthlyRecord.renew()

		# self.game.tasks.refreshStatus()

		# 同步model版本号
		self.syncVersion = self.sync.pop('sync', 0)

		# 同步csv版本号
		self.csvVersion = self.sync.pop('csv', 0)

		# 同步json csv版本号
		# self.jsonCsvVersion = self.sync.pop('json_csv', 0)

		# 同步走马灯消息ID
		self.msgID = self.sync.pop('msg', 0)

		# 同步走马灯消息ID
		self.globalRecordLastTime = self.sync.pop('global_record_last_time', 0)

		self.game.role.last_time = self.TimeInSecond

		# 记录最后操作时间
		if self.game.role.union_db_id:
			self.game.role.union_last_time = self.TimeInSecond

		# 如果有好友就刷新
		if self.game.society.friends:
			ObjectSocietyGlobal.onRoleInfo(self.game)

	@coroutine
	def request_end(self):
		# 同步newbie_guide
		if self.sync:
			roleSync = self.sync.get('role', None)
			if roleSync:
				if 'guideID' in roleSync:
					guideIDx = int(roleSync.get('guideID'))
					if guideIDx not in self.game.role.newbie_guide:
						self.game.role.newbie_guide.append(guideIDx)
				if 'client_flag' in roleSync:
					self.game.role.client_flag = int(roleSync.get('client_flag'))

		# 一直在线的玩家，接收最新的全局邮件
		mailsCount = ObjectMailGlobal.countMails()
		if self.game.role.global_mail_idx < mailsCount:
			mailThumbs = ObjectMailGlobal.getMails(self.game.role.global_mail_idx)
			for thumb in mailThumbs:
				sendFlag = False
				if thumb.get('mtype', None) == MailDefs.TypeGlobal:
					sendFlag = True
				elif thumb.get('mtype', None) == MailDefs.TypeServer and thumb['time'] >= self.game.role.created_time:
					sendFlag = True
				elif thumb.get('mtype', None) == MailDefs.TypeVip and self.game.role.vip_level >= thumb['beginVip'] and self.game.role.vip_level <= thumb['endVip']:
					sendFlag = True
				if sendFlag:
					self.game.role.addMailThumb(thumb['db_id'], thumb['subject'], thumb['time'], thumb['type'], thumb['sender'], True, thumb['hasattach'])
			self.game.role.global_mail_idx = mailsCount

		# 一直在线的玩家，接收最新的公会邮件
		if self.game.union:
			mailsCount = self.game.union.countMails()
			if self.game.role.union_mail_idx < mailsCount:
				mailThumbs = self.game.union.getMails(self.game.role.union_mail_idx)
				for thumb in mailThumbs:
					if thumb['time'] < self.game.role.union_join_time:
						continue
					self.game.role.addMailThumb(thumb['db_id'], thumb['subject'], thumb['time'], thumb['type'], thumb['sender'], True, thumb['hasattach'])
			self.game.role.union_mail_idx = mailsCount

		# 只刷新活动开启，倒计时不那么重要，无需每次请求重新计算
		self.game.role.refreshYYOpen(False)

		# 试炼活动任务隔天不清空的问题 不能放begin, 战斗隔天结束状态会记录进去
		if self.game.role.random_tower_db_id:
			self.game.randomTower.refresh()

		# 查询可抢的公会红包
		if self.game.union and self.game.union.packet_last_time != self.game.role.union_packet_last_time:
			from game.handler._union import unionCallAsync
			yield unionCallAsync(self.rpcUnion, 'GameRoleSync', self.game.role)
			self.game.role.union_packet_last_time = self.game.union.packet_last_time

		# 记录最后操作时间
		if self.game.role.union_db_id or self.game.role.union_join_que:
			from game.handler._union import refreshUnionMember
			refreshUnionMember(self.rpcUnion, self.game.role)

	def write(self, data):
		self.ackData = data

	def write_error(self, err, model=None):
		self.errData = {
			'ret': False,
			'err': err,
		}
		if model:
			self.errData['model'] = model


	def finish(self):
		if self.finished:
			return

		if self.session:
			self.session.ltaskRunning = False
		if self.session is None:
			self.ackData = self.errData
			return
		if self.session and self.session.clientLastResponse:
			d = self.session.clientLastResponse
			pwd = self.session.getPwdForNewConn()
			if pwd:
				d['session_pwd'] = pwd
			self.ackData = d
			return

		d = self.ackData or {}
		if 'ret' not in d:
			d['ret'] = True
		try:
			lastsync = None
			if hasattr(self, 'syncVersion'):
				if self.syncVersion < self.game.syncVersion:
					logger.warning('client model sync version error, client %d, server %d', self.syncVersion, self.game.syncVersion)
					lastsync = self.game.lastSyncCache
			sync = self.game.modelSync
			if sync:
				if lastsync:
					def sync_merge(base, head):
						for k, v in head.iteritems():
							if isinstance(v, dict):
								base[k] = sync_merge(base.get(k, {}), v)
							else:
								base[k] = v
						return base

					sync = sync_merge(lastsync, sync)
				if 'sync' in d:
					sync.update(d['sync'])
				d['sync'] = sync
		except:
			logger.exception('Game modelSync error')

		pwd = self.session.getPwdForNewConn()
		if pwd:
			d['session_pwd'] = pwd

		# # 配表刷新
		if ObjectGMYYConfig.isNewCsvModel(getattr(self, 'csvVersion', 0)):
			d['csv'] = ObjectGMYYConfig.getCsvModel()

		# 走马灯消息和聊天消息
		msgsD = ObjectMessageGlobal.modelSync(getattr(self, 'msgID', 0), self.game)
		if msgsD:
			d['msg'] = msgsD

		# 服务器记录刷新
		model = ObjectServerGlobalRecord.modelSync(getattr(self, 'globalRecordLastTime', 0))
		if model:
			d['global_record'] = model

		if self.errData:
			d.update(self.errData)
		self.ackData = d
		if self.session:
			self.session.clientLastResponse = d

	@coroutine
	def _run(self):
		if not getattr(self.session, 'gameLoad', False):
			raise Exception('session no load game')
		if self.session.isLastRepeatedPost():
			raise Return(None)
		if self.disabled:
			raise ServerError(ErrDefs.HandlerDisabled)

		# game login 是直接处理post
		role = self.game.role
		old_pokedex = len(role.pokedex)
		old_fight = role.top6_fighting_point
		old_star = role.gateStarSum
		old_level = role.level
		old_top_cards = role.top_cards
		old_stamina = role.stamina

		# self.game.dailyRecord.online_time += nowtime_t() - role.last_time

		yield self.request_begin()
		yield self.run()
		yield self.request_end()

		if old_pokedex != len(role.pokedex):
			yield ObjectRankGlobal.onKeyInfoChange(self.game, 'pokedex')
		if old_fight != role.top6_fighting_point:
			yield ObjectRankGlobal.onKeyInfoChange(self.game, 'fight')
		if old_star != role.gateStarSum:
			yield ObjectRankGlobal.onKeyInfoChange(self.game, 'star')
		if self.game.cards.fightChangeCards:
			yield ObjectRankGlobal.onKeyInfoChange(self.game, 'card1fight')
		if self.game.cards.fightChangeCloneDeployCard and self.game.role.clone_room_db_id:
			yield self.rpcClone.call_async("DeployCard", self.game.role.id, self.game.cards.fightChangeCloneDeployCard[0], self.game.cards.fightChangeCloneDeployCard[1])
			self.game.cards.fightChangeCloneDeployCard = None
		if self.game.role.craft_record_db_id:
			if len(old_top_cards) < 10 and len(role.top_cards) >= 10:
				from game.object.game.craft import ObjectCraftInfoGlobal
				from game.handler._craft import refreshCardsToPVP
				cards = self.game.role.top_cards[:10]
				yield refreshCardsToPVP(self.rpcCraft, self.game, hold_cards=cards)
				self.game.cards.craftAutoComplete = False
				ObjectCraftInfoGlobal.onRoleInfo(self.game)
		if old_stamina != role.stamina:
			self.game.achievement.onTargetTypeCount(AchievementDefs.StaminaCount)
		if self.game.refreshMarkMaxFight or self.game.cards.markIDMaxFightChangeCards:
			if self.game.refreshMarkMaxFight:
				self.game.cards.refreshMarkIDMaxFight()
			updateInfo = self.game.cards.getCardFightUpdateInfo()
			inRankCards = yield self.rpcCardFight.call_async("CardFightUpdate", self.game.role.makeCardFightRoleModel(), updateInfo)
			for card in self.game.cards.markIDMaxFightChangeCards.itervalues():
				if card and card.id in inRankCards:
					card.display()
			self.game.refreshMarkMaxFight = False
			self.game.cards.markIDMaxFightChangeCards = {}

		# 刷新世界等级
		worldLevelRankSize = csv.world_level.base[1].topRank
		if role.fight_rank <= worldLevelRankSize and role.level != old_level:
			yield ObjectServerGlobalRecord.refreshWorldLevel(self.dbcGame)

		# 开启远征进阶线路
		specialHuntingLevel = ObjectFeatureUnlockCSV.getOpenLevel(FeatureDefs.SpecialHunting)
		if old_level < specialHuntingLevel <= role.level:
			if role.hunting_record_db_id:
				yield self.rpcHunting.call_async('OpenSpecialRoute', role.hunting_record_db_id)
				role.huntingSync = 0

	@coroutine
	def run(self):
		raise NotImplementedError()

	@coroutine
	def runInServer(self):
		undeterminedExcep = False
		pwd = self.ntask.conn.aesPwd # client是什么密钥，回包就是什么密钥
		self.beginRunTime = time.time()
		try:
			self.prepare()
			yield self._run()
			self.finish()
			self.finished = True

		except AuthError:
			self.write_error("auth_error")

		except ClientError, e:
			self.write_error(e.log_message, e.kwargs.get('model', None))

		except ServerError, e:
			self.write_error(e.log_message)

		except Exception, e:
			err = '%s: %s' % (type(e).__name__, str(e))
			import framework
			if hasattr(framework, '__dev__'):
				excepStack = traceback.format_exc()
				err = '%s\n\n%s' % (err, excepStack)
			self.write_error(err)
			undeterminedExcep = True

		finally:
			self.finish()
			self.finished = True
			self.endRunTime = time.time()
			if undeterminedExcep:
				self.log_exception()

		raise Return(WANetTask(self.ntask.conn, url=self.ntask.url, data=self.ackData, synID=self.ntask.synID, pwd=pwd))

	def log_request(self):
		if self.loged:
			return
		self.loged = True
		self.logger.info(self._request_summary())

	def log_exception(self, force=False):
		if self.loged and not force:
			return
		self.loged = True
		self.logger.exception(self._request_summary('EXCP'))

	def _request_summary(self, prefix=None):
		input, err = '{}', self.errData['err'] if self.errData else ''
		if prefix is None:
			prefix = 'ERR' if err else 'REQ'
		try:
			input = str(self.input)
		except:
			pass

		try:
			import binascii
			if hasattr(self, 'session') and self.session.gameLoad:
				prefix = '%s %d %s' % (prefix, self.game.role.uid, binascii.hexlify(self.game.role.id))
		except:
			pass
		return '%s %s %sB %.2fms %.2fms %.2fms %s %s' % (prefix, self.ntask.url, self.ntask.len, 1000.0 * self.ntask.ioTime, 1000.0 * (self.endRunTime - self.beginRunTime), 1000.0 * (time.time() - self.ntask.firstReadTime), input, err)

	# 服务器主动推送 s->c
	def push(self, url, data):
		data['ret'] = True
		self.session.sendTaskToClient(url, data)

	# 服务器主动广播 s->all(c)
	def broadcast(self, url, data):
		data['ret'] = True
		self.session.broadcastTask(url, data)

	# 服务器主动推送 s->c
	def pushToRole(self, url, data, toRoleID):
		if not isinstance(toRoleID, list):
			toRoleID = [toRoleID]
		Session.broadcast(url, data, roles=toRoleID)

	# 服务器主动广播 s->union(c)
	def broadcastToUnion(self, url, data):
		if not self.game.union:
			return
		Session.broadcast(url, data, roles=self.game.union.members.keys())

	def destroy(self):
		del self.ntask
		del self.session
		del self.ackData
		del self.errData
		del self.input
		del self.sync