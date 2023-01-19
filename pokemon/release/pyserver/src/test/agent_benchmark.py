#!/usr/bin/python
# -*- coding: utf-8 -*-

import os
import sys
sys.path.insert(0, os.path.join(os.getcwd(), '..'))

import time
import signal
from framework.loop import AsyncLoop
from framework.rpc_client import rpc_coroutine, Client
import tornado.gen
import tornado.ioloop

with open('1.play', 'rb') as fp:
	model = fp.read()
ioloop = tornado.ioloop.IOLoop.current()
count = 10000


def agent_benchmark():
	rpc = Client('test', ('192.168.1.125', 1234), AsyncLoop(ioloop), timeout=None)
	# rpc = Client('test', ('123.207.111.69', 1234), AsyncLoop(ioloop), timeout=None)

	left = [count]
	st = time.time()
	def done(fu):
		left[0] -= 1
		if left[0] <= 0:
			print 'agent_benchmar', count, 'cost', time.time() - st
			ioloop.stop()

	for i in xrange(count):
		fu = rpc.call_async('newCraftRecord', 'test', -i, model)
		fu.add_done_callback(done)


def agentmgr_bechmark():
	rpc = Client('test', ('192.168.1.125', 24321), AsyncLoop(ioloop), timeout=None)
	# rpc = Client('test', ('123.207.111.69', 1234), AsyncLoop(ioloop), timeout=None)

	left = [count]
	st = time.time()
	def done(fu):
		left[0] -= 1
		if left[0] <= 0:
			print 'addCraftPlay', count, 'cost', time.time() - st
			# ioloop.stop()
			q.start()

	result = {}
	def query_done(fu):
		r = fu.result()
		result.update(r)
		if len(result) >= count:
			# print result
			s = set([-i for i in xrange(count)])
			rs = set(result.keys())
			print 'agentmgr_bechmark', count, len(result), 'cost', time.time() - st
			print 'result +', rs - s, '-', s - rs
			q.stop()
			ioloop.stop()

	def query():
		fu = rpc.call_async('syncCraftPlayResults', 'test')
		fu.add_done_callback(query_done)


	q = tornado.ioloop.PeriodicCallback(query, 500)
	for i in xrange(count):
		fu = rpc.call_async('addCraftPlay', 'test', -i, 1, 2, model)
		fu.add_done_callback(done)

if __name__ == '__main__':
	if sys.argv[1] == 'agent':
		agent_benchmark()
	else:
		agentmgr_bechmark()
	ioloop.start()