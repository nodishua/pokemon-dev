# -*- coding: utf-8 -*-
from tornado.gen import coroutine

from base import AuthedHandler
from analyprocess.server import Server as analyServer
from object.scheme import *


class DBViewPageHandler(AuthedHandler):
	url = "/dbview"

	@coroutine
	def get(self):
		self.render(
			"dbview.html",
			name = self.current_user,
			tag = self.tag
			)


class ManualAnalysis(AuthedHandler):
	url = "/db/manualanalysis"

	@coroutine
	def get(self, *args, **kwargs):
		file = self.get_argument("file")
		_id = int(self.get_argument("_id"))

		if file == "dmp":
			yield self.async_execute(analyServer.handleDmp, self.mongo.DBClient, {"id": _id})
			ret = {"ret": True,}
		elif file == "so":
			yield self.async_execute(analyServer.handleSymbol, self.mongo.DBClient, {"id": _id})
			ret = {"ret": True,}
		else:
			ret = {
					"ret": False,
					"error": "Analysis failed, please refresh！"
				}

		self.write_json(ret)


class DBTableViewHandler(AuthedHandler):
	url = r"/db/table_views/(.+)"

	@coroutine
	def post(self, dbc):
		jsonData = self.get_json_data()
		search = jsonData["search"]

		if dbc == "upfile_db":
			time_field = "time"
		elif dbc == "dmp_db" or dbc == "exre_db":
			time_field = "report_time"
		elif dbc == "dmpst_db" or dbc == "exst_db":
			time_field = "lasttime"
		else:
			raise HTTPError(404, "Not dbc!!!")

		query = self.makeTimeQuery(time_field, jsonData["date_start"], jsonData["date_end"])
		if search.isdigit():
			query = {"id": int(search)}

		collection = self.Collections[dbc]
		data_cursor = yield self.async_db_exec(collection.find,
			sort=(jsonData["sort"], self.PymongoOrder[jsonData["order"]]), limit=jsonData["limit"],
			skip=jsonData["offset"])

		total = collection.count(self.mongo.DBClient, query)
		datas = []
		for data in data_cursor:
			data.pop("_id")
			if dbc == 'dmp_db':
				data.pop("file_content", None)
				data.pop("stack_result", None)
				data.pop("stack_error", None)
			datas.append(data)

		res = {
			"rows": datas,
			"limit": jsonData["limit"],
			"offset": jsonData["offset"],
			"total": total,
		}
		self.write_json(res)

	def makeTimeQuery(self, time_field, date_start=None, date_end=None):
	    if date_start and date_end:
	        date_start = datetimeSet(date_start)
	        date_end = datetimeSet(date_end)
	        query = {time_field: {"$gte": date_start, "$lte": date_end}}
	        return query
	    elif date_start:
	        date_start = datetimeSet(date_start)
	        query = {time_field: {"$gte": date_start}}
	        return query
	    elif date_end:
	        date_end = datetimeSet(date_end)
	        query = {time_field: {"$lte": date_end}}
	        return query
	    query = {}
	    return query
