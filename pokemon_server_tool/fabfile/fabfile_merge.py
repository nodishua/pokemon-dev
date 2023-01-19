#!/usr/bin/python
# -*- coding: utf-8 -*-

import os
import sys
import time
import random
import pprint

from fabric import *
from env import config

from functools import wraps
from group import MyThreadingGroup

roledefs = {
	'cngame': [
		'tc-pokemon-cn_qd-23',
		'tc-pokemon-cn_qd-24',
		'tc-pokemon-cn_qd-25',
		'tc-pokemon-cn_qd-26',
		'tc-pokemon-cn_qd-27',
		'tc-pokemon-cn_qd-28',
		'tc-pokemon-cn_qd-29',
		'tc-pokemon-cn_qd-30',
		'tc-pokemon-cn_qd-31',
		'tc-pokemon-cn_qd-32',
	],
	'allgm': [
		# 'tc-pokemon-cn-gm',
		# 'ks-pokemon-tw-gm',
		# 'ks-pokemon-kr-gm',
	],
	'krgame': [
		# 'tc-pokemon-kr-05',
		# 'tc-pokemon-kr-06',
		# 'tc-pokemon-kr-07',
		# 'tc-pokemon-kr-08',
		# 'tc-pokemon-kr-09',
		# 'tc-pokemon-kr-10',
		# 'tc-pokemon-kr-11',
		# 'tc-pokemon-kr-12',
	],
	'twgame': [
		'ks-pokemon-tw-01',
		'ks-pokemon-tw-02',
	]
}

roledefs['allgame'] = []
# roledefs['allgame'] += roledefs['cngame']
# roledefs['allgame'] += roledefs['qdgame']
# roledefs['allgame'] += roledefs['krgame']
# roledefs['allgame'] += roledefs['engame']
roledefs['allgame'] += roledefs['twgame']


ServerNameList = ['game_server', 'pvp_server', 'storage_server']

# 这里配置此次合服的 服务器名: [合服列表]
ServerIDMap = {
	# 'tc-pokemon-cn-01': ['cn_qd_09_merge', 'cn_qd_999_merge'],  # test
	# 'tc-pokemon-cn_qd-23': ['cn_qd_21_merge'],
	# 'tc-pokemon-cn_qd-24': ['cn_qd_22_merge'],
	# 'tc-pokemon-cn_qd-25': ['cn_qd_23_merge'],
	# 'tc-pokemon-cn_qd-26': ['cn_qd_24_merge'],
	# 'tc-pokemon-cn_qd-27': ['cn_qd_25_merge'],
	# 'tc-pokemon-cn_qd-28': ['cn_qd_26_merge'],
	# 'tc-pokemon-cn_qd-29': ['cn_qd_27_merge'],
	# 'tc-pokemon-cn_qd-30': ['cn_qd_28_merge'],
	# 'tc-pokemon-cn_qd-31': ['cn_qd_29_merge'],
	# 'tc-pokemon-cn_qd-32': ['cn_qd_30_merge'],

	'ks-pokemon-tw-01': ['tw_01_merge', 'tw_03_merge', 'tw_05_merge'],
	'ks-pokemon-tw-02': ['tw_02_merge', 'tw_04_merge'],
}

SVN_HOST = "192.168.1.125"
GIT_HOST = "192.168.1.250"

# cn_qd_07_storagemerge_server
# storagemerge.cn_qd.7


def get_deploy_path(c):
	ret = c.run('ls -d /mnt/deploy*').stdout.strip()
	if len(str(ret).split()) != 1:
		abort("deploy dictionary can not be determinately!")
	return ret


def get_deploy_name(x, s):
	# (cn_qd_01_merge, game_server) -> cn_01_gamemerge_server
	if x.find('merge') >= 0:
		v = x.split('_')
		x = '_'.join(v[:-1])
		v = s.split('_')
		return '%s_%smerge_%s' % (x, v[0], v[1])
	return '%s_%s' % (x, s)


class parallel(object):
	def __init__(self, hosts=None, host=None):
		self.hosts = hosts
		if host:
			self.hosts = [host]

	def __call__(self, func):
		@wraps(func)
		def _warp():
			group = MyThreadingGroup(*self.hosts, config=config)
			result = group.execute(func)
			return result

		return _warp


