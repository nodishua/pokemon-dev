#!/usr/bin/python
# -*- coding: utf-8 -*-

from pymongo import MongoClient
import paramiko
import msgpack
import binascii
from bson.objectid import ObjectId

import sys
sys.path.append('../server/src')

from nsqrpc.client import NSQClient
from tornado.ioloop import IOLoop
from tornado.gen import coroutine, Return, sleep
from tornado.concurrent import Future
import datetime

def objectid2string(id):
	return binascii.hexlify(id)

def string2objectid(s):
	return binascii.unhexlify(s)

@coroutine
def wait():
	yield sleep(1)

RechargeMap = {
	1:	300,
	2:	880,
	3:	6480,
	4:	3280,
	5:	1980,
	6:	980,
	7:	600,
	8:	300,
	9:	60,
	101:	10,
	102:	60,
	103:	120,
	104:	180,
	105:	250,
	106:	300,
	107:	600,
	108:	980,
	109:	1280,
	110:	1680,
	111:	1980,
	112:	3280,
	113:	6480,
}

import json
with open('../release/storage/defines.json', 'r') as fp:
	storage_defines = json.load(fp)

pipeline = [
	{
		"$project": {
			"_id": 1,
			"rmb": 1,
			"rmb_consume": 1,
			'sum_rmb': {'$add': ['$rmb', '$rmb_consume']},
			"recharges": 1,
			'created_time': 1,
			"name": 1,
			'uid': 1,
		}
	},
	{
		"$sort": {"sum_rmb": -1},
	},
	{
		"$limit": 100,
	}
]

keys = ['storage.cn.%d' % i for i in xrange(1, 107+1)]
keys += ['storage.cn_qd.%d' % i for i in xrange(1, 454+1)]

# keys = ['storage.dev.2']
for key in keys:
	url = None
	dbname = None
	services = storage_defines[key]['services']
	for v in services:
		if v['name'] == key:
			url = v['mongodb']
			dbname = v['dbname']
			break
	conn = MongoClient(url)
	collection = conn[dbname]['Role']
	response = collection.aggregate(pipeline)
	for i, role in enumerate(response, 1):
		recharges = role['recharges']
		total = recharges.get('-1', {'cnt': 0})['cnt']
		total = 0
		for rechagreID, d in recharges.iteritems():
			rechagreID = int(rechagreID)
			if rechagreID == -1:
				continue
			cnt = d.get('cnt', 0)
			total += cnt * RechargeMap[rechagreID]
		role['total'] = total
		role['name'] = role['name'].encode('utf-8')
		role['key'] = key
		role['rank'] = i
		role['time'] = datetime.datetime.fromtimestamp(role['created_time'])

		s = '{key}\t{rank}\t{_id}\t{uid}\t{name}\t{rmb}\t{rmb_consume}\t{sum_rmb}\t{total}\t{time}'
		s = s.format(**role)
		print s

# 区服 排名 id uid 名字 当前钻石 累计钻石消耗 累计钻石获得 累计充值钻石

	conn.close()
