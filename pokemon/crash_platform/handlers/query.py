# -*- coding: utf-8 -*-

from tornado.gen import coroutine
from tornado.web import HTTPError

from base import AuthedHandler
from object.scheme import *

import time
import json
import datetime
import hashlib
import binascii
import msgpack
from bson import ObjectId


class QueryPageHandler(AuthedHandler):
	url = "/querypage"
	cacheIntervalTime = None
	servsListCache = []

	@coroutine
	def get(self):
		ctime = int(time.time())
		cit = QueryPageHandler.cacheIntervalTime
		if cit == None or (ctime - cit) > 30*60:
			QueryPageHandler.cacheIntervalTime = ctime
			serv1 = yield self.async_db_exec(DmpRecord.find, {}, distinct='server')
			serv2 = yield self.async_db_exec(ExcRecord.find, {}, distinct='server')
			QueryPageHandler.servsListCache = sorted(list(set(serv1) | set(serv2)))

		self.render(
				"query.html",
				name = self.current_user,
				tag = self.tag,
				servers = QueryPageHandler.servsListCache
			)


class RoleQueryHandler(AuthedHandler):
	url = "/querypage/role"

	@coroutine
	def get(self):
		server = self.get_argument("server")
		role = self.get_argument("role")
		query_time = self.get_argument("query_time")

		if len(role) == 24:
			server_role = server + "-" + role
			query = {"server_role": server_role,}
		else:
			query = {"server": server, "account": role}
		if query_time != u"0":
			p = self.start2end_days(int(query_time))
			query.update({"report_time": {"$gte": p[0], "$lte": p[1]}})

		dmpData = yield self.async_db_exec(DmpRecord.find, query)
		exreData = yield self.async_db_exec(ExcRecord.find, query)
		r = []

		for i in dmpData:
			r.append(i)
		for i in exreData:
			r.append(i)

		sumRepoet = len(r)
		stackIdent = {}
		for data in r:
			if data["stack_ident"] in stackIdent:
				stackIdent[data["stack_ident"]][1] += 1
				stackIdent[data["stack_ident"]][2] = min(stackIdent[data["stack_ident"]][2], data["report_time"])
				stackIdent[data["stack_ident"]][3] = max(stackIdent[data["stack_ident"]][3], data["report_time"])
				continue
			f = l = data["report_time"]
			stackIdent[data["stack_ident"]] = [data["feature"], 1, f, l]
		ret = {
			"sumReport": sumRepoet,
			"stackIdent": stackIdent,
		}
		self.write_json(ret)


class FeedBackQueryHandler(AuthedHandler):
	url = "/feedback/page"
	cacheIntervalTime = None
	servsListCache = []

	@coroutine
	def get(self):
		ctime = int(time.time())
		cit = FeedBackQueryHandler.cacheIntervalTime
		if cit == None or (ctime - cit) > 15*60:
			FeedBackQueryHandler.cacheIntervalTime = ctime
			servs = yield self.async_db_exec(FeedBackRecord.find, {}, distinct='game_server')
			FeedBackQueryHandler.servsListCache = sorted(servs)

		self.render(
				"feedback.html",
				name = self.current_user,
				tag = self.tag,
				servers = FeedBackQueryHandler.servsListCache,
				autoTag = self.get_argument('replay_info', 'nil')
			)


class FeedBackTableHandler(AuthedHandler):
	url = '/feedback/table'

	@coroutine
	def get(self):
		_id = self.get_argument('_id')
		_id = ObjectId(_id)
		query = {"_id": _id}

		status = int(self.get_argument('status'))
		if status == 1:
			up = {'$set': {"status": True}}
		else:
			up = {'$set': {"status": False}}

		yield self.async_db_exec(FeedBackRecord.update, query, up)
		data = yield self.async_db_exec(FeedBackRecord.find_one, query)
		data._id = binascii.hexlify(data._id.binary)

		self.write_json({'ret': True, 'data': data})

	@coroutine
	def post(self):
		cond = self.get_json_data()
		servName = cond.get('servName', 'all')
		role = cond.get('role', 'all')
		stime, etime = cond.get('stime', ''), cond.get('etime', '')
		tp, status = cond.get('type', 'all'), int(cond.get('status', 0))

		query = {}
		if not (servName == '' or servName == 'all'):
			query['game_server'] = servName

		if not (role == '' or role == 'all'):
			if len(role) == 24:
				query['role_id'] = role
			else:
				roleID = None
				try:
					roleID = int(role)
				except ValueError as e:
					pass

				if roleID is None:
					query['role_name'] = role
				else:
					query['role_uid'] = roleID

		if stime or etime:
			query['time'] = {}

			if stime:
				s = datetime.datetime.strptime(stime, '%Y-%m-%d')
				query['time']['$gte'] = s
			if etime:
				e = datetime.datetime.strptime(etime+' 23:59:59', '%Y-%m-%d %H:%M:%S')
				query['time']['$lte'] = e

		if tp != 'all':
			query['classify'] = tp

		if status == 1 or status == -1:
			query['status'] = {1: True, -1: False}.get(status)

		data = yield self.async_db_exec(FeedBackRecord.find, query)

		ret = []
		for item in data:
		 	item._id = binascii.hexlify(item._id.binary)
		 	ret.append(item)

		self.write_json({'data': ret})


