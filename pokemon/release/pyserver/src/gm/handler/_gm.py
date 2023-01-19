# -*- coding: utf-8 -*-
from __future__ import absolute_import

from tornado.gen import coroutine
from tornado.web import HTTPError
from framework.helper import string2objectid
from framework import int2date, int2time, todaydate2int

from .base import AuthedHandler, BaseHandler
from gm.util import *
from gm.object.db import MongoDB

from game.object import AttrDefs

import re
import os
import json
import datetime
import binascii
import itertools
import copy
import subprocess
from collections import OrderedDict

# from fabric.api import local, run, env, hosts, sudo, cd, lcd, remote_tunnel, abort, execute
# from fabric.context_managers import settings
# from fabric.contrib.console import confirm


DBDataConvertMap = {
	'union_join_time': lambda d: str(datetime.datetime.fromtimestamp(d)),
	'union_quit_time': lambda d: str(datetime.datetime.fromtimestamp(d)),
	'union_last_time': lambda d: str(datetime.datetime.fromtimestamp(d)),
	'create_time': lambda d: str(datetime.datetime.fromtimestamp(d)),
	'created_time': lambda d: str(datetime.datetime.fromtimestamp(d)),
	'last_time': lambda d: str(datetime.datetime.fromtimestamp(d)),
	'time': lambda d: str(datetime.datetime.fromtimestamp(d)),
	'cards': lambda d: len(d),
	'items': lambda d: sum(d.values()),
	'frags': lambda d: sum(d.values()),
	'recharges': lambda d: sum([d[x]['cnt'] for x in d if x > 0 and 'cnt' in d[x]]),
	'gifts': lambda d: len(d) - len([x for x in d if isinstance(x, int) and x < 0]),
	'account_roles': lambda d: str(d),
	'heirlooms': lambda d: str(d),
	'talent_trees': lambda d: str(d),
	'skins': lambda d: str(d),
	'attachs': lambda d: str(d),
	'newbie_guide': lambda l: max(l) if l else [],
	'beginDate': lambda d: str(int2date(d)),
	'beginTime': lambda d: str(int2time(d)),
	'endDate': lambda d: str(int2date(d)),
	'endTime': lambda d: str(int2time(d)),
	'paramMap': lambda d: str(d),
	'clientParam': lambda d: str(d),
	'explain': lambda d: str(d),
	'metals': lambda d: len(d),
	'yh_equips': lambda d: len(d),
}

# Player activity
class RoleActivityHancler(AuthedHandler):
	url = '/role_activity'

	@coroutine
	def get(self):
		self.render_page("_role_activity.html")


# send email
class SenderMailHandler(AuthedHandler):
	url = "/sendmail"

	@coroutine
	def get(self):
		self.render_page("_send_mail.html")

	@coroutine
	def post(self):
		paramData = self.get_json_data()

		mailType = paramData['mailType']
		mailAddressee = paramData['receive'] or False
		mailSender = paramData['sender'] or False
		mailTitle = paramData['subject'] or False
		mailContent = paramData['content'] or False
		beginVip = paramData['beginVip'] or False
		endVip = paramData['endVip'] or False

		# The full service email does not transfer the email template, the first template is default.
		try:
			mailTemplate = int(paramData.get('mailTemp', False))
		except Exception as e:
			mailTemplate = 1

		# appendix
		mailAttach = json.loads(paramData.get('attachs'))
		for k, v in mailAttach.items():
			try:
				newk = int(k)
			except ValueError:
				pass
			else:
				mailAttach.pop(k, None)
				mailAttach[newk] = v

		if paramData['servName'] == "allservers":
			servName = "__@global@__"
		else:
			servName = paramData['servName']

		if mailType == "role":
			mailAddresseeList = mailAddressee.split(';')
			retS, retF = [], []
			for roleID in mailAddresseeList:
				r = yield self.userGMRPC.gmSendMail(self.session, servName, roleID, mailTemplate, mailSender, mailTitle, mailContent, mailAttach) # 发送个人邮件
				if r:
					retS.append(roleID)
				else:
					retF.append(roleID)
			self.write({'retF': retF, 'retS': retS})

		elif mailType == "server" or mailType == "allserver":
			ret = yield self.userGMRPC.gmSendServerMail(self.session, servName, mailTemplate, mailSender, mailTitle, mailContent, mailAttach) # 全服邮件
			self.write({'result': ret})

		elif mailType == "global" or mailType == "allglobal":
			ret = yield self.userGMRPC.gmSendGlobalMail(self.session, servName, mailTemplate, mailSender, mailTitle, mailContent, mailAttach) # 全局邮件
			self.write({'result': ret})

		elif mailType == "union":
			mailAddresseeList = mailAddressee.split(';')
			retS, retF = [], []
			for unionID in mailAddresseeList:
				r = yield self.userGMRPC.gmSendUnionMail(self.session, servName, int(unionID), mailTemplate, mailSender, mailTitle, mailContent, mailAttach) # Guild mail
				if r:
					retS.append(unionID)
				else:
					retF.append(unionID)
			self.write({'retF': retF, 'retS': retS})

		elif mailType == "account":
			mailAddresseeList = mailAddressee.split(';')
			retS, retF = [], []
			for accountName in mailAddresseeList:
				r = yield self.userGMRPC.gmSendNewbieMail(self.session, servName, accountName, mailTemplate, mailSender, mailTitle, mailContent, mailAttach)
				if r:
					retS.append(accountName)
				else:
					retF.append(accountName)
			self.write({'retF': retF, 'retS': retS})

		elif mailType == "vip" or mailType == "allvip":
			beginVip, endVip = int(beginVip), int(endVip)
			ret = yield self.userGMRPC.gmSendVipMail(self.session, servName, beginVip, endVip, mailTemplate, mailSender, mailTitle, mailContent, mailAttach) # vip mail
			self.write({"result": ret})

		else:
			raise HTTPError(404, reason="wrong mailtype")


