#!/usr/bin/python
# -*- coding: utf-8 -*-

import os
import sys
sys.path.insert(0, os.path.join(os.getcwd(), '../..'))

import time
import random
import pprint
import msgpack
import functools
from collections import defaultdict

import tornado.ioloop
from framework.loop import AsyncLoop
from framework.rpc_client import Client as RPClient



rpc = None
records = {}
results = {}
idxmap = {}
numRecord = 100
startTime = 0

def onReconnect():
	print 'onReconnect'

def doneOne(idx, fu):
	global results
	global numRecord
	print 'doneOne', idx, fu.result()
	results[idx] = fu.result()
	numRecord -= 1
	if numRecord <= 0:
		tornado.ioloop.IOLoop.current().stop()
		costTime = time.time() - startTime
		print costTime, costTime / len(results)
		summary = defaultdict(lambda: defaultdict(int))
		for k, v in results.iteritems():
			summary[idxmap[k]][v] += 1
		for k, v in summary.iteritems():
			print k, ':', v.items()

def sendOne(idx):
	global results
	global idxmap

	playRecordID = random.choice(records.keys())
	recordData = records[playRecordID]
	results[idx] = 'unkown'
	idxmap[idx] = playRecordID

	fu = rpc.call_async('newRecord', idx, recordData)
	fu.add_done_callback(functools.partial(doneOne, idx))


def main():
	global rpc
	global records
	global startTime

	files = ['test.record', 'test2.record', '67957.record', '68784.record', '69216.record', '69289.record', '69789.record']
	for filename in files:
		with open(filename, 'rb') as fp:
			recordData = fp.read()
			d = msgpack.unpackb(recordData)
			playRecordID = d['id']
			print playRecordID, len(recordData)
			records[playRecordID] = recordData

	ioloop = tornado.ioloop.IOLoop.current()
	rpc = RPClient('anti-cheat', ('192.168.1.125', 1234), loop=AsyncLoop(ioloop), timeout=None, on_reconn=onReconnect)

	ret = rpc.call('hello')
	print 'rpc return', ret

	startTime = time.time()
	for i in xrange(numRecord):
		sendOne(i)

	ioloop.start()

if __name__ == '__main__':
	main()
