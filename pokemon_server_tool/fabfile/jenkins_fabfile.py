#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2019 TianJi Information Technology Inc.
'''

import os
import sys
import time
import random
import pprint
import argparse

from fabric import *
from env import config

from functools import wraps
from group import MyThreadingGroup

from fabfile import roledefs, ServerIDMap, CrossIDMap, get_deploy_path, get_config_csv_name, get_deploy_name

class parallel(object):
	def __init__(self, hosts=None):
		self.hosts = hosts

	def __call__(self, func):
		@wraps(func)
		def _warp():
			group = MyThreadingGroup(*self.hosts, config=config)
			result = group.execute(func)
			return result
		return _warp

def execute(f, hosts):
	return parallel(hosts=hosts)(f)()

def immediate(func):
	def wrapper(*args, **kwargs):
		return func(*args, **kwargs)
	wrapper.__name__ = 'immediate'
	return wrapper

ServerNameList = ['game_server', 'pvp_server', 'storage_server']
SVN_HOST = "192.168.1.125"
GIT_HOST = "192.168.1.250"

def _system_all_servers(c):
	ps = c.run('ps aux|grep -E "(/mnt/deploy|/usr/bin/python.*?py)"|sort -k 6 -n -r').stdout.strip()
	free = c.run('free -m').stdout.strip()
	uptime = c.run('uptime').stdout.strip()
	processor = c.run('cat /proc/cpuinfo |grep "processor"|wc -l').stdout.strip()
	svn = ''
	svn_config = ''
	with c.cd('/mnt/release'):
		svn = c.run('svn info').stdout.strip()
		svn_config = c.run('svn info %s' % get_config_csv_name(c)).stdout.strip()
	git = ''
	with c.cd('/mnt/release/src'):
		git = c.run('git log --pretty=format:"%h" -1').stdout.strip()

	svn_agent_csv = ''
	with c.cd('/mnt/release/anti_cheat/game_config'):
		svn_agent_csv = c.run('svn info').stdout.strip()
	svn_agent_model = ''
	with c.cd('/mnt/release/anti_cheat/game_scripts/application/src/battle'):
		svn_agent_model = c.run('svn info').stdout.strip()
	git_agent = ''
	with c.cd('/mnt/release/anti_cheat/game_scripts/framework'):
		git_agent = c.run('git log --pretty=format:"%h" -1').stdout.strip()
	ls_agent_csv = ''
	with c.cd('/mnt/release/anti_cheat/game_scripts/config'):
		ls_agent_csv = c.run('ls -l').stdout.strip()
	lang_agent = ''
	with c.cd('/mnt/release/anti_cheat/game_scripts'):
		lang_agent = c.run('cat anti_main.lua|grep "LOCAL_LANGUAGE ="').stdout.strip()

	# net_est = c.run('''netstat -ntal|grep ESTABLISHED|grep -E ":[12][0-9]888"|awk '{a[$4]+=1}END{for (i in a) print(i, a[i])}'|sort''').stdout.strip()
	# net_wait = c.run('''netstat -ntal|grep -E "(TIME_WAIT|CLOSING)"|grep -E ":[12][0-9]888"|awk '{a[$4]+=1}END{for (i in a) print(i, a[i])}'|sort''').stdout.strip()

	net_est = c.run('''netstat -ntal|grep ESTABLISHED|grep -E ":[0-9][0-9]888"|wc -l''').stdout.strip()
	net_wait = c.run('''netstat -ntal|grep -E "(TIME_WAIT|CLOSING)"|grep -E ":[0-9][0-9]888"|wc -l''').stdout.strip()

	return (ps, free, uptime, processor, svn, svn_config, git, svn_agent_csv, svn_agent_model, git_agent, ls_agent_csv, lang_agent, net_est, net_wait)

def system_all_servers(hosts):
	result = execute(_system_all_servers, hosts)

	infos = []
	warns = []
	times = []
	agentinfos = []
	netinfos = []

	for c in sorted(result.keys(), key=lambda x:(x.original_host.split('-')[:-1], int(x.original_host.split('-')[-1]))):
		k = c.original_host
		print '-' * 20
		print k, ':'
		ps, free, uptime, processor, svn, svn_config, git, svn_agent_csv, svn_agent_model, git_agent, ls_agent_csv, lang_agent, net_est, net_wait = result[c]
		gameservers = 0
		pvpservers = 0
		storageservers = 0
		agents = 0
		crossservers = 0

		lines = ps.split('\n')
		for line in lines:
			lst = line.split()
			big = False
			if line.find('game_server') >= 0:
				gameservers += 1
				times.append((lst[-1], 'TIME %s' % lst[-4], 'CPU %s%%' % lst[2], 'MEM %s%%' % lst[3], 'RSS %.2f GB' % (float(lst[5]) / 1024 / 1024) ))
			if line.find('-config=pvp.') >= 0 or line.find('-config=pvpmerge.') >= 0:
				pvpservers += 1
				big = int(lst[5]) > 5 * 1024 * 1024
			if line.find('-config=storage.') >= 0 or line.find('-config=storagemerge.') >= 0 or line.find('-config=crossdb.') >= 0:
				storageservers += 1
			if line.find('anti_cheat_server') >=0:
				agents += 1
				big = int(lst[5]) > 1024 * 1024
			if line.find('-config=cross.') >= 0:
				crossservers += 1
			big = big or int(lst[5]) > 8 * 1024 * 1024
			if big:
				warns.append(('MEM TOO BIG', '%.2fG' % (float(lst[5]) / 1024 / 1024), k, lst[-2], lst[-1]))

		lines = free.split('\n')
		lst = lines[2].split()
		swap = lines[3].split()
		used_mem, free_mem = 'used %.2fG' % (float(lst[2]) / 1024), 'free %.2fG' % (float(lst[3]) / 1024)
		used_swap, free_swap = 'used_swap %.2fG' % (float(swap[2]) / 1024), 'free_swap %.2fG' % (float(swap[3]) / 1024)
		if float(swap[2]) + float(swap[3]) < 0.1:
			used_swap = free_swap = None
		low = False
		low = int(lst[3]) < 30 * 1024
		if low and False:
			warns.append(('FREE MEM TOO LOW', k, used_mem, free_mem))

		lst = uptime.split()

		lstsvn = svn.split('\n')
		for svnline in lstsvn:
			if svnline.find('Revision:') >= 0:
				svnline = svnline[10:].strip()
				break

		lstsvn = svn_config.split('\n')
		for svnconfigline in lstsvn:
			if svnconfigline.find('Revision:') >= 0:
				svnconfigline = svnconfigline[10:].strip()
				break

		lstgit = git

		if agents > 0:
			lstsvn = svn_agent_csv.split('\n')
			for svnagentline1 in lstsvn:
				if svnagentline1.find('Revision:') >= 0:
					break

			lstsvn = svn_agent_model.split('\n')
			for svnagentline2 in lstsvn:
				if svnagentline2.find('Revision:') >= 0:
					break

			lstsvn = ls_agent_csv.split('\n')
			for lsagentline in lstsvn:
				if lsagentline.find('csv.lua') >= 0:
					lsagentline = ' '.join(lsagentline.split()[-4:-1])
					break

			lstsvn = lang_agent.split("'")
			langagent = lstsvn[-2]

			agentinfos.append(('agent-%s' % k, 'csv %s' % svnagentline1.strip(), 'model %s' % svnagentline2.strip(), 'csv2lua %s' % lsagentline.strip(), 'git %s' % git_agent.strip(), 'lang %s' % langagent.strip()))

		ns = len(ServerIDMap.get(k, []))
		nc = len(CrossIDMap.get(k, []))
		flag = ""
		if ns != gameservers or ns != pvpservers:
			flag = "!"
		if nc != crossservers or (ns + nc) != storageservers:
			flag = "!"

		swap_mem = ""
		if free_swap is not None:
			swap_mem = "%s %s" % (used_swap, free_swap)
		filename = get_config_csv_name(c)
		infos.append((k, '%s %s %s load %s %s %s' % (used_mem, free_mem, swap_mem, lst[-3], lst[-2], lst[-1]), '%s game %s/%d pvp %s cross %s/%d storage %s/%d release %s server %s %s %s' % (flag, gameservers, ns, pvpservers, crossservers, nc, storageservers, ns+nc, svnline, lstgit, filename, svnconfigline)))

		netinfos.append((k, 'ESTABLISHED', net_est, 'TIME_WAIT', net_wait))

	print '\n'
	print '=' * 20
	for t in times:
		print '\t'.join(t)

	print '\n'
	print '='*20
	for info in agentinfos:
		print '\t'.join(info)

	print '\n'
	print '=' * 20
	for info in infos:
		print '\t'.join(info)

	print '\n'
	print '=' * 20
	for info in netinfos:
		print '\t'.join(info)

	print '\n'
	warns.sort(key=lambda t:t[0])
	for warn in warns:
		print 'WARNING:', '\t'.join(warn)


@immediate
def test(c):
	print c.run('hostname')

if __name__ == '__main__':
	parser = argparse.ArgumentParser(description="")
	parser.add_argument('--language', type=str, default="cn", help="language")
	parser.add_argument('--hosts', type=str, default="", help="hosts")
	parser.add_argument('--roles', type=str, default="", help="roles")
	parser.add_argument('--method', type=str, default="", help="run method")
	args = parser.parse_args()

	print args

	roles = args.roles.split()
	if roles:
		hosts = []
		for v in roles:
			hosts.extend(roledefs[v])
	else:
		hosts = args.hosts.split()
	method = args.method

	mod = sys.modules[__name__]
	func = getattr(mod, method)
	if func.__name__ == 'immediate':
		execute(func, hosts)
	else:
		func(hosts)