# Get the email template
class GetMailTemplateHandler(AuthedHandler):
	url = "/sendmail/mail_template"

	@coroutine
	def get(self):
		servName = self.get_argument("servName")
		result = yield self.userGMRPC.gmGetMailCsv(self.session, servName)
		self.write(result)


# Player details
class RoleDetailHandler(AuthedHandler):
	url = r'/role_detail'

	@coroutine
	def get(self):
		servName = self.get_argument('servName', 'All')
		roleSearch = self.get_argument('roleSearch', None)

		if servName == "All":
			raise HTTPError(404, reason='servName error')

		roleID = None
		roleTuple = None

		if roleSearch.startswith('(') and roleSearch.endswith(')'):
			roleTuple = eval(roleSearch)

		elif len(roleSearch) == 24:
			roleID = string2objectid(roleSearch)

		else:
			try:
				roleID = int(roleSearch)
			except ValueError as e:
				pass

		columns = [
				{'field': 'account_name', 'title': 'channel account'},
				{'field': 'account_id', 'title': 'account ID'},
				{'field': 'id', 'title': 'Role ID'},
				{'field': 'uid', 'title': 'Role UID'},
				{'field': 'area', 'title': 'Chuangjiao Area Service'},
				# {'field': 'area_role_db_id', 'title': 'Creator role ID'},
				{'field': 'name', 'title': 'role name'},
				{'field': 'level', 'title': 'level'},
				{'field': 'vip_level', 'title': 'VIP'},
				{'field': 'disable_flag', 'title': 'title'},
				{'field': 'silent_flag', 'title': 'Forbidden'},
				{'field': 'gold', 'title': 'gold coins'},
				{'field': 'rmb', 'title': 'Diamond'},
				{'field': 'qq_rmb', 'title': 'QQ Managed Diamond'},
				{'field': 'qq_recharge', 'title': 'QQ recharge total'},
				{'field': 'recharges', 'title': 'Recharge times'},
				{'field': 'recharges_total', 'title': 'Total recharge'},
				{'field': 'rmb_consume', 'title': 'Diamond Consume'},
				{'field': 'coin1', 'title': 'Arena Coin'},
				{'field': 'coin2', 'title': 'Expedition Coin'},
				{'field': 'coin3', 'title': 'guild coin'},
				{'field': 'coin4', 'title': 'Alloy Essence'},
				{'field': 'coin5', 'title': 'Exploration Coin'},
				{'field': 'coin6', 'title': 'coin6'},
				{'field': 'union_db_id', 'title': 'guild ID'},
				{'field': 'tw_top_floor', 'title': 'Top Tower Floor'},
				{'field': 'battle_fighting_point', 'title': 'Card combat power'},
				{'field': 'top6_fighting_point', 'title': 'The highest fighting power of the top 6 cards in history'},
				{'field': 'top12_fighting_point', 'title': 'The top 12 card fighting power in history'},
				{'field': 'cardNum_rank', 'title': 'Card Number Ranking'},
				{'field': 'fight_rank', 'title': 'Fight Ranking'},
				{'field': 'gate_star_rank', 'title': 'Star Rank'},
				{'field': 'card1fight_rank', 'title': 'Single card fighting power ranking'},
				{'field': 'pw_rank', 'title': 'Arena Rank'},
				{'field': 'achieve_rank', 'title': 'Achievement Ranking'},
				# {'field': 'galaxy_rank', 'title': 'Constellation ranking'},
				{'field': 'stamina', 'title': 'Physical Strength'},
				{'field': 'created_time', 'title': 'created time'},
				{'field': 'last_time', 'title': 'Recent operation time'},
				{'field': '_online_', 'title': 'Online'},
				{'field': 'account_roles', 'title': 'All regional servers'},
				{'field': 'talent_point', 'title': 'talent point'},
				{'field': 'skill_point', 'title': 'Skill Point'},
				{'field': 'fightgo', 'title': 'First hand value'},
				{'field': 'achieve_fightgo', 'title': 'Achieve fightgo value'},
				{'field': 'equip_awake_frag', 'title': 'Awakening Fragment'},
				{'field': 'cards', 'title': 'Number of cards'},
				{'field': 'items', 'title': 'Number of props'},
				{'field': 'frags', 'title': 'Number of Fragments'},
				# {'field': 'metals', 'title': 'Alloy number'},
				# {'field': 'yh_equips', 'title': 'Number of aid equipment'},
				{'field': 'skins', 'title': 'skins'},
				{'field': 'card_advance_times', 'title': 'Card advance times'},
				{'field': 'card_star_times', 'title': 'The number of card star times'},
				{'field': 'gifts', 'title': 'Gifts received'},
				{'field': 'newbie_guide', 'title': 'Newbie Guide'},
				{'field': 'union_join_time', 'title': 'Join guild time'},
				{'field': 'union_quit_time', 'title': 'Quit guild time'},
				{'field': 'union_last_time', 'title': 'The last guild operation time'},
				{'field': 'talent_trees', 'title': 'Talent Trees'},
				# {'field': 'heirlooms', 'title': 'Artifact'},
		]

		if roleID:
			ret = yield self.userGMRPC.gmGetRoleInfo(self.session, servName, roleID)
		elif roleTuple:
			ret = yield self.userGMRPC.gmGetRoleInfoByRoleKey(self.session, servName, roleTuple)
		else:
			ret = yield self.userGMRPC.gmGetRoleInfoByName(self.session, servName, roleSearch)

		if len(ret) == 0:
			raise HTTPError(404, reason='no such role')

		if 'account_name' in ret and ret['account_name'].find('shuguo_') >= 0:
			raise HTTPError(404, reason='no such role')

		result = {'_online_': False}
		for field in [x['field'] for x in columns]:
			if field in ret:
				result[field] = ret[field]
				if field in DBDataConvertMap:
					result[field] = DBDataConvertMap[field](ret[field])

		# recharges {csv_id:{cnt:0, date:20141206, orders:[PayOrder.id], reset:0 or yyid or -yyid}}
		from framework.csv import csv
		recharges = csv.recharges.to_dict()
		sumRecharges = 0
		for k, d in ret['recharges'].iteritems():
			if k > 0:
				for j in xrange(d.get('cnt', 0)):
					sumRecharges += recharges.get(k, {}).get('rmb', 0)
		result['recharges_total'] = sumRecharges

		# 转化12位objectid
		data = hexlifyDictField(result)

		columns = self.setLocalColumns(columns)
		self.write({
			'columns': columns,
			'data': [data],
		})


