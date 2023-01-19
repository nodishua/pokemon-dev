#!/usr/bin/python
# -*- coding: utf-8 -*-

import sys
sys.path.append('../server/src')

import msgpack
from service_forward import open_forward, objectid2string, string2objectid

plays = {
	# ('crosscraft.cn_qd.75', '5f16cf6027cab67c3cc07872'),
	# ('crosscraft.cn_qd.17', '5f4e2c4536d55f46b031809e'),

	# ('craft.cn.253', '5fafce0754c3f8082d75300c'),
	# ('union_fight.cn_qd.61', '5ea435a47946094629cf9117'),
	# ('union_fight.cn_qd.40', '5ea439093898485fc208e454'),
	# ('craft.cn_qd.532', "5f2563943898481127ea5963"),

	('onlinefight.cn_qd.6', '5fc37ca91afd00715cba37ca'),
	# ('arena.cn.240', "5f2ca6ec54c3f86b1d28a822"),

	# ('onlinefight.cn_qd.2', '5f9522819093b020160772c8'),
	# ('onlinefight.cn_qd.2', '5f9526299093b02016077359'),
	# ('onlinefight.cn_qd.2', '5f95270a9093b02016077380'),
	# ('onlinefight.cn_qd.2', '5f95286f9093b020160773ad'),
}

Functions = {
	'craft': 'GetCraftPlayRecord',
	'arena': 'GetArenaPlayRecord',
	'union_fight': 'GetUnionFightPlayRecord',
	'crosscraft': 'GetCrossCraftPlayRecord',
	'crossarena': 'GetCrossArenaPlayRecord',
	'onlinefight': 'GetCrossOnlineFightPlayRecord',
	'crossmine': 'CrossMineGetPlayRecord',
}

RandSeedFunctions = {
	'craft': 'ResetCraftPlayRecordRandSeed',
	'union_fight': 'ResetUnionFightPlayRecordRandSeed',
}

def save_play(name, id, data):
	data = [name, msgpack.packb(data, use_bin_type=True)]
	data = msgpack.packb(data, use_bin_type=True)
	with open('plays/%s_%s.play' % (name, id), 'wb') as fp:
		fp.write(data)

def read_playrecord(client, id, service_id, name=None):
	if not name:
		name = service_id.split('.')[0]
	print 'start read %s %s' % (name, id)
	resp = client.call(Functions[name], string2objectid(id), service_id=service_id)
	print resp['name'], resp['defence_name']
	save_play(name, id, resp)

def reset_rand_seed_playrecord(client, id, service_id, name=None):
	if not name:
		name = service_id.split('.')[0]
	resp = client.call(RandSeedFunctions[name], string2objectid(id), service_id=service_id)
	print resp

with open_forward('cn') as client:
	for service_id, id in plays:
		read_playrecord(client, id, service_id)
	# id = '5f741aa95ec296364f51232c'
	# resp = client.call('DBRead', 'PVEBattlePlayRecord', string2objectid(id), False, service_id='storage.cn.1')
	# save_play('endless', id, resp['model'])