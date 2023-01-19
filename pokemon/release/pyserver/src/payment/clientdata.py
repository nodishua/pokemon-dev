#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2014 YouMi Information Technology Inc.
'''

from framework.helper import toUTF8Dict, objectid2string, string2objectid

import json
from collections import namedtuple

# "{"uid"=12345678,"rid"=123465678,"skey"="game_ali","pid"=100}"
ClientDataFields = ['uid', 'rid', 'skey', 'pid', 'yyid', 'csvid']
ClientJson = namedtuple('ClientJson', ClientDataFields)


class ClientData(object):

	def __init__(self, data):
		try:
			if not isinstance(data, (tuple, list)):
				data = json.loads(data, object_hook=toUTF8Dict)
			if len(data) < len(ClientDataFields):
				data = list(data) + ['' for _ in xrange(7-len(data))]
			self.argD = ClientJson(*data)
		except:
			self.argD = None

	def isValid(self):
		return self.argD is not None
		# for k in ClientDataFields:
		# 	if k not in self.argD:
		# 		return False
		# return True

	@property
	def accountID(self):
		return string2objectid(self.argD.uid)

	@accountID.setter
	def accountID(self, v):
		v = objectid2string(v)
		self.argD = ClientJson(v, self.argD.rid, self.argD.skey, self.argD.pid, self.argD.yyid, self.argD.csvid)

	@property
	def roleID(self):
		return string2objectid(self.argD.rid)

	@property
	def serverKey(self):
		return self.argD.skey

	@property
	def rechargeID(self):
		return int(self.argD.pid)

	@property
	def yyID(self):
		if self.argD.yyid:
			return int(self.argD.yyid)
		else:
			return 0

	@property
	def csvID(self):
		if self.argD.csvid:
			return int(self.argD.csvid)
		else:
			return 0

	def makeModel(self):
		if not self.isValid():
			return True, None
		return False, {
			'account_id': self.accountID,
			'server_key': self.serverKey,
			'role_id': self.roleID,
			'recharge_id': self.rechargeID,
			'yy_id': self.yyID,
			'csv_id': self.csvID,
			'bad_flag': False,
		}
