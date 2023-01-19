#!/usr/bin/python
# -*- coding: utf-8 -*-

import argparse
import os
import sys
import json
import re

sys.path.append(os.path.join(os.getcwd(), '../release'))
os.chdir('../release')
# os.system("svn up ssh_config")
from new_container import MongoServerIDMap
from new_container import MONGODB_MAP
from game_defines import ServerDefs

StorageMap = {}
for root, dirs, files in os.walk("./storage"):
	for file in files:
		with open(os.path.join(root, file), 'rb') as f:
			StorageMap.update(json.load(f))

# 预处理数据相关配置
MongoServerToKey = {}
with open('new_container.py', 'rb') as f:
	for line in f.readlines():
		if line.startswith('CMGO_GAME_'):
			key, conf = line.split(' = ')
			key = key.strip()
			conf = conf.strip()[1:-1]
			MongoServerToKey[conf] = key

# 导入服务相关的配置
sys.path.append(os.path.join(os.getcwd(), '../server_tool/fabfile'))
os.chdir('../server_tool/fabfile')
# os.system("svn up ssh_config")
# os.system("svn up fabfile.py")
# os.system("svn up new_game_defines.py")
from fabfile import ServerIDMap
from fabfile import CrossIDMap

Machines = {}
with open("ssh_config", 'rb') as f:
	lines = f.readlines()
	for idx, line in enumerate(lines):
		line = line.strip()
		if not line.startswith('HostName'):
			continue

		preLine = lines[idx - 1].strip()

		host = preLine.split(' ')[1]
		hostName = line.split(' ')[1]

		Machines[host] = (hostName, '')

# 解析命令参数
parser = argparse.ArgumentParser()
parser.add_argument('server', help='server num')
args = parser.parse_args()

channel, num = args.server.split('.')

# 定义变量
serverID = "%s_%02d" % (channel, int(num))
gameKey = 'game.%s' % args.server
storageKey = 'storage.%s' % args.server
mongoDBGameName = 'game_%s_%s' % (channel, num)

mergeServer = args.server
for k, v in ServerDefs.iteritems():
	if 'alias' not in v:
		continue
	if gameKey in v['alias']:
		print "!!!", gameKey, 'merge to', k
		channel, num = k.split('.')[1:]
		mergeServer = '.'.join([channel, num])
		break

serverMergeID = "%s_%02d_merge" % (channel, int(num))
gameMergeKey = 'gamemerge.%s' % mergeServer
storageMergeKey = 'storagemerge.%s' % mergeServer
mongoDBGameMergeName = 'gamemerge_%s_%s' % (channel, num)

crossDBKey = 'crossdb.%s' % args.server
mongoDBCrossName = 'cross_%s_%s' % (channel, num)
crossKey = 'cross.%s' % args.server
notFind = 'not find !!!'

# 搜索 Game 相关机器
gameMachine = notFind
for k, v in ServerIDMap.iteritems():
	if serverID in v:
		gameMachine = k
		break
gameMachineConfig = Machines.get(gameMachine, ('', ''))[0]

# 搜索 Game Merge 相关机器
gameMergeMachine = notFind
for k, v in ServerIDMap.iteritems():
	if serverMergeID in v:
		gameMergeMachine = k
		break
gameMergeMachineConfig = Machines.get(gameMergeMachine, ('', ''))[0]

# 搜索 Cross 相关机器
crossMachine = notFind
for k, v in CrossIDMap.iteritems():
	if serverID in v:
		crossMachine = k
		break
crossMachineConfig = Machines.get(crossMachine, ('', ''))[0]

# 搜索 Game DB 相关机器
mongoDBGameConfig = ''
if storageKey in StorageMap:
	mongoDBGameConfig = StorageMap[storageKey]['services'][0]['mongodb']
	mongoDBGameConfig = re.match('mongodb://.*/', mongoDBGameConfig).group()[:-1]
mongoDBGameMachine = MongoServerToKey.get(mongoDBGameConfig, notFind)

# 搜索 Game Merge DB 相关机器
mongoDBGameMergeConfig = ''
if storageMergeKey in StorageMap:
	mongoDBGameMergeConfig = StorageMap[storageMergeKey]['services'][0]['mongodb']
	mongoDBGameMergeConfig = re.match('mongodb://.*/', mongoDBGameMergeConfig).group()[:-1]
mongoDBGameMergeMachine = MongoServerToKey.get(mongoDBGameMergeConfig, notFind)

# 搜索 Cross DB 相关机器
mongoDBCrossConfig = MONGODB_MAP.get(crossDBKey, '')
mongoDBCrossMachine = MongoServerToKey.get(mongoDBCrossConfig, notFind)

# 规范打印间距
keyLen = max(len(storageKey), len(mongoDBGameName), len(mongoDBCrossName)) + 2
if gameMergeMachine != notFind:
	keyLen = max(len(storageMergeKey), len(mongoDBGameMergeName), len(mongoDBCrossName)) + 2

machineLne = max(len(gameMachine), len(mongoDBGameMachine), len(crossMachine), len(notFind)) + 2
configLen = max(len(gameMachineConfig), len(crossMachineConfig), len(mongoDBGameConfig), len(mongoDBCrossConfig), len('config')) + 6

f = '  {:%ss} {:%ss} {}' % (keyLen, machineLne)
showLen = keyLen + machineLne + configLen

print '-' * showLen
print f.format('key', 'machine', 'config')
print '-' * showLen


# 打印输出处理
def printLine(key, machine, config, isMerge=False):
	# 未找到直接跳过
	if machine == notFind:
		return
	print f.format(key, machine, config)

	keySplits = key.split('.')
	# game pvp storage 在同一个机器上
	if keySplits[0] == 'game':
		keySplits[0] = 'pvp'
		print f.format('.'.join(keySplits), machine, config)
		keySplits[0] = 'storage'
		print f.format('.'.join(keySplits), machine, config)

	# gamemerge pvp storage 在同一个机器上
	if keySplits[0] == 'gamemerge':
		keySplits[0] = 'pvpmerge'
		print f.format('.'.join(keySplits), machine, config)
		keySplits[0] = 'storagemerge'
		print f.format('.'.join(keySplits), machine, config)


print f.format('service:', '', '')
# game
printLine(gameKey, gameMachine, gameMachineConfig)

# gamemerge
printLine(gameMergeKey, gameMergeMachine, gameMergeMachineConfig, True)

# cross
printLine(crossKey, crossMachine, crossMachineConfig)

print
print f.format('mongo:', '', '')
# Game db
printLine(mongoDBGameName, mongoDBGameMachine, mongoDBGameConfig)

# Game Merge db
printLine(mongoDBGameMergeName, mongoDBGameMergeMachine, mongoDBGameMergeConfig)

# Cross db
printLine(mongoDBCrossName, mongoDBCrossMachine, mongoDBCrossConfig)

print '-' * showLen
