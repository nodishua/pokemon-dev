#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2017 TianJi Information Technology Inc.

Operation Handlers
'''
from __future__ import absolute_import

from .base import AuthedHandler
from gm.util import *
from gm.object.db import *
from gm.object.account import DBAccount
from gm.object.archive import DBArchive, DBDailyArchive
from gm.object.order import DBOrder

import datetime
import time
from itertools import izip_longest
from urllib2 import HTTPError

from tornado.gen import coroutine, Return
from collections import defaultdict

import framework
from framework import *


# 运营数据
class OperationHandler(AuthedHandler):
	url = r'/operation_data'

	@coroutine
	def run(self):
		_ajax = self.get_argument("_ajax", False)
		self.renderHandler(_ajax, "operation.html", channelList=True)

		servName = self.get_argument("servName", None)
		channel = self.get_argument("channel", None)
		subChannel = self.get_argument("subChannel", None)

		ret = {
			"warrior": 30,
			"tank": 325,
			"Mage": 798,
			"supp": 899
		}
		self.write(ret)


# Player level distribution
class LevelCheckHandler(AuthedHandler):
	url = r'/level_check'

	@coroutine
	def run(self):
		_ajax = self.get_argument("_ajax", False)
		self.renderHandler(_ajax, "operation.html", channelList=True)

		servName = self.get_argument("servName", None)
		channel = self.get_argument("channel", None)
		subChannel = self.get_argument("subChannel", None)

		ret = {
			1: 83,
			2: 89,
			5: 989,
			38: 100,
			98: 32,
			100: 32
		}

		self.write(ret)


# Battlepower rankings
class FightingRankHandler(AuthedHandler):
	url = r'/fighting_rank'

	@coroutine
	def get(self):
		servName = self.get_argument("servName", None)

		sort = self.get_argument('sort', None)
		order = self.get_argument('order', None)
		offset = int(self.get_argument("offset", 0))
		limit = int(self.get_argument("limit", 0))

		if servName == "All":
			raise HTTPError(404, reason="servName error")

		result = []
		total = 0

		if limit:
			ret = yield self.userGMRPC.gmGetGameRank(self.session, servName, 'fight')
			ret = ret['view']['rank']
			total = len(ret)
			for i, d in enumerate(ret):
				d['role']['fighting_point'] = d.pop('fighting_point')
				d['role']['rank_id'] = i + 1
				result.append(d['role'])

			if sort:
				result = sorted(result, key=lambda r: r[sort], reverse=True if order=='asc' else False)

			result = result[offset: offset+limit]

			# print 'rrrrrrrrrrrrr', result
			rows = hexlifyDictField(result)
			self.write({
				"total": total,
				"rows": rows,
				"limit": limit,
				"offset": offset
			})
		else:
			 # 'fighting_point': 269233,
		  #   'role': {
		  #     'name': '\xe7\x82\xb9\xe7\x82\xb9\xe6\xbb\xb4\xe6\xbb\xb4',
		  #     'level': 100,
		  #     'frame': 1,
		  #     'title': 17,
		  #     'vip_level': 12,
		  #     'logo': 1,
		  #     'id': '\\\xba\xcf5\x80\xae\x88\x0f\x96\x10\n\x13
			columns = [
				{'field': 'rank_id', 'title': 'rank', 'sortable': True},
				{'field': 'id', 'title': 'Role ID'},
				{'field': 'name', 'title': 'role name'},
				{'field': 'level', 'title': 'level'},
				{'field': 'vip_level', 'title': 'VIP', 'sortable': True},
				{'field': 'fighting_point', 'title': 'combat power'},
				{'field': 'title', 'title': 'title'},
				{'field': 'frame', 'title': 'frame'},
				{'field': 'logo', 'title': 'logo'},
			]

			columns = self.setLocalColumns(columns)
			self.write({'columns': columns,})


# Arena ranking
class PWRankHandler(AuthedHandler):
	url = r'/arena_rank'

	@coroutine
	def get(self):
		servName = self.get_argument("servName", None)
		sort = self.get_argument('sort', None)
		order = self.get_argument('order', None)
		offset = int(self.get_argument("offset", 0))
		limit = int(self.get_argument("limit", 0))

		if servName == "All":
			raise HTTPError(404, reason="servName error")

		result = []
		total = 0

		if limit:
			ret = yield self.userGMRPC.gmGetGameRank(self.session, servName, 'arena')
			result = ret['view']['rank']

			total = len(result)
			if sort:
				result = sorted(result, key=lambda r: r[sort], reverse=True if order=='asc' else False)

			result = result[offset: offset+limit]

			rows = hexlifyDictField(result)
			self.write({
				"total": total,
				"rows": rows,
				"limit": limit,
				"offset": offset
			})

		else:
			columns = [
				{'field': 'rank', 'title': '排名', 'sortable': True},
				{'field': 'name', 'title': '名称'},
				{'field': 'level', 'title': '等级'},
				{'field': 'role_db_id', 'title': 'db_id'},
				{'field': 'record_id', 'title': 'record_id'},
				{'field': 'fighting_point', 'title': 'fighting_point'},
				{'field': 'frame', 'title': 'frame'},
				{'field': 'display', 'title': 'display'},
				{'field': 'logo', 'title': 'logo'},
			]

			columns = self.setLocalColumns(columns)
			self.write({'columns': columns})


# Collection
class PokedexRankHandler(AuthedHandler):
	url = r'/pokedex_rank'

	@coroutine
	def get(self):
		servName = self.get_argument("servName", None)
		sort = self.get_argument('sort', None)
		order = self.get_argument('order', None)
		offset = int(self.get_argument("offset", 0))
		limit = int(self.get_argument("limit", 0))

		if servName == "All":
			raise HTTPError(404, reason="servName error")

		result = []
		total = 0

		if limit:
			ret = yield self.userGMRPC.gmGetGameRank(self.session, servName, 'pokedex')
			# Sort
			ret = sorted(ret['view']['rank'], key=lambda d: d["pokedex"], reverse=True)

			for i, d in enumerate(ret):
				d['role']['pokedex'] = d.pop('pokedex')
				d['role']['rank_id'] = i + 1
				result.append(d['role'])

			total = len(result)
			if sort:
				# Sort
				result = sorted(result, key=lambda r: r[sort], reverse=True if order=='asc' else False)
			result = result[offset: offset+limit]

			rows = hexlifyDictField(result)
			self.write({
				"total": total,
				"rows": rows,
				"limit": limit,
				"offset": offset
			})

		else:
			# {
		 #        'role': {
		 #          'name': 'zxf12',
		 #          'level': 100,
		 #          'frame': 1,
		 #          'title': 1,
		 #          'vip_level': 12,
		 #          'logo': 1,
		 #          'id': '\\\xbdk\xdd\x80\xae\x88|*\x82\xdc\xb3'
		 #        },
		 #        'pokedex': 101
		 #      },
			columns = [
				{'field': 'rank_id', 'title': 'rank', 'sortable': True,},
				{'field': 'pokedex', 'title': 'Favorites'},
				{'field': 'name', 'title': 'Player Name'},
				{'field': 'id', 'title': 'roleID'},
				{'field': 'level', 'title': 'Player Level'},
				{'field': 'vip_level', 'title': 'VIP'},
				{'field': 'title', 'title': 'title'},
				{'field': 'frame', 'title': 'frame'},
				{'field': 'logo', 'title': 'logo'},
			]

			columns = self.setLocalColumns(columns)
			self.write({'columns': columns})


# # Star rankings
# class StarsRankHandler(AuthedHandler):
# 	url = r'/stars_rank'

# 	@coroutine
# 	def get(self):
# 		servName = self.get_argument("servName", None)
# 		offset = int(self.get_argument("offset", 0))
# 		limit = int(self.get_argument("limit", 0))

# 		if servName == "All":
# 			raise HTTPError(404, reason="servName error")



# 		fields = ['roleID', 'unknown', 'name', 'level', 'fight_power', 'union_name', 'stars', 'logo_frame']

# 		result = []
# 		total = 0

# 		if limit:
# 			ret = yield self.userGMRPC.gmGetGameRank(self.session, servName, 'star')
# 			ret = ret['view']['rank']
# 			total = len(ret)
# 			start = offset * limit
# 			for t in ret:
# 				start = start + 1
# 				r = {'id': start}
# 				for i, items in enumerate(t):
# 					r[fields[i]] = items
# 				result.append(r)

# 			rows = hexlifyDictField(result)
# 			self.write({
# 				"total": total,
# 				"rows": rows,
# 				"limit": limit,
# 				"offset": offset
# 			})
# 		else:
# 			columns = [
# 				{'field': 'id', 'title': 'ranking'},
# 				{'field': 'roleID', 'title': 'role ID'},
# 				{'field': 'name', 'title': 'role name'},
# 				{'field': 'level', 'title': 'level'},
# 				{'field': 'fight_power', 'title': 'fighting power'},
# 				{'field': 'union_name', 'title': 'Union'},
# 				{'field': 'stars', 'title': 'level star'},
# 			]

# 			columns = self.setLocalColumns(columns)
# 			self.write({
# 				'columns': columns,
# 			})


# # Beast Training Ranking
# class CardNumRankHandler(AuthedHandler):
# 	url = r'/cardNum_rank'

# 	@coroutine
# 	def get(self):
# 		servName = self.get_argument("servName", None)

# 		sort = self.get_argument('sort', None)
# 		order = self.get_argument('order', None)
# 		offset = int(self.get_argument("offset", 0))
# 		limit = int(self.get_argument("limit", 0))

# 		if servName == "All":
# 			raise HTTPError(404, reason="servName error")

# 		fields = ['roleID', 'unknown', 'name', 'level', 'vip_level', 'union_name', 'cardNum', 'logo_frame']

# 		result = []
# 		total = 0

# 		if limit:
# 			ret = yield self.userGMRPC.gmGetGameRank(self.session, servName, 'cardNum')
# 			ret = ret['view']['rank']
# 			total = len(ret)
# 			start = offset * limit
# 			for t in ret:
# 				start = start + 1
# 				r = {'id': start}
# 				for i, items in enumerate(t):
# 					if fields[i] == 'cardNum':
# 						from game.object.game.rank import FightGoVal_Max
# 						r[fields[i]] = items / FightGoVal_Max
# 					else:
# 						r[fields[i]] = items
# 				result.append(r)

# 			if sort:
# 				result = sorted(result, key=lambda r: r[sort], reverse=True if order=='asc' else False)

# 			rows = hexlifyDictField(result)
# 			self.write({
# 				"total": total,
# 				"rows": rows,
# 				"limit": limit,
# 				"offset": offset
# 			})
# 		else:
# 			columns = [
			# {'field': 'id', 'title# {'field': 'id', 'title': 'ranking', 'sortable': True},
			# {'field': 'roleID', 'title': 'role ID'},
			# {'field': 'name', 'title': 'role name'},
			# {'field': 'level', 'title': 'level'},
			# {'field': 'vip_level', 'title': 'VIP', 'sortable': True},
			# {'field': 'union_name', 'title': 'Union'},
			# {'field': 'cardNum', 'title': 'Number of cards'},e': 'ranking'},
			# {'field': 'roleID', 'title': 'role ID'},
			# {'field': 'name', 'title': 'role name'},
			# {'field': 'level', 'title': 'level'},
			# {'field': 'fight_power', 'title': 'fighting power'},
			# {'field': 'union_name', 'title': 'Union'},
			# {'field': 'stars', 'title': 'level star'},
# 			]

# 			columns = self.setLocalColumns(columns)
# 			self.write({
# 				'columns': columns,
# 			})


# # Trial rankings
# class TowerRankHandler(AuthedHandler):
# 	url = r'/trails_rank'

# 	@coroutine
# 	def get(self):
# 		servName = self.get_argument("servName", None)

# 		sort = self.get_argument('sort', None)
# 		order = self.get_argument('order', None)
# 		offset = int(self.get_argument("offset", 0))
# 		limit = int(self.get_argument("limit", 0))

# 		if servName == "All":
# 			raise HTTPError(404, reason="servName error")

# 		fields = ['roleID', 'unknown', 'name', 'level', 'vip_level', 'union_name', 'score', 'logo_frame']

# 		result = []
# 		total = 0

# 		if limit:
# 			ret = yield self.userGMRPC.gmGetGameRank(self.session, servName, 'yuanzheng')
# 			ret = ret['view']['rank']
# 			total = len(ret)
# 			start = offset * limit
# 			for t in ret:
# 				start = start + 1
# 				r = {'id': start}
# 				for i, items in enumerate(t):
# 					if fields[i] == 'score':
# 						from game.object.game.rank import YzRankFloor_Max
# 						score = items / 10000000000
# 						day_point = score / YzRankFloor_Max
# 						yz_pass_floor = score % YzRankFloor_Max
# 						r['tower'] = yz_pass_floor
# 						r['day_point'] = day_point
# 					else:
# 						r[fields[i]] = items
# 				result.append(r)

# 			if sort:
# 				result = sorted(result, key=lambda r: r[sort], reverse=True if order=='asc' else False)

# 			rows = hexlifyDictField(result)
# 			self.write({
# 				"total": total,
# 				"rows": rows,
# 				"limit": limit,
# 				"offset": offset
# 			})
# 		else:
# 			columns = [
				# {'field': 'id', 'title': 'rank', 'sortable': True},
				# {'field': 'roleID', 'title': 'role ID'},
				# {'field': 'name', 'title': 'role name'},
				# {'field': 'level', 'title': 'level'},
				# {'field': 'vip_level', 'title': 'VIP', 'sortable': True},
				# {'field': 'union_name', 'title': 'Union'},
				# {'field': 'tower', 'title': 'tower'},
				# {'field': 'day_point', 'title': 'Daily points'},
# 			]

# 			columns = self.setLocalColumns(columns)
# 			self.write({
# 				'columns': columns,
# 			})


# # Union rankings
# class UnionRankHandler(AuthedHandler):
# 	url = r'/union_rank'

# 	@coroutine
# 	def get(self):
# 		servName = self.get_argument("servName", None)
# 		offset = int(self.get_argument("offset", 0))
# 		limit = int(self.get_argument("limit", 0))

# 		if servName == "All":
# 			raise HTTPError(404, reason="servName error")

# 		columns = [
			# {'field': 'ID', 'title': 'ranking'},
			# {'field': 'id', 'title': 'Union ID'},
			# {'field': 'name', 'title': 'Union Name'},
			# {'field': 'level', 'title': 'Union Level'},
			# {'field': 'members', 'title': 'Number of union members'},
			# {'field': 'intro', 'title': 'Introduction to the Union'},
			# {'field': 'contrib', 'title': 'Total contribution value'},
			# {'field': 'day_contrib', 'title': 'Day Contrib'},
			# {'field': 'join_type', 'title': 'Join type'},
			# {'field': 'join_level', 'title': 'Join level limit'},
# 		]

# 		ret = []
# 		total = 0

# 		if limit:
# 			ret = yield self.userGMRPC.gmGetGameRank(self.session, servName, 'union')
# 			ret = ret['view']['rank']
# 			total = len(ret)
# 			start = offset * limit
# 			for t in ret:
# 				start = start + 1
# 				t['ID'] = start
# 				# r = {'ID': start}
# 				# for i, items in enumerate(t):
# 				# 	r[fields[i]] = items
# 				# result.append(r)

# 			rows = hexlifyDictField(ret)
# 			self.write({
# 				"total": total,
# 				"rows": rows,
# 				"limit": limit,
# 				"offset": offset
# 			})
# 		else:
# 			columns = [
				# {'field': 'ID', 'title': 'ranking'},
				# {'field': 'id', 'title': 'Union ID'},
				# {'field': 'name', 'title': 'Union Name'},
				# {'field': 'level', 'title': 'Union Level'},
				# {'field': 'members', 'title': 'Number of union members'},
				# {'field': 'intro', 'title': 'Introduction to the Union'},
				# {'field': 'contrib', 'title': 'Total contribution value'},
				# {'field': 'day_contrib', 'title': 'Day Contrib'},
				# {'field': 'join_type', 'title': 'Join type'},
				# {'field': 'join_level', 'title': 'Join level limit'},
# 			]

# 			columns = self.setLocalColumns(columns)
# 			self.write({
# 				'columns': columns,
# 			})
