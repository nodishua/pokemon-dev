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

initLog('auto_open')
from framework.log import logger

LOGPATH = '/mnt/log'
SVN_HOST = "192.168.1.125"
GIT_HOST = "192.168.1.250"
ROLE_MAX_TO_OPEN = 5000
ROLE_MAX_TO_OPEN_MAP = {
	'game.cn_qd.100': 4000,
	'game.cn_qd.101': 4000,
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

def kill3690():
	cmd = "lsof -i:3690|grep sshd|awk '{print $2}'"
	p = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
	out, err = p.communicate()
	if len(out.split()) > 1:
		out = out.split()[0]
	if len(out) > 0:
		os.system('kill -9 %d' % int(out))

def svn_commit(c, key):
	def _svn_commit(c):
		with c.forward_local(local_port=3690, remote_host=SVN_HOST, remote_port=3690):
			ret = os.system('svn commit -m "[misc] auto open server %s commit." game_defines.py login/conf/game.json' % key)
		return ret

	with cd('/mnt/release'):
		if os.system("lsof -i:3690") == 0:
			try:
				ret = os.system('svn commit -m "[misc] auto open server %s commit." game_defines.py login/conf/game.json' % key)
			except:
				logger.exception('svn commit error')
				kill3690()
				ret = _svn_commit(c)
		else:
			ret = _svn_commit(c)
	return ret

def svn_up(c):
	def _svn_up(c):
		with c.forward_local(local_port=3690, remote_host=SVN_HOST, remote_port=3690):
			os.system('svn cleanup')
			ret = os.system('svn up --username test --password 123456')
		return ret

	with cd('/mnt/release'):
		if os.system("lsof -i:3690") == 0:
			try:
				os.system('svn cleanup')
				ret = os.system('svn up --username test --password 123456')
			except:
				logger.exception('svn up error')
				kill3690()
				ret = _svn_up(c)
		else:
			ret = _svn_up(c)
	return ret

def remote_svn_up(host):
	def _svn_up(c):
		with c.forward_remote(local_port=3690, local_host='localhost', remote_port=3690):
			c.run('svn up --username test --password 123456')

	conn = MyConnection(host, config=config)
	with conn.cd('/mnt/release'):
		try:
			_svn_up(conn)
		except Exception, e:
			if str(e).find('TCP forwarding request denied') >= 0:
				ret = conn.run("lsof -i:3690|grep sshd|awk '{print $2}'").stdout
				if len(ret.split()) > 1:
					ret = ret.split()[0]
				if len(ret) > 0:
					conn.run('kill -9 %d' % int(ret))
				_svn_up(conn)
			else:
				raise

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
		c = MyConnection('ops.tjgame.com', user='root', connect_kwargs={'password': '123456'})

		count = 0
		while True:
			now = nowdatetime_t()
			date = r"\\\t\t'open_date': datetime(%d, %d, %d, %d, %d)," % (now.year, now.month, now.day, now.hour, now.minute)
			try:
				os.system('svn revert game_defines.py login/conf/game.json')
				ret = svn_up(c)
				if ret != 0:
					raise Exception('svn up error')
				ret = os.system('sed -i "%dc%s" game_defines.py'% (row+5, date))
				if ret != 0:
					raise Exception('sed open_date error')

				# 2. 生成 game.json
				ret = os.system('python game_defines.py')
				if ret != 0:
					raise Exception('python game_defines.py error')

				# 3. commit
				ret = svn_commit(c, key)
				if ret != 0:
					raise Exception('commit error')

				break
			except Exception as e:
				logger.warning('%s', e)
				time.sleep(2)
				count += 1
				ding('准备开服', '1. 开服异常, 重试第 %d 次' % count)

	domain = key.split('.')
	name = '%s_%02d' % (domain[1], int(domain[2]))
	# 4. fab 对应机器 svn up, restart game
	count = 0
	while True:
		try:
			host = Serv2Machine[name]
			if os.system("lsof -i:3690") == 0:
				remote_svn_up(host)
				remote_restart_game(host, name)
			else:
				with c.forward_local(local_port=3690, remote_host=SVN_HOST, remote_port=3690):
					remote_svn_up(host)
					remote_restart_game(host, name)
			break
		except Exception as e:
			logger.warning('%s', e)
			time.sleep(2)
			ding('准备开服', '2. 开服异常, 重试第 %d 次' % count)

	ding('准备开服', '2. 新服 %s 启动完成' % key)
	# 5. fab login release svn up
	if os.system("lsof -i:3690") == 0:
		remote_svn_up('tc-pokemon-cn-login')
		remote_restart_payment('tc-pokemon-cn-login')
	else:
		with c.forward_local(local_port=3690, remote_host=SVN_HOST, remote_port=3690):
			remote_svn_up('tc-pokemon-cn-login')
			remote_restart_payment('tc-pokemon-cn-login')
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
