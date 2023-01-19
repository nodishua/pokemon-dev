#!/usr/bin/python
# -*- coding: utf-8 -*-

"""
## 口袋合服配置生成脚本

- 更新 release 和 fabfile 目录
- 手动配置合服区和合服后的 key value 配置, 见代码中的 MERGE 变量
- 清空代码中的 MERGE_MACHINE 变量，然后运行脚本 python config_merge_server.py
- 根据输出中合服涉及到的机器，手动配置合服后的区服所在机器，将配置填入 MERGE_MACHINE 中
- 最后再执行一遍脚本 python config_merge_server.py，生成最终需要的所有配置
"""

import os
import sys

MERGE = {
	'gamemerge.cn_qd.98': ['game.cn_qd.480', 'game.cn_qd.481', 'game.cn_qd.482', 'game.cn_qd.483', 'game.cn_qd.484'],
	'gamemerge.cn_qd.99': ['game.cn_qd.485', 'game.cn_qd.486', 'game.cn_qd.487', 'game.cn_qd.488', 'game.cn_qd.489'],
	'gamemerge.cn_qd.100': ['game.cn_qd.490', 'game.cn_qd.491', 'game.cn_qd.492', 'game.cn_qd.493', 'game.cn_qd.494'],
	'gamemerge.cn_qd.101': ['game.cn_qd.495', 'game.cn_qd.496', 'game.cn_qd.497', 'game.cn_qd.498', 'game.cn_qd.499'],
	'gamemerge.cn_qd.102': ['game.cn_qd.500', 'game.cn_qd.501', 'game.cn_qd.502', 'game.cn_qd.503', 'game.cn_qd.504'],
	'gamemerge.cn_qd.103': ['game.cn_qd.505', 'game.cn_qd.506', 'game.cn_qd.507', 'game.cn_qd.508', 'game.cn_qd.509'],
	'gamemerge.cn_qd.104': ['game.cn_qd.510', 'game.cn_qd.511', 'game.cn_qd.512', 'game.cn_qd.513', 'game.cn_qd.514'],
	'gamemerge.cn_qd.105': ['game.cn_qd.515', 'game.cn_qd.516', 'game.cn_qd.517', 'game.cn_qd.518', 'game.cn_qd.519'],
	'gamemerge.cn_qd.106': ['game.cn_qd.520', 'game.cn_qd.521', 'game.cn_qd.522', 'game.cn_qd.523', 'game.cn_qd.524'],
	'gamemerge.cn_qd.107': ['game.cn_qd.525', 'game.cn_qd.526', 'game.cn_qd.527', 'game.cn_qd.528', 'game.cn_qd.529'],
}

MERGE_MACHINE = {
	'tc-pokemon-cn_qd-57': ['cn_qd_98_merge'],
	'tc-pokemon-cn_qd-58': ['cn_qd_99_merge'],
	'tc-pokemon-cn_qd-59': ['cn_qd_100_merge'],
	'tc-pokemon-cn_qd-60': ['cn_qd_101_merge'],
	'tc-pokemon-cn_qd-61': ['cn_qd_102_merge'],
	'tc-pokemon-cn_qd-62': ['cn_qd_103_merge'],
	'tc-pokemon-cn_qd-63': ['cn_qd_104_merge'],
	'tc-pokemon-cn_qd-64': ['cn_qd_105_merge'],
	'tc-pokemon-cn_qd-65': ['cn_qd_106_merge'],
	'tc-pokemon-cn_qd-66': ['cn_qd_107_merge'],
}


def sortByKey():
	keyNums = []
	for k in MERGE:
		_, _, n = k.split('.')
		keyNums.append((k, int(n)))

	keyNums.sort(key=lambda x: int(x[0].split('.')[2]))
	data = []
	for key, _ in keyNums:
		data.append(MERGE[key])

	return data


