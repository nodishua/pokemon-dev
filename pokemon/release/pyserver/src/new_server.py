#!/usr/bin/python
# -*- coding: utf-8 -*-

import datetime

HeadTemplates = """# {name}
# {ip1}(outside)
# {ip2}(Inside)
"""

DBPrefix = 'game_db_qq'
GamePrefix = 'game_qq'
PVPPrefix = 'pvp_qq'
CrossDBPrefix = 'cross_db_qq'
CrossPrefix = 'cross_qq'

# DBPrefix = 'game_db_tw'
# GamePrefix = 'game_tw'
# PVPPrefix = 'pvp_tw'

DBTemplates = """'{GamePrefix}{servID}': <
	'redis': <
		'host': '0.0.0.0',
		'port': {redisPort},
		'db': 0,
		'password': 'redis123',
	>,
	'host': '127.0.0.1',
	'port': {port},
	'log_topic': '{GamePrefix}{servID}',
>,"""
DBRedisPort = 10379
DBPort = 10777

GameTemplates = """'{GamePrefix}{servID}': <
	'game_db': '{DBPrefix}{servID}',
	'gift_db': 'gift_db_qq',
	'ip': '{ip}',
	'port': {port},
	'rpc_port': {rpcPort},
	'debug': False,
	'discovery': 'discovery_qq',
	'key': 'game.{servID}',
	'log_topic': '{GamePrefix}{servID}',
	'appnotify_listener': ('123.207.108.22', 1212),
	'open_date': datetime({year}, {month}, {day}, {hour}),
>,"""
GamePort = 10888
GameRPCPort = 10555

PVPTemplates = """'{PVPPrefix}{servID}': <
	'game_db': '{DBPrefix}{servID}',
	'host': '0.0.0.0',
	'port': {port},
	'anti_server': QQAntiServers,
	'discovery': 'discovery_qq',
	'key': 'pvp.{servID}',
	'log_topic': '{GamePrefix}{servID}',
>,"""
PVPPort = 10444

# TWAntiServers
# discovery_tw
CrossTemplates = """'{CrossPrefix}{servID}': <
	'db': '{CrossDBPrefix}{servID}',
	'host': '0.0.0.0',
	'port': {port},
	'anti_server': QQAntiServers,
	'discovery': 'discovery_qq',
	'key': 'cross.{id}',
	'log_topic': '{CrossPrefix}{servID}',
>,"""
CrossPort = 58888

# server open date start, one day can config many open time
GameDayStart = [datetime.datetime(2017, 2, 9, 10)]
# ignore open week day
IgnoreGameWDays = [] # [2, 4]
Servers = [
	# {
	# 	'name': 'tc-shuma-03',
	# 	'range': (2, 3),
	# 	'ip1': '115.159.183.222',
	# 	'ip2': '10.105.207.210',
	# },
	# {
	# 	'name': 'tc-shuma-04',
	# 	'range': (4, 5),
	# 	'ip1': '115.159.83.118',
	# 	'ip2': '10.105.246.50',
	# },
	# {
	# 	'name': 'tc-shuma-05',
	# 	'range': (6, 7),
	# 	'ip1': '115.159.44.187',
	# 	'ip2': '10.105.235.38',
	# },
	# {
	# 	'name': 'tc-shuma-06',
	# 	'range': (8, 9),
	# 	'ip1': '115.159.125.78',
	# 	'ip2': '10.105.125.91',
	# },
	# {
	# 	'name': 'tc-shuma-07',
	# 	'range': (10, 11),
	# 	'ip1': '115.159.102.209',
	# 	'ip2': '10.105.208.165',
	# },
	# {
	# 	'name': 'tc-shuma-08',
	# 	'range': (12, 13),
	# 	'ip1': '115.159.3.100',
	# 	'ip2': '10.105.202.147',
	# },
	# {
	# 	'name': 'tc-shuma-09',
	# 	'range': (14, 15),
	# 	'ip1': '115.159.22.50',
	# 	'ip2': '10.105.197.220',
	# },
	# {
	# 	'name': 'tc-shuma-10',
	# 	'range': (16, 17),
	# 	'ip1': '115.159.99.91',
	# 	'ip2': '10.105.192.46',
	# },
	# {
	# 	'name': 'tc-shuma-11',
	# 	'range': (18, 19),
	# 	'ip1': '115.159.36.101',
	# 	'ip2': '10.105.26.65',
	# },
	# {
	# 	'name': 'tc-shuma-12',
	# 	'range': (20, 21),
	# 	'ip1': '115.159.59.152',
	# 	'ip2': '10.133.200.249',
	# },
	# {
	# 	'name': 'tc-shuma-13',
	# 	'range': (22, 23),
	# 	'ip1': '182.254.216.172',
	# 	'ip2': '10.133.194.88',
	# },
	# {
	# 	'name': 'tc-shuma-14',
	# 	'range': (24, 25),
	# 	'ip1': '182.254.241.252',
	# 	'ip2': '10.133.200.54',
	# },
	# {
	# 	'name': 'tc-shuma-15',
	# 	'range': (26, 27),
	# 	'ip1': '115.159.200.184',
	# 	'ip2': '10.105.58.19',
	# },
	# {
	# 	'name': 'tc-shuma-16',
	# 	'range': (28, 29),
	# 	'ip1': '115.159.185.23',
	# 	'ip2': '10.105.6.156',
	# },

	{
		'name': 'tc-shuma-25',
		'range': (217, 225),
		'ip1': '123.206.192.74',
		'ip2': '10.105.84.76',
	},
]

