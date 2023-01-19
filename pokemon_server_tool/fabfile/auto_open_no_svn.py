#!/usr/bin/python
# -*- coding: utf-8 -*-

import os
import sys
sys.path.append('../')
sys.path.append('../../release/')
import subprocess
import time
import datetime
import json

from contextlib import contextmanager
from fabric import *
from env import config
from framework.log import initLog
from framework import nowtime_t, nowdatetime_t
from tornado.ioloop import IOLoop, PeriodicCallback
from tornado.gen import coroutine, Return, multi_future, sleep
from tornado.curl_httpclient import CurlAsyncHTTPClient

from group import MyConnection

initLog('auto_open_no_svn')
from framework.log import logger

LOGPATH = '/mnt/log'
SVN_HOST = "192.168.1.125"
GIT_HOST = "192.168.1.250"
ROLE_MAX_TO_OPEN = 5000
ROLE_MAX_TO_OPEN_MAP = {
	'game.cn_qd.202': 3000,
}

def get_max_role_to_open():
	# now = datetime.datetime.now()
	# if now.hour >= 12 and now.hour< 19:
	# 	return 5000
	return ROLE_MAX_TO_OPEN


DINGURL = "https://oapi.dingtalk.com/robot/send?access_token=123123"
DINGHEADERS = {
	'Content-Type': 'application/json; charset=UTF-8'
}

# cat cn_qd_24_game_server/2020-03-27.log|grep "new role"|wc -l
from fabfile import ServerIDMap

Serv2Machine = {}
for machine, v in ServerIDMap.iteritems():
	for serv in v:
		Serv2Machine[serv] = machine

@contextmanager
def cd(path):
		old = os.getcwd()
		os.chdir(path)
		yield
		os.chdir(old)

# game.cn_qd.1
def server_new_role_count(key):
	_, tag, area = key.split('.')
	cmd = 'cat /mnt/log/%s_game_server/*.log|grep "new role"|wc -l' % ('_'.join([tag, area]))
	p = subprocess.Popen(cmd, shell=True, cwd=LOGPATH, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
	p.wait()
	count , err = p.communicate()
	count = int(count)
	return count

def ding(title, msg):
	# content = title + "\n\n" + msg + "\n"
	content = msg + "\n"
	logger.info('%s', content)
	ding = {
		"msgtype": "text",
		"text": {
			"title": "自动开服",
			"content": content,
		},
	}
	try:
		def callback(response):
			if response.code != 200:
				logger.warning('%s', response.body)

		httpClient = CurlAsyncHTTPClient()
		httpClient.fetch(DINGURL, method="POST", headers=DINGHEADERS, body=json.dumps(ding), callback=callback)
	except:
		logger.warning('ding error')

def scp_file(host):
	s = "scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -F /mnt/server_tool/fabfile/ssh_config /mnt/release/{file} root@{host}:/mnt/release/{file}"
	cmd = s.format(host=host, file="game_defines.py")
	logger.info("%s", cmd)
	ret = os.system(cmd)
	if ret != 0:
		raise Exception("scp %s error" % host)
	cmd = s.format(host=host, file="login/conf/game.json")
	logger.info("%s", cmd)
	ret = os.system(cmd)
	if ret != 0:
		raise Exception("scp %s error" % host)

def remote_restart_game(host, name):
	c = MyConnection(host, config=config)
	with c.cd('/mnt/deploy_cn_qd'):
		dpy = '%s_game_server' % name
		ret = c.run('supervisorctl status %s' % dpy).stdout.strip()
		if ret.find('RUNNING') < 0:
			c.run('supervisorctl start %s' % dpy)
		else:
			c.run('supervisorctl restart %s' % dpy)
		with c.cd('childlog'):
			i = 0
			while True:
				ret = c.run('cat {dpy}/`date "+%Y-%m-%d"`.log|grep "Start OK"'.format(dpy=dpy)).stdout.strip()
				if ret.find('Start OK') > 0 or ret.find('start ok') > 0:
					break
				logger.info('%s, start waiting %d', dpy, i)
				time.sleep(1)
				i += 1

def remote_restart_payment(host):
	c = MyConnection(host, config=config)
	with c.cd('/mnt/deploy_cn'):
		c.run('supervisorctl restart payment_server')

# key: game.cn_qd.1
def open_new_server(key, rolecount):
	logger.info('open_new_server %s', key)
	ding('准备开服', '1. 旧服角色已达 %d, 新服 %s 准备' % (rolecount, key))
	# 1. 修改 game_defines
	kk = r"\.".join(key.split('.'))
	cmd = 'grep -n "%s" game_defines.py'% kk
	p = subprocess.Popen(cmd, cwd='/mnt/release', shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
	out, err = p.communicate()
	row = int(out.split(':')[0].strip())

	with cd("/mnt/release"):
		now = nowdatetime_t()
		date = r"\\\t\t'open_date': datetime(%d, %d, %d, %d, %d)," % (now.year, now.month, now.day, now.hour, now.minute)
		ret = os.system('sed -i "%dc%s" game_defines.py'% (row+5, date))
		if ret != 0:
			raise Exception('sed open_date error')

		# 2. 生成 game.json
		ret = os.system('python game_defines.py')
		if ret != 0:
			raise Exception('python game_defines.py error')

		# backup game_defines.py
		os.system('cp game_defins.py game_defines_backup/game_defins_%s.py' % key)

		# 3. commit

	domain = key.split('.')
	name = '%s_%02d' % (domain[1], int(domain[2]))
	# 4. fab 对应机器 svn up, restart game
	host = Serv2Machine[name]
	scp_file(host)
	remote_restart_game(host, name)

	ding('准备开服', '2. 新服 %s 启动完成' % key)
	# 5. fab login release svn up
	host = 'tc-pokemon-cn-login'
	scp_file(host)
	ding('准备开服', '3. 新服 %s 开放' % key)

# prefix game.cn_qd
@coroutine
def auto_open():
	prefix = 'game.cn_qd'
	import game_defines
	_defines = reload(game_defines)
	ServerDefs = _defines.ServerDefs

	now = nowdatetime_t()
	current = None
	nextserv = None
	for i in xrange(1, 9999):
		key = '%s.%d' % (prefix, i)
		if key not in ServerDefs:
			break
		conf = ServerDefs[key]
		if now > conf['open_date']:
			current = key
			continue
		else:
			nextserv = key
			break
	logger.info('current %s, nextserv %s', current, nextserv)

	if current and nextserv:
		count = server_new_role_count(current)
		maxc = get_max_role_to_open()
		logger.info('current %s new role count %d, max %d' , current, count, maxc)
		now = datetime.datetime.now()
		if now.hour >= 1 and now.hour < 5:
			raise Return(None)
		# if count > ROLE_MAX_TO_OPEN_MAP.get(current, ROLE_MAX_TO_OPEN):
		if count > maxc:
			open_new_server(nextserv, count) # 开新服

if __name__ == "__main__":
	auto_open()
	PeriodicCallback(auto_open, 30 * 1000.).start()
	IOLoop.current().start()
