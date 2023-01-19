#!/usr/bin/python
# -*- coding: utf-8 -*-

import msgpackrpc

# avoid `msgpackrpc.Server` and `tornado.TCPServer` argue with loop
class AsyncLoop(msgpackrpc.Loop):
	def start(self):
		pass
	def stop(self):
		pass
