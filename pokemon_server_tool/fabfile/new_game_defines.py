#!/usr/bin/env python
# -*- coding: utf-8 -*-
# @Time     : 2020/7/20 21:51
# @Author   : cancan
# @File     : new_server.py
# @Function :

from fabfile import ServerIDMap
import os
import sys

sys.path.append(os.path.join(os.getcwd(), '../../release'))
sys.path.append(os.path.join(os.getcwd(), '../mergeserver'))
from game_defines import ServerDefs
from run_merge import MergeServs

dateTemp1 = "datetime({year}, {month}, {day}, {hour})"
dateTemp2 = "datetime({year}, {month}, {day}, {hour}, {minute})"
dateTemp3 = 'datetime(2022, 12, 31, 00)'  # 新服配置默认开服日期

machineTemp = """
	# {machine}
	# {public}(公)
	# {private}(内)
"""

defsTemp = """\t'{key}': <
		'ip': '{ip}',
		'port': {port},
		'nsq': {nsq},
		'shushu': {shushu},
		'open_date': {open_date},
		'dependent': [
			'anticheat',
			'chat_monitor',
			"giftdb.{language}.1",
			"card_comment.{language}.1",
			"card_score.{language}.1",
		],
	>,
"""

defsMergedTemp = """\t'{key}': <
		'ip': '{ip}',
		'port': {port},
		'nsq': {nsq},
		'shushu': {shushu},
		'open_date': {open_date},
		'merged': True,
		'alias': {alias},
		'dependent': [
			'anticheat',
			'chat_monitor',
			"giftdb.{language}.1",
			"card_comment.{language}.1",
			"card_score.{language}.1",
		],
	>,
"""

head = """#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2014 YouMi Information Technology Inc.

game server config defines
'''

from datetime import datetime

from nsq_defines import *

ServerDefs = {
	'game.dev.1': {
		'ip': '0.0.0.0',
		'port': 28879,
		'debug': True,
		'nsq': NSQDefs,
		'open_date': datetime(2020, 2, 17, 10),
		'dependent': [
			'anticheat',
			'chat_monitor',
			"giftdb.dev.1",
			"card_comment.dev.6",
			"card_score.dev.6",
		],
	},
	# 内网审核服
	'game.dev.7': {
		'ip': '0.0.0.0',
		'port': 28873,
		'debug': True,
		'nsq': NSQDefs,
		'open_date': datetime(2019, 9, 17, 10),
		'dependent': [
		],
	},
	'game.dev.8': {
		'ip': '0.0.0.0',
		'port': 28872,
		'debug': True,
		'nsq': NSQDefs,
		'open_date': datetime(2020, 3, 1, 10),
		'dependent': [
		],
	},
	'game.dev.9': {
		'ip': '0.0.0.0',
		'port': 28871,
		'debug': True,
		'nsq': NSQDefs,
		'open_date': datetime(2020, 3, 1, 10),
		'dependent': [
		],
	},
	'game.dev.10': {
		'ip': '0.0.0.0',
		'port': 28870,
		'debug': True,
		'nsq': NSQDefs,
		'open_date': datetime(2020, 3, 1, 10),
		'dependent': [
		],
	},
	'game.dev.11': {
		'ip': '0.0.0.0',
		'port': 10888,
		'debug': True,
		'nsq': NSQDefs,
		'open_date': datetime(2019, 9, 17, 10),
		'dependent': [
		],
	},
	'game.dev.12': {
		'ip': '0.0.0.0',
		'port': 28879,
		'debug': True,
		'nsq': NSQDefs,
		'open_date': datetime(2020, 2, 17, 10),
		'dependent': [
			'anticheat',
			'chat_monitor',
			"giftdb.dev.1",
			"card_comment.dev.6",
			"card_score.dev.6",
		],
	},

	# 体验服
    'game.trial.1': {
        'ip': '0.0.0.0',
        'port': 38879,
        'nsq': TRIALNSQDefs,
        'open_date': datetime(2019, 12, 4, 10),
        'dependent': [
            'chat_monitor',
            "giftdb.trial.1",
        ],
    },

	# 外网审核服
	'game.shenhe.1': {
		'ip': '172.81.227.66',
		'port': 10888,
		'debug': True,
		'nsq': CNNSQDefs,
		'open_date': datetime(2019, 9, 17, 10),
		'dependent': [
		],
	},
"""

