# -*- coding: utf-8 -*-

from __future__ import absolute_import

from .mongo import Model, IncModel


class Statistics(Model):
	Collection = 'statistics'
	Indexes = [
		{"index": "key", "unique": True},
	]

	@staticmethod
	def default_document():
		return {
			'key': None,
			'value': None,
		}


class Account(Model):
	Collection = 'account'
	Indexes = [
		{"index": "name", "unique": True},
	]

	@staticmethod
	def default_document():
		return {
			'name': '',
			'password': '',
		}

	@classmethod
	def init(cls, client):
		cls.create_index(client)

		"""没有注册用户接口，给个默认的用户名"""
		if not cls.find_one(client, {"name": "admin"}):
			cls.insert_one(client, {"name": "admin", "password": "qq123456..z"})


class SymbolFile(IncModel):
	Collection = 'symbolfile'
	Indexes = [
		{"index": "time"},
		{"index": "status"},
		{"index": "platform"},
		{"index": "version"},
	]

	@staticmethod
	def default_document():
		return {
			'id': 0,
			'path': '', # .so file path
			'name': '', # .so file name
			'time': None,
			'status': False,
			'symbol_nums': '',
			'platform': '', # 手机的类型，ios，android
			'version': '',
			'package_name': '',
			'game_name': '',
		}


class DmpRecord(IncModel):
	Collection = 'dmprecord'
	Indexes = [
		{"index": "id", "unique": True},
		{"index": "time"},
		{"index": "status"},
		{"index": "version"},
		{"index": "imei"},
		{"index": "symbol_nums"},
		{"index": "stack_ident"},
		{"index": "server_role"},
		{"index": "report_time"},
	]

	@staticmethod
	def default_document():
		return {
			'id': 0,
			'file_name': '',
			'file_path': None,
			'file_content': None,
			'device_info': {},
			'report_time': None,
			'status': False, # True:已解析过 False:未解析过 'unable-xxxx':有错误
			'version': '',
			'package_name': '',
			'game_name': '',
			'phone_name': '',
			'phone_sys': '', # 'android-22'
			'imei': '',
			'stack_result': '',
			'stack_ident': '', # 第一行标识,对应ident
			'feature': '', # 页面展示用
			'stack_error': '', # 对比堆栈
			'symbol_nums': '',
			'app_debug': None,
			'user_default': {}, # 一个xml的文件，保存name和content
			'url': '',
			'arch': '',
			'platform': '',
			'platform_id': '',
			'channel': '',
			'tag': '',
			'patch': '',
			'min_path': '',
			'account': '',
			'role': '',
			'server': '',
			'server_role': '',
			'game_start_time': '',
			'dump_reset': '',
		}


class DmpStatistic(IncModel):
	Collection = 'dmpstatistic'
	Indexes = [
		{"index": "id", "unique": True},
		{"index": "ident", "unique": True},
		{"index": "firsttime"},
		{"index": "lasttime"},
		{"index": "status"},
	]

	@staticmethod
	def default_document():
		return {
			'id': 0,
			'feature': '', # 页面展示用
			'ident': '', # 用来进行对比区分不同报错的第一行标识
			'ident_more': '', # 整个错误标识，深度对比
			'record_id': [],
			'imei': [],
			'phone_name': {},
			'phone_sys': {},
			'phone_sdk': {},
			'firsttime': None,
			'lasttime': None,
			'count': 0,
			'status': False,
			'comment': [],
			'report_version': [],
			'game_account': [],
		}


class ExcRecord(IncModel):
	Collection = 'excrecord'
	Indexes = [
		{"index": "id", "unique": True},
		{"index": "stack_ident"},
		{"index": "report_time"},
		{"index": "version"},
		{"index": "imei"},
		{"index": "status"},
		{"index": "server_role"},
	]

	@staticmethod
	def default_document():
		return {
			'id': 0,
			'feature': '', # 页面展示用
			'stack_ident': '', # 用来进行对比区分不同报错的标识，对应异常分类表中的ident字段
			'stack': '', # 接收到整个堆栈报错
			'device_info': {},
			'report_time': None,
			'version': '',
			'package_name': '',
			'phone_name': 'unknown', # 现在不传了
			'phone_sys': 'unknown-unknown', # 不传了，'android-22'
			'imei': 'unknown',
			'status': False,
			'app_debug': None,
			'user_default': {},
			'url': '',
			'arch': '',
			'platform': '',
			'platform_id': '',
			'channel': '',
			'tag': '',
			'patch': '',
			'min_path': '',
			'account': '',
			'role': '',
			'server': '',
			'server_role': '',
			'account_tag': '',
			'game_start_time': '',
		}


class ExcStatistic(IncModel):
	Collection = 'excstatistic'
	Indexes = [
		{"index": "id", "unique": True},
		{"index": "ident", "unique": True},
		{"index": "firsttime"},
		{"index": "lasttime"},
		{"index": "status"}
	]

	@staticmethod
	def default_document():
		return {
			'id': 0, # int 计数
			'ident': '', # 用来进行对比区分不同报错的标识
			'feature': '', # 用来页面展示
			'count': 0, # 上报次数
			'record_id': [],
			'imei': [],
			'game_account': [],
			'phone_name': {},
			'phone_sys': {},
			'phone_sdk': {},
			'report_version': [],
			'firsttime': None,
			'lasttime': None,
			'comment': [],
			'status': False,
		}


class FeedBackRecord(Model):
	Collection = 'feedbackrecord'
	Indexes = [
		{"index": "account_id"},
		{"index": "game_server"},
		{"index": "vip"},
		{"index": "classify"},
		{"index": "time"},
	]

	@staticmethod
	def default_document():
		return {
			'account_id': '',
			'game_server': '',
			'role_name': '',
			'role_id': '',
			'role_uid': '',
			'grade': '',
			'vip': '',
			'classify': '',
			'issue': '',
			'time': '',
			'status': '',
		}


class BattleReport(Model):
	Collection = 'battlereport'
	Indexes = [
		{"index": "serv_key"},
		{"index": "play_id"},
		{"index": "type"},
		{"index": "report_time"},
	]

	@staticmethod
	def default_document():
		return {
			'serv_key': '',
			'play_id': '',
			'ident': '',
			'traceback': '',
			'play_record': '',
			'type': '',
			'report_time': '',
		}

class PlayReport(Model):
	Collection = 'playreport'
	Indexes = [
		{"index": "serv_key"},
		{"index": "role_id"},
		{"index": "play_id"},
		{"index": "report_time"},
	]

	@staticmethod
	def default_document():
		return {
			'serv_key': '',
			'role_id': '',
			'play_id': '',
			'play_record': '',
			'scene_id': '',
			'report_time': '',
			'ident': '',
			'traceback': '',
			'desc': '',
		}