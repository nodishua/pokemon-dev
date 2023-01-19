#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2014 YouMi Information Technology Inc.
'''
from framework import nowtime_t
from framework.csv import csv, ConstDefs
from framework.log import logger
from framework.object import ObjectNoGCDBase, db_property
from framework.helper import objectid2string
from game import ClientError, ServerError
from game.object import EndlessTowerDefs
from tornado.gen import coroutine
from bson.objectid import ObjectId
import msgpack
import requests
import json

DINGHEADERS = {
	'Content-Type': 'application/json; charset=UTF-8'
}

class ObjectEndlessTowerGlobal(ObjectNoGCDBase):
	DBModel = 'EndlessTowerGlobal'

	Singleton = None
	MinGate = 0
	MaxGate = 0

	# 战斗线上反馈机器人
	DingURL = "https://oapi.dingtalk.com/robot/send?access_token=909694ef21918ab9a51e4cfd3c479b6e7a61aa13cd8b601a589d30ee2ee285c9"

	@classmethod
	def classInit(cls):
		cfg = csv.endless_tower_scene
		cls.MinGate = min(cfg.keys())
		cls.MaxGate = max(cfg.keys())

	def __init__(self, dbc):
		ObjectNoGCDBase.__init__(self, None, dbc)

		self.maybecheat = {} # {roleID: [timestamp, ]}

		if ObjectEndlessTowerGlobal.Singleton is not None:
			raise ValueError('This is singleton object')
		ObjectEndlessTowerGlobal.Singleton = self

	def init(self, server):
		self._server = server
		return ObjectNoGCDBase.init(self)

	# 最近通关战报
	latest_plays = db_property('latest_plays')  # {gateID : [{'play_id': play_id, 'logo': logo, ... },{} ...]}

	# 最低战力通关战报
	lower_fighting_plays = db_property('lower_fighting_plays')  # {gateID : {'play_id': play_id, 'logo': logo, ... }}

	@classmethod
	def getLatestPlays(cls, gateID):
		self = cls.Singleton
		plays = self.latest_plays.get(gateID, [])
		return plays

	@classmethod
	def getLowerPlay(cls, gateID):
		self = cls.Singleton
		play = self.lower_fighting_plays.get(gateID, None)
		return play

	@staticmethod
	def isRightCards(cards, gateID):
		'''
		卡牌布阵是否 正确
		:param cards, gateID:
		:return:
		'''
		cfg = csv.endless_tower_scene[gateID]
		limitType = cfg.limitType  # 限制类型
		limitArg = cfg.limitArg  # 限制具体条件
		if limitType == EndlessTowerDefs.NatureTypeValid:
			for card in cards:
				if card.natureType not in limitArg and card.natureType2 not in limitArg:
					return False
		elif limitType == EndlessTowerDefs.NatureTypeInvalid:
			for card in cards:
				if card.natureType in limitArg or card.natureType2 in limitArg:
					return False
		elif limitType == EndlessTowerDefs.RarityLimit:
			rarityDic = {}
			for card in cards:
				cardRarity = rarityDic.get(card.rarity, 0)
				rarityDic[card.rarity] = cardRarity + 1
			for arg in limitArg:
				if arg[0] not in rarityDic.keys():
					return False
				else:
					if arg[1] > rarityDic[arg[0]]:
						return False
		return True

	@classmethod
	@coroutine
	def recordPlay(cls, model, role):
		self = cls.Singleton

		model['role_db_id'] = role.id
		model['name'] = role.name
		model['logo'] = role.logo
		model['frame'] = role.frame

		fightingPoint = model.pop('fightingPoint')
		round = model.pop('round')
		model.pop('id')
		gateID = model.get('gate_id', 0)

		# 记录战报详情
		playRecordData = yield self._dbc.call_async('DBCreate', 'PVEBattlePlayRecord', model)
		if not playRecordData['ret']:
			raise ServerError('db create PVEBattlePlayRecord error')
		play_id = playRecordData['model']['id']

		simplePlay = {"play_id": play_id, "logo": role.logo, "name": role.name, "frame": role.frame, "level": role.level, "vip": role.vip_level_display, "fighting_point": fightingPoint, "round": round}
		# 最近战报
		latestPlays = self.latest_plays.get(gateID, [])
		deletes = latestPlays[:-2] # 最多3个
		latestPlays = latestPlays[-2:]
		latestPlays.append(simplePlay)
		self.latest_plays[gateID] = latestPlays
		if deletes:
			self._dbc.call_async('DBMultipleDelete', 'PVEBattlePlayRecord', [x['play_id'] for x in deletes])

	@classmethod
	def sendToAntiCheatCheck(cls, uid, roleID, name, model, clientResult, rpc):
		self = cls.Singleton
		gateID = model.get('gate_id', 0)
		data = msgpack.packb(model)
		def callback(future):
			result = future.result()
			if result in ('win', 'fail') and result != clientResult:
				logger.warning('role %d %s gate %d cheat, result %s anti %s', uid, objectid2string(roleID), gateID, clientResult, result)
				if roleID in self.maybecheat:
					self.maybecheat[roleID].append(nowtime_t())
				else:
					self.maybecheat[roleID] = [nowtime_t()]
				if len(self.maybecheat[roleID]) >= ConstDefs.endlessCheatSilentTimes:
					# 上报告警
					msg = "server {server}\n\nrole uid {uid} \n\nrole id {id}\n\nrole name {name}\n\nbattle type {type}\n\ngate {gate}\n\ncount {count}".format(server=self._server.key, uid=uid, id=objectid2string(roleID),name=name, type='endless', gate=gateID, count=len(self.maybecheat[roleID]))
					cls.ding(msg)
			else:
				logger.info('role %d %s gate %d, result %s anti %s', uid, objectid2string(roleID), gateID, clientResult, result)

		future = rpc.call_async('NewEndlessBattle', self._server.key, ObjectId().binary, data)
		future.add_done_callback(callback)

	@classmethod
	def maybeCheatRole(cls, roleID):
		self = cls.Singleton
		if roleID not in self.maybecheat:
			return False
		if len(self.maybecheat[roleID]) < ConstDefs.endlessCheatSilentTimes:
			return False
		time = self.maybecheat[roleID][-1]
		return nowtime_t() - time < ConstDefs.endlessCheatSilent

	@classmethod
	def ding(cls, msg):
		params = {
			"msgtype": "markdown",
			"markdown": {
				"title": "战斗反馈",
				"text": "## " + '战斗反馈' + "\n\n" + '(疑似作弊)' + "\n\n" + msg + "\n",
			}
		}
		x = requests.post(cls.DingURL, json=params, headers=DINGHEADERS)
		if x.status_code != 200:
			logger.warning('%s', x.text)
