# -*- coding: utf-8 -*-
import uuid
import time
import json
import os
import re
import datetime
import hashlib
import urllib
from tornado.gen import coroutine, Return
from tornado.web import HTTPError
from bson.binary import Binary

from base import BaseHandler, AuthedHandler
from settings import COOKIES_KEY, COOKIES_TIME, APP_DEBUG_PATH, UPLOAD_PATH
from analyprocess.helper import generate_symbol_file, translate
from util import *
from object.scheme import *

import msgpack
import binascii


class LoginHandler(BaseHandler):
	url = "/login"

	@coroutine
	def get(self):
		self.render("login.html", error="")

	@coroutine
	def post(self):
		name = self.get_argument("account")
		pwd = self.get_argument("password")

		account = yield self.async_db_exec(Account.find_one, {"name": name})
		if account:
			if pwd == account.password:
				self.set_secure_cookie(COOKIES_KEY, account.name, expires_days=None, expires=time.time() + COOKIES_TIME, httponly=True)
				self.redirect("/")
			else:
				self.render("login.html", error="密码不正确！")
		else:
			self.render("login.html", error="用户不存在！")


class LogoutHandler(AuthedHandler):
	url = "/logout"

	@coroutine
	def get(self):
		self.clear_cookie(COOKIES_KEY)
		self.redirect("/login")


# 上传.so文件
class FileUploadHandler(AuthedHandler):
	url = "/fileupload"

	@coroutine
	def get(self):
		# 版本号判断
		version = self.get_argument("versionId")
		package_name = self.get_argument("package_name")
		game_name = self.get_argument("game_name")
		platform = "android"

		key = (platform, package_name, version, game_name)
		ret = {"msg": "",}

		query = {"platform": platform, "package_name": package_name, "version": version, "game_name": game_name}
		data = yield self.async_db_exec(SymbolFile.find, query)
		if not data:
			ret["msg"] = "注意：该版本数据库已存在，继续上传将替换原先版本号的内容！"

		self.write_json(ret)

	@coroutine
	def post(self):
		files = self.request.files.get("uploadFile", None)
		if not files:
			raise HTTPError(404, "Upload File is None")

		file_content = files[0].get("body", None)
		file_name = files[0].get("filename", None)
		if not file_content or not file_name:
			raise HTTPError(404, "Upload File Content is None")

		version = self.get_argument("versionId")
		package_name = self.get_argument("package")
		game_name = self.get_argument("game_name")

		nowTime = datetime.datetime.now()

		platform = "android"
		up = {
				"name": file_name,
				"version": version,
				"time": nowTime,
				"package_name": package_name,
				"platform": platform,
				"game_name": game_name
			}

		file_path = str(uuid.uuid1()) + ".so"
		file_path = os.path.join(UPLOAD_PATH, file_path)
		up["path"] = file_path

		# 将文件写入磁盘
		yield self.async_execute(write_file, file_path, file_content)

		# 生成symbol file
		ret, nums = yield self.async_execute(generate_symbol_file, file_path, file_name)
		if ret:
			up["symbol_nums"] = nums
			up["status"] = True
		else:
			self.write_json({"result": False, "msg": nums})
			return

		yield self.async_db_exec(SymbolFile.insert_one, up)

		self.write_json({"result": True, "msg": "success"})


# 上传ios.sym文件
class IOSFileUploadHandler(BaseHandler):
	url = "/ios_upload"

	@coroutine
	def post(self):
		files = self.request.files.get("uploadFile", None)
		if not files:
			raise HTTPError(404, "Upload File is None")
		file_content = files[0].get("body", None)
		file_name = files[0].get("filename", None)
		if not file_content or not file_name:
			raise HTTPError(404, "Upload File Content is None")

		package_name = self.get_argument("package")
		version = self.get_argument("versionId")
		game_name = self.get_argument("game_name")
		platform = "ios"
		update = {
			'name': file_name,
			'platform': platform,
			'version': version,
			'package_name': package_name,
			'game_name': game_name,
			'time': datetime.datetime.now()
		}
		ret, nums = yield self.async_execute(generate_symbol_file, file_content, file_name, True)
		if ret:
			update["status"] = True
			update["symbol_nums"] = nums
		else:
			update["status"] = nums

		yield self.async_db_exec(SymbolFile.insert_one, update)
		# data = SymbolFile.find_one(self.mongo.DBClient, {"version": version, "package_name": package_name, "platform": platform, "game_name": game_name})
		# if data:
		# 	yield self.async_db_exec(SymbolFile.update, {"_id": data["_id"]}, {"$set": update})
		# else:
		# 	yield self.async_db_exec(SymbolFile.insert_one, update)
		self.write_json({"result": True})