# 玩家封号、禁言
class BanPlayerHandler(AuthedHandler):
	url = r'/ban_player'

	@coroutine
	def get(self):
		banType = self.get_argument('banType')
		servName = self.get_argument('servName')
		if not is_key(servName):
			servName = servName2ServKey(servName)

		roleID = self.get_argument('roleID')
		try:
			roleID = int(roleID)
		except ValueError as e:
			roleID = string2objectid(roleID)

		val = self.get_argument('val')
		if val == 'true':
			val = True
		elif val == 'false':
			val = False
		else:
			raise HTTPError(404, 'val is incorrect')

		ret = yield self.userGMRPC.gmRoleAbandon(self.session, servName, roleID, banType, val)
		self.write({'val': val})


# 工会详细信息
class UnionDetailHandler(AuthedHandler):
	url = r'/union_detail'

	@coroutine
	def get(self):
		servName = self.get_argument('servName', 'All')
		unionID = self.get_argument('unionID', False)

		if servName == "All":
			raise HTTPError(404, reason='servName error')
		if not unionID:
			raise HTTPError(404, reason='args missed')
		unionID = int(unionID)

		# columns = [
		# 	{'field': 'id', 'title': '工会ID'},
		# 	{'field': 'name', 'title': '工会名'},
		# 	{'field': 'level', 'title': '工会等级'},
		# 	{'field': 'members', 'title': '工会人数'},
		# 	{'field': 'intro', 'title': '工会简介'},
		# 	{'field': 'contrib', 'title': '总贡献值'},
		# 	{'field': 'day_contrib', 'title': '当日贡献'},
		# 	{'field': 'join_type', 'title': '加入类型'},
		# 	{'field': 'join_level', 'title': '加入等级限制'},
		# ]
		ret = yield self.userGMRPC.gmGetUnionInfo(self.session, servName, unionID)

		if len(ret) == 0:
			raise HTTPError(404, reason='no such union')
		ret["members"] = len(ret["members"])

		# result = {'_online_': False}
		# for field in [x['field'] for x in columns]:
		# 	if field in ret:
		# 		result[field] = ret[field]
		# 		if field in DBDataConvertMap:
		# 			result[field] = DBDataConvertMap[field](ret[field])

		# columns = self.setLocalColumns(columns, self.get_cookie("user_locale"))
		self.write({'data': [ret]})


# 获取vip信息
class getVIPMailConfirmMsg(AuthedHandler):
	url = r'/vip_msg'

	@coroutine
	def run(self):
		servName = self.get_argument("servName", False)
		beginVip = self.get_argument("beginVip", False)
		endVip = self.get_argument("endVip", False)

		if not servName:
			raise HTTPError(404, reason="no this server")
		beginVip, endVip = int(beginVip), int(endVip)
		ret = yield self.userGMRPC.gmGetRoleInfoByVip(self.session, servName, beginVip, endVip)

		vipRoleIDList = [x['id'] for x in ret]
		if not vipRoleIDList:
			msg = '不存在VIP%d到VIP%d范围内的玩家' % (beginVip, endVip)
			self.write({"ret": False, "msg": msg})
		else:
			msg = "将要向以下VIP用户发送邮件:\n"
			vipCount = [0 for i in range(1, 20)]

			for x in ret:
				vipCount[x['vip_level']] = vipCount[x['vip_level']] + 1
			for i in range(beginVip, endVip + 1):
				msg = msg + "VIP%d:  %d人<br>" % (i, vipCount[i])
			self.write({"ret": True, "msg": msg})


# 在线玩家信息
class OnlineRoleHandler(AuthedHandler):
	url = '/online_role'

	@coroutine
	def get(self):
		servName = self.get_argument("servName", "All")
		offset = int(self.get_argument("offset", 0))
		limit = int(self.get_argument("limit", 0))

		if servName == "All":
			raise HTTPError(404, reason='servName error')

		total = 0
		result = []
		columns = [
				{'field': 'account_id', 'title': self.translate('账号ID')},
				{'field': 'id', 'title': self.translate('角色ID')},
				{'field': 'name', 'title': self.translate('角色名')},
				{'field': 'level', 'title': self.translate('等级')},
				{'field': 'vip_level', 'title': 'VIP'},
				{'field': 'gold', 'title': self.translate('金币')},
				{'field': 'rmb', 'title': self.translate('钻石')},
				{'field': 'recharges', 'title': self.translate('充值次数')},
				{'field': 'union_db_id', 'title': self.translate('公会ID')},
				{'field': 'stamina', 'title': self.translate('体力')},
				{'field': 'created_time', 'title': self.translate('创建时间')},
				{'field': 'last_time', 'title': self.translate('最近操作时间')},
			]

		if limit:
			ret = yield self.userGMRPC.gmGetGameOnlineRoles(self.session, servName, offset, limit)

			total = ret['view']['size']
			for d in ret['models']:
				dd = {}
				for field in [x['field'] for x in columns]:
					dd[field] = d[field]
					if field in DBDataConvertMap:
						dd[field] = DBDataConvertMap[field](d[field])
				result.append(dd)

			# result = result[offset: offset+limit]
			rows = hexlifyDictField(result)

			self.write({
				"rows": rows,
				"limit": limit,
				"offset": offset,
				"total": total,
				})
		else:
			self.write({'columns': columns,})


