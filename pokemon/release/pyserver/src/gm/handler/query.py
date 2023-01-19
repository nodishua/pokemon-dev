#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2014 YouMi Information Technology Inc.
Copyright (c) 2016 TianJi Information Technology Inc.
'''

import os
import json
import time
import math
import subprocess

import tornado.web
from tornado.web import HTTPError, RequestHandler
from tornado.gen import coroutine, sleep, moment

from framework.csv import csv


'''
http://123.207.108.22:38080/shuma/role?token=123&serv=game_qq01&roles=11653,10001&salt=@tj1shuma2tc@

http://123.207.108.22:38080/shuma/recharge?date=161128&role=18036&serv=157&aux=30&salt=@tj1shuma2tc@
'''

class GMHTTPHandler(RequestHandler):
	LastTime = 0
	LastRequest = 0

	@property
	def gameRPCs(self):
		return self.application.gameRPCs

	@property
	def dbcAccount(self):
		return self.application.dbcAccount

	@coroutine
	def get(self):
		yield self.requestHandle()

	@coroutine
	def post(self):
		yield self.requestHandle()

	@coroutine
	def requestHandle(self):
		LastTime = 0
		LastRequest = 0

		nt = int(time.time() / 60)
		if nt != self.LastTime:
			self.LastTime = nt
			self.LastRequest = 0
		self.LastRequest += 1
		if self.LastRequest > 1000:
			raise HTTPError(404, 'to much request')

		salt = self.get_argument("salt", None)
		if salt != '@tj1shuma2tc@':
			raise HTTPError(404, 'no auth')
		yield self.handler()

	@coroutine
	def handler(self):
		raise NotImplementedError()


class RoleQueryHandler(GMHTTPHandler):
	url = "/shuma/role"

	@coroutine
	def handler(self):
		sdkID = self.get_argument("token", None)
		servKey = self.get_argument("serv", None)
		roleID = self.get_argument("role", None)
		roleIDs = self.get_argument("roles", None)
		full = self.get_argument("full", False)
		if roleIDs:
			roleIDs = [int(x) for x in roleIDs.split(',')]
		else:
			roleIDs = []
		if roleID:
			roleIDs.append(int(roleID))

		if servKey not in self.gameRPCs:
			raise HTTPError(404, 'no this server')

		else:
			rpc = self.gameRPCs[servKey]

			result = {}
			for i, roleID in enumerate(roleIDs):
				if i % 10 == 0:
					yield sleep(1)

				ret = yield rpc.call_async('gmGetRoleInfo', roleID)
				if len(ret) == 0:
					# raise HTTPError(404, 'no such role')
					continue

				if not full:
					ret = {
						'id': ret['id'],
						'account_id': ret['account_id'],
						'name': ret['name'],
						'level': ret['level'],
						'vip_level': ret['vip_level'],
						'create_time': ret['create_time'],
						'last_time': ret['last_time'],
						'area': ret['area'],
						'gold': ret['gold'],
						'rmb': ret['rmb'],
						'gate_open': ret['gate_open'],
						'recharges': ret['recharges'],
					}
					s = 0
					for k, d in ret['recharges'].iteritems():
						if k not in csv.recharges:
							continue
						cfg = csv.recharges[k]
						if cfg.type != 1:
							continue
						s += d['cnt'] * int(cfg.rmbDisplay)
					ret['recharges'] = s
				result[roleID] = ret

			ret = json.dumps(result)
			self.write(ret)


class RechargeQueryHandler(GMHTTPHandler):
	url = "/shuma/recharge"

	@coroutine
	def handler(self):
		date = self.get_argument("date", None)
		servID = self.get_argument("serv", None)
		roleID = self.get_argument("role", None)
		aux = self.get_argument("aux", None)
		tw = self.get_argument("tw", None)

		LogDir = '/mnt/deploy/childlog'
		# LogDir = '/home/wjh_shuma_server/deploy/childlog'
		LogPattern = 'payment_server-stdout*'

		import framework
		if framework.__language__ == 'tw':
			LogDir = '/mnt/deploy_login_tw/childlog'

		def servName(servID, tw):
			if servID:
				fmt = 'qq%02d'
				if tw:
					fmt = 'tw%02d'
				return fmt % int(servID)
			return None

		pattern = {
			'"I %s"': str(date) if date else None, # I 161128
			'"game_%s"': servName(servID, tw), # game_qq01
			'"role \\`%s\\`"': str(roleID) if roleID else None, # game_qq01
			'"%s"': str(aux) if aux else None, # game_qq01
		}
		patstr = '|'.join(['grep %s' % (k % v) for k, v in pattern.iteritems() if v] + ['grep "recharge ok"', 'sort'])
		# print patstr
		p = subprocess.Popen('cat %s|%s' % (LogPattern, patstr), shell=True, cwd=LogDir, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
		p.wait()
		ret = ''.join(p.stdout.readlines()).strip()
		if not ret:
			ret = 'no such recharges'
		else:
			ret = ret.replace('\n', '<br/>')
		# print 'ret', ret
		self.write(ret)