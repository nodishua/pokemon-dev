#!/usr/bin/python
# -*- coding: utf-8 -*-

from gevent.monkey import patch_all
patch_all()

import db.client
import db.server
import time
import multiprocessing

Num = 10
LogCon = True

def run_sum_server():
	import framework
	framework.DebugLog(None, LogCon)

	server = db.server.Server('bench_test')
	# print server.servName, 'listen at', server.address, 'starting...'
	server.runLoop()

def run_call():
	import framework
	log = framework.DebugLog(None, LogCon)

	client = db.client.Client('bench_db_test')
	print client.call('TestBenchmarkGet', 'begin')

	before = time.time()
	for x in range(Num):
		# client.call('TestBenchmarkSave', 'clientHello')
		# client.call('TestBenchmarkGet', 'clientHello')
		client.call_async('TestBenchmarkGet', 'clientHello')

	for x in client.futureLst:
		x.get()
	client.futureLst = []

	after = time.time()
	diff = after - before

	log.console = True
	# print client.call('TestBenchmarkGet', 'clientHello')
	print client.call_async('TestBenchmarkGet', 'clientHello')
	for x in client.futureLst:
		print x.get()

	print("call: {0} qps".format(Num / diff))


if __name__ == "__main__":
	p = multiprocessing.Process(target=run_sum_server)
	p.start()

	time.sleep(1)

	run_call()

	p.terminate()
