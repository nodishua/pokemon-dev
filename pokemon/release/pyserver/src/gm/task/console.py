#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2014 YouMi Information Technology Inc.
'''

from framework.log import logger
from gm.task import RPCTaskFactory, GMTaskError, gmrpc_coroutine, gmrpc_log_coroutine

from game.globaldata import GameServInternalPassword

from tornado.gen import Return, coroutine
from tornado.ioloop import PeriodicCallback, IOLoop

import datetime

GMServerVersion = 6
GlobalServerKey = '__@global@__'


class TConsoleFactory(RPCTaskFactory):
	PeriodicMessage = None

	# 不提供服务了
	# def _hello(self, data):
	# 	return GMTaskReturn('GMServer say hello')

	# @rpc_coroutine
	# def gmLogin(self, inl_pwd, name, passMD5):
	# 	if inl_pwd != GameServInternalPassword:
	# 		raise Return(GMTaskError('auth_error'))

	# 	ret = yield self.dbcGM.call_async('GMLogin', name, passMD5)
	# 	if not ret['ret']:
	# 		raise Return(GMTaskError(ret['err']))
	# 	model = ret['model']
	# 	# print model

	# 	sessionID = self.server.login(name, model['permission_level'])
	# 	logger.info('`%s` login, %s, %d' % (name, sessionID, model['permission_level']))
	# 	raise Return(GMTaskReturn((sessionID, model['permission_level'], GMServerVersion)))

	@gmrpc_coroutine
	def gmGetGameServers(self):
		ret = []
		for name, rpc in self.gameAllRPCs.iteritems():
			ret.append((name, ('111.111.111.111', 1111), not rpc.isLost()))
		raise Return(ret)

	@gmrpc_coroutine
	def gmGetGameServerStatus(self, name=None):
		raise Return(GMTaskReturn({}))

		if name is None:
			ret = {}
			for name, rpc in self.gameAllRPCs.iteritems():
				if not rpc.ackOK:
					continue
				ret[name] = rpc.call_async('gmGetServerStatus')

			for key, fu in ret.iteritems():
				try:
					ret2 = yield fu
				except Exception, e:
					ret2 = str(e)
				ret[key] = ret2

			raise Return(ret)
		else:
			if name not in self.gameAllRPCs:
				raise GMTaskError('no this server name')
			else:
				ret = yield self.gameAllRPCs[name].call_async('gmGetServerStatus')
				raise Return(ret)

	@gmrpc_coroutine
	def gmGetGameMachineStatus(self, name=None):
		if name is None:
			ret = {}
			for name, rpc in self.gameAllRPCs.iteritems():
				if not rpc.ackOK:
					continue
				try:
					ret[name] = rpc.call_async('gmGetMachineStatus')
				except:
					pass

			for key, fu in ret.iteritems():
				try:
					ret2 = yield fu
				except Exception, e:
					ret2 = str(e)
				ret[key] = ret2

			raise Return(ret)
		else:
			if name not in self.gameAllRPCs:
				raise GMTaskError('no this server name')
			else:
				ret = yield self.gameAllRPCs[name].call_async('gmGetMachineStatus')
				raise Return(ret)

	@gmrpc_coroutine
	def gmGetGameAccountStatus(self, name=None):
		if name is None:
			ret = {}
			for name, rpc in self.gameAllRPCs.iteritems():
				try:
					ret[name] = rpc.call_async('gmGetAccountStatus')
				except:
					pass

			for key, fu in ret.iteritems():
				try:
					ret2 = yield fu
				except Exception, e:
					ret2 = str(e)
				ret[key] = ret2

			raise Return(ret)
		else:
			if name not in self.gameAllRPCs:
				raise GMTaskError('no this server name')
			else:
				ret = yield self.gameAllRPCs[name].call_async('gmGetAccountStatus')
				raise Return(ret)

	@gmrpc_log_coroutine
	def gmGC(self, name):
		if name not in self.gameAllRPCs:
			ret = []
			for name, rpc in self.gameAllRPCs.iteritems():
				try:
					fu = self.gameAllRPCs[name].call_async('gmGC')
					ret.append((name, fu))
				except:
					pass

			for i, t in enumerate(ret):
				name, fu = t
				try:
					ret2 = yield fu
				except Exception, e:
					ret2 = str(e)
				ret[i] = (name, ret2)

			raise Return(ret)
		else:
			ret = yield self.gameAllRPCs[name].call_async('gmGC')
			raise Return(ret)

	@gmrpc_coroutine
	def gmGetGameYYComfig(self, name=None):
		if name is None:
			ret = {}
			for name, rpc in self.gameAllRPCs.iteritems():
				try:
					ret[name] = yield rpc.call_async('gmGetYYComfig')
				except:
					pass
			raise Return(ret)
		else:
			if name not in self.gameAllRPCs:
				raise GMTaskError('no this server name')
			else:
				ret = yield self.gameAllRPCs[name].call_async('gmGetYYComfig')
				raise Return(ret)

	@gmrpc_log_coroutine
	def gmSetGameYYComfig(self, db, name=None):
		if name is None:
			ret = {}
			for name, rpc in self.gameAllRPCs.iteritems():
				try:
					ret[name] = yield rpc.call_async('gmSetYYComfig', db)
				except:
					pass
			raise Return(ret)
		else:
			if name not in self.gameAllRPCs:
				raise GMTaskError('no this server name')
			else:
				ret = yield self.gameAllRPCs[name].call_async('gmSetYYComfig', db)
				raise Return(ret)

	@gmrpc_coroutine
	def gmGetGameOnlineRoles(self, name, offest=0, size=100):
		if name not in self.gameAllRPCs:
			raise GMTaskError('no this server name')
		else:
			ret = yield self.gameAllRPCs[name].call_async('gmGetOnlineRoles', offest, size)
			raise Return(ret)

	@gmrpc_log_coroutine
	def gmRefreshCSV(self, name=GlobalServerKey):
		ret = []
		if name == GlobalServerKey:
			fus = []
			for name, rpc in self.gameRPCs.iteritems():
				try:
					fus.append((name, rpc.call_async('gmRefreshCSV')))
					logger.info('server `%s` refresh csv' % (name))
				except Exception, e:
					logger.exception('server `%s` refresh csv exception' % (name))

			for name, fu in fus:
				try:
					one = yield fu
					ret.append((name, one[1]))
				except Exception, e:
					ret.append((name, str(e)))
		else:
			try:
				one = yield self.gameAllRPCs[name].call_async('gmRefreshCSV')
				ret.append((name, one[1]))
			except:
				pass
			logger.info('server `%s` refresh csv' % (name))

		raise Return(ret)

	@gmrpc_coroutine
	def gmGenRobots(self, name):
		if name not in self.gameAllRPCs:
			raise GMTaskError('no this server name')
		else:
			ret = yield self.gameAllRPCs[name].call_async('gmGenRobots')
			raise Return(ret)

	@gmrpc_coroutine
	def gmGetMailCsv(self, name):
		if name not in self.gameAllRPCs:
			from framework.csv import csv
			csv.reload()
			raise Return(csv.mail.to_dict())
		else:
			ret = yield self.gameAllRPCs[name].call_async('gmGetMailCsv')
			raise Return(ret)

	@gmrpc_coroutine
	def gmGetRoleInfo(self, name, roleID):
		if name not in self.gameAllRPCs:
			raise GMTaskError('no this server name')
		else:
			ret = yield self.gameAllRPCs[name].call_async('gmGetRoleInfo', roleID)
			if 'account_id' in ret:
				ret2 = yield self.dbcAccount.call_async('AccountQuery', ret['account_id'])
				if ret2['ret']:
					ret['account_name'] = ret2['model']['name']
					ret['account_roles'] = ret2['model']['role_infos']
			raise Return(ret)

	@gmrpc_coroutine
	def gmGetRoleInfoByName(self, name, roleName):
		if name not in self.gameAllRPCs:
			raise GMTaskError('no this server name')
		else:
			ret = yield self.gameAllRPCs[name].call_async('gmGetRoleInfoByName', roleName)
			if 'account_id' in ret:
				ret2 = yield self.dbcAccount.call_async('AccountQuery', ret['account_id'])
				if ret2['ret']:
					ret['account_name'] = ret2['model']['name']
					ret['account_roles'] = ret2['model']['role_infos']

			elif roleName.find('_') > 0:
				# 用渠道id查询
				ret2 = yield self.dbcAccount.call_async('AccountQueryByName', roleName)
				if ret2['ret']:
					ret = yield self.gameAllRPCs[name].call_async('gmGetRoleInfoByAccountID', ret2['model']['id'])
					if 'account_id' in ret:
						ret['account_name'] = ret2['model']['name']
						ret['account_roles'] = ret2['model']['role_infos']


			raise Return(ret)

	@gmrpc_coroutine
	def gmGetRoleInfoByVip(self, name, vipBegin, vipEnd):
		if name not in self.gameAllRPCs:
			raise GMTaskError('no this server name')
		else:
			ret = yield self.gameAllRPCs[name].call_async('gmGetRoleInfoByVip', vipBegin, vipEnd)
			simpleRet = [  {'account_id':x['account_id'],
							'name':x['name'],
							'vip_level':x['vip_level'],
							'rmb_consume':x['rmb_consume'],
							'id':x['id'],
							} for x in ret]
			raise Return(simpleRet)

	@gmrpc_coroutine
	def gmGetUnionInfo(self, name, roleID):
		if name not in self.gameAllRPCs:
			raise GMTaskError('no this server name')
		else:
			ret = yield self.gameAllRPCs[name].call_async('gmGetUnionInfo', roleID)
			raise Return(ret)

	@gmrpc_log_coroutine
	def gmSendMessage(self, name, type, arg, msg, ptime):
		if self.PeriodicMessage:
			self.PeriodicMessage.stop()
			self.PeriodicMessage = None

		@coroutine
		def send(name, type, arg, msg):
			if name not in self.gameAllRPCs:
				ret = []
				for name, rpc in self.gameAllRPCs.iteritems():
					try:
						ret2 = yield self.gameAllRPCs[name].call_async('gmSendMessage', type, arg, msg)
						ret.append((name, ret2))
					except Exception, e:
						ret.append((name, str(e)))
				raise Return(ret)
			else:
				ret = yield self.gameAllRPCs[name].call_async('gmSendMessage', type, arg, msg)
				raise Return(ret)

		if ptime > 0:
			import functools
			self.PeriodicMessage = PeriodicCallback(functools.partial(send, name, type, arg, msg), ptime * 1000 * 3600)
			self.PeriodicMessage.start()

		ret = yield send(name, type, arg, msg)
		raise Return(ret)

	@gmrpc_log_coroutine
	def gmSendMail(self, name, roleID, mailType, sender, subject, content, attachs):
		if name not in self.gameAllRPCs:
			raise GMTaskError('no this server name')
		else:
			ret = yield self.gameAllRPCs[name].call_async('gmSendMail', roleID, mailType, sender, subject, content, attachs)
			raise Return(ret)

	@gmrpc_log_coroutine
	def gmSendGlobalMail(self, name, mailType, sender, subject, content, attachs):
		if name == GlobalServerKey:
			ret = []
			for name, rpc in self.gameRPCs.iteritems():
				try:
					ret2 = yield self.gameRPCs[name].call_async('gmSendGlobalMail', mailType, sender, subject, content, attachs)
					logger.info('gmSendGlobalMail %s', name)
					ret.append((name, ret2))
				except Exception, e:
					ret.append((name, str(e)))
			raise Return(ret)
		else:
			ret = yield self.gameAllRPCs[name].call_async('gmSendGlobalMail', mailType, sender, subject, content, attachs)
			raise Return(ret)

	@gmrpc_log_coroutine
	def gmSendServerMail(self, name, mailType, sender, subject, content, attachs):
		if name == GlobalServerKey:
			ret = []
			for name, rpc in self.gameRPCs.iteritems():
				try:
					ret2 = yield self.gameRPCs[name].call_async('gmSendServerMail', mailType, sender, subject, content, attachs)
					logger.info('gmSendServerMail %s', name)
					ret.append((name, ret2))
				except Exception, e:
					ret.append((name, str(e)))
			raise Return(ret)
		else:
			ret = yield self.gameAllRPCs[name].call_async('gmSendServerMail', mailType, sender, subject, content, attachs)
			raise Return(ret)

	@gmrpc_log_coroutine
	def gmSendVipMail(self, name, beginVip, endVip, mailType, sender, subject, content, attachs):
		if name == GlobalServerKey:
			ret = []
			for name, rpc in self.gameRPCs.iteritems():
				try:
					ret2 = yield self.gameRPCs[name].call_async('gmSendVipMail', beginVip, endVip, mailType, sender, subject, content, attachs)
					logger.info('gmSendVipMail %s', name)
					ret.append((name, ret2))
				except Exception, e:
					ret.append((name, str(e)))
			raise Return(ret)
		else:
			ret = yield self.gameAllRPCs[name].call_async('gmSendVipMail', beginVip, endVip, mailType, sender, subject, content, attachs)
			raise Return(ret)

	# # 根据用户ID集合，发送邮件
	# @gmrpc_log_coroutine
	# def gmSendMailByGroup(self, name, roleIDs, mailType, sender, subject, content, attachs):
	# 	if name not in self.gameAllRPCs:
	# 		raise Return(GMTaskError('no this server name'))
	# 	else:
	# 		for roleID in roleIDs:
	# 			roleID = int(roleID)
	# 			ret = yield self.gameAllRPCs[name].call_async('gmSendMail', roleID, mailType, sender, subject, content, attachs)
	# 		raise Return(GMTaskReturn(ret))

	@gmrpc_log_coroutine
	def gmSendUnionMail(self, name, unionID, mailType, sender, subject, content, attachs):
		if name not in self.gameAllRPCs:
			raise GMTaskError('no this server name')
		else:
			ret = yield self.gameAllRPCs[name].call_async('gmSendUnionMail', unionID, mailType, sender, subject, content, attachs)
			raise Return(ret)

	@gmrpc_log_coroutine
	def gmSendNewbieMail(self, name, accountName, mailType, sender, subject, content, attachs):
		if name not in self.gameAllRPCs:
			raise GMTaskError('no this server name')
		else:
			ret = yield self.gameAllRPCs[name].call_async('gmSendNewbieMail', accountName, mailType, sender, subject, content, attachs)
			raise Return(ret)

	testGiftCsv = None
	@gmrpc_coroutine
	def gmGetGiftCsv(self):
		if not self.testGiftCsv:
			from framework.csv import csv
			csv.reload()
			self.testGiftCsv = csv.gift.to_dict()
		raise Return(self.testGiftCsv)

	@gmrpc_coroutine
	def gmGenGift(self, giftID, size, opts=[]):
		ret = yield self.dbcGift.call_async('GiftGen', giftID, size, opts)
		raise Return(ret)

	@gmrpc_coroutine
	def gmOpenRPDB(self, name):
		if name not in self.gameAllRPCs:
			raise GMTaskError('no this server name')
		else:
			ret = yield self.gameAllRPCs[name].call_async('gmOpenRPDB')
			raise Return(ret)

	@gmrpc_coroutine
	def gmCloseRPDB(self, name):
		if name not in self.gameAllRPCs:
			raise GMTaskError('no this server name')
		else:
			ret = yield self.gameAllRPCs[name].call_async('gmCloseRPDB')
			raise Return(ret)

	@gmrpc_coroutine
	def gmFlushDB(self, name):
		if name not in self.gameAllRPCs:
			raise GMTaskError('no this server name')
		else:
			ret = yield self.gameAllRPCs[name].call_async('gmFlushDB')
			raise Return(ret)

	@gmrpc_coroutine
	def gmCommitDB(self, name):
		if name not in self.gameAllRPCs:
			raise GMTaskError('no this server name')
		else:
			ret = yield self.gameAllRPCs[name].call_async('gmCommitDB')
			raise Return(ret)

	@gmrpc_coroutine
	def gmExecPy(self, src, name=GlobalServerKey):
		ret = []
		if name == GlobalServerKey:
			fus = []
			for name, rpc in self.gameRPCs.iteritems():
				try:
					fus.append((name, rpc.call_async('gmExecPy', src)))
				except Exception, e:
					logger.exception('server `%s` execpy %s exception' % ret[-1])
				logger.info('server `%s` execpy' % name)

			for name, fu in fus:
				try:
					ret2 = yield fu
					ret.append((name, ret2))
				except Exception, e:
					ret.append((name, str(e)))

		else:
			ret = yield self.gameAllRPCs[name].call_async('gmExecPy', src)
			ret = [(name, ret)]
			logger.info('server `%s` execpy' % name)

		raise Return(ret)

	@gmrpc_coroutine
	def gmReloadAuto(self, name):
		ret = []
		if name == GlobalServerKey:
			fus = []
			for name, rpc in self.gameRPCs.iteritems():
				try:
					fus.append((name, rpc.call_async('gmReloadAuto')))
				except Exception, e:
					logger.exception('server `%s` reload %s exception' % ret[-1])
				logger.info('server `%s` reload py' % name)

			for name, fu in fus:
				try:
					ret2 = yield fu
					ret.append((name, ret2))
				except Exception, e:
					ret.append((name, str(e)))

		else:
			ret = yield self.gameAllRPCs[name].call_async('gmReloadAuto')
			ret = [(name, ret)]
			logger.info('server `%s` reload' % name)

		raise Return(ret)

	@gmrpc_coroutine
	def gmReloadPyFiles(self, name, srcs):
		ret = []
		if name == GlobalServerKey:
			fus = []
			for name, rpc in self.gameRPCs.iteritems():
				try:
					fus.append((name, rpc.call_async('gmReloadPyFiles', srcs)))
				except Exception, e:
					logger.exception('server `%s` reload %s exception' % ret[-1])
				logger.info('server `%s` reload py' % name)

			for name, fu in fus:
				try:
					ret2 = yield fu
					ret.append((name, ret2))
				except Exception, e:
					ret.append((name, str(e)))

		else:
			ret = yield self.gameAllRPCs[name].call_async('gmReloadPyFiles', srcs)
			ret = [ret]
			logger.info('server `%s` reload' % name)

		raise Return(ret)

	@gmrpc_coroutine
	def gmGetGameRank(self, name, rtype):
		if name not in self.gameAllRPCs:
			raise GMTaskError('no this server name')
		else:
			ret = yield self.gameAllRPCs[name].call_async('gmGetGameRank', rtype)
			raise Return(ret)

	@gmrpc_log_coroutine
	def gmSetSessionCapacity(self, name, capacity):
		if name not in self.gameAllRPCs:
			raise GMTaskError('no this server name')
		else:
			ret = yield self.gameAllRPCs[name].call_async('gmSetSessionCapacity', capacity)
			raise Return(ret)

	@gmrpc_log_coroutine
	def gmRoleAbandon(self, name, roleID, type, val):
		# 这个接口的roleID目前只能是24位的id，没有支持uid，需要加
		if name not in self.gameAllRPCs:
			raise GMTaskError('no this server name')
		else:
			ret = yield self.gameAllRPCs[name].call_async('gmRoleAbandon', roleID, type, val)
			raise Return(ret)

	@gmrpc_log_coroutine
	def gmRoleModify(self, name, roleID, key, val):
		if name not in self.gameAllRPCs:
			raise GMTaskError('no this server name')
		else:
			ret = yield self.gameAllRPCs[name].call_async('gmRoleModify', roleID, key, val)
			raise Return(ret)

	@gmrpc_coroutine
	def gmRejudgePVPPlay(self, name, playID, forceAll=False):
		if name not in self.gameAllRPCs:
			raise GMTaskError('no this server name')
		else:
			ret = yield self.gameAllRPCs[name].call_async('gmRejudgePVPPlay', playID, forceAll)
			raise Return(ret)

	@coroutine
	def gmGetRoleCards(self, name, roleID, cardIDs):
		if name not in self.gameAllRPCs:
			raise GMTaskError('no this server name')
		else:
			ret = yield self.gameAllRPCs[name].call_async('GMGetRoleCards', roleID, cardIDs)
			raise Return(ret)

	@coroutine
	def gmEvalCardAttrs(self, name, roleID, cardID, disables):
		if name not in self.gameAllRPCs:
			raise GMTaskError('no this server name')
		else:
			ret = yield self.gameAllRPCs[name].call_async('GMEvalCardAttrs', roleID, cardID, disables)
			raise Return(ret)

	@gmrpc_coroutine
	def gmGetGameBlackList(self):
		ret = self.server.blackListMap.getIP()
		raise Return(ret)

	@gmrpc_log_coroutine
	def gmAddGameBlackList(self, ipL):
		yield self.server.blackListMap.addIP(ipL)
		ret = yield self.server.blackListMap.push()
		ret.update(self.server.blackListMap.getIP())
		raise Return(GMTaskReturn(ret))

	@gmrpc_log_coroutine
	def gmDelGameBlackList(self, idL):
		yield self.server.blackListMap.deleteIP(idL)
		ret = yield self.server.blackListMap.push()
		ret.update(self.server.blackListMap.getIP())
		raise Return(GMTaskReturn(ret))

	@gmrpc_log_coroutine
	# 手动刷新
	def gmPushGameBlackList(self):
		ret = yield self.server.blackListMap.push()
		ret.update(self.server.blackListMap.getIP())
		raise Return(GMTaskReturn(ret))

	@gmrpc_coroutine
	def gmGetMailCsv(self, name):
		if name not in self.gameAllRPCs:
			raise GMTaskError('no this server name')
		else:
			ret = yield self.gameAllRPCs[name].call_async('gmGetMailCsv')
			raise Return(ret)

	@gmrpc_coroutine
	def gmGetUnionInfo(self, name, unionID):
		if name not in self.gameAllRPCs:
			raise GMTaskError('no this server name')
		else:
			ret = yield self.gameAllRPCs[name].call_async('gmGetUnionInfo', unionID)
			raise Return(ret)

	@gmrpc_coroutine
	def gmGetRoleInfoByVip(self, name, beginVip, endVip):
		if name not in self.gameAllRPCs:
			raise GMTaskError('no this server name')
		else:
			ret = yield self.gameAllRPCs[name].call_async('gmGetRoleInfoByVip', beginVip, endVip)
			raise Return(ret)
