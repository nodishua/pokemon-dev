# -*- coding: utf-8 -*-
from tornado.gen import coroutine
from tornado.web import HTTPError
from collections import OrderedDict
import time
import datetime
import functools

from base import AuthedHandler
from object.scheme import *


class DashBoardHandler(AuthedHandler):
	url = "/"

	@coroutine
	def get(self):

		self.render(
			"dashboard.html",
			name = self.current_user,
			dump_count = self.statCache.get("today_dmp_count"),
			exception_count = self.statCache.get("today_exc_count"),
			versionL = self.versions,
			crash_user = len(self.statCache.get("dmp_imei")),
			exception_user = len(self.statCache.get("exc_imei")),
			tag = self.tag
		)


class DashBoardChartHandler(AuthedHandler):
	url = "/dashboard/chart"

	@coroutine
	def get(self):
		queryType = int(self.get_argument("queryType"))

		if queryType == 7 or queryType == 30:
			now = datetime.datetime.now()
			now = datetime.datetime(now.year, now.month, now.day)
			one = datetime.timedelta(days=1)

			querys = OrderedDict()
			for i in range(queryType-1, -1, -1):
				st = now - i*one
				et = st + one
				querys[st.date()] = {"report_time": {"$gte": st, "$lt": et}}

		elif queryType == 24:
			now = datetime.datetime.now()
			now = datetime.datetime(now.year, now.month, now.day, now.hour)
			one = datetime.timedelta(hours=1)

			querys = OrderedDict()
			for i in range(23, -1, -1):
				st = now - i*one
				et = st + one
				querys[st.hour] = {"report_time": {"$gte": st, "$lt": et}}

		else:
			raise HTTPError(404, "queryType is not defind")

		xAex = []
		xDmpData = []
		xExceData = []
		for x in querys:
			cd = DmpRecord.count(self.mongo.DBClient, querys[x])
			ce = ExcRecord.count(self.mongo.DBClient, querys[x])
			xAex.append(x)
			xDmpData.append(cd)
			xExceData.append(ce)

		data = {
			"xAex": xAex,
			"xDumpData": xDmpData,
			"xExceptionData": xExceData
		}
		self.write_json(data)


class DashBoardChartEfectUser(AuthedHandler):
	url = "/dashboard/efectuser"

	@coroutine
	def get(self):
		queryType = int(self.get_argument("queryType"))

		if queryType == 7 or queryType == 30:
			now = datetime.datetime.now()
			now = datetime.datetime(now.year, now.month, now.day)
			one = datetime.timedelta(days=1)

			querys = OrderedDict()
			for i in range(queryType-1, -1, -1):
				st = now - i*one
				et = st + one
				querys[st.date()] = {"report_time": {"$gte": st, "$lt": et}}

		elif queryType == 24:
			now = datetime.datetime.now()
			now = datetime.datetime(now.year, now.month, now.day, now.hour)
			one = datetime.timedelta(hours=1)

			querys = OrderedDict()
			for i in range(23, -1, -1):
				st = now - i*one
				et = st + one
				querys[st.hour] = {"report_time": {"$gte": st, "$lt": et}}

		else:
			raise HTTPError(404, "queryType is not defind")

		# userField = "server_role" if self.tag == "shuma" else "imei"
		userField = "server_role"

		xAex = []
		xDmpData = []
		xExceData = []
		for x in querys:
			xAex.append(x)

			l = DmpRecord.find(self.mongo.DBClient, querys[x], distinct=userField)
			xDmpData.append(len(l))

			l = ExcRecord.find(self.mongo.DBClient, querys[x], distinct=userField)
			xExceData.append(len(l))

		data = {
			"xAex": xAex,
			"xDumpData": xDmpData,
			"xExceptionData": xExceData
		}
		self.write_json(data)


class TodayIssueStatistics1(AuthedHandler):
	# 今日新问题
	url = "/dashboard/issuestatistics1"

	@coroutine
	def get(self):
		today = self.start2end_days()
		query = {"firsttime": {"$gte": today[0]}, "lasttime": {"$gte": today[0], "$lte": today[1]}}
		query2 = {"lasttime": {"$gte": today[0], "$lte": today[1]}}
		result = yield self.multi_async_execute([
				functools.partial(DmpStatistic.count, self.mongo.DBClient, query),
				functools.partial(ExcStatistic.count, self.mongo.DBClient, query),
				functools.partial(DmpStatistic.count, self.mongo.DBClient, query2),
				functools.partial(ExcStatistic.count, self.mongo.DBClient, query2),
			])
		issueNew = result[0] + result[1]
		issueSum = result[2] + result[3]

		ret = {
			"labels": ["今日新发现问题: %d"% issueNew, "今日总问题: %d"% issueSum],
			"datas": [issueNew, issueSum - issueNew],
			"today_time": str(today[0])
		}
		self.write_json(ret)

class TodayIssueStatistics2(AuthedHandler):
	# 今日已修复问题
	url = "/dashboard/issuestatistics2"

	@coroutine
	def get(self):
		today = self.start2end_days()
		query = {"status": True, "lasttime": {"$gte": today[0], "$lte": today[1]}}
		query2 = {"lasttime": {"$gte": today[0], "$lte": today[1]}}
		result = yield self.multi_async_execute([
				functools.partial(DmpStatistic.count, self.mongo.DBClient, query),
				functools.partial(ExcStatistic.count, self.mongo.DBClient, query),
				functools.partial(DmpStatistic.count, self.mongo.DBClient, query2),
				functools.partial(ExcStatistic.count, self.mongo.DBClient, query2),
			])
		issueHas = result[0] + result[1]
		issueSum = result[2] + result[3]

		ret = {
			"labels": ["今日已修复问题: %d"% issueHas, "今日总问题: %d"% issueSum],
			"datas": [issueHas, issueSum - issueHas],
			"today_time": str(today[0])
		}
		self.write_json(ret)


