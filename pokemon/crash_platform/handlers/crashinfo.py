# -*- coding: utf-8 -*-
import re
import datetime
from tornado.gen import coroutine
from tornado.web import HTTPError
from collections import OrderedDict

from base import AuthedHandler
from object.cache import SimpleLRUCache
from object.scheme import *


# 缓存查询过的信息
CrashInfoCache = SimpleLRUCache(100)

class CrashInfoHandler(AuthedHandler):
	url = "/crashinfo"

	@coroutine
	def get(self):
		ident = self.get_argument("ident", None)
		query = {"ident": ident}
		if not ident:
			_id = int(self.get_argument("_id"))
			query = {"id": _id}
		style = int(self.get_argument("type"))
		collection = self.ErrStatisticsType[style]

		data = yield self.async_db_exec(collection.find_one, query)
		CrashInfoCache.set((data.id, style), data)
		self.render(
				"crashinfo.html",
				name = self.current_user,
				info = data,
				tag = self.tag
			)


class SwitchStackStatus(AuthedHandler):
	url = "/crashinfo/switchstatus"

	@coroutine
	def post(self):
		jsonData = self.get_json_data()
		_id = jsonData["_id"]
		style = jsonData["style"]
		processed = jsonData["processed"]
		data = {
			"name": self.current_user,
			"time": datetime.datetime.now(),
			"comments": jsonData["comments"]
		}

		collection = self.ErrStatisticsType[style]
		yield self.async_db_exec(collection.update, {"id": _id}, {"$set": {"status": processed}, "$push": {"comment": data}})
		self.write_json({"ret": True})


class CrashInfoChart(AuthedHandler):
	url = "/crashinfo/frequencychart"

	@coroutine
	def get(self):
		queryType = int(self.get_argument("queryType"))
		_id = int(self.get_argument("_id"))
		style = int(self.get_argument("style"))

		key = (_id, style)
		if key in CrashInfoCache:
			stackData = CrashInfoCache.get(key)
		else:
			stackData = yield self.async_db_exec(self.ErrStatisticsType[style].find_one, {"id": _id})
		if not stackData:
			raise HTTPError(404, "ID %s style %s not exit in DB!"% (_id, style))

		if queryType == 7 or queryType == 30:
			now = datetime.datetime.now()
			now = datetime.datetime(now.year, now.month, now.day)
			one = datetime.timedelta(days=1)

			querys = OrderedDict()
			for i in range(queryType-1, -1, -1):
				st = now - i*one
				et = st + one
				querys[st.date()] = {"report_time": {"$gte": st, "$lt": et}, "stack_ident": stackData["ident"]}

		elif queryType == 24:
			now = datetime.datetime.now()
			now = datetime.datetime(now.year, now.month, now.day, now.hour)
			one = datetime.timedelta(hours=1)

			querys = OrderedDict()
			for i in range(23, -1, -1):
				st = now - i*one
				et = st + one
				querys[st.hour] = {"report_time": {"$gte": st, "$lt": et}, "stack_ident": stackData["ident"]}

		else:
			raise HTTPError(404, "queryType is not defind")

		xAex = []
		xData = []
		for x in querys:
			xAex.append(x)
			c = self.ErrRecordType[style].count(self.mongo.DBClient, querys[x])
			xData.append(c)

		data = {
			"ret": True,
			"xAex": xAex,
			"xData": xData,
		}
		self.write_json(data)