newLines = [head]

tail = """
}


if __name__ == "__main__":
	import json
	servers = []
	for key in sorted(ServerDefs.keys()):
		cfg = ServerDefs[key]
		if 'alias' in cfg:
			for k in cfg['alias']:
				servers.append({
					'key': k,
					'addr': '%s:%d' % (cfg['ip'], cfg['port']),
					'open_date': cfg['open_date'].strftime('%Y-%m-%d %H:%M:%S'),
				})
		else:
			servers.append({
				'key': key,
				'addr': '%s:%d' % (cfg['ip'], cfg['port']),
				'open_date': cfg['open_date'].strftime('%Y-%m-%d %H:%M:%S'),
			})
	servers = sorted(servers, key=lambda x:x['key'])
	with open('./login/conf/game.json', 'w') as fp:
		json.dump(servers, fp, sort_keys=True, indent=2)
"""

Machines = {
	'tc-pokemon-cn-01': ('212.64.40.75', '172.16.2.11'),
	'tc-pokemon-cn-02': ('106.54.126.187', '172.16.2.9'),
	'tc-pokemon-cn-03': ('175.24.82.171', '172.16.2.4'),
	'tc-pokemon-cn-04': ('175.24.83.86', '172.16.2.5'),
	'tc-pokemon-cn-05': ('212.64.87.171', '172.16.2.6'),
	'tc-pokemon-cn-06': ('175.24.90.190', '172.16.2.15'),
	'tc-pokemon-cn-07': ('175.24.66.44', '172.16.2.8'),
	'tc-pokemon-cn-08': ('49.235.219.233', '172.16.2.12'),
	'tc-pokemon-cn-09': ('49.235.43.249', '172.16.2.27'),
	'tc-pokemon-cn-10': ('175.24.94.71', '172.16.2.26'),
	'tc-pokemon-cn-11': ('175.24.55.248', '172.16.2.23'),
	'tc-pokemon-cn-12': ('212.64.32.10', '172.16.2.38'),
	'tc-pokemon-cn-13': ('129.211.84.248', '172.16.2.19'),
	'tc-pokemon-cn-14': ('175.24.16.53', '172.16.2.20'),
	'tc-pokemon-cn-15': ('49.234.76.95', ''),
	'tc-pokemon-cn-16': ('49.235.40.29', ''),
	'tc-pokemon-cn-17': ('106.54.70.57', ''),
	'tc-pokemon-cn-18': ('49.235.247.167', ''),
	'tc-pokemon-cn-19': ('49.235.16.217', ''),
	'tc-pokemon-cn-20': ('212.64.64.74', ''),
	'tc-pokemon-cn-21': ('49.235.229.36', '172.16.2.111'),
	'tc-pokemon-cn-22': ('175.24.115.75', '172.16.2.95'),
	'tc-pokemon-cn-23': ('175.24.116.251', '172.16.2.64'),
	'tc-pokemon-cn-24': ('49.234.67.78', ''),
	'tc-pokemon-cn-25': ('175.24.115.50', ''),
	'tc-pokemon-cn-26': ('49.234.125.15', ''),
	'tc-pokemon-cn-27': ('49.235.232.176', '172.16.2.190'),
	'tc-pokemon-cn-28': ('175.24.127.203', '172.16.2.248'),
	'tc-pokemon-cn-29': ('49.234.220.30', '172.16.2.193'),
	'tc-pokemon-cn-30': ('49.235.234.36', '172.16.2.222'),
	'tc-pokemon-cn-31': ('175.24.126.239', '172.16.2.160'),
	'tc-pokemon-cn-32': ('49.234.99.152', '172.16.2.175'),
	'tc-pokemon-cn-33': ('49.234.100.39', '172.16.2.187'),
	'tc-pokemon-cn-34': ('49.235.249.195', '172.16.2.239'),
	'tc-pokemon-cn-35': ('49.234.92.112', '172.16.2.231'),
	'tc-pokemon-cn-36': ('175.24.114.83', '172.16.2.211'),
	'tc-pokemon-cn-37': ('121.4.193.117', '172.16.2.202'),
	'tc-pokemon-cn-38': ('49.235.249.136', '172.16.2.219'),
	'tc-pokemon-cn-39': ('49.234.108.115', '172.16.2.166'),
	'tc-pokemon-cn-40': ('101.34.100.239', ''),
	'tc-pokemon-cn-41': ('1.116.61.52', ''),
	'tc-pokemon-cn-42': ('49.234.64.219', '172.16.2.183'),
	'tc-pokemon-cn-43': ('101.34.136.153', '172.16.2.201'),
	'tc-pokemon-cn-44': ('1.116.65.171', '172.16.2.220'),

	'tc-pokemon-cn_qd-01': ('49.235.248.105', '172.16.2.17'),
	'tc-pokemon-cn_qd-02': ('49.235.238.44', '172.16.2.42'),
	'tc-pokemon-cn_qd-03': ('106.54.69.20', '172.16.2.32'),
	'tc-pokemon-cn_qd-04': ('175.24.51.5', '172.16.2.31'),
	'tc-pokemon-cn_qd-05': ('49.234.90.53', '172.16.2.48'),
	'tc-pokemon-cn_qd-06': ('175.24.77.41', '172.16.2.33'),
	'tc-pokemon-cn_qd-07': ('175.24.83.162', '172.16.2.44'),
	'tc-pokemon-cn_qd-08': ('129.211.48.90', '172.16.2.30'),
	'tc-pokemon-cn_qd-09': ('49.235.20.229', '172.16.2.41'),
	'tc-pokemon-cn_qd-10': ('49.234.70.41', '172.16.2.24'),
	'tc-pokemon-cn_qd-11': ('49.234.230.143', '172.16.2.45'),
	'tc-pokemon-cn_qd-12': ('49.235.249.116', '172.16.2.37'),
	'tc-pokemon-cn_qd-13': ('49.234.219.64', '172.16.2.36'),
	'tc-pokemon-cn_qd-14': ('106.54.121.184', '172.16.2.29'),
	'tc-pokemon-cn_qd-15': ('49.234.229.205', '172.16.2.21'),
	'tc-pokemon-cn_qd-16': ('175.24.14.221', '172.16.2.40'),
	'tc-pokemon-cn_qd-17': ('49.235.255.131', '172.16.2.25'),
	'tc-pokemon-cn_qd-18': ('106.54.111.167', '172.16.2.39'),
	'tc-pokemon-cn_qd-19': ('172.81.216.207', '172.16.2.46'),
	'tc-pokemon-cn_qd-20': ('49.235.199.211', '172.16.2.34'),
	'tc-pokemon-cn_qd-21': ('106.54.90.178', '172.16.2.123'),
	'tc-pokemon-cn_qd-22': ('106.54.73.161', '172.16.2.65'),
	'tc-pokemon-cn_qd-23': ('212.64.35.184', '172.16.2.104'),
	'tc-pokemon-cn_qd-24': ('49.235.231.230', '172.16.2.94'),
	'tc-pokemon-cn_qd-25': ('106.54.124.52', '172.16.2.130'),
	'tc-pokemon-cn_qd-26': ('106.54.119.14', '172.16.2.71'),
	'tc-pokemon-cn_qd-27': ('49.235.4.151', '172.16.2.90'),
	'tc-pokemon-cn_qd-28': ('49.234.212.217', '172.16.2.74'),
	'tc-pokemon-cn_qd-29': ('49.234.100.177', '172.16.2.73'),
	'tc-pokemon-cn_qd-30': ('49.234.124.150', '172.16.2.51'),
	'tc-pokemon-cn_qd-31': ('49.235.221.2', '172.16.2.57'),
	'tc-pokemon-cn_qd-32': ('172.81.248.246', '172.16.2.83'),
	'tc-pokemon-cn_qd-33': ('106.54.91.94', '172.16.2.88'),
	'tc-pokemon-cn_qd-34': ('172.81.204.163', '172.16.2.72'),
	'tc-pokemon-cn_qd-35': ('49.235.23.191', '172.16.2.118'),
	'tc-pokemon-cn_qd-36': ('49.234.92.62', '172.16.2.61'),
	'tc-pokemon-cn_qd-37': ('49.235.24.152', '172.16.2.82'),
	'tc-pokemon-cn_qd-38': ('49.235.47.172', '172.16.2.78'),
	'tc-pokemon-cn_qd-39': ('129.211.93.121', '172.16.2.53'),
	'tc-pokemon-cn_qd-40': ('49.235.245.184', '172.16.2.126'),
	'tc-pokemon-cn_qd-41': ('49.235.196.126', '172.16.2.77'),
	'tc-pokemon-cn_qd-42': ('172.81.204.21', '172.16.2.96'),
	'tc-pokemon-cn_qd-43': ('49.234.75.92', ''),
	'tc-pokemon-cn_qd-44': ('175.24.85.90', ''),
	'tc-pokemon-cn_qd-45': ('212.64.87.81', ''),
	'tc-pokemon-cn_qd-46': ('49.234.64.167', ''),
	'tc-pokemon-cn_qd-47': ('172.81.243.184', ''),
	'tc-pokemon-cn_qd-48': ('49.234.232.85', ''),
	'tc-pokemon-cn_qd-49': ('129.211.78.189', ''),
	'tc-pokemon-cn_qd-50': ('106.54.108.74', ''),
	'tc-pokemon-cn_qd-51': ('49.234.84.43', ''),
	'tc-pokemon-cn_qd-52': ('49.234.118.119', ''),
	'tc-pokemon-cn_qd-53': ('106.54.87.23', ''),
	'tc-pokemon-cn_qd-54': ('212.64.87.70', ''),
	'tc-pokemon-cn_qd-55': ('49.235.216.247', ''),
	'tc-pokemon-cn_qd-56': ('118.25.251.53', ''),
	'tc-pokemon-cn_qd-57': ('106.54.113.44', ''),
	'tc-pokemon-cn_qd-58': ('49.234.123.104', ''),
	'tc-pokemon-cn_qd-59': ('49.235.52.206', ''),
	'tc-pokemon-cn_qd-60': ('49.234.70.197', ''),
	'tc-pokemon-cn_qd-61': ('106.54.133.68', ''),
	'tc-pokemon-cn_qd-62': ('49.234.64.226', ''),
	'tc-pokemon-cn_qd-63': ('49.235.248.137', ''),
	'tc-pokemon-cn_qd-64': ('106.54.108.111', ''),
	'tc-pokemon-cn_qd-65': ('49.234.66.99', ''),
	'tc-pokemon-cn_qd-66': ('49.234.121.189', ''),
	'tc-pokemon-cn_qd-67': ('175.24.116.76', '172.16.2.58'),
	'tc-pokemon-cn_qd-68': ('175.24.113.91', '172.16.2.93'),
	'tc-pokemon-cn_qd-69': ('175.24.115.196', '172.16.2.102'),
	'tc-pokemon-cn_qd-70': ('175.24.116.90', '172.16.2.68'),
	'tc-pokemon-cn_qd-71': ('175.24.117.156', '172.16.2.120'),
	'tc-pokemon-cn_qd-72': ('175.24.118.94', '172.16.2.145'),
	'tc-pokemon-cn_qd-73': ('175.24.116.116', '172.16.2.139'),
	'tc-pokemon-cn_qd-74': ('175.24.118.53', '172.16.2.54'),
	'tc-pokemon-cn_qd-75': ('49.234.74.102', '172.16.2.115'),
	'tc-pokemon-cn_qd-76': ('175.24.119.124', '172.16.2.91'),
	'tc-pokemon-cn_qd-77': ('175.24.115.221', '172.16.2.124'),
	'tc-pokemon-cn_qd-78': ('175.24.118.119', '172.16.2.103'),
	'tc-pokemon-cn_qd-79': ('49.234.228.152', '172.16.2.153'),
	'tc-pokemon-cn_qd-80': ('49.234.210.177', '172.16.2.184'),
	'tc-pokemon-cn_qd-81': ('49.234.115.168', '172.16.2.146'),
	'tc-pokemon-cn_qd-82': ('49.234.211.184', '172.16.2.196'),
	'tc-pokemon-cn_qd-83': ('49.234.71.129', '172.16.2.243'),
	'tc-pokemon-cn_qd-84': ('49.234.238.149', '172.16.2.191'),
	'tc-pokemon-cn_qd-85': ('49.234.73.141', '172.16.2.178'),
	'tc-pokemon-cn_qd-86': ('49.234.228.97', '1172.16.2.189'),
	'tc-pokemon-cn_qd-87': ('49.234.210.96', '172.16.2.232'),
	'tc-pokemon-cn_qd-88': ('49.234.230.200', '172.16.2.168'),
	'tc-pokemon-cn_qd-89': ('49.234.78.240', '172.16.2.152'),
	'tc-pokemon-cn_qd-90': ('49.234.121.201', '172.16.2.254'),
	'tc-pokemon-cn_qd-91': ('49.234.93.210', '172.16.2.208'),
	'tc-pokemon-cn_qd-92': ('49.234.75.214', '172.16.2.161'),
	'tc-pokemon-cn_qd-93': ('49.234.79.166', '172.16.2.206'),
	'tc-pokemon-cn_qd-94': ('49.234.220.17', '172.16.2.159'),
	'tc-pokemon-cn_qd-95': ('49.234.212.103', '172.16.2.246'),
	'tc-pokemon-cn_qd-96': ('49.234.125.195', '172.16.2.182'),
	'tc-pokemon-cn_qd-97': ('49.234.97.234', '172.16.2.154'),
	'tc-pokemon-cn_qd-98': ('49.234.212.226', '172.16.2.170'),
	'tc-pokemon-cn_qd-99': ('175.24.114.143', ''),
	'tc-pokemon-cn_qd-100': ('49.234.96.130', ''),
	'tc-pokemon-cn_qd-101': ('49.235.253.238', '172.16.2.173'),
	'tc-pokemon-cn_qd-102': ('49.234.104.169', '172.16.2.241'),
	'tc-pokemon-cn_qd-103': ('49.235.233.236', '172.16.2.179'),
	'tc-pokemon-cn_qd-104': ('175.24.124.179', '172.16.2.204'),
	'tc-pokemon-cn_qd-105': ('121.4.214.139', '172.16.2.236'),
	'tc-pokemon-cn_qd-106': ('121.4.215.234', '172.16.2.230'),
	'tc-pokemon-cn_qd-107': ('121.4.195.45', '172.16.2.234'),
	'tc-pokemon-cn_qd-108': ('121.4.214.248', '172.16.2.233'),
	'tc-pokemon-cn_qd-109': ('121.4.214.62', '172.16.2.164'),
	'tc-pokemon-cn_qd-110': ('121.4.190.20', '172.16.2.218'),
	'tc-pokemon-cn_qd-111': ('121.4.217.113', '172.16.2.148'),
	'tc-pokemon-cn_qd-112': ('121.4.190.11', '172.16.2.165'),

	'tc-pokemon-cn_qd-113': ('121.4.221.214', '172.16.2.158'),
	'tc-pokemon-cn_qd-114': ('121.4.221.6', '172.16.2.247'),
	'tc-pokemon-cn_qd-115': ('121.4.238.251', '172.16.2.215'),
	'tc-pokemon-cn_qd-116': ('121.4.238.247', '172.16.2.156'),
	'tc-pokemon-cn_qd-117': ('121.4.238.112', '172.16.2.149'),
	'tc-pokemon-cn_qd-118': ('121.4.207.84', '172.16.2.207'),
	'tc-pokemon-cn_qd-119': ('121.4.238.158', '172.16.2.157'),
	'tc-pokemon-cn_qd-120': ('121.4.229.161', '172.16.2.172'),
	'tc-pokemon-cn_qd-121': ('121.4.237.44', '172.16.2.250'),
	'tc-pokemon-cn_qd-122': ('81.69.8.112', '172.16.2.199'),

	'tc-pokemon-cn_qd-123': ('1.117.206.86', '172.16.2.228'),
	'tc-pokemon-cn_qd-124': ('121.4.204.128', '172.16.2.205'),
	'tc-pokemon-cn_qd-125': ('81.69.41.155', '172.16.2.150'),
	'tc-pokemon-cn_qd-126': ('49.235.231.90', '172.16.2.203'),
	'tc-pokemon-cn_qd-127': ('49.234.214.105', '172.16.2.147'),


	'tc-pokemon-kr-01': ('119.28.154.64', '192.168.1.8'),
	'tc-pokemon-kr-02': ('119.28.162.227', '192.168.1.13'),
	'tc-pokemon-kr-03': ('150.109.82.236', '192.168.1.11'),
	'tc-pokemon-kr-04': ('119.28.156.154', '192.168.1.14'),

	'tc-pokemon-kr-05': ('119.28.233.132', '192.168.1.2'),
	'tc-pokemon-kr-06': ('150.109.84.105', '192.168.1.17'),
	'tc-pokemon-kr-07': ('150.109.84.106', '192.168.1.10'),
	'tc-pokemon-kr-08': ('119.28.235.222', '192.168.1.5'),

	'tc-pokemon-kr-09': ('119.28.160.206', '192.168.1.23'),
	'tc-pokemon-kr-10': ('119.28.234.85', '192.168.1.18'),
	'tc-pokemon-kr-11': ('119.28.160.30', '192.168.1.43'),
	'tc-pokemon-kr-12': ('119.28.162.14', '192.168.1.26'),
	'tc-pokemon-kr-13': ('150.109.236.178', '192.168.1.3'),
	'tc-pokemon-kr-14': ('150.109.235.106', '192.168.1.25'),
	'tc-pokemon-kr-15': ('119.28.160.162', '192.168.1.16'),
	'tc-pokemon-kr-16': ('150.109.238.223', '192.168.1.33'),

	'tc-pokemon-en-01': ('159.138.103.119', '192.168.1.42'),
	'tc-pokemon-en-02': ('119.8.189.205', '192.168.1.6'),
	'tc-pokemon-en-03': ('119.8.182.215', '192.168.1.26'),
	'tc-pokemon-en-04': ('119.8.161.72', '192.168.1.208'),
	'tc-pokemon-en-05': ('114.119.186.104', '192.168.1.143'),
	'tc-pokemon-en-06': ('114.119.174.127', '192.168.1.114'),
	'tc-pokemon-en-07': ('119.13.100.4', '192.168.1.147'),
	'tc-pokemon-en-08': ('119.8.188.53', '192.168.1.221'),
	'tc-pokemon-en-09': ('119.13.109.63', '192.168.1.53'),
	'tc-pokemon-en-10': ('119.8.182.161', '192.168.1.176'),
	'tc-pokemon-en-11': ('49.0.201.67', '192.168.1.137'),
	'tc-pokemon-en-12': ('94.74.82.38', '192.168.1.106'),
	'tc-pokemon-en-13': ('114.119.173.117', '192.168.1.123'),
	'tc-pokemon-en-14': ('114.119.174.64', '192.168.1.139'),
	'tc-pokemon-en-15': ('119.8.174.26', '192.168.1.30'),
	'tc-pokemon-en-16': ('110.238.106.219', '192.168.1.158'),
	'tc-pokemon-en-17': ('159.138.98.88', '192.168.1.62'),
	'tc-pokemon-en-18': ('159.138.82.133', '192.168.1.74'),
	'tc-pokemon-en-19': ('119.8.180.90', '192.168.1.206'),

	'xy-pokemon-cn-01': ('123.60.17.169', '192.168.0.4'),
	'xy-pokemon-cn-02': ('123.60.63.189', '192.168.0.149'),
	'xy-pokemon-cn-03': ('123.60.59.131', '192.168.0.192'),
	'xy-pokemon-cn-04': ('124.71.136.231', '192.168.0.43'),

	'xy-pokemon-cn-05': ('123.60.36.148', '192.168.0.163'),
	'xy-pokemon-cn-06': ('124.70.184.150', '192.168.0.173'),

	'xy-pokemon-cn-07': ('124.70.216.50', '192.168.0.132'),
	'xy-pokemon-cn-08': ('123.60.99.115', '192.168.0.144'),

	'xy-pokemon-cn-09': ('121.37.169.33', '192.168.0.69'),
	'xy-pokemon-cn-10': ('123.60.36.56', '192.168.0.86'),

	'ks-pokemon-tw-01': ('43.129.176.68', '172.19.0.9'),
	'ks-pokemon-tw-02': ('43.129.179.150', '172.19.0.2'),
	'ks-pokemon-tw-03': ('43.132.179.184', '172.19.0.12'),
	'ks-pokemon-tw-04': ('43.132.183.70', '172.19.0.7'),
	'ks-pokemon-tw-05': ('43.132.180.142', '172.19.0.3'),
	'ks-pokemon-tw-06': ('43.128.15.209', '172.19.0.11'),
	'ks-pokemon-tw-07': ('43.129.208.79', '172.19.0.16'),
	'ks-pokemon-tw-08': ('43.132.155.97', '172.19.0.17'),
	'ks-pokemon-tw-09': ('43.129.172.203', '172.19.0.49'),
	'ks-pokemon-tw-10': ('43.129.231.197', '172.19.0.13'),
	'ks-pokemon-tw-11': ('150.109.69.145', '172.19.0.37'),
	'ks-pokemon-tw-12': ('119.28.62.217', '172.19.0.45'),
}