class Top3IssueHandler(AuthedHandler):
	url = "/dashboard/top3"

	@coroutine
	def get(self):
		hour = self.get_argument("hour")
		now = datetime.datetime.now()
		if hour:
			startTime = datetime.datetime(now.year, now.month, now.day, int(hour))
			endTime = datetime.datetime(now.year, now.month, now.day, int(hour), 59, 59)
		else:
			startTime = datetime.datetime(now.year, now.month, now.day)
			endTime = datetime.datetime(now.year, now.month, now.day, 23, 59, 59)
		query = {"status": True, "report_time": {"$gte": startTime, "$lte": endTime}}
		pipeline = [
			{'$match': query},
			{'$group': {'_id': "$stack_ident", 'count': {'$sum': 1}}},
		]

		cur = DmpRecord.aggregate(self.mongo.DBClient, pipeline)
		ret = sorted(cur, key=lambda x:x['count'], reverse=True)[:3]
		result = []
		for d in ret:
			data = DmpStatistic.find_one(self.mongo.DBClient, {'ident': d['_id']})
			if not data:
				continue
			result.append([d['_id'], data['feature'], -1, d['count']])

		cur = ExcRecord.aggregate(self.mongo.DBClient, pipeline)
		ret = sorted(cur, key=lambda x: x['count'], reverse=True)[:3]
		for d in ret:
			data = ExcStatistic.find_one(self.mongo.DBClient, {'ident': d['_id']})
			if not data:
				continue
			result.append([d['_id'], data['feature'], 1, d['count']])

		result = sorted(result, key=lambda r:r[3], reverse=True)[:3]
		self.write_json({"ret": True, "data": result})


class DashBoardTableHandler(AuthedHandler):
	url = "/dashboard/table"

	@coroutine
	def get(self):
		now = datetime.datetime.now()
		oneDay = datetime.timedelta(days=1)
		oneHour = datetime.timedelta(hours=1)
		query = {}

		style = int(self.get_argument("style"))
		times = self.get_argument("times", None)
		if times:
			endTime = self.get_argument("end_time")
			startTime = datetime.datetime.strptime(str(times), "%Y-%m-%d %H:%M:%S")
			endTime = datetime.datetime.strptime(str(endTime), "%Y-%m-%d %H:%M:%S")
			stackIdentL = self.ErrRecordType[style].find(self.mongo.DBClient,
					{"report_time": {"$gte": startTime, "$lt": endTime}, "status": True}, distinct="stack_ident")
			query = {"ident": {"$in": stackIdentL,},}
		else:
			days = int(self.get_argument("days"))
			if days != 0:
				endTime = datetime.datetime(now.year, now.month, now.day, 0, 0) + oneDay
				query = {"lasttime": {"$gte": endTime - oneDay*days, "$lt": endTime},}

		version = str(self.get_argument("version"))

		if version != "":
			query.update({"report_version": version,})

		processed = int(self.get_argument("processed"))
		if processed != 0:
			query.update({"status": self.ErrStatus[processed]})

		def _padding(record):
			r = {}
			r['imei_member'] = len(record.get("game_account", [])) if self.tag == "shuma" else len(record.get("imei", []))
			for k in ['id', 'feature','firsttime', 'lasttime', 'count', 'status']:
				r[k] = record.get(k)
			return r

		ret = []
		if style == 0:
			data_cursor1 = yield self.async_db_exec(DmpStatistic.find, query)
			data_cursor2 = yield self.async_db_exec(ExcStatistic.find, query)
			for item in data_cursor1:
				r = _padding(item)
				r["type"] = -1
				ret.append(r)
			for item in data_cursor2:
				r = _padding(item)
				r["type"] = 1
				ret.append(r)
		else:
			data_cursor = yield self.async_db_exec(self.ErrStatisticsType[style].find, query)
			for item in data_cursor:
				r = _padding(item)
				r["type"] = style
				ret.append(r)

		self.write_json(ret)


class ChartDataShow(AuthedHandler):
	url = "/dashboard/datashow"

	@coroutine
	def get(self):
		now = datetime.datetime.now()
		hide_time = self.get_argument("hide_time")
		oneDay = datetime.timedelta(days=1)
		oneHour = datetime.timedelta(hours=1)

		time_str = str(hide_time)
		if len(time_str) > 2:
			startTime = datetime.datetime.strptime(time_str, "%Y-%m-%d")
			endTime = startTime + oneDay
		else:
			hour = int(hide_time)
			if hour > 23:
				raise HTTPError(404, "hour is not correct")
			startTime = datetime.datetime(now.year, now.month, now.day, hour)
			if hour > now.hour:
				startTime = startTime - oneDay
			endTime = startTime + oneHour

		self.render(
			"datashow.html",
			name = self.current_user,
			versionL = self.versions,
			hide_time = str(startTime),
			end_time = str(endTime),
			hide_style = self.get_argument("hide_style"),
			tag = self.tag
		)