def format2json(s):
	return s.replace('<', '{').replace('>', '}')

def new_game_server():
	# db
	content, content2 = [], []
	for serv in Servers:
		one, two = [], []
		for i in xrange(serv['range'][0], 1+serv['range'][1]):
			servID = '%02d' % i
			redisPort = DBRedisPort + 1000 * (i - serv['range'][0])
			port = DBPort + 1000 * (i - serv['range'][0])
			one.append(format2json(DBTemplates.format(servID=servID, redisPort=redisPort, port=port, DBPrefix=DBPrefix, GamePrefix=GamePrefix, PVPPrefix=PVPPrefix)))
			two.append(format2json("'{DBPrefix}{servID}': <'server': '{GamePrefix}{servID}'>,".format(servID=servID, DBPrefix=DBPrefix, GamePrefix=GamePrefix, PVPPrefix=PVPPrefix)))
		one[0] = HeadTemplates.format(**serv) + one[0]
		content.append('\n'.join(one))
		content2.append('\n'.join(two))
	with open('db_defines.txt', 'wb') as fp:
		fp.write('\n' + '-'*20 + '\n')
		fp.write('\n\n'.join(content))
		fp.write('\n' + '-'*20 + '\n')
		fp.write('\n\n'.join(content2))

	# game
	content, cnt = [], 0
	for serv in Servers:
		one = []
		for i in xrange(serv['range'][0], 1+serv['range'][1]):
			servID = '%02d' % i
			rpcPort = GameRPCPort + 1000 * (i - serv['range'][0])
			port = GamePort + 1000 * (i - serv['range'][0])
			date = GameDayStart[cnt % len(GameDayStart)] + datetime.timedelta(days=cnt / len(GameDayStart))
			while date.isoweekday() in IgnoreGameWDays:
				cnt += 1
				date = GameDayStart[cnt % len(GameDayStart)] + datetime.timedelta(days=cnt / len(GameDayStart))
			one.append(format2json(GameTemplates.format(servID=servID, rpcPort=rpcPort, port=port, ip=serv['ip1'], year=date.year, month=date.month, day=date.day, hour=date.hour, DBPrefix=DBPrefix, GamePrefix=GamePrefix, PVPPrefix=PVPPrefix)))
			cnt += 1
		one[0] = HeadTemplates.format(**serv) + one[0]
		content.append('\n'.join(one))
	with open('game_defines.txt', 'wb') as fp:
		fp.write('\n' + '-'*20 + '\n')
		fp.write('\n\n'.join(content))

	# pvp
	content, content2 = [], []
	for serv in Servers:
		one, two = [], []
		for i in xrange(serv['range'][0], 1+serv['range'][1]):
			servID = '%02d' % i
			port = PVPPort + 1000 * (i - serv['range'][0])
			one.append(format2json(PVPTemplates.format(servID=servID, port=port, DBPrefix=DBPrefix, GamePrefix=GamePrefix, PVPPrefix=PVPPrefix)))
			two.append(format2json("'{GamePrefix}{servID}': <'server': '{PVPPrefix}{servID}'>,".format(servID=servID, DBPrefix=DBPrefix, GamePrefix=GamePrefix, PVPPrefix=PVPPrefix)))
		one[0] = HeadTemplates.format(**serv) + one[0]
		content.append('\n'.join(one))
		content2.append('\n'.join(two))
	with open('pvp_defines.txt', 'wb') as fp:
		fp.write('\n' + '-'*20 + '\n')
		fp.write('\n\n'.join(content))
		fp.write('\n' + '-'*20 + '\n')
		fp.write('\n\n'.join(content2))

	# login
	content = []
	for serv in Servers:
		one = []
		for i in xrange(serv['range'][0], 1+serv['range'][1]):
			servID = '%02d' % i
			one.append("'{GamePrefix}{servID}',".format(servID=servID, DBPrefix=DBPrefix, GamePrefix=GamePrefix, PVPPrefix=PVPPrefix))
		content.append('\n'.join(one))
	with open('login_defines.txt', 'wb') as fp:
		fp.write('\n' + '-'*20 + '\n')
		fp.write('\n\n'.join(content))

def new_cross_server():
	# cross
	content, content2 = [], []
	for serv in Servers:
		one, two = [], []
		for i in xrange(serv['range'][0], 1+serv['range'][1]):
			servID = '%02d' % i
			port = CrossPort + 1 * (i - serv['range'][0])
			one.append(format2json(CrossTemplates.format(id=int(servID), servID=servID, port=port, CrossDBPrefix=CrossDBPrefix, CrossPrefix=CrossPrefix)))
		one[0] = HeadTemplates.format(**serv) + one[0]
		content.append('\n'.join(one))
	with open('cross_defines.txt', 'wb') as fp:
		fp.write('\n' + '-'*20 + '\n')
		fp.write('\n\n'.join(content))

if __name__ == '__main__':
	new_game_server()
	# new_cross_server()