# 玩家邮件信息
class RoleMailHandler(AuthedHandler):
	url = r'/role_mail'

	@coroutine
	def get(self):
		servName = self.get_argument('servName', 'All')
		roleSearch = self.get_argument('roleSearch', None)

		if servName == "All":
			raise HTTPError(404, reason='servName error')

		# 邮件缩略数据 [{db_id:Mail.id, subject:Mail.subject, time:Mail.time, type=Mail.type, sender:Mail.sender, global:Mail.role_db_id==0}, ...]
		columns = [
			{'field': 'db_id', 'title': '邮件ID'},
			{'field': 'subject', 'title': '标题'},
			{'field': 'time', 'title': '发送时间', 'sortable': True},
			{'field': 'sender', 'title': '发件人'},
			{'field': 'content', 'title': '内容'},
			{'field': 'attachs', 'title': '附件'},
			{'field': 'deleted_flag', 'title': '是否已读'},
		]

		roleID = None
		try:
			roleID = int(roleSearch)
		except ValueError as e:
			roleID = string2objectid(roleSearch)

		if roleID:
			ret = yield self.userGMRPC.gmGetRoleInfo(self.session, servName, roleID)
		else:
			ret = yield self.userGMRPC.gmGetRoleInfoByName(self.session, servName, roleSearch)

		if len(ret) == 0:
			raise HTTPError(404, reason='no such role')

		# 存在机器人没有account_name
		account_name = ret.get('account_name', '')
		if account_name.find('shuguo_') >= 0 and self.isTCAccount():
			raise HTTPError(404, reason='no such role')

		result = []
		nUnReadMail = len(ret['mailbox'])
		for i, mailThumb in enumerate(itertools.chain(ret['mailbox'], ret['read_mailbox'])):
			d = {}
			if i >= nUnReadMail:
				mailThumb['db_id'] = mailThumb['id']

			for field in [x['field'] for x in columns]:
				if field in mailThumb:
					d[field] = mailThumb[field]
					if field in DBDataConvertMap:
						d[field] = DBDataConvertMap[field](mailThumb[field])
			d['deleted_flag'] = i < nUnReadMail
			result.append(d)

		columns = self.setLocalColumns(columns)
		data = hexlifyDictField(result)
		self.write({
			'columns': columns,
			'data': data,
		})