def make_merge_config():
	data = sortByKey()

	ret = []
	for v in data:
		for vv in v:
			_, channel, num = vv.split('.')
			ret.append('%s_%02d' % (channel, int(num)))

	sys.path.insert(0, os.path.join(os.getcwd(), "./fabfile/"))
	os.chdir("./fabfile")
	from fabfile import ServerIDMap
	os.chdir("../")

	mergeMachine = {}
	for k, v in ServerIDMap.iteritems():
		for serverKey in v:
			if serverKey in ret:
				mergeMachine.setdefault(k, [])
				mergeMachine[k].append(serverKey)

	print

	print '涉及到的机器，fabfile.py 操作关服时将改配置复制到 other 中，对指定机器进行操作'
	for k in sorted(mergeMachine.keys()):
		print "'%s'," % k

	print

	print '涉及到的机器对应的区服'
	for k in sorted(mergeMachine.keys()):
		print "'%s': %s," % (k, mergeMachine[k])

	sys.path.insert(0, os.path.join(os.getcwd(), "../release/"))

	newMachineServers = {}

	for k in sorted(mergeMachine.keys()):
		orgServers = ServerIDMap[k]
		delServers = mergeMachine[k]

		newServers = []
		newMachineServers.setdefault(k, [])

		# print k, orgServers
		for v in orgServers:
			if v not in delServers:
				newMachineServers[k].append(v)

	for k, v in MERGE_MACHINE.iteritems():
		newMachineServers[k].extend(v)

	print
	print '最终合服后 fabfile 区服配置（注意：MERGE_MACHINE 手动配置后再运行下脚本，将新加的合服区放入指定机器）'
	for k in sorted(newMachineServers.keys()):
		v = newMachineServers[k]
		print "'%s': %s," % (k, v)

	print


def statistic_mongodb():
	MongoServerToKey = {}
	with open('../release/new_container.py', 'rb') as f:
		for line in f.readlines():
			if line.startswith('CMGO_GAME_'):
				key, conf = line.split(' = ')
				key = key.strip()
				conf = conf.strip()[1:-1]
				MongoServerToKey[conf] = key

	sys.path.insert(0, os.path.join(os.getcwd(), "./fabfile/"))
	os.chdir("./fabfile")
	from fabfile import ServerIDMap
	os.chdir("../")
	serverKeyIndexMap = {}
	for v in ServerIDMap.itervalues():
		for vv in v:
			serverKeyIndexMap[vv] = True

	import json
	import re

	storageMap = {}
	for root, dirs, files in os.walk('../release/storage'):
		for file in files:
			with open(os.path.join(root, file), 'rb') as f:
				storageMap.update(json.load(f))

	mongoUseMap = {}
	for k, v in storageMap.iteritems():
		key, channel, num = k.split('.')
		if not key.startswith('storage') or channel in ["dev", 'shenhe', 'xy', 'trial', 'beta']:
			continue
		fabfileKey = "%s_%02d" % (channel, int(num))
		if key.endswith('merge'):
			fabfileKey += "_merge"

		mongoD = re.match(r"mongodb://.*/game", v['services'][0]['mongodb']).group()[:-5]

		if mongoD not in MongoServerToKey:
			print 'mongo not in', fabfileKey, mongoD
			continue

		if fabfileKey not in serverKeyIndexMap:
			print 'key not in', fabfileKey, mongoD
			continue

		mongoKey = MongoServerToKey[mongoD]
		mongoUseMap.setdefault(mongoKey, [])
		mongoUseMap[mongoKey].append(fabfileKey.encode('utf-8'))

	fmt = '{:15s} {} {}'
	print fmt.format('mongo', 'use', 'info')
	print '-' * 20
	for k in sorted(mongoUseMap.keys()):
		# print k, mongoUseMap[k]
		print fmt.format(k, len(mongoUseMap[k]), mongoUseMap[k])


def make_csv_row():
	print '配表 server/merge.csv 中需要的源服务器配置，配表中其他配置项手动补全'
	for k in sorted(MERGE.iterkeys(), key=lambda x: int(x.split('.')[2])):
		print '<%s>' % ';'.join(MERGE[k])
	print


def make_maintain_servers():
	data = sortByKey()

	print 'login 机器 maintain.json 中 maintain_servers 需要配置的指定维护区服配置'
	for idx, v in enumerate(data):
		if idx == len(data) - 1:
			print '%s' % ', '.join(["\"%s\"" % vv for vv in v])
		else:
			print '%s,' % ', '.join(["\"%s\"" % vv for vv in v])
	print


def make_some_server_close():
	data = sortByKey()

	print 'fabfile.py 中关闭部分补分区服时需要的区服配置'
	for v in data:
		tmp = []
		for vv in v:
			_, channel, num = vv.split('.')
			tmp.append('%s_%02d' % (channel, int(num)))

		print '%s,' % ', '.join(["'%s'" % vvv for vvv in tmp])


if __name__ == "__main__":
	make_merge_config()
	make_csv_row()
	make_maintain_servers()
	make_some_server_close()

	# statistic_mongodb()