class CrashChartPie(AuthedHandler):
	url = r"/crashinfo/chartpie"

	@coroutine
	def get(self):
		_id = int(self.get_argument("_id", None))
		style = int(self.get_argument("style", None))
		uriP = str(self.get_argument("type", None))
		key = (_id, style)
		if key in CrashInfoCache:
			stackData = CrashInfoCache.get(key)
		else:
			stackData = yield self.async_db_exec(self.ErrStatisticsType[style].find_one, {"id": _id})
		if not stackData:
			raise HTTPError(404, "ID %s style %s not exit in DB!"% (_id, style))

		labels = []
		datas = []
		if uriP == "phone":
			for i in stackData["phone_name"]:
				labels.append(i)
				datas.append(stackData["phone_name"][i])
		elif uriP == "sys":
			for i in stackData["phone_sys"]:
				labels.append(i)
				datas.append(stackData["phone_sys"][i])
		elif uriP == "sdk":
			if not stackData["phone_sdk"]:
				cursor = self.ErrRecordType[style].find(self.mongo.DBClient, {'stack_ident': stackData['ident']})
				sdks = {}
				for r in cursor:
					sdk = r['device_info'].get('sdk', 'unknown').replace('.', '_')
					if sdk not in sdks:
						sdks[sdk] = 1
					else:
						sdks[sdk] += 1
				# self.ErrStatisticsType[style].update(self.mongo.DBClient, {"id": _id}, {"$set": {'phone_sdk': sdks}})
				for i in sdks:
					labels.append(i)
					datas.append(sdks[i])
			else:
				for i in stackData["phone_sdk"]:
					labels.append(i)
					datas.append(stackData["phone_sdk"][i])
		else:
			raise HTTPError(404, "uri %s not exit"% uriP)

		ret = {
			"labels": labels,
			"datas": datas
		}
		self.write_json(ret)


class CrashInfoTable(AuthedHandler):
	url = "/crashinfo/table"

	@coroutine
	def get(self):
		print self.request.arguments
		offset = int(self.get_argument("offset"))
		limit = int(self.get_argument("limit"))

		_id = int(self.get_argument("_id"))
		style = int(self.get_argument("style"))
		key = (_id, style)
		if key in CrashInfoCache:
			stackData = CrashInfoCache.get(key)
		else:
			stackData = yield self.async_db_exec(self.ErrStatisticsType[style].find_one, {"id": _id})
		if not stackData:
			raise HTTPError(404, "ID %s style %s not exit in DB!"% (_id, style))

		total = len(stackData["record_id"])
		record_id = sorted(stackData["record_id"], reverse=True)

		query = {"id": {"$in": record_id[offset:offset+limit]}}

		cursor = self.ErrRecordType[style].find(self.mongo.DBClient, query)
		ret = []
		for d in cursor:
			r = {}
			for k in ['id', 'report_time']:
				r[k] = d.get(k)
			ret.append(r)

		ret = sorted(ret, key=lambda d:d['report_time'], reverse=True)
		self.write_json({
				"total": total,
				"limit": limit,
				"offset": offset,
				"rows": ret
			})


