#!/usr/bin/python
# -*- coding: utf-8 -*-

import sys
sys.path.append('../server/src')

import msgpack
from service_forward import open_forward, objectid2string, string2objectid

with open_forward('cn') as client:
	filename = "plays/craft_5e99a490c27b86584ca83626.play"
	# typ = filename.split('_')[0]
	play_id = filename.split('_')[1].split('.')[0]
	print play_id
	with open(filename, 'rb') as fp:
		data = fp.read()
		typ, data = msgpack.unpackb(data)
	for i in xrange(100):
		resp = client.call('NewCraftBattle', 'walle.cn.2', string2objectid(play_id), data)
		print i, resp

