#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2017 TianJi Information Technology Inc.
'''
from __future__ import absolute_import

import os
import re
import ast
import copy
import functools

from gm.object.db import *

from . import analyzer
from .archive import *
from .autoreload import add_reload_hook, start
from .analyzer import getChannelAndSubChannel, getSubchannelByChannel
from gm.util import *
from gm.object.account import DBAccount
from gm.object.archive import DBArchive

from framework import *


# ...../192.168.1.98/game_server/.....
# Log storage directory
LogDirPath = '/mnt/log'
# Log matching rules
AdapterLine = r"\[.* gain:\d+\] role \d+ .*\n"
LevelAdapterLine = r"\[.* _game:\d+\].*channel .+ account .+ role \d+ \w* level \d+ vip \d+ gold \d+ rmb .*\n"
LoginAdapterLine = r"\[.* enter_server\.go:\d+\].* login in server \d+ .*\n"


def preHandle(line):
	# If there is the head of rsyslog, remove it first
	return line.strip().split(' ', 1)[-1]

LogHead = r"\[(?P<servKey>\S+) I (?P<dateTime>\d+ [\d:]+).+?\]"
def handleLineHead(line):
	# [game_dev2 I 190727 20:19:32  _game:508]
	p = re.search(LogHead, line)
	if not p:
		print '!! error handleLineHead %s'% line
		return None
	return p.groupdict()

# Process level distribution
def onLevelAdapterLine(mongo, logger, line):
	# [game.dev.2 I 190727 20:19:32  _game:508] channel none account 5d39e53c80ae88767963c57e role 14404 5d39e53d80ae8825c7a8f390 level 1 vip 0 gold 20000 rmb 0
	try:
		line = preHandle(line)
		head = handleLineHead(line)
		if head is None:
			return

		server_key, dateTimeStr = head['servKey'], '20'+head['dateTime']
		area = int(server_key.split(".")[-1])
		language = getServerLanguageByKey(servKey2ServName(server_key))
		dateT = datetime.datetime.strptime(dateTimeStr, "%Y%m%d %H:%M:%S")
		timeStamp, dateInt = datetime2timestamp(dateT), date2int(dateT)

		content = line.strip().split(']', 1)[1].strip()
		offset = 0
		if "new role" in content:
			offset = 2
		ps = content.split(' ')
		channel, account, role_uid, role_id = ps[1+offset], ps[3+offset], ps[5+offset], ps[6+offset]
		level, vip, gold, rmb = ps[8+offset], ps[10+offset], ps[12+offset], ps[14+offset]

	except Exception as e:
		logger.warning('!! handle level line error: %s'% line)
		print e
		return

	# ROLE record
	role = DBFindOrCreate(mongo.client, DBLogRole, {'language': language, 'server_key': server_key, 'role_id': role_id})
	# DB supplementary record
	subChannel = getSubchannelByChannel(channel)
	dbQuery = {'date': dateInt, 'language': language, 'area': area, 'channel': channel, 'sub_channel': subChannel}
	dbArchive = DBFindOrCreate(mongo.client, DBArchive, dbQuery)

	if offset != 0:
		role.set(account, channel, role_uid, level, vip, rmb, gold, timeStamp, timeStamp)
		dbArchive.addAccountAreaCreated(account, timeStamp)
	else:
		role.set(account, channel, role_uid, level, vip, rmb, gold, timeStamp)
		dbArchive.addAccountAreaLogin(account, timeStamp)
	DBSave(mongo.client, role)
	DBSave(mongo.client, dbArchive)

	# ROLEDB statistics
	detailDs = str(datetime2int(dateT))
	archive = DBFindOrCreate(mongo.client, DBLogRoleArchive, {'date': dateInt, 'language': language, 'server_key': server_key})
	if offset != 0:
		archive.set(role_id, detailDs, level, vip, True)
	else:
		archive.set(role_id, detailDs, level, vip)

# Consumption of items
def onAdapterLine(mongo, logger, line):
	#  game_server [game_dev2 I 190807 21:07:12  gain:390] role 14294 5d34d92a80ae8825c7a8e463 gain from gate_saodang_drop_10202, {5000: 32, 3008: 26, 3007: 37, 5007: 77}
	try:
		line = preHandle(line)
		head = handleLineHead(line)
		if head is None:
			return

		server_key, dateTimeStr = head['servKey'], '20'+head['dateTime']
		language = getServerLanguageByKey(servKey2ServName(server_key))
		dateT = datetime.datetime.strptime(dateTimeStr, "%Y%m%d %H:%M:%S")
		dateInt = date2int(dateT)

		ps = line.strip().split(']', 1)[1].strip().split(',', 1)
		partList, info = ps[0].strip().split(' '), ps[1].strip()

		detailDateS = str(dateT)
		role_uid, role_id, t, from_key = partList[1], partList[2], partList[3], partList[5]

	except Exception as e:
		logger.warning('!! handle gain line error: %s'% line)
		print e
		return

	key = {
		'date': dateInt,
		'language': language,
		'server_key': server_key,
		'from_key': from_key
	}

	# Character ID Consumption Record
	# roleRecord = DBFindOrCreate(mongo.client, DBLogRoleArchive, {'date': dateInt,
	# 	'language': language, 'server_key': server_key})
	# roleRecord.set(role_id, t, from_key, detailDateS, info)

	# Event consumption record
	try:
		dic = ast.literal_eval(info)
	except Exception as e:
		logger.warning('!! error info: %s'% info)
		print e
	else:
		detailDs = str(datetime2int(dateT))
		sumArchive = DBFindOrCreate(mongo.client, DBLogItemArchive, key)
		sumArchive.set(t, detailDs, dic, role_id)

# Treatment login
def onLoginAdapterLine(mongo, logger, accountMongo, line):
	# login_server [login.cn.1 I 190820 16:53:04.289.059 enter_server.go:31] `tc_8252422` login in server 1 `game.cn.1` `Pikachu`
	try:
		line = preHandle(line)
		head = handleLineHead(line)
		if head is None:
			return

		server_key, dateTimeStr = head['servKey'], '20'+head['dateTime'].split('.')[0]
		language = getServerLanguageByKey(servKey2ServName(server_key))
		dateT = datetime.datetime.strptime(dateTimeStr, "%Y%m%d %H:%M:%S")
		timeStamp = datetime2timestamp(dateT)
		dateInt = date2int(dateT)

		ps = line.strip().split(']', 1)[1].strip().split(' ')
		name, gameServerKey = re.sub(r"[`'\"]", "", ps[0]), re.sub(r"[`'\"]", "", ps[5])
		area = int(ps[4].strip())

	except Exception as e:
		logger.warning('!! handle login line error: %s'% line)
		print e
		return

	field = {'name': 1, 'channel': 1, 'language': 1, 'pass_md5': 1, 'create_time': 1, 'last_time': 1}
	account = accountMongo.client.Account.find_one({'name': name}, field)
	if not account:
		logger.warning('not find the name %s account in accountMongo'% name)
		return
	account = AttrsDict(account)
	channel, subChannel = getChannelAndSubChannel(account)

	# Record account
	GMAccount = DBFindOrCreate(mongo.client, DBAccount, {'account_id': account._id})
	GMAccount.set(account, channel, subChannel)
	GMAccount.addLogin(area)

	query = {'date': dateInt, 'channel': channel, 'sub_channel': subChannel,
		'language': language, 'area': area}
	archive = DBFindOrCreate(mongo.client, DBArchive, query)

	query.pop('date', None)
	archives = DBFind(mongo.client, DBArchive, query)
	sumCreateArea = set([])
	for a in archives:
		sumCreateArea |= a.create
	if account._id not in sumCreateArea:
		archive.addAccountAreaCreated(account._id, timeStamp)
	else:
		archive.addAccountAreaLogin(account._id, timeStamp)
	DBSave(mongo.client, archive)


# Process change file
def onModifiedFile(mongo, logger, path):
	# Analytical filepath： /var/log/192.168.1.98/game_server/2019-12-14.log
	# /mnt/log/cn_01_game_server/2019-12-14.log
	try:
		size = os.stat(path).st_size

		pathList = path.split('/')
		server_key, name = pathList[-2], pathList[-1]
		dateInt = int(name[:-4].replace('-', ''))
	except Exception as e:
		logger.warning('!! error log path: %s'% path)
		return

	# Depending on the database to take related records for comparison
	record = DBFindOrCreate(mongo.client, DBOfflineLogInfo, {'server_key':server_key})

	pos = record.cur_pos
	ret = []
	if dateInt == record.cur_date:
		# The change file on the day is not a new file
		with open(path, 'rb') as fd:
			fd.seek(pos)
			lines = fd.readlines()

		pos += len(''.join(lines))
		ret += lines

	elif dateInt > record.cur_date:
		# New day, new files
		dtNew, dtOld = int2date(dateInt), int2date(record.cur_date)

		while dtNew >= dtOld:
			oldDateInt = date2int(dtOld)
			filePath = os.path.join(LogDirPath, server_key, dateInt2str(oldDateInt)+'.log')
			if not os.path.exists(filePath):
				dtOld += OneDay
				continue

			with open(filePath, 'rb') as fd:
				fd.seek(pos)
				lines = fd.readlines()

			ret += lines
			pos = 0
			if dtOld == dtNew:
				pos = len(''.join(lines))
			dtOld += OneDay

	else:
		logger.warning('skip %s'% dateInt)
		return

	for line in ret:
		analyzer.processLine(line)
	record.cur_date = dateInt
	record.cur_pos = pos
	DBSave(mongo.client, record)
	DBCache.saveAllMongo(mongo.client)


def startOfflineDaemon(ioloop, logger, mongo, accountMongo, check_time=2000):
	analyzer.addReHandler(re.compile(AdapterLine), functools.partial(onAdapterLine, mongo, logger))
	analyzer.addReHandler(re.compile(LevelAdapterLine), functools.partial(onLevelAdapterLine, mongo, logger))
	# analyzer.addReHandler(re.compile(LoginAdapterLine), functools.partial(onLoginAdapterLine, mongo, logger, accountMongo))

	add_reload_hook(functools.partial(onModifiedFile, mongo, logger))
	start(LogDirPath, io_loop=ioloop, check_time=check_time)


def dateInt2str(v):
	return str(v/10000) + '-' + '%02d'% ((v/100)%100) + '-' + '%02d'% (v%100)