def get_alias_servers(key):
	servers = []
	for server in MergeServs[key]:
		if 'merge' in server:
			servers += get_alias_servers(server)
		else:
			servers.append(server)
	return servers


def get_server_key(server):
	serverSplit = server.split('_')
	lang = serverSplit[0]
	if 'merge' in server:
		is_merged = True
		key = '.'.join(['gamemerge', '_'.join(serverSplit[:-2]), str(int(serverSplit[-2]))])
	else:
		is_merged = False
		key = '.'.join(['game', '_'.join(serverSplit[:-1]), str(int(serverSplit[-1]))])
	return lang, key, is_merged


def get_occupied_port(servers):
	occupied_ports = []
	for server in servers:
		lang, key, is_merged = get_server_key(server)

		if key in ServerDefs:
			defs = ServerDefs[key]
			occupied_ports.append(defs['port'])
	return occupied_ports


def get_available_ports(occupied_ports):
	# 从 10888 间隔 1000 往后加，中间有由于合服后空出来的端口就再次利用
	if occupied_ports:
		occupied_ports.sort()
		max_port = max(occupied_ports)
		new_port = 10888
		while new_port < max_port:
			if new_port not in occupied_ports:
				break
			new_port += 1000
		else:
			new_port = max_port+1000
	else:
		new_port = 10888

	if new_port > 65535:
		raise Exception('端口超上限')
		# 处理，遍历查找未使用的端口
		# for i in range(55):
		# 	new_port = 10888+i*1000
		# 	if new_port not in get_occupied_port:
		# 		break
	occupied_ports.append(new_port)
	return new_port