# 接收.dmp文件
class FileDumpHandler(BaseHandler):
	url = "/dump"

	@coroutine
	def post(self):
		dmpFile = self.request.files.get("dump", None)
		if not dmpFile:
			dmpFile = self.request.files.get("dmpFile", None)
			if not dmpFile:
				raise HTTPError(404, "Dump File is None")

		info = self.get_info()

		dmpContent = dmpFile[0].get("body", None)
		if not dmpContent:
			raise HTTPError(404, "Dump File Content is None")
		dmpName = dmpFile[0].get("filename", None)

		deviceFile = self.request.files.get("tj_device", None)
		deviceInfo = {}
		if deviceFile:
			deviceContent = deviceFile[0].get("body", "").strip()
			if deviceContent:
				try:
					deviceInfo = json.loads(deviceContent)
				except Exception as e:
					print e

		debugFile = self.request.files.get("tj_debug", None)
		debugContent = None
		if debugFile:
			debugContent = debugFile[0].get("body", None)
		debugPath = None
		if debugContent:
			debugName = str(uuid.uuid1()) + ".debug.log"
			debugPath = os.path.join(APP_DEBUG_PATH, debugName)
			yield self.async_execute(write_file, debugPath, debugContent)

		userFile = self.request.files.get("user_default", None)
		user_default = {}
		if userFile:
			user_default["filename"] = userFile[0].get("filename", None)
			user_default["body"] = userFile[0].get("body", None)

		fileData = dict(
			file_name = dmpName,
			file_content = Binary(dmpContent),
			game_name = deviceInfo.get("game_name", None),
			# game_name = "libcocos2dlua.so", # dmp分析需要用到game_name
			package_name = deviceInfo.get("package_name", "unknown"),
			game_start_time = deviceInfo.get("game_start_time", "unknown"),
			phone_name = deviceInfo.get("manufacturer", "unknown"),
			phone_sys = str(deviceInfo.get("type", "unknown")).strip() + "-" + str(deviceInfo.get("type_int", "unknown")).strip(),
			imei = deviceInfo.get("imei", "unknown"),
			device_info = deviceInfo,
			app_debug = debugPath,
			user_default = user_default,
		)

		info.update(fileData)
		info["server_role"] = info["server"] + "-" + info["role"]
		if deviceInfo.get('svn_version', None):
			info['version'] = deviceInfo['svn_version']

		if info["version"] not in self.versions:
			self.versions.insert(0, info["version"])

		yield self.async_db_exec(DmpRecord.insert_one, info)

		# 统计
		c = self.statCache.get("today_dmp_count") + 1
		self.statCache.set("today_dmp_count", c)
		self.statCache.get("dmp_imei").add(info['imei'])
		self.statCache.get("dmp_server_role").add(info['server_role'])
		self.write({'result': 'success'})

	def get_info(self):
		info = {
				"dump_reset": self.get_argument("dump_reset", None),

				"url": self.get_argument("url", "unknown"),
				"arch": self.get_argument("arch", "unknown"),
				"platform": self.get_argument("platform", "unknown"),
				"platform_id": self.get_argument("platform_id", "unknown"),
				"channel": self.get_argument("channel", "unknown"),
				"tag": self.get_argument("tag", "unknown"),
				"version": self.get_argument("version", "unknown"),
				"patch": self.get_argument("patch", "unknown"),
				"min_path": self.get_argument("min_patch", "unknown"),
				"account": self.get_argument("account", "unknown"),
				"role": self.get_argument("role", "unknown"),
				"server": self.get_argument("server", "unknown"),
				"report_time": datetime.datetime.now()
			}
		return info


