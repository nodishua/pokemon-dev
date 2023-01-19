# -*- coding: utf-8 -*-
from __future__ import absolute_import, division

from tornado.gen import coroutine
from tornado.web import HTTPError
from framework import *
import framework

from gm.object.loganalyzer.archive import *
from .base import AuthedHandler

import fabric
import copy
from collections import defaultdict


servDefines = {
	'game.dev.2': {
		'ip': 'test@192.168.1.98:22',
		'connect_kwargs': {
			'password': '123456'
		},
		'deploy': '/home/shuma_06/deploy_dev',
		'source': '/home/shuma_06/server'
	}
}

class AreaDataHanlder(AuthedHandler):
	url = '/area_data'

	@coroutine
	def get(self):
		self.render_page('_areadata.html')

	@coroutine
	def post(self):
		result = []
		# for name in servDefines:
		# 	data = {}
		# 	data['servName'] = name

		# 	cfg = servDefines[name]
		# 	conn = fabric.Connection(cfg['ip'], connect_kwargs=cfg['connect_kwargs'])
		# 	cmd = 'cd %s && supervisorctl status | grep game_server'% cfg['deploy']
		# 	try:
		# 		out = conn.run(cmd).stdout
		# 		status = out.split()[1]
		# 	except Exception, e:
		# 		print e
		# 		status = 'ERROR'

		# 	data['status'] = status
		# 	data['opendate'] = '2019-07-01 15:00:00'
		# 	data['opendays'] = 12
		# 	result.append(data)

		self.write_json(result)


# Items and other consumption
class LogItemQueryHandler(AuthedHandler):
	url = '/logitem'

	@coroutine
	def post(self):
		r = self.get_json_data()
		server_key = r.get('servName', None)
		role_id = r.get('roleID', None)
		startDate, endDate, t = r['startDate'], r['endDate'], r['type']
		huodongkeys = r['huodongs']

		columns = [
			{'field': 'time', 'title': 'time', 'sortable': True},
			{'field': 'role_id', 'title': 'Character ID'},
			{'field': 'role_uid', 'title': 'Character UID'},
			{'field': 'from_key', 'title': 'Active ID'},
			{'field': 'info', 'title': 'details', 'align': 'center'},
		]

		sd, ed = int2date(startDate), int2date(endDate)

		query = {'language': framework.__language__}
		if server_key is not None:
			query['server_key'] = server_key

		if role_id is not None:
			if len(role_id) == 24:
				query['role_id'] = role_id
			else:
				query['role_uid'] = role_id

		def determineType(obj, t):
			if t == 'all':
				return (getattr(obj, 'gain'), getattr(obj, 'cost'))
			return (getattr(obj, t),)

		result = []
		while ed >= sd:
			dateInt = date2int(sd)
			archives = DBFind(self.mongo_client, DBLogRoleArchive, query)
			for a in archives:
				dic = {'role_id': a.role_id, 'role_uid': a.role_uid}

				for item in determineType(a, t):
					for k in item:
						if huodongkeys and k not in huodongkeys:
							continue
						dic['from_key'] = k
						for s in item[k]:
							dic['time'] = s
							for f in item[k][s]:
								dic['info'] = f
								result.append(copy.deepcopy(dic))
			sd += OneDay

		self.write({
				'columns': columns,
				'data': result
			})

GameItemNameMap = {
	'Items': 'tool',
	'Fragments': 'Fragmentation',
	'coins': 'Special currency',
	'Equips': 'equipment',
	'MetalOrHeldItem': 'Alloy, carrying props'
}
class LogItemArchiveHandler(AuthedHandler):
	url = '/logitem_archive'

	@coroutine
	def get(self):
		keys = self.mongo_client.LogItemArchive.find({}).distinct('from_key')
		self.render_page('_datamonitor.html', huodongkeys=keys)

	@coroutine
	def post(self):
		r = self.get_json_data()
		server_key = r.get('servName', None)
		startDate, endDate, t = r['startDate'], r['endDate'], r['type']
		huodongkeys = r['huodongs']

		columns = [
			{'field': 'time', 'title': 'time', 'sortable': True},
			{'field': 'from_key', 'title': 'Active ID'},
			{'field': '__count__', 'title': 'frequency'},
			{'field': '__participation__', 'title': 'The number of participants'},
			{'field': 'rmb', 'title': 'RMB'},
			{'field': 'gold', 'title': 'GOLD'},
		]

		sd, ed = int2date(startDate), int2date(endDate)

		query = {}
		if server_key is not None:
			query.update({'server_key': server_key})

		result = []
		fields = ['__count__', '__participation__', 'rmb', 'gold']
		while ed >= sd:
			dateInt = date2int(sd)

			query.update({'date': dateInt})
			if huodongkeys:
				query.update({'from_key': {'$in': huodongkeys}})

			archives = DBFind(self.mongo_client, DBLogItemArchive, query)
			for a in archives:
				dic = {'from_key': a.from_key}

				if t == "gain":
					items = a.gain
				elif t == "cost":
					items = a.cost
				else:
					raise HTTPError(404, "t %s"% t)

				for time in items:
					dic['time'] = str(int2datetime(int(time)))[:-3]

					for k, v in items[time].items():
						if k not in fields:
							fields.append(k)
							columns.append({'field': k, 'title': GameItemNameMap.get(k, k)})
						dic[k] = len(v) if k == '__participation__' else v

					result.append(copy.deepcopy(dic))
			sd += OneDay

		result = sorted(result, key=lambda dic: dic['time'], reverse=True)
		self.write({
				'columns': columns,
				'data': result
			})


# Level distribution
class LevelCheckHandler(AuthedHandler):
	url = r'/levelchart'

	@coroutine
	def post(self):
		r = self.get_json_data()
		server_key = r.get('servName', None)
		startDate, endDate = r['startDate'], r['endDate']

		query = {"last_time": {"$gte": 1575388800}}
		if server_key is not None:
			query['server_key'] = server_key
		# sd, ed = int2date(startDate), int2date(endDate)

		data = self.mongo_client.LogRole.find(query)
		roleLevels = defaultdict(int)
		for role in data:
			if int(role['level']) == 1:
				roleLevels['l1'] += 1
			else:
				lev = int(int(role['level']) / 10)
				roleLevels[lev] += 1

		result = []
		xAxes = ['l1',0,1,2,3,4,5,6,7,8,9,10]
		for x in xrange(len(xAxes)):
			result.append(roleLevels.get(xAxes[x], 0))
			if xAxes[x] == 'l1':
				xAxes[x] = '1级'
			elif xAxes[x] == 0:
				xAxes[x] = '2-9级'
			else:
				xAxes[x] = '{0}0-{0}9级'.format(xAxes[x])
		# test
		# import random
		# for i in xrange(len(result)):
		# 	result[i] = random.randint(0, 5000)
		# print result
		self.write({'data': result, 'xAxes': xAxes})


# VIP level distribution
class VipLevelCheckHandler(AuthedHandler):
	url = r'/viplevelchart'

	@coroutine
	def get(self):
		pass