def run():
	# newLines = []
	for machineKey in sorted(ServerIDMap.iterkeys()):
		# if 'kr' in machineKey:
		# 	print(machineKey)
		if machineKey in Machines:
			newLines.append(machineTemp.format(
				machine=machineKey,
				public=Machines[machineKey][0],
				private=Machines[machineKey][1]
			))

		# 获取当前机器被占用的端口
		occupied_ports = get_occupied_port(ServerIDMap[machineKey])
		for serverIdx, server in enumerate(ServerIDMap[machineKey]):
			lang, key, is_merged = get_server_key(server)

			shushu = True
			if lang == 'cn':
				language = 'cn'
				nsq='CNNSQDefs'
			elif lang == 'kr':
				language = 'kr'
				nsq='KRNSQDefs'
			elif lang == 'en':
				language = 'en'
				nsq='ENNSQDefs'
			elif lang == 'xy':
				language = 'xy'
				nsq='XYNSQDefs'
				shushu = False
			elif lang == 'tw':
				language = 'tw'
				nsq='TWNSQDefs'
			else:
				raise Exception('nonsupport')
			if key in ServerDefs:
				defs = ServerDefs[key]
				openData = defs['open_date']
				formatD = {
					'year': openData.year,
					'month': openData.month,
					'day': openData.day,
					'hour': openData.hour,
				}
				openDateTemp = dateTemp1.format(**formatD)
				if openData.minute > 0:
					formatD['minute'] = openData.minute
					openDateTemp = dateTemp2.format(**formatD)
				if not is_merged:
					t = defsTemp.format(
						key=key,
						ip=defs['ip'],
						port=defs['port'],
						shushu=shushu,
						open_date=openDateTemp,
						language=language,
						nsq=nsq,
					)
				else:
					t = defsMergedTemp.format(
						key=key,
						ip=defs['ip'],
						port=defs['port'],
						shushu=shushu,
						open_date=openDateTemp,
						language=language,
						nsq=nsq,
						alias=defs['alias'],
					)
				t = t.replace('<', '{').replace('>', '}')
				newLines.append(t)
			else:
				new_port = get_available_ports(occupied_ports)
				if not is_merged:
					t = defsTemp.format(
						key=key,
						ip=Machines[machineKey][0],
						port=new_port,
						shushu=shushu,
						open_date=dateTemp3,
						language=language,
						nsq=nsq,
					)
				else:
					alias = get_alias_servers(key)
					openData = min([ServerDefs[server]['open_date'] for server in MergeServs[key]])
					formatD = {
						'year': openData.year,
						'month': openData.month,
						'day': openData.day,
						'hour': openData.hour,
					}
					openDateTemp = dateTemp1.format(**formatD)
					if openData.minute > 0:
						formatD['minute'] = openData.minute
						openDateTemp = dateTemp2.format(**formatD)

					t = defsMergedTemp.format(
						key=key,
						ip=Machines[machineKey][0],
						port=new_port,
						shushu=shushu,
						open_date=openDateTemp,
						language=language,
						nsq=nsq,
						alias=alias,
					)
				t = t.replace('<', '{').replace('>', '}')
				newLines.append(t)

	newLines.append(tail)
	# with open('game_defines.py', 'w') as fw:
	with open('../../release/game_defines.py', 'w') as fw:
		fw.writelines(newLines)


if __name__ == "__main__":
	run()

# import re
# with open('game_defines.py', 'rb') as f:
# 	lines = f.readlines()
#
# 	idx = 0
# 	while idx < len(lines):
# 		line = lines[idx]
# 		m = re.search('tc-pokemon-', line)
# 		if m:
# 			line = line.replace('\t', '').replace('\r\n', '')
# 			key = line.split(' ')[-1]
#
# 			idx += 1
# 			line = lines[idx]
# 			line = line.replace('\t', '').replace('\r\n', '')
# 			lineSplit = line.split(' ')
# 			if lineSplit[-1][-5:] == '(公)':
# 				a = lineSplit[-1][:-5]
# 			else:
# 				a = lineSplit[-1]
#
# 			idx += 1
# 			line = lines[idx]
# 			line = line.replace('\t', '').replace('\r\n', '')
# 			lineSplit = line.split(' ')
# 			if lineSplit[-1][-5:] == '(内)':
# 				b = lineSplit[-1][:-5]
# 			else:
# 				b = lineSplit[-1]
#
# 			print "'{key}': ('{a}', '{b}'),".format(key=key, a=a, b=b)
#
# 		idx += 1
