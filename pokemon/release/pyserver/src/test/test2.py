#!/usr/bin/python
# -*- coding: utf-8 -*-

import os
import sys
sys.path.insert(0, os.path.join(os.getcwd(), '..'))

import time
import signal
from framework.loop import AsyncLoop
from framework.rpc_client import rpc_coroutine, Client
import tornado.ioloop


def main():
	with open('1.play', 'rb') as fp:
		model = fp.read()

	ioloop = tornado.ioloop.IOLoop.current()
	# rpc = Client('test', ('192.168.1.125', 12345), AsyncLoop(ioloop), timeout=None)
	rpc = Client('test', ('123.207.111.69', 1234), AsyncLoop(ioloop), timeout=None)

	count = 1000
	left = [count]
	st = time.time()
	def done(fu):
		left[0] -= 1
		if left[0] <= 0:
			print count, 'cost', time.time() - st
			ioloop.stop()

	for i in xrange(count):
		fu = rpc.call_async('newCraftRecord', -i, model)
		fu.add_done_callback(done)

	ioloop.start()

if __name__ == '__main__':
	main()