# 接收异常
ExceptionRepeatedCache = {}
RepeatedCacheIntervalTime = time.time()
class ExceptionHandler(BaseHandler):
	url = "/exception"

	@coroutine
	def post(self, *args, **kwargs):
		stack = self.get_argument("exception", None)
		if not stack:
			raise HTTPError(404, "Exception Error is None")

		deviceFile = self.request.files.get("tj_device", None)
		deviceInfo = {}
		if deviceFile:
			deviceContent = deviceFile[0].get("body", "").strip()
			if deviceContent:
				try:
					deviceInfo = json.loads(deviceContent)
				except Exception as e:
					print e

		info = self.get_info()
		info['device_info'] = deviceInfo
		info["stack"] = stack

		info["game_start_time"] = deviceInfo.get('game_start_time', 'unknown')
		info["package_name"] = deviceInfo.get('package_name', 'unknown')
		if deviceInfo.get('svn_version', None):
			info["version"] = deviceInfo['svn_version']
		info["server_role"] = info["server"] + "-" + info["role"]
		info["imei"] = deviceInfo.get('imei', 'unknown')
		info["phone_name"] = deviceInfo.get("manufacturer", "unknown")
		info["phone_sys"] = str(deviceInfo.get("type", "unknown")).strip() + "-" + str(deviceInfo.get("type_int", "unknown")).strip()

		if self.exceptionRepeatedCheck(info):
			yield self.async_db_exec(ExcRecord.insert_one, info)
			# 统计
			if info["version"] not in self.versions:
				self.versions.insert(0, info["version"])
			c = self.statCache.get("today_exc_count") + 1
			self.statCache.set("today_exc_count", c)
			self.statCache.get("exc_imei").add(info['imei'])
			self.statCache.get("exc_server_role").add(info['server_role'])

		self.write({'result': 'success'})

	def get_info(self):
		info = {
				"url": self.get_argument("url", "unknown"),
				"arch": self.get_argument("arch", "unknown"),
				"platform": self.get_argument("platform", "unknown"),
				"platform_id": self.get_argument("platform_id", "unknown"),
				"channel": self.get_argument("channel", "unknown"),
				"tag": self.get_argument("tag", "unknown"),
				"version": self.get_argument("version", "unknown"),
				"patch": self.get_argument("patch", "unknown"),
				"min_path": self.get_argument("min_patch", "unknown"),
				"account": self.get_argument("account", "unknown"),
				"role": self.get_argument("role", "unknown"),
				"server": self.get_argument("server", "unknown"),
				"report_time": datetime.datetime.now()
			}
		return info

	def exceptionRepeatedCheck(self, info):
		st = time.time()
		key = info['platform'] + info['server'] + info['account'] + str(info['role']) + str(info['patch']) + str(info['min_path'])
		firstLine = re.split(r"\n", info['stack'])[0]
		identSpec = re.sub(r":\d+:", "", firstLine)
		ident = re.sub(r"\[\d+\]", "", identSpec, 1)

		md5 = hashlib.md5()
		md5.update(ident)
		md5.update(key)
		ckey = md5.hexdigest()

		cache = ExceptionRepeatedCache.get(ckey, None)
		if not cache:
			ExceptionRepeatedCache[ckey] = [st, 1]
			interval = st - RepeatedCacheIntervalTime
			if len(ExceptionRepeatedCache) >= 60 and interval >= 7:
				for k, d in ExceptionRepeatedCache.items():
					if (st - d[0]) > 5:
						ExceptionRepeatedCache.pop(k, None)
		else:
			interval = st - cache[0]
			if interval <= 5 and cache[1] <= 5:
				cache[1] += 1
			elif interval > 5:
				cache[0], cache[1] = st, 1
			elif cache[1] > 5:
				return False
		return True


# 接收数码异常
class ShumaExceptionHandler(BaseHandler):
	url = "/shumaexp"

	@coroutine
	def post(self):
		error = self.get_argument("error", None)
		stack = self.get_argument("stack", "")
		if not error or error == "":
			raise HTTPError(404, "Shuma Exception Error is None")

		error = error + "\n" + stack
		role = self.get_argument("role", "unknown")
		server = self.get_argument("server", "unknown")
		data = {
			"error": error,
			"report_time": datetime.datetime.now(),
			# url传递的参数--------
			"channel": self.get_argument("channel", None),
			"account": self.get_argument("account", None),
			"role": role,
			"server": server,
			"server_role": server + "--" + role,
			"account_tag": self.get_argument("tag", None),
			"version": self.get_argument("app_version", "unknown"),
			"game_start_time": self.get_argument("game_start_time", None),
			"phone_name": None,
			"phone_sys": "unknown-unknown",
			"imei": None,
			"package_name": None,
		}

		if data["version"] not in self.versions:
			self.versions.insert(0, data["version"])
		#self.exReCache.insert(data)
		self.async_execute(self.exre_db.insertOne, data)
		self.write({'result': 'success'})