# 运营活动
class YYHandler(AuthedHandler):
	url = '/operate_activity'

	@coroutine
	def get(self):
		self.render_page("_operate_activity.html")

	@coroutine
	def post(self):
		servName = self.get_json_data().get("servName", "All")

		if servName == "All":
			raise HTTPError(404, "server error", reason='Servename cant be all.')

		columns = [
			{'field': 'id', 'title': 'ID', 'sortable': True},
			{'field': 'icon', 'title': '活动图标', 'editable': {'type': 'textarea',}},
			{'field': 'icon1', 'title': '活动按钮角标', 'editable': {'type': 'textarea',}},
			{'field': 'independent', 'title': '是否独立icon', 'editable': {'type': 'text',}},
			{'field': 'type', 'title': '活动分类', 'editable': {'type': 'text',}},
			{'field': 'name', 'title': '名称', 'editable': {'type': 'text',}},
			# {'field': 'name1', 'title': '名称2', 'editable': {'type': 'textarea',}},
			{'field': 'desc', 'title': '活动简介', 'editable': {'type': 'textarea',}},
			# {'field': 'desc_tw', 'title': '活动简介', 'editable': {'type': 'textarea',}},
			# {'field': 'desc_en', 'title': '活动简介', 'editable': {'type': 'textarea',}},
			# {'field': 'activityDesc', 'title': 'activityDesc活动右侧的说明', 'editable': {'type': 'textarea',}},
			{'field': 'rDesc', 'title': '活动右侧的说明', 'editable': {'type': 'textarea',}},
			# {'field': 'rDesc_tw', 'title': '活动右侧的说明', 'editable': {'type': 'textarea',}},
			# {'field': 'rDesc_en', 'title': '活动右侧的说明', 'editable': {'type': 'textarea',}},
			# {'field': 'rTitle', 'title': '活动右边子面板标题图', 'editable': {'type': 'text',}},
			# {'field': 'openTimeDesc', 'title': '活动开放日期简介', 'editable': {'type': 'text',}},
			# {'field': 'displayType', 'title': '显示类型', 'editable':{'type': 'text',}},
			{'field': 'paramMap', 'title': '客户端参数', 'editable': {'type': 'textarea'}},
			{'field': 'clientParam', 'title': '空白', 'editable': {'type': 'textarea'}},
			{'field': 'huodongID', 'title': '活动版本ID', 'editable': True},
			{'field': 'countType', 'title': '  计数类型  ', 'editable':{'type': 'text'}},

			{'field': 'openType', 'title': '  开放周期  ', 'editable': True},
			{'field': 'beginDate', 'title': '开始日期', 'editable': {'type': 'text'}},
			{'field': 'beginTime', 'title': '开始时间', 'editable': {'type': 'text'}},
			{'field': 'endDate', 'title': '截止日期', 'editable': {'type': 'text'}},
			{'field': 'endTime', 'title': '截止时间', 'editable': {'type': 'text'}},
			# {'field': 'openWeekDay', 'title': '周期开启序列', 'editable': { 'type': 'text',}},
			# {'field': 'openWeekDay', 'title': '周期开启序列', 'editable': { 'type': 'checklist', 'source': [
			# 	{'value': '1', 'text': '星期一'},
			# 	{'value': '2', 'text': '星期二'},
			# 	{'value': '3', 'text': '星期三'},
			# 	{'value': '4', 'text': '星期四'},
			# 	{'value': '5', 'text': '星期五'},
			# 	{'value': '6', 'text': '星期六'},
			# 	{'value': '7', 'text': '星期日'},
			# ]}},
			{'field': 'openDuration', 'title': '持续小时', 'editable': {'type': 'text',}},
			{'field': 'relativeDayRange', 'title': '持续的相对天数', 'editable': {'type': 'text',}},
			{'field': 'leastLevel', 'title': '最低等级限制', 'editable': {'type': 'text',}},
			{'field': 'leastVipLevel', 'title': '最低VIP限制', 'editable': {'type': 'text',}},
			{'field': 'validServerOpenDateRange', 'title': '生效的开服时间区间', 'editable': {'type': 'text',}},
			{'field': 'serverDayRange', 'title': '开服时间限制', 'editable': {'type': 'text',}},
			{'field': 'roleDayRange', 'title': '创角时间限制', 'editable': {'type': 'text',}},
			{'field': 'servers', 'title': '服务器', 'editable': {'type': 'text'}},
			{'field': 'languages', 'title': '语言区域', 'editable': {'type': 'text'}},

			{'field': 'active', 'title': '是否激活', 'editable': True},
			# {'field': 'explain', 'title': '说明', 'editable': {'type': 'textarea'}},
			{'field': 'sortWeight', 'title': '排序值', 'editable': {'type': 'text'}},
			{'field': 'redpoint', 'title': '提示性红点', 'editable': True},
		]

		configCache = yield self.userGMRPC.gmGetGameYYComfig(self.session, servName)
		yyhdCache = copy.deepcopy(configCache["csv"]["yyhuodong"])

		for rowID, item in configCache['db']['yyhuodong'].items():
			rowID = int(rowID)
			if rowID not in yyhdCache:
				continue
			for k, v in item.items():
				yyhdCache[rowID][k] = copy.deepcopy(v)

		result = []
		for rowID in sorted(yyhdCache.keys()):
			yyhdCache[rowID]['id'] = rowID

			# 处理yy配表字段内容
			for k, v in yyhdCache[rowID].items():
				if k == "paramMap" and not v:
					yyhdCache[rowID][k] = ''
				else:
					yyhdCache[rowID][k] = self.py2csv(v)
			result.append(yyhdCache[rowID])

		# 公告
		placardCache = copy.deepcopy(configCache['csv']['placard'])
		if 1 in configCache['db']['placard']:
			placardCache = configCache['db']['placard']

		columns = self.setLocalColumns(columns)
		self.write({
			'columns': columns,
			'data': result,
			'placard': placardCache,
			'language': self.language
		})

	@staticmethod
	def py2csv(ob):
		if ob is None:
			return ''

		if isinstance(ob, (str, unicode)):
			return ob

		s = str(ob).replace("'", "").replace(" ", "")
		if isinstance(ob, list):
			s = s.replace('[', '<').replace(',', ';').replace(']', '>')
		elif isinstance(ob, dict):
			s = s.replace(':', '=').replace(',', ';')
		return s

	@staticmethod
	def csv2py(s):
		if s == '':
			return None

		if not (s.startswith('<') or s.startswith('{')):
			try:
				s = int(s)
			except ValueError:
				pass
			return s

		ob = ""
		s = s.replace('<', '[').replace('>', ']')
		for i in s:
			if i == '[' or i == '{':
				ob = ob + i + '"'
			elif i == '=':
				ob += '":"'
			elif i == ';':
				ob += '","'
			elif i == ']' or i == '}':
				ob = ob + '"' + i
			else:
				ob += i

		ob = eval(ob)
		if isinstance(ob, list):
			for k, v in enumerate(ob):
				try:
					ob[k] = int(v)
				except ValueError:
					pass
		elif isinstance(ob, dict):
			for k, v in ob.items():
				try:
					ob[k] = int(v)
				except ValueError:
					pass
		return ob


# 运营活动重置配置、单服保存、全服保存
class YYConfigHandler(AuthedHandler):
	url = r'/operation_config/(.+)'

	@coroutine
	def post(self, p): #p: yyhuodong, placard
		r = self.get_json_data()
		servName = r.get('servName', False)
		diffDB = r.get('diffDB', False)

		if p == 'reset':
			# 重置
			ret = yield self.userGMRPC.gmSetGameYYComfig(self.session, {'yyhuodong': {},
				'placard': {}}, servName)
			self.write({'result': ret})
			return

		if p == 'yyhuodong':
			diffDBTrans = {}
			for i, d in diffDB.items():
				id = int(i);

				vDictTemp = {}
				for k, v in d.items():
					if k == "paramMap" and v == '':
						vDictTemp[k] = {}
					else:
						vDictTemp[k] = YYHandler.csv2py(v)
				diffDBTrans[id] = vDictTemp
			data = {'yyhuodong': diffDBTrans}

		elif p == 'placard':
			content = diffDB[1]
			if "content" not in content:
				content["content"] = content.values()[0]
			data = {'placard': diffDB}

		if not servName:
			ret = yield self.userGMRPC.gmSetGameYYComfig(self.session, data)
		else:
			ret = yield self.userGMRPC.gmSetGameYYComfig(self.session, data, servName)

		self.write({'result': ret})


