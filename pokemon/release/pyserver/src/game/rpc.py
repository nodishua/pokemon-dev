#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2014 YouMi Information Technology Inc.
'''

import framework
from framework.csv import csv, MergeServ
from framework.log import logger
from framework.helper import objectid2string, string2objectid
from framework.service.rpc_client import nsqrpc_coroutine as rpc_coroutine
from framework import todayinclock5elapsedays
from game import globaldata
from game.object.game.cross_union_fight import ObjectCrossUnionFightGameGlobal
from game.object.game.servrecord import ObjectServerGlobalRecord
from nsqrpc.server import notify
from game.object.game.cross_arena import ObjectCrossArenaGameGlobal
from game.object.game.gym import ObjectGymGameGlobal
from game.session import Session
from game.globaldata import GameServInternalPassword, CrossBraveChallengeRanking, CrossHorseRaceRanking
from game.object.game.gm import ObjectGMYYConfig
from game.object.game.yyhuodong import ObjectYYHuoDongFactory
from game.object.game.cross_craft import ObjectCrossCraftGameGlobal
from game.object.game.cross_online_fight import ObjectCrossOnlineFightGameGlobal
from game.object.game.cross_fishing import ObjectCrossFishingGameGlobal
from game.object.game.cross_mine import ObjectCrossMineGameGlobal
from game.handler.robot import createRobots

from tornado.gen import Return, moment, sleep, coroutine

import binascii
import io
import gc
import pdb
import time
import random
from rpdb import Rpdb

NodeCallTimeout = 5
NodeCommitTimeout = 4*NodeCallTimeout # 防止组织者挂了，参与者一直阻塞死等

class GameRPC(object):
	def __init__(self, game):
		self.game = game
		self._rpdb = None
		self._uids = {} # {uid: role.id}

		self.tscVotes = {} # {transaction: (key, time)}
		self.tscCommits = {}

		self._lastRefreshCSV = 0 # 上次配表刷新时间

	@property
	def dbcGame(self):
		return self.game.dbcGame

	@property
	def rpcArena(self):
		return self.game.rpcArena

	@property
	def rpcUnion(self):
		return self.game.rpcUnion

	@property
	def machineStatus(self):
		return self.game.machineStatus

	@coroutine
	def _uid2roleid(self, uid):
		roleid = self._uids.get(uid, None)
		if roleid:
			raise Return(roleid)
		roleData = yield self.dbcGame.call_async('DBReadBy', 'Role', {'uid': uid})
		if not roleData['ret'] or len(roleData['models']) == 0:
			raise Exception('unknown uid %d' % uid)
		roleid = roleData['models'][0]['id']
		self._uids[uid] = roleid
		raise Return(roleid)

	@coroutine
	def _prepareRoleID(self, roleID):
		uid = None
		if isinstance(roleID, str) and roleID.isdigit():
			uid = int(roleID)
		elif isinstance(roleID, int):
			uid = roleID
		if uid:
			roleID = yield self._uid2roleid(uid)
		if len(roleID) == 24:
			roleID = roleID.decode('hex')
		raise Return(roleID)

	def Hello(self, data):
		# print data, 'say hello to GameRPCServer'
		return 'GameRPCServer say hello'

	@rpc_coroutine
	def AccountLogin(self, inl_pwd, servID, accountID, accountName, channel, sessionPwd, isNewbie, sdkInfo, rmbReturn=None):
		if inl_pwd != GameServInternalPassword:
			raise Return(None)

		logger.info("%s%s %s from %s coming %d", 'new account ' if isNewbie else '', accountName, binascii.hexlify(accountID), channel, servID)
		if servID and accountID and sessionPwd:
			session = Session(servID, accountID, accountName, sessionPwd, sdkInfo, rmbReturn)
			Session.setSession(session)

			free = Session.idSessions.capacity - len(Session.idSessions)
			used = len(Session.idSessions)

			# 返回角色信息用于记录
			if session.gameLoad:
				role = session.game.role
				raise Return((used, {'id': role.id, 'name': role.name, 'level': role.level, 'logo': role.logo, 'vip': role.vip_level, 'frame': role.frame}))
			else:
				# copy from /game/login
				query = {'account_id': accountID}
				# 是否合服查询
				if self.game.application.servMerged:
					query['area'] = session.servID
				roleData = yield self.dbcGame.call_async('RoleGet', query)
				if roleData['ret']:
					roleData = roleData['model']
					raise Return((used, {'id': roleData["id"], 'name': roleData["name"], 'level': roleData["level"], 'logo': roleData["logo"], 'vip': roleData["vip_level"], 'frame': roleData['frame']}))
			raise Return((used, None))

		raise Return(None)

	def sessionSize(self, inl_pwd):
		if inl_pwd != GameServInternalPassword:
			return None

		return len(Session.idSessions)

	def sessionCapacity(self, inl_pwd):
		if inl_pwd != GameServInternalPassword:
			return None

		# 返回的是剩余空间
		return Session.idSessions.capacity - len(Session.idSessions)

	def isSessionFull(self, inl_pwd):
		if inl_pwd != GameServInternalPassword:
			return None

		return Session.idSessions.full()

	def sessionExisted(self, inl_pwd, sessionID):
		if inl_pwd != GameServInternalPassword:
			return None

		return sessionID in Session.idSessions

	def sessionExistedByAccountID(self, inl_pwd, accountID):
		if inl_pwd != GameServInternalPassword:
			return None

		return accountID in Session.accountIDSessions

	@rpc_coroutine
	def PayForRecharge(self, inl_pwd, channel, accountID, roleID, rechargeID, orderID, amount, extInfo=None, yyID=0, csvID=0):
		if inl_pwd != GameServInternalPassword:
			raise Return('no auth')

		from game.object.game import ObjectGame
		from game.object.game.role import ObjectRole

		accountID = accountID # Account.id
		roleID = roleID # Role.id
		rechargeID = int(rechargeID) # rechages.csv ID
		orderID = orderID # PayOrder.id
		amount = float(amount) # rmb

		if rechargeID not in csv.recharges:
			raise Return('recharge %d error, bad_flag' % rechargeID)
		cfg = csv.recharges[rechargeID]

		# 回调没有金额信息，就以配表为准，只是显示用
		if channel in ('apple', 'tc'):
			amount = float(cfg.rmbDisplay)

		# amount不再判定，线上没有发现异常，且多语言版本rmbDisplay只用来显示
		# else:
		# 	# 冲多了不管，哈哈
		# 	if amount + .001 < cfg.rmbDisplay:
		# 		raise Return('recharge %d amount %.2f less, bad_flag' % (rechargeID, amount))
		# 	elif amount - cfg.rmbDisplay >= 1:
		# 		logger.warning('recharge %d amount %.2f more %.2f' % (rechargeID, amount, amount - cfg.rmbDisplay))

		rechargeOK = False
		game, safeGuard = ObjectGame.getByRoleID(roleID)

		rePro = 0
		if extInfo:
			rePro = extInfo.get('rePro', 0) # 返利比例

		# QQ无需处理离线，login的时候会查询余额
		if framework.is_qq_channel(channel):
			if game:
				with safeGuard:
					# 更新QQ pfkey等信息
					if extInfo:
						game.sdkInfo = extInfo
					game.role.syncQQRecharge(rechargeID, orderID, yyID, csvID)

		elif game is None:
			# 不在线的放入Role.recharges_cache缓存
			ret = yield self.dbcGame.call_async('DBMultipleReadKeys', 'Role', [roleID], ['recharges_cache', 'recharges'])
			if not ret['ret']:
				raise Return(ret['err'])
			if len(ret['models']) != 1:
				raise Return('no such role %s, bad_flag' % objectid2string(roleID))
			role = ret['models'][0]
			rechargeOK = True
			if yyID > 0:
				# 校验 运营活动充值是否合法（月卡，周卡，回归活动，直购礼包，条件触发礼包，通行证）
				rechargeOK = ObjectYYHuoDongFactory.isRechargeOK(rechargeID, yyID, csvID)
			if rechargeOK:
				rechargeOK = ObjectRole.isRechargeOK(role['recharges'], rechargeID, orderID)
			if rechargeOK:
				recharges_cache = role['recharges_cache']
				recharges_cache.append((rechargeID, orderID, yyID, csvID, rePro))
				ret = yield self.dbcGame.call_async('DBUpdate', 'Role', roleID, {'recharges_cache': recharges_cache}, False)
				if not ret['ret']:
					raise Return(ret['err'])
			logger.info('offline role %s recharge %d order %s %.2f in cache %s' % (objectid2string(roleID), rechargeID, objectid2string(orderID), amount, rechargeOK))

		else:
			oldRMB = game.role.rmb
			rechargeOK = True
			if yyID > 0:
				# 校验 运营活动充值是否合法（月卡，周卡，回归活动，直购礼包，条件触发礼包，通行证）
				rechargeOK = ObjectYYHuoDongFactory.isRechargeOK(rechargeID, yyID, csvID)
			if rechargeOK:
				rechargeOK = game.role.buyRecharge(rechargeID, orderID, yyID, csvID, rePro=rePro, push=True, channel=channel)
			logger.info('online role %s recharge %d order %s %.2f %s, %d -> %d, %d' % (objectid2string(roleID), rechargeID, objectid2string(orderID), amount, rechargeOK, oldRMB, game.role.rmb, game.role.rmb - oldRMB))

		raise Return('ok')

	@rpc_coroutine
	def gmRefreshCSV(self):
		buf = io.BytesIO()
		st = time.time()

		# 开发期判断模块为py时自动生成csv
		# 打包后模块为pyc，不自动生成csv
		if hasattr(framework, '__dev__'):
			import subprocess

			delta = time.time() - self._lastRefreshCSV
			if 0 < delta < 60: # 避免内网重复刷表
				buf.write('距离上次刷表刚过去 %fs\n' % delta)
				buf.write('请稍等\n')
			else:
				csvPath = './config'
				if hasattr(framework, '__dev_config__'):
					csvPath = framework.__dev_config__

				buf.write('旧版本信息：\n')
				p = subprocess.Popen('svn info', shell=True, cwd=csvPath, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
				p.wait()
				buf.write(''.join(p.stdout.readlines()))
				buf.write('\n' + '='*50 + '\n')

				buf.write('版本更新：\n')
				p = subprocess.Popen('svn update', shell=True, cwd=csvPath, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
				p.wait()
				buf.write(''.join(p.stdout.readlines()[:5]))
				buf.write('\n(more)...\n' + '='*50 + '\n')

				buf.write('现版本信息：\n')
				p = subprocess.Popen('svn info', shell=True, cwd=csvPath, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
				p.wait()
				buf.write(''.join(p.stdout.readlines()))
				buf.write('\n' + '='*50 + '\n')

				csv.reload()
				buf.write('CSV更新完毕\n')
				self._lastRefreshCSV = time.time()

		else:
			# 随机等待一定时间，防止内存雪崩
			yield sleep(random.randint(1, 60))

			csv.reload()
			buf.write('CSV更新完毕\n')

		buf.write('耗时 %f\n' % (time.time() - st))
		st = time.time()

		import game.object.game
		game.object.game.ObjectGame.initAllClass()
		buf.write('ObjectGame更新完毕\n')

		buf.write('耗时 %f\n' % (time.time() - st))

		raise Return(('ok', buf.getvalue()))

	@rpc_coroutine
	def gmGetServerStatus(self):
		# self.machineStatus.get_cur_process_info()
		# raise Return(self.machineStatus.pid)
		raise Return({
			'size': len(Session.idSessions),
			'cap': Session.idSessions.capacity,
			'active_secs': Session.ActiveStageSecs,
			'active_stat': Session.ActiveStageStat,
		})

	@rpc_coroutine
	def gmGetMachineStatus(self):
		# self.machineStatus.get_status_info()
		# ret = self.machineStatus.as_dict()
		# raise Return(ret)
		raise Return({})

	@rpc_coroutine
	def gmGetAccountStatus(self):
		from tornado.ioloop import IOLoop
		from framework.object import GCObject
		from game.object.game import ObjectGame
		from game.object.game.card import ObjectCard
		from game.object.game.rank import ObjectRankGlobal
		from game.object.game.shop import ObjectPVPShop, ObjectYZShop, ObjectUnionShop

		ioloop = IOLoop.current()
		ret = {
			'tornado': {
				'impl': str(ioloop._impl),
				'handlers': len(ioloop._handlers),
				'events': len(ioloop._events),
				'callbacks': len(ioloop._callbacks),
				'timeouts': len(ioloop._timeouts),
				'cancellations': ioloop._cancellations,
			},
			'session': {
				'size': len(Session.idSessions),
				'cap': Session.idSessions.capacity,
				'active_secs': Session.ActiveStageSecs,
				'active_stat': Session.ActiveStageStat,
			},
			'game': {
				'ObjectGame': len(ObjectGame.ObjsMap),
				'ObjectCard': len(ObjectCard.CardsObjsMap),
				'ObjectShop Free': {
					# 'pvp': len(ObjectPVPShop.FreeList),
					'yz': len(ObjectYZShop.FreeList),
					'union': len(ObjectUnionShop.FreeList),
				},
				'MailJoinableQueue': self.game.mailQueue.qsize(),
				'DBJoinableQueue': self.game.dbQueue.qsize(),
				'SDKJoinableQueue': self.game.sdkQueue.qsize(),
			},
			'gc': {
				'enable': gc.isenabled(),
				'count': gc.get_count(),
				'threshold': gc.get_threshold(),
			},
			'gcobj': GCObject.objs_count_stat(),
			# 'objs': objgraph.most_common_types(limit=24),
		}
		raise Return(ret)

	@rpc_coroutine
	def gmGetYYComfig(self):
		raise Return({
			'db': ObjectGMYYConfig.Singleton.db,
			'csv': csv.yunying.to_dict(),
		})

	@rpc_coroutine
	def gmGC(self):
		st = time.time()
		ret = gc.collect()
		ct = time.time() - st
		raise Return('gc %s cost %s s' % (ret, ct))

	def gmSetSessionCapacity(self, capacity):
		Session.setSessionCapacity(capacity)

	@rpc_coroutine
	def gmSetYYComfig(self, db):
		if 'yyhuodong' in db:
			ObjectGMYYConfig.Singleton.yyhuodong = db['yyhuodong']
		if 'login_weal' in db:
			ObjectGMYYConfig.Singleton.login_weal = db['login_weal']
		if 'level_award' in db:
			ObjectGMYYConfig.Singleton.level_award = db['level_award']
		if 'recharge_gift' in db:
			ObjectGMYYConfig.Singleton.recharge_gift = db['recharge_gift']
		if 'placard' in db:
			ObjectGMYYConfig.Singleton.placard = db['placard']

		ObjectYYHuoDongFactory.classInit()

	@rpc_coroutine
	def gmGetOnlineRoles(self, offest, size):
		keys = list(Session.idSessions.iterkeys())
		allsize = len(keys)
		keys = keys[offest:offest+size]
		models = []
		for sessionID in keys:
			session = Session.idSessions.getByKey(sessionID)
			if session and session.gameLoad:
				models.append(session.game.role.db)
		raise Return({'view': {'ret': len(models), 'size': allsize}, 'models': models})

	@rpc_coroutine
	def gmGenRobots(self):
		ret = yield createRobots(self.rpcArena, self.dbcGame)
		raise Return(ret)

	@rpc_coroutine
	def gmGetMailCsv(self):
		raise Return(csv.mail.to_dict())

	@rpc_coroutine
	def gmGetRoleInfo(self, roleID):
		from game.object.game import ObjectGame
		roleID = yield self._prepareRoleID(roleID)
		obj = ObjectGame.getByRoleID(roleID, safe=False)
		if obj is None:
			roleData = yield self.dbcGame.call_async('DBRead', 'Role', roleID, False)
			if roleData['ret']:
				raise Return(roleData['model'])
			else:
				raise Return({})
		else:
			ret = dict(obj.role.db)
			ret['_online_'] = True
			raise Return(ret)

	@rpc_coroutine
	def gmGetRoleInfoByName(self, roleName):
		roleData = yield self.dbcGame.call_async('DBReadBy', 'Role', {'name': roleName})
		if roleData['ret'] and len(roleData['models']) > 0:
			raise Return(roleData['models'][0])
		else:
			raise Return({})

	@rpc_coroutine
	def gmGetRoleInfoByAccountID(self, accountID):
		roleData = yield self.dbcGame.call_async('DBReadBy', 'Role', {'account_id': accountID})
		if roleData['ret'] and len(roleData['models']) > 0:
			raise Return(roleData['models'][0])
		else:
			raise Return({})

	@rpc_coroutine
	def gmGetRoleInfoByVip(self, beginVip, endVip):
		roleData = yield self.dbcGame.call_async('DBReadRangeBy', 'Role', {'vip_level': (beginVip, endVip)}, 0)
		if roleData['ret'] and len(roleData['models']) > 0:
			raise Return(roleData['models'])
		else:
			raise Return({})

	@rpc_coroutine
	def gmGetRoleYYOpenList(self, level, createTime, vipLevel):
		from game.object.game.yyhuodong import ObjectYYHuoDongFactory
		ret = ObjectYYHuoDongFactory.getRoleOpenList(level, createTime, vipLevel)
		raise Return(ret)

	@rpc_coroutine
	def gmGetUnionInfo(self, unionID):
		from game.object.game.union import ObjectUnion

		obj = ObjectUnion.ObjsMap.get(unionID, None)
		if obj is None:
			raise Return({})
		else:
			raise Return(obj.to_dict())

	@rpc_coroutine
	def gmSendMessage(self, type, arg, msg):
		from game.object.game import ObjectGame
		from game.object.game.union import ObjectUnion
		from game.object.game.message import ObjectMessageGlobal

		if type == 'world':
			ObjectMessageGlobal.worldMsg(msg)
		elif type == 'news':
			ObjectMessageGlobal.newsMsg(msg)
		elif type == 'union':
			union = ObjectUnion.ObjsMap.get(arg)
			if union:
				ObjectMessageGlobal.unionMsg(union, msg)
		elif type == 'society':
			pass
		elif type == 'role':
			game = ObjectGame.getByRoleID(arg, safe=False)
			if game:
				ObjectMessageGlobal.roleMsg(game.role, msg)
		raise Return(True)

	@rpc_coroutine
	def gmSendMail(self, roleID, mailType, sender, subject, content, attachs):
		roleID = yield self._prepareRoleID(roleID)
		from game.object.game import ObjectGame
		from game.object.game.role import ObjectRole
		from game.handler.inl_mail import sendMail

		mail = ObjectRole.makeMailModel(roleID, mailType, sender, subject, content, attachs)
		try:
			yield sendMail(mail, self.dbcGame, ObjectGame.getByRoleID(roleID, safe=False))
		except:
			logger.exception('gmSendMail error')
			raise Return(False)
		raise Return(True)

	@rpc_coroutine
	def gmSendGlobalMail(self, mailType, sender, subject, content, attachs):
		from game.handler.inl_mail import sendGlobalMail

		try:
			yield sendGlobalMail(self.dbcGame, mailType, sender, subject, content, attachs)
		except:
			logger.error('gmSendGlobalMail error')
			raise Return(False)
		raise Return(True)

	@rpc_coroutine
	def gmSendVipMail(self, beginVip, endVip, mailType, sender, subject, content, attachs):
		from game.handler.inl_mail import sendVipMail

		try:
			yield sendVipMail(self.dbcGame, beginVip, endVip, mailType, sender, subject, content, attachs)
		except Exception, e:
			logger.error(str(e))
			raise Return(False)
		raise Return(True)

	@rpc_coroutine
	def gmSendServerMail(self, mailType, sender, subject, content, attachs):
		from game.handler.inl_mail import sendServerMail

		try:
			yield sendServerMail(self.dbcGame, mailType, sender, subject, content, attachs)
		except:
			logger.exception('gmSendServerMail error')
			raise Return(False)
		raise Return(True)

	@rpc_coroutine
	def gmSendUnionMail(self, unionID, mailType, sender, subject, content, attachs):
		from game.handler.inl_mail import sendUnionMail

		try:
			yield sendUnionMail(self.dbcGame, unionID, mailType, sender, subject, content, attachs)
		except:
			logger.exception('gmSendUnionMail error')
			raise Return(False)
		raise Return(True)

	@rpc_coroutine
	def gmSendNewbieMail(self, accountName, mailType, sender, subject, content, attachs):
		from game.handler.inl_mail import sendNewbieMail

		try:
			yield sendNewbieMail(self.dbcGame, accountName, mailType, sender, subject, content, attachs)
		except:
			logger.exception('gmSendNewbieMail error')
			raise Return(False)
		raise Return(True)

	@rpc_coroutine
	def gmHandlerDisable(self, url, disable):
		from game.handler import handlers

		if url not in handlers:
			logger.exception('gmHandlerDisable error ' + url)
			raise Return(False)
		handlers[url].disabled = disable
		raise Return(True)

	@rpc_coroutine
	def gmOpenRPDB(self):
		if self._rpdb is None:
			try:
				self._rpdb = MyRpdb()
				logger.info('rpdb open ok')
				self._rpdb.set_trace()
				raise Return(True)

			except Return:
				raise

			except:
				logger.exception('rpdb open error')
				raise Return(False)

		else:
			raise Return(False)

	@rpc_coroutine
	def gmCloseRPDB(self):
		if self._rpdb:
			try:
				self._rpdb.shutdown()
			except:
				pass
			finally:
				self._rpdb = None
		raise Return(True)

	@rpc_coroutine
	def gmDBQueueJoin(self):
		servName = self.game.servName
		dbQueue = self.game.dbQueue
		yield dbQueue.join(closed=False)
		dbQueue._joined = False
		logger.info('%s DBJoinableQueue join over, left %d' % (servName, dbQueue.qsize()))

	@rpc_coroutine
	def gmMailQueueJoin(self):
		servName = self.game.servName
		mailQueue = self.game.mailQueue
		yield mailQueue.join(closed=False)
		mailQueue._joined = False
		logger.info('%s MailJoinableQueue join over, left %d' % (servName, mailQueue.qsize()))

	@rpc_coroutine
	def gmFlushDB(self):
		yield self.dbcGame.call_async('DBFlush', True, True)
		raise Return(True)

	@rpc_coroutine
	def gmCommitDB(self):
		yield self.dbcGame.call_async('DBCommit', True, True)
		raise Return(True)

	@rpc_coroutine
	def gmExecPy(self, src):
		if src.find(GameServInternalPassword) < 0:
			raise Return(None)

		ret = None
		try:
			exec(src)
			if 'exec_func' in locals():
				ret = exec_func(self)
			if 'exec_coroutine' in locals():
				ret = yield exec_coroutine(self)
		except Exception, e:
			logger.exception('gmExecPy Error')
			raise Return(str(e))
		raise Return(ret)

	@rpc_coroutine
	def gmReloadAuto(self):
		from framework.xreload_cache import xreload_auto

		try:
			logger.info('gmReloadAuto begin')
			ret = xreload_auto()
			for x in ret:
				logger.info('%s changed' % x)
			logger.info('gmReloadAuto end')

		except Exception, e:
			logger.exception('gmReloadAuto Error')
			raise Return(str(e))
		raise Return(None)

	@rpc_coroutine
	def gmReloadPyFiles(self, filenames):
		from framework.xreload_cache import xreload

		try:
			logger.info('gmReloadPyFiles begin')
			xreload(filenames)
			logger.info('gmReloadPyFiles end')

		except Exception, e:
			logger.exception('gmReloadPyFiles Error')
			raise Return(str(e))
		raise Return(None)

	@rpc_coroutine
	def gmGetGameRank(self, rtype):
		from game.object.game.rank import ObjectRankGlobal

		offest = 0
		size = 50

		if rtype == 'arena':
			ret = yield self.rpcArena.call_async('GetArenaTop50', offest, size)
			raise Return({'view': {
				'rank': ret,
				'offest': offest,
				'size': size,
			}})

		elif rtype == 'union':
			ret = yield self.rpcUnion.call_async('GetRankList', offest, size)
			raise Return({'view': {
				'rank': ret,
				'offest': offest,
				'size': len(ret), # all
			}})

		elif rtype in ('pokedex', 'fight', 'card1fight', 'star', 'yuanzheng', 'yybox', 'endless'):
			ret = yield ObjectRankGlobal.getRankList(rtype, offest, size)
			raise Return({'view': {
				'rank': ret,
				'offest': offest,
				'size': len(ret),
			}})

		elif rtype == 'world_boss':
			ret = yield ObjectRankGlobal.getRankList('boss',offest, size)
			raise Return({'view': {
				'rank': ret,
				'offest': offest,
				'size': len(ret), # 100
			}})

	@rpc_coroutine
	def gmRoleMemSilentDisable(self, roleID):
		from game.object.game import ObjectGame
		game = ObjectGame.getByRoleID(roleID, safe=False)
		if game:
			game.role._lastchat = None # (msg, count)
			game.role._silent_time = 0 # 禁言开始时间
		raise Return(True)

	@rpc_coroutine
	def gmRoleAbandon(self, roleID, type, val):
		from game.object.game import ObjectGame
		from game.object.game.rank import ObjectRankGlobal
		from game.object.game.craft import ObjectCraftInfoGlobal
		from game.object.game.union_fight import ObjectUnionFightGlobal
		from game.object.game.message import ObjectMessageGlobal

		game = ObjectGame.getByRoleID(roleID, safe=False)
		if type == 'disable':
			if game:
				game.role.disable_flag = bool(val)
				if bool(val):
					Session.discardSessionByAccountKey(game.role.accountKey) # 踢下线
			else:
				yield self.dbcGame.call_async('DBUpdate', 'Role', roleID, {
					'disable_flag': bool(val),
				}, True)
			if bool(val):
				yield ObjectRankGlobal.onClearRoleRank(roleID)
				ObjectCraftInfoGlobal.AutoSignRoleMap.pop(roleID, None)
				ObjectUnionFightGlobal.AutoSignRoleMap.pop(roleID, None)


		elif type == 'silent':
			if game:
				game.role.silent_flag = bool(val)
			else:
				yield self.dbcGame.call_async('DBUpdate', 'Role', roleID, {
					'silent_flag': bool(val),
				}, True)
			if bool(val):
				ObjectMessageGlobal.removeWorldQueMsg(roleID) # 删除最近聊天记录

		raise Return(True)

	@rpc_coroutine
	def gmRoleModify(self, roleID, key, val):
		from game.object.game import ObjectGame

		game = ObjectGame.getByRoleID(roleID, safe=False)
		if game:
			prop = getattr(game.role, key, None)
			if prop:
				prop.fset(val)

		else:
			yield self.dbcGame.call_async('DBUpdate', 'Role', roleID, {
				key: val,
			}, True)

		raise Return(True)

	@rpc_coroutine
	def gmRejudgePVPPlay(self, playID, forceAll):
		ret = yield self.rpcArena.call_async('rejudgePVPPlay', playID, forceAll)
		raise Return(ret)

	'''
	二阶段提交
	'''
	def VoteTransaction(self, key, transaction):
		if transaction in self.tscCommits:
			return self.tscCommits[transaction]
		if transaction not in self.tscVotes:
			self.tscVotes[transaction] = (key, time.time())
		else:
			if time.time() - self.tscVotes[transaction][1] > NodeCommitTimeout:
				self.tscVotes[transaction] = (key, time.time())
			elif key < self.tscVotes[transaction]:
				self.tscVotes[transaction] = (key, time.time())
		return self.tscVotes[transaction][0]

	@rpc_coroutine
	def CommitTransaction(self, key, transaction):
		if transaction in self.tscCommits:
			raise Return(self.tscCommits[transaction])
		if transaction not in self.tscVotes:
			raise Return('error')
		if key == self.tscVotes[transaction][0]:
			self.tscVotes.pop(transaction)
			# commited状态需要上层应用手动清理
			self.tscCommits[transaction] = key
			ret = yield self.onTransactionCommit(key, transaction)
			if ret is False:
				raise Return('refuse')
			raise Return(key)
		else:
			raise Return(self.tscVotes[transaction][0])

	def CommittedOver(self, key, transaction):
		if key == self.tscCommits.get(transaction, None):
			self.tscCommits.pop(transaction)
		return True

	@coroutine
	def onTransactionCommit(self, key, transaction):
		logger.info('onTransactionCommit %s %s', key, transaction)
		if transaction == 'crosscraft':
			ret = yield ObjectCrossCraftGameGlobal.onCrossCommit(key, transaction)
			raise Return(ret)
		elif transaction == 'crossarena':
			ret = yield ObjectCrossArenaGameGlobal.onCrossCommit(key, transaction)
			raise Return(ret)
		elif transaction == 'onlinefight':
			ret = yield ObjectCrossOnlineFightGameGlobal.onCrossCommit(key, transaction)
			raise Return(ret)
		elif transaction == 'crossfishing':
			ret = yield ObjectCrossFishingGameGlobal.onCrossCommit(key, transaction)
			raise Return(ret)
		elif transaction == 'crossgym':
			ret = yield ObjectGymGameGlobal.onCrossCommit(key, transaction)
			raise Return(ret)
		elif transaction == 'huodongboss':
			ret = yield ObjectServerGlobalRecord.onCrossCommit(key, transaction)
			raise Return(ret)
		elif transaction == 'crossmine':
			ret = yield ObjectCrossMineGameGlobal.onCrossCommit(key, transaction)
			raise Return(ret)
		elif transaction == "crossunionqa":
			ret = yield ObjectServerGlobalRecord.onCrossUnionQACommit(key, transaction)
			raise Return(ret)
		elif transaction == 'crossredpacket':
			ret = yield ObjectServerGlobalRecord.onHuoDongCrossRedPacketCommit(key, transaction)
			raise Return(ret)
		elif transaction == 'skyscraper':
			ret = yield ObjectServerGlobalRecord.onHuoDongCrossSkyscraperCommit(key, transaction)
			raise Return(ret)
		elif transaction.startswith('crossranking'):
			transaction = '_'.join(transaction.split('_')[1:])
			ret = yield ObjectServerGlobalRecord.onCrossRankingCommit(key, transaction)
			raise Return(ret)
		elif transaction == 'crosshorse':
			ret = yield ObjectServerGlobalRecord.onCrossHorseRaceCommit(key, transaction)
			raise Return(ret)
		elif transaction == 'crossunionfight':
			ret = yield ObjectCrossUnionFightGameGlobal.onCrossCommit(key, transaction)
			raise Return(ret)
		raise Return(False)

	######### 跨服石英大会
	@rpc_coroutine
	def CrossCraftEvent(self, event, key, data, sync):
		ret = yield ObjectCrossCraftGameGlobal.onCrossEvent(event, key, data, sync)
		raise Return(ret)

	@rpc_coroutine
	def CrossArenaEvent(self, event, key, data, sync):
		ret = yield ObjectCrossArenaGameGlobal.onCrossEvent(event, key, data, sync)
		raise Return(ret)

	@rpc_coroutine
	def CrossOnlineFightEvent(self, event, key, data, sync):
		ret = yield ObjectCrossOnlineFightGameGlobal.onCrossEvent(event, key, data, sync)
		raise Return(ret)

	@rpc_coroutine
	@notify
	def CrossMatchServerCheck(self, crossKey, t):
		from framework import datetimefromtimestamp
		from game import globaldata

		openTime = globaldata.GameServOpenDatetime
		ndt = datetimefromtimestamp(t)

		dt = ndt.date() - openTime.date()
		days = dt.days
		if openTime.hour < 5 and ndt.hour >= 5:
			days += 1
		elif ndt.hour < 5 and openTime.hour >= 5:
			days -= 1
		days = max(days, 0)

		yield self.game.container.getserviceOrCreate(crossKey).call_async_timeout('ServiceCheckBack', 15, self.game.name, MergeServ.getSrcServKeys(self.game.name), days)
		raise Return('ok')

	@rpc_coroutine
	def CrossFishingEvent(self, event, key, data, sync):
		ret = yield ObjectCrossFishingGameGlobal.onCrossEvent(event, key, data, sync)
		raise Return(ret)

	@rpc_coroutine
	def GymEvent(self, event, key, data, sync):
		ret = yield ObjectGymGameGlobal.onGymEvent(event, key, data, sync)
		raise Return(ret)

	@rpc_coroutine
	def HuoDongBossEvent(self, event, key, data, sync):
		ret = yield ObjectServerGlobalRecord.onHuoDongBossEvent(event, key, data, sync)
		raise Return(ret)

	@rpc_coroutine
	def CrossMineEvent(self, event, key, data, sync):
		ret = yield ObjectCrossMineGameGlobal.onCrossEvent(event, key, data, sync)
		raise Return(ret)

	@rpc_coroutine
	def CrossUnionQAEvent(self, event, key, data, sync):
		ret = yield ObjectServerGlobalRecord.onCrossUnionQAEvent(event, key, data, sync)
		raise Return(ret)

	@rpc_coroutine
	def HuoDongCrossRedPacketEvent(self, event, key, data, sync):
		ret = yield ObjectServerGlobalRecord.onHuoDongCrossRedPacketEvent(event, key, data, sync)
		raise Return(ret)

	@rpc_coroutine
	def HuoDongCrossSkyscraperEvent(self, event, key):
		ret = yield ObjectServerGlobalRecord.onHuoDongCrossSkyscraperEvent(event, key)
		raise Return(ret)

	@rpc_coroutine
	def HuoDongCrossRankingEvent(self, gamePlay, event, key):
		ret = yield ObjectServerGlobalRecord.onCrossRankingEvent(gamePlay, event, key)
		raise Return(ret)

	@rpc_coroutine
	def GetOpenDays(self, key):
		days = todayinclock5elapsedays(globaldata.GameServOpenDatetime)
		logger.info('%s openDays %d', key, days)
		raise Return(int(days))

	def CrossGetRoleLastTime(self, roleID):
		from game.object.game import ObjectGame
		game = ObjectGame.getByRoleID(roleID, safe=False)
		if game:
			return int(game.role.last_time)
		else:
			return 0

	@rpc_coroutine
	def CrossUnionFightEvent(self, event, key, data, sync):
		ret = yield ObjectCrossUnionFightGameGlobal.onCrossEvent(event, key, data, sync)
		raise Return(ret)

	######### 石英大会
	@rpc_coroutine
	def CraftEvent(self, event, data, sync):
		from game.object.game.craft import ObjectCraftInfoGlobal
		ret = yield ObjectCraftInfoGlobal.onCraftEvent(event, data, sync)
		raise Return(ret)
	@rpc_coroutine
	def UnionFightEvent(self, event, data, sync):
		from game.object.game.union_fight import ObjectUnionFightGlobal
		ret = yield ObjectUnionFightGlobal.onUnionFightEvent(event, data, sync)
		raise Return(ret)

	@rpc_coroutine
	def BraveChallengeEvent(self, event, data, sync):
		from game.object.game.yyhuodong import ObjectYYBraveChallenge
		ret = yield ObjectYYBraveChallenge.onBraveChallengeEvent(event, data, sync)
		raise Return(ret)

	@rpc_coroutine
	def SummerChallengeEvent(self, event, data, sync):
		from game.object.game.yyhuodong import ObjectYYSummerChallenge
		ret = yield ObjectYYSummerChallenge.onSummerChallengeEvent(event, data, sync)
		raise Return(ret)

	@rpc_coroutine
	def GMGetRoleCards(self, roleID, cardIDs):
		from game.object.game import ObjectGame
		roleID = yield self._prepareRoleID(roleID)
		game = ObjectGame.getByRoleID(roleID, safe=False)
		if game:
			if not cardIDs:
				cardIDs = game.role.cards
			cards = {}
			for cardID in cardIDs:
				card = game.cards.getCard(cardID)
				cards[cardID] = dict(card.db)
				cards[cardID]['name'] = card.name
			raise Return({
				'role': {
					'id': game.role.id,
					'name': game.role.name,
				},
				'cards': cards,
			})

	def GMEvalCardAttrs(self, roleID, cardID, disables):
		from game.object.game import ObjectGame
		game = ObjectGame.getByRoleID(roleID, safe=False)
		if game:
			card = game.cards.getCard(cardID)
			attrs, display = card.calcFilterAttrs(disables=disables)
			return {'attrs': attrs, 'display': display}

	@coroutine
	def _fakeLogin(self, roleID):
		from game.object.game import ObjectGame
		servID = int(self.game.key.split('.')[-1])
		roleID = yield self._prepareRoleID(roleID)
		game = ObjectGame.getByRoleID(roleID, safe=False)
		if game:
			raise Return('online')
		accountID = roleID

		from game.handler._game import GameLogin
		class FakeGameLogin(GameLogin):
			def __init__(self, application, session):
				self.application = application
				self.session = session
				self.accountID = None # 为了fix时用role_id查找
				# self.accountID = accountID
				self.roleID = roleID
				self.input = {}

			def write(self, view):
				pass

		session = Session(servID, accountID, str(accountID), accountID, {}, {})
		Session.setSession(session)
		handler = FakeGameLogin(self.game.application, session)
		yield handler.loading()
		raise Return('fake login')

	@coroutine
	def _discardFakeLogin(self, roleID):
		from game.object.game import ObjectGame
		servID = int(self.game.key.split('.')[-1])
		roleID = yield self._prepareRoleID(roleID)
		accountID = roleID
		game = ObjectGame.getByRoleID(roleID, safe=False)
		if game:
			ObjectGame.popByRoleID(roleID)
			Session.discardSessionByAccountKey((game.role.area, game.role.account_id)) # real accountKey, _syncLast
		Session.discardSessionByAccountKey((servID, accountID)) # fake accountKey, _syncLast

	@rpc_coroutine
	def GMRollbackRoleItem(self, roleID, items, award, costMap):
		roleID = yield self._prepareRoleID(roleID)
		from game.object.game import ObjectGame
		game = ObjectGame.ObjsMap.get(roleID, None)
		if game is None:
			yield self._fakeLogin(roleID)
			logger.info('role %s fake login', objectid2string(roleID))
		game, safeGuard = ObjectGame.getByRoleID(roleID)
		if not game:
			raise Return('not load')
		costResult = False
		gainResult = False
		with safeGuard:
			from game.object.game.gain import ObjectCostAux, ObjectGainAux
			from game.handler.inl import effectAutoGain
			from framework.helper import string2objectid

			cost = ObjectCostAux(game, items)
			# 卡牌
			if "cards" in costMap:
				costCards = []
				for cardID in costMap["cards"]:
					card = game.cards.getCard(string2objectid(cardID))
					costCards.append(card)
				cost.setCostCards(costCards)
			# 携带道具
			if "heldItems" in costMap:
				costHeldItems = []
				for heldItemID in costMap["heldItems"]:
					heldItem = game.heldItems.getHeldItem(string2objectid(heldItemID))
					costHeldItems.append(heldItem)
				for obj in costHeldItems:
					cardID = obj.card_db_id
					if cardID: # 如果已经装备了，脱下
						obj.card_db_id = None
						card = game.cards.getCard(cardID)
						card.held_item = None
				cost.setCostHeldItems(costHeldItems)
			# 宝石
			if "gems" in costMap:
				costGems = []
				for gemID in costMap["gems"]:
					gem = game.gems.getGem(string2objectid(gemID))
					costGems.append(gem)
				for obj in costGems:
					if obj.card_db_id:
						cardID = obj.card_db_id# 如果已经装备了，脱下
						pos = obj.getGemPos()
						# 卸下
						if pos is not None:
							card = game.cards.getCard(cardID)
							card.gems.pop(pos, None)
							obj.card_db_id = None
				cost.setCostGems(costGems)
			if cost.isEnough():
				cost.cost(src='gm_fix')
				costResult = True
				if award: # 一定先有扣除，再恢复，没扣除的就直接邮件发吧
					eff = ObjectGainAux(game, award)
					yield effectAutoGain(eff, game, self.dbcGame, src='gm_fix')
					gainResult = True
			else:
				costResult = False
		yield self._discardFakeLogin(roleID)
		raise Return((costResult, gainResult))

	@coroutine
	def _doWithLogin(self, roleID, f):
		from game.object.game import ObjectGame
		game = ObjectGame.ObjsMap.get(roleID, None)
		if game is None:
			yield self._fakeLogin(roleID)
			logger.info('role %s fake login', objectid2string(roleID))
		game, safeGuard = ObjectGame.getByRoleID(roleID)
		if not game:
			raise Return(False)
		try:
			with safeGuard:
				f(game)
		except Exception, e:
			logger.exception('_doWithLogin error', e)
		yield self._discardFakeLogin(roleID)
		raise Return(True)

	@rpc_coroutine
	def GMRecoverRoleCard(self, roleID, cardID):
		if len(cardID) == 24:
			cardID = string2objectid(cardID)
		yield self.dbcGame.call_async('RoleCardRecover', cardID)
		resp = yield self.dbcGame.call_async('DBRead', 'RoleCard', cardID, False)
		if not resp['ret']:
			raise Return('no this card')
		card = resp['model']
		roleID = yield self._prepareRoleID(roleID)
		if card['role_db_id'] != roleID:
			raise Return('not this role card')
		def do(game):
			game.role.cards.append(cardID)
			game.role.cards = list(set(game.role.cards))
			logger.info('role %s recover card %s, card_id %d, star %d', objectid2string(roleID), objectid2string(cardID), card['card_id'], card['star'])
		ok = yield self._doWithLogin(roleID, do)
		if ok:
			raise Return('success')
		else:
			raise Return('failed')

	@rpc_coroutine
	def GMRoleCardExpiredGet(self, roleID):
		roleID = yield self._prepareRoleID(roleID)
		resp = yield self.dbcGame.call_async('RoleCardExpiredGet', roleID)
		raise Return(resp)

	# GM 跑马灯消息
	def GMMarqueeBroadcast(self, msg, key):
		from game.object.game.message import ObjectMessageGlobal
		msg = ObjectMessageGlobal.marqueeMsg(msg, args={'key': key})
		data = {
			'msg': {'msgs': [msg]},
		}
		from game.session import Session
		Session.broadcast('/game/push', data)

class MyRpdb(Rpdb):
	def __init__(self, addr="", port=6161):
		Rpdb.__init__(self, addr, port)

	def do_continue(self, arg):
		"""Clean-up and do underlying continue."""
		try:
			return pdb.Pdb.do_continue(self, arg)
		finally:
			pass

	do_c = do_cont = do_continue