class RemoteDebugHandler(BaseHandler):
	url = "/remote_debug"

	def get(self):
		print "get"
		self.render('test.html')

	def post(self):
		print "post"
		print "111", self.request.arguments
		print "222", self.request.headers
		print "333", self.request.files
		print "444", self.request.body

		if not self.request.files.get("dump", None):
			print "没有dump"
		if not self.request.files.get("tj_device", None):
			print "没有tj_device"

class FeedBackHandler(BaseHandler):
	url = "/feedback"
	HttpClient = None

	@coroutine
	def get(self):
		print self.request.arguments
		print self.request.host

	@coroutine
	def post(self):
		if not self.HttpClient:
			from tornado.curl_httpclient import CurlAsyncHTTPClient
			FeedBackHandler.HttpClient = CurlAsyncHTTPClient()

		feedback = self.get_json_data(foolish=True)
		data = {
			'account_id': feedback.get('account_id', None),
			'game_server': feedback.get('game_server', None),
			'role_id': feedback.get('role_id', None),
			'role_uid': feedback.get('uid', None),
			'role_name': feedback.get('role_name', None),
			'grade': feedback.get('grade', None),
			'vip': feedback.get('vip', None),
			'classify': feedback.get('classify', None),
			'issue': feedback.get('issue', '').strip(),
			'time': datetime.datetime.now(),
			'status': False,
		}
		if not data['issue']:
			return

		yield self.async_db_exec(FeedBackRecord.insert_one, data)

		if self.dingding:
			ddURL = self.dingding
			replay_info = {'replay_info': '{0},{1},{2},{3},{4}'.format(data['game_server'], data['role_id'], data['classify'], str(data['role_name']), str(data['issue']))}
			replayURL = 'http://{0}/feedback/page?{1}'.format(self.request.host, urllib.urlencode(replay_info))
			tpZhMap = {
				"RechargeIssue": "充值问题",
				"BattleIssue": "战斗问题",
				"BugIssue": "BUG反馈",
				"Recommand": "游戏建议"
			}
			cc = tpZhMap.get(data['classify'], data['classify'])
			data['issue'] = data['issue'] + '\n' + translate(data['issue'], self.language)
			body = {
				"msgtype": "markdown",
				"markdown": {
					"title": "[口袋]{0}".format(cc),
					"text": "反馈时间: {0}\n\n问题类型: {8}\n\n区服: {1}\n\n角色名: {2}\n\n角色ID: {3}\n\n等级: {4}\n\nvip: {5}\n\n问题描述: {6}\n\n {7}".format(
							str(data['time']), data['game_server'], data['role_name'], data['role_id'], data['grade'], data['vip'], data['issue'], "[回复邮件](%s)"% replayURL, cc
						)
				}
			}
			self.HttpClient.fetch(ddURL, method="POST", headers={"Content-Type": "application/json"}, body=json.dumps(body))


# 反作弊error战报上传
class BattleReportHandler(BaseHandler):
	url = "/battle_report"

	@coroutine
	def post(self):
		data = msgpack.unpackb(self.request.body)

		traceback = data["traceback"]
		ident = traceback.split("\n", 1)[0]

		data = {
			"serv_key": data["serv_key"],
			"play_id": binascii.hexlify(data["play_id"]),
			"traceback": traceback,
			"ident": ident,
			"play_record": Binary(data["play_record"]),
			"report_time": datetime.datetime.now(),
			"type": data["type"]
		}

		yield self.async_db_exec(BattleReport.insert_one, data)


# 客户端异常战报上传
class PlayReportHandler(BaseHandler):
	url = "/play_report"

	AESIV = 'YouMi_Technology'
	AESPWD = 'tjshuma081610888'

	@coroutine
	def post(self):
		data = msgpack.unpackb(self.request.body)
		pad = data[0]
		from Crypto.Cipher import AES
		aes = AES.new(self.AESPWD, AES.MODE_CBC, self.AESIV)
		data = aes.decrypt(data[1])
		data = msgpack.unpackb(data[:-pad])

		playID = data["play_id"]
		if len(playID) == 12:
			playID = binascii.hexlify(playID)

		traceback = data.get('traceback', '')
		desc = data.get('desc', '')
		ident = traceback.split("\n", 1)[0]

		data = {
			"serv_key": data["serv_key"],
			"role_id": binascii.hexlify(data["role_id"]),
			"play_id": playID,
			"play_record": Binary(data["play_record"]),
			"scene_id": data["scene_id"],
			"report_time": datetime.datetime.now(),

			"traceback": traceback,
			"ident": ident,
			'desc': desc,
		}

		yield self.async_db_exec(PlayReport.insert_one, data)
