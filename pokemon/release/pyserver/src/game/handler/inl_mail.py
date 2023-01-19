#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2014 YouMi Information Technology Inc.
'''

from framework import nowtime_t
from framework.csv import csv, ErrDefs
from framework.log import logger
from framework.helper import getL10nCsvValue

from game import ServerError, ClientError
from game.globaldata import PVPAwardMailID, GlobalMailRoleID, RandomTowerAwardMailID
from game.object import TargetDefs, MailDefs, AchievementDefs
from game.object.game.role import ObjectRole
from game.object.game.rank import ObjectPWAwardRange, ObjectRandomTowerAwardRange
from game.object.game.mail import ObjectMailGlobal
from game.object.game.gain import pack

from tornado.gen import coroutine, moment, Return

import binascii

@coroutine
def deleteMail(roleID, mailID, dbc, game, gglobal=False):
	# 全局或全服邮件数据库数据不可删除
	if not gglobal:
		mailData = yield dbc.call_async('DBUpdate', 'Mail', mailID, {
			'deleted_flag': True,
		}, False)
		if not mailData['ret']:
			raise ServerError('db update mail error')
		# dbc.call_async('DBDelete', 'Mail', mailID, False)

	game.role.delMail(mailID)
	raise Return(True)

@coroutine
def sendRankPeriodAwardMail(roleID, game, rank, dbc, sendTime=None):
	award = ObjectPWAwardRange.getRange(rank)
	if award is None:
		raise Return(None)

	if not award.inRange(rank):
		raise ServerError('rank not in range')

	if rank == 1: # 竞技场第一，公会红包发放资格
		game.role.refreshUnionRedpackets(TargetDefs.ArenaRank, count=1, time=sendTime)

	mail = ObjectRole.makeMailModel(roleID, PVPAwardMailID, contentArgs=rank, attachs=award.periodAward, sendTime=sendTime)
	yield sendMail(mail, dbc, game)

@coroutine
def sendOnlineRankPeriodAwardMails(rpc, dbc):
	from game.object.game import ObjectGame

	allobjs, safeGuard = ObjectGame.getAll()
	allRanks = {}
	with safeGuard:
		allids = [obj.role.id for obj in allobjs]
		onlineRanks, allRanks = yield rpc.call_async('OnRankPeriodAward', allids)
		if onlineRanks:
			sendTime = nowtime_t()
			for i in xrange(len(allids)):
				obj = allobjs[i]
				if not onlineRanks[i]: # if value is zero, mean not in arena
					continue
				try:
					yield sendRankPeriodAwardMail(allids[i], obj, onlineRanks[i], dbc, sendTime)
				except:
					logger.exception('pvp award rank %s roleID %s', onlineRanks[i], binascii.hexlify(allids[i]))
				yield moment # like sleep
				logger.info('pvp award rank %s roleID %s', onlineRanks[i], binascii.hexlify(allids[i]))
	raise Return(allRanks)


def getRankRandomTowerAwardMail(roleID, rank):
	award = ObjectRandomTowerAwardRange.getRange(rank)
	if award is None:
		return None

	if not award.inRange(rank):
		logger.info('random_tower rank %d not in range', rank)
		return None

	cfg = csv.mail[RandomTowerAwardMailID]
	content = getL10nCsvValue(cfg, 'content') % (rank)
	return ObjectRole.makeMailModel(roleID, RandomTowerAwardMailID, content=content, attachs=award.periodAward)

@coroutine
def sendMail(mail, dbc, game=None):
	if game and game.is_gc_destroy():
		game = None
	if game and not game.role.canAddMail(mail['time']):
		raise Return(False)

	attachs = mail['attachs']
	mail['attachs'] = pack(attachs)
	mailData = yield dbc.call_async('DBCreate', 'Mail', mail)
	if not mailData['ret']:
		raise ServerError('db create mail error\n%s' % str(mailData))
	mailData = mailData['model']
	mailID = mailData['id']
	toRoleID = mail['role_db_id']

	if game and game.is_gc_destroy():
		game = None

	# 玩家在线
	if game:
		game.role.addMailThumb(mailID, mail['subject'], mail['time'], mail['type'], mail['sender'], False, mail['attachs'] and True or False)
		game.role.setMailModel(mailID, mailData)

	# 玩家离线
	else:
		mailBoxData = yield dbc.call_async('DBMultipleReadKeys', 'Role', [toRoleID], ['mailbox'])
		if not mailBoxData['ret']:
			raise ServerError('db read mailbox error')
		mailBoxData = mailBoxData['models'][0]['mailbox']
		mailBoxData = ObjectRole.addMailThumbInMem(mailBoxData, mailData, toRoleID)
		ret = yield dbc.call_async('DBUpdate', 'Role', toRoleID, {'mailbox': mailBoxData}, False)
		if not ret['ret']:
			raise ServerError('db update mailbox error\n%s' % str(ret))

	logger.info('send mail %s to %s role %s, %d %s %s', binascii.hexlify(mailID), 'online' if game else 'offline', binascii.hexlify(toRoleID), mail['type'], mail['subject'], attachs)
	raise Return(True)

@coroutine
def sendGlobalMail(dbc, mailType, sender, subject, content, attachs, sendTime=None):
	sendTime = sendTime if sendTime else nowtime_t()

	attachs = pack(attachs)
	mailData = yield dbc.call_async('DBCreate', 'Mail', {
		'role_db_id': GlobalMailRoleID,
		'time': sendTime,
		'type': mailType,
		'sender': sender,
		'subject': subject,
		'content': content,
		'attachs': attachs,
	})
	if not mailData['ret']:
		raise ServerError('db create mail error')

	mailID = mailData['model']['id']
	ObjectMailGlobal.addGlobalMail(mailID, subject, sendTime, mailType, sender, attachs and True or False)

@coroutine
def sendServerMail(dbc, mailType, sender, subject, content, attachs, sendTime=None):
	sendTime = sendTime if sendTime else nowtime_t()

	attachs = pack(attachs)
	mailData = yield dbc.call_async('DBCreate', 'Mail', {
		'role_db_id': GlobalMailRoleID,
		'time': sendTime,
		'type': mailType,
		'sender': sender,
		'subject': subject,
		'content': content,
		'attachs': attachs,
	})
	if not mailData['ret']:
		raise ServerError('db create mail error')

	mailID = mailData['model']['id']
	ObjectMailGlobal.addServerMail(mailID, subject, sendTime, mailType, sender, attachs and True or False)

@coroutine
def sendVipMail(dbc, beginVip, endVip, mailType, sender, subject, content, attachs, sendTime=None):
	sendTime = sendTime if sendTime else nowtime_t()

	attachs = pack(attachs)
	mailData = yield dbc.call_async('DBCreate', 'Mail', {
		'role_db_id': GlobalMailRoleID,
		'time': sendTime,
		'type': mailType,
		'sender': sender,
		'subject': subject,
		'content': content,
		'attachs': attachs,
	})
	if not mailData['ret']:
		raise ServerError('db create mail error')

	mailID = mailData['model']['id']
	ObjectMailGlobal.addVipMail(beginVip, endVip, mailID, subject, sendTime, mailType, sender, attachs and True or False)

@coroutine
def sendUnionMail(dbc, unionID, mailType, sender, subject, content, attachs, sendTime=None):
	sendTime = sendTime if sendTime else nowtime_t()
	attachs = pack(attachs)
	mailData = yield dbc.call_async('DBCreate', 'Mail', {
		'role_db_id': GlobalMailRoleID,
		'time': sendTime,
		'type': mailType,
		'sender': sender,
		'subject': subject,
		'content': content,
		'attachs': attachs,
	})
	if not mailData['ret']:
		raise ServerError('db create mail error')

	mailID = mailData['model']['id']
	thumb = {
		'db_id': mailID,
		'subject': subject,
		'time': sendTime,
		'type': mailType,
		'mtype': MailDefs.TypeUnion,
		'sender': sender,
		'hasattach': attachs and True or False,
	}
	raise Return(thumb)

@coroutine
def sendNewbieMail(dbc, accountName, mailType, sender, subject, content, attachs, sendTime=None):
	sendTime = sendTime if sendTime else nowtime_t()

	attachs = pack(attachs)
	mailData = yield dbc.call_async('DBCreate', 'Mail', {
		'role_db_id': GlobalMailRoleID,
		'time': sendTime,
		'type': mailType,
		'sender': sender,
		'subject': subject,
		'content': content,
		'attachs': attachs,
		'newbie_name': accountName,
	})
	if not mailData['ret']:
		raise ServerError('db create mail error')

@coroutine
def sendUnionAwardMail(dbc, union, mailType, sender, args, attachs):
	sendTime = nowtime_t()
	cfg = csv.mail[mailType]
	subject = getL10nCsvValue(cfg, 'subject')
	content = getL10nCsvValue(cfg, 'content') % args

	attachs = pack(attachs)
	mailData = yield dbc.call_async('DBCreate', 'Mail', {
		'role_db_id': GlobalMailRoleID,
		'time': sendTime,
		'type': mailType,
		'sender': sender,
		'subject': subject,
		'content': content,
		'attachs': attachs,
	})
	if not mailData['ret']:
		raise ServerError('db create mail error')

	mailID = mailData['model']['id']
	union.addMail(mailID, subject, sendTime, mailType, sender, attachs and True or False)


def sendUnionFubenRankAwardMail(dbc, ranks):
	if not ranks:
		return

	from game.globaldata import UnionFubenRankAwardMailID
	from game.mailqueue import MailJoinableQueue

	cache = {}
	for roleID, rank, csvID, damage in ranks:
		fbname = csv.union.union_fuben[csvID].name
		award = cache.get(rank, None)
		if award is None:
			for idx in csv.union.union_fuben_rank:
				cfg = csv.union.union_fuben_rank[idx]
				if cfg.range[0] <= rank <= cfg.range[1]:
					award = cfg.award
					break
			cache[rank] = award
		if award is None:
			logger.warning('union fuben rank %d not award', rank)
			continue
		mail = ObjectRole.makeMailModel(roleID, UnionFubenRankAwardMailID, contentArgs=(fbname, rank, damage), attachs=award)
		MailJoinableQueue.send(mail)