# 更新merge.ini配置
@parallel(hosts=roledefs['allgame'])
def update_merge_supervisor(c):
	with c.cd(get_deploy_path(c)):
		if c.original_host not in ServerIDMap:
			return
		serviceNames = []
		serverIDs = ServerIDMap[c.original_host]
		for serverID in serverIDs:
			if 'merge' not in serverID:
				continue
			names = serverID.split('_')
			prefix = '_'.join(names[:-1])
			# suffix = '.'.join(['_'.join(names[:-2]), str(int(names[-2]))])

			storageName = '%s_storagemerge_server' % prefix
			pvpName = '%s_pvpmerge_server' % prefix
			gameName = '%s_gamemerge_server' % prefix

			serviceNames += [storageName, pvpName, gameName]
		with c.cd('supervisord.dir'):
			with c.forward_remote(local_port=3690, local_host=SVN_HOST, remote_port=3690):
				for serviceName in serviceNames:
					c.run('svn up %s.ini --username test --password 123456' % serviceName)

		c.run('supervisorctl update %s' % str(' '.join(serviceNames)))


# 更新defines文件
@parallel(hosts=roledefs['allgame'])
def server_define_up(c):
	with c.cd('/mnt/release'):
		try:
			with c.forward_remote(local_port=3690, local_host=SVN_HOST, remote_port=3690):
				print c.original_host
				with c.cd('./storage'):
					c.run('svn cleanup')
					c.run('svn up --username test --password 123456')
				with c.cd('./pvp'):
					c.run('svn cleanup')
					c.run('svn up --username test --password 123456')

				c.run('svn up game_defines.py --username test --password 123456')
				c.run('svn up login/conf/game.py --username test --password 123456')

		except Exception, e:
			if str(e).find('TCP forwarding request denied') >= 0:
				ret = c.run('lsof -i:3690|grep sshd|awk \'{print $2}\'').stdout
				if len(ret.split()) > 1:
					ret = ret.split()[0]
				if len(ret) > 0:
					c.run('kill -9 %d' % int(ret))


# 关闭服务
@parallel(hosts=roledefs['allgame'])
def close_merge_servers(c):
	with c.cd(get_deploy_path(c)):
		if c.original_host not in ServerIDMap:
			return
		serverIDs = ServerIDMap[c.original_host]
		for s in ServerNameList:
			deployNameL = [get_deploy_name(x, s) for x in serverIDs]
			print deployNameL
			for dpy in deployNameL:
				c.run('supervisorctl stop %s' % dpy)

			for dpy in deployNameL:
				i = 0
				while True:
					ret = c.run('supervisorctl status %s' % dpy).stdout.strip()
					if ret.find('STOPPED') > 0 or ret.find('EXITED') > 0:
						break
					print dpy, 'stop waiting', i
					time.sleep(random.randint(1, 5))
					i += 1
			time.sleep(random.randint(1, 5))


def list_split(items, n):
	return [items[i:i + n] for i in range(0, len(items), n)]


# 启动服务
@parallel(hosts=roledefs['allgame'])
def start_merge_servers(c):
	with c.cd(get_deploy_path(c)):
		if c.original_host not in ServerIDMap:
			return
		serverIDs = ServerIDMap[c.original_host]
		steps = list_split(serverIDs, 4)
		for serverIDs in steps:
			for s in reversed(ServerNameList):
				waitIDs = []
				for x in serverIDs:
					dpy = get_deploy_name(x, s)
					ret = c.run('supervisorctl status %s' % dpy).stdout.strip()
					if ret.find('RUNNING') < 0:
						waitIDs.append(x)
						c.run('supervisorctl start %s' % dpy)
						time.sleep(random.randint(1, 5))

				for x in waitIDs:
					dpy = get_deploy_name(x, s)
					with c.cd('childlog'):
						i = 0
						while True:
							if s == 'game_server':
								ret = c.run('cat {dpy}/`date "+%Y-%m-%d"`.log|grep -E "(Start OK|End of file)"'.format(
									dpy=dpy)).stdout.strip()
							else:
								ret = c.run('cat {dpy}*.log|grep "start ok"|grep "`date "+%y%m%d"`"'.format(
									dpy=dpy)).stdout.strip()
							if ret.find('Start OK') > 0 or ret.find('start ok') > 0:
								break
							if ret.find('End of file') > 0:
								with c.cd(get_deploy_path(c)):
									if c.run('supervisorctl status %s' % dpy).stdout.strip().find('RUNNING') < 0:
										c.run('supervisorctl start %s' % dpy)
							print dpy, 'start waiting', i
							time.sleep(random.randint(1, 5))
							i += 1
			# time.sleep(random.randint(1, 5))


if __name__ == '__main__':
	method = sys.argv[1]
	print 'run', method
	mod = sys.modules[__name__]
	func = getattr(mod, method)
	func()