# 公告
class PlacardConfigHandler(AuthedHandler):
	url = r'/placard_config'
	ConfigPath = 'login/conf/notice.json'

	@coroutine
	def get(self):
		configPath = PlacardConfigHandler.ConfigPath
		print "os.getcwd", os.getcwd()
		if not os.path.exists(configPath):
			raise HTTPError(404, reason="wrong configPath")

		with open(configPath, 'r') as f:
			data = f.read()
		config = json.loads(data)
		self.write(config)

	@coroutine
	def post(self):
		placard = self.get_argument('config', None)

		try:
			config = json.loads(str(placard))
		except Exception as e:
			ret = {'result': False, 'msg': '不是标准json格式'}
		else:
			ret = self.configCheck(config)
			if ret['result']:
				strConfig = json.dumps(config, ensure_ascii=False, sort_keys=True, indent=2)
				configPath = PlacardConfigHandler.ConfigPath
				with open(configPath, 'w') as f:
					f.write(strConfig)

				# scp
				identity = "/mnt/server_tool/fabfile/ssh_key/key_kdjx_nsq"
				remotePath = "172.16.2.16:/mnt/release/login/conf/notice.json"
				cmd = "scp -i {0} {1} {2}".format(identity, configPath, remotePath)
				print "cmd", cmd
				if os.system(cmd) != 0:
					ret = {'result': False, 'msg': 'scp 执行失败'}

		self.write(ret)

	def configCheck(self, config):
		ks = set(["banner", "activity", "update"])
		updateks = set(["title", "content"])
		activityks = set(["id", "titlebar", "content"])
		ret = {'result': False, 'msg': ''}
		Flag = False

		if set(config.keys()) == ks:
			for k in ks:
				if k == "banner" and len(config[k]) == 0 and not isinstance(config[k], list):
					ret['msg'] = "banner 内容不能为空"
					break

				elif k == "update":
					for item in config[k]:
						if set(item.keys()) != updateks:
							ret['msg'] = "update 格式不正确"
							Flag = True
							break

				elif k == "activity" and len(config[k]) > 0:
					ids = []
					for item in config[k]:
						if set(item.keys()) == activityks:
							if item['id'] not in ids:
								ids.append(item['id'])
							else:
								ret['msg'] = "activity id 重复"
								Flag = True
								break

							for it in item['content']:
								if set(it.keys()) != updateks:
									ret['msg'] = "activity content 格式不正确"
									Flag = True
									break
							if Flag:
								break
						else:
							ret['msg'] = "activity 格式不正确"
							Flag = True
							break

				if Flag:
					break
		else:
			Flag = True
			ret['msg'] = "格式不正确"

		if not Flag:
			ret['result'] = True
		return ret


# 礼包生成
class GiftPacksGenerateHandler(AuthedHandler):
	url = r'/gift_packs'

	@coroutine
	def get(self):
		page = self.get_argument('page', None)
		if page:
			giftTemplates = yield self.userGMRPC.gmGetGiftCsv(self.session)
			self.write({'data': giftTemplates})
		else:
			self.render_page("_gift_packs.html")

	@coroutine
	def post(self):
		r = self.get_json_data()

		giftTemplates = r.get("giftTemplates", False) # int
		giftCounts = r.get("giftCounts", False) # int
		giftServers = r.get("giftServers", []) # []

		ret = yield self.userGMRPC.gmGenGift(self.session, giftTemplates, giftCounts, giftServers)

		self.write('\r\n'.join(ret))


# 黑名单
class BlackListHandler(AuthedHandler):
	url = r'/blacklist'

	@coroutine
	def get(self):
		# blackListTemplates = yield self.userGMRPC.gmGetGameBlackList(self.session)
		# print '-------------------'
		# print blackListTemplates
		self.render_page('_blacklist.html')

	@coroutine
	def post(self):

		datas = self.get_argument('data', False)
		if datas:
			datas = ast.literal_eval(datas)
		operator = self.get_argument('operator', False)
		if operator == 'add':
			ret = yield self.userGMRPC.gmAddGameBlackList(self.session, datas)
		if operator == 'del':
			datas = map(int, datas)
			ret = yield self.userGMRPC.gmDelGameBlackList(self.session, datas)
		if operator == 'push':
			ret = yield self.userGMRPC.gmPushGameBlackList(self.session)
		try:
			self.write({'result': ret})
		except NameError as identifier:
			self.write({'result': 'false'})