class DetailCrashInfo(AuthedHandler):
	url = "/crashinfo/info"

	@coroutine
	def get(self, *args, **kwargs):
		_id = int(self.get_argument("_id"))
		style = int(self.get_argument("style"))

		ret = yield self.async_db_exec(self.ErrRecordType[style].find_one, {"id": _id})
		if not ret:
			raise HTTPError(404, "ID %s style %s not exit in DB!"% (_id, style))

		if ret.get("app_debug", None):
			with open(ret["app_debug"], "rb") as f:
				app_debug = f.read()
		else:
			app_debug = "无玩家运行日志"

		try:
			app_debug.decode("utf-8")
		except:
			app_debug = "存在不可序列化字符串"

		if style == -1:
			crashAll = ret["stack_result"]
			regex = re.compile(r"Thread \d+ \(crashed\)")
			q = regex.search(crashAll)
			s1,e1 = q.span()

			regex = re.compile(r"Thread \d+")
			q = regex.search(crashAll[e1:])
			s2,e2 = q.span()
			crashThread = crashAll[:s2+e1]

			crashCon = ""
			for line in ret["stack_error"]:
				crashCon = crashCon + line + "\n"

			response = {
				"ret": True,
				"crashAll": crashAll,
				"crashThread": crashThread,
				"crashCon": crashCon,
			}
		elif style == 1:
			stack = ret['stack']
			lineFeed = ret['feature'].find('stack traceback')
			if lineFeed != -1:
				stack = ret['stack'][:lineFeed] + '\n' + ret['stack'][lineFeed:]
			response = {
				"ret": True,
				"crashAll": None,
				"crashThread": None,
				"crashCon": stack,
			}

		htmlText = u"<tr><td>设备机型</td><td>" + self.get_web_value(ret, "phone_name") + u"</td></tr>"
		htmlText += u"<tr><td>系统版本</td><td>" + self.get_web_value(ret, "phone_sys") + u"</td></tr>"
		htmlText += u"<tr><td>启动时间</td><td>" + self.get_web_value(ret["device_info"], "game_start_time") + "</td></tr>"
		htmlText += u"<tr><td>上报时间</td><td>" + self.get_web_value(ret, "report_time")[:19] + u"</td></tr>"
		htmlText += u"<tr><td>IMEI</td><td>" + self.get_web_value(ret, "imei") + u"</td></tr>"
		htmlText += u"<tr><td>版本号</td><td>" + self.get_web_value(ret, "version") + u"</td></tr>"
		htmlText += u"<tr><td>cpu型号</td><td>" + self.get_web_value(ret["device_info"], "cpu_name") + u"</td></tr>"
		htmlText += u"<tr><td>包名</td><td>" + self.get_web_value(ret["device_info"], "package_name") + u"</td></tr>"
		htmlText += u"<tr><td>可用存储空间</td><td>" + self.get_web_value(ret["device_info"], "available_memory") + "</td></tr>"
		# htmlText += u"<tr><td>cpu使用率</td><td>" + self.get_web_value(ret["device_info"], "cpu_total_rate") + u"</td></tr>"
		htmlText += u"<tr><td>sdk</td><td>" + self.get_web_value(ret["device_info"], "sdk") + u"</td></tr>"

		# htmlText += u"<tr><td>url</td><td>" + self.get_web_value(ret, "url") + u"</td></tr>"
		htmlText += u"<tr><td>platform</td><td>" + self.get_web_value(ret, "platform") + u"</td></tr>"
		htmlText += u"<tr><td>channel</td><td>" + self.get_web_value(ret, "channel") + u"</td></tr>"
		htmlText += u"<tr><td>account</td><td>" + self.get_web_value(ret, "account") + u"</td></tr>"
		htmlText += u"<tr><td>tag</td><td>" + self.get_web_value(ret, "tag") + u"</td></tr>"
		htmlText += u"<tr><td>patch</td><td>" + self.get_web_value(ret, "patch") + u"</td></tr>"
		htmlText += u"<tr><td>min_patch</td><td>" + self.get_web_value(ret, "min_path") + u"</td></tr>"
		htmlText += u"<tr><td>role</td><td>" + self.get_web_value(ret, "role") + u"</td></tr>"
		htmlText += u"<tr><td>server</td><td>" + self.get_web_value(ret, "server") + u"</td></tr>"
		response["htmlText"] = htmlText
		response["app_debug"] = app_debug
		self.write_json(response)

	def get_web_value(self, d, key, default=""):
		v = d.get(key, default)
		if v in [None, "unknown", "unknown-unknown", "Unknown", "Unknown-Unknown"]:
			return default
		if isinstance(v, (unicode, str)):
			return v
		try:
			return str(v)
		except Exception as e:
			return "??"


class CrashCommentHandler(AuthedHandler):
	url = "/crashinfo/comment"

	@coroutine
	def post(self):
		jsonData = self.get_json_data()
		_id = jsonData["_id"]
		style = jsonData["style"]
		comments = jsonData["comment"]
		data = {
			"name": self.current_user,
			"time": datetime.datetime.now(),
			"comments": comments
		}
		yield self.async_db_exec(self.ErrStatisticsType[style].update, {"id": _id}, {"$push": {"comment": data}})
		self.write_json({
			"ret": True,
			"data": data
			})