class GMRPCHandler(AuthedHandler):
	url = "/rpc/(.*)"
	HttpClient = None

	@coroutine
	def get(self, tp):
		pass

	@coroutine
	def post(self, tp):
		if not GMRPCHandler.HttpClient:
			from tornado.curl_httpclient import CurlAsyncHTTPClient
			GMRPCHandler.HttpClient = CurlAsyncHTTPClient()

		if tp == "_send_role_mail":
			# url = "192.168.1.96:39098/gm_cmd/_send_role_mail"
			data = self.get_json_data()
			if data['server'].startswith('game.cn_qd.'):
				url = "0.0.0.0:38081/gm_cmd/_send_role_mail"
			elif data['server'].startswith('game.kr.'):
				url = "192.168.1.4:38080/gm_cmd/_send_role_mail"
			else:
				url = "0.0.0.0:38080/gm_cmd/_send_role_mail"
			md5 = hashlib.md5("crash-gm-admin-asdzxc")
			data['auth'] = md5.hexdigest()
			# close attach
			data['attach'] = "{}"
			rep = yield GMRPCHandler.HttpClient.fetch(url, method="POST", headers={"Connection": "close"}, body=json.dumps(data))
			self.write(rep.body)
		else:
			raise HTTPError(404, reason="wrong tp")


class BallteRportHandler(AuthedHandler):
	url = "/battle_log"
	BattleType = {
		1: "arena",
		2: "craft",
		3: "union_fight",
		4: "cross_craft",
		5: "endless",
		999: "gate"
	}

	@coroutine
	def get(self):
		tp = self.get_argument("type", None)

		if tp == "download":
			play_id = self.get_argument("play_id")
			data = yield self.async_db_exec(BattleReport.find_one, {"play_id": play_id})
			if not data:
				raise HTTPError("NO %s"% play_id)

			file = [self.BattleType.get(data["type"], None), data["play_record"]]
			file = msgpack.packb(file, use_bin_type=True)

			self.write(file)

		else:
			self.render("battle.html", name=self.current_user, tag=self.tag)

	@coroutine
	def post(self):
		r = self.get_json_data()

		stime, etime = r['stime'], r['etime']
		s = datetime.datetime.strptime(stime, '%Y-%m-%d')
		e = datetime.datetime.strptime(etime+' 23:59:59', '%Y-%m-%d %H:%M:%S')

		order = self.PymongoOrder[r['order']]
		sort = (r["sort"], order)
		query = {"report_time": {"$gte": s, "$lte": e}}

		total = yield self.async_db_exec(BattleReport.count, query)
		data = yield self.async_db_exec(BattleReport.find, query, sort=sort, limit=r["limit"], skip=r["offset"])

		result = []
		id = r["offset"] + 1
		for d in data:
			d.pop("_id")
			d.pop("play_record", None)
			d["type"] = self.BattleType.get(d["type"], None)
			d["id"] = id
			id += 1
			result.append(d)

		self.write_json({
				"limit": r["limit"],
				"offset": r["offset"],
				"rows": result,
				"total": total
			})

class PlayReportQueryHandler(AuthedHandler):
	url = "/play_report/query"

	@coroutine
	def get(self):
		tp = self.get_argument("type", None)
		if tp == "download":
			play_id = self.get_argument("play_id")
			data = yield self.async_db_exec(PlayReport.find_one, {"play_id": play_id})
			if not data:
				raise HTTPError("NO %s"% play_id)
			file = data["play_record"]

			self.write(file)
		else:
			self.render("play.html", name=self.current_user, tag=self.tag)

	@coroutine
	def post(self):
		r = self.get_json_data()
		stime, etime = r['stime'], r['etime']
		s = datetime.datetime.strptime(stime, '%Y-%m-%d')
		e = datetime.datetime.strptime(etime+' 23:59:59', '%Y-%m-%d %H:%M:%S')

		order = self.PymongoOrder[r['order']]
		sort = (r["sort"], order)
		query = {"report_time": {"$gte": s, "$lte": e}}
		if r['role_id']:
			query['role_id'] = r['role_id']
		total = yield self.async_db_exec(PlayReport.count, query)
		data = yield self.async_db_exec(PlayReport.find, query, sort=sort, limit=r["limit"], skip=r["offset"])

		result = []
		id = r["offset"] + 1
		for d in data:
			d.pop("_id")
			d.pop("play_record", None)
			d["id"] = id
			id += 1
			result.append(d)

		self.write_json({
				"limit": r["limit"],
				"offset": r["offset"],
				"rows": result,
				"total": total
			})