# 聊天监控
class ChatMonitorHandler(AuthedHandler):
	url = r'/chat_monitor'

	@coroutine
	def get(self):
		self.render_page("_chat_monitor.html")

	@coroutine
	def post(self):
		r = self.get_json_data()
		servName = r.get("servName", "All")
		offset = r.get("offset", 0)
		limit = r.get("limit", None)

		if not limit:
			columns = [
				{"field": 'gameName', 'title': '区服'},
				{'field': 'roleID', 'title': '角色ID'},
				{'field': 'roleName', 'title': '角色名'},
				{'field': 'roleLevel', 'title': '等级'},
				{'field': 'roleVIP', 'title': 'VIP'},
				{'field': 'type', 'title': '类型'},
				{'field': 'msg', 'title': '聊天内容', 'width': '50%'},
				{'field': 'time', 'title': '时间'},
				{'field': 'ban', 'title': '封号、禁言'},
			]
			columns = self.setLocalColumns(columns)
			self.write({'columns': columns})
			return

		if servName == "All":
			result = list(self.messageMap["All"])
		else:
			result = []
			for d in self.messageMap["All"]:
				if d['gameName'] != servName:
					continue
				result.append(d)

		total = len(result)
		result = result[offset:offset+limit]

		for c in result:
			ret = yield self.userGMRPC.gmGetRoleInfo(self.session, c['gameName'], c['roleID'])
			c['ban'] = [ret['disable_flag'], ret['silent_flag']]

		self.write({
			'data': {
				"total": total,
				"rows": result
			}
		})


# 账号迁移
class AccountMigrateHandler(AuthedHandler):
	url = r'/account_migrate'

	@coroutine
	def get(self):
		self.render_page('_account_migrate.html')

	@coroutine
	def post(self):
		data = self.get_json_data()

		cfg = self.application.cfg['account_mongo']
		mongo = MongoDB(cfg)
		Account = mongo.client.Account
		field = {'name': 1, 'channel': 1, 'language': 1, 'pass_md5': 1, 'create_time': 1, 'last_time': 1}

		failedList = []
		for d in data:
			ret = yield self.dbcAccount.call_async('AccountMigrate', d['old'], d['new'])
			if ret['ret'] != True:
				failedList.append(d)
		# 	account = Account.find_one({'name': d['old']}, field)
		# 	newacc = Account.find_one({'name': d['new']}, field)
		# 	newacc_id = newacc.pop('_id')

		# 	if account:
		# 		oldChannel = account['channel']
		# 		newChannel = d['new'].split('_')[0]

		# 		if newacc:
		# 			newChannel = newacc['channel']
		# 			newacc['name'] = d['old'] + '@'
		# 			newacc['channel'] = oldChannel
		# 			Account.update({"_id": newacc_id}, {'$set': newacc})

		# 		account['name'] = d['new']
		# 		account['channel'] = newChannel
		# 		Account.update({"_id": account.pop('_id')}, {'$set': account})

		# 		if newacc:
		# 			newacc['name'] = d['old']
		# 			Account.update({"_id": newacc_id}, {'$set': newacc})
		# 	else:
		# 		failedList.append(d)

		# mongo.close()
		self.write({'failed': failedList})


# 刷新配表
class RefreshCsvHandler(AuthedHandler):
	url = '/refreshcsv'

	@coroutine
	def get(self):
		self.render_page('_refreshcsv.html')

	@coroutine
	def post(self):
		r = self.get_json_data()
		servName = r.get('servName', None)
		if servName is None:
			ret = yield self.userGMRPC.gmRefreshCSV(self.session)
		else:
			ret = yield self.userGMRPC.gmRefreshCSV(self.session, servName)

		self.write({'ret': ret})

# gmExecPy
class ExecPyHandler(AuthedHandler):
	url = '/execpy'

	@coroutine
	def post(self):
		srcFile = self.request.files.get('src', None)
		if not srcFile:
			raise HTTPError(404, reason="wrong srcFile")
		src = srcFile[0].get('body', None)
		if not src:
			raise HTTPError(404, reason="wrong srcFile content")

		servName = self.get_argument('servName', None)
		if not servName:
			ret = yield self.userGMRPC.gmExecPy(self.session, src)
		else:
			ret = yield self.userGMRPC.gmExecPy(self.session, src, name=servName)

		self.write({'result': ret})

# gmGenRobots
class gmGenRobotsHandler(AuthedHandler):
	url = '/genrobots'

	@coroutine
	def post(self):
		r = self.get_json_data()
		servName = r.get('servName', None)
		if not servName:
			raise HTTPError(404, reason="no servName")

		ret = yield self.userGMRPC.gmGenRobots(self.session, servName)
		self.write({'result': ret})

# 属性计算
class CalculateCardAttrs(BaseHandler):
	url = '/calattrs'

	@coroutine
	def get(self):
		servName = self.get_argument('servName')
		roleUID = self.get_argument('role_uid')
		cardID = []
		ret = yield self.userGMRPC.gmGetRoleCards(servName, roleUID, cardID)
		cards = sorted(ret['cards'].values(), key=lambda x:x['fighting_point'], reverse=True)

		def _convert(d):
			if d.get('id', None):
				d['id'] = binascii.hexlify(d['id'])
			if d.get('held_item', None):
				d['held_item'] = binascii.hexlify(d['held_item'])
			if d.get('role_db_id', None):
				d['role_db_id'] = binascii.hexlify(d['role_db_id'])
			return d;

		map(_convert, cards)
		columns = [
			{'field': 'id', 'title': ''},
			{'field': 'name', 'title': '卡片名称'},
			{'field': 'fighting_point', 'title': '战斗力'},
		]
		self.write({'columns': columns,
			'data': cards, 'role': {'id': binascii.hexlify(ret['role']['id']), 'name': ret['role']['name']}})

	@coroutine
	def post(self):
		r = self.get_json_data()
		ret = yield self.userGMRPC.gmEvalCardAttrs(r['servName'], binascii.unhexlify(r['id']),
			binascii.unhexlify(r['cur_card_id']), r['disables'])
		attrs, dis = ret['attrs'], ret['display']

		attrsMap = {} # {int: attr}
		for i, v in enumerate(AttrDefs.attrsEnum[1:], start=1):
			attrsMap[i] = v

		sysMaps = {
			'base': '基础属性',
			'character': '性格',
			'nvalue': '个体值',
			'const': '养成固定值',
			'percent': '养成百分比',
		}
		tables = {}
		columns = {}
		for t in dis:
			tabName = sysMaps.get(t, 'NIL')
			tables[t] = []
			columns[t] = OrderedDict()
			for sl in dis[t]:
				if len(sl) < 2:
					continue
				con = {t: sl[0]}
				columns[t][t] = {'field': t, 'title': tabName}
				for i, v in enumerate(sl[1], start=1):
					attrName = attrsMap.get(i, 'nil')
					columns[t][i] = {'field': attrName, 'title': attrName}
					if type(v) == float:
						con[attrName] = round(v, 4)
					else:
						con[attrName] = v
				tables[t].append(con)
		for k, d in columns.iteritems():
			columns[k] = []
			for _, v in d.iteritems():
				columns[k].append(v)

		result = OrderedDict()
		for i, v in enumerate(AttrDefs.attrsEnum[1:], start=1):
			rv = attrs.get(v, None)
			if rv:
				result[str(i)+"="+v] = rv

		self.write({'ret': result, 'tables': tables, 'columns': columns})


