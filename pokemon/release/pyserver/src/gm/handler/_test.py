#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2017 TianJi Information Technology Inc.

Test Handlers
'''
from __future__ import absolute_import

import os
import re
import sys
import json
import copy
import time
import datetime
import subprocess
import ast
from collections import defaultdict, namedtuple, OrderedDict
import msgpackrpc

import tornado.ioloop
import tornado.websocket
from tornado.gen import coroutine, Return, sleep
from tornado.web import HTTPError

from framework import int2date, int2time
from framework.log import logger

from .base import AuthedHandler
from gm.util import datetime2str, str2datetime

# 内网固定配置
servconf = namedtuple('servconf', ['name', 'source', 'deploy', 'servers', 'config_name'])
TestServerConf = {
	'pokemon01': servconf('1Area', '/home/pokemon_01/pokemon_server', '/home/pokemon_01/deploy', ['game_server',], 'game.dev.1',),
	'pokemon02': servconf('2Area', '/home/pokemon_02/server', '/home/pokemon_02/deploy', ['game_server',], 'game.dev.2',),
	'pokemon03': servconf('3Area', '/home/pokemon_03/server', '/home/pokemon_03/deploy', ['game_server',], 'game.dev.3',),
	'pokemon04': servconf('4Area', '/home/pokemon_04/server', '/home/pokemon_04/deploy', ['game_server',], 'game.dev.4',),
	'pokemon05': servconf('5Area', '/home/pokemon_05/server', '/home/pokemon_05/deploy', ['game_server',], 'game.dev.5',),
	'pokemon06': servconf('6Area', '/home/pokemon_06/server', '/home/pokemon_06/deploy', ['game_server',], 'game.dev.6',),
}
TestServerConf = OrderedDict(sorted(TestServerConf.items(), key=lambda t: t[0]))


ANTICHEAT01 = '/home/shuma_01/server/anti-cheat'

def getServerOpenDate():
	oldPath = copy.deepcopy(sys.path)
	ret = []
	for cfg in TestServerConf:
		path = os.path.join(TestServerConf[cfg].source, 'src/game')
		sys.path = oldPath
		# sys.path.append(os.path.join(TestServerConf[cfg].source, 'src')) # Prevent other modules in the DEFINES module
		sys.path.insert(0, path)
		sys.modules.pop('defines', None)
		mod = __import__('defines')
		try:
			defines = mod.ServerDefs[TestServerConf[cfg].config_name]
			ret.append(defines['open_date'])
		except Exception as e:
			logger.warning(str(e))
	sys.path = oldPath
	return ret

def getServerLanguages():
	ret = []
	for cfg in TestServerConf:
		cmd = 'cat dev_patch.py | grep "framework.__language__"'
		p = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, cwd=TestServerConf[cfg].source)
		out, err = p.communicate()
		language = eval(out.split("=")[1].strip())
		ret.append(language)
	return ret

def getServerIDandNames():
	ret = []
	for name in TestServerConf:
		ret.append((name, TestServerConf[name].name))
	return ret

def getServerStatus():
	ret = []
	for cfg in TestServerConf:
		cmd = "supervisorctl status| grep " + TestServerConf[cfg].servers[0]
		cwd = TestServerConf[cfg].deploy
		p = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, cwd=cwd)
		out, err = p.communicate()
		if out == "":
			ret.append('STOPPED')
		else:
			ret.append(out.split()[1])
	return ret

def getServerTime():
	cmd = 'date +"%Y-%m-%d %H:%M:%S"'
	p = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
	out, err = p.communicate()
	return out

def saveServerDefines(dates):
	# Modify the game defines file
	for i in dates:
		cfg = TestServerConf[i]
		dts = dates[i].get('openDate', None)
		if dts:
			dt = str2datetime(dts)

			path = os.path.join(cfg.source, 'src/game/defines.py')
			with open(path, 'rb') as fp:
				data = fp.read()

			pat = r"'%s': \{.*?'open_date': datetime\((?P<datetime>[^)]*)\),.*?\}" % cfg.config_name
			match = re.search(pat, data, re.DOTALL)
			if match:
				result = match.group("datetime")
				if result:
					s, e = match.start("datetime"), match.end("datetime")
					# print s, e, data[s:e]
					data = data[:s] + "%d, %d, %d, %d" % (dt.year, dt.month, dt.day, dt.hour) + data[e:]
					# print data[:e+10]
					with open(path, 'wb') as fp:
						fp.write(data)
				else:
					raise HTTPError(404, reason='no datetime config be found')

def saveServerLanguages(languages):
	# Modify the dev_patch.py file
	for i in languages:
		cfg = TestServerConf[i]
		lang = languages[i].get('language', None)
		if lang:
			path = os.path.join(cfg.source, 'dev_patch.py')
			cmd = ''' sed -i "s/framework.__language__ = '.*'/framework.__language__ = '%s'/g" %s ''' % (lang, path)
			os.system(cmd)


# server configuration
class TestServerHandler(AuthedHandler):
	url = r'/test_server'

	@coroutine
	def get(self):
		serverTime = getServerTime()
		self.render_page('_test_server.html', internal_server_time=serverTime)

	@coroutine
	def post(self):
		time = self.get_json_data()["time"]
		dateTime = datetime.datetime.strptime(time, "%Y-%m-%d %H:%M:%S")
		self.setServTime(dateTime)
		os.system('cd /home/pokemon_02/deploy && supervisorctl restart payment_server')
		self.write_json({"ret": True})

	def setServTime(self, dt):
		cmd = 'date -s "%d/%d/%d %d:%d:%d"' % (dt.year, dt.month, dt.day, dt.hour, dt.minute, dt.second)
		p = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
		out, err = p.communicate()
		return out

class ServTableHandler(AuthedHandler):
	url = "/test_server/t"

	@coroutine
	def get(self):
		IDandNames = getServerIDandNames()
		devOpenDates = getServerOpenDate()
		devLanguages = getServerLanguages()
		devStatus = getServerStatus()
		devInfo = []
		for i in xrange(len(IDandNames)):
			try:
				devInfo.append({
						"id": IDandNames[i][0],
						"dev": IDandNames[i][1],
						"language": devLanguages[i],
						"openDate": datetime2str(devOpenDates[i]),
						"status": devStatus[i]
					})
			except Exception as e:
				logger.warning(str(e))

		self.write_json(devInfo)

	@coroutine
	def post(self):
		area = self.get_json_data()
		print area
		for i in area:
			cfg = TestServerConf[i]
			yield self.restartServ(cfg)
		self.write_json({"ret": True})

	@coroutine
	def restartServ(self, cfg):
		cmd = "supervisorctl restart " + cfg.servers[0]
		cwd = cfg.deploy
		p = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, cwd=cwd)
		out, err = p.communicate()


class ModifyHandler(AuthedHandler):
	url = r'/test_server/set'

	@coroutine
	def post(self):
		modify = self.get_json_data()
		saveServerDefines(modify)
		saveServerLanguages(modify)
		self.write({'ret': True})


Restarting = False
# Operation activity test
class TestYYHuoDongHandler(AuthedHandler):
	url = r'/test_yyhuodong'

	@coroutine
	def get(self):
		dates = getServerOpenDate()
		names = getServerIDandNames()

		ret = []
		for i, d in enumerate(dates):
			ret.append((names[i][0], d))

		self.render_page('_test_yyhuodong.html', servDates=ret)

	@coroutine
	def post(self):
		global Restarting
		if not Restarting:
			if not self.debug:
				raise HTTPError(404, reason='test only in debug mode')

			now = datetime.datetime.now()
			dates = getOpenDate()

			Restarting = True

			# set time
			serverTime = self.get_argument("serverTime", None)
			dt = htmlToDatetime(serverTime)
			os.system('date -s "%d/%d/%d %d:%d:00"' % (dt.year, dt.month, dt.day, dt.hour, dt.minute))

			# restart
			openDate1 = self.get_argument("openDate1", None)
			openDate2 = self.get_argument("openDate2", None)
			openDate3 = self.get_argument("openDate3", None)
			openDate4 = self.get_argument("openDate4", None)
			openDate5 = self.get_argument("openDate5", None)
			openDate6 = self.get_argument("openDate6", None)
			openDate7 = self.get_argument("openDate7", None)

			dates = filter(None, [openDate1, openDate2, openDate3, openDate4, openDate5, openDate6, openDate7])
			dates = [htmlToDatetime(x) for x in dates]

			saveServerDefines(dates)
			for cfg in TestServerConfigs:
				os.system(cfg['deploy_cmd'])
			# restart cross
			os.system('cd /home/shuma_02/deploy_dev && supervisorctl restart cross_dev_server')
			Restarting = False
			testDay = int(self.get_argument("testDay", 10))
			TestYYHuoDongSocketHandler.start_cache(dt, testDay)
			self.render("test_yyhuodong.html", account=self.account, debug=self.debug, dates=[datetimeToHTML(dt) for dt in dates], serverTime=datetimeToHTML(now), messages=TestYYHuoDongSocketHandler.cache, sidebarDict=SidebarDict, locale=self.get_cookie("user_locale"))
		else:
			self.write({'restarting': True})


class TestYYHuoDongSocketHandler(tornado.websocket.WebSocketHandler):
	url = r'/test_yyhuodong/log'

	waiters = set()
	cache = {}
	yyCache = {}
	timer = None
	nowDT = None
	endDT = None
	firstStart = True

	def open(self):
		TestYYHuoDongSocketHandler.waiters.add(self)

	def on_close(self):
		TestYYHuoDongSocketHandler.waiters.remove(self)

	@classmethod
	def start_cache(cls, nowDT, days):
		cls.cache = {}
		cls.yyCache = {}
		cls.timer = tornado.ioloop.PeriodicCallback(cls.update, 2*1000)
		cls.nowDT = nowDT
		cls.endDT = nowDT + datetime.timedelta(days=days, hours=1)
		cls.firstStart = True
		TestYYHuoDongSocketHandler.send_updates({"test": ["After restart, start testing"]})
		cls.timer.start()

	@classmethod
	def stop_cache(cls):
		cls.cache = {}
		cls.yyCache = {}
		cls.timer.stop()
		TestYYHuoDongSocketHandler.send_updates({"test": ["Test"]})
		for waiter in cls.waiters:
			try:
				waiter.close()
			except:
				pass

	@classmethod
	def parseLog(cls, log):
		l = log.split('\n')
		key = l[0].split()[0]
		cur = -1
		if key in cls.cache:
			last = cls.cache[key][-1]
			while abs(cur) > len(l):
				if last == l[cur]:
					l = l[len(l) + 1 + cur:]
					break
				cur -= 1
		# slim yyhudong log
		ll = []
		# if key not in cls.yyCache:
		# 	cls.yyCache[key] = defaultdict(str)
		# for yy in l:
		# 	# 7 id, 9 True or False
		# 	ks = yy.split()
		# 	id, flag = ks[7], ks[9]
		# 	if flag != cls.yyCache[key][id]:
		# 		print key, id, flag, yy
		# 		cls.yyCache[key][id] = flag
		# 		ll.append(yy)

		for yy in l:
			# 7 id, 9 True or False
			ks = yy.split()
			id, flag = int(ks[7]), ks[9]
			ks[4], ks[5] = '', ''
			# id1~149Do not show
			if id >= 150 and flag == 'True':
				ll.append(' '.join(ks))
		return key, ll

	@classmethod
	@coroutine
	def update(cls):
		cls.timer.stop()
		# first
		starts = {}
		while cls.firstStart:
			for cfg in TestServerConfigs:
				cmd = cfg['yylog_cmd'] + '|grep "Game Server Start OK"'
				pipe = subprocess.Popen(cmd, shell=True, bufsize=1024*1024, stdout=subprocess.PIPE).stdout
				log = pipe.read().strip()
				if log and cfg['name'] not in starts:
					TestYYHuoDongSocketHandler.send_updates({"test": [cfg['name'] + "Initialization"]})
					starts[cfg['name']] = True
			if len(starts) == len(TestServerConfigs):
				TestYYHuoDongSocketHandler.send_updates({"test": ["The server initialization is complete"]})
				break
			else:
				yield sleep(1)
		if cls.nowDT.hour >= 5:
			cls.nowDT += datetime.timedelta(days=1)
		cls.nowDT = datetime.datetime.combine(cls.nowDT.date(), datetime.time(hour=5, minute=1))
		cls.firstStart = False

		# change time
		if cls.nowDT > cls.endDT:
			cls.stop_cache()
			return
		dt = cls.nowDT
		cmd = 'date -s "%d/%d/%d %d:%d:00"' % (dt.year, dt.month, dt.day, dt.hour, dt.minute)
		os.system(cmd)
		TestYYHuoDongSocketHandler.send_updates({"test": [cmd]})
		yield sleep(1)
		# get log
		for cfg in TestServerConfigs:
			while True:
				cmd = cfg['yylog_cmd'] + '|grep yyhuodong|grep delta|grep "I %d%02d%02d"' % (dt.year%100, dt.month, dt.day)
				pipe = subprocess.Popen(cmd, shell=True, bufsize=1024*1024, stdout=subprocess.PIPE).stdout
				log = pipe.read().strip()
				if log:
					break
				yield sleep(1)
			key, msgL = cls.parseLog(log)
			TestYYHuoDongSocketHandler.send_updates({key: msgL})
		cls.timer.start()

	@classmethod
	def send_updates(cls, d):
		for key, msgL in d.iteritems():
			if key not in cls.cache:
				cls.cache[key] = []
			cls.cache[key] += msgL
		for waiter in cls.waiters:
			try:
				waiter.write_message(d)
			except:
				pass


# 战斗测试
class TestFightHandler(AuthedHandler):
	url = r'/test_fight'

	@coroutine
	def get(self):
		print "test"
		self.render_page("_test_fight.html")

	@coroutine
	def post(self):
		_ajax = self.get_argument('_ajax', False)
		if not _ajax:
				self.render("test_fight.html", account=self.account, debug=self.debug, messages={}, sidebarDict=SidebarDict, locale=self.get_cookie("user_locale"))
				raise Return(None)
		battleList = self.get_argument('battleList', False)
		if not battleList:
			result = yield self.servNode.client('battletest').call_async('startBattleTest')
		else:
			battleList = ast.literal_eval(battleList)
			result = yield self.servNode.client('battletest').call_async('startBattleTest', battleList)
		TestFightSocketHandler.start_cache(self.servNode)
		self.render("test_fight.html", account=self.account, debug=self.debug,messages=TestFightSocketHandler.cache, sidebarDict=SidebarDict, locale=self.get_cookie("user_locale"))
		# self.write({'futureList': futureList})


# 战斗日志下载
class TestFightDownloadHandler(AuthedHandler):
	url = r'/test_fight/download'

	@coroutine
	def run(self):
		playid = self.get_argument("playid")
		typ = self.get_argument("type")
		result = yield self.servNode.client('battletest').call_async('download', typ, playid)
		self.write(result)


# RECORD战斗测试
class TestRecordFightHandler(AuthedHandler):
	url = r'/test_record_fight'

	@coroutine
	def run(self):
		_ajax = self.get_argument('_ajax', False)
		if not _ajax:
				self.render("test_fight.html", account=self.account, debug=self.debug, messages={}, futureList=[], sidebarDict=SidebarDict, locale=self.get_cookie("user_locale"))
				raise Return(None)
		svnVersion = self.get_argument('svnVersion', False)
		testLanguage = self.get_argument('testLanguage', False)
		method = self.get_argument('method', False)
		recordFile = self.request.files.get('recordFile', False)
		sendTimes = self.get_argument('sendTimes', False)

		if svnVersion and svnVersion != '':
			versionPipe = os.popen('cd {} && svn info | grep Revision'.format(ANTICHEAT01))
			version = versionPipe.read()
			codeVersion = version.split()[-1]
			if codeVersion != svnVersion:
				os.system('cd {path} && svn up -r {svnVersion} --accept theirs-full && svn up -r {svnVersion} game_config --accept theirs-full && svn up -r {svnVersion} game_scripts --accept theirs-full && svn up -r {svnVersion} game_scripts/model --accept theirs-full'.format(path=ANTICHEAT01, svnVersion=svnVersion))

		inspector = subprocess.Popen('cd {}/game_scripts && cat main.lua | grep "LOCAL_LANGUAGE = "'.format(ANTICHEAT01), shell=True, stdout=subprocess.PIPE)
		languageLine = inspector.communicate()[0]
		codeLanguage = languageLine.split("'")[1]
		if codeLanguage != testLanguage:
			subprocess.call('''cd {path}/game_scripts && sed -i "s/LOCAL_LANGUAGE = '.*'/LOCAL_LANGUAGE = '{testLanguage}'/g" main.lua'''.format(path=ANTICHEAT01, testLanguage=testLanguage), shell=True)
		futureList = []
		if recordFile and recordFile != '':
			currentLoop = tornado.ioloop.IOLoop.current()
			futureList = self.testRecordFight(recordFile, sendTimes, method)
			currentLoop.make_current()

		self.write({'futureList': futureList})

	def testRecordFight(self, data, sendTimes, method):
		recordFile = data
		futureList = []
		client = msgpackrpc.Client(address=msgpackrpc.Address('127.0.0.1', 1234), timeout=None, reconnect_limit=-1)
		if data:
			filename = recordFile[0]['filename']
			content = recordFile[0]['body']
			if sendTimes == '':
				sendTimes = '1'
			if method == '':
				method = 'newUnionRecord'
			sendTimes = int(sendTimes)
			sendTimes = max(1, sendTimes)
			for i in xrange(sendTimes):
				rpcArgs = ['game.dev.1', i, content]
				if 'newClientRecord' in method:
					rpcArgs = [content]
				if '.' in method:
					fu = client.call_async(method, rpcArgs)
				else:
					fu = client.call_async(method, *rpcArgs)
				try:
					futureList.append(fu.get())
				except Exception as e:
					client = msgpackrpc.Client(address=msgpackrpc.Address('127.0.0.1', 1235), timeout=None, reconnect_limit=-1)
					if '.' in method:
						fu = client.call_async(method, rpcArgs)
					else:
						fu = client.call_async(method, *rpcArgs)
					futureList.append(fu.get())
		return futureList


class TestFightSocketHandler(tornado.websocket.WebSocketHandler):
	url = r'/test_fight/log'

	waiters = set()
	cache = {}
	timer = None
	servNode = None

	def open(self):
		TestFightSocketHandler.waiters.add(self)

	def on_close(self):
		TestFightSocketHandler.waiters.remove(self)

	@classmethod
	def start_cache(cls, servNode):
		cls.cache = {}
		cls.servNode = servNode
		cls.timer = tornado.ioloop.PeriodicCallback(cls.update, 2*1000)
		cls.timer.start()
		TestFightSocketHandler.send_updates({"test": ["start testing"]})


	@classmethod
	def stop_cache(cls):
		cls.cache = {}
		cls.timer.stop()
		TestFightSocketHandler.send_updates({"testing": False})
		for waiter in cls.waiters:
			try:
				waiter.close()
			except:
				pass
		# self.close()

	@classmethod
	def parseResult(cls, oldResult):
		result = {}
		# for key, value in oldResult.items():

		# return 'test', log

	@classmethod
	@coroutine
	def update(cls):
		cls.timer.stop()
		# get log
		testing, result, resultDetail = yield cls.servNode.client('battletest').call_async('getBattleTestResult')
		result['detail'] = resultDetail
		TestFightSocketHandler.send_updates(result)
		if testing == False:
			cls.stop_cache()
			return
		cls.timer.start()

	@classmethod
	def send_updates(cls, d):
		cls.cache.update(d)
		for waiter in cls.waiters:
			try:
				waiter.write_message(d)
			except:
				pass


class TestAddRobotHandler(AuthedHandler):
	url = r'/add_robot'

	@coroutine
	def get(self):
		_ajax = self.get_argument('_ajax', False)
		self.requiredArg(_ajax)
		testServer1 = self.get_argument('testServer1', False)
		testServer2 = self.get_argument('testServer2', False)
		testServer3 = self.get_argument('testServer3', False)
		testServer4 = self.get_argument('testServer4', False)
		testServer5 = self.get_argument('testServer5', False)
		testServer6 = self.get_argument('testServer6', False)

		def parseList(s):
			return ast.literal_eval('[{s}]'.format(s=s)) if s else s
		def parseRobot(serverID, roleID):
			return ('game.dev.{0}'.format(serverID), roleID)

		robotList = [testServer1, testServer2, testServer3, testServer4, testServer5, testServer6]
		robotList = map(parseList, robotList)
		funcInput = []
		for i, robots in enumerate(robotList, 1):
			if robots:
				for r in robots:
					funcInput.append(parseRobot(i, int(r)))

		result = yield self.servNode.client('battletest').call_async('addTestRole', funcInput)
		self.write({'result': 'true'})


antiCheatRestarting = False
# restart anti_cheat
class TestAntiCheatHandler(AuthedHandler):
	url = r'/test_antiCheat'

	@coroutine
	def get(self):
		global antiCheatRestarting
		_ajax = self.get_argument("_ajax", False)
		self.requiredArg(_ajax)
		if antiCheatRestarting == False:
			antiCheatRestarting = True
			os.system('cd /home/shuma_01/server/anti-cheat && svn up && ./csv2lua.sh')
			os.system('cd /home/shuma_01/deploy_dev && supervisorctl restart anti_cheat_server')
			antiCheatRestarting = False
			self.write({'result': 'true'})
		else:
			self.write({'result': 'false'})


battleRestarting = False
# restart anti_cheat
class TestRestartBattleHandler(AuthedHandler):
	url = r'/test_restart_battle'

	@coroutine
	def get(self):
		global battleRestarting
		_ajax = self.get_argument("_ajax", False)
		self.requiredArg(_ajax)
		if battleRestarting == False:
			battleRestarting = True
			os.system('cd /home/shuma_04/deploy_dev && supervisorctl restart battle_test_server')
			battleRestarting = False
			self.write({'result': 'true'})
		else:
			self.write({'result': 'false'})

class TestAntiCheatLogHandler(AuthedHandler):
	url = r'/anti_cheat/log'

	@coroutine
	def get(self):
		count = self.get_argument('count', 2)
		before, after = 8, 10
		lineCount = before + after + 2
		cmd = "cd /home/shuma_01/deploy_dev/childlog &&cat anti_cheat_server-stdout*.log|grep 'stack traceback' -A %d -B %d|tail -%d" % (after, before, lineCount*count)
		ret = os.popen(cmd).read().strip()
		self.write({'result': ret})



serverRestarting = False
# 重启内网服务器
class TestRestartAllServerHandler(AuthedHandler):
	url = r'/test_restart_server'

	@coroutine
	def get(self):
		global serverRestarting
		waiting = 20
		_ajax = self.get_argument('_ajax', False)
		self.renderHandler(_ajax, 'test_restart_server.html', servList=self.colorA(self.serverList))
		servName = self.get_argument('servName', False)
		if serverRestarting == False:
			serverRestarting = True
			cmd = {
				'game': 'cd /home/shuma_01/deploy_dev && supervisorctl stop game_db_server pvp_server game_server && supervisorctl start game_db_server pvp_server && sleep {} && supervisorctl start game_server'.format(waiting),
				'game_dev': 'cd /home/shuma_02/deploy_dev && supervisorctl stop game_db_dev_server pvp_dev_server game_dev_server && supervisorctl start game_db_dev_server pvp_dev_server && sleep {} && supervisorctl start game_dev_server'.format(waiting),
				'game_dev2': 'cd /home/shuma_03/deploy_dev && supervisorctl stop game_db_server pvp_server game_server && supervisorctl start game_db_server pvp_server && sleep {} && supervisorctl start game_server'.format(waiting),
				'game_dev3': 'cd /home/shuma_04/deploy_dev && supervisorctl stop game_db_server pvp_dev3_server game_dev3_server && supervisorctl start game_db_server pvp_dev3_server && sleep {} && supervisorctl start game_dev3_server'.format(waiting),
				'game_dev4': 'cd /home/shuma_05/deploy_dev && supervisorctl stop game_db_dev_server pvp_dev_server game_dev_server && supervisorctl start game_db_dev_server pvp_dev_server && sleep {} && supervisorctl start game_dev_server'.format(waiting),
				'game_dev5': 'cd /home/shuma_06/deploy_dev && supervisorctl stop game_db_server pvp_server game_server && supervisorctl start game_db_server pvp_server && sleep {} &&  supervisorctl start game_server'.format(waiting),
				'default': ''
			}.get(servName, 'default')
			os.system(cmd)
			serverRestarting = False
			self.write({'result': 'true'})
		else:
			self.write({'result': 'false'})