# 日志查看
class LogInspectorHandler(AuthedHandler):
	url = r'/log_inspector'

	@coroutine
	def get(self):
		pass

	@coroutine
	def post(self):
		pass


class DataExportHandler(AuthedHandler):
	url = r'/data_export'

	@coroutine
	def get(self):
		# 需要导出的collection
		export_collection = 'Archive'
		p = subprocess.Popen('mongodump --version', shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
		out, err = p.communicate()
		if err:
			print 'err: ', err
			self.write({'ret': False})
			return

		filename = '%s.%d.json'% (export_collection, todaydate2int())
		path = 'src/gm/statics/' + filename
		mongoConfig = self.cfg['mongo']
		mongoHost = mongoConfig.get('host', '127.0.0.1')
		port, db = mongoConfig['port'], mongoConfig['dbname']
		user, pwd = mongoConfig.get('username'), mongoConfig.get('password')

		# export
		if user and pwd:
			cmd = "mongodump --uri=mongodb://{0}:{1}@{2}:{3}/{4}?authSource=admin -c {5} -o {6}".format(
				user, pwd, mongoHost, port, db, export_collection, path)
		else:
			cmd = 'mongodump -h {0}:{1} -d {2} -c {3} -o {4}'.format(mongoHost, port,
				db, export_collection, path)

		p = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
		out, err = p.communicate()
		if re.search(r'done dumping', out):
			# 压缩
			cmd = 'tar -czf {0} {1} && rm -rf {1}'.format(filename+'.tar.gz', filename)
			p = subprocess.Popen(cmd, cwd='src/gm/statics/', shell=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
			p.communicate()
			self.write({'ret': True, 'data': filename+'.tar.gz'})
		else:
			self.write({'ret': False})

	@coroutine
	def post(self):
		# 需要导入的collection
		import_collection = 'Archive'

		recordCount = self.mongo_client[import_collection].find({}).count()
		if recordCount != 0:
			self.write({'ret': False, 'msg': '当前%s中已存在数据'% import_collection})
			return

		p = subprocess.Popen('mongorestore --version', shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
		out, err = p.communicate()
		if err:
			print 'err: ', err
			self.write({'ret': False, 'msg': '缺少 mongorestore 工具'})
			return

		importFile = self.request.files['importFile'][0]
		with open('/tmp/%s'% importFile['filename'], 'wb') as f:
			f.write(importFile['body'])

		p = subprocess.Popen('tar -xzf %s'% importFile['filename'], cwd='/tmp', shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
		out, err = p.communicate()
		if err:
			print 'err: ', err
			self.write({'ret': False, 'msg': '解压失败'})
			return

		host = self.cfg['mongo'].get('host', '127.0.0.1') + ":" + str(self.cfg['mongo']['port'])
		db = self.cfg['mongo']['dbname']
		cmd = 'mongorestore -h {0} -d {1} ./{3}/{1}'.format(host, db, import_collection, importFile['filename'][:-7])
		p = subprocess.Popen(cmd, cwd='/tmp', shell=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
		out, err = p.communicate()
		if re.search(r'done', out):
			self.write({'ret': True})
		else:
			self.write({'ret': False, 'msg': '导入数据'})


# 暂不使用
def initEnv():
	env.use_ssh_config = True
	env.forward_agent = True
	env.user = 'root'
	env.ssh_config_path = './shuma/gmweb2/handler/ssh_config'
	env.password = '123456'
	env.passwords = passwords
	env.parallel = True

def svn_up_remote_config_json():
	def _config_json_csv_svn_up():
		with remote_tunnel(3690, local_host='192.168.1.125'):
			with settings(warn_only=True):
				run('svn cleanup')
				run('svn revert ./config_json.py')
				ret = run('svn up ./config_json.py')
				return not ret.failed

	with cd('/mnt/server'):
		try:
			return _config_json_csv_svn_up()
		except Exception, e:
			if str(e).find('TCP forwarding request denied') >= 0:
				ret = run('netstat -nap|grep :3690|awk \'{print substr($7, 0, index($7, "/")-1)}\'')
				if len(ret.split()) > 1:
					ret = ret.split()[0]
				run('kill -9 %d' % int(ret))
				return _config_json_csv_svn_up()

def svn_up_local_config_json():
	with lcd('./config_json'):
		local('svn cleanup')
		local('svn revert yunying')
		local('svn up')

class ConfigJsonHandler(AuthedHandler):
	url = r'/config_json/(.+)'

	@coroutine
	def get(self, p):
		print p
		pass

	def post(self, p):
		print p
		pass
